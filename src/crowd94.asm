LoadCrowdRec	;CrowdRecord = the arena record of HomeTeam from save RAM (ReadCrowdRecord into the buffer at ThreeStars), $50 when none. Called from StartGame
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(HomeTeam).w,d1
	ext.l	d1
	movea.l	#ThreeStars,a0
	jsr	(ReadCrowdRecord).l
	move.b	8(a0),d0
	beq.w	.none
	andi.w	#$FF,d0
	bra.w	.ex
.none
	move.w	#$50,d0
.ex
	move.w	d0,(CrowdRecord).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
Crowd_Noise	;The crowd meter each frame: crowd noise on / off (sflags5 bit 7) from CwdExciteLvl against
	;CrowdRecord / CrowdAvg, and every $14 ticks CurCrowdMeter (sqrt(level * 4) + 65 dB) and CrowdPeak. Called from setvideo
	btst	#7,(sflags).w	;screen is in horizontal mode
	bne.w	.ex1
	btst	#0,(gmode2).w
	bne.w	.ex1
	btst	#0,(sflags3).w	;check if game paused
	bne.w	.ex2
	btst	#7,(sflags5).w
	bne.w	.chkoff
	tst.w	(crowdnoisedelay).w
	beq.w	.chkon
	subq.w	#1,(crowdnoisedelay).w
	bpl.w	.ex1
	clr.w	(crowdnoisedelay).w
.ex2
	rts
.chkon
	move.w	(CrowdRecord).w,d0
	move.w	d0,(CrowdAvg).w
	subi.w	#$B,(CrowdAvg).w
	subi.w	#$49,d0
	muls.w	d0,d0
	asr.l	#2,d0
	addq.w	#6,d0
	cmp.w	(CwdExciteLvl).w,d0
	bgt.w	.ex1
	bset	#7,(sflags5).w
	rts
.chkoff
	move.w	(CrowdAvg).w,d0
	subi.w	#$41,d0
	muls.w	d0,d0
	asr.l	#2,d0
	cmp.w	(CwdExciteLvl).w,d0
	blt.w	.meter
	bclr	#7,(sflags5).w
.meter
	sub.w	d7,(CwdChkCntr).w
	bpl.w	.ex1
	move.w	#$14,(CwdChkCntr).w
	addq.w	#1,(CwdChkCnt).w
	move.w	(CwdExciteLvl).w,d0
	ext.l	d0
	asl.w	#2,d0
	jsr	(sroot).l
	addi.w	#$41,d0
	move.w	d0,(CurCrowdMeter).w
	cmp.w	(CrowdPeak).w,d0
	ble.w	.chkrec
	move.w	d0,(CrowdPeak).w
.chkrec
	move.w	(CurCrowdMeter).w,d0
	cmp.w	(CrowdRecord).w,d0
	blt.w	.stack
	bra.w	.stack	;*+4
.stack
	movem.l	d0-d7/a0-a6,-(sp)
	movem.l	(sp)+,d0-d7/a0-a6
.ex1
	rts
stopna2	;Slow the velocity at $28 / $2A of a3 toward 0 by $7D0. Called from goalieacc
	tst.w	Xvel(a3)
	bpl.w	.xp
	addi.w	#$7D0,Xvel(a3)
	bmi.w	.y
	clr.w	Xvel(a3)
.xp
	subi.w	#$7D0,Xvel(a3)
	bpl.w	.y
	clr.w	Xvel(a3)
.y
	tst.w	Yvel(a3)
	bpl.w	.yp
	addi.w	#$7D0,Yvel(a3)
	bmi.w	.ex
	clr.w	Yvel(a3)
.yp
	subi.w	#$7D0,Yvel(a3)
	bpl.w	.ex
	clr.w	Yvel(a3)
.ex
	rts
