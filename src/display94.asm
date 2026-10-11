;	VBlank, vb2, IRQ7, DumpSprites, DumpSprites2, DoDMAList, SetScroll2,
;	setvideo and the sprite builders it calls (updatescroll, showref,
;	checkfo, showzam, SetSframe, showcrowd).
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	Bits: disflags 0 dfok, 2 dfng, 3 dfclock, 4 face off; sflags 0 sfpz, 7 sfhor; sflags2 1 sf2refref.

VBlank	;Main vblank code for game play (vbint target, set by setupice and setupice_highlight). DumpSprites when
	;dfok is set, cramfade, then the game clock. gmode2 bit 2 keeps the clock running after the whistle, and with gmode2 bit 1
	;(penalty shot / shootout) shootoutclock counts down instead (shootoutjiffy jiffies, not while gmode2 bit 7 is set)
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w	;dfng: don't touch the vdp
	bne.w	.nograph
	bclr	#dfok,(disflags).w	;dfok
	beq.w	.01
	bsr.w	DumpSprites
.01
	bsr.w	cramfade
.nograph
	btst	#sfpz,(sflags).w	;sfpz
	bne.w	.c
	btst	#2,(gmode2).w
	bne.w	.0
	btst	#0,(gmode).w	;gmclock: game clock stopped
	bne.w	.c
.0
	btst	#1,(gmode2).w	;penalty shot / shootout clock
	bne.w	.1
	tst.w	(gameclock).w
	beq.w	.c
	subi.w	#$AAA,(gameclock+2).w	;jiffy. gameclock+2 = gameclock+2
	bcc.w	.c
	bset	#dfclock,(disflags).w	;dfclock
	subq.w	#1,(gameclock).w
	cmpi.w	#$3D,(gameclock).w	;61
	bgt.w	.c
	cmpi.w	#$3C,(gameclock).w	;60
	blt.w	.c
	move.w	#SFXbeep2,-(sp)	;SFXbeep2, played when gameclock reaches 60
	bsr.w	sfx
.c
	addq.w	#1,(vcount).w
	jsr	(p_music_vblank).l
	movem.l	(sp)+,d0-d7/a0-a6
	rte
.1
	tst.w	(shootoutclock).w
	beq.s	.c
	subi.w	#$AAA,(shootoutjiffy).w
	bcc.s	.c
	bset	#3,(disflags).w
	btst	#7,(gmode2).w
	bne.s	.c
	subq.w	#1,(shootoutclock).w
	bra.s	.c
vb2	;Vblank used for palfades only, no dmas (vbint target). No rte here: falls into IRQ7
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	bsr.w	cramfade
.nograph
	addq.w	#1,(vcount).w
	jsr	(p_music_vblank).l
	movem.l	(sp)+,d0-d7/a0-a6
IRQ7	;rte only. vb2 falls in; the vector table ($60, $64, ...) points here
	rte
DumpSprites	;Transfer (by dma) scroll stuff, sprite table, vram data in dmalist. Called from VBlank when dfok was set. Falls into DumpSprites2
	bsr.w	SetScroll2
DumpSprites2	;Transfer sprite table, then the dma list. Falls into DoDMAlist. Also called from VBlank_SetOptions
	movea.w	#(Satt-M68K_RAM),a0
	move.w	(Sattsize).w,d0	;words
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA
DoDMAList	;(symbols are case-insensitive). Transfer data from dmalist. Also called from setupice
	movea.l	(DMAlistend).w,a6
	cmpa.l	#DMAList,a6
	beq.w	rtss2	;list empty
.0
	move.w	-(a6),d1	;vram address
	move.w	-(a6),d0	;words
	movea.l	-(a6),a0	;source
	bsr.w	DoDMA
	cmpa.l	#DMAList,a6
	bne.s	.0
	rts
SetScroll2	;Write Hscroll / Vscroll to the vdp. Called from DumpSprites
	move.w	(VSCRLPM).w,d0
	addq.w	#2,d0
	bsr.w	Vmaddr
	move.w	(Hscroll).w,(a0)
	move.l	#VSRAM_W+(2<<16),Vctrl-Vdata(a0)	;vsram write, address 2
	move.w	(Vscroll).w,(a0)
	rts
setvideo	;this is not vblank code but sets up ram for vblank transfers. Called once per game frame (DoGameFrame, PauseMode, ...). Also runs AddArenaAnimSprite and Crowd_Noise
	movem.l	d0-d7/a0-a6,-(sp)
.p
	btst	#dfok,(disflags).w	;dfok: wait for vblank to take the last frame
	bne.s	.p
	movea.w	#(DMAList-M68K_RAM),a5	;dma transfer list
	bsr.w	updatescroll
	movea.w	#(Satt-M68K_RAM),a6	;sprite attribute table area
	moveq	#1,d6	;link counter
	bsr.w	checkfo
	bsr.w	checksso
	bsr.w	setsortcords
	bsr.w	setffo
	bsr.w	showclock
	bsr.w	showzam
	jsr	(AddArenaAnimSprite).l
	bsr.w	showcrowd
	bsr.w	showref
	jsr	(Crowd_Noise).l	;(?)
	cmpa.w	#(Satt-M68K_RAM),a6	;no sprites: one blank sprite
	bne.w	.n
	clr.l	(a6)+
	clr.l	(a6)+
