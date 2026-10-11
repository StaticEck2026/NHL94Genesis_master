	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	optsetup94 segment stub. Retail $0F739E-$0F8B59.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$F739E

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0F739E-$0F8B59, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
DecompressGraphicsWithCallback = $1172C	;jsr / jmp (x).l at $F81D6
DoDMA_clearCallbackPointer = $11738	;jsr / jmp (x).l at $F82CA
FigureJoy = $17E42		;jsr / jmp (x).l at $F75CC
Framer = $119B8			;jsr / jmp (x).l at $F7806
maketree = $17D80		;jsr / jmp (x).l at $F849C
NewPO = $17D16			;jsr / jmp (x).l at $F76C8
ProcessInputWithRepeat = $11318	;jsr / jmp (x).l at $F832C
ReadJoy1 = $11340		;jsr / jmp (x).l at $F8326
ReadJoy2 = $11358		;jsr / jmp (x).l at $F8356
ReadJoy3 = $11370		;jsr / jmp (x).l at $F837E
ReadJoy4 = $11388		;jsr / jmp (x).l at $F839E
TeamList = $30E			;movea.w #x operand at $F7C7C
VBlank_SetOptions = $17C42	;#x at $F8168
appstring = $11D9E		;jsr / jmp (x).l at $F8A80
ConverByteToDigits = $18BDC		;jsr / jmp (x).l at $F8A72
defaultsprites2 = $16E82		;jsr / jmp (x).l at $F82E8
dobitmap = $1169A		;jsr / jmp (x).l at $F77EA
eraser = $1197E			;jsr / jmp (x).l at $F8228
FeaturedPictures = $F92F4		;movea.l #x at $F8948 (the player picture table)
orjoy = $112BC			;jsr / jmp (x).l at $F81C0
print = $11BA4			;jsr / jmp (x).l at $F7BD2
printsmall = $11A48			;jsr / jmp (x).l at $F80BC
printz = $11B92			;jsr / jmp (x).l at $F780C
randomd0 = $11086		;jsr / jmp (x).l at $F73E8
setvram = $11594			;jsr / jmp (x).l at $F81BA
SetPojoyMode = $17AC8		;jsr / jmp (x).l at $F844A
DrawMatchupBitmaps = $17AF4		;jsr / jmp (x).l at $F7B4E
ContinuePlayoffs = $17CA0		;jsr / jmp (x).l at $F76CE
ReadPassBits = $1803E		;jsr / jmp (x).l at $F73AA
PrintRecordValue = $F98C6		;jsr / jmp (x).l at $F8AB0
PrintRecordHolder = $F9A64		;jsr / jmp (x).l at $F8AEE
PrintRecordVs = $F9AAC		;jsr / jmp (x).l at $F8B2C
ReadNameLog = $F9C68		;jsr / jmp (x).l at $F73C8
ClearShootout = $FC47C		;jsr / jmp (x).l at $F8496
ClearGameStats = $FD73C		;jsr / jmp (x).l at $F73C2
ReadLineData = $FE660		;jsr / jmp (x).l at $F739E
UnpackPicture = $FE98A		;bsr.w / Bcc.w at $F8982
GameSetUpMap = $4B7A0		;#x at $F823A
GameSetUpMap2 = $4DEEE		;#x at $F826C
SmallFontMap = $AAC52		;#x at $F81E8
TeamBitmaps = $AFE12		;#x at $F84D2
PrintFont2Map = $BE26A		;#x at $F8200
SetupMenuMap = $BEFB8		;#x at $F77C2
SetupFramerMap = $BF542		;#x at $F81D0
LogoBoxMap = $BF702		;#x at $F87A0
PicturePalette = $C63F8		;#x at $F8962
TeamLogoPalettes = $FF462		;#x at $F8692

logoANH = $BF8D0		;dc.l x in TeamLogoBitmaps
logoBOS = $BFD66		;dc.l x in TeamLogoBitmaps
logoBUF = $C00BC		;dc.l x in TeamLogoBitmaps
logoCGY = $C0412		;dc.l x in TeamLogoBitmaps
logoCHI = $C08A8		;dc.l x in TeamLogoBitmaps
logoDET = $C0CDE		;dc.l x in TeamLogoBitmaps
logoEDM = $C1034		;dc.l x in TeamLogoBitmaps
logoFLA = $C142A		;dc.l x in TeamLogoBitmaps
logoHFD = $C1900		;dc.l x in TeamLogoBitmaps
logoNYI = $C1B96		;dc.l x in TeamLogoBitmaps
logoLA = $C1FEC		;dc.l x in TeamLogoBitmaps
logoDAL = $C2362		;dc.l x in TeamLogoBitmaps
logoMTL = $C2638		;dc.l x in TeamLogoBitmaps
logoNJ = $C29AE		;dc.l x in TeamLogoBitmaps
logoNYR = $C2E64		;dc.l x in TeamLogoBitmaps
logoOTW = $C333A		;dc.l x in TeamLogoBitmaps
logoPHI = $C3750		;dc.l x in TeamLogoBitmaps
logoPIT = $C3B06		;dc.l x in TeamLogoBitmaps
logoQUE = $C3E7C		;dc.l x in TeamLogoBitmaps
logoSJ = $C41D2		;dc.l x in TeamLogoBitmaps
logoSTL = $C4608		;dc.l x in TeamLogoBitmaps
logoTB = $C49DE		;dc.l x in TeamLogoBitmaps
logoTOR = $C4DF4		;dc.l x in TeamLogoBitmaps
logoVAN = $C514A		;dc.l x in TeamLogoBitmaps
logoWSH = $C5560		;dc.l x in TeamLogoBitmaps
logoWPG = $C57D6		;dc.l x in TeamLogoBitmaps
logoASE = $C5C4C		;dc.l x in TeamLogoBitmaps
logoASW = $C6022		;dc.l x in TeamLogoBitmaps

; Main segment code
	include	optsetup94.asm
