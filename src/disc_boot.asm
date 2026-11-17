; The stub, in two runs of all-$FF bytes on the disc: run 1 $46BA-$47FF (data sector 2 byte $6BA), run 2 $5F47-$5FFF (sector 452 byte $747).
; Both copies of the data layout are patched.
;
; Without the required card RAM the patch does not run: bootchk stops with a message.
;
; The module's jump table, at $A000 + 3k: 0 row (carry set: nothing written), 1 satbody, 2 modinit (A = dgen), 3 idlework, 4 idlelate, 5 lateup, 6 leave.
ROWDRAW  = $6CD8
ROWCNT   = $6CCF
FRAMES   = $2241
TIMER    = $0C00
CD_READ  = $E009        ; System Card: cd_read (args in zero page $F8-$FF)
HALTSEC  = 158
WIDE     = $68
SBANK    = $7D
SBORG    = $C400
MODSECS  = 4
BIAS     = 64

; the stub bank's entries (JMP table at SBORG + 3k; xcall takes the low byte)
XW       = 0            ; the main loop's wait: carry clear, return now (a pass started); carry set, wait until FRAMES leaves t0
XG       = 3
XP       = 6
XL       = 12           ; the area loader's body (X: the module's directory index)
XO       = 18           ; sbobj per-pass update (+ ex_sprclr)
XS       = 21           ; sbobj per-slot coord offset + Dulan spin frame override
XR       = 24           ; sbobj Part B restore/sync on 17->18 handoff (qho)
XE       = 27           ; sbobj Scene 17 entry backup (dpass)

	.bank 0
	.org $46BA

