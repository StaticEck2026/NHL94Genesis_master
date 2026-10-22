;	The picture's layout, as the game sets it: its colours, how far its planes are scrolled,
;	how wide the screen is, how big the planes are, and how many rows the window covers at the
;	top. The game's screens set these here (the patches in amiga/tools/patches.py, where the
;	Genesis wrote its video chip's registers, colour RAM and scroll RAM); the renderer
;	(render.asm) draws from them.

	section	bss,bss
	cnop	0,4
ds_gen		ds.l	1			;bumped on every change of the picture's layout or cells
						;(the renderer draws again)
ds_palgen	ds.l	1			;bumped on every change of the colours
ds_pal		ds.w	64			;the colours, as the game keeps them: ----bbb-ggg-rrr-;
						;colour 0 is the backdrop, and the first of each line of 16
						;shows it
ds_hs		ds.l	224			;horizontal scroll, plane A : plane B: the whole screen's
						;(the first), or each line's (ds_lines)
ds_vs		ds.w	2			;vertical scroll: plane A, plane B
ds_nta		ds.w	1			;where plane A's, plane B's and the window's cells are kept,
ds_ntb		ds.w	1			;and the sprite list (the game's VmMAP1, VmMAP2, VmMAP3 and
ds_ntw		ds.w	1			;VSPRITES at setVram)
ds_sat		ds.w	1
ds_wide		ds.b	1			;the screen is 320 pixels across (else 256)
ds_big		ds.b	1			;the planes are 128 cells across (else 64; 32 down)
ds_win		ds.b	1			;rows of the window from the top (0: none)
ds_lines	ds.b	1			;scrolled by lines (ds_hs: a long each)

	section	game,code

;	A screen begins (the game's setVram): 320 or 256 pixels across (disflags df32c), planes
;	of 128 or 64 cells across (Map1col1), where the cells are (VmMAP1-3, VSPRITES); no
;	window, the planes unscrolled. Keeps all registers.
ds_setup
	movem.l	d0/a0,-(sp)
	btst	#df32c,(disflags).l
	seq	(ds_wide).l
	cmpi.w	#6,(Map1col1).l
	sne	(ds_big).l
	move.w	(VmMAP1).l,(ds_nta).l
	move.w	(VmMAP2).l,(ds_ntb).l
	move.w	(VmMAP3).l,(ds_ntw).l
	move.w	(VSPRITES).l,(ds_sat).l
	sf	(ds_win).l
	sf	(ds_lines).l
	clr.l	(ds_vs).l
	lea	(ds_hs).l,a0
	moveq	#224/4-1,d0
.c	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	dbf	d0,.c
	addq.l	#1,(ds_gen).l
	movem.l	(sp)+,d0/a0
	rts

;	The horizontal scroll of each line (the title screen's): a0 = 224 longs, plane A : plane B.
;	Keeps all registers.
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
