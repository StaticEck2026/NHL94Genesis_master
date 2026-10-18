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
rd_sprimg	ds.b	SPRBUF*4		;two (image, mask) pairs
rd_ovl		ds.b	SCRSIZE			;plane A / window overlay
rd_ovlmlo	ds.b	SBPR*SCRH		;its low priority mask
rd_ovlmhi	ds.b	SBPR*SCRH		;its high priority mask (follows the low one)

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
.loop	cmp.l	d0,d1
	bhi	.x
	bfset	(a0){d1:1}
	addq.l	#1,d1
	bra	.loop
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
	beq	.next
	clr.l	(a4)
	moveq	#1,d3
	moveq	#31,d5
.bit	btst	d5,d6
	beq	.nb
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
	bne	.long
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
	bne	.ne
	moveq	#0,d0
	bra	.cl
.ne	cmpi.w	#$FF00,d4
	blo	.cl
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
	bne	.changed
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
	bsr	rd_blitB
	bsr	rd_collect_sprites
	lea	(rd_cover).l,a0			;nothing low drawn yet
	move.w	#64*32/4-1,d0
.c	clr.l	(a0)+
	dbf	d0,.c
	bsr	rd_buildA
	tst.b	(rd_ovldirty).l
	beq	.ovl
	bsr	rd_ovl_redraw
.ovl	clr.w	(rd_pass).l
	bsr	rd_ovl_blit
	bsr	rd_waitblit			;the CPU draws the sprites
	bsr	rd_sprites_planar
	bsr	rd_waitblit
	bsr	rd_fixups
	move.w	#$8000,(rd_pass).l
	bsr	rd_ovl_blit
	bsr	rd_waitblit
	bsr	rd_sprites_planar
	bra	rd_waitblit

rd_waitblit
	btst	#6,(CUSTOM+DMACONR).l		;(first read is early on old chips)
.w	btst	#6,(CUSTOM+DMACONR).l
	bne	.w
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
	beq	.same
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
	tst.w	d6
	bne	.cell
	tst.l	(rd_btchg).l
	bne	.cell
	; only entries can have changed: find the changed longs quickly
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
.fdone	tst.w	(rd_hiBok).l
	bne	.x
	bra	rd_list_hiB
.cell	move.w	(a0)+,d0
	tst.w	d6
	bne	.draw
	cmp.w	(a1),d0
	bne	.draw
	tst.l	(rd_btchg).l
	beq	.next
	move.w	d0,d1
	andi.w	#$7FF,d1
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
	bmi	.hi
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
	bpl	.n
	move.w	d4,(a1)+
	move.w	d5,(a1)+
	addq.w	#1,d3
.n	addq.w	#1,d4
	cmp.w	d6,d4
	bne	.c
	addq.w	#1,d5
	cmp.w	d7,d5
	bne	.r
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
	lea	(CUSTOM).l,a6
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
.coll	move.w	d1,d0
	lsl.w	#3,d0
	move.l	(a0,d0.w),(a1)+
	move.l	4(a0,d0.w),(a1)+
	addq.w	#1,d5
	moveq	#0,d1
	move.b	3(a0,d0.w),d1
	andi.b	#$7F,d1
	beq	.done
	cmp.w	d6,d5
	blt	.coll
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
	bne	.bmask
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
	beq	.a4
	moveq	#-1,d6
.a4	move.b	d6,4*SBPR(a0)
	moveq	#0,d6
	btst	#1,d2
	beq	.a5
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
	beq	.b4
	or.b	d4,d7
.b4	move.b	d7,4*SBPR(a0)
	move.b	5*SBPR(a0),d7
	and.b	d6,d7
	btst	#1,d2
	beq	.b5
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
	beq	.s4
	or.w	d4,d7
.s4	move.w	d7,4*SBPR(a0)
	move.w	5*SBPR(a0),d7
	and.w	d6,d7
	btst	#1,d2
	beq	.s5
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
	lea	(rd_cover).l,a0
