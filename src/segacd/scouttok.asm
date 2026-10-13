; HOCKEY.BIN scouting script tokens, $24A8A-$24C09.
; The special bytes in the Ron Barr script: team, player, arena, crowd record.
; ScrollDisplayUp is the tail. It does not start a sample.

X_21000	equ	$21000
X_24A50	equ	$24A50

	org	$24A8A

	jsr	$281D4.l
	bra.w	L24B92
	jsr	$2ADB2.l
	bra.w	L24B92
	jsr	$2AE5A.l
	bra.w	L24B92
	move.l	a2,-(sp)
	movea.l	#$1834C,a2
	jsr	$29164.l
	movea.l	(sp)+,a2
	bra.w	L24B92
	move.l	a2,-(sp)
	movea.l	#$186B2,a2
	jsr	$29164.l
	movea.l	(sp)+,a2
	bra.w	L24B92
	move.l	a2,-(sp)
	movea.l	#$1834C,a2
	jsr	$291AA.l
	movea.l	(sp)+,a2
	bra.w	L24B92
	move.l	a2,-(sp)
	movea.l	#$186B2,a2
	jsr	$291AA.l
	movea.l	(sp)+,a2
	bra.w	L24B92
	jsr	$23132.l
	bra.w	L24B56
	jsr	$23168.l
	bra.w	L24B56
	jsr	$2328E.l
	bra.w	L24B56
	jsr	$232C4.l
	bra.w	L24B56
	movea.l	#$1834C,a1
	tst.w	$17EA0.l
	beq.w	L24B36
	movea.l	#$186B2,a1
L24B36	movea.l	$1E(a1),a1
	adda.w	$4(a1),a1
	bra.w	L24B92
	movea.l	#$186B2,a1
	bra.w	L24B52
	movea.l	#$1834C,a1
L24B52	move.w	$28(a1),d1
L24B56	movea.l	$1E(a1),a1
	adda.w	$0(a1),a1
	bra.w	L24B68
L24B62	adda.w	(a1),a1
	adda.w	#$8,a1
L24B68	dbra	d1,L24B62
	bra.w	L24B92
	movea.l	$186D0.l,a1
	adda.w	$4(a1),a1
	bra.w	L24B92
	movea.l	$186D0.l,a1
	bra.w	L24B8E
	movea.l	$1836A.l,a1
L24B8E	adda.w	$4(a1),a1
L24B92	addi.w	#$1,$1A452.l
	add.w	(a1),d0
	subi.w	#$1,d0
	move.w	(a1),d1
	subi.w	#$2,d1
	tst.b	$1(a1,d1.w)
	bne.w	X_24A50
	subi.w	#$1,d1
	bra.w	X_24A50
	clr.w	$1A44E.l
	addi.w	#$1,$1A450.l
	cmpi.w	#$7,$1A450.l
	blt.w	X_21000
	subi.w	#$1,$1A450.l
	movem.l	d0-d3,-(sp)
	moveq	#$7,d3
	move.w	$18D34.l,d1
	addi.w	#$212,d1
L24BE8	moveq	#$3A,d0
	move.w	d1,d2
	addi.w	#$80,d2
	move.w	sr,-(sp)
	move.w	#$2700,sr
	jsr	$379D6.l
	move.w	(sp)+,sr
	move.w	d2,d1
	dbra	d3,L24BE8
	movem.l	(sp)+,d0-d3
	rts
