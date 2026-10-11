;	checkcoll, checkplcoll, checkcx, newcheck, checkint, checkcheck and
;	CCStart, checkinglist, checkagr, holdcheck, Bcheck, FallDown and
;	setInjuryType.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	Sort struct (SortCords, $80 each): 0 Xpos, 4 attribute, $14 Ypos, $1C OldXpos, $20 OldYpos, $28 Xvel, $2A Yvel,
;	$2E impactp, $32 impact, $34 position, $40 temp1, $4A / $4C wall radius x / y, $4E wallcos, $50 wallsin, $52 SCnum,
;	$54 facedir, $58 SPA, $5E / $5F nopuck, $62 pflags, $63 pflags2, $64 bit 1 breakaway, bit 3 one-timer, bit 4 wall
;	collision, bit 5 fell, $66 pnum, $67 weight, $68 Agl, $71 Stk, $73 aggres, $74 Fgt, $75 Chk.

checkcoll	;d2 = new x coord, d3 = new y coord, a3 = struct of object. Check wall collision (around the hot spot and the end of the stick) and
	;player collisions, then move a3 in the OOlist sort order by its y. If a player collision set collflag, restore the old x/y instead. Called
	;from updateplayers
	clr.w	(collflag).w
	btst	#sfhor,(sflags).w	;check if in horiz mode
	beq.w	.nhor1	;branch if not horizontal
	exg	d2,d3
.nhor1
	btst	#pfnc,pflags(a3)	;check if in no collision mode
	bne.w	.ex	;branch if no collision
	movem.l	d0-d7,-(sp)
	move.w	(a3),d2	;Xpos
	move.w	Ypos(a3),d3	;Ypos - check coll around hot spot with wall
	move.w	radiusx(a3),(wcradiusx).w	;wall coll radius X
	move.w	radiusy(a3),(wcradiusy).w	;wall coll radius Y
	bsr.w	checkwallcoll
	move.w	Wallcos(a3),d0	;wallcos
	or.w	Wallsin(a3),d0	;wallsin
	bne.w	.xx	;coll didnt happen
	cmpi.w	#$B,SCnum(a3)	;check if a3 is a player
	bgt.w	.xx	;branch if not a player
	movem.l	(sp),d0-d7
	move.l	a3,-(sp)
	bsr.w	GetHot
	move.w	(a3),d2	;Xpos
	move.w	Ypos(a3),d3	;Ypos
	add.w	d0,d2
	add.w	d1,d3	;check coll around end of stick with wall
	move.w	#1,(wcradiusx).w
	move.w	#1,(wcradiusy).w
	bsr.w	checkwallcoll
.xx
	movem.l	(sp)+,d0-d7
	bsr.w	checkplcoll	;check coll with other players
.ex
	tst.w	(collflag).w	;now check order of sprites
	bne.w	.restoreold
	move.w	SCnum(a3),d0	;SCnum
	asl.w	#1,d0	;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	0(a0,d0.w),d1	;current objects pos in OOlist
.2
	cmp.w	#$F,d1	;Sortobjs-1
	beq.w	.cl2	;is it top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4	;next higher object number
	cmp.w	0(a2,d4.w),d3	;YPos of next higher object
	ble.w	.cl2
	addq.w	#1,0(a0,d0.w)
	subq.w	#1,0(a0,d4.w)
	move.b	d4,0(a1,d1.w)
	move.b	d0,1(a1,d1.w)
	addq.w	#1,d1
	bra.s	.2
.cl2
	move.w	0(a0,d0.w),d1	;current objects pos in OOlist
	beq.w	.ex2
.3
	clr.w	d4
	move.b	-1(a1,d1.w),d4	;next lower object number
	cmp.w	0(a2,d4.w),d3	;compare to Y pos of next lower object
	bge.w	.ex2
	subq.w	#1,0(a0,d0.w)
	addq.w	#1,0(a0,d4.w)
	move.b	d4,0(a1,d1.w)
	move.b	d0,-1(a1,d1.w)
	subq.w	#1,d1
	bne.s	.3
.ex2
	move.w	d3,0(a2,d0.w)	;update Ylist
	rts
.restoreold
	move.w	OldXpos(a3),(a3)	;move OldXpos into Xpos
	move.w	OldYpos(a3),Ypos(a3)	;move OldYpos into Ypos
	rts
checkplcoll	;check collision with other players. d2/d3 = x/y cords, a3 = struct. Walk up and down the OOlist from a3 and call checkcx for each
	;object within $10 in y. Called from checkcoll
	btst	#5,pflags2(a3)	;pflags2 bit 5 (line change mode)
	bne.w	.ex
	cmpi.w	#$B,SCnum(a3)	;#11, SCnum
	bgt.w	.ex
	move.w	SCnum(a3),d0	;SCnum
	asl.w	#1,d0	;current object number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	0(a0,d0.w),d1	;current objects pos in OOlist
.0
	cmp.w	#$F,d1	;#sortobjs-1
	beq.w	.cl	;it is top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4	;next higher object number
	move.w	0(a2,d4.w),d5	;y pos of next higher object
	sub.w	d3,d5
	cmp.w	#$10,d5	;#collrad*2
	bgt.w	.cl	;no higher sprite coll
	bsr.w	checkcx
	addq.w	#1,d1
	bra.s	.0
.cl
	move.w	0(a0,d0.w),d1
	beq.w	.ex
.1
	clr.w	d4
	move.b	-1(a1,d1.w),d4	;next lower object number
	move.w	d3,d5
	sub.w	0(a2,d4.w),d5	;y pos of next lower object
	cmp.w	#$10,d5	;#collrad*2
	bgt.w	.ex
	bsr.w	checkcx
	subq.w	#1,d1
	bne.s	.1
.ex
	rts
checkcx	;d4 = obj. # * 2 for possible collision so check x range and distance for collision. d2 = x, d5 = delta y, a3 = moving object. Opposing
	;players add impact and run newcheck, checkint, checkcheck and checkfight (94: an rts); then momentum moves from a3 to a2. Called from
	;checkplcoll
	movem.l	d0-d7/a0-a3,-(sp)
	asl.w	#6,d4	;6 = scsize-1
	movea.l	#SortCords,a2	;B04A = Start of player structs (SortCords)
	adda.w	d4,a2	;add d4 to a2. a2 now address of SCStruct-1
	btst	#pfnc,pflags(a2)	;test pfnc pflags = no collision mode
	bne.w	.exit	;object has no collision mode on
	btst	#5,pflags2(a2)	;pf2npc(pflags2) = another no collision mode
	bne.w	.exit	;exit if no collision mode on
	cmpi.w	#$B,SCnum(a2)	;comparing 11 with SCnum for player. Player SCnum are 0-11.
	bgt.w	.exit	;not a player
	move.w	(a2),d0	;Xpos
	btst	#sfhor,(sflags).w	;sfhor(sflags) = screen in horizontal mode
	beq.w	.nhor	;branch if not in horiz mode
	move.w	Ypos(a2),d0	;Ypos
.nhor
	sub.w	d2,d0	;subtract d2 from d0
	cmp.w	#$FFF0,d0	;compare delta Xpos to -collrad*2
	blt.w	.exit	;branch if less than
	cmp.w	#$10,d0	;compare delta Xpos to collrad*2
	bgt.w	.exit	;branch if greater than
	muls.w	d5,d5	;delta y^2
	muls.w	d0,d0	;delta x^2
	add.l	d5,d0
	cmp.l	#$100,d0	;compare d0 to (collrad*2)*(collrad*2)
	bgt.w	.exit	;branch if outside of radius
	move.w	#0,(evalue).w	;evalue = elasticity value
	move.b	pflags(a3),d6	;move pflags into d6
	move.b	pflags(a2),d0	;move pflags into d0
	eor.b	d0,d6	;xor d0 with d6
	move.w	Xvel(a3),d0	;Now do momentum transfer from object a3 to object a2
	;Xvel
	sub.w	Xvel(a2),d0	;subtract Xvel a2 from Xvel a3 (Vx)
	move.w	Yvel(a3),d1	;Yvel
	sub.w	Yvel(a2),d1	;subtract Yvel a2 from Yvel a3 (Vy)
	move.w	(a3),d2	;Xpos
	sub.w	(a2),d2	;subtract Xpos of a2 from Xpos of a3
	neg.w	d2	;Dx
	move.w	Ypos(a3),d3	;Ypos
	sub.w	Ypos(a2),d3	;subtract Ypos of a2 from Ypos of a3
	neg.w	d3	;Dy
	movem.w	d0-d1,-(sp)
	muls.w	d3,d1	;Vy*Dy
	muls.w	d2,d0	;Vx*Dx
	add.l	d0,d1	;(Vy*Dy)+(Vx*Dx)
	bmi.w	.exit4	;no collision if v1n < 0
	asr.l	#4,d1	;divide by 8
	btst	#pfteam,d6	;pfteam(d6)
	beq.w	.not	;players are on same team
	move.w	d1,d4
	lsr.w	#8,d4	;divide by 128
	cmp.w	#5,d4
	bgt.w	.g40
	moveq	#5,d4	;minimum impact value
.g40
	add.w	d4,impact(a3)	;$32 = impact value
	add.w	d4,impact(a2)
	btst	#pf2fight,pflags2(a2)	;pf2fight(pflags2)
	bne.w	.if
	move.w	SCnum(a3),impactp(a2)	;SCnum(a3), impactp(a2) = moves a3 SCnum into past impact player for a2
.if
	btst	#pf2fight,pflags2(a3)	;pf2fight(pflags2)
	bne.w	.if2
	move.w	SCnum(a2),impactp(a3)	;SCnum(a2), impactp(a3) = moves a2 SCnum into past impact player for a3
.if2
	cmp.w	#$14,d4
	blt.w	.n1
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0	;SCnum
	beq.w	.nc
	cmp.w	SCnum(a2),d0	;SCNum
	bne.w	.n1
.nc
	bsr.w	newcheck
.n1
	bsr.w	checkint
	bsr.w	checkcheck
	bsr.w	checkfight	;an rts
.not
	move.w	d1,d4	;d1 = V1n
	movem.w	(sp)+,d0-d1
	tst.w	(collflag).w
	bmi.w	.exit
	muls.w	d2,d1	;Vy*Dx
	muls.w	d3,d0	;Vx*Dy
	sub.l	d1,d0	;(Vx*Dy)-(Vy*Dx)
	asr.l	#4,d0
	move.w	d0,d5	;V1t
	clr.w	d0
	move.b	weight(a3),d0	;wgt, m1 in calc below
	addi.w	#$8C,d0
	clr.w	d1
	move.b	weight(a2),d1	;wgt, m2 in calc below
	addi.w	#$8C,d1
	move.w	(evalue).w,d7	;e*16 value (0-16)
	mulu.w	d1,d7
	lsr.w	#4,d7	;m2*e
	add.w	d0,d1	;m1+m2
	sub.w	d7,d0	;(m1-m2*e)
	muls.w	d4,d0	;V1n*(m1-m2*e)
	divs.w	d1,d0	;V1n'=(V1n*(m1-m2*e))/(m1+m2)
	move.w	(evalue).w,d1
	muls.w	d4,d1	;V1n*e
	asr.w	#4,d1
	add.w	d0,d1	;V2n'=V1n'+V1n*e
	movem.w	d2-d3,-(sp)	;Save Dx,Dy
	muls.w	d5,d3	;V1t'*Dy
	muls.w	d0,d2	;V1n'*Dx
	add.l	d2,d3	;V1t'*Dy+V1n'*Dx
	asr.l	#4,d3
	add.w	Xvel(a2),d3	;Xvel
	move.w	d3,Xvel(a3)
	movem.w	(sp),d2-d3	;Restore Dx,Dy
	muls.w	d5,d2	;V1t'*Dx
	muls.w	d0,d3	;V1n'*Dy
	sub.l	d2,d3	;V1n'*Dy-V1t'*Dx
	asr.l	#4,d3
	add.w	Yvel(a2),d3	;Yvel
	move.w	d3,Yvel(a3)
	movem.w	(sp)+,d2-d3	;Pop d2 and d3 off stack
	muls.w	d1,d2	;V2n'*Dx
	asr.l	#4,d2
	add.w	d2,Xvel(a2)	;Xvel
	muls.w	d1,d3	;V2n'*Dy
	asr.l	#4,d3
	add.w	d3,Yvel(a2)	;Yvel
	st	(collflag).w
.exit
	movem.l	(sp)+,d0-d7/a0-a3
	rts
.exit4
	addq.w	#4,sp
	bra.s	.exit
newcheck	;start a new check sound: one of 4 sounds $1C-$1F, never the last one again. Called from checkcx; FallDown branches here when the player who fell did not have the puck
	move.l	d0,-(sp)
	moveq	#3,d0
	bsr.w	randomd0
	addq.w	#1,d0	;1-3 sounds on from the last one
	add.w	(ltack).w,d0	;last tackle sound
	andi.w	#3,d0
	move.w	d0,(ltack).w
	addi.w	#$1C,d0	;first check sound (92 used 18)
	move.w	d0,-(sp)
	bsr.w	sfx
	move.l	(sp)+,d0
	rts
checkint	;check for interference penalty. player a2 interferes with a3 or vice-versa; goalie is only player who can cause an interference call. Called from checkcx
	move.l	d0,-(sp)
	bsr.w	.ci
	exg	a2,a3
	bsr.w	.ci
	exg	a2,a3
	move.l	(sp)+,d0
	rts
.ci	;a2 = goalie, a3 = player interfering with goalie. a3 falls. The interference penalty ($22) needs a3
	;in the crease area (y $EF-$10A toward a2's goal, x within $14), a CPU player or a pad player's joystick player, and randomd0($28 - aggres) <=
	;4 (($14 - byte $73) <= 2)
	tst.w	$34(a2)	;test for goalie
	bne.w	rtss2	;exits if not goalie
	btst	#0,(gmode).w	;test gmclock(gmode). Is there play
	bne.w	rtss2	;no fall downs during celebration
	move.w	(puckc).w,d0	;Puck carrier's SCnum
	cmp.w	SCnum(a3),d0	;SCnum of this struct
	beq.w	.minimpact	;jump if a3 carrying puck
	cmpi.w	#$19,impact(a3)	;compare $19 to impact
	ble.w	rtss2	;exit if less than or equal
.minimpact
	cmpi.w	#2,impact(a3)	;compare 2 to impact
	ble.w	rtss2	;exit if impact is less than 2
	exg	a2,a3
	bsr.w	FallDown
	exg	a2,a3
	cmpi.w	#$1E,impact(a2)	;compare 30 decimal to impact
	ble.w	rtss2	;exit if impact is less than 30 decimal
	btst	#4,pflags2(a3)	;pf2pen(pflags2) - Check if player already committed a penalty
	bne.w	rtss2	;exit if player is already penalized
	tst.w	$34(a2)	;test if goalie
	bne.w	rtss2	;double check to make sure player is goalie
	move.w	#1,d0	;set d0 to team1 value
	btst	#6,pflags(a3)	;check if home or away
	beq.w	.control	;jump if home (team1)
	move.w	#2,d0	;set d0 to team2 value
.control
	cmp.w	(cont1team).w,d0	;cont1team: 0= none, 1=team1, 2=team2
	beq.w	.playercont	;branch if on player 1's team
	cmp.w	(cont2team).w,d0	;check if on player 2's team
	bne.w	.checky	;branch if controlled by CPU
.playercont
	btst	#3,pflags(a3)	;pfjoycon - check if player controlled
	beq.w	rtss2	;exit if not player controlled
.checky
	move.w	Ypos(a2),d0	;Ypos
	btst	#7,pflags(a2)	;pfgoal - 0 shooting bottom, 1 shooting top
	beq.w	.checkcrease
	neg.w	d0	;negative d0 if shooting bottom
.checkcrease
	cmp.w	#$EF,d0	;compare to Ypos. Looks like it compares to both ends of crease
	blt.w	rtss2
	cmp.w	#$10A,d0
	bgt.w	rtss2
	move.w	(a2),d0	;Xpos
	cmp.w	#$14,d0	;compare Xpos to goalpost
	bgt.w	rtss2
	cmp.w	#$FFEC,d0	;compare Xpos to goalpost
	blt.w	rtss2
	move.w	#$28,d0
	sub.b	aggress(a3),d0	;aggres
	bsr.w	randomd0
	cmp.w	#4,d0	;d0 = RNG(28-aggres)
	bhi.w	rtss2
	btst	#4,(gmode).w	;Check if highlight, exit if so
	bne.w	rtss2
	move.l	#$22,d0	;Interference Penalty
	bra.w	AddPenalty
checkcheck	;player is in contact: look for various contact events. Runs CCStart for a3 on a2, then for a2 on a3. d4 = impact. Called from checkcx
	movem.l	d0-d4/a0-a3,-(sp)
	bsr.w	CCStart
	exg	a2,a3
	bsr.w	CCStart
	movem.l	(sp)+,d0-d4/a0-a3
	rts
CCStart	;Player a3 is checking player a2. Holds (SPAHold, SPAhook) go to holdcheck, SPAsweepchk to Bcheck; otherwise
	;only a3 in SPAburst checks. Sets a3's check anim from checkinglist; a big enough hit on a skater makes a2 fall, with a charging ($16 / $18)
	;or roughing ($1A / $1C) roll from checkagr. 94: the hit uses wallcollduringcheck and half the Chk rating, and each penalty goes through
	;PenShotChk
	cmpi.w	#$C90,SPA(a2)	;SPAHold
	beq.w	holdcheck
	cmpi.w	#$1122,SPA(a2)	;SPAhook
	beq.w	holdcheck
	cmpi.w	#$B24,SPA(a2)	;SPAsweepchk. B check animation
	beq.w	Bcheck
	cmpi.w	#$C5E,SPA(a3)	;SPAburst
	bne.w	rtss2
	btst	#0,(gmode).w	;gmclock: increased fight chance after clock stops
	beq.w	.nofight
	move.w	#$100,impact(a3)	;impact
	move.w	#$100,impact(a2)
.nofight
	move.w	(a2),d0	;sprite to use during checking. Xpos a2
	sub.w	(a3),d0	;Xpos a3
	move.w	Ypos(a2),d1	;Ypos a2
	sub.w	Ypos(a3),d1	;Ypos a3
	bsr.w	vtoa
	sub.w	facedir(a3),d0	;facedir a3
	andi.w	#7,d0
	btst	#3,4(a3)	;check attribute xflip?
	beq.w	.0
	neg.w	d0
	addq.w	#8,d0
	andi.w	#7,d0
.0
	asl.w	#1,d0	;Sets the sprite animation
	lea	checkinglist(pc),a0	;loads address of check list into a0
	move.w	0(a0,d0.w),d1	;moves check anim. value into d1, based on d0 offset
	bset	#5,pflags(a3)	;pfalock - lock until animation done
	bsr.w	SetSPA
	tst.w	$34(a2)	;check if a2 is goalie
	beq.w	rtss2
	cmp.w	#$14,d4	;d4 = impact value
	blt.w	rtss2
	moveq	#$78,d0	;uses 60 decimal, this is 120 decimal (most likely due to change in attribute math)
	btst	#3,pflags(a3)	;checks if player a3 is player controlled
	beq.w	.CheckingCalc
.PlayerControlled	;(no xref; a label inside CCStart). Changes d0 from 120 to 240
	;changes d0 from 120 to 240
	asl.w	#1,d0
.CheckingCalc	;(a label inside CCStart)
	sub.b	weight(a3),d0	;subtract wgt of a3 player from d0. a3 is player checking.
	add.b	$67(a2),d0	;add wgt of a2 player to d0
	lsr.w	#1,d0	;shift d0 1 right word length (divide by 2)
	exg	a2,a3	;swap addresses in a2 and a3 registers
	jsr	(wallcollduringcheck).l
	exg	a2,a3
	sub.w	impact(a2),d0	;subtract impact value of player getting checked (a2)
	beq.w	.down	;If result=0, branch
	bmi.w	.down	;If result was neg., branch
	btst	#pf3wall,pflags3(a3)	;wall collision bit
	bne.w	.down	;branch if bit set
	bsr.w	randomd0	;d0 is the RNG range.
	;Result will be in d0 (0 <= d0 < range)
	clr.w	(TempWord1).w
	move.b	checking(a3),(TempWord1+1).w	;$75 is Chk attrib. in player struct
	lsr.w	(TempWord1).w	;Shift right 1 bit
	cmp.b	(TempWord1+1).w,d0	;d0 - Chk rating / 2
	ble.w	.down	;branch if d0 less than FFBF13
	bsr.w	checkagr
	cmp.w	#4,d0
	bhi.w	rtss2
	btst	#4,(gmode).w	;checks if highlight
	bne.w	rtss2
	move.b	(VDP_CNTR).l,d0	;HVcount
	andi.w	#2,d0
	addi.w	#$16,d0	;#PenCharging
	jsr	(PenShotChk).l	;penalty shot on a breakaway
	bra.w	AddPenalty
.down
	bsr.w	checkagr
	cmp.w	#3,d0
	bhi.w	.dn2
	btst	#4,(gmode).w	;checks if highlight
	bne.w	.dn2
	move.b	(VDP_CNTR).l,d0	;HVcount
	andi.w	#2,d0
	addi.w	#$1A,d0	;#PenRoughing2
	jsr	(PenShotChk).l	;penalty shot on a breakaway
	bsr.w	AddPenalty
.dn2
	bra.w	FallDown
checkinglist	;Check anim by direction from a3 to a2, SPA offsets
	dc.w	$B96	;SPAshoulderchkl
	dc.w	$BC8	;SPAshoulderchkr
	dc.w	$C2C	;SPAhipchkr
	dc.w	$C2C	;SPAhipchkr
	dc.w	$C2C	;SPAhipchkr
	dc.w	$BFA	;SPAhipchkl
	dc.w	$BFA	;SPAhipchkl
	dc.w	$B96	;SPAshoulderchkl
checkagr	;use Agression attribute and RNG to determine if there will be a penalty. a3 = checking player, a2 = player being checked. d0 =
	;randomd0(((40 - Agr) / 2) * 13), doubled for a joystick player, halved within $28 of the puck in x and y. 94 then: a2 on a breakaway rolls
	;randomd0 again, of 8 / 7 / 4 / 3 by a2's distance in y from the goal line; and d0 = $7F (no penalty) while the other team has a delayed
	;penalty (DelayedPen). The callers call a penalty when d0 is small. Called from CCStart, holdcheck and Bcheck
	move.w	#$28,d0	;Start calculation with 40 decimal (28 hex)
	sub.b	aggress(a3),d0	;Agr(a3) - subtract Agr from d0
	lsr.b	#1,d0	;divide result by 2
	mulu.w	#$D,d0	;multiply d0 with 13 decimal
	btst	#pfjoycon,pflags(a3)	;test if player controlled
	beq.w	.checkpos	;branch if CPU player
	asl.w	#1,d0	;multiply by 2
.checkpos
	move.w	(a3),d1	;XPos
	sub.w	(puckx).w,d1	;subtract x pos of puck with X pos of player
	cmp.w	#$28,d1	;Checking position with respect to puck
	bgt.w	.random	;if d1 is greater than 28 hex (40 dec), jump
	cmp.w	#$FFD8,d1	;checking the inverse position (other side of rink)
	blt.w	.random
	move.w	Ypos(a3),d1	;Ypos
	sub.w	(pucky).w,d1
	cmp.w	#$28,d1	;same as above
	bgt.w	.random
	cmp.w	#$FFD8,d1	;checking the inverse position (other side of rink)
	blt.w	.random
	asr.w	#1,d0	;divide by 2
.random
	bsr.w	randomd0
	btst	#pf3break,pflags3(a2)	;Check for player on breakaway
	beq.w	.teamchk	;branch if bit is 0
	move.w	Ypos(a2),d1	;Ypos of player being checked
	bpl.w	.calc	;will jump if Ypos is positive
	neg.w	d1	;flip result (other side of rink)
.calc
	subi.w	#$108,d1	;subtract from Ypos
	neg.w	d1	;flip Y pos
	move.w	#8,d0	;move 8 into d0. Removes any trace of Agr here
	cmp.w	#$75,d1	;compares Ypos calc to 75 hex
	bgt.w	.rand2	;branch if higher than 75 hex
	move.w	#7,d0	;move 7 into d0
	cmp.w	#$3A,d1	;compare 3A hex to Ypos calc
	bgt.w	.rand2	;jump if higher than 3A hex
	move.w	#4,d0	;moves 4 into d0
	cmp.w	#$2C,d1	;compares 2C hex to Ypos calc
	bgt.w	.rand2	;jump if higher than 2C hex
	move.w	#3,d0	;finally, just move 3 in d0
.rand2
	bsr.w	randomd0
.teamchk
	btst	#6,pflags(a3)	;checks if home or away team
	bne.w	.away
	btst	#2,(DelayedPen).w	;visitors have a delayed penalty
	bne.w	.nopen
	bra.w	.end
.away
	btst	#1,(DelayedPen).w	;home team has a delayed penalty
	beq.w	.end
.nopen
	move.w	#$7F,d0
.end
	rts
holdcheck	;player a2 is in hold animation looking to hold opponent a3. Entered from CCStart for SPAHold or SPAhook. a3 must be within 1
	;direction of where a2 faces. a3 flails, a2 goes to SPAHold2 (or SPAhook2), and checkagr rolls penalty $24 after SPAHold2 or $1E after
	;SPAhook2 (94: through PenShotChk)
	btst	#pfalock,pflags(a3)	;#pfalock - locked animation
	bne.w	rtss2
	tst.w	position(a3)	;position - no hold on goalies
	beq.w	rtss2
	btst	#pf2fight,pflags2(a3)	;#pf2fight - no hold on fighters
	bne.w	rtss2
	move.w	(a3),d0	;Xpos a3
	sub.w	(a2),d0	;Xpos a2
	move.w	Ypos(a3),d1	;Ypos a3
	sub.w	Ypos(a2),d1	;Ypos a2
	bsr.w	vtoa
	sub.w	facedir(a2),d0	;facedir(a2)
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	rtss2
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.holdcheck
	bclr	#sfssdir,(sflags).w	;a3 has the puck
.holdcheck
	move.w	Xvel(a3),d0	;Xvel(a3)
	add.w	Xvel(a2),d0	;Xvel(a2)
	asr.w	#1,d0
	move.w	d0,Xvel(a3)
	move.w	d0,Xvel(a2)
	move.w	Yvel(a3),d0	;Yvel(a3)
	add.w	Yvel(a2),d0	;Yvel(a2)
	asr.w	#1,d0
	move.w	d0,Yvel(a3)
	move.w	d0,Yvel(a2)
	bset	#pfalock,pflags(a3)	;pfalock
	move.w	#$CF4,d1	;SPAflail
	bsr.w	SetSPA
	exg	a2,a3
	bset	#5,pflags(a3)	;pfalock
	move.w	#$CC2,d1	;SPAHold2
	cmpi.w	#$C90,SPA(a3)	;SPAHold
	beq.w	.setanimation
	move.w	#$1154,d1	;SPAhook2
.setanimation
	bsr.w	SetSPA
	bsr.w	checkagr
	cmp.w	#6,d0
	bhi.w	.ex
	btst	#4,(gmode).w	;check for highlight
	bne.w	.ex
	move.w	#$24,d0	;penalty $24 after SPAHold2 ( PenHooking?)
	cmpi.w	#$CC2,SPA(a3)	;SPAHold2
	beq.w	.addpen
	move.w	#$1E,d0	;penalty $1E after SPAhook2 ( PenHolding)
.addpen
	jsr	(PenShotChk).l
	bsr.w	AddPenalty
.ex
	exg	a2,a3
	st	(collflag).w
	rts
Bcheck	;a2 = player that is B checking, a3 = player being checked. Entered from CCStart. If OptPen is 0 and a2 is joystick controlled
	;a2 needs randomd0($20 + a2 Chk - a3 Agl, 2 less when sflags8 bit 1 or sflags7 bit 6 is set) >= $18 (93 used $10 + Chk - legstr, >= $C).
	;If a3 is within 1 direction of where a2 faces, a3 falls and checkagr may call penalty $20 (tripping) on a2. Sets collflag
	btst	#pfalock,pflags(a3)	;check if locked in animation
	bne.w	rtss2	;exit if locked
	tst.w	position(a3)	;check if goalie
	beq.w	rtss2	;exit if goalie
	btst	#pf2fight,pflags2(a3)	;is player fighting?
	bne.w	rtss2	;exit if fighting
	tst.w	(OptPen).w	;check for penalties
	bne.w	.checkdir	;Branch if penalties
	btst	#pfjoycon,pflags(a2)	;check if player controlled
	beq.w	.checkdir	;branch if not
	move.w	#$20,d0	;20 hex starting value
	add.b	checking(a2),d0	;add Chk of player B checking
	sub.b	legstr(a3),d0	;sub Agl of player being checked
	btst	#1,(sflags8).w
	bne.w	.sub2
	btst	#6,(sflags7).w
	beq.w	.rnd
.sub2
	subq.b	#2,d0	;sub 2 from d0
.rnd
	bsr.w	randomd0
	cmp.w	#$18,d0
	blt.w	rtss2	;if less than, unsuccessful B check
.checkdir
	move.w	(a3),d0	;Xpos a3
	sub.w	(a2),d0	;sub Xpos a2 from Xpos a3
	move.w	Ypos(a3),d1	;Ypos a3
	sub.w	Ypos(a2),d1	;sub Ypos a2 from Ypos a3
	bsr.w	vtoa
	sub.w	facedir(a2),d0	;sub facedir from d0
	addq.w	#1,d0
	andi.w	#7,d0	;pass first 3 bits of d0
	cmp.w	#2,d0
	bhi.w	rtss2	;exit if higher than 2
	exg	a2,a3
	bsr.w	FallDown
	bsr.w	checkagr
	cmp.w	#4,d0
	bhi.w	.exit
	move.w	#$20,d0	;Tripping
	jsr	(PenShotChk).l
	bsr.w	AddPenalty
.exit
	exg	a2,a3
	st	(collflag).w
	rts
FallDown	;player a2 falls down, player a3 is the hitting player. Skips a2 in some anims, or the same pair as the last call. A skater hitter
	;adds check stats (team $10, player $11C, ChkCnt). 94: a hit into the wall picks a fall anim from .FallList by where a2 is (the SPAboardright /
	;SPAboardleft falls near center ice (|Ypos| up to $59 / $38) become SPAboardmidl / SPAboardmidr), a strong Stk player may just stumble, and an injury
	;(setInjuryType) adds penalty $12 (or $14) and stops play. Then the crowd and a check sound (newcheck). Called from checkint (.ci), CCStart and
	;Bcheck
	cmpi.w	#$B,SCnum(a2)	;0-11 are player structs
	bgt.w	rtss2	;exit if not a player struct
	cmpi.w	#$145C,SPA(a2)	;SPAinjuryfall. checks various animations and exits if one of them
	beq.w	rtss2
	cmpi.w	#$1AF4,SPA(a2)	;SPAinjury1
	beq.w	rtss2
	cmpi.w	#$11E6,SPA(a2)	;SPAstumble
	beq.w	rtss2
	cmpi.w	#$D26,SPA(a2)	;SPAfallfwd
	beq.w	rtss2
	cmpi.w	#$DD8,SPA(a2)	;SPAfallback
	beq.w	rtss2
	cmpi.w	#$136A,SPA(a2)	;SPAflip
	beq.w	rtss2
	cmpa.l	(PlayerChked).w,a2	;compared to previous player checked
	bne.w	.cont	;branch if not the same
	cmpa.l	(PlayerChking).w,a3	;compares a3 to previous player checking
	bne.w	.cont	;branch if not the same
	rts	;exit if both players are the same as last Fall Down attempt
.cont
	move.l	a2,(PlayerChked).w	;player checked
	move.l	a3,(PlayerChking).w	;player checking
	btst	#pf3onetimer,pflags3(a2)	;is player a2 doing a one-timer
	bne.w	rtss2	;exit if yes
	btst	#pf3onetimer,pflags3(a3)	;Is player a3 doing a one-timer
	bne.w	rtss2	;exit if yes
	move.w	#$11E6,d1	;SPAstumble. toddle animation?
	btst	#pf3wall,pflags3(a3)	;wall collision bit
	bne.w	.cont2	;jump if hitting wall
.CmpPlayerStk	;(no xref; a label inside FallDown). a2's Stk value. Compares to $18 (24 decimal)
	;a2's Stk value. Compares to 18 (24 decimal)
	cmpi.b	#$18,stickhand(a2)	;Start of toddle check
	blt.w	.cont2	;jump if less than
	tst.b	nopuck+1(a2)	;check if puck collision possible
	bne.w	.cont2	;jump if not
	move.w	(VDP_CNTR).l,d0	;frame counter
	andi.w	#$F,d0	;pass 1st byte of d0
	addi.w	#$10,d0	;add 10 hex to d0
	cmp.w	impact(a2),d0	;compare impact value to d0.
	;d0 will be 10-1F hex (16-31 decimal)
	ble.w	.cont2	;no toddle if d0 <= impact
	move.b	#$3C,nopuck+1(a2)	;move 3C (60 decimal) into nopuck
	bra.w	.2
.cont2
	tst.w	position(a3)	;check for goalie
	beq.w	.chkpos	;jump if goalie
	movea.w	#(tmstruct-M68K_RAM),a0	;Start of Home Team Stats Struct
	btst	#pfteam,pflags(a3)
	beq.w	.AddChktoPlayerStats
	adda.w	#tmsize,a0	;Change to Away Team Stats
.AddChktoPlayerStats	;(a label inside FallDown)
	addq.w	#1,$10(a0)	;Add 1 Chk to Team Total
	clr.w	d0
	move.b	pnum(a3),d0	;Index of Player
	adda.w	d0,a0
	addq.b	#1,$11C(a0)	;Add 1 Chk to Player Stats
	addq.w	#1,(ChkCnt).w	;Add 1 to ChkCnt
	tst.b	fighting(a3)	;checks fight attribute?
	bne.w	.chkpos	;jump if fight attribute not 0
	addq.w	#2,(ChkCnt).w	;add 2 to ChkCnt
.chkpos
	move.b	#$78,nopuck(a2)
	move.w	(a3),d0	;Xpos
	sub.w	(a2),d0	;sub Xpos
	move.w	Ypos(a3),d1	;Ypos
	sub.w	Ypos(a2),d1	;sub Ypos
	bsr.w	vtoa
	tst.w	$34(a2)	;check if goalie a2
	beq.w	.7	;branch if goalie
	jsr	(wallcollduringcheck).l	;check for wall collision
	btst	#pf3wall,pflags3(a2)	;check wall collision bit
	beq.w	.7	;jump if not collision
	movem.l	d1-d4,-(sp)
	move.w	Xvel(a2),d1	;move Xvel into d1
	bpl.w	.yvel	;branch if positive
	neg.w	d1	;negate d1
.yvel
	move.w	Yvel(a2),d2	;move Yvel into d2
	bpl.w	.chkpos2	;branch if positive
	neg.w	d2	;negate d2
.chkpos2
	move.w	(a2),d3	;Xpos of player into d3
	sub.w	(a3),d3	;sub Xpos of checker
	move.w	Ypos(a2),d4	;Ypos of player into d4
	sub.w	Ypos(a3),d4	;sub Ypos of checker
	cmpi.w	#$108,Ypos(a3)	;compare Ypos of a3 to top goal line
	bgt.w	.bnet1	;branch if behind net
	cmpi.w	#$FEF8,Ypos(a3)	;compare to bottom goal line Y
	blt.w	.bnet2	;branch if behind net
	tst.w	(a3)	;In between goal lines
	;Check Xpos of checker
	bpl.w	.posx	;branch if positive (right side of center)
	tst.w	d3	;check diff of Xpos
	bpl.w	.chktowardcenterice	;branch if positive (player to right of checker)
	cmp.w	#$FFFD,d3	;comp diff of Xpos with -3
	bgt.w	.chktowardcenterice	;branch if greater than
	bra.w	.chkawayfromcenterice	;player to left of checker
.posx
	tst.w	d3	;check diff of Xpos
	bmi.w	.chktowardcenterice	;branch if negative (player to left of checker)
	cmp.w	#3,d3	;comp diff of Xpos with 3
	blt.w	.chktowardcenterice	;branch if less than
	bra.w	.chkawayfromcenterice	;player to right of checker
.bnet2
	tst.w	d4	;check diff of Ypos
	bpl.w	.chktowardcenterice	;branch if positive
	;player higher than checker
	bra.w	.chkawayfromcenterice	;player lower than checker
.bnet1
	tst.w	d4	;check diff of Ypos
	bmi.w	.chktowardcenterice	;branch if negative
	;player lower than checker
	bra.w	.chkawayfromcenterice	;player higher than checker
.chktowardcenterice
	movem.l	(sp)+,d1-d4
	bra.w	.7
.chkawayfromcenterice
	movem.l	(sp)+,d1-d4	;pop from stack
	bra.w	*+4	;to the next instruction (.playerpos)
.playerpos
	cmpi.w	#$10C,Ypos(a2)	;Ypos player
	;check if player is above top goal line
	bgt.w	.chkawayfrommiddle	;branch if above
	cmpi.w	#$FEF4,Ypos(a2)	;Check if player is below bottom goal line
	blt.w	.chkawayfrommiddle	;branch if below
	cmpi.w	#$68,(a2)	;Xpos player
	;check if right of crease?
	bgt.w	.chkawayfrommiddle	;branch if to the right
	cmpi.w	#$FF98,(a2)	;check if left of crease?
	blt.w	.chkawayfrommiddle	;branch if to the left
	bra.w	.7	;right of crease
.chkawayfrommiddle
	cmpi.w	#$B,SCnum(a3)	;check if SCNum is a player
	bgt.w	.0	;branch if not player
	addi.w	#$A,(CwdExciteLvl).w
	addi.w	#$96,(crowdlevel).w
	move.w	d1,-(sp)	;push to stack
	move.b	#0,temp1(a3)	;clear temp1
	move.b	#0,glitch(a3)	;clear glitch
	move.w	#$1AC2,d1	;SPAboardchk
	jsr	(SetSPA).l	;set animation
	clr.w	Xvel(a3)	;clear Xvel
	clr.w	Yvel(a3)	;clear Yvel
	move.w	(sp)+,d1	;pop from stack
.0
	movem.l	d0/a0,-(sp)	;push to stack
	cmpi.w	#$10C,Ypos(a2)	;check player Ypos with top goal line
	bgt.w	.playerabovetopgoalline	;branch if above
	cmpi.w	#$FEF4,Ypos(a2)	;check player Ypos with bottom goal line
	blt.w	.playerbelowbottomgoalline	;branch if below
	tst.w	(a2)	;test player Xpos
	bmi.w	.playerleftofcenter	;branch if negative
	move.w	#2,d0	;player right of center
	bra.w	.getchkanim
.playerleftofcenter
	move.w	#6,d0
	bra.w	.getchkanim
.playerabovetopgoalline
	move.w	#0,d0
	bra.w	.getchkanim
.playerbelowbottomgoalline
	move.w	#4,d0
.getchkanim
	add.w	d0,d0
	movea.l	#.FallList,a0
	move.w	0(a0,d0.w),d1	;move animation from list into d1
	move.w	Ypos(a2),(FallYPos).w
	move.w	(a2),(FallXPos).w
	cmp.w	#$18CC,d1	;SPAboardleft. player left of center
	bne.w	.1	;branch if not
	cmpi.w	#$59,Ypos(a2)	;compare $59 to Ypos
	bgt.w	.1	;branch if higher
	cmpi.w	#$FFA7,Ypos(a2)	;compare -$59 to Ypos
	blt.w	.1	;branch if lower
	move.w	d0,-(sp)
	move.w	#7,d0
	jsr	(StartArenaAnim).l
	move.w	(sp)+,d0
	move.w	#$193E,d1	;SPAboardmidl. anim value
	btst	#3,4(a2)
	beq.w	.6
	move.w	#$1A00,d1	;SPAboardmidr
	bra.w	.6
.1
	cmp.w	#$17E8,d1	;SPAboardright. player right of center
	bne.w	.4	;branch if not
	cmpi.w	#$38,Ypos(a2)	;compare $38 to Ypos
	bgt.w	.4	;branch if higher
	cmpi.w	#$FFC8,Ypos(a2)	;compare -38 to Ypos
	blt.w	.4	;branch if lower
	move.w	#$1A00,d1	;SPAboardmidr. change anim value
	btst	#3,4(a2)	;check bit 3 of frame
	beq.w	.6	;branch if zero
	move.w	#$193E,d1	;SPAboardmidl. change anim value
	bra.w	.6
.4
	btst	#3,4(a2)	;check bit 3 of frame
	beq.w	.6	;branch if zero
	cmp.w	#$17E8,d1	;SPAboardright. right of center
	beq.w	.5	;branch if right of center
	cmp.w	#$18CC,d1	;SPAboardleft. left of center
	bne.w	.6	;branch if not left of center
	move.w	#$17E8,d1	;SPAboardright. change anim to same as right of center
	bra.w	.6
.5
	move.w	#$18CC,d1	;SPAboardleft. change anim
.6
	clr.w	Xvel(a2)	;clear Xvel
	clr.w	Yvel(a2)	;clear Yvel
	bset	#pf3fall,pflags3(a2)	;set falldown bit
	bset	#0,pflags(a2)	;set pfdoff (deceleration)
	movem.l	(sp)+,d0/a0	;pop from stack
	bra.w	.8
.FallList	;(a table inside FallDown). Fall anim by where a2 is: above, right, below, left (2 words each)
	dc.w	$1776	;SPAboardtop
	dc.w	$1776	;SPAboardtop
	dc.w	$17E8	;SPAboardright
	dc.w	$17E8	;SPAboardright
	dc.w	$185A	;SPAboardbot
	dc.w	$185A	;SPAboardbot
	dc.w	$18CC	;SPAboardleft
	dc.w	$18CC	;SPAboardleft
.7
	move.w	#$DD8,d1	;SPAfallback
	sub.w	facedir(a2),d0	;facedir
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bls.w	.2
	move.w	#$D26,d1	;SPAfallfwd
.8
	move.w	facedir(a2),d0	;facedir
	andi.w	#3,d0
	bne.w	.2	;branch if first 2 bits of d0 arent zero
	cmpi.b	#$14,checking(a3)	;compare $14 to checker Chk attribute
	blt.w	.2	;branch if less than
	cmpi.w	#$B,SCnum(a3)	;check if SCNum of checker is a player
	bgt.w	.2	;branch if not
	btst	#pf3fall,pflags3(a2)	;check if falldown bit is set for player
	bne.w	.2	;branch if set
	move.w	#$136A,d1	;SPAflip. move anim into d1
.2
	exg	a2,a3	;swap a2 and a3
	bset	#pfalock,pflags(a3)	;set animation lock
	bsr.w	SetSPA	;set animation with d1 value
	exg	a2,a3	;swap back a2 and a3
	tst.w	position(a3)	;check if checking player is goalie
	beq.w	.21	;jump if goalie
	tst.w	$34(a2)	;check if player checked is goalie
	beq.w	.21	;jump if goalie
	addi.w	#$12C,(crowdlevel).w	;add to crowd level
	addi.w	#$F,(CwdExciteLvl).w	;add to crowd excite level
.21
	move.w	(puckc).w,d0	;move puck carrier SCNum into d0
	bmi.w	newcheck	;make check sound
	cmp.w	SCnum(a2),d0	;check if puck carrier is a2
	bne.w	newcheck
	st	(puckc).w	;clear out puck carrier
	btst	#gmhl,(gmode).w	;check if highlight
	bne.w	.22	;jump if highlight
	cmpi.w	#$DD8,SPA(a2)	;SPAfallback. check animation (player who is checked)
	bne.w	.22	;jump if not equal
	move.w	facedir(a2),d0	;facedir into d0
	andi.w	#3,d0	;pass first 2 bits of d0
	bne.w	.22
	btst	#4,pflags2(a2)	;check if player is unavailable
	bne.w	.22	;jump if unavailable
	move.l	#$A0,d0
	bsr.w	randomd0
	cmp.w	impact(a2),d0	;compare impact to d0
	bgt.w	.22	;jump if d0 higher than impact
	btst	#gmclock,(gmode).w	;check if clock running
	bne.w	.22	;jump if not
	exg	a2,a3
	move.w	#$145C,d1	;SPAinjuryfall. set injury animation
	bsr.w	SetSPA
	exg	a2,a3
	bsr.w	setInjuryType
	btst	#5,(sflags7).w	;check if game injury
	bne.w	.9	;branch if game injury
	exg	a2,a3
	move.w	#$1AF4,d1	;SPAinjury1. set injury animation
	bsr.w	SetSPA
	exg	a2,a3
.9
	move.w	#4,(InjCntDown).w
	move.l	#$14,d0	;move 14 into d0 - Pen ???
	tst.w	position(a3)	;check if a3 goalie
	beq.w	AddPenalty2	;jump if goalie
	tst.w	(OptPen).w	;check penalties
	beq.w	AddPenalty2	;jump if off
	move.l	#$12,d0	;Pen Roughing
	bsr.w	AddPenalty2
	bra.w	Stop4Pen
.22
	move.w	#$B,-(sp)	;#SFXcrowdcheer
	btst	#pfteam,pflags(a2)	;check team
	bne.w	.3	;jump if away team
	move.w	#$C,(sp)	;#SFXcrowdboo
.3
	bsr.w	song
	rts
setInjuryType	;determines if injury will be for period or game. a2 = player injured, a3 = player checking. Marks a2 unavailable, pumps up the crowd,
	;plays sfx $D, locks the scroll on a2 and sets TempPlOffset (pnum, bit 15 set for the away team). a2's tmpdst becomes $FFFD (injured for the
	;period) or, from a3's Fgt byte (getFgtbyte, chkFgtBit1), $FFFC (injured for the game, sflags7 bit 5). Called from FallDown
	move.w	d0,-(sp)
	bset	#2,pflags2(a2)	;set player unavailable
	addi.w	#$12C,(crowdlevel).w
	addi.w	#$1E,(CwdExciteLvl).w
	move.w	#SFX0D,-(sp)	;sound effect
	bsr.w	sfx
	move.w	(a2),(xc1).w	;move Xpos to scroll center
	move.w	Ypos(a2),(yc1).w	;move Ypos to scroll center
	bset	#sfslock,(sflags).w	;set sfslock (scroll lock)
	clr.w	d1	;clear d1
	movea.w	#(tmstruct-M68K_RAM),a0	;move Home team Struct to a0
	btst	#pfteam,pflags(a2)	;check if player home or away
	beq.w	.0	;branch if home
	move.w	#$8000,d1	;move $8000 into d1
	adda.w	#tmsize,a0	;add $364 to a0 (Away Team Struct start)
.0
	move.b	pnum(a2),d1	;move roster offset into d1
	move.w	d1,(TempPlOffset).w
	ext.w	d1	;sign extend - in this case just makes upper bye of word 00
	add.w	d1,d1	;add d1 to itself
	exg	a2,a3	;swap a2 and a3
	jsr	(getFgtbyte).l	;get the Fgt byte (divided by 4)
	exg	a2,a3	;swap back
	tst.w	d0	;check if d0 is zero
	bne.w	.not0	;branch if H/F was more than 3
	bclr	#5,(sflags7).w	;clear injury game bit
	move.w	#$FFFD,$66(a0,d1.w)	;update status of player
	bra.w	.exit
.not0
	cmp.w	#3,d0	;compare d0 to 3 (if H/F was 12, d0 = 3)
	beq.w	.injurygame
	bclr	#5,(sflags7).w
	move.w	#$FFFD,$66(a0,d1.w)	;update status of player
	jsr	(chkFgtBit1).l	;check Fgt bit 1 of player.
	beq.w	.exit	;jump if Fgt not 2,6,A
.injurygame
	bset	#5,(sflags7).w	;set injury game bit
	move.w	#$FFFC,$66(a0,d1.w)	;update status of player
.exit
	move.w	(sp)+,d0
	rts
;	checkfight (an rts), checkwallcoll, checkgoal, GetPeriodTimeRemaining,
;	checkgoalp, CheckBump, wallcollb, wallcoll, checkpuckcoll_sfx (entered
;	from checkpuckcoll) and checkpuckcoll.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	Sort struct (SortCords, $80 each): 0 Xpos, 4 attribute, 6 frame, $14 Ypos, $18 Zpos, $1C OldXpos, $20 OldYpos,
;	$24 OldZpos, $28 Xvel, $2A Yvel, $2C Zvel, $32 impact, $34 position, $4E wallcos, $50 wallsin, $52 SCnum, $58 SPA,
;	$5E nopuck (byte), $62 pflags, $63 pflags2, $64 bit 3 one-timer, bit 4 wall collision, $68 Agl, $76 handedness.
;	94 team struct from HmShots / AwShots (tmsize $364): $C tmscore, $18-$1C scorer and assists, $22 tmsort, $24 tmap,
;	$26 tmgoalie, $B4 / $CE goal / assist bytes per player, $342 goals by period, $356 PP goals, $35A BA goals, $362 SH goals.

checkfight	;an rts: there is no fighting (93 looked for the start of a fight between a2 and a3 here). Called from checkcx
	rts
checkwallcoll	;d2/d3 = x/y to test, a3 = object, wcradiusx/wcradiusy = radius. Check the corner circles, the goals
	;(checkgoal with a2 = SortCords+(13*SCstruct) top, SortCords+(12*SCstruct) bottom) and then the side and end boards. Calls wallcollb on a hit, with d0/d1 = cos/sin of
	;the wall. Called from checkcoll
	bclr	#pf3wall,pflags3(a3)	;wall collision bit
	move.w	#$88,d4	;136
	sub.w	(wcradiusx).w,d4
	move.w	#$12A,d5	;298: end boards
	sub.w	(wcradiusy).w,d5
	movem.w	d2-d5,-(sp)
	neg.w	d4
	neg.w	d5
	addi.w	#$40,d4	;corner circle radius 64
	addi.w	#$40,d5
	cmp.w	d5,d3
	bgt.w	.0
	cmp.w	d4,d2
	blt.w	.1
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.1
	movea.w	#(SortCords+(13*SCstruct)-M68K_RAM),a2
	bsr.w	checkgoal
	bra.w	.2
.0
	neg.w	d5
	cmp.w	d5,d3
	blt.w	.2
	cmp.w	d4,d2
	blt.w	.1
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.1
	movea.w	#(SortCords+(12*SCstruct)-M68K_RAM),a2
	bsr.w	checkgoal
	bra.w	.2
.1
	sub.w	d4,d2
	sub.w	d5,d3
	move.w	d3,d0
	move.w	d2,d1
	neg.w	d1
	muls.w	d3,d3
	muls.w	d2,d2
	add.l	d2,d3
	cmp.l	#$1000,d3	;inside the corner circle (64*64)
	bls.w	.2
	exg	d0,d3
	bsr.w	sroot	;distance from the circle center
	exg	d0,d3
	ext.l	d0
	asl.l	#8,d0
	divs.w	d3,d0
	ext.l	d1
	asl.l	#8,d1
	divs.w	d3,d1
	bsr.w	wallcollb
.2
	movem.w	(sp)+,d2-d5
	move.w	$4E(a3),d0	;wallcos: already hit
	or.w	$50(a3),d0	;wallsin
	bne.w	rtss2
	move.w	#$100,d0
	clr.w	d1
	cmp.w	d5,d3
	bge.w	wallcollb
	neg.w	d5
	neg.w	d0
	cmp.w	d5,d3
	ble.w	wallcollb
	exg	d0,d1
	cmp.w	d4,d2
	bge.w	wallcollb
	neg.w	d4
	neg.w	d1
	cmp.w	d4,d2
	ble.w	wallcollb
	rts
checkgoal	;look for coll with goal/net. a2 = goal struct, a3 = object, d2/d3 = x/y. A puck under the crossbar hits a post or the net (deflect,
	;sfx $25 or 8 and crowd) or goes in (.goal); a player goes to checkgoalp. Called from checkwallcoll
	cmpi.w	#$D,Zpos(a3)	;13 pix for zside = height of goal (puck only check)
	bgt.w	rtss2	;over goal
	cmpi.w	#$E,SCnum(a3)	;puckSCnum
	bne.w	checkgoalp	;coll with player not puck
	sub.w	(a2),d2	;Xpos
	moveq	#$10,d4	;xside = 16  width of goal/2
	add.w	(wcradiusx).w,d4
	cmp.w	d4,d2
	bgt.w	rtss2
	neg.w	d4
	cmp.w	d4,d2
	blt.w	rtss2
	sub.w	Ypos(a2),d3	;Ypos
	move.w	#2,d5	;yside = 2 depth of goal/2
	add.w	(wcradiusy).w,d5
	cmp.w	d5,d3
	bgt.w	rtss2
	neg.w	d5
	cmp.w	d5,d3
	blt.w	rtss2
	st	(collflag).w	;inside goal area now
	cmpi.w	#$D,OldZpos(a3)	;compare OldZpos to zside
	blt.w	.nod	;branch if less than (in net)
	move.w	OldZpos(a3),Zpos(a3)
	bra.w	.deflectz
.nod
	bclr	#pfgoal,pflags(a3)
	move.w	(puckc).w,d0
	bmi.w	.nocon
	st	(puckc).w
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a0
	move.b	#8,nopuck(a0,d0.w)
	move.w	(pucky).w,d1
	btst	#pfgoal,pflags(a0,d0.w)
	bne.w	.an
	neg.w	d1
.an
	tst.w	d1
	bpl.w	.nocon
	bset	#pfgoal,pflags(a3)
.nocon
	move.w	#$FF00,d0
	move.l	Ypos(a3),d1
	sub.l	OldYpos(a3),d1
	asr.l	#8,d1
	beq.w	.sideentry
	bmi.w	.0
	neg.w	d0	;check top entry
	neg.w	d5
.0
	add.w	d3,d5
	move.l	(a3),d3
	sub.l	OldXpos(a3),d3
	asr.l	#8,d3
	muls.w	d3,d5
	divs.w	d1,d5
	bvs.w	.sideentry
	sub.w	d5,d2
	cmp.w	d4,d2
	blt.w	.sideentry
	neg.w	d4
	cmp.w	d4,d2
	bgt.w	.sideentry
	clr.w	d1
	move.w	Ypos(a3),d3
	eor.w	d0,d3
	bmi.w	wallcoll
	neg.w	d0
	btst	#pfgoal,pflags(a3)
	bne.w	wallcoll
	cmpi.w	#$D,Zpos(a3)
	beq.w	.deflectsf
	subq.w	#1,d4
	cmp.w	d4,d2
	bgt.w	.deflectsf
	neg.w	d4
	cmp.w	d4,d2
	bge.w	.goal
.deflectsf
	bsr.w	ChkShotStat	;deflection: count the shot
	move.w	#$25,-(sp)	;sfx $25 when the clock is stopped (92 used 9)
	btst	#gmclock,(gmode).w	;gmclock: no goal after the whistle
	bne.w	.deflectsf2
	move.w	#8,(sp)	;sfx 8 (92 used 31) and crowd
	addi.w	#$12C,(crowdlevel).w
	addi.w	#$28,(CwdExciteLvl).w
.deflectsf2
	bsr.w	sfx
	move.w	#$1000,d0
	bsr.w	randomd0
	tst.w	Ypos(a3)
	bmi.w	.df0
	neg.w	d0
.df0
	move.w	d0,Yvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Xvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Zvel(a3)
	bra.w	puckflip
.deflectz
	neg.w	Zvel(a3)
	bpl.w	rtss2
	neg.w	Zvel(a3)
	rts
.sideentry
	clr.w	d0
	move.w	#$100,d1
	move.w	(a3),d2
	sub.w	OldXpos(a3),d2
	bmi.w	wallcoll
	neg.w	d1
	bra.w	wallcoll
.goal	;puck in goal. 94 first: in a penalty shot or shootout (BA_PS_flags bit 2) only the shooter's end counts (gmode2 bit 0
	;shootout, shootoutteam picks the end); it counts the shootout goal (homeshootgoals / awayshootgoals) and calls EndPenaltyShotPlay
	btst	#2,(BA_PS_flags).w
	beq.w	.7
	btst	#0,(gmode2).w
	bne.w	.1
	movem.l	d0/a0,-(sp)
	move.w	(BA_Sktr_SCnum).w,d0
	asl.w	#7,d0
	movea.l	#SortCords,a0
	adda.w	d0,a0
	btst	#7,$62(a0)
	movem.l	(sp)+,d0/a0
	bne.w	.2
	bra.w	.3
.1
	tst.w	(shootoutteam).w
	bne.w	.3
.2
	tst.w	(pucky).w
	bmi.w	rtss2
	bra.w	.4
.3
	tst.w	(pucky).w
	bpl.w	rtss2
.4
	bset	#5,(sflags4).w	;penalty shot / shootout goal
	tst.w	(shootoutteam).w
	beq.w	.5
	addq.w	#1,(awayshootgoals).w
	bra.w	.6
.5
	addq.w	#1,(homeshootgoals).w
.6
	bset	#0,(sflags8).w
	jsr	(EndPenaltyShotPlay).l
	bra.w	.8
.7
	btst	#0,(gmode).w
	bne.w	rtss2
.8
	bset	#0,(sflags4).w
	bclr	#3,(sflags8).w
	bsr.w	ChkShotStat
	bsr.w	play_new_song
	move.w	d0,-(sp)
	move.w	(vcount).w,d0
.loop
	cmp.w	(vcount).w,d0	;wait for the next vblank
	beq.s	.loop
	move.w	(sp)+,d0
	move.w	#SFXsiren,-(sp)	;SFXsiren (0)
	bsr.w	sfx
	jsr	(freezewindow).l
	addi.w	#$1F4,(crowdlevel).w	;add 500 (92 800)
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	$364(a2),a1	;tmsize
	tst.w	Ypos(a3)
	bpl.w	.9
	exg	a2,a1
.9
	btst	#1,(gmode).w	;gmdir
	beq.w	.10
	exg	a2,a1
.10
	addq.w	#1,$C(a2)	;tmscore: add to Goals
	btst	#5,(sflags4).w	;goal stats
	beq.w	.11
	btst	#0,(gmode2).w	;no new assignments in a shootout
	bne.w	.11
	addq.w	#1,$362(a2)	;add to SH Goals
.11
	bclr	#4,(gmode2).w
	beq.w	.12
	addq.w	#1,$35A(a2)	;add to BA Goals
.12
	btst	#5,(sflags2).w	;sf2pwrplay
	beq.w	.14
	btst	#6,(sflags2).w	;sf2pwrtm: 0 home, 1 visitors
	bne.w	.13
	cmpa.l	#AwShots,a2
	bne.w	.14
.loop2
	addq.w	#1,$356(a2)	;power play goals
	bra.w	.14
.13
	cmpa.l	#tmstruct,a2
	beq.s	.loop2
.14
	movem.l	d0/a2,-(sp)
	move.w	(gsp).w,d0
	add.w	d0,d0
	adda.w	d0,a2
	addq.w	#1,$342(a2)	;goals by period
	movem.l	(sp)+,d0/a2
	bclr	#7,(sflags8).w
	beq.w	.15
	addq.w	#1,$35E(a2)	;sflags8 bit 7 goals
.15
	cmpa.w	#(tmstruct-M68K_RAM),a2	;home goal: ChooseSong
	bne.w	.16
	move.w	(HomeTeam).w,(HmTeam).w
	move.w	#3,(SongIndex).w
	jsr	(ChooseSong).l
	move.w	#$78,(songdelay).w
	move.w	(SongNum).w,-(sp)
	move.w	(sp)+,(delayedsong).w
.16
	cmpi.w	#$168,(ScoreSumbytes).w	;60 entries of 6 bytes full? (93 kept 30)
	bne.w	.17
	subq.w	#6,(ScoreSumbytes).w	;overwrite the last entry
.17
	movea.w	#(ScoreSum-M68K_RAM),a0
	adda.w	(ScoreSumbytes).w,a0
	addq.w	#6,(ScoreSumbytes).w
	bsr.w	GetPeriodTimeRemaining
	move.w	d0,(a0)+	;entry word 0 = period/time
	moveq	#2,d0
	add.w	$24(a2),d0
	sub.w	$24(a1),d0
	move.b	d0,(a0)+	;byte 2 = 2 + tmap(a2) - tmap(a1)
	addi.w	#$1E,(CwdExciteLvl).w
	cmpa.w	#(tmstruct-M68K_RAM),a2
	beq.w	.18
	subi.w	#$14,(CwdExciteLvl).w	;less for an away goal
	bset	#7,-1(a0)	;byte 2 bit 7 = away team scored
.18
	move.w	$18(a2),d0	;scorer
	move.b	d0,(a0)+
	move.w	#$FFFF,(a0)	;no assists yet
	addi.w	#$B4,d0
	addq.b	#1,0(a2,d0.w)	;team byte $B4 + scorer +1
	move.w	$1A(a2),d0	;first assist
	bmi.w	.19
	cmp.w	$18(a2),d0
	beq.w	.19
	move.b	d0,(a0)+
	addi.w	#$CE,d0
	addq.b	#1,0(a2,d0.w)
	move.w	$1C(a2),d0	;second assist
	bmi.w	.19
	cmp.w	$18(a2),d0
	beq.w	.19
	move.b	d0,(a0)
	addi.w	#$CE,d0
	addq.b	#1,0(a2,d0.w)
.19
	move.w	$26(a1),d0	;tmgoalie of the other team
	bmi.w	.20
	addi.w	#$B4,d0
	addq.b	#1,0(a1,d0.w)
.20
	bsr.w	ChkShotStat
	bsr.w	PenGoalStuff
	bclr	#3,(BA_PS_flags).w
	bsr.w	printscores1
	move.w	#$2710,(crowdnoisedelay).w
	btst	#0,(gmode2).w
	beq.w	.21
	bra.w	.22
.21
	move.l	#7,d0	;assignment 7 (92 used 8)
	bsr.w	.setass
.22
	clr.w	(collflag).w
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	moveq	#6,d0
	tst.w	(a3)
	bpl.w	.23
	neg.w	d0
.23
	move.w	d0,(a3)
	move.w	#$110,d0	;+goalline+8
	tst.w	Ypos(a3)
	bpl.w	.24
	neg.w	d0
.24
	move.w	d0,Ypos(a3)
	move.w	#$600,Zvel(a3)	;Zvel
	clr.w	Zpos(a3)
	st	(puckcross2).w
	st	(puckcross6).w
	bset	#2,pflags(a3)	;pfnc
	move.w	#$1A,d0	;puckunflip
	bsr.w	assreplace
	move.l	a3,-(sp)
	adda.w	#$80,a3	;SCstruct
	move.w	#$102E,d1	;siren SPA (92 used $FE8)
	bsr.w	SetSPA
	movea.w	$22(a1),a3	;first sort obj of the other team
	move.l	#$E,d0	;penalty $E (92 used 6)
	bsr.w	AddPenalty2
	movea.l	(sp)+,a3
	rts
.setass	;d0 = assignment, a2 = team. Give each skater of team a2 that is not fighting
	;assignment d0, clear pfnc. Also clears $64 bit 3 (one-timer) and then calls EndOneTimer. Called from checkgoal (.goal)
	move.l	a3,-(sp)
	movea.w	$22(a2),a3	;tmsort
	moveq	#5,d3
.loop3	;next skater
	tst.w	position(a3)	;position
	ble.w	.nl
	btst	#0,pflags2(a3)	;pf2fight
	bne.w	.nl
	bclr	#2,pflags(a3)	;pfnc
	bclr	#pf3onetimer,pflags3(a3)
	beq.w	.insert
	jsr	(EndOneTimer).l
.insert
	bsr.w	assinsert
.nl
	adda.w	#$80,a3
	dbf	d3,.loop3
	movea.l	(sp)+,a3
	rts
GetPeriodTimeRemaining	;Return d0 = (gsp << 14 | PerTimeTotal) - gameclock. Called from checkgoal (ScoreSum entry) and InProgress
	move.w	(gsp).w,d0
	swap	d0
	clr.w	d0
	lsr.l	#2,d0	;gsp in bits 14-15
	or.w	(PerTimeTotal).w,d0
	sub.w	(gameclock).w,d0
	rts
checkgoalp	;check for player a3 collision with goal/net a2. Entered from checkgoal. Oval goal; skipped for no player coll (pflags2 bit 5), a high
	;player or a non-player. CheckBump, then wallcoll with sflags6 bit 4 set (no wall collision bit)
	btst	#5,pflags2(a3)	;pflags2 bit 5: no player coll
	bne.w	rtss2
	cmpi.w	#$A,Zpos(a3)	;Zpos
	bgt.w	rtss2
	cmpi.w	#$B,SCnum(a3)	;SCnum: players only
	bgt.w	rtss2
	movem.w	d2-d3,-(sp)
	sub.w	Ypos(a2),d3
	move.w	d3,d0
	sub.w	(a2),d2
	move.w	d2,d1
	neg.w	d0
	asl.w	#4,d2
	muls.w	d2,d2
	divu.w	#$400,d2
	cmp.w	#$100,d2
	bhi.w	.exit
	asl.w	#4,d3
	muls.w	d3,d3
	divu.w	#$79,d3
	add.w	d2,d3
	cmp.w	#$100,d3
	bhi.w	.exit
	movem.w	(sp)+,d2-d3
	bsr.w	CheckBump
	movem.w	d2-d3,-(sp)
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	bsr.w	sroot
	move.w	d0,d2
	movem.w	(sp)+,d0-d1
	addq.w	#1,d2
	asl.l	#8,d0
	divs.w	d2,d0
	asl.l	#8,d1
	divs.w	d2,d1
	bset	#4,(sflags6).w	;wallcoll: do not set the wall collision bit
	bsr.w	wallcoll
	bclr	#4,(sflags6).w
.exit
	movem.w	(sp)+,d2-d3
	rts
CheckBump	;supply minimum separation velocity for coll with walls/goal/net. a2 = goal, a3 = player. On one frame in 32, a player near the puck
	;in y moving faster than $2000 knocks the net (a2 gets a quarter of a3's velocity, a3 stops, sfslock) and, while the clock runs, calls penalty
	;8. Called from checkgoalp
	movem.l	d0-d1,-(sp)
	move.w	(VDP_CNTR).l,d0
	andi.w	#$1F,d0
	bne.w	.ex
	move.w	(pucky).w,d0
	sub.w	Ypos(a2),d0
	cmp.w	#$28,d0
	bgt.w	.ex
	cmp.w	#$FFD8,d0
	blt.w	.ex
	move.w	Xvel(a3),d0
	move.w	Yvel(a3),d1
	cmp.w	#$2000,d0
	bgt.w	.bb
	cmp.w	#$E000,d0
	blt.w	.bb
	cmp.w	#$2000,d1
	bgt.w	.bb
	cmp.w	#$E000,d1
	blt.w	.bb
.ex
	movem.l	(sp)+,d0-d1
	rts
.bb
	adda.w	#$C,sp	;drop the saved d0-d1 and the return to checkgoalp: return to checkgoal's caller
	asr.w	#2,d0
	asr.w	#2,d1
	move.w	d0,Xvel(a2)
	move.w	d1,Yvel(a2)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	bset	#sfslock,(sflags).w	;sfslock
	btst	#gmclock,(gmode).w	;gmclock
	bne.w	rtss2
	move.l	#8,d0
	bra.w	AddPenalty2
wallcollb	;Check for puck over wall. a3 = object, d0/d1 = cos/sin of the wall. Not the puck, or Zpos up to $12
	;wallcoll. Zpos above $1D, or above $12 with Ypos below $118: out of play. Otherwise only at x $D-$F with Yvel >= $FA0 (else wallcoll): halve
	;Yvel, SPA $1078 on the next struct, sfx $E and crowd, then out of play. Out of play: sfslock, pfnc, and while the clock runs penalty 6
	;(PenOOP) for ltplayer. Called from checkwallcoll
	cmpi.w	#$E,SCnum(a3)	;#puckSCnum
	bne.w	wallcoll	;not puck so wall coll
	cmpi.w	#$1D,Zpos(a3)	;#12*8/3, Zpos
	bgt.w	.0
	cmpi.w	#$12,Zpos(a3)	;#8*8/3, Zpos
	bls.w	wallcoll
	cmpi.w	#$118,Ypos(a3)	;#280, Ypos
	blt.w	.0
	cmpi.w	#$D,(a3)	;14, Xpos
	blt.w	wallcoll
	cmpi.w	#$F,(a3)	;15, Xpos
	bgt.w	wallcoll
	cmpi.w	#$FA0,Yvel(a3)	;#4000, Yvel
	blt.w	wallcoll
	move.l	a3,-(sp)
	asr.w	Yvel(a3)	;Yvel / 2
	adda.w	#$80,a3	;next struct (SCstruct)
	move.w	#$1078,d1
	bsr.w	SetSPA
	movea.l	(sp)+,a3
	move.w	#SFX0E,-(sp)
	bsr.w	sfx
	addi.w	#$258,(crowdlevel).w
	addi.w	#$F,(CwdExciteLvl).w
.0
	bset	#6,(sflags).w	;#sfslock
	bset	#2,pflags(a3)	;#pfnc
	tst.w	Ypos(a3)	;Ypos
	bpl.w	.1
	ori.w	#$8000,4(a3)	;attribute(a3)
.1
	clr.w	$86(a3)	;frame+SCstruct(a3)
	btst	#0,(gmode).w	;#gmclock
	bne.w	rtss2
	move.l	a3,-(sp)
	move.w	(ltplayer).w,d0
	asl.w	#7,d0	;#scsize
	movea.w	#(SortCords-M68K_RAM),a3	;#sortcords
	adda.w	d0,a3
	move.l	#6,d0	;#PenOOP
	bsr.w	AddPenalty2
	movea.l	(sp)+,a3
	rts
wallcoll	;d0 = cosine, d1 = sine of angle of incidence with wall, a3 = object. Bounce a3 off the wall: the puck loses speed, flips and plays
	;sfx $28-$2B; a player sets the wall collision bit (unless sflags6 bit 4) and plays SFXplayerwall on a hard hit. Called from checkgoal,
	;checkgoalp and wallcollb
	move.w	d0,Wallcos(a3)	;wallcos
	move.w	d1,Wallsin(a3)	;wallsin
	movem.l	d2-d3,-(sp)
	movem.w	d0-d1,-(sp)
	muls.w	Yvel(a3),d0	;Yvel
	muls.w	Xvel(a3),d1	;Xvel
	sub.l	d1,d0
	asr.l	#8,d0
	move.w	d0,d2	;v1n
	movem.w	(sp),d0-d1
	muls.w	Xvel(a3),d0	;Xvel
	muls.w	Yvel(a3),d1	;Yvel
	add.l	d1,d0
	asr.l	#8,d0
	move.w	d0,d3	;v1t
	neg.w	d2
	cmpi.w	#$E,SCnum(a3)	;#puckSCnum, SCnum
	bne.w	.player
	bclr	#sf2shot,(sflags2).w	;#sf2shot
	tst.w	d2
	bpl.w	.nocoll
	asr.w	#2,d2	;reduce normal speed on puck
	cmp.w	#$FC00,d2	;#-400
	bgt.w	.pok
	move.w	#$800,d0
	bsr.w	randomd0
	neg.w	d0
	move.w	d0,Zvel(a3)	;Zvel
	bsr.w	puckflip
	move.w	d2,d0
	asr.w	#8,d0
	asr.w	#2,d0
	addq.w	#4,d0
	bpl.w	.sf0
	clr.w	d0
.sf0
	andi.w	#3,d0
	addi.w	#$28,d0
	move.w	d0,-(sp)
	bsr.w	sfx
.pok
	move.w	d3,d0	;reduce tangent speed on puck
	asr.w	#6,d0
	sub.w	d0,d3
	asr.w	#1,d0
	sub.w	d0,d3
	bra.w	.noadd
.player
	cmp.w	#$3E8,d2	;#1000
	bgt.w	.nocoll
	bclr	#4,(sflags6).w	;set by checkgoalp
	bne.w	.0
	bset	#pf3wall,pflags3(a3)	;set wall collision bit
.0
	cmp.w	#$F000,d2	;$-1000
	bgt.w	.nosfx
	cmpi.w	#$A,impact(a3)	;impact(a3)
	blt.w	.nosfx
	move.w	#SFXplayerwall,-(sp)	;#SFXplayerwall
	bsr.w	sfx
.nosfx
	asr.w	#2,d2
	cmp.w	#$FC7C,d2	;#-900
	blt.w	.noadd
	move.w	#$FC18,d2	;#-1000
.noadd
	movem.w	(sp),d0-d1
	movem.w	d2-d3,-(sp)
	muls.w	d0,d3
	muls.w	d1,d2
	sub.l	d2,d3
	asr.l	#8,d3
	move.w	d3,Xvel(a3)	;Xvel
	movem.w	(sp)+,d2-d3
	movem.w	(sp),d0-d1
	muls.w	d1,d3
	muls.w	d0,d2
	add.l	d2,d3
	asr.l	#8,d3
	move.w	d3,Yvel(a3)	;Yvel
	tst.w	Zvel(a3)	;Zvel
	bmi.w	.nocoll
	clr.w	Zvel(a3)	;Zvel
.nocoll
	addq.w	#4,sp
	movem.l	(sp)+,d2-d3
	rts
checkpuckcoll_sfx	;(a local of wallcoll in, entered from checkpuckcoll; a global so it does not clash with sfx). Puck in the air: sfx 5 once when sflags4 bit 2 is set
	bclr	#2,(sflags4).w
	beq.w	rtss2
	move.w	#5,-(sp)
	bra.w	sfx
checkpuckcoll	;look for puck coll with players. a3 = puck. Clears Yvel past the back boards, then walks up and down the OOlist from the puck and
	;runs .ccx on each object within 22 in y: stick (puckstick), body (puckbody) or goalie (puckgoalie). 94: in a penalty shot only the shooter
	;and the goalie touch the puck, and the goalie reach comes from.cbg /.cbgsq by Agl. Entered from pucknorm
	cmpi.w	#$190,Ypos(a3)	;compare 190 hex to Ypos (back board?)
	bgt.w	.resetYvel	;branch if greater than
	cmpi.w	#$FE70,Ypos(a3)	;compare -190 to Ypos (back board?)
	bgt.w	.setup	;branch if greater than
.resetYvel
	clr.w	Yvel(a3)	;clear Yvel
.setup
	cmpi.w	#$10,Zpos(a3)	;compare 10 hex to Zpos (feet in air)
	bgt.s	checkpuckcoll_sfx
	move.w	SCnum(a3),d0	;move SCnum into d0
	asl.w	#1,d0	;current obj number
	movea.w	#(OOlistpos-M68K_RAM),a0
	movea.w	#(OOlist-M68K_RAM),a1
	movea.w	#(Ylist-M68K_RAM),a2
	move.w	0(a0,d0.w),d1	;current obj position in OOlist
.0
	cmp.w	#$F,d1	;15 = Total sprites -1
	beq.w	.cl	;it is top sprite on screen
	clr.w	d4
	move.b	1(a1,d1.w),d4	;next higher object number
	move.w	0(a2,d4.w),d5	;Y pos of next higher object
	sub.w	Ypos(a3),d5	;sub Ypos from d5
	cmp.w	#$16,d5	;16 = cbody + cstick
	bgt.w	.cl	;no higher sprite coll
	bsr.w	.ccx
	addq.w	#1,d1
	bra.s	.0
.cl
	move.w	0(a0,d0.w),d1
	beq.w	.ex
.1
	clr.w	d4
	move.b	-1(a1,d1.w),d4	;next lower object number
	move.w	Ypos(a3),d5	;move Ypos into d5
	sub.w	0(a2,d4.w),d5	;sub Y pos of next lower object
	cmp.w	#$16,d5	;compare cbody+cstick to d5
	bgt.w	.ex
	bsr.w	.ccx
	subq.w	#1,d1
	bne.s	.1
.ex
	rts
.ccx
	movem.l	d0-d7/a0-a3,-(sp)
	lsr.w	#1,d4	;divide by 2
	cmp.w	(puckc).w,d4	;compare puckc to d4
	beq.w	.exit
	cmp.w	#$B,d4	;compare 11 to d4
	bgt.w	.exit
	asl.w	#7,d4	;#scsize
	movea.w	#(SortCords-M68K_RAM),a2
	adda.w	d4,a2	;a2 now has address of player struct
	btst	#2,(BA_PS_flags).w	;check bit 2
	beq.w	.ccx2	;branch if not set
	asr.w	#7,d4	;change d4 back to SCnum of puckc
	cmp.w	(BA_Sktr_SCnum).w,d4	;check d4 with SCnum of breakaway skater
	beq.w	.ccx2	;branch if the same
	cmp.w	(BA_Goalie_SCnum).w,d4	;check d4 with SCnum of breakaway goalie
	bne.w	.exit	;exit if not equal
.ccx2
	btst	#pfnc,pflags(a2)	;check if no player collision
	bne.w	.exit	;exit if set
	tst.b	nopuck(a2)	;check if nopuck collision
	bne.w	.exit	;branch if nopuck
	btst	#2,pflags2(a2)	;check if player unavailable
	bne.w	.chkbody	;branch if so
	cmpi.w	#5,Zpos(a3)	;compare 5 to Zpos
	bgt.w	.chkbody	;branch if higher
	cmpi.w	#$200,Zvel(a3)	;compare 200 hex to Zvel
	bgt.w	.chkbody	;branch if higher
	move.l	a2,-(sp)
	bsr.w	GetHot	;Get Hot Spot d0/d1 = x/y
	add.w	(a2),d0	;add Xpos a2
	sub.w	(a3),d0	;sub Xpos a3
	cmp.w	#$E,d0	;compare to cstick (E hex)
	bgt.w	.chkbody	;branch if greater
	cmp.w	#$FFF2,d0	;compare to -cstick
	blt.w	.chkbody	;branch if less than
	add.w	Ypos(a2),d1	;add Ypos a2
	sub.w	Ypos(a3),d1	;sub Ypos a3
	cmp.w	#$E,d1	;compare to cstick
	bgt.w	.chkbody	;branch if greater
	cmp.w	#$FFF2,d1	;compare to -cstick
	blt.w	.chkbody	;branch if less than
	muls.w	d0,d0	;square d0
	muls.w	d1,d1	;square d1
	add.l	d1,d0	;add d1 to d0
	move.l	#$C4,d1	;move cstick squared to d1
	tst.b	nopuck(a3)	;check nopuck - puck not ready to be caught
	ble.w	.lo	;branch if less than or equal
	lsr.w	#2,d1	;divide d1 by 4
.lo
	cmp.l	d1,d0	;compare d1 to d0
	bhi.w	.chkbody	;branch if higher
	bsr.w	puckstick
	bra.w	.exit
.chkbody
	tst.w	position(a2)	;check if goalie
	beq.w	.chkgoalie	;branch if goalie
	btst	#pf3onetimer,pflags3(a2)	;check if doing one timer
	bne.w	.exit	;exit if so
	move.w	(a2),d0	;Xpos into d0
	sub.w	(a3),d0	;sub Xpos a3
	cmp.w	#8,d0	;compare to cbody
	bgt.w	.exit	;exit if greater
	cmp.w	#$FFF8,d0	;compare to -cbody
	blt.w	.exit	;exit if less than
	move.w	Ypos(a2),d1	;Ypos into d1
	sub.w	Ypos(a3),d1	;sub Ypos a3
	cmp.w	#8,d1	;compare cbody
	bgt.w	.exit	;exit if greater
	cmp.w	#$FFF8,d1	;compare -cbody
	blt.w	.exit	;exit if less than
	muls.w	d0,d0	;square d0
	muls.w	d1,d1	;square d1
	add.l	d1,d0	;add d1 to d0
	cmp.l	#$40,d0	;compare cbody squared to d0
	bhi.w	.exit	;exit if higher
	bsr.w	puckbody
.ret
.exit
	movem.l	(sp)+,d0-d7/a0-a3
	rts
.cbg	;Goalie body reach by Agl/2 (words, 0-$1E)
	dc.w	$C	;Agility 0 (rounded down to nearest even number)
	dc.w	$C	;2
	dc.w	$D	;4 (0.8 or 1)
	dc.w	$D	;6
	dc.w	$D	;8
	dc.w	$D	;10 (2 or 2.2)
	dc.w	$D	;12
	dc.w	$D	;14 (2.8 or 3)
	dc.w	$D	;16
	dc.w	$D	;18
	dc.w	$E	;20 (4 or 4.2)
	dc.w	$E	;22
	dc.w	$E	;24
	dc.w	$E	;26
	dc.w	$F	;28
	dc.w	$F	;30 (6)
	dc.w	$F	;32
	dc.w	$F	;34
	dc.w	$F	;36
	dc.w	$F	;38
.cbgsq	;Reach squared
	dc.w	$90
	dc.w	$90
	dc.w	$A9
	dc.w	$A9
	dc.w	$A9
	dc.w	$A9
	dc.w	$A9
	dc.w	$A9
	dc.w	$A9
	dc.w	$A9
	dc.w	$C4
	dc.w	$C4
	dc.w	$C4
	dc.w	$C4
	dc.w	$E1
	dc.w	$E1
	dc.w	$E1
	dc.w	$E1
	dc.w	$E1
	dc.w	$E1
.chkgoalie
	move.l	a0,-(sp)	;push on stack
	movea.l	#.cbg,a0
	clr.w	d0
	move.b	$68(a2),d0	;move Agl into d0
	btst	#1,(sflags8).w	;check if cwd meter broken (always is)
	bne.w	.boost
	btst	#6,(sflags7).w	;check if crowd meter currently broken
	beq.w	.joycont	;branch if not
.boost
	addq.b	#2,d0
.joycont
	lsr.w	#1,d0	;divide by 2
	btst	#3,pflags(a2)	;check if joystick controlled
	beq.w	.calcagl	;branch if not
	move.w	#$F,d0	;move F into d0 (remove Agl)
.calcagl
	add.w	d0,d0	;add d0 to itself
	btst	#0,(gmode2).w	;check if shootout
	beq.w	.maxagl	;branch if not
	tst.w	d0	;check that d0 is 0
	beq.w	.maxagl	;branch if zero
	subq.w	#2,d0	;sub 2 from d0
.maxagl
	cmp.w	#$1E,d0	;compare to 1E
	blt.w	.checkbody	;branch if less than
	move.w	#$1E,d0	;move 1E into d0
.checkbody
	move.w	0(a0,d0.w),(ChkBodyG).w
	movea.l	#.cbgsq,a0
	clr.l	(ChkBodySqG).w
	move.w	0(a0,d0.w),(ChkBodySqG+2).w
	move.w	(ChkBodyG).w,(NegChkBodyG).w
	neg.w	(NegChkBodyG).w
	btst	#1,(sflags6).w	;check if one timer
	beq.w	.2	;branch if not set
	move.w	#$C,(ChkBodyG).w
	move.l	#$90,(ChkBodySqG).w
	move.w	#$FFF4,(NegChkBodyG).w
.2
	cmpi.w	#$250,SPA(a2)	;check animation (pad stack)
	beq.w	.3	;branch if equal
	cmpi.w	#$2A2,SPA(a2)	;check animation (pad stack)
	bne.w	.4	;branch if not equal
.3
	move.w	#$12,(ChkBodyG).w
	move.l	#$144,(ChkBodySqG).w
	move.w	#$FFEE,(NegChkBodyG).w
.4
	movea.l	(sp)+,a0	;pop stack into a0
	cmpi.w	#$F,(puckz).w	;compare F to puckz
	bgt.w	.exit2	;exit if higher
	move.w	(a2),d0	;Xpos into d0
	cmpi.w	#$250,SPA(a2)	;compare animation (pad stack)
	beq.w	.neg	;branch if equal
	cmpi.w	#$2A2,SPA(a2)	;compare animation (pad stack)
	bne.w	.8	;branch if not equal
	move.w	#6,d1	;move 6 into d1
	bra.w	.5
.neg
	move.w	#$FFFA,d1	;move -6 into d1
.5
	btst	#7,pflags(a2)	;check which goal shooting at
	bne.w	.6	;branch if top
	neg.w	d1	;negate d1
.6
	btst	#0,handed(a2)	;check bit zero of handedness
	beq.w	.7	;branch if equal
	neg.w	d1	;negate d1
.7
	add.w	d1,d0	;add d1 to d0
.8
	sub.w	(a3),d0	;sub Xpos a3 from d0
	cmp.w	(ChkBodyG).w,d0	;compare to d0
	bgt.w	.exit2	;exit if greater than
	cmp.w	(NegChkBodyG).w,d0	;compare to d0
	blt.w	.exit2	;exit if less than
	move.w	Ypos(a2),d1	;move Ypos into d1
	sub.w	Ypos(a3),d1	;sub Ypos a3 from d1
	cmp.w	(ChkBodyG).w,d1	;compare to d1
	bgt.w	.exit2	;exit if greater
	cmp.w	(NegChkBodyG).w,d1	;compare to d1
	blt.w	.exit2	;exit if less than
	movem.w	d0-d1,-(sp)	;push to stack
	muls.w	d0,d0	;square d0
	muls.w	d1,d1	;square d1
	add.l	d1,d0	;add d1 to d0
	cmp.l	(ChkBodySqG).w,d0	;compare to d0
	movem.w	(sp)+,d0-d1	;pop from stack
	bhi.w	.exit2	;exit if higher
	bsr.w	puckgoalie
	bra.w	.exit
.exit2
	bclr	#2,(sflags4).w	;clear bit 2
	beq.w	.exit	;exit if it was cleared already
	move.w	(puckc).w,d0	;move puckc into d0
	cmp.w	SCnum(a2),d0	;compare SCnum to d0
	beq.w	.exit	;branch if equal
	move.w	#SFXshotwiff,-(sp)	;sound
	bsr.w	sfx
	bra.w	.exit
;	puckstick, puckglue, puckbody, rtss2 (the shared rts), puckgoalie,
;	deflect, makepde, getpde, setpde, setpersonel, SetPlList,
;	TryAddPlayerToList, SetupPenaltyShot, forcepldata, ResetBench, Setplass,
;	setplayer and ClampNibble.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	Sort struct (SortCords, $80 each): 0 Xpos, 4 attribute, 6 frame, $14 Ypos, $18 Zpos, $28 Xvel, $2A Yvel, $2C Zvel,
;	$34 position, $46 temp4, $48 temp5, $52 SCnum, $54 facedir, $58 SPA, $5A, $5E nopuck (byte), $60 newpos, $61 newpnum,
;	$62 pflags, $63 pflags2, $64 bit 3 one-timer, $66 pnum, then the attributes setplayer writes: $67 Wgt, $68 Agl,
;	$69 Spd, $6A OfA, $6B DfA, $6C ShP, $6D ShA, $6E Pas, $6F jersey, $70 PS bias, $71 Stk, $72 End, $73 Agr, $74 Fgt,
;	$75 Chk, $76 handed.
;	94 team struct from HmShots (tmsize $364): $E faceoffs won, $14 passes completed, $16 tmline, $1A / $1C assists, $1E
;	tmdata, $22 tmsort, $24 tmap, $26 tmgoalie, $30 tmflags, $32 tmpde, $66 tmpdst (-4 / -3 injured, -2 bench, -1 ice,
;	>0 penalty box), $16A line sets.

puckstick	;puck collides with stick. a2 = player who collided, a3 = puck, d0 = distance^2 (from checkpuckcoll .ccx). A stick check on the puck
	;carrier can steal the puck (Stk rolls, smaller ranges when the carrier is in the slot, sflags6 bit 5), else a slow enough puck is caught
	;(puckglue); a one-timer shoots it (onetimershot). 94 adds the slot ranges and the one-timer path
	tst.w	position(a2)	;a2 = player who collided
	;a3 = puck
	bne.w	.0	;branch if not goalie
	btst	#gmhl,(gmode).w	;check if highlight
	bne.w	rtss2	;exit if so (goalie always lets the shot in)
.0
	bclr	#pfdoff,pflags(a2)	;clear offside bit
	move.w	(puckc).w,d1	;move puckc into d1
	bmi.w	.nosteal	;branch if no puck carrier
	asl.w	#7,d1
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d1,a0	;a0 = Struct of puck carrier
	move.b	pflags(a0),d1
	move.b	pflags(a2),d2
	eor.w	d1,d2	;compare pflags of each player
	btst	#pfteam,d2	;check if on same team
	beq.w	rtss2	;no stealing from teammate
	btst	#5,(sflags6).w	;check if puckc is in slot
	beq.w	.noslot	;branch if not
	cmp.l	#$40,d0
	bhi.w	rtss2
	bra.w	.1
.noslot
	cmp.l	#$24,d0
	bhi.w	rtss2
.1
	tst.w	position(a2)	;check if colliding player is goalie
	beq.w	.steal	;branch if goalie
	tst.w	position(a0)	;check if goalie
	beq.w	rtss2	;no stealing from goalie
.CheckStkForContactWithSkater	;(no xref; a label inside puckstick). Stk for puckc
	;Stk for puckc
	move.b	stickhand(a0),d0
	lsr.b	#1,d0	;divide by 2
	bsr.w	makepde	;adjust for energy level
	move.w	d0,-(sp)	;push onto stack
	exg	a0,a2	;swap a2 and a0 (a0 now collider)
	move.b	stickhand(a0),d0	;Stk for collider
	lsr.b	#1,d0	;divie by 2
	bsr.w	makepde	;adjust for energy
	exg	a0,a2	;swap back (a0 now puckc)
	neg.w	d0	;negate d0
	add.w	(sp)+,d0	;add puckc modified Stk
	addi.w	#$24,d0	;add 24 hex (36 decimal)
	bsr.w	randomd0	;RNG
	btst	#5,(sflags6).w	;check if puckc is in slot
	beq.w	.2	;branch if not
	cmp.w	#4,d0	;compare 4 to d0
	bhi.w	rtss2	;exit if higher (not losing puck)
	bra.w	.steal
.2
	cmp.w	#2,d0	;compare 2 to d0
	bhi.w	rtss2	;exit if higher (not losing puck)
.steal
	move.b	$71(a0),d0	;Stk of puckc
	lsr.b	#1,d0	;divide by 2
	bsr.w	makepde	;adj for energy
	addi.w	#$14,d0	;add 14 hex (20 dec)
	move.b	d0,nopuck(a0)	;move result into nopuck (cant get puck timer)
	exg	a0,a2	;swap a0 and a2 (a0 now collider)
	move.b	stickhand(a0),d0	;Stk of collider
	lsr.b	#1,d0	;divide by 2
	bsr.w	makepde	;adj for energy
	addi.w	#$14,d0	;add 14 hex (20 dec)
	move.b	d0,nopuck(a0)	;move result into nopuck
	exg	a0,a2	;swap back
	move.w	SCnum(a0),(lastplayer).w	;SCNum of puckc into lastplayer
	bclr	#sfspdir,(sflags).w	;clear pass dir mode
	bclr	#sfssdir,(sflags).w	;clear shot dir mode
.stdef
	move.w	#SFXstdef,-(sp)	;#SFXstdef
	bsr.w	sfx
	bsr.w	a2touchpuck	;deflect
	bra.w	deflect
.nosteal
	tst.w	position(a2)	;check if goalie
	bne.w	.onetimerchk	;branch if not
	cmp.l	#$40,d0
	bhi.w	rtss2	;smaller range for stealing puck
.onetimerchk
	btst	#pf3onetimer,pflags3(a2)	;check if onetimer
	beq.w	.nosteal2	;branch if not
	cmp.l	#$64,d0
	bhi.w	.3
	cmpi.w	#$18,SPAnum(a2)
	bge.w	.nosteal2
	move.w	#$18,SPAnum(a2)
	bset	#7,(sflags8).w
.nosteal2
	move.w	(puckvx).w,d0
	move.w	(puckvy).w,d1
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	clr.w	d1
	btst	#4,(sflags2).w	;check if shot was taken
	bne.w	.nohand	;branch if so
	btst	#pf3onetimer,pflags3(a2)	;check if one timer
	bne.w	.onetimer	;branch if so
.PlayerPassOrLoosePuckStkLoad	;(no xref; a label inside puckstick)
	move.b	stickhand(a2),d1
	mulu.w	#$15E,d1
.nohand
	addi.w	#$32C8,d1
	mulu.w	d1,d1
	cmp.l	d1,d0
	bls.w	puckglue
	move.b	#8,nopuck(a2)
	bra.w	.stdef
.onetimer
	exg	a2,a3
	jsr	(onetimershot).l
	exg	a2,a3
	rts
.3
	cmp.l	#$144,d0
	bhi.w	.ex2
	cmpi.w	#$18,SPAnum(a2)
	bge.w	.ex2
	move.w	#$18,SPAnum(a2)
.ex2
	rts
puckglue	;part of puckstick that puckgoalie also branches to. Player a2 takes the puck: faceoff
	;and pass stats, crowd song, goalie hold time (temp5), then .setd0player
	move.w	#7,-(sp)	;SFXpuckget
	move.w	SCnum(a2),d0	;move SCnum into d0
	move.w	d0,(puckc).w	;move d0 into puckc
	movea.w	#(tmstruct-M68K_RAM),a0	;Move Home Stats struct into a0
	lea	tmsize(a0),a1	;tmsize
	btst	#pfteam,pflags(a2)	;check if player is home or away
	bne.w	.tm	;branch if away
	exg	a0,a1	;swap struct addresses
.tm
	st	$1A(a0)	;FF into assist 1
	st	$1C(a0)	;FF into assist 2
	bset	#3,tmflags(a0)	;set a flag (not sure what)
	bclr	#4,(sflags3).w	;clear flag (not sure what, might have to do with faceoff)
	beq.w	.snd	;branch if it was cleared already
	addq.w	#1,$E(a1)	;add 1 to faceoff won
	addi.w	#$C8,(crowdlevel).w	;add to crowdlevel
	move.w	#$C,(sp)	;move C to stack
	cmpa.w	#(tmstruct-M68K_RAM),a1	;compare if a1 is home
	bne.w	.snd	;branch if not
	addi.w	#$A,(CwdExciteLvl).w	;add to CwdExciteLvl
	move.w	#$B,(sp)	;Move B into stack
.snd
	bsr.w	song
	move.w	SCnum(a2),d0	;move SCnum into d0
	cmp.w	(passplayer).w,d0	;compare to d0
	bne.w	.nrec	;branch if not equal
	addq.w	#1,$14(a1)	;add 1 to pass completed
.nrec
	st	(passplayer).w	;set to FFFF
	bclr	#sfspdir,(sflags).w	;clear pass dir mode
	bclr	#sfssdir,(sflags).w	;clear shot dir mode
	tst.w	position(a2)	;check if a2 is goalie
	bne.w	.setd0player	;branch if not
	bsr.w	ChkShotStat
	move.w	#$8C,temp5(a2)	;move 8C to temp5 - countdown for faceoff?
	cmpi.w	#$2F4,SPA(a2)	;SPAgdive. check for goalie dive animation
	bne.w	.setd0player	;branch if not equal
	move.w	#5,temp5(a2)	;set temp5 to 5
.setd0player	;Give control of player d0 to a controller if his team is controlled. 94 checks the pads 3 and 4 too (cont3team / cont4team)
	cmp.w	(c1playernum).w,d0
	beq.w	rtss2	;exit if player controlled
	cmp.w	(c2playernum).w,d0
	beq.w	rtss2	;exit if player controlled
	tst.w	(cont3team).w
	beq.w	.cont4chk	;branch if 0
	cmp.w	(c3playernum).w,d0
	beq.w	rtss2	;exit if player controlled
.cont4chk
	tst.w	(cont4team).w
	beq.w	.0	;branch if 0
	cmp.w	(c4playernum).w,d0
	beq.w	rtss2	;exit if player controlled
.0
	tst.w	(cont3team).w
	bne.w	.1	;branch if no team
	tst.w	(cont4team).w
	beq.w	.setd0player2	;branch if no team
.1
	movem.l	d0/a3,-(sp)
	asl.w	#7,d0
	movea.l	#SortCords,a3
	tst.w	$34(a3,d0.w)	;check if goalie
	bne.w	.2	;branch if not
	btst	#3,$62(a3,d0.w)	;check if d0 player controlled
	beq.w	.2	;branch if not
	movem.l	(sp)+,d0/a3	;exit if player controlled
	rts
.2
	movem.l	(sp)+,d0/a3
.setd0player2
	cmp.w	#6,d0
	slt	d1
	ext.w	d1
	addq.w	#2,d1
	move.w	(lastplayer).w,d2
	cmp.w	(c2playernum).w,d2
	beq.w	.3
	cmp.w	(cont1team).w,d1
	bne.w	.3
	jmp	setc1player
.3
	cmp.w	(cont2team).w,d1
	bne.w	.4
	jmp	setc2player
.4
	cmp.w	(cont1team).w,d1
	bne.w	rtss2
	jmp	setc1player
puckbody	;puck hits player a2. a3 = puck, d0 = distance^2 (from checkpuckcoll .ccx). The puck bounces off. A high puck (Zpos > 8) that is fast
	;makes a2 fall (FallDown, Zpos > $C); a slower one starts SPAcatch ($10D0) on a2
	btst	#pf3onetimer,pflags3(a2)
	bne.w	rtss2
	cmpi.w	#8,Zpos(a3)
	bgt.w	.hit
	move.w	d0,d1
	andi.w	#$F,d1
	bne.w	rtss2
.hit
	bsr.w	a2touchpuck
	move.w	#SFXpuckbody,-(sp)	;SFXpuckbody
	bsr.w	sfx
	clr.w	Zvel(a3)
	move.b	#8,nopuck(a2)
	move.w	(a3),d0
	sub.w	(a2),d0
	move.w	Ypos(a3),d1
	sub.w	Ypos(a2),d1
	bne.w	.0
	move.l	a2,-(sp)
	bsr.w	GetHot
.0
	move.w	Xvel(a3),d2
	move.w	Yvel(a3),d3
	move.b	d0,Xvel(a3)
	move.b	d1,Yvel(a3)
	bsr.w	puckflip
	cmpi.w	#8,Zpos(a3)
	ble.w	rtss2
	muls.w	d2,d2
	muls.w	d3,d3
	add.l	d3,d2
	cmp.l	#$9000000,d2	;fast puck
	bls.w	.1
	cmpi.w	#$C,Zpos(a3)
	bgt.w	FallDown
	rts
.1
	bset	#pfalock,pflags(a2)
	bne.w	rtss2
	move.w	#$10D0,d1	;SPAcatch
	exg	a2,a3
	bsr.w	SetSPA
	exg	a2,a3
rtss2	;shared rts, branched to from many segments
	rts
puckgoalie	;puck hits goalie a2. a3 = puck, d0/d1 = goalie - puck x/y. The save odds come from the goalie's glove / stick attributes (.list) and
	;the frame tables .list2 (older goalie frames) and .list3 (frames from $292); a save bounces the puck off (.bounceoff), a slow puck near the
	;crease is held (puckglue)
	btst	#gmhl,(gmode).w	;check if highlight
	bne.s	rtss2	;exit if highlight
	clr.w	d2	;puck region
	cmpi.w	#8,Zpos(a3)	;compare to Zpos
	bgt.w	.1
	addq.w	#2,d2	;add 2 to d2
.1
	neg.w	d0	;negate d0
	neg.w	d1	;negate d1
	bsr.w	vtoa	;convert directions
	sub.w	facedir(a2),d0	;sub facedir into d0
	andi.w	#7,d0	;pass first 3 bits to d0
	;0 = puck straight in front of G
	;1-3 = puck to G right
	;4 = puck straight behind G
	;5-7 = puck to G left
	move.w	d0,d1	;move d0 into d1
	andi.w	#3,d1	;pass first 2 bits of d1
	bne.w	.2	;will branch if puck is to the left or right of G
	move.w	(VDP_CNTR).l,d0	;just for random bit
.2
	andi.w	#4,d0	;pass 3rd bit of d0. d0 will be either 4 (left) or 0 (right)
	lsr.w	#2,d0	;divide by 4. d0 will be either 1 (left) or 0 (right)
	eori.w	#1,d0	;XOR d0 - will make 1 a 0 (left), and 0 a 1 (right)
	add.w	d0,d2	;add to d2. d2 will now be 0 or 1 (Zpos > 8) or 2 or 3 (Zpos <= 8)
	add.w	d2,d2	;add d2 to itself. 0 Glove L, 2 Glove R, 4 Stick L, 6 Stick R
	lea	.list(pc),a0	;contains offsets for save attributes
	move.w	0(a0,d2.w),d0	;move from list into d0
	moveq	#$F,d1	;move F into d1
	add.b	0(a2,d0.w),d1	;save odds = save attribute + F (15 dec)
	lea	.list2(pc),a0
	btst	#3,attribute(a2)	;attribute a2 - x flip?
	beq.w	.3
	eori.w	#2,d2	;XOR d2 with 2
.3
	move.w	frame(a2),d0	;move frame into d0
	move.w	#$197,-(sp)	;SPFgoalie
	cmp.w	#$233,d0	;compare 233 hex to d0 (goal light frame, all frames before are goalie frames)
	blt.w	.32	;branch if less than (old goalie frame)
	move.w	#$292,(sp)	;the goalie frames added in 94
	lea	.list3(pc),a0
.32
	sub.w	(sp)+,d0	;sub stack value (SPFgoalie) from d0
	move.b	0(a0,d0.w),d0	;move value from list2 or list3 at offset to d0
	lsr.w	d2,d0	;shift d0 by d2
	andi.w	#3,d0	;pass first 2 bits of d0
	bclr	#2,(sflags4).w	;clear bit 2 - this is not used anywhere, might have been a debug flag
	bsr.w	ChkShotStat
	bsr.w	a2touchpuck
	cmpi.w	#$3000,(puckvy).w	;compare with puck velocity y
	bgt.w	.setsfx	;branch if greater
	cmpi.w	#$D000,(puckvy).w	;compare -3000 with puckvy
	bgt.w	.nosong	;branch if greater
.setsfx
	move.w	#$B,-(sp)	;home song
	btst	#pfteam,pflags(a2)	;check home or away
	beq.w	.song	;branch if home
	move.w	#$D,(sp)	;away song
.song
	bsr.w	song
.nosong
	move.w	#SFXpuckbody,-(sp)	;#SFXpuckbody
	bsr.w	sfx
	move.w	(puckc).w,d2	;move puckc into d2
	bmi.w	.chkanim	;branch if no puckc
	st	(puckc).w
	asl.w	#7,d2
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d2,a0
	move.b	#$14,nopuck(a0)
	move.w	SCnum(a0),(lastplayer).w
	bclr	#sfspdir,(sflags).w
	bclr	#sfssdir,(sflags).w
.bounceoff
	clr.w	Zvel(a3)	;clear puck Zvel
	move.b	#$A,nopuck(a2)	;move A into nopuck collision
	move.w	#4,temp4(a2)	;move 4 into temp4
	move.w	(a3),d0	;move puck Xpos into d0
	sub.w	(a2),d0	;sub Xpos of goalie from d0
	move.w	Ypos(a3),d1	;move puck Ypos into d1
	sub.w	Ypos(a2),d1	;sub Ypos of goalie from d1
	bne.w	.0	;branch if not equal
	move.l	a2,-(sp)	;pop onto stack
	bsr.w	GetHot
.0
	move.b	d0,Xvel(a3)	;move d0 into puck Xvel
	move.b	d1,Yvel(a3)	;move d1 into puck Yvel
	bra.w	puckflip	;flip puck
	bset	#2,(sflags4).w	;not reached (after bra.w puckflip)
	rts
.chkanim
	cmpi.w	#$2F4,SPA(a2)	;SPAgdive. check for goalie dive animation
	beq.s	.bounceoff	;branch if equal
	moveq	#2,d0	;move 2 into d0
	add.b	shotspd(a2),d0	;add puck control to d0
	asl.w	#8,d0	;mult by 256
	asl.w	#1,d0	;mult by 2
	bsr.w	randomd0	;random
	addi.w	#$C00,d0	;add C00 to d0
	add.w	d0,d0	;double d0
	bpl.w	.pos	;branch if positive
	move.w	#$7FFF,d0	;make max positive
.pos
	btst	#1,pflags2(a2)	;check if in animation
	bne.w	.chkpuckv	;branch if so
	cmpi.w	#$2C,(a3)	;compare 2C to Xpos of puck
	bgt.w	.chkpuckv	;branch if greater than
	cmpi.w	#$FFD4,(a3)
	blt.w	.chkpuckv	;branch if less than -2C
	cmpi.w	#$10E,Ypos(a3)	;compare 10E to puck Ypos
	bgt.w	.chkpuckv	;branch if greater than
	cmpi.w	#$FEF2,Ypos(a3)	;compare to -10E
	blt.w	.chkpuckv	;branch if less than
	cmpi.w	#$D2,Ypos(a3)	;compare D2 to Ypos
	bgt.w	.closepuck	;branch if greater than
	cmpi.w	#$FF2E,Ypos(a3)	;compare -D2 to Ypos
	bgt.w	.chkpuckv	;branch if greater than
.closepuck
	asr.w	#2,d0	;divide by 4
.chkpuckv
	cmp.w	(puckvx).w,d0	;compare puckvx with d0
	blt.w	.bounceoff	;branch if less than
	cmp.w	(puckvy).w,d0	;compare puckvy to d0
	blt.w	.bounceoff	;branch if less than
	neg.w	d0	;negate d0, compare if shot going down
	cmp.w	(puckvx).w,d0
	bgt.w	.bounceoff	;branch if greater than
	cmp.w	(puckvy).w,d0
	bgt.w	.bounceoff	;branch if greater than
	btst	#2,pflags2(a2)	;check if player unavailable
	bne.w	.bounceoff	;branch if so
	clr.w	Zvel(a3)	;clear puck Zvel
	bra.w	puckglue
.list	dc.w	$73	;Save attribute offsets: GGSleft
	;GGSleft
	dc.w	$6E	;GGSright
	dc.w	$70	;GSSleft
	dc.w	$72	;GSSright
.list2	dc.b	$55	;2 bit save odds per quadrant, one byte per goalie frame from SPFgoalie
	;odds for stopping puck in each quadrant for each possible goalie frame
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$55	;U
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$55	;U
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$55	;U
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$55	;U
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$55	;U
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$55	;U
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$55	;U
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0
	dc.b	$55	;U
	dc.b	$F0,$D5
	dc.b	$75	;u
	dc.b	$D5
	dc.b	$75	;u
	dc.b	$D5
	dc.b	$75	;u
	dc.b	$D5
	dc.b	$75	;u
	dc.b	$D5
	dc.b	$75	;u
	dc.b	$D5
	dc.b	$75	;u
	dc.b	$D5
	dc.b	$75	;u
	dc.b	$D5
	dc.b	$75	;u
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$55	;U
	dc.b	$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0
	dc.b	$57	;W
	dc.b	$57	;W
	dc.b	$57	;W
	dc.b	$57	;W
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
	dc.b	$A5,$A5,$A5,$A5,$A5,$A5,$A5,$A5
.list3	dc.b	$9D	;The same for the 94 goalie frames from $292
	dc.b	$67	;g
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$9D
	dc.b	$67	;g
	dc.b	$D5,$D5
	dc.b	$75	;u
	dc.b	$75	;u
	dc.b	$D5,$D5
	dc.b	$75	;u
	dc.b	$75	;u
	dc.b	$D5,$D5
	dc.b	$75	;u
	dc.b	$75	;u
	dc.b	$D5,$D5
	dc.b	$75	;u
	dc.b	$75	;u
	dc.b	$D5,$D5
	dc.b	$75	;u
	dc.b	$75	;u
	dc.b	$D5,$D5
	dc.b	$75	;u
	dc.b	$75	;u
	dc.b	$D5,$D5
	dc.b	$75	;u
	dc.b	$75	;u
	dc.b	$D5,$D5
	dc.b	$75	;u
	dc.b	$75	;u
deflect	;random puck direction on deflection, puck = a3. Entered from puckstick
	st	(puckc).w
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Yvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0s
	move.w	d0,Xvel(a3)
	move.w	#$1000,d0
	bsr.w	randomd0
	move.w	d0,Zvel(a3)
	bra.w	puckflip
makepde	;pass d0 as value to be scaled by player a0's energy level (94: full energy while sflags7 bit 4 is set). Return d0 as result
	ext.w	d0
	move.w	d0,-(sp)
	movem.l	d1/a2-a3,-(sp)
	movea.l	a0,a3
	bsr.w	getpde
	btst	#4,(sflags7).w
	beq.w	.0
	move.w	#$1000,d0
.0
	movem.l	(sp)+,d1/a2-a3
	muls.w	(sp)+,d0
	asl.l	#4,d0
	swap	d0
	ext.l	d0
	rts
getpde	;get player a3's energy level into d0. Return a2 = his team struct, d1 = pnum*2
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#pfteam,pflags(a3)	;#pfteam - home or away
	beq.w	.0
	adda.w	#tmsize,a2	;team is away
.0
	move.b	pnum(a3),d1	;pnum
	ext.w	d1
	add.w	d1,d1
	move.w	tmpde(a2,d1.w),d0
	rts
setpde	;d1 = rostnum of player * 2, a2 = team struct, d0 = new energy level (0 if negative)
	tst.w	d0
	bpl.w	.0
	clr.w	d0
.0
	move.w	d0,tmpde(a2,d1.w)
	rts
setpersonel	;This will set personnel on team a2 according to team a2's registers: PlList gives the players
	;wanted on the ice; each sort obj gets newpos / newpnum
	movem.l	d0-d5/a0-a4,-(sp)
	movea.w	tmsort(a2),a3	;#tmsort
	moveq	#5,d4	;# of players on team for loop
.10
	st	newpos(a3)	;set newpos (FF)
	st	newpnum(a3)	;set newpnum
	adda.w	#SCstruct,a3	;add size of player struct to a3
	dbf	d4,.10	;loop through each player on team
	bsr.w	SetPlList
	moveq	#5,d4
	movea.w	#(PlList-M68K_RAM),a4	;list of players we want on ice
.1
	clr.w	d5
	move.b	0(a4,d4.w),d5
	beq.w	.next
	subq.w	#1,d5
	moveq	#5,d3
	movea.w	tmsort(a2),a3	;#tmsort into a3
	suba.w	#SCstruct,a3	;sub player struct size from a3
.2
	adda.w	#SCstruct,a3	;add player struct size to a3
	cmp.b	pnum(a3),d5	;compare pnum to d5
	dbeq	d3,.2	;loop through player structs while pnum != d5 (find player d5)
	bne.w	.next	;branches if player not found
	move.b	6(a4,d4.w),newpos(a3)	;move a4+d4+6 into newpos
	move.b	d5,newpnum(a3)	;move d5 into newpnum
	clr.b	0(a4,d4.w)	;clear a4+d4
.next
	dbf	d4,.1
	moveq	#5,d4
	movea.w	#(PlList-M68K_RAM),a4
.3
	clr.w	d5
	move.b	0(a4,d4.w),d5
	beq.w	.next2
	subq.w	#1,d5
	moveq	#5,d3
	movea.w	tmsort(a2),a3
	suba.w	#SCstruct,a3
.4
	adda.w	#SCstruct,a3
	tst.b	newpnum(a3)
	dbmi	d3,.4
	bpl.w	.0
	movea.w	a3,a0
.0
	tst.w	position(a3)
	dbpl	d3,.4
	move.b	6(a4,d4.w),newpos(a0)
	move.b	d5,newpnum(a0)
	clr.b	0(a4,d4.w)
.next2
	dbf	d4,.3
	movem.l	(sp)+,d0-d5/a0-a4
	rts
SetPlList	;create PlList of players who we want on the ice now. a2 = team struct. Takes the current line (tmline) by priolist; an unavailable
	;player (in the box or injured, -3 / -4) is replaced from sublist, or from the whole roster
	movea.w	#(PlList-M68K_RAM),a4
	clr.l	(a4)	;clear 6 bytes (PlList)
	clr.w	4(a4)
	movea.l	#priolist,a0	;priority of positions
	tst.w	tmgoalie(a2)	;test tmgoalie
	bpl.w	.gin	;branch if theres a goalie
	addq.w	#1,a0	;add 1 to a0
.gin
	lea	$16A(a2),a1	;moves address of team lines list into a1
	move.w	tmline(a2),d0	;current line selected
	asl.w	#3,d0	;mult by 8
	adda.w	d0,a1	;add to a1 to set a1 to currently selected line
	move.w	tmap(a2),d4	;tmap - active players (4-6 in normal ROM)
	bra.w	.next
.0
	clr.w	d5
	move.b	0(a0,d4.w),d5	;move position into d5
	move.b	0(a1,d5.w),0(a4,d4.w)
	move.b	d5,6(a4,d4.w)
	bne.w	.next
	moveq	#1,d3
	add.w	tmgoalie(a2),d3
	move.b	d3,0(a4,d4.w)
.next
	dbf	d4,.0
	moveq	#5,d4	;now check to see if player is available
.1
	move.b	0(a4,d4.w),d3
	beq.w	.next1
	ext.w	d3
	subq.w	#1,d3
	add.w	d3,d3
	cmpi.w	#$FFFD,tmpdst(a2,d3.w)	;check if player injured for period
	beq.w	.unavail
	cmpi.w	#$FFFC,$66(a2,d3.w)	;check if player injured for game
	beq.w	.unavail
	tst.w	tmpdst(a2,d3.w)
	ble.w	.next1	;player is ok
.unavail
	lea	$16A(a2),a1	;now find a player of similar position who is available
	;move Line Lists again into d0
	move.b	6(a4,d4.w),d0	;move 6+a4+d4 into d0 (previous d5)
	ext.w	d0	;extend d0
	asl.w	#1,d0	;mult by 2
	movea.l	#sublist,a0	;move sublist into a0
	adda.w	0(a0,d0.w),a0	;move a0+d0 into a0
.s1
	clr.w	d0
	move.b	(a0)+,d0
	bmi.w	.error
	move.b	0(a1,d0.w),d0
	bsr.w	TryAddPlayerToList
	beq.s	.s1
.next1
	dbf	d4,.1
	rts
.error
	jsr	(GetPlayerCount).l	;then try the players from d0 down
	move.w	d0,d3
.try
	move.w	d3,d0
	subq.w	#1,d3
	bmi.s	.next1
	bsr.w	TryAddPlayerToList
	beq.s	.try
	bra.s	.next1
TryAddPlayerToList	;d0 = player number (1 based), d4 = PlList slot. Put d0 in the slot if he is on the bench or
	;ice (not in the box, not injured) and not in PlList yet; return d1 = 0 (Z set) if not
	move.w	d0,d1
	subq.w	#1,d0
	add.w	d0,d0
	tst.w	$66(a2,d0.w)
	bgt.w	.0
	cmpi.w	#$FFFD,$66(a2,d0.w)
	beq.w	.0
	cmpi.w	#$FFFC,$66(a2,d0.w)
	beq.w	.0
	moveq	#5,d0
.loop
	cmp.b	0(a4,d0.w),d1
	dbeq	d0,.loop
	beq.w	.0
	move.b	d1,0(a4,d4.w)
	rts
.0
	clr.w	d1
	rts
SetupPenaltyShot	;Penalty shot set up for team a2 (called from puckpenshot): the shooter (BA_Sktr_SCnum) plays center from BA_Skater_Offset
	;the goalie (BA_Goalie_SCnum) stays; every other player is made unavailable with assignment $20 (assgoaliebreakwait)
	movem.l	d0-d5/a0-a3,-(sp)
	movea.w	$22(a2),a3
	moveq	#5,d4
.loop
	move.w	SCnum(a3),d0
	cmp.w	(BA_Sktr_SCnum).w,d0
	beq.w	.0
	cmp.w	(BA_Goalie_SCnum).w,d0
	beq.w	.1
	bset	#2,pflags2(a3)	;set player unavailable
	move.w	#$20,d0	;assgoaliebreakwait
	bsr.w	assreplace
	bra.w	.3
.0
	bsr.w	Setplass
	move.b	newpnum(a3),(savednewpnum).w
	move.b	(BA_Skater_Offset+1).w,newpnum(a3)
	move.w	#4,position(a3)
	bra.w	.2
.1
	bsr.w	Setplass
	clr.w	position(a3)
.2
	clr.w	d3
	move.b	newpnum(a3),d3
	add.w	d3,d3
	move.w	#$FFFF,$66(a2,d3.w)
	lsr.w	#1,d3
	bsr.w	setplayer
.3
	st	newpnum(a3)
	st	$60(a3)
	adda.w	#$80,a3
	dbf	d4,.loop
	movem.l	(sp)+,d0-d5/a0-a3
	rts
forcepldata	;no skating on/off: force players to correct data (for faceoffs only). a2 = team struct
	movem.l	d0-d4/a0-a3,-(sp)
	movea.w	tmsort(a2),a3	;22 offset of team struct is tmsort (address of first sort obj)
	moveq	#5,d4	;will run the loop 6 times
.top
	move.b	newpos(a3),d0	;newpos = requested next pos of player
	ext.w	d0
	tst.w	position(a3)	;check for goalie
	bne.w	.0
	tst.w	d0	;is he staying as a goalie?
	beq.w	.0
	move.w	SCnum(a3),-(sp)	;push SCNum to stack
	move.w	#$F,SCnum(a3)	;put F into SCNum
	jsr	(Set4WayPlayerStub).l	;an rts
	move.w	(sp)+,SCnum(a3)	;pop original SCNum back into SCNum
.0
	move.w	d0,position(a3)	;move newpos(d0) into position
	bmi.w	.next
	bsr.w	Setplass
	cmpi.w	#4,position(a3)	;check if C
	bne.w	.notnear	;branch if not
	move.l	#$11,d0	;$11 = anearest
	bsr.w	assinsert
.notnear
	clr.w	d3
	move.b	newpnum(a3),d3	;move newpnum into d3
	add.w	d3,d3	;add d3 to itself
	move.w	#$FFFF,tmpdst(a2,d3.w)	;move -1 into tmpdst
	;put player on the ice
	lsr.w	#1,d3	;divide d3 by 2
	bsr.w	setplayer
.next
	st	newpnum(a3)	;set newpnum to FF
	st	newpos(a3)	;set newpos to FF
	adda.w	#SCstruct,a3	;move to next sortobj (player struct)
	dbf	d4,.top
	movem.l	(sp)+,d0-d4/a0-a3
	rts
ResetBench	;remove all players from penalty box / put all players on their own bench (not the injured, -3 / -4). Counts the players left in the
	;box in PBnum (home in the high nibble). .rb runs for the home team, then falls in for the visitors
	clr.b	(PBnum).w	;PBnum = HV00
	;H = home players in PB
	;V = away players in PB
	moveq	#$10,d1
	movea.w	#(tmstruct-M68K_RAM),a0
	bsr.w	.rb
	moveq	#1,d1
	adda.w	#tmsize,a0	;change to Away Team
.rb
	moveq	#$32,d0	;$32 = (MaxRos-1)*2 = 50 decimal
.rb1
	add.b	d1,(PBnum).w
	tst.w	tmpdst(a0,d0.w)	;check tmpdst
	;check and see which players are in the box
	;(-2=bench, -1=ice, 0+=pen box)
	;starts from end of list and works backwards through loop
	ble.w	.cont
	btst	#4,tmpdst(a0,d0.w)	;test 3rd bit in tmpdst (4 decimal)
	beq.w	.next
	move.w	tmpdst(a0,d0.w),d2	;move tmpdst into d2
	andi.w	#$7FF,d2	;mask 7FF with d2. Passes lowest 11 bits
	bne.w	.next
	sub.b	d1,(PBnum).w
	bra.w	.next
.cont
	sub.b	d1,(PBnum).w
	cmpi.w	#$FFFD,tmpdst(a0,d0.w)	;compare -4 with tmpdst
	beq.w	.next
	cmpi.w	#$FFFC,$66(a0,d0.w)	;compare -3 with tmpdst
	beq.w	.next
	move.w	#$FFFE,tmpdst(a0,d0.w)	;move -2 into tmpdst
.next
	subq.w	#2,d0
	bpl.s	.rb1
	rts
Setplass	;set players (a3) initial assignment from .alist by position
	move.w	position(a3),d0
	bmi.w	rtss2
	lea	.alist(pc),a0
	move.b	0(a0,d0.w),d0
	bra.w	assreplace
.alist	dc.b	$E	;assgoalie
	;assgoalie??
	dc.b	2	;assdefd
	dc.b	2	;assdefd
	dc.b	3	;asswingd
	dc.b	5	;asscenterd
	dc.b	3	;asswingd
	dc.b	5	;asscenterd
	dc.b	$FF
setplayer	;bring player onto the ice and set his attributes. d3 = offset of player on roster, a3 = sortcord of player. Reads the roster bytes
	;through AttributeCalc (attribute number in TempWord2). 94 adds the PP / PK, home / away and third period bonuses (team ScoreOdds bytes) to
	;some attributes and clamps them with ClampNibble
	bclr	#6,pflags2(a3)	;clear line change mode? (I believe pflags2 are 1 off because of fighting missing)
	movea.w	#(tmstruct-M68K_RAM),a0	;Start of Team Struct
	btst	#pfteam,pflags(a3)	;checks if home or away (if 0, home)
	beq.w	.0
.AwayTeam	;(no xref; a label inside setplayer)
	;$364 = size of Team Struct
	adda.w	#tmsize,a0
.0
	move.b	d3,pnum(a3)	;move d3 into pnum (offset on roster)
	move.l	#$A,d0	;$A = #aepen
	ext.w	d3
	add.w	d3,d3	;= asl #1,d3. Accomplishes the same. Doubles d3
	move.w	tmpdst(a0,d3.w),d1	;move tmpdst(a0, d3) into d1
	bpl.w	.da
	move.l	#9,d0	;assben
	cmp.w	#$FFFE,d1	;-2 in this case
	bne.w	.nda
.da
	bsr.w	assinsert
	bclr	#pfalock,pflags(a3)
	clr.w	SPA(a3)
.nda
	move.w	#$FFFF,tmpdst(a0,d3.w)	;clear out temp space
	lsr.w	#1,d3	;shift d3 back to its original value
	movea.l	tmdata(a0),a0	;Offset 1E from Team Struct = The address where the team's data is stored (roster, etc)
	move.l	a0,-(sp)	;pushes starting position onto the stack
	adda.w	8(a0),a0	;moves to offset where Off/Def byte is
	clr.l	(PPBonus).w	;Clears all bonuses
	tst.w	position(a3)	;check if goalie
	beq.w	.playdatamove
	btst	#5,(sflags2).w	;might be checking for a PP
	beq.w	.habonus
	bsr.w	chkpk2	;prob determines what team is PP or PK
	beq.w	.pk
	move.b	1(a0),(PPBonus).w	;moves PP/PK byte into PPBonus
	andi.b	#$F,(PPBonus).w	;passes lower nibble of PP/PK byte (bug)
	bra.w	.habonus
.pk
	move.b	1(a0),d0	;moves PP/PK byte into d0
	lsr.b	#4,d0	;shifts d0.b 4 places, to remove the lower nibble
	neg.b	d0	;switches value to negative (because its a PK, its negative bonus)
	move.b	d0,(PKBonus).w	;move d0 into PKBonus
.habonus
	move.b	2(a0),d0	;This is location of Home/Away adv
	andi.b	#$F,d0	;pass the lower nibble (Away) to d0
	neg.b	d0	;make d0 negative (away disadvantage)
	btst	#pfteam,pflags(a3)	;check if player is home or away
	bne.w	.3rdperbonuscheck
	move.b	2(a0),d0	;player is home, move Home/Away byte back in to d0
	lsr.b	#4,d0	;Shift d0 4 places right, to move upper nibble into d0
.3rdperbonuscheck
	move.b	d0,(HmAwBonus).w	;move d0 into HA bonus
	cmpi.w	#2,(gsp).w	;Check if period is 3rd or OT
	blt.w	.playdatamove
	bgt.w	.chklead	;branch if OT
	jsr	(GetPeriodTime).w	;Find period length
	lsr.w	#1,d0	;divide by 2 (5 min length = 2:30)
	cmp.w	(gameclock).w,d0	;compare to game clock
	bgt.w	.playdatamove	;branch if d0 greater than gameclock (bug)
.chklead
	move.w	(HmGoals).w,d0
	sub.w	(AwGoals).w,d0	;HmGoals-AwGoals
	beq.w	.load3pbonus	;branch if tied
	btst	#pfteam,pflags(a3)	;Check if home or away
	beq.w	.home	;branch if home
	eori	#8,ccr	;If Aw team, checks if N flag is set from HmGoals-AwGoals.
	;Xors the CCR, if N flag set, it will make it 0, if cleared, will make it 1.
	;If Aw team leading, it will jump boost for away team.
.home
	bpl.w	.playdatamove	;branch for the team who is leading
.load3pbonus
	move.b	#2,(ThirdPBonus).w	;move 2 into 3rd Per Bonus
.playdatamove
	movea.l	(sp)+,a0	;moves Team Data start to a0
	adda.w	(a0),a0	;moves to player data offset (byte 0 and 1 of Team Data)
.skiploop
	adda.w	(a0),a0	;skips the player's name length (current byte is name length)
	addq.w	#8,a0	;skips players attributes
	dbf	d3,.skiploop	;loops until current player index is met (which was stored in d3)
	subq.w	#8,a0	;Jump back to start of players attributes
	move.b	(a0),rostnum(a3)	;Jersey Number
	move.b	1(a0),d3	;move Wgt/Agl byte to d3
	andi.w	#$F0,d3	;Mask Wgt nibble
	lsr.w	#1,d3	;shift d3 1 bit right (This is taking Wgt and mult by 8)
	move.b	d3,weight(a3)	;store in player struct
	move.b	1(a0),d3	;move Wgt/Agl byte to d3
	andi.b	#$F,d3	;mask Agl nibble
	move.w	#3,(TempWord2).w	;move 3 into BF14
	jsr	(AttributeCalc).l	;attribute math and add hot/cold
	move.b	d3,legstr(a3)	;move Agl byte to player struct
	move.b	2(a0),d3	;load Spd/OfA byte to d3
	lsr.b	#4,d3	;remove OfA nibble by shifting 4 bits right, moving Spd into lower nibble
	move.w	#4,(TempWord2).w	;move 4 into BF14
	jsr	(AttributeCalc).l
	move.b	d3,legspd(a3)	;move Spd byte into player struct
	move.b	2(a0),d3	;move Spd/OfA byte to d3
	andi.b	#$F,d3	;mask d3 and pass only OfA nibble
	move.w	#5,(TempWord2).w	;move 5 into BF14
	jsr	(AttributeCalc).l
	add.b	(PPBonus).w,d3	;add Bonsuses to OfA
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	add.b	(ThirdPBonus).w,d3
	bsr.w	ClampNibble
	lsr.b	#1,d3	;shift right 1 bit (divide by 2)
	eori.b	#$F,d3	;XOR d3 with F
	addi.b	#$F,d3	;add F to d3
	lsr.b	#1,d3	;divide by 2
	move.b	d3,aioff(a3)	;OfA byte = (30-((OfA + Bonuses)/2))/2
	move.b	3(a0),d3	;move DfA/ShP byte to d3
	lsr.b	#4,d3	;see above
	move.w	#6,(TempWord2).w
	jsr	(AttributeCalc).l
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	lsr.b	#1,d3
	eori.b	#$F,d3
	addi.b	#$F,d3
	lsr.b	#1,d3
	move.b	d3,aidef(a3)	;same math and formula as OfA
	move.b	3(a0),shotspd(a3)
	andi.b	#$F,shotspd(a3)
	move.b	shotspd(a3),d3
	move.w	#7,(TempWord2).w
	jsr	(AttributeCalc).l
	move.b	d3,shotspd(a3)	;ShP does not get any bonuses
	move.b	4(a0),d3	;move Chk/Hnd byte into d3
	lsr.b	#4,d3
	move.w	#8,(TempWord2).w
	jsr	(AttributeCalc).l
	add.b	(ThirdPBonus).w,d3	;Chk gets 3rd P bonus only
	bsr.w	ClampNibble
	move.b	d3,checking(a3)	;move Chk into player struct
	bclr	#3,attribute(a3)	;clear bit 3 in attribute of player struct
	move.b	4(a0),handed(a3)	;move Chk/Hnd byte to Hnd in player struct
	andi.b	#1,handed(a3)	;masks Hnd byte with 1, only passing first bit
	eori.b	#1,handed(a3)	;XOR Hnd byte with 1. Sets to opposite what the bit was.
	;So L will be a 1 and R will be a 0
	bne.w	.attribloadcont
	bset	#3,attribute(a3)	;sets bit 3 of attribute byte in player struct (to match Hnd if Hnd bit is set)
.attribloadcont
	move.b	4(a0),fighting(a3)	;moves Chk/Hnd byte into Fgt byte in player struct
	andi.b	#$E,fighting(a3)	;mask the byte with E, ignoring the Hnd bit - will always be even
	move.b	5(a0),d3	;move Stk/ShA byte into d3
	lsr.b	#4,d3
	move.w	#$A,(TempWord2).w
	jsr	(AttributeCalc).l
	add.b	(PPBonus).w,d3
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,stickhand(a3)	;Stk gets PP/PK/Tm Bonus
	move.b	5(a0),d3
	andi.b	#$F,d3
	move.w	#$B,(TempWord2).w
	jsr	(AttributeCalc).l
	add.b	(PPBonus).w,d3
	add.b	(PKBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,shotacc(a3)	;ShA gets PP/PK/Tm Bonus
	move.b	6(a0),d3	;move End/PS Bias byte into d3
	lsr.b	#4,d3
	move.w	#$C,(TempWord2).w
	jsr	(AttributeCalc).l
	move.b	d3,endurance(a3)	;End gets no bonuses
	move.b	6(a0),d3
	andi.b	#$F,d3
	move.w	#$D,(TempWord2).w
	jsr	(AttributeCalc).l
	add.b	(ThirdPBonus).w,d3
	add.b	(ThirdPBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,spodds(a3)	;PS Bias gets a double 3rd P bonus
	move.b	7(a0),d3	;move Pas/Agr byte into d3
	lsr.b	#4,d3
	move.w	#$E,(TempWord2).w
	jsr	(AttributeCalc).l
	add.b	(PPBonus).w,d3
	add.b	(HmAwBonus).w,d3
	bsr.w	ClampNibble
	move.b	d3,passacc(a3)	;Pas gets PP and Tm bonus
	move.b	7(a0),aggress(a3)	;moves Pas/Agr into Agr byte in player struct
	move.b	aggress(a3),d3	;moves Pas/Agr byte into d3 (weird way to do it)
	andi.b	#$F,d3
	move.w	#$F,(TempWord2).w
	jsr	(AttributeCalc).l
	move.b	d3,aggress(a3)	;Agr gets no bonus
	andi.b	#$F,aggress(a3)	;mask Agr byte with F, so max is 15 decimal
	rts
ClampNibble	;Clamp byte d3 to 0-$1E (93 clamped to 0-15). Called by setplayer
	tst.b	d3	;test if d3 is zero or higher
	bpl.w	.pos
	clr.w	d3	;if negative, clear
.pos
	cmp.b	#$1E,d3	;compare upper limit
	ble.w	.withinlimits
	move.w	#$1E,d3	;if higher, set to 1E
.withinlimits
	rts
