	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$FCB9A

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
AddSmallFont = $11F04		;jsr / jmp (x).l
AttribAdjust = $FEF7C		;bsr.w / Bcc.w
CalcAttrib = $FA9F8		;bsr.w / Bcc.w
Create_HotCold_Table = $F70A2	;jsr / jmp (x).l
DecompressGraphicsWithCallback = $1172C	;jsr / jmp (x).l
DecompressGraphicsPlain = $11738	;jsr / jmp (x).l
Framer = $119B8			;jsr / jmp (x).l
PushNumberWidth = $11D3A		;jsr / jmp (x).l
TeamList = $30E			;#x
appstring = $11D9E		;jsr / jmp (x).l
clearTeamStats = $17102		;jsr / jmp (x).l
ReadCrowdRecord = $F9BE2		;jsr / jmp (x).l
dobitmap = $1169A		;jsr / jmp (x).l
PAttribOverallMask = $19420		;move.l (x).l operand
GAttribOverallMask = $19582		;move.l (x).l operand
eraser = $1197E			;jsr / jmp (x).l
printsmall = $11A48			;jsr / jmp (x).l
printbigz = $11DE2		;jsr / jmp (x).l
printz = $11B92			;jsr / jmp (x).l
printsmallz = $11A36			;jsr / jmp (x).l
setVram = $11594			;jsr / jmp (x).l
song = $11156			;jsr / jmp (x).l
InitScoutingDisplay = $17718		;jsr / jmp (x).l
UpdateScoutingDisplay = $17730		;jsr / jmp (x).l
BuildHotColdLists = $F71A2		;jsr / jmp (x).l
CompareHotColdTotals = $F7318		;jsr / jmp (x).l
StartText = $F997A		;jsr / jmp (x).l
AppendNumber = $F998E		;jsr / jmp (x).l
ReadNameLog = $F9C68		;jsr / jmp (x).l
AppendUserName = $FA014		;bsr.w / Bcc.w
DrawPlayerPicture = $FAE26		;jsr / jmp (x).l
PrintPlayerNameRight = $FD89A		;bsr.w / Bcc.w
GetTeamRating = $FE172		;bsr.w / Bcc.w
UnpackPicture = $FE98A		;bsr.w / Bcc.w
ScoutMap = $54E24		;#x
FramerMap = $55B7E		;#x
BigFontMap = $A9A10		;#x
SmallFontMap = $AAC52		;#x
RonBarrMap = $B389C		;#x
PicturePalette = $C63F8		;#x
HotIconMap = $F5AF6		;#x
ColdIconMap = $F5D1C		;#x
TeamLogoBitmaps = $F86F2		;#x
TeamLogoPalettes = $FF462		;#x
vb2 = $15E4C			;#x
waitx = $11176			;jsr / jmp (x).l

; Main segment code
	include	scout94.asm
