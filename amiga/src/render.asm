;	Renderer: draws the game's cells and tiles (vmem.asm) with the layout it set (display.asm)
;	on the AGA display, 6 bitplanes (the 64 colours), interleaved, triple buffered.

SBPR		equ	72
SROW		equ	SBPR*6
SCRX		equ	4
BUFH		equ	480
BUFSIZE		equ	SROW*BUFH
NBUF		equ	3
DLS		equ	3
DLH		equ	1<<DLS
DROWS		equ	BUFH>>DLS
DWRAP		equ	256>>DLS
SCRH		equ	224
HUDH		equ	64
HUDSPR		equ	16+HUDH*16+16
HUDX		equ	$A0
OSBPR		equ	48
OSROW		equ	OSBPR*6
NPLANES		equ	6
BMAX		equ	2048
SCARENA		equ	$40000
SCXMAX		equ	$40000
SCSLOTS		equ	1024

TNEED	macro
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
tp_pl		ds.l	4096*8
tp_mk		ds.b	4096*8
tp_cls		ds.b	4096
rd_rstage	ds.l	8*6*64/4
tc_dirty	ds.l	64
tc_pend		ds.l	64
tc_chg		ds.l	64
rd_ntb		ds.l	3
rd_ntfull	ds.b	1
rd_ntblkm	ds.b	1
	even
rd_tcn		ds.w	1
rd_tcl		ds.w	64
rd_ptab		ds.l	256
rd_pftab	ds.l	256
shB		ds.w	BMAX
rd_tlhead	ds.w	2048
rd_tlnext	ds.w	BMAX
rd_tlprev	ds.w	BMAX
rd_tltile	ds.w	BMAX
rd_hiB		ds.l	BMAX
rd_hibits	ds.l	BMAX/32
rd_fixmap	ds.l	2*32
rd_hiBn		ds.w	1
rd_hiBok	ds.w	1
rd_Bkey		ds.l	2
rd_cover	ds.l	2*32
rd_sprites	ds.l	2*80
rd_scmemo	ds.l	8*80
rd_skey		ds.l	1
rd_spn		ds.w	1
rd_w		ds.w	1
rd_cells	ds.w	1
rd_cw		ds.w	1
rd_ch		ds.w	1
rd_bx0		ds.w	1
rd_by0		ds.w	1
rd_back		ds.l	1
rd_buf		ds.l	1
rd_dmap		ds.l	1
rd_dirty	ds.l	NBUF*DROWS
rd_bufi		ds.w	1
rd_xorg		ds.w	1
rd_brow0	ds.w	1
rd_scroll	ds.w	1
rd_backcop	ds.l	1
rd_copb		ds.l	1
rd_lnta		ds.l	1
rd_lntb		ds.l	1
rd_lntw		ds.l	1
rd_lcw		ds.w	1
rd_lwide	ds.b	1
rd_llines	ds.b	1
rd_lwin		ds.b	1
	even
rd_hs		ds.l	1
rd_vs		ds.l	1
rd_sctab	ds.l	8*SCSLOTS
rd_sslot	ds.w	1
rd_rowoff	ds.l	SCRH
rd_sprnat	ds.b	1
	even
rd_bl0		ds.w	1
rd_bnl		ds.w	1
rd_bp0		ds.w	1
rd_bp1		ds.w	1
rd_scpos	ds.l	1
rd_scoff	ds.l	1
rd_scsize	ds.l	1
rd_scx		ds.l	1
rd_scxsz	ds.l	1
fe_held		ds.b	1
fe_cur		ds.b	1
	even
rd_scmin	ds.l	2
rd_tchg		ds.l	2048
rd_vblanks	ds.l	1
rd_shownvb	ds.l	NBUF
rd_lastframe	ds.l	1
rd_lastgen	ds.l	2
rd_count	ds.l	1
rd_palgen	ds.l	1
rd_colgen	ds.l	1
rd_copgen	ds.l	2*NBUF
rd_colours	ds.w	64
rd_colourslo	ds.w	64
rd_pall		ds.l	256
rd_palh		ds.l	16
rd_pass		ds.w	1
rd_tmp		ds.l	8
rd_cellpri	ds.w	1
mkB		ds.b	BMAX*8

	IFNE	NBUF-3
	FAIL	"rd_scr0-2: a screen buffer each"
	ENDC
	section	scr0,bss_c
rd_scr0		ds.b	BUFSIZE
	section	scr1,bss_c
rd_scr1		ds.b	BUFSIZE
	section	scr2,bss_c
rd_scr2		ds.b	BUFSIZE
	section	ring,bss_c
rd_scarena	ds.b	SCARENA
	section	chip,bss_c
	cnop	0,8
bmB		ds.b	BMAX*48
mkB6		ds.b	BMAX*48
rd_cop		ds.l	2*NBUF*256
rd_cqbuf	ds.b	2*CQI
rd_ovl		ds.b	OSROW*SCRH
rd_fpsimg	ds.w	5*NPLANES*NBUF
	cnop	0,8
rd_hudsd	ds.b	NBUF*8*HUDSPR
rd_sprnull	ds.l	4
rd_ovlmlo	ds.b	OSROW*SCRH
rd_ovlmhi	ds.b	OSROW*SCRH

	section	game,code

rd_init
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	#rd_bmrc,(rd_bmrp).l
	lea	(rd_pall).l,a0
	moveq	#0,d1
.pl	bsr	rd_gen2amiga
	swap	d2
	move.w	d4,d2
	move.l	d2,(a0)+
	addq.w	#1,d1
	cmpi.w	#256,d1
	blo.s	.pl
	lea	(rd_palh).l,a0
	moveq	#0,d1
.ph	bsr	rd_gen2amiga
	swap	d2
	move.w	d4,d2
	move.l	d2,(a0)+
	addi.w	#$100,d1
	cmpi.w	#$1000,d1
	blo.s	.ph
	lea	(rd_ptab).l,a0
	lea	(rd_pftab).l,a1
	moveq	#0,d0
.pt	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
.pp	move.l	#24,d4
	move.w	d3,d5
	lsl.w	#3,d5
	sub.w	d5,d4
	move.w	d3,d5
	addq.w	#4,d5
	btst	d5,d0
	beq	.nl
	move.l	d4,d5
	addq.l	#1,d5
	bset	d5,d1
	bset	d4,d2
.nl	btst	d3,d0
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
	bsr	rd_dirty_all
	lea	(rd_scr0).l,a0
	move.l	a0,(rd_back).l
	move.l	a0,(rd_buf).l
	clr.w	(rd_bufi).l
	lea	(rd_dirty).l,a0
	move.l	a0,(rd_dmap).l
	move.w	#NBUF*DROWS-1,d0
.dm	move.l	#-1,(a0)+
	dbf	d0,.dm
	lea	(rd_oplists).l,a0
	lea	(rd_opold).l,a1
	moveq	#NBUF-1,d0
.ol	move.l	a0,(a1)+
	lea	OPMAX*OPREC(a0),a0
	dbf	d0,.ol
	move.l	a0,(rd_opnew).l
	bsr	rd_op_invall
	move.w	#SCRX*8,(rd_xorg).l
	clr.w	(rd_brow0).l
	lea	(rd_cop).l,a0
	move.l	a0,d0
	move.l	a0,d1
	addi.l	#NBUF*1024-1,d1
	swap	d0
	swap	d1
	cmp.w	d0,d1
	beq.s	.cp
	clr.w	d1
	swap	d1
	movea.l	d1,a0
.cp	move.l	a0,(rd_copb).l
	move.l	a0,(rd_backcop).l
	moveq	#-1,d0
	move.l	d0,(rd_Bkey).l
	move.l	d0,(rd_lastgen).l
	move.l	d0,(rd_palgen).l
	lea	(rd_copgen).l,a0
	moveq	#2*NBUF-1,d1
.cg	move.l	d0,(a0)+
	dbf	d1,.cg
	lea	(rd_shownvb).l,a0
	moveq	#NBUF-1,d1
.sv	move.l	d0,(a0)+
	dbf	d1,.sv
	lea	(rd_sctab).l,a0
	move.w	#SCSLOTS-1,d1
.sc	move.l	d0,(a0)
	lea	32(a0),a0
	dbf	d1,.sc
	tst.b	(rd_sprnat).l
	bne.s	.sn
	st	(rd_sprnat).l
	move.l	(rd_scxsz).l,d0
	add.l	(rd_scs0).l,d0
	move.l	d0,(rd_scsize).l
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
.sn	lea	(rd_rowoff).l,a0
	moveq	#0,d0
	move.w	#SCRH-1,d1
.ro	move.l	d0,(a0)+
	addi.l	#SROW,d0
	dbf	d1,.ro
	bsr	rd_cq_init
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	Tile cache.

;	Video memory d1 (address), d0 (words) changed: convert the tiles it
;	covers again (and they no longer hold the data a load sent, vm_tsrc).
vm_dirty
	movem.l	d0-d2/a0-a1,-(sp)
	addq.l	#1,(ds_gen).l
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
	lea	(vm_tsrc).l,a1
.loop	cmp.l	d0,d1
	bhi	.x
	bfset	(a0){d1:1}
	clr.l	(a1,d1.l*4)
	addq.l	#1,d1
	bra	.loop
.x	movem.l	(sp)+,d0-d2/a0-a1
	rts

vm_dirty_all
rd_dirty_all
	movem.l	d0/a0,-(sp)
	addq.l	#1,(ds_gen).l
	lea	(tc_dirty).l,a0
	moveq	#63,d0
.c	move.l	#-1,(a0)+
	dbf	d0,.c
	lea	(vm_tsrc).l,a0
	move.w	#2048-1,d0
.s	clr.l	(a0)+
	dbf	d0,.s
	movem.l	(sp)+,d0/a0
	rts

;	Convert every dirty tile; tc_chg = the tiles converted (rd_tcn, rd_tcl: its longs with any).
DECHOLD	equ	64
rd_decode_dirty
	move.l	d2,-(sp)
	moveq	#DECHOLD,d2
	lea	(tc_chg).l,a3
	lea	(rd_tcl).l,a0
	move.w	(rd_tcn).l,d0
	bra.s	.ce
.cl	move.w	(a0)+,d1
	clr.l	(a3,d1.w)
.ce	dbf	d0,.cl
	clr.w	(rd_tcn).l
	lea	(tc_dirty).l,a4
	moveq	#0,d3
	moveq	#63,d5
.sc	tst.l	(a4)+
	dbne	d5,.sc
	beq	.x
	move	sr,-(sp)
	ori	#$0700,sr
	move.l	-(a4),d6
	clr.l	(a4)+
	move	(sp)+,sr
	moveq	#63,d7
	sub.w	d5,d7
	move.w	d7,d1
	lsl.w	#2,d1
	move.l	d6,(a3,d1.w)
	lea	(rd_bltiles).l,a0
	move.l	(a0,d1.w),d0
	and.l	d6,d0
	beq.s	.nbl
	st	(rd_bltch).l
.nbl	move.w	(rd_tcn).l,d0
	lea	(rd_tcl).l,a0
	move.w	d1,(a0,d0.w*2)
	addq.w	#1,(rd_tcn).l
	moveq	#1,d3
	lsl.l	#5,d7
.bit	bfffo	d6{0:0},d0
	bfclr	d6{d0:1}
	add.l	d7,d0
	bftst	(rd_bused).l{d0:1}
	bne.s	.now
	bftst	(rd_aused).l{d0:1}
	bne.s	.now
	bfset	(tc_pend).l{d0:1}
	lea	(rd_tchg).l,a0
	move.l	(rd_count).l,(a0,d0.l*4)
	bra.s	.nb
.now	bfclr	(tc_pend).l{d0:1}
	subq.w	#1,d2
	bne.s	.held
	move.w	#$A000,(CUSTOM+INTENA).l
.held	movem.l	d2-d3/d5/a3,-(sp)
	bsr	rd_decode_tile
	movem.l	(sp)+,d2-d3/d5/a3
.nb	tst.l	d6
	bne.s	.bit
	dbf	d5,.sc
.x	move.l	d3,d0
	move.l	(sp)+,d2
	rts

;	Tiles d0 (0-2047) to d0 + d1 - 1 (wrapping round):
;	those waiting (tc_pend) converted. Keeps everything.
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

;	Convert tile d0.
rd_decode_tile
	lea	(rd_tchg).l,a0
	move.l	(rd_count).l,(a0,d0.l*4)
	lea	(vm_tsrc).l,a0
	move.l	(a0,d0.l*4),d1
	subi.l	#Spritetiles,d1
	cmpi.l	#SPRTSIZE,d1
	blo	.nat
	lea	(vm_data).l,a0
	move.l	d0,d1
	lsl.l	#5,d1
	adda.l	d1,a0
	lea	(tp_pl).l,a1
	adda.l	d1,a1
	lea	$800*32(a1),a2
	lea	(tp_mk).l,a3
	move.l	d0,d1
	lsl.l	#3,d1
	adda.l	d1,a3
	lea	(tp_cls).l,a6
	adda.l	d0,a6
	lea	(rd_ptab).l,a5
	moveq	#0,d4
	move.w	#$FF00,d4
	moveq	#7,d3
.row	move.l	(a0)+,d0
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
	moveq	#0,d2
	move.b	d1,d2
	move.b	(rd_rev8,pc,d2.w),$800*8(a3)
	addq.l	#1,a3
	moveq	#0,d1
	moveq	#0,d2
	move.b	d0,d2
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
.nat
	lea	(Spritetiles).l,a0
	adda.l	d1,a0
	move.l	d0,d1
	lsl.l	#5,d1
	lea	(tp_pl).l,a1
	adda.l	d1,a1
	lea	$800*32(a1),a2
	lea	(tp_mk).l,a3
	move.l	d0,d1
	lsl.l	#3,d1
	adda.l	d1,a3
	lea	(tp_cls).l,a6
	adda.l	d0,a6
	lea	(rd_rev8,pc),a5
	moveq	#0,d4
	move.w	#$FF00,d4
	moveq	#0,d2
	moveq	#7,d3
.nr	move.l	(a0)+,d0
	move.l	d0,(a1)+
	rol.l	#8,d0
	move.b	d0,d2
	move.b	(a5,d2.w),d1
	rol.l	#8,d0
	move.b	d0,d2
	lsl.l	#8,d1
	move.b	(a5,d2.w),d1
	rol.l	#8,d0
	move.b	d0,d2
	lsl.l	#8,d1
	move.b	(a5,d2.w),d1
	rol.l	#8,d0
	move.b	d0,d2
	lsl.l	#8,d1
	move.b	(a5,d2.w),d1
	move.l	d1,(a2)+
	move.l	d0,d2
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
	move.b	(a5,d2.w),$800*8(a3)
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

;	One frame into the back buffer, then shown.
rd_frame
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(ds_gen).l,d0
	add.l	(ds_palgen).l,d0
	cmp.l	(rd_lastgen).l,d0
	bne	.changed
	cmp.l	(rd_lastgen+4).l,d0
	beq	.skip
.changed
	move.l	(rd_lastgen).l,(rd_lastgen+4).l
	move.l	d0,(rd_lastgen).l
	bsr	rd_palette
	lea	(rd_colours).l,a0
	moveq	#63,d0
.blk	tst.l	(a0)+
	dbne	d0,.blk
	bne.s	.draw
	bsr	rd_bmrd_age
	bsr	rd_vsync
	bsr	rd_snaptime
	bsr	rd_show
	addq.l	#1,(rd_count).l
	bra	.skip
.draw	bsr	rd_bmrd_age
	bsr	rd_vsync
	move.l	(rd_scmin).l,(rd_scmin+4).l
	move.l	#$7FFFFFFF,(rd_scmin).l
	move.w	#$2000,(CUSTOM+INTENA).l
	bsr	rd_snapshot
	bsr	rd_snaptime
	bsr	rd_palette
	bsr	rd_decode_dirty
	move.w	#$A000,(CUSTOM+INTENA).l
	move.w	#256,d0
	moveq	#33,d1
	tst.b	(rd_lwide).l
	beq	.h32
	move.w	#320,d0
	moveq	#41,d1
.h32	move.w	d0,(rd_w).l
	move.w	d1,(rd_cells).l
	tst.b	(rd_llines).l
	beq.s	.hw
	tst.b	(rd_hsuni).l
	bne.s	.hw
	tst.b	(rd_hslb).l
	beq.s	.hw
	bsr	rd_bline
.hw	bsr	rd_planesize
	mulu.w	d1,d0
	cmpi.l	#BMAX,d0
	bhi.s	.skip
	bsr	rd_fast
	bsr	rd_show
	addq.l	#1,(rd_count).l
.skip	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	d0 = plane cells across, d1 = down. Keeps the rest.
rd_planesize
	moveq	#0,d0
	move.w	(rd_lcw).l,d0
	moveq	#32,d1
	rts

;	Plane B scrolled by lines on 128 x 32 planes drawn as 64 x 32: drawn as scrolled all like the
;	last line, with the rows that have a line scrolled otherwise drawn empty. Uses d0-d7/a0-a4.
rd_bline
	tst.b	(rd_bltch).l
	beq.s	.k
	sf	(rd_bltch).l
	clr.l	(rd_blok).l
	clr.l	(rd_blsb).l
	lea	(rd_bltiles).l,a0
	moveq	#64-1,d0
.kc	clr.l	(a0)+
	dbf	d0,.kc
.k	clr.l	(rd_blfr).l
	clr.l	(rd_blsrn).l
	lea	(vm_data).l,a3
	adda.l	(rd_lntb).l,a3
	lea	(rd_hsb).l,a4
	moveq	#0,d7
	moveq	#0,d5
.l1	move.w	(a4,d5.w*2),d1
	cmp.w	(rd_hs+2).l,d1
	beq.s	.n1
	bsr	.row
	bset	d4,d7
.n1	addq.w	#1,d5
	cmpi.w	#SCRH,d5
	blo.s	.l1
	moveq	#0,d6
	moveq	#0,d4
.r	btst	d4,d7
	beq	.rn
	bsr	.mask
	move.l	(rd_bllo).l,d0
	btst	d4,d0
	bne	.no
	tst.b	d6
	bne.s	.e
	moveq	#0,d1
.ef	bftst	(a2){d1:1}
	beq.s	.eg
	addq.w	#1,d1
	cmpi.w	#128,d1
	blo.s	.ef
	bra.s	.e
.eg	st	d6
	move.w	d4,d0
	lsl.w	#7,d0
	add.w	d1,d0
	move.w	(a3,d0.w*2),(rd_blent).l
.e	move.l	(a2),d0
	or.l	4(a2),d0
	or.l	8(a2),d0
	or.l	12(a2),d0
	beq.s	.rn
	bsr	.seen
	beq.s	.rn
	bsr	.strip
	beq	.no
	move.l	(rd_blsrn).l,d0
	bset	d4,d0
	move.l	d0,(rd_blsrn).l
.rn	addq.w	#1,d4
	cmpi.w	#32,d4
	blo	.r
	tst.b	d6
	beq	.no
	lea	(rd_vntB).l,a0
	move.w	(rd_blent).l,d0
	move.w	d0,d1
	swap	d0
	move.w	d1,d0
	moveq	#0,d4
.h	btst	d4,d7
	beq.s	.hn
	move.w	d4,d1
	lsl.w	#7,d1
	lea	(a0,d1.w),a1
	moveq	#64/2-1,d1
.hf	move.l	d0,(a1)+
	dbf	d1,.hf
.hn	addq.w	#1,d4
	cmpi.w	#32,d4
	blo.s	.h
	move.l	(rd_blsrn).l,(rd_blsr).l
	moveq	#1,d0
	rts
.no	clr.l	(rd_blsr).l
	moveq	#0,d0
	rts
.row	move.w	(rd_vs+2).l,d4
	add.w	d5,d4
	lsr.w	#3,d4
	andi.w	#31,d4
	rts
.mask	lea	(rd_blmask).l,a2
	move.w	d4,d0
	lsl.w	#4,d0
	adda.w	d0,a2
	move.l	(rd_blfr).l,d3
	btst	d4,d3
	bne	.mq
	bset	d4,d3
	move.l	d3,(rd_blfr).l
	movem.l	d1-d2/a0-a1/a4,-(sp)
	move.w	d4,d0
	lsl.w	#8,d0
	lea	(a3,d0.w),a0
	lea	(rd_blcopy).l,a1
	adda.w	d0,a1
	move.l	(rd_blok).l,d3
	btst	d4,d3
	beq.s	.mk
	movem.l	a0-a1,-(sp)
	moveq	#64-1,d0
.mc	cmpm.l	(a0)+,(a1)+
	dbne	d0,.mc
	movem.l	(sp)+,a0-a1
	beq	.mx
.mk	move.l	(rd_blsb).l,d0
	bclr	d4,d0
	move.l	d0,(rd_blsb).l
	sf	(rd_bllow).l
	lea	(tp_cls).l,a4
	clr.l	(a2)
	clr.l	4(a2)
	clr.l	8(a2)
	clr.l	12(a2)
	moveq	#0,d2
	move.l	d4,-(sp)
	move.w	(a0),d4
	not.w	d4
	swap	d4
.mm	move.w	(a0)+,d1
	move.w	d1,(a1)+
	swap	d4
	cmp.w	d4,d1
	beq.s	.ms
	move.w	d1,d4
	swap	d4
	moveq	#0,d0
	move.w	d1,d0
	andi.w	#$7FF,d0
	bfset	(rd_bltiles).l{d0:1}
	bftst	(tc_pend).l{d0:1}
	beq.s	.mp
	move.l	d1,-(sp)
	moveq	#1,d1
	bsr	rd_tiles_need
	move.l	(sp)+,d1
.mp	clr.w	d4
	tst.b	(a4,d0.w)
	beq.s	.me
	move.w	#1,d4
	tst.w	d1
	bmi.s	.mb
	st	(rd_bllow).l
	bra.s	.mb
.ms	swap	d4
	tst.w	d4
	beq.s	.me
.mb	bfset	(a2){d2:1}
.me	addq.w	#1,d2
	cmpi.w	#128,d2
	blo.s	.mm
	move.l	(sp)+,d4
	lea	(rd_blcf).l,a4
	clr.l	(a4,d4.w*4)
	moveq	#0,d1
.f1	bftst	(a2){d1:1}
	bne.s	.f2
	addq.w	#1,d1
	cmpi.w	#128,d1
	blo.s	.f1
	bra.s	.f4
.f2	move.l	#127,d2
.f3	bftst	(a2){d2:1}
	bne.s	.f5
	subq.w	#1,d2
	bra.s	.f3
.f5	sub.w	d1,d2
	addq.w	#1,d2
	move.w	d1,(a4,d4.w*4)
	move.w	d2,2(a4,d4.w*4)
.f4	move.l	(rd_bllo).l,d0
	bclr	d4,d0
	tst.b	(rd_bllow).l
	beq.s	.ml
	bset	d4,d0
.ml	move.l	d0,(rd_bllo).l
	move.l	(rd_blok).l,d3
	bset	d4,d3
	move.l	d3,(rd_blok).l
.mx	movem.l	(sp)+,d1-d2/a0-a1/a4
.mq	rts
.seen	movem.l	d5/a4,-(sp)
	lea	(rd_blcf).l,a4
	move.w	(a4,d4.w*4),d1
	move.w	2(a4,d4.w*4),d2
	lea	(rd_hsb).l,a4
	lsl.w	#3,d1
	lsl.w	#3,d2
	moveq	#7,d3
.vl	move.w	d4,d5
	lsl.w	#3,d5
	add.w	d3,d5
	sub.w	(rd_vs+2).l,d5
	andi.w	#255,d5
	cmpi.w	#SCRH,d5
	bhs.s	.vn
	move.w	(a4,d5.w*2),d0
	add.w	d1,d0
	andi.w	#1023,d0
	cmp.w	(rd_w).l,d0
	blo.s	.vy
	add.w	d2,d0
	cmpi.w	#1024,d0
	bhi.s	.vy
.vn	dbf	d3,.vl
	movem.l	(sp)+,d5/a4
	moveq	#0,d0
	rts
.vy	movem.l	(sp)+,d5/a4
	moveq	#1,d0
	rts
.strip	movem.l	d4-d7/a2-a4,-(sp)
	lea	(rd_blst).l,a4
	move.w	d4,d0
	lsl.w	#4,d0
	adda.w	d0,a4
	move.l	(rd_blsb).l,d0
	btst	d4,d0
	beq.s	.sb
	move.l	(rd_scpos).l,d0
	sub.l	(a4),d0
	cmp.l	(rd_scsize).l,d0
	bls	.sok
.sb	lea	(rd_blcf).l,a0
	move.w	(a0,d4.w*4),d1
	move.w	2(a0,d4.w*4),d2
	cmpi.w	#(1024-320)/8,d2
	bhi	.sno
	move.w	d1,8(a4)
	move.w	d2,10(a4)
	addq.w	#1,d2
	andi.w	#$FFFE,d2
	addq.w	#2,d2
	move.w	d2,12(a4)
	mulu.w	#NPLANES*8,d2
	move.l	d2,-(sp)
	move.l	d2,d1
	add.l	d1,d1
	bsr	rd_sc_alloc
	move.l	d2,(a4)
	move.l	a2,4(a4)
	move.l	(sp)+,d2
	movea.l	a2,a0
	move.l	d2,d0
	lsr.l	#1,d0
	subq.l	#1,d0
.sc	clr.l	(a0)+
	dbf	d0,.sc
	move.l	(sp),d4
	movea.l	4(a4),a0
	move.w	12(a4),d3
	moveq	#0,d5
.scl	move.w	8(a4),d0
	add.w	d5,d0
	andi.w	#127,d0
	move.w	d4,d1
	lsl.w	#7,d1
	add.w	d1,d0
	move.w	(a3,d0.w*2),d0
	bsr	rd_blcell
	addq.w	#1,d5
	cmp.w	10(a4),d5
	blo.s	.scl
	move.l	(rd_blsb).l,d0
	bset	d4,d0
	move.l	d0,(rd_blsb).l
.sok	movem.l	(sp)+,d4-d7/a2-a4
	moveq	#1,d0
	rts
.sno	movem.l	(sp)+,d4-d7/a2-a4
	moveq	#0,d0
	rts

