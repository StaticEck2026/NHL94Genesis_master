	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	shootout94 segment stub. Retail $0FC47C-$0FCB99.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$FC47C

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0FC47C-$0FCB99, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
ExitAttributeScreen2 = $9CD8	;jsr / jmp (x).l at $FA29C
ExitToOpening = $172E4		;jsr / jmp (x).l at $FC4CA
FormatPlayerNameShort = $18B6E	;jsr / jmp (x).l at $FA9B0
Framer = $119B8			;jsr / jmp (x).l at $FB186
GetPlayerCount = $9F9A		;jsr / jmp (x).l at $F9FF4
PrintTeamData = $8078		;jsr / jmp (x).l at $FC9FE
ProcessInputWithRepeat = $11318	;jsr / jmp (x).l at $FA220
ReadAttributeNibble = $9F40	;jsr / jmp (x).l at $F9FCA
SetupScreen = $9BD8		;jsr / jmp (x).l at $FBC1C
dobitmap = $1169A		;jsr / jmp (x).l at $FA126
eraser = $1197E			;jsr / jmp (x).l at $FA152
GetNameandAttrib = $8D4E		;jsr / jmp (x).l at $FC90C
getname = $18A90			;jsr / jmp (x).l at $FCB00
getpzjoy = $A41E			;jsr / jmp (x).l at $FA21A
print = $11BA4			;jsr / jmp (x).l at $FB16C
printsmall = $11A48			;jsr / jmp (x).l at $FA3D2
printbig = $11DF4		;jsr / jmp (x).l at $FC348
printbigz = $11DE2		;jsr / jmp (x).l at $FB1FE
printz = $11B92			;jsr / jmp (x).l at $FA0FC
printsmallz = $11A36			;jsr / jmp (x).l at $FA42A
EndShootout = $FD618		;jsr / jmp (x).l at $FC540
StartShootoutPath = $FE756		;bsr.w / Bcc.w at $FC4D4
PAttribOverall = $1940E		;#x, retail long
GAttribOverall = $19570		;#x, retail long
ScoutMap = $54E24		;#x at $FB0E8
vcountwait = $80BA		;jsr / jmp (x).l at $FA214

; Main segment code
	include	shootout94.asm
