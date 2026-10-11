; $0FD618  NEW in 94: period stats and game statistics
;	NHL 94 (retail) segment $FD618-$FFABF
;	94 code in the high ROM, between hockey94_07 and the checksum: the shootout end, the game stats clear, the arena animations
;	(RunArenaAnim, AddArenaAnimSprite, ArenaAnims), the Period Stats and Game Statistics screens (PeriodStatsScreen, GameStatisticsScreen,
;	TeamStatTextTbl), the Manual Goalie menu item, ChooseSong, the shootout skate paths, the save RAM option and three stars
;	blocks, the player picture unpack (UnpackPicture), HiScoreScreen, newTitleScreen and the credits, clrTmPdst and chgplayer.
;	94 only; 93 has no code here, except GameStatisticsScreen / DisplayTeamStatsScreen / FormatStatValue / TeamStatTextTbl (stats93).
;	Transcribed from lst/nhl94.bin.lst lines 970645-976744. The IDA human names are kept; the IDA auto names (sub_, loc_, unk_,
;	locret_) and the entries IDA has no label for are named for what they do, or the 93 name.
;	Locals are in the 93 style (.x exit, .loop, numbered) with the IDA label, unless generic, in an ;IDA: comment. IDA left code as data at $FD6B4,
;	$FD7D0, $FD8EC-$FE14B, $FE1D8, $FE4FC and $FEEA0: written from the retail bytes (the instructions and Strings), as are the
;	Strings and remap table IDA hid in newTitleScreen. The data tables are formatted from the retail bytes.

EndShootout	;94 only. Shootout over (CountShootoutGoals, high94_2): freezewindow, then the 5 skaters of player slots 1-5 (homeshootgoals > awayshootgoals) or
	;7-$B are set up (setplayer) above or below the view and get assscore (assinsert 7)
	movem.l	d0-d7/a0-a6,-(sp)
	bset	#2,(sflags2).w
	jsr	(freezewindow).l
	move.w	#$60,(shootoutdelay).w
	movea.l	#SortCords,a3
	move.w	#0,d0
	move.w	(homeshootgoals).w,d2
	cmp.w	(awayshootgoals).w,d2
	bgt.w	.0
	move.w	#6,d0
.0
	asl.w	#7,d0
	adda.w	d0,a3
	move.w	#4,d2
	move.w	#6,d3
	bra.w	.2
.loop
	movem.w	d2-d3,-(sp)
	jsr	(setplayer).l
	move.w	#2,position(a3)
	move.w	#$F0,d0
	tst.w	(Vpos).w
	bmi.w	.1
	move.w	#$FF10,d0
.1
	add.w	(Vpos).w,d0
	move.w	d0,Ypos(a3)
	move.w	#0,(a3)
	move.w	#7,d0	;assscore
	jsr	(assinsert).l
	bclr	#5,pflags(a3)
	bclr	#1,pflags2(a3)
	bclr	#2,pflags(a3)
	movem.w	(sp)+,d2-d3
.2
	adda.l	#$80,a3
	dbf	d2,.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ClampPositionBox	;nothing calls it (IDA left it as data). Clamp $44 / $46(a3) to the box for position $34(a3) in PositionBoxes (PositionBoxesTop when bit 7 of
	;$62(a3), the top net)
	movem.l	d0-d7/a0,-(sp)
	move.w	position(a3),d7
	subq.w	#1,d7
	movea.l	#PositionBoxes,a0
	btst	#7,pflags(a3)
	beq.w	.0
	movea.l	#PositionBoxesTop,a0
.0
	add.w	d7,d7
	move.w	(a0,d7.w),d0
	cmp.w	temp3(a3),d0
	blt.w	.1
	move.w	d0,temp3(a3)
.1
	move.w	2(a0,d7.w),d0
	cmp.w	temp3(a3),d0
	bgt.w	.2
	move.w	d0,temp3(a3)
.2
	move.w	4(a0,d7.w),d0
	cmp.w	temp4(a3),d0
	blt.w	.3
	move.w	d0,temp4(a3)
