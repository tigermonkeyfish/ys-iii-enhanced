c9jt:	.dw bpos                ; 0: every pass after cpos: the bridge's take-over and stand-down
	.dw bgnew               ; 2: slot bgs's group (port 1 gives its k = 1 image's address); A = the group + 1, 0 none left
	.dw bens                ; 4: the pairs' list at port 1: every slot without a group gets one
	.dw bmfil
	.dw bmwarm              ; 8: (the fill ahead) the mid pairs' list at port 1: every pair without a tile at phase BMFT gets one
c9mk:	.db 'B', '9'            ; (bpos6's check of the copy, with the last byte)
ngn:	.db 0           ; near groups given; left in the run; the next run; the next group's first tile
ngr:	.db 0
ngx:	.db 0
ngt:	.dw 0
bga:	.db 0, 0, 0
bgk:	.db 0
bpw:	.dw 0
xm:	.dw 0
bge:	.db 0
bpre:	.db 0           ; the claim is held (bp_idle); its value on the pass before
bpo:	.db 0
bsl:	.db 0           ; the slot being given a group or a tile
mrx:	.db 0           ; the mid cache: the next run, tiles left in the run, its next tile
mrl:	.db 0
mtt:	.dw 0
btl:	.db 0           ; the tile being given
bth:	.db 0
vd:	.db 0           ; the victim search: its phase, its slot, phases left to try
vs:	.db 0
vtr:	.db 0
; the mid cache's tiles, all held by the band's own protocol while the bridge draws (bpos6 has them copied out at the claim): the
; band's 45 mid groups (mgxfer's copies), the odd set's four runs (cocopy / cores), then the two sets' tail (set 0 / set 1's restore:
; from the switch on only, MRNL: the band's restore of its sets may still be writing there while the claim is held): 241 tiles. Low,
; high, length
MRN:	.db <$5A0, >$5A0, 30, <$5E0, >$5E0, 30, <$607, >$607, 27, <$628, >$628, 18, <$63D, >$63D, 41
	.db <$66D, >$66D, 11, <$1A8, >$1A8, 8, <$578, >$578, 5, <$78C, >$78C, 71, 0, 0, 0
MRNL       = 8 * 3
OFL:	.db $E0, $00, $20, $40
OFH:	.db $FF, 0, 0, 0
MOL9:	.db $00, $40, $80, $C0, $00, $40, $80
MOH9:	.db >MTH, >MTH, >MTH, >MTH, (>MTH) + 1, (>MTH) + 1, (>MTH) + 1
NGR:	.db <MIXX, >MIXX, 1, <$680, >$680, 21, <VXT0, >VXT0, 12, <$6E7, >$6E7, 5, <$7D3, >$7D3, 15, 0, 0, 0
; (quarry-handover: the run at $15A third, not second: the first 22 groups are then in tiles band 1's last picture never names once
; the mix set it uses is known; the hand-over's image writes the second and fourth runs' low bytes at a claim going left at 624
; when that set is set 0: $6C0 x 21 and $680 x 5, the same tiles of the same pool: hngr)
; ---------------------------------------------------------------- the switch
bpos:	lda ho_bh               ; (0 while the bridge draws: brm 21)
	beq *+5
	jmp bp_idle
	lda act
	cmp #2
	bne bp_gone             ; (a window: cpos stood the band path down; the idle's wsdo puts the runs back)
	lda <LOCKZP
	and #$18
	bne bp_sd
	lda brst
	dec a
	bne bp_sd
	lda hcl                 ; outside region 1 (camera under 296, or 624 and more): at once
	cmp #<(296 + 16)
	lda hch
	sbc #>(296 + 16)
	bcc bp_sd
	lda hcl
	cmp #<(624 + 16)
	lda hch
	sbc #>(624 + 16)
	bcs bp_sd
	lda CAMX
	and #15
	bne bp_x
	lda hcl                 ; aligned at 320 or below
	cmp #<(320 + 16 + 1)
	lda hch
	sbc #>(320 + 16 + 1)
	bcs bp_x
bp_sd:	jsr sprest
	stz act                 ; (quarry-seams: the stand-down's count, nhand, is the seams' image's now, sbx: 3 bytes for bp_idle's call)
	jsr bp_inv
bp_gone:	jsr brm0                ; (passbegin's vector and handover's band test as they were: the stub bank's piece, at MPR6 here)
	stz bpw
	stz bpw + 1
	jsr bpalw
	lda di_bn               ; (quarry-seams) with the seams' image in (sinit has taken didle's camera test out: the store loaded from
	bne bp_x                ; the disc): the hand-over to band 1 at 624 (quarry_cards.inc: sbx)
	ldy #4
	jmp c7tr
bp_x:	rts
bp_inv:	stz dvalid
	stz dvalid + 1
	stz dfull
	stz dfull + 1
	stz ldir
	rts
bpalw:	lda bpw
	sta BP15
	lda bpw + 1
	sta BP15 + 1
	tma #6
	pha
	lda #CBANK
	tam #6
	lda bpw
	sta BK15
	lda bpw + 1
	sta BK15 + 1
	pla
	tam #6
	php
	sei
	lda #4 * 16 + 15
	sta $0402
	stz $0403
	lda bpw
	sta $0404
	lda bpw + 1
	sta $0405
	plp
	rts
bp_xi:	rts
bp_idle:	lda di_bn
	bne *+7
	ldy #6
	jsr c7tr
	lda bpre
	sta bpo
	stz bpre
	lda bgs
	cmp #$FD
	bcc *+5
	stz bgs
	lda act
	bne bp_xi
bp_ab      = * - 1          ; (quarry-seams-2: 0, the test off, on a pass going right at 308 .. 334: the claim while the open quarry draws; srp)
	lda brst
	dec a
	bne bp_xi
	lda <LOCKZP
	and #$18
	bne bp_xi
	lda MENU
	ora wsd
	ora vxph
	bne bp_xi
	lda pw_state
	cmp #5
	beq bp_xi
	tma #6
	pha
	lda #CBANK
	tam #6
	lda pw_state            ; (the band's column prewarm is patched out with its store in use: its count of idles cut short, so the
	cmp #1                  ; band is ready 2 idles after the bridge lets go at 624)
	bne .c
	lda #80
	sta pw_c
.c:	lda svd
	beq .no
	lda hcl
	cmp #<(322 + 16)
bp_cl      = * - 1          ; (quarry-seams-2: 308's on such a pass)
	lda hch
	sbc #>(322 + 16)
	bcc .no
	lda hcl
	cmp #<(622 + 16 + 1)
bp_cu      = * - 1          ; (quarry-handover: 624's on the pass band 1 lets go going left: the claim on the stand-down's pass, hpas)
	lda hch
	sbc #>(622 + 16 + 1)
	bcs .no
	lda bpo
	beq .cl
	lda vxok
	beq .cl
	lda pw_state
	beq .held
bp_clm     = *              ; (quarry-handover: the claim as a routine, MPR6's bank pushed: hclaim in the hand-over's image)
.cl:	pla
	tam #6
	lda #9
	jsr callb
	lda vxok                ; the borrowed runs copied out unless the band's copies are still held
	bne .h
	inc vxok
	cly
	lda #9
	ldx #C5BANK
	jsr callx
.h:	tma #4
	pha
	lda #BANDT
	tam #4
	clx
.z:	stz NS,x
	stz MTH,x               ; (the mid cache empty: no pair has a tile at any phase)
	stz MTH + $100,x
	inx
	bne .z
	pla
	tam #4
	stz ngn
	stz ngr
	stz ngx
	stz mrx
	stz mrl
	lda #$FD
	bra .sg
.no:	pla
	tam #6
	rts
.held:	lda CAMX                ; the switch: aligned, 336 .. 608
	and #15
bp_al      = * - 1          ; (quarry-seams-2: 0 on such a pass: the switch at 322, the pass after the open quarry's stand-down)
	bne .hd
	lda hcl
	cmp #<(336 + 16)
bp_sl      = * - 1          ; (quarry-seams-2: 322's)
	lda hch
	sbc #>(336 + 16)
	bcc .hd
	lda hcl
	cmp #<(608 + 16 + 1)
bp_sh      = * - 1          ; (quarry-seams-2: 622's on a pass going left at 622 .. 608: the switch on the pass after the claim, srp)
	lda hch
	sbc #>(608 + 16 + 1)
	bcc .sw
.hd:	pla
	tam #6
	lda #$FE
.sg:	sta bgs
	inc bpre
	rts
.sw:	lda #1                  ; (as bi_cam: set 0 / set 1's restore due from its start: their tiles are the bridge's from here)
	sta wz
	stz rs
	pla
	tam #6
	lda $3C04
	sta bpw
	lda $3C05
	sta bpw + 1
	jsr bpalw
	lda #2
	sta act
	lda #21                 ; (passbegin's vector: bandjt 21; bgs $FF: the first pass is to come)
	sta brm
	stz ho_bh               ; (handover's band test never lets go meanwhile)
	lda #$FF
	sta bgs
	inc nback
	jmp bp_inv

; the pairs' list at port 1 (16 rows): every slot without a group gets one, BMWB of them at most (a count of tiles: 3 a group). A = 1
; the list done, 0 the count spent, $FF no group left. BANDT at MPR4
bens:	lda #16
	sta bgk
.r:	lda $1A10
	beq .n
	sta bge
.e:	lda $1A10
	ldx $1A10
	lda NS,x
	bne .hv
	lda BMWB
	cmp #3
	bcc .o
	sbc #3
	sta BMWB
	stx bsl
	jsr bgn2
	bne .nx
	inc a                   ; (no group to have now: as done)
	rts
.hv:	lda $1A10
	lda $1A10
	lda $1A10
.nx:	dec bge
	bne .e
.n:	dec bgk
	bne .r
	lda #1
	rts
.o:	lda #0
	rts
; slot bgs's group: the next three tiles of the runs, its images k = 1 .. 3 from the address port 1 gives next (read in any case).
; A = the group + 1, 0 none left. BANDT at MPR4 (put back)
bgnew:	lda bgs
	sta bsl
bgn2:	lda $1A10
	sta bga
	lda $1A10
	sta bga + 1
	lda $1A10
	sta bga + 2
	lda ngr
	bne .g
	lda bpre                ; (the claim held: no group yet: the band's restore of its sets, which still runs in the idle until
	bne .gn                 ; the switch, writes every run of the near groups: measured on MIXX and VXT0's run too)
	ldx ngx
	lda NGR + 2,x
	bne *+5
.gn:	jmp .no
	sta ngr
	lda NGR,x
	sta ngt
	lda NGR + 1,x
	sta ngt + 1
	inx
	inx
	inx
	stx ngx
.g:	dec ngr
	inc ngn
	ldx ngn
	lda ngt
	sec
	sbc #1
	sta NGL - 1,x
	lda ngt + 1
	sbc #0
	sta NGH - 1,x
	lda ngt                 ; MAWR = the tile * 16
	ldy ngt + 1
	jsr bx16
	lda ngt
	clc
	adc #3
	sta ngt
	bcc *+5
	inc ngt + 1
	lda #$40
	tam #4
	jsr bup1
	jsr bup1
	jsr bup1
	lda #BANDT
	tam #4
	ldx bsl
	lda ngn
	sta NS,x
	rts
.no:	lda #0
	rts
; xm = (the tile A, Y) * 16
bx16:	asl a
	sta xm
	tya
	rol a
	asl xm
	rol a
	asl xm
	rol a
	asl xm
	rol a
	sta xm + 1
	rts
bup1:	lda bga
	sta $1A02
	lda bga + 1
	sta $1A03
	lda bga + 2
	sta $1A04
	lda FRAMES
	pha
	vsel 0
	lda xm
	sta $0002
	lda xm + 1
	sta $0003
	vsel 2
	tia $8000, $0002, 32
	pla
	cmp FRAMES
	bne bup1                ; (a vblank inside moved MAWR: the tile again)
	lda bga
	clc
	adc #32
	sta bga
	bcc .c
	inc bga + 1
	bne .c
	inc bga + 2
.c:	lda xm
	clc
	adc #16
	sta xm
	bcc *+5
	inc xm + 1
	rts
bmfil:	lda bgs
	sta bsl
bfc:	lda BMFT                ; (the image: the pair's k = 1 image + 32 (k - 1))
	and #3
	tax
	lda $1A10
	clc
	adc OFL,x
	sta bga
	lda $1A10
	adc OFH,x
	sta bga + 1
	lda $1A10
	adc OFH,x
	sta bga + 2
	lda mrl
	bne .g
	ldx mrx
	cpx #MRNL               ; (the claim held: the sets' tail from the switch on only)
	bcc *+7
	lda bpre
	bne .no
	lda MRN + 2,x
	beq .ev
	sta mrl
	lda MRN,x
	sta mtt
	lda MRN + 1,x
	sta mtt + 1
	inx
	inx
	inx
	stx mrx
.g:	dec mrl
	lda mtt
	sta btl
	lda mtt + 1
	sta bth
	inc mtt
	bne *+5
	inc mtt + 1
	jmp .up
.no:	lda #0
	rts
.ev:	lda BMNE                ; (the fill ahead takes free tiles only)
	bne .no
	lda BMNW
	beq .sc
	stz BMNW
	lda BMDM
	sta vd
	lda #7
	sta vtr
	bra .np
.sc:	ldx vs
.s1:	lda MTH,x
	bne .hit
	inx
	cpx #64
	bne .s1
.np:	lda vtr
	beq .no
	dec vtr
	lda vd
	sec
	sbc BMDR
	bne *+4
	lda #7
	cmp #8
	bcc *+4
	lda #1
	sta vd
	cmp BMDM
	beq .np
	cmp BMDL
	beq .np
	tax
	lda MOL9 - 1,x
	sta .s1+1
	sta .s2+1
	sta .s3+1
	lda MOH9 - 1,x
	sta .s1+2
	sta .s3+2
	dec a
	dec a
	sta .s2+2
	clx
	bra .s1
.hit:	sta bth
.s2:	lda MTL,x
	sta btl
.s3:	stz MTH,x
	stx vs
.up:	lda btl
	ldy bth
	jsr bx16
	lda #$40
	tam #4
	jsr bup1
	lda #BANDT
	tam #4
	ldx BMFT
	lda MOL9 - 1,x
	sta .w1+1
	sta .w2+1
	lda MOH9 - 1,x
	sta .w2+2
	dec a
	dec a
	sta .w1+2
	ldx bsl
	lda btl
.w1:	sta MTL,x
	lda bth
.w2:	sta MTH,x
	rts
; (vector 8; the fill ahead: bpos6's bwrm) the mid pairs' list at port 1: every pair without a tile at phase BMFT gets one (bfc: free
; tiles only, BMNE), BMWB of them at most. A = 1 the list done, 0 the count spent or no free tile now. BANDT at MPR4
bmwarm:	ldx BMFT
	lda MOL9 - 1,x
	sta .t+1
	lda MOH9 - 1,x
	sta .t+2
	lda #6
	sta bgk
.r:	lda $1A10
	beq .n
	sta bge
.e:	bit $1A10
	ldx $1A10
.t:	lda MTH,x
	beq .f
	bit $1A10
	bit $1A10
	bit $1A10
.nx:	dec bge
	bne .e
.n:	dec bgk
	bne .r
	lda #1
	rts
.f:	lda BMWB
	beq .o
	dec BMWB
	stx bsl
	jsr bfc
	bne .nx                 ; (no free tile now: 0, again on the next pass)
.o:	rts
c9end:
	.if (c9end > C8RAM + C9LEN - 1)
	.fail
	.endif
	.org C8RAM + C9LEN - 1
	.db $A5
