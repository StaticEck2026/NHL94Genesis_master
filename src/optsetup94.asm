;	Game setup screen. This file runs the option menu, starts a game or the demo, and prints each
;	option within its limits. New in 94: the goalie and user record options, the shootout, 4 Way
;	Play, and team logos on the setup screen.

;	Options (d7 = line * 2, the offset from OptPlayMode): 0 OptPlayMode (Regular Season,
;	Continue Playoffs, New Playoffs, New Playoffs/7 game, Shootout), 2 OptNOP, 4 Opt1Team,
;	6 Opt2Team, 8 OptPerlen, $A OptGoalie, $C OptUserRec (0 On), $E OptPen (0 Off), $10
;	OptLine (0 On, 2 Auto). setupcardflags bits: 0 player card up, 1 card side (visitors),
;	2 / 3 home / visitors block drawn, 5 C pressed, 6 / 7 home / visitors logo shown.
;	printz String first byte, negated: low 2 bits = map, the rest << 9 = printa.

GameSetUp							;Game setup screen, called from PeriodOver. Builds the screen
									;(setoptions), then runs the menu: up / down move the frame, left / right
									;change the option (ChangeOption) and redraw (FixModeOptions), start
									;begins the game (SetupStart), and $5460 frames without a press start a
									;demo (SetupDemo).
	jsr	(ReadLineData).l
	movea.l	#pwddatabuffer,a3		;saved playoff state
	jsr	(ReadPassBits).l
	move.w	(TmpOptLine2).w,(OptLine).w	;undo the start changes of SetupStart (Auto line changes, Shootout)
	move.w	(TempOptPlayMode).w,(OptPlayMode).w
	bclr	#1,(sflags7).w
	jsr	(ClearGameStats).l
	jsr	(ReadNameLog).l				;read the SRAM name list
	bsr.w	setoptions				;build the screen
	clr.w	(setupfirstline).w		;first menu line shown
	clr.w	(setupprevline).w
	bsr.w	PrintOptionNames		;option names
	tst.w	(demoflag).w			;clear after a demo
	bne.w	.shootout				;keep the teams
	moveq	#NumTeams,d0
	jsr	(randomd0).l
	move.w	d0,(Opt1Team).w			;random teams after a demo (0 through NumTeams-1)
	moveq	#NumTeams,d0
	jsr	(randomd0).l
	move.w	d0,(Opt2Team).w
.shootout
	st	(demoflag).w
	cmpi.w	#4,(OptPlayMode).w		;check if shootout
	bne.w	.newplay				;branch if not
	bra.w	.reggame				;branch if so
.newplay
	cmpi.w	#2,(OptPlayMode).w		;check if new playoffs
	blt.w	.contplay				;branch if cont. playoffs or reg season
	bsr.w	GoNewPlayoffs			;new playoffs: random tree
.contplay
	cmpi.w	#1,(OptPlayMode).w		;check if cont playoffs
	bne.w	.reggame				;branch if not
	bsr.w	GoContinuePlayoffs		;continue playoffs
.reggame
	clr.w	d7						;menu line 0 (d7 = line * 2 = offset in OptPlayMode ... OptLine)
	clr.w	d0
	bsr.w	MoveMenuFrame			;frame the line
	bsr.w	FixModeOptions			;print the options
	move.w	(HomeTeam).w,(setuphome).w
	move.w	(HomeTeam).w,(logoteam).w
	bsr.w	DrawHomeBlock			;home team block
	move.w	(VisTeam).w,(setupvis).w
	move.w	(VisTeam).w,(logoteam).w
	bsr.w	DrawVisBlock			;visitors team block
	move.w	#$18,(palcount).w		;24
	bclr	#dfng,(disflags).w		;dfng: fade in graphics now
.loop
	cmpi.w	#4,(OptPlayMode).w		;Shootout: line changes Off, penalties Off, user records Off
	bne.w	.0
	move.w	#1,(OptLine).w
	move.w	#0,(OptPen).w
	move.w	#1,(OptUserRec).w
.0
	bsr.w	ReadSetupPads			;d1 = new presses, 0 after $5460 frames
	tst.w	d1
	bne.w	.1
	bra.w	SetupDemo				;none: demo
.1
	btst	#sbut,d1				;sbut
	bne.w	SetupStart				;start the game
	btst	#dbut,d1				;dbut: next line, past the lines that do not apply (Demo: Goalies, User
									;Records; Shootout: Per. Length, nothing after Goalies; no SRAM: User
									;Records)
	beq.w	.9
	tst.w	(OptNOP).w
	bne.w	.2
	cmp.w	#8,d7
	bne.w	.2
	move.w	#4,d0
	bra.w	.3
.2
	move.w	#2,d0
.3
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.4
	tst.w	(OptNOP).w
	bne.w	.4
	cmp.w	#8,d7
	bne.w	.4
	move.w	#6,d0
	bra.w	.8
.4
	cmp.w	#6,d7
	bne.w	.5
	cmpi.w	#4,(OptPlayMode).w
	bne.w	.5
	tst.w	(OptNOP).w
	bne.w	.7
	clr.w	d0
	bra.w	.8
.5
	cmp.w	#$A,d7
	bne.w	.8
	cmpi.w	#4,(OptPlayMode).w
	bne.w	.6
	clr.w	d0
	bra.w	.8
.6
	tst.w	(ValidSRAM).w
	bpl.w	.8
.7
	move.w	#4,d0
.8
	bsr.w	MoveMenuFrame
	bsr.w	FixModeOptions
	bra.w	.loop
