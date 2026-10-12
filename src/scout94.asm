;	Scouting report. This file shows the pregame matchups screen with its pages of team text,
;	ratings, pictures and positions, and marks which team has the advantage.

ScoutCrowdRecord	;The text player's '@' (ScoutTextPlayer): return a1 = the home team's crowd record in dB as a String at TempBuffer (SRAM team record
	;byte 8, 80 if 0). ReadCrowdRecord reads the 16 byte SRAM record of team d1 ($B60 + d1 * 16) to a0
	movem.l	d0-d7/a0/a2-a6,-(sp)
	move.w	(HomeTeam).w,d1
	ext.l	d1
	movea.l	#teamrecbuf,a0	;SRAM team record buffer
	move.l	a0,-(sp)
	jsr	(ReadCrowdRecord).l	;read the HomeTeam record
	movea.l	(sp)+,a0
	movea.l	#TempBuffer,a1	;String buffer
	clr.w	d0
	move.b	8(a0),d0	;crowd record
	bne.w	.0
	move.b	#$50,d0	;none saved: 80 dB
.0
	move.l	a1,-(sp)
	jsr	(AppendNumber).l	;d0 as a decimal String at a1
	movea.l	(sp)+,a1
	movem.l	(sp)+,d0-d7/a0/a2-a6
	rts
ScoutCrowdRecordBy	;unused: return a1 = 'by <name> ' for the home team's crowd record (SRAM record byte 9 =
	;name number, AppendUserName reads that 12 char name from namelog), or an empty String if byte 9 is 0
	movem.l	d0-d7/a0/a2-a6,-(sp)
	move.w	(HomeTeam).w,d1
	ext.l	d1
	movea.l	#teamrecbuf,a0
	move.l	a0,-(sp)
	jsr	(ReadCrowdRecord).l
	movea.l	(sp)+,a0
	tst.b	9(a0)	;name number
	beq.w	.0
	movea.l	#ThreeStars,a3	;String buffer
	movea.l	#ScoutByTxt,a1
	move.l	a3,-(sp)
	jsr	(CopyString).l	;copy the String at a1 to a3: 'by '
	movea.l	(sp)+,a3
	clr.w	d2
	move.b	9(a0),d2
	movea.l	#TempBuffer,a1	;name String buffer
	bset	#7,(sflags6).w
	bsr.w	AppendUserName
	jsr	(appstring).l	;append the name
	movea.l	#ScoutSpaceTxt,a1
	jsr	(appstring).l	;and ' '
	movea.l	a3,a1	;a1 = 'by <name> '
	bra.w	.x
.0
	movea.l	#ScoutEmptyTxt,a1
.x
	movem.l	(sp)+,d0-d7/a0/a2-a6
	rts
ScoutEmptyTxt	String	''
ScoutByTxt	String	'by '
ScoutSpaceTxt	String	' '
GetTeamCity	;unused: return a1 = the city String of team byte $A(a0) (TeamList, Teamname offset)
	movem.l	d0-d7/a0/a2-a6,-(sp)
	clr.w	d2
	move.b	$A(a0),d2
	asl.w	#2,d2
	movea.l	#TeamList,a1
	movea.l	0(a1,d2.w),a1
	adda.w	4(a1),a1
	movem.l	(sp)+,d0-d7/a0/a2-a6
	rts
