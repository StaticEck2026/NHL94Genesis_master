;	AmigaDOS side: checks the machine, loads the save file, stops the floppy motors, takes the
;	machine over and runs the game; on exit gives the machine back to the OS and writes the save file.

EXEC_Forbid		equ	-132
EXEC_Permit		equ	-138
EXEC_Disable		equ	-120
EXEC_Enable		equ	-126
EXEC_AllocMem		equ	-198
EXEC_FreeMem		equ	-210
EXEC_AllocAbs		equ	-204
EXEC_AvailMem		equ	-216
EXEC_OpenLibrary	equ	-552
EXEC_CloseLibrary	equ	-414
EXEC_Supervisor		equ	-30
EXEC_CacheControl	equ	-648
EXEC_OpenResource	equ	-498
EXEC_CacheClearU	equ	-636
EXEC_OpenDevice		equ	-444
EXEC_CloseDevice	equ	-450
EXEC_DoIO		equ	-456
EXEC_CreateIORequest	equ	-654
EXEC_DeleteIORequest	equ	-660
EXEC_CreateMsgPort	equ	-666
EXEC_DeleteMsgPort	equ	-672
GFX_LoadView		equ	-222
GFX_WaitTOF		equ	-270
GFX_OwnBlitter		equ	-456
GFX_DisownBlitter	equ	-462
GFX_WaitBlit		equ	-228
DOS_Open		equ	-30
DOS_Close		equ	-36
DOS_Read		equ	-42
DOS_Write		equ	-48
CIA_AbleICR		equ	-18
MEMF_PUBLIC		equ	1
MEMF_CHIP		equ	2
MEMF_FAST		equ	4
MEMF_LARGEST		equ	$20000
CACRF_EnableI		equ	$1
CACRF_EnableD		equ	$100

	section	game,code

_start
	movem.l	d1-d7/a0-a6,-(sp)
	move.l	sp,(os_sp).l
	movea.l	(4).w,a6
	move.l	a6,(os_exec).l
	lea	(.dosname,pc),a1
	moveq	#36,d0
	jsr	EXEC_OpenLibrary(a6)
	move.l	d0,(os_dos).l
	beq	.fail
	lea	(.gfxname,pc),a1
	moveq	#36,d0
	jsr	EXEC_OpenLibrary(a6)
	move.l	d0,(os_gfx).l
	beq	.fail
	btst	#1,$129(a6)
	bne	.cpu
	lea	(.msgcpu,pc),a0
	bra	.error
.cpu	movea.l	(os_gfx).l,a0
	btst	#2,$EC(a0)
	bne	.aga
	move.w	(CUSTOM+$07C).l,d0
	cmpi.b	#$F8,d0
	beq	.aga
	lea	(.msgaga,pc),a0
	bra	.error
.aga
	movea.l	(os_gfx).l,a0
	btst	#2,$CE+1(a0)
	sne	(hal_pal).l
	sne	(hal_palclk).l
	movea.l	(os_exec).l,a6
	move.l	#$20000,d0
	moveq	#MEMF_FAST,d1
	jsr	EXEC_AllocMem(a6)
	tst.l	d0
	bne	.win
	move.l	#$20000,d0
	moveq	#MEMF_PUBLIC,d1
	jsr	EXEC_AllocMem(a6)
	tst.l	d0
	bne	.win
	lea	(.msgnomem,pc),a0
	bra	.error
.win
	move.l	d0,d2
	jsr	EXEC_Forbid(a6)
	movea.l	d2,a1
	move.l	#$20000,d0
	jsr	EXEC_FreeMem(a6)
	move.l	d2,d1
	addi.l	#$FFFF,d1
	clr.w	d1
	movea.l	d1,a1
	move.l	#$10000,d0
	jsr	EXEC_AllocAbs(a6)
	move.l	#$10000,(os_backsz).l
	tst.l	d0
	bne.s	.wa
	movea.l	d2,a1
	move.l	#$20000,d0
	jsr	EXEC_AllocAbs(a6)
	move.l	#$20000,(os_backsz).l
	tst.l	d0
	bne.s	.wa
	jsr	EXEC_Permit(a6)
	lea	(.msgnomem,pc),a0
	bra	.error
