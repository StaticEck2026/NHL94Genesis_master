;	The stats screens: Scores (ShowScores), Line Editor, Team Roster, Scoring
;	Summary, Penalty Summary, Player Stats / Playoff Stats, Crowd Meter, the
;	Timeout and goalie select menu items, and their helpers (SetupScreen,
;	ExitAttributeScreen2, ReadAttributeNibble ... WaitVSyncAndReadInput).
;	The screens are menu item handlers run from the pause menu.
;	Small text uses printz2 / printsmall. With OptLine set the line icon
;	entries come from MenuIconPosTable-6 (the bytes before
;	AttributeMenuTable). The crowd meter shows the arena / league records from
;	save RAM. Each DecompressGraphicsWithCallback is followed by its 8 byte
;	remap table.

ShowScores	;"Scores" screen: the other games of the night in gsstruct over the Scores bitmap
	;(ScoresMap); up / down scroll, start exits (ExitAttributeScreen2). Menu item handler (menu lists)
	moveq	#6,d0
	moveq	#$1A,d1
	bsr.w	SetupScreen
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),5,0
	moveq	#$1E,d0
	moveq	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP3),$E,3,'Scores',-(TXPRI+TXMAP3),$B,1
	movea.l	#ScoresMap,a1
	lea	8(a1),a2
	adda.l	4(a1),a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d5
	jsr	(dobitmap).l
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,2,4,0
	clr.w	(VertLineScrolling).w
	bsr.w	UpdateVertScrollReg
	jsr	(GetShifter).l
	move.w	d1,d3	;d3 = games - 1 (GetShifter)
	ble.w	.skip
.game
	bsr.w	DisplayGameInfo
	dbf	d3,.game
.skip
	clr.w	(SelectedPlayerIdx).w
	move.w	(printy).w,d0
	subi.w	#$15,d0
	bmi.w	.loop
	asl.w	#3,d0
	move.w	d0,(SelectedPlayerIdx).w	;scroll limit
	bsr.w	DrawScrollArrows
.loop
	bsr.w	vcountwait
	bsr.w	getpzjoy
	btst	#7,d3
	bne.w	ExitAttributeScreen2
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set
	move.w	d0,(PlayerScrollCtr).w
.scroll
	bsr.w	UpdatePlayerScroll
	bra.s	.loop
UpdatePlayerScroll	;Called every frame by ShowScores: add PlayerScrollCtr to VertLineScrolling (0 ... SelectedPlayerIdx), stop
	;on a 24 line boundary (DrawScrollArrows). Falls into UpdateVertScrollReg
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss8
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtss8
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss8
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divu.w	#$18,d0
	swap	d0
	tst.w	d0
	bne.w	UpdateVertScrollReg
	bsr.w	DrawScrollArrows
	clr.w	(PlayerScrollCtr).w
UpdateVertScrollReg	;VSRAM word 1 = VertLineScrolling - $30
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#VSRAM_W+(2<<16),Vctrl-Vdata(a0)
	move.w	#$FFD0,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts
DisplayGameInfo	;Print game d3 of gsstruct (16 bytes each; not the current game gamenum, not one with flag bit 1 or 2 set)
	;the two teams and scores (PrintGameInfo) and the period (PerLabels)
	cmp.w	(gamenum).w,d3
	beq.w	rtss8
	moveq	#$10,d0
	mulu.w	d3,d0
	movea.w	#(gsstruct-M68K_RAM),a0
	adda.w	d0,a0
	btst	#1,$E(a0)
	bne.w	rtss8
	btst	#2,$E(a0)
	bne.w	rtss8
	move.w	2(a0),d0
	move.w	$C(a0),d1
	bsr.w	PrintGameInfo
	addq.w	#1,(printy).w
	move.w	(a0),d0
	move.w	$A(a0),d1
	bsr.w	PrintGameInfo
	move.w	8(a0),d0
	subq.w	#1,d0
	movea.l	#PerLabels,a1
	move.w	#$1C,(printx).w
	jsr	(PrintStringFromList).l
	addq.w	#2,(printy).w
	rts
PrintGameInfo	;Print team d0's name (TeamList, $30E) at x 6 and score d1 (2 digits) at x $18
	movea.w	#$30E,a1
	asl.w	#2,d0
	movea.l	0(a1,d0.w),a1
	adda.w	4(a1),a1
	move.w	#6,(printx).w
	jsr	(print).l
	move.w	#$18,(printx).w
	move.w	d1,d0
	moveq	#2,d1
	jsr	(PushNumberWidth).l
	jmp	print
DrawScrollArrows	;ShowScores up / down arrows (ScrollArrowTable). Saves d0-d1/a1
	movem.l	d0-d1/a1,-(sp)
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,3,4,6,CC_SetFont,1
	clr.w	d0
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1
	add.b	d1,d0
	add.b	d1,d0
	lea	ScrollArrowTable(pc),a1
	jsr	(PrintStringFromList).l
	movem.l	(sp)+,d0-d1/a1
	rts
ScrollArrowTable	;DrawScrollArrows Strings: none, up, down (only 3 entries)
	String	' ',$FB,$FF,$FA,$13,' ',$F9
	String	'{',$FB,$FF,$FA,$13,' ',$F9
	String	' ',$FB,$FF,$FA,$13,'}',$F9
LineEditor	;"Line Editor" screen for team a2: line slot cursor (TestList), C picks a player for the slot from the
	;list, start runs the exit menu (ExitAttributeScreen). OptLine (manual lines off) limits the cursor. Menu item handler
	bset	#0,tmflags(a2)
	moveq	#0,d0
	moveq	#$1C,d1
	bsr.w	SetupScreen
	clr.w	(DispAttribCtr).w
	clr.w	(PlayerScrollCtr).w
	move.w	#1,(TestList).w
LineEditorRedraw	;Clear the screen and redraw everything. Also entered from ExitAttributeScreen
	jsr	(printsmallz).l
	String	CC_SetMap,2,CC_SetX,0,CC_SetY
	moveq	#$28,d0
	moveq	#$1C,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	st	(redrawicons).w
	bsr.w	ClearMenuFlags
LineEditorMenu	;Slot cursor loop: start exits, C picks a player for the slot (SelectAttributeItem), up / down /
	;left / right move the slot cursor (LineCursorTable). Also entered from SelectAttributeItem when it is done
	bsr.w	DrawTeamScreen
	bsr.w	DrawAttributeMenu
.loop
	bsr.w	vcountwait
	bsr.w	getpzjoy
	jsr	(ProcessInputWithRepeat).l
	btst	#7,d1
	bne.w	ExitAttributeScreen
	btst	#5,d1
	bne.w	SelectAttributeItem	;C: pick a player for the slot
	moveq	#1,d0
	btst	#1,d1
	bne.w	.move
	moveq	#-1,d0
	btst	#0,d1
	bne.w	.move
	moveq	#8,d0
	btst	#3,d1
	bne.w	.move
	moveq	#$FFFFFFF8,d0
	btst	#2,d1
	beq.s	.loop
.move
	add.w	(TestList).w,d0
	tst.w	(OptLine).w
	beq.w	.set
	cmp.w	#1,d0
	blt.s	.loop
	cmp.w	#5,d0
	bgt.s	.loop
.set
	lea	LineCursorTable(pc),a0	;the slot after the move
	move.b	8(a0,d0.w),(TestList+1).w
	bsr.w	DrawAttributeMenu
	bra.s	.loop
SelectAttributeItem	;Line editor: C pressed on slot TestList. Build the list of players that can go in
	;the slot in Satt (roster order is goalies, forwards, defense) and let the user pick one (left / right pages the attribute columns). C
	;stores the pick with UpdatePlayerAttribute, start goes back. Both return to LineEditorMenu
	bsr.w	ReadAttributeNibble
	move.w	d0,d1
	bsr.w	ProcessNibble
	move.w	(TestList).w,d2
	andi.w	#7,d2
	cmp.w	#2,d2
	bgt.w	.n
	add.w	d0,d1
	bsr.w	GetPlayerCount
	sub.w	d1,d0
.n
	subq.w	#1,d0
	move.w	d0,(screentimer).w
	clr.w	(PlayerScrollCtr).w
	clr.w	(VertLineScrolling).w
	movea.w	#(Satt-M68K_RAM),a0
	clr.w	d2
.fill
	move.b	d1,0(a0,d2.w)
	cmp.w	d1,d6
	bne.w	.nc
	move.w	d2,(VertLineScrolling).w
.nc
	addq.w	#1,d1
	addq.w	#1,d2
	dbf	d0,.fill
	bsr.w	ClearAttributeArea2
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,0,3,1,0
	moveq	#$12,d0
	moveq	#3,d1
	jsr	(Framer).l
	jsr	(printsmallz).l
	String	CC_SetX,$15,CC_SetY
	moveq	#$12,d0
	moveq	#3,d1
	jsr	(Framer).l
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,2,2,1,'{Select  Player}'
	clr.w	d0
	bra.w	.vert
