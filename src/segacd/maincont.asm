; MAIN.BIN $500-$CB7 ($FF0500-$FF0CB7). Emitted by tools/emit_m68k.py.
; Rest of the DMA routine, the $23A450 copy, and a 9-long table at $FF0C94.

X_FF0272	equ	$FF0272
X_FF110E	equ	$FF110E
X_FF10BE	equ	$FF10BE

	org	$FF0500

	bge.w	LFF0514
	ori.w	#$4000,d3
	swap	d3
	andi.w	#$3,d3
	move.l	d3,(a1)
	move.l	(a0),-$4(a1)
LFF0514	move.w	(sp)+,sr
	movem.l	(sp)+,d2-d3/a1
	rts
LFF051C	move.w	$C00004.l,d2
	btst	#$1,d2
	bne.b	LFF051C
	rts
	lea.l	$23A450.l,a0
	move.w	(a0)+,$FF284E.l
	move.w	(a0)+,$FF2850.l
	move.w	(a0)+,$FF2852.l
	move.w	(a0)+,$FF2856.l
	move.w	(a0)+,$FF285A.l
	move.w	(a0)+,$FF2854.l
	move.w	(a0)+,$FF285E.l
	bclr.b	#$3,$23C6E8.l
	move.w	(a0)+,d0
	or.b	d0,$23C6E8.l
	move.w	(a0)+,d0
	movea.l	#$23A850,a0
	moveq	#$3F,d1
LFF0574	move.w	d0,(a0)+
	dbra	d1,LFF0574
	move.w	#$18,$23A8D0.l
	bsr.w	LFF0734
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	move.w	#$8F02,$C00004.l
	movea.l	#$C00000,a0
	move.w	#$8C00,d0
	move.w	#$5,$FF285C.l
	btst.b	#$3,$23C6E8.l
	bne.w	LFF05C6
	move.w	#$6,$FF285C.l
	ori.w	#$81,d0
LFF05C6	move.w	d0,$4(a0)
	move.w	#$8004,$4(a0)
	move.w	#$8164,$4(a0)
	move.w	$FF2854.l,d0
	move.w	d0,$FF2858.l
	subq.w	#$5,d0
	cmpi.w	#$1,d0
	bls.w	LFF05EE
	moveq	#$3,d0
LFF05EE	cmpi.w	#$40,$FF285E.l
	bne.w	LFF05FE
	ori.w	#$10,d0
LFF05FE	cmpi.w	#$80,$FF285E.l
	bne.w	LFF060E
	ori.w	#$30,d0
LFF060E	ori.w	#$9000,d0
	move.w	d0,$4(a0)
	move.w	#$8200,d0
	move.b	$FF2852.l,d0
	lsr.b	#$2,d0
	andi.b	#$38,d0
	move.w	d0,$4(a0)
	move.w	#$8400,d0
	move.b	$FF2856.l,d0
	lsr.b	#$5,d0
	move.w	d0,$4(a0)
	move.w	#$8300,d0
	move.b	$FF285A.l,d0
	lsr.b	#$2,d0
	andi.b	#$3E,d0
	move.w	d0,$4(a0)
	move.w	#$8500,d0
	move.b	$FF2850.l,d0
	lsr.b	#$1,d0
	move.w	d0,$4(a0)
	move.w	#$8D00,d0
	move.b	$FF284E.l,d0
	lsr.b	#$2,d0
	move.w	d0,$4(a0)
	move.w	#$9100,$4(a0)
	move.w	#$9200,$4(a0)
	move.w	#$8700,$4(a0)
	move.w	#$8B00,$4(a0)
	move.l	#$40000010,$4(a0)
	move.l	#$0,(a0)
	move.w	(sp)+,$23C6E8.l
	rts
LFF069C	movea.l	#$C00000,a0
	asl.l	#$2,d0
	lsr.w	#$2,d0
	ori.w	#$4000,d0
	swap	d0
	andi.w	#$3,d0
	move.l	d0,$4(a0)
	rts
LFF06B6	movem.l	d0-d2,-(sp)
	move.w	$FF2DB2.l,d0
	move.w	$FF2DB4.l,d1
	lea.l	$FF2852.l,a0
	adda.w	$FF2DB8.l,a0
	move.w	$2(a0),d2
	asl.w	d2,d1
	add.w	d1,d0
	add.w	d0,d0
	add.w	(a0),d0
	bsr.w	LFF069C
	movem.l	(sp)+,d0-d2
	rts
LFF06E8	movem.l	d0-d3/a0,-(sp)
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	moveq	#-1,d3
	add.w	$FF285E.l,d3
	movem.w	d0-d1,-(sp)
