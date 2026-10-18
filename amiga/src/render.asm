;	Renderer: draws the emulated Genesis VDP (vdp.asm) on the AGA display, 6 bitplanes
;	(the 64 CRAM colours), interleaved, double buffered.
;
;	Fast path (full screen scroll, the game screens):
;	  * tiles are kept converted to planar form (tile cache, both horizontal orientations), and
;	    converted again when their VRAM changes (hal_vdp_dirty);
;	  * plane B is kept as a planar bitmap of its whole name table, redrawn only where an entry
;	    or its tile changed, and copied to the screen by the blitter at the scroll position;
;	  * plane A, the window and the sprites are drawn on top by the CPU, in Genesis priority
;	    order: B, A low, sprites low, B high (redrawn where something low covered it), A high,
;	    sprites high.
;	Plane B's transparent pixels keep their palette bits and show the backdrop: colours 0, 16,
;	32 and 48 are all set to the backdrop colour (rd_palette).
;
;	Fallback (line or cell scroll, per column vertical scroll, very large planes): the frame is
;	drawn per line in a chunky buffer and converted to planar (rd_chunky).

SBPR		equ	48			;screen bytes per plane row: 32 pixel margin, 320, 32 margin
SROW		equ	SBPR*6			;interleaved row of the 6 planes
SCRX		equ	4			;byte of screen x = 0
SCRH		equ	224
SCRSIZE		equ	SROW*SCRH
NPLANES		equ	6
CHPITCH		equ	384			;chunky fallback: bytes per line
CHLEFT		equ	32			;screen x 0 is at this offset
BMAX		equ	2048			;largest plane B (cells) the fast path keeps as a bitmap

	section	bss,bss
	cnop	0,4
tp_pl		ds.l	4096*8			;tile cache planes: (tile | hflip<<11), 8 rows of p0p1p2p3
tp_mk		ds.b	4096*8			;mask per row (bit set = pixel not transparent)
tp_cls		ds.b	4096			;0 empty, 1 opaque, 2 mixed
tc_dirty	ds.l	64			;one bit per tile: convert before use
tc_chg		ds.l	64			;tiles converted this frame
rd_ptab		ds.l	256			;byte (2 pixels) -> its bits in the 4 plane bytes
rd_pftab	ds.l	256			;the same for the flipped tile
rd_nibtab	ds.w	256			;chunky fallback: byte -> 2 pixel bytes
rd_revtab	ds.w	256			;the same, swapped
rd_attr		ds.l	8			;chunky fallback: pixel OR value by entry bits 15-13
chunky		ds.b	CHPITCH*SCRH
shB		ds.w	BMAX			;plane B name table as drawn in bmB
rd_hiB		ds.l	BMAX			;plane B high priority cells: column, row (words)
rd_hiBn		ds.w	1
rd_hiBok	ds.w	1			;list matches bmB
rd_Bkey		ds.l	2			;base, size of the plane in bmB (invalid: redraw all)
rd_cover	ds.b	64*32			;screen cells something low was drawn on (fixups)
rd_sprites	ds.l	2*80
rd_spn		ds.w	1
rd_w		ds.w	1			;screen width 256 / 320
rd_cells	ds.w	1			;tiles across +1
rd_cw		ds.w	1			;plane B cells across, down
rd_ch		ds.w	1
rd_bx0		ds.w	1			;plane B pixel at screen 0, 0
rd_by0		ds.w	1
rd_back		ds.l	1			;back buffer being drawn
rd_backcop	ds.l	1			;its copper list
rd_frontcop	ds.l	1
rd_lastframe	ds.l	1
rd_lastgen	ds.l	2
rd_count	ds.l	1			;frames drawn
rd_colours	ds.w	64
rd_mode		ds.w	1
rd_clipx0	ds.w	1
rd_clipx1	ds.w	1
rd_pass		ds.w	1			;0 low priority pass, $8000 high
rd_tmp		ds.l	8
rd_cellpri	ds.w	1
rd_rowbuf	ds.l	2

	section	chip,bss_c
	cnop	0,8
rd_screens	ds.b	SCRSIZE*2
bmB		ds.b	BMAX*48			;plane B: cells * 8 rows * 6 planes
mkB		ds.b	BMAX*8			;plane B high priority mask
rd_cop		ds.l	2*128

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
	beq.s	.nl
	move.l	d4,d5
	addq.l	#1,d5
	bset	d5,d1
	bset	d4,d2
.nl	btst	d3,d0				;right pixel bit p
	beq.s	.nr
	bset	d4,d1
	move.l	d4,d5
	addq.l	#1,d5
	bset	d5,d2
.nr	addq.w	#1,d3
	cmpi.w	#4,d3
	bne.s	.pp
	move.l	d1,(a0)+
	move.l	d2,(a1)+
	addq.w	#1,d0
	cmpi.w	#256,d0
	bne.s	.pt
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
	bne.s	.nt
	lea	(rd_attr).l,a0
	moveq	#0,d0
.at	move.l	d0,d1
	andi.l	#3,d1
	lsl.l	#4,d1
	btst	#2,d0
	beq.s	.np
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
	bne.s	.at
	bsr	rd_dirty_all
	lea	(rd_screens).l,a0
	move.l	a0,(rd_back).l
	lea	(rd_cop).l,a0
	move.l	a0,(rd_backcop).l
	lea	512(a0),a1
	move.l	a1,(rd_frontcop).l
	moveq	#-1,d0
	move.l	d0,(rd_Bkey).l
	move.l	d0,(rd_lastgen).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	------------------------------------------------------------------------------------------
;	Tile cache.

;	VRAM d1 (address), d0 (words) changed: convert the tiles it covers again.
hal_vdp_dirty
	movem.l	d0-d2/a0,-(sp)
	addq.l	#1,(hal_vdp_gen).l
	andi.l	#$FFFF,d0
	beq.s	.x
	andi.l	#$FFFF,d1
	add.l	d0,d0
	add.l	d1,d0
	subq.l	#1,d0
	lsr.l	#5,d1
	lsr.l	#5,d0
	cmpi.l	#2047,d0
	bls.s	.ok
	move.l	#2047,d0
.ok	lea	(tc_dirty).l,a0
.loop	cmp.l	d0,d1
	bhi.s	.x
	bfset	(a0){d1:1}
	addq.l	#1,d1
	bra.s	.loop
