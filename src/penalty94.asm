;	Penalty logic. This file calls penalties and the other stoppages of play, awards penalty
;	shots on breakaways, sends players to the penalty box, runs power plays, shows the referee's
;	messages and switches the rink between its horizontal and vertical views.

AddPenalty	;add penalty d0 (Penaltylist offset) for player a3. Ignored while the clock is stopped, when penalties are off, for a player with
	;pflags2 bit 2 set, or offsides when offsides are off. Falls into AddPenalty2
	btst	#gmclock,(gmode).w	;gmclock
	bne.w	rtss2
	cmp.w	#$C,d0	;icing (92 used 8)
	beq.w	AddPenalty2
	tst.w	(OptPen).w
	beq.w	rtss2	;penalties off
	btst	#2,pflags2(a3)	;pflags2 bit 2, which releasepl sets
	bne.w	rtss2
	btst	#gmoffs,(gmode).w	;gmoffs: offsides on
	bne.w	AddPenalty2
	cmp.w	#$10,d0	;offsides (92 used $A)
	beq.w	rtss2
AddPenalty2	;forced penalties like face off and game over. d0 = penalty number, a3 = player or player on penalized team. From $E (goal) up: crowd
	;and song. A penalty with minutes sets DelayedPen bit 1 (home) or bit 2 (away)
	btst	#sfhor,(sflags).w	;sfhor: nothing in horizontal mode
	bne.w	rtss2
	movem.l	d1/a0-a1,-(sp)
	cmp.w	#$E,d0	;goal (92 used 6) and up
	blt.w	.nonoise
	addi.w	#$C8,(crowdlevel).w	;200
	move.w	#$C,-(sp)	;song $C for the home team
	btst	#pfteam,pflags(a3)	;pfteam
	beq.w	.song
	addi.w	#$14,(CwdExciteLvl).w	;visitors: +20 excitement
	move.w	#$B,(sp)	;song $B
.song
	bsr.w	song
.nonoise
	movea.w	#(PenBuf-M68K_RAM),a1
	moveq	#$1F,d1	;MaxPen-1
.0
	tst.w	(a1)+
	dbeq	d1,.0	;find a free slot
	bne.w	.noplayer	;buffer full
	move.b	SCnum+1(a3),-(a1)	;SCnum+1
	move.b	d0,-(a1)
	movea.l	#Penaltylist,a0
	adda.w	0(a0,d0.w),a0
	tst.b	1(a0)	;penalty minutes
	beq.w	.noplayer
	bmi.w	.noplayer	;negative minutes too
	btst	#6,pflags(a3)	;pfteam. DelayedPen bit 1 home, bit 2 away
	bne.w	.away
	bset	#1,(DelayedPen).w
	bra.w	.setpenflag
.away
	bset	#2,(DelayedPen).w
.setpenflag
	bset	#4,pflags2(a3)	;pflags2 bit 4
	beq.w	.noplayer
	clr.w	(a1)	;player already has a penalty, drop this one
.noplayer
	movem.l	(sp)+,d1/a0-a1
	rts
PenaltyManager	;called periodically. d7 = elapsed time since last call
	bsr.w	updatepentime
	bsr.w	checkfornewpen
	bsr.w	chkprogress
	bra.w	UpdatePA
chkprogress	;control progress of ref and game control thru penalty events. While BA_PS_flags bit 2 is set (penalty shot), bit 7 calls
	;PenaltyShotBox and msgtimer counts down; when it runs out the message area is erased. Then, when the stop delay runs out and a penalty
	;with minutes is in PenBuf, switch to the horizontal rink for the player to enter the penalty box
	btst	#2,(BA_PS_flags).w	;to.cont
	beq.w	.cont
	btst	#7,(BA_PS_flags).w
	bne.w	.sops
	tst.w	(msgtimer).w
	bmi.w	.cont
	subq.w	#1,(msgtimer).w
	bpl.w	.ex
	movem.l	d0-d7/a0-a6,-(sp)
	bclr	#2,(sflags2).w	;sf2drec
	bclr	#7,(gmode2).w
	bsr.w	printz
	String	-TXMAP1,3,2
	moveq	#$1B,d0
	moveq	#8,d1
	btst	#0,(gmode2).w
	beq.w	.0
	move.w	#$C,d1	;12 rows when gmode2 bit 0 is set
.0
	move.l	#$7FF,d2	;blank tile
	jsr	(eraser).l
	movem.l	(sp)+,d0-d7/a0-a6
	bra.w	.ex
.sops
	jsr	(PenaltyShotBox).l
	bclr	#7,(BA_PS_flags).w
.ex
	rts
.cont
	btst	#2,(gmode).w	;gmpen: penalty called
	beq.w	rtss2	;exit if not
	tst.w	(Pencntdwn).w
	bmi.w	InProgress
	sub.w	d7,(Pencntdwn).w
	bpl.w	rtss2
	bclr	#gmpendel,(gmode).w	;gmpendel
	movea.w	#(PenBuf-M68K_RAM),a0
.find
	tst.w	(a0)+	;any penalty with minutes
	beq.w	rtss2
	clr.w	d0
	move.b	-2(a0),d0
	movea.l	#Penaltylist,a1
	adda.w	0(a1,d0.w),a1
	tst.b	1(a1)	;penalty minutes
	beq.s	.find
	bmi.s	.find	;negative minutes too
	bset	#sf2drec,(sflags2).w	;sf2drec: switch to horizontal mode for player to enter penalty box
	move.w	(vcount).w,-(sp)
	bsr.w	forceblack
	move.w	(sp)+,(vcount).w
	bsr.w	SetHor
	move.w	(ExtraChars).w,d4	;load horizontal ref tiles
	movea.l	#RefMap2+8,a2	;+8
	bsr.w	DecompressGraphicsPlain
	bsr.w	NewTicker
	bsr.w	NewTicker3
	st	(puckc).w
	movea.w	#(puckx-M68K_RAM),a3
	move.l	#$1A,d0	;puckunflip
	bsr.w	assinsert
	move.w	#$1C20,temp1(a3)	;temp1 = 120*60
	st	(RefStep).w
	clr.w	(RefCnt).w
	bsr.w	UpdatePA
	move.w	#$32,(RefCnt).w	;50
	clr.w	d0
	bsr.w	PushRef	;ref frame 0
	move.w	#$18,(palcount).w	;24
	rts
PenShotChk	;a3 = checker, a2 = player hit, d0 = penalty. If a2 is on a breakaway ($64 bit 1), no penalty shot is pending (BA_PS_flags
	;bit 3) and PenShotPenalties has an entry for d0, getBAplayerInfo sets one up and d0 = that penalty (also pspenalty). Called from CCStart before
	;AddPenalty
	movem.l	d1-d3/a0,-(sp)
	btst	#pf3break,pflags3(a2)	;breakaway
	beq.w	.loop
	btst	#3,(BA_PS_flags).w	;penalty shot pending
	beq.w	.0
.loop
	move.w	#$FFFF,d1
	bra.w	.end
.0
	movea.l	#PenShotPenalties,a0
	move.w	0(a0,d0.w),d1	;penalty shot penalty for d0, -1 = none
	bmi.w	.end
	move.w	SCnum(a2),d2	;SCnum
	movem.w	d0-d1,-(sp)
	move.w	d2,d0
	jsr	(getBAplayerInfo).l
	movem.w	(sp)+,d0-d1
	bpl.w	.found	;N clear: penalty shot set up
	bclr	#3,(BA_PS_flags).w
	bra.s	.loop
.found
	move.w	d1,(pspenalty).w
	move.w	d1,d0	;return the penalty shot penalty
.end
	movem.l	(sp)+,d1-d3/a0
	rts
getBAplayerInfo	;d0 = SCnum (0-5 home team, 6-11 away team) of the player on the breakaway, a3 = checker. If penalties are on and the other
	;team has a goalie in, set BA_PS_flags bit 3 and save BA_Sktr_SCnum, BA_Team, BA_Goalie_SCnum and the skater, goalie and checker team position
	;offsets ($66). Returns N clear when the penalty shot is set up
	movem.l	d1-d3/a1,-(sp)
	tst.w	(OptPen).w
	beq.w	.noPen
	bset	#3,(BA_PS_flags).w
	movem.w	d0,-(sp)
	move.w	#5,d1
	move.w	#0,d2
	cmp.w	#5,d0
	bgt.w	.findgoalie	;away player: search the home team for its goalie (d1 = 5), else the visitors (d1 = $B)
	move.w	#$B,d1
	move.w	#1,d2
.findgoalie
	move.w	d1,d0
	jsr	(getGoalieSCnum).l
	tst.w	d0
	bpl.w	.goaliein	;branch if there's a goalie
	movem.w	(sp)+,d0	;no goalie
	bclr	#3,(BA_PS_flags).w
	bra.w	.end
.goaliein
	move.w	d0,d1	;d1 = goalie's SCnum
	move.w	(sp)+,d0	;d0 now back to player checked on breakaway SCnum
	move.w	d0,(BA_Sktr_SCnum).w
	movea.l	#SortCords,a1
	move.w	d0,d3
	asl.w	#7,d3	;scsize
	move.w	#0,(BA_Team).w
	btst	#6,$62(a1,d3.w)	;pfteam
	beq.w	.0	;branch if home
	move.w	#1,(BA_Team).w
.0
	move.w	#0,(BA_Skater_Offset).w
	move.b	$66(a1,d3.w),(BA_Skater_Offset+1).w	;store BA player's team position offset
	move.w	d1,(BA_Goalie_SCnum).w
	asl.w	#7,d1	;scsize
	move.w	#0,(BA_Goalie_Offset).w
	move.b	$66(a1,d1.w),(BA_Goalie_Offset+1).w	;store goalie's team position offset
	move.w	#0,(BA_Checker_Offset).w
	move.b	pnum(a3),(BA_Checker_Offset+1).w	;store checker's team position offset
