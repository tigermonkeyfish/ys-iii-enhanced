; The stub, in two runs of all-$FF bytes on the disc: run 1 $46BA-$47FF (data sector 2 byte $6BA), run 2 $5F47-$5FFF (sector 452 byte $747).
; Both copies of the data layout are patched.
;
; Without the System Card's RAM the patch does not run: bootchk stops with a message.
;
; The module's jump table, at $A000 + 3k: 0 row (carry set: nothing written), 1 satbody, 2 modinit (A = dgen), 3 idlework, 4 idlelate, 5 lateup, 6 leave.

ROWDRAW  = $6CD8
ROWCNT   = $6CCF
FRAMES   = $2241
TIMER    = $0C00
CD_READ  = $E009        ; System Card: cd_read (args in zero page $F8-$FF)
HALTSEC  = 158          ; the no-card message's sectors (src/syscard_halt.asm), and the stub bank's image
WIDE     = $68          ; the RAM bank bootchk tests
SBANK    = $7D          ; the stub bank (card RAM): the halt slot's MODSECS sectors, the stub's part at $0400 of it
SBORG    = $C400        ; where that part runs (MPR6); mkdisc places it at byte $400 of HALTSEC
MODSECS  = 4            ; the module: 4 sectors, one 8 KB bank at $A000
BIAS     = 64

; the stub bank's entries (JMP table at SBORG + 3k; xcall takes the low byte)
XW       = 0            ; the main loop's wait: carry clear, return now (a pass started); carry set, wait until FRAMES leaves t0
XG       = 3
XP       = 6
XA       = 9            ; (unused)
XL       = 12           ; the area loader's body (X: the module's directory index)

	.bank 0
	.org $46BA