.9
	btst	#ubut,d1				;ubut: previous line, the same skips
	beq.w	.15
	tst.w	(OptNOP).w
	bne.w	.10
	cmp.w	#$C,d7
	bne.w	.10
	move.w	#$FFFC,d0
	bra.w	.11
.10
	move.w	#$FFFE,d0
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.11
	tst.w	(OptNOP).w
	bne.w	.11
	cmp.w	#$E,d7
	bne.w	.11
	move.w	#$FFFA,d0
	bra.w	.14
.11
	cmp.w	#$A,d7
	bne.w	.12
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.13
.12
	cmp.w	#$E,d7
	bne.w	.14
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.13
	tst.w	(ValidSRAM).w
	bpl.w	.14
.13
	move.w	#$FFFC,d0
.14
	bsr.w	MoveMenuFrame
	bsr.w	FixModeOptions
	bra.w	.loop
.15
	moveq	#1,d2
	btst	#rbut,d1				;rbut
	bne.w	.16
	btst	#lbut,d1				;lbut
	beq.w	.loop
	moveq	#-1,d2
.16
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.17
	jsr	(FigureJoy).l
.17
	move.w	(Opt2Team).w,-(sp)
	move.w	(Opt1Team).w,-(sp)
	bsr.w	ChangeOption			;change the option by d2
	move.w	(sp)+,d0
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.18
	tst.w	(OptPlayMode).w
	bne.w	.19
.18
	move.w	(Opt1Team).w,(HomeTeam).w	;Regular Season and Shootout: the menu teams
	move.w	(Opt2Team).w,(VisTeam).w
.19
	move.w	(HomeTeam).w,(logoteam).w
	btst	#6,(setupcardflags).w	;home logo shown?
	beq.w	.20
	movem.w	d0,-(sp)
	move.w	(setuphome).w,d0
	cmp.w	(HomeTeam).w,d0
	movem.w	(sp)+,d0
	beq.w	.21
.20
	move.w	(HomeTeam).w,(setuphome).w
	bsr.w	DrawHomeBlock
.21
	btst	#7,(setupcardflags).w	;visitors logo shown?
	beq.w	.22
	movem.w	d0,-(sp)
	move.w	(setupvis).w,d0
	cmp.w	(VisTeam).w,d0
	movem.w	(sp)+,d0
	beq.w	.23
.22
	move.w	(VisTeam).w,(setupvis).w
	move.w	(VisTeam).w,(logoteam).w
	bsr.w	DrawVisBlock
	move.w	(HomeTeam).w,(logoteam).w
.23
	tst.w	(sp)+
	bra.w	.fix					;redraw
	move.w	(sp)+,d0				;unreferenced: an older copy of the team block update above
	cmp.w	(VisTeam).w,d0
	beq.w	.fix
	move.w	(VisTeam).w,(logoteam).w
	movem.w	d0,-(sp)
	move.w	(VisTeam).w,d0
	cmp.w	(VisTeam).w,d0
	movem.w	(sp)+,d0
	beq.w	.24
	move.w	(VisTeam).w,(setupvis).w
	bsr.w	DrawVisBlock
.24
	movem.w	d0,-(sp)
	move.w	(setuphome).w,d0
	cmp.w	(HomeTeam).w,d0
	movem.w	(sp)+,d0
	beq.w	.fix
	move.w	(HomeTeam).w,(setuphome).w
	move.w	(HomeTeam).w,(logoteam).w
	bsr.w	DrawHomeBlock
	move.w	(VisTeam).w,(logoteam).w
.fix
	bsr.w	FixModeOptions
	bra.w	.loop
	rts								;unreferenced
GoNewPlayoffs						;New playoffs: jmp NewPO. Called from GameSetUp and ChangeOption
	jmp	NewPO
GoContinuePlayoffs					;Continue playoffs: jmp ContinuePlayoffs. Called from GameSetUp
	jmp	ContinuePlayoffs
MoveMenuFrame						;Move the menu frame by d0 (+2 / -2 lines). Shows 6 of the 9 lines and
									;scrolls: setupfirstline = first line shown
									;(0-3), setupprevline = the one before (sflags5 bit 2 set on a scroll;
									;FixModeOptions reprints the names when they differ). Continue playoffs
									;skips lines 1-3, new playoffs line 3 (Team 2). The old frame is erased by
									;redrawing the SetupMenuMap background under it. Called from GameSetUp
	move.w	d7,d3
.optionup
	bclr	#2,(sflags5).w
	tst.w	d0
	bpl.w	.optiondown
	move.w	d0,-(sp)
	move.w	d7,d0
	asr.w	#1,d0
	cmp.w	(setupfirstline).w,d0
	bne.w	.noscroll
	move.w	(setupfirstline).w,(setupprevline).w
	bset	#2,(sflags5).w
	subq.w	#1,(setupfirstline).w
	bpl.w	.noscroll
	clr.w	(setupfirstline).w
.noscroll
	move.w	(sp)+,d0
.optiondown
	move.w	d7,(TempWord1).w
	add.w	d0,d7
	bpl.w	.0
	clr.w	d7
.0
	tst.w	d0
	bmi.w	.3
	move.w	d0,-(sp)
	move.w	d7,d0
	asr.w	#1,d0
	sub.w	(setupfirstline).w,d0
	cmp.w	#5,d0
	bgt.w	.scrolldown
	bra.w	.2
.scrolldown
	move.w	(setupfirstline).w,(setupprevline).w
	bset	#2,(sflags5).w
	addq.w	#1,(setupfirstline).w
	move.w	d7,d0
	asr.w	#1,d0
	sub.w	(setupfirstline).w,d0
	cmp.w	#5,d0
	ble.w	.1
	addq.w	#1,(setupfirstline).w
