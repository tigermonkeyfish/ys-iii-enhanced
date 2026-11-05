#!/usr/bin/env python3
"""Cue/bin parsing and the data track (imported by tools/mkdisc.py and tools/patch.py); sector parity is tools/edc130.py."""
import re
import sys
from pathlib import Path

from edc130 import seal_mode1

RAW = 2352
USER = 2048
SYNC = b"\x00" + b"\xff" * 10 + b"\x00"


def encode_sector(sector):
    """Return the sector with EDC and P/Q parity recomputed (sync and header kept). seal_mode1 does not read the mode byte: checked here."""
    s = bytearray(sector)
    assert len(s) == RAW and s[:12] == SYNC and s[15] == 1, "not a Mode 1 raw sector"
    seal_mode1(s)
    return bytes(s)


# ---------------------------------------------------------------- cue sheet
def msf_to_frames(s):
    m, sec, f = (int(x) for x in s.split(":"))
    return (m * 60 + sec) * 75 + f


def parse_cue(cue_path):
    """[{num, mode, file, index1, size}] with byte offsets resolved per file."""
    cue_path = Path(cue_path)
    tracks, cur_file = [], None
    for line in cue_path.read_text(errors="replace").splitlines():
        t = line.strip().split(None, 1)
        if not t:
            continue
        key = t[0].upper()
        if key == "FILE":
            m = re.match(r'"(.*)"|(\S+)', t[1])
            cur_file = cue_path.parent / (m.group(1) or m.group(2))
        elif key == "TRACK":
            num, mode = t[1].split()
            tracks.append({"num": int(num), "mode": mode.upper(), "file": cur_file, "indexes": {}})
        elif key == "INDEX":
            idx, pos = t[1].split()
            tracks[-1]["indexes"][int(idx)] = msf_to_frames(pos)
    # byte ranges: one file per track (Redump) or one file for all (positions in frames of 2352 bytes)
    for i, tr in enumerate(tracks):
        start = tr["indexes"].get(1, tr["indexes"].get(0, 0))
        same_file_next = [u for u in tracks[i + 1:] if u["file"] == tr["file"]]
        if same_file_next:
            end = min(same_file_next[0]["indexes"].values())
        else:
            end = tr["file"].stat().st_size // RAW if tr["file"].exists() else None
        tr["start"], tr["end"] = start, end
    return tracks


def data_track(tracks):
    for tr in tracks:
        if tr["mode"].startswith("MODE1"):
            return tr
    sys.exit("no MODE1 track in the cue")


def read_track(tr):
    data = tr["file"].read_bytes()
    if tr["mode"] != "MODE1/2352":
        sys.exit(f"track {tr['num']} is {tr['mode']}: only MODE1/2352 (raw) dumps are supported")
    return data[tr["start"] * RAW:tr["end"] * RAW]

