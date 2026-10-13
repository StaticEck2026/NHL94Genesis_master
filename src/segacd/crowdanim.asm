; HOCKEY.BIN updatecrowdf, $10D28-$10E65.
; Cartridge crowd frames. The two HV-counter reads are command $1B,
; and the sample comes back in $FF8010. Frame table is $4154C.
; See docs/segacd_crowd.md.

X_14988	equ	$14988

	org	$10D28

	cmpi.w	#$15E,$17CD2.l
	blt.w	L10D3C
	subi.w	#$3,$17CD2.l
L10D3C	sub.w	d7,$17CD2.l
	bpl.w	L10D4C
	clr.w	$17CD2.l
L10D4C	sub.w	d7,$17CD6.l
	bpl.w	L10DEC
	move.w	$17CD2.l,d0
	lsr.w	#$1,d0
	cmpi.w	#$7F,d0
	bls.w	L10D68
	moveq	#$7F,d0
L10D68	andi.w	#$60,d0
	addi.w	#$2,$17CD4.l
	andi.w	#$1E,$17CD4.l
	add.w	$17CD4.l,d0
	movea.l	#$4154C,a0
	move.b	(a0,d0.w),$17CD1.l
	clr.w	d1
	move.b	$1(a0,d0.w),d1
L10D96	btst.b	#$7,$FF800E.l
	bne.b	L10D96
	move.w	#$1B,$FF8020.l
	bset.b	#$6,$FF800F.l
L10DB0	btst.b	#$6,$FF800E.l
	beq.b	L10DB0
	move.w	$FF8010.l,d2
	bset.b	#$7,$FF800F.l
	bclr.b	#$6,$FF800F.l
L10DD0	btst.b	#$6,$FF800E.l
	bne.b	L10DD0
	bclr.b	#$7,$FF800F.l
	and.w	d1,d2
	add.w	d2,d1
	move.w	d1,$17CD6.l
L10DEC	clr.b	$17CD0.l
	cmpi.w	#$118,$17CD2.l
	bls.w	X_14988
L10DFE	btst.b	#$7,$FF800E.l
	bne.b	L10DFE
	move.w	#$1B,$FF8020.l
	bset.b	#$6,$FF800F.l
L10E18	btst.b	#$6,$FF800E.l
	beq.b	L10E18
	move.w	$FF8010.l,d0
	bset.b	#$7,$FF800F.l
	bclr.b	#$6,$FF800F.l
L10E38	btst.b	#$6,$FF800E.l
	bne.b	L10E38
	bclr.b	#$7,$FF800F.l
	andi.w	#$7F,d0
	cmpi.w	#$13,d0
	blt.w	X_14988
	cmpi.w	#$19,d0
	bgt.w	X_14988
	move.b	d0,$17CD0.l
	rts
