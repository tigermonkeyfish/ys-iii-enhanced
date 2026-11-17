# Ys III Enhanced 0.2.0: smooth parallax patch for Ys III: Wanderers from Ys (TurboGrafx-CD, USA)

Smooth 60 fps multi-layer parallax and 60 fps enemy, NPC, and boss sprite interpolation through Redmont, Tigray Quarry, and the Tigray Mine. Source and releases: https://github.com/tigermonkeyfish/ys-iii-enhanced

Unofficial fan project. Not affiliated with or endorsed by Nihon Falcom, Hudson Soft, Konami or NEC. Ys is a trademark of its owners.

Replaces the original 8-pixel and 16-pixel layer snaps with smooth 60 fps sub-tile scrolling across the early town, quarry, and mine areas while keeping gameplay logic, pass timing, and the per-pass random-number sequence matched to the original disc. The patch holds no game data, and you need your own dump of the game to use it. The code is MIT licensed (see LICENSE); the licence covers this project's own code only, not the game.

EDC/ECC code was written from the published ECMA-130 standard.

## What is covered

- **Redmont** (`Scenes 0, 1`): the main street (clouds held steady, back wall at 1 pixel per frame) and the castle gate and bridge leading to the world map.
- **Tigray Quarry** (`Scene 17`): full exterior and rope gorge/bridge across three layers, with per-scanline raster splits and Arcade Card pre-built composite tiles.
- **Tigray Mine & Waterfalls** (`Scenes 18, 19, 20, 25, 28, 29, 30`): mine caves, both vertical and horizontal parallax in the deep mine shaft (Arcade Card borderless 320-pixel layout + preloaded tiles), and the waterfall shafts.
- **60 fps enemies, townspeople, and bosses**: resident `$7D` sprite-attribute interpolator with multi-sprite lock on normal-pass actors, 30 Hz ceiling-blade rotation in the Dulan fight, and smooth Elefeir fire waves.
- Later story areas and a later evening revisit of the Redmont street keep the game's own display in 0.2.0.

## Requirements

- Your own Redump-style cue/bin dump of **Ys III - Wanderers from Ys (USA)** (Redump, TGXCD1015; some dats name it "(USA) (Rev 1)", and either name is this dump), one file per track. Its Track 02 file is 58701216 bytes, with CRC32 `2438E447`, MD5 `10DDBD55A98BAF64DF1C64064EF17242`, SHA-1 `FDA4ECAB121DB0AB443956DCDF236A0F38868F73`, and it must have this SHA-256; the patcher checks only the SHA-256 and refuses anything else, including other revisions of the game:
  `32ae723dc05050c78a11ae1e8e3ece5d8a3a8f22ac2992baf0bac99e817d8dae`
- `python3` (3.8+) and `xdelta3` on the PATH.
- To play: an **Arcade Card** is required at boot — either a Super System Card 3.0 / TurboDuo / PC Engine Duo with an Arcade Card, a PC Engine / TurboGrafx-16 with System Card 2.0+ and an Arcade Card Pro, or a Krikzz Turbo EverDrive Pro in Arcade Card mode. The patched disc tests for Arcade Card RAM at boot and stops cleanly with a message when it is absent (verified in Geargrafx and Mesen2).

## How to apply

Download `ys-iii-enhanced-0.2.0.zip` from the repository's Releases page and unzip it. It contains 15 files (`apply.py`, `ys-iii-enhanced-0.2.0.xdelta`, `ys-iii-enhanced-0.2.0.store.json`, `pregen/` with 8 Python scripts, `edc130.py`, this file, `LICENSE` and `CREDITS.md`) and no game data. From that folder, with the path to your dump's cue:

<!-- apply step -->
```sh
python3 apply.py "Ys III - Wanderers from Ys (USA).cue"
```

The cue's file name does not matter; the Track 02 SHA-256 does.

`apply.py` performs two steps automatically from your own Track 02 dump:
1. Applies `ys-iii-enhanced-0.2.0.xdelta` to build Track 02 with SHA-256 `b0bcce31177c8a648c43f04b50b95db35cec79757c76f5e6e3f9a18cb274f2ff` (`106` of `24728` sectors changed).
2. Computes the pre-built quarry bridge and mine-shaft composite tiles from your own Track 02 into `401` unused sectors (plus two boot flag sectors, `507` changed sectors total), producing Track 02 with SHA-256 `c0a2e1b2ab71197f8715f1e5f79fef826c22b81a2e8dc24609c198473c6a116d` and checking every hash before replacing the file. If step 2 fails, the step-1 track still runs (falling back cleanly to the original display on the bridge and mine shaft) and `apply.py` exits with status `3`.