.end
	movem.l	(sp)+,d1-d3/a1
	rts
.noPen
	move.w	#$FFFF,d1	;N set: no penalty shot
	bra.s	.end
InProgress	;ref in progress-- update graphics and stats and penalty information. Takes the last PenBuf entry; the first pass logs a penalty
	;with minutes and sends the player to the box, later passes wait until he is off the ice and drop the entry. When PenBuf is empty, recount
	;players and go to the face off, or the penalty shot. Only a 5 minute penalty is matched as coincidental. Entered from chkprogress
	tst.w	(RefCnt).w
	bpl.w	rtss2	;animation in progress
	tst.w	(RefStep).w
	bpl.w	rtss2
	movem.l	d0/a0-a3,-(sp)
.top
	movea.w	#(PenBuf-M68K_RAM),a0	;penalty buffer
	tst.w	(a0)+
	beq.w	.4
.0
	tst.w	(a0)+
	bne.s	.0	;find end of list
	subq.w	#4,a0
	bclr	#7,1(a0)	;player who is guilty
	bne.w	.Sa
	move.l	a3,-(sp)
	clr.w	d1
	move.b	1(a0),d1
	asl.w	#7,d1	;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3
	tst.w	position(a3)	;position
	movea.l	(sp)+,a3
	bpl.w	.ex	;still on the ice
	clr.w	(a0)
	bra.w	.ex
.Sa
	clr.w	d0
	move.b	(a0),d0
	movea.l	#Penaltylist,a1
	adda.w	0(a1,d0.w),a1
	bclr	#5,(sflags5).w	;bit 5 = this penalty is 5 minutes
	clr.w	d2
	move.b	1(a1),d2	;penalty minutes
	beq.w	.sa2	;no player involved
	bmi.w	.sa2	;negative minutes too
	cmp.b	#5,d2
	bne.w	.1
	bset	#5,(sflags5).w
.1
	movem.l	d0-d1/a1-a4,-(sp)
	bsr.w	GetPeriodTimeRemaining	;log time, penalty and player
	movea.w	#(PenSum-M68K_RAM),a4
	adda.w	(PenSumLength).w,a4
	cmpi.w	#$EC,(PenSumLength).w	;log full: keep overwriting the last entry
	beq.w	.full
	addq.w	#4,(PenSumLength).w
.full
	move.w	d0,(a4)+	;time
	move.b	(a0),(a4)+	;penalty
	clr.w	d1
	move.b	1(a0),d1
	asl.w	#7,d1	;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d1,a3
	clr.w	d0
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1	;tmsize: visitors
	btst	#pfteam,pflags(a3)	;pfteam
	beq.w	.2
	bset	#7,-1(a4)	;log: visitors
	move.w	#$8000,d0
	exg	a1,a2
.2
	addq.w	#1,tmPenalties(a2)	;tmPenalties
	add.w	d2,tmPenmin(a2)	;tmPenmin
	move.b	pnum(a3),d0	;pnum
	move.b	d0,(a4)	;log: player
	move.w	d0,(TempPlOffset).w
	ext.w	d0
	addi.w	#$102,d0	;per-player penalty minutes byte at $102+pnum
	add.b	d2,0(a2,d0.w)
	subi.w	#$102,d0
	asl.w	#1,d0
	ext.w	d2
	mulu.w	#$3C,d2	;60
	bset	#$D,d2	;tmpdst bit 13
	tst.w	tmpdst(a2,d0.w)	;tmpdst
	bmi.w	.3
	btst	#4,tmpdst(a2,d0.w)
	beq.w	.3
	bset	#$C,d2	;keep byte bit 4 (word bit 12) of an old penalty time
.3
	move.w	d2,tmpdst(a2,d0.w)
	andi.w	#$EFFF,d2
	moveq	#$34,d1	;(MaxRos-1)*2+2
.ctop
	subq.w	#2,d1	;same time on the other team
	bmi.w	.nocoin
	move.w	tmpdst(a1,d1.w),d3
	andi.w	#$EFFF,d3
	cmp.w	d3,d2
	bne.s	.ctop
	btst	#5,(sflags5).w	;coincidental for a 5 minute penalty only
	beq.s	.ctop
	bset	#6,tmpdst(a1,d1.w)	;coincidental (byte bit 6, word bit 14)
	bset	#6,tmpdst(a2,d0.w)
.nocoin
	movem.l	a0,-(sp)
	lea	$9A(a2),a0	;add player to penalty box list
	moveq	#$18,d1
.pl
	tst.b	(a0)+
	dbmi	d1,.pl	;find end of list
	move.b	d0,-1(a0)
	st	(a0)
	movem.l	(sp)+,a0
	move.w	#$C,d0	;asspenalty
	bsr.w	assreplace
	movem.l	(sp)+,d0-d1/a1-a4
	bsr.w	SetPA
	bsr.w	USBoard
	bra.w	.ex
.sa2
	clr.w	(a0)	;clear the entry
	btst	#sfhor,(sflags).w	;sfhor
	bne.w	.top
	bsr.w	SetPA
	bra.w	.ex
.4
	movea.w	#(tmstruct-M68K_RAM),a2	;home team struct
	bsr.w	coinsearch
	adda.w	#tmsize,a2	;tmsize
	bsr.w	coinsearch
	bclr	#gmpen,(gmode).w	;gmpen
	movea.w	#(puckx-M68K_RAM),a3
	bclr	#6,(BA_PS_flags).w
	move.w	#$1B,d0	;puckfaceoff
	btst	#3,(BA_PS_flags).w
	beq.w	.5
	move.w	#$1E,d0	;puckshootout: penalty shot
.5
	bsr.w	assreplace
.ex
	movem.l	(sp)+,d0/a0-a3
	rts
coinsearch	;a2 = team. Clears tmpdst bit 5, counts players kept off the ice by penalties (coincidental and bit 4
	;times do not count, at most 2) and sets tmap. Called twice from InProgress
	moveq	#6,d1
	moveq	#$32,d0	;(MaxRos-1)*2
.loop
	tst.w	tmpdst(a2,d0.w)
	ble.w	.nap
	bclr	#5,tmpdst(a2,d0.w)
	btst	#6,tmpdst(a2,d0.w)	;coincidental
	bne.w	.nap
	btst	#4,tmpdst(a2,d0.w)
	bne.w	.nap
	cmp.w	#4,d1	;never below 4 players
	beq.w	.nap
	subq.w	#1,d1
.nap
	subq.w	#2,d0
	bpl.s	.loop
	move.w	d1,tmap(a2)	;tmap
	rts
checkfornewpen	;look for new penalty (entered thru addpenalty(2)). Stops play at once for penalties without minutes or when the guilty team does not
	;have the puck, otherwise starts a delayed penalty call
	btst	#sfhor,(sflags).w	;sfhor
	bne.w	rtss2
.0	;unreferenced entry
	movea.w	#(PenBuf-M68K_RAM),a0
.next
	tst.w	(a0)+
	beq.w	rtss2
	btst	#gmpen,(gmode).w	;gmpen
	bne.w	.iscalled
	clr.w	d0
	move.b	-2(a0),d0
	movea.l	#Penaltylist,a1
	adda.w	0(a1,d0.w),a1
	tst.b	1(a1)	;time for penalty
	beq.w	.callit
	move.w	(puckc).w,d0
	bmi.w	.dc
	subq.w	#6,d0
	move.b	-1(a0),d1	;player penalized
	ext.w	d1
	subq.w	#6,d1
	eor.w	d1,d0
	bmi.w	.dc	;delayed penalty call
.callit
	bsr.w	Stop4Pen
.iscalled
	bset	#7,-1(a0)
	bne.s	.next
	clr.w	d0
	move.b	-2(a0),d0	;penalty called
	movea.l	#Penaltylist,a1
	adda.w	0(a1,d0.w),a1
	clr.w	d1
	move.b	(a1),d1	;delay for stopping action
	asl.w	#5,d1
	cmp.w	(Pencntdwn).w,d1
	ble.s	.next
	move.w	d1,(Pencntdwn).w
	bra.s	.next
.dc
	bset	#gmpendel,(gmode).w	;gmpendel
	bne.s	.next
	move.w	#$2C,d0	;delayed penalty (92 used $24)
	bsr.w	SetPA
	bra.s	.next
Stop4Pen	;a0 = penaltylist penalty +2. Stop the clock, set the face off spot from the penalty type, blow the whistle, with stop_current_song before the whistle. Also entered from puckfaceoff
	bset	#gmclock,(gmode).w	;gmclock
	bne.w	.skipfo
	clr.w	d0
	clr.w	d1
	cmpi.b	#$E,-2(a0)	;goal (92 used 6): center ice
	beq.w	.noticing
	move.w	(ltx).w,d0
	move.w	(lty).w,d1
	cmpi.b	#6,-2(a0)	;OOP (92 used $C)
	beq.w	.noticing
	move.w	(puckx).w,d0
	move.w	(pucky).w,d1
	cmpi.b	#$C,-2(a0)	;icing (92 used 8)
	bne.w	.noticing
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	move.b	-1(a0),d1
	ext.w	d1
	asl.w	#7,d1	;scsize
	adda.w	d1,a3
	move.w	#$258,d1	;600
	btst	#pfgoal,pflags(a3)	;pfgoal
	movea.l	(sp)+,a3
	beq.w	.noticing
	neg.w	d1
.noticing
	movem.w	d0-d1,-(sp)
	cmp.w	#$46,d0	;.xspot = 70
	blt.w	.0
	move.w	#$46,d0
