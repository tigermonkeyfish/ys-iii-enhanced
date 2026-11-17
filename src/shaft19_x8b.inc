	.if PLG
SPB        = $7100      ; DB_NEAR (MPR3): the exact build's plug cells (85 bytes, the rows' form)
SLB        = $7155      ; per buffer (+ 85 b): the cells its last S pass left holding a plug word (the rows' form)
SPV        = $7E00      ; per near byte value: 1 code 0 (the transparent S word), 2 a staircase cell (backdrop class), 4 a see-through near
                        ; cell (no plug), 0 opaque
SPR        = $7F00      ; the exact build's list (row by row, columns rising): window row, column; the walk's fix list: a cell's BAT
SPC        = $7F80      ; address low / high (and its upload index in SWL)
SMAPS      = $9000      ; DB_X (MPR4): per local window id (0-575): its upload this pass (valid when its stamp at SMAPT + id = sstmp)
SMAPT      = $9240
SPSL       = $9500      ; per pool slot (0 .. NPOOL - 1, the dictionary's first): its tile's VRAM address, its BAT word (palette 1)
SPSH       = $9590
SPWL       = $9620
SPWH       = $96B0
SWL        = $9740      ; (unused under WAL=1)
SLOT_IDL   = $97D0      ; per pool slot: cached window id low byte
SLOT_IDH   = $8940      ; per pool slot: cached window id high byte (0..2; $FF = empty; in free $8940-$89FF)
USLOT      = $9480      ; per queued upload (0 .. snu - 1): pool slot assigned (in free $9480-$94FF)
SUL        = $98C0      ; per upload: stream A address (low, middle, bank)
SUM        = $9940
SUB        = $99C0
SCF        = $9A40      ; per pool slot: 1 when its tile's VRAM address is the slot before's + 16 (XD_VMAP's page: set-up only)
SU0        = $9AD0
SU1        = $9B60
SZERO      = $8F00      ; DB_X: 85 zero bytes
S66L       = $8F55      ; (PDD) 66 n (0-16; bank 3's stabs fills it; not read here)
S66H       = $8F66
SX2B       = $8F90      ; a nibble's bits doubled (bank 3's stabs fills it; not read here)
S5         = $8FA0      ; 5 n (0-16)
SBM        = $8FB8      ; 1 << n
S16L       = $8FC0      ; 16 n (0-16)
S16H       = $8FD1
SBSL       = $8FE8      ; the streams' base by X phase (24 bits)
SBSM       = $8FEC
SBSB       = $8FF0
S576L      = $9860      ; 576 n (0-32)
S576H      = $9881
DXO        = $4000      ; DB_X at MPR6 while S runs
SPMAX      = 128
	.if XBAR = 0
NPOOL      = 143
	.else
NPOOL      = 127        ; the backdrop cache's 103 slots, the composite cache's 24 spare
	.endif
	.if WAL
SSTRL      = $0C0000    ; relocated from $016000 under WAL (kbemit removed; static pregen >= $030000)
	.else
SSTRL      = $016000
	.endif
SWT        = $0B1800    ; the window table: 2 bytes at SWT + 2 (561 (4 p + q) + 17 cc + rr): column by column, rows rising

; ---------------------------------------------------------------- state (the recorders read the log through bank 3's slg)
sout:	.ds 16          ; (copied by bank 3's splug) the pass's left-out blocks, its buffer, p0's page in DB_NEAR, kfst | kdrp
sobi:	.db 0
skq:	.db 0
sfst:	.db 0
s64l:	.db $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0
s64h:	.db 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8
; ZP scratch ($C2-$F1 = 48 bytes; IRQ/Sys/Sound/Stub-safe, TII-saved in spass)
z_t0    = $C2
z_t1    = $C3
z_t2    = $C4
z_t3    = $C5
z_snp   = $C6
z_snu   = $C7
z_snr   = $C8
z_shold = $C9
z_snd   = $CA
z_sstrn = $CB
z_sobi  = $CC
z_sstmp = $CD
z_sgrid = $CE
z_spbm  = $CF
z_spx   = $D0
z_spy   = $D1
z_sdx   = $D2
z_sdy   = $D3
z_slo   = $D4
z_shi   = $D5
z_sb2   = $D6
z_smk   = $D7
z_spmk  = $D8
z_sbits = $D4
z_sbt   = $D5
z_zmsk  = $D2
z_sid   = $D4
z_sidth = $D5
z_srmk  = $D6
z_sox   = $D7
z_spw1  = $D8
z_sr    = $D9
z_s5r   = $DA
z_sbu   = $DB
z_snm   = $DC
z_snb   = $DD
z_spp   = $DE
z_sj8   = $DF
z_rbe   = $E0
z_cbe   = $E1
z_obibit = $E2
z_sslot = $E3
z_srbl  = $E4
z_srbh  = $E5
z_swl   = $E6
z_swh   = $E7
z_sra0  = $E8
z_sra1  = $E9
z_sra2  = $EA
z_sncc  = $EB
z_srb0l = $EC
z_srb0h = $ED
z_spa0  = $EE
z_spa1  = $EF
z_spa2  = $F0
z_spw0  = $F1

kzp_sav:	.ds 48
slog5:
spx:	.db 0           ; this pass: X phase (camera X & 6), Y phase, the class (dx | dy << 1)
spy:	.db 0
scls:	.db 0
snp:	.db 0           ; plug cells
snu:	.db 0           ; uploads
snh:	.db 0           ; (PDD) dictionary hits, slots shared in the pass
snd:	.db 0
snsee:	.db 0           ; see-through near cells under a left-out block (the exact build)
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
smode:	.db 0           ; 0: F AND C; 1: the exact build (SPB)
sstr:	.db 0, 0        ; per buffer: its last plug held a staircase cell
skl:	.db 0           ; the transparent word (KSW of code 0); skok: 1 when both code-0 byte values have it
skh:	.db 0
skok:	.db 0
scrs:	.db 0           ; the CR shadow's increment bits as found
scpl:	.db $FF         ; the camera cell (p0) SCC was read for
scph:	.db $FF
SCC:	.ds 85          ; the camera cell's class rows (C)
	.ds 5           ; (row -1 of SFM: zero)
SFM:	.ds 85          ; F: the band's cells in its odd row 2 b + 1 (the even rows' bytes unused: row 2 b reads row 2 b + 1 and, off the
	.ds 5           ; grid in Y, row 2 b - 1); row 17 zero
SRM:	.ds 17          ; per row: bit j = F's byte j is not zero (the exact set: its own)
OLB:	.ds 34          ; per buffer (+ 17 b), per row: bit j = SLB's byte j is not zero
x2m:	.db $00, $C0, $30, $F0, $0C, $CC, $3C, $FC, $03, $C3, $33, $F3, $0F, $CF, $3F, $FF   ; four blocks' bits doubled (MSB first)
x2d:	.db $00, $E0, $38, $F8, $0E, $EE, $3E, $FE, $03, $E3, $3B, $FB, $0F, $EF, $3F, $FF   ; the same and the next column (off the grid in X)
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
; a plug (both are redrawn), no slot taken, the scroll sources as they stand; the class rows read again; the transparent word
sinit:
	.if PDD
	tma #6
	pha
	lda #DB_X
	tam #6
	jsr sclrt_cb0
	pla
	tam #6
	lda #1
	sta sstmp
	.endif
	lda #1
	sta sdirty
	lda #$FF
	sta srb
	sta srb+1
	sta scph
	sta scph_c
	ldx #15
.sbx:	sta SB_DX,x
	dex
	bpl .sbx
	stz sslot
	stz su
	stz su+1
	stz sstr
	stz sstr+1
	lda KSWL                ; (the S word of near byte 0 and of $80: code 0 both)
	sta skl
	ldx KSWH
	stx skh
	stz skok
	cmp KSWL+$80
	bne .k
	cpx KSWH+$80
	bne .k
	inc skok
.k:	lda skl                 ; (the put-back's immediates)
	sta spbkc+1
	lda skh
	sta spbkh+1
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

spass:	tii $20C2, kzp_sav, 48
	tma #6
	pha
	lda #DB_X
	tam #6
	jsr spl1
	php
	tii kzp_sav, $20C2, 48
	plp
	pla
	tam #6
	rts
spl1:	stime sti0
	lda sdirty
	beq .d0
	jsr sclra
.d0:
	stz <z_snp
	stz <z_snu
	stz <z_snr
	stz <z_shold
	stz <z_snd
	stz <z_sstrn
	stz snh
	stz snsee
	lda sobi
	sta <z_sobi
	lda sstmp
	sta <z_sstmp
	lda sslot
	sta <z_sslot
	lda rbe
	sta <z_rbe
	lda cbe
	sta <z_cbe
	lda pxr
	and #6
	sta <z_spx
	sta spx
	cmp #1
	cla
	rol a
	sta scls
	lda pyr
	and #6
	sta <z_spy
	sta spy
	beq .c
	lda scls
	ora #2
	sta scls
.c:	lda <z_spx
	ora <z_spy
	cmp #1
	cla
	rol a
	eor #1
	sta <z_sgrid             ; (1 on the grid)
	jsr sbands              ; F
	lda sfst                ; the set: F AND C, or (a see-through / staircase / dropped block possible) the exact classes
	beq .f
	lda #1
	sta smode
	jsr sexact
	bra .s
.f:	stz smode
	jsr scrows              ; the class rows of the camera cell (when it changed)
	jsr sfastc              ; F AND C into SPB, SRM pruned to non-empty (F AND C) bytes/rows
.s:	stime sti1
	jsr sold                ; the buffer's last plugs in this window's coordinates
	jsr svdc                ; the VDC: select 2, increment 1
	lda <z_sstrn            ; (the put-back's words)
	ldx <z_sobi
	ora sstr,x
	ldx skok
	bne .m
	inc a
.m:	sta <z_spbm
	lda <z_shold
	beq .s0
	jmp .h
.s0:	lda snsee
	beq .r
	lda #3
	sta <z_shold
	jmp .h
.r:	jsr spre                ; the phase's bases, the pool
	jsr swalk               ; put back, words, uploads listed (shold 2 / 4: stopped)
	stime sti2
	stime sti3
	lda <z_shold
	bne .h
	jsr supl                ; the uploads
	stime sti4
	jsr sinc1
	stime sti5
	ldx <z_sobi
	lda <z_rbe
	sta srb,x
	lda <z_cbe
	sta scb,x
	lda <z_snu
	sta su,x
	sta snu
	lda <z_sstrn
	sta sstr,x
	lda <z_snp
	sta snp
	lda <z_snr
	sta snr
	lda <z_snd
	sta snd
	stz shold
	lda <z_sstmp
	sta sstmp
	lda <z_sslot
	sta sslot
	lda c5bxrv
	sta sbx
	lda c5byrv
	sta sbx+1
	clc
	rts
.h:	jsr shold_cache_cb0
	jsr sadv_tok_cb0
	jsr shall               ; HELD: every plug the buffer holds put back, the buffer's slots free
	jsr sinc1
	stz snp
	stz snu
	lda <z_snr
	sta snr
	lda <z_snd
	sta snd
	lda <z_shold
	sta shold
	lda <z_sstmp
	sta sstmp
	lda <z_sslot
	sta sslot
	stime sti3
	ldx <z_sobi
	lda #$FF
	sta srb,x
	stz su,x
	stz sstr,x
	inc nplugov
	bne .h1
	inc nplugov+1
.h1:	lda sbx                 ; (SATPAGE already held at T-1 by .e; restore shown scroll sources)
	sta BXRV
	lda sbx+1
	sta BYRV
	sec
	rts

; ---------------------------------------------------------------- the class rows: C row r = the backdrop-class bits of near cells
scrows:	lda p0l
	cmp scpl
	bne .g
	lda p0h
	cmp scph
	bne .g
	rts
.g:	lda p0l
	sta scpl
	sta <z_t0
	lda p0h
	sta scph
	and #$0F
	sta <z_t1
	lda <z_t0
	and #7
	asl a
	asl a
	ora #$C0
	sta <z_t2               ; the shift's page
	lsr <z_t1
	ror <z_t0
	lsr <z_t1
	ror <z_t0
	lsr <z_t1
	ror <z_t0
	lda <z_t1
	clc
	adc <z_t2
	sta <z_t1               ; t1:t0 = the first byte
	ldx #0
.p:	lda <z_t0               ; the five reads' addresses
	sta .a0+1,x
	lda <z_t1
	sta .a0+2,x
	inc <z_t0
	bne .p1
	inc <z_t1
.p1:	txa
	clc
	adc #6
	tax
	cpx #30
	bne .p
	tma #6
	pha
	lda #DB_CLS
	tam #6
	clx
	cly
.r:
.a0:	lda $C000,x             ; (five copies six bytes apart: the operands patched above)
	sta SCC,y
.a1:	lda $C000,x
	sta SCC+1,y
.a2:	lda $C000,x
	sta SCC+2,y
.a3:	lda $C000,x
	sta SCC+3,y
.a4:	lda $C000,x
	sta SCC+4,y
	txa
	clc
	adc #8
	tax
	tya
	adc #5
	tay
	cpy #85
	bne .r
	pla
	tam #6
	rts

; ---------------------------------------------------------------- F: per band b its blocks' columns (a nibble table, x2m or off the grid
; in X x2d, and a block's third column into the next byte) in SFM's row 2 b + 1; SRM: per row the non-zero bytes (row 2 b: the band's and,
; off the grid in Y, the band before's; row 16 band 7's off the grid in Y)
SB_LO      = $74B0
SB_HI      = $74C0
SB_DX      = $74D0
SB_MK      = $74E0

sbands:	lda scls
	and #1
	asl a
	asl a
	asl a
	asl a
	sta <z_sdx              ; (16: x2d)
	lda scls
	and #2
	beq .y
	lda #$FF
.y:	sta <z_sdy              ; ($FF: off the grid in Y)
	stz <z_spmk
	ldx #5                  ; X = 5 (2 b + 1)
	cly                     ; Y = 2 b
.b:	lda sout,y
	cmp SB_LO,y
	bne .miss
	lda sout+1,y
	cmp SB_HI,y
	bne .miss
	lda <z_sdx
	cmp SB_DX,y
	bne .miss
	lda SB_MK,y
	jmp .m
.miss:	lda sout,y
	sta <z_slo
	sta SB_LO,y
	lda sout+1,y
	sta SB_HI,y
	lda <z_sdx
	sta SB_DX,y
	lda <z_slo
	ora SB_HI,y
	bne .g
	stz SFM,x
	stz SFM+1,x
	stz SFM+2,x
	stz SFM+3,x
	stz SFM+4,x
	cla
	sta SB_MK,y
	jmp .m
.g:	lda SB_HI,y
	sta <z_shi
	sty <z_sb2
	lda <z_slo
	and #15
	ora <z_sdx
	tay
	lda x2m,y
	sta SFM,x
	lda <z_slo
	lsr a
	lsr a
	lsr a
	lsr a
	ora <z_sdx
	tay
	lda x2m,y
	sta SFM+1,x
	lda <z_shi
	and #15
	ora <z_sdx
	tay
	lda x2m,y
	sta SFM+2,x
	lda <z_shi
	lsr a
	lsr a
	lsr a
	lsr a
	ora <z_sdx
	tay
	lda x2m,y
	sta SFM+3,x
	stz SFM+4,x
	lda <z_sdx              ; (off the grid in X: block 3's column 8, 7's 16, 11's 24, 15's 32)
	beq .nc
	lda <z_slo
	and #8
	beq .c1
	lda SFM+1,x
	ora #$80
	sta SFM+1,x
.c1:	bit <z_slo
	bpl .c2
	lda SFM+2,x
	ora #$80
	sta SFM+2,x
.c2:	lda <z_shi
	and #8
	beq .c3
	lda SFM+3,x
	ora #$80
	sta SFM+3,x
.c3:	bit <z_shi
	bpl .nc
	lda #$80
	sta SFM+4,x
.nc:	cla
	ldy SFM,x
	beq .k1
	ora #1
.k1:	ldy SFM+1,x
	beq .k2
	ora #2
.k2:	ldy SFM+2,x
	beq .k3
	ora #4
.k3:	ldy SFM+3,x
	beq .k4
	ora #8
.k4:	ldy SFM+4,x
	beq .k5
	ora #16
.k5:	ldy <z_sb2
	sta SB_MK,y
.m:	sta SRM+1,y             ; row 2 b + 1
	sta <z_smk
	lda <z_spmk
	and <z_sdy
	ora <z_smk
	sta SRM,y               ; row 2 b
	lda <z_smk
	sta <z_spmk
	txa
	clc
	adc #10
	tax
	iny
	iny
	cpy #16
	beq .e
	jmp .b
.e:	lda <z_spmk
	and <z_sdy
	sta SRM+16
	rts
; ---------------------------------------------------------------- fast set (no see-through block left out): SPB = F AND C on non-zero SRM
sfastc:	jmp sfastc_cb0
; ---------------------------------------------------------------- the exact set (a see-through, staircase or dropped block possible): F's
; cells by their near byte's class (SPV: as p4's sbuild): 1 / 2 kept (2: a staircase cell, sstrn), 4 counted (snsee: the hold), 0 dropped;
; into SPB (rows), SRM again
sexact:	tii85 (SZERO + DXO), SPB
	stz <z_sr
	stz <z_s5r
.r:	ldy <z_sr
	lda SRM,y
	bne .rg
	jmp .nr
.rg:
	sta <z_sbu
	stz <z_snm
	lda s64l,y
	clc
	adc p0l
	sta .n+1
	lda s64h,y
	adc skq
	sta .n+2
	ldx <z_s5r
	stz <z_sj8
	lda #1
	sta <z_snb
.b:	lsr <z_sbu
	bcc .nb
	lda <z_sr               ; F's byte: row 2 b + 1's; an even row: row r + 1's (and off the grid in Y row r - 1's)
	lsr a
	bcs .od
	lda SFM+5,x
	ldy <z_sdy
	beq .f
	ora SFM-5,x
	bra .f
.od:	lda SFM,x
.f:	sta <z_sbits
	stz <z_spp
	stx <z_t2
	ldy <z_sj8
	lda #$80
	sta <z_sbt
.l:	asl <z_sbits
	bcc .z
.n:	ldx $6000,y
	lda SPV,x
	beq .z
	cmp #4
	beq .s
	cmp #2
	bne .k
	sta <z_sstrn
.k:	lda <z_sbt
	tsb <z_spp
	bra .z
.s:	inc snsee
.z:	iny
	lsr <z_sbt
	bne .l
	ldx <z_t2
	lda <z_spp
	sta SPB,x
	beq .nb
	lda <z_snb
	tsb <z_snm
.nb:	inx
	asl <z_snb
	lda <z_sj8
	clc
	adc #8
	sta <z_sj8
	lda <z_sbu
	bne .b
	ldy <z_sr
	lda <z_snm
	sta SRM,y
.nr:	lda <z_s5r
	clc
	adc #5
	sta <z_s5r
	inc <z_sr
	lda <z_sr
	cmp #17
	beq .rx
	jmp .r
.rx:
	rts
; ---------------------------------------------------------------- the buffer's last plugs, in this window's coordinates: none (no S pass,
; or a redraw since: rsh bit 0), as written (the same window), or moved (R shifted it: rows by srb - rbe, columns by scb - cbe; the edge
; columns 0 and 32 and what falls outside dropped: E and R wrote those cells). In place in the buffer's SLB; OLB after
sold:	ldx <z_sobi
	lda srb,x
	cmp #$FF
	bne .v
	rts                     ; (none: SLB and OLB zero already)
.v:	lda rsh
	lsr a
	bcs .z
	lda srb,x
	cmp <z_rbe
	bne .mv
	lda scb,x
	cmp <z_cbe
	bne .mv
	rts
.z:	jmp sclr                ; (a redraw: none)
.mv:	lda scb,x               ; dc = scb - cbe: new column = old + dc
	sec
	sbc <z_cbe
	sta <z_t2
	lda srb,x               ; dr = srb - rbe: new row = old + dr
	sec
	sbc <z_rbe
	sta <z_t3
	clc                     ; (|dr| > 16 or |dc| > 32: none left)
	adc #16
	cmp #33
	bcs .z
	lda <z_t2
	clc
	adc #32
	cmp #65
	bcs .z
	lda <z_sobi             ; t0 = 85 b
	beq .y0
	lda #85
.y0:	sta <z_t0
.cl:	lda <z_t2               ; the columns, one bit a turn
	beq .rw
	bmi .lf
	dec <z_t2               ; (right: + 1; each row's five bytes from the first, the carry cleared)
	ldx <z_t0
	ldy #17
.crb:	clc
	ror SLB,x
	ror SLB+1,x
	ror SLB+2,x
	ror SLB+3,x
	ror SLB+4,x
	txa
	clc
	adc #5
	tax
	dey
	bne .crb
	bra .cl
.lf:	inc <z_t2               ; (left: - 1; from the last byte of each row)
	ldx <z_t0
	ldy #17
.cf:	clc
	rol SLB+4,x
	rol SLB+3,x
	rol SLB+2,x
	rol SLB+1,x
	rol SLB,x
	txa
	clc
	adc #5
	tax
	dey
	bne .cf
	bra .cl
.rw:	lda <z_t3               ; the rows, one a turn
	bne .rw1
	jmp .e
.rw1:	bmi .up
	dec <z_t3               ; (down: + 1; rows 16 .. 1 from the row above, row 0 none)
	lda <z_sobi
	bne .dn1
	tdd SLB+79, SLB+84, 20
	tdd SLB+59, SLB+64, 20
	tdd SLB+39, SLB+44, 20
	tdd SLB+19, SLB+24, 20
	tii (SZERO + DXO), SLB, 5
	bra .rw
.dn1:	tdd SLB+164, SLB+169, 20
	tdd SLB+144, SLB+149, 20
	tdd SLB+124, SLB+129, 20
	tdd SLB+104, SLB+109, 20
	tii (SZERO + DXO), SLB+85, 5
	bra .rw
.up:	inc <z_t3               ; (up: - 1; rows 0 .. 15 from the row below, row 16 none)
	lda <z_sobi
	bne .up1
	tii SLB+5, SLB, 20
	tii SLB+25, SLB+20, 20
	tii SLB+45, SLB+40, 20
	tii SLB+65, SLB+60, 20
	tii (SZERO + DXO), SLB+80, 5
	jmp .rw
.up1:	tii SLB+90, SLB+85, 20
	tii SLB+110, SLB+105, 20
	tii SLB+130, SLB+125, 20
	tii SLB+150, SLB+145, 20
	tii (SZERO + DXO), SLB+165, 5
	jmp .rw
.e:	ldy <z_t0               ; the edge columns and the columns past 32 dropped; OLB again
	ldx <z_sobi
	beq .e0
	ldx #17
.e0:	lda #17
	sta <z_t1
.er:	lda SLB,y
	and #$7F
	sta SLB,y
	cla
	sta SLB+4,y
	sta <z_snm
	lda SLB,y
	beq .1
	lda #1
	tsb <z_snm
.1:	lda SLB+1,y
	beq .2
	lda #2
	tsb <z_snm
.2:	lda SLB+2,y
	beq .3
	lda #4
	tsb <z_snm
.3:	lda SLB+3,y
	beq .4
	lda #8
	tsb <z_snm
.4:	lda <z_snm
	sta OLB,x
	inx
	tya
	clc
	adc #5
	tay
	dec <z_t1
	bne .er
	rts
; the buffer's SLB and OLB zero; sclra both buffers'
sclr:	lda <z_sobi
	bne .b1
	tii85 (SZERO + DXO), SLB
	tii (SZERO + DXO), OLB, 17
	rts
.b1:	tii85 (SZERO + DXO), SLB+85
	tii (SZERO + DXO), OLB+17, 17
	rts
sclra:	tii85 (SZERO + DXO), SLB
	tii85 (SZERO + DXO), SLB+85
	tii (SZERO + DXO), OLB, 17
	tii (SZERO + DXO), OLB+17, 17
	lda #$FF
	clx
.sbz:	sta SB_DX,x
	inx
	inx
	cpx #16
	bne .sbz
	jsr scache_clr_cb0
	lda #1
	sta sutok0
	sta sutok1
	sta spw_suhl+1
	sta spw_sunl+1
	sta spw_othc+1
	lda #$FF
	sta scph_c
	stz sslot
	stz sdirty
	rts
sdirty:	.db 0

svdc:	lda #2
	sta <VDCREG
	st0 #2
	lda <$F4
	and #$18
	sta scrs
	beq .x
	lda <$F4
	and #$E7
	bra sincw
.x:	rts
sinc1:	lda scrs
	beq .x
	lda <$F4
	and #$E7
	ora scrs
	bra sincw
.x:	rts
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

spre:	lda #$FF
	sta <z_sidth
	lda <z_sobi
	beq .b0
	lda #17
	bra .b1
.b0:	cla
.b1:	sta sob17
	jsr sadv_tok_cb0
	lda <z_sgrid
	beq .off
	rts
.off:	lda <z_spx              ; the phase's stream base + 16 - 4 q (24 bits)
	lsr a
	tax
	lda <z_spy
	asl a
	eor #$FF
	sec
	adc #16                 ; 16 - 2 spy (= 16 - 4 q)
	clc
	adc (SBSL + DXO),x
	sta <z_spa0
	lda (SBSM + DXO),x
	adc #0
	sta <z_spa1
	lda (SBSB + DXO),x
	adc #0
	sta <z_spa2
	lda <z_spx              ; (PDD) phase 4 p + q = 2 px + py / 2
	asl a
	sta <z_t0
	lda <z_spy
	lsr a
	clc
	adc <z_t0
	tax
	lda swpl,x
	sta <z_spw0
	lda swph,x
	sta <z_spw1
	lda #$0B
	sta $1A34
	txa
	inc a
	sta <z_sstmp
	stx scph_c
	rts
sslot:	.db 0
scph_c:	.db $FF
sutok0:	.db 1
sutok1:	.db 1
s34l:	.db <0, <34, <68, <102, <136, <170, <204, <238, <272, <306, <340, <374, <408, <442, <476, <510, <544
	.db <578, <612, <646, <680, <714, <748, <782, <816, <850, <884, <918, <952, <986, <1020, <1054, <1088
s34h:	.db >0, >34, >68, >102, >136, >170, >204, >238, >272, >306, >340, >374, >408, >442, >476, >510, >544
	.db >578, >612, >646, >680, >714, >748, >782, >816, >850, >884, >918, >952, >986, >1020, >1054, >1088
swpl:	.db <($1800 + 0), <($1800 + 1122), <($1800 + 2244), <($1800 + 3366), <($1800 + 4488), <($1800 + 5610), <($1800 + 6732), <($1800 + 7854)
	.db <($1800 + 8976), <($1800 + 10098), <($1800 + 11220), <($1800 + 12342), <($1800 + 13464), <($1800 + 14586), <($1800 + 15708), <($1800 + 16830)
swph:	.db >($1800 + 0), >($1800 + 1122), >($1800 + 2244), >($1800 + 3366), >($1800 + 4488), >($1800 + 5610), >($1800 + 6732), >($1800 + 7854)
	.db >($1800 + 8976), >($1800 + 10098), >($1800 + 11220), >($1800 + 12342), >($1800 + 13464), >($1800 + 14586), >($1800 + 15708), >($1800 + 16830)

; new bits p (fast: F AND C, F the row's own byte, row 2 b + 1's for an even row, ORed with row 2 b - 1's off the grid in Y; the exact set:
; SPB's byte); the old q = old AND NOT p, put back; SLB's byte = p, written; then p's cells
swalk:	lda <z_sobi             ; (the buffer's SLB in the two operands)
	beq .b0
	lda #<(SLB + 85)
	sta .o+1
	sta .s+1
	lda #>(SLB + 85)
	sta .o+2
	sta .s+2
	bra .b1
.b0:	lda #<SLB
	sta .o+1
	sta .s+1
	lda #>SLB
	sta .o+2
	sta .s+2
.b1:	lda <z_sgrid            ; (the cells' writer)
	beq .w0
	lda #<spwg
	sta .w+1
	lda #>spwg
	sta .w+2
	bra .w1
.w0:	lda #<spwo
	sta .w+1
	lda #>spwo
	sta .w+2
.w1:	lda <z_rbe              ; row 0's BAT address: 64 rbe + cbe
	stz <z_srb0h
	lsr a
	ror <z_srb0h
	lsr a
	ror <z_srb0h
	ldx <z_srb0h
	sta <z_srb0h
	txa
	ora <z_cbe
	sta <z_srb0l
	stz <z_sr
	stz <z_s5r
	lda sob17
	sta <z_sox
.row:	ldy <z_sr
	ldx <z_sox
	lda OLB,x
	ora SRM,y
	bne .rg
	jmp .nr
.rg:	sta <z_sbu
	lda <z_spbm
	beq .nbk
	jsr spbk_row
.nbk:	lda <z_srb0l            ; the row's BAT address
	clc
	adc s64l,y
	sta <z_srbl
	lda <z_srb0h
	adc s64h,y
	sta <z_srbh
	lda SRM,y
	sta <z_srmk
	beq .rx
	lda <z_sgrid
	beq .og
	lda s64l,y              ; (on the grid: the row's screen backdrop words)
	sta sgw0+1
	inc a
	sta sgw1+1
	lda s64h,y
	clc
	adc #>(XD_SW + DXO)
	sta sgw0+2
	sta sgw1+2
	bra .rx
.og:	lda <z_spa0             ; row stream base: spa + 16 * sr (off-grid only)
	clc
	adc (S16L + DXO),y
	sta <z_sra0
	lda <z_spa1
	adc (S16H + DXO),y
	sta <z_sra1
	lda <z_spa2
	adc #0
	sta <z_sra2
	tya                     ; (off it: the row's window table address)
	asl a
	clc
	adc <z_spw0
	sta <z_swl
	lda <z_spw1
	adc #0
	sta <z_swh
.rx:	lda #$FF
	sta <z_sncc
	stz <z_snm
	ldx <z_s5r
	cly                     ; (Y: the byte's first column)
	lda #1
	sta <z_snb
.by:	lsr <z_sbu
	bcc .sk
	lda <z_srmk
	and <z_snb
	beq .p
	tsb <z_snm
	lda SPB,x
.p:	sta <z_spp
	eor #$FF
.o:	and SLB,x
	beq .q0
	phx
	phy
	jsr spbk                ; put back
	lda #$FF
	sta <z_sncc
	ply
	plx
.q0:	lda <z_spp
.s:	sta SLB,x
	beq .sk0
	phx
	phy
.w:	jsr spwo                ; the new cells
	ply
	plx
	lda <z_shold
	bne .x
.sk0:	lda <z_sbu
	beq .ed
.sk:	inx
	tya
	clc
	adc #8
	tay
	asl <z_snb
	bra .by
.ed:	ldx <z_sox
	lda <z_snm
	sta OLB,x
.nr:	inc <z_sox
	lda <z_s5r
	clc
	adc #5
	sta <z_s5r
	inc <z_sr
	lda <z_sr
	cmp #17
	beq .x
	jmp .row
.x:	rts
sob17:	.db 0

; ---------------------------------------------------------------- put back the cells of A (row sr, columns Y + bit, MSB first): code 0
; the transparent word (patched in at sinit); spbm: each cell's own S word; an edge cell E's word
spbk_row:
	lda s64l,y
	clc
	adc p0l
	sta spbk_nr+1
	lda s64h,y
	adc skq
	sta spbk_nr+2
	rts
spbk:
spbkl:	bmi .hi
	tax
	tya
	clc
	adc sclz_skip,x
	tay
	lda sclz_rem,x
	bra .c
.hi:	asl a
.c:	tax
	inc <z_snr
	cpy <z_sncc
	beq .k
	tya
	clc
	adc <z_srbl
	sei
	st0 #0
	sta $0002
	lda <z_srbh
	sta $0003
	st0 #2
	cli
.k:	tya                     ; (columns 0 and 32: the edge cells)
	and #$1F
	beq spbk_e
	lda <z_spbm
	beq spbkc
	stx <z_t0
spbk_nr:
	ldx $6000,y
	lda KSWL,x
	sta $0002
	lda KSWH,x
	sta $0003
	ldx <z_t0
	bra spbkd
spbk_e:	lda <z_sr
	sta <z_t0
	sty <z_t1
	phx
	phy
	jsr sedge
	lda <z_t3
	sta $0002
	sty $0003
	ply
	plx
	bra spbkd
spbkc:	st1 #0                  ; (the transparent word: low, high)
spbkh:	st2 #0
spbkd:	iny
	sty <z_sncc
	txa
	bne spbkl
	rts

; ---------------------------------------------------------------- the new cells of A (row sr, columns Y + bit), off the grid: the window
spwo:
spwol:	bmi .hi
	tax
	tya
	clc
	adc sclz_skip,x
	tay
	lda sclz_rem,x
	bra .c
.hi:	asl a
.c:	sta <z_zmsk
	lda <z_snp
	bpl .spok
	lda #2
	sta <z_shold
	rts
.spok:	inc <z_snp
	cpy <z_sncc
	beq .nx
	lda <z_swl              ; (port 3: the window table at spw + 34 cc + 2 r)
	clc
	adc s34l,y
	sta $1A32
	lda <z_swh
	adc s34h,y
	sta $1A33
	sty <z_sncc             ; (an id leaves the VDC's address here)
	tya
	clc
	adc <z_srbl
	sei
	st0 #0
	sta $0002
	lda <z_srbh
	sta $0003
	st0 #2
	cli
	bra .mr
.nx:	sta $1A3A
.mr:	lda $1A30
	ldx $1A30
	cpx #$10
	bcc .id
	sta $0002
	stx $0003
	iny
	sty <z_sncc
	lda <z_zmsk
	bne spwol
	rts
.id:	sta <z_sid
	cpx <z_sidth
	beq spw_idok
	stx <z_sidth
	txa
	clc
	adc #>(SMAPT + DXO)
	sta spw_t+2
	sta spw_t2+2
	txa
	clc
	adc #>(SMAPS + DXO)
	sta spw_m+2
	sta spw_m2+2
spw_idok:
	ldx <z_sid
spw_t:	lda SMAPT + DXO,x
	cmp <z_sstmp
	bne spw_nu
spw_m:	lda (SMAPS + DXO) & $FF00,x
	inc <z_snd
	tax
spw_suhl:
	lda #$01
spw_suhs:
	sta SU0 + DXO,x
	jmp spw_fx
spw_nu:	sty <z_t0
	ldy <z_sslot
	ldx #NPOOL
spw_fnd:
spw_othl:
	lda SU1 + DXO,y
spw_othc:
	cmp #1
	bne spw_fok
	iny
	cpy #NPOOL
	bcc .n
	cly
.n:	dex
	bne spw_fnd
	ldy <z_t0
	jmp spw_full
spw_fok:
	tya
	inc a
	cmp #NPOOL
	bcc .w
	cla
.w:	sta <z_sslot
	ldx SLOT_IDH + DXO,y
	bmi spw_noinv
	txa
	clc
	adc #>(SMAPS + DXO)
	sta spw_invc+2
	adc #2
	sta spw_inv+2
	ldx SLOT_IDL + DXO,y
	tya
spw_invc:
	cmp (SMAPS + DXO) & $FF00,x
	bne spw_noinv
spw_inv:
	stz SMAPT + DXO,x
spw_noinv:
spw_sunl:
	lda #$01
spw_suns:
	sta SU0 + DXO,y
	lda <z_sid
	sta SLOT_IDL + DXO,y
	lda <z_sidth
	sta SLOT_IDH + DXO,y
	ldx <z_sid
	lda <z_sstmp
spw_t2:	sta SMAPT + DXO,x
	tya
spw_m2:	sta (SMAPS + DXO) & $FF00,x
	sty <z_t1
	ldx <z_snu
	sta USLOT + DXO,x
	ldy <z_t0
	lda <z_sra0
	clc
	adc S576L + DXO,y
	sta SUL + DXO,x
	lda <z_sra1
	adc S576H + DXO,y
	sta SUM + DXO,x
	lda <z_sra2
	adc #0
	sta SUB + DXO,x
	inc <z_snu
	ldx <z_t1
spw_fx:	lda (SPWL + DXO),x      ; write pool slot BAT word directly, keeping MAWR & sncc contiguous
	sta $0002
	lda (SPWH + DXO),x
	sta $0003
	iny
	sty <z_sncc
	lda <z_zmsk
	beq .x2
	jmp spwol
.x2:	rts
spw_full:
	lda #4
	sta <z_shold
	rts

; ---------------------------------------------------------------- the new cells of A on the grid: the screen's backdrop word (row patched
spwg:
spwgl:	bmi .hi
	tax
	tya
	clc
	adc sclz_skip,x
	tay
	lda sclz_rem,x
	bra .c
.hi:	asl a
.c:	tax
	lda <z_snp
	bpl .spok
	lda #2
	sta <z_shold
	rts
.spok:	inc <z_snp
	cpy <z_sncc
	beq sgwr
	tya
	clc
	adc <z_srbl
	sei
	st0 #0
	sta $0002
	lda <z_srbh
	sta $0003
	st0 #2
	cli
sgwr:	phx
	tya
	asl a
	tax
sgw0:	lda XD_SW + DXO,x
	sta $0002
sgw1:	lda XD_SW + DXO + 1,x
	sta $0003
	plx
	iny
	sty <z_sncc
	txa
	bne spwgl
	rts

; ---------------------------------------------------------------- HELD: every cell of the buffer's SLB (this pass's written cells and the
; old ones not put back yet) gets its own word; SLB and OLB zero
shall:	stz <z_sr
	stz <z_s5r
	lda <z_rbe
	stz <z_srbh
	lsr a
	ror <z_srbh
	lsr a
	ror <z_srbh
	ldx <z_srbh
	stx <z_srbl
	sta <z_srbh
	lda <z_srbl
	ora <z_cbe
	sta <z_srbl
.row:	lda #$FF
	sta <z_sncc
	stz <z_sj8
	lda <z_spbm
	beq .nsb
	ldy <z_sr
	jsr spbk_row
.nsb:	lda <z_sobi
	beq .y
	lda #85
.y:	clc
	adc <z_s5r
	tax
.by:	lda SLB,x
	beq .n
	phx
	ldy <z_sj8
	jsr spbk
	plx
.n:	inx
	lda <z_sj8
	clc
	adc #8
	sta <z_sj8
	cmp #40
	bne .by
	inc <z_sr
	lda <z_sr
	cmp #17
	beq .x
	lda <z_s5r
	clc
	adc #5
	sta <z_s5r
	lda <z_srbl
	clc
	adc #64
	sta <z_srbl
	bcc .row
	inc <z_srbh
	bra .row
.x:	jmp sclr

; ---------------------------------------------------------------- the uploads: port 1's data at every address of bank $41 (MPR3 here),
; straight into the VDC: MAWR the slot (not set when the slot's tile follows the last one's: the VDC's address ran on), A's 16 bytes, B's 16
supl:	lda <z_snu
	bne .go
	rts
.go:	tma #3
	pha
	lda #$41
	tam #3
	lda #2
	sta <VDCREG
	st0 #2
	clx
	ldy USLOT + DXO
	bra .ma
.u:	sty <z_t0
	ldy USLOT + DXO,x
	tya
	dec a
	cmp <z_t0
	bne .ma
	lda (SCF + DXO),y       ; (the slot's tile follows the last one's in VRAM: the VDC's address ran on)
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
	inx
	cpx <z_snu
	bne .u
	pla
	tam #3
	rts

; ---------------------------------------------------------------- an edge cell's word at window cell (t0, t1 = 0 or 32): on the grid in X
; the S word on the left, the bar word on the right; off it the left / right set's slot word (E's). Returns the word: t3 low, Y high
sedge:	lda <z_t1
	bne .er
	lda <z_spx              ; left edge
	bne .es
	jmp snear
.er:	lda <z_spx              ; right edge: on the grid the bar word
	bne .es
	lda (XD_BRH + DXO)+16
	ora #$F0
	tay
	lda (XD_BRL + DXO)+16
	sta <z_t3
	rts
.es:	jmp sedge_es_cb0
; the S word of the near byte at window cell (t0, t1) of this pass: t3 low, Y high
snear:	ldx <z_t0
	lda s64l,x
	clc
	adc p0l
	sta .n+1
	lda s64h,x
	adc skq
	sta .n+2
	ldy <z_t1
.n:	ldx $6000,y
	ldy KSWH,x
	lda KSWL,x
	sta <z_t3
	rts
	.endif
