#!/usr/bin/env python3
"""Build the patched disc from your own dump.

    python3 tools/mkdisc.py [OUTDIR]        default OUTDIR: dist/disc

Reads .local/disc.cue and its track files. Assembles the stub, the boot test,
the disc modules and any Arcade Card module with pceas (from the PATH, or the
file named by the environment variable PCEAS), checks hook-site digests,
re-encodes EDC/ECC of every changed sector, and writes OUTDIR (plus
OUTDIR.store.json and OUTDIR-store when a release manifest pin is configured).
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

RAW, USER, MIRROR = 2352, 2048, 12288      # raw and user bytes a sector; copy spacing
PCEAS = os.environ.get("PCEAS") or shutil.which("pceas") or "pceas"
CFG = json.loads((ROOT / "src/modules.json").read_text())
SITES = {k: (v["sector"], v["offset"], v["sha256_16"]) for k, v in CFG["hook_sites"].items()}
HOOKS = (("block_load", "areaload"), ("row_draw", "rowstub"), ("vsync_wait", "waitfix"), ("satb_req", "satstub"), ("satb_wait", "satwait"), ("vram_alloc", "allocstub"), ("satb_top", "objpass"), ("obj_emit", "objslot"))
HALTSEC, SLOT = 158, 4
RUN1, RUN2 = (0x6BA, 0x800), (0x1F47, 0x2000)     # own: stub byte offsets in resident bank
SBPART, SBPART2 = (0x2400, 0x2800), (0x4800, 0x4C00)     # own: stub bank image offsets
HALTMAX, PGFLAG_OFF = 0x400, 0x3FF
SBPIECE, SBRA = (0x6D0, 0x800), (0x000, 0x400)     # own: stub bank module piece and resident area offsets
SBANK = 0x7D
COLD, COLD3, COLD4 = 2, 3, 4
CHUNK3B, CHUNK4B, CHUNK5B, CHUNK6B, CHUNK7B = 3, 4, 5, 6, 7
CODE_BANKS = {0x7B, 0x7C, 0x7D, 0x7E, 0x7F}        # own: CD RAM code bank pool
DATA_BANKS = set(range(0x69, 0x7B))                # own: CD RAM data bank range
WIDE = 0x68
CARD_M = {0x69} | set(range(0x6B, 0x77))           # own: module bank window range
CARD_MAXBANKS = 8
CARDSYMS = "CMSEC = 0\n"


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


def assemble(src, build, banks=None, defs=None):
    """Assemble src in build/. defs overrides matching top-level equate assignments."""
    build.mkdir(parents=True, exist_ok=True)
    asm = build / Path(src).name
    text = Path(src).read_text()
    for name, value in (defs or {}).items():
        text, n = re.subn(rf"^({re.escape(name)}\s*=\s*)\S+", rf"\g<1>{value}", text, flags=re.M)
        assert n <= 1, f"{name} defined {n} times in {src}"
    asm.write_text(text)
    if not shutil.which(PCEAS):
        sys.exit("pceas not found: put it on the PATH or name it in PCEAS (see README.md)")
    r = subprocess.run([PCEAS, "-s", "--raw", asm.name], cwd=build, capture_output=True, text=True)
    if r.returncode or "error" in (r.stdout + r.stderr).lower():
        sys.exit(r.stdout + r.stderr)
    if banks is not None:
        for m in re.finditer(r"^BANK \$([0-9A-Fa-f]+)\s+(\d+)\s*/\s*(\d+)", r.stdout, re.M):
            banks[int(m[1], 16)] = (int(m[2]), int(m[3]))
    img = (build / asm.with_suffix(".pce").name).read_bytes()
    sym, const = {}, {}
    for line in (build / asm.with_suffix(".sym").name).read_text().splitlines():
        p = line.split()
        if len(p) >= 3 and re.fullmatch(r"[0-9a-fA-F]{2}", p[0]):
            sym[p[2]] = int(p[1], 16)
        elif len(p) >= 3 and p[0] == "-" and re.fullmatch(r"[0-9a-fA-F]+", p[1]):
            const[p[2]] = int(p[1], 16)
    return img, {**const, **sym}


def stub_local(build, glob, loc, name="disc_boot"):
    cur = None
    for line in (build / f"{name}.sym").read_text().splitlines():
        p = line.split()
        if len(p) >= 3 and re.fullmatch(r"[0-9a-fA-F]{2}", p[0]):
            if not p[2].startswith("."):
                cur = p[2]
            elif cur == glob and p[2] == loc:
                return int(p[1], 16)
    sys.exit(f"stub: no local label {glob}/{loc}")


def card_sum(b):
    s1 = s2 = 0
    for g in range(8):
        a = c = 0
        for y in range(256):
            for p in range(4):
                v = a + b[g * 1024 + p * 256 + y] + c
                a, c = v & 0xFF, v >> 8
        s1 = (s1 + a + c) & 0xFF
        s2 = (s2 + s1) & 0xFF
    return s1 | s2 << 8


def fsum(data):
    s1 = s2 = 0
    for b in data:
        s1 = (s1 + b) & 0xFF
        s2 = (s2 + s1) & 0xFF
    return bytes((s1, s2))


def site_proofs(m, blob, trk, simg, build):
    rs = m.get("ram_sites", {})

    def site(name):
        sec, off, sha = (rs[name]["sector"], rs[name]["offset"], rs[name]["sha256_16"]) if name in rs else SITES[name]
        assert hashlib.sha256(user_bytes(trk, sec, off, 16)).hexdigest().startswith(sha), f"{m['name']}: site {name} at {sec}:{off} differs"
        return sec, off

    for name in rs:
        site(name)
    blob = bytearray(blob)
    for name, (label, k, n) in m.get("site_sums", {}).items():
        sec, off = site(name)
        a = m["_sym"][label] - 0xA000 + k
        assert 0 < n <= 16 and a + 2 <= len(blob) and not any(blob[a:a + 2]), f"{m['name']}: reserve {label}+{k} not empty"
        blob[a:a + 2] = fsum(user_bytes(trk, sec, off, n))
    for name, v in m.get("site_instr", {}).items():
        sec, off = site(name)
        if v[0] == "jsr":
            t = m["_sym"][v[1]]
            made = bytes([0x20, t & 0xFF, t >> 8])
        else:
            a = stub_local(build, v[1], v[2]) - 0x4000
            made = bytes(simg[a:a + 3])
        assert made == user_bytes(trk, sec, off, 3), f"{m['name']}: site {name} mismatch"
    return bytes(blob)


def overflow_check(m, banks):
    name = m["name"]
    over = {b: u for b, (u, _f) in banks.items() if u and b > (1 if m.get("chunk") else 0)
            and not (b == COLD and m.get("bank2")) and not (b == COLD3 and m.get("bank3"))
            and not (b == CHUNK3B and m.get("chunk3")) and not (b == CHUNK4B and m.get("chunk4"))
            and not (b == CHUNK5B and m.get("chunk5")) and not (b == CHUNK6B and m.get("chunk6"))
            and not (b == CHUNK7B and m.get("chunk7"))
            and not (b in (CHUNK7B + 1, CHUNK7B + 2, CHUNK7B + 3, CHUNK7B + 4) and m.get("chunk7"))
            and not (b == COLD4 and m.get("bank4"))}
    assert not over, f"{name}: code or data runs past bank limit in {sorted(over)}"
    if m.get("chunk") and 1 in banks:
        lim = 0x1000 if m.get("chunk2") else 0x800
        assert banks[1][0] <= lim, f"{name}: second bank over {lim}"


def module_blob(m, build):
    banks = {}
    img, sym = assemble(ROOT / m["source"], build, banks)

    def ovl(bk, org_k, len_k):
        org, n = sym[org_k], sym[len_k]
        assert n % 256 == 0 and 0 < n and (org & 0x1FFF) + n <= 0x2000
        return img[bk * 0x2000 + (org & 0x1FFF):bk * 0x2000 + (org & 0x1FFF) + n], org, n

    ovs = [(k, b, o, l, s_) for k, b, o, l, s_ in (("chunk5", CHUNK5B, "C6RAM", "C6LEN", "C6SUM"),
                                                  ("chunk6", CHUNK6B, "C7RAM", "C7LEN", "C7SUM"),
                                                  ("chunk7", CHUNK7B, "C8RAM", "C8LEN", "C8SUM")) if m.get(k)]
    defs = {}
    if "CBKEY" in sym and sym["CBKEY"] == 0:
        cbkey = int.from_bytes(hashlib.sha256(img).digest()[:2], "little") or 1
        defs["CBKEY"] = f"${cbkey:04X}"
        banks = {}
        img, sym = assemble(ROOT / m["source"], build, banks, defs)
    for _pass in range(4):
        want = {s_: sum(ovl(b, o, l)[0]) & 0xFFFF for _k, b, o, l, s_ in ovs}
        if "C6SUM1" in sym and any(k == "chunk5" for k, *_ in ovs):
            want["C6SUM1"] = sum(ovl(CHUNK5B, "C6RAM", "C6LEN")[0][:256]) & 0xFFFF
        if all(sym[s_] == w for s_, w in want.items()):
            break
        cur = dict(defs, **{s_: f"${w:04X}" for s_, w in want.items()})
        banks = {}
        img, sym = assemble(ROOT / m["source"], build, banks, cur)
    else:
        sys.exit(f"{m['name']}: overlay sums did not settle")

    for k, bk, o, l, s_ in ovs:
        ov, org, n = ovl(bk, o, l)
        bkb = img[bk * 0x2000:(bk + 1) * 0x2000] if len(img) > bk * 0x2000 else b""
        assert all(b == 0xFF for i, b in enumerate(bkb) if not (org & 0x1FFF) <= i < (org & 0x1FFF) + n)
        m["_" + k] = ov
        if k == "chunk7" and "C9LEN" in sym:
            n9 = sym["C9LEN"]
            b9 = img[(bk + 1) * 0x2000:(bk + 2) * 0x2000]
            assert n + n9 <= 0x1000 and all(b == 0xFF for i, b in enumerate(b9) if not (org & 0x1FFF) <= i < (org & 0x1FFF) + n9)
            m["_" + k] = ov + b9[org & 0x1FFF:(org & 0x1FFF) + n9].ljust(n9, b"\xff")
        if k == "chunk7" and "pgfast" in sym:
            b10 = img[(bk + 2) * 0x2000:(bk + 3) * 0x2000]
            pa, pb = (sym["cidle"] & 0x1FFF, sym["bready"] & 0x1FFF), (sym["q8hdr"] & 0x1FFF, sym["cup1"] & 0x1FFF)
            assert sym["pgfast"] == sym["cidle"] and sym["pgload"] == sym["q8hdr"] and sym["pgaend"] <= sym["bready"] and sym["pgbend"] <= sym["cup1"]
            m["_pgf"] = b10[pa[0]:pa[1]] + b10[pb[0]:pb[1]]
            m["_pgsec"], m["_pgdir"], m["_cbkey"] = sym["PGSEC"], sym["PGDIR"], sym["CBKEY"]
            if "sjt" in sym:
                b11 = img[(bk + 3) * 0x2000:(bk + 4) * 0x2000]
                o7, n7 = sym["C7RAM"] & 0x1FFF, sym["SLEN"]
                m["_seam"] = (sym["C6CH"] << 16 | 0x4000, b11[o7:o7 + n7])
                if "hjt" in sym:
                    b12 = img[(bk + 4) * 0x2000:(bk + 5) * 0x2000]
                    oh, nh = (sym["C8RAM"] + sym["C9LEN"]) & 0x1FFF, sym["HLEN"]
                    m["_seam"] = (m["_seam"][0], m["_seam"][1] + b12[oh:oh + nh])
    overflow_check(m, banks)
    first = img[:0x2000]
    blob = first[:max(i for i, b in enumerate(first) if b != 0xFF) + 1]
    assert all(blob[3 * k] == 0x4C for k in range(7)), f"{m['name']}: jump table entry invalid"
    assert len(blob) <= m["count"] * USER <= 0x2000
    print(f"module {m['name']}: block {m['block']} bank ${m['bank']:02X} sectors {m['sector']}-{m['sector'] + m['count'] - 1}: {len(blob)} bytes, bank headroom {0x2000 - len(blob)}")
    second = img[0x3800:0x4000] if len(img) > 0x3800 else b""
    third = img[0x3000:0x3800] if m.get("chunk2") and len(img) > 0x3000 else b""
    if m.get("chunk2"):
        m["_chunk2"] = third
    if m.get("chunk3"):
        m["_chunk3"] = img[0x7000:0x8000]
    if m.get("chunk4"):
        m["_chunk4"] = img[0x9000:0xA000]
        sra = img[0x8000 + SBRA[0]:0x8000 + SBRA[1]]
        sbp = img[0x8000 + SBPIECE[0]:0x8000 + SBPIECE[1]]
        if sra.count(0xFF) < len(sra):
            m["_sbra"] = sra
        if sbp.count(0xFF) < len(sbp):
            m["_sbpiece"] = sbp
    if m.get("chunk"):
        m["_chunk"] = second
    for ck, bk_idx in (("_cold", COLD), ("_cold3", COLD3), ("_cold4", COLD4)):
        need = {"_cold": "bank2", "_cold3": "bank3", "_cold4": "bank4"}[ck]
        if m.get(need):
            cb = img[bk_idx * 0x2000:(bk_idx + 1) * 0x2000]
            cb = cb[:max((i for i, b in enumerate(cb) if b != 0xFF), default=-1) + 1]
            assert cb[:1] == b"\x4C" and len(cb) <= SLOT * USER
            m[ck] = cb
    m["_sym"] = sym
    return blob


def card_module(m, build, simg):
    global CARDSYMS
    c = m["card"]
    defs = dict(kv.split("=", 1) for kv in m.get("set", []))
    banks = {}
    img, sym = assemble(ROOT / m["source"], build, banks, defs)
    opt = {int(e[0]): e[3].split(":")[1] for e in c["banks"] if len(e) > 3}
    kb = [(int(e[0]), int(e[1], 16), e[2]) for e in c["banks"] if not (int(e[0]) in opt and not banks.get(int(e[0]), (0, 0))[0])]
    assert 1 <= len(kb) <= CARD_MAXBANKS and kb[0][0] == 0
    parts = [bytearray(img[k * 0x2000:(k + 1) * 0x2000].ljust(0x2000, b"\xff")) for k, _r, _n in kb]
    m["_sym"] = sym
    trk0 = bytearray(disc.read_track(disc.data_track(disc.parse_cue(ROOT / ".local/disc.cue"))))
    parts[0] = bytearray(site_proofs(m, bytes(parts[0]), trk0, simg, build))
    ks, kk = sym["cmsums"] - 0xA000, sym["cmkey"] - 0xA000
    for i, p in enumerate(parts[1:]):
        parts[0][ks + 2 * i:ks + 2 * i + 2] = card_sum(p).to_bytes(2, "little")
    key = int.from_bytes(hashlib.sha256(b"".join(parts)).digest()[:2], "little") or 1
    parts[0][kk:kk + 2] = key.to_bytes(2, "little")
    s0 = card_sum(parts[0])
    image = b"".join(bytes(p) for p in parts)
    fr = CFG["free_runs"]["pregen_store"]
    n = len(kb) * SLOT
    sec = fr["sector"] + fr["count"] - n
    assert c["sector"] <= sec and sec + n == fr["sector"] + fr["count"] <= MIRROR
    run = [r for _k, r, _n in kb]
    CARDSYMS = (f"CMSEC = {sec}\nCMN = {len(kb)}\nCMBANK = ${run[0]:02X}\nCMADDR = ${c['addr']:02X}\nCMKEYA = ${sym['cmkey']:04X}\n"
                f"CMKEY = ${key:04X}\nCMSUM0 = ${s0:04X}\nCMSTG = $69\n")
    (build / "cardmod.inc").write_text(CARDSYMS)
    m["_image"], m["_cmsec"] = image, sec
    return image


def preload_syms(mods, rows, build, sym):
    q = [m for m in mods if m.get("preload")]
    if not q:
        return "PRELOAD = 0\n"
    q = q[0]
    o = [m for m in mods if m["name"] in q["preload"]][0]
    blk = q["blocks"][0]
    qrow = next(i for i, (m, b) in enumerate(rows) if m is q and b == blk)
    mrow = next(i for i, (m, b) in enumerate(rows) if m is o and b == blk)
    qsym = {}
    for line in (build / (Path(q["source"]).stem + ".sym")).read_text().splitlines():
        p = line.split()
        if len(p) >= 3 and re.fullmatch(r"[0-9a-f]{2}|-", p[0]) and re.fullmatch(r"[0-9a-f]{4}", p[1]):
            qsym[p[2]] = int(p[1], 16)
    return (f"PRELOAD = 1\nQSEC = {q['sector']}\nQBANK = ${q['bank']:02X}\nMSEC = {o['sector']}\nMBANK = ${o['bank']:02X}\nCSEC = {q['chunk2']}\n"
            f"CBK = ${q['chunk_bank']:02X}\nC4BK = ${qsym['SHBANK']:02X}\nC5BK = ${qsym['C5BANK']:02X}\nDL = ${sym['dl']:04X}\nQROW = {qrow}\nMROW = {mrow}\n"
            f"DGEN = ${sym['dgen']:04X}\nMGENA = ${qsym['mgen'] - 0xA000 + 0x8000:04X}\n"
            + (f"C6SEC = {q['chunk5']}\nC6LEN = ${qsym['C6LEN']:04X}\nC6CH = ${qsym['C6CH']:02X}\nCTIER = ${qsym['ctier']:04X}\n" if q.get("chunk5") else "C6SEC = 0\n")
            + (f"C7SEC = {q['chunk6']}\nC7LEN = ${qsym['C7LEN']:04X}\n" if q.get("chunk6") else "C7SEC = 0\n")
            + (f"C8SEC = {q['chunk7']}\nC8LEN = ${qsym['C8LEN'] + qsym.get('C9LEN', 0):04X}\n" if q.get("chunk7") else "C8SEC = 0\n")
            + (f"PGSEC = {qsym['PGSEC']}\nPGDIR = {qsym['PGDIR']}\nPGKEY = ${qsym['CBKEY']:04X}\nPGA = ${qsym['cidle']:04X}\nPGALEN = {qsym['bready'] - qsym['cidle']}\n"
               f"PGB = ${qsym['q8hdr']:04X}\nPGBLEN = {qsym['cup1'] - qsym['q8hdr']}\nBS_P5 = ${qsym['bs_p5']:04X}\nBS_PB = ${qsym['bs_pb']:04X}\nBS_LK = ${qsym['bs_lk']:04X}\n" if q.get("chunk7") and "pgfast" in qsym else "PGSEC = 0\n"))


def halt_blob(mods, build, sym, sbpart, rows, sbpart2=b""):
    (build / "haltsyms.inc").write_text(f"SBOK = ${sym['sbok']:04X}\nSBANK = ${sym['SBANK']:02X}\nSBGO = ${sym['sbgo']:04X}\n" + preload_syms(mods, rows, build, sym) + CARDSYMS)
    img, _ = assemble(ROOT / "src/syscard_halt.asm", build)
    code1 = img[0x800:0x1000].rstrip(b"\xff") if len(img) > 0x800 else b""
    code = img[:0x400].rstrip(b"\xff")
    assert code[0] == 0x4C and len(code) <= HALTMAX
    slot = code + bytes(HALTMAX - len(code)) + sbpart
    pieces = [m["_sbpiece"] for m in mods if m.get("_sbpiece")]
    if pieces:
        slot = slot + bytes(SBPIECE[0] - len(slot)) + pieces[0]
    if code1:
        slot = slot + bytes(0x800 - len(slot)) + code1
    ras = [m["_sbra"] for m in mods if m.get("_sbra")]
    if ras:
        slot = slot + bytes(0xC00 - len(slot)) + ras[0]
    if sbpart2:
        slot = slot + bytes(0x1000 - len(slot)) + sbpart2
    return slot


def write_disc(out, cue, dt, patched_bytes):
    out.mkdir(parents=True, exist_ok=True)
    for tr in cue:
        dst = out / tr["file"].name
        if dst.exists() or dst.is_symlink():
            dst.unlink()
        if tr is dt:
            dst.write_bytes(patched_bytes)
        else:
            try:
                os.link(tr["file"], dst)
            except OSError:
                shutil.copyfile(tr["file"], dst)
    shutil.copyfile(ROOT / ".local/disc.cue", out / "disc.cue")


def build_store_disc(out, cue, dt, patched, m, pd):
    sys.path.insert(0, str(ROOT / "tools/pregen"))
    import storestep
    fr = CFG["free_runs"]["pregen_store"]
    orig = dt["file"]
    a = out / dt["file"].name
    flags = [HALTSEC + 1, HALTSEC + 1 + MIRROR]
    mf = storestep.release_manifest(str(orig), str(a), m["_cbkey"], m.get("_seam"), pd, flags, PGFLAG_OFF, (fr["sector"], fr["count"]), notice=storestep.NOTICE)
    man = out.parent / f"{out.name}.store.json"
    man.write_text(storestep.dump_manifest(mf))
    man_sha = hashlib.sha256(man.read_bytes()).hexdigest()
    want_man = CFG.get("manifest_sha256")
    if want_man and man_sha != want_man:
        sys.exit(f"manifest sha256 {man_sha} differs from expected {want_man}")
    bdir = out.parent / f"{out.name}-store"
    write_disc(bdir, cue, dt, patched)
    b = bdir / dt["file"].name
    r = subprocess.run([sys.executable, str(ROOT / "tools/pregen/storestep.py"), "--manifest", str(man), "--store", str(orig), str(b)], capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"store step failed (exit {r.returncode}): {(r.stderr or r.stdout).strip()}")
    hb = hashlib.sha256(b.read_bytes()).hexdigest()
    want_b = CFG.get("store_track_sha256")
    if want_b and hb != want_b:
        sys.exit(f"store track sha256 {hb} differs from expected {want_b}")
    storestep.check_structure(str(orig), str(a), str(b), storestep.load_manifest(str(man)))
    print(f"{bdir}: store disc (sha256 {hb}); manifest {man.name} (sha256 {man_sha})")


def main():
    out = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "dist/disc"
    build = ROOT / "build"
    build.mkdir(parents=True, exist_ok=True)
    if not (ROOT / ".local/disc.cue").exists():
        sys.exit(".local/disc.cue not found: put your dump in .local/ (see README.md)")
    cfg = json.loads((ROOT / "src/modules.json").read_text())["disc"]
    for m in cfg:
        m["bank"], m["data_banks"] = int(m["bank"], 16), [int(d, 16) for d in m["data_banks"]]
        for k in ("bank2", "bank3", "bank4", "chunk_bank"):
            if m.get(k) is not None:
                m[k] = int(m[k], 16)
        m["blocks"] = m["block"] if isinstance(m["block"], list) else [m["block"]]
    cmods = [m for m in cfg if m.get("card")]
    mods = [m for m in cfg if not m.get("card")]
    code = lambda m: {m["bank"]} | ({m["bank2"]} if m.get("bank2") else set()) | ({m["bank3"]} if m.get("bank3") else set()) | ({m["bank4"]} if m.get("bank4") else set()) | ({m["chunk_bank"]} if m.get("chunk_bank") is not None and not m.get("chunks_checked") else set())
    writes = lambda m: code(m) | set(m["data_banks"])
    for p in (ROOT / "src").glob("*.inc"):
        shutil.copyfile(p, build / p.name)

    rows = [(m, b) for m in mods for b in m["blocks"]]
    mask = lambda want: sum(1 << j for j, (o, _b) in enumerate(rows) if want(o))
    dsame = [mask(lambda o, m=m: o is m) for m, _b in rows]
    dkill = [mask(lambda o, m=m: o is not m and bool(code(o) & writes(m))) for m, _b in rows]
    dsbk = [int(SBANK in writes(m)) for m, _b in rows]
    bands = any(m.get("bands") for m in mods)
    dlrow = "dl:\t.db " + ", ".join("0" for _r in rows) + "\n"
    (build / "directory.inc").write_text(
        f"NMOD = {len(rows)}\n"
        + "dblk:\t.db " + ", ".join(str(b) for _m, b in rows) + "\n"
        + "dbank:\t.db " + ", ".join(str(m["bank"]) for m, _b in rows) + "\n"
        + "".join(f"D2MOD = {i}\nD2BANK = {m['bank2']}\nD2SEC = {m['sector2']}\n" for i, (m, _b) in enumerate(rows) if m.get("bank2"))
        + "".join(f"D3BANK = {m['bank3']}\nD3SEC = {m['sector3']}\n" for i, (m, _b) in enumerate(rows) if m.get("bank3"))
        + ("" if any(m.get("bank3") for m, _b in rows) else "D3BANK = 0\nD3SEC = 0\n")
        + "".join(f"D4BANK = {m['bank4']}\n" for i, (m, _b) in enumerate(rows) if m.get("bank4"))
        + ("" if any(m.get("bank4") for m, _b in rows) else "D4BANK = 0\n")
        + ("" if any(m.get("bank2") for m, _b in rows) else "D2MOD = 255\nD2BANK = 0\nD2SEC = 0\n")
        + ("" if bands else dlrow))
    (build / "dirsec.inc").write_text(
        "\t.db " + ", ".join(str(m["sector"]) for m, _b in rows) + "\n"
        + "dsame:\t.db " + ", ".join(map(str, dsame)) + "\n"
        + "dkill:\t.db " + ", ".join(map(str, dkill)) + "\n"
        + "dsbk:\t.db " + ", ".join(map(str, dsbk)) + "\n"
        + (dlrow if bands else ""))

    ho = [(m, next(o for o in mods if o["name"] == m["handoff"]["from"])) for m in mods if m.get("handoff")]
    hsyms = f"HFROM = ${ho[0][1]['bank']:02X}\nHTO = ${ho[0][0]['bank']:02X}\nHSCA = {ho[0][0]['handoff']['scenes'][0]}\nHSCB = {ho[0][0]['handoff']['scenes'][1]}\n" if ho else "HFROM = 0\nHTO = 0\nHSCA = $FF\nHSCB = $FF\n"
    h2 = [(m, next(o for o in mods if o["name"] == m["handoff2"]["to"])) for m in mods if m.get("handoff2")]
    h2syms = f"H2FROM = ${h2[0][0]['bank']:02X}\nH2TO = ${h2[0][1]['bank']:02X}\nH2SCA = {h2[0][0]['handoff2']['scenes'][0]}\nH2SCB = {h2[0][0]['handoff2']['scenes'][1]}\n" if h2 else "H2FROM = 0\nH2TO = 0\nH2SCA = $FF\nH2SCB = $FF\n"

    img, sym = assemble(ROOT / "src/disc_boot.asm", build)
    assert sym["SBANK"] == SBANK
    (build / "stubsyms.inc").write_text(
        f"STUB_T0OK = ${sym['t0ok']:04X}\nSTUB_MHOOK = ${sym['mhook']:04X}\nSTUB_CURMOD = ${sym['curmod']:04X}\n"
        f"STUB_PREV = ${sym['prev']:04X}\nSTUB_BANDIRQ = ${sym.get('bandirq', 0):04X}\nSTUB_DGEN = ${sym['dgen']:04X}\n"
        f"STUB_OBJREC = ${sym.get('objrec', 0):04X}\nSTUB_GS = ${sym.get('gs', 0):04X}\n"
        f"STUB_SATW = ${stub_local(build, 'satwait', '.w'):04X}\nSTUB_ALLOCX = ${stub_local(build, 'allocstub', '.x'):04X}\n"
        + hsyms + h2syms + f"STUB_MCALL = ${sym['mcall']:04X}\n"
        + f"STUB_LASTMOD = ${sym['lastmod']:04X}\nSTUB_SATSKIP = ${sym['satskip']:04X}\n"
        + f"STUB_XCALL = ${sym['xcall']:04X}\nSTUB_XR = {sym['XR']}\nSTUB_XE = {sym['XE']}\n")
    for m in cmods:
        card_module(m, build, img)
    if not cmods:
        (build / "cardmod.inc").write_text("CMBANK = 0\n")

    blobs = [module_blob(m, build) for m in mods]
    sbpart = img[SBPART[0]:SBPART[1]].rstrip(b"\xff")
    sbpart2_raw = img[SBPART2[0]:SBPART2[1]].rstrip(b"\xff") if len(img) >= SBPART2[1] else b""
    sbpart2 = sbpart2_raw + bytes(0x400 - len(sbpart2_raw)) if sbpart2_raw else b""
    blob, blob2 = img[RUN1[0]:RUN1[1]].rstrip(b"\xff"), img[RUN2[0]:RUN2[1]]
    halt = halt_blob(mods, build, sym, sbpart, rows, sbpart2=sbpart2)

    cue = disc.parse_cue(ROOT / ".local/disc.cue")
    dt = disc.data_track(cue)
    trk = bytearray(disc.read_track(dt))
    if hashlib.sha256(trk).hexdigest() != CFG["baseline_sha256"]:
        sys.exit(f"{dt['file'].name}: not the dump this patch is made for (data track sha256 mismatch)")
    blobs = [site_proofs(m, rblob, trk, img, build) for m, rblob in zip(mods, blobs)]

    changed = set()
    sec, off, want = SITES["ipl_exec"]
    assert hashlib.sha256(user_bytes(trk, sec, off, 16)).hexdigest().startswith(want)
    put(trk, sec, off, sym["bootchk"].to_bytes(2, "little"), changed)
    for copy in (0, MIRROR):
        assert set(user_bytes(trk, 2 + copy, 0x6BA, len(blob))) == {0xFF}
        put(trk, 2 + copy, 0x6BA, blob, changed)
        assert set(user_bytes(trk, 452 + copy, 0x747, len(blob2))) == {0xFF}
        put(trk, 452 + copy, 0x747, blob2, changed)
        for site, target in HOOKS:
            if site not in SITES or target not in sym:
                continue
            sec, off, want = SITES[site]
            assert hashlib.sha256(user_bytes(trk, sec + copy, off, 16)).hexdigest().startswith(want)
            put(trk, sec + copy, off, bytes([0x20, sym[target] & 0xFF, sym[target] >> 8]), changed)
        assert not any(user_bytes(trk, HALTSEC + copy, 0, SLOT * USER))
        put(trk, HALTSEC + copy, 0, halt, changed)
        for m, rblob in zip(mods, blobs):
            put(trk, m["sector"] + copy, 0, rblob + bytes(m["count"] * USER - len(rblob)), changed)
            for ck, sec_k in (("_cold", "sector2"), ("_cold3", "sector3"), ("_cold4", "sector4")):
                if m.get(ck):
                    put(trk, m[sec_k] + copy, 0, m[ck] + bytes(SLOT * USER - len(m[ck])), changed)
            if m.get("chunk"):
                put(trk, m["chunk"] + copy, 0, m["_chunk"], changed)
            if m.get("chunk2"):
                put(trk, m["chunk2"] + copy, 0, m["_chunk2"] + bytes(USER - len(m["_chunk2"])), changed)
            for ck in ("chunk3", "chunk4", "chunk5", "chunk6", "chunk7"):
                if m.get(ck):
                    for k in range(2):
                        part = m["_" + ck][k * USER:(k + 1) * USER]
                        put(trk, m[ck] + k + copy, 0, part + bytes(USER - len(part)), changed)
    for m in cmods:
        put(trk, m["_cmsec"], 0, m["_image"], changed)
    store = None
    for m in mods:
        if m.get("_pgf"):
            ps, pd = m["_pgsec"], m["_pgdir"]
            put(trk, ps, 0, m["_pgf"] + bytes(USER - len(m["_pgf"])), changed)
            store = (m, pd)

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
    write_disc(out, cue, dt, patched)
    print(f"{out}: the patched disc")
    if store and CFG.get("store_track_sha256"):
        build_store_disc(out, cue, dt, patched, *store)


if __name__ == "__main__":
    main()
