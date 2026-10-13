;	Segment build for replay94.asm: sets its origin and the outside routines and data it uses,
;	then includes replay94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$9FD0

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l and movea.l #x carry the
; address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
ClrHor = $12B40			;jsr (x).l at $9FEA
DoFill = $11544			;bsr.w at $9FFC
ReadJoy1 = $11340		;bra.w at $A430
ReadJoy2 = $11358		;bne.w at $A42C
ReadJoy3 = $11370		;beq.w at $A440
ReadJoy4 = $11388		;bra.w at $A444
RevRinkTilelist = $B5180		;movea.l #x at $A478
Rinktilelist = $5605A		;movea.l #x at $A468
SPAlist = $5B1C			;movea.l #x at $AEFA.
SetHor = $12B94			;jsr (x).l at $A40A
SprSort = $1702E			;jsr (x).l at $A032
asstab = $18D7C			;movea.l #x at $AE88
checkcoll = $138AC		;jsr (x).l at $AEB8
dobitmap = $1169A		;bra.w at $A486
doinput = $B0E8			;bsr.w at $AD22., the next byte
eraser = $1197E			;jmp (x).l at $A4A2
forceblack = $10F32		;bsr.w at $9FD6
forceblack2 = $10F5C		;bsr.w at $A544
loadTeamStruct = $13040		;jsr (x).l at $ABDC
printz = $11B92			;bsr.w at $A44E
revframetbl = $F600E		;movea.l #x at $A690
SetSflags8Bit1 = $FEF66		;jsr (x).l at $AA3A
setvideo = $15EC0		;jsr (x).l at $A038
sfx = $11132			;bsr.w at $A31C
DecompressGraphicsPlain = $11738		;jsr (x).l at $A00A
setupEASNmap = $16CAC		;jsr (x).l at $A3DC
ReloadEnergyBarTiles = $16CC4		;jsr (x).l at $A3E2
ReloadCrowdTiles = $16CD2		;jsr (x).l at $A3E8
ReloadRefTiles = $16CEE		;jsr (x).l at $A3EE
ReloadFaceOffTiles = $16CFC		;jsr (x).l at $A404
ReloadFaceOffMap = $16D0A		;jsr (x).l at $A3FE
ReloadRinkGraphics = $9CDC			;jsr (x).l at $A3D6
setpads = $C656			;bsr.w at $A1C8
PlaceBoardFall = $FEB54		;jsr (x).l at $AAA0
ReplayMap = $BB4EE		;movea.l #x at $A4C6
vcountwait = $80BA		;jsr (x).l at $A548.
vtoa = $10676			;jsr (x).l at $A15A

; frames94 equates (the segment does not include frames94.asm; it emits bytes)
SPFpuck	=	394
SPFbglass	=	653
SPFfight	=	354
SPFPen	=	377
SPAbenchcheckl	=	$193E
SPAbenchcheckr	=	$1A00
SPAboardleft	=	$18CC
SPAboardright	=	$17E8
SPAboardfront	=	$1776
SPAboardback	=	$185A
SPAinjuryfall	=	$145C
SPAinjury1	=	$1AF4

; Main segment code
	include	replay94.asm