.x	movem.l	(sp)+,d0-d2/a0
	rts

hal_vdp_dirty_all
rd_dirty_all
	movem.l	d0/a0,-(sp)
	addq.l	#1,(hal_vdp_gen).l
	lea	(tc_dirty).l,a0
	moveq	#63,d0
.c	move.l	#-1,(a0)+
	dbf	d0,.c
	movem.l	(sp)+,d0/a0
	rts

;	Convert every dirty tile; tc_chg = the tiles converted. d0 = 0 if none.
rd_decode_dirty
	lea	(tc_dirty).l,a4
	lea	(tc_chg).l,a3
	moveq	#0,d7
	moveq	#0,d3				;any
.long	move.l	(a4),d6
	move.l	d6,(a3)+
	beq.s	.next
	clr.l	(a4)
	moveq	#1,d3
	moveq	#31,d5
.bit	btst	d5,d6
	beq.s	.nb
	move.l	d7,d0
	addi.l	#31,d0
	sub.l	d5,d0
	movem.l	d3/a3,-(sp)
	bsr	rd_decode_tile
	movem.l	(sp)+,d3/a3
.nb	dbf	d5,.bit
.next	addq.l	#4,a4
	addi.l	#32,d7
	cmpi.l	#2048,d7
	bne.s	.long
	move.l	d3,d0
	rts

;	Convert tile d0. Uses d0-d4/a0-a3/a5/a6.
rd_decode_tile
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
	moveq	#2,d0
	tst.b	d4
	bne.s	.ne
	moveq	#0,d0
	bra.s	.cl
.ne	cmpi.w	#$FF00,d4
	blo.s	.cl
	moveq	#1,d0
.cl	move.b	d0,(a6)
	move.b	d0,$800(a6)
	rts

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
	bne.s	.changed
	cmp.l	(rd_lastgen+4).l,d0
	beq	.skip
.changed
	move.l	(rd_lastgen).l,(rd_lastgen+4).l
	move.l	d0,(rd_lastgen).l
	bsr	rd_decode_dirty
	lea	(vdp_regs).l,a5
	move.w	#256,d0
	moveq	#33,d1
	move.b	12(a5),d2
	andi.b	#$81,d2
	beq.s	.h32
	move.w	#320,d0
	moveq	#41,d1
.h32	move.w	d0,(rd_w).l
	move.w	d1,(rd_cells).l
	; fast path?
	move.b	11(a5),d0
	andi.b	#7,d0
	bne.s	.chunky				;line / cell scroll or column vscroll
	bsr	rd_planesize			;d0 = cells across, d1 = down
	mulu.w	d1,d0
	cmpi.l	#BMAX,d0
	bhi.s	.chunky
	bsr	rd_fast
	bra.s	.shown
.chunky	moveq	#-1,d0
	move.l	d0,(rd_Bkey).l			;plane B bitmap no longer matches
	bsr	rd_chunky
.shown	bsr	rd_palette
	bsr	rd_show
	addq.l	#1,(rd_count).l
.skip	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	d0 = plane cells across, d1 = down (a5 = regs). Keeps the rest.
rd_planesize
	move.b	16(a5),d1
	moveq	#32,d0
	btst	#0,d1
	beq.s	.w
	moveq	#64,d0
	btst	#1,d1
	beq.s	.w
	move.w	#128,d0
.w	lsr.b	#4,d1
	btst	#0,d1
	bne.s	.h1
	moveq	#32,d1
	rts
.h1	btst	#1,d1
	bne.s	.h2
	moveq	#64,d1
	rts
.h2	move.w	#128,d1
	rts

;	==========================================================================================
;	Fast path
rd_fast
	bsr	rd_updateB
	bsr	rd_blitB
	bsr	rd_collect_sprites
	lea	(rd_cover).l,a0			;nothing low drawn yet
	move.w	#64*32/4-1,d0
.c	clr.l	(a0)+
	dbf	d0,.c
	bsr	rd_buildA
	bsr	rd_waitblit
	clr.w	(rd_pass).l
	bsr	rd_layerA
	bsr	rd_sprites_planar
	bsr	rd_fixups
	move.w	#$8000,(rd_pass).l
	bsr	rd_layerA
	bsr	rd_sprites_planar
	rts

rd_waitblit
	btst	#6,(CUSTOM+DMACONR).l		;(first read is early on old chips)
.w	btst	#6,(CUSTOM+DMACONR).l
	bne.s	.w
	rts

;	------------------------------------------------------------------------------------------
;	Bring the plane B bitmap up to date with the name table and the tiles.
rd_updateB
	lea	(vdp_regs).l,a5
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
	swap	d2
	move.w	d0,d2
	lsl.w	#8,d2
	or.b	d1,d2				;key = base, size
	moveq	#0,d6				;0 = only changed cells
	cmp.l	(rd_Bkey).l,d2
	beq.s	.same
	move.l	d2,(rd_Bkey).l
	moveq	#1,d6				;redraw everything
	lea	(rd_bused).l,a1
	moveq	#63,d3
.cu	clr.l	(a1)+
	dbf	d3,.cu
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
	clr.w	(rd_hiBok).l
	move.w	d0,d7
	mulu.w	d1,d7
	subq.w	#1,d7				;cells - 1
	lea	(shB).l,a1
	lea	(tc_chg).l,a2
	moveq	#0,d4				;cell column
	moveq	#0,d5				;cell row
	move.w	#-1,(rd_hiBok).l		;unchanged unless a cell is redrawn
.cell	move.w	(a0)+,d0
	tst.w	d6
	bne.s	.draw
	cmp.w	(a1),d0
	bne.s	.draw
	tst.l	(rd_btchg).l
	beq.s	.next
	move.w	d0,d1
	andi.w	#$7FF,d1
	bftst	(a2){d1:1}
	beq.s	.next
.draw	move.w	d0,(a1)
	clr.w	(rd_hiBok).l
	movem.l	d4-d7/a0-a2,-(sp)
	bsr	rd_cellB
	movem.l	(sp)+,d4-d7/a0-a2
.next	addq.l	#2,a1
	addq.w	#1,d4
	cmp.w	(rd_cw).l,d4
	bne.s	.nc
	moveq	#0,d4
	addq.w	#1,d5
.nc	dbf	d7,.cell
	tst.w	(rd_hiBok).l
	bne.s	.x
	bsr	rd_list_hiB