.r	move.w	d1,d4
	lsl.w	#6,d4
	add.w	d0,d4
	move.w	d0,d5
.c	st	(a0,d4.w)
	addq.w	#1,d4
	addq.w	#1,d5
	cmp.w	d2,d5
	ble	.c
	addq.w	#1,d1
	cmp.w	d3,d1
	ble	.r
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
	bmi	.x
.c	move.w	(a4)+,d1
	move.w	(a4)+,d2
	move.w	(a4)+,d0
	bsr	rd_drawcell
	dbf	d7,.c
.x	rts

;	------------------------------------------------------------------------------------------
;	The plane A / window overlay: the listed cells drawn into a screen sized bitmap with a mask
;	plane per priority, redrawn only when the list changes. Each frame the blitter cuts the
;	rows that have cells into the screen, low priority before the sprites, high after.

rd_ovl_redraw
	sf	(rd_ovldirty).l
	; clear image and masks (blitter, D only)
	bsr	rd_waitblit
	lea	(CUSTOM).l,a6
	move.w	#$0100,$040(a6)
	move.w	#0,$042(a6)
	move.l	#rd_ovl,$054(a6)
	move.w	#0,$066(a6)
	move.w	#SCRH*6,$05C(a6)
	move.w	#SBPR/2,$05E(a6)
	bsr	rd_waitblit
	move.l	#rd_ovlmlo,$054(a6)
	move.w	#SCRH*2,$05C(a6)		;both mask planes (they follow each other)
	move.w	#SBPR/2,$05E(a6)
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
	mulu.w	#SROW,d3
	adda.l	d3,a1
	move.l	(a2),d1
	move.b	(a3),d3
	movem.l	d4-d7/a5,-(sp)
	bsr	rd_put8
	movem.l	(sp)+,d4-d7/a5
	; mask: or the row's mask bits in
	move.w	d7,d6
	mulu.w	#SBPR,d6
	lea	(a5,d6.l),a0
	move.w	d0,d6
	addi.w	#SCRX*8,d6
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
	rts
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
	tst.w	(rd_pass).l
	bne	.nocov
	movem.l	d0-d3,-(sp)
	move.w	d1,d4
	sub.w	d0,d4
	addq.w	#1,d4
	move.w	d2,d1
	move.w	d4,d2
	bsr	rd_cover_rect
	movem.l	(sp)+,d0-d3
.nocov	; words
	addi.w	#SCRX*8,d0
	addi.w	#SCRX*8,d1
	tst.w	d0
	bpl	.x0
	moveq	#0,d0
.x0	cmpi.w	#SBPR*8-1,d1
	ble	.x1
	move.w	#SBPR*8-1,d1
.x1	lsr.w	#4,d0
	lsr.w	#4,d1
	sub.w	d0,d1
	addq.w	#1,d1				;words
	add.w	d0,d0				;first byte
	move.w	d2,d4
	mulu.w	#SROW,d4			;screen / overlay line offset
	move.w	d2,d5
	mulu.w	#SBPR,d5			;mask line offset
	movea.l	(rd_back).l,a0
	adda.l	d4,a0
	adda.w	d0,a0
	lea	(rd_ovl).l,a1
	adda.l	d4,a1
	adda.w	d0,a1
	lea	(a3,d5.l),a2
	adda.w	d0,a2
	move.w	d1,d4
	add.w	d4,d4				;bytes a row
	moveq	#NPLANES-1,d6
	lea	(CUSTOM).l,a6