checkcornercoll94	;210 = blue line to the end of the rink, corner radius 64. Corner circles and side walls
	;for object a3 at d2 / d3 (wcradiusx / wcradiusy); a hit goes to Called from
	;wallcollduringcheck.
	bclr	#pf3wall,pflags3(a3)	;clear the wall collision bit
	move.w	#$88,d4	;sideline
	sub.w	(wcradiusx).w,d4	;BD22 = wcradiusx
	move.w	#$12A,d5	;ywall
	sub.w	(wcradiusy).w,d5	;BD24 = wcradiusy
	movem.w	d2-d5,-(sp)
	neg.w	d4
	neg.w	d5
	addi.w	#$40,d4	;'@'   ; radius
	addi.w	#$40,d5
	cmp.w	d5,d3
	bgt.w	.ctc
	cmp.w	d4,d2
	blt.w	.circle
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.circle
	bra.w	.exit
.ctc
	neg.w	d5
	cmp.w	d5,d3
	blt.w	.exit
	cmp.w	d4,d2
	blt.w	.circle
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.circle
	bra.w	.exit
.circle
	sub.w	d4,d2
	sub.w	d5,d3
	move.w	d3,d0	;cos0 = dy/r
	move.w	d2,d1	;sin0 = -dx/r
	neg.w	d1
	muls.w	d3,d3
	muls.w	d2,d2
	add.l	d2,d3	;dist from dot
	cmp.l	#$1000,d3	;.radius^2 = $1000
	bls.w	.exit
	exg	d0,d3
	jsr	(sroot).l
	exg	d0,d3
	ext.l	d0
	asl.l	#8,d0
	divs.w	d3,d0
	ext.l	d1
	asl.l	#8,d1
	divs.w	d3,d1
	bsr.w	cornercollb94
.exit
	movem.w	(sp)+,d2-d5
	move.w	$4E(a3),d0	;wallcos(a3)
	or.w	$50(a3),d0	;wallsin(a3)
	bne.w	.rtss3
	move.w	#$100,d0	;now check side walls
	clr.w	d1
	cmp.w	d5,d3
	bge.w	cornercollb94
	neg.w	d5
	neg.w	d0
	cmp.w	d5,d3
	ble.w	cornercollb94
	exg	d0,d1
	cmp.w	d4,d2
	bge.w	cornercollb94
	neg.w	d4
	neg.w	d1
	cmp.w	d4,d2
	ble.w	cornercollb94
.rtss3	;branches to the shared rtss here
	rts
cornercollb94	;Thunk: jmp wallcollb
	jmp	wallcollb
Create_HotCold_Table	;Fill the hot / cold table at $1A2 of team struct a0 with 416 random values (-9 ... 8
	;randomd0s). Called from StartGame and ScoutingReport
	movem.l	d0-d7,-(sp)
	move.w	#$19F,d1	;$19F = 415. Loop will run 416 times.
	;(26 players/team * 8) * 2 teams = 416
HotColdLoop	;The Create_HotCold_Table loop
	move.w	#9,d0	;sets RNG limit (-9 - +8)
	jsr	(randomd0s).l
	move.l	a0,-(sp)
	adda.l	#$1A2,a0	;offset to Hot/Cold table
	move.b	d0,0(a0,d1.w)
	movea.l	(sp)+,a0
	dbf	d1,HotColdLoop
	movem.l	(sp)+,d0-d7
	rts
Clamp0to100	;unused: clamp d3 to 0 ... 100
	tst.w	d3
	bpl.w	.chkmax
	clr.w	d3
	rts
.chkmax
	cmp.w	#$64,d3
	ble.w	.x
	move.w	#$64,d3
.x
	rts
AttributeCalc	;Attribute d3 of player a3 * 5 plus his hot / cold value / 3, limited to 0 ... $1E. Called from setplayer
	movem.l	d0-d2/a1,-(sp)
	move.w	(TempWord2).w,d1	;BF14 goes to d1
	movea.l	#tmstruct,a1	;Start of Home Team struct
	btst	#6,pflags(a3)	;Check if home or away
	beq.w	.attribmath
.away
	;shift to start of Away Team struct
	adda.l	#$364,a1
.attribmath
	clr.w	d1
	move.b	pnum(a3),d1	;move roster offset into d1
	asl.w	#4,d1	;shifts d1 4 bits left, moving the values over 1 nibble
	adda.l	#$1A2,a1	;a1 points to Hot/Cold Table Start
	move.b	0(a1,d1.w),d1	;move data at add. (a1 + d1) into d1
	ext.w	d1	;sign-extend word. Ex: F5 (-5) -> FFF5
	ext.l	d1	;sign-extend long word. Ex: FFF5 -> FFFFFFF5
	divs.w	#3,d1	;Signed-Div D1 by 3 (FFFFFFF5 / 3, or -5 / 3 = -1r2, or FFFEFFFF
	;Remainder is 4 MS Nibbles, result is 4 LS Nibbles)
	move.w	d3,-(sp)	;push d3 onto stack
	asl.w	#2,d3	;shift left 2 bits (mult. by 4)
	add.w	(sp)+,d3	;Pop off d3 value and add to d3 (attrib X 5)
	add.w	d1,d3	;add d1 (H/C value) to d3
	bmi.w	.LowerLimit
.UpperLimitCheck
	;check if above upper limit (1E or 30 decimal)
	cmp.w	#$1E,d3
	blt.w	.MaskAttribMathResult
.UpperLimit
	;if above, set to 1E
	move.w	#$1E,d3
	bra.w	.MaskAttribMathResult
.LowerLimit
	clr.w	d3	;if below lower limit (0), set to 0
.MaskAttribMathResult
	andi.w	#$FF,d3	;pass only lower byte
	movem.l	(sp)+,d0-d2/a1
	rts
NextHomeHotPlayer	;d1 = the next home hot player (homehotidx index into the list at homehotplayer), a1 = HmShots. Called from ScoutTextPlayer (the MATCHUPS text)
	movem.l	d0/a0,-(sp)
	movea.l	#homehotplayer,a0
	move.w	(homehotidx).w,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),d1
	cmpi.w	#0,(homehotidx).w
	bge.w	.x
	addq.w	#1,(homehotidx).w
.x
	movem.l	(sp)+,d0/a0
	movea.l	#tmstruct,a1
	rts
NextAwayHotPlayer	;The same for the away team (awayhotplayer, awayhotidx), a1 = AwShots. Called from ScoutTextPlayer
	movem.l	d0/a0,-(sp)
	movea.l	#awayhotplayer,a0
	move.w	(awayhotidx).w,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),d1
	cmpi.w	#0,(awayhotidx).w
	bge.w	.x
	addq.w	#1,(awayhotidx).w
.x
	movem.l	(sp)+,d0/a0
	movea.l	#AwShots,a1
	rts
	rts	;unreferenced
BuildHotColdLists	;Build the hot / cold player lists of both teams (SortHotColdStarters, CopyHottestPlayer, CopyColdestPlayer). Called from ScoutingReport
	clr.w	(awayhotidx).w
	clr.w	(homehotidx).w
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#tmstruct,a0
	bsr.w	SortHotColdStarters
	movea.l	#homehotplayer,a0
	bsr.w	CopyHottestPlayer
	movea.l	#homecoldplayer,a0
	bsr.w	CopyColdestPlayer
	movea.l	#AwShots,a0
	bsr.w	SortHotColdStarters
	movea.l	#awayhotplayer,a0
	bsr.w	CopyHottestPlayer
	movea.l	#awaycoldplayer,a0
	bsr.w	CopyColdestPlayer
	movem.l	(sp)+,d0-d7/a0-a6
	rts
SortHotColdStarters	;Sum the hot / cold values of the 6 starters of team a0 into TempBuffer (byte pairs: player, sum), then sort them by sum
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	a0,a2
	adda.l	#$1A2,a2
	movea.l	$1E(a0),a0
	adda.w	6(a0),a0
	movea.l	#TempBuffer,a1
	move.w	#5,d0
.player
	move.b	(a0)+,d1
	subq.b	#1,d1
	move.b	d1,(a1)+
	ext.w	d1
	asl.w	#4,d1
	clr.b	(a1)
	addq.w	#3,d1
	move.w	#3,d7
.attrib
	clr.w	d2
	move.b	0(a2,d1.w),d2
	cmp.b	#9,d7
	beq.w	.nextattr
	cmp.b	#$D,d7
	beq.w	.nextattr
	add.b	d2,(a1)
.nextattr
	addq.w	#1,d1
	addq.w	#1,d7
	cmp.b	#$10,d7
	bne.s	.attrib
	tst.b	(a1)+
	dbf	d0,.player
.sort
	movea.l	#TempBuffer,a1
	clr.w	d1
	move.w	#4,d0
.cmp
	move.b	3(a1),d6
	cmp.b	1(a1),d6
	ble.w	.next
	st	d1
	move.w	2(a1),d2
	move.w	(a1),2(a1)
	move.w	d2,(a1)
.next
	tst.w	(a1)+
	dbf	d0,.cmp
	tst.w	d1
	bne.s	.sort
	movem.l	(sp)+,d0-d7/a0-a6
	rts
NextHomeColdPlayer	;d1 = the next home cold player (homecoldidx, homecoldplayer), a1 = HmShots. Called from ScoutTextPlayer
	movem.l	d0/a0,-(sp)
	movea.l	#homecoldplayer,a0
	move.w	(homecoldidx).w,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),d1
	cmpi.w	#0,(homecoldidx).w
	bge.w	.x
	addq.w	#1,(homecoldidx).w
.x
	movem.l	(sp)+,d0/a0
	movea.l	#tmstruct,a1
	rts
NextAwayColdPlayer	;The same for the away team (awaycoldidx, awaycoldplayer), a1 = AwShots. Called from ScoutTextPlayer
	movem.l	d0/a0,-(sp)
	movea.l	#awaycoldplayer,a0
	move.w	(awaycoldidx).w,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),d1
	cmpi.w	#0,(awaycoldidx).w
	bge.w	.x
	addq.w	#1,(awaycoldidx).w
.x
	movem.l	(sp)+,d0/a0
	movea.l	#AwShots,a1
	rts
	rts	;unreferenced
CopyHottestPlayer	;Copy the hottest player of TempBuffer to the list at a0
	movem.l	d0-d1/a0-a1,-(sp)
	movea.l	#TempBuffer,a1
	move.w	#0,d0
.copy
	clr.b	(a0)+
	move.b	(a1),d1
	move.b	d1,(a0)+
	tst.w	(a1)+
	dbf	d0,.copy
	movem.l	(sp)+,d0-d1/a0-a1
	rts
CopyColdestPlayer	;Copy the coldest player (TempBuffer+10) to the list at a0
	movem.l	d0/a0-a1,-(sp)
	movea.l	#TempBuffer+10,a1
	move.w	#0,d0
.copy
	clr.b	(a0)+
	move.b	(a1),(a0)+
	tst.w	-(a1)
	dbf	d0,.copy
	movem.l	(sp)+,d0/a0-a1
	rts
CompareHotColdTotals	;Compare the teams' hot / cold totals (GetHotColdTotal into TempWord1 / TempWord2): awayhotter = 1 when the away total is
	;higher; d0 = -1, $22 or $23 by the difference (ScoutingReport text "Lately ... has been playing (extremely) well")
	movem.l	d1-d7/a0-a6,-(sp)
	movea.l	#tmstruct,a0
	bsr.w	GetHotColdTotal
	move.w	d1,(TempWord1).w
	movea.l	#AwShots,a0
	bsr.w	GetHotColdTotal
	move.w	d1,(TempWord2).w
	move.w	(TempWord1).w,d1
	move.w	(TempWord2).w,d2
	sub.w	d1,d2
	move.w	#0,(awayhotter).w
	tst.w	d2
	bmi.w	.abs
	move.w	#1,(awayhotter).w
.abs
	tst.w	d2
	bpl.w	.level
	neg.w	d2
.level
	move.w	#$FFFF,d0
	cmp.w	#$5E,d2
	blt.w	.x
	move.w	#$22,d0
	cmp.w	#$BD,d2
	blt.w	.x
	move.w	#$23,d0
.x
	movem.l	(sp)+,d1-d7/a0-a6
	rts
GetHotColdTotal	;d1 = the hot / cold total of the starters of team a0 (SortHotColdStarters)
	bsr.w	SortHotColdStarters
	move.w	#6,d0
	movea.l	#TempBuffer,a0
	clr.w	d1
.sum
	move.b	1(a0),d2
	ext.w	d2
	add.w	d2,d1
	tst.w	(a0)+
	dbf	d0,.sum
	rts
