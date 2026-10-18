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

GENESIS_HZ	equ	60
CIA_CLOCK	equ	709379			;PAL E clock; an NTSC machine runs 1% faster

	section	game,code
hal_header
	bra.w	_start
	dc.b	'NH94'
	dc.l	hal_game_main
	dc.l	hal_debug

;	Debug block, read by the test harness:
;	+0  vdp_regs  +4 vdp_vram  +8 vdp_cram  +12 vdp_vsram  +16 exception info (16 longs)
;	+20 frame counter  +24 pad state
hal_debug
	dc.l	vdp_regs,vdp_vram,vdp_cram,vdp_vsram,hal_exc_info,hal_frames,hal_padstate
	dc.l	rd_count,chunky
	dc.l	bmB,rd_cw,rd_colours
	dc.l	tp_pl,tp_mk,tp_cls

;	Game entry with interrupts off and the machine ours. Sets up the vectors and the VDP, starts
;	the 60 Hz timer and jumps to the cartridge's cold start.
hal_game_main
	move	#$2700,sr
	lea	(RAMBASE).l,a0			;clear the Genesis work RAM
	move.w	#$10000/4-1,d0
.clr	clr.l	(a0)+
	dbf	d0,.clr
	lea	(RAMBASE+$FFF0).l,sp
	bsr	hal_vdp_init
	move.b	#$7D,(hal_z80ram+$96).l		;the sound driver's "Z80 idle" handshake
	bsr	hal_set_vectors
	jsr	(rd_init).l
	bsr	hal_display_init
	bsr	ctx_init
	tst.b	(hal_amiga).l
	beq.s	.nokbd
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
	move.l	a1,$6C(a0)			;level 3
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
	move.b	#(CIA_CLOCK/GENESIS_HZ)&$FF,(CIAB_TALO).l
	move.b	#(CIA_CLOCK/GENESIS_HZ)>>8,(CIAB_TAHI).l
	move.b	#$81,(CIAB_ICR).l		;timer A interrupt on
	move.b	#$11,(CIAB_CRA).l		;start, continuous, force load
	move.w	#$2000,(CUSTOM+INTREQ).l
	move.w	#$C000|$2000,(CUSTOM+INTENA).l	;master + EXTER (level 6)
	rts

;	Level 6. The CIA-B timer is the Genesis vertical blank: count it and run the game's handler
;	through the VBint vector, as VBjsr does on the cartridge. The handler ends in rte, so it is
;	given a frame that returns here; then, if the renderer was running while the game waited
;	for this vblank (hal_idle), the game gets the CPU back at once.
hal_int6
	move.l	d0,-(sp)
	move.b	(CIAB_ICR).l,d0			;reading acknowledges
	move.w	#$2000,(CUSTOM+INTREQ).l
	btst	#0,d0
	beq.s	.none
	move.l	(sp)+,d0
	addq.l	#1,(hal_frames).l
	jsr	(snd_z80_poll).l
	move.w	#$0078,-(sp)			;format 0 frame for the game handler's rte
	pea	(.post).l
	move	sr,-(sp)
	move.l	(VBint).l,-(sp)
	rts					;into the game's vblank code
.post	tst.b	(ctx_cur).l
	bne.s	ctx_to_game			;renderer interrupted: back to the waiting game
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
	bhs.s	.no				;called from interrupt code: never switch there
	move.l	(hal_frames).l,d0
	cmp.l	(rd_lastframe).l,d0
	beq.s	.no				;frame already drawn
	tst.b	(ctx_ready).l
	beq.s	.no
	move.l	(sp)+,d0
	trap	#0
	rts
.no	move.l	(sp)+,d0
	rts

;	trap #0: game -> renderer
ctx_to_render
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	sp,(ctx_game_sp).l
	st	(ctx_cur).l
	movea.l	(ctx_rend_sp).l,sp
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;	trap #1, or a vblank while drawing: renderer -> game
ctx_to_game
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
	beq.s	.yield
	move.l	d0,(rd_lastframe).l
	jsr	(rd_frame).l
.yield	trap	#1
	bra.s	rend_main

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

;	Stand-in for the Z80 sound driver: take the 68000 driver's command buffer and PCM requests
;	from the Z80 RAM buffer and play them (sound.asm). Until then just acknowledge.
snd_z80_poll
	rts
snd_z80_cmd
	move.b	#$7D,(hal_z80ram+$96).l
	clr.b	(hal_z80ram+$97).l
	rts

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
.hang	bra.s	.hang

	section	bss,bss
	cnop	0,4
hal_vectors	ds.l	64
hal_exc_info	ds.l	4
hal_exc_regs	ds.l	16
hal_frames	ds.l	1
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

	section	game,code