.1
	cmpi.w	#3,(setupfirstline).w
	ble.w	.2
	move.w	#3,(setupfirstline).w
.2
	move.w	(sp)+,d0
.3
	btst	#2,(sflags5).w
	bne.w	.4
	move.w	(setupfirstline).w,(setupprevline).w
.4
	cmp.w	#$12,d7					;past the last line (Line Changes)
	blt.w	.contplayoffs
	sub.w	d0,d7
.contplayoffs
	cmpi.w	#1,(OptPlayMode).w
	bne.w	.newplay
	tst.w	d7
	beq.w	.newplay
	cmp.w	#6,d7
	bls.w	.optionup
.newplay
	cmpi.w	#2,(OptPlayMode).w
	blt.w	.5
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.5
	cmp.w	#6,d7
	beq.w	.optionup
.5
	bsr.w	SetMenuArea				;printx $10, printy $E, 23 x 13
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(setupmenuchars).w,d4
	movea.l	#SetupMenuMap,a0		;menu background: redraw that part (sflags6 bit 0) over the old frame
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	move.w	(printx).w,d0
	subq.w	#1,d0
	move.w	d1,d3
	move.w	(printy).w,d1
	subi.w	#$E,d1
	moveq	#$17,d2
	moveq	#0,d5
	bset	#0,(sflags6).w
	jsr	(dobitmap).l
	bclr	#0,(sflags6).w
	movem.l	(sp)+,d0-d7/a0-a6
	move.w	d7,d3
	bsr.w	SetFrameRect			;the new frame
	move.w	#$6000,(printa).w
	jmp	Framer
SetMenuArea							;Set the menu area for MoveMenuFrame: printx $10, printy $E, d0 = 23 x d1
									;= 13
	jsr	(printz).l
	String	-TXMAP1,$10,$E			;(and dropped a word)
	move.w	#$17,d0
	move.w	#$D,d1
	rts
SetFrameRectUnused					;An unused copy of SetFrameRect without its printz that uses setupprevline
									;and stops at row $18
	add.w	d3,(printy).w
	move.w	(setupprevline).w,d0
	add.w	d0,d0
	sub.w	d0,(printy).w
	cmpi.w	#$18,(printy).w
	ble.w	.0
	move.w	#$18,(printy).w
.0
	moveq	#$17,d0
	moveq	#3,d1
	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtsSetup
	cmpi.w	#4,(OptPlayMode).w
	beq.w	rtsSetup
	cmp.w	#4,d3
	bne.w	rtsSetup
	moveq	#5,d1
	rts
SetFrameRect						;Frame position for line d3 (row $E + d3 - setupfirstline * 2), 23 x 3, or
									;23 x 5 for Team 1 in new playoffs.
									;MoveMenuFrame
	jsr	(printz).l
	String	-TXMAP1,$10,$E			;(and dropped a word)
	add.w	d3,(printy).w			;2 rows per line
	move.w	(setupfirstline).w,d0
	add.w	d0,d0
	sub.w	d0,(printy).w
	moveq	#$17,d0
	moveq	#3,d1
	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtsSetup
	cmpi.w	#4,(OptPlayMode).w
	beq.w	rtsSetup
	cmp.w	#4,d3
	bne.w	rtsSetup
	moveq	#5,d1
rtsSetup							;The shared rts; ChangeOption, PrintOptionValue, SetFrameRectUnused and
									;WrapOption branch to it
	rts
FixModeOptions						;Fix the options a mode does not allow, then print them: Shootout and Demo
									;set User Records Off, Demo sets both goalies to
									;Auto Control. Reprint the option names (PrintOptionNames) after a scroll,
									;then the values (PrintOptions) in the setup font (sflags6 bit 3:
									;printsmall uses setupfontchars). Called from GameSetUp
	movem.l	d0-d7/a0-a6,-(sp)
	cmpi.w	#4,(OptPlayMode).w
	bne.w	.0
	move.w	#1,(OptUserRec).w		;Off
.0
	tst.w	(OptNOP).w
	bne.w	.1
	move.w	#1,(OptUserRec).w		;Off
.1
	tst.w	(OptNOP).w
	bne.w	.2
	move.w	#0,(OptGoalie).w
	move.w	#0,(goaliemode1).w
	move.w	#0,(goaliemode2).w
	tst.w	(OptNOP).w
	bne.w	.2
	move.w	#1,(OptGoalie).w		;Auto Control
	move.w	#1,(goaliemode1).w		;both teams
	move.w	#1,(goaliemode2).w
.2
	move.w	(setupfirstline).w,d0
	cmp.w	(setupprevline).w,d0
	beq.w	.3
	bsr.w	PrintOptionNames
.3
	bset	#3,(sflags6).w
	bsr.w	PrintOptions
	bclr	#3,(sflags6).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
OptionLimits						;Number of values of each option
	dc.w	5,8,NumTeams,NumTeams,3,2,2,3,3
OptionLimits4Way					;The same with FourWayPlay (12 player choices)
	dc.w	5,$C,NumTeams,NumTeams,3,2,2,3,3
ChangeOption						;add d2 to option d7 (d2 = 0: only limit it) and wrap it in its range
									;(WrapOption). Entering Shootout saves User Records, Penalties and Line
									;Changes (TmpOptUserRec ...), leaving restores them; Team 1 in new
									;playoffs has NumPlayoffTeams teams; the Players range depends on the mode
									;and FourWayPlay. A new play mode starts the playoffs (ContinuePlayoffs /
									;GoNewPlayoffs). Called from GameSetUp and PrintOptions
	tst.w	d7
	bne.w	.2
	movem.w	d0/d2,-(sp)
	tst.w	d2
	beq.w	.1
	move.w	(OptPlayMode).w,d0
	add.w	d2,d0
	bpl.w	.0
	move.w	#4,d0
