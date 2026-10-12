;	New in 94: the EA Sports screen shown at startup. This file also draws the playoff matchup
;	pictures, holds some helpers for the option screens and runs the options screen's vertical blank.

EASportsScreen	;Called from Begin. Show the EA Sports screen until a button, or $50 x 4 frames (about 5 s)
	move.l	#vb2,(vbint).w	;vblank handler
	bclr	#1,(disflags).w
	move.w	#5,(Map3col1).w
	move.w	#$A000,(VmMap2).w
	move.w	#7,(Map2col1).w
	move.w	#$C000,(VmMap1).w
	move.w	#7,(Map1col1).w
	move.w	#$F000,(VmMap3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$1F,d1			;32 longs: all 64 colours black
.clr	clr.l	(a0)+
	dbf	d1,.clr
	bsr.w	CopyPaletteToCRAM
	bsr.w	setVram_0
	bsr.w	printz
	String	-TXMAP2,0,0,0
	movea.l	#EASportsMap,a2		;screen map
	movea.l	a2,a0
	movea.l	a2,a1
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d4
	moveq	#$F,d5
	bsr.w	dobitmap
	move.w	#$EEE,(palfadenew).w
	move.w	#0,(palfadenew+$E).w
	move.w	#$18,(palcount).w	;fade in
	move	#$2500,sr		;vblank on
	move.w	#$50,(seed).w	;frame count down in the random seed word
.wait	moveq	#4,d0
	bsr.w	waitx			;4 frames; d1 = buttons
	tst.w	d1
	bne.w	.ex			;Button pressed
	subq.w	#1,(seed).w
	bpl.s	.wait
.ex	move	#$2700,sr
	rts

UpdatePlayoffLevel	;Set pojoy from the number of players for play modes 2 and 3.
	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtss2
	cmpi.w	#4,(OptPlayMode).w
	beq.w	rtss2
	moveq	#7,d0
	tst.w	(FourWayPlay).w
	beq.w	.set
	move.w	#$B,d0			;4 way play
.set	sub.w	(OptNOP).w,d0
	move.w	d0,(pojoy).w
	rts

DrawMatchupBitmaps	;Called from PrintOptions. Draw the VisTeam and HomeTeam bitmaps (DrawTeamBitmap)
	movem.l	d0-d7/a0-a2,-(sp)
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.opt
	tst.w	(OptPlayMode).w
	bne.w	.draw
.opt	move.w	(Opt1Team).w,(HomeTeam).w
	move.w	(Opt2Team).w,(VisTeam).w
.draw	bsr.w	printz
	String	$BF,7,1,0
	move.w	(VisTeam).w,d1
	move.w	d1,d0
	asl.w	#6,d0			;64 bytes per team
	movea.l	#TeamPalettes,a0
	move.l	$26(a0,d0.w),(palfadenew+$26).w
	move.w	(teambitmapchars).w,d4
	bsr.w	DrawTeamBitmap
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$16,1,0
	move.w	(HomeTeam).w,d1
	move.w	d1,d0
	asl.w	#6,d0			;64 bytes per team
	movea.l	#TeamPalettes,a0
	move.l	2(a0,d0.w),(palfadenew+$22).w
	move.w	#$EEE,(palfadenew+$2A).w
	move.w	#2,d4
	bsr.w	DrawTeamBitmap
	bsr.w	setteams
	move.w	#$64,(palcount).w
	movem.l	(sp)+,d0-d7/a0-a2
	rts

DrawTeamBitmap	;dobitmap entry d1 of TeamBitmaps (d4 from the caller)
	clr.w	d0
	asl.w	#1,d1
	movea.l	#TeamBitmaps,a0
	movea.l	a0,a1
	adda.l	(a0),a0
	adda.l	4(a1),a1
	movea.w	#$30A,a2
	move.w	(a1),d2
	moveq	#2,d3
	moveq	#0,d5
	bra.w	dobitmap

dotb	;unreferenced. Like DrawTeamBitmap with Teamblocksmap, d4 = 2, d5 = 2
	clr.w	d0
	asl.w	#1,d1
	movea.l	#Teamblocksmap,a0
	movea.l	a0,a1
	adda.l	(a0),a0
	adda.l	4(a1),a1
	movea.w	#$30A,a2
	move.w	(a1),d2
	moveq	#2,d3
	moveq	#2,d4
	moveq	#2,d5
	bra.w	dobitmap

ClearRosterName	;unreferenced. Set the print position, then erase 12 x 2 at it
	bsr.w	setoptions_printpos2
	moveq	#$C,d0			;12
	moveq	#2,d1			;2
	move.w	#$7FF,d2
	bra.w	eraser

setoptions_printpos2	;printz position string, then printx = $1A when a2 is the home team
	bsr.w	printz
	String	-(TXPRI+TXMAP1),2,$A,0
	cmpa.w	#(tmstruct-M68K_RAM),a2	;home team struct?
	bne.w	rtss2
	move.w	#$1A,(printx).w
	rts

PickStartingGoalie	;unreferenced. $26(a2) = 0 if a pad has team a2, else (gamelevel <= 2, line changes on)
	;a value from the team's .sodds
	movem.l	d0/a0,-(sp)
	clr.w	$26(a2)
	bsr.w	FigureJoy
	cmpa.w	#(tmstruct-M68K_RAM),a2
	seq	d0
	ext.w	d0
	addq.w	#2,d0			;1 for the home team, 2 for the away team
	cmp.w	(cont1team).w,d0
	beq.w	.x
	cmp.w	(cont2team).w,d0
	beq.w	.x			;a pad has this team: leave $26(a2) = 0
	moveq	#0,d0
	cmpi.w	#2,(gamelevel).w
	bgt.w	.set
	tst.w	(OptLine).w
	bne.w	.set
	movea.w	#$30E,a0		;TeamList
	move.w	(a2),d0
	asl.w	#2,d0
	movea.l	0(a0,d0.w),a0		;team block
	adda.w	$A(a0),a0		;ScoreOdds offset: a0 = .sodds
	moveq	#4,d0
	bsr.w	UnpackNibbles
	bsr.w	WeightedRandomSelect
.set	move.w	d0,$26(a2)
.x	movem.l	(sp)+,d0/a0
	rts

VBlank_SetOptions	;vbint handler stored by setoptions: cramfade unless
	;dfng), plus DumpSprites2 when dfok is set
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w		;dfng
	bne.w	.nograph
	bclr	#dfok,(disflags).w		;dfok
	beq.w	.fade
	bsr.w	DumpSprites2
.fade	bsr.w	cramfade
.nograph	addq.w	#1,(vcount).w
	jsr	(p_music_vblank).l
	movem.l	(sp)+,d0-d7/a0-a6
	rte
