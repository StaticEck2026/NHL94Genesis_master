;	New in 94: user records. This file lets players enter their names and shows the Record
;	Holders screen with the win, goal and save records kept in save RAM.

NameEntryScreen	;"NAME ENTRY" screen for the user records (own vblank VBlank_SetOptions): pick a name from the name log or enter a new one (NameLetterGrid ...
	;SkipOtherUserName). Called from UserNameEntry
	movem.l	d0-d7/a0-a6,-(sp)
	move	#$2700,sr
	move.w	#2,d4
	move.l	#VBlank_SetOptions,(vbint).w
	bclr	#0,(disflags).w
	bset	#2,(disflags).w
	bclr	#1,(disflags).w
	move.w	#0,(VSCRLPM).w
	move.w	#$B400,(VSPRITES).w
	move.w	#$B800,(VmMap3).w
	move.w	#5,(Map3col1).w
	move.w	#$C000,(VmMap2).w
	move.w	#6,(Map2col1).w
	move.w	#$E000,(VmMap1).w
	move.w	#6,(Map1col1).w
	move.w	#0,d0
	jsr	(setVram).l
	move	#$2500,sr
	jsr	(orjoy).l
	move.w	d4,(framercset).w
	movea.l	#FramerMap+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$91234567,$89ABCDEF	;remap table
	move.w	d4,(nameframechars).w
	movea.l	#FramerMap+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$91234560,$89ABCDEF	;remap table
	move.w	d4,(smallfontchars).w
	jsr	(AddSmallFont).l
	jsr	(printz).l
	String	-TXMAP1,0,0
	moveq	#$28,d0
	moveq	#$1C,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	jsr	(setupIceRinkPal).l
	jsr	(printz).l
	String	-TXMAP2,0,0
	movea.l	#ScoutMap,a0	;(and printz Strings)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2
	moveq	#$1C,d3
	moveq	#$D,d5
	jsr	(dobitmap).l
	move.w	d4,(homepicchars).w
	addi.w	#$24,d4
	move.w	d4,(logobox1chars).w
	movea.l	#LogoBoxMap+8,a2
	jsr	(DecompressGraphicsPlain).l
	move.w	d4,(BigFontChars).w
	movea.l	#BigFontMap+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$71234567,$89ABCDEF	;remap table
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$1F,6
	move.w	(HomeTeam).w,d0
	tst.w	(nameentryvis).w
	beq.w	.0
	move.w	(VisTeam).w,d0
.0
	movea.l	#TeamList,a1
	asl.w	#2,d0
	movea.l	0(a1,d0.w),a1
	adda.w	4(a1),a1
	move.w	(a1),d0
	subq.w	#2,d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	jsr	(print).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$1B,7
	move.w	#8,d0
	move.w	#8,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-(TXPRI+TXPAL3+TXMAP1),$1C,8
	move.w	(HomeTeam).w,d3
	tst.w	(nameentryvis).w
	beq.w	.1
	move.w	(VisTeam).w,d3
.1
	asl.w	#2,d3
	movea.l	#TeamLogoBitmaps,a0	;team logo maps
	movea.l	0(a0,d3.w),a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	asl.w	#3,d3
	movea.l	#TeamLogoPalettes,a0
	subi.w	#$40,d3
	adda.w	d3,a0
	adda.l	(a2)+,a1
	move.w	#6,d3
	move.w	#6,d2
	clr.w	d0
	clr.w	d1
	move.w	#4,d5
	move.w	(homepicchars).w,d4
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),2,0
	move.w	#$24,d0
	move.w	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP1),$A,2,'NAME  ENTRY'
	bsr.w	ReadNameLog
	clr.w	(namelogarrows).w
	move.w	#1,(namelogsel).w
	clr.w	d0
	bsr.w	SkipOtherUserName
	movea.l	#nameentrybuf,a1
	bsr.w	GetLogName
	bsr.w	PrintNameLog
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),7,6,'Name Log'
	move.w	#$18,(palcount).w
	bclr	#2,(disflags).w
	clr.w	d4
	bsr.w	SyncLetterCursor
	bsr.w	PrintNameCursor
	bsr.w	LetterGridPos