.0
	cmp.w	#4,d0
	bne.w	.1
	move.w	(OptUserRec).w,(TmpOptUserRec).w
	move.w	(OptPen).w,(TmpOptPen).w
	move.w	(OptLine).w,(TmpOptLine).w
.1
	movem.w	(sp)+,d0/d2
	tst.w	d7
	bne.w	.2
	tst.w	d2
	beq.w	.2
	cmpi.w	#4,(OptPlayMode).w
	bne.w	.2
	move.w	(TmpOptUserRec).w,(OptUserRec).w
	move.w	(TmpOptPen).w,(OptPen).w
	move.w	(TmpOptLine).w,(OptLine).w
.2
	movea.w	#(OptPlayMode-M68K_RAM),a2
	movea.l	#OptionLimits,a3
	tst.w	(FourWayPlay).w
	beq.w	.3
	movea.l	#OptionLimits4Way,a3
.3
	clr.w	d5
	move.w	0(a3,d7.w),d4
	move.w	0(a2,d7.w),d3
	cmpi.w	#2,(OptPlayMode).w
	blt.w	.4
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.4
	cmp.w	#4,d7
	bne.w	.4
	moveq	#NumPlayoffTeams,d4		;playoff teams, the all-stars excluded
.4
	cmp.w	#2,d7
	bne.w	.wrap
	cmpi.w	#4,(OptPlayMode).w
	bne.w	.9
	movem.w	d2,-(sp)
	add.w	(OptNOP).w,d2
	bpl.w	.5
	addq.w	#7,d2
.5
	cmp.w	#4,d2
	movem.w	(sp)+,d2
	ble.w	.7
	tst.w	d2
	bpl.w	.6
	move.w	#4,d2
	bra.w	.9
.6
	addq.w	#2,d2
	bra.w	.9
.7
	movem.w	d2,-(sp)
	add.w	(OptNOP).w,d2
	cmp.w	#3,d2
	movem.w	(sp)+,d2
	bne.w	.9
	tst.w	d2
	bpl.w	.8
	subq.w	#1,d2
	bra.w	.9
.8
	addq.w	#1,d2
.9
	moveq	#5,d5
	tst.w	(FourWayPlay).w
	beq.w	.10
	move.w	#$A,d4
	addq.w	#2,d5
.10
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.11
	tst.w	(OptPlayMode).w
	bne.w	.loop
.11
	clr.w	d5
	moveq	#5,d4
.loop
	tst.w	(FourWayPlay).w
	beq.w	.wrap
	addq.w	#2,d4
.wrap
	bsr.w	WrapOption				;wrap d3
	tst.w	(FourWayPlay).w
	beq.w	.set
	cmp.w	#2,d7
	bne.w	.set
	tst.w	d2
	bmi.w	.13
	cmp.w	#9,d3
	beq.w	.14
	cmp.w	#$A,d3
	beq.w	.14
	bra.w	.set
.13
	cmp.w	#$A,d3
	bne.w	.set
	move.w	#8,d3
	bra.w	.set
.14
	move.w	#$B,d3
.set
	move.w	d3,0(a2,d7.w)
	tst.w	d2
	beq.w	rtsSetup
	cmpi.w	#1,(OptPlayMode).w
	bne.w	.16
	tst.w	d7
	bne.w	.16
	jsr	(ContinuePlayoffs).l		;continue playoffs
	move.w	(gamelevel).w,d0
	or.w	(bosgames).w,d0
	beq.s	.loop
	rts
.16
	cmpi.w	#2,(OptPlayMode).w
	blt.w	rtsSetup
	cmpi.w	#4,(OptPlayMode).w
	beq.w	rtsSetup
	tst.w	d7
	beq.w	GoNewPlayoffs
	cmp.w	#4,d7
	beq.w	GoNewPlayoffs
	rts
WrapOption							;d3 + d2, wrapped into d5 ... d4-1. Called from ChangeOption
	add.w	d2,d3
	cmp.w	d5,d3
	bge.w	.0
	move.w	d4,d3
	subq.w	#1,d3
.0
	cmp.w	d4,d3
	blt.w	rtsSetup
	move.w	d5,d3
	rts
PrintOptions						;Limit each option (ChangeOption with d2 = 0) and print the lines shown
									;(PrintOptionValue), the scroll marks (PrintScrollMarks) the team bitmaps
									;(DrawMatchupBitmaps) and, unless a player card is up, reset the card
									;timer (ResetCardTimer). Called from FixModeOptions
	move.w	d7,d6
	moveq	#-2,d7
.loop
	addq.w	#2,d7
	clr.w	d2
	bsr.w	ChangeOption
	movem.l	d7,-(sp)
	asr.w	#1,d7
	cmp.w	(setupfirstline).w,d7
	movem.l	(sp)+,d7
	blt.w	.0
	bsr.w	PrintOptionValue
.0
	cmp.w	#$10,d7
	bne.s	.loop
	bsr.w	PrintScrollMarks
	move.w	d6,d7
	jsr	(DrawMatchupBitmaps).l
	btst	#0,(setupcardflags).w
	bne.w	.x
	jsr	(ResetCardTimer).l
.x
	rts
