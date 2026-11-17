S0OFF      = 0
S0SET      = 1
S0ENG      = 2
S0STD      = 3
S0REB      = 4
S0RCR      = $A7
HOLDP      = 7
S0DA       = $74
S0DW       = $76        ; the setup's tables (MPR4), then the water's card copies 0-255 (MPR3)
S0DC       = $77        ; the compose cache (MPR3), then the water's card copies 256-305
S0DT       = $78        ; the pass's tables (MPR3)
LOCK       = $2025
DARKF      = $3224
FINEADC    = $4CC3      ; bank $80: the object draw's ADC $2D10 (the camera's fine X), the mine's operand swap
FINEX      = $2D10
ZERO09     = $2D09
OP_NEARH0B = $6CF7
OP_STRLO   = $6C95
OP_STRHI   = $6C9E
OP_NEAROFF = $6CE3
PALRAM     = $3C00
CHUNK      = 4

; $76 at MPR4 during the setup
GK         = $8000      ; per group: kind (0 band static, 1 lintel, 2 band water)
G1         = $8100      ; band: left mid value; lintel: near code at x ($FF: none)
G2         = $8200      ; band: mid value; lintel: near code at x + 1 ($FF: none)
G3         = $8300      ; lintel: the mid value under (0: both near); band: 0
GNX        = $8400      ; hash chain: the next group + 1 (0: none)
GW         = $8500      ; its 3 BAT words: low bytes at GW + bi * $200, high at + $100
HD         = $8B00      ; chain heads (group + 1): 0-63 band pairs, 64-127 lintel triples
MIDC       = $8C00      ; the mid map: rows 0-15 x 128 (4 frames x 32)
NMD        = $08        ; (NEARC - MIDC) >> 8
NEARC      = $9400      ; the near map: rows 0-15 x 128 (columns 0-65): the code, $FF where no near tile
; $78 at MPR3: the pass's tables
WRUN       = $6000      ; rows 10-15 (16 bytes each): runs of empty near columns: count, then (first, last) x 7 at most
LIX        = $6060      ; per n (0-32) and phase: the lintel list's address (lo, hi; hi 0: none)
PALSV      = $6130
ROWT       = $6170
WTAB       = $6200
WEND       = $7B00
ACOL       = $7B00      ; rows 10-15 x 32 mid columns: non-zero where the 4 animation frames differ
WK1        = $7D00      ; per water group w: its pair's mid values (the copies after engagement)
WK2        = $7D80
WTL        = $7BC0      ; the resident water's tiles (pool index WK0 + w * 3 + bi): low bytes at WTL + bi * WMAX + w, high at WTH + ..
WTH        = $7E00
WMASK      = $7FDC      ; rows 10-15: the water cells (screen x, 5 bytes a row: bit x & 7 of byte x >> 3)
WMAX       = 106        ; water groups at most (the model: 101)
WK0        = 450
S0D9       = $79        ; the save's third bank (pool indices 512-767)
S0DE       = $7A        ; pool tiles 768-865 of the save ($0000-$0C3F), water card copies 232- ($0C40-$16FF), the patch's run lists ($1700-)
WCAP       = 232        ; water card copies in $76 ($0300-$1FFF) before $7A
; $77 at MPR3 during the compose
CACHE      = $6000      ; source tiles, 32 bytes each
CMAX       = 176
S0SH       = $7600      ; SHL p at S0SH + (p / 2 - 1) * $100 (v << p), SHR p at + $300 (v >> (8 - p)), p = 2, 4, 6
VMAP       = $7C00      ; mid value -> cache index (band)
NMAP       = $7D00      ; near code -> cache index (lintel)
BMAP       = $7E00      ; mid value -> cache index of its copy in the spare palette's indices (lintel)

