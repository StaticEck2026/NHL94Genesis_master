;	remap, forceblack, forcefade, cramfade, CopyPaletteToCRAM, randomd0s /
;	randomd0, sroot, sfx, song, waitx, waitxsr, waitjoy, orjoy, nodiag,
;	ProcessInputWithRepeat, ReadJoy1-4, ReadJoy, jdtab, DoDMApro, DoDMA,
;	DoDMA_nd2, DoFill, WaitDMA, setVram and Vmaddr.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.

remap
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d4/a0-a2,-(sp)
	exg	d1,d0
	movea.l	a0,a2
	bsr.w	Vmaddr
	subq.w	#1,d1
.1
	moveq	#3,d0
	move.w	(a2)+,d2
	clr.w	d3
.11
	move.w	d2,d4
	andi.w	#$F,d4
	lsr.w	#1,d4
	move.b	0(a1,d4.w),d4
	btst	#0,d2
	bne.w	.2
	lsr.w	#4,d4
.2
	andi.w	#$F,d4
	or.b	d4,d3
	ror.w	#4,d3
	ror.w	#4,d2
	dbf	d0,.11
	move.w	d3,(a0)
	dbf	d1,.1
	movem.l	(sp)+,d0-d4/a0-a2
	move.w	(sp)+,(disflags).w
	rts
; fade all colors to black but don't upset palfadenew
forceblack
	movem.l	d0/a0,-(sp)
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$1F,d0
.0
	move.l	(a0),-(sp)
	clr.l	(a0)+
	dbf	d0,.0
	move.w	#$18,(palcount).w
	bsr.w	forcefade
	moveq	#$1F,d0
.1
	move.l	(sp)+,-(a0)
	dbf	d0,.1
	movem.l	(sp)+,d0/a0
	rts
forceblack2	;fade to black, keeping palfadenew (saved on the stack and restored)
	movem.l	d0/a0,-(sp)
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$1F,d0
.loop
	move.l	(a0),-(sp)
	clr.l	(a0)+
	dbf	d0,.loop
	move.w	#$64,(palcount).w
	bsr.w	forcefade
	moveq	#$1F,d0
.loop2
	move.l	(sp)+,-(a0)
	dbf	d0,.loop2
	movem.l	(sp)+,d0/a0
	rts
forcefade	;regardless of interupts/disflags fade in new palettes, don't upset anything else
	move	sr,-(sp)
	move.l	(vbint).w,-(sp)
	move.w	(disflags).w,-(sp)
	bclr	#dfng,(disflags).w
	move.l	#vb2,(vbint).l
	move	#$2500,sr
.1
	tst.w	(palcount).w
	bpl.s	.1
	move.w	(sp)+,(disflags).w
	move.l	(sp)+,(vbint).w
	move	(sp)+,sr
	rts
; fade from current color in color ram to color held in palfadenew
; this should be called during vblank because palette changes punch holes in video
cramfade
	tst.w	(palcount).w
	bmi.w	rtss2
	cmpi.w	#$64,(palcount).w
	beq.w	CopyPaletteToCRAM
	subq.w	#1,(palcount).w
	bmi.w	rtss2
	clr.l	d0
	move.w	(palcount).w,d0
	cmp.w	#$18,d0
	bgt.w	rtss2
	divu.w	#3,d0
	swap	d0
	asl.w	#2,d0
	moveq	#2,d3
	asl.w	d0,d3
	moveq	#$E,d5
	asl.w	d0,d5
	move.w	d5,d4
	not.w	d4
	movea.l	#palfadenew,a1
	movea.l	#VDP_DATA,a0
	clr.w	d6
.top
	move.w	d3,d2
	move.w	d6,d0
	swap	d0
	move.w	#$20,d0
	move.l	d0,Vctrl-Vdata(a0)
	move.w	(a0),d7
	move.w	d7,d0
	and.w	d5,d0
	move.w	(a1)+,d1
	and.w	d5,d1
	cmp.w	d1,d0
	beq.w	.next
	blt.w	.nn
	neg.w	d2
.nn
	add.w	d2,d0
	and.w	d4,d7
	or.w	d0,d7
	move.l	#$C000,d0
	move.b	d6,d0
	swap	d0
	move.l	d0,Vctrl-Vdata(a0)
	move.w	d7,(a0)
.next
	addq.w	#2,d6
	cmp.w	#$80,d6
	bne.s	.top
	rts
CopyPaletteToCRAM	;Copy all 64 palfadenew colours to colour ram, protected from vblank
	movem.l	d0/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movea.w	#(palfadenew-M68K_RAM),a1
	movea.l	#VDP_DATA,a0
	move.l	#CRAM_W,Vctrl-Vdata(a0)
	moveq	#$1F,d0
.0
	move.l	(a1)+,(a0)
	dbf	d0,.0
	st	(palcount).w
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0/a0-a1
	rts
; d0 = range
; return d0 = random number (-range < d0 < range)
randomd0s
	move.w	d0,-(sp)
	asl.w	#1,d0
	bsr.w	randomd0
	sub.w	(sp)+,d0
	rts
; d0 = range
; return random number in d0 (0 <= d0 < range)
randomd0
	movem.l	d0-d2,-(sp)
	move.w	(seed+2).w,d0
	move.w	d0,d1
	move.w	(seed).w,d2
	mulu.w	#$E62D,d0
	mulu.w	#$BB40,d1
	mulu.w	#$E62D,d2
	add.w	d2,d1
	swap	d0
	add.w	d1,d0
	swap	d0
	addq.l	#1,d0
	move.l	d0,(seed).w
	asr.l	#8,d0
	mulu.w	2(sp),d0
	swap	d0
	addq.w	#4,sp
	movem.l	(sp)+,d1-d2
	rts
; returns d0.L^.5 in d0
sroot
	tst.l	d0
	beq.w	rtss2	;zero^.5 = zero
	cmp.l	#$640,d0	;#40^2
	bhi.w	.m2
	move.l	d1,-(sp)
	moveq	#-1,d1	;-1
.0
	addq.w	#2,d1
	sub.w	d1,d0
	bcc.s	.0
	lsr.w	#1,d1
	move.w	d1,d0
	move.l	(sp)+,d1
	rts
.m2
	movem.l	d1-d4,-(sp)
	moveq	#9,d3	;max number of reps
	move.w	#$8000,d1
	cmp.l	#$F00000,d0
	bhi.w	.big
	move.l	d0,d1
	lsr.l	#8,d1
	addq.w	#2,d1
