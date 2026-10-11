	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	collide94 segment stub. Retail $0138AC-$015D99.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$138AC

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0138AC-$015D99, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
AddPenalty = $11F2C		;bsr.w / Bcc.w at $13CC0. penalty94_1
AddPenalty2 = $11F62		;bsr.w / Bcc.w at $1447A. penalty94_1
GetHot = $106E0			;bsr.w / Bcc.w at $138FC. logic94_5
PenShotChk = $1211A		;jsr / jmp (x).l at $13DDA. penalty94_1
SetSPA = $1073A			;bsr.w / Bcc.w at $13D50. logic94_5
Stop4Pen = $124A6		;bsr.w / Bcc.w at $14490. penalty94_1
chkFgtBit1 = $FECA2		;jsr / jmp (x).l at $14530
getFgtbyte = $FEC98		;jsr / jmp (x).l at $144FE
randomd0 = $11086		;bsr.w / Bcc.w at $13BB6. middle94_1
sfx = $11132			;bsr.w / Bcc.w at $13BCE. middle94_1
song = $11156			;bsr.w / Bcc.w at $144A6. middle94_1
StartArenaAnim = $FE510		;jsr / jmp (x).l at $142D6
vtoa = $10676			;bsr.w / Bcc.w at $13D22. logic94_5
wallcollduringcheck = $F8B5A	;jsr / jmp (x).l at $13D7E

ChkShotStat = $12F30		;bsr.w / Bcc.w at $14724. penalty94_2
ChooseSong = $FE556		;jsr / jmp (x).l at $1490A
PenGoalStuff = $1284A		;bsr.w / Bcc.w at $149BE. penalty94_1
printscores1 = $12C04		;bsr.w / Bcc.w at $149C8. penalty94_2
assinsert = $10658		;bsr.w / Bcc.w at $14A84. logic94_5
assreplace = $10662		;bsr.w / Bcc.w at $14A30. logic94_5
freezewindow = $AFB6		;jsr / jmp (x).l at $14852. hockey94_02
puckflip = $102D2		;bsr.w / Bcc.w at $14778. logic94_5
randomd0s = $1107A		;bsr.w / Bcc.w at $14764. middle94_1
sroot = $110BE			;bsr.w / Bcc.w at $145D0. middle94_1
play_new_song = $1A304		;bsr.w / Bcc.w at $14838
EndPenaltyShotPlay = $F37C		;jsr / jmp (x).l at $14814. logic94_4
EndOneTimer = $FEFF0		;jsr / jmp (x).l at $14A7E

AttributeCalc = $F70E4		;jsr / jmp (x).l at $15BC6
GetPeriodTime = $784E		;jsr (x).w at $15B66. hockey94_01
a2touchpuck = $1013E		;bsr.w / Bcc.w at $151D6. logic94_5
chkpk2 = $E274			;bsr.w / Bcc.w at $15B16. logic94_3
Set4WayPlayerStub = $F6E38		;jsr / jmp (x).l at $159D0
onetimershot = $F6CBA		;jsr / jmp (x).l at $1525E
priolist = $19286		;#x at $1583C
setc1player = $C0BC		;jsr / jmp (x).l at $153A8. logic94_1
setc2player = $C0DA		;jsr / jmp (x).l at $153B6. logic94_1
GetPlayerCount = $9F9A			;jsr / jmp (x).l at $158DC
sublist = $1921C			;#x at $158BA

; Main segment code
	include	collide94.asm
