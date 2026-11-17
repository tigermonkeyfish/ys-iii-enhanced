	.if PLG
SPB        = $7100      ; DB_NEAR (MPR3): this pass's plug cells, a bitmap (window row rr: 5 bytes, cell column cc: byte cc >> 3, bit cc & 7)
SLB        = $7155      ; per buffer (+ 85 b): the cells its last S pass left holding a plug word (the same form)
SPV        = $7E00      ; per near byte value: 1 code 0 (the transparent S word), 2 a staircase cell (backdrop class), 4 a see-through near
                        ; cell (no plug), 0 opaque
SPR        = $7F00      ; the plug cells' list (row by row, columns rising): window row, column
SPC        = $7F80
SMAPS      = $9000      ; DB_X (MPR4): per local window id (0-575): its slot this pass (valid when SMAPT = sstmp)
SMAPT      = $9240
SPSL       = $9500      ; per pool slot (0 .. NPOOL - 1, the dictionary's first): its tile's VRAM address, its BAT word (palette 1)
SPSH       = $9590
SPWL       = $9620
SPWH       = $96B0
SWL        = $9740      ; per plug cell: its word
SWH        = $97C0
SUS        = $9840      ; per upload: the slot, the stream A address (low, middle, bank), B's (low, middle)
SUL        = $98C0
SUM        = $9940
SUB        = $99C0
SCF        = $9A40      ; per pool slot: 1 when its tile's VRAM address is the slot before's + 16 (XD_VMAP's page: set-up only)
SZERO      = $8F00      ; DB_X: 85 zero bytes (XD_BKL's page: zeroed by xset3, the set-up's and every re-engage's; the rest made by sset /
SC         = $8F60      ; sreen from the fifth bank): per band the class footprint's columns of its left-sout blocks (5 bytes), this row's
SROW       = $8F88
SX2B       = $8F90      ; a nibble's bits doubled
S5         = $8FA0      ; 5 n (0-16)
SBM        = $8FB8      ; 1 << n
S16L       = $8FC0      ; 16 n (0-16)
S16H       = $8FD1
SBSL       = $8FE8      ; the streams' base by X phase (24 bits)
SBSM       = $8FEC
SBSB       = $8FF0
S576L      = $9B40      ; 576 n (0-32)
S576H      = $9B61
S66L       = $9B88      ; (PDD) 66 n (0-16)
S66H       = $9B99
DXO        = $4000      ; DB_X at MPR6 while S runs
SPMAX      = 128
	.if XBAR = 0
NPOOL      = 143
	.else
NPOOL      = 127        ; the backdrop cache's 103 slots, the composite cache's 24 spare (b7's 48 static composites go: xbkset not made)
	.endif
	.if WAL
SSTRL      = $0C0000
	.else
SSTRL      = $016000
	.endif
SWT        = $0B1800    ; the window table: 2 bytes at SWT + 2 (561 (4 p + q) + 33 rr + cc)

; ---------------------------------------------------------------- state (bank 3; the recorders read it: the per-pass log)
sout:	.ds 16          ; (copied by bank 3's splug) the pass's left-out blocks, its buffer, p0's page in DB_NEAR
sobi:	.db 0
skq:	.db 0
sbm1:	.db 1, 2, 4, 8, 16, 32, 64, 128
sbm8:	.db 1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128, 1
sdv5:	.db 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7
	.db 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14
	.db 15, 15, 15, 15, 15, 16, 16, 16, 16, 16
smd5:	.db 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32
	.db 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32
	.db 0, 8, 16, 24, 32, 0, 8, 16, 24, 32, 0, 8, 16, 24, 32
s64l:	.db $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0
s64h:	.db 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8
slog5:
spx:	.db 0           ; this pass: X phase (camera X & 6), Y phase, the class (dx | dy << 1)
spy:	.db 0
scls:	.db 0
snp:	.db 0           ; plug cells
snu:	.db 0           ; uploads
snh:	.db 0           ; (PDD) dictionary hits, slots shared in the pass
snd:	.db 0
snsee:	.db 0           ; see-through near cells under a left-sout block
snr:	.db 0           ; cells put back
shold:	.db 0           ; 1: this pass held (2: SPMAX, 3: see-through, 4: the pool)
nplugov:	.dw 0           ; passes held
sbx:	.db 0, 0        ; BXRV / BYRV of the last pass shown
su:	.db 0, 0        ; per buffer: the pool slots its last S pass took
srb:	.db $FF, $FF    ; per buffer: the window (rbe, cbe) its SLB was written at
scb:	.db 0, 0
sstmp:	.db 1           ; (PDD) the pass's stamp
sti0:	.db 0
sti1:	.db 0
sti2:	.db 0
sti3:	.db 0
sti4:	.db 0
sti5:	.db 0
slog5e:
sfree:	.db 0           ; the pool's slots free for this buffer
sfrst:	.db 0           ; its first slot, its direction (0 up, 1 down)
sdir:	.db 0
sr:	.db 0
sbb:	.db 0           ; sbuild: the band, its row 2 b, the row in the band, its left-sout blocks (shifted)
sr0:	.db 0
srr:	.db 0
sml:	.db 0
smol:	.db 0           ; the band's blocks as found
smoh:	.db 0
sbk:	.db 0
smh:	.db 0
sbi:	.db 0
sbt:	.db 0
spl:	.db 0           ; this row's near pointer (MPR3), its bitmap index
sph:	.db 0
s5r:	.db 0
spa0:	.db 0           ; the phase's stream base (24 bits) + 16 - 4 q
spa1:	.db 0
spa2:	.db 0
spw0:	.db 0           ; (PDD) the phase's window table base (low, middle)
spw1:	.db 0
; s6go (entry 15; from bank 3's sset / sreen): the sixth image bank's entry X (DB_SW at MPR6 while it runs)
s6go:	stx .j+1
	tma #6
	pha
	lda #CB6
	tam #6
.j:	jsr s6ent              ; (low byte: s6ent + X)
	pla
	tam #6
	rts
; sinit (entry 12; the set-up's end and every re-engage, from bank 3's sset / sreen through c5; DB_NEAR at MPR3): no buffer holds
; a plug (both are redrawn), no slot taken, the scroll sources as they stand
sinit:
	.if PDD
	tma #6
	pha
	lda #DB_X
	tam #6
	jsr sclrt
	pla
	tam #6
	lda #1
	sta sstmp
	.endif
	ldx #169
.z:	stz SLB,x
	dex
	bpl .z
	lda #$FF
	sta srb
	sta srb+1
	stz su
	stz su+1
	lda BXRV
	sta sbx
	lda BYRV
	sta sbx+1
	rts

tii85	.macro
	tii \1, \2, 17
	tii \1 + 17, \2 + 17, 17
	tii \1 + 34, \2 + 34, 17
	tii \1 + 51, \2 + 51, 17
	tii \1 + 68, \2 + 68, 17
	.endm

stime	.macro
	lda TIMER
	and #$7F
	sta \1
	.endm

spass:	tma #6
	pha
	lda #DB_X
	tam #6
	jsr spl1
	pla
	tam #6
	rts
spl1:	stime sti0
	stz snp
	stz snu
	stz snh
	stz snd
	stz snsee
	stz snr
	stz shold
	lda pxr
	and #6
	sta spx
	cmp #1
	cla
	rol a
	sta scls
	lda pyr
	and #6
	sta spy
	beq .c
	lda scls
	ora #2
	sta scls
.c:	jsr sbuild              ; the plug cells (SPB, SPR / SPC; snsee)
	stime sti1
	lda shold
	bne .hj
	lda snsee
	beq .r
	lda #3
	sta shold
.hj:	jmp .h
.r:	jsr sres                ; their words (uploads listed); shold 4: the pool
	stime sti2
	lda shold
	bne .hj
	jsr sback               ; the last pass's plug cells that are not plug cells now
	stime sti3
	jsr supl                ; the uploads
	stime sti4
	jsr swrd                ; the words
	stime sti5
	ldx sobi                 ; the buffer's plugs: this pass's
	txa
	beq .l0
	tii85 SPB, SLB + 85
	bra .l1
.l0:	tii85 SPB, SLB
.l1:	lda rbe
	sta srb,x
	lda cbe
	sta scb,x
	lda snu
	sta su,x
	lda BXRV
	sta sbx
	lda BYRV
	sta sbx+1
	clc
	rts
.h:	stz snp                 ; HELD: every plug of the buffer put back (none in P), the buffer's slots free
	stz snu
	tii85 (SZERO + DXO), SPB
	jsr sback
	stime sti3
	ldx sobi
	lda #$FF
	sta srb,x
	stz su,x
	inc nplugov
	bne .h1
	inc nplugov+1
.h1:	lda SATPAGE
	eor #1
	sta SATPAGE
	lda sbx
	sta BXRV
	lda sbx+1
	sta BYRV
	sec
	rts

; ---------------------------------------------------------------- the plug cells, block by block: per band (rows 2 b, 2 b + 1 and,
; off the grid in Y, 2 b + 2) each left-sout block's columns 2 k, 2 k + 1 and, off the grid in X, 2 k + 2 unless block k + 1 is left sout
; too (its own column then); the near byte's class (SPV) -> a plug cell (listed column by column, rows rising, and set in SPB), a see-through
; count, or nothing. A band's first row off the grid in Y is the band above's third: there a cell already listed is not listed again.
sbuild:	tii85 (SZERO + DXO), SPB
	stz sbb
.b:	lda sbb
	asl a
	tax
	lda sout,x
	sta sml
	lda sout+1,x
	sta smh
	ora sml
	bne .bg
	jmp .nb
.bg:	lda sbb                 ; the band's three near rows (MPR3)
	asl a
	sta sr0
	tax
	lda s64l,x
	clc
	adc p0l
	sta .n0+1
	lda s64h,x
	adc skq
	sta .n0+2
	lda .n0+1
	clc
	adc #64
	sta .n1+1
	lda .n0+2
	adc #0
	sta .n1+2
	lda .n1+1
	clc
	adc #64
	sta .n2+1
	lda .n1+2
	adc #0
	sta .n2+2
	lda sml                 ; (the band's blocks as found: block k + 1's bit for column 2 k + 2)
	sta smol
	lda smh
	sta smoh
.k:	lda sml                 ; the lowest block still to do: k (0-7 from sml, 8-15 from smh)
	beq .kh
	tax
	lda klsb,x
	tay
	eor sml
	sta sml
	dey
	lda kpop,y
	bra .kg
.kh:	lda smh
	bne .kh1
	jmp .nb
.kh1:	tax
	lda klsb,x
	tay
	eor smh
	sta smh
	dey
	lda kpop,y
	ora #8
.kg:	sta sbk
	asl a
	tay                     ; column 2 k
	jsr .col
	iny
	jsr .col
	lda scls                ; (off the grid in X: column 2 k + 2 unless block k + 1 is left out: its own)
	lsr a
	bcc .k
	ldx sbk
	inx
	cpx #16
	beq .c3
	cpx #8
	bcs .k8
	lda sbm1,x
	and smol
	bne .k
	bra .c3
.k8:	lda sbm1 - 8,x
	and smoh
	bne .k
.c3:	iny
	jsr .col
	bra .k
.nb:	inc sbb
	lda sbb
	cmp #8
	beq .x
	jmp .b
.x:	rts
.col:				; column Y: rows 2 b, 2 b + 1 (and 2 b + 2): a near byte of no plug class costs three instructions
.n0:	ldx $6000,y
	lda SPV,x
	beq .c1
	lda #0
	jsr .cel
.c1:
.n1:	ldx $6000,y
	lda SPV,x
	beq .c2
	lda #1
	jsr .cel
.c2:	lda scls
	and #2
	beq .cx
.n2:	ldx $6000,y
	lda SPV,x
	beq .cx
	lda #2
	jmp .cel
.cx:	rts
.cel:	sta srr                 ; (A: the row in the band, X: the near byte, Y: the column)
	lda SPV,x
	cmp #4
	beq .see
	lda sr0
	clc
	adc srr
	sta sr
	tax
	tya
	lsr a
	lsr a
	lsr a
	clc
	adc (S5 + DXO),x
	tax
	lda sbm8,y
	sta sbt
	lda srr                 ; (row 2 b off the grid in Y, b > 0: listed already?)
	bne .ad
	lda scls
	and #2
	beq .ad
	lda sbb
	beq .ad
	lda sbt
	and SPB,x
	bne .cx
.ad:	lda sbt
	ora SPB,x
	sta SPB,x
	ldx snp
	cpx #SPMAX
	bcs .ov
	tya
	sta SPC,x
	lda sr
	sta SPR,x
	inc snp
	rts
.ov:	lda #2
	sta shold
	rts
.see:	inc snsee
	rts

; ---------------------------------------------------------------- the words: on the grid the screen's backdrop word; off it a slot (uploads
; listed: SUS / SUL .. SUM2). The pool: the dictionary's PDN slots first, then buffer 0's up from there and buffer 1's down from the last,
; each buffer free to take what the shown buffer's last pass left. shold 4 when it does not fit.
sres:	lda snp
	bne .go
	rts
.go:	lda spx
	ora spy
	bne .off
	clx                     ; on the grid: XD_SW + 64 rr + 2 cc
.g:	ldy SPR,x
	lda s64l,y
	sta .gl+1
	lda s64h,y
	clc
	adc #>(XD_SW + DXO)
	sta .gl+2
	sta .gh+2
	lda SPC,x
	asl a
	ora .gl+1
	sta .gl+1
	inc a
	sta .gh+1
.gl:	lda (XD_SW + DXO)
	sta (SWL + DXO),x
.gh:	lda (XD_SW + DXO)+1
	sta (SWH + DXO),x
	inx
	cpx snp
	bne .g
	rts
.off:	ldx sobi                 ; the pool free for this buffer: NPOOL - PDN - the other buffer's
	txa
	eor #1
	tay
	lda #NPOOL - PDN
	sec
	sbc su,y
	sta sfree
	stx sdir
	lda #PDN
	cpx #0
	beq .f0
	lda #NPOOL - 1
.f0:	sta sfrst
	lda spx                 ; the phase's stream base + 16 - 4 q (24 bits)
	lsr a
	tax
	lda spy
	asl a
	eor #$FF
	sec
	adc #16                 ; 16 - 2 spy (= 16 - 4 q)
	clc
	adc (SBSL + DXO),x
	sta spa0
	lda (SBSM + DXO),x
	adc #0
	sta spa1
	lda (SBSB + DXO),x
	adc #0
	sta spa2
	.if PDD
	jmp sresd
	.else
	clx
.c:	ldy snu                 ; every cell its own upload: upload index j in SWL, $FF in SWH (swrd: the slot's word once the base is known)
	cpy sfree
	bcs .full
	tya
	sta (SWL + DXO),x
	lda #$FF
	sta (SWH + DXO),x
	jsr sadr
	inc snu
	inx
	cpx snp
	bne .c
	jmp sbase
.full:	lda #4
	sta shold
	rts
	.endif
; the uploads' first slot: buffer 0 PDN, buffer 1 NPOOL - snu (both fill upward: the pool sorted by VRAM address, the VDC's address runs
; on from slot to slot where they are contiguous)
sbase:	lda sobi
	beq .b0
	lda #NPOOL
	sec
	sbc snu
	sta sfrst
	rts
.b0:	lda #PDN
	sta sfrst
	rts

	.if PDD
; the words through the window table (port 3): a dictionary word as it stands; an id seen already this pass: that upload's slot (SMAPT
; = the pass's stamp, SMAPS = its upload index); else a new upload. The table's phase part from SWTA + 1122 (4 p + q); a cell one row
; below the last in the same column needs no base (the table runs on)
s34l:	.db <0, <34, <68, <102, <136, <170, <204, <238, <272, <306, <340, <374, <408, <442, <476, <510, <544
	.db <578, <612, <646, <680, <714, <748, <782, <816, <850, <884, <918, <952, <986, <1020, <1054, <1088
s34h:	.db >0, >34, >68, >102, >136, >170, >204, >238, >272, >306, >340, >374, >408, >442, >476, >510, >544
	.db >578, >612, >646, >680, >714, >748, >782, >816, >850, >884, >918, >952, >986, >1020, >1054, >1088
swpl:	.db <($1800 + 0), <($1800 + 1122), <($1800 + 2244), <($1800 + 3366), <($1800 + 4488), <($1800 + 5610), <($1800 + 6732), <($1800 + 7854)
	.db <($1800 + 8976), <($1800 + 10098), <($1800 + 11220), <($1800 + 12342), <($1800 + 13464), <($1800 + 14586), <($1800 + 15708), <($1800 + 16830)
swph:	.db >($1800 + 0), >($1800 + 1122), >($1800 + 2244), >($1800 + 3366), >($1800 + 4488), >($1800 + 5610), >($1800 + 6732), >($1800 + 7854)
	.db >($1800 + 8976), >($1800 + 10098), >($1800 + 11220), >($1800 + 12342), >($1800 + 13464), >($1800 + 14586), >($1800 + 15708), >($1800 + 16830)
sresd:	lda spx                 ; phase 4 p + q = 2 px + py / 2
	asl a
	sta t0
	lda spy
	lsr a
	clc
	adc t0
	tax
	lda swpl,x
	sta spw0
	lda swph,x
	sta spw1
	lda #$0B
	sta $1A34
	inc sstmp               ; the pass's stamp (0: SMAPT cleared first)
	bne .s
	jsr sclrt
	inc sstmp
.s:	lda #$FF
	sta sbt
	clx
.c:	lda SPC,x
	cmp sbt
	bne .ba
	lda SPR,x
	cmp sbi
	beq .rd
.ba:	ldy SPC,x               ; port 3's base: spw + 34 cc + 2 rr
	sty sbt
	lda s34l,y
	clc
	adc spw0
	sta t0
	lda s34h,y
	adc spw1
	sta t1
	lda SPR,x
	asl a
	clc
	adc t0
	sta $1A32
	lda t1
	adc #0
	sta $1A33
.rd:	lda SPR,x
	inc a
	sta sbi
	lda $1A30
	ldy $1A30
	cpy #$10
	bcc .id
	sta (SWL + DXO),x       ; a dictionary word
	tya
	sta (SWH + DXO),x
	inc snh
	bra .nx
.id:	sta .t+1                ; an id: SMAPT / SMAPS + id
	sta .t2+1
	sta .m+1
	sta .m2+1
	tya
	clc
	adc #>(SMAPT + DXO)
	sta .t+2
	sta .t2+2
	tya
	clc
	adc #>(SMAPS + DXO)
	sta .m+2
	sta .m2+2
.t:	lda SMAPT + DXO
	cmp sstmp
	bne .nu
.m:	lda SMAPS + DXO         ; (this pass uploads it already)
	sta (SWL + DXO),x
	lda #$FF
	sta (SWH + DXO),x
	inc snd
	bra .nx
.nu:	ldy snu                 ; a new upload
	cpy sfree
	bcs .full
	lda sstmp
.t2:	sta SMAPT + DXO
	tya
.m2:	sta SMAPS + DXO
	sta (SWL + DXO),x
	lda #$FF
	sta (SWH + DXO),x
	jsr sadr
	inc snu
.nx:	inx
	cpx snp
	beq .x
	jmp .c
.x:	jmp sbase
.full:	lda #4
	sta shold
	rts
; SMAPT zero (DB_X at MPR6)
sclrt:	clx
.z:	stz SMAPT + DXO,x
	stz SMAPT + DXO + $100,x
	stz SMAPT + DXO + $140,x
	inx
	bne .z
	rts
	.endif
sadr:	ldy SPC,x
	lda (S576L + DXO),y
	clc
	adc spa0
	sta t0
	lda (S576H + DXO),y
	adc spa1
	sta t1
	lda spa2
	adc #0
	sta t2
	ldy SPR,x
	lda (S16L + DXO),y
	clc
	adc t0
	sta t0
	lda (S16H + DXO),y
	adc t1
	sta t1
	bcc .n
	inc t2
.n:	ldy snu
	lda t0
	sta (SUL + DXO),y
	lda t1
	sta (SUM + DXO),y
	lda t2
	sta (SUB + DXO),y
	rts

; ---------------------------------------------------------------- the uploads: port 1's data at every address of bank $41 (MPR3 here),
; straight into the VDC: MAWR the slot (not set when the slot's tile follows the last one's: the VDC's address ran on), A's 16 bytes, B's 16
supl:	lda snu
	bne .go
	rts
.go:	tma #3
	pha
	lda #$41
	tam #3
	lda #2
	sta <VDCREG
	st0 #2
	ldy sfrst               ; slot = sfrst + j
	clx
.u:	lda (SCF + DXO),y       ; (the slot's tile follows the last one's in VRAM: the VDC's address ran on)
	beq .ma
	cpx #0
	bne .d
.ma:	sei
	st0 #0
	lda (SPSL + DXO),y
	sta $0002
	lda (SPSH + DXO),y
	sta $0003
	st0 #2
	cli
.d:	lda (SUL + DXO),x       ; port 1's base: A; B = A + 288 = the base after A's 16 bytes + 272 (the offset, added by a write of
	sta $1A12
	lda (SUM + DXO),x
	sta $1A13
	lda (SUB + DXO),x
	sta $1A14
	tia $6000, $0002, 16
	sta $1A1A
	tia $6000, $0002, 16
	iny
	inx
	cpx snu
	bne .u
	pla
	tam #3
	rts

; ---------------------------------------------------------------- the words of the plug cells: listed column by column, rows rising: the
swrd:	lda snp
	bne .go
	rts
.go:	jsr sinc64
	lda #$FF
	sta sbt                 ; (the last cell's column; its row + 1 in sbi)
	clx
.w:	lda SPC,x
	cmp sbt
	bne .a
	lda SPR,x
	cmp sbi
	beq .d
.a:	lda SPC,x               ; MAWR = 64 (rbe + rr) + cbe + cc
	sta sbt
	clc
	adc cbe
	sta t0
	lda SPR,x
	clc
	adc rbe
	tay
	vsel 0                  ; (vsel loads A: first)
	lda t0
	ora s64l,y
	sta $0002
	lda s64h,y
	sta $0003
	vsel 2
.d:	lda (SWH + DXO),x
	cmp #$FF
	beq .up
	sta t1
	lda (SWL + DXO),x
.wr:	sta $0002
	lda t1
	sta $0003
	lda SPR,x
	inc a
	sta sbi
	inx
	cpx snp
	bne .w
	jmp sinc1
.up:	lda (SWL + DXO),x       ; (an upload: the word of slot sfrst + j)
	clc
	adc sfrst
	tay
	lda (SPWH + DXO),y
	sta t1
	lda (SPWL + DXO),y
	bra .wr
sinc64:	lda <$F4
	and #$18
	sta scrs
	lda <$F4
	and #$E7
	ora #$10
	bra sincw
sinc1:	lda <$F4
	and #$E7
	ora scrs
sincw:	sta <$F4
	lda #5
	sta <VDCREG
	st0 #5
	lda <$F3
	sta $0002
	lda <$F4
	sta $0003
	lda #2
	sta <VDCREG
	st0 #2
	rts
scrs:	.db 0

; ---------------------------------------------------------------- the buffer's last plugs back: every cell of its SLB that is not a plug
; cell now (all of them on a hold: SPB then empty) gets its own word: the S word of the near byte now under it (a near column), E's word
; (an edge column: off the grid its slot's, on it the S word on the left, the bar word on the right). The SLB is at the window (srb, scb):
; at another window (R shifted it) a cell's BAT address is the window's cell (rr + srb - rbe, cc + scb - cbe): there the near byte of that
; cell, nothing outside the window's 17 x 33 and nothing in an edge column (E wrote both after the shift); a redraw (rsh bit 0) left none.
sback:	ldx sobi
	lda srb,x
	cmp #$FF
	bne .g
	rts
.g:
	lda rsh
	lsr a
	bcs .z
	cpx #0
	bne .s1
	ldx #84                 ; buffer 0: SLB
.l0:	lda SLB,x
	bne .h0
.n0:	dex
	bpl .l0
	bra .z
.h0:	sta sbt
	lda SPB,x
	eor #$FF
	and sbt
	beq .n0
	sta sbt
	stx sbi
	jsr sbk8
	ldx sbi
	bra .n0
.s1:	ldx #84                 ; buffer 1: SLB + 85
.l1:	lda SLB + 85,x
	bne .h1
.n1:	dex
	bpl .l1
	bra .z
.h1:	sta sbt
	lda SPB,x
	eor #$FF
	and sbt
	beq .n1
	sta sbt
	stx sbi
	jsr sbk8
	ldx sbi
	bra .n1
.z:	ldx sobi
	lda #$FF
	sta srb,x
	txa
	beq .z0
	tii85 (SZERO + DXO), SLB + 85
	rts
.z0:	tii85 (SZERO + DXO), SLB
.x:	rts
; the set bits of sbt (byte sbi of the SLB): each cell put back
sbk8:	ldx sbi                 ; row = sbi / 5, column base = 8 (sbi % 5)
	lda smd5,x
	sta spl                 ; column base
	lda sdv5,x
	sta sr                  ; row (the SLB's window)
.bi:	ldx sbt
	lda klsb,x
	eor sbt
	sta sbt
	lda klsb,x
	dec a
	tax
	lda kpop,x
	ora spl
	sta sph                 ; column (the SLB's window)
	jsr sbk1
	lda sbt
	bne .bi
	rts
; cell (sr, sph) of the SLB's window: its place in this pass's window, its word, written
sbk1:	ldx sobi
	lda sr
	clc
	adc srb,x
	sec
	sbc rbe
	cmp #17
	bcs .xx                 ; (outside the window's rows: not shown, R's)
	sta t0                  ; row now
	lda sph
	clc
	adc scb,x
	sec
	sbc cbe
	cmp #33
	bcs .xx
	sta t1                  ; column now
	lda srb,x               ; (moved: a cell that is a plug cell now is written by swrd; an edge cell is E's)
	cmp rbe
	bne .mv
	lda scb,x
	cmp cbe
	beq .w
	bra .mv
.xx:	rts
.mv:	lda t1
	beq .x
	cmp #32
	beq .x
	ldy t0
	lda (S5 + DXO),y
	sta t2
	lda t1
	lsr a
	lsr a
	lsr a
	clc
	adc t2
	tay
	lda t1
	and #7
	tax
	lda (SBM + DXO),x
	and SPB,y
	bne .x
.w:	lda t1
	beq .el
	cmp #32
	beq .er
	jsr snear               ; A, Y: the near byte's S word
.wr:	pha
	phy
	inc snr
	lda t0
	clc
	adc rbe
	tay
	lda t1
	clc
	adc cbe
	ora s64l,y
	pha
	vsel 0
	pla
	sta $0002
	lda s64h,y
	sta $0003
	vsel 2
	ply
	pla
	sta $0002
	sty $0003
.x:	rts
.el:	lda spx                 ; left edge: on the grid the S word, off it the left set's slot word
	bne .es
	jsr snear
	bra .wr
.er:	lda spx                 ; right edge: on the grid the bar word
	bne .es
	lda (XD_BRH + DXO)+16
	ora #$F0
	tay
	lda (XD_BRL + DXO)+16
	bra .wr
.es:	lda sobi                 ; set q = 2 b + side: ERS + 32 q + row -> slot; EWL / EWH + 18 q + 1 + slot
	asl a
	ldx t1
	beq .e0
	inc a
.e0:	sta t2
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc t0
	tax
	lda (ERS + DXO),x
	sta t3
	lda t2
	asl a
	asl a
	asl a
	asl a                   ; 16 q
	clc
	adc t2
	adc t2                  ; 18 q
	sec
	adc t3                  ; + 1 + slot
	tax
	ldy (EWH + DXO),x
	lda (EWL + DXO),x
	jmp .wr
; the S word of the near byte at window cell (t0, t1) of this pass: A low, Y high
snear:	ldx t0
	lda s64l,x
	clc
	adc p0l
	sta .n+1
	lda s64h,x
	adc skq
	sta .n+2
	ldy t1
.n:	ldx $6000,y
	ldy KSWH,x
	lda KSWL,x
	rts
	.endif