.n
	clr.b	-5(a6)	;end sprite list
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0	;words
	move.w	d0,(Sattsize).w
	move.l	a5,(DMAlistend).w
	bset	#dfok,(disflags).w	;dfok
	movem.l	(sp)+,d0-d7/a0-a6
	rts
updatescroll	; Using hpos and vpos set scroll cords; queue rink map rows on the dma list (a5) when vertical
	;scrolling needs new rows. Called from setvideo. Takes the rows from Rinktilelist, or RevRinkTilelist in a reverse angle replay
	;(sflags4 bit 4)
	btst	#7,(sflags).w	;sfhor
	bne.w	rtss2
	moveq	#-$40,d0	;-192+128 (#$FFFFFFC0)
	sub.w	(Hpos).w,d0
	move.w	(Vpos).w,d1
	move.w	d0,(Hscroll).w
	move.w	d1,(Vscroll).w
	neg.w	(Vscroll).w
	move.w	(Oldrow).w,d4
	asr.w	#3,d1
	move.w	d1,(Oldrow).w
	moveq	#$1F,d3	;max lines to update
	cmp.w	d4,d1
	beq.w	rtss2	;same row as last frame
	movea.l	#Rinktilelist,a0
	btst	#4,(sflags4).w	;reverse angle replay
	beq.w	.0
	movea.l	#RevRinkTilelist,a0
.0
	adda.l	4(a0),a0	;a0 = map header: (a0) = chars per row, data at 4(a0) (the move / adda leave the cmp flags)
	blt.w	.su0	;row went up
.sd
	move.w	d1,d0
	neg.w	d0
	addi.w	#$1E,d0
	andi.w	#$1F,d0
	asl.w	#7,d0
	add.w	(VmMap2).w,d0
	move.w	d0,6(a5)
	move.w	#$1E,d0
	sub.w	d1,d0
	move.w	(a0),4(a5)
	mulu.w	(a0),d0
	add.w	d0,d0
	lea	4(a0,d0.w),a1
	move.l	a1,(a5)
	addq.w	#8,a5
	subq.w	#1,d1
	cmp.w	d4,d1
	dbeq	d3,.sd
	rts
.su0
	move.w	d1,d0
	neg.w	d0
	addi.w	#$1D,d0
	andi.w	#$1F,d0
	asl.w	#7,d0
	add.w	(VmMap2).w,d0
	move.w	d0,6(a5)
	move.w	#$3D,d0
	sub.w	d1,d0
	move.w	(a0),4(a5)
	mulu.w	(a0),d0
	add.w	d0,d0
	lea	4(a0,d0.w),a1
	move.l	a1,(a5)
	addq.w	#8,a5
	addq.w	#1,d1
	cmp.w	d4,d1
	dbeq	d3,.su0
	rts
showref	;draw ref graphics. a5 = dma list, a6 = sprite table, d6 = link counter. Called from setvideo
	bclr	#sf2refref,(sflags2).w	;sf2refref
	beq.w	rtss2
	movea.w	#(RefRamMap-M68K_RAM),a0
	movea.w	#(VmMap1-M68K_RAM),a1
	move.w	2(a1),d2
	moveq	#2,d0	;refy: Xpos on ice screen
	btst	#sfhor,(sflags).w
	beq.w	.1
	moveq	#$F,d0	;Ypos on scoreboard screen
.1
	asl.w	d2,d0
	moveq	#2,d1
	asl.w	d2,d1
	addq.w	#2,d0
	btst	#sfhor,(sflags).w
	beq.w	.2
	addi.w	#$B,d0
.2
	asl.w	#1,d0
	add.w	(a1),d0
	moveq	#7,d2
.0
	move.l	a0,(a5)+
	move.w	#7,(a5)+
	move.w	d0,(a5)+
	adda.w	#$E,a0
	add.w	d1,d0
	dbf	d2,.0
	rts
checkfo	;check for face off sprites. 3 entries of fofdata2: word frame, word flags. Called from setvideo
	btst	#sfpz,(sflags).w	;sfpz
	bne.w	rtss2
	btst	#4,(disflags).w	;face off flag
	beq.w	rtss2
	movea.w	#(fofdata2-M68K_RAM),a3
	moveq	#2,d0
.loop
	move.w	(a3),d4
	bmi.w	.1
	beq.w	.1
	movea.l	#FaceOffSprites,a2
	adda.l	4(a2),a2
	add.w	d4,d4
	move.w	2(a2,d4.w),d5
	sub.w	0(a2,d4.w),d5
	lsr.w	#3,d5
	subq.w	#1,d5
	adda.w	0(a2,d4.w),a2
.loop2
	move.w	2(a2),d2
	addi.w	#$80,d2
	add.w	(fodropy).w,d2
	move.w	d2,(a6)
	move.w	(a2),d2
	btst	#3,2(a3)	;x flip
	beq.w	.0
	move.b	7(a2),d2
	andi.w	#$C,d2
	addq.w	#4,d2
	asl.w	#1,d2
	neg.w	d2
	sub.w	(a2),d2
