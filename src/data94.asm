; $017C72  Adapted from hockey93.asm: menus, season results, string tables
;	NHL 94 (retail) segment $17C72-$1837F
;	92 hockey.asm DefaultMenus, NewPO, MakeTree, FigureJoy and the playoff password code, as 93 hockey93_09: DefaultMenus (IDA
;	LoadDefMenuOptions), ContinuePlayoffs (93 NewPO), NewPO (93 SelectRandomPlayoffTree), MakeTree, FigureJoy, InitializeGameStructures, OptionRNG,
;	ReadPassBits ... SuperDiv, GetShifter, and the playoff stat packing (AddPOStats, BitWidthTable, ReadTeamStats). It follows
;	attract94 ($17C71) with no gap. ResolveGames starts hockey94_10.
;	94 keeps the playoff bits in pwddatabuffer (93 name) and saves them through WriteLineData (where 93 calls BitsToPW).
;	94 adds FourWayPlay (cont3team / cont4team, the Three and Four player choices) and Shootout, and has 9 menu options (93 7).
;	Transcribed from lst/nhl94.bin.lst lines 54836-55537. Global names are the IDA names, or the 93 name where IDA has an auto name.
;	Locals are the IDA local names (_x -> .x) or the 93 local where the code matches, else in the 93 style (.x exit, .loop, numbered), with the IDA label, unless generic,
;	in an ;IDA: comment.
;	The only IDA gap is BitWidthTable (IDA dc.b).
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	RAM (IDA names, 93 names): potree, WinBits, pojoy (93 playoffroundoffset), statsbuffer,
;	tpassbits. gsstruct game ($10 bytes, 93 gstruct): 0 gst1, 2 gst2, 4 gspotwins, 6 gspobwins, 8 gsper, $A gss1, $C gss2,
;	$E gsflags (bits 0 gsftf teams flipped, 1 gsfhl hilite, 2 gsfso series over).

DefaultMenus	;IDA: LoadDefMenuOptions. Set the default menu choices for the beginning of the game: the 9 option words from defmenuoptions (93: 7). Called once from Begin
	st	(demoflag).w	;no demo has run yet
	movea.l	#OptPlayMode,a0	;Start of Menu Options in RAM
	movea.l	#defmenuoptions,a1
	move.w	#8,d0	;9 options (93 6)
.loop
	move.w	(a1)+,(a0)+
	dbf	d0,.loop
	rts
defmenuoptions	;IDA name (93 DefaultMenus .defom). Regular Season, One - Home, MTL, LA, 10 Minutes, Manual Control, User Records Off, Penalties Off,
	;Line Changes Off (the hockey94_08 value lists; 93 0,1,$F,3,1,0,1)
	dc.w	0	;Play Mode
	dc.w	1	;Players
	dc.w	$B	;Team 1
	dc.w	$A	;Team 2
	dc.w	1	;Per Length
	dc.w	0	;Goalies
	dc.w	1	;User Records
	dc.w	0	;Penalties
	dc.w	1	;Line Changes
ContinuePlayoffs	;IDA name, kept: this is 93 NewPO, but IDA gives the name NewPO to the next routine (93 SelectRandomPlayoffTree). Continue playoffs:
	;read the playoff state back from the saved bits at pwddatabuffer (93 name), rebuild the tree and set OptNOP from pojoy (93 playofflevel
	;= 7 - playoffroundoffset; 94 7 or $B with FourWayPlay, pojoy adjusted to the pad set-ups). Called from hockey94_08 (GoContinuePlayoffs, GameSetUp_3)
	movem.l	d0-d7/a0-a3,-(sp)
	movea.w	#(pwddatabuffer-M68K_RAM),a3
	bsr.w	ReadPassBits
	move.w	(gamelevel).w,d0
	or.w	(bosgames).w,d0
	beq.w	.x	;level 0, game 0: nothing played yet
	bsr.w	maketree
	moveq	#7,d0
	tst.w	(FourWayPlay).w
	beq.w	.0
	move.w	#$B,d0
.0
	tst.w	(FourWayPlay).w
	bne.w	.1
	cmpi.w	#2,(pojoy).w
	blt.w	.3
	subq.w	#2,(pojoy).w
	bra.w	.3
.1
	cmpi.w	#1,(pojoy).w
	bne.w	.2
	move.w	#3,(pojoy).w
	bra.w	.3
.2
	cmpi.w	#2,(pojoy).w
	bne.w	.3
	move.w	#4,(pojoy).w
.3
	sub.w	(pojoy).w,d0
	move.w	d0,(OptNOP).w
.x
	movem.l	(sp)+,d0-d7/a0-a3
	rts
NewPO	;IDA name (92 NewPO, 93 SelectRandomPlayoffTree). New playoff generates tree with same team 1. Called from hockey94_08 (j_NewPO). Falls into MakeTree
	moveq	#$20,d0	;' '   ; 20 = 32 decimal
	bsr.w	randomd0
.top
	addq.w	#1,d0	;adds 1 to d0 (d0 cannot be 0)
	andi.w	#$1F,d0	;mask d0 with 1F (31 decimal). Makes sure its 31 or less
	asl.w	#4,d0	;multiply d0 by 16
	movea.l	#playoffseats,a0
	adda.w	d0,a0	;use d0 as offset
	lsr.w	#4,d0	;divide d0 by 16
	moveq	#$F,d1	;move 15 into d1
	move.w	(Opt1Team).w,d2	;Team 1 on menu
	cmp.w	#$19,d2	;compares #NumOfTeams-3 to d2 (25 decimal)
	bls.w	.loop	;branch if d2 less than 19 hex
	moveq	#$19,d2	;move 19 into d2 (limits team selection; all-star teams use team 25, 93 23)
.loop
	cmp.b	(a0)+,d2	;compare team at a0+ to d2 (looks at second byte of a0)
	dbeq	d1,.loop	;iterate through loop until team is found
	bne.s	.top
	eori.w	#$F,d1
	move.w	d1,(potreeteam).w	;which team are you on the initial playoff tree
	move.w	d0,(postarts).w	;0-31 for which playoff tree to use as frame
	clr.w	(gamelevel).w	;0-3 for the depth into the playoff tree
	move.w	#7,(bosgames).w	;0-6 game of series or 7 if not in best of seven
	cmpi.w	#2,(OptPlayMode).w	;play mode on Main Menu
	beq.w	maketree	;jump to make playoff tree if play mode is 2
	clr.w	(bosgames).w	;best of seven: game 0
	moveq	#7,d0	;clr games won
	movea.w	#(gsstruct-M68K_RAM),a0	;Game struct variables start
.cg
	clr.w	4(a0)	;gspotwins
	clr.w	6(a0)	;gspobwins
	adda.w	#$10,a0	;gssize
	dbf	d0,.cg	;falls into MakeTree
maketree	;IDA name (93 maketree, 92 MakeTree). Make the playoff tree (potree, 93 name) from playoffseats and the winbits (WinBits, 93
	;WinBits), clear the scores of this round's games and set their teams (.sett), then FigureJoy. Called from ContinuePlayoffs, EncodePW and hockey94_08
	;(SetupStart); falls in from NewPO
	movem.l	d0-d4/a0-a3,-(sp)
	move.w	(postarts).w,d1
	asl.w	#4,d1
	movea.w	#(potree-M68K_RAM),a0
	movea.l	#playoffseats,a1
	adda.w	d1,a1
	move.l	(a1),(a0)	;first round: 16 teams from the tree
	move.l	4(a1),4(a0)
	move.l	8(a1),8(a0)
	move.l	$C(a1),$C(a0)
	lea	$10(a0),a1
	moveq	#$E,d2	;15 winners
	move.w	(WinBits).w,d0
.0
	move.w	d0,d1
	andi.w	#1,d1	;winbit picks the top or bottom team of the pair
	move.b	0(a0,d1.w),(a1)+
	addq.w	#2,a0
	lsr.w	#1,d0
	dbf	d2,.0
	bsr.w	GetShifter
	tst.w	d1
	bmi.w	.nogames	;playoffs over
	movea.w	#(potree-M68K_RAM),a0
	adda.w	d2,a0
	adda.w	d2,a0
	movea.w	#(gsstruct-M68K_RAM),a1
.loop
	clr.w	gss1(a1)	;gsstruct: gss1
	clr.w	gss2(a1)	;gss2
	clr.w	gsper(a1)	;gsper
	bclr	#1,gsflags(a1)	;hilite requested (92 gsfhl)
	bsr.w	.sett	;93 local .sett
	adda.w	#gssize,a1
	dbf	d1,.loop
	bsr.w	FigureJoy
.nogames
	movem.l	(sp)+,d0-d4/a0-a3
	rts
.sett	;93 .sett. Series games 2, 3, 5: tree order, others swapped
	cmpi.w	#2,(bosgames).w
	beq.w	.1
	cmpi.w	#3,(bosgames).w
	beq.w	.1
	cmpi.w	#5,(bosgames).w
	beq.w	.1
	bset	#0,gsflags(a1)	;teams are flipped (92 gsftf)
	move.b	(a0)+,gst2+1(a1)
	move.b	(a0)+,gst1+1(a1)
	rts
.1
	bclr	#0,gsflags(a1)	;(93 .flip) gsftf
	move.b	(a0)+,gst1+1(a1)
	move.b	(a0)+,gst2+1(a1)
	rts
FigureJoy	;IDA name (92 / 93 FigureJoy). Set contteams appropriately: cont1team ... cont4team (94 adds 3 and 4 for FourWayPlay). In the playoffs
	;(not Shootout, gmode2 bit 0) find this round's game of the po team and set the teams and pads from .pojoylist (.pojoylist2 with
	;FourWayPlay); otherwise from .noplist by OptNOP. After a demo (demoflag clear), and outside the playoffs, fill gsstruct with random matchups
	;(InitializeGameStructures). Called from MakeTree and hockey94_08 GameSetUp
	movem.l	d0-d3/a0-a1,-(sp)
	clr.w	(cont1team).w
	clr.w	(cont2team).w
	clr.w	(cont3team).w
	clr.w	(cont4team).w
	tst.w	(demoflag).w
	beq.w	.init	;demo ran
	tst.w	(OptPlayMode).w
	beq.w	.fjnpo	;regular season
	btst	#0,(gmode2).w
	bne.w	.fjnpo	;shootout (94)
	bsr.w	GetShifter
	movea.w	#(potree-M68K_RAM),a0	;#potree
	move.w	(potreeteam).w,d2
	move.b	0(a0,d2.w),d2	;po team
	movea.w	#(gsstruct-M68K_RAM),a1
	moveq	#gssize,d4
	mulu.w	d1,d4
	adda.w	d4,a1
	st	(gamenum).w
	clr.w	d0
