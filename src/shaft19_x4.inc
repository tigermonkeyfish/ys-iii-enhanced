xunp:	lda FINEADC
	cmp #$6D
	bne .x
	lda FINEADC+2
	cmp #$2D
	bne .x
	lda FINEADC+1
	cmp #$09
	bne .x
	lda #$10
	sta FINEADC+1
.x:	stz BXRV
	.if YSM
	lda FINEADCY
	cmp #$6D
	bne .y
	lda FINEADCY+2
	cmp #$2D
	bne .y
	lda FINEADCY+1
	cmp #$09
	bne .y
	lda #$11
	sta FINEADCY+1
.y:	stz BYRV
	.endif
	rts
xsd:	tma #3
	pha
	lda #DB_X
	tam #3
	stz xsdr
.l:	lda xsdr
	cmp #16
	bcc .0
	adc #1
.0:	ldx #36
	jsr vbat
	lda xsdr
	asl a
	tax
	lda XD_C36 - $2000,x
	sta $0002
	lda XD_C36 - $2000 + 1,x
	sta $0003
	inc xsdr
	lda xsdr
	cmp #32
	bne .l
	ldx #31
.z:	stz XPALB,x
	dex
	bpl .z
	.if YSM
	jsr xr16b
	.endif
	lda xsdc                ; (r19-load-exit-slots) the caches' copy once per stand-down, at its first sdwork: the engaged passes, the
	bne .x                  ; caches' only writers, have ended by then; at the second (the next pass) a window may already have drawn its
	inc xsdc                ; own tiles into cache slots, which the copy took for ours (the exit restore then put the set-up's back)
	ldy #1
.sn:	lda XD_CTL - $2000,y
	sta yt0
	lda XD_CTH - $2000,y
	sta yt1
	tya
	clc
	adc #<528
	sta xcl
	lda #>528
	adc #0
	sta xch
	cpy #48
	bcc .s1
	lda xcl
	adc #3                  ; (carry set: + 4)
	sta xcl
	bcc .s1
	inc xch
.s1:	jsr .cp
	iny
	cpy #XCN + 1
	bne .sn
	ldy #1
.sb:	lda XD_BTL - $2000,y
	sta yt0
	lda XD_BTH - $2000,y
	sta yt1
	tya
	clc
	adc #<628
	sta xcl
	lda #>628
	adc #0
	sta xch
	jsr .cp
	iny
	cpy #XBN + 1
	bne .sb
.x:
	.if XTB = 0
	lda sdlv
	bne .xt
	lda sdwhy
	cmp #3
	beq .nx
	cmp #4
	beq .nx
.xt:	jsr xrsttb
.nx:
	.endif
	pla
	tam #3
	rts
.cp:	jsr xrst_ad
	jsr vmarr
	tai $0002, XD_BUF - $2000, 8
	tai $0002, XD_BUF - $2000 + 8, 8
	tai $0002, XD_BUF - $2000 + 16, 8
	tai $0002, XD_BUF - $2000 + 24, 8
	jsr x4cb
	tia XD_BUF - $2000, $1A00, 8
	tia XD_BUF - $2000 + 8, $1A00, 8
	tia XD_BUF - $2000 + 16, $1A00, 8
	tia XD_BUF - $2000 + 24, $1A00, 8
	rts
xsdr:	.db 0
xsdc:	.db 0           ; (r19-load-exit-slots) 1: this stand-down's cache copy taken (xset2 clears it: engaged again)
xtb:	.db 0           ; (HW-r19-frame-lines) 1: XD_TB already holds the set-up's BAT rows 36/47 (reeng skips re-saving)

XKEY       = 1          ; the composite table's format (its key at $0E2000: $19 $58 XKEY)
xv2:	.db 0
yk:	.db 0
yt0:	.db 0
yt1:	.db 0
xtl:	.db 0           ; (r19-reload-hang) a tile number (xsd's slot copies, x4rd): this bank's own. It was the cold bank's tl / th
xth:	.db 0
yt2:	.db 0
yq0:	.db 0
ynx:	.db 0
xcl:	.db 0
xch:	.db 0
ybb:	.ds 24
xnm:	.ds 6
nxset:	.db 0           ; set-ups that made the composite table (not cached)
xadc:	.db 0
xcq:	.db 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 15, 14, 13, 12, 11, 10, 12, 13, 14, 15, 255, 255, 255, 255
	.db 255, 255, 255, 255, 15, 14, 13, 12, 10, 11, 12, 13, 14, 15, 255, 255, 255, 255, 255, 255, 255, 255, 15, 14
; the near tile (xtl, xth) -> XD_N (DB_X at MPR4)
x4rd:	lda xtl
	sta yt0
	lda xth
	asl yt0
	rol a
	asl yt0
	rol a
	asl yt0
	rol a
	asl yt0
	rol a
	tax
	lda yt0
	jsr vmarr
	tai $0002, XD_N, 8
	tai $0002, XD_N + 8, 8
	tai $0002, XD_N + 16, 8
	tai $0002, XD_N + 24, 8
	rts
x4cb:	lda #2
	sta $1A04
	lda xcl
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $1A02
	lda xch
	asl a
	asl a
	asl a
	asl a
	asl a
	sta yt0
	lda xcl
	lsr a
	lsr a
	lsr a
	ora yt0
	sta $1A03
	rts
xset2:	stz xsdc
	tma #3
	pha
	tma #4
	pha
	lda #DB_NEAR
	tam #3
	lda #DB_X
	tam #4
	stz yk                  ; the strips' plane bytes and the near masks per key page
.kp:	lda yk
	asl a
	asl a
	tax                     ; 4 k
	asl a
	tay                     ; 8 k
	stz ybb,x
	stz ybb+1,x
	stz ybb+2,x
	stz ybb+3,x
	stz yt2
	lda #8
	sta yt1
.kb:	lda xcq,y
	cmp #$FF
	bne .kr
	sec
	rol yt2
	asl ybb,x
	asl ybb+1,x
	asl ybb+2,x
	asl ybb+3,x
	bra .kn
.kr:	phx
	tax
	lda XD_RAIL,x
	tax
	lda XD_PM,x
	plx
	clc
	rol yt2
	lsr a
	rol ybb,x
	lsr a
	rol ybb+1,x
	lsr a
	rol ybb+2,x
	lsr a
	rol ybb+3,x
.kn:	iny
	dec yt1
	bne .kb
	ldx yk
	lda yt2
	sta xnm,x
	inc yk
	lda yk
	cmp #6
	bne .kp
	.if EFIX
	stz eb6                 ; (r19-edge-fixed) page 1 of the edge images: 8 bar pixels, rails 15 .. 8 (the right side on the grid)
	stz eb6+1
	stz eb6+2
	stz eb6+3
	cly
.k6:	ldx e6q,y
	lda XD_RAIL,x
	tax
	lda XD_PM,x
	lsr a
	rol eb6
	lsr a
	rol eb6+1
	lsr a
	rol eb6+2
	lsr a
	rol eb6+3
	iny
	cpy #8
	bne .k6
	.endif
	ldx #29                 ; the strips' bytes and masks for the pass's generator (xcup): ybb, xnm
.sx:	lda ybb,x
	sta XD_BB,x
	dex
	bpl .sx
	jsr xset3
	.if XMASK = 0
	.if PLG = 0
	jsr xbkset              ; (r19-bars-off-sprites) the left edge's 48 backdrop composites (x3)
	.endif
	.endif
	.if EFIX
	jsr ereset              ; (r19-edge-fixed) the edge slots' state empty (shaft19_x6.inc)
	.endif
.c36:	stz yk                  ; column 36 of BAT rows 0-15 and 18-33 -> XD_C36 + 2 (16 buffer + row)
.cr:	lda yk
	cmp #16
	bcc .c0
	adc #1                  ; (carry set: + 2: rows 18-33)
.c0:	sta yt0                 ; MARR = 64 row + 36
	lsr a
	lsr a
	tax
	lda yt0
	and #3
	lsr a
	ror a
	ror a
	ora #36
	jsr vmarr
	lda yk
	asl a
	tax
	lda $0002
	sta XD_C36,x
	lda $0003
	sta XD_C36+1,x
	.if XBAR = 0
	lda yk                  ; (black bars: column 36 black once; the pass writes columns 2 and 34 only)
	cmp #16
	bcc .c6
	adc #1
.c6:	ldx #36
	jsr vbat
	lda XD_BRL
	sta $0002
	lda XD_BRH
	ora #$F0
	sta $0003
	.endif
	inc yk
	lda yk
	cmp #32
	bne .cr
	lda FINEADC
	cmp #$6D
	bne .af
	lda FINEADC+2
	cmp #$2D
	bne .af
	lda FINEADC+1
	cmp #$10
	bne .af
	lda $2D09
	bne .af
	lda #$09
	sta FINEADC+1
	lda #1
	bra .as
.af:	lda #2
.as:	sta xadc
	.if YSM
	lda FINEADCY
	cmp #$6D
	bne .ay
	lda FINEADCY+2
	cmp #$2D
	bne .ay
	lda FINEADCY+1
	cmp #$11
	bne .ay
	lda $2D09
	bne .ay
	lda #$09
	sta FINEADCY+1
	inc xadc
	inc xadc
.ay:	lda #16                 ; columns 0, 1, 35, 36 of rows 16 and 34: saved, black
	jsr xr16
	lda #34
	jsr xr16
	.endif
	.if XTB = 0
	lda #36                 ; the top and bottom bars (BAT rows 47 and 36, columns 0-35): saved once per visit (xtb), then the bar tile of phase 0 column 0
	jsr .tb                 ; (XBAR 0: black) in every cell; the exit restore puts them back where they still hold ours
	lda #47
	jsr .tb
	lda #1
	sta xtb
	.endif
	.if RSLACK
	jsr rsinit              ; (r19-slack-rows) the slack cells checked, both windows at k = j = 0 with no rows (redrawn), the bar word
	.endif
	pla
	tam #4
	pla
	tam #3
	rts
	.if XTB = 0
.tb:	sta yt0
	ldx #0
	cmp #36
	beq .t0
	ldx #72
.t0:	stx yt1
	lda xtb
	bne .tw0
	ldx #0
	jsr xbatm
	ldx yt1
	ldy #36
.tr:	lda $0002
	sta XD_TB,x
	lda $0003
	sta XD_TB+1,x
	inx
	inx
	dey
	bne .tr
.tw0:	lda yt0
	ldx #0
	jsr vbat
	ldy #36
.tw:	lda XD_BRL
	sta $0002
	lda XD_BRH
	ora #$F0
	sta $0003
	dey
	bne .tw
	rts
	.endif

xrst:	tma #3
	pha
	lda #DB_X
	tam #3
	jsr xwspl
	.if XTB = 0
	jsr xrsttb
	stz xtb
	.endif
	lda XD_MSK - $2000                ; (the set-up's mask tile, 0: none written)
	ora XD_MSK - $2000 + 1
	bne .m0
	jmp .nm
.m0:	stz yk
.mc:	lda XD_MSK - $2000                ; MARR = (tile + 8 cell) * 16
	clc
	adc yk
	sta yt0
	lda XD_MSK - $2000 + 1
	adc #0
	sta yt1
	jsr .ad
	php
	sei
	jsr vmarr
	plp
	clx
.mr:	lda $0002
	sta XD_BUF - $2000,x
	lda $0003
	sta XD_BUF - $2000 + 1,x
	inx
	inx
	bpl .mr
	lda #$0B
	sta $1A04
	lda yk
	lsr a
	lsr a
	lsr a                   ; cell (yk = 8 cell)
	lsr a
	cla
	ror a
	sta $1A02
	lda yk
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #$16
	sta $1A03
	clx
.mq:	lda $1A00
	cmp XD_BUF - $2000,x
	bne .mn
	inx
	bpl .mq
	lda yk
	lsr a
	lsr a
	lsr a
	lsr a
	cla
	ror a
	sta $1A02
	lda yk
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #$14
	sta $1A03
	lda XD_MSK - $2000            ; (yt1:yt0 again: .ad shifted them)
	clc
	adc yk
	sta yt0
	lda XD_MSK - $2000 + 1
	adc #0
	sta yt1
	jsr .ad
	php
	sei
	jsr vmawr
	plp
	ldx #64
.mw:	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	dex
	bne .mw
.mn:	lda yk
	clc
	adc #8
	sta yk
	cmp #32
	beq .nm
	jmp .mc
.nm:	pla
	tam #3
	rts
.ad:
xrst_ad:	lda yt0                 ; X:A = (yt1:yt0) * 16
	asl a
	rol yt1
	asl a
	rol yt1
	asl a
	rol yt1
	asl a
	rol yt1
	ldx yt1
	rts
xwspl:	lda sdlv
	bne .sx
	ldy #40
	clx
.sw0:	lda SPLITN
	cmp #2
	bcc .sw1
	dex
	bne .sw0
	dey
	bne .sw0
	rts
.sw1:	ldy #40
	clx
.sw2:	lda SPLITN
	cmp #2
	bcs .sd0
	dex
	bne .sw2
	dey
	bne .sw2
	rts
.sd0:	ldx #3
	cly
.sd1:	dey
	bne .sd1
	dex
	bne .sd1
.sx:	rts
	.if XTB = 0
xbatm:	lda yt0                 ; MAWR = MARR = BAT(yt0, X), VDCREG = 2
	jsr vbat
	lda vb0
	ora vb1
	jmp vmarr
xrsttb:	lda #36
	ldx #0
	jsr xrst_tr
	lda #47
	ldx #72
	jmp xrst_tr
xrst_tr:	sta yt0                 ; row A: each of its 36 words back from XD_TB + X when it still holds ours
	stx yt2
	stz yt1
.tl:	php
	sei
	ldx yt1
	jsr xbatm
	lda $0002
	cmp XD_BRL - $2000
	bne .tn
	lda $0003
	and #$0F
	cmp XD_BRH - $2000
	bne .tn
	lda yt0
	ldx yt1
	jsr vbat
	ldx yt2
	lda XD_TB - $2000,x
	sta $0002
	lda XD_TB - $2000 + 1,x
	sta $0003
.tn:	plp
	inc yt2
	inc yt2
	inc yt1
	lda yt1
	cmp #36
	bne .tl
	rts
	.endif

xmask:
	lda #$00
	sta $1A02
	lda #$14
	sta $1A03
	lda #$0B
	sta $1A04
	clx
.ms:	lda XD_BUF,x
	sta $1A00
	inx
	bne .ms
	clx
.ms2:	lda XD_BUF + 256,x
	sta $1A00
	inx
	bne .ms2
	ldx #7                  ; our row (scratch zh + 8 .. 15, the histograms done): plane p's high byte (pixels 0-7) at + 2 p, low at + 2 p + 1
.mz:	stz zh+8,x
	dex
	bpl .mz
	ldy #0                  ; xi
.mr:	cpy #8
	cla
	rol a
	sta yt0                 ; 1: the low byte
	lda #4
	sta yt1
	tya
	eor XD_Q0
	tax
	lda XD_RAIL,x
	ldx yt0
.mp:	lsr a
	rol zh+8,x
	inx
	inx
	dec yt1
	bne .mp
	iny
	cpy #16
	bne .mr
	ldx #0                  ; our cell (128 bytes): plane p row y: bytes 32 p + 2 y (low: pixels 8-15), + 1 (high: 0-7)
.mb:	txa
	and #$60
	lsr a
	lsr a
	lsr a
	lsr a                   ; 2 p
	tay
	lda zh+9,y           ; low byte
	sta XD_BUF,x
	lda zh+8,y
	sta XD_BUF+1,x
	inx
	inx
	bpl .mb
	lda msav+4              ; the tile, as read above
	and #$FE
	sta zl
	lda msav+5
	sta zh2
	asl zl
	rol zh2
	lda zl
	sta XD_MSK
	lda zh2
	sta XD_MSK+1
	stz yk
.mw:	lda zl
	sta yt0
	lda zh2
	sta yt1
	jsr xrst_ad
	php
	sei
	jsr vmawr
	plp
	tia XD_BUF, $0002, 32
	tia XD_BUF + 32, $0002, 32
	tia XD_BUF + 64, $0002, 32
	tia XD_BUF + 96, $0002, 32
	lda yk
	lsr a
	cla
	ror a
	sta $1A02
	lda yk
	lsr a
	clc
	adc #$16
	sta $1A03
	lda #$0B
	sta $1A04
	tia XD_BUF, $1A00, 32
	tia XD_BUF + 32, $1A00, 32
	tia XD_BUF + 64, $1A00, 32
	tia XD_BUF + 96, $1A00, 32
	lda zl
	clc
	adc #8
	sta zl
	bcc .mw1
	inc zh2
.mw1:	inc yk
	lda yk
	cmp #4
	bne .mw
	rts
zh:	.ds 16
zl:	.db 0
zh2:	.db 0

XKEY       = 1
xset3:	clx                     ; XPOPT (DB_NEAR at MPR3): the set bits of each byte value (xcellh's counts)
.pt:	txa
	cly
.pb:	lsr a
	bcc .pc
	iny
.pc:	cmp #0
	bne .pb
	tya
	sta XPOPT,x
	inx
	bne .pt
	lda #$90
	sta .z+2
.zp:	clx
.z:	stz $9000,x
	inx
	bne .z
	inc .z+2
	lda .z+2
	cmp #$96
	bne .zp
	clx
.zl:	lda #$FF
	sta XD_LK,x
	stz XD_BKL,x
	inx
	bne .zl
	ldx #127
.zb:	stz XD_BUSE,x
	dex
	bpl .zb
	stz XD_LN
	stz XD_LN+1
	ldy #$FF                ; XD_VMAP: the first transparent value
	clx
.vm:	txa
	sta XD_VMAP,x
	lda KSWL,x
	cmp #$C5
	bne .vn
	lda KSWH,x
	bne .vn
	cpy #$FF
	bne .vs
	phx
	ply
.vs:	tya
	sta XD_VMAP,x
.vn:	inx
	bne .vm
	tma #3
	pha
	lda #DB_SW
	tam #3
	clx
.sw:	lda $6000,x
	sta XD_SW,x
	lda $6100,x
	sta XD_SW + $100,x
	lda $6200,x
	sta XD_SW + $200,x
	lda $6300,x
	sta XD_SW + $300,x
	inx
	bne .sw
	pla
	tam #3
	.if XBG = 0
	rts
	.endif
	.if XBG | (EFIX = 0)
	lda #$00                ; the key
	sta $1A02
	lda #$12
	sta $1A03
	lda #$0B
	sta $1A04
	lda $1A00
	cmp #$19
	bne .bld
	lda $1A00
	cmp #$5A
	bne .bld
	lda $1A00
	cmp #XKEY
	bne .bld
	lda kcached
	beq .bld
	rts
.bld:	inc nxset
	clx                     ; the shift tables (in BTAB's pages): $90 + k: x << (8 - 2 (k + 1)), $93 + k: x >> 2 (k + 1)
.sh:	txa
	asl a
	asl a
	sta $9200,x             ; << 2
	asl a
	asl a
	sta $9100,x             ; << 4
	asl a
	asl a
	sta $9000,x             ; << 6
	txa
	lsr a
	lsr a
	sta $9300,x             ; >> 2
	lsr a
	lsr a
	sta $9400,x             ; >> 4
	lsr a
	lsr a
	sta $9500,x             ; >> 6
	inx
	bne .sh
	stz yk                  ; r
.r:	lda #3
	sta yt2                 ; c
.c:	lda yk                  ; the two screen tiles: XD_SW + 64 r + 2 (c - 3), + 2
	lsr a
	lsr a
	clc
	adc #>XD_SW
	sta .a0+2
	sta .a1+2
	sta .b0+2
	sta .b1+2
	lda yk
	and #3
	lsr a
	ror a
	ror a
	sta yt0
	lda yt2
	sec
	sbc #3
	asl a
	ora yt0
	tax
.a0:	lda XD_SW,x
	sta zl
.a1:	lda XD_SW+1,x
	and #7
	sta zh2
	phx
	ldy #0
	jsr .rd
	plx
.b0:	lda XD_SW+2,x
	sta zl
.b1:	lda XD_SW+3,x
	and #7
	sta zh2
	ldy #32
	jsr .rd
	lda #1                  ; pi
	sta yt1
.p:	lda yk
	and #7
	asl a
	asl a
	asl a
	asl a
	asl a
	sta yt0
	lda yt2
	sec
	sbc #3
	ora yt0
	tax                     ; (32 r + c - 3) & 255
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $1A02
	txa
	lsr a
	lsr a
	lsr a
	sta yt0
	lda yk
	lsr a
	lsr a
	lsr a
	asl a
	asl a
	asl a
	asl a
	asl a                   ; (r >> 3) << 5
	ora yt0
	ldx yt1
	clc
	adc .bh-1,x
	sta $1A03
	lda .bb-1,x
	sta $1A04
	lda yt1                 ; the tables of this phase
	dec a
	clc
	adc #$90
	sta .s1+2
	adc #3
	sta .s2+2
	ldy #0
.i:	ldx XD_N,y
.s1:	lda $9000,x
	ldx XD_N + 32,y
.s2:	ora $9300,x
	sta $1A00
	iny
	cpy #32
	bne .i
	inc yt1
	lda yt1
	cmp #4
	bne .p
	inc yt2
	lda yt2
	cmp #34
	beq .cn
	jmp .c
.cn:	inc yk
	lda yk
	cmp #16
	beq .kd
	jmp .r
.kd:	lda #$00                ; the key, last
	sta $1A02
	lda #$12
	sta $1A03
	lda #$0B
	sta $1A04
	lda #$19
	sta $1A00
	lda #$5A
	sta $1A00
	lda #XKEY
	sta $1A00
	lda #$90                ; BTAB clear again (the shift tables were there)
	sta .y+2
.yp:	clx
.y:	stz $9000,x
	inx
	bne .y
	inc .y+2
	lda .y+2
	cmp #$96
	bne .yp
	rts
.rd:	lda zl                  ; tile (zh2:zl) -> XD_N + Y (32 bytes)
	sta yt0
	lda zh2
	asl yt0
	rol a
	asl yt0
	rol a
	asl yt0
	rol a
	asl yt0
	rol a
	tax
	lda yt0
	phy
	jsr vmarr
	ply
	ldx #32
.rl:	lda $0002
	sta XD_N,y
	lda $0003
	sta XD_N + 1,y
	iny
	iny
	dex
	dex
	bne .rl
	rts
.bh:	.db $60, $A0, $60
.bb:	.db $01, $01, $02
	.endif

	.if YSM
; row A (16 / 34): columns 0, 1, 35, 36 -> XD_R16 (+ 8 for row 34), then the bar tile of phase 0 column 0 (black) in each (DB_X at MPR4)
xr16:	sta yt0
	ldx #0
	cmp #16
	beq .a
	ldx #8
.a:	stx yt1
	stz yt2
.c:	ldx yt2
	lda xr16c,x
	tax
	lda yt0
	jsr vbat
	lda #1
	sta <VDCREG
	st0 #1                  ; (MARR = MAWR)
	lda yt0
	stz yk
	lsr a
	ror yk
	lsr a
	ror yk
	tax
	ldy yt2
	lda xr16c,y
	ora yk
	sta $0002
	stx $0003
	lda #2
	sta <VDCREG
	st0 #2
	ldx yt1
	lda $0002
	sta XD_R16,x
	lda $0003
	sta XD_R16+1,x
	ldx yt2
	lda xr16c,x
	tax
	lda yt0
	jsr vbat
	lda XD_BRL
	sta $0002
	lda XD_BRH
	ora #$F0
	sta $0003
	inc yt1
	inc yt1
	inc yt2
	lda yt2
	cmp #4
	bne .c
	rts
xr16c:	.db 0, 1, 35, 36
; the stand-down (xsd, DB_X at MPR3): rows 16 and 34's four border columns back
xr16b:	stz yt2
.c:	lda yt2
	and #3
	tax
	lda xr16c,x
	tax
	lda yt2
	cmp #4
	lda #16
	bcc .r
	lda #34
.r:	jsr vbat
	lda yt2
	asl a
	tax
	lda XD_R16 - $2000,x
	sta $0002
	lda XD_R16 - $2000 + 1,x
	sta $0003
	inc yt2
	lda yt2
	cmp #8
	bne .c
	rts
	.endif

	.if RSLACK
rbu:	.db 0           ; the buffer
rdl:	.db 0           ; the cell change (p0 - bp0), dx, dy
rdh:	.db 0
rdx:	.db 0
rdy:	.db 0
rnk:	.db 0           ; the window's new k, j
rnj:	.db 0
rt0:	.db 0
rt1:	.db 0
rsvl:	.db 0
rsvh:	.db 0
rbwl:	.db 0
rbwh:	.db 0
rrow:	.db 0           ; the row; the window row 0's BAT address; the row code's address of the camera cell's row 0
rrl:	.db 0
rrh:	.db 0
rpl:	.db 0
rph:	.db 0
rbo:	.db 0           ; this buffer's bout offset (16 b)
rm0:	.db 0           ; runplug: a band's blocks
rm1:	.db 0
rt2:	.db 0
rbl:	.db 0           ; runplug: the band's lower row's BAT address
rbh:	.db 0
rcrs:	.db 0           ; the CR shadow's increment bits as found (rinc64)
rbout:	.ds 16          ; the buffer's left-out blocks as its cells hold them (bout), before a shift

; rown (bank 3's own rows, every engaged pass; Y = its buffer): carry set = own rows redraw (the window's k, j chosen, its bars
; written where they moved); clear = no redraw (the same cell, or a shift done here). rbe, cbe, ck, cj set either way; rsh the log.
; MPR3 / MPR4 kept.
rown:	sty rbu
	stz rsh
	lda rok
	bne .r0
	cla                     ; (R off: k = j = 0, any change a redraw)
	sta bk,y
	sta bj,y
.r0:	lda bp0h,y
	cmp #$FF
	bne .v
	lda bk,y                ; (no rows: a redraw where the window is)
	sta rnk
	lda bj,y
	sta rnj
	lda #1
	sta rt2
	jmp .rd
.v:	lda p0l
	sec
	sbc bp0l,y
	sta rdl
	lda p0h
	sbc bp0h,y
	sta rdh
	ora rdl
	bne .ch
	jsr rcur                ; (the same cell)
	clc
	rts
.ch:	lda rdl                 ; dx = the low 6 bits, signed (the window is 33 cells of a 64-cell row)
	and #63
	cmp #32
	bcc .p1
	ora #$C0
.p1:	sta rdx
	ldx #0
	cmp #0
	bpl .p2
	dex
.p2:	stx rt0
	lda rdl                 ; d - dx = 64 dy
	sec
	sbc rdx
	sta rdl
	lda rdh
	sbc rt0
	tay                     ; (Y: the high byte)
	ldx rdl
	beq .y0
	cpx #$40
	beq .y1
	cpx #$C0
	beq .y2
.yj:	tya                     ; (not a multiple of 64: cannot be; a jump, by its sign)
	bmi .yu
	bra .yd
.y0:	tya                     ; (low 0: dy 0 or a jump of 4 rows or more)
	beq .yz
	bra .yj
.y1:	tya
	bne .yj
	lda #1                  ; (+64: one row down)
	bra .ys
.y2:	cpy #$FF
	bne .yj
	lda #$FF                ; (-64: one row up)
	bra .ys
.yd:	lda #2                  ; (a jump down / up: out of the slack)
	bra .ys
.yu:	lda #$FE
	bra .ys
.yz:	cla
.ys:	sta rdy
	ldy rbu
	lda rok
	beq .nr
	lda bk,y                ; inside the slack: k + dx in 0-3, j + dy in 0-1
	clc
	adc rdx
	sta rnk
	cmp #4
	bcs .nr
	lda bj,y
	clc
	adc rdy
	sta rnj
	cmp #2
	bcs .nr
	jmp rsh1
.nr:	lda #1                  ; a redraw: preserve edge-slot phase across vertical-only 1-row redraws (rsh = 5)
	ldx rdx
	bne .nr_rsh
	ldx rdy
	cpx #1
	beq .nr_v1
	cpx #$FF
	bne .nr_rsh
.nr_v1:	lda #5
.nr_rsh:
	sta rt2
	stz rnk                 ; k 0 going right (or R off), 3 going left, else as it is; j 0 going down, 1 up, else as is
	stz rnj
	lda rok
	beq .rd
	lda rdx
	beq .k0
	bpl .k1
	lda #3
	sta rnk
	bra .k1
.k0:	lda bk,y
	sta rnk
.k1:	lda rdy
	beq .j0
	bpl .rd
	lda #1
	sta rnj
	bra .rd
.j0:	lda bj,y
	sta rnj
.rd:	ldy rbu
	lda rnk
	cmp bk,y
	bne .rb
	lda rnj
	cmp bj,y
	beq .rc
	sta bj,y
	jsr rcur
	lda rnj
	beq .ry0
	lda #16
.ry0:	jsr rrowa
	cla
	jsr rbar2
	lda #35
	jsr rbar2
	bra .rc2
.rb:	lda rnk                 ; (the window moved: its bars first, columns 0, 1, 35, 36)
	sta bk,y
	lda rnj
	sta bj,y
	jsr rcur
	jsr rrow0
	jsr rinc64
	jsr rcol035
	jsr rcol136
	jsr rinc1
	bra .rc2
.rc:	jsr rcur
.rc2:	lda rt2
	sta rsh
	inc nrrd
	bne .rx
	inc nrrd+1
.rx:	sec
	rts

; the shift (rown: rnk, rnj in the slack; dx = rdx, dy = rdy)
rsh1:	tma #3
	pha
	tma #4
	pha
	lda #CB3                ; (bank 3 at MPR4: bout)
	tam #4
	lda rbu
	asl a
	asl a
	asl a
	asl a
	sta rbo
	tax
	ldy #0
	sty rt0
	.if PBX = 0
.o:	lda bout - $4000,x      ; (this buffer's bout to rbout, zeroed there: wbat plugs from an empty set after the shift)
	sta rbout,y
	tsb rt0
	stz bout - $4000,x
	inx
	iny
	cpy #16
	bne .o
	lda rt0
	beq .np
	jsr rcur                ; the plug words back first, at the old window and camera cell: every cell of each block the buffer holds
	ldy rbu                 ; as left out gets its S word from the row code (the cells not plugged already hold it)
	lda bp0l,y
	ldx bp0h,y
	jsr rcodep
	jsr rrow0
	jsr runplug
	lda #8
	sta rsh
	.endif
.np:	ldy rbu                 ; the new window
	lda rnk
	sta bk,y
	lda rnj
	sta bj,y
	jsr rcur
	lda p0l
	ldx p0h
	jsr rcodep
	jsr rrow0
	lda rdx
	bne .xs
	jmp .ny
.xs:	jsr rinc64              ; (the columns with the VDC's increment 64)
	lda rdx
	bmi .lf
	cmp #2                  ; right by n: bars w 1, 36 (and 0, 35 for n > 1); near w 34 - n .. 33
	bcc .r1
	jsr rcol035
.r1:	jsr rcol136
	lda #34
	sec
	sbc rdx
	sta rt1
.rn:	lda rt1
	jsr rcoln
	inc rt1
	lda rt1
	cmp #34
	bne .rn
	bra .xe
.lf:	cmp #$FF                ; left by n: bars w 0, 35 (and 1, 36 for n > 1); near w 3 .. 2 + n
	beq .l1
	jsr rcol136
.l1:	jsr rcol035
	lda #2
	sec
	sbc rdx
	sta rt1                 ; (2 + n)
.ln:	lda rt1
	jsr rcoln
	dec rt1
	lda rt1
	cmp #2
	bne .ln
.xe:	jsr rinc1
	lda rsh
	ora #2
	sta rsh
.ny:	lda rdy
	beq .nx
	bmi .up
	lda #16                 ; the entering row: 16 going down, 0 going up
	bra .ye
.up:	cla
.ye:	jsr rrowin
	lda rsh
	ora #4
	sta rsh
.nx:	pla
	tam #4
	pla
	tam #3
	ldy rbu
	lda p0l
	sta bp0l,y
	lda p0h
	sta bp0h,y
	inc nrsh
	bne .x
	inc nrsh+1
.x:	clc
	rts

; ck, cj, cbe, rbe of buffer rbu's window
rcur:	ldy rbu
	lda bk,y
	sta ck
	clc
	adc #2
	sta cbe
	lda bj,y
	sta cj
	clc
	adc rb
	sta rbe
	rts
; rrow0 / rrowa: rrl / rrh = 64 (rbe [+ A]) (the window's row 0 or row A)
rrowa:	clc
	adc rbe
	bra rrow0a
rrow0:	lda rbe
rrow0a:	stz rrl
	lsr a
	ror rrl
	lsr a
	ror rrl
	sta rrh
	rts
rcodep:	sta rt0
	txa
	sec
	sbc #$C0
	sta rt1
	lsr a
	lsr a
	lsr a
	tay
	lda cbank,y
	tam #3
	lda cbank+1,y
	tam #4
	lda rt0
	asl a
	asl a
	sta rpl
	lda rt1
	and #7
	asl a
	asl a
	sta rt1
	lda rt0
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	ora rt1
	ora #$60
	sta rph
	rts
; MAWR = the window's row 0, column w = A (+ ck), VWR selected
rcma:	clc
	adc ck
	ora rrl
	stz <VDCREG
	st0 #0
	sta $0002
	lda rrh
	sta $0003
	lda #2
	sta <VDCREG
	st0 #2
	rts
rinc64:	lda <$F4
	and #$18
	sta rcrs
	lda <$F4
	and #$E7
	ora #$10
	bra rcrw
rinc1:	lda <$F4
	and #$E7
	ora rcrs
rcrw:	sta <$F4
	lda #5
	sta <VDCREG
	st0 #5
	lda <$F3
	sta $0002
	lda <$F4
	sta $0003
	rts
; window column A, rows 0-16 (increment 64): the bar word (rcolb), the near words of near column A - 2 from the row code (rcoln)
rcolb:	jsr rcma
	lda rbwl
	ldy rbwh
	ldx #XROWS
.b:	sta $0002
	sty $0003
	dex
	bne .b
	rts
rcol035:
	cla
	jsr rcolb
	lda #35
	jmp rcolb
rcol136:
	lda #1
	jsr rcolb
	lda #36
	jmp rcolb
rbar2:	jsr rcma
	lda rbwl
	ldx rbwh
	sta $0002
	stx $0003
	sta $0002
	stx $0003
	rts
rcoln:	pha
	jsr rcma
	pla
	dec a
	dec a
	asl a
	asl a
	inc a
	tay                     ; (4 c + 1: the ST1's operand; + 2 the ST2's)
	lda rpl
	sta .l+1
	inc a
	inc a
	sta .h+1
	lda rph
	sta .l+2
	sta .h+2
	ldx #XROWS
.l:	lda $6000,y
	sta $0002
.h:	lda $6002,y
	sta $0003
	inc .l+2
	inc .h+2
	dex
	bne .l
	rts
	.if PBX = 0
; runplug: every block of rbout (the buffer's bout as it was) of the old window (rbe, cbe, the old cell's code, MPR3 / MPR4): its
; 2 x 2 cells' S words (increment 1; the cells that were not plugged hold them already). Per band the two rows' BAT addresses and code
; pages once; per block two address sets of two words.
runplug:	lda #2
	sta <VDCREG
	stz rt0                 ; (the band)
.b:	lda rt0
	asl a
	tax
	lda rbout,x
	sta rm0
	lda rbout + 1,x
	sta rm1
	ora rm0
	bne .g
	jmp .nb
.g:	txa                     ; (2 band: the window row of the band's upper cells; its code page and the next)
	clc
	adc rph
	sta .la+2
	sta .ha+2
	sta .la2+2
	sta .ha2+2
	inc a
	sta .lb+2
	sta .hb+2
	sta .lb2+2
	sta .hb2+2
	lda rpl
	sta .la+1
	sta .lb+1
	sta .la2+1
	sta .lb2+1
	inc a
	inc a
	sta .ha+1
	sta .hb+1
	sta .ha2+1
	sta .hb2+1
	txa                     ; (the BAT addresses of rows rbe + 2 band and + 1)
	clc
	adc rbe
	stz rrl
	lsr a
	ror rrl
	lsr a
	ror rrl
	sta rrh
	lda rrl
	clc
	adc #$40
	sta rbl
	lda rrh
	adc #0
	sta rbh
	lda cbe
	sta rt2                 ; (the block's BAT column: cbe + 2 block; its code offset 8 block + 1)
	ldy #1
	lda rm0
	ldx #2
.k:	lsr a
	bcc .n
	jsr .w
.n:	inc rt2
	inc rt2
	pha
	tya
	clc
	adc #8
	tay
	pla
	bne .k
	dex
	bne .hi
	jmp .nb
.hi:	lda cbe                 ; (blocks 8-15)
	clc
	adc #16
	sta rt2
	ldy #65
	lda rm1
	bne .k
	jmp .nb
.w:	pha
	phx
	lda rt2
	ora rrl
	sei
	st0 #0
	sta $0002
	lda rrh
	sta $0003
	st0 #2
	cli
.la:	lda $6000,y
	sta $0002
.ha:	lda $6002,y
	sta $0003
	iny
	iny
	iny
	iny
.la2:	lda $6000,y
	sta $0002
.ha2:	lda $6002,y
	sta $0003
	lda rt2
	ora rbl
	sei
	st0 #0
	sta $0002
	lda rbh
	sta $0003
	st0 #2
	cli
	dey
	dey
	dey
	dey
.lb:	lda $6100,y
	sta $0002
.hb:	lda $6102,y
	sta $0003
	iny
	iny
	iny
	iny
.lb2:	lda $6100,y
	sta $0002
.hb2:	lda $6102,y
	sta $0003
	dey
	dey
	dey
	dey
	plx
	pla
	rts
.nb:	inc rt0
	lda rt0
	cmp #8
	beq .x
	jmp .b
.x:	rts

	.endif
; rrowin: window row A (0 / 16) whole: w 0, 1 bars, w 2 - 33 the row code (32 words, an RTS planted after them), w 34 - 36 bars
rrowin:	sta rrow
	jsr rrowa
	cla
	jsr rbar2
	lda rpl                 ; the row's code: rpl, rph + row; its RTS at + 128
	sta .j+1
	clc
	adc #128
	sta .pl+1
	sta .pr+1
	lda rph
	adc rrow
	sta .pl+2
	sta .pr+2
	lda rph
	clc
	adc rrow
	sta .j+2
	lda #$60
.pl:	sta $6080
.j:	jsr $6000
	lda #$13
.pr:	sta $6080
	ldx #3
.b:	lda rbwl
	sta $0002
	lda rbwh
	sta $0003
	dex
	bne .b
	rts

; rsinit (xset2's end, DB_X at MPR4; the set-up and every re-engage): the slack cells one word (rok); both windows k = j = 0 with no rows
rsinit:	lda XD_BRL
	sta rbwl
	lda XD_BRH
	ora #$F0
	sta rbwh
	stz bk
	stz bk+1
	stz bj
	stz bj+1
	lda #$FF
	sta bp0h
	sta bp0h+1
	lda #1
	sta rok
	lda #17                 ; row 17, column 0: the word
	ldx #0
	jsr rmar
	lda $0002
	sta rslw
	lda $0003
	sta rslw+1
	lda #17
	jsr .row
	lda #35
	jsr .row
	stz rt1                 ; columns 37-39 of rows 0-16, 18-34
.c:	lda rt1
	ldx #37
	jsr rmar
	ldx #3
	jsr .cmp
	inc rt1
	lda rt1
	cmp #17
	bne .c1
	inc rt1
.c1:	cmp #35
	bne .c
	rts
.row:	ldx #0
	jsr rmar
	ldx #40
.cmp:	lda $0002
	cmp rslw
	bne .no
	lda $0003
	cmp rslw+1
	bne .no
	dex
	bne .cmp
	rts
.no:	stz rok                 ; (one cell off is enough: R off for this engagement)
	rts
; MARR = BAT row A, column X (VRR selected)
rmar:	stx rt0
	stz rrl
	lsr a
	ror rrl
	lsr a
	ror rrl
	tax
	lda rrl
	ora rt0
	jmp vmarr

; rslr (sdwork, per buffer Y: the stand-down and leave): the buffer's slack cells get the word back (only with R on)
rslr:	lda rok
	beq .x
	tya
	beq .b
	lda #18
.b:	sta rt0
	clc
	adc #17
	ldx #0
	jsr vbat
	ldx #40
.r:	lda rslw
	sta $0002
	lda rslw+1
	sta $0003
	dex
	bne .r
	stz rt1
.c:	lda rt0
	clc
	adc rt1
	ldx #37
	jsr vbat
	ldx #3
.w:	lda rslw
	sta $0002
	lda rslw+1
	sta $0003
	dex
	bne .w
	inc rt1
	lda rt1
	cmp #17
	bne .c
.x:	rts
	.endif
