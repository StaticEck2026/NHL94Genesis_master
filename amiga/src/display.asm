;	The picture's layout, as the game sets it: its colours, how far its planes are scrolled,
;	how wide the screen is, how big the planes are, how many rows the window covers at the top.

	section	bss,bss
	cnop	0,4
ds_gen		ds.l	1
ds_palgen	ds.l	1
ds_pal		ds.w	64
ds_hs		ds.l	224
ds_vs		ds.w	2
ds_nta		ds.w	1
ds_ntb		ds.w	1
ds_ntw		ds.w	1
ds_spr		ds.l	2*80
ds_wide		ds.b	1
ds_big		ds.b	1
ds_win		ds.b	1
ds_lines	ds.b	1
ds_rink		ds.b	1

	section	game,code

;	A screen begins: 320 or 256 pixels across, planes of 128 or 64 cells across (Map1col1), where
;	the cells are (VmMAP1-3); no window, the planes unscrolled, no sprites. Keeps all registers.
ds_setup
	movem.l	d0/a0,-(sp)
	btst	#df32c,(disflags).l
	seq	(ds_wide).l
	cmpi.w	#6,(Map1col1).l
	sne	(ds_big).l
	move.w	(VmMAP1).l,(ds_nta).l
	move.w	(VmMAP2).l,(ds_ntb).l
	move.w	(VmMAP3).l,(ds_ntw).l
	sf	(ds_win).l
	sf	(ds_lines).l
	sf	(ds_rink).l
	clr.l	(ds_vs).l
	lea	(ds_hs).l,a0
	moveq	#224/4-1,d0
.c	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	dbf	d0,.c
	lea	(ds_spr).l,a0
	moveq	#80-1,d0
.s	clr.l	(a0)+
	clr.l	(a0)+
	dbf	d0,.s
	addq.l	#1,(ds_gen).l
	movem.l	(sp)+,d0/a0
	rts

;	The sprite list: d0 words at a0 (the game's Satt; its DumpSprites2 and the title screen's
;	and the playoff tree's vertical blanks), the screen's from now on. Keeps all registers.
ds_sprites
	movem.l	d0/a0-a1,-(sp)
	jsr	(rd_obj_publish).l
	addq.l	#1,(ds_gen).l
	lea	(ds_spr).l,a1
	andi.l	#$FFFF,d0
	lsr.w	#1,d0
	beq.s	.x
	cmpi.w	#2*80,d0
	bls.s	.n
	move.w	#2*80,d0
.n	subq.w	#1,d0
.c	move.l	(a0)+,(a1)+
	dbf	d0,.c
.x	movem.l	(sp)+,d0/a0-a1
	rts

;	The horizontal scroll of each line (the title screen's):
;	a0 = 224 longs, plane A: plane B. Keeps all registers.
ds_hlines
	movem.l	d0/a0-a1,-(sp)
	lea	(ds_hs).l,a1
	moveq	#224/4-1,d0
.c	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d0,.c
	addq.l	#1,(ds_gen).l
	movem.l	(sp)+,d0/a0-a1
	rts

;	The 64 colours from a1 (the game's palfadenew). Keeps all registers.
ds_colours
	movem.l	d0/a0-a1,-(sp)
	lea	(ds_pal).l,a0
	moveq	#64/2-1,d0
.c	move.l	(a1)+,(a0)+
	dbf	d0,.c
	addq.l	#1,(ds_palgen).l
	movem.l	(sp)+,d0/a0-a1
	rts
