
FRAMES     = $2241
SCENE      = $207C
LOCKB      = $2025
CAMY       = $2D0E
NEXTY      = $2D0A      ; the BYR operand the vblank latch copies to $2D06 (0 in room 28)
PASS       = $339F
LATCH      = $4AE0      ; the immediate the vblank handler latches PASS into: the parity on screen
BYRLO      = $4AF6      ; the flip table: low bytes [parity 0, 1]
BYRHI      = $4AF8      ; ... high bytes
ROWCNT     = $6CCF
ROWGAME    = $5FFF
WINDOW     = $36D6      ; 1 while a menu, a text box or a scripted scene is up
ALLOCEND   = $40B3
PHC        = $37B6      ; the renderer's pass counter for the waterfall (incremented at each pass's setup)
PHASE      = $37B5      ; the waterfall phase counter (+1 when PHC & 3 becomes 0); phase = PHASE & 3
CULLY      = $4D87      ; the sprite emission's bottom cull (CPY #$D8 at $80:4D86: a piece whose Y is 216 or more is not drawn)
FINEOP     = $4CEC
MAPZP      = $34        ; ZP: the map bank (the renderer maps it at MPR6)
PROPZP     = $59
SHAFT      = 28
SHAFT2     = 29         ; the second waterfall shaft: the same renderer, its own setup (the scene is in the key)
MODE       = $0D        ; ZP $55 in the room's play
B0         = $FFFF      ; the flip table's values on the untouched disc: buffer at BAT row 0 (511), at row 18 (143)
B1         = $008F
TIMER      = $0C00
VDCREG     = $F7
SPLITS     = $F3
SATF       = $B1        ; ZP: bit 1 set from the sprite request until the vblank handler latches
OP_NEARPTR = $6CE6
OP_NEARCOL = $6CE3
OP_NEARLO  = $6CF2
OP_NEARH0  = $6CF7
OP_NEARHI  = $6CF9
OP_MIDOFF  = $6D06
OP_MIDMASK = $6D08
OP_MIDPTR  = $6D0B
OP_MIDLO   = $6D11
OP_MIDHI   = $6D18
OP_MAWRLO  = $6C85
OP_MAWRHI  = $6C87
OP_ROWS    = $6CD1
SPROW      = $6E74      ; the row helper's three special-row operands ($6E74, $6E78, $6E7C: $FF none)
SMAIN      = $F7
SLOAD      = SMAIN - 4  ; ... on the pass the room-change thread draws at its own top level (a load: door, Load, Continue)

