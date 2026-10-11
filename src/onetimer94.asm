;	NHL 94 (retail) segment
;	94 code in the high ROM, after the graphics: the one-timer (puckvzadj, OneTimerPass / OneTimerTarget pass target, assonetimer,
;	setonetimeranim, onetimershot), the 4 way play adaptor test (Detect4WayPlay), the crowd meter (LoadCrowdRec, Crowd_Noise),
;	stopna2, the 94 corner wall check, the hot / cold tables (Create_HotCold_Table, AttributeCalc) and the
;	hot / cold player lists for the MATCHUPS text (NextHomeHotPlayer ... GetHotColdTotal). New in 94; 93 has no code here.
;Transcribed from lst/nhl94.bin.lst lines 958869-960186. Names and most comments are the (this is
;commented); names and the are named for what the
;code does. written from the retail bytes: unused code as dc.b (Read4WayPad1
;Locals
;are named for what they do (the locals keep their name), with the unless generic, in an

puckvzadj	;set puckvz for a top shelf shot from the distance to the goal line ($108) over puckvy, at most $7FFF. Called from doshot
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(pucky).w,d0	;move pucky into d0
	bpl.w	.dist	;branch if positive
	neg.w	d0	;negate d0
.dist
	subi.w	#$108,d0
	;sub top goal line from d0
	bpl.w	.0	;branch if positive
	neg.w	d0	;negate d0
.0
	swap	d0	;swap d0 words
	andi.l	#$FFFF0000,d0	;pass upper word of d0
	move.w	(puckvy).w,d1	;move puckvy into d1
	beq.w	.x	;branch if zero
	bpl.w	.speed	;branch if positive
	neg.w	d1	;negate d1
.speed
	move.w	#$11,d2	;move 11 into d2
	tst.w	(music_global_tick_counter).w	;This byte is never set
	beq.w	.div	;branch if equal (always is)
	move.w	#$16,d2	;move 16 into d2
.div
	divu.w	d1,d0	;divide d1 into d0
	andi.l	#$FFFF,d0	;pass lower word of d0
	divu.w	d2,d0	;divide d2 into d0
	tst.w	d0	;check d0
	bne.w	.calc	;branch if not zero
	move.w	#1,d0	;move 1 into d0
.calc
	move.l	#$A0000,d1
	move.w	d0,d3	;move d0 into d3
	mulu.w	d2,d0	;mult d2 and d0
	divu.w	d0,d1	;divide d0 into d1
	move.w	d2,d4	;move d2 into d4
	add.w	d2,d2	;double d2
	add.w	d4,d2	;add d4 to d2 (now d2 is d2 x 3)
	mulu.w	d3,d2	;multiply d3 and d2
	cmp.l	#$7FFF,d2	;compare to d2
	blt.w	.addvz	;branch if less than
	move.w	#$7FFF,d2	;move 7FFF into d2
.addvz
	add.w	d2,d1	;add d2 to d1
	tst.w	d1	;test d1
	bpl.w	.setvz	;branch if positive
	move.w	#$7FFF,d1	;move 7FFF into d1
.setvz
	move.w	d1,(puckvz).w	;move d1 into puckvz
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
OneTimerPass	;One-timer pass: puckvz = sqrt(12 * onetimerheight), then puckvx / puckvy toward the target onetimertargetx / onetimertargety in puckvz
	;/ 3 frames; flip the puck (puckflip, a3 = the puck at puckx). Called from passmode
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#$C,d0
	move.w	(onetimerheight).w,d1
	mulu.w	d1,d0
	swap	d0
	andi.l	#$FFFF0000,d0
	jsr	(sroot).l
	move.w	d0,(puckvz).w
	ext.l	d0
	move.w	#3,d4
	divu.w	d4,d0
	clr.l	d1
	move.w	(onetimertargetx).w,d1
	sub.w	(puckx).w,d1
	swap	d1
	tst.w	d0
	bne.w	.setv
	move.w	#1,d0
.setv
	divs.w	d0,d1
	move.w	d1,(puckvx).w
	clr.l	d1
	move.w	(onetimertargety).w,d1
	sub.w	(pucky).w,d1
	swap	d1
	divs.w	d0,d1
	move.w	d1,(puckvy).w
	movea.l	#puckx,a3
	move.w	(puckvz).w,d0
	jsr	(puckflip).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
OneTimerTarget	;One-timer pass target for receiver a3: an offset by facing from OneTimerNearTbl / OneTimerFarTbl (skater, near or far from the goal)
	;or OneTimerGoalieTbl (goalie), +-10 at random, into onetimertargetx / onetimertargety; sflags6 bit 2 = near. Called from passmode
	movem.l	d0-d7/a0-a6,-(sp)
	bclr	#2,(sflags6).w
	tst.w	position(a3)
	bne.w	.skater
	movea.l	#OneTimerGoalieTbl,a0
	bra.w	.facing
.skater
	move.w	Ypos(a3),d0
	btst	#7,pflags(a3)
	bne.w	.near
	neg.w	d0
.near
	bset	#2,(sflags6).w
	movea.l	#OneTimerNearTbl,a0
	cmp.w	#$58,d0
	blt.w	.facing
	movea.l	#OneTimerFarTbl,a0
	bclr	#2,(sflags6).w
.facing
	move.w	facedir(a3),d0
	btst	#7,pflags(a3)
	bne.w	.offset
	addq.w	#4,d0
	andi.w	#7,d0
.offset
	asl.w	#2,d0
	move.w	0(a0,d0.w),d1
	move.w	2(a0,d0.w),d2
	cmpa.l	#OneTimerFarTbl,a0
	bne.w	.side
	move.w	Ypos(a3),d0
	bpl.w	.chky
	neg.w	d0
.chky
	cmp.w	#$8A,d0
	blt.w	.side
	move.w	(a3),d0
	bpl.w	.chkx
	neg.w	d0
.chkx
	cmp.w	#$37,d0
	bgt.w	.side
	move.w	#$103,d2
.side
	btst	#7,pflags(a3)
	bne.w	.rand
	neg.w	d1
	neg.w	d2
.rand
	move.w	#$A,d0
	jsr	(randomd0).l
	add.w	d0,d1
	move.w	#$A,d0
	jsr	(randomd0).l
	add.w	d0,d2
	move.w	d1,(onetimertargetx).w
	tst.w	position(a3)
	beq.w	.sety
	sub.w	(a3),d1
	bmi.w	.left
	subi.w	#$3C,d1
	bpl.w	.sety
	neg.w	d1
	add.w	d1,(onetimertargetx).w
	bra.w	.sety
.left
	addi.w	#$3C,d1
	bmi.w	.sety
	sub.w	d1,(onetimertargetx).w
.sety
	move.w	d2,(onetimertargety).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
OneTimerNearTbl	;OneTimerTarget target offsets (x, y) by facing, receiver near the goal
	dc.w	$74,$C2,$74,$C2,$74,$C2,$74,$C2
	dc.w	$FF8C,$C2,$FF8C,$C2,$FF8C,$C2,$FF8C,$C2
OneTimerFarTbl	;OneTimerTarget target offsets (x, y) by facing, receiver far from the goal
	dc.w	$FFFB,$AB,$FFFB,$AB,$FFFB,$AB,$FFFB,$AB
	dc.w	$FFFB,$AB,$FFFB,$AB,$FFFB,$AB,$FFFB,$AB
OneTimerGoalieTbl	;OneTimerTarget target offsets (x, y) by facing, goalie
	dc.w	$FFFB,$FFF7,$32,$FFF7,$32,$FFF7,$32,$FFF7
	dc.w	$FFFB,$FFF7,$FFCE,$FFF7,$FFCE,$FFF7,$FFCE,$FFF7
assonetimer	;(and comments). assignment $23 (asstab), player a3 shooting a one-timer: take control of him
	;(setc1player / setc2player, also for pads 3 and 4), start the animation (setonetimeranim), then shoot when the puck arrives (EndOneTimer)
	bclr	#1,pflags(a3)	;pfna - clear new assignment
	beq.w	.checkxpos	;branch if not new assignment
	bset	#pf3onetimer,pflags3(a3)	;set one timer bit
	bne.w	.checkxpos	;branch if already set
	bclr	#0,(onetimerflags).w
	bclr	#5,(sflags8).w
	clr.w	(onetimerflags).w
	clr.w	(onetimerclock).w
	st	(passplayer).w
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	SCnum(a3),d0	;move a3 SCnum into d0
	move.w	d0,(onetimerplayer).w	;move d0
	btst	#3,pflags(a3)	;check if joystick controlled
	bne.w	.setanim	;branch if so
	tst.w	(inputjoy).w	;check input controller
	bmi.w	.setanim	;branch if minus (no control)
	beq.w	.cont1or3	;branch if controller 1 or 3
	cmpi.w	#1,(TmpJoyPuckCarrier).w	;compare if puck carrier is player 4
	bne.w	.setplayer2	;branch if not
	move.w	(cont2team).w,-(sp)
	move.w	(c2playernum).w,-(sp)
	move.w	(cont4team).w,(cont2team).w
	move.w	(c4playernum).w,(c2playernum).w
	jsr	(setc2player).l
	move.w	(c2playernum).w,(c4playernum).w
	move.w	(cont2team).w,(cont4team).w
	move.w	(sp)+,(c2playernum).w
	move.w	(sp)+,(cont2team).w
	bra.w	.setanim
.setplayer2
	jsr	(setc2player).l
	bra.w	.setanim
.cont1or3
	tst.w	(TmpJoyPuckCarrier).w	;check if puck carrier is player 3
	bne.w	.setplayer1	;branch if not
	move.w	(cont1team).w,-(sp)
	move.w	(c1playernum).w,-(sp)
	move.w	(cont3team).w,(cont1team).w
	move.w	(c3playernum).w,(c1playernum).w
	jsr	(setc1player).l
	move.w	(c1playernum).w,(c3playernum).w
	move.w	(cont1team).w,(cont3team).w
	move.w	(sp)+,(c1playernum).w
	move.w	(sp)+,(cont1team).w
	bra.w	.setanim
.setplayer1
	jsr	(setc1player).l
	bra.w	.setanim	;*+4
.setanim
	move.w	d0,-(sp)
	bsr.w	setonetimeranim	;sets the one timer animation
	clr.w	SPAnum(a3)	;clear SPAnum
	jsr	(SetSPA).l
	bset	#5,pflags(a3)	;lock animation
	bset	#1,pflags2(a3)	;set anim in progress
	move.w	(sp)+,d0
	movem.l	(sp)+,d0-d7/a0-a6
	bra.w	.ex
.checkxpos
	btst	#0,(onetimerflags).w	;check if shot initiated
	bne.w	.chkcarrier	;branch if set
	movem.w	d0-d1,-(sp)	;push to stack
	move.w	(puckx).w,d0	;move puckx to d0
	sub.w	(a3),d0	;sub Xpos from d0
	cmp.w	#$3C,d0	;'<'   ; compare diff to 3C (60 pixels)
	bgt.w	.chkxvel	;branch if greater than
	cmp.w	#$FFC4,d0	;compare to -60 pixels
	bgt.w	.chkypos	;branch if greater than
.chkxvel
	move.w	(puckvx).w,d1	;move puckvx into d1
	eor.w	d1,d0	;EOR d1 with d0
	bmi.w	.chkypos	;branch if minus
.notcoming
	movem.w	(sp)+,d0-d1	;pop from stack d0 and d1
	bra.w	.cancel
.chkypos
	move.w	(pucky).w,d0	;move pucky into d0
	sub.w	Ypos(a3),d0	;sub Ypos from d0
	cmp.w	#$3C,d0	;'<'   ; compare diff to 60 pix
	bgt.w	.chkyvel	;branch if greater than
	cmp.w	#$FFC4,d0	;check with -60 pix
	bgt.w	.coming	;branch if greater than
.chkyvel
	move.w	(puckvy).w,d1	;move puckvy into d0
	eor.w	d1,d0	;EOR d1 with d0
	bpl.s	.notcoming	;branch if positive
.coming
	movem.w	(sp)+,d0-d1	;pop d0 and d1 from stack
.chkcarrier
	tst.w	(puckc).w	;check if puck carrier
	bmi.w	.loose	;branch if no puck carrier
.cancel
	bclr	#7,(sflags8).w	;clear bit 7
	bra.w	.shoot
.loose
	btst	#0,(gmode).w	;check if game clock
	bne.w	.shoot	;branch if clock stopped
	movem.l	d0-d1,-(sp)	;push to stack
	cmpi.w	#$10,SPAnum(a3)	;compare 10 to SPAnum
	bge.w	.windup	;branch if greater than or equal
	btst	#2,(onetimerflags).w	;check bit 2
	bne.w	.windup	;branch if set
	move.w	(a3),d0	;move Xpos into d0
	move.w	(puckx).w,d1	;move puckx into d1
	sub.w	d1,d0	;sub d1 from d0
	bpl.w	.dy	;branch if positive
	neg.w	d0	;negate d0
.dy
	move.w	Ypos(a3),d1	;move Ypos into d1
	move.w	(pucky).w,d2	;move pucky into d2
	sub.w	d2,d1	;sub d2 from d1
	bpl.w	.vel	;branch if positive
	neg.w	d1	;negate d1
.vel
	move.w	(puckvx).w,d2	;move puckvx into d2
	beq.w	.usey	;branch if d2 is 0
	cmp.w	d0,d1	;compare d0 to d1
	ble.w	.frames	;branch if less than or equal
.usey
	move.w	(puckvy).w,d2
	move.w	d1,d0
.frames
	swap	d0
	andi.l	#$FFFF0000,d0
	tst.w	d2
	bpl.w	.speed
	neg.w	d2
.speed
	move.w	#$11,d1
	tst.w	(music_global_tick_counter).w
	beq.w	.chkzero
	move.w	#$16,d1
.chkzero
	tst.w	d2
	bne.w	.div
	move.w	#1,d2
.div
	divu.w	d2,d0
	andi.l	#$FFFF,d0
	divu.w	d1,d0
	move.w	SPAnum(a3),d2
	lsr.w	#2,d2
	subq.w	#6,d2
	neg.w	d2
	asl.w	#2,d2
	cmp.w	d2,d0
	bgt.w	.wait
	neg.w	SPAnum(a3)
	addi.w	#$18,SPAnum(a3)
	bra.w	.chkanim
.wait
	add.w	d7,(onetimerclock).w
	bra.w	.chkhold
.windup
	bset	#2,(onetimerflags).w
	btst	#1,(onetimerflags).w
	bne.w	.chkhold
	cmpi.w	#$18,SPAnum(a3)
	bne.w	.chkhold
	addi.w	#$30,SPAcnt(a3)
	bset	#1,(onetimerflags).w
.chkhold
	btst	#1,(onetimerflags).w
	beq.w	.chkshot
	cmpi.w	#$18,SPAnum(a3)
	ble.w	.chkshot
	btst	#0,(onetimerflags).w
	bne.w	.chkshot
	movem.l	(sp)+,d0-d1
	bra.w	.shoot
.chkshot
	btst	#0,(onetimerflags).w
	beq.w	.chkanim
	cmpi.w	#$18,SPAnum(a3)
	bne.w	.chkanim
	cmpi.w	#1,SPAcnt(a3)
	ble.w	.chkanim
	move.w	#1,SPAcnt(a3)
.chkanim
	btst	#1,pflags2(a3)
	bne.w	.animon
	movem.l	(sp)+,d0-d1
	bra.w	.chkdone
.animon
	move.w	SPAnum(a3),d0
	movem.l	(sp)+,d0-d1
	btst	#0,(onetimerflags).w
	beq.w	.nop
	bclr	#5,pflags(a3)
	bra.w	.chkdone
.nop
	nop
.chkdone
	btst	#1,pflags2(a3)
	bne.w	.ex
.shoot
	jsr	(EndOneTimer).l
.ex
	rts
setonetimeranim	;the one-timer animation: d1 = $7FC or $92E from the angle to the goal (vtoa, CheckOneTimerFacing)
	move.w	#$7FC,d1
	movem.w	d0-d1,-(sp)	;push to stack d0 and d1
	move.w	(a3),d0	;move XPos of a3 into d0
	neg.w	d0	;negate d0
	move.w	#$108,d1	;move top goal line into d1
	btst	#7,pflags(a3)	;check which goal shooting at
	bne.w	.top	;branch if top
	neg.w	d1	;negate d1
.top
	sub.w	Ypos(a3),d1	;sub Ypos from d1
	jsr	(vtoa).l
	jsr	(CheckOneTimerFacing).l	;code doesnt save any changes
	movem.w	(sp)+,d0-d1	;pop from stack d0 and d1
	beq.w	.ex
	move.w	#$92E,d1
.ex
	rts
PuckOnAttackHalf	;d0 = 1 when the puck is on the half of the goal player a3 shoots at, else 0 (the code after the bra is never used). Called from doinput and
	movem.w	d0-d1,-(sp)
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)	;pfgoal - check which goal shooting at
	bne.w	.cont	;branch if top goal
	neg.w	d0
.cont
	tst.w	d0	;check if d0 is 0
	bpl.w	.plus	;branch if higher
	bra.w	.0
	move.w	(passdir).w,d0	;code never used from here up to _0
	addq.w	#4,d0
	andi.w	#7,d0
	move.w	facedir(a3),d1
	cmp.w	d0,d1
	bra.w	.plus
	beq.w	.plus
	addq.w	#1,d1
	andi.w	#7,d1
	cmp.w	d0,d1
	beq.w	.plus
	addq.w	#1,d1
	andi.w	#7,d1
	cmp.w	d0,d1
	beq.w	.plus
	subq.w	#3,d1
	andi.w	#7,d1
	cmp.w	d0,d1
	beq.w	.plus
	subq.w	#1,d1
	andi.w	#7,d1
	beq.w	.plus
.0
	move.w	#0,d0
	bra.w	.ex
.plus
	move.w	#1,d0
.ex
	movem.w	(sp)+,d0-d1
	rts
onetimershot	;(and comments). do the one-timer shot (doshot), credit the last two passers as the assists, add to crowdlevel /
	;CwdExciteLvl and to the one-timer attempts ($35C of the team struct). Called from puckstick
	move.w	#4,(passdir).w
	jsr	(doshot).l
	movem.l	d0/a0,-(sp)
	movea.l	#tmstruct,a0	;Home Stats
	btst	#6,pflags(a3)	;check if home or away
	beq.w	.home	;branch if home
	lea	$364(a0),a0	;add if away
.home
	clr.w	d0
	move.b	pnum(a3),d0	;player offset in roster
	move.w	$1A(a0),$1C(a0)	;move assist 1 player to assist 2
	move.w	$18(a0),$1A(a0)	;move last player to touch puck to assist 1
	move.w	d0,$18(a0)	;move d0 into player touching puck
	bset	#7,(sflags8).w	;set bit 7
	addi.w	#$96,(crowdlevel).w	;add to crowdlevel
	addi.w	#$A,(CwdExciteLvl).w	;add to Excite Level
	addq.w	#1,$35C(a0)	;add to one timer attempt
	movem.l	(sp)+,d0/a0
	bset	#0,(onetimerflags).w	;set bit 0
	bset	#1,pflags2(a3)	;set animation in progress
	bset	#1,(sflags6).w	;set bit 1
	rts
CheckOneTimerFacing	;called from setonetimeranim. it does nothing, d0 and d1 are restored at the end; it seems meant to
	;change the way the one-timer player faces
	movem.w	d0-d1,-(sp)	;push d0 and d1 on stack
	neg.w	d0	;negate d0
	addq.w	#8,d0	;add 8 to d0
	andi.w	#7,d0	;pass first 3 bits of d0
	move.w	facedir(a3),d1	;move facedir into d1
	add.w	d0,d1	;add d0 to d1
	andi.w	#7,d1	;pass first 3 bits of d1
	cmp.w	#4,d1	;compare to 4
	bgt.w	.g0	;branch if greater than
	move.w	4(a3),d0	;move attribute into d0
	eori.w	#$FFFF,d0	;EOR FFFF with d0. Makes d0 opposite.
	andi.w	#$800,d0	;pass 12th bit of d0
	bra.w	.ex
.g0
	move.w	4(a3),d0	;move attribute into d0
	andi.w	#$800,d0	;pass 12th bit of d0
.ex
	movem.w	(sp)+,d0-d1	;pop from stack
	rts
