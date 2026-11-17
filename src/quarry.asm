
OP_NEARPTR = $6CE6
OP_NEARLO  = $6CF2
OP_NEARH0  = $6CF7
OP_NEARHI  = $6CF9
OP_MIDPTR  = $6D0B
OP_MIDLO   = $6D11
OP_MIDHI   = $6D18
OP_FARPTR  = $6D2A
OP_FARLO   = $6D2E
OP_FARHI   = $6D35
OP_MAWRLO  = $6C85
OP_MAWRHI  = $6C87
PROPZP     = $59
CAMX       = $2D0C
PASS       = $339F
VDCREG     = $F7
GAMEROW    = $6CD8
SATPAGE    = $2215
FINEX      = $2D10
ZERO09     = $2D09
FINEADC    = $4CC3      ; bank $80 (MPR2): the object draw's ADC FINEX; operand low byte is at $4CC4
FRAMES     = $2241
LOCKZP     = $25        ; $2025: bit 4 set while a load or door holds the screen dark (the room profile's lock), clear from the lit frame
BCLR       = 0          ; the data banks cleared at an entry after another module (bclr)
DGAP       = 32         ; frames without a pass that mark the room's unpack (53-70 measured on every entry; a pass a frame after it)
DMAX       = 44         ; the dark set-up's frames at most (the DARK rule: 45 added)
NBL        = 74         ; the open quarry's last near column (camera 320: columns 40-73 on screen) ...
NBR        = 78         ; ... and band 1's first (camera 624: 78); 75-77 are never drawn by this module
MBND       = 54         ; the open quarry's last mid column (the mid layer at half the camera: camera 318, (318 / 2) / 8 + 33 = 52, + 2)
TIMER      = $0C00
SPLITS     = $F3
MENU       = $36D6
ROWGAME    = $5FFF
THARD      = 336
WN         = (THAND + 16) / 8   ; the open quarry's windows: near column 0 (camera -16) .. 41 (camera 312-319)
THAND      = 320
BAND       = 640
CH3        = 1          ; read the third code area (the band path)
PROF       = 0
PROFV      = 0          ; the band pass's finer stamps (tpv0-3, tpm0-2): off (their 60 bytes went to bmv, 2026-11-10)
BLET       = BAND       ; the camera below which the band lets go (aligned); BRPROBE builds: 336, the band's passes down to camera 320
BRPROBE    = 0
BRLEV      = 0          ; 1: no upload ahead on the left walk's heavy pass (the bridge's lever; off: band 1 as measured)
BANDON     = 1
SPIRE      = 1
BANDT      = BAND0 + 3  ; the band's tables (at MPR4 while the band path runs): WIN, NW, MW, FW, PROP2

NCOLS      = 136        ; near map columns reached (camera up to 752)
MCOLS      = 96         ; mid map columns reached

