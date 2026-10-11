; $0FFAC0  Adapted from checksum93.asm: checksum
;	NHL 94 (retail) segment $FFAC0-$FFB0F
;	92 checksum.asm / 93 checksum93: ValidationRoutine, the last code in the ROM. The $FF fill $FFB10-$FFFFF follows (nhl94.asm
;	dcb.b after this include). 94 has no SecurityCheck word before it (93 retail has a $FFFF word; 93 Rev A has none), and its own long
;count and sum. Transcribed from lst/nhl94.bin.lst lines 976745-976783. The segment ends at $FFE00, so the fill comes from the retail bytes.

ValidationRoutine	;(92 / 93 name, which main94 calls). Called once at power on from Start (main94 jsr at $300). Adds
	;every ROM long from 0 up to this routine, skipping the header long at $18C. Returns if the sum is right, else turns the screen red and
	;hangs. Uses d0-d1/a0/a4
	moveq	#0,d0			;sum
	suba.l	a0,a0			;a0 = ROM address 0
	move.l	#ValidationRoutine/4,d1	;number of longs below this routine ($3FEB0)
ValidationLoop	cmpa.w	#$18C,a0		;header long $18C-$18F holds the checksum word $18E
	bne.s	SkipIncrement
	addq.w	#4,a0			;skip it, not summed
	bra.s	ContinueValidation
SkipIncrement	add.l	(a0)+,d0
ContinueValidation	subq.l	#1,d1
	bgt.s	ValidationLoop
	cmpi.l	#$8AB9F121,d0		;94 retail sum (93 retail $EB689746). Real CMPI (0C80), not EA cmp
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