LFF0706	bsr.w	LFF06B6
	move.w	(sp),d0
	subq.w	#$1,d0
LFF070E	move.w	d2,(a0)
	dbra	d0,LFF070E
	addq.w	#$1,$FF2DB4.l
	and.w	d3,$FF2DB4.l
	subq.w	#$1,$2(sp)
	bne.b	LFF0706
	addq.l	#$4,sp
	move.w	(sp)+,$23C6E8.l
	movem.l	(sp)+,d0-d3/a0
	rts
LFF0734	move.w	sr,-(sp)
	move.w	$23C6E8.l,-(sp)
	bclr.b	#$4,$23C6E8.l
	move.w	#$2500,sr
LFF0748	tst.w	$23A8D0.l
	bpl.b	LFF0748
	move.w	(sp)+,$23C6E8.l
	move.w	(sp)+,sr
	rts
	movem.l	d0/a0,-(sp)
	lea.l	$FF2A1A.l,a0
	move.w	#$1CB,d0
LFF0768	clr.w	(a0)+
	dbra	d0,LFF0768
	move.b	#$1,$FF2A18.l
	movem.l	(sp)+,d0/a0
	rts
	bset.b	#$4,$23C6E8.l
	andi.b	#$9C,$23C6E8.l
	move.w	$FF284E.l,d0
	bsr.w	LFF069C
	moveq	#$0,d1
	move.w	#$DF,d0
LFF079C	move.l	d1,(a0)
	dbra	d0,LFF079C
	move.w	$FF2850.l,d0
	bsr.w	LFF069C
	moveq	#$0,d0
	move.l	d0,(a0)
	move.l	d0,(a0)
	bclr.b	#$4,$23C6E8.l
	rts
	lea.l	$23A450.l,a0
	move.w	(a0)+,d0
	move.w	(a0)+,d1
	move.w	(a0)+,d2
	move.w	(a0)+,$FF2DB2.l
	move.w	(a0)+,$FF2DB4.l
	move.w	(a0)+,$FF2DB8.l
	bsr.w	LFF06E8
	lea.l	$23A450.l,a0
	move.w	$FF2DB2.l,(a0)+
	move.w	$FF2DB4.l,(a0)+
	move.w	$FF2DB8.l,(a0)+
	rts
	lea.l	$23A450.l,a0
	move.w	(a0)+,d0
	move.w	(a0)+,d1
	move.w	(a0)+,d2
	bsr.w	X_FF10BE
	rts
LFF080A	move.w	$FF2DB4.l,-(sp)
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	movem.l	d0-d3/d5-d6/a0-a3,-(sp)
	move.w	d1,d6
	lea.l	$FF2A1A.l,a3
	move.w	$FF2DB6.l,d5
	andi.w	#$F800,d5
	move.w	$E(sp),d2
	subq.w	#$1,d2
LFF083A	bsr.w	LFF06B6
	move.w	d6,d0
	mulu.w	(a1),d0
	add.w	$2(sp),d0
	asl.w	#$1,d0
	move.w	$A(sp),d1
	subq.w	#$1,d1
LFF084E	move.w	$4(a1,d0.w),d3
	move.w	d3,-(sp)
	andi.w	#$7FF,d3
	tst.b	(a3,d3.w)
	bne.w	LFF086E
	move.b	$FF2A18.l,(a3,d3.w)
	addq.b	#$1,$FF2A18.l
LFF086E	move.b	(a3,d3.w),d3
	andi.w	#$FF,d3
	subq.w	#$1,d3
	add.w	d4,d3
	andi.w	#$F800,(sp)
	or.w	(sp)+,d3
	eor.w	d5,d3
	move.w	d3,(a0)
	addq.w	#$2,d0
	dbra	d1,LFF084E
	addq.w	#$1,$FF2DB4.l
	addq.w	#$1,d6
	dbra	d2,LFF083A
	movem.l	(sp)+,d0-d3/d5-d6/a0-a3
	move.w	(sp)+,$23C6E8.l
	move.w	(sp)+,$FF2DB4.l
	rts
LFF08A8	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	moveq	#$1,d1
	lea.l	$FF2A1A.l,a3
	bsr.w	X_FF110E
	clr.w	d1
	move.b	$FF2A18.l,d1
	add.w	d1,d4
	move.w	(sp)+,$23C6E8.l
	rts
LFF08D4	move.w	$FF2DB4.l,-(sp)
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	movem.l	d0-d3/d5-d6/a0-a3,-(sp)
	move.w	d1,d6
	lea.l	$23A850.l,a3
	bra.w	LFF090A
LFF08F8	move.b	(a0,d0.w),(a3,d0.w)
	dbra	d0,LFF08F8