.0
	addi.w	#$80,d2
	add.w	(fodropx).w,d2
	move.w	d2,6(a6)
	move.b	7(a2),2(a6)
	move.b	d6,3(a6)
	move.w	6(a2),d2
	andi.w	#$F800,d2
	or.w	4(a2),d2
	move.w	2(a3),d1
	andi.w	#$F800,d1
	eor.w	d1,d2
	add.w	(faceoffvrcset).w,d2
	move.w	d2,4(a6)
	addq.w	#1,d6
	addq.w	#8,a6
	addq.w	#8,a2
	dbf	d5,.loop2
	addq.w	#4,a3
.1
	dbf	d0,.loop
	rts
showzam	;zamboni. a5 = dma list, a6 = sprite table, d6 = link counter. Draws frame 1, frame 2-4 picked by x, then frame 5 (home score not ahead) or a .ftab frame. Called from setvideo
	move.w	(zamx).w,d0
	bmi.w	rtss2	;no zamboni
	movea.l	#ZamFrameList,a0
	lsr.w	#2,d0
	move.w	#$12A,d1	;y (92 128+200)
	moveq	#1,d2
	move.w	(ExtraChars).w,d3
	bsr.w	SetSframe
	move.w	d0,d2
	lsr.w	#1,d2
	ext.l	d2
	divu.w	#3,d2
	swap	d2
	addq.w	#2,d2	;frame 2 + (x/2 mod 3)
	bsr.w	SetSframe
	moveq	#5,d2
	move.w	(HmGoals).w,d4	;home score
	cmp.w	(AwGoals).w,d4
	bls.w	SetSframe	;home not ahead: frame 5
	move.w	d0,d2
	subi.w	#$DA,d2
	bpl.w	.pos
	clr.w	d2
.pos
	lsr.w	#2,d2
	add.w	d2,d2
	cmp.w	#$1A,d2
	blt.w	.get
	move.l	#$18,d2
.get
	movea.l	#.ftab,a1
	move.w	0(a1,d2.w),d2
	bra.w	SetSframe
.ftab	dc.w	5,6,7,8,7,8,7,8,7,8,7,6,5	;frame by (x-$DA)/4
SetSframe	;draw one sprite frame. a0 = framelist, d0/d1 = x/y cords, d2 = frame to setup (from 0), d3 = start char in vram, a6 = sprite table,
	;d6 = link counter. Called from showzam and the screen code
	cmp.w	#$40,d6	;MaxSprites
	bge.w	rtss2
	movem.l	d0-d5/a0,-(sp)
	adda.l	4(a0),a0
	add.w	d2,d2
	move.w	2(a0,d2.w),d4
	sub.w	0(a0,d2.w),d4
	lsr.w	#3,d4
	subq.w	#1,d4	;number of sprites in frame
	adda.w	0(a0,d2.w),a0
.loop
	move.w	2(a0),(a6)
	add.w	d1,(a6)+
	move.b	7(a0),(a6)+
	move.b	d6,(a6)+
	move.w	6(a0),d2
	andi.w	#$F800,d2
	add.w	4(a0),d2
	add.w	d3,d2
	move.w	d2,(a6)+
	move.w	(a0),(a6)
	add.w	d0,(a6)+
	addq.w	#1,d6
	cmp.w	#$40,d6	;MaxSprites
	beq.w	.ex
	addq.w	#8,a0
	dbf	d4,.loop
.ex
	movem.l	(sp)+,d0-d5/a0
	rts
showcrowd	;draw crowd sprites: up to 3 frames per PBnum nibble, then the two crowdframe frames. a5 = dma list, a6 = sprite table, d6 = link
	;counter. No crowd in a reverse angle replay. Called from setvideo
	btst	#4,(sflags4).w	;check if reverse angle replay
	bne.w	.x	;branch if so
	movea.l	#CrowdFrameList,a1
	adda.l	4(a1),a1
	move.w	(Hpos).w,d4
	move.w	(Vpos).w,d5
	btst	#sfhor,(sflags).w
	beq.w	.v
	moveq	#-$40,d4	;(#$FFFFFFC0)
	move.l	#$100,d5
.v
	clr.w	d0
	move.b	(PBnum).w,d2
	moveq	#$1A,d3	;frames 26+ (low nibble)
	bsr.w	.pb
	move.b	(PBnum).w,d2
	lsr.w	#4,d2
	moveq	#$1D,d3	;frames 29+ (high nibble)
	bsr.w	.pb
	move.b	(crowdframe).w,d0
	bsr.w	.sc
	move.b	(crowdframe+1).w,d0
	bra.w	.sc
.pb	;d2 = count, d3 = first frame
	andi.w	#$F,d2
	cmp.w	#3,d2
	bls.w	.pb0
	moveq	#3,d2	;max 3
.pb0
	bra.w	.nextpb
.pbt
	move.w	d3,d0
	add.w	d2,d0
	bsr.w	.sc
.nextpb
	dbf	d2,.pbt
	rts
.sc	;d0 = frame, 0 = none
	ext.w	d0
	beq.w	rtss2
	btst	#sfhor,(sflags).w
	beq.w	.chk
	addi.w	#$1F,d0	;horizontal frames are 31 later
