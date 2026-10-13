; HOCKEY.BIN sfx, file $1C10C. Loaded at $1B000 this is $3710C.
; Cartridge sfx: one word on the stack. A negative id returns.
; Otherwise the id is stored at $17F64 and $FF8022, and command $26
; is posted on the bit-6 handshake. See docs/segacd_song.md.

	org	$1C10C

	move.l	d0,-(sp)
	move.w	$8(sp),d0
	bmi.w	L1C168
	move.w	d0,$17F64.l
	move.w	d0,$FF8022.l
L1C122	btst.b	#$7,$FF800E.l
	bne.b	L1C122
	move.w	#$26,$FF8020.l
	bset.b	#$6,$FF800F.l
L1C13C	btst.b	#$6,$FF800E.l
	beq.b	L1C13C
	bset.b	#$7,$FF800F.l
	bclr.b	#$6,$FF800F.l
L1C156	btst.b	#$6,$FF800E.l
	bne.b	L1C156
	bclr.b	#$7,$FF800F.l
L1C168	movem.l	(sp)+,d0
	move.l	(sp),$2(sp)
	addq.w	#$2,sp
	rts
