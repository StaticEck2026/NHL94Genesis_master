;	Segment build for records94.asm: sets its origin and the outside routines and data it uses,
;	then includes records94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$FBB88

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
ExitStatsScreen = $9CD8	;jsr / jmp (x).l
FormatPlayerNumInitial = $18AE8	;jsr / jmp (x).l
Framer = $119B8			;jsr / jmp (x).l
ProcessInputWithRepeat = $11318	;jsr / jmp (x).l
PushNumberWidth = $11D3A		;jsr / jmp (x).l
ReadSRAM = $1A244		;jsr / jmp (x).l
SetupScreen = $9BD8		;jsr / jmp (x).l
appstring = $11D9E		;jsr / jmp (x).l
dobitmap = $1169A		;jsr / jmp (x).l
eraser = $1197E			;jsr / jmp (x).l
getpzjoy = $A41E			;jsr / jmp (x).l
prefmes = $1277A			;jsr / jmp (x).l
print = $11BA4			;jsr / jmp (x).l
printsmall = $11A48			;jsr / jmp (x).l
printbig = $11DF4		;jsr / jmp (x).l
printbigz = $11DE2		;jsr / jmp (x).l
printz = $11B92			;jsr / jmp (x).l
printsmallz = $11A36			;jsr / jmp (x).l
ClearWinRecords = $FE6D2		;bsr.w / Bcc.w
CornerLogoMap = $E9A80		;movea.l #x, retail long
ArenaGfxBank = $E9ED6		;#x
vcountwait = $80BA		;jsr / jmp (x).l

CopyString = $F997A		;bsr.w / bra.w / Bcc.w.
ReadNameLog = $F9C68		;bsr.w / bra.w / Bcc.w.
AppendUserName = $FA014		;bsr.w / bra.w / Bcc.w.
AppendTeamName = $FA880		;bsr.w / bra.w / Bcc.w.
NameEntryScreen = $FB018	;jsr / jmp (x).l.

; Main segment code
	include	records94.asm
