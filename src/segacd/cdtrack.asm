; HOCKEY.BIN CD track select, $1C206-$1C2CF.
; CDBCHK ($80) / CDBSTAT ($81). Status high byte $00 plays $1745E.
; High byte $05, or $01 while the CDD track byte is under 7 and not 2,
; forces track 2. Track 2 uses FDRSET $300; any other track uses $400.
; Then MSCPLAY1 ($12) twice, a0 pointing at the track word at $19364.

	org	$1C206

	movem.l	d0-d2/a0-a1,-(sp)
	move.w	#$80,d0
	jsr	$5F22.w
	bcs.w	L1C2CA
	move.w	#$81,d0
	jsr	$5F22.w
	move.w	(a0),d2
	andi.w	#$FF00,d2
	cmpi.w	#$500,d2
	bne.b	L1C234
	move.w	#$2,$1745E.l
	bra.b	L1C26E
L1C234	cmpi.w	#$100,d2
	bne.b	L1C25C
	move.b	$7(a0),d0
	cmpi.b	#$FF,d0
	beq.b	L1C25C
	cmpi.b	#$2,d0
	beq.b	L1C25C
	cmpi.b	#$7,$7(a0)
	bge.b	L1C25C
	move.w	#$2,$1745E.l
	bra.b	L1C26E
L1C25C	cmpi.w	#$0,d2
	bne.b	L1C266
	bra.w	L1C26E
L1C266	tst.w	$1745C.l
	ble.b	L1C2CA
L1C26E	move.w	#$0,$1745C.l
	move.w	$1745E.l,$19364.l
	cmpi.w	#$2,$1745E.l
	bne.b	L1C2A2
	move.w	#$300,d1
	move.w	#$85,d0
	jsr	$5F22.w
	move.w	$1745E.l,$19364.l
	bra.b	L1C2AE
L1C2A2	move.w	#$400,d1
	move.w	#$85,d0
	jsr	$5F22.w
L1C2AE	lea.l	$19364.l,a0
	move.w	#$12,d0
	jsr	$5F22.w
	move.w	#$12,d0
	lea.l	$19364.l,a0
	jsr	$5F22.w
L1C2CA	movem.l	(sp)+,d0-d2/a0-a1
	rts
