"""store19.py: Room 19's static Arcade Card tables built at patch time from the untouched Track 02.

Runs the unpatched game in pce.Machine into room 19 (via room 20's west exit, avoiding room 18's transition hook) to
capture the room's static inputs (near/mid maps, property table, compositor tile operands, backdrop VRAM tiles, and
settled BG palettes 0 and 15), then ports shaft19's four static Card builders (wbuild, eset, sstrm, s6wt1) cleanly
in pure stdlib Python 3.8+ (no numpy, no assert statements, no game data).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import extract17
import pce
from store17 import Refusal, need

CARD_WLST = 0x040000
CARD_WNS = 0x060000
CARD_WKEY = 0x067000
CARD_SWTA = 0x0B1800
CARD_EFIX = 0x0B8000
CARD_SSTRL0 = 0x0C0000
CARD_SSTRL2 = 0x0D0000
CARD_SKEYA = 0x0F5100

ENMAX = 120
EKEY_OFF = 0x7F00       # $0BFF00 relative to $0B8000
EFIX_BYTES = EKEY_OFF + 6
SECTOR = 2048

# Constants from shaft19's own source tables (xtab, x3, x7, xa)
XCQ = (
    14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 15, 14, 13, 12, 11, 10,
    12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 15, 14, 13, 12,
    10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 15, 14,
)
E6Q = (15, 14, 13, 12, 11, 10, 9, 8)
Q5M = (0, 33, 66, 99)
SBAR = bytes((0xFF, 0) * 8 + (0,) * 16)  # own: solid color-1 tile bitplanes for our side-border blackout


def _fold_add(s0, s1, v):
    s0 = (s0 + v) & 255
    s1 = (s1 + s0) & 255
    return s0, s1


def _words_to_bytes(v):
    out = bytearray(len(v) * 2)
    for i, w in enumerate(v):
        out[2 * i] = w & 255
        out[2 * i + 1] = w >> 8
    return bytes(out)


def _tile(vram, word):
    idx = word & 0x7FF
    if idx == 0x0C5:
        return bytes(32)
    return vram[idx * 32:(idx + 1) * 32]


def extract(track, k=40000, log=print):
    """Run the unpatched game into room 19 and return its static setup inputs."""
    tr = track if isinstance(track, pce.Track) else pce.Track(track, extract17.IPL_SHA, lazy=True)
    own_track = tr is not track
    try:
        mc = extract17.boot(tr, k)
        M = mc.cpu.M
        M[extract17.SCENE], M[extract17.PREV] = 20, 0xFF
        M[extract17.ENTX], M[extract17.ENTY], M[extract17.ENTF] = 0x06, 0x0B, 3  # own: room-19 top-door entry parameters for extract17
        extract17.run_until(mc, k, lambda: extract17.lit(mc, 20), 1500, "room 20 lit")

        mc.pad = extract17.PAD["left"]
        extract17.run_until(mc, k, lambda: M[extract17.SCENE] == 19, 1500, "walk left into room 19")
        mc.pad = 0
        mc.vmark[:] = bytes(0x8000)
        extract17.run_until(mc, k, lambda: extract17.lit(mc, 19), 1500, "room 19 lit")

        c = mc.cpu
        c.sync()
        b81 = bytes(c.banks[mc.RAMBANK + 1])
        seen = []

        def at_row():
            if c.mpr[3] == mc.RAMBANK + 1 and not seen:
                if (c.M[0x6CE7] & 0xF0) == 0xC0 and c.M[0x6D0B] == 0 and c.M[0x6D0C] == 0xD0:
                    pptr = c.M[0x2059] | (c.M[0x205A] << 8)
                    seen.append((
                        c.mpr[6] & 255,
                        bytes(c.M[pptr + i] for i in range(128)),
                        c.M[0x6CF2],
                        (c.M[0x6CF7] + c.M[0x6CF9]) & 255,
                        c.M[0x6D11],
                        c.M[0x6D18],
                    ))

        bp = c.setbp(extract17.ROWCALL, at_row, b81[extract17.ROWCALL - 0x6000])
        for _ in range(60):
            mc.frame(k)
        c.clrbp(*bp)
        need(bool(seen), "store19: row 0 layout pointers did not match at ROWCALL")

        c.sync()
        wbank, prop, nlo, nhs, mid_lo, mid_hi = seen[0]

        wmem = c.banks[wbank]
        mapb = bytes(wmem[0x0000:0x1100])
        mid = b"".join(bytes(wmem[0x1000 + 256 * r:0x1000 + 256 * r + 32]) for r in range(16))
        vram = _words_to_bytes(mc.vram)
        pal0 = list(mc.pal[0:16])
        pal15 = list(mc.pal[240:256])

        need(pal0[0] == pal0[1], "store19: BG palette 0 entries 0 and 1 differ")
        need(any(c_val == 0 for c_val in pal15), "store19: BG palette 15 has no black colour for side bars")

        if log:
            log(f"store19: extracted room 19 at frame {mc.frames} (wbank ${wbank:02X}, nlo=${nlo:02X}, nhs=${nhs:02X}, mid=${mid_hi:02X}{mid_lo:02X})")
        return dict(nlo=nlo, nhs=nhs, mid_lo=mid_lo, mid_hi=mid_hi, mapb=mapb, mid=mid, prop=prop, vram=vram, pal0=pal0, pal15=pal15)
    finally:
        if own_track:
            tr.close()


def _build_ksw(inp):
    nlo, nhs, prop = inp["nlo"], inp["nhs"], inp["prop"]
    ksw = [0] * 256
    for x in range(256):
        y = x & 0x7F
        if (prop[y] & 0x80) and y == 0:
            ksw[x] = 0x00C5
        else:
            s = y + nlo
            lo = s & 255
            hi = (nhs + (s >> 8)) & 255
            ksw[x] = lo | (hi << 8)
    return ksw


def _build_sw(inp):
    mid_lo, mid_hi, mid = inp["mid_lo"], inp["mid_hi"], inp["mid"]
    sw = [0] * 512
    for i, mv in enumerate(mid):
        s = mv + mid_lo
        lo = s & 255
        hi = (0x10 + mid_hi + (s >> 8)) & 255
        sw[i] = lo | (hi << 8)
    return sw


def _build_wbuild(inp, ksw):
    """Build WLST ($040000), WNS ($060000), and WKEY ($067000)."""
    mapb, prop, vram = inp["mapb"], inp["prop"], inp["vram"]
    ocw = [0] * 256
    occ = [0] * 256
    for x in range(256):
        y = x & 0x7F
        if prop[y] & 0x80:
            occ[x] = 1
            ocw[x] = 16 if y else 1
        else:
            t = _tile(vram, ksw[x])
            see = 0
            for r in range(8):
                b = t[2 * r] | t[2 * r + 1] | t[16 + 2 * r] | t[17 + 2 * r]
                if b != 0xFF:
                    see = 16
                    break
            ocw[x] = see

    s0 = s1 = 0
    for x in range(256):
        s0, s1 = _fold_add(s0, s1, ocw[x])
        s0, s1 = _fold_add(s0, s1, occ[x])
    for b in mapb:
        s0, s1 = _fold_add(s0, s1, b)
    wkey = bytes((0x19, 0x8C, 1, s0, s1))  # own: our shaft19 wall-list store header signature

    wlst = bytearray(132 * 512)
    wns = bytearray(132 * 128)

    for oc in range(4):
        oy1 = 2 + (oc & 1)
        ob = 8 + ((oc >> 1) & 1)
        okw = [0] * 64
        oks = [0] * 64
        okb = [0] * 64

        def addrow(row, sign):
            base = row * 64
            has_occ = row < 64
            for oa in range(oy1):
                rb = base + oa
                for x in range(63):
                    v = mapb[rb + x]
                    w = ocw[v]
                    if w == 1:
                        okw[x] += sign
                    elif w != 0:
                        oks[x] += sign
                    if has_occ and occ[v]:
                        okb[x] += sign

        for oy0 in range(ob):
            addrow(oy0, 1)

        for owy in range(58):
            if owy > 0:
                addrow(owy - 1, -1)
                addrow(owy + ob - 1, 1)
            for ocx in range(33):
                oml = [0] * 29
                omh = [0] * 29
                for col in range(16):
                    wx = ocx + 2 * col
                    if (okb[wx] | oks[wx]) == 0:
                        continue
                    bkt = 28 if oks[wx] else okw[wx]
                    need(0 <= bkt <= 28, "store19: wbuild bucket count out of range")
                    if col < 8:
                        oml[bkt] |= 1 << col
                    else:
                        omh[bkt] |= 1 << (col - 8)
                olb = bytearray(8)
                onp = 0

                def emit_mask(mask, off):
                    nonlocal onp
                    for bit in range(8):
                        if (mask >> bit) & 1:
                            col = bit + off
                            if onp & 1:
                                olb[onp >> 1] |= col << 4
                            else:
                                olb[onp >> 1] = col
                            onp += 1

                if oml[28]:
                    emit_mask(oml[28], 0)
                if omh[28]:
                    emit_mask(omh[28], 8)
                ons = onp
                for bkt in range(27, -1, -1):
                    if oml[bkt]:
                        emit_mask(oml[bkt], 0)
                    if omh[bkt]:
                        emit_mask(omh[bkt], 8)

                om = Q5M[oc] + ocx
                wlst[512 * om + 8 * owy:512 * om + 8 * owy + 8] = olb
                wns[128 * om + 2 * owy] = onp
                wns[128 * om + 2 * owy + 1] = ons

    return bytes(wlst), bytes(wns), wkey


def _build_eset(inp, ksw):
    """Build EFIX + ekey ($0B8000..$0BFF05)."""
    mapb, vram = inp["mapb"], inp["vram"]
    xd_pm = 12  # XBAR=0: the rails' colour maps to index 12 in XPAL
    ybb = [0] * 24
    xnm = [0] * 6
    for yk in range(6):
        yt2 = 0
        for b in range(8):
            r = XCQ[8 * yk + b]
            if r == 255:
                yt2 = ((yt2 << 1) | 1) & 255
                for p in range(4):
                    ybb[4 * yk + p] = (ybb[4 * yk + p] << 1) & 255
            else:
                yt2 = (yt2 << 1) & 255
                for p in range(4):
                    ybb[4 * yk + p] = ((ybb[4 * yk + p] << 1) | ((xd_pm >> p) & 1)) & 255
        xnm[yk] = yt2

    eb6 = [0] * 4
    for _y in range(8):
        for p in range(4):
            eb6[p] = ((eb6[p] << 1) | ((xd_pm >> p) & 1)) & 255

    # XD_VMAP: collapse all transparent ($00C5) near values to the first one
    vmap = list(range(256))
    first_tr = None
    for x in range(256):
        if ksw[x] == 0x00C5:
            if first_tr is None:
                first_tr = x
            vmap[x] = first_tr

    seen_near = bytearray(256)
    for b in mapb:
        seen_near[b] = 1

    key_to_idx = [0] * 256
    ekv = []
    for x in range(256):
        if not seen_near[x]:
            continue
        kv = vmap[x]
        if not key_to_idx[kv]:
            need(len(ekv) < ENMAX, "store19: eset image index count exceeds ENMAX")
            ekv.append(kv)
            key_to_idx[kv] = len(ekv)

    en = len(ekv)
    es0 = es1 = 0
    es0, es1 = _fold_add(es0, es1, en)

    efix = bytearray(EFIX_BYTES)
    tiles = [_tile(vram, ksw[kv]) for kv in ekv]
    for kv, t in zip(ekv, tiles):
        es0, es1 = _fold_add(es0, es1, kv)
        for tb in t:
            es0, es1 = _fold_add(es0, es1, tb)
    for xb in ybb:
        es0, es1 = _fold_add(es0, es1, xb)
    for xb in xnm:
        es0, es1 = _fold_add(es0, es1, xb)
    for xb in eb6:
        es0, es1 = _fold_add(es0, es1, xb)

    ekey = bytes((0x19, 0xE4, 1, en, es0, es1))  # own: our shaft19 edge-cache store header signature
    pages = [(0xFF, 0, 0, 0, 0), (0x00, eb6[0], eb6[1], eb6[2], eb6[3])]
    for ep in range(6):
        pages.append((xnm[ep], ybb[4 * ep], ybb[4 * ep + 1], ybb[4 * ep + 2], ybb[4 * ep + 3]))

    for ei, t in enumerate(tiles):
        base = 256 * ei
        for pg, (xm, xb0, xb1, xb2, xb3) in enumerate(pages):
            p = base + 32 * pg
            for k in range(0, 16, 2):
                efix[p + k] = (t[k] & xm) | xb0
                efix[p + k + 1] = (t[k + 1] & xm) | xb1
            for k in range(16, 32, 2):
                efix[p + k] = (t[k] & xm) | xb2
                efix[p + k + 1] = (t[k + 1] & xm) | xb3

    efix[EKEY_OFF:EKEY_OFF + 6] = ekey
    return bytes(efix)


def _build_s6str(inp, sw):
    """Build SSTRL ($0C0000, $0D0000), SWTA ($0B1800), and SKEYA+SDLA ($0F5100)."""
    vram = inp["vram"]
    tiles = [_tile(vram, w) for w in sw]

    # skeyc checksum: per cell r in 0..15, c in 0..31: lo, hi, 32 tile bytes
    s0 = s1 = 0
    for i in range(512):
        w = sw[i]
        s0, s1 = _fold_add(s0, s1, w & 255)
        s0, s1 = _fold_add(s0, s1, w >> 8)
        for tb in tiles[i]:
            s0, s1 = _fold_add(s0, s1, tb)
    skey_sdla = bytes((0x19, 0xF1, 4, s0, s1)) + bytes(12)  # own: our shaft19 sprite-drop store header signature

    # sstrm: 4 phases * 33 columns * 576 bytes, split across $0C0000 (p=0,1) and $0D0000 (p=2,3)
    lsh = [[0] * 256 for _ in range(4)]
    rsh = [[0] * 256 for _ in range(4)]
    for p in range(4):
        for x in range(256):
            rsh[p][x] = x >> (2 * p)
            lsh[p][x] = 0 if p == 0 else (x << (8 - 2 * p)) & 255

    parts = [bytearray(2 * 33 * 576), bytearray(2 * 33 * 576)]
    for p in range(4):
        dst = parts[p >> 1]
        p_off = (p & 1) * 33 * 576
        lp, rp = lsh[p], rsh[p]
        for cc in range(33):
            c_off = p_off + 576 * cc
            for r in range(16):
                lt = SBAR if cc == 0 else tiles[32 * r + cc - 1]
                rt = SBAR if cc == 32 else tiles[32 * r + cc]
                off_a = c_off + 16 * r + 16
                off_b = off_a + 288
                for y in range(16):
                    dst[off_a + y] = lp[lt[y]] | rp[rt[y]]
                    dst[off_b + y] = lp[lt[16 + y]] | rp[rt[16 + y]]

    # s6wt1: SWTA (16 phases * 561 windows * 2 bytes = 17952 bytes)
    s6t8 = bytearray(18 * 34)
    for x in range(34):
        s6t8[x] = 0xFE
        s6t8[578 + x] = 0xFE
    for r in range(1, 17):
        s6t8[34 * r] = 0xFD
        s6t8[34 * r + 33] = 0xFD

    tile_to_code = {}
    sk = 0
    sov = 0
    for n in range(512):
        t = tiles[n]
        code = tile_to_code.get(t)
        if code is None:
            if sk >= 0xFD:
                sov += 1
                code = 0
            else:
                code = sk
                tile_to_code[t] = code
                sk += 1
        r = n >> 5
        c = n & 31
        s6t8[(r + 1) * 34 + (c + 1)] = code

    swta = bytearray(16 * 1122)
    out_i = 0
    for swph6 in range(16):
        p = swph6 >> 2
        q = swph6 & 3
        names = {}
        next_id = 0
        for cc in range(33):
            for rr in range(17):
                base = rr * 34 + cc
                d = s6t8[base + 35]
                c_b = s6t8[base + 34] if p else 0xFF
                b_b = s6t8[base + 1] if q else 0xFF
                a_b = s6t8[base] if (p and q) else 0xFF
                if sov:
                    wid = 17 * cc + rr
                else:
                    key4 = (a_b, b_b, c_b, d)
                    wid = names.get(key4)
                    if wid is None:
                        wid = next_id
                        names[key4] = wid
                        next_id += 1
                swta[out_i] = wid & 255
                swta[out_i + 1] = wid >> 8
                out_i += 2

    return bytes(parts[0]), bytes(parts[1]), bytes(swta), skey_sdla


def build(track, log=print):
    """Build Room 19's 8 static Arcade Card store segments from the untouched Track 02."""
    inp = extract(track, log=log)
    ksw = _build_ksw(inp)
    sw = _build_sw(inp)
    wlst, wns, wkey = _build_wbuild(inp, ksw)
    efix = _build_eset(inp, ksw)
    sstr0, sstr2, swta, skey_sdla = _build_s6str(inp, sw)
    segs = [
        (CARD_WLST, wlst),
        (CARD_WNS, wns),
        (CARD_WKEY, wkey),
        (CARD_SWTA, swta),
        (CARD_EFIX, efix),
        (CARD_SSTRL0, sstr0),
        (CARD_SSTRL2, sstr2),
        (CARD_SKEYA, skey_sdla),
    ]
    if log:
        secs = sum(-(-len(b) // SECTOR) for _a, b in segs)
        log(f"store19: {len(segs)} segments, {secs} sectors ({sum(len(b) for _a, b in segs)} bytes)")
    return segs