ScoutingReport	;pregame MATCHUPS screen, called from Opening2. Draws the Ron Barr picture, the text box and the matchup
	;matchup 0 is both team logos with the team ratings, 1-6 the two players at center, left forward, right forward, left defense, right defense
	;and goalie with their ratings, with marks toward the side that has the advantage. The text player (ScoutTextPlayer)
	;types the paragraph list. A / C page the matchups (the page also turns by itself about every $10E frames), down types fast, start leaves
	jsr	(ReadNameLog).l	;read the $80 byte SRAM name list at $DA0 to $FFD45A
	jsr	(BuildHotColdLists).l	;hot / cold players for the text
	clr.w	(advframe).w	;advantage mark frame
	move.w	#SngScout,-(sp)	;song $7A
	jsr	(song).l
	move.l	#vb2,(vbint).w
	jsr	(clearTeamStats).l
	move.l	a0,-(sp)
	movea.l	#tmstruct,a0
	jsr	(Create_HotCold_Table).l	;new random hot / cold tables ($1A2(a0))
	movea.l	#AwShots,a0
	jsr	(Create_HotCold_Table).l
	movea.l	(sp)+,a0
	jsr	(BuildHotColdLists).l	;again with the new tables
	bclr	#df32c,(disflags).w	;df32c
	move.w	#6,(Map1col1).w
	move.w	#6,(Map2col1).w
	move.w	#0,d0	;fade to color
	jsr	(setVram).l
	move.w	#2,d4	;vram chars from 2
	move.w	d4,(homepicchars).w	;home picture chars (6 x 6)
	addi.w	#$24,d4
	move.w	d4,(vispicchars).w	;visitors picture chars
	addi.w	#$24,d4
	move.w	d4,(BigFontChars).w
	movea.l	#BigFontMap+8,a2	;big font tiles
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$05431567,$79ABCDEF	;remap table
	jsr	(AddSmallFont).l	;in the table
	move.w	d4,(smallfont2chars).w	;1st vram char of the 2nd small font set
	movea.l	#SmallFontMap+8,a2	;small font tiles (as AddSmallFont), remapped
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$0A234567,$89ABCDEF	;remap table
	movea.l	#FramerMap+8,a2	;framer tiles (as AddFramer), remapped
	move.w	d4,(framercset).w
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$05422561,$89ABCDEF	;remap table
	jsr	(printz).l
	String	-TXMAP2,0,0
	movea.l	#ScoutMap,a0	;the jsr, the string and this (ori.b x4)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2	;40 x 28 background
	moveq	#$1C,d3
	moveq	#3,d5	;color fam 1-2
	jsr	(dobitmap).l
	jsr	(printbigz).l
	String	-(TXPAL2+TXMAP1),$C,$D,'MATCHUPS'
	move.w	#0,(printfontset).w	;char set 0
	jsr	(printz).l
	String	-TXMAP1,$10,$11,'ADVANTAGE:'
	jsr	(printz).l
	String	-(TXPAL2+TXMAP2),6,3
	moveq	#$21,d0	;33 x 9 text box frame
	moveq	#9,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-(TXPAL2+TXMAP2),1,$E	;(and dropped a word)
	move.w	#8,d0	;8 x 8 frame: visitors picture
	move.w	#8,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-(TXPAL2+TXMAP2),$1F,$E	;(and dropped a word)
	move.w	#8,d0	;8 x 8 frame: home picture
	move.w	#8,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-TXMAP1,1,1
	movea.l	#RonBarrMap,a0	;Ron Barr picture: palette offset, then map header offset
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#$C,d5	;color fam 3-4
	jsr	(dobitmap).l
	movea.l	#HotIconMap+8,a2
	move.w	d4,(hoticonchars).w	;tiles: 1st vram char
	jsr	(DecompressGraphicsPlain).l
	movea.l	#ColdIconMap+8,a2
	move.w	d4,(coldiconchars).w	;tiles: 1st vram char
	jsr	(DecompressGraphicsPlain).l
	clr.w	(matchup).w	;matchup 0: the teams
	clr.w	(scoutunused).w
	move.w	#$10D,(matchuptimer).l	;frames to the next matchup
	bsr.w	GetMatchupPlayers	;the matchup players
	bsr.w	DrawMatchupPictures	;pictures
	bsr.w	PrintMatchupRatings	;ratings
	move.w	#$18,(palcount).w	;24
	move.l	#vb2,(vbint).w
	move	#$2500,sr
	jsr	(InitScoutingDisplay).l	;a0 = the paragraph list
	move.w	#$1B,(a0)+	;paragraph numbers in ScoutTextScript: 'Hi, I'm Ron Barr ...'
	move.w	#$1D,(a0)+	;empty paragraph: a blank line
	move.w	#$1A,(a0)+	;'Welcome to a sold out ^ ...'
	move.w	#$1D,(a0)+
	jsr	(CompareHotColdTotals).l	;d0 = $22 / $23 ('Lately $ has been playing (extremely) well.') when the team totals (GetHotColdTotal) differ by $5E / $BD or more, else -1
	tst.w	d0
	bmi.w	.0
	move.w	d0,(a0)+
	move.w	#$1D,(a0)+
