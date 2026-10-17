;	Controller input for skaters. This file moves the player under control and lets him pass,
;	shoot and check. It also reads the pads at faceoffs and line changes and decides when a
;	player should head to the bench.


doinput	;process controller input: d0 = dpad, d1 = new buttons, d2 = changed buttons, d3 = held buttons,
	;d4 = controller 0/2
	btst	#4,d1	;B button
	beq.w	.1	;branch if not pressed
	btst	#5,d1	;C button
	beq.w	.1	;branch if not pressed
	bclr	#4,d1
	bset	#6,pflags3(a3)
	bra.w	.5
.1
	btst	#4,d1
	beq.w	.2
	bclr	#6,pflags3(a3)
.2
	btst	#4,d2
	beq.w	.5
	bclr	#6,pflags3(a3)
	beq.w	.5
	tst.w	d4
	bne.w	.3
	move.b	#$11,(bholdtimer).w
	bra.w	.4
.3
	move.b	#$11,(bholdtimer+1).w
.4
	bclr	#4,d2
.5
	btst	#7,(gmode2).w
	beq.w	.6
	cmp.b	#8,d0
	beq.w	.6
	jsr	(ShortenMsgTimer).l
.6
	move.w	d0,(TempWord1).w
	andi.w	#$F,(TempWord1).w
	bsr.w	setpads
	btst	#7,d1	;start button
	beq.w	.nostart	;branch if no start button pressed
	tst.w	(joypuckcarrier).w
	bpl.w	.7
	tst.w	d4
	beq.w	startpause1
	bra.w	startpause2
.7
	btst	#7,d1
	beq.w	.nostart
	tst.w	(joypuckcarrier).w
	beq.w	startpause3
	bra.w	startpause4
.nostart
	btst	#sfhor,(sflags).w
	beq.w	.nhor
	btst	#3,d0
	bne.w	.nhor
	addq.w	#2,d0
	andi.w	#7,d0
.nhor
	btst	#sf2faceoff,(sflags2).w
	bne.w	faceoffinput
	btst	#3,pflags2(a3)
	bne.w	lineinput
	btst	#pfjoycon,pflags(a3)
	beq.w	rtss15
	movem.l	d0-d2/a0/a3,-(sp)
	move.w	(lastplayer).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.noot
	tst.w	(passplayer).w
	bmi.w	.noot
	tst.w	(onetimerplayer).w
	bpl.w	.noot
	btst	#5,d1
	beq.w	.noot
	move.w	(passplayer).w,d0
	asl.w	#7,d0
	movea.l	#SortCords,a3
	adda.w	d0,a3
	tst.w	position(a3)
	beq.w	.noot
	jsr	(PuckOnAttackHalf).l
	beq.w	.noot
	btst	#3,pflags(a3)
	bne.w	.noot
	btst	#pf3onetimer,pflags3(a3)
	bne.w	.noot
	move.w	d4,(inputjoy).w
	move.w	(joypuckcarrier).w,(TmpJoyPuckCarrier).w
	move.w	#$23,d0	;'#'   ; assonetimer
	jsr	(assreplace).l
	movem.l	(sp)+,d0-d2/a0/a3
	rts
.noot
	movem.l	(sp)+,d0-d2/a0/a3
	btst	#pf3onetimer,pflags3(a3)
	bne.w	.chkfight
	btst	#5,pflags(a3)
	bne.w	doinput_islocked
.chkfight
	btst	#0,pflags2(a3)	;fighting in progress
	bne.w	fightinput
	move.w	(puckc).w,d5
	cmp.w	SCnum(a3),d5
	beq.w	doinput_ispc
	tst.w	position(a3)
	beq.w	.11
	btst	#pf3onetimer,pflags3(a3)
	beq.w	.10
	bra.w	.11
.10
	btst	#6,d1
	bne.w	holdplayer
.11
	tst.w	position(a3)
	beq.w	.12
	btst	#2,(BA_PS_flags).w
	bne.w	.noswitch
	bra.w	.bhold
.12
	btst	#6,(sflags5).w
	bne.w	.bhold
	tst.w	d4
	beq.w	.13
	tst.w	(goaliemode2).w
	bra.w	.14
.13
	tst.w	(goaliemode1).w
.14
	beq.w	.bhold
	movem.w	d0,-(sp)
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	movem.w	(sp)+,d0
	beq.w	.bhold
	bra.w	changeplayer
.bhold
	btst	#4,d3
	beq.w	.bpress
	tst.w	(holdreset).w
	bne.w	.bpress
	tst.w	d4
	beq.w	.c1
	tst.b	(bholdtimer+1).w
	beq.w	.noswitch
	subq.b	#1,(bholdtimer+1).w
	bpl.w	.16
	move.b	#0,(bholdtimer+1).w
.16
	tst.b	(bholdtimer+1).w
	bne.w	.bpress
	tst.w	d4
	beq.w	.17
	tst.w	(goaliemode2).w
	bra.w	.18
.17
	tst.w	(goaliemode1).w
.18
	bne.w	.bpress
	bra.w	.goalie
.c1
	tst.b	(bholdtimer).w
	beq.w	.noswitch
	subq.b	#1,(bholdtimer).w
	bpl.w	.20
	move.b	#0,(bholdtimer).w
.20
	tst.w	d4
	beq.w	.21
	tst.w	(goaliemode2).w
	bra.w	.22
.21
	tst.w	(goaliemode1).w
.22
	bne.w	.bpress
	tst.b	(bholdtimer).w
	beq.w	.goalie
.bpress
	btst	#4,d1
	beq.w	.brel
	tst.w	d4
	bne.w	.24
	move.b	#$11,(bholdtimer).w
	bra.w	.noswitch
.24
	move.b	#$11,(bholdtimer+1).w
	bra.w	.noswitch
.brel
	btst	#4,d2
	beq.w	.noswitch
	btst	#4,d3
	bne.w	.noswitch
	move.w	(bholdtimer).w,d0
	tst.w	d4
	beq.w	.28
	move.b	#$11,(bholdtimer+1).w
	andi.w	#$FF,d0
	bne.w	changeplayer
	tst.w	d4
	beq.w	.26
	tst.w	(goaliemode2).w
	bra.w	.27
.26
	tst.w	(goaliemode1).w
.27
	bne.w	changeplayer
	bra.w	.goalie
.28
	move.b	#$11,(bholdtimer).w
	andi.w	#$FF00,d0
	bne.w	changeplayer
	tst.w	d4
	beq.w	.29
	tst.w	(goaliemode2).w
	bra.w	.30
.29
	tst.w	(goaliemode1).w
.30
	bne.w	changeplayer
.goalie
	tst.w	(holdreset).w
	bne.w	changeplayer
	move.w	#5,d0
	cmp.w	#5,d6
	ble.w	.32
	move.w	#$B,d0
.32
	jsr	(getGoalieSCnum).l
	tst.w	d0
	bmi.w	rtss15
	movem.l	d0/a3,-(sp)
	movea.l	#SortCords,a3
	asl.w	#7,d0
	adda.w	d0,a3
	btst	#3,pflags(a3)
	movem.l	(sp)+,d0/a3
	bne.w	rtss15
	tst.w	d4
	beq.w	setc1player
	bra.w	setc2player
.noswitch
	tst.w	position(a3)
	bne.w	doinput_onetimer
	btst	#6,d1
	beq.w	doinput_cbut
	move.w	(TempWord1).w,d0
	cmp.b	#8,d0
	beq.w	doinput_cbut
	move.w	d0,facedir(a3)
	move.b	#8,nopuck(a3)
	move.w	#SPAgdive,d1	;goalie dive animation
	bsr.w	SetSPA
	bset	#1,pflags2(a3)
	bset	#5,pflags(a3)
	addi.w	#$96,(crowdlevel).w
rtss15
	rts
doinput_cbut	;C button (bit 5): hold / release handling for a3, then doinput_chkanim
	btst	#5,d1
	bne.w	.press
	btst	#5,d3
	bne.w	.held
	bclr	#7,pflags2(a3)
	bra.w	doinput_chkanim
