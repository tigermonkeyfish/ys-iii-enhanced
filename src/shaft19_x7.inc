OVER       = 1
klin	.macro                  ; obuild's list: block of okw + \1 (2 k, Y = cx) into its key's mask \2 (oml / omh) as bit \3
	ldx okw+\1,y
	lda \2,x
	ora #\3
	sta \2,x
	.endm
OLST       = $0E        ; the lists: card $0E2000 (bank byte, page $20)
ONS        = $0F        ; ns: card $0F3000; the key $0F6000

	jmp ksw64               ; 0 kpass (U2L): units per band from 2-line groups (shaft19_otab.inc)
	jmp kord                ; 3 kpass (ORD): the record (xcellh's), the leave-out by the static order
	jmp kunit2              ; 6 the set-up (U2L), after kunit: the 2-line unit tables into DB_K's first six pages
	.if PLG
	jmp ob6
	.else
	jmp obuild
	.endif
	.if PLG
	jmp sinit               ; 12 sset / sreen (PLUG): the plug's state empty (shaft19_x8.inc)
	jmp s6go                ; 15 sset / sreen (PLUG): the sixth bank's entry X
	.endif
k5magic:	.db $19, $B5

; ---------------------------------------------------------------- the pass: the record and the leave-out (ORD)
	.if WAL
kord:	lda pxr                 ; kcg: bit 0 off the grid in X, bit 1 in Y
	and #6
	cmp #1
	cla
	rol a
	sta t0
	lda pyr
	and #6
	cmp #1
	cla
	rol a
	asl a
	ora t0
	cmp kcg
	beq .s
	sta kcg
	lda #$FF
	sta kch
.s:	lda p0l
	cmp kcl
	bne .r
	lda p0h
	cmp kch
	beq .lv
.r:	jsr wcell5
.lv:	stz kgyt
	stz kgyt+1
	.if UPF
	clx
.fz:	stz ff,x
	inx
	cpx #16
	bne .fz
	.endif
	stz ksumd
	stz kforce
	stz kfst
	lda #64                 ; clamp emitted wall pieces so wcost0[wn0] + wn1 <= 64 - kgn
	sec
	sbc kgn
	bcs .k0ok
	cla
.k0ok:	sta t0
	; first cap wn0 <= 16 - min(units[0..3]) and wn1 <= 16 - min(units[4..7]): columns dropped on all 4 bands of a sprite row never show
	lda units
	cmp units+1
	bcc .m01
	lda units+1
.m01:	cmp units+2
	bcc .m02
	lda units+2
.m02:	cmp units+3
	bcc .m03
	lda units+3
.m03:	sta t1
	lda #16
	sec
	sbc t1
	bcs .m04
	cla
.m04:	cmp wn_tot0
	bcc .m05
	lda wn_tot0
.m05:	tax
	lda units+4
	cmp units+5
	bcc .m11
	lda units+5
.m11:	cmp units+6
	bcc .m12
	lda units+6
.m12:	cmp units+7
	bcc .m13
	lda units+7
.m13:	sta t1
	lda #16
	sec
	sbc t1
	bcs .m14
	cla
.m14:	cmp wn_tot1
	bcc .m15
	lda wn_tot1
.m15:	tay
.ck:	lda wcost0,x
	sty t1
	clc
	adc t1
	cmp t0
	bcc .co
	beq .co
	; drop from srow 1 (wn1) first while > wn_see1 (lower half already drops columns on bands 5..7), then srow 0 while > wn_see0
	cpy wn_see1
	beq .t0
	bcc .t0
	dey
	bra .ck
.t0:	cpx wn_see0
	beq .tb
	bcc .tb
	dex
	bra .ck
.tb:	cpy #0
	beq .tx
	dey
	bra .ck
.tx:	dex
	bra .ck
.co:	stx wn0
	sty wn1
	sta kne
	clx                     ; bands 0..3 (srow 0)
.b0:	lda #16
	sec
	sbc units,x
	bcs .a0
	cla
.a0:	cmp wn0
	bcc .k0
	lda wn0
.k0:	sta t1                  ; K = min(wn0, max(0, 16 - units[b]))
	tay
	clc
	adc units,x
	cmp umax
	bcc .u0
	sta umax
.u0:	lda wn_tot0
	sec
	sbc t1
	sta kD,x
	beq .z0
	clc
	adc ksumd
	sta ksumd
	lda #1
	sta kgyt
.z0:	txa
	asl a
	sta t2
	tax
	lda sux0_lo,y
	sta out,x
	lda sux0_hi,y
	sta out+1,x
	cpy wn_see0
	bcs .n0
	lda wn_see0
	sec
	sbc t1
	clc
	adc kfst
	sta kfst
	inc kforce
	.if UPF
	ldx wn_see0
	lda sux0_lo,y
	eor sux0_lo,x
	ldx t2
	sta ff,x
	ldx wn_see0
	lda sux0_hi,y
	eor sux0_hi,x
	ldx t2
	sta ff+1,x
	.endif
.n0:	lda t2
	lsr a
	tax
	inx
	cpx #4
	beq .b1
	jmp .b0
.b1:	lda #16                 ; bands 4..7 (srow 1)
	sec
	sbc units,x
	bcs .a1
	cla
.a1:	cmp wn1
	bcc .k1
	lda wn1
.k1:	sta t1                  ; K = min(wn1, max(0, 16 - units[b]))
	tay
	clc
	adc units,x
	cmp umax
	bcc .u1
	sta umax
.u1:	lda wn_tot1
	sec
	sbc t1
	sta kD,x
	beq .z1
	clc
	adc ksumd
	sta ksumd
	lda #1
	sta kgyt+1
.z1:	txa
	asl a
	sta t2
	tax
	lda sux1_lo,y
	sta out,x
	lda sux1_hi,y
	sta out+1,x
	cpy wn_see1
	bcs .n1
	lda wn_see1
	sec
	sbc t1
	clc
	adc kfst
	sta kfst
	inc kforce
	.if UPF
	ldx wn_see1
	lda sux1_lo,y
	eor sux1_lo,x
	ldx t2
	sta ff,x
	ldx wn_see1
	lda sux1_hi,y
	eor sux1_hi,x
	ldx t2
	sta ff+1,x
	.endif
.n1:	lda t2
	lsr a
	tax
	inx
	cpx #8
	beq .x
	jmp .b1
.x:	lda ksumd
	clc
	adc nleft
	sta nleft
	bcc .y
	inc nleft+1
.y:	rts

wcell5:	lda p0l
	sta kcl
	sta t0
	lda p0h
	sta kch
	and #$0F
	sta t1
	lda t0
	and #63
	tax
	lda t0
	asl a
	rol t1
	asl a
	rol t1
	ldy t1
	stx t2
	sty t3
	ldx kcg
	lda q5m,x
	clc
	adc t2
	sta t4
	lsr a
	sta $1A03
	cla
	ror a
	sta t6
	lda t3
	asl a
	ora t6
	sta $1A02
	lda #$06
	sta $1A04
	lda $1A00
	sta wn_tot0
	lda $1A00
	sta wn_see0
	lda t3
	clc
	adc #8
	asl a
	ora t6
	sta $1A02
	lda $1A00
	sta wn_tot1
	lda $1A00
	sta wn_see1
	lda t4
	asl a
	sta t5
	lda #$04
	adc #0
	sta $1A04
	lda t3
	asl a
	asl a
	asl a
	sta $1A02
	lda t5
	adc #0
	sta $1A03
	ldx #0
.u0:	lda $1A00
	tay
	and #$0F
	sta wcol0,x
	tya
	lsr a
	lsr a
	lsr a
	lsr a
	sta wcol0+1,x
	inx
	inx
	cpx #16
	bne .u0
	lda t3
	clc
	adc #8
	asl a
	asl a
	asl a
	sta $1A02
	lda t5
	adc #0
	sta $1A03
	ldx #0
.u1:	lda $1A00
	tay
	and #$0F
	sta wcol1,x
	tya
	lsr a
	lsr a
	lsr a
	lsr a
	sta wcol1+1,x
	inx
	inx
	cpx #16
	bne .u1
	ldx wn_tot0
	stz sux0_lo,x
	stz sux0_hi,x
	beq .s1
.s0:	dex
	ldy wcol0,x
	lda sux0_lo+1,x
	ora on1l,y
	sta sux0_lo,x
	lda sux0_hi+1,x
	ora on1h,y
	sta sux0_hi,x
	txa
	bne .s0
.s1:	ldx wn_tot1
	stz sux1_lo,x
	stz sux1_hi,x
	beq .wc
.s2:	dex
	ldy wcol1,x
	lda sux1_lo+1,x
	ora on1l,y
	sta sux1_lo,x
	lda sux1_hi+1,x
	ora on1h,y
	sta sux1_hi,x
	txa
	bne .s2
.wc:	stz wcost0
	ldy wn_tot0
	beq .wdone
	sty .wlim+1
	clx
	cla
.cl:	ldy wcol0,x
	cpy #2
	bcs .c1
	inc a
.c1:	inc a
	inx
	sta wcost0,x
.wlim:	cpx #16
	bne .cl
.wdone:	rts
q5m:	.db 0, 33, 66, 99
	.else
; as x5's xcellh (the camera cell's record; off the grid merged with the next cells': kcg) and kleave (per band D = n - (16 - units)),
; the D blocks from the order list of the class; xleave's mend is not needed (the list holds the merged set).
kord:	lda pxr                 ; kcg: bit 0 off the grid in X, bit 1 in Y
	and #6
	cmp #1
	cla
	rol a
	sta t0
	lda pyr
	and #6
	cmp #1
	cla
	rol a
	asl a
	ora t0
	cmp kcg
	beq .s
	sta kcg
	lda #$FF
	sta kch                 ; (the class changed: the record again)
.s:	lda p0l
	cmp kcl
	bne .r
	lda p0h
	cmp kch
	beq .lv
.r:	jsr kcell5
	lda kcg
	beq .lv
	lsr a                   ; the next cell in X (+ 1), in Y (+ 64: the next cell row), both (+ 65)
	bcc .m1
	lda #1
	jsr kmrg5
.m1:	lda kcg
	and #2
	beq .m2
	lda #64
	jsr kmrg5
	lda kcg
	cmp #3
	bne .m2
	lda #65
	jsr kmrg5
.m2:	ldx #7                  ; the counts again (XPOPT, DB_NEAR at MPR3)
.b:	ldy kvl,x
	lda XPOPT,y
	ldy kvh,x
	clc
	adc XPOPT,y
	sta kn,x
	dex
	bpl .b
.lv:	stz kgyt                ; the leave-out: per band D = n - (16 - units) > 0: the first D blocks of the band's list
	stz kgyt+1
	.if UPF
	clx                     ; (this reading's forced and dropped blocks: ff)
.fz:	stz ff,x
	inx
	cpx #16
	bne .fz
	.endif
	stz ksumd
	stz kforce
	stz kfst
	lda ohi
	sta $1A04
	lda oofl
	sta q5o
	lda oofh
	sta q5o+1
	clx
.bd:	lda #16
	sec
	sbc units,x
	bcs .a
	cla
.a:	sta t0
	sec
	sbc kn,x
	bcc .dd
	jmp .z
.dd:	eor #$FF                ; D
	inc a
	sta kD,x
	sta t5
	clc
	adc ksumd
	sta ksumd
	lda q5o
	sta $1A02
	lda oomd
	ora q5o+1
	sta $1A03
	stz t1
	stz t2
	lda t5                  ; D past ns: a see-through block left out
	sec
	sbc kns,x
	beq .nf
	bcc .nf
	clc
	adc kfst
	sta kfst
	inc kforce
	.if UPF
	lda #1
	sta q5f
	.endif
.nf:	lda t5
	lsr a
	sta t6
	beq .o
.p:	ldy $1A00               ; two blocks a byte
	lda on2l,y
	tsb t1
	lda on2h,y
	tsb t2
	dec t6
	bne .p
.o:	lda t5
	lsr a
	bcc .e
	ldy $1A00               ; the last one (the low nibble)
	lda on1l,y
	tsb t1
	lda on1h,y
	tsb t2
.e:
	.if UPF
	lda q5f                 ; (forced: the blocks past ns into ff: the list's first ns read again)
	beq .e2
	stz q5f
	jsr kfq5
.e2:
	.endif
	txa
	asl a
	tay
	lda t1
	sta out,y
	eor #$FF
	and kvl,x
	sta kkp,x
	lda t2
	sta out+1,y
	eor #$FF
	and kvh,x
	sta kkp+8,x
	txa
	lsr a
	lsr a
	tay
	lda #1
	sta kgyt,y
	lda t0
	bra .u
.z:	stz kD,x
	txa
	asl a
	tay
	cla
	sta out,y
	sta out+1,y
	lda kvl,x
	sta kkp,x
	lda kvh,x
	sta kkp+8,x
	lda kn,x
.u:	clc
	adc units,x
	cmp umax
	bcc .v
	sta umax
.v:	lda q5o
	clc
	.if OCK
	adc qstep               ; (OCK off the grid: 8, the lists per camera cell)
	.else
	adc #16
	.endif
	sta q5o
	bcc .w
	inc q5o+1
.w:	inx
	cpx #8
	beq .x
	jmp .bd
.x:	lda ksumd
	clc
	adc nleft
	sta nleft
	bcc .y
	inc nleft+1
.y:	rts
q5o:	.dw 0
	.if UPF
q5f:	.db 0
q5a:	.db 0
q5b:	.db 0
; (UPF) ff of band X |= the first D blocks (t1, t2) less the first ns of its list
kfq5:	lda q5o
	sta $1A02
	lda oomd
	ora q5o+1
	sta $1A03
	stz q5a
	stz q5b
	lda kns,x
	lsr a
	sta t6
	beq .fo
.fp:	ldy $1A00
	lda on2l,y
	tsb q5a
	lda on2h,y
	tsb q5b
	dec t6
	bne .fp
.fo:	lda kns,x
	lsr a
	bcc .fe
	ldy $1A00
	lda on1l,y
	tsb q5a
	lda on1h,y
	tsb q5b
.fe:	txa
	asl a
	tay
	lda q5a
	eor #$FF
	and t1
	ora ff,y
	sta ff,y
	lda q5b
	eor #$FF
	and t2
	ora ff+1,y
	sta ff+1,y
	rts
	.endif
kcell5:	lda p0l
	sta kcl
	sta t0
	lda p0h
	sta kch
	and #$0F
	sta t1
	lda t0
	and #63
	tax                     ; cx
	lda t0
	asl a
	rol t1
	asl a
	rol t1
	ldy t1                  ; cy
	clc
	lda krowl,y
	adc kcoll,x
	sta $1A02
	.if OCK
	sta qh0
	.endif
	lda krowm,y
	adc kcolh,x
	sta $1A03
	.if OCK
	sta qh1
	.endif
	lda krowh,y
	adc #0
	sta $1A04
	.if OCK
	sta qh2
	.endif
	tai $1A00, kh, 24
	tai $1A00, kh + 24, 24
	stx t2
	sty t3
	ldx kcg
	lda q5m,x
	clc
	adc t2
	sta t4                  ; m = 33 c + cx (at most 131)
	asl a
	sta t5
	cla
	rol a
	sta t6
	lda t5
	clc
	adc #$20
	sta oomd
	lda t6
	adc #OLST
	sta ohi
	lda t3                  ; 8 cy
	asl a
	asl a
	asl a
	sta oofl
	cla
	rol a
	sta oofh
	.if OCK
	lda #16
	sta qstep
	ldx kcg
	beq .q0
	lda #8
	sta qstep
	lda qh0
	clc
	adc qkl - 1,x
	sta oofl
	stz oofh
	lda qh1
	adc qkm - 1,x
	sta oomd
	lda qh2
	adc qkh - 1,x
	sta ohi
.q0:
	.endif
	lda t4
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc t3
	sta $1A02
	lda t4
	lsr a
	lsr a
	clc
	adc #$30
	sta $1A03
	lda #ONS
	sta $1A04
	clx
.n:	lda $1A00
	sta kns,x
	lda $1A00
	inx
	cpx #8
	bne .n
	rts
q5m:	.db 0, 33, 66, 99
	.if OCK
qh0:	.db 0
qh1:	.db 0
qh2:	.db 0
qstep:	.db 16
qkl:	.db <$019F00, <$033340, <$04C780
qkm:	.db >$019F00, >$033340, >$04C780
qkh:	.db ($019F00 >> 16), ($033340 >> 16), ($04C780 >> 16)
	.endif
; the record of the cell p0 + A ORed into kh (visible blocks, group masks): x5's xmrg
kmrg5:	clc
	adc p0l
	sta t0
	lda p0h
	adc #0
	and #$0F
	sta t1
	lda t0
	and #63
	tax
	lda t0
	asl a
	rol t1
	asl a
	rol t1
	ldy t1
	clc
	lda krowl,y
	adc kcoll,x
	sta $1A02
	lda krowm,y
	adc kcolh,x
	sta $1A03
	lda krowh,y
	adc #0
	sta $1A04
	tai $1A00, q5h2, 24
	tai $1A00, q5h2 + 24, 24
	ldx #15
.v:	lda kgv,x
	ora q5h2 + 32,x
	sta kgv,x
	cpx #8
	bcs .w
	lda kvl,x
	ora q5h2 + 8,x
	sta kvl,x
	lda kvh,x
	ora q5h2 + 16,x
	sta kvh,x
.w:	dex
	bpl .v
	rts
q5h2:	.ds 48
	.endif

; ---------------------------------------------------------------- the set-up (U2L): kunit2 after kunit (DB_K borrowed at MPR3)
kunit2:	tma #3
	pha
	lda #DB_K
	tam #3
	lda #<kunt2
	sta .t+1
	lda #>kunt2
	sta .t+2
	stz .t+3
	lda #$60
	sta .t+4
	ldx #192                ; moves of 8 (six pages)
.t:	tii kunt2, $6000, 8
	lda .t+1
	clc
	adc #8
	sta .t+1
	bcc .n
	inc .t+2
.n:	lda .t+3
	clc
	adc #8
	sta .t+3
	bcc .m
	inc .t+4
.m:	dex
	bne .t
	pla
	tam #3
	rts

	.if PLG
ob6:	ldx #6                  ; (r19-plug-streams) obuild in the sixth bank (shaft19_xa.inc)
	jmp s6go
	.endif
	.if PLG = 0
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