.wa	move.l	d0,(os_backup).l
	jsr	EXEC_Permit(a6)
	move.l	(os_backup).l,d0
	addi.l	#$FFFF,d0
	clr.w	d0
	movea.l	d0,a0
	bsr	ram_relocate
	jsr	EXEC_CacheClearU(a6)
	bsr	os_load_sram
	move.l	#MEMF_CHIP|MEMF_LARGEST,d1
	jsr	EXEC_AvailMem(a6)
	subi.l	#$8000,d0
	cmpi.l	#SCXMAX,d0
	ble.s	.xs
	move.l	#SCXMAX,d0
.xs	andi.l	#-$4000,d0
	cmpi.l	#$8000,d0
	blt.s	.nx
	move.l	d0,d2
	moveq	#MEMF_CHIP,d1
	jsr	EXEC_AllocMem(a6)
	tst.l	d0
	beq.s	.nx
	move.l	d0,(rd_scx).l
	move.l	d2,(rd_scxsz).l
.nx
	lea	(.cianame,pc),a1
	jsr	EXEC_OpenResource(a6)
	move.l	d0,(os_ciab).l
	beq	.nocia
	movea.l	d0,a6
	moveq	#0,d0
	jsr	CIA_AbleICR(a6)
	move.b	d0,(os_ciabmask).l
.nocia	movea.l	(os_exec).l,a6
	lea	(.ciaaname,pc),a1
	jsr	EXEC_OpenResource(a6)
	tst.l	d0
	beq	.nocia2
	movea.l	d0,a6
	moveq	#0,d0
	jsr	CIA_AbleICR(a6)
	move.b	d0,(os_ciaamask).l
.nocia2
	movea.l	(os_exec).l,a6
	moveq	#CACRF_EnableI,d0
	move.l	#CACRF_EnableI|CACRF_EnableD,d1
	jsr	EXEC_CacheControl(a6)
	move.l	d0,(os_cacr).l
	bsr	os_motors
	movea.l	(os_gfx).l,a6
	move.l	$22(a6),(os_view).l
	suba.l	a1,a1
	jsr	GFX_LoadView(a6)
	jsr	GFX_WaitTOF(a6)
	jsr	GFX_WaitTOF(a6)
	jsr	GFX_OwnBlitter(a6)
	jsr	GFX_WaitBlit(a6)
	movea.l	(os_exec).l,a6
	jsr	EXEC_Forbid(a6)
	jsr	EXEC_Disable(a6)
	lea	(CUSTOM).l,a0
	move.w	INTENAR(a0),(os_intena).l
	move.w	DMACONR(a0),(os_dmacon).l
	move.w	$010(a0),(os_adkcon).l
	move.b	(CIAB_CRA).l,(os_ciabcra).l
	move.w	#$7FFF,INTENA(a0)
	move.w	#$7FFF,DMACON(a0)
	move.w	#$7FFF,INTREQ(a0)
	move.w	#$7FFF,INTREQ(a0)
	lea	(os_super,pc),a5
	jsr	EXEC_Supervisor(a6)
	lea	(CUSTOM).l,a0
	tst.b	(hal_beam).l
	beq.s	.beam
	moveq	#0,d0
	tst.b	(hal_palclk).l
	beq.s	.bn
	moveq	#$20,d0