.x	rts

;	Draw entry d0 at cell d4 (column), d5 (row) of the plane B bitmap.
rd_cellB
	move.w	d0,(rd_cellpri).l		;bit 15: high priority
	move.w	d0,d1
	andi.w	#$7FF,d1
	lea	(rd_bused).l,a1
	bfset	(a1){d1:1}
	move.w	(rd_cw).l,d1			;bytes per plane row
	move.w	d1,d2
	mulu.w	#6,d2				;bytes per pixel row
	move.w	d5,d3
	lsl.w	#3,d3
	mulu.w	d3,d2
	lea	(bmB).l,a1
	adda.l	d2,a1
	adda.w	d4,a1				;a1 = cell, plane 0, row 0
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
	beq.s	.nv
	lea	28(a0),a0			;vertical flip: last row first
	addq.l	#7,a2
	moveq	#-4,d5
	moveq	#-1,d4
.nv	moveq	#0,d6				;palette planes
	btst	#13,d0
	beq.s	.p0
	move.b	#$FF,d6
.p0	moveq	#0,d7
	btst	#14,d0
	beq.s	.p1
	move.b	#$FF,d7
.p1	move.w	d1,d2
	mulu.w	#6,d2				;pixel row step
	moveq	#7,d3
.row	move.l	(a0),d0
	adda.w	d5,a0
	rol.l	#8,d0
	move.b	d0,(a1)
	adda.w	d1,a1
	rol.l	#8,d0
	move.b	d0,(a1)
	adda.w	d1,a1
	rol.l	#8,d0
	move.b	d0,(a1)
	adda.w	d1,a1
	rol.l	#8,d0
	move.b	d0,(a1)
	adda.w	d1,a1
	move.b	d6,(a1)
	adda.w	d1,a1
	move.b	d7,(a1)
	adda.w	d1,a1				;next pixel row (6 planes)
	; high priority mask
	move.b	(a2),d0
	adda.w	d4,a2
	tst.w	(rd_cellpri).l
	bmi.s	.hi
	moveq	#0,d0
.hi	move.b	d0,(a3)
	adda.w	d1,a3
	dbf	d3,.row
	rts

;	List the high priority cells of plane B (for the fixups).
rd_list_hiB
	lea	(shB).l,a0
	lea	(rd_hiB).l,a1
	move.w	(rd_cw).l,d6
	move.w	(rd_ch).l,d7
	moveq	#0,d5				;row
	moveq	#0,d3				;count
.r	moveq	#0,d4
.c	move.w	(a0)+,d0
	bpl.s	.n
	move.w	d4,(a1)+
	move.w	d5,(a1)+
	addq.w	#1,d3
.n	addq.w	#1,d4
	cmp.w	d6,d4
	bne.s	.c
	addq.w	#1,d5
	cmp.w	d7,d5
	bne.s	.r
	move.w	d3,(rd_hiBn).l
	move.w	#1,(rd_hiBok).l
	rts

;	------------------------------------------------------------------------------------------
;	Copy plane B to the back buffer at its scroll position (blitter). The bitmap wraps, so up
;	to 4 rectangles.
rd_blitB
	lea	(vdp_regs).l,a5
	moveq	#0,d0
	move.b	13(a5),d0
	andi.w	#$3F,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	lea	(vdp_vram).l,a0
	move.w	2(a0,d0.l),d0			;B hscroll
	neg.w	d0
	move.w	(rd_cw).l,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	d0,(rd_bx0).l			;plane x at screen x 0
	move.w	(vdp_vsram+2).l,d0
	move.w	(rd_ch).l,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	d0,(rd_by0).l			;plane y at screen y 0
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
	ble.s	.vh
	move.w	d2,d3
.vh	; d3 lines from plane y d4 to screen y d5: horizontal pieces, the wrapped one first
	movem.w	d3-d6,-(sp)
	move.w	(rd_cw).l,d0
	lsl.w	#3,d0				;plane width
	move.w	(rd_bx0).l,d1
	sub.w	d1,d0				;pixels to the right edge
	move.w	(rd_w).l,d2
	cmp.w	d2,d0
	bge.s	.one
	; two pieces: [bx0, W) at screen 0, then [0, w-(W-bx0)) at screen W-bx0
	movem.w	d0-d2,-(sp)
	move.w	d0,d7				;screen x of the second piece
	moveq	#0,d1				;plane x 0
	sub.w	d0,d2				;width
	bsr	rd_blitrect			;d1 plane x, d2 width, d3 lines, d4 plane y, d5 screen y,
						;d7 screen x
	movem.w	(sp)+,d0-d2
	move.w	d0,d2
	moveq	#0,d7
	bsr	rd_blitrect
	bra.s	.hd
.one	moveq	#0,d7
	bsr	rd_blitrect
.hd	movem.w	(sp)+,d3-d6
	add.w	d3,d5
	moveq	#0,d4				;wrapped to the top
	cmpi.w	#SCRH,d5
	blt.s	.vp
	rts


;	Blit d2 pixels x d3 lines of plane B from (d1, d4) to the back buffer at (d7, d5). Keeps
;	d3-d7. Channel B is the plane (shifted), C the screen, D the result; A is the edge mask
;	(BLTADAT = $FFFF through the first / last word masks), minterm AB + /AC. One extra word on
;	the left with a zero first word mask carries the shift in.
rd_blitrect
	movem.l	d3-d7,-(sp)
	bsr	rd_waitblit
	move.w	d7,d0
	addi.w	#SCRX*8,d0			;destination bit x
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
	beq.s	.r0
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
	lea	(CUSTOM).l,a6
	move.w	#$07CA,$040(a6)			;BLTCON0: B, C, D, AB+/AC
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
	move.w	d2,$05E(a6)			;BLTSIZH: go
	movem.l	(sp)+,d3-d7
	rts

;	------------------------------------------------------------------------------------------
;	The sprite list, followed from sprite 0 through the links.
rd_collect_sprites
	lea	(vdp_regs).l,a5
	moveq	#0,d0
	move.b	5(a5),d0
	moveq	#64,d6
	move.b	12(a5),d1
	andi.b	#$81,d1
	beq.s	.32
	andi.w	#$7E,d0
	moveq	#80,d6
	bra.s	.b
