;	Menu engine. This file runs the scrolling menu of the pause screen, including the Manual and
;	Auto Goalie item, and holds a few helpers for drawing team blocks and waiting for the screen.

InitMenuState	;Start a menu: a0 = item list, a1 = screen draw routine; selection and first shown item 0. Falls into
	;DrawMenuScreen. Called from PauseMode, and the stats code
	move.l	a0,(menulist).w	;item list
	move.l	a1,(menudraw).w	;draw routine
	clr.w	(menuitem).w	;selected item
	clr.w	(menuitem+2).w	;first item shown
DrawMenuScreen	;Call the draw routine, frame the menu box, print the items and fade in. Called from HandleMenuInput
	movea.l	(menudraw).w,a0
	jsr	(a0)
	jsr	(printsmallz).l
	String	CC_SetAttribute,4,CC_SetY,$C
	bsr.w	SetMenuPrintX
	moveq	#$16,d0	;22 wide
	moveq	#6,d1	;6 high
	jsr	(Framer).l
	bsr.w	UpdateMenuSelection
	move.w	#$18,(palcount).w	;fade in
	rts
SetMenuPrintX	;printx = the left edge of the menu box: 5 in 32 column mode, else 9
	move.w	#5,(printx).w
	btst	#df32c,(disflags).w	;df32c: 32 column mode on
	bne.w	rtss8
	addq.w	#4,(printx).w
	rts
HandleMenuInput	;Act on the pad bits d1 for the current menu: down / up move the selection, C runs the item's handler and
	;redraws the menu (not if the handler set sflags5 bit 1). Returns eq to leave the menu (start, or C on item 0), ne to stay. Called
	;from PauseMode, and the stats code
	btst	#7,d1	;sbut
	bne.w	.flip	;start: Z clear, flipped to eq
	btst	#1,d1	;dbut
	beq.w	.up
	addq.w	#1,(menuitem).w	;next lower item
	bra.w	UpdateMenuSelection
.up
	btst	#0,d1	;ubut
	beq.w	.sel
	subq.w	#1,(menuitem).w	;next higher item
	bra.w	UpdateMenuSelection
.sel
	btst	#5,d1	;cbut
	beq.w	.flip	;nothing: Z set, flipped to ne
	bsr.w	seta2
	move.w	(menuitem).w,d0	;find the handler of the selected item
	movea.l	(menulist).w,a0
	adda.w	(a0),a0
	adda.w	(a0),a0
	bra.w	.3
.next
	addq.w	#4,a0
.3
	adda.w	(a0),a0
	dbf	d0,.next
	movea.l	(a0),a0
	jsr	(a0)	;the handler of the selected item
	bclr	#1,(sflags5).w	;the handler drew its own screen
	bne.w	.noredraw
	bsr.w	DrawMenuScreen
.noredraw
	tst.w	(menuitem).w	;item 0 (resume) leaves the menu
	rts
.flip
	eori	#4,ccr	;invert Z
	rts
UpdateMenuSelection	;Clamp the selection, scroll the 4 rows shown and print the menu: title, the items (PrintMenuItem), the
	;selected item marked, { / } when there are items above / below. Called from DrawMenuScreen and HandleMenuInput
	move.w	(menuitem).w,d0
	bpl.w	.0
	clr.w	(menuitem).w	;no item above the first
	clr.w	d0
.0
	movea.l	(menulist).w,a0
	adda.w	(a0),a0
	adda.w	(a0),a0
	bra.w	.2
.next
	adda.w	(a0),a0
	addq.w	#4,a0
	tst.w	2(a0)	;negative: the last item
.2
	dbmi	d0,.next
	addq.w	#1,d0
	sub.w	d0,(menuitem).w	;no item below the last
	move.w	(menuitem).w,d0
	cmp.w	(menuitem+2).w,d0
	bge.w	.3
	move.w	d0,(menuitem+2).w	;scroll up
.3
	subq.w	#3,d0
	cmp.w	(menuitem+2).w,d0
	ble.w	.print
	move.w	d0,(menuitem+2).w	;scroll down
.print
	bsr.w	SetMenuPrintX
	move.w	#$D,(printy).w
	movea.l	(menulist).w,a1
	jsr	(printsmall).l	;the menu title
	jsr	(printsmallz).l	;clear the 4 item rows
	dc.w	$0026	;String length, 36 bytes: too many for the macro
	dc.b	$FB,$01,$20,$FB,$FF,$FA,$01,$20,$FB,$FF,$FA,$01
	dc.b	$20,$FB,$FF,$FA,$01,$20,$FB,$12,$20,$FB,$FF,$FA
	dc.b	$FF,$20,$FB,$FF,$FA,$FF,$20,$FB,$FF,$FA,$FF,$20
	adda.w	(a1),a1
	move.w	(menuitem+2).w,d0	;skip to the first item shown
	bra.w	.6
.skip
	adda.w	(a1),a1
	addq.w	#4,a1
.6
	dbf	d0,.skip
	moveq	#3,d1	;4 rows
	move.w	#$C,(printy).w
	bsr.w	SetMenuPrintX
	move.w	(menuitem+2).w,d0
	beq.w	.row
	jsr	(printsmallz).l	;more items above
	String	CC_SetAttribute,5,CC_AddX,1,CC_AddY,1,'{',CC_AddY,$FF	;(and hid the rest)
.row
	bsr.w	SetMenuPrintX
	jsr	(printsmallz).l	;start of an item row
	String	CC_AddX,2,CC_AddY,1
	move.l	a1,-(sp)
	movea.l	(menulist).w,a1
	jsr	(printsmall).l
	cmp.w	(menuitem).w,d0
	bne.w	.nosel
	jsr	(printsmall).l	;the selected item marker
.nosel
	movea.l	(sp)+,a1
	bsr.w	PrintMenuItem	;the item text
	addq.w	#1,d0
	addq.w	#4,a1
	tst.w	2(a1)	;negative: the last item
	dbmi	d1,.row
	bmi.w	.x
	bsr.w	SetMenuPrintX
	jsr	(printsmallz).l	;more items below
	String	CC_SetAttribute,5,CC_AddX,1,'}'	;(and hid the rest)
.x
	rts
PrintMenuItem	;Print menu item a1 and step a1 past it. An item whose text starts with 'x' is the goalie option: it prints Manual Goalie
	;(.manual) when the pause team word is 0, else Auto Goalie (.auto): goaliemode2 with sflags bit 1 (sfpj) set, else goaliemode1. Called from
	;UpdateMenuSelection
	cmpi.b	#$78,2(a1)	;first char 'x'
	bne.w	.plain
	move.l	a1,-(sp)
	movea.l	#.manual,a1
	btst	#1,(sflags).w	;sfpj: the pause pad
	beq.w	.homegoalie
	tst.w	(goaliemode2).w
	bra.w	.chkgoalie
.homegoalie
	tst.w	(goaliemode1).w
.chkgoalie
	beq.w	.print
	movea.l	#.auto,a1
.print
	jsr	(printsmall).l
	movea.l	(sp)+,a1
	adda.w	(a1),a1	;skip the 'x' item text
	bra.w	.x
.plain
	jsr	(printsmall).l
.x
	rts
.manual
	String	'  Manual Goalie   '	;no label
.auto
	String	'   Auto Goalie    '	;no label
PutTeamBlock	;Copy 2 rows of 11 map words from TeamBlockMap+d0 to printx / printy, then printx += 11.
	;Saves d0-d2/a0-a1. Called from PrintTeamLogoAndScore and the stats code
	movem.l	d0-d2/a0-a1,-(sp)
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w	;dfng: don't int graphics
	movea.w	#(TeamBlockMap-M68K_RAM),a1
	adda.w	d0,a1
	moveq	#1,d2	;2 rows
.row
	jsr	(xyVmMap).l
	move.w	#$A,d1	;11 words
.1
	move.w	(a1)+,(a0)
	dbf	d1,.1
	addq.w	#1,(printy).w
	dbf	d2,.row
	addi.w	#$B,(printx).w
	subq.w	#2,(printy).w
	move.w	(sp)+,(disflags).w
	movem.l	(sp)+,d0-d2/a0-a1
	rts
vcountwait	;wait till vcount changes, then resync vcount. Saves d0. Reads oldvcount twice. Called from PauseMode, and the stats code
	move.w	d0,-(sp)
	move.w	(oldvcount).w,d0
	move.w	(oldvcount).w,d0
.wait
	cmp.w	(vcount).w,d0
	beq.s	.wait
	move.w	(oldvcount).w,(vcount).w
	move.w	(sp)+,d0
	rts