.loop
	bsr.w	vcountwait
	bsr.w	getpzjoy
	jsr	(ProcessInputWithRepeat).l
	btst	#7,d1
	bne.w	LineEditorMenu
	btst	#5,d1
	bne.w	.pick
	moveq	#1,d0
	btst	#1,d1
	bne.w	.vert
	btst	#3,d1
	bne.w	.horz
	moveq	#-1,d0
	btst	#0,d1
	bne.w	.vert
	btst	#2,d1
	bne.w	.horz
	bra.s	.loop
.horz
	add.w	(DispAttribCtr).w,d0
	bmi.s	.loop
	move.w	d0,(DispAttribCtr).w
	bsr.w	PrintAttribHeader
.back
	bra.s	.loop
.vert
	add.w	(VertLineScrolling).w,d0
	bmi.s	.loop
	cmp.w	(screentimer).w,d0
	bgt.s	.loop
	move.w	d0,(VertLineScrolling).w
.first
	cmp.w	(PlayerScrollCtr).w,d0
.chkfirst
	bgt.w	.top
	move.w	d0,(PlayerScrollCtr).w
.top
	subq.w	#5,d0
	cmp.w	(PlayerScrollCtr).w,d0
	ble.w	.draw
	move.w	d0,(PlayerScrollCtr).w
.draw
	bsr.w	PrintAttribHeader
	bra.w	.loop
.pick
	movea.w	#(Satt-M68K_RAM),a3
	adda.w	(VertLineScrolling).w,a3
	move.b	(a3),d0
	addq.b	#1,d0
	move.w	(TestList).w,d2
	bsr.w	UpdatePlayerAttribute	;put the picked player in the slot
	bra.w	LineEditorMenu
PrintAttribHeader	;Line editor player list: the column header of attribute page DispAttribCtr, then 6 rows
	;of names and that attribute, the selected row highlighted
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),$16,1
.0
	movea.l	#PAttribColumns,a1
	move.w	(DispAttribCtr).w,d0
	bra.w	.2
.1
	adda.w	(a1),a1
	addq.w	#4,a1
.2
	tst.w	(a1)
	dbmi	d0,.1
	bpl.w	.3
	subq.w	#1,(DispAttribCtr).w
	bra.s	.0
.3
	jsr	(print).l
	move.l	(a1),d4
	movea.w	#(Satt-M68K_RAM),a3
	move.w	(PlayerScrollCtr).w,d2
	move.w	(screentimer).w,d1
	sub.w	d2,d1
	cmp.w	#5,d1
	bls.w	.4
	moveq	#5,d1
.4
	move.w	#2,(printy).w
.row
	jsr	(printsmallz).l
	String	CC_SetAttribute,4,CC_SetX,5,CC_AddY,1,'                      ',CC_SetX,5
	cmp.w	(VertLineScrolling).w,d2
	bne.w	.5
	move.w	d7,(printa).w
.5
	clr.w	d0
	move.b	0(a3,d2.w),d0
	bsr.w	GetNameandAttrib
	addq.w	#1,d2
	dbf	d1,.row
	rts
DrawAttributeMenu	;Line editor: draw the line icons for the cursor's line (AttributeMenuTable bit masks, DrawMenuIcon), then the selected player box
	moveq	#6,d5
	lea	AttributeMenuTable(pc),a0
	move.w	(TestList).w,d0
	lsr.w	#3,d0
	adda.w	d0,a0
	tst.w	(OptLine).w
	beq.w	.0
	subq.w	#1,a0
.0
	move.b	(a0),d0
	cmp.b	(redrawicons).w,d0
	beq.w	.1
	move.b	d0,(redrawicons).w
	bsr.w	ClearAttributeArea
.1
	btst	d5,(redrawicons).w
	beq.w	.2
	bsr.w	DrawMenuIcon
.2
	dbf	d5,.1
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,2,8,7,CC_SetFont,1
	moveq	#$18,d0
	moveq	#3,d1
	jsr	(Framer).l
	jsr	(printsmallz).l
	String	CC_SetX,$15,CC_SetY,8
	move.w	d6,d0
	jsr	(getname).l
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	move.w	d7,(printa).w
	jsr	(printsmall).l
	clr.w	(printfontset).w
	rts
	dc.b	1	;the entry before AttributeMenuTable (read with OptLine set)
AttributeMenuTable	;Per line: bit mask of the lines drawn together
	dc.b	7,7,7,$18,$18,$60,$60
DrawMenuIcon	;Line editor: draw line d5 (its name from linelist, then its player slots) at MenuIconPosTable (OptLine: the entry before)
	moveq	#6,d0
	mulu.w	d5,d0
	lea	MenuIconPosTable(pc),a0
	adda.w	d0,a0
	tst.w	(OptLine).w
	beq.w	.0
	subq.w	#6,a0
.0
	move.w	(a0),(printx).w
	move.w	2(a0),(printy).w
	move.w	d5,d0
	movea.l	#linelist,a1
	move.w	#$8000,(printa).w
	jsr	(PrintStringFromList).l
	jsr	(printsmallz).l
	String	' Line'
	move.w	(a0),(printx).w	
	move.w	d5,d4
	asl.w	#3,d4
	addq.w	#1,d4
	move.w	2(a0),(printy).w
	move.w	4(a0),d3
	lea	$16A(a2),a3
.1
	move.w	(a0),(printx).w
	jsr	(printsmallz).l
	String	CC_AddX,$FF,CC_AddY,2,CC_SetAttribute,6
	clr.w	d0
	move.b	0(a3,d4.w),d0
	subq.w	#1,d0
	jsr	(FormatPlayerNameShort).l
	cmp.w	(TestList).w,d4
	bne.w	.2
	move.w	d0,d6
	move.w	(printa).w,d7
	move.w	#2,(printfontset).w
.2
	jsr	(printsmall).l
	clr.w	(printfontset).w
	addq.w	#1,d4
	dbf	d3,.1
	rts
ClearAttributeArea	;Line editor: erase the line area and print the position header (LD RD LW C RW)
	jsr	(printsmallz).l
	String	CC_SetMap,2,CC_SetX,0,CC_SetY,$A
.erase
	moveq	#$28,d0
	moveq	#$12,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	move.w	(MenuIconPosTable+2).l,(printy).l
	move.w	(MenuIconPosTable).l,(printx).l
	tst.w	(OptLine).w
	beq.w	.0
	move.w	(MenuIconPosTable-6).l,(printx).l
.0
	jsr	(printsmallz).l
	dc.w	$0022	;String length: too many arguments for the String macro
	dc.b	$FE,4,$FB,$FD,$FA,2,'LD',$FB,$FE,$FA,2,'RD',$FB,$FE,$FA,2,'LW',$FB,$FE,$FA,2,'C ',$FB,$FE,$FA,2,'RW'
	rts
DrawTeamScreen	;Line editor background: bitmap (ScoutMap), frame, "Line Editor" title and the team logo map (PrintTeamData)
	bsr.w	ClearAttributeArea2
	movem.l	d0-d5/a0-a2,-(sp)
	jsr	(printz).l
	String	-TXMAP3,0,0
	movea.l	#ScoutMap,a1
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
	String	-(TXPRI+TXMAP2),$A,4,'Line  Editor',-(TXPRI+TXMAP2),$E,1
	clr.w	d0
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	PrintTeamData
	move.w	#$2C,d0
	bra.w	PrintTeamData
ClearAttributeArea2	;Erase 40 x 10 at the top of map 2
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	moveq	#$28,d0
	moveq	#$A,d1
	move.w	#$7FF,d2
	jmp	eraser
ClearMenuFlags	;Clear palfadenew+$5A and palfadenew+$7A
	clr.w	(palfadenew+$5A).w
	clr.w	(palfadenew+$7A).w
	rts
	;MenuIconPosTable-6: the line icon entry used with OptLine set (x, y, slot count - 1)
	dc.w	$10,$C,4
MenuIconPosTable	;Line icons: x, y, slot count - 1 per line
	dc.w	4,$C,4
	dc.w	$10,$C,4
	dc.w	$1C,$C,4
	dc.w	4,$C,4
	dc.w	$10,$C,4
	dc.w	4,$C,3
	dc.w	$10,$C,3
	dc.w	$FFFF
LineCursorTable	;The slot after a cursor move: indexed by slot + 8 (up / down / left / right)
	dc.b	1,1,2,3,4,5,$19,1
	dc.b	1,1,2,3,4,5,$19,1
	dc.b	9,9,$A,$B,$C,$D,$21,1
	dc.b	$11,$11,$12,$13,$14,$15,$21,1
	dc.b	5,$19,$1A,$1B,$1C,$1D,$29,1
	dc.b	$D,$21,$22,$23,$24,$25,$31,1
	dc.b	$1D,$29,$2A,$2B,$2C,$2C,1,1
	dc.b	$25,$31,$32,$33,$34,$34,1,1
	dc.b	$25,$31,$32,$33,$34,$34,1,1
ExitAttributeScreen	;Line editor: start pressed. Run the exit menu (AttributeScreenText, or ExitAttribText when
	;databuffer holds another team), then redraw the editor or leave (ExitAttributeScreen2)
	bsr.w	ClearMenuFlags
	move.w	#$18,(palcount).w
	move.l	(menuitem).w,-(sp)
	move.l	(menulist).w,-(sp)
	move.l	(menudraw).w,-(sp)
	movea.l	#rtss2,a1
	movea.l	#AttributeScreenText,a0
	movea.w	#(databuffer-M68K_RAM),a3
	move.w	Xvel(a2),d0
	addq.w	#1,d0
	cmp.b	(a3),d0
	beq.w	.0
	movea.l	#ExitAttribText,a0
