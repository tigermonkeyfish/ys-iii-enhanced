EVER       = 1
eset:	tma #3
	pha
	tma #4
	pha
	lda #DB_NEAR
	tam #3
	lda #DB_X
	tam #4
	ldx #1                  ; EML / EMH: tile * 16
.m:	lda XD_CTL,x
	sta yt0
	lda XD_CTH,x
	and #7
	asl yt0
	rol a
	asl yt0
	rol a
	asl yt0
	rol a
	asl yt0
	rol a
	sta EMH,x
	lda yt0
	sta EML,x
	lda XD_CTL,x
	sta EWL,x
	lda XD_CTH,x
	ora #XPAL << 4
	sta EWH,x
	inx
	cpx #73
	bne .m
	clx
.c:	stz XD_BUF,x
	stz XD_BUF + $100,x
	inx
	bne .c
	lda #$60
	sta .s+2
	cly
.sc:
.s:	ldx $6000,y
	lda #1
	sta XD_BUF,x
	iny
	bne .sc
	inc .s+2
	lda .s+2
	cmp #$71
	bne .sc
	stz en
	stz enov
	clx
.k:	stz ENK,x
	lda XD_BUF,x
	beq .kn
	ldy XD_VMAP,x
	lda XD_BUF + $100,y
	bne .kh
	lda en
	cmp #ENMAX
	bcc .ka
	inc enov
	bra .kn
.ka:	phx
	tax
	tya
	sta EKV,x
	plx
	inc en
	lda en
	sta XD_BUF + $100,y
.kh:	dec a
	sta ENK,x
.kn:	inx
	bne .k
	lda #$FF                ; eti: the index of the transparent S word's key
	sta eti
	clx
.t:	lda KSWL,x
	cmp #$C5
	bne .tn
	lda KSWH,x
	bne .tn
	ldy XD_VMAP,x
	lda XD_BUF + $100,y
	beq .tx
	dec a
	sta eti
	bra .tx
.tn:	inx
	bne .t
.tx:	stz es0                 ; the key: two sums over the count, each index's key value and near tile, the strips' bytes
	stz es1
	lda en
	jsr .add
	stz ei
.kk:	lda ei
	cmp en
	beq .kb
	tax
	lda EKV,x
	pha
	jsr .add
	pla
	jsr .tile
	clx
.kt:	lda XD_N,x
	jsr .add
	inx
	cpx #32
	bne .kt
	inc ei
	bra .kk
.kb:	clx
.kx:	lda XD_BB,x             ; (XD_BB 24, XD_NM 6)
	jsr .add
	inx
	cpx #30
	bne .kx
	clx
.k6:	lda eb6,x
	jsr .add
	inx
	cpx #4
	bne .k6
	jsr .kad
	clx
.kc:	lda $1A00
	cmp ekey,x
	bne .bd
	inx
	cpx #6
	bne .kc
	lda #1
	sta ecached
	jmp .x
.bd:	stz ecached
	inc nebuild
	stz ei
.bi:	lda ei
	cmp en
	bne .b1
	jmp .bk
.b1:	tax
	lda EKV,x
	jsr .tile
	stz $1A02
	lda ei
	ora #$80
	sta $1A03
	lda #$0B
	sta $1A04
	lda #$FF                ; page 0: the near tile
	sta xm
	stz xb0
	stz xb1
	stz xb2
	stz xb3
	jsr .img
	stz xm                  ; page 1: the bar's black (the right side on the grid)
	lda eb6
	sta xb0
	lda eb6+1
	sta xb1
	lda eb6+2
	sta xb2
	lda eb6+3
	sta xb3
	jsr .img
	stz ep                  ; pages 2-7: the cache's key pages 0-5 (2 (pi - 1) + side)
.bp:	ldx ep
	lda XD_NM,x
	sta xm
	txa
	asl a
	asl a
	tax
	lda XD_BB,x
	sta xb0
	lda XD_BB+1,x
	sta xb1
	lda XD_BB+2,x
	sta xb2
	lda XD_BB+3,x
	sta xb3
	jsr .img
	inc ep
	lda ep
	cmp #6
	bne .bp
	inc ei
	jmp .bi
.bk:	jsr .kad                ; the key, last
	tia ekey, $1A00, 6