.0
	move.w	(HomeTeam).w,d0
	move.w	#$1E,(a0)+	;home hot / cold player
	move.w	#$1D,(a0)+
	cmp.w	(VisTeam).w,d0
	beq.w	.1	;same team: one hot / cold paragraph
	move.w	#$1F,(a0)+	;visitors hot / cold player
.1
	move.w	#$1D,(a0)+
	move.w	#$20,(a0)+	;'The ^ crowd record is @ dB.'
	move.w	#$1D,(a0)+
	move.w	#$21,(a0)+	;'Hit the start button ...'
	move.w	#$FFFF,(a0)	;end of list
	clr.w	(asv).w	;fast text flag
	move.w	#$7FFF,(screentimer).w	;frames left on the screen
	move.l	#$8CA0,(scoutwait).w	;then 36000 more when OptNOP is not 0
.top
	moveq	#0,d0
	jsr	(waitx).l	;d1 = new presses
	subq.w	#1,(matchuptimer).w
	bpl.w	.2
	move.w	#$10E,(matchuptimer).l
.2
	bsr.w	PrintAdvantageMarks	;advantage marks
	btst	#7,d1	;sbut
	bne.w	.exit	;start leaves
	cmpi.w	#$10E,(matchuptimer).w
	beq.w	.3	;timer ran out: next matchup
	btst	#5,d1	;cbut
	beq.w	.4
	move.w	#$7FFF,(screentimer).w
	move.l	#$8CA0,(scoutwait).w
.3
	bsr.w	RestartAdvantageMarks
	move.w	#1,d0	;next matchup
	bsr.w	PageMatchup
	bra.w	.6
.4
	btst	#6,d1	;abut
	beq.w	.5
	move.w	#$7FFF,(screentimer).w
	move.l	#$8CA0,(scoutwait).w
	bsr.w	RestartAdvantageMarks
	move.w	#$FFFF,d0	;previous matchup
	bsr.w	PageMatchup
	bra.w	.6
.5
	clr.w	(asv).w
	btst	#1,d1	;dbut
	beq.w	.6
	st	(asv).w	;down: type the rest without delays
.6
	btst	#1,(waitxpad+1).w	;down held (waitx pad bits)
	beq.w	.upd
	st	(asv).w
.upd
	jsr	(UpdateScoutingDisplay).l
	subq.w	#1,(screentimer).w
	bpl.w	.top
	tst.w	(OptNOP).w
	beq.w	.exit	;OptNOP 0: leave when the text is done
	move.w	#$FFFF,(screentimer).w	;else wait for start, up to scoutwait frames
	subq.l	#1,(scoutwait).w
	bpl.w	.top
.exit
	move.w	#0,(printfontset).w	;char set 0
	rts
PageMatchup	;Page the matchup by d0 (+1 / -1, 0-6 wrapping), restart the page timer and redraw. Called from ScoutingReport
	move.w	#$10E,(matchuptimer).w
	add.w	(matchup).w,d0
	bmi.w	.0
	cmp.w	#7,d0
	blt.w	.1
	clr.w	d0
	bra.w	.1
.0
	move.w	#6,d0
.1
	move.w	d0,(matchup).w
	bsr.w	GetMatchupPlayers
	bsr.w	DrawMatchupPictures
	bsr.w	PrintMatchupRatings
	rts
PrintMatchupRating	;Print the team rating of team a0 (GetTeamRating: the TeamRatings byte for team number $28(a0)) as 2 digits at printx / printy; return d0 = the rating.
	;Called from PrintMatchupRatings
	bsr.w	PrintTwoSpaces	;clear the old number
	move.l	a2,-(sp)
	movea.l	a0,a2
	bsr.w	GetTeamRating
	movea.l	(sp)+,a2
	move.l	d0,-(sp)
	move.w	#2,d1	;2 digits
	jsr	(PushNumberWidth).l
	jsr	(printsmall).l
	move.l	(sp)+,d0
	rts
PrintTwoSpaces	;Print 2 spaces at printx / printy and keep printx
	move.l	a1,-(sp)
	move.w	(printx).w,-(sp)
	movea.l	#TwoSpacesTxt,a1
	jsr	(printsmall).l
	move.w	(sp)+,(printx).w
	movea.l	(sp)+,a1
	rts
TwoSpacesTxt	;A two space String (printsmall by PrintTwoSpaces)
	String	'  '
ScoutRatingText	;rating names; only ' Overall ' is printed (PrintMatchupRatings, matchup 0); -1 ends the list
	String	'Shooting'
	String	'Skating'
	String	'Passing'
	String	'Defense'
	String	'Checking'
	String	'Fighting'
	String	'Goalkeeping'
	String	'Power Play Adv.'
	String	'-    Home Team Adv.    '
	String	'    Overall     '
	dc.w	-1
DrawMatchupPictures	;Draw the matchup's 6 x 6 pictures, visitors at x 2, home at x $20, y $F: matchup 0 the team logos (GetTeamLogo, DrawMatchupLogo)
	;1-6 the two players' pictures (DrawPlayerPicture, DrawMatchupPicture). Called from ScoutingReport and PageMatchup
	movem.l	d0-d7/a0-a6,-(sp)
	tst.w	(matchup).w
	bne.w	.0
	move.w	(VisTeam).w,d3
	bsr.w	GetTeamLogo	;a0 = visitors logo
	move.w	#2,(printx).w
	move.w	#$F,(printy).w
	move.w	(vispicchars).w,d4
	move.w	#4,d5
	move.w	#$6000,(printa).w
	bsr.w	DrawMatchupLogo
	move.w	(HomeTeam).w,d3
	bsr.w	GetTeamLogo	;a0 = home logo
	move.w	#$20,(printx).w
	move.w	#$F,(printy).w
	move.w	(homepicchars).w,d4
	move.w	#0,(printa).w
	move.w	#2,d5
	bsr.w	DrawMatchupLogo
	move.w	#$64,(palcount).w	;100
	bra.w	.x
.0
	move.w	(VisTeam).w,d1
	move.w	(matchupvis).w,d0
	jsr	(DrawPlayerPicture).l	;a0 = picture of player d0 of team d1 (visitors)
	move.w	#2,(printx).w
	move.w	#$F,(printy).w
	move.w	(vispicchars).w,d4
	move.w	#2,d5
	move.w	#0,(printa).w
	bsr.w	DrawMatchupPicture
	move.w	(HomeTeam).w,d1
	move.w	(matchuphome).w,d0
	jsr	(DrawPlayerPicture).l	;home
	move.w	#$20,(printx).w
	move.w	#$F,(printy).w
	move.w	(homepicchars).w,d4
	move.w	#0,d5
	move.w	#0,(printa).w
	bsr.w	DrawMatchupPicture
	move.w	#$64,(palcount).w	;100
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
DrawMatchupPicture	;Draw player picture a0 at printx / printy with the PicturePalette palette. A picture with no map (offset 0) uses the PicturePalette
	;map. UnpackPicture, then the $FFDA1E tiles. Falls into DrawMatchupBitmap
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	movea.l	#PicturePalette,a0	;palette from PicturePalette
	adda.l	(a0),a0
	tst.l	(a2)	;no map?
	bne.w	.0
	movea.l	#PicturePalette,a1
	adda.l	4(a1),a1
	tst.l	(a2)+
	bra.w	.1
.0
	adda.l	(a2)+,a1
.1
	bsr.w	UnpackPicture
	movea.l	#picturebuf,a2	;tiles
	bra.w	DrawMatchupBitmap
DrawMatchupLogo	;Draw team logo a0 at printx / printy, palette TeamLogoPalettes + team d3 * 8 - $20 (d5 = 4: - $40). Falls into DrawMatchupBitmap
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	asl.w	#3,d3
	cmp.w	#4,d5
	beq.w	.0
	subi.w	#$20,d3
	bra.w	.1
.0
	subi.w	#$40,d3
.1
	movea.l	#TeamLogoPalettes,a0
	adda.w	d3,a0
	adda.l	(a2)+,a1
DrawMatchupBitmap	;6 x 6 dobitmap, then erase the 8 x 3 name area at y $19 on that side (x 2 or $20). Branched to from DrawMatchupPicture
	move.w	#6,d3
	move.w	#6,d2
	clr.w	d0
	clr.w	d1
	jsr	(dobitmap).l
	cmpi.w	#$14,(printx).w
	bgt.w	.0
	move.w	#2,(printx).l
	bra.w	.1
.0
	move.w	#$20,(printx).l
.1
	move.w	#$19,(printy).l
	move.w	#8,d0
	move.w	#3,d1
	move.w	#$7FF,d2	;blank char
	jsr	(eraser).l
	rts
GetTeamLogo	;Return a0 = the logo bitmap of team d3 (TeamLogoBitmaps table)
	asl.w	#2,d3
	movea.l	#TeamLogoBitmaps,a0
	movea.l	0(a0,d3.w),a0
	rts
PrintMatchupRatings	;Print the matchup ratings. Matchup 0: 'Overall' at y $13, the team ratings (PrintMatchupRating), home at x $22, visitors at x 4, y
	;$16. 1-6: the position name at y $13, the player names on y $17 (PrintPlayerNameRight; home right justified), and the player ratings at x $22 / 4, y
	;$16: CalcAttrib with the PAttribOverallMask (skater) or GAttribOverallMask (goalie) long in d4, * 100 / d1, AttribAdjust. The ratings go to homerating
	;(home) / visrating (visitors) for PrintAdvantageMarks. Called from ScoutingReport and PageMatchup
	tst.w	(matchup).w
	bne.w	.matchup
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,0,1,$16,$16,CC_SetFont,1
	lea	ScoutRatingText(pc),a1
	move.w	#0,d7
.loop
	move.w	(a1),d0
	asr.w	#1,d0
	neg.w	d0
	addi.w	#$16,d0	;center on column 22
	move.w	d0,(printx).w
	cmp.w	#9,d7	;only the 10th, 'Overall'
	beq.w	.0
	adda.w	(a1),a1
	bra.w	.1
.0
	move.w	#2,(printfontset).w
	move.w	(printy).w,-(sp)
	subq.w	#3,(printy).w	;y $13
	jsr	(printsmall).l
	move.w	(sp)+,(printy).w
.1
	addq.w	#1,d7
	tst.w	(a1)
	bpl.s	.loop
	move.w	#2,(printfontset).w
	jsr	(printz).l
	String	-TXMAP1,0,$17,'                                        '	;40 spaces
	jsr	(printz).l
	String	-TXMAP1,$22,$16
	movea.l	#tmstruct,a0
	movea.l	#AwShots,a2
	bsr.w	PrintMatchupRating	;home
	move.w	d0,(homerating).w
	move.w	#2,(printfontset).w
	jsr	(printz).l
	String	-TXMAP1,4,$16
	exg	a0,a2
	bsr.w	PrintMatchupRating	;visitors
	move.w	d0,(visrating).w
	bra.w	.x