.3
	move.w	6(a0,d7.w),d0
	cmp.w	temp4(a3),d0
	bgt.w	.x
	move.w	d0,temp4(a3)
.x
	movem.l	(sp)+,d0-d7/a0
	rts
PositionBoxes	;ClampPositionBox boxes: min / max of $44, then of $46, per position
	dc.w	$FFB5,0,0,$108,0,$4B,0,$108
PositionBoxesTop	;ClampPositionBox boxes, top net
	dc.w	$FFB5,0,$FEF8,0,0,$4B,$FEF8,0
ClearGameStats	;94 only. Clear the game stats: shootoutstate (19 words), both team structs (HmShots, AwShots), PenBuf, BA_PS_flags, sflags4 / F8 /
	;FA and setupcardflags / featuredplayer. Called from GameSetUp (hockey94_08)
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#shootoutstate,a0
	moveq	#$12,d0
.loop
	clr.w	(a0)+
	dbf	d0,.loop
	movea.l	#HmShots,a0
	move.w	#$363,d0
.loop2
	clr.w	(a0)+
	dbf	d0,.loop2
	movea.l	#PenBuf,a0
	moveq	#$24,d0
.loop3
	clr.w	(a0)+
	dbf	d0,.loop3
	clr.w	(BA_PS_flags).w
	clr.w	(sflags4).w
	clr.w	(sflags6).w
	clr.w	(gmode2).w
	clr.w	(setupcardflags).w
	clr.w	(featuredplayer).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
AddArenaAnimSprite	;94 only. Add the frame arenaframe of the arena animation (sprite list arenaspritelist, see RunArenaAnim) to the sprite table a6 (d6
	;sprites, 64 at most) for the pieces inside the view (Hpos / Vpos). Not in a reverse angle replay (sflags4 bit 4), sflags2 bit 3 or sflags
	;bit 7. Called from setvideo (video94_1)
	tst.w	(arenaanim).w
	bmi.w	.x2
	tst.l	(arenaspritelist).w
	beq.w	.x2
	btst	#4,(sflags4).w	;check if reverse angle replay
	bne.w	.x2	;branch if so
	btst	#3,(sflags2).w
	bne.w	.x2
	btst	#7,(sflags).w
	bne.w	.x2
	movea.l	(arenaspritelist).w,a1
	adda.l	4(a1),a1
	move.w	(Hpos).w,d4
	move.w	(Vpos).w,d5
	move.w	(arenaframe).w,d0
	bra.w	.2
	andi.w	#$F,d2	;nothing branches here: draw d2 + 1 (4 at most) frames from d3 (.2)
	cmp.w	#3,d2
	bls.w	.0
	moveq	#3,d2
.0
	bra.w	.1
.loop
	move.w	d3,d0
	add.w	d2,d0
	bsr.w	.2
.1
	dbf	d2,.loop
	rts
.2
	ext.w	d0
	beq.w	.x2
	cmp.w	#$40,d6
	bge.w	.x2
	movem.l	d0-d5,-(sp)
	add.w	d0,d0
	movea.l	a1,a0
	move.w	2(a0,d0.w),d1
	sub.w	0(a0,d0.w),d1
	lsr.w	#3,d1
	subq.w	#1,d1
	move.w	d1,-(sp)
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
.loop2
	cmp.w	2(a0),d2
	bgt.w	.3
	cmp.w	2(a0),d3
	blt.w	.3
	cmp.w	(a0),d0
	bgt.w	.3
	cmp.w	(a0),d1
	blt.w	.3
	move.w	2(a0),d5
	addi.w	#$70,d5
	sub.w	d2,d5
	move.w	d5,(a6)+
	move.b	7(a0),(a6)+
	move.b	d6,(a6)+
	move.w	6(a0),d5
	andi.w	#$F800,d5
	add.w	4(a0),d5
	add.w	(arenaanimchars).w,d5
	move.w	d5,(a6)+
	move.w	(a0),d5
	addi.w	#$70,d5
	sub.w	d0,d5
	move.w	d5,(a6)+
	addq.w	#1,d6
	cmp.w	#$40,d6
	beq.w	.x
