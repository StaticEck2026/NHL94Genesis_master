; HOCKEY.BIN scouting text player, $2486C-$24A89.
; InitScoutingDisplay, then one word of the Ron Barr script.
; A '!' skips three bytes (a wrapped line in the GRAPH2 script).
; Token handlers for the other special bytes are scouttok.asm.

X_1DF80	equ	$1DF80
X_1DF6E	equ	$1DF6E
X_24AE4	equ	$24AE4
X_24AD0	equ	$24AD0
X_24ABC	equ	$24ABC
X_24AA8	equ	$24AA8
X_24A9E	equ	$24A9E
X_24A94	equ	$24A94
X_24A8A	equ	$24A8A
X_24B16	equ	$24B16
X_24B0C	equ	$24B0C
X_24B02	equ	$24B02
X_24AF8	equ	$24AF8
X_24B42	equ	$24B42
X_24B4C	equ	$24B4C
X_24B7E	equ	$24B7E
X_24B20	equ	$24B20
X_24B70	equ	$24B70
X_24B88	equ	$24B88
X_24BB6	equ	$24BB6
X_21000	equ	$21000

	org	$2486C

	move.w	#$FFFF,$1A450.l
	move.w	#$FF00,$1A452.l
	clr.w	$1A454.l
	clr.w	$1A456.l
	movea.l	#$1A45A,a0
	rts
	cmpi.w	#$1000,$1A456.l
	bgt.w	X_21000
	tst.w	$1747A.l
	bmi.w	L248B2
	subi.w	#$1,$1A456.l
	bpl.w	X_21000
L248B2	movea.l	$47CFC.l,a1
	moveq	#$0,d0
	move.w	$1A452.l,d0
	cmpi.w	#$FF00,d0
	bne.w	L24906
	clr.w	$1A44E.l
	move.w	$1A454.l,d0
	addi.w	#$2,$1A454.l
	movea.l	#$1A45A,a0
	move.w	(a0,d0.w),d0
	bpl.w	L248FC
	move.w	#$7FFF,$1A456.l
	move.w	#$1E0,$1A458.l
	rts
L248FC	bsr.w	X_24BB6
	move.l	$17462.l,d0
L24906	lea.l	(a1,d0.l),a2
	move.w	#$A,$1A456.l
	move.w	$1A44E.l,d0
	cmpi.b	#$5F,(a2)
	beq.w	X_24B88
	cmpi.b	#$2B,(a2)
	beq.w	X_24B70
	cmpi.b	#$24,(a2)
	beq.w	X_24B20
	cmpi.b	#$7B,(a2)
	beq.w	X_24B88
	cmpi.b	#$7D,(a2)
	beq.w	X_24B7E
	cmpi.b	#$5B,(a2)
	beq.w	X_24B4C
	cmpi.b	#$5D,(a2)
	beq.w	X_24B42
	cmpi.b	#$3C,(a2)
	beq.w	X_24AF8
	cmpi.b	#$3E,(a2)
	beq.w	X_24B02
	cmpi.b	#$7C,(a2)
	beq.w	X_24B0C
	cmpi.b	#$5C,(a2)
	beq.w	X_24B16
	cmpi.b	#$40,(a2)
	beq.w	X_24A8A
	cmpi.b	#$23,(a2)
	beq.w	X_24A94
	cmpi.b	#$25,(a2)
	beq.w	X_24A9E
	cmpi.b	#$3D,(a2)
	beq.w	X_24AA8
	cmpi.b	#$2A,(a2)
	beq.w	X_24ABC
	cmpi.b	#$5E,(a2)
	beq.w	X_24AD0
	cmpi.b	#$3B,(a2)
	beq.w	X_24AE4
	move.w	#$FF00,$1A452.l
	movea.l	#$17EF4,a0
	clr.w	d1
L249B8	cmpi.b	#$21,(a2)
	bne.w	L249C2
	addq.l	#$3,a2
L249C2	cmpi.b	#$D,(a2)
	beq.w	L24A2A
	addi.w	#$1,d0
L249CE	move.b	(a2),(a0)+
	addi.w	#$1,d1
	cmpi.b	#$2C,(a2)
	beq.w	L249E4
	cmpi.b	#$2E,(a2)
	bne.w	L249EC
L249E4	addi.w	#$28,$1A456.l
L249EC	cmpi.b	#$20,(a2)+
	bne.w	L249B8
	cmpi.b	#$20,(a2)
	beq.w	L24A00
	bra.w	L24A0E
L24A00	addi.w	#$14,$1A456.l
	addq.l	#$1,a2
	bra.w	L249CE
L24A0E	subi.w	#$1,d0
	cmpa.l	a2,a1
	ble.w	L24A22
	move.w	#$FF00,$1A452.l
	bra.b	L24A2A
L24A22	suba.l	a1,a2
	move.w	a2,$1A452.l
L24A2A	move.w	d1,$17EF2.l
	addi.w	#$2,$17EF2.l
	btst	#$0,d1
	beq.w	L24A4A
	clr.b	(a0)
	addi.w	#$1,$17EF2.l
L24A4A	movea.l	#$17EF2,a1
	cmpi.w	#$1D,d0
	ble.w	L24A5C
	bsr.w	X_24BB6
L24A5C	bsr.w	X_1DF6E
	; printz string: length word, then -TXMAP1, x=9, y=4
	dc.w	$0006
	dc.b	$FF,$09,$04,$00
	move.w	$1A44E.l,d0
	add.w	d0,$18D58.l
	move.w	$1A450.l,d0
	add.w	d0,$18D5A.l
	bsr.w	X_1DF80
	add.w	d1,$1A44E.l
	rts