;	Cell entry d0 into a row's image (rd_bline) at a0 + d5: d3 bytes a
;	plane row, its mask (in each plane's place) d2 bytes on. Keeps all.
rd_blcell
	movem.l	d0-d7/a0-a5,-(sp)
	lea	(a0,d5.w),a0
	lea	(a0,d2.l),a4
	move.w	d0,d1
	andi.l	#$FFF,d1
	lea	(tp_pl).l,a1
	move.l	d1,d6
	lsl.l	#5,d6
	adda.l	d6,a1
	lea	(tp_mk).l,a2
	lsl.l	#3,d1
	adda.l	d1,a2
	moveq	#4,d6
	moveq	#1,d7
	btst	#12,d0
	beq.s	.nv
	lea	28(a1),a1
	addq.l	#7,a2
	moveq	#-4,d6
	moveq	#-1,d7
.nv	moveq	#0,d4
	btst	#13,d0
	beq.s	.p0
	moveq	#-1,d4
.p0	moveq	#0,d5
	btst	#14,d0
	beq.s	.p1
	moveq	#-1,d5
.p1	move.w	d3,d0
	add.w	d0,d0
	add.w	d3,d0
	lea	(a0,d0.w),a3
	lea	(a4,d0.w),a5
	move.w	d3,d2
	mulu.w	#NPLANES,d2
	moveq	#7,d1
.row	move.b	(a1),(a0)
	move.b	1(a1),(a0,d3.w)
	move.b	2(a1),(a0,d3.w*2)
	move.b	3(a1),(a3)
	move.b	d4,(a3,d3.w)
	move.b	d5,(a3,d3.w*2)
	move.b	(a2),d0
	move.b	d0,(a4)
	move.b	d0,(a4,d3.w)
	move.b	d0,(a4,d3.w*2)
	move.b	d0,(a5)
	move.b	d0,(a5,d3.w)
	move.b	d0,(a5,d3.w*2)
	adda.w	d6,a1
	adda.w	d7,a2
	adda.w	d2,a0
	adda.w	d2,a3
	adda.w	d2,a4
	adda.w	d2,a5
	dbf	d1,.row
	movem.l	(sp)+,d0-d7/a0-a5
	rts

;	The rows of plane B rd_bline drew empty that have pixels: each
;	line from its row's image at the line's own scroll. Keeps all.
rd_bstrips
	tst.b	(rd_hslb).l
	beq	.x
	tst.l	(rd_blsr).l
	beq	.x
	movem.l	d0-d7/a0-a6,-(sp)
	lea	(rd_hsb).l,a4
	moveq	#0,d7
.l	move.w	(rd_vs+2).l,d0
	add.w	d7,d0
	move.w	d0,d1
	lsr.w	#3,d0
	andi.w	#31,d0
	move.l	(rd_blsr).l,d2
	btst	d0,d2
	beq.s	.n1
	andi.w	#7,d1
	move.w	(a4,d7.w*2),d2
	moveq	#1,d3
.m	move.w	d7,d4
	add.w	d3,d4
	cmpi.w	#SCRH,d4
	bhs.s	.me
	cmp.w	(a4,d4.w*2),d2
	bne.s	.me
	move.w	d1,d4
	add.w	d3,d4
	cmpi.w	#8,d4
	bhs.s	.me
	addq.w	#1,d3
	bra.s	.m
.me	movem.l	d3/d7/a4,-(sp)
	bsr.s	.blit
	movem.l	(sp)+,d3/d7/a4
	add.w	d3,d7
	bra.s	.e
.n1	addq.w	#1,d7
.e	cmpi.w	#SCRH,d7
	blo.s	.l
	bsr	rd_cq_flush
	movem.l	(sp)+,d0-d7/a0-a6
.x	rts
.blit	movea.w	d1,a5
	lea	(rd_blst).l,a6
	lsl.w	#4,d0
	adda.w	d0,a6
	move.w	8(a6),d4
	lsl.w	#3,d4
	add.w	d2,d4
	andi.w	#1023,d4
	move.w	10(a6),d5
	lsl.w	#3,d5
	cmp.w	(rd_w).l,d4
	blo.s	.on
	subi.w	#1024,d4
	move.w	d4,d0
	add.w	d5,d0
	ble	.bx
.on	add.w	(rd_xorg).l,d4
	moveq	#0,d6
	tst.w	d4
	bpl.s	.c1
	move.w	d4,d6
	neg.w	d6
	addi.w	#15,d6
	andi.w	#$FFF0,d6
	add.w	d6,d4
.c1	moveq	#15,d2
	and.w	d4,d2
	ror.w	#4,d2
	lsr.w	#4,d4
	sub.w	d6,d5
	addi.w	#15,d5
	lsr.w	#4,d5
	addq.w	#1,d5
	moveq	#SBPR/2,d0
	sub.w	d4,d0
	ble	.bx
	cmp.w	d0,d5
	bls.s	.c2
	move.w	d0,d5
.c2
	move.w	d4,d0
	subq.w	#2,d0
	bpl.s	.b0
	moveq	#0,d0
.b0	move.w	d4,d1
	add.w	d5,d1
	subq.w	#3,d1
	cmpi.w	#31,d1
	ble.s	.b1
	moveq	#31,d1
.b1	sub.w	d0,d1
	bmi	.bx
	addq.w	#1,d1
	move.b	d0,(rd_opbox+2).l
	move.b	d1,(rd_opbox+3).l
	move.w	(rd_brow0).l,d0
	add.w	d7,d0
	move.w	d0,d1
	add.w	d3,d1
	subq.w	#1,d1
	asr.w	#DLS,d0
	asr.w	#DLS,d1
	sub.w	d0,d1
	move.b	d0,(rd_opbox).l
	move.b	d1,(rd_opbox+1).l
	movea.l	(rd_back).l,a0
	move.w	d7,d0
	mulu.w	#SROW,d0
	adda.l	d0,a0
	lea	(a0,d4.w*2),a0
	move.w	12(a6),d0
	move.w	a5,d1
	movea.l	4(a6),a1
	move.w	d0,d4
	mulu.w	#NPLANES*8,d4
	lea	(a1,d4.l),a2
	mulu.w	#NPLANES,d1
	mulu.w	d0,d1
	lsr.w	#3,d6
	add.w	d6,d1
	adda.l	d1,a1
	adda.l	d1,a2
	move.w	d5,d1
	add.w	d1,d1
	sub.w	d1,d0
	moveq	#SBPR,d1
	sub.w	d5,d1
	sub.w	d5,d1
	move.w	d2,d4
	move.w	d3,d2
	mulu.w	#NPLANES,d2
	move.w	d5,d3
	moveq	#0,d5
	move.l	(a6),d6
	cmp.l	(rd_scmin).l,d6
	bge.s	.sm
	move.l	d6,(rd_scmin).l
.sm	bra	rd_cut_emit
.bx	rts

;	Fast path.
rd_fast
	bsr	rd_updateB
	bsr	rd_scrollpos
	bsr	rd_bpend_run
	bsr	rd_vsync
	tst.w	(rd_scroll).l
	beq.s	.copy
	bsr	rd_op_begin
	bra.s	.b
.copy	bsr	rd_blitB
	moveq	#0,d0
	moveq	#0,d1
	move.w	(rd_w).l,d2
	move.w	#SCRH,d3
	bsr	rd_mark
.b	lea	(rd_cover+2*32*4).l,a0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	REPT	2*32/4
	movem.l	d0-d3,-(a0)
	ENDR
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
.hk	clr.w	(rd_pass).l
	bsr	rd_ovl_blit
	bsr	rd_sprites_planar
	bsr	rd_fixups
	bsr	rd_bstrips
	move.w	#$8000,(rd_pass).l
	tst.w	(rd_hudon).l
	bne.s	.hs
	bsr	rd_ovl_blit
.hs	bsr	rd_sprites_planar
	bsr	rd_op_end
	rts

;	The renderer's waits for the copper, the blitter and a show give up after RCVVB vertical
;	blanks: the copper or the blitter has stalled, and both are set up again (rd_stall).
RCVVB	equ	100

;	Wait until the back buffer is off the screen for good: the frame after it has been given to
;	the display and a vertical blank has passed since, so the copper shows that one. Keeps all.
rd_vsync
	movem.l	d0-d1/a0,-(sp)
	move.w	(rd_bufi).l,d1
	addq.w	#1,d1
	cmpi.w	#NBUF,d1
	blo.s	.n
	moveq	#0,d1
.n	lsl.w	#2,d1
	lea	(rd_shownvb).l,a0
	move.l	(rd_vblanks).l,-(sp)
rd_spin_vs
.w	move.l	(rd_vblanks).l,d0
	cmp.l	(a0,d1.w),d0
	bgt.s	.d
	sub.l	(sp),d0
	cmpi.l	#RCVVB,d0
	blo.s	.w
	bsr	rd_stall
	bra.s	.w
.d
	addq.l	#4,sp
	movem.l	(sp)+,d0-d1/a0
	rts

;	Wait until the blits given to the copper are done: it has started them
;	all (it stopped at the ring's end, SOFT) and the blitter has finished.
rd_waitblit
	tst.b	(rd_cqbat).l
	beq.s	rd_wb_q
	bsr	rd_cq_flush
rd_wb_q	nop
	move.l	d0,-(sp)
	move.l	(rd_vblanks).l,-(sp)
	tst.b	(rd_cqidle).l
	bne.s	rd_wb_blt
rd_spin_q
.q	btst	#2,(CUSTOM+$01F).l
	bne.s	.d
	move.l	(rd_vblanks).l,d0
	sub.l	(sp),d0
	cmpi.l	#RCVVB,d0
	blo.s	.q
	bsr	rd_stall
	bra.s	.q
.d	st	(rd_cqidle).l
rd_wb_blt
	btst	#6,(CUSTOM+DMACONR).l
rd_spin_w
.w	btst	#6,(CUSTOM+DMACONR).l
	beq.s	.d
	move.l	(rd_vblanks).l,d0
	sub.l	(sp),d0
	cmpi.l	#RCVVB,d0
	blo.s	.w
	bsr	rd_stall
	bra.s	.w
.d
	addq.l	#4,sp
	move.l	(sp)+,d0
	rts

;	Blit queue: the copper starts the blits.
RGAP	equ	2
BQE	equ	$38
CQSIZE	equ	16384
CQMAXB	equ	88
CQI	equ	CQSIZE+8
CQ_HALT	equ	$FFFF7FFE
CQ_WBLT	equ	$00017FFE

;	a6 = where to write a blit, as if it were the custom chips' base
;	($040(a6)... $05E(a6), BLTSIZH 0: a show marker, rd_show). Keeps all else.
rd_bq_alloc
rd_bq_allocq
	lea	(rd_bqe-$040).l,a6
	clr.w	$074(a6)
	rts

;	A copper move (to a5) of register \1, the low word of \2; \3 a data register to use.
CQV	MACRO
	move.l	#\1<<16,\3
	move.w	\2,\3
	move.l	\3,(a5)+
	ENDM
;	The moves of pointer register \1 (high, low) from address register \2; \3 a data register to use.
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
;	its first two moves are written last, by rd_cq_close), a5 = where its moves go. Keeps all else.
rd_cq_open
	cmpi.w	#CQMAXB,(rd_cqfree).l
	blo.s	.slow
	movea.l	(rd_cqwp).l,a6
	lea	8(a6),a5
	rts
.slow	movem.l	d0-d2/a0,-(sp)
	move.l	(rd_vblanks).l,-(sp)
	movea.l	(rd_cqring).l,a0
rd_spin_full
.full	move.l	(rd_cqwp).l,d0
	sub.l	a0,d0
	move.l	(rd_cqdp).l,d1
	sub.l	a0,d1
	sub.w	d0,d1
	subq.w	#8,d1
	andi.w	#CQSIZE-1,d1
	move.w	#CQSIZE-8,d2
	sub.w	d0,d2
	cmp.w	d2,d1
	bls.s	.t
	cmpi.w	#CQMAXB,d2
	bhs.s	.e
	sub.w	d2,d1
	subq.w	#8,d1
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
	addq.l	#4,sp
	movem.l	(sp)+,d0-d2/a0
	rts
.wait	btst	#2,(CUSTOM+$01F).l
	bne.s	.s
	move.l	(rd_vblanks).l,d0
	sub.l	(sp),d0
	cmpi.l	#RCVVB,d0
	blo	.full
	bsr	rd_stall
	bra	.full
.s	move.l	(rd_cqwp).l,(rd_cqdp).l
	bra	.full

;	Close the block opened (a6, its moves up to a5): its move to COP2LCL and the stop after
;	it, then it is let go and the copper started if it waits there. Uses d0-d1, a0, a5.
rd_cq_close
	move.l	a5,d0
	addq.l	#4,d0
	swap	d0
	move.w	#$086,d0
	swap	d0
	move.l	d0,(a5)+
	move.l	#$009C8004,(a5)+
	move.l	#CQ_HALT,(a5)
	subq.l	#4,a5
	move.l	#CQ_WBLT,4(a6)
	move.l	#$009C0004,(a6)
	move.l	(rd_cqjmp).l,d0
	bne.s	.j
	move.l	a6,d0
.c	move.l	a5,(rd_cqwp).l
	move.l	a5,d1
	sub.l	a6,d1
	sub.w	d1,(rd_cqfree).l
	sf	(rd_cqidle).l
	nop
	btst	#2,(CUSTOM+$01F).l
	bne.s	.kick
	rts
.j	movea.l	d0,a0
	move.l	#$008A0000,4(a0)
	move.l	(rd_cqjmv).l,(a0)
	clr.l	(rd_cqjmp).l
	bra.s	.c
.kick	move	sr,-(sp)
	ori	#$0700,sr
	bsr	rd_cq_safe
	btst	#2,(CUSTOM+$01F).l
	beq.s	.k1
	move.w	#$0004,(CUSTOM+INTREQ).l
	move.w	d0,(CUSTOM+$08A).l
	nop
	move.l	d0,(rd_cqdp).l
.k1	move	(sp)+,sr
	rts

;	Batches: the blits of a pass (rd_restore's, the sprites') go to the copper CQBATCH at a time:
;	within a batch a blit takes only a move to COP2LCL and the next one's wait for the blitter.
CQBATCH	equ	4

rd_cq_blit
	addq.b	#1,(rd_cqbat).l
	cmpi.b	#1,(rd_cqbat).l
	beq	rd_cq_open
	movea.l	(rd_cqba6).l,a6
	movea.l	(rd_cqba5).l,a5
;	Between two blits of a batch: the move to COP2LCL and the next one's wait
;	for the blitter; room for one more largest block. Keeps all but a5, a6.
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
	move.l	d0,(a5)+
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

;	The blit (or marker) from rd_bq_alloc goes to the
;	copper: the moves of the registers it uses. Keeps all.
rd_bq_go
	movem.l	d0-d1/d3/d7/a0-a1/a5-a6,-(sp)
	bsr	rd_cq_flush
	lea	(rd_bqe).l,a0
	tst.w	$05E-$040(a0)
	beq	.mark
	bsr	rd_cq_open
	sf	(rd_cqkind).l
	move.w	(a0),d3
	CQV	$040,d3,d7
	CQV	$042,$042-$040(a0),d7
	CQV	$044,$044-$040(a0),d7
	CQV	$046,$046-$040(a0),d7
	btst	#11,d3
	beq.s	.na
	movea.l	$050-$040(a0),a1
	CQA	$050,a1,d7
	CQV	$064,$064-$040(a0),d7
	cmpi.w	#$1000,d3
	blo.s	.nd
.na	CQV	$074,$074-$040(a0),d7
.nd	btst	#10,d3
	beq.s	.nb
	movea.l	$04C-$040(a0),a1
	CQA	$04C,a1,d7
	CQV	$062,$062-$040(a0),d7
.nb	btst	#9,d3
	beq.s	.nc
	movea.l	$048-$040(a0),a1
	CQA	$048,a1,d7
	CQV	$060,$060-$040(a0),d7
.nc	btst	#8,d3
	beq.s	.nn
	movea.l	$054-$040(a0),a1
	CQA	$054,a1,d7
	CQV	$066,$066-$040(a0),d7
.nn	CQV	$05C,$05C-$040(a0),d7
	CQV	$05E,$05E-$040(a0),d7
	bsr	rd_cq_close
.x	movem.l	(sp)+,d0-d1/d3/d7/a0-a1/a5-a6
	rts
.mark	bsr	rd_cq_open
	move.l	(rd_cqpmv).l,(a5)+
	move.l	#$008A0000,(a5)+
	move.w	(rd_cqmt).l,d1
	lsl.w	#4,d1
	lea	(rd_cqmq).l,a0
	adda.w	d1,a0
	move.l	a6,(a0)+
	lea	4(a5),a6
	move.l	a6,(a0)+
	lea	(rd_bqe).l,a6
	move.l	$048-$040(a6),(a0)+
	move.w	$04C-$040(a6),(a0)
	lsr.w	#4,d1
	addq.w	#1,d1
	andi.w	#7,d1
	move.w	d1,(rd_cqmt).l
	movea.l	-12(a0),a6
	bsr	rd_cq_close
	bra.s	.x

;	The blitter's registers are not what the copper left (a blit written straight into them). Keeps all.
rd_cq_inval
	sf	(rd_cqkind).l
	rts

;	Start the copper again after a show marker (COP2LCL says where to)
;	if it waits at the marker or the parking place (DSKBLK). Uses d0.
rd_cq_kickm
	move	sr,-(sp)
	ori	#$0700,sr
	bsr	rd_cq_safe
	nop
	btst	#1,(CUSTOM+$01F).l
	bne.s	.k
	moveq	#15,d0
.d	tst.w	(CUSTOM+$006).l
	dbf	d0,.d
	btst	#1,(CUSTOM+$01F).l
	beq.s	.x
.k	move.w	#$0002,(CUSTOM+INTREQ).l
	move.w	d0,(CUSTOM+$08A).l
	nop
.x	move	(sp)+,sr
	rts

;	Wait while a vertical blank's copper restart is near: a look at the copper's state and
;	a jump are not to straddle one (its display list clears the state first). Keeps all.
rd_cq_safe
	move.l	d0,-(sp)
.w	move.w	(CUSTOM+$004).l,d0
	swap	d0
	move.w	(CUSTOM+$006).l,d0
	swap	d0
	cmp.w	(CUSTOM+$004).l,d0
	bne.s	.w
	swap	d0
	andi.l	#$1FFFF,d0
	cmpi.w	#$0010,d0
	bhs.s	.l
	swap	d0
	tst.w	d0
	beq.s	.w
	swap	d0
.l	tst.b	(hal_pal).l
	bne.s	.p
	cmpi.l	#$105A0,d0
	bhs.s	.w
	bra.s	.x
.p	cmpi.l	#$137A0,d0
	bhs.s	.w
.x	move.l	(sp)+,d0
	rts

;	The copper stopped at the oldest show marker queued: if the show before it has been
;	set, this one is the show waiting and the copper goes on after it. Uses d0-d1, a0-a1.
rd_cq_mark
	tst.l	(rd_showcop).l
	bne.s	.hold
	move.w	(rd_cqmh).l,d0
	cmp.w	(rd_cqmt).l,d0
	beq.s	.x
	lea	(rd_cqmq).l,a0
	move.w	d0,d1
	lsl.w	#4,d1
	adda.w	d1,a0
	addq.w	#1,d0
	andi.w	#7,d0
	move.w	d0,(rd_cqmh).l
	move.l	(a0)+,(rd_cqdp).l
	move.w	2(a0),(CUSTOM+$086).l
	addq.l	#4,a0
	move.l	(a0)+,(rd_showcop).l
	move.w	(a0),(rd_showbuf).l
	bsr	rd_showdue
	bra	rd_cq_kickm
.hold	st	(rd_bqhold).l
.x	rts

;	The ring (in rd_cqbuf, within a 64K page, so only COP2LCL
;	changes), the copper stopped at its start. Uses d0-d1/a0.
rd_cq_init
	lea	(rd_cqbuf).l,a0
	move.l	a0,d0
	move.l	a0,d1
	addi.l	#CQI-1,d1
	swap	d0
	swap	d1
	cmp.w	d0,d1
	beq.s	.pg
	swap	d1
	clr.w	d1
	movea.l	d1,a0
.pg	move.l	a0,(rd_cqring).l
	move.l	#$009C8004,(a0)
	move.l	#CQ_HALT,4(a0)
	move.l	a0,d0
	swap	d0
	move.w	#$086,d0
	swap	d0
	move.l	d0,(rd_cqjmv).l
	lea	CQSIZE(a0),a0
	move.l	a0,d0
	swap	d0
	move.w	#$086,d0
	swap	d0
	move.l	d0,(rd_cqpmv).l
	move.l	#$009C8012,(a0)+
	move.l	#CQ_HALT,(a0)+
	move.l	(rd_cqring).l,(rd_cqwp).l
	move.l	(rd_cqring).l,(rd_cqdp).l
	move.w	#CQSIZE-8,(rd_cqfree).l
	clr.l	(rd_cqjmp).l
	clr.w	(rd_cqmh).l
	clr.w	(rd_cqmt).l
	st	(rd_cqidle).l
	bsr	rd_cq_inval
	move.w	#$0002,(CUSTOM+$02E).l
	move.l	(rd_cqring).l,(CUSTOM+$084).l
	move.w	#$0016,(CUSTOM+INTREQ).l
	rts

;	A wait for the copper, the blitter or a show has gone on RCVVB
;	vertical blanks: the copper or the blitter has stalled. Keeps all.
rd_stall
	tst.b	(ctx_cur).l
	bne	rd_recover
	tst.b	(rd_busy).l
	bne.s	.y
	movem.l	d0-d2/a0-a1/a6,-(sp)
	bsr	rd_requeue
	movem.l	(sp)+,d0-d2/a0-a1/a6
	bra.s	.t
.y	jsr	(hal_yield).l
.t	move.l	(rd_vblanks).l,4(sp)
	rts

;	The renderer started again at its loop (rend_main), its frame half drawn
;	dropped, after the copper and the blit queue are set up again (rd_requeue).
rd_recover
	move	#$2700,sr
	bsr	rd_requeue
	sf	(rd_busy).l
	lea	(rend_stack_top).l,sp
	move	#$2000,sr
	jmp	(rend_main).l

;	The copper and the blit queue set up again from nothing: the copper stopped and the
;	blitter let finish, the ring empty, the empty display list. Uses d0-d2, a0-a1, a6.
rd_requeue
	move	sr,-(sp)
	ori	#$0700,sr
	addq.l	#1,(rd_wstat).l
	lea	(CUSTOM).l,a6
	move.w	#$0080,$096(a6)
	move.w	#$8240,$096(a6)
	nop
	move.l	#$40000,d0
	btst	#6,$002(a6)
.bw	btst	#6,$002(a6)
	beq.s	.bd
	subq.l	#1,d0
	bne.s	.bw
.bd	sf	(rd_cqbat).l
	bsr	rd_cq_init
	jsr	(hal_display_init).l
	move.w	#$C000|$2000|$0020|$0010,$09A(a6)
	clr.l	(rd_showcop).l
	sf	(rd_bqhold).l
	moveq	#-1,d0
	lea	(rd_shownvb).l,a0
	moveq	#NBUF-1,d1
.sv	move.l	d0,(a0)+
	dbf	d1,.sv
	lea	(rd_dirty).l,a0
	move.w	#NBUF*DROWS-1,d1
.dm	move.l	d0,(a0)+
	dbf	d1,.dm
	bsr	rd_op_invall
	sf	(rd_stage).l
	move.l	d0,(rd_Bkey).l
	lea	(rd_akey).l,a0
	moveq	#6-1,d1
.ak	move.l	d0,(a0)+
	dbf	d1,.ak
	sf	(rd_ntsync).l
	move.l	d0,(rd_palgen).l
	move.l	d0,(rd_lastgen).l
	move.l	d0,(rd_lastgen+4).l
	lea	(rd_copgen).l,a0
	moveq	#2*NBUF-1,d1
.cg	move.l	d0,(a0)+
	dbf	d1,.cg
	lea	(rd_shkey).l,a0
	moveq	#2*NBUF-1,d1
.sk	move.l	d0,(a0)+
	dbf	d1,.sk
	lea	(rd_hudbd).l,a0
	moveq	#NBUF-1,d1
.hb	move.l	d0,(a0)+
	dbf	d1,.hb
	st	(rd_hudchg).l
	moveq	#0,d0
	lea	(rd_ovl).l,a0
	move.w	#OSROW*SCRH/16-1,d1
.oc	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	dbf	d1,.oc
	lea	(rd_ovlmlo).l,a0
	move.w	#2*OSROW*SCRH/16-1,d1
.om	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	dbf	d1,.om
	lea	(rd_ovlcolf).l,a0
	move.w	#2*32*48/4-1,d1
.of	move.l	d0,(a0)+
	dbf	d1,.of
	lea	(rd_ovlrows).l,a0
	moveq	#2*32-1,d1
.or	move.l	#$7FFF8001,(a0)+
	dbf	d1,.or
	clr.l	(rd_ovlpart).l
	st	(rd_ovldirty).l
	move.l	(rd_scsize).l,d1
	add.l	d1,d1
	add.l	d1,(rd_scpos).l
	st	(rd_bltch).l
	move.l	#$7FFFFFFF,(rd_scmin).l
	move.l	#$7FFFFFFF,(rd_scmin+4).l
	bsr	rd_bmrc_clr
	clr.l	(rd_ovrd).l
	clr.l	(rd_ovrd+4).l
	clr.l	(rd_ovrd+8).l
	move	(sp)+,sr
	rts

;	The show waiting (rd_showcop), if it is due: each frame stays
;	on the screen hal_pace vertical blanks at least. Uses d0, a1.
rd_showdue
	tst.l	(rd_showcop).l
	beq	.x
	move.l	(rd_vblanks).l,d0
	sub.l	(rd_lastset).l,d0
	sub.l	(hal_pace).l,d0
	bmi	.x
	move.l	(rd_vblanks).l,(rd_lastset).l
	move	sr,-(sp)
	ori	#$0700,sr
	bsr	rd_cq_safe
	move.l	(rd_showcop).l,(CUSTOM+$080).l
	move	(sp)+,sr
	clr.l	(rd_showcop).l
	move.w	(rd_showbuf).l,d0
	lsl.w	#2,d0
	lea	(rd_shownvb).l,a1
	move.l	(rd_vblanks).l,(a1,d0.w)
	move.l	d1,-(sp)
	lea	(rd_snapvb).l,a1
	move.l	(rd_vblanks).l,d1
	sub.l	(a1,d0.w),d1
	addq.l	#1,d1
	cmpi.l	#6,d1
	bls.s	.l6
	moveq	#6,d1
.l6
	lsl.w	#8,d1
	addi.w	#128,d1
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

;	A frame begins: what of the plane B bitmap its blits read from none (rd_bmrc, rd_cellB),
;	the 3rd frame before's forgotten (its blits are done once it has a buffer). Keeps all.
rd_bmrd_age
	move.l	(rd_ovrd+4).l,(rd_ovrd+8).l
	move.l	(rd_ovrd).l,(rd_ovrd+4).l
	clr.l	(rd_ovrd).l
	movem.l	d0/a0,-(sp)
	movea.l	(rd_bmrp).l,a0
	lea	32*4(a0),a0
	cmpa.l	#rd_bmrc+3*32*4,a0
	blo.s	.k
	lea	(rd_bmrc).l,a0
.k	move.l	a0,(rd_bmrp).l
	moveq	#32/4-1,d0
.c	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	dbf	d0,.c
	movem.l	(sp)+,d0/a0
	rts

;	The blits queued have all been let finish (rd_waitblit): none reads the bitmap now. Keeps all.
rd_bmrc_clr
	movem.l	d0/a0,-(sp)
	lea	(rd_bmrc).l,a0
	moveq	#3*32/4-1,d0
.c	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	clr.l	(a0)+
	dbf	d0,.c
	movem.l	(sp)+,d0/a0
	rts

;	d0 = the 16 pixel columns of bitmap row d5 that blits queued
;	in the last 3 frames read (column 0 the top bit). Uses a1.
rd_bmrc_row
	moveq	#31,d0
	and.w	d5,d0
	lea	(rd_bmrc).l,a1
	lea	(a1,d0.w*4),a1
	move.l	(a1),d0
	or.l	32*4(a1),d0
	or.l	64*4(a1),d0
	rts

;	The back buffer's game state is taken now (rd_showdue: the picture's delay). Keeps all.
rd_snaptime
	movem.l	d0/a0,-(sp)
	move.w	(rd_bufi).l,d0
	lea	(rd_snapvb).l,a0
	move.l	(hal_tickvb).l,(a0,d0.w*4)
	movem.l	(sp)+,d0/a0
	rts

;	Level 3: the copper at a show marker (COPER: rd_cq_mark),
;	or a vertical blank (counted: rd_vsync; the keyboard read).
rd_bq_int
	movem.l	d0-d1/a0-a1,-(sp)
	move.w	(CUSTOM+$01E).l,-(sp)
	btst	#4,1(sp)
	beq.s	.nm
	move.w	#$0010,(CUSTOM+INTREQ).l
	move.w	#$0010,(CUSTOM+INTREQ).l
	btst	#1,(CUSTOM+$01F).l
	beq.s	.nm
	bsr	rd_cq_mark
.nm	btst	#5,1(sp)
	beq.s	.x
	move.w	#$0020,(CUSTOM+INTREQ).l
	move.w	#$0020,(CUSTOM+INTREQ).l
	addq.l	#1,(rd_vblanks).l
	IFND	HARNESS
	lea	18(sp),a0
	bsr	cr_watch
	ENDC
	tst.b	(hal_vbtick).l
	beq.s	.nt
	lea	18(sp),a0
	jsr	(hal_pcnote).l
	st	(hal_vbreq).l
	move.w	#$A000,(CUSTOM+INTREQ).l
.nt	bsr	rd_showdue
	tst.b	(rd_bqhold).l
	beq.s	.kb
	tst.l	(rd_showcop).l
	bne.s	.kb
	sf	(rd_bqhold).l
	bsr	rd_cq_mark
.kb	jsr	(hal_kbd_poll).l
.x	addq.l	#2,sp
	movem.l	(sp)+,d0-d1/a0-a1
	tst.b	(hal_swpend).l
	bne.s	.sw
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
;	Can the name table at video memory d0, d1 bytes long, have changed since
;	it was last compared with its copy? Only if a load. Uses d0-d4/a0-a1.
rd_ntwritten
	cmpi.l	#VMSIZE,d0
	blo.s	.v
	st	(rd_ntfull).l
	moveq	#-1,d0
	rts
.v	lsr.l	#5,d0
	moveq	#31,d2
	add.l	d2,d1
	lsr.l	#5,d1
	moveq	#0,d2
	sf	(rd_ntfull).l
	lea	(vm_wmap).l,a0
	lea	(tc_chg).l,a1
	move	sr,-(sp)
	ori	#$0700,sr
