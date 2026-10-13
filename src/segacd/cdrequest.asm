; HOCKEY.BIN track request, $1C1D2-$1C205.
; A word argument in $30-$77 sets $1745C and stores argument-$29 in $1745E.
; $1745E is the track word. $1745C asks the selector at $1C206 to apply it.

	org	$1C1D2

	move.l	d0,-(sp)
	move.w	$8(sp),d0
	cmpi.w	#$30,d0
	blt.w	L1C1FA
	cmpi.w	#$78,d0
	bge.w	L1C1FA
	move.w	#$1,$1745C.l
	subi.w	#$29,d0
	move.w	d0,$1745E.l
L1C1FA	movem.l	(sp)+,d0
	move.l	(sp),$2(sp)
	addq.w	#$2,sp
	rts
