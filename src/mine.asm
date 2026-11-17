
FRAMES     = $2241
SCENE      = $207C
LOCKB      = $2025
DARKF      = $3224      ; the ENEMY bar's countdown (1 from a room change's start until the bar's thread next runs; 4 on a hit): not a test here
WINDOW     = $36D6      ; 1 while a menu, a text box or a scripted scene is up
CAMX       = $2D0C      ; camera X (s16)
PASS       = $339F
BXRV       = $2D08
ALLOCEND   = $40B3
ROWCNT     = $6CCF
ROWGAME    = $5FFF
VDCREG     = $F7
SPLITS     = $F3
SPLITN     = $4B4B
ZPPROP     = $59
OP_NEARPTR = $6CE6      ; the compositor's operands (bank $81 at MPR3 while the renderer runs)
OP_NEARLO  = $6CF2
OP_NEARH0  = $6CF7
OP_NEARHI  = $6CF9
OP_MIDPTR  = $6D0B
OP_MIDOFF  = $6D06
OP_MIDMASK = $6D08
OP_MIDLO   = $6D11
OP_MIDHI   = $6D18
OP_MAWRLO  = $6C85
OP_MAWRHI  = $6C87
OP_STRLO   = $6C95
OP_STRHI   = $6C9E
HOOKSITE   = $6CD4      ; INC $339F (bank $81 at MPR3 while the renderer runs; at $8CD4 with bank $81 at MPR4)
GAMEBANK   = $81

ROOM       = 25         ; the pendant cave
ROOM30     = 30
ROOM18     = 18
ROOM20     = 20
MODE       = $0C
SBPAD      = 3300       ; per-pass resident sbobj cost (sbobj_pass + sbobj_slot in satbody)
RUA30      = 35637 - SBPAD
RUA18      = 35874 - SBPAD
RUB18      = 21
RUA20      = 35815 - SBPAD
RUB20      = 22
NCMAX      = 256        ; near columns at most (the near map's rows are 256 wide; room 18's right end reads column 255)
N0MAX      = 224        ; n0 at most (room 18: v 1792)
PMAX       = 128        ; pairs made (pids 1..PMAX); each holds one slot of 64 per set, shared by pairs no window shows together
SMAX       = 64         ; slots per set (the pool's stride)
SMAIN      = $F7
SLOAD      = SMAIN - 4  ; ... on the pass the room-change thread draws at its own top level: the loaded room's first picture (door, area
                        ; load, Load, Continue alike). Deeper ones are not the room's: the Load menu's as it closes ($EF), the area
                        ; load's two before the room's data are in ($E6, $E8)
POOLT      = $780       ; the pool: set 0 at $780 + pid - 1, set 1 at $7C0 + pid - 1 (pages $78-$7F)
POOLPG     = $79        ; an allocation whose end page reaches this covers a pool page
ZCHUNK     = 16         ; pool tiles zeroed per satbody after leaving
HUDW       = 1

SATPAGE    = $2215
SATN       = $2216
SAT0       = $2F9D
OCLS       = $3097      ; object slots (68): class, screen X lo / hi, screen Y lo / hi (world = screen + camera)
OXL        = $30DB
OXH        = $311F
OYL        = $3163
OYH        = $31A7
CAMOBJ     = $85
FINEX      = $2D10
FINEY      = $2D11
ZERO09     = $2D09
FINEADC    = $4CC3      ; bank $80 (MPR2): the object draw's ADC FINEX; the operand's low byte is the one changed
GLIDE      = 0
WCLASS     = $A4
NSL        = 68
NWMAX      = 8
RDEF       = 10

TBANK      = $69        ; at MPR4: FR $8000 + r * 256 (first run per near column), RS $9000 + r * 64, RE $9400 + r * 64
TMB        = $70        ; per row r at + rof[r] (r * 148; Li 0 .. 147): PIDT +$0000 (pid per Li, $FF none looks), NZT +$0A00 (the next
PIDT       = $0000      ; Li with a pair, lcol if none), MIDC +$1400 (the mid map row: Li = L + 1, L = -1 as 0)
NZT        = $0A00
MIDC       = $1400
WB0        = $71        ; WB0 + set (at MPR6): WS at $C000 + r * 512 + Li * 2 (the cell's word, lo hi): the slot word, or the blank
LBANK      = $6F        ; at MPR4: per column pair k = n0 >> 1 (n0 and n0 + 1 show the same pair per near column) a 64-byte list
                        ; at $8000 + k * 64: [0] its ranges R, then R x (first pid, count): the pairs shown, pids numbered in
                        ; column order so that they come in few runs (a gap of GAPP or fewer pids is uploaded with them)
GAPP       = 0          ; (slots of consecutive pids need not be consecutive: no gap is uploaded)
RMAX       = 31
CW0        = $73        ; own rows (rmode): bank CW0 + set * 2 + (r >> 3) holds rows r of that half, row r at + (r & 7) * 1024:
CWS        = $200       ; +0 the near words of columns 0 .. ncol - 1, +CWS this set's cell words by Li (the slot word or the blank,
                        ; from WS); the rows' lists per column pair in TMB, WB0, WB1 (lbuild, after the setup's last use of them)
TIMER      = $0C00
OP_NEAROFF = $6CE3
OP_FARPTR  = $6D2A      ; (the far map pointer, advanced 32 a row for rows 0-14 by the loop)
ELMAX      = 36
ELEST      = 16
SPROW      = $6E74
IBANK      = $6B        ; images, phase p (1..7): bank IBANK + (p - 1) >> 1 (at MPR6), at $C000 + ((p - 1) & 1) * $1000 + (pid - 1) * 32

	.include "stubsyms.inc"  ; (mkdisc) STUB_T0OK: the stub's late-pass flag; STUB_MHOOK: the stub's hook trampoline; STUB_CURMOD,
	                        ; STUB_PREV, HSCA, HSCB: the hand-off
	.include "cardmod.inc"

	.if CMBANK
