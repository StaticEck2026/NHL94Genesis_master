;	NHL94: the launcher. Keeps AmigaDOS from loading the game into the Genesis work RAM window
;	(RAMBASE, amiga.i) by taking every free piece of it, then loads NHL94.game, runs it and
;	frees everything again. The game itself checks the window and saves / restores whatever the
;	OS keeps there.

	include	"amiga.i"

EXEC_Forbid		equ	-132
EXEC_Permit		equ	-138
EXEC_AllocAbs		equ	-204
EXEC_FreeMem		equ	-210
EXEC_OpenLibrary	equ	-552
EXEC_CloseLibrary	equ	-414
DOS_LoadSeg		equ	-150
DOS_UnLoadSeg		equ	-156
DOS_Output		equ	-60
DOS_Write		equ	-48
MAXPIECES		equ	32

	section	stub,code
start
	movem.l	d0/a0,-(sp)			;the command line, for the game
	movea.l	(4).w,a6
	lea	(dosname,pc),a1
	moveq	#36,d0
	jsr	EXEC_OpenLibrary(a6)
	move.l	d0,dosbase
	beq	.nodos
	bsr	reserve
	movea.l	dosbase,a6
	move.l	#gamename,d1
	jsr	DOS_LoadSeg(a6)
	move.l	d0,seglist
	bne.s	.run
	lea	(msgload,pc),a0
	bsr	print
	moveq	#20,d7
	bra.s	.free
.run	movem.l	(sp),d0/a0
	movea.l	seglist,a1
	adda.l	a1,a1
	adda.l	a1,a1
	jsr	4(a1)				;first hunk of the game
	move.l	d0,d7
	movea.l	dosbase,a6
	move.l	seglist,d1
	jsr	DOS_UnLoadSeg(a6)
.free	bsr	release
	movea.l	(4).w,a6
	movea.l	dosbase,a1
	jsr	EXEC_CloseLibrary(a6)
	move.l	d7,d0
	addq.l	#8,sp
	rts
.nodos	addq.l	#8,sp
	moveq	#20,d0
	rts

;	Take every free chunk that overlaps the window. AllocAbs changes the free list, so the walk
;	starts again after each one.
reserve
	movea.l	(4).w,a6
	jsr	EXEC_Forbid(a6)
.again	cmpi.w	#MAXPIECES,npieces
	bhs.s	.done
	movea.l	$142(a6),a2			;MemList.lh_Head
.mh	tst.l	(a2)
	beq.s	.done				;end of the list
	movea.l	$10(a2),a3			;mh_First
.mc	move.l	a3,d0
	beq.s	.nextmh
	move.l	d0,d1
	add.l	4(a3),d1			;chunk end
	; overlap with [RAMBASE, RAMBASE+$10000)
	cmpi.l	#RAMBASE+$10000,d0
	bhs.s	.nextmc
	cmpi.l	#RAMBASE,d1
	bls.s	.nextmc
	cmpi.l	#RAMBASE,d0
	bhs.s	.lo
	move.l	#RAMBASE,d0
.lo	cmpi.l	#RAMBASE+$10000,d1
	bls.s	.hi
	move.l	#RAMBASE+$10000,d1
.hi	sub.l	d0,d1				;length
	movea.l	d0,a1
	move.l	d1,d0
	movem.l	d0/a1,-(sp)
	jsr	EXEC_AllocAbs(a6)
	movem.l	(sp)+,d1/a1
	tst.l	d0
	beq.s	.nextmc
	move.w	npieces,d2
	lsl.w	#3,d2
	lea	pieces,a0
	move.l	a1,(a0,d2.w)
	move.l	d1,4(a0,d2.w)
	addq.w	#1,npieces
	bra.s	.again
.nextmc	movea.l	(a3),a3
	bra.s	.mc
.nextmh	movea.l	(a2),a2
	bra.s	.mh
.done	jsr	EXEC_Permit(a6)
	rts

release
	movea.l	(4).w,a6
	lea	pieces,a2
.l	tst.w	npieces
	beq.s	.x
	subq.w	#1,npieces
	movea.l	(a2)+,a1
	move.l	(a2)+,d0
	jsr	EXEC_FreeMem(a6)
	bra.s	.l
.x	rts

print
	movem.l	d1-d3/a0/a6,-(sp)
	movea.l	a0,a1
	moveq	#-1,d3
.len	addq.l	#1,d3
	tst.b	(a1)+
	bne.s	.len
	move.l	a0,-(sp)
	movea.l	dosbase,a6
	jsr	DOS_Output(a6)
	move.l	d0,d1
	move.l	(sp)+,d2
	tst.l	d1
	beq.s	.x
	jsr	DOS_Write(a6)
.x	movem.l	(sp)+,d1-d3/a0/a6
	rts

dosname		dc.b	'dos.library',0
gamename	dc.b	'PROGDIR:NHL94.game',0
msgload		dc.b	'Cannot load NHL94.game (it must be next to NHL94).',10,0
	even

	section	stubbss,bss
dosbase		ds.l	1
seglist		ds.l	1
npieces		ds.w	1
pieces		ds.l	2*MAXPIECES