.plane	bsr	rd_waitblit
	move.w	#$0FCA,$040(a6)
	move.w	#0,$042(a6)
	move.w	#$FFFF,$044(a6)
	move.w	#$FFFF,$046(a6)
	move.l	a2,$050(a6)			;A: mask
	move.l	a1,$04C(a6)			;B: overlay plane
	move.l	a0,$048(a6)			;C
	move.l	a0,$054(a6)			;D
	move.w	#SBPR,d5
	sub.w	d4,d5
	move.w	d5,$064(a6)			;AMOD
	move.w	#SROW,d5
	sub.w	d4,d5
	move.w	d5,$062(a6)			;BMOD
	move.w	d5,$060(a6)			;CMOD
	move.w	d5,$066(a6)			;DMOD
	move.w	d3,$05C(a6)
	move.w	d1,$05E(a6)
	lea	SBPR(a0),a0
	lea	SBPR(a1),a1
	dbf	d6,.plane
.bx	rts

;	Redraw the overlay cells of the listed changed name table longs (rd_chgA, rd_chgW), plane A
;	scrolled by whole cells. d6 = plane cells across, d7 = down.
rd_ovl_cells_changed
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
	andi.w	#$7FF,d3
	lea	(rd_aused).l,a3
	bfset	(a3){d3:1}
	move.w	d1,d3
	addi.w	#SCRX*8,d3
	lsr.w	#3,d3				;byte
	moveq	#7,d4
	move.w	d2,d5				;line
.cl	tst.w	d5
	bmi.s	.cn
	cmpi.w	#SCRH,d5
	bge.s	.cn
	lea	(rd_ovl).l,a0
	move.w	d5,d6
	mulu.w	#SROW,d6
	adda.l	d6,a0
	adda.w	d3,a0
	clr.b	(a0)
	clr.b	SBPR(a0)
	clr.b	2*SBPR(a0)
	clr.b	3*SBPR(a0)
	clr.b	4*SBPR(a0)
	clr.b	5*SBPR(a0)
	lea	(rd_ovlmlo).l,a0
	move.w	d5,d6
	mulu.w	#SBPR,d6
	adda.l	d6,a0
	adda.w	d3,a0
	clr.b	(a0)
	clr.b	SBPR*SCRH(a0)			;the high mask
.cn	addq.w	#1,d5
	dbf	d4,.cl
	move.w	d0,d3
	andi.w	#$FFF,d3
	lea	(tp_cls).l,a0
	tst.b	(a0,d3.w)
	beq.s	.x
	bsr	rd_ovl_cell
.x	movem.l	(sp)+,d0-d7/a0-a6
	rts

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
	andi.w	#$7FF,d3
	bfset	(a3){d3:1}
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
	bne	.nocov
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
	beq	.nv
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
	bmi	.skip
	cmpi.w	#SCRH,d7
	bge	.done
	move.l	(a2),d1
	move.b	(a3),d3
	movem.l	d4-d7,-(sp)
	bsr	rd_put8
	movem.l	(sp)+,d4-d7
.skip	adda.w	d4,a2
	adda.w	d5,a3
	lea	SROW(a1),a1
	addq.w	#1,d7
	subq.w	#1,(rd_rowc).l
	bpl	.row
.done	movem.l	(sp)+,d4-d7/a4-a5
.x	rts

;	------------------------------------------------------------------------------------------
;	Sprites of priority rd_pass, last in the list first. The CPU builds each sprite's image (6
;	interleaved planes) and mask (the same 6 times) in chip RAM, the blitter cuts it into the
;	screen at any pixel position. Two image buffers: the next sprite is built while the blitter
;	draws the last one.
SPRMAXB		equ	6			;bytes a row: up to 32 pixels and the shift word
SPRBUF		equ	32*6*SPRMAXB		;one image (or mask)

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
	movem.l	d5/a4,-(sp)
	bsr	rd_sprite_blit
	movem.l	(sp)+,d5/a4
.n	dbf	d5,.each
.x	rts

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
	tst.w	(rd_pass).l
	bne	.nocov
	move.w	d3,d0
	move.w	(rd_sy).l,d1
	move.w	(rd_scw).l,d2
	lsl.w	#3,d2
	move.w	(rd_sch).l,d3
	lsl.w	#3,d3
	bsr	rd_cover_rect
