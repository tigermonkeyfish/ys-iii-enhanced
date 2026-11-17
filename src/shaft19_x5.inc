	.if ORD = 0               ; (r19-leftout-order: the fifth bank's kord makes the record and the leave-out)
xcellh:	lda pxr                 ; kcg: bit 0 off the grid in X, bit 1 in Y (YSM)
	and #6
	cmp #1
	cla
	rol a
	.if YSM
	sta t0
	lda pyr
	and #6
	cmp #1
	cla
	rol a
	asl a
	ora t0
	.endif
	cmp kcg
	beq .s
	sta kcg
	lda #$FF
	sta kch                 ; (the grid changed: the record again)
.s:	lda p0l
	cmp kcl
	bne .r
	lda p0h
	cmp kch
	bne .r
	rts
.r:	jsr kcellh
	.if XMRG
	lda kcg
	bne .m
	.endif
	rts
.m:	ldx #7                  ; the cell's own counts and visible blocks kept (n0, V0 in E's place)
.k:	lda kn,x
	sta xn0,x
	lda kvl,x
	sta xel,x
	lda kvh,x
	sta xeh,x
	dex
	bpl .k
	lda kcg                 ; the next cell in X (+ 1), in Y (+ 64: the next cell row), both (+ 65)
	lsr a
	bcc .m1
	lda #1
	jsr xmrg
.m1:	lda kcg
	and #2
	beq .m2
	lda #64
	jsr xmrg
	lda kcg
	cmp #3
	bne .m2
	lda #65
	jsr xmrg
.m2:	ldx #7                  ; E = V - V0; the counts again
.b:	lda xel,x
	eor #$FF
	and kvl,x
	sta xel,x
	lda xeh,x
	eor #$FF
	and kvh,x
	sta xeh,x
	ldy kvl,x               ; (the counts from the set-up's table XPOPT, DB_NEAR at MPR3)
	lda XPOPT,y
	ldy kvh,x
	clc
	adc XPOPT,y
	sta kn,x
	dex
	bpl .b
	rts
; the record of the cell p0 + A ORed into kh (visible blocks, group masks)
xmrg:	clc
	adc p0l
	sta t0
	lda p0h
	adc #0
	and #$0F
	sta t1
	lda t0
	and #63
	tax
	lda t0
	asl a
	rol t1
	asl a
	rol t1
	ldy t1
	clc
	lda krowl,y
	adc kcoll,x
	sta $1A02
	lda krowm,y
	adc kcolh,x
	sta $1A03
	lda krowh,y
	adc #0
	sta $1A04
	tai $1A00, kh2, 24
	tai $1A00, kh2 + 24, 24
	ldx #15
.v:	lda kgv,x
	ora kh2 + 32,x
	sta kgv,x
	cpx #8
	bcs .w
	lda kvl,x
	ora kh2 + 8,x
	sta kvl,x
	lda kvh,x
	ora kh2 + 16,x
	sta kvh,x
.w:	dex
	bpl .v
	rts
; after kleave, off the grid: a band whose D passes n0 (its own order's length) leaves out cum[n0] and the first D - n0 blocks of E
xleave:	lda kcg
	bne .g
	rts
.g:	lda kcpm
	sta $1A03
	lda kcph
	sta $1A04
	clx
.b:	lda kD,x
	sec
	sbc xn0,x
	beq .n
	bcc .n
	sta t2                  ; blocks of E to leave out
	stz t0
	stz t1
	lda xn0,x
	beq .e
	txa                     ; cum[n0] at 32 b + 2 n0 - 2
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc xn0,x
	adc xn0,x
	sec
	sbc #2
	sta $1A02
	lda $1A00
	sta t0
	lda $1A00
	sta t1
.e:	lda xel,x               ; the first t2 of E: its low byte's bits, then its high byte's
	jsr .t
	ora t0
	sta t0
	lda xeh,x
	jsr .t
	ora t1
	sta t1
	txa
	asl a
	tay
	lda t0
	sta out,y
	eor #$FF
	and kvl,x
	sta kkp,x
	lda t1
	sta out+1,y
	eor #$FF
	and kvh,x
	sta kkp+8,x
.n:	inx
	cpx #8
	bne .b
	rts
.t:	sta t3                  ; A: E's byte -> its first t2 bits (lowest first), t2 less them
	stz t4
.t1:	lda t2
	beq .tx
	lda t3
	beq .tx
	dec a
	eor #$FF
	and t3                  ; the lowest set bit
	tsb t4
	eor t3
	sta t3
	dec t2
	bra .t1
.tx:	lda t4
	rts
	.endif
kcg:	.db 0           ; 1: the record in kh is the merged one (off the grid)
kh2:	.ds 48
xn0:	.ds 8
xel:	.ds 8
xeh:	.ds 8
	.if HOLD
khold:	lda FRAMES
	cmp pxf
	beq .f
	inc nlt                 ; (the blank already passed: late, not held)
	bra .n
.f:
	lda TIMER
	and #$7F
	sta t0
	lda pxt
	and #$7F
	sec
	sbc t0
	bcs .p
	adc #116
.p:	cmp xemx
	bcc .q
	sta xemx
.q:	clc
	adc #XEST
	cmp #XLIM
	bcs .h
.n:	clc
	rts
.h:	dec $339F
	lda SATPAGE
	eor #1
	sta SATPAGE
	inc nhold
	bne .x
	inc nhold+1
.x:	sec
	rts
nhold:	.dw 0
nlt:	.db 0
xemx:	.db 0
	.endif