.chk
	cmp.w	#$40,d6	;MaxSprites
	bge.w	rtss2
	movem.l	d0-d5,-(sp)
	add.w	d0,d0
	movea.l	a1,a0
	move.w	2(a0,d0.w),d1
	sub.w	0(a0,d0.w),d1
	lsr.w	#3,d1
	subq.w	#1,d1
	move.w	d1,-(sp)	;number of sprites in frame
	adda.w	0(a0,d0.w),a0
	move.w	d4,d0
	addi.w	#$C0,d0
	move.w	d0,d1
	subi.w	#$90,d0
	addi.w	#$80,d1
	move.w	#$170,d2
	sub.w	d5,d2
	move.w	d2,d3
	subi.w	#$80,d2
	addi.w	#$70,d3
	move.w	(sp)+,d4
.loop
	cmp.w	2(a0),d2
	bgt.w	.next
	cmp.w	2(a0),d3
	blt.w	.next
	cmp.w	(a0),d0
	bgt.w	.next
	cmp.w	(a0),d1
	blt.w	.next
	move.w	2(a0),d5
	addi.w	#$70,d5
	sub.w	d2,d5
	move.w	d5,(a6)+
	move.b	7(a0),(a6)+
	move.b	d6,(a6)+
	move.w	6(a0),d5
	andi.w	#$F800,d5
	add.w	4(a0),d5
	add.w	(gamesetuptilesetindex).w,d5	;crowd start char
	move.w	d5,(a6)+
	move.w	(a0),d5
	addi.w	#$70,d5
	sub.w	d0,d5
	move.w	d5,(a6)+
	addq.w	#1,d6
	cmp.w	#$40,d6
	beq.w	.ex
.next
	addq.w	#8,a0
	dbf	d4,.loop
.ex
	movem.l	(sp)+,d0-d5
.x
	rts
;	showclock, checksso, setsortcords, setffo, uppads, the pad label code
;	(FormatControllerDisplay, RenderSmallFontChar, ButtonLabelCharTable),
;	addframe, addframe2, find3d, updatesound and KillCrowd.
;	The horizontal clock's .digit and .digits tables sit inside showclock.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	Object offsets: Xpos 0, attribute 4, frame 6, oldframe 8, VRoffs $A, VRchar $12, Ypos $14, Zpos $18.
;	ssosize = $14. DMA list entries (a5): long source, word length in words, word vram.

showclock	;put the game clock on screen. Called from setvideo and PauseMode. On the horizontal rink the clock is printed (printz / print
	;with .digits; not in a shootout, gmode2 bit 0). On the vertical rink (.3) it goes in the dma list, only when
	;dfclock is set; with gmode2 bit 1 (penalty shot / shootout) shootoutclock is shown instead of gameclock. a5 = dma list
	btst	#7,(sflags).w	;sfhor
	beq.w	.3
	btst	#0,(gmode2).w	;shootout
	bne.w	.x
	move.l	a1,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),$D,5
	move.w	(gameclock).w,d0
	ext.l	d0
	divu.w	#$258,d0	;tens of minutes (600 seconds)
	move.l	d0,-(sp)
	tst.w	d0
	bne.w	.1
	addq.w	#1,(printx).w
	bra.w	.2
.1
	jsr	(.digit).l
.2
	move.l	(sp)+,d0
	swap	d0
	ext.l	d0
	divu.w	#$3C,d0	;minutes
	move.l	d0,-(sp)
	jsr	(.digit).l
	move.l	(sp)+,d0
	swap	d0
	ext.l	d0
	addq.w	#2,(printx).w
	divu.w	#$A,d0	;tens of seconds
	move.l	d0,-(sp)
	jsr	(.digit).l
	move.l	(sp)+,d0
	swap	d0
	ext.l	d0
	jsr	(.digit).l
	movea.l	(sp)+,a1
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),$D,5
.x
	rts
.digit	;Print digit d0 from .digits
	movea.l	#.digits,a1
	asl.w	#2,d0
	adda.w	d0,a1
	jsr	(print).l
	rts
.digits	;Strings '0' .. '9' for .digit (4 bytes each)
	String	'0'
	String	'1'
	String	'2'
	String	'3'
	String	'4'
	String	'5'
	String	'6'
	String	'7'
	String	'8'
	String	'9'
.3	;Returns unless dfclock is set
	bclr	#3,(disflags).w	;dfclock
	beq.w	rtss2
	btst	#3,(sflags2).w
	bne.w	rtss2
	cmpi.w	#4,(gsp).w	;no clock update when gsp = 4
	beq.w	rtss2
	movea.w	#(clockram+6-M68K_RAM),a0	;end of the 5 word clock buffer; written backward
	movea.l	#SmallFontMap,a1
	adda.l	4(a1),a1
	move.w	$78(a1),d0	;4+(':'*2)
	add.w	(smallfontchars).w,d0
	ori.w	#$8000,d0
	move.w	d0,(clockram).w	;colon
	move.w	(gameclock).w,d0
	btst	#1,(gmode2).w	;penalty shot / shootout clock
	beq.w	.4
	move.w	(shootoutclock).w,d0
.4
	ext.l	d0
	divu.w	#$A,d0
	bsr.w	.char	;seconds ones
	divu.w	#6,d0
	bsr.w	.char	;seconds tens
	subq.w	#2,a0	;skip the colon
	divu.w	#$A,d0
	bsr.w	.char	;minutes ones
	swap	d0
	tst.l	d0
	bne.w	.0
	moveq	#-$10,d0	;' '-'0': blank leading zero (#$FFFFFFF0)
	swap	d0
