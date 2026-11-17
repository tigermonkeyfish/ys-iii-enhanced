
xrail:	.ds 16
xpm:	.ds 16
xhist:	.ds 16
	.ds 8           ; (xhist + 16 .. 23: unused; + 8 .. 15 the mask row's words, after the histograms)
xnx:	.db 0
xq0:	.db 0           ; the mask image's column of left-bar column 0 (0, or 15 when mirrored)
xk:	.db 0
xt0:	.db 0
xt1:	.db 0
xt2:	.db 0
xbb:	.ds 4

xset1:	lda #DB_X
	tam #4
	lda #$80
	sta .z+2
.zp:	clx
.z:	stz $8000,x
	inx
	bne .z
	inc .z+2
	lda .z+2
	cmp #$88
	bne .zp
	jsr rinit               ; the slot tables from the list (index j = i - 512): bars j 0-16, composite cache k = j - 16 (j 17-63) and
.w:	jsr rnext               ; j - 20 (j 68-116), backdrop cache k = j - 116 (j 117-219); j 64-67: the transparent tile and the clones
	bcs .wd
	lda cih
	cmp #2
	bcc .w
	ldx cil
	cpx #17
	bcs .w1
	.if XBAR = 0
	cpx #16
	beq .b16
	lda tl
	sta XD_BTL + 104,x
	lda th
	sta XD_BTH + 104,x
	bra .w
.b16:	ldx #16
.bl:	lda tl
	sta XD_BRL,x
	lda th
	sta XD_BRH,x
	dex
	bpl .bl
	bra .w
	.else
	lda tl
	sta XD_BRL,x
	lda th
	sta XD_BRH,x
	bra .w
	.endif
.w1:	txa
	cpx #64
	bcs .w2
	sbc #15                 ; (carry clear: - 16)
	bra .wc
.w2:	cpx #68
	bcc .w
	cpx #117
	bcs .w3
	sbc #19                 ; (carry clear: - 20; r19-exit-leftover: was SBC #20, k = j - 21: k 47 lost to j 68, k 96 never written
	                        ; (stale RAM: the plug's pool and the exit compare read it), the stand-down's copy one slot off from k 48)
.wc:	tax
	lda tl
	sta XD_CTL,x
	lda th
	sta XD_CTH,x
	bra .w
.w3:	sbc #116
	tax
	lda tl
	sta XD_BTL,x
	lda th
	sta XD_BTH,x
	bra .w
.wd:
	; the mask's image: mask 0's pattern (tile = pattern word * 2), its four 16 x 16 cells 8 tiles apart, 64 words each -> XD_BUF
	lda msav+4
	and #$FE
	sta tl
	lda msav+5
	sta th
	asl tl
	rol th
	stz xk
.mc:	jsr ttaddr
	jsr vmarr
	lda xk                  ; dest: XD_BUF + 128 cell (shaft19-join-020: the TAI's destination operand is at +3 / +4; +1 / +2, its
	lsr a
	cla
	ror a
	sta .d0+3
	lda xk
	lsr a
	clc
	adc #>XD_BUF
	sta .d0+4
	ldy #16
.md:
.d0:	tai $0002, XD_BUF, 8
	lda .d0+3
	clc
	adc #8
	sta .d0+3
	dey
	bne .md
	lda tl
	clc
	adc #8
	sta tl
	bcc .m1
	inc th
.m1:	inc xk
	lda xk
	cmp #4
	bne .mc
	; the left bar's column q is the image's column q, or 15 - q when mask 0 is mirrored against its side (x flip xor right side)
	lda msav+7
	lsr a
	lsr a
	lsr a
	eor mside
	and #1
	beq .nf
	lda #15
.nf:	sta xq0
	stz xk                  ; q
.col:	ldx #15
.hz:	stz xhist,x
	dex
	bpl .hz
	lda xk
	eor xq0                 ; the image's column xi: byte +1 (high: pixels 0-7) when xi < 8, bit 7 - (xi & 7)
	tax
	and #7
	tay
	lda .bm,y
	sta xt1
	cpx #8
	cla
	bcs .lo
	inc a
.lo:	sta xt0                 ; byte offset within the row's word
	ldy #0                  ; R = 16 c + y (cell c 0-3, row y 0-15): XD_BUF + 128 c + 2 y + xt0, planes + 32 p
.rw:	tya
	and #$20
	beq .g0
	lda #1
.g0:	clc
	adc #>XD_BUF
	sta .r0+2
	sta .r1+2
	sta .r2+2
	sta .r3+2
	tya
	and #$10
	asl a
	asl a
	asl a
	sta xt2
	tya
	and #$0F
	asl a
	ora xt2
	ora xt0
	tax
	stz xt2                 ; the colour: planes 3 .. 0 shifted in
.r3:	lda XD_BUF + 96,x
	and xt1
	cmp #1
	rol xt2
.r2:	lda XD_BUF + 64,x
	and xt1
	cmp #1
	rol xt2
.r1:	lda XD_BUF + 32,x
	and xt1
	cmp #1
	rol xt2
.r0:	lda XD_BUF,x
	and xt1
	cmp #1
	rol xt2
	ldx xt2
	inc xhist,x
	iny
	cpy #64
	bne .rw
	ldx #0                  ; the commonest (the first of equal counts)
	ldy #1
.mx:	lda xhist,y
	cmp xhist,x
	bcc .m2
	beq .m2
	tya
	tax
.m2:	iny
	cpy #16
	bne .mx
	txa
	ldx xk
	sta xrail,x
	inx
	stx xk
	cpx #16
	beq .pm
	jmp .col
.bm:	.db $80, $40, $20, $10, $08, $04, $02, $01
.pm:
	.if XBAR = 0
	ldx #2
.bk:	lda $3C00 + 480,x
	ora $3C00 + 481,x
	beq .bf
	inx
	inx
	cpx #32
	bne .bk
	lda #$40                ; (none: refused)
	tam #4
	sec
	rts
.bf:	txa
	lsr a
	ldx #15
.bz:	sta xrail,x
	dex
	bpl .bz
	.endif
	ldx #15
.pz:	stz xpm,x
	dex
	bpl .pz
	lda #12
	sta xnx
	ldy #10
.pc:	ldx xrail,y
	lda xpm,x
	bne .pn
	lda xnx
	cmp #16
	bcc .po
	lda #$40
	tam #4
	sec
	rts
.po:	sta xpm,x
	inc xnx
.pn:	iny
	cpy #16
	bne .pc
	ldx #31
.pb:	lda $3C00,x
	sta XPALB,x
	dex
	bpl .pb
	ldx #15
.pf:	lda xpm,x
	beq .pg
	asl a
	tay
	txa
	asl a
	phx
	tax
	lda $3C00 + 480,x
	sta XPALB,y
	lda $3C00 + 481,x
	sta XPALB + 1,y
	plx
.pg:	dex
	bpl .pf
	jsr vwait
	php
	sei
	stz $0402
	stz $0403
	tai $0404, XD_PALS, 32
	lda #$F0
	sta $0402
	stz $0403
	tai $0404, XD_PALS + 32, 32
	ldx #15
.vf:	lda xpm,x
	beq .vg
	asl a
	tay
	txa
	asl a
	phx
	tax
	lda XD_PALS + 32,x
	sta XD_PALS,y
	lda XD_PALS + 33,x
	sta XD_PALS + 1,y
	plx
.vg:	dex
	bpl .vf
	lda #XPAL * 16
	sta $0402
	stz $0403
	tia XD_PALS, $0404, 32
	plp
	.if XBAR = 0
	lda #16
	sta xk
	.else
	stz xk
	.endif
.bt:	lda xk
	asl a
	asl a
	asl a
	tay                     ; 8 k
	stz xbb
	stz xbb+1
	stz xbb+2
	stz xbb+3
	lda #8
	sta xt0
.bp:	jsr xqk                 ; X = q of tile xk, pixel 8 - xt0
	lda xrail,x
	lsr a
	rol xbb
	lsr a
	rol xbb+1
	lsr a
	rol xbb+2
	lsr a
	rol xbb+3
	iny
	dec xt0
	bne .bp
	ldx #0                  ; cbuf: rows 0-7, planes 0 / 1 at 2 y, 2 y + 1; planes 2 / 3 at 16 + 2 y
.br:	lda xbb
	sta cbuf,x
	sta cbuf + 16,x
	lda xbb+1
	sta cbuf + 1,x
	sta cbuf + 17,x
	inx
	inx
	cpx #16
	bne .br
	ldx #0
.b3:	lda xbb+2
	sta cbuf + 16,x
	lda xbb+3
	sta cbuf + 17,x
	inx
	inx
	cpx #16
	bne .b3
	ldx xk
	lda XD_BRL,x
	sta tl
	lda XD_BRH,x
	sta th
	jsr wrbuf
	lda xk
	clc
	adc #<512
	sta cil
	lda #>512
	sta cih
	lda #2
	jsr cbi
	tia cbuf, $1A00, 8
	tia cbuf + 8, $1A00, 8
	tia cbuf + 16, $1A00, 8
	tia cbuf + 24, $1A00, 8
	inc xk
	lda xk
	cmp #17
	beq .bte
	jmp .bt
.bte:
	; a4's border words (bcols writes them into columns 0, 1, 34, 35 of both buffers, rows 0-15): the bars at phase 0
	ldy #0
.bw:	lda XD_BRL
	sta bword,y
	lda XD_BRH
	ora #$F0
	sta bword+1,y
	lda XD_BRL+1
	sta bword+2,y
	lda XD_BRH+1
	ora #$F0
	sta bword+3,y
	lda XD_BRL+16
	sta bword+4,y
	lda XD_BRH+16
	ora #$F0
	sta bword+5,y
	lda XD_BRL+2
	sta bword+6,y
	lda XD_BRH+2
	ora #$F0
	sta bword+7,y
	tya
	clc
	adc #8
	tay
	cpy #128
	bne .bw
	ldx #15
.ex:	lda xrail,x
	sta XD_RAIL,x
	lda xpm,x
	sta XD_PM,x
	dex
	bpl .ex
	lda xq0
	sta XD_Q0
	lda #29
	jsr cold4
	lda #$40
	tam #4
	clc
	rts
; the bar tile xk's pixel p = 8 - xt0 -> X = the left bar's column q (k 16: column 34 at phase 0; else phase 2 (k >> 2), kind k & 3)
xqk:	lda #8
	sec
	sbc xt0
	sta xt2                 ; p
	lda xk
	cmp #16
	bne .k
	lda #15
	sec
	sbc xt2
	tax
	rts
.k:	and #$0C
	lsr a
	sta xt1                 ; px
	lda xk
	and #3
	beq .k0
	cmp #2
	beq .k2
	bcs .k3
	lda xt2                 ; 1: 8 + p - px
	clc
	adc #8
	sec
	sbc xt1
	tax
	rts
.k2:	lda xt1                 ; 2: 7 - p + px
	clc
	adc #7
	sec
	sbc xt2
	tax
	rts
.k3:	lda xt2                 ; 3: p < px: px - p - 1, else 0
	cmp xt1
	bcs .z
	lda xt1
	clc
	sbc xt2
	tax
	rts
.k0:	lda xt2                 ; 0: p - px, at least 0
	sec
	sbc xt1
	bcs .k0p
.z:	cla
.k0p:	tax
	rts