.32	andi.w	#$7F,d0
.b	lsl.l	#8,d0
	add.l	d0,d0
	lea	(vdp_vram).l,a0
	adda.l	d0,a0
	lea	(rd_sprites).l,a1
	moveq	#0,d1
	moveq	#0,d5
.coll	move.w	d1,d0
	lsl.w	#3,d0
	move.l	(a0,d0.w),(a1)+
	move.l	4(a0,d0.w),(a1)+
	addq.w	#1,d5
	moveq	#0,d1
	move.b	3(a0,d0.w),d1
	andi.b	#$7F,d1
	beq.s	.done
	cmp.w	d6,d5
	blt.s	.coll
.done	move.w	d5,(rd_spn).l
	rts

;	------------------------------------------------------------------------------------------
;	Masked write of one 8 pixel row at screen x d0 on the row a1 (back buffer line):
;	d1 = planes 0-3 (p0 in the high byte), d2 = palette (planes 4, 5), d3 = mask byte.
;	Keeps d0-d3, a1. Uses d4-d7, a0.
rd_put8
	moveq	#0,d4
	move.b	d3,d4
	beq	.x
	move.w	d0,d5
	addi.w	#SCRX*8,d5
	move.w	d5,d6
	lsr.w	#3,d6
	lea	(a1,d6.w),a0			;first byte
	andi.w	#7,d5
	bne	.shift
	cmpi.b	#$FF,d4
	bne.s	.bmask
	; aligned and opaque: plain stores
	rol.l	#8,d1
	move.b	d1,(a0)
	rol.l	#8,d1
	move.b	d1,SBPR(a0)
	rol.l	#8,d1
	move.b	d1,2*SBPR(a0)
	rol.l	#8,d1
	move.b	d1,3*SBPR(a0)
	moveq	#0,d6
	btst	#0,d2
	beq.s	.a4
	moveq	#-1,d6
.a4	move.b	d6,4*SBPR(a0)
	moveq	#0,d6
	btst	#1,d2
	beq.s	.a5
	moveq	#-1,d6
.a5	move.b	d6,5*SBPR(a0)
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
	move.b	SBPR(a0),d7
	and.b	d6,d7
	or.b	d1,d7
	move.b	d7,SBPR(a0)
	rol.l	#8,d1
	move.b	2*SBPR(a0),d7
	and.b	d6,d7
	or.b	d1,d7
	move.b	d7,2*SBPR(a0)
	rol.l	#8,d1
	move.b	3*SBPR(a0),d7
	and.b	d6,d7
	or.b	d1,d7
	move.b	d7,3*SBPR(a0)
	move.b	4*SBPR(a0),d7
	and.b	d6,d7
	btst	#0,d2
	beq.s	.b4
	or.b	d4,d7
.b4	move.b	d7,4*SBPR(a0)
	move.b	5*SBPR(a0),d7
	and.b	d6,d7
	btst	#1,d2
	beq.s	.b5
	or.b	d4,d7
.b5	move.b	d7,5*SBPR(a0)
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
	move.w	SBPR(a0),d7
	and.w	d6,d7
	or.w	d3,d7
	move.w	d7,SBPR(a0)
	rol.l	#8,d1
	move.w	d1,d3
	lsl.w	#8,d3
	lsr.w	d5,d3
	move.w	2*SBPR(a0),d7
	and.w	d6,d7
	or.w	d3,d7
	move.w	d7,2*SBPR(a0)
	rol.l	#8,d1
	move.w	d1,d3
	lsl.w	#8,d3
	lsr.w	d5,d3
	move.w	3*SBPR(a0),d7
	and.w	d6,d7
	or.w	d3,d7
	move.w	d7,3*SBPR(a0)
	move.l	(sp)+,d3
	move.w	4*SBPR(a0),d7
	and.w	d6,d7
	btst	#0,d2
	beq.s	.s4
	or.w	d4,d7
.s4	move.w	d7,4*SBPR(a0)
	move.w	5*SBPR(a0),d7
	and.w	d6,d7
	btst	#1,d2
	beq.s	.s5
	or.w	d4,d7
.s5	move.w	d7,5*SBPR(a0)
	rts

;	Mark the screen cells of the rectangle d0 (x), d1 (y), d2 (w), d3 (h) as covered by
;	something of low priority. Keeps everything.
rd_cover_rect
	movem.l	d0-d6/a0,-(sp)
	add.w	d0,d2
	subq.w	#1,d2				;x1
	add.w	d1,d3
	subq.w	#1,d3				;y1
	tst.w	d0
	bpl.s	.1
	moveq	#0,d0
.1	tst.w	d1
	bpl.s	.2
	moveq	#0,d1
.2	cmpi.w	#319,d2
	ble.s	.3
	move.w	#319,d2
.3	cmpi.w	#SCRH-1,d3
	ble.s	.4
	move.w	#SCRH-1,d3
.4	cmp.w	d0,d2
	blt.s	.x
	cmp.w	d1,d3
	blt.s	.x
	asr.w	#3,d0
	asr.w	#3,d1
	asr.w	#3,d2
	asr.w	#3,d3
	lea	(rd_cover).l,a0
.r	move.w	d1,d4
	lsl.w	#6,d4
	add.w	d0,d4
	move.w	d0,d5
.c	st	(a0,d4.w)
	addq.w	#1,d4
	addq.w	#1,d5
	cmp.w	d2,d5
	ble.s	.c
	addq.w	#1,d1
	cmp.w	d3,d1
	ble.s	.r
.x	movem.l	(sp)+,d0-d6/a0
	rts

;	------------------------------------------------------------------------------------------
;	Plane A and the window. rd_buildA lists their visible non-empty cells (screen x, y, entry);
;	the list is kept while their name tables, scroll, window registers and tiles stay the same.
;	rd_layerA draws the listed cells of priority rd_pass.
rd_layerA
	lea	(rd_alist).l,a4
	move.w	(rd_alistn).l,d7
	subq.w	#1,d7
	bmi.s	.x
.c	move.w	(a4)+,d1
	move.w	(a4)+,d2
	move.w	(a4)+,d0
	bsr	rd_drawcell
	dbf	d7,.c
.x	rts

rd_buildA
	lea	(vdp_regs).l,a5
	lea	(rd_akeynew).l,a3
	; window rows (screen cells) and columns
	move.b	18(a5),d0
	move.w	d0,d1
	andi.w	#$1F,d1
	moveq	#0,d2
	move.w	d1,d3
	tst.b	d0
	bpl.s	.top
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
	bpl.s	.left
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
	beq.s	.w32
	andi.w	#$3C,d0
	moveq	#64,d6
	bra.s	.wb
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
	moveq	#0,d0
	move.b	13(a5),d0
	andi.w	#$3F,d0
	lsl.l	#8,d0
	lsl.l	#2,d0
	lea	(vdp_vram).l,a0
	move.w	(a0,d0.l),d0
	neg.w	d0
	move.w	d6,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	d0,(rd_ax0).l
	move.w	d0,(a3)+			;key: A x
	move.w	(vdp_vsram).l,d0
	move.w	d7,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	d0,(rd_ay0).l
	move.w	d0,(a3)+			;key: A y
	move.w	d6,(a3)+			;key: size, width
	move.w	d7,(a3)+
	move.w	(rd_cells).l,(a3)+
	; same as last time?
	lea	(rd_akeynew).l,a0
	lea	(rd_akey).l,a1
	moveq	#0,d5				;changed
	moveq	#5,d0
.k	cmpm.l	(a0)+,(a1)+
	beq.s	.k1
	moveq	#1,d5
.k1	dbf	d0,.k
	; name tables against their copies (copied as they are compared)
	lea	(vdp_vram).l,a0
	adda.l	(rd_abase).l,a0
	lea	(rd_shA).l,a1
	move.w	d6,d0
	mulu.w	d7,d0
	lsr.w	#1,d0
	subq.w	#1,d0				;longs - 1
.ca	move.l	(a0)+,d1
	cmp.l	(a1),d1
	beq.s	.ca1
	moveq	#1,d5
	move.l	d1,(a1)
.ca1	addq.l	#4,a1
	dbf	d0,.ca
	lea	(vdp_vram).l,a0
	adda.l	(rd_wbase).l,a0
	lea	(rd_shW).l,a1
	move.w	(rd_wwidth).l,d0
	lsl.w	#4,d0				;* 32 rows / 2
	subq.w	#1,d0
.cw	move.l	(a0)+,d1
	cmp.l	(a1),d1
	beq.s	.cw1
	moveq	#1,d5
	move.l	d1,(a1)
.cw1	addq.l	#4,a1
	dbf	d0,.cw
	; tiles of these cells converted again?
	lea	(tc_chg).l,a0
	lea	(rd_aused).l,a1
	moveq	#63,d0
.tu	move.l	(a0)+,d1
	and.l	(a1)+,d1
	beq.s	.tu1
	moveq	#1,d5
.tu1	dbf	d0,.tu
	tst.w	d5
	beq	.keep
	; rebuild
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
	beq.s	.wn
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
	blt.s	.wc
	addq.w	#1,d5
	cmpi.w	#28,d5
	blt.s	.wr
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
	bne.s	.an
	bsr	rd_addcell
.an	addq.w	#1,d4
	cmp.w	(rd_cells).l,d4
	ble.s	.ac
	addq.w	#1,d5
	cmpi.w	#28,d5
	ble.s	.ar
	move.l	a2,d0
	sub.l	#rd_alist,d0
	divu.w	#6,d0
	move.w	d0,(rd_alistn).l
.keep	rts

;	Note tile of entry d0 as used; list the cell (d1 x, d2 y) unless the tile is empty or the
;	cell is off screen. a2 = list end, a3 = rd_aused. Keeps d0-d7.
rd_addcell
	move.l	d3,-(sp)
	move.w	d0,d3
	andi.w	#$7FF,d3
	bfset	(a3){d3:1}
	move.w	d0,d3
	andi.w	#$FFF,d3
	lea	(tp_cls).l,a0
	tst.b	(a0,d3.w)
	beq.s	.x
	cmpi.w	#-8,d1
	ble.s	.x
	cmpi.w	#-8,d2
	ble.s	.x
	cmpi.w	#SCRH,d2
	bge.s	.x
	cmp.w	(rd_w).l,d1
	bge.s	.x
	move.w	d1,(a2)+
	move.w	d2,(a2)+
	move.w	d0,(a2)+
.x	move.l	(sp)+,d3
	rts

;	Z clear if screen cell d4 (column), d5 (row) is in the window. Keeps all but the flags.
rd_inwindow
	cmp.w	(rd_wy0).l,d5
	blt.s	.h
	cmp.w	(rd_wy1).l,d5
	blt.s	.yes
.h	cmp.w	(rd_wx0).l,d4
	blt.s	.no
	cmp.w	(rd_wx1).l,d4
	bge.s	.no
.yes	moveq	#1,d0				;(callers reload d0)
	rts
.no	cmp.w	d0,d0				;Z set
	rts

;	Draw entry d0 at screen (d1, d2) if its priority is rd_pass and its tile is not empty.
;	Keeps d4-d7, a4, a5.
rd_drawcell
	move.w	d0,d3
	andi.w	#$8000,d3
	cmp.w	(rd_pass).l,d3
	bne	.x
	move.w	d0,d3
	andi.w	#$FFF,d3
	lea	(tp_cls).l,a0
	tst.b	(a0,d3.w)
	beq	.x				;empty tile
	cmpi.w	#-8,d1
	ble	.x
	cmpi.w	#SCRH,d2
	bge	.x
	cmpi.w	#-8,d2
	ble	.x
	cmp.w	(rd_w).l,d1
	bge	.x
	movem.l	d4-d7/a4-a5,-(sp)
	tst.w	(rd_pass).l
	bne.s	.nocov
	movem.l	d0-d3,-(sp)
	move.w	d1,d0
	move.w	d2,d1
	moveq	#8,d2
	moveq	#8,d3
	bsr	rd_cover_rect
	movem.l	(sp)+,d0-d3
.nocov	; cache rows
	lea	(tp_pl).l,a2
	moveq	#0,d3
	move.w	d0,d3
	andi.w	#$FFF,d3
	lsl.l	#5,d3
	adda.l	d3,a2
	lea	(tp_mk).l,a3
	lsr.l	#2,d3
	adda.l	d3,a3
	moveq	#4,d4				;row steps
	moveq	#1,d5
	btst	#12,d0
	beq.s	.nv
	lea	28(a2),a2
	addq.l	#7,a3
	moveq	#-4,d4
	moveq	#-1,d5
.nv	move.w	d0,d6
	rol.w	#3,d6
	andi.w	#3,d6				;palette
	move.w	d1,d0				;x
	move.w	d2,d7				;y
	movea.l	(rd_back).l,a1
	move.w	d7,d3
	mulu.w	#SROW,d3
	adda.l	d3,a1
	move.w	d6,d2				;palette for rd_put8
	move.w	#7,(rd_rowc).l
.row	tst.w	d7
	bmi.s	.skip
	cmpi.w	#SCRH,d7
	bge.s	.done
	move.l	(a2),d1
	move.b	(a3),d3
	movem.l	d4-d5,-(sp)
	bsr	rd_put8
	movem.l	(sp)+,d4-d5
.skip	adda.w	d4,a2
	adda.w	d5,a3
	lea	SROW(a1),a1
	addq.w	#1,d7
	subq.w	#1,(rd_rowc).l
	bpl.s	.row
.done	movem.l	(sp)+,d4-d7/a4-a5
.x	rts

;	------------------------------------------------------------------------------------------
;	Sprites of priority rd_pass, last in the list first.
rd_sprites_planar
	move.w	(rd_spn).l,d5
	lea	(rd_sprites).l,a4
	move.w	d5,d0
	lsl.w	#3,d0
	adda.w	d0,a4
	subq.w	#1,d5
	bmi.s	.x
.each	subq.l	#8,a4
	move.w	4(a4),d0
	andi.w	#$8000,d0
	cmp.w	(rd_pass).l,d0
	bne.s	.n
	movem.l	d5/a4,-(sp)
	bsr	rd_sprite_planar
	movem.l	(sp)+,d5/a4
.n	dbf	d5,.each
.x	rts

;	Sprite a4.
rd_sprite_planar
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
	; off screen?
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
	tst.w	(rd_pass).l
	bne.s	.nocov
	move.w	d3,d0
	move.w	(rd_sy).l,d1
	move.w	(rd_scw).l,d2
	lsl.w	#3,d2
	move.w	(rd_sch).l,d3
	lsl.w	#3,d3
	bsr	rd_cover_rect
.nocov	move.w	(rd_sat).l,d0
	rol.w	#3,d0
	andi.w	#3,d0
	move.w	d0,(rd_spal).l
	; columns
	moveq	#0,d6				;column
.col	move.w	d6,d0
	lsl.w	#3,d0
	add.w	(rd_sx).l,d0			;screen x of the column
	cmpi.w	#-(SCRX*8-8),d0
	blt	.ncol
	cmp.w	(rd_w).l,d0
	bge	.x
	move.w	d0,(rd_colx).l
	; tile: base + c' * cells down, c' = column (reversed when flipped)
	move.w	d6,d1
	move.w	(rd_sat).l,d3
	btst	#11,d3
	beq.s	.nhf
	move.w	(rd_scw).l,d1
	subq.w	#1,d1
	sub.w	d6,d1
.nhf	mulu.w	(rd_sch).l,d1
	add.w	d3,d1
	andi.l	#$7FF,d1
	btst	#11,d3
	beq.s	.nf2
	bset	#11,d1
.nf2	move.l	d1,(rd_ctile).l
	; rows
	moveq	#0,d7
.row	move.w	(rd_sy).l,d0
	add.w	d7,d0
	bmi	.nrow
	cmpi.w	#SCRH,d0
	bge	.ncol
	movea.l	(rd_back).l,a1
	mulu.w	#SROW,d0
	adda.l	d0,a1
	; row within the sprite (flipped?)
	move.w	d7,d1
	btst	#12,(rd_sat).l
	beq.s	.nvf
	move.w	(rd_sch).l,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	sub.w	d7,d1
.nvf	move.l	(rd_ctile).l,d2
	move.w	d1,d0
	lsr.w	#3,d0
	add.l	d0,d2				;tile of this row (column major)
	andi.w	#7,d1
	move.l	d2,d0
	lsl.l	#3,d0
	add.w	d1,d0
	lea	(tp_mk).l,a0
	move.b	(a0,d0.l),d3			;mask
	beq.s	.nrow
	lea	(tp_pl).l,a0
	lsl.l	#2,d0
	move.l	(a0,d0.l),d1			;planes
	move.w	(rd_spal).l,d2
	move.w	(rd_colx).l,d0
	movem.l	d6-d7,-(sp)
	bsr	rd_put8
	movem.l	(sp)+,d6-d7
.nrow	addq.w	#1,d7
	move.w	(rd_sch).l,d0
	lsl.w	#3,d0
	cmp.w	d0,d7
	blt	.row
.ncol	addq.w	#1,d6
	cmp.w	(rd_scw).l,d6
	blt	.col
.x	rts

;	------------------------------------------------------------------------------------------
;	High priority plane B cells under something of low priority: draw them again on top.
rd_fixups
	move.w	(rd_hiBn).l,d7
	subq.w	#1,d7
	bmi	.x
	lea	(rd_hiB).l,a4
.each	move.w	(a4)+,d4			;column
	move.w	(a4)+,d5			;row
	; screen position (wrapping)
	move.w	d4,d0
	lsl.w	#3,d0
	sub.w	(rd_bx0).l,d0
	move.w	(rd_cw).l,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	cmp.w	(rd_w).l,d0
	blt.s	.xok
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
	blt.s	.yok
	sub.w	d1,d2
	subq.w	#1,d2
	cmpi.w	#-8,d2
	ble	.next
.yok	; covered?
	move.w	d0,(rd_fx).l
	move.w	d2,(rd_fy).l
	bsr	rd_iscovered
	beq	.next
	; redraw from the bitmap: 6 plane bytes and the mask per row
	move.w	(rd_cw).l,d3
	move.w	d5,d1
	lsl.w	#3,d1				;plane pixel row
	moveq	#0,d6				;row in cell
