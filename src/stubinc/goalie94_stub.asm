;	Segment build for goalie94.asm: sets its origin and the outside routines and data it uses,
;	then includes goalie94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$FE1D8

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
DecompressGraphicsPlain = $11738	;jsr / jmp (x).l
setc1player = $C0BC		;jsr / jmp (x).l
setc2player = $C0DA		;jsr / jmp (x).l

ArenaGfxBank = $E9ED6		;dc.l x+n in ArenaAnims and TeamGfxList

; Main segment code
	include	goalie94.asm