.top
	move.w	d1,d2
	move.l	d0,d1
	divu.w	d2,d1
	add.w	d2,d1
	lsr.w	#1,d1
	cmp.w	d1,d2
	dbeq	d3,.top
.done
	move.w	d1,d0
	movem.l	(sp)+,d1-d4
	rts
.big
	moveq	#0,d1
	moveq	#-1,d2
.bs
	move.w	d1,d3
	add.w	d2,d3
	roxr.w	#1,d3
	cmp.w	d3,d1
	beq.s	.done
	move.w	d3,d4
	mulu.w	d3,d3
	cmp.l	d3,d0
	bcc.w	.lo
	move.w	d4,d2
	bra.s	.bs
.lo
	move.w	d4,d1
	bra.s	.bs
; play sound effect number
; one word passed on stack
sfx
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	d0
	move.w	$40(sp),d0	;$40 = 16*4
	bmi.w	.none
	move.w	d0,(lastsfx).w
	jsr	(play_sfx_or_music_track).l
.none
	movem.l	(sp)+,d0-d7/a0-a6
	move.l	(sp),2(sp)
	addq.w	#2,sp
	rts
; play song number
; one word passed on stack
song
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	d0
	move.w	$40(sp),d0	;$40 = 16*4
	bmi.w	.none
	jsr	(play_sfx_or_music_track).l
.none
	movem.l	(sp)+,d0-d7/a0-a6
	move.l	(sp),2(sp)
	addq.w	#2,sp
	rts
; wait d0 vblanks or until input from either joystick
; return joystick variables (d0-d3) if any
waitx
	clr.w	(waitxpad).w
	neg.w	d0
	move.w	d0,(vcount).w
.wait
	bsr.w	ReadJoy1
	move.w	d3,(waitxpad).w
	tst.w	d1
	bne.w	rtss2
	bsr.w	ReadJoy2
	or.w	d3,(waitxpad).w
	tst.w	d1
	bne.w	rtss2
	tst.w	(FourWayPlay).w
	beq.w	.1
	bsr.w	ReadJoy3
	or.w	d3,(waitxpad).w
	tst.w	d1
	bne.w	rtss2
	bsr.w	ReadJoy4
	or.w	d3,(waitxpad).w
	tst.w	d1
	bne.w	rtss2
.1
	move.w	(vcount).w,d0
.0
	cmp.w	(vcount).w,d0
	beq.s	.0
	tst.w	d0
	bmi.s	.wait
	rts
; special version of waitx for zamboni crossing
; wait d0 vblanks or until input from either joystick
; retrun joystick variables (d0-d3) if any
waitxsr	;Wait d0 vblanks while the zamboni crosses
	movem.l	d4-d7/a0-a3,-(sp)
	neg.w	d0
	move.w	d0,(vcount).w
.wait
	cmpi.w	#$708,(zamx).w
	bhi.w	.nz
	addq.w	#1,(zamx).w
.nz
	moveq	#1,d7
	jsr	(updatecrowdf).w		;4EB8: target below $8000
	jsr	(RunArenaAnim).l
	clr.w	(pausepad).w
	bclr	#1,(sflags).w
	bsr.w	ReadJoy1
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	bne.w	.key
	clr.w	(pausepad).w
	bset	#1,(sflags).w
	bsr.w	ReadJoy2
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	bne.w	.key
	tst.w	(FourWayPlay).w
	beq.w	.vid
	bclr	#1,(sflags).w
	move.w	#3,(pausepad).w
	bsr.w	ReadJoy3
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	bne.w	.key
	tst.w	(FourWayPlay).w
	beq.w	.vid
	bset	#1,(sflags).w
	move.w	#4,(pausepad).w
	bsr.w	ReadJoy4
	bsr.w	ProcessInputWithRepeat
	tst.w	d1
	beq.w	.vid
.key
	move.w	(vcount).w,d0
	cmp.w	#$FF88,d0
	blt.w	.menu
	moveq	#$FFFFFF88,d0
.menu
	movem.w	d0,-(sp)
	jsr	(HandleMenuInput).w		;4EB8: target below $8000
	bne.w	.resume
	addq.w	#2,sp
	bset	#7,d1
	bra.w	.ex
.resume
	move.w	(sp)+,(vcount).w
.vid
	bsr.w	setvideo
	move.w	(vcount).w,d0
.0
	cmp.w	(vcount).w,d0
	beq.s	.0
	tst.w	d0
	bmi.w	.wait
.ex
	movem.l	(sp)+,d4-d7/a0-a3
	rts
; wait for either joystick input
; return d1 = new button presses
waitjoy
	move.w	(vcount).w,d0
.0
	cmp.w	(vcount).w,d0
	beq.s	.0
	bsr.w	orjoy
	beq.s	waitjoy
	rts
; return d1 = new button presses
orjoy
	tst.w	(FourWayPlay).w	;check for 4-way play?
	bne.w	.4way
	bsr.w	ReadJoy1
	move.w	d1,-(sp)
	bsr.w	ReadJoy2
	or.w	(sp)+,d1
	rts
.4way
	bsr.w	ReadJoy1
	move.w	d1,-(sp)
	bsr.w	ReadJoy2
	move.w	d1,-(sp)
	bsr.w	ReadJoy3
	move.w	d1,-(sp)
	bsr.w	ReadJoy4
	or.w	(sp)+,d1
	or.w	(sp)+,d1
	or.w	(sp)+,d1
	rts
; eliminate diagonal direction presses on d0
nodiag
	movem.l	d0/d4-d5,-(sp)
	moveq	#3,d4
	move.w	d3,d0
	andi.w	#$F,d0
	beq.w	.ok
.0
	clr.w	d5
	bset	d4,d5
	cmp.w	d5,d0
	dbeq	d4,.0
	beq.w	.ok
	andi.w	#$FFF0,d1
.ok
	movem.l	(sp)+,d0/d4-d5
	rts
ProcessInputWithRepeat	;nodiag, then key repeat on d1-d3
	bsr.s	nodiag
	tst.w	d3
	beq.w	rtss2
	tst.w	d2
	bne.w	.chg
	subq.w	#1,(repeatdelayframes).w
	bpl.w	rtss2
	move.w	#4,(repeatdelayframes).w
	move.w	d3,d1
	rts
.chg
	move.w	#$F,(repeatdelayframes).w
	rts
