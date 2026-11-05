#!/usr/bin/env python3
"""A VCDIFF (RFC 3284) encoder that `xdelta3 -d` applies, for two files of the same length.

Every byte equal to the source at the same offset is a copy from the source, one byte long if need be, so the
patch's added data holds only bytes that differ from the source at their place. A general encoder (`xdelta3 -e`) also
adds short stretches of unchanged bytes between changes, because a copy costs more than it saves there; this one never does.
"""
import zlib

WINDOW = 1 << 23
VCD_SOURCE, VCD_ADLER32 = 0x01, 0x04
OP_ADD, OP_COPY = 1, 19        # default code table: ADD and COPY mode 0 (VCD_SELF), the size given as a varint


def varint(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.append(0x80 | (n & 0x7F))
        n >>= 7
    return bytes(reversed(out))


def changes(a, b):
    """[(start, end)] of the runs where b differs from a."""
    out, i, n = [], 0, len(a)
    while i < n:
        step = min(4096, n - i)
        if a[i:i + step] == b[i:i + step]:
            i += step
            continue
        for j in range(i, i + step):
            if a[j] != b[j]:
                if out and out[-1][1] == j:
                    out[-1][1] = j + 1
                else:
                    out.append([j, j + 1])
        i += step
    return [tuple(r) for r in out]


def window(src, tgt, start, end, runs):
    data, inst, addr = bytearray(), bytearray(), bytearray()
    pos = start
    for a, b in runs:
        if a > pos:
            inst += bytes([OP_COPY]) + varint(a - pos)
            addr += varint(pos - start)
        inst += bytes([OP_ADD]) + varint(b - a)
        data += tgt[a:b]
        pos = b
    if end > pos:
        inst += bytes([OP_COPY]) + varint(end - pos)
        addr += varint(pos - start)
    size = end - start
    body = varint(size) + bytes([0]) + varint(len(data)) + varint(len(inst)) + varint(len(addr)) + zlib.adler32(tgt[start:end]).to_bytes(4, "big") + bytes(data) + bytes(inst) + bytes(addr)
    return bytes([VCD_SOURCE | VCD_ADLER32]) + varint(size) + varint(start) + varint(len(body)) + body


def encode(src, tgt):
    """VCDIFF bytes that make tgt from src. Windows of 8 MB, each copying from the same range of the source."""
    if len(src) != len(tgt):
        raise ValueError("source and target differ in length")
    runs = changes(src, tgt)
    out = bytearray(b"\xd6\xc3\xc4\x00\x00")
    for start in range(0, len(tgt), WINDOW):
        end = min(start + WINDOW, len(tgt))
        cut = []
        for a, b in runs:
            if b > start and a < end:
                cut.append((max(a, start), min(b, end)))
        out += window(src, tgt, start, end, cut)
    return bytes(out)
