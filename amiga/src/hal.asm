;	Amiga hardware layer: entry point, the game's frame tick (its vertical blank) on
;	a CIA timer or the display's vertical blank, the save RAM and the exception trap.

CUSTOM		equ	$DFF000
INTENA		equ	$09A
INTENAR		equ	$01C
INTREQ		equ	$09C
INTREQR		equ	$01E
DMACON		equ	$096
DMACONR		equ	$002
CIAB_ICR	equ	$BFDD00
CIAB_CRA	equ	$BFDE00
CIAB_CRB	equ	$BFDF00
CIAB_TALO	equ	$BFD400
CIAB_TAHI	equ	$BFD500
CIAB_TODLO	equ	$BFD800
CIAB_TODMID	equ	$BFD900
CIAB_TODHI	equ	$BFDA00

CIA_CLOCK	equ	709379
CIA_CLOCK_NTSC	equ	715909
RDPACE		equ	1

	section	game,code
hal_header
	bra.w	_start
	IFD	HARNESS
	dc.b	'NH94'
	dc.l	hal_game_main
	dc.l	hal_debug
	ENDC

;	The timer period for hal_hz frames a second (a running
;	timer takes it at its next underflow). Keeps all but d0.
hal_set_rate
	move.l	d1,-(sp)
	clr.w	(hal_pal50).l
	bclr	#0,(PALflag).l
	clr.w	(PalMode).l
	cmpi.w	#50,(hal_hz).l
	bne.s	.ntsc
	move.w	#1,(hal_pal50).l
	bset	#0,(PALflag).l
	move.w	#1,(PalMode).l
.ntsc	move.l	#CIA_CLOCK,d0
	tst.b	(hal_palclk).l
	bne.s	.p
	move.l	#CIA_CLOCK_NTSC,d0
.p	move.w	(hal_hz).l,d1
	divu.w	d1,d0
	move.b	d0,(CIAB_TALO).l
	lsr.w	#8,d0
	move.b	d0,(CIAB_TAHI).l
	moveq	#60,d1
	tst.b	(hal_pal).l
	beq.s	.n
	moveq	#50,d1
.n	cmp.w	(hal_hz).l,d1
	seq	(hal_vbtick).l
	move.l	(sp)+,d1
	rts

	IFD	HARNESS
;	Read by the test harness (amiga/harness/nhlrun.c: DB_*).
hal_debug
	dc.l	hal_exc_info,hal_frames,hal_padstate,rd_count
	dc.l	game_code,game_code_end,rd_lastframe,rd_busy
	dc.l	hal_starve,ctx_cur
	dc.l	rd_spin_vs,rd_spin_q,rd_spin_w,rd_spin_full
	dc.l	ctx_to_game,hal_idle_no,rd_scx,hal_early
	dc.l	hal_hwin,rd_wstat,RAMBASE
	ENDC

;	Game entry with interrupts off and the machine ours.
hal_game_main
	move	#$2700,sr
	IFD	HARNESS
	movea.l	(hal_hwin).l,a0
	bsr	ram_relocate
	ENDC
	lea	(RAMBASE).l,a0
	move.w	#$10000/4-1,d0
.clr	clr.l	(a0)+
	dbf	d0,.clr
	lea	(RAMBASE+$FFF0).l,sp
	bsr	vm_init
	jsr	(snd_init).l
	bsr	hal_set_vectors
	IFND	HARNESS
	bsr	hal_cpu_setup
	ENDC
	jsr	(rd_init).l
	bsr	hal_display_init
	bsr	ctx_init
	IFND	HARNESS
	bsr	hal_kbd_init
	ENDC
	bsr	hal_start_timer
	jmp	Begin

;	Fill the vector table (VBR) with the trap, then the interrupt handlers.
hal_set_vectors
	lea	(hal_vectors).l,a0
	lea	hal_exception(pc),a1
	moveq	#63,d0
