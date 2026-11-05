# Ys III Enhanced 0.1.0: smooth parallax patch for Ys III: Wanderers from Ys (TurboGrafx-CD, USA)

This version covers the Redmont street. Source and releases: https://github.com/tigermonkeyfish/ys-iii-enhanced

Unofficial fan project. Not affiliated with or endorsed by Nihon Falcom, Hudson Soft, Konami or NEC. Ys is a trademark of its owners.

Makes the main street of Redmont, the first town, scroll smoothly. Where the game moves the clouds and the back wall in chunks, the clouds now hold still and the back wall moves one pixel at a time while walking. Measured over the walk on the street, the clouds go from a 6-pixel step to none, and the back wall moves 1 pixel at a time in 87% of moving frames, where the original's never does. The layers are smooth from the first visible frame of the street, also right after Continue from a save, which costs a dark screen about half a second longer at three places (see Known issues). Known issues are listed below; more numbers are in CHANGELOG.md in the source repository.

The patch holds no game data, and you need your own dump of the game to use it. The code is MIT licensed (see LICENSE); the licence covers this project's own code only, not the game.

EDC/ECC code was written from the published ECMA-130 standard.

## Requirements

- Your own Redump-style cue/bin dump of **Ys III - Wanderers from Ys (USA)** (Redump, TGXCD1015; some dats name it "(USA) (Rev 1)", and either name is this dump), one file per track. Its Track 02 file is 58701216 bytes, with CRC32 `2438E447`, MD5 `10DDBD55A98BAF64DF1C64064EF17242` and SHA-1 `FDA4ECAB121DB0AB443956DCDF236A0F38868F73`, and it must have this SHA-256; the patcher checks only the SHA-256 and refuses anything else, including other revisions of the game:
  `32ae723dc05050c78a11ae1e8e3ece5d8a3a8f22ac2992baf0bac99e817d8dae`
- `python3` and `xdelta3` on the PATH.
- To play: a **Super System Card 3.0**, or a TurboDuo / PC Engine Duo, which has the 3.0 card built in. The patched disc tests for that card's RAM at boot and stops with a message if it is absent. We saw that message only with a 3.0 card's RAM switched off, on two emulators. That message has not been tried on hardware or with an older card, and we make no claim for 1.0 or 2.x cards.

## How to apply

Download `ys-iii-enhanced-0.1.0.zip` from the repository's Releases page and unzip it. It holds `apply.py`, `ys-iii-enhanced-0.1.0.xdelta`, this file, `LICENSE` and `CREDITS.md`, and no game data. From that folder, with the path to your dump's cue:

<!-- apply step -->
```sh
python3 apply.py "Ys III - Wanderers from Ys (USA).cue"
```

The cue's file name does not matter; the Track 02 SHA-256 does.

Only the Track 02 file is changed; the audio tracks and the cue are left as they are. The original is kept beside it as `*.orig`. Run the patched cue on an emulator or on hardware with one of the cards above.

## What is covered

- **The Redmont main street only.** The patch has no code for any other town or area. Its hooks stay in the game's main loop everywhere, and the tests below cover only the routes they name: the street, two shop doors, the gate, the map, the first fight in the quarry (the first area outside town), and a death there. Menus are opened in three of the tests: the game-logic comparison has a route on the street that opens Equipment twice, Status and Message; the menu-closing check closes Equipment, Status, Message, Load and Save at several places and compares the first pictures after each close (28 closes); and the whole-route picture test opens one menu. The menu-closing check covers only the street positions and waits it names; we have not shown that the first picture matches at other positions. Load is not in the game-logic comparison (see Known issues). Talking to townspeople is covered by its own check (the talk-window check): at several street positions (around camera positions 600, 950, 1000 and 1100, also after closing Equipment and after a Load) it talks to a townsperson and compares the text window and everything around it with the original, frame by frame on Geargrafx (14 talks) and by what the video chip is given on Mesen2 (17 talks); windows the patch does not know are under Known issues. None of the comparison routes saves; the save test is separate (see Not tested).
- A later copy of the street, later in the story, keeps the game's own display and is not smoothed in this version.

## Tested on

Three targets are meant: a real CD drive, the Krikzz Turbo EverDrive Pro and the MiSTer, each with a Super System Card 3.0 (or a Duo). Status of each for this version's disc:

- **Turbo EverDrive Pro** (on a TurboGrafx-16): **tested on this disc, 2026-11-05, by one person.** They reported: "The patch works on the everdrive the parallax is good." They saved, powered off and loaded again with Continue (and made a fresh load), and the parallax was good. The crowd scene and the walk by the crowd were not watched there, and the other sheet items were not reported. Earlier, one person played two earlier discs of this patch there, one made before the talking-window fix and one after, neither a full test; on the second they reported that after Continue from a save the street's background raced like the original's for a moment, which is what this version's longer black screen is for (emulator numbers in Known issues).
- **Real CD, a burned disc, on a TurboDuo-class console (a PC Engine Duo-RX with its built-in drive and System Card 3.0):** **tested on this disc, 2026-11-05, by one person.** They reported: "I can officially play off of cd. I loaded the cd, saved, powered off, reloaded, parallax is good. The crowd conversation seems correct." So saving, powering off and Continue, and the crowd scene, were good on a real disc. The first disc they burned (on Linux with cdrdao, from the bin/cue) did not load; a second burn with ImgBurn on Windows did. That is what happened in this one case, not a statement about either tool in general; if your own burn does not load, try another burning program before suspecting the patch. The other sheet items and the feel of the longer black screens were not reported.
- **MiSTer:** not tested. Nobody has run this patch there, and we make no claim for it.