.held
	btst	#7,pflags2(a3)
	beq.w	doinput_chkanim
	movem.l	d0-d3/a0-a3,-(sp)
	movea.l	#SPAlist,a0
	adda.w	SPA(a3),a0
	move.w	facedir(a3),d0
	btst	#3,4(a3)
	beq.w	.1
	neg.w	d0
	addq.w	#8,d0
	andi.w	#7,d0
.1
	asl.w	#1,d0
	adda.w	0(a0,d0.w),a0
	tst.b	$5B(a3)
	movem.l	(sp)+,d0-d3/a0-a3
	bpl.s	rtss15
	move.w	#$A,SPAcnt(a3)
	rts
.press
	btst	#5,pflags(a3)
	bne.w	doinput_chkanim
	movem.w	d0-d1,-(sp)
	move.w	(puckx).w,d0
	sub.w	(a3),d0
	move.w	(pucky).w,d1
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	move.w	d0,facedir(a3)
	movem.w	(sp)+,d0-d1
	move.w	(TempWord1).w,d0
	bclr	#0,(BA_PS_flags).w
	move.w	(gameclock).w,d0
	andi.w	#7,d0
	asl.w	#4,d0
	addi.w	#$A0,d0
	cmpi.w	#$DB,(pucky).w
	bgt.w	.3
	cmpi.w	#$FF25,(pucky).w
	bgt.w	.4
.3
	subi.w	#$40,d0
.4
	move.w	d0,d1
	muls.w	(puckvx).w,d0
	swap	d0
	add.w	(puckx).w,d0
	muls.w	(puckvy).w,d1
	swap	d1
	add.w	(pucky).w,d1
	bsr.w	ClampTargetY
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#$384,d0
	bhi.w	.far
	movem.w	(sp)+,d0-d1
	bra.w	.near
.far
	bsr.w	sroot
	moveq	#1,d2
	add.w	d0,d2
	moveq	#$12,d4
	btst	#3,(sflags).w
	beq.w	.6
	addq.w	#8,d4
.6
	movem.w	(sp)+,d0-d1
	muls.w	d4,d1
	addq.w	#8,d4
	muls.w	d4,d0
	divs.w	d2,d0
	divs.w	d2,d1
.near
	add.w	d3,d1
	move.w	d1,d2
	cmpi.w	#$22,2(a0)
	cmpi.w	#$18,(a0)
	cmpi.w	#$FFE8,(a0)
	cmpi.w	#$C,2(a0)
	cmpi.w	#$108,(pucky).w
	cmpi.w	#$FEF8,(pucky).w
	bset	#1,pflags2(a3)
	bne.w	doinput_chkanim
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#puckcross,a0
	move.w	#$108,d3
	btst	#7,pflags(a3)	;check which net shooting on
	beq.w	.save	;branch if bottom net
	neg.w	d3	;negate d3 (-108 hex)
	addq.w	#4,a0	;puckcross+4 (for bottom goalie)
.save
	jsr	(goaliesave).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ClampTargetY	;clamp the target y d1 for player a3 (d0 cleared when a3 has the puck)
	move.w	(puckc).w,d2
	cmp.w	SCnum(a3),d2
	bne.w	.0
	clr.w	d0
.0
	cmp.w	#$103,d1
	blt.w	.1
	move.w	#$103,d1
.1
	cmp.w	#$FEFD,d1
	bgt.w	.2
	move.w	#$FEFD,d1
.2
	sub.w	d3,d1
	rts
	;10 SPA offsets, unreferenced: SPAgglover, SPAgglovel, SPAgstackr, SPAgstackl
	;SPAgstickr, SPAgstickl, then the newer tables SPAghighr, SPAghighl, SPAgstick2r, SPAgstick2l
	dc.w	SPAgglover,SPAgglovel,SPAgstackr,SPAgstackl,SPAgstickr,SPAgstickl,SPAghighr,SPAghighl,SPAgstick2r,SPAgstick2l
doinput_chkanim	;Nothing while a3's animation runs (pflags2 bit 1); else skate a3 (doplayeracc)
	btst	#1,pflags2(a3)
	beq.w	.0
	rts
.0
	tst.w	position(a3)
	bne.w	doplayeracc
	bclr	#1,(BA_PS_flags).w
	cmpi.w	#$24,(a3)
	ble.w	.1
	tst.w	Xvel(a3)
	bmi.w	.1
	beq.w	.1
	bset	#1,(BA_PS_flags).w
	clr.w	Xvel(a3)
.1
	cmpi.w	#$FFDC,(a3)
	bge.w	.2
	tst.w	Xvel(a3)
	bpl.w	.2
	bset	#1,(BA_PS_flags).w
	clr.w	Xvel(a3)
.2
	cmpi.w	#$E7,Ypos(a3)
	bgt.w	.4
	cmpi.w	#$FF19,Ypos(a3)
	ble.w	.4
	bra.w	*+4
.3
	movem.w	d0-d1,-(sp)
	move.w	Ypos(a3),d0
	move.w	Yvel(a3),d1
	eor.w	d1,d0
	movem.w	(sp)+,d0-d1
	bpl.w	.4
	tst.w	Yvel(a3)
	beq.w	.4
	bset	#1,(BA_PS_flags).w
	clr.w	Yvel(a3)
.4
	btst	#1,(BA_PS_flags).w
	bne.w	rtss15
	move.w	(TempWord1).w,d0
	bra.w	doplayeracc
doinput_onetimer	;a3 is set for a one-timer: C (bit 5) starts the one-timer shot, else skate
	move.w	(TempWord1).w,d0
	btst	#pf3onetimer,pflags3(a3)
	bne.w	rtss7
	btst	#5,d1
	beq.w	doplayeracc
	movem.l	d7-a0,-(sp)
	move.w	(lastplayer).w,d7
	asl.w	#7,d7
	movea.l	#SortCords,a0
	adda.w	d7,a0
	tst.w	$34(a0)
	movem.l	(sp)+,d7-a0
	beq.w	burst
	movem.w	d7,-(sp)
	move.w	SCnum(a3),d7
	cmp.w	(passplayer).w,d7
	movem.w	(sp)+,d7
	bne.w	burst
	tst.w	(puckc).w
	bpl.w	burst
	jsr	(PuckOnAttackHalf).l
	beq.w	burst
	move.w	d0,-(sp)
	move.w	d4,(inputjoy).w
	move.w	(joypuckcarrier).w,(TmpJoyPuckCarrier).w
	move.w	#$23,d0	;'#'   ; assonetimer
	jsr	(assreplace).l
	move.w	(sp)+,d0
	rts
doinput_ispc	;a3 has the puck: pass mode, shot mode, or start a pass / shot by the buttons
	bsr.w	checkob
	tst.w	position(a3)
	bne.w	.0
	btst	#1,pflags2(a3)
	bne.w	rtss15
.0
	btst	#2,(sflags).w
	bne.w	passmode
	btst	#3,(sflags).w
	bne.w	ShotMode
	btst	#4,d1
	beq.w	.1
	jsr	(CountButtonPress).l
	bra.w	setpassmode
.1
	btst	#6,d1
	beq.w	.ahold
	tst.w	d4
	beq.w	.2
	move.b	#$F,(aholdtimer+1).w
	bra.w	.ahold
.2
	move.b	#$F,(aholdtimer).w
.ahold
	btst	#6,d3
	beq.w	.arel
	tst.w	d4
	beq.w	.c1
	subq.b	#1,(aholdtimer+1).w
	bpl.w	.4
	move.b	#0,(aholdtimer+1).w
.4
	tst.b	(aholdtimer+1).w
	bne.w	.arel
	bset	#3,(sflags5).w
	jsr	(setpassmode).l
	bra.w	SetLCmode
.c1
	subq.b	#1,(aholdtimer).w
	bpl.w	.6
	move.b	#0,(aholdtimer).w
