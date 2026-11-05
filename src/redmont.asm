; Redmont street renderer module: one fixed VRAM slot per distinct pair of adjacent scenery tiles, every phase of every pair
; made once at area entry into System Card RAM (no data ships in the patch), the BAT pointing at the slots, and once a frame the
; current phase copied into the slots shown.
;
; The near layer scrolls by hardware (BXR = cam_x & 7); the far layer (BAT rows 0-2) must stay and the mid layer (rows 3-13) move at
; half speed. In BAT space a far cell shows the far pair (x - 1, x) at phase 8 - dn and a mid cell the mid pair (x, x + 1)
; at phase rrel = dm - dn, or (x - 1, x) at rrel + 8 when rrel < 0 (dn = cam_x & 7, dm = (cam_x >> 1) & 7).
;
; Loaded by src/disc_boot.asm (src/modules.json; mapped at $A000 by MPR5). Entry points in the jump table below.
; Build: python3 tools/mkdisc.py

OP_NEARPTR = $6CE6
OP_NEAROFF = $6CE3
OP_NEARLO  = $6CF2
OP_NEARH0  = $6CF7
OP_NEARHI  = $6CF9
OP_MIDPTR  = $6D0B
OP_MIDOFF  = $6D06
OP_MIDMASK = $6D08
OP_MIDLO   = $6D11
OP_MIDHI   = $6D18
OP_FARPTR  = $6D2A
OP_FAROFF  = $6D25
OP_FARLO   = $6D2E
OP_FARHI   = $6D35
OP_MAWRLO  = $6C85
OP_MAWRHI  = $6C87
PROPPTR    = $2059
CAMX       = $2D0C
PASS       = $339F
VDCREG     = $F7
GAMEROW    = $6CD8
SATPAGE    = $2215
FRAMES     = $2241
HUDF       = $46BD
TMODEL     = 0
DARK       = $3224
IDR        = $1402      ; bit 1: the VDC's interrupt masked
IRQMASK    = $F5
SPLITN     = $4B4B
PASSMODE   = $6BC4
SPLITS     = $F3

TBANK      = $69        ; tables, at $6000 (MPR3) while drawing, at $8000 (MPR4) while uploading
PHB        = $6A        ; mid phase p (1-7): bank PHB + p - 1, slot k at k * 32
FBANK      = $71        ; far phases 2, 4, 6: at ((p >> 1) - 1) * $800 + k * 32
SHBANK     = $72        ; shift tables: SHL[p][v] at SHT + p * 512, SHR[p][v] at + 256
P8BANK     = $73        ; mid "phase 8": the pair's second tile, slot k at k * 32 (far: FBANK at 3 * $800 + k * 32), so that a
                        ; camera on a tile boundary draws the same slot words as the three passes after it (one draw a tile)
SHT        = $C000
CBANK      = $7C

