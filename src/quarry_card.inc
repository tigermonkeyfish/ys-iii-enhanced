
CR3H       = $15
TPLM       = $01
LBM        = $48
IMGM       = $D0
KTH        = $17
OCPM       = $F0
NPER       = 17         ; cn 80 .. 96
CR2H       = $11        ; (quarry-bridge-setup) the bridge's store, R2 $11:0000-$14:FFFF: header $11:0000, TPL $11:0100 + 1056 P, LB $11:B000 +
LB2M       = $B0        ; $800 P (to $12:F7FF at 41 periods), IMG $13:0000 + 32 i (4,096 images)
LB2H       = $11
NPB1       = 41         ; its periods: cn 39 .. 79, cameras 296 .. 622 (quarry-bridge-draw: the bridge's pass, quarry_cardb.inc)
CNB0       = 39
CN0        = 80
NFKEYS     = 42 * 192   ; NF keys: (2 e + side) * 192 + f; NM keys: NFKEYS + (2 e + side) * 90 + 2 g + h
KTN        = NFKEYS + 42 * 90
ONUM       = 35         ; the odd set's tiles

; ---------------------------------------------------------------- variables (the overlay's copy sets them each visit)
cper:	.db $FF         ; the period whose template WIN holds, and its region
cprg:	.db 0
crg:	.db 0           ; this pass's region; its period's list block (mid, high)
clbm:	.db 0
clbh:	.db 0
RNPER:	.db NPER, NPB1
RTPH:	.db CR3H, CR2H
RLBM:	.db LBM, LB2M
RLBH:	.db CR3H, LB2H
csh:	.db $FF         ; the mix set the shown picture uses ($FF none)
ctl:	.db $FF, $FF, $FF, $FF  ; per mix set (0, 1) and odd set (2): the camera whose images it holds, low / high
cth:	.db $FF, $FF, $FF, $FF
cosh:	.db $FF         ; the odd set the shown picture uses ($FF none)
cos:	.db $FF         ; this pass's odd set
cocp:	.db 0           ; the odd set's tiles copied out (ours in them)
cotok:	.db 0           ; OTL / OTH made
cbp:	.db 0           ; pass: the period, a row counter, k, dm, the set, the camera
crk:	.db 0
ct:	.db 0, 0, 0, 0
cfr:	.db 0           ; cup1: FRAMES before its TIA
ck:	.db 0
cdm:	.db 0
cs:	.db 0
cxl:	.db 0
cxh:	.db 0
cuo:	.db 0           ; cupl: the image's offset in its record (32 (k - 1) or 32 (d - 1)), tiles left
cun:	.db 0
ibuf:	.ds 32
OTL:	.ds ONUM
OTH:	.ds ONUM
ORUN:	.db <$65B, >$65B, 11, <$66D, >$66D, 11, <$1A8, >$1A8, 8, <$578, >$578, 5
ORN        = 4 * 3
CGUP:	.db 24, 1, 16, 16

; ---------------------------------------------------------------- helpers
cb2:	sta $1A22               ; port 2's base = A / X / Y
	stx $1A23
	sty $1A24
	rts
cpass:	lda nbpass + 1          ; (band_init: the first pass of a take-over: nothing of ours shown, the template again)
	bne .s
	lda nbpass
	cmp #1
	bne .s
	lda #$FF
	sta cper
	sta csh
	sta cosh
	ldx #3
.r:	sta ctl,x
	sta cth,x
	dex
	bpl .r
	lda cotok
	bne .s
	jsr cotgen
	inc cotok
.s:	lda pn
	sta ck
	tax
	lda CGUP,x
	sta bugm + 1
	lda dm
	sta cdm
	lda CAMX
	sta cxl
	lda CAMX + 1
	sta cxh
	lda cn
	jsr cpsel
	bcc *+5
	jmp cpx                 ; (never: the band draws cn 80 .. 96)
	ldx ck
	beq .t
	lda cbp
	cmp cper
	bne .t
	lda crg
	cmp cprg
	beq .nt
.t:	jsr cltpl
.nt:	lda ck
	bne *+5
	jmp .nk
	lda csh                 ; the sets: not the ones the shown picture uses; else the ones that hold this camera
	ldx #0
	jsr cpick
	sta cs
	lda #$FF
	sta cos
	lda cdm
	lsr a
	bcc .no
	jsr copick
	ldx cocp                ; (its tiles not copied out yet: the even phase this pass)
	bne *+4
	lda #$FF
	sta cos
.no:	jsr cpairs
	jsr cends
	jsr cmids
	jsr cupl
	lda cs
	sta csh
	lda cos
	sta cosh
	bra cpx
.nk:	lda cocp                ; k = 0: the odd set's tiles copied out if not yet; the next camera's images ahead (the sets the shown
	bne *+5                 ; picture does not use); this picture uses none
	jsr cocopy
	.if BRLEV
	lda ldir
	bpl .pa
	lda cxl
	and #15
	beq .np
.pa:
	.endif
	jsr cpre
.np:	lda #$FF
	sta csh
	sta cosh
cpx:	lda di_bn               ; (quarry-band1-lastcells) with the seams' image in: the pass's extra cells (quarry_cards.inc: sxt)
	bne *+7
	ldy #8
	jsr c7tr
	lda #BANDT
	tam #4
	rts
; (quarry-bridge-setup) A = a near column -> its store region crg (0 band 1's at $15, 1 the bridge's in R2) and period cbp there, and the
; period's list block: LB + $800 P as mid / high bytes (clbm, clbh: the carry into the high byte, so a region holds more than 23 periods:
; 60 and more). Carry set: no period for that column. The template's place needs no carry up to 61 periods a region (1056 x 62 < 64 KB
; from TPLM = 1). Region 1 is not asked for in this row (NPB1 = 0: no column maps to it until the bridge's pass is in).
cpsel:	clx
	.if BRPROBE
	jsr cprb
	bcs .n
	.else
	sec
	sbc #CN0
	bcs .b
	adc #CN0 - CNB0         ; (carry clear) the bridge's columns
	bcc .n
	inx
.b:	cmp RNPER,x
	bcs .n
	.endif
	sta cbp
	stx crg
	lsr a                   ; 8 P: its high bits
	lsr a
	lsr a
	lsr a
	lsr a
	sta clbh
	lda cbp
	asl a
	asl a
	asl a
	clc
	adc RLBM,x
	sta clbm
	lda clbh
	adc RLBH,x
	sta clbh
	clc
	rts
.n:	sec
	rts
; LB (this pass's period) + $Y00: A low (0), X mid, Y high
clb:	tya
	clc
	adc clbm
	tax
	cla
	ldy clbh
	rts
	.if BRPROBE
; (the measurement build) A = a near column -> its period, carry clear; below the band's columns: the column mod 17 (band 1's store)
cprb:	cmp #CN0
	bcs .n
.m:	cmp #NPER
	bcc .x
	sbc #NPER
	bra .m
.n:	sbc #CN0
	cmp #NPER
.x:	rts
	.endif
; A = the shown picture's set ($FF none), X = 0 mix / 2 odd: the other one; none shown: the one holding this camera (cxl / cxh), else 0
cpick:	cmp #$FF
	beq .t
	eor #1
	rts
.t:	lda ctl + 1,x
	cmp cxl
	bne .z
	lda cth + 1,x
	cmp cxh
	bne .z
	lda #1
	rts
.z:	cla
	rts
; the odd set (one): 0 unless the shown picture uses it for another camera ($FF: this pass shows the even phase one pixel off)
copick:	lda cosh
	bmi .z
	lda ctl + 2
	cmp cxl
	bne .n
	lda cth + 2
	cmp cxh
	beq .z
.n:	lda #$FF
	rts
.z:	cla
	rts
cpre:	jsr cnxt
	bcs .x
	beq .x
	lda crg                 ; (a column of the bridge's region: not this engine's)
	bne .x
	lda cxl
	lsr a
	and #7
	sta cdm
	lda csh
	ldx #0
	jsr cpick
	sta cs
	lda #$FF
	sta cos
	lda cdm
	lsr a
	bcc .u
	jsr copick
	ldx cocp
	bne *+4
	lda #$FF
	sta cos
.u:	jmp cupl
.x:	rts
cnxt:	lda ldir
	beq .n
	asl a                   ; Y = X + 2 ldir
	ldx #0
	cmp #$80
	bcc *+3
	dex
	clc
	adc cxl
	sta cxl
	txa
	adc cxh
	sta cxh
	lda cxl                 ; its period: ((Y + 16) >> 3) - 80
	clc
	adc #16
	sta ct
	lda cxh
	adc #0
	lsr a
	ror ct
	lsr a
	ror ct
	lsr a
	ror ct
	lda ct
	jsr cpsel
	bcs .n
	lda cxl                 ; k
	and #7
	lsr a
	sta ck
	clc
	rts
.n:	sec
	rts
; the template of period cbp into WIN: port 2 at TPL + 1056 P, 33 pieces of 32 bytes (interrupts between pieces)
cltpl:	lda crg
	sta cprg
	lda cbp
	sta cper
	lsr a                   ; 1056 P = 1024 P + 32 P: mid TPLM + 4 P + (P >> 3), low (P << 5) & $FF
	lsr a
	lsr a
	sta ct
	lda cbp
	asl a
	asl a
	clc
	adc ct
	adc #TPLM
	tax
	ldy crg
	lda RTPH,y
	sta .h + 1
	lda cbp
	asl a
	asl a
	asl a
	asl a
	asl a
.h:	ldy #CR3H
	jsr cb2
	lda #<WIN
	sta .d+3
	lda #>WIN
	sta .d+4
	ldx #33
.d:	tai $1A20, WIN, 32
	lda .d+3
	clc
	adc #32
	sta .d+3
	bcc *+5
	inc .d+4
	dex
	bne .d
	rts
; per row r: its count, then its entries; the row's WIN base in the stores (WIN + 66 r)
cprow:	lda #<WIN
	sta ct
	lda #>WIN
	sta ct + 1
	rts
cpnext:	lda ct
	clc
	adc #66
	sta ct
	bcc *+5
	inc ct + 1
	rts
; the pairs: (2 j, slot): a ready group's word + k
cpairs:	ldy #0
	jsr clb
	lda #$10
	jsr cb1
	jsr cprow
	lda #16
	sta crk
.r:	lda ct
	sta .l+1
	sta .h+1
	inc .h+1                ; (2 j + 1 never crosses a page: WIN + 66 r + 2 j is even)
	lda ct + 1
	sta .l+2
	sta .h+2
	lda $1A10
	beq .n
	sta ct + 2
	clc
.e:	ldy $1A10
	ldx $1A10
	lda GREADY,x
	beq .z
	lda GSLOT,x
	tax
	lda GVL,x
	adc ck
.l:	sta WIN,y
	lda GVH,x
	adc #0
.h:	sta WIN + 1,y
.z:	dec ct + 2
	bne .e
.n:	jsr cpnext
	dec crk
	bne .r
	rts
; the ends: (2 j, rank, high): the set's tile
cends:	ldy #2
	jsr clb
	jsr cb1
	lda cs                  ; set 0 $680 + rank, set 1 $6C0 + rank (64 a set: the store has at most 64 ranks)
	beq *+4
	lda #$40
	clc
	adc #<MIXBASE
	clx
cendx:	sta .o+1                ; (the bridge's lists too, bends: A = its set's first tile, low; X = what the word's high byte takes on top)
	stx .q+1
	jsr cprow
	lda #16
	sta crk
.r:	lda ct
	sta .l+1
	sta .h+1
	inc .h+1
	lda ct + 1
	sta .l+2
	sta .h+2
	lda $1A10
	beq .n
	sta ct + 2
.e:	ldy $1A10
	lda $1A10
	clc
.o:	adc #0
.l:	sta WIN,y
	lda $1A10
.q:	ora #0
.h:	sta WIN + 1,y
	dec ct + 2
	bne .e
.n:	jsr cpnext
	dec crk
	bne .r
	rts
; the mid cells, rows 13-15: midp (2 j, first - 1 low, high, odd rank), then mide (2 j, word dm < 4, word dm >= 4)
cmids:	ldy #4
	jsr clb
	lda #$40
	jsr cb1
	lda #<(WIN + 66 * 13)
	sta ct
	lda #>(WIN + 66 * 13)
	sta ct + 1
	lda #3
	sta crk
	lda mhi
	and #$F0
	sta .op+1
	lda cdm                 ; the even phase's index (an odd dm without the odd set: one back; dm 1: one on)
	lsr a
	bne *+4
	lda #1
	sta .ad+1
.r:	lda ct
	sta .l+1
	sta .l2+1
	sta .h+1
	sta .h2+1
	inc .h+1
	inc .h2+1
	lda ct + 1
	sta .l+2
	sta .l2+2
	sta .h+2
	sta .h2+2
	lda $1A10
	beq .n
	sta ct + 2
.e:	ldy $1A10
	lda cos
	bpl .od
	lda $1A10
	clc
.ad:	adc #0
.l:	sta WIN,y
	lda $1A10
	adc #0
.h:	sta WIN + 1,y
	lda $1A10               ; (the odd rank)
	bra .z
.od:	lda $1A10               ; (the group's words skipped)
	lda $1A10
	ldx $1A10
	lda OTL,x
.l2:	sta WIN,y
	lda OTH,x
.op:	ora #0
.h2:	sta WIN + 1,y
.z:	dec ct + 2
	bne .e
.n:	jsr cpnext
	dec crk
	bne .r
	rts
cupl:	ldx cs
	lda ctl,x
	cmp cxl
	bne .go
	lda cth,x
	cmp cxh
	bne .go
	jmp .od
.go:	ldy #0
	jsr clb
	jsr cb1
	lda $1A10
	beq .ud
	sta crk
	ldy #3
	jsr clb
	jsr cb1
	lda ck                  ; + 32 (k - 1)
	dec a
	asl a
	asl a
	asl a
	asl a
	asl a
	sta cuo
	lda cs                  ; MAWR: ($680 + 64 s) * 16, the tiles in a row
	asl a
	asl a
	clc
	adc #$68
	sta ct + 1
	stz ct
	lda #$40
	tam #4
	lda crk
	sta cun
	jsr cupr
.ud:	ldx cs
	lda cxl
	sta ctl,x
	lda cxh
	sta cth,x
.od:	ldx cos                 ; the odd images
	bmi .xx
	lda ctl + 2
	cmp cxl
	bne .o2
	lda cth + 2
	cmp cxh
	bne .o2
.xx:	jmp .x
.o2:	ldy #0
	jsr clb
	jsr cb1
	lda $1A10
	lda $1A10
	beq .oe
	sta crk
	ldy #3
	jsr clb
	lda #$C0
	jsr cb1
	lda cdm                 ; + 32 (d - 1)
	dec a
	asl a
	asl a
	asl a
	asl a
	asl a
	sta cuo
	lda #$40
	tam #4
	stz ct + 2              ; the odd rank i: its tile OT i (MAWR again where the runs break)
	lda #$FF
	sta ct + 3
.o:	ldx ct + 2
	lda OTL,x
	cmp ct + 3
	beq .oc
	asl a                   ; MAWR = OT * 16
	sta ct
	lda OTH,x
	rol a
	asl ct
	rol a
	asl ct
	rol a
	asl ct
	rol a
	sta ct + 1
	lda #1
	sta cun
	jsr cupr
	bra .on
.oc:	lda #1                  ; (the next tile of the run: no MAWR)
	sta cun
	jsr cupn
.on:	ldx ct + 2
	lda OTL,x
	inc a
	sta ct + 3
	inc ct + 2
	lda ct + 2
	cmp crk
	bne .o
.oe:	lda cxl
	sta ctl + 2
	lda cxh
	sta cth + 2
.x:	lda #BANDT
	tam #4
	rts
; cun tiles (cupr: MAWR first; cupn: none) from the addresses port 1 reads (+ cuo), to MAWR ct / ct + 1 and on
cupr:	jsr cumawr
cupn:
.t:	lda $1A10               ; port 0's base: the address + cuo
	clc
	adc cuo
	sta $1A02
	sta .b0+1
	lda $1A10
	adc #0
	sta $1A03
	sta .b1+1
	lda $1A10
	adc #0
	sta $1A04
	sta .b2+1
	lda FRAMES
	sta cfr
.w:	tia $8000, $0002, 32
	lda FRAMES
	cmp cfr
	bne .r
	lda ct                  ; (the next tile's MAWR, kept for a retry)
	clc
	adc #16
	sta ct
	bcc *+5
	inc ct + 1
	dec cun
	bne .t
	rts
.r:	sta cfr                 ; a vblank inside: MAWR and the port again, the tile again
	jsr cumawr
.b0:	lda #0
	sta $1A02
.b1:	lda #0
	sta $1A03
.b2:	lda #0
	sta $1A04
	bra .w
cumawr:	vsel 0
	lda ct
	sta $0002
	lda ct + 1
	sta $0003
	vsel 2
	rts
; the odd set's tile tables from its runs
cotgen:	clx
	cly
.r:	lda ORUN,y
	sta ct
	lda ORUN + 1,y
	sta ct + 1
	lda ORUN + 2,y
	sta ct + 2
.t:	lda ct
	sta OTL,x
	lda ct + 1
	sta OTH,x
	inx
	inc ct
	bne *+5
	inc ct + 1
	dec ct + 2
	bne .t
	iny
	iny
	iny
	cpy #ORN
	bne .r
	rts

; ================================================================ (quarry-bridge-band2) the ready gate's steps in this overlay (cidle, the band's idle)
ccam:	.db 0
c7s:	.db 0           ; c7ld: 0 the copy, 1 the sum's pages
c7a:	.db 0           ; the sum so far (low, high), its next page
c7x:	.db 0
c7p:	.db 0
c7ld:	lda pw_state            ; (held for the store: the band's groups are in VRAM)
	cmp #6
	bne .no
	lda #30
	jsr cclk
	bcc .no
	jsr .w
	php
	jsr cspin
	plp
	rts
.w:	lda mready
	beq *+5
	jmp c7go
	lda CAMX                ; the mid groups composed first (mcomp, a step an idle: it runs for the band's passes only), with the camera
	cmp ccam
	sta ccam
	bne .no
	lda act
	pha
	lda #2
	sta act
	jsr cmu_r
	pla
	sta act
.no:	clc
	rts
c7go:	tma #4
	pha
	ldx cov
	lda CVB,x
	tam #4
	lda CVO,x
	sta .of + 1
	lda CVA,x
	sta .ah + 1
	lda CVN,x
	sta .np + 1
	lda CVE,x
	sta .ep + 1
	lda c7s
	bne .sum
	stz $1A35
.of:	lda #$10
	sta $1A36
	lda #<(C7RAM + $2000)
	sta .c+3
.ah:	lda #>(C7RAM + $2000)
	sta .c+4
	sta c7p
.np:	ldx #C7LEN / 32
.c:	tai $1A30, C7RAM + $2000, 32
	lda .c+3
	clc
	adc #32
	sta .c+3
	bcc *+5
	inc .c+4
	dex
	bne .c
	stz $1A36               ; (port 3's offset as the preload left it)
	stz c7a
	stz c7x
	inc c7s
	clc
	bra .out
.sum:	lda c7p
	sta .p+2
	lda #4
	sta ct
	lda c7a
	ldx c7x
	cly
.l:	clc
.p:	adc C7RAM + $2000,y
	bcc .n
	inx
.n:	iny
	bne .l
	sta c7a
	inc .p+2
	lda .p+2
.ep:	cmp #>(C7RAM + $2000 + C7LEN)
	beq .end
	lda c7a
	dec ct
	bne .l
	stx c7x
	lda .p+2
	sta c7p
	clc
	bra .out
.end:	ldy cov
	lda c7a
	cmp CVSL,y
	bne .bad
	txa
	cmp CVSH,y
	bne .bad
	stz c7s                 ; (the next overlay's copy)
	sec
	bra .out
.bad:	jsr cfail
.out:	pla
	tam #4
	rts
cmu6:	tma #4
	pha
	lda #4
	sta rmng
.g:	lda mci
	cmp rnpair
	bcc .c
	inc mready
	                        ; (and the odd set's tiles copied out now, not in the band's first odd pass)
	lda cocp
	bne *+5
	jsr cocopy
	jmp .x
.c:	ldy #0                  ; copied out (mgxfer: group mci; MPR3 kept)
	jsr mgxfer
	inc mcop
	lda #$40
	tam #4
	lda mci                 ; image 7 g + 1: IMG + 32 (7 g + 1)
	sta rmwi
	stz rmwi + 1
	asl a
	rol rmwi + 1
	asl a
	rol rmwi + 1
	asl a
	rol rmwi + 1
	sec
	sbc rmwi
	sta rmwi
	bcs *+5
	dec rmwi + 1
	inc rmwi
	bne *+5
	inc rmwi + 1
	ldx mci                 ; MAWR: the group's first tile * 16
	lda MGL,x
	sta ct
	lda MGH,x
	asl ct
	rol a
	asl ct
	rol a
	asl ct
	rol a
	asl ct
	rol a
	sta ct + 1
	lda #3
	sta rmki
.i:	lda rmwi + 1             ; port 0 at $15:D000 + 32 rmwi
	sta rmti
	lda rmwi
	lsr rmti
	ror a
	lsr rmti
	ror a
	lsr rmti
	ror a
	clc
	adc #IMGM
	tax
	lda rmti
	adc #CR3H
	tay
	lda rmwi
	asl a
	asl a
	asl a
	asl a
	asl a
	jsr cup1
	lda ct                  ; the next tile, the image two on (d + 2)
	clc
	adc #16
	sta ct
	bcc *+5
	inc ct + 1
	inc rmwi                ; (quarry-band1-lastcells: the carry from the first step too: group 36's d = 6 is image 257, which the old
	bne *+5                 ; order read as image 1, group 0's d = 2: a wrong mid cell at every odd period's k = 2. 7 g + 1 / + 3 is
	inc rmwi + 1            ; never $FE for g < 45, so the second step never carries)
	inc rmwi
	dec rmki
	bne .i
	inc mci
	dec rmng
	beq .x
	jmp .g
.x:	pla
	tam #4
	rts
rmng:	.db 0
rmki:	.db 0
rmti:	.db 0
rmwi:	.dw 0
cocopy:	lda cotok
	bne .t0
	jsr cotgen
	inc cotok
.t0:	lda #OCPM
	sta ct + 1
	stz ct
	clx
.t:	phx
	lda ct
	ldx ct + 1
	ldy #KTH
	jsr cbase
	plx
	lda OTL,x
	asl a
	sta ct + 2
	lda OTH,x
	rol a
	asl ct + 2
	rol a
	asl ct + 2
	rol a
	asl ct + 2
	rol a
	sta ct + 3
.r:	lda FRAMES
	pha
	vsel 1
	lda ct + 2
	sta $0002
	lda ct + 3
	sta $0003
	vsel 2
	tai $0002, ibuf, 32
	pla
	cmp FRAMES
	bne .r
	tia ibuf, $1A00, 32
	lda ct
	clc
	adc #32
	sta ct
	bcc *+5
	inc ct + 1
	inx
	cpx #ONUM
	bne .t
	inc cocp
	rts
; (quarry-bridge-setup, vector 2) the third overlay, by the same steps (cov 1)
c8ld:	lda #30
	jsr cclk
	bcc .no
	lda #1
	sta cov
	jsr c7go
	php
	jsr cspin
	plp
	rts
.no:	clc
	rts
cov:	.db 0
CVB:	.db C7BANK, C8BANK
CVO:	.db $10, $20
CVA:	.db >(C7RAM + $2000), >(C8RAM + $2000)
CVN:	.db C7LEN / 32, C8LEN / 32
CVE:	.db >(C7RAM + $2000 + C7LEN), >(C8RAM + $2000 + C8LEN)
CVSL:	.db <C7SUM, <C8SUM
CVSH:	.db >C7SUM, >C8SUM
cswitch:	lda pw_state
	cmp #6
	bne .no
	lda cocp
	bne .s
	lda #30
	jsr cclk
	bcc .no
	jsr cocopy
	jmp cspin
.no:	clc
	rts
.s:	lda #1
	sta card
	lda #4
	sta pw_state
	lda #$4C
	jsr cpat
	sec
	rts
