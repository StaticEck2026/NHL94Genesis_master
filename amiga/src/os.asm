;	AmigaDOS side: checks the machine, loads the save file, takes the machine over and runs the
;	game; on exit (Esc) gives the machine back to the OS and writes the save file.
;
;	The Genesis work RAM window is a 64K aligned block taken at start, in fast memory if there is
;	some; ram_relocate moves the program's references to it there.

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
EXEC_CacheClearU	equ	-636
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
MEMF_FAST		equ	4
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
	bne	.cpu
	lea	(.msgcpu,pc),a0
	bra	.error
.cpu	movea.l	(os_gfx).l,a0
	btst	#2,$EC(a0)			;ChipRevBits0: GFXB_AA_ALICE
	bne	.aga
	move.w	(CUSTOM+$07C).l,d0		;Lisa id: $F8 on AGA
	cmpi.b	#$F8,d0
	beq	.aga
	lea	(.msgaga,pc),a0
	bra	.error
.aga	; PAL or NTSC display
	movea.l	(os_gfx).l,a0
	btst	#2,$CE+1(a0)			;DisplayFlags: PAL
	sne	(hal_pal).l
	sne	(hal_palclk).l
	; the Genesis RAM window: 64K aligned in a 128K block, fast memory if there is some
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
.win	move.l	d0,(os_backup).l
	addi.l	#$FFFF,d0
	clr.w	d0
	movea.l	d0,a0
	bsr	ram_relocate
	jsr	EXEC_CacheClearU(a6)		;the code has changed
	bsr	os_load_sram
	; ciab.resource: which CIA-B interrupts the OS has on
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
	st	(hal_amiga).l
	; run the game in supervisor mode
	lea	(os_super,pc),a5
	jsr	EXEC_Supervisor(a6)
	; back from the game: user mode, interrupts still disabled by Disable()
	lea	(CUSTOM).l,a0
	tst.b	(hal_beam).l			;the display's own rate again
	beq.s	.beam
	moveq	#0,d0
	tst.b	(hal_palclk).l
	beq.s	.bn
	moveq	#$20,d0
.bn	move.w	d0,$1DC(a0)			;BEAMCON0
.beam
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
	IFD	PROFILE
	bsr	os_save_prof
	ENDIF
	movea.l	(os_backup).l,a1
	move.l	#$20000,d0
	jsr	EXEC_FreeMem(a6)
	moveq	#0,d7
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

;	Move the Genesis RAM window to a0 (64K aligned): add the distance to every long listed in
;	ram_relocs (ramrel.py), which hold addresses in it. Called once, before the window is used.
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

