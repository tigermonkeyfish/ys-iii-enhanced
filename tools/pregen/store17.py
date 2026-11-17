"""store17.py EXTRACT_DIR OUT_DIR [--side=right|left] [--cbkey=N] [--gen=N] [--bld=N]: room 17's Arcade Card store computed on the PC
from extract17.py's output alone (vram.bin, cdram.bin, ram.bin, manifest.json of one entry), byte for byte as the console builds it
(the quarry's patch-time pipeline, step 2). A port of the module's own set-up and builders (the module's quarry.asm: the slot scans,
band_setup, bpal, einit2, negen, midsetup; quarry_card7.inc: region 0, band 1's store; quarry_card8.inc and q8maps: region 1, the
bridge's store). Nothing of the game is in this file: maps, tiles and palettes come from EXTRACT_DIR at run time; the output is game
data and belongs under an ignored folder, never in a commit.

Output: OUT_DIR/card.bin (the card's $10:0000-$17:FFFF as the console leaves it once both stores are sealed), region0.bin
($15:0000 to the end of its images), region1.bin ($11:0000 to the end of its images), palette.bin (the game's palette copy
$3C00-$3DFF with the set-up's merged palettes 3, 4, 5, 6, 7 in it: what the images' colour indices mean), manifest.json (sizes,
counts, tags, SHA-256).

What is not the track's and is passed in: --side (the near slots are numbered as first seen from the side the room is entered:
right = the door / camera 480 and more, left = the open quarry's entry), --cbkey (the build's key, header bytes 5-6: the console
compares it with its own), --gen / --bld (the key table's generation and the rank table's build stamp: 1 / 1 on the first build of
a power-on). Standard library only."""
import hashlib
import json
import os
import sys
import time

KMAX, MKMAX, NCOLS, MCOLS = 252, 64, 136, 96
NOSLOT, EDGEA, EDGEB = 0xFF, 0xFE, 0xFD  # own: sentinel slot markers in our quarry card store
NEMAX, NOGC, BMC0, BMCN, MGN = 21, 127, 40, 26, 45
PALF, PALM, PALX, MIXHI = 6, 7, 4, 0x06            # the merged palettes; the mix tiles' high bits (MIXBASE $680)
CARD0 = 0x100000                                    # card.bin's first byte on the card
R0, R0TPL, R0LB, R0IMG, KT, RT = 0x150000, 0x150100, 0x154800, 0x15D000, 0x170000, 0x17A000
R1, R1TPL, R1LB, R1IMG, HT = 0x110000, 0x110100, 0x11B000, 0x130000, 0x100000
NPER0, CN0, NPER1, CNB0 = 17, 80, 41, 39
NFKEYS = 42 * 192
KTN = NFKEYS + 42 * 90
# the band's mid groups' first tiles (the module's borrowed VRAM runs: ours, not the game's)
XR0 = [0x655, 0x656, 0x657, 0x658, 0x659, 0x65A, 0x57C]   # (quarry-band1-lastcells) sxt's regions: band mid groups 43-44, OT 34; MIXX
XR1 = [0x678, 0x679, 0x67A, 0x67B]
MG = [0x5A0 + 3 * i for i in range(10)] + [0x5E0 + 3 * i for i in range(10)] + [0x607 + 3 * i for i in range(9)] + \
     [0x628 + 3 * i for i in range(6)] + [0x63D + 3 * i for i in range(6)] + [0x64F + 3 * i for i in range(4)]


class Refusal(Exception):
    """the track's data is not what these builders were made for: nothing is produced (never an assert: `python -O` must refuse too)"""


def need(ok, why):
    if not ok:
        raise Refusal(why)


SHL = [bytes((v << d) & 255 for v in range(256)) for d in range(8)]
SHR = [bytes(v >> (8 - d) for v in range(256)) for d in range(8)]


def recolour(src, cmap):
    """a tile's 32 bytes (VRAM order: planes 0 / 1 by row, then 2 / 3) with every pixel's colour index sent through cmap"""
    out = bytearray(32)
    for r in range(0, 16, 2):
        b0, b1, b2, b3 = src[r], src[r + 1], src[r + 16], src[r + 17]
        o0 = o1 = o2 = o3 = 0
        for x in range(7, -1, -1):
            c = cmap[(b0 >> x & 1) | (b1 >> x & 1) << 1 | (b2 >> x & 1) << 2 | (b3 >> x & 1) << 3]
            o0 = o0 << 1 | (c & 1)
            o1 = o1 << 1 | (c >> 1 & 1)
            o2 = o2 << 1 | (c >> 2 & 1)
            o3 = o3 << 1 | (c >> 3 & 1)
        out[r], out[r + 1], out[r + 16], out[r + 17] = o0, o1, o2, o3
    return bytes(out)


