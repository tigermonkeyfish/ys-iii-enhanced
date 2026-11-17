#!/usr/bin/env python3
"""extract17.py TRACK02 OUTDIR [--entries cont18,cont8,door,round] [--frame-instructions N]

Patch-time extraction, step 1 of the quarry's pre-generated store: from the player's own data track ALONE, everything the store builder
reads in room 17 (the Tigray Quarry exterior), for each entry layout. Pure Python 3, standard library only (huc6280.py, pce.py).
Nothing of the game is in this file or its output's description: the tiles, maps and palettes are produced by RUNNING the game's own
boot, loader and unpacker from the track in a small interpreter, with the System Card's calls modelled by their documented
behaviour (pce.py). The output holds game data: write it under an ignored folder (captures/), never commit it.

How a state is made (the same for every entry):
  1. the boot record (sector 1) is honoured as the System Card does: the program's sectors to its load address, the five pages,
     the documented hand-over values in the work RAM and the video registers; the game's boot program runs;
  2. the pad presses RUN and I in turn (a new game): intro skipped, title, "Begin"; the game loads its main program and reaches
     its room-entry routine (ROOM, bank $82 at page 3) for the first time;
  3. there the ENTRY is substituted in the game's own variables (the scene and where Adol comes in: what a Continue takes from
     a save file) and the game goes on by itself: it reads the area's block, unpacks it, places the tiles, draws, lights the room.
     A door entry then walks (pad held) through the door, the game doing the room change.
Entries (the layouts found; see tools/pregen/README.md):
  cont18  Continue in room 17 from a save made at the right end (came from room 18): scene 17, cell (124, 11)
  cont8   Continue in room 17 from a save made at the left end (came from room 8): scene 17, cell (12, 12)
  door    Continue in room 18 at its left door, then left through the door into 17 (the other tile layout)
  round   cont18, then right into 18 and left back into 17 (the layout after a round trip)
Output, per entry, in OUTDIR/<entry>/ (the state at the room's first lit frame; all raw, little endian):
  vram.bin      32,768 words   the whole VRAM as the game left it
  vwritten.bin  32,768 bytes   1 = the word was written by the game since the room entry of step 3 (what the load places)
  cdram.bin     65,536 bytes   banks $80-$87 (the program with its operands, the area's data, the maps)
  ram.bin        8,192 bytes   the work RAM $2000-$3FFF (the palette copy at $3C00, the camera, zero page)
  pal.bin          512 words   the colour table 60 frames after the first lit frame (the fade over)
  adpcm.bin     65,536 bytes   the ADPCM memory (the area's second block, where the game keeps packed room data)
  manifest.json                the regions the builder reads (addresses, sizes, SHA-256), the entry, the frames, the calls made
"""
import sys
import os
import json
import time
import hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pce  # noqa: E402

IPL_SHA = "ae349a6663bab6c89c5266135d5f11db0132bdcc631a3a5388946c1aa99d7108"   # see pce.Track: finds sector 0, proves the track
ROOM = 0x78B5              # the room-entry routine (bank $82 at page 3): reads the scene, loads the area if it changed
AREA = 770                 # the quarry's area block (24): 16 sectors, read by the game itself; named here for check17.py
PROGRAM = 450              # the main program's first sector (block 14), loaded at $4800 over banks $80-$84
SCENE, PREV, ENTX, ENTY, ENTF = 0x207C, 0x207D, 0x2080, 0x2082, 0x209A   # the entry: scene, the scene before ($FF: none),
#                            the cell Adol comes in at, the entry's facing byte
DARK, LOCK, BUSY = 0x3224, 0x2025, 0x36D6                                 # dark after a load; bit 4 a scene lock; a script running
ENTRIES = {
    "cont18": dict(scene=17, x=0x7C, y=0x0B, f=0),
    "cont8": dict(scene=17, x=0x0C, y=0x0C, f=3),
    "door": dict(scene=18, x=0x0F, y=0x02, f=3, walk=[("left", 17)]),
    "round": dict(scene=17, x=0x7C, y=0x0B, f=0, walk=[("right", 18), ("left", 17)]),
}
PAD = {"left": 0x80, "right": 0x20, "run": 8, "i": 1}


class Reached(Exception):
    pass


def boot(track, k):
    """steps 1 and 2: the machine at the game's first room entry"""
    mc = pce.Machine(track)
    c = mc.cpu
    ipl = track.sectors(1, 1)
    rec, n = int.from_bytes(ipl[0:3], "big"), ipl[3]
    load, start = ipl[4] | ipl[5] << 8, ipl[6] | ipl[7] << 8
    for p in range(2, 7):
        c.map(p, mc.RAMBANK + ipl[8 + p - 2])
    c.map(7, 0)
    mc.handover()
    mc.store(track.sectors(rec, n), 1, load)
    c.put(pc=start)

    def at_room():
        if c.mpr[3] == mc.RAMBANK + 2:
            raise Reached()
    op = track.sectors(PROGRAM, 16)[(2 << 13) + (ROOM & 0x1FFF) - 0x800]    # the routine's first opcode, from the track
    bp = c.setbp(ROOM, at_room, op)
    try:
        while mc.frames < 3000:
            f = mc.frames % 40
            mc.pad = PAD["run"] if f < 4 else PAD["i"] if 20 <= f < 24 else 0
            mc.frame(k)
        raise RuntimeError("the game did not reach its room entry in 3000 frames")
    except Reached:
        pass
    c.clrbp(*bp)
    mc.pad = 0
    return mc