.row	move.w	(rd_fy).l,d2
	add.w	d6,d2
	bmi	.nr
	cmpi.w	#SCRH,d2
	bge	.next
	movea.l	(rd_back).l,a1
	mulu.w	#SROW,d2
	adda.l	d2,a1
	lea	(bmB).l,a0
	move.w	d1,d2
	add.w	d6,d2
	mulu.w	d3,d2
	mulu.w	#6,d2
	adda.l	d2,a0
	adda.w	d4,a0				;plane 0 byte
	move.b	(a0),d0
	lsl.w	#8,d0
	adda.w	d3,a0
	move.b	(a0),d0
	swap	d0
	adda.w	d3,a0
	move.b	(a0),d0
	lsl.w	#8,d0
	adda.w	d3,a0
	move.b	(a0),d0
	move.l	d0,(rd_tmp+4).l			;planes 0-3
	moveq	#0,d2
	adda.w	d3,a0
	tst.b	(a0)
	beq.s	.p4
	moveq	#1,d2
.p4	adda.w	d3,a0
	tst.b	(a0)
	beq.s	.p5
	addq.w	#2,d2
.p5	lea	(mkB).l,a0
	move.w	d1,d0
	add.w	d6,d0
	mulu.w	d3,d0
	adda.l	d0,a0
	movem.l	d1/d3-d7/a4,-(sp)
	move.b	(a0,d4.w),d3			;mask
	move.l	(rd_tmp+4).l,d1
	move.w	(rd_fx).l,d0
	bsr	rd_put8
	movem.l	(sp)+,d1/d3-d7/a4
.nr	addq.w	#1,d6
	cmpi.w	#8,d6
	blt	.row
.next	dbf	d7,.each
.x	rts

;	Z clear if a screen cell under the 8x8 box at (d0, d2) is marked in rd_cover. Keeps d0-d5.
rd_iscovered
	movem.l	d0-d5,-(sp)
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
	bpl.s	.1
	moveq	#0,d4
.1	tst.w	d1
	bpl.s	.2
	moveq	#0,d1
.2	cmpi.w	#39,d5
	ble.s	.3
	moveq	#39,d5
.3	cmpi.w	#27,d3
	ble.s	.4
	moveq	#27,d3
.4	lea	(rd_cover).l,a0
.r	cmp.w	d3,d1
	bgt.s	.no
	move.w	d1,d0
	lsl.w	#6,d0
	add.w	d4,d0
	move.w	d4,d2
.c	cmp.w	d5,d2
	bgt.s	.nr
	tst.b	(a0,d0.w)
	bne.s	.yes
	addq.w	#1,d0
	addq.w	#1,d2
	bra.s	.c
.nr	addq.w	#1,d1
	bra.s	.r
.yes	movem.l	(sp)+,d0-d5
	moveq	#1,d6				;Z clear
	rts
.no	movem.l	(sp)+,d0-d5
	moveq	#0,d6				;Z set
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
rd_fx		ds.w	1
rd_fy		ds.w	1
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
	bne.s	.line
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
	beq.s	.cls
	move.l	d1,d2
	andi.l	#$77777777,d2
	addi.l	#$77777777,d2
	or.l	d1,d2
	andi.l	#$88888888,d2
	moveq	#2,d3
	cmpi.l	#$88888888,d2
	bne.s	.cls
	moveq	#1,d3
.cls	lea	(rd_rowbuf).l,a1
	lea	(rd_nibtab).l,a0
	btst	#11,d0
	beq.s	.n
	lea	(rd_revtab).l,a0
	; flipped: bytes in reverse order through the swapped table
	moveq	#0,d2
	moveq	#3,d0
.f	move.b	d1,d2
	move.w	(a0,d2.w*2),(a1)+
	lsr.l	#8,d1
	dbf	d0,.f
	bra.s	.x
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
	beq.s	.hsdone
	move.w	d7,d2
	cmpi.w	#2,d1
	bne.s	.hsline
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
	bmi.s	.down
	cmp.w	d1,d7
	blt	rd_winline
	bra.s	.hwin
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
	beq.s	.32
	andi.w	#$3C,d0
	bra.s	.b
.32	andi.w	#$3E,d0
.b	lsl.l	#8,d0
	lsl.l	#2,d0
	rts

rd_line_split
	lsl.w	#4,d0
	move.w	d0,-(sp)
	tst.b	17(a5)
	bmi.s	.right
	move.w	(sp),(rd_clipx0).l
	move.w	(rd_w).l,(rd_clipx1).l
	bsr	.drawA
	clr.w	(rd_clipx0).l
	move.w	(sp)+,(rd_clipx1).l
	bra.s	.win
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
	bne.s	.scrolled
	move.w	(rd_cells).l,d4
	moveq	#5,d5
	cmpi.w	#41,d4
	bne.s	.w32
	moveq	#6,d5
.w32	moveq	#0,d1
	move.w	d7,d2
	move.w	#$FFFF,d3
	bra.s	.go
.scrolled
	move.b	16(a5),d4
	moveq	#5,d5
	btst	#0,d4
	beq.s	.wa
	moveq	#6,d5
	btst	#1,d4
	beq.s	.wa
	moveq	#7,d5
.wa	moveq	#5,d3
	btst	#4,d4
	beq.s	.ha
	moveq	#6,d3
	btst	#5,d4
	beq.s	.ha
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
	beq.s	.nv
	eori.w	#7,d6
.nv	andi.l	#$FFF,d0
	bsr	rd_row8				;rd_rowbuf, d3 = class
	tst.w	(rd_mode).l
	bne.s	.trans
	; opaque layer: transparent pixels keep the palette (backdrop), never the priority
	cmpi.b	#1,d3
	beq.s	.ofast
	btst	#6,d7
	beq.s	.ofast
	movea.l	a3,a0
	moveq	#7,d6
.opix	move.b	(a0)+,d3
	beq.s	.oz
	or.b	d7,d3
	move.b	d3,(a2)+
	dbf	d6,.opix
	bra.s	.next
.oz	move.b	d7,d3
	andi.b	#$30,d3
	move.b	d3,(a2)+
	dbf	d6,.opix
	bra.s	.next
.ofast	move.l	(a3),d6
	or.l	d7,d6
	move.l	d6,(a2)+
	move.l	4(a3),d6
	or.l	d7,d6
	move.l	d6,(a2)+
	bra.s	.next
.trans	tst.b	d3
	bne.s	.tdraw
	addq.l	#8,a2
	bra.s	.next
.tdraw	movem.l	d1/d4,-(sp)
	move.l	a2,d1
	sub.l	a6,d1
	subi.w	#CHLEFT,d1			;screen x
	movea.l	a3,a0
	moveq	#7,d4
