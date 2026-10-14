;	Segment build for main94.asm: sets its origin and the outside routines and data it uses,
;	then includes main94.asm on its own for checking against the ROM.

; .region code
	org	0

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names (Stack is $FFFFFFFE here)

; External addresses outside, read from lst/nhl94.bin.
; The vector longs carry the address itself; jsr (x).l carries it too; bra.w is the displacement word address + displacement.
AddError = $18BFC		;Vectors $08 (bus error) and $0C (address error)
Illinst = $18C22		;Vector $10
ZeroDiv = $18C4C		;Vector $14
IRQ7 = $15E6C			;(an rte). Vectors $60-$70 and $7C
VBjsr = $76B2			;Vector $78
ValidationRoutine = $FFAC0	;jsr (x).l at $300
Begin = $76B8			;bra.w at $306, displacement $73B0 at $308
RomEnd = $000FFFFF		;header ROM end. The full build sets this from the padded size

; Main segment code
	include	main94.asm
