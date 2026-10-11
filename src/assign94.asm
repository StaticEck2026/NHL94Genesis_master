; $00C710  Adapted from logic93.asm: player assignments
;	NHL 94 (retail) segment $C710-$D09B
;	92 Logic.Asm part 2, as 93 logic93_2.asm: the player assignments assbench ... asswingd. asswingo (logic94_3)
;	follows at $D09C. 94 has no fight code: assfight and assfwatch are an rts, and the 93 chkhit, ShowInjuryMsg,
;	banner and addinfo are not here. assgoaliebreakwait is new.
;	Transcribed from lst/nhl94.bin.lst lines 37886-38681. Global names are the IDA names except asseben (IDA
;	assben) and assfaceoffp1 (IDA assfaceoffpl), the 93 names. Local labels are the IDA local names (_x -> .x,
;	exit -> .exit, inside assfaceoffp1) or the 93 local where the code matches, else in the 93 style (.x exit, .loop, numbered), with the IDA label, unless generic, in an ;IDA: comment.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp /
;	cmpi; fixopcodes.js patches the cmp encoding after assembly.
;	SortCords offsets (93 names): Xpos 0, Ypos $14, position $34, assnum $36, asslist $38, temp3 $44, temp4 $46,
;	SCnum $52, facedir $54, SPA $58, nopuck $5E, pflags $62, pflags2 $63.

assbench
	btst	#pfalock,pflags(a3)
	bne.w	rtss3
	cmpi.w	#$64,temp1(a3)
	beq.w	.done
	bsr.w	check4bench
	btst	#4,pflags2(a3)
	bne.w	assexit
	bclr	#pfna,pflags(a3)
	beq.w	.nna
	move.w	#8,temp2(a3)
	moveq	#$50,d0
	btst	#pfteam,pflags(a3)
	bne.w	.0
	neg.w	d0
.0
	move.w	d0,temp4(a3)
	move.w	#$88,temp3(a3)
	neg.w	temp3(a3)
	subq.w	#8,temp3(a3)
	clr.w	temp1(a3)
.nna
	move.b	newpnum(a3),d0
	cmp.b	pnum(a3),d0
	beq.w	.nobench
	sub.w	d7,temp1(a3)
	bpl.w	.nodec
	addq.w	#8,temp1(a3)
	move.w	Ypos(a3),d0
	sub.w	temp4(a3),d0
	cmp.w	#$28,d0
	bgt.w	.nodec
	cmp.w	#$FFD8,d0
	blt.w	.nodec
	move.w	(a3),d0
	sub.w	temp3(a3),d0
	cmp.w	#$20,d0
	bgt.w	.nodec
	move.w	#$50C,d1
	tst.w	position(a3)
	bne.w	.gli
	move.w	#2,d1
.gli
	bsr.w	SetSPA
	bset	#pfnc,pflags(a3)
	cmpi.w	#4,facedir(a3)
	beq.w	.ok
	addq.w	#1,facedir(a3)
	andi.w	#7,facedir(a3)
.ok
	clr.w	Yvel(a3)
	move.w	#$F800,Xvel(a3)
	cmp.w	#$10,d0
	bgt.w	.x
	clr.w	Xvel(a3)
	cmpi.w	#4,facedir(a3)
	bne.w	.x
	move.w	#$F800,Xvel(a3)
	move.w	#2,facedir(a3)
	move.w	#$FAC,d1
	bsr.w	SetSPA
	bset	#pfalock,pflags(a3)
	move.w	#$64,temp1(a3)
.x
	rts
.done
	clr.w	frame(a3)
	clr.w	d0
	move.b	pnum(a3),d0
	add.w	d0,d0
	movea.l	#tmstruct,a0
	btst	#6,pflags(a3)
	beq.w	.t0
	adda.w	#tmsize,a0
.t0
	move.w	#$FFFE,tmpdst(a0,d0.w)
	move.b	newpnum(a3),d3
	bsr.w	.nobench2
	jmp	setplayer
