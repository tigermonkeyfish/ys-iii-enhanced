#!/usr/bin/env python3
"""Apply the Ys III Enhanced patch to your own Redump-style cue/bin dump.

    python3 apply.py "Ys III - Wanderers from Ys (USA).cue"

The cue's file name does not matter; the Track 02 SHA-256 below does.

Needs xdelta3 on the PATH. Only the data track (Track 02) is changed; the audio
tracks and the cue are left as they are. The original track is kept beside it as
*.orig. A dump whose Track 02 file does not have the SHA-256 below is refused.

A release may carry a second step (a *.store.json file beside the patch). The
same command then runs it after the patch: graphics for one scene are computed
from your own track and written into it, and the finished track is checked
before it replaces yours. If the second step fails, the track is still patched
and plays; the message says what is missing, and the exit status is 3. Also:

    python3 apply.py --no-store "dump.cue"               the patch alone
    python3 apply.py --store ORIGINAL.bin PATCHED.bin    the second step alone, for a track patched with another tool
    python3 apply.py --verify TRACK.bin                  which track is this: not patched, patched, or patched with the second step
"""
import hashlib
import os
import re
import shutil
import signal
import stat
import subprocess
import sys
from pathlib import Path

EXPECTED = "32ae723dc05050c78a11ae1e8e3ece5d8a3a8f22ac2992baf0bac99e817d8dae"
PATCH_NAME = "ys-iii-enhanced-0.2.0.xdelta"
STORE_NAME = PATCH_NAME[:-len(".xdelta")] + ".store.json"       # the second step's manifest, beside the patch
STEP_FAILED = 3


def find_patch():
    here = Path(__file__).resolve().parent
    for p in (here / PATCH_NAME, here / "dist" / PATCH_NAME):
        if p.exists():
            return p
    sys.exit(f"{PATCH_NAME} not found beside apply.py or in dist/")


def data_track(cue):
    files, cur = [], None
    for line in cue.read_text(errors="replace").splitlines():
        t = line.strip().split(None, 1)
        if t and t[0].upper() == "FILE":
            m = re.match(r'"(.*)"|(\S+)', t[1])
            cur = cue.parent / (m.group(1) or m.group(2))
        elif t and t[0].upper() == "TRACK" and "MODE1" in t[1].upper():
            files.append(cur)
    if len(files) != 1:
        sys.exit("expected exactly one MODE1 track file in the cue (a dump with one file per track)")
    return files[0]


def patch_only(cue):
    """The patch alone: a release without a second step."""
    patch = find_patch()
    if not shutil.which("xdelta3"):
        sys.exit("xdelta3 is not on the PATH")
    track = data_track(Path(cue))
    if hashlib.sha256(track.read_bytes()).hexdigest() != EXPECTED:
        sys.exit(f"{track.name}: not the dump this patch was made for (sha256 mismatch)")
    backup = track.with_suffix(track.suffix + ".orig")
    shutil.copyfile(track, backup)
    new = track.with_suffix(track.suffix + ".new")
    subprocess.run(["xdelta3", "-d", "-f", "-s", str(backup), str(patch), str(new)], check=True)
    os.replace(new, track)
    print(f"patched {track.name} (original kept as {backup.name})")


# ---------------------------------------------------------------- the second step
def find_manifest():
    here = Path(__file__).resolve().parent
    for p in (here / STORE_NAME, here / "dist" / STORE_NAME):
        if p.exists():
            return p
    return None


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(1 << 20)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def load_step():
    """The second step's program (its folder pregen/ is beside apply.py, or in tools/ beside it) and None, or None and why not."""
    here = Path(__file__).resolve().parent
    sys.dont_write_bytecode = True
    for d in (here / "pregen", here / "tools" / "pregen"):
        if (d / "storestep.py").exists():
            sys.path.insert(0, str(d))
            try:
                import storestep
                return storestep, None
            except Exception as e:
                return None, f"its program does not load ({type(e).__name__}): unzip the release again, or use a newer Python"
    return None, "its program was not found beside apply.py (the folder pregen: unzip the release again)"


