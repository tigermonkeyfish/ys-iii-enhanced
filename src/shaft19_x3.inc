xpi:	.db 0
	.if EFIX = 0
xbit:	.db 1
xnot:	.db 0
xe:	.db 0
	.endif
xv:	.db 0
xp:	.db 0
	.if EFIX = 0
xrw:	.db 0
	.endif
xt:	.db 0
	.if EFIX = 0
cptr:	.db 0
	.endif
xup:	.db 0           ; this pass's composite uploads
nxmx:	.db 0           ; the most in one pass
nxup:	.dw 0           ; all
nxps:	.dw 0           ; passes with the phase not 0
	.if EFIX = 0
xwl:	.ds 6
xwh:	.ds 6
xbitt:	.db 1, 2
	.endif
xob:	.db 0
	.if XMASK = 0
	.if EFIX = 0
xlv:	.db 0           ; the last row's key value, left (valid when xll) / right (valid when xlok)
xrv:	.db 0
xlok:	.db 0
xll:	.db 0
	.endif
xbo:	.db 0           ; bit b: block 0 of band b is left out this pass (wbat gave its backdrop-class cells the screen's backdrop word)
xsl:	.db 0           ; a backdrop composite's source word, its strip's key page
xsh:	.db 0
xsp:	.db 0
xbit8:	.db 1, 2, 4, 8, 16, 32, 64, 128
	.if EFIX = 0
xri:	.db 0           ; this row's BAT row (rb + row)
	.endif
xmal:	.db $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80
	.if RSLACK
	.db $C0                 ; (row 35: buffer 1's last row at j = 1)
	.endif
xmah:	.db $00, $00, $00, $00, $01, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $03, $04, $04, $04, $04, $05, $05, $05, $05, $06, $06, $06, $06, $07, $07, $07, $07, $08, $08, $08
	.if RSLACK
	.db $08
	.endif
	.endif
	.if EFIX = 0
xrl:	.db 0
xrh:	.db 0
	.endif
	.if RSLACK
xrt:	.db 0
	.endif
xpass:	sty xob               ; (Y: kpass's buffer, obi)
	.if RSLACK
	lda cj                  ; (r19-slack-rows: the scroll sources 8 j + the Y phase, 8 k + the X phase)
	asl a
	asl a
	asl a
	sta xrt
	lda pyr
	and #6
	ora xrt
	sta c5byrv
	lda ck
	asl a
	asl a
	asl a
	sta xrt
	lda pxr
	and #6
	tax
	ora xrt
	sta c5bxrv
	txa
	.else
	.if YSM
	lda pyr
	and #6
	sta c5byrv
	.endif
	lda pxr
	and #6
	sta c5bxrv
	.endif
	.if EFIX
EKMAP      = $8000      ; DB_X (EFIX: the old cache's key pages): per set (+ 128 q) image index -> its slot + 1 (0: none)
ESK        = $8200      ; per set (+ 32 q): slot -> its image index ($FF: free)
ESU        = $8280      ; per set (+ 32 q): slot -> the stamp of the last regroup that used it
ERS        = $8300      ; per set (+ 32 q): row -> its slot
ENK        = $8400      ; near byte value -> image index (eset)
EKV        = $8500      ; image index -> its key value (eset; ENMAX)
EML        = $8580      ; cache slot g (1-72) -> its tile's VRAM address, low / high (eset)
EMH        = $8600
ERK        = $8680      ; scratch: the rows' image indices (17)
EFL        = $86A0      ; scratch: the slots to fill (18)
EWL        = $8700      ; cache slot g (1-72) -> its word, low / high (palette XPAL; eset; XD_TG's place)
EWH        = $8780
ENMAX      = 120        ; image indices on the card (the room's near map holds 111 key values [design 7.4])
epass:	lsr a                   ; (A = camera X & 6: the scroll part above)
	sta xpi
	beq .p0
	inc nxps
	bne .p0
	inc nxps+1
.p0:	tma #4
	pha
	lda #CB3                ; block 0's left-out bits of the 8 bands from the pass's out (bank 3): eraw (what wbat's diff saw); xbo as b7
	tam #4
	stz xbo
	ldx #14
.ob:	lda out - $4000,x
	lsr a
	rol xbo
	dex
	dex
	bpl .ob
	lda xbo
	sta eraw
	lda $3C22
	ora $3C23
	beq .o1
	stz xbo
.o1:
	.if PLG
	lda xpi                 ; (r19-plug-streams: off the grid S plugs block 0's column-2 cells; no static composite)
	beq .o2
	stz xbo
.o2:
	.endif
	lda #DB_X
	tam #4
	stz efc
	.if EP0
	ldx xob                 ; (EP0: on the X grid the words are direct, the near cells' S words and the bar word: no slot, no fill)
	lda xpi
	bne .e1
	lda rsh
	bne .eg
	lda edir,x
	bne .nf                 ; (direct already, the cell kept: only the left rows below)
.eg:	jsr edgo
	jmp .dn
.e1:	lda edir,x              ; off the grid after direct words: the slots regrouped afresh, filled, both columns
	beq .e2
	stz edir,x
	txa
	asl a
	tay
	lda #$FF
	sta esph,y
	sta esph+1,y
	bra .ch
.e2:
	.endif
	lda rsh
	bne .ch
	lda xob                 ; no cell change: each side's slots refilled when the phase moved
	asl a
	jsr eqs
	stz enf
	jsr efil
	lda xob
	asl a
	inc a
	jsr eqs
	stz enf
	jsr efil
	.if EP0
.nf:
	.endif
	ldx xob                 ; the left rows wbat wrote (block 0's bit changed), or whose backdrop composite changed or moved phase
	lda eraw
	eor eb0r,x
	sta em
	lda xbo
	eor exb,x
	ora em
	sta em
	lda xpi
	cmp epi,x
	beq .np
	lda xbo
	ora em
	sta em
.np:	lda em
	beq .dn
	jsr ebnd
	bra .dn
.ch:	lda xob                 ; a cell change: each side regrouped (afresh when its phase moved, else keeping its keys' slots) and its
	asl a                   ; slots filled, then the two columns of words
	jsr erg
	lda xob
	asl a
	inc a
	jsr erg
	jsr ecol
.dn:	ldx xob
	lda eraw
	sta eb0r,x
	lda xbo
	sta exb,x
	lda xpi
	sta epi,x
	lda efc
	sta efl
	pla
	tam #4
	rts
eq:	.db 0           ; the set (2 buffer + side), 32 q, 18 q + 1
eqo:	.db 0
egb:	.db 0
egbt:	.db 1, 19, 37, 55
esph:	.db $FF, $FF, $FF, $FF  ; per set: the X phase its slots hold ($FF: none)
esn:	.db 0, 0, 0, 0  ; per set: its slots in use are 0 .. esn - 1 (efast), $FF: anywhere (eysh)
EFL0:	.db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17
eb0r:	.db 0, 0        ; per buffer: block 0's left-out bits at its last pass, its xbo, its X phase
exb:	.db 0, 0
epi:	.db $FF, $FF
eraw:	.db 0
em:	.db 0
eb:	.db 0
er2:	.db 0
et:	.db 0
estmp:	.db 0           ; the regroups' stamp
enf:	.db 0           ; slots to fill (EFL)
efp:	.db 0           ; the free-slot scan's start
eblo:	.db 0
efc:	.db 0
ewlo:	.db 0
ewhi:	.db 0
eti:	.db $FF         ; the transparent word's image index (eset; $FF: none)
	.if EP0
edir:	.db 0, 0        ; per buffer: 1 = its edge words are direct (the X grid: S words, the bar word), its slots stale
	.endif
ecached:	.db 0
nebuild:	.db 0           ; set-ups that made them
eb6:	.db 0, 0, 0, 0  ; page 1's strip bytes (8 bar pixels: rails 15 .. 8, xset2)
e6q:	.db 15, 14, 13, 12, 11, 10, 9, 8
; the set A: eq, eqo = 32 q, egb = 18 q + 1
eqs:	sta eq
	tax
	lda egbt,x
	sta egb
	txa
	asl a
	asl a
	asl a
	asl a
	asl a
	sta eqo
	rts
; set eq's slots refilled for this pass's phase: all in use when the phase is not the one they hold, else the enf listed in EFL
efil:	ldx eq
	lda xpi
	cmp esph,x
	beq .nw
	sta esph,x
	lda esn,x               ; (all in use: slots 0 .. esn - 1 after efast; else a scan)
	cmp #$FF
	beq .sc
	sta enf
	lda #<EFL0
	sta .f+1
	lda #>EFL0
	sta .f+2
	bra .nz
.sc:	stz enf
	cly
.a:	tya
	clc
	adc eqo
	tax
	lda ESK,x
	cmp #$FF
	beq .an
	ldx enf
	tya
	sta EFL,x
	inc enf
.an:	iny
	cpy #18
	bne .a
.nw:	lda #<EFL
	sta .f+1
	lda #>EFL
	sta .f+2
.nz:	lda enf
	bne .go
	rts
.go:	lda eq
	and #1
	asl a
	asl a
	asl a
	asl a
	asl a
	sta eblo
	lda xpi
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	ora eblo
	sta eblo
	lda eqo                 ; (the set's ESK, EML, EMH)
	sta .a1+1
	lda egb
	sta .a3+1
	clc
	adc #<EML
	sta .a2+1
	tma #3
	pha
	lda #$40
	tam #3
	lda #$0B
	sta $1A04
	lda #2
	sta <VDCREG
	cly
.f:	ldx EFL,y
.a1:	lda ESK,x
	ora #$80
	sta $1A03
	lda eblo
	sta $1A02
	sei
	st0 #0
.a2:	lda EML,x
	sta $0002
.a3:	lda EMH,x
	sta $0003
	st0 #2
	cli
	tia $6000, $0002, 32
	iny
	cpy enf
	bne .f
	pla
	tam #3
	lda efc
	clc
	adc enf
	sta efc
	rts
; set eq regrouped afresh (its slots hold another phase: every slot is filled anyway): the old slots free, the rows' keys in slots 0 ..
efast:	lda eq                  ; (the bases of the set's EKMAP, ESK, ERS)
	lsr a
	pha
	cla
	ror a
	sta .k1+1
	sta .k2+1
	sta .k3+1
	pla
	clc
	adc #>EKMAP
	sta .k1+2
	sta .k2+2
	sta .k3+2
	lda eqo
	sta .e1+1
	sta .e2+1
	sta .e3+1
	sta .r1+1
	ldx #17
.u:
.e1:	ldy ESK,x
	cpy #$FF
	beq .un
	lda #$FF
.e2:	sta ESK,x
	cla
.k1:	sta EKMAP,y
.un:	dex
	bpl .u
	lda eq
	and #1
	beq .l
	lda #32
.l:	clc
	adc p0l
	sta .q+1
	lda p0h
	adc #0
	sec
	sbc #$60
	sta .q+2
	stz enf
	clx
.r:
.q:	ldy $6000
	lda ENK,y
	tay
.k2:	lda EKMAP,y
	bne .h
	phx
	ldx enf
	tya
.e3:	sta ESK,x
	plx
	inc enf
	lda enf
.k3:	sta EKMAP,y
.h:	dec a
.r1:	sta ERS,x
	lda .q+1
	clc
	adc #64
	sta .q+1
	bcc .n1
	inc .q+2
.n1:	inx
	cpx #XROWS
	bne .r
	ldx eq
	lda enf
	sta esn,x
	stz enf                 ; (efil: every slot in use)
	rts
; set eq after a shift of one row in Y with its phase kept (rdy: + 1 down, - 1 up): ERS moved by a row, the entering row's key its slot
; (the one it holds, else a slot no other row uses: listed to fill, EFL / enf)
eysh:	lda eq                  ; (the set's EKMAP)
	lsr a
	pha
	cla
	ror a
	sta .k1+1
	sta .k2+1
	sta .k3+1
	pla
	clc
	adc #>EKMAP
	sta .k1+2
	sta .k2+2
	sta .k3+2
	ldx eqo
	ldy #16
	lda rdy
	bmi .up
.d:	lda ERS+1,x
	sta ERS,x
	inx
	dey
	bne .d
	lda #16
	bra .e
.up:	txa
	clc
	adc #16
	tax
.u:	lda ERS-1,x
	sta ERS,x
	dex
	dey
	bne .u
	cla
.e:	sta er2                 ; the entering row: its near byte at p0 (+ 32 right) + 64 row
	tax
	lda eq
	and #1
	beq .l
	lda #32
.l:	clc
	adc p0l
	php
	clc
	adc xmal,x
	sta .q+1
	lda p0h
	adc xmah,x
	plp
	adc #0
	sec
	sbc #$60
	sta .q+2
.q:	ldy $6000
	lda ENK,y
	sta et
	tay
.k1:	lda EKMAP,y
	bne .h
	ldx #17                 ; a slot no other row uses
.c:	stz EFL,x
	dex
	bpl .c
	ldx #16
.m:	cpx er2
	beq .mn
	txa
	clc
	adc eqo
	tay
	lda ERS,y
	tay
	lda #1
	sta EFL,y
.mn:	dex
	bpl .m
	cly
.s:	lda EFL,y
	beq .sf
	iny
	bra .s
.sf:	tya
	clc
	adc eqo
	tax
	lda ESK,x
	cmp #$FF
	beq .nk
	phy
	tay
	cla
.k2:	sta EKMAP,y
	ply
.nk:	lda et
	sta ESK,x
	ldx et
	tya
	inc a
.k3:	sta EKMAP,x
	sty EFL
	lda #1
	sta enf
	tya
	bra .st
.h:	dec a
	stz enf
.st:	pha
	lda er2
	clc
	adc eqo
	tax
	pla
	sta ERS,x
	ldx eq
	lda #$FF
	sta esn,x
	rts
	.if EP0
; ewd with direct words: row er2's near byte (p0 + 64 row, the left column): b7's backdrop word on the grid where it applies, else its
; S word
ewdd:	ldx er2
	lda p0l
	clc
	adc xmal,x
	sta .q+1
	lda p0h
	adc xmah,x
	sec
	sbc #$60
	sta .q+2
.q:	ldy $6000
	cpx #16
	bcs .s
	lda xbo
	and erb,x
	beq .s
	lda ENK,y
	cmp eti
	bne .s
	jmp ewd_sw
.s:	lda KSWL,y
	sta ewlo
	lda KSWH,y
	sta ewhi
	rts
	.endif
ewd:
	.if EP0
	ldx xob
	lda edir,x
	beq .sl
	jmp ewdd
.sl:
	.endif
	lda er2
	clc
	adc eqo
	tax
	lda ERS,x
	sta et                  ; the slot
	lda er2
	cmp #16
	bcs .s
	tax
	lda xbo
	and erb,x
	beq .s
	lda et
	clc
	adc eqo
	tax
	lda ESK,x
	cmp eti
	bne .s
	ldx xpi
	bne .c
	ldx er2                 ; on the grid: XD_SW + 64 row
	jmp ewd_sw
.c:	txa
	dec a
	asl a
	asl a
	asl a
	asl a
	ora er2
	tax
	lda XD_BTL+1,x
	sta ewlo
	lda XD_BTH+1,x
	ora #$10
	sta ewhi
	rts
.s:	lda et
	clc
	adc egb
	tax
	lda EWL,x
	sta ewlo
	lda EWH,x
	sta ewhi
	rts
ewd_sw:	lda xmal,x
	sta .l+1
	inc a
	sta .h+1
	lda xmah,x
	clc
	adc #>XD_SW
	sta .l+2
	sta .h+2
.l:	lda XD_SW
	sta ewlo
.h:	lda XD_SW+1
	sta ewhi
	rts
erb:	.db 1, 1, 2, 2, 4, 4, 8, 8, 16, 16, 32, 32, 64, 64, 128, 128
; the two columns of the buffer's edge words, the VDC's increment 64 (R's rinc64 / rinc1): left from (rbe, cbe), right from (rbe, cbe + 32)
ecol:	jsr rinc64
	lda xob
	asl a
	jsr eqs
	lda eqo
	sta .s0+1
	sta .s1+1
	lda egb
	sta .w0+1
	sta .w1+1
	ora #$80
	sta .h0+1
	sta .h1+1
	ldx rbe
	vsel 0
	lda xmal,x
	ora cbe
	sta $0002
	lda xmah,x
	sta $0003
	vsel 2
	lda xbo
	bne .lb
	clx
.lf:
.s0:	ldy ERS,x
.w0:	lda EWL,y
	sta $0002
.h0:	lda EWH,y
	sta $0003
	inx
	cpx #XROWS
	bne .lf
	bra .rs
.lb:	stz er2
.l:	ldx er2
	cpx #16
	bcs .ln
	lda xbo
	and erb,x
	beq .ln
	jsr ewd
	lda ewlo
	sta $0002
	lda ewhi
	sta $0003
	bra .lx
.ln:
.s1:	ldy ERS,x
.w1:	lda EWL,y
	sta $0002
.h1:	lda EWH,y
	sta $0003
.lx:	inc er2
	lda er2
	cmp #XROWS
	bne .l
.rs:	lda xob
	asl a
	inc a
	jsr eqs
	lda eqo
	sta .s2+1
	lda egb
	sta .w2+1
	ora #$80
	sta .h2+1
	ldx rbe
	vsel 0
	lda xmal,x
	ora cbe
	ora #32
	sta $0002
	lda xmah,x
	sta $0003
	vsel 2
	clx
.r:
.s2:	ldy ERS,x
.w2:	lda EWL,y
	sta $0002
.h2:	lda EWH,y
	sta $0003
	inx
	cpx #XROWS
	bne .r
	jmp rinc1
	.endif
	.if EFIX = 0
	.if XMASK
	rts                     ; (the bars on the masks: nothing else)
	.endif
	lsr a
	sta xpi
	beq .p0
	inc nxps
	bne .p0
	inc nxps+1
.p0:	tma #4
	pha
	.if XMASK = 0
	lda #CB3
	tam #4
	stz xbo
	ldx #14
.ob:	lda out - $4000,x
	lsr a
	rol xbo
	dex
	dex
	bpl .ob
	lda $3C22
	ora $3C23
	beq .o1
	stz xbo
.o1:
	.endif
	lda #DB_X
	tam #4
	stz xup
	.if XMASK
	ldx xob                 ; this buffer's edge slots: listed from XD_ESL + 32 b on (a miss takes a slot in neither list: xfree)
	lda xbitt,x
	sta xbit
	eor #$FF
	sta xnot
	txa
	asl a
	asl a
	asl a
	asl a
	asl a
	sta xe
	sta xeb
	eor #32
	sta xeo                 ; the other buffer's list
	lda xpi                 ; (on the grid no composite: this buffer's list empty)
	bne .rn
	ldx xe
	ldy #32
.rl:	stz XD_ESL,x
	inx
	dey
	bne .rl
	.else
	ldx xob                 ; (r19-bars-off-sprites) the slots in use are TAGGED, not listed: a slot is this buffer's when its tag in
	inc xsr,x               ; table XD_TG + 128 b is the serial of this buffer's pass (xsr, 1-255, one step a pass: its old uses are
	bne .s1                 ; free at once); the other buffer's when its tag there is that buffer's serial (its last pass: what it shows).
	jsr xtclr               ; A miss tests a slot in two reads (xfree); the lists' scans cost up to about 1.2k cycles a slot tried
.s1:	lda xsr,x
	sta xser
	lda xtlo,x
	sta xctg+1
	sta xffs+1
	txa
	eor #1
	tay
	lda xsr,y
	sta xsero
	lda xtlo,y
	sta xffo+1
	.endif
.rn:
	lda xpi                 ; the bars' words of this phase (every row alike)
	asl a
	asl a
	tax
	lda XD_BRL,x
	sta xwl
	lda XD_BRH,x
	ora #$F0
	sta xwh
	lda XD_BRL+1,x
	sta xwl+1
	lda XD_BRH+1,x
	ora #$F0
	sta xwh+1
	lda XD_BRL+2,x
	sta xwl+4
	lda XD_BRH+2,x
	ora #$F0
	sta xwh+4
	lda XD_BRL+3,x
	sta xwl+5
	lda XD_BRH+3,x
	ora #$F0
	sta xwh+5
	lda p0h
	sec
	sbc #$60
	sta .ql+2
	sta .qr+2
	lda p0l
	sta .ql+1
	clc
	adc #32
	sta .qr+1
	bcc .q0
	inc .qr+2
.q0:	stz xrw
	.if XMASK = 0
	stz xlok
	stz xll
	.if RSLACK
	lda cbe                 ; (r19-slack-rows: the window's columns 2 + k and 34 + k, its first row rb + j)
	sta .c2+1
	clc
	adc #32
	sta .c34+1
	lda rbe
	.else
	lda rb
	.endif
	sta xri
	lda XD_BRL+16           ; (column 34 on the grid: the bar's word, every row)
	sta xwl+3
	lda XD_BRH+16
	ora #$F0
	sta xwh+3
	.endif
.row:
.ql:	lda $6000
	.if XMASK = 0
	ldy xbo
	beq .bz
	jmp .bq
.bz:
	.endif
	ldx xpi
	bne .lc
	tax
	lda KSWL,x
	sta xwl+2
	lda KSWH,x
	sta xwh+2
	bra .rr
.lc:	tay
	lda XD_VMAP,y           ; (byte values of one S word share a key: the transparent word's)
	.if XMASK = 0
	cmp xlv                 ; (r19-bars-off-sprites: the row above's key again: its word again, already tagged; about 90 cycles saved)
	bne .lm
	ldy xll
	bne .rr
.lm:	sta xlv
	ldy #1
	sty xll
	.endif
	pha
	txa
	dec a
	asl a
	tay                     ; key page 2 (pi - 1)
	pla
	jsr xcget
	lda XD_CTL,x
	sta xwl+2
	lda XD_CTH,x
	ora #XPAL << 4
	sta xwh+2
.rr:
	.if XMASK = 0
	ldx xpi                 ; (on the grid column 34's bar word was set before the rows)
	beq .wr
	.endif
.qr:	lda $6000
	ldx xpi
	bne .rc
	lda XD_BRL+16
	sta xwl+3
	lda XD_BRH+16
	ora #$F0
	sta xwh+3
	bra .wr
.rc:	tay
	lda XD_VMAP,y
	.if XMASK = 0
	cmp xrv
	bne .rm
	ldy xlok
	bne .wr
.rm:	sta xrv
	.endif
	pha
	txa
	dec a
	asl a
	inc a
	tay                     ; key page 2 (pi - 1) + 1
	pla
	jsr xcget
	lda XD_CTL,x
	sta xwl+3
	lda XD_CTH,x
	ora #XPAL << 4
	sta xwh+3
	.if XMASK = 0
	lda #1                  ; (both sides' words of a row made: the next row may reuse them)
	sta xlok
	.endif
.wr:
	.if XMASK = 0
	.if XBAR = 0
	ldx xri                 ; (r19-bars-off-sprites: MAWR = 64 (rb + row) from a table, each address once)
	vsel 0
	lda xmal,x
.c2:	ora #2
	sta $0002
	lda xmah,x
	sta $0003
	vsel 2
	lda xwl+2
	sta $0002
	lda xwh+2
	sta $0003
	vsel 0
	lda xmal,x
.c34:	ora #34
	sta $0002
	lda xmah,x
	sta $0003
	vsel 2
	lda xwl+3
	sta $0002
	lda xwh+3
	sta $0003
	inc xri
	jmp .wn
	.endif
	.endif
	lda xrw                 ; MAWR = 64 (rb + row)
	clc
	adc rb
	stz xrl
	lsr a
	ror xrl
	lsr a
	ror xrl
	sta xrh
	vsel 0
	lda xrl
	sta $0002
	lda xrh
	sta $0003
	.if XBAR
	vsel 2
	lda xwl
	sta $0002
	lda xwh
	sta $0003
	lda xwl+1
	sta $0002
	lda xwh+1
	sta $0003
	.else
	lda xrl                 ; (black bars: columns 0, 1, 35, 36 never change: written at the set-up)
	ora #2
	sta $0002
	vsel 2
	.endif
	lda xwl+2
	sta $0002
	lda xwh+2
	sta $0003
	vsel 0
	lda xrl
	ora #34
	sta $0002
	lda xrh
	sta $0003
	vsel 2
	lda xwl+3
	sta $0002
	lda xwh+3
	sta $0003
	.if XBAR
	lda xwl+4
	sta $0002
	lda xwh+4
	sta $0003
	lda xwl+5
	sta $0002
	lda xwh+5
	sta $0003
	.endif
.wn:	lda .ql+1
	clc
	adc #64
	sta .ql+1
	bcc .n1
	inc .ql+2
.n1:	lda .qr+1
	clc
	adc #64
	sta .qr+1
	bcc .n2
	inc .qr+2
.n2:	inc xrw
	lda xrw
	cmp #XROWS
	.if XMASK = 0
	beq .ej
	jmp .row
.ej:	jmp .e
	.else
	beq .e
	jmp .row
	.endif
	.if XMASK = 0
.bq:	pha                     ; (xbo not 0) row < 16, its band's block 0 left out, the cell's S word the transparent word: the backdrop
	ldy xrw
	cpy #16
	bcs .bn
	tya
	lsr a
	tay
	lda xbo
	and xbit8,y
	beq .bn
	ply
	lda KSWL,y
	cmp #$C5
	bne .bn2
	lda KSWH,y
	bne .bn2
	stz xll                 ; (the next row's left word not from this one)
	lda xrw                 ; the screen's backdrop word of (row, column 2): XD_SW + 64 row
	lsr a
	lsr a
	clc
	adc #>XD_SW
	sta .sl+2
	sta .sh+2
	lda xrw
	and #3
	lsr a
	ror a
	ror a
	sta .sl+1
	inc a
	sta .sh+1
.sl:	lda XD_SW
	sta xsl
.sh:	lda XD_SW+1
	sta xsh
	ldx xpi
	bne .bc
	lda xsl                 ; on the grid: that word (what wbat wrote there)
	sta xwl+2
	lda xsh
	sta xwh+2
	jmp .rr
.bc:	txa
	dec a                   ; 1 is black, made at the set-up (xbkset) in backdrop-cache slot 16 (pi - 1) + row + 1
	asl a
	asl a
	asl a
	asl a
	ora xrw
	tax
	lda XD_BTL+1,x
	sta xwl+2
	lda XD_BTH+1,x
	ora #$10
	sta xwh+2
	jmp .rr
.bn:	pla
	jmp .bz
.bn2:	tya
	jmp .bz
	.endif
.e:	lda xup
	cmp nxmx
	bcc .x
	sta nxmx
.x:
	.if XBG
	jsr xbg
	.endif
	pla
	tam #4
	rts

; the cache slot of composite (near byte A, key page Y): X = the slot, marked used by this buffer and listed in its edge slots
xcget:	sta xv
	sty xp
	tax
	tya
	clc
	adc #>XD_CTAB
	sta .t+2
	sta .t2+2
.t:	ldy XD_CTAB,x
	bne .h
	ldy cptr                ; a miss: the next slot no buffer uses (at most 2 x 34 of XCNU in use)
.f:	iny
	cpy #XCNU + 1
	bcc .f1
	ldy #1
.f1:	jsr xfree
	bcs .f
	sty cptr
	lda XD_CKP,y            ; its old key forgotten
	beq .ne
	clc
	adc #(>XD_CTAB) - 1
	sta .e+2
	ldx XD_CKV,y
	cla
.e:	sta XD_CTAB,x
.ne:	lda xp
	inc a
	sta XD_CKP,y
	ldx xv
	txa
	sta XD_CKV,y
	tya
.t2:	sta XD_CTAB,x
	jsr xcup
	.if XMASK
.h:	ldx xe
	tya
	sta XD_ESL,x
	inc xe
	tax
	rts
	.else
.h:	lda xser                ; (tagged: this buffer's pass uses it)
xctg:	sta XD_TG,y
	tya
	tax
	rts
	.endif
	.if XMASK
; carry set: slot Y is in the other buffer's 32 edge slots or in this pass's (XD_ESL + xeb .. xe - 1)
xfree:	tya
	ldx xeo
	phy
	ldy #32
.o:	cmp XD_ESL,x
	beq .u
	inx
	dey
	bne .o
	ldx xeb
.t:	cpx xe
	beq .f
	cmp XD_ESL,x
	beq .u
	inx
	bra .t
.f:	ply
	clc
	rts
.u:	ply
	sec
	rts
xeb:	.db 0
xeo:	.db 0
	.else
; carry set: slot Y is tagged by this pass or by the other buffer's last pass (A changed; X, Y kept)
xfree:
xffs:	lda XD_TG,y
	cmp xser
	beq xfu
xffo:	lda XD_TG,y
	cmp xsero
	beq xfu
	clc
	rts
xfu:	sec
	rts
xser:	.db 0           ; this pass's serial, the other buffer's
xsero:	.db 0
xsr:	.db 1, 1        ; per buffer: its last pass's serial (1-255)
xtlo:	.db <XD_TG, <(XD_TG + 128)
; buffer X's tag table zero (its serial wrapped): its serial 1 (a zero tag never matches)
xtclr:	lda xtlo,x
	sta .z+1
	ldy #128
	cla
.z:	sta XD_TG
	inc .z+1
	dey
	bne .z
	lda #1
	sta xsr,x
	rts
	.endif
	.endif
; the composite (xv, xp) made into slot Y's tile: the near tile of byte xv's S word read from VRAM, its pixels outside the strip kept,
; the strip's from the set-up's bytes (XD_BB, XD_NM)
xcup:                           ; (r19-edge-fixed: with E only the set-up's backdrop composites)
	.if XMASK = 0
	.if EFIX = 0
	lda xp                  ; (key page $10: a backdrop composite, its source word xsl / xsh)
	cmp #$10
	bcc .nw
	.endif
	lda xsh
	and #7
	sta xt
	lda xsl
	.if EFIX = 0
	bra .ad
.nw:
	.endif
	.endif
	.if EFIX = 0
	ldx xv
	lda KSWH,x
	and #7
	sta xt
	lda KSWL,x
	.endif
.ad:	asl a
	rol xt
	asl a
	rol xt
	asl a
	rol xt
	asl a
	rol xt
	ldx xt
	jsr vmarr
	tai $0002, XD_BUF, 8
	tai $0002, XD_BUF + 8, 8
	tai $0002, XD_BUF + 16, 8
	tai $0002, XD_BUF + 24, 8
	.if XMASK = 0
	.if EFIX = 0
	lda xp
	cmp #$10
	bcc .ns
	.endif
	ldx xsp                 ; (a backdrop composite: the strip in colour 1, planes 1-3 clear)
	lda XD_NM,x
	sta xm
	eor #$FF
	sta xb0
	stz xb1
	stz xb2
	stz xb3
	.if EFIX = 0
	bra .go
.ns:
	.endif
	.endif
	.if EFIX = 0
	ldx xp
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
	.endif
.go:	ldx #0
.c:	lda XD_BUF,x
	and xm
	ora xb0
	sta XD_BUF,x
	lda XD_BUF+1,x
	and xm
	ora xb1
	sta XD_BUF+1,x
	lda XD_BUF+16,x
	and xm
	ora xb2
	sta XD_BUF+16,x
	lda XD_BUF+17,x
	and xm
	ora xb3
	sta XD_BUF+17,x
	inx
	inx
	cpx #16
	bne .c
	.if XMASK = 0
	.if EFIX = 0
	lda xp                  ; (a backdrop composite, set-up only: into backdrop-cache slot xv + 1)
	cmp #$10
	bcc .dn
	.endif
	ldx xv
	lda XD_BTH+1,x
	sta xt
	lda XD_BTL+1,x
	.if EFIX = 0
	bra .da
.dn:
	.endif
	.endif
	.if EFIX = 0
	lda XD_CTH,y            ; MAWR = tile * 16
	sta xt
	lda XD_CTL,y
	.endif
.da:	asl a
	rol xt
	asl a
	rol xt
	asl a
	rol xt
	asl a
	rol xt
	tax
	vsel 0
	stx $0002
	lda xt
	sta $0003
	vsel 2
	tia XD_BUF, $0002, 8
	tia XD_BUF + 8, $0002, 8
	tia XD_BUF + 16, $0002, 8
	tia XD_BUF + 24, $0002, 8
	.if EFIX = 0
	inc xup
	inc nxup
	bne .x
	inc nxup+1
	.endif
.x:	rts
	.if XMASK = 0
	.if PLG = 0
xbkset:	stz xv
.k:	lda xv
	and #15
	lsr a
	lsr a
	clc
	adc #>XD_SW
	sta .l+2
	sta .h+2
	lda xv
	and #3
	lsr a
	ror a
	ror a
	sta .l+1
	inc a
	sta .h+1
.l:	lda XD_SW
	sta xsl
.h:	lda XD_SW+1
	sta xsh
	lda xv
	lsr a
	lsr a
	lsr a
	and #$FE
	sta xsp                 ; 2 (pi - 1): the left strip's key page
	lda #$10
	sta xp
	jsr xcup
	inc xv
	lda xv
	cmp #48
	bne .k
	rts
	.endif
	.endif
xm:	.db 0
xb0:	.db 0
xb1:	.db 0
xb2:	.db 0
xb3:	.db 0

	.if XBG | (RSLACK = 0)
; ---------------------------------------------------------------- the backdrop under the blocks left out for sprite units (this buffer,
xbg:	lda xob
	asl a
	asl a
	asl a
	asl a
	asl a
	tax                     ; LK + 32 b
	stz xchg
	lda p0l
	cmp XD_LK,x
	beq .c1
	inc xchg
	sta XD_LK,x
.c1:	lda p0h
	cmp XD_LK+1,x
	beq .c2
	inc xchg
	sta XD_LK+1,x
.c2:	lda xpi
	cmp XD_LK+2,x
	beq .c3
	inc xchg
	sta XD_LK+2,x
.c3:	ldy #0
.c4:	lda XD_OUT,y
	cmp XD_LK+3,x
	beq .c5
	inc xchg
	sta XD_LK+3,x
.c5:	inx
	iny
	cpy #16
	bne .c4
	lda xchg
	bne .go
	rts
.go:	stz xbu
	lda xob
	lsr a
	cla
	ror a
	sta xlb                 ; the list's base: 0 / $80
	tax
	ldy xob
	lda XD_LN,y
	sta xoc
	beq .new
.old:	ldy XD_LS,x             ; the old cells: released, their S word back
	beq .o1
	lda XD_BUSE,y
	and xnot
	sta XD_BUSE,y
.o1:	lda XD_LR,x
	sta xr
	lda XD_LC,x
	sta xc
	phx
	jsr xsword
	jsr xbat
	plx
	inx
	dec xoc
	bne .old
.new:	stz xn
	stz xbd
.bd:	lda xbd
	asl a
	tay
	lda XD_OUT,y
	sta xo0
	lda XD_OUT+1,y
	sta xo1
	stz xbi
.bl:	lda xbi
	cmp #8
	bcs .bh
	lsr xo0
	bra .bt
.bh:	lsr xo1
.bt:	bcc .bn
	jsr xblk
.bn:	inc xbi
	lda xbi
	cmp #16
	bne .bl
	inc xbd
	lda xbd
	cmp #8
	bne .bd
	ldy xob
	lda xn
	sta XD_LN,y
	lda xbu
	cmp nxbm
	bcc .x
	sta nxbm
.x:	rts
; block (xbd, xbi): its cells
xblk:	stz xrr
.r:	lda xbd
	asl a
	ora xrr
	sta xr
	stz xcc
.c:	lda xbi
	asl a
	clc
	adc #2
	adc xcc
	sta xc
	ldx xpi
	beq .g
	cmp #2
	bne .g1
	jmp .s3
.g1:	cmp #34
	bne .g
	jmp .s3
.g:	sec                     ; the cell's class: window column w = c - 2, bit 7 - (w & 7) of rows' byte 4 r + (w >> 3)
	sbc #2
	sta xw
	lsr a
	lsr a
	lsr a
	sta xt
	lda xr
	asl a
	asl a
	ora xt
	tay
	lda xw
	and #7
	tax
	lda XD_ROWS,y
	and xbm8,x
	beq .nx
	ldx xpi
	bne .ph
	lda xr                  ; on the grid: the screen's backdrop word (XD_SW + 64 r + 2 w)
	lsr a
	lsr a
	clc
	adc #>XD_SW
	sta .sw+2
	sta .sh+2
	lda xr
	and #3
	lsr a
	ror a
	ror a
	sta xt
	lda xw
	asl a
	ora xt
	tax
.sw:	lda XD_SW,x
	sta xwl
.sh:	lda XD_SW+1,x
	sta xwh
	cly
	bra .w
.ph:	jsr xbget               ; off the grid: Y = the cache slot of the phase tile
	cpy #0
	bne .p1
	jmp .nx
.p1:	lda XD_BTL,y
	sta xwl
	lda XD_BTH,y
	ora #$10
	sta xwh
.w:	phy
	jsr xbat
	ply
	lda xn                  ; listed
	cmp #127
	bcs .nx
	clc
	adc xlb
	tax
	lda xr
	sta XD_LR,x
	lda xc
	sta XD_LC,x
	tya
	sta XD_LS,x
	inc xn
.nx:	inc xcc
	lda xcc
	ldx xpi
	beq .k2
	cmp #3
	beq .k3
	jmp .c
.k2:	cmp #2
	beq .k3
	jmp .c
.k3:	inc xrr
	lda xrr
	cmp #2
	beq .kx
	jmp .r
.kx:	rts
.s3:	inc nx3                 ; (an edge column off the grid beside a left-out block: not mended)
	bne .nx
	inc nx3+1
	bra .nx
xbm8:	.db $80, $40, $20, $10, $08, $04, $02, $01
xsword:	lda xr
	lsr a
	lsr a
	sta xt
	lda xr
	and #3
	lsr a
	ror a
	ror a
	clc
	adc xc
	bcc .a
	inc xt
.a:	sec
	sbc #2
	bcs .b
	dec xt
.b:	clc
	adc p0l
	sta .q+1
	lda p0h
	sbc #$5F                ; (carry: + 1 from the add, - $60)
	clc
	adc xt
	sta .q+2
.q:	ldx $6000
	lda KSWL,x
	sta xwl
	lda KSWH,x
	sta xwh
	rts
; BAT (rb + xr, xc) = xwl / xwh
xbat:	lda xr
	clc
	adc rb
	stz xt
	lsr a
	ror xt
	lsr a
	ror xt
	tax
	vsel 0
	lda xt
	ora xc
	sta $0002
	stx $0003
	vsel 2
	lda xwl
	sta $0002
	lda xwh
	sta $0003
	rts
; the backdrop cache slot (Y) of phase tile (xpi, xr, xc): key 512 (pi - 1) + 32 r + c - 3 (XD_BTAB)
xbget:	lda xr
	and #7
	asl a
	asl a
	asl a
	asl a
	asl a
	sta xk0
	lda xc
	sec
	sbc #3
	ora xk0
	sta xk0
	lda xpi
	dec a
	asl a
	sta xk1
	lda xr
	lsr a
	lsr a
	lsr a
	ora xk1
	sta xk1
	clc
	adc #>XD_BTAB
	sta .t+2
	sta .t2+2
	ldx xk0
.t:	ldy XD_BTAB,x
	bne .h
	lda #XBN
	sta xtry
	ldy bptr                ; a miss: the next slot no buffer uses (none: Y 0, the cell not mended, nbfull)
.f:	iny
	cpy #XBN + 1
	bcc .f1
	ldy #1
.f1:	lda XD_BUSE,y
	beq .f2
	dec xtry
	bne .f
	inc nbfull
	bne .f0
	inc nbfull+1
.f0:	cly
	rts
.f2:	sty bptr
	lda XD_BKL,y            ; its old key (+ 1) forgotten
	ora XD_BKH,y
	beq .ne
	lda XD_BKL,y
	sec
	sbc #1
	tax
	lda XD_BKH,y
	sbc #0
	clc
	adc #>XD_BTAB
	sta .e+2
	cla
.e:	sta XD_BTAB,x
.ne:	lda xk0
	clc
	adc #1
	sta XD_BKL,y
	lda xk1
	adc #0
	sta XD_BKH,y
	ldx xk0
	tya
.t2:	sta XD_BTAB,x
	jsr xbup
.h:	lda XD_BUSE,y
	ora xbit
	sta XD_BUSE,y
	rts
xbup:	lda xk0
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $1A02
	lda xk0
	lsr a
	lsr a
	lsr a
	sta xt
	lda xk1
	and #1
	asl a
	asl a
	asl a
	asl a
	asl a
	ora xt
	ldx xpi
	clc
	adc xbhi-1,x
	sta $1A03
	lda xbb2-1,x
	sta $1A04
	tai $1A00, XD_BUF, 8
	tai $1A00, XD_BUF + 8, 8
	tai $1A00, XD_BUF + 16, 8
	tai $1A00, XD_BUF + 24, 8
	lda XD_BTH,y
	sta xt
	lda XD_BTL,y
	asl a
	rol xt
	asl a
	rol xt
	asl a
	rol xt
	asl a
	rol xt
	tax
	vsel 0
	stx $0002
	lda xt
	sta $0003
	vsel 2
	tia XD_BUF, $0002, 8
	tia XD_BUF + 8, $0002, 8
	tia XD_BUF + 16, $0002, 8
	tia XD_BUF + 24, $0002, 8
	inc xbu
	inc nxbu
	bne .x
	inc nxbu+1
.x:	rts
xbhi:	.db $60, $A0, $60
xbb2:	.db $01, $01, $02
xchg:	.db 0
xlb:	.db 0
xoc:	.db 0
xtry:	.db 0
nbfull:	.dw 0
xn:	.db 0
xbd:	.db 0
xbi:	.db 0
xo0:	.db 0
xo1:	.db 0
xrr:	.db 0
xcc:	.db 0
xr:	.db 0
xc:	.db 0
xw:	.db 0
xk0:	.db 0
xk1:	.db 0
bptr:	.db 0
xbu:	.db 0           ; this pass's phase tile uploads
nxbm:	.db 0           ; the most in one pass
nxbu:	.dw 0           ; all
nx3:	.dw 0           ; edge cells beside a left-out block off the grid (not mended)
	.endif