MSB        = IBANK + 3  ; the set-up's tables at MPR3: prop $7000 (128), srca $7080 / srcb $70A0 (32 each), scr $70C0 (32: a sink)
prop       = $7000
srca       = $7080
srcb       = $70A0
scr        = $70C0
A19        = 19         ; room 19 (the card module's)
HB17       = 17         ; the quarry's room: the only scene this module hands the area back in
	.endif

vsel	.macro
	lda #\1
	sta <VDCREG
	sta $0000
	.endm

	.bank 0
	.org $A000

	jmp rowent              ; 0 a row (only a pass's first: rowgame is set)
	jmp satbody
	jmp modent              ; 2 modinit (an area load)
	jmp norts               ; 3 idlework
	jmp norts               ; 4 idlelate
	jmp norts               ; 5 lateup (not called: t0ok is cleared)
	jmp leave
	jmp norts               ; 7 vacate (Redmont's allocstub entry; not called for this bank)
	jmp hook

magic:	.db $5A, $A5
eng:	.db 0
eroom:	.db 0
hooked:	.db 0           ; the hook's bytes are in bank $81
pm:	.db 0
hv:	.db 0
gap:	.db 0
lastrf:	.db 0           ; FRAMES at the last first row
upl:	.db 0           ; satbody: upload this pass's set
zpend:	.db 0           ; the pool is to be zeroed (after leaving), from tile zcnt, once zwait passes have gone by
zwait:	.db 0
zcnt:	.db 0
dirty:	.db 0           ; pool tiles may be non-zero
v0l:	.db 0           ; this pass: camera + 16, near column, dn, dm, phase, set, Li of x = 0, the buffer's row 0 address
v0h:	.db 0
n0:	.db 0
dn:	.db 0
dm:	.db 0
ph:	.db 0
set:	.db 0
lbi:	.db 0
mw0l:	.db 0
mw0h:	.db 0
np0l:	.db 0           ; row 0 operands of this pass (the setup's source)
np0h:	.db 0
mp0l:	.db 0
mp0h:	.db 0
bnlo:	.db 0           ; tile bases read at the entry
bnhi:	.db 0
bmlo:	.db 0
bmhi:	.db 0
nbl:	.db 0           ; near map row 0 column 0, mid map row 0 column 0 (from the entry's operands)
nbh:	.db 0
mbl:	.db 0
mbh:	.db 0
npairs:	.db 0
fail:	.db 0           ; why the last setup failed (0 none)
neng:	.db 0           ; counters for the checks
nsetup:	.db 0
nstand:	.dw 0
ndis:	.db 0
npatch:	.dw 0
nupl:	.dw 0
maxupl:	.db 0
nlate:	.dw 0           ; uploads that saw a vblank (retried)
tset0:	.db 0
tset1:	.db 0
sv4:	.db 0
sv6:	.db 0
t0:	.db 0
t1:	.db 0
t2:	.db 0
t3:	.db 0
uf:	.db 0
row:	.db 0
k:	.db 0
nend:	.db 0
nend2:	.db 0
kk:	.db 0           ; n0 >> 1 (the Li of near column n is n - kk)
rend:	.db 0
ra:	.db 0
len:	.db 0
mwl:	.db 0
mwh:	.db 0
rowl:	.db 0
rowh:	.db 0
wrh:	.db 0
cnt:	.db 0
ucnt:	.db 0           ; tiles this upload
uk:	.db $FF, $FF    ; per set: the column pair and phase its slots hold ($FF none)
uph:	.db $FF, $FF
lp:	.dw 0           ; the column's list (lmap)
ep:	.dw 0           ; ulists: the next entry
ne:	.db 0
eb:	.ds 5           ; the entry being written
chk:	.db 0
lo:	.db 0
hi:	.db 0
nfz:	.dw 0           ; passes whose objects were drawn without the fine add (sprop)
nfm:	.dw 0
ngl:	.dw 0           ; sprite entries moved by the glide
ngm:	.dw 0
	.if GLIDE
nw:	.db 0           ; wglide: this pass's gliding slots (wsl: slot, wpx: lag in px, wxl..wyh: the entry's X and Y)
cxl:	.db 0
cxh:	.db 0
exl:	.db 0
exh:	.db 0
eyl:	.db 0
eyh:	.db 0
fadd:	.db 0
wsl:	.ds NWMAX
wpx:	.ds NWMAX
wxl:	.ds NWMAX
wxh:	.ds NWMAX
wyl:	.ds NWMAX
wyh:	.ds NWMAX
	.endif
rofl:	.db <(0 * 148), <(1 * 148), <(2 * 148), <(3 * 148), <(4 * 148), <(5 * 148), <(6 * 148), <(7 * 148)
	.db <(8 * 148), <(9 * 148), <(10 * 148), <(11 * 148), <(12 * 148), <(13 * 148), <(14 * 148), <(15 * 148)
rofh:	.db >(0 * 148), >(1 * 148), >(2 * 148), >(3 * 148), >(4 * 148), >(5 * 148), >(6 * 148), >(7 * 148)
	.db >(8 * 148), >(9 * 148), >(10 * 148), >(11 * 148), >(12 * 148), >(13 * 148), >(14 * 148), >(15 * 148)
par:
vmaxl:	.db 0
vmaxh:	.db 0
ncol:	.db 0
lcol:	.db 0
lcol1:	.db 0
n0m:	.db 0
n0m1:	.db 0
km1:	.db 0
rmd:	.db 0
rual:	.db 0
ruah:	.db 0
rub:	.db 0
NPAR       = 12
ptab:	.db <768, >768, 129, 81, 82, 96, 97, 49, 0, 0, 0, 0
	.db <768, >768, 129, 81, 82, 96, 97, 49, 1, <RUA30, >RUA30, 22
	.db <1792, >1792, 0, 145, 146, 224, 225, 113, 1, <RUA18, >RUA18, RUB18
	.db <1792, >1792, 0, 145, 146, 224, 225, 113, 1, <RUA20, >RUA20, RUB20
rids:	.db ROOM, ROOM30, ROOM18, ROOM20
poff:	.db NPAR - 1, 2 * NPAR - 1, 3 * NPAR - 1, 4 * NPAR - 1
NROOM      = 4
vlo:	.ds 128         ; per slot its VRAM address; per pid its image's offset in a phase block
vhi:	.ds 128
ilo:	.ds PMAX + 1
ihi:	.ds PMAX + 1
sstamp:	.ds 6           ; setup: FRAMES after the runs, the lists, the words, the shift tables, the images
nr:	.ds 16          ; near-absent runs per row
	.if CMBANK = 0
prop:	.ds 128         ; the near property table (a copy)
	.endif
pfirst:	.ds 256         ; pairs: per A code the first pair, per pair the next, A, B
pnext:	.ds PMAX
pa:	.ds PMAX
pb:	.ds PMAX
slotof:	.ds PMAX + 1    ; per pid its slot in either set (0..SMAX - 1), $FF none yet
kmx:	.ds PMAX + 1    ; per pid the last column pair whose list holds it (colour)
send:	.ds SMAX        ; per slot: the first column pair after its holder's last (colour)
	.if CMBANK = 0
scr:	.ds 32          ; (images: the phases a pass does not write)
srca:	.ds 32
srcb:	.ds 32
	.else
ald:	.db 0
cs1:	.db 0
cs2:	.db 0
	.endif
mark:	.ds PMAX + 1
rfail:	.db 0
ipass:	.db 0
rem:	.db 0           ; upload: pids left in the range; fp the sub-run's first
fp:	.db 0
bval:	.db 0, 0        ; per buffer (set): it holds our words for column bn0 (own rows, rmode)
bn0:	.db 0, 0
ndist:	.db 0           ; own passes whose pad clock was taken anew (tchk)
cut:	.db 0
tr0m:	.db 0
skp:	.db 0
left:	.db 0
npad:	.dw 0           ; own passes padded to tgt; nover: own passes already at or past it
nover:	.dw 0
tgt:	.ds N0MAX + 1
rmode:	.db 0
own:	.db 0
drr:	.db 0
dv4:	.db 0
dv6:	.db 0
duf:	.db 0
dk:	.db 0
nrr:	.db 0
pos:	.db 0
stop:	.db 0
endc:	.db 0
nby:	.db 0
mal:	.db 0
mah:	.db 0
nown:	.dw 0           ; passes drawn here
bk0:	.db 0
lb:	.dw 0
cnt0:	.db 0
lbk:	.db 0
ca:	.dw 0
est:	.db 0
emx:	.db 0
eup:	.db 0
eux:	.db 0
sps:	.db 0
	.if GLIDE
rc:	.ds NSL
rxl:	.ds NSL
rxh:	.ds NSL
rl:	.ds NSL
ri:	.ds NSL
rr:	.ds NSL
	.endif

rsl:	.db $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0
rsh:	.db $90, $90, $90, $90, $91, $91, $91, $91, $92, $92, $92, $92, $93, $93, $93, $93

rowent:	lda ROWCNT              ; a later row: only our own passes call here for one (ROWGAME clear)
	beq .r0
	lda own
	beq .gr
	clc
	rts
.gr:	tsx
	cpx #SLOAD
	beq .g1
	clx
.g1:	stx gap
	.if CMBANK
	stx ald
	.endif
	sec
	rts
.r0:	lda TIMER
	and #$7F
	sta tr0m
	stz own
	lda #1
	sta ROWGAME
	stz STUB_T0OK
	tsx
	stx sps
	lda FRAMES
	sta lastrf
	cpx #SLOAD
	bne .nl
	lda eng
	beq .nl
	tst #$08, LOCKB
	beq .nl
	jsr disengage
.nl:	pha                     ; (33 cycles from the stub's flag to stz pm on every pass that is not at SLOAD, engaged or not, as
	pla                     ; before mine-engage and mine-reload-reengage: tsx 2, stx 5, lda 5, sta 5, cpx 2, bne taken 4, pha 3,
	sax                     ; pla 4, sax 3 (A and X are dead here). An engaged pass in play is the same length to the cycle, so
	stz pm                  ; the pad fits and the caves' gates stand; SLOAD passes are the load's, in the black)
	stz hv
	lda SCENE
	ldx eng
	beq .rm
	cmp eroom
	bne rowout
	bra .m
.rm:	ldx #NROOM - 1
.rl:	cmp rids,x
	beq .r
	dex
	bpl .rl
	bra rowout
.r:	sta eroom
	lda poff,x
	tax
	ldy #NPAR - 1
.pl:	lda ptab,x
	sta par,y
	dex
	dey
	bpl .pl
.m:	lda <$55
	cmp #MODE
	bne rowout
	lda eng
	beq .nlk
	jmp litpass
.nlk:	lda LOCKB
	and #$08
	beq rowng
	lda sps
	cmp #SMAIN
	bcs .ml
	cmp #SLOAD
	bne rowx
	sta gap
	bra rowx
.ml:	lda gap
	beq rowx
	jsr camv
	bcs rowx
	jsr ops0
	jsr hookin
	bcs rowx
	lda #2
	sta pm
	stz gap
rowx:	lda pm
	cmp #1
	bne rowxg
	lda rmode
	beq rowxg
	jmp ownrows
rowxg:	stz bval
	stz bval+1
	sec
	rts
rowout:	stz gap                 ; (not armed: an area load's mark or a gap seen elsewhere does not carry over)
	lda eng
	beq .hb
	jsr disengage
.hb:	lda STUB_PREV
	beq rowx
	.if CMBANK
	lda SCENE
	cmp #A19
	beq rowarm
	stz ald
	ldx zpend
	bne rowx
	.if H2TO                ; (final-020-merge: with the shaft's hand-off too: kept in 18-25 (block 24 but 17, and 25) and 30, the
	sbc #A19 - 2
	cmp #26 - (A19 - 2)
	bcc rowx                ; 9-12, 30 -> 13, 31-33 -> 14-16. 6 bytes more than cmp #HB17 / bne rowx)
	cmp #30 - (A19 - 2)
	beq rowx
	.else
	cmp #HB17
	bne rowx
	.endif
	.else
	lda zpend
	bne rowx
	lda SCENE
	.if H2TO
	ldx #NROOM - 1
.hl:	cmp rids,x
	beq rowx
	dex
	bpl .hl
	.else
	cmp #HSCA
	beq rowx
	cmp #HSCB
	beq rowx
	.endif
	.endif
	lda STUB_PREV
	sta STUB_CURMOD
	stz STUB_PREV
	bra rowx
rowng:	stz gap
	bra rowx
rowbx:	bra rowx
	.if CMBANK
rowarm:	bbr3 <LOCKB, .alt
	lda sps
	cmp #SLOAD
	bne .al
	sta ald
.al:	lda zpend
	bne rowx
	lda ald
	beq rowx
	stz ald                 ; (answered once)
	lda $1AFF
	cmp #$51
	bne rowx
	jsr cpy0                ; (Z set: the first bank is in and checked)
	bne rowx
	lda #CMBANK
	sta STUB_CURMOD
	ldx #SLOAD              ; (X: the load seen)
	stx gap
	lda #6                  ; the module's entry 2
	jsr STUB_MCALL
	bcs .abk
	cla                     ; its entry 0: this pass's first row, its carry this row's
	jmp STUB_MCALL
.abk:	lda #SELF
	sta STUB_CURMOD
	bra rowbx
.alt:	stz ald
	bra rowbx
	.endif

	.if CMBANK
SELF       = $7E        ; this module's bank (src/modules.json "mine" bank)
; (arm) the first bank from the card into CMBANK (MPR4), then its check against CMSUM0 (the card is there). Z set: right. MPR4 kept.
cpy0:	tma #4
	pha
	lda #CMBANK
	tam #4
	stz $1A02               ; port 0's base CMADDR:0000 (increment 1, control $11: as the preload and the module set them; if not,
	stz $1A03               ; the check fails and the arm declines)
	.if CMADDR
	lda #CMADDR
	sta $1A04
	.else
	stz $1A04
	.endif
	stz .t+3
	lda #$80
	sta .t+4
	ldx #32
.t:	tai $1A00, $8000, 32
	lda .t+3
	clc
	adc #32
	sta .t+3
	bcc .t
	inc .t+4
	dex
	bne .t
	stz cs1                 ; the check (mkdisc card_sum): eight groups of four pages, carry going round, folded into two sums
	stz cs2
	lda #$80
.g:	sta .a+2
	inc a
	sta .b+2
	inc a
	sta .c+2
	inc a
	sta .d+2
	cla
	clc
	cly
.s:
.a:	adc $8000,y
.b:	adc $8100,y
.c:	adc $8200,y
.d:	adc $8300,y
	iny
	bne .s
	adc cs1
	sta cs1
	clc
	adc cs2
	sta cs2
	lda .d+2
	inc a
	cmp #$A0
	bne .g
	pla
	tam #4
	lda cs1                 ; Z set: both sums as built
	cmp #LOW(CMSUM0)
	bne .f
	lda cs2
	cmp #HIGH(CMSUM0)
.f:	rts
	.endif

ownrows:	lda #1
	sta own
	stz ROWGAME
	ldx set
	lda bval,x
	beq .dr
	lda bn0,x
	cmp n0
	beq .sk
.dr:	lda n0
	sta bn0,x
	lda #1
	sta bval,x
	inc nown
	bne .o
	inc nown+1
.o:	jsr drow
	jsr elap
	sta est
	cmp emx
	bcc .sk
	sta emx
.sk:	lda SPROW               ; the loop's other 15 rows have nothing to do (rows drawn; the row helper's three special rows
	and SPROW + 4           ; are none, $FF): the loop ends after this row (its counter to 15); the hook gives the operands the
	and SPROW + 8           ; values the 16 iterations leave (cut)
	cmp #$FF
	bne .k
	lda #15
	sta ROWCNT
	inc cut
.k:	clc
	rts

litpass:	lda WINDOW
	bne .st
	jsr allocchk
	bcs .st
	jsr camv
	bcc .go
.st:	stz pm
	stz hv
	inc nstand
	bne .sx
	inc nstand+1
.sx:	jmp rowxg
.go:
	lda v0l                 ; n0 = v >> 3, dn, dm
	and #7
	sta dn
	lda v0h
	sta t0
	lda v0l
	lsr t0
	ror a
	sta t1                  ; v >> 1 (v < 1024)
	and #7
	sta dm
	lsr t0
	lda t1
	ror a                   ; v >> 2
	lsr t0
	ror a
	sta n0                  ; v >> 3 (v < 2048)
	clc
	adc nbl
	cmp OP_NEARPTR
	bne .st
	lda n0
	inc a
	lsr a                   ; Li of x = 0: L + 1 = (n0 + 1) >> 1
	sta lbi
	lda #8
	clc
	adc dm
	sec
	sbc dn
	sta ph
	lda n0
	lsr a
	bcc .ev
	lda ph
	sec
	sbc #8
	sta ph
.ev:	lda OP_MAWRLO
	sta mw0l
	lda OP_MAWRHI
	sta mw0h
	cmp #4
	cla
	rol a
	sta set
	lda dn
	sta hv
	ldx #3
	lda ph
	beq .sp
	cmp #8
	beq .sp
	ldx #1
.sp:	stx pm
	jmp rowx

norts:	rts

; v = camera + 16 (v0l/v0h), carry set when outside 0 .. VMAX
camv:	lda CAMX
	clc
	adc #16
	sta v0l
	lda CAMX+1
	adc #0
	sta v0h
	bmi .no
	lda vmaxl               ; (v <= vmax)
	cmp v0l
	lda vmaxh
	sbc v0h
	bcc .no
	clc
	rts
.no:	sec
	rts

; the row 0 operands this pass's setup reads
ops0:	lda OP_NEARPTR
	sta np0l
	lda OP_NEARPTR+1
	sta np0h
	lda OP_MIDPTR
	sta mp0l
	lda OP_MIDPTR+1
	sta mp0h
	lda OP_MAWRLO
	sta mw0l
	lda OP_MAWRHI
	sta mw0h
	rts

allocchk:	ldx #0
.l:	lda ALLOCEND,x
	beq .ok
	cmp #POOLPG
	bcs .no
	inx
	cpx #48
	bne .l
.ok:	clc
	rts
.no:	sec
	rts

; ---------------------------------------------------------------- the hook (bank $81 at MPR3: the renderer's)
hookin:	lda HOOKSITE
	cmp #$20
	bne .g
	lda HOOKSITE+1
	cmp #<STUB_MHOOK
	bne .no
	lda HOOKSITE+2
	cmp #>STUB_MHOOK
	bne .no
	bra .ok
.g:	cmp #$EE
	bne .no
	lda HOOKSITE+1
	cmp #<PASS
	bne .no
	lda HOOKSITE+2
	cmp #>PASS
	bne .no
	lda #<STUB_MHOOK        ; (the low and high bytes first: the opcode last, the instruction is never half written)
	sta HOOKSITE+1
	lda #>STUB_MHOOK
	sta HOOKSITE+2
	lda #$20
	sta HOOKSITE
.ok:	lda #1
	sta hooked
	clc
	rts
.no:	lda #1
	sta fail
	sec
	rts

; Remove: only the bytes this module wrote are put back, whatever hooked says (hookout: bank $81 at MPR3; hookout4: mapped at MPR4)
hookout:	stz hooked
	lda HOOKSITE            ; (MPR3)
	cmp #$20
	bne .x
	lda HOOKSITE+1
	cmp #<STUB_MHOOK
	bne .x
	lda HOOKSITE+2
	cmp #>STUB_MHOOK
	bne .x
	lda #$EE
	sta HOOKSITE
	lda #<PASS
	sta HOOKSITE+1
	lda #>PASS
	sta HOOKSITE+2
.x:	rts
hookout4:	stz hooked
	tma #4
	pha
	lda #GAMEBANK
	tam #4
	lda HOOKSITE + $2000
	cmp #$20
	bne .r
	lda HOOKSITE + $2001
	cmp #<STUB_MHOOK
	bne .r
	lda HOOKSITE + $2002
	cmp #>STUB_MHOOK
	bne .r
	lda #$EE
	sta HOOKSITE + $2000
	lda #<PASS
	sta HOOKSITE + $2001
	lda #>PASS
	sta HOOKSITE + $2002
.r:	pla
	tam #4
	rts

hook:	phy
	lda pm
	cmp #1
	bne .s
	lda own
	bne .ow
	lda #1                  ; (satbody patches the words and uploads the images)
	sta upl
	bra .l
.ow:	jsr uncut
	jsr tchk
	jsr upload
	jsr elap                ; (for the checks: steps to the upload's end, last and most)
	sta eup
	cmp eux
	bcc .ue
	sta eux
.ue:	ldx n0
	lda tgt,x
	sta t1
	lda FRAMES
	sta t2
	ldx #0
.pd:	lda FRAMES
	cmp t2
	bne .pz
	lda TIMER
	and #$7F
	sta t0
	lda tr0m
	sec
	sbc t0
	bcs .pe
	adc #116
.pe:	cmp t1
	bcs .pz
	inx
	bra .pd
.pz:	txa                     ; (passes padded / come out at or over the target: for the checks)
	beq .po
	inc npad
	bne .l
	inc npad+1
	bra .l
.po:	inc nover
	bne .l
	inc nover+1
	bra .l
.s:	cmp #2
	bne .l
	jsr setup
	stz hv
.l:	php
	sei
	inc PASS
	lda hv
	sta BXRV
	plp
	jsr sprop               ; (the sprite table of this pass comes next)
	ply
	rts

elap:	lda TIMER
	and #$7F
	sta t0
	lda tr0m
	sec
	sbc t0
	bcs .e
	adc #116
.e:	rts

tchk:	lda TIMER
	and #$7F
	sta t0
	lda tr0m
	sec
	sbc t0
	bcs .e
	adc #116
.e:	cmp #ELMAX
	bcc .x
	lda t0
	clc
	adc #ELEST
	cmp #116
	bcc .s
	sbc #116
.s:	sta tr0m
	inc ndist
.x:	rts

uncut:	lda cut
	beq .x
	stz cut
	lda OP_NEARPTR+1
	clc
	adc #15
	sta OP_NEARPTR+1
	lda OP_MAWRLO
	clc
	adc #$C0
	sta OP_MAWRLO
	lda OP_MAWRHI
	adc #3
	sta OP_MAWRHI
	lda OP_MIDPTR+1
	clc
	adc #15
	sta OP_MIDPTR+1
	lda OP_FARPTR
	clc
	adc #$E0
	sta OP_FARPTR
	lda OP_FARPTR+1
	adc #1
	sta OP_FARPTR+1
.x:	rts

drow:	tma #6
	sta dv6
	tma #4
	sta dv4
	lda n0
	lsr a
	tax
	lda pnext,x             ; this column pair's lists (lbuild): bank, address
	tam #4
	lda pfirst,x
	sta lb
	lda pfirst + 128,x
	sta lb+1
	lda mw0l
	sta mal
	lda mw0h
	sta mah
	lda set
	asl a
	adc #CW0
	sta bk0                 ; rows 0-7's bank, rows 8-15's the next
	stz drr
.row:	ldx drr
	txa
	and #7
	bne .ag
	txa
	lsr a
	lsr a
	lsr a
	adc bk0
	tam #6
.ag:	lda lb                  ; the row's list: [count], count x (source lo, hi, bytes)
	sta .cn+1
	sta .el+1
	sta .eh+1
	sta .eb+1
	lda lb+1
	sta .cn+2
	sta .el+2
	sta .eh+2
	sta .eb+2
	lda FRAMES
	sta duf
	vsel 0
	lda mal
	sta $0002
	lda mah
	sta $0003
	vsel 2
.cn:	lda $8000
	sta cnt
	sta cnt0
	beq .rd                 ; (no entry: never made, a row has its 33 cells)
	ldy #1
	lda n0                  ; n0 odd: the list's first cell is left out; even: its last
	lsr a
	bcc .ev
	jsr .ld
	sec
	sbc #2
	beq .o2                 ; (a one-cell entry: nothing)
	pha
	lda .t+1
	clc
	adc #2
	sta .t+1
	bcc .o1
	inc .t+2
.o1:	pla
	jsr .tx
.o2:	dec cnt
	bra .ml
.ev:	dec cnt                 ; (the last one apart)
.ml:	lda cnt
	beq .tl
.mp:	jsr .ld
	jsr .tx
	dec cnt
	bne .mp
.tl:	lda n0
	lsr a
	bcs .rd
	jsr .ld
	sec
	sbc #2
	beq .rd
	jsr .tx
.rd:	lda FRAMES
	cmp duf
	beq .rn
	jmp .ag                 ; (a vblank went by: the row again)
.rn:	lda cnt0                ; the next row's list: past this one's count and its entries
	asl a
	sec
	adc cnt0
	clc
	adc lb
	sta lb
	bcc .r1
	inc lb+1
.r1:	lda mal
	clc
	adc #64
	sta mal
	bcc .h
	inc mah
.h:	inc drr
	lda drr
	cmp #16
	beq .x
	jmp .row
.x:	lda dv4
	tam #4
	lda dv6
	tam #6
	rts
.ld:
.el:	lda $8000,y             ; the next entry: its source into .t, A its bytes
	sta .t+1
	iny
.eh:	lda $8000,y
	sta .t+2
	iny
.eb:	lda $8000,y
	iny
	rts
.tx:	cmp #33                 ; A bytes (2 .. 68) from .t's source: TIAs of 16 words at most
	bcs .bg
	sta .t+5
.t:	tia $C000, $0002, 32
	rts
.bg:	sbc #32
	pha
	lda #32
	sta .t+5
	jsr .t
	lda .t+1
	clc
	adc #32
	sta .t+1
	bcc .b1
	inc .t+2
.b1:	pla
	bra .tx
; ---------------------------------------------------------------- the objects' fine add (bank $80 at MPR2, always)
sprop:	lda FINEADC
	cmp #$6D
	bne .x
	lda FINEADC+2
	cmp #>FINEX
	bne .x
	lda pm
	cmp #1
	beq .s
	cmp #3
	bne .g
.s:	lda FINEX
	cmp hv
	bne .m
	lda ZERO09
	bne .m
	lda #<ZERO09
	sta FINEADC+1
	inc nfz
	bne .x
	inc nfz+1
	rts
.m:	inc nfm
	bne .g
	inc nfm+1
.g:	lda #<FINEX
	sta FINEADC+1
.x:	rts
sprest:	lda FINEADC
	cmp #$6D
	bne .x
	lda FINEADC+2
	cmp #>FINEX
	bne .x
	lda #<FINEX
	sta FINEADC+1
.x:	rts

; ---------------------------------------------------------------- the patch: the mid cells' words of the hidden buffer
; Per row, the near-absent runs that meet columns n0 .. n0 + 32; each run's words are one slice of the row's word table (the
; pair at Li = lbi + x), one TIA per 16 words, MAWR set before each (a vblank in between: again).
patch:	tma #4
	sta sv4
	tma #6
	sta sv6
	lda #TBANK
	tam #4
	lda set
	clc
	adc #WB0
	tam #6
	inc npatch
	bne .c
	inc npatch+1
.c:	lda n0
	sta .fr+1
	lsr a
	sta kk                  ; Li of near column n = n - (n0 >> 1)
	lda n0
	clc
	adc #32
	sta nend                ; the window's last column
	lda mw0l
	sta rowl
	lda mw0h
	sta rowh
	lda #$C0
	sta wrh
	stz row
.rl:	ldx row
	lda nr,x
	bne .g
	jmp .nx
.g:	sta cnt
	txa
	ora #$80
	sta .fr+2
	lda rsl,x
	sta .rs+1
	sta .re+1
	lda rsh,x
	sta .rs+2
	ora #4
	sta .re+2
.fr:	ldy $8000
.k:	cpy cnt
	bcc .k1
	jmp .nx
.k1:
.rs:	lda $9000,y             ; (a run from past the window's last column: the row is done)
	cmp nend
	beq .k2
	bcc .k2
	jmp .nx
.k2:	cmp n0
	bcs .a
	lda n0
.a:	sta ra
.re:	lda $9400,y             ; (its last column, inclusive)
	cmp nend
	bcc .b
	lda nend
.b:	sec
	sbc ra
	inc a
	asl a
	sta len                 ; bytes
	lda ra
	sec
	sbc n0
	clc
	adc rowl
	sta mwl
	lda rowh
	adc #0
	sta mwh
	lda ra
	sec
	sbc kk
	asl a
	sta .t+1                ; the word table: Li * 2 (up to 290)
	lda wrh
	adc #0
	sta .t+2
	sty k
.go:	lda len
	cmp #33
	bcc .one
	lda #32
.one:	sta .t+5
.r:	lda FRAMES
	sta uf
	vsel 0
	lda mwl
	sta $0002
	lda mwh
	sta $0003
	vsel 2
.t:	tia $C000, $0002, 32
	lda FRAMES
	cmp uf
	beq .ok
	inc nlate
	bne .r
	inc nlate+1
	bra .r
.ok:	lda len
	sec
	sbc .t+5
	beq .d
	sta len                 ; (a run of more than 16 words: the next TIA 16 words on)
	lda .t+1
	clc
	adc #32
	sta .t+1
	bcc .t2
	inc .t+2
.t2:	lda mwl
	clc
	adc #16
	sta mwl
	bcc .go
	inc mwh
	bra .go
.d:	ldy k
	iny
	jmp .k
.nx:	lda rowl                ; next row: + 64 words, the next word-table row (512 bytes)
	clc
	adc #64
	sta rowl
	bcc .h
	inc rowh
.h:	inc wrh
	inc wrh
	inc row
	lda row
	cmp #16
	beq .e
	jmp .rl
.e:	lda sv4
	tam #4
	lda sv6
	tam #6
	rts

lmap:	lsr a
	pha
	lsr a
	lsr a
	clc
	adc #$80
	sta lp+1
	pla
	and #3
	lsr a
	ror a
	ror a
	sta lp
	lda #LBANK
	tam #4
	rts

	.if GLIDE
; ---------------------------------------------------------------- the slimes' glide (satbody: interrupts off on entry and exit)
wglide:	cli
	lda CAMX
	sta cxl
	lda CAMX+1
	sta cxh
	stz nw
	stz fadd
	lda FINEADC+1
	cmp #<ZERO09
	beq .f
	lda FINEX
	sta fadd
.f:	ldx #NSL - 1
.k:	cpx <CAMOBJ
	bne .k1
	jmp .nk
.k1:	lda OCLS,x
	cmp #WCLASS
	beq .w
	stz rc,x
	jmp .nk
.w:	lda OXL,x               ; world X
	clc
	adc cxl
	sta t0
	lda OXH,x
	adc cxh
	sta t1
	lda rc,x
	bne .old
	lda #1                  ; new: no lag, no interval yet
	sta rc,x
	stz rl,x
	lda #$FF
	sta ri,x
	lda #RDEF
	sta rr,x
	bra .st
.old:	lda t0                  ; its move since the last pass
	sec
	sbc rxl,x
	sta t2
	lda t1
	sbc rxh,x
	beq .pos
	cmp #$FF
	bne .jmp
	lda t2
	cmp #$F8
	beq .hm
	bra .jmp
.pos:	lda t2
	beq .st
	cmp #8
	beq .hp
.jmp:	stz rl,x
	bra .st
.hp:	jsr irate
	lda rl,x
	clc
	adc #$7F
	bvc .sl
	lda #$7F
	bra .sl
.hm:	jsr irate
	lda rl,x
	sec
	sbc #$7F
	bvc .sl
	lda #$81
.sl:	sta rl,x
.st:	lda t0
	sta rxl,x
	lda t1
	sta rxh,x
	lda ri,x
	cmp #$FF
	beq .lg
	inc ri,x
.lg:	jsr nlag
	ldy pm                  ; drawn moved only on a pass this module scrolls
	cpy #1
	beq .on
	cpy #3
	beq .on
	stz rl,x
	jmp .nk
.on:	ora #0                  ; whole px, toward 0 (at most 7 either way; the flags are the CPY's here)
	bpl .op
	eor #$FF
	inc a
	lsr a
	lsr a
	lsr a
	lsr a
	eor #$FF
	inc a
	bra .px
.op:	lsr a
	lsr a
	lsr a
	lsr a
.px:	ora #0
	bne .on1
	jmp .nk
.on1:	ldy nw
	cpy #NWMAX
	bcc .on2
	jmp .nk
.on2:	sta wpx,y
	lda OXL,x
	clc
	adc #$30
	sta t2
	lda OXH,x
	adc #0
	sta t3
	lda t2
	clc
	adc fadd
	sta t2
	lda t3
	adc #0
	beq .xo
	cmp #1
	bne .nk
	lda t2
	cmp #$60
	bcs .nk
	lda #1
.xo:	sta wxh,y
	lda t2
	sta wxl,y
	lda OYL,x
	clc
	adc #$58
	sta t2
	lda OYH,x
	adc #0
	sta t3
	lda t2
	clc
	adc FINEY
	sta wyl,y
	lda t3
	adc #0
	bne .nk
	lda wyl,y
	cmp #$D8
	bcs .nk
	lda #0
	sta wyh,y
	txa
	sta wsl,y
	inc nw
.nk:	dex
	bmi .e
	jmp .k
.e:	lda nw
	bne .tab
	sei
	rts
.tab:	ldy SAT0
.en:	cpy SATN
	bcc .e1
	jmp .done
.e1:	tya
	asl a
	asl a
	sta t2                  ; the entry's first word (Y; X at + 1)
	sei
	vsel 1
	lda t2
	sta $0002
	lda SATPAGE
	sta $0003
	vsel 2
	lda $0002
	sta eyl
	lda $0003
	and #3
	sta eyh
	vsel 1
	lda t2
	ora #1
	sta $0002
	lda SATPAGE
	sta $0003
	vsel 2
	lda $0002
	sta exl
	lda $0003
	and #3
	sta exh
	cli
	ldx nw
.c:	dex
	bpl .c1
	jmp .ne
.c1:	lda wsl,x
	bmi .c                  ; (moved already)
	lda wxl,x
	cmp exl
	bne .c
	lda wxh,x
	cmp exh
	bne .c
	lda wyl,x
	cmp eyl
	bne .c
	lda wyh,x
	cmp eyh
	bne .c
	lda wsl,x
	ora #$80
	sta wsl,x
	lda exl
	sec
	sbc wpx,x
	sta exl
	lda wpx,x
	bmi .ng
	lda exh
	sbc #0
	bra .h
.ng:	lda exh
	sbc #$FF
.h:	bmi .ne
	sta exh
	sei
	vsel 0
	lda t2
	ora #1
	sta $0002
	lda SATPAGE
	sta $0003
	vsel 2
	lda exl
	sta $0002
	lda exh
	sta $0003
	cli
	inc ngl
	bne .ne
	inc ngl+1
.ne:	iny
	jmp .en
.done:	ldx nw                  ; on screen but not found
.u:	dex
	bmi .r
	lda wsl,x
	bmi .u
	inc ngm
	bne .u
	inc ngm+1
	bra .u
.r:	sei
	rts

; slot X's lag a rate nearer 0: A = the lag
nlag:	lda rl,x
	beq .z
	bmi .up
	sec
	sbc rr,x
	bcs .sv
	cla
	bra .sv
.up:	clc
	adc rr,x
	bcc .sv
	cla
.sv:	sta rl,x
.z:	rts

irate:	lda ri,x
	stz ri,x
	cmp #5
	bcc .fast
	cmp #17
	bcs .keep
	tay
	lda rtab-5,y
	sta rr,x
.keep:	rts
.fast:	lda #32
	sta rr,x
	rts
rtab:	.db 26, 22, 19, 16, 15, 13, 12, 11, 10, 10, 9, 8   ; 5 .. 16 passes
	.endif

; The hidden set's images: the pairs this column shows (ULP[n0]) whose slot does not hold phase ph yet, one 32-byte TIA each,
; interrupts on between them (a vblank in between: that tile again). After leaving: ZCHUNK pool tiles zeroed a call.
satbody:
	.if GLIDE
	lda eng                 ; (engaged only: elsewhere in block 26 nothing runs)
	beq .ng
	jsr wglide              ; (the table is written; the fine add's operand still as this pass had it)
.ng:
	.endif
	jsr sprest              ; the draw's own operand back
	lda upl
	bne .u
	lda zpend
	beq .x
	lda zwait
	beq .z
	dec zwait
.x:	rts
.z:	jmp zchunk
.u:	stz upl
	cli
	pha
	.if HUDW
	lda FRAMES
	cmp lastrf
	bne .hd
.hw:	bbr6 <SPLITS, .hd
	lda FRAMES
	cmp lastrf
	beq .hw
.hd:
	.endif
	pla
	cmp #2
	beq .up
	jsr patch               ; the words of the hidden buffer (interrupts on)
.up:	jsr upload              ; the images of its set
	sei
	rts

upload:	ldx set
	lda n0
	lsr a
	cmp uk,x
	bne .go
	lda ph
	cmp uph,x
	bne .go
	rts
.go:	lda n0
	lsr a
	sta uk,x
	lda ph
	sta uph,x
	tma #4
	sta sv4
	tma #6
	sta sv6
	lda #1
	sta dirty
	lda n0
	jsr lmap
	lda lp
	sta .r0+1
	inc a
	sta .r1+1
	inc a
	sta .r2+1
	lda lp+1
	sta .r0+2
	sta .r1+2
	sta .r2+2
	lda ph                  ; the phase's image bank and its block's page
	dec a
	lsr a
	php
	clc
	adc #IBANK
	tam #6
	cla
	plp
	bcc .b0
	lda #$10
.b0:	clc
	adc #$C0
	sta t1
	lda set
	lsr a
	ror a
	ror a
	sta t2                  ; set * 64
	stz ucnt
.r0:	lda $8000               ; ranges
	sta cnt
	bne .rg
	jmp .done
.rg:	clx
.rl:
.r1:	ldy $8001,x             ; the first pid
.r2:	lda $8002,x             ; the count
	sta rem
	clc
	adc ucnt
	sta ucnt
.sr:	lda kmx,y               ; a sub-run from pid Y: the pids whose slots follow on (kmx: their number, colour)
	cmp rem
	bcc .sl
	lda rem
.sl:	sta len
.sg:	sty fp
	lda ilo,y               ; its image
	sta .t+1
	lda ihi,y
	clc
	adc t1
	sta .t+2
	lda slotof,y
	clc
	adc t2
	tay                     ; its slot
	lda len                 ; bytes
	asl a
	asl a
	asl a
	asl a
	asl a
	sta mwl                 ; (count * 32: at most 64 tiles, kept in two bytes)
	lda len
	lsr a
	lsr a
	lsr a
	sta mwh
	php
	sei
	st0 #0
	lda vlo,y
	sta $0002
	lda vhi,y
	sta $0003
	st0 #2
	lda #2
	sta <VDCREG
	plp
.tl:	lda #32
	ldy SPLITN
	cpy #2
	bne .ck                 ; held its BYR write 1-2 lines late: the whole playfield 1-2 px off for that frame (R19-after-visit-jumps)
	lda #128
.ck:	sta chk
	lda mwh                 ; the next TIA: chk bytes or what is left
	bne .full
	lda mwl
	cmp chk
	bcc .part
.full:	lda chk
.part:	sta .t+5
.t:	tia $C000, $0002, 32
	lda mwl
	sec
	sbc .t+5
	sta mwl
	bcs .nb
	dec mwh
.nb:	ora mwh
	beq .nr
	lda .t+1
	clc
	adc .t+5
	sta .t+1
	bcc .tl
	inc .t+2
	bra .tl
.nr:	lda rem                 ; the range's next sub-run
	sec
	sbc len
	beq .nx
	sta rem
	lda fp
	clc
	adc len
	tay
	jmp .sr
.nx:	inx
	inx
	dec cnt
	beq .done
	jmp .rl
.done:	lda ucnt
	clc
	adc nupl
	sta nupl
	bcc .c
	inc nupl+1
.c:	lda ucnt
	cmp maxupl
	bcc .m
	sta maxupl
.m:	lda sv4
	tam #4
	lda sv6
	tam #6
	rts

; ZCHUNK pool tiles to zero, from zcnt (interrupts on between them); the last one ends the leaving
zchunk:	lda #ZCHUNK
	sta t3
	cli
.l:	ldx zcnt
	jsr zslot
	inc zcnt
	lda zcnt
	cmp #128
	beq .e
	dec t3
	bne .l
	sei
	rts
.e:	stz zpend
	stz zcnt
	stz dirty
	lda #$FF
	sta uk
	sta uk+1
	sei
	rts

zslot:	txa
	asl a
	asl a
	asl a
	asl a
	sta mwl
	txa
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>(POOLT * 16)
	sta mwh
.r:	lda FRAMES
	sta uf
	vsel 0
	lda mwl
	sta $0002
	lda mwh
	sta $0003
	vsel 2
	ldy #16
.z:	st1 #0
	st2 #0
	dey
	bne .z
	lda FRAMES
	cmp uf
	bne .r
	rts

disengage:	stz eng
	jsr hookout
	jsr sprest
	stz BXRV
	stz hv
	stz pm
	stz upl
	inc ndis
	lda dirty
	beq .x
	lda #1
	sta zpend
	lda #2
	sta zwait
	stz zcnt
.x:	rts

; ---------------------------------------------------------------- an area load (the stub; the screen is dark)
modent:	stz gap
	stz own
mclr:	stz eng
	stz pm
	stz hv
	stz upl
	rts

leave:	jsr sprest
	lda hooked
	ora eng
	beq .p
	stz BXRV
.p:	jsr hookout4            ; (the bytes are checked whatever the flags say)
	jsr mclr
	stz ROWGAME
	lda dirty
	ora zpend
	beq .x
	php
	sei
	clx
.z:	phx
	jsr zslot
	plx
	inx
	bpl .z
	plp
	stz dirty
	stz zpend
	stz zcnt
	lda #$FF
	sta uk
	sta uk+1
.x:	rts

; Blocking, interrupts on, in the black: the bases, the maps' runs, the pairs, the word tables, the lists per column, the
; images, the pool zeroed. MPR6 is the field bank (the maps) on entry and is given back.
setup:	lda FRAMES
	sta tset0
	stz fail
	tma #4
	sta sv4
	tma #6
	sta sv6
	lda OP_MIDOFF           ; the layout this module knows: mid column = x + its map pointer, row strides 256
	bne .f2
	lda OP_MIDMASK
	cmp #$FF
	bne .f2
	lda OP_STRLO
	bne .f2
	lda OP_STRHI
	cmp #1
	beq .ok
.f2:	lda #2
	jmp sfail
.ok:	lda OP_MIDLO            ; the mid word: value + bmlo, $10-page + bmhi (+ carry)
	sta bmlo
	lda OP_MIDHI
	clc
	adc OP_MIDLO + 5
	sta bmhi
	lda OP_NEARLO
	sta bnlo
	lda OP_NEARH0
	clc
	adc OP_NEARHI
	sta bnhi
	lda v0l                 ; n0 = v >> 3, m0 = v >> 4 of this pass
	sta t0
	lda v0h
	lsr a
	ror t0
	lsr a
	ror t0
	lsr a
	ror t0
	lda np0l                ; the near map's row 0 column 0 = its row 0 pointer - n0
	sec
	sbc t0
	sta nbl
	lda np0h
	sbc #0
	sta nbh
	lsr t0
	lda mp0l                ; the mid map's: its row 0 pointer - m0
	sec
	sbc t0
	sta mbl
	lda mp0h
	sbc #0
	sta mbh
	lda nbh                 ; both maps in the field bank's window: 15 rows of 256 and the columns read after row 0's
	cmp #$C0
	bcc .f3
	cmp #$D0
	bcc .mm
	bne .f3
	lda ncol                ; (row 15 on page $DF: nbl + ncol <= 255; ncol 256 (0): nbl 0)
	beq .n0
	clc
	adc nbl
	bcs .f3
	bra .mm
.n0:	lda nbl
	bne .f3
.mm:	lda mbh
	cmp #$C0
	bcc .f3
	cmp #$D0
	bcc .p
	bne .f3
	lda mbl                 ; (mbl + lcol + 1 <= 255)
	sec
	adc lcol
	bcc .p
.f3:	lda #3
	jmp sfail
.p:
	.if CMBANK
	tma #3                  ; (the set-up's tables at MPR3 until nruns is done; the renderer's bank back before anything names it)
	pha
	lda #MSB
	tam #3
	.endif
	lda <ZPPROP             ; the property table, through the renderer's mapping
	sta .pp+1
	lda <ZPPROP+1
	sta .pp+2
	ldy #127
.pp:	lda $FFFF,y
	sta prop,y
	dey
	bpl .pp
	lda bmlo
	ldy bmhi
	clx
	jsr rdtile
	ldx #31
	.if CMBANK
.bz:	lda srca,x
	bne .z4
	dex
	bpl .bz
	jsr nruns
	pla                     ; (the renderer's bank at MPR3 again; carry kept)
	tam #3
	bcs .f5
	.else
.bz:	lda srca,x
	beq .bk
	jmp .f4
.bk:	dex
	bpl .bz
	jsr nruns
	bcs .f5
	.endif
	lda FRAMES              ; (the checks read the steps' vblank stamps)
	sta sstamp
	jsr midcopy
	jsr vispid
	bcs .f6
	lda FRAMES
	sta sstamp+5
	jsr nzmake
	jsr ulists
	bcs .f6
	jsr colour
	bcs .f7
	lda FRAMES
	sta sstamp+1
	jsr words
	jsr rmake
	lda FRAMES
	sta sstamp+2
	jsr atabs
	lda FRAMES
	sta sstamp+3
	jsr images
	lda FRAMES
	sta sstamp+4
	clx                     ; the pool zeroed, no image in any slot (interrupts on: zslot does a slot again after a vblank; masked,
.z:	phx
	jsr zslot
	plx
	inx
	bpl .z
	lda #$FF                ; no set holds any image
	sta uk
	sta uk+1
	stz dirty
	stz zpend
	.if GLIDE
	ldx #NSL - 1
.rc:	stz rc,x
	dex
	bpl .rc
	.endif
	lda #1
	sta eng
	inc neng
	inc nsetup
	lda FRAMES
	sta tset1
	bra sret
	.if CMBANK
.z4:	pla
	tam #3
	.endif
.f4:	lda #4
	bra sfail
.f5:	lda #5
	bra sfail
.f6:	lda #6
	bra sfail
.f7:	lda #7
sfail:	sta fail
	stz eng
	jsr hookout             ; (bank $81 at MPR3: the renderer's)
sret:	lda sv4
	tam #4
	lda sv6
	tam #6
	rts

; srca / srcb + X (0 or 32) = the 32 bytes of the tile of BAT word A (low) / Y (high), read from VRAM (masked: 150 cycles)
rdtile:	stx t3
	sta t0
	tya
	and #$07
	sta t1
	lda t0
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	sta t0
	php
	sei
	vsel 1
	lda t0
	sta $0002
	lda t1
	sta $0003
	vsel 2
	plp
	ldx t3
	ldy #16
.rw:	lda $0002
	sta srca,x
	lda $0003
	sta srca+1,x
	inx
	inx
	dey
	bne .rw
	rts

; the near-absent runs of each row over columns 0 .. NCOL - 1 (TBANK at MPR4: RS, RE, and FR = per column the first run that
; ends after it); the near map read from the field bank (MPR6). Carry set: more than 64 runs in a row.
nruns:	lda #TBANK
	tam #4
	stz row
.nr:	ldx row
	lda nbl
	sta .nm+1
	lda nbh
	clc
	adc row
	sta .nm+2
	lda rsl,x
	sta .ws+1
	sta .we+1
	sta .wc+1
	sta .fe+1
	lda rsh,x
	sta .ws+2
	clc
	adc #4
	sta .we+2
	sta .wc+2
	sta .fe+2
	txa
	clc
	adc #$80
	sta .wf+2
	stz t0                  ; runs
	stz t1                  ; in a run
	cly
.c:
.nm:	lda $C000,y
	and #$7F
	tax
	lda prop,x
	bmi .ab
	lda t1
	beq .n
	stz t1
	ldx t0
	tya
	dec a                   ; (the run's last column)
.we:	sta $9400,x
	inc t0
	bra .n
.ab:	lda t1
	bne .n
	ldx t0
	cpx #64
	bcs .no
	inc t1
	tya
.ws:	sta $9000,x
.n:	iny
	cpy ncol                ; (ncol 0: 256 columns)
	bne .c
	lda t1                  ; a run open at the last column ends there
	beq .rc
	ldx t0
	lda ncol
	dec a
.wc:	sta $9400,x
	inc t0
.rc:	ldx row
	lda t0
	sta nr,x
	cly                     ; FR: per column n the first run k with RE[k] >= n (t0 if none)
	clx
.f:	cpx t0
	bcs .fs
.fe:	lda $9400,x
	sta t2
	cpy t2
	bcc .fs
	beq .fs
	inx
	bra .f
.fs:	txa
.wf:	sta $8000,y
	iny
	cpy ncol
	bne .f
	inc row
	lda row
	cmp #16
	beq .d
	jmp .nr
.d:	clc
	rts
.no:	sec
	rts

rmake:	stz rmode
	lda rmd
	beq .no
	lda OP_NEAROFF
	bne .no
	lda sv6                 ; the near words (the field bank at MPR6)
	tam #6
	lda #<cwnear
	ldx #>cwnear
	jsr cwall
	lda #<cwcell            ; the cell words (WS at MPR6, per set)
	ldx #>cwcell
	jsr cwall
	lda #TBANK              ; the pad's targets and the lists (TBANK at MPR6)
	tam #6
	jsr tgmake
	jsr lbuild
	bcs .no
	inc rmode
.no:	rts

; every row of every CW bank: the routine at X:A with row (r) and the row's page t1 ($80 + (r & 7) * 4, the bank at MPR4), set
cwall:	sta .j+1
	stx .j+2
	stz cnt                 ; the bank index: set * 2 + half
.b:	lda cnt
	clc
	adc #CW0
	tam #4
	lda cnt
	lsr a
	sta set
	lda cnt
	and #1
	asl a
	asl a
	asl a
	sta row
.r:	lda row
	and #7
	asl a
	asl a
	adc #$80
	sta t1
.j:	jsr $FFFF
	inc row
	lda row
	and #7
	bne .r
	inc cnt
	lda cnt
	cmp #4
	bne .b
	stz set
	rts

cwnear:	lda nbl                 ; the near words of row: (code & $7F) + the base, columns 0 .. ncol - 1
	sta .s+1
	lda nbh
	clc
	adc row
	sta .s+2
	lda t1
	sta .d+2
	sta .h+2
	cly
	clx
.c:
.s:	lda $C000,y
	and #$7F
	clc
	adc bnlo
.d:	sta $8000,x
	lda bnhi
	adc #0
	inx
.h:	sta $8000,x
	inx
	bne .n
	inc .d+2
	inc .h+2
.n:	iny
	cpy ncol
	bne .c
	rts

cwcell:	lda set
	clc
	adc #WB0
	tam #6
	lda row
	asl a
	adc #$C0
	sta .s0+2
	inc a
	sta .s1+2
	lda t1
	clc
	adc #>CWS
	sta .d0+2
	inc a
	sta .d1+2
	clx
.l:
.s0:	lda $C000,x
.d0:	sta $8000,x
.s1:	lda $C100,x
.d1:	sta $8100,x
	inx
	bne .l
	rts

lbuild:	lda #TMB
	sta lbk
	tam #4
	stz .w+1
	lda #$80
	sta .w+2
	stz k
.kk:	lda .w+2                ; (a pair's lists are under 512 bytes)
	cmp #$9E
	bcc .ok
	inc lbk
	lda lbk
	cmp #TMB + 3
	bcc .nb
	jmp .fail
.nb:	tam #4
	stz .w+1
	lda #$80
	sta .w+2
.ok:	ldx k
	stx kk
	lda lbk
	sta pnext,x
	lda .w+1
	sta pfirst,x
	lda .w+2
	sta pfirst + 128,x
	txa
	asl a
	clc
	adc #33
	bcs .e9
	ldx ncol
	beq .ec
	cmp ncol
	bcc .ec
	lda ncol
	dec a
	bra .ec
.e9:	lda #255
.ec:	sta endc
	stz row
.r:	lda row
	and #7
	asl a
	asl a
	adc #$C0
	sta rowh
	lda .w+1                ; (the count's place)
	sta .cw+1
	lda .w+2
	sta .cw+2
	cla
	jsr .put
	stz cnt
	lda kk
	asl a
	sta pos
	lda row
	clc
	adc #$C0
	sta .f+2
	ldx row
	lda nr,x
	sta nrr
	lda rsl,x
	sta .s+1
	sta .e+1
	lda rsh,x
	clc
	adc #$40
	sta .s+2
	adc #4
	sta .e+2
	ldy pos
.f:	lda $C000,y             ; FR: the first run whose last column is 2kk or more
	tay
.lp:	cpy nrr
	bcs .tl
.s:	lda $D000,y
	cmp endc
	beq .s1
	bcs .tl
.s1:	cmp pos
	bcc .md
	beq .md
	sta stop
	jsr .near
	lda stop
	sta pos
.md:
.e:	lda $D400,y
	cmp endc
	bcc .m1
	lda endc
.m1:	sta stop
	lda pos                 ; cell words pos .. stop
	sec
	sbc kk
	asl a
	pha
	lda rowh
	adc #>CWS
	tax
	pla
	jsr .put
	txa
	jsr .put
	lda stop
	sec
	sbc pos
	inc a
	asl a
	jsr .put
	inc cnt
	lda stop
	cmp endc
	beq .dn
	inc a
	sta pos
	iny
	bra .lp
.tl:	lda endc
	inc a
	sta stop
	jsr .near
.dn:	lda cnt
.cw:	sta $8000
	inc row
	lda row
	cmp #16
	beq .nk
	jmp .r
.nk:	inc k
	lda k
	cmp km1
	beq .x
	jmp .kk
.x:	clc
	rts
.fail:	sec
	rts
.near:	lda pos                 ; near words pos .. stop - 1
	asl a
	pha
	lda rowh
	adc #0
	tax
	pla
	jsr .put
	txa
	jsr .put
	lda stop
	sec
	sbc pos
	asl a
	jsr .put
	inc cnt
	rts
.put:
.w:	sta $8000
	inc .w+1
	bne .p1
	inc .w+2
.p1:	rts

; the pad's target per n0: A = the near-absent cells of the window n0 .. n0 + 32 (column counts from TBANK's runs, MPR6),
; tgt = (rua + rub x A) >> 10
tgmake:	clx                     ; (pfirst and pnext are free after the pairs: the column counts, 0 past column 255)
.z:	stz pfirst,x
	inx
	bne .z
	stz pnext
	stz pnext+1
	stz row
.r:	ldx row
	lda nr,x
	sta nrr
	lda rsl,x
	sta .rs+1
	sta .re+1
	lda rsh,x
	clc
	adc #$40
	sta .rs+2
	adc #4
	sta .re+2
	cly
.k:	cpy nrr
	beq .nx
.rs:	ldx $D000,y
.re:	lda $D400,y
	sta t0
.c:	inc pfirst,x
	cpx t0
	beq .ce
	inx
	bra .c
.ce:	iny
	bra .k
.nx:	inc row
	lda row
	cmp #16
	bne .r
	stz t0                  ; A over columns 0 .. 32 (t0 lo, t1 hi)
	stz t1
	ldx #32
.a:	lda pfirst,x
	clc
	adc t0
	sta t0
	bcc .a1
	inc t1
.a1:	dex
	bpl .a
	clx
.t:	lda t0                  ; rua + rub x A
	sta lo
	lda t1
	sta hi
	lda rub
	sta t2
	lda rual
	sta mwl
	lda ruah
	sta mwh
.m:	lsr t2
	bcc .m1
	lda lo
	clc
	adc mwl
	sta mwl
	lda hi
	adc mwh
	sta mwh
.m1:	asl lo
	rol hi
	lda t2
	bne .m
	lda mwh
	lsr a
	lsr a
	sta tgt,x
	lda t0                  ; slide: + column n0 + 33, - column n0
	clc
	adc pfirst + 33,x
	sta t0
	bcc .s1
	inc t1
.s1:	lda t0
	sec
	sbc pfirst,x
	sta t0
	bcs .s2
	dec t1
.s2:	inx
	cpx n0m1
	beq .tx
	jmp .t
.tx:	rts

midcopy:	lda #TMB
	tam #4
	stz row
.r:	ldx row
	lda rofl,x
	sta .d+1
	lda rofh,x
	clc
	adc #>($8000 + MIDC)
	sta .d+2
	lda mbl                 ; source: the row's column -1, so that Li indexes it
	sec
	sbc #1
	sta .s+1
	lda mbh
	sbc #0
	clc
	adc row
	sta .s+2
	cla
	cly
	bra .d
.c:
.s:	lda $FFFF,y
.d:	sta $8000,y
	iny
	cpy lcol1
	bne .c
	inc row
	lda row
	cmp #16
	bne .r
	lda #$FF
	cly
.p:	sta $8000,y
	sta $8100,y
	sta $8200,y
	sta $8300,y
	sta $8400,y
	sta $8500,y
	sta $8600,y
	sta $8700,y
	sta $8800,y
	sta $8900,y
	iny
	bne .p
	ldx #0
.i:	sta pfirst,x
	inx
	bne .i
	stz npairs
	rts

; A = the pid of pair (t0, t1), made if new; carry set when PMAX are made. Y kept.
pairof:	ldx t0
	lda pfirst,x
.l:	cmp #$FF
	beq .new
	tax
	lda pb,x
	cmp t1
	beq .have
	lda pnext,x
	bra .l
.have:	txa
	inc a
	clc
	rts
.new:	ldx npairs
	cpx #PMAX
	bcs .x
	lda t0
	sta pa,x
	lda t1
	sta pb,x
	phx
	ldx t0
	lda pfirst,x
	plx
	sta pnext,x
	txa
	ldx t0
	sta pfirst,x
	inc npairs
	inc a
	clc
.x:	rts

words:	lda #TMB
	tam #6
	lda bmhi
	and #$F0
	ora #>POOLT
	sta t2                  ; a slot word's high byte
	stz set
.s:	lda set
	clc
	adc #WB0
	tam #4
	stz row
.r:	ldx row
	lda rofl,x
	sta .p+1
	lda rofh,x
	clc
	adc #>($C000 + PIDT)
	sta .p+2
	lda row
	asl a
	adc #$80
	sta .wl+2
	sta .wh+2
	lda set
	lsr a
	ror a
	ror a
	clc
	adc #<POOLT
	sta t3                  ; a slot word's low byte = t3 + the pid's slot
	cly
	clx
.c:
.p:	lda $D800,y
	beq .bl
	cmp #$FF
	beq .bl
	phx
	tax
	lda slotof,x
	plx
	clc
	adc t3
	sta t0
	lda t2
	bra .wh
.bl:	lda bmlo
	sta t0
	lda bmhi
.wh:	sta $8001,x
	lda t0
.wl:	sta $8000,x
	inx
	inx
	bne .w2
	inc .wl+2
	inc .wh+2
.w2:	iny
	cpy lcol
	bne .c
	inc row
	lda row
	cmp #16
	bne .r
	inc set
	lda set
	cmp #2
	beq .sx
	jmp .s
.sx:	stz set
	rts

vispid:	lda #TBANK
	tam #6
	lda #TMB
	tam #4
	stz row
.r:	ldx row
	lda nr,x
	sta t2
	bne .r1
	jmp .nr
.r1:	lda rsl,x
	sta .rs+1
	sta .re+1
	lda rsh,x
	clc
	adc #$40
	sta .rs+2
	clc
	adc #4
	sta .re+2
	lda rofl,x
	sta .pw+1
	lda rofh,x
	clc
	adc #>($8000 + PIDT)
	sta .pw+2
	stz k
.k:	ldy k
	cpy t2
	bcc .k0
	jmp .nr
.k0:
.rs:	lda $D000,y             ; Li_min(s) = s - (min(n0m, s) >> 1)
	sta t0
	cmp n0m
	bcc .s1
	lda n0m
.s1:	lsr a
	eor #$FF
	sec
	adc t0
	sta lo
.re:	lda $D400,y             ; Li_max(e) = e - (max(0, e - 32) >> 1) (e the run's last column), at most lcol - 1
	sta t0
	sec
	sbc #32
	bcs .e1
	cla
.e1:	lsr a
	eor #$FF
	sec
	adc t0
	cmp lcol
	bcc .e2
	lda lcol
	dec a
.e2:	sta hi
	ldy lo
	lda #$FE                ; (seen by some window)
.pw:	sta $8000,y
	cpy hi
	beq .nk
	iny
	bra .pw
.nk:	inc k
	jmp .k
.nr:	inc row
	lda row
	cmp #16
	beq .p
	jmp .r
.p:	stz lo                  ; then the pairs, column by column (Li outer, rows inner): the pids come in column order
.pl:	stz row
.pr:	ldx row
	lda rofl,x
	sta .pd+1
	sta .pw2+1
	sta .ma+1
	inc a
	sta .mb+1
	lda rofh,x
	clc
	adc #>($8000 + PIDT)
	sta .pd+2
	sta .pw2+2
	lda rofh,x
	clc
	adc #>($8000 + MIDC)
	sta .ma+2
	sta .mb+2
	lda .mb+1
	bne .pq
	inc .mb+2
.pq:	ldy lo
.pd:	lda $8000,y
	cmp #$FE
	bne .pn
.ma:	lda $9400,y
	sta t0
.mb:	lda $9401,y
	sta t1
	ora t0
	beq .pw2
	jsr pairof
	bcc .pw2
	rts                     ; (carry set: more than PMAX pairs)
.pw2:	sta $8000,y
.pn:	inc row
	lda row
	cmp #16
	bne .pr
	inc lo
	lda lo
	cmp lcol
	bne .pl
	clc
	rts

; nzt: per row, backwards, the next Li holding a pair (PIDT 1..PMAX)
nzmake:	lda #TMB
	tam #4
	stz row
.r:	ldx row
	lda rofl,x
	sta .w+1
	sta .w2+1
	sta .p+1
	lda rofh,x
	clc
	adc #>($8000 + NZT)
	sta .w+2
	sta .w2+2
	lda rofh,x
	clc
	adc #>($8000 + PIDT)
	sta .p+2
	lda lcol
	ldy lcol
.w2:	sta $FFFF,y
	dey
.l:
.p:	ldx $8000,y
	beq .s
	cpx #$FF
	beq .s
	tya
.s:
.w:	sta $FFFF,y
	dey
	cpy #$FF
	bne .l
	inc row
	lda row
	cmp #16
	bne .r
	rts

ulists:	stz rfail
	lda #TMB                ; (PIDT, nzt; LBANK while ranges writes a list)
	tam #4
	lda #TBANK
	tam #6
	ldx #PMAX
.m:	stz mark,x
	dex
	bpl .m
	stz n0
.n:	lda n0
	lsr a
	sta kk
	inc a
	sta t3                  ; this pair's mark
	lda n0
	clc
	adc #33
	bcc .e0
	lda #255
.e0:	sta nend2               ; the pair's last column (34 cells from 2k, column 255 at most)
	stz cnt
	stz row
.r:	ldx row
	lda nr,x
	sta t2
	bne .r1
	jmp .nr
.r1:	txa
	clc
	adc #$C0
	sta .fr+2
	ldy n0
.fr:	lda $C000,y
	sta k
	lda rsl,x
	sta .rs+1
	sta .re+1
	lda rsh,x
	clc
	adc #$40
	sta .rs+2
	clc
	adc #4
	sta .re+2
	lda rofl,x
	sta .pd+1
	sta .z0+1
	sta .z1+1
	lda rofh,x
	clc
	adc #>($8000 + PIDT)
	sta .pd+2
	lda rofh,x
	clc
	adc #>($8000 + NZT)
	sta .z0+2
	sta .z1+2
.k:	ldy k
	cpy t2
	bcc .k0
	jmp .nr
.k0:
.rs:	lda $D000,y
	cmp nend2
	beq .k1
	bcc .k1
	jmp .nr
.k1:	cmp n0
	bcs .a
	lda n0
.a:	sec
	sbc kk
	sta lo                  ; Li of the first cell
.re:	lda $D400,y
	cmp nend2
	bcc .b2
	lda nend2
.b2:	sec
	sbc kk
	sta hi                  ; Li of the last
	ldy lo
.z0:	lda $FFFF,y             ; the next Li with a pair
.c:	cmp hi
	beq .c1
	bcs .nk
.c1:	tay
.pd:	ldx $8000,y
	lda mark,x
	cmp t3
	beq .nx
	lda t3
	sta mark,x
.nx:	iny
.z1:	lda $FFFF,y
	bra .c
.nk:	inc k
	jmp .k
.nr:	inc row
	lda row
	cmp #16
	beq .r2
	jmp .r
.r2:	jsr ranges
	lda #TMB
	tam #4
	lda n0
	clc
	adc #2
	sta n0
	cmp n0m1
	bcs .x
	jmp .n
.x:	lda rfail
	cmp #1                  ; (carry set: past RMAX somewhere)
	rts

; the column pair n0 >> 1's list (lmap): the pids marked t3, as ranges (first, count) in pid order, a gap of GAPP or fewer pids
; taken in; rfail set past RMAX ranges
ranges:	lda n0
	jsr lmap
	lda lp
	sta .w0+1
	inc a
	sta .w1+1
	inc a
	sta .w2+1
	lda lp+1
	sta .w0+2
	sta .w1+2
	sta .w2+2
	stz cnt                 ; ranges
	stz t2                  ; open range: its first pid (0 none); t1 its last marked pid
	stz t0                  ; past RMAX
	ldx #1
.l:	cpx npairs
	beq .c
	bcs .end
.c:	lda mark,x
	cmp t3
	bne .n
	lda t2
	beq .new
	txa                     ; within GAPP + 1 of the last: the range goes on
	sec
	sbc t1
	cmp #GAPP + 2
	bcc .on
	jsr .close
.new:	stx t2
.on:	stx t1
.n:	inx
	bne .l
.end:	lda t2
	beq .w
	jsr .close
.w:	lda t0                  ; (past RMAX: the setup fails; every pair as one range would overwrite shared slots)
	beq .w3
	inc rfail
.w3:	lda cnt
.w0:	sta $8000
	rts
.close:	lda cnt                 ; the open range t2 .. t1 into the list
	cmp #RMAX
	bcs .all
	asl a
	tay
	lda t2
.w1:	sta $8001,y
	lda t1
	sec
	sbc t2
	inc a
.w2:	sta $8002,y
	inc cnt
	rts
.all:	lda #1
	sta t0
	rts

colour:	lda #LBANK
	tam #4
	ldx #PMAX
.i:	lda #$FF
	sta slotof,x
	stz kmx,x
	dex
	bpl .i
	ldx #SMAX - 1
.j:	stz send,x
	dex
	bpl .j
	stz t3                  ; pass 1: kmx per pid
	stz k
	jsr .walk
	lda #1
	sta t3                  ; pass 2: the slots
	stz k
	jsr .walk
	lda t3
	cmp #2                  ; (carry set: out of slots)
	bcc .r0
	rts
.r0:	ldx #PMAX               ; then kmx per pid: how many pids from it have slots that follow on (the upload's sub-runs)
	lda #1
	sta kmx,x
.rl:	dex
	beq .rx
	lda #1
	sta kmx,x
	lda slotof,x
	inc a
	cmp slotof + 1,x
	bne .rl
	lda kmx + 1,x
	inc a
	sta kmx,x
	bra .rl
.rx:	clc
	rts
.walk:	lda k                   ; every pid of every range of list k
	asl a
	jsr lmap
	lda lp
	sta .l0+1
	inc a
	sta .l1+1
	inc a
	sta .l2+1
	lda lp+1
	sta .l0+2
	sta .l1+2
	sta .l2+2
.l0:	lda $8000
	beq .nk
	sta cnt
	clx
.rg:
.l1:	ldy $8001,x
.l2:	lda $8002,x
	sta len
.p:	lda t3
	bne .s
	lda k                   ; pass 1
	sta kmx,y
	bra .q
.s:	lda slotof,y            ; pass 2: placed already?
	cmp #$FF
	bne .q
	phx
	lda slotof - 1,y        ; first the slot after the previous pid's (consecutive pids in consecutive slots: one MAWR for a
	inc a                   ; run of them in the upload), then the first free
	cmp #SMAX
	bcs .f0
	tax
	lda send,x
	beq .fr
	cmp k
	beq .fr
	bcc .fr
.f0:	clx
.f:	lda send,x
	beq .fr
	cmp k
	beq .fr
	bcc .fr
	inx
	cpx #SMAX
	bne .f
	plx
	lda #2                  ; (none free)
	sta t3
	rts
.fr:	txa
	sta slotof,y
	lda kmx,y
	inc a
	sta send,x
	plx
.q:	iny
	dec len
	bne .p
	inx
	inx
	dec cnt
	bne .rg
.nk:	inc k
	lda k
	cmp km1
	beq .wx
	jmp .walk
.wx:	rts

atabs:	clx
.v:	txa
	asl a
	asl a
	asl a
	asl a
	sta vlo,x
	txa
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>(POOLT * 16)
	sta vhi,x
	inx
	bpl .v
	ldx #PMAX               ; pids PMAX .. 1 (pid 0 is never shown)
.p:	txa
	dec a
	sta t0
	asl a
	asl a
	asl a
	asl a
	asl a
	sta ilo,x
	lda t0
	lsr a
	lsr a
	lsr a
	sta ihi,x
	dex
	bne .p
	rts

images:
	.if CMBANK
	tma #3                  ; (srca, srcb, scr at MPR3)
	pha
	lda #MSB
	tam #3
	.endif
	stz ipass
.pass:	lda ipass
	asl a
	clc
	adc #IBANK
	tam #6
	inc a
	tam #4
	stz t2
.i:	ldx t2
	cpx npairs
	bne .g
	lda ipass
	bne .x
	inc ipass
	bra .pass
.x:
	.if CMBANK
	pla
	tam #3
	.endif
	rts
.g:	lda pa,x
	clc
	adc bmlo
	pha
	lda bmhi
	adc #0
	tay
	pla
	clx
	jsr rdtile
	ldx t2
	lda pb,x
	clc
	adc bmlo
	pha
	lda bmhi
	adc #0
	tay
	pla
	ldx #32
	jsr rdtile
	ldx t2
	inx                     ; pid
	lda ihi,x
	sta t1
	lda ilo,x
	ldx ipass
	bne .b
	sta .d1+1               ; pass 1: phases 1, 2 at MPR6, 3, 4 at MPR4; 5-7 to scr
	sta .d2+1
	sta .d3+1
	sta .d4+1
	lda t1
	clc
	adc #$C0
	sta .d1+2
	adc #$10
	sta .d2+2
	lda t1
	adc #$80
	sta .d3+2
	adc #$10
	sta .d4+2
	lda #<scr
	sta .d5+1
	sta .d6+1
	sta .d7+1
	lda #>scr
	sta .d5+2
	sta .d6+2
	sta .d7+2
	bra .sh
.b:	sta .d5+1               ; pass 2: phases 5, 6 at MPR6, 7 at MPR4; 1-4 to scr
	sta .d6+1
	sta .d7+1
	lda t1
	clc
	adc #$C0
	sta .d5+2
	adc #$10
	sta .d6+2
	lda t1
	adc #$80
	sta .d7+2
	lda #<scr
	sta .d1+1
	sta .d2+1
	sta .d3+1
	sta .d4+1
	lda #>scr
	sta .d1+2
	sta .d2+2
	sta .d3+2
	sta .d4+2
.sh:	ldy #31
.bt:	lda srcb,y
	sta t0
	lda srca,y
	asl t0
	rol a
.d1:	sta $C000,y
	asl t0
	rol a
.d2:	sta $D000,y
	asl t0
	rol a
.d3:	sta $8000,y
	asl t0
	rol a
.d4:	sta $9000,y
	asl t0
	rol a
.d5:	sta $C000,y
	asl t0
	rol a
.d6:	sta $D000,y
	asl t0
	rol a
.d7:	sta $8000,y
	dey
	bpl .bt
	inc t2
	jmp .i
