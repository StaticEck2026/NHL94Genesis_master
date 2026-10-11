	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	onetimer94 segment stub. Retail $0F66EE-$0F6D5D.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$F66EE

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0F66EE-$0F6D5D, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
SetSPA = $1073A			;jsr / jmp (x).l at $F6A20
doshot = $C2F2			;jsr / jmp (x).l at $F6CC0
puckflip = $102D2		;jsr / jmp (x).l at $F67D8
randomd0 = $11086		;jsr / jmp (x).l at $F6890
setc1player = $C0BC		;jsr / jmp (x).l at $F69EE
setc2player = $C0DA		;jsr / jmp (x).l at $F69AA
sroot = $110BE			;jsr / jmp (x).l at $F678E
EndOneTimer = $FEFF0		;jsr / jmp (x).l at $F6C02
vtoa = $10676			;jsr / jmp (x).l at $F6C2A

; Main segment code
	include	onetimer94.asm
