	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	menu94 segment stub. Retail $007E36-$0080D3.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$7E36

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $007E36-$0080D3, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
Framer = $119B8			;jsr / jmp (x).l at $7E60
printsmall = $11A48			;jsr / jmp (x).l at $7F4A
printsmallz = $11A36			;jsr / jmp (x).l at $7E4C
rtss8 = $A9D4			;bsr.w / Bcc.w at $7E7E
seta2 = $7E0E			;bsr.w / Bcc.w at $7EB8. hockey94_01 name
xyVmMap = $11952			;jsr / jmp (x).l at $808E

; Main segment code
	include	menu94.asm
