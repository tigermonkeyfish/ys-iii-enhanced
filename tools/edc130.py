# MIT License. EDC/ECC code was written from the published ECMA-130 standard
# (2nd edition, 1996).
"""EDC and RSPC parity for 2352-byte Mode 1 CD-ROM sectors (ECMA-130)."""

# --- EDC: clause 14.3 -------------------------------------------------------
# 32-bit CRC over bytes 0..2063; the least significant bit of each byte goes
# first; the codeword is divisible by (x^16+x^15+x^2+1)(x^16+x^2+x+1); the x^0
# parity bit lies in the most significant bit of byte 2067 (so the register,
# kept bit-reversed, is stored least significant byte first).


def _clmul(a, b):
    r = 0
    while b:
        if b & 1:
            r ^= a
        a <<= 1
        b >>= 1
    return r


_POLY = _clmul(0x18005, 0x10007) & 0xFFFFFFFF  # drop the x^32 term
_RPOLY = int(format(_POLY, '032b')[::-1], 2)    # bit-reversed for LSB-first


def _make_crc_table():
    t = []
    for i in range(256):
        c = i
        for _ in range(8):
            c = (c >> 1) ^ _RPOLY if c & 1 else c >> 1
        t.append(c)
    return t


_CRC = _make_crc_table()


def edc(data: bytes) -> bytes:
    """4-byte EDC of data (zero initial value), as stored in the sector."""
    c = 0
    t = _CRC
    for b in data:
        c = (c >> 8) ^ t[(c ^ b) & 0xFF]
    return c.to_bytes(4, 'little')


# --- RSPC: annex A ----------------------------------------------------------
# GF(2^8) with field polynomial x^8+x^4+x^3+x^2+1 (A.3), primitive element a = 0x02.
_EXP = [0] * 255
_LOG = [0] * 256
_x = 1
for _i in range(255):
    _EXP[_i] = _x
    _LOG[_x] = _i
    _x <<= 1
    if _x & 0x100:
        _x ^= 0x11D


def _mul_table(k):
    """Translate table: multiply every byte by a^k."""
    return bytes([0] + [_EXP[(_LOG[v] + k) % 255] for v in range(1, 256)])


_MUL = [_mul_table(k) for k in range(45)]
_INV = _mul_table(255 - _LOG[_EXP[1] ^ 1])  # times 1/(a + 1)


def _parity_rows(rows, n):
    """Parity for one batch of equal-length codewords (A.3).

    rows[m] holds element m of every codeword (m = 0..n-3, the data part).
    Check matrix H = [1 ... 1; a^(n-1) ... a^1 a^0] over the n-element vector,
    whose last two elements are the parity bytes p0, p1:
      sum = s0 + p0 + p1 = 0,  s1 + a*p0 + p1 = 0
    with s0 = sum of data, s1 = sum of a^(n-1-m)*data[m].
    Hence p0 = (s0 + s1)/(a + 1) and p1 = s0 + p0. Rows are combined as big
    integers so one XOR handles every codeword of the batch.
    """
    w = len(rows[0])
    s0 = s1 = 0
    for m, r in enumerate(rows):
        s0 ^= int.from_bytes(r, 'little')
        s1 ^= int.from_bytes(r.translate(_MUL[n - 1 - m]), 'little')
    p0 = int.from_bytes(
        (s0 ^ s1).to_bytes(w, 'little').translate(_INV), 'little')
    return p0.to_bytes(w, 'little'), (s0 ^ p0).to_bytes(w, 'little')


def _rspc(plane):
    """Fill the parity part of one byte plane (all LSBs or all MSBs).

    plane has 1170 entries, entry n being the byte of word S(n) (A.2).
    """
    # P: 43 vectors of 26 elements, element Mp of vector Np is S(43*Mp+Np);
    # the last two elements (Mp = 24, 25) are parity (A.3).
    rows = [bytes(plane[43 * m:43 * m + 43]) for m in range(24)]
    p0, p1 = _parity_rows(rows, 26)
    plane[1032:1075] = p0
    plane[1075:1118] = p1
    # Q: 26 vectors of 45 elements, element Mq of vector Nq is
    # S((44*Mq + 43*Nq) mod 1118); the last two (Mq = 43, 44) are parity,
    # stored as S(1118+Nq) and S(1144+Nq). Uses the P parity just computed.
    ext = bytes(plane[:1118]) * 2
    rows = [ext[44 * m % 1118:][:1076:43] for m in range(43)]
    q0, q1 = _parity_rows(rows, 45)
    plane[1118:1144] = q0
    plane[1144:1170] = q1


def seal_mode1(sector: bytearray) -> None:
    """Set EDC, intermediate zero bytes, P and Q parity of a Mode 1 sector.

    Bytes 0..2063 (sync, header, user data) must be in place. Layout per
    clause 14: EDC 2064..2067, zeros 2068..2075, P 2076..2247, Q 2248..2351.
    """
    if len(sector) != 2352:
        raise ValueError('sector must be 2352 bytes')
    sector[2064:2068] = edc(sector[:2064])
    sector[2068:2076] = bytes(8)
    # Words are pairs (A.2): S(n) = MSB B(2n+13), LSB B(2n+12), over bytes
    # 12..2351; the RSPC runs once on the LSBs and once on the MSBs.
    lsb = bytearray(sector[12::2])
    msb = bytearray(sector[13::2])
    _rspc(lsb)
    _rspc(msb)
    sector[12::2] = lsb
    sector[13::2] = msb
