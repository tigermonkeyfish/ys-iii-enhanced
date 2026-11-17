"""pack17.py TRACK02 WORKDIR OUT.bin [--cbkey=N]: room 17's Arcade Card store packed for the disc (the patch-time pipeline, step 3).

Runs extract17.py (entries cont18 and door: the two tile layouts) and store17.py (both scan sides of each) on the player's own track,
and packs what the console's power-on preload loads into the card (syscard_halt.asm) and its loader uses
(the module's quarry_pgfast.inc). Everything it writes is game data: WORKDIR and OUT.bin belong under an ignored folder (build/, dist/,
captures/), never in a commit, a patch or a document.

The variant choice: ONE set of images, and per variant only what differs, at the same offsets 8 card banks up. Measured on the four
stores (2 tile layouts x 2 scan sides): the images are equal; the layout changes only the templates (the room tile words' high
bytes); the scan side changes only the lists (the pairs' slot bytes); neither touches what the other does. The card engine takes a
region's templates and lists from two high bytes each (RTPH, RLBH), so the console picks the visit's variant by writing four bytes:
no fix-up on the card, no second copy of the images. pack() checks all of this on the player's own data and refuses otherwise.

OUT.bin, in 2,048-byte sectors (mkdisc writes it from sector PGDIR):
  sector 0, the directory: 'Y3PG', version 1, the build's key (2), the segments' count; then per segment 8 bytes: the card address
    (3), its sectors (1), the sum of its sectors' bytes (2, the console's page-fold sum), 0, 0; at +$40 the data sectors' count (2);
    at +$60 the SHA-256 of the data sectors; at +$80 per segment its length in bytes (4) and at +$A0 per segment its SHA-256 (32)
  then the segments' sectors in order, each segment filled with zeros to whole sectors:
    0: the block at $18:0000 (the key, rnpair, the layouts' tile bases, the four variants' headers: quarry_pgfast.inc's head)
    1: region 1 ($11:0000, the bridge) and 2: region 0 ($15:0000, band 1) of the base variant (the area layout scanned from the
       band's side), as the console builds them, headers included
    3: at $19:0000 region 1's door-layout templates (+ $0100) and open-quarry-side lists (+ $B000); 4: at $1D:0000 region 0's
       (+ $0100, + $4800)
    5, 6 (quarry-seams; only when mkdisc passes the seams' image): the image (our code, the card's C6CH:4000) and the set-up's
       background products at $1E:0000 (seam17.py: the pair images, band_setup's tables)
"""
import hashlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import extract17
import seam17
import store17
import store19
from store17 import Refusal, need              # a refusal is an error, never an assert: `python -O` drops asserts

SECTOR = 2048
VERSION = 1                                         # the directory's version byte: raise it when the builders' output changes for the
#                                                     same module image (the key is a hash of the module alone)
MAXSEGS = 16
OFF_N, OFF_SHA, OFF_LENS, OFF_SEGS = 0x90, 0xA0, 0xC0, 0x100  # own: field offsets in our Y3PG directory sector
PGBLOCK = 0x180000
ALT1, ALT0 = 0x190000, 0x1D0000                    # the other variants' templates and lists: region 1's, region 0's (8 banks up)
VARIANTS = (("cont18", "right"), ("cont18", "left"), ("door", "right"), ("door", "left"))   # 2 * layout + side


def fold_sum(b):
    """The console's sum (the preload's, as the builders' ksumr / q8sum): per 256-byte page the bytes added with the carry going
    round, then the page sums folded (low += page, high += low)."""
    lo = hi = 0
    for p in range(0, len(b), 256):
        a = c = 0
        for x in b[p:p + 256]:
            a += x + c
            c = a >> 8
            a &= 255
        a = (a + c) & 255
        lo = (lo + a) & 255
        hi = (hi + lo) & 255
    return lo | hi << 8


