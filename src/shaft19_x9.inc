	.if PLG
SXO        = 0          ; DB_X at MPR4 here
q576l:	.db <0, <576, <1152, <1728, <2304, <2880, <3456, <4032, <4608, <5184, <5760, <6336, <6912, <7488, <8064, <8640, <9216
	.db <9792, <10368, <10944, <11520, <12096, <12672, <13248, <13824, <14400, <14976, <15552, <16128, <16704, <17280, <17856, <18432
q576h:	.db >0, >576, >1152, >1728, >2304, >2880, >3456, >4032, >4608, >5184, >5760, >6336, >6912, >7488, >8064, >8640, >9216
	.db >9792, >10368, >10944, >11520, >12096, >12672, >13248, >13824, >14400, >14976, >15552, >16128, >16704, >17280, >17856, >18432
q2b:	.db $00, $03, $0C, $0F, $30, $33, $3C, $3F, $C0, $C3, $CC, $CF, $F0, $F3, $FC, $FF
q5:	.db 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80
qbm:	.db 1, 2, 4, 8, 16, 32, 64, 128
q16l:	.db 0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 0
q16h:	.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
q66l:	.db <0, <66, <132, <198, <264, <330, <396, <462, <528, <594, <660, <726, <792, <858, <924, <990, <1056
q66h:	.db >0, >66, >132, >198, >264, >330, >396, >462, >528, >594, >660, >726, >792, >858, >924, >990, >1056
qbsl:	.db <SSTRL, <(SSTRL + 19008), <(SSTRL + $10000), <(SSTRL + $10000 + 19008)
qbsm:	.db >SSTRL, >(SSTRL + 19008), >(SSTRL + $10000), >(SSTRL + $10000 + 19008)
qbsb:	.db (SSTRL >> 16), ((SSTRL + 19008) >> 16), ((SSTRL + $10000) >> 16), ((SSTRL + $10000 + 19008) >> 16)

; splug (kpass, after the X phase; interrupts on): the fifth bank at MPR4, the pass's inputs copied there, its spass (DB_X at MPR6 while
; it runs, this bank back on return), its log copied here (the recorders read this bank). Carry set: held
splug:	tma #4
	pha
	lda #CB5
	tam #4
	tii out, sout, 16
	lda obi
	sta sobi
	lda kq0h
	sta skq
	.if PBX
	lda kfst                ; (r19-plug-bitmap) a see-through block left out (D past ns) or kdrop: the exact build
	ora kdrp
	sta sfst
	.endif
	jsr spass
	php
	tii slog5, slg, slog5e - slog5
	plp
	pla
	tam #4
	rts
slg:	.ds slog5e - slog5      ; the plug's per-pass log (the fifth bank's spx .. sti5)

sset:	tma #3
	pha
	tma #4
	pha
	lda #DB_NEAR
	tam #3
	lda #DB_X
	tam #4
	jsr spini
	ldx #0                  ; (the sixth bank) the streams under their key
	lda #15
	jsr c5
	jsr stabs
	ldx #3                  ; (the sixth bank) the pool's tables
	lda #15
	jsr c5
	.if PDD
	ldx #9                  ; (the sixth bank) the window table's dictionary words, the dictionary's tiles
	lda #15
	jsr c5
	.endif
	.if OCK & (WAL = 0)
	ldx #15                 ; (the sixth bank) the upload-cost order
	lda #15
	jsr c5
	.endif
	lda #12                 ; (the fifth bank) S's state
	jsr c5
	pla
	tam #4
	pla
	tam #3
	rts
; sreen (entry 17; reeng, after xset2, which zeroed DB_X's tables: the buffers are redrawn): ports, tables, pool, S's state empty
sreen:	jsr wcl                 ; (r19-window-cells) the module's cells the window wrote: saved, ours back (before the dictionary's tiles go in)
	tma #3
	pha
	tma #4
	pha
	lda #DB_NEAR
	tam #3
	lda #DB_X
	tam #4
	jsr spini
	jsr stabs
	ldx #3                  ; (the sixth bank) the pool's tables
	lda #15
	jsr c5
	.if PDD
	ldx #12                 ; (the sixth bank) the dictionary's tiles again
	lda #15
	jsr c5
	.endif
	lda #12
	jsr c5
	pla
	tam #4
	pla
	tam #3
	rts
; the pass's constant tables into DB_X (at MPR6)
stabs:	tii q2b, SX2B + SXO, 16
	tii q5, S5 + SXO, 17
	tii qbm, SBM + SXO, 8
	tii q16l, S16L + SXO, 17
	tii q16h, S16H + SXO, 17
	tii qbsl, SBSL + SXO, 12
	tii q576l, S576L + SXO, 66
	tii q66l, S66L + SXO, 34
	rts
; ports 1, 2 and 3 as port 0: increment 1, the base advancing at every data access, no offset
spini:	lda #1
	sta $1A17
	sta $1A27
	sta $1A37
	stz $1A18
	stz $1A28
	stz $1A38
	stz $1A15
	stz $1A16
	stz $1A25
	stz $1A26
	lda #$11
	sta $1A29
	lda #32
	sta $1A35
	stz $1A36
	lda #$71
	sta $1A39
	lda #<272
	sta $1A15
	lda #>272
	sta $1A16
	lda #$71
	sta $1A19
	rts
wcl:	tma #4
	pha
	lda #$40
	tam #4
	stz wcn
	clx
.r:	stx wcx
	lda wcvl,x
	sta wva
	lda wcvh,x
	sta wva+1
	lda wccl,x
	sta wca
	lda wcch,x
	sta wca+1
	lda wcnn,x
	sta wck
.u:	lda wva                 ; the probe: VRAM words 2-3 of the unit
	ora #2
	ldx wva+1
	jsr vmarr
	lda wca
	ora #4
	sta $1A02
	lda wca+1
	sta $1A03
	lda #2
	sta $1A04
	lda $0002
	cmp $1A00
	bne .d
	lda $0003
	cmp $1A00
	bne .d
	lda $0002
	cmp $1A00
	bne .d
	lda $0003
	cmp $1A00
	beq .n
.d:	lda wva                 ; the window's four tiles -> the saved copy
	ldx wva+1
	jsr vmarr
	lda wca
	sta $1A02
	lda wca+1
	sta $1A03
	lda #1
	sta $1A04
	ldy #16
.s:	tai $0002, $8000, 8     ; (eight bytes a block, as rdbuf; any address of bank $40 is port 0's data)
	dey
	bne .s
	lda wva                 ; ours -> VRAM
	ldx wva+1
	jsr vmawr
	lda wca
	sta $1A02
	lda wca+1
	sta $1A03
	lda #2
	sta $1A04
	ldy #16
.w:	tia $8000, $0002, 8
	dey
	bne .w
	inc wcn
.n:	lda wva
	clc
	adc #64
	sta wva
	bcc .n1
	inc wva+1
.n1:	lda wca
	clc
	adc #128
	sta wca
	bcc .n2
	inc wca+1
.n2:	dec wck
	beq .e
	jmp .u
.e:	ldx wcx
	inx
	cpx #3
	beq .x
	jmp .r
.x:	pla
	tam #4
	rts
wcvl:	.db $00, $00, $00
wcvh:	.db $5F, $61, $62
wccl:	.db $00, $80, $00
wcch:	.db $02, $59, $04
wcnn:	.db 4, 4, 120
wva:	.dw 0
wca:	.dw 0
wck:	.db 0
wcx:	.db 0
wcn:	.db 0
	.endif