The Duo-RX test above is on a burned disc only. The other numbers here are from two emulators, Geargrafx and Mesen2, and are from Geargrafx unless they say otherwise.

## Known issues

All of these are known defects or differences on this version's disc. We mean to revisit them when we know more. The dark-screen, first load, death and save figures below were measured on this version's disc (Geargrafx, and Mesen2 where named); the fade figures are from the previous version of this patch and were not measured again.

- **A jitter where the crowd stands on the street.** Seen on the hardware named above, on the disc made before the talking-window fix; easy to repeat by walking back and forth there. On the emulators it shows as held frames: on a scripted walk back and forth at the street's right end (camera 1440 to 1520) the patched game repeats the frame before on 32 frames (the same on both emulators) where the original repeats none; that count is from the previous version of this patch and was not measured again on this disc. Traced there to game passes that take two frames: the patch's whole redraw and tile upload at a tile boundary right after a stand or a turn. One of three causes is fixed in this version; the other two remain, so the jitter is reduced, not gone. That the console's jitter is these held frames is likely (same place, same motion) but not shown.
- **Missed frames: 9 known defects, to revisit.** A game pass that takes 2 frames where the original's takes 1. Over five test routes, outside loads: 19 such passes on the patched game, 17 on the original, 9 on the patched game only. We accept those 9 for this version, one by one; any other fails our release check.

  | Route | Patched | Original | Patched only |
  |---|---|---|---|
  | Walking both ways on the street | 0 | 0 | 0 |
  | The crowd text and the pan after it | 6 | 2 | 5 |
  | A long stand, then walking back | 5 | 6 | 2 |
  | To a shop door | 2 | 4 | 0 |
  | A fight in the quarry | 6 | 5 | 2 |

  Of the 9: 3 just after the crowd text, as the view moves left from the street's right end, within about 10 passes (cameras 1518 to 1502); 2 later in that pan, where the game itself is heavy (1316, 1172); 2 at the turn after a long stand (1516, 1494); 2 in the quarry, where the patch's renderer does not run (592, 178): we traced those to the two games reaching that area at another point of the frame.
