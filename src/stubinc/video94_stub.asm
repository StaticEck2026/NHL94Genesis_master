;	Segment build for video94.asm: sets its origin and the outside routines and data it uses,
;	then includes video94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$10E88

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
vb2 = $15E4C		;#x. vblank handler
play_sfx_or_music_track = $1A294		;jsr / jmp (x).l
rtss2 = $15464			;bsr.w / Bcc.w
setvideo = $15EC0		;bsr.w / Bcc.w
HandleMenuInput = $7E88			;jsr (x).w
RunArenaAnim = $FE2C8		;jsr / jmp (x).l
updatecrowdf = $7A9E		;jsr (x).w

FramerMap = $55B7E		;#x
Fprintsmall = $13508		;bsr.w / Bcc.w
bfasciicon = $1916A		;#x
BigFontMap = $A9A10		;#x
SmallFontMap = $AAC52		;#x
Teamblocksmap = $ABA14		;#x
PrintFont2Map = $BE26A		;#x

; Main segment code
	include	video94.asm