; Read controller 1
; return d0 = direction (bit 0-3) and new button (bit 4-7) presses
; d1 = new presses (all 8 bits)
; d2 = changed buttons (all 8)
; d3 = current held buttons (all 8)
ReadJoy1
	move.b	(pad4way1).w,d0
	bsr.w	ReadJoy
	move.w	(lj1).w,d2
	move.w	d1,(lj1).w
	move.w	d1,d3
	eor.w	d1,d2
	and.w	d2,d1
	rts
; Read controller 2
; return d0 = direction (bit 0-3) and new button (bit 4-7) presses
; d1 = new presses (all 8 bits)
; d2 = changed buttons (all 8)
; d3 = current held buttons (all 8)
ReadJoy2
	move.b	(pad4way2).w,d0
	bsr.w	ReadJoy
	move.w	(lj2).w,d2
	move.w	d1,(lj2).w
	move.w	d1,d3
	eor.w	d1,d2
	and.w	d2,d1
	rts
ReadJoy3	;read 4 way play pad 3 (pad4way3). Same returns as ReadJoy1
	move.b	(pad4way3).w,d0
	bsr.w	ReadJoy
	move.w	(lj3).w,d2
	move.w	d1,(lj3).w
	move.w	d1,d3
	eor.w	d1,d2
	and.w	d2,d1
	rts
ReadJoy4	;read 4 way play pad 4 (pad4way4). Same returns as ReadJoy1
	move.b	(pad4way4).w,d0
	bsr.w	ReadJoy
	move.w	(lj4).w,d2
	move.w	d1,(lj4).w
	move.w	d1,d3
	eor.w	d1,d2
	and.w	d2,d1
	rts
ReadJoy	;read controller a0. Return d0 = direction (bit 0-3) and new button (bit 4-7) presses, d1 = buttons down (all 8 bits)
	not.b	d0
	clr.w	d1
	move.b	d0,d1
	move.w	d1,-(sp)
	andi.w	#$F0,d0
	andi.w	#$F,d1
	movea.l	#jdtab,a0
	move.b	0(a0,d1.w),d1
	or.w	d1,d0
	move.w	(sp)+,d1
	rts
jdtab	dc.b	8
	;convert button l,r,d,u into directions 0-7,8
	dc.b	0,4,8,6,7,5,8,2,1,3,8,8,8,8,8
; init dma transfer and protect vblank interruption
; d0 = words to transfer
; d1 = initial vram address
; a0 = address to transfer from
DoDMApro
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	bsr.w	DoDMA
	move.w	(sp)+,(disflags).w
	rts
; initiate dma transfer (dma transfer bug is compensated for)
; d0 = words to transfer
; d1 = destination vram address
; a0 = source address
DoDMA
	movem.l	d2-d3/a1,-(sp)
	move.w	d0,d2
	add.w	d2,d2
	add.w	a0,d2
	bcc.w	.nd
	beq.w	.nd
	lsr.w	#1,d2	;do 2 transers if source address crosses 64k boundary
	sub.w	d2,d0
	move.w	d0,-(sp)
	bsr.w	.dd
	move.w	(sp)+,d0
	add.w	d0,d0
	add.w	d0,d1
	adda.w	d0,a0
	move.w	d2,d0
	bra.w	.nd
.dd	;(a global in ; local here, only DoDMA uses it)
	movem.l	d2-d3/a1,-(sp)
.nd
	lea	(VDP_CTRL).l,a1
	move.w	#VDPR_MODE2+$54,(a1)
	move.w	#VDPR_AUTOINC+$02,(a1)
	move.w	#$9300,d2
	move.b	d0,d2
	move.w	d2,(a1)
	move.w	#$9400,d2
	lsr.w	#8,d0
	move.b	d0,d2
	move.w	d2,(a1)
	move.l	a0,d0
	lsr.l	#1,d0
	move.w	#$9500,d2
	move.b	d0,d2
	move.w	d2,(a1)
	lsr.l	#8,d0
	move.w	#$9600,d2
	move.b	d0,d2
	move.w	d2,(a1)
	lsr.l	#8,d0
	andi.b	#$7F,d0
	move.w	#$9700,d2
	move.b	d0,d2
	move.w	d2,(a1)
	clr.l	d0
	move.w	d1,d0
	asl.l	#2,d0
	lsr.w	#2,d0
	move.l	d0,d3
	ori.l	#$804000,d0
	move.l	d0,(dmaram).w
	move	sr,-(sp)
	move	#$2700,sr
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	move.w	(dmaram+2).w,(a1)
	move.w	(dmaram).w,(a1)
	bsr.w	WaitDMA
	move.w	#VDPR_MODE2+$64,(a1)
	clr.w	(IO_Z80BUS).l
	cmpa.w	#0,a0
	bge.w	.0
	ori.w	#$4000,d3
	swap	d3
	andi.w	#3,d3
	move.l	d3,(a1)
	move.w	(a0),-4(a1)
.0
	move	(sp)+,sr
	movem.l	(sp)+,d2-d3/a1
	rts
DoDMA_nd2	;vram to vram copy by dma, protected from vblank
	movem.l	d0-d3/a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	lea	(VDP_CTRL).l,a1
	move.w	#VDPR_MODE2+$54,(a1)
	move.w	#VDPR_AUTOINC+$01,(a1)
	move.w	#$9300,d3
	move.b	d0,d3
	move.w	d3,(a1)
	move.w	#$9400,d3
	lsr.w	#8,d0
	move.b	d0,d3
	move.w	d3,(a1)
	move.w	#$9500,d3
	move.b	d2,d3
	move.w	d3,(a1)
	move.w	#$9600,d3
	lsr.w	#8,d2
	move.b	d2,d3
	move.w	d3,(a1)
	move.w	#VDPR_DMASRCH+$C0,(a1)
	clr.l	d0
	move.w	d1,d0
	asl.l	#2,d0
	lsr.w	#2,d0
	swap	d0
	ori.w	#$C0,d0
	move.l	d0,(dmaram).w
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	move.w	(dmaram).w,(a1)
	move.w	(dmaram+2).w,(a1)
	bsr.w	WaitDMA
	move.w	#VDPR_MODE2+$64,(a1)
	move.w	#VDPR_AUTOINC+$02,(a1)
	clr.w	(IO_Z80BUS).l
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d3/a1
	rts
; fill vram
; d0 = words to fill
; d1 = vram address
; d2 = data to fill with
DoFill
	movem.l	d3/a1,-(sp)
	movea.l	#VDP_DATA,a1
	andi.l	#$FFFF,d1
	asl.l	#2,d1
	lsr.w	#2,d1
	ori.w	#$4000,d1
	swap	d1
	move.l	d1,Vctrl-Vdata(a1)
	move.w	d2,d3
	swap	d3
	move.w	d2,d3
	lsr.w	#1,d0
	subq.w	#1,d0