.f0
	cmp.w	(a1),d2
	beq.w	.it1
	cmp.w	gst2(a1),d2
	beq.w	.it2
	suba.w	#gssize,a1
	dbf	d1,.f0
	bra.w	.ex	;po team not in playoffs
.it2
	moveq	#4,d0
	tst.w	(FourWayPlay).w
	beq.w	.it22
	move.w	#5,d0
.it22
	move.w	(a1),(Opt2Team).w	;(93 menuawayteam)
	move.w	gst2(a1),(Opt1Team).w
	bra.w	.itx
.it1
	clr.w	d0
	move.w	gst2(a1),(Opt2Team).w
	move.w	(a1),(Opt1Team).w
.itx
	add.w	(pojoy).w,d0	;(93 playoffroundoffset)
	move.w	d1,(gamenum).w
	move.w	(a1),(HomeTeam).w
	move.w	gst2(a1),(VisTeam).w
	asl.w	#2,d0
	lea	.pojoylist(pc),a0
	tst.w	(FourWayPlay).w
	beq.w	.0
	lea	.pojoylist2(pc),a0
.0
	move.w	0(a0,d0.w),(cont1team).w
	move.w	2(a0,d0.w),(cont2team).w
	tst.w	(FourWayPlay).w
	beq.w	.ex
	cmp.w	#4,d0
	beq.w	.1	;pojoy 1: cont3team / cont4team = cont1team / cont2team
	cmp.w	#$18,d0
	beq.w	.1
	bra.w	.2
.1
	move.w	(cont1team).w,(cont3team).w
	move.w	(cont2team).w,(cont4team).w
	bra.w	.ex
.2
	cmp.w	#8,d0
	beq.w	.3	;pojoy 2: cont3team = cont1team, cont4team 0
	cmp.w	#$1C,d0
	beq.w	.3
	bra.w	.ex
.3
	move.w	(cont1team).w,(cont3team).w
	move.w	#0,(cont4team).w
	bra.w	.ex
.pojoylist	;IDA: _pojoylist. cont1team, cont2team for pojoy 0-3 with the po team as team 1, then as team 2
	dc.w	1
	dc.w	0
	dc.w	1
	dc.w	1
	dc.w	1
	dc.w	2
	dc.w	2
	dc.w	1
	dc.w	2
	dc.w	0
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	1
	dc.w	1
	dc.w	2
.pojoylist2	;IDA: _pojoylist2. The same with FourWayPlay, pojoy 0-4
	dc.w	1
	dc.w	0
	dc.w	1
	dc.w	2
	dc.w	1
	dc.w	2
	dc.w	1
	dc.w	1
	dc.w	1
	dc.w	2
	dc.w	2
	dc.w	0
	dc.w	2
	dc.w	1
	dc.w	2
	dc.w	1
	dc.w	2
	dc.w	2
	dc.w	2
	dc.w	1
.fjnpo	;IDA: _fjnpo. 93 used playofflevel
	move.w	(OptNOP).w,d0
	asl.w	#2,d0
	lea	.noplist(pc),a0
	move.w	0(a0,d0.w),(cont1team).w
	move.w	2(a0,d0.w),(cont2team).w
	cmp.w	#$14,d0	;Three
	bne.w	.4
	move.w	(cont1team).w,(cont3team).w
	move.w	#0,(cont4team).w
	bra.w	.init
.4
	cmp.w	#$18,d0	;Four
	bne.w	.init
	move.w	(cont1team).w,(cont3team).w
	move.w	(cont2team).w,(cont4team).w
.init
	bsr.w	InitializeGameStructures	;(93 .init)
.ex
	movem.l	(sp)+,d0-d3/a0-a1
	rts
.noplist	dc.w	0	;IDA: _noplist. cont1team, cont2team by OptNOP 0-6 (93 0-4)
	dc.w	0
	dc.w	1
	dc.w	0
	dc.w	2
	dc.w	0
	dc.w	1
	dc.w	1
	dc.w	1
	dc.w	2
	dc.w	1
	dc.w	2
	dc.w	1
	dc.w	2
InitializeGameStructures	;93 name. Random team pairs for all 8 gsstruct games, none of them HomeTeam or VisTeam. Called from FigureJoy
	st	(gamenum).w
	clr.l	d3	;d3 = used team bits
	move.w	(HomeTeam).w,d1
	bset	d1,d3
	move.w	(VisTeam).w,d1
	bset	d1,d3
	movea.w	#(gsstruct-M68K_RAM),a1
	moveq	#7,d2
.loop
	bsr.w	GetRandomUnusedTeam
	move.w	d0,(a1)
	bsr.w	GetRandomUnusedTeam
	move.w	d0,gst2(a1)
	adda.w	#gssize,a1
	dbf	d2,.loop
	rts
GetRandomUnusedTeam	;93 name (IDA: OptionRNG). Calls randomd0 when changing options: return d0 = a random team 0-25 (93 0-23) not yet set in d3, and set its bit. Called from InitializeGameStructures
	moveq	#$1A,d0
	bsr.w	randomd0
	bset	d0,d3
	bne.s	GetRandomUnusedTeam
	rts
ReadPassBits	;93 name. Translate the saved bits at a3 (5 words) to the playoff variables; the 5 words are kept. 94: pojoy has 8
	;values (93 4), and without FourWayPlay pojoy 1 / 2 become 4. Called from ContinuePlayoffs, EncodePW and hockey94_08 GameSetUp
	moveq	#4,d0
	lea	$A(a3),a0
.save
	move.w	-(a0),-(sp)	;SuperDiv destroys the bits
	dbf	d0,.save
	moveq	#7,d2
	movea.w	#(gsstruct+(7*$10)-M68K_RAM),a1	;last gsstruct game (gsstruct + 7 * $10)
.loop
	bclr	#2,gsflags(a1)	;series over (92 gsfso)
	moveq	#5,d0
	bsr.w	SuperDiv
	move.w	d0,gspobwins(a1)	;gspobwins
	cmp.w	#4,d0
	bne.w	.nsf0
	bset	#2,gsflags(a1)
.nsf0
	moveq	#5,d0
	bsr.w	SuperDiv
	move.w	d0,gspotwins(a1)	;gspotwins
	cmp.w	#4,d0
	bne.w	.nsf1
	bset	#2,gsflags(a1)
.nsf1
	suba.w	#gssize,a1
	dbf	d2,.loop
	move.w	#$4000,d0
	bsr.w	SuperDiv
	move.w	d0,(WinBits).w	;winbits (93 WinBits)
	move.w	#8,d0
	bsr.w	SuperDiv
	move.w	d0,(pojoy).w	;(93 playoffroundoffset)
	tst.w	(FourWayPlay).w
	bne.w	.1
	cmpi.w	#1,(pojoy).w
	beq.w	.0
	cmpi.w	#2,(pojoy).w
	bne.w	.1
.0
	move.w	#4,(pojoy).w
.1
	moveq	#$10,d0
	bsr.w	SuperDiv
	move.w	d0,(potreeteam).w
	moveq	#4,d0
	bsr.w	SuperDiv
	move.w	d0,(gamelevel).w
	moveq	#8,d0
	bsr.w	SuperDiv
	move.w	d0,(bosgames).w
	moveq	#$20,d0
	bsr.w	SuperDiv
	move.w	d0,(postarts).w
	moveq	#4,d0
	lea	(a3),a0
.restore
	move.w	(sp)+,(a0)+	;put the bits back
	dbf	d0,.restore
	rts
EncodePW	;93 name. After a playoff game compute winners and save the bits if needed. 94 returns at once for Demo, Regular
	;Season and Shootout, and sets TempOptPlayMode with OptPlayMode. The bits are pwddatabuffer (93 name); WriteLineData (not matched yet) is
	;where 93 calls BitsToPW. Called from GameOver (hockey94_06)
	tst.w	(OptNOP).w
	beq.w	rtss2
	tst.w	(OptPlayMode).w
	beq.w	rtss2
	cmpi.w	#4,(OptPlayMode).w
	beq.w	rtss2
	move.w	#1,(OptPlayMode).w	;continue playoffs
	move.w	#1,(TempOptPlayMode).w
	bsr.w	ResolveGames	;93 ResolveGames (hockey94_10)
	bsr.w	maketree
	cmpi.w	#4,(gamelevel).w
	beq.w	.0	;finished playoffs
	tst.w	(gamenum).w
	bmi.w	.0	;po team out, same as a win
	movea.w	#(pwddatabuffer-M68K_RAM),a3
	bsr.w	WritePassBits
	jsr	(WriteLineData).l
	btst	#sf3alttree,(sflags3).w	;93 sf3alttree
	beq.w	rtss2
	movea.w	#(tpassbits-M68K_RAM),a3	;bits before all games resolved (93 tpassbits)
	bsr.w	ReadPassBits
	bra.w	maketree
.0
	movea.w	#(pwddatabuffer-M68K_RAM),a3
	bsr.w	ClrPassBits
	jsr	(WriteLineData).l
	move.w	#2,(OptPlayMode).w	;new playoffs
	move.w	#2,(TempOptPlayMode).w
	cmpi.w	#7,(bosgames).w
	beq.w	rtss2
	move.w	#3,(OptPlayMode).w	;new playoffs best of 7
	move.w	#3,(TempOptPlayMode).w
	rts
WritePassBits	;93 name. Transfer the game variables to the bits at a3 (pojoy range 8, 93 4). Called from EncodePW and ResolveGames (hockey94_10)
	bsr.w	ClrPassBits
	move.w	(postarts).w,d0
	moveq	#$20,d1
	bsr.w	PushBits
	move.w	(bosgames).w,d0
	moveq	#8,d1
	bsr.w	PushBits
	move.w	(gamelevel).w,d0
	moveq	#4,d1
	bsr.w	PushBits
	move.w	(potreeteam).w,d0
	moveq	#$10,d1
	bsr.w	PushBits
	move.w	(pojoy).w,d0
	moveq	#8,d1
	bsr.w	PushBits
	move.w	(WinBits).w,d0
	move.w	#$4000,d1	;92 1<<14
	bsr.w	PushBits
	moveq	#5,d1
	moveq	#7,d2
	movea.w	#(gsstruct-M68K_RAM),a1
.loop
	move.w	gspotwins(a1),d0
	bsr.w	PushBits
	move.w	gspobwins(a1),d0
	bsr.w	PushBits
	adda.w	#gssize,a1
	dbf	d2,.loop
	rts
PushBits	;93 name. bits = bits * d1 + d0. d1 = range 2^1-2^15, d0 = data
	movem.l	d0-d1,-(sp)
	exg	d0,d1
	bsr.w	SuperMult
	clr.l	d0
	move.w	d1,d0
	bsr.w	SuperAdd
	movem.l	(sp)+,d0-d1
	rts
ClrPassBits	;93 name. Clear the 5 words of bits at a3
	movea.w	a3,a0
	moveq	#4,d0