.nodec
	btst	#pfnc,pflags(a3)
	bne.s	.x
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	movea.l	#EvadePC,a0
	bra.w	skateto
.nobench
	bclr	#2,pflags2(a3)
.nobench2
	move.b	newpos(a3),d0
	ext.w	d0
	move.w	d0,position(a3)
	jsr	(Setplass).l
	st	newpnum(a3)
	st	$60(a3)
rtss4
	rts
; player a3 should exit bench area
asseben	;IDA: assben (93 asseben). Player a3 should exit the bench area
	btst	#5,pflags(a3)
	bne.s	rtss4
	bclr	#1,pflags(a3)
	beq.w	.1
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	move.w	SCnum(a3),d0
	subq.w	#6,d0
	bmi.w	.0
	addq.w	#1,d0
.0
	muls.w	#$E,d0
	move.w	d0,Ypos(a3)
	move.w	#$88,(a3)
	neg.w	(a3)
	move.w	#2,facedir(a3)
	bset	#5,pflags(a3)
	move.w	#$F6E,d1
	bra.w	SetSPA
.1
	move.w	#4,facedir(a3)
	bclr	#pfnc,pflags(a3)
	bclr	#5,pflags2(a3)
	bclr	#2,pflags2(a3)
	clr.w	SPA(a3)
	move.w	#$1000,Xvel(a3)
	bra.w	assexit
; player a3 should go to penalty box
asspenalty
	btst	#5,pflags(a3)
	bne.s	rtss4
	bclr	#1,pflags(a3)
	beq.w	.nna
	bset	#2,pflags2(a3)	;set player unavailable (pf2unav)
	bsr.w	.clrplayer
	moveq	#-2,d4	;move -2 into d4
	bsr.w	setpads	;moves player number into a temp value so graphics know who it is
	move.w	#8,temp2(a3)	;move 8 into temp2
	moveq	#$B,d0	;move 11 dec into d0
	move.b	(PBnum).w,d1	;gets number of players in PB. 00HV (H=Home, V=Visitors)
	btst	#6,pflags(a3)	;checks if player is home or away
	bne.w	.0	;branch if away
	lsr.w	#4,d1	;shift 4 bits to get Home players in PB
	neg.w	d0	;make d0 negative (different box)
.0
	andi.w	#$F,d1	;pass the first 4 bits of d1 (the team's player total in PB)
	cmp.w	#2,d1	;compare to 2
	bls.w	.1	;branch if less than (1 player in box or less)
	moveq	#2,d1	;add 2 if more than 1 player in box
.1
	addq.w	#3,d1	;add 3 to d1
	muls.w	d0,d1	;mult d0 with d1, store result in d1
	move.w	d1,temp4(a3)	;move d1 into temp4 (skateto YPos)
	move.w	#$88,temp3(a3)	;move 136 decimal into temp3 (skateto XPos)
	clr.w	temp1(a3)	;clear temp1
	bset	#5,pflags2(a3)	;set bit for no player collision
	clr.w	Wallcos(a3)	;clear wallCos (angle of last collision)
	clr.w	Wallsin(a3)	;clear wallSin (angle of last collision)
.nna
	move.w	Ypos(a3),d0	;Current Ypos of player
	sub.w	temp4(a3),d0	;sub temp4 (Y pos to skate to) from Ypos
	cmp.w	#$C,d0	;compare to 13 decimal
	bgt.w	.st	;branch if greater than (still skateto)
	;If its within 13 decimal, it will start the animation for hopping over the board
	cmp.w	#$FFF4,d0
	blt.w	.st
	move.w	(a3),d0
	sub.w	temp3(a3),d0
	cmp.w	#$FFE8,d0
	blt.w	.st
	sub.w	d7,temp1(a3)
	bpl.w	rtss4
	addq.w	#8,temp1(a3)
	bset	#pfnc,pflags(a3)
	move.w	#$50C,d1
	bsr.w	SetSPA
	moveq	#6,d2
	tst.b	handed(a3)
	beq.w	.left
	moveq	#2,d2