.l	moveq	#32,d3
	cmp.l	d3,d1
	bhs.s	.w
	move.l	d1,d3
.w	bfextu	(a0){d0:d3},d4
	beq.s	.w0
	st	(rd_ntfull).l
.w0	or.l	d4,d2
	bfclr	(a0){d0:d3}
	bfextu	(a1){d0:d3},d4
	or.l	d4,d2
	add.l	d3,d0
	sub.l	d3,d1
	bne.s	.l
	move	(sp)+,sr
	tst.b	(rd_ntsync).l
	seq	d0
	or.b	d0,(rd_ntfull).l
	tst.l	d2
	sne	d1
	or.b	d1,d0
	rts

;	The next block (32 bytes) of the name table being compared with a tc_chg bit: from rd_ntb,
;	below rd_ntb+4; d0 = its offset in the table, rd_ntb on past it; C set if none. Uses d0-d2/a0.
rd_ntnext
	move.l	(rd_ntb).l,d0
.l	cmp.l	(rd_ntb+4).l,d0
	bhs.s	.no
	move.l	d0,d1
	lsr.l	#5,d1
	lea	(tc_chg).l,a0
	move.l	(a0,d1.l*4),d2
	moveq	#31,d1
	and.l	d0,d1
	lsl.l	d1,d2
	bne.s	.b
	addi.l	#32,d0
	andi.l	#-32,d0
	bra.s	.l
.b	bfffo	d2{0:0},d1
	add.l	d1,d0
	cmp.l	(rd_ntb+4).l,d0
	bhs.s	.no
	move.l	d0,d1
	addq.l	#1,d1
	move.l	d1,(rd_ntb).l
	sub.l	(rd_ntb+8).l,d0
	lsl.l	#5,d0
	andi	#$FE,ccr
	rts
.no	ori	#1,ccr
	rts

;	The name table at a0 (in vm_data), d7 + 1 longs: its blocks for rd_ntnext. Keeps all.
rd_ntblocks
	movem.l	d0-d1,-(sp)
	move.l	a0,d0
	subi.l	#vm_data,d0
	lsr.l	#5,d0
	move.l	d0,(rd_ntb).l
	move.l	d0,(rd_ntb+8).l
	moveq	#0,d1
	move.w	d7,d1
	addq.l	#1,d1
	lsr.l	#3,d1
	add.l	d1,d0
	move.l	d0,(rd_ntb+4).l
	movem.l	(sp)+,d0-d1
	rts

;	Bring the plane B bitmap up to date with the name table and the tiles.
rd_updateB
	bsr	rd_planesize
	move.w	d0,(rd_cw).l
	move.w	d1,(rd_ch).l
	move.l	(rd_lntb).l,d2
	tst.b	(rd_narrow).l
	beq.s	.nar
	move.l	#rd_vntB,d2
	sub.l	#vm_data,d2
.nar	lea	(vm_data).l,a0
	adda.l	d2,a0
	movem.l	d0-d2/a0,-(sp)
	mulu.w	d0,d1
	add.l	d1,d1
	move.l	d2,d0
	bsr	rd_ntwritten
	move.b	d0,(rd_ntcur).l
	movem.l	(sp)+,d0-d2/a0
	swap	d2
	move.w	d0,d2
	lsl.w	#8,d2
	or.b	d1,d2
	moveq	#0,d6
	cmp.l	(rd_Bkey).l,d2
	beq	.same
	move.l	d2,(rd_Bkey).l
	moveq	#1,d6
	clr.w	(rd_bpn).l
	lea	(rd_bpset).l,a1
	moveq	#BMAX/32-1,d3
.cq	clr.l	(a1)+
	dbf	d3,.cq
	lea	(rd_bused).l,a1
	moveq	#63,d3
.cu	clr.l	(a1)+
	dbf	d3,.cu
	lea	(rd_mkset).l,a1
	moveq	#BMAX/32-1,d3
.cm	move.l	#-1,(a1)+
	dbf	d3,.cm
	lea	(rd_tlhead).l,a1
	move.w	#2048/2-1,d3
.ch	clr.l	(a1)+
	dbf	d3,.ch
	lea	(rd_tltile).l,a1
	move.w	#BMAX/2-1,d3
.ct	clr.l	(a1)+
	dbf	d3,.ct
.same
	moveq	#0,d3
	move.w	(rd_tcn).l,d4
	beq.s	.tun
	subq.w	#1,d4
	move.l	a3,-(sp)
	lea	(rd_tcl).l,a3
	lea	(tc_chg).l,a1
	lea	(rd_bused).l,a2
.tu	move.w	(a3)+,d5
	move.l	(a1,d5.w),d7
	and.l	(a2,d5.w),d7
	or.l	d7,d3
	dbf	d4,.tu
	movea.l	(sp)+,a3
.tun	move.l	d3,(rd_btchg).l
	clr.w	(rd_hiBok).l
	move.w	d0,d7
	mulu.w	d1,d7
	subq.w	#1,d7
	lea	(shB).l,a1
	lea	(tc_chg).l,a2
	moveq	#0,d4
	moveq	#0,d5
	move.w	#-1,(rd_hiBok).l
	tst.w	d6
	bne	.cell
	tst.b	(rd_ntcur).l
	beq	.fdone
	move.l	a0,(rd_tmp).l
	addq.w	#1,d7
	lsr.w	#1,d7
	subq.w	#1,d7
	sf	(rd_ntblkm).l
	tst.b	(rd_ntfull).l
	bne.s	.f
	st	(rd_ntblkm).l
	bsr	rd_ntblocks
.fb	bsr	rd_ntnext
	bcs	.fdone
	movea.l	(rd_tmp).l,a0
	adda.l	d0,a0
	lea	(shB).l,a1
	adda.l	d0,a1
	moveq	#7,d7
.f	cmpm.l	(a0)+,(a1)+
	dbne	d7,.f
	beq	.fend
	movem.l	d7/a0-a1,-(sp)
	move.l	a0,d0
	sub.l	(rd_tmp).l,d0
	subq.l	#4,d0
	lsr.l	#1,d0
	moveq	#1,d3
.fc	movem.l	d0/d3,-(sp)
	lea	(shB).l,a1
	movea.l	(rd_tmp).l,a0
	move.w	(a0,d0.l*2),d1
	cmp.w	(a1,d0.l*2),d1
	beq	.fn
	move.w	d1,(a1,d0.l*2)
	clr.w	(rd_hiBok).l
	moveq	#0,d4
	move.w	d0,d4
	divu.w	(rd_cw).l,d4
	move.l	d4,d5
	swap	d4
	cmpi.w	#64,(rd_cw).l
	bne.s	.now
	bsr	rd_bp_add
	beq.s	.fn
.now	move.w	d1,d0
	bsr	rd_cellB
.fn	movem.l	(sp)+,d0/d3
	addq.l	#1,d0
	dbf	d3,.fc
	movem.l	(sp)+,d7/a0-a1
	dbf	d7,.f
.fend
	tst.b	(rd_ntblkm).l
	bne	.fb
.fdone	tst.l	(rd_btchg).l
	beq.s	.fd2
	bsr	rd_btiles
.fd2	tst.w	(rd_hiBok).l
	bne	.x
	cmpi.w	#64,(rd_cw).l
	beq	.x
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
	cmpi.w	#64,(rd_cw).l
	bne.s	.dc
	move.w	d5,d1
	lsl.w	#6,d1
	add.w	d4,d1
	exg	d0,d1
	bsr	rd_bp_add
	exg	d0,d1
	bra.s	.next
.dc	movem.l	d4-d7/a0-a2,-(sp)
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
	moveq	#0,d7
.l	move.l	(a3)+,d6
	and.l	(a4)+,d6
	beq.s	.nl
.b	bfffo	d6{0:0},d1
	bfclr	d6{d1:1}
	add.w	d7,d1
	lea	(rd_tlhead).l,a0
	move.w	(a0,d1.w*2),d2
.c	subq.w	#1,d2
	bmi.s	.nt
	lea	(rd_tlnext).l,a0
	move.w	(a0,d2.w*2),d3
	lea	(shB).l,a0
	move.w	(a0,d2.w*2),d0
	cmpi.w	#64,(rd_cw).l
	bne.s	.now
	exg	d0,d2
	bsr	rd_bp_add
	exg	d0,d2
	beq.s	.q
.now	moveq	#0,d4
	move.w	d2,d4
	divu.w	(rd_cw).l,d4
	move.l	d4,d5
	swap	d4
	movem.l	d3/d6-d7/a3-a4,-(sp)
	bsr	rd_cellB
	movem.l	(sp)+,d3/d6-d7/a3-a4
.q	move.w	d3,d2
	bra.s	.c
.nt	tst.l	d6
	bne.s	.b
.nl	addi.w	#32,d7
	cmpi.w	#2048,d7
	blo.s	.l
	clr.w	(rd_hiBok).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	Draw entry d0 at cell d4 (column), d5 (row) of the plane B bitmap.
rd_cellB
	move.l	d0,-(sp)
	bsr	rd_bmrc_row
	moveq	#0,d1
	move.w	d4,d1
	lsr.w	#1,d1
	bftst	d0{d1:1}
	beq.s	.nw
	bsr	rd_waitblit
	bsr	rd_bmrc_clr
.nw	move.l	(sp)+,d0
	moveq	#0,d1
	move.w	d4,d1
	lsr.w	#1,d1
	andi.w	#31,d1
	moveq	#31,d2
	and.w	d5,d2
	lea	(rd_dirty).l,a1
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
	move.w	d0,(rd_cellpri).l
	move.w	d0,d1
	andi.l	#$7FF,d1
	lea	(rd_bused).l,a1
	bfset	(a1){d1:1}
	TNEED	d1
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
	st	(rd_cellmk).l
.lo
	lea	(rd_mkset).l,a1
	tst.b	(rd_cellmk).l
	beq.s	.m0
	bfset	(a1){d1:1}
	st	(rd_cellmw).l
	bra.s	.m1
.m0	bfclr	(a1){d1:1}
	sne	(rd_cellmw).l
.m1	bsr	rd_tl_set
	movem.l	(sp)+,d1-d2
	move.w	(rd_cw).l,d1
	move.w	d1,d2
	mulu.w	#6,d2
	move.w	d5,d3
	lsl.w	#3,d3
	mulu.w	d3,d2
	lea	(bmB).l,a1
	adda.l	d2,a1
	adda.w	d4,a1
	movea.l	a1,a4
	adda.l	#mkB6-bmB,a4
	lea	(mkB).l,a3
	move.w	d5,d3
	lsl.w	#3,d3
	mulu.w	d1,d3
	adda.l	d3,a3
	adda.w	d4,a3
	move.w	d0,d3
	andi.l	#$FFF,d3
	lea	(tp_pl).l,a0
	move.l	d3,d2
	lsl.l	#5,d2
	adda.l	d2,a0
	lea	(tp_mk).l,a2
	lsl.l	#3,d3
	adda.l	d3,a2
	moveq	#4,d5
	moveq	#1,d4
	btst	#12,d0
	beq	.nv
	lea	28(a0),a0
	addq.l	#7,a2
	moveq	#-4,d5
	moveq	#-1,d4
.nv	moveq	#0,d6
	btst	#13,d0
	beq	.p0
	move.b	#$FF,d6
.p0	moveq	#0,d7
	btst	#14,d0
	beq	.p1
	move.b	#$FF,d7
.p1	moveq	#7,d3
	move.w	d1,d2
	mulu.w	#6,d2
	movem.l	a5-a6,-(sp)
	move.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
	lea	(a1,d0.w),a5
	tst.b	(rd_cellmw).l
	beq	.rown
	lea	(a4,d0.w),a6
	tst.w	(rd_cellpri).l
	bmi.s	.row
	lea	(rd_zero8).l,a2
	moveq	#0,d4
.row	move.b	(a0),(a1)
	move.b	1(a0),(a1,d1.w)
	move.b	2(a0),(a1,d1.w*2)
	move.b	3(a0),(a5)
	move.b	d6,(a5,d1.w)
	move.b	d7,(a5,d1.w*2)
	adda.w	d5,a0
	adda.w	d2,a1
	adda.w	d2,a5
	move.b	(a2),d0
	adda.w	d4,a2
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
.rown	move.b	(a0),(a1)
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

;	Cell d1 (row * plane width + column) of plane B into the list of the cells
;	with entry d0's tile (rd_btiles), out of the one it was in. Uses d2, a1.
rd_tl_set
	movem.l	d0/d3/a0,-(sp)
	andi.w	#$7FF,d0
	addq.w	#1,d0
	lea	(rd_tltile).l,a0
	move.w	(a0,d1.w*2),d2
	cmp.w	d2,d0
	beq.s	.tk
	move.w	d0,(a0,d1.w*2)
	tst.w	d2
	beq.s	.ti
	lea	(rd_tlprev).l,a0
	move.w	(a0,d1.w*2),d3
	lea	(rd_tlnext).l,a1
	move.w	(a1,d1.w*2),d0
	tst.w	d3
	beq.s	.th
	move.w	d0,-2(a1,d3.w*2)
	bra.s	.tp
.th	lea	(rd_tlhead).l,a1
	move.w	d0,-2(a1,d2.w*2)
.tp	tst.w	d0
	beq.s	.tn
	move.w	d3,-2(a0,d0.w*2)
.tn	lea	(rd_tltile).l,a0
	move.w	(a0,d1.w*2),d0
.ti
	lea	(rd_tlhead).l,a0
	move.w	-2(a0,d0.w*2),d3
	move.w	d1,d2
	addq.w	#1,d2
	move.w	d2,-2(a0,d0.w*2)
	lea	(rd_tlnext).l,a0
	move.w	d3,(a0,d1.w*2)
	lea	(rd_tlprev).l,a0
	clr.w	(a0,d1.w*2)
	tst.w	d3
	beq.s	.tk
	move.w	d2,-2(a0,d3.w*2)
.tk	movem.l	(sp)+,d0/d3/a0
	rts

;	The rink's cells whose entries or tiles changed wait and are converted here, once the frame's
;	scroll is known: those within 8 lines and 16 pixels of the screen now. Uses d0-d7, a0-a3.
BPBUDGET	equ	6
rd_bpend_run
	tst.w	(rd_bpn).l
	beq	.x
	move.w	(rd_bx0).l,d0
	subi.w	#16,d0
	move.w	(rd_w).l,d1
	addi.w	#32,d1
	lea	(rd_bpcn).l,a0
	bsr	.cols
	move.w	(rd_bx0).l,d0
	subi.w	#48,d0
	move.w	(rd_w).l,d1
	addi.w	#96,d1
	lea	(rd_bpcp).l,a0
	bsr	.cols
	move.w	(rd_bx0).l,d0
	move.w	(rd_w).l,d1
	lea	(rd_bpcv).l,a0
	bsr	.cols
	moveq	#BPBUDGET,d6
	lea	(rd_bpset).l,a2
	move.l	(rd_bpcp).l,d2
	move.l	(rd_bpcp+4).l,d3
	moveq	#0,d5
.r	move.l	(a2)+,d0
	and.l	d2,d0
	move.l	(a2)+,d1
	and.l	d3,d1
	or.l	d1,d0
	beq	.rn
	movem.l	d2-d3/a2,-(sp)
	move.w	d5,d1
	lsl.w	#3,d1
	sub.w	(rd_by0).l,d1
	move.w	(rd_ch).l,d2
	lsl.w	#3,d2
	subq.w	#1,d2
	and.w	d2,d1
	st	d7
	cmpi.w	#SCRH+8,d1
	blo.s	.v
	subi.w	#15,d2
	cmp.w	d2,d1
	bhi.s	.v
	sf	d7
	tst.w	d6
	beq	.rd
.v	clr.l	(rd_rsel).l
	clr.l	(rd_rsel+4).l
	moveq	#0,d4
.hh	lea	(rd_bpset).l,a0
	lea	(a0,d5.w*8),a0
	move.l	(a0,d4.w*4),d0
	lea	(rd_bpcp).l,a1
	and.l	(a1,d4.w*4),d0
	beq	.hn
	moveq	#0,d3
	moveq	#0,d1
	tst.b	d7
	beq.s	.cb
	move.l	d0,d1
	lea	(rd_bpcn).l,a1
	and.l	(a1,d4.w*4),d1
.cb	tst.w	d6
	bne.s	.cc
	and.l	d1,d0
.cc	tst.l	d0
	beq	.hs
	bfffo	d0{0:0},d2
	bfclr	d0{d2:1}
	bftst	d1{d2:1}
	bne.s	.do
	subq.w	#1,d6
.do	bfset	d3{d2:1}
	subq.w	#1,(rd_bpn).l
	bra.s	.cb
.hs	lea	(rd_rsel).l,a1
	move.l	d3,(a1,d4.w*4)
	not.l	d3
	lea	(rd_bpset).l,a0
	lea	(a0,d5.w*8),a0
	and.l	d3,(a0,d4.w*4)
.hn	addq.w	#1,d4
	cmpi.w	#2,d4
	blo	.hh
	move.l	(rd_rsel).l,d0
	or.l	(rd_rsel+4).l,d0
	beq.s	.rd
	movem.l	d5-d6,-(sp)
	bsr	rd_rowB
	movem.l	(sp)+,d5-d6
.rd	movem.l	(sp)+,d2-d3/a2
.rn	addq.w	#1,d5
	cmp.w	(rd_ch).l,d5
	blo	.r
.x	rts
.cols
	lea	(rd_bptmp).l,a1
	clr.l	(a1)
	clr.l	4(a1)
	clr.l	8(a1)
	clr.l	12(a1)
	add.w	d0,d1
	subq.w	#1,d1
	asr.w	#3,d0
	asr.w	#3,d1
	sub.w	d0,d1
	addq.w	#1,d1
	cmpi.w	#64,d1
	blo.s	.c1
	moveq	#-1,d0
	move.l	d0,(a0)
	move.l	d0,4(a0)
	rts
.c1	andi.l	#63,d0
	ext.l	d1
.c2	moveq	#32,d2
	cmp.l	d2,d1
	bhs.s	.c3
	move.l	d1,d2
.c3	bfset	(a1){d0:d2}
	add.l	d2,d0
	sub.l	d2,d1
	bne.s	.c2
	move.l	(a1),d0
	or.l	8(a1),d0
	move.l	d0,(a0)
	move.l	4(a1),d0
	or.l	12(a1),d0
	move.l	d0,4(a0)
	rts

;	The cells of rink row d5 that rd_rsel names into the plane B bitmap: those with a mask, or one
;	before, by rd_cellB; the others staged in fast memory and copied in longs. Uses d0-d7, a0-a3.
rd_rowB
	movem.l	a4-a5,-(sp)
	clr.w	(rd_hiBok).l
	moveq	#0,d2
	move.l	(rd_rsel).l,d0
	bsr	.pairs
	move.l	(rd_rsel+4).l,d0
	bsr	.pairs
	bsr	rd_bmrc_row
	and.l	d2,d0
	beq.s	.nw
	bsr	rd_rowB_defer
	tst.l	d0
	beq.s	.nw
	bsr	rd_waitblit
	bsr	rd_bmrc_clr
.nw
	moveq	#31,d1
	and.w	d5,d1
	lea	(rd_dirty).l,a1
	lea	(a1,d1.w*4),a1
	moveq	#(8>>DLS)-1,d3
.mr	or.l	d2,(a1)
	or.l	d2,DROWS*4(a1)
	or.l	d2,2*DROWS*4(a1)
	cmpi.w	#DROWS-DWRAP,d1
	bhs.s	.once
	or.l	d2,DWRAP*4(a1)
	or.l	d2,(DROWS+DWRAP)*4(a1)
	or.l	d2,(2*DROWS+DWRAP)*4(a1)
.once	addq.l	#4,a1
	addq.w	#1,d1
	dbf	d3,.mr
	clr.l	(rd_rstg).l
	clr.l	(rd_rstg+4).l
	move.w	d5,d0
	lsl.w	#6,d0
	movea.w	d0,a5
	moveq	#0,d6
.h	lea	(rd_rsel).l,a0
	move.l	(a0,d6.w*4),d4
.c	tst.l	d4
	beq	.hn
	bfffo	d4{0:0},d3
	bfclr	d4{d3:1}
	moveq	#0,d1
	move.w	d6,d1
	lsl.w	#5,d1
	add.w	d3,d1
	movea.l	d1,a3
	add.w	a5,d1
	lea	(shB).l,a1
	move.w	(a1,d1.w*2),d0
	moveq	#0,d2
	move.w	d0,d2
	andi.w	#$7FF,d2
	lea	(rd_bused).l,a1
	bfset	(a1){d2:1}
	TNEED	d2
	lea	(rd_mkset).l,a1
	bftst	(a1){d1:1}
	bne.s	.slow
	tst.w	d0
	bpl.s	.fast
	move.w	d0,d2
	andi.w	#$FFF,d2
	lea	(tp_cls).l,a1
	tst.b	(a1,d2.w)
	beq.s	.fast
.slow	movem.l	d4-d6/a5,-(sp)
	move.l	a3,d4
	bsr	rd_cellB
	movem.l	(sp)+,d4-d6/a5
	bra	.c
.fast
	lea	(rd_hibits).l,a1
	bfclr	(a1){d1:1}
	bsr	rd_tl_set
	move.l	a3,d2
	lea	(rd_rstg).l,a1
	bfset	(a1){d2:1}
	lea	(rd_rstage).l,a1
	adda.l	a3,a1
	move.w	d0,d2
	andi.l	#$FFF,d2
	lsl.l	#5,d2
	lea	(tp_pl).l,a2
	adda.l	d2,a2
	moveq	#4,d3
	btst	#12,d0
	beq.s	.nv
	lea	28(a2),a2
	moveq	#-4,d3
.nv	btst	#13,d0
	sne	d1
	btst	#14,d0
	sne	d0
	moveq	#7,d2
.ln	move.l	(a2),d7
	adda.w	d3,a2
	move.b	d7,3*64(a1)
	lsr.l	#8,d7
	move.b	d7,2*64(a1)
	lsr.w	#8,d7
	move.b	d7,64(a1)
	swap	d7
	move.b	d7,(a1)
	move.b	d1,4*64(a1)
	move.b	d0,5*64(a1)
	lea	6*64(a1),a1
	dbf	d2,.ln
	bra	.c
.hn	addq.w	#1,d6
	cmpi.w	#2,d6
	blo	.h
	lea	(rd_rstage).l,a0
	lea	(bmB).l,a1
	move.w	d5,d0
	mulu.w	#8*6*64,d0
	adda.l	d0,a1
	lea	(rd_rstg).l,a2
	moveq	#0,d6
.g	bfextu	(a2){d6:4},d1
	beq	.gn
	cmpi.b	#15,d1
	bne	.gp
RBO	set	0
	REPT	8*6
	move.l	RBO(a0),RBO(a1)
RBO	set	RBO+64
	ENDR
	bra	.gn
.gp	moveq	#3,d2
.gb	btst	d2,d1
	beq	.gbn
	moveq	#3,d3
	sub.w	d2,d3
	lea	(a0,d3.w),a3
	lea	(a1,d3.w),a4
RBO	set	0
	REPT	8*6
	move.b	RBO(a3),RBO(a4)
RBO	set	RBO+64
	ENDR
.gbn	dbf	d2,.gb
.gn	addq.l	#4,a0
	addq.l	#4,a1
	addq.w	#4,d6
	cmpi.w	#64,d6
	blo	.g
	movem.l	(sp)+,a4-a5
	rts
.pairs
rd_rowB_pairs
	moveq	#15,d3
.pr	add.l	d2,d2
	move.l	d0,d1
	andi.l	#$C0000000,d1
	beq.s	.pz
	addq.l	#1,d2
.pz	lsl.l	#2,d0
	dbf	d3,.pr
	rts

;	(rd_rowB) The cells of rd_rsel (row d5) in the 16 pixel columns d0 that queued blits read
;	and that are off the screen (rd_bpcv) go back to waiting (rd_bpset). Uses d1, d3, a0-a1.
rd_rowB_defer
	movem.l	d4/d6-d7/a2,-(sp)
	move.l	d0,d7
	lea	(rd_bpset).l,a1
	lea	(a1,d5.w*8),a1
	lea	(rd_bpcv).l,a2
	move.w	d5,d1
	lsl.w	#3,d1
	sub.w	(rd_by0).l,d1
	move.w	(rd_ch).l,d3
	lsl.w	#3,d3
	subq.w	#1,d3
	and.w	d3,d1
	cmpi.w	#SCRH,d1
	blo.s	.vr
	subq.w	#7,d3
	cmp.w	d3,d1
	bhi.s	.vr
	lea	(.none,pc),a2
.vr	moveq	#0,d6
.h	lea	(rd_rsel).l,a0
	move.l	(a0,d6.w*4),d4
.c	tst.l	d4
	beq.s	.hn
	bfffo	d4{0:0},d3
	bfclr	d4{d3:1}
	move.w	d6,d1
	lsl.w	#5,d1
	add.w	d3,d1
	lsr.w	#1,d1
	bftst	d7{d1:1}
	beq.s	.c
	move.l	d6,d1
	lsl.w	#5,d1
	add.w	d3,d1
	bftst	(a2){d1:1}
	bne.s	.c
	lea	(rd_rsel).l,a0
	bfclr	(a0){d1:1}
	bfset	(a1){d1:1}
	addq.w	#1,(rd_bpn).l
	bra.s	.c
.hn	addq.w	#1,d6
	cmpi.w	#2,d6
	blo.s	.h
	moveq	#0,d2
	move.l	(rd_rsel).l,d0
	bsr	rd_rowB_pairs
	move.l	(rd_rsel+4).l,d0
	bsr	rd_rowB_pairs
	move.l	d7,d0
	and.l	d2,d0
	movem.l	(sp)+,d4/d6-d7/a2
	rts
.none	dc.l	0,0

;	(rd_updateB, rd_btiles) The rink's cell d0.w to wait for rd_bpend_run: Z set. Keeps all.
rd_bp_add
	movem.l	d1/a0,-(sp)
	moveq	#0,d1
	move.w	d0,d1
	lea	(rd_bpset).l,a0
	bfset	(a0){d1:1}
	bne.s	.in
	addq.w	#1,(rd_bpn).l
.in	moveq	#0,d1
	movem.l	(sp)+,d1/a0
	rts

;	List the high priority cells of plane B (for the fixups).
rd_list_hiB
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
	moveq	#0,d5
	moveq	#0,d3
	moveq	#0,d2
.r	moveq	#0,d4
.c	move.w	(a0)+,d0
	bpl	.n
	andi.w	#$FFF,d0
	tst.b	(a3,d0.w)
	beq	.n
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

;	Plane B's scroll position (rd_bx0, rd_by0: the plane pixel
;	at screen 0, 0) and where the screen is in the back buffer.
rd_scrollpos
	move.w	(rd_hs+2).l,d0
	neg.w	d0
	move.w	(rd_cw).l,d3
	lsl.w	#3,d3
	subq.w	#1,d3
	and.w	d3,d0
	move.w	(rd_vs+2).l,d1
	move.w	(rd_ch).l,d2
	lsl.w	#3,d2
	subq.w	#1,d2
	and.w	d2,d1
	move.w	d1,(rd_by0).l
	cmpi.w	#64,(rd_cw).l
	bne	.copy
	cmpi.w	#32,(rd_ch).l
	bne	.copy
	move.w	#512,d1
	sub.w	(rd_w).l,d1
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

;	Scroll mode: blit the parts of the back buffer its dirty map names back from the plane B bitmap.
rd_restore
	movea.l	(rd_dmap).l,a2
	moveq	#0,d7
	move.w	#DROWS,(rd_rsend).l
	tst.w	(rd_scroll).l
	beq.s	.row
	move.w	(rd_brow0).l,d7
	move.w	d7,d0
	addi.w	#SCRH-1,d0
	lsr.w	#DLS,d7
	lsr.w	#DLS,d0
	addq.w	#1,d0
	move.w	d0,(rd_rsend).l
.row	move.l	(a2,d7.w*4),d6
	bne.s	.dirty
	addq.w	#1,d7
	cmp.w	(rd_rsend).l,d7
	blt.s	.row
	rts
.dirty	move.w	d7,d5
.same	clr.l	(a2,d7.w*4)
	addq.w	#1,d7
	cmp.w	(rd_rsend).l,d7
	bge.s	.grp
	moveq	#DWRAP-1,d0
	and.w	d7,d0
	beq.s	.grp
	cmp.l	(a2,d7.w*4),d6
	beq.s	.same
