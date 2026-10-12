;	Segment build for checksum94.asm: sets its origin and the outside routines and data it uses,
;	then includes checksum94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$FFAC0

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside: none. Every branch in the segment is a bra.s / Bcc.s / dbf to a label
; inside it (checked against the retail displacements), and the only absolute addresses are the VDP ports (ports.inc).

; Main segment code
	include	checksum94.asm
