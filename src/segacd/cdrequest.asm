; HOCKEY.BIN song, file $1C1D2-$1C205.
; The game is entered at $1B000, so this is the jsr $371D2 target.
; Cartridge song took one word on the stack and called the FM driver.
; Here a word in $30-$77 sets $1745C and stores argument-$29 in $1745E.
; $79 and $7A are outside that window and do not change the track.
; See docs/segacd_song.md.

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
