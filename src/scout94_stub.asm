	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	scout94 segment stub. Retail $0FCB9A-$0FD617.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$FCB9A

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0FCB9A-$0FD617, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement. IDA names.
AddSmallFont = $11F04		;jsr / jmp (x).l at $FCD08
AttribAdjust = $FEF7C		;bsr.w / Bcc.w at $FD376
CalcAttrib = $FA9F8		;bsr.w / Bcc.w at $FD36C
Create_HotCold_Table = $F70A2	;jsr / jmp (x).l at $FCCA6
DecompressGraphicsWithCallback = $1172C	;jsr / jmp (x).l at $FCCFA
DoDMA_clearCallbackPointer = $11738	;jsr / jmp (x).l at $FCE18
Framer = $119B8			;jsr / jmp (x).l at $FCDA8
PushNumberWidth = $11D3A		;jsr / jmp (x).l at $FCFCC
TeamList = $30E			;#x at $FCC62
appstring = $11D9E		;jsr / jmp (x).l at $FCC26
clearTeamStats = $17102		;jsr / jmp (x).l at $FCC98
clrCrowdRAM = $F9BE2		;jsr / jmp (x).l at $FCBAC
dobitmap = $1169A		;jsr / jmp (x).l at $FCD62
PAttribOverallMask = $19420		;move.l (x).l operand at $FD310
GAttribOverallMask = $19582		;move.l (x).l operand at $FD31E
eraser = $1197E			;jsr / jmp (x).l at $FD1E8
printsmall = $11A48			;jsr / jmp (x).l at $FCFD2
printbigz = $11DE2		;jsr / jmp (x).l at $FCD68
printz = $11B92			;jsr / jmp (x).l at $FCD3E
printsmallz = $11A36			;jsr / jmp (x).l at $FD206
setvram = $11594			;jsr / jmp (x).l at $FCCD6
song = $11156			;jsr / jmp (x).l at $FCC8A
StartScoutText = $17718		;jsr / jmp (x).l at $FCE5C
ScoutTextPlayer = $17730		;jsr / jmp (x).l at $FCF5A
BuildHotColdLists = $F71A2		;jsr / jmp (x).l at $FCC7C
CompareHotColdTotals = $F7318		;jsr / jmp (x).l at $FCE72
StartText = $F997A		;jsr / jmp (x).l at $FCC08
AppendNumber = $F998E		;jsr / jmp (x).l at $FCBCA
ReadNameLog = $F9C68		;jsr / jmp (x).l at $FCC76
AppendUserName = $FA014		;bsr.w / Bcc.w at $FCC22
DrawPlayerPicture = $FAE26		;jsr / jmp (x).l at $FD0EE
PrintPlayerNameRight = $FD89A		;bsr.w / Bcc.w at $FD368
GetTeamRating = $FE172		;bsr.w / Bcc.w at $FCFC0
UnpackPicture = $FE98A		;bsr.w / Bcc.w at $FD170
ScoutMap = $54E24		;#x at $FCD4A
framermap = $55B7E		;#x at $FCD26
BigFontMap = $A9A10		;#x at $FCCF4
SmallFontMap = $AAC52		;#x at $FCD12
RonBarrMap = $B389C		;#x at $FCDEE
PicturePalette = $C63F8		;#x at $FD150
HotIconMap = $F5AF6		;#x at $FCE0E
ColdIconMap = $F5D1C		;#x at $FCE1E
TeamLogoBitmaps = $F86F2		;#x at $FD1F2
TeamLogoPalettes = $FF462		;#x at $FD19A
vb2 = $15E4C			;#x at $FCC90
waitx = $11176			;jsr / jmp (x).l at $FCEC4

; Main segment code
	include	scout94.asm