.grp
.run	bfffo	d6{0:0},d1
	move.l	d6,d2
	lsl.l	d1,d2
	not.l	d2
	bfffo	d2{0:0},d3
	bfclr	d6{d1:d3}
.ext
	tst.l	d6
	beq.s	.blit
	bfffo	d6{0:0},d0
	move.w	d0,d2
	sub.w	d1,d2
	sub.w	d3,d2
	cmpi.w	#RGAP,d2
	bhi.s	.blit
	move.l	d6,d2
	lsl.l	d0,d2
	not.l	d2
	bfffo	d2{0:0},d4
	bfclr	d6{d0:d4}
	add.w	d0,d4
	sub.w	d1,d4
	move.w	d4,d3
	bra.s	.ext
.blit	bfset	(rd_rmask).l{d1:d3}
	bsr	rd_cq_blit
	cmpi.b	#1,(rd_cqkind).l
	beq.s	.k
	move.l	#$004009F0,(a5)+
	move.l	#$00420000,(a5)+
	move.l	#$0044FFFF,(a5)+
	move.l	#$0046FFFF,(a5)+
	move.b	#1,(rd_cqkind).l
.k	move.w	d5,d0
	andi.w	#DWRAP-1,d0
	mulu.w	#DLH*64*6,d0
	lea	(bmB).l,a0
	adda.l	d0,a0
	lea	(a0,d1.w*2),a0
	CQA	$050,a0,d4
	move.w	d5,d0
	mulu.w	#DLH*SROW,d0
	movea.l	(rd_buf).l,a0
	adda.l	d0,a0
	lea	SCRX(a0,d1.w*2),a0
	CQA	$054,a0,d4
	add.w	d3,d3
	moveq	#64,d0
	sub.w	d3,d0
	CQV	$064,d0,d4
	moveq	#SBPR,d0
	sub.w	d3,d0
	CQV	$066,d0,d4
	move.w	d7,d0
	sub.w	d5,d0
	mulu.w	#DLH*NPLANES,d0
	CQV	$05C,d0,d4
	lsr.w	#1,d3
	CQV	$05E,d3,d4
	bsr	rd_cq_endblit
	tst.l	d6
	bne	.run
	move.l	(rd_rmask).l,d0
	clr.l	(rd_rmask).l
	lea	(rd_wmap).l,a0
	movea.l	(rd_bmrp).l,a1
.wm	move.l	d0,(a0,d5.w*4)
	moveq	#DWRAP-1,d1
	and.w	d5,d1
	or.l	d0,(a1,d1.w*4)
	addq.w	#1,d5
	cmp.w	d7,d5
	blt.s	.wm
	cmp.w	(rd_rsend).l,d7
	blt	.row
	bra	rd_cq_flush

;	Note the rectangle d0 (x), d1 (y), d2 (w), d3 (h) on the screen as drawn over
;	in the back buffer's dirty map. Keeps everything (rd_mark_u: uses d0-d3/a0).
rd_mark
	movem.l	d0-d3/a0,-(sp)
	bsr.s	rd_mark_u
	movem.l	(sp)+,d0-d3/a0
	rts
rd_mark_u
	tst.w	d2
	ble	.x
	tst.w	d3
	ble	.x
	add.w	(rd_xorg).l,d0
	subi.w	#SCRX*8,d0
	add.w	d0,d2
	subq.w	#1,d2
	asr.w	#4,d0
	bpl.s	.1
	moveq	#0,d0
.1	asr.w	#4,d2
	cmpi.w	#31,d2
	ble.s	.2
	moveq	#31,d2
.2	sub.w	d0,d2
	bmi	.x
	addq.w	#1,d2
	add.w	(rd_brow0).l,d1
	add.w	d1,d3
	subq.w	#1,d3
	asr.w	#DLS,d1
	bpl.s	.3
	moveq	#0,d1
.3	asr.w	#DLS,d3
	cmpi.w	#DROWS-1,d3
	ble.s	.4
	moveq	#DROWS-1,d3
.4	sub.w	d1,d3
	bmi	.x
	move.b	d1,(rd_opbox).l
	move.b	d3,(rd_opbox+1).l
	move.b	d0,(rd_opbox+2).l
	move.b	d2,(rd_opbox+3).l
	tst.b	(rd_stage).l
	bne.s	.st
	ext.l	d0
	movea.l	(rd_dmap).l,a0
	lea	(a0,d1.w*4),a0
.r	bfset	(a0){d0:d2}
	addq.l	#4,a0
	dbf	d3,.r
.st	rts
.x	move.b	#$FF,(rd_opbox).l
	rts

;	Copy plane B to the back buffer at its scroll position (blitter).
rd_blitB
	movem.l	d0/a0,-(sp)
	movea.l	(rd_bmrp).l,a0
	moveq	#32-1,d0
.ba	move.l	#-1,(a0)+
	dbf	d0,.ba
	movem.l	(sp)+,d0/a0
	move.w	(rd_ch).l,d6
	lsl.w	#3,d6
	moveq	#0,d5
	move.w	(rd_by0).l,d4
.vp	move.w	d6,d3
	sub.w	d4,d3
	move.w	#SCRH,d2
	sub.w	d5,d2
	cmp.w	d2,d3
	ble	.vh
	move.w	d2,d3
.vh
	movem.w	d3-d6,-(sp)
	move.w	(rd_cw).l,d0
	lsl.w	#3,d0
	move.w	(rd_bx0).l,d1
	sub.w	d1,d0
	move.w	(rd_w).l,d2
	cmp.w	d2,d0
	bge	.one
	movem.w	d0-d2,-(sp)
	move.w	d0,d7
	moveq	#0,d1
	sub.w	d0,d2
	st	(rd_blitnoc).l
	bsr	rd_blitrect
	movem.w	(sp)+,d0-d2
	move.w	d0,d2
	moveq	#0,d7
	sf	(rd_blitnoc).l
	bsr	rd_blitrect
	bra	.hd
.one	moveq	#0,d7
	st	(rd_blitnoc).l
	bsr	rd_blitrect
.hd	movem.w	(sp)+,d3-d6
	add.w	d3,d5
	moveq	#0,d4
	cmpi.w	#SCRH,d5
	blt	.vp
	rts

;	Blit d2 pixels x d3 lines of plane B from (d1, d4) to the back buffer at (d7, d5).
rd_blitrect
	movem.l	d3-d7,-(sp)
	move.w	d7,d0
	add.w	(rd_xorg).l,d0
	move.w	d0,(rd_tmp).l
	move.w	d0,d6
	lsr.w	#4,d6
	move.w	d6,d7
	lsl.w	#4,d7
	sub.w	d0,d7
	add.w	d1,d7
	move.w	d7,d0
	asr.w	#4,d0
	andi.w	#15,d7
	beq	.r0
	addq.w	#1,d0
	neg.w	d7
	addi.w	#16,d7
.r0	subq.w	#1,d0
	subq.w	#1,d6
	move.w	(rd_tmp).l,d1
	add.w	d2,d1
	subq.w	#1,d1
	move.w	d1,d2
	lsr.w	#4,d2
	sub.w	d6,d2
	addq.w	#1,d2
	andi.w	#15,d1
	move.w	#$8000,d5
	asr.w	d1,d5
	bsr	rd_bq_alloc
	move.w	#$07CA,d3
	tst.b	(rd_blitnoc).l
	beq.s	.usec
	move.w	#$05C0,d3
.usec	move.w	d3,$040(a6)
	ror.w	#4,d7
	move.w	d7,$042(a6)
	move.w	#0,$044(a6)
	move.w	d5,$046(a6)
	move.w	#$FFFF,$074(a6)
	move.w	(rd_cw).l,d1
	move.w	d4,d3
	mulu.w	d1,d3
	mulu.w	#6,d3
	lea	(bmB).l,a0
	adda.l	d3,a0
	ext.l	d0
	add.l	d0,d0
	adda.l	d0,a0
	move.l	a0,$04C(a6)
	move.w	d2,d0
	add.w	d0,d0
	sub.w	d0,d1
	move.w	d1,$062(a6)
	movea.l	(rd_back).l,a0
	move.l	(sp),d3
	move.l	8(sp),d5
	mulu.w	#SROW,d5
	adda.l	d5,a0
	ext.l	d6
	add.l	d6,d6
	adda.l	d6,a0
	move.l	a0,$048(a6)
	move.l	a0,$054(a6)
	move.w	#SBPR,d1
	sub.w	d0,d1
	move.w	d1,$060(a6)
	move.w	d1,$066(a6)
	mulu.w	#6,d3
	move.w	d3,$05C(a6)
	move.w	d2,$05E(a6)
	bsr	rd_bq_go
	movem.l	(sp)+,d3-d7
	rts

;	The state that places the picture, taken at once (no game frame can run in between):
;	the layout (display.asm, as rd_layout), the plane A / B scroll, the sprite list.
rd_snapshot
	move	sr,-(sp)
	ori	#$0700,sr
	bsr	rd_layout_take
	move.l	(ds_vs).l,(rd_vs).l
	move.l	(ds_hs).l,(rd_hs).l
	sf	(rd_hsuni).l
	sf	(rd_hslb).l
	tst.b	(ds_lines).l
	beq.s	.hu
	lea	(ds_hs).l,a0
	move.l	(a0),d2
	move.w	#SCRH-1,d1
.hl	cmp.l	(a0)+,d2
	bne.s	.hb
	dbf	d1,.hl
	st	(rd_hsuni).l
	bra.s	.hu
.hb
	lea	(ds_hs).l,a0
	lea	(rd_hsb).l,a1
	swap	d2
	move.w	#SCRH-1,d3
.hbl	cmp.w	(a0)+,d2
	bne.s	.hu
	move.w	(a0)+,(a1)+
	dbf	d3,.hbl
	move.w	-2(a1),(rd_hs+2).l
	st	(rd_hslb).l
.hu
	sf	(rd_narrow).l
	cmpi.w	#128,(rd_lcw).l
	bne	.nn
	tst.b	(rd_llines).l
	beq.s	.nu
	tst.b	(rd_hsuni).l
	bne.s	.nu
	tst.b	(rd_hslb).l
	beq	.nn
.nu	move.w	#512-8-320,d2
	tst.b	(rd_lwide).l
	bne.s	.nw
	move.w	#512-8-256,d2
.nw	move.w	(rd_hs+2).l,d1
	neg.w	d1
	andi.w	#1023,d1
	cmp.w	d2,d1
	bhi	.nn
	lea	(vm_data).l,a0
	move.l	(rd_lntb).l,d1
	lea	(a0,d1.l),a1
	lea	(rd_vntB).l,a2
	moveq	#0,d3
	bsr.s	.nc
	move.w	(rd_hs).l,d3
	neg.w	d3
	andi.w	#1023,d3
	moveq	#7,d1
	and.w	d3,d1
	neg.w	d1
	move.w	d1,(rd_hs).l
	lsr.w	#3,d3
	move.l	(rd_lnta).l,d1
	lea	(a0,d1.l),a1
	lea	(rd_vntA).l,a2
	bsr.s	.nc
	move.w	#64,(rd_lcw).l
	st	(rd_narrow).l
	bra.s	.nn
.nc	moveq	#32-1,d1
.ncr	lea	(a1,d3.w*2),a3
	move.w	#128,d4
	sub.w	d3,d4
	cmpi.w	#64,d4
	bls.s	.nc1
	moveq	#64,d4
.nc1	moveq	#64,d5
	sub.w	d4,d5
	bsr.s	.ncw
	movea.l	a1,a3
	move.w	d5,d4
	bsr.s	.ncw
	lea	256(a1),a1
	dbf	d1,.ncr
	rts
.ncw	lsr.w	#1,d4
	bcc.s	.ncl0
	move.w	(a3)+,(a2)+
.ncl0	subq.w	#1,d4
	bmi.s	.ncx
.ncl	move.l	(a3)+,(a2)+
	dbf	d4,.ncl
.ncx	rts
.nn	tst.b	(rd_narrow).l
	bne.s	.nk
	sf	(rd_hslb).l
.nk	bsr	rd_collect_sprites
	bsr	rd_obj_mark
	move	(sp)+,sr
	rts

;	The layout (display.asm) this frame is drawn with (rd_layout). Uses d0.
rd_layout_take
	move.b	(ds_wide).l,(rd_lwide).l
	move.b	(ds_lines).l,(rd_llines).l
	move.b	(ds_win).l,(rd_lwin).l
	moveq	#64,d0
	tst.b	(ds_big).l
	beq.s	.s
	move.w	#128,d0
.s	move.w	d0,(rd_lcw).l
	moveq	#0,d0
	move.w	(ds_nta).l,d0
	andi.w	#$E000,d0
	move.l	d0,(rd_lnta).l
	move.w	(ds_ntb).l,d0
	andi.w	#$E000,d0
	move.l	d0,(rd_lntb).l
	move.w	(ds_ntw).l,d0
	andi.w	#$F800,d0
	tst.b	(ds_wide).l
	beq.s	.w
	andi.w	#$F000,d0
.w	move.l	d0,(rd_lntw).l
	rts

;	The sprite list, followed from sprite 0 through the links.
rd_collect_sprites
	moveq	#64,d6
	tst.b	(rd_lwide).l
	beq.s	.32
	moveq	#80,d6
.32	lea	(ds_spr).l,a0
	lea	(rd_sprites).l,a1
	moveq	#0,d1
	moveq	#0,d5
	sf	(rd_sprnsq).l
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

;	Masked write of one 8 pixel row at screen x d0 on the row a1 (overlay line): d1 = planes
;	0-3 (p0 in the high byte), d2 = palette (planes 4, 5), d3 = mask byte. Uses d4-d7, a0.
rd_put8
	moveq	#0,d4
	move.b	d3,d4
	beq	.x
	move.w	d0,d5
	addi.w	#4*8,d5
	move.w	d5,d6
	lsr.w	#3,d6
	lea	(a1,d6.w),a0
	andi.w	#7,d5
	bne	.shift
	cmpi.b	#$FF,d4
	bne	.bmask
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
.bmask
	move.b	d4,d6
	not.b	d6
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
.shift
	lsl.w	#8,d4
	lsr.w	d5,d4
	move.w	d4,d6
	not.w	d6
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

;	Mark the screen cells of the rectangle d0 (x), d1 (y), d2 (w), d3 (h) as covered
;	by something of low priority. Keeps everything (rd_cover_u: uses d0-d3/a0).
rd_cover_rect
	movem.l	d0-d3/a0,-(sp)
	bsr.s	rd_cover_u
	movem.l	(sp)+,d0-d3/a0
	rts
rd_cover_u
	add.w	d0,d2
	subq.w	#1,d2
	add.w	d1,d3
	subq.w	#1,d3
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
	addq.w	#1,d2
	lea	(rd_cover).l,a0
	lea	(a0,d1.w*8),a0
	sub.w	d1,d3
	move.w	d0,d1
	add.w	d2,d1
	cmpi.w	#32,d1
	bhi.s	.r2
	moveq	#0,d1
	bfset	d1{d0:d2}
.r1	or.l	d1,(a0)
	addq.l	#8,a0
	dbf	d3,.r1
	rts
.r2	cmpi.w	#32,d0
	blo.s	.both
	addq.l	#4,a0
	moveq	#0,d1
	bfset	d1{d0:d2}
	bra.s	.r1
.both	moveq	#-32,d2
	add.w	d1,d2
	moveq	#0,d1
	bfset	d1{0:d2}
	move.l	d1,d2
	moveq	#-1,d1
	lsr.l	d0,d1
.rb	or.l	d1,(a0)+
	or.l	d2,(a0)+
	dbf	d3,.rb
.x	rts

;	Plane A and the window.

;	The HUD as hardware sprites.
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
	bsr	rd_hud_off
	sf	(rd_hudchg).l
	move.w	(rd_w).l,(rd_hudw).l
	cmpi.w	#256,(rd_w).l
	bne	.x
	lea	(rd_hudcols).l,a0
	moveq	#12-1,d0
.cc	clr.l	(a0)+
	dbf	d0,.cc
	lea	(rd_ovlmhi).l,a1
	moveq	#-1,d6
	moveq	#0,d7
	moveq	#0,d5
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
	bmi	.x
	move.w	d7,d0
	sub.w	d6,d0
	addq.w	#1,d0
	cmpi.w	#HUDH,d0
	bhi	.x
	move.w	d6,(rd_hudy).l
	move.w	d0,(rd_hudn).l
	lea	(rd_hudcols).l,a0
	lea	(rd_hudg).l,a1
	moveq	#0,d5
	moveq	#4,d0
.gs	cmpi.w	#36,d0
	bge.s	.ge
	tst.b	(a0,d0.w)
	bne.s	.g1
	addq.w	#1,d0
	bra.s	.gs
.g1	cmpi.w	#4,d5
	beq	.x
	move.w	d0,(a1)+
	addq.w	#1,d5
	addq.w	#8,d0
	bra.s	.gs
.ge
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
	lea	(rd_hudmo).l,a0
	move.w	#HUDMO*16/4-1,d0
.cmo	clr.l	(a0)+
	dbf	d0,.cmo
	lea	(rd_hudm).l,a0
	move.l	a0,(rd_hudbase).l
	move.w	#8*HUDSPR/4-1,d0
.cs	clr.l	(a0)+
	dbf	d0,.cs
	moveq	#0,d5
.grp	movea.l	(rd_hudbase).l,a3
	move.w	d5,d0
	mulu.w	#2*HUDSPR,d0
	adda.l	d0,a3
	lea	HUDSPR(a3),a4
	movem.l	a3-a4,-(sp)
	lea	(rd_hudg).l,a0
	move.w	(a0,d5.w*2),d4
	move.w	(rd_hudy).l,d6
	moveq	#0,d7
.gl	move.w	d6,d0
	mulu.w	#OSROW,d0
	lea	(rd_ovl).l,a1
	adda.l	d0,a1
	adda.w	d4,a1
	lea	(rd_ovlmhi).l,a2
	adda.l	d0,a2
	adda.w	d4,a2
	movem.l	(sp),a3-a4
	move.w	d7,d0
	lsl.w	#4,d0
	lea	16(a3,d0.w),a5
	lea	16(a4,d0.w),a6
	moveq	#0,d3
.gb	move.w	d4,d0
	add.w	d3,d0
	cmpi.w	#48,d0
	bge.s	.nb
	move.b	(a2,d3.w),d2
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
	moveq	#$3C,d0
	tst.b	(hal_pal).l
	bne.s	.vp
	moveq	#$1A,d0
.vp	add.w	(rd_hudy).l,d0
	move.w	d0,d1
	add.w	(rd_hudn).l,d1
	move.w	d4,d2
	lsl.w	#3,d2
	subi.w	#32,d2
	addi.w	#HUDX,d2
	move.w	d0,d3
	lsl.w	#8,d3
	move.w	d2,d6
	lsr.w	#1,d6
	move.b	d6,d3
	move.w	d1,d6
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
.h0	move.w	d3,(a3)
	move.w	d6,8(a3)
	move.w	d3,(a4)
	bset	#7,d6
	move.w	d6,8(a4)
	addq.w	#1,d5
	cmp.w	(rd_hudgn).l,d5
	blt	.grp
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
	lea	(rd_hudbd).l,a0
	moveq	#NBUF-1,d0
.ba	move.l	#-1,(a0)+
	dbf	d0,.ba
	bra.s	.x
.full	addq.l	#8,sp
	bsr	rd_hud_off
	sf	(rd_hudchg).l
.x	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	A cell of the overlay changed: its bytes of the HUD sprites in use made again;
;	a full build if it is not in their columns and lines, or needs a 16th colour.
rd_hud_cell
	tst.w	(rd_hudon).l
	bne.s	.on
	st	(rd_hudchg).l
	rts
.on	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d1,d3
	addi.w	#4*8,d3
	lsr.w	#3,d3
	lea	(rd_hudg).l,a0
	move.w	(rd_hudgn).l,d7
	subq.w	#1,d7
	moveq	#0,d5
.fg	move.w	d3,d4
	sub.w	(a0)+,d4
	bmi.s	.ng
	cmpi.w	#8,d4
	blt.s	.fd
.ng	addq.w	#1,d5
	dbf	d7,.fg
	bra	.full
.fd
	moveq	#0,d0
	move.w	d2,d0
	sub.w	(rd_hudy).l,d0
	bpl.s	.b0
	moveq	#0,d0
.b0	moveq	#0,d1
	move.w	d2,d1
	addq.w	#7,d1
	sub.w	(rd_hudy).l,d1
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
	add.w	d6,d0
	add.w	d6,d1
	lea	(rd_hudbd).l,a0
	moveq	#NBUF-1,d6
.bb	bfset	(a0){d0:1}
	bfset	(a0){d1:1}
	addq.l	#4,a0
	dbf	d6,.bb
.bx
	lea	(rd_hudspt).l,a0
	movea.l	(a0,d5.w*8),a3
	movea.l	4(a0,d5.w*8),a4
	move.w	d2,d6
	moveq	#7,d7
.ln	move.w	d6,d0
	bmi.s	.nl
	cmpi.w	#SCRH,d0
	bge.s	.nl
	mulu.w	#OSROW,d0
	lea	(rd_ovl).l,a0
	adda.l	d0,a0
	adda.w	d3,a0
	lea	(rd_ovlmhi).l,a1
	adda.l	d0,a1
	move.b	(a1,d3.w),d2
	move.w	d6,d0
	sub.w	(rd_hudy).l,d0
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
	bne.s	.full
.nl	addq.w	#1,d6
	dbf	d7,.ln
	bra.s	.x
.full	st	(rd_hudchg).l
.x	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	One byte (8 pixels) of the HUD sprites: a0 = the overlay's byte (plane p at p * OSBPR), d2
;	= its high priority mask, a5 / a6 = the even / odd sprite's byte. Uses d0-d1, d3-d7, a3-a4.
HUDMO	equ	64
rd_hud_byte
	moveq	#0,d0
	move.b	(a0),d0
	lsl.w	#8,d0
	move.b	OSBPR(a0),d0
	swap	d0
	move.b	2*OSBPR(a0),d0
	lsl.w	#8,d0
	move.b	3*OSBPR(a0),d0
	moveq	#0,d1
	move.b	d2,d1
	move.w	d1,d3
	lsl.w	#8,d3
	or.w	d3,d1
	move.w	d1,d3
	swap	d1
	move.w	d3,d1
	and.l	d1,d0
	moveq	#1,d1
	lsl.w	#8,d1
	move.b	4*OSBPR(a0),d1
	and.b	d2,d1
	lsl.l	#8,d1
	move.b	5*OSBPR(a0),d1
	and.b	d2,d1
	lsl.l	#8,d1
	move.b	d2,d1
	move.l	d0,d3
	eor.l	d1,d3
	move.l	d3,d4
	swap	d4
	eor.w	d4,d3
	move.w	d3,d4
	lsr.w	#6,d4
	eor.w	d4,d3
	andi.w	#HUDMO-1,d3
	lsl.w	#4,d3
	lea	(rd_hudmo).l,a3
	adda.w	d3,a3
	cmp.l	(a3),d0
	bne.s	.mm
	cmp.l	4(a3),d1
	bne.s	.mm
	move.b	8(a3),(a5)
	move.b	9(a3),8(a5)
	move.b	10(a3),(a6)
	move.b	11(a3),8(a6)
	andi	#$FE,ccr
	rts
.mm	movem.l	d0-d1/a3,-(sp)
	bsr.s	.make
	movem.l	(sp)+,d0-d1/a3
	bcs.s	.mx
	move.l	d0,(a3)
	move.l	d1,4(a3)
	move.b	d4,8(a3)
	move.b	d5,9(a3)
	move.b	d6,10(a3)
	move.b	d7,11(a3)
	andi	#$FE,ccr
.mx	rts
.make	lea	(rd_hudcm).l,a3
	lea	(rd_hudmap).l,a4
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	moveq	#0,d7
	moveq	#7,d0
.px	btst	d0,d2
	beq	.pn
	moveq	#0,d1
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
.c6	move.b	(a3,d1.w),d3
	bne.s	.cok
	move.w	(rd_hudnc).l,d3
	cmpi.w	#15,d3
	beq.s	.full
	addq.w	#1,d3
	move.w	d3,(rd_hudnc).l
	move.b	d3,(a3,d1.w)
	move.b	d1,(a4,d3.w)
	addq.l	#1,(rd_hudgen).l
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
	andi	#$FE,ccr
	rts
.full	ori	#1,ccr
	rts

;	The plane A / window overlay: the listed cells drawn into a screen sized
;	bitmap with a mask plane per priority, redrawn only when the list changes.

rd_ovl_redraw
	st	(rd_hudchg).l
	sf	(rd_ovldirty).l
	st	(rd_ovlrst).l
	addq.l	#1,(rd_ovlgen).l
	lea	(rd_ovlbg).l,a0
	move.l	(rd_ovlgen).l,d0
	move.l	(rd_ovlpart).l,d2
	moveq	#0,d1
.bg	tst.l	d2
	beq.s	.bg1
	btst	d1,d2
	beq.s	.bg2
.bg1	move.l	d0,(a0)
.bg2	addq.l	#4,a0
	addq.w	#1,d1
	cmpi.w	#32,d1
	blo.s	.bg
	bsr	rd_waitblit
	lea	(rd_ovlrows).l,a0
	moveq	#0,d6
	moveq	#0,d7
	moveq	#-1,d2
	moveq	#32,d3
.sz	bsr	.inp
	beq.s	.sz1
	bsr	rd_ovl_bandw
	bmi.s	.sz1
	sub.w	d0,d1
	addq.w	#1,d1
	add.w	d1,d6
	move.w	d7,d2
	cmp.w	d3,d7
	bge.s	.sz1
	move.w	d7,d3
.sz1	addq.l	#4,a0
	addq.w	#1,d7
	cmpi.w	#32,d7
	blo.s	.sz
	tst.w	d2
	bmi	.clr
	cmpi.w	#OVLCPU,d6
	bhi	.blit
	lea	(rd_ovlrows).l,a0
	moveq	#0,d7
.cb	bsr	.inp
	beq.s	.cbn
	bsr	rd_ovl_bandw
	bmi.s	.cbn
	move.w	d7,d2
	subq.w	#1,d2
	lsl.w	#3,d2
	moveq	#7,d3
.cl	tst.w	d2
	bmi.s	.cln
	cmpi.w	#SCRH,d2
	bge.s	.cbn
	move.w	d2,d4
	mulu.w	#OSROW,d4
	lea	(rd_ovl).l,a1
	adda.l	d4,a1
	lea	(a1,d0.w*2),a1
	moveq	#NPLANES-1,d4
.cp	movea.l	a1,a3
	adda.l	#rd_ovlmlo-rd_ovl,a3
	movea.l	a1,a4
	adda.l	#rd_ovlmhi-rd_ovl,a4
	move.w	d1,d5
	sub.w	d0,d5
.cw	clr.w	(a3)+
	clr.w	(a4)+
	dbf	d5,.cw
	lea	OSBPR(a1),a1
	dbf	d4,.cp
.cln	addq.w	#1,d2
	dbf	d3,.cl
.cbn	addq.l	#4,a0
	addq.w	#1,d7
	cmpi.w	#32,d7
	blo.s	.cb
	bra	.clr
.blit
	subq.w	#1,d3
	lsl.w	#3,d3
	bpl.s	.b0
	moveq	#0,d3
.b0	lsl.w	#3,d2
	addq.w	#7,d2
	cmpi.w	#SCRH-1,d2
	ble.s	.b1
	move.w	#SCRH-1,d2
.b1	sub.w	d3,d2
	addq.w	#1,d2
	mulu.w	#NPLANES,d2
	mulu.w	#OSROW,d3
	bsr	rd_cq_inval
	lea	(CUSTOM).l,a6
	move.w	#$0100,$040(a6)
	move.w	#0,$042(a6)
	move.w	#0,$066(a6)
	lea	(rd_ovlmlo).l,a0
	adda.l	d3,a0
	move.l	a0,$054(a6)
	move.w	d2,$05C(a6)
	move.w	#OSBPR/2,$05E(a6)
	bsr	rd_waitblit
	lea	(rd_ovlmhi).l,a0
	adda.l	d3,a0
	move.l	a0,$054(a6)
	move.w	d2,$05C(a6)
	move.w	#OSBPR/2,$05E(a6)
.clr
	lea	(rd_ovlrows).l,a0
	lea	(rd_ovlcolf).l,a1
	moveq	#0,d7