class Setup:
    """the module's tables as its set-up leaves them (T1's slots and far words, PROP2, NEIDX and the near-end parts, FT, the band's mid
    pairs, the merged palettes), from the extraction"""

    def __init__(self, d, side="right"):
        if isinstance(d, tuple):                                                # extract17.extract's (files, manifest): in memory
            files, man = d
            self.vram, cd, ram, reg = files["vram.bin"], files["cdram.bin"], files["ram.bin"], man["regions"]
        else:                                                                   # extract17.py's output folder for one entry
            def rd(n):
                with open(os.path.join(d, n), "rb") as f:
                    return f.read()
            self.vram, cd, ram = rd("vram.bin"), rd("cdram.bin"), rd("ram.bin")
            reg = json.loads(rd("manifest.json").decode())["regions"]
        op, pages = reg["operands"], reg["pages"]
        bank = lambda b: cd[(b - 0x80) * 0x2000:(b - 0x7F) * 0x2000]            # noqa: E731
        if reg["map_bank"] != pages[6] or not 0x80 <= pages[4] <= 0x87:
            raise Refusal("store17: the extraction's pages are not room 17's as the module sees them")
        mapb, b4 = bank(reg["map_bank"]), bank(pages[4])
        self.nw = op["near_base"]                                               # word = code + base (near: palette 0)
        self.mw = op["mid_base"] + 0x1000
        self.fw = op["far_base"] + 0x2000
        self.nlo, self.nhi, self.mlo, self.mhi, self.flo = self.nw & 255, self.nw >> 8, self.mw & 255, self.mw >> 8, self.fw & 255
        self.near = [mapb[256 * r:256 * r + 256] for r in range(16)]
        self.mid = [mapb[0x1000 + 256 * r:0x1000 + 256 * r + 256] for r in range(16)]
        if "far_row0_ptr" not in op:
            raise Refusal("store17: the extraction has no far_row0_ptr (made by an older extract17.py: run it again)")
        pp, fp = reg["property_ptr"] - 0x8000, op["far_row0_ptr"] - 0x8000       # (far_ptr itself is the row the frame's end fell in)
        if not (0 <= pp <= 0x1F80 and 0 <= fp <= 0x1E00):
            raise Refusal("store17: the property table or the far map is not in the bank at MPR4")
        self.prop = b4[pp:pp + 128]
        isnear = [not (p & 0x80) for p in self.prop]
        self.isnear = isnear
        # the far words: 16 rows x 33 screen columns (the map is 32 wide: column 32 is column 0 again)
        self.FW = [[(b4[fp + 32 * r + (j & 31)] + self.fw) & 0xFFFF for j in range(33)] for r in range(16)]
        # the near slots, as first seen in the scan's order (columns from the entry's side, rows 0-15 in each)
        self.side = side
        self.nslot = [bytearray(b"\xFF" * 256) for r in range(16)]
        seen = {}
        for c in (range(NCOLS - 1, -1, -1) if side == "right" else range(NCOLS)):
            for r in range(16):
                a, b = self.near[r][c] & 0x7F, self.near[r][c + 1] & 0x7F
                if not isnear[a]:
                    v = EDGEB if isnear[b] else NOSLOT
                elif not isnear[b]:
                    v = EDGEA
                else:
                    v = seen.get((a, b))
                    if v is None:
                        v = EDGEA
                        if len(seen) < KMAX:
                            v = seen[(a, b)] = len(seen)
                self.nslot[r][c] = v
        self.nk = len(seen)
        self.mslot = [bytearray(b"\xFF" * 128) for r in range(16)]
        seen = {}
        for c in range(MCOLS):
            for r in range(16):
                a, b = self.mid[r][c], self.mid[r][c + 1]
                if not a:
                    v = EDGEB if b else NOSLOT
                elif not b:
                    v = EDGEA
                else:
                    v = seen.get((a, b))
                    if v is None:
                        v = EDGEA
                        if len(seen) < MKMAX:
                            v = seen[(a, b)] = len(seen)
                self.mslot[r][c] = v
        self.mk = len(seen)
        # the palettes: the game's copy ($3C00, 32 bytes a palette), then ours: 5 / 3 / 4 (einit2), PALF / PALM (bpal)
        pal = bytearray(ram[0x1C00:0x1E00])
        for k, (la, lb) in enumerate(((0, 2), (0, 1), (1, 2))):
            col = []
            for layer in (la, lb):
                for i in range(1, 16):
                    if (0x1BBE, 0x01FE, 0x01FE)[layer] >> i & 1:
                        w = bytes(pal[32 * layer + 2 * i:32 * layer + 2 * i + 2])
                        if w not in col and len(col) < 15:
                            col.append(w)
            p = (5, 3, PALX)[k]
            for i in range(1, 16):
                pal[32 * p + 2 * i:32 * p + 2 * i + 2] = col[i - 1] if i <= len(col) else b"\0\0"
        self.nmap = []
        for base, p in ((2, PALF), (1, PALM)):
            pal[32 * p:32 * p + 32] = pal[32 * base:32 * base + 32]
            free, m = 9, [0] * 16
            for i in range(1, 16):
                w = bytes(pal[2 * i:2 * i + 2])
                for x in range(1, 9):
                    if bytes(pal[32 * p + 2 * x:32 * p + 2 * x + 2]) == w:
                        m[i] = x
                        break
                else:
                    if free >= 16:
                        m[i] = 15
                    else:
                        pal[32 * p + 2 * free:32 * p + 2 * free + 2] = w
                        m[i] = free
                        free += 1
            self.nmap.append(m)
        self.pal = bytes(pal)
        # the colour maps of region 1's composer (q8maps): near -> PALF, near -> PALM, near -> PALX, mid -> PALX, far -> PALX
        self.q8M = []
        for sp, dp in ((0, PALF), (0, PALM), (0, PALX), (1, PALX), (2, PALX)):
            m = [0] * 16
            for i in range(1, 16):
                lo, hi = pal[32 * sp + 2 * i], pal[32 * sp + 2 * i + 1]
                for x in range(15, 0, -1):
                    if pal[32 * dp + 2 * x] == lo and not (pal[32 * dp + 2 * x + 1] ^ hi) & 1:
                        m[i] = x
                        break
            self.q8M.append(m)
        m = self.q8M[2]
        m[1] = 0                                    # the backdrop's colour, found in palette PALX's spare entry: the backdrop itself
        if not m[2]:
            m[2] = 15                               # the near's colour 2: palette PALX's spare entry 15 (the draw row loads it)
        if not m[9]:
            m[9] = 4                                # the near's colour 9: its nearest entry (q8build)
        # NEIDX and the near-end parts (band_setup's scan: rows 0-15, columns 80-128; negen)
        self.NEIDX = bytearray(b"\xFF" * 128)
        self.NE = []
        for r in range(16):
            for c in range(80, 129):
                a, b = self.near[r][c] & 0x7F, self.near[r][c + 1] & 0x7F
                if isnear[a] == isnear[b]:
                    continue
                t = a if isnear[a] else b
                if self.NEIDX[t] != 0xFF or len(self.NE) >= NEMAX:
                    continue
                self.NEIDX[t] = len(self.NE)
                src = self.tile(self.nw + t)
                parts = {}
                for p in (0, 1):
                    rc = recolour(src, self.nmap[p])
                    for sd in (0, 1):
                        parts[sd, p] = [bytes((SHL, SHR)[sd][2 * pn][v] for v in rc) for pn in (1, 2, 3)]
                self.NE.append(parts)
        # FT: the far tiles' patterns from the far base (a multiple of 16)
        fb = self.fw & 0x7F0
        self.FT = [self.tile(fb + f) for f in range(184)]
        # the band's mid pairs (rows 13-15, mid columns 40-65): pattern indices, pairs, the table by cell
        self.TPC, self.PAI, self.PBI = [], [], []
        self.BMS = bytearray(b"\xFF" * 96)

        def ftile(code):
            if code in self.TPC:
                return self.TPC.index(code)
            if len(self.TPC) < 40:
                self.TPC.append(code)
                return len(self.TPC) - 1
            return 40
        for r in range(3):
            for c in range(BMCN):
                a = self.mid[13 + r][BMC0 + c]
                if not a:
                    continue
                ia = ftile(a)
                b = self.mid[13 + r][BMC0 + c + 1]
                if not b:
                    continue
                ib = ftile(b)
                pr = list(zip(self.PAI, self.PBI))
                if (ia, ib) in pr:
                    x = pr.index((ia, ib))
                elif len(pr) < MGN:
                    x = len(pr)
                    self.PAI.append(ia)
                    self.PBI.append(ib)
                else:
                    continue
                self.BMS[32 * r + c] = x
        self.npair = len(self.PAI)
        self.TPAT = [self.tile(self.mw + c) for c in self.TPC]

    def tile(self, word):
        t = (word & 0x7FF) * 32
        return self.vram[t:t + 32]

    def tags(self):
        """the content tag and the layout tag (kltag): 16-bit byte sums"""
        t = sum(sum(self.near[r][80:131]) for r in range(16)) + sum(sum(self.mid[r][40:68]) for r in (13, 14, 15))
        t += sum(self.NEIDX) + self.flo + self.npair
        lt = t + sum(sum(self.nslot[r][80:131]) for r in range(16)) + self.nlo + self.nhi + self.mlo + self.mhi
        return t & 0xFFFF, lt & 0xFFFF


