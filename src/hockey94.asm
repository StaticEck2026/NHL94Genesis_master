;	VBjsr / Begin through seta2: startup, the game loop (StartGame, StartPer,
;	Gameloop, DoGameFrame), the periodic events, the clock, Pausemode and
;	the pause screen draw routine. The menu engine Pausemode calls follows.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	Inline print strings after printz2 use the String macro (length word includes itself).

VBjsr	;Vertical blank interrupt (vector $78), jumps through the vbint RAM vector
	move.l	(vbint).w,-(sp)		;push handler address
	rts				;and "return" into it

Begin	;cold start, entered from Start. Clear RAM, init sound and menus, go to title
	move	#$2700,sr		;interrupts off
	movea.w	#(Stack-M68K_RAM),sp	;stack pointer to RAM $FFFE
	movea.w	#(VSCRLPM-M68K_RAM),a0	;clear out ram
.0	clr.l	(a0)+			;clear RAM $B000-$DEF3
	cmpa.w	#$DEF4,a0
	blt.s	.0
	clr.w	(PALflag).w		;clear the PAL flag
	move.w	(VDP_CTRL).l,d0
	andi.w	#1<<PAL_MODE,d0		;VDP status bit 0 = PAL (50 Hz). it DMA busy; that is bit 1
	move.w	d0,(PalMode).w
	beq.w	.ntsc
	bset	#0,(PALflag).w	;PAL
.ntsc	jsr	(p_initialZ80).l		;sound stuff
	jsr	(p_turnoff).l
	jsr	(p_music_vblank).l
	jsr	(KillCrowd).l
	jsr	(Detect4WayPlay).l
	move.w	#$FFFF,(PadControlBits34).w
	jsr	(EASportsScreen).l
	jsr	(InitSaveRAM).l
	jsr	(ReadLineData).l
	jsr	(HiScoreScreen).l
	jsr	(DefaultMenus).l
	move.w	(OptLine).w,(TmpOptLine2).w
	move.w	(OptPlayMode).w,(TempOptPlayMode).w
	jsr	(orjoy).l		;clear any previous button presses
	jmp	Opening			;goto title screen and options etc.

StartGame	;reset game state for a new game, then start the first period
	st	(arenaanim).w
	clr.l	(homepresses).w
	clr.l	(awaypresses).w
	clr.l	(homedirpresses).w
	clr.l	(awaydirpresses).w
	jsr	(ReadJoy1).l		;pad 1 = $E0 at game start forces 30 second periods
	cmp.b	#$E0,d3
	bne.w	.chkpen
	move.w	#3,(OptPerlen).w	;period length index 3 = 30 seconds
.chkpen	clr.b	(gmode).w
	cmpi.w	#1,(OptPen).w
	bne.w	.0
	bset	#gmoffs,(gmode).w		;gmoffs: offsides pen. is active
.0	cmpi.w	#1,(OptPlayMode).w
	ble.w	.1			;OptPlayMode 0-1 keep the shot buffer
	bsr.w	ClearShotData
.1	jsr	(clearTeamStats).l
	btst	#0,(gmode2).w
	beq.w	.2
	move.l	a0,-(sp)
	movea.l	#tmstruct,a0
	jsr	(Create_HotCold_Table).l
	movea.l	#AwShots,a0
	jsr	(Create_HotCold_Table).l
	movea.l	(sp)+,a0
.2	clr.w	(ScoreSumbytes).w
	clr.w	(PenSumLength).w
	clr.w	(gsp).w			;first period
	clr.w	(ChkCnt).w
	bsr.w	restoreteams
	jsr	(InitScores).l
	jsr	(setupice).l
	jsr	(LoadCrowdRec).l
	jmp	IntermissionStart		;on to period start

ClearShotData	;Clear $E4 words at $FFD092
	move.w	#$E3,d0
	movea.w	#(outputbuffer-M68K_RAM),a0
.0	clr.w	(a0)+
	dbf	d0,.0
	rts

restoreteams	;Put both teams' rosters on the bench
	movea.w	#(tmstruct-M68K_RAM),a2	;team 1
	bsr.w	.r
	adda.w	#tmsize,a2		;team 2
.r	;reset one team struct (a2), falls in for team 2
	move.w	#6,tmap(a2)		;tmap: no players in pen. box
	moveq	#$32,d0			;(maxros-1)*2
.0	move.w	#$FFFE,tmpdst(a2,d0.w)	;tmpdst: -2 = all players on bench
	subq.w	#2,d0
	bpl.s	.0
	rts

