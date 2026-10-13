; MAIN.BIN hardware readers, $FF3B3C-$FF3C3B.
; One rts each. Argument is $A12022. Reply is $A12010.
; Includes move.w $C00008,$A12010 (HV counter). See docs/segacd_film.md.

	org	$FF3B3C

	move.b	$A12022.l,$C00004.l
	rts
	move.w	$A12022.l,$C00004.l
	rts
	move.l	$A12022.l,$C00004.l
	rts
	move.b	$A12022.l,$C00000.l
	rts
	move.w	$A12022.l,$C00000.l
	rts
	move.l	$A12022.l,$C00000.l
	rts
	move.b	$A12022.l,$A10003.l
	rts
	move.b	$A12022.l,$A10005.l
	rts
	move.b	$A12022.l,$A10009.l
	rts
	move.b	$A12022.l,$A1000B.l
	rts
	move.b	$A10003.l,$A12010.l
	rts
	move.b	$A10005.l,$A12010.l
	rts
	move.w	$C00000.l,$A12010.l
	rts
	move.l	$C00000.l,$A12010.l
	rts
	move.w	$C00004.l,$A12010.l
	rts
	move.w	$A12022.l,$A11100.l
	rts
	move.w	$C00008.l,$A12010.l
	rts
	move.b	$C00008.l,$A12010.l
	rts
	movea.l	$A12022.l,a0
	move.b	(a0),$A12010.l
	rts
	movea.l	$A12022.l,a0
	move.w	(a0),$A12010.l
	rts
	movea.l	$A12022.l,a0
	move.l	(a0),$A12010.l
	rts