def pins(manifest):
    """(the manifest's track hashes, what is missing without the second step); (None, a general wording) for a file that cannot be read."""
    import json
    general = "one scene will use its fallback picture"
    try:
        m = json.loads(manifest.read_text(encoding="utf-8"))
        t = {k: m["track"][k] for k in ("untouched_sha256", "patched_sha256", "store_sha256")}
        if not all(isinstance(v, str) and len(v) == 64 for v in t.values()) or t["untouched_sha256"] != EXPECTED:
            return None, general
        n = m["store"].get("notice")
        return t, n if isinstance(n, str) and n.isprintable() and 0 < len(n) < 200 else general
    except Exception:
        return None, general


def second_step(manifest, original, patched):
    """Run the second step on PATCHED. Returns None when it is done, else the reason it is not; PATCHED is then as it was."""
    step, why = load_step()
    if step is None:
        return why
    try:
        step.add_store(original, patched, step.load_manifest(manifest))
    except step.StepError as e:
        return str(e)
    except KeyboardInterrupt:
        return "interrupted"
    except Exception as e:
        return f"its program stopped ({type(e).__name__})"
    return None


def stop_cleanly():
    """A request to stop (a kill, a closed terminal, Ctrl-\\, Ctrl-Break on Windows) is handled as Ctrl-C is: the temporary
    files are removed on the way out. A process killed outright can leave them; the next run removes them."""
    def stop(*_a):
        raise KeyboardInterrupt
    for name in ("SIGTERM", "SIGHUP", "SIGQUIT", "SIGBREAK"):       # the ones this system has
        try:
            signal.signal(getattr(signal, name), stop)
        except (AttributeError, OSError, ValueError):
            pass


def remove(path):
    """One of our own temporary files goes. Never an error of its own: a folder of that name, or a file another program holds, stays."""
    try:
        os.remove(path)
    except OSError:
        pass


def put_in_place(new, track):
    """os.replace. Windows refuses to replace a file marked read-only: there the mark is lifted first, and put back if the
    replace fails (by reading; not run on Windows). The new track is writable, as it is elsewhere."""
    mode = None
    if os.name == "nt":
        try:
            mode = os.stat(track).st_mode
            if mode & stat.S_IWRITE:
                mode = None
            else:
                os.chmod(track, mode | stat.S_IWRITE)
        except OSError:
            mode = None
    try:
        os.replace(new, track)
    except OSError:
        if mode is not None:
            try:
                os.chmod(track, mode)
            except OSError:
                pass
        raise