ResetClock	;set period length and stop clock
	bsr.w	GetPeriodTime		;d0 = period length in seconds
	cmpi.w	#3,(gsp).w		;overtime?
	blt.w	.0
	tst.w	(OptPlayMode).w
	bne.w	.0
	move.w	#$258,d0		;OptPlayMode 0 overtime is always 10:00
.0	move.w	d0,(gameclock).w
	move.w	d0,(PerTimeTotal).w
	move.w	d0,(periodendtime).w	;CheckLateGameSong trigger time =
	asr.w	#1,d0
	jsr	(randomd0).l
	sub.w	d0,(periodendtime).w	;length - random(length/2)
	bset	#gmclock,(gmode).w		;gmclock: stop clock
	rts

GetPeriodTime	;Return d0 = period length in seconds for the period length option
	move.w	(OptPerlen).w,d0
	asl.w	#1,d0
	lea	.timetab(pc),a0
	move.w	0(a0,d0.w),d0
	rts
.timetab	;Period length in seconds: 5, 10, 20 min, 30 sec
	dc.w	5*60,10*60,20*60,30

StartPer	;start a period: reset stack, rink and clock, face off, run the game loop
	cmpi.w	#3,(gsp).w
	bne.w	.reg
	bset	#1,(sflags7).w	;overtime
.reg	st	(faceoffanim).w
	movea.w	#(Stack-M68K_RAM),sp
	jsr	(p_turnoff).l		;sound off
	jsr	(setupice).l
	bsr.s	ResetClock
	ori.w	#$F000,(PadControlBits).w
	st	(c1playernum).w		;no controlled player yet
	st	(c2playernum).w
	movea.w	#(puckx-M68K_RAM),a3	;puck
	clr.w	(fox).w			;face off at center ice
	clr.w	(foy).w
	btst	#0,(gmode2).w
	beq.w	.fo
	move.w	#$1E,d0
	move.w	#8,(BA_Skater_Offset).w
	move.w	#$B,(BA_Goalie_SCnum).w
	bra.w	.ass
.fo	move.l	#$1B,d0			;pfaceoff
.ass	jsr	(assreplace).l		;face off starts period
	bset	#sf2drec,(sflags2).w		;sf2drec: don't record
	bclr	#sfwrap,(sflags).w		;sfwrap: reset replay stuff
	move.w	#$FFFF,(lastsfx).w
	move.l	#M68K_RAM,(recbpr).w	;replaystart
	move.w	(vcount).w,(oldvcount).w
	bsr.w	DoGameFrame		;run two frames before the loop
	move.w	#$FFFF,(palcount).w
	bsr.w	DoGameFrame
	move.w	(gamelevel).w,d0
	asl.w	#4,d0
	move.w	d0,(CwdExciteLvl).w	;starting excitement = gamelevel*16
	clr.w	(CurCrowdMeter).w
	move.w	(HomeTeam).w,(HmTeam).w
	move.w	#0,(SongIndex).w
	jsr	(ChooseSong).l
	move.w	(SongNum).w,-(sp)	;period start tune
	jsr	(song).l
	cmpi.w	#2,(gsp).w
	bge.w	Gameloop
	bset	#7,(sflags3).w		;set for periods 1 and 2 only

Gameloop	;Main loop for game
	bsr.w	DoGameFrame
	bsr.w	demoread		;check if demo mode
	btst	#sfpz,(sflags).w		;sfpz
	beq.s	Gameloop
	bsr.w	Pausemode
	bra.s	Gameloop

DoGameFrame	;wait for at least one vblank, then run one frame of game logic
	move.w	(vcount).w,d7
	sub.w	(oldvcount).w,d7	;number of frames since last loop
	beq.s	DoGameFrame
	move.w	(vcount).w,(oldvcount).w
	bsr.w	periodicevents
	bsr.w	updateplayers		;apply velocity and check collisions
	tst.w	(songdelay).w		;delayed song countdown
	beq.w	.nosong
	bmi.w	.nosong
	subq.w	#1,(songdelay).w
	bne.w	.nosong
	jsr	(stop_current_song).l
	move.w	(delayedsong).w,-(sp)
	jsr	(song).l
.nosong	jsr	(setSlotBit).l
	bsr.w	checkwindow
	bsr.w	updatereplay
	jmp	setvideo

