ChooseSong	;SongNum = byte SongIndex of the 6 song bytes of team HmTeam, or one of the 8 of RandomSongs at random
	;when 0; $FFFF with gmode bit 4. Called from StartPer, checkgoal, puckshootout and LeadSong
	movem.l	d0-d1/a0-a1,-(sp)
	btst	#4,(gmode).w
	beq.w	.0
	move.w	#$FFFF,d1
	bra.w	.1
.0
	bclr	#6,(sflags8).w
	movea.l	#TeamSongs,a0
	movea.l	#RandomSongs,a1
	move.w	(HmTeam).w,d0
	mulu.w	#6,d0
	add.w	(SongIndex).w,d0
	clr.w	d1
	move.b	0(a0,d0.w),d1
	bne.w	.1
	move.w	#8,d0
	jsr	(randomd0).l
	andi.w	#7,d0
	move.b	0(a1,d0.w),d1
.1
	move.w	d1,(SongNum).w
	movem.l	(sp)+,d0-d1/a0-a1
	rts
TeamSongs	;ChooseSong: 6 songs per team (TeamList order), 0 = random (RandomSongs)
	dc.b	$77,$75,$76,0,$5A,0
	dc.b	$31,$32,$30,0,$5A,$31
	dc.b	$34,$33,$33,$34,$5A,0
	dc.b	$35,$37,$35,$37,$36,$36
	dc.b	$38,$3A,$39,$38,$5A,$65
	dc.b	$4A,$4B,$4B,0,$5A,0
	dc.b	$3B,$3C,$3D,0,$5A,$3C
	dc.b	$3E,$3F,$3F,0,$5A,0
	dc.b	$77,$75,$76,0,$5A,0
	dc.b	$40,$42,$41,$42,$5A,$40
	dc.b	$43,$43,$45,$44,$5A,$46
	dc.b	$4F,$4E,$4F,$4D,$5A,$4C
	dc.b	$50,$51,$50,0,$5A,$52
	dc.b	$47,$48,$47,$49,$5A,$49
	dc.b	$54,$55,$53,0,$5A,0
	dc.b	$77,$75,$76,0,$5A,0
	dc.b	$56,$57,$56,$58,0,$58
	dc.b	$59,$5B,$59,$5C,$5A,$5C
	dc.b	$5D,$5E,$5D,0,$5A,$5E
	dc.b	$5F,$60,$61,$63,$64,$65
	dc.b	$67,$68,$68,$67,$5A,$69
	dc.b	$6A,$6B,$6B,0,$5A,0
	dc.b	$6C,$6C,$6D,0,$5A,0
	dc.b	$6E,$6F,$70,0,$5A,0
	dc.b	$71,$73,$71,0,$5A,$74
	dc.b	$77,$75,$76,0,$5A,0
	dc.b	$54,$55,$53,0,$5A,0
	dc.b	$54,$55,$53,0,$5A,0
RandomSongs	;ChooseSong: the 8 songs for a random pick
	dc.b	$34,$40,$42,$49,$58,$5C,$65,$66
ReadLineData	;Read the $100 bytes at save RAM $1EF6 to databuffer; sflags bit 4 cleared, lastsfx = -1, recbpr = $FFFF0000. Called from Begin and
	;GameSetUp
	movem.l	d0-d1/a0,-(sp)
	move.l	#$100,d1
	move.l	#$1EF6,d0
	movea.l	#databuffer,a0
	jsr	(ReadSRAM).l
	bclr	#4,(sflags).w
	move.w	#$FFFF,(lastsfx).w
	move.l	#M68K_RAM,(recbpr).w
	movem.l	(sp)+,d0-d1/a0
	rts
WriteLineData	;Write databuffer back to save RAM $1EF6 (WriteSRAM, MakeSRAMChecksum); as ReadLineData after. Called from EncodePW and EncodePlayerAttributes
	movem.l	d0-d1/a0,-(sp)
	move.l	#$100,d1
	move.l	#$1EF6,d0
	movea.l	#databuffer,a0
	jsr	(WriteSRAM).l
	jsr	(MakeSRAMChecksum).l
	bclr	#4,(sflags).w
	move.w	#$FFFF,(lastsfx).w
	move.l	#M68K_RAM,(recbpr).w
	movem.l	(sp)+,d0-d1/a0
	rts
ClearWinRecords	;Clear bytes 8-$B of the 8 ThreeStars records and write the $80 bytes to save RAM $D20 (WriteSRAM, MakeSRAMChecksum). Called from RecordHoldersScreen
	;(Record Holders)
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#ThreeStars,a0
	move.w	#7,d7
.loop
	clr.b	8(a0)
	clr.b	9(a0)
	clr.b	$A(a0)
	clr.b	$B(a0)
	adda.w	#$10,a0
	dbf	d7,.loop
	move.l	#$D20,d0
	move.l	#$80,d1
	movea.l	#ThreeStars,a0
	jsr	(WriteSRAM).l
	jsr	(MakeSRAMChecksum).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PSandSOpassdir	;(and comments). penalty shot / shootout: passdir = sopathdir (the end of the skate path, NextPathPoint), turned by
	;passdirlist for the bottom net. Called from shotdiradj
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(sopathdir).w,d0
	btst	#7,pflags(a3)	;check what net shooting at
	bne.w	.0	;branch if top net
	movea.l	#passdirlist,a0
	add.w	d0,d0
	move.w	0(a0,d0.w),d0
.0
	move.w	d0,(passdir).w	;move d0 into passdir
	movem.l	(sp)+,d0-d7/a0-a6
	rts
passdirlist	dc.w	0	;PSandSOpassdir: passdir for the other net
	dc.w	7
	dc.w	6
	dc.w	5
	dc.w	4
	dc.w	3
	dc.w	2
	dc.w	1
	dc.w	8
StartShootoutPath	;Shootout: pick one of the 7 skate paths (ShootoutPaths) at random (sopath) and start it (NextPathPoint). Called from NextShooter and
	;puckshootout
	movem.l	d0-d7/a0-a6,-(sp)
.loop
	move.w	#7,d0
	jsr	(randomd0).l
	cmp.w	#6,d0
	bgt.s	.loop
	move.w	d0,(sopath).w
	bclr	#3,(sflags7).w
	move.w	#$FFFF,(sopathpoint).w
	clr.w	(sopathx).w
	bsr.w	NextPathPoint
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ShootoutPaths	;The 7 shootout skate paths (NextPathPoint)
	dc.l	ShootoutPath1
	dc.l	ShootoutPath2
	dc.l	ShootoutPath3
	dc.l	ShootoutPath4
	dc.l	ShootoutPath5
	dc.l	ShootoutPath6
	dc.l	ShootoutPath7
ShootoutPath1	;ShootoutPaths path: x, y points; $80 in the high byte ends it (low byte: sopathend, then sopathdir)
	dc.w	$10,$E2,$10,$D0,$8020,5
ShootoutPath2	;ShootoutPaths path: x, y points; $80 in the high byte ends it (low byte: sopathend, then sopathdir)
	dc.w	$FFC9,$A0,$FFFF,$C8,$FFE0,$D0,$8020,5
ShootoutPath3	;ShootoutPaths path: x, y points; $80 in the high byte ends it (low byte: sopathend, then sopathdir)
	dc.w	$FFB0,$40,$1A,$BC,$8020,5
ShootoutPath4	;ShootoutPaths path: x, y points; $80 in the high byte ends it (low byte: sopathend, then sopathdir)
	dc.w	$FFCE,$58,$14,$D0,$802C,5
ShootoutPath5	;ShootoutPaths path: x, y points; $80 in the high byte ends it (low byte: sopathend, then sopathdir)
	dc.w	$FFCE,8,$20,$D0,$8028,6
ShootoutPath6	;ShootoutPaths path: x, y points; $80 in the high byte ends it (low byte: sopathend, then sopathdir)
	dc.w	$1C,$F4,8,$E0,$8020,6
ShootoutPath7	;ShootoutPaths path: x, y points; $80 in the high byte ends it (low byte: sopathend, then sopathdir)
	dc.w	$FFE6,$F8,0,$E0,$8020,2
NextPathPoint	;Next point of shootout path sopath: sopathx / sopathy = x (turned by bit 0 of $76(a3)) / y; at
	;the end ($80) sflags7 bit 3, sopathend and sopathdir
	movem.l	d0-d7/a0-a6,-(sp)
	cmpi.b	#$80,(sopathx).w
	beq.w	.x
	addq.w	#1,(sopathpoint).w
	move.w	(sopathpoint).w,d0
	asl.w	#2,d0
	movea.l	#ShootoutPaths,a0
	move.w	(sopath).w,d1
	asl.w	#2,d1
	movea.l	0(a0,d1.w),a0
	move.w	0(a0,d0.w),(sopathx).w
	btst	#0,handed(a3)
	beq.w	.0
	neg.w	(sopathx).w
.0
	move.w	2(a0,d0.w),(sopathy).w
	cmpi.b	#$80,4(a0,d0.w)
	bne.w	.x
	bset	#3,(sflags7).w
	clr.w	(sopathend).w
	move.b	5(a0,d0.w),(sopathend+1).w
	move.w	6(a0,d0.w),(sopathdir).w
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
SkatePath	;Shootout skate path: d0 / d1 = the point (mirrored for the bottom net); within $A of it ($12 while $28 / $2A(a3) are 0) take
	;the next one (NextPathPoint). Called from asspuckc
	movem.l	d2-d7/a0-a6,-(sp)
	cmpi.b	#$80,(sopathx).w
	beq.w	.x
	move.w	(sopathx).w,d0
	move.w	(sopathy).w,d1
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d0
	neg.w	d1
.0
	sub.w	(a3),d0
	bpl.w	.1
	neg.w	d0
.1
	tst.w	Xvel(a3)
	bne.w	.2
	tst.w	Yvel(a3)
	bne.w	.2
	cmp.w	#$12,d0
	ble.w	.3
.2
	cmp.w	#$A,d0
	bgt.w	.7
.3
	sub.w	Ypos(a3),d1
	bpl.w	.4
	neg.w	d1
.4
	tst.w	Xvel(a3)
	bne.w	.5
	tst.w	Yvel(a3)
	bne.w	.5
	cmp.w	#$12,d1
	ble.w	.6
.5
	cmp.w	#$A,d1
	bgt.w	.7
.6
	bsr.w	NextPathPoint
.7
	move.w	(sopathx).w,d0
	move.w	(sopathy).w,d1
.x
	movem.l	(sp)+,d2-d7/a0-a6
	rts
ShootoutShootCheck	;Shootout, skater a3 has the puck (gmode2 bit 1): Z set (d0 is restored) = shoot now: after 3 (shootoutclock) at the path
	;end, within sopathend of its last point, or with the puck stopped before $F. Called from asspuckc
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#1,(gmode2).w
	beq.w	.5
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	bne.w	.5
	cmpi.w	#3,(shootoutclock).w
	ble.w	.4
	cmpi.b	#$80,(sopathx).w
	beq.w	.4
	btst	#3,(sflags7).w
	bne.w	.0
	tst.w	(puckvx).w
	bne.w	.5
	tst.w	(puckvy).w
	bne.w	.5
	cmpi.w	#$F,(shootoutclock).w
	blt.w	.4
	bra.w	.5
.0
	move.w	(sopathx).w,d0
	move.w	(sopathy).w,d1
	btst	#7,pflags(a3)
	bne.w	.1
	neg.w	d0
	neg.w	d1
.1
	sub.w	(a3),d0
	bpl.w	.2
	neg.w	d0
.2
	sub.w	Ypos(a3),d1
	bpl.w	.3
	neg.w	d1
.3
	cmp.w	(sopathend).w,d0
	bgt.w	.5
	cmp.w	(sopathend).w,d1
	bgt.w	.5
.4
	clr.w	d0
	bra.w	.x
.5
	move.w	#1,d0
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
UnpackPicture	;Unpack a picture a2: count.w, then 3 bytes per row of 8 pixels to 4 bit pixels + 5 at picturebuf (count first). Called from
	;DrawPictureBox, DrawMatchupPicture and PlayerCardScreen
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#picturebuf,a0
	movea.l	#picturebits,a1
	move.w	(a2)+,d0
	move.w	d0,(a0)+
	asl.w	#3,d0
	subq.w	#1,d0
.loop
	clr.l	(a0)
	clr.l	(a1)
	move.b	(a2)+,(a1)
	move.b	(a2)+,1(a1)
	move.b	(a2)+,2(a1)
	move.l	#0,-(sp)
	move.l	(a1),d2
	andi.l	#$E0000000,d2
	lsr.l	#1,d2
	addi.l	#$50000000,d2
	or.l	d2,(sp)
	move.l	(a1),d2
	andi.l	#$1C000000,d2
	lsr.l	#2,d2
	addi.l	#$5000000,d2
	or.l	d2,(sp)
	move.l	(a1),d2
	andi.l	#$3800000,d2
	lsr.l	#3,d2
	addi.l	#$500000,d2
	or.l	d2,(sp)
	move.l	(a1),d2
	andi.l	#$700000,d2
	lsr.l	#4,d2
	addi.l	#$50000,d2
	or.l	d2,(sp)
	move.l	(a1),d2
	andi.l	#$E0000,d2
	lsr.l	#5,d2
	addi.l	#$5000,d2
	or.l	d2,(sp)
	move.l	(a1),d2
	andi.l	#$1C000,d2
	lsr.l	#6,d2
	addi.l	#$500,d2
	or.l	d2,(sp)
	move.l	(a1),d2
	andi.l	#$3800,d2
	lsr.l	#7,d2
	addi.l	#$50,d2
	or.l	d2,(sp)
	move.l	(a1),d2
	andi.l	#$700,d2
	move.w	#8,d5
	lsr.l	d5,d2
	addq.l	#5,d2
	or.l	d2,(sp)
	move.l	(sp)+,(a0)+
	dbf	d0,.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts
LoadHomeTeamGfx	;Load the HomeTeam graphics of TeamGfxList to VRAM d4 - $18 (DoDMA_clearCallbackPointer). Called from setupice, ClrHor and
	;ReloadRinkGraphics
	move.w	d0,-(sp)
	subi.w	#$18,d4
	movea.l	#TeamGfxList,a2
	move.w	(HomeTeam).w,d0
	asl.w	#2,d0
	movea.l	0(a2,d0.w),a2
	addq.w	#8,a2
	jsr	(DoDMA_clearCallbackPointer).l
	move.w	(sp)+,d0
	rts
TeamGfxList	;LoadHomeTeamGfx: one address per team (TeamList order) in ArenaGfxBank
	dc.l	ArenaGfxBank+$3FB4,ArenaGfxBank+$8BAE,ArenaGfxBank+$42BE,ArenaGfxBank+$45C8
	dc.l	ArenaGfxBank+$48D2,ArenaGfxBank+$4BDC,ArenaGfxBank+$4EE6,ArenaGfxBank+$51F0
	dc.l	ArenaGfxBank+$54FA,ArenaGfxBank+$5804,ArenaGfxBank+$5B0E,ArenaGfxBank+$5E18
	dc.l	ArenaGfxBank+$6122,ArenaGfxBank+$642C,ArenaGfxBank+$6736,ArenaGfxBank+$6A40
	dc.l	ArenaGfxBank+$6D4A,ArenaGfxBank+$7054,ArenaGfxBank+$735E,ArenaGfxBank+$7668
	dc.l	ArenaGfxBank+$7972,ArenaGfxBank+$7C7C,ArenaGfxBank+$7F86,ArenaGfxBank+$8290
	dc.l	ArenaGfxBank+$859A,ArenaGfxBank+$88A4,ArenaGfxBank+$8EB8,ArenaGfxBank+$8EB8
PrintPlayerAssists	;Print " (n)": byte $CE + d0 of team a2, then the next row at x $E. Called from DisplayPlayerAttributeMenu
	movem.l	d0/a2,-(sp)
	jsr	(printz).l
	String	' ('
	adda.w	#$CE,a2
	bra.w	PrintParenNumber
PrintPlayerGoals	;As PrintPlayerAssists with byte $B4 + d0. Called from DisplayPlayerAttributeMenu
	movem.l	d0/a2,-(sp)
	jsr	(printz).l
	String	' ('
	adda.w	#$B4,a2
PrintParenNumber	;PrintPlayerAssists / PrintPlayerGoals: the number (1 to 3 digits, PushNumberWidth) and ")"
	move.b	0(a2,d0.w),d0
	ext.w	d0
	move.w	#1,d1
	cmp.w	#9,d0
	ble.w	.0
	move.w	#2,d1
	cmp.w	#$63,d0
	ble.w	.0
	move.w	#3,d1
.0
	jsr	(PushNumberWidth).l
	jsr	(print).l
	jsr	(printz).l
	String	')'
	addq.w	#1,(printy).w
	move.w	#$E,(printx).w
	movem.l	(sp)+,d0/a2
	rts
PlaceBoardFall	;A player falling into the boards (SPAboardtop ... SPAboardmidl). For frames $1776 / $185A (y to $124 / $FEDC, or $116 / $FEEA by FallXPos) and $17E8
	;/ $1A00 / $18CC / $193E (x to +-$82 /
	;$88 by bit 3 of 4(a3)) of $58(a3): move player a3 half way there. Called from updateplayers
	cmpi.w	#$193E,SPA(a3)
	beq.w	.12
	cmpi.w	#$1A00,SPA(a3)
	beq.w	.8
	cmpi.w	#$18CC,SPA(a3)
	beq.w	.10
	cmpi.w	#$17E8,SPA(a3)
	beq.w	.6
	cmpi.w	#$1776,SPA(a3)
	beq.w	.0
	cmpi.w	#$185A,SPA(a3)
	beq.w	.3
	bra.w	.x
.0
	move.w	#$124,d0
	cmpi.w	#$56,(FallXPos).w
	bgt.w	.1
	cmpi.w	#$FFAA,(FallXPos).w
	bgt.w	.2
.1
	move.w	#$116,d0
.2
	sub.w	Ypos(a3),d0
	bmi.w	.x
	asr.w	#1,d0
	add.w	d0,Ypos(a3)
	bra.w	.x
.3
	move.w	#$FEDC,d0
	cmpi.w	#$56,(FallXPos).w
	bgt.w	.4
	cmpi.w	#$FFAA,(FallXPos).w
	bgt.w	.5
.4
	move.w	#$FEEA,d0
.5
	sub.w	Ypos(a3),d0
	bpl.w	.x
	asr.w	#1,d0
	add.w	d0,Ypos(a3)
	bra.w	.x
.6
	move.w	#$82,d0
	btst	#3,4(a3)
	beq.w	.7
	move.w	#$FF7E,d0
.7
	sub.w	(a3),d0
	asr.w	#1,d0
	add.w	d0,(a3)
	bra.w	.x
.8
	move.w	#$88,d0
	btst	#3,4(a3)
	beq.w	.9
	move.w	#$FF78,d0
.9
	sub.w	(a3),d0
	asr.w	#1,d0
	add.w	d0,(a3)
	bra.w	.x
.10
	move.w	#$FF7E,d0
	btst	#3,4(a3)
	beq.w	.11
	move.w	#$82,d0
.11
	sub.w	(a3),d0
	asr.w	#1,d0
	add.w	d0,(a3)
	bra.w	.x
.12
	move.w	#$FF78,d0
	btst	#3,4(a3)
	beq.w	.13
	move.w	#$88,d0
.13
	sub.w	(a3),d0
	asr.w	#1,d0
	add.w	d0,(a3)
.x
	rts
GetLeagueCrowdRecord	;d0 = the team (of 28) with the highest crowd record byte 8 (clrCrowdRAM; 0 counts as $50). Called from DisplayGameStats
	movem.l	d1-d7/a0-a6,-(sp)
	move.w	#$1B,d1
	ext.l	d1
	clr.w	d7
	movea.l	#ThreeStars,a0
.loop
	jsr	(clrCrowdRAM).l
	clr.w	d2
	move.b	8(a0),d2
	bne.w	.0
	move.w	#$50,d2
.0
	cmp.w	d7,d2
	ble.w	.1
	move.w	d2,d7
	move.w	d1,d0
.1
	dbf	d1,.loop
	movem.l	(sp)+,d1-d7/a0-a6
	rts
getFgtbyte	;(and comments). Called from setInjuryType
	clr.w	d0	;clear d0
	move.b	fighting(a2),d0	;move H/F bit into d0 (this is always even)
	lsr.w	#2,d0	;shift 2 right (divide by 4)
	rts
chkFgtBit1	;test bit 1 of $74(a2). Called from setInjuryType
	btst	#1,fighting(a2)
	rts
RandomFaceoffAnim	;d0 = a random faceoff animation from FaceoffAnims, 6 when fox <= -$40 and foy <= $C0. Called from puckfaceoff
	movem.l	a0,-(sp)
	movea.l	#FaceoffAnims,a0
	move.w	#$64,d0
	jsr	(randomd0).l
	andi.w	#7,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),d0
	cmpi.w	#$FFC0,(fox).w
	bgt.w	.x
	cmpi.w	#$C0,(foy).w
	bgt.w	.x
	move.w	#6,d0
.x
	movem.l	(sp)+,a0
	rts
FaceoffAnims	;RandomFaceoffAnim animations
	dc.w	3,5,3,1,5,2,3,3,$FFFF
CheckScoreLeader	;Compare the scores ($24 of HmShots / AwShots) and test $28 of the leader for $13; the result is not used (bne.w *+4). Called from puckfaceoff
	movem.l	d0-d2/a0-a2,-(sp)
	movea.l	#tmstruct,a0
	movea.l	#AwShots,a1
	move.w	$24(a0),d0
	sub.w	$24(a1),d0
	beq.w	.x
	bpl.w	.0
	exg	a0,a1
.0
	cmpi.w	#$13,$28(a0)
	bne.w	*+4
.x
	movem.l	(sp)+,d0-d2/a0-a2
	rts
DrawPlayoffSprite	;The PlayoffSprite sprite at playoffspritex / playoffspritey in Satt, then end the sprite list (Sattsize = its size). Called from PlayoffScreen
	movea.w	#(Satt-M68K_RAM),a6
	moveq	#1,d6
	movea.l	#PlayoffSprite,a0
	move.w	(energybarchars).w,d3
	ori.w	#$8000,d3
	move.w	(playoffspritex).w,d0
	move.w	(playoffspritey).w,d1
	move.w	#1,d2
	jsr	(SetSframe).l
	cmpa.w	#$C018,a6
	bne.w	.0
	clr.l	(a6)+
	clr.l	(a6)+
.0
	clr.b	-5(a6)
	move.l	a6,d0
	subi.l	#Satt,d0
	lsr.w	#1,d0
	move.w	d0,(Sattsize).w
	rts
HiScoreScreen	;vb2, the bitmap and HiScoreImg, then wait up to $50 * 4 frames or a button (waitx). Called from Begin (attract mode)
	move.l	#vb2,(vbint).w
	bclr	#1,(disflags).w
	move.w	#5,(Map3col1).w
	move.w	#$A000,(VmMap2).w
	move.w	#7,(Map2col1).w
	move.w	#$C000,(VmMap1).w
	move.w	#7,(Map1col1).w
	move.w	#$F000,(VmMap3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	jsr	(forceblack).l
	movea.w	#(palfadenew-M68K_RAM),a0
	moveq	#$1F,d1
.loop
	clr.l	(a0)+
	dbf	d1,.loop
	jsr	(setVram_0).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),$E,3
	movea.l	#PlayoffSprite+$12E0,a2
	movea.l	a2,a0
	movea.l	a2,a1
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	clr.w	d4
	moveq	#$F,d5
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),$10,$10
	movea.l	#HiScoreImg,a2
	movea.l	a2,a0
	movea.l	a2,a1
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#0,d5
	jsr	(dobitmap).l
	move.w	#$18,(palcount).w
	move	#$2500,sr
	move.w	#$50,(seed).w
.loop2
	moveq	#4,d0
	jsr	(waitx).l
	tst.w	d1
	bne.w	.0
	subq.w	#1,(seed).w
	bpl.s	.loop2
.0
	move	#$2700,sr
	rts
GetTeamStruct	;a2 = HmShots, or AwShots when team d2 is not $28 of HmShots. Called from PrintStartingLine
	movea.l	#tmstruct,a2
	cmp.w	Xvel(a2),d2
	beq.w	.x
	movea.l	#AwShots,a2
.x
	rts
CountButtonPress	;Not in gmode bit 0: add 1 to homepresses (awaypresses for d4), and to the next long unless TempWord1 is 8 or $54(a3). Called from doinput_ispc
	movem.l	d1-d7/a0,-(sp)
	btst	#0,(gmode).w
	bne.w	.x
	move.w	(TempWord1).w,d1
	movea.l	#homepresses,a0
	tst.w	d4
	beq.w	.0
	movea.l	#awaypresses,a0
.0
	addq.l	#1,(a0)
	cmp.w	#8,d1
	beq.w	.x
	cmp.w	facedir(a3),d1
	beq.w	.x
	addq.l	#1,4(a0)
.x
	movem.l	(sp)+,d1-d7/a0
	rts
TerminateLogName	;nothing calls it (it as data). The GetLogName String at lognametext, ended with 0 at namelength and its length word made even
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#lognametext,a1
	bsr.w	GetLogName
	move.w	(namelength).w,d0
	move.b	#0,(a1,d0.w)
	addq.w	#1,d0
	andi.w	#$FFFE,d0
	move.w	d0,-2(a1)
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PlayedByHome	;a1 = String "(played by NAME)" for homeuser (GetLogName name), or an empty String for 0. Called from ScoutTextPlayer
	movem.l	d0-d7/a0/a2-a6,-(sp)
	move.w	(homeuser).w,d0
PlayedByText	;PlayedByHome / PlayedByAway body
	tst.w	d0
	beq.w	PlayedByNone
	movea.l	#nameentrybuf+2,a1
	move.w	d0,(namelogsel).w
	bsr.w	GetLogName
	adda.w	(namelength).w,a1
	move.b	#0,(a1)
	addq.w	#1,(namelength).w
	andi.w	#$FFFE,(namelength).w
	addq.w	#2,(namelength).w
	move.w	(namelength).w,(nameentrybuf).w
	movea.l	#nameentrybuf,a1
	move.l	a1,-(sp)
	movea.l	#TempBuffer,a3
	movea.l	#PlayedByTxt,a1
	bsr.w	StartText
	movea.l	(sp)+,a1
	movea.l	#TempBuffer,a3
	jsr	(appstring).l
	movea.l	#TempBuffer,a3
	jsr	(appendz).l
	String	')'
	movea.l	#TempBuffer,a1
PlayedByExit	;Exit
	movem.l	(sp)+,d0-d7/a0/a2-a6
	rts
PlayedByTxt	;PlayedByHome text
	String	'(played by '
PlayedByEmptyTxt	;PlayedByHome: the empty String
	dc.w	2	;empty String
PlayedByNone	;PlayedByHome: no name
	movea.l	#PlayedByEmptyTxt,a1
	bra.s	PlayedByExit
PlayedByAway	;As PlayedByHome for awayuser. Called from ScoutTextPlayer
	movem.l	d0-d7/a0/a2-a6,-(sp)
	move.w	(awayuser).w,d0
	bra.w	PlayedByText
SetSflags8Bit1	;Always sets sflags8 bit 1 (the bclr is skipped). Called from updateplayers
	bra.w	.set
	bclr	#1,(sflags8).w
	bra.w	.ex
.set
	bset	#1,(sflags8).w	;set bit 1 of sflags8
.ex
	rts
AttribAdjust	;(and comments). an attribute under $32 becomes d0 / 2 + $19. Called from AttribRating, PrintOverallRating and PrintMatchupRatings
	cmp.w	#$32,d0	;'2'   ; compare $32 to d0
	bge.w	.exit	;branch if greater than
	asr.w	#1,d0	;divide by 2
	addi.w	#$19,d0	;add $19 (25 dec)
.exit
	rts
PuckComingToward	;nothing calls it. Z clear when the puck is within $1E of player a3 and moving toward him (x, then y); d0-d1 kept
	movem.w	d0-d1,-(sp)
	move.w	(puckx).w,d0
	sub.w	(a3),d0
	cmp.w	#$1E,d0
	bgt.w	.x
	move.w	(puckvx).w,d1
	eor.w	d1,d0
	andi.w	#$8000,d0
	beq.w	.x
	move.w	(pucky).w,d0
	sub.w	Ypos(a3),d0
	cmp.w	#$1E,d0
	bgt.w	.x
	move.w	(puckvy).w,d1
	eor.w	d1,d0
	andi.w	#$8000,d0
.x
	movem.w	(sp)+,d0-d1
	rts
ReadGoaliePulled	;(and comments). Z clear when the team of a3 pulled its goalie ($26 of the team struct). Called from doshot
	;assdefo, asspuckc and assnearest
	movem.l	a1,-(sp)
	movea.l	#tmstruct,a1
	btst	#6,pflags(a3)	;check if home or away 0=home 1=away
	beq.w	.chkgoalie
	movea.l	#AwShots,a1
.chkgoalie
	tst.w	$26(a1)
	movem.l	(sp)+,a1
	rts
EndOneTimer	;End a one-timer for a3: bits cleared, onetimerplayer = -1, SetSPA $50C, then assexit (goalie) or Setplass. Called from assonetimer and checkgoal (.setass)
	movem.l	d0/a0,-(sp)
	bclr	#pf3onetimer,pflags3(a3)
	bclr	#5,pflags(a3)
	bclr	#1,pflags2(a3)
	clr.w	(onetimerflags).w
	st	(onetimerplayer).w
	move.w	d1,-(sp)
	move.w	#$50C,d1
	jsr	(SetSPA).l
	tst.w	position(a3)
	bpl.w	.0
	jsr	(assexit).l
	bra.w	.1
.0
	jsr	(Setplass).l
.1
	clr.w	SPAnum(a3)
	st	SPAcnt(a3)
	move.w	(sp)+,d1
	movem.l	(sp)+,d0/a0
	rts
newTitleScreen	;the title screen (TitleScreenImg, NHLShieldImg, PAlogoImg, TitleImg) with the vblank TitleVBlank, song $78, then the
	;scrolling credits (Credits, CreditsList text; CreditsPrintRow, CreditsWait) until start. Called from Opening
	move	#$2700,sr
	move.w	(VDP_CNTR).l,(seed).w
	move.w	(VDP_CNTR).l,(seed+2).w
	move.l	#VBlank_TitleScreen,(vbint).l
	bset	#1,(disflags).w
	move.w	#5,(Map3col1).w
	move.w	#$A000,(VmMap2).w
	move.w	#7,(Map2col1).w
	move.w	#$C000,(VmMap1).w
	move.w	#7,(Map1col1).w
	move.w	#$F000,(VmMap3).w
	move.w	#$F800,(VSPRITES).w
	move.w	#$FC00,(VSCRLPM).w
	move.w	#0,d0
	jsr	(setvram).l
	movea.l	#VDP_DATA,a0
	move.w	#VDPR_WINX,Vctrl-Vdata(a0)
	move.w	#VDPR_WINY+$17,Vctrl-Vdata(a0)
	move.w	#VDPR_MODE3+$03,Vctrl-Vdata(a0)
	clr.w	(Vscroll).w
	jsr	(printz).l
	String	-TXMAP1,0,0
	move.l	#$80,d0	;(and the Strings)
	moveq	#$20,d1
	move.l	#$7FF,d2
	jsr	(eraser).l
	jsr	(printz).l
	String	-TXMAP2,0,0
	move.l	#$80,d0
	moveq	#$20,d1
	move.l	#$7FF,d2
	jsr	(eraser).l
	clr.w	d4
	move.w	d4,-(sp)
	jsr	(printz).l
	String	-TXMAP3,0,0
	movea.l	#TitleScreenImg,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	#$17,d3
	moveq	#$F,d5
	jsr	(dobitmap).l
	move.w	d4,(TempWord1).w
	move.w	(sp)+,d4
	jsr	(printz).l
	String	-TXMAP2,0,$17
	movea.l	#TitleScreenImg,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	move.w	#$17,d1
	move.w	(a1),d2
	move.w	#5,d3
	moveq	#0,d5
	bset	#0,(sflags6).w
	jsr	(dobitmap).l
	bclr	#0,(sflags6).w
	move.w	(TempWord1).w,d4
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),1,1
	movea.l	#NHLShieldImg,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#8,d5
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),$19,1
	movea.l	#PAlogoImg,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#0,d5
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),1,$E
	movea.l	#TitleImg,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#8,d5
	jsr	(dobitmap).l
	clr.w	(palfadenew).w
	clr.l	(fofdata2).w
	clr.w	(fofdata2+4).w
	move.w	d4,(smallfontchars).w
	movea.l	#SmallFontMap+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$0D104567,$89ABCDEF	;remap table. FF210 + FF211 = Palette assignment for scrolling credits
	jsr	(printz).l
	String	-(TXPAL1+TXMAP1),0,0
	movea.l	#Credits,a1	;start of credits for scrolling
	jsr	(CreditsPrintRow).l
	addi.w	#$20,(Vscroll).w
	move.w	#$104,(clampcounter).w
	move.w	#$120,(playoffspritex).w
	move.w	#$D0,(playoffspritey).w
	clr.w	(asv).w
	move.w	#$FFCE,(DispAttribCtr).w
	move.w	#$20,(palcount).w
	move.w	#SngTitle,-(sp)
	jsr	(song).l
	bsr.w	CreditsLineScroll
	move	#$2500,sr
.loop
	jsr	(CreditsWait).l
	tst.w	(clampcounter).w
	bne.s	.loop
	move.w	#$3C,d3
.loop2
	jsr	(CreditsWait).l
	dbf	d3,.loop2
	jsr	(printz).l
	String	-(TXPAL1+TXMAP1),0,0
	movea.l	#CreditsList,a1
.loop3
	jsr	(CreditsPrintRow).l
	adda.w	(a1),a1
	moveq	#$27,d4
.loop4
	jsr	(CreditsWait).l
	jsr	(CreditsWait).l
	addq.w	#1,(Vscroll).w
	dbf	d4,.loop4
	moveq	#$78,d4
.loop5
	jsr	(CreditsWait).l
	dbf	d4,.loop5
	tst.w	2(a1)
	bpl.s	.loop3
	rts
CreditsPrintRow	;Credits: clear the row below the screen (Vscroll / 8 + $1C) and print the Strings from a1 centred there
	move.w	(Vscroll).w,d0
	asr.w	#3,d0
	addi.w	#$1C,d0
	andi.w	#$1F,d0
	move.w	d0,(printy).w
	move.w	d0,-(sp)
	clr.w	(printx).w
	moveq	#$20,d0
	moveq	#6,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	move.w	(sp)+,(printy).w
.loop
	move.w	(a1),d0
	asr.w	#1,d0
	neg.w	d0
	addi.w	#$11,d0
	move.w	d0,(printx).w
	jsr	(print).l
	addq.w	#1,(printy).w
	andi.w	#$1F,(printy).w
	tst.w	2(a1)
	bpl.s	.loop
	rts
CreditsWait	;Credits: wait for vcount, run the clampcounter count down; start (orjoy bit 7) returns from the caller too
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(vcount).w,d0
.loop
	cmp.w	(vcount).w,d0
	beq.s	.loop
	subq.w	#2,(clampcounter).w
	bpl.w	.0
	clr.w	(clampcounter).w
.0
	jsr	(orjoy).l
	btst	#7,d1
	movem.l	(sp)+,d0-d7/a0-a6
	beq.w	.x
	addq.w	#4,sp
.x
	rts
VBlank_TitleScreen	;newTitleScreen vblank: line scroll table (SortCords) and Vscroll, sprites, cramfade, CreditsScrollStep, p_music_vblank
	movem.l	d0-d7/a0-a6,-(sp)
	btst	#2,(disflags).w
	bne.w	.1
	movea.w	#(SortCords-M68K_RAM),a0
	move.w	(VSCRLPM).w,d1
	move.w	#$1C0,d0
	jsr	(DoDMA).l
	movea.l	#VDP_DATA,a0
	move.l	#VSRAM_W,Vctrl-Vdata(a0)
	move.w	(Vscroll).w,(a0)
	movea.w	#(Satt-M68K_RAM),a0
	move.w	(Sattsize).w,d0
	beq.w	.0
	clr.w	(Sattsize).w
	move.w	(VSPRITES).w,d1
	jsr	(DoDMA).l
.0
	jsr	(cramfade).l
.1
	addq.w	#1,(vcount).w
	jsr	(CreditsScrollStep).l
	jsr	(p_music_vblank).l
	movem.l	(sp)+,d0-d7/a0-a6
	rte
CreditsLineScroll	;Credits: the line scroll table at SortCords
	movem.l	d0-d1,-(sp)
	move.w	#$14,(Hscroll).w
	move.w	#$50,(TempWord2).w
	move.w	#$50,d0
	movea.l	#SortCords,a0
	move.l	#$FD80,d1
.loop
	move.l	d1,(a0)+
	btst	#0,d0
	bne.w	.0
	subq.w	#1,d1
.0
	dbf	d0,.loop
	move.w	#$60,d0
	move.l	#$100,d1
.loop2
	move.l	d1,(a0)+
	addq.l	#4,d1
	dbf	d0,.loop2
	movem.l	(sp)+,d0-d1
	rts
CreditsScrollStep	;Credits: line scroll step, every TempWord2 frames
	subq.w	#1,(TempWord2).w
	bmi.w	.0
	rts
.0
	clr.w	(TempWord2).w
	movem.l	d0-d2/a0,-(sp)
	move.w	#$DF,d0
	movea.w	#(SortCords-M68K_RAM),a0
.loop
	tst.l	(a0)+
	cmp.w	#$28,d0
	ble.w	.2
	move.w	(Hscroll).w,d1
	cmp.w	#$8F,d0
	blt.w	.1
	move.w	-2(a0),d2
	beq.w	.2
	add.w	d1,d2
	move.w	d2,-2(a0)
	andi.w	#$FC00,d2
	cmp.w	#$FC00,d2
	beq.w	.2
	move.w	#0,-2(a0)
	bra.w	.2
.1
	sub.w	d1,-2(a0)
	bpl.w	.2
	clr.w	-2(a0)
.2
	dbf	d0,.loop
	movem.l	(sp)+,d0-d2/a0
	rts
TeamLogoPalettes	;Team logo palettes, 16 colors per team. Used by PeriodStatsScreen, ClearCardText, DrawMatchupLogo and DrawTeamLogo
	;24 are the matchup logo palettes of TeamPalettes and incbin those files; BOS, FLA, HFD and SJ differ and have their own
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalANHA.pal	;ANH, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\TeamLogoPalBOS.pal	;BOS: differs from MatchupPalBOSA.pal
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalBUFA.pal	;BUF, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalCGYA.pal	;CGY, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalCHIA.pal	;CHI, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalDALA.pal	;DAL, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalDETA.pal	;DET, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalEDMA.pal	;EDM, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\TeamLogoPalFLA.pal	;FLA: differs from MatchupPalFLAA.pal
	incbin	..\Extracted\NHL94\Graphics\Pals\TeamLogoPalHFD.pal	;HFD: differs from MatchupPalHFDA.pal
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalLAA.pal	;LA, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalMTLA.pal	;MTL, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNJA.pal	;NJ, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNYIA.pal	;NYI, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNYRA.pal	;NYR, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalOTWA.pal	;OTW, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalPHIA.pal	;PHI, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalPITA.pal	;PIT, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalQUEA.pal	;QUE, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\TeamLogoPalSJ.pal	;SJ: differs from MatchupPalSJA.pal
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalSTLA.pal	;STL, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalTBA.pal	;TB, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalTORA.pal	;TOR, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalVANA.pal	;VAN, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalWSHA.pal	;WSH, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalWPGA.pal	;WPG, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalASEA.pal	;ASE, the TeamPalettes matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalASWA.pal	;ASW, the TeamPalettes matchup logo palette
LeadSong	;Not in a shootout (gmode2 bit 1), scores not level: once (sflags2 bit 5), ChooseSong with SongIndex 1 (home ahead) or 4
	;and sflags8 bit 6; sflags2 is put back on exit. Called from puckfaceoff2
	movem.l	d0/a0-a3,-(sp)
	move.w	(sflags2).w,-(sp)
	btst	#1,(gmode2).w
	bne.w	LeadSongExit
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	$364(a2),a3
	move.w	$24(a2),d0
	sub.w	OldZpos(a3),d0
	beq.w	LeadSongExit
	bpl.w	.0
	btst	#6,(sflags2).w
	bne.w	.1
	bsr.w	ClearLeadSong
	bset	#6,(sflags2).w
	bra.w	.1
.0
	exg	a2,a3
	btst	#6,(sflags2).w
	beq.w	.1
	bsr.w	ClearLeadSong
	bclr	#6,(sflags2).w
.1
	bset	#5,(sflags2).w
	bne.w	LeadSongExit
	cmpa.w	#$C6CE,a3
	bne.w	.2
	move.w	(HomeTeam).w,(HmTeam).w
	move.w	#1,(SongIndex).w
	jsr	(ChooseSong).l
.loop
	bset	#6,(sflags8).w
	bra.w	LeadSongExit
.2
	move.w	(HomeTeam).w,(HmTeam).w
	move.w	#4,(SongIndex).w
	jsr	(ChooseSong).l
	bra.s	.loop
ClearLeadSong	;Clear sflags2 bit 5
	bclr	#5,(sflags2).w
	rts
LeadSongExit	;LeadSong exit
	move.w	(sp)+,(sflags2).w
	movem.l	(sp)+,d0/a0-a3
	rts
ClearPenalties	;Clear the penalties: PBnum, Penaltytimer, Pencntdwn, PenBuf and both teams' penalty slots (clrTmPdst). Called from clockcont_0
	movem.l	d0/a0,-(sp)
	clr.w	(PBnum).w
	clr.w	(Penaltytimer).w
	clr.w	(Pencntdwn).w
	move.w	#$10,d0
	movea.l	#PenBuf,a0
.loop
	clr.l	(a0)+
	dbf	d0,.loop
	movea.l	#tmstruct,a0
	bsr.w	clrTmPdst
	movea.l	#AwShots,a0
	bsr.w	clrTmPdst
	movem.l	(sp)+,d0/a0
	rts
clrTmPdst	;(and comments).
	move.w	#$19,d0	;19 = 25 decimal (max roster size)
	adda.w	#$66,a0	;'f'   ; Starting at (C734-home, CA98-away) and decrementing
.loop
	move.w	#$FFFE,(a0)+	;-2 = bench
	dbf	d0,.loop
	move.w	#$FFFF,(a0)	;-1 = ice
	rts
HotColdIcon	;The icon by the name of player iconplayer of team a2 at x iconx, y $19: HotIconMap when he is awayhotplayer /
	;homehotplayer, ColdIconMap when awaycoldplayer / homecoldplayer, else clear it (eraser)
	movem.l	d0/a0-a1,-(sp)
	movea.l	#awayhotplayer,a0
	move.w	#2,(iconx).w
	cmpa.l	#tmstruct,a2
	bne.w	.0
	movea.l	#homehotplayer,a0
	move.w	#$20,(iconx).w
.0
	move.w	#0,d0
.loop
	move.w	(a0)+,d1
	cmp.w	(iconplayer).w,d1
	beq.w	.2
	dbf	d0,.loop
	movea.l	#awaycoldplayer,a0
	cmpa.l	#tmstruct,a2
	bne.w	.1
	movea.l	#homecoldplayer,a0
.1
	move.w	#0,d0
.loop2
	move.w	(a0)+,d1
	cmp.w	(iconplayer).w,d1
	beq.w	.3
	dbf	d0,.loop2
	move.w	(iconx).w,(printx).w
	move.w	#$19,(printy).w
	move.w	#8,d0
	move.w	#3,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	bra.w	.x
.2
	move.w	(hoticonchars).w,d4
	movea.l	#HotIconMap,a0
	bra.w	.4
.3
	move.w	(coldiconchars).w,d4
	movea.l	#ColdIconMap,a0
.4
	move.w	(iconx).w,(printx).w
	move.w	#$19,(printy).w
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	movea.w	#$30A,a2
	clr.w	d0
	clr.w	d1
	move.w	(a1),d2
	move.w	2(a1),d3
	moveq	#0,d5
	jsr	(dobitmap).l
.x
	movem.l	(sp)+,d0/a0-a1
	rts
chgplayer	;(and comments). the pad d4 takes the nearest free skater to where the puck is going (not a goalie, not locked or
	;unavailable; in a penalty shot / shootout only BA_Sktr_SCnum or BA_Goalie_SCnum), or sweep checks when it is the same one. Called from
	;changeplayer
	btst	#6,(sflags5).w	;Check bit 6. This is never set anywhere
	bne.w	exit
	movem.l	d0-d6/a0-a1,-(sp)
	move.w	(puckvx).w,d0	;lead puck slightly
	asr.w	#8,d0
	add.w	(puckx).w,d0
	move.w	(puckvy).w,d1
	asr.w	#8,d1
	add.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	moveq	#5,d2
	move.w	d4,d3
	eori.w	#2,d3	;other controller
	moveq	#-1,d5	;-1
	movea.w	#(SortCords-M68K_RAM),a0	;start of search
	movea.w	#(cont1team-M68K_RAM),a1
	cmpi.w	#1,0(a1,d4.w)
	beq.w	.t1
	adda.w	#$300,a0	;controller is on other team
.t1
	movea.w	#(c1playernum-M68K_RAM),a1
.top
	tst.w	$34(a0)	;position
	ble.w	.next	;cant switch to goalie
	btst	#2,$63(a0)	;#pf2unav
	bne.w	.next	;this player is unavailable for some reason
	movem.w	d1,-(sp)
	move.w	$52(a0),d1	;SCnum
	cmp.w	0(a1,d4.w),d1
	movem.w	(sp)+,d1
	beq.w	.0
	btst	#3,$62(a0)	;is player controlled?
	bne.w	.next	;yes branch
.0
	btst	#2,(BA_PS_flags).w
	beq.w	.1
	movem.l	d0,-(sp)
	move.w	(BA_Sktr_SCnum).w,d0
	cmp.w	$52(a0),d0
	movem.l	(sp)+,d0
	beq.w	.1
	movem.l	d0,-(sp)
	move.w	(BA_Goalie_SCnum).w,d0
	cmp.w	$52(a0),d0
	movem.l	(sp)+,d0
	bne.w	.next
.1
	btst	#5,$62(a0)	;#pfalock
	bne.w	.next	;player is locked
	movem.w	(sp),d0-d1
	sub.w	(a0),d0	;Xpos
	muls.w	d0,d0
	sub.w	$14(a0),d1	;Ypos
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	d5,d0
	bhi.w	.next
	move.w	$52(a0),d1	;Scnum
	cmp.w	0(a1,d3.w),d1
	beq.w	.next	;this is current player
	move.l	d0,d5
	move.w	d1,d6
.next
	adda.w	#$80,a0	;size of SCstruct
	dbf	d2,.top
	addq.w	#4,sp
	pea	(.ex).l
	cmp.w	0(a1,d4.w),d6
	beq.w	swpchk	;player is same so sweep check
	move.w	d6,d0	;d0 now is new player
	tst.w	d4
	beq.w	j_setc1player
	bra.w	j_setc2player
.ex
	movem.l	(sp)+,d0-d6/a0-a1
exit
	rts
swpchk	;Sweepcheck
	jmp	Sweepcheck
j_setc1player	;(a thunk its target's name)
	jmp	setc1player
j_setc2player	;(a thunk its target's name)
	jmp	setc2player
