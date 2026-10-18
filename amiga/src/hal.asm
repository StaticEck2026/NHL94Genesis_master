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
	move.l	a1,$6C(a0)			;level 3
	move.l	a1,$70(a0)			;level 4
	move.l	a1,$74(a0)			;level 5
	move.l	a1,$7C(a0)			;level 7
	move.l	a1,$60(a0)			;spurious
	lea	hal_int6(pc),a1
	move.l	a1,$78(a0)			;level 6: CIA-B, the Genesis vblank
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
;	through the VBint vector, as VBjsr does on the cartridge.
hal_int6
	move.l	d0,-(sp)
	move.b	(CIAB_ICR).l,d0			;reading acknowledges
	move.w	#$2000,(CUSTOM+INTREQ).l
	btst	#0,d0
	beq.s	.none
	move.l	(sp)+,d0
	addq.l	#1,(hal_frames).l
	jsr	(snd_z80_poll).l
	move.l	(VBint).l,-(sp)
	rts					;into the game's vblank code, which ends in rte
.none	move.l	(sp)+,d0
	rte

_start
	moveq	#0,d0				;AmigaDOS start: not written yet
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

;	Pads: d0 = pad 1, d1 = pad 2 as the Genesis 3 button pad reads them (active low:
;	bit 7 Start, 6 A, 5 C, 4 B, 3 right, 2 left, 1 down, 0 up).
hal_readpads
	move.w	(hal_padstate).l,d0
	not.w	d0
	move.w	d0,d1
	lsr.w	#8,d1
	rts

	section	halbss,bss
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

	section	game,code
