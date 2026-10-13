; HOCKEY.BIN play the track song just stored, file $10B1E.
; Calls song ($371D2) with the word at $1A56A, copies $1745E to
; $19364, MSCPLAY1 ($12) once, then sets $1745C to $FFFF.
; See docs/segacd_song.md.

	org	$10B1E

	move.w	$1A56A.l,-(sp)
	jsr	$371D2.l
	move.w	$1745E.l,$19364.l
	movea.l	$FF8000.l,a5
	move.w	#$12,d0
	lea.l	$19364.l,a0
	jsr	$5F22.w
	move.w	#$FFFF,$1745C.l
	move.w	#$0,$17460.l
