"""pce.py: the machine around huc6280.py for the patch-time tools (our own code, pure Python, standard library only).

What is modelled is what a routine that loads and unpacks data touches: the video chip's address / data ports with VRAM (write and
read pointers, the increment, the VRAM-to-VRAM copy), the colour table port, the work RAM, the CD RAM banks, the ADPCM memory, and
the System Card calls such a routine makes, by their documented behaviour (no System Card code is used or needed):
    cd_read ($E009)   sectors of the player's data track into memory (local address or a mapped page)
    ad_trans ($E033)  sectors of the player's data track into the ADPCM memory
    ad_read ($E036)   ADPCM memory into memory or VRAM;  ad_write ($E039) the reverse
    and the calls in Machine.NOP, which only report success (sound, CD audio, pad).
A call that is not modelled stops the run with its address (Machine.trap): nothing is guessed.
The vertical interrupt is modelled as the System Card's handler behaves with the mode byte the game sets (see Machine.vblank).
Nothing of the game is in this file; every byte comes from the track given at run time.
"""
import hashlib
from huc6280 import Cpu

# The stub page's wait, built from the instruction set and the System Card's documented frame counter (no byte list):
# LDA abs / CMP abs / BEQ back to the compare / RTS.
LDA_ABS, CMP_ABS, BEQ, RTS = 0xAD, 0xCD, 0xF0, 0x60  # own: standard 6502 / HuC6280 instruction opcodes
FRAME_COUNT = 0x2241                           # the System Card's vertical-interrupt counter (rndseed)


def _abs(op, addr):
    return bytes((op, addr & 255, addr >> 8))


def _branch(op, back):
    """a relative branch that goes `back` bytes before its own first byte"""
    return bytes((op, (-(back + 2)) & 255))


WAIT_SHAPE = _abs(LDA_ABS, FRAME_COUNT) + _abs(CMP_ABS, FRAME_COUNT) + _branch(BEQ, len(_abs(CMP_ABS, FRAME_COUNT))) + bytes((RTS,))

