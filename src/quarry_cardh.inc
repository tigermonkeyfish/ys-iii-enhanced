HLEN       = $0600

hjt:	.dw hpas                ; 0: every pass with the bridge not drawing, after cpos and before the fourth image's bp_idle tests
	.dw hidl                ; 2: every idle of the seams' image (A not zero: the idle's work was this image's)
hlf:	.db 0           ; band 1 let go at 624 going left on this pass (hpas): the idle after it is the claim's fill
hfs:	.db 0           ; the mid cache's fill ahead after the left take-over: the next phase (6 .. 1), 0 none
hmp:	.db 0           ; band 1's mid groups after the right take-over: the next phase to upload (1 .. 3: mid phase 2 p), 0 all in
hmg:	.db 0           ; ... and its next group
hpn:	.db 0           ; hpas: the phase this pass needs
hc:	.db 0           ; hsmg: tiles left this call, the image (16 bits), the tile's address
hil:	.db 0
hih:	.db 0
hvl:	.db 0
hvh:	.db 0
hf:	.db 0           ; hidl: FRAMES at its entry (its steps go on until the vblank)
hlim:	.db 0           ; hmw: 1 it stops at the vblank; 1: it stopped for want of a free tile
hnf:	.db 0
hx:	.db 0           ; the cache's 40 tiles more this claim: 0 not given, 1 given (the run they came before waits: hxt, hxn), 2 that run back
hxt:	.dw 0
hxn:	.db 0
hxl:	.db <$6BF       ; ... their first tile's low byte (hngr: by the near groups' runs)
hcs:	.db 0           ; the mix set band 1's picture before its pass at 624 uses
hrb:	.db 0           ; (quarry-turn-624) the idle stood band 1 down at 624 with its lists saved (hsave) and neither engine has drawn since
hib:	.db 0
hk:	.db 0           ; hp1: the phase's k (its image's offset from the pair's k = 1 image: OFL / OFH)

