; HOCKEY.BIN scouting file load, $24C12-$24D65.
; SDK $6044 with d7=$D, then d7=1 d0=0, then d7=3.
; Adds the returned pointer to the directory longs. $47CFC is the
; script base. $47D54 is the Ron Barr picture. cdstart.asm follows.
; See docs/segacd_announce.md.

	org	$24C12

	tst.w	$3FC0A.l
	beq.b	L24C20
	jsr	$376F2.l
L24C20	move.w	#$D,d7
	jsr	$6044.w
	movem.l	d0-d2/d7/a0-a1,-(sp)
	move.w	#$1,d7
	move.w	#$0,d0
	jsr	$6044.w
	move.l	a0,$47D60.l
	movem.l	(sp)+,d0-d2/d7/a0-a1
	move.w	#$3,d7
	jsr	$6044.w
	movea.l	$47D60.l,a0
	move.l	a0,d0
	move.l	(a0)+,$47CFC.l
	add.l	d0,$47CFC.l
	move.l	(a0)+,$47D8C.l
	add.l	d0,$47D8C.l
	move.l	(a0)+,$47D88.l
	add.l	d0,$47D88.l
	move.l	(a0)+,$47DA4.l
	add.l	d0,$47DA4.l
	move.l	(a0)+,$47D3C.l
	add.l	d0,$47D3C.l
	move.l	(a0)+,$47D98.l
	add.l	d0,$47D98.l
	move.l	(a0)+,$47D9C.l
	add.l	d0,$47D9C.l
	move.l	(a0)+,$47D50.l
	add.l	d0,$47D50.l
	move.l	(a0)+,$47D38.l
	add.l	d0,$47D38.l
	move.l	(a0)+,$47D10.l
	add.l	d0,$47D10.l
	move.l	(a0)+,$47D54.l
	add.l	d0,$47D54.l
	move.l	(a0)+,$47D70.l
	add.l	d0,$47D70.l
	move.l	(a0)+,$47D0C.l
	add.l	d0,$47D0C.l
	move.l	(a0)+,$47D08.l
	add.l	d0,$47D08.l
	move.l	(a0)+,$47D78.l
	add.l	d0,$47D78.l
	move.l	(a0)+,$47D44.l
	add.l	d0,$47D44.l
	move.l	(a0)+,$47D7C.l
	add.l	d0,$47D7C.l
	move.l	(a0)+,$47D48.l
	add.l	d0,$47D48.l
	move.l	(a0)+,$47D94.l
	add.l	d0,$47D94.l
	move.l	(a0)+,$47D18.l
	add.l	d0,$47D18.l
	move.l	(a0)+,$47D00.l
	add.l	d0,$47D00.l
	move.l	(a0)+,$47D74.l
	add.l	d0,$47D74.l
	move.l	(a0)+,$47D04.l
	add.l	d0,$47D04.l