.3
	addq.w	#8,a0
	dbf	d4,.loop2
.x
	movem.l	(sp)+,d0-d5
.x2
	rts
PrintPlayerNameRight	;94 only. Print the name of player d0 of team a2 (FormatPlayerName), moved left so it ends before column $29 (a trailing pad byte or
	;two not counted), then the icon of HotColdIcon. Called from PrintMatchupRatings (hockey94_07)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d0,(iconplayer).w
	move.l	a2,-(sp)
	jsr	(FormatPlayerName).l
	movea.l	a1,a0
	move.w	(a0),d0
	move.w	d0,d5
	tst.b	-1(a0,d5.w)
	bne.w	.0
	subq.w	#1,d0
	tst.b	-2(a0,d5.w)
	bne.w	.0
	subq.w	#1,d0
.0
	add.w	(printx).w,d0
	subi.w	#$29,d0
	bmi.w	.1
	neg.w	d0
	add.w	d0,(printx).w
.1
	movea.l	a0,a1
	jsr	(print).l
	movea.l	(sp)+,a2
	jsr	(HotColdIcon).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
SkipNameNumber	;nothing calls it (IDA left it as data). a1 = the FormatPlayerNameWithAttrib String without its first 2 characters (the length word moved up 2)
	movem.l	d0-d7/a0/a2-a3,-(sp)
	jsr	(FormatPlayerNameWithAttrib).l
	move.w	(a1),d0
	subq.w	#2,d0
	move.w	d0,2(a1)
	addq.w	#2,a1
	movem.l	(sp)+,d0-d7/a0/a2-a3
	rts
	String	' . '
PeriodStatsScreen	;IDA left it as data; 93 has no counterpart. "Period Stats" menu item (hockey94_11 menu lists): both team logos
	;(TeamLogoBitmaps, TeamLogoPalettes palettes), then the goals (matchup 0) or shots of each team by period ($342 / $34A of the team struct; OT when
	;sflags7 bit 1) and the total. Left / right switch, start exits (ExitAttributeScreen2)
	movem.l	d0-d7/a0-a6,-(sp)
	clr.w	(matchup).w
	moveq	#0,d0
	moveq	#$1C,d1
	jsr	(SetupScreen).l
	jsr	(printz).l
	String	$BE,1,$B
	move.w	#8,d0
	move.w	#8,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	$BE,1,$13
	move.w	#8,d0
	move.w	#8,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	$9E,2,$C
	movea.l	#TeamLogoBitmaps,a0
	move.w	(VisTeam).w,d0
	asl.w	#2,d0
	movea.l	0(a0,d0.w),a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	asl.w	#3,d0
	movea.l	#TeamLogoPalettes,a0
	subi.w	#$40,d0
	adda.w	d0,a0
	adda.l	(a2)+,a1
	clr.w	d1
	clr.w	d0
	moveq	#6,d2
	move.w	#6,d3
	moveq	#4,d5
	jsr	(dobitmap).l
	movea.l	#palfadenew+$40,a0
	movea.l	#palfadenew+$60,a1
	move.w	#7,d0
.loop
	move.l	(a0)+,(a1)+
	dbf	d0,.loop
	jsr	(printz).l
	String	$8E,2,$14
	movea.l	#TeamLogoBitmaps,a0
	move.w	(HomeTeam).w,d0
	asl.w	#2,d0
	movea.l	0(a0,d0.w),a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	asl.w	#3,d0
	subi.w	#$40,d0
	movea.l	#TeamLogoPalettes,a0
	adda.w	d0,a0
	adda.l	(a2)+,a1
	clr.w	d1
	clr.w	d0
	moveq	#6,d2
	move.w	#6,d3
	moveq	#4,d5
	jsr	(dobitmap).l
	jsr	(printz).l
	String	$BD,4,1
	moveq	#$20,d0
	moveq	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	$BD,6,3,'  Period Stats  ',$BE,6,1
	btst	#1,(sflags7).w
	beq.w	.0
	jsr	(printz).l
	dc.w	$001C	;String length: too many arguments for the String macro (as 93)
	dc.b	$BE,$C,9,'1',$BE,$11,9,'2',$BE,$16,9,'3',$BE,$1A,9,'OT',$BE,' ',9,'Total',0
	jsr	(printz).l
	dc.w	$001C	;String length: too many arguments for the String macro (as 93)
	dc.b	$BE,$C,$A,'<',$BE,$11,$A,'<',$BE,$16,$A,'<',$BE,$1A,$A,'<<',$BE,' ',$A,'<<<<<',0
	bra.w	.1