.ir	bsr	.inp
	beq.s	.ir1
	move.w	#$7FFF,(a0)
	move.w	#-$7FFF,2(a0)
	move.w	#$7FFF,32*4(a0)
	move.w	#-$7FFF,32*4+2(a0)
	moveq	#48/4-1,d0
.icf	clr.l	32*48(a1)
	clr.l	(a1)+
	dbf	d0,.icf
	lea	-48(a1),a1
.ir1	addq.l	#4,a0
	lea	48(a1),a1
	addq.w	#1,d7
	cmpi.w	#32,d7
	blo.s	.ir
	bsr	rd_waitblit
	lea	(rd_alist).l,a4
	move.w	(rd_alistn).l,d7
	subq.w	#1,d7
	bmi	.x
.c	move.w	(a4)+,d1
	move.w	(a4)+,d2
	move.w	(a4)+,d0
	move.l	(rd_ovlpart).l,d4
	beq.s	.cd
	move.w	d2,d3
	asr.w	#3,d3
	addq.w	#1,d3
	btst	d3,d4
	bne.s	.cd
	moveq	#7,d5
	and.w	d2,d5
	beq.s	.cs
	addq.w	#1,d3
	btst	d3,d4
	beq.s	.cs
.cd	movem.l	d7/a4,-(sp)
	bsr	rd_ovl_cell
	movem.l	(sp)+,d7/a4
.cs	dbf	d7,.c
.x	clr.l	(rd_ovlpart).l
	rts
.inp
	move.l	(rd_ovlpart).l,d0
	beq.s	.in1
	btst	d7,d0
	rts
.in1	moveq	#1,d0
	rts

;	The words of band a0 (rd_ovlrows: low priority there, high 32 bands on) that its cells cover,
;	either priority: d0 the first, d1 the last (in a row of the overlay); N set if none. Uses d0-d1.
OVLCPU	equ	48
rd_ovl_bandw
	move.w	(a0),d0
	move.w	2(a0),d1
	cmp.w	32*4(a0),d0
	ble.s	.1
	move.w	32*4(a0),d0
.1	cmp.w	32*4+2(a0),d1
	bge.s	.2
	move.w	32*4+2(a0),d1
.2	cmp.w	d1,d0
	bgt.s	.none
	addi.w	#32,d0
	bpl.s	.3
	moveq	#0,d0
.3	asr.w	#4,d0
	addi.w	#32,d1
	asr.w	#4,d1
	cmpi.w	#OSBPR/2-1,d1
	ble.s	.4
	moveq	#OSBPR/2-1,d1
.4	cmp.w	d1,d0
	bgt.s	.none
	tst.w	d0
	rts
.none	moveq	#-1,d0
	rts

;	Cell d0 at (d1, d2) into the overlay.
rd_ovl_cell
	addq.l	#1,(rd_ovlgen).l
	lea	(rd_ovlbg).l,a0
	lea	(rd_ovlrows).l,a5
	tst.w	d0
	bpl	.lo
	lea	32*4(a5),a5
.lo	move.w	d2,d3
	asr.w	#3,d3
	addq.w	#1,d3
	moveq	#1,d4
	lea	(rd_ovlcolf).l,a6
	tst.w	d0
	bpl.s	.clo
	lea	32*48(a6),a6
.clo
.band	cmpi.w	#31,d3
	bhi	.nb
	move.l	(rd_ovlgen).l,(a0,d3.w*4)
	move.w	d3,d5
	mulu.w	#48,d5
	move.w	d1,d6
	addq.w	#8,d6
	asr.w	#3,d6
	bmi.s	.f1
	cmpi.w	#47,d6
	bhi.s	.f1
	add.w	d5,d6
	tst.b	(a6,d6.w)
	bne.s	.f1
	st	(a6,d6.w)
	st	(rd_ovlrst).l
.f1	move.w	d1,d6
	addi.w	#15,d6
	asr.w	#3,d6
	bmi.s	.f2
	cmpi.w	#47,d6
	bhi.s	.f2
	add.w	d5,d6
	tst.b	(a6,d6.w)
	bne.s	.f2
	st	(a6,d6.w)
	st	(rd_ovlrst).l
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
	andi.w	#3,d6
	lea	(rd_ovlmlo).l,a5
	tst.w	d0
	bpl	.mlo
	lea	(rd_ovlmhi).l,a5
.mlo	move.w	d1,d0
	move.w	d2,d7
	move.w	d6,d2
	move.w	d0,d1
	addi.w	#4*8,d1
	moveq	#7,d3
	and.w	d1,d3
	beq	.al
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
	lsr.l	d6,d1
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
.al
	lsr.w	#3,d1
	move.w	d7,d3
	muls.w	#OSROW,d3
	lea	(rd_ovl).l,a1
	adda.l	d3,a1
	adda.w	d1,a1
	movea.l	a5,a0
	adda.l	d3,a0
	adda.w	d1,a0
	moveq	#0,d0
	lsr.b	#1,d2
	bcc.s	.p4
	moveq	#-1,d0
.p4	neg.b	d2
	moveq	#7,d1
	cmpi.w	#SCRH-8,d7
	bhi.s	.ar
.a6	move.b	(a3),d3
	move.l	(a2),d6
	move.b	d6,3*OSBPR(a1)
	lsr.l	#8,d6
	move.b	d6,2*OSBPR(a1)
	lsr.w	#8,d6
	move.b	d6,OSBPR(a1)
	swap	d6
	move.b	d6,(a1)
	move.b	d3,d6
	and.b	d0,d6
	move.b	d6,4*OSBPR(a1)
	move.b	d3,d6
	and.b	d2,d6
	move.b	d6,5*OSBPR(a1)
	move.b	d3,(a0)
	move.b	d3,OSBPR(a0)
	move.b	d3,2*OSBPR(a0)
	move.b	d3,3*OSBPR(a0)
	move.b	d3,4*OSBPR(a0)
	move.b	d3,5*OSBPR(a0)
	adda.w	d4,a2
	adda.w	d5,a3
	lea	OSROW(a1),a1
	lea	OSROW(a0),a0
	dbf	d1,.a6
	rts
.ar	tst.w	d7
	bmi.s	.as
	cmpi.w	#SCRH,d7
	bge	.done
	move.b	(a3),d3
	move.l	(a2),d6
	move.b	d6,3*OSBPR(a1)
	lsr.l	#8,d6
	move.b	d6,2*OSBPR(a1)
	lsr.w	#8,d6
	move.b	d6,OSBPR(a1)
	swap	d6
	move.b	d6,(a1)
	move.b	d3,d6
	and.b	d0,d6
	move.b	d6,4*OSBPR(a1)
	move.b	d3,d6
	and.b	d2,d6
	move.b	d6,5*OSBPR(a1)
	move.b	d3,(a0)
	move.b	d3,OSBPR(a0)
	move.b	d3,2*OSBPR(a0)
	move.b	d3,3*OSBPR(a0)
	move.b	d3,4*OSBPR(a0)
	move.b	d3,5*OSBPR(a0)
.as	adda.w	d4,a2
	adda.w	d5,a3
	lea	OSROW(a1),a1
	lea	OSROW(a0),a0
	addq.w	#1,d7
	dbf	d1,.ar
	rts

;	Cut the overlay of priority rd_pass into the back buffer: its rectangles (rd_ovl_rects),
;	one blit each for the 6 planes (A the mask plane, B the overlay, C / D the screen).
rd_ovl_blit
	tst.b	(rd_ovlrst).l
	beq.s	.r
	bsr	rd_ovl_rects
.r	lea	(rd_ovlrl).l,a4
	movea.l	#rd_ovlmlo,a3
	tst.w	(rd_pass).l
	beq.s	.lo
	lea	(rd_ovlrh).l,a4
	movea.l	#rd_ovlmhi,a3
.lo	move.w	(a4)+,d7
	bra.s	.e
.rect	movem.w	(a4)+,d0-d3
	movem.l	d7/a4,-(sp)
	bsr.s	.blitrun
	movem.l	(sp)+,d7/a4
.e	dbf	d7,.rect
	bra	rd_cq_flush
.blitrun
	bfset	(rd_ovrd).l{d2:d3}
	moveq	#0,d6
	lea	(rd_ovlbg).l,a0
	lea	(a0,d2.w*4),a0
	move.w	d3,d4
	subq.w	#1,d4
.kg	cmp.l	(a0)+,d6
	bhs.s	.kn
	move.l	-4(a0),d6
.kn	dbf	d4,.kg
	move.l	d6,(rd_ovlkey).l
	subq.w	#1,d2
	lsl.w	#3,d2
	lsl.w	#3,d3
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
	addq.w	#1,d4
	movem.l	d0-d3,-(sp)
	move.w	d2,d1
	move.w	d4,d2
	bsr	rd_mark
	tst.w	(rd_pass).l
	bne.s	.nocov
	bsr	rd_cover_rect
.nocov	movem.l	(sp)+,d0-d3
	addi.w	#4*8,d0
	addi.w	#4*8,d1
	lsr.w	#4,d0
	lsr.w	#4,d1
	sub.w	d0,d1
	addq.w	#2,d1
	move.w	(rd_xorg).l,d6
	subi.w	#4*8,d6
	moveq	#15,d5
	and.w	d6,d5
	lsr.w	#4,d6
	add.w	d0,d6
	add.w	d0,d0
	add.w	d6,d6
	move.w	d2,d4
	mulu.w	#OSROW,d4
	lea	(rd_ovl).l,a1
	adda.l	d4,a1
	adda.w	d0,a1
	lea	(a3,d4.l),a2
	adda.w	d0,a2
	move.w	d2,d4
	mulu.w	#SROW,d4
	movea.l	(rd_back).l,a0
	adda.l	d4,a0
	adda.w	d6,a0
	move.w	d1,d4
	add.w	d4,d4
	move.l	a5,-(sp)
	move.w	d1,d7
	move.w	#OSBPR,d0
	sub.w	d4,d0
	moveq	#SBPR,d1
	sub.w	d4,d1
	move.w	d3,d2
	mulu.w	#NPLANES,d2
	move.w	d7,d3
	move.w	d5,d4
	ror.w	#4,d4
	moveq	#0,d5
	move.l	(rd_ovlkey).l,d6
	bsr	rd_cut_emit
	movea.l	(sp)+,a5
.bx	rts

;	The overlay's rectangles, per priority, from the runs of columns with cells in each band of
;	8 lines: a run the same in the band below makes its rectangle one band taller. Keeps all.
OVLRUNS	equ	24
OVLRECTS	equ	30*OVLRUNS
rd_ovl_rects
	sf	(rd_ovlrst).l
	movem.l	d0-d7/a0-a6,-(sp)
	lea	(rd_ovlrows).l,a4
	lea	(rd_ovlcolf).l,a5
	lea	(rd_ovlrl).l,a6
	bsr.s	.pass
	lea	(rd_ovlrows+32*4).l,a4
	lea	(rd_ovlcolf+32*48).l,a5
	lea	(rd_ovlrh).l,a6
	bsr.s	.pass
	movem.l	(sp)+,d0-d7/a0-a6
	rts
.pass	movea.l	a6,a0
	clr.w	(a6)+
	lea	(rd_ovlrun).l,a1
	lea	OVLRUNS*8(a1),a2
	clr.w	(rd_ovlrpn).l
	moveq	#0,d7
.band	moveq	#0,d5
	movea.l	a1,a3
	move.w	(rd_ovlrpn).l,d4
	move.w	(a4),d0
	move.w	2(a4),d1
	cmp.w	d1,d0
	bgt	.nb
	addq.w	#8,d0
	asr.w	#3,d0
	addq.w	#8,d1
	asr.w	#3,d1
	tst.w	d0
	bpl.s	.c0
	moveq	#0,d0
.c0	cmpi.w	#47,d1
	ble.s	.run
	moveq	#47,d1
.run	cmp.w	d1,d0
	bgt	.nb
	tst.b	(a5,d0.w)
	bne.s	.rs
	addq.w	#1,d0
	bra.s	.run
.rs	move.w	d0,d2
.re	addq.w	#1,d0
	cmp.w	d1,d0
	bgt.s	.rx
	tst.b	(a5,d0.w)
	bne.s	.re
.rx	move.w	d0,d3
	subq.w	#1,d3
.pr	tst.w	d4
	beq.s	.new
	cmp.w	(a3),d2
	blt.s	.new
	beq.s	.pe
	addq.l	#8,a3
	subq.w	#1,d4
	bra.s	.pr
.pe	cmp.w	2(a3),d3
	bne.s	.new
	move.w	4(a3),d6
	addq.w	#1,8(a0,d6.w*8)
	addq.l	#8,a3
	subq.w	#1,d4
	bra.s	.cur
.new	move.w	d2,d6
	lsl.w	#3,d6
	subq.w	#8,d6
	move.w	d6,(a6)+
	move.w	d3,d6
	lsl.w	#3,d6
	subq.w	#1,d6
	move.w	d6,(a6)+
	move.w	d7,(a6)+
	move.w	#1,(a6)+
	move.w	(a0),d6
	addq.w	#1,(a0)
.cur	move.w	d2,(a2,d5.w*8)
	move.w	d3,2(a2,d5.w*8)
	move.w	d6,4(a2,d5.w*8)
	addq.w	#1,d5
	bra.s	.run
.nb	move.w	d5,(rd_ovlrpn).l
	exg	a1,a2
	addq.l	#4,a4
	lea	48(a5),a5
	addq.w	#1,d7
	cmpi.w	#30,d7
	blt	.band
	rts

;	Redraw the overlay cells of the listed changed name table
;	longs (rd_chgA, rd_chgW), plane A scrolled by whole cells.
rd_ovl_cells_changed
	lea	(rd_aused).l,a3
	lea	(rd_chgA).l,a4
	move.w	(rd_nchgA).l,d4
	bra	.anext
.aloop	move.w	(a4)+,d0
	add.w	d0,d0
	moveq	#1,d3
.acell	movem.l	d0/d3-d4/a4,-(sp)
	moveq	#0,d1
	move.w	d0,d1
	divu.w	d6,d1
	move.l	d1,d2
	swap	d2
	move.w	(rd_ax0).l,d5
	lsr.w	#3,d5
	sub.w	d5,d2
	move.w	d6,d5
	subq.w	#1,d5
	and.w	d5,d2
	move.w	(rd_ay0).l,d5
	lsr.w	#3,d5
	sub.w	d5,d1
	move.w	d7,d5
	subq.w	#1,d5
	and.w	d5,d1
	cmp.w	(rd_cells).l,d2
	bhi.s	.askip
	cmpi.w	#28,d1
	bhi.s	.askip
	movem.l	d0-d1,-(sp)
	move.w	d2,d4
	move.w	d1,d5
	bsr	rd_inwindow
	movem.l	(sp)+,d0-d1
	bne.s	.askip
	lea	(rd_shA).l,a0
	move.w	(a0,d0.w*2),d0
	lsl.w	#3,d2
	lsl.w	#3,d1
	exg	d1,d2
	bsr	rd_ovl_setcell
.askip	movem.l	(sp)+,d0/d3-d4/a4
	addq.w	#1,d0
	dbf	d3,.acell
.anext	dbf	d4,.aloop
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
	swap	d2
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

;	Cell d0 at (d1, d2), a whole cell position: clear it in the
;	overlay and its masks, then draw it if its tile is not empty.
rd_ovl_setcell
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(rd_ovrd).l,d3
	or.l	(rd_ovrd+4).l,d3
	or.l	(rd_ovrd+8).l,d3
	move.w	d2,d4
	asr.w	#3,d4
	addq.w	#1,d4
	ext.l	d4
	moveq	#1,d5
	moveq	#7,d6
	and.w	d2,d6
	beq.s	.w1
	moveq	#2,d5
.w1	bftst	d3{d4:d5}
	beq.s	.nw
	bsr	rd_waitblit
	clr.l	(rd_ovrd).l
	clr.l	(rd_ovrd+4).l
	clr.l	(rd_ovrd+8).l
.nw
	move.w	d0,d3
	andi.l	#$7FF,d3
	lea	(rd_aused).l,a3
	bfset	(a3){d3:1}
	TNEED	d3
	move.w	d0,d3
	andi.w	#$FFF,d3
	lea	(tp_cls).l,a0
	tst.b	(a0,d3.w)
	sne	d7
	move.w	d1,d3
	addi.w	#4*8,d3
	lsr.w	#3,d3
	move.w	d2,d6
	muls.w	#OSROW,d6
	ext.l	d3
	add.l	d3,d6
	lea	(rd_ovlmlo).l,a2
	lea	(rd_ovlmhi).l,a1
	tst.w	d0
	bpl.s	.ot
	exg	a1,a2
.ot	adda.l	d6,a1
	adda.l	d6,a2
	moveq	#7,d4
	move.w	d2,d5
.cl	tst.w	d5
	bmi.s	.cn
	cmpi.w	#SCRH,d5
	bge.s	.cn
	clr.b	(a1)
	clr.b	OSBPR(a1)
	clr.b	2*OSBPR(a1)
	clr.b	3*OSBPR(a1)
	clr.b	4*OSBPR(a1)
	clr.b	5*OSBPR(a1)
	tst.b	d7
	bne.s	.cn
	clr.b	(a2)
	clr.b	OSBPR(a2)
	clr.b	2*OSBPR(a2)
	clr.b	3*OSBPR(a2)
	clr.b	4*OSBPR(a2)
	clr.b	5*OSBPR(a2)
.cn	lea	OSROW(a1),a1
	lea	OSROW(a2),a2
	addq.w	#1,d5
	dbf	d4,.cl
	tst.b	d7
	beq.s	.e
	bsr	rd_ovl_cell
	bra.s	.x
.e	addq.l	#1,(rd_ovlgen).l
	move.w	d2,d3
	asr.w	#3,d3
	addq.w	#1,d3
	cmpi.w	#31,d3
	bhi.s	.x
	lea	(rd_ovlbg).l,a0
	move.l	(rd_ovlgen).l,(a0,d3.w*4)
.x	movem.l	4(sp),d1-d2
	bsr	rd_hud_cell
	movem.l	(sp)+,d0-d7/a0-a6
	rts

CHGMAX	equ	512

;	Tiles the overlay uses were converted again: the name table longs with a cell of one listed
;	too, as if they had changed; d5 = 1 if there were any, 2 if there is no room. Uses d0-d4, a0-a2.
rd_ovl_tilecells
	moveq	#-1,d0
	bsr	.tb
	lea	(rd_tcb).l,a1
	lea	(rd_shA).l,a0
	lea	(rd_chgA).l,a2
	move.w	(rd_nchgA).l,d3
	move.w	d6,d4
	mulu.w	d7,d4
	bsr	.scan
	move.w	d3,(rd_nchgA).l
	cmpi.w	#2,d5
	beq.s	.x
	lea	(rd_shW).l,a0
	lea	(rd_chgW).l,a2
	move.w	(rd_nchgW).l,d3
	move.w	(rd_wwidth).l,d4
	lsl.w	#5,d4
	bsr	.scan
	move.w	d3,(rd_nchgW).l
.x	moveq	#0,d0
.tb
	movem.l	d1-d4/a0-a2,-(sp)
	move.w	(rd_tcn).l,d4
	subq.w	#1,d4
	lea	(rd_tcl).l,a2
	lea	(rd_tcb).l,a1
.tl	moveq	#0,d1
	move.w	(a2)+,d1
	lea	(tc_chg).l,a0
	move.l	(a0,d1.w),d2
	lea	(rd_aused).l,a0
	and.l	(a0,d1.w),d2
	lsl.l	#3,d1
.tt	tst.l	d2
	beq.s	.tn
	bfffo	d2{0:0},d3
	bfclr	d2{d3:1}
	add.l	d1,d3
	move.b	d0,(a1,d3.l)
	sub.l	d1,d3
	bra.s	.tt
.tn	dbf	d4,.tl
	movem.l	(sp)+,d1-d4/a0-a2
	rts
.scan
	moveq	#0,d2
	subq.w	#1,d4
.s	move.w	(a0)+,d0
	andi.w	#$7FF,d0
	tst.b	(a1,d0.w)
	beq.s	.n
	move.w	d2,d1
	lsr.w	#1,d1
	tst.w	d3
	beq.s	.l
	cmp.w	-2(a2,d3.w*2),d1
	beq.s	.n
.l	cmpi.w	#CHGMAX,d3
	bhs.s	.full
	move.w	d1,(a2,d3.w*2)
	addq.w	#1,d3
	moveq	#1,d5
.n	addq.w	#1,d2
	dbf	d4,.s
	rts
.full	moveq	#2,d5
	rts

rd_buildA
	lea	(rd_akeynew).l,a3
	moveq	#0,d0
	move.b	(rd_lwin).l,d0
	clr.w	(rd_wy0).l
	move.w	d0,(rd_wy1).l
	clr.w	(rd_wx0).l
	clr.w	(rd_wx1).l
	move.w	d0,(a3)+
	move.l	(rd_lntw).l,d0
	moveq	#32,d6
	tst.b	(rd_lwide).l
	beq.s	.wb
	moveq	#64,d6
.wb	move.w	d6,(rd_wwidth).l
	move.l	d0,(rd_wbase).l
	move.l	d0,(a3)+
	move.l	(rd_lnta).l,d0
	tst.b	(rd_narrow).l
	beq.s	.nar
	move.l	#rd_vntA,d0
	sub.l	#vm_data,d0
.nar	move.l	d0,(rd_abase).l
	move.l	d0,(a3)+
	move.w	(rd_cw).l,d6
	move.w	(rd_ch).l,d7
	move.w	(rd_hs).l,d0
	neg.w	d0
	move.w	d6,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	d0,(rd_ax0).l
	move.w	d0,(a3)+
	move.w	(rd_vs).l,d0
	move.w	d7,d1
	lsl.w	#3,d1
	subq.w	#1,d1
	and.w	d1,d0
	move.w	d0,(rd_ay0).l
	move.w	d0,(a3)+
	move.w	d6,(a3)+
	move.w	d7,(a3)+
	move.w	(rd_cells).l,(a3)+
	lea	(rd_akeynew).l,a0
	lea	(rd_akey).l,a1
	moveq	#0,d5
	moveq	#5,d0
.k	cmpm.l	(a0)+,(a1)+
	beq	.k1
	moveq	#2,d5
.k1	dbf	d0,.k
	clr.w	(rd_nchgA).l
	clr.w	(rd_nchgW).l
	sf	(rd_wchg).l
	movem.l	d2-d4,-(sp)
	move.l	(rd_abase).l,d0
	move.w	d6,d1
	mulu.w	d7,d1
	add.l	d1,d1
	bsr	rd_ntwritten
	movem.l	(sp)+,d2-d4
	move.b	d0,(rd_ntcur).l
	beq	.caw
	move.b	#2,(rd_nttab).l
	lea	(vm_data).l,a0
	adda.l	(rd_abase).l,a0
	lea	(rd_shA).l,a1
	lea	(rd_chgA).l,a2
	move.w	d6,d4
	mulu.w	d7,d4
	lsr.w	#1,d4
	subq.w	#1,d4
	moveq	#0,d3
	bsr	.cmpd
	move.w	d3,(rd_nchgA).l
.caw	movem.l	d2-d4,-(sp)
	move.l	(rd_wbase).l,d0
	moveq	#0,d1
	move.w	(rd_wwidth).l,d1
	lsl.l	#6,d1
	bsr	rd_ntwritten
	movem.l	(sp)+,d2-d4
	move.b	d0,(rd_ntcur).l
	beq	.cww
	move.b	#3,(rd_nttab).l
	lea	(vm_data).l,a0
	adda.l	(rd_wbase).l,a0
	lea	(rd_shW).l,a1
	lea	(rd_chgW).l,a2
	move.w	(rd_wwidth).l,d4
	lsl.w	#4,d4
	subq.w	#1,d4
	moveq	#0,d3
	bsr	.cmpd
	move.w	d3,(rd_nchgW).l
.cww	st	(rd_ntsync).l
	cmpi.w	#2,d5
	beq.s	.tun
	move.w	(rd_tcn).l,d0
	beq.s	.tun
	subq.w	#1,d0
	lea	(rd_tcl).l,a2
	lea	(tc_chg).l,a0
	lea	(rd_aused).l,a1
.tu	move.w	(a2)+,d1
	move.l	(a0,d1.w),d2
	and.l	(a1,d1.w),d2
	dbne	d0,.tu
	beq.s	.tun
	bsr	rd_ovl_tilecells
.tun	tst.w	d5
	beq	.keep
	cmpi.w	#1,d5
	bne	.full
	move.w	(rd_nchgA).l,d0
	add.w	(rd_nchgW).l,d0
	add.w	d0,d0
	cmp.w	(rd_alistn).l,d0
	bhi	.full
	move.w	(rd_ax0).l,d0
	or.w	(rd_ay0).l,d0
	andi.w	#7,d0
	bne	.full
	bsr	rd_ovl_cells_changed
	bra	.keep
.cmpd
	tst.b	(rd_ntfull).l
	bne.s	.cmp
	move.l	a0,(rd_tmp+16).l
	move.l	a1,(rd_tmp+20).l
	move.l	d7,-(sp)
	move.w	d4,d7
	bsr	rd_ntblocks
	move.l	(sp)+,d7
.cdb	bsr	rd_ntnext
	bcs.s	.cdx
	movea.l	(rd_tmp+16).l,a0
	adda.l	d0,a0
	movea.l	(rd_tmp+20).l,a1
	adda.l	d0,a1
	moveq	#7,d4
	bsr.s	.cs
	bra.s	.cdb
.cdx	rts
.cmp
	move.l	a0,(rd_tmp+16).l
.cs	cmpm.l	(a0)+,(a1)+
	dbne	d4,.cs
	beq.s	.cx
	move.l	-4(a0),-4(a1)
	move.l	a0,d2
	sub.l	(rd_tmp+16).l,d2
	lsr.l	#2,d2
	subq.w	#1,d2
	bsr.s	.note
	dbf	d4,.cs
.cx	rts
.note
	cmpi.b	#3,(rd_nttab).l
	bne.s	.nwc
	st	(rd_wchg).l
.nwc
	moveq	#1,d1
	cmpi.w	#2,d5
	beq.s	.n2
	cmpi.w	#CHGMAX,d3
	bhs.s	.nfull
	move.w	d2,(a2,d3.w*2)
	addq.w	#1,d3
	move.w	d1,d5
.n2	rts
.nfull	moveq	#2,d5
	rts
.full
	clr.l	(rd_ovlpart).l
	tst.b	(rd_wchg).l
	bne	.fa
	lea	(rd_akeynew).l,a0
	lea	(rd_akey).l,a1
	move.l	(a0),d0
	cmp.l	(a1),d0
	bne	.fa
	move.l	4(a0),d0
	cmp.l	4(a1),d0
	bne	.fa
	move.w	8(a0),d0
	cmp.w	8(a1),d0
	bne	.fa
	move.l	14(a0),d0
	cmp.l	14(a1),d0
	bne	.fa
	move.w	18(a0),d0
	cmp.w	18(a1),d0
	bne	.fa
	move.w	(rd_tcn).l,d0
	beq.s	.pt
	subq.w	#1,d0
	lea	(rd_tcl).l,a2
	lea	(tc_chg).l,a0
	lea	(rd_aused).l,a1
.ptl	move.w	(a2)+,d1
	move.l	(a0,d1.w),d2
	and.l	(a1,d1.w),d2
	dbne	d0,.ptl
	bne	.fa
.pt	move.w	(rd_wy0).l,d0
	move.w	(rd_wy1).l,d1
	cmp.w	d1,d0
	bge	.fa
	moveq	#-1,d2
	tst.w	d0
	bne.s	.pb
	subq.w	#1,d1
	ble	.fa
.pk	bclr	d1,d2
	subq.w	#1,d1
	bpl.s	.pk
	bra.s	.pp
.pb	cmpi.w	#28,d1
	bne	.fa
	addq.w	#2,d0
	cmpi.w	#31,d0
	bhi	.fa
.pc	bclr	d0,d2
	addq.w	#1,d0
	cmpi.w	#32,d0
	blo.s	.pc
.pp	move.l	d2,(rd_ovlpart).l
.fa
	lea	(vm_data).l,a0
	adda.l	(rd_abase).l,a0
	lea	(rd_shA).l,a1
	move.w	d6,d0
	mulu.w	d7,d0
	lsr.w	#1,d0
	subq.w	#1,d0
.cpa	move.l	(a0)+,(a1)+
	dbf	d0,.cpa
	lea	(vm_data).l,a0
	adda.l	(rd_wbase).l,a0
	lea	(rd_shW).l,a1
	move.w	(rd_wwidth).l,d0
	lsl.w	#4,d0
	subq.w	#1,d0
