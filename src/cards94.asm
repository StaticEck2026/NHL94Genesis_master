;	NHL 94 (retail) segment
;	94 code in the high ROM, between and: wallcollduringcheck, setSlotBit, the team palettes (TeamPalettes)
;	featured player pictures (FeaturedPictures), the save RAM records (team, player, crowd and user records), the Player Cards screens and
;	CalcAttrib, the user record NAME ENTRY screen, Record Holders, the playoff round screen (PlayoffRoundScreen) and the shootout (shooters
;	menu, next shooter, "SHOOTOUT WON BY"). New in 94; 93 has no code here.
;There are no 93 counterparts: the names are kept, and the names and the entries no label for are named for what
;they do.
;Written from the retail bytes: the inline Strings after the print calls and the remap tables ( code), the
;code behind them, and the picture lists as code. The palettes as code (TeamPalettes) are.pal incbins. The
;inside Strings are not labels.

wallcollduringcheck	;(and comments). during a check, a skater a2 (not a goalie) near the wall: test the wall at his position
	;with his size + $17. Called from CCStart
	tst.w	$34(a2)	;check if goalie
	beq.w	.end
	movem.l	d0-d7,-(sp)
	move.w	(a2),d2	;Xpos of checking player
	move.w	Ypos(a2),d3	;Ypos of checking player
	move.w	$4A(a2),(wcradiusx).w	;moves radiusX into FFBD22 (width of graphic)
	addi.w	#$17,(wcradiusx).l	;add $17 to BD22
	move.w	$4C(a2),(wcradiusy).w	;moves radiusY into FFBD24 (height of graphic)
	addi.w	#$17,(wcradiusy).l	;add $17 to BD24
	movem.l	a0-a6,-(sp)
	exg	a2,a3	;swap a2 and a3
	jsr	(checkcornercoll94).l
	exg	a2,a3	;swap a2 and a3
	movem.l	(sp)+,a0-a6
	movem.l	(sp)+,d0-d7
.end
	rts
setSlotBit	;(and comments). sflags6 bit 5 (the slot) = the puck carrier is in the slot in front of the goal. Called from DoGameFrame
	bclr	#5,(sflags6).w	;clears Slot Bit
	tst.w	(puckc).w
	bmi.w	.ex	;exit if no puckc
	movem.l	d0/a0,-(sp)
	movea.l	#SortCords,a0	;start of SCStructs
	move.w	(puckc).w,d0	;move puckc SCnum into d0
	asl.w	#7,d0	;mult by 128 decimal
	adda.w	d0,a0	;move to start of puckc SCstruct
	move.w	$14(a0),d0	;Ypos
	btst	#7,$62(a0)	;pfgoal - which goal shooting at
	bne.w	.checkpos	;jump if top goal
	neg.w	d0	;negative d0
.checkpos
	cmp.w	#$58,d0	;'X'   ; compare to blueline
	blt.w	.restore	;branch if not in off zone
	cmpi.w	#$47,(a0)	;'G' ; compare X position to $47
	bgt.w	.restore	;branch if greater than 47
	cmpi.w	#$FFB9,(a0)	;compare X position to -$47
	blt.w	.restore	;branch if less than -47
	bset	#5,(sflags6).w	;set bit
.restore
	movem.l	(sp)+,d0/a0
.ex
	rts
TeamPalettes	;Matchup and player card palettes: 56 of 16 colors, two per team (28 teams, TeamList order). A is the matchup logo palette (the TeamLogoPalettes
	;entry, except BOS, FLA, HFD, SJ), B the other side (A with colors 1-2 and 3-4 swapped). Used by DrawMatchupBitmaps and the player cards
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalANHA.pal	;ANH matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalANHB.pal	;ANH other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalBOSA.pal	;BOS matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalBOSB.pal	;BOS other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalBUFA.pal	;BUF matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalBUFB.pal	;BUF other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalCGYA.pal	;CGY matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalCGYB.pal	;CGY other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalCHIA.pal	;CHI matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalCHIB.pal	;CHI other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalDALA.pal	;DAL matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalDALB.pal	;DAL other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalDETA.pal	;DET matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalDETB.pal	;DET other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalEDMA.pal	;EDM matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalEDMB.pal	;EDM other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalFLAA.pal	;FLA matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalFLAB.pal	;FLA other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalHFDA.pal	;HFD matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalHFDB.pal	;HFD other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalLAA.pal	;LA matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalLAB.pal	;LA other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalMTLA.pal	;MTL matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalMTLB.pal	;MTL other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNJA.pal	;NJ matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNJB.pal	;NJ other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNYIA.pal	;NYI matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNYIB.pal	;NYI other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNYRA.pal	;NYR matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalNYRB.pal	;NYR other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalOTWA.pal	;OTW matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalOTWB.pal	;OTW other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalPHIA.pal	;PHI matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalPHIB.pal	;PHI other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalPITA.pal	;PIT matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalPITB.pal	;PIT other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalQUEA.pal	;QUE matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalQUEB.pal	;QUE other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalSJA.pal	;SJ matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalSJB.pal	;SJ other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalSTLA.pal	;STL matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalSTLB.pal	;STL other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalTBA.pal	;TB matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalTBB.pal	;TB other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalTORA.pal	;TOR matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalTORB.pal	;TOR other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalVANA.pal	;VAN matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalVANB.pal	;VAN other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalWSHA.pal	;WSH matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalWSHB.pal	;WSH other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalWPGA.pal	;WPG matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalWPGB.pal	;WPG other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalASEA.pal	;ASE matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalASEB.pal	;ASE other side
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalASWA.pal	;ASW matchup logo palette
	incbin	..\Extracted\NHL94\Graphics\Pals\MatchupPalASWB.pal	;ASW other side
FeaturedPictures	;The featured player pictures
	;of each team (TeamList order): a list of picture.l (NoPicSkater1 ... Card<player>) and roster index.w, 0 ends
	dc.l	.ANH,.BOS,.BUF,.CGY
	dc.l	.CHI,.DAL,.DET,.EDM
	dc.l	.FLA,.HFD,.LA,.MTL
	dc.l	.NJ,.NYI,.NYR,.OTW
	dc.l	.PHI,.PIT,.QUE,.SJ
	dc.l	.STL,.TB,.TOR,.VAN
	dc.l	.WSH,.WPG,.ASE,.ASW
.FLA
	dc.l	NoPicGoalie2
	dc.w	0
	dc.l	NoPicSkater2
	dc.w	13
	dc.l	NoPicSkater2
	dc.w	11
	dc.l	NoPicSkater1
	dc.w	7
	dc.l	NoPicSkater1
	dc.w	4
	dc.l	NoPicSkater2
	dc.w	3
	dc.l	0
.ANH
	dc.l	NoPicGoalie2
	dc.w	0
	dc.l	NoPicSkater1
	dc.w	11
	dc.l	NoPicSkater1
	dc.w	13
	dc.l	NoPicSkater1
	dc.w	3
	dc.l	NoPicSkater2
	dc.w	5
	dc.l	NoPicSkater1
	dc.w	7
	dc.l	0
.BOS
	dc.l	CardAndyMoog
	dc.w	0
	dc.l	CardDonSweeney
	dc.w	18
	dc.l	CardRayBourque
	dc.w	17
	dc.l	CardJoeJuneau
	dc.w	6
	dc.l	CardAdamOates
	dc.w	2
	dc.l	CardCamNeely
	dc.w	11
	dc.l	NoPicSkater2
	dc.w	19
	dc.l	0
.BUF
	dc.l	CardGrantFuhr
	dc.w	0
	dc.l	CardDougBodger
	dc.w	17
	dc.l	CardPetrSvoboda
	dc.w	18
	dc.l	CardDaleHawerchuk
	dc.w	4
	dc.l	CardPatLaFontaine
	dc.w	3
	dc.l	CardAlexnderMogilny
	dc.w	12
	dc.l	0
.CGY
	dc.l	CardMikeVernon
	dc.w	0
	dc.l	CardGarySuter
	dc.w	15
	dc.l	CardAlMacInnis
	dc.w	16
	dc.l	CardGaryRoberts
	dc.w	6
	dc.l	CardJoeNieuwendyk
	dc.w	2
	dc.l	CardTheorenFleury
	dc.w	11
	dc.l	0
.CHI
	dc.l	CardEdBelfour
	dc.w	0
	dc.l	CardSteveSmith
	dc.w	18
	dc.l	CardChrisChelios
	dc.w	17
	dc.l	CardMichelGoulet
	dc.w	6
	dc.l	CardJeremyRoenick
	dc.w	2
	dc.l	CardSteveLarmer
	dc.w	11
	dc.l	0
.DAL
	dc.l	CardJonCasey
	dc.w	0
	dc.l	CardMarkTinordi
	dc.w	16
	dc.l	CardTommySjodin
	dc.w	17
	dc.l	CardDaveGagner
	dc.w	3
	dc.l	CardMikeModano
	dc.w	2
	dc.l	CardRussCourtnall
	dc.w	10
	dc.l	0
.DET
	dc.l	CardTimCheveldae
	dc.w	0
	dc.l	CardSteveChiasson
	dc.w	18
	dc.l	CardPaulCoffey
	dc.w	17
	dc.l	CardSergeiFedorov
	dc.w	3
	dc.l	CardSteveYzerman
	dc.w	2
	dc.l	CardDinoCiccarelli
	dc.w	12
	dc.l	0
.EDM
	dc.l	CardBillRanford
	dc.w	0
	dc.l	CardDaveManson
	dc.w	17
	dc.l	CardIgorKravchuk
	dc.w	18
	dc.l	CardShayneCorson
	dc.w	8
	dc.l	CardDougWeight
	dc.w	2
	dc.l	CardPetrKlima
	dc.w	14
	dc.l	0
.HFD
	dc.l	CardSeanBurke
	dc.w	0
	dc.l	CardZarleyZalapski
	dc.w	18
	dc.l	CardEricWeinrich
	dc.w	19
	dc.l	CardGeoffSanderson
	dc.w	8
	dc.l	CardAndrewCassels
	dc.w	3
	dc.l	CardPatVerbeek
	dc.w	13
	dc.l	0
.LA
	dc.l	CardKellyHrudey
	dc.w	0
	dc.l	CardRobBlake
	dc.w	16
	dc.l	CardMartyMcSorley
	dc.w	17
	dc.l	CardLucRobitaille
	dc.w	7
	dc.l	CardWayneGretzky
	dc.w	3
	dc.l	CardTomasSandstrom
	dc.w	12
	dc.l	NoPicSkater2
	dc.w	13
	dc.l	0
.MTL
	dc.l	CardPatrickRoy
	dc.w	0
	dc.l	CardMattSchneider
	dc.w	17
	dc.l	CardEricDesjardins
	dc.w	16
	dc.l	CardVincentDamphousse
	dc.w	6
	dc.l	CardKirkMuller
	dc.w	2
	dc.l	CardBrianBellows
	dc.w	11
	dc.l	0
.NJ
	dc.l	CardChrisTerreri
	dc.w	0
	dc.l	CardVachslavFetisov
	dc.w	18
	dc.l	CardScottStevens
	dc.w	17
	dc.l	CardStephaneRicher
	dc.w	11
	dc.l	CardAlexnderSemak
	dc.w	2
	dc.l	CardClaudeLemieux
	dc.w	12
	dc.l	0
.NYI
	dc.l	CardGlennHealy
	dc.w	0
	dc.l	CardDariusKasparitis
	dc.w	18
	dc.l	CardVladimirMalakhov
	dc.w	17
	dc.l	CardSteveThomas
	dc.w	8
	dc.l	CardPierreTurgeon
	dc.w	2
	dc.l	CardBenoitHogue
	dc.w	3
	dc.l	0
.NYR
	dc.l	CardJohnVanbiesbrk
	dc.w	0
	dc.l	CardJamesPatrick
	dc.w	18
	dc.l	CardBrianLeetch
	dc.w	17
	dc.l	CardEsaTikkanen
	dc.w	6
	dc.l	CardMarkMessier
	dc.w	2
	dc.l	CardMikeGartner
	dc.w	11
	dc.l	0
.OTW
	dc.l	CardPeterSidorkwicz
	dc.w	0
	dc.l	CardBradShaw
	dc.w	19
	dc.l	CardNormMaciver
	dc.w	18
	dc.l	CardSylvainTurgeon
	dc.w	9
	dc.l	CardJamieBaker
	dc.w	2
	dc.l	CardBobKudelski
	dc.w	14
	dc.l	0
.PHI
	dc.l	CardTommySoderstrom
	dc.w	0
	dc.l	CardDimitriYushkevich
	dc.w	18
	dc.l	CardGarryGalley
	dc.w	17
	dc.l	CardRodBrindAmour
	dc.w	4
	dc.l	CardEricLindros
	dc.w	3
	dc.l	CardMarkRecchi
	dc.w	14
	dc.l	0
.PIT
	dc.l	CardTomBarrasso
	dc.w	0
	dc.l	CardLarryMurphy
	dc.w	16
	dc.l	CardUlfSamuelsson
	dc.w	17
	dc.l	CardKevinStevens
	dc.w	6
	dc.l	CardMarioLemieux
	dc.w	2
	dc.l	CardJaromirJagr
	dc.w	10
	dc.l	NoPicSkater2
	dc.w	11
	dc.l	NoPicGoalie1
	dc.w	1
	dc.l	0
.QUE
	dc.l	CardRonHextall
	dc.w	0
	dc.l	CardCurtisLeschyshyn
	dc.w	18
	dc.l	CardSteveDuchesne
	dc.w	17
	dc.l	CardJoeSakic
	dc.w	2
	dc.l	CardMatsSundin
	dc.w	13
	dc.l	CardOwenNolan
	dc.w	14
	dc.l	0
.SJ
	dc.l	CardArtursIrbe
	dc.w	0
	dc.l	CardNeilWilkinson
	dc.w	17
	dc.l	CardDougWilson
	dc.w	16
	dc.l	CardJohanGarpenlov
	dc.w	9
	dc.l	CardKellyKisio
	dc.w	3
	dc.l	CardPatFalloon
	dc.w	13
	dc.l	0
.STL
	dc.l	CardCurtisJoseph
	dc.w	0
	dc.l	CardJeffBrown
	dc.w	16
	dc.l	CardGarthButcher
	dc.w	17
	dc.l	CardBrendanShanahan
	dc.w	11
	dc.l	CardCraigJanney
	dc.w	2
	dc.l	CardBrettHull
	dc.w	12
	dc.l	0
.TB
	dc.l	CardWendellYoung
	dc.w	0
	dc.l	CardRomanHamrlik
	dc.w	19
	dc.l	CardBobBeers
	dc.w	18
	dc.l	CardMikaelAndersson
	dc.w	11
	dc.l	CardBrianBradley
	dc.w	3
	dc.l	CardChrisKontos
	dc.w	4
	dc.l	0
.TOR
	dc.l	CardFelixPotvin
	dc.w	0
	dc.l	CardDaveEllett
	dc.w	18
	dc.l	CardToddGill
	dc.w	17
	dc.l	CardDaveAndreychuk
	dc.w	8
	dc.l	CardDougGilmour
	dc.w	3
	dc.l	CardNikolaiBorshevsky
	dc.w	12
	dc.l	0
.VAN
	dc.l	CardKirkMcLean
	dc.w	0
	dc.l	CardDougLidster
	dc.w	18
	dc.l	CardJyrkiLumme
	dc.w	17
	dc.l	CardGeoffCourtnall
	dc.w	6
	dc.l	CardCliffRonning
	dc.w	2
	dc.l	CardPavelBure
	dc.w	12
	dc.l	0
.WSH
	dc.l	CardDonBeaupre
	dc.w	0
	dc.l	CardAlIafrate
	dc.w	17
	dc.l	CardKevinHatcher
	dc.w	16
	dc.l	CardDimitriKhristich
	dc.w	3
	dc.l	CardMikeRidley
	dc.w	2
	dc.l	CardPeterBondra
	dc.w	11
	dc.l	NoPicSkater1
	dc.w	18
	dc.l	0
.WPG
	dc.l	CardBobEssensa
	dc.w	0
	dc.l	CardTeppoNumminen
	dc.w	18
	dc.l	CardPhilHousley
	dc.w	17
	dc.l	CardThomasSteen
	dc.w	3
	dc.l	CardAlexeiZhamnov
	dc.w	2
	dc.l	CardTeemuSelanne
	dc.w	12
	dc.l	0
.ASE
	dc.l	CardPatrickRoy
	dc.w	0
	dc.l	CardRayBourque
	dc.w	18
	dc.l	CardLarryMurphy
	dc.w	17
	dc.l	CardAdamOates
	dc.w	6
	dc.l	CardMarioLemieux
	dc.w	3
	dc.l	CardAlexnderMogilny
	dc.w	15
	dc.l	CardGrantFuhr
	dc.w	1
	dc.l	CardTomBarrasso
	dc.w	2
	dc.l	CardMarkMessier
	dc.w	4
	dc.l	CardKirkMuller
	dc.w	5
	dc.l	CardJoeSakic
	dc.w	7
	dc.l	CardPierreTurgeon
	dc.w	8
	dc.l	CardPatLaFontaine
	dc.w	9
	dc.l	CardKevinStevens
	dc.w	10
	dc.l	CardJaromirJagr
	dc.w	11
	dc.l	CardPeterBondra
	dc.w	12
	dc.l	CardMikeGartner
	dc.w	13
	dc.l	NoPicSkater2
	dc.w	14
	dc.l	CardMarkRecchi
	dc.w	16
	dc.l	CardBrianLeetch
	dc.w	19
	dc.l	CardSteveDuchesne
	dc.w	20
	dc.l	CardAlIafrate
	dc.w	21
	dc.l	CardScottStevens
	dc.w	22
	dc.l	CardZarleyZalapski
	dc.w	23
	dc.l	NoPicSkater2
	dc.w	24
	dc.l	0
.ASW
	dc.l	CardEdBelfour
	dc.w	0
	dc.l	CardPaulCoffey
	dc.w	19
	dc.l	CardPhilHousley
	dc.w	21
	dc.l	CardLucRobitaille
	dc.w	10
	dc.l	CardSteveYzerman
	dc.w	3
	dc.l	CardTeemuSelanne
	dc.w	14
	dc.l	CardTimCheveldae
	dc.w	1
	dc.l	CardFelixPotvin
	dc.w	2
	dc.l	CardMikeModano
	dc.w	4
	dc.l	CardJeremyRoenick
	dc.w	5
	dc.l	CardBrianBradley
	dc.w	6
	dc.l	CardDougGilmour
	dc.w	7
	dc.l	CardWayneGretzky
	dc.w	8
	dc.l	CardGaryRoberts
	dc.w	9
	dc.l	CardTheorenFleury
	dc.w	11
	dc.l	CardBrettHull
	dc.w	12
	dc.l	CardPavelBure
	dc.w	13
	dc.l	CardPatFalloon
	dc.w	15
	dc.l	NoPicSkater2
	dc.w	16
	dc.l	CardGarySuter
	dc.w	17
	dc.l	CardJeffBrown
	dc.w	18
	dc.l	CardChrisChelios
	dc.w	20
	dc.l	CardDaveManson
	dc.w	22
	dc.l	CardSteveSmith
	dc.w	23
	dc.l	CardSteveChiasson
	dc.w	24
	dc.l	0
PrintRecordValue	;Record line for a player card (PlayerCardScreen): copy RecordTxt to a3, then the record value of player d1 (GetRecordValue) and goals / goal or
	;saves / save. An empty String when there is no value
	movem.l	d0-d7/a1-a6,-(sp)
	move.l	a1,-(sp)
	movea.l	a1,a3
	movea.l	#RecordTxt,a1
	movem.l	d0-d1,-(sp)
	bsr.w	StartText
	movem.l	(sp)+,d0-d1
	bsr.w	GetRecordValue
	tst.w	d0
	bne.w	.0
	movea.l	(sp)+,a1
	move.w	#2,(a1)
	bra.w	.x
.0
	movea.l	#TempBuffer,a1
	move.w	d0,(TempWord2).w
	bsr.w	AppendNumber
	movea.l	(sp),a3
	movea.l	#TempBuffer,a1
	jsr	(appstring).l
	move.w	(TempWord2).w,d0
	movea.l	#RecSavesTxt,a1
	cmp.w	#1,d0
	bne.w	.1
	movea.l	#RecSaveTxt,a1
.1
	tst.w	d1
	bne.w	.2
	movea.l	#RecGoalsTxt,a1
	cmp.w	#1,d0
	bne.w	.2
	movea.l	#RecGoalTxt,a1
.2
	movea.l	(sp)+,a3
	jsr	(appstring).l
.x
	movem.l	(sp)+,d0-d7/a1-a6
	rts
RecordTxt	dc.b	0	;PrintRecordValue text
	dc.b	$A
	dc.b	$52	;R
	dc.b	$65	;e
	dc.b	$63	;c
	dc.b	$6F	;o
	dc.b	$72	;r
	dc.b	$64	;d
	dc.b	$20,0
RecGoalsTxt	dc.b	0	;PrintRecordValue text
	dc.b	8,$20
	dc.b	$67	;g
	dc.b	$6F	;o
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	$73	;s
RecGoalTxt	dc.b	0	;PrintRecordValue text
	dc.b	8,$20
	dc.b	$67	;g
	dc.b	$6F	;o
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	0
RecSavesTxt	dc.b	0	;PrintRecordValue text
	dc.b	8,$20
	dc.b	$73	;s
	dc.b	$61	;a
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$73	;s
RecSaveTxt	dc.b	0	;PrintRecordValue text
	dc.b	8,$20
	dc.b	$73	;s
	dc.b	$61	;a
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	0
StartText	;Copy String a1 (length word first) to a3
	movem.l	d0,-(sp)
	move.w	(a1),d0
	subq.w	#1,d0
.loop
	move.b	(a1)+,(a3)+
	dbf	d0,.loop
	movem.l	(sp)+,d0
	rts
AppendNumber	;Write d0 (0 ... 999, no leading zeros) as a String at a1, padded to an even length
	movem.w	d0-d6/a0,-(sp)
	move.l	a1,-(sp)
	move.w	d0,d6
	addq.l	#2,a1
	clr.w	d1
	ext.l	d0
	divu.w	#$64,d0
	tst.w	d0
	beq.w	.0
	addi.w	#$30,d0
	move.b	d0,(a1)+
	addq.w	#1,d1
.0
	swap	d0
	ext.l	d0
	divu.w	#$A,d0
	addi.w	#$30,d0
	cmp.b	#$30,d0
	bne.w	.1
	cmp.w	#$A,d6
	blt.w	.2
.1
	move.b	d0,(a1)+
	addq.w	#1,d1
.2
	swap	d0
	addi.w	#$30,d0
	move.b	d0,(a1)+
	addq.w	#1,d1
	btst	#0,d1
	beq.w	.3
	move.b	#0,(a1)+
	addq.w	#1,d1
.3
	movea.l	(sp)+,a0
	addq.w	#2,d1
	move.w	d1,(a0)
	movem.w	(sp)+,d0-d6/a0
	rts
GetRecordValue	;d0 = record d0 of player d1 of team d0 from save RAM (ReadPlayerRecord into $FFFF0000); d1 = 1 when the player is a goalie
	movem.l	d2-d7/a0-a6,-(sp)
	move.w	d0,-(sp)
	movea.l	#$30E,a2
	asl.w	#2,d0
	movea.l	0(a2,d0.w),a2
	adda.w	(a2),a2
	move.w	d1,d0
	bra.w	.0
.loop
	adda.w	(a2),a2
	addq.w	#8,a2
.0
	dbf	d0,.loop
	move.w	d1,d0
	move.w	(sp)+,d1
	move.w	d0,d5
	move.w	d1,d4
	ext.l	d0
	movea.l	#M68K_RAM,a0
	bsr.w	ReadPlayerRecord
	move.b	(a0),d0
	ext.w	d0
	movea.l	#$30E,a5
	asl.w	#2,d4
	movea.l	0(a5,d4.w),a5
	adda.w	$A(a5),a5
	move.w	(a5),d1
	movem.w	d0,-(sp)
	clr.w	d0
.loop2
	addq.w	#1,d0
	asl.w	#4,d1
	bne.s	.loop2
	cmp.w	d5,d0
	movem.w	(sp)+,d0
	bgt.w	.1
	clr.w	d1
	bra.w	.x
.1
	move.w	#1,d1
.x
	movem.l	(sp)+,d2-d7/a0-a6
	rts
PrintRecordHolder	;Record holder line: RecByTxt ("by") then the holder's user name (AppendRecordHolder). An empty String when there is none
	movem.l	d0-d7/a1-a6,-(sp)
	move.l	a1,-(sp)
	movea.l	a1,a3
	movea.l	#RecByTxt,a1
	movem.l	d0-d1,-(sp)
	bsr.w	StartText
	movem.l	(sp)+,d0-d1
	movea.l	#TempBuffer,a1
	bsr.w	AppendRecordHolder
	movea.l	(sp)+,a3
	cmpi.w	#2,(a1)
	bne.w	.0
	move.w	#2,(a3)
	bra.w	.x
.0
	jsr	(appstring).l
.x
	movem.l	(sp)+,d0-d7/a1-a6
	rts
RecByTxt	dc.b	0	;PrintRecordHolder text
	dc.b	6
	dc.b	$62	;b
	dc.b	$79	;y
	dc.b	$20,0
PrintRecordVs	;Record line: RecVsTxt ("vs.") then the user name and the opponent team (AppendRecordVs)
	movem.l	d0-d7/a1-a6,-(sp)
	move.l	a1,-(sp)
	movea.l	a1,a3
	movea.l	#RecVsTxt,a1
	movem.l	d0-d1,-(sp)
	bsr.w	StartText
	movem.l	(sp)+,d0-d1
	movea.l	#TempBuffer,a1
	bsr.w	AppendRecordVs
	movea.l	(sp)+,a3
	jsr	(appstring).l
	movem.l	(sp)+,d0-d7/a1-a6
	rts
