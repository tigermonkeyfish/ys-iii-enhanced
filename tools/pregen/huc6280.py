"""huc6280.py: a small HuC6280 interpreter (our own code, pure Python, standard library only) for the patch-time tools.

It runs routines of the player's own disc on the player's PC (tools/pregen/extract17.py); it holds nothing of the game. Scope: every
official instruction but SET (the T flag) is implemented; timing is counted in instructions, not cycles (the callers need the
memory a routine leaves, not when). Memory: 8 KB banks behind the eight mapping registers, kept as one flat 64 KB view that is
swapped with the bank store on TAM (a writable bank mapped at two pages at once is kept equal on a slower path). Page 0 is the I/O page
(the machine object's ior / iow), page 1 the work RAM bank $F8 (zero page $2000, stack $2100).

    cpu = Cpu(machine)          machine.ior(addr) / machine.iow(addr, value) for $0000-$1FFF, machine.trap(pc) for a jump to a trapped
                                address (any address >= cpu.trap_lo): it returns the new pc
    cpu.bank(n)                 the bank's bytearray (created empty, read only, if it does not exist)
    cpu.run(n)                  n instructions
    cpu.setbp(addr, fn, op)     fn() is called before the instruction at addr runs (op: its opcode; default the byte there now;
                                fn may raise to stop the run); returns the arguments for cpu.clrbp
A tracking build (Cpu(machine, track=True)) records every byte read before it was written (cpu.pre: bank << 13 | offset -> 1 a
data read, 2 an instruction byte): what a routine takes from the state it was started in.
"""

_TAB = """
0:BRK,ORA izx,SXY,ST0 imm,TSB zp,ORA zp,ASL zp,RMB0 zp,PHP,ORA imm,ASL,,TSB abs,ORA abs,ASL abs,BBR0 zr
1:BPL rel,ORA izy,ORA izp,ST1 imm,TRB zp,ORA zpx,ASL zpx,RMB1 zp,CLC,ORA aby,INC,,TRB abs,ORA abx,ASL abx,BBR1 zr
2:JSR abs,AND izx,SAX,ST2 imm,BIT zp,AND zp,ROL zp,RMB2 zp,PLP,AND imm,ROL,,BIT abs,AND abs,ROL abs,BBR2 zr
3:BMI rel,AND izy,AND izp,,BIT zpx,AND zpx,ROL zpx,RMB3 zp,SEC,AND aby,DEC,,BIT abx,AND abx,ROL abx,BBR3 zr
4:RTI,EOR izx,SAY,TMA imm,BSR rel,EOR zp,LSR zp,RMB4 zp,PHA,EOR imm,LSR,,JMP abs,EOR abs,LSR abs,BBR4 zr
5:BVC rel,EOR izy,EOR izp,TAM imm,CSL,EOR zpx,LSR zpx,RMB5 zp,CLI,EOR aby,PHY,,,EOR abx,LSR abx,BBR5 zr
6:RTS,ADC izx,CLA,,STZ zp,ADC zp,ROR zp,RMB6 zp,PLA,ADC imm,ROR,,JMP ind,ADC abs,ROR abs,BBR6 zr
7:BVS rel,ADC izy,ADC izp,TII blk,STZ zpx,ADC zpx,ROR zpx,RMB7 zp,SEI,ADC aby,PLY,,JMP iax,ADC abx,ROR abx,BBR7 zr
8:BRA rel,STA izx,CLX,TST immz,STY zp,STA zp,STX zp,SMB0 zp,DEY,BIT imm,TXA,,STY abs,STA abs,STX abs,BBS0 zr
9:BCC rel,STA izy,STA izp,TST immab,STY zpx,STA zpx,STX zpy,SMB1 zp,TYA,STA aby,TXS,,STZ abs,STA abx,STZ abx,BBS1 zr
A:LDY imm,LDA izx,LDX imm,TST immzx,LDY zp,LDA zp,LDX zp,SMB2 zp,TAY,LDA imm,TAX,,LDY abs,LDA abs,LDX abs,BBS2 zr
B:BCS rel,LDA izy,LDA izp,TST immabx,LDY zpx,LDA zpx,LDX zpy,SMB3 zp,CLV,LDA aby,TSX,,LDY abx,LDA abx,LDX aby,BBS3 zr
C:CPY imm,CMP izx,CLY,TDD blk,CPY zp,CMP zp,DEC zp,SMB4 zp,INY,CMP imm,DEX,,CPY abs,CMP abs,DEC abs,BBS4 zr
D:BNE rel,CMP izy,CMP izp,TIN blk,CSH,CMP zpx,DEC zpx,SMB5 zp,CLD,CMP aby,PHX,,,CMP abx,DEC abx,BBS5 zr
E:CPX imm,SBC izx,,TIA blk,CPX zp,SBC zp,INC zp,SMB6 zp,INX,SBC imm,NOP,,CPX abs,SBC abs,INC abs,BBS6 zr
F:BEQ rel,SBC izy,SBC izp,TAI blk,SET,SBC zpx,INC zpx,SMB7 zp,SED,SBC aby,PLX,,,SBC abx,INC abx,BBS7 zr
"""
OPS = {}
for _l in _TAB.strip().splitlines():
    _h, _r = _l.split(":")
    for _i, _e in enumerate(_r.split(",")):
        _m = _e.split()
        if _m:
            OPS[int(_h, 16) * 16 + _i] = (_m[0], _m[1] if len(_m) > 1 else "")
