
BS0        = $700
BS1        = $746
BLCAP      = 24
NGMAX      = 54
NS         = NLC        ; (BANDT; the band's near lists, which band_init makes again) per near slot: its group + 1, 0 none (256)
NGL        = NLK        ; per group: its first tile - 1, low / high
NGH        = NLK + $40
MTL        = NLA        ; (BANDT; the band's near lists too) the mid cache: per phase dm = 1 .. 7 (+ 64 (dm - 1)), per mid slot: the tile
MTH        = NLG        ; that holds the pair's image at that phase, low / high (high 0: none)
BMV        = NLA + $1C0 ; the mid walk's values (the fourth image reads them): this pass's phase, the last picture's, the walk's direction
BMDM       = BMV        ; (1 / $FF), the image's offset from the pair's k = 1 image (16 bits), a walk began (the victim search starts again)
BMDL       = BMV + 1
BMDR       = BMV + 2
BMNW       = BMV + 5
BMFT       = BMV + 6    ; the phase a tile is given at (the pass's; the fill ahead's); the fill ahead (free tiles only); its count of tiles left
BMNE       = BMV + 7
BMWB       = BMV + 8
BWN        = 28         ; the fill ahead's tiles a pass
MGN        = 45         ; the band's mid groups (MGL / MGH: every one copied out while the bridge draws)
BP15       = $3C00 + 32 * 4 + 30
BK15       = MSAVE + 64 + 30           ; the kept copy's (the third merged palette: mpal)

c9ok:	.db 0           ; the switch's image is in place (1; $FF: its copy was not right)
bgy:	.db 0
bgx:	.db 0
bnr:	.db 0           ; the ranks of the camera being uploaded or patched
bdr:	.db 0, 0        ; per set: ranks uploaded of its camera
bdm:	.db 0, 0        ; per set: its camera's ends0 images uploaded (k = 0)
bcap:	.db 0           ; ranks this upload may take ($FF: all, and the mid pairs)
bgc:	.db 0
bwj:	.db 0           ; the fill ahead: its step (0 the near pairs, 1 .. 7 the mid pairs' phases, 8 done), the even column of its lists
bwc:	.db 0
BSL:	.db <BS0, <BS1

; ---------------------------------------------------------------- the switch (vector 28): in the fourth image (quarry_cardc.inc), copied
c6ext:	tma #6
	pha
	lda #C5BANK
	tam #6
	bcs .p
	jsr bpos6
	bra .x
.p:	jsr bpass
.x:	pla
	tam #6
	rts
bpos6:	lda c9ok
	bpl *+3
	rts
	bne .go
	lda brst
	dec a
	beq .ld
	jmp brm0                ; (never set without the image: a visit that ended on the bridge left it, and handover's band test)
.ld:
	tma #4
	pha
	tma #6
	pha
	cla
	ldx #>($2000 + C8LEN)
	ldy #C6CH
	jsr cbase
	lda #$40
	tam #4
	lda #C8BANK
	tam #6
	ldx #C9LEN / 32
.d:	tii $8000, C8RAM + $6000, 32
	lda .d+3
	clc
	adc #32
	sta .d+3
	bcc *+5
	inc .d+4
	dex
	bne .d
	dec c9ok
	lda c9mk + $6000
	cmp #'B'
	bne .b
	lda C8RAM + $6000 + C9LEN - 1
	cmp #$A5
	bne .b
	lda #1
	sta c9ok
.b:	pla
	tam #6
	pla
	tam #4
	rts                     ; (the switch from the next pass on)
.go:	cly
	jsr c8tr
	lda bgs                 ; ($FD: the bridge claimed its tiles on this pass: the fourth image fills them from the next pass on) the
	cmp #$FD                ; tiles its mid cache takes, copied out by the band's own protocol, whose exits put them back (vxall's
	bcc .x                  ; put-back): the odd set's (cocopy; cores) and every mid group's (mgxfer: those the band has not copied; mcop)
	beq *+5                 ; ($FE the claim held, $FF the switch's pass: the fill ahead)
	jmp bwrm
	stz bwj
	lda cocp
	bne *+5
	jsr cocopy
	lda mci
	pha
.m:	lda mcop
	cmp #MGN
	bcs .md
	sta mci
	cly
	jsr mgxfer
	inc mcop
	bra .m
.md:	pla
	sta mci
.x:	rts
; (the claim held, the switch's pass) the fill ahead, BWN tiles a pass at most, free tiles only: step 0 the near pairs' groups of the
; period the bridge will switch at (the next aligned camera the way the camera goes), steps 1 .. 7 the mid pairs' tiles at the phases
; of the 7 cameras after it, in their order (going right 1 .. 7 from the lists of the even column bwc and the odd one after it; going
; left 7 .. 1). What it does not reach, the passes fill as they meet it.
bwrm:	tma #4
	pha
	lda #BANDT
	tam #4
	lda #BWN
bw_n       = * - 1          ; (quarry-seams-2: BWA while the open quarry draws, srp)
	sta BMWB
	sta BMNE
.s:	lda ldir
	bmi .l
	lda pn
	cmp #1
	lda cn
	adc #1
	bra .m
.l:	lda cn
	dec a
	dec a
.m:	and #$FE
	sta bwc
	cmp #CN0 - 1            ; (never past region 1)
	bcs .x
	ldx bwj
	cpx #8
	bcs .x
	txa
	bne .mid
	lda bwc
	bit ldir
	bpl .ps
	inc a
	inc a
	bra .ps
.mid:	bit ldir
	bpl *+5
	eor #7                  ; (8 - j)
	inc a
	sta BMFT
	and #3
	sta ck
	lda BMFT
	cmp #4                  ; (phases 4 .. 7: the odd column's list)
	lda bwc
	adc #0
.ps:	jsr cpsel
	bcs .dn
	lda bwj
	bne .wm
	jsr bens6b
	bra .rt
.wm:	ldy #4
	jsr clb
	lda #$60
	jsr cb1
	ldy #8
	jsr c8tr
.rt:	beq .x                  ; (the count spent: this step again on the next pass)
	bpl .dn
	lda #7                  ; (no free tile left: done)
	sta bwj
.dn:	inc bwj
	bra .s
.x:	pla
	tam #4
	rts
; ---------------------------------------------------------------- a pass
bpass:	tma #4
	pha
	lda #BANDT
	tam #4
	stz nmix                ; (band_row's tail: no mix job, no group upload)
	lda #1
	sta nwfull
	lda pn
	sta ck
	lda CAMX
	sta cxl
	lda CAMX + 1
	sta cxh
	lda cn
	jsr cpsel
	bcs .xj
	lda crg
	bne *+5
.xj:	jmp .x                  ; (never: bpos stands down outside region 1)
	lda bgs                 ; ($FF: the take-over's first pass)
	inc a
	bne .s
	lda #$FF
	sta cper
	sta csh
	sta ctl
	sta cth
	sta ctl + 1
	sta cth + 1
	sta ctl + 2             ; (the odd set's tiles are the mid cache's)
.s:	lda ck
	beq .t
	lda cbp
	cmp cper
	bne .t
	lda crg
	cmp cprg
	beq .nt
.t:	jsr cltpl
.nt:	lda bgs
	inc a
	bne .nf
	stz bgs
	jsr bens6               ; (the take-over: this period's near pairs in their groups)
.nf:	lda cn
	and #1
	ora ck
	bne .own
	lda #$FF                ; a plain picture: the next camera's images ahead
	sta bcap
	lda ldir
	bpl .a
	lda cxl
	and #15
	bne .a
	lda #BLCAP
	sta bcap
.a:	jsr cnxt
	bcs .xk
	lda crg
	beq .xk
	lda csh                 ; (quarry-finish) into the set the picture still on the screen does not use: this pass's plain picture is
	clx                     ; shown from the next vblank only, and the pass before's set was written under it (set 0 whatever was
	jsr cpick               ; shown: a frame of the wrong ranks at every plain pass, both ways)
	sta cs
	jsr bupl
.xk:	lda #$FF
	sta csh
	jmp .x
.own:	ldx csh                 ; the shown set if it holds this camera (standing), else the other one
	bmi .pk
	lda ctl,x
	cmp cxl
	bne .pk
	lda cth,x
	cmp cxh
	bne .pk
	txa
	bra .st
.pk:	txa
	clx
	jsr cpick
.st:	sta cs
	lda #$FF
	sta bcap
	jsr bupl
	lda ck                  ; (k = 0 of an odd column: the ends0 ranks' images into the set, once)
	bne .md
	ldx cs
	lda bdm,x
	bne .md
	inc bdm,x
	lda #$40
	tam #4
	jsr bue0
	lda #BANDT
	tam #4
.md:	jsr bmid
	lda ck
	beq .e0
	jsr bpairs
	ldy #2
	jsr clb
	bra .en
.e0:	ldy #4
                        ; (no template again after a k = 0 picture: every ends0 cell is rewritten by the k >= 1 lists, 280 of 280
                        ; on the store, and the mid pairs' cells by the same list)
	jsr clb
	lda #$20
.en:	jsr cb1
	ldx cs
	lda BSL,x
	ldx #1
	jsr cendx
	lda cs
	sta csh
	lda ck                  ; the k = 2 pass: the period ahead's near pairs in their groups
	cmp #2
	bne .x
	lda cn
	clc
	adc ldir
	jsr cpsel
	bcs .x
	lda crg
	beq .x
	jsr bens6
.x:	pla
	tam #4
	rts
; A = n: A / X / Y = LB + $300 + 3 n, the period's ups from rank n
bups:	sta ct + 3
	asl a
	clc
	adc ct + 3
	sta ct + 3
	lda #3
	adc clbm
	tax
	ldy clbh
	lda ct + 3
	rts
; ct / ct + 1 = (set cs's first tile + A) * 16
bmawr:	ldx cs
	clc
	adc BSL,x
	sta ct
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$70
	sta ct + 1
	lda ct
	asl a
	asl a
	asl a
	asl a
	sta ct
	rts
; camera cxl / cxh (period cbp, k ck) into set cs: its ranks from where the set's count stands, bcap of them at most
bupl:	ldx cs
	lda ctl,x
	cmp cxl
	bne .nw
	lda cth,x
	cmp cxh
	beq .rs
.nw:	lda cxl
	sta ctl,x
	lda cxh
	sta cth,x
	stz bdr,x
	stz bdm,x
.rs:	ldy #0
	jsr clb
	jsr cb1
	lda $1A10
	sta bnr
	lda ck
	beq .rd
	ldx cs
	lda bnr
	sec
	sbc bdr,x
	beq .rd
	cmp bcap
	bcc *+5
	lda bcap
	sta cun
	sta bgc
	lda bdr,x
	jsr bmawr
	ldx cs
	lda bdr,x
	jsr bups
	jsr cb1
	lda ck                  ; + 32 (k - 1)
	dec a
	asl a
	asl a
	asl a
	asl a
	asl a
	sta cuo
	lda #$40
	tam #4
	jsr cupr
	lda #BANDT
	tam #4
	ldx cs
	lda bdr,x
	clc
	adc bgc
	sta bdr,x
.rd:	rts
; (k = 0) the ends0 ranks' images, the one before each record's k = 1 image
bue0:	ldy #4
	jsr clb
	lda #$20
	jsr cb1
	lda #16
	sta crk
.r:	lda $1A10
	beq .n
	sta ct + 2
.e:	lda $1A10
	lda $1A10               ; the rank
	pha
	jsr bmawr
	pla
	jsr bups
	jsr cb2
	lda $1A20
	sec
	sbc #32
	pha
	lda $1A20
	sbc #0
	tax
	lda $1A20
	sbc #0
	tay
	pla
	jsr cup1
	lda $1A10
	dec ct + 2
	bne .e
.n:	dec crk
	bne .r
	rts
bmid:	lda BMDM                ; (the last picture's phase: on the screen until this one is)
	sta BMDL
	lda #1
	sta BMNW
	lda ldir                ; (set by the camera's motion before any picture with a mid pair)
	sta BMDR
	stz BMNE
	lda cn
	and #1
	asl a
	asl a
	ora ck
	sta BMFT
	sta BMDM
	tax
	lda MOL - 1,x
	sta .a+1
	sta .p+1
	sta .o+1
	lda MOH - 1,x
	sta .a+2
	sta .o+2
	dec a
	dec a
	sta .p+2
	ldy #4
	jsr clb
	lda #$60
	jsr cb1
	lda #<(WIN + 66 * 10)
	sta .l+1
	sta .g+1
	sta .h+1
	lda #>(WIN + 66 * 10)
	sta .l+2
	sta .g+2
	sta .h+2
	lda #6
	sta crk
.r:	lda $1A10
	beq .n
	sta ct + 2
.e:	ldy $1A10
	ldx $1A10               ; the slot
.a:	lda MTH,x
	beq .f
	bit $1A10               ; (the address: not needed)
	bit $1A10
	bit $1A10
.p:	lda MTL,x
.l:	sta WIN,y
	iny
.g:	lda WIN,y
	and #$F0
.o:	ora MTH,x
.h:	sta WIN,y
.sk:	dec ct + 2
	bne .e
.n:	lda .l+1                ; the next row
	clc
	adc #66
	sta .l+1
	sta .g+1
	sta .h+1
	bcc .nc
	inc .l+2
	inc .g+2
	inc .h+2
.nc:	dec crk
	bne .r
	rts
.f:	stx bgs
	sty bgy
	ldy #6
	jsr c8tr
	ldx bgs
	ldy bgy
	ora #0
	bne .p
	bra .sk                 ; (no tile to have: the cell keeps the template's word)
MOL:	.db $00, $40, $80, $C0, $00, $40, $80
MOH:	.db >MTH, >MTH, >MTH, >MTH, (>MTH) + 1, (>MTH) + 1, (>MTH) + 1
bpairs:	ldy #0
	jsr clb
	lda #$10
	jsr cb1
	jsr cprow
	lda #16
	sta crk
.r:	lda ct
	sta .l+1
	sta .g+1
	sta .h+1
	lda ct + 1
	sta .l+2
	sta .g+2
	sta .h+2
	lda $1A10
	beq .n
	sta ct + 2
.e:	ldy $1A10
	ldx $1A10
	lda NS,x
	bne .hv
	jsr bgnew6
	beq .sk
	bra .w
.hv:	pha
	lda $1A10
	lda $1A10
	lda $1A10
	pla
.w:	tax
	lda NGL - 1,x
	clc
	adc ck
.l:	sta WIN,y
	iny
	lda NGH - 1,x
	adc #0
	sta ct + 3
.g:	lda WIN,y
	and #$F0
	ora ct + 3
.h:	sta WIN,y
.sk:	dec ct + 2
	bne .e
.n:	jsr cpnext
	dec crk
	bne .r
	rts
; slot X's group from the fourth image (port 1 gives the address next); A = the group + 1, 0 (Z) none left; Y kept
bgnew6:	stx bgs
	sty bgy
	ldy #2
	jsr c8tr
	ldy bgy
	ora #0
	rts
; period cbp's near pairs: every slot without a group gets one
bens6:	lda #$FF
	sta BMWB
bens6b:	ldy #0
	jsr clb
	lda #$10
	jsr cb1
	ldy #4
	jmp c8tr