.cpw	move.l	(a0)+,(a1)+
	dbf	d0,.cpw
	lea	(rd_akeynew).l,a0
	lea	(rd_akey).l,a1
	moveq	#5,d0
.kc	move.l	(a0)+,(a1)+
	dbf	d0,.kc
	tst.l	(rd_ovlpart).l
	beq.s	.fl
	lea	(rd_alist).l,a2
	move.w	(rd_alistw).l,d0
	mulu.w	#6,d0
	adda.l	d0,a2
	lea	(rd_aused).l,a3
	bra.s	.acells
.fl	lea	(rd_aused).l,a0
	moveq	#63,d0
.uc	clr.l	(a0)+
	dbf	d0,.uc
	lea	(rd_alist).l,a2
	lea	(rd_aused).l,a3
	lea	(vm_data).l,a4
	adda.l	(rd_wbase).l,a4
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
	move.l	a2,d0
	sub.l	#rd_alist,d0
	divu.w	#6,d0
	move.w	d0,(rd_alistw).l
.acells
	lea	(vm_data).l,a4
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

;	Note tile of entry d0 as used; list the cell (d1 x, d2 y)
;	unless the tile is empty or the cell is off screen. Keeps d0-d7.
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
.yes	moveq	#1,d0
	rts
.no	cmp.w	d0,d0
	rts

;	Sprites of priority rd_pass, last in the list first.
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
	lea	(rd_sprgend).l,a0
	moveq	#0,d1
	move.b	(a0,d5.w),d1
	beq.s	.one
	lea	(rd_sprgkey).l,a0
	move.w	(a0,d5.w*2),d2
	movem.l	d1/d5/a4,-(sp)
	bsr	rd_obj_blit
	movem.l	(sp)+,d1/d5/a4
	bne.s	.one
	subq.w	#1,d1
	sub.w	d1,d5
	lsl.w	#3,d1
	suba.w	d1,a4
	bra.s	.n
.one	movem.l	d5/a4,-(sp)
	bsr	rd_sprite_blit
	movem.l	(sp)+,d5/a4
.n	dbf	d5,.each
.x	bra	rd_cq_flush

;	Sprite a4.
rd_sprite_blit
	move.w	(a4),d0
	andi.w	#$3FF,d0
	subi.w	#128,d0
	move.w	d0,(rd_sy).l
	move.b	2(a4),d1
	moveq	#3,d2
	and.w	d1,d2
	addq.w	#1,d2
	move.w	d2,(rd_sch).l
	lsr.b	#2,d1
	andi.w	#3,d1
	addq.w	#1,d1
	move.w	d1,(rd_scw).l
	move.w	6(a4),d3
	andi.w	#$1FF,d3
	subi.w	#128,d3
	move.w	d3,(rd_sx).l
	move.w	4(a4),(rd_sat).l
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
	bsr	rd_spr_geom
	tst.w	(rd_c0).l
	beq.s	.cache
	tst.b	(rd_stage).l
	beq.s	.nl
	bsr	rd_op_fallback
.nl	move.w	(rd_sx).l,d0
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
	move.w	d0,(rd_sslot).l
	bsr	rd_sc_get
	bra	rd_spr_cut
.x	rts

;	The sprite rd_sx, rd_sy, rd_scw, rd_sch, rd_sat on the screen: the columns
;	drawn, rd_wb, its rows on the screen (rd_r0, rd_r1), its palette (rd_spal).
rd_spr_geom
	moveq	#0,d6
	move.w	(rd_sx).l,d0
.lclip	cmpi.w	#-SCRX*8,d0
	bge	.lok
	addq.w	#8,d0
	addq.w	#1,d6
	bra	.lclip
.lok	move.w	d0,(rd_colx).l
	move.w	d6,(rd_c0).l
	move.w	(rd_scw).l,d0
	sub.w	d6,d0
	move.w	d0,(rd_ncol).l
	addq.w	#1,d0
	lsr.w	#1,d0
	add.w	d0,d0
	move.w	d0,(rd_wb).l
	move.w	(rd_sy).l,d0
	moveq	#0,d1
	tst.w	d0
	bpl	.t
	move.w	d0,d1
	neg.w	d1
.t	move.w	(rd_sch).l,d2
	lsl.w	#3,d2
	move.w	#SCRH,d3
	sub.w	d0,d3
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

;	The image a2, mask a3 (rd_bl0.. rd_bp1 its box) of the sprite
;	rd_spr_geom placed, cut into the back buffer: one blit, queued.
rd_spr_cut
	move.w	(rd_bl0).l,d6
	move.w	d6,d5
	add.w	(rd_bnl).l,d5
	cmp.w	(rd_r0).l,d6
	bge.s	.r0
	move.w	(rd_r0).l,d6
.r0	cmp.w	(rd_r1).l,d5
	ble.s	.r1
	move.w	(rd_r1).l,d5
.r1	sub.w	d6,d5
	ble	.x
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
	tst.l	(rd_omcap).l
	beq.s	.cv
	movea.l	(rd_omcap).l,a0
	movem.w	d0-d3,OMCOV(a0)
	bset	#1,OMFLG+1(a0)
.cv	movem.l	d0-d3,-(sp)
	bsr	rd_cover_u
	movem.l	(sp)+,d0-d3
.mk	bsr	rd_mark_u
	move.w	(rd_colx).l,d0
	add.w	(rd_xorg).l,d0
	moveq	#15,d1
	and.w	d0,d1
	move.w	(rd_bp0).l,d2
	lsr.w	#4,d2
	move.w	(rd_bp1).l,d3
	add.w	d1,d3
	lsr.w	#4,d3
	sub.w	d2,d3
	addq.w	#1,d3
	move.w	(rd_wb).l,d4
	move.w	d6,d7
	cmpi.w	#4,d4
	bhi.s	.wm
	add.w	d7,d7
	add.w	d6,d7
	lsl.w	#2,d7
	cmpi.w	#2,d4
	beq.s	.wl
	add.w	d7,d7
	bra.s	.wl
.wm	mulu.w	d4,d7
	mulu.w	#6,d7
.wl	adda.w	d7,a2
	adda.w	d7,a3
	lea	(a2,d2.w*2),a2
	lea	(a3,d2.w*2),a3
	lsr.w	#4,d0
	add.w	d2,d0
	add.w	d0,d0
	movea.l	(rd_back).l,a0
	move.w	(rd_sy).l,d7
	add.w	d6,d7
	lea	(rd_rowoff).l,a1
	adda.l	(a1,d7.w*4),a0
	adda.w	d0,a0
	movea.l	a2,a1
	movea.l	a3,a2
	add.w	d3,d3
	add.w	d2,d2
	add.w	d3,d2
	ror.w	#4,d1
	move.w	d1,d7
	moveq	#-1,d1
	cmp.w	d4,d2
	bls.s	.lw
	moveq	#0,d1
.lw	move.w	d4,d0
	sub.w	d3,d0
	move.w	d5,d2
	add.w	d2,d2
	add.w	d5,d2
	add.w	d2,d2
	move.w	d1,d5
	move.w	d7,d4
	moveq	#SBPR,d1
	sub.w	d3,d1
	lsr.w	#1,d3
	move.l	(rd_imgpos).l,d6
	bra	rd_cut_emit
.x	rts

;	Unchanged areas kept (scroll mode).
OPMAX		equ	256
OPREC		equ	32

;	The bucket (\2, 0 to OPHASH - 1) of the listed blit
;	\1 by its C/D pointer; \3 a data register to use.
OPHASHF	MACRO
	move.l	(\1),\2
	move.l	\2,\3
	lsr.l	#6,\3
	eor.w	\3,\2
	andi.w	#OPHASH-1,\2
	ENDM

;	Begin the frame's list. Uses nothing.
rd_op_begin
	st	(rd_stage).l
	clr.w	(rd_opn).l
	move.l	#$FF000000,(rd_opbox).l
	rts

;	The buffer's list a3, d6 blits (-1: none), as rd_op_end finds it. Uses d0.
rd_op_old
	move.l	a0,-(sp)
	move.w	(rd_bufi).l,d0
	lea	(rd_opold).l,a0
	movea.l	(a0,d0.w*4),a3
	lea	(rd_opoldn).l,a0
	move.w	(a0,d0.w*2),d6
	movea.l	(sp)+,a0
	rts

;	Every buffer's list unknown (what is in the buffers was drawn some other way). Keeps all.
rd_op_invall
	move.l	#-1,(rd_opoldn).l
	move.w	#-1,(rd_opoldn+4).l
	rts

;	The box (a1: row, rows - 1, column, columns; row $FF: none) set in the map a2. Uses d0-d3, a0.
rd_box_set
	moveq	#0,d1
	move.b	(a1),d1
	cmpi.b	#$FF,d1
	beq.s	.x
	moveq	#0,d3
	move.b	1(a1),d3
	moveq	#0,d0
	move.b	2(a1),d0
	moveq	#0,d2
	move.b	3(a1),d2
	lea	(a2,d1.w*4),a0
	moveq	#0,d1
	bfset	d1{d0:d2}
.r	or.l	d1,(a0)+
	dbf	d3,.r
.x	rts

;	A cut blit: A a mask, B an image, C = D the screen, D = AB + /AC; A and B shifted by d4, d5 the
;	last word's A mask, d0 A and B's modulo, d1 C and D's, d2 BLTSIZV. Uses d0-d7, a0-a2, a5-a6.
rd_cut_emit
	tst.l	(rd_omcap).l
	beq.s	.nc
	move.l	a6,-(sp)
	movea.l	(rd_omcap).l,a6
	clr.l	(rd_omcap).l
	bset	#0,OMFLG+1(a6)
	lea	OMREC(a6),a6
	move.l	a0,d7
	sub.l	(rd_back).l,d7
	move.l	d7,(a6)+
	move.l	a1,(a6)+
	move.l	a2,(a6)+
	move.w	d0,(a6)+
	move.w	d1,(a6)+
	move.w	d2,(a6)+
	move.w	d3,(a6)+
	move.w	d4,(a6)+
	move.w	d5,(a6)+
	move.l	d6,(a6)+
	move.l	(rd_opbox).l,(a6)
	movea.l	(sp)+,a6
.nc	tst.b	(rd_stage).l
	beq	rd_cut_blit
	move.w	(rd_opn).l,d7
	cmpi.w	#OPMAX,d7
	bhs.s	.full
	movea.l	(rd_opnew).l,a6
	lsl.w	#5,d7
	adda.w	d7,a6
	move.l	a0,(a6)+
	move.l	a1,(a6)+
	move.l	a2,(a6)+
	move.w	d0,(a6)+
	move.w	d1,(a6)+
	move.w	d2,(a6)+
	move.w	d3,(a6)+
	move.w	d4,(a6)+
	move.w	d5,(a6)+
	move.l	d6,(a6)+
	move.l	(rd_opbox).l,(a6)
	addq.w	#1,(rd_opn).l
	rts
.full	bsr	rd_op_fallback
	movem.l	d0-d3/a0-a2,-(sp)
	lea	(rd_opbox).l,a1
	movea.l	(rd_dmap).l,a2
	bsr	rd_box_set
	movem.l	(sp)+,d0-d3/a0-a2
;	The blit of rd_cut_emit to the copper. Uses d0-d1/d7, a0, a5-a6.
rd_cut_blit
	bsr	rd_cq_blit
	tst.w	d4
	bne.s	.sh
	cmpi.w	#-1,d5
	bne.s	.sh
	cmpi.b	#2,(rd_cqkind).l
	beq.s	.k
	move.l	#$00400FCA,(a5)+
	move.l	#$00420000,(a5)+
	move.l	#$0044FFFF,(a5)+
	move.l	#$0046FFFF,(a5)+
	move.b	#2,(rd_cqkind).l
	bra.s	.k
.sh	sf	(rd_cqkind).l
	move.l	#$00420000,d7
	move.w	d4,d7
	move.l	d7,(a5)+
	ori.w	#$0FCA,d7
	eori.l	#($042^$040)<<16,d7
	move.l	d7,(a5)+
	move.l	#$0044FFFF,(a5)+
	move.l	#$00460000,d7
	move.w	d5,d7
	move.l	d7,(a5)+
	move.l	#$00740000,(a5)+
.k	CQA	$050,a2,d7
	CQA	$04C,a1,d7
	CQA	$048,a0,d7
	CQA	$054,a0,d7
	CQV	$064,d0,d7
	CQV	$062,d0,d7
	CQV	$060,d1,d7
	CQV	$066,d1,d7
	CQV	$05C,d2,d7
	CQV	$05E,d3,d7
	bra	rd_cq_endblit

;	The listed blit a1 to the copper. Uses d0-d7, a0-a2, a5-a6.
rd_op_blit
	movem.w	12(a1),d0-d5
	movem.l	(a1),a0-a2
	bra	rd_cut_blit

;	The listing ends half way: what the buffer's last frame drew restored with the dirty map,
;	the blits listed so far drawn, and the rest of the frame drawn as it comes. Keeps all.
rd_op_fallback
	movem.l	d0-d7/a0-a6,-(sp)
	sf	(rd_stage).l
	bsr	rd_op_old
	movea.l	(rd_dmap).l,a2
	movea.l	a3,a1
	lea	OPREC-4(a1),a1
	tst.w	d6
	bgt.s	.oe
	moveq	#0,d6
	bra.s	.oe
.o	bsr	rd_box_set
	lea	OPREC(a1),a1
.oe	dbf	d6,.o
	bsr	rd_restore
	movea.l	(rd_opnew).l,a4
	move.w	(rd_opn).l,d7
	bra.s	.ne
.n	lea	OPREC-4(a4),a1
	movea.l	(rd_dmap).l,a2
	bsr	rd_box_set
	movea.l	a4,a1
	move.l	d7,-(sp)
	bsr	rd_op_blit
	move.l	(sp)+,d7
	lea	OPREC(a4),a4
.ne	dbf	d7,.n
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	The frame listed (rd_op_begin): restored, and its blits drawn where they have to be (above).
OPHASH	equ	64
rd_op_end
	tst.b	(rd_stage).l
	bne.s	.go
	move.w	(rd_bufi).l,d0
	lea	(rd_opoldn).l,a0
	move.w	#-1,(a0,d0.w*2)
	rts
.go	sf	(rd_stage).l
	bsr	rd_op_old
	movea.l	(rd_opnew).l,a4
	move.w	(rd_opn).l,d7
	moveq	#0,d4
	tst.w	d6
	ble	.r
	lea	(rd_ophb+OPHASH*2).l,a0
	moveq	#-1,d0
	moveq	#-1,d1
	moveq	#-1,d2
	moveq	#-1,d3
	moveq	#OPHASH/8-1,d5
.hc	movem.l	d0-d3,-(a0)
	dbf	d5,.hc
	lea	(rd_ophn).l,a1
	move.w	d6,d5
	subq.w	#1,d5
	move.w	d5,d0
	lsl.w	#5,d0
	lea	(a3,d0.w),a2
.hi	OPHASHF	a2,d0,d1
	move.w	(a0,d0.w*2),(a1,d5.w*2)
	move.w	d5,(a0,d0.w*2)
	lea	-OPREC(a2),a2
	dbf	d5,.hi
	moveq	#0,d5
	lea	(rd_opkeep).l,a6
	movea.l	a4,a5
	move.w	d7,d3
	bra	.me
.m	sf	(a6)
	OPHASHF	a5,d0,d1
	move.w	(a0,d0.w*2),d1
	bra.s	.mf
.mx	move.w	(a1,d1.w*2),d1
.mf	bmi	.mn
	cmp.w	d5,d1
	blt.s	.mx
	move.w	d1,d0
	lsl.w	#5,d0
	lea	(a3,d0.w),a2
	move.l	(a5),d0
	cmp.l	(a2),d0
	bne.s	.mx
	move.l	4(a5),d0
	cmp.l	4(a2),d0
	bne.s	.mx
	move.l	8(a5),d0
	cmp.l	8(a2),d0
	bne.s	.mx
	move.l	12(a5),d0
	cmp.l	12(a2),d0
	bne.s	.mx
	move.l	16(a5),d0
	cmp.l	16(a2),d0
	bne.s	.mx
	move.l	20(a5),d0
	cmp.l	20(a2),d0
	bne.s	.mx
	move.l	24(a5),d0
	cmp.l	24(a2),d0
	bne.s	.mx
	st	(a6)
	addq.w	#1,d4
	move.w	d7,(rd_oplk).l
	sub.w	d3,(rd_oplk).l
	move.b	#$FF,OPREC-4(a2)
	move.w	d1,d5
	addq.w	#1,d5
.mn	addq.l	#1,a6
	lea	OPREC(a5),a5
.me	dbf	d3,.m
	movea.l	(rd_dmap).l,a2
	lea	OPREC-4(a3),a1
	move.w	d6,d5
	bra.s	.re
.rm	bsr	rd_box_set
	lea	OPREC(a1),a1
.re	dbf	d5,.rm
.r	movem.l	d4/d7/a4,-(sp)
	tst.w	d4
	beq.s	.nw
	lea	(rd_wmap+DROWS*4).l,a0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#DROWS/4-1,d5
.cw	movem.l	d0-d3,-(a0)
	dbf	d5,.cw
.nw	bsr	rd_restore
	movem.l	(sp)+,d4/d7/a4
	tst.w	d4
	bne.s	.w
	bra.s	.ae
.a
	movem.l	d7/a4,-(sp)
	movea.l	a4,a1
	bsr	rd_op_blit
	movem.l	(sp)+,d7/a4
	lea	OPREC(a4),a4
.ae	dbf	d7,.a
	bra	.done
.w	lea	(rd_opkeep).l,a3
	sub.w	(rd_oplk).l,d7
	move.w	(rd_oplk).l,d6
	bra.s	.ee
.e	moveq	#0,d1
	move.b	OPREC-4(a4),d1
	moveq	#0,d3
	move.b	OPREC-3(a4),d3
	moveq	#0,d0
	move.b	OPREC-2(a4),d0
	moveq	#0,d2
	move.b	OPREC-1(a4),d2
	moveq	#0,d5
	bfset	d5{d0:d2}
	lea	(rd_wmap).l,a0
	lea	(a0,d1.w*4),a0
	tst.b	(a3)+
	beq.s	.ed
	cmpi.b	#$FF,d1
	beq.s	.en
	movea.l	a0,a1
	move.w	d3,d4
.et	move.l	(a1)+,d0
	and.l	d5,d0
	bne.s	.es
	dbf	d4,.et
	bra.s	.en
.ed	cmpi.b	#$FF,d1
	beq.s	.eb
.es	or.l	d5,(a0)+
	dbf	d3,.es
.eb
	movem.l	d6-d7/a3-a4,-(sp)
	movea.l	a4,a1
	bsr	rd_op_blit
	movem.l	(sp)+,d6-d7/a3-a4
.en	lea	OPREC(a4),a4
.ee	dbf	d6,.e
	bra	.ae
.done	bsr	rd_cq_flush
	move.w	(rd_bufi).l,d0
	lea	(rd_opold).l,a0
	move.l	(a0,d0.w*4),d1
	move.l	(rd_opnew).l,(a0,d0.w*4)
	move.l	d1,(rd_opnew).l
	lea	(rd_opoldn).l,a0
	move.w	(rd_opn).l,(a0,d0.w*2)
	rts

;	(staging) The box of a plane B fixup: map column d0, d1 words, buffer line d2, 8 lines. Keeps all.
rd_fix_box
	movem.l	d2-d3,-(sp)
	move.w	d2,d3
	addq.w	#7,d3
	asr.w	#DLS,d2
	bpl.s	.1
	moveq	#0,d2
.1	asr.w	#DLS,d3
	cmpi.w	#DROWS-1,d3
	ble.s	.2
	moveq	#DROWS-1,d3
.2	sub.w	d2,d3
	bmi.s	.e
	move.b	d2,(rd_opbox).l
	move.b	d3,(rd_opbox+1).l
	move.b	d0,(rd_opbox+2).l
	move.b	d1,(rd_opbox+3).l
	movem.l	(sp)+,d2-d3
	rts
.e	move.b	#$FF,(rd_opbox).l
	movem.l	(sp)+,d2-d3
	rts

;	Sprite image cache.

;	a2 = the image, a3 = the mask of the sprite rd_sat, rd_scw, rd_sch (rd_wb set). Uses d0-d3, d7, a1.
rd_sc_get
	moveq	#0,d0
	move.w	(rd_sat).l,d0
	andi.w	#$7FFF,d0
	move.w	(rd_scw).l,d1
	subq.w	#1,d1
	lsl.w	#2,d1
	add.w	(rd_sch).l,d1
	subq.w	#1,d1
	swap	d1
	clr.w	d1
	or.l	d1,d0
	move.l	d0,(rd_skey).l
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
	andi.w	#$7FF,d1
	move.w	(rd_scw).l,d2
	mulu.w	(rd_sch).l,d2
	move.w	d1,d3
	add.w	d2,d3
	cmpi.w	#2048,d3
	bhi	.nomemo
	bftst	(tc_chg).l{d1:d2}
	bne	.nomemo
	move.l	(rd_scpos).l,d1
	sub.l	12(a1),d1
	cmp.l	(rd_scsize).l,d1
	bhi	.nomemo
	movea.l	8(a1),a2
	move.l	24(a1),d7
	lea	(a2,d7.l),a3
	move.l	16(a1),(rd_bl0).l
	move.l	20(a1),(rd_bp0).l
	move.l	(rd_count).l,4(a1)
	move.l	12(a1),d1
	move.l	d1,(rd_imgpos).l
	cmp.l	(rd_scmin).l,d1
	bge	.xm
	move.l	d1,(rd_scmin).l
.xm	rts
.nomemo
	movem.l	d4-d6/a0/a4,-(sp)
	moveq	#0,d5
	move.w	d0,d1
	andi.w	#$7FF,d1
	lea	(vm_tsrc).l,a0
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
	andi.l	#$000F7800,d5
	addq.l	#1,d5
	move.l	d3,d0
.tkey	move.l	d0,d2
	eor.l	d5,d2
	mulu.l	#$9E3779B1,d2
	swap	d2
	andi.l	#SCSLOTS-1,d2
	lsl.l	#5,d2
	lea	(rd_sctab).l,a4
	move.w	(rd_wb).l,d7
	mulu.w	(rd_sch).l,d7
	mulu.w	#NPLANES*8,d7
	cmp.l	(a4,d2.l),d0
	bne.s	.w2
	cmp.l	24(a4,d2.l),d5
	beq.s	.kf
.w2	eori.w	#32,d2
	cmp.l	(a4,d2.l),d0
	bne.s	.wv
	cmp.l	24(a4,d2.l),d5
	beq.s	.kf
.wv	move.l	4(a4,d2.l),d1
	eori.w	#32,d2
	cmp.l	4(a4,d2.l),d1
	bhs.s	.wo
	eori.w	#32,d2
.wo	adda.l	d2,a4
	bra.s	.bkey
.kf	adda.l	d2,a4
	move.l	(rd_scpos).l,d1
	sub.l	4(a4),d1
	cmp.l	(rd_scsize).l,d1
	bhi.s	.bring
	tst.l	d5
	bne.s	.found
	move.l	8(a4),d3
	moveq	#0,d1
	move.w	d0,d1
	move.w	(rd_scw).l,d2
	mulu.w	(rd_sch).l,d2
	subq.w	#1,d2
	lea	(rd_tchg).l,a0
.tc	andi.w	#$7FF,d1
	cmp.l	(a0,d1.w*4),d3
	blo.s	.btile
	addq.w	#1,d1
	dbf	d2,.tc
.found	movea.l	12(a4),a2
	bra	.mask
.bkey
	bra.s	.build
.bring
	bra.s	.build
.btile
.build	move.l	d7,d1
	add.l	d1,d1
	bsr	rd_sc_alloc
	move.l	d0,(a4)
	move.l	d5,24(a4)
	move.l	d2,4(a4)
	move.l	(rd_count).l,8(a4)
	move.l	a2,12(a4)
	lea	(a2,d7.l),a3
	move.l	(rd_r0).l,-(sp)
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
	move.l	16(a4),(rd_bl0).l
	move.l	20(a4),(rd_bp0).l
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
	move.l	4(a4),d1
	move.l	d1,(rd_imgpos).l
	cmp.l	(rd_scmin).l,d1
	bge.s	.x
	move.l	d1,(rd_scmin).l
.x	movem.l	(sp)+,d4-d6/a0/a4
	rts

;	Room in the sprite image ring for d1 bytes: d2 = its place (the
;	bytes written to the ring before it), a2 = its address. Uses d3, d4.
rd_sc_alloc
	move.l	(rd_scpos).l,d2
	move.l	(rd_scoff).l,d3
	move.l	d3,d4
	add.l	d1,d4
	cmp.l	(rd_scs0).l,d3
	bhs.s	.p2
	cmp.l	(rd_scs0).l,d4
	bls.s	.fit
	move.l	(rd_scs0).l,d4
	bra.s	.skip
.p2	cmp.l	(rd_scsize).l,d4
	bls.s	.fit
	move.l	(rd_scsize).l,d4
.skip	sub.l	d3,d4
	add.l	d4,d2
	add.l	d4,d3
	cmp.l	(rd_scsize).l,d3
	blo.s	.fit
	moveq	#0,d3
.fit	move.l	d3,-(sp)
	move.l	d2,d3
	add.l	d1,d3
	sub.l	(rd_scsize).l,d3
	move.l	(rd_scmin).l,d4
	cmp.l	(rd_scmin+4).l,d4
	ble.s	.m
	move.l	(rd_scmin+4).l,d4
.m	cmp.l	d3,d4
	bge.s	.free
	tst.b	(rd_stage).l
	beq.s	.nl
	bsr	rd_op_fallback
.nl	bsr	rd_waitblit
	move.l	#$7FFFFFFF,(rd_scmin).l
	move.l	#$7FFFFFFF,(rd_scmin+4).l
.free	move.l	(sp)+,d3
	cmp.l	(rd_scs0).l,d3
	bhs.s	.a2
	lea	(rd_scarena).l,a2
	adda.l	d3,a2
	bra.s	.a
.a2	movea.l	(rd_scx).l,a2
	suba.l	(rd_scs0).l,a2
	adda.l	d3,a2
.a	add.l	d1,d3
	move.l	d3,(rd_scoff).l
	move.l	d2,d3
	add.l	d1,d3
	move.l	d3,(rd_scpos).l
	rts

;	The pictures of the EA Sports, title and game setup
;	screens are kept deflated: when a screen begins. Keeps all.
FEWIN	equ	rd_scarena+SCARENA-FEWSIZE
fe_open_ea
	move.l	d0,-(sp)
	moveq	#1,d0
	bra.s	fe_open
fe_open_title
	move.l	d0,-(sp)
	moveq	#2,d0
	bra.s	fe_open
fe_open_setup
	move.l	d0,-(sp)
	moveq	#3,d0
fe_open
	btst	d0,(fe_cur).l
	bne.s	.x
	movem.l	d1/a0-a1,-(sp)
	tst.b	(fe_held).l
	bne.s	.h
	move.l	#SCARENA-FEWSIZE,d1
	bsr	fe_ring
	st	(fe_held).l
.h	cmpi.w	#1,d0
	bne.s	.one
	moveq	#FESCREENS,d0
.all	bsr.s	.inf
	subq.w	#1,d0
	bne.s	.all
	bra.s	.d
.one	bsr.s	.inf
.d	movem.l	(sp)+,d1/a0-a1
.x	move.l	(sp)+,d0
	rts
.inf	bset	d0,(fe_cur).l
	bne.s	.r
	lea	(fe_table-8).l,a0
	lea	(a0,d0.w*8),a0
	movea.l	(a0)+,a1
	exg	a0,a1
	movea.l	(a1),a1
	adda.l	#FEWIN,a1
	bsr	inflate
.r	rts
fe_close
	tst.b	(fe_held).l
	beq.s	.x
	move.l	d1,-(sp)
	move.l	#SCARENA,d1
	bsr	fe_ring
	sf	(fe_held).l
	sf	(fe_cur).l
	move.l	(sp)+,d1
.x	rts
;	The ring's first part d1 bytes. Keeps all.
fe_ring
	movem.l	d0/a0,-(sp)
	move	sr,-(sp)
.w	tst.b	(rd_busy).l
	beq.s	.nb
	move	(sp),d0
	andi.w	#$0700,d0
	cmpi.w	#$0600,d0
	blo.s	.i
	move	#$2500,sr
.i	jsr	(hal_yield).l
	move	(sp),sr
	bra.s	.w