periodicevents	;Called every time thru game loop with d7 = elapsed frames
	jsr	(PenaltyManager).l
	bsr.w	updatecrowdf
	jsr	(RunArenaAnim).l
	jsr	(updatesound).l
	bsr.w	clockcont
	btst	#sfhor,(sflags).w		;sfhor
	bne.w	rtss8			;exit if in horizontal mode
	sub.w	d7,(lldisp).w		;count down for screen updates
	bpl.w	rtss8
	addi.w	#$18,(lldisp).w		;jps: only update once per second
	bsr.w	ChkGoalies
	bsr.w	UpdateCwdExcite
	bsr.w	CheckLateGameSong
	bsr.w	RestoreBenchEnergy
	bsr.w	CheckInjury
	jmp	updatepwrplay

CheckInjury	;Called once per second. Count down InjCntDown, act on it at zero
	subq.w	#1,(InjCntDown).w
	bne.w	rtss8
	jmp	ShowInjuryBox		;countdown expired

RestoreBenchEnergy	;Called once per second. Restore energy for players on the bench
	tst.w	(OptLine).w
	bne.w	.ex			;exit if line changes are off
	movea.w	#(tmstruct-M68K_RAM),a2	;team 1
	bsr.w	.notinprog
	lea	tmsize(a2),a2		;team 2 (tmsize)
.notinprog
	moveq	#$32,d0			;(maxros-1)*2
.b0	cmpi.w	#$FFFE,tmpdst(a2,d0.w)	;tmpdst: -2 = bench, -1 = ice, 0+ = pen box
	bne.w	.next
	addi.w	#9,tmpde(a2,d0.w)		;tmpde: energy +9
	cmpi.w	#$1000,tmpde(a2,d0.w)
	blt.w	.next
	move.w	#$1000,tmpde(a2,d0.w)	;max energy
.next	subq.w	#2,d0
	bpl.s	.b0
.ex	rts

CheckLateGameSong	;Called once per second. 3rd period: choose and play a song once at the
		;random trigger time set by ResetClock
	cmpi.w	#2,(gsp).w		;3rd period only
	bne.w	.x
	btst	#4,(gmode).w
	bne.w	.x
	move.w	(gameclock).w,d0
	cmp.w	(periodendtime).w,d0
	bgt.w	.x			;not there yet
	st	(periodendtime).w		;high byte $FF: trigger goes negative, fires once
	move.w	(HomeTeam).w,(HmTeam).w
	move.w	#5,(SongIndex).w
	jsr	(ChooseSong).l
	move.w	(SongNum).w,-(sp)
	jsr	(song).l
.x	rts

UpdateCwdExcite	;called once per second. Track peak and running total of crowd excitement, then
		;decay the level by 1 (floor 0)
	move.w	(CwdExciteLvl).w,d0
	cmp.w	(MaxCwdExciteLvl).w,d0
	bls.w	.less
	move.w	d0,(MaxCwdExciteLvl).w	;new peak
.less	ext.l	d0
	add.l	d0,(SumCwdExciteLvl).w	;running total
	addq.w	#1,(NumCwdExciteLvl).w	;sample count
	subq.w	#1,(CwdExciteLvl).w	;decay
	bpl.w	.ex
	clr.w	(CwdExciteLvl).w
.ex	rts

updatecrowdf	;this is called every game loop with d7 = elapsed frames
	;this will update the current frame of crowd animation
	cmpi.w	#$15E,(crowdlevel).w
	blt.w	.dec
	subq.w	#3,(crowdlevel).w	;loud crowd calms down faster
.dec	sub.w	d7,(crowdlevel).w
	bpl.w	.0
	clr.w	(crowdlevel).w
.0	sub.w	d7,(crowdcnt).w
	bpl.w	.cf
	move.w	(crowdlevel).w,d0
	lsr.w	#1,d0
	cmp.w	#$7F,d0
	bls.w	.1
	moveq	#$7F,d0
.1	andi.w	#$60,d0			;%01100000
	addq.w	#2,(crowdstep).w
	andi.w	#$1E,(crowdstep).w	;%00011110
	add.w	(crowdstep).w,d0
	movea.l	#cd0,a0			;$fftt frame/time table
	move.b	0(a0,d0.w),(crowdframe+1).w
	clr.w	d1
	move.b	1(a0,d0.w),d1
	move.w	(VDP_CNTR).l,d2		;HVcount
	and.w	d1,d2			;random 0..time
	add.w	d2,d1
	move.w	d1,(crowdcnt).w		;crowdcnt = time + random
