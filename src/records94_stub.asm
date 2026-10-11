	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	records94 segment stub. Retail $0FBB88-$0FC47B.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$FBB88

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0FBB88-$0FC47B, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement. IDA names.
ExitAttributeScreen2 = $9CD8	;jsr / jmp (x).l at $FA29C
FormatPlayerNameWithAttrib = $18AE8	;jsr / jmp (x).l at $FC366
Framer = $119B8			;jsr / jmp (x).l at $FB186
ProcessInputWithRepeat = $11318	;jsr / jmp (x).l at $FA220
PushNumberWidth = $11D3A		;jsr / jmp (x).l at $FAC2C
ReadSRAM = $1A244		;jsr / jmp (x).l at $F9BCE
SetupScreen = $9BD8		;jsr / jmp (x).l at $FBC1C
appstring = $11D9E		;jsr / jmp (x).l at $F990A
dobitmap = $1169A		;jsr / jmp (x).l at $FA126
eraser = $1197E			;jsr / jmp (x).l at $FA152
getpzjoy = $A41E			;jsr / jmp (x).l at $FA21A
prefmes = $1277A			;jsr / jmp (x).l at $FC328
print = $11BA4			;jsr / jmp (x).l at $FB16C
printsmall = $11A48			;jsr / jmp (x).l at $FA3D2
printbig = $11DF4		;jsr / jmp (x).l at $FC348
printbigz = $11DE2		;jsr / jmp (x).l at $FB1FE
printz = $11B92			;jsr / jmp (x).l at $FA0FC
printsmallz = $11A36			;jsr / jmp (x).l at $FA42A
ClearWinRecords = $FE6D2		;bsr.w / Bcc.w at $FBD28
CornerLogoMap = $E9A80		;movea.l #x, retail long
ArenaGfxBank = $E9ED6		;#x at $FA192
vcountwait = $80BA		;jsr / jmp (x).l at $FA214

StartText = $F997A		;bsr.w / bra.w / Bcc.w at $FC080. cards94
ReadNameLog = $F9C68		;bsr.w / bra.w / Bcc.w at $FBCC8. cards94
AppendUserName = $FA014		;bsr.w / bra.w / Bcc.w at $FC17A. cards94
AppendTeamName = $FA880		;bsr.w / bra.w / Bcc.w at $FC0A6. cards94
NameEntryScreen = $FB018	;jsr / jmp (x).l at $FBBAA. cards94

; Main segment code
	include	records94.asm