.v	move.l	a1,(a0)+
	dbf	d0,.v
	lea	(hal_vectors).l,a0
	lea	hal_int_ignore(pc),a1
	move.l	a1,$64(a0)
	move.l	a1,$68(a0)
	lea	rd_bq_int(pc),a2
	move.l	a2,$6C(a0)
	move.l	a1,$70(a0)
	move.l	a1,$74(a0)
	move.l	a1,$7C(a0)
	move.l	a1,$60(a0)
	lea	hal_int6(pc),a1
	move.l	a1,$78(a0)
	lea	ctx_to_render(pc),a1
	move.l	a1,$80(a0)
	lea	ctx_to_game(pc),a1
	move.l	a1,$84(a0)
	movec	a0,vbr
	rts

;	A 68040 or 68060, found by a control register only they have, not by exec's AttnFlags: for
;	the game its data cache and store buffer off, and the first 16 MB not cached and in order.
hal_cpu_setup
	movem.l	d0/a0-a2,-(sp)
	lea	(hal_vectors).l,a0
	move.l	4*4(a0),a2
	lea	(.no,pc),a1
	move.l	a1,4*4(a0)
	movea.l	sp,a1
	dc.w	$4E7A,$0006
	move.l	d0,(hal_dtt0).l
	movec	cacr,d0
	move.l	d0,(hal_cacr0).l
	dc.w	$F478
	andi.l	#~$A0000000,d0
	movec	d0,cacr
	move.l	#$0000C040,d0
	dc.w	$4E7B,$0006
	st	(hal_cpu40).l
.no	movea.l	a1,sp
	move.l	a2,4*4(a0)
	movem.l	(sp)+,d0/a0-a2
	rts

;	The 68040's or 68060's cache settings as they were (hal_cpu_setup),
;	with nothing left in the data cache from before the game. Uses d0.
hal_cpu_exit
	tst.b	(hal_cpu40).l
	beq.s	.x
	dc.w	$F458
	move.l	(hal_dtt0).l,d0
	dc.w	$4E7B,$0006
	move.l	(hal_cacr0).l,d0
	movec	d0,cacr
.x	rts

;	CIA-B timer A, continuous, at the game's frame rate (hal_hz), on level 6.
hal_start_timer
	move.b	#$7F,(CIAB_ICR).l
	move.b	#0,(CIAB_CRA).l
	tst.w	(hal_hz).l
	bne.s	.hz
	move.w	#60,(hal_hz).l
	tst.b	(hal_pal).l
	beq.s	.hz
	move.w	#50,(hal_hz).l
.hz	bsr	hal_set_rate
	move.b	#$81,(CIAB_ICR).l
	move.b	#$11,(CIAB_CRA).l
	move.w	#$2000,(CUSTOM+INTREQ).l
	move.w	#$C000|$2000|$0020|$0010,(CUSTOM+INTENA).l
	rts

;	The code a game tick interrupts, from its exception frame at a0: its pc to
;	hal_pcring (the crash report), its sr and the context after them. Uses d0-d1, a0.
hal_pcnote
	moveq	#0,d1
	move.w	(a0)+,d1
	swap	d1
	move.b	(ctx_cur).l,d1
	move.l	(a0),d0
	lea	(hal_pcring).l,a0
	move.l	d1,64(a0)
	move.w	(hal_pcpos).l,d1
	move.l	d0,(a0,d1.w)
	addq.w	#4,d1
	andi.w	#63,d1
	move.w	d1,(hal_pcpos).l
	rts

;	Level 6.
hal_int6
	move.l	d0,-(sp)
	move.b	(CIAB_ICR).l,d0
	move.w	#$2000,(CUSTOM+INTREQ).l
	tst.b	(hal_vbreq).l
	bne.s	.vb
	btst	#0,d0
	beq	.none
	tst.b	(hal_vbtick).l
	bne	.none
	movem.l	d1/a0,-(sp)
	lea	12(sp),a0
	bsr	hal_pcnote
	movem.l	(sp)+,d1/a0
	bra.s	.tick
.vb	sf	(hal_vbreq).l
.tick	move.l	(sp)+,d0
	tst.b	(hal_ahead).l
	beq.s	.nah
	sf	(hal_ahead).l
	jsr	(snd_play).l
	rte
.nah
	tst.b	(ctx_cur).l
	beq.s	.gm
	movem.l	d0/a0,-(sp)
	movea.l	(ctx_game_sp).l,a0
	move.w	15*4(a0),d0
	andi.w	#$0600,d0
	cmpi.w	#$0600,d0
	movem.l	(sp)+,d0/a0
	bne.s	.gm
	rte
