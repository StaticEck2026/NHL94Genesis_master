; HOCKEY.BIN CD start, $24D66-$24DE7.
; CDCSETMODE ($96) with d1=2 (CD-DA), MSCSEEK ($15) track 4, MSCPLAYR ($13)
; track 4, then FDRSET ($85) volume $400 and master volume $8400.

	org	$24D66

	bclr.b	#$5,$FF800F.l
	jsr	$375F4.l
	jsr	$376D4.l
	st.b	$191CE.l
	moveq	#$0,d0
	tst.w	$3FC0A.l
	beq.b	L24D90
	jsr	$37752.l
L24D90	jsr	$21FC8.l
	move.w	#$2,d1
	move.w	#$96,d0
	jsr	$5F22.w
	jsr	$222D6.l
	move.w	#$4,$19364.l
	lea.l	$19364.l,a0
	move.w	#$15,d0
	jsr	$5F22.w
	lea.l	$19364.l,a0
	move.w	#$13,d0
	jsr	$5F22.w
	move.l	#$400,d1
	move.w	#$85,d0
	jsr	$5F22.w
	move.w	#$8400,d1
	move.w	#$85,d0
	jsr	$5F22.w
	rts
