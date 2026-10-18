;	AmigaDOS side: checks the machine, loads the save file, takes the machine over and runs the
;	game; on exit (Esc) gives the machine back to the OS and writes the save file.
;
;	The Genesis work RAM is the fixed 64K at RAMBASE (amiga.i). While the game runs that memory
;	is ours: its OS contents are copied out at the take over and back at the exit. None of the
;	program's own hunks may be there (they are checked).

EXEC_Forbid		equ	-132
EXEC_Permit		equ	-138
EXEC_Disable		equ	-120
EXEC_Enable		equ	-126
EXEC_AllocMem		equ	-198
EXEC_FreeMem		equ	-210
EXEC_OpenLibrary	equ	-552
EXEC_CloseLibrary	equ	-414
EXEC_Supervisor		equ	-30
EXEC_CacheControl	equ	-648
EXEC_OpenResource	equ	-498
GFX_LoadView		equ	-222
GFX_WaitTOF		equ	-270
GFX_OwnBlitter		equ	-456
GFX_DisownBlitter	equ	-462
GFX_WaitBlit		equ	-228
DOS_Open		equ	-30
DOS_Close		equ	-36
DOS_Read		equ	-42
DOS_Write		equ	-48
DOS_Output		equ	-60
CIA_AbleICR		equ	-18
MEMF_PUBLIC		equ	1
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
	; 68020 or better, AGA
	btst	#1,$129(a6)			;AttnFlags: AFB_68020
	bne.s	.cpu
	lea	(.msgcpu,pc),a0
	bra	.error
.cpu	movea.l	(os_gfx).l,a0
	btst	#2,$EC(a0)			;ChipRevBits0: GFXB_AA_ALICE
	bne.s	.aga
	move.w	(CUSTOM+$07C).l,d0		;Lisa id: $F8 on AGA
	cmpi.b	#$F8,d0
	beq.s	.aga
	lea	(.msgaga,pc),a0
	bra	.error
.aga	; none of our hunks may lie in the Genesis RAM window
	lea	(os_sections,pc),a2
.sec	move.l	(a2)+,d0
	beq.s	.secok
	move.l	(a2)+,d1
	cmpi.l	#RAMBASE+$10000,d0
	bhs.s	.sec
	cmpi.l	#RAMBASE,d1
	bls.s	.sec
	lea	(.msgmem,pc),a0
	bra	.error
.secok	; PAL or NTSC display
	movea.l	(os_gfx).l,a0
	btst	#2,$CE+1(a0)			;DisplayFlags: PAL
	sne	(hal_pal).l
	; a buffer for the OS's contents of the Genesis RAM window
	move.l	#$10000,d0
	moveq	#MEMF_PUBLIC,d1
	movea.l	(os_exec).l,a6
	jsr	EXEC_AllocMem(a6)
	move.l	d0,(os_backup).l
	bne.s	.mem
	lea	(.msgnomem,pc),a0
	bra	.error
.mem	bsr	os_load_sram
	; ciab.resource: which CIA-B interrupts the OS has on
	lea	(.cianame,pc),a1
	jsr	EXEC_OpenResource(a6)
	move.l	d0,(os_ciab).l
	beq.s	.nocia
	movea.l	d0,a6
	moveq	#0,d0
	jsr	CIA_AbleICR(a6)
	move.b	d0,(os_ciabmask).l
.nocia	movea.l	(os_exec).l,a6
	lea	(.ciaaname,pc),a1
	jsr	EXEC_OpenResource(a6)
	tst.l	d0
	beq.s	.nocia2
	movea.l	d0,a6
	moveq	#0,d0
	jsr	CIA_AbleICR(a6)
	move.b	d0,(os_ciaamask).l
.nocia2	; data cache off (the blitter and the CPU share the screens)
	movea.l	(os_exec).l,a6
	moveq	#0,d0
	move.l	#CACRF_EnableD,d1
	jsr	EXEC_CacheControl(a6)
	move.l	d0,(os_cacr).l
	; take the display and the blitter
	movea.l	(os_gfx).l,a6
	move.l	$22(a6),(os_view).l		;ActiView
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
	; save the OS's memory in the Genesis RAM window
	lea	(RAMBASE).l,a0
	movea.l	(os_backup).l,a1
	move.w	#$10000/16-1,d0
.bk	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d0,.bk
	st	(hal_amiga).l
	; run the game in supervisor mode
	lea	(os_super,pc),a5
	jsr	EXEC_Supervisor(a6)
	; back from the game: user mode, interrupts still disabled by Disable()
	lea	(CUSTOM).l,a0
	move.w	#$7FFF,DMACON(a0)
	move.w	#$7FFF,INTREQ(a0)
	move.w	(os_adkcon).l,d0
	ori.w	#$8000,d0
	move.w	#$7FFF,$09E(a0)
	move.w	d0,$09E(a0)			;ADKCON
	move.w	(os_dmacon).l,d0
	ori.w	#$8000,d0
	move.w	d0,DMACON(a0)
	move.w	(os_intena).l,d0
	ori.w	#$8000,d0
	move.w	d0,INTENA(a0)
	jsr	EXEC_Enable(a6)
	jsr	EXEC_Permit(a6)
	movea.l	(os_gfx).l,a6
	move.l	$26(a6),(CUSTOM+$080).l		;copinit
	movea.l	(os_view).l,a1
	jsr	GFX_LoadView(a6)
	jsr	GFX_WaitTOF(a6)
	jsr	GFX_DisownBlitter(a6)
	movea.l	(os_exec).l,a6
	move.l	(os_cacr).l,d0
	move.l	#CACRF_EnableD,d1
	jsr	EXEC_CacheControl(a6)
	bsr	os_save_sram
	movea.l	(os_backup).l,a1
	move.l	#$10000,d0
	jsr	EXEC_FreeMem(a6)
	moveq	#0,d7
	bra.s	.close