.gm
	addq.l	#1,(hal_frames).l
	move.l	(rd_vblanks).l,(hal_tickvb).l
	jsr	(snd_frame).l
	tst.l	(VBint).l
	beq.s	.post
	move.w	#$0078,-(sp)
	pea	(.post).l
	move	sr,-(sp)
	move.l	(VBint).l,-(sp)
	rts
.post
	btst	#2,(sp)
	bne.s	.nest
	btst	#1,(sp)
	bne.s	.nest
	btst	#0,(sp)
	bne.s	.nest
	tst.b	(ctx_cur).l
	bne	ctx_to_game
	addq.w	#1,(hal_starve).l
	cmpi.w	#3,(hal_starve).l
	blo.s	.rte
	tst.b	(ctx_ready).l
	beq.s	.rte
	clr.w	(hal_starve).l
	bra	ctx_to_render
.rte	rte
.nest
	tst.b	(ctx_cur).l
	beq.s	.rte
	st	(hal_swpend).l
	rte
.none	andi.b	#3,d0
	bne.s	.nc
	addq.l	#1,(hal_int6x).l
.nc	move.l	(sp)+,d0
	rte

;	Two contexts share the CPU: the game, and the renderer,
;	which only runs while the game waits for a vblank.

hal_idle
	move.l	d0,-(sp)
	move	sr,d0
	andi.w	#$0700,d0
	cmpi.w	#$0600,d0
	bhs	.no
	addq.l	#1,(hal_ipl0).l
	tst.b	(rd_busy).l
	bne.s	.go
	move.l	(hal_frames).l,d0
	sub.l	(rd_lastframe).l,d0
	cmp.l	(hal_pace).l,d0
	blo	.early
.go	tst.b	(ctx_ready).l
	beq	.no
	move.l	(sp)+,d0
	clr.w	(hal_starve).l
	trap	#0
	rts
.early	bsr	hal_tick_early
.no
hal_idle_no
	clr.w	(hal_starve).l
	move.l	(sp)+,d0
	rts

;	The game waits for the renderer to finish a frame half drawn (fe_ring),
;	not for a game tick: the renderer gets the CPU as in hal_idle. Keeps all.
hal_yield
	tst.b	(ctx_ready).l
	beq.s	.x
	clr.w	(hal_starve).l
	trap	#0
.x	rts

;	The game waits for a tick and the renderer has drawn its last state: the next
;	vertical blank's tick is run now, if this one's has run and none is ahead. Keeps all.
hal_tick_early
	move	sr,-(sp)
	ori	#$0700,sr
	IFD	HARNESS
	tst.b	(hal_early).l
	beq	.x
	ENDC
	tst.b	(hal_ahead).l
	bne	.x
	tst.b	(hal_vbtick).l
	beq	.x
	cmpi.l	#1,(hal_pace).l
	bne	.x
	tst.l	(VBint).l
	beq	.x
	move.l	d0,-(sp)
	move.l	(hal_tickvb).l,d0
	cmp.l	(rd_vblanks).l,d0
	move.l	(sp)+,d0
	bne	.x
	st	(hal_ahead).l
	addq.l	#1,(hal_frames).l
	move.l	(rd_vblanks).l,(hal_tickvb).l
	addq.l	#1,(hal_tickvb).l
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(snd_dly_push).l
	movem.l	(sp)+,d0-d7/a0-a6
	move.w	#$0078,-(sp)
	pea	(.r).l
	move.w	4+2(sp),-(sp)
	andi	#$FEFF,sr
	move.l	(VBint).l,-(sp)
	rts
.r
.x	move	(sp)+,sr
	rts
	IFD	HARNESS
hal_early	dc.b	1
	even
	ENDC