def pack(track, workdir, cbkey, log=print, code=None, xlog=print, r19=True):
    """the store's sectors (bytes) and their description. track: the untouched Track 02 (a file's name, or a pce.Track).
    workdir: a folder that also gets the extraction's files (game data: an ignored folder; mkdisc's build/pregen), or None:
    everything stays in memory and nothing is written (the patch-time step). code: (card address, bytes) of our code's segment.
    Raises store17.Refusal when the track's data is not what the builders were made for; the interpreter's own errors
    (ValueError, RuntimeError and others on a track that is not the untouched one) pass through."""
    x = extract17.extract(track, ["cont18", "door"], log=xlog, outdir=os.path.join(workdir, "x") if workdir else None)
    built = [store17.build(x[e], side, cbkey) for e, side in VARIANTS]
    R0, R1, C0 = store17.R0, store17.R1, store17.CARD0
    s0, card0, m0, m1 = built[0]
    e0, e1 = m0["end"], m1["end"]
    for s, card, a, b in built:
        need((a["end"], b["end"], a["images"], b["images"]) == (e0, e1, m0["images"], m1["images"]), "pack17: the variants' sizes differ")
    need(e1 <= R0 and e0 <= store17.CARD0 + 0x70000, "pack17: a region's images run past its card banks")
    # (region base, end, templates' count, lists' offset, alternate's card address): templates n x 1,056 at + $100, lists n x $800
    regs = ((R1, e1, 41, 0xB000, ALT1), (R0, e0, 17, 0x4800, ALT0))
    alts = []
    for base, end, n, lo, alt in regs:
        t0, t1, l0, l1 = 0x100, 0x100 + 1056 * n, lo, lo + 0x800 * n
        need(t1 <= l0 and base + l1 <= end, f"pack17: region at ${base:06X}: its templates and lists do not fit before its images' end")
        reg = [bytes(c[base - C0:end - C0]) for _s, c, _a, _b in built]            # the region in the four variants (2 layout + side)
        for v in range(4):
            want = bytearray(reg[0])
            want[t0:t1] = reg[2][t0:t1] if v & 2 else reg[0][t0:t1]                 # the door layout: the templates only
            want[l0:l1] = reg[1][l0:l1] if v & 1 else reg[0][l0:l1]                 # the open quarry's side: the lists only
            need(want[16:] == reg[v][16:], f"pack17: region at ${base:06X}, variant {v}: not the base with its templates / lists")
        a = bytearray(l1)
        a[t0:t1] = reg[2][t0:t1]
        a[l0:l1] = reg[1][l0:l1]
        alts.append((alt, bytes(a)))
    blk = bytearray(0x100)
    blk[0:8] = b"Y3PG" + bytes((VERSION, cbkey & 255, cbkey >> 8, m0["pairs"]))
    for lay, v in ((0, 0), (1, 2)):
        s = built[v][0]
        need((s.nw, s.mw, s.fw) == (built[v + 1][0].nw, built[v + 1][0].mw, built[v + 1][0].fw) and built[v][2]["pairs"] == m0["pairs"],
             "pack17: one layout's tile bases or pair counts differ between its two scan sides")
        blk[16 + 8 * lay:22 + 8 * lay] = bytes((s.nw & 255, s.nw >> 8, s.mw & 255, s.mw >> 8, s.fw & 255, s.fw >> 8))
    need(blk[16:22] != blk[24:30], "pack17: the two layouts' tile bases are equal")
    for v in range(4):
        c = built[v][1]
        blk[0x20 + 32 * v:0x30 + 32 * v] = c[R0 - C0:R0 - C0 + 16]
        blk[0x30 + 32 * v:0x40 + 32 * v] = c[R1 - C0:R1 - C0 + 16]
    segs = [(PGBLOCK, bytes(blk)), (R1, bytes(card0[R1 - C0:e1 - C0])), (R0, bytes(card0[R0 - C0:e0 - C0]))] + alts
    if code:                                        # (quarry-seams) the seams' image (our code, from mkdisc: card address, bytes) and its data: the
        segs += [code, (seam17.SEAM, seam17.build([b[0] for b in built]))]   # set-up's background products (seam17.py)
    if r19:
        segs += store19.build(track, log=xlog)
    need(len(segs) <= MAXSEGS, "pack17: the directory holds 16 segments")
    data = b""
    d = bytearray(SECTOR)
    d[0:8] = b"Y3PG" + bytes((VERSION, cbkey & 255, cbkey >> 8, len(segs)))
    for i, (addr, b) in enumerate(segs):
        n = -(-len(b) // SECTOR)
        padded = b + bytes(n * SECTOR - len(b))
        need(n < 256, "pack17: a segment of 256 sectors or more")
        d[8 + 8 * i:16 + 8 * i] = addr.to_bytes(3, "little") + bytes((n,)) + fold_sum(padded).to_bytes(2, "little") + bytes(2)
        d[OFF_LENS + 4 * i:OFF_LENS + 4 + 4 * i] = len(b).to_bytes(4, "little")
        d[OFF_SEGS + 32 * i:OFF_SEGS + 32 + 32 * i] = hashlib.sha256(b).digest()
        data += padded
    d[OFF_N:OFF_N + 2] = (len(data) // SECTOR).to_bytes(2, "little")
    d[OFF_SHA:OFF_SHA + 32] = hashlib.sha256(data).digest()
    info = dict(cbkey=cbkey, sectors=1 + len(data) // SECTOR, segments=[(a, len(b)) for a, b in segs], images=(m0["images"], m1["images"]),
                tags=["%04X" % built[v][2]["layout_tag"] for v in range(4)], sha256=hashlib.sha256(bytes(d) + data).hexdigest())
    log(f"pack17: {info['sectors']} sectors (directory 1; " + ", ".join(f"${a:06X} {-(-len(b) // SECTOR)}" for a, b in segs) + f"); images {m0['images']} + {m1['images']}; "
        f"tags {' '.join(info['tags'])}; key {cbkey:04X}; sha256 {info['sha256'][:16]}")
    return bytes(d) + data, info


def check(sectors, pgdir):
    """a store on a track against its own directory, with no reference: sectors(lba, n) reads user data (pce.Track.sectors),
    pgdir is the directory's sector. None when there is no directory there; else the version, the key, the data sectors' count,
    whether the count and the data's SHA-256 agree, and per segment whether its SHA-256, its sum and its zero padding agree."""
    d = sectors(pgdir, 1)
    if d[0:4] != b"Y3PG":
        return None
    nseg = d[7]
    out = dict(version=d[4], key=d[5] | d[6] << 8, data_sectors=d[OFF_N] | d[OFF_N + 1] << 8, segments=[])
    if not 1 <= nseg <= MAXSEGS:
        return dict(out, count_ok=False, data_sha256_ok=False)
    ent = [d[8 + 8 * i:16 + 8 * i] for i in range(nseg)]
    out["count_ok"] = sum(e[3] for e in ent) == out["data_sectors"]
    try:
        data = sectors(pgdir + 1, out["data_sectors"]) if out["count_ok"] else b""
    except ValueError:                              # past the end of the track
        return dict(out, count_ok=False, data_sha256_ok=False)
    out["data_sha256_ok"] = out["count_ok"] and hashlib.sha256(data).digest() == d[OFF_SHA:OFF_SHA + 32]
    at = 0
    for i, e in enumerate(ent):
        seg = data[at:at + e[3] * SECTOR]
        at += e[3] * SECTOR
        n = int.from_bytes(d[OFF_LENS + 4 * i:OFF_LENS + 4 + 4 * i], "little")
        fits = out["count_ok"] and (e[3] - 1) * SECTOR < n <= e[3] * SECTOR
        out["segments"].append(dict(card=int.from_bytes(e[0:3], "little"), sectors=e[3], bytes=n,
                                    sum_ok=out["count_ok"] and fold_sum(seg) == e[4] | e[5] << 8,
                                    sha256_ok=fits and hashlib.sha256(seg[:n]).digest() == d[OFF_SEGS + 32 * i:OFF_SEGS + 32 + 32 * i],
                                    padding_ok=fits and not any(seg[n:])))
    return out


def main(a):
    opt = dict(x[2:].split("=", 1) for x in a if x.startswith("--"))
    pos = [x for x in a if not x.startswith("--")]
    if len(pos) != 3:
        raise SystemExit(__doc__)
    try:
        blob, _info = pack(pos[0], pos[1], int(opt.get("cbkey", "0"), 0))
    except Refusal as e:
        raise SystemExit(str(e))
    open(pos[2], "wb").write(blob)


if __name__ == "__main__":
    main(sys.argv[1:])