; ---------------------------------------------------------------- variables (run 1: survive block 14 reloads)
curmod:	.db 0                   ; the active module's code bank, 0 none
lastmod:	.db 0                   ; the module that ran last: another one means the shared data banks are not its own
sbok:	.db 0                   ; the stub bank holds its part (read at an area load when a module's data overwrote it: WIDEMOD)
hf:	.db 0
prev:	.db 0
BPAD     = 26
bline:	.db 0
bbxr:	.db 0, 0
bstate:	.db 0

; ---------------------------------------------------------------- the directory (written by mkdisc: src/modules.json)
	.include "directory.inc"

; ---------------------------------------------------------------- the boot test: in the halt slot
bootchk:	lda #HALTSEC
	jsr rdm
	bne bootchk
	jmp $A000
dgen     = bootchk      ; data generation, given to modinit: a hint; each module proves it by a byte signature
t0       = bootchk + 1  ; FRAMES at this pass's row 0 (without the timing model), or the frame waitfix waits out
ts       = bootchk + 2
hs       = bootchk + 3
wi       = bootchk + 4  ; non-zero: XW asks waitfix for the module's idle work (entry 9), called there at the stack depth it had before the timing model
tr0      = bootchk + 5
tl       = bootchk + 6  ; ... as its last row returned
nr       = bootchk + 7  ; 0: a span of the module's rows to count (row 0 to tl); bit 7: counted already
t0ok     = bootchk + 8  ; (waitfix without the stub bank, the quarry's) t0 holds this pass's frame
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
rchk:	tay                     ; (Z from A in one byte: no caller of rdm keeps Y; run 1 holds bandirq)
	bne .x
	lda $A000
	cmp #$4C
.x:	rts

; ---------------------------------------------------------------- whoever is in charge leaves: nothing of it stays in VRAM
leave:	lda curmod
	beq .s
	lda #$12
	jsr mcall
	lda prev
	stz prev
	sta curmod
	bra leave
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
	pla                     ; (the block: every row of it, down to the first, which is in charge)
	pha
	bra .f
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
; Z set on return: the stub bank is not there (the quarry's data overwrote it), nothing ran, the carry as it came; else Z
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

; ---------------------------------------------------------------- the waits (called from block 14's hooks)
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


bandirq:	lda $4B4B
	beq .s0
	jmp bandn
.s0:	jsr $4B40
	lda bline
	sta bstate
	beq .x
	st0 #6
	sta $0002
	st2 #0
.x:	rts
band:	stz bstate
	ldx #BPAD
.bp:	dex
	bne .bp                 ; Geargrafx (line 103 for RCR $A7 in 388 of 388 frames): a knife edge on any other latch point
	lda $4AE0
	and #1
	tax
	st0 #7
	lda bbxr,x
	sta $0002
	st2 #0
	st0 #6
	st1 #$D7
	st2 #0
	rts

satskip:	.db 0
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


satstub:	lda curmod
	beq .req
	rmb1 <$B1               ; no latch before the DVSSR write
	lda #3
	jsr mcall
	lsr satskip
	bcs .sk
	lda #$13                ; DVSSR, as ex_sprdma selects it (register select copy $F7)
	sta <$F7
	sta $0000
	ldy $2215
	ldx #16
.chk:	tst #$02, $1403
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
.sk:	cly
	rts
.req:	jmp $E09F

mhook:	lda curmod
	beq .o
	lda #$18
	jmp mcall
.o:	inc $339F
	rts


; ---------------------------------------------------------------- per-slot / per-pass sprite smoothing dispatch (run 2: calls SBANK)
objpass:	pha
	lda #XO
	jsr xcall
	pla
	jmp $E0AE
objslot:	lda #XS
	jsr xcall
sfr	= * + 1
	lda #0
	rts

bandn:	lda bstate
	beq .g
	jmp band
.g:	jmp $4B40
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
	jmp sbobj_pass
	jmp sbobj_slot
	jmp sb_sync
	jmp sb_enter17
tmp:	.db 0

sbgo:	pha
	phx
	lda #$A0
	sta .zt + 4
	ldx #$20
.zt:	tai zz, $A000, $0100
	inc .zt + 4
	dex
	bne .zt
	plx
	pla
	jmp $20F8
zz:	.dw 0

; The area loader's body (from areaload, X = the module's directory row; MPR5 free): its banks from disc the first time (or
; after a module that wrote them), MPR5 its code bank, dgen moved on when it is not the module that ran last. Carry set: a read
; failed. At every entry the rows whose code banks this module writes (dkill, from src/modules.json's banks: mkdisc) are marked
; to be read again, and the stub bank (dsbk) when its data reach SBANK; a module's rows (dsame: one per block) arrive together.
dsec:
	.include "dirsec.inc"
dmark:	sta tmp                 ; dl = Y for every row whose bit is set in A
	phx
	clx
.l:	lsr tmp
	bcc .n
	tya
	sta dl,x
.n:	inx
	cpx #NMOD
	bne .l
	plx
	rts
xl:
	jsr sb_sync
	lda dl,x
	bne .in
	cpx #D2MOD              ; the module with a cold bank (its code at MPR6 while it runs): that bank first, then its own; dl only when both arrived
	bne .one
	.if D3BANK                ; (with a second cold bank, mkdisc "bank3" at D2SEC + 4: both in one read of 8 sectors, rd8)
	jsr rd8
	.else
	lda #D2BANK
	tam #5
	lda #D2SEC
	jsr rdm
	.endif
	bne .no
.one:	lda dbank,x
	tam #5
	lda dsec,x
	jsr rdm
	bne .no
	lda dsame,x             ; (every row of this module)
	ldy #1
	jsr dmark
.in:	lda dkill,x             ; the rows whose code this module's banks overwrite: read again at their next entry
	cly
	jsr dmark
	lda dsbk,x
	beq .nw
	stz sbok                ; (its data reach the stub bank: read again by leave at the next area load)
.nw:	lda dbank,x
	tam #5
	cmp lastmod
	beq .same
	sta lastmod
	inc dgen
.same:
	stz wi                  ; (bootchk's byte as the boot left it)
	lda #$FF
	sta nr
	clc
	rts
.no:	sec
	rts

xw:
xg:
xp:
xa:	rts
	.if D3BANK
rd8:	phx
	tma #3
	pha
	tma #4
	pha
	lda #D2BANK
	tam #3
	lda #D3BANK
	tam #4
	.if D4BANK                ; (a third cold bank, mkdisc "bank4" at D3SEC + 4: the three in one read of 12 sectors; MPR5 is the loader's to use)
	lda #D4BANK
	tam #5
	.endif
	lda #D2SEC
	sta <$FE
	stz <$FC
	stz <$FD
	lda #1
	sta <$FF
	.if D4BANK
	lda #3 * MODSECS
	.else
	lda #2 * MODSECS
	.endif
	sta <$F8
	stz <$FA
	lda #$60
	sta <$FB
	jsr CD_READ
	cmp #0
	bne .x
	lda $6000
	cmp #$4C
	bne .x
	lda $8000
	cmp #$4C
	.if D4BANK
	bne .x
	lda $A000
	cmp #$4C
	.endif
.x:	php                     ; (the banks and X back; Z as compared)
	pla
	sta <$FA                ; (a scratch byte of the call's own arguments)
	pla
	tam #4
	pla
	tam #3
	plx
	lda <$FA
	pha
	plp
	rts
	.endif
	.include "sbobj.inc"
send:
	.if (send > $C6D0)
	.fail "SBPART overflow"
	.endif

	.bank 2
	.org $C800
	.include "sbobj_b.inc"
send2:
	.if (send2 > $CC00)
	.fail "SBPART2 overflow"
	.endif
