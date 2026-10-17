;	Segment build for teamdata94.asm: sets its origin and the outside routines and data it uses,
;	then includes teamdata94.asm on its own for checking against the ROM.

	include	macros\genesis.mac		;String, Player

; External addresses outside: none. TeamList and the team block offsets point inside the segment.
; .region code
	org	$30A

; includes for stubs to replace removed code
	include	stubinc\ports.inc		;IO_* / VDP_* ports
	include	stubinc\equals.inc		;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; Main segment code
	include	teamdata94.asm