.nocov	; columns left of the screen margin are dropped
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
	addq.w	#1,d0
	add.w	d0,d0
	move.w	d0,(rd_wb).l			;bytes a row: the columns, rounded to words, + 1 word
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
	; build image and mask
	lea	(rd_sprimg).l,a2
	tst.b	(rd_sprflip).l
	beq	.b0
	lea	SPRBUF*2(a2),a2
.b0	not.b	(rd_sprflip).l
	lea	SPRBUF(a2),a3			;mask
	move.l	a2,(rd_simg).l
	move.l	a3,(rd_smask).l
	IFD	SPRBLIT
	bsr	rd_spr_build
	ELSE
	bra	rd_spr_cpu
	ENDIF
.blit	move.w	(rd_r1).l,d5
	sub.w	(rd_r0).l,d5			;rows
	ble	.x
	move.w	(rd_wb).l,d4			;bytes a row
	bsr	rd_waitblit
	lea	(CUSTOM).l,a6
	move.w	(rd_colx).l,d0
	addi.w	#SCRX*8,d0
	move.w	d0,d1
	andi.w	#15,d1				;shift
	lsr.w	#4,d0
	add.w	d0,d0				;destination byte of the first word
	ror.w	#4,d1
	move.w	d1,d2
	ori.w	#$0FCA,d2			;A mask, B image, C, D; AB + /AC
	move.w	d2,$040(a6)
	move.w	d1,$042(a6)
	move.w	#$FFFF,$044(a6)
	move.w	#$FFFF,$046(a6)
	move.l	(rd_smask).l,$050(a6)		;BLTAPT
	move.l	(rd_simg).l,$04C(a6)		;BLTBPT
	movea.l	(rd_back).l,a0
	move.w	(rd_sy).l,d1
	add.w	(rd_r0).l,d1
	mulu.w	#SROW,d1
	adda.l	d1,a0
	adda.w	d0,a0
	move.l	a0,$048(a6)			;BLTCPT
	move.l	a0,$054(a6)			;BLTDPT
	move.w	#0,$064(a6)			;BLTAMOD
	move.w	#0,$062(a6)			;BLTBMOD
	move.w	#SBPR,d0
	sub.w	d4,d0
	move.w	d0,$060(a6)			;BLTCMOD
	move.w	d0,$066(a6)			;BLTDMOD
	mulu.w	#6,d5
	move.w	d5,$05C(a6)			;BLTSIZV
	move.w	d4,d0
	lsr.w	#1,d0
	move.w	d0,$05E(a6)			;BLTSIZH: go
.x	rts

;	Draw the sprite described by rd_sx..rd_r1 straight into the back buffer: for each line the
;	tile rows of its columns are merged into one field per plane (up to 32 pixels) and written
;	with bitfield instructions under the mask.
rd_spr_cpu
	move.w	(rd_colx).l,d0
	addi.w	#SCRX*8,d0
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
.ctd	; lines
	move.w	(rd_r0).l,d5
.line	cmp.w	(rd_r1).l,d5
	bge	.x
	; source line: tile row and line in the tile (vertical flip from the other end)
	move.w	d5,d0
	btst	#4,(rd_sat).l
	beq.s	.nv
	move.w	(rd_sch).l,d0
	lsl.w	#3,d0
	subq.w	#1,d0
	sub.w	d5,d0
.nv	move.w	d0,d1
	lsr.w	#3,d1				;tile row
	andi.w	#7,d0				;line
	; gather the columns into plane longs d2 (p0), d3 (p1), rd_gp2 (p2), a5 (p3) and the mask a6
	moveq	#0,d2
	moveq	#0,d3
	clr.l	(rd_gp2).l
	suba.l	a5,a5
	suba.l	a6,a6
	lea	(rd_ctiles).l,a0
	move.w	(rd_ncol).l,d7
	subq.w	#1,d7
.g	moveq	#0,d6
	move.w	(a0)+,d6			;tile of the column's top row
	add.w	d1,d6				;this row's tile (columns are tile rows apart)
	andi.w	#$FFF,d6
	lea	(tp_mk).l,a1
	lsl.l	#3,d6
	add.w	d0,d6
	move.l	a6,d4				;(mask in d4 for the moment)
	lsl.l	#8,d4
	move.b	(a1,d6.l),d4
	movea.l	d4,a6
	lsl.l	#2,d6
	lea	(tp_pl).l,a1
	move.l	(a1,d6.l),d6			;p0 p1 p2 p3 of this column's line
	rol.l	#8,d6
	lsl.l	#8,d2
	move.b	d6,d2
	rol.l	#8,d6
	lsl.l	#8,d3
	move.b	d6,d3
	rol.l	#8,d6
	move.l	(rd_gp2).l,d4
	lsl.l	#8,d4
	move.b	d6,d4
	move.l	d4,(rd_gp2).l
	rol.l	#8,d6
	move.l	a5,d4
	lsl.l	#8,d4
	move.b	d6,d4
	movea.l	d4,a5
	dbf	d7,.g
	; left align (4 - columns bytes)
	move.w	(rd_ncol).l,d7
	subq.w	#4,d7
	neg.w	d7
	lsl.w	#3,d7				;bits to shift
	move.l	a6,d6				;mask
	beq	.nl				;nothing on this line
	lsl.l	d7,d6
	lsl.l	d7,d2
	lsl.l	d7,d3
	move.l	(rd_gp2).l,d4
	lsl.l	d7,d4
	move.l	a5,d0
	lsl.l	d7,d0
	movea.l	d0,a5
	; screen line
	movea.l	(rd_back).l,a1
	move.w	(rd_sy).l,d0
	add.w	d5,d0
	mulu.w	#SROW,d0
	adda.l	d0,a1
	move.w	(rd_sbit).l,d1
	move.l	d6,d7
	not.l	d7				;keep mask
	bfextu	(a1){d1:32},d0
	and.l	d7,d0
	or.l	d2,d0
	bfins	d0,(a1){d1:32}
	bfextu	SBPR(a1){d1:32},d0
	and.l	d7,d0
	or.l	d3,d0
	bfins	d0,SBPR(a1){d1:32}
	bfextu	2*SBPR(a1){d1:32},d0
	and.l	d7,d0
	or.l	d4,d0
	bfins	d0,2*SBPR(a1){d1:32}
	move.l	a5,d4
	bfextu	3*SBPR(a1){d1:32},d0
	and.l	d7,d0
	or.l	d4,d0
	bfins	d0,3*SBPR(a1){d1:32}
	bfextu	4*SBPR(a1){d1:32},d0
	and.l	d7,d0
	move.l	d6,d4
	and.l	(rd_spalm).l,d4
	or.l	d4,d0
	bfins	d0,4*SBPR(a1){d1:32}
	bfextu	5*SBPR(a1){d1:32},d0
	and.l	d7,d0
	move.l	d6,d4
	and.l	(rd_spalm+4).l,d4
	or.l	d4,d0
	bfins	d0,5*SBPR(a1){d1:32}
.nl	addq.w	#1,d5
	bra	.line
.x	rts

;	Build the image (a2) and mask (a3) of the sprite described by rd_sx..rd_r1: lines rd_r0 to
;	rd_r1-1, columns rd_c0 on (rd_ncol of them), rows of rd_wb bytes per plane (4 or 6).
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
	; clear both: lines * 6 * wb bytes each
	move.w	(rd_r1).l,d0
	sub.w	(rd_r0).l,d0
	mulu.w	(rd_wb).l,d0
	mulu.w	#6,d0
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
	cmpi.w	#4,(rd_wb).l
	bne.s	.w6
.l4	SPRLINE	4
	dbf	d2,.l4
	bra.s	.ld
.w6
.l6	SPRLINE	6
	dbf	d2,.l6
.ld	movem.l	(sp)+,a2-a3
.ntr	addq.w	#1,(rd_btr).l
	bra	.tr