SIZE = {"": 1, "imm": 2, "zp": 2, "zpx": 2, "zpy": 2, "izx": 2, "izy": 2, "izp": 2, "rel": 2, "abs": 3, "abx": 3, "aby": 3, "ind": 3,
        "iax": 3, "zr": 3, "immz": 3, "immzx": 3, "immab": 4, "immabx": 4, "blk": 7}

# effective address of a mode (statements that leave it in ea); zero-page modes never reach the I/O page
EA = {
    "zp": "ea = 0x2000 | M[pc + 1]",
    "zpx": "ea = 0x2000 | (M[pc + 1] + x & 255)",
    "zpy": "ea = 0x2000 | (M[pc + 1] + y & 255)",
    "abs": "ea = M[pc + 1] | M[pc + 2] << 8",
    "abx": "ea = (M[pc + 1] | M[pc + 2] << 8) + x & 0xFFFF",
    "aby": "ea = (M[pc + 1] | M[pc + 2] << 8) + y & 0xFFFF",
    "izx": "ea = M[pc + 1] + x & 255; ea = M[0x2000 | ea] | M[0x2000 | (ea + 1 & 255)] << 8",
    "izy": "ea = M[pc + 1]; ea = (M[0x2000 | ea] | M[0x2000 | (ea + 1 & 255)] << 8) + y & 0xFFFF",
    "izp": "ea = M[pc + 1]; ea = M[0x2000 | ea] | M[0x2000 | (ea + 1 & 255)] << 8",
}
ZPM = ("zp", "zpx", "zpy")