.matchup
	move.w	(matchup).w,d0
	subq.w	#1,d0
	movea.l	#MatchupPosNames,a1	;position name of matchup - 1
	bra.w	.3
.loop2
	adda.w	(a1),a1
.3
	dbf	d0,.loop2
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,0,1,$D,$13,CC_SetFont,1
	jsr	(printsmall).l
	move.w	#$16,(printy).w
	move.w	#2,(printfontset).w
	movea.l	#tmstruct,a2
	move.l	(PAttribOverallMask).l,d4	;skater rating weights
	tst.w	(matchupslot).w	;line slot 0: goalie
	bne.w	.4
	move.l	(GAttribOverallMask).l,d4	;goalie
.4
	move.w	(matchuphome).w,d0	;home player
	jsr	(printz).l
	String	-TXMAP1,0,$17,'                                        '	;40 spaces
	jsr	(printz).l
	String	-TXMAP1,$23,$17
	bsr.w	PrintPlayerNameRight	;print the name, moved left to fit the line
	bsr.w	CalcAttrib
	mulu.w	#$64,d0	;* 100
	divu.w	d1,d0
	bsr.w	AttribAdjust
	move.w	#2,d1
	move.w	d0,(homerating).w
	jsr	(PushNumberWidth).l
	jsr	(printz).l
	String	-TXMAP1,$22,$16
	bsr.w	PrintTwoSpaces
	jsr	(printsmall).l
	movea.l	#AwShots,a2
	move.l	(PAttribOverallMask).l,d4
	tst.w	(matchupslot).w
	bne.w	.5
	move.l	(GAttribOverallMask).l,d4
.5
	move.w	(matchupvis).w,d0	;visitors player
	jsr	(printz).l
	String	-TXMAP1,0,$17
	bsr.w	PrintPlayerNameRight
	bsr.w	CalcAttrib
	mulu.w	#$64,d0	;* 100
	divu.w	d1,d0
	bsr.w	AttribAdjust
	move.w	d0,(visrating).w
	move.w	#2,d1
	jsr	(PushNumberWidth).l
	jsr	(printz).l
	String	-TXMAP1,4,$16
	bsr.w	PrintTwoSpaces
	jsr	(printsmall).l
.x
	rts
MatchupPosNames	;Position names of matchups 1-6
	String	'     center     '
	String	' left forward   '
	String	' right forward  '
	String	'left defenseman '
	String	'right defenseman'
	String	'     goalie     '
GetMatchupPlayers	;matchuphome / matchupvis = the home / visitors player of the matchup. Called from ScoutingReport and PageMatchup
	movem.l	d0/a0-a1,-(sp)
	movea.l	#tmstruct,a0
	bsr.w	GetMatchupPlayer
	move.w	d0,(matchuphome).w
	movea.l	#AwShots,a0
	bsr.w	GetMatchupPlayer
	move.w	d0,(matchupvis).w
	movem.l	(sp)+,d0/a0-a1
	rts
GetMatchupPlayer	;Return d0 = the roster index of team a0's player for matchup: the first line of the team's line sets, slot
	;MatchupLineSlots[matchup] (matchupslot; 0 goalie, 1 left defense, 2 right defense, 3 left wing, 4 center, 5 right wing)
	movea.l	$1E(a0),a0	;tmdata
	adda.w	6(a0),a0	;LineSets
	move.w	(matchup).w,d0
	movea.l	#MatchupLineSlots,a1
	move.b	0(a1,d0.w),d0
	ext.w	d0
	move.w	d0,(matchupslot).w
	move.b	0(a0,d0.w),d0
	ext.w	d0
	subq.w	#1,d0	;player numbers start at 1
	rts
MatchupLineSlots	;Line slot by matchup 0-6 (0 for the teams, then 4 center, 3 left forward, 5 right forward, 1 left defense, 2 right defense,
	;0 goalie), and a pad byte
	dc.b	0,4,3,5,1,2,0,0