.0
	move.l	d3,(dmaram).w
	move.w	(dmaram).w,(a1)
	move.w	(dmaram+2).w,(a1)
	dbf	d0,.0
	movem.l	(sp)+,d3/a1
	rts
WaitDMA	;wait for dma completion
	move.w	(VDP_CTRL).l,-(sp)
	btst	#1,1(sp)
	addq.w	#2,sp
	bne.s	WaitDMA
	rts
; d0 = color to fade to
setVram
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$3F,d1
.0
	move.w	d0,(a0)+
	dbf	d1,.0
	move.w	#$18,(palcount).w
	bsr.w	forcefade
setVram_0	;second half of setVram without the fade: clear vram and set the VDP registers from disflags, Map1col, VmMap1-3, VSPRITES and VSCRLPM.
	;Falls in from setVram, called from EASportsScreen and HiScoreScreen
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w	;#dfng
	move.w	#VDPR_AUTOINC+$02,(VDP_CTRL).l
	clr.w	d0
	bsr.w	Vmaddr
	move.w	#$3FFF,d0
	clr.l	d1
.9
	move.l	d1,(a0)
	dbf	d0,.9
	move.w	#$8C00,d0	;8 for shadow mode
	btst	#df32c,(disflags).w	;#df32c
	bne.w	.i32
	ori.w	#$81,d0
.i32
	move.w	d0,Vctrl-Vdata(a0)	;40 col mode, no interlace, normal brightness
	move.w	#VDPR_MODE1+$04,Vctrl-Vdata(a0)	;512 color palette enable
	move.w	#VDPR_MODE2+$64,Vctrl-Vdata(a0)
	move.w	#$9001,d0	;playfield is 64x32
	cmpi.w	#6,(Map1col1).w
	beq.w	.i64
	move.w	#$9003,d0
.i64
	move.w	d0,Vctrl-Vdata(a0)
	move.w	#$8200,d0
	move.b	(VmMap1).w,d0
	lsr.b	#2,d0
	andi.b	#$38,d0
	move.w	d0,Vctrl-Vdata(a0)
	move.w	#$8400,d0
	move.b	(VmMap2).w,d0
	lsr.b	#5,d0
	move.w	d0,Vctrl-Vdata(a0)
	move.w	#$8300,d0
	move.b	(VmMap3).w,d0
	lsr.b	#2,d0
	andi.b	#$3E,d0
	move.w	d0,Vctrl-Vdata(a0)
	move.w	#$8500,d0
	move.b	(VSPRITES).w,d0
	lsr.b	#1,d0
	move.w	d0,Vctrl-Vdata(a0)
	move.w	#$8D00,d0
	move.b	(VSCRLPM).w,d0
	lsr.b	#2,d0
	move.w	d0,Vctrl-Vdata(a0)
	move.w	#VDPR_WINX,Vctrl-Vdata(a0)	;disable plane 3 graphics
	move.w	#VDPR_WINY,Vctrl-Vdata(a0)	;disable plane 3 graphics
	move.w	#VDPR_BGCOL,Vctrl-Vdata(a0)	;Palette # 0 is border/transparent
	move.w	#VDPR_MODE3,Vctrl-Vdata(a0)	;Scroll mode (entire scroll)
	move.l	#VSRAM_W,Vctrl-Vdata(a0)	;vsram
	move.l	#0,(a0)	;playfield 1/2
	move.w	(sp)+,(disflags).w
	rts
; set video port to address d0
; d0 = vram address
; returns a0 = Vdata!!!
Vmaddr
	movea.l	#VDP_DATA,a0
	asl.l	#2,d0
	lsr.w	#2,d0
	ori.w	#$4000,d0
	swap	d0
	andi.w	#3,d0
	move.l	d0,Vctrl-Vdata(a0)
	rts
;	dobitmap, the tile decompressor (DecompressGraphicsWithCallback,
;	DecompressGraphicsPlain, DecompressGraphics, DecompressBytecode,
;	jump_table, the Opcode_* handlers, FlushOutputBuffer), xyVmMap, eraser,
;	Framer, printz2 / printsmall and the control codes, printz / print,
;	FormatAndPrintTime, PeriodLabelTable, PushTime, PushNumber,
;	PushNumberWidth, appendz / appstring, printbigz / printbig, PrintBigChar /
;	PutBigTile, AddSmallFont, AddFramer and AddTeamBlock.
;	The decompressor handlers and control code routines sit at the addresses
;	in jump_table and ControlCodeJumpTable.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp /
;	cmpi; fixopcodes.js patches the cmp encoding after assembly.

dobitmap	;transfer palette data/map data/tiles data to vram. a0 = palette, a1 = map, a2 = tiles (DecompressGraphics data), d0 = start x, d1 = start y, d2 = width x, d3 = width y, d4 = start char, d5 = pal used bits (0-3) for color fam 1-4. printy is restored and the tiles go last through DecompressGraphics (returns d4 = end char)
	move.w	(printy).w,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w	;#dfng
	movem.l	d0-d3/d5-d6/a0-a3,-(sp)
	move.w	d1,d6
	movea.w	#(palfadenew-M68K_RAM),a3
	bra.w	.00
.01
	move.b	0(a0,d0.w),0(a3,d0.w)
	dbf	d0,.01
.02
	adda.l	#$20,a0
	adda.l	#$20,a3
.00
	moveq	#$1F,d0
	lsr.w	#1,d5
	bcs.s	.01
	bne.s	.02
	move.w	(printa).w,d5
	andi.w	#$F800,d5
	move.w	$E(sp),d2
	subq.w	#1,d2
.loop2
	bsr.w	xyVmMap
	move.w	d6,d0	;y start
	mulu.w	(a1),d0	;map width
	add.w	2(sp),d0
	asl.w	#1,d0
	move.w	$A(sp),d1
	subq.w	#1,d1
.loop1
	move.w	4(a1,d0.w),d3
	add.w	d4,d3
	eor.w	d5,d3
	move.w	d3,(a0)
	addq.w	#2,d0
	dbf	d1,.loop1
	addq.w	#1,(printy).w
	addq.w	#1,d6
	dbf	d2,.loop2
	btst	#0,(sflags6).w
	bne.w	.0
	bsr.w	DecompressGraphicsPlain