PrintOptionValue					;print the value of option d7 at x $11 on its line (past row $1B:
									;nothing). Team 1 / 2 go to PrintOptTeamName Per. Length in
									;Shootout prints 'N/A'; Players with FourWayPlay uses the second list
									;(+$B0). Called from PrintOptions
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$11,$10
	move.w	(setupfirstline).w,d0
	add.w	d0,d0
	sub.w	d0,(printy).w
	add.w	d7,(printy).w
	cmpi.w	#$1B,(printy).w
	bgt.w	rtsSetup
	subq.w	#1,(printy).w
	move.w	#$11,(printx).w
	cmp.w	#4,d7
	beq.w	PrintOptTeamName
	cmp.w	#6,d7
	beq.w	PrintOptTeamName
	movea.l	#OptPlayMode,a0
	move.w	0(a0,d7.w),d3
	movea.l	#OptionValueOffsets,a0	;value Strings of option d7
	adda.w	0(a0,d7.w),a0
	cmpa.l	#PerLengthValues,a0
	bne.w	.0
	cmpi.w	#4,(OptPlayMode).w
	bne.w	.0
	movea.l	#NATxt,a1
	jmp	print
.0
	tst.w	(FourWayPlay).w
	beq.w	.loop
	cmp.w	#2,d7
	bne.w	.loop
	adda.w	#$B0,a0					;4 way Players list
.loop
	movea.l	a0,a1
	adda.w	(a0),a0
	dbf	d3,.loop
	jmp	print
PrintScrollMarks					;Print the scroll marks at x 2: '}' at row $19 when more lines follow
									;(first line < 3), '{' at row $F when lines are above (first line > 0),
									;else a space
	move.w	#$19,(printy).w
	movea.l	#ScrollClearTxt,a1
	cmpi.w	#3,(setupfirstline).w
	beq.w	.0
	cmpi.w	#4,(OptPlayMode).w
	beq.w	.0
	movea.l	#ScrollDownTxt,a1
.0
	move.w	#2,(printx).w
	jsr	(print).l
	movea.l	#ScrollClearTxt,a1
	move.w	#$F,(printy).w
	tst.w	(setupfirstline).w
	beq.w	.1
	movea.l	#ScrollUpTxt,a1
.1
	move.w	#2,(printx).w
	jmp	print
ScrollUpTxt	String	'{'				;Scroll marks for PrintScrollMarks
ScrollDownTxt	String	'}'
ScrollClearTxt	String	' '
PrintOptTeamName					;Print team name d3 of option d7 (TeamList city; 'New York Islanders' /
									;'New York Rangers' for teams $D / $E).
									;PrintOptionValue
	move.w	(printx).w,-(sp)
	movea.l	#BlankValueTxt,a1
	jsr	(print).l
	move.w	(sp)+,(printx).w
	movea.l	#OptPlayMode,a1
	move.w	0(a1,d7.w),d3
	movea.w	#TeamList,a1
	asl.w	#2,d3
	movea.l	0(a1,d3.w),a1
	lsr.w	#2,d3
	adda.w	4(a1),a1
	cmp.w	#$E,d3
	bne.w	.0
	movea.l	#RangersTxt,a1
	bra.w	.1
.0
	cmp.w	#$D,d3
	bne.w	.1
	movea.l	#IslandersTxt,a1
.1
	jmp	print
IslandersTxt	String	'New York Islanders'	;Full names for the two New York teams (TeamList has only the
												;city)
RangersTxt	String	'New York Rangers'
BlankValueTxt	String	'                    '	;A blank value
NATxt	String	'N/A                 '	;Per. Length in Shootout
OptionValueOffsets					;Offsets of each option's value Strings. Team 1 / 2 are not read
									;(PrintOptTeamName); User Records uses the On / Off list
	dc.w	PlayModeValues-OptionValueOffsets,PlayersValues-OptionValueOffsets,UserRecValues-OptionValueOffsets,UserRecValues-OptionValueOffsets,PerLengthValues-OptionValueOffsets
	dc.w	GoaliesValues-OptionValueOffsets,UserRecValues-OptionValueOffsets,PenaltiesValues-OptionValueOffsets,LineChangeValues-OptionValueOffsets
PlayModeValues						;Play Mode: OptPlayMode 0-4
	String	'Regular Season      '
	String	'Continue Playoffs   '
	String	'New Playoffs        '
	String	'New Playoffs/7 game '
	String	'Shootout            '
PlayersValues						;Players: OptNOP 0-7, then the FourWayPlay list (+$B0)
	String	'Demo                '
	String	'One - Home          '
	String	'One - Visitor       '
	String	'Two - Teammates     '
	String	'Two - Head to Head  '
	String	'Two - Head to Head  '
	String	'Two - Teammates     '
	String	'One                 '
	String	'Demo                '
	String	'One - Home          '
	String	'One - Visitor       '
	String	'Two - Teammates     '
	String	'Two - Head to Head  '
	String	'Three               '
	String	'Four                '
	String	'Two - Head to Head  '
	String	'Two - Teammates     '
	String	'Three               '
	String	'Four                '
	String	'One                 '
PerLengthValues						;Per. Length
	String	'5 Minutes           '
	String	'10 Minutes          '
	String	'20 Minutes          '
	String	'30 Seconds          '
GoaliesValues						;Goalies
	String	'Manual Control      '
	String	'Auto Control        '
PenaltiesValues						;Penalties option values
	String	'Off                 '
	String	'On                  '
	String	'On, Except Off-sides'
UserRecValues						;User Records, and the unread Team 1 / 2 entries
	String	'On                  '
	String	'Off                 '
LineChangeValues					;Line Changes (Off, On, Auto)
	String	'On                  '
	String	'Off                 '
	String	'Auto                '
PrintOptionNames					;Print the option names from OptionNames at x 3, 2 rows apart from row $F
									;- setupfirstline * 2, rows $F-$19 only.
									;from
									;GameSetUp and FixModeOptions
	movem.l	d0-d1,-(sp)
	bset	#3,(sflags6).w
	movea.l	#OptionNames,a1
	move.w	#$F,d0
	move.w	(setupfirstline).w,d1
	add.w	d1,d1
	sub.w	d1,d0
	move.w	d0,(printy).w
