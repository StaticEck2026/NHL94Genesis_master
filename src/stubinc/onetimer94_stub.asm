;	Segment build for onetimer94.asm: sets its origin and the outside routines and data it uses,
;	then includes onetimer94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

; .region code
	org	$F66EE

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
SetSPA = $1073A			;jsr / jmp (x).l
doshot = $C2F2			;jsr / jmp (x).l
puckflip = $102D2		;jsr / jmp (x).l
randomd0 = $11086		;jsr / jmp (x).l
setc1player = $C0BC		;jsr / jmp (x).l
setc2player = $C0DA		;jsr / jmp (x).l
sroot = $110BE			;jsr / jmp (x).l
EndOneTimer = $FEFF0		;jsr / jmp (x).l
vtoa = $10676			;jsr / jmp (x).l

; frames94 equates (the segment does not include frames94.asm; it emits bytes)
SPAshotf	=	$7FC
SPAshotb	=	$92E

; Main segment code
	include	onetimer94.asm