hpas:	tma #4
	pha
	lda #C7BANK
	tam #4
	lda #<(BLET + 1)        ; handover's band test as assembled
	sta ho_bl
	stz hlf
	lda bpre                ; (the bridge does not draw and holds no claim: its fill ahead is void, and the next claim's near groups
	bne .p0                 ; start from the runs as assembled, its cache's 40 tiles more are to give again)
	stz hfs
	stz hx
	lda #1
	jsr hngr
.p0:	lda act
	cmp #2
	bne *+5
	jmp .band
	stz hmp                 ; (band 1 does not draw: a window or a stand-down took what was left of its mid groups with it)
	cmp #0
	beq *+5
.xj:	jmp .x
	lda hrb
	beq .n6
	lda ldir
	dec a
	bne .n6
	lda pw_state
	ora MENU
	ora wsd
	ora vxph
	bne .n6
	lda <LOCKZP
	and #$18
	bne .n6
	lda vxok
	beq .n6
	lda s7ev + $2000
	beq .n6
	lda hcl
	cmp #<(626 + 16)
	lda hch
	sbc #>(626 + 16)
	bcc .n6
	stz hrb
	lda #6
	sta pw_state
	lda #1
	sta s7dx + $2000
.n6:	lda pw_state
	cmp #6
	bne .l2
	lda hcl                 ; below 624: dropped (as sidle's .dc), and the left take-over's test
	cmp #<(624 + 16)
	lda hch
	sbc #>(624 + 16)
	bcs .r
	stz pw_state
	stz s7dx + $2000
	bra .l2
.r:	lda hcl                 ; 624 itself: wait (the band lets go there)
	cmp #<(626 + 16)
	lda hch
	sbc #>(626 + 16)
	bcc .xj
	lda s7dx + $2000        ; (the lists not set up yet: the idle after the stand-down's pass did not come: now)
	beq .xj
	dec a
	bne .r2
	ldy #2
	jsr c7tr
.r2:	lda #GUPMAX
	sta bugm + 1
	lda #1                  ; (band_upl's tail with mready 0 is cmu6, which copies each mid group out first: over the copies the
	sta mready              ; bridge holds, with the bridge's tiles)
.du:	lda gqh
	cmp gqt
	beq .dm
	lda #15                 ; band_upl
	jsr callb
	bra .du
.dm:	lda #1                  ; the mid groups' phases from the store: 2 first (628's picture; 626's is the odd set's): in the idles
	sta hmp                 ; from this pass's on (hidl), and before the rows of a pass that needs one not yet in (.ens)
	stz hmg
	lda rnpair              ; (mready stays set, nothing is copied out again)
	sta mci
	lda #4
	sta pw_state
	lda #2
	sta act
	inc nback
	jsr dvz
	stz ldir
	stz s7dx + $2000
	bra .x
.l2:	lda ldir
	bpl .x
	lda hcl
	cmp #<(610 + 16)
	lda hch
	sbc #>(610 + 16)
	bcc .x
	lda hcl
	cmp #<(622 + 16 + 1)
	lda hch
	sbc #>(622 + 16 + 1)
	bcs .x
	jsr hcond
	bne .x
	jsr hclaim
	lda CAMX                ; the fill ahead: from the phase after this camera's
	lsr a
	and #7
	dec a
	sta hfs
.x:	jsr hflg
	pla
	tam #4
	rts
; ---- band 1 draws
.band:	stz hrb
	lda hcl                 ; (below 624: no picture of band 1's; the idle after its pass at 624 did not come to stand it down: now, and
	cmp #<(624 + 16)        ; the left take-over's test)
	lda hch
	sbc #>(624 + 16)
	bcs .b1
	jsr hsd
	jmp .l2
.b1:	lda ldir
	bpl .ens
	lda CAMX
	and #15
	bne .ens
	lda hcl
	cmp #<(BLET + 1)
	lda hch
	sbc #>(BLET + 1)
	bcs .ens
	stz ho_bl               ; going left at 624: no let-go on this pass (handover's test: below camera 496 only), band 1 draws its
	inc hlf                 ; plain picture; the idle after it stands the band down, claims and fills (hidl)
	lda #C6BANK
	tam #4
	lda csh + $2000         ; (the mix set the picture on the screen, 626, uses: this pass's plain picture clears it)
	sta hcs
	bra .x
.ens:	lda hmp                 ; the mid groups' phase this pass's picture shows (mid phase 2 p, p = 1 .. 3) must be in
	beq .x
	lda CAMX
	and #2
	bne .x
	lda CAMX
	lsr a
	lsr a
	and #3
	beq .x
	sta hpn
.el:	lda hmp
	beq .x
	cmp hpn
	beq .eu
	bcs .x
.eu:	lda #12
	jsr hsmg
	bra .el

; the claim as the fourth image's bp_idle makes it (b_exit, the tables emptied, bgs $FD, bpre 1); the first overlay's fill ahead
; has nothing to do (this image's)
hclaim:	tma #4
	pha
	lda #C6BANK
	tam #4
	lda #8
	sta bwj + $2000
	pla
	tam #4
	stz hx
	jsr .c
	lda mci                 ; (as the first overlay's bpos6 after a claim) every mid group the band has not copied out: copied (the cache
	pha                     ; takes their tiles; the band's exits put them back: mcop 45)
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
	rts
.c:	tma #6
	pha
	jmp bp_clm
hsd:	stz hmp
	lda #9
	jsr callb
	jsr sprest
	stz act
	inc nhand
	jmp dvz
; Z set: the bridge may claim now, as the fourth image's bp_idle tests it, and without a long copy-out: the band's copies of the borrowed
; runs and of the odd set are held (vxok, cocp; the mid groups it has not copied, two as a rule, are hclaim's)
hcond:	lda bpre
	ora pw_state            ; (a set-up of the band's under way: the fourth image's own path)
	ora MENU
	ora wsd
	ora vxph
	bne .no
	lda <LOCKZP
	and #$18
	bne .no
	lda brst
	dec a
	bne .no
	lda vxok
	beq .n1
	tma #4
	pha
	lda #C6BANK
	tam #4
	ldx cocp + $2000
	pla
	tam #4
	txa
	beq .n1
	tma #6
	pha
	lda #CBANK
	tam #6
	ldx svd
	pla
	tam #6
	txa
	beq .n1
	lda #0                  ; (Z set: CLA leaves the flags)
	rts
.n1:	lda #1
.no:	rts
; the near groups' second and fourth runs and the cache's 40 tiles more, by the mix set band 1's picture on the screen uses (A = 0:
; set 0, tiles $680-$6BB: the groups at $6C0 x 21, then $680 x 5, the 40 from $68F; else as assembled: $680 x 21, $6E7 x 5, the 40
; from $6BF). The same tiles of the same pool either way (set 1's restore puts them back)
hngr:	tax
	bne .a
	lda #<$6C0
	ldx #<$680
	ldy #<$68F
	bra .w
.a:	lda #<$680
	ldx #<$6E7
	ldy #<$6BF
.w:	sta NGR + 3
	stx NGR + 9
	sty hxl
	rts
hsave:	lda bcn
	cmp #CN0
	bne .x
	lda #BANDT
	tam #4
	stz $1A22
	lda #$E0
	sta $1A23
	lda #KTH
	sta $1A24
	stz .c + 1
	lda #>NLC
	sta .c + 2
	ldx #64
.c:	tia $9000, $1A20, 32
	lda .c + 1
	clc
	adc #32
	sta .c + 1
	bcc *+5
	inc .c + 2
	dex
	bne .c
	lda #C7BANK
	tam #4
	lda #1
	sta s7ev + $2000
	sta hrb
.x:	rts
; hfl (bank 0, idlelate's test): something is left for an idle
hflg:	lda hlf
	ora hfs
	ora hmp
	sta hfl
	rts

; ---------------------------------------------------------------- the idle (and the wait for the sprite table's DMA after a pass that
hidl:	tma #4
	pha
	lda FRAMES
	sta hf
	lda hlf
	beq .b
	stz hlf
	lda act                 ; (band 1 drew 624, its plain picture, on this frame's pass)
	cmp #2
	bne .b
	lda brm
	cmp #21
	beq .b
; the idle after band 1's pass at 624 going left: its 626 picture is on the screen (or, after the vblank, its 624: no tile of ours)
	jsr hsave
	jsr hsd
	jsr hcond
	bne .b
	jsr hclaim
	lda hcs                 ; (the mix set the 626 picture uses)
	jsr hngr
	lda #BANDT
	tam #4
	ldy #$FF                ; every near pair of the first period (cn 79: LB + $010), or 22 groups: the single one and the mix
	ldx #136                ; set's 21, when a band group sits in the run at $15A
.vg:	lda GSLOT - 1,x
	cmp #VXG
	bcs *+4
	ldy #66
	dex
	bne .vg
	sty BMWB
	stz bpre                ; (the claim's gate on the near groups' runs open for this)
	lda #$10
	ldx #$F0
	jsr hlb
	jsr bens
	inc bpre                ; (the claim is held)
	lda #7
	jsr hph
	lda #6
	sta hfs
	jsr hfa
	jsr hflg
	pla
	tam #4
	lda #1
	rts
.b:	lda act
	cmp #2
	bne .n
	lda brm
	cmp #21
	bne .c
	stz hrb
; (quarry-turn-624: on every claim, not a left one only) the cache's 40 tiles more, once a claim, from the bridge's first idle on (the
; pools' tiles are the bridge's then, band 1's and the open quarry's pictures off the screen): the mix sets' tiles the near groups do
; not take (hngr), given before the rest of the run the cache is in, which goes on when they are spent. With them seven phases of
; 35-38 pairs fit (254 tiles; the runs hold 241)
	lda hx
	bne .i1
	lda mtt
	sta hxt
	lda mtt + 1
	sta hxt + 1
	lda mrl
	sta hxn
	lda hxl
	sta mtt
	lda #>MIXBASE
	sta mtt + 1
	lda #40
	sta mrl
	inc hx
	bra .i2
.i1:	dec a
	bne .i2
	lda mrl
	bne .i2
	inc hx
	lda hxn
	beq .i2
	sta mrl
	lda hxt
	sta mtt
	lda hxt + 1
	sta mtt + 1
.i2:	jsr hfa                 ; the bridge draws: the mid cache's fill ahead
	bra .n
.c:	lda hmp                 ; band 1 draws: its mid groups' phases
	beq .n
.ml:	lda #2
	jsr hsmg
	lda hmp
	beq .n
	lda FRAMES
	cmp hf
	beq .ml
.n:	jsr hflg
	pla
	tam #4
	lda FRAMES              ; (not zero: the vblank came: the idle is over, nothing after this in the seams' sidle)
	eor hf
	rts
; the mid cache's fill ahead from phase hfs down, free tiles only, until the vblank. While the claim is held (the idle at 624:
; band 1's 626 picture may be on the screen) phases 6 and 5 only: with 7 the cache's first 105 tiles, which that picture never names
hfa:	lda #BANDT
	tam #4
.l:	lda hfs
	beq .x
	ldx bpre
	beq .g
	cmp #5
	bcc .x
.g:	jsr hphl
	beq .s
	dec hfs                 ; (the phase's list is done)
	lda FRAMES
	cmp hf
	beq .l
.x:	rts
.s:	lda hnf
	beq .x                  ; (the vblank)
	stz hfs                 ; (no free tile left: the passes take it from here)
	rts

; A = a mid phase (1 .. 7): every pair of its list without a tile at it gets one (free tiles only). hph: the whole list; hphl: until
; the vblank. A = 1 the list done, 0 not (hnf 1: no free tile left; 0: the vblank came). BANDT at MPR4
hph:	stz hlim
	bra hp1
hphl:	ldx #1
	stx hlim
hp1:	sta BMFT
	sta BMNE                ; (free tiles only: not zero)
	stz hnf
	ldx #$F4                ; phases 4 .. 7: column 79's list (LB + $800 x 40 + $460)
	cmp #4
	bcs *+4
	ldx #$EC                ; 1 .. 3: column 78's
	lda #$60
	jsr hlb
; (as the fourth image's bmwarm, with the vblank's test before each tile: one pass over the list an idle, not one a step)
	ldx BMFT
	lda MOL9 - 1,x
	sta .t + 1
	sta .w1 + 1
	sta .w2 + 1
	lda MOH9 - 1,x
	sta .t + 2
	sta .w2 + 2
	dec a
	dec a
	sta .w1 + 2
	txa
	and #3
	sta hk
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
.f:	lda hlim
	beq .g
	lda FRAMES
	cmp hf
	beq .g
.v0:	lda #0                  ; (the vblank; Z set)
	rts
.g:
; (the tile, as the fourth image's bfc for a free one, in line: 150 cycles a tile less) port 1 gives the pair's k = 1 image's place
.g2:	stx bsl
	ldy hk
	lda $1A10
	clc
	adc OFL,y
	sta hil
	lda $1A10
	adc OFH,y
	sta hih
	lda $1A10
	adc OFH,y
	sta hib
	lda mrl                 ; the next tile of the cache's runs
	bne .tl
	ldx mrx
	cpx #MRNL               ; (the claim held: the sets' tail from the switch on only)
	bcc *+7
	lda bpre
	bne .nf0
	lda MRN + 2,x
	bne .rn
.nf0:	inc hnf                 ; (no free tile left)
	lda #0
	rts
.rn:	sta mrl
	lda MRN,x
	sta mtt
	lda MRN + 1,x
	sta mtt + 1
	inx
	inx
	inx
	stx mrx
.tl:	dec mrl
	lda mtt
	sta btl
	asl a
	sta hvl
	lda mtt + 1
	sta bth
	rol a
	asl hvl
	rol a
	asl hvl
	rol a
	asl hvl
	rol a
	sta hvh
	inc mtt
	bne *+5
	inc mtt + 1
	lda #$40
	tam #4
.up:	lda hil
	sta $1A02
	lda hih
	sta $1A03
	lda hib
	sta $1A04
	lda FRAMES
	pha
	vsel 0
	lda hvl
	sta $0002
	lda hvh
	sta $0003
	vsel 2
	tia $8000, $0002, 32
	pla
	cmp FRAMES              ; (a vblank in the middle: the tile again)
	bne .up
	lda #BANDT
	tam #4
	ldx bsl
	lda btl
.w1:	sta MTL,x
	lda bth
.w2:	sta MTH,x
	jmp .nx
; port 1 at A (low), X (mid) of region 1's lists past period 32 (the visit's scan side: as sinit sets RLBH + 1, + 1)
hlb:	pha
	lda nsd
	eor #1
	asl a
	asl a
	asl a
	adc #CR2H + 1
	tay
	pla
	jmp cb1
; band 1's mid groups' phase hmp (mid phase 2 hmp) from the store: region 0's image 7 g + 2 hmp - 1 into the group's tile hmp - 1, A
; tiles a call from group hmg; the phase done: the next one (after 3: 0, all in). Port 0 through bank $40 at MPR4 (put back)
hsmg:	sta hc
	tma #4
	pha
	lda #$40
	tam #4
.g:	ldx hmg
	cpx rnpair
	bcc .c
	stz hmg
	lda hmp
	inc a
	and #3
	sta hmp
.e:	pla
	tam #4
	rts
.c:	txa                     ; the image: 7 g + 2 hmp - 1 (16 bits)
	stz hih
	asl a
	rol hih
	asl a
	rol hih
	asl a
	rol hih
	sec
	sbc hmg
	bcs *+5
	dec hih
	sta hil
	lda hmp
	asl a
	dec a
	clc
	adc hil
	sta hil
	bcc *+5
	inc hih
	lda hmp                 ; the tile: the group's first + hmp - 1; its address
	dec a
	clc
	adc MGL,x
	sta hvl
	lda MGH,x
	adc #0
	asl hvl
	rol a
	asl hvl
	rol a
	asl hvl
	rol a
	asl hvl
	rol a
	sta hvh
.i:	lda hih                 ; the image's place: $15:D000 + 32 i
	lsr a
	lda hil
	ror a
	lsr a
	lsr a
	clc
	adc #IMGM
	sta $1A03
	lda hil
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $1A02
	lda #CR3H
	sta $1A04
	lda FRAMES
	pha
	vsel 0
	lda hvl
	sta $0002
	lda hvh
	sta $0003
	vsel 2
	tia $8000, $0002, 32
	pla
	cmp FRAMES              ; (a vblank in the middle: the tile again)
	bne .i
	inc hmg
	dec hc
	beq *+5
	jmp .g
	pla
	tam #4
	rts
hend:
	.if (hend > C8RAM + C9LEN + HLEN)
	.fail
	.endif
