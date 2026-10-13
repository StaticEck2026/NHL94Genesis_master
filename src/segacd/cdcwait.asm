; STARTER.BIN drive wait, file $3A76-$3A89, runtime $24D76-$24D89.
; CDBCHK ($80) until the carry flag is clear. Carry set means the BIOS is busy.

	org	$24D76

	movem.l	d0-d1/a0-a1,-(sp)
L24D7A	move.w	#$80,d0
	jsr	$5F22.w
	bcs.b	L24D7A
	movem.l	(sp)+,d0-d1/a0-a1
	rts
