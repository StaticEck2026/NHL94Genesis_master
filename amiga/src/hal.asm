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
PROFMAX		equ	65536

GENESIS_HZ	equ	60
CIA_CLOCK	equ	709379			;PAL E clock
CIA_CLOCK_NTSC	equ	715909

	section	game,code
hal_header
	bra.w	_start
	dc.b	'NH94'
	dc.l	hal_game_main
	dc.l	hal_debug

;	Debug block, read by the test harness:
;	+0  vdp_regs  +4 vdp_vram  +8 vdp_cram  +12 vdp_vsram  +16 exception info (16 longs)
;	+20 frame counter  +24 pad state ... +76 the renderer's self-check (VERIFY builds)
hal_debug
	dc.l	vdp_regs,vdp_vram,vdp_cram,vdp_vsram,hal_exc_info,hal_frames,hal_padstate
	dc.l	rd_count,chunky
	dc.l	bmB,rd_cw,rd_colours
	dc.l	tp_pl,tp_mk,tp_cls
	dc.l	rd_ovl,rd_ovlmlo,rd_ovlrows
	dc.l	rd_dbg_key,rd_vfail

;	Game entry with interrupts off and the machine ours. Sets up the vectors and the VDP, starts
;	the 60 Hz timer and jumps to the cartridge's cold start.
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
	bsr	hal_vdp_init
	move.b	#$7D,(hal_z80ram+$96).l		;the sound driver's "Z80 idle" handshake
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
	move.l	a2,$6C(a0)			;level 3: the blit queue
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

;	CIA-B timer A, continuous, at the Genesis frame rate, on level 6.
hal_start_timer
	move.b	#$7F,(CIAB_ICR).l		;all CIA-B interrupts off
	move.b	#0,(CIAB_CRA).l
	move.w	#CIA_CLOCK/GENESIS_HZ,d0
	tst.b	(hal_pal).l
	bne	.pal
	move.w	#CIA_CLOCK_NTSC/GENESIS_HZ,d0
.pal	move.b	d0,(CIAB_TALO).l
	lsr.w	#8,d0
	move.b	d0,(CIAB_TAHI).l
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
	move.w	#$C000|$2000|$0040,(CUSTOM+INTENA).l	;master, EXTER (level 6), BLIT (level 3)
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
	movem.l	d1/a0,-(sp)
	move.l	(prof_pos).l,d1
	lea	(prof_buf).l,a0
	move.l	14(sp),(a0,d1.l*4)
	addq.l	#1,d1
	andi.l	#PROFMAX-1,d1
	move.l	d1,(prof_pos).l
	addq.l	#1,(prof_count).l
	movem.l	(sp)+,d1/a0
.np
	ENDIF
	btst	#0,d0
	beq	.none
	move.l	(sp)+,d0
	addq.l	#1,(hal_frames).l
	IFD	WATCHDOG			;(debug builds: the game's screen can rightly stay
	addq.w	#1,(hal_wd).l			; the same for a long time)
	cmpi.w	#240,(hal_wd).l
	bne	.nowd
	jsr	(hal_watchdog).l
.nowd
	ENDIF
	jsr	(snd_z80_poll).l
	move.w	#$0078,-(sp)			;format 0 frame for the game handler's rte
	pea	(.post).l
	move	sr,-(sp)
	move.l	(VBint).l,-(sp)
	rts					;into the game's vblank code
.post	tst.b	(ctx_cur).l
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
	move.l	(hal_frames).l,d0
	cmp.l	(rd_lastframe).l,d0
	beq	.no				;frame already drawn
	tst.b	(ctx_ready).l
	beq	.no
	move.l	(sp)+,d0
	clr.w	(hal_starve).l
	trap	#0
	rts
.no	clr.w	(hal_starve).l
	move.l	(sp)+,d0
	rts

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
	move.l	(hal_frames).l,d0
	cmp.l	(rd_lastframe).l,d0
	beq	.yield
	move.l	d0,(rd_lastframe).l
	jsr	(rd_frame).l
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
	move.l	#$01000200,(a0)			;BPLCON0: no planes, colour
	move.l	#$01800000,4(a0)		;black
	move.l	#$FFFFFFFE,8(a0)
	move.l	a0,(CUSTOM+$080).l		;COP1LC
	move.w	d0,(CUSTOM+$088).l		;COPJMP1
	move.w	#$0020,(CUSTOM+DMACON).l	;no sprites
	move.w	#$83C0,(CUSTOM+DMACON).l	;DMA, bitplanes, copper, blitter
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

;	find3d (display94.asm) keeps the sprites of objects within these of the camera: the
;	Genesis' +-$90, wider in the wide view (rd_frame sets them).
hal_cullx	dc.w	$0090
hal_cullxn	dc.w	$FF70
rd_wide		dc.b	-1			;the wide view (F6)
hal_play	dc.b	0			;set by find3d: the game is drawing the rink
		even

	section	bss,bss
	cnop	0,4
hal_vectors	ds.l	64
hal_exc_info	ds.l	4
hal_exc_regs	ds.l	16
hal_frames	ds.l	1
hal_pcring	ds.l	17
hal_pcpos	ds.w	1
hal_wd		ds.w	1
hal_starve	ds.w	1
	IFD	PROFILE
prof_pos	ds.l	1
prof_count	ds.l	1
prof_mark	ds.l	4
prof_buf	ds.l	PROFMAX
	ENDIF
hal_padstate	ds.w	1			;pad 2 : pad 1, active high
hal_padports	ds.w	8
hal_z80bus	ds.w	1			;written by the bus requests
hal_zero	ds.w	1			;read by the bus polls: 0 = bus granted
hal_z80res	ds.w	1
hal_psg		ds.w	1
hal_z80ram	ds.b	$2000
hal_sram	ds.b	$4000			;the save RAM's odd bytes ($2000 bytes)
ctx_game_sp	ds.l	1
ctx_rend_sp	ds.l	1
ctx_cur		ds.b	1			;0 game, -1 renderer running
ctx_ready	ds.b	1
		cnop	0,4
rend_stack	ds.b	16384
rend_stack_top

	section	chip,bss_c
hal_copempty	ds.l	4
	IFD	WATCHDOG
hal_dbgcop	ds.l	20
hal_dbgscr	ds.b	40*200
	ENDIF

	section	game,code