.0
	jsr	(printz).l
	dc.w	$0016	;String length: too many arguments for the String macro (as 93)
	dc.b	$BE,$C,9,'1',$BE,$11,9,'2',$BE,$16,9,'3',$BE,' ',9,'Total'
	jsr	(printz).l
	dc.w	$0016	;String length: too many arguments for the String macro (as 93)
	dc.b	$BE,$C,$A,'<',$BE,$11,$A,'<',$BE,$16,$A,'<',$BE,' ',$A,'<<<<<'
.1
	bsr.w	.5
	bsr.w	.7
	move.w	#$18,(palcount).w
.loop2
	jsr	(WaitVSyncAndReadInput).l	;left (bit 2) goals, right (bit 3) shots, start exits
	btst	#7,d1
	bne.w	.4
	btst	#2,d1
	bne.w	.3
	btst	#3,d1
	bne.w	.2
	bra.s	.loop2
.2
	tst.w	(matchup).w
	bne.s	.loop2
	st	(matchup).w
	bsr.w	.5
	bsr.w	.7
	bra.s	.loop2
.3
	tst.w	(matchup).w
	beq.s	.loop2
	clr.w	(matchup).w
	bsr.w	.5
	bsr.w	.7
	bra.s	.loop2
.4
	movem.l	(sp)+,d0-d7/a0-a6
	jmp	(ExitAttributeScreen2).l
.5
	tst.w	(matchup).w
	beq.w	.6
	jsr	(printz).l
	String	$BE,$12,7,'Shots',$BE,$F,$1A,'[ For Goals'
	rts
.6
	jsr	(printz).l
	String	$BE,$12,7,'Goals',$BE,$F,$1A,'For Shots ]'
	rts
.7
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printz).l
	String	$BE,0,0
	movea.l	#AwShots,a2
	move.w	#$E,(printy).w
	bsr.w	.8
	movea.l	#HmShots,a2
	move.w	#$16,(printy).w
	bsr.w	.8
	movem.l	(sp)+,d0-d7/a0-a6
	rts
.8
	lea	$342(a2),a0
	tst.w	(matchup).w
	beq.w	.9
	lea	$34A(a2),a0
.9
	clr.w	(matchuptimer).w
	move.w	#$B,(printx).w
	bsr.w	.12
	cmpi.w	#1,(gsp).w
	blt.w	.10
	move.w	#$10,(printx).w
	bsr.w	.12
	cmpi.w	#2,(gsp).w
	blt.w	.10
	move.w	#$15,(printx).w
	bsr.w	.12
	cmpi.w	#3,(gsp).w
	blt.w	.10
	btst	#1,(sflags7).w
	beq.w	.10
	move.w	#$1A,(printx).w
	bsr.w	.12
.10
	move.w	#$21,(printx).w
	jsr	(printz).l
	String	'   '
	subq.w	#3,(printx).w
	move.w	(matchuptimer).w,d0
	move.w	#2,d1
	cmp.w	#$64,d0
	blt.w	.11
	move.w	#3,d1
.11
	jsr	(PushNumberWidth).l
	jsr	(print).l
	rts
.12
	move.w	(a0)+,d0
	add.w	d0,(matchuptimer).w
	jsr	(printz).l
	String	'   '
	subq.w	#3,(printx).w
	move.w	#2,d1
	cmp.w	#$64,d0
	blt.w	.13
	move.w	#3,d1
.13
	jsr	(PushNumberWidth).l
	jmp	(print).l