def _gen(track):
    """the source of the factory: one closure per opcode over the registers"""
    def rd(md, var="v"):
        if md == "imm":
            return [f"{var} = M[pc + 1]"]
        if track:
            return [EA[md], f"{var} = rdt(ea)"]
        if md in ZPM:
            return [EA[md], f"{var} = M[ea]"]
        return [EA[md], f"{var} = M[ea] if ea >= 0x2000 else ior(ea)"]

    def wr(md, val, have_ea=False):
        o = [] if have_ea else [EA[md]]
        if track:
            return o + [f"wrt(ea, {val})"]
        if md in ZPM:
            return o + [f"M[ea] = {val}"]
        return o + [f"if ea >= 0x2000: M[ea] = {val}", f"else: iow(ea, {val})"]

    ADC = ["if d:",
           "    t = (a & 15) + (v & 15) + c",
           "    if t > 9: t += 6",
           "    u = (a >> 4) + (v >> 4) + (t > 15)",
           "    if u > 9: u += 6",
           "    c = 1 if u > 15 else 0; a = (u << 4 | t & 15) & 255; nz = a",
           "else:",
           "    t = a + v + c; vf = 1 if ~(a ^ v) & (a ^ t) & 0x80 else 0; c = t >> 8; a = t & 255; nz = a"]
    SBC = ["if d:",
           "    t = (a & 15) - (v & 15) - (1 - c); u = (a >> 4) - (v >> 4)",
           "    if t < 0: t += 10; u -= 1",
           "    if u < 0: u += 10; c = 0",
           "    else: c = 1",
           "    a = (u << 4 | t & 15) & 255; nz = a",
           "else:",
           "    t = a - v - 1 + c; vf = 1 if (a ^ v) & (a ^ t) & 0x80 else 0; c = 0 if t < 0 else 1; a = t & 255; nz = a"]
    RMW = {"ASL": "c = v >> 7; v = v << 1 & 255; nz = v", "LSR": "c = v & 1; v >>= 1; nz = v",
           "ROL": "v = v << 1 | c; c = v >> 8; v &= 255; nz = v", "ROR": "v |= c << 8; c = v & 1; v >>= 1; nz = v",
           "INC": "v = v + 1 & 255; nz = v", "DEC": "v = v - 1 & 255; nz = v",
           "TSB": "t = v | a; nz = (t & 0x80) << 1 | (1 if v & a else 0); vf = t >> 6 & 1; v = t",
           "TRB": "t = v & ~a & 255; nz = (t & 0x80) << 1 | (1 if v & a else 0); vf = t >> 6 & 1; v = t"}
    PUSHP = "(0x80 if nz & 0x180 else 0) | vf << 6 | {b} | d << 3 | i << 2 | (0 if nz & 255 else 2) | c"
    PULLP = "nz = (t & 0x80) << 1 | (0 if t & 2 else 1); vf = t >> 6 & 1; d = t >> 3 & 1; i = t >> 2 & 1; c = t & 1"
    BR = {"BPL": "not nz & 0x180", "BMI": "nz & 0x180", "BVC": "not vf", "BVS": "vf", "BCC": "not c", "BCS": "c", "BNE": "nz & 255",
          "BEQ": "not nz & 255", "BRA": "True"}
    REL = "t = M[pc + {k}]; pc = pc + {n} + (t - 256 if t > 127 else t) & 0xFFFF"
    out = ["def make(M, ior, iow, trap, tam, tma, rdt, wrt, TL):",
           "    a = x = y = c = vf = d = 0; i = 1; nz = 1; s = 0xFF; pc = 0",
           "    ops = [None] * 256"]
    for op in range(256):
        if op not in OPS:
            continue
        mn, md = OPS[op]
        n = SIZE[md]
        b = []
        nxt = f"pc = pc + {n} & 0xFFFF"
        reg = {"A": "a", "X": "x", "Y": "y"}
        if mn in ("LDA", "LDX", "LDY"):
            r = reg[mn[2]]
            b = rd(md) + [f"{r} = v; nz = v", nxt]
        elif mn in ("STA", "STX", "STY", "STZ"):
            b = wr(md, {"STA": "a", "STX": "x", "STY": "y", "STZ": "0"}[mn]) + [nxt]
        elif mn in ("ORA", "AND", "EOR"):
            b = rd(md) + [f"a {'|' if mn == 'ORA' else '&' if mn == 'AND' else '^'}= v; nz = a", nxt]
        elif mn == "ADC":
            b = rd(md) + ADC + [nxt]
        elif mn == "SBC":
            b = rd(md) + SBC + [nxt]
        elif mn in ("CMP", "CPX", "CPY"):
            r = {"CMP": "a", "CPX": "x", "CPY": "y"}[mn]
            b = rd(md) + [f"t = {r} - v; c = 0 if t < 0 else 1; nz = t & 255", nxt]
        elif mn == "BIT":
            b = rd(md) + ["nz = (v & 0x80) << 1 | (1 if a & v else 0); vf = v >> 6 & 1", nxt]
        elif mn in RMW and md == "":
            b = ["v = a", RMW[mn], "a = v", nxt]
        elif mn in RMW:
            b = rd(md) + [RMW[mn]] + wr(md, "v", True) + [nxt]
        elif mn[:3] in ("RMB", "SMB"):
            k = int(mn[3])
            b = rd(md) + [f"v {'&= ' + str(255 ^ 1 << k) if mn[0] == 'R' else '|= ' + str(1 << k)}"] + wr(md, "v", True) + [nxt]
        elif mn[:3] in ("BBR", "BBS"):
            k = int(mn[3])
            b = rd("zp") + [f"if {'not ' if mn[2] == 'R' else ''}v & {1 << k}:", "    " + REL.format(k=2, n=3), "else: pc = pc + 3 & 0xFFFF"]
        elif mn == "TST":
            m2 = {"immz": "zp", "immzx": "zpx", "immab": "abs", "immabx": "abx"}[md]
            e = EA[m2].replace("pc + 2", "pc + 3").replace("pc + 1", "pc + 2")
            b = [e, ("v = rdt(ea)" if track else "v = M[ea] if ea >= 0x2000 else ior(ea)"),
                 "nz = (v & 0x80) << 1 | (1 if M[pc + 1] & v else 0); vf = v >> 6 & 1", nxt]
        elif mn in BR:
            b = [f"if {BR[mn]}:", "    " + REL.format(k=1, n=2), "else: pc = pc + 2 & 0xFFFF"]
        elif mn == "BSR":
            b = ["t = pc + 1 & 0xFFFF; M[0x2100 | s] = t >> 8; s = s - 1 & 255; M[0x2100 | s] = t & 255; s = s - 1 & 255",
                 REL.format(k=1, n=2)]
        elif mn == "JSR":
            b = ["t = pc + 2 & 0xFFFF; M[0x2100 | s] = t >> 8; s = s - 1 & 255; M[0x2100 | s] = t & 255; s = s - 1 & 255",
                 "pc = M[pc + 1] | M[pc + 2] << 8", "if pc >= TL: pc = trap(pc)"]
        elif mn == "JMP":
            if md == "abs":
                b = ["pc = M[pc + 1] | M[pc + 2] << 8"]
            elif md == "ind":
                b = ["t = M[pc + 1] | M[pc + 2] << 8; pc = M[t] | M[t + 1 & 0xFFFF] << 8"]
            else:
                b = ["t = (M[pc + 1] | M[pc + 2] << 8) + x & 0xFFFF; pc = M[t] | M[t + 1 & 0xFFFF] << 8"]
            b += ["if pc >= TL: pc = trap(pc)"]
        elif mn == "RTS":
            b = ["s = s + 1 & 255; t = M[0x2100 | s]; s = s + 1 & 255; pc = (t | M[0x2100 | s] << 8) + 1 & 0xFFFF",
                 "if pc >= TL: pc = trap(pc)"]
        elif mn == "RTI":
            b = ["s = s + 1 & 255; t = M[0x2100 | s]", PULLP,
                 "s = s + 1 & 255; t = M[0x2100 | s]; s = s + 1 & 255; pc = t | M[0x2100 | s] << 8", "if pc >= TL: pc = trap(pc)"]
        elif mn == "BRK":
            b = ["raise RuntimeError('BRK at %04X' % pc)"]
        elif mn == "SET":
            b = ["raise RuntimeError('SET (T flag) at %04X: not implemented' % pc)"]
        elif mn in ("PHA", "PHX", "PHY"):
            b = [f"M[0x2100 | s] = {reg[mn[2]]}; s = s - 1 & 255", nxt]
        elif mn in ("PLA", "PLX", "PLY"):
            r = reg[mn[2]]
            b = [f"s = s + 1 & 255; {r} = M[0x2100 | s]; nz = {r}", nxt]
        elif mn == "PHP":
            b = ["M[0x2100 | s] = " + PUSHP.format(b="0x10") + "; s = s - 1 & 255", nxt]
        elif mn == "PLP":
            b = ["s = s + 1 & 255; t = M[0x2100 | s]", PULLP, nxt]
        elif mn in ("CLC", "SEC", "CLI", "SEI", "CLD", "SED", "CLV"):
            b = [{"CLC": "c = 0", "SEC": "c = 1", "CLI": "i = 0", "SEI": "i = 1", "CLD": "d = 0", "SED": "d = 1", "CLV": "vf = 0"}[mn], nxt]
        elif mn in ("CLA", "CLX", "CLY"):
            b = [f"{reg[mn[2]]} = 0", nxt]
        elif mn in ("INX", "INY", "DEX", "DEY"):
            r = reg[mn[2]]
            b = [f"{r} = {r} {'+' if mn[0] == 'I' else '-'} 1 & 255; nz = {r}", nxt]
        elif mn in ("TAX", "TAY", "TXA", "TYA", "TSX"):
            sr = {"A": "a", "X": "x", "Y": "y", "S": "s"}
            b = [f"{sr[mn[2]]} = {sr[mn[1]]}; nz = {sr[mn[2]]}", nxt]
        elif mn == "TXS":
            b = ["s = x", nxt]
        elif mn in ("SXY", "SAX", "SAY"):
            p, q = reg[mn[1]], reg[mn[2]]
            b = [f"{p}, {q} = {q}, {p}", nxt]
        elif mn in ("ST0", "ST1", "ST2"):
            b = [f"iow({ {'ST0': 0, 'ST1': 2, 'ST2': 3}[mn] }, M[pc + 1])", nxt]
        elif mn == "TAM":
            b = ["tam(M[pc + 1], a)", nxt]
        elif mn == "TMA":
            b = ["a = tma(M[pc + 1])", nxt]
        elif mn in ("CSL", "CSH", "NOP"):
            b = [nxt]
        elif md == "blk":
            src = "u + k & 0xFFFF" if mn == "TAI" else "u"
            dst = "t + k & 0xFFFF" if mn == "TIA" else "t"
            inc = {"TII": "u = u + 1 & 0xFFFF; t = t + 1 & 0xFFFF", "TDD": "u = u - 1 & 0xFFFF; t = t - 1 & 0xFFFF",
                   "TIN": "u = u + 1 & 0xFFFF", "TIA": "u = u + 1 & 0xFFFF; k ^= 1", "TAI": "t = t + 1 & 0xFFFF; k ^= 1"}[mn]
            b = ["u = M[pc + 1] | M[pc + 2] << 8; t = M[pc + 3] | M[pc + 4] << 8; n = M[pc + 5] | M[pc + 6] << 8; k = 0",
                 "if n == 0: n = 0x10000",
                 "while n:",
                 f"    q = {src}",
                 "    v = rdt(q)" if track else "    v = M[q] if q >= 0x2000 else ior(q)",
                 f"    q = {dst}"]
            b += ["    wrt(q, v)"] if track else ["    if q >= 0x2000: M[q] = v", "    else: iow(q, v)"]
            b += [f"    {inc}", "    n -= 1", nxt]
        else:
            raise ValueError(mn)
        out.append(f"    def o{op:02X}():")
        out.append("        nonlocal a, x, y, s, pc, nz, c, vf, d, i")
        for line in b:
            for l2 in line.split("\n"):
                out.append("        " + l2)
        out.append(f"    ops[0x{op:02X}] = o{op:02X}")
    out += [
        "    def get():",
        "        return dict(a=a, x=x, y=y, s=s, pc=pc, p=" + PUSHP.format(b="0") + ", i=i)",
        "    def put(**k):",
        "        nonlocal a, x, y, s, pc, nz, c, vf, d, i",
        "        a = k.get('a', a); x = k.get('x', x); y = k.get('y', y); s = k.get('s', s); pc = k.get('pc', pc)",
        "        if 'p' in k:",
        "            t = k['p']; " + PULLP,
        "    def irq(vec):",
        "        nonlocal s, pc, i, d",
        "        M[0x2100 | s] = pc >> 8; s = s - 1 & 255; M[0x2100 | s] = pc & 255; s = s - 1 & 255",
        "        M[0x2100 | s] = " + PUSHP.format(b="0") + "; s = s - 1 & 255; i = 1; d = 0",
        "        pc = M[vec] | M[vec + 1] << 8",
        "        if pc >= TL: pc = trap(pc)",
        "    def setbp(addr, fn, o=None):",
        "        if o is None: o = M[addr]",
        "        h = ops[o]",
        "        def w():",
        "            if pc == addr: fn()",
        "            h()",
        "        ops[o] = w",
        "        return o, h",
        "    def clrbp(o, h):",
        "        ops[o] = h",
        "    def run(n):",
        "        for _ in range(n): ops[M[pc]]()",
        "    def runt(n, W, pre, mpr, LEN):",
        "        for _ in range(n):",
        "            o = M[pc]",
        "            for q in range(pc, pc + LEN[o]):",
        "                if not W[q]: pre.setdefault(mpr[q >> 13] << 13 | q & 0x1FFF, 2)",
        "            ops[o]()",
        "    return ops, get, put, irq, run, runt, setbp, clrbp",
    ]
    return "\n".join(out)