.nb	move	(sp),d0
	andi.w	#$0700,d0
	cmpi.w	#$0300,d0
	blo.s	.wb
	cmpi.w	#$0600,d0
	blo.s	.lo
	move.w	#$2000,(CUSTOM+INTENA).l
.lo	andi	#$F8FF,sr
.wb	bsr	rd_waitblit
	move	(sp),sr
	move	(sp),d0
	andi.w	#$0700,d0
	cmpi.w	#$0600,d0
	blo.s	.rg
	move.w	#$A000,(CUSTOM+INTENA).l
.rg	move.l	(rd_scsize).l,d0
	add.l	d0,d0
	add.l	d0,(rd_scpos).l
	clr.l	(rd_scoff).l
	move.l	d1,(rd_scs0).l
	move.l	d1,d0
	add.l	(rd_scxsz).l,d0
	move.l	d0,(rd_scsize).l
	move.l	#$7FFFFFFF,(rd_scmin).l
	move.l	#$7FFFFFFF,(rd_scmin+4).l
	move	(sp)+,sr
	movem.l	(sp)+,d0/a0
	rts
rd_scs0	dc.l	SCARENA
ifwork	equ	rd_ifwork
	include	"inflate.i"
	section	bss,bss
rd_ifwork	ds.b	IF_SIZE
	section	game,code
	include	"fe.i"
	section	game,code

;	The box of what the image a2 shows into its cache entry a4: first line with a pixel
;	and lines from there (0, 0: none), first and last pixel across. Keeps everything.
rd_sc_box
	movem.l	d0-d6/a0,-(sp)
	lea	(a2,d7.l),a0
	move.w	(rd_wb).l,d6
	mulu.w	#NPLANES,d6
	move.w	(rd_sch).l,d5
	lsl.w	#3,d5
	subq.w	#1,d5
	moveq	#0,d0
	moveq	#-1,d1
	moveq	#0,d2
	moveq	#0,d3
.l	move.l	(a0),d4
	cmpi.w	#2*NPLANES,d6
	bne.s	.l4
	clr.w	d4
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
	move.w	d1,20(a4)
	move.l	d0,d4
	neg.l	d4
	and.l	d0,d4
	bfffo	d4{0:0},d1
	move.w	d1,22(a4)
.x	movem.l	(sp)+,d0-d6/a0
	rts

;	Native player objects.
OBJMAX		equ	32
OBJPC		equ	8
OBJSLOTS	equ	2048
;	rd_omemo: per place of the sprite list (an object's last sprite), 128 bytes: the
;	frame it was drawn in, then what it was drawn from and the blit it was (rd_obj_blit).
OMKEY		equ	4
OMSPR		equ	8
OMORG		equ	16
OMPOS		equ	24
OMFLG		equ	28
OMCOV		equ	30
OMREC		equ	40

;	The game's addframe2, the same work in fewer steps: d0/d1 = the object's place on the
;	screen, a3 = the object. Keeps the rest; the flags as the game leaves them (its attribute).
hal_addframe2
	movem.l	d0-d5/d7/a0-a2/a4,-(sp)
	movea.l	a6,a1
	move.w	frame(a3),d4
	ble	.x
	move.w	attribute(a3),d7
	move.w	d4,d2
	andi.w	#$F800,d2
	eor.w	d2,d7
	andi.w	#$7FF,d4
	movea.l	#Sprites,a2
	adda.l	4(a2),a2
	add.w	d4,d4
	cmp.w	2(a2),d4
	bge	.x
	move.w	2(a2,d4.w),d5
	sub.w	(a2,d4.w),d5
	lsr.w	#3,d5
	subq.w	#1,d5
	adda.w	(a2,d4.w),a2
	lsr.w	#1,d4
	cmp.w	oldframe(a3),d4
	beq	.sat
	move.w	d4,oldframe(a3)
	movem.l	d0-d1/d5-d6,-(sp)
	movea.l	a2,a0
	lea	(sizetab).l,a4
	moveq	#0,d3
	moveq	#0,d4
.t	move.w	4(a0),d2
	moveq	#0,d1
	move.b	7(a0),d1
	move.b	(a4,d1.w),d1
	cmp.w	d4,d1
	bgt.s	.q
	cmp.w	d6,d2
	blt.s	.q
	move.w	d6,d0
	add.w	d4,d0
	sub.w	d2,d0
	sub.w	d1,d0
	bpl.s	.n
.q	add.w	d4,d3
	move.w	d2,d0
	ext.l	d0
	lsl.l	#5,d0
	addi.l	#Spritetiles,d0
	move.l	d0,(a5)+
	move.w	d1,d0
	lsl.w	#4,d0
	move.w	d0,(a5)+
	move.w	d3,d0
	add.w	VRchar(a3),d0
	lsl.w	#5,d0
	move.w	d0,(a5)+
.n	move.b	d3,VRoffs(a3,d5.w)
	move.w	d2,d6
	move.w	d1,d4
	addq.l	#8,a0
	dbf	d5,.t
	movem.l	(sp)+,d0-d1/d5-d6
.sat	move.w	VRchar(a3),d4
.s	move.w	2(a2),d2
	btst	#12,d7
	beq.s	.ny
	moveq	#3,d3
	and.b	7(a2),d3
	addq.w	#1,d3
	lsl.w	#3,d3
	neg.w	d3
	sub.w	d2,d3
	move.w	d3,d2
.ny	add.w	d1,d2
	move.w	d2,(a6)
	move.w	(a2),d2
	btst	#11,d7
	beq.s	.nx
	moveq	#$C,d3
	and.b	7(a2),d3
	addq.w	#4,d3
	add.w	d3,d3
	neg.w	d3
	sub.w	d2,d3
	move.w	d3,d2
.nx	add.w	d0,d2
	move.w	d2,6(a6)
	move.b	7(a2),2(a6)
	move.b	d6,3(a6)
	move.w	6(a2),d2
	eor.w	d7,d2
	andi.w	#$F800,d2
	btst	#0,d7
	beq.s	.np
	btst	#14,d2
	beq.s	.np
	bset	#13,d2
.np	or.b	VRoffs(a3,d5.w),d2
	add.w	d4,d2
	move.w	d2,4(a6)
	addq.w	#1,d6
	addq.l	#8,a6
	addq.l	#8,a2
	dbf	d5,.s
	move.l	a6,d0
	sub.l	a1,d0
	lsr.l	#3,d0
	cmpi.l	#2,d0
	blo.s	.x
	cmpi.l	#OBJPC,d0
	bhi.s	.x
	move.l	a1,d1
	subi.l	#Satt,d1
	bmi.s	.x
	lsr.l	#3,d1
	cmpi.l	#80,d1
	bhs.s	.x
	move.w	(rd_objbn).l,d2
	cmpi.w	#OBJMAX,d2
	bhs.s	.x
	addq.w	#1,(rd_objbn).l
	move.w	d7,d3
	andi.w	#$7800,d3
	btst	#0,d7
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
.x	movem.l	(sp)+,d0-d5/d7/a0-a2/a4
	tst.w	attribute(a3)
	rts

;	The sprite list is sent (ds_sprites): its objects
;	with it; the next list's from none. Keeps everything.
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

;	rd_sprgend, rd_sprgkey: the objects of the table the sprite list was taken
;	from, noted at their last sprite (rd_snapshot: no game tick meanwhile).
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
	move.b	(a0)+,d1
	move.b	(a0)+,d2
	move.w	(a0)+,d3
	add.w	d2,d1
	cmp.w	(rd_spn).l,d1
	bhi.s	.e
	move.b	d2,-1(a1,d1.w)
	move.w	d3,-2(a2,d1.w*2)
.e	dbf	d0,.o
.x	rts

;	The object whose last sprite is a4, d1 sprites (the others before it in the list),
;	d2 its key: drawn as one image, Z set; or Z clear: to be drawn sprite by sprite.
rd_obj_blit
	move.w	d1,(rd_on).l
	move.w	d2,(rd_okey).l
	subq.w	#1,d1
	lsl.w	#3,d1
	movea.l	a4,a5
	suba.w	d1,a5
	moveq	#0,d0
	move.w	d2,d0
	mulu.w	#40503,d0
	lsr.l	#5,d0
	andi.l	#OBJSLOTS-1,d0
	lsl.l	#5,d0
	lea	(rd_octab).l,a2
	move.l	#$10000,d1
	move.w	d2,d1
	cmp.l	(a2,d0.l),d1
	beq.s	.k
	eori.w	#32,d0
	cmp.l	(a2,d0.l),d1
	beq.s	.k
	move.l	8(a2,d0.l),d1
	eori.w	#32,d0
	cmp.l	8(a2,d0.l),d1
	bhs.s	.v
	eori.w	#32,d0
.v	adda.l	d0,a2
	bra.s	.miss
.k	adda.l	d0,a2
	move.l	(rd_scpos).l,d1
	sub.l	8(a2),d1
	cmp.l	(rd_scsize).l,d1
	bls.s	.hit
.miss	bsr	rd_obj_gather
	bne	.no
	movem.l	a2/a4-a5,-(sp)
	bsr	rd_obj_build
	movem.l	(sp)+,a2/a4-a5
	bne	.no
.hit
	move.l	8(a2),d1
	move.l	d1,(rd_imgpos).l
	cmp.l	(rd_scmin).l,d1
	bge.s	.mo
	move.l	d1,(rd_scmin).l
.mo
	move.l	a4,d0
	subi.l	#rd_sprites,d0
	lsl.l	#4,d0
	lea	(rd_omemo).l,a0
	adda.l	d0,a0
	move.l	(rd_count).l,d0
	subq.l	#1,d0
	cmp.l	(a0),d0
	bne	.mf
	move.w	(rd_okey).l,d0
	cmp.w	OMKEY(a0),d0
	bne	.mf
	move.w	(rd_on).l,d0
	cmp.w	OMKEY+2(a0),d0
	bne	.mf
	move.l	(a5),d0
	cmp.l	OMSPR(a0),d0
	bne	.mf
	move.l	4(a5),d0
	cmp.l	OMSPR+4(a0),d0
	bne	.mf
	move.l	(rd_xorg).l,d0
	cmp.l	OMORG(a0),d0
	bne	.mf
	move.w	(rd_w).l,d0
	cmp.w	OMORG+4(a0),d0
	bne	.mf
	cmp.l	OMPOS(a0),d1
	bne	.mf
	move.l	(rd_count).l,(a0)
	btst	#0,OMFLG+1(a0)
	beq	.yes
	btst	#1,OMFLG+1(a0)
	beq.s	.mc
	movem.l	a0,-(sp)
	movem.w	OMCOV(a0),d0-d3
	bsr	rd_cover_u
	movem.l	(sp)+,a0
.mc	lea	OMREC(a0),a1
	move.l	OPREC-4(a1),(rd_opbox).l
	tst.b	(rd_stage).l
	bne.s	.ml
	movem.l	a1,-(sp)
	lea	OPREC-4(a1),a1
	movea.l	(rd_dmap).l,a2
	bsr	rd_box_set
	movem.l	(sp)+,a1
.ml	movem.w	12(a1),d0-d5
	move.l	24(a1),d6
	movea.l	(a1),a0
	adda.l	(rd_back).l,a0
	movea.l	8(a1),a2
	movea.l	4(a1),a1
	bsr	rd_cut_emit
	bra	.yes
.mf	move.l	(rd_count).l,(a0)
	move.w	(rd_okey).l,OMKEY(a0)
	move.w	(rd_on).l,OMKEY+2(a0)
	move.l	(a5),OMSPR(a0)
	move.l	4(a5),OMSPR+4(a0)
	move.l	(rd_xorg).l,OMORG(a0)
	move.w	(rd_w).l,OMORG+4(a0)
	move.l	d1,OMPOS(a0)
	clr.w	OMFLG(a0)
	move.l	a0,(rd_omcap).l
.o
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
	cmpi.w	#SCRH,d0
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
	cmpi.w	#-SCRX*8,d3
	blt	.no
	move.l	a2,-(sp)
	bsr	rd_spr_geom
	movea.l	(sp)+,a2
	move.l	16(a2),(rd_bl0).l
	move.l	20(a2),(rd_bp0).l
	movea.l	12(a2),a2
	move.w	(rd_wb).l,d0
	mulu.w	(rd_sch).l,d0
	mulu.w	#6*8,d0
	lea	(a2,d0.l),a3
	bsr	rd_spr_cut
.yes	clr.l	(rd_omcap).l
	moveq	#0,d0
	rts
.no	move.l	(rd_omcap).l,d0
	beq.s	.nn
	movea.l	d0,a0
	clr.l	(a0)
	clr.l	(rd_omcap).l
.nn	moveq	#1,d0
	rts

;	The object's sprites (from a5, rd_on of them) into rd_opc: their tiles' source
;	(native, in a row), flips, palette, size, place from the first. Keeps a2, a4, a5.
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
	lea	(vm_tsrc).l,a3
	movea.l	a5,a0
	move.w	(rd_on).l,d7
	subq.w	#1,d7
.pk	move.w	4(a0),d0
	move.w	d0,d1
	andi.w	#$8000,d1
	cmp.w	(rd_opri).l,d1
	bne	.no
	moveq	#0,d1
	move.w	d0,d1
	andi.w	#$7FF,d1
	move.l	(a3,d1.l*4),d2
	subi.l	#Spritetiles,d2
	cmpi.l	#SPRTSIZE,d2
	bhs	.no
	move.l	d2,(a1)
	andi.w	#$7800,d0
	move.w	d0,4(a1)
	moveq	#0,d3
	move.b	2(a0),d3
	move.b	d3,6(a1)
	clr.b	7(a1)
	move.w	d3,d4
	andi.w	#3,d4
	addq.w	#1,d4
	lsr.w	#2,d3
	andi.w	#3,d3
	addq.w	#1,d3
	mulu.w	d4,d3
	subq.w	#2,d3
	bmi.s	.t1
	addi.l	#Spritetiles,d2
.tc	addq.w	#1,d1
	andi.w	#$7FF,d1
	addi.l	#32,d2
	cmp.l	(a3,d1.l*4),d2
	bne.s	.no
	dbf	d3,.tc
.t1	move.w	6(a0),d0
	andi.w	#$1FF,d0
	sub.w	(rd_ox0).l,d0
	move.w	d0,8(a1)
	move.w	(a0),d0
	andi.w	#$3FF,d0
	sub.w	(rd_oy0).l,d0
	move.w	d0,10(a1)
	lea	12(a1),a1
	addq.l	#8,a0
	dbf	d7,.pk
	moveq	#0,d0
	rts
.no	moveq	#1,d0
	rts

;	The image of the object rd_opc (rd_on sprites; its key rd_okey)
;	built into the sprite image ring and the entry a2 of rd_octab.
rd_obj_build
	move.l	a2,(rd_oent).l
	lea	(rd_opc).l,a0
	move.w	(rd_on).l,d7
	subq.w	#1,d7
	move.w	#$7FFF,d0
	move.w	#$7FFF,d1
	move.w	#-$8000,d2
	move.w	#-$8000,d3
.bx	moveq	#0,d4
	move.b	6(a0),d4
	moveq	#3,d5
	and.w	d4,d5
	addq.w	#1,d5
	lsl.w	#3,d5
	lsr.w	#2,d4
	andi.w	#3,d4
	addq.w	#1,d4
	lsl.w	#3,d4
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
	sub.w	d0,d2
	sub.w	d1,d3
	addq.w	#7,d2
	lsr.w	#3,d2
	addq.w	#7,d3
	lsr.w	#3,d3
	cmpi.w	#8,d2
	bhi	.big
	cmpi.w	#8,d3
	bhi	.big
	move.w	d2,(rd_oscw).l
	move.w	d3,(rd_osch).l
	addq.w	#1,d2
	lsr.w	#1,d2
	add.w	d2,d2
	move.w	d2,(rd_owb).l
	lsl.w	#3,d3
	move.w	d3,(rd_olines).l
	subq.w	#1,d3
	lea	(rd_oscr).l,a0
	moveq	#0,d0
	cmpi.w	#4,(rd_owb).l
	bhi.s	.c8
.c4	move.l	d0,(a0)
	move.l	d0,8(a0)
	move.l	d0,16(a0)
	move.l	d0,24(a0)
	move.l	d0,32(a0)
	move.l	d0,40(a0)
	move.l	d0,48(a0)
	move.l	d0,52(a0)
	lea	56(a0),a0
	dbf	d3,.c4
	bra.s	.cd
.c8	REPT	14
	move.l	d0,(a0)+
	ENDR
	dbf	d3,.c8
.cd
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
	move.w	(rd_owb).l,d1
	mulu.w	(rd_olines).l,d1
	mulu.w	#6*2,d1
	bsr	rd_sc_alloc
	movea.l	(rd_oent).l,a4
	move.l	#$10000,d0
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

;	One sprite of an object (a6: its rd_opc entry) into the
;	scratch (rd_oscr) at its place from rd_ominx, rd_ominy.
rd_obj_piece
	moveq	#0,d0
	move.b	6(a6),d0
	moveq	#3,d1
	and.w	d0,d1
	addq.w	#1,d1
	lsr.w	#2,d0
	andi.w	#3,d0
	addq.w	#1,d0
	move.w	d0,(rd_opw).l
	move.w	d1,d6
	lsl.w	#3,d6
	move.w	d6,(rd_oplines).l
	lsl.w	#5,d1
	ext.l	d1
	movea.l	d1,a4
	move.w	4(a6),d5
	move.w	d5,(rd_opat).l
	move.w	10(a6),d2
	sub.w	(rd_ominy).l,d2
	mulu.w	#56,d2
	lea	(rd_oscr).l,a1
	adda.l	d2,a1
	move.l	a1,(rd_opline).l
	moveq	#0,d2
	move.w	8(a6),d2
	sub.w	(rd_ominx).l,d2
	move.l	d2,(rd_opx).l
	lea	(Spritetiles).l,a0
	adda.l	(a6),a0
	lea	(rd_rev8).l,a2
	movea.w	#4,a5
	btst	#11,d5
	beq.s	.nh
	move.w	(rd_opw).l,d0
	subq.w	#1,d0
	mulu.w	d1,d0
	adda.l	d0,a0
	move.l	a4,d0
	neg.l	d0
	movea.l	d0,a4
.nh	subq.w	#1,d6
	btst	#12,d5
	beq.s	.nv
	move.w	d6,d0
	lsl.w	#2,d0
	adda.w	d0,a0
	movea.w	#-4,a5
.nv	bsr	rd_obj_overlap
	tst.b	(rd_oovl).l
	bne	.bf
	move.l	(rd_opx).l,d2
	moveq	#7,d0
	and.w	d2,d0
	bne	.bf
	lsr.w	#3,d2
	movea.l	(rd_opline).l,a1
	adda.w	d2,a1
	moveq	#0,d2
	btst	#13,d5
	beq.s	.s4
	moveq	#-1,d2
.s4	moveq	#0,d4
	btst	#14,d5
	beq.s	.s5
	moveq	#-1,d4
.s5	moveq	#0,d1
	btst	#11,d5
	bne.s	.sfl
.sl	movea.l	a0,a3
	movea.l	a1,a6
	move.w	(rd_opw).l,d7
	subq.w	#1,d7
.sc	move.l	(a3),d0
	adda.l	a4,a3
	move.b	d0,24(a6)
	move.b	d0,d3
	lsr.w	#8,d0
	move.b	d0,16(a6)
	or.b	d0,d3
	swap	d0
	move.b	d0,8(a6)
	or.b	d0,d3
	lsr.w	#8,d0
	move.b	d0,(a6)
	or.b	d0,d3
	move.b	d3,48(a6)
	move.b	d3,d0
	and.b	d2,d0
	move.b	d0,32(a6)
	and.b	d4,d3
	move.b	d3,40(a6)
	addq.l	#1,a6
	dbf	d7,.sc
	adda.l	a5,a0
	lea	56(a1),a1
	dbf	d6,.sl
	rts
.sfl	movea.l	a0,a3
	movea.l	a1,a6
	move.w	(rd_opw).l,d7
	subq.w	#1,d7
.sfc	move.l	(a3),d0
	adda.l	a4,a3
	move.b	d0,d1
	move.b	(a2,d1.w),d1
	move.b	d1,24(a6)
	move.b	d1,d3
	lsr.w	#8,d0
	move.b	d0,d1
	move.b	(a2,d1.w),d1
	move.b	d1,16(a6)
	or.b	d1,d3
	swap	d0
	move.b	d0,d1
	move.b	(a2,d1.w),d1
	move.b	d1,8(a6)
	or.b	d1,d3
	lsr.w	#8,d0
	move.b	d0,d1
	move.b	(a2,d1.w),d1
	move.b	d1,(a6)
	or.b	d1,d3
	move.b	d3,48(a6)
	move.b	d3,d0
	and.b	d2,d0
	move.b	d0,32(a6)
	and.b	d4,d3
	move.b	d3,40(a6)
	addq.l	#1,a6
	dbf	d7,.sfc
	adda.l	a5,a0
	lea	56(a1),a1
	dbf	d6,.sfl
	rts
.bf
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
	rol.l	#8,d0
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
.ur	move.b	d0,12(a6)
	move.b	d0,d3
	lsr.l	#8,d0
	move.b	d0,8(a6)
	or.b	d0,d3
	lsr.w	#8,d0
	move.b	d0,4(a6)
	or.b	d0,d3
	swap	d0
	move.b	d0,(a6)
	or.b	d0,d3
	move.b	d3,16(a6)
	addq.l	#1,a6
	dbf	d7,.uc
	adda.l	a5,a0
	lea	20(a1),a1
	dbf	d6,.ul
	lea	(rd_opbuf).l,a0
	movea.l	(rd_opline).l,a1
	move.l	(rd_opx).l,d2
	moveq	#0,d3
	move.w	(rd_opw).l,d3
	lsl.w	#3,d3
	move.w	(rd_opat).l,d6
	move.w	(rd_oplines).l,d7
	subq.w	#1,d7
	tst.b	(rd_oovl).l
	beq	.il
.ml	move.l	16(a0),d4
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
	bfextu	32(a1){d2:d3},d0
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
	bfextu	48(a1){d2:d3},d0
	or.l	d4,d0
	bfins	d0,48(a1){d2:d3}
.mn	lea	20(a0),a0
	lea	56(a1),a1
	dbf	d7,.ml
	rts
.il	move.l	16(a0),d4
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

;	Does the sprite a6 (rd_opc) overlap one after it in the list
;	(drawn into the image before it)? rd_oovl. Keeps all but the flags.
rd_obj_overlap
	movem.l	d0-d7/a0,-(sp)
	sf	(rd_oovl).l
	bsr.s	.box
	movem.w	d0-d3,-(sp)
	lea	12(a6),a0
	move.w	(rd_on).l,d7
	mulu.w	#12,d7
	addi.l	#rd_opc,d7
.o	cmpa.l	d7,a0
	bhs.s	.x
	exg	a0,a6
	bsr.s	.box
	exg	a0,a6
	cmp.w	4(sp),d0
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
.box	moveq	#0,d4
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

;	The scratch (rd_oscr) into the ring at a2 in the blitter's layout: the image (per
;	line planes 0-5, rows of rd_owb bytes), then the mask (per line its row 6 times).
OBJCPR	MACRO
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
OBJCPM	MACRO
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
OBJCPL	MACRO
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
	lea	(a2,d0.l),a3
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

;	The box of the scratch's image into the entry a4 (as rd_sc_box: first
;	line with a pixel, lines from there, first and last pixel across).
rd_obj_box
	lea	(rd_oscr+48).l,a0
	moveq	#0,d4
	moveq	#0,d5
	moveq	#-1,d1
	moveq	#0,d2
	moveq	#0,d3
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
	tst.l	d4
	beq.s	.f2
	bfffo	d4{0:0},d0
	bra.s	.f3
.f2	bfffo	d5{0:0},d0
	addi.w	#32,d0
.f3	move.w	d0,20(a4)
	tst.l	d5
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

;	Draw the sprite described by rd_sx..rd_r1 straight into the back buffer.
rd_spr_cpu
	bsr	rd_spr_tiles
	bsr	rd_waitblit
	move.w	(rd_colx).l,d0
	add.w	(rd_xorg).l,d0
	move.w	d0,(rd_sbit).l
	moveq	#0,d6
	btst	#0,(rd_spal+1).l
	beq.s	.p4
	moveq	#-1,d6
.p4	moveq	#0,d7
	btst	#1,(rd_spal+1).l
	beq.s	.p5
	moveq	#-1,d7
.p5	movem.l	d6-d7,(rd_spalm).l
	lea	(rd_ctiles).l,a0
	moveq	#0,d1
.ct	cmp.w	(rd_ncol).l,d1
	bge.s	.ctd
	move.w	d1,d0
	add.w	(rd_c0).l,d0
	btst	#3,(rd_sat).l
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
.ctd
	movea.l	(rd_back).l,a0
	move.w	(rd_sy).l,d0
	add.w	(rd_r0).l,d0
	mulu.w	#SROW,d0
	adda.l	d0,a0
	move.w	(rd_r0).l,d5
.seg	cmp.w	(rd_r1).l,d5
	bge	.x
	move.w	d5,d0
	moveq	#8,d7
	suba.l	a5,a5
	addq.l	#4,a5
	btst	#4,(rd_sat).l
	beq.s	.nv
	move.w	(rd_sch).l,d0
	lsl.w	#3,d0
	subq.w	#1,d0
	sub.w	d5,d0
	moveq	#1,d7
	subq.l	#8,a5
.nv	moveq	#7,d2
	and.w	d0,d2
	lsr.w	#3,d0
	tst.l	a5
	bmi.s	.vf
	sub.w	d2,d7
	bra.s	.cnt
.vf	add.w	d2,d7
.cnt	move.w	(rd_r1).l,d3
	sub.w	d5,d3
	cmp.w	d3,d7
	ble.s	.cn
	move.w	d3,d7
.cn	add.w	d7,d5
	movea.w	d5,a1
	subq.w	#1,d7
	lsl.w	#2,d2
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

.c1	move.w	(rd_spalm+2).l,d5
	move.w	(rd_spalm+6).l,d6
.l1	move.l	(a2),d2
	adda.l	a5,a2
	beq	.n1
	move.l	d2,d3
	swap	d3
	or.w	d2,d3
	move.w	d3,d4
	lsr.w	#8,d4
	or.b	d4,d3
	move.b	d3,d4
	not.b	d3
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

.c2	move.w	(rd_spalm+2).l,d5
	move.w	(rd_spalm+6).l,d6
.l2	move.l	(a2),d2
	adda.l	a5,a2
	move.l	(a3),d3
	adda.l	a5,a3
	move.l	d2,d0
	or.l	d3,d0
	beq	.n2
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
	or.w	d0,d4
	not.w	d4
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
	not.w	d2
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

.c3	movea.l	a4,a6
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
.four
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
	beq	.n4
	not.l	d6
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
	not.l	d2
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

;	Build the image (a2) and mask of the sprite described by rd_sx..rd_r1: lines rd_r0 to rd_r1-1,
;	columns rd_c0 on (rd_ncol of them), rows of rd_wb bytes per plane (2 or 4). Keeps a2, a3.
SPRLINE	MACRO
	move.b	(a1),d3
	adda.w	d5,a1
	move.l	(a0),d0
	adda.w	d4,a0
	tst.b	d3
	beq.s	.z\@
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
	bsr	rd_spr_tiles
	movem.l	a2-a3,-(sp)
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
	add.w	(rd_c0).l,d0
	btst	#3,(rd_sat).l
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
.nf2	move.w	d0,(rd_btile).l
	clr.w	(rd_btr).l
.tr	move.w	(rd_btr).l,d0
	cmp.w	(rd_sch).l,d0
	bge	.ncol
	lsl.w	#3,d0
	move.w	d0,d1
	addq.w	#8,d1
	cmp.w	(rd_r0).l,d0
	bge.s	.t0
	move.w	(rd_r0).l,d0
.t0	cmp.w	(rd_r1).l,d1
	ble.s	.t1
	move.w	(rd_r1).l,d1
.t1	sub.w	d0,d1
	ble	.ntr
	move.w	d1,d2
	subq.w	#1,d2
	move.w	(rd_btr).l,d1
	move.w	d0,d3
	andi.w	#7,d3
	moveq	#4,d4
	moveq	#1,d5
	btst	#4,(rd_sat).l
	beq.s	.nvf
	move.w	(rd_sch).l,d1
	subq.w	#1,d1
	sub.w	(rd_btr).l,d1
	eori.w	#7,d3
	moveq	#-4,d4
	moveq	#-1,d5