.0
	clr.w	(a0)+
	dbf	d0,.0
	rts
SuperAdd	;93 name. 1 long (d0.L) added to the 5 words at a3
	movem.l	d1/a0,-(sp)
	lea	$A(a3),a0
	moveq	#3,d1
	add.l	d0,-(a0)
	bra.w	.2
.1
	addq.w	#1,-(a0)	;carry into the next word up
.2
	dbcc	d1,.1
	movem.l	(sp)+,d1/a0
	rts
SuperMult	;93 name. 1 word (d0) multiplied by the 5 words at a3
	movem.l	d1-d4/a0,-(sp)
	movea.w	a3,a0
	moveq	#4,d4
.0
	move.w	(a0),-(sp)
	clr.w	(a0)+
	dbf	d4,.0
	moveq	#4,d4
.1
	move.w	d0,d1
	mulu.w	(sp)+,d1
	lea	2(a3),a0
	adda.w	d4,a0
	adda.w	d4,a0
	move.w	d4,d2
	add.l	d1,-(a0)
	bra.w	.3
.2
	addq.w	#1,-(a0)
.3
	dbcc	d2,.2
	dbf	d4,.1
	movem.l	(sp)+,d1-d4/a0
	rts
SuperDiv	;93 name. 5 words at a3 divided by 1 word (d0); d0 = remainder on exit
	movem.l	d1-d2/a0,-(sp)
	movea.w	a3,a0
	moveq	#4,d1
	clr.l	d2
.0
	move.w	(a0),d2
	divu.w	d0,d2
	move.w	d2,(a0)+
	dbf	d1,.0
	swap	d2
	move.w	d2,d0
	movem.l	(sp)+,d1-d2/a0
	rts
GetShifter	;IDA name (92 / 93 GetShifter). Returns d1 = number of games - 1, d2 = first bit of WinBits (WinBits)
	move.l	d0,-(sp)
	moveq	#-$10,d2
	moveq	#$10,d1
	move.w	(gamelevel).w,d0
.3
	add.w	d1,d2
	lsr.w	#1,d1
	dbf	d0,.3
	subq.w	#1,d1
	move.l	(sp)+,d0
	rts
DisplayTeamStatsForPlayoffs	;93 name (IDA: AddPOStats). Add the po team's game stats to its packed playoff totals: unpack them (ReadTeamStats),
	;add the $68 stat bytes at team struct + $B4, then pack each total back into the bit stream below outputbuffer + $DE (93 + $5E), clamped to its
	;BitWidthTable width. Called from PeriodOver
	cmpi.w	#1,(OptPlayMode).w
	blt.w	rtss2	;regular season
	bsr.w	ReadTeamStats
	movea.w	#(potree-M68K_RAM),a0
	move.w	(potreeteam).w,d2
	move.b	0(a0,d2.w),d2	;po team
	movea.w	#(HmShots-M68K_RAM),a2
	cmp.w	Xvel(a2),d2
	beq.w	.0
	adda.w	#$364,a2	;tmsize: the po team is the visitor
.0
	adda.w	#$B4,a2
	moveq	#$67,d0	;$68 stats
	movea.w	#(statsbuffer-M68K_RAM),a1	;93 statsbuffer
.loop
	clr.w	d1
	move.b	(a2)+,d1
	add.w	d1,(a1)+
	dbf	d0,.loop
	movea.w	#(statsbuffer-M68K_RAM),a0
	movea.l	#BitWidthTable,a1
	movea.w	#(outputbuffer-M68K_RAM),a2
	moveq	#$67,d0
	clr.w	d4
.loop2
	clr.l	d1
	move.w	(a0)+,d1
	move.w	d0,d2
	andi.w	#3,d2
	move.b	0(a1,d2.w),d2	;d2 = bit width
	clr.l	d3
	bset	d2,d3
	subq.w	#1,d3	;d3 = max value
	cmp.w	d3,d1
	ble.w	.1
	move.w	d3,d1	;clamp
.1
	not.l	d3
	move.w	d4,d5
	andi.w	#$F,d5
	rol.l	d5,d3
	rol.l	d5,d1
	move.w	d4,d5
	lsr.w	#4,d5
	add.w	d5,d5
	neg.w	d5	;the stream runs down in words
	addi.w	#$100,d5
	and.l	d3,-$22(a2,d5.w)
	or.l	d1,-$22(a2,d5.w)
	add.w	d2,d4
	dbf	d0,.loop2
	rts
BitWidthTable	;93 name. Playoff stat bit widths, indexed by stat number & 3 (93 8, $A, 6, 6)
	dc.b	$C,$E,$A,$A
ReadTeamStats	;93 name. Unpack the $68 playoff stat totals from the bit stream into statsbuffer (93 name) words. Called from AddPOStats and DisplayTeamStats
	movea.w	#(statsbuffer-M68K_RAM),a0
	movea.l	#BitWidthTable,a1
	movea.w	#(outputbuffer-M68K_RAM),a2
	moveq	#$67,d0
	clr.w	d4
.loop
	move.w	d4,d5
	lsr.w	#4,d5
	add.w	d5,d5
	neg.w	d5
	addi.w	#$100,d5
	move.l	-$22(a2,d5.w),d1
	move.w	d4,d5
	andi.w	#$F,d5
	lsr.l	d5,d1
	move.w	d0,d2
	andi.w	#3,d2
	move.b	0(a1,d2.w),d2
	add.w	d2,d4
	clr.w	d3
	bset	d2,d3
	subq.w	#1,d3
	and.w	d3,d1
	move.w	d1,(a0)+
	dbf	d0,.loop
	rts
;	NHL 94 (retail) segment $18380-$18CFB
;	92 hockey.asm ResolveGames and the 92 exception handlers, as 93 hockey93_10: ResolveGames, the end of game Stars of the Game box
;	(DisplayPeriodOver, FindMaxAttributeTEam, CalculateTeamAttributes / Values), the injury box (ShowInjuryBox), the 94-only penalty
;	shot box (PenaltyShotBox), the goal box (DisplayPlayerAttributeMenu), box, the player name formatters (GetTempPlayerName, getname ...
;	FinalizeTextBuffer, getplayername, d0toascii) and AddError, Illinst, ZeroDiv and crash. cd0 (hockey94_11) follows at $18CFC.
;	Transcribed from lst/nhl94.bin.lst lines 55538-56542. Global names are the IDA names, or the 93 name where IDA has an auto name
;	(IDA name, unless generic, in an ;IDA: comment); the exception handlers have the main94 vector names. Locals are the IDA local names (_x -> .x)
;	or the 93 local where the code matches, else in the 93 style (.x exit, .loop, numbered), with the IDA label, unless generic, in an ;IDA: comment; crash's helper is the 93 local .ri.
;	IDA gaps written from the retail bytes: the printz / printbigz / appendz strings that IDA shows as code or dc.b, the instructions
;	IDA hid in them (moveq #$1B,d0, moveq #$13,d0, move.w (BA_Checker_Offset).w,d0, two move.w d0,-(sp), the exception handlers'
;	move.l $A(sp),d0 / 2(sp),d0), and the printbig String tables.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.
;	gsstruct game ($10 bytes, 93 gstruct): 0 gst1, 2 gst2, 4 gspotwins, 6 gspobwins, 8 gsper, $A gss1, $C gss2, $E gsflags.
;	Team struct: $C goals, $28 team, $B4 / $CE / $E8 goals / assists / shots bytes per roster slot, $136 frames on ice; tmsize $364.

ResolveGames	;93 name. Compute winners and losers for playoff matchups (92 ResolveGames). Called from EncodePW (hockey94_09)
	move.w	(gamenum).w,d0
	mulu.w	#gssize,d0
	movea.w	#(gsstruct-M68K_RAM),a0
	move.w	(HmGoals).w,gss1(a0,d0.w)	;copy score from played game into game structures (gss1, gss2)
	move.w	(AwGoals).w,gss2(a0,d0.w)
	bsr.w	GetShifter
	movea.w	#(gsstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
	cmpi.w	#7,(bosgames).w
	beq.w	.notbos	;not best of 7
.loop
	cmpi.w	#4,gspotwins(a0)	;series complete? (gspotwins)
	beq.w	.b1
	cmpi.w	#4,gspobwins(a0)
	beq.w	.b1
	clr.w	d3
	btst	#0,gsflags(a0)	;teams flipped (92 gsftf)
	beq.w	.0
	eori.w	#gspobwins-gspotwins,d3
.0
	move.w	gss1(a0),d0
	sub.w	gss2(a0),d0
	bpl.w	.1
	eori.w	#gspobwins-gspotwins,d3
.1
	addq.w	#1,gspotwins(a0,d3.w)	;one more win
.b1
	suba.w	#gssize,a0
	dbf	d1,.loop
	addq.w	#1,(bosgames).w
	cmpi.w	#7,(bosgames).w
	beq.w	.nextround
	move.w	(gamenum).w,d0
	mulu.w	#gssize,d0
	movea.w	#(gsstruct-M68K_RAM),a0
	adda.w	d0,a0
	cmpi.w	#4,gspotwins(a0)
	beq.w	.cround
	cmpi.w	#4,gspobwins(a0)
	bne.w	rtss2
.cround
	cmpi.w	#3,(gamelevel).w	;finish off rest of round games here
	bge.w	.nextround
	bsr.w	GetShifter
	movea.w	#(gsstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
.cr0
	cmp.w	(gamenum).w,d1
	beq.w	.crn
	cmpi.w	#4,gspotwins(a0)
	beq.w	.crn
	cmpi.w	#4,gspobwins(a0)
	beq.w	.crn
	addq.w	#1,gspotwins(a0)
	move.l	#$C8,d0	;200
	jsr	(randomd0).l
	andi.w	#1,d0
	beq.s	.cr0
	subq.w	#1,gspotwins(a0)
	addq.w	#1,gspobwins(a0)
	bra.s	.cr0
.crn
	suba.w	#gssize,a0
	dbf	d1,.cr0
	movea.w	#(tpassbits-M68K_RAM),a3	;bits before advancing to next round (93 tpassbits)
	bsr.w	WritePassBits
	bset	#sf3alttree,(sflags3).w	;93 sf3alttree
.nextround
	clr.w	(bosgames).w	;advance to next round
	bsr.w	GetShifter
	movea.w	#(gsstruct-M68K_RAM),a0
	moveq	#gssize,d3
	mulu.w	d1,d3
	adda.w	d3,a0
	clr.w	d3
.loop2
	cmpi.w	#4,gspotwins(a0)
	beq.w	.2
	bset	d1,d3
.2
	clr.w	gspotwins(a0)
	clr.w	gspobwins(a0)
	suba.w	#gssize,a0
	dbf	d1,.loop2
	moveq	#1,d1
	asl.w	d2,d1
	subq.w	#1,d1
	and.w	d1,(WinBits).w	;clear this round's winbits (93 WinBits)
	asl.w	d2,d3
	or.w	d3,(WinBits).w
	addq.w	#1,(gamelevel).w
	rts
