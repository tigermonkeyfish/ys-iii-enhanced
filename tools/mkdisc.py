#!/usr/bin/env python3
"""Build the patched disc from your own dump.

    python3 tools/mkdisc.py [OUTDIR]        default OUTDIR: dist/disc

Reads .local/disc.cue and its track files. Assembles the Redmont module, the stub and the
no-card message with pceas (from the PATH, or the file named by the environment variable
PCEAS), writes them into the data track after checking the SHA-256 of the 16 bytes at each
hook site, re-encodes EDC/ECC of every changed sector, and writes OUTDIR: the patched Track 02
file, the other tracks (hard links, or copies across file systems) and disc.cue. Any failed
check stops the build. The data track keeps its length.
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import disc  # noqa: E402

RAW, USER, MIRROR = 2352, 2048, 12288      # raw and user bytes a sector; sectors from a copy of the data layout to the other
PCEAS = os.environ.get("PCEAS") or shutil.which("pceas") or "pceas"
CFG = json.loads((ROOT / "src/modules.json").read_text())
SITES = {k: (v["sector"], v["offset"], v["sha256_16"]) for k, v in CFG["hook_sites"].items()}
HOOKS = (("block_load", "areaload"), ("row_draw", "rowstub"), ("vsync_wait", "waitfix"), ("satb_req", "satstub"), ("satb_wait", "satwait"), ("vram_alloc", "allocstub"))
HALTSEC, SLOT = 158, 4                     # the no-card message's sectors (HALTSEC in disc_boot.asm too); sectors of one 8 KB bank
RUN1, RUN2 = (0x6BA, 0x800), (0x1F47, 0x2000)     # the stub's two runs in its assembled image
# The stub bank (disc_boot.asm .bank 1, $C400-$C7FF): its image at $2400-$27FF of the assembled image, written at byte $400 of the
# no-card message's sectors after the message; the boot reads them and copies the part into card RAM bank SBANK.
SBPART, HALTMAX = (0x2400, 0x2800), 0x400
COLD = 2                                   # the module's second code bank: assembler bank 2 ($C000), "bank2" / "sector2" in src/modules.json


def user_bytes(trk, sector, off, n):
    out = b""
    while n > 0:
        k = min(n, USER - off)
        base = sector * RAW + 16
        out += bytes(trk[base + off:base + off + k])
        n, sector, off = n - k, sector + 1, 0
    return out


def put(trk, sector, off, data, changed):
    i = 0
    while i < len(data):
        k = min(len(data) - i, USER - off)
        base = sector * RAW + 16
        trk[base + off:base + off + k] = data[i:i + k]
        changed.add(sector)
        i, sector, off = i + k, sector + 1, 0


def assemble(src, build, banks=None):
    """Assemble src in build/. banks gets {bank: (bytes used, bytes free)} from the assembler's segment report."""
    build.mkdir(parents=True, exist_ok=True)
    asm = build / Path(src).name
    shutil.copyfile(src, asm)
    if not shutil.which(PCEAS):
        sys.exit("pceas not found: put it on the PATH or name it in PCEAS (see README.md)")
    r = subprocess.run([PCEAS, "-s", "--raw", asm.name], cwd=build, capture_output=True, text=True)
    if r.returncode or "error" in (r.stdout + r.stderr).lower():
        sys.exit(r.stdout + r.stderr)
    if banks is not None:
        for m in re.finditer(r"^BANK \$([0-9A-Fa-f]+)\s+(\d+)\s*/\s*(\d+)", r.stdout, re.M):
            banks[int(m[1], 16)] = (int(m[2]), int(m[3]))
    img = (build / asm.with_suffix(".pce").name).read_bytes()
    sym = {}
    for line in (build / asm.with_suffix(".sym").name).read_text().splitlines():
        p = line.split()
        if len(p) >= 3 and re.fullmatch(r"[0-9a-fA-F]{2}", p[0]):
            sym[p[2]] = int(p[1], 16)
    return img, sym


