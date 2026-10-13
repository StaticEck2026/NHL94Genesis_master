; HOCKEY.BIN scouting screen open, $D2B6-$D397.
; Points the stack at $1745C, then starts song $7A (cartridge SngScout).
; $371D2 is song. The body is in the $37xxx library, outside these files.

	org	$D2B6

	move.l	sp,$47D00.l
	movea.l	#$1745C,sp
	movea.l	$47DA4.l,a0
	movea.l	#$C458,a1
	move.w	#$DAC,d0
LD2D2	move.l	(a0)+,(a1)+
	dbra	d0,LD2D2
	move.l	$47DA4.l,d1
	subi.l	#$C458,d1
	sub.l	d1,$47DA4.l
	sub.l	d1,$47D3C.l
	sub.l	d1,$47D98.l
	sub.l	d1,$47D9C.l
	jsr	$2262E.l
	jsr	$231A0.l
	clr.w	$1A446.l
	move.w	#$7A,-(sp)
	jsr	$371D2.l
	move.l	#$3DB90,$18D66.l
	jsr	$3F11E.l
	move.l	a0,-(sp)
	movea.l	#$1834C,a0
	jsr	$2308E.l
	movea.l	#$186B2,a0
	jsr	$2308E.l
	movea.l	(sp)+,a0
	jsr	$231A0.l
	bclr.b	#$1,$18D64.l
	move.w	#$6,$18D36.l
	move.w	#$6,$18D3A.l
	move.w	#$0,d0
	jsr	$37B5A.l
	move.w	#$2,d4
	move.w	d4,$19392.l
	addi.w	#$24,d4
	move.w	d4,$19394.l
	addi.w	#$24,d4
	move.w	d4,$18D40.l
	movea.l	$47D38.l,a2
	addq.l	#$8,a2
	jsr	$38946.l
