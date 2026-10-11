	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$D09C

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
AddPenalty2 = $11F62		;jsr / jmp (x).l at $D408
printscores1 = $12C04		;bsr.w / Bcc.w at $E25C
ReadGoaliePulled = $FEFCC	;jsr / jmp (x).l at $E016
setpersonel = $15788		;bsr.w / Bcc.w at $E258
donothing = $CBE4		;bsr.w / Bcc.w at $D0AC.
check4bench = $C67A		;bsr.w / Bcc.w at $D0B0.
dopass = $BC64			;jsr / jmp (x).l at $E2DA.
randomd0 = $11086		;jsr / jmp (x).l at $E2F2
randomd0s = $1107A		;bsr.w / Bcc.w at $D17C
rtss2 = $15464			;bsr.w / Bcc.w at $D476
rtss21 = $CF98			;bsr.w / Bcc.w at $D0A2.
sfx = $11132			;bsr.w / Bcc.w at $D572
sroot = $110BE			;bsr.w / Bcc.w at $D972
AvgCline = $12EF6		;bsr.w / Bcc.w at $E248
SkatePath = $FE864		;jsr / jmp (x).l at $E0EE
ShootoutShootCheck = $FE8EC		;jsr / jmp (x).l at $E0A4

Acheck = $BBD4			;bsr.w / Bcc.w at $EB64
ChooseSong = $FE556		;jsr / jmp (x).l at $ED62
ClrHor = $12B40			;bsr.w / Bcc.w at $EFFA
FaceOffMap = $55BF6		;#x at $FB8E
linelist = $191A6		;#x at $FBEE
Framer = $119B8			;bsr.w / Bcc.w at $FBCC
PeriodOver = $17236		;bsr.w / Bcc.w at $F476
PushRef = $126F8			;bsr.w / Bcc.w at $E6AA
ResetBench = $15A24		;bsr.w / Bcc.w at $F07A
SetLCmode = $B8F2		;bsr.w / Bcc.w at $F5D8
SetShotMode = $C1B8		;bsr.w / Bcc.w at $EC96
ShotMode = $C224			;bsr.w / Bcc.w at $ECAA
SprSort = $1702E			;bsr.w / Bcc.w at $F206
Stop4Pen = $124A6		;bsr.w / Bcc.w at $ED32
burst = $BB62			;bsr.w / Bcc.w at $EB72
changeplayer = $BFBC		;bsr.w / Bcc.w at $FD38
checkpuckcoll = $14D8C		;bsr.w / Bcc.w at $FFD6
checkwindow = $AFCA		;bsr.w / Bcc.w at $F06C
clockcont_0 = $7B5C		;bsr.w / Bcc.w at $F496.
dobitmap = $1169A		;bsr.w / Bcc.w at $FBAC
eraser = $1197E			;bsr.w / Bcc.w at $FE14
forceblack = $10F32		;bsr.w / Bcc.w at $EFA0
forcepldata = $159A8		;bsr.w / Bcc.w at $F9E0
freezewindow = $AFB6		;jsr / jmp (x).l at $F37C
getlinee = $12EB4		;bsr.w / Bcc.w at $F7AA
lcfound = $BB06			;bsr.w / Bcc.w at $F69E
printz = $11B92			;bsr.w / Bcc.w at $FB54
printsmallz = $11A36			;bsr.w / Bcc.w at $FBBE
resetplstuff = $170B0		;jsr / jmp (x).l at $F096
setc1player = $C0BC		;jsr / jmp (x).l at $F254
setc2player = $C0DA		;jsr / jmp (x).l at $F266
setplayer = $15AA4		;jsr / jmp (x).l at $F0EC
song = $11156			;bsr.w / Bcc.w at $ED86
DoDMA_clearCallbackPointer = $11738		;jsr / jmp (x).l at $EFCC
PrintStringFromList = $13508		;bsr.w / Bcc.w at $FBF4
SetupPenaltyShot = $1592C		;bsr.w / Bcc.w at $F086
SetLCmode2 = $B92E			;bsr.w / Bcc.w at $F680
PuckOnAttackHalf = $F6C44		;jsr / jmp (x).l at $EC0E
NextShooter = $FC4C0		;jsr / jmp (x).l at $ECE2
CountShootoutGoals = $FC516		;jsr / jmp (x).l at $F3DC
StartArenaAnim = $FE510		;jsr / jmp (x).l at $FB4E
SetFaceoffAnim = $FE53C		;jsr / jmp (x).l at $F460
EndArenaAnim = $FE548		;jsr / jmp (x).l at $FCE4
StartShootoutPath = $FE756		;jsr / jmp (x).l at $ECEC
RandomFaceoffAnim = $FECAA		;jsr / jmp (x).l at $F454
CheckScoreLeader = $FECF8		;jsr / jmp (x).l at $F43E
LeadSong = $FF7E2		;jsr / jmp (x).l at $FCA6
RefsMap = $5C408		;#x at $EFC6
FaceOffSprites = $A78AE		;#x at $FB2C

AddPenalty = $11F2C		;bsr.w / Bcc.w
HotList = $A44C8			;#x
Sweepcheck = $C0AE		;bsr.w / Bcc.w
getpde = $1575A			;bsr.w / Bcc.w
setpde = $1577A			;bsr.w / Bcc.w
stopna2 = $F6F8C			;jsr / jmp (x).l

; Main segment code
	include	checks94.asm