.2
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	jsr	(NameEntryFramer).l
	move.w	(sp)+,(printy).w
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	addq.w	#1,(printx).w
	bsr.w	PrintCurLetter
	move.w	#1,(cursoron).w
	bsr.w	NameLetterGrid
	clr.w	d0
	bra.w	.11
.loop
	bsr.w	GetNameLength
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),5,$12
	tst.w	(cursoron).w
	beq.w	.3
	movea.l	#nameentrybuf,a1
	bsr.w	PrintNameField
	bsr.w	PrintNamePrompt
.3
	bsr.w	MoveLogArrows
.loop2
	move.w	(vcount).w,d0
.loop3
	cmp.w	(vcount).w,d0
	beq.s	.loop3
	movem.w	d1,-(sp)
	move.w	(cont1team).w,d1
	subq.w	#1,d1
	cmp.w	(nameentryvis).w,d1
	movem.w	(sp)+,d1
	beq.w	.input
	jsr	(ReadJoy2).l
	tst.w	d1
	beq.s	.loop2
	bra.w	.5
.input
	jsr	(ReadJoy1).l
	tst.w	d1
	beq.s	.loop2
.5
	btst	#7,d1
	bne.w	.14
	tst.w	(cursoron).w
	bne.w	.6
	move.w	#1,d0
	btst	#1,d1
	bne.w	.7
	move.w	#$FFFF,d0
	btst	#0,d1
	bne.w	.7
	btst	#4,d1
	beq.w	.loop
	bsr.w	NameLetterGrid
	clr.w	d0
	bra.w	.7
.6
	moveq	#-1,d0
	btst	#6,d1
	bne.w	.11
	neg.w	d0
	btst	#5,d1
	bne.w	.11
	btst	#3,d1
	bne.w	.12
	neg.w	d0
	btst	#2,d1
	bne.w	.12
	moveq	#6,d0
	btst	#1,d1
	bne.w	.12
	neg.w	d0
	btst	#0,d1
	bne.w	.12
	btst	#4,d1
	beq.w	.loop
	bsr.w	NameLetterGrid
	bra.w	.loop
.7
	add.w	d0,(namelogsel).w
.loop4
	cmpi.w	#7,(namelogsel).w
	ble.w	.8
	move.w	#1,(namelogsel).w
.8
	tst.w	(namelogsel).w
	bne.w	.9
	move.w	#7,(namelogsel).w
.9
	bsr.w	SkipOtherUserName
	beq.s	.loop4
	movea.l	#nameentrybuf,a1
	bsr.w	GetLogName
	tst.w	(cursoron).w
	bne.w	.10
	jsr	(NameEntryHelp).l
	bra.w	.loop
.10
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),4,$13
	add.w	d4,(printx).w
	jsr	(printz).l
	String	'   '
	bsr.w	LetterGridPos
	moveq	#1,d2
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	jsr	(eraser).l
	move.w	(sp)+,(printy).w
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	addq.w	#1,(printx).w
	bsr.w	PrintCurLetter
	bsr.w	SyncLetterCursor
	move.w	d4,d0
	neg.w	d0
	bra.w	*+4
.11
	add.w	d4,d0
	cmp.w	#$B,d0
	bhi.w	.loop
	move.w	d0,d4
	bsr.w	PrintNameCursor
	movea.l	#nameentrybuf,a0
	clr.w	d0
	cmpi.b	#$2D,0(a0,d4.w)
	beq.w	.12
	move.b	0(a0,d4.w),d0
	ext.w	d0
	bsr.w	FindLetter
	sub.w	d5,d0
.12
	add.w	d5,d0
	cmp.w	#$1D,d0
	bhi.w	.loop
	move.w	d0,-(sp)
	bsr.w	LetterGridPos
	moveq	#1,d2
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	jsr	(eraser).l
	move.w	(sp)+,(printy).w
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	addq.w	#1,(printx).w
	bsr.w	PrintCurLetter
	move.w	(sp)+,d5
	bsr.w	LetterGridPos
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	tst.w	(cursoron).w
	beq.w	.13
	jsr	(NameEntryFramer).l
.13
	move.w	(sp)+,(printy).w
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	addq.w	#1,(printx).w
	bsr.w	PrintCurLetter
	movea.l	#nameentrybuf,a0
	movea.l	#LetterGrid,a1
	move.b	0(a1,d5.w),d0
	move.b	d0,0(a0,d4.w)
	bra.w	.loop
.14
	bsr.w	StoreUserName
	movem.l	(sp)+,d0-d7/a0-a6
	rts
NameLetterGrid	;Name entry: the letter grid ("D-Pad to a letter.", "C to select letter.", "A to go back.")
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),1,$14
	move.w	#$16,d0
	move.w	#7,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	bchg	#0,(cursoron+1).w
	bne.w	.1
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$19,$11
	movea.l	#LetterGrid,a0
	moveq	#4,d0
.loop
	moveq	#5,d1
	movea.l	#mesarea,a1
	move.w	#$E,(a1)+
.loop2
	move.b	(a0)+,(a1)+
	move.b	#$20,(a1)+
	dbf	d1,.loop2
	movea.w	#(mesarea-M68K_RAM),a1
	jsr	(print).l
	addq.w	#2,(printy).w
	subi.w	#$C,(printx).w
	dbf	d0,.loop
	jsr	(printz).l
	String	-TXMAP2,1,$14
	moveq	#$16,d0
	moveq	#7,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),2,$15,'D-Pad to a letter.'
	move.w	#2,(printx).w
	addq.w	#1,(printy).w
	move.w	(printx).w,-(sp)
	jsr	(printz).l
	String	'C to select letter.'
	move.w	(sp),(printx).w
	addq.w	#1,(printy).w
	jsr	(printz).l
	String	'A to go back.'
	move.w	(sp),(printx).w
	addq.w	#1,(printy).w
	jsr	(printz).l
	String	'B to cancel.'
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
.0
	jsr	(printz).l
	String	'START when done.'
.x
	movem.l	(sp)+,d0-d7/a0-a6
.x2
	rts
.1
	movea.l	#nameentrybuf,a1
.2
	bsr.w	GetLogName
	move.w	#0,(printx).w
.3
	move.w	#$F,(printy).w
	move.w	#$28,d0
.4
	move.w	#$D,d1
	move.w	#$7FF,d2
.5
	jsr	(eraser).l
.6
	jsr	(printz).l
	String	-TXMAP2,1,$14
	moveq	#$16,d0
	moveq	#7,d1
.7
	jsr	(Framer).l
	bsr.w	NameEntryHelp
	bra.s	.x
NameEntryHelp	;Name entry help text ("D-Pad up/down to move arrows.", "Press START to select name.", "Press B to edit.")
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),2,$15,'D-Pad up/down to    '
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),2,$16,'move arrows.        '
	move.w	#2,(printx).w
	move.w	(printx).w,-(sp)
	addq.w	#1,(printy).w
	jsr	(printz).l
	String	'Press START to      '
	addq.w	#1,(printy).w
	move.w	(sp),(printx).w
	jsr	(printz).l
	String	'select name.        '
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	jsr	(printz).l
	String	'Press B to edit.    '
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintNamePrompt	;Name entry: "Enter new name:" for an empty name log slot namelogsel, else "Select or replace:"
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(namelogsel).w,d0
	mulu.w	#$C,d0
	movea.l	#namelog,a0
	movea.l	#EnterNameTxt,a1
	tst.b	0(a0,d0.w)
	beq.w	.0
	movea.l	#SelectNameTxt,a1
.0
	jsr	(print).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
SyncLetterCursor	;Name entry: the letter grid cursor d5 = the grid index of the current letter (FindLetter), 0 when it is not in the grid
	movem.l	d0-d4/a0-a6,-(sp)
	move.b	(nameentrybuf).w,d0
	bsr.w	FindLetter
	cmp.w	#$1E,d0
	blt.w	.0
	clr.w	d5
	bra.w	.x
.0
	move.w	d0,d5
	movea.l	#LetterGrid,a0
	move.b	0(a0,d5.w),(nameentrybuf).w
.x
	movem.l	(sp)+,d0-d4/a0-a6
	rts
FindLetter	;d0 = index of letter d0 in LetterGrid, $1E when not found
	movem.l	d1-d3/a0-a6,-(sp)
	movea.l	#LetterGrid,a0
	move.b	d0,d1
	clr.w	d0
	move.w	#$1E,d3
.loop
	cmp.b	0(a0,d0.w),d1
	beq.w	.x
	addq.w	#1,d0
	dbf	d3,.loop
	move.w	#$1E,d0
.x
	movem.l	(sp)+,d1-d3/a0-a6
	rts
PrintNameCursor	;Name entry: the " < " cursor
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),4,$13
	add.w	d4,(printx).w
	tst.w	(cursoron).w
	beq.w	rtsNameCursor
	jsr	(printz).l
	String	' < '
rtsNameCursor	;The shared rts of PrintNameCursor
	rts
PrintCurLetter	;Name entry: print grid letter d5 (with the cursor on, cursoron)
	tst.w	(cursoron).w
	beq.s	rtsNameCursor
	movea.l	#ThreeStars,a1
	move.w	#4,(a1)
	move.b	#0,3(a1)
	movea.l	#LetterGrid,a0
	move.b	0(a0,d5.w),d0
	move.b	d0,2(a1)
	jmp	print
LetterGridPos	;Name entry: printx / printy of grid letter d5 (6 letters a row, 2 cells apart); d0 / d1 = 3 x 3 box
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$18,$10
	move.w	d5,d0
	ext.l	d0
	divu.w	#6,d0
	asl.w	#1,d0
	add.w	d0,(printy).w
	swap	d0
	asl.w	#1,d0
	add.w	d0,(printx).w
	moveq	#3,d0
	moveq	#3,d1
	rts
EnterNameTxt	dc.b	0	;PrintNamePrompt table
	dc.b	$18,$BF,2,$10,$20,$20
	dc.b	$45	;E
	dc.b	$6E	;n
	dc.b	$74	;t
	dc.b	$65	;e
	dc.b	$72	;r
	dc.b	$20
	dc.b	$6E	;n
	dc.b	$65	;e
	dc.b	$77	;w
	dc.b	$20
	dc.b	$6E	;n
	dc.b	$61	;a
	dc.b	$6D	;m
	dc.b	$65	;e
	dc.b	$3A	;:
	dc.b	$20,0
SelectNameTxt	dc.b	0	;PrintNamePrompt table
	dc.b	$18,$BF,2,$10
	dc.b	$53	;S
	dc.b	$65	;e
	dc.b	$6C	;l
	dc.b	$65	;e
	dc.b	$63	;c
	dc.b	$74	;t
	dc.b	$20
	dc.b	$6F	;o
	dc.b	$72	;r
	dc.b	$20
	dc.b	$72	;r
	dc.b	$65	;e
	dc.b	$70	;p
	dc.b	$6C	;l
	dc.b	$61	;a
	dc.b	$63	;c
	dc.b	$65	;e
	dc.b	$3A	;:
	dc.b	0
PrintNameLog	;Name entry: the "Name Log" list (PrintNameField, GetLogName)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(namelength).w,-(sp)
	move.w	(namelogsel).w,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),5,8
	move.w	#6,d7
	move.w	#1,(namelogsel).w
	movea.l	#TempBuffer,a1
.loop
	bsr.w	GetLogName
	move.w	(printx).w,-(sp)
	bsr.w	PrintNameField
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	addq.w	#1,(namelogsel).w
	dbf	d7,.loop
	move.w	(sp)+,(namelogsel).w
	move.w	(sp)+,(namelength).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
MoveLogArrows	;Name entry: when the name log selection namelogsel changed, erase the old ] [ arrows and print them at the new row (PrintLogArrows)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(namelogsel).w,d0
	cmp.w	(namelogarrows).w,d0
	beq.w	.x
	movea.l	#LogArrowsClrTxt,a1
	bsr.w	PrintLogArrows
	movea.l	#LogArrowsTxt,a1
	bsr.w	PrintLogArrows
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintLogArrows	;Name entry: print the two arrow Strings at a1 on name log row namelogarrows, then namelogarrows = namelogsel
	tst.w	(namelogarrows).w
	beq.w	.0
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),3,8
	move.w	(namelogarrows).w,d0
	subq.w	#1,d0
	add.w	d0,(printy).w
	move.l	a1,-(sp)
	jsr	(print).l
	movea.l	(sp)+,a1
	adda.w	(a1),a1
	move.w	#$12,(printx).w
	jsr	(print).l
.0
	move.w	(namelogsel).w,(namelogarrows).w
	rts
LogArrowsTxt	dc.b	0	;MoveLogArrows data
	dc.b	4
	dc.b	$5D	;]
	dc.b	0,0,4
	dc.b	$5B	;[
	dc.b	0
LogArrowsClrTxt	dc.b	0	;MoveLogArrows data
	dc.b	4,$20,0,0,4,$20,0
GetNameLength	;namelength = length of the name being entered (up to '-' or 0, at most 12)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#$B,d3
	movea.l	#nameentrybuf,a0
	clr.w	(namelength).w
.loop
	cmpi.b	#$2D,(a0)
	beq.w	.x
	tst.b	(a0)+
	beq.w	.x
	addq.w	#1,(namelength).w
	dbf	d3,.loop
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintNameField	;Name entry: print the 12 character name field from a1, '-' past the length namelength
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#ThreeStars,a0
	move.w	(namelength).w,d0
	move.w	#0,d3
	move.w	#$E,(a0)+
.loop
	move.b	0(a1,d3.w),d1
	cmp.w	(namelength).w,d3
	blt.w	.0
	move.b	#$2D,d1
.0
	move.b	d1,(a0)+
	addq.w	#1,d3
	cmp.w	#$C,d3
	blt.s	.loop
	movea.l	#ThreeStars,a1
	jsr	(print).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
LetterGrid	dc.b	$41	;Name entry data
	dc.b	$42	;B
	dc.b	$43	;C
	dc.b	$44	;D
	dc.b	$45	;E
	dc.b	$46	;F
	dc.b	$47	;G
	dc.b	$48	;H
	dc.b	$49	;I
	dc.b	$4A	;J
	dc.b	$4B	;K
	dc.b	$4C	;L
	dc.b	$4D	;M
	dc.b	$4E	;N
	dc.b	$4F	;O
	dc.b	$50	;P
	dc.b	$51	;Q
	dc.b	$52	;R
	dc.b	$53	;S
	dc.b	$54	;T
	dc.b	$55	;U
	dc.b	$56	;V
	dc.b	$57	;W
	dc.b	$58	;X
	dc.b	$59	;Y
	dc.b	$5A	;Z
	dc.b	$2E
	dc.b	$31	;1
	dc.b	$32	;2
	dc.b	$20
	dc.b	$2D	;-
	dc.b	0
NameEntryFramer	;Framer with the name entry frame tiles (nameframechars as framercset)
	move.w	(framercset).w,-(sp)
	move.w	(nameframechars).w,(framercset).w
	jsr	(Framer).l
	move.w	(sp)+,(framercset).w
	rts
GetLogName	;Copy name log entry namelogsel to a1 ('-' for empty), namelength = its length
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#namelog,a0
	move.w	(namelogsel).w,d2
	mulu.w	#$C,d2
	move.w	#0,(namelength).w
	move.w	#$B,d3
.loop
	move.b	0(a0,d2.w),d0
	beq.w	.0
	bra.w	.1
.0
	move.b	#$2D,d0
	subq.w	#1,(namelength).w
.1
	move.b	d0,(a1)+
	addq.w	#1,(namelength).w
	addq.w	#1,d2
	dbf	d3,.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts
StoreUserName	;Name entry: store the name in save RAM (WriteNameRecord, MakeSRAMChecksum)
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#namelog,a0
	move.w	(namelogsel).w,d0
	mulu.w	#$C,d0
	adda.w	d0,a0
	movea.l	#nameentrybuf,a1
	move.w	#$B,d4
.loop
	cmpi.b	#$2D,(a1)
	bne.w	.0
	move.b	#0,(a1)
.0
	move.b	(a1)+,d1
	cmp.b	(a0)+,d1
	bne.w	.1
	dbf	d4,.loop
	bra.w	.3
.1
	movea.l	#namelog,a0
	move.w	(namelogsel).w,d0
	mulu.w	#$C,d0
	adda.w	d0,a0
	movea.l	#nameentrybuf,a1
	move.w	#$B,d4
.loop2
	move.b	(a1)+,d1
	cmp.b	#$2D,d1
	bne.w	.2
	move.b	#0,d1
.2
	move.b	d1,(a0)+
	dbf	d4,.loop2
	bsr.w	WriteNameLog
	jsr	(WriteNameRecord).l
	jsr	(MakeSRAMChecksum).l
.3
	movea.l	#homeuser,a5
	tst.w	(nameentryvis).w
	beq.w	.4
	movea.l	#awayuser,a5
.4
	tst.b	(nameentrybuf).w
	bne.w	.5
	clr.w	(namelogsel).w
.5
	move.w	(namelogsel).w,(a5)
	movem.l	(sp)+,d0-d7/a0-a6
	rts
WriteNameRecord	;Write the name record (ReadSRAM / WriteSRAM)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#$2D7,d7
	moveq	#0,d0
	moveq	#4,d1
	movea.l	#ThreeStars,a0
	move.w	(namelogsel).w,d6
.loop
	clr.w	d5
	jsr	(ReadSRAM).l
	cmp.b	1(a0),d6
	bne.w	.0
	clr.b	1(a0)
	st	d5
.0
	cmp.b	3(a0),d6
	bne.w	.1
	clr.b	3(a0)
	st	d5
.1
	tst.w	d5
	beq.w	.2
	jsr	(WriteSRAM).l
.2
	addq.l	#4,d0
	dbf	d7,.loop
	move.w	#$1B,d7
	move.l	#$B60,d0
	moveq	#$10,d1
	movea.l	#ThreeStars,a0
	move.w	(namelogsel).w,d6
.loop2
	clr.w	d5
	jsr	(ReadSRAM).l
	cmp.b	1(a0),d6
	bne.w	.3
	clr.b	1(a0)
	st	d5
.3
	cmp.b	3(a0),d6
	bne.w	.4
	clr.b	3(a0)
	st	d5
.4
	cmp.b	5(a0),d6
	bne.w	.5
	clr.b	5(a0)
	st	d5
.5
	cmp.b	7(a0),d6
	bne.w	.6
	clr.b	7(a0)
	st	d5
.6
	cmp.b	9(a0),d6
	bne.w	.7
	clr.b	9(a0)
	st	d5
.7
	cmp.b	$B(a0),d6
	bne.w	.8
	clr.b	$B(a0)
	st	d5
.8
	tst.w	d5
	beq.w	.9
	jsr	(WriteSRAM).l
.9
	addi.l	#$10,d0
	dbf	d7,.loop2
	move.l	#$D20,d0
	move.w	(namelogsel).w,d3
	asl.w	#4,d3
	ext.l	d3
	add.l	d3,d0
	moveq	#$10,d1
	movea.l	#ThreeStars,a0
	jsr	(ReadSRAM).l
	move.l	a0,-(sp)
	move.w	#$F,d3
.loop3
	clr.b	(a0)+
	dbf	d3,.loop3
	movea.l	(sp)+,a0
	jsr	(WriteSRAM).l
	jsr	(MakeSRAMChecksum).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts

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
