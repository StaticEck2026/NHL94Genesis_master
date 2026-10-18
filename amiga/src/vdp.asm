;	The Genesis video chip (VDP) as memory. The game's port writes (hal_macros.i) land here:
;	the registers, VRAM, CRAM and VSRAM are kept in RAM and the renderer (render.asm) draws the
;	screen from them each frame.

VRAMSIZE	equ	$10000
VSLACK		equ	$400			;writes that run past the end of a memory land here

	section	bss,bss
	cnop	0,4
vdp_vram	ds.b	VRAMSIZE+VSLACK
vdp_cram	ds.w	64			;9-bit Genesis colours, ----bbb-ggg-rrr-
		ds.b	VSLACK
vdp_vsram	ds.w	40
		ds.b	VSLACK
vdp_dummy	ds.b	VSLACK			;target of commands we do not emulate
vdp_regs	ds.b	32
vdp_pending	ds.w	1			;first word of a split address command waiting
vdp_first	ds.w	1
vdp_cramgen	ds.l	1			;bumped on every CRAM change the renderer must pick up
hal_vdp_ptr	ds.l	1			;address the next data port access uses
hal_ctl_tmp	ds.l	1			;control word / long being written

	section	game,code

hal_vdp_status	dc.w	$3400			;status port: NTSC (bit 0 clear), no DMA busy (bit 1)

;	Control port word write. hal_ctl_tmp = the word. Keeps every register and the flags.
hal_vdpctl_w
	move	sr,-(sp)
	movem.l	d0-d1,-(sp)
	move.w	(hal_ctl_tmp).l,d0
	tst.w	(vdp_pending).l
	bne	.second
	move.w	d0,d1
	andi.w	#$C000,d1
	cmpi.w	#$8000,d1
	beq	.reg
	move.w	d0,(vdp_first).l		;first half of an address command
	move.w	#1,(vdp_pending).l
	bra	.x
.reg	bsr	vdp_regwrite
	bra	.x
.second	clr.w	(vdp_pending).l
	swap	d0
	move.w	(vdp_first).l,d0
	swap	d0				;d0 = first word : this word
	bsr	vdp_command
.x	movem.l	(sp)+,d0-d1
	rtr

;	Control port long write. hal_ctl_tmp = the long.
hal_vdpctl_l
	move	sr,-(sp)
	movem.l	d0-d1,-(sp)
	move.l	(hal_ctl_tmp).l,d0
	clr.w	(vdp_pending).l
	move.l	d0,d1
	swap	d1
	andi.w	#$C000,d1
	cmpi.w	#$8000,d1
	bne	.cmd
	swap	d0				;two register writes in one long (or a register, then
	bsr	vdp_regwrite			;the first half of a command)
	swap	d0
	move.w	d0,d1
	andi.w	#$C000,d1
	cmpi.w	#$8000,d1
	bne	.half
	bsr	vdp_regwrite
	bra	.x
.half	move.w	d0,(vdp_first).l
	move.w	#1,(vdp_pending).l
	bra	.x
.cmd	bsr	vdp_command
.x	movem.l	(sp)+,d0-d1
	rtr

;	d0.w = $8rvv: register r = vv
vdp_regwrite
	addq.l	#1,(hal_vdp_gen).l		;the renderer draws again
	move.l	a0,-(sp)
	move.w	d0,d1
	lsr.w	#8,d1
	andi.w	#$1F,d1
	lea	(vdp_regs).l,a0
	move.b	d0,(a0,d1.w)
	movea.l	(sp)+,a0
	rts