def module_blob(m, build):
    """The module's bank: it must end inside its 8 KB and start with its jump table."""
    banks = {}
    img, sym = assemble(ROOT / m["source"], build, banks)
    over = {b: u for b, (u, _f) in banks.items() if u and b > 0 and not (b == COLD and m.get("bank2"))}
    assert not over, f"{m['name']}: code or data runs past the bank: {over}"
    first = img[:0x2000]
    blob = first[:max(i for i, b in enumerate(first) if b != 0xFF) + 1]
    assert all(blob[3 * k] == 0x4C for k in range(7)), f"{m['name']}: no JMP at an entry of the jump table"
    assert len(blob) <= m["count"] * USER <= 0x2000, f"{m['name']}: {len(blob)} bytes over its {m['count']} sectors"
    print(f"module {m['name']}: block {m['block']} bank {m['bank']} sectors {m['sector']}-{m['sector'] + m['count'] - 1}: {len(blob)} bytes, bank headroom {0x2000 - len(blob)}")
    if m.get("bank2"):                 # its second code bank (.bank 2 at $C000): read by the stub with the first
        cold = img[COLD * 0x2000:(COLD + 1) * 0x2000]
        cold = cold[:max((i for i, b in enumerate(cold) if b != 0xFF), default=-1) + 1]
        assert cold[:1] == b"\x4C" and len(cold) <= SLOT * USER, f"{m['name']}: second code bank"
        print(f"  second code bank {m['bank2']} sectors {m['sector2']}-{m['sector2'] + SLOT - 1}: {len(cold)} bytes")
        m["_cold"] = cold
    return blob


