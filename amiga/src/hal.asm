;	Amiga hardware layer: entry point, the Genesis vertical blank on a CIA timer, the stand-ins
;	for the Genesis ports (pads, Z80 bus, sound RAM, save RAM) and the exception trap.
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
CIAB_CRB	equ	$BFDF00
CIAB_TBLO	equ	$BFD600
CIAB_TBHI	equ	$BFD700
CIAB_TODLO	equ	$BFD800			;(the TOD counts horizontal syncs: 64 us)
CIAB_TODMID	equ	$BFD900
CIAB_TODHI	equ	$BFDA00

	IFD	PROFILE
;	(statistics) The time since the last mark (CIA-B TOD lines) into prof_mark's bucket n: 0
;	the game, 1 the renderer, 2 the game's vblank code and the sound. Keeps everything.
PACCT	macro
	move.l	d1,-(sp)
	moveq	#\1,d1
	jsr	(prof_acct).l
	move.l	(sp)+,d1
	endm
	ENDC
;	(statistics, PROFILE builds) An event of the frame pipeline into prof_ev, with the time.
;	Keeps everything but the flags.
PEV	macro
	IFD	PROFILE
	move.w	#\1,-(sp)
	jsr	(prof_event).l
	addq.l	#2,sp
	ENDC
	endm
PEVMAX		equ	65536
PROFMAX		equ	65536

CIA_CLOCK	equ	709379			;PAL E clock
CIA_CLOCK_NTSC	equ	715909
	IFND	RDPACE
RDPACE		equ	1			;hal_pace at the start
	ENDC
	IFND	BENCHTP
BENCHTP		equ	60			;(BENCH: ticks put off at most, hal_int6)
	ENDC

	section	game,code
hal_header
	bra.w	_start
	dc.b	'NH94'
	dc.l	hal_game_main
	dc.l	hal_debug

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

;	Debug block, read by the test harness:
;	+0  the layout a frame is drawn with (rd_layout)  +4 vm_data  +8 colours (ds_pal)  +12 vertical scroll
;	(rd_vs)  +16 exception info (16 longs)
;	+20 frame counter  +24 pad state ... +76 the renderer's self-check (VERIFY builds)
;	+80 chip buffers (the harness' blitter statistics by kind)
hal_debug
	dc.l	rd_layout,vm_data,ds_pal,rd_vs,hal_exc_info,hal_frames,hal_padstate
	dc.l	rd_count,0
	dc.l	bmB,rd_cw,rd_colours
	dc.l	tp_pl,tp_mk,tp_cls
	dc.l	rd_ovl,rd_ovlmlo,rd_ovlrows
	dc.l	rd_dbg_key,rd_vfail
	dc.l	rd_screens,mkB6,rd_scarena,rd_fpsimg,rd_ovlmhi,rd_cop,rd_hudsd
	dc.l	RAMBASE				;+108: the Genesis RAM window
	dc.l	game_code			;+112: the converted game's code
	dc.l	rd_lastframe,rd_busy		;+116: the renderer's pacing
	dc.l	hal_starve			;+124
	dc.l	ctx_cur				;+128
	dc.l	rd_spin_vs,rd_spin_q,rd_spin_w,rd_spin_full ;+132: the renderer's wait loops
	dc.l	ctx_to_game,hal_idle_no		;+148: the renderer gives way, the game idles
	dc.l	Spritetiles,SPRTSIZE		;+156: the players' sprite tiles (planar, not in VRAM)
	dc.l	vm_tsrc			;+164: each VRAM tile's DMA source
	dc.l	game_code_end			;+168: the converted game's code ends
	dc.b	'SCX1'				;+172: the sprite image ring's second part: its
	dc.l	rd_scx				;address, then bytes (the harness may give one)
	dc.b	'ERL1'				;+180: hal_tick_early's switch (the harness turns
	dc.l	hal_early			;it off unless asked: NHL_EARLY=1)

;	Game entry with interrupts off and the machine ours. Sets up the vectors and the VDP, starts
;	the game frame timer and jumps to the cartridge's cold start.
hal_game_main
	move	#$2700,sr
	tst.b	(hal_amiga).l
	bne	.win				;started from AmigaDOS: the window is in place
	lea	($C00000).l,a0			;the test harness: a fixed one
	bsr	ram_relocate
.win	lea	(RAMBASE).l,a0			;clear the Genesis work RAM
	move.w	#$10000/4-1,d0