.0
	jsr	(printsmallz).l
	String	CC_SetMap,2
	bsr.w	InitMenuState
.1
	bsr.w	vcountwait
	bsr.w	getpzjoy
	jsr	(ProcessInputWithRepeat).l
	move.w	d1,-(sp)
	bsr.w	HandleMenuInput
	move.w	(sp)+,d1
	andi.w	#$A0,d1
	beq.s	.1
	jsr	(printsmallz).l
	String	CC_SetFont
	move.w	(menuitem).w,d0
	move.l	(sp)+,(menudraw).w
	move.l	(sp)+,(menulist).w
	move.l	(sp)+,(menuitem).w
	tst.w	d0
	bne.w	LineEditorRedraw
	bra.w	ExitAttributeScreen2
UpdatePlayerAttribute	;Put player d0 (1 based) in line slot d2 of team a2; if he is already in another slot of the same line, the old occupant of d2 moves there (swap)
	movem.l	d0-d2/a0-a1,-(sp)
	lea	$16A(a2),a0
	move.w	d2,d1
	andi.w	#$FFF8,d1
	lea	0(a0,d1.w),a1
	moveq	#5,d1
.0
	cmp.b	1(a1,d1.w),d0
	dbeq	d1,.0
	bne.w	.1
	move.b	0(a0,d2.w),1(a1,d1.w)
.1
	move.b	d0,0(a0,d2.w)
	movem.l	(sp)+,d0-d2/a0-a1
	rts
DecodePlayerAttributes	;Load team a2's lines from databuffer: byte 0 = team + 1, then one nibble
	;per slot in AttributeOffsetTbl order, relative to the first forward (or defenseman for slots 1-2). Menu item handler
	movem.l	d0-d4/a0/a3,-(sp)
	movea.w	#(databuffer-M68K_RAM),a0
	addq.w	#1,a0
	bsr.w	ReadAttributeNibble
	move.w	d0,d1
	bsr.w	ProcessNibble
	move.w	d0,d3
	movea.l	#AttributeOffsetTbl,a3
	clr.w	d4
	clr.w	d2
.next
	move.b	(a3),d2
	bmi.w	.done
	bchg	#0,d4
	bne.w	.hi
	move.b	(a0),d0
	bra.w	.nib
.hi
	move.b	(a0)+,d0
	lsr.w	#4,d0
.nib
	andi.w	#$F,d0
	add.b	d1,d0
	andi.w	#7,d2
	cmp.w	#2,d2
	bgt.w	.store
	add.b	d3,d0
.store
	addq.b	#1,d0
	andi.w	#$FF,d0
	move.b	(a3)+,d2
	bsr.w	UpdatePlayerAttribute
	bra.s	.next
.done
	movem.l	(sp)+,d0-d4/a0/a3
	rts
EncodePlayerAttributes	;Reverse of DecodePlayerAttributes: pack team a2's lines into databuffer and convert it (WriteLineData, high ROM). Menu item handler
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	#(databuffer-M68K_RAM),a0
	move.w	Xvel(a2),d0
	addq.w	#1,d0
	move.b	d0,(a0)+
	lea	$16A(a2),a1
	bsr.w	ReadAttributeNibble
	move.w	d0,d1
	bsr.w	ProcessNibble
	movea.l	#AttributeOffsetTbl,a3
	clr.w	d4
	clr.w	d2
.next
	move.b	(a3)+,d2
	bmi.w	.done
	move.b	0(a1,d2.w),d3
	subq.b	#1,d3
	sub.b	d1,d3
	andi.w	#7,d2
	cmp.w	#2,d2
	bgt.w	.pack
	sub.b	d0,d3
.pack
	bchg	#0,d4
	bne.w	.hi
	move.b	d3,(a0)
	bra.s	.next
.hi
	asl.b	#4,d3
	or.b	d3,(a0)+
	bra.s	.next
.done
	jsr	(WriteLineData).l
	movem.l	(sp)+,d0-d4/a0-a3
	rts
AttributeOffsetTbl	;Line slots saved in databuffer ($FF ends)
	dc.b	1,2,3,4,5
	dc.b	9,$A,$B,$C,$D
	dc.b	$11,$12,$13,$14,$15
	dc.b	$19,$1A,$1B,$1C,$1D
	dc.b	$21,$22,$23,$24,$25
	dc.b	$29,$2A,$2B,$2C,$31
	dc.b	$32,$33,$34,$FF
TeamRosterScreen	;"Team Roster" screen for team a2: pages of players (DisplayPlayerList: goalies, then the lines),
	;left / right attribute column, A switches teams, start exits. Menu item handler
	moveq	#$D,d0
	moveq	#$17,d1
	bsr.w	SetupScreen
	moveq	#1,d0
	add.w	tmline(a2),d0
	move.w	d0,(SelectedPlayerIdx).w
	clr.w	(DispAttribCtr).w
.redraw
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),7,1
	moveq	#$1A,d0
	moveq	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP3),9,4,'Team  Roster',-(TXPRI+TXMAP3),$E,1
	clr.w	d0
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.home
	move.w	#$2C,d0
.home
	bsr.w	PrintTeamData
.header
	jsr	(printsmallz).l
	dc.w	$0034	;String length: too many arguments for the String macro
	dc.b	$F8,6,3,2,$C,$F9,1,'Pos.^Player',$FD,$1E,$FC,$C,'Rating',$FD,$C,$FC,$1A,'A^-^Switch^Teams',$F9,0
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),1,8
	moveq	#$12,d0
	moveq	#3,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),$15,8
	moveq	#$12,d0
	moveq	#3,d1
	jsr	(Framer).l
	bsr.w	DisplayPlayerList
	move.w	(SelectedPlayerIdx).w,d0
	mulu.w	#$80,d0
	move.w	d0,(VertLineScrolling).w
	bsr.w	UpdatePlayerListScroll
	clr.w	(PlayerScrollCtr).w
.loop
	bsr.w	vcountwait
.pad
	bsr.w	getpzjoy
.repeat
	jsr	(ProcessInputWithRepeat).l
.start
	btst	#7,d3
	bne.w	ExitAttributeScreen2
.abut
	btst	#6,d1
.chka
	bne.w	.team
	jsr	(nodiag).l
	moveq	#1,d0
.right
	btst	#3,d1
.chkright
	bne.w	.col
	neg.w	d0
	btst	#2,d1
	bne.w	.col
	tst.w	(PlayerScrollCtr).w
	bne.w	.scroll
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set
	move.w	d0,(PlayerScrollCtr).w
.scroll
	bsr.w	CheckPlayerListScroll
	bra.s	.loop
.col
	add.w	(DispAttribCtr).w,d0
	bmi.s	.scroll
	move.w	d0,(DispAttribCtr).w
	bsr.w	DisplayPlayerList
	bra.s	.scroll
.team
	lea	tmsize(a2),a2
	cmpa.w	#(AwShots-M68K_RAM),a2
	beq.w	.redraw
	movea.w	#(tmstruct-M68K_RAM),a2
	bra.w	.redraw
CheckPlayerListScroll	;TeamRosterScreen per frame: add PlayerScrollCtr to VertLineScrolling (0 ... $380)
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss8
	add.w	(VertLineScrolling).w,d0
	bmi.w	StopPlayerListScroll
	cmp.w	#$380,d0
	bgt.w	StopPlayerListScroll
UpdatePlayerListScroll	;Set VertLineScrolling = d0. Stop on a page boundary ($80), draw the page coming into view, VSRAM = VertLineScrolling - $70
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$80,d0
	swap	d0
	tst.w	d0
	bne.w	.0
	clr.w	(PlayerScrollCtr).w
.0
	andi.w	#$7F,d1
	bne.w	.2
	cmp.w	#$7E,d0
	bne.w	.1
	bsr.w	DisplayPlayerListUp
.1
	cmp.w	#2,d0
	bne.w	.2
	bsr.w	DisplayPlayerListDown
.2
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#VSRAM_W+(2<<16),Vctrl-Vdata(a0)
	move.w	#$FF90,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts
StopPlayerListScroll	;Out of range: stop scrolling
	clr.w	(PlayerScrollCtr).w
	rts
DisplayPlayerListUp	;d0 = divs result (quotient in the high word): draw that page
	move.l	d0,-(sp)
	swap	d0
	move.w	d0,(SelectedPlayerIdx).w
	bsr.w	DisplayPlayerList
	move.l	(sp)+,d0
	rts
DisplayPlayerListDown	;Draw the page after the quotient in the high word of d0
	move.l	d0,-(sp)
	swap	d0
	addq.w	#1,d0
	move.w	d0,(SelectedPlayerIdx).w
	bsr.w	DisplayPlayerList
	move.l	(sp)+,d0
	rts
