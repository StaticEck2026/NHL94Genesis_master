;	Segment build for input94.asm: sets its origin and the outside routines and data it uses,
;	then includes input94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$B0E8

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l and movea.l / move.l #x carry
; the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement. (names for
; startpause3 / startpause4).
linelist = $191A6		;movea.l #x at $B994
Framer = $119B8			;bsr.w at $B950
GetHot = $106E0			;bsr.w at $BED2
PSandSOpassdir = $FE71C		;jsr (x).l at $C63C
printscores1 = $12C04		;bsr.w at $BB5E
ReadGoaliePulled = $FEFCC	;jsr (x).l at $C41C
setpersonel = $15788		;jsr (x).l at $BB30
SetSPA = $1073A			;bra.w at $B458
Setplass = $15A88		;jmp (x).l at $C6FA
assinsert = $10658		;bsr.w at $BECA
assreplace = $10662		;jsr (x).l at $B234
box = $18A56			;jsr (x).l at $B946
checkob = $E62E			;bsr.w at $B72E
chgplayer = $FF9A8		;jsr (x).l at $BFBC
dirtab = $10E64			;movea.l #x at $
doplayeracc = $10750		;bne.w at $B626
eraser = $1197E			;bsr.w at $BB5A
getpde = $1575A			;jsr (x).l at $BB62
goaliesave = $DBBA		;jsr (x).l at $B5CC
loadTeamStruct = $13040		;bsr.w at $B904
makepde = $15730			;jsr (x).l at $C382
print = $11BA4			;bsr.w at $B98E
printz = $11B92			;bsr.w at $B9DE
puckvzadj = $F66EE		;jsr (x).l at $C532
randomd0 = $11086		;bsr.w at $BDAA
randomd0s = $1107A		;bsr.w at $C474
rtss8 = $A9D4			;beq.w at $BB12
setpde = $1577A			;jsr (x).l at $BB74
sfx = $11132			;bsr.w at $BE1C
sroot = $110BE			;bsr.w at $B55E
startpause1 = $7CBC		;bne.w at $B178
startpause2 = $7CCA		;bne.w at $B17C
startpause3 = $7CDC		;beq.w at $B18C.
startpause4 = $7CEA		;bra.w at $B190.
linebar = $12E66		;bsr.w at $B9A0
PrintStringFromList = $13508		;bsr.w at $B99A
OneTimerPass = $F6778		;jsr (x).l at $BCA4
OneTimerTarget = $F67E4		;jsr (x).l at $BC88
PuckOnAttackHalf = $F6C44		;jsr (x).l at $B208
ShortenMsgTimer = $FE1AA		;jsr (x).l at $B152
CountButtonPress = $FEE60		;jsr (x).l at $B760
vtoa = $10676			;jsr (x).l at $B4EC

SPAlist = $5B1C		;#x at $B498

; Main segment code
	include	input94.asm