.0
	cmp.w	#$FFBA,d0	;-.xspot
	bgt.w	.1
	move.w	#$FFBA,d0
.1
	cmp.w	#$A6,d1	;.yspot-.ygive = 206-40
	blt.w	.2
	move.w	#$CE,d1	;.yspot = 206
	move.w	#$46,d0
	tst.w	(sp)
	bpl.w	.2
	neg.w	d0
.2
	cmp.w	#$FF5A,d1	;-.yspot+.ygive
	bgt.w	.3
	move.w	#$FF32,d1	;-.yspot
	move.w	#$46,d0
	tst.w	(sp)
	bpl.w	.3
	neg.w	d0
.3
	move.w	d0,(fox).w
	move.w	d1,(foy).w
	addq.w	#4,sp
	bsr.w	limitfo
.skipfo
	clr.w	(Pencntdwn).w
	bset	#gmpen,(gmode).w	;gmpen
	jsr	(stop_current_song).l
	move.w	#SFXwhistle,-(sp)	;whistle (92 used 10)
	bsr.w	sfx
	move.w	#$A,d0	;whistle (92 used $26)
	bra.w	SetPA
limitfo	;limit face off to 5-20 feet from walls of rink. Checks every player in PenBuf
	movem.l	d0-d1/a0-a1,-(sp)
	movea.w	#(PenBuf-M68K_RAM),a0
.loop
	bsr.w	.lf
	addq.w	#2,a0
	tst.w	(a0)
	bne.s	.loop
	movem.l	(sp)+,d0-d1/a0-a1
	rts
.lf
	move.b	1(a0),d0
	andi.w	#$7F,d0
	asl.w	#7,d0	;scsize
	movea.w	#(SortCords-M68K_RAM),a1
	move.w	#$58,d1
	btst	#pfgoal,pflags(a1,d0.w)	;pfgoal
	bne.w	.0
	neg.w	d1
	cmp.w	(foy).w,d1
	blt.w	rtss2
	move.w	#$FFBF,(foy).w	;-.nuy = -65
	bra.w	.sx
.0
	cmp.w	(foy).w,d1
	bgt.w	rtss2
	move.w	#$41,(foy).w	;.nuy = 65
.sx
	move.w	#$46,d0	;.nux = 70
	tst.w	(fox).w
	bpl.w	.1
	neg.w	d0
.1
	move.w	d0,(fox).w
	rts
UpdatePA	;animate ref in ref window. Runs ShowThreeStars for game over, and the horizontal penalty message line is reprinted when penmsgtimer runs out
	tst.w	(RefCnt).w
	bmi.w	rtss2
	sub.w	d7,(RefCnt).w
	bpl.w	.0
	bsr.w	SetPA2
.0
	cmpi.w	#4,(RefPen).l	;game over (92 used 4)
	bne.w	.1
	bsr.w	ShowThreeStars
.1
	sub.w	d7,(penmsgtimer).w
	bpl.w	rtss2
	move.w	#$7FFF,(penmsgtimer).w
	bsr.w	ClearPenaltyMessage
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$11,$B
	bsr.w	GetPlayerName
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w	;center it
	bra.w	print
SetPA	;start ref animation. d0 = animation (penalty number). Animations from $2E up are ignored, and ShootoutWonBy is called when gmode2 bits 0
	;and 3 are set. Goal calls ShowGoalBox. Falls into SetPA2
	move.w	d0,(RefPen).w
	cmp.w	#$2E,d0	;not on the penalty list
	blt.w	.1
	rts
.1
	clr.w	(RefStep).w
	bsr.w	prefmes
	cmp.w	#$E,d0	;goal (92 used 6)
	bne.w	.2
	bsr.w	ShowGoalBox
.2
	btst	#0,(gmode2).w
	beq.w	.0
	btst	#3,(gmode2).w
	beq.w	.0
	jsr	(ShootoutWonBy).l
.0
	move.w	#$7FFF,(penmsgtimer).w
	btst	#sfhor,(sflags).w	;sfhor
	beq.w	SetPA2
	move.w	#$3C,(penmsgtimer).w	;60
SetPA2	;update animation for ref. Next frame/delay pair from the Penaltylist animation of RefPen. The delay is doubled
	;when gmode2 bits 0 and 3 are set. Also called from UpdatePA
	movem.l	d0-d2/a0-a1,-(sp)
	moveq	#$40,d0	;clear ref window
	tst.w	(RefStep).w
	bmi.w	.pr
	move.w	(RefStep).w,d0
	addq.w	#2,(RefStep).w
	move.w	(RefPen).w,d1
	movea.l	#Penaltylist,a0
	adda.w	0(a0,d1.w),a0
	addq.w	#2,a0
	adda.w	(a0),a0
	move.w	0(a0,d0.w),d0
	bpl.w	.0
	neg.w	d0	;negative = last frame
	st	(RefStep).w
.0
	clr.w	d1
	move.b	d0,d1
	asl.w	#3,d1
	move.w	d1,(RefCnt).w
	btst	#0,(gmode2).w
	beq.w	.1
	btst	#3,(gmode2).w
	beq.w	.1
	move.w	d0,-(sp)
	move.w	(RefCnt).w,d0
	add.w	d0,d0
	move.w	d0,(RefCnt).w
	move.w	(sp)+,d0
.1
	lsr.w	#8,d0
.pr
	bsr.w	PushRef
	movem.l	(sp)+,d0-d2/a0-a1
	rts
PushRef	;tell vblank what to display. d0 = ref frame, $40 clears the window. The horizontal ref uses RefMap2
	movem.l	d0-d2/a0-a1,-(sp)
	cmp.w	#$40,d0
	beq.w	.clearit
	mulu.w	#$70,d0	;refwidth*refheight*2
	movea.l	#RefsMap,a0
	btst	#sfhor,(sflags).w	;sfhor
	beq.w	.m1
	movea.l	#RefMap2,a0
.m1
	adda.l	4(a0),a0
	addq.w	#4,a0
	adda.w	d0,a0
	movea.w	#(RefRamMap-M68K_RAM),a1
	move.w	(ExtraChars).w,d2
	btst	#sfhor,(sflags).w
	bne.w	.4
	ori.w	#$8000,d2	;priority
.4
	moveq	#$37,d0	;(refheight*refwidth)-1
.1
	move.w	(a0)+,(a1)
	add.w	d2,(a1)+
	dbf	d0,.1
	bset	#sf2refref,(sflags2).w	;sf2refref
	bra.w	.ex
.clearit
	btst	#7,(sflags).w	;sfhor: horizontal mode only clears the line
	bne.w	.cl
	movea.w	#(RefRamMap-M68K_RAM),a1
	moveq	#$37,d0	;(refheight*refwidth)-1
.2
	move.w	#$7FF,(a1)+	;blank tile
	dbf	d0,.2
	bset	#sf2refref,(sflags2).w	;sf2refref
.cl
	moveq	#-1,d0	;clear line
	bsr.w	prefmes
.ex
	movem.l	(sp)+,d0-d2/a0-a1
	rts
prefmes	;print message for penalty d0 (negative clears it). Vertical mode: framed under the ref. Horizontal mode: one centered line on row $B
	movem.l	d0-d2/a1,-(sp)
	btst	#sfhor,(sflags).w	;sfhor
	bne.w	.hor
	tst.w	d0
	bpl.w	.noblank
	bsr.w	printz
	String	-(TXPRI+TXMAP1),0,$A
	moveq	#$D,d0
	moveq	#3,d1
	move.w	#$7FF,d2	;blank tile
	bsr.w	eraser
	bra.w	.ex
.noblank
	bsr.w	printz
	String	-(TXPRI+TXMAP1),5,$A
	movea.l	#Penaltylist,a1
	adda.w	0(a1,d0.w),a1
	addq.w	#2,a1
	move.w	(a1),d0
	subq.w	#2,d0	;empty string
	beq.w	.ex
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bpl.w	.nb0
	clr.w	(printx).w
.nb0
	move.w	(a1),d0
	tst.b	-1(a1,d0.w)
	bne.w	.nb1
	subq.w	#1,d0
.nb1
	moveq	#3,d1
	bsr.w	Framer
	subq.w	#2,(printy).w
	addq.w	#1,(printx).w
	bsr.w	print
	bra.w	.ex
.hor
	bsr.w	ClearPenaltyMessage	;clear the line first
	tst.w	d0
	bmi.w	.ex
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$11,$B
	movea.l	#Penaltylist,a1
	adda.w	0(a1,d0.w),a1
	addq.w	#2,a1
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	print
.ex
	movem.l	(sp)+,d0-d2/a1
	rts
ClearPenaltyMessage	;Blank the horizontal mode penalty message line (22 spaces at x 5, y $B). Called from UpdatePA and prefmes
	bsr.w	printz
	String	-(TXPRI+TXMAP1),5,$B,'                      ',0	;22 spaces
	rts
PenGoalStuff	;do this stuff after a goal. a1 = scored on team, a2 = scoring team. Clears PenBuf only when the scored
	;on team has 6 on the ice. If the scoring team had more players on ice, the first scored on player in the box without a coincidental penalty
	;is released (also sets DelayedPen bit 0)
	movem.l	d0-d2/a0,-(sp)
	cmpi.w	#6,$24(a1)	;tmap
	bne.w	.1
	bsr.w	ClearPenaltyBuffer
.1
	move.w	tmap(a2),d2	;end p.killing by scored on team
	cmp.w	tmap(a1),d2
	ble.w	.ex
	lea	$9A(a1),a0