POOL       = $772       ; the pool: class k at tile POOL + k
POOLH1     = $17        ; a pool word's high byte before the carry: palette 1, page $7 (written out: pceas gives unary < > the lowest precedence)
NMAX       = 128        ; classes at most (the pool is $772-$7FF: 142 tiles)
CMAPOFF    = $80        ; the class map's column in the mid map's rows (bytes $80-$9F)
IMG0       = $6B
TSRC       = $71
WBANK      = $72
W_MMAP     = $0000
W_TUP      = $0800
W_CMAP     = $0C00
W_CMAP16   = $0E00      ; (W_CMAP's row 16)
W_SAVE     = $0F00      ; (page-aligned: the 32 r additions never carry into the high byte)
W_HEAD     = $1100
W_NEXT     = $1200
LBANK      = $73        ; per camera row cy (0-47): the runs of its visible classes (mklist), at 128 cy (6 KB)
SRCL       = $BA00      ; (code bank RAM) per class k: the low byte and the page of 32 k from $6000
SRCH       = $BA80
MAWRL      = $BB00      ; (code bank RAM) per class k: MAWR of its pool tile, (POOL + k) * 16, low and high
MAWRH      = $BB80
ADOLYL     = $3163
ADOLYH     = $31A7
W_MASK     = $1300
BHUD       = 54
VBST       = 14
NOPRE      = 0
NOOURS     = 0
NULLIDLE   = 0          ; (experiment: idle time does nothing)
NULLMOD    = 0          ; (experiment: a module that does nothing: the stub's own cost alone)
ODELAY     = 0          ; (experiment: 8-cycle loops in the first row of a pass of ours)
DELAY      = 0          ; (experiment: with NOOURS, this many 8-cycle loops at the first row where a pass of ours would be)
NOOPS      = 0
NOIDLE     = 0          ; (experiment: no idle work for passes of ours)
NOR16      = 0          ; (experiments: no row-16 rewrite; NOFINE: the object draw's operand left alone)
NOFINE     = 0
NOPROV     = 1          ; (experiment: base + s at once, as build a3)
NOSB       = 0          ; (experiment: satbody skipped on a pass of ours: its entry never written)
NOCMAP     = 0          ; (experiment: the class map never written into the map bank)
DARKWAIT   = 0          ; (experiment: the dark grown by this many frames, nothing else)
IKEY       = 1          ; (shaft-join-020) 1: a new key whose mid-layer inputs equal the last whole images' keeps them (a door 28 <-> 29); 0: as r1c
NODARK     = 0          ; (1: the setup in idle slices only, in lit play, as build a3 and r1c. 0, the default from shaft-join-020 (the owner's
                        ; rule, 2026-11-12: smooth from the first lit frame, the loading extended): the setup in the DARK span at once)
PREDINV    = 0          ; (experiment: the prediction the wrong way round: every heavy pass after an s = 0 pass goes to the guard)
SLOWSET    = 0
SPILL      = 0
LOG        = $B800      ; the upload log (code bank RAM past the code: codeend is checked below it)
HSET       = 28
HPRE       = 33
SETST      = 98

	.include "stubsyms.inc"

MMODE      = $0C        ; ZP $55 in the mine's rooms (25, 30): the hand-off's pass (as the quarry's to the mine)

vsel	.macro
	lda #\1
	sta <VDCREG
	sta $0000
	.endm

	.bank 0
	.org $A000

	jmp rowent              ; 0 a row (a pass's first only: rowgame is set there)
	jmp satbody
	jmp modini              ; 2 modinit (an area load)
	jmp idlework
	jmp norts               ; 4 idlelate
	jmp norts               ; 5 lateup (not called: t0ok is cleared)
	jmp leave
	jmp norts               ; 7 vacate (Redmont's entry; not called for this bank)

magic:	.db $5A, $A5
ok:	.db 0
own:	.db 0
wlo:	.db 0, 0
whi:	.db 0, 0
rok:	.db 0           ; a first row was seen since the last satbody
jsc:	.db $FF
gap:	.db 0
hbk:	.db 0
sld:	.db 0
ikv:	.db 0
ik0:	.db 0
ik1:	.db 0
ik2:	.db 0
nikey:	.db 0           ; set-ups that kept the images (IKEY)
blk:	.db 0           ; the setup to run at once (idlework)
dead:	.db 0           ; (DARKWAIT)
dk:	.db 0
sbw:	.db 0
wo:	.db 0
cap:	.db 1
run:	.db 0           ; idle time's judge: the next pass may take the hot path
slw:	.db 0           ; the last pass took the slow path: slowidle to run
rb4:	.db 0           ; MPR4 at the last slow first row (the renderer's property bank)
rfr:	.db 0           ; FRAMES at the last first row
sps:	.db 0           ; stack pointer at the last first row
ours:	.db 0           ; this pass draws the class slots
cs:	.db 0           ; this pass's s, phase, camera (lo, hi), near pointer at row 0, MAWR at row 0
cp:	.db 0
cyl:	.db 0
cyh:	.db 0
cnl:	.db 0
cnh:	.db 0
cml:	.db 0
cmh:	.db 0
live:	.db 0           ; engaged: an s = 0 pass seen since the setup or the last stand-down
pcyl:	.db 0
pcyh:	.db 0
pcv:	.db 0
pdir:	.db 2           ; the camera's last step
setok:	.db 0           ; the setup is done for key
ss:	.db 0           ; setup step (0 none), its counters
sr:	.db 0
sc:	.db 0
sk:	.db 0
key:	.ds 10
nkey:	.ds 10
ncls:	.db 0           ; classes
mapw:	.db 0           ; our class map is in the map bank (saved bytes in WBANK)
; per pending upload: the set to put in the pool, and the row 16 to rewrite
prq:	.db 0           ; (unused)
ipass:	.db 0           ; PASS at the last prep
ifr:	.db 0           ; FRAMES at the idle call's start
upq:	.db 0           ; 1: the pool must hold (up, us) before the latch of the last pass (or the predicted next pass)
up:	.db 0
us:	.db 0
r16q:	.db 0           ; 1: row 16 of the last pass's buffer to rewrite (its near pointer and MAWR at row 0)
r16nl:	.db 0
r16nh:	.db 0
r16ml:	.db 0
r16mh:	.db 0
hp:	.db $FF         ; what the pool holds: phase, s ($FF: nothing valid)
hsv:	.db $FF
hcy:	.db $FF
ucy:	.db 0           ; the camera row of the set to upload
mr:	.db 0           ; the masks' next camera row and window row, the rows done (bits), all done
mc:	.db 0
mrdy:	.ds 6
mdone:	.db 0
ones:	.db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
bours:	.db 0, 0        ; per parity: the buffer holds class-slot words (drawn by a pass of ours)
dirty:	.db 0           ; pool tiles may be non-zero
zpend:	.db 0
zi:	.db 0
t0:	.db 0
t1:	.db 0
t2:	.db 0
t3:	.db 0
tr0:	.db 0
hok:	.db 0
hst:	.db 0
lhs:	.db 0
lhf:	.db $80
ubad:	.db 0
ubs:	.db 0
ubn:	.db 0
sv3:	.db 0
sv4:	.db 0
sv6:	.db 0
ssb4:	.db 0           ; the renderer's MPR4 (property table) at the setup's first row
smap:	.db 0           ; the map bank
nlo:	.db 0
nhi:	.db 0
mlo:	.db 0
mhi:	.db 0
; counters (for the checks)
neng:	.dw 0           ; passes of ours
nupl:	.dw 0           ; uploads done
npre:	.dw 0           ; uploads made for a predicted pass
nhit:	.dw 0           ; passes of ours whose set the pool held already (predicted right, or standing)
nunf:	.dw 0           ; uploads not finished by their bound (a wrong picture: must stay 0)
nr16:	.dw 0           ; row 16 rewrites
nr16x:	.dw 0           ; row 16 rewrites not done before their pass's latch
nset:	.db 0           ; setups finished
nsetf:	.db 0           ; setups failed (classes over NMAX, a mid pointer off its column)
tset:	.db 0           ; FRAMES at the setup's start, frames it took
tsetn:	.db 0
nleave:	.db 0
pxp:	.db 0           ; the parity of the last drawn buffer
ndef:	.db 0           ; passes of ours whose set could not be uploaded by their latch (not begun: provisional shown)
nlate:	.db 0           ; passes of ours latched before their own end (their provisional picture shown)
ndark:	.db 0
ndisp:	.dw 0
maxul:	.db 0
nrest:	.db 0
; the proof (shaft-upload-v2): a buffer of class slots is on screen only while the pool holds its set
nshow:	.dw 0           ; idle entries with the buffer on screen drawn by a pass of ours and the pool not holding its set (must be 0)
nstep:	.dw 0
bp:	.db $FF, $FF    ; per parity: the set (phase, s, camera row) of the pass of ours that drew that buffer
bs:	.db $FF, $FF
bcy:	.db $FF, $FF
hvy:	.db 1           ; (the guard) the next pass may be the heavy one after an s = 0 pass at a multiple of 16
hvv:	.db 0           ; ... and its set is known: phase hvp, s = 2, camera row hvcy
hvp:	.db 0
hvcy:	.db 0
narm:	.dw 0           ; idle ends with the guard armed

baselo:	.db <B0, <B1
basehi:	.db >B0, >B1
bit:	.db 1, 2

; ---------------------------------------------------------------- a pass's first row (bank $81 at MPR3)
rgx:	lda SCENE
	cmp #H2SCA
	beq .h
	cmp #H2SCB
	bne .g
.h:	lda <$55
	cmp #MMODE
	bne .g
	jmp hoff
.g:	sec
	rts

rowent:	.if NULLMOD
	lda #1
	sta ROWGAME
	stz STUB_T0OK
	sec
	rts
	.endif
	stz STUB_T0OK
	lda run
	beq rgx                 ; $80 the same with the facts idle time asked for, 1 the hot path
	bmi rslow
	sta rok
	lda FRAMES
	sta rfr
	lda SCENE
	cmp key+9
	bne rgx
	lda CAMY+1
	sta cyh
	lda CAMY
	sta cyl
	and #6
	sta cs
	beq rz
	ldx live                ; (X: A keeps s for the guard)
	beq rgm
gchk:	cmp #$FF                ; the guard (arm, in idle time): 2 when this pass may be the heavy one after an s = 0 pass at a camera
	beq rgh
	.if NOOURS
	bra rgm
	.endif
	lda OP_MIDPTR           ; a pass of ours: the phase's column (32 p), then the operands
	sta cp
	bit #$9F
	bne rsd
	.if ODELAY
	ldx #ODELAY
.od:	nop
	dex
	bne .od
	.endif
	lda #CMAPOFF
	sta OP_MIDPTR
	lda #<(POOL - 1)
	sta OP_MIDLO            ; BEQ: two cycles a cell)
	lda #>(POOL - 1)
	sta OP_MIDHI
	.if NOFINE = 0
	lda #$10                ; the objects on the smooth picture (satbody puts $11 back); the bottom cull moved up by s with
	sta FINEOP              ; them, so that every piece is drawn or culled as on the untouched disc (the same SAT entries, the
	lda #$D8                ; same cycles: a piece whose top lies in the playfield's last s lines is culled, as there)
	sec
	sbc cs
	sta CULLY
	.endif
	lda #1
	sta ours
	.if NOSB = 0
	sta sbw
	.endif
rgm:	sec
	rts
rz:	lda #1
	sta live
	sec
	rts
rgh:	inc nstep
	bne rgm
	inc nstep+1
	sec
	rts
rsd:	stz live
	sec
	rts
rslow:	tsx                     ; the facts idle time asked for (slowidle): the stack level, the renderer's MPR4
	stx sps
	cpx #SLOAD
	bne .l
	stx sld
.l:
	tma #4
	sta rb4
	sta slw                 ; (non-zero: a bank number)
	cpx #SMAIN
	bne .k
	stz run
.k:	jmp rgx

slowidle:	stz slw
	stz live
	stz pcv
	lda ok                  ; the flip table's proof once per area load (block 14 is in by then)
	bne .p
	jsr proof
	lda ok
	beq .x
.p:	lda SCENE
	cmp #SHAFT
	beq .in
	cmp #SHAFT2
	beq .in
	jsr disengage
	stz pcv
	stz hbk
	stz sld
.x:	rts
.in:	lda <$55
	cmp #MODE
	bne .x
	lda sld                 ; (shaft-join-020: the load's own pass since the last call, sld, though the last pass was another)
	stz sld
	bne .ld
	lda sps
	cmp #SLOAD
	bne .ml
.ld:	tst #$08, LOCKB
	beq .ml1
	jsr disengage           ; (F7: the class map put back where the map bank still holds it, row by row: a load that rewrote the
	lda mapw                ; bank left nothing to put back, one that did not leaves our map to mapback; the key decides the rest
	beq .ml0
	jsr mapback
.ml0:	lda #1
	sta gap
	lda sps                 ; (shaft-join-020: that pass came already: on to it)
	cmp #SMAIN
	beq .ml
	rts
.ml1:	lda sps
.ml:	cmp #SMAIN
	bne .x
	.if NODARK = 0
	tst #$08, LOCKB
	beq .k
	lda gap
	ora hbk
	beq .x
	stz gap
	stz hbk
	lda #1
	sta blk
	.endif
.k:	stz hbk
	jsr keychk
	bcs .nk
	lda setok
	beq .x
	lda mapw
	ora ss
	bne .x
	lda #7                  ; (s_end)
	sta ss
	stz sr
	stz setok
	rts
.nk:	jsr diseng0             ; (a new key: the set-up below replaces any under way)
	stz setok
	lda #1
	.if IKEY
	ldx ikv
	beq .nk1
	ldx smap
	cpx ik0
	bne .nk0
	ldx mlo
	cpx ik1
	bne .nk0
	ldx mhi
	cpx ik2
	bne .nk0
	inc nikey
	jsr minit
	lda #6
	bra .nk1
.nk0:	stz ikv
	.endif
.nk1:	sta ss
	stz sr
	stz sc
	stz sk
	lda FRAMES
	sta tset
	rts

judge:	stz run
	.if DARKWAIT
	lda dead
	beq .alive
	lda #1
	sta ROWGAME
	rts
.alive:
	.endif
	lda ok
	beq .x
	lda setok
	beq .x
	lda mapw
	beq .x
	lda SCENE
	cmp key+9
	bne .x
	lda <$55
	cmp #MODE
	bne .x
	lda WINDOW
	beq .s0
	jmp .sd
.s0:
	tst #$08, LOCKB
	beq .s1
	lda dk
	beq .sd
.s1:
	lda NEXTY
	ora NEXTY+1
	bne .sd
	jsr allocchk
	bcs .sd
	tma #3                  ; (the renderer's operands: bank $81 at MPR3)
	pha
	lda #$81
	tam #3
	lda SPROW
	and SPROW + 4
	and SPROW + 8
	tax
	lda OP_MIDOFF
	sta t0
	pla
	tam #3
	cpx #$FF
	bne .sd
	lda t0
	bne .sd
	lda <MAPZP              ; the key's zero-page part unchanged (the setup's)
	cmp key
	bne .sd
	lda <$6A
	cmp key+6
	bne .sd
	lda <$6B
	cmp key+7
	bne .sd
	lda #1
	sta run
	sta ROWGAME
	rts
.sd:	stz live                ; (a stand-down: into .x; here, so the branches to it reach)
.x:	lda #1
	sta ROWGAME
	lda ss
	beq .c
	tst #$08, LOCKB
	bne .cd
	lda SCENE
	cmp key+9
	beq .r
	jsr setcut
	bra .c
.c:	lda SCENE
	cmp #SHAFT
	beq .c1
	cmp #SHAFT2
	beq .c1
	cmp jsc
	beq .r
.c1:	sta jsc
	lda #$80                ; (the next first row: the slow path with the facts)
	sta run
.r:	rts
.cd:	lda <$7C
	cmp key+9
	bne .cx
	bra .c1
.cx:	jsr setcut
	bra .c

keychk:	lda <MAPZP
	sta nkey
	lda rb4
	sta nkey+1
	lda <PROPZP
	sta nkey+2
	lda <PROPZP+1
	sta nkey+3
	lda <$66
	sta nkey+4
	lda <$67
	sta nkey+5
	lda <$6A
	sta nkey+6
	lda <$6B
	sta nkey+7
	tma #3                  ; (the renderer's operand: bank $81)
	pha
	lda #$81
	tam #3
	lda OP_NEARH0
	sta nkey+8
	pla
	tam #3
	lda SCENE
	sta nkey+9
	ldx #9
.c:	lda nkey,x
	cmp key,x
	bne .d
	dex
	bpl .c
	clc                     ; (all equal)
	rts
.d:	ldx #9
.s:	lda nkey,x
	sta key,x
	dex
	bpl .s
	lda nkey                ; the setup's sources
	sta smap
	lda nkey+1
	sta ssb4
	lda nkey+4
	sta nlo
	lda nkey+5
	clc
	adc nkey+8
	sta nhi
	lda nkey+6
	sta mlo
	lda nkey+7
	sta mhi

	sec
.x:	rts

allocchk:	ldx #0
.l:	lda ALLOCEND,x
	beq .ok
	cmp #$78
	bcs .no
	inx
	cpx #48
	bne .l
.ok:	clc
	rts
.no:	sec
	rts

disengage:	lda ss
	beq diseng0
	jsr setcut
diseng0:	stz live
	stz ours
	stz upq
	stz r16q
	lda zpend               ; (already counting down: as it is)
	bne .x
	lda dirty
	ora mapw
	beq .x
	lda #3
	sta zpend
	stz zi
.x:	rts
setcut:	stz ss
	stz setok
	lda #$FF
	sta key+9
	rts

satbody:	.if NULLMOD
	rts
	.endif
	lda sbw                 ; (nothing of ours in the table and not a pass of ours: nothing; idle time sees the pass by PASS)
	bne .f
	rts
.f:	lda ours
	beq .g
	lda #$11                ; the object draw's operand and cull back (ours ended with this pass's sprites)
	sta FINEOP
	lda #$D8
	sta CULLY
.g:	lda rok
	bne .p
	lda ok
	beq .x
	jsr restore
	bra .x
.p:	stz rok
	lda #1
	sta prq                 ; (idle time: prep)
	lda ok
	beq .x
	lda PASS                ; the entry the vblank latches next: PASS & 1, unless it is the one on screen
	and #1
	tax
	eor LATCH
	and #1
	bne .w
	inc ndisp
	bne .x
	inc ndisp+1
.x:	lda own                 ; (satbody runs again while an entry of ours is in the table)
	sta sbw
	rts
.w:	stx pxp
	lda ours
	bne .s
	lda own
	and bit,x
	beq .g0
	lda baselo,x
	sta BYRLO,x
	lda basehi,x
	sta BYRHI,x
	lda bit,x
	trb own
.g0:	stz bours,x
	bra .x
.s:	lda cs                  ; base + s: provisional (base + the pool's s, when it holds a set: the buffer then shows a whole
	.if NOPROV = 0          ; picture, the pool's phase at its s) until idle time has the pass's own set in the pool (upg); a
	ldy hsv                 ; heavy pass whose request is latched before its end has no idle time before that latch: it shows
	cpy #$FF                ; the provisional picture for a frame, never an unfinished set
	beq .s0
	tya
.s0:
	.endif
	clc
	adc baselo,x
	sta wlo,x
	sta BYRLO,x
	lda basehi,x
	adc #0
	sta whi,x
	sta BYRHI,x
	lda bit,x
	tsb own
	lda #1
	sta bours,x
	bra .x

f8op:	lda #$11                ; (prep, F8: out of line, so prep's branches reach)
	sta FINEOP
	lda #$D8
	sta CULLY
	rts

prep:	stz prq
	lda #1                  ; (the guard: armed for the next pass unless this pass's camera shows it cannot be the heavy one)
	sta hvy
	stz hvv
	lda ours                ; (this pass's: rowent sets it, nobody clears it before here)
	sta wo
	stz ours
	tax
	lda zpend
	cmp #2
	bcc .z
	txa
	bne .z
	dec zpend
.z:	txa
	beq .gp
	.if NOFINE = 0
	lda rok
	beq .f8
	jsr f8op
.f8:
	.endif
	inc neng
	bne .n
	inc neng+1
.n:	lda #1
	sta upq
	sta r16q
	sta dirty               ; (the pool holds tiles of ours from now until it is zeroed)
	lda cyh                 ; camera row cy = camera >> 3
	lsr a
	lda cyl
	ror a
	lsr a
	lsr a
	sta ucy
	lda cp                  ; phase = column / 32
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	and #3
	sta up
	lda cs
	sta us
	ldx pxp                 ; (the proof: the set this buffer shows)
	lda up
	sta bp,x
	lda us
	sta bs,x
	lda ucy
	sta bcy,x
	lda #$81                ; row 16 of the drawn buffer: the renderer's row 0 near pointer and MAWR (its operands now hold row
	tam #3                  ; 17's: 17 rows of 64 on)
	lda OP_NEARPTR          ; (- 64: row 16)
	sec
	sbc #$40
	sta r16nl
	lda OP_NEARPTR+1
	sbc #0
	sta r16nh
	lda OP_MAWRLO
	sec
	sbc #$40
	sta r16ml
	lda OP_MAWRHI
	sbc #0
	sta r16mh
	jmp .q
.gp:	stz upq
	stz r16q
	lda live
	bne .g1
	jmp .q
.g1:
	lda run
	beq .gq
	lda cs
	beq .g2
.gq:	jmp .q
.g2:	lda cyh
	bne .bt
	lda cyl
	beq .gd
	bra .ad
.bt:	lda cyl
	cmp #<384
	beq .gu
.ad:	lda ADOLYH
	bmi .gu
	bne .gd
	lda ADOLYL
	cmp #64
	.if PREDINV
	bcc .gd
	.else
	bcs .gd
	.endif
.gu:	lda #$FE
	bra .pd
.gd:	lda #2
.pd:	sta t0                  ; the next pass: camera + d, s = its & 7, row its >> 3; phase: PHASE + 1 when PHC + 1 is a multiple of 4
	clc
	adc cyl
	sta t1
	and #7
	sta us
	lda t0
	bmi .dn
	lda cyh
	adc #0
	bra .dh
.dn:	lda cyh
	adc #$FF
.dh:	lsr a
	lda t1
	ror a
	lsr a
	lsr a
	sta ucy
	lda PHC
	inc a
	and #3
	beq .p1
	cla
	bra .ph
.p1:	lda #1
.ph:	clc
	adc PHASE
	and #3
	sta up
	sta hvp                 ; (the guard: the set the heavy pass down would need, the next phase at s = 2 in this camera row)
	lda cyh
	lsr a
	lda cyl
	ror a
	lsr a
	lsr a
	sta hvcy
	lda #1
	sta hvv
	.if NOPRE = 0
	lda #2                  ; (2: a prediction)
	sta upq
	.endif
.q:	lda run                 ; (the camera is recorded by the hot path only)
	beq .q2
	lda cs                  ; (the guard: a pass at s != 0, or at s = 0 off a multiple of 16: the next is not the heavy one)
	bne .h0
	lda cyl
	and #15
	beq .h1
.h0:	stz hvy
.h1:
	lda pcv                 ; the camera's last step (2 or -2) for the next prediction while standing
	beq .q1
	lda cyl
	sec
	sbc pcyl
	cmp #2
	beq .q0
	cmp #$FE
	bne .q1
.q0:	sta pdir
.q1:	lda cyl                 ; this pass's camera for the next prediction
	sta pcyl
	lda cyh
	sta pcyh
	lda SCENE
	cmp key+9
	bne .q2
	lda #1
	sta pcv
	rts
.q2:	stz pcv
	rts

proof:	ldx #1
.c:	lda own
	and bit,x
	beq .g
	lda BYRLO,x
	cmp wlo,x
	bne .x
	lda BYRHI,x
	cmp whi,x
	bne .x
	bra .n
.g:	lda BYRLO,x
	cmp baselo,x
	bne .x
	lda BYRHI,x
	cmp basehi,x
	bne .x
.n:	dex
	bpl .c
	inc ok
.x:	rts

restore:	lda own
	beq .x
	inc nrest
	ldx #1
.r:	lda own
	and bit,x
	beq .n
	lda BYRLO,x
	cmp wlo,x
	bne .o
	lda BYRHI,x
	cmp whi,x
	bne .o
	lda baselo,x
	sta BYRLO,x
	lda basehi,x
	sta BYRHI,x
.o:	lda bit,x
	trb own
	stz bours,x
.n:	dex
	bpl .r
.x:	rts

rdtim:	lda TIMER
	and #$7F
	cmp #116
	bcc .x
	cla
.x:	rts

idlework:	.if NULLMOD | NULLIDLE
	rts
	.endif
	tma #3
	sta sv3
	tma #4
	sta sv4
	tma #6
	sta sv6
	lda <VDCREG
	pha
	lda FRAMES              ; (the idle call's frame: tleft)
	sta ifr
	lda slw                 ; a slow pass's tests, the last pass's record (a pass came: PASS moved), then the judge for the next pass
	beq .s
	jsr slowidle
.s:	lda PASS
	cmp ipass
	beq .j
	sta ipass
	jsr prep
.j:	jsr shown               ; the proof (after prep: a pass latched before its own idle call shows its own set, recorded there;
	jsr judge               ; nothing of this call has touched the pool yet)
	lda blk
	beq .nb
	jsr setdark
.nb:	tst #$08, LOCKB
	bne .db
	stz dk
.db:	stz hok
	bbr6 <SPLITS, .nh
	ldx <$41
.pre:	bbr6 <SPLITS, .hud
	lda ss
	beq .p0
	jsr sstep
	bra .pre
.p0:	bbr6 <SPLITS, .hud      ; (shaft-setup-bound, the Load-list hang: no set-up step to run, the wait bounded by the frame. A
	cpx FRAMES
	beq .p0
	lda FRAMES
	cmp ifr                 ; (X not the frame: in the idle call's own frame it was a set-up step's X: again; else a vblank went
	beq .px
	jmp .o
.px:	tax
	bra .p0
.hud:	jsr rdtim
	sta hst
	sta lhs
	lda FRAMES
	sta lhf
	lda #1
	sta hok
	bra .run
.nh:	lda FRAMES
	sec
	sbc lhf
	cmp #30
	bcs .run
	tax                     ; (frames since) * 215 / 256
	stz t1
	stz t2
	cpx #0
	beq .m1
.mu:	lda t1
	clc
	adc #215
	sta t1
	bcc .m0
	inc t2
.m0:	dex
	bne .mu
.m1:
	lda lhs
	and #$7F
	sec
	sbc t2
	bcs .hs
	adc #116
.hs:	sta hst
	lda #1
	sta hok
.run:	lda zpend
	cmp #1
	bne .r1
	jsr tleft
	bcc .o
	jsr release
	bra .run
.r1:	lda ss
	beq .u
.sl:	jsr tleft               ; the setup's steps while time is left
	bcc .o
	lda ss
	beq .o
	jsr sstep
	bra .sl
.u:	.if NOIDLE
	stz upq
	stz r16q
	.endif
	lda r16q
	beq .up
	.if NOR16 = 0
	jsr row16
	.endif
.up:	lda upq
	beq .z
	jsr upload
	bra .o
.z:	lda zpend
	cmp #1
	bne .o
	jsr tleft
	bcc .o
	jsr release
	bra .z
.o:	jsr arm
	pla
	sta <VDCREG
	sta $0000
	lda sv3
	tam #3
	lda sv4
	tam #4
	lda sv6
	tam #6
norts:	rts

shown:	lda LATCH
	and #1
	tax
	lda bours,x
	beq .x
	lda bp,x
	cmp hp
	bne .b
	lda bs,x
	cmp hsv
	bne .b
	lda bcy,x
	cmp hcy
	beq .x
.b:	inc nshow
	bne .x
	inc nshow+1
.x:	rts

arm:	ldx #$FF
	lda hvy
	beq .w
	ldx #2
	lda hvv
	beq .a
	lda hp
	cmp hvp
	bne .a
	lda hsv
	cmp #2
	bne .a
	lda hcy
	cmp hvcy
	bne .a
	ldx #$FF
	bra .w
.a:	inc narm
	bne .w
	inc narm+1
.w:	stx gchk+1
	rts

setdark:	stz blk
	.if DARKWAIT
	lda FRAMES              ; (experiment: the dark grown by DARKWAIT frames, no setup, the module idle from here on)
	clc
	adc #DARKWAIT
.dw:	cmp FRAMES
	bne .dw
	stz ss
	lda #1
	sta dead
	rts
	.endif
.l:	lda ss
	beq .e
	jsr sstep
	bra .l
.e:	lda setok
	beq .x
	lda #1
	sta live
	sta dk
	stz zpend
	inc ndark
.x:	jmp judge

upg:	lda wo
	beq .x
	ldx pxp
	lda bours,x
	beq .x
	lda us
	clc
	adc baselo,x
	sta wlo,x
	lda basehi,x
	adc #0
	sta whi,x
	php
	sei
	sta BYRHI,x
	lda wlo,x
	sta BYRLO,x
	plp
.x:	rts

tleft:	lda FRAMES
	cmp ifr
	bne .n
	bbs6 <SPLITS, .y
	lda hok
	beq .n
	lda hst
	jsr since
	cmp #HSET
	bcs .n
.y:	sec
	rts
.n:	clc
	rts

since:	and #$7F
	sta t0
	jsr rdtim
	and #$7F
	eor #$FF
	sec
	adc t0                  ; stamp - now
	bcs .x
	adc #116
.x:	rts

upload:	lda up
	cmp hp
	bne .go
	lda us
	cmp hsv
	bne .go
	lda ucy
	cmp hcy
	bne .go
	lda upq                 ; (held already)
	cmp #1
	bne .h
	jsr upg
.h:	stz upq
	inc nhit
	bne .x
	inc nhit+1
.x:	rts
.go:	lda upq
	cmp #2
	bne .g1
	lda hok
	bne .g1
	stz upq
	rts
.g1:	lda FRAMES
	sta t3
	stz pk0                 ; (from class 0, or where the same set stopped)
	lda up
	cmp kp
	bne .w
	lda us
	cmp ks
	bne .w
	lda ucy
	cmp kcy
	bne .w
	lda kk
	sta pk0
.w:	.if NOPROV
	bbr1 <SATF, .now        ; latched already: at once (as build a3)
	.else
	bbs1 <SATF, .w1         ; latched already: at once, unless the buffer latched is a pass of ours (a heavy pass whose request
	lda LATCH               ; was latched before its own end: its provisional picture shows; the next pass's set comes next)
	and #1
	tax
	lda bours,x
	beq .now
	inc nlate
	stz upq
	rts
.w1:
	.endif
	lda LATCH
	and #1
	tax
	lda bours,x
	beq .now
	lda FRAMES
	cmp rfr
	bne .lt
.wh:	bbs6 <SPLITS, .wh
	bra .now
.lt:	bbs6 <SPLITS, .lp
	bbr1 <SATF, .now
	lda FRAMES
	sec
	sbc t3
	cmp #2
	bcc .lt
	lda #4
	jmp .bad
.lp:	bbs6 <SPLITS, .lp
.now:
	.if SPILL
	lda upq
	cmp #1
	bne .sp1
	lda hok
	beq .sp1
.sp0:	lda hst
	jsr since
	cmp #SPILL
	bcc .sp0
.sp1:
	.endif
	lda #1                  ; (the pool holds tiles of ours until it is zeroed)
	sta dirty
	lda tr0                 ; (the log: steps from the first row to the start)
	jsr since
	sta lgs
	lda #$FF                ; (the pool is mid-change)
	sta hp
	sta hsv
	lda up
	sta kp
	lda us
	sta ks
	lda ucy
	sta kcy
	lda FRAMES
	sta uf
	stz vseen
	bbs1 <SATF, .b
	lda hok
	bne .b1
	lda #1
	jmp .bad
.b1:	lda #1                  ; (latched already: the vblank is behind us)
	sta vseen
	jsr rdtim
	sta tv
.b:	lda up
	asl a
	adc up
	sta t1
	lda us
	lsr a
	clc
	adc t1
	dec a
	sta t1
	lsr a
	clc
	adc #IMG0
	tam #3
	lda t1                  ; the block's page offset ($10 when odd)
	and #1
	asl a
	asl a
	asl a
	asl a
	sta t2
	lda #LBANK
	tam #4
	lda ucy
	lsr a
	clc
	adc #$80
	sta .rn+2
	sta .rk+2
	lda ucy
	lsr a
	cla
	ror a
	sta .rn+1
	ora #1
	sta .rk+1
	sta .rq+1
	lda .rk+2
	sta .rq+2
	lda pk0                 ; (the run to begin with: 0, or where the same set stopped)
	sta kk
	tay                     ; its MAWR first, whatever its bit 7 (a set that goes on after a stop)
.rk0:	lda .rk+1
	sta .r0+1
	lda .rk+2
	sta .r0+2
.r0:	lda $FFFF,y
	and #$7F
	tax
	vsel 0
	lda MAWRL,x
	sta $0002
	lda MAWRH,x
	sta $0003
	vsel 2
.l:	bbr6 <SPLITS, .i1       ; (the bounds, once a run)
	lda #3
	jmp .bd
.i1:	lda upq
	cmp #2
	bne .i3
	lda hst
	jsr since
	cmp #HPRE
	bcc .i3
	jmp .stop
.i3:	lda vseen
	bne .v
	lda FRAMES
	cmp uf
	beq .t
	lda upq                 ; (a predicted set: stopped when the vblank came)
	cmp #2
	bne .i2
	jmp .stop
.i2:	lda #1
	sta vseen
	jsr rdtim
	sta tv
.v:	lda hok
	beq .vt                 ; 60.0: see BHUD); no stamp: VBST from the vblank seen
	lda hst
	jsr since
	sta ubs
	cmp #BHUD
	bra .vc
.vt:	lda tv
	jsr since
	sta ubs
	cmp #VBST
.vc:	lda #2
	bcc .t
	jmp .bd
.t:	ldy kk
.rn:	lda $FFFF,y             ; the run's length, 0 after the last
	bne .t1
	jmp .done
.t1:	sta .ti+5
.rk:	lda $FFFF,y             ; its first class (bit 7: the MAWR is there)
	iny
	iny
	sty kk
	and #$7F                ; (every chunk its own MAWR, and interrupts off from it to the TIA's end (F4): no interrupt between
	tax
	lda SRCL,x
	sta .ti+1
	lda SRCH,x
	ora t2
	sta .ti+2
	nop
	sei
	st0 #0
	lda MAWRL,x
	sta $0002
	lda MAWRH,x
	sta $0003
	vsel 2
.ti:	tia $6000, $0002, 32
	cli
	ldy kk                  ; the next chunk marked (the second 4 tiles of a run): at once, no bounds
.rq:	lda $FFFF,y
	bpl .lj
	jmp .t
.lj:	jmp .l
.stop:	vsel 2                  ; (kk: the class to go on from; kp, ks, kcy: the set)
	lda #2
	jsr ulog
	inc nstop
	bne .s1
	inc nstop+1
.s1:	stz upq
	rts
.done:	lda #1
	jsr ulog
	lda up
	sta hp
	lda us
	sta hsv
	lda ucy
	sta hcy
	lda #$FF                ; (no partial set)
	sta kp
	lda upq
	cmp #2
	beq .p
	jsr upg
	bra .c
.p:	inc npre
	bne .c
	inc npre+1
.c:	stz upq
	inc nupl
	bne .m
	inc nupl+1
.m:	lda vseen
	beq .e
	lda tv
	jsr since
	cmp maxul
	bcc .e
	sta maxul
.e:	rts
.bd:	vsel 2
.bad:	sta ubad
	clc
	adc #8
	jsr ulog
	lda kk
	sta ubn
	lda #$FF
	sta kp
	stz upq                 ; (not finished: the pool is wrong for that buffer)
	inc nunf
	bne .e
	inc nunf+1
	rts
; the upload log (a ring of 64 entries of 8 bytes at LOG): FRAMES, the pass's frame, result (1 done, 2 stopped at the vblank, 8 + why
; not finished), classes reached, steps from the first row to the start and to now, vseen, upq
ulog:	pha
	lda lgi
	asl a
	asl a
	asl a
	tax
	pla
	sta LOG + 2,x
	lda FRAMES
	sta LOG,x
	lda rfr
	sta LOG + 1,x
	lda kk
	sta LOG + 3,x
	lda lgs
	sta LOG + 4,x
	lda tr0
	jsr since
	sta LOG + 5,x
	lda vseen
	sta LOG + 6,x
	lda upq
	sta LOG + 7,x
	lda lgi
	inc a
	and #63
	sta lgi
	rts
lgi:	.db 0
lgs:	.db 0
uf:	.db 0
vseen:	.db 0
tv:	.db 0
pk0:	.db 0
kk:	.db 0           ; the class being uploaded; kp, ks, kcy: the set a stopped upload was making ($FF none)
kp:	.db $FF
ks:	.db 0
kcy:	.db 0
lastk:	.db 0
ck:	.db 0
ntl:	.dw 0           ; tiles uploaded
nstop:	.dw 0           ; predicted sets stopped at a vblank
bitk:	.db $01, $02, $04, $08, $10, $20, $40, $80, $01, $02, $04, $08, $10, $20, $40, $80
	.db $01, $02, $04, $08, $10, $20, $40, $80, $01, $02, $04, $08, $10, $20, $40, $80
	.db $01, $02, $04, $08, $10, $20, $40, $80, $01, $02, $04, $08, $10, $20, $40, $80
	.db $01, $02, $04, $08, $10, $20, $40, $80, $01, $02, $04, $08, $10, $20, $40, $80
	.db $01, $02, $04, $08, $10, $20, $40, $80, $01, $02, $04, $08, $10, $20, $40, $80
	.db $01, $02, $04, $08, $10, $20, $40, $80, $01, $02, $04, $08, $10, $20, $40, $80
	.db $01, $02, $04, $08, $10, $20, $40, $80, $01, $02, $04, $08, $10, $20, $40, $80
	.db $01, $02, $04, $08, $10, $20, $40, $80, $01, $02, $04, $08, $10, $20, $40, $80

; row 16 of the last pass's buffer: its 33 words, the near word or the class of (row 15, row 15) at that column. Before its latch;
; after it (a late request, a heavy frame's) still before the beam reaches the playfield's last lines, most likely: counted (nr16x)
row16:	stz r16q
	bbs1 <SATF, .go         ; (latch to come: the buffer is hidden)
	bbr6 <SPLITS, .go
	inc nr16x               ; (latched, its playfield up: row 16 is its last 8 lines, about 50k cycles on; written now all the
	bne .go                 ; same: counted)
	inc nr16x+1
.go:	lda smap                ; near map at MPR6 (as the renderer has it), property table at MPR4, our class row 16 at MPR3
	tam #6
	lda ssb4
	tam #4
	lda #WBANK
	tam #3
	vsel 0
	lda r16ml
	sta $0002
	lda r16mh
	sta $0003
	vsel 2
	lda r16nl
	sta .nm+1
	lda r16nh
	sta .nm+2
	cly
.c:
.nm:	lda $FFFF,y
	and #$7F
	tax
	sty t0
	tay
	lda [PROPZP],y
	ldy t0
	bit #$80
	bne .mid
	txa
	clc
	adc nlo
	sta $0002
	lda nhi
	adc #0
	sta $0003
	bra .nx
.mid:	tya
	and #31
	tax
	lda $6000 + W_CMAP16,x
	clc
	adc #<POOL
	sta $0002
	lda #POOLH1
	adc #0
	sta $0003
.nx:	iny
	cpy #33
	bne .c
	inc nr16
	bne .e
	inc nr16+1
.e:	rts

; the pool zeroed and the map bytes put back (idle, after leaving)
release:	lda mapw
	beq .p
	jsr mapback
.p:	lda dirty
	beq .d
	lda zi                  ; tiles zi .. zi + 15 (16 TIAs, each after its own MAWR: an interrupt between two may move it)
	asl a
	asl a
	asl a
	asl a
	clc
	adc #<(POOL * 16)
	sta t0
	lda zi
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>(POOL * 16)
	sta t1
	ldx #16
.t:	php                     ; (F4: interrupts off from the MAWR to the TIA's end; leave calls this too, in any state: PHP / PLP;
	sei                     ; the select 0 by ST0 as in upload: 3 cycles a TIA more than before)
	st0 #0
	lda t0
	sta $0002
	lda t1
	sta $0003
	vsel 2
	tia tz, $0002, 32
	plp
	lda t0
	clc
	adc #16
	sta t0
	bcc .t1
	inc t1
.t1:	dex
	bne .t
	lda zi
	clc
	adc #16
	sta zi
	cmp #NMAX
	bcc .x
.d:	stz dirty
	stz zpend
	stz zi
	lda #$FF
	sta hp
	sta hsv
.x:	rts
relall:	lda dirty               ; (leave: all at once)
	ora mapw
	beq .x
	jsr release
	bra relall
.x:	rts
tz:	.ds 32

mapback:	lda smap
	tam #4
	lda #WBANK
	tam #3
	ldx #0
.r:	txa
	clc
	adc #$90
	sta .m+2
	lda #$80
	sta .m+1
	txa
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc #<($6000 + W_CMAP)
	sta .q+1
	txa
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_CMAP)
	sta .q+2
	ldy #31
.m:	lda $FFFF,y
	dec a                   ; (the map holds class + 1)
.q:	cmp $FFFF,y
	bne .nx
	dey
	bpl .m
	txa
	clc
	adc #$90
	sta .d+4
	lda #$80
	sta .d+3
	txa
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc #<($6000 + W_SAVE)
	sta .d+1
	txa
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_SAVE)
	sta .d+2
.d:	tii $FFFF, $FFFF, 32
.nx:	inx
	cpx #16
	beq .e
	jmp .r
.e:	stz mapw
	rts

; ---------------------------------------------------------------- the setup, steps in idle time
sstep:	.if SLOWSET
	lda FRAMES
	and #7
	beq .go
	rts
.go:
	.endif
	lda ss
	asl a
	tax
	jmp [sjt - 2,x]
sjt:	.dw s_map, s_tile, s_cls, s_img, s_tab, s_mask, s_end

sfail:	inc nsetf
	stz ss
	stz setok
	rts

s_map:	lda smap
	tam #4
	lda #WBANK
	tam #3
	lda sr
	clc
	adc #$90
	sta .t+2
	stz .t+1
	lda sr
	lsr a
	ora #$60
	sta .t+4
	cla
	ror a
	sta .t+3
.t:	tii $9000, $6000, 128
	inc sr
	lda sr
	cmp #16
	bne .x
	inc ss
	stz sr
.x:	rts

s_tile:	lda #TSRC
	tam #3
	ldx #4
.t:	lda sr
	clc
	adc mlo
	sta t0
	lda mhi
	adc #0
	and #$0F
	ldy #4
.sh:	asl t0
	rol a
	dey
	bne .sh
	sta t1
	vsel 1                  ; MARR = tile * 16
	lda t0
	sta $0002
	lda t1
	sta $0003
	vsel 2
	lda sr
	asl a
	asl a
	asl a
	asl a
	asl a
	sta .d+3
	lda sr
	lsr a
	lsr a
	lsr a
	ora #$60
	sta .d+4
.d:	tai $0002, $6000, 32
	inc sr
	beq .n
	dex
	bne .t
	rts
.n:	inc ss
	stz sr
	stz sc
	lda #$FF                ; class chains empty
	ldx #0
	pha
	lda #WBANK
	tam #3
	pla
.h:	sta $6000 + W_HEAD,x
	inx
	bne .h
	stz ncls
minit:	stz mr                  ; (also the images-kept start at stage 6)
	stz mc
	stz mkon
	stz mkx
	stz tk
	stz mdone
	ldx #5
.mz:	stz mrdy,x
	dex
	bpl .mz
	rts

s_cls:	lda #WBANK
	tam #3
	lda sr                  ; u row, l row
	beq .u0
	dec a
.u0:	sta t0
	lda sr
	cmp #16
	bcc .l0
	lda #15
.l0:	sta t1
	ldx #4
.c:	phx
	ldy #0                  ; the tuple: (u, l) for p = 0..3 into tup
.p:	tya                     ; p = y / 2
	lsr a
	asl a
	asl a
	asl a
	asl a
	asl a                   ; 32 p
	ora sc
	sta t2
	lda t0
	jsr mmrd
	sta tup,y
	iny
	lda t1
	jsr mmrd
	sta tup,y
	iny
	cpy #8
	bne .p
	jsr clsof               ; A = the class (carry set: over NMAX)
	bcs .f
	pha
	lda sr
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_CMAP)
	sta .cm+2
	lda sr
	asl a
	asl a
	asl a
	asl a
	asl a
	ora sc
	sta .cm+1
	pla
.cm:	sta $FFFF
	plx
	inc sc
	lda sc
	cmp #32
	beq .r
	dex
	bne .c
	rts
.r:	stz sc
	inc sr
	lda sr
	cmp #17
	bne .x
	inc ss
	stz sr
	stz sk
.x:	rts
.f:	plx
	jmp sfail
tup:	.ds 8

; A = the mid map copy's byte at row A, column t2 (32 p + c)
mmrd:	lsr a
	sta .r+2
	cla
	ror a
	ora t2
	sta .r+1
	lda .r+2
	clc
	adc #>($6000 + W_MMAP)
	sta .r+2
.r:	lda $FFFF
	rts

clsof:	ldx tup
	lda $6000 + W_HEAD,x
cl_l:	cmp #$FF
	beq cl_new
	sta t3
	jsr tupad
	ldy #7
cl_cmp:	lda tup,y
cl_ta:	cmp $FFFF,y
	bne cl_nx
	dey
	bpl cl_cmp
	lda t3
	clc
	rts
cl_nx:	ldx t3
	lda $6000 + W_NEXT,x
	bra cl_l
cl_new:	lda ncls
	cmp #NMAX
	bcs cl_full
	sta t3
	jsr tupad
	ldy #7
cl_cp:	lda tup,y
cl_tb:	sta $FFFF,y
	dey
	bpl cl_cp
	ldx tup
	lda $6000 + W_HEAD,x
	ldx t3
	sta $6000 + W_NEXT,x
	lda t3
	ldx tup
	sta $6000 + W_HEAD,x
	inc ncls
	lda t3
	clc
	rts
cl_full:	sec
	rts
; the tuple address of class t3 into the operands of .ta / .tb
tupad:	lda t3
	asl a
	asl a
	asl a
	sta cl_ta+1
	sta cl_tb+1
	lda t3
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_TUP)
	sta cl_ta+2
	sta cl_tb+2
	rts

; 4: the images of class sk at phase sr (s = 2, 4, 6 into blocks 3p, 3p + 1, 3p + 2): rows 8-s..7 of u over rows 0..7-s of l,
; each plane pair (bytes 0-15: planes 0/1 by line; 16-31: planes 2/3)
s_img:	lda #WBANK
	tam #3
	lda sk                  ; u, l of phase sr: tup bytes 2 sr, 2 sr + 1 of class sk
	sta t3
	jsr tupad
	lda sr
	asl a
	tay
	lda cl_ta+1
	sta .g+1
	lda cl_ta+2
	sta .g+2
.g:	lda $FFFF,y
	sta ua
	iny
	lda cl_ta+1
	sta .h+1
	lda cl_ta+2
	sta .h+2
.h:	lda $FFFF,y
	sta ub
	lda #TSRC
	tam #4
	lda ua
	jsr srcad
	sta ia
	stx ia+1
	lda ub
	jsr srcad
	sta ib
	stx ib+1
	lda sr                  ; block 3p .. 3p + 2
	asl a
	adc sr
	sta t0
	lda #4                  ; 2s bytes from u (s = 2: 4)
	sta t1
.k:	lda t0
	lsr a
	clc
	adc #IMG0
	tam #3
	lda sk
	asl a
	asl a
	asl a
	asl a
	asl a
	sta id
	lda sk
	lsr a
	lsr a
	lsr a
	ora #$60
	sta id+1
	lda t0
	and #1
	beq .b0
	lda id+1
	ora #$10
	sta id+1
.b0:	lda #16
	sec
	sbc t1
	sta n2                  ; 16 - 2s
	lda ia                  ; u + 16 - 2s -> dst, 2s bytes
	clc
	adc n2
	sta .c1+1
	lda ia+1
	adc #0
	sta .c1+2
	lda id
	sta .c1+3
	lda id+1
	sta .c1+4
	lda t1
	sta .c1+5
.c1:	tii $0000, $0000, 4
	lda ib                  ; l -> dst + 2s, 16 - 2s bytes
	sta .c2+1
	lda ib+1
	sta .c2+2
	lda id
	clc
	adc t1
	sta .c2+3
	lda id+1
	adc #0
	sta .c2+4
	lda n2
	sta .c2+5
.c2:	tii $0000, $0000, 4
	lda .c1+1               ; planes 2/3: everything + 16
	clc
	adc #16
	sta .c3+1
	lda .c1+2
	adc #0
	sta .c3+2
	lda .c1+3
	clc
	adc #16
	sta .c3+3
	lda .c1+4
	adc #0
	sta .c3+4
	lda t1
	sta .c3+5
.c3:	tii $0000, $0000, 4
	lda .c2+1
	clc
	adc #16
	sta .c4+1
	lda .c2+2
	adc #0
	sta .c4+2
	lda .c2+3
	clc
	adc #16
	sta .c4+3
	lda .c2+4
	adc #0
	sta .c4+4
	lda n2
	sta .c4+5
.c4:	tii $0000, $0000, 4
	inc t0
	lda t1
	clc
	adc #4
	sta t1
	cmp #16
	bcs .nx
	jmp .k
.nx:	inc sr                  ; next phase, then next class
	lda sr
	cmp #4
	bcc .x
	stz sr
	inc sk
	lda sk
	cmp ncls
	bcc .x
	inc ss
.x:	rts
ua:	.db 0
ub:	.db 0
ia:	.dw 0
ib:	.dw 0
id:	.dw 0
n2:	.db 0

srcad:	pha
	lsr a
	lsr a
	lsr a
	ora #$80
	tax
	pla
	asl a
	asl a
	asl a
	asl a
	asl a
	rts

; 6: (in idle time) the visible-class masks: camera row mr (0-47), window row mc (0-16) a step: world row mr + mc,
; columns 0-32 with no near tile (the property table's bit 7) set the bit of their class (class map row mc, column & 31); mrdy
; marks a camera row whose mask is whole (until then an upload for it takes every class)
s_mask:	lda mkon                ; the runs of a camera row whose mask is whole: 16 classes a step (each step stays under 2k cycles)
	beq .mk0
	lda #WBANK              ; (the masks at MPR3: mklist reads them there)
	tam #3
	jsr mklist
	bcc .mk1
	jmp sfail               ; (more runs than a row's 128 bytes hold)
.mk1:	lda mkon
	bne .mkx
	lda mr                  ; camera row mr whole
	lsr a
	lsr a
	lsr a
	tay
	ldx mr
	lda mrdy,y
	ora bitk,x
	sta mrdy,y
	inc mr
	lda mr
	cmp #48
	bcc .mkx
	lda #1
	sta mdone
	inc ss
.mkx:	rts
.mk0:	lda smap
	tam #6
	lda ssb4
	tam #4
	lda #WBANK
	tam #3
	lda mr
	asl a
	asl a
	asl a
	asl a
	sta .m0+1
	sta .m1+1
	sta .m2+1
	lda mr
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_MASK)
	sta .m0+2
	sta .m1+2
	sta .m2+2
	lda mc
	bne .r
	ldx #15                 ; (a new camera row: its mask empty)
	cla
.m0:	sta $FFFF,x
	dex
	bpl .m0
.r:	lda mr
	clc
	adc mc
	stz t0
	lsr a
	ror t0
	lsr a
	ror t0
	ora #$C0
	sta .nm+2
	lda t0
	sta .nm+1
	lda mc
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_CMAP)
	sta .cm+2
	lda mc
	asl a
	asl a
	asl a
	asl a
	asl a
	sta .cm+1
	cly
.c:
.nm:	lda $FFFF,y
	and #$7F
	sty t1
	tay
	lda [PROPZP],y
	ldy t1
	bit #$80
	beq .nx
	tya
	and #31
	tax
.cm:	lda $FFFF,x             ; the class k: bit k & 7 of byte k >> 3
	tax
	lsr a
	lsr a
	lsr a
	phy
	tay
.m1:	lda $FFFF,y
	ora bitk,x
.m2:	sta $FFFF,y
	ply
.nx:	iny
	cpy #33
	bne .c
	inc mc
	lda mc
	cmp #17
	bcc .x
	stz mc
	lda #1                  ; its runs next (mklist, in steps)
	sta mkon
	stz mkx
.x:	rts

mklist:	tma #4
	pha
	lda #LBANK
	tam #4
	lda mr
	lsr a
	clc
	adc #$80
	sta .wl+2
	sta .w0+2
	sta .w1+2
	sta .we+2
	sta .wz+2
	lda mr
	lsr a
	cla
	ror a
	sta .wz+1
	sta .wl+1
	sta .w0+1
	sta .we+1
	ora #1
	sta .w1+1
	lda mr
	asl a
	asl a
	asl a
	asl a
	sta .m+1
	lda mr
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_MASK)
	sta .m+2
	lda mkx
	bne .go
	lda #$FE                ; (a new row: no class taken yet, no run yet)
	sta mlk
	sta mky
.go:	lda #16
	sta mkc
	ldy mky
	ldx mkx
.k:	phx
	txa
	lsr a
	lsr a
	lsr a
	phy
	tay
.m:	lda $FFFF,y
	ply
	and bitk,x
	beq .n
	txa                     ; class k taken: the run before goes on when k = the last + 1
	dec a
	cmp mlk
	bne .nw
	lda mln                 ; (at most 4 tiles a TIA: then the next chunk goes on from it; every second chunk of a run is marked
	cmp #128                ; $80: the upload does it at once, no bounds: a group of 8 tiles between two bound checks)
	bcs .cn
	adc #32
	sta mln
.wl:	sta $FFFF,y
	bra .tk
.cn:	lda mcn
	eor #$80
	sta mcn
	bra .nr
.nw:	stz mcn
	cla
.nr:	sta t0
	iny
	iny
	cpy #124
	bcs .ov
	lda #32
	sta mln
.w0:	sta $FFFF,y
	txa
	ora t0
.w1:	sta $FFFF,y
.tk:	stx mlk
.n:	plx
	inx
	cpx ncls
	beq .end
	dec mkc
	bne .k
	stx mkx                 ; (more next step)
	sty mky
	pla
	tam #4
	clc
	rts
.end:	iny
	iny
	cla
.we:	sta $FFFF,y             ; (the end: length 0, class byte 0: no continuation mark)
	iny
.wz:	sta $FFFF,y
	stz mkon
	stz mkx
	pla
	tam #4
	clc
	rts
.ov:	plx
	stz mkon
	pla
	tam #4
	sec
	rts

; 5: the per-class tables, 16 classes a step: SRCL / SRCH (the image's offset in its block) and MAWRL / MAWRH (its pool tile's MAWR)
s_tab:	ldx tk
	lda #16
	sta mkc
.k:	txa
	asl a
	asl a
	asl a
	asl a
	asl a
	sta SRCL,x
	txa
	lsr a
	lsr a
	lsr a
	ora #$60
	sta SRCH,x
	txa                     ; MAWR = (POOL + k) * 16, the low byte's carry into the high
	asl a
	asl a
	asl a
	asl a
	clc
	adc #<(POOL * 16)
	sta MAWRL,x
	php
	txa
	lsr a
	lsr a
	lsr a
	lsr a
	plp
	adc #>(POOL * 16)
	sta MAWRH,x
	inx
	cpx ncls
	beq .e
	dec mkc
	bne .k
	stx tk
	rts
.e:	stz tk
	inc ss
	.if IKEY
	lda smap                ; (stages 1-5 whole: the images' inputs)
	sta ik0
	lda mlo
	sta ik1
	lda mhi
	sta ik2
	lda #1
	sta ikv
	.endif
	rts
tk:	.db 0
mkon:	.db 0
mkx:	.db 0
mky:	.db 0
mkc:	.db 0
mlk:	.db 0
mln:	.db 0
mcn:	.db 0

s_end:	lda smap
	tam #4
	lda #WBANK
	tam #3
	lda sr
	clc
	adc #$90
	sta .sv+2
	sta .cw+4
	lda #$80
	sta .sv+1
	sta .cw+3
	lda sr
	asl a
	asl a
	asl a
	asl a
	asl a
	sta t0
	clc
	adc #<($6000 + W_SAVE)
	sta .sv+3
	lda sr
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_SAVE)
	sta .sv+4
	lda t0
	clc
	adc #<($6000 + W_CMAP)
	sta .cw+1
	lda sr
	lsr a
	lsr a
	lsr a
	clc
	adc #>($6000 + W_CMAP)
	sta .cw+2
	lda #1
	sta mapw
.sv:	tii $FFFF, $FFFF, 32
	.if NOCMAP
	bra .nc
	.endif
.cw:	tii $FFFF, $FFFF, 32
	lda .cw+3
	sta .ic+1
	sta .ic2+1
	lda .cw+4
	sta .ic+2
	sta .ic2+2
	ldy #31
.ic:	lda $FFFF,y
	inc a
.ic2:	sta $FFFF,y
	dey
	bpl .ic
.nc:	inc sr
	lda sr
	cmp #16
	bcc .x
	stz sr
	stz ss
	lda #1
	sta setok
	stz live
	lda #$FF
	sta hp
	sta hsv
	inc nset
	lda FRAMES
	sec
	sbc tset
	sta tsetn
.x:	rts

; ---------------------------------------------------------------- an area load (the stub; the screen is dark)
modini:	.if H2TO
	lda #H2TO
	sta STUB_LASTMOD
	dec STUB_DGEN
	.endif
modent:	lda #1                  ; (no later row of a pass comes to this module)
	sta ROWGAME
	stz ok
	stz live
	stz ours
	stz rok
	stz ss
	stz setok
	stz upq
	stz r16q
	stz pcv
	stz hbk
	stz sld
	stz ikv                 ; (another module may have written the data banks)
	lda #$80                ; (shaft-join-020) the first pass after an area load gives its facts: it can be the load's own pass (a
	sta run
	ldx #9
	lda #$FF
.k:	sta key,x               ; (the key is made anew: another module may have written the data banks)
	dex
	bpl .k
	rts

hoff:	jsr restore
	lda #$11
	sta FINEOP
	lda #$D8
	sta CULLY
	tma #3
	pha
	tma #4
	pha
	lda <VDCREG
	pha
	jsr relall
	pla
	sta t3
	pla
	tam #4
	pla
	tam #3
	vsel 0
	lda OP_MAWRLO
	sta $0002
	lda OP_MAWRHI
	sta $0003
	lda t3
	sta <VDCREG
	sta $0000
	jsr modent
	stz ROWGAME
	stz zpend
	stz dirty
	stz bours
	stz bours+1
	stz gap
	stz blk
	stz dk
	stz wo
	stz sbw
	stz slw
	lda #$FF
	sta hp
	sta hsv
	sta hcy
	lda #1
	sta hbk
	lda #H2FROM
	sta STUB_PREV
	lda #H2TO
	sta STUB_CURMOD
	sec
	rts

leave:	inc nleave
	jsr restore
	lda #$11
	sta FINEOP
	lda #$D8
	sta CULLY
	tma #3
	pha
	tma #4
	pha
	lda <VDCREG
	pha
	jsr relall
	pla
	sta <VDCREG
	sta $0000
	pla
	tam #4
	pla
	tam #3
	jsr modent
	stz ROWGAME
	stz zpend
	rts

codeend:
	.if codeend > LOG
	.fail			; (the code would run into the upload log and the source tables)
	.endif