- **Longer dark screens, about half a second each.** The patch builds its tables while the screen is black after an area loads, so the street's first picture already has the smooth layers; before, on the console, the game's own stepping layers showed for about 1.4 seconds after Continue. On both emulators the dark screen is 30 vertical blanks (frames) longer than on the previous version of this patch: Continue from power on 385 against 355 on Geargrafx and 388 against 358 on Mesen2 (a second save 386 against 356 and 389 against 359); a new game's first entry to the street (the crowd scene at the street's right end, where the layers first show) 106 against 76 and 105 against 75; the street after a death in the quarry 111 against 81 and 107 against 77. The inn's two loads are the same length as before. On Mesen2 the gate load on the way back from a death is 32 longer as well (255 against 223); on Geargrafx it is not (221 both). Walking right at once from the first visible frame after Continue (two saves) and after a new game's first entry, and walking left at once after a death, no moving frame lacks the smooth layers: 0 of 283, 287, 206 and 124 moving frames on Geargrafx and 0 of 284, 288, 207 and 124 on Mesen2; the previous version of this patch had 66 and 83 such frames on Continue (two saves, same on both emulators).
- **After these longer blacks the game's clocks (its CPU timer, its frame counters) stand where a slower drive would leave them, so single frames can fall differently than on another console, as they do between consoles on the original disc.** One measured instance, on Geargrafx only: in the crowd scene after a new game's first entry, the pan begins and the scene ends about 30 frames (half a second) sooner after the screen lights than on the previous version of this patch, at the same time since power on, because the longer black is taken out of the lit scene, in which Adol walks on his own; so he ends it about 8 tiles further left. On Mesen2 the scene is the same frame for frame. The camera, random numbers and HP are otherwise equal through the quarry, a death and the return. The cause is not established.
- **The first load of the street** is 101 frames longer than the original: one dark screen, once (the 71 frames it was before plus the 30 above; measured by lining up the load, 0 differing bytes at that alignment).
- **Townspeople are drawn up to 8 pixels from where the original draws them.** The original moves a walking townsperson 8 pixels at a time; this patch draws the steps one pixel a frame. The game's own positions match, measured on one route.
- **A menu's first picture can come one frame late.** Opening Equipment at one of the two spots measured, and closing Load or Save at two of three: one extra black frame, then the right picture.
- **Opening and closing the Load screen leaves the game 2 frames ahead of the original, in the same session.** Measured on Geargrafx, on Load, on an earlier disc of this patch (on this version's disc only the pixel results below were measured); Save was not measured for this: the Load list comes up 4 frames earlier and its close runs 2 frames earlier, and the 2 frames then stay the same for 71 seconds of play (4257 game passes), neither growing nor shrinking. After a load from a fresh boot with Continue, 150 frames of walking end 4 pixels behind the original's camera instead (1396 against 1400, measured on this disc; the same-session load ends 2 ahead, 1400 against 1398; we do not know why the sign differs, and the 4 px is two game ticks of the load's input timing). Up to 4 pixels, ahead or behind depending on the path. With the patched game's inputs moved by those frames, every comparison rule passes. Two internal values of the game stay different for a time: a per-frame counter stays at another value for at least those 71 seconds, and a countdown matches again after about 170 to 200 passes. We do not know what reads either of them, so we cannot say they have no effect. The game-logic comparison does not cover Load for this reason; the menu-closing check looks only at Load's pictures.
- **Two fades in the street run 4 frames shorter:** the same palette steps, 0.07 s quicker. Over a walk from the street through the quarry to the game over screen the patched game takes 10 frames fewer (12400 against 12410); the quarry's three fades are equal to the original's. Fades of Load and Save are shorter too.
- **After a death in the quarry** the street is now smooth from the first visible frame (0 of 124 moving frames without the smooth layers, walking left at once, on both emulators), at the price of the longer dark screens above.
- **Random numbers match per game pass, not per frame.** On the routes tested we measured the same generator value at the end of every game pass as the original, drawn the same number of times: 0 differing ticks over 3904, 2393, 1193, 1151 and 12340 ticks (crowd text and pan, long stand, shop door, quarry fight, the whole walk), with 0, 0, 0, 46 and 40 draws, equal on both games; a deliberately altered generator value is caught (950 of 1151 ticks differ). By frame it differs: each fade moves the frame count, so a recording that plays inputs on fixed frames (a TAS movie made on the original, say) drifts out of step after the first fade. Not run on Mesen2.
- **Text windows the patch does not know.** Talking to someone on the street keeps the smooth layers in this version: at the 14 talks measured on Geargrafx (camera positions 600 to 1150, and the crowd's) the clouds and back wall do not step when the window opens or closes, and the window matches the original's; it opens and closes on the original's frame at 11 of them and opens one frame earlier at 3. A window the patch's rule does not cover (another kind of window, a frame over 5 rows or 8 columns, or no room left in its tile pool) makes the patch stand down while the window is up: the picture is the original's, the clouds and back wall step once when it opens and glide back over a few frames after it closes. No window on the street we measured does this, and the shop windows and the Load and Save lists do not touch the patch's tiles; windows elsewhere in the game were not measured.
- **Same as the original, not improved:** the near layer moves 2 pixels in a step while walking (the camera's own step). We measured 1 skipped frame over the walk, a stall of the camera itself, and 2 on the original.

## Not tested

Other Duo models, and an original disc in a Duo. Real older System Cards. Bosses. Confirmed kills, and other fights in story order. Saving and loading beyond one save on the street, and the sheet items other than those named under Tested on: on this disc, on Geargrafx, that save was byte for byte the same as the original's (30 non-zero bytes of 2048; saving is not the fixed part, Continue is), and all four loads (each game's save on each game, from a fresh boot) came back on the street at camera 1104 with HP 20. After 150 frames of walking right from the load, the patched game's camera was 2 pixels ahead of the original's in the same session and 4 pixels behind from a fresh boot with Continue, in line with the Load difference above; we did not look further. Not run on Mesen2. Anything past the routes named here.

## What was and was not compared

Against the original on Geargrafx, on scripted routes from power on or a saved state, we compared game memory at the moments where both games are at the same point of a game pass, and Adol's position, his HP and the camera at the end of every pass: HP never differs; on the worst route the camera differs on 2 of 3836 passes and Adol's position on 1 of 516, each a one-pass slip. Over 100 passes of the crowd text where those moments do not line up, we compared every instruction of the game's threads instead. Saving and loading are not part of the game-logic comparison. This covers what those routes reach, not the whole game.

## Building from source

Needs `python3`, `xdelta3` and `pceas`, the assembler of [HuC](https://github.com/jbrandwood/huc), commit `54f5c73` (pceas v4.10), on the PATH or named by the environment variable `PCEAS`. Another version of pceas may assemble other bytes; the build stops if the result is not the expected one.

Put your dump in `.local/`: its track files, and its cue named `disc.cue`. Then, from the top of the repository:

<!-- build steps -->
```sh
python3 tools/mkdisc.py
python3 tools/patch.py
```

`dist/disc/` then holds the patched disc (`disc.cue`), and `dist/` the patch `ys-iii-enhanced-0.1.0.xdelta` with `apply.py`, this file, `LICENSE` and `CREDITS.md`. `python3 tools/scan.py --tree` checks the repository's files by type (no disc, ROM, save or archive extension, no build folder, no file over 256 KB, nothing but UTF-8 text); it does not recognise game bytes inside text. CI runs it over the whole history too.

Credits: see CREDITS.md.
