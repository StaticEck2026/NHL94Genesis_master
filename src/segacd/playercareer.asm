; PLAYER.BIN career-stat printer, $2010-$23CF.
; Regular/Playoff headers, then up to 7 linked season rows.
; End of a list is the word $656C or $656E at offset 4.
; See docs/segacd_stats.md.

X_129C	equ	$129C
X_3D26	equ	$3D26
X_4051	equ	$4051
X_4049	equ	$4049
X_11DA	equ	$11DA
X_3C16	equ	$3C16

	org	$2010

	movem.l	d0-d7/a0-a5,-(sp)
	move.l	$44(a6),d0
	beq.w	L23BA
	movea.l	d0,a2
	move.w	#$1C3,-(sp)
	move.w	#$14B,-(sp)
	moveq	#$1,d5
L2028	moveq	#$0,d1
	move.w	(a2),d1
	lea.l	(a2,d1.w),a2
	movea.l	a2,a0
	adda.l	#$5,a0
	cmpi.w	#$1,d5
	bne.w	L204A
	move.b	(a0),$B7(a6)
	adda.l	#$2,a0
L204A	move.w	(sp)+,d0
	move.w	#$1D,d1
	bsr.w	X_3C16
	dbra	d5,L2028
	moveq	#$0,d1
	move.w	(a2),d1
	lea.l	(a2,d1.w),a2
	movea.l	a2,a0
	adda.l	#$5,a0
	movea.l	$8E(a6),a1
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	#$20,(a1)+
L2076	cmpi.b	#$20,(a0)+
	bne.w	L2076
L207E	move.b	(a0)+,(a1)+
	bne.w	L207E
	movea.l	$8E(a6),a0
	move.w	#$1EB,d0
	move.w	#$1D,d1
	bsr.w	X_3C16
	moveq	#$3,d5
L2096	move.w	(a2),d1
	lea.l	(a2,d1.w),a2
	dbra	d5,L2096
	movea.l	a2,a3
	moveq	#$0,d0
	moveq	#$0,d3
L20A6	move.b	$5(a3),d1
	sub.b	$4(a3),d1
	cmp.b	d1,d0
	bgt.w	L20B6
	move.b	d1,d0
L20B6	move.w	(a3),d3
	lea.l	(a3,d3.w),a3
	cmpi.w	#$656C,$4(a3)
	beq.w	L20D0
	cmpi.w	#$656E,$4(a3)
	bne.w	L20A6
L20D0	movea.l	$9E(a6),a0
	cmpi.b	#$A,d0
	bge.w	L20E0
	move.b	#$A,d0
L20E0	subq.b	#$1,d0
	move.b	d0,$1(a0)
	moveq	#$0,d1
	move.b	(a0)+,d1
	add.b	(a0)+,d1
	add.b	(a0),d1
	divs.w	#$4,d1
	move.b	d1,$B6(a6)
	swap	d1
	tst.w	d1
	beq.w	L2104
	addi.b	#$1,$B6(a6)
L2104	move.w	#$9,$B8(a6)
	bsr.w	X_11DA
	movea.l	$9E(a6),a0
	moveq	#$F,d3
	add.b	$1(a0),d3
	add.w	d3,d3
	addi.l	#$B682,d3
	move.l	d3,d2
	lsl.l	#$2,d2
	lsr.w	#$2,d2
	swap	d2
	addi.l	#$40000000,d2
L212E	btst.b	#$7,$FF800E.l
	bne.b	L212E
	move.l	d2,$FF8022.l
	move.w	#$B,$FF8020.l
	bset.b	#$6,$FF800F.l
L214E	btst.b	#$6,$FF800E.l
	beq.b	L214E
	bset.b	#$7,$FF800F.l
	bclr.b	#$6,$FF800F.l
L2168	btst.b	#$6,$FF800E.l
	bne.b	L2168
	bclr.b	#$7,$FF800F.l
	lea.l	X_4049(pc),a0
	move.w	$A6(a6),d1
	cmp.w	$58(a6),d1
	bge.w	L218E
	lea.l	X_4051(pc),a0
L218E	movea.l	$8E(a6),a5
	move.w	#$7,d1
	bsr.w	X_3D26
	move.l	#$B702,d3
	movea.l	$9A(a6),a0
	movea.l	$9E(a6),a1
	move.l	d3,d2
	lsl.l	#$2,d2
	lsr.w	#$2,d2
	swap	d2
	addi.l	#$40000000,d2
L21B6	btst.b	#$7,$FF800E.l
	bne.b	L21B6
	move.l	d2,$FF8022.l
	move.w	#$B,$FF8020.l
	bset.b	#$6,$FF800F.l
