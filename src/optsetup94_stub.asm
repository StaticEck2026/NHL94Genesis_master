;	Segment build for optsetup94.asm: sets its origin and the outside routines and data it uses,
;	then includes optsetup94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$F739E

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
DecompressGraphicsWithCallback = $1172C	;jsr / jmp (x).l
DecompressGraphicsPlain = $11738	;jsr / jmp (x).l
FigureJoy = $17E42		;jsr / jmp (x).l
Framer = $119B8			;jsr / jmp (x).l
maketree = $17D80		;jsr / jmp (x).l
NewPO = $17D16			;jsr / jmp (x).l
ProcessInputWithRepeat = $11318	;jsr / jmp (x).l
ReadJoy1 = $11340		;jsr / jmp (x).l
ReadJoy2 = $11358		;jsr / jmp (x).l
ReadJoy3 = $11370		;jsr / jmp (x).l
ReadJoy4 = $11388		;jsr / jmp (x).l
TeamList = $30E			;movea.w #x operand
VBlank_SetOptions = $17C42	;#x
appstring = $11D9E		;jsr / jmp (x).l
ConvertByteToDigits = $18BDC		;jsr / jmp (x).l
defaultsprites2 = $16E82		;jsr / jmp (x).l
dobitmap = $1169A		;jsr / jmp (x).l
eraser = $1197E			;jsr / jmp (x).l
FeaturedPictures = $F92F4		;movea.l #x (the player picture table)
orjoy = $112BC			;jsr / jmp (x).l
print = $11BA4			;jsr / jmp (x).l
printsmall = $11A48			;jsr / jmp (x).l
printz = $11B92			;jsr / jmp (x).l
randomd0 = $11086		;jsr / jmp (x).l
setVram = $11594			;jsr / jmp (x).l
UpdatePlayoffLevel = $17AC8		;jsr / jmp (x).l
DrawMatchupBitmaps = $17AF4		;jsr / jmp (x).l
ContinuePlayoffs = $17CA0		;jsr / jmp (x).l
ReadPassBits = $1803E		;jsr / jmp (x).l
PrintRecordValue = $F98C6		;jsr / jmp (x).l
PrintRecordHolder = $F9A64		;jsr / jmp (x).l
PrintRecordVs = $F9AAC		;jsr / jmp (x).l
ReadNameLog = $F9C68		;jsr / jmp (x).l
ClearShootout = $FC47C		;jsr / jmp (x).l
ClearGameStats = $FD73C		;jsr / jmp (x).l
ReadLineData = $FE660		;jsr / jmp (x).l
UnpackPicture = $FE98A		;bsr.w / Bcc.w
GameSetUpMap = $4B7A0		;#x
GameSetUpMap2 = $4DEEE		;#x
SmallFontMap = $AAC52		;#x
TeamBitmaps = $AFE12		;#x
PrintFont2Map = $BE26A		;#x
SetupMenuMap = $BEFB8		;#x
SetupFramerMap = $BF542		;#x
LogoBoxMap = $BF702		;#x
PicturePalette = $C63F8		;#x
TeamLogoPalettes = $FF462		;#x

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
