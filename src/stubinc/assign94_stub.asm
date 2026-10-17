;	Segment build for assign94.asm: sets its origin and the outside routines and data it uses,
;	then includes assign94.asm on its own for checking against the ROM.

	include	macros\genesis.mac		;String

; .region code
	org	$C67A

; includes for stubs to replace removed code
	include	stubinc\ports.inc		;IO_* / VDP_* ports
	include	stubinc\equals.inc		;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
EvadePC = $E594						;lea (x,pc) at $CD9E
ReadGoaliePulled = $FEFCC			;jsr / jmp (x).l at $CD40
SetSPA = $1073A						;bsr.w / Bcc.w at $C7B4
Setplass = $15A88					;jsr / jmp (x).l at $C872
SprSort = $1702E					;jsr / jmp (x).l at $CAAA
assexit = $10646					;bsr.w / Bcc.w at $C72E
assreplace = $10662					;bsr.w / Bcc.w at $C9F6
changeplayer = $BFBC				;bsr.w / Bcc.w at $CA20.
check4check = $EACE					;bsr.w / Bcc.w at $
chkpk = $E264						;bsr.w / Bcc.w at $CE76
doplayeracc = $10750				;bsr.w / Bcc.w at $CBF6
playeracc = $10BC2					;bsr.w / Bcc.w at $CC4A
randomd0 = $11086					;bsr.w / Bcc.w at $CBBC
rtss2 = $15464						;#x at $CA02. the rts
rtss3 = $C678						;bsr.w / Bcc.w at $C716. (setpads rts)
setpads = $C656						;bsr.w / Bcc.w at $C90E.
setplayer = $15AA4					;jsr / jmp (x).l at $C842
skateto = $103C8					;bsr.w / Bcc.w at $C85E
vtoa = $10676						;bsr.w / Bcc.w at $CC3A

; frames94 equates (the segment does not include frames94.asm; it emits bytes)
SPAglide	=	$50C
SPAgready	=	$2
SPAwallleft	=	$FAC
SPAwallright	=	$F6E
SPAfaceoff	=	$FEA
SPAfaceoffr	=	$1014
SPAstanley	=	$109E
SPAcelebrate	=	$E8A
SPApump	=	$EFC

; Main segment code
	include	assign94.asm