def lit(mc, scene):
    M = mc.cpu.M
    return M[SCENE] == scene and M[DARK] == 0 and not M[LOCK] & 0x10


def run_until(mc, k, cond, limit, what):
    for _ in range(limit):
        mc.frame(k)
        if cond():
            return
    raise RuntimeError(f"{what}: not reached in {limit} frames (scene {mc.cpu.M[SCENE]})")


def enter(track, name, k):
    """step 3 for one entry: the machine at the first lit frame of room 17, and its frame marks"""
    e = ENTRIES[name]
    mc = boot(track, k)
    M = mc.cpu.M
    marks = {"room_entry": mc.frames}
    M[SCENE], M[PREV], M[ENTX], M[ENTY], M[ENTF] = e["scene"], 0xFF, e["x"], e["y"], e["f"]
    mc.vmark[:] = bytes(0x8000)
    run_until(mc, k, lambda: lit(mc, e["scene"]), 1500, f"room {e['scene']} lit")
    marks["lit_%d" % e["scene"]] = mc.frames
    scene = e["scene"]
    for key, to in e.get("walk", ()):
        q = [0]

        def quiet():
            ok = lit(mc, scene) and M[BUSY] == 0
            q[0] = q[0] + 1 if ok else 0
            return q[0] >= 60
        run_until(mc, k, quiet, 1500, f"room {scene} quiet")
        mc.pad = PAD[key]
        run_until(mc, k, lambda: M[SCENE] == to, 1500, f"walk {key} into {to}")
        mc.pad = 0
        mc.vmark[:] = bytes(0x8000)                          # from here on: what the last room's load places
        marks["door_%d_%d" % (scene, to)] = mc.frames
        run_until(mc, k, lambda: lit(mc, to), 1500, f"room {to} lit")
        marks["lit_%d_after_%d" % (to, scene)] = mc.frames
        scene = to
    return mc, marks


ROWCALL, FARPTR = 0x6C8E, 0x6D2A                             # the row loop's call of the compositor, its far operand (bank $81)