.bn	move.w	d0,$1DC(a0)
.beam
	move.w	#$7FFF,DMACON(a0)
	move.w	#$7FFF,INTREQ(a0)
	move.w	(os_adkcon).l,d0
	ori.w	#$8000,d0
	move.w	#$7FFF,$09E(a0)
	move.w	d0,$09E(a0)
	move.w	(os_dmacon).l,d0
	ori.w	#$8000,d0
	move.w	d0,DMACON(a0)
	move.w	(os_intena).l,d0
	ori.w	#$8000,d0
	move.w	d0,INTENA(a0)
	jsr	EXEC_Enable(a6)
	jsr	EXEC_Permit(a6)
	movea.l	(os_gfx).l,a6
	move.l	$26(a6),(CUSTOM+$080).l
	movea.l	(os_view).l,a1
	jsr	GFX_LoadView(a6)
	jsr	GFX_WaitTOF(a6)
	jsr	GFX_DisownBlitter(a6)
	movea.l	(os_exec).l,a6
	move.l	(os_cacr).l,d0
	move.l	#CACRF_EnableI|CACRF_EnableD,d1
	jsr	EXEC_CacheControl(a6)
	bsr	os_save_sram
	movea.l	(os_backup).l,a1
	move.l	(os_backsz).l,d0
	jsr	EXEC_FreeMem(a6)
	move.l	(rd_scxsz).l,d0
	beq.s	.nxf
	movea.l	(rd_scx).l,a1
	jsr	EXEC_FreeMem(a6)
.nxf	moveq	#0,d7
	bra	.close
.error	bsr	ezrequest
.fail	moveq	#20,d7
.close	movea.l	(os_exec).l,a6
	move.l	(os_gfx).l,d0
	beq	.c1
	movea.l	d0,a1
	jsr	EXEC_CloseLibrary(a6)
.c1	move.l	(os_dos).l,d0
	beq	.c2
	movea.l	d0,a1
	jsr	EXEC_CloseLibrary(a6)
.c2	move.l	d7,d0
	movea.l	(os_sp).l,sp
	movem.l	(sp)+,d1-d7/a0-a6
	rts
.dosname	dc.b	'dos.library',0
.gfxname	dc.b	'graphics.library',0
.cianame	dc.b	'ciab.resource',0
.ciaaname	dc.b	'ciaa.resource',0
.msgcpu		dc.b	'NHL 94 needs a 68020 or better.',0
.msgaga		dc.b	'NHL 94 needs the AGA chipset',10
		dc.b	'(Amiga 1200 / 4000 / CD32).',0
.msgnomem	dc.b	'Not enough memory.',0
	even

;	Move the Genesis RAM window to a0 (64K aligned): add the distance to
;	every long listed in ram_relocs (ramrel.py), which hold addresses in it.
ram_relocate
	movem.l	d0-d1/a1-a2,-(sp)
	move.l	a0,d1
	sub.l	#RAMBASE,d1
	lea	(ram_relocs).l,a1
.l	move.l	(a1)+,d0
	beq	.x
	movea.l	d0,a2
	add.l	d1,(a2)
	bra	.l
.x	movem.l	(sp)+,d0-d1/a1-a2
	rts

;	Supervisor mode, from exec's Supervisor(). Keeps the OS's stack and VBR and starts the game.
os_super
	move	#$2700,sr
	move.l	sp,(os_ssp).l
	movec	vbr,d0
	move.l	d0,(os_vbr).l
	jmp	hal_game_main

;	Back to the OS (Esc).
hal_exit
	move	#$2700,sr
	lea	(CUSTOM).l,a0
	move.w	#$7FFF,INTENA(a0)
	move.w	#$7FFF,DMACON(a0)
	move.w	#$7FFF,INTREQ(a0)
	move.w	#0,$02E(a0)
	move.w	#$000F,DMACON(a0)
	move.b	#$7F,(CIAB_ICR).l
	move.b	(os_ciabcra).l,(CIAB_CRA).l
	move.b	(os_ciabmask).l,d0
	ori.b	#$80,d0
	move.b	d0,(CIAB_ICR).l
	bsr	hal_kbd_exit
	jsr	(snd_exit).l
	jsr	(hal_cpu_exit).l
	move.l	(os_vbr).l,d0
	movec	d0,vbr
	movea.l	(os_ssp).l,sp
	movea.l	(os_exec).l,a6
	rte

	include	"request.i"

