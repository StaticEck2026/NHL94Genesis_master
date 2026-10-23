;	NHL94: the launcher. Loads NHL94.game and runs it; started from the Workbench, it takes the
;	Workbench message. What goes wrong is said in a requester (request.i). Assembled for the
;	68000, so that it can say so on any Amiga. If there is not the memory to load the game, the
;	system is asked to free what it can (unused libraries, devices and fonts) and the Workbench
;	screen is closed (its bitmaps and pictures take chip RAM), each time loading it again; the
;	Workbench opens again when the game ends.
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
EXEC_AvailMem		equ	-216
EXEC_CacheClearU	equ	-636
DOS_Open		equ	-30
DOS_Close		equ	-36
DOS_Read		equ	-42
DOS_Seek		equ	-66
DOS_LoadSeg		equ	-150
DOS_Lock		equ	-84
DOS_UnLock		equ	-90
DOS_UnLoadSeg		equ	-156
INT_CloseWorkBench	equ	-78
INT_OpenWorkBench	equ	-210
MEMF_CHIP		equ	2
MEMF_FAST		equ	4
MEMF_LARGEST		equ	$20000

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
	bsr	loadgame
	bne	.run
	lea	(msgmem,pc),a1
	cmpa.l	a1,a0
	bne.s	.say
	; not enough memory: what the system can free freed, then the Workbench screen closed
	bsr	flushmem
	bsr	loadgame
	bne	.run
	bsr	closewb
	beq.s	.nomem				;(it could not be: other programs' windows on it)
	bsr	flushmem
	bsr	loadgame
	bne	.run
.nomem	bsr	openwb
	bsr	memfigures
	lea	(msgmem,pc),a0
	lea	memargs,a1
	bsr	ezrequesta
	bra.s	.err
.say	bsr	ezrequest
.err	moveq	#20,d7
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
.free	bsr	openwb
	movea.l	(4).w,a6
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

;	The game loaded (seglist, and packed set if from NHL94.pak): Z clear. Else Z set, a0 = why
;	not (msgmem: not enough memory). a6 = dos.library. Uses d0-d2/a0-a1.
loadgame	bsr	pakload
	tst.l	d0
	bmi.s	.no				;(a0: why not)
	move.l	d0,seglist
	bne.s	.x
	move.l	#gamename,d1
	jsr	DOS_LoadSeg(a6)
	move.l	d0,seglist
	bne.s	.x
	move.l	#gamename,d1			;there but not loaded: not enough memory
	moveq	#-2,d2				;ACCESS_READ
	jsr	DOS_Lock(a6)
	lea	(msgload,pc),a0
	move.l	d0,d1
	beq.s	.no
	jsr	DOS_UnLock(a6)
	lea	(msgmem,pc),a0
.no	moveq	#0,d0
.x	rts

;	The system asked to free what it can (an allocation it cannot meet: unused libraries,
;	devices and fonts are expunged first). Keeps all registers.
flushmem
	movem.l	d0-d1/a0-a1/a6,-(sp)
	movea.l	(4).w,a6
	move.l	#$7FFFFFF0,d0
	moveq	#1,d1				;MEMF_PUBLIC
	jsr	EXEC_AllocMem(a6)
	tst.l	d0
	beq.s	.x
	movea.l	d0,a1
	move.l	#$7FFFFFF0,d0
	jsr	EXEC_FreeMem(a6)
.x	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts

;	The Workbench screen closed: Z clear if it was (openwb opens it again). Keeps d2-d7/a2-a5.
closewb	move.l	a6,-(sp)
	movea.l	(4).w,a6
	lea	(intname,pc),a1
	moveq	#36,d0
	jsr	EXEC_OpenLibrary(a6)
	move.l	d0,intbase
	beq.s	.x
	movea.l	d0,a6
	jsr	INT_CloseWorkBench(a6)
	tst.l	d0
	bne.s	.c
	movea.l	a6,a1				;(not closed)
	movea.l	(4).w,a6
	jsr	EXEC_CloseLibrary(a6)
	clr.l	intbase
	bra.s	.x
.c	st	wbclosed
.x	movea.l	(sp)+,a6
	tst.b	wbclosed
	rts

;	The Workbench screen opened again if closewb closed it. Keeps all registers.
openwb	tst.b	wbclosed
	beq.s	.x
	movem.l	d0-d1/a0-a1/a6,-(sp)
	sf	wbclosed
	movea.l	intbase,a6
	jsr	INT_OpenWorkBench(a6)
	movea.l	a6,a1
	movea.l	(4).w,a6
	jsr	EXEC_CloseLibrary(a6)
	clr.l	intbase
	movem.l	(sp)+,d0-d1/a0-a1/a6
.x	rts

;	memargs: the memory the game takes and the memory free now, in KB (msgmem's figures).
memfigures
	movem.l	d0-d1/a0-a1/a6,-(sp)
	lea	memargs,a0
	move.l	#CHIPKB,(a0)+
	move.l	#CHIPBLKKB,(a0)+
	move.l	#ANYKB,(a0)+
	movea.l	(4).w,a6
	moveq	#MEMF_CHIP,d1
	bsr.s	.kb
	move.l	#MEMF_CHIP|MEMF_LARGEST,d1
	bsr.s	.kb
	moveq	#MEMF_FAST,d1
	bsr.s	.kb
	movem.l	(sp)+,d0-d1/a0-a1/a6
	rts
.kb	move.l	a0,-(sp)
	jsr	EXEC_AvailMem(a6)
	movea.l	(sp)+,a0
	moveq	#10,d1
	lsr.l	d1,d0
	move.l	d0,(a0)+
	rts

;	NHL94.pak, if it is there: d0 = its seglist (hunks allocated as LoadSeg does: a long of the
;	size, the next hunk's BPTR, the contents), 0 if there is no NHL94.pak, -1 with a0 = the
;	message if it cannot be loaded. a6 = dos.library.
;	Memory: the hunks with data are allocated and inflated one at a time, each from its
;	compressed bytes read into a buffer of their own (freed before the next), the others (BSS)
;	after them: so the most taken at once is the hunks and the largest hunk's compressed bytes
;	(not the whole file as well).
pakload
	movem.l	d2-d7/a2-a5,-(sp)
	clr.l	pakbuf
	clr.l	relbuf
	clr.l	hunks
	lea	hunkbase,a0
	moveq	#MAXHUNKS-1,d0
.ch	clr.l	(a0)+
	dbf	d0,.ch
	move.l	#pakname,d1
	move.l	#1005,d2			;MODE_OLDFILE
	jsr	DOS_Open(a6)
	move.l	d0,pakfh
	beq	.none
	; the header: 'NHLZ', hunks, reloc table bytes; per hunk its size and compressed bytes;
	; the reloc table's compressed bytes
	lea	pakhdr,a2
	moveq	#12,d3
	movea.l	a2,a0
	bsr	pakread
	bne	.bad
	cmpi.l	#'NHLZ',(a2)
	bne	.bad
	move.l	4(a2),d7			;hunks
	beq	.bad
	cmpi.l	#MAXHUNKS,d7
	bhi	.bad
	move.l	d7,d3
	lsl.l	#3,d3
	addq.l	#4,d3
	lea	12(a2),a0
	bsr	pakread
	bne	.bad
	; the hunks with data, in order (their bytes follow each other in the file)
	moveq	#0,d6				;hunk
.hd	move.l	d6,d0
	lsl.l	#3,d0
	lea	12(a2,d0.l),a3			;its size, compressed bytes
	tst.l	4(a3)
	beq.s	.hdn
	bsr	pakhunk
	beq	.mem
	move.l	4(a3),d0			;its compressed bytes
	addq.l	#4,d0				;(the inflater may read a little past the end)
	moveq	#1,d1				;MEMF_PUBLIC
	bsr	alloc
	move.l	d0,pakbuf
	beq	.mem
	movea.l	d0,a0
	move.l	4(a3),d3
	bsr	pakread
	bne	.bad
	movea.l	pakbuf,a0
	move.l	d6,d0
	lsl.l	#2,d0
	lea	hunkbase,a1
	movea.l	(a1,d0.l),a1
	bsr	inflate
	bsr	pakbufs
.hdn	addq.l	#1,d6
	cmp.l	d7,d6
	blo.s	.hd
	; the others (BSS)
	moveq	#0,d6
.hb	move.l	d6,d0
	lsl.l	#3,d0
	lea	12(a2,d0.l),a3
	tst.l	4(a3)
	bne.s	.hbn
	bsr	pakhunk
	beq	.mem
.hbn	addq.l	#1,d6
	cmp.l	d7,d6
	blo.s	.hb
	; the reloc table: inflated, then applied
	move.l	d7,d0
	lsl.l	#3,d0
	move.l	12(a2,d0.l),d5			;its compressed bytes
	move.l	d5,d0
	addq.l	#4,d0
	moveq	#1,d1
	bsr	alloc
	move.l	d0,pakbuf
	beq	.mem
	movea.l	d0,a0
	move.l	d5,d3
	bsr	pakread
	bne	.bad
	move.l	8(a2),d0
	addq.l	#4,d0
	moveq	#1,d1
	bsr	alloc
	move.l	d0,relbuf
	beq	.mem
	movea.l	pakbuf,a0
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
	bsr	pakclose
	; the seglist: each hunk's next-hunk long the BPTR of the next one's
	lea	hunkbase,a4
	move.l	(a4),d0
	subq.l	#4,d0
	lsr.l	#2,d0
	move.l	d0,hunks
	move.w	d7,d6
	subq.w	#2,d6
	bmi.s	.l1
.ln	movea.l	(a4)+,a0
	move.l	(a4),d0
	subq.l	#4,d0
	lsr.l	#2,d0
	move.l	d0,-4(a0)
	dbf	d6,.ln
.l1	movea.l	(4).w,a6
	cmpi.w	#37,20(a6)			;(LIB_VERSION: CacheClearU from V37)
	blo.s	.cc
	jsr	EXEC_CacheClearU(a6)
.cc	movea.l	dosbase,a6
	st	packed
	move.l	hunks,d0
	bra.s	.x
.none	moveq	#0,d0
	bra.s	.x
.mem	lea	(msgmem,pc),a0
	bra.s	.fail
.bad	lea	(msgpak,pc),a0
.fail	move.l	a0,-(sp)
	bsr	pakbufs
	bsr	pakclose
	bsr	pakfreeh
	movea.l	(sp)+,a0
	moveq	#-1,d0
.x	movem.l	(sp)+,d2-d7/a2-a5
	rts

;	Read d3 bytes of NHL94.pak to a0: Z set if they were. a6 = dos.library. Uses d0-d3.
pakread	move.l	pakfh,d1
	move.l	a0,d2
	move.l	d3,-(sp)
	jsr	DOS_Read(a6)
	cmp.l	(sp)+,d0
	rts

;	Close NHL94.pak if it is open. Keeps all but d0-d1 (dos.library: a6).
pakclose
	move.l	pakfh,d1
	beq.s	.x
	clr.l	pakfh
	jsr	DOS_Close(a6)
.x	rts

;	Hunk d6 (a3: its size in longs with the memory type, as in HUNK_HEADER) allocated (cleared):
;	hunkbase + 4 * d6 = its contents, the size and a long for the next hunk's BPTR before them.
;	Z set if there is not the memory. Keeps d2-d7/a2-a6.
pakhunk	move.l	(a3),d0
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
.nf	move.l	d0,-(sp)
	bsr	alloc
	move.l	(sp)+,d1
	tst.l	d0
	beq.s	.x
	movea.l	d0,a0
	move.l	d1,(a0)+			;size
	clr.l	(a0)+				;(the next hunk: linked at the end)
	move.l	d6,d0
	lsl.l	#2,d0
	lea	hunkbase,a1
	move.l	a0,(a1,d0.l)
	moveq	#1,d0				;(not Z)
.x	rts

;	Free the hunks pakhunk allocated (a failed load). Keeps a6.
pakfreeh
	move.l	a6,-(sp)
	movea.l	(4).w,a6
	lea	hunkbase,a2
	moveq	#MAXHUNKS-1,d2
.f	move.l	(a2),d0
	beq.s	.n
	clr.l	(a2)
	movea.l	d0,a1
	subq.l	#8,a1
	move.l	(a1),d0
	jsr	EXEC_FreeMem(a6)
.n	addq.l	#4,a2
	dbf	d2,.f
	movea.l	(sp)+,a6
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
intname		dc.b	'intuition.library',0
gamename	dc.b	'PROGDIR:NHL94.game',0
pakname		dc.b	'PROGDIR:NHL94.pak',0
msgpak		dc.b	'NHL94.pak is damaged.',0
msgload		dc.b	'Cannot load NHL94.game.',10
		dc.b	'It must be in the same directory as NHL94.',0
msgmem		dc.b	'Not enough memory to load NHL94.game.',10,10
		dc.b	'It takes %ld KB of chip RAM (in blocks of up to %ld KB)',10
		dc.b	'and %ld KB of fast RAM. Free now: %ld KB of chip RAM',10
		dc.b	'(the largest block %ld KB) and %ld KB of fast RAM.',10,10
		dc.b	'Quit other programs, close their windows on the',10
		dc.b	'Workbench screen, or start NHL 94 from a startup-',10
		dc.b	'sequence (an AGA Amiga with 2 MB chip RAM and',10
		dc.b	'at least 2 MB fast RAM).',0
msgdos		dc.b	'NHL 94 must be started from a Shell,',10
		dc.b	'a startup-sequence or the Workbench.',0
	even

MAXHUNKS	equ	16

	section	stubbss,bss
dosbase		ds.l	1
intbase		ds.l	1				;(the Workbench closed: closewb)
memargs		ds.l	6				;(msgmem's figures)
wbmsg		ds.l	1
seglist		ds.l	1
pakbuf		ds.l	1
relbuf		ds.l	1
pakfh		ds.l	1				;NHL94.pak while it is read
pakhdr		ds.l	3+2*MAXHUNKS+1			;its header
hunks		ds.l	1				;the seglist being built
hunkbase	ds.l	MAXHUNKS
packed		ds.b	1
wbclosed	ds.b	1
		even
ifwork		ds.b	IF_SIZE