GameStatisticsScreen	;IDA left it as data; 93 name. "Game Statistics" menu item (hockey94_11 menu lists): both teams' totals
	;(DisplayTeamStatsScreen). 94 has more rows than the screen: up / down scroll them (matchupvis the most, $70 or $30 without penalties,
	;OptPen), start exits (ExitAttributeScreen2)
	moveq	#9,d0
	moveq	#$1A,d1
	jsr	(SetupScreen).l
	jsr	(printz).l
	String	$BD,4,1
	moveq	#$20,d0
	moveq	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	$BD,6,4,'Game  Statistics',$BD,7,1
	move.w	#$2C,d0
	jsr	(PrintTeamData).l
	addq.w	#4,(printx).w
	clr.w	d0
	jsr	(PrintTeamData).l
	clr.w	(DispAttribCtr).w
	clr.w	(VertLineScrolling).w
	clr.w	(PlayerScrollCtr).w
	move.w	#$70,(matchupvis).w	;the most scroll: 15 rows
	tst.w	(OptPen).w
	bne.w	.0
	move.w	#$30,(matchupvis).w	;11 rows
.0
	bsr.w	DisplayTeamStatsScreen
	bsr.w	PrintStatScrollArrows
.loop
	jsr	(vcountwait).l
	jsr	(getpzjoy).l
	btst	#7,d3
	beq.w	.1
	jmp	(ExitAttributeScreen2).l
.1
	jsr	(nodiag).l
	move.w	#$FFFE,d0
	btst	#0,d3
	bne.w	.2
	neg.w	d0
	btst	#1,d3
	beq.w	.3
.2
	move.w	d0,(PlayerScrollCtr).w
.3
	bsr.w	.4
	bsr.w	PrintStatScrollArrows
	bra.s	.loop
.4
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtsStatTables
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtsStatTables
	cmp.w	(matchupvis).w,d0
	bgt.w	rtsStatTables
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	andi.w	#$F,d0
	bne.w	.5
	clr.w	(PlayerScrollCtr).w
.5
	andi.w	#$F,d1
	bne.w	SetStatScroll
	move.w	d0,-(sp)
	cmp.w	#$E,d0
	bne.w	.6
	bsr.w	StatScrollRow
.6
	move.w	(sp)+,d0
	cmp.w	#2,d0
	bne.w	SetStatScroll
	bsr.w	StatScrollRowEnd
SetStatScroll	;Plane A vertical scroll (VSRAM 0) = VertLineScrolling - $50, with disflags bit 2 set while it writes
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#$40020010,4(a0)
	move.w	#$FFB0,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts
StatScrollRow	;d3 = VertLineScrolling / 16 (GameStatisticsScreen, at a scroll step)
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3
	bra.w	rtsStatScroll
StatScrollRowEnd	;d3 = VertLineScrolling / 16 + 6 (GameStatisticsScreen, at a scroll step)
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3
	addq.w	#6,d3
	bra.w	rtsStatScroll
rtsStatScroll	;rts of StatScrollRow / StatScrollRowEnd
	rts
PrintStatScrollArrows	;GameStatisticsScreen scroll arrows (printz2): up ($7B) when VertLineScrolling > 0, down ($7D) when it is below matchupvis
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printz2).l
	String	$F9,1
	tst.w	(VertLineScrolling).w
	beq.w	.0
	jsr	(printz2).l
	String	$F8,4,3,'&',8,$F9,1,'{'
	bra.w	.1
.0
	jsr	(printz2).l
	String	$F8,4,3,'&',8,$F9,1,' '
.1
	move.w	(matchupvis).w,d0
	cmp.w	(VertLineScrolling).w,d0
	beq.w	.2
	jsr	(printz2).l
	String	$F8,4,3,'&',$1A,$F9,1,'}'
	bra.w	.3
.2
	jsr	(printz2).l
	String	$F8,4,3,'&',$1A,$F9,1,' '
.3
	jsr	(printz2).l
	String	$F9
	movem.l	(sp)+,d0-d7/a0-a6
	rts