.left
	cmp.w	facedir(a3),d2
	beq.w	.ok
	addq.w	#1,facedir(a3)
	andi.w	#7,facedir(a3)
.ok
	clr.w	Yvel(a3)
	move.w	#$1000,Xvel(a3)
	cmp.w	#$FFF8,d0
	blt.w	rtss4
	clr.w	Xvel(a3)
	cmp.w	facedir(a3),d2
	bne.w	rtss4
	bset	#5,pflags(a3)
	move.w	#2,facedir(a3)
	move.w	#$F6E,d1
	bsr.w	SetSPA
	bclr	#4,pflags2(a3)
	move.l	#$D,d0	;assdopen
	bra.w	assreplace
.st
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	movea.l	#rtss2,a0
	bra.w	skateto
.clrplayer	;take the joystick off player a3 (92 asspenalty .clrplayer, 93 global clrplayer)
	btst	#3,pflags(a3)
	beq.w	rtss4
	clr.w	d4
	move.w	SCnum(a3),d0
	cmp.w	(c1playernum).w,d0
	beq.w	changeplayer
	moveq	#2,d4
	bra.w	changeplayer
; add player a3 to penalty box
assdopen
	btst	#5,pflags(a3)
	bne.w	rtss4
	moveq	#$10,d0
	btst	#6,pflags(a3)
	beq.w	.1
	moveq	#1,d0
.1
	add.b	d0,(PBnum).w
	st	position(a3)
	clr.w	frame(a3)
	rts
; player a3 should exit penalty area
assepen
	btst	#5,pflags(a3)
	bne.w	rtss4
	bclr	#1,pflags(a3)
	beq.w	.nna
	bset	#pfnc,pflags(a3)	;set player in no collision mode
	bset	#2,pflags2(a3)	;set player unavailable
	moveq	#$10,d0
	moveq	#$FFFFFFC4,d1
	btst	#6,pflags(a3)
	beq.w	.0
	moveq	#1,d0
	neg.w	d1
.0
	sub.b	d0,(PBnum).w
	move.w	d1,Ypos(a3)
	clr.w	Xvel(a3)
	clr.w	Yvel(a3)
	move.w	#$86,(a3)
	move.w	#2,facedir(a3)
	bset	#5,pflags(a3)
	move.w	#$FAC,d1
	bsr.w	SetSPA
	jmp	SprSort
.nna
	move.w	#4,facedir(a3)
	st	newpnum(a3)
	st	newpos(a3)
	bclr	#pfjoycon,pflags(a3)
	bclr	#pfnc,pflags(a3)
	bclr	#5,pflags2(a3)
	bclr	#2,pflags2(a3)
	move.w	#$F000,Xvel(a3)
	bra.w	assexit
; moves the goalie not being used during shootout/pen shot off the screen
; a3 = goalie who is to be taken off ice
assgoaliebreakwait	;94 only (asstab entry $18DFC)
	btst	#5,pflags(a3)	;check if animation locked
	bne.w	.exit	;exit if so
	btst	#2,(BA_PS_flags).w	;check if pen shot
	bne.w	.1	;branch if so
	btst	#0,(gmode2).w	;check for shootout
	bne.w	.1	;branch if so
	nop
	bra.w	assexit
.1
	clr.w	Xvel(a3)	;clear Xvel
	clr.w	Yvel(a3)	;clear Yvel
	movem.l	d0/a0,-(sp)	;push d0 and a0 on stack
	movea.l	#SortCords,a0	;Home SC Sctruct start
	move.w	(BA_Goalie_SCnum).w,d0	;move Goalie SCNum into d0
	asl.w	#7,d0	;shift d0 7 bits left
	adda.w	d0,a0	;add d0 to address a0
	move.w	#$191,Ypos(a3)	;move 401 decimal into Ypos
	btst	#7,$62(a0)	;check if shooting up or down (a0 is goalie being shot on)
	bne.w	.popstack	;branch if shooting up
	move.w	#$FE6F,Ypos(a3)	;move -191 decimal into Ypos (goalie not being shot on)
.popstack
	movem.l	(sp)+,d0/a0
.exit
	rts
; players do nothing until faceoff is over
assfaceoff
	btst	#5,pflags(a3)
	bne.w	.exit
	btst	#sf2faceoff,(sflags2).w
	beq.w	assexit
.exit
	rts
; assignment for players actually participating in faceoff
; a3 = player
assfaceoffpl	;IDA: assfaceoffpl (93 assfaceoffp1). Face off player (was: assfaceoffp1)
	btst	#5,pflags(a3)
	bne.w	.exit2
	btst	#0,(sflags2).w
	beq.w	.exit
	bclr	#1,pflags(a3)
	beq.w	.nna
	clr.w	temp1(a3)
.nna
	movea.l	#fofdata2,a0
	btst	#6,pflags(a3)
	beq.w	.0
	addq.w	#4,a0
.0
	move.w	SPAnum(a3),d0
	lsr.w	#2,d0
	addq.w	#1,d0
	tst.b	handed(a3)
	bne.w	.lefty
	addq.w	#3,d0
.lefty
	move.w	d0,(a0)
	btst	#pfjoycon,pflags(a3)
	bne.w	.exit2
	bset	#pf2aip,pflags2(a3)
	bne.w	.exit2
	move.w	#$FEA,d1
	cmpi.w	#$10,(SortCords+(puckscnum*SCstruct)+temp1).w
	bls.w	.d
	moveq	#8,d0
	bsr.w	randomd0
	tst.w	d0
	beq.w	.d
	move.w	#$1014,d1
.d
	bset	#1,pflags2(a3)
	bra.w	SetSPA
.exit	;IDA: exit (a global in IDA; local here so it does not split assfaceoffp1)
	move.b	#$14,nopuck(a3)
	bra.w	assexit
.exit2
	rts
assfight	;94: rts only (93 has the fight code here)
	rts	;assfight - possible location where fighting logic used to be
assfwatch	;94: rts only (93 watches the fight)
	rts	;assfwatch - possible location where players watching fight
; player should do nothing
donothing	;(was: assnothing)
	btst	#5,pflags(a3)	;#pfalock
	bne.s	assfwatch
	btst	#3,pflags(a3)	;#pfjoycon
	bne.s	assfwatch
	moveq	#8,d0
	bra.w	doplayeracc
; player skates with stanley cup overhead
assstanley
	btst	#5,pflags(a3)
	bne.s	assfwatch
	bclr	#1,pflags(a3)
	beq.w	.nna
	move.w	#$5A,temp3(a3)
	tst.w	(Hpos).w
	bpl.w	.0
	neg.w	temp3(a3)
.0
	move.w	(Vpos).w,temp4(a3)
	move.w	#$109E,d1
	bsr.w	SetSPA
.nna
	move.w	temp3(a3),d0
	sub.w	(a3),d0
	move.w	temp4(a3),d1
	sub.w	Ypos(a3),d1
	bsr.w	vtoa
	cmp.w	#7,d0
	bgt.s	assfwatch
	move.w	d0,d2
	move.w	d2,facedir(a3)
	bra.w	playeracc
; player a3 celebrates, if scoreing player then do arm pump
assscore
	btst	#5,pflags(a3)
	bne.s	assfwatch
	bclr	#1,pflags(a3)
	beq.w	.nna
	bsr.w	.1
	move.w	#8,temp2(a3)
	move.w	#$5A,temp3(a3)
	tst.w	(Hpos).w
	bpl.w	.0
	neg.w	temp3(a3)