def regions(mc):
    """the builder's inputs by address, read from the state itself: the game's compositor operands (bank $81) give the three tile
    bases and the map pointers; zero page $34 the map bank, $59 / $5A the near property table"""
    c = mc.cpu
    c.sync()
    b81 = c.banks[mc.RAMBANK + 1]
    op = lambda a: b81[a - 0x6000]                                            # noqa: E731
    M = c.M
    near = op(0x6CF2) | (op(0x6CF7) + op(0x6CF9) & 255) << 8
    mid = op(0x6D11) | op(0x6D18) << 8
    far = op(0x6D2E) | op(0x6D35) << 8
    out = {"operands": {"near_base": near, "mid_base": mid, "far_base": far,
                        "near_ptr": op(0x6CE6) | op(0x6CE7) << 8, "mid_ptr": op(0x6D0B) | op(0x6D0C) << 8,
                        "far_ptr": op(0x6D2A) | op(0x6D2B) << 8},
           "pages": [x & 255 for x in c.mpr], "map_bank": M[0x2034], "property_ptr": M[0x2059] | M[0x205A] << 8, "camera_x": M[0x2D0C] | M[0x2D0D] << 8}
    vm = mc.vmark
    pages = {}
    for nm, base in (("near", near), ("mid", mid), ("far", far)):
        t0 = base & 0x7FF
        a = t0 * 16
        e = a
        while e < 0x8000 and any(vm[e:e + 16]):
            e += 16
        pages[nm] = {"first_tile": t0, "tiles": (e - a) // 16, "vram_word": a, "words": e - a, "palette": base >> 12}
    out["tile_pages"] = pages
    return out


def sha(b):
    return hashlib.sha256(bytes(b)).hexdigest()


def words(v):
    out = bytearray()
    for w in v:
        out.append(w & 255)
        out.append(w >> 8)
    return bytes(out)


def collect(mc, name, marks, k, track):
    """one entry's output in memory: ({file name: bytes}, the manifest); nothing is written (the patch-time step keeps it so)"""
    c = mc.cpu
    c.sync()
    reg = regions(mc)
    vram = words(mc.vram)
    cd = b"".join(bytes(c.banks[mc.RAMBANK + b]) for b in range(8))
    ram = bytes(c.M[0x2000:0x4000])
    files = {"vram.bin": vram, "vwritten.bin": bytes(mc.vmark), "cdram.bin": cd, "ram.bin": ram, "adpcm.bin": bytes(mc.adpcm)}
    calls = {}
    for x in mc.log:
        calls[x[0]] = calls.get(x[0], 0) + 1
    reads = [list(x[:3]) for x in mc.log if x[0] in ("cd_read", "ad_trans")]
    # The far map's first row: the compositor's far operand is the pointer of the row being drawn, so the state's own value is
    # that of whatever row the frame's end fell in. Sampled at the row loop's call of the compositor (ROWCALL, bank $81 at MPR3)
    # over the frames that follow, the lowest is row 0's (what the module reads at a pass's first row).
    b81 = c.banks[mc.RAMBANK + 1]
    seen = []

    def at_row():
        if c.mpr[3] == mc.RAMBANK + 1:
            seen.append(c.M[FARPTR] | c.M[FARPTR + 1] << 8)
    bp = c.setbp(ROWCALL, at_row, b81[ROWCALL - 0x6000])
    for _ in range(60):                                      # the colour table once the fade is over
        mc.frame(k)
    c.clrbp(*bp)
    if len(seen) < 32:
        raise RuntimeError(f"{name}: the row loop ran {len(seen)} times in 60 frames: the far map's first row is not known")
    reg["operands"]["far_row0_ptr"] = min(seen)
    reg["operands"]["far_rows_sampled"] = len(seen)
    files["pal.bin"] = words(mc.pal)
    man = {"entry": name, "substituted": ENTRIES[name], "frames": marks, "frame_instructions": k, "regions": reg,
           "sha256": {fn: sha(b) for fn, b in files.items()},
           "region_sha256": {}, "system_card_calls": calls, "disc_reads": reads,
           "system_card_calls_by_address": {f"{a:04X}": n for a, n in sorted(mc.called.items())},
           "vram_words_written_by_the_load": sum(mc.vmark)}
    for nm, p in reg["tile_pages"].items():
        man["region_sha256"]["tiles_" + nm] = sha(vram[p["vram_word"] * 2:(p["vram_word"] + p["words"]) * 2])
    mb = reg["map_bank"] - mc.RAMBANK
    if 0 <= mb < 8:
        man["region_sha256"]["map_bank"] = sha(cd[mb << 13:(mb + 1) << 13])
    area = cd[3 << 13:7 << 13]
    blk = track.sectors(AREA, 16)
    rew = [i for i in range(len(blk)) if area[i] != blk[i]]
    man["area_banks_83_86"] = {"equal_to_the_track_block_but_bytes": len(rew),            # room variables the game rewrites in play
                               "rewritten_at": [f"{mc.RAMBANK + 3 + (i >> 13):02X}:{i & 0x1FFF:04X}" for i in rew[:64]]}
    man["region_sha256"]["area_banks_83_86_as_loaded"] = sha(bytes(blk[i] if i in set(rew) else area[i] for i in range(len(blk)))
                                                             if len(rew) <= 64 else area)
    man["region_sha256"]["palette_copy_3C00"] = sha(ram[0x1C00:0x1E00])
    return files, man


def write(outdir, name, files, man):
    """one entry's output as files (game data: OUTDIR belongs under an ignored folder)"""
    d = os.path.join(outdir, name)
    os.makedirs(d, exist_ok=True)
    for fn, b in files.items():
        with open(os.path.join(d, fn), "wb") as f:
            f.write(b)
    with open(os.path.join(d, "manifest.json"), "w") as f:
        json.dump(man, f, indent=1)


def dump(mc, name, marks, outdir, k, track):
    files, man = collect(mc, name, marks, k, track)
    write(outdir, name, files, man)
    return man


FRAME_INSTRUCTIONS = 27000


def extract(track, names, k=FRAME_INSTRUCTIONS, log=print, outdir=None):
    """the entries' outputs in memory: {name: (files, manifest)}. track: a pce.Track, or a file's name. outdir: also written there."""
    own = not isinstance(track, pce.Track)
    if own:
        track = pce.Track(track, IPL_SHA)
    out = {}
    try:
        for nm in names:
            t1 = time.time()
            mc, marks = enter(track, nm, k)
            files, man = collect(mc, nm, marks, k, track)
            if outdir is not None:
                write(outdir, nm, files, man)
            out[nm] = (files, man)
            p = man["regions"]["tile_pages"]
            log(f"{nm}: frames {marks}; tile pages " + ", ".join(f"{n} ${p[n]['first_tile']:03X} x {p[n]['tiles']}" for n in p)
                + f"; map bank ${man['regions']['map_bank']:02X}; {man['vram_words_written_by_the_load']} VRAM words placed; "
                f"{time.time() - t1:.1f} s")
    finally:
        if own:
            track.close()
    return out


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    path, outdir = argv[1], argv[2]
    names, k = ["cont18", "cont8", "door"], FRAME_INSTRUCTIONS
    for a in argv[3:]:
        if a.startswith("--entries="):
            names = a.split("=")[1].split(",")
        elif a.startswith("--frame-instructions="):
            k = int(a.split("=")[1])
        else:
            sys.exit(__doc__)
    t0 = time.time()
    extract(path, names, k, print, outdir)
    try:
        import resource
        mem = f", peak memory {resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024:.0f} MB"
    except ImportError:                                      # (not on every platform: the browser's Python has none)
        mem = ""
    print(f"total {time.time() - t0:.1f} s{mem}")


if __name__ == "__main__":
    main(sys.argv)