RecVsTxt	dc.b	0	;PrintRecordVs text
	dc.b	6
	dc.b	$76	;v
	dc.b	$73	;s
	dc.b	$2E
	dc.b	$20
AppendRecordHolder	;Append the user name of the record holder (byte 1 of record a0, or read record d0 / d1 when a0 is 0) to a1 (AppendUserName)
	movem.l	d0-d7/a1-a2,-(sp)
	cmpa.l	#0,a0
	bne.w	.0
	movem.l	d0-d7/a1-a6,-(sp)
	move.w	d0,-(sp)
	move.w	d1,d0
	move.w	(sp)+,d1
	ext.l	d1
	ext.l	d0
	movea.l	#M68K_RAM,a0
	bsr.w	ReadPlayerRecord
	movea.l	#M68K_RAM,a0
	movem.l	(sp)+,d0-d7/a1-a6
.0
	move.b	1(a0),d2
	ext.w	d2
	bset	#7,(sflags6).w
	bsr.w	AppendUserName
	movem.l	(sp)+,d0-d7/a1-a2
	rts
AppendRecordVs	;Append the user name (byte 3 of record a0), a space and the opponent team name (byte 2, AppendTeamName) to a1
	movem.l	d0-d7/a0-a6,-(sp)
	cmpa.l	#0,a0
	bne.w	.0
	movem.l	d0-d7/a1-a6,-(sp)
	move.w	d0,-(sp)
	move.w	d1,d0
	move.w	(sp)+,d1
	ext.l	d1
	ext.l	d0
	movea.l	#M68K_RAM,a0
	bsr.w	ReadPlayerRecord
	movea.l	#M68K_RAM,a0
	movem.l	(sp)+,d0-d7/a1-a6
.0
	move.b	3(a0),d2
	ext.w	d2
	movem.l	d0/a1,-(sp)
	bset	#7,(sflags6).w
	bsr.w	AppendUserName
	movea.l	a1,a3
	movea.l	#RecSpaceTxt,a1
	jsr	(appstring).l
	movem.l	(sp)+,d0/a1
	move.b	2(a0),d0
	jsr	(AppendTeamName).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
RecSpaceTxt	dc.b	0	;AppendRecordVs text
	dc.b	4,$20,0
ReadPlayerRecord	;Read the 4 byte player record d1 (PlayerRecordOffsets) of team d0 from save RAM to a0
	bclr	#6,(sflags6).w
PlayerRecordIO	;Read (sflags6 bit 6 clear) or write a save RAM record block (ReadSRAM / WriteSRAM). Entered from WritePlayerRecord
	movem.l	d0-d1/a0-a1,-(sp)
	asl.l	#2,d0
	addi.l	#0,d0
	movea.l	#PlayerRecordOffsets,a1
	add.w	d1,d1
	move.w	0(a1,d1.w),d1
	asl.w	#2,d1
	ext.l	d1
	add.l	d1,d0
	moveq	#4,d1
	btst	#6,(sflags6).w
	beq.w	.0
	jsr	(WriteSRAM).l
	bra.w	.x
.0
	jsr	(ReadSRAM).l
.x
	movem.l	(sp)+,d0-d1/a0-a1
	rts
WritePlayerRecord	;Write the 4 byte player record
	bset	#6,(sflags6).w
	bra.s	PlayerRecordIO
clrCrowdRAM	;(clrCrowdRAM?). read the 16 byte crowd record block of team d1 from save RAM ($B60 + team * 16) to a0. Called from
	;LoadCrowdRec and DisplayGameStats
	bclr	#6,(sflags6).w
CrowdRecordIO	;The crowd record block: read or write (sflags6 bit 6). Entered from clrCrowdRAM and WriteCrowdRecord
	movem.l	d0-d1/a0-a1,-(sp)
	move.l	d1,d0
	asl.w	#4,d0
	addi.l	#$B60,d0
	moveq	#$10,d1
	btst	#6,(sflags6).w
	beq.w	.0
	jsr	(WriteSRAM).l
	bra.w	.x
.0
	jsr	(ReadSRAM).l
.x
	movem.l	(sp)+,d0-d1/a0-a1
	rts
WriteCrowdRecord	;Write the 16 byte crowd record block of team d1 (CrowdRecordIO)
	bset	#6,(sflags6).w
	bra.s	CrowdRecordIO
ReadTeamRecord	;Read the 16 byte team record block of team d1 ($D20 + team * 16) to a0 (TeamRecordIO)
	bclr	#6,(sflags6).w
TeamRecordIO	;A save RAM record block: read or write (sflags6 bit 6)
	movem.l	d0-d1/a0-a1,-(sp)
	move.l	d1,d0
	asl.w	#4,d0
	addi.l	#$D20,d0
	moveq	#$10,d1
	btst	#6,(sflags6).w
	beq.w	.0
	jsr	(WriteSRAM).l
	bra.w	.x
.0
	jsr	(ReadSRAM).l
.x
	movem.l	(sp)+,d0-d1/a0-a1
	rts
WriteTeamRecord	;Write the team record block (TeamRecordIO)
	bset	#6,(sflags6).w
	bra.s	TeamRecordIO
WriteNameLog	;Write the user name log ($80 bytes at namelog) to save RAM $DA0 (NameLogIO)
	bset	#6,(sflags6).w
	bra.w	NameLogIO
ReadNameLog	;Read the user name log from save RAM $DA0 to namelog. Called from GameSetUp
	bclr	#6,(sflags6).w
NameLogIO	;A user record block: read or write (sflags6 bit 6)
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	#$80,d1
	move.l	#$DA0,d0
	movea.l	#namelog,a0
	btst	#6,(sflags6).w
	beq.w	.0
	jsr	(WriteSRAM).l
	bra.w	.x
.0
	jsr	(ReadSRAM).l
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PlayerRecordOffsets	dc.b	0	;Record offsets for ReadPlayerRecord
	dc.b	0,0,$1A,0
	dc.b	$34	;4
	dc.b	0
	dc.b	$4E	;N
	dc.b	0
	dc.b	$68	;h
	dc.b	0,$82,0,$9C,0,$B6,0,$D0,0,$EA,1,4,1,$1E,1
	dc.b	$38	;8
	dc.b	1
	dc.b	$52	;R
	dc.b	1
	dc.b	$6C	;l
	dc.b	1,$86,1,$A0,1,$BA,1,$D4,1,$EE,2,8,2
	dc.b	$22	;"
	dc.b	2
	dc.b	$3C	;<
	dc.b	2
	dc.b	$56	;V
	dc.b	2
	dc.b	$70	;p
	dc.b	2,$8A,2,$A4,2,$BE,2,$D8
UpdateRecords	;With save RAM (ValidSRAM) and user records on (OptUserRec 0), update the team and player records after a game (UpdateTeamRecord
	;UpdateCrowdRecord, UpdatePlayerRecords), then the save RAM checksum (MakeSRAMChecksum). Called from Intermission
	tst.w	(ValidSRAM).w
	bmi.w	.x
	tst.w	(OptUserRec).w
	bne.w	.x
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	CountGoalies
	bsr.w	CountPlayers
	move.w	(HomeTeam).w,d1
	ext.l	d1
	movea.l	#ThreeStars,a0
	movea.l	#tmstruct,a2
	move.w	(homegoalies).w,d5
	move.w	(VisTeam).w,d6
	bsr.w	UpdatePlayerRecords
	move.w	(VisTeam).w,d1
	ext.l	d1
	movea.l	#AwShots,a2
	move.w	(awaygoalies).w,d5
	move.w	(HomeTeam).w,d6
	bsr.w	UpdatePlayerRecords
	clr.w	d7
	movea.l	#tmstruct,a1
	move.w	(homeuser).w,d4
	move.w	(awayuser).w,d5
	move.w	(HomeTeam).w,d1
	move.w	(VisTeam).w,d2
	move.w	(homegoalies).w,d6
	ext.l	d1
	movea.l	#ThreeStars,a0
	bsr.w	UpdateCrowdRecord
	movea.l	#AwShots,a1
	move.w	(awayuser).w,d4
	move.w	(homeuser).w,d5
	move.w	(VisTeam).w,d1
	move.w	(HomeTeam).w,d2
	move.w	(awaygoalies).w,d6
	ext.l	d1
	movea.l	#ThreeStars,a0
	bsr.w	UpdateCrowdRecord
	movea.l	#ThreeStars,a0
	move.w	(homeuser).w,d1
	ext.l	d1
	move.w	(awayuser).w,d2
	move.w	(HomeTeam).w,d3
	move.w	(VisTeam).w,d4
	movea.l	#tmstruct,a1
	movea.l	#AwShots,a2
	bsr.w	UpdateTeamRecord
	movea.l	#ThreeStars,a0
	move.w	(awayuser).w,d1
	ext.l	d1
	move.w	(homeuser).w,d2
	move.w	(VisTeam).w,d3
	move.w	(HomeTeam).w,d4
	movea.l	#AwShots,a1
	movea.l	#tmstruct,a2
	bsr.w	UpdateTeamRecord
	jsr	(MakeSRAMChecksum).l
	movem.l	(sp)+,d0-d7/a0-a6
.x
	rts
UpdateTeamRecord	;After a game: add the game to team record block d1 (games, wins, ties), and keep the biggest win and loss margins with the user names
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	ReadTeamRecord
	st	d7
	movem.w	d0,-(sp)
	clr.w	d0
	move.b	$A(a0),d0
	lsl.w	#8,d0
	move.b	$B(a0),d0
	cmp.w	#$2328,d0
	bge.w	.1
	addq.w	#1,d0
	move.b	d0,$B(a0)
	lsr.w	#8,d0
	move.b	d0,$A(a0)
	move.w	$C(a1),d0
	cmp.w	$C(a2),d0
	bgt.w	.0
	blt.w	.1
	clr.w	d0
	move.b	$C(a0),d0
	lsl.w	#8,d0
	move.b	$D(a0),d0
	addq.w	#1,d0
	move.b	d0,$D(a0)
	lsr.w	#8,d0
	move.b	d0,$C(a0)
	bra.w	.1
.0
	clr.w	d0
	move.b	8(a0),d0
	lsl.w	#8,d0
	move.b	9(a0),d0
	addq.w	#1,d0
	move.b	d0,9(a0)
	lsr.w	#8,d0
	move.b	d0,8(a0)
.1
	movem.w	(sp)+,d0
	movem.w	d0,-(sp)
	move.w	$C(a1),d0
	cmp.w	$C(a2),d0
	movem.w	(sp)+,d0
	ble.w	.3
	move.w	$C(a1),d5
	cmp.b	(a0),d5
	ble.w	.2
	st	d7
	move.b	d5,(a0)
	move.b	d3,1(a0)
	move.b	d4,2(a0)
	move.b	d2,3(a0)
.2
	move.w	$C(a2),d5
	move.w	(a2),d6
	sub.w	d5,d6
	cmp.b	4(a0),d6
	ble.w	.3
	st	d7
	move.b	d6,4(a0)
	move.b	d3,5(a0)
	move.b	d4,6(a0)
	move.b	d2,7(a0)
.3
	bsr.w	WriteTeamRecord
	movem.l	(sp)+,d0-d7/a0-a6
	rts
UpdateCrowdRecord	;Update the crowd records (clrCrowdRAM, WriteCrowdRecord)
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	clrCrowdRAM
	move.w	$C(a1),d3
	cmp.b	(a0),d3
	ble.w	.0
	move.b	d3,(a0)
	move.b	d4,1(a0)
	move.b	d5,3(a0)
	move.b	d2,2(a0)
	st	d7
.0
	subq.w	#1,d6
	clr.w	d3
.loop
	move.w	d6,d0
	addi.w	#$E8,d0
	move.b	0(a1,d0.w),(TempWord1).w
	addi.w	#-$34,d0
	move.b	0(a1,d0.w),d0
	sub.b	d0,(TempWord1).w
	cmp.b	(TempWord1).w,d3
	bge.w	.1
	move.b	(TempWord1).w,d3
.1
	dbf	d6,.loop
	cmp.b	4(a0),d3
	ble.w	.2
	st	d7
	move.b	d3,4(a0)
	move.b	d4,5(a0)
	move.b	d5,7(a0)
	move.b	d2,6(a0)
.2
	cmp.w	(HomeTeam).w,d1
	bne.w	.3
	move.b	8(a0),d3
	andi.w	#$FF,d3
	cmp.w	(CrowdPeak).w,d3
	bge.w	.3
	move.w	(CrowdPeak).w,d3
	st	d7
	move.b	d3,8(a0)
	move.b	d4,9(a0)
	move.b	d5,$B(a0)
	move.b	d2,$A(a0)
.3
	tst.w	d7
	beq.w	.x
	bsr.w	WriteCrowdRecord
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
UpdatePlayerRecords	;After a game: for the 26 players of team a2, keep each new best (goals, or saves for the goalies) in his player record with the user names and opponent
	;d6
	clr.l	d0
	move.w	#$19,d2
.loop
	bsr.w	ReadPlayerRecord
	cmp.w	d5,d0
	blt.w	.0
	move.w	d0,-(sp)
	addi.w	#$B4,d0
	move.b	0(a2,d0.w),d4
	move.w	(sp)+,d0
	bra.w	.1
.0
	move.w	d0,-(sp)
	addi.w	#$E8,d0
	move.b	0(a2,d0.w),d4
	addi.w	#-$34,d0
	sub.b	0(a2,d0.w),d4
	move.w	(sp)+,d0
.1
	move.b	(a0),d3
	cmp.b	d3,d4
	ble.w	.3
	move.b	d4,(a0)
	move.b	(homeuser+1).w,1(a0)
	move.b	(awayuser+1).w,3(a0)
	cmpa.l	#tmstruct,a2
	beq.w	.2
	move.b	(awayuser+1).w,1(a0)
	move.b	(homeuser+1).w,3(a0)
.2
	move.b	d6,2(a0)
	bsr.w	WritePlayerRecord
.3
	addq.w	#1,d0
	dbf	d2,.loop
	rts
CountGoalies	;homegoalies / awaygoalies = goalies of the home / away team (ReadAttributeNibble). Called and PlayerCards
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#tmstruct,a2
	jsr	(ReadAttributeNibble).l
	move.w	d0,(homegoalies).w
	movea.l	#AwShots,a2
	jsr	(ReadAttributeNibble).l
	move.w	d0,(awaygoalies).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
CountPlayers	;homeplayers / awayplayers = players of the home / away team (GetPlayerCount)
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#tmstruct,a2
	jsr	(GetPlayerCount).l
	move.w	d0,(homeplayers).w
	movea.l	#AwShots,a2
	jsr	(GetPlayerCount).l
	move.w	d0,(awayplayers).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
AppendUserName	;Append user name d2 (12 bytes of the name log at namelog, spaces for 0) to a1, or NoNameTxt when d2 is 0; trailing spaces trimmed (TrimSpaces)
	movem.l	d0-d3/a0-a3,-(sp)
	movea.l	a1,a2
	tst.w	d2
	beq.w	.2
	move.w	#$B,d0
	clr.w	d3
	movea.l	#namelog,a0
	mulu.w	#$C,d2
	adda.l	d2,a0
.loop
	move.b	0(a0,d3.w),d1
	bne.w	.0
	move.b	#$20,d1
.0
	move.b	d1,2(a1)
	tst.b	(a1)+
	addq.w	#1,d3
	dbf	d0,.loop
	move.w	#$E,(a2)
	btst	#7,(sflags6).w
	beq.w	.1
	bsr.w	TrimSpaces
.1
	bra.w	.x
.2
	movea.l	a1,a3
	move.l	a3,-(sp)
	movea.l	#NoNameTxt,a1
	jsr	(StartText).l
	movea.l	(sp)+,a2
	bsr.w	TrimSpaces
.x
	movem.l	(sp)+,d0-d3/a0-a3
	rts
NoNameTxt	dc.b	0	;AppendUserName data
	dc.b	2
PlayerCards	;93 has no counterpart. "Player Cards" menu item (menu lists), with save RAM only: the player card screens
	;(DrawPlayerCard), A / C to page, start exits (ExitAttributeScreen2)
	tst.w	(ValidSRAM).w
	bpl.w	.0
	rts
.0
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(forceblack).l
	bclr	#0,(disflags).w
	move.w	(disflags).w,-(sp)
	bset	#2,(disflags).w
	move.w	(VSPRITES).w,d0
	jsr	(Vmaddr).l
	move.l	#0,(a0)
	move.w	#VDPR_MODE4+$81,Vctrl-Vdata(a0)
	move.w	#6,(Map3col1).w
	move.w	#VDPR_HSCROLL,Vctrl-Vdata(a0)
	clr.w	d0
	jsr	(Vmaddr).l
	move.l	#0,(a0)
	move.w	(sp)+,(disflags).w
	bclr	#1,(disflags).w
	bsr.w	CountGoalies
	bsr.w	CountPlayers
	move.w	(smallfontchars).w,d4
	movea.l	#SmallFontMap+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$05234167,$89ABCDEF	;remap table
	jsr	(printz).l
	String	-TXMAP3,0,0
	movea.l	#PlayerCardsScreenPic,a0	;the Player Cards screen picture
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d1
	clr.w	d0
	moveq	#$28,d2
	move.w	#$1C,d3
	moveq	#$D,d5
	move.w	#1,d4
	jsr	(dobitmap).l
	move.w	d4,(cardlogochars1).w
	addi.w	#$24,d4
	move.w	d4,(cardlogochars2).w
	addi.w	#$24,d4
	move.w	d4,-(sp)
	jsr	(printz).l
	String	-TXMAP2,0,0
	moveq	#$40,d0
	moveq	#$20,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	move.w	(sp)+,d4
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),1,1
	movea.l	#CornerLogoMap,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d1
	clr.w	d0
	moveq	#6,d2
	move.w	#6,d3
	moveq	#8,d5
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),'!',1
	movea.l	#ArenaGfxBank,a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d1
	clr.w	d0
	moveq	#6,d2
	move.w	#6,d3
	moveq	#0,d5
	jsr	(dobitmap).l
	bsr.w	BuildCardPlayerLists
	move.w	#$18,(palcount).w
	clr.w	(homecardidx).w
	clr.w	(awaycardidx).w
	tst.w	(FourWayPlay).w
	beq.w	.1
	cmpi.w	#3,(pausepad).w
	beq.w	.3
	bra.w	.2
.1
	btst	#1,(sflags).w
	beq.w	.3
.2
	move.w	(cont2team).w,d0
	bra.w	.4
.3
	move.w	(cont1team).w,d0
.4
	subq.w	#1,d0
	bpl.w	.5
	clr.w	d0
.5
	andi.w	#1,d0
	movea.l	#awaycardidx,a0
	move.w	d0,(cardvis).w
	bne.w	.6
	movea.l	#homecardidx,a0
.6
	bsr.w	DrawPlayerCard
.loop
	jsr	(vcountwait).l
	jsr	(getpzjoy).l
	jsr	(ProcessInputWithRepeat).l
	btst	#7,d3
	bne.w	.10
	btst	#6,d1
	beq.w	.7
	eori.w	#1,(cardvis).w
	clr.w	d0
	bra.w	.8
.7
	move.w	#1,d0
	btst	#5,d1
	bne.w	.8
	moveq	#1,d0
	jsr	(nodiag).l
	btst	#3,d1
	bne.w	.8
	neg.w	d0
	btst	#2,d1
	bne.w	.8
	bra.s	.loop
.8
	movea.l	#homecardidx,a0
	move.w	(homeplayers).w,(cardcount).w
	tst.w	(cardvis).w
	beq.w	.9
	movea.l	#awaycardidx,a0
	move.w	(awayplayers).w,(cardcount).w
.9
	add.w	d0,(a0)
	bsr.w	WrapCardIndex
	bsr.w	DrawPlayerCard
	bra.w	.loop
.10
	movem.l	(sp)+,d0-d7/a0-a6
	jmp	ExitAttributeScreen2
WrapCardIndex	;Wrap the card index (a0) into 0 ... cardcount - 1
	move.w	d0,-(sp)
	move.w	(cardcount).w,d0
	addq.w	#1,d0
	cmp.w	(a0),d0
	bne.w	.0
	clr.w	(a0)
.0
	tst.w	(a0)
	bpl.w	.1
	subq.w	#1,d0
	move.w	d0,(a0)
.1
	move.w	(sp)+,d0
	rts
DrawPlayerCard	;Draw a player card: picture (DrawPictureBox), name, "Records" and "This Game" columns (PrintCardRecords, PrintSaveRecordLine, PrintGoalRecordLine), Overall
	;Rating (PrintOverallRating), Starting Line (PrintStartingLine), position, goals / assists or saves (PrintGoalsAssists, PrintSaves)
	movem.l	d0-d7/a1-a6,-(sp)
	move.l	a0,-(sp)
	move.w	(HomeTeam).w,d0
	tst.w	(cardvis).w
	beq.w	.0
	move.w	(VisTeam).w,d0
.0
	asl.w	#6,d0
	movea.l	#TeamPalettes,a6
	move.l	$26(a6,d0.w),(palfadenew+$22).w
	move.w	#$64,(palcount).w
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,7
	move.w	#$28,d0
	move.w	#$15,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	movea.l	(sp),a0
	tst.w	(a0)
	bne.w	.1
	bsr.w	PrintCardRecords
	bra.w	.2
.1
	bsr.w	.3
.2
	movea.l	(sp)+,a0
	movem.l	(sp)+,d0-d7/a1-a6
	rts
.3
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(a0),(cardindex).w
	bsr.w	DrawPictureBox
	move.w	#$21,d0
	move.w	#8,d1
	jsr	(ClearCardText).l
	move.w	#$64,(palcount).w
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	move.w	(HomeTeam).w,d0
	tst.w	(cardvis).w
	beq.w	.4
	move.w	(VisTeam).w,d0
.4
	move.w	d0,(TempWord2).w
	movea.l	#$30E,a2
	asl.w	#2,d0
	movea.l	0(a2,d0.w),a2
	adda.w	(a2),a2
	bsr.w	GetCardPlayer
	bra.w	.5
.loop
	adda.w	(a2),a2
	addq.w	#8,a2
.5
	dbf	d0,.loop
	clr.w	d7
	movea.l	#ThreeStars,a3
	movea.l	a2,a1
	bsr.w	StartText
	movea.l	#ThreeStars+2,a3
.loop2
	addq.w	#1,d7
	cmpi.b	#$20,(a3)+
	bne.s	.loop2
	subq.w	#1,d7
	move.b	#0,-(a3)
	movea.l	#ThreeStars,a3
	addq.w	#1,d7
	andi.w	#$FE,d7
	addq.w	#2,d7
	move.w	d7,(a3)
	movea.l	a3,a1
	move.w	#8,(printx).l
	move.w	#$B,(printy).l
	jsr	(printsmall).l
	bsr.w	GetCardPlayer
	movea.l	#tmstruct,a2
	tst.w	(cardvis).w
	beq.w	.6
	movea.l	#AwShots,a2
.6
	jsr	(FormatPlayerNameLast).l
	move.w	#8,(printx).l
	move.w	#$C,(printy).l
	jsr	(printsmall).l
	move.w	#8,d1
	jsr	(PrintCardTeam).l
	move.w	#$15,(printx).l
	move.w	#$C,(printy).l
	move.w	(printx).w,-(sp)
	jsr	(printsmallz).l
	String	'  Records'
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	jsr	(printsmallz).l
	String	'-----------'
	move.w	#$15,(printx).l
	move.w	#$12,(printy).l
	move.w	(printx).w,-(sp)
	jsr	(printsmallz).l
	String	' This Game '
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	jsr	(printsmallz).l
	String	'-----------'
	move.w	(HomeTeam).w,d1
	tst.w	(cardvis).w
.7
	beq.w	.8
	move.w	(VisTeam).w,d1
.8
	ext.l	d1
	bsr.w	GetCardPlayer
	ext.l	d0
	movea.l	#ThreeStars,a0
	bsr.w	ReadPlayerRecord
	movea.l	#ThreeStars,a0
	move.b	(a0),d2
	move.b	1(a0),d3
	move.b	3(a0),d4
	move.b	2(a0),d5
	move.w	#$E,d1
	move.w	(homegoalies).w,d0
	tst.w	(cardvis).w
.9
	beq.w	.11
.10
	move.w	(awaygoalies).w,d0
.11
	cmp.w	(cardplayer).w,d0
	ble.w	.12
	move.w	#$15,d0
	bsr.w	PrintSaveRecordLine
	bsr.w	GetCardPlayer
	move.w	#$15,d1
	move.w	#$14,d2
	bsr.w	PrintSaves
	st	(matchup).w
	bra.w	.13
.12
	move.w	#$15,d0
	bsr.w	PrintGoalRecordLine
	bsr.w	GetCardPlayer
	move.w	#$15,d1
	move.w	#$14,d2
	bsr.w	PrintGoalsAssists
	clr.w	(matchup).w
.13
	move.w	#3,d1
	move.w	#$11,d2
	bsr.w	GetCardPlayer
	bsr.w	PrintOverallRating
	move.w	#3,d1
	move.w	#$F,d2
	bsr.w	GetCardPlayer
	bsr.w	PrintCardPosition
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintCardRecords	;Player card "Records" column
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#$21,d0
	move.w	#8,d1
	jsr	(ClearCardText).l
	move.w	#1,d0
	move.w	#8,d1
	bset	#0,(sflags6).w
	jsr	(ClearCardText).l
	bclr	#0,(sflags6).w
	move.w	#$64,(palcount).w
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	move.w	#8,d1
	jsr	(PrintCardTeam).l
	move.w	#3,d0
	move.w	#$F,d1
	jsr	(PrintStartingLine).l
	move.w	#8,d0
	move.w	#$B,d1
	jsr	(PrintTeamRating).l
	move.w	#$15,(printx).w
	move.w	#$C,(printy).w
	move.w	(printx).w,-(sp)
	jsr	(printsmallz).l
	String	'  Records'
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	jsr	(printsmallz).l
	String	'-----------'
	move.w	(HomeTeam).w,d1
	tst.w	(cardvis).w
	beq.w	.0
	move.w	(VisTeam).w,d1
.0
	ext.l	d1
	movea.l	#ThreeStars,a0
	move.l	a0,-(sp)
	jsr	(clrCrowdRAM).l
	move.w	#$15,d0
	move.w	#$E,d1
	move.b	(a0),d2
	move.b	1(a0),d3
	move.b	3(a0),d4
	move.b	2(a0),d5
	bsr.w	PrintGoalRecordLine
	movea.l	(sp),a0
	move.w	#$15,d0
	move.w	#$12,d1
	move.b	4(a0),d2
	move.b	5(a0),d3
.1
	move.b	7(a0),d4
	move.b	6(a0),d5
	bsr.w	PrintSaveRecordLine
	movea.l	(sp)+,a0
	move.w	#$15,d0
	move.w	#$16,d1
	move.b	8(a0),d2
	move.b	9(a0),d3
	move.b	$B(a0),d4
	move.b	$A(a0),d5
	bsr.w	PrintCrowdRecordLine
	movem.l	(sp)+,d0-d7/a0-a6
	rts
ClearCardText	;Player card: erase the text area and redraw the team bitmap behind it (dobitmap)
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP2),0,0
	move.w	d0,(printx).w
	move.w	d1,(printy).w
	move.w	(cardlogochars1).w,d4
	move.w	(HomeTeam).w,d3
	tst.w	(cardvis).w
	beq.w	.0
	move.w	(VisTeam).w,d3
.0
	asl.w	#2,d3
	movea.l	#TeamLogoBitmaps,a0
	movea.l	0(a0,d3.w),a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	asl.w	#3,d3
	movea.l	#TeamLogoPalettes,a0
	subi.w	#$20,d3
	adda.w	d3,a0
	adda.l	(a2)+,a1
	move.w	#6,d3
	move.w	#6,d2
	clr.w	d0
	clr.w	d1
	move.l	(palfadenew+$22).w,-(sp)
	move.l	(palfadenew+$26).w,-(sp)
	move.w	#2,d5
	jsr	(dobitmap).l
	move.l	(sp)+,(palfadenew+$26).w
	move.l	(sp)+,(palfadenew+$22).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintCrowdRecordLine	;Player card record line: the arena crowd record (CrowdLevelTxt, PrintCardRecordLine)
	move.l	#CrowdLevelTxt,(TempMaxSpd).l
	bra.w	PrintCardRecordLine
CrowdLevelTxt	dc.b	0	;PrintCrowdRecordLine text
	dc.b	$12,$20
	dc.b	$64	;d
	dc.b	$42	;B
	dc.b	$20
	dc.b	$43	;C
	dc.b	$72	;r
	dc.b	$6F	;o
	dc.b	$77	;w
	dc.b	$64	;d
	dc.b	$20
	dc.b	$4C	;L
	dc.b	$65	;e
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$6C	;l
	dc.b	0
PrintSaveRecordLine	;Player card record line: the saves record (CardSavesTxt / CardSavesByTxt, PrintCardRecordLine)
	movem.l	a1-a3,-(sp)
	movea.l	#CardSavesTxt,a1
	tst.w	d3
	beq.w	.0
	movea.l	#CardSavesByTxt,a1
.0
	cmp.b	#1,d2
	bne.w	.1
	adda.w	(a1),a1
.1
	move.l	a1,(TempMaxSpd).w
	movem.l	(sp)+,a1-a3
	bra.w	PrintCardRecordLine
CardSavesTxt	dc.b	0	;PrintSaveRecordLine text
	dc.b	$A,$20
	dc.b	$53	;S
	dc.b	$61	;a
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$73	;s
	dc.b	$20,0,0,8,$20
	dc.b	$53	;S
	dc.b	$61	;a
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$20
CardSavesByTxt	dc.b	0	;PrintSaveRecordLine text
	dc.b	$C,$20
	dc.b	$53	;S
	dc.b	$61	;a
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$73	;s
	dc.b	$20
	dc.b	$62	;b
	dc.b	$79	;y
	dc.b	0,0,$A,$20
	dc.b	$53	;S
	dc.b	$61	;a
	dc.b	$76	;v
	dc.b	$65	;e
	dc.b	$20
	dc.b	$62	;b
	dc.b	$79	;y
PrintGoalRecordLine	;Player card record line: the goals record (CardGoalsTxt / CardGoalsByTxt, PrintCardRecordLine)
	movem.l	a1-a3,-(sp)
	movea.l	#CardGoalsTxt,a1
	tst.w	d3
	beq.w	.0
	movea.l	#CardGoalsByTxt,a1
.0
	cmp.b	#1,d2
	bne.w	.1
	adda.w	(a1),a1
.1
	move.l	a1,(TempMaxSpd).w
	movem.l	(sp)+,a1-a3
	bra.w	PrintCardRecordLine
CardGoalsTxt	dc.b	0	;PrintGoalRecordLine text
	dc.b	$A,$20
	dc.b	$47	;G
	dc.b	$6F	;o
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	$73	;s
	dc.b	$20,0,0,8,$20
	dc.b	$47	;G
	dc.b	$6F	;o
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	$20
CardGoalsByTxt	dc.b	0	;PrintGoalRecordLine text
	dc.b	$C,$20
	dc.b	$47	;G
	dc.b	$6F	;o
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	$73	;s
	dc.b	$20
	dc.b	$62	;b
	dc.b	$79	;y
	dc.b	0,0,$A,$20
	dc.b	$47	;G
	dc.b	$6F	;o
	dc.b	$61	;a
	dc.b	$6C	;l
	dc.b	$20
	dc.b	$62	;b
	dc.b	$79	;y
PrintCardRecordLine	;Print a player card record line: label (appstring), value (AppendNumber / AppendUserName / AppendTeamName)
	tst.b	d2
	bne.w	.0
	rts
.0
	move.w	d0,(printx).w
	move.w	d1,(printy).w
	move.w	d2,d0
	andi.w	#$FF,d0
	movea.l	#mesarea,a1
	move.l	a1,-(sp)
	jsr	(AppendNumber).l
	movea.l	(sp)+,a1
	movea.l	a1,a3
	movea.l	(TempMaxSpd).w,a1
	jsr	(appstring).l
	move.w	(printx).w,-(sp)
	movea.l	#mesarea,a1
	jsr	(printsmall).l
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	movea.l	#mesarea,a1
	move.w	d3,d2
	ext.w	d2
	bset	#7,(sflags6).w
	jsr	(AppendUserName).l
	movea.l	a1,a3
	movea.l	#CardVsTxt,a1
	jsr	(appstring).l
	move.w	(printx).w,-(sp)
	movea.l	#mesarea,a1
	jsr	(printsmall).l
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	move.w	d4,d2
	ext.w	d2
	movea.l	#mesarea,a1
	bset	#7,(sflags6).w
	jsr	(AppendUserName).l
	movea.l	a1,a3
	movea.l	#CardEmptyTxt,a1
	jsr	(appstring).l
	move.w	d5,d0
	movea.l	#mesarea,a1
	jsr	(AppendTeamName).l
	movea.l	#mesarea,a1
	jsr	(printsmall).l
	rts
CardVsTxt	dc.b	0	;PrintCardRecordLine text
	dc.b	6,$20
	dc.b	$76	;v
	dc.b	$73	;s
	dc.b	$2E
CardEmptyTxt	dc.b	0	;PrintCardRecordLine text
	dc.b	4,$20,0
AppendTeamName	;Append the city name of team d0 (TeamList block Strings) to a1 (appstring)
	movem.l	d0/a0-a3,-(sp)
	ext.w	d0
	asl.w	#2,d0
	movea.l	#$30E,a0
	movea.l	0(a0,d0.w),a0
	move.w	4(a0),d0
	ext.l	d0
	adda.l	d0,a0
	adda.w	(a0),a0
	movea.l	a1,a3
	movea.l	a0,a1
	jsr	(appstring).l
	movem.l	(sp)+,d0/a0-a3
	rts
PrintOverallRating	;Player card "Overall Rating" (CalcAttrib, AttribAdjust)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d1,(printx).w
	move.w	d2,(printy).w
	move.w	d1,-(sp)
	jsr	(printsmallz).l
	String	'Overall'
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	jsr	(printsmallz).l
	String	'Rating   '
	movea.l	#tmstruct,a2
	tst.w	(cardvis).w
	beq.w	.0
	movea.l	#AwShots,a2
.0
	move.l	(PAttribOverallMask).l,d4
	tst.w	(matchup).w
	beq.w	.1
	move.l	(GAttribOverallMask).l,d4
.1
	bsr.w	CalcAttrib
	mulu.w	#$64,d0
	divu.w	d1,d0
	bsr.w	AttribAdjust
	movea.l	#mesarea,a1
	bsr.w	AppendNumber
	movea.l	#mesarea,a1
	jsr	(printsmall).l
	movem.l	(sp)+,d0-d7/a0-a6
CardStub	;An rts with no caller
	rts
PrintStartingLine	;Player card "Starting Line": the line slots the player starts in (LinePosNames position names)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(HomeTeam).w,d2
	bsr.w	GetTeamStruct
	tst.w	(cardvis).w
.0
	beq.w	.1
	move.w	(VisTeam).w,d2
	bsr.w	GetTeamStruct
.1
	movea.l	#$30E,a0
	asl.w	#2,d2
	ext.l	d2
	adda.l	d2,a0
	movea.l	(a0),a0
	move.w	6(a0),d2
	ext.l	d2
	adda.l	d2,a0
	move.w	d0,(printx).w
	move.w	d1,(printy).w
	move.w	d0,-(sp)
	jsr	(printsmallz).l
	String	'Starting Line'
	addq.w	#2,(printy).w
	move.w	(sp),(printx).w
	movea.l	#LinePosNames,a1
.loop
	cmpi.w	#2,(a1)
	beq.w	.2
	move.w	(sp),(printx).w
	move.l	a1,-(sp)
	jsr	(printsmall).l
	move.b	(a0)+,d0
	ext.w	d0
	subq.w	#1,d0
	jsr	(FormatPlayerNameShort).l
	jsr	(printsmall).l
	movea.l	(sp)+,a1
	move.w	(a1),d0
	ext.l	d0
	adda.l	d0,a1
	addq.w	#1,(printy).w
	bra.s	.loop
.2
	move.w	(sp)+,d0
	movem.l	(sp)+,d0-d7/a0-a6
	rts
LinePosNames	;Position names; an empty String ends the list
	String	'G   '
	String	'LD  '
	String	'RD  '
	String	'LW  '
	String	'C   '
	String	'RW  '
	dc.w	2
CalcAttrib	;(and comments). the overall rating of player d0: his attributes weighted by OvrPlayerWgtList (skaters) or
	;OvrGoalWgtList (goalies), and by AttribWgtList. Called from getNameandAttrib and PrintOverallRating
	move.l	a6,-(sp)	;push a6 to stack
	clr.w	(OvrDivisor).w
	clr.w	(OvrDividend).w
	movea.l	#AttribWgtList,a6	;move address FAB3C into a6
	cmp.l	(PAttribOverallMask).l,d4	;compare long word (1FBA000A) to d4
	bne.w	.1	;branch if not equal
	movea.l	#OvrPlayerWgtList,a6	;move address FAB1C into a6
.1
	cmp.l	(GAttribOverallMask).l,d4	;compare long word 130F000A to d4
	bne.w	.11	;branch if not equal
	movea.l	#OvrGoalWgtList,a6	;move address FAB2C into a6
.11
	movea.l	$1E(a2),a0	;move ROM address of Team Data into a0
	lea	$1A2(a2),a4	;move start of Hot/Cold table to a4
	clr.l	d1	;clear d1
	move.w	d0,d1	;move d0 into d1. d0 is the offset of the player
	asl.w	#4,d1	;mult d1 by 16
	adda.l	d1,a4	;add d1 to a4
	adda.l	#$10,a4	;add 16 dec to a4. Move to start of Hot/Cold for player.
	adda.w	(a0),a0	;add player table offset to Team Data start
.skip
	adda.w	(a0),a0	;add Player Name length to a0
	addq.w	#8,a0	;add 8 (skips attributes)
	dbf	d0,.skip	;skip until at player
	clr.w	d0	;clear d0
	clr.w	d1	;clear d1
	moveq	#$F,d2	;move 15 dec into d2 (start at bit 15)
	swap	d4	;swap words in d4
.loop2
	btst	d2,d4	;bit test d2 bit in d4
	beq.w	.check	;branch if bit is 0
	move.w	d2,d3	;move d2 into d3
	lsr.w	#1,d3	;divide d3 by 2
	neg.w	d3	;negate d3
	move.b	-1(a0,d3.w),d3	;move a0+d3-1 into d3. a0 currently at end of player data. Sets d3 byte to attribute
	btst	#0,d2	;test bit 0 of d2
	beq.w	.0	;branch if equal
	lsr.w	#4,d3	;divide d3 by 16. Shifts upper nibble to lower in case d2 was odd
.0
	andi.w	#$F,d3	;pass bottom nibble of d3
	cmp.w	#$D,d2	;compare d2 to 13 dec (check if Wgt nibble)
	bne.w	.cont	;branch if not equal
	bra.w	.00
.cont
	cmp.w	#6,d2	;compare d2 to 6 (Fight nibble)
	beq.w	.00
	movem.l	d5-d7,-(sp)	;push to stack
	move.b	0(a6,d2.w),d5	;move a6+d2 into d5
	ext.w	d5	;sign extend d5
	cmp.w	#2,d5	;comare d5 to 2
	beq.w	.000	;branch if equal
	move.w	d3,-(sp)	;push d3 to stack (current attribute)
	subq.w	#2,d5	;sub 2 from d5
.attribadd
	add.w	(sp),d3	;add stack value to d3
	dbf	d5,.attribadd	;loop until d5 is 0
	asr.w	#1,d3	;divide d3 by 2
	tst.w	(sp)+	;test stack and increment
.000
	movem.l	(sp)+,d5-d7	;pop off stack into d5-d7
	cmpa.l	#AttribWgtList,a6	;check if a6 is FAB3C
	beq.w	.2	;branch if equal
	neg.w	d2	;negate d2
	move.w	d7,-(sp)	;push d7 to stack
	move.b	-1(a4,d2.w),d7	;move data at a4+d2-1 into d7
	ext.w	d7	;sign extend d7
	add.w	d7,(OvrDivisor).w	;add d7 to data at D6CE
	addq.w	#1,(OvrDividend).w	;add 1 to D6D0
	move.w	(sp)+,d7	;pop from stack into d7
	neg.w	d2	;negate d2
	bra.w	.00	;branch
.2
	move.w	d3,-(sp)	;push d3 onto stack
	asl.w	#4,d3	;mult d3 by 16
	add.w	(sp),d3	;add value on stack to d3
	add.w	(sp)+,d3	;add value again from stack into d3 and increment
	neg.w	d2	;negate d2
	add.b	-1(a4,d2.w),d3	;add data at a4+s2-1 into d3
	bpl.w	.pos	;branch if positive
	clr.b	d3	;clear d3
.pos
	neg.w	d2	;negate d2
.00
	add.w	d3,d0	;add d3 to d0 (d0 = attribute value)
	addi.w	#$64,d1	;'d'   ; add 100 dec to d1
.check
	dbf	d2,.loop2
	cmpa.l	#AttribWgtList,a6	;compare address value FAB3C to a6
	beq.w	.3	;branch if equal
	move.w	#$64,d1	;'d'   ; move 100 dec into d1
	movem.l	d6-d7,-(sp)	;push d6 and d7 to stack
	move.w	(OvrDivisor).w,d6	;move into d6
	ext.l	d6	;word extend d6
	move.w	(OvrDividend).w,d7	;move into d7
	divs.w	d7,d6	;divide d7 into d6
	add.w	d6,d0	;add d6 to d0
	movem.l	(sp)+,d6-d7	;pop from stack
.3
	cmp.w	d1,d0
	blt.w	.4
	move.w	d0,d1
	subq.w	#1,d0
.4
	movea.l	(sp)+,a6
	rts
OvrPlayerWgtList	dc.b	2	;CalcAttrib skater weights
	dc.b	2,2,2,4,6,2,4,2,4,6,6,4,2,2,2
OvrGoalWgtList	dc.b	2	;CalcAttrib goalie weights
	dc.b	2,2,2,2,2,2,2,9,9,2,2,9,2,2,2
AttribWgtList	dc.b	2	;CalcAttrib attribute weights
	dc.b	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
PrintCardPosition	;Player card position: Goalie, Forward or Defenseman (from the roster index: ReadAttributeNibble, GetDefenseStart)
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#mesarea,a1
	bsr.w	GetJerseyString
	move.w	d1,(printx).w
	move.w	d2,(printy).w
	jsr	(printsmall).l
	movea.l	#tmstruct,a2
	tst.w	(cardvis).w
	beq.w	.0
	movea.l	#AwShots,a2
.0
	move.w	d0,-(sp)
	jsr	(GetDefenseStart).l
	cmp.w	(sp),d0
	ble.w	.2
	move.w	(sp),d0
	jsr	(ReadAttributeNibble).l
	cmp.w	(sp),d0
	ble.w	.1
	jsr	(printsmallz).l
	String	' Goalie'
	bra.w	.3
.1
	jsr	(printsmallz).l
	String	' Forward'
	bra.w	.3
.2
	jsr	(printsmallz).l
	String	' Defenseman'
.3
	tst.w	(sp)+
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintTeamRating	;Player card "Team Rating" (GetTeamRating, high ROM)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d0,(printx).w
	move.w	d1,(printy).w
	move.w	d0,-(sp)
	jsr	(printsmallz).l
	String	'Team'
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	jsr	(printsmallz).l
	String	'Rating  '
.0
	movea.l	#tmstruct,a0
	tst.w	(cardvis).w
	beq.w	.1
	movea.l	#AwShots,a0
.1
	movea.l	a0,a2
	bsr.w	GetTeamRating
.2
	move.w	#2,d1
	jsr	(PushNumberWidth).l
.3
	jsr	(printsmall).l
	movem.l	(sp)+,d0-d7/a0-a6
.x
	rts
PrintCardTeam	;Player card: the city and nickname of the card's team (GetCardTeam cardvis), each centred (PrintCentered) on rows d1 and d1 + 1
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	d1,(printy).w
	movea.l	#tmstruct,a0
	tst.w	(cardvis).w
	beq.w	.0
	movea.l	#AwShots,a0
.0
	movea.l	$1E(a0),a0
	adda.w	4(a0),a0
.1
	bsr.w	PrintCentered
	adda.w	(a0),a0
	adda.w	(a0),a0
	addq.w	#1,(printy).w
	bsr.w	PrintCentered
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintCentered	;printsmall String a0 centred on column $14
	move.w	#$14,(printx).w
	move.w	(a0),d0
	subq.w	#2,d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	movea.l	a0,a1
	jmp	printsmall
GetJerseyString	;Player d0 of the card's team: his jersey number as a 2 digit String at a1 (space for a leading 0)
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#tmstruct,a0
	tst.w	(cardvis).w
	beq.w	.0
	movea.l	#AwShots,a0
.0
	movea.l	$1E(a0),a0
	move.w	(a0),d1
	ext.l	d1
	adda.l	d1,a0
.loop
	move.w	(a0),d1
	ext.l	d1
	adda.l	d1,a0
	addq.l	#8,a0
	dbf	d0,.loop
	subq.l	#8,a0
	move.w	#4,(a1)+
	move.b	(a0),d0
	lsr.w	#4,d0
	andi.w	#$F,d0
	bne.w	.1
	move.b	#$20,d0
	bra.w	.2
.1
	addi.b	#$30,d0
.2
	move.b	d0,(a1)+
	move.b	(a0),d0
	andi.w	#$F,d0
	addi.b	#$30,d0
	move.b	d0,(a1)+
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintGoalsAssists	;Player card "Goals" / "Assists" (GetCardTeam)
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	GetCardTeam
	move.l	a0,-(sp)
	adda.l	#$B4,a0
	move.b	0(a0,d0.w),d3
	ext.w	d3
	movea.l	(sp)+,a0
	adda.l	#$CE,a0
	move.b	0(a0,d0.w),d4
	ext.w	d4
	move.w	d1,(printx).w
	move.w	d2,(printy).w
	move.w	d1,-(sp)
	jsr	(printsmallz).l
	String	'Goals    '
	move.w	d0,-(sp)
	move.w	d3,d0
	movea.l	#mesarea,a1
	bsr.w	AppendNumber
	move.w	(sp)+,d0
	movea.l	#mesarea,a1
	jsr	(printsmall).l
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	jsr	(printsmallz).l
	String	'Assists  '
	move.w	d4,d0
	movea.l	#mesarea,a1
	bsr.w	AppendNumber
	movea.l	#mesarea,a1
	jsr	(printsmall).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintSaves	;Player card "Saves" / "Save %" (GetCardTeam)
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	GetCardTeam
	move.l	a0,-(sp)
	adda.l	#$B4,a0
.0
	move.b	0(a0,d0.w),d3
	ext.w	d3
	movea.l	(sp)+,a0
	adda.l	#$E8,a0
	move.b	0(a0,d0.w),d4
	ext.w	d4
	move.w	d4,d7
	sub.w	d3,d7
	move.w	d1,(printx).w
	move.w	d2,(printy).w
	move.w	d1,-(sp)
	jsr	(printsmallz).l
	String	'Saves    '
	move.w	d7,d0
	movea.l	#mesarea,a1
	move.l	a1,-(sp)
	bsr.w	AppendNumber
	movea.l	(sp)+,a1
	jsr	(printsmall).l
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	jsr	(printsmallz).l
	String	'Save %   '
	move.w	d7,d0
	mulu.w	#$64,d0
	tst.w	d4
	bne.w	.1
	clr.w	d0
	bra.w	.2
.1
	divu.w	d4,d0
.2
	movea.l	#mesarea,a1
	move.l	a1,-(sp)
	bsr.w	AppendNumber
	movea.l	(sp)+,a1
	jsr	(printsmall).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
DrawPlayerPicture	;Draw the player picture (NoPicSkater1 ... NoPicGoalie2, Card<player>)
	movem.l	d0-d7/a1-a6,-(sp)
	movea.l	#FeaturedPictures,a0
	move.w	d1,d2
	asl.w	#2,d2
	movea.l	0(a0,d2.w),a0
	move.w	#$FFFF,d2
	bra.w	.1
.loop
	cmp.w	4(a0),d0
	bne.w	.0
	movea.l	(a0),a0
	bra.w	.x
.0
	addq.l	#6,a0
.1
	addq.w	#1,d2
	tst.l	(a0)
	bne.s	.loop
	movea.l	#$30E,a0
	asl.w	#2,d1
	movea.l	0(a0,d1.w),a0
	movea.l	a0,a6
	move.w	d0,d6
	adda.w	(a6),a6
	bra.w	.2
.loop2
	adda.w	(a6),a6
	addq.w	#8,a6
.2
	dbf	d6,.loop2
	adda.w	(a6),a6
	adda.w	$A(a0),a0
	move.w	(a0),d1
	clr.w	d3
.loop3
	addq.w	#1,d3
	asl.w	#4,d1
	bne.s	.loop3
	movea.l	#NoPicGoalie1,a0
	btst	#0,4(a6)
	bne.w	.3
	movea.l	#NoPicGoalie2,a0
.3
	cmp.w	d3,d0
	blt.w	.x
	movea.l	#NoPicSkater2,a0
	btst	#0,4(a6)
	bne.w	.x
	movea.l	#NoPicSkater1,a0
.x
	movem.l	(sp)+,d0-d7/a1-a6
	rts
DrawPictureBox	;Player card picture box (DrawPlayerPicture, UnpackPicture)
	movem.l	d0-d7/a0-a6,-(sp)
	bsr.w	GetCardPlayer
	move.w	(HomeTeam).w,d1
	tst.w	(cardvis).w
	beq.w	.0
	move.w	(VisTeam).w,d1
.0
	bsr.w	DrawPlayerPicture
	jsr	(printz).l
	String	-(TXPRI+TXPAL3+TXMAP2),1,8
	move.w	(cardlogochars2).w,d4
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	movea.l	#PicturePalette,a0
	adda.l	(a0),a0
	tst.l	(a2)
	bne.w	.1
	movea.l	#PicturePalette,a1
	adda.l	4(a1),a1
	tst.l	(a2)+
	bra.w	.2
.1
	adda.l	(a2)+,a1
.2
	bsr.w	UnpackPicture
	movea.l	#picturebuf,a2
	move.w	#6,d3
	move.w	#6,d2
	clr.w	d0
	clr.w	d1
	movem.l	d0/a0-a1,-(sp)
	adda.w	#$20,a0
	movea.l	#palfadenew+$40,a1
	move.w	#7,d0
.loop
	move.l	(a0)+,(a1)+
	dbf	d0,.loop
	movem.l	(sp)+,d0/a0-a1
	move.w	#0,d5
	jsr	(dobitmap).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