DisplayTeamStatsScreen	;93 name. Team logos (PrintTeamData), then each TeamStatTextTbl row (TeamStatTextTblNoPen when penalties are
	;off, OptPen) centred, with the home value at x $22 and the visitors' at x 9 (FormatStatValue); SetStatScroll first
	jsr	(printz).l
	String	$BD,2,7
	move.w	#$2C,d0
	jsr	(PrintTeamData).l
	jsr	(printz).l
	String	$BD,$1A,7
	moveq	#0,d0
	jsr	(PrintTeamData).l
	bsr.w	SetStatScroll
	jsr	(printz).l
	String	$BE,0,0
	moveq	#$E,d6
	lea	TeamStatTextTbl(pc),a1
	tst.w	(OptPen).w
	bne.w	.loop
	move.w	#$A,d6
	lea	TeamStatTextTblNoPen(pc),a1
.loop
	move.w	(a1),d0
	lsr.w	#1,d0
	neg.w	d0
	addi.w	#$15,d0
	move.w	d0,(printx).w
	jsr	(print).l
	movea.l	a1,a0
	move.w	#$22,(printx).w
	movea.w	#(HmShots-M68K_RAM),a2
	bsr.w	FormatStatValue
	move.w	#9,(printx).w
	lea	$364(a2),a2
	bsr.w	FormatStatValue
	lea	4(a0),a1
	addq.w	#2,(printy).w
	dbf	d6,.loop
	rts
FormatStatValue	;93 name. Print TeamStatTextTbl entry a0 for team a2 centred at printx: the value (offsets $A and $352 are times,
	;PushTime), "/second" if any, " (pct%)" for passing. 94: offset $FFFF is the shooting percentage (goals $C * 100 / shots 0), printed with a
	;"%"
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#2,(a3)
	cmpi.w	#$FFFF,(a0)	;shooting percentage row
	bne.w	.1
	move.w	#$C,d0
	move.w	(a2,d0.w),d0
	mulu.w	#$64,d0
	move.w	#0,d1
	move.w	(a2,d1.w),d1
	beq.w	.0
	divu.w	d1,d0
.0
	jsr	(PushNumber).l
	jsr	(appstring).l
	jsr	(appendz).l
	String	'%'
	bra.w	.6
.1
	move.w	(a0),d0
	move.w	(a2,d0.w),d0
	cmpi.w	#$352,(a0)	;PP Minutes: a time
	bne.w	.2
	bsr.w	.8
	bra.w	.4
.2
	cmpi.w	#$A,(a0)
	beq.w	.3
	bsr.w	.7
.3
	cmpi.w	#$A,(a0)
	bne.w	.4
	bsr.w	.8
.4
	jsr	(appstring).l
	move.w	2(a0),d0
	bmi.w	.6
	jsr	(appendz).l
	String	'/'
	move.w	(a2,d0.w),d0
	jsr	(PushNumber).l
	jsr	(appstring).l
	cmpi.w	#$14,(a0)
	bne.w	.6
	jsr	(appendz).l
	String	' ('
	move.w	(a0),d0
	move.w	(a2,d0.w),d0
	mulu.w	#$64,d0
	move.w	2(a0),d1
	move.w	(a2,d1.w),d1
	beq.w	.5
	divu.w	d1,d0
.5
	jsr	(PushNumber).l
	jsr	(appstring).l
	jsr	(appendz).l
	String	'%)'
.6
	movea.w	a3,a1
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	jmp	(print).l
.7
	jmp	(PushNumber).l
.8
	jmp	(PushTime).l
