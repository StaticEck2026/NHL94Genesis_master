;	Segment build for period94.asm: sets its origin and the outside routines and data it uses,
;	then includes period94.asm on its own for checking against the ROM.

	include	macros\genesis.mac		;String

; .region code
	org	$FD618

; includes for stubs to replace removed code
	include	stubinc\ports.inc		;IO_* / VDP_* ports
	include	stubinc\equals.inc		;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
ExitStatsScreen = $9CD8				;jsr / jmp (x).l
FormatPlayerName = $18B26			;jsr / jmp (x).l
FormatPlayerNumInitial = $18AE8		;jsr / jmp (x).l
Framer = $119B8						;jsr / jmp (x).l
PutTeamBlock = $8078				;jsr / jmp (x).l
PushNumber = $11D06					;jsr / jmp (x).l
PushNumberWidth = $11D3A			;jsr / jmp (x).l
PushTime = $11CA2					;jsr / jmp (x).l
SetupScreen = $9BD8					;jsr / jmp (x).l
WaitVSyncAndReadInput = $9FB8		;jsr / jmp (x).l
appendz = $11D96					;jsr / jmp (x).l
appstring = $11D9E					;jsr / jmp (x).l
assinsert = $10658					;jsr / jmp (x).l
dobitmap = $1169A					;jsr / jmp (x).l
freezewindow = $AFB6				;jsr / jmp (x).l
getpzjoy = $A41E					;jsr / jmp (x).l
nodiag = $112F0						;jsr / jmp (x).l
print = $11BA4						;jsr / jmp (x).l
printbigz = $11DE2					;jsr / jmp (x).l
printz = $11B92						;jsr / jmp (x).l
printsmallz = $11A36				;jsr / jmp (x).l
setplayer = $15AA4					;jsr / jmp (x).l
TeamLogoBitmaps = $F86F2			;#x
vcountwait = $80BA					;jsr / jmp (x).l

TeamLogoPalettes = $FF462			;#x.
HotColdIcon = $FF8DE				;jsr / jmp (x).l.

; Main segment code
	include	period94.asm
