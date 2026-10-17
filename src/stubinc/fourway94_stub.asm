;	Segment build for fourway94.asm: sets its origin and the outside routines and data it uses,
;	then includes fourway94.asm on its own for checking against the ROM.

	include	macros\genesis.mac		;String

; .region code
	org	$F6D5E

; includes for stubs to replace removed code
	include	stubinc\ports.inc		;IO_* / VDP_* ports
	include	stubinc\equals.inc		;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
ReadJoy1 = $11340					;jsr / jmp (x).l

; Main segment code
	include	fourway94.asm
