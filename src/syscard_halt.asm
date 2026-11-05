; The boot test, and the screen shown when the System Card's RAM is absent. Our own code, and our own font (font.inc). The stub's bootchk reads it
; into RAM at $A000 at the card's handover. With the card's RAM present it hands over to the stub bank's part and the entry; without it, it shows the
; message and never returns: it needs only the VDC, the VCE and RAM, interrupts masked, the sound off, the CPU in a loop.

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
	lda #SBANK
	tam #6
	tii $A400, $C400, $400
	lda #1
	sta SBOK
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

text:	LINE 11, 1, "SUPER SYSTEM CARD 3.0 REQUIRED"
	LINE 13, 7, "(OR A DUO CONSOLE)"
	LINE 16, 4, "THIS PATCH WILL NOT RUN"
	LINE 18, 8, "PLEASE SWITCH OFF"
	.db $FF

font:	.include "font.inc"