; ---------------------------------------------------------------- variables
curmod:	.db 0                   ; the active module's code bank, 0 none
lastmod:	.db 0                   ; the module that ran last
sbok:	.db 0                   ; the stub bank holds its part (read at an area load; a module's data can overwrite it)
hf:	.db 0

; ---------------------------------------------------------------- the directory (written by tools/mkdisc.py)
	.include "directory.inc"

; ---------------------------------------------------------------- the boot test: in the halt slot
bootchk:	lda #HALTSEC
	jsr rdm
	bne bootchk
	jmp $A000
dgen     = bootchk      ; data generation, given to modinit: a hint; the module proves it by a byte signature
t0       = bootchk + 1  ; FRAMES at this pass's row 0 (without the timing model), or the frame waitfix waits out
ts       = bootchk + 2
hs       = bootchk + 3
wi       = bootchk + 4  ; non-zero: XW asks waitfix for the module's idle work (entry 9), called there at the stack depth it had before the timing model
tr0      = bootchk + 5
tl       = bootchk + 6  ; ... as its last row returned
nr       = bootchk + 7  ; 0: a span of the module's rows to count (row 0 to tl); bit 7: counted already
t0ok     = bootchk + 8  ; (waitfix without the stub bank) t0 holds this pass's frame
te       = bootchk + 9

rdm:	phx
	sta <$FE                ; _cl _ch _dl: the first sector
	stz <$FC
	stz <$FD
	lda #1                  ; _dh 1: to local memory at _bx, _al sectors
	sta <$FF
	lda #MODSECS
	sta <$F8
	stz <$FA
	lda #$A0
	sta <$FB
	jsr CD_READ
	plx
rchk:	cmp #0
	bne .x
	lda $A000
	cmp #$4C
.x:	rts

; ---------------------------------------------------------------- whoever is in charge leaves: nothing of it stays in VRAM
leave:	lda curmod
	beq .s
	lda #$12
	jsr mcall
	stz curmod
.s:
.x:	rts

; ---------------------------------------------------------------- the block loader's entry (its body: xl, in the stub bank)
areaload:	cmp #16
	bcc .orig
	bit #1
	beq .area
.orig:	tay                     ; the two instructions the hook replaced
	sta <$FD
	rts
.area:	phx
	pha
	jsr leave               ; at every area load
	pla
	pha
	ldx #NMOD
.f:	dex
	bmi .out
	cmp dblk,x
	bne .f
	tma #5
	pha
	lda #XL
	jsr xcall               ; its banks read, MPR5 its bank; carry set: a read failed (Z set: no stub bank, no module)
	beq .none
	bcs .none
	phx
	lda dgen
	jsr $A006               ; modinit (may take frames: the screen is dark during the area load)
	plx
	lda dbank,x
	sta curmod
.none:	pla
	tam #5
.out:	pla
	plx
	bra .orig

; ---------------------------------------------------------------- the module's entry A, its bank at MPR5 (no module: nothing)
mcall:	sta mcj + 1             ; (as before the timing model; every caller tests curmod)
	phx
	tma #5
	pha
	lda curmod
	tam #5
mcj:	jsr $A000
	pla
	tam #5
	plx
	rts

; ---------------------------------------------------------------- the stub bank's entry A, MPR6 kept
; Z set on return: the stub bank is not there (a module's data overwrote it), nothing ran, the carry as it came; else Z
; clear (the bank number pulled) and the carry as the entry left it. X and Y as the entry leaves them (it keeps them).
xcall:	sta .j + 1
	lda sbok
	beq .x
	tma #6
	pha
	lda #SBANK
	tam #6
.j:	jsr SBORG
	pla
	tam #6
.x:	rts

allocstub:	cmp #$78
	bcc .x
	lda curmod
	cmp #$7F                ; (Redmont's code bank; the other modules have no such entry)
	bne .x
	phy
	lda #$15
	jsr mcall
	ply
.x:	lda $40E4
	rts

; ---------------------------------------------------------------- the waits
waitfix:	lda t0ok
	beq .idle
	stz t0ok
	lda t0
	cmp FRAMES
	bne .late
.idle:	lda FRAMES
	sta t0
	lda curmod
	beq .wait
	lda #9
	jsr mcall
.wait:	lda t0
.wl:	cmp FRAMES
	beq .wl
.x:	rts
.late:	lda curmod              ; the late pass's slot images, if the playfield is scanned out
	beq .idle
	lda #$F
	jmp mcall

rcrhook:	pha
	lda $4B4B
	beq .t
	lda TIMER
	sta hs
	lda FRAMES
	sta hf
.t:	pla
	jmp $4B40
end1:

	.org $5F47

; ---------------------------------------------------------------- the row stub
rowstub:	lda ROWCNT              ; (as before the timing model)
	bne .notfirst
	lda FRAMES
	sta t0
	lda #1
	sta t0ok
	bra .first
.notfirst:
	lda rowgame
	bne .orig
.first:	lda curmod
	beq .orig
	tma #5
	pha
	lda curmod
	tam #5
	jsr $A000
	pla
	tam #5
	bcs .orig
	rts
.orig:	jmp ROWDRAW

satwait:	bbr1 <$B1, .out
	lda curmod
	beq .w
	lda #$C                 ; (idlelate: the stub bank does not count it, the pass starts at the coming vblank)
	jsr mcall
.w:	bbs1 <$B1, .w
.out:	rts

gwait:	lda FRAMES
	pha
	sec
	lda curmod
	beq .g
	phx
	lda #XG
	jsr xcall
	plx
.g:	pla
	bcs .x
	dec a
.x:	rts

satstub:	lda curmod
	beq .req
	rmb1 <$B1               ; no latch before the DVSSR write
	lda #3
	jsr mcall
	lda #$13                ; DVSSR
	sta <$F7
	sta $0000
	ldy $2215
	ldx #16
.chk:	lda $1403
	and #$02
	beq .go
	cli                     ; (taken after the instruction that follows CLI)
	nop
	sei
	dex
	bne .chk
.go:	ldx $2214
	stx $0002               ; the DMA runs at the first vblank after this write ...
	sty $0003
	smb1 <$B1
	cly
	rts
.req:	jmp $E09F

end2:

	.org $5FFF
rowgame:	.db 0

	.bank 1
	.org SBORG
	jmp xw
	jmp xg
	jmp xp
	jmp xa
	jmp xl
	jmp sbgo
p0:	.db 0                   ; FRAMES as the pass started
pf:	.db 0                   ; non-zero: a pass starts at frame pp (debt BIAS): the stub waited for that vblank (XW's wait, satwait's)
pp:	.db 0
debt:	.db 0
now:	.db 0
tmp:	.db 0
spn:	.db 0

tnow:	lda TIMER
	and #$7F
	sta now
	lda pf
	beq .x
	lda FRAMES
	sec
	sbc pp
	bmi .x                  ; (not yet: still before that vblank)
	lda pp
	sta p0
	stz pf
	lda #BIAS
	sta debt
.x:	rts
el:	and #$7F
	sec
	sbc now
	bcs .x
	adc #116
.x:	rts
md:	sec
	sbc tmp
	bcs .x
	adc #116
.x:	rts

HK       = 41
HF       = 76
pos:	lda hf
	cmp FRAMES
	beq .t
	inc a
	cmp FRAMES
	bne .st
	lda hs
	jsr el
	sec
	sbc #HK
	bcs .x
	cla                     ; (not past it yet: 0)
	sec
.x:	rts
.t:	lda hs
	jsr el
	clc
	adc #HF
	sec
	rts
.st:	cla
	clc
	rts

; The module's rows since they were last counted go to the debt (nr bit 7: none)
HV       = 40
HD       = 1
rows:	lda nr
	bmi .x
	lda tl
	and #$7F
	sta tmp
	lda tr0
	and #$7F
	pha
	jsr md
	sta spn
	lda hs
	and #$7F
	sec
	sbc #HV
	bcs .v
	adc #116
.v:	sta tmp
	pla
	jsr md                  ; row 0 to the vblank
	cmp spn
	bcs .c                  ; (the vblank was not inside; nor, with a stale stamp, any we know of)
	lda hf
	inc a
	cmp FRAMES
	bne .c
	lda spn
	sec
	sbc #HD
	bcs .s
	cla
.s:	sta spn
.c:	lda rowgame
	beq .n
	lda #0
	bra .r
.n:	lda ROWCNT
	cmp #16
	bcc .r
	lda #16
.r:	sta nr
	lsr a
	lsr a
	sta tmp
	lda nr
	asl a
	adc tmp                 ; (carry clear: nr < 128)
	eor #$FF
	sec
	adc spn
	clc
	adc debt
	sta debt
	lda #$FF
	sta nr
.x:	rts

sbgo:	tai zz, $A000, $2000
	jmp $20F8
zz:	.dw 0

; The area loader's body (from areaload, X = the module's directory index; MPR5 free): its banks from disc the first time (or
; after a module's data overwrote it), MPR5 its code bank, dgen moved on when it is not the module that ran last. Carry set: a read failed.
dsec:
	.include "dirsec.inc"     ; (mkdisc: each module's first sector)
xl:	lda dl,x
	bne .in
	cpx #D2MOD              ; the module with a cold bank (its code at MPR6 while it runs): that bank first, then its own; dl only when both arrived
	bne .one
	lda #D2BANK
	tam #5
	lda #D2SEC
	jsr rdm
	bne .no
.one:	lda dbank,x
	tam #5
	lda dsec,x
	jsr rdm
	bne .no
	inc dl,x
.in:	lda dbank,x
	tam #5
	cmp #WIDE               
	bne .nw
	phx
	ldx #NMOD - 1
.c:	stz dl,x
	dex
	bpl .c
	plx
	inc dl,x                ; (not itself)
	stz sbok
.nw:	cmp lastmod
	beq .same
	sta lastmod
	inc dgen
.same:	lda #BIAS
	sta debt
	stz wi                  ; (bootchk's byte as the boot left it)
	lda FRAMES
	sta p0
	lda #$FF
	sta nr
	clc
	rts
.no:	sec
	rts

macc:	lda mcj + 1
	cmp #3
	beq .c
	cmp #$15
	bne .x
.c:	lda te
	and #$7F
	sta tmp
	lda ts
	and #$7F
	jsr md
	clc
	adc debt
	sta debt
.x:	lda #$FF
	sta mcj + 1
	rts
xa:	rts                     ; (entry kept: no caller)

xp:	jsr tnow
	jsr pos
	adc #BIAS - 1           ; (fresh: pos + BIAS; stale: BIAS - 1)
	sta debt
	lda FRAMES
	sta p0
	stz pf
	lda #$FF
	sta nr
	rts

xw:	jsr tnow
	jsr rows
	jsr macc
	lda FRAMES
	sec
	sbc p0
	beq .idle
	dec a
	bne .game
	jsr pos
	bcc .game
	adc #BIAS - 1
	cmp debt
	bcs .game
	lda #$F
	jsr mcall
	jsr xp
	bbr1 <$B1, .l
	lda FRAMES
	inc a
	sta pp
	lda #1
	sta pf
.l:	lda #$FF                ; (the late entry's time is not the pass's)
	sta mcj + 1
	clc
	rts
.idle:	jsr pos
	sbc #117 - BIAS
	bcc .i                  ; 117 steps): then that one first (stale: pos 0, carry clear: never)
	cmp debt
	bcc .i
	jsr $4B6D
.i:	lda #1                  ; the module's idle work (FRAMES sampled first): waitfix calls it (wi)
	sta wi
	lda p0
	bra .w
.game:	lda FRAMES
.w:	sta t0
	inc a
	sta pp
	lda #1
	sta pf
	sec
	rts

xg:	jsr tnow
	jsr rows
	jsr macc
	lda FRAMES
	clc
	sbc p0                  ; FRAMES - p0 - 1: 0 when one vblank went by in the pass
	bne .s
	jsr pos
	bcc .s
	adc #BIAS - 1
	cmp debt
	bcs .s
	jsr xp                  ; the module made this wait late: it ends now, a pass starts
	clc
	rts
.s:	lda #BIAS               ; it waits: from the coming vblank nothing of ours is behind
	sta debt
	lda FRAMES
	inc a
	sta p0
	stz pf
	sec
	rts
send:
