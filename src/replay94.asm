;	Instant replay. This file records each frame of play, plays it back with the replay icon and
;	banner, moves the camera and restores the frames. It then updates every player and animation
;	each frame and keeps the scroll window on the play. New in 94: the reverse angle replay.

ReplayMode	;Instant replay play-back control and display code. Called from the pause menu.
	;Tracking: a d-pad press picks the nearest object in that direction and the camera follows it
	bclr	#0,(sflags5).w
	bsr.w	forceblack
	move.w	(disflags).w,-(sp)
	bset	#sf2replay,(sflags2).w
	bclr	#4,(sflags4).w
	jsr	(ClrHor).l
	move.w	#$400,d0
	move.w	(VmMap3).w,d1
	move.w	#$7FF,d2
	bsr.w	DoFill
	move.w	(ExtraChars).w,d4
	movea.l	#ReplayMap+8,a2
	jsr	(DecompressGraphicsPlain).l
	jsr	(ShowReplayIcon).l
	bclr	#sfscrl,(sflags).w
	bclr	#5,(sflags3).w
	st	(replayactive).w
	movea.l	(recbpr).w,a4
.rwd
	bsr.w	suba4
	tst.w	d7
	bne.s	.rwd
	jsr	(SprSort).l
	jsr	(setvideo).l
	bclr	#1,(sflags3).w
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	clr.l	(padcont+8).w
	move.w	#$18,(palcount).w
	moveq	#1,d7
.top
	move.w	(vcount).w,d0
	sub.w	(oldvcount).w,d0
	cmp.w	d0,d7
	bhi.s	.top
	move.w	(vcount).w,(oldvcount).w
	tst.w	(replayicontimer).w
	bmi.w	.0
	sub.w	d7,(replayicontimer).w
	bpl.w	.0
	clr.w	(replayicontimer).w
	jsr	(EraseReplayIcon).l
.0
	movem.l	d0/a3,-(sp)
	movea.l	#SortCords+(12*SCstruct),a3
	move.w	#1,8(a3)
	movea.l	#SortCords+(13*SCstruct),a3
	move.w	#1,8(a3)
	movem.l	(sp)+,d0/a3
	moveq	#1,d7
	bsr.w	getpzjoy
	btst	#0,(sflags5).w
	beq.w	.2
	andi.w	#$FFF0,d0
	ori.w	#8,d0
	andi.w	#$FFF0,d1
	andi.w	#$FFF0,d3
.2
	movea.w	#(ReplayStarStruct-M68K_RAM),a5
	btst	#5,(sflags3).w
	beq.w	.dir
	move.w	d1,d5
	andi.w	#$F,d5
	beq.w	.nomans
.dir
	btst	#3,d0
	bne.w	.nomans
	cmpi.w	#$FF60,(a5)
	bgt.w	.3
	move.w	#0,(a5)
	bra.w	*+4
.3
	cmpi.w	#$FED0,$14(a5)
	bgt.w	.4
	move.w	#0,$14(a5)
.4
	bset	#sfscrl,(sflags).w
	bne.w	.man
	move.w	(Hpos).w,(a5)
	move.w	(Vpos).w,$14(a5)
.man
	move.w	d0,d5
	andi.w	#7,d5
	eori.w	#4,d5
	movea.w	#(SortCords-M68K_RAM),a1
	st	d3
	bclr	#5,(sflags3).w
	beq.w	.find
	move.w	$16(a5),d3
.find
	move.w	(a5),d0
	move.w	$14(a5),d1
	moveq	#$B,d2
	move.l	#$100,d4
	movem.w	d0-d1,-(sp)
.loop
	cmp.w	SCnum(a1),d3
	beq.w	.skip
	movem.w	(sp),d0-d1
	sub.w	(a1),d0
	sub.w	Ypos(a1),d1
	jsr	(vtoa).l
	btst	#3,d0
	bne.w	.skip
	sub.w	d5,d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.skip
	movem.w	(sp),d0-d1
	sub.w	(a1),d0
	sub.w	Ypos(a1),d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#4,d0
	bls.w	.skip
	cmp.l	d4,d0
	bhi.w	.skip
	move.l	d0,d4
	move.w	SCnum(a1),$16(a5)
	bset	#5,(sflags3).w
.skip
	adda.w	#SCstruct,a1
	dbf	d2,.loop
	addq.w	#4,sp
	btst	#5,(sflags3).w
	beq.w	.scrl
	move.w	$16(a5),d0
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	moveq	#4,d4
	bsr.w	setpads
	bsr.w	UpdateCameraPos
	jsr	(setvideo).l
	bra.w	.top
.scrl
	bset	#5,(sflags).w
	eori.w	#4,d5
	asl.w	#2,d5
	lea	.dirtab(pc),a0
	move.w	0(a0,d5.w),d0
	add.w	(a5),d0
	cmp.w	#$88,d0
	bgt.w	.nox
	cmp.w	#$FF78,d0
	blt.w	.nox
	move.w	d0,(a5)
.nox
	move.w	2(a0,d5.w),d1
	add.w	$14(a5),d1
	cmp.w	#$126,d1
	bgt.w	.noy
	cmp.w	#$FEDA,d1
	blt.w	.noy
	move.w	d1,$14(a5)
.noy
	movea.w	a5,a3
	clr.w	$18(a5)
	andi.w	#$FFF,(PadControlBits).w
	ori.w	#$E000,(PadControlBits).w
	bsr.w	UpdateCameraPos
	jsr	(setvideo).l
	bra.w	.top
.dirtab	;scroll step per d-pad direction 0-7: x, y
	dc.w	0,2, 2,2
	dc.w	2,0, 2,-2
	dc.w	0,-2, -2,-2
	dc.w	-2,0, -2,2
.nomans
	st	$18(a5)
	btst	#5,d1
	beq.w	.00
	btst	#0,(sflags5).w
	bne.w	.00
	bchg	#sf3rmplay,(sflags3).w
.00
	btst	#6,d3
	beq.w	.5
	btst	#0,(sflags5).w
	bne.w	.5
	bsr.w	suba4
	bsr.w	suba4
	bsr.w	suba4
	bsr.w	suba4
	jsr	(SprSort).l
	jsr	(setvideo).l
	moveq	#1,d7
	bclr	#1,(sflags3).w
.5
	btst	#0,(sflags5).w
	bne.w	.1
	btst	#4,d3
	beq.w	.1
	btst	#6,d3
	beq.w	.f1
	bclr	#5,(sflags3).w
	bclr	#5,(sflags).w
	move.w	d0,-(sp)
	move.w	(PadControlBits).w,d0
	andi.w	#$FFF,d0
	ori.w	#$E000,d0
	move.w	d0,(PadControlBits).w
	move.w	(sp)+,d0
	bra.w	.top
.f1
	bsr.w	adda4
	jsr	(SprSort).l
	jsr	(setvideo).l
	asl.w	#1,d7
	bclr	#1,(sflags3).w
.1
	btst	#sf3rmplay,(sflags3).w
	beq.w	.noplay
	st	(lastsfx).w
	bsr.w	adda4
	move.w	(lastsfx).w,-(sp)
	bsr.w	sfx
	jsr	(SprSort).l
.noplay
	jsr	(setvideo).l
	btst	#0,(sflags5).w
	bne.w	.6
	btst	#7,d1
	beq.w	.top
	jsr	(ShowReplayBanner).l
	bclr	#1,(sflags3).w
	bset	#0,(sflags5).w
	bne.w	.6
	bra.w	.top
.6
	btst	#7,d1
	bne.w	.8
	btst	#6,d1
	bne.w	.7
	btst	#4,d1
	bne.w	.exit
	btst	#5,d1
	beq.w	.top
	bset	#6,(sflags4).w
	bclr	#0,(sflags5).w
	jsr	(EraseReplayBanner).l
	bsr.w	adda4
	jsr	(SprSort).l
	bra.w	.top
.7
	jmp	.top
.8
	clr.w	(menuitem).w
	bset	#1,(sflags5).w
.exit
	bsr.w	forceblack
	ori.w	#$F000,(PadControlBits).w
	bclr	#5,(sflags).w
	movea.l	(recbpr).w,a4
	bclr	#4,(sflags4).w
	bsr.w	RestoreReplayFrame
	jsr	(SprSort).l
	bclr	#3,(sflags2).w
	move.w	(sp)+,(disflags).w
	jsr	(ReloadRinkGraphics).l
	jsr	(setupEASNmap).l
	jsr	(ReloadEnergyBarTiles).l
	jsr	(ReloadCrowdTiles).l
	jsr	(ReloadRefTiles).l
	btst	#4,(disflags).w
	beq.w	.10
	jsr	(ReloadFaceOffMap).l
	jsr	(ReloadFaceOffTiles).l
.10
	jsr	(SetHor).l
	jsr	(setvideo).l
	move.w	#$18,(palcount).w
	rts
getpzjoy	;read the joystick of the pad that paused. pads 3 and 4 when FourWayPlay (pausepad = 3 or 4)
	tst.w	(FourWayPlay).w
	bne.w	.0
.loop
	btst	#sfpj,(sflags).w
	bne.w	ReadJoy2
	bra.w	ReadJoy1
.0
	tst.w	(pausepad).w
	beq.s	.loop
	cmpi.w	#3,(pausepad).w
	beq.w	ReadJoy3
	bra.w	ReadJoy4
ShowReplayIcon	;Show the replay icon and start the $F0 frame replayicontimer timer
	move.w	#$F0,(replayicontimer).w
	bsr.w	printz
	String	-(TXPRI+TXMAP3),2,2
	moveq	#$20,d0
	moveq	#$55,d1
	moveq	#8,d2
	moveq	#4,d3
	move.w	(rinkvrcset).w,d4
	move.w	#0,d5
	movea.l	#Rinktilelist,a1
	btst	#4,(sflags4).w	;check if reverse angle replay
	beq.w	.0	;branch if not
	movea.l	#RevRinkTilelist,a1
.0
	adda.l	4(a1),a1
	movea.w	#NoTiles,a2
	bra.w	dobitmap
EraseReplayIcon	;Erase the 8 x 4 replay icon (replayicontimer timer ran out)
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),2,2
	move.w	#8,d0			;8 wide
	move.w	#4,d1			;4 high
	move.w	#$7FF,d2
	jmp	eraser
ShowReplayBanner	;Show ReplayMap at 0,0 (16 x 11) and stop the replayicontimer timer
	st	(replayicontimer).w
	bsr.w	printz
	String	-(TXPRI+TXMAP3),2,0
	moveq	#0,d0
	moveq	#0,d1
	moveq	#$10,d2
	moveq	#$B,d3
	move.w	(ExtraChars).w,d4
	move.w	#0,d5
	movea.l	#ReplayMap,a1
	adda.l	4(a1),a1
	movea.w	#NoTiles,a2
	bra.w	dobitmap
EraseReplayBanner	;Erase the 16 x 11 area ShowReplayBanner drew
	jsr	(printz).l
	String	-(TXPRI+TXMAP3),2,2
	move.w	#$10,d0			;16 wide
	move.w	#$B,d1			;11 high
	move.w	#$7FF,d2
	jmp	eraser
suba4	;a4 = current replay frame. Back up 1 frame and set video parameters for display.
	;d7 = delay between frames, or zero at the end of the replay
	cmpa.l	#M68K_RAM,a4
	bne.w	.1
	btst	#sfwrap,(sflags).w
	beq.w	.end
	movea.l	#replayend,a4
.1
	suba.w	#$62,a4
	cmpa.l	(recbpr).w,a4
	bne.w	RestoreReplayFrame
	adda.w	#$62,a4
.end
	bsr.w	RestoreReplayFrame
	clr.w	d7
	rts
adda4	;Step forward 1 frame. First handles a reverse angle switch (sflags4 bit 6)
	bclr	#6,(sflags4).w
	beq.w	.1
	movem.l	d0-d7/a0-a6,-(sp)
	bchg	#4,(sflags4).w
	move.w	(Hpos).w,-(sp)
	move.w	(Vpos).w,-(sp)
	bsr.w	forceblack2
	jsr	(vcountwait).l
	jsr	(vcountwait).l
	jsr	(ReloadRinkGraphics).l
	clr.w	(Hpos).w
	clr.w	(Vpos).w
	move.w	#$7D0,(Oldrow).w
	move.w	#1,d0
.loop
	jsr	(setvideo).l
	jsr	(vcountwait).l
	dbf	d0,.loop
	move.w	(sp)+,(Vpos).w
	move.w	(sp)+,(Hpos).w
	move.w	#1,d0
	jsr	(setvideo).l
.loop2
	jsr	(vcountwait).l
	dbf	d0,.loop2
	movem.l	a0,-(sp)
	movea.l	#SortCords+(12*SCstruct),a0
	move.w	#1,8(a0)
	adda.w	#$80,a0
	move.w	#1,8(a0)
	movem.l	(sp)+,a0
	bsr.w	RevReplayAdj
	btst	#5,(sflags).w
	beq.w	*+4
.0
	jsr	(ShowReplayIcon).l
	move.w	#$64,(palcount).w
	movem.l	(sp)+,d0-d7/a0-a6
.1
	clr.w	d7
	btst	#sf2drec,(sflags2).w
	beq.w	adda42
	movem.l	a4,-(sp)
	bsr.w	adda43
	cmpa.l	(recbpr).w,a4
	movem.l	(sp)+,a4
	beq.w	rtss8
adda42	;adda4 without the sf2drec look-ahead: stop at the record point, else show the frame and
	;fall into adda43
	cmpa.l	(recbpr).w,a4
	beq.w	rtss8
	bsr.w	RestoreReplayFrame
adda43	;a4 += replay frame size ($62), wrapping from replayend to M68K_RAM
	adda.w	#$62,a4
	cmpa.l	#replayend,a4
	bne.w	rtss8
	movea.l	#M68K_RAM,a4
	rts
UpdateCameraPos	;Camera struct a5 = object a3 x/y (negated for the reverse angle), Hpos/Vpos clamped
	movem.l	d0-d2,-(sp)
	move.w	(a3),d0
	btst	#7,(sflags4).w
	beq.w	.0
	neg.w	d0
.0
	move.w	d0,(a5)
	move.w	Ypos(a3),d1
	btst	#7,(sflags4).w
	beq.w	.2
	neg.w	d1
.2
	move.w	d1,$14(a5)
	cmp.w	#$3C,d0
	blt.w	.4
	move.w	#$3C,d0
.4
	cmp.w	#$FFC4,d0
	bgt.w	.1
	move.w	#$FFC4,d0
.1
	move.w	d0,(Hpos).w
	cmp.w	#$100,d1
	blt.w	.5
	move.w	#$100,d1
.5
	cmp.w	#$FF38,d1
	bgt.w	.3
	move.w	#$FF38,d1
.3
	move.w	d1,(Vpos).w
	movem.l	(sp)+,d0-d2
	rts
; set flag for reverse replay setup if needed
RevReplayAdj	;Set sflags4 bit 7 for a reverse angle replay, then fall into RestoreReplayFrame
	btst	#4,(sflags4).w	;check if reverse angle replay
	beq.w	RestoreReplayFrame	;branch if not
	bset	#7,(sflags4).w	;set bit 7
; a4 = current replay frame address to convert into normal coordinates
RestoreReplayFrame	;a4 = current replay frame address to convert into normal cordinates,
	;then the other replay variables. Flips x/y and frames for the reverse angle
	movem.l	d0-d2/a0/a6,-(sp)
	movea.l	#revframetbl,a6
	movea.l	a4,a0
	moveq	#$F,d1	;16 objects to convert (12 players/2 nets/puck/puck shadow)
	movea.w	#(SortCords-M68K_RAM),a3
.top
	move.w	2(a0),d2
	andi.w	#$3FF,d2
	btst	#9,d2
	beq.w	.chkrevx
	ori.w	#$FC00,d2
.chkrevx
	btst	#4,(sflags4).w	;check if reverse angle
	beq.w	.p	;branch if not
	neg.w	d2
.p
	move.w	d2,(a3)	;update Xpos
	move.l	(a0),d2
	asr.l	#4,d2
	asr.w	#6,d2
	btst	#9,d2
	beq.w	.chkrevy
	ori.w	#$FC00,d2
.chkrevy
	btst	#4,(sflags4).w	;check if reverse angle
	beq.w	.p1	;branch if not
	neg.w	d2
	cmp.w	#0,d1	;check if last object (puck shadow)
	bne.w	.p1	;branch if not
	addq.w	#2,d2	;update puck shadow Xpos
.p1
	move.w	d2,Ypos(a3)	;update Ypos
	move.w	(a0),d2
	asr.w	#4,d2
	andi.w	#$3FF,d2
	btst	#4,(sflags4).w	;check if reverse angle
	beq.w	.2	;branch if not
	asl.w	#1,d2
	move.w	0(a6,d2.w),d2	;look up table to adjust d2
	cmpi.w	#$F,SCnum(a3)	;check if puck shadow
	bne.w	.0	;branch if not
	cmp.w	#SPFpuck,d2
	beq.w	.0
	move.w	#$FC00,Ypos(a3)	;update Ypos of puck shadow
.0
	cmp.w	#1,d2	;check if frame is before frame 1 (out of range)
	blt.w	.1	;branch if so
	cmp.w	#$34E,d2	;check if frame is >= 846 (last frame +1)
	bge.w	.1	;branch if so
	bra.w	.2	;branch if valid object frame
.1
	move.w	(a0),d2
	asr.w	#4,d2
	andi.w	#$3FF,d2
.2
	move.w	d2,6(a3)
	cmp.w	#SPFbglass,d2	;check if frame is before glass shatter frames
	blt.w	.3	;branch if so
	cmp.w	#SPFbglass+5,d2	;check if frame is after glass shatter frames
	bge.w	.3	;branch if so
	btst	#4,(sflags4).w
	beq.w	.3
	move.w	#$190,Ypos(a3)
.3
	move.w	(a0),d2
	asr.w	#3,d2
	andi.w	#$1800,d2
	andi.w	#$E7FF,attribute(a3)
	or.w	d2,attribute(a3)
	btst	#4,(sflags4).w	;check if reverse angle replay
	beq.w	.4	;branch if not
	move.w	6(a3),d2	;move frame into d2
	cmp.w	#SPFfight,d2	;check if frame is before old fight frames
	blt.w	.4	;branch if so
	cmp.w	#SPFPen,d2	;check if frame is after old fight frames
	bge.w	.4	;branch if so
	bchg	#3,4(a3)	;change X flip attribute for object
.4
	addq.w	#4,a0
	adda.w	#SCstruct,a3
	dbf	d1,.top	;loop to next object
	moveq	#5,d2
	movea.w	#(SortCords-M68K_RAM),a3
.loop
	move.b	(a0)+,rostnum(a3)
	move.b	(a0),d0
	andi.w	#$F,d0
	cmp.w	#$F,d0
	bne.w	.5
	moveq	#-1,d0
.5
	move.w	d0,position(a3)
	adda.w	#SCstruct,a3
	move.b	(a0)+,d0
	lsr.b	#4,d0
	move.b	d0,rostnum(a3)
	move.b	(a0),d0
	asl.b	#4,d0
	or.b	d0,rostnum(a3)
	move.b	(a0)+,d0
	lsr.b	#4,d0
	andi.w	#$F,d0
	cmp.w	#$F,d0
	bne.w	.6
	moveq	#-1,d0
.6
	move.w	d0,position(a3)
	adda.w	#SCstruct,a3
	dbf	d2,.loop
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(puckz).w
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(SortCords+((puckscnum+1)*SCstruct)+Zpos).w
	move.b	(a0)+,d0
	ext.w	d0
	move.w	d0,(lastsfx).w
	clr.w	d7
	move.b	(a0)+,d7
	move.w	(a0)+,d0
	andi.w	#$FFF,d0
	andi.w	#$F000,(PadControlBits).w
	or.w	d0,(PadControlBits).w
	move.w	(a0)+,(crowdframe).w
	move.w	(a0)+,(glovecords).w
	move.b	(a0)+,(PBnum).w
	clr.w	d0
	move.b	(a0)+,d0
	lsl.w	#4,d0
	ori.w	#$F00F,d0
	move.w	d0,(PadControlBits34).w
	btst	#sfscrl,(sflags).w
	beq.w	.pos
	movea.w	a5,a3
	btst	#5,(sflags3).w
	beq.w	.cam
	clr.w	$18(a5)
	move.w	$16(a5),d0
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
.cam
	bsr.w	UpdateCameraPos
	bra.w	.7
.pos
	move.w	(a0)+,(Hpos).w
	move.w	(a0)+,(Vpos).w
	btst	#4,(sflags4).w
	beq.w	.7
	neg.w	(Hpos).w
	neg.w	(Vpos).w
	jsr	(ClampReplayView).l
.7
	bclr	#7,(sflags4).w
	movem.l	(sp)+,d0-d2/a0/a6
	rts
ClampReplayView	;Clamp Hpos to -$3C..$3C and Vpos to -$C8..$100
	move.w	d0,-(sp)
	move.w	#$3C,d0
	cmp.w	(Hpos).w,d0
	blt.w	.0
	move.w	#$FFC4,d0
	cmp.w	(Hpos).w,d0
	ble.w	.1
.0
	move.w	d0,(Hpos).w
.1
	move.w	#$100,d0
	cmp.w	(Vpos).w,d0
	blt.w	.2
	move.w	#$FF38,d0
	cmp.w	(Vpos).w,d0
	ble.w	.3
.2
	move.w	d0,(Vpos).w
.3
	move.w	(sp)+,d0
	rts
; called every frame to save replay events
; d7 = elapsed frames
updatereplay	;called every frame to save replay events, d7 = elapsed frames
	btst	#gmhl,(gmode).w	;check if highlight
	bne.w	rtss8	;exit if so
	btst	#sf2drec,(sflags2).w	;check if replay record disabled
	beq.w	.0	;branch if not
	tst.w	(replaydelay).w
	beq.w	.rec
	subq.w	#1,(replaydelay).w
	bpl.w	.0
	clr.w	(replaydelay).w
	bra.w	.rec
.0
	addi.l	#$62,(recbpr).w
	cmpi.l	#replayend,(recbpr).w
	bne.w	.rec
	bset	#sfwrap,(sflags).w
	move.l	#M68K_RAM,(recbpr).w
.rec
	movea.l	(recbpr).w,a0
	moveq	#$F,d2
	movea.w	#(SortCords-M68K_RAM),a3
.top
	clr.l	(a0)
	move.w	(a3),d1
	andi.w	#$3FF,d1
	move.w	d1,2(a0)
	clr.l	d1
	move.w	Ypos(a3),d1
	asl.w	#6,d1
	asl.l	#4,d1
	or.l	d1,(a0)
	move.w	frame(a3),d1
	asl.w	#4,d1
	or.w	d1,(a0)
	move.w	attribute(a3),d1
	andi.w	#$1800,d1
	asl.w	#3,d1
	or.w	d1,(a0)
	addq.w	#4,a0
	adda.w	#SCstruct,a3
	dbf	d2,.top
	moveq	#5,d2
	movea.w	#(SortCords-M68K_RAM),a3
.loop
	move.b	rostnum(a3),(a0)+
	move.w	position(a3),d0
	bpl.w	.n0
	moveq	#$F,d0
.n0
	andi.w	#$F,d0
	move.b	d0,(a0)
	adda.w	#SCstruct,a3
	move.b	rostnum(a3),d0
	asl.w	#4,d0
	or.b	d0,(a0)+
	move.b	rostnum(a3),d0
	lsr.b	#4,d0
	move.b	d0,(a0)
	move.w	position(a3),d0
	bpl.w	.n1
	moveq	#$F,d0
.n1
	asl.w	#4,d0
	or.b	d0,(a0)+
	adda.w	#SCstruct,a3
	dbf	d2,.loop
	move.b	(puckz+1).w,(a0)+
	move.b	(SortCords+((puckscnum+1)*SCstruct)+Zpos+1).w,(a0)+
	move.b	(lastsfx+1).w,(a0)+
	bset	#7,(lastsfx+1).w
	move.b	d7,(a0)+
	move.w	(PadControlBits).w,(a0)+
	move.w	(crowdframe).w,(a0)+
	move.w	(glovecords).w,(a0)+
	move.b	(PBnum).w,(a0)+
	move.w	d0,-(sp)
	move.w	(PadControlBits34).w,d0
	lsr.w	#4,d0
	move.b	d0,(a0)+
	move.w	(sp)+,d0
	move.w	(Hpos).w,(a0)+
	move.w	(Vpos).w,(a0)+
rtss8
	rts
; this routine calls all collision/animation/assignment code for all players
; d7 = elapse frames since last call
updateplayers	;this routine calls all collision/animation/assignment code for all players. d7 = elapsed frames
	btst	#sfhor,(sflags).w	;check if screen is in horiz mode
	bne.w	.checkcrowd	;jump if horiz mode
	ori.w	#$F,(PadControlBits).w
	cmpi.w	#5,(puckz).w	;check puckz with 5
	bgt.w	.gt	;branch if greater
.clrcnt
	clr.w	(PuckZCntr).w	;clear counter
	bra.w	.checkcrowd
.gt
	move.w	(TmpPuckZ).w,d0
	cmp.w	(puckz).w,d0
	beq.w	.pzeq	;branch if puckz equal to TmpPuckZ
	move.w	(puckz).w,(TmpPuckZ).w
	bra.s	.clrcnt
.pzeq
	addq.w	#1,(PuckZCntr).w	;add 1 to counter
	cmpi.w	#$10,(PuckZCntr).w	;compare counter to 10 (16 decmial)
	blt.w	.checkcrowd	;branch if less than
	clr.w	(PuckZCntr).w	;clear counter
	subq.w	#1,(puckz).w	;subtract 1 from puckz
.checkcrowd
	bclr	#6,(sflags7).w	;Bit 6 = Crowd Meter bit
	move.w	(CurCrowdMeter).w,d0	;Move cur crowd meter to d0
	cmp.w	(CrowdRecord).w,d0	;compare with crowd record
	blt.w	.nobreak	;branch if less than
	bset	#6,(sflags7).w	;set Crowd Meter bit
.nobreak
	jsr	(SetSflags8Bit1).l	;turn on bit 1 of sflags8
	tst.w	(puckc).w
	bmi.w	.scload	;branch if no puck carrier
	bclr	#7,(sflags8).w
	bclr	#1,(sflags6).w
	move.w	(puckc).w,d0	;move puckc SCnum into d0
	asl.w	#7,d0
	movea.l	#SortCords,a3	;start of player SCstructs
	adda.w	d0,a3	;add offset to a3
	btst	#pf3break,pflags3(a3)	;checks if there is a breakaway
	beq.w	.scload	;branch if no breakaway
	bclr	#4,(gmode2).w	;clear if breakaway
.scload
	movea.w	#(SortCords-M68K_RAM),a3
.top
	move.l	(a3),OldXpos(a3)	;Xpos, oldXpos
	move.l	Ypos(a3),OldYpos(a3)	;Ypos, oldYpos
	move.l	Zpos(a3),OldZpos(a3)	;Zpos, oldZpos
	btst	#pf3fall,pflags3(a3)	;falling down?
	beq.w	.top2	;branch if not
	clr.w	Xvel(a3)	;clear Xvel
	clr.w	Yvel(a3)	;clear Yvel
	tst.w	SPAnum(a3)	;check animation index
	bne.w	.0	;branch if index not 0
	jsr	(PlaceBoardFall).l
	bra.w	.top2
.0
	cmpi.w	#SPAbenchcheckl,SPA(a3)	;check animation
	beq.w	.10
	cmpi.w	#SPAbenchcheckr,SPA(a3)
	beq.w	.8
	cmpi.w	#SPAboardleft,SPA(a3)
	beq.w	.9
	cmpi.w	#SPAboardright,SPA(a3)
	beq.w	.7
	cmpi.w	#SPAboardfront,SPA(a3)
	beq.w	.1
	cmpi.w	#SPAboardback,SPA(a3)
	beq.w	.4
	bra.w	.top2
.1
	move.w	#$124,d0
	cmpi.w	#$56,(FallXPos).w
	bgt.w	.2
	cmpi.w	#$FFAA,(FallXPos).w
	bgt.w	.3
.2
	move.w	#$116,d0
.3
	move.w	d0,Ypos(a3)
	bra.w	.top2
.4
	move.w	#$FEDC,d0
	cmpi.w	#$56,(FallXPos).w
	bgt.w	.5
	cmpi.w	#$FFAA,(FallXPos).w
	bgt.w	.6
.5
	move.w	#$FEEA,d0
.6
	move.w	d0,Ypos(a3)
	bra.w	.top2
.7
	move.w	#$82,(a3)
	btst	#3,4(a3)
	beq.w	.top2
	move.w	#$FF7E,(a3)
	bra.w	.top2
.8
	move.w	#$88,(a3)
	btst	#3,4(a3)
	beq.w	.top2
	move.w	#$FF78,(a3)
	bra.w	.top2
.9
	move.w	#$FF7E,(a3)
	btst	#3,4(a3)
	beq.w	.top2
	move.w	#$82,(a3)
	bra.w	.top2
.10
	move.w	#$FF78,(a3)
	btst	#3,4(a3)
	beq.w	.top2
	move.w	#$88,(a3)
.top2
	tst.w	position(a3)	;check if on ice
	bmi.w	.nf1	;branch if not on ice
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0	;check if player has puck
	beq.w	.top3	;branch if puck carrier
	bclr	#pf3break,pflags3(a3)	;clear breakaway bit
	bclr	#pf3oside,pflags3(a3)	;clear offsides bit
.top3
	bsr.w	updateanim
	sub.b	d7,nopuck(a3)	;no puck control
	bpl.w	.np
	clr.b	nopuck(a3)	;clear upper byte of nopuck
.np
	sub.b	d7,nopuck+1(a3)	;subtract # of frames from nopuck+1
	bpl.w	.np2
	clr.b	nopuck+1(a3)	;clear lower byte of nopuck
.np2
	btst	#6,(sflags3).w	;check if penalty timer is up
	beq.w	.11
	clr.w	d0
	move.b	pnum(a3),d0	;player offset on roster
	bmi.w	.11
	add.w	d0,d0
	addi.w	#$136,d0
	jsr	(loadTeamStruct).l
	addq.w	#1,0(a2,d0.w)	;add 1 to TOI for player
.11
	cmpi.w	#SPAinjuryfall,SPA(a3)	;check animation
	beq.w	.done
	cmpi.w	#SPAinjury1,SPA(a3)	;check animation
	beq.w	.done
	moveq	#$11,d4
	tst.w	(PalMode).w
	beq.w	.notoside
	moveq	#$16,d4
.notoside
	mulu.w	d7,d4	;update velocity
	tst.w	Zpos(a3)	;Zpos
	bne.w	.y2	;no deceleration
	moveq	#6,d2
	btst	#pfdoff,pflags(a3)	;pfdoff - player deceleration
	beq.w	.off
	moveq	#9,d2	;this value used when player receiving pass. Also the puck will use this when "normal"
.off
	move.w	Xvel(a3),d0	;Xvel
	beq.w	.x2
	asr.w	d2,d0	;shift d0 right d2 times
	bne.w	.x1	;branch if d0 not zero
	moveq	#1,d0	;make d0 1 if it was 0
.x1
	sub.w	d0,Xvel(a3)	;Xvel
.x2
	move.w	Yvel(a3),d0	;Yvel
	beq.w	.y2	;branch if d0 is 0
	asr.w	d2,d0	;shift d0 to the right d2 times
	bne.w	.y1	;branch if d0 not 0
	moveq	#1,d0	;make d0 1 if it was 0
.y1
	sub.w	d0,Yvel(a3)	;sub d0 from Yvel
.y2
	move.w	Xvel(a3),d0	;Xvel
	beq.w	.x3	;branch if d0 is 0
	muls.w	d4,d0	;mult d0 by d4
	add.l	d0,(a3)	;add to Xpos
.x3
	move.w	Yvel(a3),d0	;Yvel
	beq.w	.y3	;branch if d0 is 0
	muls.w	d4,d0	;mult d0 by d4
	add.l	d0,Ypos(a3)	;add to Ypos
.y3
	tst.w	Zpos(a3)	;check Zpos
	bmi.w	.done	;branch if negative
	bne.w	.z1	;branch if not 0
	tst.w	Zvel(a3)	;check Zvel
	beq.w	.done	;branch if 0
.z1
	asl.w	#1,d4	;mult d4 by 2
	sub.w	d4,Zvel(a3)	;sub d4 from Zvel
	asl.w	#1,d4	;mult d4 by 2
	sub.w	d4,Zvel(a3)	;sub d4 from Zvel
	lsr.w	#2,d4	;divide d4 by 4
	move.w	Zvel(a3),d0	;move Zvel into d0
	muls.w	d4,d0	;mult d0 by d4
	add.l	d0,Zpos(a3)	;add d0 to Zpos
	bpl.w	.done	;branch if d0+Zpos is positive
	clr.l	Zpos(a3)	;clear Zpos
	neg.w	Zvel(a3)	;negate Zvel
	asr.w	Zvel(a3)	;divide Zvel by 2
	moveq	#5,d0	;move 5 into d0
	sub.b	Zvel(a3),d0	;sub Zvel from d0
	bpl.w	.chkpuck	;branch if result is positive
	clr.w	d0	;clear d0
.chkpuck
	cmp.w	#3,d0	;compare d0 to 3
	bhi.w	.done	;branch if higher than 3
	addi.w	#$2C,d0	;','   ; #SFXpuckice
	move.w	d0,-(sp)
	bsr.w	sfx
.done
	move.w	SCnum(a3),d6	;SCnum
	cmp.w	(puckc).w,d6	;check if puck carrier
	bne.w	.tp	;not puck carrier
	btst	#pf2fight,pflags2(a3)	;pf2fight - check if fighting
	bne.w	.tp
	btst	#sfhor,(sflags).w	;#sfhor - check if in horiz mode
	bne.w	.tp
	moveq	#-2,d4	;-2 - pad index for puck carrier
	bsr.w	setpads
.tp
	btst	#0,(sflags2).w	;sf2faceoff- check for faceoff
	bne.w	.tp2	;branch if faceoff
	tst.w	(holdreset).w
	beq.w	.tp2
	subq.w	#1,(holdreset).w
	beq.w	.12
	bpl.w	.tp2
.12
	clr.w	(holdreset).w
	move.w	#$1111,(bholdtimer).w
	move.w	#$1111,(bholdtimer34).w
.tp2
	cmp.w	(c1playernum).w,d6	;check if cont 1 is puck carrier
	bne.w	.t0
	bsr.w	ReadJoy1
	clr.w	d4	;pad index for cont 1 player
	move.w	#$FFFF,(joypuckcarrier).w
	bsr.w	doinput	;B button
	bra.w	.t1
.t0
	cmp.w	(c2playernum).w,d6	;check if cont 2 is puck carrier
	bne.w	.t1
	bsr.w	ReadJoy2
	moveq	#2,d4	;pad index for cont 2 player
	move.w	#$FFFF,(joypuckcarrier).w
	bsr.w	doinput	;B button
.t1
	cmp.w	#$B,d6	;check if SCnum 0-11 were puck carrier (players)
	bgt.w	.t1cont	;jump if not
	tst.w	(cont3team).w	;check if there is 3 controllers?
	beq.w	.13
	cmp.w	(c3playernum).w,d6
	bne.w	.13
	jsr	(ReadJoy3).l
	clr.l	d4
	clr.w	(joypuckcarrier).w
	move.w	(cont1team).w,-(sp)
	move.w	(cont3team).w,(cont1team).w
	move.w	(c1playernum).w,-(sp)
	move.w	(c3playernum).w,(c1playernum).w
	move.w	(bholdtimer).w,-(sp)
	move.w	(bholdtimer34).w,(bholdtimer).w
	move.w	(padword1).w,-(sp)
	move.w	(padword3).w,(padword1).w
	move.w	(aholdtimer).w,-(sp)
	move.w	(aholdtimer34).w,(aholdtimer).w
	move.w	(PadControlBits).w,-(sp)
	move.w	(PadControlBits34).w,(PadControlBits).w
	bsr.w	doinput	;B button
	move.w	(PadControlBits).w,(PadControlBits34).w
	move.w	(sp)+,(PadControlBits).w
	move.w	(aholdtimer).w,(aholdtimer34).w
	move.w	(sp)+,(aholdtimer).w
	move.w	(padword1).w,(padword3).w
	move.w	(sp)+,(padword1).w
	move.w	(bholdtimer).w,(bholdtimer34).w
	move.w	(sp)+,(bholdtimer).w
	move.w	(c1playernum).w,(c3playernum).w
	move.w	(sp)+,(c1playernum).w
	move.w	(cont1team).w,(cont3team).w
	move.w	(sp)+,(cont1team).w
.13
	tst.w	(cont4team).w	;check if there is 4 controllers?
	beq.w	.t1cont
	cmp.w	(c4playernum).w,d6
	bne.w	.t1cont
	jsr	(ReadJoy4).l
	moveq	#2,d4
	move.w	#1,(joypuckcarrier).w
	move.w	(cont2team).w,-(sp)
	move.w	(cont4team).w,(cont2team).w
	move.w	(c2playernum).w,-(sp)
	move.w	(c4playernum).w,(c2playernum).w
	move.w	(bholdtimer).w,-(sp)
	move.w	(bholdtimer34).w,(bholdtimer).w
	move.w	(padword2).w,-(sp)
	move.w	(padword4).w,(padword2).w
	move.w	(aholdtimer).w,-(sp)
	move.w	(aholdtimer34).w,(aholdtimer).w
	move.w	(PadControlBits).w,-(sp)
	move.w	(PadControlBits34).w,(PadControlBits).w
	bsr.w	doinput	;B button
	move.w	(PadControlBits).w,(PadControlBits34).w
	move.w	(sp)+,(PadControlBits).w
	move.w	(aholdtimer).w,(aholdtimer34).w
	move.w	(sp)+,(aholdtimer).w
	move.w	(padword2).w,(padword4).w
	move.w	(sp)+,(padword2).w
	move.w	(bholdtimer).w,(bholdtimer34).w
	move.w	(sp)+,(bholdtimer).w
	move.w	(c2playernum).w,(c4playernum).w
	move.w	(sp)+,(c2playernum).w
	move.w	(cont2team).w,(cont4team).w
	move.w	(sp)+,(cont2team).w
.t1cont
	move.w	assnum(a3),d0	;assnum
	clr.w	d1
	move.b	asslist(a3,d0.w),d1	;asslist of SCstruct
	asl.w	#2,d1	;mult by 4
	movea.l	#asstab,a0
	movea.l	0(a0,d1.w),a0	;get address of assignment to use for jmp
	jsr	(loadTeamStruct).l
	jsr	(a0)	;call assignment for this player
	clr.w	Wallcos(a3)	;clear wallcos
	clr.w	Wallsin(a3)	;clear wallsin
	move.w	(a3),d2	;Xpos
	move.w	Ypos(a3),d3	;Ypos
	cmp.w	OldXpos(a3),d2	;compare to oldXpos
	bne.w	.cc	;branch if not equal
	cmp.w	OldYpos(a3),d3	;compare to oldYpos
	beq.w	.nf	;branch if equal
.cc
	jsr	(checkcoll).l	;check for collisions
.nf
	move.w	d7,d0	;move d7 into d0 (elapsed frames)
	asl.w	#1,d0	;mult by 2
	sub.w	d0,impact(a3)	;reduce impact at a constant rate
	bpl.w	.nf1	;branch if positive
	clr.w	impact(a3)	;clear impact if negative or zero
.nf1
	move.w	impact(a3),limpact(a3)	;move impact into limpact
	adda.w	#SCstruct,a3	;SCstruct size
	cmpi.w	#$F,SCnum-SCstruct(a3)	;compare Sortobjs-1 to SCnum-SCstruct
	blt.w	.top	;loop for all Sort objects
	rts
; frame switch control on struct a3
updateanim	;frame switch control on struct a3
	tst.w	SPA(a3)	;test SPA
	bne.w	.ia	;branch if not 0
	bclr	#pfalock,pflags(a3)	;clear anim lock
	bclr	#pf2aip,pflags2(a3)	;clear anim in progress
	rts
.ia
	movea.l	#SPAlist,a0	;animation data tables
	adda.w	SPA(a3),a0	;add SPA to a0 address
	move.w	$10(a0),d1	;16 dec - attributes for anim
	move.w	facedir(a3),d0	;facedir into d0
	btst	#sfhor,(sflags).w	;check if horizontal mode
	beq.w	.nhor	;branch if not
	cmpi.w	#$C,SCnum(a3)	;compare to 12 (check if a player, not the puck or nets)
	bge.w	.nhor	;branch if greater than (puck or nets)
	subq.w	#2,d0	;direction adjust for horizontal rink
	andi.w	#7,d0
.nhor
	btst	#3,attribute(a3)	;x flip flag
	beq.w	.nox	;branch if no flip
	neg.w	d0	;negate d0
	addq.w	#8,d0	;add 8 to d0 for flipping
	andi.w	#7,d0	;pass first 3 bits
.nox
	asl.w	#1,d0	;mult by 2
	adda.w	0(a0,d0.w),a0	;add a0 + d0 offset to a0 - This moves the SPF value into a0
	move.w	SPAnum(a3),d0	;SPANum into d0 (index into animation)
	move.w	0(a0,d0.w),d2	;a0 + d0 offset into d2 - this is the new SPF frame of this animation
	tst.w	SPAcnt(a3)	;check if SPAcnt is 0 (time for a new frame)
	bmi.w	.1	;branch if so (SPAcnt is negative)
	sub.w	d7,SPAcnt(a3)	;sub frames elasped from SPAcnt
	bpl.w	.cframe	;branch if SPAcnt is positive
	addq.w	#4,SPAnum(a3)	;add 4 to SPAnum (set for next index)
	addq.w	#4,d0	;add 4 to d0 (currently holds current index)
	tst.w	-2(a0,d0.w)	;test -2 offset from a0 + d0 (this is the frame time for the previous frame)
	bpl.w	.1	;branch if positive (not the end of the animation)
	clr.w	d0	;clear d0
	clr.w	SPAnum(a3)	;clear SPANum
	bclr	#5,pflags(a3)	;clear animation lock
	bclr	#1,pflags2(a3)	;clear animation in progress
	bclr	#pf3fall,pflags3(a3)	;clear fall down flag
	btst	#0,d1	;check if anim attribute loops
	bne.w	.1	;loop
	clr.w	SPA(a3)	;clear SPA
.1
	move.w	2(a0,d0.w),d0	;move frame time for animation frame into d0
	bpl.w	.0	;branch if positive
	neg.w	d0	;make d0 negative (this is the case if final frame)
.0
	move.w	d0,SPAcnt(a3)	;move d0 into SPAcnt
.cframe
	sub.b	d7,glitch(a3)	;sub frames elapsed from glitch - limit minimum time between frame switches
	bpl.w	.rtss	;branch if glitch is positive still
	clr.b	glitch(a3)	;clear glitch
	cmp.w	frame(a3),d2	;compare frame to d2
	beq.w	.rtss	;branch if equal
	move.w	d2,frame(a3)	;move d2 into frame
	move.b	#4,glitch(a3)	;move 4 into glitch - /60 sec min frame switch time
.rtss
	rts
freezewindow	;lock scrolling to the current position
	move.w	(Vpos).w,(yc1).w
	move.w	(Hpos).w,(xc1).w
	bset	#sfslock,(sflags).w
	rts
checkwindow	;set Hpos and Vpos according to how the screen should follow the puck
	move.w	(yc1).w,d2
	move.w	(xc1).w,d3
	btst	#sfslock,(sflags).w
	bne.w	.dd
	movea.w	#(puckx-M68K_RAM),a3
	move.w	(puckc).w,d0
	bmi.w	.0
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	move.w	d7,d0
	add.w	d0,d0
	btst	#pfgoal,pflags(a3)
	beq.w	.gd
	add.w	d0,(yleader).w
	cmpi.w	#$32,(yleader).w
	blt.w	.0
	move.w	#$32,(yleader).w
	bra.w	.0
.gd
	sub.w	d0,(yleader).w
	cmpi.w	#$FFCE,(yleader).w
	bgt.w	.0
	move.w	#$FFCE,(yleader).w
.0
	move.w	Yvel(a3),d2
	asr.w	#7,d2
	add.w	Ypos(a3),d2
	add.w	(yleader).w,d2
	move.w	(a3),d3
	move.w	d2,(yc1).w
	move.w	d3,(xc1).w
.dd
	move.w	d2,d0
	sub.w	(Vpos).w,d0
	cmp.w	#$FFF6,d0
	bge.w	.1
	move.w	d2,d1
	subi.w	#$FFF6,d1
	cmp.w	#$FF38,d1
	bgt.w	.2
	move.w	#$FF38,d1
	bra.w	.2
.1
	cmp.w	#$A,d0
	ble.w	.2x
	move.w	d2,d1
	subi.w	#$A,d1
	cmp.w	#$100,d1
	blt.w	.2
	move.w	#$100,d1
.2
	sub.w	(Vpos).w,d1
	beq.w	.2x
	asr.w	#4,d1
	bne.w	.v2
	addq.w	#1,d1
.v2
	add.w	d1,(Vpos).w
.2x
	move.w	d3,d0
	sub.w	(Hpos).w,d0
	cmp.w	#$FFD8,d0
	bge.w	.3
	move.w	d3,d1
	subi.w	#$FFD8,d1
	cmp.w	#$FFC4,d1
	bge.w	.4
	move.w	#$FFC4,d1
	bra.w	.4
.3
	cmp.w	#$28,d0
	ble.w	.x
	move.w	d3,d1
	subi.w	#$28,d1
	cmp.w	#$3C,d1
	ble.w	.4
	move.w	#$3C,d1
.4
	sub.w	(Hpos).w,d1
	beq.w	.x
	asr.w	#4,d1
	bne.w	.h2
	addq.w	#1,d1
.h2
	add.w	d1,(Hpos).w
.x
	rts
