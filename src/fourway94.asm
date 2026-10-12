;	New in 94: support for the EA 4 Way Play adaptor. It finds out whether the adaptor is plugged
;	in and reads the pads through it.

Detect4WayPlay	;detect the 4 way play adaptor (EA 4 Way Play) on port 2: FourWayPlay = 1 when found. Called from Begin
	move.w	#0,(IO_Z80RES).l
	move.b	#$40,(IO_CT1_CTRL+1).l
	move.b	#$43,(IO_CT2_CTRL+1).l
	nop
	move.b	#$7C,(IO_CT2_DATA+1).l
	nop
	move.b	#$7F,(IO_CT2_CTRL+1).l
	nop
	move.b	#$7C,(IO_CT2_DATA+1).l
	nop
	move.b	(IO_CT1_DATA+1).l,d0
	andi.b	#3,d0
	cmp.b	#0,d0
	bne.s	.none
	move.w	#1,(FourWayPlay).w
	bra.s	.x
.none
	move.w	#0,(FourWayPlay).w
	move.b	#$40,(IO_CT2_CTRL+1).l
.x
	move.w	#$100,(IO_Z80RES).l
	rts
ReadJoySwapPad1	;unused: read 4 way play pad 1 (ReadJoy1 with the pad word swapped in)
	move.b	#0,(IO_CT2_DATA+1).l	;4 way play: select pad
	move.w	(pad4waysave1).w,(pad4wayword).w
	jsr	(ReadJoy1).l
	move.w	(pad4wayword).w,(pad4waysave1).w
	rts
ReadJoySwapPad2	;unused: the same for pad 2
	move.b	#$10,(IO_CT2_DATA+1).l	;4 way play: select pad
	move.w	(pad4waysave2).w,(pad4wayword).w
	jsr	(ReadJoy1).l
	move.w	(pad4wayword).w,(pad4waysave2).w
	rts
ReadJoySwapPad3	;unused: the same for pad 3
	move.b	#$20,(IO_CT2_DATA+1).l	;4 way play: select pad
	move.w	(pad4waysave3).w,(pad4wayword).w
	jsr	(ReadJoy1).l
	move.w	(pad4wayword).w,(pad4waysave3).w
	rts
ReadJoySwapPad4	;unused: the same for pad 4
	move.b	#$30,(IO_CT2_DATA+1).l	;4 way play: select pad
	move.w	(pad4waysave4).w,(pad4wayword).w
	jsr	(ReadJoy1).l
	move.w	(pad4wayword).w,(pad4waysave4).w
	rts
	rts	;unreferenced
Set4WayPlayerStub	;An empty Set4WayPlayer (just rts): forcepldata calls it with SCnum $F when a goalie is pulled
	rts
Set4WayPlayer	;unused: put player a3's number ($52) in the home or away nibble of PadControlBits34 (unless PadControlBits is -1)
	cmpi.w	#$FFFF,(PadControlBits).w
	beq.w	.x
	movem.l	d0-d2,-(sp)
	move.w	#1,d0
	btst	#6,pflags(a3)
	beq.w	.chkpad3
	move.w	#2,d0
.chkpad3
	cmp.w	(cont3team).w,d0
	beq.w	.pad3
	move.w	#$F,d1
	move.w	#4,d0
	bra.w	.set
.pad3
	move.w	#$F0,d1
	move.w	#0,d0
.set
	and.w	d1,(PadControlBits34).w
	move.w	SCnum(a3),d1
	asl.w	d0,d1
	or.w	d1,(PadControlBits34).w
	movem.l	(sp)+,d0-d2
.x
	rts
