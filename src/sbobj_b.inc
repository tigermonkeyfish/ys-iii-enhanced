
	.db $A5, $5A
p2_pass:
	stz SB_AHIT
	lda SB_SCENE
	cmp #24
	beq .emapi
	cmp #32
	beq .emapi
	ldy <$84
	cpy #24
	bcs .emapi
	lda SB_ENTST,y
	cmp #4
	bne .emapi
	inc SB_AHIT
.emapi:	ldy #23
.el:	ldx SB_ENTSL,y
	cpx #$44
	bcs .enx
	lda SB_SCENE
	cmp #24
	bne .e32
	cpy #9                  ; Dulan body entity 9
	beq .eboss
.e32:	cmp #32
	bne .eflg
	cpy #12                 ; Elefeir body entity 12
	bne .eflg
.eboss:	lda O_DT,x
	ora #$80
	bra .eset
.eflg:	lda O_DT,x
	bmi .enx
	lda SB_ENTFL,y          ; bit 6 ($40) = non-combat NPC/item; bits 7|5 ($A0) = dying | sword-hit
	bit #$40
	bne .enx
	and #$A0
	beq .enx
	lda O_DT,x
	ora #$40
.eset:	sta O_DT,x
.enx:	dey
	bpl .el

; Process all 68 object slots (67..0); keep X in X on empty-slot fast path
	ldx #67
.klp:	lda SB_OCLS,x
	cmp #$A4
	bne .kskip
	cpx <$85
	beq .kskip
	lda O_DT,x
	bpl .kact
.kskip:	lda O_DT,x
	beq .knx
	stz O_DT,x
	stz O_DT+$44,x
	stz O_OFF,x
	stz O_OFF+$44,x
	cpx #16
	bcs .knx
	stz O_VFR,x
.knx:	dex
	bpl .klp
	rts

.kact:
	stx SB_K
	; World X -> SB_DXH:SB_DXL
	lda SB_OXL,x
	clc
	adc SB_CAMX
	sta SB_DXL
	lda SB_OXH,x
	adc SB_CAMX+1
	sta SB_DXH
	; World Y -> SB_DYH:SB_DYL
	lda SB_OYL,x
	clc
	adc SB_CAMY
	sta SB_DYL
	lda SB_OYH,x
	adc SB_CAMY+1
	sta SB_DYH

	lda O_DT,x
	sta SB_SIGN
	and #$3F
	sta O_DT,x
	bne .kdelta
	lda SB_DXL
	sta O_WL,x
	lda SB_DXH
	sta O_WH,x
	lda SB_DYL
	sta O_WL+$44,x
	lda SB_DYH
	sta O_WH+$44,x
.ksnap:	stz O_LAG,x
	stz O_LAG+$44,x
	stz O_LEAD,x
	stz O_LEAD+$44,x
	stz O_OFF,x
	stz O_OFF+$44,x
	lda #16
	sta O_DT,x
	sta O_DT+$44,x
	cpx #16
	bcs .knx
	stz O_VFR,x
	stz S_FR,x
	stz S_DT,x
	bra .knx

.kdelta:
	; dwx = new_wx - prev_wx, store new_wx
	ldy SB_DXL
	tya
	sec
	sbc O_WL,x
	sta SB_DXL
	tya
	sta O_WL,x
	ldy SB_DXH
	tya
	sbc O_WH,x
	sta SB_DXH
	tya
	sta O_WH,x
	; dwy = new_wy - prev_wy, store new_wy
	ldy SB_DYL
	tya
	sec
	sbc O_WL+$44,x
	sta SB_DYL
	tya
	sta O_WL+$44,x
	ldy SB_DYH
	tya
	sbc O_WH+$44,x
	sta SB_DYH
	tya
	sta O_WH+$44,x

	; Cross-axis snap checks
	lda SB_SIGN
	and #$40
	bne .go_snap
	lda SB_AHIT
	beq .rngx
	ldy <$85
	lda SB_OXL,x
	sec
	sbc SB_OXL,y
	sta SB_TMP
	lda SB_OXH,x
	sbc SB_OXH,y
	tay
	lda SB_TMP
	clc
	adc #23
	pha
	tya
	adc #0
	bne .admiss
	pla
	cmp #47
	bcc .go_snap
	bra .rngx
.go_snap:
	jmp .ksnap
.admiss:	pla

.rngx:	; dwx in [-32..+32] iff 0 <= (dwx + 32) < 65; |dwx|==32 also requires O_DT[x] <= 8
	lda SB_DXL
	clc
	adc #32
	tay
	lda SB_DXH
	adc #0
	bne .go_snap
	cpy #65
	bcs .go_snap
	cpy #0
	beq .chk32
	cpy #64
	bne .rngy
.chk32:	lda O_DT,x
	cmp #9
	bcs .go_snap

.rngy:	; dwy in [-16..+16] iff 0 <= (dwy + 16) < 33
	lda SB_DYL
	clc
	adc #16
	tay
	lda SB_DYH
	adc #0
	bne .go_snap
	cpy #33
	bcs .go_snap

	; Run shared 8-bit Q5.2 axis smoother for X (slot k) and Y (slot k+$44)
	lda SB_DXL
	jsr up_axis
	lda SB_K
	clc
	adc #$44
	tax
	lda SB_DYL
	jsr up_axis
	ldx SB_K

	cpx #16
	bcs .go_nx
	lda SB_SCENE
	cmp #24
	bne .spclr
	lda SB_OYL,x
	cmp #8
	bne .spclr
	lda SB_OYH,x
	bne .spclr
	lda SB_OFR,x
	cmp #16
	bcc .spclr
	cmp #24
	bcs .spclr

	lda S_FR,x
	bne .schk
	lda SB_OFR,x
	sta S_FR,x
	lda #7
	sta S_DT,x
	stz O_VFR,x
.go_nx:	jmp .knx

.spclr:	stz S_FR,x
	stz S_DT,x
	stz O_VFR,x
	bra .go_nx

.schk:	lda SB_OFR,x
	cmp S_FR,x
	beq .ssame
	sta S_FR,x
	stz S_DT,x
	ldy O_VFR,x
	bne .srun
	sta O_VFR,x             ; sync first frame cleanly without immediate double-advance
	bra .sinc
.ssame:	lda S_DT,x
	cmp #6
	bcc .srun
	lda #7
	sta S_DT,x
	stz O_VFR,x
	bra .go_nx
.srun:	lda S_DT,x
	bit #1
	bne .sinc
	lda O_VFR,x
	inc a
	cmp #24
	bcc .svok
	lda #16
.svok:	sta O_VFR,x
.sinc:	inc S_DT,x
	bra .go_nx

rtab:	.db 32, 16, 11, 8, 7, 6, 5, 4, 4, 4, 3, 3, 3, 3, 3, 2

; ---------------------------------------------------------------- shared axis update (X = axis slot, A = signed dw)
up_axis:
	sta SB_DW
	lda O_DT,x
	sta SB_PREVDT
	clc
	adc SB_DP
	cmp #25
	bcc .dtok
	lda #24
.dtok:	sta O_DT,x
	lda SB_DW
	bne .u_nz
	jmp .decay
.u_nz:	bpl .pos
	eor #$FF
	inc a
.pos:	sta SB_ADW
	cmp #6
	bcs .hop
	stz O_LAG,x             ; |dw| < 6: native fine step passes straight through
	stz O_LEAD,x
	jmp .pub

.hop:	lda SB_DP
	sta O_DT,x
	lda O_LAG,x
	beq .chkld
	eor SB_DW
	bmi .rev
.chkld:	lda O_LEAD,x
	beq .nudge
	eor SB_DW
	bpl .nudge
.rev:	stz O_LAG,x
	stz O_LEAD,x
	bra .rate

.nudge:	lda SB_PREVDT
	cmp #16
	bcs .rate
	lda SB_DW
	bmi .nneg
	lda O_LEAD,x
	cmp #3
	beq .rate
	inc a
	sta O_LEAD,x
	bra .rate
.nneg:	lda O_LEAD,x
	cmp #$FD
	beq .rate
	dec a
	sta O_LEAD,x

.rate:	lda SB_PREVDT
	bne .dt1
	lda #1
.dt1:	cmp #17
	bcc .dt2
	lda #16
.dt2:	dec a
	tay
	lda rtab,y
	sta SB_TMP
	lda SB_ADW
	clc
	adc #4                  ; mult = (abs_dw + 4) >> 3 in [1..4]
	lsr a
	lsr a
	lsr a
	tay
	lda #0
.rmul:	clc
	adc SB_TMP
	dey
	bne .rmul
	cmp #65
	bcc .rset2
	lda #64
.rset2:	sta O_RATE,x

	; O_LAG,x = clamp(O_LAG,x + dw * 4, -127, +127)
	ldy #0
	lda O_LAG,x
	bpl .lp
	dey
.lp:	sty SB_SIGN
	lda SB_DW
	asl a
	pha
	lda #0
	ldy SB_DW
	bpl .sp
	dec a
.sp:	sta SB_TMP
	pla
	asl a
	rol SB_TMP
	clc
	adc O_LAG,x
	tay
	lda SB_TMP
	adc SB_SIGN
	bmi .chkmin
	bne .cmax
	cpy #$80
	bcc .lok
.cmax:	ldy #$7F
	bra .lok
.chkmin:
	cmp #$FF
	bne .cmin
	cpy #$81
	bcs .lok
.cmin:	ldy #$81
.lok:	tya
	sta O_LAG,x

.decay:	lda O_LAG,x
	beq .dlead
	ldy SB_DP
	cmp #0
	bmi .dneg
.dp_pos:
	sec
	sbc O_RATE,x
	bcc .zlag
	beq .zlag
	dey
	bne .dp_pos
	bra .slag
.dneg:	clc
	adc O_RATE,x
	bcs .zlag
	dey
	bne .dneg
	bra .slag
.zlag:	lda #0
.slag:	sta O_LAG,x

.dlead:	lda O_DT,x
	cmp #16
	bcc .pub
	lda O_LEAD,x
	beq .pub
	bmi .dlneg
	dec a
	bra .dlst
.dlneg:	inc a
.dlst:	sta O_LEAD,x

.pub:	lda O_LAG,x
	bmi .pneg
	clc
	adc #2                  ; nearest-pixel rounding: (abs_lag + 2) >> 2
	lsr a
	lsr a
	sta SB_TMP
	lda O_LEAD,x
	sec
	sbc SB_TMP
	bra .pst
.pneg:	eor #$FF
	inc a
	clc
	adc #2
	lsr a
	lsr a
	clc
	adc O_LEAD,x
.pst:	sta O_OFF,x
	rts
