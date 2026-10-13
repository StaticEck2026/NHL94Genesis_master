; STARTER.BIN FilmTask, file $458C, runtime $2588C.
; Steps one 16-byte record. An SM chunk ($534D) goes to filmsm.
; See docs/segacd_film.md.

X_2609E	equ	$2609E
X_25A88	equ	$25A88
X_265B2	equ	$265B2
X_251AA	equ	$251AA
X_26368	equ	$26368
X_265E8	equ	$265E8
X_26480	equ	$26480
X_262FC	equ	$262FC
X_2640C	equ	$2640C
X_262A8	equ	$262A8
X_264DE	equ	$264DE
X_24FB4	equ	$24FB4

	org	$2588C

	link	a6,#$FFFC
	movem.l	d7/a3-a4,-(sp)
	move.l	#$C0000,-$4(a6)
	lea.l	X_24FB4(pc),a0
	lea.l	$40(a0),a4
	lea.l	X_24FB4(pc),a0
	tst.l	$38(a0)
	beq.b	L258B4
	moveq	#-2,d0
	bra.w	L25A24
L258B4	tst.l	$40(a4)
	bge.b	L258C0
	moveq	#-1,d0
	bra.w	L25A24
L258C0	lea.l	X_24FB4(pc),a0
	moveq	#$1,d0
	cmp.l	$3C(a0),d0
	bne.b	L258D6
	pea.l	$30(a4)
	jsr	X_264DE(pc)
	addq.w	#$4,sp
L258D6	movea.l	$10(a4),a0
	move.l	$40(a4),d0
	addq.l	#$1,$40(a4)
	asl.l	#$4,d0
	lea.l	$10(a0,d0.l),a3
	moveq	#-1,d0
	cmp.l	$8(a3),d0
	bne.w	L25988
	bra.b	L25906
L258F4	pea.l	$18(a4)
	jsr	X_262A8(pc)
	pea.l	$30(a4)
	jsr	X_2640C(pc)
	addq.w	#$8,sp
L25906	move.l	$4(a3),-(sp)
	move.l	(a3),d0
	add.l	$8(a4),d0
	move.l	d0,-(sp)
	pea.l	$18(a4)
	jsr	X_262FC(pc)
	move.l	d0,d7
	lea.l	$C(sp),sp
	beq.b	L258F4
	move.l	$4(a3),-(sp)
	move.l	d7,-(sp)
	pea.l	$30(a4)
	jsr	X_26480(pc)
	lea.l	X_24FB4(pc),a0
	moveq	#-1,d0
	cmp.l	$3C(a0),d0
	lea.l	$C(sp),sp
	bne.b	L2595A
	bra.b	L2594C
L25942	pea.l	$30(a4)
	jsr	X_2640C(pc)
	addq.w	#$4,sp
L2594C	pea.l	$30(a4)
	jsr	X_265E8(pc)
	tst.w	d0
	addq.w	#$4,sp
	bne.b	L25942
L2595A	move.l	$4(a3),-(sp)
	move.l	(a3),d0
	add.l	$8(a4),d0
	move.l	d0,-(sp)
	pea.l	$18(a4)
	jsr	X_26368(pc)
	lea.l	$C(sp),sp
	bra.w	L25A0C
L25976	pea.l	$30(a4)
	jsr	X_2640C(pc)
	pea.l	$18(a4)
	jsr	X_262A8(pc)
	addq.w	#$8,sp
L25988	move.l	$4(a3),-(sp)
	move.l	(a3),d0
	add.l	$8(a4),d0
	move.l	d0,-(sp)
	pea.l	$18(a4)
	jsr	X_262FC(pc)
	move.l	d0,d7
	lea.l	$C(sp),sp
	beq.b	L25976
	movea.l	d7,a0
	cmpi.w	#$534D,(a0)
	bne.b	L259F4
	move.l	d7,-(sp)
	move.l	-$4(a6),-(sp)
	jsr	X_251AA(pc)
	move.l	#$7FFFFFFF,d7
	and.l	$8(a3),d7
	bra.b	L259D4
L259C2	pea.l	$30(a4)
	jsr	X_2640C(pc)
	pea.l	$18(a4)
	jsr	X_262A8(pc)
	addq.w	#$8,sp
L259D4	pea.l	$258.w
	pea.l	$30(a4)
	jsr	X_265B2(pc)
	cmp.l	d0,d7
	addq.w	#$8,sp
	bgt.b	L259C2
	jsr	X_25A88(pc)
	moveq	#$2,d0
	move.l	d0,-(sp)
	jsr	X_2609E(pc)
	addq.w	#$4,sp
L259F4	move.l	$4(a3),-(sp)
	move.l	(a3),d0
	add.l	$8(a4),d0
	move.l	d0,-(sp)
	pea.l	$18(a4)
	jsr	X_26368(pc)
	lea.l	$C(sp),sp
L25A0C	movea.l	$10(a4),a0
	move.l	$40(a4),d0
	cmp.l	$C(a0),d0
	bne.b	L25A20
	moveq	#-1,d0
	move.l	d0,$40(a4)
L25A20	move.l	$40(a4),d0
L25A24	movem.l	-$10(a6),d7/a3-a4
	unlk	a6
	rts
