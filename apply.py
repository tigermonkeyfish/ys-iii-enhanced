#!/usr/bin/env python3
"""Apply the Ys III Enhanced patch to your own Redump-style cue/bin dump.

    python3 apply.py "Ys III - Wanderers from Ys (USA).cue"

The cue's file name does not matter; the Track 02 SHA-256 below does.

Needs xdelta3 on the PATH. Only the data track (Track 02) is changed; the audio
tracks and the cue are left as they are. The original track is kept beside it as
*.orig. A dump whose Track 02 file does not have the SHA-256 below is refused.
"""
import hashlib
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

EXPECTED = "32ae723dc05050c78a11ae1e8e3ece5d8a3a8f22ac2992baf0bac99e817d8dae"
PATCH_NAME = "ys-iii-enhanced-0.1.0.xdelta"


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


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    patch = find_patch()
    if not shutil.which("xdelta3"):
        sys.exit("xdelta3 is not on the PATH")
    track = data_track(Path(sys.argv[1]))
    if hashlib.sha256(track.read_bytes()).hexdigest() != EXPECTED:
        sys.exit(f"{track.name}: not the dump this patch was made for (sha256 mismatch)")
    backup = track.with_suffix(track.suffix + ".orig")
    shutil.copyfile(track, backup)
    new = track.with_suffix(track.suffix + ".new")
    subprocess.run(["xdelta3", "-d", "-f", "-s", str(backup), str(patch), str(new)], check=True)
    os.replace(new, track)
    print(f"patched {track.name} (original kept as {backup.name})")


if __name__ == "__main__":
    main()
