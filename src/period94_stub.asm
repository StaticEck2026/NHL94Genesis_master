	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	period94 segment stub. Retail $0FD618-$0FE1D7.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$FD618

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0FD618-$0FE1D7, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
ExitAttributeScreen2 = $9CD8	;jsr / jmp (x).l at $FDB08
FormatPlayerName = $18B26	;jsr / jmp (x).l at $FD8A4
FormatPlayerNameWithAttrib = $18AE8	;jsr / jmp (x).l at $FD8F0
Framer = $119B8			;jsr / jmp (x).l at $FD932
PrintTeamData = $8078		;jsr / jmp (x).l at $FDC9C
PushNumber = $11D06		;jsr / jmp (x).l at $FDEDE
PushNumberWidth = $11D3A		;jsr / jmp (x).l at $FDC1A
PushTime = $11CA2		;jsr / jmp (x).l at $FDFA4
SetupScreen = $9BD8		;jsr / jmp (x).l at $FD918
WaitVSyncAndReadInput = $9FB8	;jsr / jmp (x).l at $FDABC
appendz = $11D96			;jsr / jmp (x).l at $FDEEA
appstring = $11D9E		;jsr / jmp (x).l at $FDEE4
assinsert = $10658		;jsr / jmp (x).l at $FD688
dobitmap = $1169A		;jsr / jmp (x).l at $FD990
freezewindow = $AFB6		;jsr / jmp (x).l at $FD622
getpzjoy = $A41E			;jsr / jmp (x).l at $FDCDC
nodiag = $112F0			;jsr / jmp (x).l at $FDCF0
print = $11BA4			;jsr / jmp (x).l at $FD8D8
printbigz = $11DE2		;jsr / jmp (x).l at $FDA06
printz = $11B92			;jsr / jmp (x).l at $FD91E
printsmallz = $11A36			;jsr / jmp (x).l at $FDDAE
setplayer = $15AA4		;jsr / jmp (x).l at $FD65C
TeamLogoBitmaps = $F86F2		;#x at $FD95E
vcountwait = $80BA		;jsr / jmp (x).l at $FDCD6

TeamLogoPalettes = $FF462	;#x at $FD976. title94
HotColdIcon = $FF8DE		;jsr / jmp (x).l at $FD8E0. title94

; Main segment code
	include	period94.asm
