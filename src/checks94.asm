;	Skater and goalie assignments: asswingo, asscenterd, asscentero, the
;	goalie code (assgoaliectrl, assgoaliecpu, ClampYPosition,
;	AdjustFacingDirection, goaliesave, assgoalietopuck), the breakaway code,
;	asspuckc, chk4lc, chkpk / chkpk2, chk4shot, CompShoot, chk4pass and
;	EvadePC.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp /
;	cmpi; fixopcodes.js patches the cmp encoding after assembly.
;	SortCords offsets: Xpos 0, attribute 4, Ypos $14, Xvel $28, Yvel $2A, position $34, assnum $36,
;	temp1 $40, SCnum $52, facedir $54, SPA $58, nopuck $5E, pflags $62, pflags2 $63.

asswingo	;player a3 is winger on offense
	btst	#pfalock,pflags(a3)	;check if locked in animation
	bne.w	rtss21	;exit if so
	btst	#gmclock,(gmode).w	;check game clock
	bne.w	donothing	;donothing if stopped
	bsr.w	check4bench	;check if player going to bench
	btst	#pfjoycon,pflags(a3)	;check if joystick controlled
	bne.w	rtss21	;exit if so
	bclr	#pfna,pflags(a3)	;clear new assignment bit
	beq.w	.nna	;branch if it was already cleared
	st	temp5(a3)	;set old zone # (temp5)
	clr.w	temp1(a3)	;clear temp1
	move.w	#8,temp2(a3)	;move 8 into temp2
.nna
	sub.b	d7,temp1(a3)	;subtract frames elapsed from temp1
	bpl.w	.nodec	;branch if positive
	move.b	aidef(a3),temp1(a3)	;move DfA into temp1
	btst	#6,(sflags7).w	;check if crowd meter currently broken
	beq.w	.noboost
	tst.b	temp1(a3)	;check if temp1 is 0
	beq.w	.noboost
	subq.b	#1,temp1(a3)	;subtract 1 from temp1
.noboost
	move.l	#3,d0	;move asswingd into d0
	move.w	(puckc).w,d1	;move puckc SCnum into d1
	bmi.w	.de0	;branch if no puckc
	subq.w	#6,d1	;sub 6 from d1
	move.w	SCnum(a3),d2	;move SCnum into d2
	subq.w	#6,d2	;sub 6 from d2
	eor.w	d2,d1	;EOR d2 with d1. Checks if puckc on same team
	bmi.w	assreplace	;if not, branch to assreplace
.de0
	move.w	(pucky).w,d0	;pucky into d0
	move.w	(puckvy).w,d3	;puckvy into d3
	asr.w	#6,d3	;divide d3 by 64
	add.w	d0,d3	;add d0 to d3
	btst	#pfgoal,pflags(a3)	;check which goal shooting on
	bne.w	.de1	;branch if top goal
	neg.w	d0	;negate d0
	neg.w	d3	;negate d3
.de1
	clr.w	d2	;clear zone number
	cmp.w	#$FFA8,d3	;compare bottom blue line with d3
	blt.w	.de2	;branch if in defensive zone
	addq.w	#8,d2	;add 8 to d2 (d2 = 8)
	cmp.w	#$58,d0	;'X'   ; compare top blue line with d0
	blt.w	.de2	;branch if in neutral zone
	btst	#4,tmflags(a2)	;check bit 4 of offset 30 (currently offside)
	;(C6FE Home, CA62 Away)
	bne.w	.de2	;branch if set
	addq.w	#8,d2	;add 8 to d2 (d2 = $10)
	cmp.w	#$108,d3	;compare top goal line with d3
	blt.w	.de2	;branch if in offensive zone
	addq.w	#8,d2	;add 8 to d2 (d2 = $18)
.de2
	cmp.w	temp5(a3),d2	;compare temp5 with d2
	bne.w	.de3	;branch if different zone
	move.w	(VDP_CNTR).l,d0	;move frame counter into d0
	andi.w	#$7F,d0	;pass first 7 bits
	bne.w	.nodec	;branch if not equal to 0 - this allows random movement in zone while waiting
.de3
	move.w	d2,temp5(a3)	;move d2 into temp5
	lea	.dedata(pc),a0	;move zonedata address into a0
	move.w	2(a0,d2.w),d0	;move X Coord into d0
	bsr.w	randomd0s	;RNG d0
	add.w	0(a0,d2.w),d0	;add X Coord offset to d0
	move.w	d0,temp3(a3)	;move d0 into temp3
	move.w	6(a0,d2.w),d0	;move Y Coord into d0
	bsr.w	randomd0s	;RNG d0
	add.w	4(a0,d2.w),d0	;add Y Coord offset into d0
	move.w	d0,temp4(a3)	;move d0 into temp4
	bra.w	.nodec
.dedata
	dc.w	$50	;Skating zones:
	;Defensive zone
	dc.w	$14
	dc.w	$FFBA
	dc.w	$A
	dc.w	$64	;neutral zone
	dc.w	$14
	dc.w	$3A
	dc.w	5
	dc.w	$3C	;offensive zone
	dc.w	$32
	dc.w	$E6
	dc.w	$14
	dc.w	$50	;past goalline
	dc.w	$1E
	dc.w	$FA
	dc.w	$14
.nodec
	move.w	temp3(a3),d0	;move temp3 into d0
	cmpi.w	#5,position(a3)	;compare 5 (RW) to position
	beq.w	.1	;branch if RW
	neg.w	d0	;negate d0
.1
	move.w	temp4(a3),d1	;move temp4 into d1
	btst	#7,pflags(a3)	;check if shooting up or down
	bne.w	.0	;branch if shooting up
	neg.w	d0	;negate d0
	neg.w	d1	;negate d1
.0
	lea	EvadePC(pc),a0	;add EvadePC as aux routine
	bra.w	skateto	;skate to d0/d1 position
rtss11
	rts
; player a3 is center on defense
; d7 = elapsed frames
asscenterd
	btst	#5,pflags(a3)	;pfalock - locked animation
	bne.s	rtss11	;exit if locked
	btst	#0,(gmode).w	;gmclock - check if clock is running
	bne.w	donothing	;exit if stoppage
	bsr.w	check4bench
	btst	#3,pflags(a3)	;pfjoycon - check if joystick controlled
	bne.s	rtss11	;exit if joystick controlled
	bclr	#1,pflags(a3)	;pfna - new assignment
	beq.w	.nna	;branch if no new assignment
	clr.w	temp1(a3)	;clear temp1
	move.w	#8,temp2(a3)	;move 8 into temp2
.nna
	sub.b	d7,temp1(a3)	;subtract d7 from temp1
	bpl.w	.nodec
	move.b	aidef(a3),temp1(a3)	;move aidef into temp1
	btst	#6,(sflags7).w	;check for crowd record flag
	beq.w	.puckcarrier	;jump if not set
	tst.b	temp1(a3)	;check if 0
	beq.w	.puckcarrier
	subq.b	#1,temp1(a3)	;subtract 1 from temp1
.puckcarrier
	move.w	(puckc).w,d1	;move puck carrier SCnum into d1
	bmi.w	.nodec
	move.l	#6,d0	;asscentero
	subq.w	#6,d1	;subtract 6 from d1
	move.w	SCnum(a3),d2	;move player's SCnum into d2
	subq.w	#6,d2	;subtract 6 from d2
	eor.w	d2,d1	;compare d2 and d1
	bpl.w	assreplace	;if team has puck, replace assignment with acentero
.nodec
	move.w	(puckx).w,d0	;Xpos of puck
	asr.w	#1,d0	;divide by 2
	move.w	(pucky).w,d2	;Ypos of puck
	btst	#7,pflags(a3)	;pfgoal - check which net to shoot on
	bne.w	.1	;branch if top net
	neg.w	d2	;negate d2 if shooting on bottom net
.1
	moveq	#$FFFFFF80,d1	;-128 - own high slot
	cmp.w	#$FFA8,d2	;-88 - own blue line
	blt.w	.chkgoal	;branch if puck in defensive zone
	add.w	(pucky).w,d1	;add pucky position to d1
	asr.w	#1,d1	;divide by 2
.chkgoal
	btst	#7,pflags(a3)	;pfgoal - check which net to shoot at
	bne.w	.z1	;branch if top net
	neg.w	d1	;shooting at bottom net
.z1
	lea	rtss11(pc),a0	;no extra collision routine
	bra.w	skateto	;d0/d1 - x/y coord for skating to
; player a3 is center on offense
asscentero
	btst	#5,pflags(a3)	;pfalock
	bne.w	rtss11	;exit if anim locked
	btst	#0,(gmode).w	;#gmclock
	bne.w	donothing	;do nothing
	bsr.w	check4bench
	btst	#3,pflags(a3)	;pfjoycon - check if joystick controlled
	bne.w	rtss11	;exit if controlled
	bclr	#1,pflags(a3)	;clear pfna
	beq.w	.nna
	st	temp5(a3)	;old zone number - temp5
	clr.w	temp1(a3)	;clear temp1
	move.w	#8,temp2(a3)	;move 8 into temp2
.nna
	sub.b	d7,temp1(a3)	;subtract d7 from temp1 (d7 = elapsed frames)
	bpl.w	.nodec	;branch if temp1 not zero or neg
	move.b	aidef(a3),temp1(a3)	;move aidef into temp1
	btst	#6,(sflags7).w	;check if crowd record broken
	beq.w	.noboost
	tst.b	temp1(a3)	;check if temp1 is 0
	beq.w	.noboost
	subq.b	#1,temp1(a3)	;sub 1 from temp1
.noboost
	move.w	(puckc).w,d1	;move puck carrier SCnum into d1
	bmi.w	.de0
	move.l	#5,d0	;asscenterd
	subq.w	#6,d1
	move.w	SCnum(a3),d2	;move SCnum into d2
	subq.w	#6,d2
	eor.w	d2,d1	;checks to see if puck carrier is on team
	bmi.w	assreplace	;if not switch to acenterd
.de0
	move.w	(pucky).w,d0	;pucky in d0
	btst	#7,pflags(a3)	;#pfgoal - check what goal shooting on
	bne.w	.de1	;branch if top
	neg.w	d0	;negate if bottom net
.de1
	clr.w	d2	;d2 = zone number
	cmp.w	#$FFA8,d0	;check if own blue line
	blt.w	.de2	;branch if in def zone
	addq.w	#8,d2	;set zone to 8
	cmp.w	#$58,d0	;'X'   ; check opponents blue line
	blt.w	.de2	;branch if in neutral zone
	btst	#4,tmflags(a2)	;Checks if currently offside
	;C6FE - Home
	;CA62 - Away
	bne.w	.de2	;branch if offside
	addq.w	#8,d2
	cmp.w	#$108,d0	;check opponents goal line
	blt.w	.de2	;branch if in offensive zone
	addq.w	#8,d2	;add if past goal line
.de2
	cmp.w	temp5(a3),d2	;compare temp5 to d2
	bne.w	.de3
	move.w	(VDP_CNTR).l,d0	;move frame counter into d0.
	;This allows a chance for random movement in zone when waiting
	andi.w	#$7F,d0	;pass bottom 7 bits
	bne.w	.nodec
.de3
	move.w	d2,temp5(a3)	;move zone into temp5
	lea	.dedata(pc),a0
	move.w	2(a0,d2.w),d0	;move zone into d0
	bsr.w	randomd0s	;randomize d0
	add.w	0(a0,d2.w),d0	;add to d0
	move.w	d0,temp3(a3)	;move into temp3 (X coord)
	move.w	6(a0,d2.w),d0	;move into d0
	bsr.w	randomd0s	;randomize d0
	add.w	4(a0,d2.w),d0	;add into d0
	move.w	d0,temp4(a3)	;move into temp4 (Y coord)
	bra.w	.nodec
.dedata
	dc.w	0	;Skating Zones
	;puck location = defensive zone
	dc.w	$3C
	dc.w	$FFBA
	dc.w	$A
	dc.w	0	;neutral zone
	dc.w	$3C
	dc.w	$3C
	dc.w	$A
	dc.w	0	;offensive zone
	dc.w	$28
	dc.w	$AA
	dc.w	$1E
	dc.w	0	;below offensive goal line
	dc.w	$50
	dc.w	$AA
	dc.w	$14
.nodec
	move.w	temp3(a3),d0	;move temp3 into d0 (x coord to skate to)
	move.w	temp4(a3),d1	;move temp4 into d1 (y coord to skate to)
	btst	#7,pflags(a3)	;pfgoal
	bne.w	.0	;branch if top
	neg.w	d1	;negate if bottom
.0
	lea	EvadePC(pc),a0
	bra.w	skateto
; joypad controlled goalie control
; a3 = goalie
assgoaliectrl
	btst	#3,pflags(a3)	;is player joystick controlled?
	bne.w	.goaliectrl	;branch is so
	bra.w	assexit
.goaliectrl
	btst	#1,pflags(a3)	;check if new assignment
	bne.w	.na	;branch if new assignment
	movem.w	d0-d1,-(sp)	;push to stack
	move.w	(a3),d0	;Xpos
	move.w	Ypos(a3),d1	;Ypos
	cmp.w	#$AA,d1	;compare $AA to Ypos
	bgt.w	.cont
	cmp.w	#$FF56,d1	;check -$AA to Ypos
	blt.w	.cont	;branch if less than
	btst	#0,(gmode).w	;check if clock stopped
	bne.w	.cont	;branch if so
	move.w	d0,-(sp)	;push to stack
	move.w	#8,d0	;clock stoppage due to goalie out of range
	jsr	(AddPenalty2).l
	move.w	(sp)+,d0	;pop from stack
.cont
	sub.w	(Hpos).w,d0	;sub ice rink horiz position from Xpos
	sub.w	(Vpos).w,d1	;sub ice rink vert position from Ypos
	bclr	#pf3gctrl,pflags3(a3)	;clear goalie control bit?
	cmp.w	#$74,d0	;'t'   ; compare $74 to Xpos diff
	blt.w	.0	;branch if less than
	bset	#pf3gctrl,pflags3(a3)	;set goalie control bit?
	bra.w	.cont2
.0
	cmp.w	#$FF8C,d0	;compare -$74 to Xpos diff
	bgt.w	.1	;branch if greater than
	bset	#pf3gctrl,pflags3(a3)	;set goalie control bit?
	bra.w	.cont2
.1
	cmp.w	#$64,d1	;'d'   ; compare $64 to Ypos diff
	blt.w	.2	;branch if less than
	bset	#pf3gctrl,pflags3(a3)	;set goalie control bit?
	bra.w	.cont2
.2
	cmp.w	#$FF9C,d1	;compare -$64 to Ypos diff
	bgt.w	.cont2	;branch if greater than
	bset	#pf3gctrl,pflags3(a3)	;set goalie control bit?
.cont2
	movem.w	(sp)+,d0-d1	;pop from stack
	btst	#pf3gctrl,pflags3(a3)	;check goalie ctrl bit
	bne.w	checkanim	;branch if set
.na
	btst	#5,pflags(a3)	;check if anim lock
	bne.w	rtss2	;exit if so
	bsr.w	check4bench
	bclr	#1,pflags(a3)	;clear new assignment bit
	beq.w	.nna	;branch if already cleared
	clr.w	temp1(a3)	;clear temp1
	move.w	#8,temp2(a3)	;move 8 into temp2
	st	temp4(a3)	;FFFF to temp4
.nna
	btst	#1,pflags2(a3)	;check if anim in progress
	bne.w	rtss2	;exit if so
	btst	#0,(gmode).w	;check if clock stopped
	bne.w	rtss2	;exit if so
	tst.w	temp5(a3)	;test temp5
	bmi.w	.nofo	;branch if less than 0
	move.w	SCnum(a3),d0	;move SCnum into d0
	cmp.w	(puckc).w,d0	;check if puckc is goalie
	beq.w	.mbfo	;branch if equal
	st	temp5(a3)	;set temp5 to -1
	bra.w	.nofo
.mbfo
	sub.w	d7,temp5(a3)	;subtract d7(frames elapsed) from temp5
	bpl.w	.nofo	;branch if more than 0
	btst	#2,(BA_PS_flags).w	;check bit 2
	beq.w	.stoppage	;branch if not set
	bset	#4,(BA_PS_flags).w
	bra.w	.nofo
.stoppage
	move.l	#8,d0
	bsr.w	AddPenalty2
.nofo
	sub.b	d7,temp1(a3)	;sub d7(frames elapsed) from temp1
	bpl.w	.ex	;branch if positive
	move.b	aidef(a3),d0	;DfA into d0
	beq.w	.3	;branch if value was 0
	btst	#6,(sflags7).w	;check if crowd meter broken
	beq.w	.3	;jump if not
	subq.b	#1,d0	;sub 1 from d0
.3
	lsr.b	#2,d0	;divide by 4
	move.b	d0,temp1(a3)	;move d0 into temp1
	move.w	SCnum(a3),d0	;move SCnum into d0
	cmp.w	(puckc).w,d0	;compare puckc to d0
	beq.w	*+4	;jump to assgoaliecpu if the same
.ex
	rts
; a3 = goalie
assgoaliecpu
	btst	#3,pflags(a3)	;is goalie joystick controlled?
	bne.w	assgoaliectrl	;branch if so
checkanim	;Goalie animation check; assgoaliectrl branches here too
	move.w	(puckx).w,(TmpPuckX).w
	btst	#0,(sflags4).w	;test bit 0
	beq.w	.assstart
	btst	#1,pflags2(a3)	;check if animation in progress
	bne.w	.assstart	;branch if so
	btst	#1,(sflags4).w	;test bit 1
	beq.w	.0	;branch if 0
	btst	#3,(sflags4).w	;test bit 3
	bne.w	.assstart	;branch if set
	cmpi.w	#$2C4,6(a3)	;compare to alice frame number
	bne.w	.assstart	;branch if not equal
	cmpi.w	#$2C8,6(a3)	;compare to alice frame number
	bne.w	.assstart	;branch if not equal
	bset	#3,(sflags4).w	;set bit 3
	move.w	#SFXcheck,-(sp)	;SFX
	bsr.w	sfx
	bra.w	.assstart	;set bit 3
.0
	movem.w	d0-d1,-(sp)
	move.w	(pucky).w,d0	;pucky to d0
	move.w	Ypos(a3),d1	;move Ypos to d1
	eor.w	d1,d0	;XOR d1 to d0
	movem.w	(sp)+,d0-d1
	bmi.w	.assstart	;branch if d0 is negative
	cmpi.w	#$14,(a3)	;compare 14 to Xpos
	bgt.w	.assstart	;branch if greater
	cmpi.w	#$FFEC,(a3)	;compare -14 to Xpos
	ble.w	.assstart	;branch if less than
	bset	#1,(sflags4).w	;set bit 1
	bclr	#3,(sflags4).w	;clear bit 3
	move.w	#$1596,d1	;SPAgslamtop: goalie stick slam after a goal, top net
	btst	#7,pflags(a3)	;check what goal shooting at
	beq.w	.1	;branch if bottom
	move.w	#$1684,d1	;SPAgslambot: bottom net
.1
	bsr.w	SetSPA	;set animation of d1
	bset	#1,pflags2(a3)	;set anim in progress
.assstart
	btst	#5,pflags(a3)	;check if locked in animation
	bne.w	rtss2	;exit if so
	bsr.w	check4bench
	bclr	#1,pflags(a3)	;clear new assignment
	beq.w	.nna	;jump if it was cleared already
	clr.w	temp1(a3)	;clear temp1
	move.w	#8,temp2(a3)	;move 8 into temp2
	st	temp4(a3)	;set temp5 (FFFF)
.nna
	cmpi.w	#$34,(a3)	;'4' ; compare 34 hex with Xpos
	bgt.w	.nna2	;branch if greater
	cmpi.w	#$FFCC,(a3)	;compare -34 hex with Xpos
	blt.w	.nna2	;branch if less than
	cmpi.w	#$10E,Ypos(a3)	;compare 10E with Ypos
	bgt.w	.nna2
	cmpi.w	#$FEF2,Ypos(a3)
	blt.w	.nna2
	cmpi.w	#$D2,Ypos(a3)
	bgt.w	.noskate
	cmpi.w	#$FF2E,Ypos(a3)
	blt.w	.noskate
.nna2
	lea	rtss2(pc),a0	;goalie will skate back to middle position
	moveq	#4,d0
	tst.w	(a3)	;test Xpos
	bpl.w	.2	;branch if positive
	neg.w	d0
.2
	move.w	#$E4,d1
	btst	#7,pflags(a3)	;check what goal shooting at
	beq.w	skateto	;branch if bottom
	neg.w	d1
	bra.w	skateto
.noskate
	btst	#1,pflags2(a3)	;check if anim in progress
	bne.w	rtss2	;exit if so
	btst	#0,(sflags4).w	;check bit 0
	beq.w	.noskate3	;branch if not set
	cmpi.w	#$2C5,6(a3)	;check alice frame
	beq.w	.noskate2	;branch if equal
	cmpi.w	#$2C9,6(a3)	;check alice frame
	bne.w	.noskate3	;branch if not equal
	move.w	#4,facedir(a3)	;set 4 to facedir - face down
	bra.w	.noskate3
.noskate2
	move.w	#0,facedir(a3)	;set 0 to facedir - face up
.noskate3
	move.w	#2,d1	;2 = SPAgready
	bsr.w	SetSPA
	btst	#2,(BA_PS_flags).w	;check bit 2
	bne.w	.noskate4	;branch if set
	btst	#0,(gmode).w	;check if clock
	bne.w	rtss2	;exit if clock stopped
.noskate4
	tst.w	temp5(a3)	;temp5
	bmi.w	.nofo	;branch if minus
	move.w	SCnum(a3),d0	;move SCnum to d0
	cmp.w	(puckc).w,d0	;check if puckc
	beq.w	.mbfo	;branch if so
	st	temp5(a3)	;set temp5 to FFFF
	bra.w	.nofo
.mbfo
	sub.w	d7,temp5(a3)	;subtract frames from temp5
	bpl.w	.nofo	;branch if positive
	btst	#2,(BA_PS_flags).w	;check if bit 2 set
	beq.w	.mbfo2	;branch if not
	bset	#4,(BA_PS_flags).w	;set bit 4
	bra.w	.nofo
.mbfo2
	move.l	#8,d0	;PenGhold
	bsr.w	AddPenalty2	;blow whistle for FO
