	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	display94 segment stub. Retail $015D9A-$0169F9.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$15D9A

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $015D9A-$0169F9, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
CrowdFrameList = $A4B54		;#x at $161DA. 93 CrowdSprites
Crowd_Noise = $F6EBE		;jsr / jmp (x).l at $15F00
DoDMA = $113E4			;bsr.w / Bcc.w at $15E7E. middle94_1
p_music_vblank = $1A50A			;jsr / jmp (x).l at $15E1E. sound94
RevRinkTilelist = $B5180		;#x at $15F76
Rinktilelist = $5605A		;#x at $15F66. 93 IceRinkMap
Vmaddr = $11680			;bsr.w / Bcc.w at $15EAA. middle94_1
ZamFrameList = $A8922		;#x at $160FC. 93 ZamSprites (loads ZamFrameList+8)
cramfade = $10FB6		;bsr.w / Bcc.w at $15DB6. middle94_1
rtss2 = $15464			;bsr.w / Bcc.w at $15E8C. hockey94_05 (an rts)
sfx = $11132			;bsr.w / Bcc.w at $15E16. middle94_1
AddArenaAnimSprite = $FD78A		;jsr / jmp (x).l at $15EF2
FaceOffSprites = $A78AE		;#x at $16068. 93 FaceOffSprites

Spritetiles = $5DE84		;addi.l #x at $1686A (0682 + long)
jdtab = $113C0			;#x at $16574. middle94_1
Sprites = $5DE7A		;#x at $167CE. sprite frame list
print = $11BA4			;jsr / jmp (x).l at $1638E. middle94_2
printz = $11B92			;jsr / jmp (x).l at $16314. middle94_2
sizetab = $1920C			;#x at $16820
SmallFontMap = $AAC52		;#x at $163E0. 93 smallfontmap

; Main segment code
	include	display94.asm