.0
	bsr.w	.char	;minutes tens
	move.l	a0,(a5)+
	move.w	#5,(a5)+	;words to transfer
	movea.w	#(VmMap1-M68K_RAM),a1
	moveq	#$18,d0	;.clocky = 24
	moveq	#3,d2	;.clockx = 3
	btst	#sfhor,(sflags).w	;sfhor (always clear here: the horizontal rink prints the clock above)
	beq.w	.cv
	movea.w	#(VmMap2-M68K_RAM),a1
	moveq	#5,d0	;clock y (93 used 4)
	moveq	#$D,d2	;.clockx2 = 13
.cv
	move.w	2(a1),d1
	asl.w	d1,d0
	add.w	d2,d0
	asl.w	#1,d0
	add.w	(a1),d0
	move.w	d0,(a5)+	;vram destination
	rts
.char	;d0 high word = digit, write its tile to -(a0)
	swap	d0
	asl.w	#1,d0
	move.w	$64(a1,d0.w),d0	;4+('0'*2)
	add.w	(smallfontchars).w,d0
	ori.w	#$8000,d0
	move.w	d0,-(a0)
	swap	d0
	ext.l	d0
	rts
checksso	;do graphics for sso structure: arrows for the players when they are off screen. Called from setvideo. a5 = dma list, a6 = sprite
	;table, d6 = link counter. Returns on the horizontal rink. Includes the pads 3 and 4 (Joy3Struct / Joy4Struct when cont3team / cont4team).
	;Falls into .ca for the last one
	btst	#sfhor,(sflags).w
	bne.w	rtss2
	movea.w	#(Joy1Struct-M68K_RAM),a0
	movea.w	#(sso-M68K_RAM),a3
	move.w	#$180,d3	;SPFarrow
	bsr.w	.ca
	adda.w	#$1C,a0	;ffosize
	adda.w	#$14,a3	;ssosize
	move.w	#$183,d3	;SPFarrow+3
	bsr.w	.ca
	tst.w	(cont3team).w
	beq.w	rtss2	;on screen: no arrow
	movea.w	#(Joy3Struct-M68K_RAM),a0
	adda.w	#$14,a3
	move.w	#$346,d3
	bsr.w	.ca
	tst.w	(cont4team).w
	beq.w	rtss2
	movea.w	#(Joy4Struct-M68K_RAM),a0
	adda.w	#$14,a3
	move.w	#$349,d3
.ca	;a0 = object, a3 = sso, d3 = first arrow frame. In a shootout, with sflags2 bit 3 or in a penalty shot, no arrow for a player beyond x $A6
	tst.w	Zpos(a0)
	bmi.w	rtss2	;not on the ice
	st	frame(a3)
	move.w	(a0),d0
	btst	#0,(gmode2).w
	bne.w	.0
	btst	#3,(sflags2).w
	bne.w	.0
	btst	#2,(BA_PS_flags).w
	beq.w	.7
.0
	move.w	d0,-(sp)
	tst.w	d0
	bpl.w	.2
	neg.w	d0
.2
	cmp.w	#$A6,d0
	blt.w	.6
	move.w	(sp)+,d0
	rts
.6
	move.w	(sp)+,d0
.7
	move.w	Ypos(a0),d1
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	exg	d0,d1
	neg.w	d0
	subi.w	#$C5,d1	;horoff
	bra.w	.hord
.nhor
	sub.w	(Hpos).w,d0
	sub.w	(Vpos).w,d1
.hord
	clr.w	d2
	cmp.w	#$74,d0	;.xoff = 116
	blt.w	.8
	bset	#3,d2
.8
	cmp.w	#$FF8C,d0	;-.xoff
	bgt.w	.1
	bset	#2,d2
.1
	cmp.w	#$64,d1	;.yoff = 100
	blt.w	.9
	bset	#0,d2
.9
	cmp.w	#$FF9C,d1	;-.yoff
	bgt.w	.3
	bset	#1,d2
.3
	tst.w	d2
	beq.w	rtss2
	movea.l	#jdtab,a1
	move.b	0(a1,d2.w),d2
	asl.w	#3,d2
	movea.l	#.tab,a1
	move.w	0(a1,d2.w),d4
	beq.w	.4
	move.w	d4,d0
.4
	addi.w	#$100,d0	;128+128
	move.w	d0,(a3)
	move.w	2(a1,d2.w),d4
	beq.w	.5
	move.w	d4,d1
.5
	neg.w	d1
	addi.w	#$F0,d1	;112+128
	move.w	d1,2(a3)
	add.w	4(a1,d2.w),d3
	move.w	d3,frame(a3)
	move.w	6(a1,d2.w),attribute(a3)
	bra.w	addframe2
.tab	;x spot, y spot, frame add, attribute per direction
	dc.w	0,$64,0,$0000
	dc.w	$74,$64,1,$0000
	dc.w	$74,0,2,$0000
	dc.w	$74,-$64,1,$1000
	dc.w	0,-$64,0,$1000
	dc.w	-$74,-$64,1,$1800
	dc.w	-$74,0,2,$0800
	dc.w	-$74,$64,1,$0800
setsortcords	;setup sort cord graphics: addframe for the 16 objects in OOlist order. a5 = dmalist, a6 = sprite attribute table, d6 = link counter
	movea.w	#(OOlist-M68K_RAM),a4	;move OOlist into a4
	move.w	#$F,d0	;sortobj-1 (15 dec)