.x:	pla
	tam #4
	pla
	tam #3
	rts
.kad:	stz $1A02
	lda #$FF
	sta $1A03
	lda #$0B
	sta $1A04
	rts
.add:	clc                     ; es0 += A, es1 += es0
	adc es0
	sta es0
	clc
	adc es1
	sta es1
	rts
.tile:	tax                     ; key value X: its S word's tile -> XD_N (32 bytes, x4rd)
	lda KSWL,x
	sta xtl
	lda KSWH,x
	and #7
	sta xth
	jmp x4rd
.img:	clx
.ia:	lda XD_N,x
	and xm
	ora xb0
	sta $1A00
	lda XD_N+1,x
	and xm
	ora xb1
	sta $1A00
	inx
	inx
	cpx #16
	bne .ia
.ib:	lda XD_N,x
	and xm
	ora xb2
	sta $1A00
	lda XD_N+1,x
	and xm
	ora xb3
	sta $1A00
	inx
	inx
	cpx #32
	bne .ib
	rts
ekey:	.db $19, $E4, EVER     ; the key: these, the count, the two sums
en:	.db 0           ; image indices
es0:	.db 0
es1:	.db 0
ei:	.db 0
ep:	.db 0
; no cell change: the left rows of the bands em: both rows of a band whose block 0 changed (wbat wrote column 2), else the rows whose
; key is the transparent word's (their backdrop composite changed or moved phase)
ebnd:	lda xob
	asl a
	jsr eqs
	ldx xob
	lda eraw
	eor eb0r,x
	sta emr
	stz eb
.bl:	lsr em
	bcc .bn
	lda eb
	asl a
	sta er2
	jsr .row
	inc er2
	jsr .row
.bn:	inc eb
	lda em
	bne .bl
	rts
.row:
	.if EP0
	ldx xob                 ; (direct words: the slots say nothing of the rows)
	lda edir,x
	bne .w
	.endif
	ldy eb
	lda emr
	and xbit8,y
	bne .w
	lda er2
	clc
	adc eqo
	tax
	lda ERS,x
	clc
	adc eqo
	tax
	lda ESK,x
	cmp eti
	bne .x
.w:	jsr ewd
	lda er2
	clc
	adc rbe
	tax
	vsel 0
	lda xmal,x
	ora cbe
	sta $0002
	lda xmah,x
	sta $0003
	vsel 2
	lda ewlo
	sta $0002
	lda ewhi
	sta $0003
.x:	rts
emr:	.db 0
	.if EP0
; (EP0) the buffer's edge words direct on the X grid: left the near cells' S words (b7's backdrop word where it applies: ewd), right the
; bar word (both columns, increment 64); its sets' slots marked stale (the next pass off the grid regroups them afresh)
edgo:	lda #1
	sta edir,x
	txa
	asl a
	tay
	lda #$FF
	sta esph,y
	sta esph+1,y
	tya
	jsr eqs
	jsr rinc64
	ldx rbe
	vsel 0
	lda xmal,x
	ora cbe
	sta $0002
	lda xmah,x
	sta $0003
	vsel 2
	stz er2
.l:	jsr ewd
	lda ewlo
	sta $0002
	lda ewhi
	sta $0003
	inc er2
	lda er2
	cmp #XROWS
	bne .l
	ldx rbe
	vsel 0
	lda xmal,x
	ora cbe
	ora #32
	sta $0002
	lda xmah,x
	sta $0003
	vsel 2
	lda XD_BRH+16
	ora #$F0
	tay
	lda XD_BRL+16
	ldx #XROWS
.r:	sta $0002
	sty $0003
	dex
	bne .r
	jmp rinc1
	.endif
; set A regrouped and filled: a shift of one row in Y with the phase kept moves the rows (eysh); anything else afresh (efast)
erg:	jsr eqs
	ldx eq
	lda xpi
	cmp esph,x
	bne .f
	lda rsh                 ; (its phase kept: a shift or vertical-only 1-row redraw moves the rows; else afresh, every slot filled again)
	and #6
	cmp #4
	beq .y
	lda #$FF
	sta esph,x
.f:	jsr efast
	jmp efil
.y:	jsr eysh
	jmp efil