.0
	clr.w	d2
	move.b	(a0)+,d2
	bmi.w	.ex
	btst	#6,tmpdst(a1,d2.w)	;coincidental
	bne.s	.0
	clr.w	tmpdst(a1,d2.w)
	bsr.w	RemovePlayerFromList
	bset	#0,(DelayedPen).w
	addq.w	#1,tmap(a1)	;tmap
	addq.w	#1,tmPwrGoals(a2)	;tmPwrGoals
	bset	#0,(tmstruct+tmflags).w	;home tmflags: tmflcc
	bset	#0,(AwShots+tmflags).w	;visitors tmflags: tmflcc
.ex
	movem.l	(sp)+,d0-d2/a0
	rts
ClearPenaltyBuffer	;Clear PenBuf. Called from clockcont and PenGoalStuff
	moveq	#$1F,d0	;MaxPen-1
	movea.w	#(PenBuf-M68K_RAM),a0
.loop
	clr.w	(a0)+
	dbf	d0,.loop
	rts
updatepentime	;update the time remaining on all penalized players, once a second. Sets sflags3 bit 6 on that tick, then updatePPTeamTime. Falls into ProcessPenaltyList for team 2
	bclr	#6,(sflags3).w
	btst	#gmclock,(gmode).w	;gmclock
	bne.w	rtss2
	sub.w	d7,(Penaltytimer).w
	bpl.w	rtss2
	addi.w	#$18,(Penaltytimer).w	;jps
	bset	#6,(sflags3).w	;one second tick
	bsr.w	chkatop
	jsr	(updatePPTeamTime).l
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	ProcessPenaltyList
	adda.w	#tmsize,a2	;tmsize
ProcessPenaltyList	;a2 = team. Walks the penalty box list ($9A): the first two players without a coincidental penalty
	;count down one second and the rest wait. Beeps when the first served time gets to 5 or less and releases the player at 0. Coincidental
	;penalties count down on their own
	lea	$9A(a2),a0	;penalty box list
	movea.w	#(mesarea-M68K_RAM),a1	;serving players
	moveq	#2,d1	;two can serve at once
	moveq	#2,d3
.next
	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	.done
	btst	#6,tmpdst(a2,d0.w)	;coincidental
	bne.w	.1
	subq.w	#1,d1
	bmi.s	.next	;third or later player waits
	move.w	d0,(a1)+
	subq.w	#1,tmpdst(a2,d0.w)
	bne.w	.cont
	bsr.w	RemovePlayerFromList	;time is up
.cont
	bra.s	.next
.done
	move.w	(mesarea).w,d0	;first serving player
	cmp.w	#1,d1	;one serving
	beq.w	.0
	tst.w	d1
	bne.w	.n1
	bsr.w	.0	;two serving: check the first, then the second
	bra.w	.two
.n1
	cmp.w	#$FFFF,d1	;exactly three in the list: check the second only
	bne.w	rtss2
.two
	move.w	(TextBuffer).w,d0	;second serving player (mesarea+2)
.0
	cmpi.w	#5,tmpdst(a2,d0.w)
	bgt.w	rtss2
	move.w	#1,-(sp)	;SFXbeep1
	tst.w	tmpdst(a2,d0.w)
	bne.w	.snd
	bsr.w	releasepl
	move.w	#2,(sp)	;SFXbeep2
.snd
	bsr.w	sfx
	rts
.1
	subq.w	#1,tmpdst(a2,d0.w)	;coincidental penalty
	btst	#3,tmpdst(a2,d0.w)
	beq.s	.next
	btst	#4,tmpdst(a2,d0.w)
	bne.w	.2
	move.w	#$1000,tmpdst(a2,d0.w)
	bra.w	RemovePlayerFromList
.2
	clr.w	tmpdst(a2,d0.w)	;falls into RemovePlayerFromList
RemovePlayerFromList	;Remove the entry before a0 from a penalty box list by shifting the rest down (list ends with a
	;negative byte). Return a0 = removed slot. Called from PenGoalStuff, ProcessPenaltyList
	moveq	#-1,d2
.shift
	addq.w	#1,d2
	move.b	0(a0,d2.w),-1(a0,d2.w)
	bpl.s	.shift
	subq.w	#1,a0
	rts
chkatop	;attack time of possession stat update. Called once a second from updatepentime
	moveq	#0,d1
	move.w	(pucky).w,d0
	cmp.w	#$58,d0
	bgt.w	.1
	move.l	#tmsize,d1	;tmsize
	neg.w	d0
	cmp.w	#$58,d0
	blt.w	rtss2
.1
	btst	#gmdir,(gmode).w	;gmdir
	beq.w	.0
	eori.w	#tmsize,d1
.0
	movea.w	#(tmstruct-M68K_RAM),a2
	addq.w	#1,tmATOP(a2,d1.w)	;attack time
	rts
releasepl	;player's penalty time is up so let him out (if appropriate). a2 = team, d0 = player*2. Called from ProcessPenaltyList
	movem.l	d0-d3/a0-a3,-(sp)
	movea.w	tmsort(a2),a3	;tmsort
	suba.w	#SCstruct,a3
.0
	adda.w	#SCstruct,a3	;first sort obj not on the ice
	tst.w	position(a3)
	bpl.s	.0
	move.w	d0,d3
	lsr.w	#1,d3
	move.w	tmap(a2),d1	;tmap
	addq.w	#1,tmap(a2)
	bset	#0,(tmstruct+tmflags).w	;home tmflags: tmflcc
	bset	#0,(AwShots+tmflags).w	;visitors tmflags: tmflcc
	movea.l	#priolist,a0
	tst.w	tmgoalie(a2)	;tmgoalie
	bpl.w	.1
	addq.w	#1,a0
.1
	clr.w	position(a3)	;position
	move.b	0(a0,d1.w),position+1(a3)
	bsr.w	Setplass
	bsr.w	setplayer
	bset	#2,pflags2(a3)	;pflags2 bit 2
	movem.l	(sp)+,d0-d3/a0-a3
	rts
GetLowestPen	;a2 = shorthanded team, a3 = team on the power play. Return d0 = power play time left from the penalty box times. Called from updatepwrplay
	clr.w	d0
	clr.w	d3
	lea	$9A(a2),a0	;penalty box list
.getstatus
	clr.w	d2
	move.b	(a0)+,d2
	bmi.w	.endoflist
	move.w	$66(a2,d2.w),d2	;tmpdst
	btst	#$E,d2	;bit 14: coincidental
	bne.s	.getstatus
	sub.w	d3,d2
	add.w	d2,d0
	move.w	d2,d3
	bra.s	.getstatus
.endoflist
	cmpi.w	#6,OldZpos(a3)	;tmap: 6 on ice, done
	beq.w	rtss2
	sub.w	d3,d0
	lea	$9A(a3),a0
	clr.w	d2
.getstatusopp
	move.b	(a0)+,d2
	bmi.w	rtss2
	btst	#6,$66(a3,d2.w)	;coincidental (byte bit 6, word bit 14)
	bne.s	.getstatusopp
	cmp.w	$66(a3,d2.w),d0
	blt.w	rtss2
	add.w	d3,d0
	rts
updatepwrplay	;show graphic and time remaining for power plays. Nothing when gmode2 bit 1 is set, and no song at the start of a home power
	;play (the gmode2 test is kept but both ways go to .uppt). Prints the time and the team on the power play
	btst	#1,(gmode2).w
	bne.w	rtss2
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3	;tmsize
	move.w	tmap(a2),d0	;tmap
	sub.w	tmap(a3),d0
	beq.w	.clrpwrplay	;same number on the ice
	bpl.w	.t0
	btst	#sf2pwrtm,(sflags2).w	;sf2pwrtm: 0 home, 1 visitors
	bne.w	.upp
	bsr.w	.clrpwrplay
	bset	#sf2pwrtm,(sflags2).w
	bra.w	.upp
.t0
	exg	a2,a3
	btst	#sf2pwrtm,(sflags2).w
	beq.w	.upp
	bsr.w	.clrpwrplay
	bclr	#sf2pwrtm,(sflags2).w
.upp
	bset	#sf2pwrplay,(sflags2).w	;sf2pwrplay
	bne.w	.uppt
	addq.w	#1,tmPwrPlays(a3)	;tmPwrPlays
	cmpa.w	#(tmstruct-M68K_RAM),a3	;home team (93 played song $33 here)
	bne.w	.away
.home
	bra.w	.uppt
.away
	bra.s	.home
.uppt
	bsr.w	printz
	String	-(TXPRI+TXMAP1),1,$19,'   ',$16,$17,$18,$19,-(TXPRI+TXMAP1),1,$1A,'  ',0
	bsr.w	GetLowestPen
	bsr.w	PushTime
	bsr.w	print
	movea.l	tmdata(a3),a0	;tmdata
	movea.w	#(mesarea-M68K_RAM),a3
	move.w	#2,(a3)
	bsr.w	appendz
	String	$BF,1,$19
	adda.w	4(a0),a0	;team name
	adda.w	(a0),a0
	movea.l	a0,a1
	bsr.w	appstring
	movea.w	a3,a1
	bra.w	print
.clrpwrplay
	bclr	#sf2pwrplay,(sflags2).w
	beq.w	rtss2
	bra.w	EASNLogo
ClrHor	;revert the graphics back to vertical ice rink mode. Reloads Rinktiles and calls LoadHomeTeamGfx
	movem.l	d0-d7/a0-a6,-(sp)
	bclr	#sfhor,(sflags).w	;sfhor
	move.w	#$3E8,(Oldrow).w	;1000
	move.w	(rinkvrcset).w,d4
	movea.l	#Rinktiles,a2
	jsr	(DecompressGraphicsPlain).l
	jsr	(LoadHomeTeamGfx).l
	bsr.w	SprSort
	btst	#sfpz,(sflags).w	;sfpz
	bne.w	.ex
	bsr.w	printz
	String	-TXMAP1,0,0
	moveq	#$20,d0	;32
	moveq	#$1C,d1	;28
	move.w	#$7FF,d2	;blank tile
	bsr.w	eraser
	bsr.w	printscores1