RestartAdvantageMarks	;Restart the advantage marks (PrintAdvantageMarks)
	clr.w	(advcount).w
	clr.w	(advframe).w
	rts
PrintAdvantageMarks	;Called every frame by ScoutingReport. Print the advantage marks at x $13, y $16: ']' marks growing toward the home
	;side (right) when the home rating is higher, '[' marks toward the visitors (left) when lower, one more every 7 frames up to 3; blank if equal
	movem.l	d0-d7/a0-a6,-(sp)
	addq.w	#1,(advcount).w
	cmpi.w	#7,(advcount).w
	blt.w	.0
	clr.w	(advcount).w
	addq.w	#1,(advframe).w
	cmpi.w	#6,(advframe).w
	blt.w	.0
	move.w	#5,(advframe).w
.0
	move.w	(advframe).w,d1
	asl.w	#2,d1
	movea.l	#HomeAdvMarks,a1
	move.w	(homerating).w,d0
	cmp.w	(visrating).w,d0	;home - visitors
	bgt.w	.1
	beq.w	.2
	movea.l	#VisAdvMarks,a1
.1
	movea.l	0(a1,d1.w),a1
	bra.w	.3
.2
	movea.l	#EvenAdvTxt,a1	;equal
.3
	move.w	#2,(printfontset).w
	jsr	(printz).l
	String	-TXMAP1,$13,$16
	jsr	(printsmall).l
	move.w	#0,(printfontset).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
HomeAdvMarks	;Home advantage marks, by advframe (0-5)
	dc.l	HomeAdv0Txt,HomeAdv1Txt,HomeAdv2Txt,HomeAdv3Txt,HomeAdv3Txt,HomeAdv3Txt
VisAdvMarks	;Visitors advantage marks
	dc.l	VisAdv0Txt,VisAdv1Txt,VisAdv2Txt,VisAdv3Txt,VisAdv3Txt,VisAdv3Txt
HomeAdv0Txt	String	'   '
HomeAdv1Txt	String	']  '
HomeAdv2Txt	String	']] '
HomeAdv3Txt	String	']]]'
VisAdv0Txt	String	'   '
VisAdv1Txt	String	'  ['
VisAdv2Txt	String	' [['
VisAdv3Txt	String	'[[['
EvenAdvTxt	String	'   '	;Even teams
GetTeamNickname	;The text player's '=' (a2 = HmShots) and '*' (AwShots): return a1 = the team nickname String, or 'Home' / 'Visitors' when it is empty (the all star teams)
	movem.l	d0/a0/a2,-(sp)
	movea.l	a2,a1
	movea.l	$1E(a1),a1	;tmdata
	adda.w	4(a1),a1	;city
	adda.w	(a1),a1	;abbreviation
	adda.w	(a1),a1	;nickname
	cmpi.w	#2,(a1)	;empty String?
	bne.w	.x
	movea.l	#HomeTxt,a1
	cmpa.l	#tmstruct,a2
	beq.w	.x
	movea.l	#VisitorsTxt,a1
.x
	movem.l	(sp)+,d0/a0/a2
	rts
HomeTxt	String	'Home'
VisitorsTxt	String	'Visitors'
GetTeamArena	;The text player's '^' (a2 = HmShots) and ';' (AwShots): return a1 = the team arena String
	movem.l	d0/a0/a2,-(sp)
	movea.l	a2,a1
	movea.l	$1E(a1),a1	;tmdata
	adda.w	4(a1),a1	;city
	adda.w	(a1),a1
	adda.w	(a1),a1
	adda.w	(a1),a1	;arena
	movem.l	(sp)+,d0/a0/a2
	rts
ScoutStub	;An empty routine
	movem.l	d0-d7/a0-a6,-(sp)
	movem.l	(sp)+,d0-d7/a0-a6
	rts
