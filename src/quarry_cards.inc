SEAMH      = $1E        ; the card's bank of the segment (seam17.py's SEAM)
SLEN       = $0E00      ; the image's length (whole pages: port 3's offset is left at a page's start)
SPERM      = C7RAM + $0E00      ; (past the image) the open-quarry-side scan's slot -> the band's-side slot (the card's images' order)
SRN        = 5

sjt:	.dw sinit
	.dw sidle
	.dw sbx
	.dw spas
	.dw sxv
	.dw ssp
smk:	.db 'S', '7'            ; (pgload's check of the copy, with the last byte)
sjob:	.db 0
s7scl:	.db 0
s7scm:	.db 0
s7sbk:	.db 0
s7sdl:	.db 0
s7sdh:	.db 0
s7scn:	.db 0           ; a range's pieces left; the next range
s7sr:	.db 0
s7sx:	.db 0
s7sp:	.db 0
snne:	.db 0           ; the segment's counts: near-end tiles with parts; the far tiles it holds (then sjob 4's counter)
sftn:	.db 0
s7busy:	.db 0         ; sidle is inside ssrun; the camera's low byte at the last idle
s7kc:	.db 0
s7f:	.db 0
s7dx:	.db 0           ; the bridge's hand-over to band 1: 1 band_init in this idle, 2 the groups in a later frame's
s7f2:	.db 0
s7tb:	.db 0           ; the bridge stood down at 320 on the pass before (spas)
s7eb:	.db 0
s7ec:	.db 0
s7ev:	.db 0
s7tk:	.db 0           ; stk: a unit's ticks
s7rs:	.db 1
SRT:	.db $00, $88, BANDN, $80, 0
	.db $00, $A8, BANDF, $80, 0
	.db $00, $C0, BANDT, >FW, 33
	.db $80, $46, BANDT, >NEIDX, 4
	.db $00, $47, BANDT, >PROP2, 4

sinit:	tma #4
	pha
	lda #C6BANK
	tam #4
	lda #$80                ; (quarry-finish: the fourth image is not in yet, srest; bpos6 waits)
	sta c9ok + $2000
	lda rtag
	ora #CR3H
	sta RTPH + $2000
	sec                     ; (region 1's high byte is region 0's - 4)
	sbc #4
	sta RTPH + $2001
	lda nsd
	eor #1
	asl a
	asl a
	asl a
	ora #CR3H
	sta RLBH + $2000
	sec
	sbc #4
	sta RLBH + $2001
	pla
	tam #4
	lda #<cposb             ; (as c6fin: passbegin's cpos with the bridge's switch)
	sta pb_cv
	lda pw_state            ; the band set up (4, or held: 6; an entry at its side) with its mid groups' composition under way (mcomp,
	cmp #4                  ; in the set-up's passes) and a group half made: that group put back from its copy and counted as not
	bcc .k
	lda mready
	bne .k
	lda mcph
	dec a
	beq .k
	ldy #1
	jsr mgxfer
	dec mcop
.k:	lda pw_state
	cmp #6
	bne .c
	lda #4
	sta pw_state
.c:	lda #1
	sta card
	sta brst
	sta cvis
	lda #5
	sta cst
	lda #$4C
	jsr cpat
	stz di_bn
	stz bs_br
	tma #4
	pha
	lda #CBANK
	tam #4
	stz qi_bg - $4000
	lda #(624 + 16) >> 3    ; (bi_cam, there too: band_init's columns from the band's first, 80 at camera 624, not from 640's: the
	sta bi_c1 - $4000       ; hand-over at 624 sets the band up for the camera it is at)
	sta bi_c2 - $4000
	pla
	tam #4
	lda bgf
	beq .x
	lda #$40
	sta $1A22
	lda #$46
	sta $1A23
	lda #SEAMH
	sta $1A24
	lda $1A20
	sta snne
	lda $1A20
	cmp nk
	bne .x
	lda $1A20
	lda $1A20
	sta sftn
	sta SRT + 5 + 4
	stz $1A22
	lda #$44
	sta $1A23
	lda #SEAMH
	sta $1A24
	tai $1A20, SPERM, 136
	lda rtag
	ora #$C0
	sta SRT + 10 + 1
	lda snne                ; x 12
	asl a
	asl a
	sta s7sx
	asl a
	clc
	adc s7sx
	sta SRT + 4
	lda bgss
	cmp #SSGN
	beq .n
	cmp #SSGM
	beq .m
	cmp #SSEND
	bne .x
	lda bsr                 ; (band_setup's pieces under way: the console's)
	bne .x
	lda #3
	bra .j
