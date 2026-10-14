;	EA startup code: macros, assembler options, the 68000 vector table, the Sega ID
;	header and the EA logo.

	include	macros\genesis.mac

;	68000
;	ABSOLUTE
;	A4OFF
;	llchar	'.'	; Change the local label character to '.'.
;	mlchar	'@'	; Change the macro label character to '@'.

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Imports and exports
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
RAMStart = $FF0000	
	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Equates
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

InitialSP = $FFFFF6	;reset vector 0. 24-bit form of $FFFFFFF6. The game's Stack is $FFFFFFFE (ram_addrs.inc)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Vectors
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

;;	.region code
	org	0
	dc.l	InitialSP	; 0 initial stack pointer
	dc.l	Start		; 1 initial program counter
	dc.l	AddError	; 2 bus error: bus and address error share AddError
	dc.l	AddError	; 3 address error
	dc.l	Illinst		; 4 illegal instruction
	dc.l	ZeroDiv		; 5 zero divide
	dcb.b	72,$FF		; 6-23 ($18-$5F): CHK ... reserved, not used ($FF)

	dc.l	IRQ7		; 24 ($60) spurious interrupt. IRQ7 is an rte
	dc.l	IRQ7		; 25 ($64) level 1, not used
	dc.l	IRQ7		; 26 ($68) level 2 (external), not used
	dc.l	IRQ7		; 27 ($6C) level 3, not used
	dc.l	IRQ7		; 28 ($70) level 4: horizontal retrace (not used)
	dc.l	0		; 29 ($74) level 5: not used
	dc.l	VBjsr		; 30 ($78) level 6: vertical retrace, jumps through vbint
	dc.l	IRQ7		; 31 ($7C) level 7

	dc.l	0,0,0,0		; 32-35 ($80-$8F): trap #0-#3, not used. 0 in retail
	dcb.b	112,$FF		; 36-63 ($90-$FF): trap #4-#15 and reserved, not used

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Start
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	org	$100

	include	sega\SegaIDTable94.asm	;$100-$1FF cartridge header
Start	;($200). Power on: the Sega hardware init, then the checksum, then the game
	Include	sega\SegaInit.asm	;$200-$2FF SegaInit, falls into CHECK_VDP ($2FA)
	IF CHECKSUM=1
		jsr	ValidationRoutine	;jsr (x).l, 4EB9. Red screen and hang if the ROM sum is wrong
	ELSE
		nop
		nop
		nop
	ENDIF
	;no KillCrowd here

	;Short branch while Begin is in range. The build passes LONGBRA=0, and assembles again
	;with LONGBRA=1 (a long jump) when that branch cannot reach.
	IF LONGBRA=1
		jmp	(Begin).l
	ELSE
		bra.w	Begin	;last instruction of the startup code; team data follows
	ENDIF
