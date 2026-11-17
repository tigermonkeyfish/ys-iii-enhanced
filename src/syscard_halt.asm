; The boot test, and the screen shown when the required card RAM ($68 / $1AFF) is absent. Our own code, and our own font (font.inc).
; The stub's bootchk reads it into RAM at $A000 at the card's handover. With the required hardware present it copies stub bank parts and hands over;
; without it, it shows the message and never returns: it needs only the VDC, the VCE and RAM, interrupts masked, the sound off, the CPU in a loop.

BAT_SP   = $0100        ; BAT word of a space: palette 0, tile $100 (VRAM $1000)
P        = $F8          ; (zero page, the card's CD arguments: nothing reads them again)
	.include "haltsyms.inc"  ; (mkdisc, from the stub's symbols) SBOK: sbok's address; SBANK; SBGO: the stub bank's sbgo

	.bank 0
	.org $A000
	jmp boot                ; (the stub tests this JMP: it arrived)

boot:	lda #$68
	tam #6
	lda #$A5
.t:	sta $C000
	cmp $C000
	bne halt
	eor #$FF
	bpl .t
	lda $1AFF
	cmp #$51
	bne halt
	lda #$5A
	sta $1A32
	cmp $1A32
	bne halt
	eor #$FF
	sta $1A32
	cmp $1A32
	bne halt
	lda #SBANK
	tam #6
	tii $A400, $C400, $400
	tii $B000, $C800, $400
	lda #1
	sta SBOK
	.if CMSEC
	jsr cmload
	.endif
	.if PRELOAD
	jsr preload             ; (the quarry's code, the mine's, at power-on: their entries read nothing; sector 1 of the slot)
	.endif
	lda #$40                ; the execute address, as the untouched disc's
	sta <$08
	stz <$07
	lda #$53
	sta <$F8
	lda #$40
	sta <$F9
	sta <$FC
	lda #$4C
	sta <$FA
	stz <$FB
	lda #$84
	jmp SBGO

halt:	sei
	csh
	lda #$07
	sta $1402
	stz $0C01
	lda $0000               ; (any VDC status flag read away)
	ldx #5                  ; the six sound channels off
.psg:	stx $0800
	stz $0804
	stz $0805
	dex
	bpl .psg
	stz $0801
	st0 #5                  ; the display off while VRAM is written
	st1 #0
	st2 #0
	lda #$04
	sta $0400
	cly                     ; the registers, from the table
.reg:	lda vdcregs,y
	bmi .regx
	sta $0000
	lda vdcregs + 1,y
	sta $0002
	lda vdcregs + 2,y
	sta $0003
	iny
	iny
	iny
	bra .reg
.regx:
	stz $0402               ; the colours: 0 black, 1 white; the border (sprite colour 0) black
	stz $0403
	stz $0404
	stz $0405
	lda #$FF
	sta $0404
	lda #$01
	sta $0405
	stz $0402
	sta $0403
	stz $0404
	stz $0405
	stz <P                  ; the BAT, all spaces
	stz <P + 1
	jsr mawr
	ldx #4                  ; 4 x 256 words
	cly
.bat:	st1 #LOW(BAT_SP)
	st2 #HIGH(BAT_SP)
	dey
	bne .bat
	dex
	bne .bat
	stz <P                  ; the font at tile $100: plane 0 from the glyph, the other three empty
	lda #$10
	sta <P + 1
	jsr mawr
	lda #LOW(font)
	sta <P
	lda #HIGH(font)
	sta <P + 1
	ldx #64
.gl:	ldy #8
.row:	lda [P]
	sta $0002
	st2 #0
	inc <P
	bne .r1
	inc <P + 1
.r1:	dey
	bne .row
	ldy #8
.pad:	st1 #0
	st2 #0
	dey
	bne .pad
	dex
	bne .gl
	clx
.ln:	lda text,x
	cmp #$FF
	beq .show
	sta <P
	lda text + 1,x
	sta <P + 1
	jsr mawr
	inx
	inx
.ch:	lda text,x
	beq .eol
	sec
	sbc #$20
	sta $0002
	st2 #HIGH(BAT_SP)
	inx
	bra .ch
.eol:	inx
	bra .ln
.show:	st0 #5                  ; background only: no interrupt sources
	st1 #$80
	st2 #0
.h:	bra .h

mawr:	st0 #0                  ; VRAM write address = P; register select left on the data port
	lda <P
	sta $0002
	lda <P + 1
	sta $0003
	st0 #2
	rts

vdcregs:	.db $06, $00, $00       ; RCR off
	.db $07, $00, $00       ; BXR
	.db $08, $00, $00       ; BYR
	.db $09, $00, $00       ; MWR: 32 x 32
	.db $0A, $02, $02       ; HSR
	.db $0B, $1F, $04       ; HDR: 256 wide
	.db $0C, $02, $0F       ; VPR
	.db $0D, $EF, $00       ; VDW: 240 lines
	.db $0E, $F6, $00       ; VCR
	.db $0F, $00, $00       ; DCR
	.db $FF

; row r, column c: VRAM word r * 32 + c
LINE	.macro
	.dw \1 * 32 + \2
	.db \3, 0
	.endm

text:	LINE  8, 6, "ARCADE CARD REQUIRED"
	LINE 11, 2, "SUPER CD / DUO + ARCADE DUO"
	LINE 13, 3, "SYSTEM CARD 2 + ARCADE PRO"
	LINE 15, 5, "OR TURBO EVERDRIVE PRO"
	LINE 18, 7, "PLEASE SWITCH OFF"
	.db $FF

font:	.include "font.inc"

; ---------------------------------------------------------------- the preload (mkdisc PRELOAD, the quarry's "preload": quarry-entry-black)
	.if PRELOAD
	.org $A800
preload:	lda #$AC                ; (the quarry's resident area of the stub bank, the slot's $C00-$FFF: mkdisc SBRA; MPR6 = SBANK)
	ldx #$C0
	ldy #$04
	jsr cp_tii
	.if C6SEC
	jsr cdet
	.endif
	stz .e
	tma #3
	pha
	tma #4
	pha
	stz <$FC
	lda #>QSEC
	sta <$FD
	lda #<QSEC
	sta <$FE
	lda #3
	sta <$FF
	lda #$69
	sta <$FA
	lda #MSEC + 4 - QSEC
	sta <$F8
	jsr $E009
	ora .e
	sta .e
	lda #$69                ; the quarry's: bank $69 whole
	tam #3
	lda #QBANK
	tam #4
	lda #$60
	ldx #$80
	ldy #$20
	jsr cp_tii
	lda #MBANK              ; the mine's: from (MSEC - QSEC) * 2 KB on
	tam #4
	lda #$69 + (MSEC - QSEC) / 4
	tam #3
	lda #$60 + ((MSEC - QSEC) & 3) * 8
	ldx #$80
	ldy #$20 - ((MSEC - QSEC) & 3) * 8
	jsr cp_tii
	.if ((MSEC - QSEC) & 3)
	lda #$69 + (MSEC - QSEC) / 4 + 1
	tam #3
	lda #$60
	ldx #$80 + $20 - ((MSEC - QSEC) & 3) * 8
	ldy #((MSEC - QSEC) & 3) * 8
	jsr cp_tii
	.endif
	lda #$69
	tam #3
	lda #$6A
	tam #4
	lda #<CSEC
	ldx #>CSEC
	ldy #6
	.if C6SEC
	lda CTIER
	beq .r6
	ldy #8
.r6:	lda #<CSEC
	.endif
	jsr .rd6
	lda #CBK
	tam #6
	lda #$60
	ldx #$D0
	ldy #$10
	jsr cp_tii
	lda #C4BK
	tam #6
	lda #$70
	ldx #$D0
	ldy #$10
	jsr cp_tii
	lda #C5BK
	tam #6
	lda #$80
	ldx #$D0
	ldy #$10
	jsr cp_tii
	lda #SBANK
	tam #6
	.if C6SEC
	lda CTIER
	beq .nc
	lda .e
	bne .nc0
	stz $1A35
	stz $1A36
	.if (C6LEN & 255)
	.fail
	.endif
	lda #$90
	ldy #HIGH(C6LEN)
	jsr cp_tia3
	.if C7SEC
	lda #<C7SEC
	ldx #>C7SEC
	ldy #2
	jsr .rd
	lda .e
	bne .nc0
	stz $1A35
	lda #$10
	sta $1A36
	.if (C7LEN & 255)
	.fail
	.endif
	lda #$80
	ldy #HIGH(C7LEN)
	jsr cp_tia3
	.endif
	.if C8SEC
	lda #<C8SEC             ; (quarry-bridge-setup: the third overlay, the bridge's set-up and builder, to C6CH:2000)
	ldx #>C8SEC
	ldy #2
	jsr .rd
	lda .e
	bne .nc0
	stz $1A35
	lda #$20
	sta $1A36
	.if (C8LEN & 255)
	.fail
	.endif
	lda #$80
	ldy #HIGH(C8LEN)
	jsr cp_tia3
	.endif
	.if PGSEC
	lda PGFLAG
	beq *+5
	jsr .pgl
	.endif
	bra .nc
.nc0:	stz CTIER
.nc:
	.endif
	lda .e                  ; (a read failed: nothing marked, the stub reads them at the entry as before)
	bne .x
	lda #1
	sta DL + QROW
	sta DL + MROW
	lda #QBANK
	tam #4
	lda DGEN
	sta MGENA
.x:	pla
	tam #4
	pla
	tam #3
	rts
.rd:	pha
	lda #$80
	bra .r
.rd6:	pha
	lda #$60
.r:	sta <$FB
	pla
	sta <$FE
	stx <$FD
	sty <$F8
	stz <$FC
	stz <$FA
	lda #1
	sta <$FF
	jsr $E009
	ora .e
	sta .e
	rts
	.if PGSEC
.pgl:	lda #<PGDIR
	ldx #>PGDIR
	ldy #1
	jsr .rd
	lda .e
	beq *+5
	jmp .pgn
	ldx #6
.pm:	lda $8000,x
	cmp .pgm,x
	beq *+5
	jmp .pgn
	dex
	bpl .pm
	tii $8007, .pgd, 129
	lda #<(PGDIR + 1)
	sta .ps
	lda #>(PGDIR + 1)
	sta .ps + 1
	clx
.sg:	stx .pi
	lda .pgd + 1,x
	sta $1A02
	sta $1A12
	lda .pgd + 2,x
	sta $1A03
	sta $1A13
	lda .pgd + 3,x
	sta $1A04
	sta $1A14
	lda .pgd + 4,x
	sta .pn
	sta .pv
.ch:	lda .pn                 ; up to 56 sectors a read (one command: a drive pays a seek for each), into banks $69-$76 by cd_read's
	cmp #57                 ; bank mode (free at power-on: the modules' banks are filled, nothing else is yet), then each bank
	bcc .c4
	lda #56
.c4:	sta .pc
	sta .pk
	sta <$F8
	stz <$FC
	lda .ps + 1
	sta <$FD
	lda .ps
	sta <$FE
	lda #3
	sta <$FF
	lda #$69
	sta <$FA
	sta .pb
	jsr $E009
	ora .e
	sta .e
	beq *+5
	jmp .pgn
.wb:	lda .pb
	tam #4
	ldy #4
	lda .pk
	cmp #4
	bcs .w4
	tay
.w4:	sty .pt
	tya
	asl a
	asl a
	asl a
	tay
	jsr cp_tia0
	inc .pb
	lda .pk
	sec
	sbc .pt
	sta .pk
	bne .wb
	lda .ps
	clc
	adc .pc
	sta .ps
	bcc *+5
	inc .ps + 1
	lda .pn
	sec
	sbc .pc
	sta .pn
	bne .ch
	stz .s
	stz .s + 1
.sp:	lda #8
	sta .pc
.pg:	cla
	clc
	cly
.sb:	adc $1A10
	iny
	bne .sb
	adc #0
	clc
	adc .s
	sta .s
	clc
	adc .s + 1
	sta .s + 1
	dec .pc
	bne .pg
	dec .pv
	bne .sp
	ldx .pi
	lda .s
	cmp .pgd + 5,x
	beq *+5
	jmp .pgn
	lda .s + 1
	cmp .pgd + 6,x
	beq *+5
	jmp .pgn
	txa
	clc
	adc #8
	tax
	dec .pgd
	beq *+5
	jmp .sg
	lda #<PGSEC
	ldx #>PGSEC
	ldy #1
	jsr .rd
	lda .e
	beq *+5
	jmp .pgn
	tii $8000, PGA, PGALEN
	tii $8000 + PGALEN, PGB, PGBLEN
	lda #$80
	sta BS_P5
	lda #$10
	sta BS_PB
	stz BS_LK
.pgn:	stz .e                  ; (a failed read here marks nothing: the modules are in)
	rts
	.endif
PGFLAG     = $ABFF
.e:	.db 0
	.if PGSEC
.pgm:	.db 'Y', '3', 'P', 'G', 1, <PGKEY, >PGKEY
.pgd       = $A400
.ps:	.dw 0
.pi:	.db 0
.pn:	.db 0
.pv:	.db 0
.pc:	.db 0
.pk:	.db 0
.pb:	.db 0
.pt:	.db 0
.s:	.dw 0
	.endif
	.if C6SEC
cdet:	stz CTIER
	lda $1AFF
	cmp #$51
	bne .n
	lda #$5A
	sta $1A32
	cmp $1A32
	bne .n
	lda #$A5
	sta $1A32
	cmp $1A32
	bne .n
	ldx #$30
.p:	stz $1A02,x
	stz $1A03,x
	stz $1A04,x
	stz $1A05,x
	stz $1A06,x
	lda #1
	sta $1A07,x
	stz $1A08,x
	lda #$11
	sta $1A09,x
	txa
	sec
	sbc #$10
	tax
	bpl .p
	lda #C6CH
	sta $1A34
	lda #3
	sta $1A39
	inc CTIER
.n:	rts
cp_tia3:
	sta .t3 + 2
.t3:	tia $8000, $1A30, $0100
	inc .t3 + 2
	dey
	bne .t3
	rts
	.endif
; Y pages ($100 bytes each, ~3.4 lines: VBlank IRQ never delayed into active display) from A:$00 to X:$00
cp_tii:	sta .ti + 2
	stx .ti + 4
.ti:	tii $6000, $8000, $0100
	inc .ti + 2
	inc .ti + 4
	dey
	bne .ti
	rts
	.endif

	.if CMSEC
	.if PRELOAD = 0
	.org $A800
	.endif
cmload:	lda $1AFF
	cmp #$51
	bne .x
	lda #$5A
	sta $1A02
	cmp $1A02
	bne .x
	tma #3
	pha
	tma #4
	pha
	stz <$FC
	lda #HIGH(CMSEC)
	sta <$FD
	lda #LOW(CMSEC)
	sta <$FE
	lda #3
	sta <$FF
	lda #CMSTG
	sta <$FA
	lda #CMN * 4
	sta <$F8
	jsr $E009
	cmp #0
	bne .r
	stz $1A02
	stz $1A03
	lda #CMADDR
	sta $1A04
	stz $1A05
	stz $1A06
	lda #1
	sta $1A07
	stz $1A08
	lda #$11
	sta $1A09
	lda #CMSTG
	ldx #CMN
.w:	tam #4
	ldy #$20
	jsr cp_tia0
	inc a
	dex
	bne .w
.r:	pla
	tam #4
	pla
	tam #3
.x:	rts
	.endif
	.if PRELOAD | CMSEC
cp_tia0:
	pha
	lda #$80
	sta .t0 + 2
.t0:	tia $8000, $1A00, $0100
	inc .t0 + 2
	dey
	bne .t0
	pla
	rts
	.endif