;	The floppy drives' motors off: the file system stops one a second or
;	two after its last read, and the game takes the machine before then.
os_motors
	movem.l	d0-d4/a0-a1/a6,-(sp)
	movea.l	(os_exec).l,a6
	jsr	EXEC_CreateMsgPort(a6)
	move.l	d0,d3
	beq.s	.x
	movea.l	d0,a0
	moveq	#56,d0
	jsr	EXEC_CreateIORequest(a6)
	move.l	d0,d2
	beq.s	.np
	moveq	#0,d4
.u	lea	(.tdname,pc),a0
	move.l	d4,d0
	movea.l	d2,a1
	moveq	#0,d1
	jsr	EXEC_OpenDevice(a6)
	tst.b	d0
	bne.s	.n
	movea.l	d2,a1
	move.w	#9,28(a1)
	clr.l	36(a1)
	jsr	EXEC_DoIO(a6)
	movea.l	d2,a1
	jsr	EXEC_CloseDevice(a6)
.n	addq.l	#1,d4
	cmpi.l	#4,d4
	blo.s	.u
	movea.l	d2,a0
	jsr	EXEC_DeleteIORequest(a6)
.np	movea.l	d3,a0
	jsr	EXEC_DeleteMsgPort(a6)
.x	movem.l	(sp)+,d0-d4/a0-a1/a6
	rts
.tdname	dc.b	'trackdisk.device',0
	even

;	The save file holds the save RAM (hal_sram: the cartridge's battery RAM, $2000 bytes).
os_load_sram
	movem.l	d1-d4/a0-a1/a6,-(sp)
	movea.l	(os_dos).l,a6
	move.l	#os_savename,d1
	move.l	#1005,d2
	jsr	DOS_Open(a6)
	move.l	d0,d4
	beq	.x
	move.l	d4,d1
	move.l	#os_iobuf,d2
	move.l	#$2000,d3
	jsr	DOS_Read(a6)
	cmpi.l	#$2000,d0
	bne	.cl
	lea	(os_iobuf).l,a0
	lea	(hal_sram).l,a1
	move.w	#$2000/4-1,d0
.cp	move.l	(a0)+,(a1)+
	dbf	d0,.cp
	st	(os_sramok).l
.cl	move.l	d4,d1
	jsr	DOS_Close(a6)
.x	movem.l	(sp)+,d1-d4/a0-a1/a6
	rts

os_save_sram
	movem.l	d1-d4/a0-a1/a6,-(sp)
	lea	(hal_sram).l,a0
	lea	(os_iobuf).l,a1
	move.w	#$2000/4-1,d0
.cp	move.l	(a0)+,(a1)+
	dbf	d0,.cp
	movea.l	(os_dos).l,a6
	move.l	#os_savename,d1
	move.l	#1006,d2
	jsr	DOS_Open(a6)
	move.l	d0,d4
	beq	.x
	move.l	d4,d1
	move.l	#os_iobuf,d2
	move.l	#$2000,d3
	jsr	DOS_Write(a6)
	move.l	d4,d1
	jsr	DOS_Close(a6)
.x	movem.l	(sp)+,d1-d4/a0-a1/a6
	rts

os_savename	dc.b	'PROGDIR:NHL94.sav',0
	even

	section	bss,bss
os_sp		ds.l	1
os_ssp		ds.l	1
os_vbr		ds.l	1
os_exec		ds.l	1
os_dos		ds.l	1
os_gfx		ds.l	1
os_ciab		ds.l	1
os_view		ds.l	1
os_backup	ds.l	1
os_backsz	ds.l	1
os_cacr		ds.l	1
os_intena	ds.w	1
os_dmacon	ds.w	1
os_adkcon	ds.w	1
os_ciabmask	ds.b	1
os_ciabcra	ds.b	1
os_ciaamask	ds.b	1
os_sramok	ds.b	1
hal_pal		ds.b	1
hal_palclk	ds.b	1
hal_beam	ds.b	1
		even
os_iobuf	ds.b	$2000

	section	game,code
