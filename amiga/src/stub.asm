;	NHL94: the launcher. Loads NHL94.game and runs it. Started from the Workbench, it takes the
;	Workbench message and gives the messages a console window (it opens only if there is
;	something to say).

EXEC_Forbid		equ	-132
EXEC_Permit		equ	-138
EXEC_FindTask		equ	-294
EXEC_GetMsg		equ	-372
EXEC_ReplyMsg		equ	-378
EXEC_WaitPort		equ	-384
EXEC_OpenLibrary	equ	-552
EXEC_CloseLibrary	equ	-414
DOS_LoadSeg		equ	-150
DOS_UnLoadSeg		equ	-156
DOS_Open		equ	-30
DOS_Close		equ	-36
DOS_Output		equ	-60
DOS_Write		equ	-48

	section	stub,code
start
	movem.l	d0/a0,-(sp)			;the command line, for the game
	movea.l	(4).w,a6
	suba.l	a1,a1
	jsr	EXEC_FindTask(a6)
	movea.l	d0,a4
	tst.l	$AC(a4)				;pr_CLI
	bne	.cli
	lea	$5C(a4),a0			;pr_MsgPort: the Workbench message
	jsr	EXEC_WaitPort(a6)
	lea	$5C(a4),a0
	jsr	EXEC_GetMsg(a6)
	move.l	d0,wbmsg
.cli	lea	(dosname,pc),a1
	moveq	#36,d0
	jsr	EXEC_OpenLibrary(a6)
	move.l	d0,dosbase
	beq	.nodos
	tst.l	wbmsg
	beq	.out
	movea.l	d0,a6
	move.l	#conname,d1
	move.l	#1006,d2			;MODE_NEWFILE
	jsr	DOS_Open(a6)
	move.l	d0,con
	beq	.out
	lsr.l	#2,d0
	move.l	d0,$A0(a4)			;pr_COS (BPTR)
.out
	movea.l	dosbase,a6
	move.l	#gamename,d1
	jsr	DOS_LoadSeg(a6)
	move.l	d0,seglist
	bne	.run
	lea	(msgload,pc),a0
	bsr	print
	moveq	#20,d7
	bra	.free
.run	movem.l	(sp),d0/a0
	movea.l	seglist,a1
	adda.l	a1,a1
	adda.l	a1,a1
	jsr	4(a1)				;first hunk of the game
	move.l	d0,d7
	movea.l	dosbase,a6
	move.l	seglist,d1
	jsr	DOS_UnLoadSeg(a6)
.free	movea.l	dosbase,a6
	move.l	con,d1
	beq	.nocon
	suba.l	a1,a1
	movea.l	(4).w,a6
	jsr	EXEC_FindTask(a6)
	movea.l	d0,a0
	clr.l	$A0(a0)				;pr_COS back to none
	movea.l	dosbase,a6
	move.l	con,d1
	jsr	DOS_Close(a6)
.nocon	movea.l	(4).w,a6
	movea.l	dosbase,a1
	jsr	EXEC_CloseLibrary(a6)
	move.l	d7,d0
	bra	.wb
.nodos	moveq	#20,d0
.wb	addq.l	#8,sp
	move.l	wbmsg,d1
	beq	.x
	move.l	d0,-(sp)
	jsr	EXEC_Forbid(a6)			;(the Workbench unloads us once it has the message back)
	movea.l	d1,a1
	jsr	EXEC_ReplyMsg(a6)
	move.l	(sp)+,d0
.x	rts

print
	movem.l	d1-d3/a0/a6,-(sp)
	movea.l	a0,a1
	moveq	#-1,d3
.len	addq.l	#1,d3
	tst.b	(a1)+
	bne	.len
	move.l	a0,-(sp)
	movea.l	dosbase,a6
	jsr	DOS_Output(a6)
	move.l	d0,d1
	move.l	(sp)+,d2
	tst.l	d1
	beq	.x
	jsr	DOS_Write(a6)
.x	movem.l	(sp)+,d1-d3/a0/a6
	rts

dosname		dc.b	'dos.library',0
conname		dc.b	'CON:20/20/600/80/NHL 94/AUTO/CLOSE/WAIT',0
gamename	dc.b	'PROGDIR:NHL94.game',0
msgload		dc.b	'Cannot load NHL94.game (it must be next to NHL94).',10,0
	even

	section	stubbss,bss
dosbase		ds.l	1
wbmsg		ds.l	1
con		ds.l	1
seglist		ds.l	1
