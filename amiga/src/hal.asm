;	Amiga hardware layer: entry point, the game's frame tick (its vertical blank) on a CIA
;	timer or the display's vertical blank, the save RAM and the exception trap.
;
;	The code hunk starts with a small header so tools can find the entry points:
;	  +0  bra.w  _start            AmigaDOS entry (takes over the machine)
;	  +4  'NH94'
;	  +8  dc.l   hal_game_main     entry with the machine already taken over (test harness)
;	  +12 dc.l   hal_debug         debug block (see below)

CUSTOM		equ	$DFF000
INTENA		equ	$09A
INTENAR		equ	$01C
INTREQ		equ	$09C
INTREQR		equ	$01E
DMACON		equ	$096
DMACONR		equ	$002
CIAB_ICR	equ	$BFDD00
CIAB_CRA	equ	$BFDE00
CIAB_TALO	equ	$BFD400
CIAB_TAHI	equ	$BFD500
CIAB_TODLO	equ	$BFD800			;(the TOD counts horizontal syncs: 64 us)
CIAB_TODMID	equ	$BFD900
CIAB_TODHI	equ	$BFDA00

CIA_CLOCK	equ	709379			;PAL E clock
CIA_CLOCK_NTSC	equ	715909
RDPACE		equ	1			;hal_pace at the start

	section	game,code
hal_header
	bra.w	_start
	IFD	HARNESS
	dc.b	'NH94'
	dc.l	hal_game_main
	dc.l	hal_debug
	ENDC

;	The timer period for hal_hz frames a second (a running timer takes it at its next
;	underflow). Keeps all but d0.
hal_set_rate
	move.l	d1,-(sp)
	; the game takes a 50 Hz rate for a PAL console's (hal_pal50, read at its start): its
	; sound driver then runs the music an extra step every 6th frame (PALflag), so songs
	; keep their tempo, and some of its speeds are scaled (PalMode); F8 changes them with
	; the rate
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
	moveq	#60,d1				;the display's own rate: the vertical blank gives the
	tst.b	(hal_pal).l			;ticks (rd_bq_int), in step with the frames shown
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

;	Game entry with interrupts off and the machine ours. Sets up the vectors and video memory, starts
;	the game frame timer and jumps to the cartridge's cold start.
hal_game_main
	move	#$2700,sr
	IFD	HARNESS
	movea.l	(hal_hwin).l,a0
	bsr	ram_relocate
	ENDC
	lea	(RAMBASE).l,a0			;clear the Genesis work RAM
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
	move.l	a1,$64(a0)			;level 1
	move.l	a1,$68(a0)			;level 2
	lea	rd_bq_int(pc),a2
	move.l	a2,$6C(a0)			;level 3: the blit queue's shows, the vertical blank count
	move.l	a1,$70(a0)			;level 4
	move.l	a1,$74(a0)			;level 5
	move.l	a1,$7C(a0)			;level 7
	move.l	a1,$60(a0)			;spurious
	lea	hal_int6(pc),a1
	move.l	a1,$78(a0)			;level 6: CIA-B, the Genesis vblank
	lea	ctx_to_render(pc),a1
	move.l	a1,$80(a0)			;trap #0
	lea	ctx_to_game(pc),a1
	move.l	a1,$84(a0)			;trap #1
	movec	a0,vbr
	rts