_MAKE = {}


def _make(track):
    if track not in _MAKE:
        ns = {}
        exec(compile(_gen(track), f"<huc6280 {'tracking' if track else 'plain'}>", "exec"), ns)
        _MAKE[track] = ns["make"]
    return _MAKE[track]


class Cpu:
    def __init__(self, machine, track=False, trap_lo=0xE000):
        self.mc = machine
        self.track = track
        self.trap_lo = trap_lo
        self.M = bytearray(0x10008)
        self.banks = {}
        self.ro = set()                     # read-only banks (no copy back)
        self.mpr = [0xFF, 0xF8, -1, -1, -1, -1, -1, -1]  # own: HuC6280 I/O ($FF) and base RAM ($F8) MPR reset state
        self.banks[0xF8] = bytearray(0x2000)
        self.W = bytearray(0x10008) if track else None
        self.wb = {}                        # the written maps of the banks not mapped (tracking)
        self.pre = {}
        self.alias = []                     # (pages, bytes) of the writable banks mapped at two pages
        self.ops, self.get, self.put, self.irq, self._run, self._runt, self.setbp, self.clrbp = _make(track)(
            self.M, machine.ior, machine.iow, machine.trap, self._tam, self._tma, self._rdt, self._wrt, trap_lo)
        self.LEN = [SIZE[OPS[o][1]] if o in OPS else 1 for o in range(256)]

    # ---- banks
    def bank(self, n, writable=True):
        b = self.banks.get(n)
        if b is None:
            b = self.banks[n] = bytearray(0x2000)
            if not writable:
                self.ro.add(n)
        return b

    def sync(self):
        """the mapped pages' bytes back into the bank store (call before reading banks from outside)"""
        for p in range(1, 8):
            n = self.mpr[p]
            if n in self.banks and n not in self.ro:
                self.banks[n][:] = self.M[p << 13:(p + 1) << 13]

    def map(self, p, n):
        """page p <- bank n. A writable bank mapped at two pages at once is kept equal by run() (the slow path: one
        instruction at a time, the changed page copied to the other)."""
        M, old = self.M, self.mpr[p]
        if old == n:
            return
        lo, hi = p << 13, (p + 1) << 13
        if p and old in self.banks and old not in self.ro:
            self.banks[old][:] = M[lo:hi]
            if self.track:
                self.wb[old] = bytes(self.W[lo:hi])
        self.mpr[p] = n
        if n == 0xFF:
            M[lo:hi] = bytes(0x2000)
        else:
            if n not in self.banks:
                self.bank(n, writable=(0x68 <= n <= 0x87))
            q = next((q for q in range(1, 8) if q != p and self.mpr[q] == n), None)
            if q is not None and n not in self.ro:           # the other page has the bank's bytes as they are now
                M[lo:hi] = M[q << 13:(q + 1) << 13]
                if self.track:
                    self.W[lo:hi] = self.W[q << 13:(q + 1) << 13]
            else:
                M[lo:hi] = self.banks[n]
                if self.track:
                    self.W[lo:hi] = self.wb.get(n, bytes(0x2000))
        self.alias = []
        for b in set(self.mpr[1:]):
            pg = [q for q in range(1, 8) if self.mpr[q] == b]
            if len(pg) > 1 and b not in self.ro and b != 0xFF:
                self.alias.append((pg, bytes(M[pg[0] << 13:(pg[0] + 1) << 13])))

    def _sync_alias(self):
        M = self.M
        for k, (pg, ref) in enumerate(self.alias):
            for q in pg:
                cur = M[q << 13:(q + 1) << 13]
                if cur != ref:
                    for r in pg:
                        if r != q:
                            M[r << 13:(r + 1) << 13] = cur
                            if self.track:
                                self.W[r << 13:(r + 1) << 13] = self.W[q << 13:(q + 1) << 13]
                    self.alias[k] = (pg, bytes(cur))
                    break

    def _tam(self, mask, a):
        for p in range(8):
            if mask >> p & 1:
                if p == 0 and a != 0xFF or p == 1 and a != 0xF8:
                    raise RuntimeError(f"TAM: page {p} <- ${a:02X}")
                self.map(p, a)

    def _tma(self, mask):
        for p in range(8):
            if mask >> p & 1:
                return self.mpr[p]
        return 0

    # ---- tracking
    def _rdt(self, ea):
        if ea < 0x2000:
            return self.mc.ior(ea)
        if not self.W[ea]:
            self.pre.setdefault(self.mpr[ea >> 13] << 13 | ea & 0x1FFF, 1)
        return self.M[ea]

    def _wrt(self, ea, v):
        if ea < 0x2000:
            self.mc.iow(ea, v)
        else:
            self.M[ea] = v
            self.W[ea] = 1

    def mark(self, bank, off, n):
        """bytes given by the caller (a disc read): written"""
        for p in range(1, 8):
            if self.mpr[p] == bank:
                self.W[(p << 13) + off:(p << 13) + off + n] = b"\x01" * n
                return
        w = bytearray(self.wb.get(bank, bytes(0x2000)))
        w[off:off + n] = b"\x01" * n
        self.wb[bank] = bytes(w)

    # ---- memory from outside (logical addresses, through the mapping)
    def peek(self, ea):
        return self.M[ea]

    def poke(self, ea, v):
        self.M[ea] = v
        if self.track:
            self.W[ea] = 1

    def run(self, n):
        while n > 0 and self.alias:
            if self.track:
                self._runt(1, self.W, self.pre, self.mpr, self.LEN)
            else:
                self._run(1)
            n -= 1
            if self.alias:
                self._sync_alias()
        if n <= 0:
            return
        if self.track:
            self._runt(n, self.W, self.pre, self.mpr, self.LEN)
        else:
            self._run(n)
