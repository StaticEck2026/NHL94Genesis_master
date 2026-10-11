	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	data94 segment stub. Retail $017C72-$01A04F.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$17C72

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $017C72-$01A04F, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement. IDA names.
playoffseats = $5576		;#x at $17D24
randomd0 = $11086		;bsr.w / Bcc.w at $17D18
rtss2 = $15464			;bsr.w / Bcc.w at $18100
WriteLineData = $FE696		;jsr / jmp (x).l at $18144

Framer = $119B8			;bsr.w / Bcc.w at $18548
GetPeriodTime = $784E		;jsr (x).w at $18624. hockey94_01 (IDA ClockLength)
Rinktilelist = $5605A		;#x at $1856A
appendz = $11D96			;bsr.w / Bcc.w at $18AAE
appstring = $11D9E		;bsr.w / Bcc.w at $18AB8
dobitmap = $1169A		;bsr.w / Bcc.w at $18586
eraser = $1197E			;bsr.w / Bcc.w at $18A6A
lcfound2 = $BB36			;jsr / jmp (x).l at $188B2
PlayoffRoundScreen = $FC320		;jsr / jmp (x).l at $187C8
prefmes = $1277A			;jsr / jmp (x).l at $187D6
print = $11BA4			;bsr.w / Bcc.w at $185AE
printbig = $11DF4		;bsr.w / Bcc.w at $187F2
printbigz = $11DE2		;bsr.w / Bcc.w at $18C00
printz = $11B92			;bsr.w / Bcc.w at $1853A
song = $11156			;jsr / jmp (x).l at $185D4
ReadAttributeNibble = $9F40			;jsr / jmp (x).l at $1868C
CountGoalies = $F9FC0		;jsr / jmp (x).l at $188F2
StartArenaAnim = $FE510		;jsr / jmp (x).l at $18966
PrintPlayerAssists = $FEAE4		;jsr / jmp (x).l at $189DC
PrintPlayerGoals = $FEAFA		;jsr / jmp (x).l at $189A0

InitTeamSructure = $171BE	;hockey94_06 label. The line editor menus have dc.l InitTeamSructure+$10 (retail $171CE)
ReplayMode = $9FD0		;dc.l in the menu lists, retail value. hockey94_02
assbench = $C710			;dc.l in asstab, retail value. logic94_2
assbreakaway = $E6CE		;dc.l in asstab, retail value. logic94_4
asscenterd = $D1E8		;dc.l in asstab, retail value. logic94_3
asscentero = $D294		;dc.l in asstab, retail value. logic94_3
assdefd = $CDE0			;dc.l in asstab, retail value. logic94_2
assdefo = $CD00			;dc.l in asstab, retail value. logic94_2
assdopen = $CA2A			;dc.l in asstab, retail value. logic94_2
asseben = $C882			;dc.l in asstab, retail value. logic94_2
assepen = $CA50			;dc.l in asstab, retail value. logic94_2
assfaceoff = $CB3A		;dc.l in asstab, retail value. logic94_2
assfaceoffpl = $CB50		;dc.l in asstab, retail value. logic94_2
assfight = $CBE0			;dc.l in asstab, retail value. logic94_2
assfwatch = $CBE2		;dc.l in asstab, retail value. logic94_2
assgoaliebreakwait = $CAE0	;dc.l in asstab, retail value. logic94_2
assgoaliecpu = $D51C		;dc.l in asstab, retail value. logic94_3
assgoaliectrl = $D3C6		;dc.l in asstab, retail value. logic94_3
assgoalietopuck = $DD2E		;dc.l in asstab, retail value. logic94_3
assnearest = $E6F4		;dc.l in asstab, retail value. logic94_4
assonetimer = $F693E		;dc.l in asstab, retail value
asspassrec = $EB84		;dc.l in asstab, retail value. logic94_4
asspenalty = $C8F0		;dc.l in asstab, retail value. logic94_2
asspuckc = $DF18			;dc.l in asstab, retail value. logic94_3
assscore = $CC4E			;dc.l in asstab, retail value. logic94_2
assshoot = $EC82			;dc.l in asstab, retail value. logic94_4
assstanley = $CBFA		;dc.l in asstab, retail value. logic94_2
asswingd = $CF9A			;dc.l in asstab, retail value. logic94_2
asswingo = $D09C			;dc.l in asstab, retail value. logic94_3
chkpuckc = $DEEE			;dc.l in asstab, retail value. logic94_3
puckfaceoff = $F3E4		;dc.l in asstab, retail value. logic94_4
puckfaceoff2 = $F88E		;dc.l in asstab, retail value. logic94_4
pucknorm = $FF0C			;dc.l in asstab, retail value. logic94_4
puckpenshot = $EF92		;dc.l in asstab, retail value. logic94_4
puckshadow = $102EC		;dc.l in asstab, retail value. logic94_5
puckshootout = $ECB6		;dc.l in asstab, retail value. logic94_4
puckunflip = $102A8		;dc.l in asstab, retail value. logic94_5
ShowScores = $80D4			;dc.l in the menu lists, retail value
LineEditor = $82DA			;dc.l in the menu lists, retail value
DecodePlayerAttributes = $88C8			;dc.l in the menu lists, retail value
EncodePlayerAttributes = $8928			;dc.l in the menu lists, retail value
TeamRosterScreen = $89AC			;dc.l in the menu lists, retail value
ScoringSummaryScreen = $8EB0			;dc.l in the menu lists, retail value
PenaltySummaryScreen = $9142			;dc.l in the menu lists, retail value
DisplayTeamStats = $9428			;dc.l in the menu lists, retail value
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