DisplayPlayerList	;Draw roster page SelectedPlayerIdx (0 goalies, 1-7 lines): title (PlayerStatMenuTxt), column header, then
	;the rows (GoalieRowText / PlayerPositionText, getNameandAttrib)
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,7,3,2,9,CC_SetFont,1
	move.w	(SelectedPlayerIdx).w,d0
	lea	PlayerStatMenuTxt(pc),a1
	jsr	(AdvanceStringPtr).l
	jsr	(printsmall).l
	jsr	(printsmallz).l
	String	CC_SetX,$16,CC_SetY,9
.0
	movea.l	#PAttribColumns,a1
	move.w	(DispAttribCtr).w,d0
	tst.w	(SelectedPlayerIdx).w
	bne.w	.2
	movea.l	#GAttribColumns,a1
	bra.w	.2
.1
	adda.w	(a1),a1
	addq.w	#4,a1
.2
	tst.w	(a1)
	dbmi	d0,.1
	bpl.w	.3
	subq.w	#1,(DispAttribCtr).w
	bra.s	.0
.3
	jsr	(printsmall).l
	move.l	(a1),d4
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,2,0,0,CC_SetFont,0
	btst	#0,(SelectedPlayerIdx+1).w
	beq.w	.4
	addi.w	#$10,(printy).w
.4
	move.w	(printy).w,-(sp)
	moveq	#$28,d0
	moveq	#$10,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	move.w	(sp)+,(printy).w
	bsr.w	ReadAttributeNibble
	move.w	d0,d1
	subq.w	#1,d1
	movea.l	#GoalieRowText,a5
	movea.w	#(Satt-M68K_RAM),a3
	move.l	#$1020304,(a3)
	move.w	(SelectedPlayerIdx).w,d0
	subq.w	#1,d0
	bmi.w	.5
	asl.w	#3,d0
	lea	$16A(a2),a3
	lea	1(a3,d0.w),a3
	movea.l	#PlayerPositionText,a5
	moveq	#4,d1
	cmpi.w	#5,(SelectedPlayerIdx).w
	ble.w	.5
	subq.w	#1,d1
.5
	move.w	#2,(printx).w
	movea.l	a5,a1
	jsr	(print).l
	movea.l	a1,a5
	move.w	#7,(printx).w
	clr.w	d0
	move.b	(a3)+,d0
	subq.w	#1,d0
	bsr.w	GetNameandAttrib
	addq.w	#2,(printy).w
	dbf	d1,.5
	rts
GoalieRowText	;Position text for the goalie rows
	String	'G'
	String	'G'
	String	'G'
	String	'G'
PlayerStatMenuTxt	;Roster page titles; { } are the left / right arrows
	String	'    Goalies    }'
	String	'{  Scoring  1  }'
	String	'{  Scoring  2  }'
	String	'{   Checking   }'
	String	'{ Power Play 1 }'
	String	'{ Power Play 2 }'
	String	'{Penalty Kill 1}'
	String	'{Penalty Kill 2 '
GetNameandAttrib	;Print player d0's name, then at x $1E the column d4 picks (attribjmp; above 2 a rating through CalcAttrib, high ROM). Saves d0-d4/a0-a1/a4-a5
	movem.l	d0-d4/a0-a1/a4-a5,-(sp)
	pea	.x(pc)
	jsr	(getname).l
	jsr	(print).l
	move.w	#$1E,(printx).w
	cmp.w	#2,d4
	bls.w	.jump
	jsr	(CalcAttrib).l
	swap	d4
.jump
	lea	attribjmp(pc),a0
	adda.w	0(a0,d4.w),a0
	jmp	(a0)
.x
	movem.l	(sp)+,d0-d4/a0-a1/a4-a5
	rts
attribjmp	;getNameandAttrib column handlers, offsets from attribjmp
	dc.w	AttribStatus-attribjmp
	dc.w	AttribEnergy-attribjmp
	dc.w	AttribHanded-attribjmp
	dc.w	AttribWeight-attribjmp
	dc.w	AttribFighting-attribjmp
	dc.w	AttribRating-attribjmp
AttribStatus	;Player d0's status word at $66(a2): Ice, Bench, injured, or penalty time
	add.w	d0,d0	;jump for status
	move.w	tmpdst(a2,d0.w),d0
	bpl.w	.pen
	not.w	d0
	cmp.w	#3,d0
	bls.w	.st
	moveq	#1,d0
	bra.w	.st
.inj
	moveq	#3,d0
.st
	lea	StatusTextTbl(pc),a1
	jmp	PrintStringFromList
.pen
	btst	#$C,d0
	bne.s	.inj
	subq.w	#1,(printx).w
	move.w	d0,d1
	andi.w	#$FFF,d0
	jsr	(PushTime).l
	jsr	(print).l
	moveq	#4,d0
	bclr	#$E,d1
	beq.w	.t
	moveq	#5,d0
.t
	lea	StatusTextTbl(pc),a1
	jmp	PrintStringFromList
StatusTextTbl	;AttribStatus Strings
	String	'Ice     '
	String	'Bench   '
	String	'Injury P'
	String	'Injury G'
	String	'    '
	String	' C  '
AttribEnergy	;Energy: word $32(a2) / 40, at most 100 (AttribPrintPct)
	add.w	d0,d0	;jump for energy
	move.w	tmpde(a2,d0.w),d0
	ext.l	d0
	divu.w	#$28,d0
	cmp.w	#$64,d0
	ble.w	AttribPrintPct
	moveq	#$64,d0
	bra.w	AttribPrintPct
AttribFighting	;Bit 0 of the nibble is the handedness: drop it, then a rating out of d1 - 1
	andi.w	#$E,d0	;jump for fighting attrib - ignore bit 0 (remove Handedness)
	subq.w	#1,d1	;sub 1 from d1
AttribRating	;d0 * 100 / d1, adjusted (AttribAdjust, high ROM); falls into AttribPrintPct
	mulu.w	#$64,d0	;'d'   ; mult by 100 dec
	divu.w	d1,d0	;divide by d1 (usually 100 dec)
	jsr	(AttribAdjust).l
AttribPrintPct	;Print d0 4 wide, then 4 blanks
	moveq	#4,d1
	jsr	(PushNumberWidth).l
	jsr	(print).l
	jsr	(printz).l
	String	'    '
	rts
AttribHanded	;Bit 0 of the sum: Righty / Lefty (HandedTextTbl)
	andi.w	#1,d0
	eori.w	#1,d0
	lea	HandedTextTbl(pc),a1
	jmp	PrintStringFromList
HandedTextTbl	;AttribHanded Strings
	String	'Righty  '
	String	'Lefty   '
AttribWeight	;Weight: 140 + 8 * rating lb
	asl.w	#3,d0	;jump for weight - mult by 8
	addi.w	#$8C,d0	;add 140 lbs (minimum weight)
	jsr	(PushNumber).l
	jsr	(print).l
	jsr	(printz).l
	String	' lb  '
	rts
ScoringSummaryScreen	;"Scoring Summary": one 4 row entry per goal (6 bytes each from ScoreSum), scrolled with up / down, start exits. Menu item handler
	moveq	#$A,d0
	moveq	#$1A,d1
	bsr.w	SetupScreen
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),4,1
	moveq	#$20,d0
	moveq	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP3),6,4,'Scoring Summary',-(TXPRI+TXMAP3),7,1
	move.w	#$2C,d0
	bsr.w	PrintTeamData
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PrintTeamData
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,6,3,0,8,CC_SetFont,1,'^Per^^Time^^Tm^^Goal/Assist^^^^^^^^P/S^^',CC_SetFont,0
	clr.l	d0
	move.w	(ScoreSumbytes).w,d0
	divu.w	#6,d0
	asl.w	#5,d0
	move.w	d0,(VertLineScrolling).w
	subi.w	#$80,d0
	bpl.w	.0
	clr.w	d0
.0
	move.w	d0,(SelectedPlayerIdx).w
	move.w	(VertLineScrolling).w,d0
.1
	bsr.w	vcountwait
	bsr.w	UpdateGameStatScroll
	move.w	(VertLineScrolling).w,d0
	subq.w	#2,d0
	cmp.w	(SelectedPlayerIdx).w,d0
	bge.s	.1
	clr.w	(PlayerScrollCtr).w
.loop
	bsr.w	vcountwait
	bsr.w	getpzjoy
	btst	#7,d3
	bne.w	ExitAttributeScreen2
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set
	move.w	d0,(PlayerScrollCtr).w
.scroll
	bsr.w	CheckGameStatScroll
	bra.s	.loop
CheckGameStatScroll	;ScoringSummaryScreen per frame: add PlayerScrollCtr to VertLineScrolling (0 ... SelectedPlayerIdx). Falls into UpdateGameStatScroll
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss8
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtss8
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss8
UpdateGameStatScroll	;Set VertLineScrolling = d0. Stop on an entry boundary (32 lines; arrows by DrawScrollArrowsPenalty)
	;draw the entry coming into view, VSRAM = VertLineScrolling - $50
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$20,d0
	swap	d0
	tst.w	d0
	bne.w	.0
	bsr.w	DrawScrollArrowsPenalty
	clr.w	(PlayerScrollCtr).w
.0
	andi.w	#$1F,d1
	bne.w	.2
	move.l	d0,-(sp)
	cmp.w	#$1E,d0
	bne.w	.1
	bsr.w	DisplayGameStatLineUp
