;	The crash report: when the game stops on a CPU exception (hal_exception), no game frame has
;	run for 10 seconds, only interrupts have run for 10 seconds, or the game has changed the
;	picture but none has been drawn for 10 seconds (cr_watch, from the vertical blank), the
;	screen shows what is needed to find why, for a photo: the exception, the code address and
;	registers (the renderer's if the picture stopped), the stack, the CPU, where the program
;	is, the code the last game ticks interrupted, the interrupts counted, and the state of the
;	renderer's blit queue and shows. It is drawn with the ROM's topaz 8 (graphics.library's
;	font list). The machine must be reset after it.

CR_ROWB		equ	80			;bytes a line: 640 pixels, one bitplane
CR_LH		equ	9			;lines a text row
CR_PLANE	equ	rd_scr0+1024		;(a screen buffer: chip RAM; the copper list before it)

	section	bss,bss
	cnop	0,4
cr_regs		ds.l	16			;d0-d7/a0-a7 when it stopped
cr_frame	ds.l	1			;its exception frame
cr_font		ds.l	1			;topaz 8 (0: none: no text)
cr_ticks	ds.l	1			;(cr_watch: the game ticks at its last look)
cr_rdc		ds.l	1			;(cr_watch: frames drawn at its last look,
cr_rdgen	ds.l	1			;and ds_gen when that changed)
cr_vpos		ds.l	1			;VPOSR, VHPOSR,
cr_intreq	ds.w	1			;INTREQR, DMACONR when it stopped
cr_dmacon	ds.w	1
cr_intena	ds.w	1			;and INTENAR
cr_busy		ds.b	1			;(the report is being drawn: cr_nested)
cr_nest		ds.b	1
cr_why		ds.w	1			;the vector, or -1: no game frame for 10 seconds, -2: no
						;picture drawn for 10 seconds while the game changed it,
						;-3: ticks but no code outside interrupts for 10 seconds
cr_col		ds.w	1			;the cursor: column, text row
cr_row		ds.w	1
cr_wdn		ds.w	1			;(cr_watch: vertical blanks with no game tick,
cr_rdn		ds.w	1			;and with no picture drawn, one due,
cr_mn		ds.w	1			;and ticks with no code outside interrupts run,
cr_xn		ds.w	1			;and vertical blanks since cr_x0 was taken)
	cnop	0,4
cr_ipl0		ds.l	1			;(cr_watch: hal_ipl0 at its last look,
cr_x0		ds.l	1			;and the interrupts not used counted then)
		ds.b	2048
cr_stack					;(its own stack: the game's may be the trouble)

	section	game,code

;	A vertical blank (level 3, rd_bq_int): the report if no game tick has run for 10 seconds,
;	the ticks go on but neither the game's code outside them nor the renderer has run for 10
;	seconds (hal_ipl0: an interrupt that never stops asking takes the CPU), more than 10000
;	interrupts the game does not use came in 10 seconds (the same, the code creeping on
;	between them), or no picture has been drawn for 10 seconds while the game changed it
;	(ds_gen), a0 = the level 3 exception frame (d0-d1/a0-a1 saved under it). Uses d0.
cr_watch
	tst.b	(hal_amiga).l			;(the test harness watches itself)
	beq	.x
	; interrupts the game does not use, more than 10000 in 10 seconds: one that never stops
	; asking, even if the code outside interrupts still creeps on between them
	addq.w	#1,(cr_xn).l
	cmpi.w	#10*50,(cr_xn).l		;(vertical blanks: 50 or 60 a second)
	blo.s	.xw
	clr.w	(cr_xn).l
	move.l	(hal_intx).l,d0
	add.l	(hal_int6x).l,d0
	sub.l	(cr_x0).l,d0
	cmpi.l	#10000,d0
	bhi	.main
	add.l	d0,(cr_x0).l
.xw	move.l	(hal_frames).l,d0
	cmp.l	(cr_ticks).l,d0
	beq.s	.same
	move.l	d0,(cr_ticks).l
	clr.w	(cr_wdn).l
	move.l	(hal_ipl0).l,d0			;a tick: the code outside the interrupts since?
	cmp.l	(cr_ipl0).l,d0
	beq.s	.msame
	move.l	d0,(cr_ipl0).l
	clr.w	(cr_mn).l
	bra.s	.pic
.msame	addq.w	#1,(cr_mn).l
	cmpi.w	#10*50,(cr_mn).l		;(ticks: 50 or 60 a second)
	bhs	.main
	bra.s	.pic
.same	addq.w	#1,(cr_wdn).l
	cmpi.w	#10*60,(cr_wdn).l
	bhs	.game
.pic	move.l	(rd_count).l,d0
	cmp.l	(cr_rdc).l,d0
	beq.s	.psame
	move.l	d0,(cr_rdc).l
	move.l	(ds_gen).l,(cr_rdgen).l
	clr.w	(cr_rdn).l
.x	rts
.psame	move.l	(ds_gen).l,d0
	cmp.l	(cr_rdgen).l,d0
	beq.s	.x				;(nothing new to draw)
	addq.w	#1,(cr_rdn).l
	cmpi.w	#10*60,(cr_rdn).l
	blo.s	.x
	; the picture stopped: where the renderer is (this interrupt's frame if it was running,
	; else its context, saved under its frame: ctx_to_game)
	move	#$2700,sr
	bsr	cr_hw
	tst.b	(ctx_cur).l
	bne.s	.rhere
	movea.l	(ctx_rend_sp).l,a1
	lea	(cr_regs).l,a2
	moveq	#15-1,d0
.rc	move.l	(a1)+,(a2)+
	dbf	d0,.rc
	movea.l	a1,a0				;its frame
	lea	8(a0),a1
	move.l	a1,(a2)				;(a7)
	moveq	#-2,d0
	bra	cr_show2
.rhere	moveq	#-2,d0
	bra.s	.regs
.main	move	#$2700,sr
	bsr	cr_hw
	moveq	#-3,d0
	bra.s	.regs
.game	move	#$2700,sr
	bsr	cr_hw
	moveq	#-1,d0
.regs	movem.l	d0-d7/a0-a7,(cr_regs).l
	move.l	-16(a0),(cr_regs).l		;(d0, d1, a0, a1 as they were: saved under the frame)
	move.l	-12(a0),(cr_regs+4).l
	move.l	-8(a0),(cr_regs+8*4).l
	move.l	-4(a0),(cr_regs+9*4).l
	lea	8(a0),a1
	move.l	a1,(cr_regs+15*4).l		;(a7 before the interrupt)
	bra.s	cr_show2

;	The custom chips' state as it stopped (before cr_show2 turns DMA off). Keeps all.
cr_hw	move.l	(CUSTOM+$004).l,(cr_vpos).l	;VPOSR, VHPOSR
	move.w	(CUSTOM+INTREQR).l,(cr_intreq).l
	move.w	(CUSTOM+DMACONR).l,(cr_dmacon).l
	move.w	(CUSTOM+INTENAR).l,(cr_intena).l
	rts

;	The report: d0 = the vector of the exception, a0 = its frame, the registers in hal_exc_regs.
cr_show
	tst.b	(cr_busy).l
	bne	cr_nested
	bsr	cr_hw
	lea	(hal_exc_regs).l,a1
	lea	(cr_regs).l,a2
	moveq	#16-1,d1
.c	move.l	(a1)+,(a2)+
	dbf	d1,.c
cr_show2
	move	#$2700,sr
	st	(cr_busy).l
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

;	An exception while the report is drawn: the rest of it is not drawn, but this one's vector,
;	frame and where the report had got to, on the last row (cr_putc does not fault: it drew
;	what is above). d0 = the vector, a0 = its frame.
cr_nested
	lea	(cr_stack).l,sp
	addq.b	#1,(cr_nest).l
	cmpi.b	#1,(cr_nest).l
	bne.s	.hang				;(a fault in this too)
	move.l	a0,a2
	move.w	d0,d2
	move.w	#27,(cr_row).l
	clr.w	(cr_col).l
	lea	(.tn,pc),a0
	bsr	cr_puts
	moveq	#0,d0
	move.w	d2,d0
	moveq	#2,d1
	bsr	cr_hex
	moveq	#' ',d0
	bsr	cr_putc
	moveq	#6-1,d3
.f	move.l	(a2)+,d0
	moveq	#8,d1
	bsr	cr_hex
	moveq	#' ',d0
	bsr	cr_putc
	dbf	d3,.f
.hang	bra.s	.hang
.tn	dc.b	'Fault in the report: vector $',0
	even

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
	addq.w	#1,d0
	beq.s	.fz
	lea	(.tpic,pc),a0
	addq.w	#1,d0
	beq.s	.fz
	lea	(.tmain,pc),a0
.fz	bsr	cr_puts
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
	lea	(.trend,pc),a0
	cmpi.w	#-2,(cr_why).l			;(the picture stopped: the renderer's)
	beq.s	.g
	tst.b	(ctx_cur).l
	bne.s	.g
	lea	(.tgame,pc),a0
.g	bsr	cr_puts
	lea	(.tcacr,pc),a0			;(the caches: a 68060 started from a floppy has no
	bsr	cr_puts				;68060.library to set them)
	movec	cacr,d0
	moveq	#8,d1
	bsr	cr_hex
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
	movea.l	(os_exec).l,a0			;(not (4).w: an MMU may guard page 0, its handler gone)
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
	move.w	#4,(cr_row).l
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
	addq.w	#1,(cr_row).l
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
	; the renderer's blit queue and shows
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
	lea	(.tstate,pc),a2
.st	move.w	(a2)+,d2			;digits (0: the table's end; -1: a new row)
	beq.s	.ste
	bpl.s	.st1
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
	bra.s	.st
.st1	movea.l	a2,a0				;its name
.sn	tst.b	(a2)+
	bne.s	.sn
	move.l	a2,d0
	addq.l	#1,d0
	andi.w	#-2,d0
	movea.l	d0,a2
	movea.l	(a2)+,a1			;its address
	bsr	cr_puts
	moveq	#' ',d0
	bsr	cr_putc
	moveq	#0,d0
	move.w	d2,d1
	cmpi.w	#2,d2
	bne.s	.s4
	move.b	(a1),d0
	bra.s	.sp
.s4	cmpi.w	#4,d2
	bne.s	.s8
	move.w	(a1),d0
	bra.s	.sp
.s8	move.l	(a1),d0
.sp	bsr	cr_hex
	addq.w	#2,(cr_col).l
	bra.s	.st
.ste	; the copper ring where the copper stops, the show taken last and the next queued
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
	lea	(.tring,pc),a0
	bsr	cr_puts
	movea.l	(rd_cqwp).l,a2
	subq.l	#8,a2
	moveq	#6-1,d4
.rg	move.l	(a2)+,d0
	moveq	#8,d1
	bsr	cr_hex
	addq.w	#1,(cr_col).l
	dbf	d4,.rg
	addq.w	#1,(cr_row).l
	clr.w	(cr_col).l
	lea	(.tmark,pc),a0
	moveq	#-1,d2
	bsr	.show
	lea	(.tmnx,pc),a0
	moveq	#0,d2
	bsr	.show
	addq.w	#2,(cr_row).l
	clr.w	(cr_col).l
	lea	(.treset,pc),a0
	bra	cr_puts
.show	bsr	cr_puts				;show marker rd_cqmh + d2 (its place, where the copper
	add.w	(rd_cqmh).l,d2			;goes on, its copper list, its buffer)
	andi.w	#7,d2
	lsl.w	#4,d2
	lea	(rd_cqmq).l,a2
	adda.w	d2,a2
	moveq	#3-1,d4
.mk	move.l	(a2)+,d0
	moveq	#8,d1
	bsr	cr_hex
	addq.w	#1,(cr_col).l
	dbf	d4,.mk
	moveq	#0,d0
	move.w	(a2),d0
	moveq	#2,d1
	bra	cr_hex
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
.tpic	dc.b	'No picture drawn for 10 seconds while the game runs (the renderer is where)',0
.tmain	dc.b	'An interrupt that never stops has the CPU (10 seconds; the code below)',0
.texc	dc.b	'CPU exception',0
.tvn	dc.b	' (vector $',0
.tvec	dc.b	2,'Bus error / access fault',0,3,'Address error',0,4,'Illegal instruction',0
	dc.b	5,'Divide by zero',0,6,'CHK',0,7,'TRAPV',0,8,'Privilege violation',0
	dc.b	9,'Trace',0,10,'Line A instruction',0,11,'Line F instruction (FPU / MMU)',0
	dc.b	14,'Format error',0,15,'Uninitialised interrupt',0,24,'Spurious interrupt',0
	dc.b	60,'Unimplemented effective address',0,61,'Unimplemented integer instruction',0
	dc.b	0
.tpc	dc.b	'PC ',0
.tcacr	dc.b	'   CACR ',0
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
.tring	dc.b	'Ring at the stop: ',0
.tmark	dc.b	'Shows: last ',0
.tmnx	dc.b	'  next ',0
	even
;	digits, name, (even) address; -1 a new row, 0 the end
CRS	MACRO
	dc.w	\1
	dc.b	\2,0
	even
	dc.l	\3
	ENDM
.tstate	CRS	4,'INTREQ',cr_intreq
	CRS	4,'INTENA',cr_intena
	CRS	4,'DMACON',cr_dmacon
	CRS	8,'VPOS',cr_vpos
	CRS	2,'ctx',ctx_cur
	CRS	2,'busy',rd_busy
	CRS	4,'bufi',rd_bufi
	dc.w	-1
	CRS	2,'idle',rd_cqidle
	CRS	2,'batch',rd_cqbat
	CRS	8,'ring',rd_cqring
	CRS	8,'stop',rd_cqwp
	CRS	8,'done',rd_cqdp
	CRS	4,'free',rd_cqfree
	dc.w	-1
	CRS	4,'marks',rd_cqmh
	CRS	4,'to',rd_cqmt
	CRS	8,'show',rd_showcop
	CRS	4,'its buffer',rd_showbuf
	CRS	2,'held',rd_bqhold
	CRS	8,'set at',rd_lastset
	dc.w	-1
	CRS	8,'shown at',rd_shownvb
	CRS	8,'',rd_shownvb+4
	CRS	8,'',rd_shownvb+8
	CRS	8,'last frame',rd_lastframe
	CRS	8,'pace',hal_pace
	dc.w	-1
	CRS	8,'states from',rd_snapvb
	CRS	8,'',rd_snapvb+4
	CRS	8,'',rd_snapvb+8
	CRS	2,'ahead',hal_ahead
	CRS	8,'tick at',hal_tickvb
	dc.w	-1
	CRS	8,'other ints',hal_intx
	CRS	8,'last',hal_intxv
	CRS	8,'level 6 others',hal_int6x
	CRS	8,'main',hal_ipl0
	dc.w	0

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