.ex
	movem.l	(sp)+,d0-d7/a0-a6
	rts
SetHor	;switch graphics to horizontal ice rink graphics mode
	movem.l	d0-d7/a0-a6,-(sp)
	bset	#sfhor,(sflags).w	;sfhor
.p
	btst	#dfok,(disflags).w	;dfok
	bne.s	.p
	clr.w	(Hscroll).w
	clr.w	(Vscroll).w
	bsr.w	SprSort
	bsr.w	printz
	String	-TXMAP2,0,0
	movea.l	#HorRinkMap,a1	;tiles start at HorRinkMap+8
	adda.l	4(a1),a1
	movea.l	#HorRinkTiles,a2	;rink tiles
	clr.w	d0
	move.w	#0,d1
	moveq	#$20,d2	;32
	moveq	#$1C,d3	;28
	move.w	(rinkvrcset).w,d4
	moveq	#0,d5
	bsr.w	dobitmap
	bsr.w	USBoard
	btst	#sfpz,(sflags).w	;sfpz
	bne.w	.ex
	move.w	#$800,d0	;92 $1000
	move.w	(VmMap1).w,d1
	move.w	#$7FF,d2	;blank tile
	bsr.w	DoFill
.ex
	movem.l	(sp)+,d0-d7/a0-a6
	rts
;	printscores1, PrintTeamNameAndScore, PrintTeamLogoAndScore, EASNLogo,
;	USBoard, pplpen, linebar, getlinee, AvgCline, ChkShotStat,
;	loadTeamStruct, SetupTeamForIntermission, RestoreTeamEnergy,
;	reenergizeteam, Intermission, InitScores, UpdateScores, SetScore, sctab,
;	NewTicker, NewTicker2, NewTicker3, NewTicker3pt2, GameLabels,
;	ClearTickerArea, SetTickerAreaPosition, PrintStringFromList,
;	AdvanceStringPtr, DoHiLights, StartHL and StartHL2.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	Team struct from HmShots / AwShots (tmsize $364): 0 tmshots, $C tmscore, $16 tmline, $1E tmdata, $22 tmsort, $24 tmap,
;	$26 tmgoalie, $32 tmpde, $66 tmpdst, $9A penalty box list, $E8 per-player shot bytes, $16A line sets, $34A shots by
;	period, $354 power play shots. Game struct (gsstruct, $10 each): 0 gst1, 2 gst2, 8 gsper, $A gss1, $C gss2, $E gsflags
;	(bit 1 gsfhl, bit 2 gsfso).

printscores1	;Draw scoreboard. Vertical rink: period box and the score box (team names and scores). Horizontal rink
	;.sbscreen: period and both team logos with big scores. The period name is gsp of PerLabels, or name 4 of PerLabels2
	;when gmode2 bit 1 is set; the horizontal rink uses PerLabels2 (name 4 when bit 0 is set). sflags5 bit 7 sets crowdnoisedelay = $78.
	;Called from USBoard, Pausemode, lcfound2 and others
	movem.l	d0-d2/a0-a3,-(sp)
	btst	#sfhor,(sflags).w	;sfhor
	bne.w	.sbscreen
	bclr	#7,(sflags5).w
	beq.w	.0
	move.w	#$78,(crowdnoisedelay).w
.0
	bsr.w	printz
	String	-(TXPRI+TXMAP1),0,$17
	moveq	#9,d0
	moveq	#5,d1
	bsr.w	Framer
	bset	#dfclock,(disflags).w	;dfclock
	bsr.w	printz
	String	-(TXPRI+TXMAP1),1,$18
	move.w	(gsp).w,d0	;period name
	movea.l	#PerLabels,a1
	btst	#1,(gmode2).w
	beq.w	.1
	move.w	#4,d0
	movea.l	#PerLabels2,a1
.1
	bsr.w	PrintStringFromList
	bsr.w	EASNLogo
	btst	#sf3llcs,(sflags3).w	;sf3llcs: lower line change box is up
	bne.w	.ex
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$17,$17
	moveq	#8,d0
	moveq	#5,d1
	bsr.w	Framer
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$18,$1A	;home team on the lower row
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	PrintTeamNameAndScore
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$18,$18
	adda.w	#tmsize,a2	;tmsize
	bsr.w	PrintTeamNameAndScore
.ex
	movem.l	(sp)+,d0-d2/a0-a3
	rts
.sbscreen
	bsr.w	printz
	String	-(TXPRI+TXMAP2),$11,2
	move.w	(gsp).w,d0
	btst	#0,(gmode2).w
	beq.w	.2
	move.w	#4,d0
.2
	movea.l	#PerLabels2,a1	;the horizontal rink always takes the name from PerLabels2
	bsr.w	AdvanceStringPtr
	move.w	(a1),d0
	lsr.w	#1,d0	;center the period name on x $11
	sub.w	d0,(printx).w
	bsr.w	print
	bsr.w	printz
	String	-(TXPRI+TXMAP2),$17,2
	movea.w	#(tmstruct-M68K_RAM),a2
	clr.w	d0	;home logo data offset
	bsr.w	PrintTeamLogoAndScore
	bsr.w	printz
	String	-(TXPRI+TXMAP2),8,2
	adda.w	#tmsize,a2	;tmsize
	move.w	#$2C,d0	;visitor logo data offset
	bsr.w	PrintTeamLogoAndScore
	bra.s	.ex
PrintTeamNameAndScore	;Print the team name of team a2 at printx/printy, then its score as 2 digits at x $1C. Called twice from printscores1
	movea.l	tmdata(a2),a1	;tmdata
	adda.w	4(a1),a1
	adda.w	(a1),a1	;skip the first string to the team name
	bsr.w	print
	move.w	#$1C,(printx).w
	move.w	tmscore(a2),d0	;tmscore
	moveq	#2,d1
	bsr.w	PushNumberWidth
	bra.w	print
PrintTeamLogoAndScore	;Draw the team logo map (PutTeamBlock, d0 = offset) 5 columns left of printx
	;then the score of team a2 in big font, centered 2 rows lower; a 2 digit score is moved one more left. Called twice from printscores1
	move.w	(printx).w,-(sp)
	subq.w	#5,(printx).w
	jsr	(PutTeamBlock).l
	move.w	(sp)+,(printx).w
	addq.w	#2,(printy).w
	move.w	tmscore(a2),d0	;tmscore
	cmp.w	#$A,d0
	bge.w	.0
	bra.w	.1
.0
	subq.w	#1,(printx).w
.1
	bsr.w	PushNumber
	move.w	(a1),d0	;center on the old printx
	subq.w	#2,d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	addq.w	#1,(printx).w
	bra.w	printbig
EASNLogo	;Draw the EASN logo map at x 1, y $19 on the vertical ice rink if no power play. Called from printscores1 and updatepwrplay
	btst	#sf2pwrplay,(sflags2).w	;sf2pwrplay
	bne.w	rtss2
	bsr.w	printz
	String	-(TXPRI+TXMAP1),1,$19
	movea.l	#EASNmap,a1
	adda.l	4(a1),a1
	movea.w	#NoTiles,a2
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2	;width and height from the map header
	move.w	2(a1),d3
	move.w	(EASNcset).w,d4
	clr.w	d5
	bra.w	dobitmap
USBoard	;Update score board, including the players in the penalty box and their time remaining. Called from InProgress and SetHor
	movem.l	d0-d7/a0-a3,-(sp)
	bset	#dfclock,(disflags).w	;dfclock
	bsr.w	printscores1
	bsr.w	printz
	String	-(TXPRI+TXMAP2),$14,8
	movea.w	#(tmstruct-M68K_RAM),a2	;home team
	bsr.w	.dispen
	bsr.w	printz
	String	-(TXPRI+TXMAP2),5,8
	movea.w	#(AwShots-M68K_RAM),a2	;visitors
	bsr.w	.dispen
	movem.l	(sp)+,d0-d7/a0-a3
	rts
.dispen	;penalty box list of team a2: the players without a coincidental penalty first, then those with one
	lea	$9A(a2),a0
.l1
	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	.p2	;end of list
	btst	#6,tmpdst(a2,d0.w)	;coincidental (tmpdst high byte bit 6)
	bne.s	.l1
	bsr.w	pplpen
	bra.s	.l1
.p2
	lea	$9A(a2),a0
.l2
	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	rtss2
	btst	#6,tmpdst(a2,d0.w)
	beq.s	.l2
	bsr.w	pplpen
	bra.s	.l2
pplpen	;print one penalty box line: player number and time remaining. a2 = team, d0 = roster offset (player*2). Only
	;rows up to y $A are printed; printy += 1. Called from USBoard .dispen
	cmpi.w	#$A,(printy).w
	bhi.w	rtss2	;no room for more rows
	move.w	tmpdst(a2,d0.w),d2
	andi.w	#$7FF,d2	;penalty time
	movea.l	tmdata(a2),a1	;tmdata
	adda.w	(a1),a1
	lsr.w	#1,d0
.find
	adda.w	(a1),a1	;skip d0+1 roster entries (name string + 8 bytes)
	addq.w	#8,a1
	dbf	d0,.find
	clr.w	d0
	move.b	-8(a1),d0	;player number (BCD)
	move.w	(printx).w,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1	;mesarea+2
	bsr.w	ConvertByteToDigits
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#4,(a1)	;string length: 2 digits
	bsr.w	print
	move.w	d2,d0
	bsr.w	PushTime
	bsr.w	print
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	rts
linebar	;Draw the energy bar of line d0 for team a2 at printx/printy (bitmap from the bar map, 16 steps). Called from SetLCmode2
	movem.l	d0-d5/a0-a2,-(sp)
	bsr.w	getlinee
	move.w	(printa).w,-(sp)
	move.w	#$8000,(printa).w
	ext.l	d0
	divu.w	#$100,d0	;4096/16
	cmp.w	#$F,d0
	bls.w	.ok
	moveq	#$F,d0
