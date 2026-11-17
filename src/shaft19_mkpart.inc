mkpart:
	lda #>mid
	sta .tl+2
	lda #>(mid + 1)
	sta .tr+2
	lda #>(mid + 32)
	sta .bl+2
	lda #>(mid + 33)
	sta .br+2
	cly                     ; block
	clx                     ; offset in this half of the map (4 bands a half)
.l:
.tl:	lda mid,x
	sta t0
.tr:	lda mid + 1,x
	sta t1
.bl:	lda mid + 32,x
	sta t2
.br:	lda mid + 33,x
	sta t3
	stz t4                  ; the six equality bits: 0=1, 0=2, 0=3, 1=2, 1=3, 2=3 (bit 5 first)
	lda t0
	cmp t1
	jsr eqb
	lda t0
	cmp t2
	jsr eqb
	lda t0
	cmp t3
	jsr eqb
	lda t1
	cmp t2
	jsr eqb
	lda t1
	cmp t3
	jsr eqb
	lda t2
	cmp t3
	jsr eqb
	phx
	ldx t4
	lda p6,x
	plx
	sta bpart,y
	iny
	inx
	inx
	txa
	and #$1F
	bne .l                  ; (16 blocks of the band)
	clc
	txa
	adc #32                 ; (past the band's second row)
	tax
	bne .l                  ; (4 bands)
	inc .tl+2
	inc .tr+2
	inc .bl+2
	inc .br+2
	cpy #128
	bne .l
	rts
eqb:	php                     ; t4 = t4 << 1 | Z
	pla
	lsr a
	lsr a
	rol t4
	rts
