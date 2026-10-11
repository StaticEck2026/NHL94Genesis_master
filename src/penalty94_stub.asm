	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$11F2C

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
DecompressGraphicsPlain = $11738	;bsr.w / Bcc.w.
DoFill = $11544			;bsr.w / Bcc.w.
Framer = $119B8			;bsr.w / Bcc.w.
Penaltylist = $18E0C		;#x
PushTime = $11CA2		;bsr.w / Bcc.w.
RefsMap = $5C408			;#x
Rinktiles = $56062		;#x
Setplass = $15A88		;bsr.w / Bcc.w
SprSort = $1702E			;bsr.w / Bcc.w
appendz = $11D96			;bsr.w / Bcc.w.
appstring = $11D9E		;bsr.w / Bcc.w.
assinsert = $10658		;bsr.w / Bcc.w.
assreplace = $10662		;bsr.w / Bcc.w.
dobitmap = $1169A		;bsr.w / Bcc.w.
eraser = $1197E			;jsr / jmp (x).l.
forceblack = $10F32		;bsr.w / Bcc.w.
getGoalieSCnum = $B86A		;jsr / jmp (x).l.
HorRinkTiles = $BC064		;#x
ShowGoalBox = $1889A		;bsr.w / Bcc.w.
print = $11BA4			;bsr.w / Bcc.w.
printz = $11B92			;bsr.w / Bcc.w.
priolist = $19286		;#x
rtss2 = $15464			;bsr.w / Bcc.w. an rts
setplayer = $15AA4		;bsr.w / Bcc.w
sfx = $11132			;bsr.w / Bcc.w.
song = $11156			;(bsr.w ; a fixed value because the.song local also matches the name)
GetPeriodTimeRemaining = $14A94		;bsr.w / Bcc.w.
ShowThreeStars = $1850A		;bsr.w / Bcc.w.
PenaltyShotBox = $187B8		;jsr / jmp (x).l
GetPlayerName = $18A6E		;bsr.w / Bcc.w.
stop_current_song = $1A304		;jsr / jmp (x).l
ShootoutWonBy = $FC5AE		;jsr / jmp (x).l
LoadHomeTeamGfx = $FEA52		;jsr / jmp (x).l
PenShotPenalties = $1913A		;#x. penalty shot penalty per penalty number
RefMap2 = $5CF64		;#x.
HorRinkMap = $BC05C		;#x. hidden in the SetHor string. ; HorRinkTiles is +8
updatePPTeamTime = $FE14C	;jsr / jmp (x).l

p_turnoff = $1A264		;jsr / jmp (x).l.
DoGameFrame = $794E		;jsr (x).w.
GetShifter = $1828A		;bsr.w / Bcc.w
KillCrowd = $169D0		;jsr / jmp (x).l
PushNumber = $11D06		;bsr.w / Bcc.w
PushNumberWidth = $11D3A		;bsr.w / Bcc.w. (?)
ResetBench = $15A24		;bsr.w / Bcc.w
setpersonel = $15788		;bsr.w / Bcc.w
setplayercolors = $1720C		;bsr.w / Bcc.w.
SetupPauseScreen = $7DCE		;jsr (x).w. (also movea.l #x)
WeightedRandomSelect = $10EB4	;bsr.w / Bcc.w.
clearTeamStats = $17102		;jsr / jmp (x).l
ConvertByteToDigits = $18BDC		;bsr.w / Bcc.w.
forcepldata = $159A8		;bsr.w / Bcc.w
orjoy = $112BC			;bsr.w / Bcc.w
printsmall = $11A48			;bsr.w / Bcc.w
printbig = $11DF4		;bsr.w / Bcc.w
randomd0 = $11086		;bsr.w / Bcc.w
resetplstuff = $170B0		;bsr.w / Bcc.w
restoreteams = $77F4		;jsr (x).w.
setvideo = $15EC0		;bsr.w / Bcc.w
setupice_highlight = $16BAC		;bsr.w / Bcc.w.
InitMenuState = $7E36			;jsr (x).w.
DrawMenuScreen = $7E46			;jsr (x).w.
PutTeamBlock = $8078			;jsr / jmp (x).l.
UpdateRecords = $F9CDE		;jsr / jmp (x).l
PerLabels = $191E4		;#x.
PenShotPenalties2 = $191F8		;#x. 94 period names
ShootoutIntermissionMenu = $19A00		;#x. 94 item list (gmode2 bit 0)
StartGameText = $19A84		;dc.l in.sslist
StartGameTextPO = $19B38		;dc.l in.sslist
IntermissionText = $19C04		;dc.l in.sslist
ExitGameText = $19D60		;dc.l in.sslist
ExitGameTextPO = $19E74		;dc.l in.sslist
ZamFrameList = $A8922		;#x. +8
EnergyBarMap = $AB920		;#x.
EASNmap = $B3530		;#x.
waitxsr = $111D0		;bsr.w / Bcc.w.

; Main segment code
	include	penalty94.asm