.notbos
	clr.w	d3	;solve for no best of 7 playoffs (much simpler)
.loop3
	move.w	gss1(a0),d0
	cmp.w	gss2(a0),d0
	bhi.w	.3
	bset	d1,d3
.3
	btst	#0,gsflags(a0)
	beq.w	.nb2
	bchg	d1,d3
.nb2
	suba.w	#gssize,a0
	dbf	d1,.loop3
	moveq	#1,d1
	asl.w	d2,d1
	subq.w	#1,d1
	and.w	d1,(WinBits).w
	asl.w	d2,d3
	or.w	d3,(WinBits).w
	addq.w	#1,(gamelevel).w
	rts
DisplayPeriodOver	;93 name. End of game Stars of the Game box. Called from UpdatePA (penalty94_1) while RefPen is the game over
	;penalty. Waits for RefCnt <= $40 and runs once (gmode bit 7); 94 then sets disflags bit 3 and waits a vblank. Frames the box, draws a bitmap
	;from Rinktilelist (93 IceRinkMap), then the three best star scores (FindMaxAttributeTEam): team abbreviation and getname. Song $F when the
	;home team won
	cmpi.w	#$40,(RefCnt).w
	bgt.w	rtss2	;ref animation not far enough yet
	bset	#7,(gmode).w
	bne.w	rtss2	;already shown
	movem.l	d0/a1,-(sp)
	bset	#3,(disflags).w
	move.w	(vcount).w,d0
.loop2
	cmp.w	(vcount).w,d0
	beq.s	.loop2
	movem.l	(sp)+,d0/a1
	movem.l	d0-d5/a0-a4,-(sp)
	bsr.w	printz
	String	-(TXPRI+TXMAP1),2,$E	;IDA: ori.b (and dropped a word)
	moveq	#$1C,d0	;framer size
	moveq	#9,d1
	bsr.w	Framer
	bsr.w	printz
	String	-(TXPRI+TXMAP1),9,$10,'Stars of the Game',-(TXPRI+TXMAP1),3,$F	;IDA: code
	movea.l	#Rinktilelist,a1	;IDA hid this in the string. map at offset 4
	movea.w	#$30A,a2	;a zero long (93 #$310)
	adda.l	4(a1),a1
	moveq	#$D,d0
	moveq	#$5B,d1
	moveq	#6,d2
	moveq	#4,d3
.0
	move.w	(rinkvrcset).w,d4
	clr.w	d5
	bsr.w	dobitmap
	bsr.w	CalculateTeamAttributes
	move.w	#$12,(printy).w
	moveq	#2,d2	;3 stars
.loop
	bsr.w	FindMaxAttributeTEam	;a2 = team, d0 = player
	move.w	#$1A,(printx).w
	addq.w	#1,(printy).w
	movea.l	tmdata(a2),a1
	adda.w	4(a1),a1
	adda.w	(a1),a1
	bsr.w	print
	bsr.w	getname	;a1 = number and name of player d0
	move.w	#3,(printx).w
	bsr.w	print
	dbf	d2,.loop
	move.w	(HmGoals).w,d0
.1
	sub.w	(AwGoals).w,d0
	ble.w	.nosong
	move.w	#SFXhomewin,-(sp)	;song $F: home team won
	jsr	(song).l
.nosong
	movem.l	(sp)+,d0-d5/a0-a4
	rts
FindMaxAttributeTEam	;93 name. Take the highest of the 52 star scores at ThreeStars (93 DispAttribCtr; 26 per team, home first)
	;and clear it. Returns d0 = player slot, a2 = its team struct. Called from DisplayPeriodOver
	movem.l	d1-d2/a1/a4,-(sp)
	movea.w	#(ThreeStars-M68K_RAM),a4
	clr.l	d0
	moveq	#$33,d2
.find
	cmp.l	(a4)+,d0
	bge.w	.next	;not higher
	lea	-4(a4),a1
	move.l	(a1),d0
.next
	dbf	d2,.find
	clr.l	(a1)
	move.w	a1,d0
	subi.w	#(ThreeStars-M68K_RAM),d0
	lsr.w	#2,d0	;entry number
	movea.w	#(HmShots-M68K_RAM),a2
	cmp.w	#$1A,d0
	blt.w	.home
	subi.w	#$1A,d0
	adda.w	#tmsize,a2	;26-51: away team (tmsize)
.home
	movem.l	(sp)+,d1-d2/a1/a4
	rts
CalculateTeamAttributes	;93 name. Star score for every roster slot of both teams to ThreeStars (26 longs per team, home first). d5 =
	;GetPeriodTime + d2, the goalie ice time needed. If gsp is 3 and the score is not tied, the scorer of the last goal gets $7FFFFFFF. Called
	;from DisplayPeriodOver
	movea.w	#(ThreeStars-M68K_RAM),a4
	jsr	(GetPeriodTime).w	;IDA: ClockLength
	move.w	d0,d5
	add.w	d2,d5
	movea.w	#(HmShots-M68K_RAM),a2
	lea	tmsize(a2),a3
	bsr.w	CalculateTeamAttributeValues	;home
	movea.w	a3,a2
	lea	-tmsize(a2),a3
	bsr.w	CalculateTeamAttributeValues	;away (d3 = away - home score)
	cmpi.w	#3,(gsp).w
	bne.w	.x
	tst.w	d3
	beq.w	.x	;tied
	movea.w	#(ChkCnt-M68K_RAM),a0	;+ ScoreSumbytes = last goal entry
	adda.w	(ScoreSumbytes).w,a0
	clr.w	d0
	btst	#7,2(a0)
	beq.w	.slot
	addi.w	#$1A,d0	;away goal: second 26 entries
.slot
	add.b	3(a0),d0
	asl.w	#2,d0
	movea.w	#(ThreeStars-M68K_RAM),a0
	move.l	#$7FFFFFFF,0(a0,d0.w)	;game winner is the first star
.x
	rts
CalculateTeamAttributeValues	;93 name. Star scores of team a2 (a3 = other team) to (a4)+, one long per roster slot (26). Each
	;starts at the goal difference. Skaters: goals*11000 + assists*10100 + shots*10, or in a tied game shots*1000 + frames on ice. Goalies on ice
	;at least d5 with shots against: +32000 if goals against*100/shots <= 4, +75000 more for a shutout. Called from CalculateTeamAttributes
	movea.w	a2,a1
	move.w	tmscore(a2),d3
	sub.w	tmscore(a3),d3	;goal difference (HmGoals / AwGoals)
	ext.l	d3
	moveq	#$19,d4	;26 slots
	jsr	(ReadAttributeNibble).l	;d0 = goalies on the team (93 ReadAttributeNibble)
	neg.w	d0
	add.w	d4,d0
.loop
	move.l	d3,(a4)
	cmp.w	d0,d4
	bhi.w	.goalie	;goalie slot
	clr.w	d1
	move.b	$B4(a2),d1
	mulu.w	#$2AF8,d1	;goals * 11000
	add.l	d1,(a4)
	clr.w	d1
	move.b	$CE(a2),d1
	mulu.w	#$2774,d1	;assists * 10100
	add.l	d1,(a4)
	clr.w	d1
	move.b	$E8(a2),d1
	mulu.w	#$A,d1
	tst.w	d3
	bne.w	.add	;not tied: shots * 10
	mulu.w	#$64,d1	;tied: shots * 1000
	add.l	d1,(a4)
	clr.l	d1
	add.w	$136(a1),d1	;+ frames on ice
.add
	add.l	d1,(a4)
	bra.w	.next
.goalie
	cmp.w	$136(a1),d5
	bhi.w	.next	;not on ice long enough
	clr.w	d1
	move.b	$B4(a2),d1
	mulu.w	#$64,d1
	clr.w	d2
	move.b	$E8(a2),d2
	beq.w	.next
	divu.w	d2,d1
	cmp.w	#4,d1
	bhi.w	.next
	addi.l	#$7D00,(a4)	;32000
	tst.w	d1
	bne.w	.next
	addi.l	#$124F8,(a4)	;75000 for a shutout
.next
	addq.w	#2,a1
	addq.w	#1,a2
	addq.w	#4,a4
	dbf	d4,.loop
	rts
ShowInjuryBox	;93 name. Injury box: 'Injury to:' player TempPlOffset (GetPlayerNameWithAttrib), 'Out for period', or 'Out for game'
	;when sflags7 bit 5 is set (94), and 'the game' over 'period' when puck_pflags2 bit 0 (93 pf2fight) is set. Jumped to from CheckInjury
	;(hockey94_01), so global
	movem.l	d0-d2/a0-a4,-(sp)
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$B,3	;IDA: ori.b / btst
	moveq	#$12,d0	;framer size
	moveq	#5,d1
	bsr.w	Framer
	btst	#5,(sflags7).w
	bne.w	.0
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$C,4,'Injury to:',-(TXPRI+TXMAP1),$C,6,'Out for period',-(TXPRI+TXMAP1),$C,5	;IDA: code
	bra.w	.1
.0
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$C,4,'Injury to:',-(TXPRI+TXMAP1),$C,6,'Out for game',-(TXPRI+TXMAP1),$C,5	;IDA: code
.1
	bsr.w	GetPlayerNameWithAttrib
	bsr.w	print
	btst	#pf2fight,(puck_pflags2).w
	beq.w	.ex
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$14,6,'the game'	;IDA: ori.b / addi.w / bsr.s
.ex
	movem.l	(sp)+,d0-d2/a0-a4	;IDA: bcs.w / move.b (IDA hid this in the string)
	rts
PenaltyShotBox	;94 only. Penalty shot box, called from chkprogress (penalty94_1). Sets gmode2 bit 7; in Shootout (bit 0) jumps to PlayoffRoundScreen
	;instead. Otherwise: printbig 'PENALTY SHOT!', the shooter (BA_Sktr_SCnum, BA_Team), the penalty name (PenaltyList, pspenalty) and ' by' the
	;player BA_Checker_Offset of the other team
	bset	#7,(gmode2).w
	btst	#0,(gmode2).w
.0
	beq.w	.1
	jmp	PlayoffRoundScreen
.1
	movem.l	d0-d2/a0-a4,-(sp)
	move.w	#$FFFF,d0
	jsr	(prefmes).l	;d0 = -1
	bsr.w	printz
	String	-(TXPRI+TXMAP1),3,2	;IDA: ori.b / andi.b
	moveq	#$1B,d0	;IDA hid this in the string
.2
	moveq	#8,d1
	bsr.w	Framer
.3
	lea	PenShotBigTxt(pc),a1
.4
	bsr.w	printbig
	move.w	(BA_Sktr_SCnum).w,d0
	asl.w	#7,d0	;sprite structs are $80 bytes
	movea.l	#SortCords,a2
	adda.w	d0,a2
	clr.w	d0
	move.b	$66(a2),d0	;roster slot
	movea.l	#HmShots,a2
	tst.w	(BA_Team).w
	beq.w	.6
.5
	movea.l	#AwShots,a2
.6
	bsr.w	FormatPlayerNameWithAttrib
	bsr.w	print
	bsr.w	printz
	String	-(TXPRI+TXMAP1),4,7	;IDA: ori.b / btst
	movem.l	a1/a3,-(sp)
	move.w	(pspenalty).w,d0
	movea.l	#PenaltyList,a1
	adda.w	0(a1,d0.w),a1
	lea	2(a1),a1
	bsr.w	print
	movem.l	(sp)+,a1/a3
	bsr.w	printz
	String	' by',-(TXPRI+TXMAP1),4,8	;IDA: ori.b / subi.b / add.b
	move.w	(BA_Checker_Offset).w,d0	;IDA hid this in the string
	movea.l	#AwShots,a2
	tst.w	(BA_Team).w
	beq.w	.7
	movea.l	#HmShots,a2
.7
	jsr	(FormatPlayerNameWithAttrib).l
	jsr	(print).l
	movem.l	(sp)+,d0-d2/a0-a4
	rts
PenShotBigTxt	String	$BF,4,3,'PENALTY SHOT!',$BF,4,5	;printbig String for PenaltyShotBox
DisplayPlayerAttributeMenu	;93 name. Goal box. Closes both line change boxes, then printbig 'GOAL!' ('PP GOAL!' when DelayedPen
	;bit 0 is set, cleared here), or 'HAT TRICK!' on the scorer's third goal when the scorer's slot is at least scorergoalies (homegoalies home /
	;awaygoalies visitors), then the scorer and up to two assists of the last goal entry (FormatPlayerName). 94 calls CountGoalies, StartArenaAnim (home
	;hat trick), PrintPlayerGoals and PrintPlayerAssists (not matched yet); BA_PS_flags bit 2 sets sflags2 bit 2. Called from SetPA (penalty94_1)
	movem.l	d0-d2/a0-a4,-(sp)
	btst	#2,(BA_PS_flags).w
	beq.w	.0
	bset	#2,(sflags2).w
.0
	movea.w	#(HmShots-M68K_RAM),a2
	jsr	(lcfound2).l	;close lc box
	adda.w	#tmsize,a2
	jsr	(lcfound2).l
	movea.w	#(ChkCnt-M68K_RAM),a4	;+ ScoreSumbytes = last goal entry
	adda.w	(ScoreSumbytes).w,a4
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$B,2	;IDA: ori.b / andi.b
	moveq	#$13,d0	;IDA hid this in the string
	move.w	#5,d1	;5 rows: no assist
	tst.b	4(a4)
	bmi.w	.frame
	addq.w	#2,d1	;7: one assist
	tst.b	5(a4)
	bmi.w	.frame
	addq.w	#1,d1	;8: two assists
.frame
	bsr.w	Framer
	jsr	(CountGoalies).l
	movea.w	#(HmShots-M68K_RAM),a2
	move.w	(homegoalies).w,(scorergoalies).w
	btst	#7,2(a4)
	beq.w	.1	;home team scored
	adda.w	#tmsize,a2
	move.w	(awaygoalies).w,(scorergoalies).w
.1
	lea	GoalBigTxt(pc),a1
	bclr	#0,(DelayedPen).w
	beq.w	.2
	lea	PPGoalBigTxt(pc),a1
.2
	clr.w	d0
	move.b	3(a4),d0	;scorer
	addi.w	#$B4,d0
	cmpi.b	#3,0(a2,d0.w)	;goals
	bne.w	.4
	movem.w	d1,-(sp)
	clr.w	d1
	move.b	3(a4),d1
	cmp.w	(scorergoalies).w,d1
	movem.w	(sp)+,d1
	blt.w	.4
	adda.w	(a1),a1	;HAT TRICK!
	move.w	d0,-(sp)
	move.w	Xvel(a2),d0
	cmp.w	(HomeTeam).w,d0
	bne.w	.3
	move.w	#0,d0
	jsr	(StartArenaAnim).l
.3
	move.w	(sp)+,d0
.4
	bsr.w	printbig
	clr.w	d0
	move.b	3(a4),d0
	move.w	d0,-(sp)
	move.w	#$C,(printx).w
	bsr.w	FormatPlayerName
	bsr.w	print
	move.w	(sp)+,d0
	movem.w	d1,-(sp)
	clr.w	d1
	move.b	3(a4),d1
	cmp.w	(scorergoalies).w,d1
	movem.w	(sp)+,d1
	blt.w	.5
	jsr	(PrintPlayerGoals).l
.5
	clr.w	d0
	move.b	4(a4),d0	;first assist
	bmi.w	.6
	bclr	#5,(sflags4).w
	bne.w	.6	;sflags4 bit 5 set: no assists
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$E,6,'Assist by:',-(TXPRI+TXMAP1),$C,7	;IDA: code
	move.w	d0,-(sp)	;IDA hid this in the string
	bsr.w	FormatPlayerName
	bsr.w	print
	move.w	(sp)+,d0
	jsr	(PrintPlayerAssists).l
	clr.w	d0
	move.b	5(a4),d0	;second assist
	bmi.w	.6
	bsr.w	printz
	String	-(TXPRI+TXMAP1),$C,8	;IDA: ori.b / #0
	move.w	d0,-(sp)	;IDA hid this in the string
	bsr.w	FormatPlayerName
	bsr.w	print
	move.w	(sp)+,d0
	jsr	(PrintPlayerAssists).l
.6
	bclr	#5,(sflags4).w
	movem.l	(sp)+,d0-d2/a0-a4
	rts
GoalBigTxt	String	$BF,$F,3,'GOAL!',$BF,$C,5	;printbig Strings for DisplayPlayerAttributeMenu (93 attrText): GOAL!, then HAT TRICK!
	String	$BF,$C,3,'HAT TRICK!',$BF,$C,5
PPGoalBigTxt	String	$BF,$D,3,'PP GOAL!',$BF,$C,5	;The same after DelayedPen bit 0: PP GOAL!, then HAT TRICK!
	String	$BF,$C,3,'HAT TRICK!',$BF,$C,5
box	;IDA name (93 box). Fill a $13 x 8 rectangle at printz position $FF,$B,2 with char $7FF (eraser). Called from SetLCmode2 (logic94_1)
	bsr.w	printz
	String	-TXMAP1,$B,2	;IDA dc.b
	moveq	#$13,d0	;IDA hid this in the string
	moveq	#8,d1
	move.l	#$7FF,d2
	bra.w	eraser
GetTempPlayerName	;93 GetPlayerName, but that is the same symbol as getplayername (SNASM symbols are case-insensitive).
	;a1 = mesarea "NN First Last" (getname) for player TempPlOffset (bit 15 set: away team). Called from UpdatePA (penalty94_1)
	movem.l	d0/a2,-(sp)
	movea.w	#(HmShots-M68K_RAM),a2
	move.w	(TempPlOffset).w,d0
	bpl.w	.0
	andi.w	#$FF,d0
	adda.w	#$364,a2	;away team (tmsize)
.0
	bsr.w	getname
	movem.l	(sp)+,d0/a2
	rts
