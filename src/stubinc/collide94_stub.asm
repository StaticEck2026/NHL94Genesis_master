;	Segment build for collide94.asm: sets its origin and the outside routines and data it uses,
;	then includes collide94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$138AC

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
AddPenalty = $11F2C		;bsr.w / Bcc.w.
AddPenalty2 = $11F62		;bsr.w / Bcc.w.
GetHot = $106E0			;bsr.w / Bcc.w.
PenShotChk = $1211A		;jsr / jmp (x).l.
SetSPA = $1073A			;bsr.w / Bcc.w.
Stop4Pen = $124A6		;bsr.w / Bcc.w.
chkFgtBit1 = $FECA2		;jsr / jmp (x).l
getFgtbyte = $FEC98		;jsr / jmp (x).l
randomd0 = $11086		;bsr.w / Bcc.w.
sfx = $11132			;bsr.w / Bcc.w.
song = $11156			;bsr.w / Bcc.w.
StartArenaAnim = $FE510		;jsr / jmp (x).l
vtoa = $10676			;bsr.w / Bcc.w.
wallcollduringcheck = $F8B5A	;jsr / jmp (x).l

ChkShotStat = $12F30		;bsr.w / Bcc.w.
ChooseSong = $FE556		;jsr / jmp (x).l
PenGoalStuff = $1284A		;bsr.w / Bcc.w.
printscores1 = $12C04		;bsr.w / Bcc.w.
assinsert = $10658		;bsr.w / Bcc.w.
assreplace = $10662		;bsr.w / Bcc.w.
freezewindow = $AFB6		;jsr / jmp (x).l.
puckflip = $102D2		;bsr.w / Bcc.w.
randomd0s = $1107A		;bsr.w / Bcc.w.
sroot = $110BE			;bsr.w / Bcc.w.
stop_current_song = $1A304		;bsr.w / Bcc.w
EndPenaltyShotPlay = $F37C		;jsr / jmp (x).l.
EndOneTimer = $FEFF0		;jsr / jmp (x).l

AttributeCalc = $F70E4		;jsr / jmp (x).l
GetPeriodTime = $784E		;jsr (x).w.
a2touchpuck = $1013E		;bsr.w / Bcc.w.
chkpk2 = $E274			;bsr.w / Bcc.w.
Set4WayPlayerStub = $F6E38		;jsr / jmp (x).l
onetimershot = $F6CBA		;jsr / jmp (x).l
priolist = $19286		;#x
setc1player = $C0BC		;jsr / jmp (x).l.
setc2player = $C0DA		;jsr / jmp (x).l.
GetPlayerCount = $9F9A			;jsr / jmp (x).l
sublist = $1921C			;#x

; frames94 equates (the segment does not include frames94.asm; it emits bytes)
SPAHold	=	$C90
SPAhook	=	$1122
SPAsweepchk	=	$B24
SPAburst	=	$C5E
SPAHold2	=	$CC2
SPAinjuryfall	=	$145C
SPAinjury1	=	$1AF4
SPAstumble	=	$11E6
SPAfallfwd	=	$D26
SPAfallback	=	$DD8
SPAflip	=	$136A
SPAgstackr	=	$250
SPAgstackl	=	$2A2
SPAgdive	=	$2F4
SPAshoulderchkl	=	$B96
SPAshoulderchkr	=	$BC8
SPAhipchkr	=	$C2C
SPAhipchkl	=	$BFA
SPAflail	=	$CF4
SPAhook2	=	$1154
SPAcrosscheck	=	$1AC2
SPAbenchcheckl	=	$193E
SPAbenchcheckr	=	$1A00
SPAboardright	=	$17E8
SPAboardleft	=	$18CC
SPAboardfront	=	$1776
SPAboardback	=	$185A
SPAsiren	=	$102E
SPAbglass	=	$1078
SPAcatch	=	$10D0
SPFGoalie	=	407
SPFSiren	=	563
SPFghighr	=	658

; Main segment code
	include	collide94.asm
