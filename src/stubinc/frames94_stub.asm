;	Segment build for frames94.asm: sets its origin and the outside routines and data it uses,
;	then includes frames94.asm on its own for checking against the ROM.

; External addresses outside: none. Every word is a direction offset inside its own table
; a flag, or a frame / time pair.
; .region code
	org	$5B1C

; includes for stubs to replace removed code
	include	stubinc\ports.inc		;IO_* / VDP_* ports
	include	stubinc\equals.inc		;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; Main segment code
	include	frames94.asm