.top
	clr.w	d1
	move.b	(a4)+,d1	;move next sortcord into d1
	asl.w	#6,d1	;mult by 64
	movea.w	#(SortCords-M68K_RAM),a3	;Sort Cord struct start into a3 (FFB04A)
	adda.w	d1,a3	;add offset to next struct
	bsr.w	addframe
	dbf	d0,.top	;loop until done
	rts
setffo	;draw the 7 objects tied to icerink scrolling (gloves and pads), moving each by its x offset. Called from setvideo
	bsr.w	uppads
	move.w	#6,d0	;ffo obj -1
	movea.w	#(pads-M68K_RAM),a3	;move start of struct into a3
.top
	movea.w	a6,a0
	bsr.w	addframe
	cmpa.w	a6,a0
	beq.w	.next
	move.w	2(a3),d1
	add.w	d1,6(a0)
	add.w	d1,$E(a0)
.next
	adda.w	#$1C,a3	;move to next struct
	dbf	d0,.top
	rts
uppads	;update the gloves object and the 6 pad objects, and queue new pad labels (FormatControllerDisplay). The pad players
	;come from the PadControlBits / PadControlBits34 nibbles ($E = no change, $F = none)
	movea.w	#(glovestruct-M68K_RAM),a0
	st	Zpos(a0)	;set Zpos
	move.b	(glovecords).w,d0
	beq.w	.0	;branch if 0
	move.b	(glovecords+1).w,d1
	ext.w	d0
	asl.w	#2,d0
	move.w	d0,(a0)	;move d0 into Xpos
	ext.w	d1
	asl.w	#2,d1
	move.w	d1,Ypos(a0)	;move d1 into Ypos
	clr.w	Zpos(a0)	;clear Zpos
.0
	move.w	#5,d4
	movea.w	#(pads-M68K_RAM),a0
	movea.w	#(padcont-M68K_RAM),a1
	movea.w	#(SortCords-M68K_RAM),a2
	move.w	(PadControlBits).w,d3
.top
	cmp.w	#1,d4
	bne.w	.nibble
	move.w	(PadControlBits34).w,d3
	lsr.w	#4,d3
	bra.w	*+4	;to the next instruction
.nibble
	move.w	d3,d0
	andi.w	#$F,d0
	move.w	#$F,d1
	cmp.w	#$E,d0
	beq.w	.chg
	st	Zpos(a0)
	cmp.w	#$F,d0
	beq.w	.next
	asl.w	#7,d0
	move.w	0(a2,d0.w),(a0)
	move.w	Ypos(a2,d0.w),Ypos(a0)
	clr.w	Zpos(a0)
	move.b	position+1(a2,d0.w),d1
	asl.w	#8,d1
	move.b	rostnum(a2,d0.w),d1
.chg
	cmp.w	(a1),d1
	beq.w	.next
	move.w	d1,(a1)
	bsr.w	FormatControllerDisplay
.next
	lsr.w	#4,d3
	adda.w	#$1C,a0
	addq.w	#2,a1
	dbf	d4,.top
	rts
FormatControllerDisplay	;Queue the 3 character label of a pad object. d1 = label code: bits 7-4 and 3-0 are digits ($F =
	;blank), bits 10-8 index ButtonLabelCharTable (none while sflags7 bit 7 is set). a0 = pad object, a5 = dma list. Falls into
	;RenderSmallFontChar for the last char
	lea	ButtonLabelCharTable(pc),a4
	clr.w	2(a0)	;x offset (setffo adds it to the sprites)
	move.w	d1,d2
	lsr.w	#4,d2
	andi.w	#$F,d2
	bne.w	.hi
	move.w	#$FFF0,d2	;' '-'0': blank leading zero
	subq.w	#4,2(a0)
.hi
	addi.w	#$30,d2
	clr.w	d0
	bsr.w	RenderSmallFontChar
	move.w	d1,d2
	andi.w	#$F,d2
	cmp.w	#$F,d2
	bne.w	.lo
	move.w	#$FFF0,d2	;$F: blank
.lo
	addi.w	#$30,d2
	moveq	#1,d0
	bsr.w	RenderSmallFontChar
	move.w	d1,d2
	btst	#7,(sflags7).w
	beq.w	.0
	clr.w	d2
.0
	lsr.w	#8,d2
	andi.w	#7,d2
	bne.w	.1
	addq.w	#4,2(a0)
.1
	move.b	0(a4,d2.w),d2
	moveq	#2,d0
RenderSmallFontChar	;Dma one small font tile (SmallFontMap) to the object's chars. d2 = ascii char, d0 = char slot, a0 = object (VRchar), a5 = dma list
	movea.l	#SmallFontMap,a3
	adda.l	4(a3),a3
	add.w	d2,d2
	move.w	4(a3,d2.w),d2
	andi.w	#$7FF,d2
	asl.w	#5,d2	;32 bytes per tile
	movea.l	#SmallFontMap,a3
	lea	$A(a3,d2.w),a3
	move.l	a3,(a5)+
	move.w	#$10,(a5)+	;words to transfer
	add.w	VRchar(a0),d0
	asl.w	#5,d0
	move.w	d0,(a5)+
	rts
ButtonLabelCharTable	;Third label character by bits 10-8 of the label code
	dc.b	' DDLCRX',$FF	;pad byte (93 used $10)