LFF0902	adda.w	#$20,a0
	adda.w	#$20,a3
LFF090A	moveq	#$1F,d0
	lsr.w	#$1,d5
	bcs.b	LFF08F8
	bne.b	LFF0902
	move.w	$FF2DB6.l,d5
	andi.w	#$F800,d5
	move.w	$E(sp),d2
	subq.w	#$1,d2
LFF0922	bsr.w	LFF06B6
	move.w	d6,d0
	mulu.w	(a1),d0
	add.w	$2(sp),d0
	asl.w	#$1,d0
	move.w	$A(sp),d1
	subq.w	#$1,d1
LFF0936	move.w	$4(a1,d0.w),d3
	add.w	d4,d3
	eor.w	d5,d3
	move.w	d3,(a0)
	addq.w	#$2,d0
	dbra	d1,LFF0936
	addq.w	#$1,$FF2DB4.l
	addq.w	#$1,d6
	dbra	d2,LFF0922
	bsr.w	X_FF0272
	movem.l	(sp)+,d0-d3/d5-d6/a0-a3
	move.w	(sp)+,$23C6E8.l
	move.w	(sp)+,$FF2DB4.l
	rts
	lea.l	$23A450.l,a5
	movea.l	(a5)+,a0
	movea.l	(a5)+,a1
	movea.l	(a5)+,a2
	move.l	(a5)+,d0
	move.l	(a5)+,d1
	move.l	(a5)+,d2
	move.l	(a5)+,d3
	move.l	(a5)+,d4
	move.l	(a5)+,d5
	adda.l	#$180000,a0
	adda.l	#$180000,a1
	adda.l	#$180000,a2
	move.w	(a5)+,$FF2DB6.l
	move.w	(a5)+,$FF2DB2.l
	move.w	(a5)+,$FF2DB4.l
	move.w	(a5)+,$FF2DB8.l
	bsr.w	LFF08D4
	lea.l	$23A450.l,a5
	move.w	d4,(a5)+
	move.w	$FF2DB6.l,(a5)+
	move.w	$FF2DB2.l,(a5)+
	move.w	$FF2DB4.l,(a5)+
	move.w	$FF2DB8.l,(a5)+
	rts
	lea.l	$23A450.l,a5
	movea.l	(a5)+,a0
	adda.l	#$180000,a0
	move.w	(a5),d4
	bsr.w	LFF08A8
	move.w	d4,$23A450.l
	rts
	lea.l	$23A450.l,a5
	movea.l	(a5)+,a0
	movea.l	(a5)+,a1
	movea.l	(a5)+,a2
	adda.l	#$180000,a0
	adda.l	#$180000,a1
	adda.l	#$180000,a2
	move.l	(a5)+,d0
	move.l	(a5)+,d1
	move.l	(a5)+,d2
	move.l	(a5)+,d3
	move.l	(a5)+,d4
	move.l	(a5)+,d5
	move.w	(a5)+,$FF2DB6.l
	move.w	(a5)+,$FF2DB2.l
	move.w	(a5)+,$FF2DB4.l
	move.w	(a5),$FF2DB8.l
	bsr.w	LFF080A
	move.w	d4,$23A450.l
	rts
LFF0A3A	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	LFF06B6
	move.w	$FF2DB6.l,d2
	move.w	(a1)+,d3
	subq.w	#$2,d3
	bra.w	LFF0AD8
LFF0A5E	move.b	(a1)+,d0
	beq.w	LFF0AD8
	ext.w	d0
	bpl.w	LFF0AA8
	neg.w	d0
	move.w	d0,d2
	asl.w	#$8,d2
	asl.w	#$1,d2
	andi.w	#$F800,d2
	move.w	d2,$FF2DB6.l
	andi.w	#$3,d0
	asl.w	#$2,d0
	subq.w	#$4,d0
	move.w	d0,$FF2DB8.l
	move.b	(a1)+,d0
	ext.w	d0
	move.w	d0,$FF2DB2.l
	move.b	(a1)+,d1
	ext.w	d1
	move.w	d1,$FF2DB4.l
	bsr.w	LFF06B6
	subq.w	#$2,d3
	bra.w	LFF0AD8
LFF0AA8	cmpi.b	#$40,d0
	bne.w	LFF0AB8
	move.w	#$7FF,d0
	bra.w	LFF0ACE
LFF0AB8	asl.w	#$1,d0
	movea.l	$FF2884.l,a2
	adda.l	$4(a2),a2
	move.w	$4(a2,d0.w),d0
	add.w	$FF287A.l,d0
LFF0ACE	add.w	d2,d0
	move.w	d0,(a0)
	addq.w	#$1,$FF2DB2.l
