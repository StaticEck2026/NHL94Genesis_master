;	A message for the user in a requester (it stays until OK is clicked, also when the program
;	was started from a startup-sequence whose console closes at once). Shared by the launcher
;	and the game. ezrequest: a0 = the text (0 ended, lines split by 10). Keeps all registers.
;	ezrequesta: the same, with a1 = the text's arguments (a long for each %ld in it).

ez_OpenLibrary		equ	-552
ez_CloseLibrary		equ	-414
ez_EasyRequestArgs	equ	-588

ezrequest
	move.l	a1,-(sp)
	suba.l	a1,a1
	bsr.s	ezrequesta
	movea.l	(sp)+,a1
	rts
ezrequesta
	movem.l	d0-d1/a0-a3/a6,-(sp)
	move.l	a0,ez_text
	movea.l	a1,a3
	movea.l	(4).w,a6
	lea	(ez_intname,pc),a1
	moveq	#36,d0
	jsr	ez_OpenLibrary(a6)
	tst.l	d0
	beq.s	.x
	movea.l	d0,a6
	suba.l	a0,a0				;no window: the Workbench screen
	lea	ez_struct,a1
	suba.l	a2,a2
	jsr	ez_EasyRequestArgs(a6)
	movea.l	a6,a1
	movea.l	(4).w,a6
	jsr	ez_CloseLibrary(a6)
.x	movem.l	(sp)+,d0-d1/a0-a3/a6
	rts

ez_struct
	dc.l	20				;es_StructSize
	dc.l	0				;es_Flags
	dc.l	ez_title			;es_Title
ez_text	dc.l	0				;es_TextFormat
	dc.l	ez_ok				;es_GadgetFormat
ez_intname	dc.b	'intuition.library',0
ez_title	dc.b	'NHL 94',0
ez_ok		dc.b	'OK',0
	even
