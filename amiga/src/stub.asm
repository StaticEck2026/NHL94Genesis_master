;	NHL94: the launcher. Loads NHL94.game and runs it; started from the Workbench, it takes the
;	Workbench message. What goes wrong is said in a requester (request.i). Assembled for the
;	68000, so that it can say so on any Amiga.

EXEC_Forbid		equ	-132
EXEC_Permit		equ	-138
EXEC_FindTask		equ	-294
EXEC_GetMsg		equ	-372
EXEC_ReplyMsg		equ	-378
EXEC_WaitPort		equ	-384
EXEC_OpenLibrary	equ	-552
EXEC_CloseLibrary	equ	-414
DOS_LoadSeg		equ	-150
DOS_Lock		equ	-84
DOS_UnLock		equ	-90
DOS_UnLoadSeg		equ	-156

	section	stub,code
start
	movem.l	d0/a0,-(sp)			;the command line, for the game
	movea.l	(4).w,a6
	suba.l	a1,a1
	jsr	EXEC_FindTask(a6)
	movea.l	d0,a4
	cmpi.b	#13,8(a4)			;NT_PROCESS: not run from a boot block or the like
	beq.s	.proc
	lea	(msgdos,pc),a0
	bsr	ezrequest
	addq.l	#8,sp
	moveq	#20,d0
	rts
.proc	tst.l	$AC(a4)				;pr_CLI
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
	movea.l	d0,a6
	move.l	#gamename,d1
	jsr	DOS_LoadSeg(a6)
	move.l	d0,seglist
	bne	.run
	; there but not loaded: not enough memory
	move.l	#gamename,d1
	moveq	#-2,d2				;ACCESS_READ
	jsr	DOS_Lock(a6)
	lea	(msgload,pc),a0
	move.l	d0,d1
	beq.s	.say
	jsr	DOS_UnLock(a6)
	lea	(msgmem,pc),a0
.say	bsr	ezrequest
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
.free	movea.l	(4).w,a6
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

	include	"request.i"

dosname		dc.b	'dos.library',0
gamename	dc.b	'PROGDIR:NHL94.game',0
msgload		dc.b	'Cannot load NHL94.game.',10
		dc.b	'It must be in the same directory as NHL94.',0
msgmem		dc.b	'Not enough memory to load NHL94.game.',10,10
		dc.b	'NHL 94 needs an AGA Amiga (A1200 / A4000)',10
		dc.b	'with fast RAM: 2 MB chip RAM and',10
		dc.b	'at least 2 MB fast RAM.',0
msgdos		dc.b	'NHL 94 must be started from a Shell,',10
		dc.b	'a startup-sequence or the Workbench.',0
	even

	section	stubbss,bss
dosbase		ds.l	1
wbmsg		ds.l	1
seglist		ds.l	1
