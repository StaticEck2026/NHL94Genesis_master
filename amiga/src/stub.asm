;	NHL94: the launcher. Loads NHL94.game and runs it; started from the Workbench, it takes the
;	Workbench message. What goes wrong is said in a requester (request.i). Assembled for the
;	68000, so that it can say so on any Amiga.
;	On the floppy the game is NHL94.pak (amiga/tools/pack.py: its hunks deflate compressed),
;	which the launcher loads itself when it is there.

EXEC_Forbid		equ	-132
EXEC_Permit		equ	-138
EXEC_FindTask		equ	-294
EXEC_GetMsg		equ	-372
EXEC_ReplyMsg		equ	-378
EXEC_WaitPort		equ	-384
EXEC_OpenLibrary	equ	-552
EXEC_CloseLibrary	equ	-414
EXEC_AllocMem		equ	-198
EXEC_FreeMem		equ	-210
EXEC_CacheClearU	equ	-636
DOS_Open		equ	-30
DOS_Close		equ	-36
DOS_Read		equ	-42
DOS_Seek		equ	-66
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
	bsr	pakload
	tst.l	d0
	bmi.s	.say				;(a0: why not)
	move.l	d0,seglist
	bne	.run
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
	tst.b	packed
	beq.s	.unl
	bsr	pakfree
	bra.s	.free
.unl	jsr	DOS_UnLoadSeg(a6)
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

