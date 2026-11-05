; The data proof the module carries: `dgen` from the stub says whether another
; module ran, a hint; this signature over one page ($200-$2FF) of each of the module's data banks is the proof.
; The module's `leave` ends with `jsr sigsave`; its modinit starts with `+sigchk` semantics: A = dgen on entry,
;     jsr sigkeep / bcc .keep (carry clear: dgen and the bytes both match, the data stands, return)
; Needs: `sigbanks` (.db banks, 0) in the module. MPR6 is saved and restored.
sdgen:	.db 0
ssum:	.db 0, 0
sdone:	.db 0                   ; a signature has been saved since the last rebuild

sigcalc:	tma #6
	pha
	stz sumr
	stz sumr + 1
	clx
.b:	lda sigbanks,x
	beq .e
	tam #6
	cly
.p:	lda sumr
	clc
	adc $C200,y
	sta sumr
	lda sumr + 1
	adc sumr
	sta sumr + 1
	iny
	bne .p
	inx
	bra .b
.e:	pla
	tam #6
	rts
sumr:	.db 0, 0

sigsave:	jsr sigcalc
	lda sumr
	sta ssum
	lda sumr + 1
	sta ssum + 1
	lda #1
	sta sdone
	rts

; A = dgen. Carry clear: same generation and same bytes, nothing to do. Carry set: rebuild, dgen stored.
sigkeep:	cmp sdgen
	sta sdgen
	bne .no
	lda sdone
	beq .no
	jsr sigcalc
	lda sumr
	cmp ssum
	bne .no
	lda sumr + 1
	cmp ssum + 1
	bne .no
	clc
	rts
.no:	stz sdone
	sec
	rts

	.ifndef OWNBATCLEAN      ; (a module with batrest shares its loop: redmont.asm)
batclean:	stz t0                  ; the word's address
	stz t1
	lda #1                  ; MARR 0
	sta <VDCREG
	sta $0000
	st1 #0
	st2 #0
	lda #2                  ; VRR: each high-byte read moves on
	sta <VDCREG
	sta $0000
.w:	ldx $0002
	lda $0003
	and #7
	cmp #7
	bne .nx
	cpx #$72
	bcc .nx
	stz <VDCREG             ; MAWR = this word
	stz $0000
	lda t0
	sta $0002
	lda t1
	sta $0003
	lda #2                  ; VWR: word 0
	sta <VDCREG
	sta $0000
	st1 #0
	st2 #0
	lda #1                  ; MARR = the next word
	sta <VDCREG
	sta $0000
	lda t0
	clc
	adc #1
	sta $0002
	lda t1
	adc #0
	sta $0003
	lda #2
	sta <VDCREG
	sta $0000
.nx:	inc t0
	bne .w
	inc t1
	lda t1
	cmp #>(64 * 36)
	bne .w
	lda t0
	bne .w
	rts
	.endif
