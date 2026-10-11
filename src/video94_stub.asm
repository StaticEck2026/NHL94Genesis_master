	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	video94 segment stub. Retail $010EE0-$011F2B.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$10EE0

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $010EE0-$011F2B, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
vb2 = $15E4C		;#x at $10F96. vblank handler
play_sfx_or_music_track = $1A294		;jsr / jmp (x).l at $11144
rtss2 = $15464			;bsr.w / Bcc.w at $10FBA
setvideo = $15EC0		;bsr.w / Bcc.w at $11290
HandleMenuInput = $7E88			;jsr (x).w at $1127A
RunArenaAnim = $FE2C8		;jsr / jmp (x).l at $111EE
updatecrowdf = $7A9E		;jsr (x).w at $111EA

framermap = $55B7E		;#x at $119D2
PrintStringFromList = $13508		;bsr.w / Bcc.w at $11C7E
bfasciicon = $1916A		;#x at $11E92
BigFontMap = $A9A10		;#x at $11EAA
SmallFontMap = $AAC52		;#x at $11AAE
Teamblocksmap = $ABA14		;#x at $11F22
PrintFont2Map = $BE26A		;#x at $11ABE

; Main segment code
	include	video94.asm