.tp	move.b	(a0)+,d3
	beq.s	.tn
	cmpi.w	#2,(rd_mode).l
	bne.s	.tnc
	cmp.w	(rd_clipx0).l,d1
	blt.s	.tn
	cmp.w	(rd_clipx1).l,d1
	bge.s	.tn
.tnc	btst	#6,d7
	bne.s	.tw
	btst	#6,(a2)
	bne.s	.tn
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

;	Sprites into the chunky buffer, last first.
rd_sprites_chunky
	bsr	rd_collect_sprites
	move.w	(rd_spn).l,d5
	lea	(rd_sprites).l,a1
	move.w	d5,d0
	lsl.w	#3,d0
	adda.w	d0,a1
	subq.w	#1,d5
	bmi.s	.x
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
	beq.s	.nvf
	move.w	(rd_sh).l,d7
	sub.w	d6,d7
.nvf	moveq	#0,d1
.col	move.w	d1,d0
	btst	#11,d3
	beq.s	.nhf
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
	beq.s	.nf2
	bset	#11,d0
.nf2	move.l	d6,-(sp)
	move.w	d7,d6
	andi.w	#7,d6
	move.l	d3,-(sp)
	bsr	rd_row8
	tst.b	d3
	movem.l	(sp)+,d3
	movem.l	(sp)+,d6
	beq.s	.ncol
	lea	(rd_rowbuf).l,a0
	move.w	(rd_sx).l,d0
	move.w	d1,d2
	lsl.w	#3,d2
	add.w	d2,d0
	movea.l	a2,a3
	adda.w	d2,a3
	moveq	#7,d4
.px	move.b	(a0)+,d2
	beq.s	.pn
	tst.w	d0
	bmi.s	.pn
	cmp.w	(rd_w).l,d0
	bge.s	.pn
	btst	#15,d3
	bne.s	.pw
	btst	#6,(a3)
	bne.s	.pn
.pw	or.b	(rd_sor+1).l,d2
	move.b	(a3),d5
	andi.b	#$40,d5
	or.b	d5,d2
	btst	#15,d3
	beq.s	.pw2
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
	lea	(vdp_cram).l,a0
	lea	(rd_colours).l,a1
	moveq	#63,d0
.c	move.w	(a0)+,d1
	bsr.s	rd_gen2amiga
	move.w	d2,(a1)+
	dbf	d0,.c
	lea	(rd_colours).l,a1
	moveq	#0,d0
	move.b	(vdp_regs+7).l,d0
	andi.w	#$3F,d0
	move.w	(a1,d0.w*2),d1
	move.w	d1,(a1)
	move.w	d1,32(a1)
	move.w	d1,64(a1)
	move.w	d1,96(a1)
	btst	#6,(vdp_regs+1).l
	bne.s	.on
	moveq	#31,d0				;display off: black
.off	clr.l	(a1)+
	dbf	d0,.off
.on	rts

rd_gen2amiga
	moveq	#0,d2
	move.w	d1,d3
	lsr.w	#1,d3
	andi.w	#7,d3
	move.b	(.x7,pc,d3.w),d3
	lsl.w	#8,d3
	or.w	d3,d2
	move.w	d1,d3
	lsr.w	#5,d3
	andi.w	#7,d3
	move.b	(.x7,pc,d3.w),d3
	lsl.w	#4,d3
	or.w	d3,d2
	move.w	d1,d3
	lsr.w	#8,d3
	lsr.w	#1,d3
	andi.w	#7,d3
	move.b	(.x7,pc,d3.w),d3
	or.w	d3,d2
	rts
.x7	dc.b	0,2,4,6,9,11,13,15

;	------------------------------------------------------------------------------------------
;	The back buffer's copper list: 6 interleaved planes, 2x fetch (FMODE 1), 320 pixels
;	fetched from screen x 0 (H40) or -32 (H32, the window shows the middle 256), 224 lines,
;	the 64 colours. It becomes the copper's list from the next frame; the buffers swap.
COPMOVE	MACRO
	move.w	#\1,(a0)+
	move.w	\2,(a0)+
	ENDM

rd_show
	movea.l	(rd_backcop).l,a0
	move.l	(rd_back).l,d0
	cmpi.w	#320,(rd_w).l
	beq.s	.w320
	COPMOVE	$08E,#$3CA1			;DIWSTRT
	COPMOVE	$090,#$1CA1			;DIWSTOP
	addi.l	#SCRX-4,d0
	bra.s	.dw
.w320	COPMOVE	$08E,#$3C81
	COPMOVE	$090,#$1CC1
	addq.l	#SCRX,d0
.dw	COPMOVE	$092,#$0038			;DDFSTRT
	COPMOVE	$094,#$00C8			;DDFSTOP (2x fetch)
	COPMOVE	$108,#SROW-40			;BPL1MOD: interleaved
	COPMOVE	$10A,#SROW-40			;BPL2MOD
	COPMOVE	$100,#$6201			;BPLCON0: 6 planes, colour, ECS bits on
	COPMOVE	$102,#0				;BPLCON1
	COPMOVE	$104,#$0024			;BPLCON2
	COPMOVE	$1FC,#$0001			;FMODE: 32 bit bitplane fetch
	COPMOVE	$10C,#$0011			;BPLCON4
	move.w	#$0E0,d1
	moveq	#NPLANES-1,d2
.bp	move.w	d1,(a0)+
	swap	d0
	move.w	d0,(a0)+
	addq.w	#2,d1
	move.w	d1,(a0)+
	swap	d0
	move.w	d0,(a0)+
	addq.w	#2,d1
	addi.l	#SBPR,d0
	dbf	d2,.bp
	lea	(rd_colours).l,a1
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
	addq.w	#1,d3
	cmpi.w	#2,d3
	bne.s	.bank
	move.l	#$FFFFFFFE,(a0)+
	move.l	(rd_backcop).l,d0
	move.l	d0,(CUSTOM+$080).l		;COP1LC: from the next frame
	move.l	(rd_frontcop).l,(rd_backcop).l
	move.l	d0,(rd_frontcop).l
	move.l	(rd_back).l,d0
	lea	(rd_screens).l,a0
	cmp.l	a0,d0
	bne.s	.second
	addi.l	#SCRSIZE,d0
	bra.s	.set
.second	move.l	a0,d0
.set	move.l	d0,(rd_back).l
	rts

	section	bss,bss
rd_tline	ds.w	1
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