getname	;IDA name (93 getname). gets player number and name, appends to string: a1 = mesarea "NN First Last" for player d0 (roster offset) of team struct a2. The number is the bcd byte after the name
	movem.l	d0-d3/a0/a2-a3,-(sp)	;push to stack
	bsr.w	GetPlayerNamePointer	;get to start of player name
	move.l	a0,-(sp)	;push a0 (address to start of player name) to stack
	movea.w	#(mesarea-M68K_RAM),a3	;move mesarea to a3 address
	move.w	#4,(a3)	;move 4 into a3 address location
	lea	2(a3),a1	;move long address at a3+2 into a1
	adda.w	(a0),a0	;add data at a0 (player name length) to a0
	move.b	(a0),d0	;move a0 data (jersey #) to d0
	bsr.w	ConverByteToDigits	;convert JNo to ascii
	bsr.w	appendz	;add space after JNo
	String	' '
	movea.l	(sp)+,a1	;pop from stack into a1 (address to start of player name)
	bsr.w	appstring	;add player name to string a3
	movea.w	#(mesarea-M68K_RAM),a1	;move mesarea address into a1
	movem.l	(sp)+,d0-d3/a0/a2-a3	;pop from stack
	rts
GetPlayerNameWithAttrib	;93 name. a1 = mesarea "NN F. Last" (FormatPlayerNameWithAttrib) for player TempPlOffset (bit 15 set: away team). Called from ShowInjuryBox
	movem.l	d0/a2,-(sp)
	movea.w	#(HmShots-M68K_RAM),a2
	move.w	(TempPlOffset).w,d0
	bpl.w	.get
	andi.w	#$FF,d0
	adda.w	#tmsize,a2
.get
	bsr.w	FormatPlayerNameWithAttrib
	movem.l	(sp)+,d0/a2
	rts
FormatPlayerNameWithAttrib	;93 name. a1 = mesarea string "NN F. Last" for player d0 of team a2, built in TextBuffer (93 name). Called from PenaltyShotBox and others
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	adda.w	(a0),a0
	move.b	(a0),d0
	bsr.w	ConverByteToDigits
	move.b	#$20,(a1)+
	movea.l	(sp)+,a0
	move.w	(a0)+,d0
	lea	-2(a0,d0.w),a2
	move.b	(a0)+,(a1)+	;first initial
	move.w	#$2E20,(a1)+	;'. '
.skip
	cmpi.b	#$20,(a0)+
	bne.s	.skip
.copy
	move.b	(a0)+,(a1)+
	cmpa.l	a0,a2
	bne.s	.copy
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts
FormatPlayerName	;93 name. a1 = mesarea string "NN Last" for player d0 of team a2, built in TextBuffer. Called from DisplayPlayerAttributeMenu and others
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	move.l	a0,-(sp)
	movea.w	#(TextBuffer-M68K_RAM),a1
	adda.w	(a0),a0
	move.b	(a0),d0
	bsr.w	ConverByteToDigits
	move.b	#$20,(a1)+
	movea.l	(sp)+,a0
	move.w	(a0)+,d0
	lea	-2(a0,d0.w),a2
.skip
	cmpi.b	#$20,(a0)+
	bne.s	.skip
.copy
	move.b	(a0)+,(a1)+
	cmpa.l	a0,a2
	bne.s	.copy
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts
FormatPlayerNameLast	;94 only. FormatPlayerNameShort without the leading space ("Last", space padded). Branches into FormatLastName
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	movea.w	#(TextBuffer-M68K_RAM),a1
	bra.w	FormatLastName
FormatPlayerNameShort	;93 name. a1 = mesarea string " Last" for player d0 of team a2, space padded to 12 characters; a 0 byte also ends the name
	movem.l	d0-d3/a0/a2,-(sp)
	bsr.w	GetPlayerNamePointer
	movea.w	#(TextBuffer-M68K_RAM),a1
	move.b	#$20,(a1)+
FormatLastName	;Skip the first name, copy the last name, pad; branched to from FormatPlayerNameLast, so global
	move.w	(a0)+,d0
	lea	-2(a0,d0.w),a2
.loop
	cmpi.b	#$20,(a0)+
	bne.s	.loop
.loop2
	move.b	(a0)+,(a1)+
	cmpa.l	a0,a2
	beq.w	.0
	tst.b	(a0)
	bne.s	.loop2
	bra.w	.0
.loop3
	move.b	#$20,(a1)+
.0
	cmpa.w	#$BFB2,a1	;TextBuffer+12
	blt.s	.loop3
	bsr.w	FinalizeTextBuffer
	movem.l	(sp)+,d0-d3/a0/a2
	rts
FinalizeTextBuffer	;93 name. mesarea length word = a1 - mesarea, with a 0 pad byte when odd. Returns a1 = mesarea. Called from the FormatPlayerName routines
	move.w	a1,d0
	subi.w	#(mesarea-M68K_RAM),d0
	btst	#0,d0
	beq.w	.even
	clr.b	(a1)+
	addq.w	#1,d0
.even
	movea.w	#(mesarea-M68K_RAM),a1
	move.w	d0,(a1)
	rts
GetPlayerNamePointer	;93 name (IDA: getplayername). loops through team roster to get to d0 player: a0 = name string of player d0 (roster offset) of
	;team struct a2. Each record is a length word String and 8 more bytes
	movea.l	$1E(a2),a0	;offset $1E - ROM address of team data?
	adda.w	(a0),a0	;add offset (player data start) to a0 address
	bra.w	.loop
.skip
	adda.w	(a0),a0	;add player name length to a0
	addq.w	#8,a0	;add 8 to a0 (player attributes field)
.loop
	dbf	d0,.skip	;loop until at player offset
	rts
ConverByteToDigits	;93 name (IDA: d0toascii). converts decimal number in d0 to ascii: two ascii digits of bcd byte d0 to (a1)+, a leading 0 becomes a space ($F0 + '0')
	move.w	d0,-(sp)	;push to stack
	lsr.b	#4,d0	;divide by 16 (get upper digit in d0)
	bne.w	.n0	;branch if not 0
	move.b	#$F0,d0	;move $F0 into d0
.n0
	addi.b	#$30,d0	;'0'   ; add $30 (48 dec) to d0
	move.b	d0,(a1)+	;move d0 into a1 and increment
	move.w	(sp)+,d0	;pop d0 from stack
	andi.w	#$F,d0	;pass bottom 4 bytes of d0 (lower digit in d0)
	addi.b	#$30,d0	;'0'   ; add $30 (48 dec) to d0
	move.b	d0,(a1)+	;move d0 into a1 and increment
	rts
AddError	;IDA: AdrErr (92 / 93 name, main94 vectors). Address error vector; 94 has no BusError, the bus error vector also points here
	move	#$2700,sr
	bsr.w	printbigz
	String	-(TXPRI+TXMAP3),0,0,'Address Error'	;IDA dc.b
	move.l	$A(sp),d0	;pc. IDA dc.b
	move.l	2(sp),d1	;access address
	bra.w	crash
Illinst	;IDA: InvOpCode (92 / 93 name, main94 vectors). Illegal instruction vector
	move	#$2700,sr
	bsr.w	printbigz
	String	-(TXPRI+TXMAP3),0,0,'Illegal Instruction'	;IDA dc.b
	move.l	2(sp),d0	;IDA dc.b
	move.l	d0,d1
	bra.w	crash
ZeroDiv	;IDA: DivBy0 (92 / 93 name, main94 vectors). Divide by zero vector, falls into crash
	move	#$2700,sr
	bsr.w	printbigz
	String	-(TXPRI+TXMAP3),0,0,'Division by zero'	;IDA dc.b
	move.l	2(sp),d0	;IDA dc.b
	move.l	d0,d1
crash	;92 / 93 name. printbig d1 then d0 as hex, set the vdp up, copy 8 longs from the Rinktilelist palette + $20 (93 IceRinkMap)
	;to cram $20 and hang. Branched to from AddError and Illinst, falls in from ZeroDiv
	movea.w	#(mesarea-M68K_RAM),a0
	move.w	#$18,(a0)+	;2+3+8+3+8 (93 form)
	move.b	#$BD,(a0)+	;92 -$43
	move.b	#0,(a0)+
	move.b	#2,(a0)+
	move.l	d1,-(sp)
	bsr.w	.ri	;d1
	move.b	#$BD,(a0)+
	move.b	#0,(a0)+
	move.b	#4,(a0)+
	move.l	(sp)+,d0
	bsr.w	.ri	;d0
	movea.w	#(mesarea-M68K_RAM),a1
	bsr.w	printbig
	movea.l	#VDP_DATA,a0
	move.w	#VDPR_WINX,Vctrl-Vdata(a0)
	move.w	#VDPR_WINY+$06,Vctrl-Vdata(a0)
	move.w	#VDPR_AUTOINC+$02,Vctrl-Vdata(a0)
	move.l	#CRAM_W+($20<<16),Vctrl-Vdata(a0)	;cram write $20 (92 $C0060000)
	movea.l	#Rinktilelist,a1
	adda.l	(a1),a1
	adda.w	#$20,a1
	moveq	#7,d0
.pal
	move.l	(a1)+,(a0)
	dbf	d0,.pal
.end
	bra.w	.end
.ri	;93 local .ri. d0 as 8 hex digits to (a0)+
	moveq	#7,d2
.top
	rol.l	#4,d0
	move.w	d0,d1
	andi.w	#$F,d1
	addi.w	#$30,d1
	cmp.w	#$39,d1
	ble.w	.t1
	addq.w	#7,d1	;'A'-'0'-10
.t1
	move.b	d1,(a0)+
	dbf	d2,.top
	rts
;	NHL 94 (retail) segment $18CFC-$1A04F
;	Data only, as 93 hockey93_11: the 92 crowd frame table (updatecrowdf .cd0), the player logic assignment table asstab, PenaltyList,
;	the 94 penalty shot table (PenShotPenalties), bfasciicon, linelist (IDA FaceOffsprites), PlayerPositionText, PerLabels, sizetab, sublist,
;	priolist, the playoff tree layout (PlayoffTreeSetup), the attribute column lists, and the menu item lists for the pause,
;	intermission and line editor exit menus. sram94 (InitSaveRAM) starts at $1A050.
;	Transcribed from lst/nhl94.bin.lst lines 56543-61321 (IDA dc.b / dc.w / dc.l). Global names are the IDA names, or the 93 name where
;	IDA has an auto name or no label. IDA labels the code reads inside a table stay (PAttribOverall,
;	PAttribOverallMask, GAttribOverall, GAttribOverallMask). Two attribute column longs IDA read as offsets are dc.w pairs.
;	Code addresses in the tables are the routines in the earlier segments (asstab, the menu handlers); handlers in the stats code
;	and the high ROM that no matched segment owns are equated by name in hockey94_11_stub.asm.
;	Menu item lists (as 93): two printsmall control Strings, then per item a String and the handler address (dc.l). Item 0 leaves the menu,
;	its handler is rtss2. String $FF ends.

cd0	;IDA: _cd0. $fftt = frame/time for various levels of crowd excitement. 92 updatecrowdf .cd0, same bytes as 93.
	;Used by updatecrowdf (hockey94_01), indexed by crowd level and crowdstep
	dc.w	$010c,$020c,$030c,$040c,$050c,$0a0c,$090c,$080c
	dc.w	$060c,$070c,$080c,$090c,$0a0c,$050c,$040c,$030c

	dc.w	$0107,$0207,$0307,$0407,$0507,$0b07,$0c07,$0d07
	dc.w	$0607,$0707,$0807,$0907,$0a07,$0b07,$0c07,$0d07

	dc.w	$0e07,$0f07,$1007,$1107,$1207,$0b07,$0c07,$0d07
	dc.w	$1207,$1107,$1007,$0f07,$0e07,$0d07,$0c07,$0b07

	dc.w	$0e03,$0f03,$1003,$1103,$1203,$0b03,$0c03,$0d03
	dc.w	$1203,$1103,$1003,$0f03,$0e03,$0d03,$0c03,$0b03

asstab	;jump table of all the player logic assignments. 92 / 93 asstab; 94 adds 7 entries ($1D-$23). Used by updateplayers
	dc.l	rtss2		;0 (93 rtss)
	dc.l	assdefo		;1 adefo
	dc.l	assdefd		;2 adefd
	dc.l	asswingd		;3 awingd
	dc.l	asswingo		;4 awingo
	dc.l	asscenterd	;5 acenterd
	dc.l	asscentero	;6 acentero
	dc.l	assscore		;7 ascore
	dc.l	assstanley	;8 astanley
	dc.l	asseben		;9 aeben
	dc.l	assepen		;$A aepen
	dc.l	assbench		;$B abench
	dc.l	asspenalty	;$C apenalty
	dc.l	assdopen		;$D adopen
	dc.l	assgoaliecpu	;$E agoalie (93 assgoalie)
	dc.l	assgoalietopuck	;$F
	dc.l	asspuckc		;$10 apuckc
	dc.l	assnearest	;$11 anearest
	dc.l	assshoot		;$12 ashoot
	dc.l	asspassrec	;$13 apassrec
	dc.l	assfight		;$14 afight
	dc.l	assfwatch		;$15
	dc.l	assfaceoff	;$16
	dc.l	assfaceoffp1	;$17
	dc.l	pucknorm		;$18 puck logic
	dc.l	puckshadow	;$19
	dc.l	puckunflip	;$1A (93 pucknothing)
	dc.l	puckfaceoff	;$1B
	dc.l	puckfaceoff2	;$1C
	dc.l	assgoaliectrl	;$1D 94 only
	dc.l	puckshootout	;$1E 94 only
	dc.l	puckpenshot	;$1F 94 only
	dc.l	assgoaliebreakwait	;$20 94 only
	dc.l	chkpuckc		;$21 94 only
	dc.l	assbreakaway	;$22 94 only
	dc.l	assonetimer	;$23 94 only (high ROM)

PenaltyList	;92 Penaltylist, 93 numbers. Penalty number = word offset into this table; 94 adds 8 entries ($2E-$3C: the penalty shot
	;versions of 7 penalties, minutes byte $FF, and a second Face Off). Used by AddPenalty, SetPA2, PenaltyShotBox (hockey94_10), ...
	dc.w	$0000
	dc.w	.eop-PenaltyList	;$2 period over
	dc.w	.eog-PenaltyList	;$4 game over
	dc.w	.ghold-PenaltyList	;$6
	dc.w	.ghold-PenaltyList	;$8
	dc.w	.whistle-PenaltyList	;$A whistle
	dc.w	.ice-PenaltyList	;$C icing
	dc.w	.goal-PenaltyList	;$E goal
	dc.w	.offsides-PenaltyList	;$10 offsides
	dc.w	.rough2-PenaltyList	;$12 roughing, slow down time $A
	dc.w	.p14-PenaltyList	;$14 no text
	dc.w	.charge-PenaltyList	;$16
	dc.w	.slash-PenaltyList	;$18
	dc.w	.rough-PenaltyList	;$1A
	dc.w	.cross-PenaltyList	;$1C
	dc.w	.hook-PenaltyList	;$1E
	dc.w	.trip-PenaltyList	;$20
	dc.w	.int-PenaltyList	;$22
	dc.w	.hold-PenaltyList	;$24
	dc.w	.fight-PenaltyList	;$26
	dc.w	.fight2-PenaltyList	;$28
	dc.w	.inst-PenaltyList	;$2A
	dc.w	.delay-PenaltyList	;$2C delay
	dc.w	.hookps-PenaltyList	;$2E 94: penalty shot
	dc.w	.tripps-PenaltyList	;$30 94: penalty shot
	dc.w	.ghold2-PenaltyList	;$32 94: face off, no slow down
	dc.w	.intps-PenaltyList	;$34 94: penalty shot
	dc.w	.roughps-PenaltyList	;$36 94: penalty shot
	dc.w	.chargeps-PenaltyList	;$38 94: penalty shot
	dc.w	.crossps-PenaltyList	;$3A 94: penalty shot
	dc.w	.slashps-PenaltyList	;$3C 94: penalty shot

;format
;	dc.w	$ttmm	;tt=slow dnw time in half secs,mm=penalty min.
;	String	'penalty text'
;	dc.w	$ffdd,$ffdd,$ffdd,...	;ff = frame,dd=delay (neg for end)

.eop	dc.w	$0100
	String	'Period Over'
	dc.w	-$0510
.eog	dc.w	$0100
	String	'Game Over'
	dc.w	$0510,-$4060
.goal	dc.w	$0100
	dc.w	2			;String with no text
	dc.w	$050a,-$4018
.p14	dc.w	$0100
	dc.w	2			;String with no text
	dc.w	$0510,-$4018
.ice	dc.w	$0100
	String	'Icing'
	dc.w	$0002,$0101,-$0206
.offsides	dc.w	$0100
	String	'Off-side'
	dc.w	$0002,$0301,-$040f
.ghold	dc.w	$0100
	String	'Face Off'
	dc.w	-$050a
.ghold2	dc.w	$0000
	String	'Face Off'
	dc.w	-$050a
.delay	dc.w	$0000
	String	'Penalty'
	dc.w	$0003,$0301,-$040f
.whistle	dc.w	$0000
	dc.w	2			;String with no text
	dc.w	-$050a
.charge	dc.w	$0402
	String	'Charging'
	dc.w	$0004,$0101,$0a01,$0b01,$0a01,$0b01,$0a01,$0b01,$0a01,$0b01,-$0101
.chargeps	dc.w	$04ff
	String	'Charging'
	dc.w	$0004,$0101,$0a01,$0b01,$0a01,$0b01,$0a01,$0b01,$0a01,$0b01,-$0101
.slash	dc.w	$0402
	String	'Slashing'
	dc.w	$0004,$0101,$0201,$0301,$0201,$0301,$0201,$0301,$0201,$0301,-$0101
.slashps	dc.w	$04ff
	String	'Slashing'
	dc.w	$0004,$0101,$0201,$0301,$0201,$0301,$0201,$0301,$0201,$0301,-$0101
.trip	dc.w	$0402
	String	'Tripping'
	dc.w	$0004,$0401,$0501,$0401,$0501,$0401,$0501,$0401,$0501,-$0101
.tripps	dc.w	$04ff
	String	'Tripping'
	dc.w	$0004,$0401,$0501,$0401,$0501,$0401,$0501,$0401,$0501,-$0101
.rough2	dc.w	$0a02
	String	'Roughing'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.rough	dc.w	$0402
	String	'Roughing'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.roughps	dc.w	$04ff
	String	'Roughing'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.hook	dc.w	$0402
	String	'Hooking'
	dc.w	$0004,$0101,$0901,$0801,$0901,$0801,$0901,$0801,$0901,$0801,-$0101
.hookps	dc.w	$04ff
	String	'Hooking'
	dc.w	$0004,$0101,$0901,$0801,$0901,$0801,$0901,$0801,$0901,$0801,-$0101
.cross	dc.w	$0402
	String	'Cross Check'
	dc.w	$0004,$0601,$0f01,$1001,$0f01,$1001,$0f01,$1001,$0f01,$1001,-$0101
.crossps	dc.w	$04ff
	String	'Cross Check'
	dc.w	$0004,$0601,$0f01,$1001,$0f01,$1001,$0f01,$1001,$0f01,$1001,-$0101
.int	dc.w	$0402
	String	'Interference'
	dc.w	$0004,$0101,$0c06,-$0101
.intps	dc.w	$04ff
	String	'Interference'
	dc.w	$0004,$0101,$0c06,-$0101
.hold	dc.w	$0402
	String	'Holding'
	dc.w	$0004,$0101,$0706,-$0101
.fight	dc.w	$2805
	String	'Fighting'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.fight2	dc.w	$2805
	String	'Fighting *'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101
.inst	dc.w	$2802
	String	'Fight Instigator'
	dc.w	$0004,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,$0d01,$0e01,-$0101

PenShotPenalties	;94 only: the penalty shot penalty number for penalty number d0 (word offset), -1 none. Used by PenShotChk
	;(penalty94_1)
	dc.w	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,$38,$3C
	dc.w	$36,$3A,$2E,$30,$34,-1,-1,-1,-1,-1,-1,-1

bfasciicon	;equates to find each char definition for bigfont.map. 92 bfasciicon, 93 values. Indexed by ascii
	;- $20 in PrintBigChar (middle94_2, called from printbig)
;	 -  -!  "  #  $  %  &  -'  (  )  *  +  ,  -  -.  /
	dc.b	-76,-73,00,00,00,00,00,-71,00,00,00,00,00,00,-72,00
;	 0   1  2  3  4  5  6  7  8  9   :  ;  <  =  >  ?
	dc.b	51,-53,54,56,58,60,62,64,66,68,-71,00,00,00,00,74
;	@  A  B  C  D  E  F  G	H  -I  J  K  L  M  N  O
	dc.b	74,00,02,04,06,08,10,12,14,-16,17,19,21,23,25,27
;	P  Q  R  S  T  U  V  W	X  Y  Z
	dc.b	29,31,33,35,37,39,41,43,45,47,49
	dc.b	$FF			;pad (93 $F0)

linelist	String	'Sc1'	;IDA: FaceOffsprites (93 linelist). text list for line choices. Used by SetLCmode2 and puckfaceoff2
	String	'Sc2'
	String	'Chk'
	String	'PP1'
	String	'PP2'
	String	'PK1'
	String	'PK2'

PlayerPositionText	String	'LD'	;93 name. position names for the line slots. Used by DisplayPlayerList
	String	'RD'
	String	'LW'
	String	'C'
	String	'RW'

PerLabels	String	'1',$12	;93 name. text list for periods; 94 ' F' (93 'Final'). Used by PrintScores1, NewTicker3
	String	'2',$13
	String	'3',$14
	String	'OT'
	String	' F'

PenShotPenalties2	String	'1',$12	;94 only: the same with a blank last entry. Used by PrintScores1
	String	'2',$13
	String	'3',$14
	String	'OT'
	String	'  '

sizetab	;sprite size code to tile count. 92 video.asm sizetab, used by addframe2
	dc.b	1,2,3,4,2,4,6,8,3,6,9,12,4,8,12,16

sublist	;substitution lists by position (goalie, LD, RD, LW, C, RW, extra attacker). 92 sublist; 93 / 94 word offsets from
	;sublist. Used by SetPlList
	dc.w	.defl-sublist		;goalie
	dc.w	.defl-sublist
	dc.w	.defr-sublist
	dc.w	.wingl-sublist
	dc.w	.center-sublist
	dc.w	.wingr-sublist
	dc.w	.center-sublist

.defl	dc.b	0+1,8+1,16+1,24+1,32+1,40+1,48+1	;list of players in there lines/each line = 8 bytes
	dc.b	0+2,8+2,16+2,24+2,32+2,40+2,48+2
.defr	dc.b	0+2,8+2,16+2,24+2,32+2,40+2,48+2
	dc.b	0+1,8+1,16+1,24+1,32+1,40+1,48+1
.wingl	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
.wingr	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
.center	dc.b	0+4,8+4,16+4,24+4,32+4,40+4,48+4
	dc.b	0+3,8+3,16+3,24+3,32+3,40+3,48+3
	dc.b	0+5,8+5,16+5,24+5,32+5,40+5,48+5
	dc.b	-1

priolist	dc.b	0,1,2,4,3,5,6	;positions in order of importance. 92 priolist. Used by SetPlList,
	;releasepl and getlinee
	dc.b	$FF			;pad (93 $23)

PlayoffTreeSetup	;93 name. Playoff tree layout by gamelevel. 92 PlayoffScreen .setup, same layout with 94
	;columns. Used by PlayoffScreen (hockey94_06)
	dc.w	.l0-PlayoffTreeSetup
	dc.w	.l1-PlayoffTreeSetup
	dc.w	.l2-PlayoffTreeSetup
	dc.w	.l3-PlayoffTreeSetup
	dc.w	.l4-PlayoffTreeSetup

	;tree graphics for level 0: teams-1 then x,y per team (DrawTeamBlocks), arrows-1 then x,d0 per arrow
	;(DrawPlayoffBracket), scores-1 then x,y per score (FormatScore, negative: none)
.l0	dc.b	16-1
	dc.b	46,2,46,5,46,8,46,11,46,14,46,17,46,20,46,23
	dc.b	71,2,71,5,71,8,71,11,71,14,71,17,71,20,71,23
	dc.b	1,57,0,69,10
	dc.b	7,50,4,50,10,50,16,50,22,75,4,75,10,75,16,75,22

	;tree graphics for level 1
.l1	dc.b	16+8-1
	dc.b	32,2,32,5,32,8,32,11,32,14,32,17,32,20,32,23
	dc.b	85,2,85,5,85,8,85,11,85,14,85,17,85,20,85,23
	dc.b	46,4,46,10,46,15,46,21
	dc.b	71,4,71,10,71,15,71,21
	dc.b	3,43,0,57,2,69,8,83,10
	dc.b	3,50,8,50,18,75,8,75,18

	;tree graphics for level 2
.l2	dc.b	16+8+4-1
	dc.b	18,2,18,5,18,8,18,11,18,14,18,17,18,20,18,23
	dc.b	99,2,99,5,99,8,99,11,99,14,99,17,99,20,99,23
	dc.b	32,4,32,10,32,15,32,21
	dc.b	85,4,85,10,85,15,85,21
	dc.b	46,7,46,18
	dc.b	71,7,71,18
	dc.b	5,29,0,43,2,57,4,69,6,83,8,97,10
	dc.b	1,50,13,75,13

	;tree graphics for level 3
.l3	dc.b	16+8+4+2-1
	dc.b	4,2,4,5,4,8,4,11,4,14,4,17,4,20,4,23
	dc.b	113,2,113,5,113,8,113,11,113,14,113,17,113,20,113,23
	dc.b	18,4,18,10,18,15,18,21
	dc.b	99,4,99,10,99,15,99,21
	dc.b	32,7,32,18
	dc.b	85,7,85,18
	dc.b	46,12
	dc.b	71,12
	dc.b	5,15,0,29,2,43,4,83,6,97,8,111,10
	dc.b	0,63,23

	;tree graphics for level 4
.l4	dc.b	16+8+4+2+1-1
	dc.b	4,2,4,5,4,8,4,11,4,14,4,17,4,20,4,23
	dc.b	113,2,113,5,113,8,113,11,113,14,113,17,113,20,113,23
	dc.b	18,4,18,10,18,15,18,21
	dc.b	99,4,99,10,99,15,99,21
	dc.b	32,7,32,18
	dc.b	85,7,85,18
	dc.b	46,12
	dc.b	71,12
	dc.b	58,23
	dc.b	5,15,0,29,2,43,4,83,6,97,8,111,10
	dc.b	-1			;no scores
	dc.b	$FF			;pad (93 $47)

PAttribColumns	;IDA name (93 PAttribColumns). Skater attribute columns for PrintAttribHeader / the player list. String header,
	;then a long for getNameandAttrib: high word = mask of rating nibbles to average, low word = attribjmp offset (0 status, 2 energy,
	;4 handed, 6 weight, 8 fighting, $A rating). A negative word ends the list. 94 has no Fighting column. PAttribOverall / PAttribOverallMask (the
	;Overall entry) are read by PrintShooterList, PrintOverallRating and hockey94_07
	String	'     Status    ]'
	dc.w	$0000,$0		;status
PAttribOverall	String	'[   Overall    ]'
PAttribOverallMask	dc.w	$1fba,$a
	String	'[   Energy     ]'
	dc.w	$0000,$2		;energy
	String	'[   Agility    ]'
	dc.w	$1000,$a
	String	'[    Speed     ]'
	dc.w	$0800,$a
	String	'[   Handed     ]'
	dc.w	$0040,$4		;handed
	String	'[Off. Awareness]'
	dc.w	$0400,$a
	String	'[Def. Awareness]'
	dc.w	$0200,$a
	String	'[  Shot Power  ]'
	dc.w	$0100,$a
	String	'[Shot  Accuracy]'
	dc.w	$0010,$a
	String	'[Pass  Accuracy]'
	dc.w	$0002,$a
	String	'[Stick Handling]'
	dc.w	$0020,$a
	String	'[    Weight    ]'
	dc.w	$2000,$6		;weight
	String	'[  Endurance   ]'
	dc.w	$0008,$a
	String	'[Aggressiveness]'
	dc.w	$0001,$a
	String	'[   Checking    '
	dc.w	$0080,$a
	dc.w	-1

GAttribColumns	;IDA name (93 GAttribColumns). Goalie attribute columns, same format as PAttribColumns. GAttribOverall /
	;GAttribOverallMask (the Overall entry) are read by PrintShooterList, PrintOverallRating and hockey94_07
	String	'     Status    ]'
	dc.w	$0000,$0		;status
GAttribOverall	String	'[   Overall    ]'
GAttribOverallMask	dc.w	$130f,$a
	String	'[   Agility    ]'
	dc.w	$1000,$a
	String	'[    Speed     ]'
	dc.w	$0800,$a
	String	'[  Glove Hand  ]'
	dc.w	$0040,$4		;handed
	String	'[Def. Awareness]'
	dc.w	$0200,$a
	String	'[ Puck Control ]'
	dc.w	$0100,$a
	String	'[ Stick  Right ]'
	dc.w	$0008,$a
	String	'[  Stick Left  ]'
	dc.w	$0004,$a
	String	'[ Glove  Right ]'
	dc.w	$0002,$a
	String	'[  Glove Left  ]'
	dc.w	$0001,$a
	String	'[    Weight     '
	dc.w	$2000,$6		;weight
	dc.w	-1

PauseMenuItems	;94 only: pause menu item list (PauseMode; hockey94_01)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss2
	String	'  Instant Replay  '
	dc.l	ReplayMode
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	'x Manual Goalie   '
	dc.l	ManualGoalieMenu	;94 only
	String	$FF

PauseText	;93 name. Pause menu item list (PauseMode, hockey94_01)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss2
	String	'  Instant Replay  '
	dc.l	ReplayMode
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu	;93 SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor	;93 LineEditor
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen	;93 GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen	;93 PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen	;93 ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen	;93 PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores	;93 ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen	;93 CrowdMeterScreen
	String	'     Timeout      '
	dc.l	TimeoutMenu	;93 TimeoutMenu
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	'   Period Stats   '
	dc.l	PeriodStatsScreen	;94 only
	String	'x Manual Goalie   '
	dc.l	ManualGoalieMenu	;94 only
	String	$FF

PauseText2	;93 name. Pause menu item list without Timeout (PauseMode)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss2
	String	'  Instant Replay  '
	dc.l	ReplayMode
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu	;93 SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor	;93 LineEditor
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen	;93 GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen	;93 PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen	;93 ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen	;93 PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores	;93 ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen	;93 CrowdMeterScreen
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	'   Period Stats   '
	dc.l	PeriodStatsScreen	;94 only
	String	'x Manual Goalie   '
	dc.l	ManualGoalieMenu	;94 only
	String	$FF

ShootoutIntermissionMenu	;94 only: Intermission menu in Shootout (gmode2 bit 0; penalty94_2)
	String	$FE,5
	String	$FE,4
	String	'  Start Shootout  '
	dc.l	rtss2
	String	'  Shootout SetUp  '
	dc.l	ShootoutShooters	;94 only
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	$FF

StartGameText	;93 name. Intermission menu for gsp 0 (penalty94_2 .sslist)
	String	$FE,5
	String	$FE,4
	String	'    Start Game    '
	dc.l	rtss2
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu	;93 SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor	;93 LineEditor
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores	;93 ShowScores
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	$FF

StartGameTextPO	;93 name. Intermission menu for gsp 0 in the playoffs (penalty94_2 .sslist)
	String	$FE,5
	String	$FE,4
	String	'    Start Game    '
	dc.l	rtss2
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu	;93 SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor	;93 LineEditor
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'  Playoff Stats   '
	dc.l	DisplayTeamStats	;93 DisplayTeamStats
	String	'   Other Scores   '
	dc.l	ShowScores	;93 ShowScores
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	$FF

IntermissionText	;93 name. Intermission menu for gsp 1-3 (penalty94_2 .sslist)
	String	$FE,5
	String	$FE,4
	String	'   Resume Game    '
	dc.l	rtss2
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen	;93 GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen	;93 PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen	;93 ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen	;93 PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores	;93 ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen	;93 CrowdMeterScreen
	String	'  Change Goalie   '
	dc.l	SelectGoalieMenu	;93 SelectGoalieMenu
	String	'    Edit Lines    '
	dc.l	LineEditor	;93 LineEditor
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	'   Period Stats   '
	dc.l	PeriodStatsScreen	;94 only
	String	'x Manual Goalie   '
	dc.l	ManualGoalieMenu	;94 only
	String	$FF

ExitGameText	;93 name. Intermission menu for gsp 4 (penalty94_2 .sslist)
	String	$FE,5
	String	$FE,4
	String	'    Exit Game     '
	dc.l	rtss2
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen	;93 GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen	;93 PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen	;93 ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen	;93 PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores	;93 ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen	;93 CrowdMeterScreen
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	'   Period Stats   '
	dc.l	PeriodStatsScreen	;94 only
	String	$FF

ExitGameTextPO	;93 name. Intermission menu for gsp 4 in the playoffs (penalty94_2 .sslist)
	String	$FE,5
	String	$FE,4
	String	'    Exit Game     '
	dc.l	rtss2
	String	'    Game Stats    '
	dc.l	GameStatisticsScreen	;93 GameStatisticsScreen
	String	'   Player Stats   '
	dc.l	PlayerStatsScreen	;93 PlayerStatsScreen
	String	' Scoring Summary  '
	dc.l	ScoringSummaryScreen	;93 ScoringSummaryScreen
	String	' Penalty Summary  '
	dc.l	PenaltySummaryScreen	;93 PenaltySummaryScreen
	String	'   Team Roster    '
	dc.l	TeamRosterScreen	;93 TeamRosterScreen
	String	'   Other Scores   '
	dc.l	ShowScores	;93 ShowScores
	String	'   Crowd Meter    '
	dc.l	CrowdMeterScreen	;93 CrowdMeterScreen
	String	'   Player Cards   '
	dc.l	PlayerCards	;94 only
	String	'  Record Holders  '
	dc.l	RecordHoldersScreen	;94 only
	String	'   Period Stats   '
	dc.l	PeriodStatsScreen	;94 only
	String	$FF

AttributeScreenText	;93 name. Line editor exit menu (the line editor at $882E)
	String	$FE,6,$F9,1
	String	$FE,4,$F9,1
	String	'       Exit       '
	dc.l	rtss2
	String	'Set Original lines'
	dc.l	InitTeamSructure+$10	;the line copy loop of InitTeamSructure (hockey94_06), as 93
	String	'  Save Team Line  '
	dc.l	EncodePlayerAttributes	;93 EncodePlayerAttributes
	String	'  Load Team Line  '
	dc.l	DecodePlayerAttributes	;93 DecodePlayerAttributes
	String	$FF

ExitAttribText	;93 name. Line editor exit menu without Load Team Line ($8844)
	String	$FE,6,$F9,1
	String	$FE,4,$F9,1
	String	'       Exit       '
	dc.l	rtss2
	String	'Set Original lines'
	dc.l	InitTeamSructure+$10	;the line copy loop of InitTeamSructure (hockey94_06), as 93
	String	'  Save Team Line  '
	dc.l	EncodePlayerAttributes	;93 EncodePlayerAttributes
	String	$FF