;	trap #0: game -> renderer.
ctx_to_render
	ori.w	#$0700,sr
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	sp,(ctx_game_sp).l
	st	(ctx_cur).l
	movea.l	(ctx_rend_sp).l,sp
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;	trap #1, or a vblank while drawing: renderer -> game.
ctx_to_game
	ori.w	#$0700,sr
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	sp,(ctx_rend_sp).l
	sf	(ctx_cur).l
	movea.l	(ctx_game_sp).l,sp
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;	The renderer's loop: draw each new frame, then give the CPU back.
rend_main
	addq.l	#1,(hal_ipl0).l
	move.l	(hal_frames).l,d0
	sub.l	(rd_lastframe).l,d0
	cmp.l	(hal_pace).l,d0
	blo	.yield
	move.l	(hal_frames).l,(rd_lastframe).l
	st	(rd_busy).l
	jsr	(rd_frame).l
	sf	(rd_busy).l
.yield	trap	#1
	bra	rend_main

;	Set up the renderer's context: its stack holds a frame that starts rend_main.
ctx_init
	lea	(rend_stack_top).l,a0
	move.w	#$0080,-(a0)
	move.l	#rend_main,-(a0)
	move.w	#$2000,-(a0)
	moveq	#14,d0
.r	clr.l	-(a0)
	dbf	d0,.r
	move.l	a0,(ctx_rend_sp).l
	sf	(ctx_cur).l
	st	(ctx_ready).l
	rts

;	Display: copper and bitplane DMA on, an empty copper list until the first frame.
hal_display_init
	lea	(hal_copempty).l,a0
	move.l	#$009C0006,(a0)
	move.l	#$01000200,4(a0)
	move.l	#$01800000,8(a0)
	lea	12(a0),a1
	move.l	#rd_sprnull,d1
	move.w	#$120,d2
	moveq	#7,d0
.sp	move.w	d2,(a1)+
	swap	d1
	move.w	d1,(a1)+
	addq.w	#2,d2
	move.w	d2,(a1)+
	swap	d1
	move.w	d1,(a1)+
	addq.w	#2,d2
	dbf	d0,.sp
	move.l	#$008A0000,(a1)
	move.l	a0,(CUSTOM+$080).l
	move.w	d0,(CUSTOM+$088).l
	move.w	#$83E0,(CUSTOM+DMACON).l
	rts

;	An interrupt the game does not use (none is on at INTENA: a spurious
;	one, level 7): counted for the crash report, its vector and INTREQR kept.
hal_int_ignore
	addq.l	#1,(hal_intx).l
	move.w	6(sp),(hal_intxv).l
	move.w	(CUSTOM+$01E).l,(hal_intxv+2).l
	rte

;	Any other exception: keep the frame and registers for the debugger, then hang.
hal_exception
	move	#$2700,sr
	movem.l	d0-d7/a0-a7,(hal_exc_regs).l
	move.l	(sp),(hal_exc_info).l
	move.l	4(sp),(hal_exc_info+4).l
	move.l	8(sp),(hal_exc_info+8).l
	move.l	12(sp),(hal_exc_info+12).l
	move.w	6(sp),d0
	andi.w	#$0FFF,d0
	lsr.w	#2,d0
	movea.l	sp,a0
	bra	cr_show

hal_pace	dc.l	RDPACE
hal_hz		dc.w	0
	IFD	HARNESS
hal_hwin	dc.l	$C00000
	ENDC
hal_pal50	dc.w	0

	section	bss,bss
	cnop	0,4
hal_vectors	ds.l	64
hal_exc_info	ds.l	4
hal_exc_regs	ds.l	16
hal_frames	ds.l	1
hal_tickvb	ds.l	1
hal_ahead	ds.b	1
	even
hal_pcring	ds.l	17
	even
hal_pcpos	ds.w	1
	cnop	0,4
hal_ipl0	ds.l	1
hal_intx	ds.l	1
hal_intxv	ds.w	2
hal_int6x	ds.l	1
hal_starve	ds.w	1
hal_cpu40	ds.b	1
	even
hal_cacr0	ds.l	1
hal_dtt0	ds.l	1
hal_padstate	ds.w	1
hal_sram	ds.b	$2000
ctx_game_sp	ds.l	1
ctx_rend_sp	ds.l	1
ctx_cur		ds.b	1
ctx_ready	ds.b	1
rd_busy		ds.b	1
hal_vbtick	ds.b	1
hal_vbreq	ds.b	1
hal_swpend	ds.b	1
		cnop	0,4
		ds.b	4096
rend_stack_top

	section	chip,bss_c
hal_copempty	ds.l	4+16

	section	game,code
