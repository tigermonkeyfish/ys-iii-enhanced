
CR3H       = $15
TPLM       = $01
LBM        = $48
IMGM       = $D0
KTH        = $17        ; key table $17:0000 (3 x 11,844 bytes), rank table $17:A000 (2 bytes a record)
RTM        = $A0
NPER       = 17
CN0        = 80
NFKEYS     = 42 * 192
KTN        = NFKEYS + 42 * 90

c7jt:	.dw kidle               ; 0, 2: (cidle, every idle of the band until it is ready) the store built or found, in slices on the clock
	.dw kidle

KSTOP      = 106
kco:	.db 0           ; a build is under way (its frame in ksv)
ksp:	.db 0
kn:	.db 0
ksv:	.ds 16
km4:	.db 0
kmr4:	.db 0
kra:	.db 0
krx:	.db 0
kry:	.db 0
kvb:	.db 0
kvf:	.db 0
kt9:	.db 0
khb:	.ds 16          ; the store's header read or written
ks:	.dw 0           ; its sum
kpg:	.dw 0
KHM:	.db 'Y', '3', 'C', 3, 2, <CBKEY, >CBKEY

kerr:	.db 0
kgen:	.db 0
knimg:	.dw 0
kbp:	.db 0           ; period, row, cell, cn, cm, cn & 1
kbr:	.db 0
kbj:	.db 0
kcn:	.db 0
kcm:	.db 0
kch:	.db 0
knu:	.db 0           ; this period's ranks, odd ranks; this row's counts (pairs, ends, mid pairs)
kno:	.db 0
knp:	.db 0
kne:	.db 0
knm:	.db 0
ke:	.db 0
kside:	.db 0
kund:	.db 0
kpal:	.db 0
knmf:	.db 0
krk:	.db 0
kkk:	.db 0
ktpl:	.dw 0           ; TPL + 66 r (low, mid)
klb:	.db 0           ; this period's LB mid byte
kpp:	.dw 0           ; the reserved count bytes of this row: pairs, ends (low, mid; $15 high)
kpe:	.dw 0
kwm:	.dw 0           ; the mid pairs' list pointer
kww:	.dw 0
kt:	.db 0, 0, 0, 0
kna:	.dw 0
kfw:	.dw 0           ; FW's row (BANDT)
ktag:	.dw 0
kltg:	.dw 0
KFL:	.ds 42          ; per es: the NF keys' base (192 es), the NM keys' (NFKEYS + 90 es)
KFH:	.ds 42
KML:	.ds 42
KMH:	.ds 42
kucl:	.ds 64          ; this period's ranks: their records
kuch:	.ds 64
korank:	.ds 46
korg:	.ds 46          ; per odd rank: its group
knrow:	.ds 34
kmrow:	.ds 34
ksrow:	.ds 33
krbuf:	.ds 66
kibuf:	.ds 32
CMSK:	.db 0, $03, $0F, $3F

; ---------------------------------------------------------------- helpers
kbase:	sta $1A02               ; port 0's base = A / X / Y
	stx $1A03
	sty $1A04
	rts
; image kww -> A low, X mid, Y high (IMG + 32 kww)
kimga:	lda kww + 1
	sta kt
	lda kww
	lsr kt
	ror a
	lsr kt
	ror a
	lsr kt
	ror a
	clc
	adc #IMGM
	tax
	lda kt
	adc #CR3H
	tay
	lda kww
	asl a
	asl a
	asl a
	asl a
	asl a
	rts
; kww = 7 A
k7g:	sta kt + 2
	stz kww + 1
	asl a
	rol kww + 1
	asl a
	rol kww + 1
	asl a
	rol kww + 1
	sec
	sbc kt + 2
	sta kww
	bcs *+5
	dec kww + 1
	rts