.ncol	addq.w	#1,(rd_bcol).l
	bra	.col
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
	beq	.p4
	moveq	#1,d2
.p4	adda.w	d3,a0
	tst.b	(a0)
	beq	.p5
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
.4	lea	(rd_cover).l,a0
.r	cmp.w	d3,d1
	bgt	.no
	move.w	d1,d0
	lsl.w	#6,d0
	add.w	d4,d0
	move.w	d4,d2
.c	cmp.w	d5,d2
	bgt	.nr
	tst.b	(a0,d0.w)
	bne	.yes
	addq.w	#1,d0
	addq.w	#1,d2
	bra	.c
.nr	addq.w	#1,d1
	bra	.r
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

;	Sprites into the chunky buffer, last first.
rd_sprites_chunky
	bsr	rd_collect_sprites
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
	lea	(vdp_cram).l,a0
	lea	(rd_colours).l,a1
	moveq	#63,d0
.c	move.w	(a0)+,d1
	bsr	rd_gen2amiga
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
	bne	.on
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
;	Frames drawn in the last second, top left of the screen in colour 63 (F10 shows it).
rd_fps
	move.l	(hal_frames).l,d0
	sub.l	(rd_fpst).l,d0
	cmpi.l	#GENESIS_HZ,d0
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
.t	movea.l	(rd_back).l,a0
	lea	SROW*4+SCRX(a0),a0
	bsr	.digit
	addq.l	#1,a0
	move.w	d1,d0
.digit	; 4x5 digit d0 at byte a0, all 6 planes
	lea	(.font,pc),a1
	mulu.w	#5,d0
	adda.w	d0,a1
	movea.l	a0,a2
	moveq	#4,d2
.r	move.b	(a1)+,d3
	moveq	#NPLANES-1,d4
	movea.l	a2,a3
.p	move.b	d3,(a3)
	lea	SBPR(a3),a3
	dbf	d4,.p
	lea	SROW(a2),a2
	dbf	d2,.r
	rts
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
;	The back buffer's copper list: 6 interleaved planes, 2x fetch (FMODE 1), 320 pixels
;	fetched from screen x 0 (H40) or -32 (H32, the window shows the middle 256), 224 lines,
;	the 64 colours. It becomes the copper's list from the next frame; the buffers swap.
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
	move.l	(rd_back).l,d0
	cmpi.w	#320,(rd_w).l
	beq	.w320
	COPMOVE	$08E,#$3CA1			;DIWSTRT
	COPMOVE	$090,#$1CA1			;DIWSTOP
	addi.l	#SCRX-4,d0
	bra	.dw
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
	bne	.bank
	move.l	#$FFFFFFFE,(a0)+
	move.l	(rd_back).l,(rd_frontshow).l
	move.l	(rd_backcop).l,d0
	move.l	d0,(CUSTOM+$080).l		;COP1LC: from the next frame
	move.l	(rd_frontcop).l,(rd_backcop).l
	move.l	d0,(rd_frontcop).l
	move.l	(rd_back).l,d0
	lea	(rd_screens).l,a0
	cmp.l	a0,d0
	bne	.second
	addi.l	#SCRSIZE,d0
	bra	.set
.second	move.l	a0,d0
.set	move.l	d0,(rd_back).l
	rts

	section	bss,bss
rd_tline	ds.w	1
rd_nchgA	ds.w	1
rd_sbit		ds.w	1
rd_ctiles	ds.w	4
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
		cnop	0,4
rd_frontshow	ds.l	1
rd_ovldirty	ds.w	1
rd_ovlrows	ds.l	2*32			;per priority, per band: x min, x max
rd_ovlcolf	ds.b	2*32*48			;per priority, band: columns with cells
rd_c0		ds.w	1
rd_ncol		ds.w	1
rd_wb		ds.w	1
rd_r0		ds.w	1
rd_r1		ds.w	1
rd_sprflip	ds.w	1
		cnop	0,4
rd_simg		ds.l	1
rd_smask	ds.l	1
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
