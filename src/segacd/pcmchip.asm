; STARTER.BIN PCM chip primitives, file $3FD0-$40F9, runtime $252D0-$253F9.
; Init, start channel 0, stop, read the play address, load one $1000-byte bank.

	org	$252D0

	movea.l	#$FF0000,a0
	move.b	#$FF,$11(a0)
	moveq	#$14,d0
L252DE	dbra	d0,L252DE
	move.b	#$C0,$F(a0)
	moveq	#$14,d0
L252EA	dbra	d0,L252EA
	move.b	#$FF,$1(a0)
	moveq	#$14,d0
L252F6	dbra	d0,L252F6
	move.b	#$FF,$3(a0)
	moveq	#$14,d0
L25302	dbra	d0,L25302
	move.b	#$4,$7(a0)
	moveq	#$14,d0
L2530E	dbra	d0,L2530E
	clr.b	$5(a0)
	moveq	#$14,d0
L25318	dbra	d0,L25318
	clr.b	$B(a0)
	moveq	#$14,d0
L25322	dbra	d0,L25322
	clr.b	$9(a0)
	moveq	#$14,d0
L2532C	dbra	d0,L2532C
	clr.b	$D(a0)
	moveq	#$14,d0
L25336	dbra	d0,L25336
	move.w	#$88,d0
	move.b	d0,$F(a0)
	moveq	#$14,d0
L25344	dbra	d0,L25344
	move.b	#$FF,$2001(a0)
	move.b	#$FF,$2002(a0)
	rts
	movea.l	#$FF0000,a0
	move.b	#$80,$F(a0)
	moveq	#$14,d0
L25364	dbra	d0,L25364
	move.b	#$FE,$11(a0)
	rts
	movea.l	#$FF0000,a0
	move.b	#$FF,$11(a0)
	rts
	movea.l	#$FF0000,a0
	lea.l	$21(a0),a0
	moveq	#$14,d0
L2538A	dbra	d0,L2538A
	move.b	(a0),d1
	move.b	(a0),d1
	addq.w	#$2,a0
	moveq	#$14,d0
L25396	dbra	d0,L25396
	moveq	#$0,d0
	move.b	(a0),d0
	move.b	(a0),d0
	lsl.w	#$8,d0
	move.b	d1,d0
	rts
	movea.l	#$FF0000,a0
	move.l	$8(sp),d0
	ori.w	#$80,d0
	move.b	d0,$F(a0)
	moveq	#$14,d0
L253BA	dbra	d0,L253BA
	move.b	d0,$F(a0)
	moveq	#$14,d0
L253C4	dbra	d0,L253C4
	lea.l	$2001(a0),a0
	movea.l	$4(sp),a1
	move.w	#$1FF,d3
L253D4	move.b	(a1)+,(a0)
	addq.w	#$2,a0
	move.b	(a1)+,(a0)
	addq.w	#$2,a0
	move.b	(a1)+,(a0)
	addq.w	#$2,a0
	move.b	(a1)+,(a0)
	addq.w	#$2,a0
	move.b	(a1)+,(a0)
	addq.w	#$2,a0
	move.b	(a1)+,(a0)
	addq.w	#$2,a0
	move.b	(a1)+,(a0)
	addq.w	#$2,a0
	move.b	(a1)+,(a0)
	addq.w	#$2,a0
	dbra	d3,L253D4
	rts