.clr	clr.l	(a0)+
	dbf	d0,.clr
	lea	(RAMBASE+$FFF0).l,sp
	bsr	vm_init
	jsr	(snd_init).l
	bsr	hal_set_vectors
	jsr	(rd_init).l
	bsr	hal_display_init
	bsr	ctx_init
	IFD	SHOWFPS
	st	(hal_fpsshow).l
	ENDIF
	tst.b	(hal_amiga).l
	beq	.nokbd
	bsr	hal_kbd_init
.nokbd	bsr	hal_start_timer
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
	IFD	PROFILE
	move.b	#0,(CIAB_CRB).l
	move.b	#355&$FF,(CIAB_TBLO).l		;~2 kHz
	move.b	#355>>8,(CIAB_TBHI).l
	move.b	#$82,(CIAB_ICR).l
	move.b	#$11,(CIAB_CRB).l
	ENDIF
	move.w	#$2000,(CUSTOM+INTREQ).l
	move.w	#$C000|$2000|$0020|$0010,(CUSTOM+INTENA).l	;master, EXTER (level 6), VERTB and
							;COPER (level 3: the blit queue's shows)
	rts

;	Level 6. The CIA-B timer is the Genesis vertical blank: count it and run the game's handler
;	through the VBint vector, as VBjsr does on the cartridge. The handler ends in rte, so it is
;	given a frame that returns here; then, if the renderer was running while the game waited
;	for this vblank (hal_idle), the game gets the CPU back at once.
hal_int6
	movem.l	d0/a0,-(sp)			;sample the interrupted pc (watchdog)
	lea	(hal_pcring).l,a0
	move.w	(hal_pcpos).l,d0
	move.l	10(sp),(a0,d0.w)		;pc
	move.w	8(sp),d0			;sr
	swap	d0
	move.b	(ctx_cur).l,d0
	move.w	(hal_pcpos).l,-(sp)
	move.l	d0,64(a0)			;last: sr, context
	move.w	(sp)+,d0
	addq.w	#4,d0
	andi.w	#63,d0
	move.w	d0,(hal_pcpos).l
	movem.l	(sp)+,d0/a0
	move.l	d0,-(sp)
	move.b	(CIAB_ICR).l,d0			;reading acknowledges
	move.w	#$2000,(CUSTOM+INTREQ).l
	IFD	PROFILE
	btst	#1,d0				;timer B: sample the interrupted pc
	beq.s	.np
	movem.l	d1-d2/a0,-(sp)
	move.l	18(sp),d2
	cmpi.l	#rd_waitblit,d2			;waiting for the blitter: the caller instead
	blo.s	.pc				;(bit 31 set)
	cmpi.l	#rd_waitblit_end,d2
	bhs.s	.pc
	move.l	24(sp),d2
	bset	#31,d2
.pc	btst	#6,(CUSTOM+DMACONR).l		;(the blitter busy: bit 30)
	beq.s	.pb
	bset	#30,d2
.pb	move.l	(prof_pos).l,d1
	lea	(prof_buf).l,a0
	move.l	d2,(a0,d1.l*4)
	addq.l	#1,d1
	andi.l	#PROFMAX-1,d1
	move.l	d1,(prof_pos).l
	addq.l	#1,(prof_count).l
	movem.l	(sp)+,d1-d2/a0
.np
	ENDIF
	tst.b	(hal_vbreq).l
	bne.s	.vb
	btst	#0,d0
	beq	.none
	tst.b	(hal_vbtick).l
	bne	.none				;(the vertical blank gives the ticks)
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
	IFD	BENCH
	bra	.tp				;(a benchmark build: at the game's next wait)
	ELSE
	rte
	ENDC
.gm
	IFD	BENCH
	; benchmark builds: a tick that comes while the game runs (not waiting since the last
	; one: a frame that took the renderer more than a vertical blank too) waits for the game's
	; next wait (hal_idle), so the game's course does not depend on the renderer's timing (the
	; game never sees two ticks pass at once); BENCHTP ticks on, it runs anyway (a wait loop
	; without hal_idle)
	tst.b	(hal_yielding).l		;(the renderer on for the game, which does not wait
	bne.s	.tp				;for a tick: hal_yield)
	tst.b	(hal_idled).l
	bne.s	.tw
.tp	addq.b	#1,(hal_tickpend).l
	cmpi.b	#BENCHTP,(hal_tickpend).l
	bhs.s	.tf
	IFD	PROFILE
	IFND	MEMBENCH
	addq.l	#1,(prof_mark+92).l		;(statistics: ticks put off)
	ENDC
	ENDC
	rte
.tf
	IFD	PROFILE
	IFND	MEMBENCH
	addq.l	#1,(prof_mark+96).l		;(statistics: ticks run all the same)
	ENDC
	ENDC
.tw	sf	(hal_idled).l
	sf	(hal_tickpend).l
	jsr	(bench_wait).l
	ENDC
	addq.l	#1,(hal_frames).l
	IFD	PROFILE
	tst.b	(ctx_cur).l			;(statistics: the context interrupted until now)
	bne.s	.pr
	PACCT	0
	bra.s	.pg
.pr	PACCT	1
.pg
	ENDC
	IFD	WATCHDOG			;(debug builds: the game's screen can rightly stay
	addq.w	#1,(hal_wd).l			; the same for a long time)
	cmpi.w	#240,(hal_wd).l
	bne	.nowd
	jsr	(hal_watchdog).l
.nowd
	ENDIF
	PEV	'T'				;(statistics: a game tick)
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
	IFD	PROFILE
	PACCT	2				;(statistics: the vblank code)
	ENDC
	btst	#2,(sp)				;the interrupted code's interrupt mask
	bne.s	.nest
	btst	#1,(sp)
	bne.s	.nest
	btst	#0,(sp)
	bne.s	.nest
	tst.b	(ctx_cur).l
	bne	ctx_to_game			;renderer interrupted: back to the waiting game
	; the game has not waited for a vblank for a while (a wait loop the converter did not
	; mark): give the renderer this frame's time anyway (not in BENCH builds: the game's time
	; would depend on the renderer's)
	IFD	BENCH
	rte
	ENDC
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
.none	move.l	(sp)+,d0
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
	IFD	BENCH
	st	(hal_idled).l			;(the game waits)
	tst.b	(hal_tickpend).l
	beq.s	.nt
	bsr	hal_tick_late
.nt
	ENDC
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
	PEV	'R'				;(statistics: the renderer gets the CPU)
	trap	#0
	rts
.early	bsr	hal_tick_early			;(the renderer has drawn the last state)
.no
hal_idle_no					;(the harness: the game waits, nothing to draw)
	clr.w	(hal_starve).l
	move.l	(sp)+,d0
	rts

;	The game waits for the renderer to finish a frame half drawn (fe_ring), not for a game
;	tick: the renderer gets the CPU as in hal_idle, but a BENCH build's tick count is left
;	alone (a tick that comes meanwhile waits for the game's next wait), so the game's course
;	does not depend on whether a frame was half drawn. Keeps all.
hal_yield
	tst.b	(ctx_ready).l
	beq.s	.x
	clr.w	(hal_starve).l
	PEV	'R'
	IFD	BENCH
	st	(hal_yielding).l
	ENDC
	trap	#0
	IFD	BENCH
	sf	(hal_yielding).l
	ENDC
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
	tst.b	(hal_early).l
	beq	.x
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
	IFD	BENCH
	sf	(hal_idled).l
	jsr	(bench_wait).l
	ENDC
	addq.l	#1,(hal_frames).l
	PEV	'T'
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
hal_early	dc.b	1			;(hal_tick_early on)
	even

	IFD	BENCH
;	A game tick put off while the game ran (hal_int6), now that it waits: as the interrupt
;	would have run it, at level 6. Keeps all.
hal_tick_late
	move	sr,-(sp)
	ori	#$0700,sr
	sf	(hal_tickpend).l
	sf	(hal_idled).l
	jsr	(bench_wait).l
	addq.l	#1,(hal_frames).l
	PEV	'T'
	move.l	(rd_vblanks).l,(hal_tickvb).l
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(snd_frame).l
	movem.l	(sp)+,d0-d7/a0-a6
	tst.l	(VBint).l			;(never a vblank code at 0)
	beq.s	.r
	move.w	#$0078,-(sp)			;format 0 frame for the game handler's rte
	pea	(.r).l
	move.w	4+2(sp),-(sp)			;(the sr from before)
	andi	#$FEFF,sr			;level 6 (as the interrupt)
	move.l	(VBint).l,-(sp)
	rts
.r	move	(sp)+,sr
	rts
	ENDC

;	trap #0: game -> renderer
ctx_to_render
	ori.w	#$0700,sr			;no vblank half way through the switch
	IFD	PROFILE
	PACCT	0
	ENDC
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	sp,(ctx_game_sp).l
	st	(ctx_cur).l
	movea.l	(ctx_rend_sp).l,sp
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;	trap #1, or a vblank while drawing: renderer -> game
ctx_to_game
	ori.w	#$0700,sr
	IFD	PROFILE
	PACCT	1
	ENDC
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	sp,(ctx_rend_sp).l
	sf	(ctx_cur).l
	movea.l	(ctx_game_sp).l,sp
	movem.l	(sp)+,d0-d7/a0-a6
	rte

	IFD	PROFILE
;	(statistics) The time since the last mark into bucket d1 of prof_mark+116. Keeps all.
prof_acct
	movem.l	d0/d2/a0,-(sp)
	moveq	#0,d0
	move.b	(CIAB_TODHI).l,d0		;(reading it latches the others)
	lsl.w	#8,d0
	move.b	(CIAB_TODMID).l,d0
	lsl.l	#8,d0
	move.b	(CIAB_TODLO).l,d0
	move.l	d0,d2
	sub.l	(prof_last).l,d0
	andi.l	#$FFFFFF,d0
	move.l	d2,(prof_last).l
	lea	(prof_mark+116).l,a0
	add.l	d0,(a0,d1.w*4)
	movem.l	(sp)+,d0/d2/a0
	rts
	ENDC

	IFD	PROFILE
;	(statistics) An event (the code: the word pushed before the call) into the ring prof_ev:
;	the code in the top byte, the time (CIA-B TOD, lines) below. Keeps everything.
prof_event
	move	sr,-(sp)
	ori	#$0700,sr
	movem.l	d0-d1/a0,-(sp)
	moveq	#0,d0
	move.b	(CIAB_TODHI).l,d0		;(reading it latches the others)
	lsl.w	#8,d0
	move.b	(CIAB_TODMID).l,d0
	lsl.l	#8,d0
	move.b	(CIAB_TODLO).l,d0
	moveq	#0,d1
	move.b	12+2+4+1(sp),d1			;the code
	ror.l	#8,d1
	or.l	d1,d0
	move.l	(prof_evpos).l,d1
	lea	(prof_ev).l,a0
	move.l	d0,(a0,d1.l*4)
	addq.l	#1,d1
	andi.l	#PEVMAX-1,d1
	move.l	d1,(prof_evpos).l
	addq.l	#1,(prof_evcount).l
	IFD	PROFMARK
	move.b	12+2+4+1(sp),d0			;(a frame's start and end among the PC samples:
	cmpi.b	#'S',d0				;$3F0000 and the code)
	beq.s	.pm
	cmpi.b	#'D',d0
	bne.s	.npm
.pm	andi.l	#$FF,d0
	ori.l	#$3F000000,d0
	move.l	(prof_pos).l,d1
	lea	(prof_buf).l,a0
	move.l	d0,(a0,d1.l*4)
	addq.l	#1,d1
	andi.l	#PROFMAX-1,d1
	move.l	d1,(prof_pos).l
	addq.l	#1,(prof_count).l
.npm
	ENDC
	movem.l	(sp)+,d0-d1/a0
	move	(sp)+,sr
	rts
	ENDC

;	The renderer's loop: draw each new frame, then give the CPU back.
rend_main
	move.l	(hal_frames).l,d0
	sub.l	(rd_lastframe).l,d0
	cmp.l	(hal_pace).l,d0
	blo	.yield
	move.l	(hal_frames).l,(rd_lastframe).l
	st	(rd_busy).l
	PEV	'S'				;(statistics: a frame begun, ended)
	jsr	(rd_frame).l
	PEV	'E'
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

;	No frame drawn for 4 seconds (-DWATCHDOG=1 builds): a black and white debug screen with the
;	code base, the last 16 interrupted pcs and the last sr / context, in hex.
	IFD	WATCHDOG
hal_watchdog
	movem.l	d0-d2/a0-a2,-(sp)
	lea	(hal_dbgscr).l,a0
	move.w	#40*200/4-1,d0
.c	clr.l	(a0)+
	dbf	d0,.c
	lea	(hal_dbgscr+40*8+2).l,a0
	lea	hal_header(pc),a1
	move.l	a1,d0
	bsr	hal_hex8
	lea	(hal_dbgscr+40*20+2).l,a0
	lea	(hal_pcring).l,a2
	moveq	#16,d2
.l	move.l	(a2)+,d0
	bsr	hal_hex8
	lea	40*9(a0),a0
	dbf	d2,.l
	; copper: 1 plane, white on black
	lea	(hal_dbgcop).l,a0
	move.l	#$008E2C81,(a0)+
	move.l	#$00902CC1,(a0)+
	move.l	#$00920038,(a0)+
	move.l	#$009400D0,(a0)+
	move.l	#$01001200,(a0)+
	move.l	#$01020000,(a0)+
	move.l	#$01080000,(a0)+
	move.l	#$01FC0000,(a0)+
	move.l	#$01060C00,(a0)+
	move.l	#$01800000,(a0)+
	move.l	#$01820FFF,(a0)+
	move.l	#hal_dbgscr,d0
	move.w	#$00E0,(a0)+
	swap	d0
	move.w	d0,(a0)+
	move.w	#$00E2,(a0)+
	swap	d0
	move.w	d0,(a0)+
	move.l	#$FFFFFFFE,(a0)+
	move.l	#hal_dbgcop,(CUSTOM+$080).l
	movem.l	(sp)+,d0-d2/a0-a2
	rts

;	d0 as 8 hex digits at byte a0 of the debug screen (40 bytes a row). Keeps a0.
hal_hex8
	movem.l	d0-d4/a0-a3,-(sp)
	moveq	#7,d4
.d	rol.l	#4,d0
	moveq	#15,d1
	and.w	d0,d1
	lea	(rd_font).l,a1
	mulu.w	#5,d1
	adda.w	d1,a1
	movea.l	a0,a2
	moveq	#4,d2
.r	move.b	(a1)+,(a2)
	lea	40(a2),a2
	dbf	d2,.r
	addq.l	#1,a0
	dbf	d4,.d
	movem.l	(sp)+,d0-d4/a0-a3
	rts
	ENDIF

hal_int_ignore
	move.w	#$3FFF,(CUSTOM+INTREQ).l
	rte

;	Any other exception: keep the frame and registers for the debugger, then hang.
hal_exception
	move	#$2700,sr
	movem.l	d0-d7/a0-a7,(hal_exc_regs).l
	move.l	(sp),(hal_exc_info).l		;sr, pc high
	move.l	4(sp),(hal_exc_info+4).l	;pc low, format/vector
	move.l	8(sp),(hal_exc_info+8).l
	move.l	12(sp),(hal_exc_info+12).l
	move.w	#$F00,(CUSTOM+$180).l
.hang	bra	.hang

hal_pace	dc.l	RDPACE			;1: a new frame each game tick if there is time for it
						;(50 or 60 a second), or 2: every 2 game ticks at most,
						;each shown for 2 vertical blanks at least (a steady 25
						;or 30 a second); F6
hal_hz		dc.w	0			;game frames a second (0: from the display)
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
hal_idled	ds.b	1			;(BENCH: the game waited since the last tick)
hal_yielding	ds.b	1			;(BENCH: the game in hal_yield)
hal_tickpend	ds.b	1			;(BENCH: ticks put off)
	even
hal_pcpos	ds.w	1
hal_wd		ds.w	1
hal_starve	ds.w	1
	IFD	PROFILE
prof_pos	ds.l	1
prof_count	ds.l	1
prof_mark	ds.l	5+8+16+4		;(+20: frames shown 1 ... 8+ vertical blanks; +52: vertical
					;blanks from a frame's game state to its showing, 0 ... 6+;
					;+116: time in the game, the renderer, the game's vblank code)
prof_last	ds.l	1
prof_buf	ds.l	PROFMAX
prof_intreq	ds.l	1
	IFD	BENCH
bench_tlog	ds.l	8192			;(the game RAM's sum at each tick: bench_wait)
	IFD	BENCHDUMP
bench_ram	ds.b	$10000			;(the game RAM at tick BENCHDUMP)
	ENDC
	ENDC
prof_evpos	ds.l	1
prof_evcount	ds.l	1
prof_ev		ds.l	PEVMAX			;events: code (top byte), CIA-B TOD
	ENDIF
hal_padstate	ds.w	1			;pad 2 : pad 1, active high
hal_hv		ds.w	1			;(BENCH builds: the game's HVcount)
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
rend_stack	ds.b	4096			;(the most it held in long runs of the harness: some
rend_stack_top					;360 bytes; a game tick switches to the game's stack)

	section	chip,bss_c
	IFD	MEMBENCH
mb_chip		ds.b	2048
mb_blt		ds.b	128*64
	ENDC
hal_copempty	ds.l	4+16
	IFD	WATCHDOG
hal_dbgcop	ds.l	20
hal_dbgscr	ds.b	40*200
	ENDIF

	section	game,code
