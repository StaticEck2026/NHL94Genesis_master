	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	attract94 segment stub. Retail $017A18-$017C71.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$17A18

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $017A18-$017C71, read from lst/nhl94.bin: jsr (x).l, movea.l #x and move.l #x carry the
; address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
vb2 = $15E4C		;move.l #x at $17A18. vblank handler
CopyPaletteToCRAM = $11044		;bsr.w at $17A62
setVram_0 = $115AA		;bsr.w at $17A66
printz = $11B92			;bsr.w at $17A6A
dobitmap = $1169A		;bsr.w at $17A90
waitx = $11176			;bsr.w at $17AB2
rtss2 = $15464			;blt.w at $17ACE (an rts)
setteams = $17190		;bsr.w at $17B68
DumpSprites2 = $15E72		;bsr.w at $17C5A. 93 DumpSprites2
cramfade = $10FB6		;bsr.w at $17C5E
p_music_vblank = $1A50A			;jsr (x).l at $17C66. sound94
eraser = $1197E			;bra.w at $17BC6
FigureJoy = $17E42		;bsr.w at $17BEC (range)
UnpackNibbles = $10E88		;bsr.w at $17C30
WeightedRandomSelect = $10EB4		;bsr.w at $17C34
TeamPalettes = $F8BF4		;movea.l #x at $17B28. 64 bytes per team
TeamBitmaps = $AFE12		;movea.l #x at $17B7C
Teamblocksmap = $ABA14		;movea.l #x at $17B9C
EASportsMap = $B425A		;movea.l #x at $17A74. hidden in the string

; Main segment code
	include	attract94.asm
