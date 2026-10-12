;	Segment build for attract94.asm: sets its origin and the outside routines and data it uses,
;	then includes attract94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$17A18

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr (x).l, movea.l #x and move.l #x carry the
; address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
vb2 = $15E4C		;move.l #x. vblank handler
CopyPaletteToCRAM = $11044		;bsr.w
setVram_0 = $115AA		;bsr.w
printz = $11B92			;bsr.w
dobitmap = $1169A		;bsr.w
waitx = $11176			;bsr.w
rtss2 = $15464			;blt.w (an rts)
setteams = $17190		;bsr.w
DumpSprites2 = $15E72		;bsr.w.
cramfade = $10FB6		;bsr.w
p_music_vblank = $1A50A			;jsr (x).l.
eraser = $1197E			;bra.w
FigureJoy = $17E42		;bsr.w (range)
UnpackNibbles = $10E88		;bsr.w
WeightedRandomSelect = $10EB4		;bsr.w
TeamPalettes = $F8BF4		;movea.l #x. 64 bytes per team
TeamBitmaps = $AFE12		;movea.l #x
Teamblocksmap = $ABA14		;movea.l #x
EASportsMap = $B425A		;movea.l #x. hidden in the string

; Main segment code
	include	attract94.asm