GetCardTeam	;a0 = HmShots, or AwShots when cardvis is set (the card's team)
	movea.l	#tmstruct,a0
	tst.w	(cardvis).w
	beq.w	.x
	movea.l	#AwShots,a0
.x
	rts
TrimSpaces	;Trim the trailing spaces of String a2 and pad it to an even length
	movem.l	a3,-(sp)
	movea.l	a2,a3
	adda.w	(a2),a3
.loop
	move.b	-(a3),d0
	cmp.b	#$20,d0
	bne.w	.0
	move.b	#0,(a3)
	subq.w	#1,(a2)
	bra.s	.loop
.0
	addq.w	#1,(a2)
	andi.w	#$FE,(a2)
	movem.l	(sp)+,a3
	rts
GetCardPlayer	;cardplayer = the roster index of card cardindex from the card's team list (homecardlist, awaycardlist)
	movem.l	d1/a0,-(sp)
	movea.l	#homecardlist,a0
	tst.w	(cardvis).w
	beq.w	.0
	movea.l	#awaycardlist,a0
.0
	move.w	(cardindex).w,d1
	subq.w	#1,d1
	move.b	0(a0,d1.w),d0
	ext.w	d0
	move.w	d0,(cardplayer).w
	movem.l	(sp)+,d1/a0
	rts
BuildCardPlayerLists	;Build the player card order of both teams: home at homecardlist, away at awaycardlist
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#homecardlist,a1
	movea.l	#tmstruct,a0
	bsr.w	BuildCardPlayerList
	movea.l	#awaycardlist,a1
	movea.l	#AwShots,a0
	bsr.w	BuildCardPlayerList
	movem.l	(sp)+,d0-d7/a0-a6
	rts
BuildCardPlayerList	;Player card order of team a0 into a1: the 6 starters (TeamList line at +6) first, the other players of the 26 after them
	movea.l	$1E(a0),a0
	adda.w	6(a0),a0
	movea.l	a1,a2
	addq.w	#6,a2
	clr.w	d0
.loop
	move.w	#5,d1
.loop2
	move.b	0(a0,d1.w),d3
	subq.b	#1,d3
	cmp.b	d3,d0
	beq.w	.0
	dbf	d1,.loop2
	move.b	d0,(a2)+
	bra.w	.1
.0
	move.b	d0,(a1)+
.1
	addq.w	#1,d0
	cmp.w	#$1A,d0
	blt.s	.loop
	rts
NameEntryScreen	;"NAME ENTRY" screen for the user records (own vblank VBlank_SetOptions): pick a name from the name log or enter a new one (NameLetterGrid ...
	;SkipOtherUserName). Called from UserNameEntry
	movem.l	d0-d7/a0-a6,-(sp)
	move	#$2700,sr
	move.w	#2,d4
	move.l	#VBlank_SetOptions,(vbint).w
	bclr	#0,(disflags).w
	bset	#2,(disflags).w
	bclr	#1,(disflags).w
	move.w	#0,(VSCRLPM).w
	move.w	#$B400,(VSPRITES).w
	move.w	#$B800,(VmMap3).w
	move.w	#5,(Map3col1).w
	move.w	#$C000,(VmMap2).w
	move.w	#6,(Map2col1).w
	move.w	#$E000,(VmMap1).w
	move.w	#6,(Map1col1).w
	move.w	#0,d0
	jsr	(setvram).l
	move	#$2500,sr
	jsr	(orjoy).l
	move.w	d4,(framercset).w
	movea.l	#framermap+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$91234567,$89ABCDEF	;remap table
	move.w	d4,(nameframechars).w
	movea.l	#framermap+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$91234560,$89ABCDEF	;remap table
	move.w	d4,(smallfontchars).w
	jsr	(AddSmallFont).l
	jsr	(printz).l
	String	-TXMAP1,0,0
	moveq	#$28,d0
	moveq	#$1C,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	jsr	(setupIceRinkMap).l
	jsr	(printz).l
	String	-TXMAP2,0,0
	movea.l	#ScoutMap,a0	;(and printz Strings)
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	adda.l	(a2)+,a1
	clr.w	d0
	clr.w	d1
	moveq	#$28,d2
	moveq	#$1C,d3
	moveq	#$D,d5
	jsr	(dobitmap).l
	move.w	d4,(homepicchars).w
	addi.w	#$24,d4
	move.w	d4,(logobox1chars).w
	movea.l	#LogoBoxMap+8,a2
	jsr	(DoDMA_clearCallbackPointer).l
	move.w	d4,(BigFontChars).w
	movea.l	#BigFontMap+8,a2
	jsr	(DecompressGraphicsWithCallback).l
	dc.l	$71234567,$89ABCDEF	;remap table
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$1F,6
	move.w	(HomeTeam).w,d0
	tst.w	(nameentryvis).w
	beq.w	.0
	move.w	(VisTeam).w,d0
.0
	movea.l	#$30E,a1	;TeamList
	asl.w	#2,d0
	movea.l	0(a1,d0.w),a1
	adda.w	4(a1),a1
	move.w	(a1),d0
	subq.w	#2,d0
	lsr.w	#1,d0
	sub.w	d0,(printx).w
	jsr	(print).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$1B,7
	move.w	#8,d0
	move.w	#8,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-(TXPRI+TXPAL3+TXMAP1),$1C,8
	move.w	(HomeTeam).w,d3
	tst.w	(nameentryvis).w
	beq.w	.1
	move.w	(VisTeam).w,d3
.1
	asl.w	#2,d3
	movea.l	#TeamLogoBitmaps,a0	;team logo maps
	movea.l	0(a0,d3.w),a0
	movea.l	a0,a1
	movea.l	a0,a2
	adda.l	(a2)+,a0
	asl.w	#3,d3
	movea.l	#TeamLogoPalettes,a0
	subi.w	#$40,d3
	adda.w	d3,a0
	adda.l	(a2)+,a1
	move.w	#6,d3
	move.w	#6,d2
	clr.w	d0
	clr.w	d1
	move.w	#4,d5
	move.w	(homepicchars).w,d4
	jsr	(dobitmap).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),2,0
	move.w	#$24,d0
	move.w	#6,d1
	jsr	(Framer).l
	jsr	(printbigz).l
	String	-(TXPRI+TXMAP1),$A,2,'NAME  ENTRY'
	bsr.w	ReadNameLog
	clr.w	(namelogarrows).w
	move.w	#1,(namelogsel).w
	clr.w	d0
	bsr.w	SkipOtherUserName
	movea.l	#nameentrybuf,a1
	bsr.w	GetLogName
	bsr.w	PrintNameLog
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),7,6,'Name Log'
	move.w	#$18,(palcount).w
	bclr	#2,(disflags).w
	clr.w	d4
	bsr.w	SyncLetterCursor
	bsr.w	PrintNameCursor
	bsr.w	LetterGridPos
.2
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	jsr	(NameEntryFramer).l
	move.w	(sp)+,(printy).w
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	addq.w	#1,(printx).w
	bsr.w	PrintCurLetter
	move.w	#1,(cursoron).w
	bsr.w	NameLetterGrid
	clr.w	d0
	bra.w	.11
.loop
	bsr.w	GetNameLength
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),5,$12
	tst.w	(cursoron).w
	beq.w	.3
	movea.l	#nameentrybuf,a1
	bsr.w	PrintNameField
	bsr.w	PrintNamePrompt
.3
	bsr.w	MoveLogArrows
.loop2
	move.w	(vcount).w,d0
.loop3
	cmp.w	(vcount).w,d0
	beq.s	.loop3
	movem.w	d1,-(sp)
	move.w	(cont1team).w,d1
	subq.w	#1,d1
	cmp.w	(nameentryvis).w,d1
	movem.w	(sp)+,d1
	beq.w	.4
	jsr	(ReadJoy2).l
	tst.w	d1
	beq.s	.loop2
	bra.w	.5
.4
	jsr	(ReadJoy1).l
	tst.w	d1
	beq.s	.loop2
.5
	btst	#7,d1
	bne.w	.14
	tst.w	(cursoron).w
	bne.w	.6
	move.w	#1,d0
	btst	#1,d1
	bne.w	.7
	move.w	#$FFFF,d0
	btst	#0,d1
	bne.w	.7
	btst	#4,d1
	beq.w	.loop
	bsr.w	NameLetterGrid
	clr.w	d0
	bra.w	.7
.6
	moveq	#-1,d0
	btst	#6,d1
	bne.w	.11
	neg.w	d0
	btst	#5,d1
	bne.w	.11
	btst	#3,d1
	bne.w	.12
	neg.w	d0
	btst	#2,d1
	bne.w	.12
	moveq	#6,d0
	btst	#1,d1
	bne.w	.12
	neg.w	d0
	btst	#0,d1
	bne.w	.12
	btst	#4,d1
	beq.w	.loop
	bsr.w	NameLetterGrid
	bra.w	.loop
.7
	add.w	d0,(namelogsel).w
.loop4
	cmpi.w	#7,(namelogsel).w
	ble.w	.8
	move.w	#1,(namelogsel).w
.8
	tst.w	(namelogsel).w
	bne.w	.9
	move.w	#7,(namelogsel).w
.9
	bsr.w	SkipOtherUserName
	beq.s	.loop4
	movea.l	#nameentrybuf,a1
	bsr.w	GetLogName
	tst.w	(cursoron).w
	bne.w	.10
	jsr	(NameEntryHelp).l
	bra.w	.loop
.10
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),4,$13
	add.w	d4,(printx).w
	jsr	(printz).l
	String	'   '
	bsr.w	LetterGridPos
	moveq	#1,d2
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	jsr	(eraser).l
	move.w	(sp)+,(printy).w
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	addq.w	#1,(printx).w
	bsr.w	PrintCurLetter
	bsr.w	SyncLetterCursor
	move.w	d4,d0
	neg.w	d0
	bra.w	*+4
.11
	add.w	d4,d0
	cmp.w	#$B,d0
	bhi.w	.loop
	move.w	d0,d4
	bsr.w	PrintNameCursor
	movea.l	#nameentrybuf,a0
	clr.w	d0
	cmpi.b	#$2D,0(a0,d4.w)
	beq.w	.12
	move.b	0(a0,d4.w),d0
	ext.w	d0
	bsr.w	FindLetter
	sub.w	d5,d0
.12
	add.w	d5,d0
	cmp.w	#$1D,d0
	bhi.w	.loop
	move.w	d0,-(sp)
	bsr.w	LetterGridPos
	moveq	#1,d2
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	jsr	(eraser).l
	move.w	(sp)+,(printy).w
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	addq.w	#1,(printx).w
	bsr.w	PrintCurLetter
	move.w	(sp)+,d5
	bsr.w	LetterGridPos
	move.w	(printx).w,-(sp)
	move.w	(printy).w,-(sp)
	tst.w	(cursoron).w
	beq.w	.13
	jsr	(NameEntryFramer).l
.13
	move.w	(sp)+,(printy).w
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	addq.w	#1,(printx).w
	bsr.w	PrintCurLetter
	movea.l	#nameentrybuf,a0
	movea.l	#LetterGrid,a1
	move.b	0(a1,d5.w),d0
	move.b	d0,0(a0,d4.w)
	bra.w	.loop
.14
	bsr.w	StoreUserName
	movem.l	(sp)+,d0-d7/a0-a6
	rts
NameLetterGrid	;Name entry: the letter grid ("D-Pad to a letter.", "C to select letter.", "A to go back.")
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),1,$14
	move.w	#$16,d0
	move.w	#7,d1
	move.w	#$7FF,d2
	jsr	(eraser).l
	bchg	#0,(cursoron+1).w
	bne.w	.1
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$19,$11
	movea.l	#LetterGrid,a0
	moveq	#4,d0
.loop
	moveq	#5,d1
	movea.l	#mesarea,a1
	move.w	#$E,(a1)+
.loop2
	move.b	(a0)+,(a1)+
	move.b	#$20,(a1)+
	dbf	d1,.loop2
	movea.w	#(mesarea-M68K_RAM),a1
	jsr	(print).l
	addq.w	#2,(printy).w
	subi.w	#$C,(printx).w
	dbf	d0,.loop
	jsr	(printz).l
	String	-TXMAP2,1,$14
	moveq	#$16,d0
	moveq	#7,d1
	jsr	(Framer).l
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),2,$15,'D-Pad to a letter.'
	move.w	#2,(printx).w
	addq.w	#1,(printy).w
	move.w	(printx).w,-(sp)
	jsr	(printz).l
	String	'C to select letter.'
	move.w	(sp),(printx).w
	addq.w	#1,(printy).w
	jsr	(printz).l
	String	'A to go back.'
	move.w	(sp),(printx).w
	addq.w	#1,(printy).w
	jsr	(printz).l
	String	'B to cancel.'
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
.0
	jsr	(printz).l
	String	'START when done.'
.x
	movem.l	(sp)+,d0-d7/a0-a6
.x2
	rts
.1
	movea.l	#nameentrybuf,a1
.2
	bsr.w	GetLogName
	move.w	#0,(printx).w
.3
	move.w	#$F,(printy).w
	move.w	#$28,d0
.4
	move.w	#$D,d1
	move.w	#$7FF,d2
.5
	jsr	(eraser).l
.6
	jsr	(printz).l
	String	-TXMAP2,1,$14
	moveq	#$16,d0
	moveq	#7,d1
.7
	jsr	(Framer).l
	bsr.w	NameEntryHelp
	bra.s	.x