.6
	tst.b	(aholdtimer).w
	bne.w	.arel
	bset	#3,(sflags5).w
	jsr	(setpassmode).l
	bra.w	SetLCmode
.arel
	btst	#6,d3
	bne.w	.8
	btst	#6,d2
	beq.w	.8
	bset	#3,(sflags5).w
	bra.w	setpassmode
.8
	tst.w	position(a3)
	bne.w	.shot
	bra.w	doplayeracc
.shot
	btst	#5,d1
	beq.w	doplayeracc
	jsr	(CountButtonPress).l
	bra.w	SetShotMode
doinput_islocked	;a3 is locked in an animation: B (bit 4) changes the controlled player
	move.w	(puckc).w,d5
	cmp.w	SCnum(a3),d5
	beq.w	rtss15
	btst	#4,d1
	beq.w	rtss7
	btst	#6,(sflags5).w
	bne.w	rtss7
	bsr.w	changeplayer
	movem.l	d0/a0,-(sp)
	move.w	(c1playernum).w,d0
	tst.w	d4
	beq.w	.0
	move.w	(c2playernum).w,d0
.0
	tst.w	d0
	bmi.w	.x
	asl.w	#7,d0
	movea.l	#SortCords,a0
	adda.w	d0,a0
	bset	#6,pflags3(a0)
.x
	movem.l	(sp)+,d0/a0
rtss7
	rts
; Find goalie SCnum, store in d0
; If no goalie, store FFFF in d0
getGoalieSCnum	;d0 = SCnum of the goalie in the 6 sort objects up to object d0, -1 if none
	movem.l	d1/a0,-(sp)
	movea.l	#SortCords,a0
	asl.w	#7,d0
	adda.w	d0,a0
	move.w	#5,d1
.loop
	tst.w	$34(a0)
	beq.w	.goalie
	suba.w	#$80,a0
	dbf	d1,.loop
	move.w	#$FFFF,d0
	bra.w	.end
.goalie
	move.w	$52(a0),d0
.end
	movem.l	(sp)+,d1/a0
	rts
faceoffinput	;controller processing for faceoff
	btst	#6,(sflags5).w
	beq.w	.0
	rts
.0
	;move assnum into d4
	move.w	assnum(a3),d4
	cmpi.b	#$17,$38(a3,d4.w)	;check if afaceoffpl is in asslist at assnum position
	bne.s	rtss7	;exit if this is not a faceoff player
	movea.w	#(fodir1-M68K_RAM),a0	;faceoff direction of puck control variable
	btst	#pfgoal,pflags(a3)	;check which goal shooting on
	beq.w	.2	;branch if bottom goal
	movea.w	#(fodir2-M68K_RAM),a0
.2
	;store dpad for faceoff pull
	move.w	d0,(a0)
	btst	#pf2aip,pflags2(a3)	;check if anim in progress
	bne.s	rtss7	;exit if anim in progress
	btst	#4,d1	;test for b button press
	beq.w	.1	;branch if pressed
	move.w	#SPAfaceoff,d1
	bset	#1,pflags2(a3)	;set anim in progress
	bra.w	SetSPA
.1
	;#SPAfaceoffr anim
	move.w	#SPAfaceoffr,d1
	bra.w	SetSPA
fightinput
	rts	;controller processing for fighting
; initiate line change option if available
SetLCmode
	tst.w	(OptLine).w
	bne.w	rtss7
	btst	#4,(sflags7).w
	bne.w	rtss7
	bsr.w	loadTeamStruct
	bset	#1,tmflags(a2)
	bne.w	rtss7
	btst	#3,(sflags5).w
	bne.w	.0
	bclr	#2,(sflags).w
.0
	bclr	#3,(sflags).w
	bset	#3,pflags2(a3)
SetLCmode2	;a2 = team struct. Draw the line change box
	bsr.w	setlccords
	cmpi.w	#$F,(printy).w
	blt.w	.box
	bset	#sf3llcs,(sflags3).w
	bra.w	.frame
.box
	jsr	(box).l
	bsr.w	setlccords
.frame
	bsr.w	Framer
	subq.w	#2,(printy).w
.0
	addq.w	#1,(printx).w
	moveq	#2,d4
.loop
	move.w	d4,d0
	bsr.w	getlchoice
	tst.w	d0
	bmi.w	.next
	btst	#1,tmflags(a2)
	bne.w	.pr
	cmp.w	$2E(a2),d4
	bne.w	.up
	move.w	tmline(a2),d0
.pr
	movea.w	#(mesarea-M68K_RAM),a1
	move.l	#$44120,(a1)	;String length 4, 'A '
	add.b	d4,2(a1)
	bsr.w	print
	move.w	d0,-(sp)
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
	move.w	(sp)+,d0
	bsr.w	linebar
	subq.w	#5,(printx).w
.up
	subq.w	#1,(printy).w
.next
	dbf	d4,.loop
	movea.l	tmdata(a2),a1
	adda.w	4(a1),a1
	adda.w	(a1),a1
	addq.w	#2,(printx).w
	bra.w	print
setlccords	;set printx/y to cords for lc box on team a2
	clr.w	d0
	cmpa.w	#$C6CE,a2
	bne.w	.0
	eori.w	#$16,d0
.0
	btst	#gmdir,(gmode).w
	beq.w	.noflip
	eori.w	#$16,d0
.noflip
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$16,0,0
	add.w	d0,(printy).w
	moveq	#2,d0
	bsr.w	getlchoice
	moveq	#6,d1
	tst.w	d0
	bpl.w	.ex
	subq.w	#1,d1
	addq.w	#1,(printy).w
.ex
	moveq	#9,d0
	rts
getlchoice	;d0 = 0-2 (a2 = team)
	movem.l	d1-d2,-(sp)
	move.w	tmsize+tmap(a2),d2
	cmpa.w	#$C6CE,a2
	beq.w	getlchoice2
	move.w	tmap-tmsize(a2),d2
getlchoice2	;add $15 to d0 for each player more or fewer than the other team has on the ice
	sub.w	$24(a2),d2
	beq.w	.0
	addi.w	#$15,d0
	tst.w	d2
	bmi.w	.0
	addi.w	#$15,d0
.0
	move.w	$16(a2),d1
	add.w	d1,d0
	add.w	d1,d0
	add.w	d1,d0
	lea	.tab(pc),a0
	move.b	0(a0,d0.w),d0
	ext.w	d0
	movem.l	(sp)+,d1-d2
	rts
.tab	dc.b	0
	dc.b	1,2,1,2,0,2,0,1,0,1,2,0,1,2,0,1
	dc.b	2,0,1,2,3,4,$FF,3,4,$FF,3,4,$FF,3,4,$FF
	dc.b	4,3,$FF,3,4,$FF,3,4,$FF,5,6,$FF,5,6,$FF,5
	dc.b	6,$FF,5,6,$FF,5,6,$FF,5,6,$FF,6,5,$FF,$FF
; process input for line changes
; d1 = new button presses
lineinput
	btst	#3,(sflags5).w
	beq.w	.0
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(passmode).l
	movem.l	(sp)+,d0-d7/a0-a6
.0
	move.w	d1,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#pfteam,pflags(a3)
	beq.w	.2
	adda.w	#tmsize,a2
.2
	bclr	#0,tmflags(a2)
	beq.w	.1
	bsr.w	lcfound2
	bsr.w	SetLCmode2
.1
	move.w	(sp)+,d1
	clr.w	d2
	btst	#6,d1
	bne.w	lcfound
	addq.w	#1,d2
	btst	#4,d1
	bne.w	lcfound
	addq.w	#1,d2
	btst	#5,d1
	bne.w	lcfound
	btst	#pfjoycon,pflags(a3)
	beq.w	.x
	btst	#pfalock,pflags(a3)
	bne.w	.x
	btst	#pf2fight,pflags2(a3)
	beq.w	doplayeracc
.x
	rts
; d2 = choice made 0-2
lcfound
	move.w	d2,d0
	move.w	d2,$2E(a2)
	bsr.w	getlchoice	;translate choice 0-2 into line number 0-6
	tst.w	d0
	bmi.w	rtss8
	bclr	#3,pflags2(a3)
	bset	#pfjoycon,pflags(a3)
	bsr.w	loadTeamStruct
	bclr	#1,tmflags(a2)
	move.w	d0,tmline(a2)
	jsr	(setpersonel).l
lcfound2	;close lc box
	btst	#7,(sflags).w
	bne.w	rtss
	bsr.w	setlccords
	cmpi.w	#$F,(printy).w
	blt.w	.nollcm
	bclr	#sf3llcs,(sflags3).w
.nollcm
	addq.w	#1,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	bra.w	printscores1
; c button press check/speed
burst
	jsr	(getpde).l	;get players energy
	tst.w	(OptLine).w
	bne.w	.0
	subi.w	#$CC,d0
	jsr	(setpde).l	;decrease players energy
	btst	#4,(sflags7).w
	beq.w	.0
	move.w	#$1000,d0
.0
	lsr.w	#7,d0	;d0 will be $1000 with lines off
	;d0 / 64 will be 20 hex if max energy
	move.w	d0,d1	;energy = speed increase (check violence)
	move.w	facedir(a3),d2	;facedir
	asl.w	#2,d2
	movea.l	#dirtab,a0
	muls.w	0(a0,d2.w),d0
	muls.w	2(a0,d2.w),d1
	add.w	d0,Xvel(a3)	;add to X Vel
	add.w	d1,Yvel(a3)	;add to Y Vel
	bset	#pfalock,pflags(a3)	;lock in this animation
	move.w	#SPAburst,d1
	bra.w	SetSPA
; A button press hold
; CPU hold jumps in at Acheck
;
; a3 = holder
; a0 = player being held
holdplayer
	bset	#5,pflags(a3)	;lock animation
	move.w	#SPAhook,d1	;move anim into d1 - normal hold check
	tst.w	impact(a3)	;check if impact = 0
	beq.w	SetSPA	;set anim if 0
	movea.w	#(SortCords-M68K_RAM),a0	;move SortCord into a0
	move.w	impactp(a3),d0	;move last impact player into d0
	asl.w	#7,d0	;calc offset
	adda.w	d0,a0	;add offset to a0
Acheck	;start SPAhook, or SPAHold if a0 is ahead
	bset	#pfalock,pflags(a3)	;lock animation
	move.w	#SPAhook,d1	;move anim into d1 - normal hold check
	tst.w	impact(a3)	;check if impact = 0
	beq.w	.ex	;branch if 0
	move.w	Ypos(a3),d0	;move Ypos checker into d0
	sub.w	Ypos(a0),d0	;sub Ypos of player
	btst	#pfgoal,pflags(a3)	;check goal checker is shooting at
	beq.w	.air	;jump if bottom
	neg.w	d0	;make d0 negative
.air
	bmi.w	.ex
	move.w	#SPAHold,d1	;set anim - hold check stick in air
.ex
	bra.w	SetSPA
; initialize pass mode
setpassmode
	move.w	facedir(a3),(passdir).w	;facedir, default pass direction
	andi.w	#7,(passdir).w	;Passes first 3 bits of passdir
	btst	#2,(BA_PS_flags).w
	beq.w	.0
	bclr	#2,(gmode2).w
	bset	#5,(BA_PS_flags).w
	bne.w	rtss7
	bclr	#5,(gmode2).w
	move.w	#$64,(passmodetimer).w
.0
	bset	#2,(sflags).w	;#sfspdir - set pass dir mode
rtss
	rts
; start passing sequence
passmode
	btst	#4,d2	;has b button changed?
	bne.w	dopass	;yes
	btst	#3,(sflags5).w	;Not in NHL Hockey Source
	bne.w	dopass
	btst	#3,d0	;look for dpad
	bne.s	rtss
	andi.w	#7,d0	;pass first 3 bits of d0
	move.w	d0,(passdir).w	;new pass dir
	bset	#3,d0
dopass	;pass the puck in passdir, to the best teammate there if any
	movem.l	d0-d5/a0-a1,-(sp)
	bclr	#sfspdir,(sflags).w	;#sfspdir
	st	(puckc).w	;player is not puck handler anymore
	move.b	#$10,nopuck(a3)	;$5E = nopuck
	move.w	SCnum(a3),(lastplayer).w	;$52 = offset of player on ice
	bclr	#3,(sflags5).w	;Not in NHL Hockey Source
	beq.w	.noot
	jsr	(OneTimerTarget).l
	move.w	#$12,(onetimerheight).w
	btst	#2,(sflags6).w
	beq.w	.1
	move.w	#$3A,(onetimerheight).w
.1
	jsr	(OneTimerPass).l
	bra.w	.exit
.noot
	moveq	#8,d0	;moves 8 into d0
	tst.w	position(a3)	;checks if goalie
	beq.w	.calc	;jump if goalie
.LoadPassAttribForPassStart
	;Passacc
	move.b	passacc(a3),d0
.calc
	asl.w	#2,d0	;d0 = passacc for player, 8 for goalie
	asr.w	#1,d0	;change from NHL Hockey Source,
	;because max passacc can be 30
	;(15 in 92)
	addi.w	#$A0,d0
	move.w	d0,(passspeed).w	;Passspeed = PassAcc (0 to 30 decimal) * 2 + A0 (160 decimal)
	btst	#0,passacc(a3)	;Checks to see if bit 0 in Passacc is 0
	beq.w	.findplayer	;Jumps if 0 (even number)
	asr.w	#4,d0	;divide d0 by 16
	add.w	d0,(passspeed).w	;add d0 to passspeed
.findplayer
	moveq	#-1,d4	;look for closest and best player to pass to
	moveq	#5,d3	;Set total number of players (6 total, set to 5)
	movea.w	#(SortCords-M68K_RAM),a1	;B04A - Start of Home Players on Ice Arrays
	cmpi.w	#6,SCnum(a3)	;compares 6 to offset 52 from a3 (current player with puck) to check if player is away team or home team
	blt.w	.0	;Jump if player is Home, continue if Away
	adda.w	#6*SCstruct,a1	;Switch to Away Team Players
	btst	#2,(BA_PS_flags).w
	bne.w	.nopp
.0
	cmpa.l	a1,a3	;Check to see if passing to self
	beq.w	.next	;skip if this is passing player
	tst.w	position(a1)	;position(a1)
	beq.w	.next	;skip if goalie
	btst	#2,pflags2(a1)	;check if player is unavailable
	bne.w	.next	;player unavailable
	move.w	(a1),d0	;X Position of receiving player
	sub.w	(puckx).w,d0	;sub puckx from d0
	move.w	Ypos(a1),d1	;Y position of receiving player
	sub.w	(pucky).w,d1	;sub pucky from d1
	movem.w	d0-d1,-(sp)	;push to stack
	bsr.w	vtoa	;get direction of pass in d0
	movem.w	(sp)+,d1-d2	;pop from stack d1 is dX, d2 is dY
	sub.w	(passdir).w,d0	;sub passdir from d0
	andi.w	#7,d0	;pass only lower 3 bits in d0
	asl.b	#5,d0	;Multiply d0 by 32 (224 decimal is max)
	ext.w	d0	;sign extend d0 byte to d0 word
	asl.w	#3,d0	;mult d0 by 8 (700 decimal max)
	muls.w	d0,d0	;square d0 = max is 490000 decimal
	cmp.l	#$10000,d0		;compare to 65536 decimal (#256^2: power, SNASM ^ is xor)
	bhi.w	.next	;if higher branch to next
	muls.w	d1,d1	;square d1 (dX)
	muls.w	d2,d2	;square d2 (dY)
	add.l	d1,d2	;add together
	add.l	d0,d2	;add modified passdir to d2
	cmp.l	d4,d2	;compare d4 to d2
	bhi.w	.next	;branch if higher (player is farther away than the closest player)
	move.l	d2,d4	;move d2 into d4
	movea.l	a1,a0	;move a1 address into a0 (receiving player)
.next
	adda.w	#SCstruct,a1	;Skip to next player (80 hex is length of player struct)
	dbf	d3,.0
	tst.l	d4	;check if there's a player to pass to
	bmi.w	.nopp	;skip if no player to pass to
	bsr.w	passto
	bra.w	.exit
.nopp
	move.w	(passdir).w,d0	;just hit puck in pass dir not to any player
	asl.w	#2,d0
	movea.l	#dirtab,a0
	move.w	2(a0,d0.w),d1	;y inc
	muls.w	(passspeed).w,d1
	moveq	#$A,d2
	asl.l	d2,d1
	divs.w	#runspeed*15,d1
	add.w	Yvel(a3),d1	;Yvel
	move.w	d1,(puckvy).w
	move.w	0(a0,d0.w),d1	;X inc
	muls.w	(passspeed).w,d1
	asl.l	d2,d1
	divs.w	#runspeed*15,d1
	add.w	Xvel(a3),d1	;Xvel
	move.w	d1,(puckvx).w
	move.w	#$1000,d0
	bsr.w	randomd0
	move.w	d0,(puckvz).w
.exit
	tst.w	position(a3)	;$34 = position
	bne.w	.notgoalie
	tst.w	(puckvy).w
	btst	#pfgoal,pflags(a3)	;$62 = pflags Checks for what goal team is shooting at (0=bottom, 1=top)
	beq.w	.g0
	bmi.w	.nvy
	bra.w	.notgoalie
.g0
	bmi.w	.notgoalie
.nvy
	neg.w	(puckvy).w	;negative velocity on puck
.notgoalie
	move.w	(puckvx).w,d0
	move.w	(puckvy).w,d1
	bsr.w	vtoa
	move.w	#SPAgswing,d1	;SPA = Sprite Animation
	tst.w	position(a3)	;$34 = position
	beq.w	.e1	;goalie anim.
	move.w	#SPApassf,d1
	bsr.w	Findhittype
	beq.w	.e1
	move.w	#SPApassb,d1
.e1
	bsr.w	SetSPA
	bset	#pfalock,pflags(a3)	;#pfalock, $62 = pflags
	moveq	#$C,d0	;Rest to rts, not in NHL Hockey Source
	;Used to make puck sound
	sub.b	(puckvz).w,d0
	lsr.w	#2,d0
	andi.w	#3,d0
	addi.w	#$10,d0
	move.w	d0,-(sp)	;#SFXpass
	bsr.w	sfx
	movem.l	(sp)+,d0-d5/a0-a1
	rts
; pass puck to player a0
; a3 = passer
passto
	btst	#3,pflags(a3)
	beq.w	passtoa0
	tst.w	position(a3)
	bne.w	passtoa0
	movem.l	d0-d1,-(sp)
	btst	#3,$62(a0)
	bne.w	.stack
	bset	#6,pflags3(a0)	;pflags3 bit 6
	move.w	(cont1team).w,d1
	cmp.w	(cont2team).w,d1	;checks to see if 2 player co-op (on same team)
	bne.w	.h2hor1p
	move.w	$52(a0),d0	;SCnum of receiver into d0
	move.w	SCnum(a3),d1	;SCnum of passer into d1
	cmp.w	(c1playernum).w,d1	;checks if cont 1 controlling passer
	bne.w	.p2passing
	jsr	(setc1player).l
	bra.w	.stack
.p2passing
	jsr	(setc2player).l
	bra.w	.stack
.h2hor1p
	move.w	#1,d1
	btst	#6,pflags(a3)	;check if home or away team
	beq.w	.0	;branch if home
	move.w	#2,d1	;away team
.0
	move.w	$52(a0),d0	;move SCnum of receiver into d0
	cmp.w	(cont1team).w,d1	;compare cont1 team with d1 (1=home, 2=away)
	bne.w	.diffteam
	jsr	(setc1player).l
	bra.w	.stack
.diffteam
	jsr	(setc2player).l
.stack
	movem.l	(sp)+,d0-d1
passtoa0	;pass puck to player a0
	bsr.w	loadTeamStruct
	addq.w	#1,$12(a2)	;add 1 to total pass attempts
	move.w	SCnum(a0),(passplayer).w	;Moves index number for a0 player
	move.w	(passspeed).w,d5	;passspeed = pix/sec
	asr.w	#2,d5	;divides pass speed by 4
	exg	a0,a3	;tell pass recipient to get puck - swaps a3 and a0 for assinsert
	move.l	#$13,d0	;#apassrec - assignment for receiving pass
	bsr.w	assinsert
	exg	a0,a3
	move.l	a0,-(sp)	;This routine uses passspeed and player's a0 x/y speed to determine the x/y velocity of the puck so it will meet player a0
	bsr.w	GetHot
	add.w	(a0),d0	;Xpos
	sub.w	(puckx).w,d0
	add.w	Ypos(a0),d1	;Ypos
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	movem.w	(sp),d2-d3	;pop d0-d1 off into d2-d3
	asr.w	#2,d2	;d2 divide by 4
	asr.w	#2,d3	;d3 divide by 4
	move.w	Xvel(a0),d0	;Xvel
	muls.w	#$F0,d0	;#(16 * 60)/4 = $F0 xpix / (1/4) sec
	swap	d0	;swap upper and lower bytes
	move.w	Yvel(a0),d1	;Yvel
	muls.w	#$F0,d1
	swap	d1	;swap upper and lower bytes
	movem.w	d0-d1,-(sp)	;push on stack
	muls.w	d2,d0	;d0 = (d2 = Xpos puck / 4) * d0 (x pix per 1/4 sec)
	muls.w	d3,d1	;d1 = (d3 = Ypos puck /4) * d1 (y pix per 1/4 sec)
	add.w	d1,d0	;add d1 to d0
	asl.w	#1,d0	;d0 mult by 2
	move.w	d0,d4	;j = move d0 into d4
	movem.w	(sp),d0-d1	;pop d0 and d1 off stack
	muls.w	d0,d0	;(x pix per 1/4 sec)^2
	muls.w	d1,d1	;(y pix per 1/4 sec)^2
	muls.w	d5,d5	;passspeed^2
	neg.l	d5	;negative d5
	add.l	d0,d5	;add d0 to d5
	add.l	d1,d5	;k = add d1 to d5
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d2,d3	;a^2 = add d2 to d3
	muls.w	d5,d3	;multiply k * a^2
	asl.l	#2,d3	;divide by 4
	move.w	d4,d0	;d0 = j
	muls.w	d0,d0	;j^2
	sub.l	d3,d0	;j^2 - ((k*a^2)/4)
	bsr.w	sroot	;square root of d0
	moveq	#1,d3	;limit infinite loop
	asr.w	#2,d5	;k divide by 4
	bne.w	.0
	moveq	#1,d5	;no div by zero
.0
	move.w	d0,d2
	neg.w	d0
	sub.w	d4,d2
	ext.l	d2
	divs.w	d5,d2
	dbpl	d3,.0
	bne.w	.1
	addq.w	#1,d2	;can't be zero
.1
	cmp.w	#$18,d2	;limit to 3 sec.
	bls.w	.2
	moveq	#$18,d2	;d2 = time in 1/8 sec to intersection
.2
	move.b	d2,(puckvz).w
	cmp.w	#$C,d2
	blt.w	.3
	move.b	#$C,(puckvz).w
.3
	move.w	d2,d0
	asl.w	#3,d0
	subi.w	#$A,d0	;only subtract #6 in NHL Hockey
	move.b	d0,$40(a0)	;$40 = temp1
	subq.w	#6,d0	;sub. #10 in NHL Hockey
	move.b	d0,(puckx_nopuck).w
	movem.w	(sp)+,d0-d1
	muls.w	d2,d0
	asr.l	#1,d0
	add.w	(sp)+,d0	;x distance
	move.w	(puckx).w,temp3(a0)
	add.w	d0,temp3(a0)	;$44 = temp3
	muls.w	d2,d1
	asr.l	#1,d1
	add.w	(sp)+,d1	;y distance
	move.w	(pucky).w,temp4(a0)
	add.w	d1,temp4(a0)	;$46 = temp4
	mulu.w	#$78,d2	;'x'   ; $78 = 60*2
	swap	d0
	divs.w	d2,d0
	move.w	d0,(puckvx).w
	swap	d1
	divs.w	d2,d1
	move.w	d1,(puckvy).w
	rts
; Attributes: thunk
changeplayer
	jmp	chgplayer
	bne.w	.x
	movem.l	d0-d6/a0-a1,-(sp)
	move.w	(puckvx).w,d0
	asr.w	#8,d0
	add.w	(puckx).w,d0
	move.w	(puckvy).w,d1
	asr.w	#8,d1
	add.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	moveq	#5,d2
	move.w	d4,d3
	eori.w	#2,d3
	moveq	#-1,d5
	movea.w	#(SortCords-M68K_RAM),a0
	movea.w	#(cont1team-M68K_RAM),a1
	cmpi.w	#1,0(a1,d4.w)
	beq.w	.t1
	adda.w	#6*SCstruct,a0
.t1
	movea.w	#(c1playernum-M68K_RAM),a1
.loop
	tst.w	position(a0)
	ble.w	.next
	btst	#2,pflags2(a0)
	bne.w	.next
	btst	#3,pflags(a0)
	bne.w	.next
	btst	#2,(BA_PS_flags).w
	beq.w	.0
	movem.l	d0,-(sp)
	move.w	(BA_Sktr_SCnum).w,d0
	cmp.w	$52(a0),d0
	movem.l	(sp)+,d0
	beq.w	.0
	movem.l	d0,-(sp)
	move.w	(BA_Goalie_SCnum).w,d0
	cmp.w	$52(a0),d0
	movem.l	(sp)+,d0
	bne.w	.next
.0
	btst	#5,$62(a0)
	bne.w	.next
	movem.w	(sp),d0-d1
	sub.w	(a0),d0
	muls.w	d0,d0
	sub.w	Ypos(a0),d1
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	d5,d0
	bhi.w	.next
	move.w	SCnum(a0),d1
	cmp.w	0(a1,d3.w),d1
	beq.w	.next
	move.l	d0,d5
	move.w	d1,d6
.next
	adda.w	#SCstruct,a0
	dbf	d2,.loop
	addq.w	#4,sp
	pea	(.ex).l
	cmp.w	0(a1,d4.w),d6
	beq.w	Sweepcheck
	move.w	d6,d0
	tst.w	d4
	beq.w	setc1player
	bra.w	setc2player
.ex
	movem.l	(sp)+,d0-d6/a0-a1
.x
	rts
Sweepcheck	;start sweep check on player a3
	bset	#pfalock,pflags(a3)
	move.w	#SPAsweepchk,d1
	bra.w	SetSPA
; restore old player and switch to new d0 player on cont. 1
setc1player
	cmp.w	(c1playernum).w,d0
	beq.w	.ex
	movem.l	d1/a0-a1,-(sp)
	move.w	(c1playernum).w,d1
	bsr.w	restorepl
	move.w	d0,(c1playernum).w
	movem.l	(sp)+,d1/a0-a1
.ex
	rts
; restore old player and switch to new d0 player on cont. 2
setc2player
	cmp.w	(c2playernum).w,d0
	beq.w	.ex
	movem.l	d1/a0-a1,-(sp)
	move.w	(c2playernum).w,d1
	bsr.w	restorepl
	move.w	d0,(c2playernum).w
	movem.l	(sp)+,d1/a0-a1
.ex
	rts
; d1 = old player
restorepl
	movea.w	#(SortCords-M68K_RAM),a0
	tst.w	d1
	blt.w	.spd
	cmp.w	#$B,d1
	bgt.w	.spd
	asl.w	#7,d1	;multiply d0 by 80 hex (SCsize)
	btst	#3,pflags2(a0,d1.w)	;#pfnp - no joystick pad
	beq.w	.cont
	lsr.w	#7,d1	;divide by 80 hex
	move.w	d1,d0
	rts
.cont
	bclr	#pfjoycon,pflags(a0,d1.w)	;#pfjoycon
	btst	#3,$64(a0,d1.w)	;bit 3, pflags3
	bne.w	.spd
	bset	#pfna,pflags(a0,d1.w)	;#pfna - new assignment
.spd
	tst.w	d0	;checks if d0 0 or higher
	blt.w	.ex
	cmp.w	#$B,d0	;checks if d0 11 or less
	bgt.w	.ex
	move.w	d0,d1	;copies d0 into d1
	asl.w	#7,d1
	btst	#2,(BA_PS_flags).w
	bne.w	.chkgoalie
	btst	#0,(gmode2).w
	beq.w	.3
.chkgoalie	;Local: only restorepl uses it, and a global here would split restorepl
	tst.w	$34(a0,d1.w)
	bne.w	.3
	btst	#6,$62(a0,d1.w)	;check if home or away
	beq.w	.0
	tst.w	(goaliemode2).w
	bra.w	.1
.0
	tst.w	(goaliemode1).w
.1
	beq.w	.3
	move.w	#0,d0	;first position of home SCNum
	btst	#6,$62(a0,d1.w)	;check if home or away
	beq.w	.2
	move.w	#6,d0	;first position of away SCNum
.2
	bra.w	.ex
.3
	bset	#3,$62(a0,d1.w)	;set pfjoycon for SCNum
.ex
	rts
; look for type of swing (forehand or backhand)
; input d0 = launch dir
Findhittype
	neg.w	d0
	add.w	facedir(a3),d0	;facedir
	andi.w	#7,d0
	btst	#3,attribute(a3)	;attribute bit 3
	beq.w	.1
	btst	d0,#$F0			;%11110000: beq forehand, bne backhand. show btst Dn,#imm
	rts
.1	btst	d0,#$1E	;%00011110
	rts
; initiate shot by player a3
SetShotMode
	btst	#2,(BA_PS_flags).w	;check for PS or SO
	beq.w	.start	;branch if not
	bclr	#2,(gmode2).w
	bset	#5,(BA_PS_flags).w
	bne.w	rtss7
	bclr	#5,(gmode2).w
	move.w	#$64,(passmodetimer).w
.start
	move.w	#8,(passdir).w	;default shot direction
	bset	#sfssdir,(sflags).w	;#sfssdir
	clr.w	d0	;find dx/dy for shot
	move.w	#$128,d1	;#296 = top Y boards
	btst	#pfgoal,pflags(a3)	;#pfgoal - which goal to shoot on
	bne.w	.ck0	;branch if top goal
	neg.w	d1	;flip if bottom goal
.ck0
	sub.w	(a3),d0	;Sub Xpos of player from d0. d0 starts as 0 (middle of rink in X)
	sub.w	Ypos(a3),d1	;Sub Ypos of player from Y boards
	bsr.w	vtoa
	move.w	#$F,(passspeed).w
	move.w	#SPAshotf,d1
	bsr.s	Findhittype
	beq.w	.ck1
	move.w	#SPAshotb,d1
	move.w	#$F,(passspeed).w	;minimum shot speed
.ck1
	bra.w	SetSPA
; shot input
ShotMode
	cmpi.w	#$1C,SPAnum(a3)
	bge.w	prepshot	;end of animation so shoot
	btst	#3,d0	;checks dpad for direction
	bne.w	.ss0
	andi.w	#7,d0	;pass the first 3 bits of d0
	move.w	d0,(passdir).w	;set shot direction
.ss0
	cmpi.w	#$10,SPAnum(a3)
	bge.w	.end	;past full windup so no more passspeed
	add.w	d7,(passspeed).w
	cmpi.b	#$14,shotspd(a3)	;6C = shot speed
	bge.w	.checkcbut
	cmpi.w	#8,SPAnum(a3)	;SPANum
	bgt.w	.chganim
.checkcbut
	btst	#5,d2	;5 = #cbut
	beq.w	.end	;button hasnt changed so continue windup
.chganim
	neg.w	SPAnum(a3)	;end windup and swing through
	addi.w	#$1C,SPAnum(a3)	;Add to SPANum
.end
	rts
; Check certain conditions before shooting
prepshot
	bclr	#4,(sflags5).w
	move.w	#$B,d0
	btst	#6,pflags(a3)	;check if home or away
	beq.w	.getGoalie	;gets opponents Goalie SCnum
	move.w	#5,d0	;opponent is home
.getGoalie
	jsr	(getGoalieSCnum).l
	tst.w	d0
	bmi.w	.nogoalie
	movem.l	a0,-(sp)
	asl.w	#7,d0
	movea.l	#SortCords,a0
	cmpi.w	#SPAgstackr,$58(a0,d0.w)	;Checking goalie animations - pad stack right
	beq.w	.svgoalie
	cmpi.w	#SPAgstackl,$58(a0,d0.w)	;Checking another goalie animation - pad stack left
.svgoalie
	movem.l	(sp)+,a0	;pop stack value into a0
	bne.w	.cont
.nogoalie
	cmpi.w	#1,(passdir).w
	ble.w	.dir017	;branch if passdir is 0 or 1
	cmpi.w	#7,(passdir).w
	bne.w	.cont	;branch if passdir is not 7
.dir017
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)	;#pfgoal - goal to shoot at (0=bottom, 1=top)
	bne.w	.cmppuck	;branch if top
	neg.w	d0	;flips d0 for compare calc
.cmppuck
	cmp.w	#$D8,d0	;compares location of puck
	blt.w	.cont
	bset	#4,(sflags5).w	;set flag for in-close top shelf shooting
.cont
	bra.w	*+4
; stick is at puck so launch puck toward goal
; a3 = shooter
doshot
	movem.l	d0-d7/a0-a3,-(sp)
	bclr	#4,(gmode2).w
	btst	#pf3break,pflags3(a3)	;check if player on breakaway
	beq.w	.cont
	bset	#4,(gmode2).w	;set if breakaway
.cont
	bsr.w	shotdiradj
	move.w	#5,-(sp)	;#SFXshotwiff - sound effect
	move.w	SCnum(a3),(shotplayer).w
	bclr	#sfssdir,(sflags).w	;#sfssdir - shot direction mode
	bset	#pfalock,pflags(a3)	;#pfalock
	btst	#pf3onetimer,pflags3(a3)	;check if shooting one timer
	bne.w	.shottype	;jump if yes
	move.w	(puckc).w,d0	;puck carrier SCnum into d0
	cmp.w	SCnum(a3),d0	;is player puck carrier?
	bne.w	.ex	;wiffed shot
.shottype
	move.w	#$18,(sp)	;#SFXshotfh
	bset	#sf2shot,(sflags2).w	;#sf2shot - shot was taken
	cmpi.w	#SPAshotb,SPA(a3)
	bne.w	.nbh	;no backhand
	move.w	#$14,(sp)	;#SFXshotbh
	move.w	(passspeed).w,d0
	lsr.w	#2,d0	;sub 25% for backhand shots
	sub.w	d0,(passspeed).w
.nbh
	btst	#pf3onetimer,pflags3(a3)	;check if shooting one timer
	beq.w	.cont2	;jump if not
	movem.l	d0-d1,-(sp)	;push d0-d1 on stack
	move.w	#$1F,d0	;1F into d0 - one timer min speed
	move.w	d0,(passspeed).w	;make passspeed start with a higher value
	movem.l	(sp)+,d0-d1	;Pop off stack d0-d1
.cont2
	clr.w	d0
	move.b	shotspd(a3),d0	;6C = shotspd (ShP)
	lsr.b	#1,d0	;divide by 2
	movea.l	a3,a0	;move a3 address into a0
	jsr	(makepde).l	;scale d0 based on energy level
	addi.w	#$14,d0	;add 14 to d0
	mulu.w	(passspeed).w,d0	;shot speed ranged by energy level
	mulu.w	#$5249,d0	;($4000*45)/35
	swap	d0	;swaps the upper and lower words of d0
	move.w	d0,(passspeed).w	;move d0 into passspeed
	btst	#0,shotspd(a3)	;checks if ShP value is even or odd
	beq.w	.even
	asr.w	#4,d0	;divide by 16
	add.w	(passspeed).w,d0	;add passspeed to d0
.even
	lsr.w	#4,d0	;divide by 16 (d0 is passspeed)
	neg.w	d0	;negative
	addq.w	#3,d0	;add 3 to d0
	bpl.w	.nbh2
	clr.w	d0	;clear if negative
.nbh2
	add.w	d0,(sp)	;add to stack current value (Shot SFX)
	st	(puckc).w	;clear puck carrier
	move.b	#$10,nopuck(a3)	;5E = nopuck - no puck collision till 0
	move.w	SCnum(a3),(lastplayer).w	;SCNum
	move.w	#$108,d1	;$108 = top goal line Y position
	btst	#pfgoal,pflags(a3)	;pfgoal, pflags
	bne.w	.0	;branch if shooting up
	neg.w	d1	;flip d1 if shooting down
.0
	move.w	(passdir).w,d2	;passdir into d2
	asl.w	#2,d2	;mult by 4
	lea	shotsets(pc),a0	;table of shot directions
	move.w	0(a0,d2.w),d0	;xoffset
	move.w	2(a0,d2.w),d2	;z offset
	sub.w	(puckx).w,d0
	sub.w	(pucky).w,d1
	movem.w	d0-d2,-(sp)	;push d0-d2(dx,dy,z offset) on stack
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	sroot
	tst.w	d0	;distance in pix to goal
	bne.w	.1
	addq.w	#1,d0
.1
	move.w	d0,d3	;straight line distance from puck to spot aiming for with passdir
	btst	#gmhl,(gmode).w	;check if highlight (always perfect)
	bne.w	.perf
	cmp.w	#$C8,d3	;C8 = 200 decimal
	bhi.w	.notperf	;too far away from perfect shot
	jsr	(ReadGoaliePulled).l	;checks if shooting team's G pulled
	bmi.w	.perf	;perfect shot with pulled goalie
	btst	#0,(gmode2).w	;check if shootout
	bne.w	.perf	;perfect shot in shootout
	moveq	#$10,d0	;start value for ShA calc
	add.b	shotacc(a3),d0	;shotacc(a3)
	bsr.w	randomd0
	cmp.w	#$E,d0	;chance of perfect shot
	bgt.w	.perf	;branch if higher - perfect shot
.notperf
	clr.w	d0
	move.b	shotacc(a3),d0	;shotacc(a3)
	lsr.w	#1,d0	;divide by 2
	move.b	d0,-(sp)	;push on stack
	move.w	(passspeed).w,d0	;move passspeed into d0
	lsr.w	#4,d0	;divide by 16
	sub.b	(sp)+,d0	;shotacc(a3) / 2
	addi.b	#$10,d0	;add $10 to d0
	mulu.w	d3,d0	;mult straight line distance with d0
	lsr.w	#6,d0	;shot accuracy adjust - divide by 64
	cmp.w	#$FA,d3	;250 pixels straight line distance
	bhi.w	.chkvalue	;branch if higher
	lsr.w	#1,d0	;extra shot accuracy adjust
.chkvalue
	cmp.w	#$88,d0	;compare to $88 (max adj value in X)
	blt.w	.cont3
	move.w	#$88,d0
.cont3
	move.w	d0,-(sp)	;push adjusting value on stack
	bsr.w	randomd0s	;RNG adj value
	add.w	d0,2(sp)	;add result to x diff
	move.w	(sp),d0	;move adjusting value into d0
	cmp.w	#$3C,d0	;'<'   ; compare to $3C (max adjustment in Y)
	bls.w	.lessx	;branch if less
	moveq	#$3C,d0
	move.w	d0,(sp)
.lessx
	tst.w	4(sp)
	bpl.w	.ycalc
	lsr.w	#1,d0
.ycalc
	bsr.w	randomd0s	;RNG adjustment
	add.w	d0,4(sp)	;add to y diff
	move.w	(sp)+,d0	;pop adj value
	lsr.w	#1,d0	;divide by 2
	bsr.w	randomd0	;RNG result
	add.w	d0,4(sp)	;add to Z diff
.perf
	move.w	(passspeed).w,d2	;shot speed
	muls.w	#$44,d2	;'D'   ; 1024/15
	muls.w	(sp)+,d2	;mult by x dist
	divs.w	d3,d2	;divide d2 by straight line distance
	move.w	d2,(puckvx).w	;move into puckvx
	move.w	(passspeed).w,d2
	muls.w	#$44,d2	;'D'   ; 1024/15
	muls.w	(sp)+,d2	;mult by y dist
	divs.w	d3,d2	;divide d2 by straight line distance
	move.w	d2,(puckvy).w	;move into puckvy
	move.w	#$8000,d1	;this is the highest negative puckvy possible
	btst	#7,pflags(a3)	;check direction of shooting net
	beq.w	.2	;branch if bottom goal
	clr.w	d1
.2
	eor.w	d2,d1	;EOR - checking to see if exceeding maximum puckvy
	bpl.w	.3	;branch if positive
	move.w	#$3810,(puckvy).w	;move into puckvy
	btst	#7,pflags(a3)	;check net shooting on
	bne.w	.3	;branch if top
	move.w	#$C7F0,(puckvy).w	;move into puckvy (shooting on bottom net)
.3
	move.w	(sp)+,d1	;pix height in goal
	beq.w	.ex	;exit if zero
	mulu.w	(passspeed).w,d1
	mulu.w	#$44,d1	;'D'   ; 1024/15
	divu.w	d3,d1	;d3 = distance in pix to goal
	mulu.w	#$B33,d3	;(1024*42)/15
	divu.w	(passspeed).w,d3	;divide by passspeed
	add.w	d1,d3
	cmp.w	#$1800,d3
	bls.w	.noup	;branch if less than
	move.w	#$1800,d3	;set max puckvz
.noup
	move.w	d3,(puckvz).w	;move into puckvz
	bclr	#4,(sflags5).w	;check in-close top shelf bit
	beq.w	.ex	;if bit was cleared, exit
	btst	#pf3onetimer,pflags3(a3)	;check if one timer
	bne.w	.ex	;branch if so
	jsr	(puckvzadj).l	;adjust puckvz for top shelf shot
.ex
	bsr.w	sfx
	movem.l	(sp)+,d0-d7/a0-a3
	rts
shotsets	dc.w	0
	;offsets for different directions on the shot
	;passdir 0(x,z)
	dc.w	$C
	dc.w	$10	;passdir 1
	dc.w	$C
	dc.w	$10	;passdir 2
	dc.w	6
	dc.w	$10	;passdir 3
	dc.w	0
	dc.w	0	;passdir 4
	dc.w	0
	dc.w	$FFF0	;passdir 5
	dc.w	0
	dc.w	$FFF0	;passdir 6
	dc.w	6
	dc.w	$FFF0	;passdir 7
	dc.w	$C
	dc.w	0	;passdir 8
	dc.w	6
; a3 = shooter
; Determines where to shoot for CPU player or on a one timer
shotdiradj
	btst	#pf3onetimer,pflags3(a3)	;check if shooting one timer
	bne.w	.0	;jump if shooting one timer
	btst	#3,pflags(a3)	;pfjoycon - checks if player is joystick controlled
	bne.w	.ex	;exit if joystick
.0
	moveq	#8,d0
	moveq	#5,d1
	movea.w	#(SortCords-SCstruct-M68K_RAM),a0	;SC Struct start - 80
	btst	#6,pflags(a3)	;pfteam - check if home or away
	bne.w	.loop	;jump if away
	adda.w	#$300,a0	;add 300 to a0 (start on away team)
.loop
	adda.w	#$80,a0	;move to next player struct
	tst.w	$34(a0)	;check if goalie. Find opponents goalie
	dbeq	d1,.loop
	bne.w	.setpassdir	;branches if no goalie
	move.b	$28(a0),d0	;Opponent's G is A0. Move Xvel into d0
	ext.w	d0	;sign extend d0
	asr.w	#1,d0	;divide by 2
	add.w	(a0),d0	;Xpos
	sub.w	(puckx).w,d0	;sub puckx from d0
	move.b	$2A(a0),d1	;Yvel
	ext.w	d1	;sign extend d1
	asr.w	#1,d1	;divide by 2
	add.w	$14(a0),d1	;Ypos
	sub.w	(pucky).w,d1	;sub pucky from d1
	movem.w	d0-d1,-(sp)	;push to stack
	muls.w	d0,d0	;square d0
	muls.w	d1,d1	;square d1
	add.l	d1,d0	;add d1 to d0
	addq.l	#1,d0	;add 1 to d0
	bsr.w	sroot	;get square root
	move.w	d0,d2	;move result into d2
	movem.w	(sp)+,d0-d1	;pop from stack (distance x and y from G to puck)
	moveq	#$12,d3	;post?
	move.w	#$108,d4	;Goal line
	btst	#7,pflags(a3)	;check which goal shooting at
	bne.w	.chkposts	;jump if top goal
	neg.w	d4	;negate if bottom goal
.chkposts
	movem.w	d3-d4,-(sp)	;push to stack
	bsr.w	CalcAngleOffset
	move.w	d4,d5
	movem.w	(sp)+,d3-d4	;pop from stack
	neg.w	d3	;negate d3 (other post)
	bsr.w	CalcAngleOffset
	add.w	d5,d4	;add results to d4
	clr.w	d0	;clear d0
	cmp.w	#$2C,d4	;','   ; 2C - right X edge of crease
	bgt.w	.setpassdir
	cmp.w	#$FFD4,d4	;FFD4 - left X edge of crease
	blt.w	.setpassdir
	btst	#7,pflags(a3)	;check what net shooting on
	beq.w	.passdir	;branch if bottom
	neg.w	d4	;negate d4
.passdir
	moveq	#2,d0	;move 2 into d0
	tst.w	d4	;check if d4 is 0
	bpl.w	.setpassdir	;branch if positive
	moveq	#6,d0	;move 6 into d0
.setpassdir
	move.w	d0,(passdir).w	;will be 0,2,6, or 8 (no goalie)
	btst	#2,(BA_PS_flags).w
	bne.w	.PSorSO	;branch if bit 2 is set
	btst	#0,(gmode2).w	;check if shootout
	beq.w	.ex	;branch if not set
.PSorSO
	jsr	(PSandSOpassdir).l
.ex
	rts
; Gets the area with respect to puck location, goalie location, and the post and divides it by the straight distance from goalie to puck
;
; d0 = difference in X from G to puck
; d1 = difference in Y from G to puck
; d2 = distance from G to puck (straight line)
; d3 = post X position
; d4 = goalline
;
CalcAngleOffset
	sub.w	(puckx).w,d3	;sub puckx from post X
	sub.w	(pucky).w,d4	;sub pucky from goalline
	muls.w	d0,d4	;mult d0 with d4
	muls.w	d1,d3	;mult d1 with d3
	sub.l	d3,d4	;sub d3 from d4
	divs.w	d2,d4	;divide d2 into d4
	rts
; copy info into pad cont so graphics know which player/number
setpads	;Put SCnum of a3 in the d4 nibble of PadControlBits ; d4 = -2 puck
	;carrier, 0 / 2 pads, 4 replay target. Falls into rtss3
	movem.l	d0-d1,-(sp)
	moveq	#2,d0
	add.w	d4,d0
	add.w	d0,d0
	move.w	#$FFF0,d1
	rol.w	d0,d1
	and.w	d1,(PadControlBits).w
	move.w	SCnum(a3),d1
	asl.w	d0,d1
	or.w	d1,(PadControlBits).w
	movem.l	(sp)+,d0-d1
rtss3
	rts
