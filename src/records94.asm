UserNameEntry	;With user records on (OptUserRec 0): the name entry (NameEntryScreen) for the pads in use. Called from PeriodOver
	tst.w	(OptUserRec).w
	bne.w	.x
	clr.w	(homeuser).w
	clr.w	(awayuser).w
	tst.w	(cont1team).w
	beq.w	.0
	move.w	(cont1team).w,(nameentryvis).w
	subq.w	#1,(nameentryvis).w
	jsr	(NameEntryScreen).l
.0
	tst.w	(cont2team).w
	beq.w	.x
	movem.w	d0,-(sp)
	move.w	(cont1team).w,d0
	cmp.w	(cont2team).w,d0
	movem.w	(sp)+,d0
	beq.w	.x
	move.w	(cont2team).w,(nameentryvis).w
	subq.w	#1,(nameentryvis).w
	jsr	(NameEntryScreen).l
.x
	rts
SkipOtherUserName	;Name entry: step the selection namelogsel past the name the other pad picked (homeuser / awayuser), in the direction on the stack
	movem.w	d0,-(sp)
	move.w	(awayuser).w,d0
	tst.w	(nameentryvis).w
	beq.w	.0
	move.w	(homeuser).w,d0
.0
	cmp.w	(namelogsel).w,d0
	bne.w	.x
	move.w	#1,d0
	tst.w	(sp)
	bpl.w	.1
	move.w	#$FFFF,d0
.1
	add.w	d0,(namelogsel).w
	clr.w	d0
.x
	movem.w	(sp)+,d0
	rts
RecordHoldersScreen	;"Record Holders" menu item (menu lists): the save RAM record holders (PrintRecordTitles ... ReadTeamRecords)
	move.w	#0,d0
	move.w	#$1A,d1
	jsr	(SetupScreen).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),1,1
	movea.l	#CornerLogoMap,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d1
	clr.w	d0
	moveq	#6,d2
	move.w	#6,d3
	moveq	#8,d5
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),'!',1
	movea.l	#ArenaGfxBank,a0
	movea.l	a0,a1
.0
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d1
	clr.w	d0
	moveq	#6,d2
	move.w	#6,d3
	moveq	#0,d5
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),$B,1
	move.w	#$12,d0
	move.w	#7,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP3),$E,2,'Record',-(TXPRI+TXMAP3),$D,5,'Holders',-(TXPRI+TXMAP3),1,9
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,6,3,5,8,CC_SetFont,1,'Name',CC_SetFont,0
	bsr.w	ReadNameLog
	clr.w	(TempWord1).w
	bclr	#6,(sflags6).w
	bsr.w	ReadTeamRecords
	bset	#6,(sflags6).w
	bsr.w	ReadTeamRecords
	bsr.w	CalcWinPercents
	bsr.w	PrintRecordTitles
	bsr.w	PrintWinRecords
.loop
	jsr	(vcountwait).l
	jsr	(getpzjoy).l
	jsr	(ProcessInputWithRepeat).l
	btst	#7,d3
	beq.w	.1
	jmp	ExitStatsScreen
.1
	tst.w	(TempWord1).w
.2
	bne.w	.right
	btst	#6,d3
	beq.w	.right
.3
	btst	#5,d3
	beq.w	.right
	bsr.w	ClearWinRecords
	bsr.w	CalcWinPercents
.show
	bsr.w	PrintWinRecords
	bra.s	.loop
.right
	btst	#3,d1
	beq.w	.left
	cmpi.w	#2,(TempWord1).w
	beq.s	.loop
	bsr.w	ClearRecordArea
	addq.w	#1,(TempWord1).w
	bsr.w	PrintRecordTitles
	bsr.w	PrintRecordPage
	bra.s	.loop
.left
	btst	#2,d1
	beq.s	.loop
	tst.w	(TempWord1).w
	beq.s	.loop
	bsr.w	ClearRecordArea
	subq.w	#1,(TempWord1).w
	bsr.w	PrintRecordTitles
	bsr.w	PrintRecordPage
	bra.w	.loop
	dc.b	$4E	;N
	dc.b	$75	;u
PrintRecordPage	;Record Holders: print page TempWord1 (0: PrintWinRecords, else PrintPlayerRecords)
	tst.w	(TempWord1).w
	beq.w	PrintWinRecords
	bra.w	PrintPlayerRecords
PrintRecordTitles	;Record Holders: the record titles (WinRecTitles, GoalRecTitles, SaveRecTitles)
	movea.l	#WinRecTitles,a1
	tst.w	(TempWord1).w
	beq.w	.0
	movea.l	#SaveRecTitles,a1
	cmpi.w	#2,(TempWord1).w
	beq.w	.0
	movea.l	#GoalRecTitles,a1