.loop
	cmpi.w	#$F,(printy).w
	bge.w	.0
	adda.w	(a1),a1
	bra.w	.1
.0
	cmpi.w	#$19,(printy).w
	bgt.w	.done
	move.w	#3,(printx).w
	move.w	#0,(printa).w
	move.w	#0,(printm).w
	jsr	(printsmall).l
.1
	addq.w	#2,(printy).w
	bra.s	.loop
.done
	bclr	#3,(sflags6).w
	movem.l	(sp)+,d0-d1
	rts
OptionNames							;Option names; the last entry is an empty String (dc.w 4,0)
	String	'Play Mode    '
	String	'Players      '
	String	'Team 1       '
	String	'Team 2       '
	String	'Per. Length  '
	String	'Goalies      '
	String	'User Records '
	String	'Penalties    '
	String	'Line Changes '
	dc.w	4,0
setoptions							;options screen display: build the game setup screen only: vblank vram
									;maps, the TeamBitmaps+8 tiles (LoadSetupTiles), framer, small font and
									;setup font tiles, the screen and menu bitmaps, the logo box tiles and
									;defaultsprites2. Called from GameSetUp
	move.l	#VBlank_SetOptions,(vbint).w
	move	#$2500,sr
	bclr	#dfok,(disflags).w		;#dfok - graphics are ready for transfer (clr = not ready)
	bset	#dfng,(disflags).w		;#dfng - dont int graphics
	bclr	#df32c,(disflags).w		;#df32c - 32 bit column mode (clr = off)
	move.w	#0,(VSCRLPM).w
	move.w	#$B400,(VSPRITES).w
	move.w	#$B800,(VmMap3).w
	move.w	#5,(Map3col1).w
	move.w	#$C000,(VmMap2).w
	move.w	#6,(Map2col1).w
	move.w	#$E000,(VmMap1).w
	move.w	#6,(Map1col1).w
	move.w	#0,d0					;fade to color
	jsr	(setVram).l
	jsr	(orjoy).l
	jsr	(LoadSetupTiles).l			;TeamBitmaps+8 tiles 
	move.w	d4,(framercset).w
	movea.l	#SetupFramerMap+8,a2	;framer tiles
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$03567564,$89ABCDEF		;remap table (/ or.l, a word dropped)
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2		;small font
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$0FC04567,$89ABCDEF		;remap table (/ or.l)
	move.w	d4,(setupfontchars).w
	movea.l	#PrintFont2Map+8,a2		;setup screen font (printsmall with sflags6 bit 3)
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$01234567,$89ABCDEF		;remap table (/ or.l)
	jsr	(printz).l
	String	-TXMAP1,0,0				;x2
	moveq	#$28,d0
	moveq	#$1C,d1					;40 x 28
	move.w	#$7FF,d2				;blank char
	jsr	(eraser).l
	jsr	(printz).l
	String	-TXMAP2,0,0				;x3
	movea.l	#GameSetUpMap,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2
	moveq	#$1C,d3
	moveq	#$D,d5					;color fam 1, 3, 4
	jsr	(dobitmap).l
	move.w	d4,(vispicchars).w
	addi.w	#$24,d4
	jsr	(printz).l
	String	-TXMAP1,0,0				;x3
	movea.l	#GameSetUpMap2,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2
	moveq	#4,d3					;40 x 4
	moveq	#0,d5
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-TXMAP1,1,$E			;(and dropped a word)
	move.w	d4,(setupmenuchars).w
	movea.l	#SetupMenuMap,a0		;menu background, 38 x 13 at x 1, y $E
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$26,d2
	moveq	#$D,d3
	moveq	#0,d5
	jsr	(dobitmap).l
	move.w	d4,(homepicchars).w
	addi.w	#$24,d4
	move.w	d4,(logobox1chars).w
	movea.l	#LogoBoxMap+8,a2		;logo box tiles
	jsr	(DecompressGraphicsPlain).l
	move.w	d4,(logobox2chars).w
	movea.l	#LogoBoxMap+8,a2		;again, remapped
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$03414567,$89ABCDEF		;remap table (/ or.l, a word dropped)
	jsr	(defaultsprites2).l
	move.w	#$28,(SortCords+OldXpos).w
	move.w	#$28,(SortCords+(6*SCstruct)+OldXpos).w
	st	(tmstruct).w
	st	(AwShots).w
	rts
ReadSetupPads						;wait up to $5460 frames (6 minutes) for a press on any pad (4 with
									;FourWayPlay); return d1 = the presses, 0 on timeout. C does not return:
									;it sets setupcardflags bit 5 (next player card sooner). When only one
									;logo is shown (after a player card) redraws the team blocks. For the
									;first $E10 frames of the wait, and while a card is up, runs the player
									;cards (PlayerCardTimer), else resets their timer (ResetCardTimer). Called
									;from GameSetUp
	move.l	#$5460,d6				;21600 frames
.loop
	move.w	(vcount).w,d1
	sub.w	(oldvcount).w,d1
	beq.s	.loop
	move.w	(vcount).w,(oldvcount).w
	bclr	#5,(setupcardflags).w
	jsr	(UpdateRosterPlayers).l
	jsr	(ReadJoy1).l
	jsr	(ProcessInputWithRepeat).l
	tst.w	d1
	beq.w	.1
	btst	#cbut,d1				;cbut
	beq.w	.x						;another button: return
	btst	#5,d2
	beq.w	.0
	move.w	#$53,(cardtimer).l
.0
	bset	#5,(setupcardflags).w
