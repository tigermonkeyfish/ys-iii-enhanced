
FRAMES     = $2241
SCENE      = $207C
LOCKB      = $2025      ; bit 3: the DARK span (the room-change routine sets bits 3 and 4)
DARKF      = $3224
WINDOW     = $36D6
HP         = $2D18
ROWCNT     = $6CCF
ROWN       = $6CD1
ROWGAME    = $5FFF
VDCREG     = $F7
NSAT       = $2216      ; entries the object draw wrote this table (after its last)
SATPAGE    = $2215
ALLOCEND   = $40B3
OP_MAWRL   = $6C85      ; the row's MAWR (ST1 / ST2 operands): row 0's = the hidden buffer
OP_MAWRH   = $6C87
OP_STRL    = $6C95      ; the near map's row stride
OP_STRH    = $6C9E
OP_NOFF    = $6CE3
OP_NPTRL   = $6CE6      ; the near map pointer (row 0's at row 0)
OP_NPTRH   = $6CE7
OP_NLO     = $6CF2      ; near word: code + lo, high byte $6CF7 + $6CF9
OP_NH1     = $6CF7
OP_NH2     = $6CF9
OP_MIDOFF  = $6D06
OP_MIDMASK = $6D08
OP_MPTRL   = $6D0B
OP_MPTRH   = $6D0C
OP_MIDLO   = $6D11      ; backdrop word: v + lo, high byte $10 + hi + carry
OP_MIDHI   = $6D18
MIDA       = $6D03      ; the mid path's code bytes we change: $6D03-$6D05, $6D09-$6D0A
MIDB       = $6D09
PAL1       = $3C20      ; the System Card's colour buffer: BG palette 1
PAL4       = $3E80
ROOM       = 19
MODE       = $0D
GAPN       = 8
SMAIN      = $F7
SLOAD      = SMAIN - 4  ; ... on the pass the room-change thread draws at its own top level (the scheduler's call and its call of the thread are below it):
                        ; the loaded room's first picture, once per room load (door, Load, Continue, a death's Continue), in the DARK span, with the
                        ; scene and the mode already the loaded room's. Never a play pass; the Load menu's pass as it closes is deeper ($EF)
GROW       = $6CD8
GWAIT      = $4B6D
GSATR      = $E09F
OBSSITE    = $5646
STPSITE    = $7238
SFSITE     = $4C5A
STPBANK    = $85        ; five bytes); written through MPR4 (+ $2000) while engaged (room19-s-kernel-gates: the palette race)
GAMEBANK   = $81        ; the renderer's bank (row_draw, the mid path), mapped at MPR4 while the module writes it outside the rows
CARDMOD    = 0
ORD        = 1
U2L        = 1
UPF        = 1
UFM        = 1
PLUG       = 1
PDD        = 1
PDN        = 0
OCK        = 1          ; (PLUG, PDD) 1 = off the grid the leave-out order of each band by UPLOAD COST (the class's phases at which a code-0 cell of
                        ; the block's footprint is not a dictionary word, summed), per camera cell in the cum pages (made in the dark); 0 = O's
PBM        = 1
WAL        = 1
C5SAT      = $028000
C5CAR      = 0          ; 0 = let TMODEL handle 1-vblank overruns; 1 = multi-frame carry pause
	.if CARDMOD
BANK5      = ORD | U2L  ; the fifth image bank (pceas .bank 5 at $8000, shaft19_x7.inc): CB5 = DB_N after the set-up's kbuild
	.else
BANK5      = 0
	.endif
PLG        = PLUG & BANK5 ; (the plug engages only on the card class with the fifth bank)
PBX        = PBM & PLG  ; (r19-plug-bitmap in this build)
HUDX       = 1
HUDS       = HUDX & PLG
DB_SW      = $69        ; data: the screen's backdrop words (16 x 32 words at $8000)
	.if CARDMOD
DB_CLS     = $6C        ; data: the near window's backdrop class, eight bit shifts x 1 KB ($6A is outside M; $6C was a4's DB_TILE, named by no code)
CMB0       = $73        ; the main bank (the arm copies it from the card, STUB_CURMOD while in charge)
CB         = $74        ; the cold bank (MPR6 while it runs)
CB3        = $75        ; the second cold bank (the engaged pass, room19-s-pass-kernel)
CB4        = $76        ; the third cold bank (room19-s-fold-build)
ARMBANK    = $7E        ; the bank in charge before the arm's call and after the hand-back (the mine's; the stand-in arm19.asm on this build)
CMN        = 4 + BANK5 + PLG ; the image's banks (main, CB, CB3, CB4, CB5: card CMADDR:0000 + $2000 n)
CB6        = $69        ; (PLG) the sixth image bank: DB_SW's bank (its code at $C600-$DFFF; the set-up makes the first 1.5 KB again)
CB5        = $6E        ; (BANK5) the fifth image bank: DB_N's bank (kbuild's nibble map only while it rebuilds; copied again after)
CMADDR     = $00        ; the image's card address, byte 2 (src/modules.json card.addr; mkdisc checks)
	.else
DB_CLS     = $6A        ; data: the near window's backdrop class, eight bit shifts x 1 KB
DB_TILE    = $6C        ; data: set-up's tile staging
CB         = $7F        ; the cold bank (MPR6 while it runs)
CB3        = $7C        ; the second cold bank (the engaged pass, room19-s-pass-kernel)
CB4        = $7B        ; the third cold bank (room19-s-fold-build: room for the scenery fold; src/modules.json bank4 / sector4)
	.endif
DB_NEAR    = $6B        ; data: the near map window's copy (8 KB)
DB_K       = $6D        ; data: the pass's unit tables, the pseudo-groups' SAT entries, the masks' entries
DB_N       = $6E        ; data: set-up's nibble map (the class of 2 x 2 near cells at every map position)
DB_C0      = $6F        ; data: own rows' row code (room19-s-own-rows): S's word of near byte $C000 + k as ST1 #lo / ST2 #hi at
DB_C1      = $70        ; 4 (k & 2047) of bank DB_C0 + (k >> 11); a world row (64 words) is one 256-byte page, so the code of a
DB_C2      = $71        ; window row runs straight on into the next world row, as the row routine reads the map (k 0-4351 built)
	.if CARDMOD
DB_T       = DB_SW      ; data: set-up's word of each byte value (lo DBT_O, hi DBT_O + $100): (shaft19-join-020) in DB_SW past its 1 KB,
DBT_O      = $8400      ; so that DB_X has a bank of M ($72) and code + data stay 13 banks
	.else
DB_T       = $72        ; data: set-up's word of each byte value (lo $8000, hi $8100)
DBT_O      = $8000
	.endif
ENGAGE     = 1
WINDARK    = 1          ; room19-stack-arm: 1 = the window flag ($36D6) does not stand an engaged pass down before the room was lit after the set-up (lit 0): a Load through the pause menu leaves the flag set until the reload's first lit pass; 0 = every Load into 19 sets up and stands down at once
REPHASE    = 0
FOLDW      = 1          ; room19-s-fold-build, the fold's part 1 (0 = build p1; 1 with FOLD): 1 = the S word of a staircase cell (backdrop class, not the hole's code 0) is the map's tile word (the near path's word), not the transparent word; every overlay still drawn
FOLDU      = 0          ; room19-s-fold-build, a measuring experiment only (0 = build p1; the picture is NOT valid with 1): the units of every 16 x 16 palette-14 entry (the overlays) are not counted by kent, as if each were folded; the entries are still drawn. What the pad's log then says is the most the fold can buy
STEPPAD    = 0          ; room19-s-fold, experiment (build n; 0 = build l): 1 = the colour-cycle hook's cycles (KSTEP) come off the pad of the pass they ran in
FOLD       = 1          ; room19-s-fold-parts: 1 = the scenery fold in the pass (FOLDW must be 1, FOLDU 0); 0 with FOLDW 0 rebuilds build q's track bit for bit. See "the scenery fold" before kent
FOLDP      = 0
TMCHK      = 0
FOLDF      = 0
FOLDS      = 1
PADON      = 0          ; room19-path-3: 1 = the measured pad before the sprite request; 0 = the spans are measured and logged, no pad
PADK       = 35863
TIMER      = $0C00
IRQMASK    = $1402
SPLITN     = $4B4B
KSTEP      = 408
K24        = 309
K152       = 267
OBSERVE    = 1
NSLOT      = 580
XRAILS     = 1
	.if XRAILS
	.if CARDMOD
DB_X       = $72        ; data (shaft19-join-020: $73 is the card class's main code bank; DB_T moved into DB_SW):
	.else
DB_X       = $73        ; data:
	.endif
                        ; the composite cache's keys and users, the slot tables, column 36's saved words, scratch (XD_*)
XPAL       = 10         ; the composites' BG palette: palette 0's 0-11 and the bar strips' colours at 12-15
XPALB      = $3C00 + 32 * XPAL
BXRV       = $2D08      ; the BXR value the vblank routine latches into $2D04 with the buffer's parity (after the sprite request)
FINEADC    = $4CC3
XD_CTAB    = $8000      ; DB_X at MPR4: 6 key pages (2 (pi - 1) + side) x 256 near byte values -> cache slot (0: none)
XD_CKP     = $8600      ; per cache slot: its key page + 1 (0: none), its near byte
XD_CKV     = $8680
XD_CUSE    = $8700      ; per cache slot: bit 0 / 1 = in buffer 0's / 1's edge columns
XD_ESL     = $8780      ; per buffer: the 32 edge slots it uses (0: none)
XD_CTL     = $8800      ; the cache slots' tiles (1..XCN)
XD_CTH     = $8880
XD_BRL     = $8900      ; the 17 bar tiles
XD_BRH     = $8920
XD_BTL     = $8A00      ; the backdrop cache's tiles (1..XBN)
XD_BTH     = $8A80
XD_C36     = $8B00      ; column 36's words of rows 0-15 / 18-33 as the set-up found them
XD_BUF     = $8C00      ; scratch (512 bytes)
XD_N       = $8E00      ; set-up: a near tile (32 bytes)
XD_PALS    = $8E00      ; set-up, xset1 only: the VCE's palettes 0 and 15 (64 bytes, $8E00-$8E3F; XD_N is written after it)
XD_RAIL    = $8E40      ; set-up: the rails (16), the palette map (16)
XD_PM      = $8E50
XD_BB      = $8E60      ; the composites' strip bytes (6 key pages x 4 planes) and near masks (6): xcup
XD_NM      = $8E78
XD_Q0      = $8E80      ; set-up: 15 when the mask image is mirrored against its side
XD_MSK     = $8E7E      ; the mask sprites' pattern tile the set-up wrote our image into (0: none)
XD_TB      = $8B40      ; the top and bottom bars' words as the set-up found them (rows 36, 47; 72 bytes each)
XD_BUSE    = $8D80      ; per backdrop cache slot: its users (bit 0 / 1: buffer)
XD_BKL     = $8F00      ; per backdrop cache slot: its key + 1 (0: none)
XD_BKH     = $8F80
XD_BTAB    = $9000      ; backdrop phase tiles: 512 (pi - 1) + 32 row + (column - 3) -> slot
XD_BLS     = $9600      ; per buffer (+ $100): the cells holding a backdrop phase tile: row, column, slot (128 each)
XD_SW      = $9C00      ; the screen's backdrop words (16 x 32), copied at the set-up
XD_OUT     = $8E90      ; the pass's left-out blocks (out: 8 bands x 2 bytes)
XD_ROWS    = $8EA0      ; the camera cell's class rows (rows: 16 x 4 bytes)
XD_LR      = $9600      ; per buffer (+ $80): the cells holding a backdrop phase tile: row, column, slot (XD_LN their count)
XD_LC      = $9700
XD_LS      = $9800
XD_LN      = $8EE0
XD_VMAP    = $9A00      ; near byte value -> its composite key's value (the transparent word's values share one)
XD_LK      = $9900      ; per buffer (+ $20): the state its cells were written from: p0 (2), pi, out (16)
HOLD       = 0          ; room19-s-x-rails, section 10 A of room19-frame: 1 = a pass whose span after its rows plus KREST would pass the pad's
                        ; target is HELD: the hidden buffer keeps its new rows, the pass parity $339F is put back and the sprite table
                        ; asked for is the shown page (the screen repeats its picture whole; the next pass flips); 0 = such a pass runs late
