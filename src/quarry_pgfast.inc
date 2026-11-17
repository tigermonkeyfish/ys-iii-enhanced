PGH        = $18
	.org cidle
pgfast:	lda cst
	beq .n
	bmi .x
	ldy #2                  ; (quarry-seams) the visit on its store: the seams' idle (quarry_cards.inc: sidle)
	jmp c7tr
.x:	rts
.n:	lda pw_state            ; (a window up: wait)
	cmp #5
	beq .x
	tma #3
	pha
	tma #4
	pha
	lda #C8BANK
	tam #4
	jsr pgload
	pla
	tam #4
	pla
	tam #3
	bcc .ok
	jmp cfail
.ok:	cly                     ; (quarry-seams) the visit's variant, band 1 on its store, cst 5, brst 1: sinit
	jmp c7tr
; X pieces of 64 bytes from port 3 to A:00 (interrupts between pieces; quarry-seams: 64, not 32: the seams' image is 1,792 bytes more)
pgcp:	sta .t + 4
	stz .t + 3
.t:	tai $1A30, C6RAM, 64
	lda .t + 3
	clc
	adc #64
	sta .t + 3
	bcc *+5
	inc .t + 4
	dex
	bne .t
	rts
pgaend:
	.if (pgaend > bready)
	.fail
	.endif

	.org q8hdr
pgload:	cla
	clx
	ldy #PGH
	jsr cb1
	lda #C6BANK
	tam #3
	tai $1A10, C6RAM, 32    ; the block's head, in the overlay's place for a moment
	ldx #6
.m:	lda C6RAM,x
	cmp pgk,x
	bne .bad
	dex
	bpl .m
	lda C6RAM + 7
	sta rnpair
	clx
.l:	cly
.c:	lda nlo,y
	cmp C6RAM + 16,x
	bne .n
	inx
	iny
	cpy #4
	bne .c
	lda flo
	cmp C6RAM + 16,x
	bne .n
	lda fhi
	cmp C6RAM + 17,x
	beq .f
.n:	txa
	and #8
	eor #8
	tax
	bne .l
.bad:	sec
	rts
.f:	txa
	and #8
	sta rtag                ; (the resident's builder variables are free in such a power-on)
	jsr ccopy               ; the first overlay's first page and its sum (port 3 at C6CH:0000; MPR3 = C6BANK)
	bne .bad
	lda #>(C6RAM + 256)
	ldx #(C6LEN - 256) / 64
	jsr pgcp
	stz $1A35               ; (quarry-seams) the seams' image: C6CH:4000, into C7BANK's tail (at MPR3 from here: pgfast puts it back);
	lda #$40                ; (quarry-finish) its first two pages only (sinit, srest and sidle's head): the rest of it and the fourth
	sta $1A36               ; image come in the idles after this one (quarry_cards.inc: srest); all of them here cost a frame of
	lda #C7BANK             ; black on three entries
	tam #3
	lda #>C7RAM
	ldx #512 / 64
	jsr pgcp
	stz $1A36               ; (port 3's offset as the preload left it)
	lda smk
	cmp #'S'
	bne .bad2
	clc                     ; (the visit's variant and switches: sinit, pgfast's next step)
	rts
.bad2:	sec
	rts
pgk:	.db 'Y', '3', 'P', 'G', 1, <CBKEY, >CBKEY
pgbend:
	.if (pgbend > cup1)
	.fail
	.endif
	.if (CR3H & 8) | (CR2H & 8) | (LB2H & 8) | (<C6RAM) | (<C8RAM) | (<C7RAM) | (<SLEN) | (C6LEN & 63) | (C9LEN & 63) | (SLEN & 63) | (CR3H - 4 - CR2H) | (CR3H - 4 - LB2H)
	.fail
	.endif