.1
	move.l	(sp)+,d0
	cmp.w	#2,d0
	bne.w	.2
	bsr.w	DisplayGameStatLineDown
.2
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#VSRAM_W+(2<<16),Vctrl-Vdata(a0)
	moveq	#$FFFFFFB0,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts
DisplayGameStatLineUp	;Draw goal entry (d0 high word) at the top of the window
	move.l	d0,-(sp)
	swap	d0
	moveq	#6,d3
	mulu.w	d0,d3
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0
	subq.w	#3,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DisplayGameStatEntry
	move.l	(sp)+,d0
	rts
DisplayGameStatLineDown	;Draw goal entry (d0 high word) + 4 at the bottom of the window
	move.l	d0,-(sp)
	swap	d0
	addq.w	#4,d0
	moveq	#6,d3
	mulu.w	d0,d3
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0
	addi.w	#$10,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DisplayGameStatEntry
	move.l	(sp)+,d0
	rts
DisplayGameStatEntry	;Print ScoreSum entry d3: time, team (bit 7 of byte 2 = away), goal type (GoalTypeTbl), scorer and the two assists (PrintPeriodTime)
	move.w	(printy).w,-(sp)
	moveq	#$28,d0
	moveq	#4,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	move.w	(sp)+,(printy).w
	movea.w	#(ScoreSum-M68K_RAM),a0
	move.w	0(a0,d3.w),d0
	move.w	#1,(printx).w
	jsr	(FormatAndPrintTime).l
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#7,2(a0,d3.w)
	beq.w	.0
	adda.w	#tmsize,a2
.0
	movea.l	tmdata(a2),a1
	adda.w	4(a1),a1
	adda.w	(a1),a1
	move.w	#$C,(printx).w
	jsr	(print).l
	move.w	#$23,(printx).w
	lea	GoalTypeTbl(pc),a1
	move.b	2(a0,d3.w),d0
	andi.w	#$7F,d0
	jsr	(PrintStringFromList).l
	move.w	#$10,(printx).w
	move.b	3(a0,d3.w),d0
	bsr.w	PrintPeriodTime
	move.w	#$E000,(printa).w
	move.w	#$12,(printx).w
	move.b	4(a0,d3.w),d0
	bsr.w	PrintPeriodTime
	move.w	#$12,(printx).w
	move.b	5(a0,d3.w),d0
PrintPeriodTime	;Print player d0 (byte, negative = none) and go down a row
	ext.w	d0
	bmi.w	.0
	jsr	(FormatPlayerNameWithAttrib).l
	jsr	(print).l
.0
	addq.w	#1,(printy).w
	rts
GoalTypeTbl	;ScoreSum byte 2 & $7F: SH2, SH, even, PP, PP2
	String	'SH2'
	String	'SH'
	String	' '
	String	'PP'
	String	'PP2'
PenaltySummaryScreen	;"Penalty Summary": one 3 row entry per penalty (4 bytes each from PenSum, PenSumLength
	;bytes), scrolled as ScoringSummaryScreen. Menu item handler
	moveq	#$A,d0
	moveq	#$19,d1
	bsr.w	SetupScreen
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),4,1
	moveq	#$20,d0
	moveq	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP3),5,4,'Penalty  Summary',-(TXPRI+TXMAP3),7,1
	move.w	#$2C,d0
	bsr.w	PrintTeamData
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PrintTeamData
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,6,3,0,8,CC_SetFont,1,'^Per^^Time^^Tm^^Player/Penalty^^^^min^^^',CC_SetFont,0
	clr.l	d0
	move.w	(PenSumLength).w,d0
	lsr.w	#2,d0
	mulu.w	#$18,d0
	move.w	d0,(VertLineScrolling).w
	subi.w	#$78,d0
	bpl.w	.0
	clr.w	d0
.0
	move.w	d0,(SelectedPlayerIdx).w
	move.w	(VertLineScrolling).w,d0
.1
	bsr.w	vcountwait
	bsr.w	UpdatePenaltyScroll
	move.w	(VertLineScrolling).w,d0
	subq.w	#2,d0
	cmp.w	(SelectedPlayerIdx).w,d0
	bge.s	.1
	clr.w	(PlayerScrollCtr).w
.loop
	bsr.w	vcountwait
	bsr.w	getpzjoy
	btst	#7,d3
	bne.w	ExitAttributeScreen2
	moveq	#-2,d0
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set
	move.w	d0,(PlayerScrollCtr).w
.scroll
	bsr.w	CheckPenaltyScroll
	bra.s	.loop
CheckPenaltyScroll	;PenaltySummaryScreen per frame: add PlayerScrollCtr to VertLineScrolling (0 ... SelectedPlayerIdx). Falls into UpdatePenaltyScroll
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss8
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtss8
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss8
UpdatePenaltyScroll	;Set VertLineScrolling = d0. Stop on an entry boundary (24 lines), draw the entry coming into view, VSRAM = VertLineScrolling - $50
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	ext.l	d0
	divs.w	#$18,d0
	swap	d0
	tst.w	d0
	bne.w	.0
	bsr.w	DrawScrollArrowsPenalty
	clr.w	(PlayerScrollCtr).w
.0
	ext.l	d1
	divs.w	#$18,d1
	swap	d1
	tst.w	d1
	bne.w	.2
	move.l	d0,-(sp)
	cmp.w	#$16,d0
	bne.w	.1
	bsr.w	DisplayPenaltyLineUp
.1
	move.l	(sp)+,d0
	cmp.w	#2,d0
	bne.w	.2
	bsr.w	DisplayPenaltyLineDown
.2
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#VSRAM_W+(2<<16),Vctrl-Vdata(a0)
	move.w	#$FFB0,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts
DisplayPenaltyLineUp	;Draw penalty entry (d0 high word) at the top of the window
	move.l	d0,-(sp)
	swap	d0
	move.w	d0,d3
	asl.w	#2,d3
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0
	subq.w	#2,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DisplayPenaltyEntry
	move.l	(sp)+,d0
	rts
DisplayPenaltyLineDown	;Draw penalty entry (d0 high word) + 5 at the bottom of the window
	move.l	d0,-(sp)
	swap	d0
	addq.w	#5,d0
	move.w	d0,d3
	asl.w	#2,d3
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	move.w	(VertLineScrolling).w,d0
	lsr.w	#3,d0
	addi.w	#$F,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	bsr.w	DisplayPenaltyEntry
	move.l	(sp)+,d0
	rts
DisplayPenaltyEntry	;Print PenSum entry d3: time, team (bit 7 of byte 2 = away), minutes and name from Penaltylist, player (byte 3)
	move.w	(printy).w,-(sp)
	moveq	#$28,d0
	moveq	#3,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	move.w	(sp)+,(printy).w
	movea.w	#(PenSum-M68K_RAM),a0
	move.w	0(a0,d3.w),d0
	move.w	#1,(printx).w
	jsr	(FormatAndPrintTime).l
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#7,2(a0,d3.w)
	beq.w	.0
	adda.w	#tmsize,a2
.0
	movea.l	tmdata(a2),a1
	adda.w	4(a1),a1
	adda.w	(a1),a1
	move.w	#$C,(printx).w
	jsr	(print).l
	move.b	2(a0,d3.w),d0
	andi.w	#$7F,d0
	movea.l	#Penaltylist,a3
	adda.w	0(a3,d0.w),a3
	clr.w	d0
	move.b	1(a3),d0
	jsr	(PushNumber).l
	move.w	#$23,(printx).w
	jsr	(print).l
	move.w	#$10,(printx).w
	clr.w	d0
	move.b	3(a0,d3.w),d0
	jsr	(FormatPlayerNameWithAttrib).l
	jsr	(print).l
	addq.w	#1,(printy).w
	move.w	#$13,(printx).w
	move.w	#$E000,(printa).w
	lea	2(a3),a1
	jmp	(print).l
DrawScrollArrowsPenalty	;Summary screen up / down arrows (ScrollArrowTbl). Saves d0-d1/a1. Also used by UpdateGameStatScroll
	movem.l	d0-d1/a1,-(sp)
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,3,4,9,CC_SetFont,1
	clr.w	d0
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1
	add.b	d1,d0
	add.b	d1,d0
	lea	ScrollArrowTbl(pc),a1
	jsr	(PrintStringFromList).l
	movem.l	(sp)+,d0-d1/a1
	rts
ScrollArrowTbl	;None, up, down, both
	String	' ',$FB,$FF,$FA,$11,' ',$F9
	String	'{',$FB,$FF,$FA,$11,' ',$F9
	String	' ',$FB,$FF,$FA,$11,'}',$F9
	String	'{',$FB,$FF,$FA,$11,'}',$F9
DisplayTeamStats	;"Playoff Stats": the playoff totals (ReadTeamStats) of the potreeteam team as DisplayAttributeScreen with d7 = 1. Called and the menu lists
	movem.l	a2,-(sp)
	jsr	(ReadTeamStats).l
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d0
	move.b	0(a0,d0.w),d0
	movea.w	#(tmstruct-M68K_RAM),a2
	cmp.w	Xvel(a2),d0
	beq.w	.0
	adda.w	#tmsize,a2