.0
	movem.l	(sp)+,d0-d3/d5-d6/a0-a3
	move.w	(sp)+,(disflags).w
	move.w	(sp)+,(printy).w
	rts
DecompressGraphicsWithCallback	;DecompressGraphics, then return 8 bytes past the call (callback data)
	move.l	(sp),(callbackPtr).w
	bsr.w	DecompressGraphics
	addq.l	#8,(sp)
	rts
DecompressGraphicsPlain	;Clear callbackPtr, fall into DecompressGraphics
	clr.l	(callbackPtr).w
DecompressGraphics	;a2 = graphics data, d4 = start char
	movem.l	d0-d1/a0-a6,-(sp)
	movea.l	a2,a0
	move.w	d4,d1
	asl.w	#5,d1
	move.w	(a0)+,d0
	beq.w	.done
	bmi.w	.packed
	add.w	d0,d4
	asl.w	#4,d0
	pea	(.done).l
	tst.l	(callbackPtr).w
	beq.w	DoDMApro
	movea.l	(callbackPtr).w,a1
	bra.w	remap
.packed
	andi.w	#$7FFF,d0
	add.w	d0,d4
	bsr.w	DecompressBytecode
.done
	movem.l	(sp)+,d0-d1/a0-a6
	rts
DecompressBytecode	;Unpack a0 into the 256 byte ring buffer at ThreeStars
	movea.w	#(ThreeStars-M68K_RAM),a1
	movea.w	#(ThreeStars-M68K_RAM),a3
	movea.w	#(callbackPtr-M68K_RAM),a4
	movea.l	#remap,a5
	movea.l	#DoDMApro,a6
	movem.l	d0-d3/a0-a2,-(sp)
	move.w	d1,d3
	clr.w	d1
	clr.w	d2
.loop
	move.b	(a0)+,d0
	andi.w	#$F0,d0
	lsr.w	#3,d0
	lea	jump_table(pc),a2
	move.w	0(a2,d0.w),d0
	jsr	0(a2,d0.w)
	bra.s	.loop
jump_table	;DecompressBytecode handler offsets, one per opcode high nibble
	dc.w	Opcode_CopyLiteral-jump_table	;0
	dc.w	Opcode_CopyLiteral-jump_table	;1
	dc.w	Opcode_ClearBytes-jump_table	;2
	dc.w	Opcode_Fillbytes-jump_table	;3
	dc.w	Opcode_CopyBackwardShort-jump_table	;4
	dc.w	Opcode_CopyBackwardShort-jump_table	;5
	dc.w	Opcode_CopyBackwardShort-jump_table	;6
	dc.w	Opcode_CopyBackwardShort-jump_table	;7
	dc.w	Opcode_CopyBackwardMedium-jump_table	;8
	dc.w	Opcode_CopyBackwardLong-jump_table	;9
	dc.w	Opcode_CopyBackwardExtended1-jump_table	;A
	dc.w	Opcode_CopyBackwardExtended2-jump_table	;B
	dc.w	Opcode_CopyBackwardReverseShort-jump_table	;C
	dc.w	Opcode_CopyBackwardReverseShort-jump_table	;D
	dc.w	Opcode_CopyBackwardReverseMedium-jump_table	;E
	dc.w	Opcode_CopyBackwardReverseLong-jump_table	;F
Opcode_CopyLiteral	;opcodes 0-1, copy (low 5 bits)+1 bytes from the data
	move.b	-1(a0),d0
	andi.w	#$1F,d0