.cf	clr.b	(crowdframe).w
	cmpi.w	#$118,(crowdlevel).w	;280
	bls.w	rtss8
	move.w	(VDP_CNTR).l,d0		;HVcount
	andi.w	#$7F,d0
	cmp.w	#$13,d0
	blt.w	rtss8
	cmp.w	#$19,d0
	bgt.w	rtss8
	move.b	d0,(crowdframe).w	;random extra frame 19-25 when crowd is loud
	rts

clockcont	;monitor period clock and initiate various clock activated events
	btst	#gmclock,(gmode).w		;gmclock
	bne.w	rtss8
	tst.w	(gameclock).w
	bne.w	rtss8
	bset	#3,(disflags).w		;dfclock: clock needs update
	jsr	(stop_current_song).l
	move.w	#SFXhorn,-(sp)		;horn
	jsr	(sfx).l
	bsr.w	freezewindow
clockcont_0	;End of period. Also entered from puckfaceoff
	movea.w	#(puckx-M68K_RAM),a3	;puck
	move.l	#$18,d0			;pucknothing assignment
	jsr	(assinsert).l
	cmpi.w	#2,(gsp).w		;periods 1-2 just end the period
	blt.w	.eop
	move.l	#7,d0			;score assignment
	movea.w	#(SortCords-M68K_RAM),a3
	cmpi.w	#3,(gamelevel).w	;playoffs?
	bne.w	.t3
	cmpi.w	#7,(bosgames).w
	beq.w	.sc			;bosgames 7 skips the series check

	;Stanley Cup if the winning team already has 3 series wins
	moveq	#$10,d3			;gssize
	mulu.w	(gamenum).w,d3
	movea.w	#(gsstruct-M68K_RAM),a0	;game structs (games stored for playoffs and box scores)
	adda.w	d3,a0
	clr.w	d3
	btst	#0,$E(a0)		;gsftf, gsflags(a0): teams are flipped
	beq.w	.nf
	eori.w	#2,d3			;gspobwins-gspotwins
.nf	move.w	(HmGoals).w,d1
	sub.w	(AwGoals).w,d1
	bpl.w	.ns1
	eori.w	#2,d3			;gspobwins-gspotwins
.ns1	cmpi.w	#3,4(a0,d3.w)		;gspotwins(a0,d3)
	bne.w	.t3

.sc	move.l	#8,d0			;stanley cup assignment
	moveq	#$B,d2			;all 12 players lose joystick control
.t0	bclr	#pfjoycon,pflags(a3)		;pfjoycon, pflags(a3)
	adda.w	#SCstruct,a3			;SCstruct
	dbf	d2,.t0
	movea.w	#(SortCords-M68K_RAM),a3
.t3	moveq	#5,d2			;winning team's skaters celebrate
	move.w	(HmGoals).w,d1
	sub.w	(AwGoals).w,d1
	beq.w	.eop			;tied
	bpl.w	.t2			;home team leads
	adda.w	#6*SCstruct,a3		;6*SCstruct: away team leads
.t2	tst.w	position(a3)			;position
	ble.w	.n2			;skip the goalie
	jsr	(assinsert).l		;first skater gets d0, the rest get score
	move.l	#7,d0			;score assignment
.n2	adda.w	#SCstruct,a3			;SCstruct
	dbf	d2,.t2
.eog	jsr	(ClearPenaltyBuffer).l	;end of game
	addi.w	#$3E8,(crowdlevel).w	;1000
	bset	#0,(gmode).w		;gmclock: stop clock
	bset	#6,(gmode).w		;set at end of game
	jsr	(ClearPenalties).l
	move.w	#4,d0			;PenEOG
	jmp	AddPenalty2

.eop	cmpi.w	#3,(gsp).w		;end of OT?
	bne.w	.eop_ex
	tst.w	(OptPlayMode).w
	beq.s	.eog			;gsp 3 with OptPlayMode 0 ends the game
.eop_ex	move.w	#2,d0			;PenEOP
	jmp	AddPenalty2

demoread	;monitor joystick if in demo mode (called every game loop)
	tst.w	(cont1team).w
	bne.w	rtss8			;not demo
	tst.w	(cont2team).w
	bne.w	rtss8			;not demo
	jsr	(ReadJoy1).l
	btst	#7,d1			;sbut
	bne.w	startpause1		;start on pad 1 pauses
	bsr.w	EndDemoOnPress
	jsr	(ReadJoy2).l
	btst	#7,d1
	bne.w	startpause2
	tst.w	(FourWayPlay).w		;pads 3 and 4 on the 4 way play adapter
	beq.w	EndDemoOnPress
	jsr	(ReadJoy3).l
	btst	#7,d1
	bne.w	startpause3
	bsr.w	EndDemoOnPress
	jsr	(ReadJoy4).l
	btst	#7,d1
	bne.w	startpause4
	;falls into EndDemoOnPress with pad 4 in d1

