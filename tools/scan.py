#!/usr/bin/env python3
"""Check by file type that no disc or ROM file is in this repository. It does not recognise game bytes inside a text file.

    python3 tools/scan.py --tree             the working tree as git sees it
    python3 tools/scan.py --history [RANGE]  every blob ever committed
    python3 tools/scan.py --staged           the files about to be committed

A file is rejected when ANY of these holds:
  * its extension is a disc/ROM/save/archive type (.cue .bin .iso .chd .img .pce .ccd .sub .mdf .mds
    .nrg .toc .wav .ogg .flac .mp3 .brm .sav .state .mmo .zip .7z .rar .gz .tar .xz .bz2)
  * it is under .local/ build/ captures/ dist/ roms/
  * it is larger than MAX_BYTES (262,144)
  * it is not UTF-8 text with no NUL byte: raw disc sectors and ROM images fail this
Exit 1 with the list of offenders; exit 0 when clean.
"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True).stdout.strip() or ".")
MAX_BYTES = 262_144
BAD_EXT = {".cue", ".bin", ".iso", ".chd", ".img", ".pce", ".ccd", ".sub", ".mdf", ".mds", ".nrg", ".toc",
           ".wav", ".ogg", ".flac", ".mp3", ".brm", ".sav", ".state", ".mmo",
           ".zip", ".7z", ".rar", ".gz", ".tar", ".xz", ".bz2"}
BAD_DIRS = ("local/", ".local/", "build/", "captures/", "dist/", "roms/")


def check(path, data):
    p = path.replace("\\", "/")
    ext = Path(p).suffix.lower()
    if ext in BAD_EXT:
        return f"forbidden extension {ext}"
    if any(p.startswith(d) or f"/{d}" in p for d in BAD_DIRS):
        return "lives in a disc-data folder"
    if len(data) > MAX_BYTES:
        return f"{len(data)} bytes > {MAX_BYTES}"
    if b"\0" in data:
        return "binary file"
    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        return "not UTF-8 text"
    return None


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, cwd=ROOT).stdout


def staged():
    for p in git("diff", "--cached", "--name-only", "--diff-filter=AM", "-z").decode().split("\0"):
        if p:
            yield p, git("show", f":{p}")


def tree():
    for p in git("ls-files", "-z").decode().split("\0"):
        if p and (ROOT / p).is_file():
            yield p, (ROOT / p).read_bytes()


def history(rng):
    args = ["rev-list", "--objects", rng] if rng else ["rev-list", "--objects", "--all"]
    seen = set()
    for line in git(*args).decode(errors="replace").splitlines():
        parts = line.split(" ", 1)
        if len(parts) == 2 and parts[0] not in seen:
            seen.add(parts[0])
            kind = git("cat-file", "-t", parts[0]).decode().strip()
            if kind == "blob":
                yield f"{parts[1]} @{parts[0][:8]}", git("cat-file", "-p", parts[0])


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "--staged"
    rng = sys.argv[2] if len(sys.argv) > 2 else ""
    items = {"--staged": staged, "--tree": tree, "--history": lambda: history(rng)}[mode]()
    bad = []
    n = 0
    for p, data in items:
        n += 1
        why = check(p.split(" @")[0], data)
        if why:
            bad.append((p, why))
    if bad:
        print("scan: these files are not allowed in this repository:", file=sys.stderr)
        for p, why in bad:
            print(f"  {p}: {why}", file=sys.stderr)
        sys.exit(1)
    print(f"scan: {n} files clean ({mode})")


if __name__ == "__main__":
    main()
