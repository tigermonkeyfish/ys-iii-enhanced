	.if PLG
SXO        = 0          ; DB_X at MPR4 here
; the entries at $C600 (X from s6go: the low byte)
s6ent:	jmp s6str               ; 0 the streams under their key
	jmp s6pool              ; 3 the pool's tables
	.if WAL
	jmp wbuild
	.else
	jmp obuild
	.endif
	jmp s6dict              ; 9 (PDD) after the pool: the window table's dictionary words (when made again), the dictionary's tiles in VRAM
	jmp s6dup               ; 12 (PDD) reeng: the dictionary's tiles in VRAM
	.if OCK & (WAL = 0)
	jmp s6ock               ; 15 (OCK) the upload-cost order (after s6dict)
	.endif
STB        = $9000 + SXO ; a field row's 32 backdrop tiles as read (32 bytes each)
SSH        = $9400 + SXO ; the shift tables: + 512 p the left tile's byte (b << (8 - 2 p), 0 for p 0), + 256 the right tile's (b >> 2 p)
SKEYA      = $0F5100    ; the streams' key on the card: $19 $F1 SVER, two sums over the screen's backdrop words and their tiles (the window
SVER       = 4          ; table and the dictionary's list are kept under it too)
SDLA       = $0F5110    ; the dictionary's list on the card: its count, then per entry phase, column, row, id (2)
SHT        = $0B6000    ; set-up: the windows' key table (1,024 entries of 8 bytes: stamp, the four tile codes, the id)
skey:	.db $19, $F1, SVER, 0, 0
scached:	.db 0
nsbuild:	.db 0           ; set-ups that made them
sbar:	.db $FF, 0, $FF, 0, $FF, 0, $FF, 0, $FF, 0, $FF, 0, $FF, 0, $FF, 0   ; the bars' pixels: colour 1 (black)
	.ds 16
ssr:	.db 0           ; field tile row, phase, column
ssp:	.db 0
ssc:	.db 0
s9t:	.db 0
s9u:	.db 0
s9l:	.db 0, 0, 0
q576x:	.db <0, <576, <1152, <1728, <2304, <2880, <3456, <4032, <4608, <5184, <5760, <6336, <6912, <7488, <8064, <8640, <9216
	.db <9792, <10368, <10944, <11520, <12096, <12672, <13248, <13824, <14400, <14976, <15552, <16128, <16704, <17280, <17856, <18432
q576y:	.db >0, >576, >1152, >1728, >2304, >2880, >3456, >4032, >4608, >5184, >5760, >6336, >6912, >7488, >8064, >8640, >9216
	.db >9792, >10368, >10944, >11520, >12096, >12672, >13248, >13824, >14400, >14976, >15552, >16128, >16704, >17280, >17856, >18432
qbsx:	.db <SSTRL, <(SSTRL + 19008), <(SSTRL + $10000), <(SSTRL + $10000 + 19008)
qbsn:	.db >SSTRL, >(SSTRL + 19008), >(SSTRL + $10000), >(SSTRL + $10000 + 19008)
qbsc:	.db (SSTRL >> 16), ((SSTRL + 19008) >> 16), ((SSTRL + $10000) >> 16), ((SSTRL + $10000 + 19008) >> 16)

s6str:	tma #3
	pha
	lda #DB_NEAR
	tam #3
	clx
.v:	lda ocw,x
	cmp #1
	beq .vs
	cmp #16
	bne .v0
	lda occ,x
	beq .v4
	lda #2
	bra .vs
.v4:	lda #4
	bra .vs
.v0:	cla
.vs:	sta SPV,x
	inx
	bne .v
	pla
	tam #3
	tma #4
	pha
	lda #DB_X
	tam #4
	jsr skeyc               ; the key
	stz $1A02
	lda #>SKEYA
	sta $1A03
	lda #(SKEYA >> 16)
	sta $1A04
	clx
.kc:	lda $1A00
	cmp skey,x
	bne .bd
	inx
	cpx #5
	bne .kc
	lda #1
	sta scached
	.if PDD
	jsr sdlrd
	.endif
	bra .x
.bd:	stz scached
	inc nsbuild
	jsr sstrm
	.if PDD
	jsr s6wt1               ; the window table's ids and the dictionary's list
	.endif
	stz $1A02               ; the key, last
	lda #>SKEYA
	sta $1A03
	lda #(SKEYA >> 16)
	sta $1A04
	tia skey, $1A00, 5
.x:	pla
	tam #4
	rts
s6pool:	tma #4
	pha
	lda #DB_X
	tam #4
	jsr spool
	pla
	tam #4
	rts
spool:	clx
	ldy #1
.b:	lda XD_BTL + SXO,y
	sta t0
	lda XD_BTH + SXO,y
	jsr .put
	iny
	.if XBAR = 0
	cpy #XBN + 17
	.else
	cpy #XBN + 1
	.endif
	bne .b
	ldy #73
.c:	lda XD_CTL + SXO,y
	sta t0
	lda XD_CTH + SXO,y
	jsr .put
	iny
	cpy #XCN + 1
	bne .c
	clx                     ; sorted by VRAM address (selection), then SCF: 1 where a slot's tile follows the slot before's
.s:	txa
	tay
	inx
	cpx #NPOOL
	beq .f
	dex
	phx
.m:	inx                     ; Y: the lowest from X on
	cpx #NPOOL
	beq .mx
	lda SPSL + SXO,x
	cmp SPSL + SXO,y
	lda SPSH + SXO,x
	sbc SPSH + SXO,y
	bcs .m
	txa
	tay
	bra .m
.mx:	plx
	lda SPSL + SXO,x        ; swap X and Y (four tables)
	pha
	lda SPSL + SXO,y
	sta SPSL + SXO,x
	pla
	sta SPSL + SXO,y
	lda SPSH + SXO,x
	pha
	lda SPSH + SXO,y
	sta SPSH + SXO,x
	pla
	sta SPSH + SXO,y
	lda SPWL + SXO,x
	pha
	lda SPWL + SXO,y
	sta SPWL + SXO,x
	pla
	sta SPWL + SXO,y
	lda SPWH + SXO,x
	pha
	lda SPWH + SXO,y
	sta SPWH + SXO,x
	pla
	sta SPWH + SXO,y
	inx
	bra .s
.f:	stz SCF + SXO
	ldx #1
.g:	lda SPSL + SXO - 1,x
	clc
	adc #16
	sta t0
	lda SPSH + SXO - 1,x
	adc #0
	cmp SPSH + SXO,x
	bne .g0
	lda t0
	cmp SPSL + SXO,x
	bne .g0
	lda #1
	bra .g1
.g0:	cla
.g1:	sta SCF + SXO,x
	inx
	cpx #NPOOL
	bne .g
	rts
.put:	sta t1
	ora #$10
	sta SPWH + SXO,x
	lda t0
	sta SPWL + SXO,x
	asl a
	asl a
	asl a
	asl a
	sta SPSL + SXO,x
	lda t1
	asl a
	asl a
	asl a
	asl a
	sta t1
	lda t0
	lsr a
	lsr a
	lsr a
	lsr a
	ora t1
	sta SPSH + SXO,x
	inx
	rts
; the key: two running sums over the screen's backdrop words (XD_SW) and the 32 bytes of each one's tile in VRAM
skeyc:	stz skey+3
	stz skey+4
	stz ssr
.r:	stz ssc
.c:	jsr stadr               ; (A low, X high: the tile's VRAM address; t0 / t2 its word)
	pha
	lda t0
	jsr sadd
	lda t2
	jsr sadd
	pla
	jsr vmarr
	ldy #32
.b:	lda $0002
	jsr sadd
	lda $0003
	jsr sadd
	dey
	dey
	bne .b
	inc ssc
	lda ssc
	cmp #32
	bne .c
	inc ssr
	lda ssr
	cmp #16
	bne .r
	rts
sadd:	clc
	adc skey+3
	sta skey+3
	clc
	adc skey+4
	sta skey+4
	rts
; field cell (ssr, ssc)'s tile: its word from XD_SW (both bytes into the key), A / X its VRAM address
stadr:	lda ssr
	lsr a
	lsr a
	clc
	adc #>(XD_SW + SXO)
	sta .l+2
	sta .h+2
	lda ssr
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	sta t0
	lda ssc
	asl a
	ora t0
	sta .l+1
	inc a
	sta .h+1
.l:	lda XD_SW + SXO
	sta t0
.h:	lda XD_SW + SXO + 1
	sta t2
	and #7
	asl a
	asl a
	asl a
	asl a
	sta t1
	lda t0
	lsr a
	lsr a
	lsr a
	lsr a
	ora t1
	tax
	lda t0
	asl a
	asl a
	asl a
	asl a
	rts
; the streams (design 2.4): X phase p (2 p px), cell column cc 0-32 at SSTR(p) + 576 cc: A = planes 0 / 1 of the screen's lines -8 .. 135
; (2 bytes a line), B = planes 2 / 3, the backdrop as it stands on the screen under the cell (its pixels from field x 8 cc - 2 p): the left
; tile's last 2 p pixels then the right tile's first 8 - 2 p; the bars (x < 0, x >= 256) colour 1 (black), lines outside the field 0
sstrm:	cly                     ; the shift tables, phase Y
.tp:	tya
	asl a
	clc
	adc #>SSH
	sta .tl+2
	inc a
	sta .tr+2
	clx
.tb:	txa
	phy
	cpy #0
	beq .r0
.rs:	lsr a
	lsr a
	dey
	bne .rs
.r0:	ply
.tr:	sta SSH + 256,x
	txa
	cpy #0
	beq .l0
	phy
.ls:	cpy #4
	beq .l1
	asl a
	asl a
	iny
	bra .ls
.l1:	ply
	bra .tl
.l0:	cla
.tl:	sta SSH,x
	inx
	bne .tb
	iny
	cpy #4
	bne .tp
	stz ssr                 ; the field's 16 tile rows
.r:	stz ssc                 ; its 32 tiles into STB
.rt:	jsr stadr
	jsr vmarr
	lda ssc
	asl a
	asl a
	asl a
	asl a
	asl a
	sta .rd+3
	lda ssc
	lsr a
	lsr a
	lsr a
	clc
	adc #>STB
	sta .rd+4
.rd:	tai $0002, STB, 32
	inc ssc
	lda ssc
	cmp #32
	bne .rt
	stz ssp
.p:	lda ssp                 ; the phase's shift tables
	asl a
	clc
	adc #>SSH
	sta .sl+2
	inc a
	sta .sr+2
	stz ssc
.cc:	lda ssc                 ; left tile: column cc - 1 (cc 0: the bar), right: cc (32: the bar)
	beq .lb
	dec a
	jsr .tad
	sta .la+1
	stx .la+2
	bra .rr
.lb:	lda #<sbar
	sta .la+1
	lda #>sbar
	sta .la+2
.rr:	lda ssc
	cmp #32
	beq .rb
	jsr .tad
	sta .ra+1
	stx .ra+2
	bra .ad
.rb:	lda #<sbar
	sta .ra+1
	lda #>sbar
	sta .ra+2
.ad:	ldx ssc                 ; A: SSTR(p) + 576 cc + 16 ssr + 16
	ldy ssp
	lda ssr
	asl a
	asl a
	asl a
	asl a
	clc
	adc #16
	sta t0
	lda #0
	rol a
	sta t1
	lda q576x,x
	clc
	adc t0
	sta t0
	lda q576y,x
	adc t1
	sta t1
	lda qbsx,y
	clc
	adc t0
	sta s9l
	lda qbsn,y
	adc t1
	sta s9l+1
	lda qbsc,y
	adc #0
	sta s9l+2
	jsr .base
	cly
.by:
.la:	lda sbar,y
	tax
.sl:	lda SSH,x
	sta s9t
.ra:	lda sbar,y
	tax
.sr:	lda SSH + 256,x
	ora s9t
	sta $1A00
	iny
	cpy #16
	bne .nb
	lda s9l                 ; B: + 288
	clc
	adc #<288
	sta s9l
	lda s9l+1
	adc #>288
	sta s9l+1
	jsr .base
.nb:	cpy #32
	bne .by
	inc ssc
	lda ssc
	cmp #33
	beq .cn
	jmp .cc
.cn:	inc ssp
	lda ssp
	cmp #4
	beq .pn
	jmp .p
.pn:	inc ssr
	lda ssr
	cmp #16
	beq .z
	jmp .r
.z:	stz ssp                 ; lines -8 .. -1 and 128 .. 135 zero: A + 0, + 272, B + 288, + 560
.zp:	stz ssc
.zc:	ldx ssc
	ldy ssp
	lda q576x,x
	clc
	adc qbsx,y
	sta s9l
	lda q576y,x
	adc qbsn,y
	sta s9l+1
	lda qbsc,y
	adc #0
	sta s9l+2
	lda #4
	sta s9u
	clx
.zz:	lda s9l
	clc
	adc .zo,x
	sta $1A02
	lda s9l+1
	adc .zo+4,x
	sta $1A03
	lda s9l+2
	adc #0
	sta $1A04
	ldy #16
.z0:	stz $1A00
	dey
	bne .z0
	inx
	dec s9u
	bne .zz
	inc ssc
	lda ssc
	cmp #33
	bne .zc
	inc ssp
	lda ssp
	cmp #4
	bne .zp
	rts
.zo:	.db <0, <272, <288, <560, >0, >272, >288, >560
.base:	lda s9l
	sta $1A02
	lda s9l+1
	sta $1A03
	lda s9l+2
	sta $1A04
	rts
.tad:	pha                     ; STB + 32 A: A low, X high (STB's low byte 0)
	lsr a
	lsr a
	lsr a
	clc
	adc #>STB
	tax
	pla
	asl a
	asl a
	asl a
	asl a
	asl a
	rts

	.if PDD
SWTA       = $0B1800    ; the window table: 2 bytes at SWTA + 1122 (4 p + q) + 34 cc + 2 rr (column by column, rows rising)
SCNT       = $9000      ; DB_X at MPR4, set-up only: per id its windows (saturating), its first window's column, row
SREPC      = $9240
SREPR      = $9480
STMAP      = $9000      ; (first) per tile number (0-2047) its code
SDMAP      = $9000      ; (s6dict) per id of a phase its dictionary index + 1
SHB        = $9000      ; (first) per hash of a tile's 32 bytes: the cell + 1 whose tile is its first (512 x 2)
SCODE      = $9400      ; (first) per field cell (512): its tile's code
sta6:	.ds 32          ; a tile's bytes, another's
stb6:	.ds 32
s6t8:	.ds 612         ; the tile codes of the field with a border: 18 rows (-1 .. 16) x 34 columns (-1 .. 32)
sdsl:	.ds PDN         ; the dictionary's list (best first): count, phase, id, first window
sdsh:	.ds PDN
sdlp:	.ds PDN
sdil:	.ds PDN
sdih:	.ds PDN
sdcc:	.ds PDN
sdrr:	.ds PDN
sdn:	.db 0
sov:	.db 0
sk:	.db 0           ; the tile codes' count, the phase, its stamp, the window, its name, its hash, its id
swph6:	.db 0
spq:	.db 0
swc:	.db 0
swr:	.db 0
sna:	.db 0, 0, 0, 0
shl:	.db 0
shh:	.db 0
sidl:	.db 0
sidh:	.db 0
snid:	.db 0, 0
s6wt1:	lda #$90                ; the tile codes by CONTENT: SHB (512 buckets: a cell + 1 whose tile has that hash) zero
	sta .hz0+2
	ldx #4
.hc:	cly
	cla
.hz0:	sta $9000,y
	iny
	bne .hz0
	inc .hz0+2
	dex
	bne .hc
	stz sk
	stz sov
	clx                     ; the border: rows -1 and 16 $FE, columns -1 and 32 $FD
.b1:	lda #$FE
	sta s6t8,x
	sta s6t8 + 578,x
	inx
	cpx #34
	bne .b1
	ldx #16
.b2:	txa                     ; columns -1 and 32 of rows 0-15
	phx
	tax
	lda #34
	jsr smul8
	plx
	lda #<s6t8
	clc
	adc t0
	sta .b3+1
	sta .b4+1
	lda #>s6t8
	adc t1
	sta .b3+2
	sta .b4+2
	lda #$FD
	ldy #0
.b3:	sta $FFFF,y
	ldy #33
.b4:	sta $FFFF,y
	dex
	bne .b2
	stz swc                 ; cell n = 32 r + c (swc low, swr high: 0-511)
	stz swr
.n:	lda swc                 ; its tile into sta6, its hash (9 bits) in shl / shh
	ldy swr
	jsr strd
	stz shl
	stz shh
	clx
.hsh:	lda sta6,x
	clc
	adc shl
	rol a
	sta shl
	lda shh
	adc #0
	eor sta6+1,x
	sta shh
	inx
	inx
	cpx #32
	bne .hsh
	lda shh
	and #1
	sta shh
.pr:	lda shl                 ; bucket SHB + 2 h
	asl a
	sta .bl+1
	sta .bh+1
	sta .bw+1
	sta .bv+1
	lda shh
	rol a
	clc
	adc #>SHB
	sta .bl+2
	sta .bh+2
	sta .bw+2
	sta .bv+2
	inc .bh+1
	inc .bv+1
.bl:	lda SHB
.bh:	ora SHB+1
	beq .nw
	lda .bl+1               ; (the cell there: its tile against ours)
	sta .q1+1
	lda .bl+2
	sta .q1+2
	lda .bh+1
	sta .q2+1
	lda .bh+2
	sta .q2+2
.q1:	lda SHB
	sec
	sbc #1
	pha
.q2:	lda SHB+1
	sbc #0
	tay
	pla
	pha
	phy
	jsr strd2
	ldx #31
.cm:	lda sta6,x
	cmp stb6,x
	bne .ne
	dex
	bpl .cm
	ply                     ; equal: its code
	pla
	sta .cd+1
	tya
	clc
	adc #>SCODE
	sta .cd+2
.cd:	lda SCODE
	bra .wcd
.ne:	ply
	pla
	inc shl
	bne .pj
	lda shh
	eor #1
	sta shh
.pj:	jmp .pr
.nw:	lda swc                 ; new: the bucket holds n + 1, the code K
	clc
	adc #1
.bw:	sta SHB
	lda swr
	adc #0
.bv:	sta SHB+1
	lda sk
	cmp #$FD
	bcc .k1
	inc sov
	cla
	bra .wcd
.k1:	inc sk
.wcd:	pha                     ; SCODE[n] = A; s6t8 at row (n >> 5) + 1, column (n & 31) + 1
	lda swr
	clc
	adc #>SCODE
	sta .cw+2
	lda swc
	sta .cw+1
	pla
.cw:	sta SCODE
	pha
	lda swc                 ; row r = n >> 5
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	sta t2
	lda swr
	asl a
	asl a
	asl a
	ora t2
	inc a
	tax
	lda #34
	jsr smul8
	lda swc
	and #31
	inc a
	clc
	adc t0
	sta t0
	lda t1
	adc #0
	sta t1
	lda #<s6t8
	clc
	adc t0
	sta .tw+1
	lda #>s6t8
	adc t1
	sta .tw+2
	pla
.tw:	sta s6t8
	inc swc
	bne .nn
	inc swr
.nn:	lda swr
	cmp #2
	beq .nd
	jmp .n
.nd:
	lda #<SHT               ; the key table zero (port 2)
	sta $1A22
	lda #>SHT
	sta $1A23
	lda #(SHT >> 16)
	sta $1A24
	ldx #32
.hz:	cly
.hz2:	stz $1A20
	dey
	bne .hz2
	dex
	bne .hz
	stz sdn
	stz swph6
.ph:	lda swph6                 ; phase swph6 = 4 p + q: the table's part from SWTA + 1122 swph6 (port 0, written in order)
	inc a
	sta spq
	lda swph6
	ldx #<1122
	ldy #>1122
	jsr smul16              ; (t0 t1 = 1122 A)
	lda t0
	clc
	adc #<SWTA
	sta $1A02
	lda t1
	adc #>SWTA
	sta $1A03
	lda #(SWTA >> 16)
	sta $1A04
	stz snid
	stz snid+1
	clx                     ; the counts zero
.cz:	stz SCNT,x
	stz SCNT + $100,x
	stz SCNT + $140,x
	inx
	bne .cz
	stz swc
.wc:	stz swr
	lda swc                 ; P = s6t8 + cc (row 0's: rr = 0's top), stepping 34 a row
	clc
	adc #<s6t8
	sta .pa+1
	sta .pb+1
	sta .pc+1
	sta .pd+1
	lda #>s6t8
	adc #0
	sta .pa+2
	sta .pb+2
	sta .pc+2
	sta .pd+2
.wr:	lda swph6                 ; the name: a (p and q), b (q), c (p), d
	and #3
	sta t3                  ; q
	lda swph6
	lsr a
	lsr a
	sta t2                  ; p
	ldy #35
.pd:	lda s6t8,y
	sta sna+3
	lda #$FF
	ldx t2
	beq .nc
	ldy #34
.pc:	lda s6t8,y
.nc:	sta sna+2
	lda #$FF
	ldx t3
	beq .nb
	ldy #1
.pb:	lda s6t8,y
.nb:	sta sna+1
	lda #$FF
	ldx t2
	beq .na
	ldx t3
	beq .na
	ldy #0
.pa:	lda s6t8,y
.na:	sta sna
	lda sov
	beq .hs
	lda swc                 ; (more than 252 tiles: id = 17 cc + rr)
	ldx #17
	ldy #0
	jsr smul16
	lda t0
	clc
	adc swr
	sta sidl
	lda t1
	adc #0
	sta sidh
	bra .wid
.hs:	jsr slook               ; the id of the name (sidl, sidh; new: snid)
.wid:	lda sidl                ; into the table, counted
	sta $1A00
	lda sidh
	sta $1A00
	clc
	adc #>SCNT
	sta .ci+2
	sta .co+2
	lda sidl
	sta .ci+1
	sta .co+1
.ci:	lda SCNT
	inc a
	beq .sat
.co:	sta SCNT
.sat:	lda swr                 ; next row: P += 34
	inc a
	cmp #17
	beq .wn
	sta swr
	lda .pa+1
	clc
	adc #34
	sta .pa+1
	sta .pb+1
	sta .pc+1
	sta .pd+1
	bcc .wr2
	inc .pa+2
	inc .pb+2
	inc .pc+2
	inc .pd+2
.wr2:	jmp .wr
.wn:	inc swc
	lda swc
	cmp #33
	beq .pm
	jmp .wc
.pm:	.if PDN > 0
	lda sov                 ; the phase's names into the dictionary's list
	bne .pn
	jsr smerge
	.endif
.pn:	inc swph6
	lda swph6
	cmp #16
	beq .lw
	jmp .ph
.lw:	jmp sdlwr
.w:	sta $FFFF,y
	rts
; strd: cell (A low, Y high: 0-511) its tile into sta6; strd2: into stb6 (ssr / ssc, t0-t2 used)
strd:	ldx #<sta6
	stx strdt+3
	ldx #>sta6
	bra strdx
strd2:	ldx #<stb6
	stx strdt+3
	ldx #>stb6
strdx:	stx strdt+4
	pha
	and #31
	sta ssc
	pla
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	sta ssr
	tya
	asl a
	asl a
	asl a
	ora ssr
	sta ssr
	jsr stadr
	jsr vmarr
strdt:	tai $0002, sta6, 32
	rts
; t0 t1 = A * X (8 x 8 bits)
smul8:	stz t0
	stz t1
	stx t2
	ldx #8
.ml:	asl t0
	rol t1
	asl a
	bcc .mn
	pha
	lda t0
	clc
	adc t2
	sta t0
	bcc .mm
	inc t1
.mm:	pla
.mn:	dex
	bne .ml
	rts
; t0 t1 = A * (Y:X) (A 8 bits, result 16)
smul16:	stx t2
	sty t3
	stz t0
	stz t1
	tay
.ma:	cpy #0
	beq .mx
	lda t0
	clc
	adc t2
	sta t0
	lda t1
	adc t3
	sta t1
	dey
	bra .ma
.mx:	rts
; the name sna -> its id: the key table (port 2) by a hash of the name, probed on
slook:	lda sna+3               ; h = (d << 2) ^ c ^ (b << 1) ^ (a << 3), 10 bits
	stz shh
	asl a
	rol shh
	asl a
	rol shh
	eor sna+2
	sta shl
	lda sna+1
	asl a
	php
	eor shl
	sta shl
	plp
	cla
	rol a
	eor shh
	sta shh
	lda sna
	stz t0
	asl a
	rol t0
	asl a
	rol t0
	asl a
	rol t0
	eor shl
	sta shl
	lda t0
	eor shh
	and #3
	sta shh
.pr:	lda shl                 ; the entry: SHT + 8 h
	asl a
	asl a
	asl a
	sta $1A22
	sta t0
	lda shh
	asl a
	asl a
	asl a
	sta t1
	lda shl
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	ora t1
	clc
	adc #>SHT
	sta $1A23
	sta t1
	lda #(SHT >> 16)
	sta $1A24
	lda $1A20               ; stamp
	cmp spq
	bne .new
	lda $1A20
	cmp sna
	bne .nx
	lda $1A20
	cmp sna+1
	bne .nx
	lda $1A20
	cmp sna+2
	bne .nx
	lda $1A20
	cmp sna+3
	bne .nx
	lda $1A20
	sta sidl
	lda $1A20
	sta sidh
	rts
.nx:	inc shl
	bne .pr
	lda shh
	inc a
	and #3
	sta shh
	bra .pr
.new:	lda t0                  ; a new name: its entry, its id, its first window
	sta $1A22
	lda t1
	sta $1A23
	lda spq
	sta $1A20
	lda sna
	sta $1A20
	lda sna+1
	sta $1A20
	lda sna+2
	sta $1A20
	lda sna+3
	sta $1A20
	lda snid
	sta sidl
	sta $1A20
	lda snid+1
	sta sidh
	sta $1A20
	clc
	adc #>SREPC
	sta .rc+2
	lda snid+1
	adc #>SREPR
	sta .rr+2
	lda snid
	sta .rc+1
	sta .rr+1
	lda swc
.rc:	sta SREPC
	lda swr
.rr:	sta SREPR
	inc snid
	bne .nw
	inc snid+1
.nw:	rts
; the phase's ids into the list (best first, at most PDN): an id goes in when the list is not full or it beats the last
	.if PDN > 0
smerge:	stz sidl
	stz sidh
.mg:	lda sidl
	cmp snid
	lda sidh
	sbc snid+1
	bcc .mg1
	rts
.mg1:	lda sidh
	clc
	adc #>SCNT
	sta .mc+2
	lda sidl
	sta .mc+1
.mc:	lda SCNT
	sta t0                  ; its count
	ldx sdn
	cpx #PDN
	bcc .mi                 ; (not full: in)
	lda t0
	cmp sdsl + PDN - 1
	bcc .mnx
	beq .mnx
	dec sdn                 ; (full: the last goes)
	ldx sdn
.mi:	cpx #0                  ; the place: after every entry with a count >= this one's
	beq .mp
	lda sdsl - 1,x
	cmp t0
	bcs .mp
	lda sdsl - 1,x          ; one down
	sta sdsl,x
	lda sdlp - 1,x
	sta sdlp,x
	lda sdil - 1,x
	sta sdil,x
	lda sdih - 1,x
	sta sdih,x
	lda sdcc - 1,x
	sta sdcc,x
	lda sdrr - 1,x
	sta sdrr,x
	dex
	bra .mi
.mp:	lda t0
	sta sdsl,x
	lda swph6
	sta sdlp,x
	lda sidl
	sta sdil,x
	lda sidh
	sta sdih,x
	clc
	adc #>SREPC
	sta .m1+2
	lda sidh
	adc #>SREPR
	sta .m2+2
	lda sidl
	sta .m1+1
	sta .m2+1
.m1:	lda SREPC
	sta sdcc,x
.m2:	lda SREPR
	sta sdrr,x
	inc sdn
.mnx:	inc sidl
	bne .mj
	inc sidh
.mj:	jmp .mg
	.endif
sdlwr:	jsr sdla
	lda sdn
	sta $1A00
	.if PDN > 0
	tia sdlp, $1A00, PDN
	tia sdil, $1A00, PDN
	tia sdih, $1A00, PDN
	tia sdcc, $1A00, PDN
	tia sdrr, $1A00, PDN
	.endif
	rts
sdlrd:	jsr sdla
	lda $1A00
	sta sdn
	.if PDN > 0
	tai $1A00, sdlp, PDN
	tai $1A00, sdil, PDN
	tai $1A00, sdih, PDN
	tai $1A00, sdcc, PDN
	tai $1A00, sdrr, PDN
	.endif
	rts
sdla:	lda #<SDLA
	sta $1A02
	lda #>SDLA
	sta $1A03
	lda #(SDLA >> 16)
	sta $1A04
	rts
; s6dict (entry 9, after the pool): the table's dictionary windows get their slot's word (when the table was made this set-up: the list's
; entries of each phase mapped id -> index in SDMAP, the phase's 561 entries read through port 3 and the hits written through port 0); then
; the dictionary's tiles into its slots
s6dict:	tma #4
	pha
	lda #DB_X
	tam #4
	lda scached
	beq .mk
	jmp .up
.mk:	lda #$FF                ; SDMAP all none
	clx
.z:	sta SDMAP,x
	sta SDMAP + $100,x
	sta SDMAP + $140,x
	inx
	bne .z
	stz swph6
.p:	lda #0                  ; this phase's entries in (index), patched, out again
	jsr .set
	lda swph6
	ldx #<1122
	ldy #>1122
	jsr smul16
	lda t0
	clc
	adc #<SWTA
	sta t0
	sta $1A32
	lda t1
	adc #>SWTA
	sta t1
	sta $1A33
	lda #(SWTA >> 16)
	sta $1A34
	sta $1A04
	lda #<561
	sta swc
	lda #>561
	sta swr
.e:	lda $1A30
	ldy $1A30
	cpy #4
	bcs .en                 ; (a word already)
	sta .mp+1
	tya
	clc
	adc #>SDMAP
	sta .mp+2
.mp:	ldx SDMAP
	cpx #$FF
	beq .en
	lda t0                  ; this entry: its slot's word
	sta $1A02
	lda t1
	sta $1A03
	lda SPWL,x
	sta $1A00
	lda SPWH,x
	sta $1A00
.en:	lda t0
	clc
	adc #2
	sta t0
	bcc .e1
	inc t1
.e1:	lda swc
	bne .e2
	dec swr
.e2:	dec swc
	lda swc
	ora swr
	bne .e
	lda #$FF
	jsr .set
	inc swph6
	lda swph6
	cmp #16
	beq .up
	jmp .p
.up:	jsr sdupl
	pla
	tam #4
	rts
.set:	sta t2                  ; SDMAP[id] = index (A 0) or none (A $FF) for the list's entries of phase swph6
	ldx sdn
.s1:	dex
	bmi .s2
	lda sdlp,x
	cmp swph6
	bne .s1
	lda sdih,x
	clc
	adc #>SDMAP
	sta .sw+2
	lda sdil,x
	sta .sw+1
	lda t2
	bne .sw
	txa
.sw:	sta SDMAP
	bra .s1
.s2:	rts
; s6dup (entry 12, reeng): the dictionary's tiles again
s6dup:	tma #4
	pha
	lda #DB_X
	tam #4
	jsr sdupl
	pla
	tam #4
	rts
; the dictionary's tiles: entry i's window from the streams into slot i (port 0's mapped bank $40 at MPR3, straight into the VDC)
sdupl:	tma #3
	pha
	lda #$40
	tam #3
	clx
.u:	cpx sdn
	bne .u1
	jmp .x
.u1:
	lda sdlp,x              ; A = SSTR(p) + 576 cc + 16 rr + 16 - 4 q
	and #3
	asl a
	asl a
	eor #$FF
	sec
	adc #16
	sta t0
	ldy sdcc,x
	lda q576x,y
	clc
	adc t0
	sta t0
	lda q576y,y
	adc #0
	sta t1
	lda sdrr,x
	asl a
	asl a
	asl a
	asl a
	php
	clc
	adc t0
	sta t0
	lda t1
	adc #0
	plp
	adc #0
	sta t1
	lda sdlp,x
	lsr a
	lsr a
	tay
	lda t0
	clc
	adc qbsx,y
	sta t0
	sta $1A02
	lda t1
	adc qbsn,y
	sta t1
	sta $1A03
	lda qbsc,y
	adc #0
	sta $1A04
	vsel 0
	lda SPSL,x
	sta $0002
	lda SPSH,x
	sta $0003
	vsel 2
	tia $6000, $0002, 16
	lda t0
	clc
	adc #<288
	sta $1A02
	lda t1
	adc #>288
	sta $1A03
	tia $6000, $0002, 16
	inx
	jmp .u
.x:	pla
	tam #3
	rts
	.endif

	.if OCK & (WAL = 0)
OCKA       = $04A000
SM1        = $9000      ; DB_X at MPR4, set-up only: M_c (17 rows x 33), c = 1, 2, 3
SM2        = $9240
SM3        = $9740
sonb:	.ds 16          ; the band's list (block per place), its costs, the order
soncu:	.ds 16
sm:	.db 0           ; class, cy, cx, band
scy:	.db 0
scx:	.db 0
sbd:	.db 0
sns:	.db 0
su8:	.db 0
smc:	.db >SM1, >SM2, >SM3
smcl:	.db <SM1, <SM2, <SM3
s6ock:	lda scached             ; made again only when something under it was
	and kcached
	and ocached
	beq .go
	rts
.go:	tma #4
	pha
	tma #3
	pha
	lda #DB_X
	tam #4
	lda #DB_NEAR
	tam #3
	jsr smbld               ; M_c from the window table
	lda #<OCKA              ; port 2: the new lists, written in order
	sta $1A22
	lda #>OCKA
	sta $1A23
	lda #(OCKA >> 16)
	sta $1A24
	lda #1
	sta sm
.c:	stz scy
.y:	stz scx
.x:	lda sm
	tax
	lda smcm,x
	clc
	adc scx
	sta t4                  ; m = 33 c + cx
	asl a
	sta t5
	cla
	rol a
	sta t6
	lda scy
	asl a
	asl a
	asl a
	sta $1A02
	cla
	rol a
	ora t5
	clc
	adc #$20
	sta $1A03
	lda t6
	adc #OLST
	sta $1A04
	lda t4
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc scy
	sta $1A32
	lda t4
	lsr a
	lsr a
	clc
	adc #$30
	sta $1A33
	lda #ONS
	sta $1A34
	stz sbd
.b:	ldx #0                  ; the list's 16 nibbles (block of place i)
.r:	lda $1A00
	pha
	and #$0F
	sta sonb,x
	pla
	lsr a
	lsr a
	lsr a
	lsr a
	sta sonb+1,x
	inx
	inx
	cpx #16
	bne .r
	ldx #8
.r2:	lda $1A00               ; (the next world row's list: skipped)
	dex
	bne .r2
	lda $1A30
	sta sns
	lda $1A30
	lda sns
	cmp #2
	bcc .w                  ; (fewer than 2 to sort)
	jsr .rows               ; the band's near and M rows
	clx                     ; the costs
.u:	lda sonb,x
	jsr .cost
	sta soncu,x
	inx
	cpx sns
	bne .u
	ldx #1                  ; stable insertion sort of places 0 .. ns - 1 by cost
.s:	lda soncu,x
	sta su8
	lda sonb,x
	pha
	txa
	tay
.s1:	cpy #0
	beq .s2
	lda soncu - 1,y
	cmp su8
	bcc .s2
	beq .s2
	sta soncu,y
	lda sonb - 1,y
	sta sonb,y
	dey
	bra .s1
.s2:	lda su8
	sta soncu,y
	pla
	sta sonb,y
	inx
	cpx sns
	bne .s
.w:	ldx #0                  ; the band's 8 bytes (port 2)
.w1:	lda sonb+1,x
	asl a
	asl a
	asl a
	asl a
	ora sonb,x
	sta $1A20
	inx
	inx
	cpx #16
	bne .w1
	inc sbd
	lda sbd
	cmp #8
	beq .nx
	jmp .b
.nx:	inc scx
	lda scx
	cmp #33
	beq .ny
	jmp .x
.ny:	inc scy
	lda scy
	cmp #49
	beq .nc
	jmp .y
.nc:	inc sm
	lda sm
	cmp #4
	beq .dn
	jmp .c
.dn:	pla
	tam #3
	pla
	tam #4
	rts
.rows:	lda sbd
	asl a
	clc
	adc scy                 ; wy
	sta t0
	stz t1
	lsr t1                  ; (64 wy: wy << 6)
	lsr a
	ror t1
	lsr a
	ror t1
	clc
	adc #$60
	sta t2                  ; high
	lda t1
	clc
	adc scx
	sta .n0+1
	lda t2
	adc #0
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
	ldx sm                  ; M_c + 33 (2 b)
	lda sbd
	asl a
	tay
	lda #33
	phx
	tax
	tya
	jsr smul8
	plx
	lda smcl - 1,x
	clc
	adc t0
	sta .m0+1
	lda smc - 1,x
	adc t1
	sta .m0+2
	lda .m0+1
	clc
	adc #33
	sta .m1+1
	lda .m0+2
	adc #0
	sta .m1+2
	lda .m1+1
	clc
	adc #33
	sta .m2+1
	lda .m1+2
	adc #0
	sta .m2+2
	rts
; the cost of block A (X kept): over its columns 2 k .. 2 k + 1 (+ 1 off the grid in X) and rows 0-1 (+ 2 off it in Y)
.cost:	phx
	asl a
	tay
	stz su8
	jsr .cc
	iny
	jsr .cc
	lda sm
	lsr a
	bcc .c9
	iny
	jsr .cc
.c9:	lda su8
	plx
	rts
.cc:
.n0:	ldx $6000,y
	lda SPV,x
	cmp #1
	bne .c1
.m0:	lda SM1,y
	clc
	adc su8
	sta su8
.c1:
.n1:	ldx $6000,y
	lda SPV,x
	cmp #1
	bne .c2
.m1:	lda SM1,y
	clc
	adc su8
	sta su8
.c2:	lda sm
	and #2
	beq .c3
.n2:	ldx $6000,y
	lda SPV,x
	cmp #1
	bne .c3
.m2:	lda SM1,y
	clc
	adc su8
	sta su8
.c3:	rts
smcm:	.db 0, 33, 66, 99
; M_c (c 1-3): zero, then per phase of class c, per window that is not a dictionary word (the table's high byte < $10), + 1
smbld:	clx
	cla
.z:	sta $9000,x
	sta $9100,x
	sta $9200,x
	sta $9300,x
	sta $9400,x
	sta $9800,x
	sta $9900,x
	cpx #$C0
	bcs .z1
	sta $9740,x
.z1:	inx
	bne .z
	lda #<SWTA              ; the table in order (port 3)
	sta $1A32
	lda #>SWTA
	sta $1A33
	lda #(SWTA >> 16)
	sta $1A34
	stz swph6
.p:
	lda swph6
	and #$0C
	cmp #1
	cla
	rol a
	sta t0                  ; p > 0
	lda swph6
	and #3
	cmp #1
	cla
	rol a
	asl a
	ora t0
	sta t3                  ; c
	stz swc
.wc:	lda t3                  ; M row pointer: M_c + cc
	beq .sk
	tax
	lda smcl - 1,x
	clc
	adc swc
	sta .mi+1
	sta .mo+1
	lda smc - 1,x
	adc #0
	sta .mi+2
	sta .mo+2
.sk:	stz swr
.wr:	lda $1A30
	ldy $1A30
	ldx t3
	beq .nn
	cpy #$10
	bcs .nn
.mi:	lda SM1
	inc a
.mo:	sta SM1
.nn:	lda .mi+1               ; next row: + 33
	clc
	adc #33
	sta .mi+1
	sta .mo+1
	bcc .n1
	inc .mi+2
	inc .mo+2
.n1:	inc swr
	lda swr
	cmp #17
	bne .wr
	inc swc
	lda swc
	cmp #33
	bne .wc
	inc swph6
	lda swph6
	cmp #16
	beq .pe
	jmp .p
.pe:	rts
	.endif
	.if WAL
ocw:	.ds 256
occ:	.ds 256
okw:	.ds 64
oks:	.ds 64
okb:	.ds 64
oml:	.ds 32
omh:	.ds 32
olb:	.ds 8
otb:	.ds 32
oc:	.db 0
owy:	.db 0
ocx:	.db 0
om:	.db 0
onp:	.db 0
ons:	.db 0
oa:	.db 0
oy0:	.db 0
oy1:	.db 0
ob:	.db 0
wsign:	.db 0
wkey:	.db $19, $8C, 1, 0, 0
wbuild:	tma #3
	pha
	lda #DB_NEAR
	tam #3
	clx                     ; ocw / occ per near byte value (same semantics as obuild for s6str SPV)
.v:	txa
	and #$7F
	tay
	lda prop,y
	bpl .nc
	lda #1
	sta occ,x
	tya
	beq .ho
	lda #16                 ; staircase cell (see-through)
	bra .st
.ho:	lda #1                  ; hole / plug cell
	bra .st
.nc:	stz occ,x
	jsr .see
.st:	sta ocw,x
	inx
	bne .v
	stz wkey+3
	stz wkey+4
	clx
.k1:	lda ocw,x
	jsr .add
	lda occ,x
	jsr .add
	inx
	bne .k1
	lda #$60
	sta .kr+2
	cly
.kr:	lda $6000,y
	jsr .add
	iny
	bne .kr
	inc .kr+2
	lda .kr+2
	cmp #$71
	bne .kr
	stz $1A02
	lda #$70
	sta $1A03
	lda #$06
	sta $1A04
	clx
.kc:	lda $1A00
	cmp wkey,x
	bne .bd
	inx
	cpx #5
	bne .kc
	lda #1
	sta ocached
	jmp .x
.bd:	stz ocached
	inc nobuild
	stz oc
.cl:	lda oc
	and #1
	inc a
	inc a
	sta oy1                 ; column width: 2 + dx
	lda oc
	lsr a
	and #1
	clc
	adc #8
	sta ob                  ; row height: 8 + dy
	clx
.z:	stz okw,x
	stz oks,x
	stz okb,x
	inx
	cpx #64
	bne .z
	stz wsign               ; owy = 0: accumulate rows 0 .. ob-1
	stz owy
	stz oy0
.r0:	lda oy0
	jsr .addrow
	inc oy0
	lda oy0
	cmp ob
	bne .r0
	bra .do_cx
.rw:	lda #$FF                ; owy >= 1: subtract row owy-1, add row owy + ob - 1
	sta wsign
	lda owy
	dec a
	jsr .addrow
	stz wsign
	lda owy
	clc
	adc ob
	dec a
	jsr .addrow
.do_cx:	stz ocx
.cx:	jsr .wlist
	inc ocx
	lda ocx
	cmp #33
	bne .cx
	inc owy
	lda owy
	cmp #58
	bne .rw
	inc oc
	lda oc
	cmp #4
	beq .done
	jmp .cl
.done:	stz $1A02
	lda #$70
	sta $1A03
	lda #$06
	sta $1A04
	tia wkey, $1A00, 5
.x:	pla
	tam #3
	rts
.add:	clc
	adc wkey+3
	sta wkey+3
	clc
	adc wkey+4
	sta wkey+4
	rts
.see:	phx
	lda KSWL,x
	sta t0
	lda KSWH,x
	and #7
	asl t0
	rol a
	asl t0
	rol a
	asl t0
	rol a
	asl t0
	rol a
	tax
	lda t0
	jsr vmarr
	tai $0002, otb, 8
	tai $0002, otb + 8, 8
	tai $0002, otb + 16, 8
	tai $0002, otb + 24, 8
	ldx #14
.sr:	lda otb,x
	ora otb+1,x
	ora otb+16,x
	ora otb+17,x
	cmp #$FF
	bne .sy
	dex
	dex
	bpl .sr
	plx
	cla
	rts
.sy:	plx
	lda #16
	rts
.addrow:	sta t0
	lsr a
	lsr a
	clc
	adc #$60
	sta t1                  ; base hi
	lda t0
	and #3
	lsr a
	ror a
	ror a
	sta t2                  ; base lo
	stz oa
.ca:	lda t2
	clc
	adc oa
	sta .ra+1
	lda t1
	adc #0
	sta .ra+2
	clx
	lda t0
	cmp #64
	bcs .ce_nocc            ; row >= 64 has no backdrop class bits
	lda wsign
	bne .sub_occ
.add_ce:
.ra:	ldy $6000,x
	lda ocw,y
	beq .ac
	cmp #1
	bne .as
	inc okw,x
	bra .ac
.as:	inc oks,x
.ac:	lda occ,y
	beq .an
	inc okb,x
.an:	inx
	cpx #63
	bne .add_ce
	bra .ca_nxt
.sub_occ:
	lda .ra+1
	sta .rs+1
	lda .ra+2
	sta .rs+2
.sub_ce:
.rs:	ldy $6000,x
	lda ocw,y
	beq .sc
	cmp #1
	bne .ss
	dec okw,x
	bra .sc
.ss:	dec oks,x
.sc:	lda occ,y
	beq .sn
	dec okb,x
.sn:	inx
	cpx #63
	bne .sub_ce
.ca_nxt:
	inc oa
	lda oa
	cmp oy1
	bne .ca
	rts
.ce_nocc:
	lda .ra+1
	sta .rn1+1
	lda .ra+2
	sta .rn1+2
	lda wsign
	bne .sn_lp
.an_lp:
.rn1:	ldy $6000,x
	lda ocw,y
	beq .ann
	cmp #1
	bne .ans
	inc okw,x
	bra .ann
.ans:	inc oks,x
.ann:	inx
	cpx #63
	bne .an_lp
	bra .ca_nxt
.sn_lp:
	lda .rn1+1
	sta .rn2+1
	lda .rn1+2
	sta .rn2+2
.sn2:
.rn2:	ldy $6000,x
	lda ocw,y
	beq .snn
	cmp #1
	bne .sns
	dec okw,x
	bra .snn
.sns:	dec oks,x
.snn:	inx
	cpx #63
	bne .sn2
	bra .ca_nxt
.wlist:	ldx #28
.zc:	stz oml,x
	stz omh,x
	dex
	bpl .zc
	ldx #7
.zo:	stz olb,x
	dex
	bpl .zo
	stz onp
	stz ons
	clx
	ldy ocx
.col_lp:
	lda okb,y
	ora oks,y
	beq .skip               ; 100% opaque BG -> omit wall piece!
	lda oks,y
	beq .plug
	lda #28                 ; see-through bucket
	bra .bkt
.plug:	lda okw,y
.bkt:	sta t0
	txa
	cmp #8
	bcs .hi
	lda .bit,x
	ldx t0
	ora oml,x
	sta oml,x
	bra .nx
.hi:	and #7
	tax
	lda .bit,x
	ldx t0
	ora omh,x
	sta omh,x
.nx:	txa                     ; restore col? no, recompute from Y: col = (Y - ocx) >> 1
	tya
	sec
	sbc ocx
	lsr a
	tax
.skip:	iny
	iny
	inx
	cpx #16
	bne .col_lp
	; emit bucket 28 (see-through) first
	lda oml+28
	beq .s_hi
	ldy #0
	jsr .em8
.s_hi:	lda omh+28
	beq .s_dn
	ldy #8
	jsr .em8
.s_dn:	lda onp
	sta ons
	; emit buckets 27 down to 0 (most-plug -> fewest-plug last)
	ldx #27
.bk:	lda oml,x
	beq .bh
	ldy #0
	jsr .em8
.bh:	lda omh,x
	beq .bn
	ldy #8
	jsr .em8
.bn:	dex
	bpl .bk
	lda ocx
	ldx oc
	clc
	adc q5m,x
	sta om
	lda owy
	asl a
	asl a
	asl a
	sta $1A02
	lda owy
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	sta t0                  ; owy >> 5
	stz t2
	lda om
	asl a
	rol t2                  ; C = om >> 7
	ora t0
	sta $1A03
	lda #$04
	clc
	adc t2
	sta $1A04
	tia olb, $1A00, 8
	lda om
	lsr a
	sta $1A03
	cla
	ror a                   ; (om & 1) << 7
	sta t0
	lda owy
	asl a
	ora t0
	sta $1A02
	lda #$06
	sta $1A04
	lda onp
	sta $1A00
	lda ons
	sta $1A00
	rts
.bit:	.db $01, $02, $04, $08, $10, $20, $40, $80
; emit set bits of A starting at col offset Y (0 or 8), preserving X
.em8:	phx
	sty t3
	sta t4
	ldx #0
.e8l:	lsr t4
	bcc .e8n
	txa
	clc
	adc t3
	sta t6
	lda onp
	lsr a
	tay
	bcs .e8h
	lda t6
	sta olb,y
	bra .e8i
.e8h:	lda t6
	asl a
	asl a
	asl a
	asl a
	ora olb,y
	sta olb,y
.e8i:	inc onp
.e8n:	inx
	cpx #8
	bne .e8l
	plx
	rts
	.endif
	.if WAL = 0
	.if ORD
; ---------------------------------------------------------------- the set-up's end (ORD): the orders (interrupts on, in the dark; MPR3
ocw:	.ds 256         ; per near byte value: 1 a plug cell (backdrop class, code 0), 16 a see-through cell (summed: P + 16 T)
occ:	.ds 256         ; per near byte value: 1 backdrop class
okw:	.ds 72          ; this row's footprint sums (P + 16 T), class bits; then the keys (P, + 16 see-through; 31 not listed)
okc:	.ds 72
oml:	.ds 32          ; per key: its blocks 0-7 / 8-15
omh:	.ds 32
olb:	.ds 8           ; the list
otb:	.ds 32          ; a tile
oc:	.db 0           ; class, world row, camera column, m, the list's nibble count, ns
owy:	.db 0
ocx:	.db 0
om:	.db 0
onp:	.db 0
ons:	.db 0
ob:	.db 0
oa:	.db 0
oy0:	.db 0
oy1:	.db 0
okey:	.db $19, $0E, OVER, 0, 0
obuild:	tma #3
	pha
	lda #DB_NEAR
	tam #3
	clx                     ; ocw / occ per byte value (its low seven bits)
.v:	txa
	and #$7F
	tay
	lda prop,y
	bpl .nc
	lda #1
	sta occ,x
	tya
	beq .ho
	lda #16                 ; a staircase cell: the map's tile word (see-through)
	bra .st
.ho:	lda #1                  ; the hole: the transparent word (a plug cell)
	bra .st
.nc:	stz occ,x
	jsr .see
.st:	sta ocw,x
	inx
	bne .v
	stz okey+3              ; the key: the two tables, the near map's copy, OVER
	stz okey+4
	clx
.k1:	lda ocw,x
	jsr .add
	lda occ,x
	jsr .add
	inx
	bne .k1
	lda #$60
	sta .kr+2
	cly
.kr:	lda $6000,y
	jsr .add
	iny
	bne .kr
	inc .kr+2
	lda .kr+2
	cmp #$71
	bne .kr
	stz $1A02
	lda #$60
	sta $1A03
	lda #ONS
	sta $1A04
	clx
.kc:	lda $1A00
	cmp okey,x
	bne .bd
	inx
	cpx #5
	bne .kc
	lda #1
	sta ocached
	jmp .x
.bd:	stz ocached
	inc nobuild
	stz oc
.cl:	stz owy
.rw:	jsr .row                ; okw / okc: the keys of this world row's footprints
	stz ocx
.cx:	jsr .list
	inc ocx
	lda ocx
	cmp #33
	bne .cx
	inc owy
	lda owy
	cmp #64
	bne .rw
	inc oc
	lda oc
	cmp #4
	bne .cl
	stz $1A02               ; the key, last
	lda #$60
	sta $1A03
	lda #ONS
	sta $1A04
	tia okey, $1A00, 5
.x:	pla
	tam #3
	rts
.add:	clc                     ; okey+3 += A, okey+4 += okey+3
	adc okey+3
	sta okey+3
	clc
	adc okey+4
	sta okey+4
	rts
; a near byte value X that is not of the backdrop class: 16 when its tile (its S word's) has a pixel of colour 0, else 0. X kept.
.see:	phx
	lda KSWL,x
	sta t0
	lda KSWH,x
	and #7
	asl t0
	rol a
	asl t0
	rol a
	asl t0
	rol a
	asl t0
	rol a
	tax
	lda t0
	jsr vmarr
	tai $0002, otb, 8
	tai $0002, otb + 8, 8
	tai $0002, otb + 16, 8
	tai $0002, otb + 24, 8
	ldx #14
.sr:	lda otb,x
	ora otb+1,x
	ora otb+16,x
	ora otb+17,x
	cmp #$FF
	bne .sy
	dex
	dex
	bpl .sr
	plx
	cla
	rts
.sy:	plx
	lda #16
	rts
; this world row's footprint keys: okw[wx] = the sum of ocw over the footprint at (owy, wx) (rows owy .. owy + 1 + dy, columns wx ..
; wx + 1 + dx, the map's linear order: a column past 63 is the next row's), okc[wx] its class bits (rows from 64 on: none, as the
; nibble map's); then okw = okc ? P + 16 (a see-through cell) : 31
.row:	clx
.z:	stz okw,x
	stz okc,x
	inx
	cpx #72
	bne .z
	lda oc
	lsr a
	cla
	rol a
	inc a
	inc a
	sta oy1                 ; columns: 2 + dx
	lda oc
	lsr a
	inc a
	inc a
	sta ob                  ; rows: 2 + dy
	lda owy
	sta oy0                 ; the row
.rr:	lda oy0
	lsr a
	lsr a
	clc
	adc #$60
	sta .ra+2
	lda oy0
	and #3
	lsr a
	ror a
	ror a
	sta .ra+1
	stz oa
.ca:	lda #<okw               ; okw - a / okc - a, indexed by wx + a
	sec
	sbc oa
	sta .w1+1
	sta .w2+1
	lda #>okw
	sbc #0
	sta .w1+2
	sta .w2+2
	lda #<okc
	sec
	sbc oa
	sta .c1+1
	sta .c2+1
	lda #>okc
	sbc #0
	sta .c1+2
	sta .c2+2
	ldy oa
.ce:
.ra:	ldx $6000,y
	lda ocw,x
	clc
.w1:	adc okw,y
.w2:	sta okw,y
	lda oy0
	cmp #64
	bcs .cn
	lda occ,x
.c1:	ora okc,y
.c2:	sta okc,y
.cn:	iny
	tya
	sec
	sbc oa
	cmp #64
	bne .ce
	inc oa
	lda oa
	cmp oy1
	bne .ca
	inc oy0
	dec ob
	beq .rk
	jmp .rr
.rk:
	clx                     ; the keys
.ky:	lda okc,x
	beq .kn
	lda okw,x
	cmp #16
	bcc .kp
	and #$0F
	ora #16
.kp:	sta okw,x
	bra .kx
.kn:	lda #31                 ; (not listed: a key no scan reads, its masks cleared with the list)
	sta okw,x
.kx:	inx
	cpx #64
	bne .ky
	rts
; the list of camera column ocx at this class and world row: the listed blocks by their key, in each key the lowest index first
.list:	ldy ocx
	klin 0, oml, 1
	klin 2, oml, 2
	klin 4, oml, 4
	klin 6, oml, 8
	klin 8, oml, 16
	klin 10, oml, 32
	klin 12, oml, 64
	klin 14, oml, 128
	klin 16, omh, 1
	klin 18, omh, 2
	klin 20, omh, 4
	klin 22, omh, 8
	klin 24, omh, 16
	klin 26, omh, 32
	klin 28, omh, 64
	klin 30, omh, 128
	stz oml+31
	stz omh+31
	stz onp
	stz ons
	stz olb
	stz olb+1
	stz olb+2
	stz olb+3
	stz olb+4
	stz olb+5
	stz olb+6
	stz olb+7
	clx
.lk:	lda oml,x               ; keys 0-9, then 16-25
	beq .lh
	stz oml,x
	ldy #0
	jsr .em
.lh:	lda omh,x
	beq .ln
	stz omh,x
	ldy #8
	jsr .em
.ln:	inx
	cpx #10
	bne .l2
	lda onp
	sta ons
	ldx #16
.l2:	cpx #26
	bne .lk
	lda ocx                 ; m = 33 c + cx
	ldx oc
	clc
	adc q5m,x
	sta om
	lda owy
	asl a
	asl a
	asl a
	sta $1A02
	cla
	rol a
	sta t0
	lda om
	asl a
	sta t1
	cla
	rol a
	sta t2
	lda t1
	clc
	adc #$20
	ora t0
	sta $1A03
	lda t2
	adc #OLST
	sta $1A04
	tia olb, $1A00, 8
	lda om
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc owy
	sta $1A02
	lda om
	lsr a
	lsr a
	clc
	adc #$30
	sta $1A03
	lda #ONS
	sta $1A04
	lda ons
	sta $1A00
	rts
; the blocks of mask A (Y: 0 the band's blocks 0-7, 8 blocks 8-15) appended to the list, lowest first. X kept.
.em:	sty t3
.e1:	sta t4
	tay
	lda klsb,y
	sta t5
	eor t4
	sta t4
	ldy t5
	dey
	lda kpop,y              ; the bit's index
	clc
	adc t3
	sta t6
	lda onp
	lsr a
	tay
	bcs .eh
	lda t6
	sta olb,y
	bra .en
.eh:	lda t6
	asl a
	asl a
	asl a
	asl a
	ora olb,y
	sta olb,y
.en:	inc onp
	lda t4
	bne .e1
	rts
	.endif
	.endif
	.endif