POOLN      = 142
STDN       = 4
POOLPG     = $78        ; an allocation ending above page $77 reaches the pool (bank $80's end table: $40B3 + entry; the stub's allocstub has the same number)
RESV       = $FE        ; OWN of a pool tile a text window will write (tlwin): no slot may take it (talloc) until the window's pages are back
C2BANK     = CBANK      ; the press and stand-down code (.bank 2 from c2org) shares the cold bank: one read by the loader, no read of its own
                        ; (the upload family from $C000, this code from the next page on (c2org), its tables at $DD00-$DFFF: zero as read, past the image's end)
MMAX       = 254
FMAX       = 64

; tables (TBANK, offsets from the window base)
MSLOT      = $0000      ; 16 rows x 128 map columns: mid slot of the pair starting there ($FF none)
FSLOT      = $0800      ; 16 rows x 64: far slot of screen column x ($FF none)
MFIRST     = $0C00      ; setup: per A code, the first mid slot with that A ($FF none); per slot, the next; B code
MNEXT      = $0D00
MCB        = $0E00
FFIRST     = $0F00      ; (the same for far slots)
FNEXT      = $1000
FCB        = $1040
MAL        = $1200      ; mid slot: source words A, B; BAT word; VRAM address of its tile; pass listed
MAH        = $1300
MBL        = $1400
MBH        = $1500
MWL        = $1600
MWH        = $1700
MVL        = $1800
MVH        = $1900
MVIS       = $1A00
FAL        = $1B00      ; far slot: the same (64 each)
FAH        = $1B40
FBL        = $1B80
FBH        = $1BC0
FWL        = $1C00
FWH        = $1C40
FVL        = $1C80
FVH        = $1CC0
FVIS       = $1D00
LSTM      = $1D40      ; slots shown by a pass of even parity (mid: up to 250, far: up to 64), odd parity: LSTM1, LSTF1
LSTF      = $1E40
LSTM1     = $1080
LSTF1     = $1180
MSRCL      = $0C00      ; after setup (MFIRST / MNEXT / FFIRST / FNEXT are dead then): per slot the low and high byte of its
MSRCH      = $0D00      ; phase image's address in its bank ($8000 + k * 32; far: + the phase's $800 block)
FSRCL      = MSRCL      ; (the same k * 32 for the far slots)
FSRCH      = MSRCH
NONE       = $1E80      ; 256 x $FF: the slot row of a phase-0 layer (whole tiles)
OWN        = $0E00      ; the pool, once the scans are done (MCB and FFIRST's page are dead from SSGM on): per pool tile its slot ($FF free), and 1 if a far slot
OWNF       = $0F40

vsel	.macro
	lda #\1
	sta <VDCREG
	sta $0000
	.endm

	.bank 0
	.org $A000

	jmp rowent
	jmp satbody
	jmp modinit
	jmp upsave
	jmp idlelate
	jmp lateups
	jmp leave
	jmp allocx

; ---------------------------------------------------------------- state
magic:	.db $5A, $A5
tset0:	.db 0
tset1:	.db 0
nsetup:	.db 0
setok:	.db 0           ; slots and phases made for the maps below
skmid:	.db 0           ; their key: mid map page of row 0, far map row 0, far column offset, tile bases
skfl:	.db 0
skfh:	.db 0
skfo:	.db 0
skml:	.db 0
skmh:	.db 0
skfbl:	.db 0
skfbh:	.db 0
lastpass:	.db $FF
pass:	.db 0
dn:	.db 0
dm:	.db 0
rrel:	.db 0
mph:	.db 0           ; this pass's mid phase (0: whole tiles) and far phase (0: whole tiles)
fph:	.db 0
mlc:	.db 0           ; slots listed this pass
flc:	.db 0
upass:	.db $FF         ; the pass last uploaded
done:	.db $FF
rows:	.db 0           ; rows drawn this pass
ppar:	.db 0           ; this pass's parity; per parity: slots listed, mid and far phase
mlcp:	.ds 2
flcp:	.ds 2
mphp:	.ds 2
fphp:	.ds 2
umph:	.db 0           ; the pass being uploaded: its phases and counts
ufph:	.db 0
uml:	.db 0
ufl:	.db 0
row:	.db 0
save3:	.db 0
save4:	.db 0
save6:	.db 0
t0:	.db 0
t1:	.db 0
t2:	.db 0
t3:	.db 0
kk:	.db 0
mcode:	.db 0
nm:	.db 0           ; slots made
nf:	.db 0
mbase:	.db 0           ; mid map page of row 0
fbl:	.db 0           ; far map row 0
fbh:	.db 0
dirty:	.db 0           ; slot images are in VRAM (cleared on leaving the area)
ss:	.db 0
si:	.db 0
sj:	.db 0
ssb4:	.db 0
ssb6:	.db 0
sfr:	.db 0
pend:	.db 0           ; this pass listed a slot whose image is not in VRAM yet (its cells show their whole tiles)
copy:	.db 0           ; this pass copies the last full draw's words from rowbuf (the same key, its slots uploaded)
rbpar:	.db $FF         ; that draw's parity ($FF: none complete), pass and key
rbpass:	.db 0
rbkey:	.ds 10
sv3:	.db 0
sv4:	.db 0
sv6:	.db 0
hand:	.db 0           ; the pool's clock hand (per pool tile its slot and kind: OWN / OWNF in TBANK)
thud:	.db 0
thf:	.db 0
ufar:	.db 0           ; the pass whose far list satbody's early upload has copied, ufn slots of it (any other value: none)
ufn:	.db 0
umode:	.db 0           ; farlist is running from satbody's wait: its group check is the clock, not the vblank
uvf:	.db 0
nofs:	.db 0           ; this pass's near map offset: the cell loop's X runs from it (x + nofs), the row's stores and tables are based back by it
cxl:	.db 0           ; satbody: the camera, this entry's X and true world X, npc's search
cxh:	.db 0
sxl:	.db 0
sxh:	.db 0
wl:	.db 0
wh:	.db 0
nsy:	.db 0
pfr:	.db 0
lastpf:	.db $FF
fset:	.db 0
lwl:	.db 0
lwh:	.db 0
lpal:	.db 0
spal:	.db 0
sati:	.db 0
skip:	.db 0
lastcam:	.db 0
kok:	.db 0, 0
kcur:	.ds 10
keys:	.ds 20
ufr:	.db 0
ulim:	.db 0
uforce:	.db 0
loff:	.db 0
nbi:	.db 0
nbd:	.db 0
rfor:	.ds 64          ; per sprite entry, the record it used last pass (npc's fast path)
rs:	.ds NPN
rtl:	.ds NPN
rth:	.ds NPN
rl:	.ds NPN
ri:	.ds NPN
rr:	.ds NPN
rp:	.ds NPN
ra:	.ds NPN
srca:	.ds 32
srcb:	.ds 32
pcl:	.ds 2           ; per parity, the camera of its last pass; the parity and camera of the last upload
pch:	.ds 2
upx:	.db $FF
ucl:	.db 0
uch:	.db 0
xp:	.db 0
xs:	.db 0
mvd:	.db 0           ; this pass moved the camera
subp:	.db $FF
sd:	.db 0
mainsp:	.db 0
srow:	.ds 2
sdd:	.db 0           ; this pass has drawn a row
sres:	.db 0           ; this pass is a stand going on from srow: its slots stamped at its start, its lists stay
gap:	.db 0           ; vblanks since the last pass began
fin:	.db 0           ; far slots given their image at the draw this pass (fimg)
bawl:	.db 0           ; this row's first BAT address
bawh:	.db 0
stood:	.db 0
resv:	.db 0
glide:	.db 0

idlelate:
	rts

NPN        = 16
HUDWAIT    = 1
satbody:
	lda stood
	bne idlelate
	lda done
	sta subp
	.if HUDWAIT
	lda FRAMES
	cmp pfr
	bne .go
	bbr6 <SPLITS, .go
	.if TMODEL
	jsr nosplit
	bne .go
	.endif
	cli
.hw:	bbr6 <SPLITS, .hs
	lda IDR
	and #2
	bne .hd
	lda FRAMES
	cmp pfr
	bne .hd
	lda setok               ; (no slots: the wait as it was, to the cycle)
	beq .hw
	jsr upearly
	bra .hw
.hs:	lda setok
	beq .hd
	lda $0C01
	and #$7F
	sta thud
	lda FRAMES
	sta thf
.hd:	sei
.go:
	.endif
	jsr satguard
	stz sati
	lda FRAMES
	cmp pfr
	beq .sa
	inc sati
.sa:	lda CAMX
	sta cxl
	lda CAMX+1
	sta cxh
	ldx #NPN - 1
.mk:	lda rs,x                ; live records: not seen yet this pass
	beq .mn
	lda #1
	sta rs,x
.mn:	dex
	bpl .mk
	lda #$FF
	sta lwh
	ldy #4
.spr:	cli                     ; (an interrupt waiting gets in here: CLI takes effect one instruction late)
	nop
	lda sati
	bne .ion
	sei
.ion:	tya
	asl a
	asl a
	sta t0
	ora #3
	ldx #1
	jsr satadr
	lda $0002
	sta t1
	ora $0003
	bne *+5
	jmp .done
	lda t1
	and #$0F
	sta spal
	tax
	lda glpal,x
	bne *+5
	jmp .next
	lda t0                  ; its X word
	ora #1
	ldx #1
	jsr satadr
	lda $0002
	sta sxl
	lda $0003
	and #$03
	sta sxh
	lda sxl                 ; true world X
	clc
	adc cxl
	sta wl
	lda sxh
	adc cxh
	sta wh
	lda wl
	cmp lwl
	bne .own
	lda wh
	cmp lwh
	bne .own
	lda spal
	cmp lpal
	bne .own
	lda loff
	bra .off
.own:	lda wl
	sta lwl
	lda wh
	sta lwh
	lda spal
	sta lpal
	jsr npc
	sta loff
.off:	beq .next
	sta t2
	lda t0
	ora #1
	clx
	jsr satadr
	lda sxl                 ; X - lag in px, 10 bits
	sec
	sbc t2
	sta $0002
	lda t2
	bmi .neg
	lda sxh
	sbc #0
	bra .hi
.neg:	lda sxh
	sbc #$FF
.hi:	and #$03
	sta $0003
.next:	iny
	cpy #64
	beq .done
	jmp .spr
.done:	ldx #NPN - 1
.fr:	lda rs,x
	cmp #1
	bne .fn
	inc ra,x
	lda ra,x
	cmp #16
	bcc .fw
	stz rs,x
	bra .fn
.fw:	jsr nlag
.fn:	dex
	bpl .fr
satend:	sei
	rts
; the VDC's read (X 1: MARR) or write (X 0: MAWR) address at the sprite table's word A, then VRR / VWR
satadr:	stx <VDCREG
	stx $0000
	sta $0002
	lda SATPAGE
	sta $0003
	vsel 2
	rts

; the record of the NPC at wl / wh (nearest live one within 16 px; a new one otherwise): A = its lag in whole px, Z set
; when 0. Y kept.
npc:	sty nsy
	ldx rfor,y
	cpx #NPN
	bcs .srch
	lda rs,x
	cmp #1
	bne .srch
	lda rp,x
	cmp spal
	bne .srch
	lda wl
	sec
	sbc rtl,x
	sta t3
	lda wh
	sbc rth,x
	beq .fp
	cmp #$FF
	bne .srch
	lda t3
	cmp #$FE
	bcc .srch
	jmp .hit
.fp:	lda t3
	cmp #3
	bcs .srch
	jmp .hit
.srch:	lda #$FF
	sta nbi
	lda #17
	sta nbd
	ldx #NPN - 1
.f:	lda rs,x
	cmp #1
	bne .n
	lda rp,x
	cmp spal
	bne .n
	lda wl
	sec
	sbc rtl,x
	sta t3
	lda wh
	sbc rth,x
	beq .pos
	cmp #$FF
	bne .n
	lda t3                  ; -16..-1: distance
	cmp #$F0
	bcc .n
	eor #$FF
	inc a
	bra .cmp
.pos:	lda t3
.cmp:	cmp nbd
	bcs .n
	sta nbd
	stx nbi
.n:	dex
	bpl .f
	ldx nbi
	cpx #$FF
	bne .hit
	ldx #NPN - 1            ; new: a free record, no lag
.a:	lda rs,x
	beq .new
	dex
	bpl .a
	ldy nsy
	lda #$FF
	sta rfor,y
	cla
	rts
.new:	stz rl,x
	stz ra,x
	lda spal
	sta rp,x
	lda #14
	sta rr,x
	lda #$FF
	sta ri,x
	bra .st
.hit:	lda wl                  ; its move this pass
	sec
	sbc rtl,x
	beq .st
	cmp #8
	beq .hp
	cmp #16
	beq .hp
	cmp #$F8
	beq .hm
	cmp #$F0
	beq .hm
	stz rl,x
	bra .st
.hp:	jsr irate
	lda rl,x
	clc
	adc #$7F
	bvc .sl
	lda #$7F
	bra .sl
.hm:	jsr irate
	lda rl,x
	sec
	sbc #$7F
	bvc .sl
	lda #$81
.sl:	sta rl,x
.st:	lda #2                  ; seen; position; a pass nearer
	sta rs,x
	stz ra,x
	lda wl
	sta rtl,x
	lda wh
	sta rth,x
	lda ri,x
	cmp #$FF
	beq .w
	inc ri,x
.w:	ldy nsy
	txa
	sta rfor,y
	jsr nlag
	cmp #$80                ; whole px (arithmetic shift)
	ror a
	cmp #$80
	ror a
	cmp #$80
	ror a
	cmp #$80
	ror a
	ldy nsy
	ora #0
	rts
; record X's lag a pass nearer 0: A = the lag
nlag:	lda rl,x
	beq .z
	bmi .up
	sec
	sbc rr,x
	bcs .sv
	cla
	bra .sv
.up:	clc
	adc rr,x
	bcc .sv
	cla
.sv:	sta rl,x
.z:	rts
irate:	lda ri,x
	stz ri,x
	sec
	sbc #6
	bcc .fast
	cmp #7
	bcs .keep
	tay
	lda rtab,y
	sta rr,x
.keep:	rts
.fast:	lda #21
	sta rr,x
	rts
rtab:	.db 21, 18, 16, 14, 13, 12, 11   
glpal:	.db 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0

; ---------------------------------------------------------------- init (at the first area load)
OWNBATCLEAN = 1
	.include "modsig.inc"
sigbanks:	.db TBANK, PHB, PHB + 1, PHB + 2, PHB + 3, PHB + 4, PHB + 5, PHB + 6, FBANK, SHBANK, P8BANK, 0

modinit:
	jsr c2load
	jsr sigkarm
	bcs .make
	rts
.make:	tma #6                  ; shift tables: SHL[p][v] = (v << p) & $FF, SHR[p][v] = v >> (8 - p)
	pha
	lda #SHBANK
	tam #6
	ldx #1
.td:	stx t0
	txa
	asl a
	clc
	adc #>SHT
	sta .shl+2
	inc a
	sta .shr+2
	cly
.tv:	tya
	ldx t0
.l1:	asl a
	dex
	bne .l1
.shl:	sta SHT,y
	tya
	pha
	lda #8
	sec
	sbc t0
	tax
	pla
.l2:	lsr a
	dex
	bne .l2
.shr:	sta SHT + 256,y
	iny
	bne .tv
	ldx t0
	inx
	cpx #8
	bne .td
	pla
	tam #6
	stz setok
	stz ss
	lda #$FF
	sta lastpass
	sta upass
	rts

rowent:	stz wgame
	lda <$55
	and #$C0
	bne .g
	jsr rowdraw
	lda wgame
	lsr a
	cly
	rts
.g:	jsr kokclr
	sec
	rts
wgame:	.db 0
kokclr:	stz kok                 ; neither buffer holds a whole draw of its key
	stz kok+1
	rts

SDROWS     = 6          ; rows a stand draws once past the top split
GAPF       = 8          ; vblanks without a pass after which the buffers are checked (skipchk): the screen may have been elsewhere
CPROW      = 12
SHOWN      = $4AE0
rowdraw:
	lda PASS
	bne .nr
	lda rows
	cmp #16
	bne .np
	lda #1
	sta lastpf
	sta lastpass
.np:	lda PASS
.nr:	cmp lastpf
	beq .pf
	sta lastpf
	lda FRAMES
	tax
	sec
	sbc pfr
	sta gap
	stx pfr
	lda stood               ; standing down, or a window holding pool tiles: the allocator says when its pages are back (pollx)
	ora resv
	beq .pf
	jsr pollx
.pf:	lda stood
	bne .gw
	lda OP_MIDMASK
	cmp #$FF
	beq .ok
.gw:	jsr kokclr
	inc wgame
	rts
.ok:	lda OP_MAWRLO           ; screen row: BAT row (MAWR / 64), buffers at 0 and 18
	sta t0
	lda OP_MAWRHI
	asl t0
	rol a
	asl t0
	rol a
	and #63
	cmp #18
	bcc .r
	sbc #18
.r:	sta row
	lda PASS
	cmp lastpass
	bne *+5
	jmp .same
	sta lastpass
	sta pass
	stz pend
	lda rows                ; the last pass not drawn whole: no buffer can be trusted to hold a whole draw
	cmp #16
	beq .whole
	jsr kokclr
.whole:	lda done
	eor pass
	lsr a
	bcs .wp
	lda done
	cmp upass
	beq .wp
	sta upass
	lda #$FF                ; (its slots are not all in VRAM: no copying from that draw)
	sta rbpar
.wp:	lda pass
	stz mlc
	stz flc
	stz rows
	stz fin
	and #1
	sta ppar
	tax
	lda lstm_lo,x           ; this parity's lists
	sta c_lm+1
	sta c_lm1+1
	lda lstm_hi,x
	sta c_lm+2
	sta c_lm1+2
	lda lstf_lo,x
	sta c_lf+1
	sta c_lf1+1
	lda lstf_hi,x
	sta c_lf+2
	sta c_lf1+2
	lda CAMX                ; this pass's phases (the camera does not move during a pass)
	and #7
	sta dn
	lda CAMX
	lsr a
	and #7
	sta dm
	sec
	sbc dn
	sta rrel
	and #7
	bne .m8
	lda #8                  ; (rrel 0: the pair (x - 1, x) at 8, its second tile: the whole tile, and the slot words of the
.m8:	sta mph                 ; passes that follow in rowbuf)
	lda #8
	sec
	sbc dn
	and #$FE
	bne .f0
	lda #8
.f0:	sta fph
	bit glide
	bpl .ng
	jsr glidex
.ng:	ldx ppar
	sta fphp,x
	lda mph
	sta mphp,x
	lda CAMX                ; (doupload: this parity's camera)
	sta pcl,x
	lda CAMX+1
	sta pch,x
	jsr setkey              ; slots made (or being made) for these maps?
	beq .nk
	jsr setbd               ; (setbegin; in the black after a load the hold armed too: save-standdown-fix-2)
	jsr kokclr
.nk:	jsr skipchk
	stz xp
	stz xs
	tsx
	cpx mainsp
	beq .same
	bbr1 <IRQMASK, .same
	lda PASSMODE
	bne .same
	lda mvd                 ; (standing, it draws like any other)
	beq .same
	inc xp                  ; the next pass is this step's, not a stand
	bbs1 <$B1, .same
	inc xs
	lda skip
	bne .xs
	ldx ppar
	stz kok,x
	inc skip
.xs:	stz copy
.same:	lda setok
	beq *+5
	jmp .go
	jmp .gw
.skp:	lda rows                ; this buffer already holds these words (skipchk): its rows stand, its lists stay
	beq .s00
	cmp #CPROW
	bne .s0a
	bra .s0
.s00:	lda xs
	bne .s0
	lda resv
	beq .sw
	lda gap
	cmp #GAPF
	bcs .s0
.sw:	jsr waitset
.s0:	lda copy
	beq .s0a
	lda pass
	eor SHOWN
	lsr a
	bcc .s0a
	lda gap
	ldy rows
	beq .s0g
	tay
	bne .s0a
	bra .s0w
.s0g:	cmp #GAPF               ; (no pass for a while: this pass may start anywhere in the playfield)
	bcc .s0a
.s0w:	jsr waitclr
.s0a:	jsr lateup0
	lda rows
	bne .s1
	jsr skipmark
	tma #3
	pha
	lda #TBANK
	tam #3
	jsr agestamps
	pla
	tam #3
.s1:	lda copy
	beq .s1b
	jsr rowcopy
.s1b:	inc rows
	lda rows
	cmp #16
	bne .s2
	lda copy
	beq .s1c
	ldx ppar                ; the copy made this buffer a whole draw of its key, with the copied draw's lists
	lda #1
	sta kok,x
	stz srow,x
	jsr listcopy
.s1c:	lda xs                  ; (never shown: `done` stays the last pass that can be)
	bne .s2
	lda pass
	sta done
	eor #$80                ; (no early far upload for it yet)
	sta ufar
.s2:	rts
.go:	lda skip
	ora copy
	beq *+5
	jmp .skp
	lda sd
	beq .gd
	ldx ppar                ; each stand of this parity goes on from where the last one stopped and draws at least a row, so any row is drawn again within 16 of its passes (something else wrote the BAT: rows heal)
	lda rows
	cmp srow,x
	bcs *+5
	jmp .skp
	lda sdd
	beq .gd
	lda pend                ; (a whole tile standing in for a slot: must be drawn through)
	bne .gd
	lda FRAMES
	cmp pfr
	bne .tr
	lda SPLITN
	cmp #2
	bcs .tr
	bbr6 <SPLITS, .gd
	lda sdd
	cmp #SDROWS
	bcc .gd
.tr:	lda rows
	sta srow,x
	inc skip
	lda #1                  ; (its lists stay: the same camera lists the same slots, in the same order)
	sta kok,x
	stz sd
	lda rbpar               ; rowbuf still holds its draw, with slots stamped now: the copy stays
	bmi .trs
	lda pass
	sta rbpass
.trs:	lda sres
	bne .tr2
	jsr stampall            ; the rows not drawn show slots too: stamped, or the allocator would take them
.tr2:	jmp .skp
.gd:
	jsr lateup0             ; a pass drawn but not uploaded, and the playfield scanned out: upload it first
	tma #3
	sta save3
	lda OP_NEARPTR
	sta c_nrd+1
	lda OP_NEARPTR+1
	sta c_nrd+2
	lda OP_MIDPTR
	sta c_mrd+1
	sta t1                  ; (map column of screen column 0 + the mid offset: OP_MIDPTR's low byte)
	lda OP_MIDPTR+1
	sta c_mrd+2
	lda OP_FARPTR
	sta c_frd+1
	sta c_frd2+1
	lda OP_FARPTR+1
	sta c_frd+2
	sta c_frd2+2
	lda sdd
	beq .op0
	jmp .opd
.op0:	lda sd                  ; (a stand writes the words they hold: if rowbuf holds this key, it stays good)
	beq .wr
	jsr rbchk
	bra .op1
.wr:	lda #$FF                ; rowbuf and this buffer are being rewritten
	sta rbpar
	ldx ppar
	stz kok,x
.op1:	lda OP_NEAROFF          ; X runs from nofs: the near map read is indexed by X itself
	sta nofs
	sta c_x0+1
	clc
	adc #33
	sta c_end+1
	lda OP_NEARLO
	sta c_nlo+1
	lda OP_NEARH0
	clc
	adc OP_NEARHI
	sta c_nhi+1
	lda PROPPTR
	sta c_prd+1
	lda PROPPTR+1
	sta c_prd+2
	lda OP_MIDOFF
	sec
	sbc nofs
	sta c_mofs+1
	lda OP_MIDLO
	sta c_mlo+1
	sta c_mlo2+1
	lda OP_MIDHI
	clc
	adc #$10
	sta c_mhi+1
	sta c_mhi2+1
	lda OP_FAROFF
	sec
	sbc nofs
	sta c_fofs+1
	sta c_fofs2+1
	lda OP_FARLO
	sta c_flo+1
	sta c_flo2+1
	lda OP_FARHI
	clc
	adc #$20
	sta c_fhi+1
	sta c_fhi2+1
.opd:	ldx row                 ; rowbuf row: the 14 store sites of the cell loop (row * 33 + x)
	lda row33h,x
	sta t2
	lda row33l,x
	sec                     ; - nofs: X carries it
	sbc nofs
	bcs *+5
	dec t2
	sta t3
	clc
	adc #<rbl
	sta rb_n0+1
	sta rb_m0+1
	sta rb_mw0+1
	sta rb_mp0+1
	sta rb_f0+1
	sta rb_fw0+1
	sta rb_fp0+1
	lda t2
	adc #>rbl
	sta rb_n0+2
	sta rb_m0+2
	sta rb_mw0+2
	sta rb_mp0+2
	sta rb_f0+2
	sta rb_fw0+2
	sta rb_fp0+2
	lda t3
	clc
	adc #<rbh
	sta rb_n1+1
	sta rb_m1+1
	sta rb_mw1+1
	sta rb_mp1+1
	sta rb_f1+1
	sta rb_fw1+1
	sta rb_fp1+1
	lda t2
	adc #>rbh
	sta rb_n1+2
	sta rb_m1+2
	sta rb_mw1+2
	sta rb_mp1+2
	sta rb_f1+2
	sta rb_fw1+2
	sta rb_fp1+2
	vsel 0                  ; MAWR = this row (kept for fimg: bank $81 goes off now)
	lda OP_MAWRLO
	sta $0002
	sta bawl
	lda OP_MAWRHI
	sta $0003
	sta bawh
	vsel 2
	lda #TBANK
	tam #3
	lda rows                ; first row of the pass: keep the 8-bit "listed" stamps from wrapping into "this pass"
	bne .aged
	jsr agestamps
.aged:
	; mid slot row: MSLOT + map row * 128 + the map column of index 0 (- 1 when rrel < 0); a phase-0 layer: NONE
	lda mph
	beq .mnone
	lda c_mrd+2             ; map row = the row pointer's page - the map's page of row 0
	sec
	sbc mbase
	lsr a
	sta t2
	cla
	ror a                   ; (row * 128: high = row >> 1, low = (row & 1) << 7)
	clc
	adc t1
	sta t3
	lda t2
	adc #>($6000 + MSLOT)
	sta t2
	lda rrel
	bmi .mn1
	bne .mp
.mn1:	lda t3
	bne .md
	dec t2
.md:	dec t3
.mp:	lda t3
	sta c_mtab+1
	lda t2
	sta c_mtab+2
	bra .ft
.mnone:	lda #<($6000 + NONE)
	sta c_mtab+1
	lda #>($6000 + NONE)
	sta c_mtab+2
.ft:	lda fph                 ; far slot row: FSLOT + screen row * 64
	beq .fnone
	lda row
	stz t2
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t2
	asl a
	rol t2
	sec
	sbc nofs
	bcs *+5
	dec t2
	sta c_ftab+1
	lda t2
	clc
	adc #>($6000 + FSLOT)
	sta c_ftab+2
	bra .cells
.fnone:	lda #<($6000 + NONE)
	sta c_ftab+1
	lda #>($6000 + NONE)
	sta c_ftab+2
.cells:	inc sdd
c_x0:	ldx #0
	jsr cells
	lda save3
	tam #3
	inc rows                ; the pass's last row: it is drawn, its lists are complete
	lda rows
	cmp #16
	bne rowsend
	ldx ppar
	stz srow,x
	lda sres
	bne .nl
	lda mlc
	sta mlcp,x
	lda flc
	sta flcp,x
.nl:	lda pend                ; (a buffer with whole tiles standing in for slots must be redrawn, never skipped)
	beq .kset
	stz kok,x
	bra .np
.kset:	lda #1
	sta kok,x
.np:	lda sres                ; (the end of a round begun in an earlier pass: rowbuf is whole only if it was)
	beq .rw
	lda rbpar
	bmi .rd
	lda pass
	sta rbpass
	bra .rd
.rw:	stx rbpar               ; rowbuf holds this whole draw (slot words even where the buffer got whole tiles)
	lda pass
	sta rbpass
	ldy #9
.rk:	lda kcur,y
	sta rbkey,y
	dey
	bpl .rk
.rd:	lda pass
	sta done
	eor #$80
	sta ufar
rowsend:	rts
skipmark:	rts             ; (the first row of a skipped pass)
skipchk:	stz skip
	ldx #8
.k:	lda opkey_lo,x
	sta .kr+1
	lda opkey_hi,x
	sta .kr+2
.kr:	lda $FFFF
	sta kcur,x
	dex
	bpl .k
	lda rrel                ; (the sign of rrel; 0 counts as negative: the (x - 1, x) pair)
	beq .ng
	and #$80
	bra .sg
.ng:	lda #$80
.sg:	ldy mph
	beq .a
	ora #1
.a:	ldy fph
	beq .b
	ora #2
.b:	sta kcur+9
	stz t3
	cly
	lda ppar
	beq .c
	ldy #10
.c:	clx
.l:	lda kcur,x
	cmp keys,y
	beq .e
	sta keys,y
	inc t3
.e:	iny
	inx
	cpx #10
	bne .l
	stz copy
	stz mvd
	stz sd
	stz sres
	stz sdd
	lda CAMX
	cmp lastcam
	sta lastcam
	bne .mv
	lda xp
	bne .mv1
	lda t3
	bne .cp
	ldx ppar
	lda kok,x
	sta sd
	bne .sg0
	jmp .cp                 ; (this buffer does not hold it: the copy, if rowbuf does)
.sg0:	lda gap
	cmp #GAPF
	bcc .sg1
	jsr batsame
	bcc .sg1
	jsr kokclr
	stz srow
	stz srow+1
	stz sd
	jmp .cp                 ; (rowbuf still holds this key: the quick way back, so the sprites of this pass make the same frame)
.sg1:	ldx ppar
	lda srow,x
	beq .sx
	inc sres
	jmp stampall
.sx:	rts
.mv:	inc mvd
.mv1:	lda t3
	bne .cp
	ldx ppar
	lda kok,x
	sta skip
	bne .x
.cp:	lda rbpar               ; rowbuf holds a complete full draw of this key whose slots have been uploaded (so every slot word in
	bmi .x                  ; it has its image in VRAM): copy it instead of drawing
	lda upass
	sec
	sbc rbpass
	cmp #8
	bcs .x
	jsr rbsame
	bne .x
	lda #1
	sta copy
.x:	rts
opkey_lo:	.db <OP_NEARPTR, <(OP_NEARPTR+1), <OP_NEAROFF, <OP_MIDPTR, <(OP_MIDPTR+1), <OP_MIDOFF, <OP_FARPTR, <(OP_FARPTR+1), <OP_FAROFF
opkey_hi:	.db >OP_NEARPTR, >(OP_NEARPTR+1), >OP_NEAROFF, >OP_MIDPTR, >(OP_MIDPTR+1), >OP_MIDOFF, >OP_FARPTR, >(OP_FARPTR+1), >OP_FAROFF
; carry clear when both buffers still show rowbuf at the sample cells, rowbuf holding this key (a sample, not a proof: stands heal the rest)
batsame:	jsr rbsame
	bne .no
	ldy #3
.w:	php
	sei
	lda #1
	sta <VDCREG
	sta $0000
	lda bs_al,y
	sta $0002
	lda bs_ah,y
	sta $0003
	lda #2
	sta <VDCREG
	sta $0000
	lda $0002
	sta t0
	lda $0003
	plp
	ldx bs_i,y
	cmp rbh + 256,x
	bne .no
	lda t0
	cmp rbl + 256,x
	bne .no
	dey
	bpl .w
	clc
	rts
.no:	sec
	rts
BSC        = 16         ; the cell sampled (the rows start at BAT column 2)
bs_al:	.db <(8 * 64 + 2 + BSC), <(14 * 64 + 2 + BSC), <(26 * 64 + 2 + BSC), <(32 * 64 + 2 + BSC)
bs_ah:	.db >(8 * 64 + 2 + BSC), >(14 * 64 + 2 + BSC), >(26 * 64 + 2 + BSC), >(32 * 64 + 2 + BSC)
bs_i:	.db 8 * 33 + BSC - 256, 14 * 33 + BSC - 256, 8 * 33 + BSC - 256, 14 * 33 + BSC - 256
; rowbuf's key is not this pass's: it stops being a whole draw of anything
rbchk:	lda rbpar
	bmi .x
	jsr rbsame
	beq .x
	lda #$FF
	sta rbpar
.x:	rts
; Z set when rowbuf's key is this pass's
rbsame:	ldx #9
.l:	lda kcur,x
	cmp rbkey,x
	bne .x
	dex
	bpl .l
	inx
.x:	rts
; the slots this parity's whole draw listed: stamped "listed this pass", as drawing every row would
stampall:	tma #3
	pha
	lda #TBANK
	tam #3
	ldx ppar
	lda lstm_lo,x
	sta .m+1
	lda lstm_hi,x
	sta .m+2
	lda lstf_lo,x
	sta .f+1
	lda lstf_hi,x
	sta .f+2
	lda mlcp,x
	sta t0
	lda flcp,x
	sta t1
	lda pass
	clx
	cpx t0
	beq .fs
.ml:
.m:	ldy $6000 + LSTM,x
	sta $6000 + MVIS,y
	inx
	cpx t0
	bne .ml
.fs:	clx
	cpx t1
	beq .out
.fl:
.f:	ldy $6000 + LSTF,x
	sta $6000 + FVIS,y
	inx
	cpx t1
	bne .fl
.out:	pla
	tam #3
	rts
rowcopy:	ldx row
	clc
	lda row33l,x
	adc #<rbl
	sta .l0+1
	lda row33h,x
	adc #>rbl
	sta .l0+2
	lda .l0+1
	adc #1
	sta .l1+1
	lda .l0+2
	adc #0
	sta .l1+2
	lda .l0+1
	adc #2
	sta .l2+1
	lda .l0+2
	adc #0
	sta .l2+2
	lda row33l,x
	adc #<rbh
	sta .h0+1
	lda row33h,x
	adc #>rbh
	sta .h0+2
	lda .h0+1
	adc #1
	sta .h1+1
	lda .h0+2
	adc #0
	sta .h1+2
	lda .h0+1
	adc #2
	sta .h2+1
	lda .h0+2
	adc #0
	sta .h2+2
	vsel 0                  ; MAWR = this row
	lda OP_MAWRLO
	sta $0002
	lda OP_MAWRHI
	sta $0003
	vsel 2
	clx
.cl:
.l0:	lda rbl,x
	sta $0002
.h0:	lda rbh,x
	sta $0003
.l1:	lda rbl + 1,x
	sta $0002
.h1:	lda rbh + 1,x
	sta $0003
.l2:	lda rbl + 2,x
	sta $0002
.h2:	lda rbh + 2,x
	sta $0003
	inx
	inx
	inx
	cpx #33
	bne .cl
	rts
; the copied draw's lists (the other parity's) become this parity's: slots shown and their counts
listcopy:	tma #3
	pha
	lda #TBANK
	tam #3
	lda rbpar
	and #1
	tax
	lda lstm_lo,x
	sta .sm+1
	lda lstm_hi,x
	sta .sm+2
	lda lstf_lo,x
	sta .sf+1
	lda lstf_hi,x
	sta .sf+2
	lda mlcp,x
	sta t0
	lda flcp,x
	sta t1
	ldx ppar
	lda lstm_lo,x
	sta .dm+1
	lda lstm_hi,x
	sta .dm+2
	lda lstf_lo,x
	sta .df+1
	lda lstf_hi,x
	sta .df+2
	lda t0
	sta mlcp,x
	lda t1
	sta flcp,x
	clx
	cpx t0
	beq .fs
.ml:
.sm:	lda $6000 + LSTM,x
.dm:	sta $6000 + LSTM1,x
	inx
	cpx t0
	bne .ml
.fs:	clx
	cpx t1
	beq .out
.fl:
.sf:	lda $6000 + LSTF,x
.df:	sta $6000 + LSTF1,x
	inx
	cpx t1
	bne .fl
.out:	pla
	tam #3
	rts
lstm_lo:	.db <($6000 + LSTM), <($6000 + LSTM1)
lstm_hi:	.db >($6000 + LSTM), >($6000 + LSTM1)
lstf_lo:	.db <($6000 + LSTF), <($6000 + LSTF1)
lstf_hi:	.db >($6000 + LSTF), >($6000 + LSTF1)

; A stamp older than 128 passes is brought to 64 old: mid slots pass and pass + 128 (each every 128 passes, the oldest
; reaches 192), far slot pass & 63 (every 64)
agestamps:	ldy pass
	jsr .m
	tya
	eor #$80
	tay
	jsr .m
	lda pass
	and #63
	tay
	lda pass
	sec
	sbc $6000 + FVIS,y
	bpl .x
	lda pass
	sec
	sbc #64
	sta $6000 + FVIS,y
.x:	rts
.m:	lda pass
	sec
	sbc $6000 + MVIS,y
	bpl .y
	lda pass
	sec
	sbc #64
	sta $6000 + MVIS,y
.y:	rts

; the row's 33 cells: near tile if there is one, else the mid pair's slot (or the mid tile), else the far pair's
; slot (or the far tile); each slot shown is listed once a pass for the upload
cells:
c_loop:
c_nrd:	lda $FFFF,x
	and #$7F
	tay
c_prd:	lda $FFFF,y
	bmi c_mid
	tya
	clc
c_nlo:	adc #0
	sta $0002
rb_n0:	sta rbl,x
c_nhi:	lda #0
	adc #0
	sta $0003
rb_n1:	sta rbh,x
c_next:	inx
c_end:	cpx #33
	bne c_loop
	rts
c_mid:	txa
	clc
c_mofs:	adc #0
	tay
c_mrd:	lda $FFFF,y
	beq c_far
	sta mcode
c_mtab:	lda $FFFF,y
	cmp #$FF
	beq c_mw
	tay
c_m2:	lda $6000 + MWL,y       ; (the low byte only latches: a slot without a tile rewrites it)
	sta $0002
rb_m0:	sta rbl,x
	lda $6000 + MWH,y
	beq c_ma
	sta $0003
rb_m1:	sta rbh,x
	lda $6000 + MVIS,y
	cmp pass
	beq c_next
	lda pass
	sta $6000 + MVIS,y
	tya
	ldy mlc
c_lm:	sta $6000 + LSTM,y
	inc mlc
	jmp c_next
c_ma:	lda $6000 + MVH,y       ; no image yet (tile taken: MVH, image in VRAM: MWH): its image now (mimg) and the slot; past the bound, listed for the upload and the whole tile this pass
	bne c_mi
	jsr mtile
	bcs c_mw
c_mi:	jsr mimg
	bcs c_mpj
	jmp c_m2
c_mpj:	jmp c_mp
c_mw:	lda mcode
	clc
c_mlo:	adc #0
	sta $0002
rb_mw0:	sta rbl,x
c_mhi:	lda #0
	adc #0
	sta $0003
rb_mw1:	sta rbh,x
	jmp c_next
c_far:
c_ftab:	lda $FFFF,x
	cmp #$FF
	beq c_fw
	tay
c_f2:	lda $6000 + FWL,y
	sta $0002
rb_f0:	sta rbl,x
	lda $6000 + FWH,y
	beq c_fa
	sta $0003
rb_f1:	sta rbh,x
	lda $6000 + FVIS,y
	cmp pass
	bne *+5
	jmp c_next
	lda pass
	sta $6000 + FVIS,y
	tya
	ldy flc
c_lf:	sta $6000 + LSTF,y
	inc flc
	jmp c_next
c_fa:	lda $6000 + FVH,y
	bne c_fi
	jsr ftile
	bcs c_fw
c_fi:	jsr fimg
	bcs c_fpj
	jmp c_f2
c_fpj:	jmp c_fp
c_fw:	txa
	clc
c_fofs:	adc #0
	and #$1F
	tay
c_frd:	lda $FFFF,y
	clc
c_flo:	adc #0
	sta $0002
rb_fw0:	sta rbl,x
c_fhi:	lda #0
	adc #0
	sta $0003
rb_fw1:	sta rbh,x
	jmp c_next
FIMAX      = 4
fimg:	lda mvd
	bne .go
	lda fin
	cmp #FIMAX
	bcs .x
	inc fin
.go:
	tma #4
	pha
	lda #FBANK
	tam #4
	lda fph
	lsr a
	dec a
	asl a
	asl a
	asl a
	clc
	adc $6000 + FSRCH,y
	sta ximg0+2
	sta ximg1+2
	lda $6000 + FSRCL,y
	sta ximg0+1
	inc a
	sta ximg1+1
	lda $6000 + FVL,y
	sta t0
	lda $6000 + FVH,y
	sta t1
	jsr ximg
	pla
	tam #4
	lda $6000 + FAH,y
	and #$F0
	ora #$07
	sta $6000 + FWH,y
	clc
.x:	rts
mimg:	lda mvd
	bne .go
	lda fin
	cmp #FIMAX
	bcs .x
	inc fin
.go:
	tma #4
	pha
	lda mph
	cmp #8
	bne .b
	lda #P8BANK + 1 - PHB
.b:	clc
	adc #PHB - 1
	tam #4
	lda $6000 + MSRCH,y
	sta ximg0+2
	sta ximg1+2
	lda $6000 + MSRCL,y
	sta ximg0+1
	inc a
	sta ximg1+1
	lda $6000 + MVL,y
	sta t0
	lda $6000 + MVH,y
	sta t1
	jsr ximg
	pla
	tam #4
	lda $6000 + MAH,y
	and #$F0
	ora #$07
	sta $6000 + MWH,y
	clc
.x:	rts
; 32 bytes from ximg0 (the bank at MPR4) to VRAM t1:t0 by words, interrupts on between them; MAWR back at the cell in hand (X)
ximg:	lda t1
	php
	sei
	st0 #0
	sta $0003
	lda t0
	sta $0002
	st0 #2
	plp
	phx
	clx
ximgc:
ximg0:	lda $8000,x
	sta $0002
ximg1:	lda $8001,x
	sta $0003
	inx
	inx
	cpx #32
	bne ximgc
	plx
	php
	sei
	st0 #0
	txa
	sec
	sbc nofs
	clc
	adc bawl
	sta $0002
	lda bawh
	adc #0
	sta $0003
	st0 #2
	plp
	rts
; (out of line) a mid / far cell whose slot has no image yet
c_mp:	lda #1
	sta pend
	lda $6000 + MVIS,y
	cmp pass
	beq c_mp2
	lda pass
	sta $6000 + MVIS,y
	tya
	ldy mlc
c_lm1:	sta $6000 + LSTM,y
	inc mlc
	tay
c_mp2:	lda $6000 + MWL,y       ; rowbuf: the slot word (a copy of this draw comes after the upload)
rb_mp0:	sta rbl,x
	lda $6000 + MAH,y
	and #$F0
	ora #$07
rb_mp1:	sta rbh,x
	lda mcode               ; the buffer: the whole tile
	clc
c_mlo2:	adc #0
	sta $0002
c_mhi2:	lda #0
	adc #0
	sta $0003
	jmp c_next
c_fp:	lda #1
	sta pend
	lda $6000 + FVIS,y
	cmp pass
	beq c_fp2
	lda pass
	sta $6000 + FVIS,y
	tya
	ldy flc
c_lf1:	sta $6000 + LSTF,y
	inc flc
	tay
c_fp2:	lda $6000 + FWL,y
rb_fp0:	sta rbl,x
	lda $6000 + FAH,y
	and #$F0
	ora #$07
rb_fp1:	sta rbh,x
	txa
	clc
c_fofs2:	adc #0
	and #$1F
	tay
c_frd2:	lda $FFFF,y
	clc
c_flo2:	adc #0
	sta $0002
c_fhi2:	lda #0
	adc #0
	sta $0003
	jmp c_next

; Z set when the slots were made for this row's maps (mid page of row 0, far row 0, far offset, tile bases)
setkey:	lda setok
	ora ss
	beq .no
	jsr curkey
	lda t0
	cmp skmid
	bne .no
	lda t1
	cmp skfl
	bne .no
	lda t2
	cmp skfh
	bne .no
	lda OP_FAROFF
	cmp skfo
	bne .no
	lda #0
	rts
.no:	lda #1
	rts
; t0 = mid page of row 0 (the row pointer's page - row); t1 / t2 = far map row 0 (the row pointer - row * 32)
curkey:	lda OP_MIDPTR+1
	sec
	sbc row
	sta t0
	lda row
	stz t2
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t2
	sta t3
	lda OP_FARPTR
	sec
	sbc t3
	sta t1
	lda OP_FARPTR+1
	sbc t2
	sta t2
	rts

; ---------------------------------------------------------------- setup (once per set of maps)
SSCLR      = 1
SSFILL     = 2
SSMID      = 3
SSFAR      = 4
SSGM       = 5
SSGF       = 6
SSEND      = 7
setbegin:
	lda #$FF                ; (doupload's standing shortcut: no images to rely on after this)
	sta upx
	lda FRAMES              ; (vblanks at its start and end; slots made are nm, nf)
	sta tset0
	jsr curkey
	lda t0
	sta skmid
	sta mbase
	lda t1
	sta skfl
	sta fbl
	lda t2
	sta skfh
	sta fbh
	lda OP_FAROFF
	sta skfo
	sta sf_ofs+1
	lda OP_MIDLO
	sta skml
	sta su_mlo+1
	lda OP_MIDHI
	sta skmh
	clc
	adc #$10
	sta su_mhi+1
	lda OP_FARLO
	sta skfbl
	sta su_flo+1
	lda OP_FARHI
	sta skfbh
	clc
	adc #$20
	sta su_fhi+1
	tma #4
	sta ssb4
	tma #6
	sta ssb6
	stz setok
	lda #SSCLR
	sta ss
	stz si
	stz sj
	rts

ssrun:	tma #3
	sta sv3
	tma #4
	sta sv4
	tma #6
	sta sv6
	lda #TBANK
	tam #3
	lda FRAMES
	sta sfr
.l:	lda ss
	beq .out
	lda FRAMES
	cmp sfr
	bne .out
	jsr sstep
	bra .l
.out:	lda sv3
	tam #3
	lda sv4
	tam #4
	lda sv6
	tam #6
	rts

; one step
sstep:	lda ss
	asl a
	tax
	jmp [ss_jt - 2,x]
ss_jt:	.dw ss_clr, ss_fill, ss_mid, ss_far, ss_gm, ss_gf, ss_end

; zero the pool's tiles if any image is there, 20 at a time
ss_clr:	lda dirty
	beq .nx
	ldy #20
.t:	jsr clrnext
	beq .all
	dey
	bne .t
	lda #1
	rts
.all:	stz dirty
.nx:	stz si
	lda #SSFILL
	sta ss
	lda #1
	rts

; the tables: 2 pages a step (a plain loop; interrupts stay on)
ss_fill:	lda #2
	sta t2
.p:	ldx si
	lda fill_pg,x
	beq .done
	sta .st+2
	cly                     ; (NONE's first page from <NONE on; every other page whole)
	cpx #16
	bne *+4
	ldy #<NONE
	lda #$FF                ; ($FF everywhere but the three flag pages MWH, FWH, MVH: 0)
	cpx #18
	bcc .st
	cla
.st:	sta $6000,y
	iny
	bne .st
	inc si
	dec t2
	bne .p
	lda #1
	rts
.done:	stz nm
	stz nf
	stz si
	lda #SSMID
	sta ss
	lda #1
	rts
; pages to fill (entries 0-17 with $FF, 18-20 with 0; entry 16, NONE's first page, from <NONE on)
fill_pg:	.db >($6000 + $0000), >($6000 + $0100), >($6000 + $0200), >($6000 + $0300), >($6000 + $0400), >($6000 + $0500), >($6000 + $0600), >($6000 + $0700)
	.db >($6000 + $0800), >($6000 + $0900), >($6000 + $0A00), >($6000 + $0B00), >($6000 + MFIRST), >($6000 + FFIRST), >($6000 + MVIS), >($6000 + FVIS)
	.db >($6000 + NONE), >($6000 + NONE) + 1, >($6000 + MWH), >($6000 + FWH), >($6000 + MVH), 0

; mid pairs of map row si: at (mbase + si) * 256, columns 0-127, 40 columns a step (sj)
ss_mid:	lda ssb4
	tam #4
	lda ssb6
	tam #6
	lda mbase
	clc
	adc si
	sta .ma+2
	sta .mb+2
	lda si                  ; slot row: MSLOT + r * 128
	lsr a
	sta t3
	cla
	ror a
	sta .ms+1
	lda t3
	clc
	adc #>($6000 + MSLOT)
	sta .ms+2
	ldy sj
	lda #40
	sta t2
.mc:
.ma:	lda $FF00,y
	beq .mn
	sta kk
.mb:	lda $FF01,y
	beq .mn
	sta t1
	phy
	jsr midslot
	ply
.ms:	sta $FFFF,y
.mn:	iny
	cpy #128
	beq .row
	dec t2
	bne .mc
	sty sj
	lda #1
	rts
.row:	stz sj
	inc si
	lda si
	cmp #16
	bne .c
	stz si
	lda #SSFAR
	sta ss
.c:	lda #1
	rts

; far pairs per screen cell of row si: at fbl / fbh + r * 32, columns (x + off) & 31 and the one before
ss_far:	lda ssb4
	tam #4
	lda ssb6
	tam #6
	lda si
	stz t3
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t3
	clc
	adc fbl
	sta sf_a+1
	sta sf_b+1
	lda t3
	adc fbh
	sta sf_a+2
	sta sf_b+2
	lda si                  ; slot row: FSLOT + r * 64
	stz t3
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t3
	asl a
	rol t3
	sta sf_s+1
	lda t3
	clc
	adc #>($6000 + FSLOT)
	sta sf_s+2
	clx
sf_c:	txa
	clc
sf_ofs:	adc #0
	tay
	dey
	tya
	and #$1F
	tay
sf_a:	lda $FFFF,y
	sta kk
	iny
	tya
	and #$1F
	tay
sf_b:	lda $FFFF,y
	sta t1
	phx
	jsr farslot
	plx
sf_s:	sta $FFFF,x
	inx
	cpx #33
	bne sf_c
	inc si
	lda si
	cmp #16
	bne sf_x
	stz si
	lda #$FF                ; every pool tile free (OWN lies on the scans' pages: not before this)
	ldx #POOLN - 1
.o:	sta $6000 + OWN,x
	dex
	cpx #$FF                ; (more than 128: not BPL)
	bne .o
	stz hand
	lda #SSGM
	sta ss
sf_x:	lda #1
	rts

ss_gm:	lda si
	cmp nm
	bcc .go
	stz si
	stz sj
	lda #SSGF
	sta ss
	rts
.go:	sta kk
	lda #SHBANK
	tam #6
	lda sj
	bne .gp
	ldx kk
	lda $6000 + MAL,x
	ldy $6000 + MAH,x
	ldx #0
	jsr rdtile
	ldx kk
	lda $6000 + MBL,x
	ldy $6000 + MBH,x
	ldx #32
	jsr rdtile
	lda #P8BANK             ; phase 8: the second tile
	tam #4
	jsr dstk
	jsr putb
	inc sj
.gp:	lda sj
	sta t2
	clc
	adc #PHB - 1
	tam #4
	jsr dstk
	jsr genph
	inc sj
	lda sj
	cmp #8
	bne .x
	stz sj
	inc si
.x:	rts

; far slot si, one step a phase (sj): phases 2, 4, 6 in FBANK at ((p >> 1) - 1) * $800 + k * 32
ss_gf:	lda si
	cmp nf
	bcc .go
	lda #SSEND
	sta ss
	rts
.go:	sta kk
	lda #SHBANK
	tam #6
	lda sj
	bne .gfp
	ldx kk
	lda $6000 + FAL,x
	ldy $6000 + FAH,x
	ldx #0
	jsr rdtile
	ldx kk
	lda $6000 + FBL,x
	ldy $6000 + FBH,x
	ldx #32
	jsr rdtile
	lda #FBANK              ; phase 8: the second tile, at 3 * $800
	tam #4
	jsr dstk
	lda gdst+2
	clc
	adc #$18
	sta gdst+2
	jsr putb
	lda #2
	sta sj
.gfp:	lda #FBANK
	tam #4
	lda sj
	sta t2
	jsr dstk
	lda t2
	lsr a
	dec a
	asl a
	asl a
	asl a
	clc
	adc gdst+2
	sta gdst+2
	jsr genph
	inc sj
	inc sj
	lda sj
	cmp #8
	bne .x
	stz sj
	inc si
.x:	rts

; done: the next pass draws with the slots
ss_end:	clx                     ; the upload's source addresses per slot (the setup's link pages are free now)
.sm:	txa
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $6000 + MSRCL,x
	txa
	lsr a
	lsr a
	lsr a
	ora #$80
	sta $6000 + MSRCH,x
	inx
	bne .sm
	lda #$FF
	sta rbpar
	inc nsetup
	lda FRAMES
	sta tset1
	lda #$FF
	sta done
	sta upass
	lda #1
	sta setok
	stz ss
	lda #0
	rts

; the slot of mid pair (kk, t1) (codes), made if new; A = slot or $FF (all taken). X kept free for the caller.
midslot:	ldy kk                  ; the slots whose A is kk: B = t1?
	lda $6000 + MFIRST,y
.ch:	cmp #$FF
	beq .new
	tax
	lda $6000 + MCB,x
	cmp t1
	beq .have
	lda $6000 + MNEXT,x
	bra .ch
.have:	txa
	rts
.new:	lda nm
	cmp #MMAX
	bcc .mk
	lda #$FF
	rts
.mk:	ldy kk
	ldx nm
	inc nm
	lda $6000 + MFIRST,y    ; at the head of kk's chain
	sta $6000 + MNEXT,x
	txa
	sta $6000 + MFIRST,y
	lda t1
	sta $6000 + MCB,x
	lda kk                  ; words: code + base
	clc
su_mlo:	adc #0
	sta $6000 + MAL,x
	lda #0
su_mhi:	adc #0
	sta $6000 + MAH,x
	lda t1
	clc
	adc su_mlo+1
	sta $6000 + MBL,x
	lda #0
	adc su_mhi+1
	sta $6000 + MBH,x
	txa
	rts

; the slot of far pair (kk, t1) (codes), made if new; A = slot or $FF
farslot:	ldy kk
	lda $6000 + FFIRST,y
.ch:	cmp #$FF
	beq .new
	tax
	lda $6000 + FCB,x
	cmp t1
	beq .have
	lda $6000 + FNEXT,x
	bra .ch
.have:	txa
	rts
.new:	lda nf
	cmp #FMAX
	bcc .mk
	lda #$FF
	rts
.mk:	ldy kk
	ldx nf
	inc nf
	lda $6000 + FFIRST,y
	sta $6000 + FNEXT,x
	txa
	sta $6000 + FFIRST,y
	lda t1
	sta $6000 + FCB,x
	lda kk
	clc
su_flo:	adc #0
	sta $6000 + FAL,x
	lda #0
su_fhi:	adc #0
	sta $6000 + FAH,x
	lda t1
	clc
	adc su_flo+1
	sta $6000 + FBL,x
	lda #0
	adc su_fhi+1
	sta $6000 + FBH,x
	txa
	rts

; zero pool tile si (address and data together, interrupts off); Z set when it was the last, si back at 0
clrnext:	lda si
	stz t3
	asl a
	rol t3
	asl a
	rol t3
	asl a
	rol t3
	asl a
	rol t3
	clc
	adc #$20
	sta t1
	lda t3
	adc #$77
	sta t3
	php
	sei
	vsel 0
	lda t1
	sta $0002
	lda t3
	sta $0003
	vsel 2
	ldx #16
.z:	st1 #0
	st2 #0
	dex
	bne .z
	plp
	inc si
	lda si
	cmp #POOLN
	bne .x
	stz si
	cla
.x:	rts

; a VRAM tile for mid slot Y / far slot Y, when a cell first shows it: the next pool tile free or whose slot no pass
; listed in the last 2 (each buffer is redrawn every other pass, so nothing on screen or to come refers to it).
; Y kept; carry set when all are in use (the cell shows its whole tile this pass). Tables at MPR3.
mtile:	phx
	sty kk
	jsr talloc
	bcs .x
	ldy kk
	tya
	sta $6000 + OWN,x
	stz $6000 + OWNF,x
	txa
	clc
	adc #$72
	sta $6000 + MWL,y
	pha
	asl a
	asl a
	asl a
	asl a
	sta $6000 + MVL,y
	pla
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$70
	sta $6000 + MVH,y
	clc
.x:	ldy kk
	plx
	rts
ftile:	phx
	sty kk
	jsr talloc
	bcs .x
	ldy kk
	tya
	sta $6000 + OWN,x
	lda #1
	sta $6000 + OWNF,x
	txa
	clc
	adc #$72
	sta $6000 + FWL,y
	pha
	asl a
	asl a
	asl a
	asl a
	sta $6000 + FVL,y
	pla
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$70
	sta $6000 + FVH,y
	clc
.x:	ldy kk
	plx
	rts
; X = a pool tile free to take (its old slot loses it), carry clear; carry set when none
talloc:	ldx hand
	lda #POOLN
	sta t3
.l:	inx
	cpx #POOLN
	bcc .c
	clx
.c:	ldy $6000 + OWN,x
	cpy #$FF
	beq .take
	cpy #RESV
	beq .n
	lda $6000 + OWNF,x
	bne .f
	lda pass
	sec
	sbc $6000 + MVIS,y
	cmp #9                  ; (a buffer that skipped or copied still shows a slot stamped at the draw before: up to 8 at a 1-px camera)
	bcc .n
	cla
	sta $6000 + MWH,y
	sta $6000 + MVH,y
	bra .take
.f:	lda pass
	sec
	sbc $6000 + FVIS,y
	cmp #9
	bcc .n
	cla
	sta $6000 + FWH,y
	sta $6000 + FVH,y
	bra .take
.n:	dec t3
	bne .l
	sec
	rts
.take:	stx hand
	clc
	rts

leave:	lda #$FF                ; (the same, on leaving the area)
	sta upx
	lda dirty
	beq .x
	stz si
.t:	jsr clrnext
	bne .t
	stz dirty
	jsr forget
.x:	lda ss
	beq .y
	lda #SSCLR
	sta ss
	stz si
.y:	jsr batclean
	jmp sigsave
bseek:	lda #1
	sta <VDCREG
	sta $0000
	lda t0
	sta $0002
	lda t1
	sta $0003
	lda #2                  ; VRR: each high-byte read moves on
	sta <VDCREG
	sta $0000
	rts

; ---------------------------------------------------------------- the glide (rowdraw's phases, after a stand-down)
glidex:	lda gfirst
	beq .g
	stz gfirst
	lda #8
	sec
	sbc fph
	sta gf
	cla
	sec
	sbc rrel
	sta gm
.g:	lda gf
	ora gm
	bne .b
	stz glide               ; (at the module's phases: this pass is the last that uploads for the glide)
	bra .u
.b:	lda fph
	clc
	adc gf
	cmp #9
	bcc *+4
	lda #8
	sta fph
	lda rrel
	clc
	adc gm
	bpl .p
	cmp #$F9
	bcs .s
	lda #$F9
	bra .s
.p:	cmp #8
	bcc .s
	lda #7
.s:	sta rrel
	and #7
	bne *+4
	lda #8
	sta mph
	lda gf
	beq .d1
	dec gf
	dec gf
.d1:	lda gm
	beq .u
	bmi .d3
	dec gm
	bra .u
.d3:	inc gm
.u:	lda #$FF
	sta upx
	lda fph
	rts
gfirst:	.db 0
gf:	.db 0
gm:	.db 0

; second code bank entries (the code is in .bank 2 from c2org below, C2BANK at MPR6 while it runs): A = the entry's low byte
allocx:	lda #<c2_alloc
	bra c2call
batrest:	lda #<c2_batrest
	bra c2call
batclean:	lda #<c2_batclean
	bra c2call
pollx:	lda #<c2_poll
	bra c2call
c2call:	bit c2ok                ; (X, Y and the carry pass through both ways; before c2load, nothing)
	bpl .x
	sta .j+1
	tma #6
	pha
	lda #C2BANK
	tam #6
.j:	jsr c2org             ; (the entries' page: only the low byte changes)
	pla
	tam #6
.x:	rts
c2ok:	.db 0                   ; $80: tinit1 has run since this bank was read (the loader reads C2BANK with it)
; modinit: the second code bank's tables, once per load of this bank (the loader has read C2BANK with it). A kept
c2load:	bit c2ok
	bmi .x
	pha
	lda #$80
	sta c2ok
	lda #<c2_init
	jsr c2call
	pla
.x:	rts
forget:	lda #$FF                ; nothing drawn before this can be trusted: no copy, no skip
	sta upx
	sta rbpar
	sta lastpass
	jsr kokclr
	tma #3                  ; every slot shows its whole tile again until the upload has put its image back
	pha
	lda #TBANK
	tam #3
	clx
.c:	stz $6000 + MWH,x
	inx
	bne .c
	ldx #63
.e:	stz $6000 + FWH,x
	dex
	bpl .e
	pla
	tam #3
vrts:	rts

; srca / srcb + X (0 or 32) = the 32 bytes of the tile of BAT word A (low) / Y (high), read from VRAM
rdtile:	stx t3
	sta t0
	tya
	and #$07
	sta t1
	lda t0
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	sta t0
	php
rdsplit:	bbs6 <SPLITS, rdon
	sei
rdon:	vsel 1
	lda t0
	sta $0002
	lda t1
	sta $0003
	vsel 2
	ldx t3
	ldy #16
.rw:	lda $0002
	sta srca,x
	lda $0003
	sta srca+1,x
	inx
	inx
	dey
	bne .rw
	plp
	rts

dstk:	lda kk
	stz t3
	asl a
	rol t3
	asl a
	rol t3
	asl a
	rol t3
	asl a
	rol t3
	asl a
	rol t3
	sta gdst+1
	lda t3
	clc
	adc #$80
	sta gdst+2
	rts

; srcb to gdst (the phase-8 image)
putb:	lda gdst+1
	sta .pd+1
	lda gdst+2
	sta .pd+2
	ldy #31
.pl:	lda srcb,y
.pd:	sta $8000,y
	dey
	bpl .pl
	rts
; phase t2 of (srca, srcb) to gdst: byte = SHL[p][A] | SHR[p][B]
genph:	lda t2
	asl a
	clc
	adc #>SHT
	sta gph_sl+2
	inc a
	sta gph_sr+2
	ldy #31
gph_l:	ldx srca,y
gph_sl:	lda SHT,x
	ldx srcb,y
gph_sr:	ora SHT + 256,x
gdst:	sta $8000,y
	dey
	bpl gph_l
	rts

upsave:	phy
	tsx
	stx mainsp
	lda <$55
	bpl .r
	lda dirty
	beq .r
	jsr batrest
	jsr leave
.r:
	jsr upload
	ply
	rts
lateups:	phy
	jsr lateup
	ply
rts0:	rts
upload:	lda stood
	bne rts0
	lda ss
	beq uplist
upjmp:	jmp ssrun               ; (ssrund while armed: an area load's modinit, sigkarm)
uplist:	lda setok
	beq rts0
	lda done
	cmp upass
	beq rts0
	jsr waitclr
	jmp cdoup
waitset:	lda FRAMES
	sta t0
	.if TMODEL
	bbs6 <SPLITS, .x
	jsr nosplit
	bne .x
	.endif
.w:	bbs6 <SPLITS, .x
	jsr waitgo
	beq .w
.x:	rts
waitclr:	lda FRAMES
	sta t0
	.if TMODEL
	bbr6 <SPLITS, .x
	jsr nosplit
	bne .x
	.endif
.w:	bbr6 <SPLITS, .x
	jsr waitgo
	beq .w
.x:	rts
	.if TMODEL
nosplit:	lda HUDF
	cmp FRAMES
	beq .x
	inc a
	cmp FRAMES
.x:	rts
	.endif
waitgo:	lda IDR                 ; Z set: still this frame's wait
	and #2
	bne .x
	lda FRAMES
	cmp t0
.x:	rts
lateup:	jsr lateup0
	lda setok
	beq .x
	lda done
	cmp upass
	beq .x
	bbs1 <$B1, .next
	lda #1
	sta uforce
	jsr cdoup
	stz uforce
.x:	rts
.next:	jsr lateup0
	lda done
	cmp upass
	beq .x
	lda IDR
	and #2
	bne .nx
	bbs1 <$B1, .next
.nx:	rts
lateup0:	bbr6 <SPLITS, .clr      ; (in the playfield: note the frame, nothing to do yet)
	lda FRAMES
	sta fset
	rts
.clr:	lda setok
	beq .x
	lda done
	cmp upass
	beq .x
	cmp subp
	bne .x
	lda FRAMES
	cmp fset
	bne .x
	jmp cdoup
.x:	rts
; ---------------------------------------------------------------- the cold bank's entries (hot code calls the upload family only through these)
cdoup:	ldx #0
	bra cold
cupgo:	ldx #2                  ; (upearly)
cold:	tma #6
	pha
	lda #CBANK
	tam #6
	jsr .j
	pla
	tam #6
	rts
.j:	jmp [coldtab,x]
UPLIM      = 10
UPMIDCUT   = 2
UPFORCE    = 8
	.bank 2
	.org $C000
	jmp doupload            ; (the loader's check: a JMP first)
coldtab:	.dw doupload, upgo
ulimit:	dec ulim
	bne .x
	lda FRAMES
	sta ufr
	jsr waitset
	sei
.x:	rts
doupload:
	lda done                ; standing: the other buffer's slots at the same camera and phases are the same list: its images are
	and #1
	tax
	cmp upx
	beq .up
	lda upx                 ; (forgotten, setup or leaving: no images to rely on, even at the same camera)
	bmi .up
	lda pcl,x
	cmp ucl
	bne .up
	lda pch,x
	cmp uch
	bne .up
	lda mphp
	cmp mphp+1
	bne .up
	lda fphp
	cmp fphp+1
	bne .up
	lda mlcp
	cmp mlcp+1
	bne .up
	lda flcp
	cmp flcp+1
	bne .up
	tma #3
	sta save3
	lda #TBANK
	tam #3
	ldx mlcp
	beq .cf
.cm:	dex
	lda $6000 + LSTM,x
	cmp $6000 + LSTM1,x
	bne .ne
	txa
	bne .cm
.cf:	ldx flcp
	beq .eq
.cf1:	dex
	lda $6000 + LSTF,x
	cmp $6000 + LSTF1,x
	bne .ne
	txa
	bne .cf1
.eq:	lda save3
	tam #3
	lda done
	sta upass
	and #1
	sta upx
	rts
.ne:	lda save3
	tam #3
.up:	lda done
	and #1
	sta upx
	tax
	lda FRAMES
	sta uvf
	lda pcl,x
	sta ucl
	lda pch,x
	sta uch
	lda #1
	sta dirty
	lda FRAMES              ; (a pass that ended very late: once the vblank has passed, at most UPLIM more slots, then the top
	sta ufr
	lda #UPLIM
	bbr1 <IRQMASK, .np
	ldx SPLITN
	bne .np
	dec ufr
.np:	ldx uforce
	beq .nf
	dec ufr
	lda #UPFORCE
.nf:	sta ulim
	lda done
	sta upass
	jsr upsel
	php                     ; (ulimit may leave interrupts off)
	lda ufar                ; the far images went in from satbody's wait, all (the mid list only) or the first ufn
	cmp done
	beq .f1
	stz ufn
.f1:	lda ufn
	cmp ufl
	bcs .mid
	jsr farlist
.mid:	lda ulim
	sec
	sbc #UPMIDCUT
	beq .mc0
	bcs .mc1
.mc0:	lda #1
.mc1:	sta ulim
	jsr midlist
.done:
	plp
upend:	lda save3
	tam #3
	lda save4
	tam #4
.out:	rts
; the far list of the pass being uploaded (ufph, ufl, farlf patched; TBANK at MPR3, VWR selected): FBANK at ((phase >> 1) - 1) * $800 (phase 8 at 3 * $800)
farlist:	ldx ufn                 ; from the slot after the ones satbody's early upload copied (0 otherwise)
	lda ufph
	beq farx
	lda #FBANK
	tam #4
	lda ufph
	lsr a
	dec a
	asl a
	asl a
	asl a
	sta t2
farl:	cpx ufl
	beq farx
	txa
	and #3
	bne farlf
	jsr fgroup
farlf:	ldy $6000 + LSTF,x
	lda $6000 + FSRCL,y
	sta fart+1
	lda $6000 + FSRCH,y
	clc
	adc t2
	sta fart+2
	lda $6000 + FVH,y
	beq farn
	php
	sei
	st0 #0
	sta $0003
	lda $6000 + FVL,y
	sta $0002
	st0 #2
fart:	tia $8000, $0002, 32
	plp
	lda $6000 + FWH,y
	bne farn
	lda $6000 + FAH,y
	and #$F0
	ora #$07
	sta $6000 + FWH,y
farn:	inx
	bra farl
farx:	stx ufn
	rts
; the mid list of the pass being uploaded: bank PHB + phase - 1, phase 8 in P8BANK
midlist:	lda umph
	beq midx
	cmp #8
	bne midb
	lda #P8BANK + 1 - PHB
midb:	clc
	adc #PHB - 1
	tam #4
	ldx #0
midl:	cpx uml
	beq midx
	txa
	and #3
	bne midlm
	jsr fgroup
midlm:	ldy $6000 + LSTM,x
	lda $6000 + MSRCL,y
	sta midt+1
	lda $6000 + MSRCH,y
	sta midt+2
	lda $6000 + MVH,y       ; (its tile reclaimed since this list was made)
	beq midn
	php
	sei
	st0 #0                  ; (interrupts off: the shadow, set above, stays 2)
	sta $0003
	lda $6000 + MVL,y
	sta $0002
	st0 #2
midt:	tia $8000, $0002, 32
	plp
	lda $6000 + MWH,y       ; its image is there: cells may show the slot from now on
	bne midn
	lda $6000 + MAH,y
	and #$F0
	ora #$07
	sta $6000 + MWH,y
midn:	inx
	bra midl
midx:	rts
; the lists, phases and banks of pass `done` for farlist and midlist: TBANK at MPR3 (save3, save4 for upend), VWR selected
upsel:	lda done
	and #1
	tax
	lda mphp,x
	sta umph
	lda fphp,x
	sta ufph
	lda mlcp,x
	sta uml
	lda flcp,x
	sta ufl
	lda lstm_lo,x
	sta midlm+1
	lda lstm_hi,x
	sta midlm+2
	lda lstf_lo,x
	sta farlf+1
	lda lstf_hi,x
	sta farlf+2
	tma #3
	sta save3
	tma #4
	sta save4
	lda #TBANK
	tam #3
	vsel 2
	rts
fgroup:	lda umode
	bne earlyck
	lda FRAMES
	cmp uvf
	beq .n
	sta uvf
	jsr tclockf
	bcs .n
	lda FRAMES
	sta thf
	dec thf
	lda $0C01
	and #$7F
	clc
	adc #42
	cmp #116
	bcc .s
	sbc #116
.s:	sta thud
.n:	jsr tclockf
	bcc .c
	cmp #ELIM
	bcc .c
	lda #1
	sta ulim
.c:	lda FRAMES
	cmp ufr
	beq .x
	jmp ulimit
.x:	rts
earlyck:	jsr tclock
	cmp #EHI2
	bcc .x
	stx ufn
	pla                     ; (farlist's jsr: back to upearly with the list stopped)
	pla
.x:	rts
; ================================================================ bank 0 again: satguard and the clock (every loop of satbody's wait)
	.bank 0
satguard:	lda mvd
	beq .x
	jsr tclockf
	bcc .x
	cmp #EGA
	bcc .x
	cmp #EGB + 1
	bcs .x
	cmp #EGH
	bcs .h
	clc
	adc t0
	cmp #EGS
	bcs .x
.h:	lda FRAMES
	sta t0
	cli
.w:	lda IDR
	and #2
	bne .d
	lda FRAMES
	cmp t0
	beq .w
.d:	sei
.x:	rts
; tclock when a frame of the last 4 gave the clock (thf): carry set; else carry clear
tclockf:	lda FRAMES
	sec
	sbc thf
	dec a
	cmp #4
	bcs .n
	sta t1
	jsr tclock
	clc
	adc t1
	sec
	rts
.n:	clc
	rts
tclock:	lda $0C01
	and #$7F
	sta t0
	lda thud
	sec
	sbc t0
	bcs .e
	adc #116
.e:	rts

ELO        = 79
ELIM       = 58
EGA        = 30
EGB        = 40
EGH        = 32
EGS        = 61
EHI2       = 104
upearly:	lda done
	cmp upass
	beq .x
	cmp ufar
	beq .x
	jsr tclockf
	bcc .x
	cmp #ELO
	bcc .x
	cmp #EHI2
	bcs .x
	jmp cupgo               ; the copy: in the cold bank
.x:	rts
; ================================================================ the cold bank again: upearly's copy
	.bank 2
upgo:	lda done
	sta ufar
	stz ufn
	lda #1
	sta umode
	sta dirty
	jsr upsel
	jsr farlist             ; (interrupts stay as they are between slots)
	stz umode
	jmp upend
coldend:
; ================================================================ end of the cold bank's upload part: bank 0 again
	.bank 0

row33l:	.db <(0 * 33), <(1 * 33), <(2 * 33), <(3 * 33), <(4 * 33), <(5 * 33), <(6 * 33), <(7 * 33), <(8 * 33), <(9 * 33), <(10 * 33), <(11 * 33), <(12 * 33), <(13 * 33), <(14 * 33), <(15 * 33)
row33h:	.db >(0 * 33), >(1 * 33), >(2 * 33), >(3 * 33), >(4 * 33), >(5 * 33), >(6 * 33), >(7 * 33), >(8 * 33), >(9 * 33), >(10 * 33), >(11 * 33), >(12 * 33), >(13 * 33), >(14 * 33), >(15 * 33)
; rowbuf: the last full draw's words per row, low bytes then high (16 rows x 33 cells), and a line for the copy
rbl:	.ds 528
rbh:	.ds 528

; ---------------------------------------------------------------- the stand-down's hold (save-standdown-fix-2)
sigkarm:	ldx #<ssrund            ; (A = dgen for sigkeep, kept; X is free in modinit)
	stx upjmp + 1
	ldx #>ssrund
	stx upjmp + 2
	jmp sigkeep
setbd:	lda DARK
	bne .arm
	jmp setbegin
.arm:	lda #<ssrund
	sta upjmp + 1
	lda #>ssrund
	sta upjmp + 2
	jmp setbegin
ssrund:	lda #<ssrun             ; disarmed: one choice per arming
	sta upjmp + 1
	lda #>ssrun
	sta upjmp + 2
	lda DARK
	bne .hold
	jmp ssrun
.hold:	stz rdsplit + 2
	tma #3
	sta sv3
	tma #4
	sta sv4
	tma #6
	sta sv6
	lda #TBANK
	tam #3
.l:	jsr sstep               ; (ss is not 0: upload tested it)
	lda ss
	bne .l
	lda #rdon - rdsplit - 3 ; rdtile as before
	sta rdsplit + 2
	lda sv3
	tam #3
	lda sv4
	tam #4
	lda sv6
	tam #6
	rts


TLRET      = 15         ; tlwin: the window code's return address ($82:$66FD, from its JSR $4039 at $66FA) on the stack, from S
                        ; (allocator 3, allocstub 2 + 1, mcall 2 + 2, c2call 2 + 1: disc_boot.asm and c2call above)
TMAP       = $DD00      ; per pool tile: $FF not the window's; $FE the window's, its slot to move; $FD the window's, nothing to move; else the tile its slot moved to
HITT       = $DF00      ; batmap's table, per BAT word low byte
TDBG       = $DE00      ; the last press, for the tests: reason (0 kept, 1 standing, 2 no setup, 3 not the window code, 4 request, 5 size, 6 no room, 7 rowbuf not both buffers' draw), need, room, window tiles, moved
	.bank 2
	.org (coldend + $FF) & $FF00
c2org:
c2_alloc:	jmp tlwin
c2_batclean:	jmp batclean1
c2_poll:	jmp poll1
c2_batrest:	jmp batrest1
c2_init:	jmp tinit1

tlwin:	lda stood               ; (standing already)
	beq .a
	lda #1
	bra .vd
.a:	lda #2
	ldx setok               ; the slots made and no setup running
	beq .vd
	ldx ss
	bne .vd
	tsx
	lda $2100 + TLRET,x
	cmp #$FC
	bne .v3
	lda $2100 + TLRET + 1,x
	cmp #$66
	bne .v3
	tma #3
	cmp #$82
	bne .v3
	lda $40E3               ; the request
	cmp #$10
	beq .rq
	cmp #$18
	beq .rq
	lda #4
.vd:	jmp .vac
.v3:	lda #3
	bra .vd
.rq:	lda <$40                ; the frame's size is this window's: W = max(([$40] + 1) >> 1, 8), H = max(([$41] + 1) >> 1, 2)
	inc a
	lsr a
	cmp #8
	bcs *+4
	lda #8
	cmp $671D
	bne .v5
	lda <$41
	inc a
	lsr a
	cmp #2
	bcs *+4
	lda #2
	cmp $6725
	bne .v5
	cmp #6                  ; H 5 at most: rows 0-4
	bcs .v5
	cmp #5
	cla
	bcc *+4
	lda #1
	sta h5
	lda $40E3               ; (a $10 request has H 4 at most: the bottom row is never its)
	cmp #$10
	bne *+5
	stz h5
	lda $671D               ; C = max((4W - 3) >> 3, [$40] >> 2), 7 at most
	asl a
	asl a
	sec
	sbc #3
	lsr a
	lsr a
	lsr a
	sta cmax
	lda <$40
	lsr a
	lsr a
	cmp cmax
	bcc *+5
	sta cmax
	lda cmax
	cmp #8
	bcc .sz
.v5:	lda #5
	bra .vd
.sz:	tma #3
	pha
	lda #TBANK
	tam #3
	ldy nw                  ; TMAP: $FF not the window's, HITT 0 (tinit1 at the load): the last window's entries back
	beq .c3
.c2:	ldx wlist - 1,y
	lda #$FF
	sta TMAP,x
	stz HITT + $72,x
	dey
	bne .c2
.c3:	stz need
	stz nw
	lda $40E4               ; the window's tiles: its columns c <= C of the top area (32 each from start * 16), and with H 5 the
	lsr a                   ; first 8 of each bottom unit k whose column is <= C ($100 + 16k on)
	lsr a
	lsr a
	lsr a
	sta twh
	lda $40E4
	asl a
	asl a
	asl a
	asl a
	sta twl
	stz kc
.tc:	lda #32
	jsr wrange
	lda twl                  ; (next column: + 32 tiles)
	clc
	adc #32
	sta twl
	bcc *+5
	inc twh
	lda kc
	inc a
	sta kc
	cmp cmax
	beq .tc
	bcc .tc
	lda h5
	beq .cd
	lda $40E4               ; the bottom units from start * 16 + $100
	lsr a
	lsr a
	lsr a
	lsr a
	inc a
	sta twh
	lda $40E4
	asl a
	asl a
	asl a
	asl a
	sta twl
	stz kc
.bu:	ldx kc
	lda kcol,x
	cmp cmax
	beq .b1
	bcs .b2
.b1:	lda #8
	jsr wrange
.b2:	lda twl
	clc
	adc #16
	sta twl
	bcc *+5
	inc twh
	inc kc
	lda kc
	cmp #8
	bne .bu
.cd:	lda need
	sta TDBG + 1
	lda nw
	sta TDBG + 3
	stz TDBG + 4
	stz room
	ldx #POOLN - 1
.rm:	lda room
	cmp need
	bcs .mv
	lda TMAP,x
	cmp #$FF
	bne .rn0
	ldy $6000 + OWN,x
	cpy #RESV               ; (another window's)
	beq .rn0
	jsr recent
	bcs .rn0
	txa
	ldy room
	sta cand,y
	inc room
.rn0:	dex
	cpx #$FF
	bne .rm
	lda room
	sta TDBG + 2
	lda #6
	jmp .vt
.mv:	lda room
	sta TDBG + 2
	lda need
	beq .mv0
	jsr okmask
	lda okm
	cmp #3
	beq .mv0
	lda #7                  ; (rowbuf does not hold both buffers' draw: as before)
	jmp .vt
.mv0:
	stz kc                  ; move each window tile's slot to the next candidate
	stz kw
.ml:	ldy kw
	ldx wlist,y
	lda TMAP,x
	cmp #$FE
	bne .mn
	ldy kc
	lda cand,y
	tay
	inc kc
	jsr move1
	inc TDBG + 4
.mn:	inc kw
	lda kw
	cmp nw
	bcc .ml
	lda need                ; (no slot to move: no word to change)
	beq .ok
	jsr hitt                ; the BAT's words naming the moved tiles: where rowbuf names them (RAM; both buffers hold its draw,
	jsr rbpath              ; okmask), both buffers now (the first pass after the window must not pay for the other: its sprites come late)
	bra .ok
.vt:	tax
	pla
	tam #3
	txa
	bra .vac
.ok:	jsr resvw               ; the window's tiles out of talloc's reach
	pla
	tam #3
	lda nw
	beq .k
	lda #STDN
	sta resv
.k:	stz TDBG
	rts
.vac:	sta TDBG
	cmp #2
	bcc .v1
	cmp #4
	lda #0
	bcc .v0
	lda #$80
.v0:	sta gwin
.v1:	jmp vacate1
; the window's tiles out of reach (a slot left on one loses it, as talloc would take it). TBANK at MPR3
resvw:	ldy nw
	beq .rz
.rl:	ldx wlist - 1,y
	phy
	lda TMAP,x
	cmp #$FD                ; (moved: its slot lives on the new tile)
	bne .rr
	ldy $6000 + OWN,x
	cpy #$FF
	beq .rr
	cpy #RESV
	beq .rr
	jsr unown
.rr:	lda #RESV
	sta $6000 + OWN,x
	ply
	dey
	bne .rl
.rz:	rts

; A = n tiles from tile twh:twl: those in the pool are the window's (TMAP $FE: a slot that may be on screen holds it, to move; $FD: not)
wrange:	sta t3
	lda twl                  ; x = tile - $772
	sec
	sbc #$72
	tax
	lda twh
	sbc #7
	beq .in
	cmp #$FF
	bne .x                  ; (beyond the pool, or far below)
	cpx #0                  ; below the pool by 256 - X: skip that many (X 0: 256, more than a range)
	beq .x
	txa
	eor #$FF
	inc a
	cmp t3
	bcs .x
	eor #$FF                ; n - skipped
	sec
	adc t3
	sta t3
	clx
.in:	cpx #POOLN
	bcs .x
	txa
	ldy nw
	sta wlist,y
	inc nw
	ldy $6000 + OWN,x
	jsr recent
	lda #$FD
	bcc .s
	inc need
	lda #$FE
.s:	sta TMAP,x
	inx
	dec t3
	bne .in
.x:	rts
kcol:	.db 0, 4, 1, 5, 2, 6, 3, 7

; Y = OWN of pool tile X: carry set if a slot holds it that a pass listed in the last 8 (talloc's test: it may be on screen)
recent:	cpy #$FF
	beq .n
	cpy #RESV
	beq .n
	lda $6000 + OWNF,x
	bne .f
	lda pass
	sec
	sbc $6000 + MVIS,y
	bra .t
.f:	lda pass
	sec
	sbc $6000 + FVIS,y
.t:	cmp #9
	bcs .n
	sec
	rts
.n:	clc
	rts
; the slot Y of pool tile X loses it (as talloc)
unown:	lda $6000 + OWNF,x
	bne .f
	cla
	sta $6000 + MWH,y
	sta $6000 + MVH,y
	rts
.f:	cla
	sta $6000 + FWH,y
	sta $6000 + FVH,y
	rts

; pool tile X's slot to pool tile Y (free or not shown, outside the window); the image copied in VRAM. X kept
move1:	phx
	phy                     ; (the free tile's old slot, if any, loses it)
	tya
	tax
	ldy $6000 + OWN,x
	cpy #$FF
	beq .f0
	jsr unown
.f0:	ply
	plx
	phx
	tya
	sta TMAP,x              ; (the map: X's words become Y's)
	lda $6000 + OWN,x       ; the slot and its kind to Y
	sta $6000 + OWN,y
	lda $6000 + OWNF,x
	sta $6000 + OWNF,y
	sty t2
	txa
	jsr tadr
	php
	bbs6 <SPLITS, .on
	sei
.on:	vsel 1
	lda t0
	sta $0002
	lda t1
	sta $0003
	vsel 2
	tai $0002, srca, 32
	lda t2
	jsr tadr
	vsel 0
	lda t0
	sta $0002
	lda t1
	sta $0003
	vsel 2
	tia srca, $0002, 32
	plp
	plx
	phx
	ldy $6000 + OWN,x       ; the slot's words: its tile now t2
	lda t2
	clc
	adc #$72
	sta t0                  ; (BAT low byte, and VRAM address (low 4 bits shifted): as mtile)
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
	ora #$70
	sta t3
	lda $6000 + OWNF,x
	bne .ff
	lda t0
	sta $6000 + MWL,y
	lda t1
	sta $6000 + MVL,y
	lda $6000 + MVH,y       ; (no tile: none to give; it keeps none)
	beq .x
	lda t3
	sta $6000 + MVH,y
	bra .x
.ff:	lda t0
	sta $6000 + FWL,y
	lda t1
	sta $6000 + FVL,y
	lda $6000 + FVH,y
	beq .x
	lda t3
	sta $6000 + FVH,y
.x:	plx
	rts

; A = a pool tile: t1:t0 = its VRAM address (($772 + A) * 16)
tadr:	clc
	adc #$72
	sta t0
	lda #$07
	sta t1
	asl t0
	rol t1
	asl t0
	rol t1
	asl t0
	rol t1
	asl t0
	rol t1
	rts
; okm: bit 0 / 1 when buffer 0 / 1 holds the draw rowbuf holds (rowbuf valid, a whole draw of its key, the same key)
okmask:	stz okm
	lda rbpar
	bmi .x
	lda kok
	beq .b1
	cly
	jsr keq
	bne .b1
	lda #1
	tsb okm
.b1:	lda kok+1
	beq .x
	ldy #10
	jsr keq
	bne .x
	lda #2
	tsb okm
.x:	rts
keq:	clx
.l:	lda keys,y
	cmp rbkey,x
	bne .r
	iny
	inx
	cpx #10
	bne .l
.r:	rts
; rowbuf's words naming a moved tile, written renamed to both buffers at the same row and column (no BAT read), and
; rowbuf itself renamed. (Both buffers hold rowbuf's draw: okmask)
rbpath:	stz brow
.r:	ldx brow
	clc
	lda row33l,x
	adc #<rbl
	sta .l+1
	sta .s+1
	lda row33h,x
	adc #>rbl
	sta .l+2
	sta .s+2
	lda row33l,x
	adc #<rbh
	sta .h+1
	lda row33h,x
	adc #>rbh
	sta .h+2
	txa                     ; the row's first word (column 2) in each buffer: rows brow and brow + 18
	stz b0l
	lsr a
	ror b0l
	lsr a
	ror b0l
	sta b0h
	txa
	clc
	adc #18
	stz b1l
	lsr a
	ror b1l
	lsr a
	ror b1l
	sta b1h
	lda #2
	tsb b0l
	tsb b1l
	ldy #32
.c:
.l:	ldx rbl,y
	lda HITT,x
	bne .hit
.cn:	dey
	bpl .c
	inc brow
	lda brow
	cmp #16
	bne .r
	rts
.hit:
.h:	lda rbh,y
	sta bhi
	and #7
	cmp #7
	bne .cn
	lda TMAP - $72,x
	clc
	adc #$72
.s:	sta rbl,y
	tax
	php
	bbs6 <SPLITS, .on
	sei
.on:	vsel 0
	tya
	clc
	adc b0l
	sta $0002
	lda b0h
	sta $0003
	vsel 2
	stx $0002
	lda bhi
	sta $0003
	vsel 0
	tya
	clc
	adc b1l
	sta $0002
	lda b1h
	sta $0003
	vsel 2
	stx $0002
	lda bhi
	sta $0003
	plp
	bra .cn
b0l:	.db 0
b0h:	.db 0
b1l:	.db 0
b1h:	.db 0
okm:	.db 0
bnew:	.db 0
; the bank just loaded: TMAP all $FF, HITT 0 (all of it: batmap reads it for any word's low byte), no window listed
tinit1:	ldx #0
.h0:	stz HITT,x
	inx
	bne .h0
	lda #$FF
	ldx #POOLN - 1
.c0:	sta TMAP,x
	dex
	cpx #$FF
	bne .c0
	stz nw
	rts
; HITT[low byte of a BAT word] = 1: a moved tile (its word changes). (A word naming a window tile whose slot did not move
; would be a slot no pass listed in the last 8, which talloc assumes no buffer shows: assumed here too, checked by the tests)
hitt:	ldy nw                  ; (the window's tiles; the rest of HITT is 0)
	beq .x
.l:	ldx wlist - 1,y
	lda TMAP,x
	cmp #$FD
	bcs .n
	lda #1
	sta HITT + $72,x
.n:	dey
	bne .l
.x:	rts
bm_r0:	.db 0, 18
brow:	.db 0
bmh:	.db 0
bhi:	.db 0
bma:	.db 0

h5:	.db 0
cmax:	.db 0
sl:	.db 0
sh:	.db 0
need:	.db 0
room:	.db 0
nw:	.db 0
twl:	.db 0
twh:	.db 0
kc:	.db 0
kw:	.db 0
cand:	.ds 64
wlist:	.ds 64

; ---------------------------------------------------------------- the allocator's pages back (rowdraw, a new pass, while standing or a window holds tiles)
; The allocator's last entry (sorted, zero after it) says when; the pages come back a little before the window's sprites
; go: STDN passes more before a slot may show again (stood) or take a window tile (resv)
poll1:	ldx #47
.st:	lda $40B3,x
	bne .sf
	dex
	bpl .st
.sf:	cmp #POOLPG
	bcc .bk
	lda #STDN
	ldx stood
	beq .r1
	sta stood
.r1:	ldx resv
	beq .x
	sta resv
.x:	rts
.bk:	lda resv
	beq .sd
	dec resv
	bne .sd
	jsr unres
.sd:	lda stood
	beq .x
	dec stood
	bne .x
	lda gwin
	sta glide
	sta gfirst
	rts
gwin:	.db 0
; the window's tiles free again
unres:	tma #3
	pha
	lda #TBANK
	tam #3
	ldx #POOLN - 1
	lda #$FF
.l:	ldy $6000 + OWN,x
	cpy #RESV
	bne .n
	sta $6000 + OWN,x
.n:	dex
	cpx #$FF
	bne .l
	pla
	tam #3
	rts


; ---------------------------------------------------------------- the stand-down (moved here from bank 0)
vacate1:	lda stood
	bne .x
	lda #STDN
	sta stood
	stz rows                ; (no pass is drawn while standing: rowdraw's "pass 0 after a whole pass 0" must not see the last one's 16 on every row and count each row a pass)
	lda done                ; (an upload still due would write into the window)
	sta upass
	lda dirty
	beq .x
	bbs1 <$B1, .both        ; (a request waiting: the next vblank shows the other buffer)
	lda SHOWN
	lsr a
	bcs .odd
	lda #2
	sta t0
	cla
	ldx #4
	bra .scan
.odd:	lda #$82
	sta t0
	lda #4
	ldx #>(64 * 36)
.scan:	jsr batrs
	jmp forget
.both:	jsr batrest1
	jmp forget
.x:	rts

;; leaving: batrest's loop with word 0 for every word naming a pool tile
batclean1:	inc bz            ; (and no window holds tiles any more, no glide)
	jsr batrest1
	stz bz
	stz glide
	lda resv
	beq .x
	stz resv
	jmp unres
.x:	rts
bz:	.db 0
batrest1:	lda #2
	sta t0
	cla
	ldx #>(64 * 36)
batrs:	sta t1                  ; (t1:t0 from A and t0: the first word, at column 2; X: the high byte the rows end at. Columns 2-34 are the only ones the cell loop writes)
	stx .lim+1
	tma #3
	sta save3
	lda #TBANK
	tam #3
	jsr bseek
.w:	ldx $0002
	lda $0003
	and #7
	cmp #7
	bne .nx
	cpx #$72
	bcc .nx
	stz <VDCREG             ; MAWR = this word
	stz $0000
	lda t0
	sta $0002
	lda t1
	sta $0003
	lda #2
	sta <VDCREG
	sta $0000
	txa
	sec
	sbc #$72
	tax
	ldy bz
	bne .z
	ldy $6000 + OWN,x
	cpy #RESV
	beq .z
	cpy #$FF
	bne .s
.z:	st1 #0                  ; (no owner: as leave would)
	st2 #0
	bra .nw
.s:	lda $6000 + OWNF,x
	beq .m
	lda $6000 + FBL,y
	sta $0002
	lda $6000 + FBH,y
	sta $0003
	bra .nw
.m:	lda rrel
	bmi .b
	beq .b
	lda $6000 + MAL,y
	sta $0002
	lda $6000 + MAH,y
	sta $0003
	bra .nw
.b:	lda $6000 + MBL,y
	sta $0002
	lda $6000 + MBH,y
	sta $0003
.nw:	inc t0
	jsr bseek               ; (MARR = the next word)
	bra .ny
.nx:	inc t0
.ny:	lda t0
	and #63
	cmp #35
	beq *+5
	jmp .w
	lda t0                  ; the next row's column 2
	clc
	adc #31
	sta t0
	bcc .nc
	inc t1
.nc:	lda t1
.lim:	cmp #0
	beq .e
	jsr bseek
	jmp .w
.e:	lda save3
	tam #3
	rts
c2end:
	.if (c2end > TMAP)
	.fail
	.endif