.1
	jsr	(ReadJoy2).l
	jsr	(ProcessInputWithRepeat).l
	tst.w	d1
	beq.w	.2
	btst	#5,d1
	beq.w	.x
	bset	#5,(setupcardflags).w
.2
	tst.w	(FourWayPlay).w
	beq.w	.4
	jsr	(ReadJoy3).l
	jsr	(ProcessInputWithRepeat).l
	tst.w	d1
	beq.w	.3
	btst	#5,d1
	beq.w	.x
	bset	#5,(setupcardflags).w
.3
	jsr	(ReadJoy4).l
	jsr	(ProcessInputWithRepeat).l
	tst.w	d1
	beq.w	.4
	btst	#5,d1
	beq.w	.x
	bset	#5,(setupcardflags).w
.4
	btst	#6,(setupcardflags).w
	beq.w	.5
	btst	#7,(setupcardflags).w
	bne.w	.6
	move.w	(setupvis).w,(logoteam).w
	bsr.w	DrawVisBlock
.5
	btst	#7,(setupcardflags).w
	beq.w	.6
	move.w	(setuphome).w,(logoteam).w
	bsr.w	DrawHomeBlock
.6
	cmp.w	#$4650,d6				;the first $E10 frames (a minute)?
	bgt.w	.timer
	btst	#0,(setupcardflags).w
	bne.w	.timer
	jsr	(ResetCardTimer).l
	bra.w	.8
.timer
	jsr	(PlayerCardTimer).l			;player cards
.8
	dbf	d6,.loop
.x
	rts
SetupDemo							;Demo after no press for $5460 frames. Clear demoflag, seed RNGseed,
									;Regular Season, Demo, line changes On
									;penalties On. Falls into SetupStart. Branched to from GameSetUp
	clr.w	(demoflag).w
	move.w	(HVcount).l,(seed).w
	move.w	(HVcount).l,(seed+2).w
	clr.w	(OptPlayMode).w
	clr.w	(OptNOP).w				;Demo
	clr.w	(OptLine).w
	move.w	#1,(OptPen).w			;On
SetupStart							;Start pressed: Copy Goalies to both teams, set pojoy, seed RNGseed, and
									;keep OptLine / OptPlayMode in TmpOptLine2 / TempOptPlayMode: Auto line
									;changes play as On with sflags7 bit 4, Shootout as Regular Season with
									;gmode2 bit 0 (ClearShootout). Then jmp MakeTree. Branched to from
									;GameSetUp
	move.w	(OptGoalie).w,-(sp)
	move.w	(sp),(goaliemode1).w
	move.w	(sp)+,(goaliemode2).w
	jsr	(UpdatePlayoffLevel).l
	move.w	(HVcount).l,(seed).w
	move.w	(HVcount).l,(seed+2).w
	move.w	(OptLine).w,(TmpOptLine2).w
	cmpi.w	#2,(OptLine).w
	bne.w	.0
	clr.w	(OptLine).w
	bset	#4,(sflags7).w
.0
	move.w	(OptPlayMode).w,(TempOptPlayMode).w
	cmpi.w	#4,(OptPlayMode).w
	bne.w	.1
	move.w	#0,(OptPlayMode).w
	bset	#0,(gmode2).w
	jsr	(ClearShootout).l
.1
	jmp	maketree
CheckNOPUnused						;unreferenced. Tests OptNOP for 0, 5, 6, 9 and $A and returns: no effect
	tst.w	(OptNOP).w
	beq.w	.x
	cmpi.w	#5,(OptNOP).w
	beq.w	.x
	cmpi.w	#6,(OptNOP).w
	beq.w	.x
	cmpi.w	#9,(OptNOP).w
	beq.w	.x
	cmpi.w	#$A,(OptNOP).w
.x
	rts
LoadSetupTiles						;Load the TeamBitmaps+8 tiles from char 2, then again remapped
									;teambitmapchars.
									;Called
									;from setoptions
	moveq	#2,d4					;vram char 2
	movea.l	#TeamBitmaps+8,a2
	jsr	(DecompressGraphicsPlain).l
	move.w	d4,(teambitmapchars).w
	movea.l	#TeamBitmaps+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$03412567,$89ABCDEF		;remap table (/ move.l / dc.b)
	rts
UpdateRosterPlayers					;An empty routine, called from ReadSetupPads. An unused rts follows
	rts
	rts
EraseCard							;If a player card is up (setupcardflags bit 0, cleared here), clear both
									;logo flags (bits 6 / 7) and erase the card: its logo box and its 25 x 8
									;box. Called from DrawHomeBlock and DrawVisBlock
	movem.l	d0-d7,-(sp)
	bclr	#0,(setupcardflags).w
	beq.w	.x
	bclr	#6,(setupcardflags).w
	bclr	#7,(setupcardflags).w
	jsr	(printz).l
	String	-(TXPAL1+TXMAP1),0,0	;x3
	move.w	#5,(printy).w
	moveq	#8,d0
	moveq	#8,d1
	move.w	#$7FF,d2
	btst	#1,(setupcardflags).w
	beq.w	.1
	move.w	#3,(printx).w
	jsr	(eraser).l
	jsr	(printz).l
	String	-TXMAP1,0,0				;x3
	move.w	#$B,(printx).w
	move.w	#5,(printy).w
	move.w	#$19,d0
	move.w	#8,d1
.0
	move.w	#$7FF,d2
	jsr	(eraser).l
	bra.w	.x
.1
	move.w	#$1C,(printx).w
	jsr	(eraser).l
	jsr	(printz).l
	String	-TXMAP1,0,0				;x3
	move.w	#3,(printx).w
	move.w	#5,(printy).w
	move.w	#$19,d0
	move.w	#8,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