def a3(addr):
    return bytes((addr & 255, addr >> 8 & 255, addr >> 16))


def cardsum(card, start, pages):
    """the stores' sum: a page's bytes added with the carry going round, the page sums folded (low += s, high += low)"""
    lo = hi = 0
    o = start - CARD0
    for p in range(pages):
        a = c = 0
        for b in card[o:o + 256]:
            a += b + c
            c = a >> 8
            a &= 255
        lo = (lo + ((a + c) & 255)) & 255
        hi = (hi + lo) & 255
        o += 256
    return lo, hi


def region0(s, card, cbkey, gen, bld):
    """band 1's store (quarry_card7.inc's kbuild, a full build): near columns 80-96"""
    def w(addr, data):
        card[addr - CARD0:addr - CARD0 + len(data)] = data
    card[R0 - CARD0] = 0
    w(KT, b"\xFF" * (((KTN * 3 + 31) // 32) * 32))
    for g in range(s.npair):                                                    # every band mid pair's phases 1-7
        A, B = s.TPAT[s.PAI[g]], s.TPAT[s.PBI[g]]
        for d in range(1, 8):
            w(R0IMG + 32 * (7 * g + d - 1), bytes(SHL[d][A[y]] | SHR[d][B[y]] for y in range(32)))
    nimg = 7 * s.npair
    err = 0
    nb, mb, fb = s.nw, s.mw, s.flo
    pend, mfst = [], []
    for P in range(NPER0):
        cn = CN0 + P
        cm, ch = cn >> 1, cn & 1
        lb = R0LB + 0x800 * P
        ranks, oranks, org = [], {}, []
        mfq, erows = [], []
        pp, pe, pm = lb + 0x10, lb + 0x200, lb + 0x440
        for r in range(16):
            nrow, srow = s.near[r][cn:cn + 34], s.nslot[r][cn:cn + 33]
            mrow = s.mid[r][cm:cm + 34] if r >= 13 else None
            row = list(s.FW[r])
            pairs, ends, mids = bytearray(), bytearray(), bytearray()

            def grp(j):
                t = cm + j - BMC0
                return s.BMS[32 * (r - 13) + t] if 0 <= t < BMCN else 0xFF

            def under(j):
                if r < 13:
                    return
                a, b = mrow[j], mrow[j + 1]
                if a and b:
                    g = grp(j) if ch else 0xFF
                    row[j] = (a + mb) & 0xFFFF if g == 0xFF else (((s.mhi & 0xF0) << 8) | MG[g]) + 1
                elif a:
                    if not ch:
                        row[j] = (a + mb) & 0xFFFF
                elif b and ch:
                    row[j] = (b + mb) & 0xFFFF

            def midc(j):
                if r < 13 or not mrow[j] or not mrow[j + 1]:
                    return
                g = grp(j)
                if g == 0xFF:
                    return
                if g not in oranks:
                    oranks[g] = len(org)
                    org.append(g)
                t = MG[g] - 1
                mids.extend((2 * j, t & 255, (s.mhi & 0xF0) | t >> 8, oranks[g]))

            def end(j, code, side):
                """a near end's record (made when new), its rank, its entry; False: none"""
                nonlocal nimg, err
                e = s.NEIDX[code]
                if e >= NEMAX or j == 32:
                    return False
                es = 2 * e + side
                g = grp(j) if r >= 13 and mrow[j] and mrow[j + 1] else 0xFF
                if g != 0xFF:
                    key, palhi = NFKEYS + 90 * es + (2 * g | ch), MIXHI | PALM << 4
                else:
                    f = (s.FW[r][j] - fb) & 255
                    if f >= 184:
                        return False
                    key, palhi = 192 * es + f, MIXHI | PALF << 4
                ka = KT + 3 * key - CARD0
                if card[ka] == gen:
                    rec = card[ka + 1] | card[ka + 2] << 8
                else:
                    if nimg >> 8 >= 9:
                        err += 1
                        return False
                    rec = nimg
                    card[ka:ka + 3] = bytes((gen, rec & 255, rec >> 8))
                    card[RT + 4 * rec - CARD0] = 0
                    parts = s.NE[e][side, 1 if g != 0xFF else 0]
                    for k in (1, 2, 3):
                        if g != 0xFF:
                            o = R0IMG + 32 * (7 * g + 4 * ch + k - 1) - CARD0
                            u = card[o:o + 32]
                        else:
                            u = s.FT[f]
                        m = (0, 0x03, 0x0F, 0x3F)[k] ^ (0xFF if side else 0)  # own: 2-pixel sub-tile bitplane masks (2, 4, 6 bits)
                        w(R0IMG + 32 * (rec + k - 1), bytes((u[y] & m) | parts[k - 1][y] for y in range(32)))
                    nimg += 3
                ra = RT + 4 * rec - CARD0
                if card[ra] == bld and card[ra + 1] == P:
                    rk = card[ra + 2]
                else:
                    if len(ranks) >= 64:
                        return False
                    rk = len(ranks)
                    ranks.append(rec)
                    card[ra:ra + 3] = bytes((bld, P, rk))
                ends.extend((2 * j, rk, palhi))
                return True

            for j in range(33):
                a, b = nrow[j] & 0x7F, nrow[j + 1] & 0x7F
                if s.isnear[a]:
                    row[j] = (a + nb) & 0xFFFF
                    if not s.isnear[b]:
                        end(j, a, 0)
                    elif srow[j] < KMAX and j + cn < NOGC:
                        pairs.extend((2 * j, srow[j]))
                elif s.isnear[b]:
                    under(j)
                    if not end(j, b, 1):
                        midc(j)
                elif r >= 13:
                    under(j)
                    midc(j)
                    if j != 32 and bool(mrow[j]) != bool(mrow[j + 1]):     # (quarry-k17: the even columns too, dm 1 .. 3)
                        mfq.append((r, j, mrow[j], mrow[j + 1], s.FW[r][j]))
            w(pp, bytes((len(pairs) // 2,)) + pairs)
            pp += 1 + len(pairs)
            erows.append(ends)
            if r >= 13:
                w(pm, bytes((len(mids) // 4,)) + mids)
                pm += 1 + len(mids)
            w(R0TPL + 1056 * P + 66 * r, b"".join(bytes((x & 255, x >> 8)) for x in row))
        w(lb + 0x3C0, b"".join(a3(R0IMG + 32 * 7 * g) for g in org))
        pend.append((P, lb, ranks, mfq, erows, len(org)))
    # (quarry-finish-2) a mid run's end over the far in rows 13-15 (a mid tile on one side of the cell only, no near tile): in an odd
    # column (dm = 4 + k) a record of three images, k = 1 .. 3 (the mid tile shifted by dm over the far tile, both in palette PALX as
    # region 1 composes them), a rank after the period's own and an entry in its row's ends list. Made after every period, so the
    # console-made records keep their places (images, ranks, lists' heads byte-equal to the console's build). k = 0 (dm 4): the template.
    # (quarry-k17) The even columns the same (dm = k, k = 1 .. 3): their template shows an a-only end's mid tile whole and the far for a
    # b-only one, right at dm 0 only, so both edges of the mid ground's gap stood 1, 2, 3 px off the layer and snapped every 16 px of
    # camera (the owner's "jitter in the gorge"). A record per (tiles, far word, column parity); k = 0 of an even column is the template.
    mfrec, mfimg, xl = {}, {}, {}
    for P, lb, ranks, mfq, erows, norg in pend:
        ch = (CN0 + P) & 1
        rk, nskip, cj, ovf = {}, 0, {}, []
        for q in mfq:
            cj[q[1]] = cj.get(q[1], 0) + 1
        for r, j, xa, xb, fw in sorted(mfq, key=lambda q: (-cj[q[1]], q[1], q[0])):     # (place by place, those with most rows first)
            key = (xa, xb, fw & 0x0FFF, ch)
            if key not in mfimg:                    # (the three images; none needed where they equal what the template shows: in an odd
                far = recolour(s.tile(fw), s.q8M[4])    # column the far beside an a-only end and the whole mid tile for a b-only one, in an
                mid = recolour(s.tile((xa or xb) + s.mw), s.q8M[3])     # even column the other way round)
                ims = []
                for k in (1, 2, 3):
                    d = 4 * ch + k
                    keep = ((1 << d) - 1) ^ (0xFF if xb else 0)
                    T = SHR[d] if xb else SHL[d]
                    ims.append(bytes((far[y] & keep) | T[mid[y]] for y in range(32)))
                tpl = (mid if xb else far) if ch else (far if xb else mid)
                mfimg[key] = None if all(x == tpl for x in ims) else ims
            if mfimg[key] is None:
                continue
            if key in mfrec and mfrec[key] in rk:
                rank = rk[mfrec[key]]
            elif len(ranks) >= 64:                  # (no rank left in the period: an extra cell, below)
                nskip += 1
                if key not in mfrec:
                    if nimg >> 8 >= 9:
                        raise Refusal("store17: region 0 has no room for its images (the console gives up too)")
                    mfrec[key] = nimg
                    for x in mfimg[key]:
                        w(R0IMG + 32 * nimg, x)
                        nimg += 1
                ovf.append((r, j, mfrec[key]))
                continue
            else:
                if key not in mfrec:
                    if nimg >> 8 >= 9:
                        raise Refusal("store17: region 0 has no room for its images (the console gives up too)")
                    mfrec[key] = nimg
                    for x in mfimg[key]:
                        w(R0IMG + 32 * nimg, x)
                        nimg += 1
                rank = rk[mfrec[key]] = len(ranks)
                ranks.append(mfrec[key])
            erows[r].extend((2 * j, rank, MIXHI | PALX << 4))
        pe = lb + 0x200
        for ends in erows:
            w(pe, bytes((len(ends) // 3,)) + ends)
            pe += 1 + len(ends)
        if pe > lb + 0x300:
            raise Refusal("store17: region 0's ends lists overrun their page")
        w(lb, bytes((len(ranks), norg)))
        w(lb + 0x300, b"".join(a3(R0IMG + 32 * x) for x in ranks))
        mfst.append((P, len(ranks), pe - lb - 0x200, len(mfq), nskip))
        # (quarry-band1-lastcells) the period's extra cells (quarry_cards.inc: sxt): k = 0, every mid run end over the far of an odd period
        # at dm 4 (the template shows it whole); k = 1 .. 3 the cells left without a rank (their records' image k)
        if norg > 34 or s.npair > 43:
            raise Refusal("store17: the extra cells' region 0 needs odd ranks <= 34 and band mid pairs <= 43")
        k0 = []
        for r, j, xa, xb, fw in (mfq if ch else ()):     # (an even column's k = 0 is dm 0: the template is right)
            far = recolour(s.tile(fw), s.q8M[4])
            mid = recolour(s.tile((xa or xb) + s.mw), s.q8M[3])
            keep = ((1 << 4) - 1) ^ (0xFF if xb else 0)
            im = bytes((far[y] & keep) | (SHR[4] if xb else SHL[4])[mid[y]] for y in range(32))
            if im == (mid if xb else far):
                continue
            if mfimg[(xa, xb, fw & 0x0FFF, ch)] is None:
                raise Refusal("store17: an extra cell at k = 0 that no list patches at k = 1 .. 3")
            if im not in xl:
                if nimg >> 8 >= 9:
                    raise Refusal("store17: region 0 has no room for its images (the console gives up too)")
                xl[im] = nimg
                w(R0IMG + 32 * nimg, im)
                nimg += 1
            k0.append((r, j, xl[im]))
        for k in range(4):
            cells = k0 if k == 0 else [(r, j, rec + k - 1) for r, j, rec in ovf]
            if not cells:
                continue
            imgs = list(dict.fromkeys(x for _, _, x in cells))
            reg = XR1 if k & 1 and len(imgs) <= len(XR1) else XR0
            if len(imgs) > len(reg):
                raise Refusal(f"store17: period {P} k {k}: {len(imgs)} extra images, the region holds {len(reg)}")
            o = lb + 0x700 + 64 * k
            if any(card[o - CARD0:o - CARD0 + 64]):
                raise Refusal("store17: the extra cells' list place is not empty")
            blk = bytes((len(imgs), len(cells)))
            for r, j, x in cells:
                wd = PALX << 12 | reg[imgs.index(x)]
                blk += bytes((2 * j + 66 * (r - 13), wd & 255, wd >> 8))
            blk += b"".join(a3(R0IMG + 32 * x) for x in imgs)
            if len(blk) > 64:
                raise Refusal("store17: an extra cells' list longer than 64 bytes")
            w(o, blk)
            mfst[-1] += ((k, len(imgs), len(cells)),)
    if err:
        raise Refusal("store17: region 0 has no room for its images (the console gives up too)")
    ct, lt = s.tags()
    lo, hi = cardsum(card, R0TPL, ((nimg + 7) >> 3) + 0xCF)
    w(R0, b"Y3C" + bytes((3, 2, cbkey & 255, cbkey >> 8, lt & 255, lt >> 8, nimg & 255, nimg >> 8, s.npair, lo, hi, 0, 0)))  # own: our Y3C region-0 store header magic and version
    return dict(images=nimg, pairs=s.npair, layout_tag=lt, content_tag=ct, sum=lo | hi << 8, end=R0IMG + 32 * nimg, mf=mfst, mfrec=len(mfrec))


def region1(s, card, cbkey, tag):
    """the bridge's store (quarry_card8.inc's q8build): near columns 39-79"""
    def w(addr, data):
        card[addr - CARD0:addr - CARD0 + len(data)] = data
    card[R1 - CARD0] = 0
    w(HT, bytes(0x8000))
    ni = 0
    S = bytearray(128)                              # a record's sources: far, mid A, mid B, near (kept from record to record)
    PH = (MIXHI | PALF << 4, MIXHI | PALM << 4, MIXHI | PALX << 4)
    for P in range(NPER1):
        cn = CNB0 + P
        cm, h = cn >> 1, cn & 1
        lb = R1LB + 0x800 * P
        nu = 0
        pos = [lb + 0x10, lb + 0x200, lb + 0x420, lb + 0x460]
        for r in range(16):
            row = list(s.FW[r])
            lst = [bytearray(), bytearray(), bytearray(), bytearray()]
            cnt = [0, 0, 0, 0]
            for j in range(33):
                na, nb = s.near[r][cn + j] & 0x7F, s.near[r][cn + j + 1] & 0x7F
                ma, mb = (s.mid[r][cm + j], s.mid[r][cm + j + 1]) if r >= 10 else (0, 0)
                ns, ms = s.nslot[r][cn + j], s.mslot[r][cm + j]
                ea, eb = s.isnear[na], s.isnear[nb]
                fw = row[j]
                if ea:
                    row[j] = (na + s.nw) & 0xFFFF
                elif ma and (not h or mb):
                    row[j] = (ma + s.mw) & 0xFFFF
                if ea and eb:
                    if ns >= KMAX:
                        continue
                    ma = mb = fw = 0
                pc = (1 if mb else 2) if ma else (2 if mb else 0)
                if pc == 2:                         # a near end with a mid run's end: by the columns each takes
                    if ea:
                        if mb:
                            if h:
                                pc = 1
                        elif h:
                            ma, pc = 0, 0
                    elif eb:
                        if ma:
                            if not h:
                                pc = 1
                        elif not h:
                            mb, pc = 0, 0
                if not (ea or eb or pc):
                    continue
                key = bytearray((na | 0x80 if ea else 0, nb | 0x80 if eb else 0, ma, mb, 0, 0))  # own: our 6-byte composite tile hash-table key layout
                k0 = 0
                if pc != 1:
                    key[4], key[5] = fw & 255, fw >> 8 & 0x7F
                if pc and h:
                    key[5] |= 0x80
                    if not ea:
                        k0 = 1
                hv = 0
                for x in key:
                    hv = ((hv << 2) + x) & 0xFFFF
                while True:
                    hv &= 0x7FF
                    ha = HT + 16 * hv - CARD0
                    if not card[ha + 6]:
                        break
                    if card[ha:ha + 6] == key:
                        break
                    hv += 1
                if not card[ha + 6]:                # a new record: its images
                    if ni >> 8 >= 0x0F:
                        raise Refusal("store17: region 1 has no room for its images (the console gives up too)")
                    first = ni + k0
                    card[ha:ha + 7] = key + b"\x01"
                    card[ha + 8], card[ha + 9], card[ha + 10] = first & 255, first >> 8, 0
                    if pc != 1:
                        S[0:32] = s.tile(fw) if pc == 0 else recolour(s.tile(fw), s.q8M[4])
                    if ma:
                        S[32:64] = s.tile(ma + s.mw) if pc == 1 else recolour(s.tile(ma + s.mw), s.q8M[3])
                    if mb:
                        S[64:96] = s.tile(mb + s.mw) if pc == 1 else recolour(s.tile(mb + s.mw), s.q8M[3])
                    bx = 64 if ea else 96
                    if ea:
                        t = s.tile(na + s.nw)
                        S[96:128] = t if eb else recolour(t, s.q8M[pc])
                    if eb:
                        t = s.tile(nb + s.nw)
                        S[bx:bx + 32] = t if ea else recolour(t, s.q8M[pc])
                    for kk in range(1 - k0, 4):
                        ib = bytearray(S[0:32])
                        d = 4 * h + kk
                        for on, src, dd, sd in ((ma, 32, d, 0), (mb, 64, d, 1), (ea and kk, 96, 2 * kk, 0), (eb and kk, bx, 2 * kk, 1)):
                            if not on:
                                continue
                            keep = ((1 << dd) - 1) ^ (0xFF if sd else 0)
                            T = (SHL, SHR)[sd][dd]
                            for y in range(32):
                                ib[y] = (ib[y] & keep) | T[S[src + y]]
                        w(R1IMG + 32 * ni, ib)
                        ni += 1
                first = card[ha + 8] | card[ha + 9] << 8
                if ea and eb:
                    lst[0].extend((2 * j, ns) + tuple(a3(R1IMG + 32 * first)))
                    cnt[0] += 1
                elif not (ea or eb) and pc == 1:
                    lst[3].extend((2 * j, ms) + tuple(a3(R1IMG + 32 * first)))
                    cnt[3] += 1
                elif j != 32:                       # a mix: its rank in this period
                    if card[ha + 10] != P + 1:
                        card[ha + 10] = P + 1
                        if nu >= 96:
                            raise Refusal("store17: region 1 has no rank left in a period (the console gives up too)")
                        card[ha + 11] = nu
                        w(lb + 0x300 + 3 * nu, a3(R1IMG + 32 * first))
                        nu += 1
                    lst[1].extend((2 * j, card[ha + 11], PH[pc]))
                    cnt[1] += 1
                    if k0:
                        lst[2].extend((2 * j, card[ha + 11], PH[pc]))
                        cnt[2] += 1
            for x in range(4):
                if x == 3 and r < 10:
                    continue
                w(pos[x], bytes((cnt[x],)) + lst[x])
                pos[x] += 1 + len(lst[x])
            w(R1TPL + 1056 * P + 66 * r, b"".join(bytes((x & 255, x >> 8)) for x in row))
        card[lb - CARD0] = nu
    lo, hi = cardsum(card, R1TPL, ((ni + 7) >> 3) + 0x1FF)
    w(R1, b"Y3C" + bytes((2, 1, cbkey & 255, cbkey >> 8, tag & 255, tag >> 8, ni & 255, ni >> 8, 0, lo, hi, 0, 0)))  # own: our Y3C region-1 store header magic and version
    return dict(images=ni, layout_tag=tag, sum=lo | hi << 8, end=R1IMG + 32 * ni)


def build(extract, side="right", cbkey=0, gen=1, bld=1):
    s = Setup(extract, side)
    card = bytearray(0x80000)
    m0 = region0(s, card, cbkey, gen, bld)
    m1 = region1(s, card, cbkey, m0["layout_tag"])
    return s, card, m0, m1


def main(a):
    opt = dict(x[2:].split("=", 1) for x in a if x.startswith("--"))
    pos = [x for x in a if not x.startswith("--")]
    if len(pos) != 2:
        raise SystemExit(__doc__)
    t0 = time.time()
    try:
        s, card, m0, m1 = build(pos[0], opt.get("side", "right"), int(opt.get("cbkey", "0"), 0), int(opt.get("gen", "1"), 0),
                                int(opt.get("bld", "1"), 0))
    except Refusal as e:
        raise SystemExit(str(e))
    os.makedirs(pos[1], exist_ok=True)
    parts = {"card.bin": bytes(card), "region0.bin": bytes(card[R0 - CARD0:m0["end"] - CARD0]),
             "region1.bin": bytes(card[R1 - CARD0:m1["end"] - CARD0]), "palette.bin": s.pal}
    for n, b in parts.items():
        open(os.path.join(pos[1], n), "wb").write(b)
    man = {"side": s.side, "tile_bases": {"near": s.nw, "mid": s.mw, "far": s.fw}, "near_slots": s.nk, "mid_slots": s.mk,
           "near_end_tiles": len(s.NE), "mid_patterns": len(s.TPC), "region0": m0, "region1": m1,
           "bytes": {n: len(b) for n, b in parts.items()}, "sha256": {n: hashlib.sha256(b).hexdigest() for n, b in parts.items()}}
    json.dump(man, open(os.path.join(pos[1], "manifest.json"), "w"), indent=1)
    try:
        import resource
        mem = ", peak memory %.0f MB" % (resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024)
    except ImportError:                             # (not on every platform: the browser's Python has none)
        mem = ""
    print("store17:", pos[0], "side", s.side, "| region 0: images", m0["images"], "pairs", m0["pairs"], "tag %04X" % m0["layout_tag"],
          "sum %04X" % m0["sum"], "bytes", len(parts["region0.bin"]), "| region 1: images", m1["images"], "sum %04X" % m1["sum"],
          "bytes", len(parts["region1.bin"]), "| %.2f s" % (time.time() - t0) + mem)


if __name__ == "__main__":
    main(sys.argv[1:])
