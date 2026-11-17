SCENE      = $207C
LOCKB      = $2025      ; bit 4: the room-change lock
WINDOW     = $36D6      ; non-zero while a menu or a scripted scene (the map exit) is up
ROWCNT     = $6CCF
BLINE      = $46BF
BBXR       = $46C0
BSTATE     = $46C2
S0KEY      = $0C
S0CBANK    = $7B        ; the second cold bank (src/modules.json "bank3"): scene0c.inc
S0X_R15    = 0          ; its entries
S0X_SAT    = 3
S0X_IDLE   = 6
S0X_LEAVE  = 9

s0st:	.db 0
s0fb:	.db 0           ; MPR6 at the renderer's row 15 (the field bank: the maps)
s0ld:	.db 0
s0fail:	.db 0
s0ss:	.db 0
s0si:	.db 0
s0sj:	.db 0
s0sk:	.db 0
s0lay:	.db 0
s0nbh:	.db 0           ; near map row 0 (high byte; low 0), mid map row 0
s0mbh:	.db 0
s0bnl:	.db 0
s0bnh:	.db 0
s0bml:	.db 0
s0bmh:	.db 0
s0n:	.db 0           ; this pass (row 15): camera tile, phase, mid frame, buffer's first row (0 / 18), ok (1 patch, 2 phase 0)
s0b:	.db 0
s0a:	.db 0
s0bf:	.db 0
s0ok:	.db 0
s0sw:	.db 0           ; the fine add's operand swapped for this pass
s0pc:	.db 0
s0fr:	.db 0
s0hold:	.db 0           ; the hold ran: its frames
s0hf:	.db 0
s0ng:	.db 0           ; groups made; of them in pool A
s0nga:	.db 0
s0nc:	.db 0           ; cache tiles
s0pal:	.db 0
s0mn:	.dw 0
s0mb:	.dw 0
s0sv:	.db 0           ; pool A saved (the composites may be in it): restore at the exit
s0pl:	.db 0
s0t0:	.db 0           ; FRAMES at arming, at engagement
s0t1:	.db 0
s0nl:	.dw 0           ; counters: late passes, stand-downs, patches, refused swaps (nfm), engagements, exits, refusals, rebuild passes
s0nsd:	.db 0
s0np:	.dw 0
s0nfm:	.dw 0
s0neng:	.db 0
s0nex:	.db 0
s0nref:	.db 0
s0lastf:	.db 0           ; the last refusal's reason (kept)
s0reb:	.db 0
s0wn:	.dw 0           ; water tiles (pool B slots used)
s0wi:	.dw 0           ; a copy's index
s0cl:	.db 0           ; the pool cursor: run pointer, tile in run, the tile
s0ch:	.db 0
s0ck:	.db 0
s0ctl:	.db 0
s0cth:	.db 0
s0v3:	.db 0
s0v4:	.db 0
k1:	.db 0
k2:	.db 0
k3:	.db 0
s0kk:	.db 0
q0:	.db 0
q1:	.db 0
q2:	.db 0
q3:	.db 0
q4:	.db 0
q5:	.db 0
q6:	.db 0
q7:	.db 0
s0cam0:	.dw 0
s0aend:	.db 0
s0late:	.db 0           ; armed with the lock clear (the map entry): the hold at once
s0far:	.db 0
s0hmove:	.db 0           ; holds forced by the camera moving before engagement (the fallback)
s0wrdy:	.db 0
s0wc:	.db 0
s0wun:	.dw 0
s0uw:	.db 0
s0ub:	.db 0
s0vce:	.db 0
s0wpre:	.dw 0
s0lr:	.db 0
s0fall:	.db 0
s0aix:	.db 0
s0aend2:	.db 0
s0j:	.db 0
s0cbn:	.db 0           ; the lintel cells of one n (row, x, group: s0cbr / s0cbx / s0cbg in $76)
s0tst:	.ds 10          ; FRAMES at each setup step's start (tset per step), and at engagement
s0r2:	.db 0           ; (row - 10) * 2, x * 2 of the cell s0put stores (s0enb sets them)
s0x2:	.db 0
s0pwf:	.db 0
s0wl:	.db 0
s0wh:	.db 0
s0anim:	.ds 6           ; rows 10-15: 1 when the row has a block per frame (s0rows)
s0nw:	.db 0           ; water groups
s0pi:	.dw 0
s0pdir:	.db 0
s0cv:	.db 0
s0cff:	.db 0
s0cn:	.db 0
s0sq:	.db 0
s0x0:	.db 0
s0x1:	.db 0
s0mr:	.db 0
s0srl:	.db 0
s0srh:	.db 0
s0rfp:	.db 0
s0rmin:	.ds 10
s0rmax:	.ds 10
s0xe:	.db 0
s0pq2:	.db 0

s0hon:	php
	sei
	stz BSTATE
	lda #S0RCR
	sta BLINE
	lda #<STUB_BANDIRQ
	sta $4AAA
	lda #>STUB_BANDIRQ
	sta $4AAB
	plp
	rts
s0hoff:	php
	sei
	lda #$40
	sta $4AAA
	lda #$4B
	sta $4AAB
	stz BLINE
	stz BBXR
	stz BBXR+1
	lda BSTATE
	beq .x
	stz BSTATE
	st0 #6
	st1 #$D7
	st2 #0
	lda <VDCREG
	sta $0000
.x:	plp
	rts

s0r15h:	lda SCENE
	bne .x
	lda <$55
	cmp #S0KEY
	bne .x
	tma #6
	sta s0fb
	phy
	ldx #S0X_R15
	jsr cold3
	ply
.x:	rts
s0sath:	ldx #S0X_SAT
	bra cold3
; upsave (the idle time), s0st non-zero
s0idleh:	.if S0ARM = 0
	rts
	.endif
	ldx #S0X_IDLE
	bra cold3
; leave (an area load), s0st non-zero
s0lvh:	ldx #S0X_LEAVE
; S0CBANK at MPR6 for the call (the caller's MPR6 back after it), entry X; Y, the carry and the interrupt flag as it leaves them
cold3:	stx .j+1
	tma #6
	pha
	lda #S0CBANK
	tam #6
.j:	jsr $C000
	pla
	tam #6
	rts
