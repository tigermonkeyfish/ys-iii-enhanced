"""seam17.py: room 17's set-up products that the module otherwise makes in the background of a visit (quarry-seams), computed at
patch time from store17's Setup objects and packed as one more segment of the pre-generated store (pack17.py), at SEAM on the card.
The console copies them into its own tables in idle time (the module's quarry_cards.inc) instead of making them: the pair images of
the side the room was not entered from (ss_gn / ss_gm: genph), and band_setup's tables (the property table, the far words, NEIDX,
the near-end parts, the far tiles' patterns).

Everything this makes is game data (the player's own track's tiles, shifted and recoloured): it belongs under an ignored folder,
never in a commit, a patch or a document.

The segment (offsets from SEAM; slot numbers are the band's-side scan's, `right`):
  + $0000  the near pairs' images: phase p (0-3: 2 p pixels) at + $1100 p + 32 k
  + $4400  136 bytes: the open-quarry-side scan's slot -> the band's-side slot (the same pair of tiles)
  + $4500  136 bytes by band's-side slot: 1 = the pair looks the same at every phase (genph's flat: NPO gets PFLAT)
  + $4600  64 bytes by mid slot: likewise (MPO); + $4640 nne (the near-end tiles with parts); + $4641 nk, + $4642 mk,
           + $4643 the far tiles given here (the room's own: the console reads the rest of the 184 from its VRAM)
  + $4680  NEIDX (128); + $4700 the property table (128)
  + $4800  the mid pairs' images: phase p (0-7) at + $800 p + 32 k
  + $8800  the near-end parts: e * 384 + side * 192 + pal * 96 + (pn - 1) * 32 (BANDN)
  + $A800  the far tiles' patterns: 32 f (BANDF)
  + $C000  the far words of the area layout: row r at + 66 r, column j at + 2 j; + $C800 the door layout's
"""
import store17
from store17 import need                      # a refusal is an error, never an assert: `python -O` drops asserts, and one of
#                                              these used to do its work inside one (the slot table below)

SEAM = 0x1E0000
SEAMLEN = 0xCC20
KMAX = store17.KMAX
SHL, SHR = store17.SHL, store17.SHR


def pairs(slot, maps, ncols, mask):
    """slot number -> (code a, code b), from the slot table and the map (as the scan numbered them)"""
    out = {}
    for r in range(16):
        for c in range(ncols):
            v = slot[r][c]
            if v < KMAX:
                p = (maps[r][c] & mask, maps[r][c + 1] & mask)
                need(out.setdefault(v, p) == p, "seam17: one slot number for two different pairs of tiles")
    need(sorted(out) == list(range(len(out))), "seam17: the slot numbers have a gap")
    return [out[k] for k in range(len(out))]


def phases(a, b, step):
    """genph: the pair's images at 0, step, 2 step .. pixels, and whether every one equals tile a"""
    img, flat = [bytes(a)], 1
    for d in range(step, 8, step):
        x = bytes(SHL[d][a[y]] | SHR[d][b[y]] for y in range(32))
        if x != bytes(a):
            flat = 0
        img.append(x)
    return img, flat


def build(setups):
    """setups: store17 Setup objects for (area layout, right), (area, left), (door layout, right), (door, left)"""
    s, sl, sd, sdl = setups
    blob = bytearray(SEAMLEN)
    npr = pairs(s.nslot, s.near, store17.NCOLS, 0x7F)
    npl = pairs(sl.nslot, sl.near, store17.NCOLS, 0x7F)
    need(len(npr) == len(npl) == s.nk <= 136 and sorted(npr) == sorted(npl), "seam17: the two scan sides' near pairs differ, or more than 136")
    need(pairs(sd.nslot, sd.near, store17.NCOLS, 0x7F) == npr and pairs(sdl.nslot, sdl.near, store17.NCOLS, 0x7F) == npl,
         "seam17: the two layouts' near pairs differ")
    for k, (a, b) in enumerate(npr):
        img, flat = phases(s.tile(s.nw + a), s.tile(s.nw + b), 2)
        need(phases(sd.tile(sd.nw + a), sd.tile(sd.nw + b), 2) == (img, flat), "seam17: the two layouts' near tiles differ")
        for p in range(4):
            blob[0x1100 * p + 32 * k:0x1100 * p + 32 * k + 32] = img[p]
        blob[0x4500 + k] = flat
        need(not flat, "seam17: a near pair that looks the same at every phase (NPO's PFLAT: the console's copy does not mark it)")
    for k, p in enumerate(npl):
        blob[0x4400 + k] = npr.index(p)
    mp = pairs(s.mslot, s.mid, store17.MCOLS, 0xFF)
    need(len(mp) == s.mk <= 64 and pairs(sd.mslot, sd.mid, store17.MCOLS, 0xFF) == mp and pairs(sl.mslot, sl.mid, store17.MCOLS, 0xFF) == mp,
         "seam17: the variants' mid pairs differ, or more than 64")
    for k, (a, b) in enumerate(mp):
        img, flat = phases(s.tile(s.mw + a), s.tile(s.mw + b), 1)
        need(phases(sd.tile(sd.mw + a), sd.tile(sd.mw + b), 1) == (img, flat), "seam17: the two layouts' mid tiles differ")
        for p in range(8):
            blob[0x4800 + 0x800 * p + 32 * k:0x4800 + 0x800 * p + 32 * k + 32] = img[p]
        blob[0x4600 + k] = flat
        need(not flat, "seam17: a mid pair that looks the same at every phase (MPO's PFLAT: the console's copy does not mark it)")
    for x in (sl, sd, sdl):
        need((x.NEIDX, x.NE, x.prop) == (s.NEIDX, s.NE, s.prop), "seam17: band_setup's tables differ between the variants")
    # the far tiles' patterns: the first ftn are the room's own (equal in both layouts); the tiles after them belong to whatever
    # follows the far set in VRAM (another set in each layout): the console reads those from its own VRAM, as ftcopy does
    ftn = next((f for f in range(184) if any(x.FT[f] != s.FT[f] for x in (sl, sd, sdl))), 184)
    need(ftn >= 160, "seam17: the far tiles differ between the layouts")
    blob[0x4643] = ftn
    need(sl.FW == s.FW and sdl.FW == sd.FW, "seam17: the far words differ between the scan sides")
    blob[0x4640], blob[0x4641], blob[0x4642] = len(s.NE), s.nk, s.mk
    blob[0x4680:0x4700] = s.NEIDX
    blob[0x4700:0x4780] = s.prop
    for e, parts in enumerate(s.NE):
        for side in (0, 1):
            for pal in (0, 1):
                for pn in (1, 2, 3):
                    o = 0x8800 + e * 384 + side * 192 + pal * 96 + (pn - 1) * 32
                    blob[o:o + 32] = parts[side, pal][pn - 1]
    for f, t in enumerate(s.FT[:ftn]):
        blob[0xA800 + 32 * f:0xA800 + 32 * f + 32] = t
    for o, x in ((0xC000, s), (0xC800, sd)):
        for r in range(16):
            for j in range(33):
                blob[o + 66 * r + 2 * j] = x.FW[r][j] & 255
                blob[o + 66 * r + 2 * j + 1] = x.FW[r][j] >> 8
    return bytes(blob)
