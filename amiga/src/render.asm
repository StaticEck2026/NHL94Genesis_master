;	Renderer: draws the emulated Genesis VDP (vdp.asm) on the AGA display, 6 bitplanes
;	(the 64 CRAM colours), interleaved, double buffered.
;
;	Fast path (full screen scroll, the game screens):
;	  * tiles are kept converted to planar form (tile cache, both horizontal orientations), and
;	    converted again when their VRAM changes (hal_vdp_dirty);
;	  * plane B is kept as a planar bitmap of its whole name table, redrawn only where an entry
;	    or its tile changed;
;	  * scroll mode (a 64 x 32 cell plane B, the rink): each screen buffer holds all of plane B
;	    and the display hardware scrolls it (bitplane pointers, BPLCON1). What was drawn over
;	    it (only each sprite image's box of pixels is drawn) and the cells that changed are
;	    restored from the bitmap by the blitter (rd_dirty: 16 pixels by 8 lines a bit);
;	    otherwise plane B is copied to the screen by the blitter at the scroll position;
;	  * plane A, the window and the sprites are drawn on top by the CPU, in Genesis priority
;	    order: B, A low, sprites low, B high (redrawn where something low covered it), A high,
;	    sprites high.
;	Plane B's transparent pixels keep their palette bits and show the backdrop: colours 0, 16,
;	32 and 48 are all set to the backdrop colour (rd_palette).
;
;	Fallback (line or cell scroll, per column vertical scroll, very large planes): the frame is
;	drawn per line in a chunky buffer and converted to planar (rd_chunky).

SBPR		equ	72			;screen bytes per plane row: 32 pixel margin, plane B's 512, 32
SROW		equ	SBPR*6			;interleaved row of the 6 planes
SCRX		equ	4			;byte of plane x 0 (scroll mode) / screen x 0 (otherwise)
BUFH		equ	480			;rows: plane B's 256, then its first 224 again (vertical wrap)
BUFSIZE		equ	SROW*BUFH
NBUF		equ	3			;screen buffers: one shown, one waiting to be, one drawn
	IFND	DLS
DLS		equ	3			;dirty maps: a row is 1 << DLS lines
	ENDC
DLH		equ	1<<DLS
DROWS		equ	BUFH>>DLS		;rows of the dirty maps
DWRAP		equ	256>>DLS		;(the row the buffer's second copy of plane B begins at)
SCRH		equ	224
HUDH		equ	64			;HUD sprites: lines at most
HUDSPR		equ	16+HUDH*16+16		;bytes of one (64 pixels wide: control, lines, end)
HUDX		equ	$A0			;sprite horizontal position of screen x 0 (H32)
OSBPR		equ	48			;the overlay: 32 pixel margin, 320, 32 margin
OSROW		equ	OSBPR*6
NPLANES		equ	6
CHPITCH		equ	384			;chunky fallback: bytes per line
CHLEFT		equ	32			;screen x 0 is at this offset
BMAX		equ	2048			;largest plane B (cells) the fast path keeps as a bitmap
SCARENA		equ	$40000			;sprite image cache: bytes of images (a power of 2)
SCSLOTS		equ	4096			;its table entries (a power of 2): key, ring position,
						;frame built, image, its box (rd_sc_box), the key's
						;second long (a data address key: rd_sc_get), 32 bytes

TNEED	macro					;tile \1 (0-2047, a long) converted if it waits
	bftst	(tc_pend).l{\1:1}
	beq.s	.tn\@
	movem.l	d0-d1,-(sp)
	move.l	\1,d0
	moveq	#1,d1
	bsr	rd_tiles_need
	movem.l	(sp)+,d0-d1
.tn\@
	endm

	section	bss,bss
	cnop	0,4
tp_pl		ds.l	4096*8			;tile cache planes: (tile | hflip<<11), 8 rows of p0p1p2p3
tp_mk		ds.b	4096*8			;mask per row (bit set = pixel not transparent)
tp_cls		ds.b	4096			;0 empty, 1 opaque, 2 mixed
tc_dirty	ds.l	64			;one bit per tile: convert before use
tc_pend		ds.l	64			;one bit per tile: changed, converted when a sprite needs it
tc_chg		ds.l	64			;tiles converted this frame
rd_ptab		ds.l	256			;byte (2 pixels) -> its bits in the 4 plane bytes
rd_pftab	ds.l	256			;the same for the flipped tile
rd_nibtab	ds.w	256			;chunky fallback: byte -> 2 pixel bytes
rd_revtab	ds.w	256			;the same, swapped
rd_attr		ds.l	8			;chunky fallback: pixel OR value by entry bits 15-13
chunky		ds.b	CHPITCH*SCRH
shB		ds.w	BMAX			;plane B name table as drawn in bmB
rd_tlhead	ds.w	2048			;per tile: the first cell of plane B with it + 1 (0: none)
rd_tlnext	ds.w	BMAX			;per cell: the next with its tile + 1
rd_tlprev	ds.w	BMAX			;and the one before + 1 (0: it is the first)
rd_tltile	ds.w	BMAX			;the tile whose list it is in + 1 (0: none)
rd_hiB		ds.l	BMAX			;plane B high priority cells: column, row (words)
rd_hibits	ds.l	BMAX/32			;the same as bits (row * plane width + column)
rd_fixmap	ds.l	2*32			;rd_fixups: the cells to draw again (64 a row)
rd_hiBn		ds.w	1
rd_hiBok	ds.w	1			;list matches bmB (rd_hibits always does: rd_cellB)
rd_Bkey		ds.l	2			;base, size of the plane in bmB (invalid: redraw all)
rd_cover	ds.l	2*32			;screen cells something low was drawn on (fixups): a bit
						;each, 64 a row
rd_sprites	ds.l	2*80
rd_scmemo	ds.l	8*80			;per sprite of the list: the image it had (rd_sc_get)
rd_skey		ds.l	1			;(rd_sc_get: the key by tiles)
rd_spn		ds.w	1
rd_w		ds.w	1			;screen width 256 / 320
rd_cells	ds.w	1			;tiles across +1
rd_cw		ds.w	1			;plane B cells across, down
rd_ch		ds.w	1
rd_bx0		ds.w	1			;plane B pixel at screen 0, 0
rd_by0		ds.w	1
rd_back		ds.l	1			;back buffer: screen line 0
rd_buf		ds.l	1			;back buffer
rd_dmap		ds.l	1			;its dirty map
rd_dirty	ds.l	NBUF*DROWS		;per buffer, row of DLH lines: the 16 pixel columns of plane B
						;(bit 31 - n: column n) that differ from the bitmap
rd_bufi		ds.w	1			;the back buffer's number
rd_xorg		ds.w	1			;bit in a buffer row of screen x 0
rd_brow0	ds.w	1			;buffer row of screen line 0
rd_scroll	ds.w	1			;scroll mode this frame
rd_vfail	ds.l	1			;self-check (VERIFY builds): first failure
rd_backcop	ds.l	1			;its copper list
rd_regs		ds.b	32			;the VDP registers (rd_snapshot)
rd_hs		ds.l	1			;its plane A, B horizontal scroll
rd_vs		ds.l	1			;and vertical scroll
rd_sctab	ds.l	8*SCSLOTS		;sprite image cache (rd_sc_get)
rd_sslot	ds.w	1			;rd_sc_get: the sprite's place in the list
rd_rowoff	ds.l	SCRH			;line * SROW
rd_sprnat	ds.b	1			;Spritetiles is planar (rd_init)
	even
rd_bl0		ds.w	1			;rd_sc_get: the image's first line with something in it,
rd_bnl		ds.w	1			;lines from there (0: none),
rd_bp0		ds.w	1			;first pixel and last pixel across
rd_bp1		ds.w	1
rd_scpos	ds.l	1			;bytes written to its ring so far
rd_scmin	ds.l	2			;its oldest image used in this frame, in the one before
rd_tchg		ds.l	2048			;frame each tile was last converted in
rd_vblanks	ds.l	1			;vertical blanks (level 3 interrupt)
rd_shownvb	ds.l	NBUF			;per buffer: rd_vblanks when its copper list was set
						;($7FFFFFFF: queued, not yet)
rd_lastframe	ds.l	1
rd_lastgen	ds.l	2
rd_count	ds.l	1			;frames drawn
rd_palgen	ds.l	1			;the CRAM changes and registers the colours are of
rd_palkey	ds.l	1
rd_colgen	ds.l	1			;changed when rd_colours change
rd_copgen	ds.l	2*NBUF			;per buffer: rd_colgen, rd_hudgen its copper list's
						;colours are of
rd_colours	ds.w	64			;high nibbles of the 24 bit colours ($0RGB)
rd_colourslo	ds.w	64			;and the low nibbles
rd_mode		ds.w	1
rd_clipx0	ds.w	1
rd_clipx1	ds.w	1
rd_pass		ds.w	1			;0 low priority pass, $8000 high
rd_tmp		ds.l	8
rd_cellpri	ds.w	1
rd_rowbuf	ds.l	2
mkB		ds.b	BMAX*8			;plane B high priority mask (for the CPU: fast memory)

	section	chip,bss_c
	cnop	0,8
rd_screens	ds.b	BUFSIZE*NBUF
bmB		ds.b	BMAX*48			;plane B: cells * 8 rows * 6 planes
mkB6		ds.b	BMAX*48			;its high priority mask in each plane's place (blitter)
rd_cop		ds.l	NBUF*256			;a copper list per buffer
rd_cqbuf	ds.b	2*CQI			;the copper's blit ring (rd_cq_init)
rd_scarena	ds.b	SCARENA			;sprite images (rd_sc_get)
rd_ovl		ds.b	OSROW*SCRH		;plane A / window overlay
rd_fpsimg	ds.w	5*NPLANES*NBUF		;the frame rate digits (rd_fps), per buffer
	cnop	0,8
rd_hudsd	ds.b	NBUF*8*HUDSPR		;the HUD sprites: each buffer's copy of rd_hudm
rd_sprnull	ds.l	4			;a sprite that is not there
rd_ovlmlo	ds.b	OSROW*SCRH		;its low priority mask, each row once per plane (so one blit
rd_ovlmhi	ds.b	OSROW*SCRH		;does all 6); the high priority mask (follows the low one)

	section	game,code

;	------------------------------------------------------------------------------------------
rd_init
	movem.l	d0-d7/a0-a6,-(sp)
	; plane tables: pixel pair b (left pixel in the high nibble), bit p of each pixel goes to
	; plane byte p (p0 is the high byte of the long); left pixel bit 1, right pixel bit 0
	lea	(rd_ptab).l,a0
	lea	(rd_pftab).l,a1
	moveq	#0,d0
.pt	moveq	#0,d1				;normal
	moveq	#0,d2				;flipped: left pixel bit 0, right bit 1
	moveq	#0,d3				;plane
.pp	move.l	#24,d4
	move.w	d3,d5
	lsl.w	#3,d5
	sub.w	d5,d4				;bit position of plane p's byte
	move.w	d3,d5
	addq.w	#4,d5
	btst	d5,d0				;left pixel bit p
	beq	.nl
	move.l	d4,d5
	addq.l	#1,d5
	bset	d5,d1
	bset	d4,d2
.nl	btst	d3,d0				;right pixel bit p
	beq	.nr
	bset	d4,d1
	move.l	d4,d5
	addq.l	#1,d5
	bset	d5,d2
.nr	addq.w	#1,d3
	cmpi.w	#4,d3
	bne	.pp
	move.l	d1,(a0)+
	move.l	d2,(a1)+
	addq.w	#1,d0
	cmpi.w	#256,d0
	bne	.pt
	; chunky tables
	lea	(rd_nibtab).l,a0
	lea	(rd_revtab).l,a1
	moveq	#0,d0
.nt	move.w	d0,d1
	lsr.w	#4,d1
	move.w	d0,d2
	andi.w	#$F,d2
	move.w	d1,d3
	lsl.w	#8,d3
	or.w	d2,d3
	move.w	d3,(a0)+
	move.w	d2,d3
	lsl.w	#8,d3
	or.w	d1,d3
	move.w	d3,(a1)+
	addq.w	#1,d0
	cmpi.w	#256,d0
	bne	.nt
	lea	(rd_attr).l,a0
	moveq	#0,d0
.at	move.l	d0,d1
	andi.l	#3,d1
	lsl.l	#4,d1
	btst	#2,d0
	beq	.np
	ori.l	#$40,d1
.np	move.l	d1,d2
	lsl.l	#8,d2
	or.l	d2,d1
	move.l	d1,d2
	swap	d2
	or.l	d2,d1
	move.l	d1,(a0)+
	addq.w	#1,d0
	cmpi.w	#8,d0
	bne	.at
	bsr	rd_dirty_all
	lea	(rd_screens).l,a0
	move.l	a0,(rd_back).l
	move.l	a0,(rd_buf).l
	clr.w	(rd_bufi).l
	lea	(rd_dirty).l,a0
	move.l	a0,(rd_dmap).l
	move.w	#NBUF*DROWS-1,d0
.dm	move.l	#-1,(a0)+			;nothing in the buffers yet
	dbf	d0,.dm
	move.w	#SCRX*8,(rd_xorg).l
	clr.w	(rd_brow0).l
	lea	(rd_cop).l,a0
	move.l	a0,(rd_backcop).l
	moveq	#-1,d0
	move.l	d0,(rd_Bkey).l
	move.l	d0,(rd_lastgen).l
	move.l	d0,(rd_palgen).l
	lea	(rd_copgen).l,a0		;no colours in the copper lists
	moveq	#2*NBUF-1,d1
.cg	move.l	d0,(a0)+
	dbf	d1,.cg
	lea	(rd_shownvb).l,a0		;(none on the screen)
	moveq	#NBUF-1,d1
.sv	move.l	d0,(a0)+
	dbf	d1,.sv
	lea	(rd_sctab).l,a0			;no sprite images
	move.w	#SCSLOTS-1,d1
.sc	move.l	d0,(a0)
	lea	32(a0),a0
	dbf	d1,.sc
	; the players' sprite tiles (Spritetiles) to planar rows in place, as the tile cache holds
	; them (tp_pl): DMAs from them only note where each tile's data is (vdp_tsrc, hal_vdp_dma)
	; and the tile cache copies it from here (rd_decode_tile). Once.
	tst.b	(rd_sprnat).l
	bne.s	.sn
	st	(rd_sprnat).l
	lea	(Spritetiles).l,a0
	move.l	#SPRTSIZE/4,d7
	lea	(rd_ptab).l,a5
	moveq	#0,d2
.snr	move.l	(a0),d0
	rol.l	#8,d0
	move.b	d0,d2
	move.l	(a5,d2.w*4),d1
	lsl.l	#2,d1
	rol.l	#8,d0
	move.b	d0,d2
	or.l	(a5,d2.w*4),d1
	lsl.l	#2,d1
	rol.l	#8,d0
	move.b	d0,d2
	or.l	(a5,d2.w*4),d1
	lsl.l	#2,d1
	rol.l	#8,d0
	move.b	d0,d2
	or.l	(a5,d2.w*4),d1
	move.l	d1,(a0)+
	subq.l	#1,d7
	bne.s	.snr
.sn	lea	(rd_rowoff).l,a0		;screen line -> offset in a buffer
	moveq	#0,d0
	move.w	#SCRH-1,d1
.ro	move.l	d0,(a0)+
	addi.l	#SROW,d0
	dbf	d1,.ro
	bsr	rd_cq_init
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	------------------------------------------------------------------------------------------
;	Tile cache.

;	VRAM d1 (address), d0 (words) changed: convert the tiles it covers again (and they no
;	longer hold the data a DMA sent, vdp_tsrc).
hal_vdp_dirty
	movem.l	d0-d2/a0-a1,-(sp)
	addq.l	#1,(hal_vdp_gen).l
	andi.l	#$FFFF,d0
	beq	.x
	andi.l	#$FFFF,d1
	add.l	d0,d0
	add.l	d1,d0
	subq.l	#1,d0
	lsr.l	#5,d1
	lsr.l	#5,d0
	cmpi.l	#2047,d0
	bls	.ok
	move.l	#2047,d0
.ok	lea	(tc_dirty).l,a0
	lea	(vdp_tsrc).l,a1
.loop	cmp.l	d0,d1
	bhi	.x
	bfset	(a0){d1:1}
	clr.l	(a1,d1.l*4)
	addq.l	#1,d1
	bra	.loop
.x	movem.l	(sp)+,d0-d2/a0-a1
	rts

hal_vdp_dirty_all
rd_dirty_all
	movem.l	d0/a0,-(sp)
	addq.l	#1,(hal_vdp_gen).l
	lea	(tc_dirty).l,a0
	moveq	#63,d0
.c	move.l	#-1,(a0)+
	dbf	d0,.c
	lea	(vdp_tsrc).l,a0
	move.w	#2048-1,d0
.s	clr.l	(a0)+
	dbf	d0,.s
	movem.l	(sp)+,d0/a0
	rts

;	Convert every dirty tile; tc_chg = the tiles converted. d0 = 0 if none. (rd_frame holds
;	the game's tick meanwhile: the game, which sets the bits, cannot run.)
rd_decode_dirty
	lea	(tc_dirty).l,a4
	lea	(tc_chg).l,a3
	moveq	#0,d7				;the tile of the long's bit 31
	moveq	#0,d3				;any
.long	move.l	(a4),d6
	clr.l	(a4)
	move.l	d6,(a3)+
	beq	.next
	moveq	#1,d3
.bit	bfffo	d6{0:0},d0
	bfclr	d6{d0:1}
	add.l	d7,d0				;a tile
	; a tile of plane A, B or the window: converted now; another (a sprite's): when a sprite
	; image of it is made (rd_tiles_need), which the image cache mostly spares
	bftst	(rd_bused).l{d0:1}
	bne.s	.now
	bftst	(rd_aused).l{d0:1}
	bne.s	.now
	bfset	(tc_pend).l{d0:1}
	lea	(rd_tchg).l,a0
	move.l	(rd_count).l,(a0,d0.l*4)	;(the sprite image cache sees it)
	bra.s	.nb
.now	bfclr	(tc_pend).l{d0:1}
	movem.l	d3/a3,-(sp)
	bsr	rd_decode_tile
	movem.l	(sp)+,d3/a3
.nb	tst.l	d6
	bne.s	.bit
.next	addq.l	#4,a4
	addi.l	#32,d7
	cmpi.l	#2048,d7
	bne	.long
	move.l	d3,d0
	rts

;	Tiles d0 (0-2047) to d0 + d1 - 1 (wrapping round): those waiting (tc_pend) converted. Keeps
;	everything.
rd_tiles_need
	movem.l	d0-d7/a0-a6,-(sp)
	lea	(tc_pend).l,a4
	move.l	d0,d6
	move.l	d1,d7
	subq.w	#1,d7
	bmi.s	.x
.t	andi.l	#$7FF,d6
	bftst	(a4){d6:1}
	beq.s	.n
	bfclr	(a4){d6:1}
	move.l	d6,d0
	bsr	rd_decode_tile
.n	addq.l	#1,d6
	dbf	d7,.t
.x	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	Convert tile d0. Uses d0-d4/a0-a3/a5/a6. A tile a DMA sent from the players' sprite tiles
;	(Spritetiles, planar already: rd_init) is copied from there; VRAM does not hold it.
rd_decode_tile
	lea	(rd_tchg).l,a0
	move.l	(rd_count).l,(a0,d0.l*4)	;(the sprite image cache sees it)
	lea	(vdp_tsrc).l,a0
	move.l	(a0,d0.l*4),d1
	subi.l	#Spritetiles,d1
	cmpi.l	#SPRTSIZE,d1
	blo	.nat
	lea	(vdp_vram).l,a0
	move.l	d0,d1
	lsl.l	#5,d1
	adda.l	d1,a0				;VRAM tile
	lea	(tp_pl).l,a1
	adda.l	d1,a1				;normal planes (32 bytes a tile)
	lea	$800*32(a1),a2			;flipped
	lea	(tp_mk).l,a3
	move.l	d0,d1
	lsl.l	#3,d1
	adda.l	d1,a3				;masks
	lea	(tp_cls).l,a6
	adda.l	d0,a6
	lea	(rd_ptab).l,a5
	moveq	#0,d4				;and of masks : or of masks
	move.w	#$FF00,d4
	moveq	#7,d3
.row	move.l	(a0)+,d0
	; normal: pairs from the top byte, each shifted into place
	moveq	#0,d1
	moveq	#0,d2
	rol.l	#8,d0
	move.b	d0,d2
	move.l	(a5,d2.w*4),d1
	lsl.l	#2,d1
	rol.l	#8,d0
	move.b	d0,d2
	or.l	(a5,d2.w*4),d1
	lsl.l	#2,d1
	rol.l	#8,d0
	move.b	d0,d2
	or.l	(a5,d2.w*4),d1
	lsl.l	#2,d1
	rol.l	#8,d0
	move.b	d0,d2
	or.l	(a5,d2.w*4),d1
	move.l	d1,(a1)+
	; mask = or of the plane bytes
	move.l	d1,d2
	swap	d2
	or.w	d1,d2
	move.w	d2,d1
	lsr.w	#8,d1
	or.b	d2,d1
	move.b	d1,(a3)
	or.b	d1,d4
	move.w	d4,d2
	lsr.w	#8,d2
	and.b	d1,d2
	lsl.w	#8,d2
	move.b	d4,d2
	move.w	d2,d4
	; flipped mask: the bits reversed
	moveq	#0,d2
	move.b	d1,d2
	move.b	(rd_rev8,pc,d2.w),$800*8(a3)
	addq.l	#1,a3
	; flipped planes: the pairs in the other order through the flipped table
	moveq	#0,d1
	moveq	#0,d2
	move.b	d0,d2				;d0 is back to the original: byte 3 (pixels 6, 7)
	move.l	(rd_pftab-rd_ptab)(a5,d2.w*4),d1
	lsl.l	#2,d1
	ror.l	#8,d0
	move.b	d0,d2
	or.l	(rd_pftab-rd_ptab)(a5,d2.w*4),d1
	lsl.l	#2,d1
	ror.l	#8,d0
	move.b	d0,d2
	or.l	(rd_pftab-rd_ptab)(a5,d2.w*4),d1
	lsl.l	#2,d1
	ror.l	#8,d0
	move.b	d0,d2
	or.l	(rd_pftab-rd_ptab)(a5,d2.w*4),d1
	move.l	d1,(a2)+
	dbf	d3,.row
	; class: all rows $FF -> opaque, all 0 -> empty
.class	moveq	#2,d0
	tst.b	d4
	bne	.ne
	moveq	#0,d0
	bra	.cl
.ne	cmpi.w	#$FF00,d4
	blo	.cl
	moveq	#1,d0
.cl	move.b	d0,(a6)
	move.b	d0,$800(a6)
	rts
.nat	; a native tile: its rows are planar already; the flipped planes are each byte's bits
	; reversed, the mask the planes ORed
	lea	(Spritetiles).l,a0
	adda.l	d1,a0				;its rows
	move.l	d0,d1
	lsl.l	#5,d1
	lea	(tp_pl).l,a1
	adda.l	d1,a1				;normal planes
	lea	$800*32(a1),a2			;flipped
	lea	(tp_mk).l,a3
	move.l	d0,d1
	lsl.l	#3,d1
	adda.l	d1,a3				;masks
	lea	(tp_cls).l,a6
	adda.l	d0,a6
	lea	(rd_rev8,pc),a5
	moveq	#0,d4				;and of masks : or of masks
	move.w	#$FF00,d4
	moveq	#0,d2
	moveq	#7,d3
.nr	move.l	(a0)+,d0
	move.l	d0,(a1)+
	rol.l	#8,d0				;(p0)
	move.b	d0,d2
	move.b	(a5,d2.w),d1
	rol.l	#8,d0				;(p1)
	move.b	d0,d2
	lsl.l	#8,d1
	move.b	(a5,d2.w),d1
	rol.l	#8,d0				;(p2)
	move.b	d0,d2
	lsl.l	#8,d1
	move.b	(a5,d2.w),d1
	rol.l	#8,d0				;(p3; d0 is the row again)
	move.b	d0,d2
	lsl.l	#8,d1
	move.b	(a5,d2.w),d1
	move.l	d1,(a2)+
	move.l	d0,d2				;the mask
	swap	d2
	or.w	d0,d2
	move.w	d2,d1
	lsr.w	#8,d1
	or.b	d2,d1
	move.b	d1,(a3)
	or.b	d1,d4
	move.w	d4,d2
	lsr.w	#8,d2
	and.b	d1,d2
	lsl.w	#8,d2
	move.b	d4,d2
	move.w	d2,d4
	moveq	#0,d2
	move.b	d1,d2
	move.b	(a5,d2.w),$800*8(a3)		;(flipped)
	addq.l	#1,a3
	dbf	d3,.nr
	bra	.class

rd_rev8
	dc.b	$00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
	dc.b	$08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
	dc.b	$04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
	dc.b	$0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
	dc.b	$02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
	dc.b	$0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
	dc.b	$06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
	dc.b	$0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
	dc.b	$01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
	dc.b	$09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
	dc.b	$05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
	dc.b	$0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
	dc.b	$03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
	dc.b	$0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
	dc.b	$07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
	dc.b	$0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF

;	------------------------------------------------------------------------------------------
;	One frame into the back buffer, then shown. Skipped when nothing in the VDP changed for two
;	frames.
rd_frame
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(hal_vdp_gen).l,d0
	add.l	(vdp_cramgen).l,d0
	cmp.l	(rd_lastgen).l,d0
	bne	.changed
	cmp.l	(rd_lastgen+4).l,d0
	beq	.skip
.changed
	move.l	(rd_lastgen).l,(rd_lastgen+4).l
	move.l	d0,(rd_lastgen).l
	; all black (a fade, or the game loading behind a black screen): show black and leave the
	; CPU to the game; the tiles are converted when there is something to see
	bsr	rd_palette
	lea	(rd_colours).l,a0
	moveq	#63,d0
.blk	tst.l	(a0)+				;(both tables)
	dbne	d0,.blk
	bne.s	.draw
	bsr	rd_vsync
	bsr	rd_snaptime
	bsr	rd_show
	addq.l	#1,(rd_count).l
	bra	.skip
.draw	bsr	rd_vsync			;(the state is taken once there is a buffer for it)
	move.l	(rd_scmin).l,(rd_scmin+4).l	;(the frame before that has been shown: its blits
	move.l	#$7FFFFFFF,(rd_scmin).l		;are done)
	move.w	#$2000,(CUSTOM+INTENA).l	;the sprite list and the tiles of one game tick: no
	bsr	rd_snapshot			;tick in between (level 6 held; the blit queue and the
	bsr	rd_decode_dirty			;vertical blank go on)
	bsr	rd_snaptime
	move.w	#$A000,(CUSTOM+INTENA).l
	lea	(rd_regs).l,a5
	move.w	#256,d0
	moveq	#33,d1
	move.b	12(a5),d2
	andi.b	#$81,d2
	beq	.h32
	move.w	#320,d0
	moveq	#41,d1
.h32	move.w	d0,(rd_w).l
	move.w	d1,(rd_cells).l
	; fast path?
	move.b	11(a5),d0
	andi.b	#7,d0
	bne	.chunky				;line / cell scroll or column vscroll
	bsr	rd_planesize			;d0 = cells across, d1 = down
	mulu.w	d1,d0
	cmpi.l	#BMAX,d0
	bhi	.chunky
	bsr	rd_fast
	bra	.shown
.chunky	moveq	#-1,d0
	sf	(rd_ntsync).l			;(name table writes are not followed meanwhile)
	bsr	rd_hud_off
	move.l	d0,(rd_Bkey).l			;plane B bitmap no longer matches (all redrawn and
						;restored on the way back)
	move.w	#SCRX*8,(rd_xorg).l
	clr.w	(rd_brow0).l
	bsr	rd_vsync
	bsr	rd_chunky
.shown	bsr	rd_show
	addq.l	#1,(rd_count).l
.skip	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	d0 = plane cells across, d1 = down (a5 = regs). Keeps the rest.
rd_planesize
	move.b	16(a5),d1
	moveq	#32,d0
	btst	#0,d1
	beq	.w
	moveq	#64,d0
	btst	#1,d1
	beq	.w
	move.w	#128,d0
.w	lsr.b	#4,d1
	btst	#0,d1
	bne	.h1
	moveq	#32,d1
	rts
.h1	btst	#1,d1
	bne	.h2
	moveq	#64,d1
	rts
.h2	move.w	#128,d1
	rts

;	==========================================================================================
;	Fast path
rd_fast
	bsr	rd_updateB
	bsr	rd_scrollpos
	bsr	rd_vsync			;(from here on the back buffer is written)
	tst.w	(rd_scroll).l
	beq.s	.copy
	bsr	rd_restore			;scroll mode: plane B is in the buffer, mended
	bra.s	.b
.copy	bsr	rd_blitB
	moveq	#0,d0				;(to be mended when back in scroll mode)
	moveq	#0,d1
	move.w	(rd_w).l,d2
	move.w	#SCRH,d3
	bsr	rd_mark
.b	lea	(rd_cover).l,a0			;nothing low drawn yet
	moveq	#2*32-1,d0
.c	clr.l	(a0)+
	dbf	d0,.c
	bsr	rd_buildA
	tst.b	(rd_ovldirty).l
	beq	.ovl
	bsr	rd_ovl_redraw
.ovl	tst.b	(rd_hudchg).l
	bne.s	.hb
	move.w	(rd_w).l,d0
	cmp.w	(rd_hudw).l,d0
	beq.s	.hk
.hb	bsr	rd_hud_build
.hk	clr.w	(rd_pass).l			;(all queued for the blitter; what the CPU draws
	bsr	rd_ovl_blit			;waits for it)
	bsr	rd_sprites_planar
	bsr	rd_fixups
	move.w	#$8000,(rd_pass).l
	tst.w	(rd_hudon).l
	bne.s	.hs				;(the high priority overlay is the HUD sprites)
	bsr	rd_ovl_blit
.hs	bsr	rd_sprites_planar
	IFD	VERIFY
	bsr	rd_waitblit
	bra	rd_verify
	ENDC
	rts					;(the blitter goes on; rd_show queues the swap)

	IFD	VERIFY
;	Debug: in scroll mode every part of the back buffer its dirty map does not name must be the
;	bitmap's. The first that is not: rd_vfail = frame, map row, column (once).
rd_verify
	tst.w	(rd_scroll).l
	beq	.x
	tst.l	(rd_vfail).l
	bne	.x
	movea.l	(rd_dmap).l,a2
	moveq	#0,d7				;cell row
.r	move.l	(a2,d7.w*4),d6
	moveq	#0,d5				;column
.c	btst	#31,d6
	bne.s	.n
	move.w	d7,d0
	mulu.w	#DLH*SROW,d0
	movea.l	(rd_buf).l,a0
	adda.l	d0,a0
	lea	SCRX(a0,d5.w*2),a0
	moveq	#DWRAP-1,d0
	and.w	d7,d0
	mulu.w	#DLH*64*6,d0
	lea	(bmB).l,a1
	adda.l	d0,a1
	lea	(a1,d5.w*2),a1
	moveq	#DLH*6-1,d4
.l	move.w	(a0),d0
	cmp.w	(a1),d0
	bne.s	.fail
	lea	SBPR(a0),a0
	lea	64(a1),a1
	dbf	d4,.l
.n	lsl.l	#1,d6
	addq.w	#1,d5
	cmpi.w	#32,d5
	blt.s	.c
	addq.w	#1,d7
	cmpi.w	#DROWS,d7
	blt.s	.r
.x	rts
.fail	move.w	(rd_count+2).l,(rd_vfail).l
	move.b	d7,(rd_vfail+2).l
	move.b	d5,(rd_vfail+3).l
	rts
	ENDC

;	Wait until the back buffer is off the screen for good: the frame after it (the next
;	buffer's) has been given to the display and a vertical blank has passed since, so the
;	copper shows that one. Its copper list is free then too. With 3 buffers it nearly always is.
;	Keeps all.
rd_vsync
	movem.l	d0-d1/a0,-(sp)
	move.w	(rd_bufi).l,d1
	addq.w	#1,d1
	cmpi.w	#NBUF,d1
	blo.s	.n
	moveq	#0,d1
.n	lsl.w	#2,d1
	lea	(rd_shownvb).l,a0
	PEV	'v'				;(statistics: waiting for a buffer, got it)
rd_spin_vs					;(the harness: the renderer waits here)
.w	move.l	(rd_vblanks).l,d0
	cmp.l	(a0,d1.w),d0
	ble.s	.w				;(signed: $7FFFFFFF is not yet)
	PEV	'V'
	movem.l	(sp)+,d0-d1/a0
	rts

;	Wait until the blits given to the copper are done: it has started them all (it stopped at
;	the ring's end, SOFT) and the blitter has finished. Keeps all.
rd_waitblit
	tst.b	(rd_cqbat).l			;(a batch open: let go first)
	beq.s	rd_wb_q
	bsr	rd_cq_flush
rd_wb_q	tst.b	(rd_cqidle).l			;nothing given to it since it stopped
	bne.s	rd_wb_blt
rd_spin_q
.q	btst	#2,(CUSTOM+$01F).l		;INTREQR SOFT
	beq	.q
	st	(rd_cqidle).l
rd_wb_blt
	btst	#6,(CUSTOM+DMACONR).l		;(first read is early on old chips)
rd_spin_w
.w	btst	#6,(CUSTOM+DMACONR).l
	bne	.w
	rts
rd_waitblit_end

;	------------------------------------------------------------------------------------------
;	Blit queue: the copper starts the blits. Each is written into a ring of copper code in chip
;	memory (rd_cqring) as a block: a wait for the blitter to finish, moves to the blitter's
;	registers (BLTSIZH last: the blit starts) and to COP2LCL (where a vertical blank's copper
;	restart resumes: every display list ends by jumping to COP2LC). So the CPU goes on with its
;	own work and takes no interrupt for a blit. A block moves only the registers its blit uses
;	(the hot ones, rd_restore and rd_spr_cut, write their blocks themselves: rd_cq_open,
;	rd_cq_close, constants where they can; the restores' BLTCON0 .. BLTALWM once for a run of
;	them, rd_cqkind).
;	After the last block the copper stops (a wait that never comes), setting INTREQ's SOFT bit
;	(no interrupt) first; the next block written there takes its place and, if SOFT says the
;	copper stopped, the CPU starts it again (COPJMP2). At a show marker (rd_show), once the
;	blits before it are done, the copper goes to the parking place, which stops it (DSKBLK)
;	and calls the level 3 interrupt (COPER): that sets the copper list when due (rd_showdue)
;	and starts the copper again after the marker. A vertical blank's restart while it waits
;	there comes back to it (COP2LC) and calls again: a call while DSKBLK is off is one left
;	over. The display lists clear SOFT and DSKBLK first: the CPU never takes a list's jump
;	for the copper (rd_cq_safe).
;	A block runs again if a vertical blank comes in the middle of it, which a blit allows (it
;	reads the same and writes the same again).
	IFND	RGAP
RGAP	equ	2				;rd_restore: runs this many columns apart are one blit
	ENDC
BQE	equ	$38				;the blit being written: laid out as the blitter's
						;registers $040-$077
CQSIZE	equ	16384				;the ring's bytes (a power of 2)
CQMAXB	equ	88				;a block's bytes at most after its first two moves
CQI	equ	CQSIZE+8			;the ring and the parking place
CQ_HALT	equ	$FFFF7FFE			;a wait that never comes (beam position $FF,$FE)
CQ_WBLT	equ	$00017FFE			;a wait for the blitter (and any beam position)

;	a6 = where to write a blit, as if it were the custom chips' base ($040(a6) ... $05E(a6),
;	BLTSIZH 0: a show marker, rd_show). Keeps all else.
rd_bq_alloc
rd_bq_allocq
	lea	(rd_bqe-$040).l,a6
	clr.w	$074(a6)			;BLTADAT: what a shift brings into the first word
	rts

;	A copper move (to a5) of register \1, the low word of \2; \3 a data register to use.
CQV	MACRO
	move.l	#\1<<16,\3
	move.w	\2,\3
	move.l	\3,(a5)+
	ENDM
;	The moves of pointer register \1 (high, low) from address register \2; \3 a data register
;	to use.
CQA	MACRO
	move.l	\2,\3
	clr.w	\3
	swap	\3
	ori.l	#\1<<16,\3
	move.l	\3,(a5)+
	move.l	#(\1+2)<<16,\3
	move.w	\2,\3
	move.l	\3,(a5)+
	ENDM

;	Open a block for the next blit: a6 = its place (the copper's stop now, or the ring's start:
;	its first two moves are written last, by rd_cq_close), a5 = where its moves go. Room for
;	the largest block (CQMAXB). Keeps all else.
rd_cq_open
	cmpi.w	#CQMAXB,(rd_cqfree).l
	blo.s	.slow
	movea.l	(rd_cqwp).l,a6
	lea	8(a6),a5
	rts
.slow	movem.l	d0-d2/a0,-(sp)
	movea.l	(rd_cqring).l,a0
rd_spin_full
.full	move.l	(rd_cqwp).l,d0
	sub.l	a0,d0				;the stop
	move.l	(rd_cqdp).l,d1
	sub.l	a0,d1				;(the copper has run what is before this)
	sub.w	d0,d1
	subq.w	#8,d1
	andi.w	#CQSIZE-1,d1			;bytes free after the stop
	move.w	#CQSIZE-8,d2
	sub.w	d0,d2				;those before the ring's end
	cmp.w	d2,d1
	bls.s	.t				;(the copper's place first)
	cmpi.w	#CQMAXB,d2
	bhs.s	.e
	sub.w	d2,d1				;the ring's end first, too near: from its start (the
	subq.w	#8,d1				;stop becomes a jump there, rd_cq_close)
	cmpi.w	#CQMAXB,d1
	blo.s	.wait
	move.l	(rd_cqwp).l,(rd_cqjmp).l
	move.w	d1,(rd_cqfree).l
	movea.l	a0,a6
	bra.s	.x
.e	move.w	d2,d1
.t	cmpi.w	#CQMAXB,d1
	blo.s	.wait
	move.w	d1,(rd_cqfree).l
	movea.l	(rd_cqwp).l,a6
.x	lea	8(a6),a5
	movem.l	(sp)+,d0-d2/a0
	rts
.wait	btst	#2,(CUSTOM+$01F).l		;SOFT: the copper waits at the stop, all have run
	beq.s	.full
	move.l	(rd_cqwp).l,(rd_cqdp).l
	bra.s	.full

;	Close the block opened (a6, its moves up to a5): its move to COP2LCL (the next block's place:
;	a vertical blank's restart goes on there) and the stop after it, then it is let go (its wait
;	for the blitter first, its first move last) and the copper started if it waits there.
;	Uses d0-d1, a0, a5.
rd_cq_close
	move.l	a5,d0
	addq.l	#4,d0
	swap	d0
	move.w	#$086,d0
	swap	d0
	move.l	d0,(a5)+			;COP2LCL
	move.l	#$009C8004,(a5)+		;the stop: INTREQ SOFT on,
	move.l	#CQ_HALT,(a5)			;and wait
	subq.l	#4,a5
	move.l	#CQ_WBLT,4(a6)
	move.l	#$009C0004,(a6)			;(INTREQ: SOFT off)
	move.l	(rd_cqjmp).l,d0			;the copper's stop before (it may wait there)
	bne.s	.j
	move.l	a6,d0
.c	move.l	a5,(rd_cqwp).l
	move.l	a5,d1
	sub.l	a6,d1
	sub.w	d1,(rd_cqfree).l
	sf	(rd_cqidle).l
	btst	#2,(CUSTOM+$01F).l		;SOFT: the copper waits there: start it
	bne.s	.kick
	rts
.j	movea.l	d0,a0				;(the block went to the ring's start: the stop before
	move.l	#$008A0000,4(a0)		;jumps there, COPJMP2 after
	move.l	(rd_cqjmv).l,(a0)		;COP2LCL)
	clr.l	(rd_cqjmp).l
	bra.s	.c
.kick	move	sr,-(sp)
	ori	#$0700,sr
	bsr	rd_cq_safe
	btst	#2,(CUSTOM+$01F).l		;(again: a vertical blank may have come)
	beq.s	.k1
	move.w	#$0004,(CUSTOM+INTREQ).l	;SOFT off
	move.w	d0,(CUSTOM+$08A).l		;COPJMP2: to the stop's place (COP2LC)
	move.l	d0,(rd_cqdp).l			;(what is before it has run)
	IFD	PROFILE
	addq.l	#1,(prof_mark+84).l		;(statistics: the copper started again)
	ENDC
.k1	move	(sp)+,sr
	rts

;	Batches: the blits of a pass (rd_restore's, the sprites') go to the copper CQBATCH at a time:
;	within a batch a blit takes only a move to COP2LCL and the next one's wait for the blitter
;	(not a stop, its replacing and a look at SOFT each). rd_cq_blit begins a blit's moves (a6,
;	a5 as rd_cq_open: the batch's place, where the moves go), rd_cq_endblit ends them (the batch
;	is let go when full), rd_cq_flush lets an open batch go (at a pass's end, before any other
;	blit or a wait for the blitter: the copper waits before a batch until it is let go).
CQBATCH	equ	4

rd_cq_blit
	IFD	PROFILE
	addq.l	#1,(prof_mark+80).l		;(statistics: blits)
	ENDC
	addq.b	#1,(rd_cqbat).l
	cmpi.b	#1,(rd_cqbat).l
	beq	rd_cq_open			;(the batch's first)
	movea.l	(rd_cqba6).l,a6
	movea.l	(rd_cqba5).l,a5
;	Between two blits of a batch: the move to COP2LCL (a vertical blank's restart goes on at
;	the next one) and the next one's wait for the blitter; room for one more largest block,
;	else the batch is let go and a new one begun. Keeps all but a5, a6.
rd_cq_next
	move.l	d0,-(sp)
	move.l	a5,d0
	sub.l	a6,d0
	addi.w	#CQMAXB,d0
	cmp.w	(rd_cqfree).l,d0
	bhi.s	.full
	move.l	a5,d0
	addq.l	#4,d0
	swap	d0
	move.w	#$086,d0
	swap	d0
	move.l	d0,(a5)+			;COP2LCL: the next blit's wait
	move.l	#CQ_WBLT,(a5)+
	move.l	(sp)+,d0
	rts
.full	movem.l	d1/a0,-(sp)
	bsr	rd_cq_close
	movem.l	(sp)+,d1/a0
	move.l	(sp)+,d0
	move.b	#1,(rd_cqbat).l
	bra	rd_cq_open

;	A blit's moves written (to a5): the batch let go if full. Uses d0-d1, a0, a5.
rd_cq_endblit
	cmpi.b	#CQBATCH,(rd_cqbat).l
	bhs.s	.c
	move.l	a5,(rd_cqba5).l
	move.l	a6,(rd_cqba6).l
	rts
.c	sf	(rd_cqbat).l
	bra	rd_cq_close

;	The batch open, if any, let go. Keeps all.
rd_cq_flush
	tst.b	(rd_cqbat).l
	bne.s	.f
	rts
.f	movem.l	d0-d1/a0/a5-a6,-(sp)
	sf	(rd_cqbat).l
	movea.l	(rd_cqba6).l,a6
	movea.l	(rd_cqba5).l,a5
	bsr	rd_cq_close
	movem.l	(sp)+,d0-d1/a0/a5-a6
	rts

;	The blit (or marker) from rd_bq_alloc goes to the copper: the moves of the registers it
;	uses. Keeps all.
rd_bq_go
	movem.l	d0-d1/d3/d7/a0-a1/a5-a6,-(sp)
	bsr	rd_cq_flush			;(after the batch open)
	lea	(rd_bqe).l,a0
	tst.w	$05E-$040(a0)
	beq	.mark
	IFD	PROFILE
	addq.l	#1,(prof_mark+80).l		;(statistics: blits)
	ENDC
	bsr	rd_cq_open
	sf	(rd_cqkind).l
	move.w	(a0),d3				;BLTCON0
	CQV	$040,d3,d7			;BLTCON0
	CQV	$042,$042-$040(a0),d7		;BLTCON1
	CQV	$044,$044-$040(a0),d7		;BLTAFWM
	CQV	$046,$046-$040(a0),d7		;BLTALWM
	btst	#11,d3
	beq.s	.na
	movea.l	$050-$040(a0),a1
	CQA	$050,a1,d7			;BLTAPT
	CQV	$064,$064-$040(a0),d7		;BLTAMOD
	cmpi.w	#$1000,d3
	blo.s	.nd				;(no shift: BLTADAT not used)
.na	CQV	$074,$074-$040(a0),d7		;BLTADAT
.nd	btst	#10,d3
	beq.s	.nb
	movea.l	$04C-$040(a0),a1
	CQA	$04C,a1,d7			;BLTBPT
	CQV	$062,$062-$040(a0),d7		;BLTBMOD
.nb	btst	#9,d3
	beq.s	.nc
	movea.l	$048-$040(a0),a1
	CQA	$048,a1,d7			;BLTCPT
	CQV	$060,$060-$040(a0),d7		;BLTCMOD
.nc	btst	#8,d3
	beq.s	.nn
	movea.l	$054-$040(a0),a1
	CQA	$054,a1,d7			;BLTDPT
	CQV	$066,$066-$040(a0),d7		;BLTDMOD
.nn	CQV	$05C,$05C-$040(a0),d7		;BLTSIZV (always: the blitter counts it down)
	CQV	$05E,$05E-$040(a0),d7		;BLTSIZH: it starts
	bsr	rd_cq_close
.x	movem.l	(sp)+,d0-d1/d3/d7/a0-a1/a5-a6
	rts
	; a show marker: once the blits before it are done the copper goes to the parking place
	; (COP2LCL first: a vertical blank's restart goes there too), which says it waits there
	; (DSKBLK) and calls (COPER). The level 3 interrupt (rd_cq_mark) takes its list and buffer
	; from rd_cqmq
.mark	bsr	rd_cq_open
	move.l	(rd_cqpmv).l,(a5)+		;COP2LCL: the parking place
	move.l	#$008A0000,(a5)+		;COPJMP2
	move.w	(rd_cqmt).l,d1
	lsl.w	#4,d1
	lea	(rd_cqmq).l,a0
	adda.w	d1,a0
	move.l	a6,(a0)+			;where it is
	lea	4(a5),a6
	move.l	a6,(a0)+			;where the copper goes on (the stop after it)
	lea	(rd_bqe).l,a6
	move.l	$048-$040(a6),(a0)+		;its copper list
	move.w	$04C-$040(a6),(a0)		;its buffer
	lsr.w	#4,d1
	addq.w	#1,d1
	andi.w	#7,d1
	move.w	d1,(rd_cqmt).l
	movea.l	-12(a0),a6			;(the block)
	bsr	rd_cq_close
	bra.s	.x

;	The blitter's registers are not what the copper left (a blit written straight into them).
;	Keeps all.
rd_cq_inval
	sf	(rd_cqkind).l
	rts

;	Start the copper again after a show marker (COP2LCL says where to) if it waits at the
;	marker or the parking place (DSKBLK). Not if it runs a display list: that ends by jumping to
;	COP2LC itself (unless it has just jumped to the parking place: a second look). Uses d0.
rd_cq_kickm
	move	sr,-(sp)
	ori	#$0700,sr
	bsr	rd_cq_safe
	btst	#1,(CUSTOM+$01F).l		;DSKBLK
	bne.s	.k
	moveq	#15,d0				;(a little later: 16 chip reads)
.d	tst.w	(CUSTOM+$006).l
	dbf	d0,.d
	btst	#1,(CUSTOM+$01F).l
	beq.s	.x
.k	move.w	#$0002,(CUSTOM+INTREQ).l	;DSKBLK off
	move.w	d0,(CUSTOM+$08A).l		;COPJMP2
	IFD	PROFILE
	addq.l	#1,(prof_mark+84).l		;(statistics: the copper started again)
	ENDC
.x	move	(sp)+,sr
	rts

;	Wait while a vertical blank's copper restart is near (the last line from H $A0, line 0 to
;	H $10): a look at the copper's state and a jump are not to straddle one (its display list
;	clears the state first). Interrupts off. Keeps all.
rd_cq_safe
	move.l	d0,-(sp)
.w	move.l	(CUSTOM+$004).l,d0		;VPOSR, VHPOSR: V8, V7-0, H
	andi.l	#$1FFFF,d0
	cmpi.w	#$0010,d0			;(line 0 or 256: the high word tells)
	bhs.s	.l
	swap	d0
	tst.w	d0
	beq.s	.w
	swap	d0
.l	tst.b	(hal_pal).l
	bne.s	.p
	cmpi.l	#$105A0,d0			;NTSC: line 261
	bhs.s	.w
	bra.s	.x
.p	cmpi.l	#$137A0,d0			;PAL: line 311
	bhs.s	.w
.x	move.l	(sp)+,d0
	rts

;	The copper stopped at the oldest show marker queued (or a vertical blank parked it): if
;	the show before it has been set, this one is the show waiting (rd_showdue sets it when
;	due) and the copper goes on after it; else it waits for that (rd_bqhold, the vertical
;	blank). Interrupts at level 3 or more. Uses d0-d1, a0-a1.
rd_cq_mark
	tst.l	(rd_showcop).l			;the show before still waits for its vertical blank
	bne.s	.hold
	move.w	(rd_cqmh).l,d0
	cmp.w	(rd_cqmt).l,d0
	beq.s	.x				;(none)
	lea	(rd_cqmq).l,a0
	move.w	d0,d1
	lsl.w	#4,d1
	adda.w	d1,a0
	addq.w	#1,d0
	andi.w	#7,d0
	move.w	d0,(rd_cqmh).l
	move.l	(a0)+,(rd_cqdp).l		;(what is before it has run)
	move.w	2(a0),(CUSTOM+$086).l		;COP2LCL: where the copper goes on
	addq.l	#4,a0
	move.l	(a0)+,(rd_showcop).l
	move.w	(a0),(rd_showbuf).l
	bsr	rd_showdue
	bra	rd_cq_kickm
.hold	st	(rd_bqhold).l
	PEV	'H'
.x	rts

;	The ring (in rd_cqbuf, within a 64K page, so only COP2LCL changes), the copper stopped at
;	its start. Uses d0-d1/a0.
rd_cq_init
	lea	(rd_cqbuf).l,a0
	move.l	a0,d0
	move.l	a0,d1
	addi.l	#CQI-1,d1
	swap	d0
	swap	d1
	cmp.w	d0,d1
	beq.s	.pg
	swap	d1				;(across a page: from the next page on)
	clr.w	d1
	movea.l	d1,a0
.pg	move.l	a0,(rd_cqring).l
	move.l	#$009C8004,(a0)			;INTREQ: SOFT on,
	move.l	#CQ_HALT,4(a0)			;and stop
	move.l	a0,d0				;a move of the start to COP2LCL
	swap	d0
	move.w	#$086,d0
	swap	d0
	move.l	d0,(rd_cqjmv).l
	lea	CQSIZE(a0),a0			;the parking place
	move.l	a0,d0
	swap	d0
	move.w	#$086,d0
	swap	d0
	move.l	d0,(rd_cqpmv).l			;(a move of it to COP2LCL)
	move.l	#$009C8012,(a0)+		;DSKBLK, COPER on
	move.l	#CQ_HALT,(a0)+
	move.l	(rd_cqring).l,(rd_cqwp).l
	move.l	(rd_cqring).l,(rd_cqdp).l
	move.w	#CQSIZE-8,(rd_cqfree).l
	clr.l	(rd_cqjmp).l
	clr.w	(rd_cqmh).l
	clr.w	(rd_cqmt).l
	st	(rd_cqidle).l
	bsr	rd_cq_inval
	move.w	#$0002,(CUSTOM+$02E).l		;COPCON: CDANG (the copper may write the blitter)
	move.l	(rd_cqring).l,(CUSTOM+$084).l	;COP2LC
	move.w	#$0016,(CUSTOM+INTREQ).l	;(SOFT, DSKBLK, COPER off)
	rts

;	The show waiting (rd_showcop), if it is due: each frame stays on the screen hal_pace
;	vertical blanks at least. Its copper list is set (from the next frame on), its buffer's rd_shownvb
;	noted. Interrupts off. Uses d0, a1.
rd_showdue
	tst.l	(rd_showcop).l
	beq	.x
	move.l	(rd_vblanks).l,d0
	sub.l	(rd_lastset).l,d0
	sub.l	(hal_pace).l,d0
	bmi	.x
	IFD	PROFILE
	add.l	(hal_pace).l,d0			;(statistics: vertical blanks the frame before was
	subq.l	#1,d0				;shown for)
	cmpi.l	#7,d0
	bls.s	.h
	moveq	#7,d0
.h	lea	(prof_mark+20).l,a1
	addq.l	#1,(a1,d0.l*4)
	ENDC
	move.l	(rd_vblanks).l,(rd_lastset).l
	PEV	'C'				;(statistics: a copper list set)
	move.l	(rd_showcop).l,(CUSTOM+$080).l	;COP1LC
	clr.l	(rd_showcop).l
	move.w	(rd_showbuf).l,d0
	lsl.w	#2,d0
	lea	(rd_shownvb).l,a1
	move.l	(rd_vblanks).l,(a1,d0.w)
	; its delay: vertical blanks from its game state (rd_snaptime) to its showing (from the
	; next frame on). The sound waits as long (snd_delay: the mean, to within 3/4 frame)
	move.l	d1,-(sp)
	lea	(rd_snapvb).l,a1
	move.l	(rd_vblanks).l,d1
	sub.l	(a1,d0.w),d1
	addq.l	#1,d1
	cmpi.l	#6,d1
	bls.s	.l6
	moveq	#6,d1
.l6
	IFD	PROFILE
	lea	(prof_mark+52).l,a1		;(statistics)
	addq.l	#1,(a1,d1.w*4)
	ENDC
	lsl.w	#8,d1
	sub.w	(snd_latf).l,d1
	asr.w	#3,d1
	add.w	d1,(snd_latf).l
	move.w	(snd_delay).l,d1
	lsl.w	#8,d1
	sub.w	(snd_latf).l,d1
	bpl.s	.lp
	neg.w	d1
.lp	cmpi.w	#192,d1
	blo.s	.lk
	move.w	(snd_latf).l,d1
	addi.w	#128,d1
	lsr.w	#8,d1
	move.w	d1,(snd_delay).l
.lk	move.l	(sp)+,d1
.x	rts

;	The back buffer's game state is taken now (rd_showdue: the picture's delay). Keeps all.
rd_snaptime
	movem.l	d0/a0,-(sp)
	move.w	(rd_bufi).l,d0
	lea	(rd_snapvb).l,a0
	move.l	(rd_vblanks).l,(a0,d0.w*4)
	movem.l	(sp)+,d0/a0
	rts

;	Level 3: the copper at a show marker (COPER: rd_cq_mark), or a vertical blank (counted:
;	rd_vsync).
rd_bq_int
	movem.l	d0-d1/a0-a1,-(sp)
	IFD	PROFILE
	addq.l	#1,(prof_mark+88).l		;(statistics: level 3 interrupts)
	ENDC
	move.w	(CUSTOM+$01E).l,-(sp)		;INTREQR
	btst	#4,1(sp)
	beq.s	.nm
	move.w	#$0010,(CUSTOM+INTREQ).l
	move.w	#$0010,(CUSTOM+INTREQ).l
	btst	#1,(CUSTOM+$01F).l		;(DSKBLK: it waits there; else a call left over from
	beq.s	.nm				;a vertical blank's restart: the copper went on)
	PEV	'M'				;(statistics: the copper at a show)
	bsr	rd_cq_mark
.nm	btst	#5,1(sp)
	beq.s	.x
	move.w	#$0020,(CUSTOM+INTREQ).l
	move.w	#$0020,(CUSTOM+INTREQ).l
	PEV	'B'				;(statistics: a vertical blank)
	addq.l	#1,(rd_vblanks).l
	tst.b	(hal_vbtick).l
	beq.s	.nt
	st	(hal_vbreq).l
	move.w	#$A000,(CUSTOM+INTREQ).l	;the game's tick (level 6)
.nt	bsr	rd_showdue
	tst.b	(rd_bqhold).l
	beq.s	.x
	tst.l	(rd_showcop).l
	bne.s	.x
	sf	(rd_bqhold).l			;the copper goes on with the next show
	bsr	rd_cq_mark
.x	addq.l	#2,sp
	movem.l	(sp)+,d0-d1/a0-a1
	tst.b	(hal_swpend).l			;a game tick came in a handler: switch now, unless
	bne.s	.sw				;this one interrupted a handler too
	rte
.sw	btst	#2,(sp)
	bne.s	.r
	btst	#1,(sp)
	bne.s	.r
	btst	#0,(sp)
	bne.s	.r
	sf	(hal_swpend).l
	tst.b	(ctx_cur).l
	bne	ctx_to_game
.r	rte
;	------------------------------------------------------------------------------------------
;	Can the name table at VRAM d0 (32 byte aligned), d1 bytes long, have changed since it was
;	last compared with its copy? Only if a DMA, fill or copy changed its blocks (tc_chg) or a
;	data port write began in one (vdp_wmap: cleared here), or the copies are not in step
;	(rd_ntsync). d0.b = $FF if so, else 0 (and the flags). Uses d0-d4/a0-a1.
rd_ntwritten
	lsr.l	#5,d0				;first block
	moveq	#31,d2
	add.l	d2,d1
	lsr.l	#5,d1				;blocks
	moveq	#0,d2
	lea	(vdp_wmap).l,a0
	lea	(tc_chg).l,a1
	move	sr,-(sp)
	ori	#$0700,sr			;(the game sets vdp_wmap bits)
.l	moveq	#32,d3
	cmp.l	d3,d1
	bhs.s	.w
	move.l	d1,d3
.w	bfextu	(a0){d0:d3},d4
	or.l	d4,d2
	IFD	STATS
	beq.s	.s1
	addq.l	#1,(rd_dbg_x+32).l
	move.l	d0,(rd_dbg_x+36).l
.s1
	ENDC
	bfclr	(a0){d0:d3}
	bfextu	(a1){d0:d3},d4
	or.l	d4,d2
	IFD	STATS
	tst.l	d4
	beq.s	.s2
	addq.l	#1,(rd_dbg_x+24).l
	move.l	d0,(rd_dbg_x+28).l
.s2
	ENDC
	add.l	d3,d0
	sub.l	d3,d1
	bne.s	.l
	move	(sp)+,sr
	tst.b	(rd_ntsync).l
	seq	d0
	tst.l	d2
	sne	d1
	or.b	d1,d0
	rts

	IFD	VERIFY
;	Debug: a name table changed that rd_ntwritten said could not have (d0 = 1 plane B, 2 plane
;	A, 3 window): rd_vfail = frame, $FE, d0 (once).
rd_ntfail
	tst.l	(rd_vfail).l
	bne.s	.x
	move.w	(rd_count+2).l,(rd_vfail).l
	move.b	#$FE,(rd_vfail+2).l
	move.b	d0,(rd_vfail+3).l
.x	rts
	ENDC

;	Bring the plane B bitmap up to date with the name table and the tiles.
rd_updateB
	lea	(rd_regs).l,a5
	bsr	rd_planesize
	move.w	d0,(rd_cw).l
	move.w	d1,(rd_ch).l
	moveq	#0,d2
	move.b	4(a5),d2
	andi.w	#7,d2
	lsl.l	#8,d2
	lsl.l	#5,d2				;name table address
	lea	(vdp_vram).l,a0
	adda.l	d2,a0				;a0 = name table
	movem.l	d0-d2/a0,-(sp)
	mulu.w	d0,d1
	add.l	d1,d1
	move.l	d2,d0
	bsr	rd_ntwritten
	move.b	d0,(rd_ntcur).l			;written since last time?
	movem.l	(sp)+,d0-d2/a0
	swap	d2
	move.w	d0,d2
	lsl.w	#8,d2
	or.b	d1,d2				;key = base, size
	moveq	#0,d6				;0 = only changed cells
	cmp.l	(rd_Bkey).l,d2
	beq	.same
	move.l	d2,(rd_Bkey).l
	moveq	#1,d6				;redraw everything
	lea	(rd_bused).l,a1
	moveq	#63,d3
.cu	clr.l	(a1)+
	dbf	d3,.cu
	lea	(rd_mkset).l,a1			;(the cells are others: all masks written)
	moveq	#BMAX/32-1,d3
.cm	move.l	#-1,(a1)+
	dbf	d3,.cm
	lea	(rd_tlhead).l,a1		;(and the tiles' lists of cells)
	move.w	#2048/2-1,d3
.ch	clr.l	(a1)+
	dbf	d3,.ch
	lea	(rd_tltile).l,a1
	move.w	#BMAX/2-1,d3
.ct	clr.l	(a1)+
	dbf	d3,.ct
.same	; were any tiles of plane B converted again?
	lea	(tc_chg).l,a1
	lea	(rd_bused).l,a2
	moveq	#0,d3
	moveq	#63,d4
.tu	move.l	(a1)+,d5
	and.l	(a2)+,d5
	or.l	d5,d3
	dbf	d4,.tu
	move.l	d3,(rd_btchg).l
	IFD	STATS
	beq.s	.st0
	addq.l	#1,(rd_dbg_x+0).l
.st0
	ENDC
	clr.w	(rd_hiBok).l
	move.w	d0,d7
	mulu.w	d1,d7
	subq.w	#1,d7				;cells - 1
	lea	(shB).l,a1
	lea	(tc_chg).l,a2
	moveq	#0,d4				;cell column
	moveq	#0,d5				;cell row
	move.w	#-1,(rd_hiBok).l		;unchanged unless a cell is redrawn
	tst.w	d6
	bne	.cell
	; changed entries, if the name table was written to: found quickly as changed longs; then
	; the cells of the tiles converted again (rd_btiles)
	IFND	VERIFY
	tst.b	(rd_ntcur).l
	beq	.fdone
	ENDC
	move.l	a0,(rd_tmp).l			;name table start
	addq.w	#1,d7
	lsr.w	#1,d7
	subq.w	#1,d7				;longs - 1
.f	cmpm.l	(a0)+,(a1)+
	dbne	d7,.f
	beq	.fdone
	; long at a0-4 differs: its two cells
	movem.l	d7/a0-a1,-(sp)
	move.l	a0,d0
	sub.l	(rd_tmp).l,d0
	subq.l	#4,d0
	lsr.l	#1,d0				;first cell
	moveq	#1,d3
.fc	movem.l	d0/d3,-(sp)
	lea	(shB).l,a1
	movea.l	(rd_tmp).l,a0
	move.w	(a0,d0.l*2),d1			;entry
	cmp.w	(a1,d0.l*2),d1
	beq	.fn
	move.w	d1,(a1,d0.l*2)
	clr.w	(rd_hiBok).l
	IFD	VERIFY
	tst.b	(rd_ntcur).l
	bne.s	.vok
	move.l	d0,-(sp)
	moveq	#1,d0
	bsr	rd_ntfail
	move.l	(sp)+,d0
.vok
	ENDC
	moveq	#0,d4
	move.w	d0,d4
	divu.w	(rd_cw).l,d4
	move.l	d4,d5
	swap	d4				;column
	move.w	d1,d0
	bsr	rd_cellB
.fn	movem.l	(sp)+,d0/d3
	addq.l	#1,d0
	dbf	d3,.fc
	movem.l	(sp)+,d7/a0-a1
	dbf	d7,.f
.fdone	tst.l	(rd_btchg).l
	beq.s	.fd2
	bsr	rd_btiles
.fd2	tst.w	(rd_hiBok).l
	bne	.x
	cmpi.w	#64,(rd_cw).l
	beq	.x				;(rd_cellB keeps rd_hibits; the list is not used)
	bra	rd_list_hiB
.cell	move.w	(a0)+,d0
	tst.w	d6
	bne	.draw
	cmp.w	(a1),d0
	bne	.draw
	tst.l	(rd_btchg).l
	beq	.next
	move.w	d0,d1
	andi.l	#$7FF,d1
	bftst	(a2){d1:1}
	beq	.next
.draw	move.w	d0,(a1)
	clr.w	(rd_hiBok).l
	movem.l	d4-d7/a0-a2,-(sp)
	bsr	rd_cellB
	movem.l	(sp)+,d4-d7/a0-a2
.next	addq.l	#2,a1
	addq.w	#1,d4
	cmp.w	(rd_cw).l,d4
	bne	.nc
	moveq	#0,d4
	addq.w	#1,d5
.nc	dbf	d7,.cell
	tst.w	(rd_hiBok).l
	bne	.x
	cmpi.w	#64,(rd_cw).l
	beq	.x
	bsr	rd_list_hiB
.x	rts

;	The cells of plane B whose tile was converted again (tc_chg and rd_bused) drawn again,
;	found through the tile's list of cells (rd_tlhead, kept by rd_cellB). Keeps everything.
rd_btiles
	movem.l	d0-d7/a0-a6,-(sp)
	lea	(tc_chg).l,a3
	lea	(rd_bused).l,a4
	moveq	#0,d7				;the tile of the long's bit 31
.l	move.l	(a3)+,d6
	and.l	(a4)+,d6
	beq.s	.nl
.b	bfffo	d6{0:0},d1
	bfclr	d6{d1:1}
	add.w	d7,d1				;a tile
	lea	(rd_tlhead).l,a0
	move.w	(a0,d1.w*2),d2			;its first cell + 1
.c	subq.w	#1,d2
	bmi.s	.nt
	lea	(rd_tlnext).l,a0
	move.w	(a0,d2.w*2),d3			;(the next + 1)
	lea	(shB).l,a0
	move.w	(a0,d2.w*2),d0			;its entry
	moveq	#0,d4
	move.w	d2,d4
	divu.w	(rd_cw).l,d4
	move.l	d4,d5
	swap	d4				;column
	movem.l	d3/d6-d7/a3-a4,-(sp)
	bsr	rd_cellB
	movem.l	(sp)+,d3/d6-d7/a3-a4
	move.w	d3,d2
	bra.s	.c
.nt	tst.l	d6
	bne.s	.b
.nl	addi.w	#32,d7
	cmpi.w	#2048,d7
	blo.s	.l
	clr.w	(rd_hiBok).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	Draw entry d0 at cell d4 (column), d5 (row) of the plane B bitmap. The blits of the frame
;	before may still read the bitmap: they are let finish first.
rd_cellB
	IFD	STATS
	addq.l	#1,(rd_dbg_x+4).l
	ENDC
	bsr	rd_waitblit
	; all buffers are to be mended there (scroll mode: rows 0-27 are in a buffer twice)
	moveq	#0,d1				;(bit field offsets are longs)
	move.w	d4,d1
	lsr.w	#1,d1
	andi.w	#31,d1				;16 pixel column
	moveq	#31,d2
	and.w	d5,d2
	lea	(rd_dirty).l,a1
	IFNE	3-DLS
	lsl.w	#3-DLS,d2			;(its first map row)
	ENDC
	lea	(a1,d2.w*4),a1
	moveq	#(8>>DLS)-1,d3
.mr	bfset	(a1){d1:1}
	bfset	DROWS*4(a1){d1:1}
	bfset	2*DROWS*4(a1){d1:1}
	cmpi.w	#DROWS-DWRAP,d2
	bhs.s	.once
	bfset	DWRAP*4(a1){d1:1}
	bfset	(DROWS+DWRAP)*4(a1){d1:1}
	bfset	(2*DROWS+DWRAP)*4(a1){d1:1}
.once	addq.l	#4,a1
	addq.w	#1,d2
	dbf	d3,.mr
	move.l	a4,-(sp)
	move.w	d0,(rd_cellpri).l		;bit 15: high priority
	move.w	d0,d1
	andi.l	#$7FF,d1
	lea	(rd_bused).l,a1
	bfset	(a1){d1:1}
	TNEED	d1
	; its bit in rd_hibits (rd_fixups): high priority, and the tile not empty
	movem.l	d1-d2,-(sp)
	move.w	d5,d1
	mulu.w	(rd_cw).l,d1
	moveq	#0,d2
	move.w	d4,d2
	add.l	d2,d1
	lea	(rd_hibits).l,a1
	bfclr	(a1){d1:1}
	sf	(rd_cellmk).l
	tst.w	d0
	bpl.s	.lo
	move.w	d0,d2
	andi.w	#$FFF,d2
	lea	(tp_cls).l,a1
	tst.b	(a1,d2.w)
	beq.s	.lo
	lea	(rd_hibits).l,a1
	bfset	(a1){d1:1}
	st	(rd_cellmk).l			;(it has a mask)
.lo	; its masks are written if it has one or had one (rd_mkset); else they are all 0 already
	lea	(rd_mkset).l,a1
	tst.b	(rd_cellmk).l
	beq.s	.m0
	bfset	(a1){d1:1}
	st	(rd_cellmw).l
	bra.s	.m1
.m0	bfclr	(a1){d1:1}
	sne	(rd_cellmw).l
.m1	; the cell in its tile's list (rd_btiles)
	movem.l	d0/d3/a0,-(sp)
	andi.w	#$7FF,d0
	addq.w	#1,d0				;its tile + 1
	lea	(rd_tltile).l,a0
	move.w	(a0,d1.w*2),d2
	cmp.w	d2,d0
	beq.s	.tk				;(there already)
	move.w	d0,(a0,d1.w*2)
	tst.w	d2
	beq.s	.ti
	; out of the old tile's list
	lea	(rd_tlprev).l,a0
	move.w	(a0,d1.w*2),d3			;the one before + 1
	lea	(rd_tlnext).l,a1
	move.w	(a1,d1.w*2),d0			;the next + 1
	tst.w	d3
	beq.s	.th
	move.w	d0,-2(a1,d3.w*2)		;(next of the one before)
	bra.s	.tp
.th	lea	(rd_tlhead).l,a1
	move.w	d0,-2(a1,d2.w*2)		;(the old tile's first)
.tp	tst.w	d0
	beq.s	.tn
	move.w	d3,-2(a0,d0.w*2)		;(the one before of the next)
.tn	lea	(rd_tltile).l,a0
	move.w	(a0,d1.w*2),d0			;(the tile + 1 again)
.ti	; at the front of the new tile's list
	lea	(rd_tlhead).l,a0
	move.w	-2(a0,d0.w*2),d3		;its first + 1
	move.w	d1,d2
	addq.w	#1,d2				;this cell + 1
	move.w	d2,-2(a0,d0.w*2)
	lea	(rd_tlnext).l,a0
	move.w	d3,(a0,d1.w*2)
	lea	(rd_tlprev).l,a0
	clr.w	(a0,d1.w*2)
	tst.w	d3
	beq.s	.tk
	move.w	d2,-2(a0,d3.w*2)
.tk	movem.l	(sp)+,d0/d3/a0
	movem.l	(sp)+,d1-d2
	move.w	(rd_cw).l,d1			;bytes per plane row
	move.w	d1,d2
	mulu.w	#6,d2				;bytes per pixel row
	move.w	d5,d3
	lsl.w	#3,d3
	mulu.w	d3,d2
	lea	(bmB).l,a1
	adda.l	d2,a1
	adda.w	d4,a1				;a1 = cell, plane 0, row 0
	movea.l	a1,a4
	adda.l	#mkB6-bmB,a4			;a4 = its mask in the bitmap's layout
	lea	(mkB).l,a3
	move.w	d5,d3
	lsl.w	#3,d3
	mulu.w	d1,d3
	adda.l	d3,a3
	adda.w	d4,a3				;a3 = mask
	move.w	d0,d3
	andi.l	#$FFF,d3
	lea	(tp_pl).l,a0
	move.l	d3,d2
	lsl.l	#5,d2
	adda.l	d2,a0				;planes
	lea	(tp_mk).l,a2
	lsl.l	#3,d3
	adda.l	d3,a2				;masks
	moveq	#4,d5				;row step in the cache
	moveq	#1,d4
	btst	#12,d0
	beq	.nv
	lea	28(a0),a0			;vertical flip: last row first
	addq.l	#7,a2
	moveq	#-4,d5
	moveq	#-1,d4
.nv	moveq	#0,d6				;palette planes
	btst	#13,d0
	beq	.p0
	move.b	#$FF,d6
.p0	moveq	#0,d7
	btst	#14,d0
	beq	.p1
	move.b	#$FF,d7
.p1	moveq	#7,d3
	move.w	d1,d2
	mulu.w	#6,d2				;bytes from one pixel row to the next
	movem.l	a5-a6,-(sp)
	move.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0				;3 plane rows on
	lea	(a1,d0.w),a5			;planes 3-5 (a1: 0-2)
	tst.b	(rd_cellmw).l
	beq	.rown
	lea	(a4,d0.w),a6			;the mask's 3-5 (a4: 0-2)
	tst.w	(rd_cellpri).l
	bmi.s	.row
	lea	(rd_zero8).l,a2			;(low priority: no mask)
	moveq	#0,d4
.row	move.b	(a0),(a1)			;(the cache's row: the plane bytes p0 p1 p2 p3)
	move.b	1(a0),(a1,d1.w)
	move.b	2(a0),(a1,d1.w*2)
	move.b	3(a0),(a5)
	move.b	d6,(a5,d1.w)
	move.b	d7,(a5,d1.w*2)
	adda.w	d5,a0
	adda.w	d2,a1
	adda.w	d2,a5
	move.b	(a2),d0				;the high priority mask: for the CPU, and in each plane's
	adda.w	d4,a2				;place for the blitter
	move.b	d0,(a3)
	adda.w	d1,a3
	move.b	d0,(a4)
	move.b	d0,(a4,d1.w)
	move.b	d0,(a4,d1.w*2)
	move.b	d0,(a6)
	move.b	d0,(a6,d1.w)
	move.b	d0,(a6,d1.w*2)
	adda.w	d2,a4
	adda.w	d2,a6
	dbf	d3,.row
	movem.l	(sp)+,a5-a6
	movea.l	(sp)+,a4
	rts
.rown	move.b	(a0),(a1)			;(no masks to write)
	move.b	1(a0),(a1,d1.w)
	move.b	2(a0),(a1,d1.w*2)
	move.b	3(a0),(a5)
	move.b	d6,(a5,d1.w)
	move.b	d7,(a5,d1.w*2)
	adda.w	d5,a0
	adda.w	d2,a1
	adda.w	d2,a5
	dbf	d3,.rown
	movem.l	(sp)+,a5-a6
	movea.l	(sp)+,a4
	rts

;	List the high priority cells of plane B (for the fixups).
rd_list_hiB
	IFD	STATS
	addq.l	#1,(rd_dbg_x+8).l
	ENDC
	lea	(rd_hibits).l,a1
	moveq	#BMAX/32-1,d0
.cb	clr.l	(a1)+
	dbf	d0,.cb
	lea	(shB).l,a0
	lea	(rd_hiB).l,a1
	lea	(rd_hibits).l,a2
	lea	(tp_cls).l,a3
	move.w	(rd_cw).l,d6
	move.w	(rd_ch).l,d7
	moveq	#0,d5				;row
	moveq	#0,d3				;count
	moveq	#0,d2				;cell (bit in rd_hibits)
.r	moveq	#0,d4
.c	move.w	(a0)+,d0
	bpl	.n
	andi.w	#$FFF,d0
	tst.b	(a3,d0.w)
	beq	.n				;(an empty tile: nothing in front)
	move.w	d4,(a1)+
	move.w	d5,(a1)+
	addq.w	#1,d3
	bfset	(a2){d2:1}
.n	addq.l	#1,d2
	addq.w	#1,d4
	cmp.w	d6,d4
	bne	.c
	addq.w	#1,d5
	cmp.w	d7,d5
	bne	.r
	move.w	d3,(rd_hiBn).l
	move.w	#1,(rd_hiBok).l
	rts

;	------------------------------------------------------------------------------------------
;	Plane B's scroll position (rd_bx0, rd_by0: the plane pixel at screen 0, 0) and where the
;	screen is in the back buffer. Scroll mode when the plane is 64 x 32 cells and the screen's
;	columns do not wrap around its right edge: then the buffer holds the plane (column x at bit
;	x + 32, row y at rows y and y + 256) and the screen is the window on it at the scroll
;	position.
rd_scrollpos
	move.w	(rd_hs+2).l,d0			;B hscroll
	neg.w	d0
	move.w	(rd_cw).l,d3
	lsl.w	#3,d3
	subq.w	#1,d3				;plane width - 1
	and.w	d3,d0				;plane x at Genesis screen x 0
	move.w	(rd_vs+2).l,d1
	move.w	(rd_ch).l,d2
	lsl.w	#3,d2
	subq.w	#1,d2
	and.w	d2,d1
	move.w	d1,(rd_by0).l			;plane y at screen y 0
	cmpi.w	#64,(rd_cw).l
	bne	.copy
	cmpi.w	#32,(rd_ch).l
	bne	.copy
	move.w	#512,d1				;the last start that keeps the screen's columns in the
	sub.w	(rd_w).l,d1			;plane
	cmp.w	d1,d0
	bhi	.copy
	move.w	d0,(rd_bx0).l
	move.w	#1,(rd_scroll).l
	addi.w	#SCRX*8,d0
	move.w	d0,(rd_xorg).l
	move.w	(rd_by0).l,d1
	move.w	d1,(rd_brow0).l
	mulu.w	#SROW,d1
	add.l	(rd_buf).l,d1
	move.l	d1,(rd_back).l
	rts
.copy	move.w	d0,(rd_bx0).l
	clr.w	(rd_scroll).l
	move.w	#SCRX*8,(rd_xorg).l
	clr.w	(rd_brow0).l
	move.l	(rd_buf).l,(rd_back).l
	rts

;	Scroll mode: blit the parts of the back buffer its dirty map names back from the plane B
;	bitmap. A blit per run of columns, for all the following rows with the same columns.
rd_restore
	movea.l	(rd_dmap).l,a2
	moveq	#0,d7				;row
.row	move.l	(a2,d7.w*4),d6
	bne.s	.dirty
	addq.w	#1,d7
	cmpi.w	#DROWS,d7
	blt.s	.row
	rts
.dirty	move.w	d7,d5				;first row
.same	clr.l	(a2,d7.w*4)
	addq.w	#1,d7
	cmpi.w	#DROWS,d7
	bge.s	.grp
	moveq	#DWRAP-1,d0
	and.w	d7,d0
	beq.s	.grp				;(the bitmap's rows wrap there)
	cmp.l	(a2,d7.w*4),d6
	beq.s	.same
.grp	; rows d5 .. d7-1, the columns of d6: the runs
	IFD	STATS
	addq.l	#1,(rd_dbg_x+68).l		;(statistics: groups of rows)
	ENDC
.run	bfffo	d6{0:0},d1			;first column
	move.l	d6,d2
	lsl.l	d1,d2
	not.l	d2
	bfffo	d2{0:0},d3			;columns
	bfclr	d6{d1:d3}
.ext	; the next run, if at most RGAP columns on: the same blit (the columns between are the
	; bitmap's already; a blit costs more than the words)
	tst.l	d6
	beq.s	.blit
	bfffo	d6{0:0},d0			;its first column
	move.w	d0,d2
	sub.w	d1,d2
	sub.w	d3,d2				;columns between
	cmpi.w	#RGAP,d2
	bhi.s	.blit
	move.l	d6,d2
	lsl.l	d0,d2
	not.l	d2
	bfffo	d2{0:0},d4			;its columns
	bfclr	d6{d0:d4}
	add.w	d0,d4
	sub.w	d1,d4
	move.w	d4,d3				;to its last
	bra.s	.ext
.blit	bsr	rd_cq_blit			;the copper block
	cmpi.b	#1,(rd_cqkind).l
	beq.s	.k
	move.l	#$004009F0,(a5)+		;BLTCON0: A to D (once for the restores in a row)
	move.l	#$00420000,(a5)+		;BLTCON1
	move.l	#$0044FFFF,(a5)+		;BLTAFWM
	move.l	#$0046FFFF,(a5)+		;BLTALWM
	move.b	#1,(rd_cqkind).l
.k	move.w	d5,d0
	andi.w	#DWRAP-1,d0
	mulu.w	#DLH*64*6,d0			;the bitmap: 64 cells, 6 planes a line
	lea	(bmB).l,a0
	adda.l	d0,a0
	lea	(a0,d1.w*2),a0
	CQA	$050,a0,d4			;BLTAPT
	move.w	d5,d0
	mulu.w	#DLH*SROW,d0
	movea.l	(rd_buf).l,a0
	adda.l	d0,a0
	lea	SCRX(a0,d1.w*2),a0
	CQA	$054,a0,d4			;BLTDPT
	add.w	d3,d3				;bytes
	moveq	#64,d0
	sub.w	d3,d0
	CQV	$064,d0,d4			;BLTAMOD
	moveq	#SBPR,d0
	sub.w	d3,d0
	CQV	$066,d0,d4			;BLTDMOD
	move.w	d7,d0
	sub.w	d5,d0
	mulu.w	#DLH*NPLANES,d0
	CQV	$05C,d0,d4			;BLTSIZV
	lsr.w	#1,d3
	CQV	$05E,d3,d4			;BLTSIZH
	IFD	STATS
	mulu.w	d3,d0
	add.l	d0,(rd_dbg_x+52).l		;(statistics: words restored and blits)
	addq.l	#1,(rd_dbg_x+48).l
	ENDC
	bsr	rd_cq_endblit
	tst.l	d6
	bne	.run
	cmpi.w	#DROWS,d7
	blt	.row
	bra	rd_cq_flush

;	Note the rectangle d0 (x), d1 (y), d2 (w), d3 (h) on the screen as drawn over in the back
;	buffer's dirty map. Keeps everything (rd_mark_u: uses d0-d3/a0).
rd_mark
	movem.l	d0-d3/a0,-(sp)
	bsr.s	rd_mark_u
	movem.l	(sp)+,d0-d3/a0
	rts
rd_mark_u
	tst.w	d2
	ble.s	.x
	tst.w	d3
	ble.s	.x
	add.w	(rd_xorg).l,d0
	subi.w	#SCRX*8,d0			;plane x
	add.w	d0,d2
	subq.w	#1,d2
	asr.w	#4,d0				;first column (16 pixels)
	bpl.s	.1
	moveq	#0,d0
.1	asr.w	#4,d2				;last
	cmpi.w	#31,d2
	ble.s	.2
	moveq	#31,d2
.2	sub.w	d0,d2
	bmi.s	.x
	addq.w	#1,d2				;columns (32 is coded as 0)
	add.w	(rd_brow0).l,d1
	add.w	d1,d3
	subq.w	#1,d3
	asr.w	#DLS,d1				;first row
	bpl.s	.3
	moveq	#0,d1
.3	asr.w	#DLS,d3
	cmpi.w	#DROWS-1,d3
	ble.s	.4
	moveq	#DROWS-1,d3
.4	sub.w	d1,d3
	bmi.s	.x
	ext.l	d0				;(a bit field offset is a long)
	movea.l	(rd_dmap).l,a0
	lea	(a0,d1.w*4),a0
.r	bfset	(a0){d0:d2}
	addq.l	#4,a0
	dbf	d3,.r
.x	rts

;	------------------------------------------------------------------------------------------
;	Copy plane B to the back buffer at its scroll position (blitter). The bitmap wraps, so up
;	to 4 rectangles.
rd_blitB
	; vertical pieces: [by0, min(H, by0+224)) then from 0
	move.w	(rd_ch).l,d6
	lsl.w	#3,d6				;plane height
	moveq	#0,d5				;screen y
	move.w	(rd_by0).l,d4			;plane y
.vp	move.w	d6,d3
	sub.w	d4,d3				;lines left in the plane
	move.w	#SCRH,d2
	sub.w	d5,d2				;lines left on screen
	cmp.w	d2,d3
	ble	.vh
	move.w	d2,d3
.vh	; d3 lines from plane y d4 to screen y d5: horizontal pieces, the wrapped one first
	movem.w	d3-d6,-(sp)
	move.w	(rd_cw).l,d0
	lsl.w	#3,d0				;plane width
	move.w	(rd_bx0).l,d1
	sub.w	d1,d0				;pixels to the right edge
	move.w	(rd_w).l,d2
	cmp.w	d2,d0
	bge	.one
	; two pieces: [bx0, W) at screen 0, then [0, w-(W-bx0)) at screen W-bx0
	movem.w	d0-d2,-(sp)
	move.w	d0,d7				;screen x of the second piece
	moveq	#0,d1				;plane x 0
	sub.w	d0,d2				;width
	st	(rd_blitnoc).l			;its first word is drawn over by the next piece
	bsr	rd_blitrect			;d1 plane x, d2 width, d3 lines, d4 plane y, d5 screen y,
						;d7 screen x
	movem.w	(sp)+,d0-d2
	move.w	d0,d2
	moveq	#0,d7
	sf	(rd_blitnoc).l			;its last word holds the other piece's first pixels
	bsr	rd_blitrect
	bra	.hd
.one	moveq	#0,d7
	st	(rd_blitnoc).l			;whole width: the edges are margin
	bsr	rd_blitrect
.hd	movem.w	(sp)+,d3-d6
	add.w	d3,d5
	moveq	#0,d4				;wrapped to the top
	cmpi.w	#SCRH,d5
	blt	.vp
	rts


;	Blit d2 pixels x d3 lines of plane B from (d1, d4) to the back buffer at (d7, d5). Keeps
;	d3-d7. Channel B is the plane (shifted), C the screen, D the result; A is the edge mask
;	(BLTADAT = $FFFF through the first / last word masks), minterm AB + /AC. One extra word on
;	the left with a zero first word mask carries the shift in.
rd_blitrect
	movem.l	d3-d7,-(sp)
	move.w	d7,d0
	add.w	(rd_xorg).l,d0			;destination bit x
	move.w	d0,(rd_tmp).l
	move.w	d0,d6
	lsr.w	#4,d6				;first destination word
	move.w	d6,d7
	lsl.w	#4,d7
	sub.w	d0,d7
	add.w	d1,d7				;T = source bit for destination bit d6*16
	move.w	d7,d0
	asr.w	#4,d0				;floor(T / 16)
	andi.w	#15,d7
	beq	.r0
	addq.w	#1,d0
	neg.w	d7
	addi.w	#16,d7				;shift = 16 - (T & 15)
.r0	subq.w	#1,d0				;source word, with the extra word
	subq.w	#1,d6				;destination word, with the extra word
	; words: up to the word of the last destination pixel
	move.w	(rd_tmp).l,d1
	add.w	d2,d1
	subq.w	#1,d1				;last destination bit
	move.w	d1,d2
	lsr.w	#4,d2
	sub.w	d6,d2
	addq.w	#1,d2				;d2 = words
	andi.w	#15,d1
	move.w	#$8000,d5
	asr.w	d1,d5				;last word mask: bits up to the last pixel
	bsr	rd_bq_alloc
	move.w	#$07CA,d3			;BLTCON0: B, C, D, AB+/AC
	tst.b	(rd_blitnoc).l
	beq.s	.usec
	move.w	#$05C0,d3			;B, D, AB: nothing to keep at the edges
.usec	move.w	d3,$040(a6)
	ror.w	#4,d7
	move.w	d7,$042(a6)			;BLTCON1: B shift
	move.w	#0,$044(a6)			;BLTAFWM: the extra word is kept
	move.w	d5,$046(a6)			;BLTALWM
	move.w	#$FFFF,$074(a6)			;BLTADAT
	; source: bmB + plane y * cw * 6 + word * 2
	move.w	(rd_cw).l,d1
	move.w	d4,d3
	mulu.w	d1,d3
	mulu.w	#6,d3
	lea	(bmB).l,a0
	adda.l	d3,a0
	ext.l	d0
	add.l	d0,d0
	adda.l	d0,a0
	move.l	a0,$04C(a6)			;BLTBPT
	move.w	d2,d0
	add.w	d0,d0				;bytes a row
	sub.w	d0,d1
	move.w	d1,$062(a6)			;BLTBMOD
	movea.l	(rd_back).l,a0
	move.l	(sp),d3				;(lines)
	move.l	8(sp),d5			;(screen y)
	mulu.w	#SROW,d5
	adda.l	d5,a0
	ext.l	d6
	add.l	d6,d6
	adda.l	d6,a0
	move.l	a0,$048(a6)			;BLTCPT
	move.l	a0,$054(a6)			;BLTDPT
	move.w	#SBPR,d1
	sub.w	d0,d1
	move.w	d1,$060(a6)			;BLTCMOD
	move.w	d1,$066(a6)			;BLTDMOD
	mulu.w	#6,d3
	move.w	d3,$05C(a6)			;BLTSIZV: lines * 6 planes
	move.w	d2,$05E(a6)			;BLTSIZH
	bsr	rd_bq_go
	movem.l	(sp)+,d3-d7
	rts

;	------------------------------------------------------------------------------------------
;	The VDP state that places the picture, taken at once (no game frame can run in between):
;	the registers, the plane A / B scroll, the sprite list. A frame takes the game several of
;	its frames to draw; drawn from this, its planes and sprites are all of the same one.
rd_snapshot
	move	sr,-(sp)
	ori	#$0700,sr
	lea	(vdp_regs).l,a0
	lea	(rd_regs).l,a1
	moveq	#32/4-1,d0
.r	move.l	(a0)+,(a1)+
	dbf	d0,.r
	move.l	(vdp_vsram).l,(rd_vs).l		;full screen vertical scroll: A, B
	moveq	#0,d0
	move.b	(rd_regs+13).l,d0
	andi.w	#$3F,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	lea	(vdp_vram).l,a0
	move.l	(a0,d0.l),(rd_hs).l		;full screen horizontal scroll: A, B
	bsr	rd_collect_sprites
	bsr	rd_obj_mark
	move	(sp)+,sr
	rts

;	The sprite list, followed from sprite 0 through the links.
rd_collect_sprites
	lea	(rd_regs).l,a5
	moveq	#0,d0
	move.b	5(a5),d0
	moveq	#64,d6
	move.b	12(a5),d1
	andi.b	#$81,d1
	beq	.32
	andi.w	#$7E,d0
	moveq	#80,d6
	bra	.b
.32	andi.w	#$7F,d0
.b	lsl.l	#8,d0
	add.l	d0,d0
	lea	(vdp_vram).l,a0
	adda.l	d0,a0
	lea	(rd_sprites).l,a1
	moveq	#0,d1
	moveq	#0,d5
	sf	(rd_sprnsq).l			;(the list is the table in order: objects can be used)
.coll	move.w	d1,d0
	lsl.w	#3,d0
	move.l	(a0,d0.w),(a1)+
	move.l	4(a0,d0.w),(a1)+
	addq.w	#1,d5
	moveq	#0,d1
	move.b	3(a0,d0.w),d1
	andi.b	#$7F,d1
	beq	.done
	cmp.w	d1,d5
	beq.s	.sq
	st	(rd_sprnsq).l
.sq	cmp.w	d6,d5
	blt	.coll
.done	move.w	d5,(rd_spn).l
	rts

;	------------------------------------------------------------------------------------------
;	Masked write of one 8 pixel row at screen x d0 on the row a1 (overlay line):
;	d1 = planes 0-3 (p0 in the high byte), d2 = palette (planes 4, 5), d3 = mask byte.
;	Keeps d0-d3, a1. Uses d4-d7, a0.
rd_put8
	moveq	#0,d4
	move.b	d3,d4
	beq	.x
	move.w	d0,d5
	addi.w	#4*8,d5
	move.w	d5,d6
	lsr.w	#3,d6
	lea	(a1,d6.w),a0			;first byte
	andi.w	#7,d5
	bne	.shift
	cmpi.b	#$FF,d4
	bne	.bmask
	; aligned and opaque: plain stores
	rol.l	#8,d1
	move.b	d1,(a0)
	rol.l	#8,d1
	move.b	d1,OSBPR(a0)
	rol.l	#8,d1
	move.b	d1,2*OSBPR(a0)
	rol.l	#8,d1
	move.b	d1,3*OSBPR(a0)
	moveq	#0,d6
	btst	#0,d2
	beq	.a4
	moveq	#-1,d6
.a4	move.b	d6,4*OSBPR(a0)
	moveq	#0,d6
	btst	#1,d2
	beq	.a5
	moveq	#-1,d6
.a5	move.b	d6,5*OSBPR(a0)
	rts
.bmask	; aligned, masked
	move.b	d4,d6
	not.b	d6				;keep mask
	rol.l	#8,d1
	move.b	(a0),d7
	and.b	d6,d7
	or.b	d1,d7
	move.b	d7,(a0)
	rol.l	#8,d1
	move.b	OSBPR(a0),d7
	and.b	d6,d7
	or.b	d1,d7
	move.b	d7,OSBPR(a0)
	rol.l	#8,d1
	move.b	2*OSBPR(a0),d7
	and.b	d6,d7
	or.b	d1,d7
	move.b	d7,2*OSBPR(a0)
	rol.l	#8,d1
	move.b	3*OSBPR(a0),d7
	and.b	d6,d7
	or.b	d1,d7
	move.b	d7,3*OSBPR(a0)
	move.b	4*OSBPR(a0),d7
	and.b	d6,d7
	btst	#0,d2
	beq	.b4
	or.b	d4,d7
.b4	move.b	d7,4*OSBPR(a0)
	move.b	5*OSBPR(a0),d7
	and.b	d6,d7
	btst	#1,d2
	beq	.b5
	or.b	d4,d7
.b5	move.b	d7,5*OSBPR(a0)
.x	rts
.shift	; across two bytes: word read-modify-write (the 68020 allows odd addresses)
	lsl.w	#8,d4
	lsr.w	d5,d4				;mask word
	move.w	d4,d6
	not.w	d6				;keep mask
	move.l	d3,-(sp)
	rol.l	#8,d1
	move.w	d1,d3
	lsl.w	#8,d3
	lsr.w	d5,d3
	move.w	(a0),d7
	and.w	d6,d7
	or.w	d3,d7
	move.w	d7,(a0)
	rol.l	#8,d1
	move.w	d1,d3
	lsl.w	#8,d3
	lsr.w	d5,d3
	move.w	OSBPR(a0),d7
	and.w	d6,d7
	or.w	d3,d7
	move.w	d7,OSBPR(a0)
	rol.l	#8,d1
	move.w	d1,d3
	lsl.w	#8,d3
	lsr.w	d5,d3
	move.w	2*OSBPR(a0),d7
	and.w	d6,d7
	or.w	d3,d7
	move.w	d7,2*OSBPR(a0)
	rol.l	#8,d1
	move.w	d1,d3
	lsl.w	#8,d3
	lsr.w	d5,d3
	move.w	3*OSBPR(a0),d7
	and.w	d6,d7
	or.w	d3,d7
	move.w	d7,3*OSBPR(a0)
	move.l	(sp)+,d3
	move.w	4*OSBPR(a0),d7
	and.w	d6,d7
	btst	#0,d2
	beq	.s4
	or.w	d4,d7
.s4	move.w	d7,4*OSBPR(a0)
	move.w	5*OSBPR(a0),d7
	and.w	d6,d7
	btst	#1,d2
	beq	.s5
	or.w	d4,d7
.s5	move.w	d7,5*OSBPR(a0)
	rts

;	Mark the screen cells of the rectangle d0 (x), d1 (y), d2 (w), d3 (h) as covered by
;	something of low priority. Keeps everything (rd_cover_u: uses d0-d3/a0).
rd_cover_rect
	movem.l	d0-d3/a0,-(sp)
	bsr.s	rd_cover_u
	movem.l	(sp)+,d0-d3/a0
	rts
rd_cover_u
	add.w	d0,d2
	subq.w	#1,d2				;x1
	add.w	d1,d3
	subq.w	#1,d3				;y1
	tst.w	d0
	bpl	.1
	moveq	#0,d0
.1	tst.w	d1
	bpl	.2
	moveq	#0,d1
.2	cmpi.w	#319,d2
	ble	.3
	move.w	#319,d2
.3	cmpi.w	#SCRH-1,d3
	ble	.4
	move.w	#SCRH-1,d3
.4	cmp.w	d0,d2
	blt	.x
	cmp.w	d1,d3
	blt	.x
	asr.w	#3,d0
	asr.w	#3,d1
	asr.w	#3,d2
	asr.w	#3,d3
	sub.w	d0,d2
	addq.w	#1,d2				;cells across (at most 40)
	ext.l	d0				;(a bit field offset is a long)
	lea	(rd_cover).l,a0
	lea	(a0,d1.w*8),a0			;first row
	sub.w	d1,d3				;rows - 1
.r	cmpi.w	#32,d2
	bgt.s	.wide
	bfset	(a0){d0:d2}			;(a width of 32 is coded as 0)
	bra.s	.n
.wide	bfset	(a0){d0:0}
	moveq	#32,d1
	add.l	d1,d0
	sub.w	d1,d2
	bfset	(a0){d0:d2}
	sub.l	d1,d0
	add.w	d1,d2
.n	addq.l	#8,a0
	dbf	d3,.r
.x	rts

;	------------------------------------------------------------------------------------------
;	Plane A and the window. rd_buildA lists their visible non-empty cells (screen x, y, entry);
;	the list is kept while their name tables, scroll, window registers and tiles stay the same.

;	------------------------------------------------------------------------------------------
;	The HUD as hardware sprites. On the rink plane A's high priority cells are the score and
;	clock boxes at the bottom; blitted each frame (and the plane under them restored after) they
;	cost the blitter a lot. When the screen is 256 wide (H32: the display leaves the sprites' DMA
;	slots free) and the high priority overlay fits, it is shown by up to 4 attached pairs of 64
;	pixel wide sprites instead (at most 4 groups of 8 columns, HUDH lines, 15 colours) and not
;	blitted. Built again when the overlay is redrawn; a cell the game changes (a clock digit)
;	only has its bytes made again (rd_hud_cell). Both in rd_hudm: each screen buffer shows a
;	copy of it made with its frame (rd_show). rd_hudon: in use.
rd_hud_off
	clr.w	(rd_hudon).l
	st	(rd_hudchg).l
	addq.l	#1,(rd_hudgen).l
	movem.l	d0/a0,-(sp)
	lea	(rd_hudspt).l,a0
	moveq	#7,d0
.n	move.l	#rd_sprnull,(a0)+
	dbf	d0,.n
	movem.l	(sp)+,d0/a0
	rts

;	All of it, into rd_hudm.
rd_hud_build
	movem.l	d0-d7/a0-a6,-(sp)
	IFD	STATS
	addq.l	#1,(rd_dbg_x+44).l
	ENDC
	bsr	rd_hud_off
	sf	(rd_hudchg).l
	move.w	(rd_w).l,(rd_hudw).l
	cmpi.w	#256,(rd_w).l
	bne	.x
	; lines and 8 pixel columns used (the mask's plane 0 copy)
	lea	(rd_hudcols).l,a0
	moveq	#12-1,d0
.cc	clr.l	(a0)+
	dbf	d0,.cc
	lea	(rd_ovlmhi).l,a1
	moveq	#-1,d6				;first line
	moveq	#0,d7				;last
	moveq	#0,d5				;line
.ln	lea	(rd_hudcols).l,a0
	moveq	#0,d1
	moveq	#12-1,d0
.lc	move.l	(a1)+,d2
	or.l	d2,(a0)+
	or.l	d2,d1
	dbf	d0,.lc
	lea	OSROW-OSBPR(a1),a1
	tst.l	d1
	beq.s	.le
	tst.w	d6
	bpl.s	.l1
	move.w	d5,d6
.l1	move.w	d5,d7
.le	addq.w	#1,d5
	cmpi.w	#SCRH,d5
	blt.s	.ln
	tst.w	d6
	bmi	.x				;(none)
	move.w	d7,d0
	sub.w	d6,d0
	addq.w	#1,d0
	cmpi.w	#HUDH,d0
	bhi	.x
	move.w	d6,(rd_hudy).l
	move.w	d0,(rd_hudn).l			;lines
	; groups of 8 columns from each first used one (screen columns: bytes 4-35)
	lea	(rd_hudcols).l,a0
	lea	(rd_hudg).l,a1
	moveq	#0,d5				;groups
	moveq	#4,d0				;byte
.gs	cmpi.w	#36,d0
	bge.s	.ge
	tst.b	(a0,d0.w)
	bne.s	.g1
	addq.w	#1,d0
	bra.s	.gs
.g1	cmpi.w	#4,d5
	beq	.x				;(more than 4)
	move.w	d0,(a1)+
	addq.w	#1,d5
	addq.w	#8,d0
	bra.s	.gs
.ge	; used columns off the screen: not shown this way
	moveq	#0,d1
	moveq	#3,d0
.go	or.b	(a0,d0.w),d1
	dbf	d0,.go
	moveq	#36,d0
.go2	or.b	(a0,d0.w),d1
	addq.w	#1,d0
	cmpi.w	#48,d0
	blt.s	.go2
	tst.b	d1
	bne	.x
	move.w	d5,(rd_hudgn).l
	; colours: none yet
	lea	(rd_hudcm).l,a0
	moveq	#64/4-1,d0
.cm	clr.l	(a0)+
	dbf	d0,.cm
	lea	(rd_hudmap).l,a0
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.w	(rd_hudnc).l
	; the sprite data: clear
	lea	(rd_hudm).l,a0
	move.l	a0,(rd_hudbase).l
	move.w	#8*HUDSPR/4-1,d0
.cs	clr.l	(a0)+
	dbf	d0,.cs
	; each group: an attached pair (sprites 2g, 2g+1)
	moveq	#0,d5				;group
.grp	movea.l	(rd_hudbase).l,a3
	move.w	d5,d0
	mulu.w	#2*HUDSPR,d0
	adda.l	d0,a3				;even sprite
	lea	HUDSPR(a3),a4			;odd
	movem.l	a3-a4,-(sp)
	lea	(rd_hudg).l,a0
	move.w	(a0,d5.w*2),d4			;first byte of the overlay row
	move.w	(rd_hudy).l,d6			;line
	moveq	#0,d7				;line of the sprites
.gl	move.w	d6,d0
	mulu.w	#OSROW,d0
	lea	(rd_ovl).l,a1
	adda.l	d0,a1
	adda.w	d4,a1				;the overlay's bytes (plane p at p * OSBPR)
	lea	(rd_ovlmhi).l,a2
	adda.l	d0,a2
	adda.w	d4,a2				;the mask
	movem.l	(sp),a3-a4
	move.w	d7,d0
	lsl.w	#4,d0
	lea	16(a3,d0.w),a5			;even sprite: A (8 bytes), B (8 bytes)
	lea	16(a4,d0.w),a6			;odd
	moveq	#0,d3				;byte of the 8
.gb	move.w	d4,d0
	add.w	d3,d0
	cmpi.w	#48,d0
	bge.s	.nb
	move.b	(a2,d3.w),d2			;mask byte
	beq.s	.nb
	lea	(a1,d3.w),a0
	movem.l	d3-d7/a5-a6,-(sp)
	adda.w	d3,a5
	adda.w	d3,a6
	bsr	rd_hud_byte
	movem.l	(sp)+,d3-d7/a5-a6
	bcs	.full
.nb	addq.w	#1,d3
	cmpi.w	#8,d3
	blt.s	.gb
	addq.w	#1,d6
	addq.w	#1,d7
	cmp.w	(rd_hudn).l,d7
	blt	.gl
	movem.l	(sp)+,a3-a4
	; control words: vertical from the window's first line, horizontal from HUDX
	moveq	#$3C,d0				;(DIWSTRT: PAL)
	tst.b	(hal_pal).l
	bne.s	.vp
	moveq	#$1A,d0
.vp	add.w	(rd_hudy).l,d0			;VSTART
	move.w	d0,d1
	add.w	(rd_hudn).l,d1			;VSTOP
	move.w	d4,d2
	lsl.w	#3,d2
	subi.w	#32,d2				;screen x
	addi.w	#HUDX,d2			;HSTART
	move.w	d0,d3				;POS: VSTART 7-0, HSTART 8-1
	lsl.w	#8,d3
	move.w	d2,d6
	lsr.w	#1,d6
	move.b	d6,d3
	move.w	d1,d6				;CTL: VSTOP 7-0, VSTART 8, VSTOP 8, HSTART 0
	lsl.w	#8,d6
	btst	#8,d0
	beq.s	.v8
	bset	#2,d6
.v8	btst	#8,d1
	beq.s	.e8
	bset	#1,d6
.e8	btst	#0,d2
	beq.s	.h0
	bset	#0,d6
.h0	move.w	d3,(a3)				;(64 bit control words: POS, then CTL 8 bytes on)
	move.w	d6,8(a3)
	move.w	d3,(a4)
	bset	#7,d6				;ATT: the odd one is attached
	move.w	d6,8(a4)
	addq.w	#1,d5
	cmp.w	(rd_hudgn).l,d5
	blt	.grp
	; in use
	movea.l	(rd_hudbase).l,a0
	lea	(rd_hudspt).l,a1
	move.w	(rd_hudgn).l,d0
	add.w	d0,d0
	subq.w	#1,d0
.sp	move.l	a0,(a1)+
	lea	HUDSPR(a0),a0
	dbf	d0,.sp
	move.w	#1,(rd_hudon).l
	addq.l	#1,(rd_hudgen).l
	lea	(rd_hudbd).l,a0			;(each buffer's copy: all of it)
	moveq	#NBUF-1,d0
.ba	move.l	#-1,(a0)+
	dbf	d0,.ba
	bra.s	.x
.full	addq.l	#8,sp				;(more than 15 colours: blitted)
	bsr	rd_hud_off
	sf	(rd_hudchg).l
.x	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	A cell of the overlay changed (d1 x, d2 y on the screen, rd_ovl_setcell): its bytes of the
;	HUD sprites in use made again; a full build if it is not in their columns and lines, or
;	needs a 16th colour.
rd_hud_cell
	tst.w	(rd_hudon).l
	bne.s	.on
	st	(rd_hudchg).l			;(not in use: the full build looks again)
	rts
.on	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d1,d3
	addi.w	#4*8,d3
	lsr.w	#3,d3				;overlay byte
	lea	(rd_hudg).l,a0
	move.w	(rd_hudgn).l,d7
	subq.w	#1,d7
	moveq	#0,d5				;group
.fg	move.w	d3,d4
	sub.w	(a0)+,d4			;byte in the group
	bmi.s	.ng
	cmpi.w	#8,d4
	blt.s	.fd
.ng	addq.w	#1,d5
	dbf	d7,.fg
	bra	.full
.fd
	IFD	STATS
	addq.l	#1,(rd_dbg_x+72).l		;(statistics: HUD cells made again)
	ENDC
	; the bands of 8 lines it is in, of its group: each buffer's copy takes them (rd_show)
	moveq	#0,d0
	move.w	d2,d0
	sub.w	(rd_hudy).l,d0			;its first line in the sprites
	bpl.s	.b0
	moveq	#0,d0
.b0	moveq	#0,d1
	move.w	d2,d1
	addq.w	#7,d1
	sub.w	(rd_hudy).l,d1			;its last
	bmi.s	.bx
	cmpi.w	#HUDH-1,d1
	ble.s	.b1
	move.w	#HUDH-1,d1
.b1	cmp.w	d1,d0
	bgt.s	.bx
	lsr.w	#3,d0
	lsr.w	#3,d1
	move.w	d5,d6
	lsl.w	#3,d6
	add.w	d6,d0				;group * 8 + band
	add.w	d6,d1
	lea	(rd_hudbd).l,a0
	moveq	#NBUF-1,d6
.bb	bfset	(a0){d0:1}
	bfset	(a0){d1:1}
	addq.l	#4,a0
	dbf	d6,.bb
.bx
	lea	(rd_hudspt).l,a0
	movea.l	(a0,d5.w*8),a3			;even sprite
	movea.l	4(a0,d5.w*8),a4			;odd
	move.w	d2,d6				;line
	moveq	#7,d7
.ln	move.w	d6,d0
	bmi.s	.nl
	cmpi.w	#SCRH,d0
	bge.s	.nl
	mulu.w	#OSROW,d0
	lea	(rd_ovl).l,a0
	adda.l	d0,a0
	adda.w	d3,a0				;its byte
	lea	(rd_ovlmhi).l,a1
	adda.l	d0,a1
	move.b	(a1,d3.w),d2			;its mask
	move.w	d6,d0
	sub.w	(rd_hudy).l,d0			;line of the sprites
	bmi.s	.out
	cmp.w	(rd_hudn).l,d0
	bge.s	.out
	lsl.w	#4,d0
	lea	16(a3,d0.w),a5
	lea	16(a4,d0.w),a6
	adda.w	d4,a5
	adda.w	d4,a6
	movem.l	d3-d7/a3-a4,-(sp)
	bsr	rd_hud_byte
	movem.l	(sp)+,d3-d7/a3-a4
	bcs.s	.full
	bra.s	.nl
.out	tst.b	d2
	bne.s	.full				;(something outside the sprites' lines)
.nl	addq.w	#1,d6
	dbf	d7,.ln
	bra.s	.x
.full	st	(rd_hudchg).l
.x	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	One byte (8 pixels) of the HUD sprites: a0 = the overlay's byte (plane p at p * OSBPR), d2 =
;	its high priority mask, a5 / a6 = the even / odd sprite's byte (plane A; plane B 8 bytes
;	on). New colours are given sprite colours (rd_hudcm, rd_hudmap). C set if a 16th would be
;	needed. Uses d0-d1, d3-d7, a3-a4.
rd_hud_byte
	lea	(rd_hudcm).l,a3
	lea	(rd_hudmap).l,a4
	moveq	#0,d4				;even A
	moveq	#0,d5				;even B
	moveq	#0,d6				;odd A
	moveq	#0,d7				;odd B
	moveq	#7,d0				;pixel bit
.px	btst	d0,d2
	beq	.pn
	moveq	#0,d1				;its colour
	btst	d0,(a0)
	beq.s	.c1
	bset	#0,d1
.c1	btst	d0,OSBPR(a0)
	beq.s	.c2
	bset	#1,d1
.c2	btst	d0,2*OSBPR(a0)
	beq.s	.c3
	bset	#2,d1
.c3	btst	d0,3*OSBPR(a0)
	beq.s	.c4
	bset	#3,d1
.c4	btst	d0,4*OSBPR(a0)
	beq.s	.c5
	bset	#4,d1
.c5	btst	d0,5*OSBPR(a0)
	beq.s	.c6
	bset	#5,d1
.c6	move.b	(a3,d1.w),d3			;its sprite colour
	bne.s	.cok
	move.w	(rd_hudnc).l,d3
	cmpi.w	#15,d3
	beq.s	.full
	addq.w	#1,d3
	move.w	d3,(rd_hudnc).l
	move.b	d3,(a3,d1.w)
	move.b	d1,(a4,d3.w)
	addq.l	#1,(rd_hudgen).l		;(the copper lists' HUD colours)
.cok	btst	#0,d3
	beq.s	.s1
	bset	d0,d4
.s1	btst	#1,d3
	beq.s	.s2
	bset	d0,d5
.s2	btst	#2,d3
	beq.s	.s3
	bset	d0,d6
.s3	btst	#3,d3
	beq.s	.pn
	bset	d0,d7
.pn	dbf	d0,.px
	move.b	d4,(a5)
	move.b	d5,8(a5)
	move.b	d6,(a6)
	move.b	d7,8(a6)
	andi	#$FE,ccr			;C clear
	rts
.full	ori	#1,ccr				;C set
	rts

;	------------------------------------------------------------------------------------------
;	The plane A / window overlay: the listed cells drawn into a screen sized bitmap with a mask
;	plane per priority, redrawn only when the list changes. Each frame the blitter cuts the
;	rows that have cells into the screen, low priority before the sprites, high after.

rd_ovl_redraw
	st	(rd_hudchg).l
	IFD	STATS
	addq.l	#1,(rd_dbg_x+16).l
	ENDC
	sf	(rd_ovldirty).l
	; clear image and masks (blitter, D only)
	bsr	rd_waitblit
	bsr	rd_cq_inval			;(the blitter's registers written here)
	lea	(CUSTOM).l,a6
	move.w	#$0100,$040(a6)
	move.w	#0,$042(a6)
	move.l	#rd_ovl,$054(a6)
	move.w	#0,$066(a6)
	move.w	#SCRH*6,$05C(a6)
	move.w	#OSBPR/2,$05E(a6)
	bsr	rd_waitblit
	move.l	#rd_ovlmlo,$054(a6)
	move.w	#SCRH*6*2,$05C(a6)		;both masks (they follow each other)
	move.w	#OSBPR/2,$05E(a6)
	; rows used, per priority: x min, x max (pixels), empty = min > max
	lea	(rd_ovlrows).l,a0
	moveq	#2*32-1,d0
.ir	move.w	#$7FFF,(a0)+
	move.w	#-$7FFF,(a0)+
	dbf	d0,.ir
	lea	(rd_ovlcolf).l,a0
	move.w	#2*32*48/4-1,d0
.icf	clr.l	(a0)+
	dbf	d0,.icf
	bsr	rd_waitblit
	; draw the cells
	lea	(rd_alist).l,a4
	move.w	(rd_alistn).l,d7
	subq.w	#1,d7
	bmi	.x
.c	move.w	(a4)+,d1			;x
	move.w	(a4)+,d2			;y
	move.w	(a4)+,d0			;entry
	movem.l	d7/a4,-(sp)
	bsr	rd_ovl_cell
	movem.l	(sp)+,d7/a4
	dbf	d7,.c
.x	rts

;	Cell d0 at (d1, d2) into the overlay.
rd_ovl_cell
	; rows table: this cell's 8 lines extend its rows' extents
	lea	(rd_ovlrows).l,a5
	tst.w	d0
	bpl	.lo
	lea	32*4(a5),a5
.lo	move.w	d2,d3
	asr.w	#3,d3
	addq.w	#1,d3				;rows of 8 lines from y = -8
	moveq	#1,d4				;the cell can touch 2 bands
	lea	(rd_ovlcolf).l,a6		;column flags: band * 48 + (x + 8) / 8
	tst.w	d0
	bpl.s	.clo
	lea	32*48(a6),a6
.clo
.band	cmpi.w	#31,d3
	bhi	.nb
	move.w	d3,d5
	mulu.w	#48,d5
	move.w	d1,d6
	addq.w	#8,d6
	asr.w	#3,d6
	bmi.s	.f1
	cmpi.w	#47,d6
	bhi.s	.f1
	add.w	d5,d6
	st	(a6,d6.w)
.f1	move.w	d1,d6
	addi.w	#15,d6
	asr.w	#3,d6
	bmi.s	.f2
	cmpi.w	#47,d6
	bhi.s	.f2
	add.w	d5,d6
	st	(a6,d6.w)
.f2
	cmp.w	(a5,d3.w*4),d1
	bge	.nmin
	move.w	d1,(a5,d3.w*4)
.nmin	move.w	d1,d5
	addq.w	#7,d5
	cmp.w	2(a5,d3.w*4),d5
	ble	.nb
	move.w	d5,2(a5,d3.w*4)
.nb	addq.w	#1,d3
	dbf	d4,.band
	; cache rows
	lea	(tp_pl).l,a2
	moveq	#0,d3
	move.w	d0,d3
	andi.w	#$FFF,d3
	lsl.l	#5,d3
	adda.l	d3,a2
	lea	(tp_mk).l,a3
	lsr.l	#2,d3
	adda.l	d3,a3
	moveq	#4,d4
	moveq	#1,d5
	btst	#12,d0
	beq	.nv
	lea	28(a2),a2
	addq.l	#7,a3
	moveq	#-4,d4
	moveq	#-1,d5
.nv	move.w	d0,d6
	rol.w	#3,d6
	andi.w	#3,d6				;palette
	lea	(rd_ovlmlo).l,a5
	tst.w	d0
	bpl	.mlo
	lea	(rd_ovlmhi).l,a5
.mlo	move.w	d1,d0				;x
	move.w	d2,d7				;y
	move.w	d6,d2
	move.w	#7,(rd_rowc).l
.row	tst.w	d7
	bmi	.skip
	cmpi.w	#SCRH,d7
	bge	.done
	lea	(rd_ovl).l,a1
	move.w	d7,d3
	mulu.w	#OSROW,d3
	adda.l	d3,a1
	move.l	(a2),d1
	move.b	(a3),d3
	movem.l	d4-d7/a5,-(sp)
	bsr	rd_put8
	movem.l	(sp)+,d4-d7/a5
	; mask: or the row's mask bits in (each plane's copy)
	move.w	d7,d6
	mulu.w	#OSROW,d6
	lea	(a5,d6.l),a0
	move.w	d0,d6
	addi.w	#4*8,d6
	moveq	#0,d1
	move.b	d3,d1
	ror.l	#8,d1
	move.w	d6,-(sp)
	andi.w	#7,d6
	lsr.l	d6,d1				;mask in the top bits, shifted
	move.w	(sp)+,d6
	lsr.w	#3,d6
	adda.w	d6,a0
	swap	d1
	or.w	d1,(a0)
	or.w	d1,OSBPR(a0)
	or.w	d1,2*OSBPR(a0)
	or.w	d1,3*OSBPR(a0)
	or.w	d1,4*OSBPR(a0)
	or.w	d1,5*OSBPR(a0)
.skip	adda.w	d4,a2
	adda.w	d5,a3
	addq.w	#1,d7
	subq.w	#1,(rd_rowc).l
	bpl	.row
.done	rts

;	Cut the overlay rows of priority rd_pass into the back buffer: per band of 8 lines, the
;	words from the band's x min to x max, one blit per plane (A the mask plane, B the overlay,
;	C / D the screen). Low priority bands also mark rd_cover.
rd_ovl_blit
	lea	(rd_ovlrows).l,a4
	movea.l	#rd_ovlmlo,a3
	tst.w	(rd_pass).l
	beq	.lo
	lea	32*4(a4),a4
	movea.l	#rd_ovlmhi,a3
.lo	lea	(rd_ovlcolf).l,a5
	tst.w	(rd_pass).l
	beq.s	.lof
	lea	32*48(a5),a5
.lof	moveq	#0,d7				;band (lines -8 + 8 * band)
.band	move.w	(a4),d0				;x min
	move.w	2(a4),d1			;x max
	cmp.w	d1,d0
	bgt	.next
	; runs of flagged columns between them
	addq.w	#8,d0
	asr.w	#3,d0				;first column
	addq.w	#8,d1
	asr.w	#3,d1				;last column
	tst.w	d0
	bpl.s	.c0
	moveq	#0,d0
.c0	cmpi.w	#47,d1
	ble.s	.c1
	moveq	#47,d1
.c1	move.w	d7,d2
	mulu.w	#48,d2
	lea	(a5,d2.w),a2			;this band's flags
.run	cmp.w	d1,d0
	bgt	.next
	tst.b	(a2,d0.w)
	bne.s	.rs
	addq.w	#1,d0
	bra.s	.run
.rs	move.w	d0,d2				;run start
.re	addq.w	#1,d0
	cmp.w	d1,d0
	bgt.s	.rx
	tst.b	(a2,d0.w)
	bne.s	.re
.rx	; columns d2 .. d0-1: pixels d2*8-8 .. d0*8-9
	movem.l	d0-d1/a2,-(sp)
	move.w	d0,d1
	lsl.w	#3,d1
	subi.w	#9,d1
	move.w	d2,d0
	lsl.w	#3,d0
	subq.w	#8,d0
	bsr	.blitrun
	movem.l	(sp)+,d0-d1/a2
	bra.s	.run
.next	addq.l	#4,a4
	addq.w	#1,d7
	cmpi.w	#30,d7
	blt	.band
	bra	rd_cq_flush			;(the last batch let go)
.blitrun	; pixels d0 .. d1 of band d7
	; lines of the band on screen
	move.w	d7,d2
	subq.w	#1,d2
	lsl.w	#3,d2				;first line
	moveq	#8,d3				;lines
	tst.w	d2
	bpl	.t
	add.w	d2,d3
	moveq	#0,d2
.t	move.w	d2,d4
	add.w	d3,d4
	cmpi.w	#SCRH,d4
	ble	.b
	move.w	#SCRH,d3
	sub.w	d2,d3
.b	tst.w	d3
	ble	.bx
	; only the screen's columns
	tst.w	d0
	bpl.s	.g0
	moveq	#0,d0
.g0	move.w	(rd_w).l,d4
	subq.w	#1,d4
	cmp.w	d4,d1
	ble.s	.g1
	move.w	d4,d1
.g1	cmp.w	d1,d0
	bgt	.bx
	move.w	d1,d4
	sub.w	d0,d4
	addq.w	#1,d4				;pixels
	movem.l	d0-d3,-(sp)
	move.w	d2,d1
	move.w	d4,d2
	bsr	rd_mark
	tst.w	(rd_pass).l
	bne.s	.nocov
	bsr	rd_cover_rect
.nocov	movem.l	(sp)+,d0-d3
	; the overlay's words (x 0 is its bit 32) that hold the pixels and one more, masked out,
	; that carries the shift to the screen's bits (rd_xorg + x)
	addi.w	#4*8,d0
	addi.w	#4*8,d1
	lsr.w	#4,d0				;first word
	lsr.w	#4,d1
	sub.w	d0,d1
	addq.w	#2,d1				;words
	move.w	(rd_xorg).l,d6
	subi.w	#4*8,d6				;screen bit - overlay bit
	moveq	#15,d5
	and.w	d6,d5				;shift
	lsr.w	#4,d6
	add.w	d0,d6				;first screen word
	add.w	d0,d0				;first byte
	add.w	d6,d6
	move.w	d2,d4
	mulu.w	#OSROW,d4
	lea	(rd_ovl).l,a1
	adda.l	d4,a1
	adda.w	d0,a1
	lea	(a3,d4.l),a2			;(the masks are interleaved like the overlay)
	adda.w	d0,a2
	move.w	d2,d4
	mulu.w	#SROW,d4
	movea.l	(rd_back).l,a0
	adda.l	d4,a0
	adda.w	d6,a0
	move.w	d1,d4
	add.w	d4,d4				;bytes a row
	; one blit for the 6 planes: rows of the interleaved image, mask and screen (the copper
	; block: rd_cq_blit)
	move.l	a5,-(sp)
	bsr	rd_cq_blit
	sf	(rd_cqkind).l
	ror.w	#4,d5
	move.l	#$00420000,d6
	move.w	d5,d6
	move.l	d6,(a5)+			;BLTCON1: B shift
	ori.w	#$0FCA,d6
	eori.l	#($042^$040)<<16,d6
	move.l	d6,(a5)+			;BLTCON0: A shift; A mask, B overlay, C, D: AB + /AC
	move.l	#$0044FFFF,(a5)+		;BLTAFWM
	move.l	#$00460000,(a5)+		;BLTALWM: the extra word
	move.l	#$00740000,(a5)+		;BLTADAT: what the shift brings into the first word
	CQA	$050,a2,d6			;A: mask
	CQA	$04C,a1,d6			;B: overlay
	CQA	$048,a0,d6			;C
	CQA	$054,a0,d6			;D
	move.l	#$00640000|OSBPR,d6
	sub.w	d4,d6
	move.l	d6,(a5)+			;BLTAMOD
	eori.l	#($064^$062)<<16,d6
	move.l	d6,(a5)+			;BLTBMOD
	move.l	#$00600000|SBPR,d6
	sub.w	d4,d6
	move.l	d6,(a5)+			;BLTCMOD
	eori.l	#($060^$066)<<16,d6
	move.l	d6,(a5)+			;BLTDMOD
	mulu.w	#NPLANES,d3
	CQV	$05C,d3,d6			;BLTSIZV: lines * 6 planes
	CQV	$05E,d1,d6			;BLTSIZH
	bsr	rd_cq_endblit
	movea.l	(sp)+,a5
.bx	rts

;	Redraw the overlay cells of the listed changed name table longs (rd_chgA, rd_chgW), plane A
;	scrolled by whole cells. d6 = plane cells across, d7 = down.
rd_ovl_cells_changed
	IFD	STATS
	addq.l	#1,(rd_dbg_x+20).l
	ENDC
	bsr	rd_waitblit			;(the frame before's blits may still read the overlay)
	lea	(rd_aused).l,a3
	lea	(rd_chgA).l,a4
	move.w	(rd_nchgA).l,d4
	bra	.anext
.aloop	move.w	(a4)+,d0
	add.w	d0,d0				;first cell of the long
	moveq	#1,d3
.acell	movem.l	d0/d3-d4/a4,-(sp)
	moveq	#0,d1
	move.w	d0,d1
	divu.w	d6,d1				;row : column (remainder)
	move.l	d1,d2
	swap	d2				;column
	move.w	(rd_ax0).l,d5
	lsr.w	#3,d5
	sub.w	d5,d2
	move.w	d6,d5
	subq.w	#1,d5
	and.w	d5,d2				;screen column
	move.w	(rd_ay0).l,d5
	lsr.w	#3,d5
	sub.w	d5,d1
	move.w	d7,d5
	subq.w	#1,d5
	and.w	d5,d1				;screen row
	cmp.w	(rd_cells).l,d2
	bhi.s	.askip
	cmpi.w	#28,d1
	bhi.s	.askip
	movem.l	d0-d1,-(sp)
	move.w	d2,d4
	move.w	d1,d5
	bsr	rd_inwindow
	movem.l	(sp)+,d0-d1
	bne.s	.askip				;the window covers it
	lea	(rd_shA).l,a0
	move.w	(a0,d0.w*2),d0			;entry
	lsl.w	#3,d2
	lsl.w	#3,d1
	exg	d1,d2				;d1 = x, d2 = y
	bsr	rd_ovl_setcell
.askip	movem.l	(sp)+,d0/d3-d4/a4
	addq.w	#1,d0
	dbf	d3,.acell
.anext	dbf	d4,.aloop
	; window
	lea	(rd_chgW).l,a4
	move.w	(rd_nchgW).l,d4
	bra	.wnext
.wloop	move.w	(a4)+,d0
	add.w	d0,d0
	moveq	#1,d3
.wcell	movem.l	d0/d3-d4/a4,-(sp)
	moveq	#0,d1
	move.w	d0,d1
	divu.w	(rd_wwidth).l,d1
	move.l	d1,d2
	swap	d2				;column
	movem.l	d0-d2,-(sp)
	move.w	d2,d4
	move.w	d1,d5
	bsr	rd_inwindow
	movem.l	(sp)+,d0-d2
	beq.s	.wskip
	lea	(rd_shW).l,a0
	move.w	(a0,d0.w*2),d0
	lsl.w	#3,d2
	lsl.w	#3,d1
	exg	d1,d2
	bsr	rd_ovl_setcell
.wskip	movem.l	(sp)+,d0/d3-d4/a4
	addq.w	#1,d0
	dbf	d3,.wcell
.wnext	dbf	d4,.wloop
	rts

;	Cell d0 at (d1, d2), a whole cell position: clear it in the overlay and its masks, then draw
;	it if its tile is not empty. a3 = rd_aused.
rd_ovl_setcell
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d0,d3
	andi.l	#$7FF,d3
	lea	(rd_aused).l,a3
	bfset	(a3){d3:1}
	TNEED	d3
	move.w	d1,d3
	addi.w	#4*8,d3
	lsr.w	#3,d3				;byte
	moveq	#7,d4
	move.w	d2,d5				;line
.cl	tst.w	d5
	bmi.s	.cn
	cmpi.w	#SCRH,d5
	bge.s	.cn
	lea	(rd_ovl).l,a0
	move.w	d5,d6
	mulu.w	#OSROW,d6
	adda.l	d6,a0
	adda.w	d3,a0
	clr.b	(a0)
	clr.b	OSBPR(a0)
	clr.b	2*OSBPR(a0)
	clr.b	3*OSBPR(a0)
	clr.b	4*OSBPR(a0)
	clr.b	5*OSBPR(a0)
	lea	(rd_ovlmlo).l,a0
	move.w	d5,d6
	mulu.w	#OSROW,d6
	adda.l	d6,a0
	adda.w	d3,a0
	lea	(rd_ovlmhi-rd_ovlmlo).l,a1
	adda.l	a0,a1				;the high mask
	moveq	#5,d6
.cm	clr.b	(a0)
	clr.b	(a1)
	lea	OSBPR(a0),a0
	lea	OSBPR(a1),a1
	dbf	d6,.cm
.cn	addq.w	#1,d5
	dbf	d4,.cl
	move.w	d0,d3
	andi.w	#$FFF,d3
	lea	(tp_cls).l,a0
	tst.b	(a0,d3.w)
	beq.s	.x
	bsr	rd_ovl_cell
.x	movem.l	4(sp),d1-d2
	bsr	rd_hud_cell			;(the HUD sprites)
	movem.l	(sp)+,d0-d7/a0-a6
	rts

rd_buildA
	lea	(rd_regs).l,a5
	lea	(rd_akeynew).l,a3
	; window rows (screen cells) and columns
	move.b	18(a5),d0
	move.w	d0,d1
	andi.w	#$1F,d1
	moveq	#0,d2
	move.w	d1,d3
	tst.b	d0
	bpl	.top
	move.w	d1,d2
	moveq	#28,d3
.top	move.w	d2,(rd_wy0).l
	move.w	d3,(rd_wy1).l
	move.b	17(a5),d0
	move.w	d0,d1
	andi.w	#$1F,d1
	add.w	d1,d1
	moveq	#0,d2
	move.w	d1,d3
	tst.b	d0
	bpl	.left
	move.w	d1,d2
	moveq	#41,d3
.left	move.w	d2,(rd_wx0).l
	move.w	d3,(rd_wx1).l
	move.w	17(a5),(a3)+			;key: window registers
	; window name table
	moveq	#0,d0
	move.b	3(a5),d0
	moveq	#32,d6
	move.b	12(a5),d1
	andi.b	#$81,d1
	beq	.w32
	andi.w	#$3C,d0
	moveq	#64,d6
	bra	.wb
.w32	andi.w	#$3E,d0
.wb	lsl.l	#8,d0
	lsl.l	#2,d0
	move.w	d6,(rd_wwidth).l
	move.l	d0,(rd_wbase).l
	move.l	d0,(a3)+			;key: window base
	; plane A name table and scroll
	moveq	#0,d0
	move.b	2(a5),d0
	andi.w	#$38,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	move.l	d0,(rd_abase).l
	move.l	d0,(a3)+			;key: A base
	move.w	(rd_cw).l,d6
	move.w	(rd_ch).l,d7
	move.w	(rd_hs).l,d0			;A hscroll
	neg.w	d0
	move.w	d6,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	d0,(rd_ax0).l
	move.w	d0,(a3)+			;key: A x
	move.w	(rd_vs).l,d0
	move.w	d7,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	d0,(rd_ay0).l
	move.w	d0,(a3)+			;key: A y
	move.w	d6,(a3)+			;key: size, width
	move.w	d7,(a3)+
	move.w	(rd_cells).l,(a3)+
	; same as last time? d5: 0 nothing, 1 a few cells (listed), 2 everything
	lea	(rd_akeynew).l,a0
	lea	(rd_akey).l,a1
	moveq	#0,d5
	moveq	#5,d0
.k	cmpm.l	(a0)+,(a1)+
	beq	.k1
	moveq	#2,d5
.k1	dbf	d0,.k
	; name tables against their copies (copied as they are compared); changed longs listed
	clr.w	(rd_nchgA).l
	clr.w	(rd_nchgW).l
	movem.l	d2-d4,-(sp)
	move.l	(rd_abase).l,d0
	move.w	d6,d1
	mulu.w	d7,d1
	add.l	d1,d1
	bsr	rd_ntwritten
	movem.l	(sp)+,d2-d4
	move.b	d0,(rd_ntcur).l
	IFND	VERIFY
	beq	.caw				;not written to: as it was
	ENDC
	move.b	#2,(rd_nttab).l
	lea	(vdp_vram).l,a0
	adda.l	(rd_abase).l,a0
	lea	(rd_shA).l,a1
	lea	(rd_chgA).l,a2
	move.w	d6,d0
	mulu.w	d7,d0
	lsr.w	#1,d0
	subq.w	#1,d0				;longs - 1
	moveq	#0,d2				;long index
	moveq	#0,d3				;listed
.ca	move.l	(a0)+,d1
	cmp.l	(a1),d1
	beq	.ca1
	move.l	d1,(a1)
	bsr	.note
.ca1	addq.l	#4,a1
	addq.w	#1,d2
	dbf	d0,.ca
	move.w	d3,(rd_nchgA).l
.caw	movem.l	d2-d4,-(sp)
	move.l	(rd_wbase).l,d0
	moveq	#0,d1
	move.w	(rd_wwidth).l,d1
	lsl.l	#6,d1				;* 32 rows * 2
	bsr	rd_ntwritten
	movem.l	(sp)+,d2-d4
	move.b	d0,(rd_ntcur).l
	IFND	VERIFY
	beq	.cww
	ENDC
	move.b	#3,(rd_nttab).l
	lea	(vdp_vram).l,a0
	adda.l	(rd_wbase).l,a0
	lea	(rd_shW).l,a1
	lea	(rd_chgW).l,a2
	move.w	(rd_wwidth).l,d0
	lsl.w	#4,d0				;* 32 rows / 2
	subq.w	#1,d0
	moveq	#0,d2
	moveq	#0,d3
.cw	move.l	(a0)+,d1
	cmp.l	(a1),d1
	beq	.cw1
	move.l	d1,(a1)
	bsr	.note
.cw1	addq.l	#4,a1
	addq.w	#1,d2
	dbf	d0,.cw
	move.w	d3,(rd_nchgW).l
.cww	st	(rd_ntsync).l			;(the copies are in step from here on)
	; tiles of these cells converted again?
	lea	(tc_chg).l,a0
	lea	(rd_aused).l,a1
	moveq	#63,d0
.tu	move.l	(a0)+,d1
	and.l	(a1)+,d1
	beq	.tu1
	moveq	#2,d5
.tu1	dbf	d0,.tu
	tst.w	d5
	beq	.keep
	cmpi.w	#1,d5
	bne	.full
	; a few cells: redraw just those in the overlay (only with whole cell scroll)
	move.w	(rd_ax0).l,d0
	or.w	(rd_ay0).l,d0
	andi.w	#7,d0
	bne	.full
	bsr	rd_ovl_cells_changed
	bra	.keep
.note	; long d2 of a name table changed: list it (d3 = count), or ask for a full redraw
	IFD	VERIFY
	tst.b	(rd_ntcur).l
	bne.s	.nok
	move.l	d0,-(sp)
	moveq	#0,d0
	move.b	(rd_nttab).l,d0
	bsr	rd_ntfail
	move.l	(sp)+,d0
.nok
	ENDC
	moveq	#1,d1
	cmpi.w	#2,d5
	beq.s	.n2
	cmpi.w	#16,d3
	bhs.s	.nfull
	move.w	d2,(a2,d3.w*2)
	addq.w	#1,d3
	move.w	d1,d5
.n2	rts
.nfull	moveq	#2,d5
	rts
.full
	; rebuild, the copies as drawn (a compare skipped while the key changed left them behind)
	lea	(vdp_vram).l,a0
	adda.l	(rd_abase).l,a0
	lea	(rd_shA).l,a1
	move.w	d6,d0
	mulu.w	d7,d0
	lsr.w	#1,d0
	subq.w	#1,d0
.cpa	move.l	(a0)+,(a1)+
	dbf	d0,.cpa
	lea	(vdp_vram).l,a0
	adda.l	(rd_wbase).l,a0
	lea	(rd_shW).l,a1
	move.w	(rd_wwidth).l,d0
	lsl.w	#4,d0
	subq.w	#1,d0
.cpw	move.l	(a0)+,(a1)+
	dbf	d0,.cpw
	IFD	STATS
	addq.l	#1,(rd_dbg_x+12).l
	ENDC
	lea	(rd_akeynew).l,a0
	lea	(rd_akey).l,a1
	moveq	#5,d0
.kc	move.l	(a0)+,(a1)+
	dbf	d0,.kc
	lea	(rd_aused).l,a0
	moveq	#63,d0
.uc	clr.l	(a0)+
	dbf	d0,.uc
	lea	(rd_alist).l,a2
	lea	(rd_aused).l,a3
	lea	(vdp_vram).l,a4
	adda.l	(rd_wbase).l,a4
	; window cells
	moveq	#0,d5
.wr	moveq	#0,d4
.wc	bsr	rd_inwindow
	beq	.wn
	move.w	d5,d0
	mulu.w	(rd_wwidth).l,d0
	add.w	d4,d0
	add.w	d0,d0
	move.w	(a4,d0.w),d0
	move.w	d4,d1
	lsl.w	#3,d1
	move.w	d5,d2
	lsl.w	#3,d2
	bsr	rd_addcell
.wn	addq.w	#1,d4
	cmp.w	(rd_cells).l,d4
	blt	.wc
	addq.w	#1,d5
	cmpi.w	#28,d5
	blt	.wr
	; plane A cells outside the window
	lea	(vdp_vram).l,a4
	adda.l	(rd_abase).l,a4
	moveq	#0,d5
.ar	moveq	#0,d4
.ac	move.w	(rd_ax0).l,d0
	lsr.w	#3,d0
	add.w	d4,d0
	move.w	d6,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	(rd_ay0).l,d1
	lsr.w	#3,d1
	add.w	d5,d1
	move.w	d7,d2
	subq.w	#1,d2
	and.w	d2,d1
	mulu.w	d6,d1
	add.w	d0,d1
	add.w	d1,d1
	move.w	(a4,d1.w),d0
	move.w	d4,d1
	lsl.w	#3,d1
	move.w	(rd_ax0).l,d2
	andi.w	#7,d2
	sub.w	d2,d1
	move.w	d5,d2
	lsl.w	#3,d2
	move.w	(rd_ay0).l,d3
	andi.w	#7,d3
	sub.w	d3,d2
	movem.w	d0/d4-d5,-(sp)
	move.w	d1,d4
	addq.w	#4,d4
	asr.w	#3,d4
	move.w	d2,d5
	addq.w	#4,d5
	asr.w	#3,d5
	bsr	rd_inwindow
	movem.w	(sp)+,d0/d4-d5
	bne	.an
	bsr	rd_addcell
.an	addq.w	#1,d4
	cmp.w	(rd_cells).l,d4
	ble	.ac
	addq.w	#1,d5
	cmpi.w	#28,d5
	ble	.ar
	move.l	a2,d0
	sub.l	#rd_alist,d0
	divu.w	#6,d0
	move.w	d0,(rd_alistn).l
	st	(rd_ovldirty).l
.keep	rts

;	Note tile of entry d0 as used; list the cell (d1 x, d2 y) unless the tile is empty or the
;	cell is off screen. a2 = list end, a3 = rd_aused. Keeps d0-d7.
rd_addcell
	move.l	d3,-(sp)
	move.w	d0,d3
	andi.l	#$7FF,d3
	bfset	(a3){d3:1}
	TNEED	d3
	move.w	d0,d3
	andi.w	#$FFF,d3
	lea	(tp_cls).l,a0
	tst.b	(a0,d3.w)
	beq	.x
	cmpi.w	#-8,d1
	ble	.x
	cmpi.w	#-8,d2
	ble	.x
	cmpi.w	#SCRH,d2
	bge	.x
	cmp.w	(rd_w).l,d1
	bge	.x
	move.w	d1,(a2)+
	move.w	d2,(a2)+
	move.w	d0,(a2)+
.x	move.l	(sp)+,d3
	rts

;	Z clear if screen cell d4 (column), d5 (row) is in the window. Keeps all but the flags.
rd_inwindow
	cmp.w	(rd_wy0).l,d5
	blt	.h
	cmp.w	(rd_wy1).l,d5
	blt	.yes
.h	cmp.w	(rd_wx0).l,d4
	blt	.no
	cmp.w	(rd_wx1).l,d4
	bge	.no
.yes	moveq	#1,d0				;(callers reload d0)
	rts
.no	cmp.w	d0,d0				;Z set
	rts

;	------------------------------------------------------------------------------------------
;	Sprites of priority rd_pass, last in the list first. The CPU builds each sprite's image (6
;	interleaved planes) and mask (the same 6 times) in chip RAM, the blitter cuts it into the
;	screen at any pixel position. Two image buffers: the next sprite is built while the blitter
;	draws the last one.
SPRMAXB		equ	6			;bytes a row: up to 32 pixels and the shift word

rd_sprites_planar
	move.w	(rd_spn).l,d5
	lea	(rd_sprites).l,a4
	move.w	d5,d0
	lsl.w	#3,d0
	adda.w	d0,a4
	subq.w	#1,d5
	bmi	.x
.each	subq.l	#8,a4
	move.w	4(a4),d0
	andi.w	#$8000,d0
	cmp.w	(rd_pass).l,d0
	bne	.n
	lea	(rd_sprgend).l,a0		;the last sprite of an object: all of its sprites as
	moveq	#0,d1				;one image (rd_obj_blit)
	move.b	(a0,d5.w),d1
	beq.s	.one
	lea	(rd_sprgkey).l,a0
	move.w	(a0,d5.w*2),d2
	movem.l	d1/d5/a4,-(sp)
	bsr	rd_obj_blit
	movem.l	(sp)+,d1/d5/a4
	bne.s	.one				;(not: sprite by sprite)
	subq.w	#1,d1				;its other sprites are drawn too
	sub.w	d1,d5
	lsl.w	#3,d1
	suba.w	d1,a4
	bra.s	.n
.one	movem.l	d5/a4,-(sp)
	bsr	rd_sprite_blit
	movem.l	(sp)+,d5/a4
.n	dbf	d5,.each
.x	bra	rd_cq_flush			;(the last batch let go)

;	Sprite a4.
rd_sprite_blit
	move.w	(a4),d0
	andi.w	#$3FF,d0
	subi.w	#128,d0
	move.w	d0,(rd_sy).l			;y
	move.b	2(a4),d1
	moveq	#3,d2
	and.w	d1,d2
	addq.w	#1,d2
	move.w	d2,(rd_sch).l			;cells down
	lsr.b	#2,d1
	andi.w	#3,d1
	addq.w	#1,d1
	move.w	d1,(rd_scw).l			;cells across
	move.w	6(a4),d3
	andi.w	#$1FF,d3
	subi.w	#128,d3
	move.w	d3,(rd_sx).l			;x
	move.w	4(a4),(rd_sat).l
	; whole sprite off screen?
	cmpi.w	#SCRH,d0
	bge	.x
	move.w	d2,d4
	lsl.w	#3,d4
	add.w	d0,d4
	ble	.x
	cmp.w	(rd_w).l,d3
	bge	.x
	move.w	d1,d4
	lsl.w	#3,d4
	add.w	d3,d4
	ble	.x
	IFD	STATS
	movem.l	d0-d1/a0,-(sp)
	addq.l	#1,(rd_dbg_ntw).l		;(statistics: sprites drawn, those of new tiles)
	move.w	(rd_sat).l,d0
	andi.l	#$7FF,d0
	move.w	(rd_scw).l,d1
	mulu.w	(rd_sch).l,d1
	lea	(tc_chg).l,a0
	bftst	(a0){d0:d1}
	beq.s	.st0
	addq.l	#1,(rd_dbg_til).l
.st0	movem.l	(sp)+,d0-d1/a0
	ENDC
	bsr	rd_spr_geom
	; from the image cache: the sprite as 6 interleaved planes and a mask, the box of its pixels
	; cut into the screen by one blit (queued: the CPU goes on). Columns dropped on the left:
	; the CPU draws
	tst.w	(rd_c0).l
	beq.s	.cache
	move.w	(rd_sx).l,d0			;(the whole sprite)
	move.w	(rd_sy).l,d1
	move.w	(rd_scw).l,d2
	lsl.w	#3,d2
	move.w	(rd_sch).l,d3
	lsl.w	#3,d3
	bsr	rd_mark
	tst.w	(rd_pass).l
	bne	rd_spr_cpu
	bsr	rd_cover_rect
	bra	rd_spr_cpu
.cache	move.l	a4,d0
	subi.l	#rd_sprites,d0
	lsr.w	#3,d0
	move.w	d0,(rd_sslot).l			;(its place in the list)
	bsr	rd_sc_get			;a2 = image, a3 = mask, rd_bl0 .. rd_bp1 its box
	bra	rd_spr_cut
.x	rts

;	The sprite rd_sx, rd_sy, rd_scw, rd_sch, rd_sat on the screen: the columns drawn (rd_c0,
;	rd_colx, rd_ncol; those left of the screen margin are dropped), rd_wb, its rows on the
;	screen (rd_r0, rd_r1), its palette (rd_spal).
rd_spr_geom
	moveq	#0,d6				;first column drawn
	move.w	(rd_sx).l,d0
.lclip	cmpi.w	#-SCRX*8,d0
	bge	.lok
	addq.w	#8,d0
	addq.w	#1,d6
	bra	.lclip
.lok	move.w	d0,(rd_colx).l			;screen x of the first column drawn
	move.w	d6,(rd_c0).l
	move.w	(rd_scw).l,d0
	sub.w	d6,d0
	move.w	d0,(rd_ncol).l			;columns drawn
	addq.w	#1,d0
	lsr.w	#1,d0
	add.w	d0,d0
	move.w	d0,(rd_wb).l			;bytes a row: the columns, rounded to words (2 or 4)
	; rows on screen
	move.w	(rd_sy).l,d0
	moveq	#0,d1				;first row
	tst.w	d0
	bpl	.t
	move.w	d0,d1
	neg.w	d1
.t	move.w	(rd_sch).l,d2
	lsl.w	#3,d2				;sprite height
	move.w	#SCRH,d3
	sub.w	d0,d3				;rows left on screen
	cmp.w	d3,d2
	ble	.b
	move.w	d3,d2
.b	move.w	d1,(rd_r0).l
	move.w	d2,(rd_r1).l
	move.w	(rd_sat).l,d0
	rol.w	#3,d0
	andi.w	#3,d0
	move.w	d0,(rd_spal).l
	rts

;	The image a2, mask a3 (rd_bl0 .. rd_bp1 its box) of the sprite rd_spr_geom placed, cut into
;	the back buffer: one blit, queued.
rd_spr_cut
	; its lines with pixels, on the screen
	move.w	(rd_bl0).l,d6
	move.w	d6,d5
	add.w	(rd_bnl).l,d5
	cmp.w	(rd_r0).l,d6
	bge.s	.r0
	move.w	(rd_r0).l,d6			;first line
.r0	cmp.w	(rd_r1).l,d5
	ble.s	.r1
	move.w	(rd_r1).l,d5
.r1	sub.w	d6,d5				;lines
	ble	.x
	; the box drawn over: for the restore and (low priority) the fixups
	move.w	(rd_colx).l,d0
	add.w	(rd_bp0).l,d0
	move.w	(rd_sy).l,d1
	add.w	d6,d1
	move.w	(rd_bp1).l,d2
	sub.w	(rd_bp0).l,d2
	addq.w	#1,d2
	move.w	d5,d3
	tst.w	(rd_pass).l
	bne.s	.mk
	movem.l	d0-d3,-(sp)
	bsr	rd_cover_u
	movem.l	(sp)+,d0-d3
.mk	bsr	rd_mark_u
	; words: from the first pixel's to the one the last pixel is shifted into (the bits a row
	; shifts into the next are past the last pixel: clear in the mask)
	move.w	(rd_colx).l,d0
	add.w	(rd_xorg).l,d0			;buffer x of the image's pixel 0
	moveq	#15,d1
	and.w	d0,d1				;shift
	move.w	(rd_bp0).l,d2
	lsr.w	#4,d2				;first word
	move.w	(rd_bp1).l,d3
	add.w	d1,d3
	lsr.w	#4,d3
	sub.w	d2,d3
	addq.w	#1,d3				;words
	IFD	SPRLOG
	movem.l	d0/a0,-(sp)			;(harness: each sprite blit, NHL_DBGPORT)
	lea	(CUSTOM+$1F0).l,a0
	move.w	#$8000,(a0)
	move.w	(rd_bufi).l,(a0)
	move.w	(rd_count+2).l,(a0)
	move.w	(rd_xorg).l,(a0)
	move.w	(rd_brow0).l,(a0)
	move.w	(rd_colx).l,(a0)
	move.w	(rd_sy).l,(a0)
	move.w	(rd_r0).l,(a0)
	move.w	(rd_r1).l,(a0)
	move.w	(rd_ncol).l,(a0)
	move.w	(rd_wb).l,(a0)
	move.w	(rd_bp0).l,(a0)
	move.w	(rd_bp1).l,(a0)
	move.w	d6,(a0)
	move.w	d5,(a0)
	move.w	d3,(a0)
	movem.l	(sp)+,d0/a0
	ENDC
	move.w	(rd_wb).l,d4			;bytes a plane row of the image: 2 to 8
	move.w	d6,d7				;its first line: * 6 * wb
	cmpi.w	#4,d4
	bhi.s	.wm
	add.w	d7,d7
	add.w	d6,d7
	lsl.w	#2,d7				;(* 12)
	cmpi.w	#2,d4
	beq.s	.wl
	add.w	d7,d7				;(* 24)
	bra.s	.wl
.wm	mulu.w	d4,d7				;(objects: wider)
	mulu.w	#6,d7
.wl	adda.w	d7,a2
	adda.w	d7,a3
	lea	(a2,d2.w*2),a2
	lea	(a3,d2.w*2),a3
	bsr	rd_cq_blit			;the copper block
	sf	(rd_cqkind).l
	lsr.w	#4,d0
	add.w	d2,d0
	add.w	d0,d0				;destination byte of the first word
	ror.w	#4,d1
	move.l	#$00420000,d7
	move.w	d1,d7
	move.l	d7,(a5)+			;BLTCON1: B shift
	ori.w	#$0FCA,d7
	eori.l	#($042^$040)<<16,d7
	move.l	d7,(a5)+			;BLTCON0: A shift; A mask, B image, C, D: AB + /AC
	move.l	#$0044FFFF,(a5)+		;BLTAFWM
	move.l	#$00740000,(a5)+		;BLTADAT: what the shift brings into the first word
	CQA	$050,a3,d7			;BLTAPT
	CQA	$04C,a2,d7			;BLTBPT
	movea.l	(rd_back).l,a0
	move.w	(rd_sy).l,d1
	add.w	d6,d1
	lea	(rd_rowoff).l,a1
	adda.l	(a1,d1.w*4),a0
	adda.w	d0,a0
	move.l	a0,d7				;BLTCPT, BLTDPT
	clr.w	d7
	swap	d7
	ori.l	#$00480000,d7
	move.l	d7,(a5)+
	eori.l	#($048^$054)<<16,d7
	move.l	d7,(a5)+
	move.l	#$004A0000,d7
	move.w	a0,d7
	move.l	d7,(a5)+
	eori.l	#($04A^$056)<<16,d7
	move.l	d7,(a5)+
	add.w	d3,d3				;bytes a row
	move.w	d2,d0				;past the image's row (the word the shift goes into):
	add.w	d0,d0				;that word of the mask is masked off
	add.w	d3,d0
	move.l	#$0046FFFF,d7			;BLTALWM
	cmp.w	d4,d0
	bls.s	.lw
	clr.w	d7
.lw	move.l	d7,(a5)+
	sub.w	d3,d4
	move.l	#$00640000,d7
	move.w	d4,d7
	move.l	d7,(a5)+			;BLTAMOD
	eori.l	#($064^$062)<<16,d7
	move.l	d7,(a5)+			;BLTBMOD
	move.l	#$00600000|SBPR,d7
	sub.w	d3,d7
	move.l	d7,(a5)+			;BLTCMOD
	eori.l	#($060^$066)<<16,d7
	move.l	d7,(a5)+			;BLTDMOD
	move.w	d5,d4				;lines * 6 planes
	add.w	d4,d4
	add.w	d4,d5
	add.w	d5,d5
	CQV	$05C,d5,d7			;BLTSIZV
	lsr.w	#1,d3
	CQV	$05E,d3,d7			;BLTSIZH
	bra	rd_cq_endblit
.x	rts

;	------------------------------------------------------------------------------------------
;	Sprite image cache. A sprite's image (6 interleaved planes, rows of rd_wb bytes: its
;	columns rounded to words; the word the blitter's shift goes into is read past the row and
;	masked off) and its mask (the same layout, the mask in each plane's place) are built once
;	(in fast memory, then copied) and kept in a ring of chip RAM
;	(rd_scarena), found through a hash table by its tiles, size, flips and palette. An image is
;	used while none of its tiles was converted again (rd_tchg: the frame each tile last was)
;	after it was built and the ring has not come round to it again. The players use the same
;	few frames over and over: most sprites are found. Each place of the sprite list keeps the
;	image it had (rd_scmemo): the same sprite there in the next frame, none of its tiles
;	changed and the image still in the ring, takes it without the table.

;	a2 = the image, a3 = the mask of the sprite rd_sat, rd_scw, rd_sch (rd_wb set). Uses d0-d3,
;	d7, a1.
rd_sc_get
	moveq	#0,d0
	move.w	(rd_sat).l,d0
	andi.w	#$7FFF,d0			;tile, flips, palette (not the priority)
	move.w	(rd_scw).l,d1
	subq.w	#1,d1
	lsl.w	#2,d1
	add.w	(rd_sch).l,d1
	subq.w	#1,d1
	swap	d1
	clr.w	d1
	or.l	d1,d0				;key: size << 16 | attributes
	move.l	d0,(rd_skey).l
	; the same sprite in its place of the list in the frame before, none of its tiles
	; changed since (tc_chg) and its image still in the ring: that image
	move.w	(rd_sslot).l,d1
	lsl.w	#5,d1
	lea	(rd_scmemo).l,a1
	adda.w	d1,a1
	cmp.l	(a1),d0
	bne	.nomemo
	move.l	(rd_count).l,d1
	subq.l	#1,d1
	cmp.l	4(a1),d1
	bne	.nomemo
	moveq	#0,d1
	move.w	d0,d1
	andi.w	#$7FF,d1			;first tile
	move.w	(rd_scw).l,d2
	mulu.w	(rd_sch).l,d2			;tiles
	move.w	d1,d3
	add.w	d2,d3
	cmpi.w	#2048,d3
	bhi	.nomemo				;((wrapping round: not here)
	bftst	(tc_chg).l{d1:d2}
	bne	.nomemo
	move.l	(rd_scpos).l,d1
	sub.l	12(a1),d1
	cmpi.l	#SCARENA,d1
	bhi	.nomemo
	movea.l	8(a1),a2
	move.l	24(a1),d7
	lea	(a2,d7.l),a3
	move.l	16(a1),(rd_bl0).l
	move.l	20(a1),(rd_bp0).l
	move.l	(rd_count).l,4(a1)
	move.l	12(a1),d1			;(the oldest image used in this frame)
	cmp.l	(rd_scmin).l,d1
	bge	.xm
	move.l	d1,(rd_scmin).l
.xm	rts
.nomemo
	movem.l	d4-d6/a0/a4,-(sp)
	; its tiles hold data a DMA sent from consecutive addresses of the program (vdp_tsrc):
	; then the key is that address (and size, flips, palette: d5), so a frame of animation
	; sent again, or the same frame on another player, is found whatever its tiles
	moveq	#0,d5				;(0: the key is the tiles)
	move.w	d0,d1
	andi.w	#$7FF,d1
	lea	(vdp_tsrc).l,a0
	move.l	(a0,d1.w*4),d3
	beq.s	.tkey
	move.l	d3,d4
	move.w	(rd_scw).l,d2
	mulu.w	(rd_sch).l,d2
	subq.w	#1,d2
.cs	andi.w	#$7FF,d1
	cmp.l	(a0,d1.w*4),d4
	bne.s	.tkey
	addq.w	#1,d1
	addi.l	#32,d4
	dbf	d2,.cs
	move.l	d0,d5
	andi.l	#$000F7800,d5			;size, palette, flips
	addq.l	#1,d5
	move.l	d3,d0
.tkey	move.l	d0,d2
	eor.l	d5,d2
	mulu.l	#$9E3779B1,d2
	swap	d2
	andi.l	#SCSLOTS-1,d2
	lsl.l	#5,d2
	lea	(rd_sctab).l,a4
	adda.l	d2,a4
	; the image size, image and mask
	move.w	(rd_wb).l,d7
	mulu.w	(rd_sch).l,d7
	mulu.w	#NPLANES*8,d7			;bytes of the image (and of the mask)
	cmp.l	(a4),d0
	bne.s	.bkey
	cmp.l	24(a4),d5
	bne.s	.bkey
	move.l	(rd_scpos).l,d1
	sub.l	4(a4),d1			;ring written since
	cmpi.l	#SCARENA,d1
	bhi.s	.bring
	tst.l	d5
	bne.s	.found				;(its data cannot have changed)
	move.l	8(a4),d3			;built in this frame
	moveq	#0,d1
	move.w	d0,d1				;(the tile in bits 10-0)
	move.w	(rd_scw).l,d2
	mulu.w	(rd_sch).l,d2
	subq.w	#1,d2
	lea	(rd_tchg).l,a0
.tc	andi.w	#$7FF,d1
	cmp.l	(a0,d1.w*4),d3
	blo.s	.btile				;a tile converted since
	addq.w	#1,d1
	dbf	d2,.tc
.found	movea.l	12(a4),a2			;found
	bra	.mask
.bkey
	IFD	STATS
	addq.l	#1,(rd_dbg_x+56).l		;(statistics: built: not in the table,
	ENDC
	bra.s	.build
.bring
	IFD	STATS
	addq.l	#1,(rd_dbg_x+60).l		;the ring came round,
	ENDC
	bra.s	.build
.btile
	IFD	STATS
	addq.l	#1,(rd_dbg_x+64).l		;a tile converted since)
	ENDC
.build	move.l	d7,d1
	add.l	d1,d1				;room in the ring for image and mask
	bsr	rd_sc_alloc
	move.l	d0,(a4)
	move.l	d5,24(a4)
	move.l	d2,4(a4)
	move.l	(rd_count).l,8(a4)
	move.l	a2,12(a4)
	lea	(a2,d7.l),a3
	move.l	(rd_r0).l,-(sp)			;all its lines (r0, r1)
	clr.w	(rd_r0).l
	move.w	(rd_sch).l,d0
	lsl.w	#3,d0
	move.w	d0,(rd_r1).l
	movem.l	d7/a4,-(sp)
	bsr	rd_spr_build
	movem.l	(sp)+,d7/a4
	move.l	(sp)+,(rd_r0).l
	movea.l	12(a4),a2
	bsr	rd_sc_box
.mask	lea	(a2,d7.l),a3
	move.l	16(a4),(rd_bl0).l		;its box
	move.l	20(a4),(rd_bp0).l
	; (for this place of the list in the next frame)
	move.w	(rd_sslot).l,d1
	lsl.w	#5,d1
	lea	(rd_scmemo).l,a1
	adda.w	d1,a1
	move.l	(rd_skey).l,(a1)
	move.l	(rd_count).l,4(a1)
	move.l	a2,8(a1)
	move.l	4(a4),12(a1)
	move.l	16(a4),16(a1)
	move.l	20(a4),20(a1)
	move.l	d7,24(a1)
	move.l	4(a4),d1			;(the oldest image used in this frame)
	cmp.l	(rd_scmin).l,d1
	bge.s	.x
	move.l	d1,(rd_scmin).l
.x	movem.l	(sp)+,d4-d6/a0/a4
	rts

;	Room in the sprite image ring (rd_scarena) for d1 bytes: d2 = its place (the bytes written
;	to the ring before it), a2 = its address. A blit queued in this frame or the one before may
;	still read an image of the ring this writes over (from the lap before): if one was used
;	there, they are let finish. Uses d3, d4.
rd_sc_alloc
	move.l	(rd_scpos).l,d2
	move.l	d2,d3
	andi.l	#SCARENA-1,d3
	add.l	d1,d3
	cmpi.l	#SCARENA,d3
	bls.s	.fit
	andi.l	#-SCARENA,d2			;(the rest of this lap is left)
	addi.l	#SCARENA,d2
.fit	move.l	d2,d3
	add.l	d1,d3
	subi.l	#SCARENA,d3			;the ring below here is written over
	move.l	(rd_scmin).l,d4
	cmp.l	(rd_scmin+4).l,d4
	ble.s	.m
	move.l	(rd_scmin+4).l,d4
.m	cmp.l	d3,d4
	bge.s	.free
	IFD	STATS
	addq.l	#1,(rd_dbg_x+40).l		;(statistics: waits for the blitter here)
	ENDC
	bsr	rd_waitblit
	move.l	#$7FFFFFFF,(rd_scmin).l
	move.l	#$7FFFFFFF,(rd_scmin+4).l
.free	move.l	d2,d3
	andi.l	#SCARENA-1,d3
	lea	(rd_scarena).l,a2
	adda.l	d3,a2
	move.l	d2,d3
	add.l	d1,d3
	move.l	d3,(rd_scpos).l
	rts

;	The box of what the image a2 (d7 bytes, its mask after it) shows into its cache entry a4:
;	first line with a pixel and lines from there (0, 0: none), first and last pixel across.
;	The mask is all in each row's first 32 pixels. Keeps everything.
rd_sc_box
	movem.l	d0-d6/a0,-(sp)
	lea	(a2,d7.l),a0			;the mask
	move.w	(rd_wb).l,d6
	mulu.w	#NPLANES,d6			;bytes a line
	move.w	(rd_sch).l,d5
	lsl.w	#3,d5
	subq.w	#1,d5
	moveq	#0,d0				;the lines' masks ORed
	moveq	#-1,d1				;first line
	moveq	#0,d2				;last
	moveq	#0,d3				;line
.l	move.l	(a0),d4
	cmpi.w	#2*NPLANES,d6
	bne.s	.l4
	clr.w	d4				;(rows of 2 bytes: the next is another plane's)
.l4	tst.l	d4
	beq.s	.n
	or.l	d4,d0
	tst.w	d1
	bpl.s	.f
	move.w	d3,d1
.f	move.w	d3,d2
.n	adda.w	d6,a0
	addq.w	#1,d3
	dbf	d5,.l
	tst.w	d1
	bpl.s	.some
	clr.l	16(a4)
	clr.l	20(a4)
	bra.s	.x
.some	move.w	d1,16(a4)
	sub.w	d1,d2
	addq.w	#1,d2
	move.w	d2,18(a4)
	bfffo	d0{0:0},d1
	move.w	d1,20(a4)			;first pixel
	move.l	d0,d4
	neg.l	d4
	and.l	d0,d4				;(the lowest bit set)
	bfffo	d4{0:0},d1
	move.w	d1,22(a4)			;last pixel
.x	movem.l	(sp)+,d0-d6/a0
	rts

;	------------------------------------------------------------------------------------------
;	Native player objects. The game's addframe2 writes each player's frame as a few sprites in
;	a row of the sprite table (Satt): it notes where they begin (hal_obj_a6), hal_obj_end the
;	range and the object's key (its frame, flips, palette). The ranges go with the table when
;	it is sent (rd_obj_publish), and the renderer draws each object as one image
;	(rd_obj_blit): built once from the native tiles (Spritetiles), kept in the sprite image
;	ring and found by its key; one blit instead of one a sprite.
OBJMAX		equ	32			;objects in a table
OBJPC		equ	8			;sprites an object at most
OBJSLOTS	equ	2048			;object images in the table (a power of 2)

;	addframe2 (a3 = the object) has written its sprites from hal_obj_a6 to a6. Keeps all.
hal_obj_end
	move	sr,-(sp)
	movem.l	d0-d4/a0,-(sp)
	move.l	a6,d0
	sub.l	(hal_obj_a6).l,d0
	lsr.l	#3,d0				;its sprites
	cmpi.l	#2,d0
	blo.s	.x				;(one: drawn as it is)
	cmpi.l	#OBJPC,d0
	bhi.s	.x
	move.l	(hal_obj_a6).l,d1
	subi.l	#Satt,d1
	bmi.s	.x
	lsr.l	#3,d1				;the first
	cmpi.l	#80,d1
	bhs.s	.x
	move.w	(rd_objbn).l,d2
	cmpi.w	#OBJMAX,d2
	bhs.s	.x
	addq.w	#1,(rd_objbn).l
	; its key: the frame, the flips and palette its sprites have them by, the second team's
	; colour switch (addframe2)
	move.w	frame(a3),d3
	andi.w	#$F800,d3
	move.w	attribute(a3),d4
	eor.w	d4,d3
	andi.w	#$7800,d3
	btst	#0,attribute+1(a3)
	beq.s	.k
	bset	#15,d3
.k	move.w	frame(a3),d4
	andi.w	#$7FF,d4
	or.w	d3,d4
	lea	(rd_objb).l,a0
	lsl.w	#2,d2
	move.b	d1,(a0,d2.w)
	move.b	d0,1(a0,d2.w)
	move.w	d4,2(a0,d2.w)
.x	movem.l	(sp)+,d0-d4/a0
	rtr

;	The sprite table is sent to VRAM (hal_vdp_dma): its objects with it; the next table's from
;	none. Keeps everything.
rd_obj_publish
	movem.l	d0/a0-a1,-(sp)
	lea	(rd_objb).l,a0
	lea	(rd_objp).l,a1
	moveq	#OBJMAX-1,d0
.c	move.l	(a0)+,(a1)+
	dbf	d0,.c
	move.w	(rd_objbn).l,(rd_objpn).l
	clr.w	(rd_objbn).l
	movem.l	(sp)+,d0/a0-a1
	rts

;	rd_sprgend, rd_sprgkey: the objects of the table the sprite list was taken from, noted at
;	their last sprite (rd_snapshot: no game tick meanwhile).
rd_obj_mark
	lea	(rd_sprgend).l,a0
	moveq	#80/4-1,d0
.c	clr.l	(a0)+
	dbf	d0,.c
	tst.b	(rd_sprnsq).l
	bne.s	.x
	lea	(rd_objp).l,a0
	lea	(rd_sprgend).l,a1
	lea	(rd_sprgkey).l,a2
	move.w	(rd_objpn).l,d0
	bra.s	.e
.o	moveq	#0,d1
	moveq	#0,d2
	move.b	(a0)+,d1			;its first sprite
	move.b	(a0)+,d2			;sprites
	move.w	(a0)+,d3			;key
	add.w	d2,d1
	cmp.w	(rd_spn).l,d1
	bhi.s	.e
	move.b	d2,-1(a1,d1.w)
	move.w	d3,-2(a2,d1.w*2)
.e	dbf	d0,.o
.x	rts

;	The object whose last sprite is a4, d1 sprites (the others before it in the list), d2 its
;	key: drawn as one image, Z set; or Z clear: to be drawn sprite by sprite (a tile not
;	native, mixed priorities, too big, cut by the screen's left margin).
rd_obj_blit
	move.w	d1,(rd_on).l
	move.w	d2,(rd_okey).l
	subq.w	#1,d1
	lsl.w	#3,d1
	movea.l	a4,a5
	suba.w	d1,a5				;the first sprite
	moveq	#0,d0
	move.w	d2,d0
	mulu.w	#40503,d0
	lsr.l	#5,d0
	andi.l	#OBJSLOTS-1,d0
	lsl.l	#5,d0
	lea	(rd_octab).l,a2
	adda.l	d0,a2
	move.l	#$10000,d0			;(an entry in use)
	move.w	d2,d0
	cmp.l	(a2),d0
	bne.s	.miss
	move.l	(rd_scpos).l,d1
	sub.l	8(a2),d1
	cmpi.l	#SCARENA,d1
	bls.s	.hit
.miss	bsr	rd_obj_gather
	bne	.no
	movem.l	a2/a4-a5,-(sp)
	bsr	rd_obj_build
	movem.l	(sp)+,a2/a4-a5
	bne	.no				;(too big)
.hit
	IFD	STATS
	addq.l	#1,(rd_dbg_x+84).l		;(statistics: objects drawn as one image)
	ENDC
	move.l	8(a2),d1			;(the oldest image used in this frame)
	cmp.l	(rd_scmin).l,d1
	bge.s	.o
	move.l	d1,(rd_scmin).l
.o	; placed: the first sprite's place and the image's offset from it
	move.w	6(a5),d3
	andi.w	#$1FF,d3
	subi.w	#128,d3
	add.w	24(a2),d3
	move.w	d3,(rd_sx).l
	move.w	(a5),d0
	andi.w	#$3FF,d0
	subi.w	#128,d0
	add.w	26(a2),d0
	move.w	d0,(rd_sy).l
	move.w	28(a2),d1
	move.w	d1,(rd_scw).l
	move.w	30(a2),d2
	move.w	d2,(rd_sch).l
	move.w	4(a5),(rd_sat).l
	cmpi.w	#SCRH,d0			;all off the screen: nothing to draw
	bge	.yes
	move.w	d2,d4
	lsl.w	#3,d4
	add.w	d0,d4
	ble	.yes
	cmp.w	(rd_w).l,d3
	bge	.yes
	move.w	d1,d4
	lsl.w	#3,d4
	add.w	d3,d4
	ble	.yes
	cmpi.w	#-SCRX*8,d3			;cut by the margin: sprite by sprite
	blt	.no
	move.l	a2,-(sp)
	bsr	rd_spr_geom
	movea.l	(sp)+,a2
	move.l	16(a2),(rd_bl0).l		;its box
	move.l	20(a2),(rd_bp0).l
	movea.l	12(a2),a2			;the image
	move.w	(rd_wb).l,d0
	mulu.w	(rd_sch).l,d0
	mulu.w	#6*8,d0
	lea	(a2,d0.l),a3			;its mask
	bsr	rd_spr_cut
.yes	moveq	#0,d0				;(Z: drawn)
	rts
.no	moveq	#1,d0
	rts

;	The object's sprites (from a5, rd_on of them) into rd_opc: their tiles' source (native, in a
;	row), flips, palette, size, place from the first. Z clear if one is not native or the
;	priorities differ. Keeps a2, a4, a5.
rd_obj_gather
	move.w	4(a5),d0
	andi.w	#$8000,d0
	move.w	d0,(rd_opri).l
	move.w	(a5),d0
	andi.w	#$3FF,d0
	move.w	d0,(rd_oy0).l
	move.w	6(a5),d0
	andi.w	#$1FF,d0
	move.w	d0,(rd_ox0).l
	lea	(rd_opc).l,a1
	lea	(vdp_tsrc).l,a3
	movea.l	a5,a0
	move.w	(rd_on).l,d7
	subq.w	#1,d7
.pk	move.w	4(a0),d0			;attributes
	move.w	d0,d1
	andi.w	#$8000,d1
	cmp.w	(rd_opri).l,d1
	bne	.no
	moveq	#0,d1
	move.w	d0,d1
	andi.w	#$7FF,d1			;its first tile
	move.l	(a3,d1.l*4),d2
	subi.l	#Spritetiles,d2
	cmpi.l	#SPRTSIZE,d2
	bhs	.no
	move.l	d2,(a1)				;its source
	andi.w	#$7800,d0
	move.w	d0,4(a1)			;flips, palette
	moveq	#0,d3
	move.b	2(a0),d3
	move.b	d3,6(a1)			;size
	clr.b	7(a1)
	move.w	d3,d4
	andi.w	#3,d4
	addq.w	#1,d4
	lsr.w	#2,d3
	andi.w	#3,d3
	addq.w	#1,d3
	mulu.w	d4,d3				;tiles
	subq.w	#2,d3
	bmi.s	.t1
	addi.l	#Spritetiles,d2
.tc	addq.w	#1,d1				;the others from the next sources
	andi.w	#$7FF,d1
	addi.l	#32,d2
	cmp.l	(a3,d1.l*4),d2
	bne.s	.no
	dbf	d3,.tc
.t1	move.w	6(a0),d0
	andi.w	#$1FF,d0
	sub.w	(rd_ox0).l,d0
	move.w	d0,8(a1)			;x from the first
	move.w	(a0),d0
	andi.w	#$3FF,d0
	sub.w	(rd_oy0).l,d0
	move.w	d0,10(a1)			;y
	lea	12(a1),a1
	addq.l	#8,a0
	dbf	d7,.pk
	moveq	#0,d0
	rts
.no	moveq	#1,d0
	rts

;	The image of the object rd_opc (rd_on sprites; its key rd_okey) built into the sprite image
;	ring and the entry a2 of rd_octab. Z clear if it is too big (over 8 x 8 cells).
rd_obj_build
	move.l	a2,(rd_oent).l
	; its box, from the first sprite's place
	lea	(rd_opc).l,a0
	move.w	(rd_on).l,d7
	subq.w	#1,d7
	move.w	#$7FFF,d0			;least x
	move.w	#$7FFF,d1			;least y
	move.w	#-$8000,d2			;x past the right
	move.w	#-$8000,d3			;y below
.bx	moveq	#0,d4
	move.b	6(a0),d4			;size
	moveq	#3,d5
	and.w	d4,d5
	addq.w	#1,d5
	lsl.w	#3,d5				;height
	lsr.w	#2,d4
	andi.w	#3,d4
	addq.w	#1,d4
	lsl.w	#3,d4				;width
	move.w	8(a0),d6
	cmp.w	d0,d6
	bge.s	.b1
	move.w	d6,d0
.b1	add.w	d6,d4
	cmp.w	d2,d4
	ble.s	.b2
	move.w	d4,d2
.b2	move.w	10(a0),d6
	cmp.w	d1,d6
	bge.s	.b3
	move.w	d6,d1
.b3	add.w	d6,d5
	cmp.w	d3,d5
	ble.s	.b4
	move.w	d5,d3
.b4	lea	12(a0),a0
	dbf	d7,.bx
	move.w	d0,(rd_ominx).l
	move.w	d1,(rd_ominy).l
	sub.w	d0,d2				;width
	sub.w	d1,d3				;height
	addq.w	#7,d2
	lsr.w	#3,d2				;cells across
	addq.w	#7,d3
	lsr.w	#3,d3				;cells down
	cmpi.w	#8,d2
	bhi	.big
	cmpi.w	#8,d3
	bhi	.big
	IFD	STATS
	addq.l	#1,(rd_dbg_x+88).l		;(statistics: object images built)
	ENDC
	move.w	d2,(rd_oscw).l
	move.w	d3,(rd_osch).l
	addq.w	#1,d2
	lsr.w	#1,d2
	add.w	d2,d2
	move.w	d2,(rd_owb).l			;bytes a row (as rd_spr_geom has it)
	lsl.w	#3,d3
	move.w	d3,(rd_olines).l
	; the scratch: lines of 7 rows of 8 bytes (planes 0-3, the palette planes 4, 5, the mask)
	mulu.w	#56/4,d3
	subq.w	#1,d3
	lea	(rd_oscr).l,a0
.cl	clr.l	(a0)+
	dbf	d3,.cl
	; the sprites, the last first (the first is in front)
	move.w	(rd_on).l,d0
	subq.w	#1,d0
	mulu.w	#12,d0
	lea	(rd_opc).l,a6
	adda.w	d0,a6
.pc	move.l	a6,-(sp)
	bsr	rd_obj_piece
	movea.l	(sp)+,a6
	lea	-12(a6),a6
	cmpa.l	#rd_opc,a6
	bhs.s	.pc
	; into the ring: per line the 6 plane rows, then (the mask) the mask row 6 times
	move.w	(rd_owb).l,d1
	mulu.w	(rd_olines).l,d1
	mulu.w	#6*2,d1
	bsr	rd_sc_alloc			;d2 = its place, a2 = it
	movea.l	(rd_oent).l,a4
	move.l	#$10000,d0			;(in use) and its key
	move.w	(rd_okey).l,d0
	move.l	d0,(a4)
	clr.l	4(a4)
	move.l	d2,8(a4)
	move.l	a2,12(a4)
	move.w	(rd_ominx).l,24(a4)
	move.w	(rd_ominy).l,26(a4)
	move.w	(rd_oscw).l,28(a4)
	move.w	(rd_osch).l,30(a4)
	bsr	rd_obj_copy
	bsr	rd_obj_box
	moveq	#0,d0
	rts
.big	moveq	#1,d0
	rts

;	One sprite of an object (a6: its rd_opc entry) into the scratch (rd_oscr) at its place
;	from rd_ominx, rd_ominy. First its lines unpacked (rd_opbuf: per line the 4 planes and the
;	mask, each a long, the sprite's bytes in its low end; the tiles are native: Spritetiles has
;	a long a line, the 4 plane bytes; flipped: each byte's bits reversed, the columns and the
;	lines from the last), then each line merged into the scratch under its mask: one bit field
;	a plane.
rd_obj_piece
	moveq	#0,d0
	move.b	6(a6),d0
	moveq	#3,d1
	and.w	d0,d1
	addq.w	#1,d1				;tiles down
	lsr.w	#2,d0
	andi.w	#3,d0
	addq.w	#1,d0				;across
	move.w	d0,(rd_opw).l
	move.w	d1,d6
	lsl.w	#3,d6				;lines
	move.w	d6,(rd_oplines).l
	lsl.w	#5,d1				;bytes from one column's tiles to the next's
	ext.l	d1
	movea.l	d1,a4				;column step
	move.w	4(a6),d5			;flips (bits 11, 12), palette (13, 14)
	move.w	d5,(rd_opat).l
	move.w	10(a6),d2
	sub.w	(rd_ominy).l,d2
	mulu.w	#56,d2
	lea	(rd_oscr).l,a1
	adda.l	d2,a1
	move.l	a1,(rd_opline).l		;its first line in the scratch
	moveq	#0,d2
	move.w	8(a6),d2
	sub.w	(rd_ominx).l,d2
	move.l	d2,(rd_opx).l			;its first pixel
	lea	(Spritetiles).l,a0
	adda.l	(a6),a0				;its tiles
	lea	(rd_rev8).l,a2
	movea.w	#4,a5				;line step
	btst	#11,d5
	beq.s	.nh
	move.w	(rd_opw).l,d0			;horizontal flip: from the last column back
	subq.w	#1,d0
	mulu.w	d1,d0
	adda.l	d0,a0
	move.l	a4,d0
	neg.l	d0
	movea.l	d0,a4
.nh	subq.w	#1,d6
	btst	#12,d5
	beq.s	.nv
	move.w	d6,d0				;vertical flip: from the last line up
	lsl.w	#2,d0
	adda.w	d0,a0
	movea.w	#-4,a5
.nv	; unpacked: the column c's bytes at 4 - across + c of each long
	lea	(rd_opbuf+4).l,a1
	suba.w	(rd_opw).l,a1
	moveq	#0,d1
.ul	movea.l	a0,a3
	movea.l	a1,a6
	move.w	(rd_opw).l,d7
	subq.w	#1,d7
.uc	move.l	(a3),d0
	adda.l	a4,a3
	btst	#11,d5
	beq.s	.ur
	rol.l	#8,d0				;(flipped: each plane byte's bits reversed)
	move.b	d0,d1
	move.b	(a2,d1.w),d4
	rol.l	#8,d0
	move.b	d0,d1
	lsl.l	#8,d4
	move.b	(a2,d1.w),d4
	rol.l	#8,d0
	move.b	d0,d1
	lsl.l	#8,d4
	move.b	(a2,d1.w),d4
	rol.l	#8,d0
	move.b	d0,d1
	lsl.l	#8,d4
	move.b	(a2,d1.w),d4
	move.l	d4,d0
.ur	move.b	d0,12(a6)			;plane 3
	move.b	d0,d3
	lsr.l	#8,d0
	move.b	d0,8(a6)			;2
	or.b	d0,d3
	lsr.w	#8,d0
	move.b	d0,4(a6)			;1
	or.b	d0,d3
	swap	d0
	move.b	d0,(a6)				;0
	or.b	d0,d3
	move.b	d3,16(a6)			;the mask
	addq.l	#1,a6
	dbf	d7,.uc
	adda.l	a5,a0
	lea	20(a1),a1
	dbf	d6,.ul
	; merged: under each line's mask; inserted if it overlaps no sprite drawn before it (the
	; image is clear there)
	movea.l	4(sp),a6			;(its entry: the caller's)
	bsr	rd_obj_overlap
	lea	(rd_opbuf).l,a0
	movea.l	(rd_opline).l,a1
	move.l	(rd_opx).l,d2
	moveq	#0,d3
	move.w	(rd_opw).l,d3
	lsl.w	#3,d3				;bits
	move.w	(rd_opat).l,d6
	move.w	(rd_oplines).l,d7
	subq.w	#1,d7
	tst.b	(rd_oovl).l
	beq	.il
.ml	move.l	16(a0),d4			;the mask
	beq	.mn
	move.l	d4,d5
	not.l	d5
	bfextu	(a1){d2:d3},d0
	and.l	d5,d0
	or.l	(a0),d0
	bfins	d0,(a1){d2:d3}
	bfextu	8(a1){d2:d3},d0
	and.l	d5,d0
	or.l	4(a0),d0
	bfins	d0,8(a1){d2:d3}
	bfextu	16(a1){d2:d3},d0
	and.l	d5,d0
	or.l	8(a0),d0
	bfins	d0,16(a1){d2:d3}
	bfextu	24(a1){d2:d3},d0
	and.l	d5,d0
	or.l	12(a0),d0
	bfins	d0,24(a1){d2:d3}
	bfextu	32(a1){d2:d3},d0		;the palette planes: the mask, or nothing
	and.l	d5,d0
	btst	#13,d6
	beq.s	.p4
	or.l	d4,d0
.p4	bfins	d0,32(a1){d2:d3}
	bfextu	40(a1){d2:d3},d0
	and.l	d5,d0
	btst	#14,d6
	beq.s	.p5
	or.l	d4,d0
.p5	bfins	d0,40(a1){d2:d3}
	bfextu	48(a1){d2:d3},d0		;the mask
	or.l	d4,d0
	bfins	d0,48(a1){d2:d3}
.mn	lea	20(a0),a0
	lea	56(a1),a1
	dbf	d7,.ml
	rts
.il	move.l	16(a0),d4			;(nothing under it: inserted)
	beq.s	.in
	move.l	(a0),d0
	bfins	d0,(a1){d2:d3}
	move.l	4(a0),d0
	bfins	d0,8(a1){d2:d3}
	move.l	8(a0),d0
	bfins	d0,16(a1){d2:d3}
	move.l	12(a0),d0
	bfins	d0,24(a1){d2:d3}
	btst	#13,d6
	beq.s	.i4
	bfins	d4,32(a1){d2:d3}
.i4	btst	#14,d6
	beq.s	.i5
	bfins	d4,40(a1){d2:d3}
.i5	bfins	d4,48(a1){d2:d3}
.in	lea	20(a0),a0
	lea	56(a1),a1
	dbf	d7,.il
	rts

;	Does the sprite a6 (rd_opc) overlap one after it in the list (drawn into the image before
;	it)? rd_oovl. Keeps all but the flags.
rd_obj_overlap
	movem.l	d0-d7/a0,-(sp)
	sf	(rd_oovl).l
	bsr.s	.box
	movem.w	d0-d3,-(sp)			;its box
	lea	12(a6),a0
	move.w	(rd_on).l,d7
	mulu.w	#12,d7
	addi.l	#rd_opc,d7			;the end of the list
.o	cmpa.l	d7,a0
	bhs.s	.x
	exg	a0,a6
	bsr.s	.box
	exg	a0,a6
	cmp.w	4(sp),d0			;(apart: one's left at or past the other's right ...)
	bge.s	.n
	cmp.w	(sp),d2
	ble.s	.n
	cmp.w	6(sp),d1
	bge.s	.n
	cmp.w	2(sp),d3
	ble.s	.n
	st	(rd_oovl).l
	bra.s	.x
.n	lea	12(a0),a0
	bra.s	.o
.x	addq.l	#8,sp
	movem.l	(sp)+,d0-d7/a0
	rts
.box	moveq	#0,d4				;a6's box: d0 left, d1 top, d2 right, d3 bottom
	move.b	6(a6),d4
	moveq	#3,d5
	and.w	d4,d5
	addq.w	#1,d5
	lsl.w	#3,d5
	lsr.w	#2,d4
	andi.w	#3,d4
	addq.w	#1,d4
	lsl.w	#3,d4
	move.w	8(a6),d0
	move.w	10(a6),d1
	move.w	d0,d2
	add.w	d4,d2
	move.w	d1,d3
	add.w	d5,d3
	rts

;	The scratch (rd_oscr) into the ring at a2 in the blitter's layout: the image (per line
;	planes 0-5, rows of rd_owb bytes), then the mask (per line its row 6 times).
OBJCPR	MACRO					;one row: \1 bytes from \2(a0) to (a1)+
	IFEQ	\1-2
	move.w	\2(a0),(a1)+
	ENDC
	IFEQ	\1-4
	move.l	\2(a0),(a1)+
	ENDC
	IFEQ	\1-6
	move.l	\2(a0),(a1)+
	move.w	\2+4(a0),(a1)+
	ENDC
	IFEQ	\1-8
	move.l	\2(a0),(a1)+
	move.l	\2+4(a0),(a1)+
	ENDC
	ENDM
OBJCPM	MACRO					;the mask row of \1 bytes 6 times to (a3)+
	move.l	48(a0),d0
	move.l	52(a0),d1
	REPT	6
	IFEQ	\1-2
	swap	d0
	move.w	d0,(a3)+
	swap	d0
	ENDC
	IFEQ	\1-4
	move.l	d0,(a3)+
	ENDC
	IFEQ	\1-6
	move.l	d0,(a3)+
	swap	d1
	move.w	d1,(a3)+
	swap	d1
	ENDC
	IFEQ	\1-8
	move.l	d0,(a3)+
	move.l	d1,(a3)+
	ENDC
	ENDR
	ENDM
OBJCPL	MACRO					;all lines, rows of \1 bytes
.l\1	OBJCPR	\1,0
	OBJCPR	\1,8
	OBJCPR	\1,16
	OBJCPR	\1,24
	OBJCPR	\1,32
	OBJCPR	\1,40
	OBJCPM	\1
	lea	56(a0),a0
	dbf	d7,.l\1
	rts
	ENDM
rd_obj_copy
	lea	(rd_oscr).l,a0
	movea.l	a2,a1
	move.w	(rd_owb).l,d0
	mulu.w	(rd_olines).l,d0
	mulu.w	#6,d0
	lea	(a2,d0.l),a3			;the mask
	move.w	(rd_olines).l,d7
	subq.w	#1,d7
	move.w	(rd_owb).l,d0
	cmpi.w	#2,d0
	beq.s	.l2
	cmpi.w	#4,d0
	beq	.l4
	cmpi.w	#6,d0
	beq	.l6
	bra	.l8
	OBJCPL	2
	OBJCPL	4
	OBJCPL	6
	OBJCPL	8

;	The box of the scratch's image into the entry a4 (as rd_sc_box: first line with a pixel,
;	lines from there, first and last pixel across).
rd_obj_box
	lea	(rd_oscr+48).l,a0
	moveq	#0,d4				;the masks ORed: pixels 0-31
	moveq	#0,d5				;32-63
	moveq	#-1,d1				;first line
	moveq	#0,d2				;last
	moveq	#0,d3				;line
	move.w	(rd_olines).l,d6
	subq.w	#1,d6
.l	move.l	(a0),d0
	move.l	4(a0),d7
	or.l	d0,d4
	or.l	d7,d5
	or.l	d7,d0
	beq.s	.n
	tst.w	d1
	bpl.s	.f
	move.w	d3,d1
.f	move.w	d3,d2
.n	lea	56(a0),a0
	addq.w	#1,d3
	dbf	d6,.l
	tst.w	d1
	bpl.s	.some
	clr.l	16(a4)
	clr.l	20(a4)
	rts
.some	move.w	d1,16(a4)
	sub.w	d1,d2
	addq.w	#1,d2
	move.w	d2,18(a4)
	tst.l	d4				;first pixel
	beq.s	.f2
	bfffo	d4{0:0},d0
	bra.s	.f3
.f2	bfffo	d5{0:0},d0
	addi.w	#32,d0
.f3	move.w	d0,20(a4)
	tst.l	d5				;last pixel
	beq.s	.l2
	move.l	d5,d0
	neg.l	d0
	and.l	d5,d0
	bfffo	d0{0:0},d0
	addi.w	#32,d0
	bra.s	.l3
.l2	move.l	d4,d0
	neg.l	d0
	and.l	d4,d0
	bfffo	d0{0:0},d0
.l3	move.w	d0,22(a4)
	rts

;	The tiles of sprite rd_sat (rd_scw x rd_sch) converted, those waiting. Keeps everything.
rd_spr_tiles
	movem.l	d0-d1,-(sp)
	moveq	#0,d0
	move.w	(rd_sat).l,d0
	andi.w	#$7FF,d0
	move.w	(rd_scw).l,d1
	mulu.w	(rd_sch).l,d1
	bsr	rd_tiles_need
	movem.l	(sp)+,d0-d1
	rts

;	Draw the sprite described by rd_sx..rd_r1 straight into the back buffer: for each line the
;	tile rows of its columns are merged into one field per plane (up to 32 pixels) and written
;	with bitfield instructions under the mask.
rd_spr_cpu
	bsr	rd_spr_tiles
	bsr	rd_waitblit			;(the CPU draws into the back buffer)
	move.w	(rd_colx).l,d0
	add.w	(rd_xorg).l,d0
	move.w	d0,(rd_sbit).l			;bit offset of the first column in a screen row
	moveq	#0,d6
	btst	#0,(rd_spal+1).l
	beq.s	.p4
	moveq	#-1,d6
.p4	moveq	#0,d7
	btst	#1,(rd_spal+1).l
	beq.s	.p5
	moveq	#-1,d7
.p5	movem.l	d6-d7,(rd_spalm).l		;palette planes 4, 5: all or nothing
	; the columns' tiles (left to right as drawn)
	lea	(rd_ctiles).l,a0
	moveq	#0,d1
.ct	cmp.w	(rd_ncol).l,d1
	bge.s	.ctd
	move.w	d1,d0
	add.w	(rd_c0).l,d0
	btst	#3,(rd_sat).l			;horizontal flip
	beq.s	.nh
	move.w	(rd_scw).l,d2
	subq.w	#1,d2
	sub.w	d0,d2
	move.w	d2,d0
.nh	mulu.w	(rd_sch).l,d0
	add.w	(rd_sat).l,d0
	andi.w	#$7FF,d0
	btst	#3,(rd_sat).l
	beq.s	.nf
	bset	#11,d0
.nf	move.w	d0,(a0)+
	addq.w	#1,d1
	bra.s	.ct
.ctd	; the screen line of the first line drawn
	movea.l	(rd_back).l,a0
	move.w	(rd_sy).l,d0
	add.w	(rd_r0).l,d0
	mulu.w	#SROW,d0
	adda.l	d0,a0
	move.w	(rd_r0).l,d5
	; a run of lines in one tile row at a time: a pointer into the tile cache per column
.seg	cmp.w	(rd_r1).l,d5
	bge	.x
	move.w	d5,d0
	moveq	#8,d7				;lines left in the tile row
	suba.l	a5,a5
	addq.l	#4,a5				;source step
	btst	#4,(rd_sat).l			;vertical flip: from the other end, backwards
	beq.s	.nv
	move.w	(rd_sch).l,d0
	lsl.w	#3,d0
	subq.w	#1,d0
	sub.w	d5,d0
	moveq	#1,d7
	subq.l	#8,a5
.nv	moveq	#7,d2
	and.w	d0,d2				;line in the tile
	lsr.w	#3,d0				;tile row
	tst.l	a5
	bmi.s	.vf
	sub.w	d2,d7				;8 - line
	bra.s	.cnt
.vf	add.w	d2,d7				;line + 1
.cnt	move.w	(rd_r1).l,d3
	sub.w	d5,d3
	cmp.w	d3,d7
	ble.s	.cn
	move.w	d3,d7
.cn	add.w	d7,d5
	movea.w	d5,a1				;(next line)
	subq.w	#1,d7
	lsl.w	#2,d2				;line offset in the tile
	lea	(rd_ctiles).l,a6
	moveq	#0,d3
	move.w	(a6)+,d3
	add.w	d0,d3
	andi.w	#$FFF,d3
	lsl.l	#5,d3
	add.w	d2,d3
	lea	(tp_pl).l,a2
	adda.l	d3,a2
	move.w	(rd_ncol).l,d4
	move.w	(rd_sbit).l,d1
	subq.w	#2,d4
	bmi	.c1
	moveq	#0,d3
	move.w	(a6)+,d3
	add.w	d0,d3
	andi.w	#$FFF,d3
	lsl.l	#5,d3
	add.w	d2,d3
	lea	(tp_pl).l,a3
	adda.l	d3,a3
	tst.w	d4
	beq	.c2
	moveq	#0,d3
	move.w	(a6)+,d3
	add.w	d0,d3
	andi.w	#$FFF,d3
	lsl.l	#5,d3
	add.w	d2,d3
	lea	(tp_pl).l,a4
	adda.l	d3,a4
	subq.w	#1,d4
	beq	.c3
	moveq	#0,d3
	move.w	(a6)+,d3
	add.w	d0,d3
	andi.w	#$FFF,d3
	lsl.l	#5,d3
	add.w	d2,d3
	lea	(tp_pl).l,a6
	adda.l	d3,a6
	bra	.c4
.next	move.w	a1,d5
	bra	.seg
.x	rts

	; one column: 8 pixel fields. d2 = the line's planes (p0 p1 p2 p3), d3 = mask
.c1	move.w	(rd_spalm+2).l,d5
	move.w	(rd_spalm+6).l,d6
.l1	move.l	(a2),d2
	adda.l	a5,a2
	beq	.n1				;all transparent
	move.l	d2,d3
	swap	d3
	or.w	d2,d3
	move.w	d3,d4
	lsr.w	#8,d4
	or.b	d4,d3				;mask
	move.b	d3,d4
	not.b	d3				;keep
	rol.l	#8,d2
	bfextu	(a0){d1:8},d0
	and.b	d3,d0
	or.b	d2,d0
	bfins	d0,(a0){d1:8}
	rol.l	#8,d2
	bfextu	SBPR(a0){d1:8},d0
	and.b	d3,d0
	or.b	d2,d0
	bfins	d0,SBPR(a0){d1:8}
	rol.l	#8,d2
	bfextu	2*SBPR(a0){d1:8},d0
	and.b	d3,d0
	or.b	d2,d0
	bfins	d0,2*SBPR(a0){d1:8}
	rol.l	#8,d2
	bfextu	3*SBPR(a0){d1:8},d0
	and.b	d3,d0
	or.b	d2,d0
	bfins	d0,3*SBPR(a0){d1:8}
	move.b	d4,d2
	and.b	d5,d2
	bfextu	4*SBPR(a0){d1:8},d0
	and.b	d3,d0
	or.b	d2,d0
	bfins	d0,4*SBPR(a0){d1:8}
	and.b	d6,d4
	bfextu	5*SBPR(a0){d1:8},d0
	and.b	d3,d0
	or.b	d4,d0
	bfins	d0,5*SBPR(a0){d1:8}
.n1	lea	SROW(a0),a0
	dbf	d7,.l1
	bra	.next

	; two columns: 16 pixel fields. The two columns' plane bytes are interleaved:
	; d2 = p0 p2 words, d3 = p1 p3 words, column 0 in the high bytes
.c2	move.w	(rd_spalm+2).l,d5
	move.w	(rd_spalm+6).l,d6
.l2	move.l	(a2),d2
	adda.l	a5,a2
	move.l	(a3),d3
	adda.l	a5,a3
	move.l	d2,d0
	or.l	d3,d0
	beq	.n2				;all transparent
	move.l	d3,d0
	lsr.l	#8,d0
	eor.l	d2,d0
	andi.l	#$00FF00FF,d0
	eor.l	d0,d2
	lsl.l	#8,d0
	eor.l	d0,d3
	move.l	d2,d4
	or.l	d3,d4
	move.l	d4,d0
	swap	d0
	or.w	d0,d4				;mask
	not.w	d4				;keep
	swap	d2
	bfextu	(a0){d1:16},d0
	and.w	d4,d0
	or.w	d2,d0
	bfins	d0,(a0){d1:16}
	swap	d3
	bfextu	SBPR(a0){d1:16},d0
	and.w	d4,d0
	or.w	d3,d0
	bfins	d0,SBPR(a0){d1:16}
	swap	d2
	bfextu	2*SBPR(a0){d1:16},d0
	and.w	d4,d0
	or.w	d2,d0
	bfins	d0,2*SBPR(a0){d1:16}
	swap	d3
	bfextu	3*SBPR(a0){d1:16},d0
	and.w	d4,d0
	or.w	d3,d0
	bfins	d0,3*SBPR(a0){d1:16}
	move.w	d4,d2
	not.w	d2				;mask
	move.w	d2,d3
	and.w	d5,d2
	bfextu	4*SBPR(a0){d1:16},d0
	and.w	d4,d0
	or.w	d2,d0
	bfins	d0,4*SBPR(a0){d1:16}
	and.w	d6,d3
	bfextu	5*SBPR(a0){d1:16},d0
	and.w	d4,d0
	or.w	d3,d0
	bfins	d0,5*SBPR(a0){d1:16}
.n2	lea	SROW(a0),a0
	dbf	d7,.l2
	bra	.next

	; three or four columns: 32 pixel fields. A 4 x 4 byte transpose of the columns' lines
	; gives the plane longs d2-d5, column 0 in the high byte
.c3	movea.l	a4,a6				;(the 4th column reads the 3rd again and is cleared)
	move.w	#$FF00,(rd_c4m).l
	bra	.l4
.c4	move.w	#$FFFF,(rd_c4m).l
.l4	move.l	(a2),d2
	adda.l	a5,a2
	move.l	(a3),d3
	adda.l	a5,a3
	move.l	(a4),d4
	adda.l	a5,a4
	move.l	(a6),d5
	adda.l	a5,a6
	tst.b	(rd_c4m+1).l
	bne.s	.four
	moveq	#0,d5
.four	; bytes: (d2, d3) and (d4, d5)
	move.l	d3,d0
	lsr.l	#8,d0
	eor.l	d2,d0
	andi.l	#$00FF00FF,d0
	eor.l	d0,d2
	lsl.l	#8,d0
	eor.l	d0,d3
	move.l	d5,d0
	lsr.l	#8,d0
	eor.l	d4,d0
	andi.l	#$00FF00FF,d0
	eor.l	d0,d4
	lsl.l	#8,d0
	eor.l	d0,d5
	; words: (d2, d4) and (d3, d5)
	swap	d4
	move.w	d2,d0
	move.w	d4,d2
	move.w	d0,d4
	swap	d4
	swap	d5
	move.w	d3,d0
	move.w	d5,d3
	move.w	d0,d5
	swap	d5
	move.l	d2,d6
	or.l	d3,d6
	or.l	d4,d6
	or.l	d5,d6
	beq	.n4				;all transparent
	not.l	d6				;keep
	bfextu	(a0){d1:32},d0
	and.l	d6,d0
	or.l	d2,d0
	bfins	d0,(a0){d1:32}
	bfextu	SBPR(a0){d1:32},d0
	and.l	d6,d0
	or.l	d3,d0
	bfins	d0,SBPR(a0){d1:32}
	bfextu	2*SBPR(a0){d1:32},d0
	and.l	d6,d0
	or.l	d4,d0
	bfins	d0,2*SBPR(a0){d1:32}
	bfextu	3*SBPR(a0){d1:32},d0
	and.l	d6,d0
	or.l	d5,d0
	bfins	d0,3*SBPR(a0){d1:32}
	move.l	d6,d2
	not.l	d2				;mask
	move.l	d2,d3
	and.l	(rd_spalm).l,d2
	and.l	(rd_spalm+4).l,d3
	bfextu	4*SBPR(a0){d1:32},d0
	and.l	d6,d0
	or.l	d2,d0
	bfins	d0,4*SBPR(a0){d1:32}
	bfextu	5*SBPR(a0){d1:32},d0
	and.l	d6,d0
	or.l	d3,d0
	bfins	d0,5*SBPR(a0){d1:32}
.n4	lea	SROW(a0),a0
	dbf	d7,.l4
	bra	.next

;	Build the image (a2) and mask (a3, after the image) of the sprite described by rd_sx..rd_r1:
;	lines rd_r0 to rd_r1-1, columns rd_c0 on (rd_ncol of them), rows of rd_wb bytes per plane
;	(2 or 4). Built in fast memory (rd_sbuild), then copied in longs. Keeps a2, a3.
SPRLINE	MACRO					;one line of one column; \1 = bytes a plane row
	move.b	(a1),d3
	adda.w	d5,a1
	move.l	(a0),d0
	adda.w	d4,a0
	tst.b	d3
	beq.s	.z\@				;transparent: the cleared buffer is right
	rol.l	#8,d0
	move.b	d0,(a2)
	rol.l	#8,d0
	move.b	d0,\1(a2)
	rol.l	#8,d0
	move.b	d0,2*\1(a2)
	rol.l	#8,d0
	move.b	d0,3*\1(a2)
	move.b	d3,d1
	and.b	d6,d1
	move.b	d1,4*\1(a2)
	move.b	d3,d1
	and.b	d7,d1
	move.b	d1,5*\1(a2)
	move.b	d3,(a3)
	move.b	d3,\1(a3)
	move.b	d3,2*\1(a3)
	move.b	d3,3*\1(a3)
	move.b	d3,4*\1(a3)
	move.b	d3,5*\1(a3)
.z\@	lea	6*\1(a2),a2
	lea	6*\1(a3),a3
	ENDM

rd_spr_build
	ifd	STATS
	addq.l	#1,(rd_dbg_key).l		;(statistics: sprites built)
	endif
	bsr	rd_spr_tiles
	movem.l	a2-a3,-(sp)
	; clear both: lines * 6 * wb bytes each
	move.w	(rd_r1).l,d0
	sub.w	(rd_r0).l,d0
	mulu.w	(rd_wb).l,d0
	mulu.w	#6,d0
	lea	(rd_sbuild).l,a2
	lea	(a2,d0.w),a3
	lsr.w	#2,d0
	subq.w	#1,d0
	bmi	.x
	movea.l	a2,a0
	movea.l	a3,a1
.clr	clr.l	(a0)+
	clr.l	(a1)+
	dbf	d0,.clr
	; palette planes
	moveq	#0,d6
	btst	#0,(rd_spal+1).l
	beq.s	.p4
	moveq	#-1,d6
.p4	moveq	#0,d7
	btst	#1,(rd_spal+1).l
	beq.s	.p5
	moveq	#-1,d7
.p5	clr.w	(rd_bcol).l
.col	move.w	(rd_bcol).l,d0
	cmp.w	(rd_ncol).l,d0
	bge	.x
	add.w	(rd_c0).l,d0			;column in the sprite
	btst	#3,(rd_sat).l			;horizontal flip (bit 11)
	beq.s	.nhf
	move.w	(rd_scw).l,d1
	subq.w	#1,d1
	sub.w	d0,d1
	move.w	d1,d0
.nhf	mulu.w	(rd_sch).l,d0
	add.w	(rd_sat).l,d0
	andi.w	#$7FF,d0
	btst	#3,(rd_sat).l
	beq.s	.nf2
	bset	#11,d0
.nf2	move.w	d0,(rd_btile).l			;tile of the column's first tile row
	; tile rows
	clr.w	(rd_btr).l
.tr	move.w	(rd_btr).l,d0
	cmp.w	(rd_sch).l,d0
	bge	.ncol
	lsl.w	#3,d0				;first sprite line of the tile row
	move.w	d0,d1
	addq.w	#8,d1				;end
	cmp.w	(rd_r0).l,d0
	bge.s	.t0
	move.w	(rd_r0).l,d0
.t0	cmp.w	(rd_r1).l,d1
	ble.s	.t1
	move.w	(rd_r1).l,d1
.t1	sub.w	d0,d1				;lines in this tile row
	ble	.ntr
	move.w	d1,d2
	ifd	STATS
	ext.l	d1
	add.l	d1,(rd_dbg_nta).l		;(statistics: lines built)
	endif
	subq.w	#1,d2				;loop count
	; source tile row (vertical flip: from the other end) and line
	move.w	(rd_btr).l,d1
	move.w	d0,d3
	andi.w	#7,d3				;line in the tile
	moveq	#4,d4
	moveq	#1,d5
	btst	#4,(rd_sat).l			;vertical flip (bit 12)
	beq.s	.nvf
	move.w	(rd_sch).l,d1
	subq.w	#1,d1
	sub.w	(rd_btr).l,d1
	eori.w	#7,d3
	moveq	#-4,d4
	moveq	#-1,d5
.nvf	ext.l	d1
	add.w	(rd_btile).l,d1			;(hflip bit 11 of the tile survives the add)
	andi.l	#$FFF,d1
	lea	(tp_pl).l,a0
	move.l	d1,-(sp)
	lsl.l	#5,d1
	adda.l	d1,a0
	lea	(tp_mk).l,a1
	move.l	(sp)+,d1
	lsl.l	#3,d1
	adda.l	d1,a1
	adda.w	d3,a1
	lsl.w	#2,d3
	adda.w	d3,a0
	; destinations: line (d0 - r0), column
	sub.w	(rd_r0).l,d0
	move.w	(rd_wb).l,d1
	mulu.w	#6,d1
	mulu.w	d1,d0
	add.w	(rd_bcol).l,d0
	movem.l	a2-a3,-(sp)
	adda.w	d0,a2
	adda.w	d0,a3
	cmpi.w	#2,(rd_wb).l
	bne.s	.w4
.l2	SPRLINE	2
	dbf	d2,.l2
	bra.s	.ld
.w4
.l4	SPRLINE	4
	dbf	d2,.l4
.ld	movem.l	(sp)+,a2-a3
.ntr	addq.w	#1,(rd_btr).l
	bra	.tr
.ncol	addq.w	#1,(rd_bcol).l
	bra	.col
.x	; into chip memory: image and mask, lines * wb * 12 bytes
	move.w	(rd_r1).l,d0
	sub.w	(rd_r0).l,d0
	mulu.w	(rd_wb).l,d0
	mulu.w	#3,d0				;longs
	lea	(rd_sbuild).l,a0
	movea.l	(sp),a1
	subq.w	#1,d0
	bmi.s	.nc
.cp	move.l	(a0)+,(a1)+
	dbf	d0,.cp
.nc	movem.l	(sp)+,a2-a3
	rts

;	------------------------------------------------------------------------------------------
;	High priority plane B cells under something of low priority: draw them again on top.
FIXPL	MACRO					;plane at \1: the bitmap byte (a3) under the mask d5
	move.b	(a3),d7
	and.b	d5,d7
	bfextu	\1(a1){d1:8},d0
	and.b	d2,d0
	or.b	d7,d0
	bfins	d0,\1(a1){d1:8}
	adda.w	d3,a3
	ENDM
FIXPAL	MACRO					;palette plane at \1: all of the mask if set
	tst.b	(a3)
	sne	d7
	and.b	d5,d7
	bfextu	\1(a1){d1:8},d0
	and.b	d2,d0
	or.b	d7,d0
	bfins	d0,\1(a1){d1:8}
	adda.w	d3,a3
	ENDM

;	The high priority cells of plane B something low was drawn under (rd_cover) get their high
;	priority pixels drawn again: in scroll mode a blit each (rd_fix_blit, queued), else by the
;	CPU. A 64 cell wide plane: the screen cell rows of rd_cover, moved to plane columns, ANDed
;	with the plane rows under them in rd_hibits, give the cells (rd_fixmap); else each cell of
;	rd_hiB is looked up in rd_cover.
rd_fixups
	tst.w	(rd_scroll).l
	bne.s	.go
	bsr	rd_waitblit			;(the CPU draws into the back buffer)
.go	cmpi.w	#64,(rd_cw).l
	bne	.list
	lea	(rd_fixmap).l,a0
	moveq	#2*32-1,d0
.cf	clr.l	(a0)+
	dbf	d0,.cf
	lea	(rd_fixmap).l,a0
	lea	(rd_cover).l,a1
	lea	(rd_tmp).l,a2
	lea	(rd_hibits).l,a3
	moveq	#0,d4
	move.w	(rd_bx0).l,d4
	moveq	#7,d5
	and.w	d4,d5				;pixels into the cell (0: one plane column a screen cell)
	lsr.w	#3,d4
	neg.l	d4
	addi.l	#64,d4				;the row twice (128 bits) from here: at plane columns
	move.w	(rd_by0).l,d6
	moveq	#7,d3
	and.w	d6,d3
	sne	(rd_fixchk).l			;(here: a screen cell row is on 2 plane rows)
	lsr.w	#3,d6				;plane row of screen cell row 0
	moveq	#0,d7				;screen cell row
.sr	move.l	(a1)+,d0
	move.l	(a1)+,d1
	move.l	d0,d2
	or.l	d1,d2
	beq	.nsr
	movem.l	d0-d1,(a2)
	movem.l	d0-d1,8(a2)
	bfextu	(a2){d4:0},d0			;the covered screen cells at their plane columns
	addi.l	#32,d4
	bfextu	(a2){d4:0},d1
	tst.w	d5
	beq.s	.one
	subq.l	#1,d4				;and the column after each
	bfextu	(a2){d4:0},d2
	or.l	d2,d1
	subi.l	#32,d4
	bfextu	(a2){d4:0},d2
	or.l	d2,d0
	addq.l	#1,d4
	bra.s	.rows
.one	subi.l	#32,d4
.rows	move.w	d7,d3
	add.w	d6,d3
	andi.w	#31,d3
	lsl.w	#3,d3
	move.l	(a3,d3.w),d2
	and.l	d0,d2
	or.l	d2,(a0,d3.w)
	move.l	4(a3,d3.w),d2
	and.l	d1,d2
	or.l	d2,4(a0,d3.w)
	tst.b	(rd_fixchk).l
	beq.s	.nsr
	addq.w	#8,d3
	andi.w	#31*8,d3
	move.l	(a3,d3.w),d2
	and.l	d0,d2
	or.l	d2,(a0,d3.w)
	move.l	4(a3,d3.w),d2
	and.l	d1,d2
	or.l	d2,4(a0,d3.w)
.nsr	addq.w	#1,d7
	cmpi.w	#SCRH/8,d7
	blt	.sr
	IFD	VERIFY
	bsr	rd_fixverify
	ENDC
	; the cells, row by row
	sf	(rd_fixchk).l
	tst.w	(rd_scroll).l
	bne	rd_fix_runs
	moveq	#0,d5				;row
.fr	movem.l	(a0),d0-d1
	addq.l	#8,a0
	moveq	#0,d4				;column of bit 31 of d0
.fl	tst.l	d0
	bne.s	.fb
	move.l	d1,d0				;the right half
	moveq	#0,d1
	addi.w	#32,d4
	cmpi.w	#64,d4
	blo.s	.fl
	bra.s	.fn
.fb	bfffo	d0{0:0},d2
	bfclr	d0{d2:1}
	tst.w	(rd_scroll).l
	beq.s	.f1
	btst	#0,d2
	bne.s	.f1
	addq.w	#1,d2				;(the blit draws the word: the cell next to it too)
	bfclr	d0{d2:1}
	subq.w	#1,d2
.f1	movem.l	d0-d1/d4-d5/a0,-(sp)
	add.w	d2,d4
	bsr	rd_fixcell
	movem.l	(sp)+,d0-d1/d4-d5/a0
	bra.s	.fl
.fn	addq.w	#1,d5
	cmpi.w	#32,d5
	blo	.fr
	rts
.list	tst.w	(rd_hiBok).l
	bne.s	.lok
	bsr	rd_list_hiB
.lok	st	(rd_fixchk).l			;every high priority cell, if covered
	move.w	(rd_hiBn).l,d7
	subq.w	#1,d7
	bmi	.x
	lea	(rd_hiB).l,a4
.each	move.w	(a4)+,d4			;column
	move.w	(a4)+,d5			;row
	bsr	rd_fixcell
	dbf	d7,.each
.x	rts

;	Plane B cell d4 (column), d5 (row): if it is on the screen (and, with rd_fixchk set, under a
;	cell of rd_cover), its high priority pixels are drawn again. Keeps everything.
	IFD	VERIFY
;	Debug: every high priority cell the search through rd_hiB and rd_iscovered would draw again
;	must be in rd_fixmap: else rd_vfail = frame, $FD, column (once).
rd_fixverify
	movem.l	d0-d7/a0-a4,-(sp)
	move.w	(rd_hiBn).l,d7
	subq.w	#1,d7
	bmi	.x
	lea	(rd_hiB).l,a4
.each	move.w	(a4)+,d4
	move.w	(a4)+,d5
	; screen position (wrapping)
	move.w	d4,d0
	lsl.w	#3,d0
	sub.w	(rd_bx0).l,d0
	move.w	(rd_cw).l,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	cmp.w	(rd_w).l,d0
	blt	.xok
	sub.w	d1,d0
	subq.w	#1,d0				;- plane width
	cmpi.w	#-8,d0
	ble	.next
.xok	move.w	d5,d2
	lsl.w	#3,d2
	sub.w	(rd_by0).l,d2
	move.w	(rd_ch).l,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d2
	cmpi.w	#SCRH,d2
	blt	.yok
	sub.w	d1,d2
	subq.w	#1,d2
	cmpi.w	#-8,d2
	ble	.next
.yok	bsr	rd_iscovered
	beq	.next
	move.w	d5,d0
	lsl.w	#6,d0
	add.w	d4,d0
	ext.l	d0
	lea	(rd_fixmap).l,a0
	bftst	(a0){d0:1}
	bne	.next
	tst.l	(rd_vfail).l
	bne	.next
	move.w	(rd_count+2).l,(rd_vfail).l
	move.b	#$FD,(rd_vfail+2).l
	move.b	d4,(rd_vfail+3).l
.next	dbf	d7,.each
.x	movem.l	(sp)+,d0-d7/a0-a4
	rts
	ENDC

rd_fixcell
	movem.l	d0-d7/a0-a4,-(sp)
	; screen position (wrapping)
	move.w	d4,d0
	lsl.w	#3,d0
	sub.w	(rd_bx0).l,d0
	move.w	(rd_cw).l,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	cmp.w	(rd_w).l,d0
	blt	.xok
	sub.w	d1,d0
	subq.w	#1,d0				;- plane width
	cmpi.w	#-8,d0
	ble	.next
.xok	move.w	d5,d2
	lsl.w	#3,d2
	sub.w	(rd_by0).l,d2
	move.w	(rd_ch).l,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d2
	cmpi.w	#SCRH,d2
	blt	.yok
	sub.w	d1,d2
	subq.w	#1,d2
	cmpi.w	#-8,d2
	ble	.next
.yok	tst.b	(rd_fixchk).l
	beq.s	.go
	bsr	rd_iscovered			;under something low?
	beq	.next
.go	tst.w	(rd_scroll).l
	beq.s	.cpu
	bsr	rd_fix_blit
	bra	.next
.cpu
	; redraw from the bitmap (rows of 6 plane rows, then the mask bitmap): its lines on screen
	move.w	(rd_cw).l,d3
	moveq	#0,d6				;first line
	tst.w	d2
	bpl	.top
	move.w	d2,d6
	neg.w	d6
.top	move.w	#SCRH,d7
	sub.w	d2,d7				;lines to the screen bottom
	cmpi.w	#8,d7
	ble	.bot
	moveq	#8,d7
.bot	sub.w	d6,d7				;lines
	subq.w	#1,d7
	bmi	.next
	add.w	d6,d2
	mulu.w	#SROW,d2
	movea.l	(rd_back).l,a1
	adda.l	d2,a1
	move.w	d0,d1
	add.w	(rd_xorg).l,d1			;bit offset
	ext.l	d1
	lsl.w	#3,d5
	add.w	d6,d5				;plane pixel row
	mulu.w	d3,d5
	lea	(mkB).l,a2
	adda.l	d5,a2
	adda.w	d4,a2
	mulu.w	#6,d5
	lea	(bmB).l,a0
	adda.l	d5,a0
	adda.w	d4,a0
	move.w	d3,d6
	mulu.w	#6,d6				;bitmap row
	move.w	d7,d4
.row	move.b	(a2),d5				;mask
	beq	.nr
	move.b	d5,d2
	not.b	d2				;keep
	movea.l	a0,a3
	FIXPL	0
	FIXPL	SBPR
	FIXPL	2*SBPR
	FIXPL	3*SBPR
	FIXPAL	4*SBPR
	FIXPAL	5*SBPR
.nr	lea	SROW(a1),a1
	adda.w	d6,a0
	adda.w	d3,a2
	dbf	d4,.row
.next	movem.l	(sp)+,d0-d7/a0-a4
	rts

;	Scroll mode: queue the redraw of plane B's high priority pixels of cell d4 (column), d5
;	(row), at screen line d2: the bitmap through its mask (mkB6), the cell's word, no shift
;	(the buffer holds the plane at its own columns). Its neighbour in the word is redrawn too:
;	high priority plane B pixels are right over anything drawn before the high pass. Keeps
;	everything.
rd_fix_blit
	movem.l	d0-d1/a0-a2/a5-a6,-(sp)
	move.w	d4,d0
	andi.w	#$FFFE,d0			;the word's byte
	move.w	d5,d1
	mulu.w	#8*64*NPLANES,d1		;the bitmap's row (64 cells across)
	lea	(bmB).l,a0
	adda.l	d1,a0
	adda.w	d0,a0
	lea	(mkB6).l,a1
	adda.l	d1,a1
	adda.w	d0,a1
	move.w	(rd_brow0).l,d1
	add.w	d2,d1
	mulu.w	#SROW,d1
	movea.l	(rd_buf).l,a2
	adda.l	d1,a2
	lea	SCRX(a2,d0.w),a2
	moveq	#1,d1				;(one word)
	bsr	rd_fix_cq
	movem.l	(sp)+,d0-d1/a0-a2/a5-a6
	rts

;	The fixup blit (rd_fix_blit, rd_fix_runs): the bitmap a0 through its mask a1 over the buffer
;	a2, d1 words across, 8 lines; its copper block. Uses d0-d1, a0, a5-a6.
rd_fix_cq
	bsr	rd_cq_blit
	cmpi.b	#2,(rd_cqkind).l
	beq.s	.k
	move.l	#$00400FCA,(a5)+		;BLTCON0: A mask, B bitmap, C, D: AB + /AC (once for
	move.l	#$00420000,(a5)+		;the fixups in a row)
	move.l	#$0044FFFF,(a5)+
	move.l	#$0046FFFF,(a5)+
	move.b	#2,(rd_cqkind).l
.k	CQA	$050,a1,d0			;BLTAPT: the mask
	CQA	$054,a2,d0			;BLTDPT
	CQA	$048,a2,d0			;BLTCPT
	CQA	$04C,a0,d0			;BLTBPT: the bitmap
	move.l	#$00640000|64,d0
	sub.w	d1,d0
	sub.w	d1,d0
	move.l	d0,(a5)+			;BLTAMOD
	eori.l	#($064^$062)<<16,d0
	move.l	d0,(a5)+			;BLTBMOD
	move.l	#$00600000|SBPR,d0
	sub.w	d1,d0
	sub.w	d1,d0
	move.l	d0,(a5)+			;BLTCMOD
	eori.l	#($060^$066)<<16,d0
	move.l	d0,(a5)+			;BLTDMOD
	move.l	#$005C0000|(8*NPLANES),(a5)+	;BLTSIZV
	CQV	$05E,d1,d0			;BLTSIZH
	bra	rd_cq_endblit

;	Scroll mode, 64 cells across (the screen's columns do not wrap there): each plane row's
;	cells of rd_fixmap (a0) as words (2 cells each) on the screen, and each run of them one
;	blit: the bitmap through its mask over the buffer (as rd_fix_blit).
rd_fix_runs
	; the words on the screen: those of plane x bx0 to bx0 + width - 1
	move.w	(rd_bx0).l,d6
	move.w	d6,d7
	add.w	(rd_w).l,d7
	subq.w	#1,d7
	lsr.w	#4,d6
	lsr.w	#4,d7
	sub.w	d6,d7
	addq.w	#1,d7
	moveq	#0,d3
	bfset	d3{d6:d7}
	lea	(rd_pairtab).l,a1
	moveq	#0,d5				;row
.r	movem.l	(a0)+,d0-d1			;its cells
	move.l	d0,d2
	or.l	d1,d2
	beq	.nr
	moveq	#0,d2				;its words
	moveq	#3,d7
.p0	rol.l	#8,d0
	moveq	#0,d6
	move.b	d0,d6
	lsl.l	#4,d2
	or.b	(a1,d6.w),d2
	dbf	d7,.p0
	moveq	#3,d7
.p1	rol.l	#8,d1
	moveq	#0,d6
	move.b	d1,d6
	lsl.l	#4,d2
	or.b	(a1,d6.w),d2
	dbf	d7,.p1
	and.l	d3,d2
	beq	.nr
	; the row's screen line (wrapping), if on the screen
	move.w	d5,d4
	lsl.w	#3,d4
	sub.w	(rd_by0).l,d4
	andi.w	#255,d4				;(the plane is 256 lines)
	cmpi.w	#SCRH,d4
	blt.s	.on
	subi.w	#256,d4
	cmpi.w	#-8,d4
	ble	.nr
.on	; the runs of words
.run	bfffo	d2{0:0},d0			;first
	move.l	d2,d1
	not.l	d1
	bfffo	d1{d0:0},d1			;(first after it not to draw, 32 or more: none)
	cmpi.w	#32,d1
	bls.s	.e
	moveq	#32,d1
.e	sub.w	d0,d1				;words
	bfclr	d2{d0:d1}
	bsr.s	.blit
	tst.l	d2
	bne.s	.run
.nr	addq.w	#1,d5
	cmpi.w	#32,d5
	blo	.r
	bra	rd_cq_flush			;(the last batch let go)
	; words d0 (first), d1 (how many) of plane row d5, at screen line d4
.blit	movem.l	d0-d2/a0-a2/a5-a6,-(sp)
	add.w	d0,d0				;its byte
	move.w	d5,d2
	mulu.w	#8*64*NPLANES,d2		;the bitmap's row (64 cells across)
	lea	(bmB).l,a0
	adda.l	d2,a0
	adda.w	d0,a0
	lea	(mkB6).l,a1
	adda.l	d2,a1
	adda.w	d0,a1
	move.w	(rd_brow0).l,d2
	add.w	d4,d2
	mulu.w	#SROW,d2
	movea.l	(rd_buf).l,a2
	adda.l	d2,a2
	lea	SCRX(a2,d0.w),a2
	bsr	rd_fix_cq
	movem.l	(sp)+,d0-d2/a0-a2/a5-a6
	rts

;	(rd_fix_runs) A byte of 8 cells (bit 7 the first) to 4 words of 2 cells (bit 3 the first).
rd_pairtab
	dc.b	0,1,1,1,2,3,3,3,2,3,3,3,2,3,3,3
	dc.b	4,5,5,5,6,7,7,7,6,7,7,7,6,7,7,7
	dc.b	4,5,5,5,6,7,7,7,6,7,7,7,6,7,7,7
	dc.b	4,5,5,5,6,7,7,7,6,7,7,7,6,7,7,7
	dc.b	8,9,9,9,10,11,11,11,10,11,11,11,10,11,11,11
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15
	dc.b	8,9,9,9,10,11,11,11,10,11,11,11,10,11,11,11
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15
	dc.b	8,9,9,9,10,11,11,11,10,11,11,11,10,11,11,11
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15
	dc.b	12,13,13,13,14,15,15,15,14,15,15,15,14,15,15,15

;	Z clear if a screen cell under the 8x8 box at (d0, d2) is marked in rd_cover. Keeps d0-d5.
rd_iscovered
	movem.l	d0-d5/a0,-(sp)
	move.w	d0,d4				;x0
	move.w	d0,d5
	addq.w	#7,d5				;x1
	move.w	d2,d1				;y0
	move.w	d2,d3
	addq.w	#7,d3				;y1
	asr.w	#3,d4
	asr.w	#3,d5
	asr.w	#3,d1
	asr.w	#3,d3
	tst.w	d4
	bpl	.1
	moveq	#0,d4
.1	tst.w	d1
	bpl	.2
	moveq	#0,d1
.2	cmpi.w	#39,d5
	ble	.3
	moveq	#39,d5
.3	cmpi.w	#27,d3
	ble	.4
	moveq	#27,d3
.4	sub.w	d4,d5
	bmi	.no
	addq.w	#1,d5				;cells across (1 or 2)
	ext.l	d4				;(a bit field offset is a long)
	lea	(rd_cover).l,a0
	lea	(a0,d1.w*8),a0
	sub.w	d1,d3				;rows - 1 (0 or 1)
	bmi	.no
.r	bfextu	(a0){d4:d5},d0
	bne	.yes
	addq.l	#8,a0
	dbf	d3,.r
.no	movem.l	(sp)+,d0-d5/a0
	moveq	#0,d6				;Z set
	rts
.yes	movem.l	(sp)+,d0-d5/a0
	moveq	#1,d6				;Z clear
	rts

	section	bss,bss
rd_wy0		ds.w	1
rd_wy1		ds.w	1
rd_wx0		ds.w	1
rd_wx1		ds.w	1
rd_wwidth	ds.w	1
rd_ax0		ds.w	1
rd_ay0		ds.w	1
rd_rowc		ds.w	1
rd_sy		ds.w	1
rd_sx		ds.w	1
rd_sch		ds.w	1
rd_scw		ds.w	1
rd_sat		ds.w	1
rd_spal		ds.w	1
rd_colx		ds.w	1
rd_ctile	ds.l	1
rd_fixchk	ds.b	1			;rd_fixcell: look in rd_cover
	even
rd_sh		ds.w	1
rd_sor		ds.w	1
rd_c2pw		ds.w	1
rd_c2py		ds.w	1
hal_vdp_gen	ds.l	1

	section	game,code

;	==========================================================================================
;	Fallback: per line into the chunky buffer (bits 0-5 CRAM index, 6 plane priority, 7 sprite),
;	then chunky to planar. Tiles are read straight from VRAM.
rd_chunky
	moveq	#0,d7
.line	bsr	rd_line
	addq.w	#1,d7
	cmpi.w	#SCRH,d7
	bne	.line
	bsr	rd_sprites_chunky
	bra	rd_c2p

;	Row d6 (0-7) of tile d0 (tile | hflip << 11) as 8 pixel bytes in rd_rowbuf; d3 = 0 if the
;	row is transparent, 1 if opaque, 2 mixed. Keeps all other registers.
rd_row8
	movem.l	d0-d2/a0-a1,-(sp)
	move.l	d0,d1
	andi.l	#$7FF,d1
	lsl.l	#5,d1
	moveq	#0,d2
	move.w	d6,d2
	lsl.w	#2,d2
	add.l	d2,d1
	lea	(vdp_vram).l,a0
	move.l	(a0,d1.l),d1			;8 nibbles
	moveq	#0,d3
	tst.l	d1
	beq	.cls
	move.l	d1,d2
	andi.l	#$77777777,d2
	addi.l	#$77777777,d2
	or.l	d1,d2
	andi.l	#$88888888,d2
	moveq	#2,d3
	cmpi.l	#$88888888,d2
	bne	.cls
	moveq	#1,d3
.cls	lea	(rd_rowbuf).l,a1
	lea	(rd_nibtab).l,a0
	btst	#11,d0
	beq	.n
	lea	(rd_revtab).l,a0
	; flipped: bytes in reverse order through the swapped table
	moveq	#0,d2
	moveq	#3,d0
.f	move.b	d1,d2
	move.w	(a0,d2.w*2),(a1)+
	lsr.l	#8,d1
	dbf	d0,.f
	bra	.x
.n	moveq	#0,d2
	moveq	#3,d0
.nl	rol.l	#8,d1
	move.b	d1,d2
	move.w	(a0,d2.w*2),(a1)+
	dbf	d0,.nl
.x	movem.l	(sp)+,d0-d2/a0-a1
	rts

;	One line, d7 = y: plane B, then plane A or the window.
rd_line
	lea	(chunky).l,a6
	move.w	d7,d0
	mulu.w	#CHPITCH,d0
	adda.l	d0,a6
	lea	(vdp_regs).l,a5
	moveq	#0,d0
	move.b	13(a5),d0
	andi.w	#$3F,d0
	lsl.l	#8,d0
	lsl.l	#2,d0				;hscroll table
	move.b	11(a5),d1
	andi.w	#3,d1
	beq	.hsdone
	move.w	d7,d2
	cmpi.w	#2,d1
	bne	.hsline
	andi.w	#$FFF8,d2
.hsline	andi.l	#$FFFF,d2
	lsl.l	#2,d2
	add.l	d2,d0
.hsdone	lea	(vdp_vram).l,a0
	andi.l	#$FFFF,d0
	move.l	(a0,d0.l),d6			;A scroll : B scroll
	moveq	#0,d0
	move.b	4(a5),d0
	andi.w	#7,d0
	lsl.l	#8,d0
	lsl.l	#5,d0
	move.w	d6,d1
	moveq	#2,d2
	moveq	#0,d3
	bsr	rd_plane
	move.b	18(a5),d0
	move.b	d0,d1
	andi.w	#$1F,d1
	lsl.w	#3,d1
	tst.b	d0
	bmi	.down
	cmp.w	d1,d7
	blt	rd_winline
	bra	.hwin
.down	cmp.w	d1,d7
	bge	rd_winline
.hwin	move.b	17(a5),d0
	andi.w	#$1F,d0
	bne	rd_line_split
	tst.b	17(a5)
	bmi	rd_winline
	moveq	#0,d0
	move.b	2(a5),d0
	andi.w	#$38,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	swap	d6
	move.w	d6,d1
	moveq	#0,d2
	moveq	#1,d3
	bra	rd_plane

rd_winline
	bsr	rd_winbase
	moveq	#-1,d1
	moveq	#1,d3
	bra	rd_plane

rd_winbase
	moveq	#0,d0
	move.b	3(a5),d0
	move.b	12(a5),d1
	andi.b	#$81,d1
	beq	.32
	andi.w	#$3C,d0
	bra	.b
.32	andi.w	#$3E,d0
.b	lsl.l	#8,d0
	lsl.l	#2,d0
	rts

rd_line_split
	lsl.w	#4,d0
	move.w	d0,-(sp)
	tst.b	17(a5)
	bmi	.right
	move.w	(sp),(rd_clipx0).l
	move.w	(rd_w).l,(rd_clipx1).l
	bsr	.drawA
	clr.w	(rd_clipx0).l
	move.w	(sp)+,(rd_clipx1).l
	bra	.win
.right	clr.w	(rd_clipx0).l
	move.w	(sp),(rd_clipx1).l
	bsr	.drawA
	move.w	(sp)+,(rd_clipx0).l
	move.w	(rd_w).l,(rd_clipx1).l
.win	bsr	rd_winbase
	moveq	#-1,d1
	moveq	#2,d3
	bra	rd_plane
.drawA	moveq	#0,d0
	move.b	2(a5),d0
	andi.w	#$38,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	move.l	d6,d1
	swap	d1
	moveq	#0,d2
	moveq	#2,d3
	bra	rd_plane

;	One plane line into the chunky line a6. d0 = name table, d1 = hscroll (-1: window),
;	d2 = vsram byte offset, d3 = 0 opaque, 1 transparent, 2 transparent and clipped,
;	d7 = y, a5 = regs. Keeps d6, d7, a5, a6.
rd_plane
	movem.l	d6-d7/a5-a6,-(sp)
	lea	(vdp_vram).l,a0
	adda.l	d0,a0
	move.w	d3,(rd_mode).l
	cmpi.w	#-1,d1
	bne	.scrolled
	move.w	(rd_cells).l,d4
	moveq	#5,d5
	cmpi.w	#41,d4
	bne	.w32
	moveq	#6,d5
.w32	moveq	#0,d1
	move.w	d7,d2
	move.w	#$FFFF,d3
	bra	.go
.scrolled
	move.b	16(a5),d4
	moveq	#5,d5
	btst	#0,d4
	beq	.wa
	moveq	#6,d5
	btst	#1,d4
	beq	.wa
	moveq	#7,d5
.wa	moveq	#5,d3
	btst	#4,d4
	beq	.ha
	moveq	#6,d3
	btst	#5,d4
	beq	.ha
	moveq	#7,d3
.ha	lea	(vdp_vsram).l,a1
	move.w	(a1,d2.w),d2
	add.w	d7,d2
	moveq	#3,d4
	add.w	d3,d4
	moveq	#0,d0
	bset	d4,d0
	subq.w	#1,d0
	and.w	d0,d2
	neg.w	d1
	moveq	#3,d4
	add.w	d5,d4
	moveq	#0,d3
	bset	d4,d3
	subq.w	#1,d3
.go	and.w	d3,d1
	move.w	d2,d0
	lsr.w	#3,d0
	lsl.w	d5,d0
	add.w	d0,d0
	lea	(a0,d0.w),a1			;row of entries
	andi.w	#7,d2				;line in tile
	move.w	d2,(rd_tline).l
	move.w	d1,d0
	andi.w	#7,d0
	lea	CHLEFT(a6),a2
	suba.w	d0,a2
	lsr.w	#3,d1
	moveq	#1,d0
	lsl.w	d5,d0
	subq.w	#1,d0
	move.w	d0,d5				;cell mask
	move.w	(rd_cells).l,d4
	subq.w	#1,d4
	lea	(rd_attr).l,a4
	lea	(rd_rowbuf).l,a3
.tile	move.w	d1,d0
	add.w	d0,d0
	move.w	(a1,d0.w),d0
	move.w	d0,d6
	rol.w	#3,d6
	andi.w	#7,d6
	move.l	(a4,d6.w*4),d7			;palette / priority bits
	move.w	(rd_tline).l,d6
	btst	#12,d0
	beq	.nv
	eori.w	#7,d6
.nv	andi.l	#$FFF,d0
	bsr	rd_row8				;rd_rowbuf, d3 = class
	tst.w	(rd_mode).l
	bne	.trans
	; opaque layer: transparent pixels keep the palette (backdrop), never the priority
	cmpi.b	#1,d3
	beq	.ofast
	btst	#6,d7
	beq	.ofast
	movea.l	a3,a0
	moveq	#7,d6
.opix	move.b	(a0)+,d3
	beq	.oz
	or.b	d7,d3
	move.b	d3,(a2)+
	dbf	d6,.opix
	bra	.next
.oz	move.b	d7,d3
	andi.b	#$30,d3
	move.b	d3,(a2)+
	dbf	d6,.opix
	bra	.next
.ofast	move.l	(a3),d6
	or.l	d7,d6
	move.l	d6,(a2)+
	move.l	4(a3),d6
	or.l	d7,d6
	move.l	d6,(a2)+
	bra	.next
.trans	tst.b	d3
	bne	.tdraw
	addq.l	#8,a2
	bra	.next
.tdraw	movem.l	d1/d4,-(sp)
	move.l	a2,d1
	sub.l	a6,d1
	subi.w	#CHLEFT,d1			;screen x
	movea.l	a3,a0
	moveq	#7,d4
.tp	move.b	(a0)+,d3
	beq	.tn
	cmpi.w	#2,(rd_mode).l
	bne	.tnc
	cmp.w	(rd_clipx0).l,d1
	blt	.tn
	cmp.w	(rd_clipx1).l,d1
	bge	.tn
.tnc	btst	#6,d7
	bne	.tw
	btst	#6,(a2)
	bne	.tn
.tw	or.b	d7,d3
	move.b	d3,(a2)
.tn	addq.l	#1,a2
	addq.w	#1,d1
	dbf	d4,.tp
	movem.l	(sp)+,d1/d4
.next	addq.w	#1,d1
	and.w	d5,d1
	dbf	d4,.tile
	movem.l	(sp)+,d6-d7/a5-a6
	rts

;	Sprites into the chunky buffer, last first (the list from rd_snapshot).
rd_sprites_chunky
	move.w	(rd_spn).l,d5
	lea	(rd_sprites).l,a1
	move.w	d5,d0
	lsl.w	#3,d0
	adda.w	d0,a1
	subq.w	#1,d5
	bmi	.x
.each	subq.l	#8,a1
	movem.l	d5/a1,-(sp)
	bsr	rd_sprite_chunky
	movem.l	(sp)+,d5/a1
	dbf	d5,.each
.x	rts

rd_sprite_chunky
	move.w	(a1),d0
	andi.w	#$3FF,d0
	subi.w	#128,d0
	move.b	2(a1),d1
	moveq	#3,d2
	and.w	d1,d2
	addq.w	#1,d2
	lsr.b	#2,d1
	andi.w	#3,d1
	addq.w	#1,d1
	move.w	4(a1),d3
	move.w	6(a1),d4
	andi.w	#$1FF,d4
	subi.w	#128,d4
	cmpi.w	#SCRH,d0
	bge	.out
	move.w	d2,d5
	lsl.w	#3,d5
	add.w	d0,d5
	ble	.out
	cmp.w	(rd_w).l,d4
	bge	.out
	move.w	d1,d5
	lsl.w	#3,d5
	add.w	d4,d5
	ble	.out
	move.w	d3,d5
	rol.w	#3,d5
	andi.w	#3,d5
	lsl.w	#4,d5
	ori.w	#$80,d5
	move.w	d5,(rd_sor).l
	move.w	d2,d5
	lsl.w	#3,d5
	subq.w	#1,d5
	move.w	d5,(rd_sh).l
	move.w	d1,(rd_scw).l
	move.w	d2,(rd_sch).l
	move.w	d0,(rd_sy).l
	move.w	d4,(rd_sx).l
	move.w	d3,(rd_sat).l
	moveq	#0,d6
.row	move.w	(rd_sy).l,d0
	add.w	d6,d0
	bmi	.nrow
	cmpi.w	#SCRH,d0
	bge	.out
	lea	(chunky).l,a2
	mulu.w	#CHPITCH,d0
	adda.l	d0,a2
	move.w	(rd_sx).l,d0
	lea	CHLEFT(a2,d0.w),a2
	move.w	d6,d7
	move.w	(rd_sat).l,d3
	btst	#12,d3
	beq	.nvf
	move.w	(rd_sh).l,d7
	sub.w	d6,d7
.nvf	moveq	#0,d1
.col	move.w	d1,d0
	btst	#11,d3
	beq	.nhf
	move.w	(rd_scw).l,d0
	subq.w	#1,d0
	sub.w	d1,d0
.nhf	mulu.w	(rd_sch).l,d0
	move.w	d7,d2
	lsr.w	#3,d2
	add.w	d2,d0
	add.w	d3,d0
	andi.l	#$7FF,d0
	btst	#11,d3
	beq	.nf2
	bset	#11,d0
.nf2	move.l	d6,-(sp)
	move.w	d7,d6
	andi.w	#7,d6
	move.l	d3,-(sp)
	bsr	rd_row8
	tst.b	d3
	movem.l	(sp)+,d3
	movem.l	(sp)+,d6
	beq	.ncol
	lea	(rd_rowbuf).l,a0
	move.w	(rd_sx).l,d0
	move.w	d1,d2
	lsl.w	#3,d2
	add.w	d2,d0
	movea.l	a2,a3
	adda.w	d2,a3
	moveq	#7,d4
.px	move.b	(a0)+,d2
	beq	.pn
	tst.w	d0
	bmi	.pn
	cmp.w	(rd_w).l,d0
	bge	.pn
	btst	#15,d3
	bne	.pw
	btst	#6,(a3)
	bne	.pn
.pw	or.b	(rd_sor+1).l,d2
	move.b	(a3),d5
	andi.b	#$40,d5
	or.b	d5,d2
	btst	#15,d3
	beq	.pw2
	ori.b	#$40,d2
.pw2	move.b	d2,(a3)
.pn	addq.l	#1,a3
	addq.w	#1,d0
	dbf	d4,.px
.ncol	addq.w	#1,d1
	cmp.w	(rd_scw).l,d1
	blt	.col
.nrow	addq.w	#1,d6
	cmp.w	(rd_sh).l,d6
	ble	.row
.out	rts

;	Chunky to planar, 16 pixels at a time into the 6 interleaved planes of the back buffer.
MERGE	MACRO					;\1 = a, \2 = b, \3 = shift, \4 = mask
	move.l	\1,d4
	lsr.l	#\3,d4
	eor.l	\2,d4
	and.l	\4,d4
	eor.l	d4,\2
	lsl.l	#\3,d4
	eor.l	d4,\1
	ENDM

MERGE16	MACRO
	move.l	\1,d4
	swap	d4
	eor.l	\2,d4
	and.l	#$0000FFFF,d4
	eor.l	d4,\2
	swap	d4
	eor.l	d4,\1
	ENDM

rd_c2p
	lea	(chunky+CHLEFT).l,a0
	movea.l	(rd_back).l,a1
	addq.l	#SCRX,a1
	move.w	(rd_w).l,d0
	lsr.w	#4,d0
	subq.w	#1,d0
	move.w	d0,(rd_c2pw).l
	move.l	#$00FF00FF,d5
	move.l	#$0F0F0F0F,d6
	move.l	#$33333333,d7
	move.w	#SCRH-1,(rd_c2py).l
.y	movea.l	a0,a2
	movea.l	a1,a3
	move.w	(rd_c2pw).l,a4
.x	movem.l	(a2)+,d0-d3
	andi.l	#$3F3F3F3F,d0
	andi.l	#$3F3F3F3F,d1
	andi.l	#$3F3F3F3F,d2
	andi.l	#$3F3F3F3F,d3
	MERGE	d2,d0,8,d5
	MERGE	d3,d1,8,d5
	MERGE	d1,d0,4,d6
	MERGE	d3,d2,4,d6
	MERGE16	d0,d1
	MERGE16	d2,d3
	MERGE	d0,d1,2,d7
	MERGE	d2,d3,2,d7
	MERGE	d2,d0,1,#$55555555
	MERGE	d3,d1,1,#$55555555
	move.w	d2,4*SBPR(a3)
	move.w	d0,5*SBPR(a3)
	swap	d2
	swap	d0
	swap	d3
	swap	d1
	move.w	d2,(a3)
	move.w	d0,SBPR(a3)
	move.w	d3,2*SBPR(a3)
	move.w	d1,3*SBPR(a3)
	addq.l	#2,a3
	subq.w	#1,a4
	move.w	a4,d4
	bpl	.x
	lea	CHPITCH(a0),a0
	lea	SROW(a1),a1
	subq.w	#1,(rd_c2py).l
	bpl	.y
	rts

;	==========================================================================================
;	Colours: CRAM ----bbb-ggg-rrr- to Amiga $0RGB. 0, 16, 32 and 48 all show the backdrop.
rd_palette
	; the same colours as last time? (CRAM, backdrop colour, display on)
	move.l	(vdp_cramgen).l,d0
	move.w	(vdp_regs).l,d1			;registers 0, 1
	swap	d1
	move.b	(vdp_regs+7).l,d1
	cmp.l	(rd_palgen).l,d0
	bne.s	.new
	cmp.l	(rd_palkey).l,d1
	beq	.on
.new	move.l	d0,(rd_palgen).l
	addq.l	#1,(rd_colgen).l
	move.l	d1,(rd_palkey).l
	lea	(vdp_cram).l,a0
	lea	(rd_colours).l,a1
	lea	(rd_colourslo).l,a2
	moveq	#63,d0
.c	move.w	(a0)+,d1
	bsr	rd_gen2amiga
	move.w	d2,(a1)+
	move.w	d4,(a2)+
	dbf	d0,.c
	; colour 0 of each palette line is the backdrop colour
	moveq	#0,d0
	move.b	(vdp_regs+7).l,d0
	andi.w	#$3F,d0
	lea	(rd_colours).l,a1
	bsr.s	.bd
	lea	(rd_colourslo).l,a1
	bsr.s	.bd
	btst	#6,(vdp_regs+1).l
	bne	.on
	lea	(rd_colours).l,a1		;display off: black
	moveq	#63,d0
.off	clr.l	(a1)+				;(both tables)
	dbf	d0,.off
.on	rts
.bd	move.w	(a1,d0.w*2),d1
	move.w	d1,(a1)
	move.w	d1,32(a1)
	move.w	d1,64(a1)
	move.w	d1,96(a1)
	rts

;	Genesis colour d1 (CRAM: ----BBB-GGG-RRR-) -> AGA 24 bit colour: d2 = high nibbles ($0RGB),
;	d4 = low nibbles. The 8 levels are those the Genesis puts out (its DAC and video encoder
;	compress the scale: measured 0, 52, 87, 116, 144, 172, 206, 255), not a straight line.
rd_gen2amiga
	moveq	#0,d2
	moveq	#0,d4
	move.w	d1,d3
	lsr.w	#1,d3				;red
	bsr.s	.ch
	move.w	d1,d3
	lsr.w	#5,d3				;green
	bsr.s	.ch
	move.w	d1,d3
	lsr.w	#8,d3
	lsr.w	#1,d3				;blue
.ch	andi.w	#7,d3
	move.b	(.lv,pc,d3.w),d3
	lsl.w	#4,d2
	lsl.w	#4,d4
	ror.b	#4,d3				;high nibble low
	move.b	d3,d5
	andi.b	#15,d5
	or.b	d5,d2
	lsr.b	#4,d3
	or.b	d3,d4
	rts
.lv	dc.b	0,52,87,116,144,172,206,255

;	------------------------------------------------------------------------------------------
;	Frames drawn in the last second, top left of the screen in colour 63 (F10 shows it).
rd_fps
	move.l	(hal_frames).l,d0
	sub.l	(rd_fpst).l,d0
	cmp.w	(hal_hz).l,d0
	blt	.draw
	move.l	(hal_frames).l,(rd_fpst).l
	move.l	(rd_count).l,d0
	sub.l	(rd_fpsc).l,d0
	move.l	(rd_count).l,(rd_fpsc).l
	move.w	d0,(rd_fpsv).l
.draw	moveq	#0,d0
	move.w	(rd_fpsv).l,d0
	divu.w	#10,d0
	move.l	d0,d1
	swap	d1				;units
	cmpi.w	#9,d0
	bls	.t
	moveq	#9,d0
.t	movem.l	d0-d3,-(sp)
	moveq	#0,d0
	moveq	#4,d1
	moveq	#32,d2
	moveq	#5,d3
	bsr	rd_mark
	movem.l	(sp)+,d0-d3
	; the two 4x5 digits, all 6 planes, into this buffer's image; a queued blit puts it on the
	; screen (the CPU does not wait for the blitter)
	move.w	(rd_bufi).l,d2
	mulu.w	#5*NPLANES*2,d2
	lea	(rd_fpsimg).l,a0
	adda.l	d2,a0
	movea.l	a0,a3
	lea	(.font,pc),a1
	mulu.w	#5,d0
	mulu.w	#5,d1
	lea	(a1,d0.w),a2			;tens
	adda.w	d1,a1				;units
	moveq	#4,d2
.r	move.b	(a2)+,d3
	lsl.w	#8,d3
	move.b	(a1)+,d3
	moveq	#NPLANES-1,d4
.p	move.w	d3,(a0)+
	dbf	d4,.p
	dbf	d2,.r
	bsr	rd_bq_alloc
	move.l	#$09F00000,$040(a6)		;A to D
	move.l	#$FFFFFFFF,$044(a6)
	move.l	a3,$050(a6)			;BLTAPT
	movea.l	(rd_back).l,a0
	move.w	(rd_xorg).l,d2
	addi.w	#15,d2				;(the first whole word on the screen)
	lsr.w	#4,d2
	add.w	d2,d2
	lea	SROW*4(a0,d2.w),a0
	move.l	a0,$054(a6)			;BLTDPT
	clr.w	$064(a6)			;BLTAMOD
	move.w	#SBPR-2,$066(a6)		;BLTDMOD
	move.w	#5*NPLANES,$05C(a6)		;BLTSIZV
	move.w	#1,$05E(a6)			;BLTSIZH
	bra	rd_bq_go
.font
rd_font	dc.b	$E0,$A0,$A0,$A0,$E0, $40,$C0,$40,$40,$E0, $E0,$20,$E0,$80,$E0, $E0,$20,$60,$20,$E0
	dc.b	$A0,$A0,$E0,$20,$20, $E0,$80,$E0,$20,$E0, $E0,$80,$E0,$A0,$E0, $E0,$20,$40,$40,$40
	dc.b	$E0,$A0,$E0,$A0,$E0, $E0,$A0,$E0,$20,$E0
	dc.b	$40,$A0,$E0,$A0,$A0, $C0,$A0,$C0,$A0,$C0, $60,$80,$80,$80,$60, $C0,$A0,$A0,$A0,$C0
	dc.b	$E0,$80,$C0,$80,$E0, $E0,$80,$C0,$80,$80
	even

;	Debug: the long d0 as 8 hex digits from byte a0 of a screen (all planes). Keeps a1.
rd_hex8
	movem.l	d0-d4/a0-a3,-(sp)
	moveq	#7,d4
.d	rol.l	#4,d0
	moveq	#15,d1
	and.w	d0,d1
	lea	(rd_font,pc),a1
	mulu.w	#5,d1
	adda.w	d1,a1
	movea.l	a0,a2
	moveq	#4,d2
.r	move.b	(a1)+,d3
	movea.l	a2,a3
	moveq	#NPLANES-1,d1
.p	move.b	d3,(a3)
	lea	SBPR(a3),a3
	dbf	d1,.p
	lea	SROW(a2),a2
	dbf	d2,.r
	addq.l	#1,a0
	dbf	d4,.d
	movem.l	(sp)+,d0-d4/a0-a3
	rts

;	------------------------------------------------------------------------------------------
;	The back buffer's copper list: 6 interleaved planes, 4x fetch (FMODE 3), 320 (H40) or 256
;	(H32) pixels from the buffer's bit rd_xorg, 224 lines, the 64 colours. The fetch
;	starts on a 64 pixel boundary up to 63 pixels before and BPLCON1 delays it to the first
;	pixel. It becomes the copper's list from the next frame; the buffers swap.
COPMOVE	MACRO
	move.w	#\1,(a0)+
	move.w	\2,(a0)+
	ENDM

rd_show
	clr.w	(hal_wd).l
	tst.b	(hal_fpsshow).l
	beq	.nofps
	bsr	rd_fps
.nofps	movea.l	(rd_backcop).l,a0
	; the list's moves but for the scroll (BPLCON1, the bitplane pointers) stay as they were
	; made while the display rate, the width and the HUD do (rd_shkey: per buffer)
	moveq	#0,d0
	move.w	(rd_bufi).l,d0
	lea	(rd_shkey).l,a1
	lea	(a1,d0.w*8),a1
	moveq	#0,d1
	move.b	(hal_pal).l,d1
	swap	d1
	move.w	(rd_w).l,d1
	move.l	(rd_hudgen).l,d2
	sf	(rd_shfast).l
	cmp.l	(a1),d1
	bne.s	.key
	cmp.l	4(a1),d2
	bne.s	.key
	st	(rd_shfast).l
.key	move.l	d1,(a1)+
	move.l	d2,(a1)
	; the 224 lines: from line $3C on PAL, $1A on NTSC (262 lines a frame)
	move.w	#$3CA1,d1			;DIWSTRT, H32 (256 pixels)
	move.w	#$1CA1,d2			;DIWSTOP
	tst.b	(hal_pal).l
	bne	.pal
	move.w	#$1AA1,d1
	move.w	#$FAA1,d2
.pal	cmpi.w	#320,(rd_w).l
	bne	.h32
	move.b	#$81,d1				;H40: 320 pixels
	move.b	#$C1,d2
	moveq	#64,d6				;the window's first pixel: fetched pixel 64, less the
	moveq	#63,d7				;delay (0-63)
	move.w	#$0018,d3			;6 fetches of 64 pixels (384) from 64 before the window
	move.w	#SROW-48,d5
	move.w	#$000F,d4			;FMODE: 64 bit bitplane fetch, 64 pixel sprites
	bra.s	.dw
.h32	moveq	#32,d6				;H32: fetched pixel 32, less the delay (0-31): 9
	moveq	#31,d7				;fetches of 32 pixels (288) from 32 before the window.
	move.w	#$0038,d3			;Not from $18: those fetches would take the DMA slots
	move.w	#SROW-36,d5			;of sprites 1-7 (the HUD, rd_hud_build)
	move.w	#$000D,d4			;FMODE: 32 bit bitplane fetch, 64 pixel sprites
.dw	tst.b	(rd_shfast).l
	bne	.dyn
	move.l	#$009C0006,(a0)			;INTREQ: SOFT, DSKBLK off (the blit queue's copper state)
	move.w	#$08E,4(a0)
	move.w	d1,6(a0)
	move.w	#$090,8(a0)
	move.w	d2,10(a0)
	move.w	#$092,12(a0)			;DDFSTRT
	move.w	d3,14(a0)
	move.l	#$009400B8,16(a0)		;DDFSTOP
	move.w	#$108,20(a0)			;BPL1MOD, BPL2MOD: interleaved
	move.w	d5,22(a0)
	move.w	#$10A,24(a0)
	move.w	d5,26(a0)
	move.w	#$1FC,28(a0)			;FMODE (the fewer bitplane fetches the more of the bus is
	move.w	d4,30(a0)			;left to the blitter and the CPU)
	move.l	#$01006201,32(a0)		;BPLCON0: 6 planes, colour, ECS bits on
	move.w	#$102,36(a0)			;BPLCON1
	move.l	#$01040224,40(a0)		;BPLCON2: KILLEHB (6 planes would be Extra Half-Brite)
	move.l	#$010C0044,44(a0)		;BPLCON4: sprite colours 64-79
	lea	48(a0),a1			;the bitplane pointers' registers
	move.w	#$0E0,d1
	moveq	#NPLANES*2-1,d2
.bpr	move.w	d1,(a1)
	addq.l	#4,a1
	addq.w	#2,d1
	dbf	d2,.bpr
	; the delay puts buffer bit rd_xorg at the window's first pixel; the bit fetched first is
	; on a fetch boundary (it can be before the row: those pixels are not shown)
.dyn	move.w	(rd_xorg).l,d0
	move.w	d6,d1
	sub.w	d0,d1
	and.w	d7,d1				;delay
	add.w	d1,d0
	sub.w	d6,d0				;the bit fetched first
	asr.w	#3,d0
	ext.l	d0
	add.l	(rd_back).l,d0
	move.w	d1,d2
	andi.w	#15,d2
	move.w	d2,d3
	lsl.w	#4,d3
	or.w	d3,d2				;PF1H5-2, PF2H5-2
	btst	#4,d1
	beq.s	.d16
	ori.w	#$4400,d2			;PF1H6, PF2H6: 16 pixels
.d16	btst	#5,d1
	beq.s	.d32
	ori.w	#$8800,d2			;PF1H7, PF2H7: 32 pixels
.d32	move.w	d2,38(a0)			;BPLCON1
	lea	50(a0),a1			;the bitplane pointers
	moveq	#NPLANES-1,d2
.bp	swap	d0
	move.w	d0,(a1)
	swap	d0
	move.w	d0,4(a1)
	addq.l	#8,a1
	addi.l	#SBPR,d0
	dbf	d2,.bp
	lea	96(a0),a0			;(the sprites' pointers)
	; the sprites: the HUD's (rd_hud_build) or none. This buffer shows its own copy of them,
	; brought up to date from rd_hudm now: the frames queued before it keep the HUD of their
	; moment (a clock digit changes with the rest of the picture)
	tst.w	(rd_hudon).l
	beq	.hs0
	movem.l	d3-d5/a0/a2-a3,-(sp)
	move.w	(rd_bufi).l,d0
	move.w	d0,d3
	mulu.w	#8*HUDSPR,d3
	add.l	#rd_hudsd,d3
	move.l	d3,(rd_hudcopy).l
	lea	(rd_hudbd).l,a1			;the bands of 8 lines changed since its copy
	move.l	(a1,d0.w*4),d2
	beq.s	.hk
	clr.l	(a1,d0.w*4)
	lea	(rd_hudm).l,a2			;the sprites in use
	movea.l	d3,a3
	cmpi.l	#-1,d2
	bne.s	.hb
	move.w	(rd_hudgn).l,d2			;all
	mulu.w	#2*HUDSPR/4,d2
	subq.w	#1,d2
.hcp	move.l	(a2)+,(a3)+
	dbf	d2,.hcp
	bra.s	.hk
.hb	bfffo	d2{0:0},d4			;group * 8 + band
	bfclr	d2{d4:1}
	moveq	#0,d5
	move.w	d4,d5
	lsr.w	#3,d5
	mulu.w	#2*HUDSPR,d5			;the group's even sprite
	andi.w	#7,d4
	lsl.w	#7,d4				;(8 lines of 16 bytes)
	add.w	d4,d5
	addi.w	#16,d5				;(after the control words)
	lea	(a2,d5.l),a0
	lea	(a3,d5.l),a1
	moveq	#128/4-1,d4
.hbe	move.l	(a0)+,(a1)+
	dbf	d4,.hbe
	lea	HUDSPR-128(a0),a0		;the odd one
	lea	HUDSPR-128(a1),a1
	moveq	#128/4-1,d4
.hbo	move.l	(a0)+,(a1)+
	dbf	d4,.hbo
	tst.l	d2
	bne.s	.hb
.hk	movem.l	(sp)+,d3-d5/a0/a2-a3
.hs0	tst.b	(rd_shfast).l
	beq.s	.hsp
	lea	64(a0),a0			;(as they were)
	bra.s	.hse
.hsp	lea	(rd_hudspt).l,a1
	move.w	#$120,d1
	moveq	#7,d2
.sp	move.l	(a1)+,d0
	cmpi.l	#rd_sprnull,d0
	beq.s	.sn
	sub.l	#rd_hudm,d0
	add.l	(rd_hudcopy).l,d0
.sn	move.w	d1,(a0)+
	swap	d0
	move.w	d0,(a0)+
	addq.w	#2,d1
	move.w	d1,(a0)+
	swap	d0
	move.w	d0,(a0)+
	addq.w	#2,d1
	dbf	d2,.sp
.hse
	; the 64 colours: per bank of 32 the high nibbles, then (LOCT) the low nibbles. Already
	; there if neither they nor the HUD changed since this buffer's list was made.
	moveq	#0,d0
	move.w	(rd_bufi).l,d0
	lea	(rd_copgen).l,a1
	lea	(a1,d0.w*8),a1
	move.l	(rd_colgen).l,d0
	move.l	(rd_hudgen).l,d1
	cmp.l	(a1),d0
	bne.s	.cnew
	cmp.l	4(a1),d1
	beq	.cdone
.cnew	move.l	d0,(a1)+
	move.l	d1,(a1)
	lea	(rd_colours).l,a1
	lea	(rd_colourslo).l,a2
	moveq	#0,d3
.bank	move.w	#$106,(a0)+			;BPLCON3: bank
	move.w	d3,d0
	lsl.w	#8,d0
	lsl.w	#5,d0
	ori.w	#$0C00,d0
	move.w	d0,(a0)+
	move.w	#$180,d1
	moveq	#31,d2
.col	move.w	d1,(a0)+
	move.w	(a1)+,(a0)+
	addq.w	#2,d1
	dbf	d2,.col
	move.w	#$106,(a0)+			;BPLCON3: the same bank, LOCT
	ori.w	#$0200,d0
	move.w	d0,(a0)+
	move.w	#$180,d1
	moveq	#31,d2
.lo	move.w	d1,(a0)+
	move.w	(a2)+,(a0)+
	addq.w	#2,d1
	dbf	d2,.lo
	addq.w	#1,d3
	cmpi.w	#2,d3
	bne	.bank
	; the HUD sprites' colours (64-79): those of the overlay colours they stand for
	tst.w	(rd_hudon).l
	beq	.nohc
	lea	(rd_hudmap).l,a1
	lea	(rd_colours).l,a2
	COPMOVE	$106,#$4C00			;BPLCON3: bank 2 (64-95)
	move.w	#$180,d1
	moveq	#15,d2
.hc	moveq	#0,d0
	move.b	(a1)+,d0
	move.w	d1,(a0)+
	move.w	(a2,d0.w*2),(a0)+
	addq.w	#2,d1
	dbf	d2,.hc
	lea	(rd_hudmap).l,a1
	lea	(rd_colourslo).l,a2
	COPMOVE	$106,#$4E00			;(LOCT)
	move.w	#$180,d1
	moveq	#15,d2
.hl	moveq	#0,d0
	move.b	(a1)+,d0
	move.w	d1,(a0)+
	move.w	(a2,d0.w*2),(a0)+
	addq.w	#2,d1
	dbf	d2,.hl
.nohc
	move.l	#$008A0000,(a0)+		;COPJMP2: the blit queue (rd_bq_go)
.cdone
	; it is shown once the blits queued for it are done: a marker in the blit queue has the
	; level 3 interrupt set the copper list then (rd_cq_mark); the CPU goes on
	moveq	#0,d1				;(a long below)
	move.w	(rd_bufi).l,d1
	lea	(rd_shownvb).l,a1
	move.l	#$7FFFFFFF,(a1,d1.w*4)		;(not on the screen yet)
	PEV	'D'				;(statistics: drawn, the show queued)
	bsr	rd_bq_allocq
	move.l	(rd_backcop).l,$048(a6)		;the copper list
	move.w	d1,$04C(a6)			;the buffer
	clr.w	$05E(a6)			;(a marker, not a blit)
	bsr	rd_bq_go
	; the next buffer, its dirty map and copper list
	addq.w	#1,d1
	cmpi.w	#NBUF,d1
	blo.s	.nb
	moveq	#0,d1
.nb	move.w	d1,(rd_bufi).l
	move.l	d1,d0
	mulu.l	#BUFSIZE,d0
	add.l	#rd_screens,d0
	move.l	d0,(rd_buf).l
	move.l	d0,(rd_back).l
	move.w	d1,d0
	mulu.w	#DROWS*4,d0
	add.l	#rd_dirty,d0
	move.l	d0,(rd_dmap).l
	move.w	d1,d0
	mulu.w	#1024,d0
	add.l	#rd_cop,d0
	move.l	d0,(rd_backcop).l
	rts

	section	bss,bss
rd_tline	ds.w	1
rd_hudspt	ds.l	8			;the sprites' data in rd_hudm (rd_sprnull: none)
rd_hudgen	ds.l	1			;(changed when its sprites or their colours change, not a
						;cell's bytes: the copper lists' HUD parts, rd_show)
rd_shkey	ds.l	2*NBUF			;per buffer: display rate, width; rd_hudgen of its copper
						;list's moves but the scroll (rd_show)
rd_shfast	ds.b	1			;(rd_show: those as they were)
	even
rd_hudbd	ds.l	NBUF			;per buffer: its copy's bands of 8 lines to make again
						;(bit group * 8 + band from the top; -1: all)
rd_hudcopy	ds.l	1			;(rd_show: the back buffer's copy)
rd_hudon	ds.w	1
rd_hudchg	ds.w	1			;(the overlay changed: rd_hud_build)
rd_hudw		ds.w	1			;(the screen width it was built for)
rd_hudy		ds.w	1			;first line
rd_hudn		ds.w	1			;lines
rd_hudgn	ds.w	1			;groups
rd_hudg		ds.w	4			;their first overlay row bytes
rd_hudnc	ds.w	1			;colours used
rd_hudbase	ds.l	1			;(rd_hudm)
		cnop	0,4
rd_hudm		ds.b	8*HUDSPR		;the HUD sprites (rd_hud_build, rd_hud_cell)
rd_hudcols	ds.b	48			;(columns used)
rd_hudcm	ds.b	64			;overlay colour -> sprite colour (0: none yet)
rd_hudmap	ds.b	16			;sprite colour -> overlay colour
rd_nchgA	ds.w	1
rd_ntcur	ds.b	1			;the name table being compared was written (rd_ntwritten)
rd_nttab	ds.b	1			;(VERIFY: which)
rd_ntsync	ds.b	1			;0: compare all name tables with their copies
	even
rd_sbit		ds.w	1
rd_ctiles	ds.w	4
rd_cqwp		ds.l	1			;the copper ring: where the copper stops (the next block),
rd_cqdp		ds.l	1			;what it has run all before (or more)
rd_cqmh		ds.w	1			;show markers queued (rd_cqmq): the oldest,
rd_cqmt		ds.w	1			;the next to queue
rd_cqring	ds.l	1			;the ring (in rd_cqbuf)
rd_cqjmv	ds.l	1			;a copper move of its start to COP2LCL
rd_cqpmv	ds.l	1			;and of the parking place
rd_cqjmp	ds.l	1			;(rd_cq_open: the stop to make a jump to the start)
rd_cqfree	ds.w	1			;bytes free after the stop, to the ring's end at most
rd_cqkind	ds.b	1			;the blitter holds BLTCON0 .. BLTALWM of 1: rd_restore,
						;2: the fixups (0: not known)
rd_cqbat	ds.b	1			;blits in the batch open (rd_cq_blit)
	even
rd_cqba5	ds.l	1			;(its moves' end,
rd_cqba6	ds.l	1			;its place)
	even
rd_cqmq		ds.b	8*16			;show markers: where, where the copper goes on, the
						;copper list, the buffer
rd_bqe		ds.b	BQE			;the blit being written (rd_bq_alloc)
rd_cqidle	ds.b	1			;nothing given to the copper since it stopped at the end
rd_bqhold	ds.b	1			;the copper waits at a show for a vertical blank
	even
rd_lastset	ds.l	1			;rd_vblanks when the last copper list was set
rd_showcop	ds.l	1			;a copper list waiting to be set (0: none)
rd_snapvb	ds.l	NBUF			;rd_vblanks when each buffer's game state was taken
rd_showbuf	ds.w	1			;(its buffer)
		even
rd_c4m		ds.w	1			;$FFFF: 4 columns, $FF00: 3
		cnop	0,4
rd_spalm	ds.l	2
rd_gp2		ds.l	1
rd_bcol		ds.w	1
rd_btr		ds.w	1
rd_btile	ds.w	1
rd_blitnoc	ds.w	1
rd_nchgW	ds.w	1
rd_chgA		ds.w	16
rd_chgW		ds.w	16
		cnop	0,4
rd_dbg_key	ds.l	1
rd_dbg_nta	ds.l	1
rd_dbg_ntw	ds.l	1
rd_dbg_til	ds.l	1
rd_dbg_x	ds.l	26			;(statistics: see nhlrun)
		cnop	0,4
rd_ovldirty	ds.w	1
rd_ovlrows	ds.l	2*32			;per priority, per band: x min, x max
rd_ovlcolf	ds.b	2*32*48			;per priority, band: columns with cells
rd_c0		ds.w	1
rd_ncol		ds.w	1
rd_wb		ds.w	1
rd_mkset	ds.l	BMAX/32			;plane B cells whose masks (mkB, mkB6) are not all 0
rd_cellmk	ds.b	1			;rd_cellB: the cell has a mask
rd_cellmw	ds.b	1			;and its masks are written
	cnop	0,4
rd_zero8	ds.b	8			;(0: a low priority cell's mask rows)
	cnop	0,4
rd_sbuild	ds.l	2*4*NPLANES*32/4		;a sprite image and mask being built (rd_spr_build)
hal_obj_a6	ds.l	1			;addframe2: where its object's sprites begin
rd_oent		ds.l	1			;its entry of rd_octab
rd_opx		ds.l	1			;rd_obj_piece: the sprite's first pixel in the image
rd_objbn	ds.w	1			;objects of the sprite table being made (hal_obj_end)
rd_objpn	ds.w	1			;of the table sent (rd_obj_publish)
rd_on		ds.w	1			;rd_obj_blit: the object's sprites
rd_opri		ds.w	1			;their priority
rd_ox0		ds.w	1			;the first's place
rd_oy0		ds.w	1
rd_ominx	ds.w	1			;the image's, from it
rd_ominy	ds.w	1
rd_oscw		ds.w	1			;cells across, down
rd_osch		ds.w	1
rd_owb		ds.w	1			;bytes a row
rd_olines	ds.w	1
rd_opw		ds.w	1			;rd_obj_piece: the sprite's tiles across
rd_oplines	ds.w	1			;its lines
rd_opat		ds.w	1			;its flips and palette
rd_okey		ds.w	1			;rd_obj_blit: the object's key
rd_oovl		ds.b	1			;rd_obj_overlap: the sprite overlaps one drawn before
	even
rd_opline	ds.l	1			;rd_obj_piece: its first line in the scratch
rd_objb		ds.b	4*OBJMAX		;per object: its first sprite, sprites, key (word)
rd_objp		ds.b	4*OBJMAX
rd_sprgkey	ds.w	80			;per place of the sprite list: the key of the object whose
						;last sprite is there
rd_sprgend	ds.b	80			;and its sprites (0: none)
rd_sprnsq	ds.b	1			;the list is not the table in order (no objects)
	cnop	0,4
rd_opc		ds.b	12*OBJPC		;per sprite: its tiles' source in Spritetiles (long),
						;flips and palette (word), size (byte), 0, its place from
						;the first's (x, y words)
rd_oscr		ds.b	56*64			;the image being built: lines of 7 rows of 8 bytes
rd_opbuf	ds.b	20*32			;a sprite's lines unpacked (rd_obj_piece)
rd_octab	ds.l	8*OBJSLOTS		;object images: $10000 + key, 0, ring place, image, box (4
						;words), offset from the first sprite (x, y), cells across, down
rd_r0		ds.w	1
rd_r1		ds.w	1
		cnop	0,4
rd_fpsv		ds.w	1
		cnop	0,4
rd_fpst		ds.l	1
rd_fpsc		ds.l	1
		cnop	0,4
rd_akey		ds.l	6
rd_akeynew	ds.l	6
rd_shA		ds.w	BMAX
rd_shW		ds.w	64*32
rd_aused	ds.l	64
rd_bused	ds.l	64
rd_btchg	ds.l	1
rd_wbase	ds.l	1
rd_abase	ds.l	1
rd_alistn	ds.w	1
rd_alist	ds.w	3*(42*30+42*29)

	section	game,code
