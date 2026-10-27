;	The game's video memory: its tiles and its cell maps (the planes, the window), in its
;	own formats and at the addresses it gives them, as its graphics routines write them.

VMSIZE		equ	$10000
SPRTSIZE	equ	frameSprData-Spritetiles
VSLACK		equ	$400

	section	bss,bss
	cnop	0,4
vm_data		ds.b	VMSIZE+VSLACK
vm_wmap		ds.l	64
vm_tsrc		ds.l	2048

	section	game,code

;	The game's Vmaddr: a0 = where the data for its address
;	d0.w goes (the game writes it through (a0)+). Keeps d0-d7.
vm_at
	move.l	d0,-(sp)
	addq.l	#1,(ds_gen).l
	andi.l	#$FFFF,d0
	lea	(vm_data).l,a0
	adda.l	d0,a0
	lsr.w	#5,d0
	bfset	(vm_wmap).l{d0:1}
	move.l	(sp)+,d0
	rts

;	DoDMA: copy d0 words from a0 to address d1.
vm_load
	bsr	vm_tsrc_note
	cmpa.l	#Spritetiles,a0
	blo.s	.cp
	cmpa.l	#Spritetiles+SPRTSIZE,a0
	bhs.s	.cp
	move.w	d1,-(sp)
	andi.w	#31,(sp)+
	bne.s	.cp
	addq.l	#1,(ds_gen).l
	rts
.cp
	movem.l	d0-d4/a0-a2,-(sp)
	addq.l	#1,(ds_gen).l
	lea	(vm_data).l,a1
	andi.l	#$FFFF,d1
	adda.l	d1,a1
	andi.l	#$FFFF,d0
	beq	.x
	lea	(tc_dirty).l,a2
	moveq	#-1,d3
	lsr.l	#1,d0
	beq	.word
	subq.l	#1,d0
.long	cmpm.l	(a0)+,(a1)+
	dbne	d0,.long
	beq	.word
	move.l	-4(a0),-(a1)
	bsr	.mark
	addq.l	#4,a1
	dbf	d0,.long
.word	btst	#0,3(sp)
	beq	.x
	move.w	(a0)+,d2
	cmp.w	(a1),d2
	beq	.x
	move.w	d2,(a1)
	bsr	.mark
.x	movem.l	(sp)+,d0-d4/a0-a2
	rts
.mark	move.l	a1,d4
	sub.l	#vm_data,d4
	lsr.l	#5,d4
	cmp.l	d3,d4
	beq	.m
	move.l	d4,d3
	cmpi.l	#2047,d4
	bhi	.m
	bfset	(a2){d4:1}
.m	rts

;	A load of d0 words from a0 to address d1: each tile it fills whole from the
;	program gets its data's address in vm_tsrc, the others it writes 0. Keeps all.
vm_tsrc_note
	movem.l	d0-d6/a1-a2,-(sp)
	lea	(tc_dirty).l,a2
	andi.l	#$FFFF,d0
	beq	.x
	andi.l	#$FFFF,d1
	add.l	d0,d0
	move.l	d1,d2
	add.l	d0,d2
	moveq	#0,d5
	cmpa.l	#hal_header,a0
	blo.s	.k
	cmpa.l	#game_end,a0
	bhs.s	.k
	moveq	#1,d5
.k	move.l	d1,d3
	lsr.l	#5,d3
	lea	(vm_tsrc).l,a1
.t	cmpi.l	#2047,d3
	bhi.s	.x
	move.l	d3,d4
	lsl.l	#5,d4
	cmp.l	d2,d4
	bhs.s	.x
	tst.b	d5
	beq.s	.z
	cmp.l	d1,d4
	blo.s	.z
	move.l	d4,d0
	addi.l	#32,d0
	cmp.l	d2,d0
	bhi.s	.z
	move.l	d4,d0
	sub.l	d1,d0
	add.l	a0,d0
	bra.s	.st
.z	moveq	#0,d0
.st	move.l	(a1,d3.l*4),d6
	move.l	d0,(a1,d3.l*4)
	cmp.l	d0,d6
	beq.s	.n
	subi.l	#Spritetiles,d6
	cmpi.l	#SPRTSIZE,d6
	blo.s	.mk
	move.l	d0,d6
	subi.l	#Spritetiles,d6
	cmpi.l	#SPRTSIZE,d6
	bhs.s	.n
.mk	bfset	(a2){d3:1}
.n	addq.l	#1,d3
	bra.s	.t
.x	movem.l	(sp)+,d0-d6/a1-a2
	rts

;	DoDMA_nd2: a copy within video memory, d0 = bytes, d1 = destination, d2 = source.
vm_copy
	movem.l	d0-d2/a0-a1,-(sp)
	move.l	d0,-(sp)
	addq.w	#1,d0
	lsr.w	#1,d0
	jsr	(vm_dirty).l
	move.l	(sp)+,d0
	lea	(vm_data).l,a0
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

;	DoFill: write d0 words of d2 from address d1 (the game's loop wrote d0/2 longs).
vm_fill
	jsr	(vm_dirty).l
	movem.l	d0-d1/a0,-(sp)
	lea	(vm_data).l,a0
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

;	Clear the video memory.
vm_init
	movem.l	d0/a0,-(sp)
	lea	(vm_data).l,a0
	move.l	#(VMSIZE+VSLACK)/4-1,d0
.c	clr.l	(a0)+
	subq.l	#1,d0
	bpl	.c
	movem.l	(sp)+,d0/a0
	rts