;	d0.l = address command: CD1-0 in bits 31-30, A13-0 in bits 29-16, CD5-2 in bits 7-4,
;	A15-14 in bits 1-0. Points hal_vdp_ptr at the memory and address it selects.
vdp_command
	addq.l	#1,(hal_vdp_gen).l
	movem.l	d2/a0,-(sp)
	move.l	d0,d1
	swap	d1
	andi.l	#$3FFF,d1
	move.w	d0,d2
	andi.w	#3,d2
	ror.w	#2,d2				;A15-14 to bits 15-14
	or.w	d2,d1				;d1 = address
	move.l	d0,d2
	rol.l	#2,d2
	andi.w	#3,d2				;CD1-0
	lsr.w	#2,d0
	andi.w	#$C,d0				;CD3-2
	or.w	d0,d2				;d2 = CD3-0
	cmpi.w	#1,d2
	bls	.vram				;0 read, 1 write
	cmpi.w	#3,d2
	beq	.cram
	cmpi.w	#8,d2
	beq	.cram
	cmpi.w	#4,d2
	beq	.vsram
	cmpi.w	#5,d2
	beq	.vsram
	lea	(vdp_dummy).l,a0
	bra	.set
.vram	lea	(vdp_vram).l,a0
	adda.l	d1,a0
	bra	.set
.cram	andi.w	#$7F,d1
	lea	(vdp_cram).l,a0
	adda.w	d1,a0
	addq.l	#1,(vdp_cramgen).l
	bra	.set
.vsram	andi.w	#$7F,d1
	lea	(vdp_vsram).l,a0
	adda.w	d1,a0
.set	move.l	a0,(hal_vdp_ptr).l
	movem.l	(sp)+,d2/a0
	rts

;	DoDMA: copy d0 words from a0 to VRAM address d1. Keeps every register.
hal_vdp_dma
	jsr	(hal_vdp_dirty).l
	movem.l	d0-d1/a0-a1,-(sp)
	lea	(vdp_vram).l,a1
	andi.l	#$FFFF,d1
	adda.l	d1,a1
	andi.l	#$FFFF,d0
	beq	.x
	subq.l	#1,d0
.loop	move.w	(a0)+,(a1)+
	dbf	d0,.loop
.x	movem.l	(sp)+,d0-d1/a0-a1
	rts

;	DoDMA_nd2: VRAM to VRAM copy, d0 = bytes, d1 = destination, d2 = source.
hal_vdp_copy
	movem.l	d0-d2/a0-a1,-(sp)
	move.l	d0,-(sp)
	addq.w	#1,d0
	lsr.w	#1,d0				;bytes to words
	jsr	(hal_vdp_dirty).l
	move.l	(sp)+,d0
	lea	(vdp_vram).l,a0
	movea.l	a0,a1
	andi.l	#$FFFF,d1
	andi.l	#$FFFF,d2
	adda.l	d2,a0
	adda.l	d1,a1
	andi.l	#$FFFF,d0
	beq	.x
	subq.l	#1,d0
.loop	move.b	(a0)+,(a1)+
	dbf	d0,.loop
.x	movem.l	(sp)+,d0-d2/a0-a1
	rts

;	DoFill: write d0 words of d2 from VRAM address d1 (the game's loop writes d0/2 longs).
hal_vdp_fill
	jsr	(hal_vdp_dirty).l
	movem.l	d0-d1/a0,-(sp)
	lea	(vdp_vram).l,a0
	andi.l	#$FFFF,d1
	adda.l	d1,a0
	andi.l	#$FFFF,d0
	lsr.l	#1,d0
	beq	.x
	subq.l	#1,d0
.loop	move.w	d2,(a0)+
	move.w	d2,(a0)+
	dbf	d0,.loop
.x	movem.l	(sp)+,d0-d1/a0
	rts

;	Clear the VDP memories and registers.
hal_vdp_init
	movem.l	d0/a0,-(sp)
	lea	(vdp_vram).l,a0
	move.l	#(VRAMSIZE+VSLACK)/4-1,d0
.c	clr.l	(a0)+
	subq.l	#1,d0
	bpl	.c
	lea	(vdp_cram).l,a0
	move.w	#(128+VSLACK+80+VSLACK+VSLACK+32)/4-1,d0
.c2	clr.l	(a0)+
	dbf	d0,.c2
	clr.w	(vdp_pending).l
	move.l	#vdp_dummy,(hal_vdp_ptr).l
	movem.l	(sp)+,d0/a0
	rts
