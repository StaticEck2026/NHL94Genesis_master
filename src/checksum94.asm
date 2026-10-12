;	ROM security check. This routine adds up the ROM and stops the game if the sum is wrong. The
;	fill that pads the ROM out to its full size follows it.

ValidationRoutine	; Called once at power on from Start. Adds
	;every ROM long from 0 up to this routine, skipping the header long at $18C. Returns if the sum is right, else turns the screen red and
	;hangs. Uses d0-d1/a0/a4
	moveq	#0,d0			;sum
	suba.l	a0,a0			;a0 = ROM address 0
	move.l	#ValidationRoutine/4,d1	;number of longs below this routine
ValidationLoop	cmpa.w	#$18C,a0		;header long $18C-$18F holds the checksum word $18E
	bne.s	SkipIncrement
	addq.w	#4,a0			;skip it, not summed
	bra.s	ContinueValidation
SkipIncrement	add.l	(a0)+,d0
ContinueValidation	subq.l	#1,d1
	bgt.s	ValidationLoop
	cmpi.l	#$8AB9F121,d0		;retail sum. Real CMPI (0C80), not EA cmp
	bne.s	VDPErrorSetup			;wrong sum: red screen
	rts
VDPErrorSetup	movea.l	#VDP_CTRL,a4
	move.w	#VDPR_AUTOINC+$02,(a4)		;auto increment 2
	move.w	#VDPR_MODE1+$04,(a4)		;mode 1: h interrupt off
	move.w	#VDPR_BGCOL,(a4)		;backdrop = colour 0
	move.w	#VDPR_MODE2+$44,(a4)		;mode 2: display on, v interrupt off, dma off
	move.w	#$C000,(a4)		;cram write, colour 0 (first command word only)
	move.w	#$3F,d1			;64 colours
VRAMWriteLoop	move.w	#$E,(VDP_DATA).l	;colour = $00E, full red
	dbf	d1,VRAMWriteLoop
Halt	bra.s	Halt			;hang