.nofo
	sub.b	d7,temp1(a3)	;sub d7 from temp1
	bpl.w	.nodec	;branch if still positive
	move.b	aidef(a3),d0	;move aidef into d0 (DfA)
	beq.w	.nofo2	;branch if 0
	btst	#6,(sflags7).w	;check if crowd meter broken
	beq.w	.nofo2	;branch if not
	subq.b	#1,d0	;sub from d0
.nofo2
	lsr.b	#2,d0	;divide by 4
	move.b	d0,temp1(a3)	;move d0 into temp1
	btst	#3,pflags(a3)	;check if joy controlled
	beq.w	.nocontrol	;branch if not
	btst	#pf3gctrl,pflags3(a3)	;check bit 2
	bne.w	.nocontrol	;branch if set
	move.l	#$1D,d0	;assignment assgoaliectrl
	bra.w	assinsert
.nocontrol
	move.w	(pucky).w,d0	;move pucky into d0
	move.w	Ypos(a3),d1	;move Ypos into d1
	eor.w	d0,d1	;XOR
	bpl.w	.3	;branch if positive
	clr.w	d0
	move.w	#$F4,d2	;move F4 into d2
	btst	#7,pflags(a3)	;check which net shooting at
	beq.w	.de5	;branch if bottom
	neg.w	d2
	bra.w	.de5
.3
	subq.w	#1,temp4(a3)	;sub 1 from temp4
	bpl.w	.4	;branch if positive
	move.w	#$FFFF,temp4(a3)	;move -1 into temp4
.4
	move.w	SCnum(a3),d0	;SCnum into d0
	cmp.w	(puckc).w,d0	;check if puckc
	bne.w	.notpuckc	;branch if not
	tst.w	temp5(a3)	;check temp5
	bpl.w	.5	;branch if positive
	move.w	#$5A,temp5(a3)	;'Z' ; move 5A into temp5
.5
	st	temp4(a3)	;FFFF into temp4
	cmpi.w	#$5A,temp5(a3)	;'Z' ; compare to temp5
	bgt.w	.de1	;branch if greater
	move.w	(VDP_CNTR).l,d0
	andi.w	#3,d0	;pass first 2 bits
	bne.w	.de1	;branch if not 0
	moveq	#5,d0
	movea.w	#(SortCords-M68K_RAM),a0
	btst	#6,pflags(a3)	;check home or away
	bne.w	.opploop	;branch if away
	adda.w	#$300,a0
.opploop
	btst	#2,$63(a0)	;check if player unavailable
	bne.w	.opploop2	;branch if so
	move.w	(pucky).w,d1	;pucky into d1
	sub.w	$14(a0),d1	;sub Ypos a0 from d1
	cmp.w	#$1C,d1	;compare 1C to difference
	bgt.w	.opploop2	;branch if greater
	cmp.w	#$FFE4,d1	;compare -1C
	blt.w	.opploop2	;branch if less than
	move.w	(puckx).w,d1	;puckx into d1
	sub.w	(a0),d1	;sub Xpos a0 from d1
	cmp.w	#$19,d1	;compare 19 to difference
	bgt.w	.opploop2	;branch if greater
	cmp.w	#$FFE7,d1	;compare -19 to diff
	bgt.w	.de1	;branch if greater
.opploop2
	adda.w	#$80,a0	;move to next struct
	dbf	d0,.opploop
	move.w	#1,(threat).w	;dir of threat on puck handler
	bsr.w	chk4pass
	bra.w	.de1
.notpuckc
	tst.w	temp4(a3)	;check temp4
	bne.w	.de1	;branch if not 0
	tst.w	(puckc).w	;check puckc
	bpl.w	.de1	;branch if there is a puckc
	move.w	(puckx).w,d0
	sub.w	(a3),d0	;sub Xpos
	cmp.w	#$14,d0	;compare 14 to diff
	bgt.w	.de1	;branch if greater
	cmp.w	#$FFEC,d0	;-14
	blt.w	.de1	;branch if less
	move.w	(pucky).w,d1
	cmp.w	#$108,d1	;check goalline
	bgt.w	.de1	;branch if past goalline
	cmp.w	#$FEF8,d1	;check other goalline
	blt.w	.de1	;branch if past
	sub.w	Ypos(a3),d1	;sub Ypos from d1
	cmp.w	#$1E,d1	;compare to 1E
	bgt.w	.de1	;branch if greater
	cmp.w	#$FFE2,d1	;compare to -1E
	blt.w	.de1	;branch if less
	movem.w	d0-d1,-(sp)
	move.w	(puckvx).w,d0
	bpl.w	.6
	neg.w	d0
.6
	move.w	(puckvy).w,d1
	bpl.w	.7
	neg.w	d1
.7
	add.w	d1,d0	;add puckvx and vy
	cmp.w	#$1000,d0	;compare to 1000
	movem.w	(sp)+,d0-d1
	bgt.w	.de1	;branch if greater
	bsr.w	vtoa
	move.w	d0,facedir(a3)	;d0 into facedir. Goalie will face puck
	move.b	#8,nopuck(a3)	;move 8 to nopuck collision
	move.w	#$2F4,d1	;goalie dive anim.
	bsr.w	SetSPA	;set animation
	bset	#1,pflags2(a3)	;set anim in progress
	addi.w	#$96,(crowdlevel).w
	rts
.de1
	movea.w	#(puckcross-M68K_RAM),a0	;puckcross = xcord/frames top to bottom for goalies to react to
	move.w	#$104,d3
	btst	#7,pflags(a3)	;check what net shooting at
	beq.w	.8	;branch if bottom
	addq.w	#4,a0
	neg.w	d3
.8
	cmpi.w	#$104,Ypos(a3)
	bgt.w	.9
	cmpi.w	#$FEFC,Ypos(a3)
	bgt.w	.10
.9
	clr.w	d2
	clr.w	d0
	cmpi.w	#$2C,(a3)
	bgt.w	.de5
	cmpi.w	#$FFD4,(a3)
	blt.w	.de5
	move.w	#$88,d0
	tst.w	(a3)
	bpl.w	.de5
	neg.w	d0
	bra.w	.de5
.10
	tst.w	(puckc).w
	bmi.w	.11
	move.w	SCnum(a3),d0
	cmp.w	(puckc).w,d0
	beq.w	.11
	move.l	a0,-(sp)
	movea.l	#SortCords,a0
	move.w	(puckc).w,d0
	asl.w	#7,d0
	adda.w	d0,a0
	move.w	(puckx).w,d0
	sub.w	(a0),d0
	asr.w	#1,d0
	add.w	(a0),d0
	move.w	d0,(TmpPuckX).w
	movea.l	(sp)+,a0
.11
	move.w	(TmpPuckX).w,d0
	move.w	(pucky).w,d1
	bsr.w	ClampYPosition
	bsr.w	vtoa
	bsr.w	AdjustFacingDirection
	move.w	(gameclock).w,d0
	andi.w	#7,d0
	asl.w	#4,d0
	addi.w	#$A0,d0
	cmpi.w	#$DB,(pucky).w
	bgt.w	.12
	cmpi.w	#$FF25,(pucky).w
	bgt.w	.13
.12
	subi.w	#$40,d0
.13
	move.w	d0,d1
	muls.w	(puckvx).w,d0
	swap	d0
	add.w	(TmpPuckX).w,d0
	muls.w	(puckvy).w,d1
	swap	d1
	add.w	(pucky).w,d1
	bsr.w	ClampYPosition
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#$384,d0
	bhi.w	.14
	movem.w	(sp)+,d0-d1
	bra.w	.16
.14
	bsr.w	sroot
	moveq	#1,d2
	add.w	d0,d2
	moveq	#$12,d4
	btst	#3,(sflags).w
	beq.w	.15
	addq.w	#8,d4
.15
	movem.w	(sp)+,d0-d1
	muls.w	d4,d1
	addq.w	#8,d4
	muls.w	d4,d0
	divs.w	d2,d0
	divs.w	d2,d1
.16
	add.w	d3,d1
	move.w	d1,d2
	btst	#0,(gmode2).w
	bne.w	.18
	btst	#2,(BA_PS_flags).w
	bne.w	.18
	btst	#3,(sflags).w
	beq.w	.18
	cmpi.w	#$D0,(pucky).w
	bgt.w	.17
	cmpi.w	#$FF30,(pucky).w
	blt.w	.17
	bra.w	.18
.17
	cmpi.w	#$14,(a3)
	bgt.w	.18
	cmpi.w	#$FFEC,(a3)
	blt.w	.18
	btst	#1,(gameclock+1).w
	bne.w	.18
	bra.w	.19
.18
	cmpi.w	#$22,2(a0)
	bhi.w	.de5
	cmpi.w	#$18,(a0)
	bgt.w	.22
	cmpi.w	#$FFE8,(a0)
	blt.w	.22
	cmpi.w	#$C,2(a0)
	bhi.w	.20
.19
	cmpi.w	#$108,(pucky).w
	bgt.w	.20
	cmpi.w	#$FEF8,(pucky).w
	blt.w	.20
	bset	#1,pflags2(a3)
	bne.w	.20
	jsr	(goaliesave).l
.20
	move.w	(a0),d0
	cmpi.w	#$FC,(pucky).w
	bgt.w	.21
	cmpi.w	#$FF04,(pucky).w
	bgt.w	.de5
.21
	moveq	#$18,d0
	tst.w	(TmpPuckX).w
	bpl.w	.de5
	neg.w	d0
.de5
	move.w	d2,d1
	movem.w	d0-d1,-(sp)
	move.b	Xvel(a3),d0
	ext.w	d0
	neg.w	d0
	add.w	(sp)+,d0
	sub.w	(a3),d0
	move.b	Yvel(a3),d1
	ext.w	d1
	neg.w	d1
	add.w	(sp)+,d1
	sub.w	Ypos(a3),d1
	cmp.w	#4,d0
	bgt.w	.vt
	cmp.w	#$FFFC,d0
	blt.w	.vt
	cmp.w	#4,d1
	bgt.w	.vt
	cmp.w	#$FFFC,d1
	blt.w	.vt
	clr.w	d0
	clr.w	d1
.vt
	bsr.w	vtoa
	move.b	d0,temp2+1(a3)	;move d0 into temp2+1
.nodec
	move.b	temp2+1(a3),d2	;temp2+1
	ext.w	d2
	cmp.w	#7,d2
	ble.w	playeracc
	bra.w	stopna
.22
	tst.w	(puckc).w
	bpl.s	.de5
	btst	#2,(iflags).w
	bne.s	.de5
	movea.w	#(tmstruct-M68K_RAM),a1
	lea	$364(a1),a2
	btst	#6,pflags(a3)
	beq.w	.23
	exg	a1,a2
.23
	cmpi.l	#$1324,$2A(a1)
	blt.w	.de5
	cmpi.l	#$9C4,Yvel(a2)
	blt.w	.de5
	cmpi.w	#$E0,(pucky).w
	bgt.w	.24
	cmpi.w	#$FF20,(pucky).w
	bgt.w	.de5
.24
	tst.w	(puckvy).w
	btst	#7,pflags(a3)
	beq.w	.25
	eori	#8,ccr
.25
	bmi.w	.de5
	move.w	(puckvx).w,d0
	bpl.w	.26
	neg.w	d0
.26
	move.w	(puckvy).w,d1
	bpl.w	.27
	neg.w	d1
.27
	cmp.w	d0,d1
	blt.w	.de5
	move.l	#$F,d0	;assignment DD2E?
	bra.w	assinsert
ClampYPosition	;d1 = y clamped to +-$103, minus goal line d3. d0 = 0 if a3 has the puck
	move.w	(puckc).w,d2
	cmp.w	SCnum(a3),d2
	bne.w	.0
	clr.w	d0
.0
	cmp.w	#$103,d1
	blt.w	.1
	move.w	#$103,d1
.1
	cmp.w	#$FEFD,d1
	bgt.w	.2
	move.w	#$FEFD,d1
.2
	sub.w	d3,d1
	rts
AdjustFacingDirection	;Turn facedir one step toward direction d0
	move.w	facedir(a3),d1		;facedir
	sub.w	d1,d0
	beq.w	rtss2
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0
	subq.w	#1,d0			;d0 = +1/-1
	btst	#3,pflags(a3)		;pfjoycon
	bne.w	.add
	btst	d1,#$42			;facing 1 or 6
	beq.w	.add
	add.w	d0,d1
	btst	#pfgoal,pflags(a3)		;pfgoal
	bne.w	.dn
	btst	d1,#$83			;0, 1 or 7
	bra.w	.t
.dn	btst	d1,#$38	;3, 4 or 5
.t	beq.w	.set
	neg.w	d0
	add.w	d0,d1
.add	add.w	d0,d1
.set	andi.w	#7,d1
	move.w	d1,facedir(a3)		;facedir
	rts
; set save animation for goalie depending on puck location
; a3 = goalie
; a0 = puckcross
; d3 = goalline of goalie
goaliesave
	move.w	(a0),d0	;puckcross x frames into d0
	sub.w	(a3),d0	;sub goalie Xpos from d0
	move.w	d3,d1	;move goalline into d1
	sub.w	Ypos(a3),d1	;sub goalie Ypos from d1
	bsr.w	vtoa
	sub.w	facedir(a3),d0	;sub facedir from d0
	andi.w	#7,d0	;pass first 3 bits of d0
	move.w	d0,d3	;move d0 into d3
	lsr.w	#2,d0	;divide d0 by 4
	btst	#3,4(a3)
	beq.w	.0
	eori.w	#1,d0
.0
	cmpi.w	#8,(puckz).w
	bgt.w	.1
	cmpi.w	#$800,(puckvz).w
	bgt.w	.1
	bra.w	.3
.1
	movem.l	d0,-(sp)
	move.w	(a3),d0
	sub.w	(a0),d0
	cmp.w	#$10,d0
	bgt.w	.2
	cmp.w	#$FFF0,d0
	blt.w	.2
	movem.l	(sp)+,d0
	addq.w	#6,d0
	bra.w	.12
.2
	movem.l	(sp)+,d0
	bra.w	.12
.3
	addq.w	#4,d0
	cmpi.w	#8,2(a0)
	bls.w	.9
	cmpi.w	#2,facedir(a3)
	beq.w	.12
	cmpi.w	#6,facedir(a3)
	beq.w	.12
	tst.w	(puckc).w
	bmi.w	.12
	subq.w	#2,d0
	move.w	d1,-(sp)
	move.w	#$1000,d1
	move.w	d1,Xvel(a3)
	ori.w	#1,d0
	btst	#7,pflags(a3)
	bne.w	.4
	eori.w	#1,d0
.4
	move.w	#$FFFA,d1
	tst.w	Xvel(a3)
	bmi.w	.5
	neg.w	Xvel(a3)
.5
	tst.w	(a3)
	bpl.w	.7
	tst.w	Xvel(a3)
	bpl.w	.6
	neg.w	Xvel(a3)
.6
	move.w	#6,d1
	eori.w	#1,d0
.7
	add.w	d1,(a3)
	btst	#0,handed(a3)	;check hand of goalie
	beq.w	.8	;Branch if goalie is Full Right
	eori.w	#1,d0
.8
	move.w	(sp)+,d1
	bra.w	.12
.9
	movem.l	d0,-(sp)
	move.w	(a3),d0
	sub.w	(a0),d0
	cmp.w	#$10,d0
	ble.w	.10
	movem.l	(sp)+,d0
	bra.w	.11
.10
	cmp.w	#$FFF0,d0
	movem.l	(sp)+,d0
	bgt.w	.12
.11
	addq.w	#4,d0
.12
	add.w	d0,d0
	lea	.saveanim(pc),a1
	move.w	0(a1,d0.w),d1
	cmp.w	#$178,d1
	bne.w	.13
	andi.w	#3,d3
	beq.w	.13
	cmpi.b	#$B,aggress(a3)	;73 = Glove Left. Compares 11 dec to GloveL
	blt.w	.13	;branch if less than
	move.w	#$1AA,d1	;reach out glove save
.13
	bsr.w	SetSPA
	addi.w	#$96,(crowdlevel).w
	addi.w	#$A,(CwdExciteLvl).w
	asr.w	Xvel(a3)
	asr.w	Xvel(a3)
	asr.w	Yvel(a3)
	asr.w	Yvel(a3)
	rts
.saveanim	;SPA per save type. Same 10 words as the unreferenced table in the input code
	dc.w	$146
	;blocker save
	dc.w	$178	;glove save
	dc.w	$250	;pad stack right
	dc.w	$2A2	;pad stack left
	dc.w	$1EC	;kick save
	dc.w	$21E	;blocking butterfly save
	dc.w	$148E	;SPAghighr. high shoulder save right
	dc.w	$14C0	;SPAghighl. high shoulder save left
	dc.w	$14F2	;SPAgstick2r. stick save right
	dc.w	$1544	;SPAgstick2l. stick save left
; assignment to have goalie skate to the puck when it is loose
assgoalietopuck
	btst	#3,pflags(a3)
	bne.w	assexit
	btst	#0,(gmode).w
	bne.w	assexit
	bsr.w	check4bench
	bclr	#1,pflags(a3)
	beq.w	.0
	clr.w	temp1(a3)
.0
	sub.b	d7,temp1(a3)
	bpl.w	.go
	move.b	aidef(a3),d0	;aidef
	beq.w	.1
	btst	#6,(sflags7).w
	beq.w	.1
	subq.b	#1,d0
.1
	lsr.b	#2,d0
	move.b	d0,temp1(a3)
	tst.w	(puckc).w
	bpl.w	assexit
	tst.w	(puckvy).w
	btst	#7,pflags(a3)
	beq.w	.dir
	eori	#8,ccr
.dir
	bmi.w	assexit
	movea.w	#(tmstruct-M68K_RAM),a1	;load home team struct into a1
	lea	tmsize(a1),a2	;load away team struct into a2
	btst	#6,pflags(a3)	;check if player is home or away
	beq.w	.t0	;branch if home
	exg	a1,a2	;swap if away
.t0
	cmpi.l	#$E10,$2A(a1)
	blt.w	assexit
	cmpi.l	#$640,Yvel(a2)
	blt.w	assexit
.go
	bra.w	skatetopuck
breakaway	;puck carrier a3 on a breakaway: beep on a new assignment and check the skating direction toward the net
	bset	#2,(sflags5).w
	bclr	#1,pflags(a3)	;pfna - clear new assignment
	beq.w	.nna	;jump if no new assignment
	move.w	#SFXbeep1,-(sp)	;ding SFX
	jsr	(sfx).l
	movem.l	a2,-(sp)	;push a2 on stack
	movea.l	#tmstruct,a2	;move Home Team Struct into a2
	btst	#6,pflags(a3)	;pfteam - check if home or away
	beq.w	.c0	;jump if home
	movea.l	#AwShots,a2	;move Away Team Struct into a2
.c0
	addq.w	#1,$358(a2)	;add one to breakaway attempt
	addi.w	#$14,(CwdExciteLvl).w	;add to CwdExcite
	addi.w	#$C8,(crowdlevel).w	;add to crowdlevel
	movem.l	(sp)+,a2
.nna
	movem.w	d1,-(sp)	;push d1 on stack
	move.w	Ypos(a3),d0	;move Ypos into d0
	move.w	Yvel(a3),d1	;move Yvel into d1
	beq.w	.yvel0	;jump if Yvel = 0
	eor.w	d1,d0	;EOR d1 with d0. d0 will be negative if skating opposite direction of net
.exit
	movem.w	(sp)+,d1	;pop d1 off stack
	rts
.yvel0
	move.w	#$FFFF,d1
	bra.s	.exit
BreakawayOffsidesFlagSet	;On a new assignment clear the offsides and breakaway bits of a3. Behind the goal line or not yet in the attack zone set pf3oside, else end the assignment
	btst	#1,pflags(a3)	;check for new assignment
	beq.w	.loadYpos	;branch if no new assignment
	bclr	#pf3oside,pflags3(a3)	;clear player offsides flag
	bclr	#pf3break,pflags3(a3)	;clear player breakaway flag
.loadYpos
	movem.w	d0-d1/a0,-(sp)
	move.w	#$108,d0	;108 = top goal line Y pos
	move.w	Ypos(a3),d1	;Ypos
	bpl.w	.cmpgoalline	;branch if Ypos is positive
	neg.w	d1	;negate d1
.cmpgoalline
	cmp.w	d0,d1	;compare position to top goal line
	bge.w	.nogood	;Branch if above it
	move.w	#$58,d0	;'X'   ; 58 = top blue line Y pos
	move.w	Ypos(a3),d1	;Ypos
	btst	#7,pflags(a3)	;check goal to shoot on (0=bottom, 1=top)
	bne.w	.top	;branch if top goal
	neg.w	d0	;bottom goal, so negate d0
	cmp.w	d1,d0	;compare Ypos to blue line Y
	blt.w	.setoffside	;branch if not in attack zone
	bra.w	.offzone	;branch if in attack zone
.top
	cmp.w	d1,d0	;compare Ypos to blue line Y
	blt.w	.offzone	;branch if in offensive zone
.setoffside
	bset	#pf3oside,pflags3(a3)	;set offsides flag
	bra.w	.nogood
.offzone
	bclr	#pf3oside,pflags3(a3)	;clear offside bit
	beq.w	.nogood	;branch if on the blue line
	movea.l	#SortCords+(11*SCstruct),a0	;loads last SCScruct player struct (Away pos #6)
	move.w	#$B,d0	;B = # of player structs to check (12)
	tst.w	d1	;checks if d1 is negative (determines what zone to check)
	bmi.w	.checkYpos
.checkYpos2
	cmp.w	$14(a0),d1	;compare Ypos of a0 player to d1 (Ypos puckc)
	bge.w	.substruct2	;branch if d1 greater than or equal
	tst.w	$34(a0)	;check if goalie
	beq.w	.substruct2	;branch if goalie
	bra.w	.nogood
.substruct2
	suba.w	#$80,a0
	dbf	d0,.checkYpos2
.setBAbit
	bset	#pf3break,pflags3(a3)	;set breakaway bit
	move.w	#1,d0	;moves 1 into d0 (used by returned subroutine)
.exit
	movem.w	(sp)+,d0-d1/a0
	rts
.nogood
	move.w	#0,d0	;move 0 into d0 (used on return to subroutine)
	bra.s	.exit
.checkYpos
	cmp.w	$14(a0),d1	;check Ypos with d1 (d1 = blue line Y)
	ble.w	.substruct
	tst.w	$34(a0)	;checks if goalie (who would be below blue line)
	beq.w	.substruct
	bra.s	.nogood
