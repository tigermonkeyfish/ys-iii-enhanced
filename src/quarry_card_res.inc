cb1:	sta $1A12               ; port 1's base = A / X / Y
	stx $1A13
	sty $1A14
	rts
rtag:	.dw 0           ; the store this power-on built (quarry_card7.inc): its layout tag and good, its records' content tag and good, the key
rvalid:	.db 0           ; table's generation, the images stored, the builds (the rank table's stamps)
rctag:	.dw 0
rcvalid:	.db 0
rgen:	.db 0
rnimg:	.dw 0
rbld:	.db 0
rnpair:	.db 0           ; the band mid pairs the store holds images for
brst:	.db 0           ; (quarry-bridge-store) the bridge's store (region 1) this visit: 0 not yet, 1 ready, $FF given up
q8vb:	.db 0
q8vf:	.db 0
r2valid:	.db 0           ; ... a store this power-on built or found, and its layout tag (band 1's store's: rtag)
r2tag:	.dw 0
q8hdr:	cla
	clx
	ldy #R2H
	jsr cb1
	tai $1A10, q8hb, 16
	ldx #6
.c:	lda q8hb,x
	cmp Q8HM,x
	bne .no
	dex
	bpl .c
	lda q8hb + 7
	cmp rtag
	bne .no
	lda q8hb + 8
	cmp rtag + 1
	bne .no
	lda q8hb + 9
	sta q8ni
	lda q8hb + 10
	sta q8ni + 1
	cmp #$10
	bcs .no
	jsr q8sum
	lda q8s
	cmp q8hb + 12
	bne .no
	lda q8s + 1
	cmp q8hb + 13
	bne .no
	clc
	rts
.no:	sec
	rts
q8maps:	clx
.m:	stx q8t
	lda Q8SL,x
	sta .s0+1
	inc a
	sta .s1+1
	lda Q8DL,x
	sta .d0+1
	inc a
	sta .d1+1
	lda Q8DH,x
	sta .d0+2
	sta .d1+2
	txa
	asl a
	asl a
	asl a
	asl a
	sta q8t + 1
	tax
	stz q8M,x
	ldy #2
.i:	ldx #30
.j:
.s0:	lda $3C00,y
.d0:	cmp $3C00,x
	bne .n
.s1:	lda $3C01,y
.d1:	eor $3C01,x
	lsr a
	bcc .f
.n:	dex
	dex
	bne .j
.f:	txa
	lsr a
	pha
	tya
	lsr a
	clc
	adc q8t + 1
	tax
	pla
	sta q8M,x
	iny
	iny
	cpy #32
	bne .i
	ldx q8t
	inx
	cpx #5
	bne .m
	stz q8M + 32 + 1
	lda q8M + 32 + 2
	bne .r
	lda #15
	sta q8M + 32 + 2
.r:	rts

Q8SL:	.db $00, $00, $00, $20, $40
Q8DL:	.db $C0, $E0, $80, $80, $80
Q8DH:	.db $3C, $3C, $3C, $3C, $3C
	.if PROOF
; a region's header through port 1 (X = region): magic, id, format, key = C6SUM (cent's operands), its payload length; the sum started
cvbeg:	stz cvok
	lda RGL,x
	sta $1A12
	lda RGM,x
	sta $1A13
	lda RGH,x
	sta $1A14
	tai $1A10, chdr, 16
	lda chdr
	cmp #'Y'
	bne .no
	lda chdr + 1
	cmp #'3'
	bne .no
	lda chdr + 2
	cmp #'C'
	bne .no
	txa
	cmp chdr + 3
	bne .no
	lda chdr + 4
	cmp #CFMT
	bne .no
	lda chdr + 5
	cmp cent_sl + 1
	bne .no
	lda chdr + 6
	cmp cent_sh + 1
	bne .no
	lda chdr + 7
	sta cvn
	lda chdr + 8
	sta cvn + 1
	lda chdr + 9
	sta cvn + 2
	stz cvs
	stz cvs + 1
	clc
	rts
.no:	sec
	rts
; up to A pages more of the payload summed through port 1 (whole pages but the last); carry set when done (cvok: the sum is right)
cvstep:	sta chdr + 15
.pg:	lda cvn + 1
	ora cvn + 2
	beq .last
	ldy #0
	jsr .sum
	lda cvn + 1
	bne .d
	dec cvn + 2
.d:	dec cvn + 1
	dec chdr + 15
	bne .pg
	clc
	rts
.last:	ldy cvn
	beq .end
	jsr .sum
	stz cvn
.end:	lda cvs
	cmp chdr + 10
	bne .bad
	lda cvs + 1
	cmp chdr + 11
	bne .bad
	inc cvok
.bad:	sec
	rts
.sum:	lda cvs                 ; Y bytes (0: 256)
	ldx cvs + 1
.l:	clc
	adc $1A10
	bcc .n
	inx
.n:	dey
	bne .l
	sta cvs
	stx cvs + 1
	rts
csbeg:	stx chdr + 3
	lda #16                 ; the payload's start: the header + 16
	clc
	adc RGL,x
	sta $1A12
	lda RGM,x
	adc #0
	sta $1A13
	lda RGH,x
	adc #0
	sta $1A14
	lda cvn
	sta chdr + 7
	lda cvn + 1
	sta chdr + 8
	lda cvn + 2
	sta chdr + 9
	stz cvs
	stz cvs + 1
	rts
csend:	lda cvs
	sta chdr + 10
	lda cvs + 1
	sta chdr + 11
	lda #'Y'
	sta chdr
	lda #'3'
	sta chdr + 1
	lda #'C'
	sta chdr + 2
	lda #CFMT
	sta chdr + 4
	lda cent_sl + 1
	sta chdr + 5
	lda cent_sh + 1
	sta chdr + 6
	stz chdr + 12
	stz chdr + 13
	stz chdr + 14
	stz chdr + 15
	lda RGL,x
	sta $1A02
	lda RGM,x
	sta $1A03
	lda RGH,x
	sta $1A04
	tia chdr, $1A00, 16
	rts

	.endif
cup1:	jsr cbase
	sta .b+1
	stx .b+3
	sty .b+5
.t:	lda FRAMES
	sta cfr
	vsel 0
	lda ct
	sta $0002
	lda ct + 1
	sta $0003
	vsel 2
	tia $8000, $0002, 32
	lda FRAMES
	cmp cfr
	beq .x
.b:	lda #0                  ; (the port's base again)
	ldx #0
	ldy #0
	jsr cbase
	bra .t
.x:	rts
cores:	lda cocp
	beq .x
	tma #4
	pha
	lda #$40
	tam #4
	stz ct + 2              ; port 0 at $17:F000 + 32 i
	lda #OCPM
	sta ct + 3
	clx
.t:	phx
	lda OTL,x
	asl a
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
	lda ct + 2
	ldx ct + 3
	ldy #KTH
	jsr cup1
	lda ct + 2
	clc
	adc #32
	sta ct + 2
	bcc *+5
	inc ct + 3
	plx
	inx
	cpx #ONUM
	bne .t
	stz cocp
	lda #$FF
	sta ctl + 2
	pla
	tam #4
.x:	rts
cmu_r:	lda #GUPMAX             ; (band_upl's cap back: cpass sets it per pass, the idle's uploads take the full cap)
	sta bugm + 1
	lda card                ; (1: the store is ready; $80, held for it: mcomp)
	cmp #1
	beq *+5
	jmp mcomp
	lda mready
	beq *+3
	rts
	ldy #16
	jmp c6tr