YSM        = 1          ; room19-s-x-rails stage Y: 1 = smooth Y too (the BYR latch $2D0A, 17 rows, the object draw's fine-Y add off)
	.if YSM
XROWS      = 17
	.else
XROWS      = 16
	.endif
BYRV       = $2D0A      ; the BYR value the vblank routine latches into $2D06 (split 0: BYR = $2D06 + the buffer's base)
FINEADCY   = $4CEB      ; bank $80 (MPR2): the object draw's ADC $2D11 (operand at $4CEC): the camera's fine Y on scenery objects
XD_R16     = $8BD0      ; columns 0, 1, 35, 36 of BAT rows 16 and 34 as the set-up found them (16 bytes)
XMASK      = 0
	.if XMASK
XCNU       = XCN        ; the composite cache's slots in use
	.else
XCNU       = 72         ; (r19-bars-off-sprites) the composite cache's slots in use (design 2.2: at most 2 x 34 in use at once): the
                        ; first 72 of XCN
XD_TG      = $8700      ; per buffer (+ 128) per cache slot: the serial of the buffer's pass that last used it (x3's xpass / xfree; in
                        ; place of XD_CUSE and the edge-slot lists XD_ESL)
	.endif
XMRG       = 1          ; 1 = the visible blocks off the grid merged from the next cells' records (xcellh); 0 = a timing experiment only (holes)
XPOPT      = $7C00      ; DB_NEAR (MPR3 in the pass): the set bits of each byte value (256), made at the set-up
XBG        = 0
XLIM       = 112
XEST       = 8
XBAR       = 0
XTB        = 0
RNOWN      = 32
RNSLR      = 35
RSLACK     = 1
EFIX       = 1
EP0        = 1          ; (EFIX) 1 = on the X grid the edge words are direct (S words left, the bar word right), no slot filled; the next pass
                        ; off the grid regroups and fills; 0 = slots on the grid too (phase-0 images), as design 7.4 states
	.else
XMASK      = 0          ; (shaft19-join-020: XRAILS 0 = a4: the names the shared code tests)
XROWS      = 16
RSLACK     .equ 0
EFIX       .equ 0
EP0        .equ 0
	.endif

	.include "stubsyms.inc"  ; STUB_T0OK, STUB_MHOOK, STUB_CURMOD, STUB_PREV, STUB_SATW, STUB_ALLOCX

kmx9	.macro
	cmp t9
	bcc \1
	sta t9
	.if FOLD
	.else
	bra \2
	.endif
\1:
	.if FOLD
	.else
	sta t8
	nop
	.endif
\2:
	.endm
kmxu	.macro
	cmp umax
	bcc \1
	sta umax
	.if FOLD
	.else
	bra \2
	.endif
\1:
	.if FOLD
	.else
	sta t8
	nop
	.endif
\2:
	.endm
vsel	.macro
	lda #\1
	sta <VDCREG
	sta $0000
	.endm

	.bank 0
	.org $A000

	jmp rowent              ; 0 a row (a pass's first: rowgame is set)
	jmp satbody
	jmp modent              ; 2 modinit (an area load)
	jmp norts               ; 3 idlework
	jmp norts               ; 4 idlelate
	jmp lateup              ; 5 lateup
	jmp leave
	jmp norts               ; 7 vacate
	jmp hook

magic:	.db $19, $A7
dorm:	.db 0
obson:	.db 0
card:	.db 0
lastsc:	.db 0
armed:	.db 0
fail:	.db 0
nmod:	.db 0
ndorm:	.db 0
nrearm:	.db 0
nobs:	.dw 0
narm:	.db 0
nrel:	.db 0
nbsite:	.db 0
nleave:	.db 0
has:	.ds 5
stsav:	.ds 15
eng:	.db 0           ; engaged: set up, the mid path ours
lit:	.db 0
pend:	.db 0           ; our images are in the slots (an exit restore is due)
	.if XRAILS
pxr:	.db 0           ; the camera X's low byte at this pass's row 0
	.if YSM
pyr:	.db 0           ; the camera Y's
	.endif
	.if HOLD
pxt:	.db 0
pxf:	.db 0
	.endif
	.endif
doset:	.db 0           ; satbody: run the set-up
sdpend:	.db 0           ; satbody: the stand-down's sprite / BAT work (two passes: sdph)
sdph:	.db 0
patched:	.db 0           ; the mid path's code bytes are ours
stpin:	.db 0           ; the colour-cycle request site holds ours (patch / unpatch)
nstp:	.dw 0           ; steps mirrored by the hook (count)
	.if CARDMOD
rechk:	.db 0           ; (shaft19-join-020) sdtest for reeng: the mid path not tested
reng:	.db 0           ; satbody: engage again after a window's stand-down (reeng)
nreng:	.db 0           ; (count)
	.endif
sdwhy:	.db 0
gap:	.db 0
cons:	.db 0
ld:	.db 0
nld:	.db 0           ; Non-zero only while armed (dormant clears it), cleared on a lit pass and when the set-up is asked for. nld: loads seen (count)
lastrf:	.db 0
nsetup:	.db 0
nsd:	.db 0
nres:	.db 0
npass:	.dw 0           ; engaged passes (satbody's work done)
nleft:	.dw 0           ; blocks left out for units (sum over passes)
nover:	.dw 0           ; blocks left out for the 64-entry limit (sum)
umax:	.db 0
emax:	.db 0
nback:	.dw 0
nkeep:	.dw 0
tset0:	.db 0           ; FRAMES: set-up start, end
tset1:	.db 0
tres0:	.db 0           ; FRAMES: exit restore start, end
tres1:	.db 0
p0l:	.db 0           ; this pass: the near pointer at row 0, the hidden buffer's first BAT row (0 / 18)
p0h:	.db 0
lp0l:	.db $FF
lp0h:	.db $FF
rb:	.db 0
own:	.db 0
nlo:	.db 0           ; the near word: code + nlo, high nhs + carry (the row routine's operands, saved by cpymaps)
nhs:	.db 0
wbank:	.db 0
alim1:	.db 0
ourst:	.db 0, 0        ; per SAT page: our first entry, the entry after our last (0: none)
ourend:	.db 0, 0
nrm:	.db 0           ; remap cells (window offsets lo / hi) and their clone words
rml:	.ds 4
rmh:	.ds 4
rmw:	.ds 4
mside:	.ds 4           ; per mask entry 0-3: its side (0 left, 1 right), its half (0 upper, 1 lower)
mhalf:	.ds 4
msav:	.ds 64
bsav:	.ds 256
bword:	.ds 128         ; the border words we write: row * 8 + column index * 2
mid:	.ds 512         ; the mid map (16 rows x 32)
prop:	.ds 128         ; the near property table
t0:	.db 0
t1:	.db 0
t2:	.db 0
t3:	.db 0
t4:	.db 0
t5:	.db 0
t6:	.db 0
t7:	.db 0
t8:	.db 0
t9:	.db 0
c5act:	.db 0           ; Candidate 5: 1 while a heavy kpass is suspended across ticks
c5stage:	.db 0           ; Stage: 0 before ownrows, 1 before kent..kord, 2 before xpass+splug, 3 before kemit+flip
c5fr:	.db 0           ; FRAMES when the active/resumed tick started
c5satpg:	.db 0           ; carried pass's SATPAGE ($0E / $0F)
c5satok:	.db 0
c5nsat:	.db 0
c5hold:	.db 0           ; non-zero when kpass held (shold != 0)
c5nopad:	.db 0           ; non-zero when carried/paused (skip tpad)
c5bxrv:	.db 0           ; BXRV / BYRV computed by Stage 2 (xpass)
c5byrv:	.db 0
c5shx:	.db 0           ; shown BXRV / BYRV of the last completed frame
c5shy:	.db 0
nc5car:	.dw 0           ; carried pause count
nc5don:	.dw 0           ; carried pass completion count
sv4:	.db 0
cur:	.ds 3
wbuf:	.ds 3
zero8:	.db 0, 0, 0, 0, 0, 0, 0, 0
	.if RSLACK
; r19-slack-rows (R): the windows' state, here in the main bank (bank 3's own rows, wbat and bank 4's xpass / rown all read it; the
; recorders read this bank: the per-pass log)
bp0l:	.db 0, 0        ; per buffer: the camera cell (row 0's near pointer) its rows were drawn with ($FF high: none)
bp0h:	.db $FF, $FF
bk:	.db 0, 0        ; per buffer: its window's column offset k (0-3: BAT columns k .. k + 36) and row offset j (0-1: rows j .. j + 16)
bj:	.db 0, 0
rbe:	.db 0           ; this pass's buffer: its window's first BAT row (rb + j) and the BAT column of its near column 0 (2 + k)
cbe:	.db 2
ck:	.db 0           ; this pass's k, j
cj:	.db 0
rsh:	.db 0           ; this pass's own rows: 0 nothing, 1 a redraw, 2 / 4 an X / Y shift (bits), 8 the plug words put back first
rok:	.db 0           ; 1: the slack cells held one word at the last (re)engage (R on); 0: k = j = 0 and every cell change redraws
rslw:	.db 0, 0        ; that word
nrsh:	.dw 0           ; passes that shifted a window (count)
nrrd:	.dw 0           ; passes that redrew (count)
	.if EFIX
efl:	.db 0           ; (r19-edge-fixed) this pass's edge slots refilled (the log)
enov:	.db 0
ereset:	clx
.z:	stz EKMAP,x
	stz EKMAP + $100,x
	inx
	bne .z
	ldx #127
.k:	lda #$FF
	sta ESK,x
	stz ESU,x
	dex
	bpl .k
	stz estmp
	ldx #3
.p:	lda #$FF
	sta esph,x
	dex
	bpl .p
	stz eb0r
	stz eb0r+1
	stz exb
	stz exb+1
	lda #$FF
	sta epi
	sta epi+1
	stz esn
	stz esn+1
	stz esn+2
	stz esn+3
	.if EP0
	stz edir
	stz edir+1
	.endif
	rts
	.endif
	.endif

; ---------------------------------------------------------------- the sites
	.if CARDMOD = 0         ; (the hand-back's and the observer's: a4 only)
NSITE      = 5
gaddr_l:	.db <$6C8E, <$4A67, <$4A6D, <$4C85, <$44BF
gaddr_h:	.db >$6C8E, >$4A67, >$4A6D, >$4C85, >$44BF
gmpr4:	.db 1, 0, 0, 0, 0
gsite:	.ds 15              ; (RAM) mkg
gobs:	.ds 4
	rts
cobs:	.ds 2               ; the sums of those four bytes (mkdisc)
	.endif
cmid:	.ds 4
	.if CARDMOD = 0
osav:	.db 0               ; gobs holds the site's bytes
mobs:	jsr STUB_MHOOK          ; ours there: JSR mhook / NOP (four bytes, as data)
	nop
	.endif
gstp:	.ds 5
	rts
cstp:	.ds 2               ; the sums of those five bytes (mkdisc)
gsf:	.ds 1
csf:	.ds 2
	.if HUDS
chud:	.ds 2
chud2:	.ds 2
	.endif
ostp:	jsr STUB_MHOOK          ; ours there: JSR mhook / NOP / NOP (five bytes, as data)
	nop
	nop

	.if CARDMOD = 0
; gsite at run time (see above); A, X lost
mkg:	lda #$20                ; (JSR, the CPU's opcode: the three call sites keep it)
	sta gsite
	sta gsite+3
	sta gsite+9
	lda #<GROW
	sta gsite+1
	lda #>GROW
	sta gsite+2
	lda #<GWAIT
	sta gsite+4
	lda #>GWAIT
	sta gsite+5
	lda #<GSATR
	sta gsite+10
	lda #>GSATR
	sta gsite+11
	ldx #2
.c:	lda STUB_SATW,x         ; (the stub's own wait for the sprite flag / its own read of the allocator's byte: bank $80, always mapped)
	sta gsite+6,x
	lda STUB_ALLOCX,x
	sta gsite+12,x
	dex
	bpl .c
	rts
	.endif
; t2 / t3 = the two running sums (s1 += byte, s2 += s1, mod 256) of the X bytes at Y:A (A, X, Y lost)
fsum:	sta .a+1
	sty .a+2
	stz t2
	stz t3
	cly
.l:
.a:	lda $FFFF,y
	clc
	adc t2
	sta t2
	clc
	adc t3
	sta t3
	iny
	dex
	bne .l
	rts

	.if CARDMOD = 0
; t0/t1 = site X's address as the module writes it (MPR4 = the renderer's bank for row_draw: the caller maps it); X kept
saddr:	lda gaddr_l,x
	sta t0
	lda gaddr_h,x
	ldy gmpr4,x
	beq .d
	clc
	adc #$20
.d:	sta t1
	rts

; cur = the 3 bytes at (t1:t0); wr3: wbuf to (t1:t0), interrupts off for the three writes
rd3:	lda t0
	sta .a+1
	lda t1
	sta .a+2
	ldy #2
.l:
.a:	lda $FFFF,y
	sta cur,y
	dey
	bpl .l
	rts
wr3:	lda t0
	sta .a+1
	lda t1
	sta .a+2
	php
	sei
	ldy #2
.l:	lda wbuf,y
.a:	sta $FFFF,y
	dey
	bpl .l
	plp
	rts
; carry clear when cur equals the 3 bytes at gsite + Y (Y kept)
cmpg:	lda cur
	cmp gsite,y
	bne .no
	lda cur+1
	cmp gsite+1,y
	bne .no
	lda cur+2
	cmp gsite+2,y
	bne .no
	clc
	rts
.no:	sec
	rts
; Y = 3 X
x3:	txa
	asl a
	sta t2
	txa
	clc
	adc t2
	tay
	rts

handback:	tma #4
	sta sv4
	lda #GAMEBANK
	tam #4
	clx
.l:	jsr saddr
	jsr rd3
	jsr x3
	jsr cmpg
	bcc .n
	lda cur                 ; the stub's JSR?
	cmp #$20
	bne .bad
	lda cur+2
	cmp #$46
	beq .s1
	cmp #$47
	beq .s1
	cmp #$5F
	bne .bad
.s1:	lda cur
	sta stsav,y
	lda cur+1
	sta stsav+1,y
	lda cur+2
	sta stsav+2,y
	lda gsite,y
	sta wbuf
	lda gsite+1,y
	sta wbuf+1
	lda gsite+2,y
	sta wbuf+2
	jsr wr3
	lda #1
	sta has,x
	bra .n
.bad:	inc nbsite
.n:	inx
	cpx #NSITE
	bne .l
	lda sv4
	tam #4
	lda #1
	sta dorm
	inc ndorm
	rts

rearm:	tma #4
	sta sv4
	lda #GAMEBANK
	tam #4
	clx
.l:	lda has,x
	beq .n
	stz has,x
	jsr saddr
	jsr rd3
	jsr x3
	jsr cmpg
	bcs .n
	lda stsav,y
	sta wbuf
	lda stsav+1,y
	sta wbuf+1
	lda stsav+2,y
	sta wbuf+2
	jsr wr3
.n:	inx
	cpx #NSITE
	bne .l
	lda sv4
	tam #4
	stz dorm
	inc nrearm
	rts

obsq:	ldx #3
.c:	lda OBSSITE,x
	cmp mobs,x
	bne .x
	dex
	bpl .c
	inx                     ; (Z)
.x:	rts
obsin:	jsr obsq
	beq .in
	lda #<OBSSITE
	ldy #>OBSSITE
	ldx #4
	jsr fsum
	lda t2
	cmp cobs
	bne .no
	lda t3
	cmp cobs+1
	bne .no
	php
	sei
	ldx #3
.w:	lda OBSSITE,x
	sta gobs,x
	lda mobs,x
	sta OBSSITE,x
	dex
	bpl .w
	plp
	lda #1
	sta osav
.in:	lda #1
	sta obson
	rts
.no:	stz obson
	inc nbsite
	rts
obsout:	stz obson
	jsr obsq
	bne .x
	lda osav
	beq .bad                ; (ours there and nothing saved: cannot happen, leave precedes every read of this bank; counted)
	php
	sei
	ldx #3
.w:	lda gobs,x
	sta OBSSITE,x
	dex
	bpl .w
	plp
.x:	rts
.bad:	inc nbsite
	rts

	.endif
; the next vertical blank (the frame counter moves), or about 1.1 frames at most: an area load can run with the vblank interrupt off,
; and the exit restore under leave must not hang there (40 x 256 x 13 cycles = 133k; a frame is 119.4k). A, X, Y lost.
vwait:	lda FRAMES
	clx
	ldy #40
.w:	cmp FRAMES
	bne .x
	dex
	bne .w
	dey
	bne .w
.x:	rts

dormant:	stz armed
	stz ld
	stz c5act
	stz c5stage
	stz c5satok
	lda SCENE
	sta lastsc
	.if CARDMOD
	lda pend
	sta dorm
	bne .k
	lda #ARMBANK
	sta STUB_CURMOD
	inc nhb
	bne .k
	inc nhb+1
.k:	rts
	.else
	cmp #ROOM
	bne away
	jsr handback
	.if OBSERVE
	jmp obsin
	.else
	rts
	.endif
away:	jsr obsout
	lda dorm
	beq .x
	jsr rearm
.x:	lda FRAMES
	sta lastrf
	rts
	.endif

arm:
	.if CARDMOD
	stz dorm
	.else
	jsr rearm
	.endif
	lda #1
	sta armed
	inc narm
	stz gap
	stz cons
	lda FRAMES
	sta lastrf
	rts

; ---------------------------------------------------------------- the stub's entries
rowent:	lda ROWCNT
	beq .r0
	clc
	rts
.r0:	lda eng
	bne .r0n
	stz STUB_T0OK
.r0n:	stz own
	lda #1
	sta ROWGAME
	lda armed
	.if CARDMOD
	beq .n0
	jmp .a
.n0:
	.else
	bne .a
	.endif
	lda dorm
	beq .aw
	.if CARDMOD
	lda SCENE
	cmp #ROOM
	bne .dr
	lda LOCKB
	and #$08
	beq .dx
	tsx
	cpx #SLOAD
	bne .dx
.dr:	jsr arm
	bra .a
.dx:	lda sdwhy
	cmp #1
	bne .dz
	bbs3 <$25, .dz
	inc rechk
	jsr sdtest
	stz rechk
	bcs .dz
	jsr arm
	lda #1
	sta reng
.dz:	sec
	rts
	.else
	inc nrel
	jsr dormant
	sec
	rts
	.endif
.aw:	lda SCENE
	cmp #ROOM
	beq .in
	sta lastsc
	lda pend
	beq .np
	stz gap
	lda FRAMES
	sta lastrf
	bra .pa
.np:
	stz gap
	jsr gapcons
	sec
	rts
.in:	lda #ROOM
	sta lastsc
	.if ENGAGE
	lda card
	beq .nd
	stz gap
	jsr gapcons
	stz cons
	inc narm
.pa:	lda #1
	sta armed
	bra .a
	.else
.pa:	lda #1
	sta armed
	bra .a
	.endif
.nd:	jsr dormant
	sec
	rts
.a:	jsr getrb               ; (this pass's hidden buffer: the stand-down's second pass needs it too)
	lda eng
	beq .ne
	jmp engrow
.ne:	jsr gapcons
	lda LOCKB
	and #$08
	beq .lt
	tsx
	cpx #SLOAD
	bne .nl
	stx ld
	stz cons                ; (the passes in a row are counted from the load's own pass, however short the load was)
	inc nld
.nl:	lda pend
	bne .x
	lda SCENE
	cmp #ROOM
	bne .x
	lda <$55
	cmp #MODE
	bne .x
	lda ld
	beq .x
	lda cons
	cmp #2
	bcc .x
	stz ld
	jsr layout
	bcs .no
	jsr cpymaps             ; the near window, the mid map, the property table (carry set: refused)
	bcs .no
	lda #1
	sta doset
.x:	sec
	rts
.lt:	lda pend
	bne .x
	stz ld                  ; lit: no load is pending (unless pend is still waiting for exit restore)
.no:	jsr dormant             ; (lit before the set-up: not this visit; or refused)
	sec
	rts

gapcons:	lda FRAMES
	sec
	sbc lastrf
	cmp #1
	beq .c1
	stz cons
	bra .c2
.c1:	inc cons
.c2:	cmp #GAPN
	bcc .c3
	lda #1
	sta gap
.c3:	lda FRAMES
	sta lastrf
	rts

engrow:	jsr sdtest
	bcc .ok
	stz STUB_T0OK
	stz c5act
	stz c5stage
	stz c5satok
	tsx
	cpx #SLOAD
	bne .nu
	bbr3 <$25, .nu
	stx ld
.nu:	jsr unpatch
	lda #1
	sta sdpend
	sec
	rts
.ok:	lda c5act
	bne .rs
	lda OP_NPTRL
	sta p0l
	lda OP_NPTRH
	sta p0h
	.if XRAILS
	lda $2D0C               ; (the camera X this pass's rows are drawn from: its phase, xpass)
	sta pxr
	.if YSM
	lda $2D0E               ; (and the camera Y)
	sta pyr
	.endif
	.if HOLD
	lda TIMER               ; (the pass's start: right after a vertical blank; HOLD's clock)
	sta pxt
	lda FRAMES
	sta pxf
	.endif
	.endif
	lda FRAMES
	sta c5fr
	bra .rw
.rs:	lda FRAMES
	sta c5fr
.rw:	lda ROWN
	cmp #17
	bne .nc
	lda #1
	sta ROWN
.nc:	lda #1
	sta own
	stz ROWGAME
	lda lit
	bne .x
	lda LOCKB
	and #$08
	bne .x
	lda #1
	sta lit
.x:	clc
	rts

; rb = the hidden buffer's first BAT row: row 0's MAWR >> 6
getrb:	lda OP_MAWRL
	asl a
	lda OP_MAWRH
	rol a
	sta t0
	lda OP_MAWRL
	asl a
	asl a
	lda t0
	rol a
	and #$3F
	sta rb
	rts

; carry set: stand down (sdwhy)
sdtest:	lda #1
	ldx WINDOW
	bne .yw
.w0:	inc a
	ldx HP
	beq .y
	inc a
	ldx lit
	beq .d
	bbs3 <$25, .y
.d:	inc a
	ldx SCENE
	cpx #ROOM
	bne .y
	ldx <$55
	cpx #MODE
	bne .y
	jsr allocchk
	bcc .al
	lda #5
	bra .y
.al:	lda #6
	jsr layout
	bcs .y6
	.if CARDMOD
	lda rechk
	bne .om
	.endif
	jsr ourmid
	bcs .y6
.om:	lda OP_NPTRH
	and #$F0
	cmp #$C0
	bne .y6
	tma #6
	cmp wbank
	bne .y6
	lda OP_NPTRL
	sta t0
	lda OP_NPTRH
	and #$0F
	sta t1
	lda t0
	and #63
	cmp #33
	bcs .y7
	lda t0
	asl a
	rol t1
	asl a
	rol t1
	lda t1
	cmp #50
	bcs .y7
	clc
	rts
.y7:	lda #7
	bra .y
.y6:	lda #6
	bra .y
.yw:	.if WINDARK
	ldx lit
	beq .w0
	.endif
.y:	sta sdwhy
	sec
	rts

allocchk:	lda alim1               ; (unrolled: the engaged pass's glue is counted)
	cmp ALLOCEND+15
	beq .no
	bcc .no
	cmp ALLOCEND+14
	beq .no
	bcc .no
	cmp ALLOCEND+13
	beq .no
	bcc .no
	cmp ALLOCEND+12
	beq .no
	bcc .no
	cmp ALLOCEND+11
	beq .no
	bcc .no
	cmp ALLOCEND+10
	beq .no
	bcc .no
	cmp ALLOCEND+9
	beq .no
	bcc .no
	cmp ALLOCEND+8
	beq .no
	bcc .no
	cmp ALLOCEND+7
	beq .no
	bcc .no
	cmp ALLOCEND+6
	beq .no
	bcc .no
	cmp ALLOCEND+5
	beq .no
	bcc .no
	cmp ALLOCEND+4
	beq .no
	bcc .no
	cmp ALLOCEND+3
	beq .no
	bcc .no
	cmp ALLOCEND+2
	beq .no
	bcc .no
	cmp ALLOCEND+1
	beq .no
	bcc .no
	cmp ALLOCEND+0
	beq .no
	bcc .no
	clc
	rts
.no:	sec
	rts

layout:	pha
	lda OP_MIDOFF
	bne .no
	lda OP_MIDMASK
	cmp #$1F
	bne .no
	lda OP_MIDLO
	cmp #$40
	bne .no
	lda OP_MIDHI
	cmp #$02
	bne .no
	lda OP_NLO
	cmp #$E0
	bne .no
	lda OP_NH1
	clc
	adc OP_NH2
	cmp #$01
	bne .no
	lda OP_NOFF
	bne .no
	lda OP_STRL
	cmp #$40
	bne .no
	lda OP_STRH
	bne .no
	pla
	clc
	rts
.no:	lda #8
	sta fail
	pla
	sec
	rts

gmid:	.ds 5
omid:	.db $13, $C5, $23, $80, $11
ourmid:	ldx #2
.a:	lda MIDA,x
	cmp omid,x
	bne .no
	dex
	bpl .a
	lda MIDB
	cmp omid+3
	bne .no
	lda MIDB+1
	cmp omid+4
	bne .no
	clc
	rts
.no:	sec
	rts
; the colour-cycle request site (bank $85 at MPR4, MPR4 restored by the caller): C clear when it holds ours (A, X lost)
stpq:	ldx #4
.c:	lda STPSITE + $2000,x
	cmp ostp,x
	bne .n
	dex
	bpl .c
	clc
	rts
.n:	sec
	rts
stpsv:	lda #STPBANK
	tam #4
	jsr stpq
	bcc .ok
	lda #<(STPSITE + $2000)
	ldy #>(STPSITE + $2000)
	ldx #5
	jsr fsum
	lda t2
	cmp cstp
	bne .no
	lda t3
	cmp cstp+1
	bne .no
	ldx #4
.s:	lda STPSITE + $2000,x
	sta gstp,x
	dex
	bpl .s
.ok:	lda #GAMEBANK
	tam #4
	clc
	rts
.no:	lda #GAMEBANK
	tam #4
	sec
	rts
stpout:	lda stpin
	beq .x
	stz stpin
	tma #4
	pha
	lda #STPBANK
	tam #4
	jsr stpq
	bcs .n
	php
	sei
	ldx #4
.w:	lda gstp,x
	sta STPSITE + $2000,x
	dex
	bpl .w
	plp
.n:	pla
	tam #4
.x:	rts
unpatch:	jsr stpout
	lda patched
	beq .x
	stz patched
	.if XRAILS
	.if HUDS
	lda #26
	jsr cold3
	.else
	lda #14
	jsr cold4
	.endif
	.endif
	tma #4
	pha
	lda #GAMEBANK
	tam #4
	php
	sei
	ldx #2
.c:	lda MIDA + $2000,x
	cmp omid,x
	bne .n
	dex
	bpl .c
	ldx #2
.w:	lda gmid,x
	sta MIDA + $2000,x
	dex
	bpl .w
.n:	lda MIDB + $2000
	cmp omid+3
	bne .p
	lda MIDB + $2001
	cmp omid+4
	bne .p
	lda gmid+3              ; (TAY first: the BRA's offset byte is the LDA's opcode: a half-written path never runs, the rows are not running)
	sta MIDB + $2000
	lda gmid+4
	sta MIDB + $2001
.p:	lda SFSITE
	cmp #$80
	bne .q
	lda gsf
	sta SFSITE
.q:	plp
	pla
	tam #4
.x:	rts
patch:	tma #4
	pha
	lda #GAMEBANK
	tam #4
	lda #<(MIDA + $2000)
	ldy #>(MIDA + $2000)
	ldx #3
	jsr fsum
	lda t2
	cmp cmid
	bne .no
	lda t3
	cmp cmid+1
	bne .no
	lda #<(MIDB + $2000)
	ldy #>(MIDB + $2000)
	ldx #2
	jsr fsum
	lda t2
	cmp cmid+2
	bne .no
	lda t3
	cmp cmid+3
	bne .no
	jsr stpsv
	bcs .no
	ldx #2
.s:	lda MIDA + $2000,x
	sta gmid,x
	dex
	bpl .s
	lda MIDB + $2000
	sta gmid+3
	lda MIDB + $2001
	sta gmid+4
	php
	sei
	ldx #2
.w:	lda omid,x
	sta MIDA + $2000,x
	dex
	bpl .w
	lda omid+3
	sta MIDB + $2000
	lda omid+4
	sta MIDB + $2001
	lda #STPBANK
	tam #4
	ldx #4
.t:	lda ostp,x
	sta STPSITE + $2000,x
	dex
	bpl .t
	lda #1
	sta stpin
	sta patched             ; (r19-line154: stored before the PLP, two bytes of the main bank for chud2)
	plp
	pla
	tam #4
	clc
	rts
.no:	lda #3
	sta fail
	pla
	tam #4
	sec
	rts

	.if CARDMOD
reeng:	tma #4
	pha
	lda #$40
	tam #4
	lda #17                 ; (cold bank) bcols
	jsr cold
	lda #$FF
	sta lp0l
	sta lp0h
	tii PAL1, PAL4, 8
	tii PAL1 + 8, PAL4 + 8, 8
	tii PAL1 + 16, PAL4 + 16, 8
	tii PAL1 + 24, PAL4 + 24, 8
	jsr vwait
	php
	sei
	lda #$10
	sta $0402
	stz $0403
	tai $0404, bpart, 32
	lda #$40
	sta $0402
	lda #$01
	sta $0403
	tia bpart, $0404, 32
	plp
	lda #<SFSITE
	ldy #>SFSITE
	ldx #2
	jsr fsum
	lda t2
	cmp csf
	bne .no
	lda t3
	cmp csf+1
	bne .no
	jsr patch
	bcs .no
	lda SFSITE
	sta gsf
	lda #$80
	sta SFSITE
	.if HUDS
	lda #23
	jsr cold3
	.else
	lda #20                 ; (bank 4) xset2
	jsr cold4
	.endif
	.if PLG
	lda #17                 ; (bank 3) the plug's tables, pool, state (r19-plug-streams)
	jsr cold3
	.endif
	lda #1
	sta eng
	jsr c5init
	stz lit
	lda #64
	sta ourend
	sta ourend+1
	sta ourst
	sta ourst+1
	inc nreng
	pla
	tam #4
	clc
	rts
.no:	lda #6
	sta sdwhy
	pla
	tam #4
	sec
	rts
	.endif

; ---------------------------------------------------------------- satbody (interrupts off on entry and on return)
satbody:	lda armed
	bne .a
	.if CARDMOD
	rts
	.else
	lda dorm
	bne .rl
	rts                     ; (away: the stub's own request follows)
.rl:	inc nrel
	jmp dormant
	.endif
.a:
	.if CARDMOD
	lda reng                ; (shaft19-join-020) engaged again after a window's stand-down
	beq .a0
	stz reng
	cli
	jsr reeng
	sei
	bcs .a1
	rts
.a1:	jmp dormant
.a0:
	.endif
	lda doset
	beq .b
	stz doset
	cli
	lda #3                  ; the set-up (cold bank); carry set: refused (slots back already)
	jsr cold
	sei
	bcc .x
	jmp dormant
.b:	lda sdpend              ; the stand-down: this pass's page and buffer now, the other one in the next pass (each shown only after
	beq .c                  ; its own vblank: the shown pair never changes under the picture)
	stz eng
	cli
	jsr sdwork
	sei
	inc sdph
	lda sdph
	cmp #2
	bcs .b2
	rts
.b2:	stz sdph
	stz sdpend
	inc nsd
	stz gap
	lda FRAMES
	sta lastrf
	lda sdwhy
	cmp #3
	beq .c
	cmp #4
	beq .c
	lda ld
	bne .c
	jmp dormant
.c:	lda eng
	bne .e
	lda pend
	beq .x
	lda #29                 ; (bank 3) check exit/reload restore and missed dark-window rescue
	jsr cold3
	bcs .x
	jmp dormant
.x:	rts
.e:	stz STUB_T0OK           ; waitfix waits cleanly for vblank after engaged pass (no .late lag-1 skip)
	lda c5act               ; the engaged pass (bank 3), Candidate 5 resumable across vblanks
	sta c5nopad
	bne .e1
	stz c5stage
	stz c5satok
	lda SATPAGE
	sta c5satpg
	lda NSAT
	cmp #65
	bcc .e0
	lda #64
.e0:	sta c5nsat
.e1:	php
	sei
	lda c5act
	bne .e1s
	dec $339F               ; hold frame display latches at T-1 across preemptions (initial entry only)
.e1s:	lda c5satpg
	eor #1
	sta SATPAGE
	lda c5shx
	sta BXRV
	lda c5shy
	sta BYRV
	plp
	.if C5CAR
	lda FRAMES
	cmp c5fr
	bne .c5p
	.endif
	stz c5hold
	lda #0                  ; (bank 3) kpass
	jsr cold3
	bcc .eok
	lda c5hold
	beq .c5p
	lda c5satpg
	eor #1
	sta SATPAGE
	lda c5shx
	sta BXRV
	lda c5shy
	sta BYRV
	stz c5act
	stz c5stage
	stz c5satok
	bra satreq
.eok:	lda c5satpg
	sta SATPAGE
	lda BXRV
	sta c5shx
	lda BYRV
	sta c5shy
	lda c5act
	beq .ek0
	inc nc5don
	bne .ek0
	inc nc5don+1
.ek0:	stz c5act
	stz c5stage
	stz c5satok
	bra satreq
.c5p:	lda #1
	sta STUB_SATSKIP
	jsr c5pause
	sei
	rts
satreq:	vsel $13
	ldx $2214
	ldy $2215
	cli
	nop                     ; (an interrupt already waiting is taken here, the flag clear)
satrqw:	stx $0002
	sty $0003               ; the DMA runs at the first blank after this write ...
	smb1 <$B1
	sei
	rts

lateup:	lda eng
	beq .lx
	lda c5act
	beq .lx
	rmb1 <$B1
.lx:	rts

c5init:	stz x16dc
	stz c5act
	stz c5stage
	stz c5satok
	lda BXRV
	sta c5shx
	lda BYRV
	sta c5shy
	rts

c5pause:	lda c5satpg
	eor #1
	sta SATPAGE
	lda c5shx
	sta BXRV
	lda c5shy
	sta BYRV
	lda #1
	sta c5act
	inc nc5car
	bne .cx
	inc nc5car+1
.cx:	rts

c5card:	lda #1
	sta $1A07
	stz $1A08
	stz $1A05
	stz $1A06
	lda #$11
	sta $1A09
	lda #<C5SAT
	sta $1A02
	lda #>C5SAT
	sta $1A03
	lda #(C5SAT >> 16)
	sta $1A04
	rts

c5save:	tma #4
	pha
	lda #$40
	tam #4
	jsr c5card
	clx
.l:	sei
	st0 #1
	stx $0002
	lda c5satpg
	sta $0003
	ldy #2
	sty <VDCREG
	st0 #2
	tai $0002, $8000, 16
	cli
	txa
	clc
	adc #8
	tax
	bne .l
	pla
	tam #4
	rts

c5load:	tma #4
	pha
	lda #$40
	tam #4
	jsr c5card
	clx
.l:	sei
	st0 #0
	stx $0002
	lda c5satpg
	sta $0003
	ldy #2
	sty <VDCREG
	st0 #2
	tia $8000, $0002, 16
	cli
	txa
	clc
	adc #8
	tax
	bne .l
	pla
	tam #4
	rts

; ---------------------------------------------------------------- an area load (the stub; the screen is dark). Never armed from here:
	.if CARDMOD
modent:	stx cmld
	jsr cmcopy
	bcc .ok
	rts
.ok:
	.else
modent:
	.endif
	inc nmod
	stz armed
	stz eng
	stz pend
	stz doset
	stz sdpend
	stz sdph
	stz fail
	stz ourend
	stz ourend+1
	lda SCENE
	sta lastsc
	.if CARDMOD = 0
	jsr mkg
	.endif
	lda #0
	jsr cold
	cla
	rol a
	eor #1
	sta card
	.if CARDMOD
	bne .c
	sec
	rts
.c:	jsr arm
	lda cmld
	beq .n
	sta ld                  ; (rowent's mark of the load: its level, the count)
	inc nld
.n:	clc
	rts

cmld:	.db 0               ; the load seen (the arm's X)
nhb:	.dw 0               ; hand-backs to ARMBANK (count)
	.if BANK5
	.if PLG
cmbk:	.db CB, CB3, CB4, CB6, CB5 ; (the fifth bank last: the set-up's cmcpx after a kbuild copies it alone)
cmsums:	.dw 0, 0, 0, 0, 0   ; (mkdisc) csum of each of the banks 1 .. CMN - 1 as built
	.else
cmbk:	.db CB, CB3, CB4, CB5
cmsums:	.dw 0, 0, 0, 0      ; (mkdisc) csum of each of the banks 1 .. CMN - 1 as built
	.endif
	.else
cmbk:	.db CB, CB3, CB4
cmsums:	.dw 0, 0, 0         ; (mkdisc) csum of each of the banks 1 .. CMN - 1 as built
	.endif
cmkey:	.dw 0               ; (mkdisc) the build's key: the arm compares it before it runs this bank
	.if BANK5
cmcopy:	clx                     ; (cmcpx: from bank X + 1 on; the set-up's copy of the fifth bank after a kbuild that rebuilt: X = 3)
cmcpx:	tma #4
	pha
	stz $1A02
	txa
	inc a
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $1A03
	.else
cmcopy:	tma #4
	pha
	stz $1A02
	lda #$20
	sta $1A03
	.endif
	lda #CMADDR
	sta $1A04
	stz $1A05
	stz $1A06
	lda #1
	sta $1A07
	stz $1A08
	lda #$11
	sta $1A09
	.if BANK5 = 0
	clx
	.endif
.b:	lda cmbk,x
	tam #4
	stz .t+3
	lda #$80
	sta .t+4
.t:	tai $1A00, $8000, 32
	lda .t+3
	clc
	adc #32
	sta .t+3
	bcc .t
	inc .t+4
	lda .t+4
	cmp #$A0
	bne .t
	jsr csum
	txa
	asl a
	tay
	lda cs1
	cmp cmsums,y
	bne .no
	lda cs2
	cmp cmsums+1,y
	bne .no
	inx
	cpx #CMN - 1
	bne .b
	pla
	tam #4
	clc
	rts
.no:	pla
	tam #4
	sec
	rts
cs1:	.db 0
cs2:	.db 0
csum:	stz cs1
	stz cs2
	lda #$80
.g:	sta .a+2
	inc a
	sta .b+2
	inc a
	sta .c+2
	inc a
	sta .d+2
	cla
	clc
	cly
.l:
.a:	adc $8000,y
.b:	adc $8100,y
.c:	adc $8200,y
.d:	adc $8300,y
	iny
	bne .l
	adc cs1
	sta cs1
	clc
	adc cs2
	sta cs2
	lda .d+2
	inc a
	cmp #$A0
	bne .g
	rts
	.else
	jmp dormant
	.endif

leave:	inc nleave
	stz c5act
	stz c5stage
	stz c5satok
	lda <VDCREG
	pha
	lda eng
	ora sdpend
	beq .p
	stz eng
	stz sdpend
	stz sdph
	jsr unpatch
	lda #1
	sta sdlv
	jsr sdwork
	stz sdlv
.p:	lda pend
	beq .o
	lda #6
	jsr cold
.o:	pla
	sta <VDCREG
	sta $0000
	.if CARDMOD = 0
	jsr obsout
	jsr rearm
	.endif
	stz armed
	stz ROWGAME
	rts

norts:	rts

; ---------------------------------------------------------------- entry 8: the stub's mhook (A lost; X kept by mcall; Y ours to keep)
hook:	phy
	tsx
	lda $2107,x
	cmp #>(STPSITE + 2)
	bne .ob
	lda $2106,x
	cmp #<(STPSITE + 2)
	beq stphk
	bra .x
.ob:
	.if CARDMOD = 0
	cmp #>(OBSSITE + 2)
	bne .x
	lda $2106,x
	cmp #<(OBSSITE + 2)
	bne .x
	jsr gobs
	inc nobs
	bne .o
	inc nobs+1
.o:	lda SCENE
	sta lastsc
	ldx pend
	bne .arm
	cmp #ROOM
	bne .ow
	lda card
	beq .x
.arm:	tsx
	lda #<(OBSSITE + 3)
	sta $2106,x
	jsr obsout
	jsr arm
.x:	ply
	rts
.ow:	tsx
	lda #<(OBSSITE + 3)
	sta $2106,x
	jsr away
	bra .x
	.else
.x:	ply
	rts
	.endif
stphk:	lda eng
	beq .r
	tii PAL1, PAL4, 8
	tii PAL1 + 8, PAL4 + 8, 8
	tii PAL1 + 16, PAL4 + 16, 8
	tii PAL1 + 24, PAL4 + 24, 8
	inc nstp
	bne .r
	inc nstp+1
.r:	jsr gstp
	ply
	rts

; the cold bank's entry A (MPR6 kept; the carry as the entry leaves it)
cold:	sta .j+1
	tma #6
	pha
	lda #CB
	tam #6
.j:	jsr $C000
	pla
	tam #6
	rts
cold3:	sta c3j+1               ; the second cold bank's entry A (MPR6 as it was on return: a call from the cold bank returns there)
	tma #6
	pha
	lda #CB3
c3in:	tam #6
c3j:	jsr $C000
	pla
	tam #6
	rts
cold4:	sta c3j+1
	tma #6
	pha
	lda #CB4
	bra c3in
	.if BANK5
c5:	sta .j+1                ; (r19-leftout-order) the fifth image bank's entry A at MPR4 (the pass: DB_K's back after it; the set-up)
	tma #4
	pha
	lda #CB5
	tam #4
.j:	jsr $8000
	pla
	tam #4
	rts
ocached:	.db 0
nobuild:	.db 0           ; set-ups that made them
	.endif

; ---------------------------------------------------------------- the near map, the mid map, the property table (rowent at the set-up
cpymaps:	lda OP_NPTRH
	and #$F0
	cmp #$C0
	beq .j843
	jmp .no
.j843:
	lda OP_MPTRH
	cmp #$D0
	beq .j853
	jmp .no
.j853:
	lda OP_MPTRL
	beq .j855
	jmp .no
.j855:
	tma #6
	sta wbank
	lda OP_NLO              ; (the near word's operands for the S word map: lo = code + NLO, hi = NH1 + NH2 + carry)
	sta nlo
	lda OP_NH1
	clc
	adc OP_NH2
	sta nhs
	lda <$59
	sta .p+1
	lda <$5A
	sta .p+2
	ldy #127
.p:	lda $FFFF,y
	sta prop,y
	dey
	bpl .p
	lda #<mid
	sta .d+1
	lda #>mid
	sta .d+2
	lda #$D0
	sta .s+2
	clx
.r:	ldy #31
.m:
.s:	lda $D000,y
.d:	sta mid,y
	dey
	bpl .m
	inc .s+2
	lda .d+1
	clc
	adc #32
	sta .d+1
	bcc .n
	inc .d+2
.n:	inx
	cpx #16
	bne .r
	tma #4                  ; the near map to DB_NEAR
	pha
	lda #DB_NEAR
	tam #4
	stz .t+1
	stz .t+3
	lda #$C0
	sta .t+2
	lda #$80
	sta .t+4
.c:
.t:	tii $C000, $8000, 8
	lda .t+1
	clc
	adc #8
	sta .t+1
	sta .t+3
	bcc .c
	inc .t+2
	inc .t+4
	lda .t+4
	cmp #$91
	bne .c
	pla
	tam #4
	clc
	rts
.no:	lda #7
	sta fail
	sec
	rts

; MAWR (vmawr) / MARR (vmarr) = A (lo) / X (hi), then the data register selected. Callers hold interrupts off around address and data.
vmawr:	pha
	stz <VDCREG
	st0 #0
	pla
	sta $0002
	stx $0003
	lda #2
	sta <VDCREG
	st0 #2
	rts
vmarr:	pha
	lda #1
	sta <VDCREG
	st0 #1
	pla
	sta $0002
	stx $0003
	lda #2
	sta <VDCREG
	st0 #2
	rts
; MAWR = BAT row A (0-63), column X, VWR selected (interrupts off)
vbat:	stx vb1
	stz vb0
	lsr a
	ror vb0
	lsr a
	ror vb0
	tax                     ; (high byte: row >> 2)
	lda vb0
	ora vb1
	jmp vmawr
vb0:	.db 0
vb1:	.db 0

sdwork:	stz t7                  ; page 0 / 1 (not from leave: only this pass's page, which the coming vblank shows with this pass's buffer)
.p:	lda sdlv
	bne .pa
	lda SATPAGE
	and #1
	cmp t7
	beq .pa
	jmp .n
.pa:	lda t7
	ora #$0E
	sta t8
	lda t7                  ; msav + 32 p
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc #<msav
	sta .t+1
	lda #>msav
	adc #0
	sta .t+2
	stz t6
	lda #0
	ldx t8
	jsr vmawr
	ldx #4
.t:	tia msav, $0002, 8
	lda .t+1
	clc
	adc #8
	sta .t+1
	bcc .t1
	inc .t+2
.t1:	dex
	bne .t
	ldx t7
	lda ourst,x
	sta t6
	lda ourend,x
	sta t9
	stz ourend,x
	lda t9
	beq .n                  ; (none of ours in this page)
	lda sdlv
	bne .z
	lda SATPAGE
	and #1
	cmp t7
	bne .z
	lda NSAT
	cmp t6
	bcc .z
	sta t6
.z:	lda t6
	cmp t9
	bcs .n
	lda t6
	asl a
	asl a
	ldx t8
	jsr vmawr
	tia zero8, $0002, 8
	inc t6
	bra .z
.n:	inc t7
	lda t7
	cmp #2
	beq .j2050
	jmp .p
.j2050:
	stz t7                  ; the border columns (not from leave: only this pass's hidden buffer): bsav (buffer * 128 + row * 8 + 2 index)
.bb:	lda sdlv
	bne .ba
	lda rb
	beq .b1
	lda #1
.b1:	cmp t7
	beq .ba
	jmp .bx
.ba:
	.if RSLACK
	ldy t7                  ; (bank 4) r19-slack-rows: this buffer's slack cells (columns 37-39, row 17 / 35) back
	lda #RNSLR
	jsr cold4
	.endif
	stz t9
.br:	lda t7                  ; Y = buffer * 128 + row * 8
	lsr a
	lda #0
	ror a
	sta t0
	lda t9
	asl a
	asl a
	asl a
	ora t0
	tay
	ldx #0
.bc:	cpx #2
	beq .bn
	phx
	phy
	lda t7                  ; BAT row = 18 buffer + row
	beq .b0
	lda #18
.b0:	clc
	adc t9
	pha
	lda bcol,x
	tax
	pla
	jsr vbat
	ply
	plx
	phx
	txa
	asl a
	sta t0
	tya
	clc
	adc t0
	tax
	lda bsav,x
	sta $0002
	lda bsav+1,x
	sta $0003
	plx
.bn:	inx
	cpx #4
	bne .bc
	inc t9
	lda t9
	cmp #16
	bne .br
.bx:	inc t7
	lda t7
	cmp #2
	beq .bz
	jmp .bb
.bz:
	.if XRAILS
	lda #17
	jsr cold4
	.if XBAR = 0
	jsr xsdb16
	.endif
	.endif
	tii zero8, PAL4, 8
	tii zero8, PAL4 + 8, 8
	tii zero8, PAL4 + 16, 8
	tii zero8, PAL4 + 24, 8
	rts
bcol:	.db 0, 1, 34, 35
	.if XRAILS
	.if XBAR = 0
x16dc:	.db 0
xsdb16:	lda x16dc
	bne .x
	inc x16dc
	tma #3
	pha
	tma #4
	pha
	tma #6
	pha
	lda #DB_X
	tam #3
	lda #$40
	tam #4
	lda #CB
	tam #6
	jsr pinit
	clx
.l:	phx
	lda XD_BTL - $2000 + 104,x
	sta tl
	lda XD_BTH - $2000 + 104,x
	sta th
	stx cil
	lda #>512
	sta cih
	lda #2
	jsr cbi
	jsr rdtile
	plx
	inx
	cpx #16
	bne .l
	pla
	tam #6
	pla
	tam #4
	pla
	tam #3
.x:	rts
	.endif
	.endif

; ---------------------------------------------------------------- set-up's tables in the main bank (called from the cold bank, MPR6 = it on
buildcls:	tma #4
	pha
	tma #6
	pha
	lda #DB_NEAR
	tam #4
	lda #DB_CLS
	tam #6
	stz nrm
	stz .s+1
	lda #$80
	sta .s+2
	lda #$C0
	sta .d+2
	clx
.byt:	ldy #0
.bit:
.s:	lda $8000,y
	and #$7F
	sta t1
	phx
	tax
	lda prop,x
	plx
	asl a                   ; carry: backdrop class
	rol t0
	lda t0
	lsr a
	bcs .nr                 ; (backdrop class: no remap)
	lda t1
	phx
	ldx #2
.rc:	cmp rcode,x
	beq .rm
	dex
	bpl .rc
	plx
	bra .nr
.rm:	lda rclone,x
	plx
	phx
	phy
	ldx nrm
	cpx #4
	bcs .rf
	sta rmw,x
	tya
	clc
	adc .s+1
	sta rml,x
	lda .s+2
	adc #0
	sec
	sbc #$80
	sta rmh,x
	inc nrm
.rf:	ply
	plx
.nr:	iny
	cpy #8
	bne .bit
	lda t0
.d:	sta $C000,x
	lda .s+1
	clc
	adc #8
	sta .s+1
	bcc .c
	inc .s+2
.c:	inx
	bne .c2
	inc .d+2
.c2:	lda .s+2
	cmp #$91                ; (the map and the 256 bytes after it: 544 bytes of bits)
	bne .byt
	stz $C220               ; (4 bytes past them: zero)
	stz $C221
	stz $C222
	stz $C223
	lda #1                  ; shifts 1-7: B_s[k] = (B0[k] << s) | (B0[k + 1] >> (8 - s)), k 0 .. 547
	sta t2
.sl:	lda t2
	asl a
	asl a
	clc
	adc #$C0
	sta .w+2
	stz .w+1
	stz .a+1
	lda #$C0
	sta .a+2
	lda #<548
	sta t5
	lsr a                   ; (t6 = >548 = 2 = (<548) >> 4; not LDA #2 / STA abs: those three bytes are also the first of the colour-cycle
	lsr a                   ;  site's, and the sector scan wants no run of any site's bytes in the module's sectors)
	lsr a
	lsr a
	sta t6
.k:
.a:	lda $C000
	sta t3
	lda .a+1
	sta .b+1
	lda .a+2
	sta .b+2
	inc .b+1
	bne .b0
	inc .b+2
.b0:
.b:	lda $C001
	sta t4
	ldx t2
.sh:	asl t4
	rol t3
	dex
	bne .sh
	lda t3
.w:	sta $C400
	inc .a+1
	bne .a1
	inc .a+2
.a1:	inc .w+1
	bne .w1
	inc .w+2
.w1:	lda t5
	bne .d1
	dec t6
.d1:	dec t5
	lda t5
	ora t6
	bne .k
	inc t2
	lda t2
	cmp #8
	beq .e8
	jmp .sl
.e8:	pla
	tam #6
	pla
	tam #4
	rts
rcode:	.db $0D, $0E, $18
rclone:	.db $C6, $C7, $C8

; ---------------------------------------------------------------- set-up's and the stand-down's work areas (the pass's are bank 3's)
sdlv:	.db 0           ; sdwork from leave (no pass in flight: both pages from our first entry)
bpart:	.ds 128         ; per screen block (16 bj + bi): 16 x the partition of its four backdrop tiles by equality (mkpart, at set-up)
kbf0:	.db 0           ; FRAMES at kbuild's start, end (the dark set-up's table part)
kbf1:	.db 0
kcached:	.db 0
nbuild:	.db 0

; ---------------------------------------------------------------- the leave-out key: the fewest DISTINCT PLUG IMAGES first
	.if FOLD
	.else
	.include "shaft19_mkpart.inc"
	.endif
	.include "shaft19_ptab.inc"

; was on return): nib[i] = c(i) << 3 | c(i + 1) << 2 | c(i + 64) << 1 | c(i + 65), c(i) = bit i of DB_CLS's shift-0 stream (byte
; i >> 3, MSB first: getrows' order), 0 from i = 4096 on (past the map: the bitmap's zero bytes)
mknib:	tma #4
	pha
	tma #6
	pha
	lda #DB_CLS
	tam #4
	lda #DB_N
	tam #6
	stz .r+1
	lda #$80
	sta .r+2
	stz .w+1
	lda #$C0
	sta .w+2
	stz t1
	jsr .bit
	cla
	rol a
	sta t3                  ; c(0)
.l:	jsr .bit                ; pass 1: h2[i] = c(i) << 1 | c(i + 1)
	lda t3
	rol a
	and #3
.w:	sta $C000
	and #1
	sta t3
	inc .w+1
	bne .l
	inc .w+2
	lda .w+2
	cmp #$D0
	bne .l
	ldx #63
.z:	stz $D000,x
	dex
	bpl .z
	lda #$C0                ; pass 2: nib[i] = h2[i] << 2 | h2[i + 64]
	sta .a+2
	sta .b+2
	sta .s+2
.pg:	cly
.a:	lda $C000,y
	asl a
	asl a
.b:	ora $C040,y
.s:	sta $C000,y
	iny
	bne .a
	inc .a+2
	inc .b+2
	inc .s+2
	lda .a+2
	cmp #$D0
	bne .pg
	pla
	tam #6
	pla
	tam #4
	rts
.bit:	dec t1                  ; carry = the next bit of the stream
	bpl .b1
.r:	lda $8000
	sta t0
	lda #7
	sta t1
	inc .r+1
	bne .b1
	inc .r+2
.b1:	asl t0
	rts

; ---------------------------------------------------------------- the pass's tables (bank 3's entry 3 jumps here: CB3 at MPR6; setup,
kbuild:	lda #$FF                ; (own rows: neither buffer holds a camera cell's rows yet)
	sta bp0h
	sta bp0h+1
	tma #4
	pha
	lda FRAMES
	sta kbf0
	lda #DB_K
	tam #4
	.if WAL = 0
	stz t8                  ; the pseudo-groups' pages
.g:	lda t8
	clc
	adc #KGPAGE
	sta .y0+2
	sta .y1+2
	sta .x0+2
	sta .x1+2
	sta .p0+2
	sta .p1+2
	sta .a0+2
	sta .a1+2
	cly
	clx
.p:	lda kpr0,x
	asl a
	asl a
	asl a
	asl a
	phx
	ldx t8
	clc
	adc kgy,x
	plx
.y0:	sta $8000,y
	cla
.y1:	sta $8001,y
	lda kpc0,x
	asl a
	asl a
	asl a
	asl a
	phx
	ldx t8
	clc
	adc kgxl,x
	sta t0
	lda kgxh,x
	adc #0
	plx
.x1:	sta $8003,y
	lda t0
.x0:	sta $8002,y
	lda kpcl,x
	asl a
	phx
	ldx t8
	clc
	adc kgpl,x
	sta t0
	lda kgph,x
	adc #0
	plx
.p1:	sta $8005,y
	lda t0
.p0:	sta $8004,y
	lda #$04
.a0:	sta $8006,y
	lda kpah,x
.a1:	sta $8007,y
	tya
	clc
	adc #8
	tay
	inx
	cpx #21
	bne .p
	inc t8
	lda t8
	cmp #17
	beq .gx
	jmp .g
.gx:
	.endif
	stz t8
.mt:	lda t8
	lsr a
	lsr a
	lsr a
	lsr a
	asl a
	asl a
	asl a
	tax                     ; msav + 32 page + 8 mask
	cly
.c:	lda msav,x
	sta kmte,y
	inx
	iny
	cpy #8
	bne .c
	lda t8
	and #15
	tay
	lda kmshape,y
	beq .off
	cmp #3
	beq .put
	sta t5                  ; cells: 1 or 2
	lda kmcell,y
	sta t4                  ; o: the first displayed cell
	lda kmte+7              ; source cell: y flip ? 4 - cells - o : o
	bpl .nf
	lda #4
	sec
	sbc t5
	sec
	sbc t4
	bra .sf
.nf:	lda t4
.sf:	asl a
	asl a
	sta t0
	lda kmte+4
	and #$F3
	ora t0
	sta kmte+4
	lda t4                  ; y + 16 o
	asl a
	asl a
	asl a
	asl a
	clc
	adc kmte
	sta kmte
	bcc .y
	inc kmte+1
.y:	lda kmte+7              ; cgy 0 (16 lines) / 1 (32)
	and #$CF
	ldy t5
	cpy #2
	bne .c1
	ora #$10
.c1:	sta kmte+7
	bra .put
.off:	lda kmte+1              ; y + 512
	ora #2
	sta kmte+1
.put:	lda t8
	asl a
	asl a
	asl a
	sta .d+3
	lda t8
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #KMTPAGE
	sta .d+4
.d:	tii kmte, $9A00, 8
	inc t8
	lda t8
	cmp #128
	beq .mx0
	jmp .mt
.mx0:	clx
.mx:	lda mside,x
	asl a
	ora mhalf,x
	sta mnix,x
	lda mhalf,x
	asl a
	asl a
	sta mhb,x
	inx
	cpx #4
	bne .mx
	lda #$FF                ; (no camera cell's record in kh)
	sta kcl
	sta kch
	.if WAL
	lda #1
	sta kcached
	.else
	; the key
	lda #DB_CLS
	tam #4
	stz t0
	stz t1
	stz t2
	stz t3
	cly
.s0:	lda $8000,y
	jsr kfl
	iny
	bne .s0
.s1:	lda $8100,y
	jsr kfl
	iny
	bne .s1
.s2:	lda $8200,y
	jsr kfl
	iny
	cpy #8
	bne .s2
	cly
.s3:	lda bpart,y
	jsr kfl
	iny
	cpy #128
	bne .s3
	lda #KVER
	jsr kfl
	lda #$19
	sta kmte
	lda #$5C
	sta kmte+1
	ldx #KVER               ; (X: KVER is 2, and LDA #2 / STA abs are the colour-cycle site's first three bytes; X is set again below)
	stx kmte+2
	lda t0
	sta kmte+3
	lda t1
	sta kmte+4
	lda t2
	sta kmte+5
	lda t3
	sta kmte+6
	stz $1A02
	stz $1A03
	lda #3
	sta $1A04
	clx
.kc:	lda $1A00
	cmp kmte,x
	bne .rb
	inx
	cpx #7
	bne .kc
	lda #1
	sta kcached
	jmp .end
.rb:	stz kcached
	jsr mknib               ; (main bank) the nibble map in DB_N
	lda #DB_N
	tam #4
	.if FOLD
	lda #8                  ; (bank 4) the nibble map's bit 4: a staircase cell among the block's four
	jsr cold4
	stz t8
	lda #$90
	sta .kt+2
	sta .k5+2
.kb:	ldx t8
	lda bpart,x
	sta t0
	ldy #0
.kn:	tya
	ora t0
	tax
	lda dimg,x
.kt:	sta $9000,y
	iny
	cpy #16
	bne .kn
	lda #5
.k5:	sta $9000,y
	iny
	cpy #32
	bne .k5
	lda .kt+1
	clc
	adc #32
	sta .kt+1
	sta .k5+1
	bcc .kq
	inc .kt+2
	inc .k5+2
	bra .kq
	.else
	stz t8
	lda #$90
	sta .kt+2
.kb:	ldx t8
	lda bpart,x
	sta t0
	ldy #0
.kn:	tya
	ora t0
	tax
	lda dimg,x
	ldx t8
.kt:	sta $9000,y
	iny
	cpy #16
	bne .kn
	lda .kt+1
	clc
	adc #16
	sta .kt+1
	.endif
	bcc .kq
	inc .kt+2
.kq:	inc t8
	bpl .kb
	stz kcy
.cy:	stz kcx
.cx:	lda kcy
	lsr a
	lsr a
	sta kixh
	lda kcy
	and #3
	lsr a
	ror a
	ror a
	clc
	adc kcx
	sta kixl
	ldy kcy
	ldx kcx
	clc
	lda krowl,y
	adc kcoll,x
	sta kcb
	lda krowm,y
	adc kcolh,x
	sta kcb+1
	lda krowh,y
	adc #0
	sta kcb+2
	txa
	clc
	adc kcrl,y
	sta kbb+1
	lda kcrh,y
	adc #0
	sta kbb+2
	stz kbb
	stz kbn
.band:	lda kbn
	lsr a
	sta t1
	cla
	ror a
	clc
	adc kixl
	tax
	lda t1
	adc kixh
	ora #$80
	sta .n0+2
	sta .n1+2
	sta .n2+2
	sta .n3+2
	sta .n4+2
	sta .n5+2
	sta .n6+2
	sta .n7+2
	sta .n8+2
	sta .n9+2
	sta .n10+2
	sta .n11+2
	sta .n12+2
	sta .n13+2
	sta .n14+2
	sta .n15+2
	lda kbn
	.if FOLD
	asl a
	.endif
	clc
	adc #$90
	sta .q0+2
	sta .q1+2
	sta .q2+2
	sta .q3+2
	sta .q4+2
	sta .q5+2
	sta .q6+2
	sta .q7+2
	.if FOLD
	inc a
	.endif
	sta .q8+2
	sta .q9+2
	sta .q10+2
	sta .q11+2
	sta .q12+2
	sta .q13+2
	sta .q14+2
	sta .q15+2
	lda kbb                 ; cum[1..n] of this band at the cum page + 32 b
	sta $1A02
	clc
	adc #32
	sta kbb
	lda kbb+1
	sta $1A03
	lda kbb+2
	sta $1A04
	stz kml+1
	stz kml+2
	stz kml+3
	stz kml+4
	stz kmh+1
	stz kmh+2
	stz kmh+3
	stz kmh+4
	.if FOLD
	stz kml+5
	stz kmh+5
	.endif
.n0:	ldy $8000+0,x
.q0:	lda $9000+0,y
	tay
	lda kml,y
	ora #$01
	sta kml,y
.n1:	ldy $8000+2,x
.q1:	lda $9000+KQ*1,y
	tay
	lda kml,y
	ora #$02
	sta kml,y
.n2:	ldy $8000+4,x
.q2:	lda $9000+KQ*2,y
	tay
	lda kml,y
	ora #$04
	sta kml,y
.n3:	ldy $8000+6,x
.q3:	lda $9000+KQ*3,y
	tay
	lda kml,y
	ora #$08
	sta kml,y
.n4:	ldy $8000+8,x
.q4:	lda $9000+KQ*4,y
	tay
	lda kml,y
	ora #$10
	sta kml,y
.n5:	ldy $8000+10,x
.q5:	lda $9000+KQ*5,y
	tay
	lda kml,y
	ora #$20
	sta kml,y
.n6:	ldy $8000+12,x
.q6:	lda $9000+KQ*6,y
	tay
	lda kml,y
	ora #$40
	sta kml,y
.n7:	ldy $8000+14,x
.q7:	lda $9000+KQ*7,y
	tay
	lda kml,y
	ora #$80
	sta kml,y
.n8:	ldy $8000+16,x
.q8:	lda $9000+KQH+KQ*0,y
	tay
	lda kmh,y
	ora #$01
	sta kmh,y
.n9:	ldy $8000+18,x
.q9:	lda $9000+KQH+KQ*1,y
	tay
	lda kmh,y
	ora #$02
	sta kmh,y
.n10:	ldy $8000+20,x
.q10:	lda $9000+KQH+KQ*2,y
	tay
	lda kmh,y
	ora #$04
	sta kmh,y
.n11:	ldy $8000+22,x
.q11:	lda $9000+KQH+KQ*3,y
	tay
	lda kmh,y
	ora #$08
	sta kmh,y
.n12:	ldy $8000+24,x
.q12:	lda $9000+KQH+KQ*4,y
	tay
	lda kmh,y
	ora #$10
	sta kmh,y
.n13:	ldy $8000+26,x
.q13:	lda $9000+KQH+KQ*5,y
	tay
	lda kmh,y
	ora #$20
	sta kmh,y
.n14:	ldy $8000+28,x
.q14:	lda $9000+KQH+KQ*6,y
	tay
	lda kmh,y
	ora #$40
	sta kmh,y
.n15:	ldy $8000+30,x
.q15:	lda $9000+KQH+KQ*7,y
	tay
	lda kmh,y
	ora #$80
	sta kmh,y
	stz kcum+1             ; (cum low byte in Y)
	cly
	stz kc0
	ldx kml+1
	beq .e0
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l0:	tya
	ora klsb,x
	tay
	sta $1A00
	lda kcum+1
	sta $1A00
	lda kclr,x
	tax
	bne .l0
.e0:
	ldx kmh+1
	beq .e1
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l1:	lda kcum+1
	ora klsb,x
	sta kcum+1
	sty $1A00
	sta $1A00
	lda kclr,x
	tax
	bne .l1
.e1:
	.if FOLD
	.else
	ldx kbn
	lda kc0
	sta kb1,x
	.endif
	ldx kml+2
	beq .e2
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l2:	tya
	ora klsb,x
	tay
	sta $1A00
	lda kcum+1
	sta $1A00
	lda kclr,x
	tax
	bne .l2
.e2:
	ldx kmh+2
	beq .e3
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l3:	lda kcum+1
	ora klsb,x
	sta kcum+1
	sty $1A00
	sta $1A00
	lda kclr,x
	tax
	bne .l3
.e3:
	.if FOLD
	.else
	ldx kbn
	lda kc0
	sta kb2,x
	.endif
	ldx kml+3
	beq .e4
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l4:	tya
	ora klsb,x
	tay
	sta $1A00
	lda kcum+1
	sta $1A00
	lda kclr,x
	tax
	bne .l4
.e4:
	ldx kmh+3
	beq .e5
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l5:	lda kcum+1
	ora klsb,x
	sta kcum+1
	sty $1A00
	sta $1A00
	lda kclr,x
	tax
	bne .l5
.e5:
	.if FOLD
	.else
	ldx kbn
	lda kc0
	sta kb3,x
	.endif
	ldx kml+4
	beq .e6
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l6:	tya
	ora klsb,x
	tay
	sta $1A00
	lda kcum+1
	sta $1A00
	lda kclr,x
	tax
	bne .l6
.e6:
	ldx kmh+4
	beq .e7
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l7:	lda kcum+1
	ora klsb,x
	sta kcum+1
	sty $1A00
	sta $1A00
	lda kclr,x
	tax
	bne .l7
.e7:
	.if FOLD
	ldx kbn                 ; (kb3: the blocks before the staircase blocks in the order: kleave's forced test; kb1 / kb2 are not written:
	lda kc0                 ;  nothing reads them, and their two stores pay for the fifth key's two tests in the dark)
	sta kb3,x
	ldx kml+5
	beq .e8
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l8:	tya
	ora klsb,x
	tay
	sta $1A00
	lda kcum+1
	sta $1A00
	lda kclr,x
	tax
	bne .l8
.e8:
	ldx kmh+5
	beq .e9
	lda kc0
	clc
	adc kpop,x
	sta kc0
.l9:	lda kcum+1
	ora klsb,x
	sta kcum+1
	sty $1A00
	sta $1A00
	lda kclr,x
	tax
	bne .l9
.e9:
	.endif
	sty kcum
	ldx kbn
	lda kc0
	sta kn,x
	lda kcum
	sta kvl,x
	sta kkp,x
	lda kcum+1
	sta kvh,x
	sta kkp+8,x
	inc kbn
	lda kbn
	cmp #8
	beq .bx
	jmp .band
.bx:	jsr ktr0                ; the visible blocks' group masks
	jsr ktr1
	tii gm, kgv, 16
	lda kcb                 ; the header
	sta $1A02
	lda kcb+1
	sta $1A03
	lda kcb+2
	sta $1A04
	.if FOLD
	tia kh, $1A00, 24       ; (the header's 48 bytes in two moves of 24: 161 cycles each with the interrupts held, under the 200 below
	tia kh + 24, $1A00, 24  ;  and what kcellh's two moves hold in play; four moves' set-up less a cell: the fifth key's frame in the dark)
	.else
	tia kh, $1A00, 8
	tia kh + 8, $1A00, 8
	tia kh + 16, $1A00, 8
	tia kh + 24, $1A00, 8
	tia kh + 32, $1A00, 8
	tia kh + 40, $1A00, 8
	tia kh + 48, $1A00, 8
	tia kh + 56, $1A00, 8
	.endif
	inc kcx
	lda kcx
	cmp #33
	beq .cn
	jmp .cx
.cn:	inc kcy
	lda kcy
	cmp #50
	beq .ky
	jmp .cy
.ky:
	stz $1A02               ; the key, last
	stz $1A03
	lda #3
	sta $1A04
	tia kmte, $1A00, 7
	inc nbuild
	.endif
.end:	lda FRAMES
	sta kbf1
	pla
	tam #4
	rts
	.if WAL = 0
kfl:	clc                     ; t1:t0 += A; t3:t2 += t1:t0
	adc t0
	sta t0
	lda t1
	adc #0
	sta t1
	lda t0
	clc
	adc t2
	sta t2
	lda t1
	adc t3
	sta t3
	rts
	.endif
tedge:
.a:	lda SPLITN
	sta tsp
	lda FRAMES
	sta tfr
	lda TIMER
	sta tc
	clx
.l:	inx
	beq .dead
	lda TIMER
	cmp tc
	beq .l
	txa
	clc
	adc tw
	sta tw
	lda SPLITN
	cmp tsp
	bne .a
	lda FRAMES
	cmp tfr
	bne .a
	lda TIMER
	and #$7F
	rts
.dead:	lda #$80                ; (not 2: LDA #2 / STA abs is also the start of the colour-cycle site's bytes; the sector scan wants no such run)
	sta tvb
	rts
tsa:	phx
	lda IRQMASK
	sta tmsk
	ora #$04
	sta IRQMASK
	stz tw
	jsr tedge
tsad:	sta tca
	lda tw
	clc
	adc tturn
	sta tturn
	plx
	rts
tsb:	phx
	lda tsp
	pha
	lda tfr
	pha
	jsr tedge
tsbd:	sta tcb
	lda tca
	sec
	sbc tcb
	bcs .p
	adc #116
.p:	sta tnl
	clc
	adc tticks
	sta tticks
	pla
	cmp tfr
	beq .s
	pla
	lda #1
	sta tvb
	bra .x
.s:	pla
	bne .s1
	lda tsp
	beq .x
	inc tk24
	bra .s2
.s1:	cmp #2
	bcs .x
.s2:	lda tsp
	cmp #2
	bcc .x
	inc tk152
.x:	lda tmsk
	and #$04
	bne .x2
	lda IRQMASK
	and #$03
	sta IRQMASK
.x2:	plx
	rts
tpad:	lda tvb
	bne .no
	lda tticks
	cmp #64
	bcs .no
	asl a
	asl a
	sta pt
	lda tcl2                ; (bank 3's, mapped here: the target with the zero fill, kfill)
	sta pu
	lda tch2
	sec
	sbc pt
	bcc .no
	sta tdh
	lda tturn               ; less 18 a turn of the waits for A (16 + 2)
	stz pt
	ldx #4
.m:	asl a
	rol pt
	dex
	bne .m
	jsr .sb
	bcc .no
	lda tturn
	stz pt
	asl a
	rol pt
	jsr .sb
	bcc .no
	lda tk24
	beq .z1
	lda #<K24
	ldx #>K24
	bra .k1
.z1:	cla
	clx
	nop
.k1:	jsr .ad
	lda tk152
	beq .z2
	lda #<K152
	ldx #>K152
	bra .k3
.z2:	cla
	clx
	nop
.k3:	jsr .ad
	inc tnp
	.if PADON
	ldx tdl
	ldy tdh
	lda #14
	jsr cold
	.endif
	rts
.no:	stz tdl
	stz tdh
	inc tnn
	rts
.sb:	eor #$FF                ; tdl / tdh -= A / pt (carry clear: below zero)
	sec
	adc pu
	sta pu
	sta tdl
	lda tdh
	sbc pt
	sta tdh
	rts
.ad:	clc
	adc tdl
	sta tdl
	txa
	adc tdh
	sta tdh
	rts
pu:	.db 0
pt:	.db 0
	.if REPHASE
rphd:	tax
	beq .x
	cly
	cla
.m:	pha
	txa
	and #3
	eor #3
	cmp #3                  ; (carry: one frame in four, the quarter)
	tya
	adc #220
	tay
	pla
	adc #0
	cmp #116
	bcc .n
	sbc #116
.n:	dex
	bne .m
	cpy #128                ; rounded
	adc #0
	cmp #116
	bcc .x
	cla
.x:	rts
	.endif
	.if FOLD
tmcw:	clc
	adc tql
	sta t0
	lda tqh
	and #$0F
	adc #0
	sta t1
	lda t0
	and #7
	tax
	lda tmbit,x
	sta t2
	lsr t1
	ror t0
	lsr t1
	ror t0
	lsr t1
	ror t0
	ldy t0
	lda t1
	ora #$80
	cmp tcpg
	beq .go
	sta tcpg
	sta .b0+2
	sta .b1+2
	sta .b2+2
	sta .b3+2
	sta .b4+2
	sta .b5+2
	sta .b6+2
	sta .b7+2
	sta .b8+2
	sta .b9+2
	sta .b10+2
	sta .b11+2
	sta .b12+2
	sta .b13+2
	sta .b14+2
	sta .b15+2
	sta .b16+2
.go:	clx
.b0:	lda $8000+0,y
	and t2
	beq .n0
	inx
.n0:
.b1:	lda $8000+8,y
	and t2
	beq .n1
	inx
.n1:
.b2:	lda $8000+16,y
	and t2
	beq .n2
	inx
.n2:
.b3:	lda $8000+24,y
	and t2
	beq .n3
	inx
.n3:
.b4:	lda $8000+32,y
	and t2
	beq .n4
	inx
.n4:
.b5:	lda $8000+40,y
	and t2
	beq .n5
	inx
.n5:
.b6:	lda $8000+48,y
	and t2
	beq .n6
	inx
.n6:
.b7:	lda $8000+56,y
	and t2
	beq .n7
	inx
.n7:
.b8:	lda $8000+64,y
	and t2
	beq .n8
	inx
.n8:
.b9:	lda $8000+72,y
	and t2
	beq .n9
	inx
.n9:
.b10:	lda $8000+80,y
	and t2
	beq .n10
	inx
.n10:
.b11:	lda $8000+88,y
	and t2
	beq .n11
	inx
.n11:
.b12:	lda $8000+96,y
	and t2
	beq .n12
	inx
.n12:
.b13:	lda $8000+104,y
	and t2
	beq .n13
	inx
.n13:
.b14:	lda $8000+112,y
	and t2
	beq .n14
	inx
.n14:
.b15:	lda $8000+120,y
	and t2
	beq .n15
	inx
.n15:
.b16:	lda $8000+128,y
	and t2
	beq .n16
	inx
.n16:
	txa
	rts
	.if TMCHK
tmchk:	lda tm                  ; (the test: the stepped count against the whole one)
	sta tmc
	lda tm+1
	sta tmc+1
	lda #11
	jsr cold
	inc tmck
	bne .c
	inc tmck+1
.c:	lda tm
	cmp tmc
	bne .b
	lda tm+1
	cmp tmc+1
	beq .x
.b:	inc tmbad
.x:	rts
tmc:	.dw 0
tmck:	.dw 0
tmbad:	.db 0
	.endif
tcpg:	.db 0           ; the page the 17 reads are set to
tql:	.db 0           ; the window tmupd is stepping from / to (its first cell's pointer)
tqh:	.db 0
	.else
tmupd:	lda p0h
	cmp tph
	bne .f
	lda p0l
	sec
	sbc tpl
	bne .s
	rts                     ; (the same cell)
.s:	cmp #1
	beq .r
	cmp #$FF
	bne .f
	lda #0                  ; one column left: window column 0 in, the old window's column 32 (this window's 33) out
	jsr tmcol
	jsr .add
	lda #33
	jsr tmcol
	jsr .sub
	bra .k
.r:	dec p0l                 ; one column right: column 32 in, the old window's column 0 out (from the old pointer: columns 33 and 0)
	lda #33
	jsr tmcol
	jsr .add
	lda #0
	jsr tmcol
	jsr .sub
	inc p0l
.k:	lda p0l
	sta tpl
	jmp tmk
.f:	lda p0l
	sta tpl
	lda p0h
	sta tph
	lda #11
	jmp cold                ; (tmid: ends in tmk)
.add:	clc
	adc tm
	sta tm
	bcc .x
	inc tm+1
.x:	rts
.sub:	sta t0
	lda tm
	sec
	sbc t0
	sta tm
	bcs .x
	dec tm+1
	rts
; A = the window column (0 .. 33): the mid cells of its 17 rows -> A
tmcol:	clc
	adc p0l
	sta t0
	lda p0h
	and #$0F
	adc #0
	sta t1
	lda t0
	and #7
	tax
	lda tmbit,x
	sta t2
	lsr t1
	ror t0
	lsr t1
	ror t0
	lsr t1
	ror t0
	lda t0
	sta .b+1
	lda t1
	ora #$80
	sta .b+2
	tma #4
	pha
	lda #DB_CLS
	tam #4
	clx
	cly
.l:
.b:	lda $8000,y
	and t2
	beq .n
	inx
.n:	tya
	clc
	adc #8                  ; (the next row: 64 cells on)
	tay
	cpy #136
	bne .l
	pla
	tam #4
	txa
	rts
	.endif
tmbit:	.db $80, $40, $20, $10, $08, $04, $02, $01
; tcl / tch = PADK + 17 tm (tm <= 561)
tmk:	lda tm
	sta tcl
	lda tm+1
	sta tch
	ldx #4
.m:	asl tcl
	rol tch
	dex
	bne .m
	lda tcl
	clc
	adc tm
	sta tcl
	lda tch
	adc tm+1
	sta tch
	lda tcl
	clc
	adc #<PADK
	sta tcl
	lda tch
	adc #>PADK
	sta tch
	rts
tm:	.dw 0           ; the window's mid cells
; the pad's state. tlog on: read by the measuring tools (one pass a frame at most)
tlog:
tturn:	.db 0           ; this pass: turns of the waits for A (18 cycles each)
tticks:	.db 0
tk24:	.db 0
tk152:	.db 0
tvb:	.db 0
tdl:	.db 0
tdh:	.db 0
tnl:	.db 0
tnp:	.db 0
tnn:	.db 0
tca:	.db 0
tcb:	.db 0
tcl:	.db 0
tch:	.db 0
tpl:	.db $FF
tph:	.db $FF
tw:	.db 0
tc:	.db 0
tsp:	.db 0
tfr:	.db 0
tmsk:	.db 0

	.include "shaft19_kbtab.inc"
kpop       = mid
klsb       = mid + 256
kclr       = bsav
kgen:	clx
.l:	txa
	cly
.p:	lsr a
	bcc .q
	iny
.q:	bne .p
	tya
	sta kpop,x
	stx t0
	txa
	eor #$FF
	inc a
	and t0
	sta klsb,x
	txa
	dec a
	and t0
	sta kclr,x
	inx
	bne .l
	rts

smbuild:	tma #3
	pha
	tma #4
	pha
	tma #6
	pha
	lda wbank
	tam #6
	lda #DB_T
	tam #4
	clx                     ; the word of each byte value
.t:	txa
	and #$7F
	tay
	lda prop,y
	bmi .tb
.tw:	tya
	clc
	adc nlo
	sta DBT_O,x
	lda nhs
	adc #0
	sta DBT_O + $100,x
	bra .tn
.tb:
	.if FOLDW
	tya                     ; (a staircase cell: the map's tile word; the hole, code 0: the transparent word)
	bne .tw
	.endif
	lda #$C5
	sta DBT_O,x
	stz DBT_O + $100,x
.tn:	inx
	bne .t
	lda #DB_C0              ; the row code: banks 0 and 1 32 pages (2,048 words) each, bank 2 four pages
	tam #3
	cla
	ldx #$C0
	ldy #32
	jsr .bld
	lda #DB_C1
	tam #3
	cla
	ldx #$C8
	ldy #32
	jsr .bld
	lda #DB_C2
	tam #3
	cla
	ldx #$D0
	ldy #4
	jsr .bld
	ldx nrm                 ; the remap cells: k = offset: the ST1 operand of word k = the clone word's low byte (ST2's 0)
	beq .x
.r:	dex
	lda rml,x
	sta t0
	lda rmh,x
	sta t1
	lsr a
	lsr a
	lsr a
	tay
	lda cbank,y
	tam #3
	lda t0
	asl a
	asl a
	ora #1
	sta .w1+1
	ora #3
	sta .w2+1               ; (the ST2 operand: two bytes on)
	lda t1
	and #7
	asl a
	asl a
	sta t2
	lda t0
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	ora t2
	ora #$60
	sta .w1+2
	sta .w2+2
	lda rmw,x
.w1:	sta $6001
	cla
.w2:	sta $6003
	cpx #0
	bne .r
.x:	pla
	tam #6
	pla
	tam #4
	pla
	tam #3
	.if FOLD
	.if REPHASE
	lda #11                 ; (bank 4) kscr, called from here when REPHASE takes the cold bank's last bytes
	jmp cold4
	.endif
	.endif
	rts
.bld:	sta .s+1
	stx .s+2
	sty t0
	lda #$60
	sta .d0+2
	sta .d1+2
	sta .d2+2
	sta .d3+2
.p:	clx
	cly
.l:
.s:	lda $C002,x
	sta .a+1
	sta .h+1
	lda #$13                ; ST1 #
.d0:	sta $6000,y
	iny
.a:	lda DBT_O
.d1:	sta $6000,y
	iny
	lda #$23                ; ST2 #
.d2:	sta $6000,y
	iny
.h:	lda DBT_O + $100
.d3:	sta $6000,y
	inx
	iny
	bne .l
	lda .s+1
	clc
	adc #64
	sta .s+1
	bcc .q
	inc .s+2
.q:	inc .d0+2
	inc .d1+2
	inc .d2+2
	inc .d3+2
	dec t0
	bne .p
	rts
cbank:	.db DB_C0, DB_C1, DB_C2, DB_C2

sclz_skip:
	.db $00, $07, $06, $06, $05, $05, $05, $05, $04, $04, $04, $04, $04, $04, $04, $04
	.db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
	.db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
	.db $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
	.db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	.db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	.db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	.db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
sclz_rem:
	.db $00, $00, $00, $80, $00, $40, $80, $C0, $00, $20, $40, $60, $80, $A0, $C0, $E0
	.db $00, $10, $20, $30, $40, $50, $60, $70, $80, $90, $A0, $B0, $C0, $D0, $E0, $F0
	.db $00, $08, $10, $18, $20, $28, $30, $38, $40, $48, $50, $58, $60, $68, $70, $78
	.db $80, $88, $90, $98, $A0, $A8, $B0, $B8, $C0, $C8, $D0, $D8, $E0, $E8, $F0, $F8
	.db $00, $04, $08, $0C, $10, $14, $18, $1C, $20, $24, $28, $2C, $30, $34, $38, $3C
	.db $40, $44, $48, $4C, $50, $54, $58, $5C, $60, $64, $68, $6C, $70, $74, $78, $7C
	.db $80, $84, $88, $8C, $90, $94, $98, $9C, $A0, $A4, $A8, $AC, $B0, $B4, $B8, $BC
	.db $C0, $C4, $C8, $CC, $D0, $D4, $D8, $DC, $E0, $E4, $E8, $EC, $F0, $F4, $F8, $FC

SZ_SDY     = $D3
SZ_SR      = $D9
SZ_S5R     = $DA
SZ_SBU     = $DB
SZ_SNM     = $DC
SZ_SNB     = $DD

sfastc_cb0:
	stz <SZ_SR
	stz <SZ_S5R
.r:	ldy <SZ_SR
	lda SRM,y
	bne .rg
	jmp .nr
.rg:	sta <SZ_SBU
	stz <SZ_SNM
	ldx <SZ_S5R
	lda #1
	sta <SZ_SNB
	tya
	lsr a
	bcs .od
	ldy <SZ_SDY
	bne .ev
.e0:	lsr <SZ_SBU
	bcc .n0
	lda SFM+5,x
	and SCC,x
	sta SPB,x
	beq .nz0
	lda <SZ_SNB
	tsb <SZ_SNM
.nz0:	lda <SZ_SBU
	beq .w
.n0:	inx
	asl <SZ_SNB
	bra .e0
.ev:	lsr <SZ_SBU
	bcc .n1
	lda SFM+5,x
	ora SFM-5,x
	and SCC,x
	sta SPB,x
	beq .nz1
	lda <SZ_SNB
	tsb <SZ_SNM
.nz1:	lda <SZ_SBU
	beq .w
.n1:	inx
	asl <SZ_SNB
	bra .ev
.od:	lsr <SZ_SBU
	bcc .n2
	lda SFM,x
	and SCC,x
	sta SPB,x
	beq .nz2
	lda <SZ_SNB
	tsb <SZ_SNM
.nz2:	lda <SZ_SBU
	beq .w
.n2:	inx
	asl <SZ_SNB
	bra .od
.w:	ldy <SZ_SR
	lda <SZ_SNM
	sta SRM,y
.nr:	lda <SZ_S5R
	clc
	adc #5
	sta <SZ_S5R
	inc <SZ_SR
	lda <SZ_SR
	cmp #17
	beq .rx
	jmp .r
.rx:	rts

SZ_T0      = $C2
SZ_T1      = $C3
SZ_T2      = $C4
SZ_T3      = $C5
SZ_SNU     = $C7
SZ_SOBI    = $CC
SZ_SSTMP   = $CD
SZ_MAPT    = $D240
SZ_MAPS    = $D000

sclrt_cb0:
	clx
.z:	stz SZ_MAPT,x
	stz SZ_MAPT + $100,x
	stz SZ_MAPT + $140,x
	inx
	bne .z
	rts

sedge_es_cb0:
	lda <SZ_SOBI
	asl a
	ldx <SZ_T1
	beq .e0
	inc a
.e0:	sta <SZ_T2
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc <SZ_T0
	tax
	lda (ERS + DXO),x
	sta <SZ_T3
	lda <SZ_T2
	asl a
	asl a
	asl a
	asl a
	clc
	adc <SZ_T2
	adc <SZ_T2
	sec
	adc <SZ_T3
	tax
	ldy (EWH + DXO),x
	lda (EWL + DXO),x
	sta <SZ_T3
	rts

scache_clr_cb0:
	clx
	lda #$FF
.l:	sta SLOT_IDH + DXO,x
	stz SU0 + DXO,x
	stz SU1 + DXO,x
	inx
	cpx #NPOOL
	bne .l
	stz SU0 + DXO + NPOOL
	stz SU1 + DXO + NPOOL
	rts

sclru0_cb0:
	ldx #NPOOL
.l:	stz SU0 + DXO - 1,x
	dex
	bne .l
	rts

sclru1_cb0:
	ldx #NPOOL
.l:	stz SU1 + DXO - 1,x
	dex
	bne .l
	rts

shold_cache_cb0:
	lda <SZ_SNU
	beq .nph
	jsr sclrt_cb0
	ldx #NPOOL
	lda #$FF
.ih:	sta SLOT_IDH + DXO - 1,x
	dex
	bne .ih
	sta scph_c
.nph:	rts

sadv_tok_cb0:
	lda <SZ_SOBI
	beq .t0
	inc sutok1
	bne .k1
	jsr sclru1_cb0
	inc sutok1
.k1:	lda sutok1
	sta spw_suhl+1
	sta spw_sunl+1
	lda sutok0
	sta spw_othc+1
	lda #<(SU0 + DXO)
	sta spw_othl+1
	lda #>(SU0 + DXO)
	sta spw_othl+2
	lda #<(SU1 + DXO)
	sta spw_suhs+1
	sta spw_suns+1
	bra .ke
.t0:	inc sutok0
	bne .k0
	jsr sclru0_cb0
	inc sutok0
.k0:	lda sutok0
	sta spw_suhl+1
	sta spw_sunl+1
	lda sutok1
	sta spw_othc+1
	lda #<(SU1 + DXO)
	sta spw_othl+1
	lda #>(SU1 + DXO)
	sta spw_othl+2
	lda #<(SU0 + DXO)
	sta spw_suhs+1
	sta spw_suns+1
	lda #>(SU0 + DXO)
	bra .k0h
.k1h:
.ke:	lda #>(SU1 + DXO)
.k0h:	sta spw_suhs+2
	sta spw_suns+2
	rts

	.bank 2
	.org $C000

	jmp cdetect
	jmp setup               ; 3 the set-up (satbody, interrupts on; carry set: refused, the slots back)
	jmp restore             ; 6 the exit restore (interrupts on, in the dark)

cmagic:	.db $19, $AE
	jmp tmid
	jmp tdly                ; 14 the measured pad's delay
	jmp bcols               ; 17 (shaft19-join-020: reeng) the border columns of both buffers: saved, ours in
	.if XRAILS
	.include "shaft19_xslots.inc"
	.include "shaft19_x2.inc"
	.else
	.include "shaft19_slots.inc"
	.endif

bitw:	.db $01, $02, $04, $08, $10, $20, $40, $80

kunit:	tma #4
	pha
	lda #DB_K
	tam #4
	lda #<kunt
	sta .t+1
	lda #>kunt
	sta .t+2
	stz .t+3
	lda #$80
	sta .t+4
	ldx #9                  ; pages
.p:	ldy #32                 ; moves of 8 a page
.t:	tii kunt, $8000, 8
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
.m:	dey
	bne .t
	dex
	bne .p
	pla
	tam #4
	rts
	.include "shaft19_kunits.inc"

kbemit:	tma #4
	pha
	lda #DB_K
	tam #4
	stz t8                  ; g
.g:	stz $1A02
	lda t8
	and #7
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $1A03
	lda t8
	lsr a
	lsr a
	lsr a
	clc
	adc #$0C
	sta $1A04
	lda t8
	clc
	adc #KGPAGE
	sta .t+2
	lda #16
	ldx t8
	cpx #2
	bcc .n
	cla                     ; (256 masks)
.n:	sta t7
	stz t6                  ; m
.m:	ldx t6
	lda ktlo,x
	sta .p+1
	lda kthi,x
	sta .p+2
	lda ktcn2,x
	beq .e
	sta t5
	cly
.p:	lda $FFFF,y
	sta .t+1
.t:	tia $8000, $1A00, 8
	iny
	dec t5
	bne .p
.e:	inc t6
	lda t6
	cmp t7
	bne .m
	inc t8
	lda t8
	cmp #17
	bne .g
	pla
	tam #4
	rts
	.include "shaft19_kemit.inc"

cdetect:	lda $1AFF
	cmp #$51
	bne .no
	lda #$5A
	sta $1A02
	lda $1A02
	cmp #$5A
	bne .no
	lda #$A5
	sta $1A02
	lda $1A02
	cmp #$A5
	bne .no
	jsr pinit
	clc
	rts
.no:	sec
	rts
pinit:	lda #1                  ; port 0: increment 1, the base advances at every data access, no offset
	sta $1A07
	stz $1A08
	stz $1A05
	stz $1A06
	lda #$11
	sta $1A09
	rts
cbi:	sta $1A04
	lda cil                 ; byte 0: (i << 5) & $FF
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $1A02
	lda cih                 ; byte 1: (i >> 3) & $FF (i < 2048: no carry into byte 2)
	asl a
	asl a
	asl a
	asl a
	asl a
	sta t0
	lda cil
	lsr a
	lsr a
	lsr a
	ora t0
	sta $1A03
	rts
cil:	.db 0
cih:	.db 0
; MARR / MAWR = tile (tl, th) * 16
ttaddr:	lda tl
	asl a
	sta t0
	lda th
	rol a
	asl t0
	rol a
	asl t0
	rol a
	asl t0
	rol a
	tax
	lda t0
	rts
tl:	.db 0
th:	.db 0
rdtile:
	jsr ttaddr
	jsr vmarr
	tai $0002, $8000, 8
	tai $0002, $8000 + 8, 8
	tai $0002, $8000 + 16, 8
	tai $0002, $8000 + 24, 8
	rts
wrtile:
	jsr ttaddr
	jsr vmawr
	tia $8000, $0002, 8
	tia $8000 + 8, $0002, 8
	tia $8000 + 16, $0002, 8
	tia $8000 + 24, $0002, 8
	rts
; one tile VRAM -> cbuf
rdbuf:
	jsr ttaddr
	jsr vmarr
	tai $0002, cbuf, 8
	tai $0002, cbuf + 8, 8
	tai $0002, cbuf + 16, 8
	tai $0002, cbuf + 24, 8
	rts
; one tile cbuf -> VRAM
wrbuf:
	jsr ttaddr
	jsr vmawr
	tia cbuf, $0002, 8
	tia cbuf + 8, $0002, 8
	tia cbuf + 16, $0002, 8
	tia cbuf + 24, $0002, 8
	rts
cbuf:	.ds 32
cbuf2:	.ds 32
vtmp:	.ds 32
rinit:	stz rr
	stz rleft
	lda #$FF
	sta cil
	sta cih
	rts
rnext:	inc cil
	bne .i
	inc cih
.i:	lda rleft
	bne .t
	ldx rr
	cpx #NRUN
	bcs .x
	lda runl,x
	sta tl
	lda runh,x
	sta th
	lda runc,x
	sta rleft
	inc rr
	bra .g
.t:	inc tl
	bne .g
	inc th
.g:	dec rleft
	clc
.x:	rts
rr:	.db 0
rleft:	.db 0
bdone:	.db 0

; ---------------------------------------------------------------- the set-up
setup:	lda FRAMES
	sta tset0
	stz fail
	stz bdone
	tma #4
	sta sv4
	lda #$40
	tam #4
	jsr pinit
	; the masks: entries 0-3 of both SAT pages
	lda #0
	ldx #$0E
	jsr vmarr
	tai $0002, msav, 8
	tai $0002, msav + 8, 8
	tai $0002, msav + 16, 8
	tai $0002, msav + 24, 8
	lda #0
	ldx #$0F
	jsr vmarr
	tai $0002, msav + 32, 8
	tai $0002, msav + 32 + 8, 8
	tai $0002, msav + 32 + 16, 8
	tai $0002, msav + 32 + 24, 8
	jsr mchk
	bcc .s1
	lda #4
	jmp sfail
.s1:	lda #0                  ; the third cold bank's entry 0: the side tables to DB_K (ksdcpy; carry clear; cold4 returns no A), or the set-up is refused
	jsr cold4
	bcc .s1a
	lda #7
	jmp sfail
.s1a:
	lda #1
	stz cil
	stz cih
	jsr cbi
	jsr rinit
.sv:	jsr rnext
	bcs .s2
	jsr rdtile
	bra .sv
.s2:	; the screen's backdrop words: SW[r][X] = (v + MIDLO) | ($10 + MIDHI + carry) << 8 (DB_SW at MPR4)
	lda #DB_SW
	tam #4
	jsr mksw
	.if WAL = 0
	.if FOLD
	lda #5                  ; (bank 4) the blocks' tile partitions: the leave-out key
	jsr cold4
	.else
	jsr mkpart              ; (main bank) the blocks' tile partitions: the leave-out key
	.endif
	.endif
	lda #$40
	tam #4
	; 128 backdrop cells
	jsr cells
	.if XRAILS
	jsr xset1
	.else
	; 64 border tiles
	jsr border
	.endif
	bcc .s3
	lda #5
	jmp sfail
.s3:	; the transparent tile and the remap clones
	jsr tclones
	bcc .s4
	lda #6
	jmp sfail
.s4:	jsr buildcls            ; (main bank)
	jsr kunit               ; the entries' unit tables to DB_K
	.if U2L
	lda #6                  ; (the fifth bank) their first six pages by 2-line groups (r19-leftout-order, U)
	jsr c5
	.endif
	.if WAL = 0
	jsr kgen                ; (main bank) kbuild's byte tables
	.endif
	lda #3
	jsr cold3
	.if WAL = 0
	lda kcached
	bne .kc
	jsr kbemit
	.if BANK5
	ldx #CMN - 2
	jsr cmcpx
	bcc .kc
	lda #9
	jmp sfail
	.endif
.kc:
	.endif
	lda #$FF                ; (the rows cache empty)
	sta lp0l
	sta lp0h
	jsr bcols               ; the border columns of both buffers: saved, ours in
	lda #1
	sta bdone
	jsr allocmk
	tii PAL1, PAL4, 8
	tii PAL1 + 8, PAL4 + 8, 8
	tii PAL1 + 16, PAL4 + 16, 8
	tii PAL1 + 24, PAL4 + 24, 8
	jsr vwait               ; (bounded)
	php
	sei
	lda #$10
	sta $0402
	stz $0403
	tai $0404, vtmp, 32
	lda #$40
	sta $0402
	lda #$01
	sta $0403
	tia vtmp, $0404, 32
	plp
	jsr smbuild
	.if FOLD
	.if REPHASE
	.else
	lda #11                 ; (bank 4) the pass's scratch in DB_NEAR: the S word of each byte value, the fold's map zero, KYOK
	jsr cold4
	.endif
	.endif
	lda #<SFSITE
	ldy #>SFSITE
	ldx #2
	jsr fsum
	lda t2
	cmp csf
	bne .sf4
	lda t3
	cmp csf+1
	bne .sf4
	jsr patch
	bcc .s5
.sf4:	lda #3
	jmp sfail
.s5:	lda SFSITE
	sta gsf
	lda #$80
	sta SFSITE
	.if XRAILS
	.if HUDS
	lda #23
	jsr cold3
	.else
	lda #20                 ; (bank 4) the composite table, column 36 saved, the object draw's fine-X add removed
	jsr cold4
	.endif
	.if EFIX
	lda #38
	jsr cold4
	.endif
	.endif
	.if ORD
	lda #9
	jsr c5
	.endif
	.if PLG
	lda #14                 ; (bank 3) the plug's streams, pool, state (r19-plug-streams, S)
	jsr cold3
	.endif
	jsr c5init
	lda #1
	sta eng
	sta pend
	stz lit
	lda #64
	sta ourend
	sta ourend+1
	sta ourst
	sta ourst+1
	inc nsetup
	lda FRAMES
	sta tset1
	.if REPHASE
	sec
	sbc tset0
	jsr rph
	.endif
	lda sv4
	tam #4
	clc
	rts
sfail:	sta fail
	lda #1                  ; the slots back (what we wrote: compared)
	sta pend
	jsr restore
	lda bdone
	beq .b
	jsr bcrest
.b:	lda sv4
	tam #4
	sec
	rts

mchk:	ldx #31
.e:	lda msav,x
	cmp msav+32,x
	bne .no
	dex
	bpl .e
	stz t2                  ; the four (side, half) seen
	ldx #0
.m:	txa
	asl a
	asl a
	asl a
	tay
	lda msav+6,y
	and #$0F
	cmp #$0F
	bne .no
	lda msav+7,y            ; cgx 0, cgy 3
	and #$31
	cmp #$30
	bne .no
	lda msav+4,y            ; pattern bits 1-2 (word bits 2-3) clear
	and #$0C
	bne .no
	lda msav+1,y            ; y: 88 (upper) / 152 (lower)
	bne .no
	lda msav,y
	cmp #88
	beq .u
	cmp #152
	bne .no
	lda #1
	bra .h
.u:	cla
.h:	sta mhalf,x
	lda msav+3,y            ; x: 32 (left) / 304 (right)
	beq .l
	cmp #1
	bne .no
	lda msav+2,y
	cmp #48                 ; (304 = $130)
	bne .no
	lda #1
	bra .sd
.l:	lda msav+2,y
	cmp #32
	bne .no
	cla
.sd:	sta mside,x
	asl a
	ora mhalf,x
	tay
	lda bitw,y
	tsb t2
	inx
	cpx #4
	bne .m
	lda t2
	cmp #$0F
	bne .no
	clc
	rts
.no:	sec
	rts

mksw:	lda #<mid
	sta .m+1
	lda #>mid
	sta .m+2
	stz putw+1
	lda #$80
	sta putw+2
.l:
.m:	lda mid
	clc
	adc OP_MIDLO
	jsr put
	lda #$10
	adc OP_MIDHI
	jsr put
	inc .m+1
	bne .m1
	inc .m+2
.m1:	lda putw+2
	cmp #$84
	bne .l
	rts
put:
putw:	sta $8000               ; (INC keeps the carry)
	inc putw+1
	bne .x
	inc putw+2
.x:	rts

cells:	stz cbrow
.bj:	stz cbcol
.bi:	lda #DB_SW
	tam #4
	ldx #0                  ; the four tiles TL, TR, BL, BR from VRAM into tb
.t:	stx t9
	lda cbrow
	asl a
	clc
	adc tro,x               ; row 2 bj + (0, 0, 1, 1)
	sta t6
	lda cbcol
	asl a
	clc
	adc tco,x               ; column 2 bi + (0, 1, 0, 1)
	asl a
	sta t7                  ; SW offset: row * 64 + 2 X
	lda t6
	stz t8
	lsr a
	ror t8
	lsr a
	ror t8
	clc
	adc #$80
	sta .r+2
	sta .r2+2
	lda t8
	ora t7
	sta .r+1
	inc a
	sta .r2+1
.r:	lda $8000
	sta tl
.r2:	lda $8001
	and #$07
	sta th
	jsr rdbuf
	lda t9
	asl a
	asl a
	asl a
	asl a
	asl a
	tay
	ldx #0
.c:	lda cbuf,x
	sta tb,y
	iny
	inx
	cpx #32
	bne .c
	ldx t9
	inx
	cpx #4
	bne .t
	jsr cvcell              ; tb -> sb (the sprite cell, 128 bytes)
	; the cell's slot: group k = 8 (bj >> 2) + (bi >> 1), cell c = 2 (bj & 3) + (bi & 1)
	lda cbrow
	and #3
	asl a
	sta t0
	lda cbcol
	and #1
	ora t0
	sta t1                  ; c
	lda cbrow
	and #4
	asl a
	sta t0
	lda cbcol
	lsr a
	ora t0
	sta t2                  ; k
	bne .gk
	lda t1                  ; group 0: c < 4 at $0D0 + 4 c (i 4 c), else $5F0 + 4 (c - 4) (i 16 + 4 (c - 4))
	cmp #4
	bcs .g0l
	asl a
	asl a
	sta cil
	clc
	adc #$D0
	sta tl
	stz th
	bra .wr
.g0l:	sec
	sbc #4
	asl a
	asl a
	sta t0
	clc
	adc #16
	sta cil
	lda t0
	clc
	adc #$F0
	sta tl
	lda #5
	sta th
	bra .wr
.gk:	lda t2                  ; groups 1-15: $620 + 32 (k - 1) + 4 c; i = 32 + 32 (k - 1) + 4 c = 32 k + 4 c
	stz th
	asl a
	asl a
	asl a
	asl a
	asl a
	rol th
	sta t0
	lda t1
	asl a
	asl a
	clc
	adc t0
	sta cil
	lda th
	adc #0
	sta cih
	lda cil                 ; tile = $600 + 32 k + 4 c
	sta tl
	lda cih
	clc
	adc #6
	sta th
	bra .wr2
.wr:	stz cih
.wr2:	lda #$40
	tam #4
	lda #2
	jsr cbi
	tii sb, $8000, 8
	tii sb + 8, $8000 + 8, 8
	tii sb + 16, $8000 + 16, 8
	tii sb + 24, $8000 + 24, 8
	tii sb + 32, $8000 + 32, 8
	tii sb + 40, $8000 + 40, 8
	tii sb + 48, $8000 + 48, 8
	tii sb + 56, $8000 + 56, 8
	tii sb + 64, $8000 + 64, 8
	tii sb + 72, $8000 + 72, 8
	tii sb + 80, $8000 + 80, 8
	tii sb + 88, $8000 + 88, 8
	tii sb + 96, $8000 + 96, 8
	tii sb + 104, $8000 + 104, 8
	tii sb + 112, $8000 + 112, 8
	tii sb + 120, $8000 + 120, 8
	jsr ttaddr
	jsr vmawr
	tia sb, $0002, 8
	tia sb + 8, $0002, 8
	tia sb + 16, $0002, 8
	tia sb + 24, $0002, 8
	tia sb + 32, $0002, 8
	tia sb + 40, $0002, 8
	tia sb + 48, $0002, 8
	tia sb + 56, $0002, 8
	tia sb + 64, $0002, 8
	tia sb + 72, $0002, 8
	tia sb + 80, $0002, 8
	tia sb + 88, $0002, 8
	tia sb + 96, $0002, 8
	tia sb + 104, $0002, 8
	tia sb + 112, $0002, 8
	tia sb + 120, $0002, 8
	inc cbcol
	lda cbcol
	cmp #16
	beq .nbj
	jmp .bi
.nbj:	inc cbrow
	lda cbrow
	cmp #8
	beq .x
	jmp .bj
.x:	lda #$40
	tam #4
	rts
cbrow:	.db 0
cbcol:	.db 0
tro:	.db 0, 0, 1, 1
tco:	.db 0, 1, 0, 1
tb:	.ds 128                 ; TL, TR, BL, BR (32 bytes each: BG format)
sb:	.ds 128                 ; the sprite cell: plane p row y at word 16 p + y (bytes 32 p + 2 y: low = right 8 px, high = left 8 px)

; tb -> sb. BG tile row r: plane 0 / 1 at bytes 2 r / 2 r + 1, plane 2 / 3 at 16 + 2 r / 17 + 2 r; leftmost pixel = bit 7.
cvcell:	ldy #0                  ; y 0-15
.y:	tya
	and #7
	asl a
	sta t0                  ; 2 (y & 7)
	lda #0                  ; TL / TR (y < 8) or BL / BR
	cpy #8
	bcc .u
	lda #64
.u:	sta t1                  ; left tile's offset in tb; right = + 32
	ldx #0                  ; plane p
.p:	lda poff,x              ; plane offset in a tile: 0, 1, 16, 17
	clc
	adc t0
	clc
	adc t1
	sta t2
	phx
	txa                     ; sb offset 32 p + 2 y
	asl a
	asl a
	asl a
	asl a
	asl a
	sta t3
	tya
	asl a
	clc
	adc t3
	tax
	phy
	ldy t2
	lda tb + 32,y           ; right tile -> low byte
	sta sb,x
	lda tb,y                ; left tile -> high byte
	sta sb+1,x
	ply
	plx
	inx
	cpx #4
	bne .p
	iny
	cpy #16
	bne .y
	rts
poff:	.db 0, 1, 16, 17

	.if XRAILS
	.else
border:	lda msav+4              ; tile 4 P = pattern word * 2 (bit 0 of the word is not the pattern's)
	and #$FE
	sta tl
	lda msav+5
	sta th
	asl tl
	rol th
	stz t9                  ; cell
	lda #<mimg
	sta .d+1
	lda #>mimg
	sta .d+2
.rc:	ldy #4                  ; its 4 tiles
.rt:	phy
	jsr rdbuf
	ldx #0
.cp:	lda cbuf,x
.d:	sta mimg
	inc .d+1
	bne .d0
	inc .d+2
.d0:	inx
	cpx #32
	bne .cp
	inc tl
	bne .t0
	inc th
.t0:	ply
	dey
	bne .rt
	lda tl                  ; the next even cell: 4 tiles on
	clc
	adc #4
	sta tl
	bcc .t1
	inc th
.t1:	inc t9
	lda t9
	cmp #4
	bne .rc
	stz t6                  ; mask m
.m:	lda t6
	asl a
	asl a
	asl a
	tax
	lda msav+7,x
	sta t5                  ; flips: bit 3 x, bit 7 y
	ldx t6
	lda mhalf,x
	asl a
	asl a
	asl a
	sta t4                  ; first screen row (8 half)
	lda mside,x
	asl a
	sta t3                  ; first column index (2 side)
	stz t7                  ; tile row tr
.tr:	stz t8                  ; tile column tc
.tc:	lda t5                  ; off: 1 (the high byte, the left 8 px) when tc = x flip, else 0
	and #8
	beq .f0
	lda #1
.f0:	eor t8
	eor #1
	sta mof
	ldy #0                  ; yy
.yy:	sty myy
	lda t7
	asl a
	asl a
	asl a
	ora myy                 ; Y = 8 tr + yy
	bit t5
	bpl .ny
	eor #63
.ny:	sta t2                  ; source row: cell Y >> 4, row Y & 15: mimg + 128 cell + 2 (Y & 15) + off
	and #15
	asl a
	ora mof
	sta t0
	lda t2
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a                   ; (cell >> 1, carry = cell & 1)
	sta t1
	lda #0
	ror a
	ora t0
	clc
	adc #<mimg
	sta .s+1
	lda t1
	adc #>mimg
	sta .s+2
	ldx #0                  ; plane p: + 32 p
.pl:
.s:	lda mimg
	sta t0
	lda t5
	and #8
	beq .nr
	phx
	ldx #8                  ; reversed (x flip)
.rv:	lsr t0
	rol a
	dex
	bne .rv
	sta t0
	plx
.nr:	phx
	lda myy
	asl a
	clc
	adc cpoff,x
	tax
	lda t0
	sta cbuf,x
	plx
	lda .s+1
	clc
	adc #32
	sta .s+1
	bcc .s0
	inc .s+2
.s0:	inx
	cpx #4
	bne .pl
	ldy myy
	iny
	cpy #8
	beq .j2976
	jmp .yy
.j2976:
	ldy #7                  ; every pixel non-zero: the planes' OR is $FF on every row
.op:	tya
	asl a
	tax
	lda cbuf,x
	ora cbuf+1,x
	ora cbuf+16,x
	ora cbuf+17,x
	cmp #$FF
	beq .ok
	sec
	rts
.ok:	dey
	bpl .op
	lda t4                  ; screen row
	clc
	adc t7
	sta t1
	asl a
	asl a
	clc
	adc t3
	clc
	adc t8
	tax                     ; j
	sta cil
	stz cih                 ; (cih = 2, not LDA #2 / STA abs: see buildcls)
	inc cih
	inc cih
	lda bordl,x
	sta tl
	lda bordh,x
	sta th
	lda t1
	asl a
	asl a
	asl a
	sta t0
	lda t3
	clc
	adc t8
	asl a
	clc
	adc t0
	tay
	lda tl
	sta bword,y
	lda th
	ora #$F0
	sta bword+1,y
	jsr wrbuf
	lda #2
	jsr cbi
	tii cbuf, $8000, 8
	tii cbuf + 8, $8000 + 8, 8
	tii cbuf + 16, $8000 + 16, 8
	tii cbuf + 24, $8000 + 24, 8
	inc t8
	lda t8
	cmp #2
	beq .ntc
	jmp .tc
.ntc:	inc t7
	lda t7
	cmp #8
	beq .ntr
	jmp .tr
.ntr:	inc t6
	lda t6
	cmp #4
	beq .x
	jmp .m
.x:	clc
	rts
mof:	.db 0
myy:	.db 0
cpoff:	.db 0, 1, 16, 17
mimg:	.ds 512
	.endif

tclones:	lda $3C00
	cmp $3C02
	beq .j3056
	jmp .no
.j3056:
	lda $3C01
	cmp $3C03
	beq .j3059
	jmp .no
.j3059:
	ldx #31
.z:	stz cbuf,x
	dex
	bpl .z
	lda #$C5
	sta tl
	stz th
	jsr wrbuf
	lda #$40
	sta cil
	stz cih                 ; (cih = 2, not LDA #2 / STA abs: see buildcls)
	inc cih
	inc cih
	lda #2
	jsr cbi
	tii cbuf, $8000, 8
	tii cbuf + 8, $8000 + 8, 8
	tii cbuf + 16, $8000 + 16, 8
	tii cbuf + 24, $8000 + 24, 8
	stz t6
.c:	ldx t6
	lda rsrc,x
	sta tl
	lda #1
	sta th
	jsr rdbuf
	ldy #7
.r:	tya                     ; row r: z = ~(p0 | p1 | p2 | p3); p0 |= z
	asl a
	tax
	lda cbuf,x
	ora cbuf+1,x
	ora cbuf+16,x
	ora cbuf+17,x
	eor #$FF
	ora cbuf,x
	sta cbuf,x
	dey
	bpl .r
	lda t6
	clc
	adc #$C6
	sta tl
	stz th
	jsr wrbuf
	lda t6
	clc
	adc #$41
	sta cil
	stz cih                 ; (cih = 2, not LDA #2 / STA abs: see buildcls)
	inc cih
	inc cih
	lda #2
	jsr cbi
	tii cbuf, $8000, 8
	tii cbuf + 8, $8000 + 8, 8
	tii cbuf + 16, $8000 + 16, 8
	tii cbuf + 24, $8000 + 24, 8
	inc t6
	lda t6
	cmp #3
	bne .c
	clc
	rts
.no:	sec
	rts
rsrc:	.db $ED, $EE, $F8

; the border columns (0, 1, 34, 35) of both BAT buffers, rows 0-15: saved in bsav, bword in
bcols:	stz t7
.b:	stz t9
.r:	stz t8                  ; column index
.c:	jsr bcell               ; X = bsav / bword offset
	stx t6
	lda t1
	ldx t2
	jsr vbat2
	lda #1                  ; (MARR: vbat2 set MAWR; read through MARR at the same address)
	sta <VDCREG
	st0 #1
	lda t3
	sta $0002
	lda t4
	sta $0003
	lda #2
	sta <VDCREG
	st0 #2
	ldx t6
	lda $0002
	sta bsav,x
	lda $0003
	sta bsav+1,x
	lda t1                  ; and ours
	ldx t2
	jsr vbat2
	ldx t6
	txa
	and #$7F
	tax
	lda bword,x
	sta $0002
	lda bword+1,x
	sta $0003
	inc t8
	lda t8
	cmp #4
	bne .c
	inc t9
	lda t9
	cmp #16
	bne .r
	inc t7
	lda t7
	cmp #2
	bne .b
	rts
; the saved words back (a refused set-up)
bcrest:	stz t7
.b:	stz t9
.r:	stz t8
.c:	jsr bcell
	stx t6
	lda t1
	ldx t2
	jsr vbat2
	ldx t6
	lda bsav,x
	sta $0002
	lda bsav+1,x
	sta $0003
	inc t8
	lda t8
	cmp #4
	bne .c
	inc t9
	lda t9
	cmp #16
	bne .r
	inc t7
	lda t7
	cmp #2
	bne .b
	rts
; buffer t7, row t9, column index t8: t1 BAT row, t2 column; t3 / t4 its MAWR (lo / hi); X = buffer * 128 + row * 8 + 2 index
bcell:	lda t7
	beq .0
	lda #18
.0:	clc
	adc t9
	sta t1
	ldx t8
	lda bcolc,x
	sta t2
	lda t1                  ; MAWR = row * 64 + column
	stz t3
	lsr a
	ror t3
	lsr a
	ror t3
	sta t4
	lda t3
	ora t2
	sta t3
	lda t7
	lsr a
	lda #0
	ror a
	sta t0
	lda t9
	asl a
	asl a
	asl a
	ora t0
	sta t0
	lda t8
	asl a
	ora t0
	tax
	rts
bcolc:	.db 0, 1, 34, 35
; MAWR = BAT row A, column X (the main bank's vbat with interrupts already off)
vbat2:	jmp vbat

; the allocator's bound: m0 = the highest end page of its entries now; alim1 = 1 + the least page >= m0 that holds one of our slots
allocmk:	clx
	stz t0
.l:	lda ALLOCEND,x
	beq .e
	cmp t0
	bcc .n
	sta t0
.n:	inx
	cpx #48
	bne .l
.e:	ldx #0
.p:	lda spages,x
	cmp t0
	bcs .f
	inx
	cpx #NPAGE
	bne .p
	lda #$FF
	sta alim1
	rts
.f:	inc a
	sta alim1
	rts

	.if REPHASE
rph:	jsr rphd
	cmp #0
	beq .x
	cmp #12
	bcs .a
	adc #116
.a:	dec a
	sta TIMER
	lda TIMER
	and #$7F
	sta t0
	clx
	cly
.l:	lda TIMER
	and #$7F
	cmp t0
	beq .c
	bcs .w
	sta t0
.c:	dey
	bne .l
	dex
	bne .l
.w:	lda #115
	sta TIMER
.x:	rts
	.endif
restore:	lda FRAMES
	sta tres0
	tma #4
	pha
	lda #$40
	tam #4
	jsr pinit
	.if XRAILS
	lda #23                 ; (bank 4) the composite slots' last images as "ours"
	jsr cold4
	.endif
	jsr rinit
.l:	jsr rnext
	bcs .d
	.if PLG
	lda cih                 ; (r19-load-exit-slots) a PAT slot (i < 512): by its whole sprite cell (bank 3's xcell: X 1 keep, 2 back)
	cmp #2
	bcs .t
	lda tl
	sta t2
	lda th
	sta t3
	ldx cil
	ldy cih
	lda #20
	jsr cold3
	dex
	beq .k
	bra .w
.t:
	.endif
	jsr rdbuf               ; VRAM -> cbuf
	lda #2                  ; our upload -> cbuf2
	jsr cbi
	tii $8000, cbuf2, 8
	tii $8000 + 8, cbuf2 + 8, 8
	tii $8000 + 16, cbuf2 + 16, 8
	tii $8000 + 24, cbuf2 + 24, 8
	ldx #31
.c:	lda cbuf,x
	cmp cbuf2,x
	bne .k
	dex
	bpl .c
.w:	lda #1                  ; ours still: the saved contents back
	jsr cbi
	jsr wrtile
	inc nback
	bne .l
	inc nback+1
	bra .l
.k:	inc nkeep
	bne .l
	inc nkeep+1
	bra .l
.d:	tii zero8, PAL4, 8      ; the colour buffer's row zero; VCE $140-$14F zero right after a vertical blank
	tii zero8, PAL4 + 8, 8
	tii zero8, PAL4 + 16, 8
	tii zero8, PAL4 + 24, 8
	jsr vwait               ; (bounded)
	php
	sei
	lda #$40
	sta $0402
	lda #$01
	sta $0403
	ldx #32
.vz:	stz $0404
	stz $0405
	dex
	dex
	bne .vz
	.if XRAILS
	lda #XPAL * 16
	sta $0402
	stz $0403
	ldx #32
.vx:	stz $0404
	stz $0405
	dex
	dex
	bne .vx
	.endif
	plp
	stz pend
	inc nres
	lda FRAMES
	sta tres1
	.if REPHASE
	sec
	sbc tres0
	jsr rph
	.endif
	pla
	tam #4
	rts



; tmid: the window's mid cells (17 x 33; the bitmaps of getrows, bit set = the compositor's mid path): tm, then tmk (the target)
tmid:	lda p0l
	sta tix
	lda p0h
	and #$0F
	sta tix+1
	tma #4
	pha
	lda #DB_CLS
	tam #4
	stz tm
	stz tm+1
	lda #17
	sta trc
.r:	lda tix
	and #7
	asl a
	asl a
	ora #$80
	sta tu
	lda tix+1
	sta tt
	lda tix
	lsr tt
	ror a
	lsr tt
	ror a
	lsr tt
	ror a
	sta .s+1
	lda tt
	clc
	adc tu
	sta .s+2
	ldy #4
	stz tu                  ; this row's count
.s:	lda $8000,y
	cpy #4
	bne .b
	and #$80                ; (the fifth byte: X 32 only)
.b:	tax
	lda kpop,x              ; (kgen's table: a byte's bits set)
	clc
	adc tu
	sta tu
	dey
	bpl .s
	clc
	adc tm
	sta tm
	bcc .n
	inc tm+1
.n:	lda tix
	clc
	adc #64
	sta tix
	bcc .n2
	inc tix+1
.n2:	dec trc
	bne .r
	pla
	tam #4
	jmp tmk                 ; (main bank) the pad's target
tix:	.dw 0
trc:	.db 0
tu:	.db 0
tt:	.db 0
; tdly: a counted delay of Y x 256 + X cycles, to within 8 (the measured pad's: bank 3's tpad)
tdly:	stx tu
	cpy #0
	beq .lo
.h:	ldx #41                 ; 256 cycles a turn
.i:	dex
	bne .i
	nop
	nop
	dey
	bne .h
.lo:	lda tu
	lsr a
	lsr a
	lsr a
	tax
	beq .x
.j:	nop                     ; 8 cycles a turn
	dex
	bne .j
.x:	rts

	.bank 3
	.org $C000

	jmp kpass               ; 0 the engaged pass (satbody: interrupts off on entry and on return)
	jmp kbuild              ; 3 the tables (setup: interrupts on, in the dark)
k3magic:	.db $19, $AF
	jmp ownrows
	.if RSLACK
	.if PBX
	jmp wbx                 ; 11 (r19-plug-bitmap: wbat not run; the entry kept for the table's offsets)
	.else
	jmp wbat                ; 11 r19-slack-rows: the plug diff (bank 4's rown: a window's plug words back before it shifts)
	.endif
	.endif
	.if PLG
	jmp sset                ; 14 r19-plug-streams: the set-up's end (streams, pool, state; shaft19_x9.inc)
	jmp sreen               ; 17 reeng: tables, pool, state
	jmp xcell               ; 20 (r19-load-exit-slots) the exit restore: a PAT slot's verdict by its whole sprite cell (xcell, after shaft19_x9.inc's include)
	.if HUDS
	jmp hudin
	jmp hudout
	.endif
	.endif
	jmp satc                ; 29 (HW-r19-frame-lines) satbody .c exit/reload restore check and dark-window rescue

KUNT       = $8000      ; DB_K at MPR4 while the pass runs: kunt (kfg 16 / 32 / 64, keg, kbm: 9 pages)
KGPAGE     = $89        ; the 17 pseudo-groups' pages (0 upper, 0 lower, 1-15): 21 constant SAT entries each (piece p at 8 p)
KMTPAGE    = $9A        ; the masks' entries: page KMTPAGE + 2 page + (mask >> 1), (mask & 1) * 128 + 8 nibble (1 KB)
ksd16      = $9E00      ; DB_K's last two pages: the side columns' x tables (kent's handlers; room19-s-fold-build: their source is in the third cold bank,
ksd32      = $9F00      ; copied here at every set-up by ksdcpy: 512 bytes of this bank back, the instructions that read them unchanged)
KSWL       = $7200      ; the pass's scratch (FOLD; DB_NEAR at MPR3 through the pass, past the near map's copy at $6000-$70FF; kscr): the S
KSWH       = $7300      ; word of each near byte value, low / high (the fix-up's word of a cell no longer left out);
omap       = $7400
OMAPZ      = $7480
KEC0       = $7D00
KEC1       = $7D40
KEY0       = $7D80
KEY1       = $7DC0
KYOK       = $7500      ; per y low byte: 0 = an overlay there is on the 8-px grid with a row inside the field's 16 (y 80, 88 .. 208), else 1
	.if FOLD
KTD        = $D700 - $7700 ; room19-s-objram: the generated tables of shaft19_ktab.inc (ktcnt, koffl, koffh, khim, kuv, kt8: 845 bytes) are read
	.else
KTD        = 0
	.endif
KFL        = $7600
KFH        = $7680
KPO        = $7B00
KPARK      = $82
	.if FOLD
KVER       = 3          ; the card tables' format (in their key); 3: the staircase blocks last in the order, kb3 the blocks before them
KQ         = 32         ; kbuild's key tables: bytes a block (the nibble map's bit 4: a staircase block), blocks 8-15 in the band's second page
KQH        = 0
	.else
KVER       = 2          ; the card tables' format (in their key)
KQ         = 16
KQH        = 128
	.endif

ownrows:	ldx #0
	lda rb
	beq .b0
	inx
.b0:	stx obi
	.if RSLACK
	txa                     ; (bank 4) r19-slack-rows: this buffer's window: the same cell, a shift (done there: carry clear), or a
	tay                     ; redraw at the k, j chosen there (carry set; rbe, cbe set either way)
	lda #RNOWN
	jsr cold4
	ldx obi
	bcs .d
	.else
	lda p0l
	cmp bp0l,x
	bne .d
	lda p0h
	cmp bp0h,x
	bne .d
	.endif
	stz redr
	rts
.d:	lda p0l
	sta bp0l,x
	lda p0h
	sta bp0h,x
	txa                     ; (no block of this buffer is left out now)
	asl a
	asl a
	asl a
	asl a
	tax
	ldy #16
.z:	stz bout,x
	inx
	dey
	bne .z
	tma #3
	pha
	tma #4
	pha
	lda p0l
	sta ksl
	lda p0h
	sec
	sbc #$C0
	sta ksh
	lsr a
	lsr a
	lsr a
	sta kb
	tay
	lda cbank,y
	tam #3
	lda cbank+1,y
	tam #4
	lda ksl
	asl a
	asl a
	sta kal
	lda ksh
	and #7
	asl a
	asl a
	sta kah
	lda ksl
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	ora kah
	ora #$60
	sta kah
	lda kal
	sta .j+1
	.if XMASK
	ldx #132                ; (XMASK: every row to X 32, BAT column 34: the near cell under the right mask)
	.else
	ldx #128                ; (an RTS after X 31: column 34 is xpass's on every pass, r19-bars-off-sprites)
	.endif
	txa
	clc
	adc kal
	sta .pl+1
	sta .pr+1
	lda #0
	rol a
	sta .pc+1
	lda #2
	sta <VDCREG
	stz krow
.r:	lda kah                 ; (a row starting in MPR4's half: the pair moves on one bank)
	cmp #$80
	bcc .m
	sbc #$20
	sta kah
	inc kb
	ldy kb
	lda cbank,y
	tam #3
	lda cbank+1,y
	tam #4
.m:	lda krow                ; MAWR: BAT row rb + r, column 2 (RSLACK: rb + j + r, column 2 + k)
	clc
	.if RSLACK
	adc rbe
	.else
	adc rb
	.endif
	tay
	sei
	st0 #0
	lda r64l,y
	.if RSLACK
	ora cbe
	.else
	ora #2
	.endif
	sta $0002
	lda r64h,y
	sta $0003
	st0 #2
	cli
	lda kah
	sta .j+2
	clc
.pc:	adc #0
	sta .pl+2
	sta .pr+2
	lda #$60
.pl:	sta $6080
.j:	jsr $6000
	lda #$13
.pr:	sta $6080
.n:	inc kah
	inc krow
	lda krow
	cmp #XROWS
	beq .e
	jmp .r
.e:	pla
	tam #4
	pla
	tam #3
	lda #1
	sta redr
	rts
obi:	.db 0           ; this pass's buffer: 0 (BAT rows 0-16) or 1 (rows 18-34)
redr:	.db 0           ; 1: own rows redrew this pass's buffer
	.if RSLACK = 0
bp0l:	.db 0, 0        ; per buffer: the camera cell (row 0's near pointer) its rows were drawn with ($FF high: none)
bp0h:	.db $FF, $FF
	.endif
bout:	.ds 32          ; per buffer: the left-out blocks whose backdrop cells hold the backdrop word (out's 8 x 2 bytes)
ocur:	.db 0, 0        ; (wbat: out of this block row, shifted)
wmode:	.db 0           ; wsw: 1 the backdrop word, 0 the transparent word (a block no longer left out)
wh:	.db 0
wm:	.db 0           ; ... the block's bit
kb:	.db 0
kal:	.db 0
kah:	.db 0
ksl:	.db 0
ksh:	.db 0
krow:	.db 0

; ---------------------------------------------------------------- the pass's state (this bank's RAM)
kgn:	.db 0
kpg:	.db 0           ; its SAT page (0 / 1)
kng:	.db 0           ; its entries after the masks
kne:	.db 0           ; ours
kmtp:	.db 0           ; KMTPAGE + 2 kpg
kcnt:	.db 0
	.if FOLDU | FOLD
kpal:	.db 0
	.endif
	.if FOLD
knof:	.db 0           ; 1: the fallback's reading (nothing parked, the parked entries put back)
npark:	.db 0           ; not 0: an entry was parked in this reading
kforce:	.db 0           ; kleave: a band's D is past its blocks before the staircase blocks
kdrp:	.db 0           ; kdrop ran
kovf:	.db 0           ; kh16_1: the entry counted is an overlay (not put in the map)
	.if FOLDP
kpl:	.db 0           ; the entry's pattern word (the high byte's bits 0-2)
kph:	.db 0
kpb:	.db 1, 0, 2, 0, 0, 0, 0, 0     ; KPO's bit by the pattern word's high byte
	.endif
	.if UFM
kel:	.db 0           ; the list's entries (UFM)
keh:	.db 0           ; this entry's lines less one
	.endif
kots:	.db 0
	.if FOLDS
kfx:	.db 0           ; this pass's X phase (camera X & 6), Y phase (& 6; 0 without YSM): kh16_1's scrolled grid
kfy:	.db 0
	.endif
kq0h:	.db 0           ; p0's high byte less $60: the near copy's page of the window's first cell at MPR3
nfp:	.dw 0           ; passes with an entry parked
nfb:	.dw 0           ; passes that took the fallback
	.if UPF
nfq:	.dw 0           ; passes that took the partial fallback
kpf:	.db 0           ; 1: the partial reading (UPF)
krr:	.db 0           ; not 0: a reading after the first (the parked entries' marks read back: knof or kpf)
ff:	.ds 16          ; this reading's forced (see-through, D past ns) and dropped blocks (8 bands x 2 bytes)
fq:	.ds 16          ; the first reading's: the partial reading puts back the overlays over them
	.endif
	.endif
eyh:	.db 0
exl:	.db 0
exh:	.db 0
kcl:	.db $FF         ; the camera cell whose record is in kh (p0)
kch:	.db $FF
ksumd:	.db 0
kgyt:	.ds 2           ; per block-row half: a band of it has blocks left out (transpose)
gma:	.db 0           ; group 0's halves (pieces of the upper / lower two block rows)
gmb:	.db 0
units:	.ds 8
side:	.ds 2
	.if U2L
kdl:	.ds 66          ; per 2-line group (64, the one past the end, a spare for entries off the field): units entering / leaving
	.else
kdl:	.ds 34          ; per 4-line group (32, the one past the end, a spare for entries off the field): units entering / leaving
	.endif
	.if ORD
kns:	.ds 8           ; per band: the listed blocks without a see-through cell (the class's ns)
ohi:	.db 0
oomd:	.db 0
oofl:	.db 0
oofh:	.db 0
kfst:	.db 0           ; this pass: see-through blocks left out (D past ns, summed over the bands)
nfst:	.dw 0           ; passes with one
	.endif
snib:	.ds 4
mnib:	.ds 4
mnix:	.ds 4           ; per mask: 2 side + half (snib's index), 4 half (its first band)
mhb:	.ds 4
kD:	.ds 8           ; per band: blocks left out
kcpm:	.db 0
kcph:	.db 0
kkp:	.ds 16          ; keep: band b's blocks 0-7 at b, 8-15 at 8 + b
gm:	.ds 16          ; per group (8 gy + gx): its kept blocks (bit 2 r + c)
out:	.ds 16          ; per band: blocks left out (wbat)
	.if WAL
wcol0:		.ds 16
wcol1:		.ds 16
sux0_lo:	.ds 17
sux0_hi:	.ds 17
sux1_lo:	.ds 17
sux1_hi:	.ds 17
wcost0:		.ds 17
wn_tot0:	.db 0
wn_see0:	.db 0
wn_tot1:	.db 0
wn_see1:	.db 0
wn0:		.db 0
wn1:		.db 0
kzero8:		.db 0, 0, 0, 0, 0, 0, 0, 0
kmte:		.ds 8
	.else
rows:	.ds 64          ; the camera cell's backdrop class rows (getrows: wbat's)
	.if FOLD
kh:
kn:	.ds 8           ; per band: visible blocks
kvl:	.ds 8           ; per band: the visible blocks (blocks 0-7, 8-15)
kvh:	.ds 8
kb3:	.ds 8           ; per band: the blocks before the staircase blocks in its order (keys 1-4)
kgv:	.ds 16          ; per group: its visible blocks
	.else
kh:
kn:	.ds 8           ; per band: visible blocks
kvl:	.ds 8           ; per band: the visible blocks (blocks 0-7, 8-15)
kvh:	.ds 8
kb1:	.ds 8           ; per band: blocks of key <= 1, <= 2, <= 3 in its order
kb2:	.ds 8
kb3:	.ds 8
kgv:	.ds 16          ; per group: its visible blocks
	.endif
kzero8:	.db 0, 0, 0, 0, 0, 0, 0, 0
kmte:	.ds 8
; kbuild's
kcy:	.db 0
kcx:	.db 0
kixl:	.db 0
kixh:	.db 0
kbn:	.db 0
kcb:	.ds 3
kbb:	.ds 3
kcum:	.ds 2
kc0:	.db 0
	.if FOLD
kml:	.ds 6           ; per key 1-5 (0: the invisible blocks, unused; 5: the staircase blocks): the band's blocks 0-7 / 8-15 of that key
kmh:	.ds 6
	.else
kml:	.ds 5           ; per key 1-4 (0: the invisible blocks, unused): the band's blocks 0-7 / 8-15 of that key
kmh:	.ds 5
	.endif
	.endif

; ---------------------------------------------------------------- the engaged pass
	.if FOLD
kfill:	ldx kgn
	lda tcl
	clc
	adc KFL,x
	sta tcl2
	lda tch
	adc KFH,x
	sta tch2
	.if STEPPAD
	lda nstp
	cmp kstp
	beq .f
	sta kstp
	lda tcl2
	sec
	sbc #<KSTEP
	sta tcl2
	lda tch2
	sbc #>KSTEP
	sta tch2
.f:
	.endif
	rts
tmupd:	lda p0l
	sec
	sbc tpl
	sta t0
	lda p0h
	sbc tph
	sta t1
	ora t0
	bne .ch
	rts                     ; (the same cell)
.ch:	lda tpl
	sta tql
	lda tph
	sta tqh
	lda p0l
	sta tpl
	lda p0h
	sta tph
	stz t3                  ; dy: 0, 1 (down), $FF (up)
	stz t4                  ; dx: 0, 1 (right), $FF (left)
	lda t1
	beq .po
	cmp #$FF
	bne .full
	lda t0                  ; - 1, - 64, - 63, - 65
	cmp #$FF
	beq .xl
	dec t3
	cmp #$C0
	beq .go
	cmp #$C1
	beq .xr
	cmp #$BF
	beq .xl
	bra .full
.po:	lda t0                  ; + 1, + 64, + 65, + 63
	cmp #1
	beq .xr
	inc t3
	cmp #64
	beq .go
	cmp #65
	beq .xr
	cmp #63
	beq .xl
.full:	lda #11
	jmp cold                ; (tmid: ends in tmk)
.xl:	dec t4
	bra .go
.xr:	inc t4
.go:	tma #4
	pha
	lda #DB_CLS
	tam #4
	lda t3
	beq .cx
	bmi .up
	cla                     ; one row down: the window's row 0 out, then row 16 of the window one row on in
	jsr tmrw
	jsr .sub
	lda tql
	clc
	adc #64
	sta tql
	bcc .d1
	inc tqh
.d1:	lda #4
	jsr tmrw
	jsr .add
	bra .cx
.up:	lda #4                  ; one row up: row 16 out, then row 0 of the window one row back in
	jsr tmrw
	jsr .sub
	lda tql
	sec
	sbc #64
	sta tql
	bcs .u1
	dec tqh
.u1:	cla
	jsr tmrw
	jsr .add
.cx:	lda t4
	beq .dn
	bmi .lf
	lda #33                 ; one column right: column 33 (the new window's 32) in, column 0 out
	jsr tmcw
	jsr .add
	cla
	jsr tmcw
	jsr .sub
	bra .dn
.lf:	lda tql                 ; one column left: from the new window: its column 0 in, its column 33 (the old one's 32) out
	bne .l1
	dec tqh
.l1:	dec tql
	cla
	jsr tmcw
	jsr .add
	lda #33
	jsr tmcw
	jsr .sub
.dn:	pla
	tam #4
	.if TMCHK
	jmp tmchk
	.else
	jmp tmk
	.endif
.add:	clc
	adc tm
	sta tm
	bcc .x
	inc tm+1
.x:	rts
.sub:	sta t0
	lda tm
	sec
	sbc t0
	sta tm
	bcs .x
	dec tm+1
	rts
; A = 0 (row 0 of the window at tql / tqh) or 4 (row 16: 1,024 cells on): the mid cells of the row's 33 cells -> A (DB_CLS at MPR4):
; the bitmap of the row's shift (index & 7: page $80 + 4 shift) has the row's first cell at a byte's top bit
tmrw:	sta t1
	lda tqh
	and #$0F
	clc
	adc t1
	sta t1
	lda tql
	and #7
	asl a
	asl a
	ora #$80
	sta t2
	lda tql
	lsr t1
	ror a
	lsr t1
	ror a
	lsr t1
	ror a
	sta .s+1
	lda t1
	clc
	adc t2
	sta .s+2
	ldy #4
	stz t0
.s:	lda $8000,y
	cpy #4
	bne .b
	and #$80                ; (the fifth byte: X 32 only)
.b:	tax
	lda kpop,x
	clc
	adc t0
	sta t0
	dey
	bpl .s
	rts
	.else
kfill:	lda tcl
	sta tcl2
	lda tch
	sta tch2
	.if STEPPAD
	lda nstp                ; a colour-cycle step since the last pass: its hook's cycles (KSTEP, in this pass's logic, before row 0)
	cmp kstp
	beq .f
	sta kstp
	lda tcl2
	sec
	sbc #<KSTEP
	sta tcl2
	lda tch2
	sbc #>KSTEP
	sta tch2
.f:
	.endif
	lda #64
	sec
	sbc kgn
	beq .x
	sta kfl0
	stz kfh0
	lda #3
	clc
	adc tcl2
	sta tcl2
	bcc .b
	inc tch2
.b:	asl kfl0                 ; 2 n
	jsr .ad
	asl kfl0                 ; 8 n
	rol kfh0
	asl kfl0
	rol kfh0
	jsr .ad
	asl kfl0                 ; 16 n
	rol kfh0
.ad:	lda kfl0
	clc
	adc tcl2
	sta tcl2
	lda kfh0
	adc tch2
	sta tch2
.x:	rts
	.endif
	.if STEPPAD
kstp:	.db 0           ; nstp's low byte at the last pass
	.endif
tcl2:	.db 0           ; the pad's target with the zero fill
tch2:	.db 0
kfl0:	.db 0
kfh0:	.db 0
	.if XRAILS
	.include "shaft19_x5.inc"
	.endif
kpass:	cli
	lda c5stage
	beq .st0
	dec a
	beq .st1j
	dec a
	beq .st2j
	dec a
	beq .st3j
	jmp kpst4
.st1j:	jmp .st1
.st2j:	jmp kpst2
.st3j:	jmp kpst3
.st0:
	.if PADON
	stz tturn               ; (the measured pad: this pass's sums)
	stz tticks
	stz tk24
	stz tk152
	stz tvb
	jsr tsa
	.endif
	jsr ownrows
	.if PADON
	jsr tmupd               ; the window's mid cells -> the pad's target
	.endif
	lda #1
	sta c5stage
	.if C5CAR
	lda FRAMES
	cmp c5fr
	beq .st1
	lda #1
	sta c5nopad             ; (non-zero: paused)
	sei
	sec
	rts
	.endif
.st1:	tma #4
	pha
	lda #DB_K
	tam #4
	.if FOLD
	tma #3                  ; (the pass's scratch and the S words: kscr)
	pha
	lda #DB_NEAR
	tam #3
	.endif
	lda c5nsat
	sta kgn
	.if PADON
	jsr kfill
	.endif
	lda c5satpg
	and #1
	sta kpg
	asl a
	clc
	adc #KMTPAGE
	sta kmtp
	lda kgn
	sec
	sbc #4
	bcs .n2
	cla
.n2:	sta kng
	.if FOLD
	lda knof
	beq .nk
	lda #<kh16_1
	sta khjt
	lda #>kh16_1
	sta khjt+1
.nk:	stz knof
	.if UPF
	stz kpf
	stz krr
	.endif
	stz npark
	.if FOLDS
	lda pxr                 ; (the pass's phases for kh16_1: the scroll of this pass's BG, BXRV / BYRV)
	and #6
	sta kfx
	.if YSM
	lda pyr
	and #6
	sta kfy
	.endif
	.endif
	lda p0h
	sec
	sbc #$60
	sta kq0h
kpa:	stz kdrp
	.endif
	stz side
	stz side+1
	jsr kent
	.if U2L
	cla                     ; (the fifth bank) ksw64: units by 2-line groups
	jsr c5
	.else
	jsr ksweep
	.endif
	.if XMASK
	lda #$FF
	sta side
	sta side+1
	.else
	lda side+1
	ora #$80
	sta side+1
	.endif
	jsr kmask
	.if XRAILS
	.if ORD
	lda #3                  ; (the fifth bank) kord: the record and the leave-out by the class's order
	jsr c5
	lda kfst
	beq .nfs
	inc nfst
	bne .nfs
	inc nfst+1
.nfs:
	.else
	jsr xcellh              ; (the camera cell's record, merged with the next cell's off the grid)
	jsr kleave
	jsr xleave
	.endif
	.else
	jsr kcellh
	jsr kleave
	.endif
	.if WAL = 0
	jsr kgm
	jsr kcount
kpc:	clc
	adc kgn
	cmp #65
	bcc .e
	.if FOLD
	inc kdrp
	.endif
	jsr kdrop               ; (kdrop stops when they fit)
.e:
	.endif
	.if FOLD
	lda npark               ; the fallback: an entry is parked and a staircase block is left out (kleave: kforce) or kdrop left out
	beq .ok                 ; whole groups: the parked entries back, the pass counted again without the fold (knof)
	.if FOLDF
	.else
	lda kforce
	ora kdrp
	beq .pk
	.endif
	.if UPF
	lda kpf
	bne .p2
	tii ff, fq, 16          ; (the partial reading: the overlays over this reading's forced and dropped blocks put back)
	inc kpf
	inc krr
	stz npark
	inc nfq
	bne .pj
	inc nfq+1
.pj:	jmp kpa
.p2:	ldx #15                 ; (the partial reading's own forced and dropped blocks inside the first's: done)
.p3:	lda fq,x
	eor #$FF
	and ff,x
	bne .p4
	dex
	bpl .p3
	jmp .ok
.p4:	stz kpf
	.endif
	inc knof
	.if UPF
	inc krr
	.endif
	lda #<kh16c             ; (the fallback's reading: every 16 x 16 entry counted, none parked, none in the map)
	sta khjt
	lda #>kh16c
	sta khjt+1
	stz npark
	inc nfb
	.if UPF
	bne .fj
	inc nfb+1
.fj:	jmp kpa
	.else
	bne kpa
	inc nfb+1
	bra kpa
	.endif
.pk:	inc nfp
	bne .ok
	inc nfp+1
.ok:
	.endif
	.if FOLD
	pla
	tam #3
	.endif
	pla
	tam #4
	lda #2
	sta c5stage
	.if C5CAR
	lda FRAMES
	cmp c5fr
	beq kpst2
	lda #1
	sta c5nopad
	sei
	sec
	rts
	.endif
kpst2:	tma #4
	pha
	lda #DB_K
	tam #4
	.if FOLD
	tma #3
	pha
	lda #DB_NEAR
	tam #3
	.endif
	.if PBX = 0
	jsr wbat
	.endif
	.if XRAILS
	.if HOLD
	jsr khold               ; a pass that would run over: held (its rows, kernel and fix-up done in the hidden buffer and page, not shown)
	bcs .xh
	.endif
	.if XBG
	tma #4                  ; the pass's left-out blocks and the cell's class rows for the X phase's fix-up (DB_X)
	pha
	lda #DB_X
	tam #4
	tii out, XD_OUT, 16
	tii rows, XD_ROWS, 16
	tii rows + 16, XD_ROWS + 16, 16
	tii rows + 32, XD_ROWS + 32, 16
	tii rows + 48, XD_ROWS + 48, 16
	pla
	tam #4
	.endif
	ldy obi                 ; (bank 4) the X phase: scroll latch, bars, edge composites, the backdrop phase tiles
	lda #26
	jsr cold4
.xh:
	.endif
	.if FOLD
	pla
	tam #3
	.endif
	pla
	tam #4
	lda #3
	sta c5stage
	.if C5CAR
	lda FRAMES
	cmp c5fr
	beq kpst3
	lda #1
	sta c5nopad
	sei
	sec
	rts
	.endif
kpst3:	tma #4
	pha
	lda #DB_K
	tam #4
	.if FOLD
	tma #3
	pha
	lda #DB_NEAR
	tam #3
	.endif
	.if XRAILS & PLG
	jsr splug               ; (r19-plug-streams) the plug; carry set: held
	bcc .s3ok
	inc c5hold
	.if FOLD
	pla
	tam #3
	.endif
	pla
	tam #4
	sei
	sec
	rts
.s3ok:
	.endif
	.if FOLD
	pla
	tam #3
	.endif
	pla
	tam #4
	lda #4
	sta c5stage
kpst4:	tma #4
	pha
	lda #DB_K
	tam #4
	.if FOLD
	tma #3
	pha
	lda #DB_NEAR
	tam #3
	.endif
	jsr kemit
	sei
	inc $339F
	lda c5satpg
	sta SATPAGE
	stz c5satok
	lda c5bxrv
	sta BXRV
	lda c5byrv
	sta BYRV
	inc npass
	bne kps
	inc npass+1
kps:
	.if FOLD
	pla
	tam #3
	.endif
	pla
	tam #4
	.if PADON
	lda c5nopad
	bne kpnpd
	jsr tsb
kpm:	jsr tpad
kpnpd:
	.endif
	clc
kpe:	sei
	rts

	.if FOLD
kent:	lda kng
	bne .g
	rts
.g:	lda knof
	bne .m                  ; (the fallback's reading: no map, nothing parked; MAWR's high byte still the first reading's)
	tii OMAPZ, omap, 23     ; (two moves: 155 cycles each with the interrupts held)
	tii OMAPZ, omap + 23, 22
	.if UFM
	stz kel
	.endif
	sei                     ; MAWR's high byte for the parked words: the table's page (the low byte per entry); then the data
	st0 #0
	st1 #0
	lda c5satpg
	sta $0003
	lda #2
	sta <VDCREG
	st0 #2
	cli
.m:	stz kots
	lda c5satpg
	sta kms+1
	lda kgn
	dec a
	asl a
	asl a
	sta kma+1               ; the last entry's address (4 index)
kent_e:	sei
	st0 #1
kma:	st1 #0
kms:	st2 #0                  ; (the read buffer loads)
	st0 #2
	ldy $0002               ; y low
	lda $0003
	bit #3
	bne kent_o              ; (y >= 256: below the field; count: ent - hit)
kent_x:	lda $0002
	sta exl
	lda $0003
	sta exh
	.if FOLDP
	lda $0002               ; the pattern word (kh16_1's pool test)
	sta kpl
	lda $0003
	and #7
	sta kph
	.else
	lda $0003               ; (the pattern word: the port moves on)
	.endif
	ldx $0002
	lda $0003               ; attribute high: cgx bit 0, cgy bits 4-5
	cli
	and #$31
	asl a
	sax
	jmp [khjt,x]
	.if UPF
kent_o:	ldx krr
	.else
kent_o:	ldx knof
	.endif
	beq .n
	cmp #KPARK              ; the fallback: a parked entry (its mark) gets its y back and is read on as it was
	bne .n
	st0 #0
	lda kma+1
	sta $0002
	st0 #2
	sty $0002
	st2 #0
	bra kent_x
.n:	cli
kent_n:	lda kma+1
	sec
	sbc #4
	sta kma+1
	cmp #16
	bcs kent_e
	rts
; an entry that is not an overlay: its box into omap (A: its bands; x from 320: off the screen), 16 / 32 px wide
kmx0:	jmp kent_n
kmk32:	sta t9
	lda exh                 ; X = the 8-px column of x (bit 5: x from 256): the entry's columns X .. X + 3, and X + 4 when x is off the grid
	lsr a
	lda exl
	ror a
	lsr a
	lsr a
	tax
	cpx #40
	bcs kmx0
	.if UFM
	lda exl
	and #7
	beq .k3a
	lda t9
	ora omap+2,x
	sta omap+2,x
	lda t9
	ora omap+3,x
	sta omap+3,x
	lda t9
	ora omap+4,x
	sta omap+4,x
	lda t9
	ora omap,x
	sta omap,x
	tsb kots
	lda t9
	ora omap+1,x
	sta omap+1,x
	txa
	ldx kel
	sta KEC0,x
	clc
	adc #4
	bra krec
.k3a:	lda t9
	ora omap+2,x
	sta omap+2,x
	lda t9
	ora omap+3,x
	sta omap+3,x
	lda t9
	ora omap,x
	sta omap,x
	tsb kots
	lda t9
	ora omap+1,x
	sta omap+1,x
	txa
	ldx kel
	sta KEC0,x
	clc
	adc #3
krec:	sta KEC1,x
	tya
	sta KEY0,x
	clc
	adc keh
	bcc .krc
	lda #$FF
.krc:	sta KEY1,x
	inc kel
	jmp kent_n
	.else
	lda t9
	ora omap+2,x
	sta omap+2,x
	lda t9
	ora omap+3,x
	sta omap+3,x
	lda exl
	and #7
	beq kmk16c
	lda t9
	ora omap+4,x
	sta omap+4,x
	bra kmk16c
	.endif
kmk16:	sta t9
	lda exh                 ; (16 px wide: X, X + 1, and X + 2 when x is off the grid)
	lsr a
	lda exl
	ror a
	lsr a
	lsr a
	tax
	cpx #40
	bcs kmx
	.if UFM
	lda exl
	and #7
	beq .k1a
	lda t9
	ora omap+2,x
	sta omap+2,x
	lda t9
	ora omap,x
	sta omap,x
	tsb kots
	lda t9
	ora omap+1,x
	sta omap+1,x
	txa
	ldx kel
	sta KEC0,x
	clc
	adc #2
	jmp krec
.k1a:	lda t9
	ora omap,x
	sta omap,x
	tsb kots
	lda t9
	ora omap+1,x
	sta omap+1,x
	txa
	ldx kel
	sta KEC0,x
	inc a
	jmp krec
	.else
	lda exl
	and #7
	beq kmk16c
	lda t9
	ora omap+2,x
	sta omap+2,x
kmk16c:	lda t9
	ora omap,x
	sta omap,x
	tsb kots                ; (not 0 when the entry lies on a band of the field)
	lda t9
	ora omap+1,x
	sta omap+1,x
	.endif
kmx:	jmp kent_n
	.if UPF
; (UPF) carry set: the overlay at x (exh:exl), y (Y) covers a block of fq (screen blocks: x 48 + 16 k, y 88 + 16 b). Y kept.
kfq:	lda exl
	sec
	sbc #48
	sta t8
	lda exh
	and #3
	sbc #0
	bmi .kn
	bne .no
	lda t8                  ; d 0-255: k0 = d >> 4, k1 = min(d + 15, 255) >> 4
	lsr a
	lsr a
	lsr a
	lsr a
	sta t6
	lda t8
	clc
	adc #15
	bcc .k1
	lda #$FF
.k1:	lsr a
	lsr a
	lsr a
	lsr a
	sta t5
	bra .y
.kn:	lda t8                  ; d -15 .. -1: block 0
	cmp #$F1
	bcc .no
	stz t6
	stz t5
.y:	tya                     ; e = y - 88: b0 = max(e, 0) >> 4, b1 = min(e + 15, 127) >> 4
	cmp #73
	bcc .no
	sec
	sbc #88
	bcs .y1
	cla
.y1:	cmp #128
	bcs .no
	lsr a
	lsr a
	lsr a
	lsr a
	sta t4
	tya
	clc
	adc #15
	bcs .yb
	sec
	sbc #88
	cmp #128
	bcc .y2
.yb:	lda #127
.y2:	lsr a
	lsr a
	lsr a
	lsr a
	sta t3
	lda t4                  ; (b0, k0), (b0, k1), (b1, k0), (b1, k1)
	ldx t6
	jsr .t
	bne .yes
	ldx t5
	jsr .t
	bne .yes
	lda t3
	ldx t6
	jsr .t
	bne .yes
	ldx t5
	jsr .t
	bne .yes
.no:	clc
	rts
.yes:	sec
	rts
.t:	sta t2                  ; band A, block X: fq's bit (Z clear: set). A kept.
	asl a
	sta t1
	txa
	lsr a
	lsr a
	lsr a
	ora t1
	phx
	tax
	lda fq,x
	plx
	sta t1
	txa
	and #7
	tax
	lda kbit8,x
	and t1
	php
	lda t2
	plp
	rts
kbit8:	.db 1, 2, 4, 8, 16, 32, 64, 128
	.endif
	.if UFM
; (UFM) an overlay whose columns meet an entry of the map on a band: drawn only when an entry of the list shares a line with it
; (X: its first column; Y: its y)
kex:	stx t8
	stx t7
	inc t7
	lda exl
	and #7
	beq .ka
	inc t7
.ka:	sty t5
	tya
	clc
	adc #15
	bcc .c
	lda #$FF
.c:	sta t6                  ; its last line
	ldx kel
.l:	dex
	bmi .no
	lda t7
	cmp KEC0,x
	bcc .l
	lda KEC1,x
	cmp t8
	bcc .l
	lda t6
	cmp KEY0,x
	bcc .l
	lda KEY1,x
	cmp t5
	bcc .l
	jmp kh16c
.no:	jmp kh16p
	.endif
kh16_1:	and #$8F                ; (A: attribute low)
	cmp #$8E
	bne kh16u               ; (not an overlay)
	.if FOLDP
	ldx kpl                 ; its pattern in the builder's pool (KPO), or it is an entry like any other
	lda KPO,x
	ldx kph
	and kpb,x
	beq kh16u
	.endif
	.if FOLDS
	lda exl                 ; on the pass's SCROLLED grid (x + X phase and y + Y phase multiples of 8: the BG cell under each quadrant is
	clc                     ; the staircase's own, at any phase) and a row on the field (KYOK: y 73 .. 215; on the grid: 80, 88 .. 208)
	adc kfx
	sta t9
	tya
	clc
	adc kfy
	ora t9
	and #7
	.else
	lda exl                 ; on the 8-px grid, a row inside the field's 16 (KYOK: y 80, 88 .. 208)
	and #7
	.endif
	ora KYOK,y
	bne kh16c
	lda kots                ; no entry that is not an overlay read yet: nothing is behind this one: parked without the map
	beq .p
	lda exh                 ; its two 8-px columns of omap (on the screen's grid; FOLDS: three when x is off it)
	lsr a
	lda exl
	ror a
	lsr a
	lsr a
	tax
	.if FOLDS
	lda exl
	and #7
	beq .g2
	lda omap+2,x
.g2:	ora omap,x
	.else
	lda omap,x
	.endif
	ora omap+1,x
	and KUNT + 1536,y       ; (the bands of a 16-line entry at y)
	.if UFM
	beq .p
	jmp kex                 ; (by lines)
	.else
	bne kh16c               ; an entry behind it lies over its columns on a band of its own: drawn
	.endif
.p:
kh16p:
	.if UPF
	lda kpf                 ; (the partial reading: an overlay over a block of fq is drawn)
	beq .pp
	jsr kfq
	bcc .pp
	jmp kh16c
.pp:
	.endif
	sei                     ; parked: y + 512 in its own word, with the mark
	st0 #0
	lda kma+1
	sta $0002
	st0 #2
	sty $0002
	st2 #KPARK
	cli
	sta npark               ; (its address: never 0)
	jmp kent_n
kh16c:	inc kovf
kh16u:	ldx KUNT + 0,y
	inc kdl,x
	ldx KUNT + 768,y
	dec kdl,x
	lda exh
	and #3
	tax
	lda khim-KTD,x
	ldx exl
	and ksd16,x
	beq .n
	lsr a                   ; (count: side)
	tax
	lda KUNT + 1536,y
	ora side,x
	sta side,x
.n:	lda kovf
	bne .o
	.if UFM
	lda #15
	sta keh
	.endif
	lda KUNT + 1536,y
	jmp kmk16
.o:	stz kovf
	jmp kent_n
	.else
kent:	lda kng
	bne .g
	rts
.g:	sta kcnt
	lda #16
	ldx c5satpg
	jsr vmarr
kent_e:	sei
	ldy $0002               ; y low
	lda $0003
	and #3
	bne kent_o              ; (y >= 256: below the field; count: ent - hit)
	lda $0002
	sta exl
	lda $0003
	sta exh
	lda $0002
	lda $0003
	lda $0002
	.if FOLDU
	sta kpal
	.endif
	lda $0003               ; attribute high: cgx bit 0, cgy bits 4-5
	cli
	and #$31
	asl a
	tax
	jmp [khjt,x]
kent_o:	lda $0002               ; (the other six bytes: the data port moves on)
	lda $0003
	lda $0002
	lda $0003
	lda $0002
	lda $0003
	cli
kent_n:	dec kcnt
	bne kent_e
	rts
kh16_1:
	.if FOLDU
	lda kpal
	and #$0F
	cmp #$0E
	bne .u
	jmp kent_n
.u:
	.endif
	ldx KUNT + 0,y
	inc kdl,x
	ldx KUNT + 768,y
	dec kdl,x
	lda exh
	and #3
	tax
	lda khim-KTD,x
	ldx exl
	and ksd16,x
	beq .n
	lsr a                   ; (count: side)
	tax
	lda KUNT + 1536,y
	ora side,x
	sta side,x
.n:	jmp kent_n
	.endif
kh16_2:	ldx KUNT + 0,y
	inc kdl,x
	inc kdl,x
	ldx KUNT + 768,y
	dec kdl,x
	dec kdl,x
	lda exh
	and #3
	tax
	lda khim-KTD,x
	ldx exl
	and ksd32,x
	beq .n
	lsr a                   ; (count: side)
	tax
	lda KUNT + 1536,y
	ora side,x
	sta side,x
.n:
	.if FOLD
	.if UFM
	lda #15
	sta keh
	.endif
	lda KUNT + 1536,y
	jmp kmk32
	.else
	jmp kent_n
	.endif
kh32_1:	ldx KUNT + 256,y
	inc kdl,x
	ldx KUNT + 1024,y
	dec kdl,x
	lda exh
	and #3
	tax
	lda khim-KTD,x
	ldx exl
	and ksd16,x
	beq .n
	lsr a                   ; (count: side)
	tax
	lda KUNT + 1792,y
	ora side,x
	sta side,x
.n:
	.if FOLD
	.if UFM
	lda #31
	sta keh
	.endif
	lda KUNT + 1792,y
	jmp kmk16
	.else
	jmp kent_n
	.endif
kh32_2:	ldx KUNT + 256,y
	inc kdl,x
	inc kdl,x
	ldx KUNT + 1024,y
	dec kdl,x
	dec kdl,x
	lda exh
	and #3
	tax
	lda khim-KTD,x
	ldx exl
	and ksd32,x
	beq .n
	lsr a                   ; (count: side)
	tax
	lda KUNT + 1792,y
	ora side,x
	sta side,x
.n:
	.if FOLD
	.if UFM
	lda #31
	sta keh
	.endif
	lda KUNT + 1792,y
	jmp kmk32
	.else
	jmp kent_n
	.endif
kh64_1:	ldx KUNT + 512,y
	inc kdl,x
	ldx KUNT + 1280,y
	dec kdl,x
	lda exh
	and #3
	tax
	lda khim-KTD,x
	ldx exl
	and ksd16,x
	beq .n
	lsr a                   ; (count: side)
	tax
	lda KUNT + 2048,y
	ora side,x
	sta side,x
.n:
	.if FOLD
	.if UFM
	lda #63
	sta keh
	.endif
	lda KUNT + 2048,y
	jmp kmk16
	.else
	jmp kent_n
	.endif
kh64_2:	ldx KUNT + 512,y
	inc kdl,x
	inc kdl,x
	ldx KUNT + 1280,y
	dec kdl,x
	dec kdl,x
	lda exh
	and #3
	tax
	lda khim-KTD,x
	ldx exl
	and ksd32,x
	beq .n
	lsr a                   ; (count: side)
	tax
	lda KUNT + 2048,y
	ora side,x
	sta side,x
.n:
	.if FOLD
	.if UFM
	lda #63
	sta keh
	.endif
	lda KUNT + 2048,y
	jmp kmk32
	.else
	jmp kent_n
	.endif
khjt:	.dw kh16_1, kh16_2, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n
	.dw kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kh32_1, kh32_2, kent_n, kent_n
	.dw kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n
	.dw kent_n, kent_n, kh64_1, kh64_2, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n
	.dw kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kent_n, kh64_1, kh64_2
; units per band: the most of its four groups' running sums (kdl left zero)
; units per band: the most of its four groups' running sums (kdl left zero); unrolled: constant
	.if U2L = 0
ksweep:	cla
	stz t9
	clc
	adc kdl+0
	stz kdl+0
	kmx9 .a0, .b0
	clc
	adc kdl+1
	stz kdl+1
	kmx9 .a1, .b1
	clc
	adc kdl+2
	stz kdl+2
	kmx9 .a2, .b2
	clc
	adc kdl+3
	stz kdl+3
	kmx9 .a3, .b3
	ldx t9
	stx units+0
	stz t9
	clc
	adc kdl+4
	stz kdl+4
	kmx9 .a4, .b4
	clc
	adc kdl+5
	stz kdl+5
	kmx9 .a5, .b5
	clc
	adc kdl+6
	stz kdl+6
	kmx9 .a6, .b6
	clc
	adc kdl+7
	stz kdl+7
	kmx9 .a7, .b7
	ldx t9
	stx units+1
	stz t9
	clc
	adc kdl+8
	stz kdl+8
	kmx9 .a8, .b8
	clc
	adc kdl+9
	stz kdl+9
	kmx9 .a9, .b9
	clc
	adc kdl+10
	stz kdl+10
	kmx9 .a10, .b10
	clc
	adc kdl+11
	stz kdl+11
	kmx9 .a11, .b11
	ldx t9
	stx units+2
	stz t9
	clc
	adc kdl+12
	stz kdl+12
	kmx9 .a12, .b12
	clc
	adc kdl+13
	stz kdl+13
	kmx9 .a13, .b13
	clc
	adc kdl+14
	stz kdl+14
	kmx9 .a14, .b14
	clc
	adc kdl+15
	stz kdl+15
	kmx9 .a15, .b15
	ldx t9
	stx units+3
	stz t9
	clc
	adc kdl+16
	stz kdl+16
	kmx9 .a16, .b16
	clc
	adc kdl+17
	stz kdl+17
	kmx9 .a17, .b17
	clc
	adc kdl+18
	stz kdl+18
	kmx9 .a18, .b18
	clc
	adc kdl+19
	stz kdl+19
	kmx9 .a19, .b19
	ldx t9
	stx units+4
	stz t9
	clc
	adc kdl+20
	stz kdl+20
	kmx9 .a20, .b20
	clc
	adc kdl+21
	stz kdl+21
	kmx9 .a21, .b21
	clc
	adc kdl+22
	stz kdl+22
	kmx9 .a22, .b22
	clc
	adc kdl+23
	stz kdl+23
	kmx9 .a23, .b23
	ldx t9
	stx units+5
	stz t9
	clc
	adc kdl+24
	stz kdl+24
	kmx9 .a24, .b24
	clc
	adc kdl+25
	stz kdl+25
	kmx9 .a25, .b25
	clc
	adc kdl+26
	stz kdl+26
	kmx9 .a26, .b26
	clc
	adc kdl+27
	stz kdl+27
	kmx9 .a27, .b27
	ldx t9
	stx units+6
	stz t9
	clc
	adc kdl+28
	stz kdl+28
	kmx9 .a28, .b28
	clc
	adc kdl+29
	stz kdl+29
	kmx9 .a29, .b29
	clc
	adc kdl+30
	stz kdl+30
	kmx9 .a30, .b30
	clc
	adc kdl+31
	stz kdl+31
	kmx9 .a31, .b31
	ldx t9
	stx units+7
	stz kdl+32
	stz kdl+33
	rts
	.endif
; the masks: the needed bands of each mask's half of its side (a nibble), the units it adds to that half's bands
kmask:	lda side
	and #$0F
	sta snib
	lda side
	lsr a
	lsr a
	lsr a
	lsr a
	sta snib+1
	lda side+1
	and #$0F
	sta snib+2
	lda side+1
	lsr a
	lsr a
	lsr a
	lsr a
	sta snib+3
	ldx mnix+0
	lda snib,x
	sta mnib+0
	asl a
	asl a
	tay
	ldx mhb+0
	lda units+0,x
	clc
	adc kuv-KTD+0,y
	sta units+0,x
	lda units+1,x
	clc
	adc kuv-KTD+1,y
	sta units+1,x
	lda units+2,x
	clc
	adc kuv-KTD+2,y
	sta units+2,x
	lda units+3,x
	clc
	adc kuv-KTD+3,y
	sta units+3,x
	ldx mnix+1
	lda snib,x
	sta mnib+1
	asl a
	asl a
	tay
	ldx mhb+1
	lda units+0,x
	clc
	adc kuv-KTD+0,y
	sta units+0,x
	lda units+1,x
	clc
	adc kuv-KTD+1,y
	sta units+1,x
	lda units+2,x
	clc
	adc kuv-KTD+2,y
	sta units+2,x
	lda units+3,x
	clc
	adc kuv-KTD+3,y
	sta units+3,x
	ldx mnix+2
	lda snib,x
	sta mnib+2
	asl a
	asl a
	tay
	ldx mhb+2
	lda units+0,x
	clc
	adc kuv-KTD+0,y
	sta units+0,x
	lda units+1,x
	clc
	adc kuv-KTD+1,y
	sta units+1,x
	lda units+2,x
	clc
	adc kuv-KTD+2,y
	sta units+2,x
	lda units+3,x
	clc
	adc kuv-KTD+3,y
	sta units+3,x
	ldx mnix+3
	lda snib,x
	sta mnib+3
	asl a
	asl a
	tay
	ldx mhb+3
	lda units+0,x
	clc
	adc kuv-KTD+0,y
	sta units+0,x
	lda units+1,x
	clc
	adc kuv-KTD+1,y
	sta units+1,x
	lda units+2,x
	clc
	adc kuv-KTD+2,y
	sta units+2,x
	lda units+3,x
	clc
	adc kuv-KTD+3,y
	sta units+3,x
	rts
	.if ORD = 0
kcellh:	lda p0l
	eor kcl
	sta t0
	lda p0h
	eor kch
	ora t0
	bne .c
	rts
.c:	lda p0l                 ; (count: cell)
	sta kcl
	sta t0
	lda p0h
	sta kch
	and #$0F
	sta t1
	lda t0
	and #63
	tax                     ; cx = p0 & 63 (sdtest: <= 32)
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
	.if FOLD
	tai $1A00, kh, 24
	tai $1A00, kh + 24, 24
	.else
	tai $1A00, kh, 32
	tai $1A00, kh + 32, 32
	.endif
	txa
	clc
	adc kcrl,y
	sta kcpm
	lda kcrh,y
	adc #0
	sta kcph
	rts
kleave:	stz kgyt
	stz kgyt+1
	stz ksumd
	lda kcpm
	sta $1A03
	lda kcph
	sta $1A04
	lda #16
	sec
	sbc units+0
	bcs .a0
	cla
.a0:	sta t0
	sec
	sbc kn+0
	bcs .z0
	eor #$FF               ; (count: band)
	inc a
	sta kD+0
	clc
	adc ksumd
	sta ksumd
	lda kD+0
	asl a
	adc #$FE
	sta $1A02
	lda $1A00
	sta out+0
	eor #$FF
	and kvl+0
	sta kkp+0
	lda $1A00
	sta out+1
	eor #$FF
	and kvh+0
	sta kkp+8
	lda #1
	sta kgyt+0
	lda t0
	bra .u0
.z0:	stz kD+0
	stz out+0
	stz out+1
	lda kvl+0
	sta kkp+0
	lda kvh+0
	sta kkp+8
	lda kn+0
.u0:	clc
	adc units+0
	kmxu .v0, .w0
	lda #16
	sec
	sbc units+1
	bcs .a1
	cla
.a1:	sta t0
	sec
	sbc kn+1
	bcs .z1
	eor #$FF
	inc a
	sta kD+1
	clc
	adc ksumd
	sta ksumd
	lda kD+1
	asl a
	adc #$1E
	sta $1A02
	lda $1A00
	sta out+2
	eor #$FF
	and kvl+1
	sta kkp+1
	lda $1A00
	sta out+3
	eor #$FF
	and kvh+1
	sta kkp+9
	lda #1
	sta kgyt+0
	lda t0
	bra .u1
.z1:	stz kD+1
	stz out+2
	stz out+3
	lda kvl+1
	sta kkp+1
	lda kvh+1
	sta kkp+9
	lda kn+1
.u1:	clc
	adc units+1
	kmxu .v1, .w1
	lda #16
	sec
	sbc units+2
	bcs .a2
	cla
.a2:	sta t0
	sec
	sbc kn+2
	bcs .z2
	eor #$FF
	inc a
	sta kD+2
	clc
	adc ksumd
	sta ksumd
	lda kD+2
	asl a
	adc #$3E
	sta $1A02
	lda $1A00
	sta out+4
	eor #$FF
	and kvl+2
	sta kkp+2
	lda $1A00
	sta out+5
	eor #$FF
	and kvh+2
	sta kkp+10
	lda #1
	sta kgyt+0
	lda t0
	bra .u2
.z2:	stz kD+2
	stz out+4
	stz out+5
	lda kvl+2
	sta kkp+2
	lda kvh+2
	sta kkp+10
	lda kn+2
.u2:	clc
	adc units+2
	kmxu .v2, .w2
	lda #16
	sec
	sbc units+3
	bcs .a3
	cla
.a3:	sta t0
	sec
	sbc kn+3
	bcs .z3
	eor #$FF
	inc a
	sta kD+3
	clc
	adc ksumd
	sta ksumd
	lda kD+3
	asl a
	adc #$5E
	sta $1A02
	lda $1A00
	sta out+6
	eor #$FF
	and kvl+3
	sta kkp+3
	lda $1A00
	sta out+7
	eor #$FF
	and kvh+3
	sta kkp+11
	lda #1
	sta kgyt+0
	lda t0
	bra .u3
.z3:	stz kD+3
	stz out+6
	stz out+7
	lda kvl+3
	sta kkp+3
	lda kvh+3
	sta kkp+11
	lda kn+3
.u3:	clc
	adc units+3
	kmxu .v3, .w3
	lda #16
	sec
	sbc units+4
	bcs .a4
	cla
.a4:	sta t0
	sec
	sbc kn+4
	bcs .z4
	eor #$FF
	inc a
	sta kD+4
	clc
	adc ksumd
	sta ksumd
	lda kD+4
	asl a
	adc #$7E
	sta $1A02
	lda $1A00
	sta out+8
	eor #$FF
	and kvl+4
	sta kkp+4
	lda $1A00
	sta out+9
	eor #$FF
	and kvh+4
	sta kkp+12
	lda #1
	sta kgyt+1
	lda t0
	bra .u4
.z4:	stz kD+4
	stz out+8
	stz out+9
	lda kvl+4
	sta kkp+4
	lda kvh+4
	sta kkp+12
	lda kn+4
.u4:	clc
	adc units+4
	kmxu .v4, .w4
	lda #16
	sec
	sbc units+5
	bcs .a5
	cla
.a5:	sta t0
	sec
	sbc kn+5
	bcs .z5
	eor #$FF
	inc a
	sta kD+5
	clc
	adc ksumd
	sta ksumd
	lda kD+5
	asl a
	adc #$9E
	sta $1A02
	lda $1A00
	sta out+10
	eor #$FF
	and kvl+5
	sta kkp+5
	lda $1A00
	sta out+11
	eor #$FF
	and kvh+5
	sta kkp+13
	lda #1
	sta kgyt+1
	lda t0
	bra .u5
.z5:	stz kD+5
	stz out+10
	stz out+11
	lda kvl+5
	sta kkp+5
	lda kvh+5
	sta kkp+13
	lda kn+5
.u5:	clc
	adc units+5
	kmxu .v5, .w5
	lda #16
	sec
	sbc units+6
	bcs .a6
	cla
.a6:	sta t0
	sec
	sbc kn+6
	bcs .z6
	eor #$FF
	inc a
	sta kD+6
	clc
	adc ksumd
	sta ksumd
	lda kD+6
	asl a
	adc #$BE
	sta $1A02
	lda $1A00
	sta out+12
	eor #$FF
	and kvl+6
	sta kkp+6
	lda $1A00
	sta out+13
	eor #$FF
	and kvh+6
	sta kkp+14
	lda #1
	sta kgyt+1
	lda t0
	bra .u6
.z6:	stz kD+6
	stz out+12
	stz out+13
	lda kvl+6
	sta kkp+6
	lda kvh+6
	sta kkp+14
	lda kn+6
.u6:	clc
	adc units+6
	kmxu .v6, .w6
	lda #16
	sec
	sbc units+7
	bcs .a7
	cla
.a7:	sta t0
	sec
	sbc kn+7
	bcs .z7
	eor #$FF
	inc a
	sta kD+7
	clc
	adc ksumd
	sta ksumd
	lda kD+7
	asl a
	adc #$DE
	sta $1A02
	lda $1A00
	sta out+14
	eor #$FF
	and kvl+7
	sta kkp+7
	lda $1A00
	sta out+15
	eor #$FF
	and kvh+7
	sta kkp+15
	lda #1
	sta kgyt+1
	lda t0
	bra .u7
.z7:	stz kD+7
	stz out+14
	stz out+15
	lda kvl+7
	sta kkp+7
	lda kvh+7
	sta kkp+15
	lda kn+7
.u7:	clc
	adc units+7
	kmxu .v7, .w7
	.if FOLD
	stz kforce              ; a band whose D is past its blocks before the staircase blocks (kb3): a staircase block is left out
	lda npark               ; (asked only with an entry parked and a block left out)
	beq .fx
	lda ksumd
	beq .fx
	lda kb3+0
	cmp kD+0
	bcc .ff
	lda kb3+1
	cmp kD+1
	bcc .ff
	lda kb3+2
	cmp kD+2
	bcc .ff
	lda kb3+3
	cmp kD+3
	bcc .ff
	lda kb3+4
	cmp kD+4
	bcc .ff
	lda kb3+5
	cmp kD+5
	bcc .ff
	lda kb3+6
	cmp kD+6
	bcc .ff
	lda kb3+7
	cmp kD+7
	bcs .fx
.ff:	inc kforce
.fx:
	.endif
	lda ksumd
	clc
	adc nleft
	sta nleft
	lda nleft+1
	adc #0
	sta nleft+1
	rts
	.endif
	.if WAL = 0
; the group masks: a half with a band left out transposed from keep, else the record's
kgm:	lda kgyt
	beq .v0
	jsr ktr0                ; (count: half transposed)
	bra .g1
.v0:	tii kgv, gm, 8
.g1:	lda kgyt+1
	beq .v1
	jsr ktr1
	bra .x
.v1:	tii kgv + 8, gm + 8, 8
.x:	jmp kg0
ktr0:	clx
	cly
	jsr ktr
	ldx #8
	ldy #4
	jmp ktr
ktr1:	ldx #4
	ldy #8
	jsr ktr
	ldx #12
	ldy #12
	jmp ktr
kg0:	lda gm
	and #$0F
	sta gma
	lda gm
	lsr a
	lsr a
	lsr a
	lsr a
	sta gmb
	rts
; four bands' keep bytes (kkp + X .. + 3) -> four groups (gm + Y .. + 3): group pair j of band r -> bits 2 r, 2 r + 1
ktr:	lda kkp,x
	and #$33
	sta t0
	lda kkp+1,x
	and #$33
	asl a
	asl a
	ora t0
	sta t1                  ; pairs 0 / 2 of rows 0-1
	lda kkp,x
	and #$CC
	lsr a
	lsr a
	sta t0
	lda kkp+1,x
	and #$CC
	ora t0
	sta t2                  ; pairs 1 / 3 of rows 0-1
	lda kkp+2,x
	and #$33
	sta t0
	lda kkp+3,x
	and #$33
	asl a
	asl a
	ora t0
	sta t3                  ; pairs 0 / 2 of rows 2-3
	lda kkp+2,x
	and #$CC
	lsr a
	lsr a
	sta t0
	lda kkp+3,x
	and #$CC
	ora t0
	sta t4                  ; pairs 1 / 3 of rows 2-3
	lda t3
	asl a
	asl a
	asl a
	asl a
	sta t0
	lda t1
	and #$0F
	ora t0
	sta gm+0,y
	lda t1
	lsr a
	lsr a
	lsr a
	lsr a
	sta t0
	lda t3
	and #$F0
	ora t0
	sta gm+2,y
	lda t4
	asl a
	asl a
	asl a
	asl a
	sta t0
	lda t2
	and #$0F
	ora t0
	sta gm+1,y
	lda t2
	lsr a
	lsr a
	lsr a
	lsr a
	sta t0
	lda t4
	and #$F0
	ora t0
	sta gm+3,y
	rts
; our entries: the sum of the 17 pseudo-groups' piece counts
kcount:	clc
	ldx gma
	lda ktcnt-KTD,x
	ldx gmb
	adc ktcnt-KTD,x
	ldx gm+1
	adc ktcnt-KTD,x
	ldx gm+2
	adc ktcnt-KTD,x
	ldx gm+3
	adc ktcnt-KTD,x
	ldx gm+4
	adc ktcnt-KTD,x
	ldx gm+5
	adc ktcnt-KTD,x
	ldx gm+6
	adc ktcnt-KTD,x
	ldx gm+7
	adc ktcnt-KTD,x
	ldx gm+8
	adc ktcnt-KTD,x
	ldx gm+9
	adc ktcnt-KTD,x
	ldx gm+10
	adc ktcnt-KTD,x
	ldx gm+11
	adc ktcnt-KTD,x
	ldx gm+12
	adc ktcnt-KTD,x
	ldx gm+13
	adc ktcnt-KTD,x
	ldx gm+14
	adc ktcnt-KTD,x
	ldx gm+15
	adc ktcnt-KTD,x
	sta kne
	rts

kdrop:
.c16:	ldx gm+15
	lda ktcnt-KTD,x
	beq .e16                  ; (count: dchk, the groups looked at)
	sta t5
	ldx #16
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e16
	jmp .x
.e16:
.c15:	ldx gm+14
	lda ktcnt-KTD,x
	beq .e15
	sta t5
	ldx #15
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e15
	jmp .x
.e15:
.c14:	ldx gm+13
	lda ktcnt-KTD,x
	beq .e14
	sta t5
	ldx #14
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e14
	jmp .x
.e14:
.c13:	ldx gm+12
	lda ktcnt-KTD,x
	beq .e13
	sta t5
	ldx #13
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e13
	jmp .x
.e13:
.c12:	ldx gm+11
	lda ktcnt-KTD,x
	beq .e12
	sta t5
	ldx #12
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e12
	jmp .x
.e12:
.c11:	ldx gm+10
	lda ktcnt-KTD,x
	beq .e11
	sta t5
	ldx #11
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e11
	jmp .x
.e11:
.c10:	ldx gm+9
	lda ktcnt-KTD,x
	beq .e10
	sta t5
	ldx #10
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e10
	jmp .x
.e10:
.c9:	ldx gm+8
	lda ktcnt-KTD,x
	beq .e9
	sta t5
	ldx #9
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e9
	jmp .x
.e9:
.c8:	ldx gm+7
	lda ktcnt-KTD,x
	beq .e8
	sta t5
	ldx #8
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e8
	jmp .x
.e8:
.c7:	ldx gm+6
	lda ktcnt-KTD,x
	beq .e7
	sta t5
	ldx #7
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e7
	jmp .x
.e7:
.c6:	ldx gm+5
	lda ktcnt-KTD,x
	beq .e6
	sta t5
	ldx #6
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e6
	jmp .x
.e6:
.c5:	ldx gm+4
	lda ktcnt-KTD,x
	beq .e5
	sta t5
	ldx #5
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e5
	jmp .x
.e5:
.c4:	ldx gm+3
	lda ktcnt-KTD,x
	beq .e4
	sta t5
	ldx #4
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e4
	jmp .x
.e4:
.c3:	ldx gm+2
	lda ktcnt-KTD,x
	beq .e3
	sta t5
	ldx #3
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e3
	jmp .x
.e3:
.c2:	ldx gm+1
	lda ktcnt-KTD,x
	beq .e2
	sta t5
	ldx #2
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e2
	jmp .x
.e2:
.c1:	ldx gmb
	lda ktcnt-KTD,x
	beq .e1
	sta t5
	ldx #1
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e1
	jmp .x
.e1:
.c0:	ldx gma
	lda ktcnt-KTD,x
	beq .e0
	sta t5
	ldx #0
	jsr kdrop1
	lda kne
	clc
	adc kgn
	cmp #65
	bcs .e0
	jmp .x
.e0:
.x:	lda kne
	rts
; pseudo-group X (t5 pieces) left out: its blocks into out, nover; emptied (count: drop)
kdrop1:	stx t6                  ; its blocks (group g's mask bits) left out: out of their bands; the pseudo-group emptied
	lda kpgg,x
	sta t7                  ; g
	cpx #2
	bcs .g
	lda gm                  ; (group 0: its upper or lower two block rows)
	and kpgm,x
	sta t0
	stz gma,x
	bra .o
.g:	ldx t7
	lda gm,x
	sta t0
	stz gm,x
.o:	ldx t0
	lda kpop,x              ; (nover: the blocks left out for the limit)
	clc
	adc nover
	sta nover
	lda nover+1
	adc #0
	sta nover+1
	lda t7
	and #3
	asl a
	asl a
	sta t2                  ; 4 (gx & 3): kpv's row
	lda t7
	asl a
	asl a
	sta t1                  ; 4 g: koi's row
	lda t0
	and #3
	ora t2
	tax
	lda kpv,x
	sta t3
	ldy t1
	lda koi+0,y
	tax
	lda t3
	ora out,x
	sta out,x
	.if UPF
	lda t3
	ora ff,x
	sta ff,x
	.endif
	lsr t0
	lsr t0
	lda t0
	and #3
	ora t2
	tax
	lda kpv,x
	sta t3
	ldy t1
	lda koi+1,y
	tax
	lda t3
	ora out,x
	sta out,x
	.if UPF
	lda t3
	ora ff,x
	sta ff,x
	.endif
	lsr t0
	lsr t0
	lda t0
	and #3
	ora t2
	tax
	lda kpv,x
	sta t3
	ldy t1
	lda koi+2,y
	tax
	lda t3
	ora out,x
	sta out,x
	.if UPF
	lda t3
	ora ff,x
	sta ff,x
	.endif
	lsr t0
	lsr t0
	lda t0
	and #3
	ora t2
	tax
	lda kpv,x
	sta t3
	ldy t1
	lda koi+3,y
	tax
	lda t3
	ora out,x
	sta out,x
	.if UPF
	lda t3
	ora ff,x
	sta ff,x
	.endif
	lda kne                 ; (our entries less the group's)
	sec
	sbc t5
	sta kne
	rts
kpgg:	.db 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15     ; pseudo-group -> group
kpgm:	.db $0F, $F0                                                       ; group 0's halves' bits
kpv:	.db $00, $01, $02, $03, $00, $04, $08, $0C, $00, $10, $20, $30, $00, $40, $80, $C0    ; pair p of group column j (gx & 3) in its band byte
koi:	.db 0, 2, 4, 6, 0, 2, 4, 6, 0, 2, 4, 6, 0, 2, 4, 6, 1, 3, 5, 7, 1, 3, 5, 7, 1, 3, 5, 7, 1, 3, 5, 7, 8, 10, 12, 14, 8, 10, 12, 14, 8, 10, 12, 14, 8, 10, 12, 14, 9, 11, 13, 15, 9, 11, 13, 15, 9, 11, 13, 15, 9, 11, 13, 15    ; group g, row r: out's byte
	.endif

wx0l:	.db $30, $40, $50, $60, $70, $80, $90, $A0, $B0, $C0, $D0, $E0, $F0, $00, $10, $20
wx0h:	.db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01
wp0l:	.db $68, $6A, $10, $12, $20, $22, $30, $32, $40, $42, $50, $52, $60, $62, $70, $72
wp0bl:	.db $F8, $FA
wp1l:	.db $80, $82, $90, $92, $A0, $A2, $B0, $B2, $C0, $C2, $D0, $D2, $E0, $E2, $F0, $F2

kemit:	lda kgn
	sta t6
	jsr ksatm
	.if WAL
	ldx #0
.e0:	cpx wn0
	bcs .s1
	ldy wcol0,x
	cpy #2
	bcc .y01
	sei
	st1 #$58
	st2 #$00
	lda wx0l,y
	sta $0002
	lda wx0h,y
	sta $0003
	lda wp0l,y
	sta $0002
	st2 #$03
	st1 #$04
	st2 #$30
	cli
	inx
	bra .e0
.y01:	sei
	st1 #$58
	st2 #$00
	lda wx0l,y
	sta $0002
	st2 #$00
	lda wp0l,y
	sta $0002
	st2 #$00
	st1 #$04
	st2 #$10
	st1 #$78
	st2 #$00
	lda wx0l,y
	sta $0002
	st2 #$00
	lda wp0bl,y
	sta $0002
	st2 #$02
	st1 #$04
	st2 #$10
	cli
	inx
	bra .e0
.s1:	ldx #0
.e1:	cpx wn1
	bcs .s16
	ldy wcol1,x
	sei
	st1 #$98
	st2 #$00
	lda wx0l,y
	sta $0002
	lda wx0h,y
	sta $0003
	lda wp1l,y
	sta $0002
	st2 #$03
	st1 #$04
	st2 #$30
	cli
	inx
	bra .e1
.s16:
	.else
	lda #$40
	tam #4
	lda #$0C
	sta $1A04
	ldx gma
	ldy ktcnt-KTD,x
	beq .s0
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	sta $1A03
	cpy #5                  ; (count: group)
	bcs .w0
	lda kt8-KTD,y
	sta .t0+5
.t0:	tia $8000, $0002, 8
	bra .s0
.w0:	tia $8000, $0002, 32    ; (count: group of 5-8)
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u0+5
.u0:	tia $8000, $0002, 8
.s0:
	ldx gmb
	ldy ktcnt-KTD,x
	beq .s1
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$20
	sta $1A03
	cpy #5
	bcs .w1
	lda kt8-KTD,y
	sta .t1+5
.t1:	tia $8000, $0002, 8
	bra .s1
.w1:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u1+5
.u1:	tia $8000, $0002, 8
.s1:
	ldx gm+1
	ldy ktcnt-KTD,x
	beq .s2
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$40
	sta $1A03
	cpy #5
	bcs .w2
	lda kt8-KTD,y
	sta .t2+5
.t2:	tia $8000, $0002, 8
	bra .s2
.w2:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u2+5
.u2:	tia $8000, $0002, 8
.s2:
	ldx gm+2
	ldy ktcnt-KTD,x
	beq .s3
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$60
	sta $1A03
	cpy #5
	bcs .w3
	lda kt8-KTD,y
	sta .t3+5
.t3:	tia $8000, $0002, 8
	bra .s3
.w3:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u3+5
.u3:	tia $8000, $0002, 8
.s3:
	ldx gm+3
	ldy ktcnt-KTD,x
	beq .s4
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$80
	sta $1A03
	cpy #5
	bcs .w4
	lda kt8-KTD,y
	sta .t4+5
.t4:	tia $8000, $0002, 8
	bra .s4
.w4:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u4+5
.u4:	tia $8000, $0002, 8
.s4:
	ldx gm+4
	ldy ktcnt-KTD,x
	beq .s5
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$A0
	sta $1A03
	cpy #5
	bcs .w5
	lda kt8-KTD,y
	sta .t5+5
.t5:	tia $8000, $0002, 8
	bra .s5
.w5:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u5+5
.u5:	tia $8000, $0002, 8
.s5:
	ldx gm+5
	ldy ktcnt-KTD,x
	beq .s6
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$C0
	sta $1A03
	cpy #5
	bcs .w6
	lda kt8-KTD,y
	sta .t6+5
.t6:	tia $8000, $0002, 8
	bra .s6
.w6:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u6+5
.u6:	tia $8000, $0002, 8
.s6:
	ldx gm+6
	ldy ktcnt-KTD,x
	beq .s7
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$E0
	sta $1A03
	cpy #5
	bcs .w7
	lda kt8-KTD,y
	sta .t7+5
.t7:	tia $8000, $0002, 8
	bra .s7
.w7:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u7+5
.u7:	tia $8000, $0002, 8
.s7:
	lda #$0D
	sta $1A04
	ldx gm+7
	ldy ktcnt-KTD,x
	beq .s8
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	sta $1A03
	cpy #5
	bcs .w8
	lda kt8-KTD,y
	sta .t8+5
.t8:	tia $8000, $0002, 8
	bra .s8
.w8:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u8+5
.u8:	tia $8000, $0002, 8
.s8:
	ldx gm+8
	ldy ktcnt-KTD,x
	beq .s9
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$20
	sta $1A03
	cpy #5
	bcs .w9
	lda kt8-KTD,y
	sta .t9+5
.t9:	tia $8000, $0002, 8
	bra .s9
.w9:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u9+5
.u9:	tia $8000, $0002, 8
.s9:
	ldx gm+9
	ldy ktcnt-KTD,x
	beq .s10
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$40
	sta $1A03
	cpy #5
	bcs .w10
	lda kt8-KTD,y
	sta .t10+5
.t10:	tia $8000, $0002, 8
	bra .s10
.w10:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u10+5
.u10:	tia $8000, $0002, 8
.s10:
	ldx gm+10
	ldy ktcnt-KTD,x
	beq .s11
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$60
	sta $1A03
	cpy #5
	bcs .w11
	lda kt8-KTD,y
	sta .t11+5
.t11:	tia $8000, $0002, 8
	bra .s11
.w11:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u11+5
.u11:	tia $8000, $0002, 8
.s11:
	ldx gm+11
	ldy ktcnt-KTD,x
	beq .s12
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$80
	sta $1A03
	cpy #5
	bcs .w12
	lda kt8-KTD,y
	sta .t12+5
.t12:	tia $8000, $0002, 8
	bra .s12
.w12:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u12+5
.u12:	tia $8000, $0002, 8
.s12:
	ldx gm+12
	ldy ktcnt-KTD,x
	beq .s13
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$A0
	sta $1A03
	cpy #5
	bcs .w13
	lda kt8-KTD,y
	sta .t13+5
.t13:	tia $8000, $0002, 8
	bra .s13
.w13:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u13+5
.u13:	tia $8000, $0002, 8
.s13:
	ldx gm+13
	ldy ktcnt-KTD,x
	beq .s14
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$C0
	sta $1A03
	cpy #5
	bcs .w14
	lda kt8-KTD,y
	sta .t14+5
.t14:	tia $8000, $0002, 8
	bra .s14
.w14:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u14+5
.u14:	tia $8000, $0002, 8
.s14:
	ldx gm+14
	ldy ktcnt-KTD,x
	beq .s15
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	ora #$E0
	sta $1A03
	cpy #5
	bcs .w15
	lda kt8-KTD,y
	sta .t15+5
.t15:	tia $8000, $0002, 8
	bra .s15
.w15:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u15+5
.u15:	tia $8000, $0002, 8
.s15:
	lda #$0E
	sta $1A04
	ldx gm+15
	ldy ktcnt-KTD,x
	beq .s16
	lda koffl-KTD,x
	sta $1A02
	lda koffh-KTD,x
	sta $1A03
	cpy #5
	bcs .w16
	lda kt8-KTD,y
	sta .t16+5
.t16:	tia $8000, $0002, 8
	bra .s16
.w16:	tia $8000, $0002, 32
	tya
	sec
	sbc #4
	asl a
	asl a
	asl a
	sta .u16+5
.u16:	tia $8000, $0002, 8
.s16:
	lda #DB_K
	tam #4
	.endif
	lda kgn
	clc
	adc kne
	sta t6
	ldx kpg
	lda ourend,x
	sec
	sbc t6
	bcc .m
	beq .m
	tax
.zl:	sei
	st1 #0
	st2 #0
	st1 #0
	st2 #0
	st1 #0
	st2 #0
	st1 #0
	st2 #0
	cli
	dex
	bne .zl
.m:	ldx kpg
	lda kgn
	sta ourst,x
	lda t6
	sta ourend,x
	cmp emax
	bcc .vv
	sta emax
	bra .ww
.vv:	sta t8
	nop
.ww:	stz t6
	jsr ksatm
	lda mnib+0
	asl a
	asl a
	asl a
	sta .k0+1
	lda kmtp
	sta .k0+2
.k0:	tia $8000, $0002, 8
	lda mnib+1
	asl a
	asl a
	asl a
	ora #$80
	sta .k1+1
	lda kmtp
	sta .k1+2
.k1:	tia $8000, $0002, 8
	lda mnib+2
	asl a
	asl a
	asl a
	sta .k2+1
	lda kmtp
	inc a
	sta .k2+2
.k2:	tia $8000, $0002, 8
	lda mnib+3
	asl a
	asl a
	asl a
	ora #$80
	sta .k3+1
	lda kmtp
	inc a
	sta .k3+2
.k3:	tia $8000, $0002, 8
	rts
ksatm:	lda t6
	asl a
	asl a
	ldx c5satpg
	jmp vmawr
	.if WAL
wtab0:	.db $58, $00, $30, $00, $68, $00, $04, $10 ; srow 0 col 0 upper 16x32
	.db $58, $00, $40, $00, $6A, $00, $04, $10 ; srow 0 col 1 upper 16x32
	.db $58, $00, $50, $00, $10, $03, $04, $30 ; srow 0 col 2 16x64
	.db $58, $00, $60, $00, $12, $03, $04, $30 ; srow 0 col 3 16x64
	.db $58, $00, $70, $00, $20, $03, $04, $30 ; srow 0 col 4 16x64
	.db $58, $00, $80, $00, $22, $03, $04, $30 ; srow 0 col 5 16x64
	.db $58, $00, $90, $00, $30, $03, $04, $30 ; srow 0 col 6 16x64
	.db $58, $00, $A0, $00, $32, $03, $04, $30 ; srow 0 col 7 16x64
	.db $58, $00, $B0, $00, $40, $03, $04, $30 ; srow 0 col 8 16x64
	.db $58, $00, $C0, $00, $42, $03, $04, $30 ; srow 0 col 9 16x64
	.db $58, $00, $D0, $00, $50, $03, $04, $30 ; srow 0 col 10 16x64
	.db $58, $00, $E0, $00, $52, $03, $04, $30 ; srow 0 col 11 16x64
	.db $58, $00, $F0, $00, $60, $03, $04, $30 ; srow 0 col 12 16x64
	.db $58, $00, $00, $01, $62, $03, $04, $30 ; srow 0 col 13 16x64
	.db $58, $00, $10, $01, $70, $03, $04, $30 ; srow 0 col 14 16x64
	.db $58, $00, $20, $01, $72, $03, $04, $30 ; srow 0 col 15 16x64
wtab0b:	.db $78, $00, $30, $00, $F8, $02, $04, $10 ; srow 0 col 0 lower 16x32
	.db $78, $00, $40, $00, $FA, $02, $04, $10 ; srow 0 col 1 lower 16x32
wtab1:	.db $98, $00, $30, $00, $80, $03, $04, $30 ; srow 1 col 0 16x64
	.db $98, $00, $40, $00, $82, $03, $04, $30 ; srow 1 col 1 16x64
	.db $98, $00, $50, $00, $90, $03, $04, $30 ; srow 1 col 2 16x64
	.db $98, $00, $60, $00, $92, $03, $04, $30 ; srow 1 col 3 16x64
	.db $98, $00, $70, $00, $A0, $03, $04, $30 ; srow 1 col 4 16x64
	.db $98, $00, $80, $00, $A2, $03, $04, $30 ; srow 1 col 5 16x64
	.db $98, $00, $90, $00, $B0, $03, $04, $30 ; srow 1 col 6 16x64
	.db $98, $00, $A0, $00, $B2, $03, $04, $30 ; srow 1 col 7 16x64
	.db $98, $00, $B0, $00, $C0, $03, $04, $30 ; srow 1 col 8 16x64
	.db $98, $00, $C0, $00, $C2, $03, $04, $30 ; srow 1 col 9 16x64
	.db $98, $00, $D0, $00, $D0, $03, $04, $30 ; srow 1 col 10 16x64
	.db $98, $00, $E0, $00, $D2, $03, $04, $30 ; srow 1 col 11 16x64
	.db $98, $00, $F0, $00, $E0, $03, $04, $30 ; srow 1 col 12 16x64
	.db $98, $00, $00, $01, $E2, $03, $04, $30 ; srow 1 col 13 16x64
	.db $98, $00, $10, $01, $F0, $03, $04, $30 ; srow 1 col 14 16x64
	.db $98, $00, $20, $01, $F2, $03, $04, $30 ; srow 1 col 15 16x64
	.endif

	.if PBX
wbx:	rts                     ; (r19-plug-bitmap: the BAT fix-up and its class rows are not built: the plug writes every cell they wrote)
	.else
; ---------------------------------------------------------------- the BAT fix-up (slice 0's, apart from the bar)
; ---------------------------------------------------------------- the backdrop class of this pass's 16 x 32 cells: rows (16 x 4 bytes,
getrows:	lda p0l                 ; (the same camera cell as the last pass: the rows are as they were)
	cmp lp0l
	bne .g
	lda p0h
	cmp lp0h
	bne .g
	rts
.g:
	lda p0l
	sta lp0l
	lda p0h
	sta lp0h
	tma #4
	pha
	lda #DB_CLS
	tam #4
	lda p0l
	sta t0
	lda p0h
	and #$0F
	sta t1
	lda t0                  ; s = idx & 7: page $80 + 4 s; k = idx >> 3
	and #7
	asl a
	asl a
	ora #$80
	sta t2
	lsr t1
	ror t0
	lsr t1
	ror t0
	lsr t1
	ror t0
	lda t1
	clc
	adc t2
	sta t1
	lda t0
	sta .a0+1
	lda t1
	sta .a0+2
	inc t0
	bne .n1
	inc t1
.n1:	lda t0
	sta .a1+1
	lda t1
	sta .a1+2
	inc t0
	bne .n2
	inc t1
.n2:	lda t0
	sta .a2+1
	lda t1
	sta .a2+2
	inc t0
	bne .n3
	inc t1
.n3:	lda t0
	sta .a3+1
	lda t1
	sta .a3+2
	clx
	cly
.r:
.a0:	lda $8000,y
	sta rows,x
.a1:	lda $8000,y
	sta rows+1,x
.a2:	lda $8000,y
	sta rows+2,x
.a3:	lda $8000,y
	sta rows+3,x
	tya
	clc
	adc #8
	tay
	inx                     ; (four INX, not TXA / CLC / ADC #: those three bytes are also the start of the mid path's site, and the
	inx                     ;  sector scan wants no run of any site's bytes in the module's sectors)
	inx
	inx
	cpx #64
	bne .r
	pla
	tam #4
	rts

wbat:	jsr getrows             ; the camera cell's class rows (only the fix-up reads them)
	tma #4
	pha
	lda #DB_SW
	tam #4
	lda obi
	asl a
	asl a
	asl a
	asl a
	sta t2                  ; (this buffer's bout)
	clx
.b:	stx t6
	txa
	asl a
	tay
	clc
	adc t2
	tax
	lda out,y
	sta ocur                ; (the pass's copy of out, shifted with the diff)
	eor bout,x
	sta t0
	lda out,y
	sta bout,x
	lda out+1,y
	sta ocur+1
	eor bout+1,x
	sta t1
	lda out+1,y
	sta bout+1,x
	lda t0
	ora t1
	bne .j2208
	jmp .nb
.j2208:
	.if FOLD
	lda t6                  ; (wblk's eight reads of the screen's backdrop words: their page, $80 + this band's rows >> 2, set when it changes)
	lsr a
	ora #$80
	cmp wpg
	beq .pg
	sta wpg
	sta wbp0+2
	sta wbp1+2
	sta wbp2+2
	sta wbp3+2
	sta wbq0+2
	sta wbq1+2
	sta wbq2+2
	sta wbq3+2
.pg:
	.endif
	stz wh                  ; 0: blocks 0-7 (the low bytes); 8: blocks 8-15
.by:	lda wh
	beq .lo
	lda t1
	sta t0
	lda ocur+1
	sta ocur
.lo:	lda t0
	bne .bi
	jmp .nby
.bi:	ldx t0
	lda klsb,x
	sta wm
	eor t0
	sta t0
	ldx wm
	dex
	lda kpop,x
	clc
	adc wh
	tay                     ; the block (0-15)
	cla
	ldx ocur
	stx wmode               ; (scratch)
	lda wm
	and wmode
	beq .w0
	lda #1
.w0:	sta wmode               ; (1: left out now)
.go:	sty t7                  ; block (t6, t7): rows 2 t6 + rr, cells X = 2 t7 + cc
	tya                     ; rows byte: 8 t6 + (bi >> 2) (+ 4 for the second row)
	lsr a
	lsr a
	sta t2+1
	lda t6
	asl a
	asl a
	asl a
	clc
	adc t2+1
	tax
	tya
	and #3
	tay                     ; field t
	lda rows,x
	and pmask,y
	sta t8                  ; row 2 bj's two cells
	lda rows+4,x
	and pmask,y
	sta t5                  ; row 2 bj + 1's
	lda t6
	asl a
	sta t9                  ; row
	lda t7
	asl a
	sta t3                  ; X = 2 bi
	.if FOLD
	lda wmode
	beq .ob
	lda t8
	and t5
	cmp pmask,y
	bne .ob
	jsr wblk
	jmp .c4
.ob:
	.endif
	lda t8
	cmp pmask,y
	bne .s1
	jsr wsw2
	inc t3
	bra .c2
.s1:	and lbit,y
	beq .c1
	jsr wsw
.c1:	inc t3
	lda t8
	and rbit,y
	beq .c2
	jsr wsw
.c2:	inc t9
	dec t3
	lda t5
	cmp pmask,y
	bne .s3
	jsr wsw2
	inc t3
	bra .c4
.s3:	and lbit,y
	beq .c3
	jsr wsw
.c3:	inc t3
	lda t5
	and rbit,y
	beq .c4
	jsr wsw
.c4:
	lda t0
	beq .nby
	jmp .bi
.nby:	lda wh
	bne .nb
	lda #8
	sta wh
	jmp .by
.nb:	ldx t6
	inx
	cpx #8
	beq .x
	jmp .b
.x:	pla
	tam #4
	rts
	.if FOLD
wblk:	lda t9
	clc
	.if RSLACK
	adc rbe
	.else
	adc rb
	.endif
	sta t8
	tax
	lda t3
	clc
	.if RSLACK
	adc cbe
	.else
	adc #2
	.endif
	sta t4
	sei
	st0 #0
	ora r64l,x
	sta $0002
	lda r64h,x
	sta $0003
	st0 #2
	ldx t9
	lda t3
	asl a
	ora r64l,x
	tax
wbp0:	lda $8000,x
	sta $0002
wbp1:	lda $8001,x
	sta $0003
wbp2:	lda $8002,x
	sta $0002
wbp3:	lda $8003,x
	sta $0003
	cli
	ldx t8
	sei
	st0 #0
	lda t4
	ora r64l+1,x
	sta $0002
	lda r64h+1,x
	sta $0003
	st0 #2
	ldx t9
	lda t3
	asl a
	ora r64l+1,x
	tax
wbq0:	lda $8000,x
	sta $0002
wbq1:	lda $8001,x
	sta $0003
wbq2:	lda $8002,x
	sta $0002
wbq3:	lda $8003,x
	sta $0003
	cli
	rts
wpg:	.db 0           ; the page wblk's reads are set to
	.endif
wsw:	ldx t9
	lda r64l,x
	sta t4
	lda t3
	asl a
	ora t4
	sta .w+1
	inc a
	sta .h+1
	lda r64h,x
	ora #$80
	sta .w+2
	sta .h+2
	txa
	clc
	.if RSLACK
	adc rbe
	.else
	adc rb
	.endif
	tax
	lda t3
	clc
	.if RSLACK
	adc cbe
	.else
	adc #2
	.endif
	ora r64l,x
	stz <VDCREG
	st0 #0
	sta $0002
	lda r64h,x
	sta $0003
	lda #2
	sta <VDCREG
	st0 #2
	lda wmode
	beq .t
.w:	lda $8000
	sta $0002
.h:	lda $8001
	sta $0003
	rts
	.if FOLD
.t:	ldx t9                  ; the cell's own S word (a staircase cell's tile word, else the transparent word): of its near byte, at
	lda r64l,x              ; p0 + 64 row + X in the near map's copy (KSWL / KSWH: kscr)
	ora t3
	clc
	adc p0l
	sta .n+1
	lda r64h,x
	adc kq0h
	sta .n+2
.n:	ldx $6000
	lda KSWL,x
	sta $0002
	lda KSWH,x
	sta $0003
	rts
	.else
.t:	st1 #$C5
	st2 #0
	rts
	.endif
; BAT cells (rb + row t9, columns 2 + t3 and 3 + t3): both words in one address set (wmode 1: SW[t9][t3] and [t3 + 1] in one 4-byte
; move; 0: the transparent word twice). X and A lost, Y kept.
wsw2:	lda t9
	clc
	.if RSLACK
	adc rbe
	.else
	adc rb
	.endif
	tax
	lda t3
	clc
	.if RSLACK
	adc cbe
	.else
	adc #2
	.endif
	ora r64l,x
	stz <VDCREG
	st0 #0
	sta $0002
	lda r64h,x
	sta $0003
	lda #2
	sta <VDCREG
	st0 #2
	lda wmode
	beq .t
	ldx t9
	lda t3
	asl a
	ora r64l,x
	sta .w+1
	lda r64h,x
	ora #$80
	sta .w+2
.w:	tia $8000, $0002, 4
	rts
	.if FOLD
.t:	ldx t9                  ; (the two cells' own S words, as wsw)
	lda r64l,x
	ora t3
	clc
	adc p0l
	sta .n+1
	sta .o+1
	lda r64h,x
	adc kq0h
	sta .n+2
	sta .o+2
	inc .o+1
	bne .n
	inc .o+2
.n:	ldx $6000
	lda KSWL,x
	sta $0002
	lda KSWH,x
	sta $0003
.o:	ldx $6000
	lda KSWL,x
	sta $0002
	lda KSWH,x
	sta $0003
	rts
	.else
.t:	st1 #$C5
	st2 #0
	st1 #$C5
	st2 #0
	rts
	.endif
	.endif
	.include "shaft19_x9.inc"
	.if PLG
xcell:	txa
	and #3
	beq .f
	jmp .q
.f:	stx xcil
	sty xcih
	stz xckp
	lda t3                  ; MARR = the tile * 16
	sta xcth
	lda t2
	asl a
	rol xcth
	asl a
	rol xcth
	asl a
	rol xcth
	asl a
	rol xcth
	ldx xcth
	jsr vmarr
	tai $0002, xcbuf, 8     ; (eight bytes a block, as rdbuf: the interrupts wait no longer than there)
	tai $0002, xcbuf + 8, 8
	tai $0002, xcbuf + 16, 8
	tai $0002, xcbuf + 24, 8
	tai $0002, xcbuf + 32, 8
	tai $0002, xcbuf + 40, 8
	tai $0002, xcbuf + 48, 8
	tai $0002, xcbuf + 56, 8
	tai $0002, xcbuf + 64, 8
	tai $0002, xcbuf + 72, 8
	tai $0002, xcbuf + 80, 8
	tai $0002, xcbuf + 88, 8
	tai $0002, xcbuf + 96, 8
	tai $0002, xcbuf + 104, 8
	tai $0002, xcbuf + 112, 8
	tai $0002, xcbuf + 120, 8
	lda #2
	sta $1A04
	lda xcil
	asl a
	asl a
	asl a
	asl a
	asl a
	sta $1A02
	lda xcih
	asl a
	asl a
	asl a
	asl a
	asl a
	sta xcth
	lda xcil
	lsr a
	lsr a
	lsr a
	ora xcth
	sta $1A03
	clx
.c:	lda xcbuf,x
	cmp $1A00
	bne .k
	inx
	bpl .c
	bra .q
.k:	inc xckp
.q:	ldx #2
	lda xckp
	beq .r
	dex
.r:	rts
xcil:	.db 0
xcih:	.db 0
xcth:	.db 0
xckp:	.db 0
xcbuf:	.ds 128
	.endif
r64l:	.db $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0, $00, $40, $80, $C0
r64h:	.db 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8
pmask:	.db $C0, $30, $0C, $03
lbit:	.db $80, $20, $08, $02
rbit:	.db $40, $10, $04, $01

	.if HUDS
HTAIL      = $4B4E
HCALL      = $4AFA
hudin:	ldx #8
.c:	lda HTAIL,x
	sta htmp,x
	dex
	bpl .c
	jsr hsum
	bne .x
	lda #<HCALL
	ldy #>HCALL
	ldx #16
	jsr fsum
	lda t2
	cmp chud2
	bne .x
	lda t3
	cmp chud2+1
	bne .x
	ldx #18
.s:	lda HCALL,x
	sta hgs,x
	dex
	bpl .s
	lda hgs
	sta hours
	lda hgs+1
	sta hours+1
	ldx #6
.t:	lda hgs+2,x
	sta hours+5,x
	dex
	bpl .t
	lda hgs+9
	sta hours+12
	lda hgs+10
	sta hours+13
	lda $2212
	sta hours+15
	lda $2213
	sta hours+17
	lda hgs+18
	sta hours+18
	ldy #8
	php
	sei
.w:	ldx hpin,y
	lda htmp,x
	sta HTAIL,y
	dey
	bpl .w
	ldx #18
.v:	lda hours,x
	sta HCALL,x
	dex
	bpl .v
	plp
.x:	lda #20                 ; (bank 4) xset2, the caller's call
	jmp cold4
hudout:	php
	sei
	ldx #18
.c:	lda HCALL,x
	cmp hours,x
	bne .t
	dex
	bpl .c
	ldx #18
.w:	lda hgs,x
	sta HCALL,x
	dex
	bpl .w
.t:	ldy #8
.u:	ldx hpout,y
	lda HTAIL,x
	sta htmp,y
	dey
	bpl .u
	jsr hsum
	bne .x
	ldx #8
.v:	lda htmp,x
	sta HTAIL,x
	dex
	bpl .v
.x:	plp
	lda #14
	jmp cold4
hsum:	lda #<htmp
	ldy #>htmp
	ldx #9
	jsr fsum
	lda t2
	cmp chud
	bne .x
	lda t3
	cmp chud+1
.x:	rts
hpin:	.db 3, 4, 5, 0, 1, 2, 6, 7, 8
hpout:	.db 3, 4, 5, 0, 1, 2, 6, 7, 8
htmp:	.ds 9
hgs:	.ds 19
hours:	.db 0, 0, $20, <(HTAIL + 5), >(HTAIL + 5), 0, 0, 0, 0, 0, 0, 0, 0, 0, $13, 0, $23, 0, 0   ; ours (JSR, ST1, ST2: the CPU's opcodes)
	.endif

; satc (bank 3, cold3 entry 29): pend != 0 and eng == 0. Carry set: stay armed; carry clear: go dormant.
satc:	lda SCENE
	cmp #ROOM
	bne .do
	bbr3 <$25, .lit
	lda DARKF
	ora gap
	ora ld
	bne .dr
	sec
	rts
.dr:	jsr .res
	bbr3 <$25, .lt
	sec
	rts
.lit:	jsr .res
.lt:	stz ld
	clc
	rts
.do:	jsr .res
	clc
	rts
.res:	cli
	lda #6
	jsr cold
	sei
	rts

	.if FOLD
	.else
	.include "shaft19_ktab.inc"
	.endif

	.bank 4
	.org $C000

	jmp ksdcpy              ; 0 the set-up (interrupts on, in the dark): the side tables to DB_K; carry clear
k4magic:	.db $19, $B0
	.if FOLD
	jmp mkpart              ; 5 the set-up: the blocks' tile partitions (out of the main bank: its bytes are kbuild's fifth key)
	jmp kstair              ; 8 kbuild: the nibble map's staircase bit
	jmp kscr                ; 11 the set-up: the pass's scratch
	.if XRAILS
	jmp xunp
	jmp xsd
	jmp xset2               ; 20 the set-up's end: the composite table, column 36, the fine-X add
	jmp xrst                ; 23 the exit restore's first step: the masks' pattern, the top and bottom bars
	jmp xpass               ; 26 kpass: the X phase (Y = the pass's buffer)
	jmp xmask               ; 29 the set-up: the mask sprites' pattern
	.if RSLACK
	jmp rown                ; 32 own rows: this pass's window (r19-slack-rows)
	jmp rslr                ; 35 sdwork: a buffer's slack cells back
	.if EFIX
	jmp eset
	.endif
	.endif
	.include "shaft19_x3.inc"
	.include "shaft19_x4.inc"
	.endif
	.include "shaft19_mkpart.inc"
kstair:	tma #3
	pha
	lda #DB_NEAR
	tam #3
	clx
.t:	stz $9000,x
	txa
	and #$7F
	beq .tn
	tay
	lda prop,y
	bpl .tn
	inc $9000,x
.tn:	inx
	bne .t
	lda #$60
	sta .s+2
.l:
.s:	ldy $6000,x
	lda $9000,y
	beq .n
	stx t0                  ; i: DB_N's page $80 + (the near copy's page - $60)
	lda .s+2
	clc
	adc #$20
	sta t1
	jsr .set
	lda t0                  ; i - 1
	bne .d1
	dec t1
.d1:	dec t0
	jsr .set
	lda t0                  ; i - 64
	sec
	sbc #63
	sta t0
	bcs .d2
	dec t1
.d2:	jsr .set
	lda t0                  ; i - 65
	bne .d3
	dec t1
.d3:	dec t0
	jsr .set
.n:	inx
	bne .l
	inc .s+2
	lda .s+2
	cmp #$70
	bne .l
	pla
	tam #3
	rts
.set:	lda t1
	cmp #$80
	bcc .q                  ; (before the map)
	sta .r+2
	sta .w+2
	ldy t0
.r:	lda $8000,y
	ora #$10
.w:	sta $8000,y
.q:	rts
kscr:	tma #3
	pha
	tma #4
	pha
	lda #DB_T
	tam #3
	lda #DB_NEAR
	tam #4
	clx
.l:	lda DBT_O - $2000,x
	sta $9200,x
	lda DBT_O - $1F00,x
	sta $9300,x
	stz $9400,x
	lda #1
	sta $9500,x
	inx
	bne .l
	.if FOLDS
	ldx #73                 ; (KYOK, FOLDS: every y 73 .. 215, an overlay with a line on the field's 128 (y 88 .. 215); kh16_1 tests the
.y:	stz $9500,x             ;  scrolled grid itself. On the screen's grid the same set as below: 80, 88 .. 208)
	inx
	cpx #216
	bne .y
	.else
	ldx #80
.y:	stz $9500,x
	clc                     ; (CLC first: the other order's three bytes are the start of the mid path's site, and the sector scan
	txa                     ;  wants no run of any site's bytes in the module's sectors)
	adc #8
	tax
	cpx #216
	bne .y
	.endif
	lda #<1667
	sta t0
	lda #>1667
	sta t1
	clx
.f:	lda t0
	sta $9600,x
	lda t1
	sta $9680,x
	lda t0
	sec
	sbc #26
	sta t0
	bcs .f1
	dec t1
.f1:	inx
	cpx #64
	bne .f
	stz $9600,x
	stz $9680,x
	.if FOLDP
	clx
.o:	cla
	cpx #$D8
	bcc .o1
	cpx #$E0
	bcs .o1
	lda #1
.o1:	cpx #$A0
	bcc .o2
	cpx #$F8
	bcs .o2
	ora #2
.o2:	sta $9B00,x
	inx
	bne .o
	.endif
	clx
.g:	lda $D700,x
	sta $9700,x
	lda $D800,x
	sta $9800,x
	lda $D900,x
	sta $9900,x
	lda $DA00,x
	sta $9A00,x
	inx
	bne .g
	.if XRAILS
	.if XTB = 0
	stz xtb                 ; fresh set-up: capture XD_TB from BAT rows 36 & 47
	.endif
	.endif
	pla
	tam #4
	pla
	tam #3
	rts
	.if * > $D700
	.fail                   ; (the third cold bank's code must end below its generated tables)
	.endif
	.org $D700
	.include "shaft19_ktab.inc"
	.endif
ksdcpy:	tma #4
	pha
	lda #DB_K
	tam #4
	clx
.l:	lda ksd16s,x
	sta ksd16,x
	lda ksd32s,x
	sta ksd32,x
	inx
	bne .l
	pla
	tam #4
	clc
	rts
	.include "shaft19_ksd.inc"
	.if EFIX
	.include "shaft19_x6.inc"
	.endif

	.if BANK5
	.bank 5
	.org $8000
	.include "shaft19_x7.inc"
	.if PBX
	.include "shaft19_x8b.inc"
	.else
	.include "shaft19_x8.inc"
	.endif
	.include "shaft19_otab.inc"
	.if PLG
	.bank 6
	.org $C000
	jmp s6ent               ; (the bank's first byte: mkdisc's check; overwritten at the set-up, never called here)
	.org $C600
	.include "shaft19_xa.inc"
	.endif
	.endif