L21D6	btst.b	#$6,$FF800E.l
	beq.b	L21D6
	bset.b	#$7,$FF800F.l
	bclr.b	#$6,$FF800F.l
L21F0	btst.b	#$6,$FF800E.l
	bne.b	L21F0
	bclr.b	#$7,$FF800F.l
	moveq	#$2,d5
	moveq	#$0,d1
	movea.l	$8E(a6),a5
L220A	moveq	#$0,d1
	move.b	(a1)+,d1
	bsr.w	X_3D26
	dbra	d5,L220A
	move.w	#$0,$B4(a6)
	movea.l	$8E(a6),a4
L2220	tst.b	(a4)+
	bne.w	L2220
	move.b	#$20,-$1(a4)
	movea.l	$8E(a6),a4
	bsr.w	X_129C
	move.w	#$2,$B4(a6)
	cmpi.w	#$0,$58(a6)
	beq.w	L225A
	move.w	$58(a6),d5
	subq.w	#$1,d5
L224A	tst.b	(a0)+
	bne.w	L224A
	adda.l	#$1,a1
	dbra	d5,L224A
L225A	move.l	a1,$FE(a6)
	moveq	#$2,d5
	moveq	#$0,d1
	movea.l	$8E(a6),a5
L2266	moveq	#$0,d1
	move.b	(a1)+,d1
	bsr.w	X_3D26
	dbra	d5,L2266
L2272	move.w	$56(a6),d6
	beq.w	L22C8
	subq.w	#$1,d6
	movea.l	a2,a0
L227E	move.w	(a0),d5
	lea.l	(a0,d5.w),a0
	addi.w	#$80,d3
	cmpi.w	#$656C,$4(a0)
	beq.w	L23C0
	cmpi.w	#$656E,$4(a0)
	beq.w	L23C0
	dbra	d6,L227E
	movea.l	a0,a3
	moveq	#$6,d6
L22A4	cmpi.w	#$656C,$4(a0)
	beq.w	L23C0
	cmpi.w	#$656E,$4(a0)
	beq.w	L23C0
	move.w	(a0),d5
	lea.l	(a0,d5.w),a0
	addi.w	#$80,d3
	dbra	d6,L22A4
	movea.l	a3,a2
L22C8	move.l	#$B802,d3
	moveq	#$6,d6
L22D0	movea.l	a2,a0
	moveq	#$0,d5
	move.b	$2(a0),d5
	lea.l	$3(a0,d5.w),a0
	movea.l	$9E(a6),a1
	move.l	d3,d2
	lsl.l	#$2,d2
	lsr.w	#$2,d2
	swap	d2
	addi.l	#$40000000,d2
L22EE	btst.b	#$7,$FF800E.l
	bne.b	L22EE
	move.l	d2,$FF8022.l
	move.w	#$B,$FF8020.l
	bset.b	#$6,$FF800F.l
L230E	btst.b	#$6,$FF800E.l
	beq.b	L230E
	bset.b	#$7,$FF800F.l
	bclr.b	#$6,$FF800F.l
L2328	btst.b	#$6,$FF800E.l
	bne.b	L2328
	bclr.b	#$7,$FF800F.l
	move.w	#$2,d5
	movea.l	$8E(a6),a5
L2342	moveq	#$0,d1
	move.b	(a1)+,d1
	bsr.w	X_3D26
	dbra	d5,L2342
	movea.l	$8E(a6),a4
L2352	tst.b	(a4)+
	bne.w	L2352
	move.b	#$20,-$1(a4)
	movea.l	$8E(a6),a4
	bsr.w	X_129C
	movea.l	a2,a0
	moveq	#$0,d1
	move.b	$2(a0),d1
	lea.l	$3(a0,d1.w),a0
	moveq	#$0,d1
	move.w	$58(a6),d1
	move.b	$6(a2,d1.w),d1
	lea.l	(a0,d1.w),a0
	movea.l	$FE(a6),a1
	move.w	#$2,d5
	movea.l	$8E(a6),a5
L238C	moveq	#$0,d1
	move.b	(a1)+,d1
	bsr.w	X_3D26
	dbra	d5,L238C
	move.w	(a2),d5
	lea.l	(a2,d5.w),a2
	addi.w	#$80,d3
	cmpi.w	#$656C,$4(a2)
	beq.w	L23BA
	cmpi.w	#$656E,$4(a2)
	beq.w	L23BA
	dbra	d6,L22D0
L23BA	movem.l	(sp)+,d0-d7/a0-a5
	rts
L23C0	subi.w	#$1,$56(a6)
	move.w	#$0,$B0(a6)
	bra.w	L2272