NameEntryHelp	;Name entry help text ("D-Pad up/down to move arrows.", "Press START to select name.", "Press B to edit.")
	movem.l	d0-d7/a0-a6,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),2,$15,'D-Pad up/down to    '
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),2,$16,'move arrows.        '
	move.w	#2,(printx).w
	move.w	(printx).w,-(sp)
	addq.w	#1,(printy).w
	jsr	(printz).l
	String	'Press START to      '
	addq.w	#1,(printy).w
	move.w	(sp),(printx).w
	jsr	(printz).l
	String	'select name.        '
	addq.w	#1,(printy).w
	move.w	(sp)+,(printx).w
	jsr	(printz).l
	String	'Press B to edit.    '
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintNamePrompt	;Name entry: "Enter new name:" for an empty name log slot namelogsel, else "Select or replace:"
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(namelogsel).w,d0
	mulu.w	#$C,d0
	movea.l	#namelog,a0
	movea.l	#EnterNameTxt,a1
	tst.b	0(a0,d0.w)
	beq.w	.0
	movea.l	#SelectNameTxt,a1
.0
	jsr	(print).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
SyncLetterCursor	;Name entry: the letter grid cursor d5 = the grid index of the current letter (FindLetter), 0 when it is not in the grid
	movem.l	d0-d4/a0-a6,-(sp)
	move.b	(nameentrybuf).w,d0
	bsr.w	FindLetter
	cmp.w	#$1E,d0
	blt.w	.0
	clr.w	d5
	bra.w	.x
.0
	move.w	d0,d5
	movea.l	#LetterGrid,a0
	move.b	0(a0,d5.w),(nameentrybuf).w
.x
	movem.l	(sp)+,d0-d4/a0-a6
	rts
FindLetter	;d0 = index of letter d0 in LetterGrid, $1E when not found
	movem.l	d1-d3/a0-a6,-(sp)
	movea.l	#LetterGrid,a0
	move.b	d0,d1
	clr.w	d0
	move.w	#$1E,d3
.loop
	cmp.b	0(a0,d0.w),d1
	beq.w	.x
	addq.w	#1,d0
	dbf	d3,.loop
	move.w	#$1E,d0
.x
	movem.l	(sp)+,d1-d3/a0-a6
	rts
PrintNameCursor	;Name entry: the " < " cursor
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),4,$13
	add.w	d4,(printx).w
	tst.w	(cursoron).w
	beq.w	rtsNameCursor
	jsr	(printz).l
	String	' < '
rtsNameCursor	;The shared rts of PrintNameCursor
	rts
PrintCurLetter	;Name entry: print grid letter d5 (with the cursor on, cursoron)
	tst.w	(cursoron).w
	beq.s	rtsNameCursor
	movea.l	#ThreeStars,a1
	move.w	#4,(a1)
	move.b	#0,3(a1)
	movea.l	#LetterGrid,a0
	move.b	0(a0,d5.w),d0
	move.b	d0,2(a1)
	jmp	print
LetterGridPos	;Name entry: printx / printy of grid letter d5 (6 letters a row, 2 cells apart); d0 / d1 = 3 x 3 box
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),$18,$10
	move.w	d5,d0
	ext.l	d0
	divu.w	#6,d0
	asl.w	#1,d0
	add.w	d0,(printy).w
	swap	d0
	asl.w	#1,d0
	add.w	d0,(printx).w
	moveq	#3,d0
	moveq	#3,d1
	rts
EnterNameTxt	dc.b	0	;PrintNamePrompt table
	dc.b	$18,$BF,2,$10,$20,$20
	dc.b	$45	;E
	dc.b	$6E	;n
	dc.b	$74	;t
	dc.b	$65	;e
	dc.b	$72	;r
	dc.b	$20
	dc.b	$6E	;n
	dc.b	$65	;e
	dc.b	$77	;w
	dc.b	$20
	dc.b	$6E	;n
	dc.b	$61	;a
	dc.b	$6D	;m
	dc.b	$65	;e
	dc.b	$3A	;:
	dc.b	$20,0
SelectNameTxt	dc.b	0	;PrintNamePrompt table
	dc.b	$18,$BF,2,$10
	dc.b	$53	;S
	dc.b	$65	;e
	dc.b	$6C	;l
	dc.b	$65	;e
	dc.b	$63	;c
	dc.b	$74	;t
	dc.b	$20
	dc.b	$6F	;o
	dc.b	$72	;r
	dc.b	$20
	dc.b	$72	;r
	dc.b	$65	;e
	dc.b	$70	;p
	dc.b	$6C	;l
	dc.b	$61	;a
	dc.b	$63	;c
	dc.b	$65	;e
	dc.b	$3A	;:
	dc.b	0
PrintNameLog	;Name entry: the "Name Log" list (PrintNameField, GetLogName)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(namelength).w,-(sp)
	move.w	(namelogsel).w,-(sp)
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),5,8
	move.w	#6,d7
	move.w	#1,(namelogsel).w
	movea.l	#TempBuffer,a1
.loop
	bsr.w	GetLogName
	move.w	(printx).w,-(sp)
	bsr.w	PrintNameField
	move.w	(sp)+,(printx).w
	addq.w	#1,(printy).w
	addq.w	#1,(namelogsel).w
	dbf	d7,.loop
	move.w	(sp)+,(namelogsel).w
	move.w	(sp)+,(namelength).w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
MoveLogArrows	;Name entry: when the name log selection namelogsel changed, erase the old ] [ arrows and print them at the new row (PrintLogArrows)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	(namelogsel).w,d0
	cmp.w	(namelogarrows).w,d0
	beq.w	.x
	movea.l	#LogArrowsClrTxt,a1
	bsr.w	PrintLogArrows
	movea.l	#LogArrowsTxt,a1
	bsr.w	PrintLogArrows
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintLogArrows	;Name entry: print the two arrow Strings at a1 on name log row namelogarrows, then namelogarrows = namelogsel
	tst.w	(namelogarrows).w
	beq.w	.0
	jsr	(printz).l
	String	-(TXPRI+TXMAP1),3,8
	move.w	(namelogarrows).w,d0
	subq.w	#1,d0
	add.w	d0,(printy).w
	move.l	a1,-(sp)
	jsr	(print).l
	movea.l	(sp)+,a1
	adda.w	(a1),a1
	move.w	#$12,(printx).w
	jsr	(print).l
.0
	move.w	(namelogsel).w,(namelogarrows).w
	rts
LogArrowsTxt	dc.b	0	;MoveLogArrows data
	dc.b	4
	dc.b	$5D	;]
	dc.b	0,0,4
	dc.b	$5B	;[
	dc.b	0
LogArrowsClrTxt	dc.b	0	;MoveLogArrows data
	dc.b	4,$20,0,0,4,$20,0
GetNameLength	;namelength = length of the name being entered (up to '-' or 0, at most 12)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#$B,d3
	movea.l	#nameentrybuf,a0
	clr.w	(namelength).w
.loop
	cmpi.b	#$2D,(a0)
	beq.w	.x
	tst.b	(a0)+
	beq.w	.x
	addq.w	#1,(namelength).w
	dbf	d3,.loop
.x
	movem.l	(sp)+,d0-d7/a0-a6
	rts
PrintNameField	;Name entry: print the 12 character name field from a1, '-' past the length namelength
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#ThreeStars,a0
	move.w	(namelength).w,d0
	move.w	#0,d3
	move.w	#$E,(a0)+
.loop
	move.b	0(a1,d3.w),d1
	cmp.w	(namelength).w,d3
	blt.w	.0
	move.b	#$2D,d1
.0
	move.b	d1,(a0)+
	addq.w	#1,d3
	cmp.w	#$C,d3
	blt.s	.loop
	movea.l	#ThreeStars,a1
	jsr	(print).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
LetterGrid	dc.b	$41	;Name entry data
	dc.b	$42	;B
	dc.b	$43	;C
	dc.b	$44	;D
	dc.b	$45	;E
	dc.b	$46	;F
	dc.b	$47	;G
	dc.b	$48	;H
	dc.b	$49	;I
	dc.b	$4A	;J
	dc.b	$4B	;K
	dc.b	$4C	;L
	dc.b	$4D	;M
	dc.b	$4E	;N
	dc.b	$4F	;O
	dc.b	$50	;P
	dc.b	$51	;Q
	dc.b	$52	;R
	dc.b	$53	;S
	dc.b	$54	;T
	dc.b	$55	;U
	dc.b	$56	;V
	dc.b	$57	;W
	dc.b	$58	;X
	dc.b	$59	;Y
	dc.b	$5A	;Z
	dc.b	$2E
	dc.b	$31	;1
	dc.b	$32	;2
	dc.b	$20
	dc.b	$2D	;-
	dc.b	0
NameEntryFramer	;Framer with the name entry frame tiles (nameframechars as framercset)
	move.w	(framercset).w,-(sp)
	move.w	(nameframechars).w,(framercset).w
	jsr	(Framer).l
	move.w	(sp)+,(framercset).w
	rts
GetLogName	;Copy name log entry namelogsel to a1 ('-' for empty), namelength = its length
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#namelog,a0
	move.w	(namelogsel).w,d2
	mulu.w	#$C,d2
	move.w	#0,(namelength).w
	move.w	#$B,d3
.loop
	move.b	0(a0,d2.w),d0
	beq.w	.0
	bra.w	.1
.0
	move.b	#$2D,d0
	subq.w	#1,(namelength).w
.1
	move.b	d0,(a1)+
	addq.w	#1,(namelength).w
	addq.w	#1,d2
	dbf	d3,.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts
StoreUserName	;Name entry: store the name in save RAM (WriteNameRecord, MakeSRAMChecksum)
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	#namelog,a0
	move.w	(namelogsel).w,d0
	mulu.w	#$C,d0
	adda.w	d0,a0
	movea.l	#nameentrybuf,a1
	move.w	#$B,d4
.loop
	cmpi.b	#$2D,(a1)
	bne.w	.0
	move.b	#0,(a1)
.0
	move.b	(a1)+,d1
	cmp.b	(a0)+,d1
	bne.w	.1
	dbf	d4,.loop
	bra.w	.3
.1
	movea.l	#namelog,a0
	move.w	(namelogsel).w,d0
	mulu.w	#$C,d0
	adda.w	d0,a0
	movea.l	#nameentrybuf,a1
	move.w	#$B,d4
.loop2
	move.b	(a1)+,d1
	cmp.b	#$2D,d1
	bne.w	.2
	move.b	#0,d1
.2
	move.b	d1,(a0)+
	dbf	d4,.loop2
	bsr.w	WriteNameLog
	jsr	(WriteNameRecord).l
	jsr	(MakeSRAMChecksum).l
.3
	movea.l	#homeuser,a5
	tst.w	(nameentryvis).w
	beq.w	.4
	movea.l	#awayuser,a5
.4
	tst.b	(nameentrybuf).w
	bne.w	.5
	clr.w	(namelogsel).w
.5
	move.w	(namelogsel).w,(a5)
	movem.l	(sp)+,d0-d7/a0-a6
	rts
WriteNameRecord	;Write the name record (ReadSRAM / WriteSRAM)
	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#$2D7,d7
	moveq	#0,d0
	moveq	#4,d1
	movea.l	#ThreeStars,a0
	move.w	(namelogsel).w,d6
.loop
	clr.w	d5
	jsr	(ReadSRAM).l
	cmp.b	1(a0),d6
	bne.w	.0
	clr.b	1(a0)
	st	d5
.0
	cmp.b	3(a0),d6
	bne.w	.1
	clr.b	3(a0)
	st	d5
.1
	tst.w	d5
	beq.w	.2
	jsr	(WriteSRAM).l
.2
	addq.l	#4,d0
	dbf	d7,.loop
	move.w	#$1B,d7
	move.l	#$B60,d0
	moveq	#$10,d1
	movea.l	#ThreeStars,a0
	move.w	(namelogsel).w,d6
.loop2
	clr.w	d5
	jsr	(ReadSRAM).l
	cmp.b	1(a0),d6
	bne.w	.3
	clr.b	1(a0)
	st	d5
.3
	cmp.b	3(a0),d6
	bne.w	.4
	clr.b	3(a0)
	st	d5
.4
	cmp.b	5(a0),d6
	bne.w	.5
	clr.b	5(a0)
	st	d5
.5
	cmp.b	7(a0),d6
	bne.w	.6
	clr.b	7(a0)
	st	d5
.6
	cmp.b	9(a0),d6
	bne.w	.7
	clr.b	9(a0)
	st	d5
.7
	cmp.b	$B(a0),d6
	bne.w	.8
	clr.b	$B(a0)
	st	d5
.8
	tst.w	d5
	beq.w	.9
	jsr	(WriteSRAM).l
.9
	addi.l	#$10,d0
	dbf	d7,.loop2
	move.l	#$D20,d0
	move.w	(namelogsel).w,d3
	asl.w	#4,d3
	ext.l	d3
	add.l	d3,d0
	moveq	#$10,d1
	movea.l	#ThreeStars,a0
	jsr	(ReadSRAM).l
	move.l	a0,-(sp)
	move.w	#$F,d3
.loop3
	clr.b	(a0)+
	dbf	d3,.loop3
	movea.l	(sp)+,a0
	jsr	(WriteSRAM).l
	jsr	(MakeSRAMChecksum).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
