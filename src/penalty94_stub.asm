	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	penalty94 segment stub. Retail $011F2C-$0138AB.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$11F2C

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $011F2C-$0138AB, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement. IDA names.
DoDMA_clearCallbackPointer = $11738	;bsr.w / Bcc.w at $120D6. middle94_2
DoFill = $11544			;bsr.w / Bcc.w at $12BFA. middle94_1
Framer = $119B8			;bsr.w / Bcc.w at $127E2. middle94_2
PenaltyList = $18E0C		;#x at $11FB0
PushTime = $11CA2		;bsr.w / Bcc.w at $12B02. middle94_2
RefsMap = $5C408			;#x at $12708
Rinktiles = $56062		;#x at $12B54
Setplass = $15A88		;bsr.w / Bcc.w at $12A1A
SprSort = $1702E			;bsr.w / Bcc.w at $12B66
appendz = $11D96			;bsr.w / Bcc.w at $12B16. middle94_2
appstring = $11D9E		;bsr.w / Bcc.w at $12B28. middle94_2
assinsert = $10658		;bsr.w / Bcc.w at $120F0. logic94_5
assreplace = $10662		;bsr.w / Bcc.w at $1237A. logic94_5
dobitmap = $1169A		;bsr.w / Bcc.w at $12BDC. middle94_2
eraser = $1197E			;jsr / jmp (x).l at $12058. middle94_2
forceblack = $10F32		;bsr.w / Bcc.w at $120C0. middle94_1
getGoalieSCnum = $B86A		;jsr / jmp (x).l at $121A4. logic94_1
icerinkmap = $BC064		;#x at $12BC6
DisplayPlayerAttributeMenu = $1889A		;bsr.w / Bcc.w at $12656. 93 DisplayPlayerAttributeMenu
print = $11BA4			;bsr.w / Bcc.w at $12634. middle94_2
printz = $11B92			;bsr.w / Bcc.w at $12036. middle94_2
priolist = $19286		;#x at $12A00
rtss2 = $15464			;bsr.w / Bcc.w at $11F32. an rts
setplayer = $15AA4		;bsr.w / Bcc.w at $12A1E
sfx = $11132			;bsr.w / Bcc.w at $12572. middle94_1
song = $11156			;middle94_1 (bsr.w at $11F96; a fixed value because the .song local also matches the name)
GetPeriodTimeRemaining = $14A94		;bsr.w / Bcc.w at $1229E. 93 GetPeriodTimeRemaining
DisplayPeriodOver = $1850A		;bsr.w / Bcc.w at $12608. 93 DisplayPeriodOver
PenaltyShotBox = $187B8		;jsr / jmp (x).l at $12066
GetTempPlayerName = $18A6E		;bsr.w / Bcc.w at $12628. 93 GetPlayerName
play_new_song = $1A304		;jsr / jmp (x).l at $12568
ShootoutWonBy = $FC5AE		;jsr / jmp (x).l at $1266E
LoadHomeTeamGfx = $FEA52		;jsr / jmp (x).l at $12B60
PenShotPenalties = $1913A		;#x at $1213A. penalty shot penalty per penalty number
RefMap2 = $5CF64		;#x at $12718. 93 RefMap2
HorRinkMap = $BC05C		;#x at $12BBC. hidden in the SetHor string. 93 IceRinkMap; icerinkmap is +8
updatePPTeamTime = $FE14C	;jsr / jmp (x).l at $128DA

p_turnoff = $1A264		;jsr / jmp (x).l at $13656. sound94
DoGameFrame = $794E		;jsr (x).w at $136F0. hockey94_01
GetShifter = $1828A		;bsr.w / Bcc.w at $1315C
KillCrowd = $169D0		;jsr / jmp (x).l at $13740
PushNumber = $11D06		;bsr.w / Bcc.w at $12D5A
PushNumberWidth = $11D3A		;bsr.w / Bcc.w at $12D28. middle94_2 (IDA DeterStrLength?)
ResetBench = $15A24		;bsr.w / Bcc.w at $13056
setpersonel = $15788		;bsr.w / Bcc.w at $13802
setplayercolors = $1720C		;bsr.w / Bcc.w at $13774. hockey94_06
SetupPauseScreen = $7DCE		;jsr (x).w at $13780. hockey94_01 (also movea.l #x at $1314E)
WeightedRandomSelect = $10EB4	;bsr.w / Bcc.w at $13334. logic94_5
clearTeamStats = $17102		;jsr / jmp (x).l at $135D2
ConverByteToDigits = $18BDC		;bsr.w / Bcc.w at $12E42. 93 ConverByteToDigits
forcepldata = $159A8		;bsr.w / Bcc.w at $13806
orjoy = $112BC			;bsr.w / Bcc.w at $13704
printsmall = $11A48			;bsr.w / Bcc.w at $1350C
printbig = $11DF4		;bsr.w / Bcc.w at $12D6C
randomd0 = $11086		;bsr.w / Bcc.w at $13224
resetplstuff = $170B0		;bsr.w / Bcc.w at $136A0
restoreteams = $77F4		;jsr (x).w at $135D8. hockey94_01
setvideo = $15EC0		;bsr.w / Bcc.w at $1377C
setupice_highlight = $16BAC		;bsr.w / Bcc.w at $1365C. 93 setupice_highlight
InitMenuState = $7E36			;jsr (x).w at $13158. 93 InitMenuState
DrawMenuScreen = $7E46			;jsr (x).w at $13784. 93 DrawMenuScreen
PrintTeamData = $8078			;jsr / jmp (x).l at $12D38. 93 PrintTeamData
UpdateRecords = $F9CDE		;jsr / jmp (x).l at $130F6
PerLabels = $191E4		;#x at $12C48. 93 PerLabels
PenShotPenalties2 = $191F8		;#x at $12C5C. 94 period names
ShootoutIntermissionMenu = $19A00		;#x at $13146. 94 item list (gmode2 bit 0)
StartGameText = $19A84		;dc.l in .sslist (93 StartGameText)
StartGameTextPO = $19B38		;dc.l in .sslist (93 StartGameTextPO)
IntermissionText = $19C04		;dc.l in .sslist (93 IntermissionText)
ExitGameText = $19D60		;dc.l in .sslist (93 ExitGameText)
ExitGameTextPO = $19E74		;dc.l in .sslist (93 ExitGameTextPO)
ZamFrameList = $A8922		;#x at $13114. 93 ZamSprites+8
EnergyBarMap = $AB920		;#x at $12E8E. 93 EnergyBarMap
EASNmap = $B3530		;#x at $12D84. 93 EASNmap
IntermissionLoop = $111D0		;bsr.w / Bcc.w at $13178. middle94_1

; Main segment code
	include	penalty94.asm