T1         = $69        ; at MPR3 ($6000) while drawing
T2         = $6A        ; at MPR4 ($8000) while drawing and uploading
NPB        = $6B        ; near images: phase index p (0-3, offset 2p) in bank NPB + p at k * 32
MPB        = $6F        ; mid images: phase p (0-7) packed four a bank: bank MPB + (p >> 2), $C000 + (p & 3) * $800 + k * 32 (k < MKMAX)
MKMAX      = 64         ; mid slots (the room has 57; past it the pair shows its left tile)
BAND0      = $71
T3         = $78        ; edge keys (at MPR3 while looking one up)
T4         = $79        ; source tiles recoloured for merged palette k: bank T4 + k (index * 32; index 0 is all zero)
EBANK0     = $7C        ; edge images from here on, then the free part of the other image banks (ibt)
EKMAX      = $260       ; edge keys made since the store was emptied, at which it is emptied again (handover; the table holds 765)
KEEP1      = $7D        ; banks this module never writes (bclr, ibt; src/modules.json's data_banks leave them out, mkdisc checks):
KEEP2      = $7E        ; the stub bank SBANK, and the mine's code bank (resident beside this module in block 24: the successor protocol)
SCENE      = $207C      ; the scene id (the hand-off: rowent)
SHBANK     = $77        ; shift tables: SHL[p][v] at SHT + p * 512, SHR[p][v] at + 256
SHT        = $C000
C6BANK     = NPB + 1      ; (quarry-bridge-setup: the first overlay in NPB + 1's tail past the near images, 3,840 bytes: taken from the image
C6RAM      = $7100      ; store's last resort on the card tier only (dstz: ibt's last entry); the second in NPB + 3's, the third in NPB + 2's
C6LEN      = $0F00      ; past the mid groups' copies: all in place)
C6SUM      = 0
C6SUM1     = 0          ; ... and of its first page alone (the resident's check: the page that copies and checks the rest, c6ld)
C6SEC      = 444
C7BANK     = NPB + 3
C7RAM      = $7100      ; the second overlay (the store's builder): in NPB + 3's tail, copied from the card in the idle (c7ld)
C7LEN      = $0F00
C7SUM      = 0
CBKEY      = 0          ; the build's key in the store's header (mkdisc: 16 bits of the SHA-256 of the module's image assembled with the three at 0)
C7SEC      = 446
C8BANK     = NPB + 2      ; (quarry-bridge-setup) the third overlay (the bridge's set-up and store builder): NPB + 2's tail past the mid
C8RAM      = $7500      ; groups' copies (the first overlay's place until this row), loaded after the second (c8ld), called through c8tr
C8LEN      = $0B00
C8SUM      = 0
C8SEC      = 448
C9LEN      = $0500      ; (quarry-bridge-draw) the fourth image: after the third overlay's in its sectors and on the card, copied over it
PGSEC      = 10562      ; (quarry-pregen-load) the pre-generated store's loader (quarry_pgfast.inc: one sector, in every build) and the store's
PGDIR      = 10563
C6CH       = $1F
PROOF      = 0
IMGWIN     = $C000

PREB       = 0          ; prebuilt row images built in idle time (tried, off: see the checklist)
PROWS      = 12         ; image rows built per idle time at most
PREU       = 1          ; ... and used by the heavy passes (0: live draws only; for bisecting)
SLOTMAX    = 142        ; slots listed in a pass, beyond it whole tiles
POOLN      = 142        ; pool tiles per set: set 0 $772-$7FF, set 1 $680-$70D (pool1 below)
KMAX       = 252        ; near / mid slots each; $FD..$FF are the table's specials
NOSLOT     = $FF        ; slot tables: no tile at column c or c + 1 of this layer (near: look under; mid: far)
EDGEA      = $FE        ; only the left tile exists: an edge cell
EDGEB      = $FD        ; only the right one
MEDGE      = 1          ; mid-over-far outlines as edge slots too (0: whole tiles)
PFLAT      = $FE        ; NPO / MPO: the pair looks the same at every phase: the whole tile
PNONE      = $FF        ; NPO / MPO: not in the pool

NSLOT      = $6000      ; near slot of the pair starting at column c, row r: $6000 + r * 256 + c
MSLOT      = $7000      ; mid: $7000 + r * 128 + c
FARL       = $7800      ; far word of screen column x (33), row r: + r * 64
FARH       = $7C00
NFIRST     = $8000      ; per code the first slot with that left tile
MFIRST     = $8100
NNEXT      = $8200
MNEXT      = $8300
NCB        = $8400      ; the right code
MCB        = $8500
NCA        = $8600      ; the left code
MCA        = $8700
NPO        = $8800      ; slot -> pool tile
MPO        = $8900
OWN        = $8A00      ; pool tile -> slot ($FF free)
OWNK       = $8B00      ; its kind: 0 near, 1 mid
SRCB       = $8C00      ; its images: first bank, address
SRCL       = $8D00
SRCH       = $8E00
STAMP      = $8F00      ; the pass that last listed or uploaded it
VL0        = $9000      ; the pool tile's VRAM address per set
VH0        = $9100
VL1        = $9200
VH1        = $9300
WL0        = $9400      ; its BAT word per set (palette from its slot)
WH0        = $9500
WL1        = $9600
WH1        = $9700
LST0       = $9800      ; pool tiles the buffer of each set shows (the page per set in lstpg: swapped with a prebuilt list)
LST1       = $9900
PL0        = $9A00      ; the prebuilt images' lists
PL1        = $9B00
PIN        = $9C00      ; pool tile: referenced by a prebuilt image (not reclaimable)
QP         = $9D00
QL         = $9D40
PWA        = $9D80      ; prebuilt image, per set and row: the window range (rba / rbb at consume) and the range written
PWB        = $9DA0
PTA        = $9DC0
PTB        = $9DE0
LBL        = $9E00      ; a row's words being built: low bytes, high bytes
LBH        = $9E40
prop       = $9E80
pmap       = $9F00
mcol       = $9F90      ; a merged palette being built
IMG        = $D000      ; (SHBANK) prebuilt row word images: set * $800 + row * $80, in the window the bank is mapped at

FNA = 0
FNB = 1
FMA = 2
FMB = 3
FFF = 4
FPO = 5                 ; EPO_*, or its pool tile
FB  = 6                 ; images: bank; address in the $C000 window, its low bits the merged palette
FAL = 7
FAH = 8
EEMPTY  = $FE           ; FNA of a free entry
EP_FREE = $FF           ; made, not in the pool
EP_WAIT = $FE           ; being made (the cell shows whole tiles)
EP_NONE = $FD           ; no merged palette holds its colours (all three layers): whole tiles
RN0 = $7B00             ; recoloured tile index per layer's code and merged palette (0: not yet; $FF: does not fit); per mrt
RN2 = $7B80
RM0 = $7C00
RM2 = $7D00
RF0 = $7E00
RF2 = $7F00
QN  = 64

WIN        = $8000
PROP2      = $9E00
NP         = $8600
MP         = $8820
MA         = $8920
MS         = $8A20
FW         = $8B00      ; the far words (screen-locked), row stride 66
NLC        = $9000      ; the near lists: per row a ring of 32 entries ordered by near column c (row r at + r * 32): c
NLK        = $9200      ; kind                                                   (band 1 has at most 26 near cells in a row)
NLA        = $9400      ; tile A's code (the present tile's for an end)
NLG        = $9600
NLX        = $9800      ; 2 (c - bc0): the cell's byte offset in its WIN row from the row base of column bc0
NLVL       = $9A00      ; the word written at phase 0 (whole A; a pair: its group's first tile - 1, the word at phase pn = + pn), low and high
NLVH       = $9C00
NLMASK     = $1F
GUSE       = $8420      ; per near slot (136): entries on screen using it (a group is held while any)
GSLOT      = $84B0      ; per near slot: its VRAM group (0 - NGROUP-1) or $FF
GREADY     = $8540
GVL        = $8F20      ; per group: its first tile - 1 (the BAT word at phase 0, palette 0), low and high (ginit, from the runs)
GVH        = $8F90
GQ         = $9E80
GFREE      = $9F80
NOGC       = 127        ; (camera 750 is the last at a non-zero phase: cn 95, screen columns 0-31 show near columns 95-126)
VXT0       = $15A
VXG        = 12
NGROUP     = VXG + 85   ; 97
GUPMAX     = 24         ; tiles uploaded a pass at most
BANDN      = BAND0      ; $71: the near-end parts NE: e * 384 + side * 192 + pal * 96 + (pn - 1) * 32 (side 0: A, a run's right
                        ; end, shifted left by the phase; 1: B, a left end, shifted right; pal 0: merged with far, 1: with mid)
BANDF      = BAND0 + 1  ; $72: FT, the far tiles' patterns: f * 32 (f = tile - the far base)
NEMAX      = 21         ; near-end tiles with parts (21 x 384 = 8,064)
MIXBASE    = $680       ; the mix tiles: two sets of 64, set s at MIXBASE + 64 s + i
MIXMAX     = 64
MJMAX      = 66         ; mix jobs a pass: 64 in MIXBASE's set, 2 more in MIXX (quarry-band1-bounce-mid: 64 + 1 needed at 658-672)
MIXX       = $678       ; the two sets' jobs 64-65: $678-$679 / $67A-$67B (all-zero, referenced by nothing in 17 over the longplay,
                        ; untouched by the stress census: zeroed again with the runs' restore)
MJ_E       = $7B10      ; (T3 at MPR3, past T3_LO / T3_HI) the jobs: e | side << 7 (80 bytes each)
MJ_P       = $7B60      ; pal | pn << 1
MJ_LO      = $7BB0      ; under low
MJ_HI      = $7C00      ; under high
MJ_BNK     = $7C50      ; under bank
MJ_T       = $7CA0      ; its tile's low byte (high $06): MIXBASE + mset + i, or MIXX + 2 set + i - 64
T3_LO      = $7AC0      ; (T3 at MPR3) es * 192 base lo (34 bytes)
T3_HI      = $7AE2      ; (T3 at MPR3) es * 192 base hi (34 bytes)
NEIDX      = $9F00      ; (BANDT) near tile code -> its NE index e, or $FF
PALF       = 6          ; the merged palettes: BG palette 6 = far's colours + the near ends' extras, 7 = mid's + the extras
PALM       = 7

vsel	.macro
	lda #\1
	sta <VDCREG
	sta $0000
	.endm

	.include "stubsyms.inc"  ; (mkdisc) STUB_CURMOD, STUB_PREV and the hand-off's HFROM, HTO, HSCA, HSCB

	.bank 0
	.org $A000

	jmp rowent
	jmp satbody
	jmp modent
	jmp idlework
	jmp idlelate
	jmp norts               ; (lateup: the waitfix late path; nothing to do here)
	jmp leave2

; ---------------------------------------------------------------- state
magic:	.db $5A, $A5
setok:	.db 0           ; slots and images made for the exterior
nsetup:	.db 0
tset0:	.db 0
tset1:	.db 0
nk:	.db 0           ; slots made
mk:	.db 0
over:	.db 0           ; cells past the cap or the pool this pass (the check reads it)
overn:	.dw 0           ; ... in all
novf:	.dw 0           ; passes with any
ups:	.db 0           ; slots uploaded by the last upload
maxup:	.db 0           ; ... most in one upload
lastpass:	.db $FF
pass:	.db 0
pmode:	.db 0
set:	.db 0
rows:	.db 0
row:	.db 0
cn:	.db 0           ; columns and offsets of this pass
cm:	.db 0
dn:	.db 0
dm:	.db 0
pn:	.db 0           ; near phase index
lc:	.db 0           ; slots listed while drawing
lcs:	.ds 2           ; per set: slots listed, its columns, whether its columns are valid, the phases its images hold
dcn:	.ds 2
dcm:	.ds 2
dvalid:	.ds 2
updn:	.ds 2
updm:	.ds 2
save3:	.db 0
save4:	.db 0
save6:	.db 0
t0:	.db 0
t1:	.db 0
t2:	.db 0
t3:	.db 0
kk:	.db 0
hand:	.db 0
nlo:	.db 0           ; tile bases: word = code + (hi, lo)
nhi:	.db 0
mlo:	.db 0
mhi:	.db 0
ss:	.db 0
si:	.db 0
sj:	.db 0
ssb4:	.db 0
ssb6:	.db 0
sfr:	.db 0
sbud:	.db 0
sv3:	.db 0
sv4:	.db 0
sv6:	.db 0
dirty:	.db 0           ; images are in VRAM
early:	.db 0
pfr:	.db 0
lastpf:	.db $FF
dkg:	.db 0
dks:	.db 0           ; ... requested by passbegin (setbegin on this pass)
dst0:	.db 0           ; FRAMES as the dark set-up began
dkin:	.db 0           ; the dark set-up is running (band_setup's synchronous prewarm only then)
mign:	.db 0           ; the window flag was up as the dark set-up ended (a Load's): cpos ignores it until it drops
nsd:	.db 0           ; the near map's scan order: 0 from column 0 (an entry at the open quarry's side), 1 from NCOLS - 1 (the band's side)
nbc:	.db 0           ; ... its boundary column: past it the slots are the other side's (NBL / NBR)
nk1:	.db 0           ; near slots first seen up to the boundary: the entry side's (images in the set-up; the rest in the background)
mk1:	.db 0           ; mid slots first seen in mid columns 0 .. MBND (the open quarry's; the others are never drawn: no images)
gnh:	.db 0           ; ss_gn's last slot + 1, ss_gm's first and last + 1
gml:	.db 0
gmh:	.db 0
bgss:	.db 0           ; the background images' stage (ss while it runs; 0 none): the other side's slots, after the first lit frame
bgf:	.db 0           ; 1: ss_end2 is the background's end
imall:	.db 0           ; the open quarry's images made (the take-over and the take-back wait for it)
bsok:	.db 0           ; the band's images and set-up made (its prewarm at 512-640 waits for it)
sati:	.db 0
uf:	.db 0
srca:	.ds 32
srcb:	.ds 32
ua:	.db 0
ub:	.db 0
ub2:	.db 0
ey:	.db 0
ena:	.db 0           ; the edge key looked up
enb:	.db 0
ema:	.db 0
emb:	.db 0
eff:	.db 0
ep:	.db 0           ; its group, entry
el:	.db 0
qh:	.db 0
qt:	.db 0
bst:	.db 0           ; the key being made: step, group, entry, source, target, image, its masks and block
bp:	.db 0
bl:	.db 0
bs:	.db 0
bT:	.db 0
bi:	.db 0
bn:	.db 0
bna:	.db 0
bnb:	.db 0
bma:	.db 0
bmb:	.db 0
bff:	.db 0
bb:	.db 0
bal:	.db 0
bah:	.db 0
bidx:	.ds 5
ib:	.db 0           ; image space: next bank, its address high byte, low
ia:	.dw 0
iz:	.db 0
nkeys:	.dw 0           ; edge keys
nbuilt:	.dw 0           ; ... made
nnofit:	.db 0
nreb:	.db 0
sc:	.db 0           ; the scan ahead: near column, row, count
sr:	.db 0
snd:	.db 0
adl8:	.db 0
adh8:	.db 0
adl4:	.db 0
adh4:	.db 0
pal0:	.dw 0
rmns:	.ds 3
mcn:	.db 0
pdirty:	.db 0
	.if PREB
pre:	.db 0           ; 1: cells writes a row's words to LBL / LBH (a prebuilt image), 0: to the VDC
	.endif
	.if PREB
pval:	.ds 2           ; per set: an image is ready, for near column pcn, mid pcm, built at the set's draw generation pgen, slots listed
	.endif
	.if PREB
pcn:	.ds 2
	.endif
	.if PREB
pcm:	.ds 2
	.endif
	.if PREB
pgen:	.ds 2
	.endif
	.if PREB
plcs:	.ds 2
	.endif
dgen:	.ds 2           ; per set: counts its draws (live or from an image)
lstpg:	.db >LST0, >LST1 ; per set: the page of its list
	.if PREB
prelst:	.db >PL0, >PL1  ; per set: the page of its image's list
	.endif
	.if PREB
pbusy:	.db 0           ; an image is being built: its set, row, column
	.endif
	.if PREB
pset:	.db 0
	.endif
	.if PREB
prow:	.db 0
	.endif
	.if PREB
ptcn:	.db 0
	.endif
	.if PREB
prows:	.db 0           ; rows left for this idle time
	.endif
	.if PREB
pmask:	.db 0           ; the sets the build under way is for (bit per set)
	.endif
lpass:	.db 0           ; the pass number (pass itself is shifted while images are built)
ldir:	.db 0           ; the camera's last motion (1 right, $FF left)
camlo:	.db 0
camhi:	.db 0
npl:	.db 0           ; the row's map pointers for rowops
nph:	.db 0
mpl:	.db 0
mph:	.db 0
	.if PREB
svset:	.db 0
	.endif
	.if PREB
svcn:	.db 0
	.endif
	.if PREB
svcm:	.db 0
	.endif
	.if PREB
svekp:	.db 0
	.endif
	.if PREB
svlc:	.db 0
	.endif
	.if PREB
svpass:	.db 0
	.endif
nmiss:	.dw 0           ; heavy passes drawn live (no image for them)
	.if PREB
nhit:	.dw 0           ; ... from an image
	.endif
dfull:	.ds 2           ; this set's buffer was drawn by us
bla:	.ds 2
rnf:	.ds 16
rnl:	.ds 16
rmf:	.ds 16
rml:	.ds 16
rba:	.ds 32          ; per set and row the columns written in the last draw
rbb:	.ds 32
act:	.db 0
hcl:	.db 0           ; camera + 16 at a switch test (never negative)
hch:	.db 0
nhand:	.db 0           ; stand-downs
tpb:	.db 0
tpd:	.db 0
tpu:	.db 0
tpi:	.db 0
tpf:	.db 0           ; the frame counter at the pass's first row
tpp:	.db 0
	.if PROFV
tpv0:	.db 0           ; (band, a right step) before nvacate, after it, after the shift and trim, after nfetch
tpv1:	.db 0
tpv2:	.db 0
tpv3:	.db 0
tpm0:	.db 0
tpm1:	.db 0
tpm2:	.db 0
	.endif
	.if PROF
nidov:	.db 0           ; idle works that ended in a later frame, and the key step / image / entry then (quarry-spire-fix: the four
idovb:	.db 0           ; inside PROF, where their only uses are: 4 bytes of bank 0 for satbody's call)
idovi:	.db 0
idove:	.db 0
	.endif
nback:	.db 0           ; take-backs
bcn:	.db 0           ; the band's near and mid columns at screen column 0 as its tables hold them ($FF: none)
bcm:	.db 0
bc0:	.db 0           ; the column NLX is relative to (cn at the last rebuild)
gfn:	.db 0           ; free groups on the stack
gqh:	.db 0
gqt:	.db 0
gover:	.db 0           ; pairs shown whole for want of a group
gqp:	.db 0
nne:	.db 0           ; near-end tiles with parts made
nmap0:	.ds 16
nmap1:	.ds 16
nmix:	.db 0           ; mix jobs this pass
pb0:	.db 0           ; (negen) a row's planes in, out
pb1:	.db 0
pb2:	.db 0
pb3:	.db 0
ob0:	.db 0
ob1:	.db 0
ob2:	.db 0
ob3:	.db 0
nmixov:	.db 0          ; mixes past MJMAX (shown whole; quarry-spire-fix: 8 bits)
mset:	.db 0           ; the mix set written this pass (0 / 64)
ngup:	.db 0           ; tiles uploaded (quarry-spire-fix: 8 bits)
nlh:	.ds 16          ; the near lists' heads and tails (a ring of 64 per row)
nlt:	.ds 16
nfA:	.ds 16          ; a column being fetched: per row the tile codes, kind, slot (nfetch / mfetch)
nfB:	.ds 16
nfK:	.ds 16
nfG:	.ds 16
nwfull:	.db 0           ; this pass changed a column: every listed cell is written, the far unders too
nbpass:	.dw 0           ; band passes drawn
nfmix:	.db 0           ; precomposed far-mix slots allocated (0-254)
nfmix0:	.db 0           ; bank 0 slots (es <= 8)
nfmix1:	.db 0           ; bank 1 slots (es >= 9)
pw_state: .db 0
bgs:	.db 0
card:	.db 0
hut:	.db 0
huf:	.db $80
tlp:	.db 0
tnw:	.db 0
wq:	.db 0
erq:	.db 0           ; the band's prewarm took the edge store: ereset in the next key step
rnext:	.db 0           ; esrc: the next source needs its recolour (a step of its own)
rpk:	.db 0           ; rmget: 0 a look only (no recolour)
hsn:	.db 0
wq2:	.db 0
sw:	.db $FF         ; the window being scanned ($FF: none)
nnrd:	.db 0
nkmiss:	.dw 0
ssv:	.db 0
ekon:	.db 0           ; the edge store is up during the set-up (einit at ss_mid's end): keys in its idle time
erow:	.ds 16          ; per row: an edge slot (near or mid) somewhere in it (ss_near, ss_mid)
wsc:	.ds WN          ; per window: scanned
wtk:	.ds WN          ; ... its ticket (nkeys at the end of its scan)

hfl:	.db 0           ; (quarry-handover) the hand-over's image has idle work pending (quarry_cardh.inc: hflg): idlelate's test (here,
                        ; after the variables: the addresses before it are k18's)
idlelate:
	lda hfl                 ; (quarry-handover) the hand-over's image has work for a wait (hfl: the claim's fill after band 1 let go at 624
	beq .q
	jmp idlework
.q:
	.if PREB
	lda setok
	beq .x
	lda act
	cmp #1
	bne .x
	lda FRAMES
	sta sfr
	jsr prework
.x:
	.endif
	rts

; ---------------------------------------------------------------- the objects' fine add (bank $80 at MPR2, always)
sprest:	lda #<FINEX
spset:	ldx FINEADC
	cpx #$6D
	bne .n
	ldx FINEADC+2
	cpx #>FINEX
	bne .n
	sta FINEADC+1
.n:	rts

vxrest:	lda vxok
	beq .x
	stz vxok
	lda #1
	jmp vxfer
.x:	rts
vxok:	.db 0           ; the run is copied (its tiles may hold groups)
wsd:	.db 0
nwin:	.db 0           ; ... such stand-downs (counted)

; ---------------------------------------------------------------- sprites
satbody:
	jsr sprest
	lda act
	beq .g
	dec a
	beq .a
	lda CAMX + 1            ; (quarry-spire-fix) a pass of the band path (the bridge, band 1): the world objects had their fine add
	lsr a
	bne .r
	lda #30
	jmp cx5
.g:	lda setok
	beq .br
	lda hcl
	cmp #<(THAND + 16)
	lda hch
	sbc #>(THAND + 16)
	bcs .br
	jmp hwait
.br:	lda TIMER
	and #$7F
	bbr6 <SPLITS, .r
	sta hut
	lda FRAMES
	sta huf
.r:	rts
.a:	jsr hwait
.go:	stz sati
	lda FRAMES
	cmp pfr
	beq .sa
	inc sati
.sa:	lda CAMX
	and #7
	sta dn
	lda CAMX
	lsr a
	and #7
	sta dm
	ldy #4
.spr:	cli
	nop
	lda sati
	bne .ion
	sei
.ion:	vsel 1                  ; MARR = SAT + 4*i + 3 (attributes)
	tya
	asl a
	asl a
	sta t3
	ora #3
	sta $0002
	lda SATPAGE
	sta $0003
	vsel 2
	lda $0002
	sta t2
	ora $0003
	beq .done
	lda t2
	and #$0F
	cmp #$0D
	beq .next
	cmp #$0F
	beq .next
	ldx dn
	cmp #$04
	bne .d
	ldx dm
.d:	txa
	beq .next
	stx t2
	vsel 1                  ; MARR = X word
	jsr .sx
	vsel 2
	lda $0002
	sta t0
	lda $0003
	sta t1
	vsel 0                  ; MAWR = X word
	jsr .sx
	vsel 2
	lda t0                  ; X word - d (10 bits)
	sec
	sbc t2
	sta $0002
	lda t1
	sbc #0
	and #$03
	sta $0003
.next:	iny
	cpy #64
	beq .done
	jmp .spr
.sx:	lda t3
	ora #1
	sta $0002
	lda SATPAGE
	sta $0003
	rts
.done:	sei
	rts

hwait:	lda TIMER
	and #$7F
	sta tlp
	lda FRAMES
	cmp pfr
	bne .x
	bbr6 <SPLITS, .x
	lda #1
	sta early
	stz hsn
	cli
.hw:	lda TIMER
	and #$7F
	bbr6 <SPLITS, .hd
	sta tlp
	lda FRAMES
	cmp pfr
	bne .h2
	lda hsn                 ; (no step fits any more: only the poll)
	bne .hw
	jsr hstep
	bra .hw
.hd:	lda tlp
	sta hut
	lda FRAMES
	sta huf
.h2:	sei
.x:	rts

; ---------------------------------------------------------------- init (at the first area load)
rowent:	stz wgame
	lda <$55
	and #$C0
	beq .r
	lda act
	bne .r
	stz ROWGAME
	sec
	rts
.r:	jsr rowdraw
	lda SCENE
	cmp #18
	bcc .k
	cmp #25
	bcs .k
	lda <$55
	cmp #$0C
	bcc .k
	cmp #$11
	bcs .k
.h:	lda #20                 ; (third area, qho: set 1 put back in the fade's idle first, then the hand-off; step 3)
	jsr call2
.k:	lda wgame
	lsr a
norts:	rts
wgame:	.db 0
leave2:	lda #10                 ; (in the second code sector: no BAT word left on either pool set either)
	jmp call2
modent:	tax
	sec
	sbc mgen
	stx mgen
	stz mval
	cmp #2
	beq .v
	tma #3
	pha
	tma #4
	pha
	lda #T1
	tam #3
	lda #T2
	tam #4
	stz <$FC
	lda #>C3SEC
	sta <$FD
	lda #<C3SEC
	sta <$FE
	lda #1
	sta <$FF
	lda #6
	sta <$F8
	stz <$FA
	lda #$60
	sta <$FB
	jsr $E009
	tma #6
	pha
	lda #CBANK
	tam #6
	tii $6000, C3ORG, $1000
	lda #SHBANK
	tam #6
	tii $7000, C4ORG, $1000
	lda #C5BANK
	tam #6
	tii $8000, C5ORG, $1000
	pla
	tam #6
	pla
	tam #4
	pla
	tam #3
	.if BCLR
	lda #12                 ; (in the second code sector) its data banks as at power on: other modules wrote them
	jsr call2
	.endif
	bra .g
.v:	inc mval
.g:	jmp modinit2
mgen:	.db 0           ; dgen at the last modinit (in this bank's image 0: read at the first entry after a power-on or a reload)
mval:	.db 0           ; this entry found the code areas as it left them (modinit: the shift tables kept too)

rowdraw:
	lda PASS
	cmp lastpf
	beq .pf
	tay                     ; (quarry-k17: dpass stores it, Y kept by callx: three bytes of the piece for the visit's first-pass test)
	lda #27                 ; (a new pass: the dark set-up's request, dpass in the stub bank's piece)
	ldx #C5BANK
	jsr callx
.pf:	lda SCENE
	cmp #17
	bne .game
	lda PASS
	cmp lastpass
	beq .ext
	lda #18
	jsr call2
	bcc .ext
.game:	jsr dvz
	.if PREB
	jsr pdrop
	.endif
	stz ss                  ; (a setup under way restarts when the exterior comes back)
	stz card
	stz setok
	stz act
	jsr sprest
	stz ROWGAME
	inc wgame
	sec
	rts
.ext:	lda PASS
	cmp lastpass
	beq .same
	sta lastpass
	sta pass
	sta lpass
	jsr passbegin
.same:	lda pmode
	bne .ours
	inc wgame
	sec
	rts
.ours:	cmp #2
	bne .n2
	lda rows                ; the buffer holds these columns: nothing but the count
	inc a
	sta rows
	cmp #16
	bne .x
	tma #3
	sta save3
	tma #4
	sta save4
	lda #T2
	tam #4
	.if PROF
	lda $0C00
	sta tpd
	.endif
	jsr upload
	.if PROF
	lda $0C00
	sta tpu
	.endif
	lda save3
	tam #3
	lda save4
	tam #4
.x:	rts
.n2:
	.if BANDON
	cmp #3
	bne .draw
	lda #6                  ; band_row
	jmp callb
	.endif
.draw:	tma #3
	sta save3
	tma #4
	sta save4
	lda #T2
	tam #4
	lda OP_NEARPTR+1        ; (row r: the operand's page - $C0)
	sec
	sbc #$C0
	sta row
	.if PREB
	ldx set                 ; an image for this buffer, these columns, this draw generation: its rows go in as they are
	lda pval,x
	beq .live
	lda pcn,x
	cmp cn
	bne .live
	lda pcm,x
	cmp cm
	bne .live
	lda pgen,x
	cmp dgen,x
	bne .live
	jmp fastrow
	.endif
.live:
	.if PREB
	lda rows
	bne .lv
	inc nmiss
	bne .lv
	inc nmiss+1
	.endif
.lv:	lda OP_NEARPTR
	sta npl
	lda OP_NEARPTR+1
	sta nph
	lda OP_MIDPTR
	sta mpl
	lda OP_MIDPTR+1
	sta mph
	jsr rowops
	jsr bounds              ; the columns to write (outside them far tiles, as this buffer already holds)
	bcc .wr
	lda save4
	tam #4
	inc rows                ; nothing in this row
	lda rows
	cmp #16
	bne .ne
	jmp rowend
.ne:	rts
.wr:	vsel 0                  ; MAWR = the first of them in this row
	lda OP_MAWRLO
	clc
	adc ua
	sta $0002
	lda OP_MAWRHI
	adc #0
	sta $0003
	vsel 2
	lda #T1
	tam #3
	jsr cells
	inc rows
	lda rows
	cmp #16
	bne .nr
	jmp rowend2
.nr:	lda save3
	tam #3
	lda save4
	tam #4
	rts

; the row's operands from npl / nph (near map pointer), mpl / mph (mid), row
rowops:	lda npl
	sta c_nmap+1
	sta ek_n+1
	sta c_n+1
	inc a
	sta ek_n2+1
	lda nph
	sta ek_n2+2
	sta c_nmap+2
	sta ek_n+2
	lda row
	clc
	adc #>NSLOT
	sta c_n+2
	lda mpl
	sta c_mmap+1
	sta ek_m+1
	sta t1
	inc a
	sta ek_m2+1
	lda mph
	sta ek_m2+2
	sta c_mmap+2
	sta ek_m+2
	lda row                 ; mid slots: MSLOT + r * 128 + c
	lsr a
	sta t0
	cla
	ror a
	clc
	adc t1
	sta c_m+1
	lda t0
	adc #>MSLOT
	sta c_m+2
	lda row                 ; far words: + r * 64
	stz t0
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t0
	asl a
	rol t0
	sta c_fl+1
	sta c_fh+1
	sta ek_f+1
	lda t0
	clc
	adc #>FARL
	sta c_fl+2
	sta ek_f+2
	lda t0
	clc
	adc #>FARH
	sta c_fh+2
	rts

	.if PREB
fastrow:	lda row
	ldx set
	beq .s
	clc
	adc #16
.s:	tax
	lda PWA,x               ; the window range: the last draw's, for the next bounds
	sta rba,x
	lda PWB,x
	sta rbb,x
	lda PTA,x
	sta ua
	lda PTB,x
	sta ub
	cmp ua
	beq fr_d2
	bcs fr_go
fr_d2:	jmp fr_done
fr_go:	lda #SHBANK
	tam #4
	lda row
	lsr a
	sta t1
	cla
	ror a
	sta t0
	lda set
	asl a
	asl a
	asl a
	clc
	adc t1
	clc
	adc #>(IMG - $4000)
	sta t1
	lda ua
	asl a
	clc
	adc t0
	sta t0
	bcc fr_a
	inc t1
fr_a:	lda ub
	sec
	sbc ua
	asl a
	sta t2                  ; bytes left
	lda FRAMES
	sta uf
	vsel 0
	lda OP_MAWRLO
	clc
	adc ua
	sta $0002
	lda OP_MAWRHI
	adc #0
	sta $0003
	vsel 2
	lda t0
	sta fr_t+1
	lda t1
	sta fr_t+2
fr_c:	lda t2
	beq fr_e
	cmp #33
	bcc fr_l
	lda #32
fr_l:	sta fr_t+5
	sta t3
fr_t:	tia $8000, $0002, 32
	lda fr_t+1
	clc
	adc t3
	sta fr_t+1
	bcc fr_n
	inc fr_t+2
fr_n:	lda t2
	sec
	sbc t3
	sta t2
	bra fr_c
fr_e:	lda FRAMES
	cmp uf
	bne fr_a
fr_done:	lda #T2
	tam #4
	inc rows
	lda rows
	cmp #16
	beq fr_end
	lda save3
	tam #3
	lda save4
	tam #4
	rts
fr_end:	ldx set                 ; drawn from the image: the image's list becomes the set's, its pins go
	inc nhit
	bne *+5
	inc nhit+1
	lda plcs,x
	sta lcs,x
	lda #$FF
	jsr pins
	ldx set
	lda lstpg,x
	pha
	lda prelst,x
	sta lstpg,x
	pla
	sta prelst,x
	stz pval,x
	lda set
	jsr settab
	jmp rowend3
	.endif
rowend:	tma #3
	sta save3
	tma #4
	sta save4
	lda #T2
	tam #4
rowend2:	ldx set                 ; the buffer is drawn: its list and columns
	lda lc
	sta lcs,x
rowend3:	ldx set
	inc dgen,x
	lda cn
	sta dcn,x
	lda cm
	sta dcm,x
	lda #1
	sta dvalid,x
	lda #$FF                ; the images it needs are not there yet, whatever the phase
	sta updn,x
	lda #1
	sta dfull,x
	stz bla,x
	.if PROF
	lda $0C00
	sta tpd
	.endif
	jsr upload
	.if PROF
	lda $0C00
	sta tpu
	.endif
	lda save3
	tam #3
	lda save4
	tam #4
	rts

; A = +1 / $FF: the pins of set X's image list, up and down (T2 at MPR4)
	.if PREB                ; (the prebuilt rows' pins: left out with them)
pins:	sta pdel                ; (X kept)
	phx
	lda prelst,x
	sta .l+2
	lda plcs,x
	beq .x
	tay
.n:	dey
.l:	ldx PL0,y
	lda PIN,x
	clc
	adc pdel
	sta PIN,x
	cpy #0
	bne .n
.x:	plx
	rts
pdel:	.db 0

	.endif
; the columns of this row to write: those that may not be far now (near / mid columns of the row inside the window) or were not in
; this buffer's last draw. Carry set: none. ua = first, c_end = past the last, per set and row the range kept in rba / rbb.
bounds:	jsr bwin
.c:	lda row                 ; per set and row
	ldx set
	beq .s
	clc
	adc #16
.s:	tax
	lda set
	tay
	lda dfull,y
	bne .old
	phx
	lda bla,y
	bne .all
	ldx row
	lda cn
	clc
	adc #36
	cmp rnf,x
	bcs .all
	lda cm
	clc
	adc #36
	cmp rmf,x
	bcs .all
	plx
	lda #33
	sta t0
	stz ub2
	bra .st
.all:	plx
	stz t0
	lda #33
	sta ub2
	bra .st
.old:	lda rba,x
	sta t0
	lda rbb,x
	sta ub2
.st:	lda ua                  ; the window range is the next draw's "last"
	sta rba,x
	lda ub
	sta rbb,x
	lda t0                  ; the union with the last draw
	cmp ua
	bcs .a
	sta ua
.a:	lda ub2
	cmp ub
	bcc .b
	sta ub
.b:	lda ub
	sta c_end+1
	lda ua
	cmp ub
	rts                     ; (carry set when first >= past the last)
; the window: ua / ub = the columns of this row with a near or mid tile at cn / cm
bwin:	lda #33
	sta ua
	stz ub
	ldx row
	lda rnf,x               ; near
	cmp #$FF
	beq .m
	ldy cn
	jsr .win
.m:	ldx row
	lda rmf,x
	cmp #$FF
	beq .ex
	sta t0
	lda rml,x
	sta t1
	ldy cm
	bra .wn2
.win:	sta t0                  ; near: first in A, X = row
	lda rnl,x
	sta t1
.wn2:	sty t2                  ; window c .. c + 32 against first t0, last t1 (map columns)
	lda t1
	cmp t2
	bcc .ex                 ; last < c
	lda t2
	clc
	adc #32
	cmp t0
	bcc .ex                 ; first > c + 32
	lda t0
	sec
	sbc t2
	bcs .f
	cla
.f:	cmp ua
	bcs .g
	sta ua
.g:	lda t1
	sec
	sbc t2
	inc a
	cmp #33
	bcc .h
	lda #33
.h:	cmp ub
	bcc .ex
	sta ub
.ex:	rts
; image mode: per set the window (PWA / PWB) and its union with that set's last draw (PTA / PTB); ua / c_end = the union of both
; (words outside the window are far words, the same for both sets). Carry set: nothing in this row.
	.if PREB                ; (image mode: left out with the prebuilt rows)
pbounds:	jsr bwin
	lda ua
	sta t2                  ; the window
	lda ub
	sta t3
	lda #33
	sta ua
	stz ub
	ldx #1
.s:	txa
	beq .r0
	lda row
	clc
	adc #16
	bra .r1
.r0:	lda row
.r1:	tay
	lda t2
	sta PWA,y
	lda t3
	sta PWB,y
	lda dfull,x
	bne .old
	stz t0
	lda #33
	sta t1
	bra .un
.old:	lda rba,y
	sta t0
	lda rbb,y
	sta t1
.un:	lda t0                  ; this set's union
	cmp t2
	bcc .a
	lda t2
.a:	sta PTA,y
	cmp ua
	bcs .b
	sta ua
.b:	lda t1
	cmp t3
	bcs .c
	lda t3
.c:	sta PTB,y
	cmp ub
	bcc .d
	sta ub
.d:	dex
	bpl .s
	lda ub
	sta c_end+1
	lda ua
	cmp ub
	rts

	.endif
handover:	lda act
	beq .ac
	.if BANDON
	cmp #2
	bne .a1
	lda CAMX                ; the band path: lets go at camera BAND - 16, aligned (its hysteresis: it keeps drawing down to 626)
	and #15
	bne .xj
	lda hcl
	cmp #<(BLET + 1)        ; (quarry-bridge-draw: both operands, ho_bl / ho_bh, 0 while the bridge draws, brm: its own switch lets
	lda hch                 ; go, bpos)
	sbc #>(BLET + 1)
	bcc .bx
.xj:	jmp .x
.bx:	lda #9                  ; band_exit
	jsr callb
	bra .sd
.a1:
	.endif
	lda hcl                 ; camera 320 or more on any pass, aligned or not (a knockback, any step over 2 px): stand down at once
	cmp #<THARD
	lda hch
	sbc #>THARD
	bcs .sd
.ac:	lda CAMX
	and #15
	beq .al
	lda act                 ; (off the 16-px grid: a take-over only in a load's dark, the dark set-up's entry at rest anywhere)
	bne .xj
	lda <LOCKZP
	and #$18
	beq .xj
.al:	lda act
	beq .off
	ldx iz                  ; the edge store at its high-water mark (the last image bank of ibt in use, or EKMAX keys made: the
	lda ibt+1,x             ; key table fills at 765): stand down on this aligned pass and set up again (an empty store: einit),
	beq .full
	lda nkeys+1
	cmp #>EKMAX
	bcc .nf
	lda nkeys
	cmp #<EKMAX
	bcs .full
.nf:	lda hcl
	cmp #<(THAND + 16)
	lda hch
	sbc #>(THAND + 16)
	bcs .sd
	jsr w3rdy               ; (below the hand-over: every edge key of the windows it can show before the next aligned pass made,
	bcc .x
	inc nnrd
.sd:	jsr sprest
	stz act
	inc nhand
	bra .inv
.full:	stz setok
	inc nreb
	bra .sd
.off:	lda hcl                 ; camera <= THAND - 16 (aligned, so camera + 16 < THAND + 1)
	cmp #<(THAND + 1)
	lda hch
	sbc #>(THAND + 1)
	bcc .tb
	.if BANDON
	lda hcl                 ; camera >= BAND: the band path (act 2)
	cmp #<(BAND + 16)
	lda hch
	sbc #>(BAND + 16)
	bcc .x
	lda pw_state            ; (once its set-up is done and its groups are in VRAM: band_idle_prewarm's state 4)
	cmp #4
	bne .x
	lda #2
	sta act
	inc nback
	bra .inv
	.else
	bra .x
	.endif
.tb:	jsr w3rdy               ; (the take-over and the take-back: only with the edge keys of the windows A - 1 .. A + 1 made)
	bcc .tk
	inc nnrd
	bra .x
.tk:	lda #1
	sta act
	inc nback
.inv:	jsr dvz
	stz ldir
	.if PREB
	jsr pdrop
	.endif
.x:	rts
dvz:	stz dvalid
	stz dvalid+1
	stz dfull
	stz dfull+1
	rts

ho_bl      = handover + 20     ; (quarry-handover: the low operand: 0 on the pass band 1 draws 624 going left: no let-go on that pass, hpas)
ho_bh      = handover + 25     ; (handover's band test: its high operand, 0 while the bridge draws: with the low one in place the test lets
                               ; go below camera 113 only, where the bridge never draws. A move would not fail the build; the bridge's
                               ; first run shows it: the band path lets go at once)
passbegin:
	.if PROF
	lda $0C00
	sta tpb
	lda FRAMES
	sta tpf
	.endif
	stz pmode
	stz rows
	lda OP_MAWRHI           ; the buffer: BAT row 0-15 or 18-33 (MAWR high = row >> 2)
	cmp #4
	lda #0
	bcc .s0
	inc a
.s0:	sta set
	lda #24
pb_cv      = * - 1
	jsr callb               ; tier the first overlay's c6ld makes the operand cposb's: cpos, then the bridge's switch (quarry-pregen-load)
	lda setok
	bne .ok
	lda dkg
	beq .nd
	stz dkg
	inc dks
	bra .sg0
.nd:	lda ss
	beq .sg0
	lda OP_FARPTR
	cmp fal
	bne .sg1
	lda OP_FARPTR+1
	cmp fah
	beq .x
.sg1:	jmp setbegin
.sg0:	jsr setbegin
.x:	lda #1
	sta ROWGAME
	rts
.ok:	jsr handover
	lda act                 ; (quarry-handover: k17's hold at the left seam is gone: the claim is made on the stand-down's pass at 624 and
	sta t0
	beq .x                  ; (.x: ROWGAME 1)
	stz ROWGAME
	lda #14
	jsr call2
	lda CAMX
	and #6
	sta dn
	lsr a
	sta pn
	lda CAMX
	lsr a
	and #7
	sta dm
	lda OP_NEARPTR
	sta cn
	and #1
	sta ekp
	lda OP_MIDPTR
	sta cm
	.if BANDON
	lda act
	cmp #2
	bne .nb
	cla
	jsr spset
	lda #3                  ; (pmode 3: the band path's rows)
	sta pmode
	lda #3                  ; band_pass (bandjt 3), or the bridge's pass from its store (bandjt 21: bpx): brm, written by the switch
brm        = * - 1
	jsr callb
	.if PROF
	lda $0C00
	sta tpp
	.endif
	rts
.nb:
	.endif
	lda over
	beq .nov
	clc
	adc overn
	sta overn
	bcc .o1
	inc overn+1
.o1:	inc novf
	bne .nov
	inc novf+1
.nov:	stz over
	tma #4
	sta save4
	lda #T2
	tam #4
	jsr agestamp
	lda save4
	tam #4
	lda #2
	sta pmode
	ldx set
	lda dvalid,x
	beq .draw
	lda dcn,x
	cmp cn
	bne .draw
	lda dcm,x
	cmp cm
	beq .st
.draw:	lda #1
	sta pmode
	stz dvalid,x            ; (until it is drawn in full)
	stz lc
.st:	lda set
; set A's tables in the cell loop and the upload
settab:	bne .s1
	lda #<WL0
	sta c_wl+1
	lda #>WL0
	sta c_wl+2
	lda #<WH0
	sta c_wh+1
	lda #>WH0
	sta c_wh+2
	lda lstpg
	sta c_lst+2
	sta u_lst+2
	lda #>VL0
	sta u_vl+2
	lda #>VH0
	sta u_vh+2
	rts
.s1:	lda #<WL1
	sta c_wl+1
	lda #>WL1
	sta c_wl+2
	lda #<WH1
	sta c_wh+1
	lda #>WH1
	sta c_wh+2
	lda lstpg+1
	sta c_lst+2
	sta u_lst+2
	lda #>VL1
	sta u_vl+2
	lda #>VH1
	sta u_vh+2
	rts

w3rdy:	lda #30                 ; (w3rdy2, in the second code sector)
	jmp call2
; A = the camera's window (camera + 16) >> 3 from this pass's hcl / hch (camhand), at most WN - 1 (the bridge: the take-back's first)
wcam:	lda hch
	cmp #2
	bcs .m
	lsr a
	lda hcl
	ror a
	lsr a
	lsr a
	cmp #WN
	bcc .x
.m:	lda #WN - 1
.x:	rts
; A stamp more than 128 passes old is brought to 64 old, so an 8-bit stamp never looks like "this pass" (two tiles a pass)
agestamp:	ldy lpass
	jsr .a
	tya
	eor #$80
	tay
.a:	cpy #POOLN
	bcs .x
	lda lpass
	sec
	sbc STAMP,y
	bpl .x
	lda lpass
	sec
	sbc #64
	sta STAMP,y
.x:	rts

; ---------------------------------------------------------------- the row's 33 cells
; near slot of the pair here, else mid slot, else the far tile. Y = column. A slot gets a pool tile when a cell first shows it,
; is listed once a pass, and past the cap (or with no pool tile free) the cell shows its whole tile (counted in `over`).
cells:	ldy ua
c_n:	lda $FFFF,y
	cmp #EDGEB
	bcs c_ns
	tax
	lda NPO,x
	cmp #PFLAT
	bcc c_put
	bne c_nal
c_nw:                           ; a pair that looks the same at every phase: its left tile, no slot
c_nmap:	lda $FFFF,y
	and #$7F
	clc
	adc nlo
s_nl:	sta $0002
	lda nhi
	adc #0
s_nh:	sta $0003
	bra c_next
c_nov:	inc over
	bra c_nw
c_nal:	stx kk
	jsr nalloc
	bcs c_nov
c_put:	tax
	lda STAMP,x
	cmp pass
	beq c_w
	lda lc
	cmp #SLOTMAX
	bcs c_cap
	lda pass
	sta STAMP,x
	stx t0
	ldx lc
	lda t0
c_lst:	sta LST0,x
	inc lc
	tax
c_w:
c_wl:	lda WL0,x
s_wl:	sta $0002
c_wh:	lda WH0,x
s_wh:	sta $0003
c_next:	iny
c_end:	cpy #33
	bne c_n
	rts
c_cap:	inc over
	jmp c_whole
c_ns:	cmp #NOSLOT
	beq c_m
	jmp c_ne
c_m:	lda $FFFF,y
	cmp #EDGEB
	bcs c_ms
	tax
	lda MPO,x
	cmp #PFLAT
	bcc c_put
	bne c_mal
c_mw:
c_mmap:	lda $FFFF,y
	clc
	adc mlo
s_ml:	sta $0002
	lda mhi
	adc #0
s_mh:	sta $0003
	jmp c_next
c_mov:	inc over
	bra c_mw
c_mal:	stx kk
	jsr malloc
	bcs c_mov
	bra c_put
c_ms:	cmp #NOSLOT
	beq c_fl
	jmp c_me
c_fl:	lda $FFFF,y
s_fl:	sta $0002
c_fh:	lda $FFFF,y
s_fh:	sta $0003
	jmp c_next
; past the cap: which layer's whole tile
c_whole:	lda OWNK,x
	and #3
	bne c_mw2
	jmp c_nw
c_mw2:	cmp #1
	bne c_ef
	jmp c_mw
c_ef:	lda ena
	cmp #$FF
	beq c_ef2
	jmp c_nw
c_ef2:	lda ema
	beq c_ef3
	jmp c_mw
c_ef3:	jmp c_fl
; near tile at only one of c, c + 1 (A: EDGEA / EDGEB): the key from the maps
c_ne:	sty ey
	cmp #EDGEA
	bne c_nb
ek_n:	lda $FFFF,y
	and #$7F
	sta ena
	lda #$FF
	sta enb
	bra c_nu
c_nb:	lda #$FF
	sta ena
	jsr ek_n2
c_nu:	jsr ek_under
	jsr efind32
	ldy ey
	bcs c_efb
c_eput:	jmp c_put
c_efb:	jmp c_ef
; mid tile at only one of them, no near tile
c_me:	.if MEDGE
	sty ey
	lda #$FF
	sta ena
	sta enb
	jsr ek_under
	jsr efind32
	ldy ey
	bcs c_efb
	bra c_eput
	.else
	lda #$FF
	sta ena
ek_ma:	lda $FFFF,y
	sta ema
	jmp c_ef
	.endif
ek_n2:	lda $FFFF,y
	and #$7F
	sta enb
	rts
ek_under:
ek_m:	lda $FFFF,y
	sta ema
ek_m2:	lda $FFFF,y
	sta emb
ek_f:	lda $FFFF,y
	ldx ema
	beq .k
	ldx emb
	beq .k
	cla                     ; (both mid tiles: the far tile never shows)
.k:	sta eff
	lda ekp                 ; near over mid: odd near columns show dm 4-7, even ones 0-3: a key per parity, 4 images each
	beq .x
	lda ema
	ora emb
	beq .x
	lda ena
	cmp #$FF
	beq .nb
	ora #$80
	sta ena
	rts
.nb:	lda enb
	cmp #$FF
	beq .x
	ora #$80
	sta enb
.x:	rts

; a pool tile for near slot kk / mid slot kk; A = it, carry clear; carry set when none is free. Y kept.
nalloc:	lda #0                  ; a pool tile for near slot kk / mid slot kk; A = it, carry clear; carry set when none is free. Y kept.
	bra kalloc
malloc:	lda #1
kalloc:	sta t2
	phy
	jsr talloc
	bcs .x
	ldy kk
	txa
	ldy t2
	bne .m
	ldy kk
	sta NPO,y
	bra .k
.m:	ldy kk
	sta MPO,y
.k:	tya
	sta OWN,x
	lda t2
	sta OWNK,x
	stz t3                  ; its images: bank NPB / MPB + p, k * 32
	tya
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
	sta SRCL,x
	lda t3
	clc
	adc #>IMGWIN
	sta SRCH,x
	lda t2
	beq .nb
	lda #MPB
	sta SRCB,x
	lda mhi
	bra .w
.nb:	lda #NPB
	sta SRCB,x
	lda nhi
.w:	and #$F0
	jsr setw
	txa
	clc
.x:	ply
	rts
setw:	sta t3
	lda WH0,x
	and #$0F
	ora t3
	sta WH0,x
	lda WH1,x
	and #$0F
	ora t3
	sta WH1,x
	rts
; X = a pool tile free to take, carry clear (an old slot loses it, and the other set's buffer is drawn again before it is
; used: it may still show this tile); carry set when none. Y is used.
talloc:	ldx hand
	lda #POOLN
	sta t3
.l:	inx
	cpx #POOLN
	bcc .c
	clx
.c:
	.if PREB
	lda PIN,x               ; (a prebuilt image refers to it)
	bne .n
	.endif
	ldy OWN,x
	cpy #$FF
	beq .take
	lda lpass
	sec
	sbc STAMP,x
	cmp #3
	bcc .n
	lda OWNK,x
	and #3
	bne .m
	lda #PNONE
	sta NPO,y
	bra .inv
.m:	cmp #1
	bne .e
	lda #PNONE
	sta MPO,y
	bra .inv
.e:	jsr erel
.inv:	phx
	lda set
	eor #1
	tax
	stz dvalid,x
	plx
	bra .take
.n:	dec t3
	bne .l
	sec
	rts
.take:	stx hand
	lda #$FF
	sta OWN,x
	lda lpass               ; (no stale "listed" stamp survives a take)
	sec
	sbc #64
	sta STAMP,x
	clc
	rts

; ---------------------------------------------------------------- upload
upload:	ldx set
	lda dn
	cmp updn,x
	bne .go
	lda dm
	cmp updm,x
	bne .go
	stz ups
	rts                     ; (standing: these images are there)
.go:	lda dn
	sta updn,x
	lda dm
	sta updm,x
	lda lcs,x
	sta t1
	sta ups
	cmp maxup
	bcc .m
	sta maxup
.m:	lda #1
	sta dirty
	tma #6
	sta save6
	lda dm                  ; edge images: phase * 32 from the block's start (8 phases by dm, 4 by dn)
	stz adh8
	asl a
	asl a
	asl a
	asl a
	asl a
	rol adh8
	sta adl8
	lda pn
	stz adh4
	asl a
	asl a
	asl a
	asl a
	asl a
	rol adh4
	sta adl4
	ldx #0
u_l:	cpx t1
	bne u_lg
	jmp u_x
u_lg:
u_lst:	ldy LST0,x
	lda pass
	sta STAMP,y
	lda OWNK,y
	and #3
	beq u_n
	cmp #1
	beq u_m
	lsr a                   ; (kind 2 / 3 -> carry clear / set after bit 0)
	lda SRCB,y
	tam #6
	bcs u_e4
	lda SRCL,y
	clc
	adc adl8
	sta u_t+1
	lda SRCH,y
	adc adh8
	sta u_t+2
	bra u_r
u_e4:	lda SRCL,y
	clc
	adc adl4
	sta u_t+1
	lda SRCH,y
	adc adh4
	sta u_t+2
	bra u_r
u_m:	lda dm                  ; mid: bank MPB + (p >> 2), address + (p & 3) * $800
	lsr a
	lsr a
	clc
	adc SRCB,y
	tam #6
	lda SRCL,y
	sta u_t+1
	lda dm
	and #3
	asl a
	asl a
	asl a
	clc
	adc SRCH,y
	sta u_t+2
	bra u_r
u_n:	lda SRCB,y
	clc
	adc pn
u_b:	tam #6
	lda SRCL,y
	sta u_t+1
	lda SRCH,y
	sta u_t+2
u_r:	lda FRAMES
	sta uf
	vsel 0
u_vl:	lda VL0,y
	sta $0002
u_vh:	lda VH0,y
	sta $0003
	vsel 2
u_t:	tia $C000, $0002, 32
	lda FRAMES
	cmp uf
	bne u_r
	inx
	jmp u_l
u_x:	lda save6
	tam #6
	rts

; ---------------------------------------------------------------- setup (once per visit)
SBUD       = 6
SBUDL      = 2
SEBUDL     = 4
SSCLR      = 1
SSFILL     = 2
SSFAR      = 3
SSNEAR     = 4
SSMID      = 5
SSGN       = 6
SSGM       = 7
SSEND      = 8
SSE        = 9
setbegin:
	stz imall               ; (the entry side's part and the background start again)
	stz bsok
	stz bgss
	stz bgf
	stz ekon
	ldx #15                 ; (no edge slot in any row yet)
.er:	stz erow,x
	dex
	bpl .er
	lda FRAMES
	sta tset0
	lda OP_NEARLO
	sta nlo
	lda OP_NEARH0
	clc
	adc OP_NEARHI
	sta nhi
	lda OP_MIDLO
	sta mlo
	lda OP_MIDHI
	clc
	adc #$10
	sta mhi
	lda OP_FARLO
	sta flo
	lda OP_FARHI
	clc
	adc #$20
	sta fhi
	lda OP_FARPTR           ; far row 0 (the row's pointer: this is the pass's first row)
	sta fal
	lda OP_FARPTR+1
	sta fah
	tma #4
	sta ssb4
	tma #6
	sta ssb6
	jsr dvz
	lda #SSCLR
	sta ss
	stz si
	stz sj
	rts

idlework:	lda dks                 ; (the dark set-up first: the window's keys and the band's set-up follow from it)
	beq .i1
	lda #21                 ; (didle in the resident area: dstall, in the stub bank's piece)
	ldx #C5BANK             ; (cx5; quarry-spire-fix: satbody's call 30 ends here too)
	jmp callx
.i1:	lda #22                 ; (third area, qidle: the restore before the hand-off, step 3; carry set: it ran)
	jsr call2
	bcc .i
	rts
.i:	lda ss
	beq .i2
	jsr ssrun               ; (the set-up's steps on their units, then, from the pair images on, edge keys on the clock)
	lda FRAMES
	cmp sfr
	bne .r
	lda ekon
	beq .r
	lda ss
	cmp #SSGN
	bcc .r
	cmp #SSEND
	bcs .r
	sta ssv
	jsr .a2
	lda ssv
	sta ss
	stz ssv
.r:	rts
.i2:	lda setok
	beq .x
	lda act
	beq .a0
	cmp #1
	beq .a1ok
	.if PROF
	lda $0C00
	sta tpi
	.endif
	rts
.a0:	lda bgss
	beq .a0b
	lda #34
	jsr call2
	bcc .a0b
	rts
.a0b:	lda CAMX+1              ; (camera below 512: from 512 the band's prewarm has the idle)
	bmi .a3
	cmp #2
	bcs .x
.a3:	bra .a2                 ; (quarry-bridge-store: sfr is ssrun's own stamp, before any use: 6 bytes for its call of bslice)
.a1ok:
	.if PREB
	lda FRAMES
	sta sfr
	jsr prework
	lda FRAMES
	cmp sfr
	bne .x
	.else
	bra .a3
	.endif
.a2:	stz sdone
	lda #SSE                ; the slots are made: edge keys in the rest of the idle time
	sta ss
	jsr ssrun
	stz ss
	.if PROF
	lda $0C00
	sta tpi
	lda FRAMES              ; (profiling) the idle work ran past the frame it began in: which key step was running
	cmp sfr
	beq .x
	inc nidov
	lda bst
	sta idovb
	lda bi
	sta idovi
	lda ep
	sta idove
	.endif
.x:	rts
idcx       = idlework + 5      ; (lda #21 / ldx #C5BANK / jmp callx: didle, also band_idle_prewarm's last state)
cx5        = idlework + 7      ; (ldx #C5BANK / jmp callx: satbody's call 30, quarry-spire-fix)
ssrun:	jsr tok                 ; (the clock's stamp, if the playfield is still on)
	tma #3
	sta sv3
	tma #4
	sta sv4
	tma #6
	sta sv6
	lda FRAMES
	sta sfr
	lda #SBUD
	ldx early
	bne .b
	lda #SBUDL
	ldx ss
	cpx #SSE
	bne .b
	lda #SEBUDL
	ldx act
	bne .b
	lda #0
.b:	sta sbud
	stz early
.l:	lda ss
	beq .out
	lda FRAMES
	cmp sfr
	bne .out
	lda ss
	cmp #SSE
	bne .u
	jsr tok                 ; edge keys: as long as a step ends before the vblank (the clock), else the units as before
	beq .go
	lsr a
	bcc .out
.u:	lda sbud
	bmi .out
	beq .out
.go:	lda #T1
	tam #3
	lda #T2
	tam #4
	jsr sstep
	sta t3
	lda sbud
	sec
	sbc t3
	sta sbud
	lda ss
	cmp #SSE
	bne .l
	lda sdone               ; (nothing left for now)
	beq .l
.out:	lda sv3
	tam #3
	lda sv4
	tam #4
	lda sv6
	tam #6
	lda ss
	cmp #SSE
	bne .r
	jsr idcx
	cly
.sp:	lda FRAMES
	cmp sfr
	bne .v
	lda TIMER
	and #$7F
	tay
	iny
	bra .sp
.v:	tya
	beq .r                  ; (the vblank went by before the wait: no stamp)
	clc
	adc #40
	cmp #116
	bcc .h
	sbc #116
.h:	sta hut
	lda sfr
	sta huf
.r:	rts

sstep:	lda ss
	asl a
	tax
	jmp [ss_jt - 2,x]
ss_jt:	.dw ss_clr, ss_fill, ss_far2, ss_near, ss_mid, ss_gn, ss_gm, ss_end, ss_e

; zero the pool if images are there, 20 tiles a step
ss_clr:	lda dirty
	beq .nx
	lda #20
	sta t2
.t:	jsr clrnext
	beq .all
	dec t2
	bne .t
	lda #1
	rts
.all:	stz dirty
.nx:	stz si
	lda #SSFILL
	sta ss
	lda #1
	rts

; the tables: pages of T1 with $FF (slots) and T2's chains, pool; 4 pages a step
ss_fill:	lda #24                 ; (in the stub bank's piece: ssfill)
	ldx #C5BANK
	jmp callx
sv_a:	.db 0
sv_b:	.db 0
mpalh:	.db $50, $30, $40
flo:	.db 0
fhi:	.db 0
fal:	.db 0
fah:	.db 0
; A = tile high, kk = tile low: sv_a / sv_b = its VRAM address

; near pairs a column (16 rows) a call, three a step, in the order nsd gives from sj (f_e): slots are numbered as first seen, so the
; entry side's are 0 .. nk1 - 1 (nk at the boundary column nbc)
ss_near:	lda ssb6
	tam #6
	lda #3
	sta t2
n_col:	stz si
	ldy sj
n_r:	lda si
	clc
	adc #$C0
	sta n_a+2
	sta n_b+2
	sta n_b0+2
	lda si
	clc
	adc #>NSLOT
	sta n_d+2
n_c:
n_a:	lda $FF00,y
	and #$7F
	sta kk
	tax
	lda prop,x
	bpl n_an                ; a near tile at c?
n_b0:	lda $FF01,y             ; no: near at c + 1 only?
	and #$7F
	tax
	lda prop,x
	bmi n_nn
	lda #EDGEB
	bra n_d
n_nn:	lda #NOSLOT
	bra n_d
n_an:
n_b:	lda $FF01,y
	and #$7F
	sta t1
	tax
	lda prop,x
	bpl n_pr
	lda #EDGEA
	bra n_d
n_pr:	phy
	jsr nslot
	ply
n_d:	sta $6000,y
	cmp #NOSLOT
	beq n_nb
	cmp #EDGEB              ; (an edge slot: the look-ahead scans this row)
	bcc n_eb
	ldx si
	sta erow,x
n_eb:	jsr nbound
n_nb:	inc si
	lda si
	cmp #16
	bne n_r
	cpy nbc                 ; (the column done: the boundary's count)
	bne .b
	lda nk
	sta nk1
.b:	lda nsd
	beq .up
	dey
	cpy #$FF
	beq n_row
	bra .nx
.up:	iny
	cpy #NCOLS
	beq n_row
.nx:	sty sj
	dec t2
	beq .st
	jmp n_col
.st:	lda #1
	rts
n_row:	stz sj
	stz si
	lda #SSMID
	sta ss
	lda #1
	rts

; mid pairs a column (16 rows) a call, from column 0, three a step: the open quarry's slots (first seen in columns 0 .. MBND) are
; 0 .. mk1 - 1; the others are never drawn here (no images). At the end: the set-up's image ranges and the background's (ss_end2).
ss_mid:	lda ssb6
	tam #6
	lda #3
	sta t2
.col:	stz si
	ldy sj
.r:	lda si
	clc
	adc #$D0
	sta .a+2
	sta .b+2
	sta .b0+2
	lsr a
	cla
	ror a
	sta .d+1
	lda si
	lsr a
	clc
	adc #>MSLOT
	sta .d+2
.a:	lda $FF00,y
	bne .an
.b0:	lda $FF01,y
	beq .n0
	lda #EDGEB
	bra .d
.n0:	lda #NOSLOT
	bra .d
.an:	sta kk
.b:	lda $FF01,y
	bne .pr
	lda #EDGEA
	bra .d
.pr:	sta t1
	phy
	jsr mslot
	ply
.d:	sta $FFFF,y
	cmp #NOSLOT
	beq .nb
	cmp #EDGEB
	bcc .eb
	ldx si
	sta erow,x
.eb:	jsr mbound
.nb:	inc si
	lda si
	cmp #16
	bne .r
	cpy #MBND
	bne .m
	lda mk
	sta mk1
.m:	iny
	sty sj
	cpy #MCOLS
	beq .row
	dec t2
	bne .col
	lda #1
	rts
.row:	stz sj
	stz si                  ; the set-up's images: near 0 .. nk1 - 1; mid 0 .. mk1 - 1 from the open quarry's side, none from the band's
	lda nk1
	sta gnh
	stz gml
	lda mk1
	ldx nsd
	beq .g
	cla
.g:	sta gmh
	lda #SSGN
	sta ss
	lda $3224
	bne .y
	lda #6                  ; einit
	jsr call2
	inc ekon
.y:	lda #1
	rts

; row si, column Y has a tile: the row's first and last
nbound:	ldx si
	tya
	cmp rnf,x
	bcs .l
	sta rnf,x
.l:	cmp rnl,x
	bcc .x
	sta rnl,x
.x:	rts
mbound:	ldx si
	tya
	cmp rmf,x
	bcs .l
	sta rmf,x
.l:	cmp rml,x
	bcc .x
	sta rml,x
.x:	rts

; the slot of near pair (kk, t1), made if new; A = slot (past KMAX the pair shows its left tile)
nslot:	lda #KMAX
	sta k_cm+1
	lda #>NFIRST            ; the slot of near pair (kk, t1) (codes), made if new; A = slot (past KMAX the pair shows its left tile)
	sta k_f+2
	sta k_f2+2
	sta k_f3+2
	lda #>NNEXT
	sta k_n+2
	sta k_n2+2
	lda #>NCB
	sta k_b+2
	sta k_b2+2
	lda #>NCA
	sta k_a+2
	lda #<nk
	bra kslot
mslot:	lda #>MFIRST            ; (mid)
	sta k_f+2
	sta k_f2+2
	sta k_f3+2
	lda #>MNEXT
	sta k_n+2
	sta k_n2+2
	lda #>MCB
	sta k_b+2
	sta k_b2+2
	lda #>MCA
	sta k_a+2
	lda #MKMAX
	sta k_cm+1
	lda #<mk
kslot:	sta k_c+1
	sta k_c2+1
	sta k_c3+1
	ldy kk
k_f:	lda NFIRST,y
ks_ch:	cmp #$FF
	beq ks_new
	tax
k_b:	lda NCB,x
	cmp t1
	beq ks_have
k_n:	lda NNEXT,x
	bra ks_ch
ks_have:	txa
	rts
ks_new:
k_c:	lda nk
k_cm:	cmp #KMAX
	bcc ks_mk
	lda #EDGEA
	rts
ks_mk:	ldy kk
k_c2:	ldx nk
k_c3:	inc nk
k_f2:	lda NFIRST,y
k_n2:	sta NNEXT,x
	txa
k_f3:	sta NFIRST,y
	lda t1
k_b2:	sta NCB,x
	lda kk
k_a:	sta NCA,x
	txa
	rts

ss_gn:	lda si
	cmp gnh
	bcc .go
	lda gml
	sta si
	lda #SSGM
	sta ss
	lda #0
	rts
.go:	lda #>NCA
	sta g_a+2
	lda #>NCB
	sta g_b+2
	lda #>NPO
	sta g_o+2
	lda nlo
	sta g_lo+1
	lda nhi
	sta g_hi+1
	lda #2
	sta g_st
	lda #NPB
	sta g_bk
	bra gslot
ss_gm:	lda si
	cmp gmh
	bcc .go
	lda #SSEND
	sta ss
	lda #0
	rts
.go:	lda #>MCA
	sta g_a+2
	lda #>MCB
	sta g_b+2
	lda #>MPO
	sta g_o+2
	lda mlo
	sta g_lo+1
	lda mhi
	sta g_hi+1
	lda #1
	sta g_st
	lda #MPB
	sta g_bk
gslot:	lda si
	sta kk
	tax
g_a:	lda NCA,x
	jsr g_w
	ldx #0
	jsr rdtile
	ldx kk
g_b:	lda NCB,x
	jsr g_w
	ldx #32
	jsr rdtile
	jsr dstk
	stz t2
	lda #1
	sta t3                  ; flat so far
	lda #SHBANK
	tam #6
.gp:	lda t2
	ldx g_st
	cpx #2
	bne .m
	lsr a
	bra .b
.m:	pha                     ; mid: four phases a bank, (p & 3) * $800 on
	and #3
	asl a
	asl a
	asl a
	clc
	adc gd2
	sta gdst+2
	pla
	lsr a
	lsr a
.b:	clc
	adc g_bk
	tam #4
	jsr genph
	lda t2
	clc
	adc g_st
	sta t2
	cmp #8
	bne .gp
	lda #T2
	tam #4
	ldx kk
	lda t3
	beq g_ko
	lda #PFLAT
g_o:	sta NPO,x
g_ko:	inc si
	lda #1
	rts
g_w:	clc                     ; the tile's word: A = low, Y = high
g_lo:	adc #0
	pha
g_hi:	lda #0
	adc #0
	tay
	pla
	rts
g_st:	.db 0
g_bk:	.db 0
gd2:	.db 0           ; dstk's high byte (the mid phases add to it)

; done: the next pass draws with the slots
ss_end:	lda #16                 ; (in the second code sector: ss_end2)
	jmp call2

; pool tile si of both sets zeroed; Z set when it was the last, si back at 0
clrnext:	lda #T2
	tam #4
	ldx si
	lda VL0,x
	ldy VH0,x
	jsr clr1
	ldx si
	lda VL1,x
	ldy VH1,x
	jsr clr1
	inc si
	lda si
	cmp #POOLN
	bne .x
	stz si
	cla
.x:	rts
clr1:	sta t1
	sty t3
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
	rts

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
	bbs6 <SPLITS, .on
	sei
.on:	vsel 1
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
	sta gd2
	rts

; phase t2 of (srca, srcb) to gdst: byte = SHL[p][A] | SHR[p][B] (phase 0: A); t3 cleared when it differs from A
genph:	lda t2
	bne .sh
	ldy #31
	lda gdst+1
	sta .d+1
	lda gdst+2
	sta .d+2
.c:	lda srca,y
.d:	sta $8000,y
	dey
	bpl .c
	rts
.sh:	asl a
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
	cmp srca,y
	beq .s
	stz t3
.s:	dey
	bpl gph_l
	rts

; ---------------------------------------------------------------- layer edges
epage:	lda ep
	asl a
	asl a
	asl a
	clc
	adc ep
	adc #$60
	sta t2
	rts

efind32:	cpy #32
	bne efind
	sec
	rts
; look up / insert the key (ena .. eff). Carry clear: A = its pool tile (it may be new). Carry set: not ready. X is free, Y is used.
efind:	lda efill
	beq .go
	sec                     ; (T3 not cleared yet)
	rts
.go:	lda enb                 ; group and entry
	eor eff
	and #3
	cmp #3
	bne .p
	cla
.p:	sta ep
	jsr epage
	sta ef_a+2
	inc a
	sta ef_b+2
	inc a
	sta ef_c+2
	inc a
	sta ef_d+2
	inc a
	sta ef_e+2
	inc a
	sta ef_o+2
	lda #T3
	tam #3
	lda ena
	asl a
	eor enb
	asl a
	eor ema
	asl a
	eor emb
	asl a
	eor eff
	tay
	ldx #48                 ; probes
ef_l:
ef_a:	lda $6000,y
	cmp #EEMPTY
	beq ef_new
	cmp ena
	bne ef_nx
ef_b:	lda $6000,y
	cmp enb
	bne ef_nx
ef_c:	lda $6000,y
	cmp ema
	bne ef_nx
ef_d:	lda $6000,y
	cmp emb
	bne ef_nx
ef_e:	lda $6000,y
	cmp eff
	bne ef_nx
	sty el
ef_o:	lda $6000,y
	cmp #EP_NONE
	bcc ef_hit              ; a pool tile
	cmp #EP_FREE
	beq ef_al
	cmp #EP_WAIT
	beq ef_ms
ef_no:	lda #T1
	tam #3
	sec
	rts
ef_hit:	tax
	lda #T1
	tam #3
	txa
	clc
	rts
ef_nx:	iny
	dex
	bne ef_l
	bra ef_ms
ef_new:	sty el
	lda qh
	inc a
	and #QN - 1
	cmp qt
	beq ef_ms
	tax
	lda ep
	ldy qh
	sta QP,y
	lda el
	sta QL,y
	stx qh
	lda ena
	ldx #FNA
	jsr efput
	lda enb
	ldx #FNB
	jsr efput
	lda ema
	ldx #FMA
	jsr efput
	lda emb
	ldx #FMB
	jsr efput
	lda eff
	ldx #FFF
	jsr efput
	lda #EP_WAIT
	ldx #FPO
	jsr efput
	inc nkeys
	bne ef_no2
	inc nkeys+1
ef_no2:	jmp ef_ms
ef_al:	lda eprobe
	beq ef_al2
	jmp ef_no
ef_al2:	jsr ealloc
	bcc ef_got
ef_ms:	lda eprobe              ; a cell drawn without its edge image (not a look-ahead probe): counted
	bne ef_n3
	inc nkmiss
	bne ef_n3
	inc nkmiss+1
ef_n3:	jmp ef_no
ef_got:	tax
	lda #T1
	tam #3
	txa
	clc
	rts
efill:	.db 0
sdone:	.db 0
eprobe:	.db 0
pmx:	.db 0
; write A into field X of entry el of group ep (T3 at MPR3)
efput:	pha
	jsr epage
	txa
	clc
	adc t2
	sta .w+2
	pla
	ldy el
.w:	sta $6000,y
	rts
; A = field X of the entry (T3 at MPR3)
efget:	jsr epage
	txa
	clc
	adc t2
	sta .r+2
	ldy el
.r:	lda $6000,y
	rts
; the pool tile of entry el, group ep: A = it, carry clear; carry set when none is free. (T3 at MPR3, T2 at MPR4)
ealloc:	jsr talloc
	bcs .x
	txa
	phx
	ldx #FPO
	jsr efput
	plx
	lda el
	sta OWN,x
	lda ep
	asl a
	asl a
	sta t1
	lda ena
	and enb
	cmp #$FF
	bne .k4                 ; (a near tile: 4 images by dn; a mid tile alone: 8 by dm)
	lda #2
	bra .k
.k4:	lda #3
.k:	ora t1
	sta OWNK,x
	phx
	ldx #FB
	jsr efget
	plx
	sta SRCB,x

	phx
	ldx #FAL
	jsr efget
	plx
	sta t1
	and #$80
	sta SRCL,x
	phx
	ldx #FAH
	jsr efget
	plx
	sta SRCH,x
	lda t1
	and #3
	phx
	tax
	lda mpalh,x
	plx
	jsr setw
	txa
	clc
.x:	rts
; an edge key loses its pool tile (Y = entry, OWNK,x its group). X kept.
erel:	tma #3
	pha
	lda t2                  ; (epage below writes t2; kalloc holds the slot's kind in it across talloc)
	pha
	lda ep
	pha
	lda el
	pha
	sty el
	lda OWNK,x
	lsr a
	lsr a
	and #3
	sta ep
	lda #T3
	tam #3
	phx
	ldx #FPO                ; (only if the entry still holds this tile: an emptied store, ereset, leaves the pool's old owners)
	jsr efget
	plx
	sta wq2
	cpx wq2
	bne .k
	phx
	lda #EP_FREE
	ldx #FPO
	jsr efput
	plx
.k:	pla
	sta el
	pla
	sta ep
	pla
	sta t2
	pla
	tam #3
	rts

ss_e:	lda erq
	beq .e0
	stz erq
	lda #32                 ; ereset
	jmp call2
.e0:	lda efill
	beq .ok
	dec a
	sta efill
	tax
	lda ef_pg,x
	sta .fw+2
	lda ef_v,x
	tax
	lda #T3
	tam #3
	txa
	cly
.fw:	sta $6000,y
	iny
	bne .fw
	lda #1
	rts
.ok:	lda bst
	beq .q
	jmp .b
.q:	lda qh
	cmp qt
	bne .pop
	jsr escan
	lda #1
	rts
.pop:	ldy qt
	lda QP,y
	sta bp
	lda QL,y
	sta bl
	tya
	inc a
	and #QN - 1
	sta qt
	lda #T3
	tam #3
	lda bp
	sta ep
	lda bl
	sta el
	ldx #FNA
	jsr efget
	sta bna
	ldx #FNB
	jsr efget
	sta bnb
	ldx #FMA
	jsr efget
	sta bma
	ldx #FMB
	jsr efget
	sta bmb
	ldx #FFF
	jsr efget
	sta bff
	stz bs
	stz bpar
	lda bna
	cmp #$FF
	beq .pb
	bpl .pc
	and #$7F
	sta bna
	inc bpar
	bra .pc
.pb:	lda bnb
	cmp #$FF
	beq .pc
	bpl .pc
	and #$7F
	sta bnb
	inc bpar
.pc:	lda bma
	ora bmb
	beq .tn
	lda bna
	and bnb
	cmp #$FF
	bne .t1
	lda #2
	bra .ts
.t1:	lda #1
	bra .ts
.tn:	cla
.ts:	sta bT
	lda #1
	sta bst
	rts
.b:	cmp #1
	beq .src
	jmp egen
.src:	lda #T3
	tam #3
	lda bp
	sta ep
	lda bl
	sta el
	jsr esrc
	lda #1
	rts
ef_pg:	.db $60, $69, $72, $7B, $7C, $7D, $7E, $7F
ef_v:	.db $FE, $FE, $FE, 0, 0, 0, 0, 0

esrc:	ldx bs
	cpx #5
	bne .s
	jmp eblock
.s:	stz bidx,x
	lda bna,x
	cpx #2
	bcs .mf
	cmp #$FF                ; near
	beq .next
	ldy #0
	bra .get
.mf:	cpx #4
	beq .far
	cmp #0                  ; mid
	beq .next
	ldy #1
	bra .get
.far:	ldy bma
	beq .fa
	ldy bmb
	bne .next               ; (both mid tiles: far hidden)
.fa:	ldy #2
.get:	ldx rnext               ; (a tile still to recolour ends the step before it: the next step does it, in its own time)
	stx rpk
	jsr rmget
	bcc .ok
	cmp #$FE
	bne .none
	lda #1
	sta rnext
	rts
.ok:	ldx bs
	sta bidx,x
.next:	stz rnext
	inc bs
	rts
.none:	lda #EP_NONE
	ldx #FPO
	jsr efput
	inc nnofit
	stz bst
	rts

mrtl:	.db <RN0, <RN2, 0, 0, <RM0, <RM2, <RF0, 0, <RF2
mrth:	.db >RN0, >RN0, 0, 0, >RM0, >RM2, >RF0, 0, >RF2
rmget:	sta t2                  ; (code)
	sty t3
	lda bT
	sta kk
	tya
	asl a
	clc
	adc t3
	clc
	adc kk
	tax
	lda mrtl,x
	sta .r+1
	sta rm_w+1
	lda mrth,x
	sta .r+2
	sta rm_w+2
	beq .bad
	ldx t2
.r:	lda $6000,x
	cmp #0
	beq .make
	cmp #$FF
	beq .bad
	clc
	rts
.bad:	sec
	rts
.make:	lda rpk                 ; (a look only: A $FE, carry set)
	bne .mk
	lda #$FE
	sec
	rts
.mk:	lda t3                  ; the tile's word
	bne .wm
	lda t2
	clc
	adc nlo
	sta t0
	lda nhi
	adc #0
	bra .wd
.wm:	cmp #1
	bne .wf
	lda t2
	clc
	adc mlo
	sta t0
	lda mhi
	adc #0
	bra .wd
.wf:	lda t2                  ; far: the key holds the word's low byte
	sta t0
	cmp flo
	lda fhi
	bcs .wd
	inc a
.wd:	tay
	sta rmh
	lda t2
	sta rmc
	lda t3
	sta rml2
	lda t0
	ldx #0
	jsr rdtile
	lda rml2                ; the map: pmap + (layer * 3 + k) * 16
	asl a
	clc
	adc rml2
	clc
	adc kk
	asl a
	asl a
	asl a
	asl a
	sta t3
	ldx kk
	lda rmns,x
	ldy kk                  ; (near + far: the whole bank; the others share theirs with images past tile 96)
	beq .cap
	cmp #96
	bcs .nf
.cap:	cmp #128                ; (near + far: CBANK's top 4 KB is code, so 128 tiles; the others share theirs with images past tile 96)
	bcs .nf
	jsr rmdst
	lda #T2
	tam #3
	jsr recolor
	lda #T3
	tam #3
	lda rbad
	bne .nf
	ldx kk
	lda rmns,x
	inc rmns,x
	jsr rmset
	lda #T2
	tam #4
	lda t1
	clc
	rts
.nf:	lda #T2
	tam #4
	lda #$FF
	jsr rmset
	sec
	rts
rmh:	.db 0
rmc:	.db 0
rml2:	.db 0
rmset:	sta t1                  ; the table entry = A; t1 = A
	ldx rmc
	lda t1
rm_w:	sta $6000,x
	rts
rmdst:	lda kk
	clc
	adc #T4
	tam #4
	ldx kk
	lda rmns,x
	stz t1
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	sta rmw+1
	lda t1
	clc
	adc #$80
	sta rmw+2
	rts
rmst:
rmw:	sta $8000,y
	rts
recolor:	stz rbad
	lda t3                  ; a map that keeps every index it holds (the mid in mid + far): the planes as they are
	clc
	adc #15
	tax
	ldy #15
.ic:	lda pmap - $2000,x
	cmp #$FF
	beq .in
	sta t2
	cpy t2
	bne .sl
.in:	dex
	dey
	bne .ic
	ldy #31
.cp:	lda srca,y
	jsr rmst
	dey
	bpl .cp
	rts
.sl:	lda #15                 ; (recols, in the fourth code area)
	ldx #C5BANK
	jmp callx
wpo:	.db 0, 1, 2, 3, 4, 5, $FF, $FE
	.db 2, 3, 4, 1, 5, 0, $FF, 6
rbad:	.db 0
rbit:	.db $01, $02, $04, $08, $10, $20, $40, $80
r0:	.db 0
r1:	.db 0
r2:	.db 0
r3:	.db 0
o0:	.db 0
o1:	.db 0
o2:	.db 0
o3:	.db 0
kk2:	.db 0

eblock:	lda #4                  ; 4 phases, or 8 for a mid tile over far (near over mid: 4 of its parity)
	ldy bma
	bne .e8
	ldy bmb
	beq .n
.e8:	ldy bna
	cpy #$FF
	bne .n
	ldy bnb
	cpy #$FF
	bne .n
	lda #8
.n:	sta bn
	cmp #8
	bne .c
	lda ia
	sta t1
	lda ia+1
	inc a
	bra .cc
.c:	lda ia
	clc
	adc #$80
	sta t1
	lda ia+1
	adc #0
.cc:	cmp #$E0
	bcc .room
	beq .eq
.next:	inc iz
	ldx iz
	lda ibt,x
	bne .nb
	dec iz                  ; (out of image space)
	lda #EP_NONE
	ldx #FPO
	jsr efput
	inc nnofit
	stz bst
	rts
.nb:	sta ib
	stz ia
	lda ibs,x
	cmp #2
	bne .pg
	lda nk                  ; (nk * 32 rounded up to a page)
	dec a
	lsr a
	lsr a
	lsr a
	inc a
	clc
	adc #$C0
.pg:	sta ia+1
	jmp eblock
.eq:	lda t1
	beq .room
	bra .next
.room:	lda ib
	sta bb
	sta bbk
	lda ia
	sta bal
	lda ia+1
	sta bah
	lda bn                  ; the next
	cmp #8
	bne .a4
	inc ia+1
	bra .af
.a4:	lda ia
	clc
	adc #$80
	sta ia
	lda ia+1
	adc #0
	sta ia+1
.af:	lda bb
	ldx #FB
	jsr efput
	lda bal
	ora bT
	ldx #FAL
	jsr efput
	lda bah
	ldx #FAH
	jsr efput
	stz bi
	lda #2
	sta bst
	rts
bbk:	.db 0
bpar:	.db 0
ekp:	.db 0
ibt:	.db EBANK0, BAND0 + 4, BAND0 + 5, EBANK0 + 3, T4 + 1, T4 + 2  ; (not KEEP1, KEEP2; not MPB: packed full; not BAND0-BAND0 + 3:
	.db NPB, NPB + 1, 0, 0, 0
ibs:	.db $C0, $C0, $C0, $DF, $CC, $CC, 2, 2, 2, 2, 0

; image bi of the key: per byte (near & Mn) | (~Mn & ((mid & Mm) | (~Mm & far))). T4 at MPR3, the block at MPR4, shift tables at MPR6.
egen:	lda bi                  ; offsets: 8 images by dm (dn = 2 dm), 4 by dn
	ldx bn
	cpx #8
	bne .e4
	sta gdm
	asl a
	and #6
	sta gdn
	bra .o
.e4:	asl a
	sta gdn
	lsr a                   ; (near over mid: dm = parity * 4 + image; near over far: no mid, dm unused)
	ldx bpar
	beq .e5
	ora #4
.e5:	sta gdm
.o:	lda #SHBANK
	tam #6
	lda #T4
	clc
	adc bT
	tam #3
	lda bbk
	tam #4
	lda gdn                 ; shift tables
	asl a
	clc
	adc #>SHT
	sta g_nal+2
	sta .ml+2
	inc a
	sta g_nbr+2
	sta .mr+2
	lda gdm
	asl a
	clc
	adc #>SHT
	sta g_mal+2
	sta .nl+2
	inc a
	sta g_mbr+2
	sta .nr+2
	; masks
	cla
	ldx bna
	cpx #$FF
	beq .n1
	ldx #$FF
.ml:	lda SHT,x
.n1:	sta t0
	cla
	ldx bnb
	cpx #$FF
	beq .n2
	ldx #$FF
.mr:	lda SHT + 256,x
.n2:	ora t0
	sta gmn
	eor #$FF
	sta g_nn+1
	cla
	ldx bma
	beq .m1
	ldx #$FF
.nl:	lda SHT,x
.m1:	sta t0
	cla
	ldx bmb
	beq .m2
	ldx #$FF
.nr:	lda SHT + 256,x
.m2:	ora t0
	sta g_mm+1
	eor #$FF
	sta g_nm+1
	lda gmn
	sta g_mn+1
	lda bi                  ; sources: once a key
	bne .ds
	lda bidx
	jsr gptr
	lda t0
	sta g_na+1
	lda t1
	sta g_na+2
	lda bidx+1
	jsr gptr
	lda t0
	sta g_nb+1
	lda t1
	sta g_nb+2
	lda bidx+2
	jsr gptr
	lda t0
	sta g_ma+1
	lda t1
	sta g_ma+2
	lda bidx+3
	jsr gptr
	lda t0
	sta g_mb+1
	lda t1
	sta g_mb+2
	lda bidx+4
	jsr gptr
	lda t0
	sta g_f+1
	sta h_f+1
	lda t1
	sta g_f+2
	sta h_f+2
.ds:	lda bi
	stz t1
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t1
	clc
	adc bal
	sta g_d+1
	lda t1
	adc bah
	sec
	sbc #$40
	sta g_d+2
	lda bna                 ; no near tile (a mid edge over the far: 8 of 10 images in the quarry): one mid tile, the short loop
	and bnb
	cmp #$FF
	bne eg_gl
	lda g_d+1
	sta h_d+1
	lda g_d+2
	sta h_d+2
	lda g_mm+1
	sta h_mm+1
	lda g_nm+1
	sta h_nm+1
	lda bma
	beq .hb
	lda g_mal+2             ; (tile A: its left shift; B: its right shift)
	ldx g_ma+1
	ldy g_ma+2
	bra .hs
.hb:	lda g_mbr+2
	ldx g_mb+1
	ldy g_mb+2
.hs:	sta h_ms+2
	stx h_m+1
	sty h_m+2
	ldy #31
h_l:
h_m:	ldx $6000,y
h_ms:	lda SHT,x
h_mm:	and #$FF
	sta t3
h_f:	lda $6000,y
h_nm:	and #$FF
	ora t3
h_d:	sta $8000,y
	dey
	bpl h_l
	bra eg_dn
eg_gl:	ldy #31
g_l:
g_na:	ldx $6000,y
g_nal:	lda SHT,x
g_nb:	ldx $6000,y
g_nbr:	ora SHT + 256,x
g_mn:	and #$FF
	sta t2
g_ma:	ldx $6000,y
g_mal:	lda SHT,x
g_mb:	ldx $6000,y
g_mbr:	ora SHT + 256,x
g_mm:	and #$FF
	sta t3
g_f:	lda $6000,y
g_nm:	and #$FF
	ora t3
g_nn:	and #$FF
	ora t2
g_d:	sta $8000,y
	dey
	bpl g_l
eg_dn:	inc bi
	lda bi
	cmp bn
	bcc .x
	lda #T3                 ; all made
	tam #3
	lda bp
	sta ep
	lda bl
	sta el
	lda #EP_FREE
	ldx #FPO
	jsr efput
	stz bst
	inc nbuilt
	bne .x
	inc nbuilt+1
.x:	lda #1
	rts
gdn:	.db 0
gdm:	.db 0
gmn:	.db 0
gptr:	stz t1
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	asl a
	rol t1
	sta t0
	lda t1
	clc
	adc #$60
	sta t1
	rts

escan:	lda sw
	bpl .f2                 ; (a window under way)
	lda #6                  ; wpick5
	ldx #C5BANK
	jsr callx
	bcc .nw
	lda #1                  ; (every window near the camera scanned)
	sta sdone
	rts
.nw:	sta sw
	stz sr
.f2:	ldx sr                  ; (a row with no edge slot anywhere: nothing to look up)
	lda erow,x
	bne .f3
	jmp e_nr
.f3:	lda ssb6
	tam #6
	lda #1
	sta eprobe
	lda sw
	and #1
	sta ekp
	lda sw
	sta e_n+1
	sta e_nm+1
	sta ek_n+1
	inc a
	sta ek_n2+1
	lda sr
	clc
	adc #>NSLOT
	sta e_n+2
	lda sr
	clc
	adc #$C0
	sta e_nm+2
	sta ek_n+2
	sta ek_n2+2
	lda sw
	lsr a
	sta t1
	sta ek_m+1
	inc a
	sta ek_m2+1
	lda sr
	clc
	adc #$D0
	sta ek_m+2
	sta ek_m2+2
	lda sr                  ; mid slot row
	lsr a
	sta t0
	cla
	ror a
	clc
	adc t1
	sta e_m1+1
	lda t0
	adc #>MSLOT
	sta e_m1+2
	lda sr                  ; far words
	stz t0
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t0
	asl a
	rol t0
	sta ek_f+1
	lda t0
	clc
	adc #>FARL
	sta ek_f+2
	cly
e_c:	sty ey
e_n:	lda $6000,y
	cmp #EDGEB
	bcc e_x                 ; a near pair
	cmp #NOSLOT
	beq e_m
	cmp #EDGEA
	bne e_b
e_nm:	lda $C000,y
	and #$7F
	sta ena
	lda #$FF
	sta enb
	bra e_u
e_b:	lda #$FF
	sta ena
	jsr ek_n2
	bra e_u
e_m:
e_m1:	lda $7000,y
	.if MEDGE
	cmp #EDGEB
	bcc e_x
	cmp #NOSLOT
	beq e_x
	lda #$FF
	sta ena
	sta enb
	.else
	bra e_x
	.endif
e_u:	jsr ek_under
	jsr efind
	ldy ey
e_x:	iny
	cpy #32                 ; (column 32: under the border, no key)
	bne e_c
	stz eprobe
e_nr:	inc sr
	lda sr
	cmp #16
	bne e_y
	ldx sw                  ; the window scanned: its ticket
	lda nkeys
	sta wtk,x
	lda #1
	sta wsc,x
	lda #$FF
	sta sw
e_y:	rts

tok:	lda TIMER
	and #$7F
	bbr6 <SPLITS, .a
	sta hut
	lda FRAMES
	sta huf
	lda #0
	rts
.a:	sta tnw
	lda FRAMES
	sec
	sbc huf
	cmp #3
	bcs .nc
	lda hut
	jsr tel
	jsr tadd
	cmp #40
	lda #0
	bcc .x
	lda #2
.x:	rts
.nc:	lda #1
	rts
; A = (A - tnw) mod 116: the ticks since stamp A; carry clear
tel:	sec
	sbc tnw
	bcs .p
	adc #116
.p:	clc
	rts
; A + the coming step's ticks and margin: 13 for a source step (bst 1), else 7
tadd:	ldx bst
	beq .p                  ; (0: a pop, a scan row or a page of T3: under 4k cycles)
	dex
	bne .i
	ldx rnext               ; (1: a source: a recolour, 9.7k cycles, or a look-up)
	bne .s
	clc
	adc #2 + 2
	rts
.i:
	ldx bna                 ; (2: an image: the short loop under 2k, the full one under 4k)
	cpx #$FF
	bne .p
	ldx bnb
	cpx #$FF
	bne .p
	clc
	adc #2 + 2
	rts
.s:	clc
	adc #10 + 2
	rts
.p:	clc
	adc #4 + 2
	rts
hstep:	lda ss
	bne .n
	lda FRAMES
	sec
	sbc huf
	dec a
	cmp #2
	bcs .n
	lda tlp
	sta tnw
	lda hut
	jsr tel
	cmp #40
	bcc .n
	jsr tadd
	cmp #117
	bcs .n
	jsr kstep
.x:	rts
.n:	inc hsn
	rts
dsto:	lda FRAMES              ; carry set: DMAX frames gone
	sec
	sbc dst0
	cmp #DMAX
	rts
; (ssfill) the slot counts and the rows' first / last columns emptied
rbinit:	stz nk
	stz mk
	ldx #15
.rb:	lda #$FF
	sta rnf,x
	sta rmf,x
	stz rnl,x
	stz rml,x
	dex
	bpl .rb
	rts
; one edge-key step (T1 / T2 mapped; MPR3, 4 and 6 kept): hstep and the dark set-up
kstep:	tma #3
	pha
	tma #4
	pha
	tma #6
	pha
	lda #T1
	tam #3
	lda #T2
	tam #4
	lda #SSE
	sta ss
	jsr sstep
	stz ss
	pla
	tam #6
	pla
	tam #4
	pla
	tam #3
	rts

; ---------------------------------------------------------------- prebuilt rows
pdrop:
	.if PREB                ; (no prebuilt row images without them: nothing to drop)
	tma #4
	pha
	lda #T2
	tam #4
	ldx #1
.s:	lda pval,x
	beq .n
	stz pval,x
	lda #$FF
	jsr pins
.n:	dex
	bpl .s
	jsr pabandon
	pla
	tam #4
	rts
; a build under way: its pins go
pabandon:	lda pbusy
	beq .x
	stz pbusy
	ldx #1
.s:	lda pmask
	and pbit,x
	beq .n
	lda #$FF
	jsr pins
.n:	dex
	bpl .s
.x:	rts
pbit:	.db 1, 2
	.endif
	rts

; idle time: rows of the images wanted, until the vblank (sfr) or nothing is wanted
prework:
	.if PREB                ; (the prebuilt rows: tried, off; their code is left out of the bank)
	lda ldir
	bne .go
	rts
.go:	tma #3
	sta sv3
	tma #4
	sta sv4
	tma #6
	sta sv6
	lda #T1
	tam #3
	lda #T2
	tam #4
	lda set                 ; the pass's values, back at the end; the cell loop in image mode: set 0's words, the image list
	sta svset
	lda cn
	sta svcn
	lda cm
	sta svcm
	lda ekp
	sta svekp
	lda lc
	sta svlc
	lda pass
	sta svpass
	clc
	adc #64
	sta pass
	lda #1
	sta pre
	jsr stmode
	cla
	jsr settab
	lda prelst
	sta c_lst+2
	lda #PROWS
	sta prows
.loop:	lda FRAMES
	cmp sfr
	bne .out
	lda svcn                ; (pwant reads the pass's columns and set)
	sta cn
	lda svset
	sta set
	jsr pwant               ; A = column wanted, t3 = the sets wanting it; carry set: nothing (a build under way goes on as
	bcs .out                ; started: a restart on every change of what is wanted would never finish one)
	ldy pbusy
	bne .row
.start:	sta ptcn
	lda t3
	sta pmask
	stz prow
	stz plcs
	stz plcs+1
	lda #1
	sta pbusy
.row:	jsr prerow
	dec prows
	beq .out                ; (rows per idle time: the edge keys want their share)
	lda prow
	cmp #16
	bne .loop
	ldx #1                  ; the images are complete
.f:	lda pmask
	and pbit,x
	beq .fn
	lda ptcn
	sta pcn,x
	lsr a
	sta pcm,x
	lda dgen,x
	sta pgen,x
	lda #1
	sta pval,x
.fn:	dex
	bpl .f
	stz pbusy
	bra .loop
.out:	lda svpass
	sta pass
	stz pre
	jsr stmode
	lda svlc
	sta lc
	lda svekp
	sta ekp
	lda svcm
	sta cm
	lda svcn
	sta cn
	lda svset
	sta set
	jsr settab
	lda sv3
	tam #3
	lda sv4
	tam #4
	lda sv6
	tam #6
	rts

; what to build next: per set (the one drawn after this pass first) the current column if its buffer is not at it, else the next;
; the first set without a valid image for its column decides the column, t3 = the sets wanting that column without an image.
; Images of another column or generation are dropped. Carry set: nothing wanted (the build under way is returned as is).
pwant:	lda pbusy
	beq .scan
	lda pmask
	sta t3
	lda ptcn
	clc
	rts
.scan:	stz t3
	lda #$FF
	sta t2
	lda set
	eor #1
	tax
	jsr .one
	ldx set
	jsr .one
	lda t2
	cmp #$FF
	beq .none
	clc
	rts
.none:	sec
	rts
.one:	lda dvalid,x            ; the buffer not at the current column: that one
	beq .cur
	lda dcn,x
	cmp cn
	bne .cur
	lda cn                  ; else the next
	clc
	adc ldir
	bra .chk
.cur:	lda cn
.chk:	sta t0
	lda pval,x              ; have it?
	beq .need
	lda pgen,x
	cmp dgen,x
	bne .stale
	lda pcn,x
	cmp t0
	beq .have
.stale:	stz pval,x              ; (an image of another column or generation: dropped)
	lda #$FF
	jsr pins
.need:	lda t2
	cmp #$FF
	bne .same
	lda t0
	sta t2
.same:	lda t0
	cmp t2
	bne .have
	lda t3
	ora pbit,x
	sta t3
.have:	rts

; one row of the images: the cell loop (set 0's tables, image mode) into LBL / LBH, then into the image rows (SHBANK at MPR6)
prerow:	stz set
	lda ptcn
	sta cn
	sta npl
	and #1
	sta ekp
	lda ptcn
	lsr a
	sta cm
	sta mpl
	lda prow
	sta row
	clc
	adc #$C0
	sta nph
	lda prow
	clc
	adc #$D0
	sta mph
	lda plcs
	sta lc
	jsr rowops
	jsr pbounds
	bcc .go
	jmp .none
.go:	lda ssb6                ; the maps
	tam #6
	jsr cells
	lda prelst+1            ; the tiles this row listed: pinned now (a later row's allocation must not take them), listed for set 1 too
	sta .p1+2
	lda pmask
	cmp #3
	bne .m1
	lda #2
.m1:	sta t2                  ; (the images referring to the tile: 1 or 2)
	ldy plcs
.pl:	cpy lc
	beq .pd
.pn:	ldx PL0,y
	txa
.p1:	sta PL1,y
	lda PIN,x
	clc
	adc t2
	sta PIN,x
	iny
	bra .pl
.pd:	lda #SHBANK             ; the words into the image rows: set 0 as they are, set 1 with its pool words
	tam #6
	lda prow
	lsr a
	sta t1
	cla
	ror a
	sta t0
	lda ua
	asl a
	clc
	adc t0
	sta t0
	bcc .nc
	inc t1
.nc:	lda t1
	clc
	adc #>IMG
	sta t1
	lda pmask
	lsr a
	bcc .s1
	lda t0
	sta .w0+1
	sta .w1+1
	lda t1
	sta .w0+2
	sta .w1+2
	ldy ua
	clx
.c0:	lda LBL,y
.w0:	sta IMG,x
	inx
	lda LBH,y
.w1:	sta IMG,x
	inx
	iny
	cpy ub
	bne .c0
.s1:	lda pmask
	and #2
	bne .g1
	jmp .none
.g1:	lda t0
	sta .w2+1
	sta .w3+1
	lda t1
	clc
	adc #8
	sta .w2+2
	sta .w3+2
	ldy ua
	clx
.c1:	lda LBH,y
	sta t2
	and #7
	cmp #7                  ; a set-0 pool tile ($772-$7FF): set 1's tile for the same pool index
	bne .as
	lda LBL,y
	cmp #$72
	bcc .as
	sec
	sbc #$72
	sta t3
	phy
	ldy t3
	lda WL1,y
	jsr .st2
	lda WH1,y
	and #$0F
	sta t3
	lda t2
	and #$F0
	ora t3
	ply
	bra .wr
.as:	lda LBL,y
	jsr .st2
	lda LBH,y
.wr:
.w3:	sta IMG,x
	inx
	iny
	cpy ub
	bne .c1
.none:	lda lc
	sta plcs
	sta plcs+1
	inc prow
	rts
.st2:
.w2:	sta IMG,x
	inx
	rts

; the cell loop's word stores: to the VDC (pre = 0) or to LBL / LBH,y (pre = 1)
stmode:	ldx #7
.s:	lda stlo,x
	sta .w+1
	lda sthi,x
	sta .w+2
	lda pre
	beq .vdc
	lda #$99                ; STA abs,Y
	ldy #0
	jsr .w
	txa
	and #1
	bne .h
	lda #<LBL
	ldy #1
	jsr .w
	lda #>LBL
	bra .p
.h:	lda #<LBH
	ldy #1
	jsr .w
	lda #>LBH
.p:	ldy #2
	jsr .w
	bra .n
.vdc:	lda #$8D                ; STA abs
	ldy #0
	jsr .w
	txa
	and #1
	ora #2
	ldy #1
	jsr .w
	cla
	ldy #2
	jsr .w
.n:	dex
	bpl .s
	rts
.w:	sta $FFFF,y
	rts
stlo:	.db <s_nl, <s_nh, <s_wl, <s_wh, <s_ml, <s_mh, <s_fl, <s_fh
sthi:	.db >s_nl, >s_nh, >s_wl, >s_wh, >s_ml, >s_mh, >s_fl, >s_fh
	.endif
	rts

; ---------------------------------------------------------------- the band path's setup pieces (bank 0: called from the band code)
; the groups: none in use, all free, nothing queued (BANDT at MPR4; the code is in the second code sector: ginit2)
ginit:	lda #26
	jmp call2

ftcopy:	lda #BANDF
	tam #3
	lda flo                 ; the base tile * 16 = VRAM address
	and #$F0
	sta t0
	lda fhi
	and #$0F
	asl a
	asl a
	asl a
	asl a
	sta t1
	lda flo
	lsr a
	lsr a
	lsr a
	lsr a
	ora t1
	sta t1                  ; address high = tile >> 4 ... (tile * 16: low = (tile & 15) << 4 = 0, high = tile >> 4)
	stz t0
	lda #<$6000
	sta ft_d+1
	sta ft_d2+1
	lda #>$6000
	sta ft_d+2
	sta ft_d2+2
	lda #184
	sta t2
ft_t:	lda FRAMES
	sta uf
	vsel 1
	lda t0
	sta $0002
	lda t1
	sta $0003
	vsel 2
	clx
ft_w:	lda $0002
ft_d:	sta $6000,x
	inx
	lda $0003
ft_d2:	sta $6000,x
	inx
	cpx #32
	bne ft_w
	lda FRAMES
	cmp uf
	bne ft_t
	lda t0                  ; the next tile
	clc
	adc #16
	sta t0
	bcc *+5
	inc t1
	lda ft_d+1
	clc
	adc #32
	sta ft_d+1
	sta ft_d2+1
	bcc *+8
	inc ft_d+2
	inc ft_d2+2
	dec t2
	bne ft_t
	rts

bpal:	lda #>nmap0
	sta bp_m+2
	sta bp_m0+2
	lda #64
	ldx #PALF
	ldy #<nmap0
	jsr bpal1
	lda #32
	ldx #PALM
	ldy #<nmap1
bpal1:	stx t1
	sta bp_s+1
	sty bp_m+1
	lda t1
	asl a
	asl a
	asl a
	asl a
	asl a
	sta bp_d+1
	sta bp_c1+1
	sta bp_c2+1
	sta bp_w1+1
	sta bp_w2+1
	sta bp_v1+1
	sta bp_v2+1
	inc bp_c2+1
	inc bp_w2+1
	inc bp_v2+1
	cly
bp_c:
bp_s:	lda $3C00,y
bp_d:	sta $3C00,y
	iny
	cpy #32
	bne bp_c
	lda #9
	sta t2                  ; the next free entry
	ldy #1
bp_n:	tya
	asl a
	tax
	lda $3C00,x             ; near colour i
	sta t3
	lda $3C01,x
	sta srca
	ldx #2
bp_f:	lda t3
bp_c1:	cmp $3C00,x
	bne bp_f2
	lda srca
bp_c2:	cmp $3C01,x
	bne bp_f2
	txa
	lsr a
	bra bp_set
bp_f2:	inx
	inx
	cpx #18
	bne bp_f
	lda t2
	cmp #16
	bcc bp_fr
	lda #15
	bra bp_set
bp_fr:	inc t2
	pha
	asl a
	tax
	lda t3
bp_w1:	sta $3C00,x
	lda srca
bp_w2:	sta $3C01,x
	pla
bp_set:
bp_m:	sta nmap0,y
	iny
	cpy #16
	bne bp_n
	lda bp_m+1              ; nmap[0] = 0
	sta bp_m0+1
bp_m0:	stz nmap0
	lda t1                  ; into the VCE
	asl a
	asl a
	asl a
	asl a
	sta t2
	cly
bp_v:	php
	sei
	tya
	lsr a
	ora t2
	sta $0402
	stz $0403
bp_v1:	lda $3C00,y
	sta $0404
bp_v2:	lda $3C01,y
	sta $0405
	plp
	iny
	iny
	cpy #32
	bne bp_v
	rts

; ---------------------------------------------------------------- the second code bank
; Setup-only code lives in the top sector of bank CBANK (loaded there by disc_boot's loadmod), mapped at MPR6 while it runs: the
; module's 8 KB are full. Nothing in it needs MPR6 (the maps, the shift tables) itself.
C2SEC      = 439        ; (src/modules.json chunk: after C3SEC, so that the code areas are one read of six sectors, modent)
CBANK      = $79        ; (T4's first bank: its recoloured tiles stop at 128; its top 4 KB is code, $D000-$DFFF at MPR6)
C2ORG      = $D800
C3SEC      = 438        ; (src/modules.json chunk2; C7b's sector proof) the second bank's lower 2 KB, read by modinit once after the first
C3ORG      = $D000
C4SEC      = 440        ; (src/modules.json chunk3) the band path: two sectors into SHBANK's $D000-$DFFF, read by modent once per power-on
C4ORG      = $D000
C5SEC      = 442        ; (src/modules.json chunk4) the fourth code area: two sectors into the stub bank's spare $1000-$1FFF (C5BANK at
C5BANK     = $7D        ; MPR6, $D000-$DFFF while it runs: callx), read by c5load once per power-on with the third. No module's data reach
C5ORG      = $D000      ; SBANK (src/modules.json), so it stays; its $0800-$0FFF hold the copy of two of the mid runs (vxall)
MSAVE      = $DF00      ; (top of the second code sector's 2 KB, which bclr keeps) kept copies of the merged palettes: 32 bytes each, page-aligned
modinit2:	lda #0
	bra call2
ss_far2:	lda #2
	bra call2
pooltab2:	lda #4
	bra call2
mwrite2:	lda #8
call2:	tax
	lda c2tab,x
	sta call_j+1
	lda c2tab+1,x
	sta call_j+2
	tma #6
	pha
	lda #CBANK
	tam #6
	bra call_j

; the band path's routines (the third code area, SHBANK's top half): A = offset into bandjt (0, 3, 6 ...), MPR6 saved and put back
callb:	ldx #SHBANK
callx:	sta call_j+1
	lda #>bandjt
	sta call_j+2
	tma #6
	pha
	txa
	tam #6
call_j:	jsr $FFFF
	tax
	pla
	tam #6
	txa
	rts
c2tab:	.dw modinit, ss_far, pooltab, einit, mwrite, leave, bclr, bchk, ss_end2, basechk, qho, qidle, prewarm_mixes, ginit2, bi_cam
	.dw w3rdy2, ereset, bgrun

	.bank 1
	.org C3ORG
c3var:
nlay:	.db 0           ; layout changes seen (the operands' bases differed from the set-up ones: setup again)
nfail:	.db 0           ; set-ups refused (a layer's words would reach the pools, or the allocator at $68 or above)

basechk:	lda setok
	ora ss
	beq .gate
	lda OP_NEARLO
	cmp nlo
	bne .chg
	lda OP_NEARH0
	clc
	adc OP_NEARHI
	cmp nhi
	bne .chg
	lda OP_MIDLO
	cmp mlo
	bne .chg
	lda OP_MIDHI
	clc
	adc #$10
	cmp mhi
	bne .chg
	clc
	rts
.chg:	inc nlay
	sec
	rts
.gate:	lda OP_NEARLO
	sta t0
	lda OP_NEARH0
	clc
	adc OP_NEARHI
	jsr .bt
	bcs .no
	lda OP_MIDLO
	sta t0
	lda OP_MIDHI
	jsr .bt
	bcs .no
	lda OP_FARLO
	sta t0
	lda OP_FARHI
	jsr .bt
	bcs .no
	ldx #47
.a:	lda $40B3,x
	cmp #$68
	bcs .no
	dex
	bpl .a
	clc
	rts
.no:	inc nfail
	sec
	rts
.bt:	and #7                  ; base tile (hi bits 10-8, t0 the low byte) + 255 below $680: base below $581
	cmp #5
	bcc .ok
	bne .bad
	lda t0
	cmp #$81
	rts
.ok:	clc
	rts
.bad:	sec
	rts
svd:	.db 0           ; set 1 copied (this visit)
wz:	.db 0           ; a set-up again after the copy (ss_clr may have zeroed set 1): the restore is due even with dirty 0
cpi:	.db 0           ; tiles copied
rs:	.db 0           ; restore: 0 none, 1 zero set 0, 2 set 1 back, 3 done
rpi:	.db 0           ; restore cursor
rdone:	.db 0
hp:	.db 0
hpp:	.db 0
c3m4:	.db 0
cti:	.db 0
cnt3:	.db 0
rfr:	.db 0
val:	.db 0           ; a tile's VRAM word address, its copy's address
vah:	.db 0
cal:	.db 0
cah:	.db 0
SV1N       = 242        ; tiles of the copy: set 1 ($680-$70D) and $70E-$771
RTN        = 16         ; tiles put back per idle (about 300 cycles each: about 5k)

c3rst:	stz svd
	stz wz
	stz cpi
	stz rs
	stz rpi
	stz rdone
	stz hp
	rts

c1adr:	sta cti
	asl a
	asl a
	asl a
	asl a
	sta val
	lda cti
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #$68
	sta vah
	lda cti
	asl a
	asl a
	asl a
	asl a
	asl a
	sta cal
	lda cti
	lsr a
	lsr a
	lsr a
	clc
	adc #$80
	sta cah
	rts

; ss_far's first steps: 8 tiles of set 1 into the copy a step; carry set when the copy is complete (or was)
capt:	lda svd
	beq .go
	sta wz
	sec
	rts
.go:	tma #4
	sta c3m4
	lda #$7F
	tam #4
	lda #8
	sta cnt3
.l:	lda cpi
	jsr c1adr
	php
	sei
	vsel 1                  ; MARR = the tile
	lda val
	sta $0002
	lda vah
	sta $0003
	vsel 2
	lda cal
	sta .t+3
	lda cah
	sta .t+4
.t:	tai $0002, $8000, 32
	plp
	inc cpi
	lda cpi
	cmp #SV1N
	beq .d
	dec cnt3
	bne .l
	lda c3m4
	tam #4
	clc
	rts
.d:	lda #1
	sta svd
	lda c3m4
	tam #4
	sec
	rts

; one tile of the restore (MPR4 = $7F)
rtile:	lda rs
	cmp #1
	bne .s1
	lda rpi
	lsr a
	lsr a
	lsr a
	lsr a
	sta vah
	lda rpi
	and #$0F
	asl a
	asl a
	asl a
	asl a
	clc
	adc #$20
	sta val
	lda vah                 ; (the low byte's carry)
	adc #$77
	sta vah
	php
	sei
	vsel 0
	lda val
	sta $0002
	lda vah
	sta $0003
	vsel 2
	ldx #16
.z:	st1 #0
	st2 #0
	dex
	bne .z
	plp
	bra .nx
.s1:	lda rpi                 ; set 1: the copy back
	jsr c1adr
	php
	sei
	vsel 0
	lda val
	sta $0002
	lda vah
	sta $0003
	vsel 2
	lda cal
	sta .t+1
	lda cah
	sta .t+2
.t:	tia $8000, $0002, 32
	plp
.nx:	inc rpi
	lda rpi
	cmp #142
	bne .x
	stz rpi
	inc rs
.x:	rts

qho:	lda vxok                ; (the band's borrowed run copied: put back too)
	bne .r
	lda svd
	beq .ho
	lda dirty
	ora wz
	beq .ho
.r:	lda <VDCREG
	pha
.rv:	jsr vxrest              ; (to the end: the mid groups come back MRSTEP a call)
	lda vxok
	bne .rv
	lda dirty
	ora wz
	beq .r2
	jsr rall
	stz dirty
.r2:	vsel 0
	lda OP_MAWRLO
	sta $0002
	lda OP_MAWRHI
	sta $0003
	pla
	sta <VDCREG
	sta $0000
.ho:	lda #HFROM
	sta STUB_PREV
	lda #HTO
	jmp qho_fin
	nop

qidle:	lda SCENE
	cmp #17
	beq .i7
.n0:	clc
	rts
.i7:	lda wsd                 ; (a window opened over the band this pass: its borrowed runs back first, wsdo)
	beq .is17
	lda #27
	jmp callb
.is17:	lda act
	beq .sd
	stz rs                  ; (taken back: the module writes the pools again)
	jmp idcx
.sd:	lda setok
	beq .n0
.sd_ready:
	lda bsok                ; (the band's images and set-up first: the background, from the open quarry's side)
	beq .q_chk_bridge
	lda bgss
	beq .bp
qi_bg      = * - 1          ; (quarry-seams: 0 with the seams' image in, sinit: walking left the band's prewarm never starts, whatever
                            ; bgss is; it undid the bridge's claim every pass from 624 down to 512 once the background was over)
	lda pw_state
	cmp #2
	bcs .bp
	lda ldir
	bmi .q_chk_bridge
.bp:
qi_bp      = *              ; (quarry-seams-2: JMP idcx likewise: the let-go's pass leaves ldir 0; quarry-load-after-handover: through qj_bp)
	lda CAMX+1
	bmi .q_chk_bridge
	cmp #2
	bcc .q_chk_bridge
	jsr band_idle_prewarm
	.if PROF
	lda $0C00
	sta tpi
	.endif
	sec
	rts
.q_chk_bridge:
qi_cb      = *              ; (quarry-seams-2: JMP idcx on a pass going left at 624 .. 608, srp: the idle is the seams' image's, sfil; through qj_cb)
	stz pw_state
	lda svd
	beq .no
	lda dirty
	ora wz
	beq .no
	lda CAMX                ; camera >= THAND + 8
	cmp #<(THAND + 8)
	lda CAMX+1
	sbc #>(THAND + 8)
	bmi .no
	lda CAMX
	and #15
	cmp #14
	beq .no
	cmp #2
	beq .no
	and #7
	beq .no
	tma #4
	sta c3m4
	lda #$7F
	tam #4
	lda rs
	bne .go
	lda #1
	sta rs
	stz rpi
.go:	lda #RTN
	sta cnt3
.l:	jsr rtile
	lda rs
	cmp #3
	beq .dn
	dec cnt3
	bne .l
.o:	lda c3m4
	tam #4
	sec
	rts
.dn:	stz rs
	stz dirty
	stz wz
	bra .o
.no:	clc
	rts

; leave (an area exit): set 0 zero, set 1 back, to completion
rall:	lda svd
	beq .x
	tma #4
	sta c3m4
	lda #$7F
	tam #4
	lda #1
	sta rs
	stz rpi
.l:	jsr rtile
	lda rs
	cmp #3
	bne .l
	lda c3m4
	tam #4
.x:	jmp c3rst

; setup pre-init (called from ss_end2): FW, PROP2, bpal, ftcopy, pre-generate all near-end parts in band 1
band_setup:	tma #3
	pha
	tma #4
	pha
	lda bsr                 ; (the background's pieces, bgm: bsr 0 the tables, 1-16 a row of the scan each)
	beq .p0
	lda #BANDT
	tam #4
	lda ssb6
	tam #3
	jmp bs_rlp
.p0:	lda #T2
	tam #3
	lda #BANDT
	tam #4
	tii prop - $2000, PROP2, 128   ; (indexed by code & $7F; the upper half is GQ)
	lda #T1
	tam #3
	cla
	sta bs_d+1
	sta bs_d2+1
	sta bs_l+1
	sta bs_h+1
	sta t0                  ; r
	lda #>FW
	sta bs_d+2
	sta bs_d2+2
	lda #>FARL
	sta bs_l+2
	clc
	adc #4
	sta bs_h+2
bs_r:	cly
	clx
bs_l:	lda FARL,y
bs_d:	sta FW,x
	inx
bs_h:	lda FARH,y
bs_d2:	sta FW,x
	inx
	iny
	cpy #33
	bne bs_l
	lda bs_l+1
	clc
	adc #64
	sta bs_l+1
	sta bs_h+1
	bcc .nl
	inc bs_l+2
	inc bs_h+2
.nl:	lda bs_d+1
	clc
	adc #66
	sta bs_d+1
	sta bs_d2+1
	bcc .nd
	inc bs_d+2
	inc bs_d2+2
.nd:	inc t0
	lda t0
	cmp #16
	bne bs_r
	jsr bpal
	jsr ftcopy
	lda #BANDT
	tam #4
	clx
	lda #$FF
bs_ne:	sta NEIDX,x
	inx
	bpl bs_ne
	stz nne
	lda ssb6
	tam #3
	stz bs_row
	lda bgm
	bne bs_pc
bs_rlp:	lda bs_row
	clc
	adc #$60
	sta bs_ma+2
	sta bs_mb+2
	lda #80
	sta bs_col
bs_clp:	ldy bs_col
bs_ma:	lda $6000,y
	and #$7F
	tax
	iny
bs_mb:	lda $6000,y
	and #$7F
	tay
	lda PROP2,x
	bpl .a_nr
	lda PROP2,y
	bmi bs_next
	tya
	jsr bs_chk_ng
	bra bs_next
.a_nr:	lda PROP2,y
	bpl bs_next
	txa
	jsr bs_chk_ng
bs_next:
	inc bs_col
	lda bs_col
	cmp #129
	bne bs_clp
	inc bs_row
	lda bs_row
	cmp #16
	beq bs_rd
	lda bgm
	beq bs_rlp
bs_pc:	inc bsr                 ; (a piece done: more to come)
	bra bs_ex
bs_rd:	stz bsr

	lda dkin                ; (camera 624 on, in the dark set-up only (ss_end2): elsewhere the idle's prewarm, a column a frame)
	beq .bs_done
	jsr prewarm_mixes
	.if 0
	jsr spwait
	.endif
	lda #0                  ; band_init
	jsr callb
	lda #3                  ; (its groups' tiles go up in the idle, band_idle_prewarm's state 3; the band takes over after: the
	sta pw_state
	bra bs_ex
.bs_done:
	stz pw_state
bs_ex:
	pla
	tam #4
	pla
	tam #3
	rts

bs_chk_ng:
	tax
	lda NEIDX,x
	cmp #$FF
	bne bs_skp
	stx t2
	lda #12
	jsr callb
	lda ssb6
	tam #3
bs_skp:	rts
bs_row:	.db 0
bs_col:	.db 0
bsr:	.db 0

prewarm_mixes:
	jsr pw_init
pwsite1:	jsr pw_one_col
	dec pw_c
	lda pw_c
	cmp #79
	bne pwsite1
	rts

pw_init:
	inc erq                 ; (the edge store: the mixes take T3 and its banks; emptied in the next key step, ss_e)
	tma #3
	pha
	lda #T3
	tam #3
	lda #18
	jsr callb
	stz nfmix
	stz nfmix0
	stz nfmix1
	jsr init_t3_tab
	pla
	tam #3
	lda #127
	sta pw_c
	rts

spwait:	lda FRAMES
	inc a
	inc a
	sta uf
.w0:	lda FRAMES
	cmp uf
	beq .x
	bbs6 <SPLITS, .w0
.w1:	lda FRAMES
	cmp uf
	beq .x
	bbr6 <SPLITS, .w1
.x:	rts

pw_one_col:
	tma #3
	pha
	tma #4
	pha
	stz pw_r
.pw_rlp:
	lda ssb6
	tam #3
	lda #BANDT
	tam #4
	lda pw_r
	clc
	adc #$60
	sta .pw_ma+2
	sta .pw_mb+2
	ldy pw_c
.pw_ma:	lda $6000,y             ; A = map[r, c]
	and #$7F
	tax
	iny
.pw_mb:	lda $6000,y             ; B = map[r, c+1]
	and #$7F
	tay
	lda PROP2,x
	bpl .a_nr
	; A is non-near: check if B is near (side 1: B only)
	lda PROP2,y
	bmi .pw_rnext
	; B is near, A is non-near -> side 1, tile is B (in Y)
	tya
	ldx #1
	jsr pw_one_end
	bra .pw_rnext
.a_nr:
	; A is near: check if B is non-near (side 0: A only)
	lda PROP2,y
	bpl .pw_rnext
	; A is near, B is non-near -> side 0, tile is A (in X)
	txa
	ldx #0
	jsr pw_one_end
.pw_rnext:
	inc pw_r
	lda pw_r
	cmp #16                 ; all 16 rows!
	bne .pw_rlp
	pla
	tam #4
	pla
	tam #3
	rts

band_idle_prewarm:
	lda pw_state
	beq bist0
	dec a
	beq bist1
	dec a
	beq bist2
	dec a
	beq bist3
	jmp idcx

bist0:
	jsr pw_init
	inc pw_state
	rts

bist1:
	jsr vxrest
pwsite2:	jsr pw_one_col
	dec pw_c
	lda pw_c
	cmp #79
	bne bist1_x
bist1dn:	lda #2
	sta pw_state
bist1_x:
	rts

bist2:
	lda CAMX+1
	bmi bist2_x
	cmp #2
	bcc bist2_x
	bne bist2_ge
	lda CAMX
	cmp #<624
	bcc bist2_x
bist2_ge:
	cla                     ; band_init
	jsr callb
	lda #3
	sta pw_state
bist2_x:
	rts

bist3:
	lda gqh
	cmp gqt
	beq bist3_rdy
	lda #15                 ; band_upl
	jsr callb
	lda gqh
	cmp gqt
	bne bist3_x
bist3_rdy:
	inc pw_state
	jmp idcx
bist3_x:
	rts

init_t3_tab:
	stz t0
	lda #$60
	sta t1
	clx
.bi_tab_lp:
	lda t0
	sta T3_LO,x
	lda t1
	sta T3_HI,x
	lda t0
	clc
	adc #192
	sta t0
	lda t1
	adc #0
	sta t1
	inx
	cpx #34
	bne .bi_tab_lp
	rts


pw_one_end:
	stx pw_side
	tax                     ; X = tile code
	lda NEIDX,x
	cmp #$FF
	bne .pw_e_ok
	rts
.pw_e_ok:
	sta pw_e
	asl a
	ora pw_side
	sta pw_es

	lda pw_c
	sec
	sbc #80
	bpl .pw_c_ge80
	rts                     ; if pw_c < 80, jmax < 0: never on screen in Band 1!
.pw_c_ge80:
	cmp #33
	bcc .pw_jmax_ok
	lda #32
.pw_jmax_ok:
	sta pw_jmax

	lda pw_c
	sec
	sbc #95
	bcs .pw_jmin_pos
	cla
.pw_jmin_pos:
	sta pw_jmin
	cmp pw_jmax
	beq .pw_j_range_ok
	bcc .pw_j_range_ok
	rts
.pw_j_range_ok:
	lda pw_jmin
	sta pw_j
	lda pw_jmax
	sta pw_jend

.pw_jlp:
	lda pw_j
	asl a
	ldy pw_r
	clc
	adc FWROWL,y
	sta .pw_fw+1
	lda FWROWH,y
	adc #0
	sta .pw_fw+2
	lda #BANDT
	tam #4
.pw_fw:	lda $8B00
	sec
	sbc flo
	sta pw_f

	lda #T3
	tam #3
	ldx pw_es
	lda T3_LO,x
	clc
	adc pw_f
	sta .pw_rd+1
	sta .pw_wr+1
	lda T3_HI,x
	adc #0
	sta .pw_rd+2
	sta .pw_wr+2
.pw_rd:	lda $6000
	cmp #$FF
	bne .pw_jnext

	lda pw_es
	cmp #9
	bcs .pw_slot_b1
	lda nfmix0
	cmp #254
	bcs .pw_full
	sta pw_slot
	inc nfmix0
	bra .pw_wr_go
.pw_slot_b1:
	lda nfmix1
	cmp #254
	bcs .pw_full
	sta pw_slot
	inc nfmix1
.pw_wr_go:
	lda pw_slot
.pw_wr:	sta $6000

	jsr do_compose_3phases

.pw_jnext:
	inc pw_j
	lda pw_j
	cmp pw_jend
	beq .pw_j_in
	bcc .pw_j_in
	rts
.pw_j_in:
	jmp .pw_jlp
.pw_full:
	rts

do_compose_3phases:
	tma #3
	pha
	tma #4
	pha
	lda pw_slot
	asl a
	asl a
	asl a
	asl a
	asl a
	sta pw_dlo
	lda pw_slot
	lsr a
	lsr a
	lsr a
	clc
	adc #$80
	sta pw_dhi

	lda pw_f
	asl a
	asl a
	asl a
	asl a
	asl a
	sta pw_flo
	lda pw_f
	lsr a
	lsr a
	lsr a
	clc
	adc #$60
	sta pw_fhi

	lda #BANDF              ; the far tile once into srca (the three phases mask it from there: no copy a phase)
	tam #3
	lda pw_flo
	sta .p_tii+1
	lda pw_fhi
	sta .p_tii+2
.p_tii:
	tii $6000, srca, 32
	lda #1
	sta pw_pn
.pn_l:
	ldx pw_pn
	lda pw_es
	cmp #9
	bcs .pn_b1
	lda PBNK2,x
	bra .pn_bok
.pn_b1:
	lda PBNK2_B,x
.pn_bok:
	tam #4

	lda #BANDN
	tam #3
	ldx pw_e
	lda NE384L2,x
	sta t2
	lda NE384H2,x
	sta t1
	lda pw_side
	beq .p_s0
	lda t2
	clc
	adc #192
	sta t2
	bcc .p_s0
	inc t1
.p_s0:
	lda pw_pn
	dec a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc t2
	sta .p_nora+1
	lda t1
	adc #$60
	sta .p_nora+2

	ldx pw_pn
	lda bm_mr2,x
	ldy pw_side
	beq .p_m0
	eor #$FF
.p_m0:	sta pb0

	lda pw_dlo
	sta .p_nsta+1
	lda pw_dhi
	sta .p_nsta+2

	ldy #31
.p_bloop:
	lda srca,y
	and pb0
.p_nora:
	ora $6000,y
.p_nsta:
	sta $8000,y
	dey
	bpl .p_bloop

	inc pw_pn
	lda pw_pn
	cmp #4
	beq .pn_done
	jmp .pn_l
.pn_done:
	pla
	tam #4
	pla
	tam #3
	rts

FWROWL:	.db $00, $42, $84, $C6, $08, $4A, $8C, $CE, $10, $52, $94, $D6, $18, $5A, $9C, $DE
FWROWH:	.db $8B, $8B, $8B, $8B, $8C, $8C, $8C, $8C, $8D, $8D, $8D, $8D, $8E, $8E, $8E, $8E
PBNK2:	.db 0, $73, $75, $76
PBNK2_B: .db 0, $7A, $7B, $7C
bm_mr2:	.db 0, $03, $0F, $3F
NE384L2: .db $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00
NE384H2: .db $00, $01, $03, $04, $06, $07, $09, $0A, $0C, $0D, $0F, $10, $12, $13, $15, $16, $18, $19, $1B, $1C, $1E
pw_r:	.db 0
pw_c:	.db 0
pw_side: .db 0
pw_e:	.db 0
pw_es:	.db 0
pw_j:	.db 0
pw_jmin: .db 0
pw_jmax: .db 0
pw_f:	.db 0
pw_slot: .db 0
pw_left: .db 0
pw_right: .db 0
pw_dlo:	.db 0
pw_dhi:	.db 0
pw_flo:	.db 0
pw_fhi:	.db 0
pw_pn:	.db 0
pw_t0:	.db 0
pw_off:	.dw 0
pw_jend:	.db 0
pw_pass:	.db 0

bi_cam:	lda CAMX+1
	sta t0
	lda CAMX
	lsr t0
	ror a
	lsr t0
	ror a
	lsr t0
	ror a
	clc
	adc #2
	cmp #(BAND + 16) >> 3
bi_c1      = * - 1          ; (quarry-seams: both 80, the band's first column at camera 624, with the seams' image in, sinit: the
	bcs .k                  ; bridge's hand-over sets the band up at 624-638 for the camera it is at, not for 640)
	lda #(BAND + 16) >> 3
bi_c2      = * - 1
.k:	sta cn
	sta bcn
	lsr a
	sta cm
	sta bcm
	lda #1                  ; (the band writes $680-$7FE from now: set 0 / set 1's restore due, from its start: qidle, qho, rall)
	sta wz
	stz rs
	lda vxok
	bne .x
	inc vxok
	cla
	jmp vxfer
.x:	rts

c3end:
	.if (c3end > C2ORG)
	.fail
	.endif

	.org C2ORG
shok:	.db 0           ; the shift tables made (0 in this sector's image: a read of the code areas, or the boot's preload)
modinit:	jsr c3rst               ; (step 3: bclr has cleared $7F, which holds set 1's copy: no copy this visit yet)
	lda mval                ; (the code areas as this module left them, and the shift tables made since: kept)
	beq .t
	lda shok
	bne .sk
.t:	inc shok
	tma #4                  ; shift tables: SHL[p][v] = (v << p) & $FF, SHR[p][v] = v >> (8 - p); SHBANK at MPR4
	pha
	lda #SHBANK
	tam #4
	cly                     ; SHL[0] = identity, SHR[0] = 0
.t0:	tya
	sta SHT - $4000,y
	cla
	sta SHT - $4000 + 256,y
	iny
	bne .t0
	ldx #1
.td:	stx t0
	txa
	asl a
	clc
	adc #>(SHT - $4000)
	sta .shl+2
	inc a
	sta .shr+2
	cly
.tv:	tya
	ldx t0
.l1:	asl a
	dex
	bne .l1
.shl:	sta SHT - $4000,y
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
.shr:	sta SHT - $4000 + 256,y
	iny
	bne .tv
	ldx t0
	inx
	cpx #8
	bne .td
	pla
	tam #4
.sk:	stz setok               ; (quarry-spire-fix: the area loads' count, nmodi, read by nothing, gave its byte of bank 0)
	stz ss
	stz card                ; (quarry-k17: an area load: no overlay of an earlier visit is in place)
	stz dvalid
	stz dvalid+1
	lda #$FF
	sta lastpass
	rts

; far words: 16 rows x 33 screen columns; two rows a step (first: set 1's tiles copied, 24 a step, before anything of ours is written there)
ss_far:	jsr capt
	bcs ss_far0
	lda #1
	rts
ss_far0:	lda ssb4
	tam #4
	lda #2
	sta t2
f_rw:	lda si                  ; destination + r * 64, source + r * 32
	stz t0
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t0
	sta t1
	asl a
	rol t0
	sta f_dl+1
	sta f_dh+1
	lda t0
	clc
	adc #>FARL
	sta f_dl+2
	lda t0
	clc
	adc #>FARH
	sta f_dh+2
	lda si
	stz t0
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t0
	clc
	adc fal
	sta f_s+1
	lda t0
	adc fah
	sta f_s+2
	cly
f_c:	tya
	and #$1F
	tax
f_s:	lda $FFFF,x
	clc
	adc flo
f_dl:	sta $FFFF,y
	lda fhi
	adc #0
f_dh:	sta $FFFF,y
	iny
	cpy #33
	bne f_c
	inc si
	lda si
	cmp #16
	beq f_e
	dec t2
	bne f_rw
	lda #T2
	tam #4
	lda #1
	rts
f_e:	stz si
	stz nsd                 ; the near scan's order: from the side the camera is nearer (480: the hand-back's middle)
	stz sj
	lda #NBL
	ldx CAMX+1
	bmi .s
	cpx #>480
	bcc .s
	bne .r
	ldx CAMX
	cpx #<480
	bcc .s
.r:	inc nsd
	lda #NCOLS - 1
	sta sj
	lda #NBR
.s:	sta nbc
	lda #SSNEAR
	sta ss
	lda #T2
	tam #4
	lda #1
	rts

; the pool's VRAM addresses and stamps: set 0 tiles $772 + i; set 1 the runs of pool1
POOL1C	= 1
pool1:	.db $80, $06, 142
pooltab:	clx
	stz t2                  ; run, its next tile, its count
	lda pool1
	sta t0
	lda pool1+1
	sta t1
	lda pool1+2
	sta t3
.i:	txa                     ; set 0: tile $772 + i, its VRAM address << 4
	clc
	adc #$72
	sta kk
	sta WL0,x
	lda #$07
	adc #0
	sta WH0,x
	jsr tileaddr
	lda sv_a
	sta VL0,x
	lda sv_b
	sta VH0,x
	lda t0                  ; set 1
	sta kk
	sta WL1,x
	lda t1
	sta WH1,x
	jsr tileaddr
	lda sv_a
	sta VL1,x
	lda sv_b
	sta VH1,x
	inc t0
	bne .n
	inc t1
.n:	dec t3
	bne .k
	inc t2                  ; next run
	phx
	lda t2
	asl a
	clc
	adc t2
	tax
	cpx #POOL1C * 3
	bcs .e
	lda pool1,x
	sta t0
	lda pool1+1,x
	sta t1
	lda pool1+2,x
	sta t3
.e:	plx
.k:	lda pass
	sec
	sbc #64
	sta STAMP,x
	stz PIN,x
	inx
	cpx #POOLN
	bne .i
	rts
tileaddr:	sta sv_b
	lda kk
	asl a
	rol sv_b
	asl a
	rol sv_b
	asl a
	rol sv_b
	asl a
	rol sv_b
	sta sv_a
	rts

einit:	jsr ereset
	jmp einit2
ereset:	stz qh
	stz qt
	stz bst
	lda #EBANK0
	sta ib
	stz ia
	lda #$C0
	sta ia+1
	stz iz
	stz nkeys
	stz nkeys+1
	stz nbuilt
	stz nbuilt+1
	stz nnofit
	ldx #WN                 ; (no window scanned)
.zw:	stz wsc - 1,x
	dex
	bne .zw
	lda #$FF
	sta sw
	lda #8                  ; T3's clearing: in steps
	sta efill
	stz sdone
	stz iz
	lda #1
	sta rmns
	sta rmns+1
	sta rmns+2
	clx
.zb:	txa                     ; recoloured tile 0 of each: all zero
	clc
	adc #T4
	tam #4
	ldy #31
.z0:	cla
	sta $8000,y
	dey
	bpl .z0
	inx
	cpx #3
	bne .zb
	lda #T2
	tam #4
	rts
einit2:
	cly                     ; pmap: nothing
	lda #$FF
.pf:	sta pmap,y
	iny
	cpy #9 * 16
	bne .pf
	clx
.mp:	stx kk
	stz mcn
	lda mla,x
	jsr mlayer
	ldx kk
	lda mlb,x
	jsr mlayer
	jsr mwrite
	ldx kk
	inx
	cpx #3
	bne .mp
	lda #1
	sta pdirty
	rts
mla:	.db 0, 0, 1
mlb:	.db 2, 1, 2
mpal:	.db 5, 3, 4
mmaskl:	.db $BE, $FE, $FE
mmaskh:	.db $1B, $01, $01
mlayer:	sta t2
	asl a
	clc
	adc t2
	clc
	adc kk
	asl a
	asl a
	asl a
	asl a
	sta pmx                 ; the row
	tax
	stz pmap,x              ; (colour 0 stays 0)
	ldx t2
	lda mmaskl,x
	sta t0
	lda mmaskh,x
	sta t1
	lda #1
	sta t3                  ; index
	lsr t1                  ; (past bit 0)
	ror t0
.i:	lsr t1
	ror t0
	bcc .n
	lda t2
	asl a
	asl a
	asl a
	asl a
	asl a
	sta sv_a
	lda t3
	asl a
	clc
	adc sv_a
	tax
	lda $3C00,x
	sta sv_a
	lda $3C01,x
	sta sv_b
	ldx mcn
.f:	cpx #0
	beq .new
	txa
	asl a
	tay
	lda mcol,y
	cmp sv_a
	bne .nx
	lda mcol+1,y
	cmp sv_b
	beq .got
.nx:	dex
	bra .f
.new:	inc mcn
	lda mcn
	cmp #16
	bcs .n
	tax
	asl a
	tay
	lda sv_a
	sta mcol,y
	lda sv_b
	sta mcol+1,y
.got:	txa
	pha
	lda pmx
	clc
	adc t3
	tax
	pla
	sta pmap,x
.n:	inc t3
	lda t3
	cmp #16
	bne .i
	rts
mwrite:	lda kk
	asl a
	asl a
	asl a
	asl a
	asl a
	sta mw_sl+1
	inc a
	sta mw_sh+1
	ldx kk
	lda mpal,x
	sta t2
	stz t1
	asl a
	asl a
	asl a
	asl a
	asl a
	rol t1
	sta mw_l+1
	inc a
	sta mw_h+1
	lda t1
	clc
	adc #$3C
	sta mw_l+2
	sta mw_h+2
	lda t2
	asl a
	asl a
	asl a
	asl a
	sta t2                  ; VCE entry: p * 16 + i (p < 16: fits 8 bits)
	ldy #1
mw_c:	cpy #16
	beq mw_x
	cpy mcn
	beq mw_w
	bcc mw_w
	stz sv_a
	stz sv_b
	bra mw_o
mw_w:	tya
	asl a
	tax
	lda mcol,x
	sta sv_a
	lda mcol+1,x
	sta sv_b
mw_o:	tya
	asl a
	tax
	lda sv_a
mw_l:	sta $3C00,x
mw_sl:	sta MSAVE,x
	lda sv_b
mw_h:	sta $3C01,x
mw_sh:	sta MSAVE,x
	bbs3 <LOCKZP, mw_nv
	php
	sei
	tya
	ora t2
	sta $0402
	stz $0403
	lda sv_a
	sta $0404
	lda sv_b
	sta $0405
	plp
mw_nv:	iny
	bra mw_c
mw_x:	rts
leave:	jsr vxrest              ; (the band's borrowed runs back first, to the end)
	lda vxok
	bne leave
	tma #4
	pha
	lda dirty
	beq .x
	stz si
.t:	jsr clrnext
	bne .t
	stz dirty
.x:	pla
	tam #4
	lda pdirty
	beq .pd
	tma #4
	pha
	lda #T2
	tam #4
	stz pdirty
	stz kk
.pk:	stz mcn
	jsr mwrite2
	inc kk
	lda kk
	cmp #3
	bne .pk
	pla
	tam #4
.pd:	jsr pdrop
	clx
.zpal:	stz $3CC0,x
	inx
	cpx #64
	bne .zpal
	php
	sei
	lda #$60
	sta $0402
	stz $0403
	ldy #32
.zvce:	stz $0404
	stz $0405
	dey
	bne .zvce
	plp
	stz pw_state
	stz wsd
	stz setok
	stz act
	jsr sprest
	stz ROWGAME
	stz dvalid
	stz dvalid+1
	stz dfull
	stz dfull+1
	stz ss
	stz card
	jsr rall
	jmp batc


bchk:	ldx set
	lda <VDCREG
	pha
	php
	bbs6 <SPLITS, .on
	sei
.on:	vsel 1
	lda #$02
	sta $0002
	txa
	beq .s0
	lda #$82                ; (BAT row 18)
	sta $0002
	lda #$04
.s0:	sta $0003
	vsel 2
	lda $0002
	ldy $0003
	sta t0
	plp
	pla
	sta <VDCREG
	sta $0000
	lda t0
	cmp #$30
	bne .x
	tya
	and #$0F
	cmp #$01
	bne .x
	lda #1
	sta bla,x
	stz dvalid,x
	stz dfull,x
	tma #4
	pha
	lda #T2
	tam #4
	lda lpass
	sec
	sbc #64
	cly
.st:	sta STAMP,y
	iny
	cpy #POOLN
	bne .st
	pla
	tam #4
	rts
.x:	rts

bclr:	tma #4
	pha
	ldx #$69
.b:	txa
	tam #4
	stz $8000
	tii $8000, $8001, 31
	lda #$20
	sta .d + 3
	lda #$80
	sta .d + 4
.d:	tii $8000, $8020, 32
	lda .d + 3
	clc
	adc #32
	sta .d + 3
	bcc .c
	inc .d + 4
.c:	cpx #CBANK              ; (the bank this code runs in: its top 4 KB stay; SHBANK's too: the band path)
	beq .h
	cpx #SHBANK
	bne .e
.h:	lda .d + 4
	cmp #$90
	bra .t
.e:	lda .d + 4
	cmp #$A0
.t:	bne .d
.k:	inx
	cpx #KEEP1              ; (never written: the stub bank, the mine's code)
	beq .k
	cpx #KEEP2
	beq .k
	cpx #$80
	bne .b
	pla
	tam #4
	rts

batc:	stz t0
	stz t1
	lda #1
	sta <VDCREG
	sta $0000
	st1 #0
	st2 #0
	lda #2
	sta <VDCREG
	sta $0000
.w:	ldx $0002
	lda $0003
	and #7
	cmp #7
	beq .hit
	cmp #6                  ; tiles $680-$6FF (set 1)
	bne .nx
	cpx #$80
	bcc .nx
.hit:	jsr bcol                ; (MAWR selected, unless the word is in columns 40-63: carry set, not ours. The same 5 bytes as the
	bcs .nx                 ; select they replace, so nothing in this sector moves)
	lda t0
	sta $0002
	lda t1
	sta $0003
	lda #2
	sta <VDCREG
	sta $0000
	st1 #0
	st2 #0
	lda #1
	sta <VDCREG
	sta $0000
	lda t0
	clc
	adc #1
	sta $0002
	lda t1
	adc #0
	sta $0003
	lda #2
	sta <VDCREG
	sta $0000
.nx:	inc t0
	bne .w
	inc t1
	lda t1
	cmp #>(64 * 36)
	bne .w
	rts

; ---------------------------------------------------------------- the band's groups (quarry-band1-groups)
ginit2:	clx
.s:	stz GUSE,x
	stz GREADY,x
	lda #$FF
	sta GSLOT,x
	inx
	cpx #136
	bne .s
	ldy #<(VXT0 - 1)
	lda #>(VXT0 - 1)
	sta t1
	clx
.g:	txa
	sta GFREE,x
	cpx #VXG
	bne .n
	ldy #<($700 - 1)
	lda #>($700 - 1)
	sta t1
.n:	tya
	sta GVL,x
	clc
	adc #3
	tay
	lda t1
	sta GVH,x
	adc #0
	sta t1
	inx
	cpx #NGROUP
	bne .g
	stx gfn
	rts

vxfer:	tay                     ; (the body, vxall, is in the fourth code area: every borrowed run, Y = A)
	lda #9
	ldx #C5BANK
	jmp callx
; carry clear: window A is ready (scanned, and no key queued before its ticket still unmade: the keys not made, nkeys - nbuilt -
; nnofit, all queued after it; then wsc 2 for good), or outside the open quarry. A kept.
wrdy:	tax
	cmp #WN
	bcs .y
	lda wsc,x
	beq .no
	cmp #2
	beq .y
	lda nkeys
	sec
	sbc nbuilt
	sec
	sbc nnofit
	sta wq2
	lda nkeys
	sec
	sbc wtk,x
	cmp wq2
	bcc .no
	lda #2
	sta wsc,x
.y:	txa
	clc
	rts
.no:	txa
	sec
	rts
; carry clear: the windows around the camera's (A - 1 .. A + 1: all a camera can show before the next aligned pass) are ready
w3rdy2:	lda imall               ; (the open quarry's images first: the background, from the band's side)
	bne .i
	sec
	rts
.i:	jsr wcam
	sta wq
	dec a
	jsr wrdy
	bcs .x
	lda wq
	jsr wrdy
	bcs .x
	inc a
	jsr wrdy
.x:	rts

bgrun:	lda hcl
	cmp #<(THAND + 16)
	lda hch
	sbc #>(THAND + 16)
	bcc .x
	lda CAMX
	and #15
	cmp #14
	beq .n
	cmp #2
	beq .n
	lda bgss
	sta ss
	inc early
	jsr ssrun
	lda ss
	sta bgss
	stz ss
.n:	sec
.x:	rts
bgbs:	inc bgm                 ; band_setup a piece at a time (Z clear: more)
	jsr band_setup
	stz bgm
	lda bsr
	rts
bgm:	.db 0
qj_bp:	lda card
	dec a
	beq qj_i
qj_bo:	lda CAMX+1
	jmp qi_bp + 3
qj_cb:	lda card
	dec a
	beq qj_i
qj_co:	stz pw_state
	jmp qi_cb + 3
qj_i:	jmp idcx
bcol:	lda t0
	and #63
	cmp #40
	bcs .x
	stz <VDCREG
	stz $0000
.x:	rts
qho_fin:
	sta STUB_CURMOD
	lda #STUB_XR
	jmp STUB_XCALL
c2end:
	.if (c2end > MSAVE)
	.fail
	.endif

	.org MSAVE + $60
ss_end2:	lda bgf
	bne .bg
	lda ekon                ; (einit, unless at ss_mid's end)
	bne .ek
	jsr einit
.ek:	inc nsetup
	lda FRAMES
	sta tset1
	stz dvalid
	stz dvalid+1
	stz dfull
	stz dfull+1
	jsr pdrop
	stz ldir
	stz act                 ; (handover takes over at the first aligned camera below the threshold)
	lda nsd                 ; the entry side's part: from the band's side its set-up now (the open quarry's images follow in the
	beq .o                  ; background, bgss), from the open quarry's side the band's images and set-up follow
	lda CAMX+1              ; (band_setup's synchronous prewarm: camera 624 on, in the dark set-up: dkin stays 1)
	cmp #2
	bcc .p0
	bne .p1
	lda CAMX
	cmp #<624
	bcs .p1
.p0:	stz dkin
.p1:	jsr band_setup
	inc bsok
	bra .k
.o:	inc imall
.k:	lda #1
	sta setok
	inc bgf                 ; the background: near nk1 .. nk - 1; mid 0 .. mk1 - 1 from the band's side, none from the other
	lda nk
	sta gnh
	lda mk1
	sta gmh
	ldx nsd
	bne .m
	sta gml
	bra .m2
.m:	stz gml
.m2:	lda nk1
	sta si
	lda #SSGN
	sta bgss
	stz ss
	lda #0
	rts
.bg:	lda nsd                 ; (the background's end: from the open quarry's side the band's set-up, a piece a call)
	bne .bo
	jsr bgbs
	bne .mo
	inc bsok
	bra .bz
.bo:	inc imall
.bz:	stz bgf
	stz ss
	lda #0
	rts
.mo:	lda #6
	rts

c2top:
	.if (c2top > $E000)
	.fail
	.endif


	.bank 3
	.org C4ORG
bandjt:	jmp band_init           ; 0: the take-over (far words, the property table; nothing in VRAM yet)
	jmp band_pass           ; 3: a pass's first row (cn, cm set): the layer tables shifted to this position, WIN composed
	jmp band_row            ; 6: a row: WIN's row to the VDC
	jmp b_exit              ; 9: letting go (zeroes VRAM $700-$7FF)
	jmp b_negen             ; 12: negen wrapper for callb
	jmp bu_c5               ; 15: band_upl (in the fourth code area)
	jmp t3fill              ; 18: pw_init's fill of the mix store, in pieces
bpx:	sec                     ; 21: (quarry-bridge-draw) the bridge's pass (passbegin's brm 21), here itself: c6ext with the carry set
	bra bx_c
	jmp cpos                ; 24: the camera's motion and position (passbegin)
	lda #18                 ; 27: (qidle, a window over the band) wsdo in the fourth code area
	ldx #C5BANK
	jmp callx
cposb:	jsr cpos
	lda card
	dec a
	bne bx_r
bx_c:	tma #3
	pha
	lda #C6BANK
	tam #3
	jsr c6ext
	pla
	tam #3
bx_r:	rts

; the take-over: reset column tracking and groups
band_init:	tma #4
	pha
	tma #3
	pha
	lda #BANDT
	tam #4
	lda ssb6
	tam #3
	stz nbpass
	stz nbpass+1
	lda #28
	jsr call2
	lda #12                 ; (C5 midsetup: the band's mid pairs and their tiles' patterns)
	ldx #C5BANK
bims:	jsr callx               ; (quarry-finish-2: BIT while the seams' image's sturn sets the columns up again for the camera)
	jsr rebuild             ; (ginit, then every column fetched: groups held and queued)
	jsr mrebuild
	lda #1
	sta nwfull
	stz pn
	stz dm
	jsr mwalk
	jsr nwalk
	pla
	tam #3
	pla
	tam #4
	rts

; a pass: the lists and kind maps follow cn / cm (one column shifted in when they moved by one, everything fetched on a jump),
; the cells they left get their under layer, then every listed cell gets this pass's word
band_pass:	tma #3
	pha
	tma #4
	pha
	lda ssb6
	tam #3
	lda #BANDT
	tam #4
	inc nbpass
	bne *+5
	inc nbpass+1
	stz nwfull
	lda cn
	cmp bcn
	bne bp_ch
	lda cm
	cmp bcm
	beq bp_nd
bp_ch:	inc nwfull
	jsr bmv
	.db 33, $73
	.dw FW, WIN
	lda cn
	cmp bcn
	beq bp_nd
	sec
	sbc bcn
	cmp #1
	beq bp_nl
	cmp #$FF
	beq bp_nr
	jsr rebuild
	jsr mrebuild
	lda cn
	sta bcn
	jmp bp_md
bp_nl:
	.if PROFV
	lda $0C00
	sta tpv1
	.endif
	jsr bmv                 ; moved right by a column: NP .. NP + 543 (the 16 bytes past NP are free) in 17 pieces
	.db 17, $73
	.dw NP + 1, NP
	jsr ntrimh
	.if PROFV
	lda $0C00
	sta tpv2
	.endif
	ldy #32
	jsr nfetch
	.if PROFV
	lda $0C00
	sta tpv3
	.endif
	bra bp_nd
bp_nr:
	.if PROFV
	lda $0C00
	sta tpv0
	.endif
	jsr bmv                 ; moved left (NP .. NP + 543)
	.db 17, $C3
	.dw NP + 542, NP + 543
	.if PROFV
	lda $0C00
	sta tpv1
	.endif
	jsr ntrimt
	.if PROFV
	lda $0C00
	sta tpv2
	.endif
	cly
	jsr nfetch
	.if PROFV
	lda $0C00
	sta tpv3
	.endif
bp_nd:	lda cn
	sta bcn
	lda cm
	cmp bcm
	beq bp_md
	sec
	sbc bcm
	cmp #1
	beq bp_ml
	cmp #$FF
	beq bp_mr
	jsr mrebuild
	bra bp_md
bp_ml:	jsr bmv                 ; MP, MA, MS (a page apart) moved together: 23 pieces, MP .. MS + 197 and the gaps (nothing lives there)
	.db 23, $73
	.dw MP + 1, MP
	ldy #32
	jsr mfetch
	bra bp_md
bp_mr:	jsr bmv
	.db 23, $C3
	.dw MP + 734, MP + 735
	cly
	jsr mfetch
bp_md:	lda cm
	sta bcm
	.if PROFV
	lda $0C00
	sta tpm0
	.endif
	lda #T3                 ; (the mix jobs: MJ in T3)
	tam #3
	stz nmix
	lda nbpass
	and #1
	beq *+4
	lda #64
	sta mset
	lda dm                  ; the mid cells' whole tiles: at mid phase 0 (every mid cell's word) and at a column change
	beq bp_mw
	lda nwfull
	beq bp_nmw
bp_mw:	jsr mwalk
bp_nmw:
	.if PROFV
	lda $0C00
	sta tpm1
	.endif
	jsr nwalk
	.if PROFV
	lda $0C00
	sta tpm2
	.endif
	lda #3
	ldx #C5BANK
	jsr callx
	pla
	tam #4
	pla
	tam #3
	rts

; every column fetched: the lists emptied, WIN all far, the kind maps clear
rebuild:	lda cn                  ; (bc0 = cn - 32: NLX = 2 (c - bc0) stays positive and under 256 anywhere in the band)
	sec
	sbc #32
	sta bc0
	jsr ginit
	stz gqh                 ; (nothing queued; no head part-done)
	stz gqt
	stz gqp
	jsr bmv
	.db 33, $73
	.dw FW, WIN
	stz NP
	jsr bmv                 ; (16 pieces: NP's last 15 bytes are written by the fetches anyway)
	.db 16, $73
	.dw NP, NP + 1
	clx
rb_z:	stz nlh,x
	stz nlt,x
	inx
	cpx #16
	bne rb_z
	cly
rb_c:	phy
	jsr nfetch
	ply
	iny
	cpy #33
rb_n       = * - 1          ; (quarry-seams-2: 1 for a call of the seams' image, sebi: the head and column 0 only)
	bne rb_c
	rts
mrebuild:	stz MP
	jsr bmv                 ; (7 pieces: MP and its gap; mfetch writes every cell anyway)
	.db 7, $73
	.dw MP, MP + 1
	cly
mrb_c:	phy
	jsr mfetch
	ply
	iny
	cpy #33
mrb_n      = * - 1          ; (quarry-seams-2: likewise)
	bne mrb_c
	rts

; a dying entry (ring index Y, row X): a pair's slot loses a user; the last frees its group (X, Y kept)
grel:	phx
	phy
gr_k:	lda NLK,y
	cmp #1
	bne gr_x
gr_g:	lda NLG,y
	tax
	dec GUSE,x
	bne gr_x
	stz GREADY,x            ; (ready is per slot)
	lda GSLOT,x
	tay
	lda #$FF
	sta GSLOT,x
	ldx gfn
	tya
	sta GFREE,x
	inc gfn
gr_x:	ply
	plx
	rts

; the heads: entries at columns below cn die
ntrimh:	stz t0                  ; r
	lda #<NLC
	sta nth_c+1
	sta gr_k+1
	sta gr_g+1
	lda #>NLC
	sta nth_c+2
	lda #>NLK
	sta gr_k+2
	lda #>NLG
	sta gr_g+2
nth_r:	ldx t0
	lda nlh,x
nth_l:	cmp nlt,x
	beq nth_e
	and #NLMASK
	tay
nth_c:	lda NLC,y
	cmp cn
	bcs nth_e
	jsr grel
	lda nlh,x
	inc a
	sta nlh,x
	bra nth_l
nth_e:	lda nth_c+1
	clc
	adc #32
	sta nth_c+1
	sta gr_k+1
	sta gr_g+1
	bcc *+11
	inc nth_c+2
	inc gr_k+2
	inc gr_g+2
	inc t0
	lda t0
	cmp #16
	bne nth_r
	rts
; the tails: entries at columns past cn + 32 die
ntrimt:	stz t0
	lda #<NLC
	sta ntt_c+1
	sta gr_k+1
	sta gr_g+1
	lda #>NLC
	sta ntt_c+2
	lda #>NLK
	sta gr_k+2
	lda #>NLG
	sta gr_g+2
ntt_r:	ldx t0
	lda nlt,x
ntt_l:	cmp nlh,x
	beq ntt_e
	dec a
	and #NLMASK
	tay
ntt_c:	lda NLC,y
	sec
	sbc cn
	cmp #33
	bcc ntt_e
	jsr grel
	lda nlt,x
	dec a
	sta nlt,x
	bra ntt_l
ntt_e:	lda ntt_c+1
	clc
	adc #32
	sta ntt_c+1
	sta gr_k+1
	sta gr_g+1
	bcc *+11
	inc ntt_c+2
	inc gr_k+2
	inc gr_g+2
	inc t0
	lda t0
	cmp #16
	bne ntt_r
	rts

; the near cells of screen column Y (near column cn + Y): the 16 rows' codes and kinds read from the map (ssb6 at MPR3), the
; pairs' slots looked up in T2 (a flat pair, PFLAT: kind 4, its left tile at every phase), then NP and the entries: at the tails
; (Y = 32, or a rebuild) or before the heads (Y = 0). MPR4 is BANDT on entry and exit.
nfetch:	sty t3
	tya
	clc
	adc cn
	sta t2                  ; c
	sta nf_a+1
	inc a
	sta nf_b+1
	sta nf_b2+1
	lda #$60
	sta nf_a+2
	sta nf_b+2
	sta nf_b2+2
	clx                     ; r
nf_r:
nf_a:	lda $6000
	and #$7F
	tay
	lda PROP2,y
	bmi nf_na
	tya
	sta nfA,x
nf_b:	lda $6001
	and #$7F
	tay
	lda PROP2,y
	bmi nf_a0
	tya
	sta nfB,x
	lda #1                  ; pair
	bra nf_e
nf_a0:	lda #2                  ; A only
	bra nf_e
nf_na:
nf_b2:	lda $6001
	and #$7F
	tay
	lda PROP2,y
	bmi nf_no
	tya
	sta nfA,x               ; (the present tile)
	lda #3                  ; B only
	bra nf_e
nf_no:	cla
nf_e:	sta nfK,x
	inc nf_a+2
	inc nf_b+2
	inc nf_b2+2
	inx
	cpx #16
	bne nf_r
	lda #T1                 ; the pairs' slots: T1's NSLOT (row r, column c) at MPR3
	tam #3
	lda t2
	sta nf_s1+1
	lda #>NSLOT
	sta nf_s1+2
	clx
nf_s:	lda nfK,x
	cmp #1
	bne nf_sn
nf_s1:	lda NSLOT
	sta nfG,x
	cmp #KMAX
	bcc nf_sn
	lda #4                  ; past the cap: the left tile whole at every phase
	sta nfK,x
nf_sn:	inc nf_s1+2
	inx
	cpx #16
	bne nf_s
	lda #BANDT              ; the ends: their near-end parts (made now if new): e into nfG
	tam #4
	clx
nf_e1:	lda nfK,x
	cmp #2
	bcc nf_e2
	cmp #4
	bcs nf_e2
	phx
	lda nfA,x
	tax
	lda NEIDX,x
	cmp #$FF
	bne nf_e3
	lda t1                  ; (negen and rdtile use t0-t3)
	pha
	lda t2
	pha
	lda t3
	pha
	txa
	jsr negen
	sta t0
	pla
	sta t3
	pla
	sta t2
	pla
	sta t1
	lda t0
nf_e3:	plx
	sta nfG,x
nf_e2:	inx
	cpx #16
	bne nf_e1
	lda ssb6
	tam #3
	lda t3                  ; NP + r * 33 + j: row 0's
	clc
	adc #<NP
	sta nf_p+1
	lda #>NP
	adc #0
	sta nf_p+2
	lda #<NLC               ; row 0's rings
	sta nf_c+1
	sta nf_k+1
	sta nf_x+1
	sta nf_g+1
	sta nf_o+1
	sta nf_vl+1
	sta nf_vh+1
	sta nf_vl2+1
	sta nf_vh2+1
	sta nf_k2+1
	lda #>NLC
	sta nf_c+2
	lda #>NLK
	sta nf_k+2
	sta nf_k2+2
	lda #>NLA
	sta nf_x+2
	lda #>NLG
	sta nf_g+2
	lda #>NLX
	sta nf_o+2
	lda #>NLVL
	sta nf_vl+2
	sta nf_vl2+2
	lda #>NLVH
	sta nf_vh+2
	sta nf_vh2+2
	lda t2                  ; 2 (c - bc0)
	sec
	sbc bc0
	asl a
	sta t1
	clx
nf_w:	lda nfK,x
nf_p:	sta NP
	bne *+5
	jmp nf_n
	pha
	lda t3                  ; the entry: at the tail (Y = 32 or a rebuild), else before the head
	bne nf_t
	lda nlh,x
	dec a
	sta nlh,x
	bra nf_w2
nf_t:	lda nlt,x
	inc nlt,x
nf_w2:	and #NLMASK
	tay
	pla
nf_k:	sta NLK,y
	lda t2
nf_c:	sta NLC,y
	lda nfA,x
nf_x:	sta NLA,y
	lda nfG,x
nf_g:	sta NLG,y
	lda t1
nf_o:	sta NLX,y
	lda nfK,x
	cmp #1
	bne nf_wa
	lda t2                  ; (column NOGC on: on screen only at camera 752, phase 0: the tile A, no group)
	cmp #NOGC
	bcs nf_g4
	phx
	lda nfG,x               ; the pair's slot: a group for it (held while any entry on screen uses the slot)
	tax
	inc GUSE,x
	lda GSLOT,x
	cmp #$FF
	bne nf_gw
	lda gfn
	beq nf_gn
	dec gfn
	phy
	ldy gfn
	lda GFREE,y
	ply
	sta GSLOT,x
	phy
	ldy gqt                 ; queued for upload (the slot; its group from GSLOT)
	txa
	sta GQ,y
	iny
	tya
	and #127
	sta gqt
	ply
	lda GSLOT,x
	bra nf_gw
nf_gn:	dec GUSE,x              ; no group free: the whole tile (kind 4 for this entry, counted; it does not hold the slot)
	plx
	inc gover
nf_g4:	lda #4
nf_k2:	sta NLK,y
	bra nf_wa
nf_gw:	tax                     ; the group's first tile - 1 (the word at phase pn: + pn)
	lda GVL,x
nf_vl2:	sta NLVL,y
	lda GVH,x
nf_vh2:	sta NLVH,y
	plx
	bra nf_n
nf_wa:	lda nfA,x               ; the phase-0 word: the whole tile A (for a B-only end: never used at phase 0)
	clc
	adc nlo
nf_vl:	sta NLVL,y
	lda nhi
	adc #0
nf_vh:	sta NLVH,y
nf_n:	lda nf_p+1
	clc
	adc #33
	sta nf_p+1
	bcc *+5
	inc nf_p+2
	lda nf_c+1
	clc
	adc #32
	sta nf_c+1
	sta nf_k+1
	sta nf_x+1
	sta nf_g+1
	sta nf_o+1
	sta nf_vl+1
	sta nf_vh+1
	sta nf_vl2+1
	sta nf_vh2+1
	sta nf_k2+1
	bcc *+32
	inc nf_c+2
	inc nf_k+2
	inc nf_x+2
	inc nf_g+2
	inc nf_o+2
	inc nf_vl+2
	inc nf_vh+2
	inc nf_vl2+2
	inc nf_vh2+2
	inc nf_k2+2
	inx
	cpx #16
	beq *+5
	jmp nf_w
	rts

; the mid cells of screen column Y (mid column cm + Y), rows 10-15: MP (kind; 4 flat), MA (the tile A), MS (the pair's slot)
mfetch:	sty t3
	tya
	clc
	adc cm
	sta mf_a+1
	inc a
	sta mf_b+1
	sta mf_b2+1
	lda #$7A                ; row 10
	sta mf_a+2
	sta mf_b+2
	sta mf_b2+2
	clx
mf_r:
mf_a:	lda $7A00
	beq mf_na
	sta nfA,x
mf_b:	lda $7A01
	beq mf_a0
	sta nfB,x
	lda #1
	bra mf_e
mf_a0:	lda #2
	bra mf_e
mf_na:
mf_b2:	lda $7A01
	beq mf_no
	sta nfA,x
	lda #3
	bra mf_e
mf_no:	cla
mf_e:	sta nfK,x
	inc mf_a+2
	inc mf_b+2
	inc mf_b2+2
	inx
	cpx #6
	bne mf_r
	lda #T1                 ; the pairs' slots: T1's MSLOT (row r, column c: + r * 128 + c) at MPR3
	tam #3
	lda t3
	clc
	adc cm
	sta mf_s1+1
	lda #>(MSLOT + 10 * 128)
	sta mf_s1+2
	clx
mf_s:	lda nfK,x
	cmp #1
	bne mf_sn
mf_s1:	lda MSLOT
	sta nfG,x
	cmp #MKMAX
	bcc mf_sn
	lda #4
	sta nfK,x
mf_sn:	lda mf_s1+1
	eor #$80
	sta mf_s1+1
	bne *+5
	inc mf_s1+2
	inx
	cpx #6
	bne mf_s
	lda ssb6
	tam #3
	lda t3
	clc
	adc #<MP
	sta mf_p+1
	sta mf_m+1
	sta mf_g+1
	lda #>MP
	adc #0
	sta mf_p+2
	inc a
	sta mf_m+2
	inc a
	sta mf_g+2
	clx
mf_w:	lda nfK,x
mf_p:	sta MP
	lda nfA,x
mf_m:	sta MA
	lda nfG,x
mf_g:	sta MS
	lda mf_p+1
	clc
	adc #33
	sta mf_p+1
	sta mf_m+1
	sta mf_g+1
	bcc *+11
	inc mf_p+2
	inc mf_m+2
	inc mf_g+2
	inx
	cpx #6
	bne mf_w
	rts

setrow:	lda WROW,x
	sta fx_w+1
	sta fx_w2+1
	sta ux_w+1
	sta ux_w2+1
	sta fx_f+1              ; (FW's row: WIN's + $B00)
	sta fx_f2+1
	lda WROWH,x
	sta fx_w+2
	sta fx_w2+2
	sta ux_w+2
	sta ux_w2+2
	clc
	adc #>(FW - WIN)
	sta fx_f+2
	sta fx_f2+2
	lda MPROW,x
	sta ux_p+1
	sta ux_m+1
	lda MPROWH,x
	sta ux_p+2
	inc a
	sta ux_m+2
	rts
; WIN cell (this row, X = 2 j) = its far word (X, Y kept)
farx:
fx_f:	lda FW,x
fx_w:	sta WIN,x
	inx
fx_f2:	lda FW,x
fx_w2:	sta WIN,x
	dex
	rts
; WIN cell (this row, X = 2 j, Y = j) = what is under the near layer: the mid tile A where the mid kind map has one (kind 1, 2),
; else far; rows below 10 have no mid (the caller: farx)
underx:
ux_p:	lda MP,y
	beq farx
	cmp #3
	beq farx
ux_m:	lda MA,y
	clc
	adc mlo
ux_w:	sta WIN,x
	lda mhi
	adc #0
	inx
ux_w2:	sta WIN,x
	dex
	rts

WROW:	.db <(WIN), <(WIN + 66), <(WIN + 132), <(WIN + 198), <(WIN + 264), <(WIN + 330), <(WIN + 396), <(WIN + 462)
	.db <(WIN + 528), <(WIN + 594), <(WIN + 660), <(WIN + 726), <(WIN + 792), <(WIN + 858), <(WIN + 924), <(WIN + 990)
WROWH:	.db >(WIN), >(WIN + 66), >(WIN + 132), >(WIN + 198), >(WIN + 264), >(WIN + 330), >(WIN + 396), >(WIN + 462)
	.db >(WIN + 528), >(WIN + 594), >(WIN + 660), >(WIN + 726), >(WIN + 792), >(WIN + 858), >(WIN + 924), >(WIN + 990)
NPROW:	.db <(NP), <(NP + 33), <(NP + 66), <(NP + 99), <(NP + 132), <(NP + 165), <(NP + 198), <(NP + 231)
	.db <(NP + 264), <(NP + 297), <(NP + 330), <(NP + 363), <(NP + 396), <(NP + 429), <(NP + 462), <(NP + 495)
NPROWH:	.db >(NP), >(NP + 33), >(NP + 66), >(NP + 99), >(NP + 132), >(NP + 165), >(NP + 198), >(NP + 231)
	.db >(NP + 264), >(NP + 297), >(NP + 330), >(NP + 363), >(NP + 396), >(NP + 429), >(NP + 462), >(NP + 495)
MPROWT:	.db <(MP), <(MP + 33), <(MP + 66), <(MP + 99), <(MP + 132), <(MP + 165)    ; (rows 10-15; rows below read the bytes before: unused)
MPROWHT:	.db >(MP), >(MP + 33), >(MP + 66), >(MP + 99), >(MP + 132), >(MP + 165)
MPROW      = MPROWT - 10
MPROWH     = MPROWHT - 10

; this pass's words: rows 13-15, every mid cell with no near over it (rows 10-12 have 0 mid tiles in Band 1)
mwalk:	lda card
	beq *+3
	rts
	lda #13
	sta t0
mdw_r:	ldx t0
	jsr setrow
	lda MPROW,x
	sta mdw_p+1
	sta mdw_m+1
	lda MPROWH,x
	sta mdw_p+2
	inc a
	sta mdw_m+2
	lda NPROW,x
	sta mdw_q+1
	lda NPROWH,x
	sta mdw_q+2
	lda WROW,x
	sta mdw_w+1
	sta mdw_w2+1
	lda WROWH,x
	sta mdw_w+2
	sta mdw_w2+2
	cly
mdw_l:
mdw_p:	lda MP,y
	beq mdw_n
mdw_q:	ldx NP,y
	bne mdw_n
	cmp #3
	beq mdw_u
	cmp #4
	bne mdw_t
	ldx nwfull
	beq mdw_n
mdw_t:	tya
	asl a
	tax
mdw_m:	lda MA,y
	clc
	adc mlo
mdw_w:	sta WIN,x
	lda mhi
	adc #0
	inx
mdw_w2:	sta WIN,x
	bra mdw_n
mdw_u:	tya
	asl a
	tax
	jsr farx
mdw_n:	iny
	cpy #33
	bne mdw_l
	inc t0
	lda t0
	cmp #16
	beq *+5
	jmp mdw_r
	rts
nwalk:	lda card
	beq *+3
	rts
	stz t0
	lda #<NLC
	sta nw_k+1
	sta nw_o+1
	sta nw_o2+1
	sta nw_o3+1
	sta nw_vl+1
	sta nw_vl2+1
	sta nw_vl3+1
	sta nw_vh+1
	sta nw_vh2+1
	sta nw_a+1
	sta nw_c+1
	sta nw_c2+1
	sta nw_c3+1
	sta nw_c4+1
	sta nw_g+1
	sta nw_g2+1
	sta nw_k2+1
	sta nw_k3+1
	sta nw_o4+1
	sta nw_o5+1
	sta nw_x5+1
	lda #>NLK
	sta nw_k+2
	sta nw_k2+2
	sta nw_k3+2
	lda #>NLG
	sta nw_g+2
	sta nw_g2+2
	sta nw_vl3+2
	lda #>NLX
	sta nw_x5+2
	sta nw_o+2
	sta nw_o2+2
	sta nw_o3+2
	sta nw_o4+2
	sta nw_o5+2
	lda #>NLVL
	sta nw_vl+2
	sta nw_vl2+2
	lda #>NLVH
	sta nw_vh+2
	sta nw_vh2+2
	lda #>NLA
	sta nw_a+2
	lda #>NLC
	sta nw_c+2
	sta nw_c2+2
	sta nw_c3+2
	sta nw_c4+2
	lda cn                  ; the WIN row base of column bc0's cell: WROW - 2 (cn - bc0) (36-92)
	sec
	sbc bc0
	asl a
	sta nw_sbc+1
	clc
	adc #64
	sta nw_x5c+1
nw_r:	ldx t0
	jsr setrow
	lda MPROW,x
	sta ux_p2+1
	sta ux_s2+1
	lda MPROWH,x
	sta ux_p2+2
	inc a
	inc a
	sta ux_s2+2
	lda WROW,x
	sec
nw_sbc:	sbc #0
	sta nw_w+1
	lda WROWH,x
	sbc #0
	sta nw_w+2
	lda nw_w+1
	sta nw_w3+1
	sta nw_w5+1
	sta nw_w7+1
	sta nw_f+1
	lda nw_w+2
	sta nw_w3+2
	sta nw_w5+2
	sta nw_w7+2
	clc
	adc #>(FW - WIN)        ; the far words at the same offset
	sta nw_f+2
	lda nw_w+1              ; + 1 for the high byte's store
	clc
	adc #1
	sta nw_w2+1
	sta nw_w4+1
	sta nw_w6+1
	sta nw_w8+1
	lda nw_w+2
	adc #0
	sta nw_w2+2
	sta nw_w4+2
	sta nw_w6+2
	sta nw_w8+2
	lda nlt,x
	sec
	sbc nlh,x
	bne *+5
	jmp nw_e
	sta t3                  ; entries left
	lda nlh,x
	and #NLMASK
	tay
nw_l:
nw_c:	lda NLC,y
nw_k:	lda NLK,y
	cmp #1
	beq nw_p
	cmp #4
	beq nw_o
	ldx pn                  ; an end: at phase 0 the tile A (kind 2) or the under (kind 3), else a mix
	beq nw_e0
	jmp nw_mix
nw_e0:	cmp #3
	bne nw_o
	jmp nw_u
nw_o:	ldx NLX,y
nw_vl:	lda NLVL,y
nw_w:	sta WIN,x
nw_vh:	lda NLVH,y
nw_w2:	sta WIN + 1,x
nw_n:	iny
	tya
	and #NLMASK
	tay
	dec t3
	bne nw_l
	bra nw_e
nw_p:	lda pn                  ; a pair: at phase 0 the tile A; else its group's tile at this phase when its three are in VRAM
	beq nw_pw
nw_vl3:	ldx NLG,y               ; (its slot: ready per slot)
	lda GREADY,x
	beq nw_pw
nw_o2:	ldx NLX,y
nw_vl2:	lda NLVL,y              ; (the group's first tile - 1, + pn)
	clc
	adc pn
nw_w3:	sta WIN,x
nw_vh2:	lda NLVH,y
	adc #0
nw_w4:	sta WIN + 1,x
	bra nw_n
nw_pw:
nw_o3:	ldx NLX,y
nw_a:	lda NLA,y
	clc
	adc nlo
nw_w5:	sta WIN,x
	lda nhi
	adc #0
nw_w6:	sta WIN + 1,x
	bra nw_n
nw_e:	lda nw_k+1
	clc
	adc #32
	sta nw_k+1
	sta nw_o+1
	sta nw_o2+1
	sta nw_o3+1
	sta nw_vl+1
	sta nw_vl2+1
	sta nw_vl3+1
	sta nw_vh+1
	sta nw_vh2+1
	sta nw_a+1
	sta nw_c+1
	sta nw_c2+1
	sta nw_c3+1
	sta nw_c4+1
	sta nw_g+1
	sta nw_g2+1
	sta nw_k2+1
	sta nw_k3+1
	sta nw_o4+1
	sta nw_o5+1
	sta nw_x5+1
	bcc nw_ni
	inc nw_k+2
	inc nw_o+2
	inc nw_o2+2
	inc nw_o3+2
	inc nw_vl+2
	inc nw_vl2+2
	inc nw_vl3+2
	inc nw_vh+2
	inc nw_vh2+2
	inc nw_a+2
	inc nw_c+2
	inc nw_c2+2
	inc nw_c3+2
	inc nw_c4+2
	inc nw_g+2
	inc nw_g2+2
	inc nw_k2+2
	inc nw_k3+2
	inc nw_o4+2
	inc nw_o5+2
	inc nw_x5+2
nw_ni:	inc t0
	lda t0
	cmp #16
	beq *+5
	jmp nw_r
	rts
nw_u:	lda t0                  ; (kind 3 at phase 0: the under)
	cmp #10
	bcs nw_u2
nw_c3:	lda NLC,y               ; (no mid in this row: the far word, at the column changes)
	sec
	sbc cn
	asl a
	tax
	jsr farx
nw_nj:	jmp nw_n
nw_u2:	sty t1
nw_c2:	lda NLC,y
	sec
	sbc cn
	tay
	asl a
	tax
	jsr underx
	ldy t1
	jmp nw_n
nw_mix:
nw_x5:	lda NLX,y               ; (screen column 32, under the frame's right border: no mix, MJMAX kept for the 32 shown;
nw_x5c:	cmp #64                 ; NLX = 2 (c - bc0): column 32 is NLX >= 2 (cn - bc0) + 64)
	bcs nw_mno
nw_g:	lda NLG,y
	cmp #$FF
	beq nw_mno
	lda nmix
	cmp #MJMAX
	bcc nw_mok
	inc nmixov
nw_mno:
nw_k3:	lda NLK,y
	cmp #3
	bne nw_oj
	jmp nw_u
nw_oj:	jmp nw_o
nw_mok:	sty t1
	ldx nmix
nw_k2:	lda NLK,y               ; e | side << 7 (side 1: kind 3)
	cmp #3
nw_g2:	lda NLG,y
	bcc *+4
	ora #$80
	sta MJ_E,x
	lda pn                  ; pal | pn << 1 (pal set below)
	asl a
	sta MJ_P,x
	lda #$FF
	sta MJ_BNK,x
	lda t0                  ; the under: rows below 13 far; else the mid kind map: a pair -> MPB, else far
	cmp #13
	bcc nw_mf
	phx
nw_c4:	lda NLC,y
	sec
	sbc cn
	tay
ux_p2:	lda MP,y
	cmp #1
	beq ux_s2
	plx
	ldy t1
	bra nw_mf
ux_s2:	lda MS,y
	stz t2
	asl a
	rol t2
	asl a
	rol t2
	asl a
	rol t2
	asl a
	rol t2
	asl a
	rol t2
	plx
	sta MJ_LO,x
	lda dm
	and #3
	asl a
	asl a
	asl a
	clc
	adc t2
	clc
	adc #$80
	sta MJ_HI,x
	lda dm
	lsr a
	lsr a
	clc
	adc #MPB
	sta MJ_BNK,x
	lda MJ_P,x
	ora #1                  ; pal 1: merged with mid
	sta MJ_P,x
	ldy t1
	jmp nw_mw
nw_mf:	lda MJ_E,x              ; (side << 7) | e (properly row-modified)
	cmp #$80                ; Carry = side
	and #$7F                ; A = e
	rol a                   ; A = (e << 1) | side = es!
	sta ces
	phx
nw_o4:	ldx NLX,y
nw_f:	lda FW,x
	sec
	sbc flo
	sta t2                  ; t2 = f
	ldx ces                 ; X = es
	clc
	adc T3_LO,x
	sta .c_t3+1
	lda T3_HI,x
	adc #0
	sta .c_t3+2
.c_t3:	lda $6000               ; slot directly from T3!
	cmp #$FF
	beq nw_mf_live
	sta cslot               ; slot
	plx                     ; restore X = MJ job index (nmix)
	lda cslot
	asl a
	asl a
	asl a
	asl a
	asl a
	sta MJ_LO,x
	lda cslot
	lsr a
	lsr a
	lsr a
	clc
	adc #$60
	sta MJ_HI,x
	ldy pn
	lda ces
	cmp #9
	bcs .nw_b1
	lda PBNK,y
	bra .nw_bok
.nw_b1:
	lda PBNK_B,y
.nw_bok:
	sta MJ_BNK,x
	ldy t1                  ; restore ring index
	jmp nw_mw
nw_mf_live:
	lda t2                  ; restore f in A
	stz t2
	asl a
	rol t2
	asl a
	rol t2
	asl a
	rol t2
	asl a
	rol t2
	asl a
	rol t2
	plx
	sta MJ_LO,x
	lda t2
	clc
	adc #$80
	sta MJ_HI,x
nw_mw:	lda nmix
	cmp #64
	bcc nw_mw0
	clc
	adc #<MIXX - 64
	bit mset                ; (V: set 1, mset = 64; Y is the ring index, kept)
	bvc nw_mw1
	adc #2
	bra nw_mw1
nw_mw0:	clc
	adc mset
	clc
	adc #<MIXBASE
nw_mw1:	sta MJ_T,x
	pha
	lda MJ_P,x
	and #1
	bne nw_mpm
	lda #(>MIXBASE) | (PALF << 4)
	bra nw_mww
nw_mpm:	lda #(>MIXBASE) | (PALM << 4)
nw_mww:	sta t2
	inc nmix
nw_o5:	ldx NLX,y
	pla
nw_w7:	sta WIN,x
	lda t2
nw_w8:	sta WIN + 1,x
	jmp nw_n

bmv:	tsx
	lda $2101,x
	sta mv_p+1
	clc
	adc #6
	sta $2101,x
	lda $2102,x
	sta mv_p+2
	adc #0
	sta $2102,x
	lda card
	bne mv_x
	ldy #6
mv_p:	lda $FFFF,y
	sta mv_n - 1,y
	dey
	bne mv_p
	bra mv_i
mv_n:	.db 0
mv_i:	tii 0, 0, 32
	dec mv_n
	beq mv_x
	ldx #1
	jsr mv_ad
	ldx #3
	jsr mv_ad
	bra mv_i
mv_ad:	lda mv_i
	bmi mv_m
	lda mv_i,x
	clc
	adc #32
	sta mv_i,x
	bcc mv_x
	inc mv_i + 1,x
mv_x:	rts
mv_m:	lda mv_i,x
	sec
	sbc #32
	sta mv_i,x
	bcs mv_x
	dec mv_i + 1,x
	rts
; the mix store emptied ($FF) in pieces (pw_init, T3 at MPR3)
t3fill:	lda #$FF
	sta $6000
	lda #$00
	sta t3f+1
	inc a
	sta t3f+3
	lda #$60
	sta t3f+2
	sta t3f+4
	ldx #204
t3f:	tii $6000, $6001, 32
	lda t3f+1
	clc
	adc #32
	sta t3f+1
	inc a
	sta t3f+3
	bcc t3n
	inc t3f+2
	inc t3f+4
t3n:	dex
	bne t3f
	rts

band_row:	tma #4
	pha
	lda #BANDT
	tam #4
	ldy rows
	lda WROW,y
	sta t0
	lda WROWH,y
	sta t1
br_a:	lda FRAMES
	sta uf
	vsel 0
	lda OP_MAWRLO
	sta $0002
	lda OP_MAWRHI
	sta $0003
	vsel 2
	lda t0
	sta br_t+1
	lda t1
	sta br_t+2
br_t:	tia WIN, $0002, 32
	lda br_t+1
	clc
	adc #32
	sta br_t2+1
	lda br_t+2
	adc #0
	sta br_t2+2
br_t2:	tia WIN + 32, $0002, 34
	lda FRAMES
	cmp uf
	bne br_a
	inc rows
	lda rows
	cmp #16
	bne br_x
	.if PROF
	lda $0C00
	sta tpd
	.endif
	jsr band_mix
	lda nwfull              ; (a column-change pass has no time for group uploads: the next pass takes them)
	bne *+5
	jsr bu_c5
	.if PROF
	lda $0C00
	sta tpu
	.endif
br_x:	pla
	tam #4
	clc
	rts

; after the pass's rows: this pass's mixes composed into their VRAM tiles (MIXBASE + mset + i): per job the near-end part
; (BANDN at MPR3) or'ed over the under's image masked to the pixels the near leaves (the far's from FT, BANDF at MPR4; a mid
; pair's from its MPB bank at MPR4). The job is copied out of MJ first (its bank leaves MPR3).
band_mix:	tma #3
	pha
	tma #4
	pha
	lda nmix
	bne *+5
	jmp bm_x
	stz t3                  ; job i
bm_l:	lda #T3
	tam #3
	ldx t3
	lda MJ_E,x
	sta srcb
	lda MJ_P,x
	sta srcb+1
	lda MJ_LO,x
	sta bm_u1+1
	sta bm_u2+1
	sta bm_u3+1
	sta bm_u4+1
	sta .bm_ftia+1
	lda MJ_HI,x
	sta bm_u1+2
	sta bm_u2+2
	sta bm_u3+2
	sta bm_u4+2
	sta .bm_ftia+2
	lda MJ_T,x
	sta srcb+3
	lda MJ_BNK,x
	sta srcb+2
	cmp #$FF
	beq .bm_live
	cmp #$73
	bcc .bm_live
	tam #3
	lda srcb+3              ; VDC MAWR = the job's tile ($600 + MJ_T) * 16
	asl a
	asl a
	asl a
	asl a
	sta t1
	lda srcb+3
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #$60
	sta t0
.bm_fa:	lda FRAMES
	sta uf
	vsel 0
	lda t1
	sta $0002
	lda t0
	sta $0003
	vsel 2
.bm_ftia:
	tia $6000, $0002, 32
	lda FRAMES
	cmp uf
	bne .bm_fa
	jmp bm_next
.bm_live:
	lda srcb
	and #$7F
	tax
	lda NE384L,x
	sta t2
	lda NE384H,x
	sta t1
	lda srcb
	bpl bm_s0
	lda t2                  ; + 192
	clc
	adc #192
	sta t2
	bcc bm_s0
	inc t1
bm_s0:	lda srcb+1
	and #1
	beq bm_p0
	lda t2                  ; + 96
	clc
	adc #96
	sta t2
	bcc bm_p0
	inc t1
bm_p0:	lda srcb+1              ; + 32 (pn - 1)
	lsr a
	dec a
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc t2
	sta bm_n1+1
	sta bm_n2+1
	sta bm_n3+1
	sta bm_n4+1
	lda t1
	adc #$60
	sta bm_n1+2
	sta bm_n2+2
	sta bm_n3+2
	sta bm_n4+2
	lda srcb+1              ; the mask: the under keeps the pixels the part leaves: side 0 the right 2 pn, side 1 the left 8 - 2 pn
	lsr a
	tax
	lda bm_mr,x
	bit srcb
	bpl *+4
	eor #$FF
	sta pb0
	lda srcb+2              ; the under's bank at MPR4 (FT: BANDF)
	cmp #$FF
	bne *+4
	lda #BANDF
	tam #4
	lda #BANDN
	tam #3
	lda srcb+3              ; VDC MAWR = the job's tile ($600 + MJ_T) * 16
	asl a
	asl a
	asl a
	asl a
	sta t1
	lda srcb+3
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #$60
	sta t0
bm_a:	lda FRAMES
	sta uf
	vsel 0
	lda t1
	sta $0002
	lda t0
	sta $0003
	vsel 2
	cly
bm_c:
bm_u1:	lda $8000,y
	and pb0
bm_n1:	ora $6000,y
	sta $0002
	iny
bm_u2:	lda $8000,y
	and pb0
bm_n2:	ora $6000,y
	sta $0003
	iny

bm_u3:	lda $8000,y
	and pb0
bm_n3:	ora $6000,y
	sta $0002
	iny
bm_u4:	lda $8000,y
	and pb0
bm_n4:	ora $6000,y
	sta $0003
	iny
	cpy #32
	bne bm_c
	lda FRAMES
	cmp uf
	bne bm_a
bm_next:
	inc t3
	lda t3
	cmp nmix
	beq bm_x
	jmp bm_l
bm_x:	pla
	tam #4
	pla
	tam #3
	rts
bm_mr:	.db 0, $03, $0F, $3F
NE384L:	.db $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00, $80, $00
NE384H:	.db $00, $01, $03, $04, $06, $07, $09, $0A, $0C, $0D, $0F, $10, $12, $13, $15, $16, $18, $19, $1B, $1C, $1E
PBNK:	.db 0, $73, $75, $76
PBNK_B:	.db 0, $7A, $7B, $7C
cslot:	.db 0
ces:	.db 0
coff_hi: .db 0

bu_c5:	cla                     ; band_upl, in the fourth code area
	ldx #C5BANK
	jmp callx

b_negen:
	lda t2
negen:	ldx nne
	cpx #NEMAX
	bcc ng_ok
	lda #$FF
	rts
ng_ok:	sta t2                  ; the code
	tax
	lda nne
	sta NEIDX,x
	inc nne
	sta ng_e                ; e
	lda t2
	clc
	adc nlo
	ldy nhi
	bcc *+3
	iny
	clx
	jsr rdtile              ; the tile's planes into srca
	ldx ng_e
	lda NE384L,x
	sta ng_d+1
	lda NE384H,x
	clc
	adc #$60
	sta ng_d+2
	lda #BANDN
	tam #3
	stz ng_pal
ng_pl:	lda #<nmap0
	ldy ng_pal
	beq *+4
	lda #<nmap1
	sta ng_mp+1
	lda #>nmap0
	sta ng_mp+2
ng_m1:	cly                     ; y = row * 2
ng_r:	lda srca,y
	sta pb0
	lda srca+1,y
	sta pb1
	lda srca+16,y
	sta pb2
	lda srca+17,y
	sta pb3
	ldx #8
ng_x:	cla                     ; the pixel's index from the four planes' top bits
	asl pb3
	rol a
	asl pb2
	rol a
	asl pb1
	rol a
	asl pb0
	rol a
	phx
	tax
ng_mp:	lda nmap0,x             ; -> the merged index, its bits into the output planes
	plx
	lsr a
	rol ob0
	lsr a
	rol ob1
	lsr a
	rol ob2
	lsr a
	rol ob3
	dex
	bne ng_x
	lda ob0
	sta srcb,y
	lda ob1
	sta srcb+1,y
	lda ob2
	sta srcb+16,y
	lda ob3
	sta srcb+17,y
	iny
	iny
	cpy #16
	bne ng_r
	ldx #1                  ; the three phases, two sides: NE images
ng_ph:	txa                     ; SHL page: SHT + 1024 pn; SHR + 256
	asl a
	asl a
	clc
	adc #>SHT
	sta ng_sl+2
	inc a
	sta ng_sr+2
	cly
ng_c:	phx
	ldx srcb,y
ng_sl:	lda SHT,x
ng_d:	sta $6000,y             ; side 0, this pal, this phase (+ 192 for side 1)
	ldx srcb,y
ng_sr:	lda SHT + 256,x
	pha
	lda ng_d+1
	clc
	adc #192
	sta ng_d2+1
	lda ng_d+2
	adc #0
	sta ng_d2+2
	pla
ng_d2:	sta $6000,y
	plx
	iny
	cpy #32
	bne ng_c
	lda ng_d+1              ; the next phase: + 32
	clc
	adc #32
	sta ng_d+1
	bcc *+5
	inc ng_d+2
	inx
	cpx #4
	bne ng_ph
	lda ng_pal
	bne ng_x2
	inc ng_pal
	jmp ng_pl
ng_x2:	lda #BANDT
	tam #4
	lda ng_e
	rts
ng_pal:	.db 0
ng_e:	.db 0
wsv:	.db 0           ; (cpos) the band's set-up state to go on with after a window (0-2)

b_exit:	stz gqh
	stz gqt
	stz gover
	stz gqp
	stz pw_state
	rts

cpos:	jsr cmotion
	lda pw_state
	cmp #5
	bne .w0
	lda MENU
	ora wsd
	bne camhand
	lda wsv
	sta pw_state
	bra camhand
.w0:	lda MENU
	bne .w1
	stz mign
	bra camhand
.w1:	lda mign
	bne camhand
	lda act
	cmp #2
	beq .w2
	lda vxok
	beq camhand
.w2:	jsr sprest              ; (act 1 with a run held, never seen: slice 1 stands down too, and takes back on an aligned pass)
	stz act
	lda pw_state
	cmp #3
	bcc .w3
	lda #2
.w3:	sta wsv
	jsr b_exit
	lda #5
	sta pw_state
	inc wsd
camhand:	lda CAMX
	clc
	adc #16
	sta hcl
	lda CAMX+1
	adc #0
	sta hch
	rts
cmotion:	lda CAMX
	cmp camlo
	bne .mv
	lda CAMX+1
	cmp camhi
	beq .st
.mv:	lda CAMX
	cmp camlo
	lda CAMX+1
	sbc camhi
	lda #1
	bcs .dr
	lda #$FF
.dr:	sta ldir
	lda CAMX
	sta camlo
	lda CAMX+1
	sta camhi
.st:	rts

; ---------------------------------------------------------------- the edge-key windows: slice 1's look-ahead (callb 24; its readiness gate, w3rdy2, is in the second code sector)
c4end:
	.if (c4end > $E000)
	.fail
	.endif

	.bank 4
	.org C5ORG
c5jt:	jmp band_upl            ; 0 (then mcomp)
	jmp midwalk
	jmp wpick5              ; 6: the next edge-key window to scan (escan)
	jmp vxall               ; 9: the borrowed runs: Y = 0 copied out of VRAM, 1 put back
	jmp midsetup            ; 12: band_init: the band's mid pairs, their tiles' patterns
	jmp recols
	jmp wsdo                ; 18: (qidle, through bandjt 27) a window over the band: every borrowed run back
	jmp didle
	jmp ssfill              ; 24: the set-up's tables filled (ss_fill)
	jmp dpass               ; 27: a new pass (rowdraw): the dark set-up's request
	jmp sp4c

PAI        = $D800
PBI        = $D840
TPC        = $D880      ; per pattern index (40 at most; 35 in band 1): the mid tile's code
BMS        = $D8B0      ; per row 13-15 (32 bytes a row) and mid column BMC0 + c: the pair starting there, $FF none
TPAT       = $D920      ; per pattern index: the tile's 32 bytes (from VRAM, mcomp) ($D920-$DE1F; $DE40-$DEFF: two mid groups' copy)
BMC0       = 40         ; the first mid column of the band's table (the band's window starts at 41)
BMCN       = 26         ; ... columns scanned (40-65: the mid map's last column is 65)
MGN        = 45         ; mid groups (MGL / MGH)
MCSTEP     = 12
MRSTEP     = 12

band_upl:	tma #3
	pha
	tma #4
	pha
	lda #BANDT
	tam #4
bugm:	lda #GUPMAX
	sta t3
bu_l:	lda gqh
	cmp gqt
	bne *+5
	jmp bu_x
	tay
	lda GQ,y                ; the slot
	tax
	lda GSLOT,x
	cmp #$FF
	bne *+5
	jmp bu_skip             ; (freed while queued)
	ldy gqp                 ; (the head part-done for another group, freed and taken again since: from its first tile)
	beq bu_g0
	cmp gqg
	beq bu_g1
	stz gqp
bu_g0:	sta gqg
bu_g1:	sta t2                  ; g
	txa
	stz t0
	asl a
	rol t0
	asl a
	rol t0
	asl a
	rol t0
	asl a
	rol t0
	asl a
	rol t0
	sta bu_t+1
	lda t0
	clc
	adc #$60
	sta bu_t+2
	lda gqp
	clc
	adc #NPB + 1
	tam #3
	ldy t2                  ; destination: (the group's first tile - 1 + 1 + gqp) * 16
	lda GVH,y
	sta t0
	lda GVL,y
	sec
	adc gqp
	bcc *+5
	inc t0
	asl a
	rol t0
	asl a
	rol t0
	asl a
	rol t0
	asl a
	rol t0
	sta t1
bu_a:	lda FRAMES
	sta uf
	vsel 0
	lda t1
	sta $0002
	lda t0
	sta $0003
	vsel 2
bu_t:	tia $6000, $0002, 32
	lda FRAMES
	cmp uf
	bne bu_a
	inc ngup                ; (quarry-spire-fix: 8 bits now, no tool reads it: 3 bytes for c5jt's entry 30; the same cycles while
	bne *+2                 ; the low byte does not wrap)
	inc gqp
	lda gqp
	cmp #3
	bne bu_c
	lda #1                  ; (X: the slot)
	sta GREADY,x
bu_skip:	stz gqp
	lda gqh
	inc a
	and #127
	sta gqh
bu_c:	dec t3
	beq bu_x
	jmp bu_l
bu_x:	pla
	tam #4
	pla
	tam #3
	jmp cmu_r
gqg:	.db 0           ; the group the head's gqp tiles went to

; a step of the mid groups' composition: MCSTEP images (pair mci, phase 2 mcph), SHL[d] of the left tile | SHR[d] of the right straight
; to the group's tile; mready when every pair is in
mcomp:	lda act                 ; (in the band's passes only: in the idle before the take-over its cost added a lost frame at 628)
	cmp #2
	beq *+5
	jmp mc_x
	lda mready
	beq *+5
	jmp mc_x
	tma #4
	pha
	lda #SHBANK
	tam #4
	lda #MCSTEP
	sta mcc
	lda msr                 ; first the pair table, a row a step
	cmp #3
	bcs mc_n
	jsr ms_row
	jmp mc_e
mc_n:	lda mpt                 ; then the tiles' patterns from VRAM (TPAT), then the groups
	cmp ntile
	bcs mc_g
	tax
	lda TPC,x
	clc
	adc mlo
	sta mul
	lda mhi
	adc #0
	and #$07
	sta muh
	jsr mu_16
	lda mpt
	jsr mu_pa
	sta mc_rd+3
	stx mc_rd+4
mc_ra:	lda FRAMES              ; (no SEI: a vblank in the middle reads it again)
	sta uf
	vsel 1
	lda mul
	sta $0002
	lda muh
	sta $0003
	vsel 2
mc_rd:	tai $0002, TPAT, 32
	lda FRAMES
	cmp uf
	bne mc_ra
	inc mpt
	jmp mc_c
mc_g:	lda mci
	cmp npair
	bcc mc_go
	inc mready
	jmp mc_e
mc_go:	tay
	lda mcph                ; (a group's first image: its three tiles copied out first: mgcopy)
	cmp #1
	bne mc_go2
	cly
	jsr mgxfer
	inc mcop
	ldy mci
mc_go2:
	lda PAI,y
	jsr mu_pa
	sta mc_a1+1
	sta mc_a2+1
	stx mc_a1+2
	stx mc_a2+2
	lda PBI,y
	jsr mu_pa
	sta mc_b1+1
	sta mc_b2+1
	stx mc_b1+2
	stx mc_b2+2
	lda mcph
	asl a
	asl a
	clc
	adc #$80
	sta mc_s1+2
	sta mc_s2+2
	inc a
	sta mc_r1+2
	sta mc_r2+2
	lda MGL,y               ; the tile: the group's first + ph - 1, * 16
	clc
	adc mcph
	sta mul
	lda MGH,y
	adc #0
	sta muh
	lda mul
	sec
	sbc #1
	sta mul
	bcs *+5
	dec muh
	asl a
	rol muh
	asl a
	rol muh
	asl a
	rol muh
	asl a
	rol muh
	sta mul
mu_a:	lda FRAMES
	sta uf
	vsel 0
	lda mul
	sta $0002
	lda muh
	sta $0003
	vsel 2
	cly
mc_l:
mc_a1:	ldx TPAT,y
mc_s1:	lda $8000,x
mc_b1:	ldx TPAT,y
mc_r1:	ora $8100,x
	sta $0002
	iny
mc_a2:	ldx TPAT,y
mc_s2:	lda $8000,x
mc_b2:	ldx TPAT,y
mc_r2:	ora $8100,x
	sta $0003
	iny
	cpy #32
	bne mc_l
	lda FRAMES
	cmp uf
	bne mu_a
	inc mcph
	lda mcph
	cmp #4
	bne mc_c
	lda #1
	sta mcph
	inc mci
mc_c:	dec mcc
	beq mc_e
	jmp mc_n
mc_e:	pla
	tam #4
mc_x:	rts
mu_16:	lda mul                 ; muh:mul * 16
	asl a
	rol muh
	asl a
	rol muh
	asl a
	rol muh
	asl a
	rol muh
	sta mul
	rts
; group mci's three tiles (Y = 0) copied out of VRAM to its store, (Y = 1) put back; a tile at a time, a vblank in the middle repeats it
mgxfer:	sty vxd
	tma #3
	pha
	ldx mci
	lda MSBK,x
	tam #3
	lda MSAL,x
	sta mg_c+3
	sta mg_w+1
	lda MSAH,x
	sta mg_c+4
	sta mg_w+2
	lda MGL,x
	sta mul
	lda MGH,x
	sta muh
	jsr mu_16
	lda #3
	sta vxn
mg_t:	lda FRAMES
	sta uf
	lda vxd                 ; MARR (1) to read, MAWR (0) to write
	eor #1
	sta <VDCREG
	sta $0000
	lda mul
	sta $0002
	lda muh
	sta $0003
	vsel 2
	lda vxd
	bne mg_w
mg_c:	tai $0002, $6000, 32
	bra mg_k
mg_w:	tia $6000, $0002, 32
mg_k:	lda FRAMES
	cmp uf
	bne mg_t
	lda mul
	clc
	adc #16
	sta mul
	bcc *+5
	inc muh
	lda mg_c+3
	clc
	adc #32
	sta mg_c+3
	sta mg_w+1
	bcc *+8
	inc mg_c+4
	inc mg_w+2
	dec vxn
	bne mg_t
	pla
	tam #3
	rts
mu_pa:	stz mut                 ; A = a pattern index: A = TPAT + 32 index low, X high
	asl a
	rol mut
	asl a
	rol mut
	asl a
	rol mut
	asl a
	rol mut
	asl a
	rol mut
	clc
	adc #<TPAT
	pha
	lda mut
	adc #>TPAT
	tax
	pla
	rts

; this pass's mid words, rows 13-15, screen columns 0-31 (32: under the frame's border): a cell no near tile covers (or a B-only near
; end at near phase 0: its under shows) gets: a band pair (kind 1 or 4) its group's tile at phase dm & 6 once the groups are composed
; (the tile A at phase 0 or before); kinds 2 / 3 (a run's end over far) the end's whole tile or the far word, whichever covers more of
; it (kind 2: A while dm < 4; kind 3: its tile from dm 4). Skipped when nothing changes (same even phase, no column change, near
; phase not 0).
midwalk:	lda card
	beq mwk0
	jmp cwalk_r
mwk0:	lda dm
	lsr a
	ldx mready
	bne *+3
	cla
	sta mwq2                ; (the phase index shown: 0 until the groups are in)
	lda dm                  ; (the ends' choice)
	and #4
	ora mwq2
	cmp mwq
	bne mw_go
	lda nwfull
	bne mw_go
	lda mwq2
	beq mw_rts0
	lda pn
	beq mw_go
mw_rts0:	rts
mw_go:	lda dm                  ; (the key again: A was overwritten on the way)
	and #4
	ora mwq2
	sta mwq
	lda mhi
	and #$F0
	sta mwpal
	lda #2
	sta mwr
mw_r:	ldx mwr
	lda MWNL,x
	sta mw_np+1
	lda MWNH,x
	sta mw_np+2
	lda MWML,x
	sta mw_mp+1
	sta mw_ma+1
	lda MWMH,x
	sta mw_mp+2
	inc a
	sta mw_ma+2
	lda MWWL,x
	sta mw_w1+1
	sta mw_w2+1
	sta mw_f1+1
	sta mw_f2+1
	lda MWWH,x
	sta mw_w1+2
	sta mw_w2+2
	clc
	adc #>(FW - WIN)
	sta mw_f1+2
	sta mw_f2+2
	txa                     ; the pair table's row: BMS + 32 r + cm - BMC0
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc cm
	clc
	adc #<(BMS - BMC0)
	sta mw_ms+1
	lda #>(BMS - BMC0)
	adc #0
	sta mw_ms+2
	ldy #31
mz_l:
mw_np:	lda NP,y
	beq mw_ok
	cmp #3
	bne mw_n
	lda pn
	bne mw_n
mw_ok:
mw_mp:	lda MP,y
	beq mw_n
	cmp #2
	beq mw_k2
	cmp #3
	bne mw_p
	lda dm                  ; kind 3: its tile from dm 4
	cmp #4
	bcs mw_ma
	bra mw_f
mw_k2:	lda dm                  ; kind 2: A while dm < 4
	cmp #4
	bcc mw_ma
mw_f:	tya
	asl a
	tax
mw_f1:	lda FW,x
	sta mwlo
	inx
mw_f2:	lda FW,x
	sta mwhi
	bra mw_wr
mw_n:	dey
	bpl mz_l
	dec mwr
	bmi mw_rts
	jmp mw_r
mw_rts:	rts
mw_ma:	lda MA,y
	clc
	adc mlo
	sta mwlo
	lda mhi
	adc #0
	sta mwhi
	bra mw_wr
mw_p:	lda mwq2                ; a pair (kinds 1, 4): phase 0 (or not yet composed): its tile A
	beq mw_ma
mw_ms:	lda BMS,y
	cmp #$FF
	beq mw_ma               ; (not a band pair: the whole tile)
	tax
	lda MGL,x               ; the group's first tile - 1 + the phase index
	clc
	adc mwq2
	sta mwlo
	lda MGH,x
	adc #0
	sta mwhi
	lda mwlo
	bne *+5
	dec mwhi
	dec mwlo
	lda mwhi
	ora mwpal
	sta mwhi
mw_wr:	tya
	asl a
	tax
	lda mwlo
mw_w1:	sta WIN,x
	inx
	lda mwhi
mw_w2:	sta WIN,x
	bra mw_n

vxall:	sty vxd
	lda vxph                ; (a restore under way: only its next mid groups)
	beq *+5
	jmp vxa_mg
	tma #3
	pha
	clx
vxa_e:	stx vxe
	lda VXRT + 3,x
	tam #3
	lda VXRT + 4,x
	sta vxa_c+3
	sta vxa_w+1
	lda VXRT + 5,x
	sta vxa_c+4
	sta vxa_w+2
	lda VXRT,x
	sta vxl
	lda VXRT + 1,x
	sta vxh
	lda VXRT + 2,x
	sta vxn
vxa_t:	lda FRAMES
	sta uf
	lda vxd                 ; MARR (1) to read, MAWR (0) to write
	eor #1
	sta <VDCREG
	sta $0000
	lda vxl
	sta $0002
	lda vxh
	sta $0003
	vsel 2
	lda vxd
	bne vxa_w
vxa_c:	tai $0002, $7700, 32
	bra vxa_k
vxa_w:	tia $7700, $0002, 32
vxa_k:	lda FRAMES
	cmp uf
	bne vxa_t
	lda vxl
	clc
	adc #16
	sta vxl
	bcc *+5
	inc vxh
	lda vxa_c+3
	clc
	adc #32
	sta vxa_c+3
	sta vxa_w+1
	bcc *+8
	inc vxa_c+4
	inc vxa_w+2
	dec vxn
	bne vxa_t
	lda vxe
	clc
	adc #6
	tax
	cpx #6 * 2              ; (copied out: the first two runs; put back: the third too, from set 1's copy, which ss_far's capt made)
	bne vxa_j
	lda vxd
	beq vxa_o
vxa_j:	cpx #6 * 3
	beq *+5
	jmp vxa_e
vxa_o:	pla
	tam #3
	lda vxd                 ; put back: then the mid groups copied so far, MRSTEP a call ($680-$70D, $772-$7FF: set 0 / set 1's restore)
	beq vxa_x
	jsr ores_r
	inc vxph
	inc vxok
vxa_x:	rts                     ; (the mid groups from the next call on: an idle each, MRSTEP at a time)
vxa_mg:	lda mci                 ; up to MRSTEP mid groups put back from their copies; vxok set again while any is left (vxrest calls
	pha                     ; again: the next idle, or at once in leave / qho's loops)
	lda #MRSTEP
	sta vxn2
vxa_m:	lda mcop
	beq vxa_m2
	dec mcop
	lda mcop
	sta mci
	ldy #1
	jsr mgxfer
	dec vxn2
	bne vxa_m
vxa_m2:	pla
	sta mci
	lda mcop
	beq vxa_d
	inc vxok
	rts
vxa_d:	stz vxph
	stz mready              ; (compose again at the next entry)
	rts
VXRT:	.dw VXT0 * 16            ; the groups' run
	.db VXG * 3, BANDF
	.dw $7700
	.dw MIXX * 16
	.db 4, $7F
	.dw $7E40
	.dw $70E * 16
	.db 100, $7F
	.dw $6000 + 142 * 32

wsdo:	stz wsd
	inc nwin
	lda FRAMES
.v:	cmp FRAMES
	beq .v
.r:	lda vxok
	beq .d
	stz vxok
	ldy #1
	jsr vxall
	bra .r
.d:	sec
	rts

MSBK:	.db NPB + 2, NPB + 2, NPB + 2, NPB + 2, NPB + 2, NPB + 2, NPB + 2, NPB + 2, NPB + 2, NPB + 2 ; per mid group: its copy's bank, address at MPR3
	.db C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK
	.db C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK, C5BANK
	.db BANDF, BANDF, BANDF, BANDF, BANDF, BANDF
	.db BANDF, BANDF, BANDF, BANDF, BANDF, BANDF
	.db C5BANK, C5BANK, C5BANK, C5BANK
MSA0 = $7100            ; (NPB + 2 at MPR3: its tail past the 136 near images, never written by the image store (ibt) or anything else in 17)
MSA1 = $6800
MSA3 = $7B80
MSA5 = $6F20
MSA6 = $7E40
MSAL:	.db <(MSA0), <(MSA0 + 96), <(MSA0 + 192), <(MSA0 + 288), <(MSA0 + 384), <(MSA0 + 480), <(MSA0 + 576), <(MSA0 + 672), <(MSA0 + 768), <(MSA0 + 864)
	.db <(MSA1), <(MSA1 + 96), <(MSA1 + 192), <(MSA1 + 288), <(MSA1 + 384), <(MSA1 + 480), <(MSA1 + 576), <(MSA1 + 672), <(MSA1 + 768), <(MSA1 + 864)
	.db <(MSA1 + 960), <(MSA1 + 1056), <(MSA1 + 1152), <(MSA1 + 1248), <(MSA1 + 1344), <(MSA1 + 1440), <(MSA1 + 1536), <(MSA1 + 1632), <(MSA1 + 1728)
	.db <(MSA3), <(MSA3 + 96), <(MSA3 + 192), <(MSA3 + 288), <(MSA3 + 384), <(MSA3 + 480)
	.db <(MSA3 + 576), <(MSA3 + 672), <(MSA3 + 768), <(MSA3 + 864), <(MSA3 + 960), <(MSA3 + 1056)
	.db <(MSA5), <(MSA5 + 96), <(MSA6), <(MSA6 + 96)
MSAH:	.db >(MSA0), >(MSA0 + 96), >(MSA0 + 192), >(MSA0 + 288), >(MSA0 + 384), >(MSA0 + 480), >(MSA0 + 576), >(MSA0 + 672), >(MSA0 + 768), >(MSA0 + 864)
	.db >(MSA1), >(MSA1 + 96), >(MSA1 + 192), >(MSA1 + 288), >(MSA1 + 384), >(MSA1 + 480), >(MSA1 + 576), >(MSA1 + 672), >(MSA1 + 768), >(MSA1 + 864)
	.db >(MSA1 + 960), >(MSA1 + 1056), >(MSA1 + 1152), >(MSA1 + 1248), >(MSA1 + 1344), >(MSA1 + 1440), >(MSA1 + 1536), >(MSA1 + 1632), >(MSA1 + 1728)
	.db >(MSA3), >(MSA3 + 96), >(MSA3 + 192), >(MSA3 + 288), >(MSA3 + 384), >(MSA3 + 480)
	.db >(MSA3 + 576), >(MSA3 + 672), >(MSA3 + 768), >(MSA3 + 864), >(MSA3 + 960), >(MSA3 + 1056)
	.db >(MSA5), >(MSA5 + 96), >(MSA6), >(MSA6 + 96)

MGL:	.db <$5A0, <$5A3, <$5A6, <$5A9, <$5AC, <$5AF, <$5B2, <$5B5, <$5B8, <$5BB
	.db <$5E0, <$5E3, <$5E6, <$5E9, <$5EC, <$5EF, <$5F2, <$5F5, <$5F8, <$5FB
	.db <$607, <$60A, <$60D, <$610, <$613, <$616, <$619, <$61C, <$61F
	.db <$628, <$62B, <$62E, <$631, <$634, <$637
	.db <$63D, <$640, <$643, <$646, <$649, <$64C
	.db <$64F, <$652, <$655, <$658
MGH:	.db >$5A0, >$5A3, >$5A6, >$5A9, >$5AC, >$5AF, >$5B2, >$5B5, >$5B8, >$5BB
	.db >$5E0, >$5E3, >$5E6, >$5E9, >$5EC, >$5EF, >$5F2, >$5F5, >$5F8, >$5FB
	.db >$607, >$60A, >$60D, >$610, >$613, >$616, >$619, >$61C, >$61F
	.db >$628, >$62B, >$62E, >$631, >$634, >$637
	.db >$63D, >$640, >$643, >$646, >$649, >$64C
	.db >$64F, >$652, >$655, >$658
MWNL:	.db <(NP + 33 * 13), <(NP + 33 * 14), <(NP + 33 * 15)
MWNH:	.db >(NP + 33 * 13), >(NP + 33 * 14), >(NP + 33 * 15)
MWML:	.db <(MP + 33 * 3), <(MP + 33 * 4), <(MP + 33 * 5)
MWMH:	.db >(MP + 33 * 3), >(MP + 33 * 4), >(MP + 33 * 5)
MWWL:	.db <(WIN + 66 * 13), <(WIN + 66 * 14), <(WIN + 66 * 15)
MWWH:	.db >(WIN + 66 * 13), >(WIN + 66 * 14), >(WIN + 66 * 15)

midsetup:	lda vxph                ; (a restore of the mid groups still under way from a stand-down: finished first, their copies
	beq ms_go               ; are taken again below)
	ldy #1
	jsr vxall
	bra midsetup
ms_go:	lda #1                  ; (the near groups' run counts as copied: bi_cam found it so or copied it)
	sta vxok
	tma #3
	pha
	lda ssb6
	tam #3
	lda #$FF
	sta BMS
	tii BMS, BMS + 1, 31
	tii BMS + 31, BMS + 32, 32
	tii BMS + 63, BMS + 64, 32
	stz npair
	stz ntile
	stz mready
	stz mci
	stz mpt
	lda #1
	sta mcph
	lda #$FF
	sta mwq
	stz msr
	stz msc
	pla
	tam #3
	rts
; one row of the pair table (msr: rows 13 + msr), a call (mcomp's first three steps: about 25k cycles each, in the band's passes)
ms_row:	tma #3
	pha
	lda ssb6
	tam #3
	lda msc                 ; (half a row a call: 13 columns, about 12k cycles)
	bne ms_c
ms_r:	lda msr
	clc
	adc #>$7D00             ; row 13 + r of the mid map
	sta ms_a+2
	sta ms_b+2
	lda #BMC0
	sta ms_a+1
	inc a
	sta ms_b+1
	stz msc
ms_c:
ms_a:	lda $7D00
	beq ms_n
	jsr ftile
	sta mia
ms_b:	lda $7D00
	beq ms_n
	jsr ftile
	sta mib
	clx                     ; the pair: found or added
ms_p:	cpx npair
	beq ms_pa
	lda PAI,x
	cmp mia
	bne ms_pn
	lda PBI,x
	cmp mib
	beq ms_pf
ms_pn:	inx
	bra ms_p
ms_pa:	cpx #MGN
	beq ms_n                ; (full: whole tiles)
	lda mia
	sta PAI,x
	lda mib
	sta PBI,x
	inc npair
ms_pf:	lda msr
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc msc
	tay
	txa
	sta BMS,y
ms_n:	inc ms_a+1
	inc ms_b+1
	inc msc
	lda msc
	cmp #BMCN / 2
	beq ms_x
	cmp #BMCN
	beq *+5
	jmp ms_c
	inc msr
	stz msc
ms_x:	pla
	tam #3
	rts
; A = a mid tile's code: its pattern index (added if new; 40 at most, then the last)
ftile:	ldx #0
ft_l:	cpx ntile
	beq ft_a
	cmp TPC,x
	beq ft_f
	inx
	bra ft_l
ft_a:	cpx #40
	beq ft_f
	sta TPC,x
	inc ntile
ft_f:	txa
	rts

npair:	.db 0
ntile:	.db 0
msr:	.db 0
msc:	.db 0
mia:	.db 0
mib:	.db 0
mready:	.db 0
mpt:	.db 0
mcop:	.db 0
mci:	.db 0
mcph:	.db 0
mcc:	.db 0
mwq:	.db 0
mwq2:	.db 0
mwr:	.db 0
mwpal:	.db 0
mwlo:	.db 0
mwhi:	.db 0
mut:	.db 0
mul:	.db 0
muh:	.db 0
vxd:	.db 0
vxe:	.db 0
vxl:	.db 0
vxh:	.db 0
vxn:	.db 0
vxn2:	.db 0
vxph:	.db 0
c5end:
	.if (c5end > PAI)
	.fail
	.endif

RAORG      = $C000
	.org RAORG
didle:	lda ss                  ; (quarry-bridge-store: from ssrun's end, the edge keys' step: the bridge's store's slice)
	cmp #SSE
	beq bslice
	lda dks                 ; (idlework's one call: the dark set-up when asked for, else the band's idle)
	bne dstz
	lda act
	beq .c
	cmp #2
	bne .n
	lda card
	cmp #1
	bne .n
	lda CAMX
	cmp bsc
	sta bsc
	bne .n
di_bn      = * - 1          ; (quarry-seams: 0 once the seams' image is in, sinit: cidle is pgfast then, i.e. its idle)
	phy
	jsr cidle
	ply
.n:	lda act
	clc
	rts
.c:	jmp cidle
bsc:	.db 0
bslice:	ldx cst
	cpx #5
bs_p5      = * - 1          ; (quarry-pregen-load: with the store loaded from the disc the preload makes these CPX #$80 / BPL: cidle, i.e.
bs_pb      = *              ; pgfast then, from the edge keys' idle whatever cst is, but $FF)
	bne .x
	lda brst
	bne .x
bs_br      = * - 1          ; (quarry-seams: 0 with the seams' image in, sinit: the edge keys' idle goes on to cidle, i.e. pgfast and sidle)
	lda <LOCKZP
	and #$18
bs_lk      = * - 1          ; (quarry-pregen-load: 0 with the store loaded from the disc: pgfast runs in a door's or a load's dark too; it
	bne .x                  ; waits for nothing)
	lda act
	bne .go
	lda CAMX
	tax
	eor bsc
	stx bsc
	beq .go
	txa
	and #15
	cmp #14
	beq .x
	cmp #2
	beq .x
	and #7
	beq .x
.go:	jsr cidle
	lda brst                ; (over in this slice: it did not wait)
	bne .x
	lda q8vf                ; the slice's own wait saw the vblank that just went by (else a step ran over: no stamp): the edge keys'
	cmp FRAMES
	bne .x
	dec a
	sta huf
	lda q8vb
	clc
	adc #41
	cmp #116
	bcc .h
	sbc #116
.h:	sta hut
.x:	rts
dstz:	stz card
	stz cst
	stz brst
	stz cvis                ; (the overlays of this visit are not in place yet: other modules write their banks)
	lda ctier
	beq .n
	stz ibt + 7
	lda #$20                ; (the idle's prewarm back in)
	jsr cpat
.n:	jsr vzero
	jmp dstall
vdark:	php
	sei
	lda #1
	sta $0402
	stz $0403
	ldx #15
.v:	lda $0404
	bne .n
	lda $0405               ; (the high byte reads 1-7 as ones: bit 0 only; the read moves the address on)
	lsr a
	bcs .n
	dex
	bne .v
.n:	plp
	txa
	rts
ctier:	.db 0
cvis:	.db 0
cvg:	.db 0
cvgn:	.db 0
centc:	.db 0
cload:	lda STUB_DGEN           ; (the stub's area generation: another module ran since, which may have written C6BANK)
	cmp cvg
	bne .new
	lda nsetup
	cmp cvgn
	beq centx
.new:	lda STUB_DGEN
	sta cvg
	lda nsetup
	sta cvgn
	stz cvis
	lda ctier
	beq centx
	jsr ccopy
	bne centx
	inc cvis
centx:	rts
ccopy:	lda #C6BANK
	tam #3
	stz $1A32               ; port 3 as the preload set it (a build cut short left it on its lists): base C6CH:0000, offset 0,
	stz $1A33               ; the offset added and auto-incremented
	lda #C6CH
	sta $1A34
	lda #3
	sta $1A39
	stz $1A35
	stz $1A36
	lda #<C6RAM             ; (32-byte pieces: an interrupt is taken between them)
	sta .c+3
	ldx #8                  ; (quarry-bridge-band2: its first page only, 6k cycles with the sum: the page's c6ld copies and checks the rest)
.c:	tai $1A30, C6RAM, 32
	lda .c+3
	clc
	adc #32
	sta .c+3
	dex
	bne .c
	clx
	cly
	cla
.l:	clc
	adc C6RAM,y
	bcc .n
	inx
.n:	iny
	bne .l
cs1l:	cmp #<C6SUM1
	bne ccx
cs1h:	cpx #>C6SUM1
ccx:	rts
c6sumw:	.dw (C6SUM - C6SUM1) & $FFFF   ; (the sum of the overlay's pages past the first: c6ld)
cent_sl    = c6sumw - 1
cent_sh    = c6sumw
cst:	.db 0
cidle:	lda ctier
	beq .x
	lda cst
	bmi .x
	lda pw_state
	cmp #4
	bne .v
	lda card
	cmp #1
	beq .v                  ; (the store ready: cst 5)
	jsr bhold
.v:	lda <LOCKZP
	and #$18
	bne .x
	lda cvis                ; the first overlay's first page of this visit (cload: once a set-up; 6k cycles)
	bne .c
	tma #3
	pha
	jsr cload
	pla
	tam #3
	lda cvis
	bne .x
	jmp cfail
.c:	ldx cst
	cpx #5
	bcs .b
	ldy CIV,x
	cpx #3
	beq .7
	jsr c6tr
	bra .a
.7:	jsr c7tr
.a:	bcc .x
	inc cst
.x:	rts
.b:	lda brst                ; (quarry-bridge-store) band 1's store ready: the bridge's store (region 1) built or found, a slice an idle
	bne .x                  ; (the third overlay's vector 0; brst 1: ready, $FF: given up for this visit)
	cly
	jsr c8tr
	bcc .x
	inc brst
	rts
CIV:	.db 26, 22, 2, 2, 24
bready:	lda #4
	sta pw_state
	lda ctier
	beq bhx
bhold:	lda #6
	sta pw_state
	lda #$80
	sta card
bhx:	rts
cfail:	lda #$FF
	sta cst
	stz cvis
	stz card
	lda pw_state
	cmp #6
	bne .x
	lda #4
	sta pw_state
.x:	clc
	rts
; a call into the overlay (callers test setok and call cload first: cvis): Y = 2 x the vector (c6jt); MPR3 saved and put back; A and the carry returned
c8tr:	ldx #C8BANK             ; (quarry-bridge-setup: the third overlay's vectors, c8jt)
	lda #>C8RAM
	bra c6t2
c7tr:	ldx #C7BANK             ; (the second overlay's vectors: c7jt)
	lda #>C7RAM
	bra c6t2
c6tr:	ldx #C6BANK
	lda #>C6RAM
c6t2:	sta .j+2
	sty .j+1
	tma #3
	pha
	txa
	tam #3
	jsr .j
	tay
	pla
	tam #3
	tya
	rts
.j:	jmp [C6RAM]
	.if PROOF
prfh:	lda ctier
	beq .x
	lda setok
	beq .x
	lda SCENE
	cmp #17
	bne .x
	tma #3
	pha
	jsr cload
	pla
	tam #3
	lda cvis
	beq .x
	ldy #14
	jmp c6tr
.x:	rts
	.endif
cwalk_r:	ldy #18
	jmp c6tr
ores_r:	lda cst                 ; (the odd set is out from the switch on: cst 4, 5)
	cmp #4
	bcc .x
	bmi .x
	ldy #20
	jmp c6tr
.x:	rts
vzero:	ldy #2
.p:	php
	sei
	lda mpalh,y
	sta $0402
	stz $0403
	ldx #16
.c:	stz $0404
	stz $0405
	dex
	bne .c
	plp
	dey
	bpl .p
	rts
; the idle prewarm's column step in C3 (A = JMP: out, the store replaces its mixes; JSR: back in, every set-up)
cpat:	tay
	tma #4
	pha
	lda #CBANK
	tam #4
	tya
	sta pwsite2 - $4000
	ldx #<bist1dn
	ldy #>bist1dn
	cmp #$4C
	beq .3
	ldx #<pw_one_col
	ldy #>pw_one_col
.3:	stx pwsite2 - $4000 + 1
	sty pwsite2 - $4000 + 2
	pla
	tam #4
	rts
	.include "quarry_card_res.inc"
raend:
	.if (raend > $C400)
	.fail
	.endif

; part; carried by the halt slot, so the boot's copy and any re-read of the slot put it there: mkdisc SBPIECE). Called with SBANK at MPR6
; (callx 21, 24), like the fourth code area.
	.org $C6D0
dpass:
	sty lastpf
	jsr $C400 + STUB_XE
	.if PROOF
	jsr prfh
	.endif
	lda FRAMES
	tay
	sec
	sbc pfr
	sty pfr
	ldy SCENE
	cpy #17
	bne .lt
	tst #$F8, <LOCKZP
	beq .lt
	ldy setok
	bne .g
	ldy ss
	beq .d
.g:	cmp #DGAP
	bcc .x
.d:	jsr vdark
	bne .x
	inc dkg
.x:	rts
.lt:	stz dkg
	rts
dstall:	stz dks
	inc dkin
	lda FRAMES
	sta dst0
	tma #3
	pha
	tma #4
	pha
.s:	jsr dsto
	bcs .x
	lda #1
	sta early
	jsr ssrun
	lda setok
	beq .s
.k:	jsr dsto
	bcs .x
	lda nsd                 ; (from the band's side: its groups' uploads and mid groups)
	bne .b
	jsr w3rdy               ; (carry clear: the keys of the windows A - 1 .. A + 1 made)
	bcc .x
	jsr kstep
	bra .k
.b:	lda pw_state
	cmp #3
	bne .x
	lda #2                  ; (mcomp composes in the band's passes only)
	sta act
.bl:	jsr dsto
	bcs .be
	lda #15                 ; band_upl, then a step of mcomp
	jsr callb
	lda gqh
	cmp gqt
	bne .bl
	lda mready
	beq .bl
	jsr bready
.be:	stz act
.x:	pla
	tam #4
	pla
	tam #3
	stz dkin
	lda MENU
	sta mign
	lda FRAMES              ; (the next pass's gap is not the unpack's)
	sta pfr
	rts
ssfill:	lda #4
	sta t2
.p:	ldx si
	cpx #24                 ; T1's pages $60-$77, then the chains and pool tables in T2
	bcs .t2
	txa
	clc
	adc #$60
	bra .pg
.t2:	lda fill_pg - 24,x
	beq .done
.pg:	sta .st+2
	lda #$FF
	ldy #0
.st:	sta $6000,y
	iny
	bne .st
	inc si
	dec t2
	bne .p
	lda #1
	rts
.done:	lda <PROPZP             ; the property table (128 bytes) into T2. The pointer as it stands now: at setbegin it can
	sta pp_r+1
	lda <PROPZP+1
	sec
	sbc #$20
	sta pp_r+2
	lda ssb4
	tam #3
	ldy #127
pp_r:	lda $FFFF,y
	sta prop,y
	dey
	bpl pp_r
	lda #T1
	tam #3
	jsr rbinit
	stz si
	stz sj
	jsr pooltab2
	lda #SSFAR
	sta ss
	lda #1
	rts
fill_pg:	.db >NFIRST, >MFIRST, >NPO, >MPO, >OWN, 0
; (quarry-pregen-load) the band path is band 1's again: passbegin's vector 3, handover's band test as it was (the stub bank at MPR6:
; the first overlay's bpos6, the fourth image's bp_gone)
brm0:	lda #3
	sta brm
	dec a                   ; (2: BLET + 1's high byte)
	sta ho_bh
	rts
	.if (>(BLET + 1)) != 2
	.fail
	.endif
sp4c:
	.if SPIRE
	lda di_bn
	bne .x
	ldy #10
	jmp c7tr
	.endif
.x:	rts

sbpend:
	.if (sbpend > $C800)
	.fail
	.endif

	.org $DF00
wpick5:	jsr wcam
	sta wq
	lda ldir
	dec a
	bne .z
	lda ssv
	cmp #SSGN
	beq .gn
	cmp #SSGM
	bne .z
	lda mk
	bra .r
.gn:	lda nk
	clc
	adc mk
.r:	sec
	sbc si
	lsr a
	lsr a
	lsr a
	clc
	adc wq
	cmp #WN
	bcc .s
	lda #WN - 1
.s:	sta wq
.z:
	cly
	lda act                 ; (drawing, or the dark set-up's keys: the camera's windows first)
	ora dkin
	bne .l
	ldy #8
.l:	lda wpo,y
	ldx ldir
	bpl .p
	eor #$FF
	inc a
.p:	clc
	adc wq
	cmp #WN
	bcs .n                  ; (outside the open quarry: -1 and -2 are $FF, $FE)
	tax
	lda wsc,x
	bne .n
	txa
	clc
	rts
.n:	iny
	tya
	and #7
	bne .l
	sec
	rts
recols:	stz t2                  ; row * 2
.r:	ldy t2
	lda srca,y
	sta r0
	lda srca+1,y
	sta r1
	lda srca+16,y
	sta r2
	lda srca+17,y
	sta r3
	ldx #8
	stx kk2
.p:	cla
	asl r3
	rol a
	asl r2
	rol a
	asl r1
	rol a
	asl r0
	rol a
	clc
	adc t3
	tax
	lda pmap - $2000,x      ; (T2 at MPR3 here)
	cmp #$FF
	bne .ok
	ldx kk2
	lda rbit - 1,x
	ora rbad
	sta rbad
	cla
.ok:	lsr a
	rol o0
	lsr a
	rol o1
	lsr a
	rol o2
	lsr a
	rol o3
	dec kk2
	bne .p
	ldy t2
	lda o0
	jsr rmst
	iny
	lda o1
	jsr rmst
	tya
	clc
	adc #15
	tay
	lda o2
	jsr rmst
	iny
	lda o3
	jsr rmst
	inc t2
	inc t2
	lda t2
	cmp #16
	beq .rd
	jmp .r
.rd:	rts
c6end:
	.if (c6end > $E000)
	.fail
	.endif

	.bank 5
	.org C6RAM
c6jt:	.dw cbase_v             ; 0: port 0's base = t0 / t1 / t2 (low, mid, high)
	.if PROOF
	.dw cwr32
	.dw ctile_v             ; 4: 32 bytes from port 0's base to VRAM word address t0 (low) / t1 (high), by one TIA through bank $40
	.else
	.dw c8ld
	.dw cprx
	.endif
	.if PROOF
	.dw cvbeg               ; 6: X = region: its header read and checked (carry clear: good so far), the sum started
	.dw cvstep              ; 8: A = pages of the payload summed (carry set: done; cvok 1 if the sum is right)
	.dw csbeg
	.dw csend               ; 12: X = region: its header written (after csbeg and cvstep)
	.else
	.dw cprx, cprx, cprx, cprx
	.endif
	.if PROOF
	.dw cprf                ; 14: a pass: the proof's step
	.else
	.dw cprx
	.endif
	.dw cmu6                ; 16: (quarry-bridge-setup; cmu_r) the band mid groups' even phases from the store
	.dw cpass
	.dw cores               ; 20: the odd set's borrowed tiles put back
	.dw c7ld
	.dw cswitch
	.dw c6ld
cvb:	.db 0
cvf:	.db 0
cq:	.db 0, 0
c6s:	.db 0           ; c6ld: 0 the copy, 1 the sum's pages
c6a:	.db 0
c6x:	.db 0
c6p:	.db 0
cclk:	sta cq + 1
	lda FRAMES
	cmp cvf
	bne cspin
	lda TIMER
	and #$7F
	sta cq
	lda cvb
	sec
	sbc cq
	bcs *+4
	adc #116
	clc
	adc cq + 1
	cmp #113
	bcs cspin
	sec
	rts
cspin:	lda FRAMES              ; (carry clear at the end)
	sta cq
.s:	lda TIMER
	and #$7F
	tax
	lda FRAMES
	cmp cq
	beq .s
	stx cvb
	sta cvf
	clc
	rts
c6ld:	lda #31                 ; (quarry-bridge-setup: 112 pieces, C6LEN $F00)
	jsr cclk
	bcs *+3
	rts
	lda c6s
	bne .sum
	stz $1A35
	lda #1
	sta $1A36
	ldx #(C6LEN - 256) / 32
.c:	tai $1A30, C6RAM + 256, 32
	lda .c+3
	clc
	adc #32
	sta .c+3
	bcc *+5
	inc .c+4
	dex
	bne .c
	stz $1A36
	lda #>(C6RAM + 256)     ; (the sum: pages 1 on; the first page, with these variables in it, was the resident's)
	sta c6p
	inc c6s
	bra .sp
.sum:	lda c6p
	sta .p+2
	lda #4
	sta cq + 1
	lda c6a
	ldx c6x
	cly
.l:	clc
.p:	adc C6RAM,y
	bcc .n
	inx
.n:	iny
	bne .l
	sta c6a
	inc .p+2
	lda .p+2
	cmp #>(C6RAM + C6LEN)
	beq .end
	lda c6a
	dec cq + 1
	bne .l
	stx c6x
	lda .p+2
	sta c6p
.sp:	jmp cspin
.end:	lda c6a
	cmp c6sumw
	bne .bad
	cpx c6sumw + 1
	bne .bad
	jmp c6fin               ; (quarry-pregen-load: past the first page, whose variables keep their places)
	nop
.x:	rts
.bad:	jmp cfail
c6p1end:
	.if (c6p1end > C6RAM + 256)
	.fail
	.endif
c6var:
cvok:	.db 0           ; the last region checked: 1 its header and sum are right
cvn:	.db 0, 0, 0     ; payload bytes left to sum
cvs:	.db 0, 0        ; the sum so far
chdr:	.ds 16
RGH:	.db $10, $11, $15, $16, $16
RGM:	.db $00, $00, $00, $00, $40
RGL:	.db $00, $00, $00, $00, $00
CFMT       = 1

cbase_v:	lda t0
	ldx t1
	ldy t2
cbase:	sta $1A02               ; A / X / Y = port 0's base, low / mid / high
	stx $1A03
	sty $1A04
	rts
	.if PROOF
cwr32:	tia srca, $1A00, 32
	rts
ctile_v:	lda t0
	ldx t1
ctile:	tay
	tma #4
	pha
	lda #$40
	tam #4
	vsel 0
	sty $0002
	stx $0003
	vsel 2
ct_t:	tia $8000, $0002, 32
ct_e:	pla
	tam #4
	rts
	.endif
	.if PROOF
; the same by the port register (the direct path, for comparison): 16 words, unrolled
ctilep:	tay
	vsel 0
	sty $0002
	stx $0003
	vsel 2
cp_t:	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
	lda $1A00
	sta $0002
	lda $1A00
	sta $0003
cp_e:	rts
	.endif

; ---------------------------------------------------------------- the proof (PROOF builds only; prfh in the resident area calls it at every
	.if PROOF
pst:	.db 0
pgi:	.db 0
pk:	.db 8           ; tiles a pass (a harness may write it)
pp:	.db 0
pver:	.db 1
pidx:	.db 0
pcur:	.db 0           ; this pass's path
perr:	.dw 0           ; tiles read back wrong
pbad:	.dw 0           ; bytes read back wrong
pcnt:	.db 0, 0, 0     ; tiles uploaded
pnv:	.db 0, 0, 0     ; tiles read back
ppas:	.dw 0           ; passes with uploads
pfail:	.db 0
pd0:	.db 0           ; this pass's first destination tile's word address, low ($67xx)
pi:	.db 0
pfr6:	.db 0
pbt:	.db 0
cbuf:	.ds 32
psav:	.ds 64

cprf:	lda pst
	cmp #3
	bne .n3
	jmp pupl
.n3:	cmp #1
	beq .seal
	bcc .gen
	cmp #2
	beq .chk
	rts
.gen:	lda pgi                 ; port 0 at R1's payload + 32 pgi
	jsr pbase
	lda #32
	sta pi
.g:	lda pgi
	jsr ppat
	tia cbuf, $1A00, 32
	inc pgi
	beq .gd
	dec pi
	bne .g
	rts
.gd:	inc pst
	stz cvn                 ; (R1) 8 KB
	lda #$20
	sta cvn + 1
	stz cvn + 2
	ldx #0
	jmp csbeg
.seal:	lda #8
	jsr cvstep
	bcc .x
	ldx #0
	jsr csend
	ldx #0
	jsr cvbeg
	bcs .bad
	inc pst
.x:	rts
.chk:	lda #8
	jsr cvstep
	bcc .x
	lda cvok
	beq .bad
	inc pst
	rts
.bad:	inc pfail
	lda #4
	sta pst
	rts
pbase:	pha
	asl a
	asl a
	asl a
	asl a
	asl a
	ora #$10
	sta $1A02
	pla
	lsr a
	lsr a
	lsr a
	sta $1A03
	lda #$10
	sta $1A04
	rts
; A = tile: its 32 pattern bytes into cbuf
ppat:	sta cbuf
	asl a
	asl a
	clc
	adc cbuf
	clc
	adc #$37
	ldy #0
.l:	sta cbuf,y
	clc
	adc #$1D
	iny
	cpy #32
	bne .l
	rts
; two tiles (word address pd0 / pd0 + $10, high $67) read into or written from psav
psave:	lda pd0
	jsr .rd
	lda pd0
	ora #$10
	ldy #32
.rd:	pha
.again:	lda FRAMES
	sta pi
	vsel 1
	pla
	pha
	sta $0002
	lda #$67
	sta $0003
	vsel 2
	ldx #16
.w:	lda $0002
	sta psav,y
	iny
	lda $0003
	sta psav,y
	iny
	dex
	bne .w
	lda FRAMES
	cmp pi
	beq .ok
	tya
	sec
	sbc #32
	tay
	bra .again
.ok:	pla
	rts
prest:	vsel 0
	lda pd0
	sta $0002
	lda #$67
	sta $0003
	vsel 2
	tia psav, $0002, 64     ; (the two tiles are consecutive: pd0 and pd0 + $10 words)
	rts
pupl:	lda MENU
	beq pu_go
	rts
pu_go:	lda set                 ; the coming pass's set: the other one
	eor #1
	asl a
	asl a
	asl a
	asl a
	asl a
	ora #$80
	sta pd0
	ldy #0
	jsr psave
	lda pp
	cmp #2
	bne pu_p
	lda ppas
	and #1
pu_p:	sta pcur
	lda pk
	beq pu_done
	sta pi
pu_t:	lda pidx
	jsr pbase
	lda pi
	and #1
	asl a
	asl a
	asl a
	asl a
	ora pd0
	ldx #$67
	ldy pcur
	bne pu_port
pt_a:	jsr ctile
pt_b:	bra pu_up
pu_port:	
pp_a:	jsr ctilep
pp_b:
pu_up:	inc pcnt
	bne pu_c
	inc pcnt + 1
	bne pu_c
	inc pcnt + 2
pu_c:	lda pver
	beq pu_nv
	jsr pvfy
pu_nv:	inc pidx
	dec pi
	bne pu_t
pu_done:	jsr prest
	inc ppas
	bne pu_x
	inc ppas + 1
pu_x:	rts
; the tile just uploaded (pidx, at pd0 + (pi & 1) $10) read back and compared with its pattern
pvfy:	lda pidx
	jsr ppat
	lda pi
	and #1
	asl a
	asl a
	asl a
	asl a
	ora pd0
	pha
.again:	lda FRAMES
	sta pfr6
	vsel 1
	pla
	pha
	sta $0002
	lda #$67
	sta $0003
	vsel 2
	stz pbt
	ldy #0
.r:	lda $0002
	cmp cbuf,y
	beq .a
	inc pbt
.a:	iny
	lda $0003
	cmp cbuf,y
	beq .b
	inc pbt
.b:	iny
	cpy #32
	bne .r
	lda FRAMES
	cmp pfr6
	bne .again
	pla
	inc pnv
	bne .c
	inc pnv + 1
	bne .c
	inc pnv + 2
.c:	lda pbt
	beq .x
	clc
	adc pbad
	sta pbad
	bcc .e
	inc pbad + 1
.e:	inc perr
	bne .x
	inc perr + 1
.x:	rts
	.endif
cprx:	rts
	.include "quarry_card.inc"
	.include "quarry_cardb.inc"
c6fin:	lda #<cposb
	sta pb_cv
	jsr cspin
	sec
	rts
ovend:
	.if (ovend > C6RAM + C6LEN)
	.fail
	.endif

	.bank 6
	.org C7RAM
	.include "quarry_card7.inc"
ov7end:
	.if (ov7end > C7RAM + C7LEN)
	.fail
	.endif

; ================================================================ the third overlay (quarry-bridge-setup): C8BANK's tail at MPR3 through c8tr
	.bank 7
	.org C8RAM
	.include "quarry_card8.inc"

	.if (ov8end > C8RAM + C8LEN)
	.fail
	.endif

; ================================================================ the fourth image (quarry-bridge-draw): the bridge's switch, at the third overlay's place
	.bank 8
	.org C8RAM
	.include "quarry_cardc.inc"

; ================================================================ (quarry-pregen-load) the pre-generated store's loader: assembled at its places
; in the resident area (over cidle, over q8hdr / q8maps), carried by sector PGSEC, copied there by the preload only when the store loaded
	.bank 9
	.include "quarry_pgfast.inc"

	.bank 10
	.org C7RAM
	.include "quarry_cards.inc"

	.bank 11
	.org C8RAM + C9LEN
	.include "quarry_cardh.inc"