LFF0AD8	dbra	d3,LFF0A5E
	movem.l	(sp)+,d0-d3/a0/a2
	move.w	(sp)+,$23C6E8.l
	rts
	move.l	a1,-(sp)
	movea.l	$4(sp),a1
	bsr.w	LFF0A3A
	move.l	a1,$4(sp)
	movea.l	(sp)+,a1
	rts
	lea.l	$23A450.l,a1
	move.w	(a1)+,$FF2DB6.l
	move.w	(a1)+,$FF2DB8.l
	move.w	(a1)+,$FF2DB2.l
	move.w	(a1)+,$FF2DB4.l
	move.w	(a1)+,$FF287A.l
	bsr.w	LFF0A3A
	lea.l	$23A450.l,a1
	move.w	$FF2DB6.l,(a1)+
	move.w	$FF2DB8.l,(a1)+
	move.w	$FF2DB2.l,(a1)+
	move.w	$FF2DB4.l,(a1)
	rts
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	movem.l	d0-d3/a0/a2-a3,-(sp)
	lea.l	$FF287A.l,a3
	bsr.w	LFF06B6
	move.w	$FF2DB6.l,d2
	move.w	(a1)+,d3
	subq.w	#$2,d3
	bra.w	LFF0B8C
LFF0B6C	move.b	(a1)+,d0
	ext.w	d0
	bgt.w	LFF0B88
	neg.w	d0
	asl.w	#$2,d0
	movea.l	#$FF1C94,a2
	movea.l	(a2,d0.w),a2
	jsr	(a2)
	bra.w	LFF0B8C
LFF0B88	bsr.w	LFF0B9C
LFF0B8C	dbra	d3,LFF0B6C
	movem.l	(sp)+,d0-d3/a0/a2-a3
	move.w	(sp)+,$23C6E8.l
	rts
LFF0B9C	move.w	$FF2DBA.l,d1
	cmpi.w	#$4,d1
	beq.w	LFF0BEC
	cmpi.b	#$40,d0
	bne.w	LFF0BBA
	move.w	#$7FF,d0
	bra.w	LFF0BD6
LFF0BBA	cmpi.b	#$5E,d0
	beq.w	LFF0BE2
	asl.w	#$1,d0
	movea.l	$FF2884.l,a2
	adda.l	$4(a2),a2
	move.w	$4(a2,d0.w),d0
	add.w	(a3,d1.w),d0
LFF0BD6	add.w	d2,d0
	move.w	d0,(a0)
	addq.w	#$1,$FF2DB2.l
	rts
LFF0BE2	addq.w	#$1,$FF2DB2.l
	bra.w	LFF06B6
LFF0BEC	cmpi.b	#$61,d0
	blt.w	LFF0C00
	cmpi.b	#$7A,d0
	bgt.w	LFF0C00
	addi.w	#$FFE0,d0
LFF0C00	movem.l	d4-d7/a0,-(sp)
	subi.w	#$20,d0
	lea.l	$FF2DBC.l,a0
	moveq	#$1,d4
	move.b	(a0,d0.w),d5
	ext.w	d5
	bpl.w	LFF0C1E
	neg.w	d5
	clr.w	d4
LFF0C1E	add.w	d5,d5
	movea.l	$FF2888.l,a0
	adda.l	$4(a0),a0
LFF0C2A	bsr.w	LFF0C58
	move.w	(a0),d7
	add.w	d7,d7
	add.w	d7,d5
	addq.w	#$1,$FF2DB4.l
	bsr.w	LFF0C58
	sub.w	d7,d5
	subq.w	#$1,$FF2DB4.l
	addq.w	#$1,$FF2DB2.l
	addq.w	#$2,d5
	dbra	d4,LFF0C2A
	movem.l	(sp)+,d4-d7/a0
	rts
LFF0C58	movem.l	d1/a0,-(sp)
	move.w	(a3,d1.w),d6
	add.w	$4(a0,d5.w),d6
	add.w	d2,d6
	move.w	$FF2DB4.l,d0
	lea.l	$FF2852.l,a0
	adda.w	$FF2DB8.l,a0
	move.w	$2(a0),d1
	asl.w	d1,d0
	add.w	$FF2DB2.l,d0
	add.w	d0,d0
	add.w	(a0),d0
	bsr.w	LFF069C
	move.w	d6,(a0)
	movem.l	(sp)+,d1/a0
	rts
	dc.l	$FF2698
	dc.l	$FF1CCC
	dc.l	$FF1CE2
	dc.l	$FF1CF4
	dc.l	$FF1D04
	dc.l	$FF1D14
	dc.l	$FF1D24
	dc.l	$FF1D34
	dc.l	$FF1CB8