.0
	jsr	(printsmall).l
	rts
WinRecTitles	dc.b	0	;PrintRecordTitles Strings
	dc.b	$52	;R
	dc.b	$F8,6,3,$10,8,$F9,1,$20,$20,$20
	dc.b	$57	;W
	dc.b	$69	;i
	dc.b	$6E	;n
	dc.b	$20
	dc.b	$25	;%
	dc.b	$20,$20,$20
	dc.b	$57	;W
	dc.b	$69	;i
	dc.b	$6E	;n
	dc.b	$2D	;-
	dc.b	$4C	;L
	dc.b	$6F	;o
	dc.b	$73	;s
	dc.b	$73	;s
	dc.b	$2D	;-
	dc.b	$54	;T
	dc.b	$69	;i
	dc.b	$65	;e
	dc.b	$FD,4,$FC,$19
	dc.b	$55	;U
	dc.b	$73	;s
	dc.b	$65	;e
	dc.b	$20
	dc.b	$41	;A
	dc.b	$2B	;+
	dc.b	$43	;C
	dc.b	$20
	dc.b	$74	;t
	dc.b	$6F	;o
	dc.b	$20
	dc.b	$63	;c
	dc.b	$6C	;l
	dc.b	$65	;e
	dc.b	$61	;a
	dc.b	$72	;r
	dc.b	$20
	dc.b	$41	;A
	dc.b	$4C	;L
	dc.b	$4C	;L
	dc.b	$20
	dc.b	$77	;w
	dc.b	$69	;i
	dc.b	$6E	;n
	dc.b	$20
	dc.b	$72	;r
	dc.b	$65	;e
	dc.b	$63	;c
	dc.b	$6F	;o
	dc.b	$72	;r
	dc.b	$64	;d
	dc.b	$73	;s
	dc.b	$FD,$10,$FC,$1A,$20,$20
	dc.b	$4D	;M
	dc.b	$6F	;o
	dc.b	$72	;r
	dc.b	$65	;e
	dc.b	$20
	dc.b	$5D	;]
	dc.b	$F9,0
GoalRecTitles	dc.b	0	;PrintRecordTitles Strings
	dc.b	$50	;P
	dc.b	$F8,6,3,$12,8,$F9,1
	dc.b	$47	;G
	dc.b	$6F	;o
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	$73	;s
	dc.b	$20,$20,$20,$20,$20,$20,$20
	dc.b	$54	;T
	dc.b	$65	;e
	dc.b	$61	;a
	dc.b	$6D	;m
	dc.b	$73	;s
	dc.b	$20,$20,$20,$20,$FD,4,$FC,$19,$20,$20,$20,$20
	dc.b	$54	;T
	dc.b	$45	;E
	dc.b	$41	;A
	dc.b	$4D	;M
	dc.b	$20
	dc.b	$4D	;M
	dc.b	$55	;U
	dc.b	$53	;S
	dc.b	$54	;T
	dc.b	$20
	dc.b	$57	;W
	dc.b	$49	;I
	dc.b	$4E	;N
	dc.b	$20
	dc.b	$54	;T
	dc.b	$4F	;O
	dc.b	$20
	dc.b	$51	;Q
	dc.b	$55	;U
	dc.b	$41	;A
	dc.b	$4C	;L
	dc.b	$49	;I
	dc.b	$46	;F
	dc.b	$59	;Y
	dc.b	$20,$20,$20,$20,$FD,$10,$FC,$1A
	dc.b	$5B	;[
	dc.b	$20
	dc.b	$4D	;M
	dc.b	$6F	;o
	dc.b	$72	;r
	dc.b	$65	;e
	dc.b	$20
	dc.b	$5D	;]
	dc.b	$F9,0