Optional modes:
- `python3 apply.py --no-store "Ys III - Wanderers from Ys (USA).cue"` — apply only the `.xdelta` patch (step 1, Track 02 SHA-256 `b0bcce31177c8a648c43f04b50b95db35cec79757c76f5e6e3f9a18cb274f2ff`).
- `python3 apply.py --store ORIGINAL.bin PATCHED.bin` — run step 2 alone on a step-1 track.
- `python3 apply.py --verify "Track 02.bin"` — report whether Track 02 is untouched, step-1 patched, or full pre-built store patched.

Only the Track 02 file is changed; the audio tracks and the cue are left as they are. The original is kept beside it as `*.orig`. Run the patched cue on an emulator or on hardware with Arcade Card support enabled.

## Tested on

- **TurboGrafx-16 + EDFX + Krikzz Turbo EverDrive Pro (Arcade Card mode) = TESTED** — full `0.2.0` playthrough through Redmont, Tigray Quarry, Mine Caves, Mine Shaft, Waterfall Shafts, Pendant, Dulan, and Elefeir verified on hardware (`2026-11-16` / `2026-11-17`), including the 256-byte chunked boot preload fix eliminating `Super CD-ROM²` screen jitter after pressing `RUN`.
- **Real CD / physical Arcade Card (PC Engine Duo / TurboDuo / Super System Card 3.0) = NOT TESTED** (`0.1.0` was tested on a burned CD-R in a PC Engine Duo-RX, but `0.2.0` with an Arcade Card has not yet been tested on a real optical drive).
- **MiSTer FPGA = NOT TESTED**.
- **Emulators**: Geargrafx (Arcade Card enabled) and Mesen2 (Arcade CD mode).

## Known issues

- **Room-entry blacks:** Room entries hold dark setup screens roughly `1.0–1.5 s` longer than the untouched disc so the first visible frame is already smooth (the cold entry into the mine shaft is `+62` frames / `~1.03 s` longer over the untouched disc via the pre-built store, with a `~50 s` live-build fallback if the no-store step-1 track is used).
- **Mine Shaft (`Scene 19`) layout & slowdown:** Switches to a black borderless 320-pixel tile-grid layout on the Arcade Card to free tiles and DMA bandwidth for gap-free 60 fps vertical and horizontal parallax; dying inside the mine shaft brings back the top/bottom `GAME OVER` bars while side borders stay off, and normal decorative frames restore on exit. Heavy scrolling sections prioritize gap-free imagery (`0` gaps) over speed and run slower by repeating previous frames (`435` vs `354` frames on the fall; `+61` frames on full top-to-bottom descent).
- **Mine caves (`Scenes 18, 20, 25, 30`):** The bottom scanline of the playfield adopts the HUD scroll split one line early (matching the original split timing, `2–6 px` offset on in-between frames); single frames can show sprite pixels on that HUD boundary line (`Room 18`). Heavy multi-enemy fights fall back briefly to the original layer cadence where needed.
- **Tigray Quarry (`Scene 17`):** About `8` edge cells hold brightness across exit fades. Cold boots and saves from earlier Redmont or story spots start smoothly across the gorge bridge (`0` choppy frames on step-2 discs); only saves made directly on the bridge while holding the D-pad continuously from lit frame `0` take `68–92` frames to finish restoring before scrolling smoothly.
- **Redmont street (`Scene 1`) carried items:** Crowd jitter (`32` held frames walking back and forth by the crowd on the right end), `7` known 2-frame street passes carried over from `0.1.0` (the two unpatched-quarry slow ticks and scene-0 VRAM leftover from `0.1.0` are gone in `0.2.0`), slightly shorter street fades (`4` frames), `1`-frame late menu opens on some phases, unrecognised text windows temporarily standing the layers down while open, and near-layer `2`-pixel camera step.
- **Pass-locked gameplay:** Play logic, enemy spawns, damage, and RNG match the untouched disc per game pass (`0` logic/RNG divergences on tested routes), while added dark load frames shift wall-clock timing so fixed-frame recordings diverge across loads.

## Building from source

Needs `python3`, `xdelta3` and `pceas`, the assembler of [HuC](https://github.com/jbrandwood/huc), commit `54f5c73` (pceas v4.10), on the PATH or named by the environment variable `PCEAS`. Another version of pceas may assemble other bytes; the build stops if the result is not the expected one.

Put your dump in `.local/`: its track files, and its cue named `disc.cue`. Then, from the top of the repository:

<!-- build steps -->
```sh
python3 tools/mkdisc.py
python3 tools/patch.py
```

`dist/disc/` then holds the patched disc (`disc.cue`), and `dist/` the patch `ys-iii-enhanced-0.2.0.xdelta` with `apply.py`, this file, `LICENSE`, `CREDITS.md`, `pregen/`, `edc130.py`, and the store manifest. `python3 tools/scan.py --tree` checks the repository's files by type (no disc, ROM, save or archive extension, no build folder, no file over 256 KB, nothing but UTF-8 text).

Credits: see CREDITS.md.