.0
	moveq	#1,d7
	bsr.w	DisplayAttributeScreen
	movem.l	(sp)+,a2
	rts
PlayerStatsScreen	;"Player Stats": DisplayAttributeScreen with d7 = 0 (this game). Menu item handler
	clr.w	d7
DisplayAttributeScreen	;Stats screen for team a2, d7 = 0 game / 1 playoff: the column headers, the players sorted by the
	;selected column (left / right), up / down scroll, A switches teams (game stats only), start exits
	moveq	#$D,d0
	moveq	#$16,d1
	bsr.w	SetupScreen
	clr.w	(DispAttribCtr).w
	clr.w	(VertLineScrolling).w
.redraw
	clr.w	(PlayerScrollCtr).w
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),5,1
	moveq	#$1E,d0
	moveq	#6,d1
	jsr	(Framer).l
	tst.w	d7
	beq.w	.title
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP3),7,4,'Playoff  Stats',-(TXPRI+TXMAP3),$E,1
	bra.w	.team
.title
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,6,3,$C,$1A,CC_SetFont,1,'A^-^Switch^Teams',CC_SetFont,0
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP3),8,4,'Player  Stats',-(TXPRI+TXMAP3),$E,1
.team
	clr.w	d0
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.home
	move.w	#$2C,d0
.home
	bsr.w	PrintTeamData
	bsr.w	DisplayAttributeMenu
	bsr.w	DrawScrollArrowsAttribute
.loop
	bsr.w	vcountwait
	bsr.w	getpzjoy
	btst	#7,d3
	bne.w	ExitAttributeScreen2
	btst	#6,d1
	bne.w	.switch
	bsr.w	nodiag
	moveq	#1,d0
.right
	btst	#3,d1
	bne.w	.col
	neg.w	d0
	btst	#2,d1
	bne.w	.col
	moveq	#-2,d0
.updown
	btst	#0,d3
	bne.w	.set
	neg.w	d0
	btst	#1,d3
	beq.w	.scroll
.set
	move.w	d0,(PlayerScrollCtr).w
.scroll
	bsr.w	UpdateAttributeScroll
	bra.s	.loop
.col
	add.w	(DispAttribCtr).w,d0
	cmp.w	#$FFFF,d0
	blt.s	.scroll
	cmp.w	#4,d0
	bgt.s	.scroll
	move.w	d0,(DispAttribCtr).w
	bsr.w	DisplayAttributeMenu
	bsr.w	DrawScrollArrowsAttribute
	bra.s	.scroll
.switch
	tst.w	d7
	bne.s	.scroll
	lea	tmsize(a2),a2
	cmpa.w	#(AwShots-M68K_RAM),a2
	beq.w	.redraw
	movea.w	#(tmstruct-M68K_RAM),a2
	bra.w	.redraw
UpdateAttributeScroll	;Stats screen per frame: scroll 0 ... SelectedPlayerIdx, stop on a 16 line boundary, draw the row coming into view
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss8
	add.w	(VertLineScrolling).w,d0
	bmi.w	rtss8
	cmp.w	(SelectedPlayerIdx).w,d0
	bgt.w	rtss8
	move.w	(VertLineScrolling).w,d1
	move.w	d0,(VertLineScrolling).w
	andi.w	#$F,d0
	bne.w	.0
	bsr.w	DrawScrollArrowsAttribute
	clr.w	(PlayerScrollCtr).w
.0
	andi.w	#$F,d1
	bne.w	SetAttribScrollReg
	move.w	d0,-(sp)
	cmp.w	#$E,d0
	bne.w	.1
	bsr.w	DisplayAttributeLineUp
.1
	move.w	(sp)+,d0
	cmp.w	#2,d0
	bne.w	SetAttribScrollReg
	bsr.w	DisplayAttributeLineDown
SetAttribScrollReg	;VSRAM = VertLineScrolling - $68
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	movea.l	#VDP_DATA,a0
	move.l	#VSRAM_W+(2<<16),Vctrl-Vdata(a0)
	move.w	#$FF98,d0
	add.w	(VertLineScrolling).w,d0
	move.w	d0,(a0)
	move.w	(sp)+,(disflags).w
	rts
DisplayAttributeLineUp	;Draw the top row of the window
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3
	bra.w	DisplayAttributeEntry
DisplayAttributeLineDown	;Draw the row below the window
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3
	addq.w	#6,d3
	bra.w	DisplayAttributeEntry
DisplayAttributeMenu	;Stats screen: column headers (sort column highlighted), the title of the sort column
	;(AttributeTitleTxt), then the players sorted by it into Satt and the rows drawn
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,6,3,4,$B,CC_SetFont,1,'Player',CC_AddX,7
	lea	AttributeMenuTxt(pc),a1
	moveq	#5,d3
	tst.w	(DispAttribCtr).w
	bmi.w	.0
	adda.w	(a1),a1
	clr.w	d3
.0
	move.w	#$8000,(printa).w
	cmp.w	(DispAttribCtr).w,d3
	bne.w	.1
	move.w	#$C000,(printa).w
.1
	jsr	(printsmall).l
	addq.w	#1,d3
	cmp.w	#5,d3
	blt.s	.0
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,3,9,7
	moveq	#$16,d0
	moveq	#3,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-(TXPRI+TXPAL3+TXMAP3),$A,8
	lea	AttributeTitleTxt(pc),a1
	moveq	#1,d0
	add.w	(DispAttribCtr).w,d0
	jsr	(PrintStringFromList).l
	clr.w	(printfontset).w
	movea.w	#(Satt-M68K_RAM),a3
	clr.l	d6
	tst.w	(DispAttribCtr).w
	bpl.w	.2
	bsr.w	ReadAttributeNibble
	bset	d0,d6
	subq.w	#1,d6
	not.l	d6
.2
	moveq	#-1,d4
	st	d5
	bsr.w	GetPlayerCount
	bra.w	.6
.3
	btst	d0,d6
	bne.w	.6
	clr.w	d2
	move.w	(DispAttribCtr).w,d1
	bmi.w	.4
	bsr.w	CheckAttributeValid
.4
	ext.l	d2
	asl.l	#8,d2
	movea.l	tmdata(a2),a1
	adda.w	(a1),a1
	move.w	d0,d1
	subq.w	#8,a1
.5
	addq.w	#8,a1
	adda.w	(a1),a1
	dbf	d1,.5
	move.b	#$FF,d2
	sub.b	(a1),d2
	cmp.l	d4,d2
	ble.w	.6
	move.l	d2,d4
	move.w	d0,d5
.6
	dbf	d0,.3
	bset	d5,d6
	move.b	d5,(a3)+
	bpl.s	.2
	moveq	#5,d0
.7
	st	0(a3,d0.w)
	dbf	d0,.7
	move.w	a3,d0
	subi.w	#$C01E,d0
	bpl.w	.8
	clr.w	d0
.8
	asl.w	#4,d0
	move.w	d0,(SelectedPlayerIdx).w
	cmp.w	(VertLineScrolling).w,d0
	bcc.w	.9
	move.w	d0,(VertLineScrolling).w
.9
	moveq	#5,d4
.ent
	move.w	(VertLineScrolling).w,d3
	lsr.w	#4,d3
	add.w	d4,d3
	bsr.w	DisplayAttributeEntry
	dbf	d4,.ent
	bra.w	SetAttribScrollReg
DisplayAttributeEntry	;Stats screen row d3 of Satt: rank, name, then the 5 columns, or for goalies saves, shots and save %
	movea.w	#(Satt-M68K_RAM),a4
	adda.w	d3,a4
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	add.w	d3,d3
	andi.w	#$1F,d3
	move.w	d3,(printy).w
	moveq	#$28,d0
	moveq	#1,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	tst.b	(a4)
	bmi.w	rtss8
	subq.w	#1,(printy).w
	move.w	#1,(printx).w
	move.w	a4,d0
	subi.w	#$C017,d0
	moveq	#2,d1
	move.w	#$E000,(printa).w
	jsr	(PushNumberWidth).l
	jsr	(print).l
	clr.w	d0
	move.b	(a4),d0
	jsr	(FormatPlayerName).l
	addq.w	#1,(printx).w
	move.w	#$8000,(printa).w
	jsr	(print).l
	move.w	#$11,(printx).w
	tst.w	(DispAttribCtr).w
	bmi.w	.goalie
	clr.w	d5
.0
	clr.w	d0
	move.b	(a4),d0
	move.w	d5,d1
	bsr.w	CheckAttributeValid
	move.w	d2,d0
	moveq	#4,d1
	jsr	(PushNumberWidth).l
	move.w	#$8000,(printa).w
	cmp.w	(DispAttribCtr).w,d5
	bne.w	.1
	move.w	#$C000,(printa).w
.1
	jsr	(print).l
	addq.w	#1,d5
	cmp.w	#5,d5
	bne.s	.0
	bra.w	.x
.goalie
	clr.w	d0
	move.b	(a4),d0
	moveq	#3,d1
	bsr.w	GetAttributeValue2
	clr.w	d0
	move.b	(a4),d0
	moveq	#0,d1
	move.w	d2,-(sp)
	bsr.w	GetAttributeValue2
	move.w	(sp)+,d0
	move.w	d0,d3
	sub.w	d2,d0
	bpl.w	.2
	clr.w	d0