.nvf	ext.l	d1
	add.w	(rd_btile).l,d1
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
.x
	move.w	(rd_r1).l,d0
	sub.w	(rd_r0).l,d0
	mulu.w	(rd_wb).l,d0
	mulu.w	#3,d0
	lea	(rd_sbuild).l,a0
	movea.l	(sp),a1
	subq.w	#1,d0
	bmi.s	.nc
.cp	move.l	(a0)+,(a1)+
	dbf	d0,.cp
.nc	movem.l	(sp)+,a2-a3
	rts

;	High priority plane B cells under something of low priority: draw them again on top.
FIXPL	MACRO
	move.b	(a3),d7
	and.b	d5,d7
	bfextu	\1(a1){d1:8},d0
	and.b	d2,d0
	or.b	d7,d0
	bfins	d0,\1(a1){d1:8}
	adda.w	d3,a3
	ENDM
FIXPAL	MACRO
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
;	priority pixels drawn again: in scroll mode a blit each (rd_fix_blit, queued), else by the CPU.
rd_fixups
	tst.w	(rd_scroll).l
	bne.s	.go
	bsr	rd_waitblit
.go	cmpi.w	#64,(rd_cw).l
	bne	.list
	lea	(rd_fixmap+2*32*4).l,a0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	REPT	2*32/4
	movem.l	d0-d3,-(a0)
	ENDR
	lea	(rd_cover).l,a1
	lea	(rd_hibits).l,a3
	moveq	#0,d4
	move.w	(rd_bx0).l,d4
	moveq	#7,d5
	and.w	d4,d5
	movea.w	d5,a2
	lsr.w	#3,d4
	neg.w	d4
	andi.w	#63,d4
	sf	(rd_fixsw).l
	cmpi.w	#32,d4
	blo.s	.r0
	st	(rd_fixsw).l
	subi.w	#32,d4
.r0	moveq	#32,d5
	sub.w	d4,d5
	move.w	(rd_by0).l,d6
	moveq	#7,d3
	and.w	d6,d3
	sne	(rd_fixchk).l
	lsr.w	#3,d6
	moveq	#0,d7
.sr	move.l	(a1)+,d0
	move.l	(a1)+,d1
	move.l	d0,d2
	or.l	d1,d2
	beq	.nsr
	tst.b	(rd_fixsw).l
	beq.s	.r1
	exg	d0,d1
.r1	move.l	d0,d2
	move.l	d1,d3
	lsl.l	d4,d0
	lsr.l	d5,d3
	or.l	d3,d0
	lsl.l	d4,d1
	lsr.l	d5,d2
	or.l	d2,d1
	move.l	a2,d2
	beq.s	.rows
	move.l	d1,d3
	lsr.l	#1,d3
	move.l	d0,d2
	roxr.l	#1,d2
	move.l	d1,d3
	roxr.l	#1,d3
	or.l	d2,d0
	or.l	d3,d1
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
	sf	(rd_fixchk).l
	tst.w	(rd_scroll).l
	bne	rd_fix_runs
	moveq	#0,d5
.fr	movem.l	(a0),d0-d1
	addq.l	#8,a0
	moveq	#0,d4
.fl	tst.l	d0
	bne.s	.fb
	move.l	d1,d0
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
	addq.w	#1,d2
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
.lok	st	(rd_fixchk).l
	move.w	(rd_hiBn).l,d7
	subq.w	#1,d7
	bmi	.x
	lea	(rd_hiB).l,a4
.each	move.w	(a4)+,d4
	move.w	(a4)+,d5
	bsr	rd_fixcell
	dbf	d7,.each
.x	rts

rd_fixcell
	movem.l	d0-d7/a0-a4,-(sp)
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
	subq.w	#1,d0
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
	bsr	rd_iscovered
	beq	.next
.go	tst.w	(rd_scroll).l
	beq.s	.cpu
	bsr	rd_fix_blit
	bra	.next
.cpu
	move.w	(rd_cw).l,d3
	moveq	#0,d6
	tst.w	d2
	bpl	.top
	move.w	d2,d6
	neg.w	d6
.top	move.w	#SCRH,d7
	sub.w	d2,d7
	cmpi.w	#8,d7
	ble	.bot
	moveq	#8,d7
.bot	sub.w	d6,d7
	subq.w	#1,d7
	bmi	.next
	add.w	d6,d2
	mulu.w	#SROW,d2
	movea.l	(rd_back).l,a1
	adda.l	d2,a1
	move.w	d0,d1
	add.w	(rd_xorg).l,d1
	ext.l	d1
	lsl.w	#3,d5
	add.w	d6,d5
	mulu.w	d3,d5
	lea	(mkB).l,a2
	adda.l	d5,a2
	adda.w	d4,a2
	mulu.w	#6,d5
	lea	(bmB).l,a0
	adda.l	d5,a0
	adda.w	d4,a0
	move.w	d3,d6
	mulu.w	#6,d6
	move.w	d7,d4
.row	move.b	(a2),d5
	beq	.nr
	move.b	d5,d2
	not.b	d2
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

;	Scroll mode: queue the redraw of plane B's high priority pixels of cell d4, d5 (row), at screen
;	line d2: the bitmap through its mask (mkB6), the cell's word, no shift. Keeps everything.
rd_fix_blit
	movem.l	d0-d1/a0-a2/a5-a6,-(sp)
	movea.l	(rd_bmrp).l,a0
	moveq	#31,d0
	and.w	d5,d0
	lea	(a0,d0.w*4),a0
	moveq	#0,d0
	move.w	d4,d0
	lsr.w	#1,d0
	bfset	(a0){d0:1}
	move.w	d4,d0
	andi.w	#$FFFE,d0
	move.w	d5,d1
	mulu.w	#8*64*NPLANES,d1
	lea	(bmB).l,a0
	adda.l	d1,a0
	adda.w	d0,a0
	lea	(mkB6).l,a1
	adda.l	d1,a1
	adda.w	d0,a1
	move.w	(rd_brow0).l,d1
	add.w	d2,d1
	tst.b	(rd_stage).l
	beq.s	.nb
	movem.l	d0-d2,-(sp)
	move.w	d1,d2
	lsr.w	#1,d0
	moveq	#1,d1
	bsr	rd_fix_box
	movem.l	(sp)+,d0-d2
.nb	mulu.w	#SROW,d1
	movea.l	(rd_buf).l,a2
	adda.l	d1,a2
	lea	SCRX(a2,d0.w),a2
	moveq	#1,d1
	bsr	rd_fix_cq
	movem.l	(sp)+,d0-d1/a0-a2/a5-a6
	rts

;	The fixup blit (rd_fix_blit, rd_fix_runs): the bitmap a0 through its mask a1
;	over the buffer a2, d1 words across, 8 lines: rd_cut_emit. Uses d0-d1, a0, a5-a6.
rd_fix_cq
	movem.l	d2-d7/a1-a2,-(sp)
	move.w	d1,d3
	add.w	d1,d1
	moveq	#64,d0
	sub.w	d1,d0
	moveq	#SBPR,d7
	sub.w	d1,d7
	move.w	d7,d1
	move.l	a0,d7
	movea.l	a2,a0
	movea.l	a1,a2
	movea.l	d7,a1
	moveq	#8*NPLANES,d2
	moveq	#0,d4
	moveq	#-1,d5
	moveq	#0,d6
	bsr	rd_cut_emit
	movem.l	(sp)+,d2-d7/a1-a2
	rts

;	Scroll mode, 64 cells across: each plane row's cells of rd_fixmap (a0) as words (2 cells each)
;	on the screen, and each run of them one blit: the bitmap through its mask over the buffer.
rd_fix_runs
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
	moveq	#0,d5
.r	movem.l	(a0)+,d0-d1
	move.l	d0,d2
	or.l	d1,d2
	beq	.nr
	moveq	#0,d2
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
	move.w	d5,d4
	lsl.w	#3,d4
	sub.w	(rd_by0).l,d4
	andi.w	#255,d4
	cmpi.w	#SCRH,d4
	blt.s	.on
	subi.w	#256,d4
	cmpi.w	#-8,d4
	ble	.nr
.on
.run	bfffo	d2{0:0},d0
	move.l	d2,d1
	not.l	d1
	bfffo	d1{d0:0},d1
	cmpi.w	#32,d1
	bls.s	.e
	moveq	#32,d1
.e	sub.w	d0,d1
	bfclr	d2{d0:d1}
	bsr.s	.blit
	tst.l	d2
	bne.s	.run
.nr	addq.w	#1,d5
	cmpi.w	#32,d5
	blo	.r
	bra	rd_cq_flush
.blit	movem.l	d0-d2/a0-a2/a5-a6,-(sp)
	movea.l	(rd_bmrp).l,a0
	moveq	#31,d2
	and.w	d5,d2
	lea	(a0,d2.w*4),a0
	moveq	#0,d2
	move.w	d0,d2
	bfset	(a0){d2:d1}
	add.w	d0,d0
	move.w	d5,d2
	mulu.w	#8*64*NPLANES,d2
	lea	(bmB).l,a0
	adda.l	d2,a0
	adda.w	d0,a0
	lea	(mkB6).l,a1
	adda.l	d2,a1
	adda.w	d0,a1
	move.w	(rd_brow0).l,d2
	add.w	d4,d2
	tst.b	(rd_stage).l
	beq.s	.nb
	move.l	d0,-(sp)
	lsr.w	#1,d0
	bsr	rd_fix_box
	move.l	(sp)+,d0
.nb	mulu.w	#SROW,d2
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
	move.w	d0,d4
	move.w	d0,d5
	addq.w	#7,d5
	move.w	d2,d1
	move.w	d2,d3
	addq.w	#7,d3
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
	addq.w	#1,d5
	ext.l	d4
	lea	(rd_cover).l,a0
	lea	(a0,d1.w*8),a0
	sub.w	d1,d3
	bmi	.no
.r	bfextu	(a0){d4:d5},d0
	bne	.yes
	addq.l	#8,a0
	dbf	d3,.r
.no	movem.l	(sp)+,d0-d5/a0
	moveq	#0,d6
	rts
.yes	movem.l	(sp)+,d0-d5/a0
	moveq	#1,d6
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
rd_fixchk	ds.b	1
rd_fixsw	ds.b	1
	even
rd_rsend	ds.w	1
	even
rd_rsel		ds.l	2
rd_rstg		ds.l	2
rd_bmrc		ds.l	3*32
rd_bmrp		ds.l	1
rd_ovrd		ds.l	3
	even

	section	game,code

;	Colours: the game's ----bbb-ggg-rrr- (display.asm) to Amiga $0RGB.
rd_palette
	move.l	(ds_palgen).l,d0
	cmp.l	(rd_palgen).l,d0
	beq	.on
	move.l	d0,(rd_palgen).l
	addq.l	#1,(rd_colgen).l
	movem.l	a3-a4,-(sp)
	lea	(ds_pal).l,a0
	lea	(rd_colours).l,a1
	lea	(rd_colourslo).l,a2
	lea	(rd_palh).l,a3
	lea	(rd_pall).l,a4
	moveq	#63,d0
	moveq	#0,d1
.c	move.b	(a0)+,d1
	andi.b	#$0E,d1
	move.l	(a3,d1.w*4),d2
	move.b	(a0)+,d1
	or.l	(a4,d1.w*4),d2
	move.w	d2,(a2)+
	swap	d2
	move.w	d2,(a1)+
	dbf	d0,.c
	movem.l	(sp)+,a3-a4
	lea	(rd_colours).l,a1
	bsr.s	.bd
	lea	(rd_colourslo).l,a1
.bd	move.w	(a1),d1
	move.w	d1,32(a1)
	move.w	d1,64(a1)
	move.w	d1,96(a1)
.on	rts

;	Genesis colour d1 (----BBB-GGG-RRR-) -> AGA 24 bit
;	colour: d2 = high nibbles ($0RGB), d4 = low nibbles.
rd_gen2amiga
	moveq	#0,d2
	moveq	#0,d4
	move.w	d1,d3
	lsr.w	#1,d3
	bsr.s	.ch
	move.w	d1,d3
	lsr.w	#5,d3
	bsr.s	.ch
	move.w	d1,d3
	lsr.w	#8,d3
	lsr.w	#1,d3
.ch	andi.w	#7,d3
	move.b	(.lv,pc,d3.w),d3
	lsl.w	#4,d2
	lsl.w	#4,d4
	ror.b	#4,d3
	move.b	d3,d5
	andi.b	#15,d5
	or.b	d5,d2
	lsr.b	#4,d3
	or.b	d3,d4
	rts
.lv	dc.b	0,52,87,116,144,172,206,255

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
	swap	d1
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
	move.w	(rd_bufi).l,d2
	mulu.w	#5*NPLANES*2,d2
	lea	(rd_fpsimg).l,a0
	adda.l	d2,a0
	movea.l	a0,a3
	lea	(.font,pc),a1
	mulu.w	#5,d0
	mulu.w	#5,d1
	lea	(a1,d0.w),a2
	adda.w	d1,a1
	moveq	#4,d2
.r	move.b	(a2)+,d3
	lsl.w	#8,d3
	move.b	(a1)+,d3
	moveq	#NPLANES-1,d4
.p	move.w	d3,(a0)+
	dbf	d4,.p
	dbf	d2,.r
	bsr	rd_bq_alloc
	move.l	#$09F00000,$040(a6)
	move.l	#$FFFFFFFF,$044(a6)
	move.l	a3,$050(a6)
	movea.l	(rd_back).l,a0
	move.w	(rd_xorg).l,d2
	addi.w	#15,d2
	lsr.w	#4,d2
	add.w	d2,d2
	lea	SROW*4(a0,d2.w),a0
	move.l	a0,$054(a6)
	clr.w	$064(a6)
	move.w	#SBPR-2,$066(a6)
	move.w	#5*NPLANES,$05C(a6)
	move.w	#1,$05E(a6)
	bra	rd_bq_go
.font	dc.b	$E0,$A0,$A0,$A0,$E0, $40,$C0,$40,$40,$E0, $E0,$20,$E0,$80,$E0, $E0,$20,$60,$20,$E0
	dc.b	$A0,$A0,$E0,$20,$20, $E0,$80,$E0,$20,$E0, $E0,$80,$E0,$A0,$E0, $E0,$20,$40,$40,$40
	dc.b	$E0,$A0,$E0,$A0,$E0, $E0,$A0,$E0,$20,$E0
	dc.b	$40,$A0,$E0,$A0,$A0, $C0,$A0,$C0,$A0,$C0, $60,$80,$80,$80,$60, $C0,$A0,$A0,$A0,$C0
	dc.b	$E0,$80,$C0,$80,$E0, $E0,$80,$C0,$80,$80
	even

;	The back buffer's copper list: 6 interleaved planes, 4x fetch (FMODE 3), 320 (H40)
;	or 256 (H32) pixels from the buffer's bit rd_xorg, 224 lines, the 64 colours.
COPMOVE	MACRO
	move.w	#\1,(a0)+
	move.w	\2,(a0)+
	ENDM

rd_show
	tst.b	(hal_fpsshow).l
	beq	.nofps
	bsr	rd_fps
.nofps	movea.l	(rd_backcop).l,a0
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
	move.w	#$3CA1,d1
	move.w	#$1CA1,d2
	tst.b	(hal_pal).l
	bne	.pal
	move.w	#$1AA1,d1
	move.w	#$FAA1,d2
.pal	cmpi.w	#320,(rd_w).l
	bne	.h32
	move.b	#$81,d1
	move.b	#$C1,d2
	moveq	#64,d6
	moveq	#63,d7
	move.w	#$0018,d3
	move.w	#SROW-48,d5
	move.w	#$000F,d4
	bra.s	.dw
.h32	moveq	#32,d6
	moveq	#31,d7
	move.w	#$0038,d3
	move.w	#SROW-36,d5
	move.w	#$000D,d4
.dw	tst.b	(rd_shfast).l
	bne	.dyn
	move.l	#$009C0006,(a0)
	move.w	#$08E,4(a0)
	move.w	d1,6(a0)
	move.w	#$090,8(a0)
	move.w	d2,10(a0)
	move.w	#$092,12(a0)
	move.w	d3,14(a0)
	move.l	#$009400B8,16(a0)
	move.w	#$108,20(a0)
	move.w	d5,22(a0)
	move.w	#$10A,24(a0)
	move.w	d5,26(a0)
	move.w	#$1FC,28(a0)
	move.w	d4,30(a0)
	move.l	#$01006201,32(a0)
	move.w	#$102,36(a0)
	move.l	#$01040224,40(a0)
	move.l	#$010C0044,44(a0)
	lea	48(a0),a1
	move.w	#$0E0,d1
	moveq	#NPLANES*2-1,d2
.bpr	move.w	d1,(a1)
	addq.l	#4,a1
	addq.w	#2,d1
	dbf	d2,.bpr
.dyn	move.w	(rd_xorg).l,d0
	move.w	d6,d1
	sub.w	d0,d1
	and.w	d7,d1
	add.w	d1,d0
	sub.w	d6,d0
	asr.w	#3,d0
	ext.l	d0
	add.l	(rd_back).l,d0
	move.w	d1,d2
	andi.w	#15,d2
	move.w	d2,d3
	lsl.w	#4,d3
	or.w	d3,d2
	btst	#4,d1
	beq.s	.d16
	ori.w	#$4400,d2
.d16	btst	#5,d1
	beq.s	.d32
	ori.w	#$8800,d2
.d32	move.w	d2,38(a0)
	lea	50(a0),a1
	moveq	#NPLANES-1,d2
.bp	swap	d0
	move.w	d0,(a1)
	swap	d0
	move.w	d0,4(a1)
	addq.l	#8,a1
	addi.l	#SBPR,d0
	dbf	d2,.bp
	lea	96(a0),a0
	tst.w	(rd_hudon).l
	beq	.hs0
	movem.l	d3-d5/a0/a2-a3,-(sp)
	move.w	(rd_bufi).l,d0
	move.w	d0,d3
	mulu.w	#8*HUDSPR,d3
	add.l	#rd_hudsd,d3
	move.l	d3,(rd_hudcopy).l
	lea	(rd_hudbd).l,a1
	move.l	(a1,d0.w*4),d2
	beq.s	.hk
	clr.l	(a1,d0.w*4)
	lea	(rd_hudm).l,a2
	movea.l	d3,a3
	cmpi.l	#-1,d2
	bne.s	.hb
	move.w	(rd_hudgn).l,d2
	mulu.w	#2*HUDSPR/4,d2
	subq.w	#1,d2
.hcp	move.l	(a2)+,(a3)+
	dbf	d2,.hcp
	bra.s	.hk
.hb	bfffo	d2{0:0},d4
	bfclr	d2{d4:1}
	moveq	#0,d5
	move.w	d4,d5
	lsr.w	#3,d5
	mulu.w	#2*HUDSPR,d5
	andi.w	#7,d4
	lsl.w	#7,d4
	add.w	d4,d5
	addi.w	#16,d5
	lea	(a2,d5.l),a0
	lea	(a3,d5.l),a1
	moveq	#128/4-1,d4
.hbe	move.l	(a0)+,(a1)+
	dbf	d4,.hbe
	lea	HUDSPR-128(a0),a0
	lea	HUDSPR-128(a1),a1
	moveq	#128/4-1,d4
.hbo	move.l	(a0)+,(a1)+
	dbf	d4,.hbo
	tst.l	d2
	bne.s	.hb
.hk	movem.l	(sp)+,d3-d5/a0/a2-a3
.hs0	tst.b	(rd_shfast).l
	beq.s	.hsp
	lea	64(a0),a0
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
.bank	move.w	#$106,(a0)+
	move.w	d3,d0
	lsl.w	#8,d0
	lsl.w	#5,d0
	ori.w	#$0C00,d0
	move.w	d0,(a0)+
	move.l	#$01800000,d1
	moveq	#31,d2
.col	move.w	(a1)+,d1
	move.l	d1,(a0)+
	addi.l	#$20000,d1
	dbf	d2,.col
	move.w	#$106,(a0)+
	ori.w	#$0200,d0
	move.w	d0,(a0)+
	move.l	#$01800000,d1
	moveq	#31,d2
.lo	move.w	(a2)+,d1
	move.l	d1,(a0)+
	addi.l	#$20000,d1
	dbf	d2,.lo
	addq.w	#1,d3
	cmpi.w	#2,d3
	bne	.bank
	tst.w	(rd_hudon).l
	beq	.nohc
	lea	(rd_hudmap).l,a1
	lea	(rd_colours).l,a2
	COPMOVE	$106,#$4C00
	move.l	#$01800000,d1
	moveq	#15,d2
	moveq	#0,d0
.hc	move.b	(a1)+,d0
	move.w	(a2,d0.w*2),d1
	move.l	d1,(a0)+
	addi.l	#$20000,d1
	dbf	d2,.hc
	lea	(rd_hudmap).l,a1
	lea	(rd_colourslo).l,a2
	COPMOVE	$106,#$4E00
	move.l	#$01800000,d1
	moveq	#15,d2
	moveq	#0,d0
.hl	move.b	(a1)+,d0
	move.w	(a2,d0.w*2),d1
	move.l	d1,(a0)+
	addi.l	#$20000,d1
	dbf	d2,.hl
.nohc
	move.l	#$008A0000,(a0)+
.cdone
	moveq	#0,d1
	move.w	(rd_bufi).l,d1
	lea	(rd_shownvb).l,a1
	move.l	#$7FFFFFFF,(a1,d1.w*4)
	bsr	rd_bq_allocq
	move.l	(rd_backcop).l,$048(a6)
	move.w	d1,$04C(a6)
	clr.w	$05E(a6)
	bsr	rd_bq_go
	addq.w	#1,d1
	cmpi.w	#NBUF,d1
	blo.s	.nb
	moveq	#0,d1
.nb	move.w	d1,(rd_bufi).l
	move.l	(rd_scrs,pc,d1.w*4),d0
	move.l	d0,(rd_buf).l
	move.l	d0,(rd_back).l
	move.w	d1,d0
	mulu.w	#DROWS*4,d0
	add.l	#rd_dirty,d0
	move.l	d0,(rd_dmap).l
	move.w	d1,d0
	mulu.w	#1024,d0
	add.l	(rd_copb).l,d0
	move.l	d0,(rd_backcop).l
	rts

rd_scrs		dc.l	rd_scr0,rd_scr1,rd_scr2

	section	bss,bss
rd_hudspt	ds.l	8
rd_hudgen	ds.l	1
rd_shkey	ds.l	2*NBUF
rd_shfast	ds.b	1
	even
rd_hudbd	ds.l	NBUF
rd_hudcopy	ds.l	1
rd_hudon	ds.w	1
rd_hudchg	ds.w	1
rd_hudw		ds.w	1
rd_hudy		ds.w	1
rd_hudn		ds.w	1
rd_hudgn	ds.w	1
rd_hudg		ds.w	4
rd_hudnc	ds.w	1
rd_hudbase	ds.l	1
		cnop	0,4
rd_hudm		ds.b	8*HUDSPR
rd_hudcols	ds.b	48
rd_hudcm	ds.b	64
	cnop	0,4
rd_hudmo	ds.b	HUDMO*16
rd_hudmap	ds.b	16
rd_nchgA	ds.w	1
rd_ntcur	ds.b	1
rd_nttab	ds.b	1
rd_ntsync	ds.b	1
	even
rd_sbit		ds.w	1
rd_ctiles	ds.w	4
rd_cqwp		ds.l	1
rd_cqdp		ds.l	1
rd_cqmh		ds.w	1
rd_cqmt		ds.w	1
rd_cqring	ds.l	1
rd_cqjmv	ds.l	1
rd_cqpmv	ds.l	1
rd_cqjmp	ds.l	1
rd_cqfree	ds.w	1
rd_cqkind	ds.b	1
rd_cqbat	ds.b	1
	even
rd_cqba5	ds.l	1
rd_cqba6	ds.l	1
	even
rd_cqmq		ds.b	8*16
rd_bqe		ds.b	BQE
rd_cqidle	ds.b	1
rd_bqhold	ds.b	1
	even
rd_lastset	ds.l	1
rd_showcop	ds.l	1
rd_wstat	ds.l	1
rd_snapvb	ds.l	NBUF
rd_showbuf	ds.w	1
		even
rd_c4m		ds.w	1
		cnop	0,4
rd_spalm	ds.l	2
rd_bcol		ds.w	1
rd_btr		ds.w	1
rd_btile	ds.w	1
rd_blitnoc	ds.w	1
rd_nchgW	ds.w	1
rd_chgA		ds.w	CHGMAX
rd_chgW		ds.w	CHGMAX
		cnop	0,4
rd_ovldirty	ds.w	1
rd_ovlrows	ds.l	2*32
rd_ovlcolf	ds.b	2*32*48
rd_ovlrl	ds.w	1+4*OVLRECTS
rd_ovlrh	ds.w	1+4*OVLRECTS
rd_ovlrun	ds.b	2*OVLRUNS*8
rd_ovlrpn	ds.w	1
rd_ovlrst	ds.b	1
	even
rd_ovlgen	ds.l	1
rd_ovlbg	ds.l	32
rd_ovlkey	ds.l	1
rd_tcb		ds.b	2048
	cnop	0,4
rd_oplists	ds.b	(NBUF+1)*OPMAX*OPREC
rd_octab	ds.l	8*OBJSLOTS
rd_opold	ds.l	NBUF
rd_opoldn	ds.w	NBUF
rd_opnew	ds.l	1
rd_opn		ds.w	1
rd_opbox	ds.l	1
rd_imgpos	ds.l	1
rd_wmap		ds.l	DROWS
rd_rmask	ds.l	1
rd_opkeep	ds.b	OPMAX
rd_ophb		ds.w	OPHASH
rd_ophn		ds.w	OPMAX
rd_bpn		ds.w	1
rd_bpset	ds.l	BMAX/32
rd_bpcn		ds.l	2
rd_bpcv		ds.l	2
rd_bpcp		ds.l	2
rd_bptmp	ds.l	4
rd_omemo	ds.b	80*128
rd_omcap	ds.l	1
rd_oplk		ds.w	1
rd_stage	ds.b	1
	even
rd_c0		ds.w	1
rd_ncol		ds.w	1
rd_wb		ds.w	1
rd_mkset	ds.l	BMAX/32
rd_cellmk	ds.b	1
rd_cellmw	ds.b	1
	cnop	0,4
rd_zero8	ds.b	8
	cnop	0,4
rd_sbuild	ds.l	2*4*NPLANES*32/4
rd_oent		ds.l	1
rd_opx		ds.l	1
rd_objbn	ds.w	1
rd_objpn	ds.w	1
rd_on		ds.w	1
rd_opri		ds.w	1
rd_ox0		ds.w	1
rd_oy0		ds.w	1
rd_ominx	ds.w	1
rd_ominy	ds.w	1
rd_oscw		ds.w	1
rd_osch		ds.w	1
rd_owb		ds.w	1
rd_olines	ds.w	1
rd_opw		ds.w	1
rd_oplines	ds.w	1
rd_opat		ds.w	1
rd_okey		ds.w	1
rd_oovl		ds.b	1
	even
rd_opline	ds.l	1
rd_objb		ds.b	4*OBJMAX
rd_objp		ds.b	4*OBJMAX
rd_sprgkey	ds.w	80
rd_sprgend	ds.b	80
rd_sprnsq	ds.b	1
	cnop	0,4
rd_opc		ds.b	12*OBJPC
rd_oscr		ds.b	56*64
rd_opbuf	ds.b	20*32
rd_r0		ds.w	1
rd_r1		ds.w	1
		cnop	0,4
rd_fpsv		ds.w	1
		cnop	0,4
rd_fpst		ds.l	1
rd_fpsc		ds.l	1
		cnop	0,4
rd_hsuni	ds.b	1
rd_narrow	ds.b	1
rd_hslb		ds.b	1
rd_bltch	ds.b	1
rd_bllow	ds.b	1
rd_wchg		ds.b	1
	even
rd_ovlpart	ds.l	1
rd_alistw	ds.w	1
	cnop	0,4
rd_vntA		ds.w	64*32
rd_vntB		ds.w	64*32
rd_hsb		ds.w	SCRH
rd_blent	ds.w	1
rd_blok		ds.l	1
rd_blfr		ds.l	1
rd_blmask	ds.l	32*4
rd_blcopy	ds.w	32*128
rd_blcf		ds.w	2*32
rd_bllo		ds.l	1
rd_blsb		ds.l	1
rd_blsr		ds.l	1
rd_blsrn	ds.l	1
rd_bltiles	ds.l	64
rd_blst		ds.l	4*32
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