.substruct
	suba.w	#$80,a0	;subtract SCstruct size (80 hex)
	dbf	d0,.checkYpos
	bra.s	.setBAbit
chkpuckc	;puck carrier a3: check for a breakaway (not in a shootout or penalty shot), else assign asspuckc
	btst	#0,(gmode2).w
	bne.w	.0
	btst	#2,(BA_PS_flags).w
	bne.w	.0
	bsr.w	breakaway
	bpl.w	asspuckc	;currently skating towards net in Y
.0
	bclr	#pf3break,pflags3(a3)	;clear breakaway bit
	move.w	#$10,d0	;asspuckc
	bsr.w	assreplace
asspuckc	;player a3 is puck handler
	bclr	#2,(sflags5).w
	bne.w	.0
	bclr	#pf3break,pflags3(a3)
.0
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	assexit
	btst	#2,(BA_PS_flags).w
	beq.w	.1
	cmpi.w	#1,(msgtimer).w
	bgt.w	.x
.1
	btst	#pf3break,pflags3(a3)
	bne.w	.2
	btst	#2,(BA_PS_flags).w
	bne.w	.2
	jsr	(BreakawayOffsidesFlagSet).l
	beq.w	.2	;branch if breakaway flag not set
	move.w	#$21,d0	;'!'   ; chkpuckc assignment
	bsr.w	assreplace
	bra.w	*+4
.2
	btst	#5,pflags(a3)
	bne.w	rtss2
	btst	#2,(BA_PS_flags).w
	bne.w	.3
	btst	#0,(gmode).w
	bne.w	donothing
.3
	btst	#3,pflags(a3)
	bne.w	assexit
	bclr	#1,pflags(a3)
	beq.w	.7
	btst	#pf3break,pflags3(a3)
	beq.w	.4
	move.w	#SFXbeep1,-(sp)
	jsr	(sfx).l
.4
	btst	#pf3break,pflags3(a3)
	beq.w	.6
	movem.l	a2,-(sp)
	movea.l	#tmstruct,a2
	btst	#6,pflags(a3)
	beq.w	.5
	movea.l	#AwShots,a2
.5
	addq.w	#1,$358(a2)
	addi.w	#$14,(CwdExciteLvl).w
	addi.w	#$C8,(crowdlevel).w
	movem.l	(sp)+,a2
.6
	clr.w	temp1(a3)
	move.w	#8,temp2(a3)
	move.w	(VDP_CNTR).l,d0
	andi.w	#3,d0
	move.w	d0,temp3(a3)
.7
	sub.b	d7,temp1(a3)
	bpl.w	.nodec
	move.b	aioff(a3),temp1(a3)
	jsr	(ReadGoaliePulled).l
	bmi.w	.8
	btst	#6,(sflags7).w
	beq.w	.9
	tst.b	temp1(a3)
	beq.w	.9
.8
	subq.b	#1,temp1(a3)
.9
	btst	#2,(BA_PS_flags).w
	bne.w	.12
	btst	#0,(gmode2).w
	bne.w	.12
	bsr.w	checkob
	bsr.w	chk4lc
	btst	#0,(gmode2).w
	bne.w	.12
	btst	#2,(BA_PS_flags).w
	bne.w	.12
	btst	#pf3break,pflags3(a3)
	bne.w	.11
	move.w	#1,d0
	btst	#6,pflags(a3)
	beq.w	.10
	move.w	#2,d0
.10
	cmp.w	(cont1team).w,d0
	beq.w	.11
	cmp.w	(cont2team).w,d0
	beq.w	.11
	btst	#1,(vcount+1).w
	bne.w	.13
.11
	bsr.w	chk4shot
	bra.w	.13
.12
	jsr	(ShootoutShootCheck).l
	bne.w	.nodec
	jsr	(CompShoot).l
.13
	bsr.w	chk4pass
.nodec
	moveq	#6,d0
	add.w	temp3(a3),d0	;add temp3 to d0
	lea	.postab2(pc),a0
	btst	#sf2offsig,(sflags2).w	;#sf2offsig
	beq.w	.nd1
	move.w	position(a3),d0	;position
.nd1
	asl.w	#2,d0
	move.w	2(a0,d0.w),d1
	move.w	0(a0,d0.w),d0
	btst	#2,(BA_PS_flags).w
	bne.w	.14
	btst	#0,(gmode2).w
	beq.w	.15
.14
	jsr	(SkatePath).l
	cmpi.b	#$80,(sopathx).w
	beq.w	.x
.15
	btst	#7,pflags(a3)	;pfgoal - 0 for bottom 1 for top
	bne.w	.nd0
	neg.w	d0
	neg.w	d1
.nd0
	lea	.chkdir(pc),a0
	btst	#2,(BA_PS_flags).w
	bne.w	.16
	btst	#0,(gmode2).w
	beq.w	.17
.16
	lea	.x(pc),a0
.17
	bra.w	skateto
.chkdir
	ext.w	d0
	move.b	Xvel(a3),d2	;Xvel
	ext.w	d2
	add.w	(puckx).w,d2
	move.b	Yvel(a3),d3	;Yvel
	ext.w	d3
	add.w	(pucky).w,d3
	clr.w	(threat).w
	moveq	#5,d4
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	bge.w	.loop
	adda.w	#6*SCstruct,a0	;away team SCstruct start
.loop
	move.b	Xvel(a0),d1	;Xvel
	ext.w	d1
	add.w	(a0),d1	;Xpos
	sub.w	d2,d1
	cmp.w	#$14,d1
	bgt.w	.next
	cmp.w	#$FFEC,d1
	blt.w	.next
	move.b	Yvel(a0),d1	;Yvel
	ext.w	d1
	add.w	Ypos(a0),d1	;Ypos
	sub.w	d3,d1
	cmp.w	#$14,d1
	bgt.w	.next
	cmp.w	#$FFEC,d1
	blt.w	.next
	addq.w	#1,(threat).w
	move.w	(a3),d0	;Xpos
	sub.w	(a0),d0
	move.w	Ypos(a3),d1	;Ypos
	sub.w	Ypos(a0),d1
	bsr.w	vtoa
	move.w	facedir(a3),d1	;facedir
	eori.w	#4,d1
	cmp.w	d0,d1
	bne.w	.next
	move.w	(VDP_CNTR).l,d1
	andi.w	#1,d1
	add.w	d1,d0
	andi.w	#7,d0
.next
	adda.w	#SCstruct,a0	;SCstruct size
	dbf	d4,.loop
.x
	rts
.postab2	dc.w	$FF9C
	dc.w	$FFEC
	dc.w	$64
	dc.w	$FFEC
	dc.w	$FF88
	dc.w	$28
	dc.w	$14
	dc.w	$28
	dc.w	$78
	dc.w	$28
	dc.w	$FFEC
	dc.w	$28
	dc.w	$FFD8
	dc.w	$F0
	dc.w	0
	dc.w	$DC
	dc.w	$14
	dc.w	$E6
	dc.w	$1E
	dc.w	$E6
chk4lc	;see if computer should call line change
	btst	#4,(sflags7).w
	bne.w	rtss2
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.0
	neg.w	d0
.0
	tst.w	d0
	bmi.w	rtss2
	cmp.w	#$58,d0
	bgt.w	rtss2
	move.w	(VDP_CNTR).l,d0
	andi.w	#3,d0
	bne.w	rtss2
	btst	#3,pflags2(a3)
	bne.w	rtss2
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	$364(a2),a1
	btst	#6,pflags(a3)
	beq.w	.1
	exg	a2,a1
.1
	bsr.w	AvgCline
	cmp.w	#$C00,d0
	bhi.w	rtss2
	bsr.w	CompLine
	bsr.w	setpersonel
	bsr.w	printscores1
	bra.w	CompShoot
; return z flag set if killing penalty
; return z flag clr if not
chkpk
	btst	#sf2pwrplay,(sflags2).w	;#sf2pwrplay - check if power play in progress
	bne.w	chkpk2
	eori	#4,ccr	;Z flag
	rts
chkpk2	;return z flag set if a3's team is the one on the power play (sf2pwrtm against pfteam)
	movem.l	d0-d1,-(sp)
	btst	#6,(sflags2).w	;#sf2pwrtm - 0 for team 1, 1 for team 2
	move	sr,d0
	btst	#6,pflags(a3)	;pfteam - 0 home, 1 away
	move	sr,d1
	eor.w	d1,d0
	move	d0,ccr
	movem.l	(sp)+,d0-d1
	rts
; player a3 looks for shot (computer controlled)
chk4shot
	bsr.s	chkpk
	bne.w	.pkill	;killing penalty
	tst.w	(threat).w
	beq.w	.pkill	;no threat
	move.w	(VDP_CNTR).l,d0
	andi.w	#3,d0
	bne.w	.pkill
	move.w	#$58,d0	;'X'   ; top blue line Y position
	btst	#7,pflags(a3)
	beq.w	.cmphome
	move.w	#$FFA8,d0	;bottom blue line Y pos
	cmp.w	Ypos(a3),d0
	blt.w	CompShoot	;clear puck
	bra.w	.0
.cmphome
	cmp.w	Ypos(a3),d0
	bgt.w	CompShoot	;clear puck
