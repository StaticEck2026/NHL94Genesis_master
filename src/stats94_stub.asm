	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$80D4

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
AddFramer = $11F12		;jsr / jmp (x).l at $9D56
AddSmallFont = $11F04		;jsr / jmp (x).l at $9C40
AdvanceStringPtr = $13510	;jsr / jmp (x).l at $8BBE
AttribAdjust = $FEF7C		;jsr / jmp (x).l at $8E46
AttributeScreenText = $19F88	;#x at $882E
CalcAttrib = $FA9F8		;jsr / jmp (x).l at $8D70
DecompressGraphicsWithCallback = $1172C	;bsr.w / Bcc.w at $9C30
DoDMA_clearCallbackPointer = $11738	;bsr.w / Bcc.w at $9D32
ExitAttribText = $19FF8		;#x at $8844
linelist = $191A6		;#x at $860E
FormatAndPrintTime = $11C72	;jsr / jmp (x).l at $90A0
FormatPlayerName = $18B26	;jsr / jmp (x).l at $979C
FormatPlayerNameShort = $18B6E	;jsr / jmp (x).l at $8660
FormatPlayerNumInitial = $18AE8	;jsr / jmp (x).l at $9118
Framer = $119B8			;jsr / jmp (x).l at $80EC
GAttribColumns = $1955A		;#x at $8BE8
GetShifter = $1828A		;jsr / jmp (x).l at $813C
HandleMenuInput = $7E88		;bsr.w / Bcc.w at $8868
InitMenuState = $7E36		;bsr.w / Bcc.w at $8854
PAttribColumns = $193F8		;#x at $84DA
PauseText2 = $1988C		;#x at $9D82
Penaltylist = $18E0C		;#x at $9370
PerLabels = $191E4		;#x at $8238
PlayerPositionText = $191D0	;#x at $8C70
PrintStringFromList = $13508	;jsr / jmp (x).l at $8244
PrintTeamData = $8078		;bsr.w / Bcc.w at $8768
ProcessInputWithRepeat = $11318	;jsr / jmp (x).l at $832A
PushNumber = $11D06		;jsr / jmp (x).l at $8E94
PushNumberWidth = $11D3A		;jsr / jmp (x).l at $8274
PushTime = $11CA2		;jsr / jmp (x).l at $8DCA
ReadTeamStats = $1833A		;jsr / jmp (x).l at $942C
RevRinkTiles = $B5188		;#x at $9D2C
Rinktiles = $56062		;#x at $9D1C
setpersonel = $15788		;jsr / jmp (x).l at $9E76
setplayercolors = $1720C		;jsr / jmp (x).l at $9D74
Vmaddr = $11680			;bsr.w / Bcc.w at $9BF4
ReadCrowdRecord = $F9BE2		;jsr / jmp (x).l at $9B02
dobitmap = $1169A		;jsr / jmp (x).l at $8120
eraser = $1197E			;jsr / jmp (x).l at $830C
forceblack = $10F32		;bsr.w / Bcc.w at $9BDC
getname = $18A90			;jsr / jmp (x).l at $85C8
getpzjoy = $A41E			;bsr.w / Bcc.w at $816E
nodiag = $112F0			;jsr / jmp (x).l at $8AA0
print = $11BA4			;jsr / jmp (x).l at $8264
printsmall = $11A48			;jsr / jmp (x).l at $85DA
printbigz = $11DE2		;jsr / jmp (x).l at $80F2
printz = $11B92			;jsr / jmp (x).l at $80DC
printsmallz = $11A36			;jsr / jmp (x).l at $8126
rtss2 = $15464			;#x at $8828
rtss8 = $A9D4			;bsr.w / Bcc.w at $819C
setupEASNmap = $16CAC		;jsr / jmp (x).l at $9D5C
setupIceRinkMap = $16C96		;jsr / jmp (x).l at $9D6E
sroot = $110BE			;bsr.w / Bcc.w at $9BB8
RestoreTeamEnergy = $13098		;jsr / jmp (x).l at $9DD0
ReloadEnergyBarTiles = $16CC4		;jsr / jmp (x).l at $9D62
ReloadCrowdTiles = $16CD2		;jsr / jmp (x).l at $9D68
WriteLineData = $FE696		;jsr / jmp (x).l at $897E
LoadHomeTeamGfx = $FEA52		;jsr / jmp (x).l at $9D36
GetLeagueCrowdRecord = $FEC5E		;jsr / jmp (x).l at $9B50
ScoutMap = $54E24		;#x at $870C
FramerMap = $55B7E		;#x at $9C2A
SmallFontMap = $AAC52		;#x at $9CA4
ScoresMap = $B3E74		;#x at $8106
vcountwait = $80BA		;bsr.w / Bcc.w at $816A
waitx = $11176			;bsr.w / Bcc.w at $9DE2

; Main segment code
	include	stats94.asm