EndDemoOnPress	;Any button on the pad just read (d1) ends the demo
	tst.w	d1
	beq.w	rtss8			;nothing pressed
	jmp	ExitToOpening		;exit demo

startpause1	;pause initiated by cont 1
	clr.w	(pausepad).w		;pausing pad number (0 = pad 1 or 2)
	bclr	#1,(sflags).w		;sfpj
	bra.w	startpause
startpause2	;pause initiated by cont 2
	clr.w	(pausepad).w
	bset	#1,(sflags).w		;sfpj
startpause	;set sfpz: pause at the end of this frame
	bset	#0,(sflags).w		;sfpz
	rts

startpause3	;pause initiated by cont 3 (4 way play). Also from doinput
	move.w	#3,(pausepad).w
	bclr	#1,(sflags).w		;sfpj
	bra.s	startpause
startpause4	;pause initiated by cont 4 (4 way play). Also from doinput
	move.w	#4,(pausepad).w
	bset	#1,(sflags).w		;sfpj
	bra.s	startpause

Pausemode	;Game is in pause mode now
	jsr	(forceblack).l		;fade screen to black
	move.w	d0,-(sp)
	move.w	(vcount).w,d0
.vb	cmp.w	(vcount).w,d0		;Wait for the next vblank
	beq.s	.vb
	move.w	(sp)+,d0
	jsr	(p_turnoff).l		;shut off sound
	move.w	(sflags).w,-(sp)
	bsr.w	seta2			;a2 = team of pausing controller
	movea.l	#PauseText,a0		;menu item list
	lea	SetupPauseScreen(pc),a1	;screen draw routine
	btst	#0,(gmode2).w
	beq.w	.chk2
	movea.l	#PauseMenuItems,a0		;third item list
	bra.w	.0
.chk2	btst	#2,tmflags(a2)		;tmflags
	beq.w	.0
	movea.l	#PauseText2,a0		;alternate item list
.0	bsr.w	InitMenuState
.1	bsr.w	vcountwait
	bsr.w	getpzjoy
	jsr	(showclock).l
	jsr	(ProcessInputWithRepeat).l
	bsr.w	HandleMenuInput
	bne.s	.1			;eq = leave pause

	;restore graphics and return from pause mode
	jsr	(forceblack).l
	move.w	(sp)+,(sflags).w
	btst	#7,(sflags).w		;sfhor
	beq.w	.clr
	jsr	(ReloadRefHorTiles).l
	jsr	(SetHor).l
	bra.w	.hor
.clr	jsr	(ClrHor).l
.hor	movea.l	#VDP_DATA,a0
	move.w	#VDPR_WINX,Vctrl-Vdata(a0)
	move.w	#VDPR_WINY,Vctrl-Vdata(a0)
	bset	#dfclock,(disflags).w		;dfclock: clock needs update
	bclr	#sfpz,(sflags).w		;sfpz
	jsr	(printscores1).l
	jsr	(setvideo).l
	move.w	#$18,(palcount).w
.wait	tst.w	(palcount).w
	bpl.s	.wait
	move.w	(vcount).w,(oldvcount).w
	rts

SetupPauseScreen	;Draw routine for the pause menu.
	;also called
	movea.l	#VDP_DATA,a0
	move.w	#VDPR_WINX,Vctrl-Vdata(a0)		;playfield 3 width
	move.w	#VDPR_WINY+$1C,Vctrl-Vdata(a0)		;playfield 3 height
	jsr	(SetHor).l
	jsr	(setvideo).l
	jsr	(KillCrowd).l
	jsr	(printsmallz).l		;erase playfield 3
	String	CC_SetMap,3,CC_SetX,0,CC_SetY,0
	moveq	#$20,d0			;32
	moveq	#$1C,d1			;28
	move.w	#$7FF,d2
	jmp	eraser

seta2	;Set a2 to the team struct of the pause joystick
	;also called from HandleMenuInput
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#sfpj,(sflags).w		;sfpj
	beq.w	.seta20
	cmpi.w	#1,(cont2team).w
	bra.w	.seta21
.seta20	cmpi.w	#1,(cont1team).w
.seta21	beq.w	.x
	adda.w	#tmsize,a2		;tmsize
.x	rts
