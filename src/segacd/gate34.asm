; HOCKEY.BIN command $34, file $1C174. Loaded at $1B000 this is $37174.
; Posts the stack word at $FF8028 and command $34 at $FF8026,
; using flag bits 3 and 4. Sits between sfx and song. See docs/segacd_song.md.

	org	$1C174

	move.l	d0,-(sp)
	move.w	$8(sp),d0
	move.w	d0,$FF8028.l
L1C180	btst.b	#$4,$FF800E.l
	bne.b	L1C180
	move.w	#$34,$FF8026.l
	bset.b	#$3,$FF800F.l
L1C19A	btst.b	#$3,$FF800E.l
	beq.b	L1C19A
	bset.b	#$4,$FF800F.l
	bclr.b	#$3,$FF800F.l
L1C1B4	btst.b	#$3,$FF800E.l
	bne.b	L1C1B4
	bclr.b	#$4,$FF800F.l
	movem.l	(sp)+,d0
	move.l	(sp),$2(sp)
	addq.w	#$2,sp
	rts
