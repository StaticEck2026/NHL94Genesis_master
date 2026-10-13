; STARTER.BIN CD-DA helpers, file $54F6-$556D, runtime $267F6-$2686D.
; Seek a track and repeat it, ramp the fader, or stop.
; $15 MSCSEEK, $13 MSCPLAYR, $86 FDRCHG, $02 MSCSTOP. _CDBIOS is $5F22.

	org	$267F6

	movem.l	d0-d7/a0-a6,-(sp)
	move.w	$40(sp),$10AD4.l
	lea.l	$10AD4.l,a0
	move.w	#$15,d0
	jsr	$5F22.w
	lea.l	$10AD4.l,a0
	move.w	#$13,d0
	jsr	$5F22.w
	move.l	#$400,d1
	move.w	#$86,d0
	jsr	$5F22.w
	moveq	#$1E,d0
	jsr	$E118.l
	movem.l	(sp)+,d0-d7/a0-a6
	move.l	(sp),$2(sp)
	addq.l	#$2,sp
	rts
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	$40(sp),d1
	move.w	#$86,d0
	jsr	$5F22.w
	movem.l	(sp)+,d0-d7/a0-a6
	move.l	(sp),$4(sp)
	addq.l	#$4,sp
	rts
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#$2,d0
	jsr	$5F22.w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