.0
	move.w	(Vpos).w,temp4(a3)
.nna
	movea.l	#rtss2,a0
	move.w	temp3(a3),d0
	move.w	temp4(a3),d1
	btst	#0,(gmode2).w	;start of code not in 92
	beq.w	.4
	tst.w	(shootoutdelay).w
	beq.w	.2
	subq.w	#1,(shootoutdelay).w
	bne.w	.2
	bset	#2,(sflags2).w
.2
	cmpi.w	#$88,(a3)
	bgt.w	.3
	cmpi.w	#$FF78,(a3)
	bgt.w	.4
.3
	clr.w	d1	;end of code not in 92
.4
	sub.w	d7,temp1(a3)
	bpl.w	.ckcon
	bset	#5,pflags(a3)
	move.w	#$E8A,d1
	move.w	(shotplayer).w,d0
	cmp.w	SCnum(a3),d0
	bne.w	.nopump
	move.w	#$EFC,d1
.nopump
	bsr.w	SetSPA
.1
	moveq	#$78,d0
	bsr.w	randomd0
	move.w	d0,temp1(a3)
	rts
.ckcon
	btst	#3,pflags(a3)
	beq.w	skateto
rtss6
	rts
; player a3 is defensive player on offense
assdefo
	btst	#5,pflags(a3)
	bne.s	rtss6
	btst	#gmclock,(gmode).w	;#gmclock
	bne.w	donothing	;Whistle blown, do nothing
	bsr.w	check4bench	;check if player should go to bench
	btst	#3,pflags(a3)	;#pfjoycon - is player joystick controlled
	bne.s	rtss6	;yes, then exit
	bclr	#1,pflags(a3)	;#pfna - checks if theres a new assignment
	beq.w	.nna
	clr.w	temp1(a3)	;clears temp1 if new assignment
	move.w	#8,temp2(a3)	;moves 8 into temp2 if new assignment
.nna
	sub.b	d7,temp1(a3)	;subtract frames elapsed since last call from temp1
	bpl.w	.nodec	;temp1 not zero or negative
	move.b	aioff(a3),temp1(a3)	;Loads aioff into temp1
	jsr	(ReadGoaliePulled).l
	bmi.w	.boost	;branch if goalie is pulled
	btst	#6,(sflags7).w	;check if crowd meter broken
	beq.w	.noboost	;branch if not
	tst.b	temp1(a3)	;check if temp1 is 0
	beq.w	.noboost	;branch if so
.boost
	subq.b	#1,temp1(a3)	;sub 1 from temp1
.noboost
	move.l	#2,d0	;assdefd
	btst	#4,tmflags(a2)	;check if team is offsides
	bne.w	assreplace	;if so, assreplace (assdefd)
	move.w	(pucky).w,d1	;move pucky into d1
	btst	#7,pflags(a3)	;#pfgoal - check which net to score on
	bne.w	.de1	;branch if top
	neg.w	d1	;Negates d1- shooting on bottom net
.de1
	cmp.w	#$5D,d1	;']'   ; slightly above top blueline - checks Y position of puck
	blt.w	assreplace	;not in offensive zone, change assignment
	move.w	(puckc).w,d1	;puck carrier (SCnum) into d1
	bmi.w	.nodec	;branch if no puckc
	subq.w	#6,d1	;sub 6 from d1
	move.w	SCnum(a3),d2	;move SCnum into d2
	subq.w	#6,d2	;sub 6 from d2
	eor.w	d2,d1	;EOR d2 with d1
	bmi.w	assreplace	;ass replace if puckc not on same team
.nodec
	lea	EvadePC(pc),a0	;EvadePC, extra collision routine for skateto
	moveq	#$50,d0	;'P'   ; move 80 dec into d0
	cmpi.w	#2,position(a3)	;position(a3) - checks that player is RD
	beq.w	.1	;branch if RD
	neg.w	d0	;player is LD, so negates d0
