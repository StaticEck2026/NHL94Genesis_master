;	The crash report: when the game stops on a CPU exception (hal_exception) or no game frame has
;	run for 10 seconds (cr_watch, from the vertical blank), the screen shows what is needed to
;	find why, for a photo: the exception, the code address and registers, the stack, the CPU,
;	where the program is, and the code the last game ticks interrupted. It is drawn with the
;	ROM's topaz 8 (graphics.library's font list). The machine must be reset after it.

CR_ROWB		equ	80			;bytes a line: 640 pixels, one bitplane
CR_LH		equ	9			;lines a text row
CR_PLANE	equ	rd_scr0+1024		;(a screen buffer: chip RAM; the copper list before it)

	section	bss,bss
	cnop	0,4
cr_regs		ds.l	16			;d0-d7/a0-a7 when it stopped
cr_frame	ds.l	1			;its exception frame
cr_font		ds.l	1			;topaz 8 (0: none: no text)
cr_ticks	ds.l	1			;(cr_watch: the game ticks at its last look)
cr_why		ds.w	1			;the vector, or -1: no game frame for 10 seconds
cr_col		ds.w	1			;the cursor: column, text row
cr_row		ds.w	1
cr_wdn		ds.w	1			;(cr_watch: vertical blanks with no game tick)
		ds.b	2048