.error	bsr	os_print
.fail	moveq	#20,d7
.close	movea.l	(os_exec).l,a6
	move.l	(os_gfx).l,d0
	beq.s	.c1
	movea.l	d0,a1
	jsr	EXEC_CloseLibrary(a6)
.c1	move.l	(os_dos).l,d0
	beq.s	.c2
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
.msgcpu		dc.b	'NHL 94 needs a 68020 or better.',10,0
.msgaga		dc.b	'NHL 94 needs the AGA chipset (Amiga 1200 / 4000 / CD32).',10,0
.msgmem		dc.b	'NHL 94 was loaded where it needs its work RAM. Reboot and start it first.',10,0
.msgnomem	dc.b	'Not enough memory.',10,0
	even

;	The sections (start, end), for the RAM window check.
os_sections
	dc.l	hal_header,game_end
	dc.l	bss_start,bss_end
	dc.l	chip_start,chip_end
	dc.l	0

;	Supervisor mode, from exec's Supervisor(). Keeps the OS's stack and VBR and starts the game.
os_super
	move	#$2700,sr
	move.l	sp,(os_ssp).l
	movec	vbr,d0
	move.l	d0,(os_vbr).l
	jmp	hal_game_main

;	Back to the OS (Esc). Called in supervisor mode from anywhere in the game.
hal_exit
	move	#$2700,sr
	lea	(CUSTOM).l,a0
	move.w	#$7FFF,INTENA(a0)
	move.w	#$7FFF,DMACON(a0)
	move.w	#$7FFF,INTREQ(a0)
	move.w	#$000F,DMACON(a0)		;sound off
	move.b	#$7F,(CIAB_ICR).l		;CIA-B: our timer off, the OS's interrupts back
	move.b	(os_ciabcra).l,(CIAB_CRA).l
	move.b	(os_ciabmask).l,d0
	ori.b	#$80,d0
	move.b	d0,(CIAB_ICR).l
	bsr	hal_kbd_exit
	; the OS's memory back
	movea.l	(os_backup).l,a0
	lea	(RAMBASE).l,a1
	move.w	#$10000/16-1,d0
.rs	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d0,.rs
	move.l	(os_vbr).l,d0
	movec	d0,vbr
	movea.l	(os_ssp).l,sp
	movea.l	(os_exec).l,a6
	rte					;returns from Supervisor()

;	Print the 0 ended text a0 on the CLI.
os_print
	movem.l	d1-d3/a0-a1/a6,-(sp)
	movea.l	a0,a1
	moveq	#-1,d3
.len	addq.l	#1,d3
	tst.b	(a1)+
	bne.s	.len
	move.l	a0,-(sp)
	movea.l	(os_dos).l,a6
	jsr	DOS_Output(a6)
	move.l	d0,d1
	move.l	(sp)+,d2
	beq.s	.x
	tst.l	d1
	beq.s	.x
	jsr	DOS_Write(a6)
.x	movem.l	(sp)+,d1-d3/a0-a1/a6
	rts

;	The save file holds the cartridge's battery RAM ($2000 bytes, in the odd bytes of hal_sram).
os_load_sram
	movem.l	d1-d4/a0-a1/a6,-(sp)
	movea.l	(os_dos).l,a6
	move.l	#os_savename,d1
	move.l	#1005,d2			;MODE_OLDFILE
	jsr	DOS_Open(a6)
	move.l	d0,d4
	beq.s	.x
	move.l	d4,d1
	move.l	#os_iobuf,d2
	move.l	#$2000,d3
	jsr	DOS_Read(a6)
	cmpi.l	#$2000,d0
	bne.s	.cl
	lea	(os_iobuf).l,a0
	lea	(hal_sram+1).l,a1
	move.w	#$1FFF,d0
.cp	move.b	(a0)+,(a1)
	addq.l	#2,a1
	dbf	d0,.cp
	st	(os_sramok).l
.cl	move.l	d4,d1
	jsr	DOS_Close(a6)
.x	movem.l	(sp)+,d1-d4/a0-a1/a6
	rts

os_save_sram
	movem.l	d1-d4/a0-a1/a6,-(sp)
	lea	(hal_sram+1).l,a0
	lea	(os_iobuf).l,a1
	move.w	#$1FFF,d0
.cp	move.b	(a0),(a1)+
	addq.l	#2,a0
	dbf	d0,.cp
	movea.l	(os_dos).l,a6
	move.l	#os_savename,d1
	move.l	#1006,d2			;MODE_NEWFILE
	jsr	DOS_Open(a6)
	move.l	d0,d4
	beq.s	.x
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
os_cacr		ds.l	1
os_intena	ds.w	1
os_dmacon	ds.w	1
os_adkcon	ds.w	1
os_ciabmask	ds.b	1
os_ciabcra	ds.b	1
os_ciaamask	ds.b	1
os_sramok	ds.b	1
hal_amiga	ds.b	1			;set when started from AmigaDOS (not the test harness)
hal_pal		ds.b	1			;PAL display
		even
os_iobuf	ds.b	$2000

	section	game,code