.1
	move.w	#$62,d1	;'b'   ; just inside of blueline
	btst	#7,pflags(a3)	;#pfgoal
	bne.w	.0	;branch if top net shooting
	neg.w	d0	;shooting on bottom net, so negate d0 and d1
	neg.w	d1
.0
	move.w	(puckx).w,d2	;move puckx into d2
	eor.w	d0,d2	;XOR d0 with d2
	bmi.w	.2	;branch if puck on the other side of X center
	move.w	(puckx).w,d0	;move puckx to d0
	bra.w	skateto	;d0/d1 are x/y positions, a0 is extra collision routine
.2
	move.w	(puckx).w,d2	;move puckx into d2
	asr.w	#1,d2	;divide by 2
	add.w	d2,d0	;add d2 to d0
	bra.w	skateto	;skateto routine
; player a3 is defensive player on defense
assdefd
	btst	#5,pflags(a3)	;check if locked in animiation
	bne.w	rtss6	;exit if so
	btst	#0,(gmode).w	;check if clock running
	bne.w	donothing	;assnothing if no clock
	bsr.w	check4bench	;check if going to bench
	btst	#3,pflags(a3)	;check if joystick controlled
	bne.w	rtss6	;exit if so
	bclr	#1,pflags(a3)	;clear new assignment bit
	beq.w	.nna	;branch if no new assignment
	clr.w	temp1(a3)	;clear temp1
	move.w	#8,temp2(a3)	;move 8 into temp2
.nna
	sub.b	d7,temp1(a3)	;sub frames elapsed from temp1
	bpl.w	.nodec	;branch if not 0
	move.b	aidef(a3),temp1(a3)	;move DfA into temp1
	btst	#6,(sflags7).w	;check if crowd meter currently broken
	beq.w	.noboost	;branch if not
	tst.b	temp1(a3)	;check if temp1 is 0
	beq.w	.noboost	;branch if so
	subq.b	#1,temp1(a3)	;sub 1 from temp1
.noboost
	move.w	(pucky).w,d1	;move pucky into d1
	move.w	(puckvy).w,d3	;move puckvy into d3
	asr.w	#6,d3	;divide by 64
	btst	#7,pflags(a3)	;check which net shooting on
	bne.w	.de00	;branch if top
	neg.w	d1	;negate d1 and d3 if bottom
	neg.w	d3
.de00
	tst.w	d3	;check if d3 is zero
	bpl.w	.de000	;branch if positive
	clr.w	d3	;clear d3
.de000
	add.w	d1,d3	;add d1 to d3
	cmp.w	#$58,d3	;'X'   ; compare top blueline to d3
	blt.w	.de0
	btst	#4,tmflags(a2)	;check if team is offsides
	bne.w	.de0	;branch if offsides
	move.w	(puckc).w,d1	;move puckc into d1
	bmi.w	.de0	;branch if no puckc
	bsr.w	chkpk	;check if theres a PK
	beq.w	.de0	;branch if on PK
	move.l	#1,d0	;assdefo into d0
	subq.w	#6,d1	;sub 6 from d1
	move.w	SCnum(a3),d2	;move SCnum into d2
	subq.w	#6,d2	;sub 6 from d2
	eor.w	d2,d1	;EOR d2 and d1
	bpl.w	assreplace	;assreplace if puckc on same team
.de0
	move.w	#$41,temp3(a3)	;'A' ; move 65 dec into temp3
	cmpi.w	#2,position(a3)	;compare if player is RD
	beq.w	.de1	;branch if RD
	neg.w	temp3(a3)	;negate temp3 if LD
.de1
	movea.w	#(SortCords-M68K_RAM),a0	;move SC struct start into a0
	cmpi.w	#6,SCnum(a3)	;compare 6 with player SCnum
	bge.w	.de2	;branch if away team
	adda.w	#6*SCstruct,a0	;add 300 to a0 (start at away SC Struct)