;	Back to the OS (Esc). Called in supervisor mode from anywhere in the game.
hal_exit
	move	#$2700,sr
	lea	(CUSTOM).l,a0
	IFD	PROFILE
	move.w	$01E(a0),(prof_intreq+2).l	;(statistics: the blit queue's copper state)
	ENDC
	move.w	#$7FFF,INTENA(a0)
	move.w	#$7FFF,DMACON(a0)
	move.w	#$7FFF,INTREQ(a0)
	move.w	#0,$02E(a0)			;COPCON: the copper off the blitter again
	move.w	#$000F,DMACON(a0)		;sound off
	move.b	#$7F,(CIAB_ICR).l		;CIA-B: our timer off, the OS's interrupts back
	move.b	(os_ciabcra).l,(CIAB_CRA).l
	move.b	(os_ciabmask).l,d0
	ori.b	#$80,d0
	move.b	d0,(CIAB_ICR).l
	bsr	hal_kbd_exit
	jsr	(snd_exit).l
	move.l	(os_vbr).l,d0
	movec	d0,vbr
	movea.l	(os_ssp).l,sp
	movea.l	(os_exec).l,a6
	rte					;returns from Supervisor()

	include	"request.i"

;	The save file holds the cartridge's battery RAM ($2000 bytes, in the odd bytes of hal_sram).
os_load_sram
	movem.l	d1-d4/a0-a1/a6,-(sp)
	movea.l	(os_dos).l,a6
	move.l	#os_savename,d1
	move.l	#1005,d2			;MODE_OLDFILE
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
	beq	.x
	move.l	d4,d1
	move.l	#os_iobuf,d2
	move.l	#$2000,d3
	jsr	DOS_Write(a6)
	move.l	d4,d1
	jsr	DOS_Close(a6)
.x	movem.l	(sp)+,d1-d4/a0-a1/a6
	rts

	IFD	PROFILE
;	PC samples: the code base, the count, then the samples.
os_save_prof
	movem.l	d1-d4/a0-a1/a6,-(sp)
	movea.l	(os_dos).l,a6
	move.l	#.name,d1
	move.l	#1006,d2
	jsr	DOS_Open(a6)
	move.l	d0,d4
	beq	.x
	lea	hal_header(pc),a0
	move.l	a0,(os_iobuf).l
	move.l	#PROFMAX,d0
	cmp.l	(prof_count).l,d0
	bls.s	.full
	move.l	(prof_count).l,d0
.full	move.l	d0,(os_iobuf+4).l
	move.l	d4,d1
	move.l	#os_iobuf,d2
	moveq	#8,d3
	jsr	DOS_Write(a6)
	move.l	d4,d1
	move.l	#prof_buf,d2
	move.l	(os_iobuf+4).l,d3
	lsl.l	#2,d3
	jsr	DOS_Write(a6)
	; then frames drawn and game frames at the F9 mark and now, and the game frame rate
	move.l	(rd_count).l,(prof_mark+8).l
	move.l	(hal_frames).l,(prof_mark+12).l
	moveq	#0,d0
	move.w	(hal_hz).l,d0
	move.l	d0,(prof_mark+16).l
	move.w	(snd_delay).l,d0		;(and the sound's delay now: the last slot)
	move.l	d0,(prof_mark+52+60).l
	move.l	d4,d1
	move.l	#prof_mark,d2
	move.l	#52+64+16,d3
	jsr	DOS_Write(a6)
	; then the events (prof_ev): count, position, the ring
	move.l	d4,d1
	move.l	#prof_evpos,d2
	moveq	#8,d3
	jsr	DOS_Write(a6)
	move.l	d4,d1
	move.l	#prof_ev,d2
	move.l	#PEVMAX*4,d3
	jsr	DOS_Write(a6)
	; then the blit queue's copper ring: INTREQR at the exit, rd_cqwp .. rd_cqmq, the ring
	move.l	d4,d1
	move.l	#prof_intreq,d2
	moveq	#4,d3
	jsr	DOS_Write(a6)
	move.l	d4,d1
	move.l	#rd_cqwp,d2
	move.l	#32+128,d3
	jsr	DOS_Write(a6)
	move.l	d4,d1
	move.l	(rd_cqring).l,d2
	move.l	#CQI,d3
	jsr	DOS_Write(a6)
	IFD	BENCH
	move.l	d4,d1				;then the game RAM's sums at each tick (BENCH)
	move.l	#bench_tlog,d2
	move.l	#8192*4,d3
	jsr	DOS_Write(a6)
	IFD	BENCHDUMP
	move.l	d4,d1
	move.l	#bench_ram,d2
	move.l	#$10000,d3
	jsr	DOS_Write(a6)
	ENDC
	ENDC
	move.l	d4,d1
	jsr	DOS_Close(a6)
.x	movem.l	(sp)+,d1-d4/a0-a1/a6
	rts
.name	dc.b	'PROGDIR:nhl94.prof',0
	even
	ENDIF

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
os_backup	ds.l	1			;the block that holds the RAM window
os_cacr		ds.l	1
os_intena	ds.w	1
os_dmacon	ds.w	1
os_adkcon	ds.w	1
os_ciabmask	ds.b	1
os_ciabcra	ds.b	1
os_ciaamask	ds.b	1
os_sramok	ds.b	1
hal_amiga	ds.b	1			;set when started from AmigaDOS (not the test harness)
hal_pal		ds.b	1			;PAL display (50 Hz; F8 switches it)
hal_palclk	ds.b	1			;PAL machine (its clocks)
hal_beam	ds.b	1			;the display's rate was switched (BEAMCON0)
		even
os_iobuf	ds.b	$2000

	section	game,code