;	A 68040 or 68060, found by a control register only they have (DTT0: an illegal instruction
;	before them), not by exec's AttnFlags (started from a floppy, a 68060 has no 68060.library
;	to name it, and its caches are as the board left them): for the game its data cache and
;	store buffer off, and the first 16 MB (chip memory, the custom chips, the CIAs) not cached
;	and in order (DTT0: cache inhibited, precise), whatever the system had; so the copper, the
;	blitter and Paula always see the CPU's writes, in order, and the CPU theirs. The
;	instruction cache stays. Put back on quitting (hal_cpu_exit). Supervisor, interrupts off.
hal_cpu_setup
	movem.l	d0/a0-a2,-(sp)
	lea	(hal_vectors).l,a0
	move.l	4*4(a0),a2			;(the illegal instruction vector)
	lea	(.no,pc),a1
	move.l	a1,4*4(a0)
	movea.l	sp,a1
	dc.w	$4E7A,$0006			;movec dtt0,d0
	move.l	d0,(hal_dtt0).l
	movec	cacr,d0
	move.l	d0,(hal_cacr0).l
	dc.w	$F478				;cpusha dc: what the data cache holds to memory
	andi.l	#~$A0000000,d0			;data cache (bit 31), the 68060's store buffer (29) off
	movec	d0,cacr
	move.l	#$0000C040,d0			;$00xxxxxx, user and supervisor, cache inhibited, precise
	dc.w	$4E7B,$0006			;movec d0,dtt0
	st	(hal_cpu40).l
.no	movea.l	a1,sp				;(a 68020 or 68030: its exception frame dropped)
	move.l	a2,4*4(a0)
	movem.l	(sp)+,d0/a0-a2
	rts

;	The 68040's or 68060's cache settings as they were (hal_cpu_setup), with nothing left in
;	the data cache from before the game (cinva dc: memory has changed since; exec turns it on
;	again). Supervisor, interrupts off. Uses d0.
hal_cpu_exit
	tst.b	(hal_cpu40).l
	beq.s	.x
	dc.w	$F458				;cinva dc
	move.l	(hal_dtt0).l,d0
	dc.w	$4E7B,$0006			;movec d0,dtt0
	move.l	(hal_cacr0).l,d0
	movec	d0,cacr
.x	rts

;	CIA-B timer A, continuous, at the game's frame rate (hal_hz), on level 6. The rate is the
;	display's, as on the console of each region: 50 Hz with a PAL display (a PAL Mega Drive
;	runs the game at 50 Hz, a sixth slower), 60 Hz with NTSC; F8 switches it.
hal_start_timer
	move.b	#$7F,(CIAB_ICR).l		;all CIA-B interrupts off
	move.b	#0,(CIAB_CRA).l
	tst.w	(hal_hz).l
	bne.s	.hz
	move.w	#60,(hal_hz).l
	tst.b	(hal_pal).l
	beq.s	.hz
	move.w	#50,(hal_hz).l