cr_stack					;(its own stack: the game's may be the trouble)

	section	game,code

;	A vertical blank (level 3, rd_bq_int): if no game tick has run for 10 seconds, the report,
;	a0 = the level 3 exception frame (d0-d1/a0-a1 saved under it). Uses d0.
cr_watch
	tst.b	(hal_amiga).l			;(the test harness watches itself)
	beq.s	.x
	move.l	(hal_frames).l,d0
	cmp.l	(cr_ticks).l,d0
	beq.s	.same
	move.l	d0,(cr_ticks).l
	clr.w	(cr_wdn).l
.x	rts
.same	addq.w	#1,(cr_wdn).l
	cmpi.w	#10*60,(cr_wdn).l
	blo.s	.x
	move	#$2700,sr
	movem.l	d0-d7/a0-a7,(cr_regs).l
	move.l	-16(a0),(cr_regs).l		;(d0, d1, a0, a1 as they were: saved under the frame)
	move.l	-12(a0),(cr_regs+4).l
	move.l	-8(a0),(cr_regs+8*4).l
	move.l	-4(a0),(cr_regs+9*4).l
	lea	8(a0),a1
	move.l	a1,(cr_regs+15*4).l		;(a7 before the interrupt)
	moveq	#-1,d0
	bra.s	cr_show2

;	The report: d0 = the vector of the exception, a0 = its frame, the registers in hal_exc_regs.
cr_show
	lea	(hal_exc_regs).l,a1
	lea	(cr_regs).l,a2
	moveq	#16-1,d1
.c	move.l	(a1)+,(a2)+
	dbf	d1,.c
cr_show2
	move	#$2700,sr
	move.w	d0,(cr_why).l
	move.l	a0,(cr_frame).l
	move.w	#$0F00,(CUSTOM+$180).l		;red (the test harness stops at this)
	tst.b	(hal_amiga).l
	beq	.hang
	lea	(cr_stack).l,sp
	move.w	#$7FFF,(CUSTOM+INTENA).l
	move.w	#$7FFF,(CUSTOM+DMACON).l	;all DMA off: the copper, the blitter, sprites, sound
	bsr	cr_findfont
	; the screen: 640 x 256, one bitplane, white on dark red
	lea	(CR_PLANE).l,a0
	move.w	#CR_ROWB*256/4-1,d0
.cl	clr.l	(a0)+
	dbf	d0,.cl
	lea	(rd_scr0).l,a0
	lea	(.cop,pc),a1
.cc	move.l	(a1)+,(a0)+
	bne.s	.cc
	subq.l	#4,a0
	move.l	#CR_PLANE,d0
	move.w	#$00E0,(a0)+
	swap	d0
	move.w	d0,(a0)+
	move.w	#$00E2,(a0)+
	swap	d0
	move.w	d0,(a0)+
	move.l	#$FFFFFFFE,(a0)
	move.l	#rd_scr0,(CUSTOM+$080).l	;COP1LC
	move.w	d0,(CUSTOM+$088).l		;COPJMP1
	move.w	#$8380,(CUSTOM+DMACON).l	;DMA on: bitplanes, copper
	bsr	cr_text
.hang	bra.s	.hang
.cop	dc.l	$01FC0000,$01060000,$010C0011	;FMODE 0, BPLCON3, BPLCON4
	dc.l	$008E2C81,$00902CC1,$0092003C,$009400D4	;DIWSTRT, DIWSTOP, DDFSTRT, DDFSTOP
	dc.l	$01009200,$01020000,$01040000	;BPLCON0: hires, 1 plane; BPLCON1, 2
	dc.l	$01080000,$010A0000		;modulos
	dc.l	$01800600,$01820FFF		;colours
	dc.l	0

;	cr_font = the ROM's topaz 8 from graphics.library's font list (or its default font if that is
;	8 or 9 lines high and not proportional), 0 if neither.
cr_findfont
	clr.l	(cr_font).l
	move.l	(os_gfx).l,d0
	beq.s	.x
	movea.l	d0,a0
	movea.l	$8C(a0),a1			;gb_TextFonts: its first
.n	tst.l	(a1)				;(ln_Succ 0: the list's end)
	beq.s	.def
	cmpi.w	#8,$14(a1)			;tf_YSize
	bne.s	.nx
	movea.l	10(a1),a2			;ln_Name
	lea	(.topaz,pc),a3
.c	move.b	(a2)+,d1
	cmp.b	(a3)+,d1
	bne.s	.nx
	tst.b	d1
	bne.s	.c
	move.l	a1,(cr_font).l
	rts
.nx	movea.l	(a1),a1
	bra.s	.n
.def	movea.l	$9A(a0),a1			;gb_DefaultFont
	cmpi.w	#CR_LH,$14(a1)
	bhi.s	.x
	btst	#5,$17(a1)			;FPF_PROPORTIONAL
	bne.s	.x
	cmpi.w	#8,$18(a1)			;tf_XSize
	bhi.s	.x
	move.l	a1,(cr_font).l
.x	rts
.topaz	dc.b	'topaz.font',0
	even

;	The report's text.
cr_text
	clr.l	(cr_col).l
	lea	(buildver+6,pc),a0		;(build.i: "NHL94 b<number> (<commit>)")
	bsr	cr_puts
	lea	(.t0,pc),a0
	bsr	cr_puts
	move.w	#2,(cr_row).l
	; why
	clr.w	(cr_col).l
	move.w	(cr_why).l,d0
	bpl.s	.ex
	lea	(.tfrz,pc),a0
	bsr	cr_puts
	bra.s	.w1
.ex	lea	(.tvec,pc),a0
.vn	move.b	(a0)+,d1			;the names: vector, text, 0
	beq.s	.vg
	cmp.b	d0,d1
	beq.s	.vf
.vs	tst.b	(a0)+
	bne.s	.vs
	bra.s	.vn
.vg	lea	(.texc,pc),a0
	bra.s	.vp
.vf
.vp	bsr	cr_puts
	lea	(.tvn,pc),a0
	bsr	cr_puts
	moveq	#0,d0
	move.w	(cr_why).l,d0
	moveq	#2,d1
	bsr	cr_hex
	moveq	#')',d0
	bsr	cr_putc
.w1	; where
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
	movea.l	(cr_frame).l,a2
	lea	(.tpc,pc),a0
	bsr	cr_puts
	move.l	2(a2),d0
	moveq	#8,d1
	bsr	cr_hex
	lea	(.tsr,pc),a0
	bsr	cr_puts
	moveq	#0,d0
	move.w	(a2),d0
	moveq	#4,d1
	bsr	cr_hex
	lea	(.tfmt,pc),a0
	bsr	cr_puts
	moveq	#0,d0
	move.b	6(a2),d0
	lsr.b	#4,d0
	moveq	#1,d1
	bsr	cr_hex
	lea	(.tgame,pc),a0
	tst.b	(ctx_cur).l
	beq.s	.g
	lea	(.trend,pc),a0
.g	bsr	cr_puts
	; the program and the CPU
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
	lea	(.tcode,pc),a0
	bsr	cr_puts
	lea	(hal_header,pc),a0
	move.l	a0,d0
	moveq	#8,d1
	bsr	cr_hex
	lea	(.tdata,pc),a0
	bsr	cr_puts
	move.l	#bss_start,d0
	moveq	#8,d1
	bsr	cr_hex
	lea	(.twin,pc),a0
	bsr	cr_puts
	move.l	#RAMBASE,d0
	moveq	#8,d1
	bsr	cr_hex
	lea	(.tcpu,pc),a0
	bsr	cr_puts
	movea.l	(4).w,a0
	move.w	$128(a0),d2			;AttnFlags
	lea	(.t060,pc),a0
	btst	#7,d2
	bne.s	.cp
	lea	(.t040,pc),a0
	btst	#3,d2
	bne.s	.cp
	lea	(.t030,pc),a0
	btst	#2,d2
	bne.s	.cp
	lea	(.t020,pc),a0
.cp	bsr	cr_puts
	lea	(.tfl,pc),a0
	bsr	cr_puts
	moveq	#0,d0
	move.w	d2,d0
	moveq	#4,d1
	bsr	cr_hex
	moveq	#')',d0
	bsr	cr_putc
	; registers
	move.w	#5,(cr_row).l
	lea	(cr_regs).l,a2
	moveq	#'D',d3
	bsr	.regs
	moveq	#'A',d3
	bsr	.regs
	; the stack from the frame on
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
	lea	(.tstk,pc),a0
	bsr	cr_puts
	movea.l	(cr_frame).l,a2
	moveq	#4-1,d3
	bsr	.longs
	; the code the last game ticks interrupted
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
	lea	(.ttck,pc),a0
	bsr	cr_puts
	lea	(hal_pcring).l,a2
	moveq	#2-1,d3
	bsr	.longs
	; counts
	addq.w	#2,(cr_row).l
	clr.w	(cr_col).l
	lea	(.tcnt,pc),a0
	bsr	cr_puts
	move.l	(hal_frames).l,d0
	moveq	#8,d1
	bsr	cr_hex
	lea	(.tfrm,pc),a0
	bsr	cr_puts
	move.l	(rd_count).l,d0
	moveq	#8,d1
	bsr	cr_hex
	lea	(.tvb,pc),a0
	bsr	cr_puts
	move.l	(rd_vblanks).l,d0
	moveq	#8,d1
	bsr	cr_hex
	addq.w	#2,(cr_row).l
	clr.w	(cr_col).l
	lea	(.treset,pc),a0
	bra	cr_puts
.regs	moveq	#0,d4				;d3 = 'D' or 'A', a2 = its 8 registers: two rows of 4
.r	move.w	d4,d0
	andi.w	#3,d0
	bne.s	.r1
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
.r1	move.b	d3,d0
	bsr	cr_putc
	moveq	#'0',d0
	add.b	d4,d0
	bsr	cr_putc
	moveq	#' ',d0
	bsr	cr_putc
	move.l	(a2)+,d0
	moveq	#8,d1
	bsr	cr_hex
	addq.w	#3,(cr_col).l
	addq.w	#1,d4
	cmpi.w	#8,d4
	blo.s	.r
	rts
.longs	addq.w	#1,(cr_row).l			;d3 + 1 rows of 8 longs from a2
	clr.w	(cr_col).l
	moveq	#8-1,d4
.l	move.l	(a2)+,d0
	moveq	#8,d1
	bsr	cr_hex
	addq.w	#1,(cr_col).l
	dbf	d4,.l
	dbf	d3,.longs
	rts
.t0	dc.b	' stopped. Please photograph this screen and send it.',0
.tfrz	dc.b	'No game frame for 10 seconds: it is stuck (the code below is where)',0
.texc	dc.b	'CPU exception',0
.tvn	dc.b	' (vector $',0
.tvec	dc.b	2,'Bus error / access fault',0,3,'Address error',0,4,'Illegal instruction',0
	dc.b	5,'Divide by zero',0,6,'CHK',0,7,'TRAPV',0,8,'Privilege violation',0
	dc.b	9,'Trace',0,10,'Line A instruction',0,11,'Line F instruction (FPU / MMU)',0
	dc.b	14,'Format error',0,15,'Uninitialised interrupt',0,24,'Spurious interrupt',0
	dc.b	60,'Unimplemented effective address',0,61,'Unimplemented integer instruction',0
	dc.b	0
.tpc	dc.b	'PC ',0
.tsr	dc.b	'   SR ',0
.tfmt	dc.b	'   frame format ',0
.tgame	dc.b	'   in the game',0
.trend	dc.b	'   in the renderer',0
.tcode	dc.b	'Code ',0
.tdata	dc.b	'   data ',0
.twin	dc.b	'   RAM window ',0
.tcpu	dc.b	'   CPU ',0
.t020	dc.b	'68020',0
.t030	dc.b	'68030',0
.t040	dc.b	'68040',0
.t060	dc.b	'68060',0
.tfl	dc.b	' (AttnFlags ',0
.tstk	dc.b	'Stack from the frame on:',0
.ttck	dc.b	'Code the last game ticks interrupted:',0
.tcnt	dc.b	'Game ticks ',0
.tfrm	dc.b	'   frames drawn ',0
.tvb	dc.b	'   vertical blanks ',0
.treset	dc.b	'The Amiga must be reset.',0
	even

;	The text at a0 (0 ended) at the cursor. Keeps all but a0.
cr_puts	move.l	d0,-(sp)
.n	move.b	(a0)+,d0
	beq.s	.x
	bsr.s	cr_putc
	bra.s	.n
.x	move.l	(sp)+,d0
	rts

;	d0 in hex, d1 digits, at the cursor. Keeps all.
cr_hex	movem.l	d0-d2,-(sp)
	move.l	d0,d2
	moveq	#8,d0
	sub.w	d1,d0
	lsl.w	#2,d0
	rol.l	d0,d2				;(the first digit wanted on top)
	subq.w	#1,d1
.d	rol.l	#4,d2
	moveq	#15,d0
	and.w	d2,d0
	move.b	(.hx,pc,d0.w),d0
	bsr.s	cr_putc
	dbf	d1,.d
	movem.l	(sp)+,d0-d2
	rts
.hx	dc.b	'0123456789ABCDEF'

;	Character d0.b at the cursor, which moves on. Keeps all.
cr_putc	movem.l	d0-d5/a0-a2,-(sp)
	move.l	(cr_font).l,d1
	beq	.n
	cmpi.w	#CR_ROWB,(cr_col).l
	bhs	.n				;(past the line's end)
	movea.l	d1,a1
	moveq	#0,d1
	move.b	d0,d1
	moveq	#0,d2
	move.b	$20(a1),d2			;tf_LoChar
	sub.w	d2,d1
	bcs	.n
	moveq	#0,d2
	move.b	$21(a1),d2			;tf_HiChar
	sub.b	$20(a1),d2
	cmp.w	d2,d1
	bhi	.n
	movea.l	$28(a1),a2			;tf_CharLoc: bit offset, bit width
	move.w	(a2,d1.w*4),d3
	ext.l	d3
	move.w	2(a2,d1.w*4),d4
	cmpi.w	#8,d4
	bls.s	.w
	moveq	#8,d4
.w	move.w	#$FF00,d2
	lsr.w	d4,d2				;(its width's bits of a byte: the low byte)
	movea.l	$22(a1),a2			;tf_CharData
	lea	(CR_PLANE).l,a0
	move.w	(cr_row).l,d5
	mulu.w	#CR_LH*CR_ROWB,d5
	adda.l	d5,a0
	adda.w	(cr_col).l,a0
	moveq	#0,d5
	move.w	$26(a1),d5			;tf_Modulo
	lsl.l	#3,d5				;(bits)
	move.w	$14(a1),d1			;tf_YSize
	cmpi.w	#CR_LH,d1
	bls.s	.h
	moveq	#CR_LH,d1
.h	subq.w	#1,d1
.y	bfextu	(a2){d3:8},d0
	and.b	d2,d0
	move.b	d0,(a0)
	lea	CR_ROWB(a0),a0
	add.l	d5,d3
	dbf	d1,.y
.n	addq.w	#1,(cr_col).l
	movem.l	(sp)+,d0-d5/a0-a2
	rts

	include	"build.i"			;(buildver: the build's number and commit)
	even