.loop
	move.b	(a0)+,0(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next
	dbf	d0,.loop
	rts
Opcode_ClearBytes	;opcode 2, write (low 4 bits)+1 zero bytes
	move.b	-1(a0),d0
	andi.w	#$F,d0
.loop
	clr.b	0(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next
	dbf	d0,.loop
	rts
Opcode_Fillbytes	;opcode 3, write the next data byte (low 4 bits)+3 times
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
.loop
	move.b	d2,0(a1,d1.w)
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next
	dbf	d0,.loop
	rts
Opcode_CopyBackwardShort	;opcodes 4-7, copy from back in the output buffer
	move.b	-1(a0),d0
	andi.w	#7,d0
	addq.w	#1,d0
	move.b	-1(a0),d2
	lsr.w	#3,d2
	andi.w	#7,d2
	addq.w	#1,d2
CopyBackwardRun	;shared copy loop, d0 = count-1, d2 = distance back
	neg.b	d2
	add.b	d1,d2
.loop
	move.b	0(a1,d2.w),0(a1,d1.w)
	addq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next
	dbf	d0,.loop
	rts
Opcode_CopyBackwardMedium	;opcode 8
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	bra.s	CopyBackwardRun
Opcode_CopyBackwardLong	;opcode 9
	move.b	(a0),d0
	asl.b	#1,d0
	move.b	-1(a0),d0
	roxl.b	#1,d0
	andi.w	#$1F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$7F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun
Opcode_CopyBackwardExtended1	;opcode A
	move.b	-1(a0),d0
	asl.w	#8,d0
	move.b	(a0),d0
	lsr.w	#6,d0
	andi.w	#$3F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$3F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun
Opcode_CopyBackwardExtended2	;opcode B
	move.b	-1(a0),d0
	asl.w	#8,d0
	move.b	(a0),d0
	lsr.w	#5,d0
	andi.w	#$7F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$1F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardRun
Opcode_CopyBackwardReverseShort	;opcodes C-D, copy backwards through the source
	move.b	-1(a0),d0
	andi.w	#3,d0
	addq.w	#1,d0
	move.b	-1(a0),d2
	lsr.w	#2,d2
	andi.w	#7,d2
	addq.w	#1,d2
CopyBackwardReverseRun	;shared reverse copy loop
	neg.b	d2
	add.b	d1,d2
.loop
	move.b	0(a1,d2.w),0(a1,d1.w)
	subq.b	#1,d2
	addq.b	#1,d1
	bne.w	.next
	bsr.w	FlushOutputBuffer
.next
	dbf	d0,.loop
	rts
Opcode_CopyBackwardReverseMedium	;opcode E. Distance 0 is the end code
	move.b	-1(a0),d0
	andi.w	#$F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	bne.s	CopyBackwardReverseRun
	tst.w	d1
	beq.w	.fin
	bsr.w	FlushOutputBuffer
.fin
	addq.w	#4,sp
	movem.l	(sp)+,d0-d3/a0-a2
	rts
Opcode_CopyBackwardReverseLong	;opcode F
	move.b	(a0),d0
	asl.b	#1,d0
	move.b	-1(a0),d0
	roxl.b	#1,d0
	andi.w	#$1F,d0
	addq.w	#2,d0
	move.b	(a0)+,d2
	andi.w	#$7F,d2
	addq.w	#1,d2
	bra.s	CopyBackwardReverseRun
FlushOutputBuffer	;Write the full ring buffer to vram
	movem.l	d0-d1/a0-a1,-(sp)
	move.w	d1,d0
	bne.w	.size
	move.w	#$100,d0
.size
	lsr.w	#1,d0
	move.w	d3,d1
	add.w	d0,d3
	add.w	d0,d3
	movea.l	a1,a0
	tst.l	(a4)
	beq.w	.dma
	movea.l	(a4),a1
	jsr	(a5)
	bra.w	.done
.dma
	jsr	(a6)
.done
	movem.l	(sp)+,d0-d1/a0-a1
	rts
; use print x/y/m to set vram address
xyVmMap
	movem.l	d0-d2,-(sp)
	move.w	(printx).w,d0
	move.w	(printy).w,d1
	movea.l	#VmMap1,a0
	adda.w	(printm).w,a0
	move.w	2(a0),d2
	asl.w	d2,d1
	add.w	d1,d0
	asl.w	#1,d0
	add.w	(a0),d0
	bsr.w	Vmaddr
	movem.l	(sp)+,d0-d2
	rts
; fill rectangle with char
; d0/d1 - x/y size of rectangle
; d2 = char word to fill with
; printx/y/m define top corner to start at
eraser
	movem.l	d0-d2/a0,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w	;#dfng
	movem.w	d0-d1,-(sp)
.1
	bsr.s	xyVmMap
	move.w	(sp),d0
	subq.w	#1,d0
.0
	move.w	d2,(a0)
	dbf	d0,.0
	addq.w	#1,(printy).w
	andi.w	#$1F,(printy).w
	subq.w	#1,2(sp)
	bne.s	.1
	addq.w	#4,sp
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d2/a0
	rts
; frame and fill (uses framer.map graphics and assumes tiles are already located at framercset)
; d0/d1 = x/y size of rectangle
; printx/y/m define top left corner to start at
Framer
	movem.l	d0-d4/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w	;#dfng
	movem.w	d0-d1,-(sp)
	move.w	(printa).w,d2
	add.w	(framercset).w,d2
	movea.l	#FramerMap,a1
	adda.l	4(a1),a1
	addq.w	#4,a1
	clr.w	d4
	bsr.w	.tbline
	subq.w	#3,2(sp)
.mtop
	bsr.w	.tbline
	subq.w	#6,d4
	subq.w	#1,2(sp)
	bpl.s	.mtop
	addq.w	#6,d4
	bsr.w	.tbline
	addq.w	#4,sp
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d4/a0-a1
	rts
.tbline
	bsr.w	xyVmMap
	addq.w	#1,(printy).w
	bsr.w	.setter
	addq.w	#2,d4
	move.w	4(sp),d0
	subq.w	#3,d0
.tblp
	bsr.w	.setter
	dbf	d0,.tblp
	addq.w	#2,d4
	bsr.w	.setter
	addq.w	#2,d4
	rts
.setter
	move.w	0(a1,d4.w),d3
	add.w	d2,d3
	move.w	d3,(a0)
	rts
; see print
; string macro should follow jsr to this routine
printsmallz	;String macro follows the call
	move.l	a1,-(sp)
	movea.l	4(sp),a1
	bsr.w	printsmall
	move.l	a1,4(sp)
	movea.l	(sp)+,a1
	rts
; a1 = string macro
; printx/y = x/y coordinate on map for printing
; printm = map to print on
; printa = attribute for characters
;
; string \-$ab,$xx,$yy,'Sample!'\
;
; a = map number (1-3)
; b = color/priority (0-3 = color fam,prio off), (4-7 = color fam, prio on)
; xx = x coord to print at
; yy = y coord to print at
printsmall	;Print string macro a1 at printx/y/m with printa; uses the setup font (setupfontchars) when sflags6 bit 3 is set
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	movem.l	d0-d3/a0/a2-a3,-(sp)
	movea.w	#(smallfontchars-M68K_RAM),a3
	btst	#3,(sflags6).w
	beq.w	.start
	movea.w	#(setupfontchars-M68K_RAM),a3
.start
	bsr.w	xyVmMap
	move.w	(printa).w,d2
	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1
.0
	move.b	(a1)+,d0
	ext.w	d0
	bgt.w	.nocom
	neg.w	d0
	asl.w	#2,d0
	movea.l	#ControlCodeJumpTable,a2
	movea.l	0(a2,d0.w),a2
	jsr	(a2)
	bra.w	.1
.nocom
	cmp.b	#$40,d0
	bne.w	.noblank
	move.w	#$7FF,d0
	bra.w	.p
.noblank
	cmp.b	#$5E,d0
	beq.w	.skip
	asl.w	#1,d0
	movea.l	#SmallFontMap,a2
	btst	#3,(sflags6).w
	beq.w	.4
	movea.l	#PrintFont2Map,a2
.4
	adda.l	4(a2),a2
	move.w	4(a2,d0.w),d0
	move.w	(printfontset).w,d1
	add.w	0(a3,d1.w),d0
.p
	add.w	d2,d0
	move.w	d0,(a0)
	addq.w	#1,(printx).w
.1
	dbf	d3,.0
	movem.l	(sp)+,d0-d3/a0/a2-a3
	move.w	(sp)+,(disflags).w
	rts
.skip
	addq.w	#1,(printx).w
	bsr.w	xyVmMap
	bra.s	.1
ControlCodeJumpTable	;printsmall control codes, indexed by -byte
	dc.l	rtss2		;0: padding, no-op
	dc.l	ControlCode_SetMap		;-1: map
	dc.l	ControlCode_SetAttribute		;-2: palette/priority
	dc.l	ControlCode_SetX		;-3: x
	dc.l	ControlCode_SetY		;-4: y
	dc.l	ControlCode_AddX		;-5: x offset
	dc.l	ControlCode_AddY		;-6: y offset
	dc.l	ControlCode_SetFont		;-7: char set
	dc.l	ControlCode_SetMapAndPosition		;-8: attribute, map, x, y
ControlCode_SetMapAndPosition	;control code -8, next 4 bytes = attribute, map, x, y
	bsr.w	ControlCode_SetAttribute
	bsr.w	ControlCode_SetMap
	bsr.w	ControlCode_SetX
	bra.w	ControlCode_SetY
ControlCode_SetMap	;Control code -1, next byte = map number -> printm
	move.b	(a1)+,d0
	subq.w	#1,d3
	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w
	bra.w	xyVmMap
ControlCode_SetAttribute	;Control code -2, next byte = palette/priority -> printa
	move.b	(a1)+,d2
	andi.w	#7,d2
	subq.w	#1,d3
	ror.w	#3,d2
	move.w	d2,(printa).w
	rts
ControlCode_SetX	;Control code -3, next byte = printx
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	move.w	d0,(printx).w
	bra.w	xyVmMap
ControlCode_SetY	;Control code -4, next byte = printy
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	move.w	d0,(printy).w
	bra.w	xyVmMap
ControlCode_AddX	;control code -5, add the next (signed) byte to printx
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#1,d3
	add.w	d0,(printx).w
	bra.w	xyVmMap
ControlCode_AddY	;control code -6, add the next (signed) byte to printy
	move.b	(a1)+,d0
	ext.w	d0
	subq.w	#1,d3
	add.w	d0,(printy).w
	bra.w	xyVmMap
ControlCode_SetFont	;control code -7, next byte = char set index
	clr.w	d0
	move.b	(a1)+,d0
	subq.w	#1,d3
	asl.w	#1,d0
	move.w	d0,(printfontset).w
	rts
; see print
; string macro should follow jsr to this routine
printz
	move.l	a1,-(sp)
	movea.l	4(sp),a1
	bsr.w	print
	move.l	a1,4(sp)
	movea.l	(sp)+,a1
	rts
; a1 = string macro
; printx/y = x/y coordinate on map for printing
; printm = map to print on
; printa = attribute for characters
;
; string \-$ab,$xx,$yy,'Sample!'\
; a = map number (1-3)
; b = color/priority (0-3 = color fam, prio off), (4-7 = color fam, prio on)
; xx = x coord to print at
; yy = y coord to print at
print
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	xyVmMap
	move.w	(printa).w,d2
	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1
.0
	move.b	(a1)+,d0
	beq.w	.1
	ext.w	d0
	bpl.w	.nocom
	neg.w	d0
	move.w	d0,d2
	asl.w	#8,d2
	asl.w	#1,d2
	andi.w	#$F800,d2
	move.w	d2,(printa).w
	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w
	move.b	(a1)+,d0
	ext.w	d0
	move.w	d0,(printx).w
	move.b	(a1)+,d1
	ext.w	d1
	move.w	d1,(printy).w
	bsr.w	xyVmMap
	subq.w	#2,d3
	bra.w	.1
.nocom
	cmp.b	#$40,d0
	bne.w	.noblank
	move.w	#$7FF,d0
	bra.w	.p
.noblank
	cmp.b	#$5E,d0
	beq.w	.skip
	asl.w	#1,d0
	movea.l	#SmallFontMap,a2
	btst	#3,(sflags6).w
	beq.w	.2
	movea.l	#PrintFont2Map,a2
.2
	adda.l	4(a2),a2
	move.w	4(a2,d0.w),d0
	btst	#3,(sflags6).w
	beq.w	.3
	add.w	(setupfontchars).w,d0
	bra.w	.p
.3
	add.w	(smallfontchars).w,d0
.p
	add.w	d2,d0	;for alternate palettes
	move.w	d0,(a0)
	addq.w	#1,(printx).w
.1
	dbf	d3,.0
	movem.l	(sp)+,d0-d3/a0/a2
	move.w	(sp)+,(disflags).w
	rts
.skip
	addq.w	#1,(printx).w
	bsr.w	xyVmMap
	bra.s	.1
FormatAndPrintTime	;d0 bits 14-15 = period, bits 0-13 = seconds
	swap	d0
	clr.w	d0
	rol.l	#2,d0
	movea.l	#PeriodLabelTable,a1
	bsr.w	PrintStringFromList
	addq.w	#2,(printx).w
	swap	d0
	lsr.w	#2,d0
	bsr.w	PushTime
	bra.w	print
PeriodLabelTable	;String list for FormatAndPrintTime: " 1", " 2", " 3", "OT"
	dc.w	4
	dc.b	' 1'
	dc.w	4
	dc.b	' 2'
	dc.w	4
	dc.b	' 3'
	dc.w	4
	dc.b	'OT'
; convert d0 into string format of min:sec
PushTime
	movea.w	#(mesarea+30-M68K_RAM),a1
	move.l	d0,-(sp)
	move.l	a1,-(sp)
	ext.l	d0
	divu.w	#$A,d0
	swap	d0
	addi.w	#$30,d0
	move.b	d0,-(a1)
	swap	d0
	ext.l	d0
	divu.w	#6,d0
	swap	d0
	addi.w	#$30,d0
	move.b	d0,-(a1)
	swap	d0
	move.b	#$3A,-(a1)
	ext.l	d0
	divu.w	#$A,d0
	swap	d0
	addi.w	#$30,d0
	move.b	d0,-(a1)
	swap	d0
	move.b	#$20,-(a1)
	tst.w	d0
	beq.w	.noz
	addi.w	#$30,d0
	move.b	d0,(a1)
.noz
	move.l	(sp)+,d0
	sub.l	a1,d0
	addq.w	#2,d0
	btst	#0,d0
	beq.w	.1
	clr.b	-(a1)
	addq.w	#1,d0
.1
	move.w	d0,-(a1)
	move.l	(sp)+,d0
	rts
PushNumber	;convert d0 into string format of base 10 number, no leading zeros. Return a1 = string
	movea.w	#(PushNumberBuf-M68K_RAM),a1
	move.l	d0,-(sp)
	move.l	a1,-(sp)
.0
	ext.l	d0
	divu.w	#$A,d0
	swap	d0
	addi.w	#$30,d0
	move.b	d0,-(a1)
	swap	d0
	tst.w	d0
	bne.s	.0
	move.l	(sp)+,d0
	sub.l	a1,d0
	addq.w	#2,d0
	btst	#0,d0
	beq.w	.1
	clr.b	-(a1)
	addq.w	#1,d0
.1
	move.w	d0,-(a1)
	move.l	(sp)+,d0
	rts
PushNumberWidth	;right-justified number
	movem.l	d0-d3,-(sp)	;push to stack
	movea.w	#(PushWidthBuf+2-M68K_RAM),a1	;move address FFC00A into a1
	moveq	#1,d2	;move 1 into d2
	sub.w	d2,d1	;sub d2 from d1
	bra.w	.loop	;branch
.mul
	mulu.w	#$A,d2	;mult d2 by 10 dec
.loop
	dbf	d1,.mul	;exit when d1 is 0
	moveq	#$20,d3	;' '   ; move 20 into d3
.loop2
	ext.l	d0	;sign extend d0
	divu.w	d2,d0	;divide d2 into d0
	bne.w	.0	;branch if not equal
	cmp.w	#1,d2	;compare d2 to 1
	beq.w	.0	;branch if equal
	move.w	d3,d0	;move d3 into d0
	bra.w	.put
.0
	;DeterStrLength?+26   j
	moveq	#$30,d3	;'0'   ; move 48 dec into d3
	add.w	d3,d0	;add d3 to d0
.put
	move.b	d0,(a1)+	;move d0 into a1 and increment a1
	swap	d0	;swap d0 words
	divu.w	#$A,d2	;divide d2 by 10 dec
	bne.s	.loop2	;branch if not equal to 0
	move.l	a1,d0	;move a1 into d0
	subi.w	#$C008,d0	;sub C008 from d0
	btst	#0,d0	;test bit 0 of d0
	beq.w	.00
	clr.b	(a1)+	;clear byte at a1 and increment
	addq.w	#1,d0	;add 1 to d0
.00
	movea.w	#(PushWidthBuf-M68K_RAM),a1	;move address FFC008 back into a1
	move.w	d0,(a1)	;move d0 into a1 address location
	movem.l	(sp)+,d0-d3	;push from stack
	rts
appendz	;see appstring. String macro should follow the bsr/jsr to this routine
	movea.l	(sp)+,a1
	bsr.w	appstring
	jmp	(a1)
; append string a1 to string a3
appstring
	movem.l	d0/a0,-(sp)
	lea	2(a3),a0
	move.w	(a3),d0
	subq.w	#3,d0
	bmi.w	.1
.0
	addq.w	#1,a0
	tst.b	(a0)
	dbeq	d0,.0
.1
	move.w	(a1)+,d0
	subq.w	#3,d0
	bmi.w	.ex
.2
	move.b	(a1)+,(a0)+
	bne.w	.3
	subq.w	#1,a0
.3
	dbf	d0,.2
	move.l	a0,d0
	btst	#0,d0
	beq.w	.4
	clr.b	(a0)+
	addq.l	#1,d0
.4
	sub.l	a3,d0
	move.w	d0,(a3)
.ex
	movem.l	(sp)+,d0/a0
	rts
printbigz	;String macro follows the call
	move.l	a1,-(sp)
	movea.l	4(sp),a1
	bsr.w	printbig
	move.l	a1,4(sp)
	movea.l	(sp)+,a1
	rts
printbig
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movem.l	d0-d7/a0/a2,-(sp)
	move.w	(printx).w,d4
	move.w	(printy).w,d5
	move.w	(printa).w,d6
	add.w	(BigFontChars).w,d6
	move.w	(a1)+,d3
	subq.w	#2,d3
	bra.w	.1
.0
	move.b	(a1)+,d0
	beq.w	.1
	ext.w	d0
	bpl.w	.nocom
	neg.w	d0
	move.w	d0,d6
	asl.w	#8,d6
	asl.w	#1,d6
	andi.w	#$F800,d6
	move.w	d6,(printa).w
	add.w	(BigFontChars).w,d6
	andi.w	#3,d0
	asl.w	#2,d0
	subq.w	#4,d0
	move.w	d0,(printm).w
	move.b	(a1)+,d4
	ext.w	d4
	move.w	d4,(printx).w
	move.b	(a1)+,d5
	ext.w	d5
	move.w	d5,(printy).w
	subq.w	#2,d3
	bra.w	.1
.nocom
	cmp.b	#$61,d0
	blt.w	.2
	cmp.b	#$7A,d0
	bgt.w	.2
	addi.b	#-$20,d0
.2
	move.w	d3,-(sp)
	bsr.w	PrintBigChar
	move.w	(sp)+,d3
.1
	dbf	d3,.0
	move.w	d4,(printx).w
	move.w	d5,(printy).w
	movem.l	(sp)+,d0-d7/a0/a2
	move.w	(sp)+,(disflags).w
	rts
PrintBigChar	;print big font char d0 (ascii) through bfasciicon
	subi.w	#$20,d0
	movea.l	#bfasciicon,a0
	moveq	#1,d2
	move.b	0(a0,d0.w),d1
	ext.w	d1
	bpl.w	.0
	neg.w	d1
	clr.w	d2
.0
	asl.w	#1,d1
	movea.l	#BigFontMap,a0
	adda.l	4(a0),a0
.loop
	move.w	4(a0,d1.w),d3
	bsr.w	PutBigTile
	move.w	(a0),d7
	asl.w	#1,d7
	add.w	d7,d1
	move.w	4(a0,d1.w),d3
	sub.w	d7,d1
	addq.w	#1,d5
	bsr.w	PutBigTile
	subq.w	#1,d5
	addq.w	#1,d4
	addq.w	#2,d1
	dbf	d2,.loop
	rts
PutBigTile	;write one big font tile to the map at printx / printy
	add.w	d6,d3
	movem.l	d1/a0,-(sp)
	move.w	d5,d0
	movea.l	#VmMap1,a0
	adda.w	(printm).w,a0
	move.w	2(a0),d1
	asl.w	d1,d0
	add.w	d4,d0
	asl.w	#1,d0
	add.w	(a0),d0
	bsr.w	Vmaddr
	move.w	d3,(a0)
	movem.l	(sp)+,d1/a0
	rts
AddSmallFont	;transfer smallfont.map tiles to vram. d4 = char to start tiles at, return d4 = end of tiles + 1. Goes through DecompressGraphics
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	bra.w	DecompressGraphicsPlain
AddFramer	;transfer framer.map tiles to vram. d4 = char to start tiles at, return d4 = end of tiles + 1. Goes through DecompressGraphics
	movea.l	#FramerMap+8,a2
	move.w	d4,(framercset).w
	bra.w	DecompressGraphicsPlain
AddTeamBlock	;transfer TeamBlocks.map tiles to vram at char 2. Return d4 = end of tiles + 1. Goes through DecompressGraphics
	moveq	#2,d4
	movea.l	#Teamblocksmap+8,a2
	bra.w	DecompressGraphicsPlain
