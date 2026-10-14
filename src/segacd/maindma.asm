; MAIN.BIN $272-$4FF ($FF0272-$FF04FF). Emitted by tools/emit_m68k.py.
; Word-RAM blit and VDP DMA. Continues the call at the end of maincd.asm.
; Assemble with /o oz- (see tools/segacd.json; npm run build:segacd).

X_FF051C	equ	$FF051C
X_FF069C	equ	$FF069C
X_FF110E	equ	$FF110E
X_FF1912	equ	$FF1912

	org	$FF0272

	lea.l	X_FF1912(pc),a0
	clr.l	(a0)
	movem.l	d0-d1/a0,-(sp)
	movea.l	a2,a0
	move.w	d4,d1
	asl.w	#$5,d1
	move.w	(a0)+,d0
	beq.b	LFF02B0
	bmi.b	LFF02A6
	add.w	d0,d4
	asl.w	#$4,d0
	pea.l	$FF12B0.l
	tst.l	$FF2912.l
	beq.w	LFF03D2
	movea.l	$FF2912.l,a1
	bra.w	LFF02B6
LFF02A6	andi.w	#$7FFF,d0
	add.w	d0,d4
	bsr.w	X_FF110E
LFF02B0	movem.l	(sp)+,d0-d1/a0
	rts
LFF02B6	move.w	sr,-(sp)
	move.w	#$2700,sr
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	movem.l	d0-d4/a0-a2,-(sp)
	exg.l	d0,d1
	movea.l	a0,a2
	bsr.w	X_FF069C
	subq.w	#$1,d1
LFF02D8	moveq	#$3,d0
	move.w	(a2)+,d2
	clr.w	d3
LFF02DE	move.w	d2,d4
	andi.w	#$F,d4
	lsr.w	#$1,d4
	move.b	(a1,d4.w),d4
	btst	#$0,d2
	bne.w	LFF02F4
	lsr.w	#$4,d4
LFF02F4	andi.w	#$F,d4
	or.b	d4,d3
	ror.w	#$4,d3
	ror.w	#$4,d2
	dbra	d0,LFF02DE
	move.w	d3,(a0)
	dbra	d1,LFF02D8
	movem.l	(sp)+,d0-d4/a0-a2
	move.w	(sp)+,$23C6E8.l
	move.w	(sp)+,sr
	rts
	movem.l	d0-d1/a0-a1,-(sp)
	move.w	d1,d0
	bne.w	LFF0324
	move.w	#$100,d0
LFF0324	btst	#$0,d3
	beq.w	LFF037A
	lsr.w	#$5,d0
	subq.w	#$1,d0
LFF0330	lea.l	$20(a1),a1
	move.b	(a3)+,d1
	dbne	d0,LFF0330
	beq.w	LFF03A4
	add.w	d4,d1
	subq.w	#$1,d1
	asl.w	#$5,d1
	movea.l	#$C00000,a0
	asl.l	#$2,d1
	lsr.w	#$2,d1
	ori.w	#$4000,d1
	swap	d1
	andi.w	#$3,d1
	move.l	d1,$4(a0)
	clr.w	d1
	lea.l	-$20(a1),a1
	move.l	(a1)+,(a0)
	move.l	(a1)+,(a0)
	move.l	(a1)+,(a0)
	move.l	(a1)+,(a0)
	move.l	(a1)+,(a0)
	move.l	(a1)+,(a0)
	move.l	(a1)+,(a0)
	move.l	(a1)+,(a0)
	dbra	d0,LFF0330
	bra.w	LFF03A4
LFF037A	lsr.w	#$1,d0
	move.w	d3,d1
	add.w	d0,d3
	add.w	d0,d3
	movea.l	a1,a0
	tst.l	$FF2912.l
	beq.w	LFF039C
	movea.l	$FF2912.l,a1
	bsr.w	LFF02B6
	bra.w	LFF03A4
LFF039C	bsr.w	LFF03D2
	bra.w	LFF03A4
LFF03A4	movem.l	(sp)+,d0-d1/a0-a1
	rts
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	moveq	#$0,d0
	bsr.w	X_FF069C
	move.w	#$3FFF,d0
	clr.l	d1
LFF03C4	move.l	d1,(a0)
	dbra	d0,LFF03C4
	move.w	(sp)+,$23C6E8.l
	rts
LFF03D2	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	bsr.w	LFF0418
	move.w	(sp)+,$23C6E8.l
	rts
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	bsr.w	LFF0406
	move.w	(sp)+,$23C6E8.l
	rts
LFF0406	lea.l	$23A450.l,a1
	move.w	(a1)+,d0
	move.w	(a1)+,d1
	movea.l	(a1)+,a0
	adda.l	#$180000,a0
LFF0418	movem.l	d2-d3/a1,-(sp)
	move.w	d0,d2
	add.w	d2,d2
	add.w	a0,d2
	bcc.w	LFF044A
	beq.w	LFF044A
	lsr.w	#$1,d2
	sub.w	d2,d0
	movem.l	d0/a0,-(sp)
	bsr.w	LFF0446
	movem.l	(sp)+,d0/a0
	add.w	d0,d0
	add.w	d0,d1
	adda.w	d0,a0
	move.w	d2,d0
	bra.w	LFF044A
LFF0446	movem.l	d2-d3/a1,-(sp)
LFF044A	lea.l	$C00004.l,a1
	cmpa.l	#$200000,a0
	blt.w	LFF0466
	cmpa.l	#$240000,a0
	bge.w	LFF0466
	addq.l	#$2,a0
LFF0466	move.w	#$8154,(a1)
	move.w	#$8F02,(a1)
	move.w	#$9300,d2
	move.b	d0,d2
	move.w	d2,(a1)
	move.w	#$9400,d2
	lsr.w	#$8,d0
	move.b	d0,d2
	move.w	d2,(a1)
	move.l	a0,d0
	lsr.l	#$1,d0
	move.w	#$9500,d2
	move.b	d0,d2
	move.w	d2,(a1)
	lsr.l	#$8,d0
	move.w	#$9600,d2
	move.b	d0,d2
	move.w	d2,(a1)
	lsr.l	#$8,d0
	andi.b	#$7F,d0
	move.w	#$9700,d2
	move.b	d0,d2
	move.w	d2,(a1)
	clr.l	d0
	move.w	d1,d0
	asl.l	#$2,d0
	lsr.w	#$2,d0
	move.l	d0,d3
	ori.l	#$804000,d0
	move.l	d0,$FF290E.l
	move.w	sr,-(sp)
	move.w	#$2700,sr
	move.w	$FF2910.l,(a1)
	move.w	$FF290E.l,(a1)
	bsr.w	X_FF051C
	move.w	#$8164,(a1)
	cmpa.l	#$200000,a0
	blt.w	LFF04FC
	cmpa.l	#$240000,a0
	bge.w	LFF04FC
	move.l	d3,d0
	ori.w	#$4000,d0
	swap	d0
	andi.w	#$3,d0
	move.l	d0,(a1)
	subq.l	#$2,a0
	move.l	(a0),-$4(a1)
LFF04FC	cmpa.w	#$0,a0
