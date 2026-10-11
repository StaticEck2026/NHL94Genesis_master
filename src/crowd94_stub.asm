	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	crowd94 segment stub. Retail $0F6E8A-$0F739D.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$F6E8A

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0F6E8A-$0F739D, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
clrCrowdRAM = $F9BE2		;jsr / jmp (x).l at $F6E9A
randomd0s = $1107A		;jsr / jmp (x).l at $F70AE
sroot = $110BE			;jsr / jmp (x).l at $F678E
wallcollb = $14BC2		;jsr / jmp (x).l at $F709C

; Main segment code
	include	crowd94.asm