.ok
	moveq	#$F,d1	;d1 = bar frame (15 = empty)
	sub.w	d0,d1
	clr.w	d0
	movea.l	#EnergyBarMap,a1
	adda.l	4(a1),a1
	movea.w	#NoTiles,a2
	move.w	(a1),d2
	moveq	#1,d3
	move.w	(energybarchars).w,d4
	moveq	#0,d5
	bsr.w	dobitmap
	move.w	(sp)+,(printa).w
	movem.l	(sp)+,d0-d5/a0-a2
	rts
getlinee	;d0 = line number, a2 = team struct. Return d0 = energy level of this line
	movem.l	d1-d5/a0-a3,-(sp)
	lea	$16A(a2),a1	;line sets
	asl.w	#3,d0
	adda.w	d0,a1
	clr.l	d0
	clr.w	d1
	movea.l	#priolist,a0
	move.w	tmap(a2),d4	;tmap
	bra.w	.next
.loop
	clr.w	d5
	move.b	0(a0,d4.w),d5	;position
	beq.w	.next	;goalie energy doesn't count
	clr.w	d3
	move.b	0(a1,d5.w),d3	;player number
	asl.w	#1,d3
	addq.w	#1,d1
	add.w	tmpde-2(a2,d3.w),d0	;tmpde-2
.next
	dbf	d4,.loop
	divu.w	d1,d0
	movem.l	(sp)+,d1-d5/a0-a3
	rts
AvgCline	;Return d0 = average energy of current line on team a2
	movem.l	d1-d3/a0,-(sp)
	clr.l	d0
	clr.w	d1
	moveq	#5,d2
	movea.w	tmsort(a2),a0	;tmsort
.loop
	tst.w	position(a0)	;position
	ble.w	.next
	clr.w	d3
	move.b	pnum(a0),d3	;pnum
	add.w	d3,d3
	add.w	tmpde(a2,d3.w),d0	;tmpde
	addq.w	#1,d1
.next
	adda.w	#SCstruct,a0
	dbf	d2,.loop
	tst.w	d1
	beq.w	.ex
	divu.w	d1,d0
.ex
	movem.l	(sp)+,d1-d3/a0
	rts
ChkShotStat	;determine if shot taken, add to appropriate stats: crowd, team, shooter and goalie shots against. Nothing while the
	;clock is stopped or in a highlight, PP shots ($354) and period shots ($34A), and a second path (sflags4 bit 0, sflags8 bit 3 every
	;second call) that counts the shot for the player in the last ScoreSum entry
	btst	#0,(gmode).w	;gmclock: clock stopped
	bne.w	rtss2	;exit if so
	btst	#4,(gmode).w	;gmhl: highlight
	bne.w	rtss2	;exit if so
	bclr	#4,(sflags2).w	;sf2shot: shot taken
	bne.w	.Cwdupdate	;it was set
	btst	#0,(sflags4).w
	beq.w	rtss2	;exit if cleared
	bclr	#3,(sflags8).w
	bne.w	.0
	bset	#3,(sflags8).w
	bra.w	rtss2
.0
	movem.l	d0-d1/a1-a3,-(sp)
	move.l	a4,-(sp)
	movea.l	#ScoreSum-6,a4	;#$FFFFC46E (ChkCnt). +ScoreSumbytes, then 2(a4) = the last ScoreSum entry
	adda.w	(ScoreSumbytes).w,a4
	movea.l	#tmstruct,a2	;home team
	btst	#7,2(a4)	;entry flag: visitors
	beq.w	.pllookup
	adda.w	#$364,a2	;tmsize
.pllookup
	clr.w	d0
	move.b	3(a4),d0	;pnum (roster offset)
	movea.l	(sp)+,a4
	movea.w	$22(a2),a2	;tmsort
	move.w	#5,d1
.findplayer
	cmp.b	$66(a2),d0	;pnum
	beq.w	.foundplayer
	adda.w	#$80,a2	;SCstruct
	dbf	d1,.findplayer
	bra.w	.ex
.foundplayer
	move.w	SCnum(a2),d0	;SCnum
	bra.w	.addShot
.Cwdupdate
	movem.l	d0-d1/a1-a3,-(sp)
	addi.w	#$64,(crowdlevel).w	;100
	addi.w	#$A,(CwdExciteLvl).w
	move.w	(shotplayer).w,d0
.addShot
	asl.w	#7,d0	;scsize
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	bsr.w	loadTeamStruct
	addq.w	#1,(a2)	;tmshots
	btst	#5,(sflags2).w	;sf2pwrplay
	beq.w	.2
	btst	#6,(sflags2).w	;sf2pwrtm: 0 home, 1 visitors
	bne.w	.1
	btst	#6,pflags(a3)	;pfteam
	bne.w	.2	;not the team on the power play
.PPshot
	addq.w	#1,$354(a2)	;power play shots
	bra.w	.2
.1
	btst	#6,pflags(a3)	;pfteam
	bne.s	.PPshot
.2
	move.l	a2,-(sp)
	move.w	(gsp).w,d0	;period
	add.w	d0,d0
	adda.w	d0,a2
	addq.w	#1,$34A(a2)	;shots by period
	movea.l	(sp)+,a2
	clr.w	d0
	move.b	pnum(a3),d0	;pnum
	addi.w	#$E8,d0
	addq.b	#1,0(a2,d0.w)	;shooter's shot count
	move.w	tmgoalie(a1),d0	;other team's tmgoalie
	bmi.w	.ex	;empty net
	addi.w	#$E8,d0
	addq.b	#1,0(a1,d0.w)	;goalie's shots against
.ex
	movem.l	(sp)+,d0-d1/a1-a3
	rts
loadTeamStruct	;return a2 = team struct of player a3, a1 = the other team's struct. Called from ChkShotStat and updateplayers
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1	;tmsize
	btst	#pfteam,pflags(a3)	;pfteam
	beq.w	rtss2
	exg	a1,a2
	rts
SetupTeamForIntermission	;Reset the bench, then for each team refill energy and pick the starting line: power play 1 (3)
	;for the team with more players on ice, PK1 (5) for the team with fewer, else 0. Called from Intermission
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a3
	bsr.w	.r
	exg	a2,a3	;falls in for the other team
.r	;refill this team
	bsr.w	reenergizeteam
	clr.w	tmline(a3)	;tmline
	tst.w	(OptLine).w
	bne.w	rtss2	;line changes off
	move.w	tmap(a3),d0
	sub.w	tmap(a2),d0
	beq.w	rtss2
	move.w	#3,tmline(a3)	;Pw1
	tst.w	d0
	bpl.w	rtss2
	move.w	#5,tmline(a3)	;PK1
	rts
RestoreTeamEnergy	;a2 = team: max energy (tmpde $1000) for every player. The skip needs tmpdst to be both -3 and -4, so it never happens.
	;Called from the menu code before ReplayMode
	moveq	#$32,d0	;(MaxRos-1)*2
.loop
	cmpi.w	#$FFFD,$66(a2,d0.w)
	bne.w	.0
	cmpi.w	#$FFFC,$66(a2,d0.w)
	bne.w	.0
	bra.w	.1
.0
	move.w	#$1000,$32(a2,d0.w)	;tmpde
.1
	subq.w	#2,d0
	bpl.s	.loop
	rts
reenergizeteam	;Set all players to max energy on team a2 except those at tmpdst -4; players marked -3 in tmpdst go to
	;the bench (-2). Called from SetupTeamForIntermission and StartHL2 .setteam
	moveq	#$32,d0	;(MaxRos-1)*2
.loop
	cmpi.w	#$FFFC,$66(a2,d0.w)
	beq.w	.nb
	move.w	#$1000,tmpde(a2,d0.w)	;tmpde
	cmpi.w	#$FFFD,tmpdst(a2,d0.w)
	bne.w	.nb
	move.w	#$FFFE,tmpdst(a2,d0.w)	;on bench
.nb
	subq.w	#2,d0
	bpl.s	.loop
	rts
Intermission	;end of period junk (zamboni/stats). Opens the pause menu screen (item list by period, +5 in playoffs), shows the ticker scores
	;of the other games, then the highlights; Start on either pad cuts it short. When gsp is 4 the clock is cleared and UpdateRecords runs first,
	;and gmode2 bit 0 picks the ShootoutIntermissionMenu item list. Called from PeriodOver
	cmpi.w	#4,(gsp).w
	bne.w	.1
	move.w	#0,(gameclock).w
	jsr	(UpdateRecords).l
.1
	bsr.w	SetupTeamForIntermission
	moveq	#$F,d0
	movea.w	#(SortCords-M68K_RAM),a0
.clr
	clr.w	(a0)	;Xpos
	adda.w	#SCstruct,a0	;SCstruct
	dbf	d0,.clr
	move.w	(ExtraChars).w,d4
	movea.l	#ZamFrameList+8,a2	;+8
	bsr.w	DecompressGraphicsPlain
	move.w	#$140,(zamx).w	;320
	move.w	(gsp).w,d0
	tst.w	(OptPlayMode).w
	beq.w	.ss
	addq.w	#5,d0	;playoffs
.ss
	asl.w	#2,d0
	lea	.sslist(pc),a0
	movea.l	0(a0,d0.w),a0
	btst	#0,(gmode2).w
	beq.w	.2
	movea.l	#ShootoutIntermissionMenu,a0
.2
	bset	#sfpz,(sflags).w	;sfpz
	movea.l	#SetupPauseScreen,a1
	jsr	(InitMenuState).w
	bsr.w	GetShifter
	move.w	d1,(TickerNum).w
.top
	tst.w	(TickerNum).w
	bmi.w	.doh	;no more ticker games
	bsr.w	NewTicker2
	bsr.w	NewTicker3
	move.w	#$96,d0	;150 frames
	bsr.w	waitxsr
	btst	#7,d1	;sbut
	bne.w	.clrh
	bsr.w	ClearTickerArea
	move.w	#$3C,d0	;60 frames
	bsr.w	waitxsr
	btst	#7,d1
	beq.s	.top
.clrh
	bset	#sf3sbut,(sflags3).w	;sf3sbut
.doh
	bsr.w	DoHiLights
	bclr	#sf3sbut,(sflags3).w
	bne.w	.clrz
.wait
	move.w	#$1E0,d0	;480 frames
	bsr.w	waitxsr
	btst	#7,d1
	bne.w	.clrz
	tst.w	(cont1team).w
	bne.s	.wait	;keep waiting while a pad is on a team
	tst.w	(cont2team).w
	bne.s	.wait
.clrz
	st	(zamx).w
	rts
.sslist	;menu item lists by period, then playoff period
	dc.l	StartGameText,IntermissionText,IntermissionText,IntermissionText,ExitGameText
	dc.l	StartGameTextPO,IntermissionText,IntermissionText,IntermissionText,ExitGameTextPO
InitScores	;initialize other games scores/period in playoffs. Called from StartGame
	cmpi.w	#1,(gamelevel).w
	bgt.w	rtss2
	bsr.w	GetShifter
	movea.w	#(gsstruct-M68K_RAM),a0
	moveq	#$10,d0	;gssize
	mulu.w	d1,d0
	adda.w	d0,a0
.top
	cmp.w	(gamenum).w,d1
	beq.w	.next
	btst	#2,$E(a0)	;gsfso
	bne.w	.next
	clr.w	8(a0)	;gsper
	moveq	#3,d0
	bsr.w	randomd0
	bra.w	.1
.0
	bsr.w	SetScore
.1
	dbf	d0,.0
.next
	suba.w	#$10,a0	;gssize
	dbf	d1,.top
	rts
UpdateScores	;update ticker score values. Called from PeriodOver
	bsr.w	GetShifter
	move.w	d1,(TickerNum).w
	movea.w	#(gsstruct-M68K_RAM),a0
	moveq	#$10,d0	;gssize
	mulu.w	d1,d0
	adda.w	d0,a0
.top
	cmp.w	(gamenum).w,d1
	beq.w	.next
	bclr	#1,$E(a0)	;gsfhl
	btst	#2,$E(a0)	;gsfso
	bne.w	.next
	bsr.w	SetScore
.next
	suba.w	#$10,a0	;gssize
	dbf	d1,.top
	rts
SetScore	;add to score for game in a0. After period 3 a game within one goal goes to OT (gsper 3) and asks for a highlight
	cmpi.w	#4,8(a0)	;gsper
	bge.w	rtss2
	movem.l	d0-d1/a0-a1,-(sp)
	cmpi.w	#3,8(a0)
	bne.w	.o
	move.w	#5,8(a0)	;final
	move.w	$A(a0),d0	;gss1
	sub.w	$C(a0),d0	;gss2
	cmp.w	#1,d0
	bgt.w	.ex
	cmp.w	#$FFFF,d0
	blt.w	.ex
	move.w	#3,8(a0)	;close game: overtime
	bset	#1,$E(a0)	;gsfhl
	bra.w	.ex
.o
	addq.w	#1,8(a0)
	move.w	(a0),d0	;gst1
	move.w	2(a0),d1	;gst2
	bsr.w	.getscore
	add.w	d0,$A(a0)	;gss1
	move.w	2(a0),d0
	move.w	(a0),d1
	bsr.w	.getscore
	add.w	d0,$C(a0)	;gss2
.ex
	movem.l	(sp)+,d0-d1/a0-a1
	rts
.getscore	;d0 = scoring team, d1 = other team. Adds the scoring team's (bits 4-6) and the other team's (bits 0-2) sctab rows as weights. Return d0 = goals 0-3
	asl.w	#2,d0
	movea.w	#TeamList,a1
	movea.l	0(a1,d0.w),a1
	adda.w	8(a1),a1
	move.b	(a1),d0
	andi.w	#$70,d0
	lsr.w	#1,d0	;row * 8
	lea	sctab(pc),a1
	move.l	0(a1,d0.w),(nibblebuffer).w
	move.l	4(a1,d0.w),(nibblebuffer+4).w
	asl.w	#2,d1
	movea.w	#TeamList,a1
	movea.l	0(a1,d1.w),a1
	adda.w	8(a1),a1
	move.b	(a1),d0
	andi.w	#7,d0
	asl.w	#3,d0
	lea	sctab(pc),a1
	move.l	0(a1,d0.w),d1
	add.l	d1,(nibblebuffer).w
	move.l	4(a1,d0.w),d1
	add.l	d1,(nibblebuffer+4).w
	moveq	#4,d0	;4 weights
	bra.w	WeightedRandomSelect
sctab	;weights for 0, 1, 2, 3 goals, 8 rows (92 had 4 percent bytes per row)
	dc.w	$2B,$1E,$17,4
	dc.w	$27,$20,$18,5
	dc.w	$23,$21,$1A,6
	dc.w	$1E,$22,$1E,6
	dc.w	$1A,$24,$1E,8
	dc.w	$16,$25,$1F,$A
	dc.w	$13,$26,$1F,$C
	dc.w	$F,$26,$20,$F
NewTicker	;show the next ticker score once the clock is at 8:00 or less. d3 = -1 if not. Called from chkprogress. Falls into NewTicker2
	moveq	#-1,d3
	cmpi.w	#$1E0,(gameclock).w	;480
	bgt.w	rtss2
NewTicker2	;goto next ticker. Return d3 = game, or neg if none left. Falls into NewTicker3
	move.w	(TickerNum).w,d3
	bmi.w	rtss2
	subq.w	#1,(TickerNum).w
	cmp.w	(gamenum).w,d3	;don't show current game as ticker
	beq.s	NewTicker2
CheckGameTickerStatus	;d3 = game. Return a0 = its gstruct; skip to the next ticker game if a highlight is coming up or the series is over. Called from StartHL2
	moveq	#$10,d0	;gssize
	mulu.w	d3,d0
	movea.w	#(gsstruct-M68K_RAM),a0
	adda.w	d0,a0
	btst	#1,$E(a0)	;gsfhl
	bne.s	NewTicker2	;don't show if hilite coming up
	btst	#2,$E(a0)	;gsfso
	bne.s	NewTicker2	;don't show if the series is over for this game
	rts
NewTicker3	;Display ticker score for game d3 (a0 = gstruct entry), skip if d3 is negative. Called from chkprogress, Intermission and StartHL2
	tst.w	d3
	bmi.w	rtss2
	bsr.w	SetTickerAreaPosition
	bsr.w	Framer
	addq.w	#1,(printx).w
	subq.w	#4,(printy).w
	move.w	(printx).w,-(sp)
	bsr.w	GetShifter
	move.w	#$A000,(printa).w
	bsr.w	printz
	String	'                        '	;24 spaces
	move.w	(sp),(printx).w
	moveq	#1,d0
	add.w	(gamelevel).w,d0
	tst.w	(OptPlayMode).w
	bne.w	.0
	clr.w	d0	;not playoffs: 'EA Hockey Night'
.0
	lea	GameLabels(pc),a1
	bsr.w	PrintStringFromList
	move.w	8(a0),d0	;gsper
	subq.w	#1,d0
	movea.l	#PerLabels,a1
	bsr.w	AdvanceStringPtr
	move.w	(a1),d0	;period name centered on x+$17
	lsr.w	#1,d0
	neg.w	d0
	add.w	(sp),d0
	addi.w	#$17,d0
	move.w	d0,(printx).w
	bsr.w	print
	move.w	#$8000,(printa).w
	move.w	2(a0),d0	;gst2
	move.w	$C(a0),d1	;gss2
	bsr.w	.tn
	move.w	(a0),d0	;gst1
	move.w	$A(a0),d1	;gss1
	bsr.w	.tn
	addq.w	#2,sp
	rts
.tn	;print team d0 name and score d1 on the next row
	move.w	4(sp),(printx).w
	addq.w	#1,(printy).w
	movea.w	#TeamList,a1
	asl.w	#2,d0
	movea.l	0(a1,d0.w),a1
	adda.w	4(a1),a1	;team name
	bsr.w	print
	move.w	4(sp),(printx).w
	addi.w	#$15,(printx).w	;92 23
	move.w	d1,d0
	moveq	#2,d1
	bsr.w	PushNumberWidth
	bra.w	print
GameLabels	;Ticker titles, by OptPlayMode and gamelevel
	String	'EA Hockey Night'
	String	'Stanley Cup Qualifier'
	String	'Quarterfinal'
	String	'Stanley Cup Semifinal'
ClearTickerArea	;Erase the ticker box. Called from Intermission and StartHL2
	bsr.w	SetTickerAreaPosition
	move.w	#$7FF,d2	;blank char
	bra.w	eraser
SetTickerAreaPosition	;Set printx/printy/printm for the ticker box (x 3, y $17; the $BD map in pause mode). Return d0 =
	;$1A wide, d1 = 5 high. Called from NewTicker3pt2 and ClearTickerArea
	bsr.w	printz
	String	-(TXPRI+TXMAP3),3,$17
	btst	#sfpz,(sflags).w	;sfpz
	bne.w	.1
	bsr.w	printz
	String	-(TXPRI+TXMAP1),3,$17
.1
	moveq	#$1A,d0
	moveq	#5,d1
	rts
PrintStringFromList	;Print string d0 of the String list a1 with printsmall
	bsr.w	AdvanceStringPtr
	bra.w	printsmall
AdvanceStringPtr	;Return a1 = string d0 of the String list a1
	bra.w	.0
.loop
	adda.w	(a1),a1
.0
	dbf	d0,.loop
	rts
DoHiLights	;Hilites logic: search for hilite game and show hilite. Called from Intermission
	bsr.w	GetShifter
	moveq	#$10,d3	;gssize
	mulu.w	d1,d3
	movea.w	#(gsstruct-M68K_RAM),a0
	adda.w	d3,a0
.top
	btst	#2,$E(a0)	;gsfso
	bne.w	.next
	bclr	#1,$E(a0)	;gsfhl
	beq.w	.next
	bsr.w	StartHL
.next
	suba.w	#$10,a0	;gssize
	dbf	d1,.top
	rts
StartHL	;Play hilite for game a0, d1 = game. Called from DoHiLights. Falls into StartHL2
	movem.l	d0-d7/a0-a6,-(sp)
StartHL2	;Play hilite for game a0. Start skips it with a random result. A tied game is replayed (beq StartHL2). Uses
	;song $79, setupice_highlight, setplayercolors
	btst	#sf3sbut,(sflags3).w	;sf3sbut
	bne.w	.nhl0
	bsr.w	.sv
	move.w	d1,d3
	bsr.w	CheckGameTickerStatus
	bsr.w	NewTicker3	;show score from hilight game
	btst	#sf3sbut,(sflags3).w
	bne.w	.nhl1
	move.w	#4,(printx).w
	subq.w	#6,(printy).w
	moveq	#$18,d0	;24
	moveq	#3,d1
	bsr.w	Framer
	addq.w	#1,(printx).w
	subq.w	#2,(printy).w
	bsr.w	printz
	String	'Highlight from game:'	;the text as code
	move.w	#$B4,d0	;180 frames
	bsr.w	waitxsr
	btst	#7,d1	;sbut
	bne.w	.nhl1
	st	(zamx).w
	clr.w	(CwdExciteLvl).w
	move.w	(a0),(HomeTeam).w	;set up teams for game in a0
	move.w	2(a0),(VisTeam).w
	move.l	a0,-(sp)
	clr.w	(tmstruct+tmgoalie).w
	clr.w	(AwShots+tmgoalie).w
	jsr	(clearTeamStats).l
	jsr	(restoreteams).w
	st	(c1playernum).w
	st	(c2playernum).w
	clr.w	(cont1team).w
	clr.w	(cont2team).w
	moveq	#$78,d0	;120
	bsr.w	randomd0
	addi.w	#$3C,d0	;60
	move.w	d0,(gameclock).w
	movea.l	(sp),a0
	move.w	8(a0),(gsp).w	;gsper
	subq.w	#1,(gsp).w
	move.w	$A(a0),(HmGoals).w	;gss1
	move.w	$C(a0),(AwGoals).w	;gss2
	move.b	#$10,(gmode).w	;1<<gmhl
	btst	#0,(gsp+1).w
	beq.w	.ndi
	bset	#gmdir,(gmode).w	;gmdir
.ndi
	clr.b	(sflags).w
	move.b	#4,(sflags2).w	;1<<sf2drec
	clr.b	(sflags3).w
	bclr	#4,(disflags).w
	bset	#dfclock,(disflags).w	;dfclock
	clr.w	(glovecords).w
	clr.b	(iflags).w
	st	(RefCnt).w
	st	(puckcross2).w
	st	(puckcross6).w
	jsr	(p_turnoff).l
	bsr.w	setupice_highlight
	bsr.w	ClrHor
	movea.l	#VDP_DATA,a0
	move.w	#VDPR_WINX,Vctrl-Vdata(a0)	;window H position 0
	move.w	#VDPR_WINY,Vctrl-Vdata(a0)	;window V position 0
	move.w	(ExtraChars).w,d4	;ref cam chars
	movea.l	#RefsMap+8,a2	;+8
	bsr.w	DecompressGraphicsPlain
	clr.w	(Vpos).w
	clr.w	(Hpos).w
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	.setteam
	adda.w	#tmsize,a2	;tmsize
	bsr.w	.setteam
	bsr.w	resetplstuff
	moveq	#$B,d0
	movea.l	#.postab,a0
	movea.w	#(SortCords-M68K_RAM),a1
.loop
	move.w	position(a1),d1	;position
	btst	#pfgoal,pflags(a1)	;pfgoal
	bne.w	.pl0
	addq.w	#6,d1
.pl0
	asl.w	#2,d1
	move.w	0(a0,d1.w),(a1)	;Xpos
	move.w	2(a0,d1.w),Ypos(a1)	;Ypos
	clr.w	Xvel(a1)	;Xvel
	clr.w	Yvel(a1)	;Yvel
	adda.w	#SCstruct,a1
	dbf	d0,.loop
	bsr.w	SprSort
	move.w	#$18,(palcount).w
	move.w	(vcount).w,(oldvcount).w
	move.w	#$B4,-(sp)	;180 frames after the clock stops
.0
	jsr	(DoGameFrame).w
	btst	#gmclock,(gmode).w	;gmclock
	beq.w	.1
	subq.w	#1,(sp)
	bmi.w	.endhl
.1
	bsr.w	orjoy
	btst	#5,d1	;cbut
	bne.w	.2
	btst	#7,d1	;sbut
	beq.s	.0
.2
	move.w	(HmGoals).w,d0	;tied: random winner
	cmp.w	(AwGoals).w,d0
	bne.w	.endhl
	move.w	(VDP_CNTR).l,d0	;hvcount
	andi.w	#1,d0
	add.w	d0,(HmGoals).w
	eori.w	#1,d0
	add.w	d0,(AwGoals).w
.endhl
	addq.w	#2,sp
	movea.l	(sp)+,a0
	movem.l	d1/a0,-(sp)
	jsr	(KillCrowd).l
	jsr	(p_turnoff).l
	movem.l	(sp)+,d1/a0
	move.w	(HmGoals).w,$A(a0)	;gss1
	move.w	(AwGoals).w,$C(a0)	;gss2
	bsr.w	forceblack
	moveq	#$F,d0
	movea.w	#(SortCords-M68K_RAM),a0
.clr
	clr.w	(a0)
	adda.w	#SCstruct,a0
	dbf	d0,.clr
	bsr.w	.lo
	bsr.w	setplayercolors
	bsr.w	SetHor
	bsr.w	setvideo
	jsr	(SetupPauseScreen).w	;pause menu screen
	jsr	(DrawMenuScreen).w
	move.w	#$18,(palcount).w
	move.w	#SngEOG,-(sp)	;song $79
	bsr.w	song
	movem.l	(sp),d0-d7/a0-a6
	move.w	#4,8(a0)	;gsper: OT
	move.w	$A(a0),d0
	cmp.w	$C(a0),d0
	beq.w	StartHL2	;still tied: play another hilite
	move.w	#5,8(a0)	;final
	move.w	d1,d3
	bsr.w	CheckGameTickerStatus
	bsr.w	NewTicker3
	move.w	#$B4,d0
	bsr.w	waitxsr
	btst	#7,d1
	bne.w	.exit2
	bsr.w	ClearTickerArea
	move.w	#$3C,d0
	bsr.w	waitxsr
	btst	#7,d1
	beq.w	.exit
.exit2
	bset	#sf3sbut,(sflags3).w	;sf3sbut
.exit
	movem.l	(sp)+,d0-d7/a0-a6
	rts
.nhl1
	bsr.w	.lo
	bsr.w	.ranres
	bra.s	.exit2
.nhl0
	bsr.w	.ranres
	bra.s	.exit
.setteam	;refill energy, set personnel; also clears sflags8 bit 7
	jsr	(reenergizeteam).l
	bsr.w	setpersonel
	bsr.w	forcepldata
	st	$18(a2)
	bclr	#7,(sflags8).w
	st	$1A(a2)
	st	$1C(a2)
	rts
.ranres	;random resolve of game (if tied = random score)
	move.w	$A(a0),d0
	cmp.w	$C(a0),d0
	bne.w	.rr0
	move.w	(VDP_CNTR).l,d0	;hvcount
	andi.w	#1,d0
	add.w	d0,$A(a0)
	eori.w	#1,d0
	add.w	d0,$C(a0)
.rr0
	move.w	#5,8(a0)	;gsper: final
	rts
.sv	;save $5BE words from gmode to M68K_RAM, then ScoreSumbytes
	move.w	#$5BD,d0
	movea.w	#(gmode-M68K_RAM),a1
	movea.l	#M68K_RAM,a2
.sv1
	move.w	(a1)+,(a2)+
	dbf	d0,.sv1
	move.w	(ScoreSumbytes).w,(a2)+
	rts
.lo	;restore what .sv saved
	move.w	#$5BD,d0
	movea.w	#(gmode-M68K_RAM),a2
	movea.l	#M68K_RAM,a1
.lo1
	move.w	(a1)+,(a2)+
	dbf	d0,.lo1
	move.w	(a1)+,(ScoreSumbytes).w
	rts
.postab	;Xpos,Ypos by position (goalie, l.def, r.def, l.wing, center, r.wing), pfgoal set, then clear
	dc.w	0,-240,-70,-140,20,-110,-100,-60,25,-40,70,-80
	dc.w	0,240,34,90,-55,80,100,40,-10,10,-50,0
