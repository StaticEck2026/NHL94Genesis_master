;	Segment build for data94.asm: sets its origin and the outside routines and data it uses,
;	then includes data94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$17C72

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
playoffseats = $5576		;#x
randomd0 = $11086		;bsr.w / Bcc.w
rtss2 = $15464			;bsr.w / Bcc.w
WriteLineData = $FE696		;jsr / jmp (x).l

Framer = $119B8			;bsr.w / Bcc.w
GetPeriodTime = $784E		;jsr (x).w.
Rinktilelist = $5605A		;#x
appendz = $11D96			;bsr.w / Bcc.w
appstring = $11D9E		;bsr.w / Bcc.w
dobitmap = $1169A		;bsr.w / Bcc.w
eraser = $1197E			;bsr.w / Bcc.w
lcfound2 = $BB36			;jsr / jmp (x).l
ShootoutModeBox = $FC320		;jsr / jmp (x).l
prefmes = $1277A			;jsr / jmp (x).l
print = $11BA4			;bsr.w / Bcc.w
printbig = $11DF4		;bsr.w / Bcc.w
printbigz = $11DE2		;bsr.w / Bcc.w
printz = $11B92			;bsr.w / Bcc.w
song = $11156			;jsr / jmp (x).l
GetGoalieCount = $9F40			;jsr / jmp (x).l
CountGoalies = $F9FC0		;jsr / jmp (x).l
StartArenaAnim = $FE510		;jsr / jmp (x).l
PrintPlayerAssists = $FEAE4		;jsr / jmp (x).l
PrintPlayerGoals = $FEAFA		;jsr / jmp (x).l

InitTeamStructure = $171BE	;The line editor menus have dc.l InitTeamStructure+$10
ReplayMode = $9FD0		;dc.l in the menu lists, retail value.
assbench = $C710			;dc.l in asstab, retail value.
assbreakaway = $E6CE		;dc.l in asstab, retail value.
asscenterd = $D1E8		;dc.l in asstab, retail value.
asscentero = $D294		;dc.l in asstab, retail value.
assdefd = $CDE0			;dc.l in asstab, retail value.
assdefo = $CD00			;dc.l in asstab, retail value.
assdopen = $CA2A			;dc.l in asstab, retail value.
asseben = $C882			;dc.l in asstab, retail value.
assepen = $CA50			;dc.l in asstab, retail value.
assfaceoff = $CB3A		;dc.l in asstab, retail value.
assfaceoffpl = $CB50		;dc.l in asstab, retail value.
assfight = $CBE0			;dc.l in asstab, retail value.
assfwatch = $CBE2		;dc.l in asstab, retail value.
assgoaliebreakwait = $CAE0	;dc.l in asstab, retail value.
assgoaliecpu = $D51C		;dc.l in asstab, retail value.
assgoaliectrl = $D3C6		;dc.l in asstab, retail value.
assgoalietopuck = $DD2E		;dc.l in asstab, retail value.
assnearest = $E6F4		;dc.l in asstab, retail value.
assonetimer = $F693E		;dc.l in asstab, retail value
asspassrec = $EB84		;dc.l in asstab, retail value.
asspenalty = $C8F0		;dc.l in asstab, retail value.
asspuckc = $DF18			;dc.l in asstab, retail value.
assscore = $CC4E			;dc.l in asstab, retail value.
assshoot = $EC82			;dc.l in asstab, retail value.
assstanley = $CBFA		;dc.l in asstab, retail value.
asswingd = $CF9A			;dc.l in asstab, retail value.
asswingo = $D09C			;dc.l in asstab, retail value.
chkpuckc = $DEEE			;dc.l in asstab, retail value.
puckfaceoff = $F3E4		;dc.l in asstab, retail value.
puckfaceoff2 = $F88E		;dc.l in asstab, retail value.
pucknorm = $FF0C			;dc.l in asstab, retail value.
puckpenshot = $EF92		;dc.l in asstab, retail value.
puckshadow = $102EC		;dc.l in asstab, retail value.
puckshootout = $ECB6		;dc.l in asstab, retail value.
puckunflip = $102A8		;dc.l in asstab, retail value.
ShowScores = $80D4			;dc.l in the menu lists, retail value
LineEditor = $82DA			;dc.l in the menu lists, retail value
DecodeTeamLines = $88C8			;dc.l in the menu lists, retail value
EncodeTeamLines = $8928			;dc.l in the menu lists, retail value
TeamRosterScreen = $89AC			;dc.l in the menu lists, retail value
ScoringSummaryScreen = $8EB0			;dc.l in the menu lists, retail value
PenaltySummaryScreen = $9142			;dc.l in the menu lists, retail value
PlayoffStatsScreen = $9428			;dc.l in the menu lists, retail value
PlayerStatsScreen = $945A			;dc.l in the menu lists, retail value
CrowdMeterScreen = $9A2A			;dc.l in the menu lists, retail value
TimeoutMenu = $9D7A			;dc.l in the menu lists, retail value
SelectGoalieMenu = $9DE6			;dc.l in the menu lists, retail value
PlayerCards = $FA07E		;dc.l in the menu lists, retail value
RecordHoldersScreen = $FBC14		;dc.l in the menu lists, retail value
ShootoutShooters = $FC620		;dc.l in the menu lists, retail value
PeriodStatsScreen = $FD90C		;dc.l in the menu lists, retail value
GameStatisticsScreen = $FDC5A		;dc.l in the menu lists, retail value
ManualGoalieMenu = $FE1D8		;dc.l in the menu lists, retail value

; Main segment code
	include	data94.asm
