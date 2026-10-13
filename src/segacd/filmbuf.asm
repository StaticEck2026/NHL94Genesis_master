; STARTER.BIN film buffer, file $4E26, runtime $26126.
; Asks $25E34 for a size, clamps it to $14000-$34000, and allocates
; that many bytes plus $4000. See docs/segacd_film.md.

X_262A8	equ	$262A8
X_24FB4	equ	$24FB4
X_25E7E	equ	$25E7E
X_26632	equ	$26632
X_25E34	equ	$25E34

	org	$26126

	link	a6,#$0
	movem.l	d7/a4,-(sp)
	movea.l	$8(a6),a4
	jsr	X_25E34(pc)
	move.l	d0,d7
	cmpi.l	#$14000,d7
	bge.b	L26144
	moveq	#-1,d0
	bra.b	L261B6
L26144	cmpi.l	#$34000,d7
	ble.b	L26152
	move.l	#$34000,d7
L26152	move.l	d7,d0
	; SNASM rewrites sub.l #imm,dn into subi.l. The disc is 90BC.
	dc.w	$90BC
	dc.l	$00004000
	move.l	#$800,d1
	jsr	X_26632(pc)
	move.l	d0,d1
	mulu.w	#$800,d0
	swap	d1
	mulu.w	#$800,d1
	swap	d1
	clr.w	d1
	add.l	d1,d0
	move.l	d0,$4(a4)
	; SNASM rewrites add.l #imm,dn into addi.l. The disc is D0BC.
	dc.w	$D0BC
	dc.l	$00004000
	move.l	d0,-(sp)
	jsr	X_25E7E(pc)
	move.l	d0,(a4)
	addq.w	#$4,sp
	bne.b	L26190
	moveq	#-1,d0
	bra.b	L261B6
L26190	moveq	#$0,d0
	move.l	d0,$8(a4)
	move.l	d0,$C(a4)
	move.l	$C(a6),$10(a4)
	move.l	d0,$14(a4)
	lea.l	X_24FB4(pc),a0
	move.l	a4,$1C(a0)
	move.l	a4,-(sp)
	jsr	X_262A8(pc)
	moveq	#$0,d0
	addq.w	#$4,sp
L261B6	movem.l	-$8(a6),d7/a4
	unlk	a6
	rts