.2
	move.w	d0,d2
	moveq	#4,d1
	jsr	(PushNumberWidth).l
	addq.w	#1,(printx).w
	jsr	(print).l
	move.w	d3,d0
	moveq	#4,d1
	jsr	(PushNumberWidth).l
	addq.w	#2,(printx).w
	jsr	(print).l
	tst.w	d3
	beq.w	.3
	mulu.w	#$64,d2
	divu.w	d3,d2
.3
	move.w	d2,d0
	moveq	#4,d1
	jsr	(PushNumberWidth).l
	addq.w	#2,(printx).w
	jsr	(print).l
	jsr	(printz).l
	String	'%'
.x
	rts
CheckAttributeValid	;d2 = stat column d1 for player d0. Goalies only have PIM (btst d1,#6 picks the columns kept)
	move.w	d0,-(sp)
	bsr.w	ReadAttributeNibble
	move.w	d0,d2
	move.w	(sp)+,d0
	cmp.w	d2,d0
	bge.w	GetAttributeValue2
	clr.w	d2
	btst	d1,#6	;written as btst Dn,#imm
	beq.w	rtss8
	moveq	#1,d1
GetAttributeValue2	;d2 = stat column d1 for player d0. d7 = 0: the team struct byte arrays (AttributeOffsetTbl2); d7 = 1: the playoff tables (GetStatsValue)
	tst.w	d7
	bne.w	.stats
	lea	AttributeOffsetTbl2(pc),a1
	asl.w	#2,d1
	adda.w	d1,a1
	move.w	(a1),d1
	add.w	d0,d1
	clr.w	d2
	move.b	0(a2,d1.w),d2
	move.w	2(a1),d1
	bmi.w	rtss8
	add.w	d0,d1
	clr.w	d3
	move.b	0(a2,d1.w),d3
	add.w	d3,d2
	rts
.stats
	asl.w	#2,d1
	add.w	d0,d0
	clr.w	d2
	bsr.w	GetStatsValue
	addq.w	#2,d1
	bsr.w	GetStatsValue
	lsr.w	#1,d0
	rts
GetStatsValue	;d2 += word d0 of the RAM table at StatsOffsetTbl2+d1 (0 = none)
	movea.l	#StatsOffsetTbl2,a1
	tst.w	0(a1,d1.w)
	beq.w	rtss8
	movea.w	0(a1,d1.w),a1
	add.w	0(a1,d0.w),d2
	rts
StatsOffsetTbl2	;Playoff stat RAM tables per column (G, A, G+A, SOG, PIM)
	dc.w	$CD96,0,$CDCA,0,$CD96,$CDCA,$CDFE,0,$CE32,0
AttributeOffsetTbl2	;Team struct byte arrays per column, same order
	dc.w	$B4,$FFFF,$CE,$FFFF,$B4,$CE,$E8,$FFFF,$102,$FFFF
AttributeMenuTxt	;Stats screen column headers (goalie header, then 5 columns)
	String	'Saves Shots Save %  '
	String	'   G'
	String	'   A'
	String	' Pts'
	String	' SOG'
	String	' PIM'
AttributeTitleTxt	;the lea in DisplayAttributeMenu. Sort column titles
	String	'    Goalie Saves   ]'
	String	'[      Goals       ]'
	String	'[     Assists      ]'
	String	'[      Points      ]'
	String	'[  Shots On Goal   ]'
	String	'[ Penalty Minutes   '
DrawScrollArrowsAttribute	;Stats screen up / down arrows (ScrollArrowTbl2). Saves d0-d1/a1
	movem.l	d0-d1/a1,-(sp)
	jsr	(printsmallz).l
	String	CC_SetMapAndPosition,4,3,2,$B,CC_SetFont,1
	clr.w	d0
	move.w	(VertLineScrolling).w,d1
	tst.w	d1
	sgt	d0
	neg.b	d0
	cmp.w	(SelectedPlayerIdx).w,d1
	slt	d1
	neg.b	d1
	add.b	d1,d0
	add.b	d1,d0
	lea	ScrollArrowTbl2(pc),a1
	jsr	(PrintStringFromList).l
	movem.l	(sp)+,d0-d1/a1
	rts
ScrollArrowTbl2	;None, up, down, both
	String	' ',$FB,$FF,$FA,$C,' ',$F9
	String	'{',$FB,$FF,$FA,$C,' ',$F9
	String	' ',$FB,$FF,$FA,$C,'}',$F9
	String	'{',$FB,$FF,$FA,$C,'}',$F9
CrowdMeterScreen	;"Crowd Meter": current, average and peak level (DisplayGameStats), plus the arena and league
	;records; start exits. Menu item handler
	moveq	#9,d0
	moveq	#$1C,d1
	bsr.w	SetupScreen
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),6,1
	moveq	#$1C,d0
	moveq	#6,d1
	bsr.w	Framer
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP3),9,4,'Crowd  Meter',-(TXPRI+TXMAP3),7,1
	move.w	#$2C,d0
	bsr.w	PrintTeamData
	addq.w	#4,(printx).w
	clr.w	d0
	bsr.w	PrintTeamData
	bsr.w	DisplayGameStats
.loop
	bsr.w	WaitVSyncAndReadInput
	btst	#7,d1
	bne.w	ExitAttributeScreen2
	bra.s	.loop
DisplayGameStats	;Crowd meter rows: CwdExciteLvl, the average (SumCwdExciteLvl / NumCwdExciteLvl) and MaxCwdExciteLvl
	;in dB (FormatPercentage). With save RAM (ValidSRAM) the arena record of HomeTeam and the league record, read into the buffer
	;at ThreeStars by ReadCrowdRecord (high ROM); 0 reads as $50
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,4,2,4,$C,'Current Level',CC_SetX,$1C
	move.w	(CwdExciteLvl).w,d0
	bsr.w	FormatPercentage
	bsr.w	printsmallz
	String	CC_SetX,4,CC_AddY,2,'Average Level',CC_SetX,$1C
	move.l	(SumCwdExciteLvl).w,d0
	divu.w	(NumCwdExciteLvl).w,d0
	bsr.w	FormatPercentage
	bsr.w	printsmallz
	String	CC_SetX,4,CC_AddY,2,'Peak Level',CC_SetX,$1C
	move.w	(MaxCwdExciteLvl).w,d0
	bsr.w	FormatPercentage
	movem.l	d0-d7/a0-a6,-(sp)
	tst.w	(ValidSRAM).w
	bmi.w	.x
	move.w	(HomeTeam).w,d1
	ext.l	d1
	movea.l	#ThreeStars,a0
	jsr	(ReadCrowdRecord).l
	move.b	8(a0),d0
	bne.w	.gotarena
	move.b	#$50,d0
.gotarena
	andi.w	#$FF,d0
	move.w	d0,-(sp)
.arena
	bsr.w	printsmallz
	String	CC_SetX,4,CC_AddY,2,'Arena Record',CC_SetX,$1C
	move.w	(sp)+,d0
	move.w	#3,d1
	jsr	(PushNumberWidth).l
	jsr	(print).l
.arenadb
	jsr	(printz).l
	String	' dB'
.league
	jsr	(GetLeagueCrowdRecord).l
	move.w	d0,d1
	ext.l	d1
	movea.l	#ThreeStars,a0
	jsr	(ReadCrowdRecord).l
	move.b	8(a0),d0
	bne.w	.gotleague
	move.w	#$50,d0
.gotleague
	andi.w	#$FF,d0
	move.w	d0,-(sp)
	bsr.w	printsmallz
	String	CC_SetX,4,CC_AddY,2,'League Record',CC_SetX,$1C
	move.w	(sp)+,d0
.leaguew
	move.w	#3,d1
.leaguenum
	jsr	(PushNumberWidth).l
	jsr	(print).l
	bsr.w	printz
	String	' dB'
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
FormatPercentage	;Print crowd level d0 as sqrt(d0 * 4) + 65 " dB"
	ext.l	d0
	asl.w	#2,d0
	bsr.w	sroot
	addi.w	#$41,d0
	moveq	#3,d1
	jsr	(PushNumberWidth).l
	bsr.w	print
	bsr.w	printz
	String	' dB'
	rts
SetupScreen	;Common start of the stats screens: blank, 40 cell mode, the framer and small font tiles, the background bitmap (ScoutMap) from row d0, d1 rows high
	movem.l	d0-d1/a2,-(sp)
	bsr.w	forceblack
	bclr	#0,(disflags).w
	move.w	(disflags).w,-(sp)
.noint
	bset	#2,(disflags).w
	move.w	(VSPRITES).w,d0
	bsr.w	Vmaddr
	move.l	#0,(a0)