;	NHL94.pak, if it is there: d0 = its seglist (hunks allocated as LoadSeg does: a long of the
;	size, the next hunk's BPTR, the contents), 0 if there is no NHL94.pak, -1 with a0 = the
;	message if it cannot be loaded. a6 = dos.library.
pakload
	movem.l	d2-d7/a2-a5,-(sp)
	clr.l	pakbuf
	clr.l	relbuf
	clr.l	hunks
	move.l	#pakname,d1
	move.l	#1005,d2			;MODE_OLDFILE
	jsr	DOS_Open(a6)
	move.l	d0,d4
	beq	.none
	move.l	d4,d1				;its size: from the end back to the start
	moveq	#0,d2
	moveq	#1,d3				;OFFSET_END
	jsr	DOS_Seek(a6)
	move.l	d4,d1
	moveq	#0,d2
	moveq	#-1,d3				;OFFSET_BEGINNING
	jsr	DOS_Seek(a6)
	move.l	d0,d5
	ble	.badc
	move.l	d5,d0
	addq.l	#4,d0				;(the inflater may read a little past the end)
	moveq	#1,d1				;MEMF_PUBLIC
	bsr	alloc
	move.l	d0,pakbuf
	beq	.memc
	move.l	d4,d1
	move.l	d0,d2
	move.l	d5,d3
	jsr	DOS_Read(a6)
	cmp.l	d5,d0
	bne	.badc
	move.l	d4,d1
	jsr	DOS_Close(a6)
	movea.l	pakbuf,a2
	cmpi.l	#'NHLZ',(a2)
	bne	.bad
	move.l	4(a2),d7			;hunks
	cmpi.l	#MAXHUNKS,d7
	bhi	.bad
	; allocate the hunks, linked
	lea	12(a2),a3			;(size, compressed bytes) per hunk
	lea	hunkbase,a4
	lea	hunks,a5			;where the BPTR to the next one goes
	moveq	#0,d6
.al	move.l	(a3),d0
	andi.l	#$3FFFFFFF,d0
	lsl.l	#2,d0
	addq.l	#8,d0
	move.l	#$10001,d1			;MEMF_CLEAR | MEMF_PUBLIC
	btst	#6,(a3)				;(bit 30: chip)
	beq.s	.nc
	addq.l	#2,d1
.nc	btst	#7,(a3)				;(bit 31: fast)
	beq.s	.nf
	addq.l	#4,d1
.nf	move.l	d0,d5
	bsr	alloc
	tst.l	d0
	beq	.mem
	movea.l	d0,a0
	move.l	d5,(a0)+			;size
	move.l	a0,d0
	lsr.l	#2,d0
	move.l	d0,(a5)				;BPTR of the next long
	movea.l	a0,a5
	clr.l	(a0)+
	move.l	a0,(a4)+			;the contents
	addq.l	#8,a3
	addq.w	#1,d6
	cmp.w	d7,d6
	blt.s	.al
	; inflate them
	lea	12(a2),a3
	move.l	d7,d0
	lsl.l	#3,d0
	lea	16(a2,d0.l),a0			;the first deflate data
	lea	hunkbase,a4
	move.w	d7,d6
	subq.w	#1,d6
.in	movea.l	(a4)+,a1
	move.l	4(a3),d0
	beq.s	.inn
	move.l	a0,-(sp)
	bsr	inflate
	movea.l	(sp)+,a0
	adda.l	d0,a0
.inn	addq.l	#8,a3
	dbf	d6,.in
	; the reloc table: inflated, then applied
	move.l	a0,-(sp)
	move.l	8(a2),d0
	addq.l	#4,d0
	moveq	#1,d1
	bsr	alloc
	movea.l	(sp)+,a0
	move.l	d0,relbuf
	beq	.mem
	movea.l	d0,a1
	bsr	inflate
	movea.l	relbuf,a3
	lea	hunkbase,a4
	move.w	d7,d6
	subq.w	#1,d6
.rh	movea.l	(a4)+,a1			;the hunk
.rg	move.l	(a3)+,d5			;a group: count, target, offsets
	beq.s	.rn
	move.l	(a3)+,d0
	lsl.l	#2,d0
	lea	hunkbase,a0
	move.l	(a0,d0.l),d4
	subq.l	#1,d5
.ro	move.l	(a3)+,d0
	add.l	d4,(a1,d0.l)
	subq.l	#1,d5
	bpl.s	.ro
	bra.s	.rg
.rn	dbf	d6,.rh
	bsr	pakbufs
	movea.l	(4).w,a6
	cmpi.w	#37,20(a6)			;(LIB_VERSION: CacheClearU from V37)
	blo.s	.cc
	jsr	EXEC_CacheClearU(a6)
.cc	movea.l	dosbase,a6
	st	packed
	move.l	hunks,d0
	bra.s	.x
.none	moveq	#0,d0
	bra.s	.x
.memc	move.l	d4,d1
	jsr	DOS_Close(a6)
.mem	lea	(msgmem,pc),a0
	bra.s	.fail
.badc	move.l	d4,d1
	jsr	DOS_Close(a6)
.bad	lea	(msgpak,pc),a0
.fail	move.l	a0,-(sp)
	bsr	pakbufs
	move.l	hunks,d1
	bsr	pakfree
	movea.l	(sp)+,a0
	moveq	#-1,d0
.x	movem.l	(sp)+,d2-d7/a2-a5
	rts

;	Free the packed file and the reloc table. Keeps a6.
pakbufs	move.l	a6,-(sp)
	movea.l	(4).w,a6
	move.l	relbuf,d0
	beq.s	.r
	movea.l	d0,a1
	move.l	-(a1),d0
	jsr	EXEC_FreeMem(a6)
	clr.l	relbuf
.r	move.l	pakbuf,d0
	beq.s	.p
	movea.l	d0,a1
	move.l	-(a1),d0
	jsr	EXEC_FreeMem(a6)
	clr.l	pakbuf
.p	movea.l	(sp)+,a6
	rts

;	d0 = memory of d0 bytes (type d1) or 0; its size is kept in the long before it (for
;	pakbufs: the hunks keep theirs in their own first long). Keeps a6.
alloc	move.l	a6,-(sp)
	movea.l	(4).w,a6
	cmpi.l	#$10000,d1
	bhs.s	.h				;(a hunk: the caller lays it out)
	addq.l	#4,d0
	move.l	d0,-(sp)
	jsr	EXEC_AllocMem(a6)
	move.l	(sp)+,d1
	tst.l	d0
	beq.s	.x
	movea.l	d0,a0
	move.l	d1,(a0)+
	move.l	a0,d0
	bra.s	.x
.h	jsr	EXEC_AllocMem(a6)
.x	movea.l	(sp)+,a6
	rts

;	Free the hunks of the seglist d1 (from pakload). Keeps a6.
pakfree	move.l	a6,-(sp)
	movea.l	(4).w,a6
.n	tst.l	d1
	beq.s	.x
	lsl.l	#2,d1
	movea.l	d1,a1
	move.l	(a1),d1				;the next
	subq.l	#4,a1
	move.l	(a1),d0
	jsr	EXEC_FreeMem(a6)
	bra.s	.n
.x	movea.l	(sp)+,a6
	rts

	include	"inflate.i"

	include	"build.i"			;(the version string: the build, build.sh)
dosname		dc.b	'dos.library',0
gamename	dc.b	'PROGDIR:NHL94.game',0
pakname		dc.b	'PROGDIR:NHL94.pak',0
msgpak		dc.b	'NHL94.pak is damaged.',0
msgload		dc.b	'Cannot load NHL94.game.',10
		dc.b	'It must be in the same directory as NHL94.',0
msgmem		dc.b	'Not enough memory to load NHL94.game.',10,10
		dc.b	'NHL 94 needs an AGA Amiga (A1200 / A4000)',10
		dc.b	'with fast RAM: 2 MB chip RAM and',10
		dc.b	'at least 2 MB fast RAM.',0
msgdos		dc.b	'NHL 94 must be started from a Shell,',10
		dc.b	'a startup-sequence or the Workbench.',0
	even

MAXHUNKS	equ	16

	section	stubbss,bss
dosbase		ds.l	1
wbmsg		ds.l	1
seglist		ds.l	1
pakbuf		ds.l	1
relbuf		ds.l	1
hunks		ds.l	1				;the seglist being built
hunkbase	ds.l	MAXHUNKS
packed		ds.b	1
		even
ifwork		ds.b	IF_SIZE