.hz	bsr	hal_set_rate
	move.b	#$81,(CIAB_ICR).l		;timer A interrupt on
	move.b	#$11,(CIAB_CRA).l		;start, continuous, force load
	move.w	#$2000,(CUSTOM+INTREQ).l
	move.w	#$C000|$2000|$0020|$0010,(CUSTOM+INTENA).l	;master, EXTER (level 6), VERTB and
							;COPER (level 3: the blit queue's shows)
	rts

;	The code a game tick interrupts, from its exception frame at a0: its pc to hal_pcring (the
;	crash report), its sr and the context after them (hal_int6, or rd_bq_int when the vertical
;	blank gives the ticks). Uses d0-d1, a0.
hal_pcnote
	moveq	#0,d1
	move.w	(a0)+,d1			;sr
	swap	d1
	move.b	(ctx_cur).l,d1
	move.l	(a0),d0				;pc
	lea	(hal_pcring).l,a0
	move.l	d1,64(a0)			;last: sr, context
	move.w	(hal_pcpos).l,d1
	move.l	d0,(a0,d1.w)
	addq.w	#4,d1
	andi.w	#63,d1
	move.w	d1,(hal_pcpos).l
	rts

;	Level 6. The CIA-B timer is the Genesis vertical blank: count it and run the game's handler
;	through the VBint vector, as VBjsr does on the cartridge. The handler ends in rte, so it is
;	given a frame that returns here; then, if the renderer was running while the game waited
;	for this vblank (hal_idle), the game gets the CPU back at once.
hal_int6
	move.l	d0,-(sp)
	move.b	(CIAB_ICR).l,d0			;reading acknowledges
	move.w	#$2000,(CUSTOM+INTREQ).l
	tst.b	(hal_vbreq).l
	bne.s	.vb
	btst	#0,d0
	beq	.none
	tst.b	(hal_vbtick).l
	bne	.none				;(the vertical blank gives the ticks)
	movem.l	d1/a0,-(sp)
	lea	12(sp),a0
	bsr	hal_pcnote			;(the vertical blank notes its own ticks)
	movem.l	(sp)+,d1/a0
	bra.s	.tick
.vb	sf	(hal_vbreq).l
.tick	move.l	(sp)+,d0
	tst.b	(hal_ahead).l
	beq.s	.nah
	sf	(hal_ahead).l			;its tick was run early (hal_tick_early): the sound only
	jsr	(snd_play).l
	rte
.nah	; the renderer has the CPU while the game has its interrupts off (its sr saved under its
	; registers, ctx_to_render): no tick now, as the Genesis holds its interrupt then (the
	; game's vblank code may not be there: Opening2 clears it with the RAM before a screen
	; sets it again, and the screen lets the renderer finish a frame meanwhile, fe_ring)
	tst.b	(ctx_cur).l
	beq.s	.gm
	movem.l	d0/a0,-(sp)
	movea.l	(ctx_game_sp).l,a0
	move.w	15*4(a0),d0
	andi.w	#$0600,d0
	cmpi.w	#$0600,d0
	movem.l	(sp)+,d0/a0			;(the flags stay)
	bne.s	.gm
	rte
.gm
	addq.l	#1,(hal_frames).l
	move.l	(rd_vblanks).l,(hal_tickvb).l	;(its vertical blank: the sound's delay, rd_showdue)
	jsr	(snd_frame).l
	tst.l	(VBint).l			;(never a vblank code at 0)
	beq.s	.post
	move.w	#$0078,-(sp)			;format 0 frame for the game handler's rte
	pea	(.post).l
	move	sr,-(sp)
	move.l	(VBint).l,-(sp)
	rts					;into the game's vblank code
.post
	btst	#2,(sp)				;the interrupted code's interrupt mask
	bne.s	.nest
	btst	#1,(sp)
	bne.s	.nest
	btst	#0,(sp)
	bne.s	.nest
	tst.b	(ctx_cur).l
	bne	ctx_to_game			;renderer interrupted: back to the waiting game
	; the game has not waited for a vblank for a while (a wait loop the converter did not
	; mark): give the renderer this frame's time anyway
	addq.w	#1,(hal_starve).l
	cmpi.w	#3,(hal_starve).l
	blo.s	.rte
	tst.b	(ctx_ready).l
	beq.s	.rte
	clr.w	(hal_starve).l
	bra	ctx_to_render
.rte	rte
.nest	; an interrupt handler was interrupted: switching now would leave it half run until its
	; context runs again (a blit queue handler, then started twice). The level 3 handler
	; switches when it ends (hal_swpend).
	tst.b	(ctx_cur).l
	beq.s	.rte
	st	(hal_swpend).l
	rte
.none	andi.b	#3,d0				;(not a tick, nor CIA-B's timers: another source of
	bne.s	.nc				;level 6, which the crash report counts)
	addq.l	#1,(hal_int6x).l
.nc	move.l	(sp)+,d0
	rte

;	------------------------------------------------------------------------------------------
;	Two contexts share the CPU: the game, and the renderer, which only runs while the game
;	waits for a vblank. The converter puts a jsr hal_idle at the top of the game's wait loops.
;	Each context is its registers on its own stack under an exception frame, so switching is
;	movem, swap stacks, movem, rte.

hal_idle
	move.l	d0,-(sp)
	move	sr,d0
	andi.w	#$0700,d0
	cmpi.w	#$0600,d0
	bhs	.no				;called from interrupt code: never switch there
	addq.l	#1,(hal_ipl0).l			;(the game's code runs: cr_watch)
	tst.b	(rd_busy).l
	bne.s	.go				;a frame half drawn: on with it
	move.l	(hal_frames).l,d0
	sub.l	(rd_lastframe).l,d0
	cmp.l	(hal_pace).l,d0
	blo	.early				;too soon for the next frame
.go	tst.b	(ctx_ready).l
	beq	.no
	move.l	(sp)+,d0
	clr.w	(hal_starve).l
	trap	#0
	rts
.early	bsr	hal_tick_early			;(the renderer has drawn the last state)
.no
hal_idle_no					;(the harness: the game waits, nothing to draw)
	clr.w	(hal_starve).l
	move.l	(sp)+,d0
	rts

;	The game waits for the renderer to finish a frame half drawn (fe_ring), not for a game
;	tick: the renderer gets the CPU as in hal_idle. Keeps all.
hal_yield
	tst.b	(ctx_ready).l
	beq.s	.x
	clr.w	(hal_starve).l
	trap	#0
.x	rts

;	The game waits for a tick and the renderer has drawn its last state: the next vertical
;	blank's tick is run now, if this one's has run and none is ahead (hal_ahead: that vertical
;	blank then runs none, only the sound's side, snd_play). The game's work for the next frame
;	goes into time the CPU would spend idle, and its picture is ready a little sooner, so a
;	frame that takes long does not make the next one late. At the full frame rate only
;	(hal_pace 1), the ticks given by the vertical blank. Keeps all.
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
	tst.l	(VBint).l			;(no vblank code at 0)
	beq	.x
	move.l	d0,-(sp)
	move.l	(hal_tickvb).l,d0
	cmp.l	(rd_vblanks).l,d0
	move.l	(sp)+,d0
	bne	.x				;(this vertical blank's tick not run yet)
	st	(hal_ahead).l
	addq.l	#1,(hal_frames).l
	move.l	(rd_vblanks).l,(hal_tickvb).l	;(its vertical blank: the next)
	addq.l	#1,(hal_tickvb).l
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(snd_dly_push).l		;(its sound commands: played from the next vertical
	movem.l	(sp)+,d0-d7/a0-a6		;blank on, as ever)
	move.w	#$0078,-(sp)			;format 0 frame for the game handler's rte
	pea	(.r).l
	move.w	4+2(sp),-(sp)			;(the sr from before)
	andi	#$FEFF,sr			;level 6 (as the interrupt)
	move.l	(VBint).l,-(sp)
	rts
.r
.x	move	(sp)+,sr
	rts
	IFD	HARNESS
hal_early	dc.b	1			;(hal_tick_early on)
	even
	ENDC


;	trap #0: game -> renderer
ctx_to_render
	ori.w	#$0700,sr			;no vblank half way through the switch
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	sp,(ctx_game_sp).l
	st	(ctx_cur).l
	movea.l	(ctx_rend_sp).l,sp
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;	trap #1, or a vblank while drawing: renderer -> game
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
	addq.l	#1,(hal_ipl0).l			;(the renderer runs: cr_watch)
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
	move.w	#$0080,-(a0)			;format 0, vector trap #0
	move.l	#rend_main,-(a0)
	move.w	#$2000,-(a0)			;supervisor, interrupts on
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
	move.l	#$009C0006,(a0)			;INTREQ: SOFT, DSKBLK off (the blit queue, rd_bq_go)
	move.l	#$01000200,4(a0)		;BPLCON0: no planes, colour
	move.l	#$01800000,8(a0)		;black
	lea	12(a0),a1
	move.l	#rd_sprnull,d1			;the sprites: none
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
	move.l	#$008A0000,(a1)			;COPJMP2: the blit queue
	move.l	a0,(CUSTOM+$080).l		;COP1LC
	move.w	d0,(CUSTOM+$088).l		;COPJMP1
	move.w	#$83E0,(CUSTOM+DMACON).l	;DMA, bitplanes, copper, blitter, sprites (the HUD)
	rts

;	An interrupt the game does not use (none is on at INTENA: a spurious one, level 7): counted
;	for the crash report, its vector and INTREQR kept. INTREQ is left alone: SOFT and DSKBLK are
;	the blit queue's copper state (rd_bq_go), VERTB, COPER and EXTER calls still to come.
hal_int_ignore
	addq.l	#1,(hal_intx).l
	move.w	6(sp),(hal_intxv).l		;format, vector
	move.w	(CUSTOM+$01E).l,(hal_intxv+2).l	;INTREQR
	rte

;	Any other exception: keep the frame and registers for the debugger, then hang.
hal_exception
	move	#$2700,sr
	movem.l	d0-d7/a0-a7,(hal_exc_regs).l
	move.l	(sp),(hal_exc_info).l		;sr, pc high
	move.l	4(sp),(hal_exc_info+4).l	;pc low, format/vector
	move.l	8(sp),(hal_exc_info+8).l
	move.l	12(sp),(hal_exc_info+12).l
	move.w	6(sp),d0
	andi.w	#$0FFF,d0
	lsr.w	#2,d0				;the vector
	movea.l	sp,a0
	bra	cr_show				;(crash.asm: the report)

hal_pace	dc.l	RDPACE			;1: a new frame each game tick if there is time for it
						;(50 or 60 a second), or 2: every 2 game ticks at most,
						;each shown for 2 vertical blanks at least (a steady 25
						;or 30 a second); F6
hal_hz		dc.w	0			;game frames a second (0: from the display)
	IFD	HARNESS
hal_hwin	dc.l	$C00000
	ENDC
hal_pal50	dc.w	0			;bit 0: the game runs at 50 Hz (a PAL console's rate: the
						;game reads it at its start, hal_set_rate)

	section	bss,bss
	cnop	0,4
hal_vectors	ds.l	64
hal_exc_info	ds.l	4
hal_exc_regs	ds.l	16
hal_frames	ds.l	1
hal_tickvb	ds.l	1			;rd_vblanks at the last game tick
hal_ahead	ds.b	1			;the next vertical blank's tick has run (hal_tick_early)
	even
hal_pcring	ds.l	17
	even
hal_pcpos	ds.w	1
	cnop	0,4
hal_ipl0	ds.l	1			;the game's waits (hal_idle) and the renderer's loops: the
						;code outside interrupts runs (cr_watch)
hal_intx	ds.l	1			;interrupts not used (hal_int_ignore),
hal_intxv	ds.w	2			;the last's vector word and INTREQR
hal_int6x	ds.l	1			;level 6 calls from neither CIA-B's timers nor the
						;vertical blank's tick
hal_starve	ds.w	1
hal_cpu40	ds.b	1			;a 68040 or 68060 (hal_cpu_setup): its settings before,
	even
hal_cacr0	ds.l	1			;CACR,
hal_dtt0	ds.l	1			;DTT0
hal_padstate	ds.w	1			;pad 2 : pad 1, active high
hal_sram	ds.b	$2000			;the save RAM (the cartridge's battery RAM)
ctx_game_sp	ds.l	1
ctx_rend_sp	ds.l	1
ctx_cur		ds.b	1			;0 game, -1 renderer running
ctx_ready	ds.b	1
rd_busy		ds.b	1			;the renderer is drawing a frame
hal_vbtick	ds.b	1			;the game ticks come from the vertical blank
hal_vbreq	ds.b	1			;(one asked for)
hal_swpend	ds.b	1			;a context switch waits for an interrupt handler's end
		cnop	0,4
		ds.b	4096			;the renderer's stack (the most it held in long runs of
rend_stack_top					;the harness: some 360 bytes; a game tick switches to the
						;game's stack)

	section	chip,bss_c
hal_copempty	ds.l	4+16

	section	game,code