s0rmp      = $7F40      ; mid colour index -> spare palette index (lintel; $77's tail, MPR3 in the prep)
s0prop     = $9F70
s0bmp      = $9C00      ; the pool's tiles as a bitmap: tile >> 3, bit tile & 7
s0used     = $9D00      ; the cache's wants: mid values (32 bytes of flags), near codes (16), mid values under the lintel (32); the scan's seen flags before
s0cbr      = $9D50      ; the lintel cells of one n
s0cbx      = $9D90
s0cbg      = $9DD0
s0clt      = $9E10      ; the cache's tiles
s0cht      = $9EC0

; ---------------------------------------------------------------- banks
s0sv34:	tma #3
	sta s0v3
	tma #4
	sta s0v4
	rts
s0rs34:	lda s0v3
	tam #3
	lda s0v4
	tam #4
	rts

s0r15:	lda s0st
	beq *+5
	jmp .on
	stz s0late
	lda LOCK
	and #$10
	ora DARKF
	bne .b
	lda s0ld
	bne .lt
	stz s0fail              ; (in play: a refusal is forgotten; the next entry tries again)
	rts
.lt:	inc s0late
.b:	stz s0ld
	lda s0fail
	bne .x
	jsr s0rec
	bcs .x
	lda #S0SET
	sta s0st
	stz s0ss
	stz s0si
	stz s0sj
	stz s0pc
	stz s0hold
	stz s0wrdy
	stz s0wc
	stz s0aend2
	lda CAMX
	sta s0cam0
	ldx CAMX+1
	stx s0cam0+1
	stz s0aend
	cmp #$F0
	bne .ce
	cpx #$FF
	beq .ce1
.ce:	cmp #240
	bne .ce2
	cpx #0
	bne .ce2
.ce1:	inc s0aend
.ce2:	lda FRAMES
	sta s0tst
	stz s0wun
	stz s0wun+1
	stz s0uw
	stz s0ub
	lda FRAMES
	sta s0t0
.x:	rts
.on:	stz s0ld
	cmp #S0SET
	bne .e
	inc s0pc
	rts
.e:	pha
	jsr s0sprest            ; (never left swapped from a pass whose satbody did not come)
	pla
	stz s0ok
	cmp #S0ENG
	bne .x
	lda WINDOW
	bne .x
	lda FRAMES              ; in time: the pass began in this frame (a pass that began in an earlier one gets nothing: BXR 0,
	cmp pfr
	beq *+7
	ldx #1
	jmp .late
	lda CAMX
	and #7
	sta s0b
	lsr a
	bcc *+7
	ldx #3
	jmp .late                ; (an odd camera: no composites for it)
	lda CAMX                ; n = (camera + 16) >> 3: the near pointer's column (the pass drew at it)
	clc
	adc #16
	sta q0
	lda CAMX+1
	adc #0
	ldx #4
	bmi .late
	lsr a
	ror q0
	lsr a
	ror q0
	lsr a
	ror q0
	cmp #0
	bne .late
	lda q0
	cmp #33
	bcs .late
	ldx #5
	cmp OP_NEARPTR
	bne .late
	sta s0n
	lda OP_MIDPTR           ; the mid frame
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	and #3
	sta s0a
	lda OP_MAWRHI           ; row 15 of rows 18-33 is at $7C2, of rows 0-15 at $3C2
	cmp #4
	cla
	bcc .bf
	lda #18
.bf:	sta s0bf
	lda s0b
	bne .sw
	lda #2
	sta s0ok
	rts
.sw:	lda FINEADC
	cmp #$6D
	bne .nf
	lda FINEADC+2
	cmp #>FINEX
	bne .nf
	lda FINEX
	cmp s0b
	bne .nf
	lda ZERO09
	bne .nf
	lda #<ZERO09
	sta FINEADC+1
	inc s0sw
	bra .o1
.nf:	inc s0nfm
	bne .o1
	inc s0nfm+1
.o1:	lda #1
	sta s0ok
	rts
.late:	stx s0lr               ; (DIAG: the reason)
	inc s0nl
	bne .lx
	inc s0nl+1
.lx:	rts

; the operand back (satbody, row 15, the stand-down, the exits)
s0sprest:	lda FINEADC
	cmp #$6D
	bne .x
	lda FINEADC+2
	cmp #>FINEX
	bne .x
	lda #<FINEX
	sta FINEADC+1
.x:	stz s0sw
	rts

s0rec:	lda OP_NEAROFF
	ora OP_MIDOFF
	ora OP_STRLO
	beq *+5
	jmp .f2
	lda OP_MIDMASK
	cmp #$1F
	beq *+5
	jmp .f2
	lda OP_STRHI
	cmp #1
	beq *+5
	jmp .f2
	lda OP_NEARLO
	sta s0bnl
	lda OP_NEARH0B
	clc
	adc OP_NEARHI
	sta s0bnh
	lda OP_MIDLO
	sta s0bml
	lda OP_MIDHI
	clc
	adc OP_MIDLO + 5
	sta s0bmh
	ldx #0
	lda s0bnh
	cmp #$01
	beq .l
	inx
	cmp #$02
	beq *+5
	jmp .f2
.l:	stx s0lay
	lda s0bnl
	cmp #$E0
	beq *+5
	jmp .f2
	lda s0bml
	cmp #$10
	beq *+5
	jmp .f2
	txa
	clc
	adc #$12
	cmp s0bmh
	bne .f2
	lda CAMX                ; row 15's near pointer is the map's row 0 + 15 rows + n (n from the camera; the map's low byte 0)
	clc
	adc #16
	sta q0
	lda CAMX+1
	adc #0
	lsr a
	ror q0
	lsr a
	ror q0
	lsr a
	ror q0
	lda q0
	cmp OP_NEARPTR
	bne .f2
	lda OP_NEARPTR+1
	sec
	sbc #15
	sta s0nbh
	cmp #$C0
	bcc .f2
	cmp #$D1
	bcs .f2
	lda OP_MIDPTR           ; row 15's mid pointer: its map's row 0 + 15 rows + frame * 32
	and #$9F
	bne .f2
	lda OP_MIDPTR+1
	sec
	sbc #15
	sta s0mbh
	cmp #$C0
	bcc .f2
	cmp #$D1
	bcs .f2
	ldx #47
.al:	lda $40B3,x
	cmp #$4A
	bcs .f11
	dex
	bpl .al
	lda <$59                ; the property table (through the renderer's mapping, now) to $76's tail: $76 at MPR3 for the copy, interrupts
	sta .p+1                ; off (the renderer's bank $81 is MPR3's, given back before anything of it runs)
	lda <$5A
	sta .p+2
	php
	sei
	tma #3
	pha
	lda #S0DW
	tam #3
	ldx #127
.p:	lda $FFFF,x
	sta s0prop - $2000,x
	dex
	bpl .p
	pla
	tam #3
	plp
	clc
	rts
.f2:	lda #2
	bra s0refuse
.f11:	lda #11
s0refuse:	sta s0fail
	sta s0lastf
	inc s0nref
	jsr s0off
	sec
	rts

s0sat:	jsr s0chk
	jsr s0vcew
	lda s0st
	cmp #S0ENG
	beq .e
	cmp #S0SET              ; the setup not done and the camera moved off its arrival: the rest now (the fallback hold), engaged from
	bne .n
	lda CAMX
	cmp s0cam0
	bne .h
	lda CAMX+1
	cmp s0cam0+1
	beq .n
.h:	inc s0hmove
	lda FRAMES
	sta s0hf
	cli
.hl:	jsr s0step
	lda s0st
	cmp #S0SET
	beq .hl
	sei
	lda FRAMES
	sec
	sbc s0hf
	inc a
	sta s0hold
.n:	clc
	rts
.e:	jsr s0agrd
	lda s0ok
	cmp #1
	bne .z
	stz s0fall
	lda s0wrdy
	cmp #2
	beq .pp
	inc s0wpre
	bne .fb
	inc s0wpre+1
.fb:	inc s0fall
.pp:	jsr s0patch
	lda PASS                ; this pass's buffer: its frames take this BXR at the band (the vblank latches the parity)
	and #1
	tax
	lda s0b
	sta BBXR,x
	bra .d
.z:	lda PASS
	and #1
	tax
	stz BBXR,x
.d:	jsr s0sprest
	stz s0ok
	sec
	rts

s0agrd:	ldx s0aix
.up:	cpx #47
	bcs .dn
	lda $40B4,x
	beq .dn
	inx
	bra .up
.dn:	lda $40B3,x
	bne .c
	dex
	bpl .dn
	inx
.c:	stx s0aix
	cmp #S0WPG + 1
	bcc .x
	cmp s0aend2
	bcc .x
	sta s0aend2
	lda #3
	sta s0wrdy
.x:	rts

s0chk:	lda s0st
	beq .x
	lda SCENE
	bne .out
	lda <$55
	cmp #S0KEY
	bne .out
	lda s0st
	cmp #S0ENG
	bne .x
	lda WINDOW
	beq .x
	jsr s0hoff
	jsr s0sprest
	lda #S0STD
	sta s0st
	inc s0nsd
.x:	rts
.out:	php
	cli
	jsr s0exit
	plp
	rts

; ---------------------------------------------------------------- the exits
s0leave:	jmp s0exit              ; (an area load: the map exit, a Load)
s0exit:	jsr s0off
	stz s0fail
	inc s0nex
	rts
s0off:	jsr s0hoff
	jsr s0sprest
	lda s0sv
	beq .p
	jsr s0rest
	stz s0sv
.p:	lda s0pl
	beq .o
	jsr s0palback
	stz s0pl
.o:	stz s0st
	stz s0vce
	rts

; ---------------------------------------------------------------- the idle time (upsave, interrupts on)
s0idle:	php
	sei
	jsr s0chk
	plp
	lda s0st
	cmp #S0SET
	beq .set
	cmp #S0STD
	beq .std
	cmp #S0REB
	beq .reb
	cmp #S0ENG
	bne .x
	jmp s0ework
.x:	rts
.std:	lda WINDOW
	bne .x
	lda #1
	sta s0vce
	lda s0wrdy
	beq .eng                ; (no copies yet: engaged, the idle work goes on)
	cmp #3
	beq .eng                ; (lost to the allocator: never again this visit)
	lda #1
	sta s0wrdy
	stz s0wun
	stz s0wun+1
	stz s0uw
	stz s0ub
	bra .eng
.reb:	lda WINDOW
	beq .rb
	lda #S0STD
	sta s0st
	rts
.rb:	lda s0wrdy
	cmp #1
	bne .eng
	lda FRAMES
	sta s0fr
.rl:	jsr s0wup
	lda s0wrdy
	cmp #2
	beq .eng
	lda FRAMES
	cmp s0fr
	beq .rl
	rts
.eng:	inc s0reb
	jmp s0engage
.set:	lda FRAMES
	sta s0fr
.l:	lda s0late              ; (armed after the lock's clear: at once)
	bne .lh
	lda s0pc                ; the hold: from HOLDP passes after arming, past the vblanks (the screen is black): all of the setup,
	cmp #HOLDP
	bcc .c
.lh:
	lda s0hold
	bne .c                  ; (held once already)
	jsr s0farq
	lda FRAMES
	sta s0hf
.s:	jsr s0step
	lda s0st
	cmp #S0SET
	bne .se
	lda s0far
	beq .s
	lda s0ss
	cmp #5                  ; (the far case: through the save)
	bcc .s
	bra .sd
.se:	cmp #S0ENG
	bne .sd
.sw:	lda s0wrdy
	bne .su
	jsr s0wcomp
	bra .sw
.su:	cmp #2
	bcs .sd
	jsr s0wup
	bra .sw
.sd:	lda FRAMES
	sec
	sbc s0hf
	inc a
	sta s0hold
	rts
.c:	jsr s0step
	lda s0st
	cmp #S0SET
	bne .cx
	lda FRAMES
	cmp s0fr
	beq .l
.cx:	rts

; one bounded piece of the setup, by step
s0step:	lda s0ss
	asl a
	tax
	jmp [s0steps,x]
s0steps:	.dw s0scan, s0runs, s0enb, s0enl, s0save, s0prep, s0comp, s0engage
s0next:	inc s0ss
	ldx s0ss                ; (the step's start: tset per step)
	lda FRAMES
	sta s0tst,x
	stz s0si
	stz s0sj
	stz s0sk
	rts

; ---- step 0: the maps, a row a piece: near codes and mid values copied, every value checked against the pools once
s0scan:	jsr s0sv34
	lda s0fb
	tam #3
	lda #S0DW
	tam #4
	lda s0si
	bne .r
	jsr s0bitmap            ; (first piece: the pool's bitmap; the seen flags cleared)
.r:
	lda s0si                ; the near row: s0nbh - $60 + r : 0
	clc
	adc s0nbh
	sec
	sbc #$60
	sta .n+2
	lda s0si                ; NEARC + r * 128
	lsr a
	sta .w+2
	cla
	ror a
	sta .w+1
	lda .w+2
	clc
	adc #>NEARC
	sta .w+2
	clx
.n:	lda $6000,x
	and #$7F
	tay
	lda s0prop,y
	bmi .e
	sty q5
	cpx #65                 ; (column 65 is never drawn: n + x <= 64)
	bcs .w0
	phx
	tya
	jsr s0nchk              ; a near tile in a pool: refuse
	plx
	bcs .f4
.w0:	lda q5
	bra .w
.e:	lda #$FF
.w:	sta NEARC,x
	inx
	cpx #66
	bne .n
	lda s0si                ; the mid row: s0mbh - $60 + r : 0, 128 values (the 4 frames)
	clc
	adc s0mbh
	sec
	sbc #$60
	sta .m+2
	lda .m+2                ; one TII of the row (128 bytes) to MIDC + r * 128 (NEARC's row less NMD pages)
	sta .t+2
	stz .t+1
	lda .w+1
	sta .t+3
	sta .z+1
	lda .w+2
	sec
	sbc #NMD
	sta .t+4
	sta .z+2
.t:	tii $6000, MIDC, 128
	ldx #127
.z:	lda MIDC,x              ; (a mid value 0 would show the far layer: refused)
	beq .f3
	dex
	bpl .z
	lda s0si                ; rows 0-9 drawn wherever no near tile is: checked against the pool on frame 0 (s0rows proves the frames
	cmp #10                 ; alike); rows 10-15's drawn values are the composites' sources, checked with the cache's list
	bcs .mn
	ldx #31
.m:	lda $6000,x
	phx
	jsr s0mchk
	plx
	bcs .f4
	dex
	bpl .m
.mn:
	jsr s0rs34
	inc s0si
	lda s0si
	cmp #16
	bne .x
	jmp s0next
.x:	rts
.f3:	jsr s0rs34
	lda #3
	jmp s0refuse
.f4:	jsr s0rs34
	lda #4
	jmp s0refuse

; carry set: the near word of code A (s0nchk), or the mid word of value A (s0mchk), names a pool tile; each value tested once
; (s0used's seen flags: mid values at 0-31, near codes at 32-47)
s0nchk:	sta q4
	ldy #32
	jsr s0seen
	bcs s0nok
	lda q4
	clc
	adc s0bnl
	sta q0
	lda s0bnh
	adc #0
	bra s0tchk
s0mchk:	sta q4
	cly
	jsr s0seen
	bcs s0nok
	lda q4
	clc
	adc s0bml
	sta q0
	lda s0bmh
	adc #0
	bra s0tchk
s0nok:	clc
	rts
; flag q4 in s0used + Y (bytes): carry set when it was set already
s0seen:	lda q4
	lsr a
	lsr a
	lsr a
	sta q1
	tya
	clc
	adc q1
	tax
	lda q4
	and #7
	tay
	lda s0bit,y
	and s0used,x
	beq .n
	sec
	rts
.n:	lda s0bit,y
	ora s0used,x
	sta s0used,x
	clc
	rts
; carry set: the tile of the word (A high, q0 low) is a pool tile of this layout (s0bmp: tile >> 3, bit tile & 7)
s0tchk:	and #7
	sta q1
	lda q0
	and #7
	tay
	lda q0
	lsr q1
	ror a
	lsr q1
	ror a
	lsr q1
	ror a
	tax
	lda s0bmp,x
	and s0bit,y
	beq s0nok
	sec
	rts
s0bit:	.db 1, 2, 4, 8, 16, 32, 64, 128

; the pools of this layout as a bitmap (A, and the first S0WN tiles of B); the flags cleared
s0bitmap:	clx
.z:	stz s0bmp,x
	inx
	bne .z
	ldx #79
.u:	stz s0used,x
	dex
	bpl .u
	jsr s0ca
.a:	jsr s0cnext
	bcs .x
	jsr s0bset
	bra .a
.x:	rts
s0bset:	lda s0ctl
	and #7
	tay
	lda s0cth
	and #7
	sta q1
	lda s0ctl
	lsr q1
	ror a
	lsr q1
	ror a
	lsr q1
	ror a
	tax
	lda s0bmp,x
	ora s0bit,y
	sta s0bmp,x
	rts

s0ca:	lda #<s0pr
	ldy #>s0pr
s0cset:	sta s0cl
	sty s0ch
	stz s0ck
	rts
s0cnext:	lda s0cl
	sta .r0+1
	sta .r1+1
	sta .r2+1
	lda s0ch
	sta .r0+2
	sta .r1+2
	sta .r2+2
	ldy #2
.r2:	lda $FFFF,y             ; the run's count
	beq .end
	cmp s0ck
	bne .in
	lda s0cl                ; the next run
	clc
	adc #3
	sta s0cl
	bcc *+5
	inc s0ch
	stz s0ck
	bra s0cnext
.in:	cly
.r0:	lda $FFFF,y
	clc
	adc s0ck
	sta s0ctl
	iny
.r1:	lda $FFFF,y
	adc #0
	sta s0cth
	inc s0ck
	clc
	rts
.end:	sec
	rts

s0runs:	jsr s0sv34
	lda #S0DT
	tam #3
	lda #S0DW
	tam #4
	ldx #79                 ; (the scan's seen flags cleared: from here s0used is the cache's wants)
.u:	stz s0used,x
	dex
	bpl .u
	ldx #127
.h:	stz HD,x
	dex
	bpl .h
	lda #10
	sta q2                  ; row
	stz q3                  ; its WRUN offset
.row:	lda q2
	jsr s0nrow              ; .n's operand: NEARC row q2
	sta .n+1
	sty .n+2
	sta .m+1
	sty .m+2
	ldy q3
	lda #0
	sta WRUN,y              ; count
	iny
	clx
.c:	cpx #66
	beq .rd
.n:	lda NEARC,x
	inx
	cmp #$FF
	bne .c
	dex                     ; a run from x
	txa
	sta WRUN,y
	iny
.c2:	inx
	cpx #66
	beq .e
.m:	lda NEARC,x
	cmp #$FF
	beq .c2
.e:	txa
	dec a
	sta WRUN,y
	iny
	phy
	ldy q3
	lda WRUN,y
	inc a
	sta WRUN,y
	ply
	cmp #7
	bcc .c
	cpx #66
	beq .rd
	jsr s0rs34
	lda #6
	jmp s0refuse
.rd:	lda q3
	clc
	adc #16
	sta q3
	inc q2
	lda q2
	cmp #16
	bne .row
	jsr s0rows
	bcs .f
	jsr s0palpick
	bcs .f7
	lda q0                  ; (s0rows left the lintel lists' start in q0 / q1)
	sta s0hpl
	lda q1
	sta s0hph
	jsr s0lrng              ; rows 0-9: the near columns' range
	stz s0ng
	stz s0nga
	stz s0nw
	jsr s0ca
	jsr s0wtab              ; the resident water's tiles (pool indices WK0 on), the cursor back at the start ($78 at MPR3)
	php
	jsr s0rs34
	plp
	bcs .f8
	jmp s0next
.f8:	lda #8
	jmp s0refuse
.f:	jsr s0rs34
	lda q7
	jmp s0refuse
.f7:	jsr s0rs34
	lda #7
	jmp s0refuse
; A = row: A / Y = NEARC + row * 128 (MIDC: Y - (>NEARC - >MIDC))
s0nrow:	lsr a
	tay
	cla
	ror a
	pha
	tya
	clc
	adc #>NEARC
	tay
	pla
	rts

; rows 0-9 static (every mid frame alike in columns 0-31), and the rows' word blocks: a row of 10-15 whose mid words differ
; between frames has one block per frame and phase, the others one per phase. Carry set: refused (q7 the reason); q0 / q1 the
; lintel lists' start
s0rows:	stz q2                  ; row
.r:	lda q2
	jsr s0nrow
	sta .a+1
	sta .b+1
	tya
	sec
	sbc #NMD
	sta .a+2
	sta .b+2
	stz q4                  ; animated
	ldx #31
.c:	lda #3
	sta q5
	stz q7                  ; (this column animated)
	txa
	clc
	adc #32
	tay
.a:	lda MIDC,x
.b:	cmp MIDC,y
	beq .s
	inc q4
	inc q7
.s:	tya
	clc
	adc #32
	tay
	dec q5                  ; (y = x + 32, + 64, + 96: the three frames past the first)
	bne .a
	lda q2                  ; rows 10-15: ACOL[(row - 10) * 32 + column]
	sec
	sbc #10
	bcc .na
	asl a
	asl a
	asl a
	asl a
	asl a
	phx
	stx q6
	ora q6
	tax
	lda q7
	sta ACOL,x
	plx
.na:	dex
	bpl .c
	lda q2
	cmp #10
	bcs .bk
	lda q4
	bne *+5
	jmp .nx
	lda #5
	sta q7
	sec
	rts
.bk:	sta q6                  ; rows 10-15: the blocks (q0 / q1 the next free address)
	sec
	sbc #10
	tay
	lda q4
	sta s0anim,y
	lda q6
	lda q2
	cmp #10
	bne .k
	lda #<WTAB
	sta q0
	lda #>WTAB
	sta q1
.k:	stz q3                  ; phase
.p:	stz q5                  ; frame
.fa:	lda q5                  ; ROWT index: ((a * 3 + bi) * 6 + row - 10) * 2
	asl a
	clc
	adc q5
	adc q3
	sta q7
	asl a
	adc q7
	asl a
	clc
	adc q6
	sec
	sbc #10
	asl a
	tax
	lda q0
	sta ROWT,x
	lda q1
	sta ROWT+1,x
	lda q4
	beq .same
	lda q0                  ; a block for this frame
	clc
	adc #66
	sta q0
	bcc .same
	inc q1
.same:	inc q5
	lda q5
	cmp #4
	bne .fa
	lda q4
	bne .pn
	lda q0                  ; one block for the four frames
	clc
	adc #66
	sta q0
	bcc .pn
	inc q1
.pn:	inc q3
	lda q3
	cmp #3
	bne .p
.nx:	inc q2
	lda q2
	cmp #16
	beq .d
	jmp .r
.d:	clc
	rts

s0palpick:	ldy #3
.p:	lda s0pals,y
	sta s0pal
	asl a
	asl a
	asl a
	asl a
	asl a
	tax
	lda s0pal
	lsr a
	lsr a
	lsr a
	clc
	adc #>PALRAM
	sta .r+2
	stx .r+1
	ldx #31
.r:	lda $FFFF,x
	bne .n
	dex
	bpl .r
	clc
	rts
.n:	dey
	bpl .p
	sec
	rts
s0pals:	.db 14, 7, 8, 9

; a group for the key k1, k2, k3 of kind s0kk (0 band static, 1 lintel, 2 band water): A = the group. Carry set: refused (A the reason)
s0lk:	lda k2
	asl a
	eor k1
	eor k3
	and #63
	ldx s0kk
	cpx #1
	bne .h
	ora #64
.h:	sta q6                  ; the head
	tax
	lda HD,x
.w:	beq .new
	dec a
	tax
	lda G1,x
	cmp k1
	bne .nx
	lda G2,x
	cmp k2
	bne .nx
	lda G3,x
	cmp k3
	bne .nx
	lda GK,x                ; (a band pair matches a band pair of either kind)
	eor s0kk
	cmp #3
	beq .nx
	cmp #1
	beq .nx
	txa
	clc
	rts
.nx:	lda GNX,x
	bra .w
.new:	ldx s0ng
	cpx #255
	bne .ok
	lda #6
	sec
	rts
.ok:	lda s0kk
	cmp #2
	beq .room
	lda s0nga
	inc a
	jsr s0x3                ; (static and lintel groups + 1) * 3
	lda q0
	cmp #<(WK0 - S0PCUT + 1)
	lda q1
	sbc #>(WK0 - S0PCUT + 1)
	bcc .room
	lda #8
	sec
	rts
.room:	lda k1
	sta G1,x
	lda k2
	sta G2,x
	lda k3
	sta G3,x
	lda s0kk
	sta GK,x
	ldy q6
	lda HD,y
	sta GNX,x
	txa
	inc a
	sta HD,y
	lda #$10
	ldy s0kk
	cpy #1
	bne .pal
	lda s0pal
	asl a
	asl a
	asl a
	asl a
.pal:	sta q7
	lda s0kk
	cmp #2
	bne .ta                 ; (a water pair: its tiles the resident water's w; its index w in GW, its keys in WK1 / WK2)
	ldy s0nw
	cpy #WMAX
	bcc *+6
	lda #9
	sec
	rts
	tya
	sta GW,x
	lda k1
	sta WK1,y
	lda k2
	sta WK2,y
	inc s0nw
	bra .tw
.ta:	inc s0nga
	jsr s0cnext             ; its 3 tiles (X kept)
	lda s0ctl
	sta GW,x
	lda s0cth
	ora q7
	sta GW + $100,x
	jsr s0cnext
	lda s0ctl
	sta GW + $200,x
	lda s0cth
	ora q7
	sta GW + $300,x
	jsr s0cnext
	lda s0ctl
	sta GW + $400,x
	lda s0cth
	ora q7
	sta GW + $500,x
.tw:	inc s0ng
	lda s0kk                  ; the cache's wants
	cmp #1
	beq .lt
	lda k1
	jsr s0wm
	lda k2
	jsr s0wm
	bra .y
.lt:	lda k1
	jsr s0wnr
	lda k2
	jsr s0wnr
	lda k3
	beq .y
	ldy #48
	jsr s0wf
.y:	txa
	clc
	rts
s0wm:	cly                     ; want mid value A (band)
	bra s0wf
s0wnr:	cmp #$FF                ; want near code A
	beq s0wx
	ldy #32
s0wf:	phx
	sta q4
	jsr s0seen
	plx
s0wx:	rts

; q0 / q1 = A * 3 (X, Y kept)
s0x3:	sta q0
	stz q1
	asl a
	rol q1
	clc
	adc q0
	sta q0
	bcc .x
	inc q1
.x:	rts

; a band cell: X = x, q2 = row: the mid values of x - 1 and x of frame q5 in k1 / k2 (MIDC at MPR4)
s0pair:	lda q2
	jsr s0nrow
	sta .a+1
	sta .b+1
	tya
	sec
	sbc #NMD
	sta .a+2
	sta .b+2
	lda q5
	asl a
	asl a
	asl a
	asl a
	asl a
	sta q4                  ; frame * 32
	txa
	dec a
	and #31
	ora q4
	tay
.a:	lda MIDC,y
	sta k1
	txa
	and #31
	ora q4
	tay
.b:	lda MIDC,y
	sta k2
	stz k3
	rts
; carry set when x (X) is a band position of row q2: some run of WRUN reaches columns x .. x + 32 (WRUN at MPR3; q3 its offset)
s0pos:	ldy q3
	lda WRUN,y
	beq .n
	sta q4
	iny
.r:	lda WRUN + 1,y          ; last >= x
	stx q0
	cmp q0
	bcc .nx
	txa                     ; first <= x + 32
	clc
	adc #32
	cmp WRUN,y
	bcs .y
.nx:	iny
	iny
	dec q4
	bne .r
.n:	clc
	rts
.y:	sec
	rts
; carry set when cell x (X) of row q2 shows the same pair in every frame
s0stat:	lda q2                  ; static unless the column or its left neighbour animates (ACOL, $78 at MPR3)
	sec
	sbc #10
	asl a
	asl a
	asl a
	asl a
	asl a
	sta q6
	txa
	and #31
	ora q6
	tay
	lda ACOL,y
	bne .n
	txa
	dec a
	and #31
	ora q6
	tay
	lda ACOL,y
	bne .n
	sec
	rts
.n:	clc
	rts
; store the group A's word of phase q3 at ROWT (frame q5, phase q3, row q2) + x * 2 (X = x)
s0put:	tay                     ; (the group)
	ldx q5                  ; ROWT index ((a * 3 + bi) * 6 + row - 10) * 2 = s0m12[a * 3 + bi] + (row - 10) * 2
	lda s0m3,x
	clc
	adc q3
	tax
	lda s0m12,x
	clc
	adc s0r2
	tax
	lda ROWT,x              ; the row's block + x * 2
	clc
	adc s0x2
	sta .s+1
	sta .t+1
	lda ROWT+1,x
	adc #0
	sta .s+2
	sta .t+2
	lda s0pwf
	bne .w
	ldx q3                  ; the group's word of phase q3 (GW + bi * $200, high at + $100)
	lda s0gwp,x
	sta .l+2
	inc a
	sta .h+2
	tya
	tax
.l:	lda GW,x
	sta s0wl
.h:	lda GW + $100,x
	sta s0wh
.w:	ldx #0
	lda s0wl
.s:	sta $FFFF,x
	inx
	lda s0wh
.t:	sta $FFFF,x
	rts
s0m3:	.db 0, 3, 6, 9
s0m12:	.db 0, 12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 132
s0gwp:	.db (GW >> 8), (GW >> 8) + 2, (GW >> 8) + 4
; store the word s0wl / s0wh at ROWT (frame q5, phase q3, row q2) + x * 2 (X = x)
s0pword:	lda #1
	sta s0pwf
	jsr s0put
	stz s0pwf
	rts

; ---- step 2: the static band cells (pool A), a cell a piece: s0si row - 10, s0sj x
s0enb:	jsr s0sv34
	lda #S0DT
	tam #3
	lda #S0DW
	tam #4
	lda s0si
	clc
	adc #10
	sta q2
	lda s0si
	asl a
	asl a
	asl a
	asl a
	sta q3
	lda s0si
	asl a
	sta s0r2
	lda s0sj
	asl a
	sta s0x2
	ldx s0sj
	jsr s0pos
	bcs *+5
	jmp .nx
	jsr s0stat              ; static: one group for every frame (pool tiles); water: per frame (the resident water's groups). Pass 0 (s0sk) the static
	lda #2                  ; cells, pass 1 the water cells (after the row's frame-0 blocks are copied to the other frames)
	bcc *+4
	lda #0
	sta s0kk
	lsr a
	eor s0sk
	beq *+5
	jmp .nx
	stz q5                  ; frame
.fr:	ldx s0sj
	jsr s0pair
	jsr s0lk
	bcc *+5
	jmp .f
	sta q7
	lda s0kk
	beq .st
	jsr s0wmark             ; a water cell (WMASK); its pair: a static group's words, or the resident water's
	ldx q7
	lda GK,x
	cmp #2
	bne .st
	lda GW,x                ; (a water group's index w: its resident tiles)
	sta s0j
	stz q3
.wph:	jsr s0wword             ; the resident word of (w, phase q3) in s0wl / s0wh
	ldx s0sj
	jsr s0pword
	inc q3
	lda q3
	cmp #3
	bne .wph
	jmp .wn
.st:	stz q3
.ph:	lda q7
	ldx s0sj
	jsr s0put
.p1:	inc q3
	lda q3
	cmp #3
	bne .ph
	lda s0kk
	beq .nx
.wn:	inc q5
	lda q5
	cmp #4
	beq .nx
	jmp .fr
.nx:	inc s0sj
	lda s0sj
	cmp #33
	beq *+5
	jmp s0rs34
	stz s0sj
	ldy s0si                ; the row's pass done
	lda s0anim,y
	beq .rn                 ; (a row that does not animate: no water cells, no second pass)
	lda s0sk
	bne .rn
	jsr s0bcopy             ; frame 0's blocks of this row to frames 1-3, then the water pass
	inc s0sk
	jmp s0rs34
.rn:	stz s0sk
	jsr s0rs34
	inc s0si
	lda s0si
	cmp #6
	bne .x
	lda s0nw
	jsr s0x3
	lda q0
	sta s0wn
	lda q1
	sta s0wn+1
	jmp s0next
.x:	rts
.f:	pha
	jsr s0rs34
	pla
	jmp s0refuse
; row s0si + 10: its frame-0 blocks (3 phases) copied to frames 1-3 ($78 at MPR3)
s0bcopy:	stz q3                  ; phase
.p:	lda q3                  ; source: ROWT ((0 * 3 + bi) * 6 + row) * 2
	tax
	lda s0m12,x
	clc
	adc s0r2
	tax
	lda ROWT,x
	sta .t+1
	lda ROWT+1,x
	sta .t+2
	lda #1
	sta q5
.f:	ldx q5                  ; destination: frame q5
	lda s0m3,x
	clc
	adc q3
	tax
	lda s0m12,x
	clc
	adc s0r2
	tax
	lda ROWT,x
	sta .t+3
	lda ROWT+1,x
	sta .t+4
.t:	tii $6000, $6000, 66
	inc q5
	lda q5
	cmp #4
	bne .f
	inc q3
	lda q3
	cmp #3
	bne .p
	rts

; ---- step 3: the lintel's cells (rows 0-9), a row of one n a piece (s0si n, s0sj row), then that n's three lists
s0enl:	jsr s0sv34
	lda #S0DT
	tam #3
	lda #S0DW
	tam #4
	lda #1
	sta s0kk
	lda s0sj
	bne .r
	stz s0cbn
.r:	lda s0sj
	sta q2
	jsr s0nrow
	sta .a+1
	sta .b+1
	sty .a+2
	sty .b+2
	tya
	sec
	sbc #NMD
	sta .m+2
	lda .a+1
	sta .m+1
	clc                     ; (the near column n + x: the row's low byte + n)
	adc s0si
	sta .a+1
	inc a
	sta .b+1
	ldy q2                  ; cells x from (first near column - n - 1) to (last - n), within 0-32; none for a row without near tiles
	lda s0rmax,y
	cmp #$FF
	bne *+5
	jmp .rdn
	sec
	sbc s0si
	bcs *+5
	jmp .rdn
	cmp #33
	bcc *+4
	lda #32
	inc a
	sta s0xe
	lda s0rmin,y
	sec
	sbc s0si
	bcc .z0
	beq .z0
	dec a
	bra .z1
.z0:	cla
.z1:	tax
	cpx s0xe
	bcc .c
	jmp .rdn
.c:
.a:	lda NEARC,x
	sta k1
.b:	lda NEARC,x
	sta k2
	and k1
	cmp #$FF
	beq .nx                 ; (neither is near)
	stz k3
	lda k1
	cmp #$FF
	beq .mv
	lda k2
	cmp #$FF
	bne .lk
.mv:	txa                     ; the mid value under (frame 0)
	and #31
	tay
.m:	lda MIDC,y
	sta k3
.lk:	phx
	jsr s0lk
	plx
	bcs .f
	ldy s0cbn
	cpy #64
	bcs .f6
	sta s0cbg,y
	txa
	sta s0cbx,y
	lda q2
	sta s0cbr,y
	inc s0cbn
.nx:	inx
	cpx s0xe
	bne .c
.rdn:	inc s0sj
	lda s0sj
	cmp #10
	beq .emit
	jsr s0rs34
	rts
.f6:	lda #6
.f:	pha
	jsr s0rs34
	pla
	jmp s0refuse
.emit:	stz s0sj                ; n's three lists: [row, x0, count, words]... $FF; LIX (n * 3 + phase) * 2
	stz q3
.ph:	lda s0si
	asl a
	clc
	adc s0si
	adc q3
	asl a
	tax
	lda s0cbn
	bne .l
	stz LIX+1,x
	jmp .pn
.l:	lda s0hpl
	sta LIX,x
	lda s0hph
	sta LIX+1,x
	stz q4                  ; cell index
.run:	ldy q4                  ; a run: cells of one row with consecutive x
	lda s0cbr,y
	jsr s0hput
	lda s0cbx,y
	jsr s0hput
	lda s0hpl               ; (its count, filled in below)
	sta .cn+1
	lda s0hph
	sta .cn+2
	lda #0
	jsr s0hput
	stz q5
.cw:	ldy q4
	lda s0cbg,y
	tax
	lda q3
	asl a
	clc
	adc #>GW
	sta .wl+2
	inc a
	sta .wh+2
.wl:	lda GW,x
	jsr s0hput
.wh:	lda GW + $100,x
	jsr s0hput
	inc q5
	inc q4
	lda q4
	cmp s0cbn
	beq .re
	tay
	lda s0cbr,y
	cmp s0cbr - 1,y
	bne .re
	lda s0cbx,y
	dec a
	cmp s0cbx - 1,y
	beq .cw
.re:	lda q5
.cn:	sta $FFFF
	lda q4
	cmp s0cbn
	bne .run
	lda #$FF
	jsr s0hput
	bcc *+5
	jmp .f6
.pn:	inc q3
	lda q3
	cmp #3
	beq .nn
	jmp .ph
.nn:	jsr s0rs34
	inc s0si
	lda s0si
	cmp #33
	bne .x
	jsr s0sv34              ; the patch's run lists
	lda #S0DT
	tam #3
	lda #S0DE
	tam #4
	jsr s0plist
	php
	jsr s0rs34
	plp
	bcc *+7
	lda #6
	jmp s0refuse
	jmp s0next
.x:	rts
; A to the lintel lists' next byte (carry set when full)
s0hput:	sta $FFFF               ; (s0hpl / s0hph: this operand)
	inc s0hpl
	bne .c
	inc s0hph
.c:	lda s0hph
	cmp #>WEND
	rts
s0hpl      = s0hput + 1
s0hph      = s0hput + 2


s0cadr:	tya
	clc
	adc q3
	tam #3
	stz q1
	lda q2
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	sta q0
	lda q1
	clc
	adc #$60
	sta q1
	rts
s0marr:	lda #1
	bra s0madr
s0mawr:	cla
s0madr:	sta <VDCREG
	sta $0000
	lda s0cth
	sta q4
	lda s0ctl
	asl a
	rol q4
	asl a
	rol q4
	asl a
	rol q4
	asl a
	rol q4
	sta $0002
	lda q4
	sta $0003
	lda #2
	sta <VDCREG
	sta $0000
	rts
; ---- step 5: pool A's tiles in use saved ($74, $75), CHUNK tiles a piece (index q3:q2 in s0si / s0sj)
s0save:	lda s0sk
	bne .go
	inc s0sk
	jsr s0ca
	jsr s0nused
	stz s0pi
	stz s0pi+1
.go:	jsr s0sv34
	lda #8                  ; (8 tiles a piece: the setup also runs in the idle time of play)
	jsr s0pcopy
	php
	jsr s0rs34
	plp
	bcs .d
	rts
.d:	lda #1
	sta s0sv
	jmp s0next

s0pcopy:	sta q6
.t:	lda s0pi                ; left in all
	sec
	sbc s0wi
	lda s0pi+1
	sbc s0wi+1
	bcc *+3
	rts                     ; (carry set: done)
	jsr s0cpeek             ; the tile here and the run's tiles left (A)
	cmp #8
	bcc *+4
	lda #8
	sta q5
	lda s0pi                ; to the save bank's end
	eor #$FF
	inc a
	beq .b
	cmp q5
	bcs .b
	sta q5
.b:	lda s0wi                ; to the end
	sec
	sbc s0pi
	tax
	lda s0wi+1
	sbc s0pi+1
	bne .e
	cpx q5
	bcs .e
	stx q5
.e:	lda q5
	cmp q6
	bcc .k
	lda q6
	sta q5
.k:	lda s0pdir
	beq .k1
	lda s0aend2
	beq .k1
	jsr s0agpg
	bcc .sk
.k1:	lda s0pi
	sta q2
	lda s0pi+1
	sta q3
	jsr s0sadr
	lda q5                  ; 16-byte halves: tiles * 2, one block move each with the caller's interrupt flag between them
	asl a                   ; (a move holds an interrupt back at most about 105 cycles, 190 on the console with sprites on the
	sta q7
	lda q0
	sta .r+3
	sta .w+1
	lda q1
	sta .r+4
	sta .w+2
	php
	sei
	lda s0pdir
	bne .wr
	jsr s0marr
	bra .h
.wr:	jsr s0mawr
.h:	lda s0pdir
	bne .w
.r:	tai $0002, $6000, 16
	bra .n
.w:	tia $6000, $0002, 16
.n:	plp
	php
	sei
	lda .r+3
	clc
	adc #16
	sta .r+3
	sta .w+1
	bcc *+8
	inc .r+4
	inc .w+2
	dec q7
	bne .h
	plp
.sk:	lda q5
	jsr s0cadv
	lda s0pi
	clc
	adc q5
	sta s0pi
	bcc *+5
	inc s0pi+1
	lda q6
	sec
	sbc q5
	sta q6
	beq *+5
	jmp .t
	clc
	rts
; the chunk at the cursor's tile (q5 tiles) cut to that tile's page; carry clear when the page is the allocator's (from $10, below s0aend2)
s0agpg:	lda s0ctl
	and #15
	eor #15
	inc a
	cmp q5
	bcs .a
	sta q5
.a:	lda s0cth
	asl a
	asl a
	asl a
	asl a
	sta q7
	lda s0ctl
	lsr a
	lsr a
	lsr a
	lsr a
	ora q7
	cmp #$10
	bcc .k
	cmp s0aend2
	rts
.k:	sec
	rts
; the cursor's tile (s0ctl / s0cth) and A = the tiles left in its run (0 past the end)
s0cpeek:	lda s0cl
	sta .r0+1
	sta .r1+1
	sta .r2+1
	lda s0ch
	sta .r0+2
	sta .r1+2
	sta .r2+2
	ldy #0
.r0:	lda $FFFF,y
	clc
	adc s0ck
	sta s0ctl
	iny
.r1:	lda $FFFF,y
	adc #0
	sta s0cth
	iny
.r2:	lda $FFFF,y
	sec
	sbc s0ck
	rts
; the cursor A tiles on (inside one run)
s0cadv:	clc
	adc s0ck
	sta s0ck
	jsr s0cpeek
	bne .x
	lda s0cl
	clc
	adc #3
	sta s0cl
	bcc *+5
	inc s0ch
	stz s0ck
.x:	rts

s0prep:	jsr s0sv34
	lda #S0DC
	tam #3
	lda #S0DW               ; (the cache's list and the wants in $76's tail)
	tam #4
	lda s0si
	cmp #6
	bcs .n6
	jsr s0shift             ; (all six at once)
	lda #6
	sta s0si
	jmp s0rs34
.n6:	bne .n7
	jsr s0clist
	bcs .f
	inc s0si
	jmp s0rs34
.n7:	cmp #7
	bne .n8
	jsr s0cread
	jmp s0rs34
.n8:	cmp #8
	bne .n9
	jsr s0cmask
	jmp s0rs34
.n9:	cmp #9
	bne .n10
	lda #S0DT
	tam #4
	jsr s0palset
	bcs .f
	inc s0si
	stz s0sj
	jmp s0rs34
.n10:	jsr s0cremap
	jsr s0rs34
	lda s0si
	cmp #11
	bne .x
	jmp s0next
.x:	rts
.f:	pha
	jsr s0rs34
	pla
	jmp s0refuse

; shift table s0si: 0-2 SHL p = 2, 4, 6 (v << p), 3-5 SHR p = 2, 4, 6 (v >> (8 - p))
s0shift:	cly                     ; SHL p (v << p) at S0SH + (p / 2 - 1) * $100, SHR p (v >> (8 - p)) at + $300, p = 2, 4, 6
.l:	tya
	asl a
	asl a
	sta S0SH,y
	asl a
	asl a
	sta S0SH + $100,y
	asl a
	asl a
	sta S0SH + $200,y
	tya
	lsr a
	lsr a
	sta S0SH + $500,y
	lsr a
	lsr a
	sta S0SH + $400,y
	lsr a
	lsr a
	sta S0SH + $300,y
	iny
	bne .l
	rts

s0clist:	stz s0cff
	ldx #0
.c:	lda #$FF
	sta VMAP,x
	sta BMAP,x
	inx
	bne .c
	ldx #127
.n:	sta NMAP,x
	dex
	bpl .n
	stz s0nc
	stz q5                  ; value
.m:	lda q5                  ; band mid values
	ldy #0
	jsr s0want
	bcc .m1
	ldx q5
	lda s0nc
	sta VMAP,x
	lda q5
	jsr s0midt
	bcs .full
.m1:	inc q5
	bne .m
	lda s0nc
	sta s0cv                ; (the near tiles from here)
.k:	lda q5                  ; near codes
	ldy #32
	jsr s0want
	bcc .k1
	ldx q5
	lda s0nc
	sta NMAP,x
	lda q5
	clc
	adc s0bnl
	sta q0
	lda s0bnh
	adc #0
	jsr s0cadd
	bcs .full
.k1:	inc q5
	bpl .k
	stz q5
	lda s0nc
	sta s0cn                ; (the mid tiles under the lintel from here)
.b:	lda q5
	ldy #48
	jsr s0want
	bcc .b1
	ldx q5
	lda s0nc
	sta BMAP,x
	lda q5
	jsr s0midt
	bcs .full
.b1:	inc q5
	bne .b
	clc
	rts
.full:	lda s0cff
	bne .f4
	lda #10
.f4:	sec
	rts
; carry set: value A is flagged in s0used + Y
s0want:	sta q4
	lsr a
	lsr a
	lsr a
	sta q1
	tya
	clc
	adc q1
	tax
	lda q4
	and #7
	tay
	lda s0used,x
	and s0bit,y
	beq .n
	sec
	rts
.n:	clc
	rts
s0midt:	clc                     ; the mid word of value A to the cache's list
	adc s0bml
	sta q0
	lda s0bmh
	adc #0
s0cadd:	ldx s0nc                ; word A (high) / q0 (low) to the cache's list: carry set when full (or a pool tile: s0cfail 4)
	cpx #CMAX
	bcs .x
	pha
	jsr s0tchk
	pla
	bcs .p
	ldx s0nc
	and #7
	sta s0cht,x
	lda q0
	sta s0clt,x
	inc s0nc
	clc
	rts
.p:	lda #4
	sta s0cff
	sec
.x:	rts

; the cache's tiles, CHUNK a piece (s0sj the index): CACHE + j * 32
s0cread:	lda #CHUNK
	sta q6
.t:	lda s0sj
	cmp s0nc
	bcs .d
	tax
	lda s0clt,x
	sta s0ctl
	lda s0cht,x
	sta s0cth
	jsr s0cptr
	sta .r+3
	sty .r+4
	php
	sei
	jsr s0marr
.r:	tai $0002, $6000, 32
	plp
	inc s0sj
	dec q6
	bne .t
	rts
.d:	inc s0si
	lda s0cv                ; (the masks: from the near tiles on)
	sta s0sj
	stz s0mn
	stz s0mn+1
	stz s0mb
	stz s0mb+1
	rts
; A / Y = CACHE + s0sj * 32
s0cptr:	lda s0sj
	stz q1
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	pha
	lda q1
	clc
	adc #>CACHE
	tay
	pla
	rts

; A = a tile's low byte: X = A + 1, q2 = A + 16, q3 = A + 17 (no carry: tiles are 32-byte aligned); A kept
s0cops:	pha
	inc a
	tax
	clc
	adc #15
	sta q2
	inc a
	sta q3
	pla
	rts

; the colour indices used by cache tile s0sj (near tiles into s0mn, mid tiles under the lintel into s0mb), one a piece
s0cmask:	lda s0sj
	cmp s0nc
	bcc .t
	inc s0si
	rts
.t:	jsr s0cptr
	jsr s0cops
	sta .p0+1
	stx .p1+1
	sty .p0+2
	sty .p1+2
	sty .p2+2
	sty .p3+2
	lda q2
	sta .p2+1
	lda q3
	sta .p3+1
	stz q6                  ; the mask (lo, hi)
	stz q7
	clx                     ; row byte offset (0, 2, .. 14)
.r:
.p0:	lda $FFFF,x
	sta q0
.p1:	lda $FF01,x
	sta q1
.p2:	lda $FF10,x
	sta q2
.p3:	lda $FF11,x
	sta q3
	ldy #8
.px:	cla
	asl q3
	rol a
	asl q2
	rol a
	asl q1
	rol a
	asl q0
	rol a                   ; the pixel's index 0-15
	phy
	tay
	cmp #8
	bcs .h
	lda s0bit,y
	tsb q6
	bra .n
.h:	lda s0bit - 8,y
	tsb q7
.n:	ply
	dey
	bne .px
	inx
	inx
	cpx #16
	bne .r
	lda s0sj
	cmp s0cn
	bcs .b
	lda q6
	tsb s0mn
	lda q7
	tsb s0mn+1
	bra .x
.b:	lda q6
	tsb s0mb
	lda q7
	tsb s0mb+1
.x:	inc s0sj
	rts

PALSV4     = PALSV + $2000
s0palset:	ldx #31
.z:	stz s0pw,x
	dex
	bpl .z
	ldx #15
.z1:	stz s0rmp,x
	dex
	bpl .z1
	lda s0mn                ; taken: the near tiles' indices and 0
	ora #1
	sta q6
	lda s0mn+1
	sta q7
	ldx #1
.c0:	jsr s0used16
	bcc .c1
	txa
	asl a
	tay
	lda PALRAM,y
	sta s0pw,y
	lda PALRAM+1,y
	sta s0pw+1,y
.c1:	inx
	cpx #16
	bne .c0
	ldx #1                  ; each mid index j used under the lintel
.m:	lda s0mb
	sta q0
	lda s0mb+1
	sta q1
	jsr s0bit16
	bcc .mn
	txa
	asl a
	tay
	lda PALRAM + 32,y
	sta q2
	lda PALRAM + 33,y
	sta q3
	ldy #1                  ; a near index i of the same colour
.s:	phx
	tya
	tax
	lda s0mn
	sta q0
	lda s0mn+1
	sta q1
	jsr s0bit16
	plx
	bcc .s1
	tya
	asl a
	sta q4
	phy
	ldy q4
	lda s0pw,y
	cmp q2
	bne .s0
	lda s0pw+1,y
	cmp q3
.s0:	ply
	bne .s1
	tya
	sta s0rmp,x
	bra .mn
.s1:	iny
	cpy #16
	bne .s
	ldy #1                  ; else a free index
.f:	phx
	tya
	tax
	jsr s0used16
	plx
	bcc .take
	iny
	cpy #16
	bne .f
	lda #7
	sec
	rts
.take:	tya
	sta s0rmp,x
	phx
	tax
	jsr s0set16
	plx
	tya
	asl a
	tay
	lda q2
	sta s0pw,y
	lda q3
	sta s0pw+1,y
.mn:	inx
	cpx #16
	beq *+5
	jmp .m
	lda s0pal               ; PALRAM + p * 32 saved, the new words in
	asl a
	asl a
	asl a
	asl a
	asl a
	sta .a+1
	sta .b+1
	lda s0pal
	lsr a
	lsr a
	lsr a
	clc
	adc #>PALRAM
	sta .a+2
	sta .b+2
	ldx #31
.a:	lda $FFFF,x
	sta PALSV4,x
	lda s0pw,x
.b:	sta $FFFF,x
	dex
	bpl .a
	php                     ; the VCE's colours p * 16 .. saved, written when lit
	sei
	jsr s0vadr
	clx
.v:	lda $0404
	sta PALSV4 + 32,x
	lda $0405
	sta PALSV4 + 33,x
	inx
	inx
	cpx #32
	bne .v
	plp
	lda #1
	sta s0pl
	jsr s0lit
	beq .lit
	lda #1                  ; (made in a black: to the VCE once lit, s0vcew)
	sta s0vce
	bra .x
.lit:	php
	sei
	jsr s0vadr
	clx
.vw:	lda s0pw,x
	sta $0404
	lda s0pw+1,x
	sta $0405
	inx
	inx
	cpx #32
	bne .vw
	plp
.x:	clc
	rts
s0pw       = $7F00      ; (the spare palette's words being made: $77's tail, MPR3 in the prep)
; the VCE's address at the spare palette's first colour (interrupts off)
s0vadr:	lda s0pal
	asl a
	asl a
	asl a
	asl a
	sta $0402
	stz $0403
	rts
s0vcew:	lda s0vce
	beq .x
	jsr s0lit
	bne .x
	stz s0vce
	jsr s0sv34
	lda #S0DC
	tam #3
	lda s0pal
	lsr a
	lsr a
	lsr a
	clc
	adc #>PALRAM
	sta .p+2
	lda s0pal
	asl a
	asl a
	asl a
	asl a
	asl a
	sta .p+1
	jsr s0vadr
	clx
.s:	lda s0pw,x
.p:	sta $FFFF,x
	sta $0404
	inx
	lda s0pw,x
	jsr .p2
	sta $0405
	inx
	cpx #32
	bne .s
	jmp s0rs34
.p2:	pha                     ; (the high byte to PALRAM too: .p's address + X)
	lda .p+1
	sta .q+1
	lda .p+2
	sta .q+2
	pla
.q:	sta $FFFF,x
.x:	rts
s0lit:	php
	sei
	lda #17
	sta $0402
	stz $0403
	lda $0404
	cmp PALRAM + 34
	bne .x
	lda $0405               ; (the VCE reads back bit 0 of the high byte only: the rest of that byte is not data)
	eor PALRAM + 35
	and #1
.x:	php                     ; (the compare's Z through the flags' restore)
	pla
	and #2
	sta q4
	plp
	lda q4
	eor #2                  ; (Z set when the compare's Z was set)
	rts
; carry set: bit X of q6 / q7 (s0used16) or of q0 / q1 (s0bit16); s0set16 sets bit X of q6 / q7
s0used16:	lda q6
	sta q0
	lda q7
	sta q1
s0bit16:	phy
	txa
	and #7
	tay
	cpx #8
	bcs .h
	lda q0
	bra .t
.h:	lda q1
.t:	and s0bit,y
	ply
	cmp #1                  ; (carry set when non-zero)
	rts
s0set16:	phy
	txa
	and #7
	tay
	lda s0bit,y
	cpx #8
	bcs .h
	tsb q6
	ply
	rts
.h:	tsb q7
	ply
	rts

s0cremap:	lda s0sj
	cmp s0nc
	bcc .t
	inc s0si
	rts
.t:	cmp s0cn
	bcs .g
	lda s0cn
	sta s0sj
	bra s0cremap
.g:	jsr s0cptr
	jsr s0cops
	sta .p0+1
	sta .w0+1
	stx .p1+1
	stx .w1+1
	sty .p0+2
	sty .p1+2
	sty .p2+2
	sty .p3+2
	sty .w0+2
	sty .w1+2
	sty .w2+2
	sty .w3+2
	lda q2
	sta .p2+1
	sta .w2+1
	lda q3
	sta .p3+1
	sta .w3+1
	lda .p0+1
	clx
.r:
.p0:	lda $FFFF,x
	sta q0
.p1:	lda $FF01,x
	sta q1
.p2:	lda $FF10,x
	sta q2
.p3:	lda $FF11,x
	sta q3
	ldy #8
.px:	cla
	asl q3
	rol a
	asl q2
	rol a
	asl q1
	rol a
	asl q0
	rol a
	phx
	tax
	lda s0rmp,x
	plx
	lsr a                   ; the new index's planes into q4-q7
	rol q4
	lsr a
	rol q5
	lsr a
	rol q6
	lsr a
	rol q7
	dey
	bne .px
	lda q4
.w0:	sta $FFFF,x
	lda q5
.w1:	sta $FF01,x
	lda q6
.w2:	sta $FF10,x
	lda q7
.w3:	sta $FF11,x
	inx
	inx
	cpx #16
	bne .r
	inc s0sj
	rts

; ---- step 7: the composites, one group (3 tiles) a piece: s0si the group
s0comp:	lda s0si
	cmp s0ng
	bcc .go
	jmp s0next
.go:	jsr s0sv34
	lda #S0DC
	tam #3
	lda #S0DW
	tam #4
	ldx s0si
	lda GK,x
	cmp #2
	bne *+5
	jmp .d
	cmp #1
	bne .band
	jsr s0clint
	jmp .d
.band:	lda G1,x                ; band: L = the cache's tile of mid value G1, R of G2
	tay
	lda VMAP,y
	jsr s0cix
	sta .l0+1
	sta .l1+1
	stx .l0+2
	stx .l1+2
	ldx s0si
	lda G2,x
	tay
	lda VMAP,y
	jsr s0cix
	sta .r0+1               ; (bytes y, y + 1, y + 2, y + 3)
	stx .r0+2
	stx .r1+2
	stx .r2+2
	stx .r3+2
	inc a
	sta .r1+1
	inc a
	sta .r2+1
	inc a
	sta .r3+1
	lda .l0+1
	ldx .l0+2
	stx .l1+2
	stx .l2+2
	stx .l3+2
	inc a
	sta .l1+1
	inc a
	sta .l2+1
	inc a
	sta .l3+1
	jsr s0gseq              ; carry set: the group's 3 tiles follow each other in VRAM (one address for the three)
	ror s0sq
	stz q5                  ; phase bi: p = 8 - b = 6 - 2 bi: SHL at S0SH + (2 - bi) * $100, SHR at + $300
.ph:	lda #2
	sec
	sbc q5
	clc
	adc #>S0SH
	sta .s0+2
	sta .s1+2
	sta .s2+2
	sta .s3+2
	adc #3
	sta .t0+2
	sta .t1+2
	sta .t2+2
	sta .t3+2
	lda q5
	beq .g
	bit s0sq
	bmi .ng
	plp
.g:	jsr s0gtile             ; the group's tile of phase q5 at the VDC's write address (interrupts off)
.ng:	cly
.b:
.l0:	ldx $FFFF,y
.s0:	lda S0SH,x
.r0:	ldx $FFFF,y
.t0:	ora S0SH,x
	sta $0002
.l1:	ldx $FFFF,y
.s1:	lda S0SH,x
.r1:	ldx $FFFF,y
.t1:	ora S0SH,x
	sta $0003
.l2:	ldx $FFFF,y
.s2:	lda S0SH,x
.r2:	ldx $FFFF,y
.t2:	ora S0SH,x
	sta $0002
.l3:	ldx $FFFF,y
.s3:	lda S0SH,x
.r3:	ldx $FFFF,y
.t3:	ora S0SH,x
	sta $0003
	tya
	clc
	adc #4
	tay
	plp                     ; (after each two words: a pending interrupt gets in; the flags s0gtile pushed, pushed again)
	php
	sei
	cpy #32
	bne .b
	inc q5
	lda q5
	cmp #3
	beq *+5
	jmp .ph
	plp
.d:	jsr s0rs34
	inc s0si
	rts
; carry set when group s0si's tiles of phases 1 and 2 follow its phase-0 tile (GW, $76 at MPR4)
s0gseq:	ldx s0si
	lda GW,x
	inc a
	cmp GW + $200,x
	bne .n
	inc a
	cmp GW + $400,x
	bne .n
	lda GW + $100,x
	cmp GW + $300,x
	bne .n
	cmp GW + $500,x
	bne .n
	sec
	rts
.n:	clc
	rts
; A = cache index: A (lo) / X (hi) = CACHE + A * 32 (Y kept)
s0cix:	stz q1
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	asl a
	rol q1
	pha
	lda q1
	clc
	adc #>CACHE
	tax
	pla
	rts
; group s0si's tile of phase q5 at the VDC's write address: php / sei here, plp by the caller after its 16 words
s0gtile:	pla                     ; (the return address under the flags)
	sta q6
	pla
	sta q7
	php
	lda q7
	pha
	lda q6
	pha
	sei
	lda q5
	asl a
	clc
	adc #>GW
	sta .l+2
	inc a
	sta .h+2
	ldx s0si
.l:	lda GW,x
	sta s0ctl
.h:	lda GW + $100,x
	and #7
	sta s0cth
	jmp s0mawr
; a lintel group (X = s0si): near0 (G1, $FF none), near1 (G2), the mid tile under (G3, 0 none), per pixel run
s0clint:	lda G1,x
	sta k1
	lda G2,x
	sta k2
	lda G3,x
	sta k3
	lda k1
	cmp #$FF
	beq .a
	tay
	lda NMAP,y
	jsr s0cix
	sta .n0+1
	stx .n0+2
.a:	lda k2
	cmp #$FF
	beq .b
	tay
	lda NMAP,y
	jsr s0cix
	sta .n1+1
	stx .n1+2
.b:	lda k3
	beq .c
	tay
	lda BMAP,y
	jsr s0cix
	sta .m0+1
	stx .m0+2
	sta .m1+1
	stx .m1+2
.c:	stz q5                  ; phase bi: b = p = 2 bi + 2: SHL at S0SH + bi * $100, SHR at + $300
.ph:	lda q5
	clc
	adc #>S0SH
	sta .s+2
	sta .ml+2
	adc #3
	sta .t+2
	sta .mr+2
	jsr s0gtile
	cly
.y:	lda k1                  ; left part: near0 << b, or the mid's left 8 - b px
	cmp #$FF
	beq .lm
.n0:	ldx $FFFF,y
.s:	lda S0SH,x
	bra .r
.lm:	ldx #$FF
.ml:	lda S0SH,x
.m0:	and $FFFF,y
.r:	sta q4
	lda k2                  ; right part: near1 >> (8 - b), or the mid's right b px
	cmp #$FF
	beq .rm
.n1:	ldx $FFFF,y
.t:	lda S0SH,x
	bra .o
.rm:	ldx #$FF
.mr:	lda S0SH,x
.m1:	and $FFFF,y
.o:	ora q4
	pha
	tya
	lsr a
	pla
	bcs .hi
	sta $0002
	bra .nx
.hi:	sta $0003
	plp                     ; (after each word: a pending interrupt gets in; the flags s0gtile pushed, pushed again)
	php
	sei
.nx:	iny
	cpy #32
	bne .y
	plp
	inc q5
	lda q5
	cmp #3
	bne .ph
	rts

; ---- step 9: engaged (the band published; the patch and the swap from the next pass)
s0engage:	stz BBXR
	stz BBXR+1
	jsr s0hon
	lda #S0ENG
	sta s0st
	lda FRAMES
	sta s0t1
	sta s0tst + 8
	inc s0neng
	rts

; ---- the exit: pool A's tiles back from $74 / $75 (all at once: the screen is black or the camera at an end)
s0rest:	jsr s0sv34
	jsr s0ca
	jsr s0nused
	stz s0pi
	stz s0pi+1
	lda #1
	sta s0pdir
.l:	lda #255
	jsr s0pcopy
	bcc .l
	stz s0pdir
	jmp s0rs34
s0palback:	jsr s0sv34
	lda #S0DT
	tam #3
	lda s0pal
	asl a
	asl a
	asl a
	asl a
	asl a
	sta .b+1
	lda s0pal
	lsr a
	lsr a
	lsr a
	clc
	adc #>PALRAM
	sta .b+2
	ldx #31
.a:	lda PALSV,x
.b:	sta $FFFF,x
	dex
	bpl .a
	php
	sei
	jsr s0vadr
	clx
.v:	lda PALSV + 32,x
	sta $0404
	lda PALSV + 33,x
	sta $0405
	inx
	inx
	cpx #32
	bne .v
	plp
	jmp s0rs34

; ---------------------------------------------------------------- the patch (satbody, interrupts off; a pass in time, b != 0)
; Rows 10-15: each run of empty near columns that meets the window, its words from the row's block of this frame and phase;
; rows 0-9: the lintel's list of this n and phase. One MAWR and one TIA a run; a pending interrupt is let in between runs.
s0patch:	jsr s0sv34
	lda #S0DT
	tam #3
	inc s0np
	bne *+5
	inc s0np+1
	lda s0b                 ; bi = b / 2 - 1
	lsr a
	dec a
	sta q6
	lda s0a                 ; ROWT index of row 10: (a * 3 + bi) * 12
	asl a
	clc
	adc s0a
	adc q6
	sta q0
	asl a
	adc q0
	asl a
	asl a
	sta q2                  ; (ROWT offset, +2 a row)
	sta s0pq2               ; (ROWT offset of row 10, +2 a row)
	lda #S0DE               ; the runs of camera tile n (s0plist): [row, x0, x1]..., $FF
	tam #4
	lda s0n
	asl a
	tax
	lda PLI,x
	sta .g0+1
	sta .g1+1
	sta .g2+1
	lda PLI+1,x
	sta .g0+2
	sta .g1+2
	sta .g2+2
.gl:	ldy #0
.g0:	lda $FFFF,y
	cmp #$FF
	beq .gle
	sta q3
	iny
.g1:	lda $FFFF,y
	sta k1
	iny
.g2:	lda $FFFF,y
	sta k2
	lda q3                  ; q2 = ROWT offset of this row
	sec
	sbc #10
	asl a
	clc
	adc s0pq2
	sta q2
	lda s0fall
	beq .gall
	jsr s0psplit
	bra .gnx
.gall:	jsr s0prun
.gnx:	lda .g0+1                ; the next entry
	clc
	adc #3
	sta .g0+1
	sta .g1+1
	sta .g2+1
	bcc .gl
	inc .g0+2
	inc .g1+2
	inc .g2+2
	bra .gl
.gle:
	lda s0n                 ; the lintel: LIX (n * 3 + bi) * 2
	asl a
	clc
	adc s0n
	adc q6
	asl a
	tax
	lda LIX+1,x
	beq .x
	sta .e0+2
	lda LIX,x
	sta .e0+1
.ent:	lda .e0+1               ; [row, x0, count, words]
	sta .e1+1
	sta .e2+1
	lda .e0+2
	sta .e1+2
	sta .e2+2
.e0:	lda $FFFF
	cmp #$FF
	beq .x
	sta q3
	ldy #1
.e1:	lda $FFFF,y
	sta k1
	iny
.e2:	lda $FFFF,y
	asl a
	sta .u+5
	cli
	nop
	sei
	lda s0bf
	clc
	adc q3
	jsr s0brow
	lda .e0+1               ; the words: entry + 3
	clc
	adc #3
	sta .u+1
	lda .e0+2
	adc #0
	sta .u+2
.u:	tia $6000, $0002, 0
	lda .u+1                ; the next entry: past the words
	clc
	adc .u+5
	sta .e0+1
	lda .u+2
	adc #0
	sta .e0+2
	bra .ent
.x:	jmp s0rs34
; the VDC's write address at BAT row A, column 2 + k1, VWR selected
s0brow:	stz q7
	lsr a                   ; row * 64 = (row << 6): high row >> 2, low (row & 3) << 6
	ror q7
	lsr a
	ror q7
	sta q1
	lda k1
	clc
	adc #2
	ora q7
	sta q0
	cla
	sta <VDCREG
	sta $0000
	lda q0
	sta $0002
	lda q1
	sta $0003
	lda #2
	sta <VDCREG
	sta $0000
	rts
; ---------------------------------------------------------------- the one pool's helpers
; s0wi = the pool tiles saved and restored: WK0 + the water's tiles
s0nused:	lda #<WK0               ; (static and lintel below WK0, the water from it: all saved and restored, the unused gap between too)
	clc
	adc s0wn
	sta s0wi
	lda #>WK0
	adc s0wn+1
	sta s0wi+1
	rts
s0sadr:	ldy q3
	lda s0sbk,y
	tam #3
	ldy #S0DA               ; (q0 / q1 as s0cadr's, its bank overwritten below)
	lda q3
	pha
	stz q3
	jsr s0cadr
	pla
	sta q3
	tay
	lda s0sbk,y
	tam #3
	rts
s0sbk:	.db S0DA, S0DA + 1, S0D9, S0DE
; the resident water's tiles: pool indices WK0 .. WK0 + 3 * WMAX - 1 into WTL / WTH by phase and group, then the cursor back at the
; pool's start (static and lintel from index 0); WMASK cleared ($78 at MPR3). Carry set: the pool short
s0wtab:	lda #<WK0
	sta q4
	lda #>WK0
	sta q5
.s:	jsr s0cnext             ; (WK0 tiles skipped)
	bcs .x
	lda q4
	bne .d
	dec q5
.d:	dec q4
	lda q4
	ora q5
	bne .s
	clx
.t:	jsr s0cnext
	bcs .x
	lda s0ctl
	sta WTL,x
	lda s0cth
	sta WTH,x
	jsr s0cnext
	bcs .x
	lda s0ctl
	sta WTL + WMAX,x
	lda s0cth
	sta WTH + WMAX,x
	jsr s0cnext
	bcs .x
	lda s0ctl
	sta WTL + 2 * WMAX,x
	lda s0cth
	sta WTH + 2 * WMAX,x
	inx
	cpx #WMAX
	bne .t
	jsr s0ca
	ldx #29
.m:	stz WMASK,x
	dex
	bpl .m
	clc
.x:	rts
; A = phase bi, X = water group w: A = its resident tile's low byte, Y = the high
s0wtile:	cmp #1
	beq .b1
	bcs .b2
	ldy WTH,x
	lda WTL,x
	rts
.b1:	ldy WTH + WMAX,x
	lda WTL + WMAX,x
	rts
.b2:	ldy WTH + 2 * WMAX,x
	lda WTL + 2 * WMAX,x
	rts
; WMASK: cell (row q2, x s0sj) is a water cell
s0wmark:	lda q2
	sec
	sbc #10
	sta q0
	asl a
	asl a
	adc q0                  ; (row - 10) * 5
	sta q0
	lda s0sj
	lsr a
	lsr a
	lsr a
	clc
	adc q0
	tax
	lda s0sj
	and #7
	tay
	lda s0bit,y
	ora WMASK,x
	sta WMASK,x
	rts
s0wword:	lda q3
	ldx s0j
	jsr s0wtile
	sta s0wl
	tya
	ora #$10
	sta s0wh
	rts

; ---------------------------------------------------------------- the patch's runs ($78 at MPR3, interrupts off)
; one run: row q3, x k1 .. k2, the words from ROWT (offset q2) + x * 2
s0prun:	cli                     ; (an interrupt waiting gets in here)
	nop
	sei
	lda s0bf                ; MAWR = (buffer + row) * 64 + 2 + x0
	clc
	adc q3
	jsr s0brow
	ldx q2                  ; the words: ROWT + x0 * 2
	lda k1
	asl a
	clc
	adc ROWT,x
	sta .t+1
	lda ROWT+1,x
	adc #0
	sta .t+2
	lda k2                  ; bytes (x1 - x0 + 1) * 2
	sec
	sbc k1
	inc a
	asl a
	sta .t+5
.t:	tia $6000, $0002, 0
	rts
s0psplit:	lda k2
	sta s0x1
	lda q3
	sec
	sbc #10
	sta q0
	asl a
	asl a
	adc q0
	sta s0mr                ; this row's WMASK offset
	ldx k1
.c:	stx s0x0                ; skip water cells
.w:	cpx s0x1
	beq .w1
	bcs .x
.w1:	jsr s0wat
	bcc .e
	inx
	bra .w
.e:	stx k1                  ; a run of other cells
.e1:	inx
	cpx s0x1
	beq .e2
	bcs .em
.e2:	jsr s0wat
	bcc .e1
.em:	dex
	stx k2
	phx
	jsr s0prun
	plx
	inx
	bra .c
.x:	rts
; carry set when x (X) is a water cell of this row (X kept)
s0wat:	phx
	txa
	and #7
	tay
	txa
	lsr a
	lsr a
	lsr a
	clc
	adc s0mr
	tax
	lda WMASK,x
	plx
	and s0bit,y
	cmp #1
	rts

s0ework:	lda FRAMES              ; (a frame whose pass ran long: nothing)
	cmp pfr
	bne .x
	sta s0fr
.l:	lda s0wrdy
	bne .r
	jsr s0wcomp
	bra .c
.r:	cmp #2
	bcs .x                  ; (resident, or lost to the allocator)
	jsr s0wup
.c:	lda FRAMES
	cmp s0fr
	beq .l
.x:	rts

s0wcomp:	lda s0wc
	cmp s0nw
	bcc .go
	lda #1
	sta s0wrdy
	rts
.go:	jsr s0sv34
	lda #S0DT               ; (its keys)
	tam #4
	ldx s0wc
	lda WK1 + $2000,x
	sta k1
	lda WK2 + $2000,x
	sta k2
	lda #S0DC
	tam #3
	lda k1
	tay
	lda VMAP,y
	jsr s0cix
	sta .l0+1
	stx .l0+2
	sta .l1+1
	stx .l1+2
	lda k2
	tay
	lda VMAP,y
	jsr s0cix
	sta .r0+1
	stx .r0+2
	sta .r1+1
	stx .r1+2
	lda s0wc
	jsr s0x3                ; c of phase 0
	stz q5
.ph:	lda q0                  ; the copy's bank and address (MPR4)
	cmp #<WCAP
	lda q1
	sbc #>WCAP
	bcs .e
	lda #S0DW
	tam #4
	lda q0
	ldx q1
	ldy #$83
	bra .a
.e:	lda #S0DE
	tam #4
	lda q0
	sec
	sbc #<WCAP
	ldx q1
	bcs *+3
	dex
	ldy #$8C
.a:	jsr s0c32
	sta .d0+2
	sta .d1+2
	lda q2
	sta .d0+1
	sta .d1+1
	lda #2                  ; p = 8 - b = 6 - 2 bi
	sec
	sbc q5
	clc
	adc #>S0SH
	sta .s0+2
	sta .s1+2
	adc #3
	sta .t0+2
	sta .t1+2
	cly
.b:
.l0:	ldx $FFFF,y
.s0:	lda S0SH,x
.r0:	ldx $FFFF,y
.t0:	ora S0SH,x
.d0:	sta $FFFF,y
	iny
.l1:	ldx $FFFF,y
.s1:	lda S0SH,x
.r1:	ldx $FFFF,y
.t1:	ora S0SH,x
.d1:	sta $FFFF,y
	iny
	cpy #32
	bne .b
	inc q0
	bne *+5
	inc q1
	inc q5
	lda q5
	cmp #3
	beq *+5
	jmp .ph
	inc s0wc
	jmp s0rs34
; (s0wcomp's destination: Y = page, X:A = the copy index past its base: .d0 / .d1 = Y:$00 + (X:A) * 32 (+ $40 for $7A's base))
s0c32:	sta q2
	stx q3
	stz q4
	asl q2
	rol q3
	asl q2
	rol q3
	asl q2
	rol q3
	asl q2
	rol q3
	asl q2
	rol q3
	cpy #$8C
	bne .n
	lda q2
	clc
	adc #$40
	sta q2
	bcc .n
	inc q3
.n:	tya
	clc
	adc q3                  ; (A = the page, q2 the low byte)
	rts

s0wup:	jsr s0sv34
	lda #S0DT
	tam #3
	lda #CHUNK
	sta q6
.t:	lda s0wun
	cmp s0wn
	lda s0wun+1
	sbc s0wn+1
	bcc .go
	lda #2
	sta s0wrdy
	bra .o
.go:	lda s0wun
	sta q0
	lda s0wun+1
	sta q1
	jsr s0csrc              ; MPR4 and s0srl / s0srh
	lda s0srl
	sta .w+1
	lda s0srh
	sta .w+2
	lda s0ub
	ldx s0uw
	jsr s0wtile
	sta s0ctl
	sty s0cth
	php
	sei
	jsr s0mawr
.w:	tia $8000, $0002, 32
	plp
	inc s0wun
	bne *+5
	inc s0wun+1
	inc s0ub
	lda s0ub
	cmp #3
	bne .n
	stz s0ub
	inc s0uw
.n:	dec q6
	bne .t
.o:	jmp s0rs34
s0csrc:	lda q0
	cmp #<WCAP
	lda q1
	sbc #>WCAP
	bcs .e
	lda #S0DW
	tam #4
	lda q0
	ldx q1
	ldy #$83
	bra .a
.e:	lda #S0DE
	tam #4
	lda q0
	sec
	sbc #<WCAP
	ldx q1
	bcs *+3
	dex
	ldy #$8C
.a:	jsr s0c32
	sta s0srh
	lda q2
	sta s0srl
	rts
; A = a frame: X = its slot (A & 1); carry clear when that slot does not hold it and no BAT buffer holds the slot's words (A kept)
; rows 0-9: the first and last near column (0-65) of each row in s0rmin / s0rmax ($FF / $FF: none). NEARC ($76) at MPR4
s0lrng:	stz q2
.r:	lda q2
	jsr s0nrow
	sta .n+1
	sty .n+2
	ldy q2
	lda #$FF
	sta s0rmin,y
	sta s0rmax,y
	clx
.c:
.n:	lda NEARC,x
	cmp #$FF
	beq .e
	txa
	sta s0rmax,y
	lda s0rmin,y
	cmp #$FF
	bne .e
	txa
	sta s0rmin,y
.e:	inx
	cpx #66
	bne .c
	inc q2
	lda q2
	cmp #10
	bne .r
	rts

s0farq:	stz s0far
	lda s0aend
	beq .x
	lda $311F               ; (screen X high: off screen or wrapped: not far)
	bne .x
	lda s0cam0+1
	beq .r
	lda #136 - 96           ; left end: X <= 40
	cmp $30DB
	bcc .x
	bra .y
.r:	lda $30DB               ; right end: X >= 208
	cmp #112 + 96
	bcc .x
.y:	inc s0far
.x:	rts

PLI        = $9700
PLH        = $9750
PLEND      = $9FF0
s0plist:	lda #<PLH
	sta .w+1
	lda #>PLH
	sta .w+2
	stz q6                  ; n
.n:	lda q6
	asl a
	tax
	lda .w+1
	sta PLI,x
	lda .w+2
	sta PLI+1,x
	lda #10
	sta q3
	stz q4
.row:	ldy q4
	lda WRUN,y
	sta q5
	iny
.run:	lda q5
	beq .nr
	dec q5
	lda WRUN,y
	sta k1
	iny
	lda WRUN,y
	iny
	sec
	sbc q6
	bcc .run
	cmp #33
	bcc *+4
	lda #32
	sta k2
	lda k1
	sec
	sbc q6
	bcs .p
	cla
.p:	cmp #33
	bcs .nr
	sta k1
	lda q3
	jsr .put
	lda k1
	jsr .put
	lda k2
	jsr .put
	bcs .x
	bra .run
.nr:	lda q4
	clc
	adc #16
	sta q4
	inc q3
	lda q3
	cmp #16
	bne .row
	lda #$FF
	jsr .put
	bcs .x
	inc q6
	lda q6
	cmp #33
	beq *+5
	jmp .n
	clc
.x:	rts
.put:
.w:	sta $FFFF
	inc .w+1
	bne *+5
	inc .w+2
	lda .w+2
	cmp #>PLEND
	rts

s0cend:
