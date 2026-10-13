; MAIN.BIN $CB8-$12BF ($FF0CB8-$FF12BF). Emitted by tools/emit_m68k.py.
; Byte-stream decoder and gate-array flag handshakes. 16-long table at $FF1280.

X_FF0316	equ	$FF0316
X_FF051C	equ	$FF051C
X_FF0278	equ	$FF0278
X_FF0B42	equ	$FF0B42
X_FF06B6	equ	$FF06B6

	org	$FF0CB8

	bsr.w	LFF0CE2
	bsr.w	LFF0CCC
	bsr.w	LFF0D34
	bsr.w	LFF0CF4
	bra.w	LFF0D04
LFF0CCC	move.b	(a1)+,d0
	subq.w	#$1,d3
	andi.w	#$3,d0
	asl.w	#$2,d0
	subq.w	#$4,d0
	move.w	d0,$FF2DB8.l
	bra.w	X_FF06B6
LFF0CE2	move.b	(a1)+,d2
	andi.w	#$7,d2
	subq.w	#$1,d3
	ror.w	#$3,d2
	move.w	d2,$FF2DB6.l
	rts
LFF0CF4	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#$1,d3
	move.w	d0,$FF2DB2.l
	bra.w	X_FF06B6
LFF0D04	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#$1,d3
	move.w	d0,$FF2DB4.l
	bra.w	X_FF06B6
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#$1,d3
	add.w	d0,$FF2DB2.l
	bra.w	X_FF06B6
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#$1,d3
	add.w	d0,$FF2DB4.l
	bra.w	X_FF06B6
LFF0D34	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#$1,d3
	add.w	d0,d0
	move.w	d0,$FF2DBA.l
	rts
	lea.l	$23A450.l,a2
	move.w	(a2)+,$FF2DB6.l
	move.w	(a2)+,$FF2DB2.l
	move.w	(a2)+,$FF2DB4.l
	move.w	(a2)+,$FF2DBA.l
	move.w	(a2)+,$FF2DB8.l
	move.w	(a2)+,$FF287A.l
	move.w	(a2)+,$FF287C.l
	move.w	(a2)+,$FF287E.l
	movea.l	a2,a1
	bsr.w	X_FF0B42
	lea.l	$23A450.l,a2
	move.w	$FF2DB6.l,(a2)+
	move.w	$FF2DB2.l,(a2)+
	move.w	$FF2DB4.l,(a2)+
	move.w	$FF2DBA.l,(a2)+
	move.w	$FF2DB8.l,(a2)
	rts
	move.l	a1,-(sp)
	movea.l	$4(sp),a1
	bsr.w	X_FF0B42
	move.l	a1,$4(sp)
	movea.l	(sp)+,a1
	rts
	lea.l	$23A450.l,a1
	move.w	(a1)+,$FF2DB6.l
	move.w	(a1)+,$FF2DB2.l
	move.w	(a1)+,$FF2DB4.l
	move.w	(a1)+,$FF2DBA.l
	move.w	(a1)+,$FF2DB8.l
	move.w	(a1)+,$FF287A.l
	move.w	(a1)+,$FF287C.l
	move.w	(a1)+,$FF287E.l
	bsr.w	X_FF0B42
	lea.l	$23A450.l,a1
	move.w	$FF2DB6.l,(a1)+
	move.w	$FF2DB2.l,(a1)+
	move.w	$FF2DB4.l,(a1)+
	move.w	$FF2DBA.l,(a1)+
	move.w	$FF2DB8.l,(a1)
	rts
	lea.l	$23A450.l,a0
	lea.l	$FF2860.l,a1
LFF0E24	move.w	(a0)+,(a1)+
	cmpa.l	#$FF2884,a1
	blt.b	LFF0E24
	rts
	lea.l	$23A450.l,a0
	move.w	(a0)+,d1
	movea.l	(a0)+,a1
	move.w	(a0)+,$FF2DB2.l
	move.w	(a0)+,$FF2DB4.l
	move.w	(a0)+,$FF2DB8.l
	adda.l	#$180000,a1
	bset.b	#$4,$23C6E8.l
	bsr.w	X_FF06B6
	neg.w	d1
	addq.w	#$3,d1
	moveq	#$2,d2
LFF0E64	move.w	(a1),d0
	cmp.b	d2,d1
	ble.w	LFF0E70
	move.w	$2(a1),d0
LFF0E70	add.w	$FF286C.l,d0
	move.w	d0,(a0)
	dbra	d2,LFF0E64
	bclr.b	#$4,$23C6E8.l
	rts
	rts
	move.w	$C00008.l,$23A450.l
	rts
	lea.l	$23A450.l,a0
	move.l	(a0)+,d4
	movea.l	(a0)+,a2
	move.l	a0,$FF2912.l
	adda.l	#$180000,a2
	bsr.w	X_FF0278
	lea.l	$23A450.l,a0
	move.l	d4,(a0)
	rts
	lea.l	$23A450.l,a5
	addq.l	#$4,a5
	move.w	(a5)+,d4
	move.w	(a5)+,d2
	movea.l	(a5)+,a1
	adda.l	#$180000,a1
	move.w	(a5)+,$FF2DB2.l
	move.w	(a5)+,$FF2DB4.l
	move.w	(a5)+,$FF2DB6.l
	move.w	(a5)+,$FF2DB8.l
	lea.l	$23A450.l,a5
	bsr.w	LFF0EFA
	addq.l	#$4,a5
	move.w	d4,(a5)+
	move.w	$FF2DB4.l,(a5)
	rts
LFF0EFA	bsr.w	X_FF06B6
	addq.w	#$1,$FF2DB4.l
	bsr.w	LFF0F22
	addq.w	#$2,d4
	move.w	$0(a5),d0
	subq.w	#$3,d0
LFF0F10	bsr.w	LFF0F22
	dbra	d0,LFF0F10
	addq.w	#$2,d4
	bsr.w	LFF0F22
	addq.w	#$2,d4
	rts
LFF0F22	move.w	(a1,d4.w),d3
	add.w	d2,d3
	move.w	d3,(a0)
	rts
	bset.b	#$0,$A12018.l
LFF0F34	btst.b	#$0,$A12028.l
	beq.b	LFF0F34
	bclr.b	#$0,$A12018.l
LFF0F46	btst.b	#$0,$A12028.l
	bne.b	LFF0F46
	rts
	bset.b	#$1,$A12018.l
LFF0F5A	btst.b	#$1,$A12028.l
	beq.b	LFF0F5A
	bclr.b	#$1,$A12018.l
LFF0F6C	btst.b	#$1,$A12028.l
	bne.b	LFF0F6C
	rts
	bset.b	#$2,$A12018.l
LFF0F80	btst.b	#$2,$A12028.l
	beq.b	LFF0F80
	bclr.b	#$2,$A12018.l
LFF0F92	btst.b	#$2,$A12028.l
	bne.b	LFF0F92
	rts
	bset.b	#$3,$A12018.l
LFF0FA6	btst.b	#$3,$A12028.l
	beq.b	LFF0FA6
	bclr.b	#$3,$A12018.l
LFF0FB8	btst.b	#$3,$A12028.l
	bne.b	LFF0FB8
	rts
	move.l	a1,-(sp)
	movea.l	$4(sp),a1
	bsr.w	LFF0FD6
	move.l	a1,$4(sp)
	movea.l	(sp)+,a1
	rts
LFF0FD6	movem.l	d0-d3,-(sp)
	move.w	$E(a1),d3
	bra.w	LFF0FFE
LFF0FE2	lea.l	(a1),a0
	bsr.w	LFF100E
	move.w	d0,d2
	lea.l	$6(a1),a0
	bsr.w	LFF100E
	move.w	d0,d1
	move.w	$C(a1),d0
	add.w	d0,d0
	bsr.w	LFF103E
LFF0FFE	dbra	d3,LFF0FE2
	adda.l	#$10,a1
	movem.l	(sp)+,d0-d3
	rts
LFF100E	movem.l	d1/a0-a2,-(sp)
	lea.l	$FF284E.l,a2
	move.w	$4(a0),d1
	asl.w	#$2,d1
	adda.w	d1,a2
	move.w	$E(a1),d0
	sub.w	d3,d0
	subq.w	#$1,d0
	add.w	$2(a0),d0
	move.w	$2(a2),d1
	asl.w	d1,d0
	add.w	(a0),d0
	add.w	d0,d0
	add.w	(a2),d0
	movem.l	(sp)+,d1/a0-a2
	rts
LFF103E	movem.l	d0-d3/a1,-(sp)
	move.w	$23C6E8.l,-(sp)
	bset.b	#$4,$23C6E8.l
	lea.l	$C00004.l,a1
	move.w	#$8154,(a1)
	move.w	#$8F01,(a1)
	move.w	#$9300,d3
	move.b	d0,d3
	move.w	d3,(a1)
	move.w	#$9400,d3
	lsr.w	#$8,d0
	move.b	d0,d3
	move.w	d3,(a1)
	move.w	#$9500,d3
	move.b	d2,d3
	move.w	d3,(a1)
	move.w	#$9600,d3
	lsr.w	#$8,d2
	move.b	d2,d3
	move.w	d3,(a1)
	move.w	#$97C0,(a1)
	clr.l	d0
	move.w	d1,d0
	asl.l	#$2,d0
	lsr.w	#$2,d0
	swap	d0
	ori.w	#$C0,d0
	move.l	d0,$FF290E.l
	move.w	$FF290E.l,(a1)
	move.w	$FF2910.l,(a1)
	bsr.w	X_FF051C
	move.w	#$8164,(a1)
	move.w	#$8F02,(a1)
	move.w	(sp)+,$23C6E8.l
	movem.l	(sp)+,d0-d3/a1
	rts
	movem.l	d3/a1,-(sp)
	movea.l	#$C00000,a1
	andi.l	#$FFFF,d1
	asl.l	#$2,d1
	lsr.w	#$2,d1
	ori.w	#$4000,d1
	swap	d1
	move.l	d1,$4(a1)
	move.w	d2,d3
	swap	d3
	move.w	d2,d3
	lsr.w	#$1,d0
	subq.w	#$1,d0
LFF10E6	move.l	d3,$FF290E.l
	move.w	$FF290E.l,(a1)
	move.w	$FF2910.l,(a1)
	dbra	d0,LFF10E6
	movem.l	(sp)+,d3/a1
	rts
	lea.l	$23A450.l,a1
	bsr.w	LFF0FD6
	rts
	movem.l	d0-d3/a0-a2,-(sp)
	move.w	d1,d3
	clr.w	d1
	clr.w	d2
	lea.l	$FF2916.l,a1
LFF111E	move.b	(a0)+,d0
	andi.w	#$F0,d0
	lsr.w	#$2,d0
	movea.l	#$FF2280,a2
	movea.l	(a2,d0.w),a2
	jsr	(a2)
	bra.b	LFF111E
	move.b	-$1(a0),d0
	andi.w	#$1F,d0
LFF113C	move.b	(a0)+,(a1,d1.w)
	addq.b	#$1,d1
	bne.w	LFF114A
	bsr.w	X_FF0316
LFF114A	dbra	d0,LFF113C
	rts
	move.b	-$1(a0),d0
	andi.w	#$F,d0
LFF1158	clr.b	(a1,d1.w)
	addq.b	#$1,d1
	bne.w	LFF1166
	bsr.w	X_FF0316
LFF1166	dbra	d0,LFF1158
	rts
	move.b	-$1(a0),d0
	andi.w	#$F,d0
	addq.w	#$2,d0
	move.b	(a0)+,d2
LFF1178	move.b	d2,(a1,d1.w)
	addq.b	#$1,d1
	bne.w	LFF1186
	bsr.w	X_FF0316
LFF1186	dbra	d0,LFF1178
	rts
	move.b	-$1(a0),d0
	andi.w	#$7,d0
	addq.w	#$1,d0
	move.b	-$1(a0),d2
	lsr.w	#$3,d2
	andi.w	#$7,d2
	addq.w	#$1,d2
LFF11A2	neg.b	d2
	add.b	d1,d2
LFF11A6	move.b	(a1,d2.w),(a1,d1.w)
	addq.b	#$1,d2
	addq.b	#$1,d1
	bne.w	LFF11B8
	bsr.w	X_FF0316
LFF11B8	dbra	d0,LFF11A6
	rts
	move.b	-$1(a0),d0
	andi.w	#$F,d0
	addq.w	#$2,d0
	move.b	(a0)+,d2
	bra.b	LFF11A2
	move.b	(a0),d0
	asl.b	#$1,d0
	move.b	-$1(a0),d0
	roxl.b	#$1,d0
	andi.w	#$1F,d0
	addq.w	#$2,d0
	move.b	(a0)+,d2
	andi.w	#$7F,d2
	addq.w	#$1,d2
	bra.b	LFF11A2
	move.b	-$1(a0),d0
	asl.w	#$8,d0
	move.b	(a0),d0
	lsr.w	#$6,d0
	andi.w	#$3F,d0
	addq.w	#$2,d0
	move.b	(a0)+,d2
	andi.w	#$3F,d2
	addq.w	#$1,d2
	bra.b	LFF11A2
	move.b	-$1(a0),d0
	asl.w	#$8,d0
	move.b	(a0),d0
	lsr.w	#$5,d0
	andi.w	#$7F,d0
	addq.w	#$2,d0
	move.b	(a0)+,d2
	andi.w	#$1F,d2
	addq.w	#$1,d2
	bra.b	LFF11A2
	move.b	-$1(a0),d0
	andi.w	#$3,d0
	addq.w	#$1,d0
	move.b	-$1(a0),d2
	lsr.w	#$2,d2
	andi.w	#$7,d2
	addq.w	#$1,d2
LFF1230	neg.b	d2
	add.b	d1,d2
LFF1234	move.b	(a1,d2.w),(a1,d1.w)
	subq.b	#$1,d2
	addq.b	#$1,d1
	bne.w	LFF1246
	bsr.w	X_FF0316
LFF1246	dbra	d0,LFF1234
	rts
	move.b	-$1(a0),d0
	andi.w	#$F,d0
	addq.w	#$2,d0
	move.b	(a0)+,d2
	bne.b	LFF1230
	bsr.w	X_FF0316
	addq.l	#$4,sp
	movem.l	(sp)+,d0-d3/a0-a2
	rts
	move.b	(a0),d0
	asl.b	#$1,d0
	move.b	-$1(a0),d0
	roxl.b	#$1,d0
	andi.w	#$1F,d0
	addq.w	#$2,d0
	move.b	(a0)+,d2
	andi.w	#$7F,d2
	addq.w	#$1,d2
	bra.b	LFF1230
	dc.l	$FF2134
	dc.l	$FF2134
	dc.l	$FF2150
	dc.l	$FF216C
	dc.l	$FF218C
	dc.l	$FF218C
	dc.l	$FF218C
	dc.l	$FF218C
	dc.l	$FF21BE
	dc.l	$FF21CC
	dc.l	$FF21E6
	dc.l	$FF2200
	dc.l	$FF221A
	dc.l	$FF221A
	dc.l	$FF224C
	dc.l	$FF2266