; the key table's entry of key kww (3 kww): A low, X mid, Y high
kkta:	lda kww
	sta kt
	lda kww + 1
	sta kt + 1
	asl kt
	rol kt + 1
	lda kww
	clc
	adc kt
	pha
	lda kww + 1
	adc kt + 1
	tax
	ldy #KTH
	pla
	rts
; the rank table's entry of record kww ($17:A000 + 4 kww: this build, period, rank)
krta:	lda kww
	sta kt
	lda kww + 1
	asl kt
	rol a
	asl kt
	rol a
	adc #RTM
	tax
	ldy #KTH
	lda kt
	rts

; ================================================================ the idle's slice (carry set: the store is ready; a failed build: cst $FF)
kidle:	tma #4
	sta km4
	tsx
	stx ksp
	lda FRAMES              ; (no stamp of this frame's vblank: wait for the next one and stamp it)
	cmp kvf
	beq *+5
	jmp kspin
	lda kco
	bne .res
	inc kco
	jsr kbuild
	stz kco
	lda km4
	tam #4
	bcs .f
	sec
	rts
.f:	jmp cfail
.res:	ldx kn
.p:	lda ksv - 1,x
	pha
	dex
	bne .p
	lda kmr4
	tam #4
	lda kra
	ldx krx
	ldy kry
	rts
kyck:	sta kra
	lda FRAMES
	cmp kvf
	bne .y
	lda TIMER
	and #$7F
	sta kt9
	lda kvb
	sec
	sbc kt9
	bcs *+4
	adc #116
	cmp #KSTOP
	bcs .y
	lda kra
	rts
.y:	stx krx
	sty kry
	tma #4
	sta kmr4
	tsx
	stx kt9
	lda ksp
	sec
	sbc kt9
	sta kn
	cly
.c:	inx
	lda $2100,x
	sta ksv,y
	iny
	cpy kn
	bne .c
	ldx ksp
	txs
	lda km4
	tam #4
	lda FRAMES              ; (late: past the vblank already; the next idle stamps)
	cmp kvf
	beq kspin
	clc
	rts
kspin:	lda FRAMES
	sta kt9
.s:	lda TIMER
	and #$7F
	tax
	lda FRAMES
	cmp kt9
	beq .s
	stx kvb
	sta kvf
	clc
	rts
khdr:	cla
	clx
	ldy #CR3H
	jsr cb1
	tai $1A10, khb, 16
	ldx #6
.c:	lda khb,x
	cmp KHM,x
	bne .no
	dex
	bpl .c
	lda khb + 9
	sta knimg
	lda khb + 10
	sta knimg + 1
	cmp #9
	bcs .no
	jsr ksumr
	lda ks
	cmp khb + 12
	bne .no
	lda ks + 1
	cmp khb + 13
	bne .no
	lda khb + 7
	sta rtag
	lda khb + 8
	sta rtag + 1
	lda knimg
	sta rnimg
	lda knimg + 1
	sta rnimg + 1
	lda khb + 11
	sta rnpair
	inc rvalid
.no:	rts
; ks = the store's sum, read back through port 1: $15:0100 (the templates, the lists) to the images' end, a page at a time: the page's
; bytes summed with the carry going round, the page sums folded (ks low += s, high += low)
ksumr:	lda knimg
	clc
	adc #7
	sta kpg
	lda knimg + 1
	adc #0
	lsr a
	ror kpg
	lsr a
	ror kpg
	lsr a
	ror kpg
	sta kpg + 1
	lda kpg
	clc
	adc #IMGM - TPLM
	sta kpg
	bcc *+5
	inc kpg + 1
	cla
	ldx #TPLM
	ldy #CR3H
	jsr cb1
	stz ks
	stz ks + 1
.pg:	jsr kyck
	cla
	clc
	cly
.b:	adc $1A10
	iny
	bne .b
	adc #0
	clc
	adc ks
	sta ks
	clc
	adc ks + 1
	sta ks + 1
	lda kpg
	bne *+5
	dec kpg + 1
	dec kpg
	lda kpg
	ora kpg + 1
	bne .pg
	rts
; the store sealed: its sum, then the header
kseal:	jsr ksumr
	ldx #6
.c:	lda KHM,x
	sta khb,x
	dex
	bpl .c
	lda kltg
	sta khb + 7
	lda kltg + 1
	sta khb + 8
	lda knimg
	sta khb + 9
	lda knimg + 1
	sta khb + 10
	lda npair
	sta khb + 11
	lda ks
	sta khb + 12
	lda ks + 1
	sta khb + 13
	stz khb + 14
	stz khb + 15
	cla
	clx
	ldy #CR3H
	jsr kbase
	tia khb, $1A00, 16
	rts
; a build begins: no header (a reset before the seal finds no store)
kinv:	cla
	clx
	ldy #CR3H
	jsr kbase
	stz $1A00
	rts
; ================================================================ the build (a coroutine: kidle)
kbuild:	tma #4
	pha
	lda rvalid
	ora rgen
	bne .t
	jsr khdr
.t:	jsr kltag               ; the tags: content (ktag) and layout (kltg)
	lda rvalid              ; a store this power-on built for this layout: used as it is
	beq .b
	lda kltg
	cmp rtag
	bne .b
	lda kltg + 1
	cmp rtag + 1
	bne .b
	pla
	tam #4
	clc
	rts
.b:	jsr kinv
	stz rvalid
	stz kerr
	inc rbld                ; (the rank table's stamps: this build's)
	lda rcvalid             ; the records of this content this power-on: kept (the key table, the images, the mid pairs' phases)
	beq .full
	lda ktag
	cmp rctag
	bne .full
	lda ktag + 1
	cmp rctag + 1
	bne .full
	lda rgen
	sta kgen
	lda rnimg
	sta knimg
	lda rnimg + 1
	sta knimg + 1
	stz rcvalid             ; (a build cut short, by a new set-up or a reset, leaves no records to keep: set again at its end)
	jsr kkeys
	bra .per
.full:	stz rcvalid
	lda rgen                ; (the key table: a new generation; the first build of a power-on, or at the wrap, empties it)
	beq .c
	inc a
	sta rgen
	cmp #$FF
	bne .g
.c:	lda #1
	sta rgen
	lda #$FF
	ldx #31
.f:	sta kibuf,x
	dex
	bpl .f
	cla
	clx
	ldy #KTH
	jsr kbase
	ldy #>((KTN * 3 + 31) / 32)
	ldx #<((KTN * 3 + 31) / 32)
	beq .k2
.k:	jsr kyck
	tia kibuf, $1A00, 32
	dex
	bne .k
.k2:	dey
	bpl .k
.g:	lda rgen
	sta kgen
	jsr kkeys
	stz knimg
	stz knimg + 1
	jsr kbmid
.per:	lda #$11                ; port 3: the end lists' stream (base advanced at every access); put back after
	sta $1A39
	stz kbp
.p:	jsr kbper
	inc kbp
	lda kbp
	cmp #NPER
	bne .p
	stz $1A32               ; port 3 as the preload set it: base C6CH:0000, offset 0, control 3
	stz $1A33
	lda #C6CH
	sta $1A34
	stz $1A35
	stz $1A36
	lda #3
	sta $1A39
	pla
	tam #4
	lda kerr
	bne .x
	jsr kseal
	lda knimg
	sta rnimg
	lda knimg + 1
	sta rnimg + 1
	lda ktag
	sta rctag
	lda ktag + 1
	sta rctag + 1
	inc rcvalid
	lda kltg
	sta rtag
	lda kltg + 1
	sta rtag + 1
	inc rvalid
	lda npair
	sta rnpair
	clc
	rts
.x:	sec
	rts
; the key bases per es
kkeys:	clx
	stz kt
	stz kt + 1
	lda #<NFKEYS
	sta kt + 2
	lda #>NFKEYS
	sta kt + 3
.e:	lda kt
	sta KFL,x
	lda kt + 1
	sta KFH,x
	lda kt + 2
	sta KML,x
	lda kt + 3
	sta KMH,x
	lda kt
	clc
	adc #192
	sta kt
	bcc *+5
	inc kt + 1
	lda kt + 2
	clc
	adc #90
	sta kt + 2
	bcc *+5
	inc kt + 3
	inx
	cpx #42
	bne .e
	rts
; the layout tag: a 16-bit sum of the near map rows 0-15 and the slots over columns 80-130, the mid map rows 13-15 over 40-67, NEIDX, the
; tile bases and npair; A / X (also ktag)
kltag:	stz kt
	stz kt + 1
	lda ssb6
	jsr .m
	lda ssb6
	tam #4
	lda #$9D
	sta .a+2
	ldy #3
.r:	ldx #40
.a:	lda $9D00,x
	jsr .s
	inx
	cpx #68
	bne .a
	inc .a+2
	dey
	bne .r
	lda #BANDT
	tam #4
	ldx #127
.n:	lda NEIDX,x
	jsr .s
	dex
	bpl .n
	lda flo
	jsr .s
	lda npair
	jsr .s
	lda kt                  ; (the content: the records hold for it)
	sta ktag
	lda kt + 1
	sta ktag + 1
	lda #T1                 ; (the layout: the slots and the tile bases too)
	jsr .m
	lda nlo
	jsr .s
	lda nhi
	jsr .s
	lda mlo
	jsr .s
	lda mhi
	jsr .s
	lda kt
	sta kltg
	ldx kt + 1
	stx kltg + 1
	rts
.m:	tam #4                  ; rows 0-15 (r * 256 + c), columns 80-130 of the bank at MPR4
	lda #$80
	sta .b+2
	ldy #16
.mr:	jsr kyck
	ldx #80
.b:	lda $8000,x
	jsr .s
	inx
	cpx #131
	bne .b
	inc .b+2
	dey
	bne .mr
	rts
.s:	clc
	adc kt
	sta kt
	bcc *+5
	inc kt + 1
	rts

; ---------------------------------------------------------------- every band mid pair's phases 1-7: SHL[d] of its left pattern | SHR[d] of
; its right's (as mcomp), TPAT in SBANK (MPR6), the shift tables at MPR4; image 7 g + d - 1
kbmid:	lda #SHBANK
	tam #4
	stz kbj
.g:	lda kbj
	cmp npair
	bcc *+3
	rts
	jsr k7g
	jsr kimga
	jsr kbase
	ldy kbj
	lda PAI,y
	jsr mu_pa
	sta .a+1
	stx .a+2
	ldy kbj
	lda PBI,y
	jsr mu_pa
	sta .b+1
	stx .b+2
	lda #1
	sta kbr
.d:	jsr kyck
	lda kbr
	asl a
	clc
	adc #$80
	sta .s+2
	inc a
	sta .r+2
	cly
.y:
.a:	ldx TPAT,y
.s:	lda $8000,x
.b:	ldx TPAT,y
.r:	ora $8100,x
	sta $1A00
	iny
	cpy #32
	bne .y
	inc kbr
	lda kbr
	cmp #8
	bne .d
	lda knimg
	clc
	adc #7
	sta knimg
	bcc *+5
	inc knimg + 1
	inc kbj
	bra .g

; ---------------------------------------------------------------- one period (kbp): template rows to TPL, lists to LB
kbper:	lda kbp
	clc
	adc #CN0
	sta kcn
	lsr a
	sta kcm
	lda kcn
	and #1
	sta kch
	stz knu
	stz kno
	ldx #45
	lda #$FF
.o:	sta korank,x
	dex
	bpl .o
	lda kbp                 ; LB's mid byte; the streams: pairs (port 2) from + $010, ends (port 3) from + $200; mid pairs from + $440
	asl a
	asl a
	asl a
	clc
	adc #LBM
	sta klb
	sta $1A23
	lda #$10
	sta $1A22
	lda #CR3H
	sta $1A24
	sta $1A34
	stz $1A32
	lda klb
	inc a
	inc a
	sta $1A33
	clc
	adc #2
	sta kwm + 1
	lda #$40
	sta kwm
	lda kbp                 ; TPL + 1056 P: mid TPLM + 4 P + (P >> 3), low (P << 5)
	lsr a
	lsr a
	lsr a
	sta kt
	lda kbp
	asl a
	asl a
	clc
	adc kt
	adc #TPLM
	sta ktpl + 1
	lda kbp
	asl a
	asl a
	asl a
	asl a
	asl a
	sta ktpl
	lda #<FW
	sta kfw
	lda #>FW
	sta kfw + 1
	stz kbr
.r:	jsr kbrow
	lda ktpl
	clc
	adc #66
	sta ktpl
	bcc *+5
	inc ktpl + 1
	lda kfw
	clc
	adc #66
	sta kfw
	bcc *+5
	inc kfw + 1
	inc kbr
	lda kbr
	cmp #16
	bne .r
	cla                     ; the header: ranks, odd ranks
	ldx klb
	ldy #CR3H
	jsr kbase
	lda knu
	sta $1A00
	lda kno
	sta $1A00
	cla                     ; ups (+ $300)
	ldx klb
	inx
	inx
	inx
	ldy #CR3H
	jsr kbase
	stz krk
.u:	jsr kyck
	lda krk
	cmp knu
	beq .ud
	tax
	lda kucl,x
	sta kww
	lda kuch,x
	sta kww + 1
	jsr kimga
	sta $1A00
	stx $1A00
	sty $1A00
	inc krk
	bra .u
.ud:	lda #$C0                ; oups (+ $3C0), in odd-rank order
	ldx klb
	inx
	inx
	inx
	ldy #CR3H
	jsr kbase
	stz krk
.v:	jsr kyck
	lda krk
	cmp kno
	beq .vd
	tax
	lda korg,x
	jsr k7g
	jsr kimga
	sta $1A00
	stx $1A00
	sty $1A00
	inc krk
	bra .v
.vd:	rts

; ---------------------------------------------------------------- one row (kbr): the maps' bytes, each cell, the counts, the template row
kbrow:	lda ssb6                ; near map row r, columns cn .. cn + 33; mid map row r (13-15), columns cm .. cm + 33
	tam #4
	lda kcn
	sta .n+1
	lda kbr
	clc
	adc #$80
	sta .n+2
.n:	tii $8000, knrow, 34
	lda kbr
	cmp #13
	bcc .nm
	lda kcm
	sta .m+1
	lda kbr
	clc
	adc #$90
	sta .m+2
.m:	tii $9000, kmrow, 34
.nm:	lda #T1                 ; NSLOT row r
	tam #4
	lda kcn
	sta .s+1
	lda kbr
	clc
	adc #$80
	sta .s+2
.s:	tii $8000, ksrow, 33
	lda #BANDT
	tam #4
	lda kfw                 ; the template row starts as the far row
	sta .f+1
	lda kfw + 1
	sta .f+2
.f:	tii FW, krbuf, 66
	stz knp
	stz kne
	stz knm
	lda $1A22               ; the count bytes reserved (their places kept)
	sta kpp
	lda $1A23
	sta kpp + 1
	stz $1A20
	lda $1A32
	sta kpe
	lda $1A33
	sta kpe + 1
	stz $1A30
	lda kbr
	cmp #13
	bcc .c0
	lda kwm
	ldx kwm + 1
	ldy #CR3H
	jsr kbase
	stz $1A00
	inc kwm
	bne .c0
	inc kwm + 1
.c0:	stz kbj
.c:	jsr kyck
	jsr kbcell
	inc kbj
	lda kbj
	cmp #33
	bne .c
	lda kpp                 ; the counts
	ldx kpp + 1
	ldy #CR3H
	jsr kbase
	lda knp
	sta $1A00
	lda kpe
	ldx kpe + 1
	ldy #CR3H
	jsr kbase
	lda kne
	sta $1A00
	lda kbr
	cmp #13
	bcc .t
	lda knm                 ; (the mid pairs' count byte: 4 n + 1 back)
	asl a
	asl a
	inc a
	sta kt
	lda kwm
	sec
	sbc kt
	pha
	lda kwm + 1
	sbc #0
	tax
	pla
	ldy #CR3H
	jsr kbase
	lda knm
	sta $1A00
.t:	lda ktpl                ; the template row
	ldx ktpl + 1
	ldy #CR3H
	jsr kbase
	tia krbuf, $1A00, 66
	rts

; ---------------------------------------------------------------- a cell (kbj): its template word (krbuf, the far already) and list entries
kbcell:	ldx kbj
	lda knrow,x
	and #$7F
	tay
	lda PROP2,y
	bmi .na                 ; (bit 7: no tile)
	lda knrow + 1,x
	and #$7F
	tay
	lda PROP2,y
	bmi .ea
	jsr kwnear              ; a pair: its tile A; listed when its slot can have a group (slot < KMAX, column < NOGC)
	ldx kbj
	lda ksrow,x
	cmp #KMAX
	bcs .x
	txa
	clc
	adc kcn
	cmp #NOGC
	bcs .x
	txa
	asl a
	sta $1A20
	lda ksrow,x
	sta $1A20
	inc knp
.x:	rts
.ea:	jsr kwnear              ; A only (a run's right end): its tile A at k = 0, a mix from k = 1
	stz kside
	ldx kbj
	lda knrow,x
	and #$7F
	tay
	jmp kbend
.na:	lda knrow + 1,x
	and #$7F
	tay
	lda PROP2,y
	bmi .no
	phy                     ; B only (a run's left end): its under at k = 0, a mix from k = 1
	jsr kunder
	ply
	lda #1
	sta kside
	jsr kbend
	bcc .x2
	jmp kmidc
.x2:	rts
.no:	lda kbr                 ; nothing of the near: rows 0-12 the far (already there)
	cmp #13
	bcs .u
	rts
.u:	jsr kunder
	jmp kmidc
; the template word = the near tile at kbj (its code & $7F)
kwnear:	ldx kbj
	lda knrow,x
	and #$7F
	tay
	txa
	asl a
	tax
	tya
	clc
	adc nlo
	sta krbuf,x
	lda nhi
	adc #0
	sta krbuf + 1,x
	rts
; the template word = the cell without its near layer at k = 0: rows 13-15 the mid at dm = 4 (cn & 1) (else the far, already there)
kunder:	lda kbr
	cmp #13
	bcs *+3
	rts
	lda kbj
	asl a
	tax
	ldy kbj
	lda kmrow,y
	beq .b
	lda kmrow + 1,y
	beq .ea
	lda kch                 ; a pair: dm 0 its tile A; dm 4 a band pair's phase-4 tile (group first + 1), else its tile A
	beq .ta
	phx
	jsr kgrp
	plx
	cmp #$FF
	beq .ta
	tay
	lda MGL,y
	clc
	adc #1
	sta krbuf,x
	lda mhi
	and #$F0
	ora MGH,y
	adc #0
	sta krbuf + 1,x
	rts
.ea:	lda kch                 ; A only: its tile while dm < 4, else the far
	bne .f
.ta:	ldy kbj
	lda kmrow,y
.tm:	clc
	adc mlo
	sta krbuf,x
	lda mhi
	adc #0
	sta krbuf + 1,x
.f:	rts
.b:	lda kmrow + 1,y          ; B only: the far while dm < 4, else its tile
	beq .f
	lda kch
	beq .f
	lda kmrow + 1,y
	bra .tm
; A = the band mid group at this cell (rows 13-15, mid column cm + j: BMS), $FF none
kgrp:	lda kcm
	clc
	adc kbj
	sec
	sbc #BMC0
	cmp #BMCN
	bcs .n
	sta kt
	lda kbr
	sec
	sbc #13
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc kt
	tay
	lda BMS,y
	rts
.n:	lda #$FF
	rts
; a mid cell of rows 13-15 with nothing of the near over it at any k: a band pair -> the mid pairs' list (the template has the rest)
kmidc:	lda kbr
	cmp #13
	bcc .x
	ldy kbj
	lda kmrow,y
	beq .x
	lda kmrow + 1,y
	beq .x
	jsr kgrp
	cmp #$FF
	beq .x
	sta kund
	tax
	lda korank,x            ; its odd rank this period
	cmp #$FF
	bne .r
	lda kno
	sta korank,x
	tay
	txa
	sta korg,y
	tya
	inc kno
.r:	sta krk
	lda kwm
	ldx kwm + 1
	ldy #CR3H
	jsr kbase
	lda kwm
	clc
	adc #4
	sta kwm
	bcc *+5
	inc kwm + 1
	lda kbj
	asl a
	sta $1A00
	ldy kund
	lda MGL,y               ; first tile - 1
	sec
	sbc #1
	sta $1A00
	lda MGH,y
	sbc #0
	sta kt
	lda mhi
	and #$F0
	ora kt
	sta $1A00
	lda krk
	sta $1A00
	inc knm
.x:	rts

; ---------------------------------------------------------------- a near end (Y = its tile, kside): its record (made when new), its rank, the
; ends' entry. Carry set: none (no part: NEIDX >= NEMAX; screen column 32, under the frame's border; a far tile past FT; no rank left)
kbend:	lda NEIDX,y
	cmp #NEMAX
	bcs .no
	sta ke
	lda kbj
	cmp #32
	beq .no
	jsr kkey
	bcs .no
	jsr krec
	bcs .no
	jsr krank
	bcs .no
	ldx kbj
	txa
	asl a
	sta $1A30
	lda krk
	sta $1A30
	lda kpal
	sta $1A30
	inc kne
	clc
	rts
.no:	sec
	rts
kkey:	lda ke
	asl a
	ora kside
	tax
	stz knmf
	lda kbr
	cmp #13
	bcc .nf
	ldy kbj
	lda kmrow,y
	beq .nf
	lda kmrow + 1,y
	beq .nf
	phx
	jsr kgrp
	plx
	cmp #$FF
	beq .nf
	sta kund
	inc knmf
	lda #(>MIXBASE) | (PALM << 4)
	sta kpal
	lda kund                ; NFKEYS + 90 es + 2 g + h
	asl a
	ora kch
	clc
	adc KML,x
	sta kww
	lda KMH,x
	adc #0
	sta kww + 1
	clc
	rts
.nf:	lda kbj                 ; the far tile: its word in FW's row (krbuf may hold this cell's template word already)
	asl a
	tay
	lda kfw
	sta .fa+1
	lda kfw + 1
	sta .fa+2
.fa:	lda FW,y
	sec
	sbc flo
	cmp #184
	bcs .x
	sta kund
	lda #(>MIXBASE) | (PALF << 4)
	sta kpal
	lda kund                ; 192 es + f
	clc
	adc KFL,x
	sta kww
	lda KFH,x
	adc #0
	sta kww + 1
	clc
.x:	rts
krec:	jsr kkta
	jsr cb1
	lda $1A10
	cmp kgen
	bne .new
	lda $1A10
	ldx $1A10
	sta kww
	stx kww + 1
	clc
	rts
.new:	lda knimg + 1
	cmp #9                  ; (2,304 images: IMG ends under the key table at $17:0000)
	bcc .ok
	inc kerr
	sec
	rts
.ok:	jsr kkta                ; the key's entry: generation, first image
	jsr kbase
	lda kgen
	sta $1A00
	lda knimg
	sta $1A00
	sta kww
	lda knimg + 1
	sta $1A00
	sta kww + 1
	jsr krta                ; its rank entry: no period yet
	jsr kbase
	stz $1A00
	jsr kcomp
	lda knimg
	clc
	adc #3
	sta knimg
	bcc *+5
	inc knimg + 1
	clc
	rts
; krk = the rank of record kww in this period (added when new). Carry set: no rank left (64)
krank:	jsr krta
	jsr cb1
	lda $1A10
	cmp rbld
	bne .new
	lda $1A10
	cmp kbp
	bne .new
	lda $1A10
	sta krk
	clc
	rts
.new:	lda knu
	cmp #64
	bcs .x
	sta krk
	tax
	lda kww
	sta kucl,x
	lda kww + 1
	sta kuch,x
	inc knu
	jsr krta
	jsr kbase
	lda rbld
	sta $1A00
	lda kbp
	sta $1A00
	lda krk
	sta $1A00
	clc
.x:	rts
kcomp:	jsr kimga
	jsr kbase
	lda knmf
	bne .u
	tma #6                  ; FT[f] into kibuf (BANDF at MPR6 for a moment)
	pha
	lda #BANDF
	tam #6
	lda kund
	stz kt
	asl a
	rol kt
	asl a
	rol kt
	asl a
	rol kt
	asl a
	rol kt
	asl a
	rol kt
	sta .ft+1
	lda kt
	clc
	adc #$C0
	sta .ft+2
.ft:	tii $C000, kibuf, 32
	pla
	tam #6
.u:	lda #BANDN
	tam #4
	lda ke                  ; 384 e: high e + e / 2, low (e & 1) << 7
	lsr a
	cla
	ror a
	sta kna
	lda ke
	lsr a
	clc
	adc ke
	sta kna + 1
	lda kside
	beq .s0
	lda kna                 ; + 192
	clc
	adc #192
	sta kna
	bcc .s0
	inc kna + 1
.s0:	lda knmf
	beq .p0
	lda kna                 ; + 96 (PALM)
	clc
	adc #96
	sta kna
	bcc .p0
	inc kna + 1
.p0:	lda kna + 1
	clc
	adc #$80
	sta kna + 1
	lda #1
	sta kkk
.k:	lda knmf
	beq .m
	lda kww
	pha
	lda kww + 1
	pha
	lda kund
	jsr k7g
	lda kkk
	ldx kch                 ; + 4 h + k - 1
	beq *+5
	clc
	adc #4
	dec a
	clc
	adc kww
	sta kww
	bcc *+5
	inc kww + 1
	jsr kimga
	jsr cb1
	tai $1A10, kibuf, 32
	pla
	sta kww + 1
	pla
	sta kww
.m:	ldx kkk
	lda CMSK,x
	ldx kside
	beq *+4
	eor #$FF
	sta .m0+1
	sta .m1+1
	sta .m2+1
	sta .m3+1
	lda kna
	sta .n0+1
	inc a
	sta .n1+1
	inc a
	sta .n2+1
	inc a
	sta .n3+1
	lda kna + 1
	sta .n0+2
	sta .n1+2
	sta .n2+2
	sta .n3+2
	cly
.y:	lda kibuf,y             ; (four bytes a turn: kna is a multiple of 32, so + 3 stays in its page)
.m0:	and #0
.n0:	ora $8000,y
	sta $1A00
	lda kibuf + 1,y
.m1:	and #0
.n1:	ora $8001,y
	sta $1A00
	lda kibuf + 2,y
.m2:	and #0
.n2:	ora $8002,y
	sta $1A00
	lda kibuf + 3,y
.m3:	and #0
.n3:	ora $8003,y
	sta $1A00
	iny
	iny
	iny
	iny
	cpy #32
	bne .y
	lda kna                 ; the next k: + 32
	clc
	adc #32
	sta kna
	bcc *+5
	inc kna + 1
	inc kkk
	lda kkk
	cmp #4
	beq *+5
	jmp .k
	lda #BANDT
	tam #4
	rts