TeamStatTextTbl	;93 name. Label, then the team struct stat offset and the second offset ($FFFF none). 15 rows
	dc.w	$0008
	dc.b	'Score',0
	dc.w	$C,$FFFF
	dc.w	$0008
	dc.b	'Shots',0
	dc.w	0,$FFFF
	dc.w	$000E
	dc.b	'Shooting Pct'
	dc.w	$FFFF,$FFFF
	dc.w	$000C
	dc.b	'Power Play'
	dc.w	2,4
	dc.w	$000C
	dc.b	'PP Minutes'
	dc.w	$352,$FFFF
	dc.w	$000A
	dc.b	'PP Shots'
	dc.w	$354,$FFFF
	dc.w	$000A
	dc.b	'SH Goals'
	dc.w	$356,$FFFF
	dc.w	$000C
	dc.b	'Breakaways'
	dc.w	$35A,$358
	dc.w	$000C
	dc.b	'One-Timers'
	dc.w	$35E,$35C
	dc.w	$0010
	dc.b	'Penalty Shots',0
	dc.w	$362,$360
	dc.w	$000E
	dc.b	'Faceoffs Won'
	dc.w	$E,$FFFF
	dc.w	$000E
	dc.b	'Body Checks',0
	dc.w	$10,$FFFF
	dc.w	$000C
	dc.b	'Penalties',0
	dc.w	6,8
	dc.w	$000E
	dc.b	'Attack Zone',0
	dc.w	$A,$FFFF
	dc.w	$000A
	dc.b	'Passing',0
	dc.w	$14,$12
TeamStatTextTblNoPen	;94 only. The rows without the power play ones, used when penalties are off. 11 rows
	dc.w	$0008
	dc.b	'Score',0
	dc.w	$C,$FFFF
	dc.w	$0008
	dc.b	'Shots',0
	dc.w	0,$FFFF
	dc.w	$000E
	dc.b	'Shooting Pct'
	dc.w	$FFFF,$FFFF
	dc.w	$000C
	dc.b	'Breakaways'
	dc.w	$35A,$358
	dc.w	$000C
	dc.b	'One-Timers'
	dc.w	$35E,$35C
	dc.w	$0010
	dc.b	'Penalty Shots',0
	dc.w	$362,$360
	dc.w	$000E
	dc.b	'Faceoffs Won'
	dc.w	$E,$FFFF
	dc.w	$000E
	dc.b	'Body Checks',0
	dc.w	$10,$FFFF
	dc.w	$000C
	dc.b	'Penalties',0
	dc.w	6,8
	dc.w	$000E
	dc.b	'Attack Zone',0
	dc.w	$A,$FFFF
	dc.w	$000A
	dc.b	'Passing',0
	dc.w	$14,$12
rtsStatTables	;rts after the stat tables (GameStatisticsScreen scroll step)
	rts
updatePPTeamTime	;IDA name (and comments). 94 only: one more second of power play time ($352 of the team struct) for the team on the power play
	;(sflags2 bit 5, bit 6 the visitors). Called from updatepentime (penalty94_1)
	btst	#5,(sflags2).w	;check if PP
	beq.w	.x	;branch if not
	movea.l	#HmShots,a2	;move home team struct into a2
	btst	#6,(sflags2).w	;check who's on PP
	beq.w	.0	;branch if home (team 1)
	movea.l	#AwShots,a2	;move away team struct into a2
.0
	addq.w	#1,$352(a2)	;add 1 to PP team total
.x
	rts
GetTeamRating	;94 only. d0 = the TeamRatings byte of team $28(a2). Called from PrintTeamRating (high94_2, the player card "Team Rating") and PrintMatchupRating (hockey94_07)
	movem.l	d1-d7/a0-a6,-(sp)
	move.w	Xvel(a2),d0
	movea.l	#TeamRatings,a0
	clr.w	d1
	move.b	0(a0,d0.w),d1
	move.w	d1,d0
	movem.l	(sp)+,d1-d7/a0-a6
	rts
TeamRatings	;GetTeamRating values, one byte per team (TeamList order)
	dc.b	$33,$4C,$49,$4B,$4E,$43,$4B,$43,$34,$42,$4A,$49,$44,$42
	dc.b	$4A,$37,$45,$4B,$47,$38,$45,$38,$48,$47,$48,$46,$5B,$59
ShortenMsgTimer	;94 only. Cap msgtimer at 2, unless a second pad is on (cont2team) and a3 is not the puck carrier. Called from doinput (logic94_1)
	movem.l	d0,-(sp)
	tst.w	(cont2team).w
	beq.w	.0
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	bne.w	.x
.0
	cmpi.w	#2,(msgtimer).w
	ble.w	.x
	move.w	#2,(msgtimer).w
.x
	movem.l	(sp)+,d0
	rts