def main():
    out = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "dist/disc"
    build = ROOT / "build"
    build.mkdir(parents=True, exist_ok=True)
    if not (ROOT / ".local/disc.cue").exists():
        sys.exit(".local/disc.cue not found: put your dump in .local/ (see README.md)")
    mods = CFG["disc"]
    assert len(mods) == 1
    m = mods[0]
    cue = disc.parse_cue(ROOT / ".local/disc.cue")
    dt = disc.data_track(cue)
    trk = bytearray(disc.read_track(dt))
    if hashlib.sha256(trk).hexdigest() != CFG["baseline_sha256"]:
        sys.exit(f"{dt['file'].name}: not the dump this patch is made for (data track sha256 mismatch)")
    for name in ("modsig.inc", "font.inc"):
        shutil.copyfile(ROOT / "src" / name, build / name)
    blob_mod = module_blob(m, build)
    (build / "directory.inc").write_text(
        "NMOD = 1\n"
        f"dblk:\t.db {m['block']}\n"
        f"dbank:\t.db {int(m['bank'], 16)}\n"
        + (f"D2MOD = 0\nD2BANK = {int(m['bank2'], 16)}\nD2SEC = {m['sector2']}\n" if m.get("bank2") else "D2MOD = 255\nD2BANK = 0\nD2SEC = 0\n") +
        "dl:\t.db 0\n")
    (build / "dirsec.inc").write_text(f"\t.db {m['sector']}\n")       # dsec: the module's first sector, assembled in the stub bank
    img, sym = assemble(ROOT / "src/disc_boot.asm", build)
    assert all(b == 0xFF for i, b in enumerate(img) if not (RUN1[0] <= i < RUN1[1] or RUN2[0] <= i < RUN2[1] or SBPART[0] <= i < SBPART[1])), "stub outside its two runs and the stub bank"
    stub_src = (ROOT / "src/disc_boot.asm").read_text()
    sym["SBORG"], sym["SBANK"] = (int(re.search(rf"^{k}\s*=\s*\$([0-9A-Fa-f]+)", stub_src, re.M)[1], 16) for k in ("SBORG", "SBANK"))      # (equates, not in the symbol file)
    assert sym["SBORG"] == 0xC400 and SBPART[0] - 0x2000 + 0xC000 == sym["SBORG"]
    sbpart = img[SBPART[0]:SBPART[1]].rstrip(b"\xff")
    blob, blob2 = img[RUN1[0]:RUN1[1]].rstrip(b"\xff"), img[RUN2[0]:RUN2[1]]
    print(f"stub: run 1 {len(blob)} of {RUN1[1] - RUN1[0]} bytes, run 2 {len(img[RUN2[0]:RUN2[1] - 1].rstrip(bytes([0xFF])))} of {RUN2[1] - RUN2[0] - 1}")
    (build / "haltsyms.inc").write_text(f"SBOK = ${sym['sbok']:04X}\nSBANK = ${sym['SBANK']:02X}\nSBGO = ${sym['sbgo']:04X}\n")
    himg, _ = assemble(ROOT / "src/syscard_halt.asm", build)
    code = himg[:0x2000].rstrip(b"\xff")
    assert code[0] == 0x4C and len(code) <= HALTMAX, f"no-card message: {len(code)} bytes, over the {HALTMAX} below the stub bank's part"
    halt = code + bytes(HALTMAX - len(code)) + sbpart
    changed = set()
    sec, off, want = SITES["ipl_exec"]
    got = hashlib.sha256(user_bytes(trk, sec, off, 16)).hexdigest()
    assert got.startswith(want), f"ipl_exec site at {sec}:{off} is not the expected header ({got[:12]})"
    put(trk, sec, off, sym["bootchk"].to_bytes(2, "little"), changed)
    for copy in (0, MIRROR):
        assert set(user_bytes(trk, 2 + copy, 0x6BA, len(blob))) == {0xFF}, "first run not free"
        put(trk, 2 + copy, 0x6BA, blob, changed)
        assert set(user_bytes(trk, 452 + copy, 0x747, len(blob2))) == {0xFF}, "second run not free"
        put(trk, 452 + copy, 0x747, blob2, changed)
        for site, target in HOOKS:
            sec, off, want = SITES[site]
            got = hashlib.sha256(user_bytes(trk, sec + copy, off, 16)).hexdigest()
            assert got.startswith(want), f"{site} site at {sec + copy}:{off} is not the expected code ({got[:12]})"
            put(trk, sec + copy, off, bytes([0x20, sym[target] & 0xFF, sym[target] >> 8]), changed)
        assert not any(user_bytes(trk, HALTSEC + copy, 0, SLOT * USER)), "the no-card message's sectors are not all zero"
        put(trk, HALTSEC + copy, 0, halt, changed)
        n = m["count"]
        assert not any(user_bytes(trk, m["sector"] + copy, 0, n * USER)), f"{m['name']}: its sectors are not all zero"
        put(trk, m["sector"] + copy, 0, blob_mod + bytes(n * USER - len(blob_mod)), changed)
        if m.get("bank2"):
            assert not any(user_bytes(trk, m["sector2"] + copy, 0, SLOT * USER)), f"{m['name']}: its second bank's sectors are not all zero"
            put(trk, m["sector2"] + copy, 0, m["_cold"] + bytes(SLOT * USER - len(m["_cold"])), changed)
    for s in sorted(changed):
        trk[s * RAW:(s + 1) * RAW] = disc.encode_sector(bytes(trk[s * RAW:(s + 1) * RAW]))
    src_data = dt["file"].read_bytes()
    patched = src_data[:dt["start"] * RAW] + bytes(trk) + src_data[dt["end"] * RAW:]
    assert len(patched) == len(src_data)
    got = hashlib.sha256(patched).hexdigest()
    print(f"{len(changed)} sectors changed {sorted(changed)}")
    print(f"patched Track 02 sha256 {got}")
    if got != CFG["release_track_sha256"]:
        sys.exit(f"not the expected build (sha256 {CFG['release_track_sha256']}), nothing written: check the pceas version in README.md")
    out.mkdir(parents=True, exist_ok=True)
    for tr in cue:
        dst = out / tr["file"].name
        if dst.exists() or dst.is_symlink():
            dst.unlink()
        if tr is dt:
            dst.write_bytes(patched)
        else:
            try:
                os.link(tr["file"], dst)
            except OSError:
                shutil.copyfile(tr["file"], dst)
    shutil.copyfile(ROOT / ".local/disc.cue", out / "disc.cue")
    print(f"{out}: the patched disc")


if __name__ == "__main__":
    main()