addframe	;a3 = sort cord object. Project it with find3d, then addframe2. a5 = dma trans, a6 = sprite attribute table. Called from setsortcords and setffo
	movem.l	d0-d2,-(sp)
	move.w	(a3),d0	;Xpos into d0
	move.w	Ypos(a3),d1	;Ypos into d1
	move.w	Zpos(a3),d2	;Zpos into d2
	bmi.w	.exit	;exit if Zpos minus
	bsr.w	find3d	;get position on screen
	cmp.w	#$4E20,d1	;#osflag into d1
	beq.w	.exit	;exit if Sort Cord is off screen
	bsr.w	addframe2
.exit
	movem.l	(sp)+,d0-d2
	rts
addframe2	;d0/d1 = x/y coord on screen, a3 = object, a5 = dma trans, a6 = sprite attribute table, d6 = link counter. Queue the sprite tiles of
	;the frame (once per frame change, sharing tiles already sent) and write its sprites
	move.w	attribute(a3),-(sp)	;push attribute to stack
	movem.l	d0-d5/a0-a2,-(sp)	;push to stack
	move.w	frame(a3),d4	;move frame into d4
	bmi.w	.exit	;exit if minus
	beq.w	.exit	;exit if 0
	andi.w	#$F800,d4	;pass highest 5 bits
	eor.w	d4,attribute(a3)	;EOR d4 with attribute
	move.w	frame(a3),d4	;move frame back into d4
	andi.w	#$7FF,d4	;pass first 11 bits
	movea.l	#Sprites,a2	;sprite frame list
	adda.l	4(a2),a2	;add long word at offset 4 to a2 address. a2 now
	add.w	d4,d4	;add d4 to itself
	cmp.w	2(a2),d4	;compare offset 2 of a2 to d4. Offset 2 = $69E
	bge.w	.exit	;branch if greater than or equal
	move.w	2(a2,d4.w),d5	;move data at 2+a2+d4 into d5
	sub.w	0(a2,d4.w),d5	;sub data at a2+d4 from d5
	lsr.w	#3,d5	;divide d5 by 8
	subq.w	#1,d5	;sub 1 from d5. d5 now total sprites in frame -1(SprStrnum)
	adda.w	0(a2,d4.w),a2	;add data at a2+d4 to a2, a2 now at SprStrdat - sprite data
	clr.w	d3	;clear d3
	clr.w	d4	;clear d4
.sloop
	move.w	d0,-(sp)	;push d0 on stack
	move.w	frame(a3),d0	;move frame into d0
	andi.w	#$7FF,d0	;pass first 11 bits
	cmp.w	oldframe(a3),d0	;compare old frame to d0 (current frame)
	beq.w	.noref	;branch if equal (no change)
	tst.w	d5	;check if d5 is 0
	bne.w	.nn	;branch if not
	move.w	d0,oldframe(a3)	;move frame into old frame
.nn
	movem.w	d0-d4,-(sp)	;push to stack
	move.w	4(a2),d2	;move 4 + a2 data into d2 (tile pointer bytes)
	clr.w	d4	;clear d4
	move.b	7(a2),d4	;move 7 + a2 data into d4 (sizetab byte)
	movea.l	#sizetab,a0	;move address into a0
	move.b	0(a0,d4.w),d4	;move data at a0+d4 into d4 - tiles used in sprite
	cmp.w	8(sp),d4	;compare current d4 to previous d4
	bgt.w	.nodup	;branch if d4 greater - more data in prev sprite so no dup
	;d0 = frame
	;d2 = 11 bit pointer to sprite tiles
	;d4 = # of tiles in sprite
	;d5 = # of sprites in frame-1
	cmp.w	4(sp),d2	;compare current d2 to previous d2
	blt.w	.nodup	;branch if less than
	move.w	4(sp),d0	;move previous d2 into d0
	add.w	8(sp),d0	;add previous d4 to d0 - end of last data
	sub.w	d2,d0	;sub d2 from d0
	sub.w	d4,d0	;sub d4 from d0
	bmi.w	.nodup	;branch if d0 negative
	movem.w	(sp)+,d0-d1	;pop d0 and d1 from stack
	addq.w	#6,sp	;add 6 to stack pointer
	bra.w	.dup	;branch
.nodup
	add.w	8(sp),d3	;add old d4 to d3 - both of these are 0 if first sprite in frame
	movem.w	(sp)+,d0-d1	;pop d0 and d1 from stack (d0=Xpos, d1=Ypos)
	addq.w	#6,sp	;add 6 to stack pointer (moves past old d4 spot on stack)
	movem.w	d0-d4,-(sp)	;push d0-d4 to stack (all new values are on stack)
	add.w	VRchar(a3),d3	;add VRChar of player struct to d3
	ext.l	d2	;extend d2 (clears out upper word)
	asl.l	#5,d2	;mult d2 by 32
	addi.l	#Spritetiles,d2
	asl.w	#4,d4	;mult by 16 (# of sprite tiles by 16)
	asl.w	#5,d3	;mult by 32 (# of prev sprite tiles+VrChar by 32)
	move.l	d2,(a5)+
	move.w	d4,(a5)+	;words to transfer
	move.w	d3,(a5)+	;vram destination
	movem.w	(sp)+,d0-d4	;pop from stack
