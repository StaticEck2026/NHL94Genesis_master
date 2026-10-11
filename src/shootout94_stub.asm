	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$FC47C

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
ExitStatsScreen = $9CD8	;jsr / jmp (x).l
ExitToOpening = $172E4		;jsr / jmp (x).l
FormatPlayerNameShort = $18B6E	;jsr / jmp (x).l
Framer = $119B8			;jsr / jmp (x).l
GetPlayerCount = $9F9A		;jsr / jmp (x).l
PrintTeamData = $8078		;jsr / jmp (x).l
ProcessInputWithRepeat = $11318	;jsr / jmp (x).l
GetGoalieCount = $9F40	;jsr / jmp (x).l
SetupScreen = $9BD8		;jsr / jmp (x).l
dobitmap = $1169A		;jsr / jmp (x).l
eraser = $1197E			;jsr / jmp (x).l
GetNameandAttrib = $8D4E		;jsr / jmp (x).l
getname = $18A90			;jsr / jmp (x).l
getpzjoy = $A41E			;jsr / jmp (x).l
print = $11BA4			;jsr / jmp (x).l
printsmall = $11A48			;jsr / jmp (x).l
printbig = $11DF4		;jsr / jmp (x).l
printbigz = $11DE2		;jsr / jmp (x).l
printz = $11B92			;jsr / jmp (x).l
printsmallz = $11A36			;jsr / jmp (x).l
EndShootout = $FD618		;jsr / jmp (x).l
StartShootoutPath = $FE756		;bsr.w / Bcc.w
PAttribOverall = $1940E		;#x, retail long
GAttribOverall = $19570		;#x, retail long
ScoutMap = $54E24		;#x
vcountwait = $80BA		;jsr / jmp (x).l

; Main segment code
	include	shootout94.asm