.vdpregs
	move.w	#VDPR_MODE4+$81,Vctrl-Vdata(a0)
	move.w	#6,(Map3col1).w
	move.w	#VDPR_HSCROLL,Vctrl-Vdata(a0)
	clr.w	d0
	bsr.w	Vmaddr
	move.l	#0,(a0)
	move.w	(sp)+,(disflags).w
	bclr	#1,(disflags).w
	move.w	(framercset).w,d4
	movea.l	#FramerMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$91234567,$89ABCDEF	;remap table
	move.w	(smallfontchars).w,d4
	jsr	(AddSmallFont).l
	bsr.w	printz
	String	-(TXPRI+TXMAP3),0,0
	movea.l	#ScoutMap,a1
	adda.l	4(a1),a1
	movea.w	#$30A,a2
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#1,d4
	moveq	#0,d5
	bsr.w	dobitmap
	bsr.w	printz
	String	-TXMAP3,0,0
	movem.l	(sp),d0-d1/a2
	add.w	d0,(printy).w
	movea.l	#ScoutMap,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	move.w	d1,d3
	sub.w	d0,d3
	move.w	d0,d1
	clr.w	d0
	moveq	#$28,d2
	moveq	#$D,d5
	bsr.w	dobitmap
	move.w	d4,(smallfont2chars).w
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$D1234567,$89ABCDEF	;remap table
	bsr.w	printz
	String	-TXMAP2,0,0
	moveq	#$40,d0
	moveq	#$20,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	move.w	#$18,(palcount).w
	movem.l	(sp)+,d0-d1/a2
	rts
ExitAttributeScreen2	;Leave a stats screen: blank, then ReloadRinkGraphics
	bsr.w	forceblack
ReloadRinkGraphics	;after the forceblack: back to 32 cell mode and reload the rink (Rinktiles or RevRinkTiles in a reverse angle
	;replay), font, framer, EASN and team graphics. Falls out through setplayercolors. Also called from the replay code
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	move.w	(VSCRLPM).w,d0
	bsr.w	Vmaddr
	move.l	#0,(a0)
	move.w	#$8D00,d0
	move.b	(VSCRLPM).w,d0
	lsr.b	#2,d0
	move.w	d0,Vctrl-Vdata(a0)
	move.w	#VDPR_MODE4,Vctrl-Vdata(a0)
	move.w	#5,(Map3col1).w
	move.w	(sp)+,(disflags).w
	bset	#1,(disflags).w
	move.w	(rinkvrcset).w,d4
	movea.l	#Rinktiles,a2	;load rink address
	btst	#4,(sflags4).w	;check if reverse angle replay
	beq.w	.load	;branch if not
	movea.l	#RevRinkTiles,a2	;load reverse rink address
.load
	bsr.w	DoDMA_clearCallbackPointer
	jsr	(LoadHomeTeamGfx).l
	move.w	(smallfontchars).w,d4
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$43434567,$89ABCDEF	;remap table
	move.w	(framercset).w,d4
	jsr	(AddFramer).l
	jsr	(setupEASNmap).l
	jsr	(ReloadEnergyBarTiles).l
	jsr	(ReloadCrowdTiles).l
	jsr	(setupIceRinkMap).l
	jmp	setplayercolors
TimeoutMenu	;Pause menu "Timeout" for team a2: switch the menu to PauseText2, show the team name, rest both teams
	;(RestoreTeamEnergy), wait $78 frames (waitx). Menu item handler
	subq.w	#1,(menuitem).w
	subq.w	#1,(menuitem+2).w
	move.l	#PauseText2,(menulist).l
	bset	#2,tmflags(a2)
	bsr.w	printz
	String	-(TXPRI+TXMAP3),5,$C
	moveq	#$16,d0
	moveq	#6,d1
	bsr.w	Framer
	bsr.w	printz
	String	-(TXPRI+TXMAP3),$C,$E,'Timeout',-(TXPRI+TXMAP3),$11,$F
	movea.l	tmdata(a2),a1
	adda.w	4(a1),a1
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	print
	movea.w	#(tmstruct-M68K_RAM),a2
	jsr	(RestoreTeamEnergy).l
	adda.w	#$364,a2
	jsr	(RestoreTeamEnergy).l
	moveq	#$78,d0
	bra.w	waitx
SelectGoalieMenu	;it in TimeoutMenu's String. Pick team a2's goalie (or no goalie) from a list (DisplayPlayerSelectMenu)
	;with up / down, C or start; sets $26(a2) and SetPersonel. Menu item handler
	move.w	(menuitem).w,-(sp)
	move.w	(menuitem+2).w,-(sp)
	bsr.w	ReadAttributeNibble
	move.w	d0,(menuitem+2).w
	bsr.w	printz
	String	-(TXPRI+TXMAP3),4,$C
	moveq	#$18,d0
	moveq	#3,d1
	add.w	(menuitem+2).w,d1
	bsr.w	Framer
	move.w	tmgoalie(a2),d0
	bpl.w	.0
	moveq	#-1,d0
.0
	addq.w	#1,d0
	move.w	d0,(menuitem).w
.loop
	bsr.w	DisplayPlayerSelectMenu
.pad
	bsr.w	WaitVSyncAndReadInput
	btst	#7,d1
	bne.w	.done
	btst	#5,d1
	bne.w	.done
	btst	#1,d1
	beq.w	.up
	move.w	(menuitem).w,d0
	addq.w	#1,d0
	cmp.w	(menuitem+2).w,d0
	bgt.s	.loop
	move.w	d0,(menuitem).w
.up
	btst	#0,d1
	beq.s	.loop
	subq.w	#1,(menuitem).w
	bpl.s	.loop
	clr.w	(menuitem).w
	bra.s	.loop
.done
	move.w	(menuitem).w,d0
	subq.w	#1,d0
	bpl.w	.set
	cmpi.w	#$FFFF,tmgoalie(a2)
	blt.w	.x
.set
	move.w	d0,tmgoalie(a2)
	jsr	(setpersonel).l
.x
	move.w	(sp)+,(menuitem+2).w
	move.w	(sp)+,(menuitem).w
	rts
DisplayPlayerSelectMenu	;Draw the goalie list, row menuitem highlighted, each goalie with his two digit number
	move.w	#$D,(printy).w
	move.w	(menuitem+2).w,d1
	moveq	#0,d0
.0
	move.w	#5,(printx).w
	move.w	#$A000,(printa).w
	cmp.w	(menuitem).w,d0
	bne.w	.1
	move.w	#$8000,(printa).w
.1
	bsr.w	printz
	String	'                      '
	tst.w	d0
	bne.w	.player
	move.w	#$B,(printx).w
	bsr.w	printz
	String	'no goalie'
	bra.w	.next
.player
	movea.l	tmdata(a2),a1
	adda.w	(a1),a1
	move.w	d0,d2
	subq.w	#1,d2
	bra.w	.3
.2
	adda.w	(a1),a1
	addq.w	#8,a1
.3
	dbf	d2,.2
	move.w	#8,(printx).w
	bsr.w	print
	move.b	(a1),d2
	lsr.b	#4,d2
	addi.b	#$30,d2
	move.b	d2,(TextBuffer).w
	move.b	(a1),d2
	andi.b	#$F,d2
	addi.b	#$30,d2
	move.b	d2,(TextBuffer+1).w
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#4,(a1)
	move.w	#5,(printx).w
	bsr.w	print
.next
	addq.w	#1,(printy).w
	addq.w	#1,d0
	dbf	d1,.0
	rts
ReadAttributeNibble	;d0 = goalies on team a2 (nibbles in the team data word at +$A)
	movem.l	d1/a0,-(sp)
	movea.l	tmdata(a2),a0
.word
	adda.w	$A(a0),a0
	move.w	(a0),d1
	clr.w	d0
.0
	addq.w	#1,d0
	asl.w	#4,d1
	bne.s	.0
	movem.l	(sp)+,d1/a0
	rts
GetDefenseStart	;d0 = goalies + forwards of team a2 (ReadAttributeNibble + ProcessNibble), the roster index of the
	;first defenseman (roster order is goalies, forwards, defense). Called from the high ROM player cards
	movem.l	a0,-(sp)
	bsr.s	ReadAttributeNibble
	move.w	d0,-(sp)
	movea.l	$1E(a2),a0
	adda.w	8(a0),a0
	move.b	3(a0),d0
	lsr.w	#4,d0
	andi.w	#$F,d0
	add.w	(sp)+,d0
	movem.l	(sp)+,a0
	rts
ProcessNibble	;d0 = forwards on team a2 (high nibble of team data byte 3 at +8)
	movem.l	a0,-(sp)
	movea.l	tmdata(a2),a0
	adda.w	8(a0),a0
	move.b	3(a0),d0
	lsr.w	#4,d0
	andi.w	#$F,d0
	movem.l	(sp)+,a0
	rts
GetPlayerCount	;d0 = players on team a2 (records until a length word of 2)
	movem.l	a0,-(sp)
	movea.l	tmdata(a2),a0
	adda.w	(a0),a0
	clr.w	d0
.loop
	addq.w	#1,d0
	adda.w	(a0),a0
	addq.w	#8,a0
	cmpi.w	#2,(a0)
	bne.s	.loop
	movem.l	(sp)+,a0
	rts
WaitVSyncAndReadInput	;Wait for vcount to change and for a new button press (d1)
	move.w	(vcount).w,d1
.rj0
	cmp.w	(vcount).w,d1
	beq.s	.rj0
	bsr.w	getpzjoy
	bsr.w	nodiag
	tst.b	d1
	beq.s	WaitVSyncAndReadInput
	rts
