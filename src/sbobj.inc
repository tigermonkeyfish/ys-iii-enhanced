

SB_AREA   = $2F9C
SB_SCENE  = $207C
SB_LOCK   = $2025
SB_WIN    = $36D6
SB_PASS   = $339F
SB_CAMX   = $2D0C
SB_CAMY   = $2D0E
SB_ENTSL  = $2736
SB_ENTFL  = $29D6
SB_ENTST  = $2B56
SB_OFR    = $3053
SB_OCLS   = $3097
SB_OXL    = $30DB
SB_OXH    = $311F
SB_OYL    = $3163
SB_OYH    = $31A7

P2_RUN    = $C800               ; 2-byte sig ($A5, $5A) + p2_pass ($C802)
P2_ENT    = $C802
P2_QBAK1  = $9A00               ; $6A:$1A00..$1BFF mapped at MPR4 (512 B)
P2_QBAK2A = $8780               ; $6F:$0780/$0F80/$1780/$1F80 mapped at MPR4 (4 x 128 = 512 B)
P2_QBAK2B = $8F80
P2_QBAK2C = $9780
P2_QBAK2D = $9F80

SB_BSS    = $CC00
O_WL      = $CC00               ; $88: prev world lo (+0 X, +$44 Y)
O_WH      = $CC88               ; $88: prev world hi
O_LAG     = $CD10               ; $88: signed Q5.2 lag clamped [-127..+127] (1/4 px units)
O_RATE    = $CD98
O_DT      = $CE20
O_LEAD    = $CEA8               ; $88: signed centered lead [-3..+3] px
O_OFF     = $CF30               ; $88: published signed px shift (O_OX = +0, O_OY = +$44)
S_FR      = $CFB8               ; $10: Dulan sword last $3053,x (0 = uninit)
S_DT      = $CFC8               ; $10: passes since $3053,x changed
O_VFR     = $CFD8

SB_DP     = $CFE8
SB_DXL    = $CFE9
SB_DXH    = $CFEA
SB_DYL    = $CFEB
SB_DYH    = $CFEC
SB_TMP    = $CFED
SB_PREVDT = $CFEE
SB_AHIT   = $CFEF
SB_K      = $CFF0
SB_DW     = $CFF1
SB_ADW    = $CFF2
SB_SIGN   = $CFF3

; --- Persistent scalars inside SBPART (survive tai BSS reset; Quarry never writes SBPART) ---
smon:	.db 0
in_17:	.db 0
last_sc:	.db $FF
last_ar:	.db $FF
last_ps:	.db 0

sb_mkbak:
	tma #4
	pha
	lda #$6A
	tam #4
	tii P2_RUN, P2_QBAK1, $200
	lda #$6F
	tam #4
	tii P2_RUN+$200, P2_QBAK2A, $80
	tii P2_RUN+$280, P2_QBAK2B, $80
	tii P2_RUN+$300, P2_QBAK2C, $80
	tii P2_RUN+$380, P2_QBAK2D, $80
	pla
	tam #4
	lda #1
	sta in_17
	rts

sb_rest:
	tma #4
	pha
	lda #$6A
	tam #4
	tii P2_QBAK1, P2_RUN, $200
	lda #$6F
	tam #4
	tii P2_QBAK2A, P2_RUN+$200, $80
	tii P2_QBAK2B, P2_RUN+$280, $80
	tii P2_QBAK2C, P2_RUN+$300, $80
	tii P2_QBAK2D, P2_RUN+$380, $80
	pla
	tam #4
	stz in_17
	rts

; Called at top of xl / xd and qho handoff via XR (MPR6 = SBANK, preserves X and Y)
sb_sync:
	lda in_17
	bne sb_rest
	lda P2_RUN
	cmp #$A5
	bne sb_rest
	lda P2_RUN+1
	cmp #$5A
	bne sb_rest
	rts

sb_enter17:
	lda in_17
	bne .s17x
	lda P2_RUN
	cmp #$A5
	bne .m17f
	lda P2_RUN+1
	cmp #$5A
	bne .m17f
	jmp sb_mkbak
.m17f:	lda #1
	sta in_17
.s17x:	rts

sbobj_pass:
	phx
	phy
	lda curmod
	cmp #WIDE
	bne .not17
	jsr sb_enter17
	bra .off

.not17:	jsr sb_sync

	lda SB_LOCK
	bit #$08
	bne .off
	lda SB_AREA
	ldy SB_SCENE
	cmp #16
	bne .chk24
	cpy #0
	beq .act
	bra .off
.chk24:	cmp #24
	beq .sc
	cmp #26
	bne .off
.sc:	cpy #18
	bcc .off
	cpy #28
	bcc .act
	cpy #30
	bcc .off
	cpy #34
	bcc .act
.off:	stz smon
	lda #$FF
	sta last_sc
.done:	ply
	plx
	rts

.act:	ldx smon
	beq .rst
	cmp last_ar
	bne .rst
	cpy last_sc
	beq .same
.rst:	sta last_ar
	sty last_sc
	lda #1
	sta smon
	clx
.clr:	stz SB_BSS,x
	stz SB_BSS+$100,x
	stz SB_BSS+$200,x
	stz SB_BSS+$300,x
	dex
	bne .clr
	lda SB_PASS
	dec a
	sta last_ps
.same:	lda SB_PASS
	sec
	sbc last_ps
	beq .done
	ldy SB_PASS
	sty last_ps
	cmp #5
	bcc .dpok
	lda #4
.dpok:	sta SB_DP

	jsr P2_ENT
	ply
	plx
	rts

; ---------------------------------------------------------------- per-slot emit offset (X = slot, preserves X and Y, writes frame to sfr)
sbobj_slot:
	php
	lda SB_OFR,x
	sta sfr
	lda smon
	beq .srts
	lda O_OFF,x
	beq .sy
	clc
	adc <$04
	sta <$04
	lda O_OFF,x
	bpl .sxp
	lda #$FF
	bra .sxh
.sxp:	lda #0
.sxh:	adc <$05
	sta <$05
.sy:	lda O_OFF+$44,x
	beq .sfr
	clc
	adc <$06
	sta <$06
	lda O_OFF+$44,x
	bpl .syp
	lda #$FF
	bra .syh
.syp:	lda #0
.syh:	adc <$07
	sta <$07
.sfr:	cpx #16
	bcs .srts
	lda O_VFR,x
	beq .srts
	sta sfr
.srts:	plp
	rts