.x
	movem.l	(sp)+,d0-d7
	rts
DrawHomeBlock						;Draw the home team block: the logo box and the HomeTeam logo (logoteam)
									;at x $19, y 6. setupcardflags bit 2
									;home drawn, bit 6: home logo shown. Called from GameSetUp and
									;ReadSetupPads
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	EraseCard
	bset	#2,(setupcardflags).w
	bset	#6,(setupcardflags).w
	bsr.w	LogoBoxHome
	bclr	#3,(setupcardflags).w
	beq.w	.0
	jsr	(printz).l
	String	-(TXPAL1+TXMAP1),0,0	;x3
	move.w	#8,(printx).w
	move.w	#5,(printy).w
	moveq	#8,d0
	moveq	#8,d1
	move.w	#$7FF,d2
.0
	jsr	(printz).l
	String	-TXMAP1,0,0				;x3
	move.w	#$19,(printx).w
	bra.w	DrawTeamLogo
DrawVisBlock						;The same for the visitors: logo box, logo at x 9. setupcardflags bit 3,
									;bit 7. Called from GameSetUp and ReadSetupPads
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	EraseCard
	bset	#3,(setupcardflags).w
	bset	#7,(setupcardflags).w
	bsr.w	LogoBoxVis
	bclr	#2,(setupcardflags).w
	beq.w	.0
	jsr	(printz).l
	String	-(TXPAL1+TXMAP1),0,0	;x3
	move.w	#$18,(printx).w
	move.w	#5,(printy).w
	moveq	#8,d0
	moveq	#8,d1
	move.w	#$7FF,d2
.0
	jsr	(printz).l
	String	-(TXPAL3+TXMAP1),0,0
	move.w	#9,(printx).w
DrawTeamLogo						;Draw the logo of team logoteam at printx, y 6, 6 x 6, palette
									;TeamLogoPalettes + team * 8 - $20 (home, color fam
									;2) or - $40 (visitors, color fam 3), then wait $B4 frames before a player
									;card (carddelay). Branched to
	;  from DrawHomeBlock
	move.w	#$B4,(carddelay).w		;180 frames
	move.w	#6,(printy).w
	move.w	(homepicchars).w,d4
	btst	#2,(setupcardflags).w
	bne.w	.0
	move.w	(vispicchars).w,d4
.0
	move.w	(logoteam).w,d3
	asl.w	#2,d3
	movea.l	#TeamLogoBitmaps,a0
	movea.l	0(a0,d3.w),a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	asl.w	#3,d3
	movea.l	#TeamLogoPalettes,a0
	btst	#2,(setupcardflags).w
	beq.w	.1
	subi.w	#$20,d3
	bra.w	.2
.1
	subi.w	#$40,d3
.2
	adda.w	d3,a0
	adda.l	(a2)+,a1
	move.w	#6,d3
	move.w	#6,d2
	clr.w	d0
	clr.w	d1
	move.l	(palfadenew+$22).w,-(sp)
	move.l	(palfadenew+$26).w,-(sp)
	move.w	#4,d5
	btst	#2,(setupcardflags).w
	beq.w	.draw
	move.w	#2,d5
.draw
	jsr	(dobitmap).l
	move.l	(sp)+,(palfadenew+$26).w
	move.l	(sp)+,(palfadenew+$22).w
	move.w	#$64,(palcount).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
TeamLogoBitmaps						;Team logo bitmaps by team number (TeamList
									;order); also used by GetTeamLogo
	dc.l	logoANH,logoBOS,logoBUF,logoCGY,logoCHI,logoDAL,logoDET,logoEDM
	dc.l	logoFLA,logoHFD,logoLA,logoMTL,logoNJ,logoNYI,logoNYR,logoOTW
	dc.l	logoPHI,logoPIT,logoQUE,logoSJ,logoSTL,logoTB,logoTOR,logoVAN
	dc.l	logoWSH,logoWPG,logoASE,logoASW
TeamLogoBitmapsEnd
	IF (TeamLogoBitmapsEnd-TeamLogoBitmaps)<>(NumTeams*4)
		inform	3,"TeamLogoBitmaps needs one entry per team"
	ENDIF
LogoBoxRight						;Logo box (LogoBoxMap, 8 x 8) at x $1C, y 5 with the logobox1chars tiles.
									;Called from PlayerCardScreen
	move.w	(logobox1chars).w,d4
	move.w	#$1C,(printx).w
	bra.w	DrawLogoBox
LogoBoxHome							;Logo box at x $18 (home block). Called from DrawHomeBlock
	move.w	(logobox1chars).w,d4
	move.w	#$18,(printx).w
	bra.w	DrawLogoBox
LogoBoxLeft							;Logo box at x 3 with the logobox2chars tiles.
									;Called from PlayerCardScreen
	move.w	(logobox2chars).w,d4
	move.w	#3,(printx).w
	bra.w	DrawLogoBox
LogoBoxVis							;Logo box at x 8 (visitors block). Called from DrawVisBlock
	move.w	(logobox2chars).w,d4
	move.w	#8,(printx).w
DrawLogoBox							;Draw the LogoBoxMap box at printx, y 5 (sflags6 bit 0 set). Branched to
									;from LogoBoxRight ... LogoBoxVis
	clr.w	(printa).w
	move.w	#5,(printy).w
	movea.l	#LogoBoxMap,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	move.w	#8,d3
	move.w	#8,d2
	clr.w	d0
	clr.w	d1
	move.w	#0,d5
	bset	#0,(sflags6).w
	jsr	(dobitmap).l
	bclr	#0,(sflags6).w
	rts