.de2
	moveq	#5,d2	;move 5 into d2
	move.w	#$FC18,d0	;move -1000 dec into d0
	btst	#7,pflags(a3)	;check what net shooting at
	beq.w	.gdwn	;branch if bottom net
	neg.w	d0	;negate d0
.gup
	btst	#2,pflags2(a0)	;check if a0 player unavailable
	bne.w	.gu0	;branch if so
	tst.w	position(a0)	;check a0 position
	bmi.w	.gu0	;branch if empty position
	move.w	Yvel(a0),d1	;move Yvel of a0 into d1
	bmi.w	.gu2	;branch if Yvel was negative
	clr.w	d1	;clear d1
.gu2
	asr.w	#4,d1	;divide d1 by 16
	add.w	Ypos(a0),d1	;add Ypos of a0 player to d1
	cmp.w	d0,d1	;compare d0 to d1
	bgt.w	.gu0	;branch if d1 is greater
	move.w	d1,d0	;move d1 into d0
.gu0
	adda.w	#SCstruct,a0	;add 80 (offset to next player struct) to a0
	dbf	d2,.gup	;loop
	subi.w	#$32,d0	;'2'   ; sub $32 (50 dec) from d0
	cmp.w	#$FF42,d0	;compare to $FF42 (-190 dec)
	bgt.w	.gu1	;branch if greater than
	move.w	#$FF24,d0	;move -220 dec into d0
.gu1
	move.w	d0,temp4(a3)	;move d0 into temp4
	move.w	(puckx).w,d0	;move puckx into d0
	move.w	temp3(a3),d1	;move temp3 into d1
	eor.w	d0,d1	;EOR d0 and d1
	bpl.w	.nodec	;branch if puck on same side
	clr.w	temp3(a3)	;clear temp3 if not
	bra.w	.nodec
.gdwn
	btst	#2,pflags2(a0)	;check if player a0 unavail
	bne.w	.gd0	;branch if so
	tst.w	position(a0)	;check a0 position
	bmi.w	.gd0	;branch if empty (goalie)
	move.w	Yvel(a0),d1	;move Yvel of a0 into d1
	bpl.w	.gd2	;branch if positive
	clr.w	d1	;clear d1
.gd2
	asr.w	#4,d1	;divide d1 by 16
	add.w	Ypos(a0),d1	;add Ypos of a0 to d1
	cmp.w	d0,d1	;compare d0 to d1
	blt.w	.gd0	;branch if less than d0
	move.w	d1,d0	;move d1 into d0
.gd0
	adda.w	#SCstruct,a0	;add offset to next player struct
	dbf	d2,.gdwn	;loop
	addi.w	#$32,d0	;'2'   ; add 32 to d0
	cmp.w	#$BE,d0	;compare 190 dec to d0
	blt.w	.gd1	;branch if d0 less than
	move.w	#$DC,d0	;move 220 dec into d0
.gd1
	move.w	d0,temp4(a3)	;move d0 into temp4
	neg.w	temp3(a3)	;negate temp3
	move.w	(puckx).w,d0	;move puckx into d0
	move.w	temp3(a3),d1	;move temp3 into d1
	eor.w	d0,d1	;EOR d0 and d1
	bpl.w	.nodec	;branch if puck on same side
	clr.w	temp3(a3)	;clear temp3 if not
.nodec
	move.w	temp3(a3),d0	;move temp3 to d0
	move.w	temp4(a3),d1	;move temp4 to d1
	movea.l	#EvadePC,a0	;EvadePC to a0
	bsr.w	skateto
	bra.w	check4check
rtss21
	rts
