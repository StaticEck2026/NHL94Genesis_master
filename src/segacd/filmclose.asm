; STARTER.BIN FilmClose, file $473A, runtime $25A3A.
; Frees the film block and sets the frame index back to -1.
; See docs/segacd_film.md.

X_2609E	equ	$2609E
X_25CFA	equ	$25CFA
X_261CE	equ	$261CE
X_25536	equ	$25536
X_26556	equ	$26556
X_24FB4	equ	$24FB4

	org	$25A3A

	link	a6,#$0
	move.l	a4,-(sp)
	lea.l	X_24FB4(pc),a0
	lea.l	$40(a0),a4
	pea.l	$30(a4)
	jsr	X_26556(pc)
	jsr	X_25536(pc)
	pea.l	$18(a4)
	jsr	X_261CE(pc)
	moveq	#-1,d0
	move.l	d0,$40(a4)
	move.l	$14(a4),-(sp)
	jsr	X_25CFA(pc)
	moveq	#$3,d0
	move.l	d0,-(sp)
	jsr	X_2609E(pc)
	moveq	#$0,d0
	movea.l	-$4(a6),a4
	unlk	a6
	rts
