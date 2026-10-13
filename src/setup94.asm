;	Rink and team setup. This file lays down the ice, sets up the sprites and the teams with
;	their structures and colors, and then runs the flow between periods and at the end of a game,
;	the opening and playoff screens, and the text player of the scouting report.

setupice	;set all variables, send non purgeable graphics, build sprite frame lists for ice rink. Called from StartGame and StartPer.
	;Decompresses the tile sets with DecompressGraphicsPlain / DecompressGraphicsWithCallback. Loads RevRinkTiles in a reverse angle replay
	;(sflags4 bit 4) and calls LoadHomeTeamGfx
	movem.l	d0-d7/a0-a6,-(sp)
	bset	#df32c,(disflags).w	;df32c
	move.w	#$C000,(VmMap2).w
	move.w	#6,(Map2col1).w
	move.w	#$DC00,(VSPRITES).w
	move.w	#$E000,(VmMap1).w
	move.w	#6,(Map1col1).w
	move.w	#$F000,(VmMap3).w
	move.w	#5,(Map3col1).w
	move.w	#$FC00,(VSCRLPM).w
	moveq	#0,d0
	bsr.w	setVram
	bclr	#sfpz,(sflags).w	;sfpz
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w	;dfng
	clr.w	(Hpos).w
	clr.w	(Vpos).w
	move.w	#$7D0,(Oldrow).w
	st	(zamx).w
	move.w	#$800,d0
	move.w	(VmMap1).w,d1
	move.w	#$7FF,d2
	bsr.w	DoFill
	clr.w	d4
	move.w	d4,(rinkvrcset).w
	movea.l	#Rinktiles,a2
	btst	#4,(sflags4).w	;reverse angle replay
	beq.w	.0	;branch if not
	movea.l	#RevRinkTiles,a2
.0
	bsr.w	DecompressGraphicsPlain
	jsr	(LoadHomeTeamGfx).l
	move.w	d4,(EASNcset).w
	bsr.w	setupEASNmap
	move.w	d4,(energybarchars).w	;energy bar chars
	movea.l	#EnergyBarMap+8,a2
	bsr.w	DecompressGraphicsPlain
	move.w	d4,(animchars).w	;crowd chars
	movea.l	#CrowdFrameList+8,a2
	bsr.w	DecompressGraphicsPlain
	move.w	d4,(arenaanimchars).w
	addi.w	#$32,d4
	move.w	d4,(spritechars).w
	bsr.w	defaultsprites
	bsr.w	setupIceRinkPal
	bsr.w	AddFramer
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$43434567,$89ABCDEF	;remap table
	move.w	d4,(BigFontChars).w
	movea.l	#BigFontMap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$71234567,$89ABCDEF	;remap table
	bsr.w	setupTeamBlocksMap
	move.w	d4,(ExtraChars).w
	btst	#gmdir,(gmode).w	;gmdir: flip pfgoal for the 12 players
	beq.w	.gok
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d0
.loop
	bchg	#pfgoal,pflags(a3)
	adda.w	#SCstruct,a3
	dbf	d0,.loop
.gok
	bsr.w	setplayercolors
	move.w	#$FFFF,(PadControlBits).w
	move.w	#$FFFF,(PadControlBits34).w
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	clr.l	(padcont+8).w
	st	(c1playernum).w
	st	(c2playernum).w
	movea.w	#(DMAList-M68K_RAM),a5
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6
	movea.w	#(pads-M68K_RAM),a3
	clr.w	d0
	clr.w	d1
	bsr.w	addframe2	;pads1 addframe
	adda.w	#$1C,a3
	bsr.w	addframe2	;pads2 addframe
	adda.w	#$1C,a3
	bsr.w	addframe2	;pads3 addframe
	adda.w	#$1C,a3
	bsr.w	addframe2	;center ice logo addframe
	adda.w	#$1C,a3
	bsr.w	addframe2	;stick/gloves addframe?
	adda.w	#$1C,a3
	bsr.w	addframe2	;?? addframe
	move.l	a5,(DMAlistend).w
	bsr.w	DoDMAList
	move.w	(sp)+,(disflags).w
	move.l	#VBlank,(vbint).w
	bclr	#dfok,(disflags).w
	bclr	#dfng,(disflags).w
	move	#$2300,sr
	movem.l	(sp)+,d0-d7/a0-a6
	rts
setupice_highlight	;Rebuild the rink sprites after a highlight replay without reloading tiles, then fade in. Uses the
	;sprite char start saved by setupice in spritechars. Called from StartHL2
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack
	bclr	#sfpz,(sflags).w
	move.w	(disflags).w,-(sp)
	bset	#dfng,(disflags).w
	clr.w	(Hpos).w
	clr.w	(Vpos).w
	move.w	#$7D0,(Oldrow).w
	st	(zamx).w
	move.w	(spritechars).w,d4
	bsr.w	defaultsprites
	bsr.w	setupIceRinkPal
	btst	#gmdir,(gmode).w
	beq.w	.gok
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d0
.loop
	bchg	#pfgoal,pflags(a3)
	adda.w	#SCstruct,a3
	dbf	d0,.loop
.gok
	bsr.w	setplayercolors
	move.w	#$FFFF,(PadControlBits).w
	move.w	#$FFFF,(PadControlBits34).w
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	clr.l	(padcont+8).w
	st	(c1playernum).w
	st	(c2playernum).w
	bsr.w	setupEASNmap
	movea.w	#(DMAList-M68K_RAM),a5
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6
	movea.w	#(pads-M68K_RAM),a3
	clr.w	d0
	clr.w	d1
	bsr.w	addframe2
	adda.w	#$1C,a3
	bsr.w	addframe2
	adda.w	#$1C,a3
	bsr.w	addframe2
	adda.w	#$1C,a3
	bsr.w	addframe2
	adda.w	#$1C,a3
	bsr.w	addframe2
	adda.w	#$1C,a3
	bsr.w	addframe2
	move.l	a5,(DMAlistend).w
	bsr.w	DoDMAList
	move.w	#$1C,(palcount).w
	move.w	(sp)+,(disflags).w
	move.l	#VBlank,(vbint).w
	bclr	#dfok,(disflags).w
	bclr	#dfng,(disflags).w
	move	#$2300,sr
	movem.l	(sp)+,d0-d7/a0-a6
	rts
setupIceRinkPal	;Copy the ice rink palettes (pal 0&1, 16 longs) to palfadenew. Called from setupice, setupice_highlight and the stats screens
	movea.l	#Rinktilelist,a0
	adda.l	(a0),a0
	moveq	#$F,d0
	movea.w	#(palfadenew-M68K_RAM),a1
.ipal
	move.l	(a0)+,(a1)+
	dbf	d0,.ipal
	rts
setupEASNmap	;Decompress the easn logo tiles (EASNmap+8) to vram at EASNcset. Called from setupice, setupice_highlight
	move.w	(EASNcset).w,d4
	movea.l	#EASNmap+8,a2
	bsr.w	DecompressGraphicsWithCallback
	dc.l	$71234567,$89ABCDEF	;remap table
	rts
ReloadEnergyBarTiles	;Reload the energy bar tiles (EnergyBarMap+8) at energybarchars. Called from the replay code and ReloadRinkGraphics
	move.w	(energybarchars).w,d4
	movea.l	#EnergyBarMap+8,a2
	bra.w	DecompressGraphicsPlain
ReloadCrowdTiles	;Reload the crowd tiles (CrowdFrameList+8) at animchars. Called from the replay code and ReloadRinkGraphics
	move.w	(animchars).w,d4
	movea.l	#CrowdFrameList+8,a2
	bra.w	DecompressGraphicsPlain
ReloadRefHorTiles	;Reload the horizontal ref tiles (RefMap2+8) at ExtraChars. Called from PauseMode
	move.w	(ExtraChars).w,d4
	movea.l	#RefMap2+8,a2
	bra.w	DecompressGraphicsPlain
ReloadRefTiles	;Reload the ref tiles (RefsMap+8) at ExtraChars. Called from the replay code
	move.w	(ExtraChars).w,d4
	movea.l	#RefsMap+8,a2
	bra.w	DecompressGraphicsPlain
ReloadFaceOffTiles	;Reload the face off tiles (FaceOffSprites+8) at faceoffvrcset. Called from the replay code
	move.w	(faceoffvrcset).w,d4
	movea.l	#FaceOffSprites+8,a2
	bra.w	DecompressGraphicsPlain
ReloadFaceOffMap	;Reload the FaceOffMap+8 tiles at ExtraChars. Called from the replay code
	move.w	(ExtraChars).w,d4
	movea.l	#FaceOffMap+8,a2
	bra.w	DecompressGraphicsPlain
setupTeamBlocksMap	;Load the TeamBlocks map tiles (Teamblocksmap) at d4+$2C and copy the home and visitor team
	;blocks to vram at basetileoffset and basetileoffset+$16. d4 = 1st vram char; return d4 = basetileoffset+$2C. Called from setupice
	move.w	d4,(basetileoffset).w
	addi.w	#$2C,d4
	movea.w	#(TeamBlockMap-M68K_RAM),a1
	movea.l	#Teamblocksmap,a0
	lea	8(a0),a2
	bsr.w	DecompressGraphicsPlain
	adda.l	4(a0),a0
	move.l	a0,-(sp)
	move.w	(HomeTeam).w,d0
	move.w	(basetileoffset).w,d1
	asl.w	#5,d1
	bsr.w	CopyTeamBlockMapData
	movea.l	(sp)+,a0
	move.w	(VisTeam).w,d0
	move.w	(basetileoffset).w,d1
	addi.w	#$16,d1
	asl.w	#5,d1
	bsr.w	CopyTeamBlockMapData
	move.w	(basetileoffset).w,d4
	addi.w	#$2C,d4
	rts
CopyTeamBlockMapData	;Copy one team's 22 block chars from the loaded tile set to vram at d1 by vram dma
	;(DoDMA_nd2), and store their map words at (a1)+. a0 = map data, d0 = team, d1 = vram address
	mulu.w	#$2C,d0
	lea	4(a0,d0.w),a0
	move.w	#$15,d3
.row
	moveq	#$20,d0
	move.w	d1,-(sp)
	move.b	(a0),(a1)
	andi.w	#$F800,(a1)
	lsr.w	#5,d1
	ori.w	#$8000,d1
	or.w	d1,(a1)+
	move.w	(sp)+,d1
	move.w	(a0)+,d2
	andi.w	#$7FF,d2
	add.w	(basetileoffset).w,d2
	addi.w	#$2C,d2
	asl.w	#5,d2
	bsr.w	DoDMA_nd2
	addi.w	#$20,d1
	dbf	d3,.row
	rts
defaultsprites	;allocate vram and assign char area for graphic structures. d4 = char area for data. Sets up the sso (4) and ffo (7) objects from
	;.listsso / .listffo, then jumps to defaultsprites2. Called from setupice and setupice_highlight
	movea.l	#.listsso,a2
	movea.w	#(sso-M68K_RAM),a3
	moveq	#3,d0	;#ssonum-1 into d0
.ssotop
	move.w	#$FFFF,oldframe(a3)	;screen objects not locked to scroll of screen
	move.w	(a2)+,(a3)
	move.w	(a2)+,2(a3)
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4
	adda.w	#$14,a3	;#ssosize
	dbf	d0,.ssotop
	movea.l	#.listffo,a2
	movea.l	#pads,a3	;ffo
	moveq	#6,d0	;#ffonum-1
.ffotop
	st	oldframe(a3)	;objects tied to screen scrolling (not players/net/puck)
	move.w	(a2)+,(a3)
	move.w	(a2)+,Ypos(a3)
	move.w	(a2)+,Zpos(a3)
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4
	adda.w	#$1C,a3	;#ffosize
	dbf	d0,.ffotop
	bra.w	defaultsprites2
.listsso
	dc.w	0	;xcord,ycord,frame,attribute,vram char size
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	9
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	9
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	9
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	0
	dc.w	9
.listffo
	dc.w	0	;xcord,ycord,zpos,frame,attribute,vram char size
	dc.w	0
	dc.w	$FFFF
	dc.w	SPFpad+2	;puck poss. star
	dc.w	0
	dc.w	7
	dc.w	0
	dc.w	0
	dc.w	$FFFF
	dc.w	SPFpad	;joypad 1 star
	dc.w	0
	dc.w	7
	dc.w	0
	dc.w	0
	dc.w	$FFFF
	dc.w	SPFpad+1	;joypad 2 star
	dc.w	0
	dc.w	7
	dc.w	0
	dc.w	0
	dc.w	$FFFF
	dc.w	SPFreplay	;replay cursor
	dc.w	$8000
	dc.w	7
	dc.w	0
	dc.w	0
	dc.w	$FFFF
	dc.w	$34C	;SPFPad3 frame (joypad 3 star)
	dc.w	0
	dc.w	7
	dc.w	0
	dc.w	0
	dc.w	$FFFF
	dc.w	$34D	;SPFPad4 frame (joypad 4 star)
	dc.w	0
	dc.w	7
	dc.w	0
	dc.w	0
	dc.w	$FFFF
	dc.w	SPFgloves
	dc.w	0
	dc.w	5
defaultsprites2	;objects which are tied to screen scrolling and have velocity: the 16 SortCords objects from .list (players, puck, puck shadow, goal
	;nets ...), the OOlist and OOlistpos; then SprSort. Also called from setoptions
	clr.w	d6
	movea.w	#(OOlist-M68K_RAM),a1
	lea	.list(pc),a2
	movea.w	#(SortCords-M68K_RAM),a3
	movea.w	#(OOlistpos-M68K_RAM),a4
.0
	moveq	#$1F,d0
	movea.w	a3,a0
.1
	clr.l	(a0)+
	dbf	d0,.1
	move.w	d6,SCnum(a3)
	st	oldframe(a3)
	st	pnum(a3)
	move.w	(a2)+,(a3)
	move.w	(a2)+,Ypos(a3)
	move.w	(a2)+,Zpos(a3)
	move.w	(a2)+,frame(a3)
	move.w	(a2)+,attribute(a3)
	move.w	d4,VRchar(a3)
	add.w	(a2)+,d4
	move.w	(a2)+,radiusx(a3)
	move.w	(a2)+,radiusy(a3)
	addq.w	#1,a2
	move.b	(a2)+,asslist(a3)
	addq.w	#1,a2
	move.b	(a2)+,pflags(a3)
	adda.w	#SCstruct,a3
	asl.w	#1,d6
	move.b	d6,(a1)+
	lsr.w	#1,d6
	move.w	d6,(a4)+
	addq.w	#1,d6
	cmp.w	#$10,d6
	bne.s	.0
	bra.w	SprSort
.list
	dc.w	$180	;xcord,ycord,zcord,frame,att,crsize,radx,rady,asslist,pflags
	;home team
	dc.w	$C0
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$80
	dc.w	$FF38
	dc.w	$FF9C
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$80
	dc.w	$FF38
	dc.w	$FFB0
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$80
	dc.w	$FF38
	dc.w	$FFC4
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$80
	dc.w	$FF38
	dc.w	$FFD8
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$80
	dc.w	$FF38
	dc.w	$FFEC
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$80
	dc.w	$C0	;visitor team
	dc.w	$C0
	dc.w	0
	dc.w	1
	dc.w	1
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$40
	dc.w	$FF38
	dc.w	$28
	dc.w	0
	dc.w	1
	dc.w	1
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$40
	dc.w	$FF38
	dc.w	$3C
	dc.w	0
	dc.w	1
	dc.w	1
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$40
	dc.w	$FF38
	dc.w	$50
	dc.w	0
	dc.w	1
	dc.w	1
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$40
	dc.w	$FF38
	dc.w	$64
	dc.w	0
	dc.w	1
	dc.w	1
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$40
	dc.w	$FF38
	dc.w	$78
	dc.w	0
	dc.w	1
	dc.w	1
	dc.w	$14
	dc.w	8
	dc.w	4
	dc.w	0
	dc.w	$40
	dc.w	0	;goal net
	dc.w	$10C
	dc.w	0
	dc.w	SPFgoal	;92 used $18E
	dc.w	0
	dc.w	$B
	dc.w	$14
	dc.w	6
	dc.w	0
	dc.w	0
	dc.w	0	;goal net 2
	dc.w	$FEF4
	dc.w	0
	dc.w	SPFgoal+1
	dc.w	0
	dc.w	$11
	dc.w	$14
	dc.w	6
	dc.w	0
	dc.w	0
	dc.w	0	;puck
	dc.w	0
	dc.w	0
	dc.w	SPFpuck+1
	dc.w	0
	dc.w	1
	dc.w	5
	dc.w	5
	dc.w	$18
	dc.w	1
	dc.w	0	;puck shadow
	dc.w	0
	dc.w	0
	dc.w	SPFpuck	;92 used $183, 4 chars
	dc.w	0
	dc.w	$11
	dc.w	3
	dc.w	3
	dc.w	$19
	dc.w	4
SprSort	;sort objects in struct SortObj and set corresponding tables for keeping them sorted later (Ylist, OOlist, OOlistpos)
	movem.l	d0-d4/a0-a2,-(sp)
	movea.l	#OOlistpos,a2
	movea.l	#Ylist,a1
	movea.l	#SortCords,a0
	move.w	#$F,d3	;Sortobjs -1
.loop0
	move.w	Ypos(a0),d4
	btst	#sfhor,(sflags).w
	beq.w	.101
	move.w	(a0),d4
.101
	move.w	d4,(a1)+
	adda.w	#SCstruct,a0
	dbf	d3,.loop0
	movea.l	#Ylist,a1
.loop
	clr.w	d4
	movea.l	#OOlist,a0
	move.w	#$E,d3
	clr.w	d0
	clr.w	d1
.0
	move.b	(a0)+,d0
	move.b	(a0),d1
	move.w	0(a1,d0.w),d2
	cmp.w	0(a1,d1.w),d2
	ble.w	.1
	move.b	d0,(a0)
	move.b	d1,-1(a0)
	move.l	a0,d2
	subi.l	#OOlist,d2
	move.w	d2,0(a2,d0.w)
	subq.w	#1,d2
	move.w	d2,0(a2,d1.w)
	st	d4
.1
	dbf	d3,.0
	tst.w	d4
	bne.s	.loop
	movem.l	(sp)+,d0-d4/a0-a2
	rts
resetplstuff	;reset team variables/and players on both teams. Called from puckfaceoff2, puckpenshot and StartHL2
	movem.l	d0-d2/a0-a3,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	.top
	movea.w	#(AwShots-M68K_RAM),a2
	bsr.w	.top
	movem.l	(sp)+,d0-d2/a0-a3
	rts
.top
	bclr	#4,tmflags(a2)	;clear team offside bit
	moveq	#5,d2
	movea.w	tmsort(a2),a3	;tmsort
.loop
	clr.b	pflags2(a3)	;pflags2
	tst.w	position(a3)	;check for goalie
	bmi.w	.next
	move.w	#SPAglide,d1	;92 $346
	bsr.w	SetSPA
	clr.w	impact(a3)	;impact
	clr.b	nopuck(a3)	;nopuck
	andi.b	#$C2,pflags(a3)	;2^pfteam + 2^pfgoal +2^pfna, pflags
.next
	adda.w	#SCstruct,a3	;SCstruct size
	dbf	d2,.loop
	rts
clearTeamStats	;clear both team structs (2 x tmsize) but keep the first $1A0 bytes of each hot / cold table (HmShots+$1A2 / AwShots+$1A2, saved to
	;homehotcoldsave / awayhotcoldsave and back) and HmShots+tmgoalie / AwShots+tmgoalie. Falls into setteams
	move.w	(tmstruct+tmgoalie).w,-(sp)
	move.w	(AwShots+tmgoalie).w,-(sp)
	movem.l	a1-a3,-(sp)
	move.w	#$19F,d0
	movea.l	#AwShots+$1A2,a1	;Hot/Cold table Away Team
	movea.l	#tmstruct+$1A2,a0	;Hot/Cold table Home Team
	movea.l	#homehotcoldsave,a2
	movea.l	#awayhotcoldsave,a3
.loop
	move.b	(a0)+,(a2)+
	move.b	(a1)+,(a3)+
	dbf	d0,.loop
	movem.l	(sp)+,a1-a3
	move.l	#$363,d0
	movea.w	#(tmstruct-M68K_RAM),a0
.loop2
	clr.b	(a0)+
	dbf	d0,.loop2
	movea.w	#(AwShots-M68K_RAM),a0
	move.w	#$363,d0
.loop3
	clr.b	(a0)+
	dbf	d0,.loop3
	movem.l	a1-a3,-(sp)
	move.w	#$19F,d0
	movea.l	#AwShots+$1A2,a1
	movea.l	#tmstruct+$1A2,a0
	movea.l	#homehotcoldsave,a2
	movea.l	#awayhotcoldsave,a3
.loop4
	move.b	(a2)+,(a0)+
	move.b	(a3)+,(a1)+
	dbf	d0,.loop4
	movem.l	(sp)+,a1-a3
	move.w	(sp)+,(AwShots+tmgoalie).w
	move.w	(sp)+,(tmstruct+tmgoalie).w
	st	(tmstruct+tmpdst+$34).w
	st	(AwShots+tmpdst+$34).w
setteams	;Use hometeam/visteam to set team structures (InitTeamStructure for each). Falls in from clearTeamStats, also called from DrawMatchupBitmaps
	movem.l	d0/a0-a2,-(sp)
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	(HomeTeam).w,d0
	move.w	#(SortCords-M68K_RAM),tmsort(a2)
	bsr.w	InitTeamStructure
	movea.w	#(AwShots-M68K_RAM),a2
	move.w	(VisTeam).w,d0
	move.w	#(SortCords-M68K_RAM)+(6*SCstruct),tmsort(a2)
	bsr.w	InitTeamStructure
	movem.l	(sp)+,d0/a0-a2
	rts
InitTeamStructure	;Set up team struct a2 for team d0: store the team number at $28, the team data address
	;at $1E (tmdata), and copy the line sets to $16A (two layouts by OptLine)
	move.w	d0,Xvel(a2)
	movea.w	#$30E,a0	;TeamList
	asl.w	#2,d0
	move.l	0(a0,d0.w),$1E(a2)
	tst.w	(OptLine).w
	beq.w	.0
	movea.l	$1E(a2),a0
	adda.w	6(a0),a0
	lea	$16A(a2),a1
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	addq.w	#8,a0
	move.w	#$B,d0
.loop
	move.l	(a0)+,(a1)+
	dbf	d0,.loop
	rts
.0
	moveq	#$D,d0
	movea.l	tmdata(a2),a0
	adda.w	6(a0),a0
	addq.w	#8,a0
	lea	$16A(a2),a1
.copy
	move.l	(a0)+,(a1)+
	dbf	d0,.copy
	rts
setplayercolors	;Copy in correct color data for each team:.team for the home team, then falls in for the visitors.
	;Called from setupice, setupice_highlight, StartHL2 and ReloadRinkGraphics
	clr.w	d1
	movea.w	#(tmstruct-M68K_RAM),a0
	bsr.w	.team
	moveq	#$20,d1
	adda.w	#$364,a0
.team	;a0 = team struct, d1 = palette offset ($20 for the visitors)
	movea.l	$1E(a0),a2
	adda.w	2(a2),a2
	adda.w	d1,a2
	movea.w	#(palfadenew+$40-M68K_RAM),a1
	adda.w	d1,a1
	moveq	#7,d0
.loop
	move.l	(a2)+,(a1)+
	dbf	d0,.loop
	rts
PeriodOver	;what to do if period over. Branched to from puckfaceoff when the clock runs out. After period 3 a tied game goes to
	;overtime (gsp 3), else the game is over (gsp 4); after overtime only a tied playoff game plays on. Falls into IntermissionStart
	addq.w	#1,(gsp).w
	bchg	#gmdir,(gmode).w
	cmpi.w	#3,(gsp).w
	blt.w	.0
	beq.w	.1
	move.w	#3,(gsp).w
	tst.w	(OptPlayMode).w
	bne.w	.1
	move.w	#4,(gsp).w
.1
	move.w	(HmGoals).w,d0
	sub.w	(AwGoals).w,d0
	beq.w	.0
	move.w	#4,(gsp).w
.0
	bsr.w	forceblack
IntermissionStart	;reset the clock, song $79, ticker scores, playoff stats at the end
	;(AddPOStats), Intermission, then StartPer or GameOver. Also jumped to from StartGame
	jsr	(ResetClock).w
	move.w	d0,-(sp)
	move.w	(vcount).w,d0
.loop
	cmp.w	(vcount).w,d0
	beq.s	.loop
	jsr	(p_turnoff).l
	move.w	d0,-(sp)
	move.w	(vcount).w,d0
.loop2
	cmp.w	(vcount).w,d0
	beq.s	.loop2
	move.w	(sp)+,d0
	move.w	#SngEOG,-(sp)
	bsr.w	song
	bsr.w	UpdateScores
	cmpi.w	#4,(gsp).w
	bne.w	.1
	bsr.w	AddPlayoffTeamStats
.1
	bsr.w	Intermission
	cmpi.w	#4,(gsp).w
	beq.w	GameOver
	jmp	(StartPer).w
GameOver	;EncodePW (save the password), then in playoff mode PlayoffStatsScreen (the playoff stats) and the playoff screen. Falls into ExitToOpening
	bsr.w	EncodePW
	tst.w	(OptPlayMode).w
	beq.w	.po
	bclr	#sfpj,(sflags).w
	jsr	(PlayoffStatsScreen).l
.po
	bsr.w	PlayoffScreen
ExitToOpening	;Song $78, then restart at Opening2. Also jumped to from demoread and NextShooter
	move.w	#SngTitle,-(sp)
	bsr.w	song
	bra.w	Opening2
Opening	;title screen (newTitleScreen), then into Opening2. Jumped to from Begin
	bsr.w	KillCrowd
	jsr	(newTitleScreen).l
Opening2	;reset the stack and clear the variables, then options (GameSetUp, UserNameEntry), playoff screen and (not in a shootout) ScoutingReport, then StartGame
	bsr.w	KillCrowd
	move	#$2700,sr
	movea.w	#(Stack-M68K_RAM),sp
	movea.w	#(VSCRLPM-M68K_RAM),a0
.0
	clr.l	(a0)+
	cmpa.w	#$D03E,a0	;clear from VSCRLPM to $FFFFD03E
	blt.s	.0
	jsr	(GameSetUp).l
	jsr	(UserNameEntry).l
Opening3	bsr.w	PlayoffScreen
	btst	#0,(gmode2).w
	bne.w	.1
	jsr	(ScoutingReport).l	;skipped in shootouts, so no global label here (.1 below is local to Opening3)
.1
	jmp	(StartGame).w
PlayoffScreen	;bring up playoff screen if in playoff mode. Called from GameOver and Opening2. Runs its own vblank and
	;scrolls the tree a page ($70 pixels) at a time. Returns when start is pressed (PlayoffScreenExit)
	tst.w	(OptPlayMode).w
	beq.w	rtss2
	move.l	#VBlank_Playoff,(vbint).l
	bclr	#df32c,(disflags).w
	move.w	#0,(VSCRLPM).w
	move.w	#$BC00,(VSPRITES).w
	move.w	#$B000,(VmMap3).w
	move.w	#6,(Map3col1).w
	move.w	#$C000,(VmMap2).w
	move.w	#7,(Map2col1).w
	move.w	#$E000,(VmMap1).w
	move.w	#7,(Map1col1).w
	move.w	#0,d0
	bsr.w	setVram
	bsr.w	printz
	String	-TXMAP1,0,0
	move.l	#$80,d0
	moveq	#$1C,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	bsr.w	printz
	String	-TXMAP3,0,0
	moveq	#$28,d0
	moveq	#2,d1
	move.w	#$7FF,d2
	bsr.w	eraser
	bsr.w	AddTeamBlock
	bsr.w	AddSmallFont
	movea.l	#Arrowsmap+8,a2
	move.w	d4,(ExtraChars).w
	bsr.w	DecompressGraphicsPlain
	bsr.w	printz
	String	-(TXPAL3+TXMAP2),0,0
	movea.l	#ScoutMap,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#3,d5
	bsr.w	dobitmap
	movea.l	#PlayoffSprite,a1
	lea	8(a1),a2
	adda.l	(a1),a1
	moveq	#7,d0
	movea.w	#(palfadenew+$40-M68K_RAM),a0
.pal
	move.l	-$40(a0),$20(a0)
	move.l	(a1)+,-$40(a0)
	move.l	-$20(a0),(a0)+
	dbf	d0,.pal
	move.w	d4,(energybarchars).w
	bsr.w	DecompressGraphicsPlain
	move.w	#$104,(clampcounter).w
	move.w	#$A0,(playoffspritey).w
	movea.l	#VDP_CTRL,a0
	move.w	#VDPR_WINY+$02,(a0)
	movea.w	#(potree-M68K_RAM),a1
	movea.l	#PlayoffTreeSetup,a0	;playoff tree layout by gamelevel
	move.w	(gamelevel).w,d0
	asl.w	#1,d0
	adda.w	0(a0,d0.w),a0
	clr.w	d4
	move.b	(a0)+,d4
.top
	bsr.w	printz
	String	-TXMAP1,0,0
	move.b	(a0)+,(printx+1).w
	move.b	(a0)+,(printy+1).w
	clr.w	d1
	move.b	(a1)+,d1
	add.w	d1,d1
	bsr.w	DrawTeamBlocks
	dbf	d4,.top
	clr.w	d4
	move.b	(a0)+,d4
.top2
	bsr.w	printz
	String	-TXMAP1,0,2
	move.b	(a0)+,(printx+1).w
	clr.w	d0
	move.b	(a0)+,d0
	bsr.w	DrawTreeArrow
	dbf	d4,.top2
	bsr.w	printz
	String	-(TXPAL1+TXMAP1),0,0
	cmpi.w	#7,(bosgames).w	;best of 7
	beq.w	.noscr
	clr.w	d4
	move.b	(a0)+,d4
	bmi.w	.noscr
	movea.w	#(gsstruct-M68K_RAM),a2
.top3
	move.b	(a0)+,(printx+1).w
	move.b	(a0)+,(printy+1).w
	bsr.w	PrintSeriesScore
	adda.w	#$10,a2
	dbf	d4,.top3
.noscr
	bsr.w	printsmallz
	String	CC_SetMapAndPosition,1,1,$41,$1A
	lea	PlayoffScreenText(pc),a1
	move.w	(gamelevel).w,d0
	bsr.w	AdvanceStringPtr
	move.w	(a1),d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	bsr.w	printsmall
	tst.w	(gamelevel).w
	beq.w	.nopage
	bsr.w	printz
	String	-(TXPAL3+TXMAP3),$A,1,'Press [ or ] to page',0	;the text as code
.nopage
	move.w	#$18,(palcount).w	;after the string
	move.w	#SngEOG,-(sp)
	bsr.w	song
	clr.w	d0
	clr.w	d4
	move.w	#$FFFF,(PlayerScrollCtr).w
	move.w	#1,(DispAttribCtr).w
	bsr.w	UpdatePlayoffScroll
.input
	bsr.w	PlayoffScreen_waitvsync
	movea.l	#rtss2,a0
	jsr	(DrawPlayoffSprite).l
	bsr.w	HandlePlayoffInput
	bra.s	.input
HandlePlayoffInput	;Read both pads: start leaves PlayoffScreen, right/left set the scroll step, then falls into UpdatePlayoffScroll
	bsr.w	ReadJoy1
	move.w	d3,-(sp)
	bsr.w	ReadJoy2
	or.w	(sp)+,d3
	btst	#7,d3
	bne.w	PlayoffScreenExit
	btst	#3,d3
	beq.w	.nr
	move.w	#$FFFE,(PlayerScrollCtr).w
.nr
	btst	#2,d3
	beq.w	UpdatePlayoffScroll
	move.w	#2,(PlayerScrollCtr).w
UpdatePlayoffScroll	;Move the tree one step (PlayerScrollCtr) and stop on a page boundary ($70). The position is
	;DispAttribCtr; playoffspritex is the sprite x offset while it is on screen
	move.w	(PlayerScrollCtr).w,d0
	beq.w	rtss2
	add.w	(DispAttribCtr).w,d0
	move.w	(gamelevel).w,d1
	cmp.w	#3,d1
	bls.w	.lim
	moveq	#3,d1
.lim
	mulu.w	#$70,d1
	cmp.w	d1,d0
	bgt.w	rtss2
	neg.w	d1
	cmp.w	d1,d0
	blt.w	rtss2
	move.w	d0,(DispAttribCtr).w
	clr.w	(playoffspritex).w
	move.w	d0,d1
	addi.w	#$100,d1
	cmp.w	#$40,d1
	blt.w	.nox
	cmp.w	#$200,d1
	bgt.w	.nox
	move.w	d1,(playoffspritex).w
.nox
	ext.l	d0
	divs.w	#$70,d0
	swap	d0
	tst.w	d0
	bne.w	rtss2
	clr.w	(PlayerScrollCtr).w
	rts
PlayoffScreenExit	;Drop HandlePlayoffInput's return address and return from PlayoffScreen
	addq.w	#4,sp
	rts
PlayoffScreen_waitvsync	;Each time palcount runs out, eor the color word at palfadenew+$42 with $EE and restart palcount at $18; then wait for the next vblank
	tst.w	(palcount).w
	bpl.w	.wait
	eori.w	#$EE,(palfadenew+$42).w
	move.w	#$18,(palcount).w
.wait
	move.w	(vcount).w,d0
	cmp.w	(oldvcount).w,d0
	beq.s	.wait
	move.w	d0,(oldvcount).w
	rts
PrintSeriesScore	;Print best of 7 wins "t-b" for game struct a2 at printx/printy
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	#6,(a1)+
	move.w	4(a2),d0
	addi.w	#$30,d0
	move.b	d0,(a1)+
	move.b	#$2D,(a1)+
	move.w	6(a2),d0
	addi.w	#$30,d0
	move.b	d0,(a1)+
	clr.b	(a1)+
	movea.w	#(mesarea-M68K_RAM),a1
	bra.w	print
DrawTreeArrow	;Draw tree arrow d0 from the arrows map (Arrowsmap) at printx/printy
	movem.l	d0-d7/a0-a3,-(sp)
	movea.l	#Arrowsmap,a0
	movea.l	a0,a1
	adda.l	(a0),a0
	adda.l	4(a1),a1
	movea.w	#$30A,a2
	clr.w	d1
	moveq	#2,d2
	moveq	#$17,d3
	move.w	(ExtraChars).w,d4
	moveq	#0,d5
	bsr.w	dobitmap
	movem.l	(sp)+,d0-d7/a0-a3
	rts
DrawTeamBlocks	;Draw team block d1 (team*2) from the TeamBlocks map (Teamblocksmap) at printx/printy; the user's team
	;(potreeteam entry of potree) is highlighted (printa $6000)
	movem.l	d0-d7/a0-a3,-(sp)
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d0
	move.b	0(a0,d0.w),d0
	add.b	d0,d0
	cmp.b	d0,d1
	bne.w	.nohi
	move.w	#$6000,(printa).w
.nohi
	movea.l	#Teamblocksmap,a1
	adda.l	4(a1),a1
	movea.w	#$30A,a2
	clr.w	d0
	move.w	(a1),d2
	moveq	#2,d3
	moveq	#2,d4
	moveq	#0,d5
	bsr.w	dobitmap
	movem.l	(sp)+,d0-d7/a0-a3
	rts
VBlank_Playoff	;the PlayoffScreen vblank handler (vbint): dma the sprite table, write
	;$FEA0+DispAttribCtr to the hscroll, cramfade. Always vcount+1, p_music_vblank, rte
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#dfng,(disflags).w
	bne.w	.nograph
	movea.w	#(Satt-M68K_RAM),a0
	move.w	(Sattsize).w,d0
	beq.w	.nosat
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	bsr.w	DoDMA
	move.w	(VSCRLPM).w,d0
	bsr.w	Vmaddr
	move.w	#$FEA0,d0
	add.w	(DispAttribCtr).w,d0
	move.w	d0,(a0)
.nosat
	bsr.w	cramfade
.nograph
	addq.w	#1,(vcount).w
	jsr	(p_music_vblank).l
	movem.l	(sp)+,d0-d7/a0-a6
	rte
PlayoffScreenText	;Round titles by gamelevel, printed with printsmall
	String	'Playoffs'
	String	'Quarterfinals'
	String	'Semifinals'
	String	'Finals'
	String	'Champions'
InitScoutingDisplay	;Start the text player ScoutTextPlayer: VertLineScrolling = -1, PlayerScrollCtr = -1, clear SelectedPlayerIdx / typedelay; return a0 = TestList. Called from
	;ScoutingReport
	move.w	#$FFFF,(VertLineScrolling).w
	st	(PlayerScrollCtr).w
	clr.w	(SelectedPlayerIdx).w
	clr.w	(typedelay).w
	movea.w	#(TestList-M68K_RAM),a0
	rts
UpdateScoutingDisplay	;Text player for ScoutingReport: prints the ScoutTextScript script word by word with a typing delay (typedelay, longer
	;after , and .). $D ends a line; special characters ( _ + $ { } [ ] < > | \ @ # % = * ^ ; ) insert team data through the $FCxxx-$FExxx
	;routines (GetTeamNickname / GetTeamArena for HmShots / AwShots). Line breaks scroll the text box. Called from ScoutingReport
	cmpi.w	#$1000,(typedelay).w
	bgt.w	rtss2
	tst.w	(asv).w
	bmi.w	.0
	subq.w	#1,(typedelay).w
	bpl.w	rtss2
.0
	movea.l	#ScoutTextScript,a1
	move.w	(PlayerScrollCtr).w,d0
	bpl.w	.3
	clr.w	(DispAttribCtr).w
	move.w	(SelectedPlayerIdx).w,d0
	addq.w	#2,(SelectedPlayerIdx).w
	movea.w	#(TestList-M68K_RAM),a0
	move.w	0(a0,d0.w),d0
	bpl.w	.1
	move.w	#$7FFF,(typedelay).w
	move.w	#$1E0,(screentimer).w
	rts
.1
	bsr.w	ScrollDisplayUp
	movea.l	a1,a2
	bra.w	.2
.loop
	cmpi.b	#$D,(a2)+
	bne.s	.loop
.2
	dbf	d0,.loop
	suba.l	a1,a2
	move.w	a2,d0
.3
	lea	0(a1,d0.w),a2
	move.w	#$A,(typedelay).w
	move.w	(DispAttribCtr).w,d0
	cmpi.b	#$5F,(a2)
	beq.w	.29
	cmpi.b	#$2B,(a2)
	beq.w	.27
	cmpi.b	#$24,(a2)
	beq.w	.20
	cmpi.b	#$7B,(a2)
	beq.w	.29
	cmpi.b	#$7D,(a2)
	beq.w	.28
	cmpi.b	#$5B,(a2)
	beq.w	.23
	cmpi.b	#$5D,(a2)
	beq.w	.22
	cmpi.b	#$3C,(a2)
	beq.w	.16
	cmpi.b	#$3E,(a2)
	beq.w	.17
	cmpi.b	#$7C,(a2)
	beq.w	.18
	cmpi.b	#$5C,(a2)
	beq.w	.19
	cmpi.b	#$40,(a2)
	beq.w	.9
	cmpi.b	#$23,(a2)
	beq.w	.10
	cmpi.b	#$25,(a2)
	beq.w	.11
	cmpi.b	#$3D,(a2)
	beq.w	.12
	cmpi.b	#$2A,(a2)
	beq.w	.13
	cmpi.b	#$5E,(a2)
	beq.w	.14
	cmpi.b	#$3B,(a2)
	beq.w	.15
	st	(PlayerScrollCtr).w
	movea.w	#(TextBuffer-M68K_RAM),a0
	clr.w	d1
.loop2
	cmpi.b	#$D,(a2)
	beq.w	.print
	addq.w	#1,d0
.loop3
	move.b	(a2),(a0)+
	addq.w	#1,d1
	cmpi.b	#$2C,(a2)
	beq.w	.4
	cmpi.b	#$2E,(a2)
	bne.w	.5
.4
	addi.w	#$28,(typedelay).w
.5
	cmpi.b	#$20,(a2)+
	bne.s	.loop2
	cmpi.b	#$20,(a2)
	beq.s	.loop3
	subq.w	#1,d0
	suba.w	a1,a2
	move.w	a2,(PlayerScrollCtr).w
.print
	move.w	d1,(mesarea).w
	addq.w	#2,(mesarea).w
	btst	#0,d1
	beq.w	.7
	clr.b	(a0)
	addq.w	#1,(mesarea).w
.7
	movea.w	#(mesarea-M68K_RAM),a1
.loop4
	cmp.w	#$1D,d0
	ble.w	.8
	bsr.w	ScrollDisplayUp
.8
	bsr.w	printz
	String	-TXMAP1,9,4
	move.w	(DispAttribCtr).w,d0
	add.w	d0,(printx).w
	move.w	(VertLineScrolling).w,d0
	add.w	d0,(printy).w
	bsr.w	print
	add.w	d1,(DispAttribCtr).w
	rts
.9
	jsr	(ScoutCrowdRecord).l
	bra.w	.append
.10
	jsr	(PlayedByHome).l
	bra.w	.append
.11
	jsr	(PlayedByAway).l
	bra.w	.append
.12
	move.l	a2,-(sp)
	movea.l	#tmstruct,a2
	jsr	(GetTeamNickname).l
	movea.l	(sp)+,a2
	bra.w	.append
.13
	move.l	a2,-(sp)
	movea.l	#AwShots,a2
	jsr	(GetTeamNickname).l
	movea.l	(sp)+,a2
	bra.w	.append
.14
	move.l	a2,-(sp)
	movea.l	#tmstruct,a2
	jsr	(GetTeamArena).l
	movea.l	(sp)+,a2
	bra.w	.append
.15
	move.l	a2,-(sp)
	movea.l	#AwShots,a2
	jsr	(GetTeamArena).l
	movea.l	(sp)+,a2
	bra.w	.append
.16
	jsr	(NextHomeHotPlayer).l
	bra.w	.roster
.17
	jsr	(NextAwayHotPlayer).l
	bra.w	.roster
.18
	jsr	(NextHomeColdPlayer).l
	bra.w	.roster
.19
	jsr	(NextAwayColdPlayer).l
	bra.w	.roster
.20
	movea.l	#tmstruct,a1
	tst.w	(awayhotter).w
	beq.w	.21
	movea.l	#AwShots,a1
.21
	movea.l	$1E(a1),a1
	adda.w	4(a1),a1
	bra.w	.append
.22
	movea.w	#(AwShots-M68K_RAM),a1
	bra.w	.24
.23
	movea.w	#(tmstruct-M68K_RAM),a1
.24
	move.w	$26(a1),d1
.roster
	movea.l	$1E(a1),a1
	adda.w	(a1),a1
	bra.w	.26
.loop5
	adda.w	(a1),a1
	addq.w	#8,a1
.26
	dbf	d1,.loop5
	bra.w	.append
.27
	movea.l	(AwayTeamRosterPtr).w,a1
	adda.w	4(a1),a1
	bra.w	.append
.28
	movea.l	(AwayTeamRosterPtr).w,a1
	bra.w	.30
.29
	movea.l	(HomeTeamRosterPtr).w,a1
.30
	adda.w	4(a1),a1
.append
	addq.w	#1,(PlayerScrollCtr).w
	add.w	(a1),d0
	subq.w	#1,d0
	move.w	(a1),d1
	subq.w	#2,d1
	tst.b	1(a1,d1.w)
	bne.w	.loop4
	subq.w	#1,d1
	bra.w	.loop4
ScrollDisplayUp	;Next text line for ScoutTextPlayer: VertLineScrolling + 1; at 7 lines, scroll the 8 rows up by vram dma (DoDMA_nd2)
	clr.w	(DispAttribCtr).w
	addq.w	#1,(VertLineScrolling).w
	cmpi.w	#7,(VertLineScrolling).l
	blt.w	rtss2
	subq.w	#1,(VertLineScrolling).w
	movem.l	d0-d3,-(sp)
	move.l	#7,d3
	move.w	(VmMap1).w,d1
	addi.w	#$212,d1
.loop
	move.l	#$3A,d0
	move.w	d1,d2
	addi.w	#$80,d2
	bsr.w	DoDMA_nd2
	move.w	d2,d1
	dbf	d3,.loop
	movem.l	(sp)+,d0-d3
	rts