SaveRecTitles	dc.b	0	;PrintRecordTitles Strings
	dc.b	$50	;P
	dc.b	$F8,6,3,$12,8,$F9,1
	dc.b	$53	;S
	dc.b	$61	;a
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$73	;s
	dc.b	$20,$20,$20,$20,$20,$20,$20
	dc.b	$54	;T
	dc.b	$65	;e
	dc.b	$61	;a
	dc.b	$6D	;m
	dc.b	$73	;s
	dc.b	$20,$20,$20,$20,$FD,4,$FC,$19,$20,$20,$20,$20
	dc.b	$54	;T
	dc.b	$45	;E
	dc.b	$41	;A
	dc.b	$4D	;M
	dc.b	$20
	dc.b	$4D	;M
	dc.b	$55	;U
	dc.b	$53	;S
	dc.b	$54	;T
	dc.b	$20
	dc.b	$57	;W
	dc.b	$49	;I
	dc.b	$4E	;N
	dc.b	$20
	dc.b	$54	;T
	dc.b	$4F	;O
	dc.b	$20
	dc.b	$51	;Q
	dc.b	$55	;U
	dc.b	$41	;A
	dc.b	$4C	;L
	dc.b	$49	;I
	dc.b	$46	;F
	dc.b	$59	;Y
	dc.b	$20,$20,$20,$20,$FD,$10,$FC,$1A
	dc.b	$5B	;[
	dc.b	$20
	dc.b	$4D	;M
	dc.b	$6F	;o
	dc.b	$72	;r
	dc.b	$65	;e
	dc.b	$20,$20,$F9,0
PrintWinRecords	;Record Holders: the rows (PrintRecordName)
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,2,2,$A,CC_SetFont,0
	move.w	#6,d7
	movea.l	#winsort,a0
	movea.l	#winpcts,a2
	movea.l	#ThreeStars,a5
.loop
	move.w	#2,(printx).w
	move.b	(a0)+,d0
	ext.w	d0
	move.b	0(a2,d0.w),d5
	asl.w	#4,d0
	move.b	$A(a5,d0.w),d4
	lsl.w	#8,d4
	move.b	$B(a5,d0.w),d4
	move.w	d4,-(sp)
	move.b	$C(a5,d0.w),d4
	lsl.w	#8,d4
	move.b	$D(a5,d0.w),d4
	move.w	d4,(recties).w
	move.b	8(a5,d0.w),d4
	lsl.w	#8,d4
	move.b	9(a5,d0.w),d4
	move.w	d4,(recwins).w
	add.w	(recties).w,d4
	sub.w	(sp),d4
	neg.w	d4
	move.w	d4,(reclosses).w
	move.w	(sp)+,d4
	tst.w	d4
	beq.w	.0
	bsr.w	PrintRecordName
	move.w	#$13,(printx).w
	move.w	d0,-(sp)
	move.w	d5,d0
	move.w	#3,d1
	jsr	(PushNumberWidth).l
	jsr	(printsmall).l
	move.w	#$1A,(printx).w
	move.w	(recwins).w,d0
	move.w	#4,d1
	jsr	(PushNumberWidth).l
	jsr	(printsmall).l
	move.w	#$1F,(printx).w
	move.w	(reclosses).w,d0
	move.w	#4,d1
	jsr	(PushNumberWidth).l
	jsr	(printsmall).l
	move.w	#$24,(printx).w
	move.w	(recties).w,d0
	move.w	#3,d1
	jsr	(PushNumberWidth).l
	move.w	(sp)+,d0
	bra.w	.1
.0
	movea.l	#RecParenTxt,a1
.1
	jsr	(printsmall).l
	addq.w	#2,(printy).w
	dbf	d7,.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ClearRecordArea	;Record Holders: erase the record rows ($28 x $12), keeping printx / printy / printm
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	move.w	(printm).w,-(sp)
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,2,0,$A
	move.w	#$28,d0
	move.w	#$12,d1
	jsr	(eraser).l
	move.w	(sp)+,(printm).w
	move.w	(sp)+,(printy).w
	move.w	(sp)+,(printx).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintPlayerRecords	;Record Holders: the rows of the other page (PrintRecordName)
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,2,2,$A,CC_SetFont,0
	move.w	#6,d7
	movea.l	#recsort1,a0
	cmpi.w	#1,(TempWord1).w
	beq.w	.0
	movea.l	#recsort2,a0
.0
	movea.l	#ThreeStars,a2
.loop
	move.w	#2,(printx).w
	move.b	(a0)+,d0
	ext.w	d0
	asl.w	#4,d0
	move.b	0(a2,d0.w),d5
	cmpi.w	#1,(TempWord1).w
	beq.w	.1
	move.b	4(a2,d0.w),d5
.1
	tst.b	d5
	beq.w	.none
	bsr.w	PrintRecordName
	move.w	#$12,(printx).w
	move.w	d0,-(sp)
	cmpi.w	#1,(TempWord1).w
	bne.w	.2
	move.b	0(a2,d0.w),d0
	bra.w	.3
.2
	move.b	4(a2,d0.w),d0
.3
	andi.w	#$FF,d0
	move.w	#3,d1
	jsr	(PushNumberWidth).l
	jsr	(printsmall).l
	move.w	(sp)+,d0
	move.w	#$19,(printx).w
	movea.l	#RecHolderByTxt,a1
	movea.l	#mesarea,a3
	bsr.w	CopyString
	move.w	d0,-(sp)
	cmpi.w	#1,(TempWord1).w
	bne.w	.4
	move.b	1(a2,d0.w),d0
	bra.w	.5
.4
	move.b	5(a2,d0.w),d0
.5
	andi.w	#$FF,d0
	movea.l	#mesarea,a1
	bsr.w	AppendTeamName
	movea.l	#RecHolderVsTxt,a1
	movea.l	#mesarea,a3
	jsr	(appstring).l
	movea.l	#mesarea,a1
	move.w	(sp)+,d0
	cmpi.w	#1,(TempWord1).w
	bne.w	.6
	move.b	2(a2,d0.w),d0
	bra.w	.7
.6
	move.b	6(a2,d0.w),d0
.7
	andi.w	#$FF,d0
	bsr.w	AppendTeamName
	bra.w	.print
.none
	movea.l	#RecParenTxt,a1
.print
	jsr	(printsmall).l
	addq.w	#2,(printy).w
	dbf	d7,.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts
RecParenTxt	dc.b	0	;PrintWinRecords data
	dc.b	$28	;(
	dc.b	$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	dc.b	$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	dc.b	$20,$20,$20,$20,$20,$20
RecHolderByTxt	dc.b	0	;PrintPlayerRecords data
	dc.b	6
	dc.b	$62	;b
	dc.b	$79	;y
	dc.b	$20,0
RecHolderVsTxt	dc.b	0	;PrintPlayerRecords data
	dc.b	8,$20
	dc.b	$76	;v
	dc.b	$73	;s
	dc.b	$2E
	dc.b	$20,0
PrintRecordName	;Record Holders: print a value (AppendUserName)
	move.w	d7,-(sp)
	neg.w	d7
	addq.w	#7,d7
	addi.w	#$30,d7
	movea.l	#mesarea,a1
	move.w	#6,(a1)
	move.b	d7,2(a1)
	move.b	#$2E,3(a1)
	move.b	#$20,4(a1)
	move.b	#0,5(a1)
	jsr	(printsmall).l
	move.w	(sp)+,d7
	move.b	-1(a0),d2
	ext.w	d2
	movea.l	#mesarea,a1
	bclr	#7,(sflags6).w
	bsr.w	AppendUserName
	jmp	printsmall
CalcWinPercents	;Record Holders: for the 8 user record blocks at ThreeStars, the win % (winpcts), games (wingames) and ties (winties), then sort the rows (winsort)
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#ThreeStars,a0
	movea.l	#winpcts,a1
	movea.l	#winties,a6
	movea.l	#wingames,a5
	move.w	#7,d7
.loop
	move.b	8(a0),d0
	lsl.w	#8,d0
	move.b	9(a0),d0
	move.b	$A(a0),d1
	lsl.w	#8,d1
	move.b	$B(a0),d1
	move.w	d1,(a5)+
	tst.w	d1
	bne.w	.0
	clr.w	d0
	bra.w	.1
.0
	mulu.w	#$64,d0
	divu.w	d1,d0
.1
	move.b	d0,(a1)+
	move.b	$C(a0),(a6)+
	move.b	$D(a0),(a6)+
	adda.w	#$10,a0
	dbf	d7,.loop
	movea.l	#winsort,a1
	move.l	a1,-(sp)
	move.w	#1,d0
	move.w	#6,d7
.loop2
	move.b	d0,(a1)+
	addq.w	#1,d0
	dbf	d7,.loop2
	movea.l	(sp),a1
	movea.l	#winpcts,a0
	movea.l	#winties,a6
	movea.l	#wingames,a5
.loop3
	movea.l	(sp),a1
	move.w	#5,d7
	clr.w	d6
.loop4
	move.b	(a1)+,d1
	ext.w	d1
	move.b	(a1),d2
	ext.w	d2
	move.b	0(a0,d1.w),d0
	move.b	0(a0,d2.w),d3
	cmp.b	d3,d0
	bgt.w	.next
	blt.w	.swap
	movem.l	d1-d3,-(sp)
	add.w	d1,d1
	add.w	d2,d2
	move.w	0(a6,d1.w),d0
	move.w	0(a6,d2.w),d3
	cmp.w	d3,d0
	movem.l	(sp)+,d1-d3
	bgt.w	.next
	blt.w	.swap
	movem.l	d1-d3,-(sp)
	add.w	d1,d1
	add.w	d2,d2
	move.w	0(a5,d1.w),d0
	move.w	0(a5,d2.w),d3
	cmp.w	d3,d0
	movem.l	(sp)+,d1-d3
	bge.w	.next
.swap
	move.b	(a1),d0
	move.b	-1(a1),d1
	move.b	d0,-1(a1)
	move.b	d1,(a1)
	st	d6
.next
	dbf	d7,.loop4
	tst.w	d6
	bne.s	.loop3
	movea.l	(sp)+,a1
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ReadTeamRecords	;Record Holders: read the records (ReadSRAM)
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	#$D20,d0
	move.l	#$80,d1
	movea.l	#ThreeStars,a0
	jsr	(ReadSRAM).l
	movea.l	#recsort1,a1
	btst	#6,(sflags6).w
	beq.w	.0
	movea.l	#recsort2,a1
.0
	move.l	a1,-(sp)
	move.w	#1,d0
	move.w	#6,d7
.loop
	move.b	d0,(a1)+
	addq.w	#1,d0
	dbf	d7,.loop
	movea.l	(sp),a1
	movea.l	#ThreeStars,a0
.loop2
	movea.l	(sp),a1
	move.w	#5,d7
	clr.w	d6
.loop3
	move.b	(a1)+,d1
	ext.w	d1
	move.b	(a1),d2
	ext.w	d2
	asl.w	#4,d1
	asl.w	#4,d2
	move.b	0(a0,d1.w),d0
	move.b	0(a0,d2.w),d3
	btst	#6,(sflags6).w
	beq.w	.1
	move.b	4(a0,d1.w),d0
	move.b	4(a0,d2.w),d3
.1
	cmp.b	d3,d0
	bge.w	.next
	move.b	(a1),d0
	move.b	-1(a1),d1
	move.b	d0,-1(a1)
	move.b	d1,(a1)
	st	d6
.next
	dbf	d7,.loop3
	tst.w	d6
	bne.s	.loop2
	movea.l	(sp)+,a1
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ShootoutModeBox	;Shootout "SHOOTOUT MODE" box: the shooter " vs." the goalie and both teams' shootout goals. Jumped to from PenaltyShotBox
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#$FFFF,d0
	jsr	(prefmes).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),3,2
	moveq	#$1B,d0
	moveq	#$C,d1
	jsr	(Framer).l
	lea	ShootoutModeBigTxt(pc),a1
	jsr	(printbig).l
	move.w	(BA_Skater_Offset).w,d0
	movea.l	#tmstruct,a2
	tst.w	(BA_Team).w
	beq.w	.0
	movea.l	#AwShots,a2
.0
	jsr	(FormatPlayerNumInitial).l
	move.w	(printx).w,-(sp)
	jsr	(print).l
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	addq.w	#6,(printx).w
	jsr	(printz).l
	String	' vs.',-(TXPRI+TXMAP1),4,7
	move.w	(BA_Goalie_SCnum).w,d0
	asl.w	#7,d0
	movea.l	#SortCords,a2
	adda.w	d0,a2
	clr.w	d0
	move.b	$66(a2),d0
	movea.l	#AwShots,a2
	tst.w	(BA_Team).w
	beq.w	.1
	movea.l	#tmstruct,a2
.1
	jsr	(FormatPlayerNumInitial).l
	jsr	(print).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),4,9
	movea.l	#tmstruct,a1
	movea.l	$1E(a1),a1
	adda.w	4(a1),a1
	jsr	(print).l
	move.w	#$15,(printx).w
	move.w	(homeshootgoals).w,d0
	move.w	#3,d1
	jsr	(PushNumberWidth).l
	jsr	(print).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),4,$A
	movea.l	#AwShots,a1
	movea.l	$1E(a1),a1
	adda.w	4(a1),a1
	jsr	(print).l
	move.w	#$15,(printx).w
	move.w	(awayshootgoals).w,d0
	move.w	#3,d1
	jsr	(PushNumberWidth).l
	jsr	(print).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),4,$C,'Round '
	move.w	(shootoutround).w,d0
	move.w	#2,d1
	jsr	(PushNumberWidth).l
	jsr	(print).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ShootoutModeBigTxt	dc.b	0	;ShootoutModeBox big text
	dc.b	$16,$BF,4,3
	dc.b	$53	;S
	dc.b	$48	;H
	dc.b	$4F	;O
	dc.b	$4F	;O
	dc.b	$54	;T
	dc.b	$4F	;O
	dc.b	$55	;U
	dc.b	$54	;T
	dc.b	$20
	dc.b	$4D	;M
	dc.b	$4F	;O
	dc.b	$44	;D
	dc.b	$45	;E
	dc.b	$BF,4,5,0
