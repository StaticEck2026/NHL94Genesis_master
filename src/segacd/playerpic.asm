; PLAYER.BIN photo picker, $1D54-$200F.
; Selects a real photo or a generic $504-byte frame, copies it to $BC000,
; and posts gate commands $B and $D so the main CPU can DMA it.
; See docs/segacd_stats.md.

X_1B9C	equ	$1B9C
X_EBC	equ	$EBC
X_10D8	equ	$10D8
X_281C	equ	$281C
X_F64	equ	$F64
X_2D3A	equ	$2D3A
X_2010	equ	$2010
X_45C8	equ	$45C8
X_40C4	equ	$40C4
X_6DE8	equ	$6DE8
X_68E4	equ	$68E4
X_295B	equ	$295B
X_2966	equ	$2966
X_3C16	equ	$3C16
X_2AA0	equ	$2AA0

	org	$1D54

	movem.l	d0-d7/a0-a4,-(sp)
	movea.l	$1C(a6),a1
	movea.l	$48(a6),a2
	cmpi.w	#$0,$18(a6)
	beq.w	L1D72
	movea.l	$20(a6),a1
	movea.l	$4C(a6),a2
L1D72	bsr.w	X_2AA0
	move.w	#$D3,d0
	move.w	#$1E,d1
	bsr.w	X_3C16
	movea.l	$50(a6),a3
	tst.l	$44(a6)
	bne.w	L1DA2
	tst.b	$5(a3)
	beq.w	L1D9E
	lea.l	X_2966(pc),a0
	bra.w	L1DA2
L1D9E	lea.l	X_295B(pc),a0
L1DA2	move.w	$80(a6),d0
	add.w	d0,d0
	tst.w	(a2,d0.w)
	bmi.w	L1DBA
	add.w	d0,d0
	movea.l	(a1,d0.w),a1
	bra.w	L1E28
L1DBA	moveq	#$0,d0
	tst.b	$5(a3)
	bne.w	L1DF8
	btst.b	#$0,$4(a3)
	beq.w	L1DD6
	lea.l	X_68E4(pc),a1
	bra.w	L1E28
L1DD6	lea.l	X_6DE8(pc),a1
	move.b	$104(a6),d0
	cmpi.b	#$3,d0
	blt.w	L1DEC
	clr.w	d0
	move.b	d0,$104(a6)
L1DEC	mulu.w	#$504,d0
	lea.l	(a1,d0.l),a1
	bra.w	L1E28
L1DF8	btst.b	#$0,$4(a3)
	beq.w	L1E0A
	lea.l	X_40C4(pc),a1
	bra.w	L1E28
L1E0A	lea.l	X_45C8(pc),a1
	move.b	$105(a6),d0
	cmpi.b	#$7,d0
	blt.w	L1E20
	clr.w	d0
	move.b	d0,$105(a6)
L1E20	mulu.w	#$504,d0
	lea.l	(a1,d0.l),a1
L1E28	move.w	$EE(a6),d0
	bsr.w	X_2010
	lea.l	$2(a1),a1
	move.w	(a1)+,d0
	lsl.w	#$4,d0
	move.w	d0,$E0(a6)
	move.w	#$EB00,$E2(a6)
	movea.l	#$BC000,a2
	move.l	a2,$E4(a6)
	subq.w	#$1,d0
L1E4E	move.w	(a1)+,(a2)+
	dbra	d0,L1E4E
	move.w	#$1,$DE(a6)
L1E5A	tst.w	$DE(a6)
	bne.w	L1E5A
	movea.l	#$BBCF0,a2
	moveq	#$7,d0
	lea.l	$20(a1),a1
L1E6E	move.l	(a1)+,(a2)+
	dbra	d0,L1E6E
	move.l	#$EEE,$BBCF0.l
	move.w	#$444,$BBCB0.l
	move.w	#$444,$BBCD0.l
	move.w	#$444,$BBCF0.l
	move.w	#$444,$BBD10.l
	move.w	#$758,d5
	bset	#$E,d5
	move.w	#$B286,d3
	move.w	#$80,d6
	moveq	#$5,d1
	move.w	d1,d7
	move.w	d1,d2
L1EB4	move.w	d3,d4
	bsr.w	X_2D3A
L1EBA	btst.b	#$7,$FF800E.l
	bne.b	L1EBA
	move.l	d4,$FF8022.l
	move.w	#$B,$FF8020.l
	bset.b	#$6,$FF800F.l
L1EDA	btst.b	#$6,$FF800E.l
	beq.b	L1EDA
	bset.b	#$7,$FF800F.l
	bclr.b	#$6,$FF800F.l
L1EF4	btst.b	#$6,$FF800E.l
	bne.b	L1EF4
	bclr.b	#$7,$FF800F.l
L1F06	move.w	d5,d4
L1F08	btst.b	#$7,$FF800E.l
	bne.b	L1F08
	move.w	d4,$FF8022.l
	move.w	#$D,$FF8020.l
	bset.b	#$6,$FF800F.l
L1F28	btst.b	#$6,$FF800E.l
	beq.b	L1F28
	bset.b	#$7,$FF800F.l
	bclr.b	#$6,$FF800F.l
L1F42	btst.b	#$6,$FF800E.l
	bne.b	L1F42
	bclr.b	#$7,$FF800F.l
	addi.w	#$1,d5
	dbra	d1,L1F06
	add.w	d6,d3
	move.w	d7,d1
	dbra	d2,L1EB4
	cmpi.w	#$0,$B0(a6)
	beq.w	L1FD8
	cmpi.w	#$2,$B0(a6)
	ble.w	L1F88
	move.w	#$E,d0
	move.w	#$0,d1
	bsr.w	X_F64
	bra.w	L1FBE
L1F88	moveq	#$10,d0
	moveq	#$0,d1
	bsr.w	X_F64
	cmpi.w	#$2,$B0(a6)
	bne.w	L1FBE
	move.w	#$50,d0
	move.w	$EE(a6),d1
	subi.w	#$2000,d1
	addi.w	#$F00,d1
	swap	d1
	move.w	#$100,d1
	move.l	#$B8000080,d2
	move.w	#$0,d3
	bsr.w	X_281C
L1FBE	move.w	$B0(a6),d0
	bsr.w	X_10D8
	move.w	#$0,$B0(a6)
	moveq	#$1C,d0
	moveq	#$0,d1
	bsr.w	X_F64
	bsr.w	X_EBC
L1FD8	move.w	#$50,d0
	move.w	$EE(a6),d1
	subi.w	#$2000,d1
	swap	d1
	move.w	#$100,d1
	move.l	#$B0000080,d2
	move.w	#$1B,d3
	bsr.w	X_281C
	move.w	#$0,$B0(a6)
	moveq	#$0,d0
	moveq	#$0,d1
	bsr.w	X_F64
	bsr.w	X_1B9C
	movem.l	(sp)+,d0-d7/a0-a4
	rts
