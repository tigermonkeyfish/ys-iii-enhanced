
R2H        = $11
Q8HT       = $10
Q8STOP     = 106

c8jt:	.dw q8idle              ; 0: (cidle, every idle once band 1's store is ready) the bridge's store built or found, in slices

q8co:	.db 0           ; the coroutine (as the second overlay's)
q8sp:	.db 0
q8n:	.db 0
q8sv:	.ds 16
q8m4:	.db 0
q8mr4:	.db 0
q8ra:	.db 0
q8rx:	.db 0
q8ry:	.db 0
q8t9:	.db 0
q8hb:	.ds 16          ; the header read or written
Q8HM:	.db 'Y', '3', 'C', 2, 1, <CBKEY, >CBKEY
q8s:	.dw 0           ; the sum, its pages left, its page
q8pg:	.dw 0
q8sm:	.db 0
q8sh:	.db 0
q8err:	.db 0
q8ni:	.dw 0           ; images made
q8w:	.dw 0
q8p:	.db 0           ; period, row, cell, cn, cm, h, ranks
q8r:	.db 0
q8j:	.db 0
q8cn:	.db 0
q8cm:	.db 0
q8h:	.db 0
q8nu:	.db 0
q8tp:	.db 0, 0, 0     ; the template row's place
q8lm:	.db 0           ; the period's list block (mid, high)
q8lh:	.db 0
q8fp:	.dw 0           ; FW's row
q8pl:	.ds 4           ; the lists (0 pairs, 1 ends, 2 ends0, 3 midp): the next byte's place, the row's count byte's place, the count
q8pm:	.ds 4
q8ph:	.ds 4
q8cl:	.ds 4
q8cmm:	.ds 4
q8chh:	.ds 4
q8c:	.ds 4
Q8LO:	.db $10, $00, $20, $60
Q8LM:	.db 0, 2, 4, 4
Q8PH:	.db (>MIXBASE) | (PALF << 4), (>MIXBASE) | (PALM << 4), (>MIXBASE) | (4 << 4)
Q8K:	.db 0, 1, 3, 7, $0F, $1F, $3F, $7F
q8na:	.db 0
q8nb:	.db 0
q8ma:	.db 0
q8mb:	.db 0
q8ns:	.db 0
q8ms:	.db 0
q8ea:	.db 0
q8eb:	.db 0
q8fw:	.dw 0
q8pc:	.db 0
q8k0:	.db 0
q8k:	.ds 6           ; the key, its hash, its entry
q8hl:	.db 0
q8hh:	.db 0
q8e:	.ds 16
q8t:	.db 0, 0, 0
q8kk:	.db 0
q8d:	.db 0
q8sd:	.db 0
q8mo:	.db 0
q8rr:	.db 0
q8b:	.ds 4
q8o:	.ds 4
q8M:	.ds 80
q8S:	.ds 128
q8ib:	.ds 32
q8rb:	.ds 66

; ---------------------------------------------------------------- helpers
q8b0:	sta $1A02               ; port 0's base = A / X / Y
	stx $1A03
	sty $1A04
	rts
; image q8w -> A low, X mid, Y high (IMG + 32 q8w)
q8ia:	lda q8w + 1
	sta q8t
	lda q8w
	lsr q8t
	ror a
	lsr q8t
	ror a
	lsr q8t
	ror a
	tax
	lda q8t
	clc
	adc #R2H + 2
	tay
	lda q8w
	asl a
	asl a
	asl a
	asl a
	asl a
	rts
; the table's entry of hash q8hh : q8hl (16 x): A low, X mid, Y high
q8ha:	lda q8hh
	sta q8t
	lda q8hl
	lsr q8t
	ror a
	lsr q8t
	ror a
	lsr q8t
	ror a
	lsr q8t
	ror a
	tax
	lda q8hl
	asl a
	asl a
	asl a
	asl a
	ldy #Q8HT
	rts
; a byte A to list X (kept), its place moved on
q8lw:	pha
	lda q8pl,x
	sta $1A02
	lda q8pm,x
	sta $1A03
	lda q8ph,x
	sta $1A04
	pla
	sta $1A00
	inc q8pl,x
	bne .x
	inc q8pm,x
	bne .x
	inc q8ph,x
.x:	rts
; an entry of list X: (2 j, A)
q8ent2:	stx q8sd
	pha
	lda q8j
	asl a
	jsr q8lw
	pla
	jsr q8lw
	inc q8c,x
	rts
q8ent3:	lda q8j
	asl a
	jsr q8lw
	lda q8e + 11
	jsr q8lw
	ldy q8pc
	lda Q8PH,y
	jsr q8lw
	inc q8c,x
	rts

; ================================================================ the idle's slice (carry set: over: brst 1 ready, $FF given up)
q8idle:	tma #4
	sta q8m4
	tsx
	stx q8sp
	lda FRAMES              ; the idle's frame is the stub's t0 (waitfix's sample: its wait returns once FRAMES leaves it). The vblank
	cmp STUB_T0OK - 7       ; went by already (the edge keys' step before this ran over): nothing, and no wait (a wait here was a
	bne .nv
	cmp q8vf
	bne .sp
	jsr q8tm                ; (the clock first: a slice that begins late, after the edge keys' step or a long pass, takes no step and
	bcc .go                 ; restores nothing: straight to the wait)
.sp:	jmp q8spin
.nv:	clc
	rts
.go:	lda q8co
	bne .res
	inc q8co
	jsr q8build
	stz q8co
	lda q8m4
	tam #4
	bcc .ok
	lda #$FE
	sta brst
.ok:	sec
	rts
.res:	ldx q8n
.p:	lda q8sv - 1,x
	pha
	dex
	bne .p
	lda q8mr4
	tam #4
	lda q8ra
	ldx q8rx
	ldy q8ry
	rts
; carry set: Q8STOP ticks or more since the stamped vblank
q8tm:	lda TIMER
	and #$7F
	sta q8t9
	lda q8vb
	sec
	sbc q8t9
	bcs *+4
	adc #116
	cmp #Q8STOP
	rts
q8yck:	sta q8ra
	lda FRAMES
	cmp q8vf
	bne .y
	jsr q8tm
	bcs .y
	lda q8ra
	rts
.y:	stx q8rx
	sty q8ry
	tma #4
	sta q8mr4
	tsx
	stx q8t9
	lda q8sp
	sec
	sbc q8t9
	sta q8n
	cly
.c:	inx
	lda $2100,x
	sta q8sv,y
	iny
	cpy q8n
	bne .c
	ldx q8sp
	txs
	lda q8m4
	tam #4
	lda FRAMES
	cmp q8vf
	beq q8spin
	clc
	rts
q8spin:	lda TIMER
	and #$7F
	tax
.s:	stx q8vb
	lda TIMER
	and #$7F
	tax
	lda FRAMES
	cmp STUB_T0OK - 7
	beq .s
	sta q8vf
	clc
	rts

; ================================================================ the store found or built (carry set: given up)
q8build:	lda r2valid             ; a store this power-on built or found for this layout: used as it is
	beq .hd
	lda r2tag
	cmp rtag
	bne .bld
	lda r2tag + 1
	cmp rtag + 1
	bne .bld
	clc
	rts
.hd:	jsr q8hdr
	bcs .bld
	jmp q8good
.bld:	stz r2valid
	cla                     ; a build begins: no header
	clx
	ldy #R2H
	jsr q8b0
	stz $1A00
	stz q8sm                ; the records' table emptied
.hc:	jsr q8yck
	cla
	ldx q8sm
	ldy #Q8HT
	jsr q8b0
	cly
.hz:	stz $1A00
	iny
	bne .hz
	inc q8sm
	bpl .hc
	jsr q8maps
	lda q8M + 32 + 9
	bne *+7
	lda #4
	sta q8M + 32 + 9
	stz q8ni
	stz q8ni + 1
	stz q8err
	stz q8tp
	lda #1
	sta q8tp + 1
	lda #R2H
	sta q8tp + 2
	sta q8lh
	lda #$B0
	sta q8lm
	stz q8p
.p:	jsr q8per
	inc q8p
	lda q8p
	cmp #41
	bne .p
	lda q8err
	beq .seal
	sec
	rts
.seal:	jsr q8sum               ; sealed: the sum, then the header
	ldx #6
.c:	lda Q8HM,x
	sta q8hb,x
	dex
	bpl .c
	lda rtag
	sta q8hb + 7
	lda rtag + 1
	sta q8hb + 8
	lda q8ni
	sta q8hb + 9
	lda q8ni + 1
	sta q8hb + 10
	lda q8s
	sta q8hb + 12
	lda q8s + 1
	sta q8hb + 13
	cla
	clx
	ldy #R2H
	jsr q8b0
	tia q8hb, $1A00, 16
q8good:	lda rtag
	sta r2tag
	lda rtag + 1
	sta r2tag + 1
	lda #1
	sta r2valid
	clc
	rts
; q8s = the store's sum, read back through port 1 a page at a step: $11:0100 to the images' end (511 pages of templates and lists, then
; the images': contiguous); a page's bytes summed with the carry going round, the page sums folded (low += s, high += low)
q8sum:	lda q8ni
	clc
	adc #7
	sta q8pg
	lda q8ni + 1
	adc #0
	lsr a
	ror q8pg
	lsr a
	ror q8pg
	lsr a
	ror q8pg
	sta q8pg + 1
	lda q8pg
	clc
	adc #$FF
	sta q8pg
	lda q8pg + 1
	adc #1
	sta q8pg + 1
	lda #1
	sta q8sm
	lda #R2H
	sta q8sh
	stz q8s
	stz q8s + 1
.pg:	jsr q8yck
	cla
	ldx q8sm
	ldy q8sh
	jsr cb1
	cla
	clc
	cly
.b:	adc $1A10
	iny
	bne .b
	adc #0
	clc
	adc q8s
	sta q8s
	clc
	adc q8s + 1
	sta q8s + 1
	inc q8sm
	bne *+5
	inc q8sh
	lda q8pg
	bne *+5
	dec q8pg + 1
	dec q8pg
	lda q8pg
	ora q8pg + 1
	bne .pg
	rts
; ---------------------------------------------------------------- one period (q8p): its template rows and lists
q8per:	lda q8p
	clc
	adc #CNB0
	sta q8cn
	lsr a
	sta q8cm
	lda q8cn
	and #1
	sta q8h
	stz q8nu
	ldx #3
.l:	lda Q8LO,x
	sta q8pl,x
	lda q8lm
	clc
	adc Q8LM,x
	sta q8pm,x
	lda q8lh
	sta q8ph,x
	dex
	bpl .l
	lda #<FW
	sta q8fp
	lda #>FW
	sta q8fp + 1
	stz q8r
.r:	jsr q8row
	inc q8r
	lda q8r
	cmp #16
	bne .r
	cla                     ; the ranks
	ldx q8lm
	ldy q8lh
	jsr q8b0
	lda q8nu
	sta $1A00
	lda q8lm                ; the next period's lists
	clc
	adc #8
	sta q8lm
	bcc *+5
	inc q8lh
	rts
; ---------------------------------------------------------------- one row (q8r): the cells' places in the maps, the far row, each cell, the counts, the template row
q8row:	lda q8r
	clc
	adc #$80
	sta q8n0+2
	sta q8n1+2
	sta q8s0+2
	adc #$10
	sta q8m0+2
	sta q8m1+2
	lda q8cn
	sta q8n0+1
	sta q8s0+1
	inc a
	sta q8n1+1
	lda q8cm
	sta q8m0+1
	inc a
	sta q8m1+1
	lda q8r
	lsr a
	tay
	cla
	ror a
	ora q8cm
	sta q8s1+1
	tya
	clc
	adc #$90
	sta q8s1+2
	lda #BANDT
	tam #4
	lda q8fp
	sta .f+1
	clc
	adc #66
	sta q8fp
	lda q8fp + 1
	sta .f+2
	adc #0
	sta q8fp + 1
.f:	tii FW, q8rb, 66
	ldx #3
.s:	cpx #3
	bne .s1
	lda q8r
	cmp #10
	bcc .s2
.s1:	lda q8pl,x
	sta q8cl,x
	lda q8pm,x
	sta q8cmm,x
	lda q8ph,x
	sta q8chh,x
	stz q8c,x
	cla
	jsr q8lw
.s2:	dex
	bpl .s
	stz q8j
.c:	jsr q8yck
	jsr q8cell
	inc q8j
	lda q8j
	cmp #33
	bne .c
	ldx #3
.e:	cpx #3
	bne .e1
	lda q8r
	cmp #10
	bcc .e2
.e1:	lda q8cl,x
	sta $1A02
	lda q8cmm,x
	sta $1A03
	lda q8chh,x
	sta $1A04
	lda q8c,x
	sta $1A00
.e2:	dex
	bpl .e
	lda q8tp                ; the template row
	ldx q8tp + 1
	ldy q8tp + 2
	jsr q8b0
	tia q8rb, $1A00, 66
	lda q8tp
	clc
	adc #66
	sta q8tp
	bcc .x
	inc q8tp + 1
	bne .x
	inc q8tp + 2
.x:	rts

; ---------------------------------------------------------------- a cell (q8j): its template word (q8rb: the far already) and its list entry
q8cell:	ldx q8j
	lda ssb6
	tam #4
q8n0:	lda $8000,x
	and #$7F
	sta q8na
q8n1:	lda $8001,x
	and #$7F
	sta q8nb
q8m0:	lda $9000,x
	sta q8ma
q8m1:	lda $9001,x
	sta q8mb
	lda #T1
	tam #4
q8s0:	lda $8000,x
	sta q8ns
q8s1:	lda $9000,x
	sta q8ms
	lda q8r
	cmp #10
	bcs .m
	stz q8ma
	stz q8mb
.m:	lda #BANDT
	tam #4
	ldy q8na
	lda PROP2,y
	asl a
	cla
	rol a
	eor #1
	sta q8ea
	ldy q8nb
	lda PROP2,y
	asl a
	cla
	rol a
	eor #1
	sta q8eb
	txa
	asl a
	tax
	lda q8rb,x
	sta q8fw
	lda q8rb + 1,x
	sta q8fw + 1
	lda q8ea                ; the template word: the near tile A; else the mid's tile A (h = 0, or a pair), else the far
	beq .u
	lda q8na
	clc
	adc nlo
	sta q8rb,x
	lda nhi
	adc #0
	sta q8rb + 1,x
	bra .cls
.u:	lda q8ma
	beq .cls
	ldy q8h
	beq .mw
	ldy q8mb
	beq .cls
.mw:	clc
	adc mlo
	sta q8rb,x
	lda mhi
	adc #0
	sta q8rb + 1,x
.cls:	lda q8ea                ; a near pair (a slot with phases): nothing under it
	and q8eb
	beq .np
	lda q8ns
	cmp #KMAX
	bcc .pr
.x:	rts
.pr:	stz q8ma
	stz q8mb
	stz q8fw
	stz q8fw + 1
.np:	cla
	ldy q8ma
	bne .p1
	ldy q8mb
	beq .p3
.p2:	lda #2
	bra .p3
.p1:	ldy q8mb
	beq .p2
	lda #1
.p3:	sta q8pc
	cmp #2                  ; a near end with a mid run's end: by the columns each takes at k = 1 .. 3 (near A [0, 8 - 2 k), B the rest; mid A
	bne .p4                 ; [0, 8 - dm), B the rest), three layers show only for A over mid A with h = 0, A over mid B with h = 0, B over
	lda q8ea                ; mid B with h = 1, B over mid A with h = 1. A over B with h = 1 and B over A with h = 0 leave nothing of the
	beq .pb                 ; far: as over a mid pair (PALM; the far out of the key). A over A with h = 1 and B over B with h = 0 hide the
	lda q8mb                ; mid: as over the far alone (PALF; the mid out of the key)
	beq .pa
	lda q8h
	beq .p4
	bra .p5
.pa:	lda q8h
	beq .p4
	stz q8ma
	bra .p6
.pb:	lda q8eb
	beq .p4
	lda q8ma
	beq .pc
	lda q8h
	bne .p4
	bra .p5
.pc:	lda q8h
	bne .p4
	stz q8mb
.p6:	stz q8pc
	bra .p4
.p5:	dec q8pc
.p4:
	lda q8ea
	ora q8eb
	bne .mix
	lda q8pc
	beq .x
.mix:	stz q8k                 ; its key
	stz q8k + 1
	lda q8ea
	beq .kb
	lda q8na
	ora #$80
	sta q8k
.kb:	lda q8eb
	beq .kc
	lda q8nb
	ora #$80
	sta q8k + 1
.kc:	lda q8ma
	sta q8k + 2
	lda q8mb
	sta q8k + 3
	stz q8k + 4
	stz q8k + 5
	stz q8k0
	lda q8pc
	cmp #1
	beq .kh
	lda q8fw
	sta q8k + 4
	lda q8fw + 1
	and #$7F
	sta q8k + 5
	lda q8pc
	beq .kr
.kh:	lda q8h
	beq .kr
	lda q8k + 5
	ora #$80
	sta q8k + 5
	lda q8ea
	bne .kr
	inc q8k0
.kr:	jsr q8rec
	bcs .x2
	lda q8ea                ; a pair of one layer: (2 j, its slot, its k = 1 image's place)
	and q8eb
	beq .k1
	clx
	lda q8ns
	bra .k5
.k1:	lda q8ea
	ora q8eb
	bne .k3
	lda q8pc
	cmp #1
	bne .k3
	ldx #3
	lda q8ms
.k5:	jsr q8ent2
	lda q8e + 8
	sta q8w
	lda q8e + 9
	sta q8w + 1
	jsr q8ia
	phy
	phx
	ldx q8sd
	jsr q8lw
	pla
	jsr q8lw
	pla
	jmp q8lw
.k3:	lda q8j                 ; a mix: not under the frame's border
	cmp #32
	beq .x2
	jsr q8rank
	bcs .x2
	ldx #1
	jsr q8ent3
	lda q8k0
	beq .x2
	ldx #2
	jmp q8ent3
.x2:	rts

; ---------------------------------------------------------------- the record of key q8k: its entry in q8e (the table's, or made with its images);
q8rec:	stz q8hl
	stz q8hh
	clx
.h:	asl q8hl
	rol q8hh
	asl q8hl
	rol q8hh
	lda q8k,x
	clc
	adc q8hl
	sta q8hl
	bcc *+5
	inc q8hh
	inx
	cpx #6
	bne .h
.p:	lda q8hh
	and #$07
	sta q8hh
	jsr q8ha
	jsr cb1
	tai $1A10, q8e, 16
	lda q8e + 6
	beq .new
	ldx #5
.c:	lda q8e,x
	cmp q8k,x
	bne .nx
	dex
	bpl .c
	clc
	rts
.nx:	inc q8hl
	bne .p
	inc q8hh
	bra .p
.new:	lda q8ni + 1
	cmp #$0F
	bcs q8bad
	ldx #5
.k:	lda q8k,x
	sta q8e,x
	dex
	bpl .k
	lda #1
	sta q8e + 6
	lda q8ni
	clc
	adc q8k0
	sta q8e + 8
	lda q8ni + 1
	adc #0
	sta q8e + 9
	stz q8e + 10
	jsr q8comp
	jsr q8ew
	clc
	rts
q8bad:	inc q8err
	sec
	rts
; the entry's rank in this period (q8e + 11; given, its ups written and the entry put back, when it has none); carry set: no rank left
q8rank:	lda q8p
	inc a
	cmp q8e + 10
	beq .have
	sta q8e + 10
	lda q8nu
	cmp #96
	bcs q8bad
	sta q8e + 11
	inc q8nu
	asl a
	clc
	adc q8e + 11
	pha
	lda q8lm
	adc #3
	tax
	ldy q8lh
	pla
	jsr q8b0
	lda q8e + 8
	sta q8w
	lda q8e + 9
	sta q8w + 1
	jsr q8ia
	sta $1A00
	stx $1A00
	sty $1A00
	jsr q8ew
.have:	clc
	rts
; the entry q8e into the table
q8ew:	jsr q8ha
	jsr q8b0
	tia q8e, $1A00, 16
	rts

; recoloured (a step each), then k = 1 .. 3 (from 0 with q8k0). BANDT at MPR4 after.
q8comp:	lda q8pc
	cmp #1
	beq .m
	lda q8fw                ; the far (not under a mid pair)
	ldy q8fw + 1
	clx
	jsr rdtile
	ldy #$FF
	lda q8pc
	beq *+4
	ldy #64
	clx
	jsr q8rc
.m:	lda q8ma
	beq .mb
	ldx #32
	jsr q8rm
.mb:	lda q8mb
	beq .n
	ldx #64
	jsr q8rm
.n:	lda q8ea
	beq .nb
	lda q8na
	ldx #96
	jsr q8rn
.nb:	lda q8eb
	beq .im
	jsr q8bx
	lda q8nb
	jsr q8rn
.im:	lda #SHBANK
	tam #4
	lda #1
	sec
	sbc q8k0
	sta q8kk
.k:	jsr q8yck
	tii q8S, q8ib, 32
	lda q8h
	asl a
	asl a
	clc
	adc q8kk
	sta q8d
	stz q8sd
	lda q8ma
	beq .a1
	ldx #32
	lda q8d
	jsr q8pt
.a1:	inc q8sd
	lda q8mb
	beq .a2
	ldx #64
	lda q8d
	jsr q8pt
.a2:	lda q8kk
	beq .w
	stz q8sd
	lda q8ea
	beq .a3
	ldx #96
	lda q8kk
	asl a
	jsr q8pt
.a3:	lda q8eb
	beq .w
	inc q8sd
	jsr q8bx
	lda q8kk
	asl a
	jsr q8pt
.w:	lda q8ni
	sta q8w
	lda q8ni + 1
	sta q8w + 1
	jsr q8ia
	jsr q8b0
	tia q8ib, $1A00, 32
	inc q8ni
	bne *+5
	inc q8ni + 1
	inc q8kk
	lda q8kk
	cmp #4
	beq *+5
	jmp .k
	lda #BANDT
	tam #4
	rts
; X = the near B's source: 96, or 64 beside a near A (a pair: no mid)
q8bx:	ldx #96
	lda q8ea
	beq *+4
	ldx #64
	rts
q8rn:	phx
	clc
	adc nlo
	pha
	lda nhi
	adc #0
	tay
	pla
	clx
	jsr rdtile
	plx
	ldy #$FF
	lda q8ea
	and q8eb
	bne q8rc
	lda q8pc
	asl a
	asl a
	asl a
	asl a
	tay
	bra q8rc
q8rm:	phx
	clc
	adc mlo
	pha
	lda mhi
	adc #0
	tay
	pla
	clx
	jsr rdtile
	plx
	ldy #$FF
	lda q8pc
	cmp #1
	beq *+4
	ldy #48
; srca -> q8S + X through the colour map q8M + Y (Y $FF: as it is); then the clock
q8rc:	stx q8t + 2
	cpy #$FF
	bne .m
	cly
.c:	lda srca,y
	sta q8S,x
	inx
	iny
	cpy #32
	bne .c
	rts
.m:	sty q8mo
	stz q8rr
.r:	ldx q8rr
	lda srca,x
	sta q8b
	lda srca + 1,x
	sta q8b + 1
	lda srca + 16,x
	sta q8b + 2
	lda srca + 17,x
	sta q8b + 3
	ldy #8
.px:	cla
	asl q8b + 3
	rol a
	asl q8b + 2
	rol a
	asl q8b + 1
	rol a
	asl q8b
	rol a
	ora q8mo
	tax
	lda q8M,x
	lsr a
	rol q8o
	lsr a
	rol q8o + 1
	lsr a
	rol q8o + 2
	lsr a
	rol q8o + 3
	dey
	bne .px
	lda q8rr
	clc
	adc q8t + 2
	tax
	lda q8o
	sta q8S,x
	lda q8o + 1
	sta q8S + 1,x
	lda q8o + 2
	sta q8S + 16,x
	lda q8o + 3
	sta q8S + 17,x
	inc q8rr
	inc q8rr
	lda q8rr
	cmp #16
	bne .r
	jmp q8yck
; ib = (ib & keep) | the source X shifted by A = d (1 .. 7): q8sd 0 the tile's left part (<< d: the cell's columns from the left, the right d
; kept), 1 its right part (>> 8 - d, the left 8 - d kept). SHBANK at MPR4.
q8pt:	sta q8t
	asl a
	clc
	adc #$80
	adc q8sd
	sta .s+2
	txa
	clc
	adc #<q8S
	sta .a+1
	lda #>q8S
	adc #0
	sta .a+2
	ldy q8t
	lda Q8K,y
	ldy q8sd
	beq *+4
	eor #$FF
	sta .k+1
	cly
.y:
.a:	ldx q8S,y
	lda q8ib,y
.k:	and #0
.s:	ora $8000,x
	sta q8ib,y
	iny
	cpy #32
	bne .y
	rts
ov8end:
