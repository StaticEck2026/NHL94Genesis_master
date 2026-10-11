; $0FC47C  NEW in 94: shootout
ClearShootout	;94 only. Clear the player structs (SortCords) and the shootout state. Called from hockey94_08
	movea.l	#SortCords,a0
	move.w	#$3FF,d0
.loop
	clr.w	(a0)+
	dbf	d0,.loop
	clr.w	(shootoutdelay).w
	move.w	#1,(playoffround).w
	bclr	#3,(gmode2).w
	clr.w	(homeshootgoals).w
	clr.w	(awayshootgoals).w
	clr.w	(homeshootnum).w
	clr.w	(shootoutteam).w
.0
	bsr.w	InitShooters
	move.w	#1,(shootoutteam).w
	bsr.w	InitShooters
	clr.w	(shootoutteam).w
	rts
NextShooter	;94 only. Shootout: the next shooter (BA_Team, BA_Goalie_SCnum, StartShootoutPath), or the end (ExitToOpening). Called from logic94_4
	btst	#3,(gmode2).w
	beq.w	.0
	jmp	ExitToOpening
.0
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	StartShootoutPath
	move.w	(shootoutteam).w,(BA_Team).w
	move.w	#$B,(BA_Goalie_SCnum).w
	movea.l	#homeshooters,a0
	tst.w	(shootoutteam).w
	beq.w	.1
	move.w	#5,(BA_Goalie_SCnum).w
	movea.l	#awayshooters,a0
.1
	move.w	(homeshootnum).w,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),(BA_Skater_Offset).w
	bclr	#2,(SortCords+(puckscnum*SCstruct)+pflags).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
CountShootoutGoals	;94 only. Shootout: count the goals and end it when one team cannot catch up (EndShootout, high ROM). Called from EndPenaltyShotPlay (logic94_4)
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#0,(shootoutteam+1).w
	beq.w	.0
	cmpi.w	#5,(playoffround).w
	blt.w	.0
	move.w	(homeshootgoals).w,d0
	cmp.w	(awayshootgoals).w,d0
	beq.w	.0
	bset	#3,(gmode2).w
	jsr	(EndShootout).l
	bra.w	.x
.0
	eori.w	#1,(shootoutteam).w
	bne.w	.x
	addq.w	#1,(homeshootnum).w
	cmpi.w	#5,(homeshootnum).w
	blt.w	.1
	clr.w	(homeshootnum).w
.1
	addq.w	#1,(playoffround).w
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
InitShooters	;94 only. Shootout: the 6 starters of the home (shootoutteam 0) or away team as the shooter list below homeshootnum / shootoutteam
	movea.l	#homeshootnum,a0
	move.w	(HomeTeam).w,d0
	tst.w	(shootoutteam).w
	beq.w	.0
	move.w	(VisTeam).w,d0
	movea.l	#shootoutteam,a0
.0
	movea.l	#$30E,a1
	asl.w	#2,d0
	movea.l	0(a1,d0.w),a1
	adda.w	6(a1),a1
	move.w	#5,d0
.loop
	clr.w	d1
	move.b	(a1)+,d1
	subq.w	#1,d1
	move.w	d1,-(a0)
	dbf	d0,.loop
	rts
ShootoutWonBy	;94 only. Shootout: "SHOOTOUT WON BY" (printbig). Called from SetPA (penalty94_1)
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),1,$D
	move.w	#6,d1
	move.w	#$1E,d0
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP1),2,$E,'SHOOTOUT WON BY'
	addq.w	#2,(printy).w
	move.w	(HomeTeam).w,d1
	move.w	(homeshootgoals).w,d0
	cmp.w	(awayshootgoals).w,d0
	bgt.w	.0
	move.w	(VisTeam).w,d1
.0
	asl.w	#2,d1
	movea.l	#$30E,a1
	movea.l	0(a1,d1.w),a1
	adda.w	4(a1),a1
	move.w	#2,(printx).w
	jsr	(printbig).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ShootoutShooters	;Shootout shooters menu item (hockey94_11 menu lists): pick the 3 shooters of each team
	btst	#0,(gmode2).w
	beq.w	ShootersExit
	moveq	#0,d0
	moveq	#$1C,d1
	jsr	(SetupScreen).l
	clr.w	(DispAttribCtr).w
	clr.w	(PlayerScrollCtr).w
	jsr	(printsmallz).l
	String	TXS_MAP,2,TXS_X,0,TXS_Y
	moveq	#$28,d0
	moveq	#$1C,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	bsr.w	ResetShooterScroll
	bsr.w	PrintShooterSlots
	move.w	#0,(TestList).w
ShootersRedraw	;Shootout shooters: redraw (ShootersBackground, PrintShooterBox, PrintShooterNames)
	bsr.w	ShootersBackground
	bsr.w	PrintShooterNames
	bsr.w	PrintShooterBox
ShootersLoop	;Shootout shooters: the input loop
	jsr	(vcountwait).l
	jsr	(getpzjoy).l
	jsr	(ProcessInputWithRepeat).l
	btst	#7,d1
	bne.w	ShootersExit
	move.w	#1,d0
	btst	#1,d1
	bne.w	ShootersMove
	move.w	#$FFFF,d0
	btst	#0,d1
	bne.w	ShootersMove
	move.w	#0,d0
	btst	#2,d1
	bne.w	ShootersPick
	move.w	#5,d0
	btst	#3,d1
	bne.w	ShootersPick
	btst	#5,d1
	bne.w	ShooterSelectList
	bra.s	ShootersLoop
ShootersExit	;Leave (ExitAttributeScreen2)
	jmp	ExitAttributeScreen2
ShooterSelectList	;Shootout shooters: "{Select Player}" list
	move.w	#$C000,d7
	movea.l	#homeshooters,a0
	cmpa.l	#HmShots,a2
	beq.w	.0
	movea.l	#awayshooters,a0
.0
	move.w	(TestList).w,d0
	asl.w	#1,d0
	move.w	0(a0,d0.w),d6
	jsr	(ReadAttributeNibble).l
	move.w	d0,d1
	jsr	(GetPlayerCount).l
	sub.w	d1,d0
	subq.w	#1,d0
	cmpi.w	#5,(TestList).w
	bne.w	.1
	move.w	d1,d0
	subq.w	#1,d0
	clr.w	d1
.1
	move.w	d0,(screentimer).w
	clr.w	(PlayerScrollCtr).w
	clr.w	(VertLineScrolling).w
	movea.w	#(Satt-M68K_RAM),a0
	clr.w	d2
.loop
	move.b	d1,0(a0,d2.w)
	cmp.w	d1,d6
	bne.w	.2
	move.w	d2,(VertLineScrolling).w
.2
	addq.w	#1,d1
	addq.w	#1,d2
	dbf	d0,.loop
	bsr.w	ClearShooterScreen
	jsr	(printsmallz).l
	String	TXS_ALL,0,3,1,0
	move.w	#$12,d0
	move.w	#3,d1
	jsr	(Framer).l
	jsr	(printsmallz).l
	String	TXS_X,$15,TXS_Y
	move.w	#$12,d0	;IDA hid this
	move.w	#3,d1	;IDA hid this
	jsr	(Framer).l	;IDA hid this
	jsr	(printsmallz).l	;IDA hid this
	String	TXS_ALL,4,2,2,1,'{Select Player}'
	clr.w	d0
	bra.w	.6
.loop2
	jsr	(vcountwait).l
	jsr	(getpzjoy).l
	jsr	(ProcessInputWithRepeat).l
	btst	#7,d1
	bne.w	ShootersRedraw
	btst	#5,d1
	bne.w	.10
	moveq	#1,d0
	btst	#1,d1
	bne.w	.6
	btst	#3,d1
	bne.w	.3
	moveq	#-1,d0
	btst	#0,d1
	bne.w	.6
	btst	#2,d1
	bne.w	.3
	bra.s	.loop2
.3
	add.w	(DispAttribCtr).w,d0
	bmi.s	.loop2
	move.w	d0,(DispAttribCtr).w
.4
	bsr.w	PrintShooterList
.5
	bra.s	.loop2
.6
	add.w	(VertLineScrolling).w,d0
	bmi.s	.loop2
	cmp.w	(screentimer).w,d0
	bgt.s	.loop2
.7
	move.w	d0,(VertLineScrolling).w
	cmp.w	(PlayerScrollCtr).w,d0
	bgt.w	.8
	move.w	d0,(PlayerScrollCtr).w
.8
	subq.w	#5,d0
	cmp.w	(PlayerScrollCtr).w,d0
	ble.w	.9
	move.w	d0,(PlayerScrollCtr).w
.9
	bsr.w	PrintShooterList
	bra.w	.loop2
.10
	movea.w	#(Satt-M68K_RAM),a3
	adda.w	(VertLineScrolling).w,a3
	clr.w	d0
	move.b	(a3),d0
	move.w	(TestList).w,d2
	movea.l	#homeshooters,a0
	cmpa.l	#HmShots,a2
	beq.w	.11
	movea.l	#awayshooters,a0
.11
	asl.w	#1,d2
	move.w	d0,0(a0,d2.w)
	bra.w	ShootersRedraw
PrintShooterList	;94 only. Shootout shooters: the player list rows (getNameandAttrib)
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),$16,1
.loop
	movea.l	#PAttribOverall,a1
	cmpi.w	#5,(TestList).w
	bne.w	.0
	movea.l	#GAttribOverall,a1
.0
	move.w	(DispAttribCtr).w,d0
	bra.w	.1
.loop2
	adda.w	(a1),a1
	addq.w	#4,a1
.1
	tst.w	(a1)
	dbmi	d0,.loop2
	bpl.w	.2
	subq.w	#1,(DispAttribCtr).w
	bra.s	.loop
.2
	cmpa.l	#PAttribOverall,a1
	bne.w	.3
	movea.l	#ShooterOverallTxt,a1
.3
	cmpa.l	#GAttribOverall,a1
	bne.w	.4
	movea.l	#ShooterOverallTxt2,a1
.4
	jsr	(print).l
	move.l	(a1),d4
	movea.w	#(Satt-M68K_RAM),a3
	move.w	(PlayerScrollCtr).w,d2
	move.w	(screentimer).w,d1
	sub.w	d2,d1
	cmp.w	#5,d1
	bls.w	.5
	moveq	#5,d1
.5
	move.w	#2,(printy).w
.loop3
	jsr	(printsmallz).l
	String	TXS_ATTR,4,TXS_X,5,TXS_ADDY,1,'                      ',TXS_X,5
	cmp.w	(VertLineScrolling).w,d2
	bne.w	.6
	move.w	d7,(printa).w
.6
	clr.w	d0
	move.b	0(a3,d2.w),d0
	jsr	(GetNameandAttrib).l
	addq.w	#1,d2
	dbf	d1,.loop3
	rts
ShooterOverallTxt	dc.b	0	;PrintShooterList data
	dc.b	$12,$20,$20,$20,$20
	dc.b	$4F	;O
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$72	;r
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	$6C	;l
	dc.b	$20,$20,$20,$20
	dc.b	$5D	;]
	dc.b	$1F
	dc.b	$3A	;:
	dc.b	0,$A
ShooterOverallTxt2	dc.b	0	;PrintShooterList data
	dc.b	$12,$20,$20,$20,$20
	dc.b	$4F	;O
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$72	;r
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	$6C	;l
	dc.b	$20,$20,$20,$20
	dc.b	$5D	;]
	dc.b	$1B,$F,0,$A
ShootersPick	;94 only. Shootout shooters: C on a slot; the same slot (TestList) goes back to the loop, else select it (ShootersSelect)
	cmp.w	(TestList).w,d0
	beq.w	ShootersLoop
	bra.w	ShootersSelect
ShootersMove	;94 only. Shootout shooters: move the slot cursor by d0, wrapping in 0 ... 4 (not on slot 5)
	cmpi.w	#5,(TestList).w
	beq.w	ShootersLoop
	add.w	(TestList).w,d0
	bmi.w	.0
	cmp.w	#5,d0
	blt.w	ShootersSelect
	clr.w	d0
	bra.w	ShootersSelect
.0
	move.w	#4,d0
ShootersSelect	;94 only. Shootout shooters: TestList = d0, redraw the names and the player box, back to the loop
	move.w	d0,(TestList).w
	bsr.w	PrintShooterNames
	bsr.w	PrintShooterBox
	bra.w	ShootersLoop
ShootersBackground	;94 only. Shootout shooters background and "Shootout" title
	bsr.w	ClearShooterScreen
	movem.l	d0-d5/a0-a2,-(sp)
	jsr	(printz).l
	String	-TXMAP3,0,0
	movea.l	#ScoutMap,a1	;IDA hid this
	adda.l	4(a1),a1
	movea.w	#$30A,a2
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#1,d4
	moveq	#0,d5
	jsr	(dobitmap).l
	movem.l	(sp)+,d0-d5/a0-a2
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),7,1
	moveq	#$1A,d0
	moveq	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP2),$A,4,'  Shootout  ',-(TXPRI+TXMAP2),$F,1
	clr.w	d0
	cmpa.w	#$C6CE,a2
	beq.w	.0
	move.w	#$2C,d0
.0
	jmp	PrintTeamData
ClearShooterScreen	;94 only. Shootout shooters: erase the screen
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	moveq	#$28,d0	;IDA hid this
	moveq	#$A,d1
	move.w	#$7FF,d2
	jmp	eraser
ResetShooterScroll	;94 only. Shootout shooters: clear the list scroll words palfadenew+$5A and palfadenew+$7A
	clr.w	(palfadenew+$5A).w
	clr.w	(palfadenew+$7A).w
	rts
PrintShooterSlots	;94 only. Shootout shooters: "Shooters" 1. 2. 3.
	jsr	(printsmallz).l
	String	TXS_MAP,2,TXS_X,0,TXS_Y,$A
	jsr	(printsmallz).l
	String	TXS_ATTR,4
	jsr	(printsmallz).l
	String	TXS_X,7,TXS_Y,$C,'Shooters'
.0
	jsr	(printsmallz).l
	String	TXS_X,3,TXS_Y,$E,'1. '
	jsr	(printsmallz).l	;IDA hid this
	String	TXS_X,3,TXS_Y,$10,'2. '
	jsr	(printsmallz).l	;IDA hid this
	String	TXS_X,3,TXS_Y,$12,'3. '
	jsr	(printsmallz).l	;IDA hid this
	String	TXS_X,3,TXS_Y,$14,'4. '
	jsr	(printsmallz).l	;IDA hid this
	String	TXS_X,3,TXS_Y,$16,'5. '
	jsr	(printsmallz).l	;IDA hid this
	String	TXS_X,$1A,TXS_Y,$C,'Goalie'
	rts
PrintShooterBox	;94 only. Shootout shooters: the selected player box (getname)
	jsr	(printsmallz).l
	String	TXS_ALL,4,2,8,7,TXS_FONT,1
	moveq	#$18,d0
	moveq	#3,d1
	jsr	(Framer).l
	jsr	(printsmallz).l
	String	TXS_X,$15,TXS_Y,8,TXS_ATTR,6
	movea.l	#homeshooters,a1
	cmpa.l	#HmShots,a2
	beq.w	.0
	movea.l	#awayshooters,a1
.0
	move.w	(TestList).w,d0
	asl.w	#1,d0
	move.w	0(a1,d0.w),d0
	jsr	(getname).l
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	jsr	(printsmall).l
	clr.w	(printfontset).w
	rts
PrintShooterNames	;94 only. Shootout shooters: the shooters' names (FormatPlayerNameShort)
	movem.l	d0-d7/a0-a6,-(sp)
.0
	jsr	(printsmallz).l
	String	TXS_X,6,TXS_Y,$E,TXS_ATTR,6
	move.w	#0,d1
	movea.l	#homeshooters,a0
	cmpa.l	#HmShots,a2
	beq.w	.loop
	movea.l	#awayshooters,a0
.loop
	move.w	d1,d0
	asl.w	#1,d0
	move.w	0(a0,d0.w),d0
	jsr	(FormatPlayerNameShort).l
	move.w	(printx).w,-(sp)
	cmp.w	(TestList).w,d1
	bne.w	.1
	move.w	#2,(printfontset).w
.1
	cmp.w	#5,d1
	bne.w	.2
	move.w	#$19,(printx).w
	move.w	#$E,(printy).w
.2
	jsr	(printsmall).l
	clr.w	(printfontset).w
	move.w	(sp)+,(printx).w
	addq.w	#2,(printy).w
	addq.w	#1,d1
	cmp.w	#6,d1
	blt.s	.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts
