;	The Manual Goalie menu item, followed by the arena and faceoff animations.

ManualGoalieMenu	;"x Manual Goalie" menu item (menu lists; PrintMenuItem prints
	;Manual / Auto Goalie from the same words): with OptNOP set, toggle the goalie mode of the pause pad (goaliemode2 for pad 2, sflags bit 1,
	;else goaliemode1; both when the pads are on one team). In a penalty shot or shootout (gmode2 bit 0, BA_PS_flags bit 2) the pad then
	;takes player 0 / 6 or 5 / $B by its mode, when BA_Sktr_SCnum is on its side (setc1player / setc2player)
	movem.l	d0-d7/a0-a6,-(sp)
	tst.w	(OptNOP).w
	beq.w	.chkso
	move.w	(cont1team).w,d0
	cmp.w	(cont2team).w,d0
	bne.w	.0
	eori.w	#1,(goaliemode2).w
	bra.w	.g1
.0
	btst	#sfpj,(sflags).w
	beq.w	.g1
	eori.w	#1,(goaliemode2).w
	bra.w	.chkso
.g1
	eori.w	#1,(goaliemode1).w
.chkso
	btst	#0,(gmode2).w
	bne.w	.so
	btst	#2,(BA_PS_flags).w
	beq.w	.x
.so
	btst	#sfpj,(sflags).w
	bne.w	.p2
	cmpi.w	#2,(OptNOP).w
	bne.w	.4
	cmpi.w	#5,(BA_Sktr_SCnum).w
	bgt.w	.x
	bra.w	.5
.4
	cmpi.w	#5,(BA_Sktr_SCnum).w
	ble.w	.x
.5
	move.w	#0,d0
	cmpi.w	#2,(OptNOP).w
	bne.w	.6
	move.w	#6,d0
.6
	tst.w	(goaliemode1).w
	bne.w	.set1
	move.w	#5,d0
	cmpi.w	#2,(OptNOP).w
	bne.w	.set1
	move.w	#$B,d0
.set1
	jsr	(setc1player).l
	bra.w	.x
.p2
	cmpi.w	#2,(OptNOP).w
	bne.w	.9
	cmpi.w	#5,(BA_Sktr_SCnum).w
	ble.w	.x
	bra.w	.10
.9
	cmpi.w	#5,(BA_Sktr_SCnum).w
	bgt.w	.x
.10
	move.w	#6,d0
	tst.w	(goaliemode2).w
	bne.w	.set2
	move.w	#$B,d0
.set2
	jsr	(setc2player).l
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
RunArenaAnim	;Run the arena animation arenaanim (negative: none): the first time, its frame list and graphics from ArenaAnims
	;(arenaframelist / arenaspritelist, tiles to VRAM d4 = arenaanimchars: DecompressGraphicsPlain); then count down the frame time arenaframetime by d7
	;and step (NextArenaFrame). Called from periodicevents and waitxsr
	tst.w	(arenaanim).w
	bmi.w	.x2
	movem.l	d0-d7/a0-a6,-(sp)
	tst.l	(arenaspritelist).w
	bne.w	.run
	move.w	(arenaanim).w,d0
	asl.w	#3,d0
	movea.l	#ArenaAnims,a0
	move.l	0(a0,d0.w),(arenaframelist).w
	move.l	4(a0,d0.w),(arenaspritelist).w
	movea.l	4(a0,d0.w),a2
	addq.w	#8,a2
	move.w	(arenaanimchars).w,d4
	jsr	(DecompressGraphicsPlain).l
	clr.w	(arenaframeidx).w
	bsr.w	NextArenaFrame
	bra.w	.x
.run
	sub.w	d7,(arenaframetime).w
	bpl.w	.x
	addq.w	#1,(arenaframeidx).w
	bsr.w	NextArenaFrame
.x
	movem.l	(sp)+,d0-d7/a0-a6
.x2
	rts
NextArenaFrame	;Read frame arenaframeidx of the list: arenaframe = frame, arenaframetime = time; frame $FF loops to the start, $FE ends the animation (EndArenaAnim)
	movea.l	(arenaframelist).w,a0
	move.w	(arenaframeidx).w,d0
	add.w	d0,d0
	move.b	0(a0,d0.w),d1
	ext.w	d1
	move.w	d1,(arenaframe).w
	move.b	1(a0,d0.w),d1
	ext.w	d1
	move.w	d1,(arenaframetime).w
	cmpi.w	#$FFFF,(arenaframe).w
	bne.w	.0
	clr.w	(arenaframeidx).w
	bra.s	NextArenaFrame
.0
	cmpi.w	#$FFFE,(arenaframe).w
	bne.w	.x
	bsr.w	EndArenaAnim
.x
	rts
ArenaAnims	;The 8 arena animations (StartArenaAnim d0): frame list, then the graphics in ArenaGfxBank (sprite list at 4(x), tiles at 8(x))
	dc.l	ArenaFrames8,ArenaGfxBank+$416
	dc.l	ArenaFrames6,ArenaGfxBank+$C3A
	dc.l	ArenaFrames7,ArenaGfxBank+$C3A
	dc.l	ArenaFrames5,ArenaGfxBank+$1940
	dc.l	ArenaFrames4,ArenaGfxBank+$23AE
	dc.l	ArenaFrames3,ArenaGfxBank+$23AE
	dc.l	ArenaFrames2,ArenaGfxBank+$32DA
	dc.l	ArenaFrames1,ArenaGfxBank+$32DA
ArenaFrames1	;ArenaAnims frame list: (frame, time) byte pairs, $FF loops, $FE ends
	dc.b	1,$A,2,$A,3,$A,4,$A,5,$A,6,$A,7,$A,8,$A
	dc.b	9,$A,$A,$A,1,$A,2,$A,3,$A,4,$A,5,$A,6,$A
	dc.b	7,$A,8,$A,9,$A,$A,$A,1,$A,2,$A,3,$A,4,$A
	dc.b	5,$A,6,$A,7,$A,8,$A,9,$A,$A,$A,$FE,0
ArenaFrames2	;ArenaAnims frame list: (frame, time) byte pairs, $FF loops, $FE ends
	dc.b	1,$A,2,$A,3,$A,4,$A,5,$A,6,$A,7,$A,8,$A
	dc.b	9,$A,$A,$A,$FF,0
ArenaFrames3	;ArenaAnims frame list: (frame, time) byte pairs, $FF loops, $FE ends
	dc.b	1,$A,2,$A,3,$A,4,$A,5,$A,6,$A,7,$A,8,$A
	dc.b	9,$A,$A,$A,$B,$A,$C,$A,$D,$A,$E,$A,$F,$A,$10,$A
	dc.b	$11,$A,$12,$A,$13,$A,$14,$A,$15,$A,$16,$A,$17,$A,$FE,0
ArenaFrames4	;ArenaAnims frame list: (frame, time) byte pairs, $FF loops, $FE ends
	dc.b	1,8,2,8,3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C
	dc.b	3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C
	dc.b	3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C
	dc.b	3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C
	dc.b	3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C,3,$3C,4,$3C
	dc.b	2,8,1,8,$FF,0
ArenaFrames5	;ArenaAnims frame list: (frame, time) byte pairs, $FF loops, $FE ends
	dc.b	1,8,2,8,3,8,4,8,5,8,6,8,7,8,8,8
	dc.b	$FF,0
ArenaFrames6	;ArenaAnims frame list: (frame, time) byte pairs, $FF loops, $FE ends
	dc.b	1,8,2,8,3,8,4,$1E,5,8,6,8,7,8,8,$1E
	dc.b	5,8,6,8,7,8,8,$1E,9,8,$A,8,$B,8,$C,8
	dc.b	$D,8,$E,8,$FE,0
ArenaFrames7	;ArenaAnims frame list: (frame, time) byte pairs, $FF loops, $FE ends
	dc.b	$F,8,$10,8,$11,8,$12,$1E,$13,8,$14,8,$15,8,$16,$1E
	dc.b	$13,8,$14,8,$15,8,$16,$1E,$17,8,$18,8,$19,8,$1A,8
	dc.b	$1B,8,$1C,8,$FE,0
ArenaFrames8	;ArenaAnims frame list: (frame, time) byte pairs, $FF loops, $FE ends
	dc.b	1,$A,2,$A,3,$A,4,$A,5,$A,6,$A,7,$A,8,$A
	dc.b	9,$A,$A,$A,$B,$A,$C,$A,$D,$A,$E,$A,$F,$7F,$FE,0
SetCameraTop	;Unreferenced. Sflags bit 6, xc1 = 0, yc1 = $160
	bset	#sfslock,(sflags).w
	move.w	#0,(xc1).w
	move.w	#$160,(yc1).w
	rts
StartArenaAnim	;Start arena animation d0 (ArenaAnims): arenaanim = d0, RunArenaAnim loads it. Called from FallDown (7)
	;ShowGoalBox (0 on a home hat trick) and puckfaceoff2 (the one SetFaceoffAnim set)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d0,(arenaanim).w
	move.l	#0,(arenaframelist).w
	move.l	#0,(arenaspritelist).w
	move.w	#1,(arenaframe).w
	clr.w	(arenaframeidx).w
	st	(faceoffanim).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
SetFaceoffAnim	;Set the faceoff animation: sflags7 bit 0, faceoffanim = d0. Called from puckfaceoff
	bset	#0,(sflags7).w
	move.w	d0,(faceoffanim).w
	rts
EndArenaAnim	;End the arena animation: arenaanim = -1, sflags7 bit 0 cleared. Called from NextArenaFrame and puckfaceoff2
	move.w	#$FFFF,(arenaanim).w
	bclr	#0,(sflags7).w
	rts
