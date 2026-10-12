;	Segment build for display94.asm: sets its origin and the outside routines and data it uses,
;	then includes display94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$15D9A

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
CrowdFrameList = $A4B54		;#x.
Crowd_Noise = $F6EBE		;jsr / jmp (x).l
DoDMA = $113E4			;bsr.w / Bcc.w.
p_music_vblank = $1A50A			;jsr / jmp (x).l.
RevRinkTilelist = $B5180		;#x
Rinktilelist = $5605A		;#x.
Vmaddr = $11680			;bsr.w / Bcc.w.
ZamFrameList = $A8922		;#x (loads ZamFrameList+8)
cramfade = $10FB6		;bsr.w / Bcc.w.
rtss2 = $15464			;bsr.w / Bcc.w. (an rts)
sfx = $11132			;bsr.w / Bcc.w.
AddArenaAnimSprite = $FD78A		;jsr / jmp (x).l
FaceOffSprites = $A78AE		;#x.

Spritetiles = $5DE84		;addi.l #x (0682 + long)
jdtab = $113C0			;#x.
Sprites = $5DE7A		;#x. sprite frame list
print = $11BA4			;jsr / jmp (x).l.
printz = $11B92			;jsr / jmp (x).l.
sizetab = $1920C			;#x
SmallFontMap = $AAC52		;#x.

; Main segment code
	include	display94.asm