def patch_and_store(cue, manifest, store):
    """The patch, then the second step (store: False for --no-store). The track is replaced once, at the end."""
    patch = find_patch()
    if not shutil.which("xdelta3"):
        sys.exit("xdelta3 is not on the PATH")
    track = data_track(Path(cue))
    pin, notice = pins(manifest)
    backup = track.with_suffix(track.suffix + ".orig")
    new = track.with_suffix(track.suffix + ".new")
    part = track.with_suffix(track.suffix + ".orig.part")           # the copy of the original while it is being written
    for stale in (part, Path(str(new) + ".store-tmp"), Path(str(track) + ".store-tmp")):
        remove(stale)                                               # what a run that was killed outright may have left
    have = sha256(track)
    if have != EXPECTED:
        if pin and have == pin["store_sha256"]:
            sys.exit(f"{track.name}: already patched, second step included; nothing was changed (sha256 mismatch with the dump the patch applies to)")
        if pin and have == pin["patched_sha256"]:
            if not store:
                sys.exit(f"{track.name}: already patched; nothing was changed (sha256 mismatch with the dump the patch applies to)")
            if not backup.exists():
                sys.exit(f"{track.name}: already patched, without the second step, and {backup.name} is not beside it: "
                         f"run apply.py --store ORIGINAL PATCHED with your own copy of the dump's Track 02 (sha256 mismatch with the dump the patch applies to)")
            if not backup.is_file() or sha256(backup) != EXPECTED:
                sys.exit(f"{track.name}: already patched, without the second step, and the {backup.name} beside it is not the untouched track "
                         f"(an unfinished copy, or another file: sha256 mismatch): run apply.py --store ORIGINAL PATCHED with your own copy of the dump's Track 02")
            why = second_step(manifest, backup, track)        # a second run after a failed second step: from the kept original
            if why:
                print(f"{track.name} is patched and plays, but the second step did not finish ({why}): {notice}.", file=sys.stderr)
                return STEP_FAILED
            print(f"{track.name}: the second step was added (it was already patched; original kept as {backup.name})")
            return 0
        sys.exit(f"{track.name}: not the dump this patch was made for (sha256 mismatch)")
    if new.is_dir():
        sys.exit(f"{track.name}: {new.name} beside it is a folder, and the patch writes a file of that name: move the folder away; the track was not changed")
    kept = False
    try:
        try:                                                        # the original is copied under another name and renamed when it is whole:
            shutil.copyfile(track, part)                            # a copy that stops halfway is never left looking like the original
            os.replace(part, backup)
            kept = True
        except OSError as e:
            sys.exit(f"{track.name}: the copy of the original ({backup.name}) could not be written ({e.strerror or type(e).__name__}); "
                     f"the track was not changed, and no unfinished copy was left")
        r = subprocess.run(["xdelta3", "-d", "-f", "-s", str(backup), str(patch), str(new)])
        if r.returncode:
            sys.exit(f"{track.name}: xdelta3 did not apply the patch (exit {r.returncode}); the track was not changed")
        if pin and sha256(new) != pin["patched_sha256"]:
            sys.exit(f"{track.name}: the patch did not give the track it should (sha256 mismatch after xdelta3); the track was not changed")
        why = None
        if store:
            why = second_step(manifest, track, new) if pin else "its manifest does not belong to this patch"
        try:
            put_in_place(new, track)
        except OSError as e:
            sys.exit(f"{track.name}: the patched track could not be put in its place ({e.strerror or type(e).__name__}): close any program "
                     f"that has the track open and run this again; the track was not changed (original kept as {backup.name})")
    except KeyboardInterrupt:
        sys.exit(f"{track.name}: interrupted before the patch was applied; the track was not changed"
                 + (f" (a copy of it is beside it as {backup.name})" if kept else ""))
    finally:
        remove(part)
        remove(new)
    if why:
        print(f"{track.name} is patched and plays (original kept as {backup.name}), but the second step did not finish ({why}): {notice}.", file=sys.stderr)
        return STEP_FAILED
    print(f"patched {track.name} (original kept as {backup.name})" + (", second step included" if store else "; the second step was left out (--no-store)"))
    return 0


def main():
    args = sys.argv[1:]
    manifest = find_manifest()
    if args[:1] in (["--store"], ["--verify"]) and len(args) == (3 if args[0] == "--store" else 2):
        stop_cleanly()
        step, why = load_step() if manifest else (None, f"this release has none: {STORE_NAME} is not beside apply.py")
        if step is None:
            if args[0] == "--verify":
                sys.exit(f"{Path(args[1]).name} could not be checked: the second step is not here ({why})")
            print(f"{Path(args[2]).name} was not changed (the second step is not here: {why})"
                  + (f": it plays as it is, and {pins(manifest)[1]}." if manifest else "."), file=sys.stderr)
            return STEP_FAILED
        return step.run_store(manifest, args[1], args[2]) if args[0] == "--store" else step.run_verify(manifest, args[1])
    store = "--no-store" not in args
    rest = [a for a in args if a != "--no-store"]
    if len(rest) != 1 or rest[0].startswith("--"):
        sys.exit(__doc__ or "python3 apply.py CUE")
    if manifest is None:
        return patch_only(rest[0])
    stop_cleanly()
    return patch_and_store(rest[0], manifest, store)


if __name__ == "__main__":
    sys.exit(main())