RAW, USER = 2352, 2048
class Track:
    """the player's data track (raw 2352-byte sectors, or 2048-byte user data), read by the game's sector numbers. ipl_sha: the
    SHA-256 of user bytes 32-54 of sector 1 (the boot record's fixed text): finds sector 0 in a file with or without the
    track's pregap and proves it is a boot track; None: the file starts at sector 0.
    path: a file's name (the whole file is read, as before), or bytes, or (lazy=True) a file's name whose sectors are read from
    the file as they are asked for: no copy of the track in memory (close() when done; the patch-time step uses this)."""

    def __init__(self, path, ipl_sha=None, lazy=False):
        self.f = None
        if isinstance(path, (bytes, bytearray)):
            self.d, self.len = path, len(path)
        elif lazy:
            self.f = open(path, "rb")
            self.d, self.len = None, self.f.seek(0, 2)
        else:
            with open(path, "rb") as f:
                self.d = f.read()
            self.len = len(self.d)
        n = self.len
        sync = b"\x00" + b"\xff" * 10 + b"\x00"
        try:
            self.raw = n % RAW == 0 and any(self._at(k * RAW, 12) == sync for k in range(min(400, n // RAW)))
            self.size = RAW if self.raw else USER
            self.head = 16 if self.raw else 0
            self.base = 0
            self.count = n // self.size                        # whole sectors in the file (before and after sector 0)
            if ipl_sha is not None:
                for b in range(0, min(400, n // self.size - 2)):
                    p = (b + 1) * self.size + self.head + 32
                    if hashlib.sha256(self._at(p, 23)).hexdigest() == ipl_sha:
                        self.base = b
                        break
                else:
                    raise ValueError("the boot record was not found in the first 400 sectors: not this game's data track?")
        except BaseException:
            self.close()
            raise

    def _at(self, p, n):
        if self.f is None:
            return self.d[p:p + n]
        self.f.seek(p)
        return self.f.read(n)

    def close(self):
        if self.f is not None:
            self.f.close()
            self.f = None

    def sectors(self, lba, n):
        out = bytearray()
        for k in range(lba, lba + n):
            p = (self.base + k) * self.size + self.head
            s = self._at(p, USER)
            if len(s) != USER:
                raise ValueError(f"sector {k} is past the end of the track")
            out += s
        return bytes(out)


class Machine:
    # address -> name: calls that only report success (A = 0): sound and CD audio have no part in what a load leaves in memory
    NOP = {0xE003: "cd_reset", 0xE006: "cd_base", 0xE00C: "cd_seek", 0xE012: "cd_play", 0xE018: "cd_pause", 0xE01B: "cd_stat", 0xE02D: "cd_fade", 0xE030: "ad_reset", 0xE03C: "ad_play",
           0xE03F: "ad_cplay", 0xE042: "ad_stop", 0xE045: "ad_stat", 0xE0D8: "psg_bios", 0xE0E1: "psg_driver"}
    WAIT = 0xFF00
    VERSION = (3, 0)
    RAMBANK = 0x80                             # the byte the System Card holds at $FFF5: the first CD RAM bank

    def __init__(self, track, track_reads=False):
        self.disc = track
        self.cpu = Cpu(self, track=track_reads)
        self.vram = [0] * 0x8000
        self.reg = [0] * 32
        self.ar = 0
        self.vlatch = 0                        # the low byte waiting for the high one (register 2)
        self.rbuf = 0
        self.status = 0
        self.pal = [0] * 512
        self.pa = 0
        self.adpcm = bytearray(0x10000)
        self.ad_w = self.ad_r = self.ad_lat = self.ad_buf = self.ad_ctl = self.ad_dma = 0   # the ADPCM memory's ports
        self.log = []                          # (name, parameters) of the System Card calls made
        self.frames = 0
        self.called = {}                       # System Card entry address -> times called
        self.pad = 0
        self.irqmask = 0
        self.vwrites = 0
        self.vmark = bytearray(0x8000)         # VRAM words written since the caller last cleared it
        self.stubs = {0xE009: self.cd_read, 0xE033: self.ad_trans, 0xE036: self.ad_read, 0xE039: self.ad_write,
                      0xE07B: self.ex_vsync, 0xE0E4: self.ex_colorcmd, 0xE063: self.ex_joysns, 0xE05A: self.ex_getver, 0xE0B4: self.ex_binbcd, 0xE05D: self.ex_setvec, 0xE057: self.bm_files, 0xE04B: self.bm_free, 0xE04E: self.bm_none, 0xE0BD: self.ma_mul8u, 0xE0C3: self.ma_mul16u, 0xE0C9: self.ma_div16u,
                      0xE07E: lambda: self._cr(4, 0), 0xE081: lambda: self._cr(0, 4), 0xE084: lambda: self._cr(8, 0),
                      0xE087: lambda: self._cr(0, 8), 0xE08A: lambda: self._shadow(0x80, 0), 0xE08D: lambda: self._shadow(0, 0x80),
                      0xE090: lambda: self._shadow(0x40, 0), 0xE093: lambda: self._shadow(0, 0x40),
                      0xE096: lambda: self._shadow(0xC0, 0), 0xE099: lambda: self._shadow(0, 0xC0),
                      0xE069: self.ex_scrsiz, 0xE06C: self.ex_dotmod, 0xE06F: self.ex_scrmod, 0xE072: self.ex_imode,
                      0xE075: self.ex_vmode, 0xE078: self.ex_hmode, 0xE09C: self.ex_dmamod, 0xE0A2: self.ex_satclr, 0xE0A5: self.ex_sprput, 0xE09F: self.ex_sprdma, 0xE0A8: lambda: self._setreg(6, None),
                      0xE0AB: lambda: self._setreg(1, 2), 0xE0AE: lambda: self._setreg(0, 2)}
        self.hooks = {}                        # trap address -> function (the interrupt's return)
        self.in_irq = False
        rom = self.cpu.bank(0, writable=False)
        rom[0x1FF5] = self.RAMBANK
        # our own wait on the frame count at WAIT: load the counter, compare it until the interrupt moves it, return
        rom[self.WAIT & 0x1FFF:(self.WAIT & 0x1FFF) + len(WAIT_SHAPE)] = WAIT_SHAPE

    def handover(self):
        """the state the System Card hands a CD program (documented defaults, version 3): stack empty, interrupts as left by the
        card, the vertical interrupt on (control shadow $20F3 = $88), every vector at a return-from-interrupt, the sprite table
        at VRAM $1000, pads enabled, the 32 x 30 screen; our own RTI stands where the vectors point"""
        c = self.cpu
        c.put(s=0xFF, p=0x81, a=0, x=0xFF, y=0xFF)
        rti = 0xE8E2
        c.bank(0)[rti & 0x1FFF] = 0x40
        c.M[rti] = 0x40
        for a in range(0x2200, 0x220C, 2):
            c.M[a], c.M[a + 1] = rti & 255, rti >> 8
        self._scrmod(0, 32, 30)
        for a, v in ((0x20E7, 0x80), (0x20F3, 0x88), (0x20F4, 0), (0x20F6, 0x20), (0x20F7, 2), (0x2215, 0x10), (0x2227, 0x1F),
                     (0x2285, 0xE0)):
            c.M[a] = v
        self.reg[5] = 0x88
        self.reg[19] = 0x1000
        self.ar = 2

    # ---- I/O page
    def ior(self, a):
        if a < 0x400:
            r = a & 3
            if r == 0:
                v = self.status
                self.status = 0
                return v
            if r == 2:
                return self.rbuf & 255
            if r == 3:
                v = self.rbuf >> 8
                if self.ar == 2:
                    self.reg[1] = self.reg[1] + self.inc() & 0xFFFF
                    self.rbuf = self.vram[self.reg[1]] if self.reg[1] < 0x8000 else 0
                return v
            return 0
        if a < 0x800:
            r = a & 7
            if r == 4:
                return self.pal[self.pa] & 255
            if r == 5:
                v = self.pal[self.pa] >> 8 | 0xFE
                self.pa = self.pa + 1 & 511
                return v
            return 0xFF
        if 0x1400 <= a < 0x1800:
            return self.irqmask if a & 3 == 2 else 0
        if 0x1800 <= a < 0x1C00:
            r = a & 15
            if r == 0x0A:                       # the ADPCM memory's data port: the byte read ahead, then the next one
                v = self.ad_buf
                self.ad_buf = self.adpcm[self.ad_r]
                self.ad_r = self.ad_r + 1 & 0xFFFF
                return v
            if r == 0x0D:
                return self.ad_ctl
            if r == 0x0B:
                return self.ad_dma
            return 0                            # $180C: never busy, not playing; the CD's own ports: idle
        return 0

    def inc(self):
        return (1, 32, 64, 128)[self.reg[5] >> 11 & 3]

    def iow(self, a, v):
        if a < 0x400:
            r = a & 3
            if r == 0:
                self.ar = v & 31
            elif r == 2:
                n = self.ar
                if n == 2:
                    self.vlatch = v
                else:
                    self.reg[n] = self.reg[n] & 0xFF00 | v
            elif r == 3:
                n = self.ar
                if n == 2:
                    w = self.reg[0]
                    if w < 0x8000:
                        self.vram[w] = v << 8 | self.vlatch
                        self.vwrites += 1
                        self.vmark[w] = 1
                    self.reg[0] = w + self.inc() & 0xFFFF
                else:
                    self.reg[n] = self.reg[n] & 0xFF | v << 8
                    if n == 1:
                        self.rbuf = self.vram[self.reg[1]] if self.reg[1] < 0x8000 else 0
                    elif n == 0x12:
                        self.vdma()
        elif a < 0x800:
            r = a & 7
            if r == 2:
                self.pa = self.pa & 0x100 | v
            elif r == 3:
                self.pa = self.pa & 0xFF | (v & 1) << 8
            elif r == 4:
                self.pal[self.pa] = self.pal[self.pa] & 0x100 | v
            elif r == 5:
                self.pal[self.pa] = self.pal[self.pa] & 0xFF | (v & 1) << 8
                self.pa = self.pa + 1 & 511
        elif 0x1400 <= a < 0x1800:
            if a & 3 == 2:
                self.irqmask = v & 7
        elif 0x1800 <= a < 0x1C00:
            r = a & 15
            if r == 8:
                self.ad_lat = self.ad_lat & 0xFF00 | v
            elif r == 9:
                self.ad_lat = self.ad_lat & 0xFF | v << 8
            elif r == 0x0A:
                self.adpcm[self.ad_w] = v
                self.ad_w = self.ad_w + 1 & 0xFFFF
            elif r == 0x0B:
                self.ad_dma = v
            elif r == 0x0D:                     # the address control: bit 1 rising sets the write address (bit 0 clear: one less),
                o = self.ad_ctl                 # bit 3 rising the read address (bit 2 clear: one less), bit 7 resets
                if v & 2 and not o & 2:
                    self.ad_w = self.ad_lat - (0 if v & 1 else 1) & 0xFFFF
                if v & 8 and not o & 8:
                    self.ad_r = self.ad_lat - (0 if v & 4 else 1) & 0xFFFF
                self.ad_ctl = v
                if v & 0x80:
                    self.ad_r = self.ad_w = self.ad_lat = 0

    def vdma(self):
        """the VRAM-to-VRAM copy (registers $10 source, $11 destination, $12 length; $0F bits 2 / 3: downwards)"""
        s, d, n = self.reg[0x10], self.reg[0x11], self.reg[0x12]
        si = -1 if self.reg[0x0F] & 4 else 1
        di = -1 if self.reg[0x0F] & 8 else 1
        for _ in range(n + 1):
            if d < 0x8000:
                self.vram[d] = self.vram[s] if s < 0x8000 else 0
                self.vmark[d] = 1
            s = s + si & 0xFFFF
            d = d + di & 0xFFFF
        self.reg[0x10], self.reg[0x11], self.reg[0x12] = s, d, 0xFFFF

    # ---- System Card calls
    def zp(self, a):
        return self.cpu.M[0x2000 | a]

    def zp16(self, a):
        return self.cpu.M[0x2000 | a] | self.cpu.M[0x2001 | a] << 8

    def ret(self, a=None):
        """return from a call: the address on the stack, A = the result (None: as it is)"""
        c = self.cpu
        r = c.get()
        s = r["s"]
        lo = c.M[0x2100 | (s + 1 & 255)]
        hi = c.M[0x2100 | (s + 2 & 255)]
        c.put(s=s + 2 & 255)
        if a is not None:
            c.put(a=a)
        return (lo | hi << 8) + 1 & 0xFFFF

    def trap(self, pc):
        if pc < 0xFF00:
            self.called[pc] = self.called.get(pc, 0) + 1
        f = self.stubs.get(pc)
        if f:
            return f()
        h = self.hooks.get(pc)
        if h:
            return h()
        if pc in self.NOP:
            self.log.append((self.NOP[pc],))
            return self.ret(0)
        c = self.cpu
        r = c.get()
        s = r["s"]
        ra = (c.M[0x2100 | (s + 1 & 255)] | c.M[0x2100 | (s + 2 & 255)] << 8) + 1 & 0xFFFF
        raise RuntimeError(f"System Card address ${pc:04X} is not modelled (from ${ra:04X}, A {r['a']:02X} X {r['x']:02X} Y {r['y']:02X}, "
                           f"$F8-$FF {bytes(c.M[0x20F8:0x2100]).hex(' ')}, pages {bytes(c.mpr).hex()})")

    def store(self, data, typ, bx):
        """bytes into memory the way cd_read / ad_read address it: typ 0 / 1 a local address, 2-6 a page with the bank in _BL
        (the banks follow on), $FE / $FF VRAM"""
        c = self.cpu
        if typ in (0xFE, 0xFF):  # own: System Card cd_read VRAM destination type codes
            a = bx
            for k in range(0, len(data) - 1, 2):
                if a < 0x8000:
                    self.vram[a] = data[k] | data[k + 1] << 8
                    self.vmark[a] = 1
                a = a + 1 & 0xFFFF
            return
        if typ in (0, 1):
            ea = bx
            for k in range(0, len(data), 0x2000):          # page by page, through the mapping
                chunk = data[k:k + 0x2000]
                while chunk:
                    n = min(len(chunk), 0x2000 - (ea & 0x1FFF))
                    if ea < 0x2000:
                        raise RuntimeError("a read into the I/O page")
                    c.M[ea:ea + n] = chunk[:n]
                    if c.track:
                        c.W[ea:ea + n] = b"\x01" * n
                    ea = ea + n & 0xFFFF
                    chunk = chunk[n:]
            return
        if 2 <= typ <= 6:
            bank = bx & 255
            c.sync()
            for k in range(0, len(data), 0x2000):
                chunk = data[k:k + 0x2000]
                b = c.bank(bank)
                b[:len(chunk)] = chunk
                for p in range(1, 8):
                    if c.mpr[p] == bank:
                        c.M[p << 13:(p << 13) + len(chunk)] = chunk
                if c.track:
                    c.mark(bank, 0, len(chunk))
                bank += 1
            return
        raise RuntimeError(f"address type ${typ:02X} is not modelled")

    def cd_read(self):
        al, ah, bx = self.zp(0xF8), self.zp(0xF9), self.zp16(0xFA)
        lba = self.zp(0xFC) << 16 | self.zp(0xFD) << 8 | self.zp(0xFE)
        typ = self.zp(0xFF)
        if typ in (0, 0xFE):                    # a length in bytes
            n = al | ah << 8
            data = self.disc.sectors(lba, (n + USER - 1) // USER)[:n]
        else:
            data = self.disc.sectors(lba, al)
        self.log.append(("cd_read", lba, len(data), typ, bx, bytes(self.cpu.mpr).hex()))
        self.store(data, typ, bx)
        return self.ret(0)

    def ad_trans(self):
        """sectors into the ADPCM memory: _AL sectors from record _CL _CH _DL; _DH 0: from address _BX, else where the last
        write ended (through the ports, as the System Card does it)"""
        lba = self.zp(0xFC) << 16 | self.zp(0xFD) << 8 | self.zp(0xFE)
        n = self.zp(0xF8)
        if self.zp(0xFF) == 0:
            bx = self.zp16(0xFA)
            self.iow(0x1808, bx & 255)
            self.iow(0x1809, bx >> 8)
            self.iow(0x180D, self.ad_ctl | 3)
            self.iow(0x180D, self.ad_ctl & ~1)
            self.iow(0x180D, self.ad_ctl & ~2)
        self.log.append(("ad_trans", lba, n, self.ad_w))
        for b in self.disc.sectors(lba, n):
            self.adpcm[self.ad_w] = b
            self.ad_w = self.ad_w + 1 & 0xFFFF
        return self.ret(0)

    def ad_read(self):
        """ADPCM memory from address _CX, _AX bytes, to a local address _BX (_DH 0) or to VRAM address _BX (_DH $FF), through
        the ports; the parameters are left as the System Card leaves them"""
        c = self.cpu
        M = c.M
        n, bx, cx, typ = self.zp16(0xF8), self.zp16(0xFA), self.zp16(0xFC), self.zp(0xFF)
        self.log.append(("ad_read", cx, n, typ, bx))
        self.iow(0x1808, cx & 255)
        self.iow(0x1809, cx >> 8)
        self.iow(0x180D, self.ad_ctl | 8)
        self.ior(0x180A)
        self.iow(0x180D, self.ad_ctl & ~8)
        self.ior(0x180A)
        if n == 0:
            n = 0x10000
        if typ == 0:
            for k in range(n):
                ea = bx + k & 0xFFFF
                v = self.ior(0x180A)
                if ea < 0x2000:
                    self.iow(ea, v)
                else:
                    M[ea] = v
                    if c.track:
                        c.W[ea] = 1
            bx = bx + n & 0xFFFF
            M[0x20FA], M[0x20FB] = bx & 255, bx >> 8
        elif typ == 0xFF:
            M[0x20F7] = 2
            self.iow(0, 0)
            self.iow(2, bx & 255)
            self.iow(3, bx >> 8)
            self.iow(0, 2)
            for k in range(n):
                self.iow(2 + (k & 1), self.ior(0x180A))
            M[0x20FA], M[0x20FB] = 2 + (n & 1), 0
            M[0x2272] = 0
        else:
            raise RuntimeError(f"ad_read to address type ${typ:02X} is not modelled")
        M[0x20F8] = M[0x20F9] = 0
        return self.ret(0)

    def ad_write(self):
        raise RuntimeError("ad_write is not modelled")

    def _colorcmd(self):
        """ex_colorcmd: command $221F (0 none; even: memory to the colour table, odd: the colour table to memory), background
        colours at ($2220) for $2222 palettes from entry 0, sprite colours at ($2223) for $2225 palettes from entry $100; the
        command cleared. The System Card's work bytes $2286-$228D are left as it leaves them."""
        M = self.cpu.M
        cmd = M[0x221F]
        if not cmd:
            return
        rd = cmd & 1
        M[0x2286] = 0xF3 if rd else 0xE3
        if rd:
            M[0x2287] = M[0x2288] = 4
        else:
            M[0x2289] = M[0x228A] = 4
        M[0x228D] = 0x60
        for ptr, ln, hi in ((0x2220, 0x2222, 0), (0x2223, 0x2225, 1)):
            n = M[ln]
            if not n:
                continue
            n = (n & 0x1F) << 5
            M[0x228B], M[0x228C] = n & 255, n >> 8
            a = M[ptr] | M[ptr + 1] << 8
            q = 0x2289 if rd else 0x2287
            M[q], M[q + 1] = a & 255, a >> 8
            self.iow(0x402, 0)
            self.iow(0x403, hi)
            if n == 0:
                n = 0x10000
            for k in range(n):
                if rd:
                    M[a + k & 0xFFFF] = self.ior(0x404 + (k & 1))
                    if self.cpu.track:
                        self.cpu.W[a + k & 0xFFFF] = 1
                else:
                    self.iow(0x404 + (k & 1), self.cpu._rdt(a + k & 0xFFFF) if self.cpu.track else M[a + k & 0xFFFF])
        M[0x221F] = 0

    def ex_colorcmd(self):
        self._colorcmd()
        return self.ret(0)

    def _joysns(self):
        """ex_joysns: the pads' last state kept at $2232, the state at $2228, the new presses at $222D; pad 1 holds self.pad
        (I 1, II 2, SELECT 4, RUN 8, up $10, right $20, down $40, left $80), the others nothing"""
        M = self.cpu.M
        for y in range(5):
            v = self.pad if y == 0 else 0
            o = M[0x2228 + y]
            M[0x2232 + y] = o
            M[0x2228 + y] = v
            M[0x222D + y] = (v ^ o) & v

    def ex_joysns(self):
        self._joysns()
        self.cpu.put(y=5)
        return self.ret(0)

    def ex_getver(self):
        """the System Card's version: 3.00 (the Super System Card; the Arcade Card reports the same)"""
        self.cpu.put(x=self.VERSION[0], y=self.VERSION[1])
        return self.ret()

    def ex_binbcd(self):
        """A (under 100) to two decimal digits; the ones are left in $20EC"""
        c = self.cpu
        r = c.get()
        a = r["a"]
        if a >= 100:
            c.put(p=r["p"] | 1)
            return self.ret()
        c.M[0x20EC] = a % 10
        c.put(p=r["p"] & ~1)
        return self.ret(a // 10 << 4 | a % 10)

    def ma_mul8u(self):
        """_CX = _AL x _BL (unsigned); A the low byte, X the high one, Y 0; the page 6 bank noted at $22BB as the card does"""
        c = self.cpu
        M = c.M
        v = M[0x20F8] * M[0x20FA]
        M[0x20FC], M[0x20FD] = v & 255, v >> 8
        M[0x22BB] = c.mpr[6] & 255
        c.put(x=v >> 8, y=0)
        return self.ret(v & 255)

    def ex_setvec(self):
        """vector A (0-5: $2200 + 2 A; 6: the reset vector $2284) <- X (low), Y (high)"""
        c = self.cpu
        r = c.get()
        if r["a"] == 6:
            c.M[0x2284], c.M[0x2285] = r["x"], r["y"]
        else:
            q = 0x2200 + 2 * r["a"]
            c.M[q], c.M[q + 1] = r["x"], r["y"]
            c.put(x=2 * r["a"] + 1 & 255)
        return self.ret()

    def bm_none(self):
        """the backup memory holds no file of this game (bm_files, bm_read: A = 1, not found)"""
        self.log.append(("bm_none",))
        return self.ret(1)

    def bm_files(self):
        """no file: the count asked for in _AL is 0, A = 1"""
        self.cpu.M[0x20F8] = 0
        return self.bm_none()

    def bm_free(self):
        """the free bytes of an empty, formatted backup memory in _CX"""
        self.cpu.M[0x20FC], self.cpu.M[0x20FD] = 0xDE, 0x07  # own: empty formatted 2 KB BRAM free-byte count ($07DE)
        self.log.append(("bm_free",))
        return self.ret(0)

    def ma_div16u(self):
        """_CX = _AX / _BX, _DX the remainder (unsigned; a zero divisor: _CX = 0), step by step as the documented restoring
        division leaves A, X and the scratch $20EC / $20ED"""
        c = self.cpu
        M = c.M
        M[0x22BB] = c.mpr[6] & 255
        bx = M[0x20FA] | M[0x20FB] << 8
        if bx == 0:
            M[0x20FC] = M[0x20FD] = 0
            return self.ret(0)
        M[0x20EC], M[0x20ED] = bx & 255, bx >> 8
        ax = M[0x20F8] | M[0x20F9] << 8
        q = ax << 1 & 0xFFFF
        cy = ax >> 15
        rem = 0
        a = q >> 8
        for _ in range(16):
            rem = (rem << 1 | cy) & 0xFFFF
            a = rem >> 8
            if rem >> 8 == bx >> 8:
                a = rem & 255
            if rem >= bx:
                rem -= bx
                a = rem >> 8
                cy = 1
            else:
                cy = 0
            q = q << 1 | cy
            cy = q >> 16
            q &= 0xFFFF
        M[0x20FC], M[0x20FD], M[0x20FE], M[0x20FF] = q & 255, q >> 8, rem & 255, rem >> 8
        c.put(x=0)
        return self.ret(a)

    def ma_mul16u(self):
        """_DX:_CX = _AX x _BX (unsigned, 32 bits); the scratch $20EC / $20ED as the documented shift-and-add leaves it"""
        c = self.cpu
        M = c.M
        M[0x22BB] = c.mpr[6] & 255
        ax = M[0x20F8] | M[0x20F9] << 8
        bx = M[0x20FA] | M[0x20FB] << 8
        m = ax
        hi = lo = 0
        cy = 0
        a = ax >> 8
        for _ in range(16):
            m |= cy << 16
            cy = m & 1
            m >>= 1
            if cy:
                hi += bx
                a = hi >> 8 & 255
            v = hi << 16 | lo
            cy2 = v & 1
            v >>= 1
            hi, lo = v >> 16, v & 0xFFFF
            cy = cy2
        M[0x20EC], M[0x20ED] = m & 255, m >> 8 & 255
        M[0x20FC], M[0x20FD], M[0x20FE], M[0x20FF] = lo & 255, lo >> 8, hi & 255, hi >> 8 & 255
        c.put(x=0)
        return self.ret(a)

    # the display helpers: the control shadow $20F3 and the register select's shadow $20F7, as documented
    def _sel(self, n):
        self.cpu.M[0x20F7] = n
        self.iow(0, n)

    def _cr(self, on, off):
        M = self.cpu.M
        M[0x20F3] = (M[0x20F3] | on) & ~off & 255
        self._sel(5)
        self.iow(2, M[0x20F3])
        return self.ret(M[0x20F3])

    def _shadow(self, on, off):
        M = self.cpu.M
        M[0x20F3] = (M[0x20F3] | on) & ~off & 255
        return self.ret()

    def ex_vsync(self):
        """wait for the next vertical interrupt: interrupts on (the vertical one enabled), then our own three-instruction wait
        on the frame count, placed in the page the System Card would be in"""
        c = self.cpu
        M = c.M
        if M[0x20F5] & 2:
            return self.ret()
        c.put(p=c.get()["p"] & ~4)
        if not M[0x20F3] & 8:
            M[0x20F3] |= 8
            self._sel(5)
            self.iow(2, M[0x20F3])
        return self.WAIT

    def _mwr(self, keep, bits):
        """the memory width shadow $2242 into register 9 (ex_scrsiz: the map size bits; ex_dotmod: the dot bits)"""
        M = self.cpu.M
        M[0x2242] = M[0x2242] & keep | bits
        self._sel(9)
        self.iow(2, M[0x2242])
        return M[0x2242]

    def ex_scrsiz(self):
        return self.ret(self._mwr(0x8F, (self.cpu.get()["a"] & 7) << 4))

    def ex_dotmod(self):
        return self.ret(self._mwr(0x70, self.cpu.get()["a"] & 0x8F))

    def ex_scrmod(self):
        """the display timing registers ($0A-$0E) and the dot clock for a screen of X by Y characters, clock A (documented
        formulas; a size out of range gives 32 x 30 and the carry). They place the picture; no memory depends on them."""
        r = self.cpu.get()
        err = self._scrmod(r["a"] & 5, r["x"], r["y"])
        p = self.cpu.get()["p"]
        self.cpu.put(p=p | 1 if err else p & ~1)
        return self.ret(1 if err else self.cpu.M[0x2242])

    def _scrmod(self, a, w, h):
        err = False
        if not 10 <= h < 31 or (not 10 <= w < 35 if not a & 1 else not 16 <= w < 45):
            a, w, h, err = 0, 32, 30, True
        M = self.cpu.M
        M[0x2244], M[0x2245], M[0x2246] = a, w, h
        t = h * 8 & 255
        self._sel(0x0C)
        self.iow(2, 2)
        self.iow(3, (~(t >> 1) & 255) + 0x88 & 255)
        self._sel(0x0D)
        self.iow(2, t - 1 & 255)
        self.iow(3, 0)
        self._sel(0x0E)
        u = (t - 1 & 255) + 2 & 255
        self.iow(2, (u >> 1) + 0x7D + (u & 1) & 255)
        self.iow(3, 0)
        self.iow(0x400, a ^ 4)
        self._sel(0x0A)
        self.iow(2, 3 if a & 1 else 2)
        v = (~(w >> 1) & 255) + (0x19 if a & 1 else 0x13) & 255
        self.iow(3, v)
        y = ~(v + w) & 255
        self._sel(0x0B)
        self.iow(2, w - 1 & 255)
        self.iow(3, y + (0x35 if a & 1 else 0x27) & 255)
        self._mwr(0x70, 0x0A if a & 1 else 0)  # own: System Card zero-page scratch ($2070) mock status
        return err

    def _crhi(self):
        M = self.cpu.M
        self._sel(5)
        self.iow(3, M[0x20F4])
        return self.ret(M[0x20F4])

    def ex_imode(self):
        """the VRAM address increment (A: 0 +1, 1 +32, 2 +64, 3 +128) into the control shadow $20F4 and register 5"""
        M = self.cpu.M
        M[0x20F4] = M[0x20F4] & ~0x18 & 255 | self.cpu.get()["a"] << 3 & 0x18
        return self._crhi()

    def ex_vmode(self):
        M = self.cpu.M
        M[0x20F4] |= 8
        if M[0x2242] & 0x30:
            M[0x20F4] = (M[0x20F4] | 0x10) & ~8 & 255
        else:
            M[0x20F4] &= ~0x10 & 255
        return self._crhi()

    def ex_hmode(self):
        self.cpu.M[0x20F4] &= ~0x18 & 255
        return self._crhi()

    def ex_satclr(self):
        """256 zero words at the sprite table's VRAM address ($2214), the sprite count $2216 zero"""
        M = self.cpu.M
        self._sel(0)
        self.iow(2, M[0x2214])
        self.iow(3, M[0x2215])
        self._sel(2)
        for _ in range(256):
            self.iow(2, 0)
            self.iow(3, 0)
        M[0x2216] = 0
        self.cpu.put(x=0)
        return self.ret(2)

    def ex_sprput(self):
        """the sprite entry at $2217 (4 words) into the table's next place (64 at most), the count $2216 up"""
        M = self.cpu.M
        n = M[0x2216]
        if n >= 0x40:
            return self.ret(n)
        a = (M[0x2214] | M[0x2215] << 8) + 4 * n & 0xFFFF
        self._sel(0)
        self.iow(2, a & 255)
        self.iow(3, a >> 8)
        self._sel(2)
        for y in range(0, 8, 2):
            self.iow(2, M[0x2217 + y])
            self.iow(3, M[0x2218 + y])
        M[0x2216] = n + 1
        return self.ret(M[0x221E])

    def ex_dmamod(self):
        a = self.cpu.get()["a"] & 0x1F
        self.cpu.M[0x2243] = a
        self._sel(0x0F)
        self.iow(2, a)
        return self.ret(a)

    def ex_sprdma(self):
        M = self.cpu.M
        self._sel(0x13)
        self.iow(2, M[0x2214])
        self.iow(3, M[0x2215])
        return self.ret(M[0x2215])

    def _setreg(self, n, then):
        r = self.cpu.get()
        self._sel(n)
        self.iow(2, r["a"])
        self.iow(3, r["x"])
        if then is not None:
            self._sel(then)
            return self.ret(then)
        return self.ret()

    # ---- the video interrupts, as the System Card's handler behaves (mode byte $20F5: bit 1 the game's own handler at ($2202).
    # At the vertical blank (status $20): the control shadow $20F3 / $20F4 into register 5, the frame count $2241; with bit 5 clear
    # the scroll shadows, the colour command, the random seed's count, the pad (read as no button; the sound driver has no part);
    # with bit 4 the game's hook at ($2208). At the raster line (status $04): with bit 7 clear the second scroll shadows; with bit 6
    # the game's hook at ($220A). Then the register select back from its shadow $20F7.) Returns False while interrupts are off.
    HOOKRET = 0xFFF0

    def irq1(self, st):
        c = self.cpu
        M = c.M
        r = c.get()
        if r["i"] or self.in_irq:
            return False
        if st & 0x20:
            self.frames += 1
        if self.irqmask & 2 or not self.reg[5] & (8 if st & 0x20 else 4):
            self.status |= st if self.reg[5] & (8 if st & 0x20 else 4) else 0
            return True
        if M[0x20F5] & 2:
            self.status |= st
            self._enter(M[0x2202] | M[0x2203] << 8)
            return True
        self._enter(None)
        s = c.get()["s"]
        for v in (r["a"], r["x"], r["y"]):
            M[0x2100 | s] = v
            s = s - 1 & 255
        c.put(s=s)
        M[0x20F6] = st
        self.steps = []
        if st & 0x20:
            self.reg[5] = M[0x20F3] | M[0x20F4] << 8
            M[0x2241] = M[0x2241] + 1 & 255
            if not M[0x20F5] & 0x20:
                self.reg[7] = M[0x220C] | M[0x220D] << 8
                self.reg[8] = M[0x2210] | M[0x2211] << 8
                self._colorcmd()
                M[0x2249] = M[0x2249] + 1 & 255
                self._joysns()
            if M[0x20F5] & 0x10:
                self.steps.append(0x2208)
        if st & 4:
            if not M[0x20F5] & 0x80:
                self.steps.append(-1)
            if M[0x20F5] & 0x40:
                self.steps.append(0x220A)
        self.in_irq = True
        self.hooks[self.HOOKRET] = self._step
        c.put(pc=self._step())
        return True

    def _step(self):
        """the handler's next part: a hook of the game's (called as a subroutine), then the end"""
        c = self.cpu
        M = c.M
        while self.steps:
            v = self.steps.pop(0)
            if v < 0:
                self.reg[7] = M[0x220E] | M[0x220F] << 8
                self.reg[8] = M[0x2212] | M[0x2213] << 8
                continue
            s = c.get()["s"]
            t = self.HOOKRET - 1
            M[0x2100 | s] = t >> 8
            s = s - 1 & 255
            M[0x2100 | s] = t & 255
            c.put(s=s - 1 & 255)
            return M[v] | M[v + 1] << 8
        return self._leave()

    def frame(self, k):
        """one frame of about k instructions in 263 lines: a raster interrupt at the line the compare register (6) asks for (the
        handler may move it on: several a frame), the vertical one at line 240"""
        c = self.cpu
        per = max(1, k // 263)
        for line in range(263):
            c.run(per)
            if self.reg[5] & 4 and self.reg[6] - 64 == line:
                st = 4
            elif line == 240:
                st = 0x20
            else:
                continue
            m = 0
            while not self.irq1(st):
                c.run(50)
                m += 1
                if m > 200000:
                    raise RuntimeError("interrupts stay off")

    def _enter(self, pc):
        """the interrupt's entry: the return address and the flags on the stack, interrupts off"""
        c = self.cpu
        M = c.M
        r = c.get()
        s = r["s"]
        for v in (r["pc"] >> 8, r["pc"] & 255, r["p"] & 0xEF):
            M[0x2100 | s] = v
            s = s - 1 & 255
        c.put(s=s, p=(r["p"] | 4) & 0xF7)
        if pc is not None:
            c.put(pc=pc)

    def _leave(self):
        """the handler's end: the register select back from its shadow, Y X A and the flags off the stack"""
        c = self.cpu
        M = c.M
        self.in_irq = False
        self.ar = M[0x20F7] & 31
        s = c.get()["s"]
        v = []
        for _ in range(6):
            s = s + 1 & 255
            v.append(M[0x2100 | s])
        c.put(y=v[0], x=v[1], a=v[2], p=v[3], s=s)
        return v[4] | v[5] << 8