.m:	lda #2
	bra .j
.n:	lda #1
.j:	sta sjob
	stz bgss
.x:	clc
	rts

srest:	jsr tok
	cmp #2
	beq .r
	stz $1A35
	ldx s7rs
	cpx #4
	beq .c9
	lda SRO - 1,x
	pha
	clc
	adc #$40
	sta $1A36
	pla
	clc
	adc #>C7RAM
	pha
	lda SRP - 1,x
	tax
	pla
	jsr pgcp
	stz $1A36               ; (port 3's offset as the preload left it)
	lda s7rs
	cmp #3
	bne .n
	lda C7RAM + SLEN - 1
	cmp #$A5
	bne .r                  ; (not right: again in the next idle)
.n:	inc s7rs
.r:	rts
.c9:	tma #4
	pha
	lda #C8BANK
	tam #4
	lda #>($2000 + C8LEN)
	sta $1A36
	lda #>(C8RAM + $2000)
	ldx #C9LEN / 64
	jsr pgcp
	lda #>($4000 + SLEN)    ; (quarry-handover) the hand-over's image: after this image in its segment (C6CH:4000 + SLEN), into the
	sta $1A36               ; third overlay's place past the fourth image
	lda #>(C8RAM + C9LEN + $2000)
	ldx #HLEN / 64
	jsr pgcp
	stz $1A36
	ldx #$FF
	lda c9mk + $2000
	cmp #'B'
	bne .b
	lda C8RAM + $2000 + C9LEN - 1
	cmp #$A5
	bne .b
	ldx #1
.b:	lda #C6BANK
	tam #4
	stx c9ok + $2000
	pla
	tam #4
	stz s7rs
	rts
SRO:	.db 2, 6, 10
SRP:	.db 16, 16, 16
sxv:	lda s7rs
	bne *+5
	jmp sxt
	rts
sidle:	lda s7rs
	beq *+5
	jmp srest
sihe:
	.if (sihe > C7RAM + $0200)
	.fail
	.endif
	lda s7busy              ; (ssrun's own way out comes through here)
	bne .x
	lda s7dx
	beq *+5
	jmp .dx
	ldy #2                  ; (quarry-handover) the hand-over's image's idle (hidl); not zero: the claim's fill at 624 going left was
	jsr h5                  ; this idle's work
	bne .x
	jsr swin
	lda sjob
	bne .sj
	jsr sfil
	jsr sebi
	jmp .ek
.sj:	tma #4
	pha
	lda hcl
	cmp #<(448 + 16)
	lda hch
	sbc #>(448 + 16)
	lda nsd
	beq .a
	bcc .sync
	bra .clk
.a:	bcs .sync
.clk:	jsr tok
	bne .o
	jsr sunit
	lda sjob
	bne .clk
	bra .o
.sync:	jsr sunit
	lda sjob
	bne .sync
.o:	pla
	tam #4
.x:	rts
.dx:	lda act
	beq *+5
	jmp .dc
	lda pw_state
	cmp #6
	beq *+5
	jmp .dn
	lda s7dx
	dec a
	bne .d2
	lda s7ev
	beq .bi
	jsr srst
	bra .b2
.bi:	cla                     ; band_init
	jsr callb
.b2:	lda FRAMES
	sta s7f2
	inc s7dx
	rts
.d2:                            ; (quarry-handover: the uploads and the take-over are the pass's at 626 now, hpas in the hand-over's image)
.dw:	lda hcl                 ; (standing at 624: wait; below: dropped)
	cmp #<(624 + 16)
	lda hch
	sbc #>(624 + 16)
	bcs .dr
.dc:	lda pw_state
	cmp #6
	bne .dn
	stz pw_state
.dn:	stz s7dx
.dr:	rts
.ek:	lda act
	cmp #2
	bne .kx
lda imall
	beq .kx
	lda brm                 ; (the band itself: at any camera, whichever way; the bridge: going left only, and as bslice)
	cmp #21
	bne .go
	lda ldir
	bpl .kx
	lda CAMX
	tax
	eor s7kc
	stx s7kc
	beq .go
	txa
	and #15
	cmp #14
	beq .kx
	cmp #2
	beq .kx
	and #7
	beq .kx
.go:	jsr sclk
	bne .kx
	inc s7busy
	stz sdone
	lda #SSE
	sta ss
	jsr ssrun
	stz ss
	stz s7busy
.kx:	rts

sunit:	lda sjob
	dec a
	beq snear
	dec a
	beq smid
	dec a
	bne *+5
	jmp srng
	dec a
	bne *+5
	jmp sfv
	jmp send

snear:	ldx si
	cpx gnh
	bcc .go
	lda gml
	sta si
	inc sjob
	rts
.go:	lda nsd
	bne .q
	lda SPERM,x
	tax
.q:	txa
	jsr s32
	sta s7scm
	lda s7sx
	sta s7scl
	lda si
	jsr s32
	ora #$80
	sta s7sdh
	lda s7sx
	sta s7sdl
	lda #NPB
	sta s7sbk
	ldx #4
.p:	jsr spc
	lda s7scm
	clc
	adc #$11
	sta s7scm
	inc s7sbk
	dex
	bne .p
	inc si
	rts

smid:	ldx si
	cpx gmh
	bcc .go
	inc sjob
	stz s7sr
	stz s7scn
	rts
.go:	txa
	jsr s32
	pha
	clc
	adc #$48
	sta s7scm
	pla
	ora #$80
	sta s7sdh
	lda s7sx
	sta s7scl
	sta s7sdl
	lda #MPB
	sta s7sbk
	stz s7sp
.p:	jsr spc
	lda s7scm
	clc
	adc #8
	sta s7scm
	lda s7sdh
	clc
	adc #8
	sta s7sdh
	inc s7sp
	lda s7sp
	cmp #4
	bne .n
	inc s7sbk
	lda s7sdh
	sec
	sbc #$20
	sta s7sdh
.n:	lda s7sp
	cmp #8
	bne .p
	inc si
	rts

; (vector 4; the fourth image's bp_gone, the bridge stood down on this pass) at camera 624 and on with band 1's tables made and its
; borrowed tiles still held: the hand-over (sidle's s7dx)
sbx:	lda act
	bne .x
	inc nhand
	stz s7tb
	lda hcl
	cmp #<(624 + 16)
	lda hch
	sbc #>(624 + 16)
	bcs .r
	lda hcl                 ; (at 320 or below: the open quarry's take-back on the next pass, spas)
	cmp #<(320 + 16 + 1)
	lda hch
	sbc #>(320 + 16 + 1)
	bcs .x
	inc s7tb
	rts
.r:
	lda bsok
	beq .x
	lda card
	dec a
	bne .x
	lda pw_state
	ora MENU
	ora wsd
	ora vxph
	bne .x
	lda vxok
	beq .x
	lda <LOCKZP
	and #$18
	bne .x
	lda #6
	sta pw_state
	lda #1
	sta s7dx
.x:	rts
spas:	cly                     ; (quarry-handover) the hand-over's image's step of the pass first (hpas: band 1's stand-down and the
	jsr h5                  ; bridge's claim at 624 going left, band 1's take-over at 626 going right), then the pass's operands
	jsr srp
	lda s7tb
	beq .x
	stz s7tb
	lda act
	bne .x
	lda ldir
	bpl .x
	lda hcl
	cmp #<(304 + 16)
	lda hch
	sbc #>(304 + 16)
	bcc .x
	lda hcl
	cmp #<(320 + 16)
	lda hch
	sbc #>(320 + 16)
	bcs .x
	lda <LOCKZP
	and #$18
	ora MENU
	bne .x
	lda #30                 ; w3rdy2 (the second code sector)
	jsr call2
	bcs .x
	lda #1
	sta act
	inc nback
	stz dvalid
	stz dvalid + 1
	stz dfull
	stz dfull + 1
	stz ldir
.x:	rts
; (quarry-handover) Y = 2 x a vector of the hand-over's image (quarry_cardh.inc: in the third overlay's place after the fourth image,
; C8BANK at MPR3 for the call, this image's bank put back): the resident's c6t2
h5:	ldx #C8BANK
	lda #>(C8RAM + C9LEN)
	jmp c6t2
; Z set: an edge-key step still ends before the vblank (tok 0). No clock this frame (tok 1): this idle waits for the vblank and
; stamps the clock, as ssrun's end does (Z clear)
sclk:	jsr tok
	beq .x
	lsr a
	bcc .n
	jsr sstp
.n:	lda #1
.x:	rts
; this idle waits for the vblank and stamps the clock, as ssrun's end does (also sfil: the stamp for the idle after this one)
sstp:	lda FRAMES
	cmp pfr
	bne .n
	sta s7f
	cly
.sp:	lda FRAMES
	cmp s7f
	bne .v
	lda TIMER
	and #$7F
	tay
	iny
	bra .sp
.v:	tya
	beq .n
	clc
	adc #40
	cmp #116
	bcc .h
	sbc #116
.h:	sta hut
	lda s7f
	sta huf
.n:	rts
; A = a slot: s7sx = its images' offset's low byte (32 A), A = its high byte
s32:	pha
	asl a
	asl a
	asl a
	asl a
	asl a
	sta s7sx
	pla
	lsr a
	lsr a
	lsr a
	rts
spc:	lda s7scl
	sta $1A22
	lda s7scm
	sta $1A23
	lda #SEAMH
	sta $1A24
	lda s7sbk
	tam #4
	lda s7sdl
	sta .c + 3
	lda s7sdh
	sta .c + 4
.c:	tai $1A20, $8000, 32
	rts

srng:	lda nsd                 ; (entered at the band's side: band_setup ran in the set-up)
	beq .t
	lda #5
	sta sjob
	rts
.t:	lda s7scn
	bne .go
	ldx s7sr
	cpx #SRN * 5
	bcc .nx
	inc sjob
	rts
.nx:	lda SRT,x
	sta s7scl
	lda SRT + 1,x
	sta s7scm
	lda SRT + 2,x
	sta s7sbk
	lda SRT + 3,x
	sta s7sdh
	lda SRT + 4,x
	sta s7scn
	stz s7sdl
	txa
	clc
	adc #5
	sta s7sr
	rts
.go:	ldx #8
.c:	jsr spc
	lda s7scl
	clc
	adc #32
	sta s7scl
	bcc *+5
	inc s7scm
	lda s7sdl
	clc
	adc #32
	sta s7sdl
	bcc *+5
	inc s7sdh
	dec s7scn
	beq .o
	dex
	bne .c
.o:	rts

sfv:	lda sftn
	cmp #184
	bcc .go
	inc sjob
	rts
.go:	lda #BANDF
	tam #4
	lda sftn
	jsr s32
	ora #$80
	sta .c + 4
	lda s7sx
	sta .c + 3
	lda fhi                 ; the far base's address ((tile & $FF0) * 16), + 16 f
	asl a
	asl a
	asl a
	asl a
	sta s7sx
	lda flo
	lsr a
	lsr a
	lsr a
	lsr a
	ora s7sx
	sta s7sx
	lda sftn
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc s7sx
	sta s7scm
	lda sftn
	asl a
	asl a
	asl a
	asl a
	sta s7scl
.r:	lda FRAMES
	pha
	vsel 1
	lda s7scl
	sta $0002
	lda s7scm
	sta $0003
	vsel 2
.c:	tai $0002, $8000, 32
	pla
	cmp FRAMES
	bne .r
	inc sftn
	rts

; the end, as ss_end2's: entered at the open quarry's side band_setup's last steps and bsok, else imall
send:	lda nsd
	bne .i
	lda snne
	sta nne
	jsr bpal
	inc bsok
	bra .z
.i:	inc imall
.z:	stz bgf
	stz sjob
	rts

srp:	tma #4
	pha
	lda #C8BANK
	tam #4
	clx
	ldy #$9C
	lda ldir
	bmi .l
	dec a
	bne .w
	lda vxok
	beq .w
	lda mcop
	cmp #MGN
	bcc .w
	lda hcl
	cmp #<(308 + 16)
	lda hch
	sbc #>(308 + 16)
	bcc .w
	lda hcl
	cmp #<(336 + 16)
	lda hch
	sbc #>(336 + 16)
	bcs .w
	ldx #6
	lda act
	beq .w
	ldx #12
	bra .w
.l:	lda hcl
	cmp #<(608 + 16)
	lda hch
	sbc #>(608 + 16)
	bcc .w
	lda hcl
	cmp #<(624 + 16 + 1)
	lda hch
	sbc #>(624 + 16 + 1)
	bcs .w
	ldy #$4C
	lda act
	bne .w
	ldx #18
.w:	lda SRV,x
	sta bp_ab + $2000
	lda SRV + 1,x
	sta bp_cl + $2000
	lda SRV + 2,x
	sta bp_al + $2000
	lda SRV + 3,x
	sta bp_sl + $2000
	lda SRV + 4,x
	sta bp_sh + $2000
	lda #C6BANK
	tam #4
	lda SRV + 5,x
	sta bw_n + $2000
	lda #CBANK
	tam #4
	stz s7lr
	cpy #$4C
	beq .j
	lda #$9C                ; stz pw_state; lda CAMX + 1
	sta qi_cb - $4000
	lda #<pw_state
	sta qi_cb - $4000 + 1
	lda #>pw_state
	sta qi_cb - $4000 + 2
	lda #$AD
	sta qi_bp - $4000
	lda #<(CAMX + 1)
	sta qi_bp - $4000 + 1
	lda #>(CAMX + 1)
	sta qi_bp - $4000 + 2
	bra .q
.j:	inc s7lr                ; (quarry-load-after-handover: the jumps go through qj_cb / qj_bp in the second code sector, which take
	sty qi_cb - $4000
	sty qi_bp - $4000
	lda #<qj_cb
	sta qi_cb - $4000 + 1
	lda #>qj_cb
	sta qi_cb - $4000 + 2
	lda #<qj_bp
	sta qi_bp - $4000 + 1
	lda #>qj_bp
	sta qi_bp - $4000 + 2
.q:	pla
	tam #4
	rts
s7lr:	.db 0
SRV:	.db (bp_xi - bp_ab - 1) & $FF, <(322 + 16), 15, <(336 + 16), <(608 + 16 + 1), BWN
	.db 0, <(308 + 16), 0, <(322 + 16), <(608 + 16 + 1), BWN
	.db 0, <(308 + 16), 0, <(322 + 16), <(608 + 16 + 1), BWA
	.db (bp_xi - bp_ab - 1) & $FF, <(322 + 16), 0, <(336 + 16), <(LSW + 16 + 1), BWL
SBT        = $9FE2
BWA        = 12
BWL        = 28
LSW        = 622        ; (quarry-handover: 620 before; the claim is made at 624 now and the switch comes on the pass after it)
BWJ0       = 2
sbtc:	lda #0
	tam #3
	lda #0
	jsr $FFFF
	lda #C7BANK
	tam #3
	rts
SEN:	.db 14, 28, 12, 12, 8, 5, 8
sebi:	lda pw_state
	beq .p
	cmp #6
	beq .p
	stz s7ev
	stz s7eb
.p:	lda act
	dec a
	bne .ab
	lda pw_state
	ora MENU
	ora wsd
	ora vxph
	bne .ab
	lda <LOCKZP
	and #$18
	bne .ab
	lda s7eb
	bne .l
	lda s7ev
	ora nsd
	bne .x
	lda bsok
	beq .x
	lda card
	dec a
	bne .x
	lda hcl
	cmp #<(280 + 16)
	lda hch
	sbc #>(280 + 16)
	bcs .x
	inc s7eb
.l:	lda hcl
	cmp #<(300 + 16)
	lda hch
	sbc #>(300 + 16)
	bcs .ab
	ldx s7eb
	lda SEN - 1,x
	jsr stk
	bne .x
	jsr seu
	lda s7eb
	bne .l
.x:	rts
.ab:	stz s7eb
	rts
; Z set: a unit of A ticks (its margin in them) still ends before the vblank: the edge keys' clock (tok) with this unit's length
stk:	sta s7tk
	jsr tok
	bne .x
	lda TIMER
	and #$7F
	sta tnw
	lda hut
	jsr tel
	clc
	adc s7tk
	cmp #40
	lda #0
	bcc .x
	inc a
.x:	rts
seu:	tma #4
	pha
	lda #BANDT
	tam #4
	lda s7eb
	dec a
	bne .n1
	tii sbtc, SBT, 14       ; 1
	lda #28
	jsr call2
	jmp .nx
.n1:	dec a
	bne .n2
	lda #<rebuild           ; 2
	ldx #>rebuild
.h:	jsr shd
	inc s7eb
	lda #1
	sta s7ec
	jmp .o
.n2:	dec a
	bne .n3
	lda #<nfetch            ; 3
	ldx #>nfetch
.col:	ldy s7ec
	jsr sbt6
	inc s7ec
	lda s7ec
	cmp #33
	beq *+5
	jmp .o
	jmp .nx
.n3:	dec a
	bne .n4
	lda #<mrebuild          ; 4
	ldx #>mrebuild
	jmp .h
.n4:	dec a
	bne .n5
	lda #<mfetch            ; 5
	ldx #>mfetch
	jmp .col
.n5:	dec a
	bne .n6
	lda mcop                ; 6
	cmp #MGN
	bcc *+5
	jmp .nx
	lda mci
	pha
	lda mcop
	sta mci
	cly
	jsr mgxfer
	inc mcop
	pla
	sta mci
	jmp .o
.n6:	lda s7ec
	stz s7sdl
	lsr a
	ror s7sdl
	lsr a
	ror s7sdl
	lsr a
	ror s7sdl
	pha
	ora #$E0
	sta $1A23
	lda s7sdl
	sta $1A22
	sta .c + 1
	lda #KTH
	sta $1A24
	pla
	ora #>NLC
	sta .c + 2
	ldx #16
.c:	tia $9000, $1A20, 32
	lda .c + 1
	clc
	adc #32
	sta .c + 1
	bcc *+5
	inc .c + 2
	inc s7ec
	dex
	bne .c
	lda s7ec
	cmp #64
	beq *+5
	jmp .o
	inc s7ev
	stz s7eb
	jmp .o
.nx:	inc s7eb
	stz s7ec
.o:	pla
	tam #4
	rts
; A / X = rebuild or mrebuild: its head and column 0 only (both loops' ends at column 1 for this call)
shd:	sta SBT + 7
	stx SBT + 8
	lda ssb6
	sta SBT + 1
	lda #(624 + 16) >> 3
	sta cn
	lsr a
	sta cm
	tma #6
	pha
	lda #SHBANK
	tam #6
	lda #1
	sta rb_n
	sta mrb_n
	cly
	jsr SBT
	lda #33
	sta rb_n
	sta mrb_n
	pla
	tam #6
	rts
; A / X = a routine of the band's (SHBANK at MPR6), Y its column: called with the maps' bank at MPR3 through SBT; BANDT is at MPR4.
; cn / cm are the band's first columns for the call (bi_cam's; every pass of the open quarry's sets its own)
sbt6:	sta SBT + 7
	stx SBT + 8
	lda ssb6
	sta SBT + 1
	lda #(624 + 16) >> 3
	sta cn
	lsr a
	sta cm
	tma #6
	pha
	lda #SHBANK
	tam #6
	jsr SBT
	pla
	tam #6
	rts
srst:	stz s7ev
	lda #12
	ldx #C5BANK
	jsr callx
	tma #4
	pha
	lda #BANDT
	tam #4
	stz $1A22
	lda #$E0
	sta $1A23
	lda #KTH
	sta $1A24
	stz .c + 3
	lda #>NLC
	sta .c + 4
	ldx #64
.c:	tai $1A20, $9000, 32
	lda .c + 3
	clc
	adc #32
	sta .c + 3
	bcc *+5
	inc .c + 4
	dex
	bne .c
	clx
	cly
.q:	lda GSLOT,x
	cmp #$FF
	beq .n
	stz GREADY,x
	txa
	sta GQ,y
	iny
.n:	inx
	cpx #136
	bne .q
	sty gqt
	stz gqh
	stz gqp
	stz gover
	pla
	tam #4
	lda #(624 + 16) >> 3
	sta bcn
	sta cn
	lsr a
	sta bcm
	sta cm
	stz pn
	stz dm
	stz nbpass
	stz nbpass + 1
	lda #1
	sta nwfull
	tma #4                  ; (wz / rs are the third code area's, CBANK: at MPR4 here, as sinit's patches)
	pha
	lda #CBANK
	tam #4
	lda #1
	sta wz - $4000
	stz rs - $4000
	pla
	tam #4
	rts

BWI        = 8
BWIT       = 10
sfil:	lda act
	cmp #2
	bne *+3
	rts
	tma #4
	pha
	lda #C8BANK
	tam #4
	lda bpre + $2000
	beq *+5
	jmp .c
	jmp .x
.c:	lda bgs
	cmp #$FD
	bcs *+5
	jmp .x
	beq *+5
	jmp .k
	lda s7lr
	bne *+5
	jmp .k
	stz bpre + $2000
	lda #C6BANK
	tam #4
	lda #BWJ0
	sta bwj + $2000
	lda bw_n + $2000
	pha
	lda #64
	sta bw_n + $2000
	jsr .sb
	lda #CN0 - 1
	sta SBT + 5
	lda #<cpsel
	sta SBT + 7
	lda #>cpsel
	sta SBT + 8
	jsr SBT
	lda #<bens6
	sta SBT + 7
	lda #>bens6
	sta SBT + 8
	jsr SBT
	lda #<bwrm
	sta SBT + 7
	lda #>bwrm
	sta SBT + 8
	lda #12
	sta s7fc
.a:	jsr SBT
	lda #C6BANK
	tam #4
	lda bwj + $2000
	tax
	lda #BANDT
	tam #4
	cpx #8
	bcs .ad
	dec s7fc
	bne .a
.ad:	lda s7fc                ; (then phase 7, 606's, into what is left free)
	bmi .af
	lda #$FF
	sta s7fc
	lda #C6BANK
	tam #4
	lda #1
	sta bwj + $2000
	lda #BANDT
	tam #4
	jsr SBT
	lda #C6BANK
	tam #4
	lda #8
	sta bwj + $2000
.af:	lda #C8BANK
	tam #4
	lda #1
	sta bpre + $2000
	bra .e
.k:	lda #C6BANK
	tam #4
	lda bw_n + $2000
	pha
	lda #BWI
	sta bw_n + $2000
	jsr .sb
	lda #<bwrm
	sta SBT + 7
	lda #>bwrm
	sta SBT + 8
	lda #40
	sta s7fc
.l:	lda #BWIT
	jsr stk
	bne .e
	jsr SBT
	dec s7fc
	bne .l
.e:	lda #C6BANK
	tam #4
	pla
	sta bw_n + $2000
.x:	pla
	tam #4
	rts
.sb:	lda #BANDT
	tam #4
	tii sbtc, SBT, 14
	lda #C6BANK
	sta SBT + 1
	rts
s7fc:	.db 0
swin:	lda pw_state
	cmp #4
	bne .x
	lda act
	bne .x
	lda mready
	bne sturn
	lda #16
	sta swc
.l:	lda #15                 ; band_upl, then cmu_r: four groups
	jsr callb
	lda mready
	bne .x
	dec swc
	bne .l
.x:	rts
; THE TURN AT THE BAND'S LEFT END (quarry-finish-2): set up again (bist2's band_init at 624: column 80), the band's aligned take-over
; comes at 640 (column 82): a jump, every column fetched again and every near group queued anew, drawn as the template's tile A until
; uploaded (17 pictures 644 .. 676). Now while the set-up waits for the take-over (pw_state 4, act 0, the mid groups made) at camera
; 624 and on, the idle follows the camera: when its near column is not the one band_init's tables hold, band_init again without
; midsetup (its call made a BIT for that call: the mid groups' copies and images kept, nothing copied out twice) and every queued
; group uploaded. The take-over's pass then finds the tables at most a column off (the pass's one-column shift, as on any pass).
sturn:	lda hcl
	cmp #<(624 + 16)
	lda hch
	sbc #>(624 + 16)
	bcc .x
	lda CAMX + 1            ; (bi_cam's column: (camera >> 3) + 2, 80 and more from 624)
	sta swc
	lda CAMX
	lsr swc
	ror a
	lsr swc
	ror a
	lsr swc
	ror a
	inc a
	inc a
	cmp bcn
	beq .x
	tma #4
	pha
	lda #SHBANK
	tam #4
	lda #$2C                ; (BIT)
	sta bims - $4000
	cla                     ; band_init
	jsr callb
	lda #$20                ; (JSR)
	sta bims - $4000
	pla
	tam #4
	lda #GUPMAX
	sta bugm + 1
.u:	lda gqh
	cmp gqt
	beq .x
	lda #15                 ; band_upl
	jsr callb
	bra .u
.x:	rts
swc:	.db 0
SXN1       = 4
sxt:	tma #4
	pha
	lda nbpass + 1
	bne .a
	lda nbpass
	cmp #1
	bne .a
	lda #$FF
	sta sxsh
	sta sxtl
	sta sxtl + 1
.a:	lda cn                  ; band 1's period
	sec
	sbc #CN0
	cmp #NPER
	bcs .no
	asl a                   ; its list: $15 : LBM + 8 P + 7 : 64 k
	asl a
	asl a
	adc #LBM + 7
	tax
	lda pn
	lsr a
	ror a
	ror a
	ldy #CR3H
	jsr cb1
	lda $1A10
	beq .no
	sta sxn
	cly                     ; the region
	lda pn
	lsr a
	bcc .r
	lda sxn
	cmp #SXN1 + 1
	bcs .r
	iny
.r:	sty sxr
	cpy sxsh                ; (shown: only this camera's again)
	bne .f
	jsr .tag
	bne .x
.f:	tya                     ; region 0: the odd set copied out, the groups 43 and 44 too
	bne .w
	lda #C6BANK
	tam #4
	lda cocp + $2000
	beq .x
	lda mcop
	cmp #45
	bcs .w
	cmp rnpair
	bne .x
	lda mci
	pha
.g:	lda mcop
	sta mci
	cly
	jsr mgxfer
	inc mcop
	lda mcop
	cmp #45
	bcc .g
	pla
	sta mci
	bra .w
.no:	lda #$FF
	sta sxsh
.x:	pla
	tam #4
	rts
.w:	lda #BANDT              ; the cells
	tam #4
	lda $1A10
	sta sxc
.c:	ldx $1A10
	lda $1A10
	sta WIN + 66 * 13,x
	lda $1A10
	sta WIN + 66 * 13 + 1,x
	dec sxc
	bne .c
	ldy sxr
	sty sxsh
	jsr .tag
	bne *+5
	jmp .x
	lda CAMX
	sta sxtl,y
	lda CAMX + 1
	sta sxth,y
	lda #$40                ; the images, port 0 through bank $40
	tam #4
	ldx SXB,y
.i:	lda $1A10
	sta sxa
	lda $1A10
	sta sxa + 1
	lda $1A10
	sta sxa + 2
.t:	lda sxa
	sta $1A02
	lda sxa + 1
	sta $1A03
	lda sxa + 2
	sta $1A04
	lda FRAMES
	sta s7f
	vsel 0
	lda SXTL,x
	sta $0002
	lda SXTH,x
	sta $0003
	vsel 2
	tia $8000, $0002, 32
	lda FRAMES              ; (a vblank in the middle: the tile again)
	cmp s7f
	bne .t
	inx
	dec sxn
	bne .i
	pla
	tam #4
	rts
.tag:	lda CAMX                ; Z: region Y holds this camera's images
	cmp sxtl,y
	bne .tx
	lda CAMX + 1
	cmp sxth,y
.tx:	rts
sxsh:	.db $FF
sxtl:	.db $FF, $FF
sxth:	.db $FF, $FF
sxr:	.db 0
sxn:	.db 0
sxc:	.db 0
sxa:	.db 0, 0, 0
SXB:	.db 0, 7
SXTL:	.db <($655 * 16), <($656 * 16), <($657 * 16), <($658 * 16), <($659 * 16), <($65A * 16), <($57C * 16)
	.db <($678 * 16), <($679 * 16), <($67A * 16), <($67B * 16)
SXTH:	.db >($655 * 16), >($656 * 16), >($657 * 16), >($658 * 16), >($659 * 16), >($65A * 16), >($57C * 16)
	.db >($678 * 16), >($679 * 16), >($67A * 16), >($67B * 16)
; ---------------------------------------------------------------- (quarry-spire-fix) the spire's sprites on the band path's passes
ssp:	lda CAMX + 1            ; cameras 448 .. 511: nothing (the last pixel of the spire leaves the screen at 447: the right sprite's 8
	beq .lo
	lda CAMX
	cmp #$C0
	bcs .x
.lo:	lda CAMX
	lsr a
	and #7
	beq .x
	sta t2
	cli
	vsel 1                  ; MARR = entry 4's X word
	lda #17
	sta $0002
	lda SATPAGE
	sta $0003
	vsel 2
	lda #60
	sta t3                  ; entries left: this one is 64 - t3
.q:	ldx $0002               ; the X word
	ldy $0003
	lda $0003               ; (the pattern word)
	lda $0002
	beq .z
	and #$0F
	cmp #4
	beq .h
.a:	lda $0003               ; (its high byte)
.n:	lda $0003               ; (the next entry's Y word)
	dec t3
	bne .q
.d:	sei
.x:	rts
.z:	ora $0003
	bne .n
	bra .d
.h:	txa                     ; X - phase (10 bits)
	sec
	sbc t2
	tax
	tya
	sbc #0
	bcc .a
	pha
	vsel 0                  ; MAWR = this entry's X word: 4 (64 - t3) + 1
	lda t3
	asl a
	asl a
	eor #$FF
	inc a
	inc a
	sta $0002
	lda SATPAGE
	sta $0003
	vsel 2                  ; (the read address and its word waiting are untouched by the write)
	stx $0002
	pla
	sta $0003
	bra .a
s7end:
	.if (s7end > C7RAM + SLEN - 1)
	.fail
	.endif
	.org C7RAM + SLEN - 1
	.db $A5
