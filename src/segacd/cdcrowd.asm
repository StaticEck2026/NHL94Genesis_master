; HOCKEY.BIN crowd-volume slew, $238CE-$2391B.
; The cartridge updatesound. Crowdlevel is $17CD2, asv is $1747A.
; The PSG writes are gone: this builds the old volume byte and returns it in d0.

	org	$238CE

	move.w	$17CD2.l,d0
	asl.w	#$3,d0
	addi.w	#$400,d0
	cmpi.w	#$EFF,d0
	bls.w	L238E6
	move.w	#$EFF,d0
L238E6	moveq	#$28,d2
	sub.w	$1747A.l,d0
	cmp.w	d2,d0
	bgt.w	L238FC
	neg.w	d2
	cmp.w	d2,d0
	bge.w	L2390C
L238FC	add.w	d2,$1747A.l
	bpl.w	L2390C
	clr.w	$1747A.l
L2390C	move.b	$1747A.l,d0
	eori.b	#$F,d0
	ori.b	#$F0,d0
	rts