.0
	bset	#3,(sflags5).w
	jmp	dopass
	dc.b	$60	;`
	dc.b	0,1
	dc.b	$30	;0
.pkill
	btst	#pf3break,pflags3(a3)
	beq.w	.npk
	move.w	#$1E,d0
	jsr	(randomd0).l
	addi.w	#$82,d0
	cmp.w	(pucky).w,d0
	blt.w	.1
	neg.w	d0
	cmp.w	(pucky).w,d0
	bgt.w	.1
	bra.w	.npk
.1
	move.w	#2,d0
	jsr	(randomd0s).l
	add.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,facedir(a3)
	bra.w	CompShoot
.npk
	moveq	#$20,d4
	clr.w	d1
	move.b	spodds(a3),d1
	lsr.w	#1,d1
	sub.b	d1,d4
	asl.w	#4,d4
	move.w	#$108,d1	;top goal line Y
	btst	#7,pflags(a3)
	bne.w	.c0
	neg.w	d1
.c0
	sub.w	(pucky).w,d1
	move.w	(puckx).w,d0
	neg.w	d0
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d0,d1
	cmp.l	#$2710,d1
	movem.w	(sp)+,d0-d1
	bhi.w	.no1
	lsr.w	#4,d4
	bsr.w	vtoa
	move.w	d0,d5
	moveq	#5,d3
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,SCnum(a3)
	bge.w	.loop
	adda.w	#6*SCstruct,a1
.loop
	tst.w	position(a1)
	beq.w	.2
	move.w	(a1),d0
	sub.w	(puckx).w,d0
	move.w	Ypos(a1),d1
	sub.w	(pucky).w,d1
	bsr.w	vtoa
	cmp.w	d5,d0
	bne.w	.co1
	asl.w	#1,d4
	bra.w	.co1
.2
	btst	#1,pflags2(a1)
	beq.w	.co1
	clr.w	d3
	moveq	#1,d4
.co1
	adda.w	#SCstruct,a1
	dbf	d3,.loop
.no1
	move.w	d4,d0
	bsr.w	randomd0
	btst	#0,spodds(a3)
	beq.w	.3
	cmp.w	#7,d0
	bgt.w	rtss2
	bra.w	.4
.3
	cmp.w	#8,d0
	bgt.w	rtss2
.4
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.ds0
	neg.w	d0
.ds0
	tst.w	d0
	bmi.w	rtss2
	move.w	#$108,d1
	sub.w	d0,d1
	bmi.w	rtss2
	btst	#sf2offsig,(sflags2).w
	bne.w	rtss2
CompShoot	;computer shot: drop the return address and aim from the puck's distance to the goal line
	addq.w	#4,sp
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.ds0
	neg.w	d0
.ds0
	move.w	#$108,d1
	sub.w	d0,d1
	lsr.w	#3,d1
	cmp.w	#$14,d1
	blt.w	.0
	moveq	#$14,d1
.0
	move.w	d1,temp2(a3)
	move.l	#$12,d0	;assshoot
	bra.w	assreplace
chk4pass	;player a3 looks for good pass (computer controlled)
	tst.w	(threat).w
	bne.w	.dp0
	moveq	#$10,d0
	add.b	spodds(a3),d0
	bsr.w	randomd0
	cmp.w	#$C,d0
	bgt.w	rtss2
.dp0
	moveq	#6,d0
	bsr.w	randomd0
	cmpi.w	#6,SCnum(a3)
	blt.w	.0
	addq.w	#6,d0
.0
	tst.w	position(a3)
	beq.w	.1
	cmpi.w	#$28,(puckx).w
	bgt.w	.1
	cmpi.w	#$FFD8,(puckx).w
	blt.w	.1
	cmpi.w	#$CC,(pucky).w
	bgt.w	rtss2
	cmpi.w	#$FF34,(pucky).w
	blt.w	rtss2
.1
	cmp.w	SCnum(a3),d0
	beq.w	rtss2
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a0
	adda.w	d0,a0
	tst.w	position(a0)
	ble.w	rtss2
	btst	#2,pflags2(a0)
	bne.w	rtss2
	btst	#pfalock,pflags(a0)
	bne.w	rtss2
	move.w	Ypos(a0),d0
	move.w	Ypos(a3),d1
	btst	#7,pflags(a3)
	bne.w	.f0
	neg.w	d0
	neg.w	d1
.f0
	btst	#gmoffs,(gmode).w
	beq.w	.oko
	movem.w	d0-d1,-(sp)
	subi.w	#$58,d0
	subi.w	#$58,d1
	eor.w	d0,d1
	movem.w	(sp)+,d0-d1
	bmi.w	rtss2
.oko
	cmp.w	#$58,d0
	bgt.w	.ok
	sub.w	d1,d0
	cmp.w	#$FFF1,d0
	blt.w	rtss2
.ok
	move.w	(a0),d0
	sub.w	(puckx).w,d0
	move.w	Ypos(a0),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	bsr.w	vtoa
	move.w	d0,(passdir).w
	movem.w	(sp)+,d1-d2
	muls.w	d1,d1
	muls.w	d2,d2
	add.l	d1,d2
	moveq	#5,d3
	movea.w	#(SortCords-M68K_RAM),a1
	cmpi.w	#6,SCnum(a3)
	bge.w	.co0
	adda.w	#6*SCstruct,a1
.co0
	move.w	(a1),d0
	sub.w	(puckx).w,d0
	move.w	Ypos(a1),d1
	sub.w	(pucky).w,d1
	movem.w	d0-d1,-(sp)
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d0,d1
	cmp.l	d2,d1
	movem.w	(sp)+,d0-d1
	bhi.w	.co1
	bsr.w	vtoa
	cmp.w	(passdir).w,d0
	beq.w	rtss2
.co1
	adda.w	#SCstruct,a1
	dbf	d3,.co0
	bsr.w	dopass
	tst.w	position(a3)
	beq.w	rtss2
	addq.w	#4,sp
	bra.w	assexit
; player a3 should avoid the puck carrier if he's on their team
EvadePC
	tst.w	(puckc).w
	bmi.w	rtss2	;no puck carrier
	move.b	Xvel(a3),d2	;Xvel
	sub.b	(puckvx).w,d2	;sub puckvx from Xvel
	ext.w	d2
	add.w	(a3),d2	;add Xpos
	sub.w	(puckx).w,d2	;Sub puckx
	cmp.w	#$28,d2	;'('   ; compare to 40 decimal
	bgt.w	rtss2	;exit if greater than 40
	cmp.w	#$FFD8,d2	;compare to -40
	blt.w	rtss2	;exit if less than -40
	move.b	Yvel(a3),d1	;Yvel
	sub.b	(puckvy).w,d1	;sub puckvy from Yvel
	ext.w	d1
	add.w	Ypos(a3),d1	;add Ypos to d1
	sub.w	(pucky).w,d1	;Sub pucky
	cmp.w	#$28,d1	;'('   ; compare to 40 dec
	bgt.w	rtss2	;exit if greater than
	cmp.w	#$FFD8,d1	;compare to -40 dec
	blt.w	rtss2	;exit if less than
	move.w	(a3),d0	;Xpos
	sub.w	(puckx).w,d0	;Sub puckx from Xpos
	move.w	Ypos(a3),d1	;Ypos
	sub.w	(pucky).w,d1	;Sub pucky from Ypos
	bsr.w	vtoa	;find direction and convert to 0-7
	btst	#5,(gmode).w	;check if offsides is on
	beq.w	.ex	;exit if not
	move.w	Ypos(a3),d1	;Ypos
	btst	#7,pflags(a3)	;check what net shooting at
	bne.w	.0	;branch if top
	neg.w	d1	;negate d1 (Ypos)
.0
	subi.w	#$58,d1	;'X'   ; sub 88 from Ypos (top blue line)
	cmp.w	#$A,d1	;compare to 10 decimal
	bgt.w	.ex	;exit if greater
	cmp.w	#$FFCE,d1	;compare to -50
	blt.w	.ex	;branch if less than
	moveq	#2,d0
	move.w	(a3),d1	;Xpos
	cmp.w	(puckx).w,d1	;compare puckx with Ypos difference
	bgt.w	.ex	;exit if greater
	moveq	#6,d0
.ex
	rts
;	checkob, assbreakaway, assnearest, check4check, asspassrec, assshoot, the
;	penalty shot code (puckshootout ... PenaltyShotEndReturn), the faceoff code
;	(puckfaceoff ... Endfaceoff), ChkGoalies, ReturnGoalies, CPgoalie,
;	CompLine, pucknorm, then ChkOffsides, the puck state routines, skateto,
;	avdgoal, skatetopuck, the assignment list helpers, GetHot, SetSPA, the
;	acceleration code (doplayeracc ... stopna) and dirtab.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp /
;	cmpi; fixopcodes.js patches the cmp encoding after assembly.
;	Inline print strings after printz / printz2 use the String macro (length word includes itself).
;	SortCords offsets: Xpos 0, Ypos $14, Xvel $28, Yvel $2A, position $34, assnum $36, temp1 $40,
;	temp3 $44, temp4 $46, SCnum $52, facedir $54, SPA $58, pflags $62, pflags2 $63.

checkob	;bring up little warning ref if a player on your team is over blue line
	btst	#5,(gmode).w
	beq.w	rtss2
	btst	#2,(BA_PS_flags).w
	bne.w	rtss2
	movem.l	d0-d1/a0,-(sp)
	moveq	#5,d0
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)
	blt.w	.0
	adda.w	#6*SCstruct,a0
.0
	moveq	#$5C,d1
	btst	#pfgoal,pflags(a3)
	bne.w	.top
	neg.w	d1
	cmp.w	(pucky).w,d1
	bgt.w	.nob
.bottom
	tst.w	position(a0)
	bmi.w	.bn
	cmp.w	Ypos(a0),d1
	bgt.w	.ob
.bn
	adda.w	#SCstruct,a0
	dbf	d0,.bottom
.nob
	moveq	#$40,d0
	bclr	#sf2offsig,(sflags2).w
	bne.w	.dref
.ex
	movem.l	(sp)+,d0-d1/a0
	rts
.ob
	moveq	#6,d0
	bset	#sf2offsig,(sflags2).w
	bne.s	.ex
.dref
	tst.w	(RefCnt).w
	bpl.s	.ex
	bsr.w	PushRef
	bra.s	.ex
.top
	cmp.w	(pucky).w,d1
	blt.s	.nob
.top1
	tst.w	position(a0)
	bmi.w	.tn
	cmp.w	Ypos(a0),d1
	blt.s	.ob
.tn
	adda.w	#SCstruct,a0
	dbf	d0,.top1
	bra.s	.nob
; assignment for breakaway
assbreakaway
	move.w	SCnum(a3),d0	;Move SCnum into d0
	cmp.w	(puckc).w,d0	;compare puck carrier SCnum with d0
	beq.w	.puckc	;branch if puck carrier
.notpuckc
	bclr	#pf3break,pflags3(a3)	;clear breakaway bit
	move.w	#$11,d0	;11 - assnearest
	bsr.w	assreplace
	bra.w	assnearest
.puckc
	jsr	(breakaway).l
	bmi.s	.notpuckc
; this is a special assignment used for the player who is nearest the puck but doesn't have it
assnearest
	bclr	#2,(sflags5).w
	bne.w	.chkpuck
	bclr	#pf3break,pflags3(a3)	;clear breakaway bit
.chkpuck
	move.w	SCnum(a3),d0	;move SCnum into d0
	cmp.w	(puckc).w,d0	;compare with puck carrier SCnum
	bne.w	.chkbreak	;jump if not puck carrier
	btst	#pf3break,pflags3(a3)	;check breakaway bit
	bne.w	.chkbreak	;jump if set
	btst	#2,(BA_PS_flags).w	;check if bit 2 set (cleared on Faceoffs)
	bne.w	.chkbreak	;jump if set
	jsr	(BreakawayOffsidesFlagSet).l
	beq.w	.chkbreak
	move.w	#$22,d0	;'"'   ; 22 - assbreakaway if flag set
	bsr.w	assreplace	;assreplace with assbreakaway
	bra.w	*+4
.chkbreak
	bclr	#1,pflags(a3)	;pfna - clear new assignment
	beq.w	.nna
	btst	#pf3break,pflags3(a3)	;check if breakaway
	beq.w	.chkbreak2	;jump if not
	move.w	#SFXbeep1,-(sp)	;ding SFX
	jsr	(sfx).l
.chkbreak2
	btst	#pf3break,pflags3(a3)	;check if breakaway
	beq.w	.nobreak	;jump if not
	movem.l	a2,-(sp)	;push a2 to stack
	movea.l	#tmstruct,a2	;put Home Team Struct into a2
	btst	#6,pflags(a3)	;pfteam - check home or away
	beq.w	.addcrowd	;jump if home
	movea.l	#AwShots,a2	;put Away Team Struct into a2
.addcrowd
	addq.w	#1,$358(a2)	;add to breakaway attempt
	addi.w	#$14,(CwdExciteLvl).w	;add to excite level
	addi.w	#$C8,(crowdlevel).w	;add to crowd level
	movem.l	(sp)+,a2	;pop off stack into a2
.nobreak
	clr.w	temp3(a3)	;clear temp3
	move.w	#8,temp2(a3)	;move 8 into temp2
	clr.w	temp1(a3)	;clear temp1
.nna
	move.w	SCnum(a3),d1	;checks if puck carrier
	cmp.w	(puckc).w,d1
	bne.w	.nopc	;jumps if not
	tst.w	position(a3)	;check if goalie
	beq.w	assgoaliecpu	;branch if goalie
	move.l	#$10,d0	;10 = asspuckc
	btst	#pfjoycon,pflags(a3)	;pfjoycon - check if controlled
	beq.w	assinsert	;jump if not
	rts
.nopc
	sub.b	d7,temp1(a3)	;subtract d7 (elapsed frames) from temp1
	bpl.w	.nodec	;jump if positive
	move.b	aioff(a3),temp1(a3)	;move aioff into temp1
	jsr	(ReadGoaliePulled).l	;check if goalie is pulled
	bmi.w	.bonus
	btst	#6,(sflags7).w	;check if crowd meter currently broken
	beq.w	.nopc2	;jump if not broken
	tst.b	temp1(a3)	;check if temp1 is 0
	beq.w	.nopc2	;jump if so
.bonus
	subq.b	#1,temp1(a3)	;subtract 1 from temp1
.nopc2
	btst	#5,(sflags6).w	;check if slot bit is set (puckc in slot)
	beq.w	.nopc3	;branch if not set
	move.w	(puckc).w,d1	;move puck carrier SCnum
	cmp.w	#5,d1	;check if its home (5 or less) or away (6-11)
	bgt.w	.pcaway	;jump if away
	btst	#6,pflags(a3)	;pfteam
	beq.w	.nopc3	;jump if home
.tmnopc
	move.b	temp1(a3),d1	;temp1 into d1
	ext.w	d1	;extend d1
	asr.w	#1,d1	;divide by 2
	move.b	d1,temp1(a3)	;move d1 into temp1 - cutting the timer in half
	bne.w	.nopc3	;jump if not zero
	move.b	#1,temp1(a3)	;move 1 into temp1
	bra.w	.nopc3
.pcaway
	btst	#6,pflags(a3)	;pfteam - 0 home, 1 away
	beq.s	.tmnopc	;jump if home
.nopc3
	clr.l	Yvel(a2)	;Calculated future Ypos of the player closest to the puck
	move.w	(puckc).w,d1	;move puck carrier SCnum into d1
	bmi.w	.np	;branch if no puck carrier
	asl.w	#7,d1	;scsize
	movea.w	#(SortCords-M68K_RAM),a1	;Move SortCords into a1
	adda.w	d1,a1	;use d1 as offset
	move.b	pflags(a1),d0	;pflags of puck carrier
	move.b	pflags(a3),d1	;pflags of current player
	eor.b	d0,d1	;XOR pflags
	btst	#pfteam,d1	;check pfteam
	beq.w	.switch	;branch if on same team
.np
	moveq	#-1,d2	;-1
	moveq	#5,d4	;5 = # of players on team
	movea.w	tmsort(a2),a0	;SortCord start value for team
.de0
	tst.w	position(a0)	;check if goalie
	ble.w	.next	;branch if goalie
	tst.b	nopuck(a0)	;check if nopuck (cant touch puck)
	bne.w	.next	;branch if nopuck timer not 0
	btst	#2,pflags2(a0)	;pf2unav - unavailable
	bne.w	.next	;branch if unavailable
	move.w	assnum(a0),d0	;assnum - current assignment
	cmpi.b	#$13,asslist(a0,d0.w)	;check if current assignment is asspassrec
	beq.w	.next	;branch if a0 is going to receive puck
	move.l	a0,-(sp)	;push onto stack
	bsr.w	GetHot	;get hot spot
	add.w	(a0),d0	;Xpos to d0
	sub.w	(puckx).w,d0	;sub puck Xpos
	add.w	Ypos(a0),d1	;add Ypos to d1
	sub.w	(pucky).w,d1	;sub puck Ypos
	move.w	(puckvx).w,d3	;puckvx into d3
	asr.w	#6,d3	;divide by 64
	sub.w	d3,d0	;sub d3 from d0 (X distance between player and puck)
	move.w	(puckvy).w,d3	;puckvy into d3
	asr.w	#6,d3	;divide by 64
	sub.w	d3,d1	;sub d3 from d1 (Y distance between player and puck)
	muls.w	d0,d0	;square d0
	muls.w	d1,d1	;square d1
	add.l	d1,d0	;add d1 to d0
	cmp.l	d2,d0	;compare d2 to d0
	bhi.w	.next	;branch if d0 higher than d2 (0 or a positive # first run)
	move.l	d0,d2	;move d0 into d2
	movea.w	a0,a1	;move a0 address into a1
.next
	adda.w	#SCstruct,a0	;SCstruct size
	dbf	d4,.de0	;iterate through loop
	tst.l	d2	;check if 0
	bmi.w	.de1	;branch if less (no one near puck)
	move.l	d2,Yvel(a2)	;moves d2 into $2A(a2)
.switch
	cmpa.w	a1,a3	;a1 = closest to the puck, or puckc (if on same team)
	beq.w	.de1	;branch if same
	btst	#gmclock,(gmode).w	;gmclock - 1 if stopped
	bne.w	.de1	;jump if stopped
	btst	#2,pflags2(a1)	;pf2unav
	bne.w	.de1	;jump if unavailable
	btst	#pf3onetimer,pflags3(a1)	;shooting one timer
	bne.w	.de1	;jump if shooting
	exg	a1,a3	;swap addresses
	bclr	#pfdoff,pflags(a3)	;clear pfdoff
	move.l	#$11,d0	;assnearest
	bsr.w	assinsert
	exg	a1,a3
	bra.w	assexit
.de1
	btst	#pfalock,pflags(a3)	;pfalock - check if locked in animation
	bne.w	rtss2	;exit if locked
	moveq	#2,d1	;move 2 into d1
	cmp.w	#$190,d2	;compare $190 (20^2) to d2. d2 = distance to puck^2
	bhi.w	.nfar	;branch if d2 higher
	subq.w	#2,d1
	cmpi.w	#2,position(a3)	;compare if position is F or D (1 and 2 are D)
	bls.w	.nodec	;jump if D
.nfar
	btst	#sf2pwrplay,(sflags2).w	;sf2pwrplay - check if PP
	beq.w	.x	;branch if no PP
	subq.w	#2,d1	;sub 2 from d1
	bsr.w	chkpk2
	bne.w	.x	;branch if on PK
	addq.w	#4,d1	;add 4 to d1
.x
	move.w	#$28,d0	;'('   ; move $28 into d0 (40 dec)
	sub.b	checking(a3),d0	;sub checking from d0
	asl.w	d1,d0	;shift d0 by value of d1
	bsr.w	randomd0	;RNG
	cmp.w	#2,d0	;compare 2 to d0
	bhi.w	.nodec	;branch if d0 more than 2
	move.w	#$F0,temp3(a3)	;move 240 dec into temp3
.nodec
	btst	#pfalock,pflags(a3)	;pfalock - check if anim lock
	bne.w	rtss2	;exit if locked
	btst	#2,(BA_PS_flags).w	;check bit 2
	beq.w	.gmclock	;jump if not set
	btst	#5,(BA_PS_flags).w	;check bit 5
	beq.w	.nodec2	;jump if not set
.gmclock	;clock running?
	btst	#0,(gmode).w	;check if clock running
	bne.w	donothing	;branch if not
.nodec2
	btst	#pfjoycon,pflags(a3)	;pfjoycon - check if controlled
	bne.w	rtss2	;jump if controlled
	btst	#2,tmflags(a2)	;check bit 2 of $30(a2)
	bne.w	.nodec22
	tst.w	(puckc).w	;check if theres a puck carrier
	bmi.w	.topuck	;jump if no puck carrier
	sub.w	d7,temp3(a3)	;subtract frames from temp3
	bpl.w	.topuck	;jump if positive
	clr.w	temp3(a3)	;clear temp3
.nodec22
	bsr.w	skatetopuckinit
	movem.w	d0-d1,-(sp)	;d0 = future puckx, d1 = future pucky push on stack
	neg.w	d0
	neg.w	d1
	addi.w	#$F4,d1	;add goalline - 20 decimal
	btst	#pfgoal,pflags(a3)	;pfgoal - check what net shooting on
	beq.w	.nd0	;branch if bottom
	subi.w	#$1E8,d1	;sub bottom goalline - 20 decimal
.nd0
	asr.w	#1,d0	;divide by 2
	asr.w	#1,d1	;divide by 2
	add.w	(sp)+,d0	;add original future puckx
	add.w	(sp)+,d1	;add original future pucky
	btst	#2,tmflags(a2)	;?? - doesn't seem to be set anywhere
	beq.w	.spdboost
	btst	#pfgoal,pflags(a3)	;pfgoal
	beq.w	.botshoot	;branch if bottom
	cmp.w	#$53,d1	;'S'   ; check if y pos of puck near blue line
	blt.w	.spdboost	;branch if in neutral zone or D zone
	move.w	#$44,d1	;'D'   ; move 44 hex into d1
	bra.w	.spdboost
.botshoot
	cmp.w	#$FFAD,d1	;check if pucky near bottom blue line
	bgt.w	.spdboost	;branch if in neutral zone or D zone
	move.w	#$FFBC,d1	;move FFBC into d1
.spdboost
	btst	#5,(sflags6).w	;check if puckc is in the slot
	beq.w	.noslot	;branch if not
	move.b	legspd(a3),(TempLegSpd).w	;legspd into FFBF1E
	addq.b	#6,legspd(a3)	;add 6 to legspd
	btst	#1,(sflags8).w	;check if crowd meter broken (always is)
	bne.w	.spdboostex	;jump if set
	btst	#6,(sflags7).w	;check if crowd meter currently broken
	beq.w	.spdlimit	;jump if not set
.spdboostex
	addq.b	#2,legspd(a3)
.spdlimit
	cmpi.b	#$1E,legspd(a3)	;check speed limit
	ble.w	.cont
	move.b	#$1E,legspd(a3)	;limit legspd to $1E (30 decimal)
.cont
	lea	rtss2(pc),a0
	bsr.w	skateto
	move.b	(TempLegSpd).w,legspd(a3)	;move original legpsd back into player
	bra.w	.chkslot
.noslot
	lea	rtss2(pc),a0
	bsr.w	skateto
.chkslot
	btst	#5,(sflags6).w
	beq.w	.chkcont
	move.w	(pucky).w,d0
	move.w	Ypos(a3),d2	;Ypos into d2
	tst.w	d0	;check if d0 is 0
	bpl.w	.pospuck	;branch if positive
	neg.w	d0	;make d0 negative
	neg.w	d2	;make d2 negative
.pospuck
	sub.w	d0,d2	;sub d0 from d2 (equals how far puck is from player Ypos)
	cmp.w	#$A,d2	;check difference with A (10 decimal)
	blt.w	.exit
	move.w	(a3),d0	;Xpos of player (gets here if player is between net and puck carrier)
	sub.w	(puckx).w,d0	;sub puckx from Xpos
	bpl.w	.chkx	;branch if positive difference
	neg.w	d0	;make d0 negative
.chkx
	cmp.w	#$F,d0	;compare F (15 dec) with Xpos difference
	blt.w	.chkcont	;branch if less than (within 15 pix in X direction)
.exit
	rts
.chkcont
	btst	#5,(sflags6).w	;check if puckc is in the slot
	beq.w	check4check	;branch if not in slot
	move.b	checking(a3),d0	;move Chk into d0
	ext.w	d0	;clear top byte of d0
	movem.l	d0/a3,-(sp)	;push to stack
	add.b	d0,d0	;add d0 to itself
	cmp.b	#$1E,d0	;compare max Chk to d0
	blt.w	.chkcont2	;branch if less
	move.b	#$1E,d0	;move 1E into d0
.chkcont2
	move.b	d0,checking(a3)	;move d0 into Chk
	bsr.w	check4check
	movem.l	(sp)+,d0/a3	;pop off stack
	move.b	d0,checking(a3)	;move original Chk into player
	rts
.topuck
	bsr.w	skatetopuck
; look for good opportunity for checking opponent
; a3 = player
check4check
	tst.w	position(a3)	;check if goalie
	bne.w	.player	;branch if not
	rts
.player
	move.w	#$28,d0	;'('   ; start with 28 hex (40 decimal)
	sub.b	checking(a3),d0	;subtract Chk from d0 (Chk max is 1E or 30 decimal)
	tst.w	(OptPen).w	;check for penalties option
	beq.w	.nopen	;branch if not on
	asl.w	#1,d0	;mult by 2
.nopen
	bsr.w	randomd0	;RNG d0
	cmp.w	#6,d0	;compare 6 to d0
	bhi.w	rtss2	;exit if d0 higher than 6
	moveq	#5,d2	;move 5 into d2
	movea.w	#(SortCords-M68K_RAM),a0
	cmpi.w	#6,SCnum(a3)	;check if player on home team
	bge.w	.0	;branch if away
	adda.w	#6*SCstruct,a0	;add if home (checks opposite team in loop)
.0
	tst.w	position(a0)	;check if goalie
	beq.w	.next	;branch if goalie
	btst	#pfalock,pflags(a0)	;check if locked in anim
	bne.w	.next	;branch if locked
	btst	#pf2fight,pflags2(a0)	;check if fighting
	bne.w	.next	;branch if fighting
	move.w	(a0),d0	;move Xpos into d0
	sub.w	(a3),d0	;sub a3 from a0
	cmp.w	#$1E,d0	;compare to 30 decimal
	bgt.w	.next	;branch if more than 30 decimal
	cmp.w	#$FFE2,d0	;compare to -30 decimal
	blt.w	.next	;branch if less than -30
	move.w	Ypos(a0),d1	;Ypos
	sub.w	Ypos(a3),d1	;subtract checker Ypos from d1
	cmp.w	#$1E,d1	;compare to 30 decimal
	bgt.w	.next	;branch if more
	cmp.w	#$FFE2,d1	;check with -30 decimal
	blt.w	.next	;branch if less
	bsr.w	vtoa	;determine direction
	cmp.w	facedir(a3),d0	;compare facedir with vtoa result
	bne.w	.next	;branch if not facing in that direction
	btst	#5,(sflags6).w	;check if puckc in slot
	bne.w	Acheck	;branch if in slot
	move.w	(VDP_CNTR).l,d0	;move HVcounter into d0
	andi.w	#3,d0	;pass first 2 bits
	bne.w	burst	;throw check
	bra.w	Acheck
.next
	adda.w	#SCstruct,a0	;move to next SCstruct
	dbf	d2,.0
	rts
; assignment for catching pass
asspassrec
	btst	#pfalock,pflags(a3)	;pfalock - animation lock
	bne.w	rtss2	;exit if locked
	btst	#gmclock,(gmode).w	;gmclock - check if clock running
	bne.w	donothing	;exit if clock stopped
	btst	#pfjoycon,pflags(a3)	;pfjoycon - joystick controlled?
	bne.w	assexit	;exit if controlled
	bclr	#pfna,pflags(a3)	;#pfna - clear new assignment
	beq.w	.nna
	bset	#pfdoff,pflags(a3)	;#pfdoff - set decceleration off
	move.b	#8,temp2+1(a3)	;move into temp2+1
	clr.b	temp2(a3)	;clear temp2 byte
	move.w	#$FFFE,temp4(a3)	;move into temp4
.nna
	tst.w	(puckc).w	;check if there is a puck carrier
	bpl.w	.exit	;exit if puck still in possession
	addq.w	#1,temp4(a3)	;add to temp4
	beq.w	.0	;branch if temp4 is zero
	bpl.w	.ex2	;branch if temp4 is positive
.0
	tst.w	(onetimerplayer).w
	bpl.w	.ex2
	tst.w	position(a3)	;test if goalie
	beq.w	.ex2	;exit if goalie
	move.w	d0,-(sp)	;push d0 on stack
	clr.w	temp4(a3)	;clear temp4
	move.w	#1,d0
	btst	#6,pflags(a3)	;check if home or away
	beq.w	.1
	move.w	#2,d0	;away team
.1
	cmp.w	(cont1team).w,d0	;check if player on cont 1 team
	beq.w	.pop	;branch if so
	cmp.w	(cont2team).w,d0	;check if player on cont 2 team
	beq.w	.pop	;branch if so
	jsr	(PuckOnAttackHalf).l
	beq.w	.pop
	move.w	Ypos(a3),d0	;Ypos
	btst	#7,pflags(a3)	;pfgoal
	bne.w	.chkpos	;branch if shooting at top
	neg.w	d0
.chkpos
	cmp.w	#$58,d0	;'X'   ; blueline
	blt.w	.nozone
	cmp.w	#$108,d0	;goalline
	bgt.w	.nozone
	bra.w	.atkzone
.nozone
	move.w	#8,d0	;outside of attack zone
	jsr	(randomd0).l
	tst.w	d0	;check if d0 is zero
	bne.w	.pop
.atkzone
	move.w	(sp)+,d0
	move.w	#$FFFF,(inputjoy).w
	move.w	#$23,d0	;'#'   ; assonetimer
	jmp	assreplace
.pop
	move.w	(sp)+,d0
.ex2
	sub.b	d7,temp1(a3)
	bpl.w	rtss2
.exit
	bclr	#pfdoff,pflags(a3)
	bra.w	assexit
SkateToTempTarget	;unreferenced. Skate to temp3 / temp4, then rts
	move.w	temp3(a3),d0		;temp3
	move.w	temp4(a3),d1		;temp4
	lea	rtss2(pc),a0
	bra.w	skateto

; assignment for computer shooting
assshoot
	btst	#pfalock,pflags(a3)	;pfalock - animation locked
	bne.w	rtss2
	bclr	#pfna,pflags(a3)	;clear pfna
	beq.w	.nna
	bra.w	SetShotMode
.nna
	btst	#sfssdir,(sflags).w	;#sfssdir
	beq.w	assexit
	clr.w	d2
	sub.w	d7,temp2(a3)
	bpl.w	ShotMode
	bset	#5,d2	;#cbut
	bra.w	ShotMode
puckshootout	;puck logic for the shootout: on a new assignment clear the pads and select the skater, then run the attempt
	bclr	#1,pflags(a3)
	beq.w	.selectskater
	bset	#7,(sflags7).w
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	clr.l	(padcont+8).w
	bclr	#7,(gmode2).w
	btst	#0,(gmode2).w
	beq.w	.startattempt
	jsr	(NextShooter).l
	bra.w	.initflags
.startattempt
	jsr	(StartShootoutPath).l
	move.l	a2,-(sp)
	movea.l	#tmstruct,a2
	tst.w	(BA_Team).w
	beq.w	.countattempt
	movea.l	#AwShots,a2
.countattempt
	addq.w	#1,$360(a2)
	movea.l	(sp)+,a2
.initflags
	bclr	#2,(BA_PS_flags).w
	bclr	#4,(BA_PS_flags).w
	bclr	#5,(BA_PS_flags).w
	bclr	#6,(BA_PS_flags).w
	bset	#1,(sflags6).w
	btst	#3,(gmode).w
	bne.w	Stop4Pen
	bclr	#1,pflags(a3)
	btst	#0,(gmode2).w
	beq.w	.selectsong
	tst.w	(shootoutteam).w
	bne.w	.setstopped
	tst.w	(homeshootnum).w
	bne.w	.setstopped
	move.w	(HomeTeam).w,(HmTeam).w
	move.w	#2,(SongIndex).w
	jsr	(ChooseSong).l
	move.w	(SongNum).w,-(sp)
	bra.w	.playsong
.selectsong
	move.w	(HomeTeam).w,(HmTeam).w
	move.w	#2,(SongIndex).w
	jsr	(ChooseSong).l
	move.w	(SongNum).w,-(sp)
.playsong
	bsr.w	song
.setstopped
	bset	#0,(gmode).w
	bset	#1,(gmode2).w
	clr.w	(puckvx).w
	clr.w	(puckvy).w
	move.w	#$19,(shootoutclock).w
	bsr.w	ReturnGoalies
	st	temp1(a3)
	st	temp2(a3)
.selectskater
	bset	#2,(BA_PS_flags).w
	movem.w	d1-d2,-(sp)
	jsr	(SelectPenaltyShotSkater).l
	bmi.w	.noeligible
	movem.w	(sp)+,d1-d2
	bra.w	.checkgoalie
.noeligible
	movem.w	(sp)+,d1-d2
	bclr	#2,(BA_PS_flags).w
	move.w	#$1B,d0	;puckfaceoff
	bsr.w	assreplace
	rts
.checkgoalie
	movem.w	d1-d2,-(sp)
	move.w	(BA_Goalie_SCnum).w,d0
	movea.l	#SortCords,a2
	asl.w	#7,d0
	adda.w	d0,a2
	tst.w	$34(a2)
	bne.w	.findgoalie
	btst	#2,pflags2(a2)
	beq.w	.startpenshot
.findgoalie
	move.w	(BA_Goalie_SCnum).w,d0
	move.w	#6,d2
.goalieloop
	subq.w	#1,d2
	bmi.s	.noeligible
	subq.w	#1,d0
	bpl.w	.wraphome
	move.w	#5,d0
	bra.w	.checkcandidate
.wraphome
	cmp.w	#5,d0
	bne.w	.checkcandidate
	move.w	#$B,d0
.checkcandidate
	movea.l	#SortCords,a2
	move.w	d0,d1
	asl.w	#7,d1
	adda.w	d1,a2
	tst.w	$34(a2)
	bne.s	.goalieloop
	btst	#2,pflags2(a2)
	bne.s	.goalieloop
	move.w	d0,(BA_Goalie_SCnum).w
.startpenshot
	movem.w	(sp)+,d1-d2
	movea.w	#(tmstruct-M68K_RAM),a2
	move.w	#$1F,d0	;puckpenshot
	bra.w	assreplace
SelectPenaltyShotSkater	;pick the skater for the penalty shot from team BA_Team
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#tmstruct,a0
	tst.w	(BA_Team).w
	beq.w	.hometeam
	movea.l	#AwShots,a0
.hometeam
	move.w	#0,d1
	move.w	#$FFFF,d6
	move.w	#$FFFF,d5
	movea.l	$1E(a0),a2
	adda.w	(a2),a2
.playerloop
	cmpi.w	#2,(a2)
	beq.w	.doneplayers
	adda.w	(a2),a2
	move.w	d1,d7
	asl.w	#1,d7
	move.b	5(a2),d0
	andi.w	#$F,d0
	cmp.b	#1,d0
	ble.w	.nextplayer
	btst	#0,(gmode2).w
	bne.w	.setskaterscnum
	cmpi.w	#$FFFE,$66(a0,d7.w)
	beq.w	.scorecandidate
	cmpi.w	#$FFFF,$66(a0,d7.w)
	bne.w	.nextplayer
.scorecandidate
	clr.w	d3
	clr.w	d0
	move.b	1(a2),d0
	andi.w	#$F,d0
	add.w	d0,d3
	move.b	2(a2),d0
	andi.w	#$F,d0
	add.w	d0,d3
	move.b	2(a2),d0
	andi.w	#$F0,d0
	lsr.w	#4,d0
	add.w	d0,d3
	move.b	3(a2),d0
	andi.w	#$F,d0
	add.w	d0,d3
	move.b	3(a2),d0
	andi.w	#$F0,d0
	lsr.w	#4,d0
	add.w	d0,d3
	move.b	5(a2),d0
	andi.w	#$F,d0
	add.w	d0,d3
	move.b	5(a2),d0
	andi.w	#$F0,d0
	lsr.w	#4,d0
	add.w	d0,d3
	move.b	6(a2),d0
	andi.w	#$F0,d0
	lsr.w	#4,d0
	add.w	d0,d3
	move.b	7(a2),d0
	andi.w	#$F0,d0
	lsr.w	#4,d0
	add.w	d0,d3
	cmp.w	(BA_Skater_Offset).w,d1
	bne.w	.comparebest
	move.w	#$7FFF,d3
.comparebest
	cmp.w	d6,d3
	blt.w	.nextplayer
	move.w	d3,d6
	move.w	d1,d5
	bra.w	*+4
.nextplayer
	addq.l	#8,a2
	addq.w	#1,d1
	cmp.w	#$1A,d1
	blt.w	.playerloop
.doneplayers
	tst.w	d5
	bmi.w	.noeligible
	move.w	d5,(BA_Skater_Offset).w
.setskaterscnum
	move.w	#0,(BA_Sktr_SCnum).w
	tst.w	(BA_Team).w
	beq.w	.loadskater
	move.w	#6,(BA_Sktr_SCnum).w
.loadskater
	move.w	(BA_Sktr_SCnum).w,d0
	asl.w	#7,d0
	movea.l	#SortCords,a3
	adda.w	d0,a3
	move.w	(BA_Skater_Offset).w,d3
	bra.w	.eligible
.noeligible
	move.w	#$FFFF,d0
	bra.w	.exit
.eligible
	move.w	#1,d0
.exit
	movem.l	(sp)+,d0-d7/a0-a6
	rts
; puck start for penalty shot/shootout
puckpenshot
	bclr	#1,pflags(a3)
	beq.w	.resumeplay
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack
.waitvblank
	btst	#0,(disflags).w
	bne.s	.waitvblank
	cmpi.w	#$258,(crowdlevel).w
	bls.w	.setuprink
	move.w	#$258,(crowdlevel).w
	addi.w	#$14,(CwdExciteLvl).w
.setuprink
	move.w	(ExtraChars).w,d4
	movea.l	#RefsMap+8,a2
	jsr	(DecompressGraphicsPlain).l
	bset	#3,(disflags).w
	bclr	#0,(sflags).w
	bclr	#0,(sflags3).w
	clr.w	(glovecords).w
	clr.b	(iflags).w
	st	(RefCnt).w
	bclr	#1,(sflags2).w
	st	(passplayer).w
	bsr.w	ClrHor
	clr.w	(Vpos).w
	clr.w	(Hpos).w
	move.w	#0,(puckx).w
	move.w	#0,(pucky).w
	clr.w	(puckz).w
	clr.w	(puckvx).w
	clr.w	(puckvy).w
	clr.w	(puckvz).w
	st	(puckc).w
	movea.w	#(SortCords+(12*SCstruct)-M68K_RAM),a0	;goal net SCstruct
	clr.w	$28(a0)
	clr.w	$2A(a0)
	clr.w	(a0)
	move.w	#$10C,$14(a0)
	adda.w	#$80,a0	;move to second goal net SCstruct
	clr.w	$28(a0)
	clr.w	$2A(a0)
	clr.w	(a0)
	move.w	#$FEF4,$14(a0)
	movea.w	#(SortCords+((puckscnum+1)*SCstruct)-M68K_RAM),a0	;puck shadow SCstruct
	move.w	#$18A,6(a0)
	clr.w	$58(a0)
	clr.w	4(a0)
	clr.w	(SortCords+(puckscnum*SCstruct)+attribute).w
	bclr	#6,(sflags).w
	moveq	#$64,d4
.scrollloop
	bsr.w	checkwindow
	dbf	d4,.scrollloop
	move.w	#$3C,(yleader).w
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	setpersonel
	bsr.w	SetupPenaltyShot
	adda.w	#$364,a2
	bsr.w	setpersonel
	bsr.w	SetupPenaltyShot
	jsr	(resetplstuff).l
	move.l	a3,-(sp)
	movea.l	#SortCords+(11*SCstruct),a3	;away goalie SCstruct
	move.w	#$B,d2	;11 = # of player SCstructs
.playerloop
	cmp.w	(BA_Sktr_SCnum).w,d2
	beq.w	.setupskater
	cmp.w	(BA_Goalie_SCnum).w,d2
	beq.w	.setupgoalie
	move.w	#$FF10,(a3)
	clr.w	Ypos(a3)
	clr.w	6(a3)
	move.w	#$20,d0
	bsr.w	assinsert
	bra.w	.nextplayer
.setupskater
	tst.w	position(a3)
	bpl.w	.placeskater
	bclr	#2,pflags2(a3)
	beq.w	.placeskater
	movem.l	d0-d7/a0-a6,-(sp)
	clr.w	d3
	move.b	pnum(a3),d3
	jsr	(setplayer).l
	movem.l	(sp)+,d0-d7/a0-a6
	tst.w	position(a3)
	beq.w	.skaterready
	bpl.w	.placeskater
.skaterready
	nop
.placeskater
	move.w	(puckx).w,d0
	subi.w	#0,d0
	move.w	d0,(a3)
	move.w	(pucky).w,d0
	btst	#7,pflags(a3)
	bne.w	.skaterattop
	addi.w	#$10,d0
	move.w	#4,facedir(a3)
	bra.w	.setskaterpos
.skaterattop
	addi.w	#-$10,d0
	move.w	#0,facedir(a3)
.setskaterpos
	move.w	d0,Ypos(a3)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	clr.w	Zvel(a3)
	move.w	#$11,d0
	bsr.w	assinsert
	bra.w	.nextplayer
.setupgoalie
	btst	#0,(gmode2).w
	beq.w	.goalieactive
	move.b	(shootoutteam-1).w,pnum(a3)
	tst.w	(shootoutteam).w
	beq.w	.loadgoalieplayer
	move.b	(homeshootnum-1).w,pnum(a3)
	bra.w	.loadgoalieplayer
.goalieactive
	tst.w	position(a3)
	bpl.w	.placegoalie
	bclr	#2,pflags2(a3)
	beq.w	.placegoalie
.loadgoalieplayer
	movem.l	d0-d7/a0-a6,-(sp)
	clr.w	d3
	move.b	pnum(a3),d3
	jsr	(setplayer).l
	movem.l	(sp)+,d0-d7/a0-a6
	tst.w	position(a3)
	bne.w	.goalieok
	bpl.w	.placegoalie
.goalieok
	nop
.placegoalie
	bclr	#2,pflags2(a3)
	move.w	#0,d0
	move.w	#$E5,d1
	btst	#7,pflags(a3)
	bne.w	.goalieattop
	move.w	#$FF1B,d1
.goalieattop
	move.w	d0,(a3)
	move.w	d1,Ypos(a3)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	clr.w	Zpos(a3)
	sub.w	(puckx).w,d0
	sub.w	(pucky).w,d1
	neg.w	d0
	neg.w	d1
	bsr.w	vtoa
	move.w	d0,facedir(a3)
	bclr	#2,pflags2(a3)
	bclr	#5,pflags(a3)
	move.w	#$50C,d1
	bsr.w	SetSPA
.nextplayer
	suba.l	#$80,a3
	dbf	d2,.playerloop	;cycle to next player
	bsr.w	SprSort
	movea.l	(sp)+,a3
	bsr.w	ResetAndSelectPlayers
	move.w	(BA_Goalie_SCnum).w,d0
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	move.w	#0,(a3)
	move.w	#$FF06,Ypos(a3)
	btst	#7,pflags(a3)
	bne.w	.goalieatbottom
	move.w	#$FA,Ypos(a3)
.goalieatbottom
	move.w	(BA_Goalie_SCnum).w,d0
	move.w	#1,d1
	btst	#6,pflags(a3)
	beq.w	.checkcont1
	move.w	#2,d1
.checkcont1
	cmp.w	(cont1team).w,d1
	bne.w	.checkcont2
	jsr	(setc1player).l
	bra.w	.setgoalieassignment
.checkcont2
	cmp.w	(cont2team).w,d1
	bne.w	.setgoalieassignment
	jsr	(setc2player).l
.setgoalieassignment
	move.w	#$E,d0	;assignment D51C?
	bsr.w	assreplace
	bset	#7,(BA_PS_flags).w
	bset	#2,(sflags2).w
	move.w	#$190,(msgtimer).w
	tst.w	(cont1team).w
	bne.w	.finishsetup
	tst.w	(cont2team).w
	bne.w	.finishsetup
	move.w	#$64,(msgtimer).w
.finishsetup
	move.w	#$18,(palcount).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
.resumeplay
	bset	#2,(gmode2).w
	move.w	#$18,d0	;pucknorm
	bsr.w	assreplace
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	rts
	dc.b	0,1,2,3,4,5,6,0,0,1,5,3,4,2,0,0
	dc.b	0,3,5,1,4,0,0,0,0,0,$FF,6,$FF,$DD,$FF,$CE
	dc.b	0
	dc.b	$23	;#
	dc.b	$FF,$CE,$FF,$CE,$FF,$F6,0,0,$FF,$F1,0
	dc.b	$32	;2
	dc.b	$FF,$F6,0,0,$FF,$C4
UpdatePenaltyShotEnd	;end the penalty shot when the goalie has the puck, the puck is loose or the timer runs out
	movem.w	d0,-(sp)
	move.w	(puckc).w,d0
	cmp.w	(BA_Goalie_SCnum).w,d0
	movem.w	(sp)+,d0
	beq.w	.setended
	btst	#5,(BA_PS_flags).w
	beq.w	.checktimer
	btst	#5,(gmode2).w
	bne.w	.puckloose
	tst.w	(puckc).w
	bpl.w	.countdown
	bset	#5,(gmode2).w
.puckloose
	tst.w	(puckc).w
	bpl.w	.setended
.countdown
	tst.w	(passmodetimer).w
	bmi.w	.setended
	subq.w	#1,(passmodetimer).w
	bra.w	.checktimer
.setended
	bset	#4,(BA_PS_flags).w
.checktimer
	tst.w	(shootoutclock).w
	bne.w	.checkended
	bset	#4,(BA_PS_flags).w
.checkended
	btst	#4,(BA_PS_flags).w
	bne.w	.finishshot
	rts
.finishshot
	btst	#6,(BA_PS_flags).w
	bne.w	PenaltyShotEndReturn
	bset	#6,(BA_PS_flags).w
	move.w	#$A,d0
	jsr	(AddPenalty2).l
EndPenaltyShotPlay	;stop play after a penalty shot or shootout attempt: freeze the window, stop the clock, clear the penalty shot flags
	jsr	(freezewindow).l
	btst	#0,(gmode2).w
	bne.w	.stopplay
	move.w	#$A,(replaydelay).w
	bset	#2,(sflags2).w
.stopplay
	bset	#0,(gmode).w
	bclr	#2,(gmode2).w
	bclr	#2,(BA_PS_flags).w
	bclr	#3,(BA_PS_flags).w
	bclr	#5,(BA_PS_flags).w
	bclr	#4,(BA_PS_flags).w
	bclr	#6,(BA_PS_flags).w
	movem.l	d0/a0,-(sp)
	movea.l	#SortCords,a0
	move.w	(BA_Sktr_SCnum).w,d0
	asl.w	#7,d0
	move.b	(savednewpnum).w,$61(a0,d0.w)
	movem.l	(sp)+,d0/a0
	jsr	(CountShootoutGoals).l
PenaltyShotEndReturn
	rts
; this is where the action starts
puckfaceoff
	bclr	#4,(sflags8).w
	btst	#0,(gmode2).w
	beq.w	.normalfaceoff
	clr.w	(puckvx).w
	clr.w	(puckvy).w
	move.w	#$1E,d0	;assignment ECB6?
	bra.w	assreplace
.normalfaceoff
	bclr	#1,pflags(a3)
	beq.w	WaitForFaceoffLineChanges
	bclr	#0,(sflags8).w
	beq.w	.resetpads
	clr.w	(fox).w
	clr.w	(foy).w
.resetpads
	bclr	#7,(sflags7).w
	clr.l	(padcont).w
	clr.l	(padcont+4).w
	clr.l	(padcont+8).w
	bclr	#6,(sflags7).w
	bclr	#2,(sflags7).w
	jsr	(CheckScoreLeader).l
	tst.w	(faceoffanim).w
	bmi.w	.choosefaceoffspot
	move.w	(faceoffanim).w,d0
	bra.w	.handlefaceoffspot
.choosefaceoffspot
	jsr	(RandomFaceoffAnim).l
	tst.w	d0
	bmi.w	.checkperiod
.handlefaceoffspot
	jsr	(SetFaceoffAnim).l
.checkperiod
	bclr	#1,(sflags6).w
	bclr	#1,(gmode2).w
	tst.w	(gameclock).w
	beq.w	PeriodOver
	btst	#6,(gmode).w
	bne.w	PeriodOver
	cmpi.w	#3,(gsp).w
	bne.w	.npo
	move.w	(HmGoals).w,d0
	cmp.w	(AwGoals).w,d0
	bne.w	clockcont_0
.npo
	btst	#gmpendel,(gmode).w
	bne.w	Stop4Pen
	move.w	(PerTimeTotal).w,d0
	asr.w	#1,d0
	cmp.w	(gameclock).w,d0
	bls.w	.returngoalies
	cmpi.w	#$3C,(gameclock).w
	blt.w	.returngoalies
	bclr	#7,(sflags3).w
	beq.w	.returngoalies
	btst	#gmclock,(gmode).w
	beq.w	.returngoalies
	btst	#6,(sflags8).w
	bne.w	.returngoalies
	move.w	(HomeTeam).w,(HmTeam).w
	move.w	#2,(SongIndex).w
	jsr	(ChooseSong).l
	bset	#4,(sflags8).w
.returngoalies
	bsr.w	ReturnGoalies
	st	temp1(a3)
	st	temp2(a3)
	tst.w	(OptLine).w
	bne.w	WaitForFaceoffLineChanges
	bclr	#1,(tmstruct+tmflags).w
	bclr	#1,(AwShots+tmflags).w
	movea.w	#(SortCords-M68K_RAM),a0
	moveq	#$B,d0
.clearlcmloop
	bclr	#3,pflags2(a0)
	adda.w	#SCstruct,a0
	dbf	d0,.clearlcmloop
	move.w	(cont1team).w,d0
	or.w	(cont2team).w,d0
	beq.w	.checkc1line
	btst	#sfhor,(sflags).w
	beq.w	.checkc1line
	bsr.w	forceblack
	bset	#sfslock,(sflags).w
	bsr.w	ClrHor
	move.w	#$18,(palcount).w
	tst.w	(OptLine).w
	bne.w	.checkc1line
	btst	#4,(sflags7).w
	beq.w	.checkc1line
	clr.w	(palcount).w
.checkc1line
	move.w	(c1playernum).w,d0
	bmi.w	.checkc2line
	bsr.w	StartFaceoffLineChange
.checkc2line
	move.w	(c2playernum).w,d0
	bmi.w	.checkcomputerline
	bsr.w	StartFaceoffLineChange
.checkcomputerline
	movea.w	#(tmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2
	moveq	#2,d0
	bsr.w	SetFaceoffComputerLine
	bra.w	WaitForFaceoffLineChanges
SetFaceoffComputerLine	;faceoff: start a line change for team d0 when the computer controls it (line changes on)
	tst.w	(OptLine).w
	bne.w	rtss2
	btst	#4,(sflags7).w
	bne.w	.dochange
	cmp.w	(cont1team).w,d0
	beq.w	rtss2
	cmp.w	(cont2team).w,d0
	beq.w	rtss2
.dochange
	bsr.w	CompLine
	bsr.w	setpersonel
	bsr.w	printscores1
	move.w	#$2710,(crowdnoisedelay).w
	rts
StartFaceoffLineChange	;start the line change box for team d0's sort object before a faceoff
	exg	a2,a3
	asl.w	#7,d0
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3
	bclr	#3,pflags2(a3)
	move.l	a2,-(sp)
	bsr.w	SetLCmode
	movea.l	(sp)+,a2
	btst	#3,pflags2(a3)
	beq.w	.exit
	btst	#6,pflags(a3)
	beq.w	.homeplayer
	move.w	#$168,temp2(a2)
	move.w	SCnum(a3),temp4(a2)
	bra.w	.exit
.homeplayer
	move.w	#$258,temp1(a2)
	move.w	SCnum(a3),temp3(a2)
.exit
	exg	a2,a3
	rts
WaitForFaceoffLineChanges	;run both teams' faceoff line change timers (temp1 / temp2); continue when both have run out
	move.w	#$40,d0
	bsr.w	UpdateFaceoffLineChangeTimer
	move.w	#$42,d0
	bsr.w	UpdateFaceoffLineChangeTimer
	tst.w	temp1(a3)
	bpl.w	rtss2
	tst.w	temp2(a3)
	bpl.w	rtss2
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	$364(a2),a1
	moveq	#1,d0
	bsr.w	SetFaceoffComputerLine
	move.w	#$FFFF,(facelcwait).w
	move.w	#$1C,d0	;puckfaceoff2
	bra.w	assreplace
UpdateFaceoffLineChangeTimer	;count down one team's faceoff line change timer at offset d0 of a3
	tst.w	0(a3,d0.w)
	bmi.w	rtss2
	move.w	4(a3,d0.w),d1
	asl.w	#7,d1
	movea.w	#(SortCords-M68K_RAM),a0
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#6,$62(a0,d1.w)
	beq.w	.checkactive
	adda.w	#$364,a2
.checkactive
	btst	#3,$63(a0,d1.w)
	bne.w	.countdown
	st	0(a3,d0.w)
	bra.w	SetLCmode2
.countdown
	sub.w	d7,0(a3,d0.w)
	bpl.w	rtss2
	move.l	a3,-(sp)
	lea	0(a0,d1.w),a3
	btst	#3,pflags2(a3)
	beq.w	.exit
	clr.w	d2
	bsr.w	lcfound
	bsr.w	SetLCmode2
.exit
	movea.l	(sp)+,a3
	rts
; computer pulls goalie on delayed penalty
ChkGoalies
	btst	#gmclock,(gmode).w	;check if clock running
	bne.w	rtss2
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	moveq	#1,d0
	bsr.w	.chkgoalie
	moveq	#2,d0
	exg	a1,a2
.chkgoalie
	tst.w	tmgoalie(a2)	;check for goalie
	bmi.w	rtss2	;no goalie, exit
	move.w	(puckc).w,d1	;move puck carrier SCnum into d1
	bmi.w	rtss2
	subq.w	#6,d1
	cmpa.w	#$C6CE,a2
	beq.w	.chkpen
	not.w	d1	;makes d1 negative if away team
.chkpen
	tst.w	d1
	bpl.w	rtss2
	btst	#gmpendel,(gmode).w	;#gmpendel - delayed penalty called
	beq.w	.nopen
	st	tmgoalie(a2)	;sets to FFFF (no goalie)
	bra.w	setpersonel
.nopen
	cmp.w	(cont1team).w,d0
	beq.w	rtss2	;exit if team is joy controlled
	cmp.w	(cont2team).w,d0
	beq.w	rtss2	;exit if team is joy controlled
	move.w	(pucky).w,d1
	bra.w	CPgoalie
; if computer pulled goalie, look to see if computer should return him
ReturnGoalies
	movea.w	#(tmstruct-M68K_RAM),a2
	lea	tmsize(a2),a1
	moveq	#1,d0
	bsr.w	.r
	moveq	#2,d0
	exg	a1,a2
.r
	cmpi.w	#$FFFF,tmgoalie(a2)
	beq.w	rtss2	;still no goalie
	clr.b	tmgoalie(a2)	;clear for goalie return
	cmp.w	(cont1team).w,d0
	beq.w	rtss2	;exit if team is joy controlled
	cmp.w	(cont2team).w,d0
	beq.w	rtss2	;exit if team is joy controlled
	move.w	(foy).w,d1
; see if computer should pull his goalie
; d1 = Faceoff Y position
CPgoalie
	cmpi.w	#2,(gsp).w	;check if 3rd period
	bne.w	rtss2	;exit if not
	move.w	tmscore(a1),d0	;tmscore
	sub.w	tmscore(a2),d0
	bmi.w	rtss2	;exit if leading in the game
	cmp.w	#2,d0
	bne.w	rtss2	;exit if behind by more than 2
	cmpi.w	#$3C,(gameclock).w	;'<' ; #60
	bgt.w	rtss2	;exit if more than 1 min left
	move.l	a0,-(sp)
	movea.w	tmsort(a2),a0	;moves a player struct address into a0
	btst	#pfgoal,pflags(a0)	;#pfgoal
	movea.l	(sp)+,a0
	bne.w	.0
	neg.w	d1	;if shooting on bottom goal, make d1 negative
.0
	tst.w	d1
	bmi.w	rtss2	;exit if d1 negative (faceoff in own zone)
	st	tmgoalie(a2)	;set to FFFF (no goalie)
	bra.w	setpersonel
; find good line for comp to switch to
CompLine
	movem.l	d0-d2/a0,-(sp)
	moveq	#3,d0
	move.w	tmap(a2),d1	;tmap
	sub.w	tmap(a1),d1
	beq.w	.nopwr
	bpl.w	.0
	addq.w	#2,d0
.0
	move.w	d0,-(sp)	;find pk/pp line
	bsr.w	getlinee
	move.w	d0,d1
	move.w	(sp),d0
	addq.w	#1,d0
	bsr.w	getlinee
	cmp.w	d0,d1
	bge.w	.1
	addq.w	#1,(sp)
.1
	move.w	(sp)+,tmline(a2)	;tmline
.ex
	movem.l	(sp)+,d0-d2/a0
	rts
.nopwr
	cmpa.w	#$C6CE,a2	;find normal line
	bne.w	.away
	moveq	#2,d1
	lea	.hl1(pc),a0
	cmpi.w	#2,(gsp).w
	bne.w	.h0
	move.w	tmscore(a2),d2	;tmscore
	cmp.w	tmscore(a1),d2
	beq.w	.h0
	adda.w	#$E,a0
	bgt.w	.h0
	adda.w	#$E,a0
.h0
	move.w	tmline(a1),d1	;tmline
	asl.w	#1,d1
	move.w	0(a0,d1.w),d0
	bsr.w	getlinee
	cmp.w	#$C00,d0	;#(3*$1000)/4
	bls.w	.away
	move.w	0(a0,d1.w),$16(a2)	;tmline
	bra.s	.ex
.hl1
	dc.w	0
	dc.w	1
	dc.w	2
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	1
	dc.w	2
	dc.w	0
	dc.w	1
	dc.w	2
	dc.w	0
	dc.w	2
	dc.w	0
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	1
.away
	moveq	#2,d1
	lea	.al1(pc),a0
	cmpi.w	#2,(gsp).w
	bne.w	.a0
	move.w	tmscore(a2),d2	;tmscore
	cmp.w	tmscore(a1),d2
	beq.w	.a0
	addq.w	#6,a0
	bgt.w	.a0
	addq.w	#6,a0
.a0
	move.w	(a0)+,d0
	bsr.w	getlinee
	cmp.w	#$C00,d0	;#(19*$1000)/20
	dbhi	d1,.a0
	move.w	-(a0),tmline(a2)	;tmline
	bra.w	.ex
.al1
	dc.w	0
	dc.w	1
	dc.w	2
	dc.w	0
	dc.w	2
	dc.w	1
	dc.w	0
	dc.w	1
	dc.w	0
; face off control logic and general setup for action
puckfaceoff2
	bclr	#1,pflags(a3)
	beq.w	.nna
	bclr	#2,(BA_PS_flags).w
	bclr	#5,(BA_PS_flags).w
	bclr	#0,(sflags4).w
	bclr	#1,(sflags4).w
	bclr	#0,(DelayedPen).w
	bclr	#1,(DelayedPen).w
	bclr	#2,(DelayedPen).w
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	forceblack
.p
	btst	#dfok,(disflags).w
	bne.s	.p
	move	sr,-(sp)
	move.w	#$3C,(holdreset).w
	tst.w	(fox).w
	bne.w	.lockinterrupts
	tst.w	(foy).w
	bne.w	.lockinterrupts
	move.w	#$FFFF,(faceoffanim).w
	bra.w	.limitcrowd
.lockinterrupts
	move	#$2700,sr
.limitcrowd
	cmpi.w	#$258,(crowdlevel).w
	bls.w	.ntm
	move.w	#$258,(crowdlevel).w	;limit crowd level
.ntm
	bset	#dfclock,(disflags).w	;stop clock
	bclr	#sfpz,(sflags).w	;no pause
	bclr	#sf3llcs,(sflags3).w	;no line changes
	clr.w	(glovecords).w	;no fighting gloves
	clr.b	(iflags).w	;no icing
	st	(RefCnt).w	;no refs
	st	(puckcross2).w	;no goalie moves
	st	(puckcross6).w
	bclr	#sf2refref,(sflags2).w	;no ref refresh
	bset	#sf2faceoff,(sflags2).w	;face off in progress
	bset	#sf2drec,(sflags2).w	;dont record yet
	st	(passplayer).w
	st	(onetimerplayer).w
	bset	#4,(disflags).w
	bsr.w	ClrHor	;vertical ice rink
	move.w	#$2710,(crowdnoisedelay).w
	clr.w	(Vpos).w	;clear h/v pos
	clr.w	(Hpos).w
	move.w	(fox).w,(puckx).w
	move.w	(foy).w,(pucky).w
	st	(puckz).w	;no visible puck
	clr.w	(puckvx).w
	clr.w	(puckvy).w
	clr.w	(puckvz).w
	st	(puckc).w
	movea.w	#(SortCords+(12*SCstruct)-M68K_RAM),a0	;reposition goal nets
	clr.w	Xvel(a0)	;Xvel
	clr.w	Yvel(a0)	;Yvel
	clr.w	(a0)	;Xpos
	move.w	#$10C,Ypos(a0)	;Ypos
	adda.w	#SCstruct,a0	;add SCstruct to move to next goal net
	clr.w	Xvel(a0)
	clr.w	Yvel(a0)
	clr.w	(a0)
	move.w	#$FEF4,Ypos(a0)	;Ypos
	movea.w	#(SortCords+((puckscnum+1)*SCstruct)-M68K_RAM),a0	;move to puck shadow SCnum
	move.w	#$18A,frame(a0)	;#SPFpuck, Frame
	clr.w	SPA(a0)	;SPA
	clr.w	attribute(a0)	;attribute
	clr.w	(SortCords+(puckscnum*SCstruct)+attribute).w	;clear puck SCnum attribute
	bclr	#sfslock,(sflags).w
	moveq	#$64,d4
.cw
	bsr.w	checkwindow	;scroll to faceoff spot
	dbf	d4,.cw
	move.w	#$3C,(yleader).w
	bsr.w	ResetBench
	movea.w	#(tmstruct-M68K_RAM),a2
	bsr.w	setpersonel
	bsr.w	forcepldata
	adda.w	#tmsize,a2
	bsr.w	setpersonel
	bsr.w	forcepldata
	bsr.w	resetplstuff
	move.l	a3,-(sp)
	movea.w	#(SortCords-M68K_RAM),a3
	moveq	#$B,d2
.10
	move.w	#$FF10,(a3)	;-240, Xpos
	clr.w	Ypos(a3)	;Ypos
	clr.w	frame(a3)	;frame
	move.w	position(a3),d1	;position
	bmi.w	.next
	beq.w	.goalie1
	move.l	#$16,d0	;#afaceoff - assignment faceoff
	cmp.w	#4,d1	;find the center (position 4)
	bne.w	.11
	movea.w	#(tmstruct-M68K_RAM),a2
	btst	#pfteam,pflags(a3)	;#pfgoal - what goal to score on
	beq.w	.clr
	adda.w	#tmsize,a2
.clr
	clr.w	$18(a2)
	move.b	pnum(a3),$19(a2)	;66(a3) = player offset on roster 19(a2) = player who touches puck
	bclr	#7,(sflags8).w
	st	$1A(a2)	;clear last player to touch puck (assist 1)
	st	$1C(a2)	;clear second last player to touch puck (assist 2)
	bclr	#3,tmflags(a2)
	move.l	#$17,d0	;#afaceoffpl - faceoff player assignment
.11
	bsr.w	assinsert
.goalie1
	move.w	(tmstruct+tmap).w,d4	;tmap = active players on ice (4-6). (tmap).w
	btst	#pfteam,pflags(a3)	;#pfteam - 0=home 1=away
	beq.w	.t0
	move.w	(AwShots+tmap).w,d4	;(tmsize).w
.t0
	neg.w	d4
	addq.w	#6,d4
	asl.w	#3,d4
	movea.l	#.apl,a1
	adda.w	d4,a1
	move.b	0(a1,d1.w),d4
	asl.w	#2,d4
	movea.l	#.ptab,a1
	move.w	0(a1,d4.w),d0
	move.w	2(a1,d4.w),d1
	btst	#pfgoal,pflags(a3)	;#pfgoal - 0=bottom, 1=top
	bne.w	.f0
	neg.w	d0
	neg.w	d1
.f0
	tst.w	position(a3)	;check for goalie
	beq.w	.goalie2
	cmp.w	#8,d4
	bgt.w	.nodef
	move.w	(fox).w,d3
	eor.w	d0,d3
	bpl.w	.notmid
	move.w	(foy).w,d3
	asr.w	#3,d3
	sub.w	d3,d1
.notmid
	move.w	(fox).w,d3
	asr.w	#2,d3
	sub.w	d3,d0
.nodef
	add.w	(fox).w,d0
	add.w	(foy).w,d1
.goalie2
	move.w	d0,(a3)	;Xpos
	move.w	d1,Ypos(a3)	;Ypos
	clr.w	Xvel(a3)	;Xvel
	clr.w	Yvel(a3)	;Yvel
	sub.w	(puckx).w,d0
	sub.w	(pucky).w,d1
	neg.w	d0
	neg.w	d1
	bsr.w	vtoa
	move.w	d0,facedir(a3)	;facedir
	bclr	#2,pflags2(a3)	;#pf2unav
	bclr	#pfalock,pflags(a3)	;#pfalock
	move.w	#$50C,d1	;#SPAglide
	bsr.w	SetSPA
.next
	adda.w	#$80,a3	;#Scstruct
	dbf	d2,.10
	bsr.w	SprSort
	movea.l	(sp)+,a3
	bsr.w	ResetAndSelectPlayers
	move.w	(ExtraChars).w,d4
	movea.l	#FaceOffMap+8,a2
	jsr	(DecompressGraphicsPlain).l
	move.w	d4,(faceoffvrcset).w
	movea.l	#FaceOffSprites+8,a2
	bsr.w	DecompressGraphicsPlain
	move.w	#$FFFF,(arenaanim).w
	btst	#0,(sflags7).w
	beq.w	.drawfaceoffwindow
	move.w	(faceoffanim).w,d0
	bmi.w	.drawfaceoffwindow
	jsr	(StartArenaAnim).l
.drawfaceoffwindow
	bsr.w	printz
	dc.b	0,6,$FF,0,0,0
	moveq	#$36,d0	;'6'   ; X Position of the faceoff window
	tst.w	(fox).w
	bpl.w	.fok
	move.w	#$BE,d0
.fok
	move.w	d0,(fodropx).w
	subi.w	#$2E,d0
	asr.w	#3,d0
	move.w	d0,(printx).w
	moveq	#$5C,d0	;'\'   ; Y position of the faceoff window
	move.w	d0,(fodropy).w
	subi.w	#$44,d0
	asr.w	#3,d0
	move.w	d0,(printy).w
	move.w	(ExtraChars).w,d4	;space for faceoff map
	movea.l	#FaceOffMap,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$C,d2
	moveq	#$A,d3
	moveq	#0,d5
	bset	#0,(sflags6).w
	bsr.w	dobitmap
	bclr	#0,(sflags6).w
	tst.w	(OptLine).w
	bne.w	.setdroptime
	bsr.w	printsmallz
	String	CC_AddY,$A,CC_SetAttribute,4		;$FBC2. ori.b #$A,d6 and drops the $FE04 word
	moveq	#$C,d0
	moveq	#3,d1
	bsr.w	Framer
	move.w	(tmstruct+tmline).w,d0
	move.w	(AwShots+tmline).w,d1
	btst	#gmdir,(gmode).w
	bne.w	.printline2
	exg	d0,d1
.printline2
	bsr.w	printsmallz
	String	CC_AddX,1,CC_AddY,$FE
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
	addq.w	#4,(printx).w
	move.w	d1,d0
	movea.l	#linelist,a1
	bsr.w	PrintStringFromList
.setdroptime
	move.w	#$78,d0
	bsr.w	randomd0
	addi.w	#$B4,d0
	cmpi.w	#0,(arenaanim).w
	beq.w	.chkmintime
	cmpi.w	#1,(arenaanim).w
	beq.w	.chkmintime
	cmpi.w	#5,(arenaanim).w
	beq.w	.chkmintime
	cmpi.w	#4,(arenaanim).w
	beq.w	.chkmintime
	cmpi.w	#2,(arenaanim).w
	bne.w	.time
.chkmintime
	cmp.w	#$10E,d0
	bgt.w	.time
	move.w	#$10E,d0	;sets minimum value in d0 to 10E
.time
	move.w	d0,temp1(a3)	;time for puck drop
	move.w	#$18,(palcount).w
	movea.l	#fofdata2,a0
	move.w	#1,(a0)
	move.w	#$8000,2(a0)
	move.w	#4,4(a0)
	move.w	#$A800,6(a0)
	move.w	#7,8(a0)	;frame of ref
	move.w	#$8000,$A(a0)
	btst	#gmdir,(gmode).w	;#gmdir - 0 = home team goes up
	bne.w	.nfl
	eori.w	#$800,2(a0)
	eori.w	#$800,6(a0)
.nfl
	move.w	#$FFFF,(fodir1).w	;-1
	move.w	#$FFFF,(fodir2).w	;-1
	jsr	(LeadSong).l
	bclr	#6,(sflags8).w
	bne.w	.playqueuedsong
	bclr	#4,(sflags8).w
	beq.w	.restorestate
.playqueuedsong
	bclr	#4,(sflags8).w
	move.w	(SongNum).w,-(sp)
	bsr.w	song
.restorestate
	move.w	#$18,(palcount).w
	move	(sp)+,sr
	movem.l	(sp)+,d0-d7/a0-a6
	rts
.nna
	subq.w	#1,temp1(a3)
	bpl.w	updatefaceoff
	jsr	(EndArenaAnim).l
	bra.w	Endfaceoff
.apl	dc.b	0
	dc.b	1,2,3,4,5,6,0,0,1,5,3,4,2,0,0,0
	dc.b	3,5,1,4,0,0,0
.ptab
	dc.w	0
	dc.w	$FF06
	dc.w	$FFDD
	dc.w	$FFCE
	dc.w	$23
	dc.w	$FFCE
	dc.w	$FFCE
	dc.w	$FFF6
	dc.w	0
	dc.w	$FFF1
	dc.w	$32
	dc.w	$FFF6
	dc.w	0
	dc.w	$FFC4
ResetAndSelectPlayers	;c1playernum / c2playernum = -1, then changeplayer for each human team
	move.w	#$FFFF,(c1playernum).w
	move.w	#$FFFF,(c2playernum).w
	tst.w	(cont1team).w
	beq.w	.checkcont2
	clr.w	d4
	bsr.w	changeplayer
.checkcont2
	tst.w	(cont2team).w
	beq.w	.checkcont3
	moveq	#2,d4
	bsr.w	changeplayer
.checkcont3
	tst.w	(cont3team).w
	beq.w	.checkcont4
	move.w	(cont1team).w,-(sp)
	move.w	(cont3team).w,(cont1team).w
	move.w	(c1playernum).w,-(sp)
	move.w	#$FFFF,(c1playernum).w
	clr.w	d4
	jsr	(changeplayer).l
	move.w	(c1playernum).w,(c3playernum).w
	move.w	(cont1team).w,(cont3team).w
	move.w	(sp)+,(c1playernum).w
	move.w	(sp)+,(cont1team).w
.checkcont4
	tst.w	(cont4team).w
	beq.w	.exit
	move.w	(cont2team).w,-(sp)
	move.w	(cont4team).w,(cont2team).w
	move.w	(c2playernum).w,-(sp)
	move.w	#$FFFF,(c2playernum).w
	move.w	#2,d4
	jsr	(changeplayer).l
	move.w	(c2playernum).w,(c4playernum).w
	move.w	(cont2team).w,(cont4team).w
	move.w	(sp)+,(c2playernum).w
	move.w	(sp)+,(cont2team).w
.exit
	rts
updatefaceoff	;a3 = puck. Drop animation frame from temp1; at 0 erases the faceoff box
	move.w	temp1(a3),d0
	beq.w	.erase
	addq.w	#6,d0
	lsr.w	#3,d0
	cmp.w	#2,d0
	bgt.w	rtss2
	neg.w	d0
	addi.w	#$A,d0
	move.w	d0,(fofdata).w
	rts
.erase
	bclr	#4,(disflags).w
	bsr.w	printz
	String	-(TXPRI+TXMAP1),0,0,0
	move.w	(fodropx).w,d0
	subi.w	#$2E,d0
	asr.w	#3,d0
	move.w	d0,(printx).w
	moveq	#$64,d0
	move.w	(fodropy).w,d0
	subi.w	#$44,d0
	asr.w	#3,d0
	move.w	d0,(printy).w
	moveq	#$C,d0
	moveq	#$D,d1
	move.w	#$7FF,d2
	bra.w	eraser
Endfaceoff	;drop the puck: pick the faceoff winner and send the puck off
	move.w	#SFXpuckice+3,-(sp)
	bsr.w	sfx
	bclr	#sf2faceoff,(sflags2).w
	move.w	#$3C,(holdreset).w
	move.w	(ExtraChars).w,d4
	movea.l	#RefsMap+8,a2
	bsr.w	DecompressGraphicsPlain
	bclr	#sf2drec,(sflags2).w
	bclr	#gmclock,(gmode).w
	bclr	#pf2fight,pflags2(a3)
	clr.w	(crowdnoisedelay).w
	bset	#4,(sflags3).w
	move.w	(fodir1).w,d3
	move.w	#$800,d4
	movea.l	#.ftab,a0
	movea.w	#(fofdata2-M68K_RAM),a1
	moveq	#$10,d2
	move.w	(a1),d1
	sub.b	-1(a0,d1.w),d2
	move.w	4(a1),d1
	add.b	-1(a0,d1.w),d2
	moveq	#$21,d0
	bsr.w	randomd0
	cmp.b	d0,d2
	bls.w	.p1won
	addq.w	#4,a1
.p1won
	btst	#3,2(a1)
	beq.w	.pos
	move.w	(fodir2).w,d3
	neg.w	d4
.pos
	move.w	d3,d0
	btst	#3,d0
	bne.w	.nojoy
	andi.w	#7,d0
	move.w	(VDP_CNTR).l,d1
	andi.w	#3,d1
	bne.w	.nj2
.nojoy
	moveq	#5,d0
	bsr.w	randomd0
	subq.w	#2,d0
	andi.w	#7,d0
	tst.w	d4
	bmi.w	.nj2
	eori.w	#4,d0
.nj2
	asl.w	#2,d0
	movea.l	#dirtab,a0
	move.w	0(a0,d0.w),d1
	asl.w	#5,d1
	move.w	d1,Xvel(a3)
	move.w	2(a0,d0.w),d1
	asl.w	#5,d1
	add.w	d4,d1
.setpuckvy
	move.w	d1,Yvel(a3)
	move.w	#$800,d0
	bsr.w	randomd0
	move.w	d0,Zvel(a3)
	clr.w	(puckz).w
	bclr	#pfnc,pflags(a3)
	move.l	#$18,d0	;pucknorm
	bra.w	assreplace
.ftab
	dc.b	0,8,$10,0,8,$10
; assignment for puck most of the time
; a3 = puck
; d7 = elapse frames since last call
pucknorm
	btst	#2,(BA_PS_flags).w	;check if flag is clear (normal play)
	beq.w	.normalplay
	bsr.w	UpdatePenaltyShotEnd
.normalplay
	bclr	#pfna,pflags(a3)	;#pfna clear
	beq.w	.nna
	clr.w	temp1(a3)	;temp1
	move.w	#$78,temp2(a3)	;'x' ; temp2
.nna
	movea.w	#(puckcross-M68K_RAM),a1	;table for puck crossing lines
	sub.w	d7,2(a1)	;sub elapse frames from time til crossing
	sub.w	d7,6(a1)
	sub.w	d7,temp1(a3)	;temp1
	bpl.w	.0
	addq.w	#5,temp1(a3)
	bsr.w	findpc
.0
	move.w	(puckc).w,d0
	bmi.w	.nothandled
	asl.w	#7,d0	;#scsize
	movea.w	#(SortCords-M68K_RAM),a2
	adda.w	d0,a2
	bsr.w	a2touchpuck
	move.l	a2,-(sp)
	bsr.w	GetHot
	add.w	(a2),d0	;Xpos - bungie the puck towards the hot spot on player a2
	sub.w	(a3),d0
	asr.w	#2,d0
	add.w	d0,(a3)
	add.w	Ypos(a2),d1	;Ypos
	sub.w	Ypos(a3),d1
	asr.w	#2,d1
	add.w	d1,Ypos(a3)
	move.w	Xvel(a2),Xvel(a3)	;Xvel
	move.w	Yvel(a2),Yvel(a3)	;Yvel
.nothandled
	bsr.w	puckIChk
	bsr.w	ChkOffsides
	btst	#0,(gmode).w	;check for play stoppage
	bne.w	.end
	tst.w	(puckc).w
	bpl.w	.resetstilltimer
	move.w	(a3),d0	;Xpos
	cmp.w	OldXpos(a3),d0	;oldXpos
	bne.w	.resetstilltimer
	move.w	Ypos(a3),d0	;Ypos
	cmp.w	OldYpos(a3),d0	;oldYpos
	bne.w	.resetstilltimer
	move.l	#6,d0
	subq.w	#1,temp2(a3)	;temp3
.maybepenalty
	bpl.w	.stillpuckdone
	bsr.w	AddPenalty2
.stillpuckdone
	bra.w	.end
.resetstilltimer
	move.w	#$78,temp2(a3)	;'x' ; move 78 hex into temp2
.end
	tst.b	Zvel(a3)	;Zvel
	bne.w	checkpuckcoll
	tst.w	Zpos(a3)	;Zpos
	bne.w	checkpuckcoll
	bsr.w	puckunflip
	bra.w	checkpuckcoll
;	puckIChk, puckunflip / puckflip / puckshadow, findpc, skateto, avdgoal, skatetopuckinit / skatetopuck, assexit /
;	assinsert / assreplace, vtoa, GetHot, SetSPA, doplayeracc, goalieacc, noturn0 / noturn, playeracc, MaxSpeed,
;	dostop, stopna, dirtab, UnpackNibbles, WeightedRandomSelect. remap follows.
;The source has the real cmp / cmpi; fixopcodes.js patches the cmp encoding after assembly.
;	SortCords offsets: Xpos 0, attribute 4, Ypos $14, Zpos $18, Xvel $28, Yvel $2A, position $34
;	SCnum $52, facedir $54, SPA $58, SPAnum $5A, SPAcnt $5C, pflags $62, pflags2 $63.

ChkOffsides	;check for offsides penalty. a3 = puck. Flags the whole team
	btst	#5,(gmode).w
	beq.w	rtss2
	btst	#2,(BA_PS_flags).w
	bne.w	rtss2
	movea.w	#(tmstruct-M68K_RAM),a1
	lea	tmsize(a1),a2
	bsr.w	ClearOffsidesIfAllPlayers
	exg	a1,a2
	bsr.w	ClearOffsidesIfAllPlayers
	move.w	#$54,d0
	cmp.w	Ypos(a3),d0
	bgt.w	.neg
	cmp.w	OldYpos(a3),d0
	ble.w	rtss2
	addi.w	#$A,d0
	btst	#gmdir,(gmode).w
	beq.w	.t0
	exg	a2,a1
.t0
	moveq	#5,d2
	movea.w	tmsort(a2),a0
.0
	tst.w	position(a0)
	bmi.w	.1
	cmp.w	Ypos(a0),d0
	bge.w	.1
	bset	#4,tmflags(a2)
	rts
.1
	adda.w	#SCstruct,a0
	dbf	d2,.0
	rts
.neg
	neg.w	d0
	cmp.w	Ypos(a3),d0
	blt.w	rtss2
	cmp.w	OldYpos(a3),d0
	bge.w	rtss2
	subi.w	#$A,d0
	btst	#gmdir,(gmode).w
	bne.w	.t1
	exg	a2,a1
.t1
	moveq	#5,d2
	movea.w	tmsort(a2),a0
.2
	tst.w	position(a0)
	bmi.w	.3
	cmp.w	Ypos(a0),d0
	ble.w	.3
	bset	#4,tmflags(a2)
	rts
.3
	adda.w	#SCstruct,a0
	dbf	d2,.2
	rts
ClearOffsidesIfAllPlayers	;a2 = team struct: clear the team offsides flag once no skater is past the line
	btst	#4,tmflags(a2)
	beq.w	rtss2
	movea.w	tmsort(a2),a0
	moveq	#5,d1
.top
	tst.w	position(a0)
	bmi.w	.next
	move.w	Ypos(a0),d0
	btst	#pfgoal,pflags(a0)
	bne.w	.next
	neg.w	d0
.next
	adda.w	#SCstruct,a0
	cmp.w	#$58,d0
	dbgt	d1,.top
	bgt.w	rtss2
	bclr	#4,tmflags(a2)
	rts
a2offsides	;player a2 touched the puck: offsides penalty if his team is flagged and the puck is past the blue line
	btst	#gmoffs,(gmode).w
	beq.w	rtss2
	move.w	(pucky).w,d0
	btst	#pfgoal,pflags(a2)
	bne.w	.0
	neg.w	d0
.0
	cmp.w	#$68,d0
	blt.w	rtss2
	movea.w	#(tmstruct-M68K_RAM),a0
	btst	#pfteam,pflags(a2)
	beq.w	.1
	adda.w	#tmsize,a0
.1
	btst	#4,tmflags(a0)
	beq.w	rtss2
	btst	#gmhl,(gmode).w
	bne.w	rtss2
	exg	a2,a3
	move.l	#$10,d0
	bsr.w	AddPenalty
	exg	a2,a3
	rts
; player a2 touches puck
; look for penalties/offsides/other junk
a2touchpuck
	move.w	(a2),(ltx).w	;move Xpos to last touch X
	move.w	Ypos(a2),(lty).w	;move Ypos to last touch Y
	move.w	SCnum(a2),(ltplayer).w	;move SCnum to last touch player
	movea.w	#(tmstruct-M68K_RAM),a0	;move Home Shots into a0
	btst	#pfteam,pflags(a2)	;check if home or away
	beq.w	.t	;branch if home
	lea	tmsize(a0),a0	;add to a0 if away
.t
	clr.w	d0
	move.b	pnum(a2),d0	;move pnum into d0
	btst	#pf3onetimer,pflags3(a2)	;check if one timer
	beq.w	.checklast	;branch if not
	bset	#7,(sflags8).w	;set if one timer
.checklast
	cmp.w	$18(a0),d0	;compare value in C6E6 (home) to d0
	beq.w	.same	;branch if equal
	bclr	#3,tmflags(a0)	;clear bit 3
	bne.w	.st	;branch if not cleared before
	move.w	$1A(a0),$1C(a0)	;move current player to assist slot
	move.w	$18(a0),$1A(a0)	;move current player to last player slot
.st
	move.w	d0,$18(a0)	;move pnum into current player
	cmp.w	$1C(a0),d0	;compare if same player as assist slot
	bne.w	.same	;branch if not
	st	$1C(a0)	;set FFFF to assist slot
.same
	bclr	#sf2shot,(sflags2).w	;clear shot taken
	bsr.w	a2offsides
	btst	#2,(iflags).w	;check if icing
	beq.w	.notice	;branch if not
	btst	#0,(iflags).w	;test if crossed goalline
	beq.w	.notice	;branch if not
	tst.w	position(a2)	;check if goalie
	beq.w	.notice	;branch if so
	btst	#1,(iflags).w	;check if must cross top line
	bne.w	.up	;branch if so
	btst	#pfgoal,pflags(a2)	;check if top or bottom shooting goal
	beq.w	.notice	;branch if bottom
.icing
	clr.w	d0
	move.b	(icingPlayer).w,d0	;move iflags+1 into d0
	asl.w	#7,d0
	move.l	a3,-(sp)	;push on stack
	movea.w	#(SortCords-M68K_RAM),a3
	adda.w	d0,a3	;a3 now player struct
	move.w	#$C,d0	;#PenIcing
	bsr.w	AddPenalty
	movea.l	(sp)+,a3
	rts
.up
	btst	#pfgoal,pflags(a2)	;check top or bottom shooting goal
	beq.s	.icing	;branch if bottom
.notice
	clr.b	(iflags).w
	move.b	SCnum+1(a2),(icingPlayer).w	;move SCnum+1 into icingPlayer
	move.w	(pucky).w,d0	;move pucky into d0
	btst	#pfgoal,pflags(a2)	;check if shooting up or down
	beq.w	.0	;branch if down
	bset	#1,(iflags).w	;set icing direction up
	neg.w	d0	;negate d0
.0
	bmi.w	rtss2	;exit if minus
	move.w	(tmstruct+tmap).w,d0	;(tmap).w
	sub.w	(AwShots+tmap).w,d0	;(tmsize).w
	btst	#pfteam,pflags(a2)	;check home or away
	beq.w	.1	;branch if home
	neg.w	d0	;negate d0
.1
	bmi.w	rtss2	;exit if minus
	bset	#2,(iflags).w	;set icing flag
	rts
; check for icing of puck penalty
puckIChk
	btst	#2,(iflags).w	;#ifok
	beq.w	rtss2
	btst	#0,(iflags).w	;#ifcgl - if crossed goal line
	bne.w	rtss2
	tst.w	(puckc).w
	bpl.w	rtss2
	move.w	#$108,d0	;goalline
	btst	#1,(iflags).w	;#ifdir - 1 = must cross top line
	bne.w	.0
	neg.w	d0
	cmp.w	(pucky).w,d0	;check other goalline
	bgt.w	.chkx
	rts
.0
	cmp.w	(pucky).w,d0
	bgt.w	rtss2
.chkx
	cmpi.w	#$2C,(puckx).w	;',' ; 2C - edge of crease
	bgt.w	.set
	cmpi.w	#$FFD4,(puckx).w	;FFD4 - edge of crease
	blt.w	.set
	bclr	#2,(iflags).w	;#ifok cleared
	rts
.set
	bset	#0,(iflags).w	;#ifcgl
	rts
; stop spinning puck
; a3 = puck
puckunflip
	cmpi.w	#8,SPAnum(a3)
	blt.w	.k
	cmpi.w	#$18,SPAnum(a3)
	bge.w	.k
	eori.w	#2,facedir(a3)	;facedir
.k
	ori.w	#4,facedir(a3)
	clr.w	SPAnum(a3)	;SPAnum
	st	SPAcnt(a3)	;SPAcnt
	rts
; start puck spinning
; a3 = puck
puckflip
	andi.w	#1,d0
	eor.w	d0,facedir(a3)	;facedir
	andi.w	#3,facedir(a3)
	st	SPAcnt(a3)	;SPAcnt
	move.w	#$46A,d1	;#SPApflip
	bra.w	SetSPA
; assignment for puck shadow
; a3 = puck shadow
puckshadow
	cmpi.w	#$18A,frame(a3)	;#SPFpuck, frame
	bne.w	.siren	;shadow turns into siren on goals
	move.w	Xpos-SCstruct(a3),(a3)	;Xpos-SCstruct, Xpos
	move.w	Ypos-SCstruct(a3),Ypos(a3)	;Ypos-SCstruct, Ypos
	clr.w	Zpos(a3)	;Zpos
	moveq	#Ypos,d0	;Ypos
	btst	#sfhor,(sflags).w	;#sfhor - check if horizontal mode
	beq.w	.nhor
	moveq	#Xpos,d0	;Xpos
.nhor
	addq.w	#1,0(a3,d0.w)
	rts
.siren
	tst.w	frame(a3)	;frame
	beq.w	rtss2
	clr.w	(a3)	;Xpos
	move.w	#$12C,Ypos(a3)	;Ypos
	move.w	#$E,Zpos(a3)	;Zpos
	tst.w	Ypos-SCstruct(a3)	;Ypos-SCstruct
	bpl.w	.s0
	move.w	#$8000,attribute(a3)	;attribute
	neg.w	Ypos(a3)	;Ypos
	subq.w	#1,Zpos(a3)	;Zpos
.s0
	rts
; find puck crossing lines
; calculate when puck will cross goalline (if at all)
findpc
	movem.l	d0-d4/a1-a2,-(sp)
	movea.w	#(puckcross-M68K_RAM),a1
	move.w	#$88,d1	;sideline - distance from center to side boards
	move.w	#$108,d4	;goaline
	bsr.w	.calc
	neg.w	d4	;make d4 negative to check bottom goal line
	bsr.w	.calc
	movem.l	(sp)+,d0-d4/a1-a2
	rts
.calc
	move.w	d4,d0	;move goaline into d0
	sub.w	(pucky).w,d0	;sub pucky from d0
	tst.w	(puckvy).w	;check puckvy
	beq.w	.nocross	;branch if 0
	move.w	d0,d2	;move d0 into d2
	swap	d2	;swap upper and lower word of d2
	clr.w	d2	;clear bottom word of d2
	asr.l	#4,d2	;shift 4 bits right (divide by 16)
	divs.w	(puckvy).w,d2	;divide puckvy into d2
	bmi.w	.nocross	;branch if negative
	move.w	d2,2(a1)	;time until crossing in frames (puckcross y)
	muls.w	(puckvx).w,d0	;mult puckvx with d0
	divs.w	(puckvy).w,d0	;divide puckvy into d0
	bvs.w	.nocross	;branch if overflow set
	add.w	(puckx).w,d0	;add puckx to d0
	cmp.w	d1,d0	;compare d1 (sideline) to d0
	blt.w	.o1	;branch if less than (in play)
	neg.w	d0	;negate d0
	add.w	d1,d0	;add d1 3 times to d0
	add.w	d1,d0
	add.w	d1,d0
.o1
	neg.w	d1	;negate d1
	cmp.w	d1,d0	;compare d1 (other sideline) to d0
	bgt.w	.o2	;branch if greater than (in play)
	neg.w	d0	;negate d0
	add.w	d1,d0	;add d1 to d0 3 times
	add.w	d1,d0
	add.w	d1,d0
.o2
	neg.w	d1	;negate d1
	move.w	d0,(a1)	;move d0 into puckcross
	bra.w	.next
.nocross
	move.w	#$FFFF,2(a1)	;move -1 into puckcross y
.next
	addq.w	#4,a1	;add 4 to puckcross (to move to the other goal line)
	rts
; a0 = extra routine for collision avoidance
; d0/d1 = x/y coord to skate to
; d7 = elapsed frames
skateto
	sub.b	d7,temp2(a3)	;sub d7 from temp2
	bpl.w	.ex	;exit if not 0 or less
	addi.b	#$C,temp2(a3)	;add 12 - only execute every 12 frames
	bsr.w	avdgoal	;avoid the goal nets
	movem.w	d0-d1,-(sp)
	move.w	Xvel(a3),d0	;Xvel
	asr.w	#8,d0	;divide by 256
	neg.w	d0	;make negative
	add.w	(sp)+,d0	;add new x coord from stack
	sub.w	(a3),d0	;sub Xpos
	move.w	Yvel(a3),d1	;Yvel
	asr.w	#8,d1	;divide by 256
	neg.w	d1	;make negative
	add.w	(sp)+,d1	;add new y coord from stack
	sub.w	Ypos(a3),d1	;sub Ypos
	cmp.w	#$C,d0	;compare 12 to d0
	bgt.w	.vt
	cmp.w	#$FFF4,d0	;cmp -12
	blt.w	.vt
	cmp.w	#$C,d1	;compare 12 to d1
	bgt.w	.vt
	cmp.w	#$FFF4,d1	;cmp -12
	blt.w	.vt
	moveq	#9,d0
	bra.w	.nvt
.vt
	bsr.w	vtoa
.nvt
	jsr	(a0)	;extra collision routine
	move.b	d0,temp2+1(a3)	;move d0 into temp2+1
	cmp.w	#7,d0	;compare to 7
	ble.w	.ex
	move.w	Xvel(a3),d0	;Xvel
	or.w	Yvel(a3),d0	;Yvel
	bne.w	.ex
	move.w	(puckx).w,d0	;move puckx into d0
	move.w	(pucky).w,d1	;move pucky into d1
	btst	#pf2fight,(puck_pflags2).w	;#pf2fight, puckx+pflags2
	beq.w	.nf
	move.w	(xc1).w,d0	;scroll lock x coord
	move.w	(yc1).w,d1	;scroll lock y coord
.nf
	sub.w	(a3),d0	;Xpos
	sub.w	Ypos(a3),d1	;Ypos - face towards puck
	bsr.w	vtoa
	sub.w	facedir(a3),d0	;facedir
	beq.w	.ex
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0	;divide by 2
	subq.w	#1,d0
	add.w	facedir(a3),d0	;facedir
	andi.w	#7,d0
	move.w	d0,facedir(a3)	;facedir
.ex
	clr.w	d0
	move.b	temp2+1(a3),d0	;temp2+1
	bra.w	doplayeracc
; Don't try to skate through goal
; If d0/d1 coords intersect through goal, then provide new d0/d1 coords
; a3 = player
; .xr = 80
; .yr = 30
; .ye = 30
; .gl = 258
avdgoal
	clr.w	(deltax).w
	clr.w	(deltay).w
	tst.w	position(a3)	;goalie? If so, quit
	beq.w	rtss2
	move.w	(a3),d2	;Xpos
	eor.w	d0,d2
	bpl.w	.chbar
	move.w	d1,d2
	sub.w	Ypos(a3),d2	;Ypos
	move.w	(a3),d3	;Xpos
	muls.w	d3,d2
	sub.w	d0,d3
	divs.w	d3,d2
	add.w	Ypos(a3),d2	;Ypos
	cmp.w	#$121,d2	;.gl+.yr
	bgt.w	.chbar
	cmp.w	#$DB,d2	;.gl-.yr
	blt.w	.lower
	move.w	#$144,d3	;.gl-.yr-.ye
	cmp.w	#$FE,d2	;.gl
	bgt.w	.2
	blt.w	.1
	cmpi.w	#$FE,Ypos(a3)	;.gl, Ypos
	bgt.w	.2
.1
	move.w	#$B8,d3	;.gl-.yr-.ye
.2
	sub.w	d2,d3
	move.w	d3,(deltay).w
	bra.w	.chbar
.lower
	cmp.w	#$FF25,d2	;-.gl+.yr
	bgt.w	.chbar
	cmp.w	#$FEDF,d2	;-.gl-.yr
	blt.w	.chbar
	move.w	#$FF48,d3	;-.gl+.yr+.ye
	cmp.w	#$FF02,d2	;-.gl
	bgt.w	.4
	blt.w	.3
	cmpi.w	#$FF02,Ypos(a3)	;-.gl, Ypos
	bgt.w	.4
.3
	move.w	#$FEBC,d3	;-.gl-.yr-.ye
.4
	sub.w	d2,d3
	move.w	d3,(deltay).w
.chbar
	move.w	d1,d3
	subi.w	#$FE,d3
	move.w	Ypos(a3),d2
	subi.w	#$FE,d2
	bsr.w	.ch1
	move.w	d1,d3
	addi.w	#$FE,d3
	move.w	Ypos(a3),d2
	addi.w	#$FE,d2
	bsr.w	.ch1
	add.w	(deltax).w,d0
	add.w	(deltay).w,d1
	rts
.ch1
	move.w	d3,d4
	eor.w	d2,d4
	bpl.w	rtss2
	move.w	d0,d4
	sub.w	(a3),d4	;Xpos
	muls.w	d2,d4
	sub.w	d3,d2
	divs.w	d2,d4
	add.w	(a3),d4	;Xpos
	cmp.w	#$50,d4	;'P'   ; #.xr
	bgt.w	rtss2
	cmp.w	#$FFB0,d4	;#-.xr
	blt.w	rtss2
	moveq	#$50,d3	;'P'   ; #.xr
	tst.w	d4
	bne.w	.ch2
	tst.w	(a3)	;Xpos
.ch2
	bpl.w	.ch3
	neg.w	d3
.ch3
	sub.w	d4,d3
	move.w	d3,(deltax).w
	rts
; find where the puck is going to be
skatetopuckinit
	move.b	(puckvx).w,d0
	asr.b	#1,d0
	ext.w	d0
	add.w	(puckx).w,d0
	move.b	(puckvy).w,d1
	asr.b	#1,d1
	ext.w	d1
	add.w	(pucky).w,d1
	rts
; player a3 should skate to puck
skatetopuck
	bsr.s	skatetopuckinit
	sub.b	d7,temp2(a3)	;temp2
	bpl.w	.ex
	addi.b	#$A,temp2(a3)	;temp2
	bsr.w	avdgoal
	movem.w	d0-d1,-(sp)
	move.l	a3,-(sp)
	bsr.w	GetHot
	neg.b	d0
	neg.b	d1
	sub.b	Xvel(a3),d0	;Xvel
	ext.w	d0
	add.w	(sp)+,d0
	sub.w	(a3),d0	;Xpos
	sub.b	Yvel(a3),d1	;Yvel
	ext.w	d1
	add.w	(sp)+,d1
	sub.w	Ypos(a3),d1	;Ypos
	bsr.w	vtoa
	move.b	d0,temp2+1(a3)	;temp2 lower byte
	tst.w	position(a3)
	beq.w	.ex
	move.w	(puckvx).w,d0
	move.w	(puckvy).w,d1
	bsr.w	vtoa
	eori.w	#4,d0
	cmp.w	facedir(a3),d0	;facedir
	beq.w	.ex
	move.w	(puckx).w,d0
	sub.w	(a3),d0	;Xpos
	move.w	(pucky).w,d1
	sub.w	Ypos(a3),d1	;Ypos
	movem.w	d0-d1,-(sp)
	bsr.w	vtoa
	cmp.w	facedir(a3),d0	;$54 = facedir
	movem.w	(sp)+,d0-d1
	bne.w	.ex
	muls.w	d0,d0
	muls.w	d1,d1
	add.l	d1,d0
	cmp.l	#$384,d0	;#30^2
	bls.w	.ex
	cmp.l	#$5A4,d0	;#38^2
	bls.w	Sweepcheck
.ex
	move.b	temp2+1(a3),d0
	bra.w	doplayeracc
; exit current assignment on player a3
assexit
	addq.w	#1,assnum(a3)	;add 1 to current assignment index
	andi.w	#7,assnum(a3)	;mask passing first 3 bits
	bset	#pfna,pflags(a3)	;signal next assignment
	rts
; insert new assignment on player a3
assinsert
	subq.w	#1,assnum(a3)	;$36 = assnum
	andi.w	#7,assnum(a3)
; replace current assignment on player a3
assreplace
	move.l	d1,-(sp)	;push on stack
	move.w	assnum(a3),d1	;$36 = assnum
	move.b	d0,asslist(a3,d1.w)	;replace current assignment with d0 on asslist
	bset	#pfna,pflags(a3)	;set flag to start new assignment
	move.l	(sp)+,d1	;pop on stack
	rts
; d0/d1 are x/y distances which are converted into direction 0-7 and returned in d0
vtoa
	movem.l	d2/a0,-(sp)
	move.w	d0,d2
	or.w	d1,d2
	beq.w	.nodir
	clr.w	d2
	tst.w	d0
	bpl.w	.0
	neg.w	d0
	bset	#0,d2
.0
	tst.w	d1
	bpl.w	.1
	neg.w	d1
	bset	#1,d2
.1
	asl.w	#1,d1
	cmp.w	d1,d0
	bhi.w	.2
	bset	#2,d2
.2
	lsr.w	#1,d1
	asl.w	#1,d0
	cmp.w	d0,d1
	bhi.w	.3
	bset	#3,d2
.3
	movea.l	#.dt,a0	;#.dt
	clr.w	d0
	move.b	0(a0,d2.w),d0
	movem.l	(sp)+,d2/a0
	rts
.nodir
	moveq	#8,d0
	movem.l	(sp)+,d2/a0
	rts
.dt	dc.b	1
	dc.b	7,3,5,0,0,4,4,2,6,2,6,1,7,3,5
; Push long address of structure to get hot spot from
; hot spot x/y returned in d0/d1
GetHot
	movem.l	a0-a1,-(sp)
	movea.l	$C(sp),a0	;move stored address before sub routine call into a0
	clr.w	d0	;clear d0
	clr.w	d1	;clear d1
	tst.w	frame(a0)	;$6 = frame
	ble.w	.ex	;branch if <= 0
	movea.l	#HotList,a1	;move HotList address into a1
	move.w	frame(a0),d0	;move frame into d0
	add.w	d0,d0	;double d0
	move.b	1(a1,d0.w),d1	;SprStrHot Y byte
	ext.w	d1	;extend d1
	move.b	0(a1,d0.w),d0	;SprStrHot X byte
	ext.w	d0	;extend d0
	btst	#3,attribute(a0)	;check attribute for X flip
	beq.w	.nox	;branch if equal
	neg.w	d0	;negate d0 (flip)
.nox
	btst	#4,attribute(a0)	;check attribute for Y flip
	bne.w	.noy	;branch if no flip
	neg.w	d1	;negate d1 (flip)
.noy
	btst	#sfhor,(sflags).w	;check if horizontal mode
	beq.w	.ex	;branch if not
	exg	d0,d1	;swap d0 and d1
	neg.w	d1	;ngate d1 (x now)
.ex
	movem.l	(sp)+,a0-a1
	move.l	(sp)+,(sp)
	rts
; set sprite animation on struct a3
; d1 = new animation
SetSPA
	cmp.w	SPA(a3),d1
	beq.w	rtss2
	clr.w	SPAnum(a3)
	move.w	d1,SPA(a3)
	st	SPAcnt(a3)	;restart animation
	rts
; player a3 gets acc. in d0 dir
doplayeracc
	tst.w	position(a3)
	beq.w	goalieacc	;goalie is special
	move.w	#$50C,d1	;#SPAglide
	btst	#pfrev,pflags(a3)	;check if skating backwards
	beq.w	.d0	;branch if not
	move.w	#$A60,d1	;#SPAglideback
.d0
	andi.w	#$F,d0	;pass first 4 bits of d0
	cmp.w	#7,d0	;compare to 7
	ble.w	.d1	;branch if less than
	cmp.w	#9,d0	;compare to 9
	bne.w	.cgl	;branch if not equal
	move.w	Xvel(a3),d0	;Xvel
	or.w	Yvel(a3),d0	;OR Yvel with Xvel
	bne.w	dostop	;stop if not equal
.cgl
	btst	#pf2aip,pflags2(a3)	;check if anim in progress
	beq.s	SetSPA	;if not set animation
	rts
.d1
	movem.w	d0-d1,-(sp)
	move.w	d0,d2
	move.w	SCnum(a3),d0	;move SCnum into d0
	cmp.w	(puckc).w,d0	;check if puckc
	beq.w	.clrrev	;branch if so
	move.w	(puckx).w,d0	;puckx into d0
	sub.w	(a3),d0	;sub Xpos
	move.w	Ypos(a3),d3	;Ypos into d3
	move.b	(puckvy).w,d1	;puckvy into d1
	ext.w	d1
	add.w	(pucky).w,d1	;add pucky to d1
	sub.w	d3,d1	;sub Ypos from d1
	btst	#pfgoal,pflags(a3)	;check which goal shooting at
	bne.w	.c1	;branch if top
	neg.w	d0
	neg.w	d1
	neg.w	d3
	eori.w	#4,d2
.c1
	btst	#pfrev,pflags(a3)	;check if skating in reverse
	bne.w	.inrev	;branch if so
	tst.w	d3
	bpl.w	.clrrev	;skate back in own zone only
	cmp.w	#4,d2
	bne.w	.clrrev
	bsr.w	vtoa
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.clrrev
	bra.w	.rev
.inrev
	subq.w	#3,d2
	andi.w	#7,d2
	cmp.w	#2,d2
	bhi.w	.clrrev
	bsr.w	vtoa
	addq.w	#2,d0
	andi.w	#7,d0
	cmp.w	#4,d0
	bhi.w	.clrrev
.rev
	btst	#pfrev,pflags(a3)	;check if skating in reverse
	bne.w	.done	;branch if so
	move.w	Xvel(a3),d0	;move Xvel into d0
	or.w	Yvel(a3),d0	;or with Yvel
	beq.w	.setrev	;branch if equal
	move.w	Xvel(a3),d0	;move Xvel into d0
	move.w	Yvel(a3),d1	;Yvel to d1
	bsr.w	vtoa
	sub.w	(sp),d0
	addq.w	#1,d0
	andi.w	#7,d0
	cmp.w	#2,d0
	bhi.w	.done
.setrev
	bset	#pfrev,pflags(a3)	;set skating in reverse flag
	bra.w	.done
.clrrev
	bclr	#pfrev,pflags(a3)	;clear skating in reverse flag
.done
	movem.w	(sp)+,d0-d1
	move.w	facedir(a3),d2	;facedir into d2
	sub.w	d2,d0
	andi.w	#7,d0
	movea.l	#.ftab,a0
	asl.w	#1,d0
	tst.w	0(a0,d0.w)
	beq.w	noturn0
	move.w	Xvel(a3),d4	;Xvel to d4
	muls.w	d4,d4	;square d4
	move.w	Yvel(a3),d3	;Yvel to d3
	muls.w	d3,d3	;square d3
	add.l	d4,d3	;add d4 and d3
	swap	d3	;swap upper and lower words
	move.w	#$300,d4
	sub.w	d3,d4
	cmp.w	#$180,d4	;compare to d4
	bge.w	.iok	;branch if greater than or equal
	move.w	#$180,d4
.iok
	muls.w	0(a0,d0.w),d4
	btst	#pfrev,pflags(a3)	;check if skating in reverse
	beq.w	.i0	;branch if not
	neg.l	d4
.i0
	add.l	d4,facedir(a3)	;add d4 to facedir
	andi.w	#7,facedir(a3)	;pass the first 3 bits to facedir
	move.w	facedir(a3),d2	;move facedir to d2
	cmp.w	#$14,d3
	bls.w	.s3
	clr.w	d1
	tst.w	0(a0,d0.w)
	bpl.w	.s1
	eori.w	#$FFCE,d1	;#SPAturnl-#SPAturnr
.s1
	btst	#3,attribute(a3)	;test bit 3 of attribute
	beq.w	.s2
	eori.w	#$FFCE,d1	;#SPAturnl-#SPAturnr
.s2
	addi.w	#$694,d1	;#SPAturnr
	bset	#pf2aip,pflags2(a3)	;set animation in progress flag
.s3
	bsr.w	SetSPA
	cmp.w	#2,d3
	bhi.w	noturn
	rts
.ftab	dc.w	0
	dc.w	$10
	dc.w	$10
	dc.w	$10
	dc.w	0
	dc.w	$FFF0
	dc.w	$FFF0
	dc.w	$FFF0
goalieacc	;goalie gets acc. in direction d0. Turns facedir one step toward d0
	btst	#3,pflags(a3)
	beq.w	.normalgoalie
	movem.w	d0,-(sp)
	move.w	(puckc).w,d0
	cmp.w	SCnum(a3),d0
	movem.w	(sp)+,d0
	beq.w	.normalgoalie
	cmpi.w	#$30,(a3)
	bgt.w	.normalgoalie
	cmpi.w	#$FFD0,(a3)
	blt.w	.normalgoalie
	cmpi.w	#$FF40,Ypos(a3)
	bgt.w	.checkbottom
	cmpi.w	#$FEFA,Ypos(a3)
	blt.w	.normalgoalie
	bra.w	.facepuck
.checkbottom
	cmpi.w	#$C0,Ypos(a3)
	blt.w	.normalgoalie
	cmpi.w	#$106,Ypos(a3)
	bgt.w	.normalgoalie
.facepuck
	movem.w	d0-d1,-(sp)
	move.w	(puckx).w,d0
	sub.w	(a3),d0
	move.w	(pucky).w,d1
	sub.w	Ypos(a3),d1
	cmp.w	#$10,d0
	bgt.w	.usevtoa
	cmp.w	#$FFF0,d0
	blt.w	.usevtoa
	cmp.w	#$10,d1
	bgt.w	.usevtoa
	cmp.w	#$FFF0,d1
	blt.w	.usevtoa
	move.w	facedir(a3),d0
	bra.w	.checkadjust
.usevtoa
	bsr.w	vtoa
.checkadjust
	btst	#0,(sflags4).w
	bne.w	.adjustkeepdir
	bsr.w	AdjustFacingDirection
	movem.w	(sp)+,d0-d1
	bra.w	.setready
.adjustkeepdir
	movem.w	(sp)+,d0-d1
	cmp.w	#8,d0
	beq.w	.setready
	movem.w	d0-d1,-(sp)
	bsr.w	AdjustFacingDirection
	movem.w	(sp)+,d0-d1
.setready
	move.w	#2,d1
	btst	#1,pflags2(a3)
	bne.w	.exit
	bsr.w	SetSPA
	cmp.w	#8,d0
	bne.w	.playermove
	tst.w	position(a3)
	bne.w	.playermove
	btst	#3,pflags(a3)
	beq.w	.playermove
	move.w	d0,-(sp)
	move.w	Ypos(a3),d0
	btst	#7,pflags(a3)
	beq.w	.topstay
	neg.w	d0
.topstay
	cmp.w	#$D8,d0
	blt.w	.stopandrestore
	move.w	(a3),d0
	cmp.w	#$20,d0
	bgt.w	.stopandrestore
	cmp.w	#$FFE0,d0
	blt.w	.stopandrestore
	move.w	(sp)+,d0
	jsr	(stopna2).l
	bra.w	.playermove
.stopandrestore
	jsr	(stopna2).l
	move.w	(sp)+,d0
.playermove
	move.w	d0,d2
	bra.w	playeracc
.normalgoalie
	move.w	#2,d1
	btst	#3,pflags(a3)
	beq.w	.goalieacc2
	btst	#2,pflags(a3)
	bne.w	.cgl
	cmp.w	#8,d0
	bne.w	.turnskater
	tst.w	position(a3)
	bne.w	.cgl
	move.w	d0,-(sp)
	move.w	Ypos(a3),d0
	btst	#7,pflags(a3)
	beq.w	.topstop
	neg.w	d0
.topstop
	cmp.w	#$D8,d0
	blt.w	.restoreidle
	move.w	(a3),d0
	cmp.w	#$20,d0
	bgt.w	.restoreidle
	cmp.w	#$FFE0,d0
	blt.w	.restoreidle
	move.w	(sp)+,d0
	bsr.w	stopna
	bra.w	.cgl
.restoreidle
	move.w	(sp)+,d0
	bra.w	.cgl
.turnskater
	bra.w	.d1
.goalieacc2
	andi.w	#$F,d0
	cmp.w	#7,d0
	ble.w	.d1
	cmp.w	#9,d0
	bne.w	.cgl
	move.w	Xvel(a3),d0
	or.w	Yvel(a3),d0
	beq.w	.cgl
	jmp	stopna2
.cgl
	btst	#pf2aip,pflags2(a3)
	beq.w	SetSPA
.exit
	rts
.d1
	sub.w	facedir(a3),d0
	beq.w	.d11
	neg.w	d0
	andi.w	#4,d0
	lsr.w	#1,d0
	subq.w	#1,d0
	add.w	facedir(a3),d0
	andi.w	#7,d0
	move.w	d0,facedir(a3)
.d11
	move.w	#$3D8,d1
	bsr.w	SetSPA
	move.w	facedir(a3),d2
	bra.w	playeracc
noturn0	;doplayeracc when the wanted direction needs no turn (.ftab entry 0). d0 = direction minus facedir, times 2
	moveq	#2,d4
	btst	#pfrev,pflags(a3)
	beq.w	.0
	addq.w	#4,d4
	eori.w	#8,d0
.0
	tst.w	d0
	beq.w	.nochg
	move.w	Xvel(a3),d0
	move.w	Yvel(a3),d1
	bsr.w	vtoa
	btst	#3,d0
	bne.w	.nostop
	sub.w	facedir(a3),d0
	add.w	d4,d0
	andi.w	#7,d0
	cmp.w	#4,d0
	blt.w	dostop
.nostop
	addq.w	#1,facedir(a3)
	btst	#3,attribute(a3)
	beq.w	.nos0
	subq.w	#2,facedir(a3)
.nos0
	andi.w	#7,facedir(a3)
	move.w	#$50C,d1
	btst	#pfrev,pflags(a3)
	beq.w	SetSPA
	move.w	#$A60,d1
	bra.w	SetSPA
.nochg
	move.w	#$A92,d1
	btst	#pfrev,pflags(a3)
	bne.w	.ns
	move.w	#$5D0,d1
	btst	#6,pflags2(a3)
	beq.w	.nb6
	move.w	#$11E6,d1
.nb6
	move.w	(puckc).w,d4
	cmp.w	SCnum(a3),d4
	bne.w	.ns
	move.w	#$53E,d1
.ns
	btst	#pf2aip,pflags2(a3)
	bne.w	noturn
	bsr.w	SetSPA
noturn	;reverse the acc. direction when skating backwards, then falls into playeracc
	btst	#pfrev,pflags(a3)
	beq.w	playeracc
	eori.w	#4,d2
; d2 = direction of acc
playeracc
	asl.w	#2,d2
	lea	dirtab(pc),a0
	move.w	2(a0,d2.w),d1	;Y Inc
	move.w	0(a0,d2.w),d0	;x Inc
	move.w	Wallsin(a3),d2	;check acc dir and dont push wall
	;wallsin
	beq.w	.nox
	eor.w	d0,d2
	bpl.w	.nox
	clr.w	d0
.nox
	move.w	Wallcos(a3),d2	;wallcos
	beq.w	.noy
	eor.w	d1,d2
	bmi.w	.noy
	clr.w	d1
.noy
	clr.w	d2	;clear d2
	move.b	weight(a3),d2	;move wgt of player into d2
	lsr.w	#2,d2	;divide d2 by 2
	neg.w	d2	;make it negative
	addi.w	#$40,d2	;'@'   ; add 40 hex (64 decimal) to d2
	add.b	legstr(a3),d2	;add agl (legstr) of player to d2
	btst	#1,(sflags8).w
	bne.w	.incagl
	btst	#6,(sflags7).w	;check flag for crowd meter record
	beq.w	.incaglg	;branch if not set
.incagl
	addq.b	#2,d2	;add 2 to d2 (crowd meter boost)
.incaglg
	tst.w	position(a3)	;test for goalie
	bne.w	.noy2
	add.b	legstr(a3),d2	;goalie gets double agl
	addi.w	#$10,d2	;double agl + 10 hex
.noy2
	asr.w	#1,d2	;divide by 2
	muls.w	d2,d0	;x
	muls.w	d2,d1	;y
	asr.l	#5,d0	;divide by 32
	asr.l	#5,d1
	muls.w	d7,d0	;mult d0 with frames elapsed (d7)
	muls.w	d7,d1	;mult d1 by frames elapsed (d7)
	tst.w	position(a3)	;test goalie
	bne.w	.noy3
	btst	#3,pflags(a3)	;joypad controlled
	beq.w	.noy3	;no, then jump
	move.w	(puckc).w,d2	;puck carrier SCnum
	cmp.w	SCnum(a3),d2	;carrying puck?
	bne.w	.noy3	;jump if not
	asr.w	#1,d0	;divide by 2 (puck carrier, joypad controlled)
	asr.w	#1,d1	;divide by 2
.noy3
	add.w	Xvel(a3),d0	;Xvel
	add.w	Yvel(a3),d1	;Yvel
	move.w	d0,d2	;move d0 into d2
	move.w	d1,d3	;move d1 into d3
	muls.w	d2,d2	;square d2
	muls.w	d3,d3	;square d3
	add.l	d2,d3	;add together
	movem.w	d0-d1,-(sp)	;push d0 and d1 to stack
	bsr.w	getpde
	btst	#4,(sflags7).w
	beq.w	.noy4
	move.w	#$1000,d0	;d0 = energy, move 1000 hex into d0
.noy4
	clr.w	d2	;clear d2
	move.b	legspd(a3),d2	;add speed (legspd) to d2
	btst	#1,(sflags8).w
	bne.w	.incspd
	btst	#6,(sflags7).w	;skip boost if 0
	beq.w	.noy5
.incspd
	addq.b	#2,d2	;add 2 to d2 (speed)
	cmp.b	#$1E,d2	;compare to max speed attribute (1E or 30)
	ble.w	.noy5	;branch if less than
	move.b	#$1E,d2	;limit it to max speed
.noy5
	move.w	d2,(TempRawSpd).w	;hold spd value
	lsr.w	#1,d2	;divide by 2
	mulu.w	d0,d2	;multiply energy with spd
	asl.l	#4,d2	;mult by 16
	swap	d2	;swap d2 words (this math is to adjust for energy. Line Changes off, d2 = Spd value / 2)
	asl.w	#2,d2	;mult by 4 (No Line changes result from above = Spd value * 2)
	andi.w	#$3F,d2	;'?'   ; pass first 6 bits. Limits d2 to $3F (63 decimal)
	lea	MaxSpeed(pc),a2	;move Maxspeed table address into a2
	move.w	d2,(TempEnergySpd).w	;hold new spd value
	move.l	0(a2,d2.w),d2	;use value from MaxSpeed list
	move.l	d2,(TempMaxSpd).w	;hold MaxSpeed value
	cmpi.w	#$3C,(TempEnergySpd).w	;'<' ; compare new spd value with 60 decimal
	bge.w	.fgtinj	;branch if greater than or equal
	btst	#0,(TempRawSpd+1).w	;check if TempRawSpd is odd
	beq.w	.fgtinj	;branch if even
	move.w	(TempEnergySpd).w,d2	;move TempEnergySpd into d2
	addq.w	#4,d2	;add 4 to d2
	move.l	0(a2,d2.w),d2	;use value from MaxSpeed list (rounding the odd number up)
	sub.l	(TempMaxSpd).w,d2	;sub TempMaxSpd from d2
	asr.l	#1,d2	;divide by 2
	add.l	(TempMaxSpd).w,d2	;add TempMaxSpd to d2 (so halves the difference between the 2 Speed steps)
.fgtinj
	btst	#6,pflags2(a3)	;check if injured during fight
	beq.w	.puckc	;branch if not
	lsr.l	#3,d2	;divide d2 by 8
.puckc
	tst.w	position(a3)	;test goalie
	bne.w	.noy6	;branch if not goalie
	move.w	(puckc).w,d0	;puck carrier SCnum
	cmp.w	SCnum(a3),d0	;check if puck carrier
	bne.w	.noy6	;branch if not puck carrier
	asr.l	#1,d2	;divide d2 by 2
.noy6
	movem.w	(sp)+,d0-d1	;pop from stack
	cmp.l	d2,d3	;Compare d3 to d2 (max speed check)
	bhi.w	.sube	;branch if d3 is higher than d2 (no increase in velocity)
	move.w	d0,Xvel(a3)	;move new Xvel into Xvel
	move.w	d1,Yvel(a3)	;move new Yvel into Yvel
.sube
	tst.w	(OptLine).w
	bne.w	rtss2
	move.w	(VDP_CNTR).l,d0
	andi.w	#$7F,d0
	bne.w	rtss2
	bsr.w	getpde
	subi.w	#$21,d0
	cmp.w	#$C00,d0
	blt.w	setpde
	move.b	endurance(a3),d2	;endurance
	ext.w	d2
	lsr.w	#1,d2
	add.w	d2,d0
	bsr.w	setpde
	btst	#0,endurance(a3)
	beq.w	.ex
	btst	#0,(vcount+1).w
	beq.w	.ex
	addq.w	#1,d0
	bra.w	setpde
.ex
	rts
MaxSpeed	;max speed values for each rating level 0-$F: ((n+20)*275)^2 (92 used 250)
	dc.l	(20*275)*(20*275)	;$1CD9410
	dc.l	(21*275)*(21*275)	;$1FCE3E1
	dc.l	(22*275)*(22*275)	;$22E8284
	dc.l	(23*275)*(23*275)	;$2626FF9
	dc.l	(24*275)*(24*275)	;$298AC40
	dc.l	(25*275)*(25*275)	;$2D13759
	dc.l	(26*275)*(26*275)	;$30C1144
	dc.l	(27*275)*(27*275)	;$3493A01
	dc.l	(28*275)*(28*275)	;$388B190
	dc.l	(29*275)*(29*275)	;$3CA77F1
	dc.l	(30*275)*(30*275)	;$40E8D24
	dc.l	(31*275)*(31*275)	;$454F129
	dc.l	(32*275)*(32*275)	;$49DA400
	dc.l	(33*275)*(33*275)	;$4E8A5A9
	dc.l	(34*275)*(34*275)	;$535F624
	dc.l	(35*275)*(35*275)	;$5859571
; player a3 stops
; .slim = 1000
dostop
	cmpi.w	#$1000,Xvel(a3)	;Xvel
	bgt.w	.set
	cmpi.w	#$F000,Xvel(a3)
	blt.w	.set
	cmpi.w	#$1000,Yvel(a3)	;Yvel
	bgt.w	.set
	cmpi.w	#$F000,Yvel(a3)
	blt.w	.set
	tst.w	position(a3)	;check if goalie
	bne.w	stopna
	jmp	stopna2
	bra.w	stopna
.set
	move.w	#$50C,d1	;#SPAglide
	btst	#pfrev,pflags(a3)	;#pfrev - skating backwards
	bne.w	.0
	bset	#pf2aip,pflags2(a3)	;#pf2aip
	move.w	#$6C6,d1	;#SPAstop
.0
	bsr.w	SetSPA
	tst.w	position(a3)
	bne.w	stopna
	jmp	stopna2
; stop with no animation
stopna
	tst.w	Xvel(a3)	;Xvel
	bpl.w	.xp
	addi.w	#$96,Xvel(a3)
	bmi.w	.y
	clr.w	Xvel(a3)
.xp
	subi.w	#$96,Xvel(a3)
	bpl.w	.y
	clr.w	Xvel(a3)
.y
	tst.w	Yvel(a3)	;Yvel
	bpl.w	.yp
	addi.w	#$96,Yvel(a3)
	bmi.w	rtss2
	clr.w	Yvel(a3)
.yp
	subi.w	#$96,Yvel(a3)
	bpl.w	rtss2
	clr.w	Yvel(a3)
	rts
dirtab	dc.w	0
	;X/Y acc speed for each direction 0-7
	;runspeed constant = 200 ($C8)
	dc.w	$C8
	dc.w	$8D	;runspeed / sqrt(2)
	dc.w	$8D
	dc.w	$C8
	dc.w	0
	dc.w	$8D
	dc.w	$FF73	;- runspeed / sqrt(2)
	dc.w	0
	dc.w	$FF38	;- runspeed
	dc.w	$FF73
	dc.w	$FF73
	dc.w	$FF38
	dc.w	0
	dc.w	$FF73
	dc.w	$8D
	dc.w	0
	dc.w	0
UnpackNibbles	;a0 = packed data, d0 = count: unpack 4-bit values into words at nibblebuffer
	movem.l	d0-d2/a0-a1,-(sp)
	movea.w	#(nibblebuffer-M68K_RAM),a1
	clr.w	d2
	bra.w	.next
.loop
	move.b	(a0)+,d1
	bchg	#0,d2
	bne.w	.lo
	subq.w	#1,a0
	lsr.w	#4,d1
.lo
	andi.w	#$F,d1
	move.w	d1,(a1)+
.next
	dbf	d0,.loop
	movem.l	(sp)+,d0-d2/a0-a1
	rts
WeightedRandomSelect	;d0 = number of word weights at nibblebuffer: return a weighted random index
	movem.l	d1/a1,-(sp)
	movea.w	#(nibblebuffer-M68K_RAM),a1
	clr.w	d1
	bra.w	.pick
.sumloop
	add.w	(a1)+,d1
.pick
	dbf	d0,.sumloop
	move.w	d1,d0
	bsr.w	randomd0
.findloop
	sub.w	-(a1),d0
	bpl.s	.findloop
	suba.w	#$D036,a1
	move.w	a1,d0
	lsr.w	#1,d0
	movem.l	(sp)+,d1/a1
	rts