.dup
	move.b	d3,VRoffs(a3,d5.w)	;move d3 into VRoffs of sprite
	;This and VRChar are for VRAM access
.noref
	move.w	(sp)+,d0	;pop from stack
	movem.w	d0-d2,-(sp)	;push to stack
	move.w	2(a2),d2	;move data at 2+a2 into d2 - Y global
	btst	#4,attribute(a3)	;check for Y flip
	beq.w	.noyflip	;branch if no y flip
	move.b	7(a2),d2	;move byte 7 (sizetab byte) into d2
	andi.w	#3,d2	;pass bit 1 and 2
	addq.w	#1,d2	;add 1
	asl.w	#3,d2	;mult by 8
	neg.w	d2	;negate d2
	sub.w	2(a2),d2	;sub Y global from d2
.noyflip
	add.w	d2,d1	;add d2 to d1 (d1=Ypos of Sort Cord)
	move.w	d1,(a6)	;move sprite's Ypos into a6 data (Satt)
	move.w	(a2),d2	;move data at a2 to d2 (X global into d2)
	btst	#3,attribute(a3)	;check for x flip
	beq.w	.noxflip	;branch if no x flip
	move.b	7(a2),d2	;move data at 7+a2 into d2
	andi.w	#$C,d2	;pass bit 3 and 4
	addq.w	#4,d2	;add 4
	asl.w	#1,d2	;mult by 2
	neg.w	d2	;negate d2
	sub.w	(a2),d2	;sub data at a2 from d2
.noxflip
	add.w	d2,d0	;add d2 to d0 (d0 = Xpos of Sort Cord)
	move.w	d0,6(a6)	;move sprite's Xpos into 6+a6 position
	move.b	7(a2),2(a6)	;move sizetab byte into 2+a6
	move.b	d6,3(a6)	;move d6 (link counter) into 3+a6
	move.w	6(a2),d2	;move 6+a2 into d2 (to be used to check palette and set HVFlip)
	move.w	attribute(a3),d0	;move attribute into d0
	eor.w	d0,d2	;EOR d0 with d2
	andi.w	#$F800,d2	;pass top 5 bits
	btst	#0,attribute+1(a3)	;check if bit 0 of attribute+1 is 0
	beq.w	.nospec	;branch if zero
	btst	#$E,d2	;check if bit 14 is 0
	beq.w	.nospec	;branch if zero
	bset	#$D,d2	;set bit 13 to 0 - team 2 color
.nospec
	or.b	VRoffs(a3,d5.w),d2	;OR Vroffs of a3+d5 to d2
	add.w	VRchar(a3),d2	;add VRchar to d2
	move.w	d2,4(a6)	;move d2 into 4+a6 (Satt)
	movem.w	(sp)+,d0-d2	;pop from stack
	addq.w	#1,d6	;add 1 to d6
	addq.w	#8,a6	;add 8 to a6
	addq.w	#8,a2	;add 8 to a2
	dbf	d5,.sloop	;loop if still sprites in frame
.exit
	movem.l	(sp)+,d0-d5/a0-a2
	move.w	(sp)+,attribute(a3)
	rts
find3d	;input: d0 = xfield, d1 = yfield, d2 = height off field. Output: d0 = xscreen, d1 = yscreen, or d1 = $4E20 when off screen
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	exg	d0,d1
	neg.w	d0
	subi.w	#$C5,d1
	bra.w	.crange
.nhor
	sub.w	(Hpos).w,d0
	sub.w	(Vpos).w,d1
.crange
	cmp.w	#$90,d0
	bgt.w	.offscr
	cmp.w	#$FF70,d0
	blt.w	.offscr
	addi.w	#$100,d0
	add.w	d2,d1
	asr.w	#1,d2
	add.w	d2,d1
	cmp.w	#$90,d1
	bgt.w	.offscr
	cmp.w	#$FF70,d1
	blt.w	.offscr
	neg.w	d1
	addi.w	#$F0,d1
	rts
.offscr
	move.w	#$4E20,d1
	rts
updatesound	;move the crowd noise volume (psg noise channel, asv) toward crowdlevel. Called from periodicevents
	move.w	(crowdlevel).w,d0
	asl.w	#3,d0
	addi.w	#$400,d0
	cmp.w	#$EFF,d0
	bls.w	.ip
	move.w	#$EFF,d0
.ip
	moveq	#$28,d2
	sub.w	(asv).w,d0
	cmp.w	d2,d0
	bgt.w	.iasv
	neg.w	d2
	cmp.w	d2,d0
	bge.w	.non
.iasv
	add.w	d2,(asv).w
	bpl.w	.non
	clr.w	(asv).w
.non
	move.b	#$C8,(VDP_PSG).l
	move.b	#1,(VDP_PSG).l
	move.b	(asv).w,d0
	eori.b	#$F,d0
	ori.b	#$F0,d0
	move.b	d0,(VDP_PSG).l
	rts
KillCrowd	;silence the crowd noise (psg). Called from Begin, SetupPauseScreen, StartHL2, ...
	move.b	#$E7,(VDP_PSG).l
	move.b	#$DF,(VDP_PSG).l
	move.b	#$C8,(VDP_PSG).l
	move.b	#1,(VDP_PSG).l
	move.b	#$FF,(VDP_PSG).l
	rts
