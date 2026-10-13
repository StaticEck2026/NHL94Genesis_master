; STARTER.BIN FilmOpen, file $4336, runtime $25636.
; Requires the long FILM ($46494C4D). Returns -1 on a bad file.
; See docs/segacd_film.md.

X_263D8	equ	$263D8
X_25606	equ	$25606
X_2609E	equ	$2609E
X_25A88	equ	$25A88
X_25844	equ	$25844
X_262A8	equ	$262A8
X_26126	equ	$26126
X_2584E	equ	$2584E
X_2585A	equ	$2585A
X_25CFA	equ	$25CFA
X_26632	equ	$26632
X_2586A	equ	$2586A
X_2607E	equ	$2607E
X_25546	equ	$25546
X_25E7E	equ	$25E7E
X_25BC4	equ	$25BC4
X_2587C	equ	$2587C
X_25F84	equ	$25F84
X_24FB4	equ	$24FB4

	org	$25636

	link	a6,#$FFFC
	movem.l	d3/d5-d7/a3-a4,-(sp)
	move.l	$8(a6),d5
	move.l	#$C0000,-$4(a6)
	lea.l	X_24FB4(pc),a0
	lea.l	$40(a0),a4
	jsr	X_25F84(pc)
	move.l	d5,-(sp)
	pea.l	X_2587C(pc)
	jsr	X_25BC4(pc)
	moveq	#-1,d0
	move.l	d0,$40(a4)
	pea.l	$800.w
	jsr	X_25E7E(pc)
	movea.l	d0,a3
	move.l	a3,d0
	lea.l	$C(sp),sp
	bne.b	L2567E
	moveq	#-1,d0
	bra.w	L2582E
L2567E	move.l	a3,-(sp)
	moveq	#$1,d0
	move.l	d0,-(sp)
	move.l	d5,-(sp)
	jsr	X_25546(pc)
	jsr	X_2607E(pc)
	cmpi.l	#$46494C4D,(a3)
	lea.l	$C(sp),sp
	beq.b	L256AC
	move.l	d5,-(sp)
	pea.l	X_2586A(pc)
	jsr	X_25BC4(pc)
	moveq	#-1,d0
	addq.w	#$8,sp
	bra.w	L2582E
L256AC	move.l	$4(a3),d7
	move.l	d7,d0
	; SNASM rewrites add.l #imm,dn into addi.l. The disc is D0BC.
	dc.w	$D0BC
	dc.l	$000007FF
	move.l	#$800,d1
	jsr	X_26632(pc)
	move.l	d0,d6
	moveq	#$1,d0
	cmp.l	d6,d0
	bge.b	L25714
	move.l	a3,-(sp)
	jsr	X_25CFA(pc)
	move.l	d6,d1
	move.l	d1,d0
	mulu.w	#$800,d1
	swap	d0
	mulu.w	#$800,d0
	swap	d0
	clr.w	d0
	add.l	d0,d1
	move.l	d1,-(sp)
	jsr	X_25E7E(pc)
	movea.l	d0,a3
	move.l	a3,d0
	addq.w	#$8,sp
	bne.b	L256F8
	moveq	#-1,d0
	bra.w	L2582E
L256F8	move.l	d6,-(sp)
	pea.l	X_2585A(pc)
	jsr	X_25BC4(pc)
	move.l	a3,-(sp)
	move.l	d6,-(sp)
	move.l	d5,-(sp)
	jsr	X_25546(pc)
	jsr	X_2607E(pc)
	lea.l	$14(sp),sp
L25714	move.l	$4(a3),$8(a4)
	move.l	a3,d0
	moveq	#$10,d1
	add.l	d1,d0
	move.l	d0,$C(a4)
	movea.l	d0,a0
	move.l	$4(a0),d0
	add.l	$C(a4),d0
	move.l	d0,$10(a4)
	move.l	a3,$14(a4)
	pea.l	X_2584E(pc)
	jsr	X_25BC4(pc)
	move.l	d5,-(sp)
	pea.l	$18(a4)
	jsr	X_26126(pc)
	tst.w	d0
	lea.l	$C(sp),sp
	beq.b	L25756
	moveq	#-1,d0
	bra.w	L2582E
L25756	pea.l	$18(a4)
	jsr	X_262A8(pc)
	pea.l	X_25844(pc)
	jsr	X_25BC4(pc)
	moveq	#$0,d5
	move.l	d5,d6
	move.l	d6,d7
	addq.w	#$8,sp
	bra.b	L25796
L25770	movea.l	$10(a4),a0
	move.l	d7,d0
	asl.l	#$4,d0
	lea.l	$10(a0,d0.l),a3
	moveq	#-1,d0
	cmp.l	$8(a3),d0
	seq.b	d3
	neg.b	d3
	beq.b	L2578E
	move.l	d5,d0
	addq.l	#$1,d5
	bra.b	L25792
L2578E	move.l	d6,d0
	addq.l	#$1,d6
L25792	move.l	d7,d0
	addq.l	#$1,d7
L25796	movea.l	$10(a4),a0
	cmp.l	$C(a0),d7
	blt.b	L25770
	lea.l	X_24FB4(pc),a0
	moveq	#$0,d0
	move.l	d0,$3C(a0)
	tst.l	d6
	bne.b	L257B8
	lea.l	X_24FB4(pc),a0
	moveq	#-1,d0
	move.l	d0,$3C(a0)
L257B8	tst.l	d5
	bne.b	L257C6
	lea.l	X_24FB4(pc),a0
	moveq	#$1,d0
	move.l	d0,$3C(a0)
L257C6	lea.l	X_24FB4(pc),a0
	movea.l	-$4(a6),a1
	move.l	$20(a0),(a1)
	lea.l	X_24FB4(pc),a0
	lea.l	X_24FB4(pc),a1
	move.l	$28(a1),d0
	add.l	d0,d0
	add.l	$24(a0),d0
	lea.l	X_24FB4(pc),a0
	move.l	$2C(a0),d1
	asl.l	#$7,d1
	add.l	d0,d1
	movea.l	-$4(a6),a0
	move.l	d1,$4(a0)
	lea.l	X_24FB4(pc),a0
	movea.l	-$4(a6),a1
	move.l	$30(a0),$8(a1)
	jsr	X_25A88(pc)
	moveq	#$3,d0
	move.l	d0,-(sp)
	jsr	X_2609E(pc)
	moveq	#$0,d0
	move.l	d0,$40(a4)
	moveq	#$3C,d0
	move.l	d0,-(sp)
	jsr	X_25606(pc)
	pea.l	$30(a4)
	jsr	X_263D8(pc)
	moveq	#$0,d0
	lea.l	$C(sp),sp
L2582E	movem.l	-$1C(a6),d3/d5-d7/a3-a4
	unlk	a6
	rts
