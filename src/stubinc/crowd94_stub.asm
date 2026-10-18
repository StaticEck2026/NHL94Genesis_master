;	Segment build for crowd94.asm: sets its origin and the outside routines and data it uses,
;	then includes crowd94.asm on its own for checking against the ROM.

	include	macros\genesis.mac		;String

; .region code
	org	$F6E8A

; includes for stubs to replace removed code
	include	stubinc\ports.inc		;IO_* / VDP_* ports
	include	stubinc\equals.inc		;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
ReadCrowdRecord = $F9BE2			;jsr / jmp (x).l
randomd0s = $1107A					;jsr / jmp (x).l
Sroot = $110BE						;jsr / jmp (x).l
wallcollb = $14BC2					;jsr / jmp (x).l

; Main segment code
	include	crowd94.asm