; player a3 is winger on defense
asswingd
	btst	#5,pflags(a3)	;check if locked in animation
	bne.s	rtss21	;exit if so
	btst	#0,(gmode).w	;check if clock is running
	bne.w	donothing	;assnothing if its stopped
	bsr.w	check4bench	;check if going to bench
	btst	#3,pflags(a3)	;check if joystick controlled
	bne.s	rtss21	;exit if so
	bclr	#1,pflags(a3)	;clear new assignment bit
	beq.w	.nna	;branch if cleared already (no new assignment)
	clr.w	temp1(a3)	;clear temp1
	move.w	#8,temp2(a3)	;move 8 into temp2
.nna
	sub.b	d7,temp1(a3)	;sub frames elapsed from temp1
	bpl.w	.nodec	;branch if not 0
	move.b	aidef(a3),temp1(a3)	;move DfA into temp1
	btst	#6,(sflags7).w	;check if crowd meter currently broken
	beq.w	.noboost	;branch if not
	tst.b	temp1(a3)	;check if temp1 is 0
	beq.w	.noboost	;branch if 0
	subq.b	#1,temp1(a3)	;sub 1 from temp1
.noboost
	move.w	(puckc).w,d1	;move puckc into d1
	bmi.w	.nodec	;branch if no puck carrier
	move.l	#4,d0	;asswingo into d0
	subq.w	#6,d1	;sub 6 from d1
	move.w	SCnum(a3),d2	;move SCnum into d2
	subq.w	#6,d2	;sub 6 from d2
	eor.w	d2,d1	;EOR d2 with d1. Checks if player on same team
	bpl.w	assreplace	;branch if team has puck
.nodec
	moveq	#$64,d0	;'d'   ; move 64 (100 dec) into d0
	cmpi.w	#5,position(a3)	;check if player is RW
	bne.w	.1	;branch if not
	neg.w	d0	;make d0 negative
.1
	move.l	#$9E,d1	;move $9E into d1 (blueline + 70 dec)
	btst	#7,pflags(a3)	;check which goal shooting at
	beq.w	.0	;branch if bottom goal
	neg.w	d0	;negate d0
	neg.w	d1	;negate d1
	moveq	#$FFFFFFB2,d2	;move into d2 (slightly above bottom blue line)
	btst	#4,tmflags(a2)	;check bit 4 of offset 30 (currently offside)
	;Home - C6FE
	;Away - CA62
	bne.w	.dg11	;branch if set
	cmp.w	(pucky).w,d2	;compare pucky to d2
	bgt.w	.ug1	;branch if puck in defensive zone
	move.w	(pucky).w,d1	;move pucky into d1
	bra.w	.z1
.ug1
	move.w	#$FEF8,d2	;move bottom goal line into d2
	cmp.w	(pucky).w,d2	;compare pucky to d2
	blt.w	.z1	;branch if puck in defensive zone
	move.w	d2,d1	;move d2 into d1 if puck behind goal line
	bra.w	.z1
.0
	moveq	#$4E,d2	;'N'   ; defending top goal
	;4E - slightly below top blue line
	btst	#4,tmflags(a2)	;check bit 4 of offset 30
	;Home - C6FE
	;Away - CA62
	bne.w	.dg11	;branch if set
	cmp.w	(pucky).w,d2	;compare pucky to d2
	blt.w	.dg1	;branch if puck in defensive zone
	move.w	(pucky).w,d1	;move pucky into d1
	bra.w	.z1
.dg1
	move.w	#$108,d2	;move top goal line into d2
	cmp.w	(pucky).w,d2	;compare pucky to d2
	bgt.w	.z1	;branch if puck in between goal line and blue line
.dg11
	move.w	d2,d1	;move d2 into d1 if puck behind goal line
.z1
	lea	rtss21(pc),a0
	move.w	(puckx).w,d2	;move puckx into d2
	eor.w	d0,d2	;EOR d0 and d2
	bmi.w	skateto	;branch if minus - skate to d0/d1, no extra routine
	move.w	(puckx).w,d0	;move puckx into d0
	bra.w	skateto	;skate to d0/d1 no extra routine
; player a3 is winger on offense
