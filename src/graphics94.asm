;	Graphics and text data, all loaded from the extracted files: the rink, sprites, fonts, screen
;	maps, pictures and one file per player card, in roster order.

ScoutTextScript						;the script ScoutTextPlayer types out word by word on the ScoutingReport
									;(MATCHUPS) screen
	incbin	..\Extracted\NHL94\Text\ScoutTextScript.bin
	even
GameSetUpMap						;the game setup screen bitmap, 40 x 28
	incbin	..\Extracted\NHL94\Graphics\GameSetUp94-1.map.jim
	even
GameSetUpMap2						;the second game setup bitmap
	incbin	..\Extracted\NHL94\Graphics\GameSetUp94-2.map.jim
	even
TitleScreenImg						;the newTitleScreen backdrop (high ROM)
	incbin	..\Extracted\NHL94\Graphics\Title94-1.map.jim
	even
NHLShieldImg						;the NHL shield on newTitleScreen
	incbin	..\Extracted\NHL94\Graphics\Title94-2.map.jim
	even
PAlogoImg							;the NHLPA logo on newTitleScreen
	incbin	..\Extracted\NHL94\Graphics\Title94-3.map.jim
	even
TitleImg							;the title on newTitleScreen
	incbin	..\Extracted\NHL94\Graphics\Title94-4.map.jim
	even
ScoutMap							;the ScoutingReport and PlayoffScreen background
	incbin	..\Extracted\NHL94\Graphics\Scouting94.map.jim
	even
FramerMap							;Framer
	incbin	..\Extracted\NHL94\Graphics\Framer.map.jim
	even
;FramerMap+8: the framer tiles (AddFramer, ScoutingReport)
FaceOffMap							;: puckfaceoff2
	incbin	..\Extracted\NHL94\Graphics\FaceOff.map.jim
	even
;FaceOffMap+8: the tiles (puckfaceoff2, ReloadFaceOffMap)
Rinktilelist						;the ice rink (updatescroll, setupIceRinkPal,
									;ShowReplayIcon, ShowThreeStars, crash)
	incbin	..\Extracted\NHL94\Graphics\IceRink94.map.jim
	even
Rinktiles	equ	Rinktilelist+8		;the rink tiles (setupice, ClrHor)
RefsMap								;: the ref (PushRef)
	incbin	..\Extracted\NHL94\Graphics\Refs.map.jim
	even
;RefsMap+8: the tiles (puckpenshot, Endfaceoff, StartHL2, ReloadRefTiles)
RefMap2								;the horizontal ref (PushRef)
	incbin	..\Extracted\NHL94\Graphics\Refs2.map.jim
	even
;RefMap2+8: the tiles (chkprogress, ReloadRefHorTiles)
Sprites								;the sprite header (addframe2): long offsets from here (to
	incbin	..\Extracted\NHL94\Graphics\Sprites.bin
	even
Spritetiles							;the sprite tiles (+$A; addframe2 adds the frame tile offset to
									;#Spritetiles)
	incbin	..\Extracted\NHL94\Graphics\Spritetiles.bin
	even
frameSprData
	incbin	..\Extracted\NHL94\Graphics\frameSprData.bin
	even
HotList								;the hot spot byte pair of each frame
	incbin	..\Extracted\NHL94\Graphics\HotList.bin
	even
CrowdFrameList						;showcrowd
	incbin	..\Extracted\NHL94\Graphics\Crowd.anim
	even
;CrowdFrameList+8: the tiles (setupice, ReloadCrowdTiles)
FaceOffSprites						;same size: checkfo
	incbin	..\Extracted\NHL94\Graphics\FaceOff.anim
	even
;FaceOffSprites+8: the tiles (puckfaceoff2, ReloadFaceOffTiles)
ZamFrameList						;showzam
	incbin	..\Extracted\NHL94\Graphics\Zam.anim
	even
;ZamFrameList+8: the tiles (Intermission)
BigFontMap							;the big font (PrintBigChar)
	incbin	..\Extracted\NHL94\Graphics\BigFont94.map.jim
	even
;BigFontMap+8: the tiles (setupice, ScoutingReport, BuildCardPlayerList)
SmallFontMap						;same size: the small font (print, printsmall,
									;showclock, RenderSmallFontChar)
	incbin	..\Extracted\NHL94\Graphics\SmallFont.map.jim
	even
;SmallFontMap+8: the tiles (AddSmallFont, setupice, ScoutingReport, setoptions)
EnergyBarMap						;same size: the line energy bar frames (linebar)
	incbin	..\Extracted\NHL94\Graphics\EnergyBar.map.jim
	even
;EnergyBarMap+8: the tiles (setupice, ReloadEnergyBarTiles)
Teamblocksmap						;the team blocks (setupTeamBlocksMap, DrawTeamBlocks, DrawTeamBlockBitmap)
	incbin	..\Extracted\NHL94\Graphics\TeamBlocks.map.jim
	even
;Teamblocksmap+8: the tiles (AddTeamBlock)
TeamBitmaps							;dobitmap entries (DrawTeamBitmap)
	incbin	..\Extracted\NHL94\Graphics\TeamBlocks94.map.jim
	even
	include	..\output\teamcounts.inc
	IF TeamblocksEntries<>NumTeams
		inform	3,"Teamblocksmap needs one entry per team"
	ENDIF
	IF TeamBitmapsEntries<>NumTeams
		inform	3,"TeamBitmaps needs one entry per team"
	ENDIF
;TeamBitmaps+8: the tiles (LoadSetupTiles)
EASNmap								;the EASN logo (EASNLogo)
	incbin	..\Extracted\NHL94\Graphics\EASN.map.jim
	even
;EASNmap+8: the tiles (setupEASNmap)
Arrowsmap							;same size: the playoff tree arrows (DrawTreeArrow)
	incbin	..\Extracted\NHL94\Graphics\Arrows.map.jim
	even
;Arrowsmap+8: the tiles (PlayoffScreen)
RonBarrMap							;same size: the Ron Barr picture (ScoutingReport). The old
									;RonBarrCompressed.map.jim ran 4 bytes into ScoresMap
	incbin	..\Extracted\NHL94\Graphics\RonBarr.map.jim
	even
ScoresMap							;same size
	incbin	..\Extracted\NHL94\Graphics\Scores.map.jim
	even
EASportsMap							;the EA Sports screen map
	incbin	..\Extracted\NHL94\Graphics\EASportsMap.bin
	even
RevRinkTilelist						;the reversed ice rink (updatescroll, ShowReplayIcon)
	incbin	..\Extracted\NHL94\Graphics\IceRink94Reverse.map.jim
	even
RevRinkTiles	equ	RevRinkTilelist+8	;the tiles (setupice)
ReplayMap							;the replay map ShowReplayBanner shows at 0,0 (16 x 11)
	incbin	..\Extracted\NHL94\Graphics\ReplayOptions.map.jim
	even
;ReplayMap+8: the tiles (ReplayMode)
HorRinkMap							;SetHor
	incbin	..\Extracted\NHL94\Graphics\PauseScreen.map.jim
	even
HorRinkTiles	equ	HorRinkMap+8	;the tiles (SetHor)
PrintFont2Map						;the second print font (print, printsmall)
	incbin	..\Extracted\NHL94\Graphics\SmallFont94.map.jim
	even
;PrintFont2Map+8: the tiles (setoptions: the setup screen font)
SetupMenuMap						;the setoptions menu background (setoptions, MoveMenuFrame)
	incbin	..\Extracted\NHL94\Graphics\GameSetupBkgd1.map.jim
	even
SetupFramerMap						;the setoptions framer
	incbin	..\Extracted\NHL94\Graphics\GameSetupBkgd2.map.jim
	even
;SetupFramerMap+8: the framer tiles (setoptions)
LogoBoxMap							;the logo box (DrawLogoBox, LogoBoxRight)
	incbin	..\Extracted\NHL94\Graphics\GameSetupLogoBorder.map.jim
	even
;LogoBoxMap+8: the tiles (setoptions, BuildCardPlayerList)
logoANH								;the ANH logo, team 0 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoANA.map.jim
	even
logoBOS								;the BOS logo, team 1 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoBOS.map.jim
	even
logoBUF								;the BUF logo, team 2 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoBUF.map.jim
	even
logoCGY								;the CGY logo, team 3 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoCGY.map.jim
	even
logoCHI								;the CHI logo, team 4 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoCHI.map.jim
	even
logoDET								;the DET logo, team 6 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoDET.map.jim
	even
logoEDM								;the EDM logo, team 7 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoEDM.map.jim
	even
logoFLA								;the FLA logo, team 8 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoFLA.map.jim
	even
logoHFD								;the HFD logo, team 9 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoHFD.map.jim
	even
logoNYI								;the NYI logo, team 13 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoNYI.map.jim
	even
logoLA								;the LA logo, team 10 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoLA.map.jim
	even
logoDAL								;the DAL logo, team 5 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoDAL.map.jim
	even
logoMTL								;the MTL logo, team 11 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoMTL.map.jim
	even
logoNJ								;the NJ logo, team 12 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoNJ.map.jim
	even
logoNYR								;the NYR logo, team 14 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoNYR.map.jim
	even
logoOTW								;the OTW logo, team 15 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoOTW.map.jim
	even
logoPHI								;the PHI logo, team 16 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoPHI.map.jim
	even
logoPIT								;the PIT logo, team 17 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoPIT.map.jim
	even
logoQUE								;the QUE logo, team 18 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoQUE.map.jim
	even
logoSJ								;the SJ logo, team 19 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoSJ.map.jim
	even
logoSTL								;the STL logo, team 20 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoSTL.map.jim
	even
logoTB								;the TB logo, team 21 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoTB.map.jim
	even
logoTOR								;the TOR logo, team 22 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoTOR.map.jim
	even
logoVAN								;the VAN logo, team 23 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoVAN.map.jim
	even
logoWSH								;the WSH logo, team 24 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoWSH.map.jim
	even
logoWPG								;the WPG logo, team 25 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoWPG.map.jim
	even
logoASE								;the ASE logo, team 26 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoASE.map.jim
	even
logoASW								;the ASW logo, team 27 in TeamLogoBitmaps (DrawTeamLogo, GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoASW.map.jim
	even
PicturePalette						;the player picture palette, and the picture of a player with none
									;(DrawMatchupPicture, PlayerCardScreen)
	incbin	..\Extracted\NHL94\Graphics\PicturePalette.bin
	even
NoPicSkater1						;read by DrawPlayerPicture (high ROM)
	incbin	..\Extracted\NHL94\Graphics\NoPicSkater1.bin
	even
NoPicSkater2						;read by DrawPlayerPicture (high ROM)
	incbin	..\Extracted\NHL94\Graphics\NoPicSkater2.bin
	even
NoPicGoalie1						;read by DrawPlayerPicture (high ROM)
	incbin	..\Extracted\NHL94\Graphics\NoPicGoalie1.bin
	even
NoPicGoalie2						;the generic goalie card: DrawPlayerPicture uses it for a goalie with no
									;card whose hand rating (h) bit 0 is clear (NoPicGoalie1 when set). Also
									;listed for ANH 0 and FLA 0
	incbin	..\Extracted\NHL94\Graphics\NoPicGoalie2.bin
	even
CardAndyMoog						;Andy Moog player card (FeaturedPictures BOS 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAndyMoog.bin
	even
CardRayBourque						;Ray Bourque player card (FeaturedPictures BOS 17, ASE 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRayBourque.bin
	even
CardAdamOates						;Adam Oates player card (FeaturedPictures BOS 2, ASE 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAdamOates.bin
	even
CardDonSweeney						;Don Sweeney player card (FeaturedPictures BOS 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDonSweeney.bin
	even
CardJoeJuneau						;Joe Juneau player card (FeaturedPictures BOS 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJoeJuneau.bin
	even
CardCamNeely						;Cam Neely player card (FeaturedPictures BOS 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCamNeely.bin
	even
CardAlexnderMogilny					;Alexnder Mogilny player card (FeaturedPictures BUF 12, ASE 15)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlexnderMogilny.bin
	even
CardPatLaFontaine					;Pat LaFontaine player card (FeaturedPictures BUF 3, ASE 9)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPatLaFontaine.bin
	even
CardDaleHawerchuk					;Dale Hawerchuk player card (FeaturedPictures BUF 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaleHawerchuk.bin
	even
CardDougBodger						;Doug Bodger player card (FeaturedPictures BUF 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougBodger.bin
	even
CardGrantFuhr						;Grant Fuhr player card (FeaturedPictures BUF 0, ASE 1)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGrantFuhr.bin
	even
CardPetrSvoboda						;Petr Svoboda player card (FeaturedPictures BUF 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPetrSvoboda.bin
	even
CardMikeVernon						;Mike Vernon player card (FeaturedPictures CGY 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikeVernon.bin
	even
CardGaryRoberts						;Gary Roberts player card (FeaturedPictures CGY 6, ASW 9)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGaryRoberts.bin
	even
CardTheorenFleury					;Theoren Fleury player card (FeaturedPictures CGY 11, ASW 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTheorenFleury.bin
	even
CardGarySuter						;Gary Suter player card (FeaturedPictures CGY 15, ASW 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGarySuter.bin
	even
CardAlMacInnis						;Al MacInnis player card (FeaturedPictures CGY 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlMacInnis.bin
	even
CardJoeNieuwendyk					;Joe Nieuwendyk player card (FeaturedPictures CGY 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJoeNieuwendyk.bin
	even
CardEdBelfour						;Ed Belfour player card (FeaturedPictures CHI 0, ASW 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEdBelfour.bin
	even
CardJeremyRoenick					;Jeremy Roenick player card (FeaturedPictures CHI 2, ASW 5)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJeremyRoenick.bin
	even
CardSteveLarmer						;Steve Larmer player card (FeaturedPictures CHI 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveLarmer.bin
	even
CardChrisChelios					;Chris Chelios player card (FeaturedPictures CHI 17, ASW 20)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardChrisChelios.bin
	even
CardSteveSmith						;Steve Smith player card (FeaturedPictures CHI 18, ASW 23)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveSmith.bin
	even
CardMichelGoulet					;Michel Goulet player card (FeaturedPictures CHI 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMichelGoulet.bin
	even
CardTimCheveldae					;Tim Cheveldae player card (FeaturedPictures DET 0, ASW 1)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTimCheveldae.bin
	even
CardSteveYzerman					;Steve Yzerman player card (FeaturedPictures DET 2, ASW 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveYzerman.bin
	even
CardSergeiFedorov					;Sergei Fedorov player card (FeaturedPictures DET 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSergeiFedorov.bin
	even
CardPaulCoffey						;Paul Coffey player card (FeaturedPictures DET 17, ASW 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPaulCoffey.bin
	even
CardSteveChiasson					;Steve Chiasson player card (FeaturedPictures DET 18, ASW 24)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveChiasson.bin
	even
CardDinoCiccarelli					;Dino Ciccarelli player card (FeaturedPictures DET 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDinoCiccarelli.bin
	even
CardBillRanford						;Bill Ranford player card (FeaturedPictures EDM 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBillRanford.bin
	even
CardDaveManson						;Dave Manson player card (FeaturedPictures EDM 17, ASW 22)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaveManson.bin
	even
CardIgorKravchuk					;Igor Kravchuk player card (FeaturedPictures EDM 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardIgorKravchuk.bin
	even
CardShayneCorson					;Shayne Corson player card (FeaturedPictures EDM 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardShayneCorson.bin
	even
CardDougWeight						;Doug Weight player card (FeaturedPictures EDM 2). Own palette and tile
									;layout, header 0000033A 000003BA 0022
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougWeight.bin
	even
CardPetrKlima						;Petr Klima player card (FeaturedPictures EDM 14)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPetrKlima.bin
	even
CardSeanBurke						;Sean Burke player card (FeaturedPictures HFD 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSeanBurke.bin
	even
CardAndrewCassels					;Andrew Cassels player card (FeaturedPictures HFD 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAndrewCassels.bin
	even
CardGeoffSanderson					;Geoff Sanderson player card (FeaturedPictures HFD 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGeoffSanderson.bin
	even
CardPatVerbeek						;Pat Verbeek player card (FeaturedPictures HFD 13)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPatVerbeek.bin
	even
CardZarleyZalapski					;Zarley Zalapski player card (FeaturedPictures HFD 18, ASE 23)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardZarleyZalapski.bin
	even
CardEricWeinrich					;Eric Weinrich player card (FeaturedPictures HFD 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEricWeinrich.bin
	even
CardBenoitHogue						;Benoit Hogue player card (FeaturedPictures NYI 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBenoitHogue.bin
	even
CardSteveThomas						;Steve Thomas player card (FeaturedPictures NYI 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveThomas.bin
	even
CardPierreTurgeon					;Pierre Turgeon player card (FeaturedPictures NYI 2, ASE 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPierreTurgeon.bin
	even
CardGlennHealy						;Glenn Healy player card (FeaturedPictures NYI 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGlennHealy.bin
	even
CardDariusKasparitis				;Darius Kasparitis player card (FeaturedPictures NYI 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDariusKasparitis.bin
	even
CardVladimirMalakhov				;Vladimir Malakhov player card (FeaturedPictures NYI 17). Own palette and
									;tile layout, header 0000033A 000003BA 0022
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardVladimirMalakhov.bin
	even
CardKellyHrudey						;Kelly Hrudey player card (FeaturedPictures LA 0). Own palette and tile
									;layout, header 00000322 000003A2 0021
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKellyHrudey.bin
	even
CardWayneGretzky					;Wayne Gretzky player card (FeaturedPictures LA 3, ASW 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardWayneGretzky.bin
	even
CardLucRobitaille					;Luc Robitaille player card (FeaturedPictures LA 7, ASW 10)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardLucRobitaille.bin
	even
CardTomasSandstrom					;Tomas Sandstrom player card (FeaturedPictures LA 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTomasSandstrom.bin
	even
CardRobBlake						;Rob Blake player card (FeaturedPictures LA 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRobBlake.bin
	even
CardMartyMcSorley					;Marty McSorley player card (FeaturedPictures LA 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMartyMcSorley.bin
	even
CardJonCasey						;Jon Casey player card (FeaturedPictures DAL 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJonCasey.bin
	even
CardMikeModano						;Mike Modano player card (FeaturedPictures DAL 2, ASW 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikeModano.bin
	even
CardMarkTinordi						;Mark Tinordi player card (FeaturedPictures DAL 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMarkTinordi.bin
	even
CardTommySjodin						;Tommy Sjodin player card (FeaturedPictures DAL 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTommySjodin.bin
	even
CardDaveGagner						;Dave Gagner player card (FeaturedPictures DAL 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaveGagner.bin
	even
CardRussCourtnall					;Russ Courtnall player card (FeaturedPictures DAL 10)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRussCourtnall.bin
	even
CardPatrickRoy						;Patrick Roy player card (FeaturedPictures MTL 0, ASE 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPatrickRoy.bin
	even
CardEricDesjardins					;Eric Desjardins player card (FeaturedPictures MTL 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEricDesjardins.bin
	even
CardMattSchneider					;Matt Schneider player card (FeaturedPictures MTL 17). Own palette and
									;tile layout, header 0000030A 0000038A 0020
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMattSchneider.bin
	even
CardKirkMuller						;Kirk Muller player card (FeaturedPictures MTL 2, ASE 5)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKirkMuller.bin
	even
CardVincentDamphousse				;Vincent Damphousse player card (FeaturedPictures MTL 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardVincentDamphousse.bin
	even
CardBrianBellows					;Brian Bellows player card (FeaturedPictures MTL 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrianBellows.bin
	even
CardScottStevens					;Scott Stevens player card (FeaturedPictures NJ 17, ASE 22)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardScottStevens.bin
	even
CardChrisTerreri					;Chris Terreri player card (FeaturedPictures NJ 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardChrisTerreri.bin
	even
CardVachslavFetisov					;Vachslav Fetisov player card (FeaturedPictures NJ 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardVachslavFetisov.bin
	even
CardStephaneRicher					;Stephane Richer player card (FeaturedPictures NJ 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardStephaneRicher.bin
	even
CardAlexnderSemak					;Alexnder Semak player card (FeaturedPictures NJ 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlexnderSemak.bin
	even
CardClaudeLemieux					;Claude Lemieux player card (FeaturedPictures NJ 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardClaudeLemieux.bin
	even
CardJohnVanbiesbrk					;John Vanbiesbrk player card (FeaturedPictures NYR 0). Own palette and
									;tile layout, header 0000030A 0000038A 0020
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJohnVanbiesbrk.bin
	even
CardMarkMessier						;Mark Messier player card (FeaturedPictures NYR 2, ASE 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMarkMessier.bin
	even
CardJamesPatrick					;James Patrick player card (FeaturedPictures NYR 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJamesPatrick.bin
	even
CardMikeGartner						;Mike Gartner player card (FeaturedPictures NYR 11, ASE 13)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikeGartner.bin
	even
CardBrianLeetch						;Brian Leetch player card (FeaturedPictures NYR 17, ASE 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrianLeetch.bin
	even
CardEsaTikkanen						;Esa Tikkanen player card (FeaturedPictures NYR 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEsaTikkanen.bin
	even
CardPeterSidorkwicz					;Peter Sidorkwicz player card (FeaturedPictures OTW 0). Own palette and
									;tile layout, header 0000030A 0000038A 0020
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPeterSidorkwicz.bin
	even
CardSylvainTurgeon					;Sylvain Turgeon player card (FeaturedPictures OTW 9)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSylvainTurgeon.bin
	even
CardNormMaciver						;Norm Maciver player card (FeaturedPictures OTW 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardNormMaciver.bin
	even
CardBradShaw						;Brad Shaw player card (FeaturedPictures OTW 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBradShaw.bin
	even
CardJamieBaker						;Jamie Baker player card (FeaturedPictures OTW 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJamieBaker.bin
	even
CardBobKudelski						;Bob Kudelski player card (FeaturedPictures OTW 14)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBobKudelski.bin
	even
CardEricLindros						;Eric Lindros player card (FeaturedPictures PHI 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEricLindros.bin
	even
CardRodBrindAmour					;Rod BrindAmour player card (FeaturedPictures PHI 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRodBrindAmour.bin
	even
CardGarryGalley						;Garry Galley player card (FeaturedPictures PHI 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGarryGalley.bin
	even
CardMarkRecchi						;Mark Recchi player card (FeaturedPictures PHI 14, ASE 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMarkRecchi.bin
	even
CardTommySoderstrom					;Tommy Soderstrom player card (FeaturedPictures PHI 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTommySoderstrom.bin
	even
CardDimitriYushkevich				;Dimitri Yushkevich player card (FeaturedPictures PHI 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDimitriYushkevich.bin
	even
CardTomBarrasso						;Tom Barrasso player card (FeaturedPictures PIT 0, ASE 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTomBarrasso.bin
	even
CardMarioLemieux					;Mario Lemieux player card (FeaturedPictures PIT 2, ASE 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMarioLemieux.bin
	even
CardKevinStevens					;Kevin Stevens player card (FeaturedPictures PIT 6, ASE 10)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKevinStevens.bin
	even
CardJaromirJagr						;Jaromir Jagr player card (FeaturedPictures PIT 10, ASE 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJaromirJagr.bin
	even
CardLarryMurphy						;Larry Murphy player card (FeaturedPictures PIT 16, ASE 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardLarryMurphy.bin
	even
CardUlfSamuelsson					;Ulf Samuelsson player card (FeaturedPictures PIT 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardUlfSamuelsson.bin
	even
CardRonHextall						;Ron Hextall player card (FeaturedPictures QUE 0). Own palette and tile
									;layout, header 0000030A 0000038A 0020
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRonHextall.bin
	even
CardOwenNolan						;Owen Nolan player card (FeaturedPictures QUE 14)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardOwenNolan.bin
	even
CardSteveDuchesne					;Steve Duchesne player card (FeaturedPictures QUE 17, ASE 20)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveDuchesne.bin
	even
CardJoeSakic						;Joe Sakic player card (FeaturedPictures QUE 2, ASE 7)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJoeSakic.bin
	even
CardCurtisLeschyshyn				;Curtis Leschyshyn player card (FeaturedPictures QUE 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCurtisLeschyshyn.bin
	even
CardMatsSundin						;Mats Sundin player card (FeaturedPictures QUE 13)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMatsSundin.bin
	even
CardKellyKisio						;Kelly Kisio player card (FeaturedPictures SJ 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKellyKisio.bin
	even
CardDougWilson						;Doug Wilson player card (FeaturedPictures SJ 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougWilson.bin
	even
CardPatFalloon						;Pat Falloon player card (FeaturedPictures SJ 13, ASW 15)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPatFalloon.bin
	even
CardArtursIrbe						;Arturs Irbe player card (FeaturedPictures SJ 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardArtursIrbe.bin
	even
CardNeilWilkinson					;Neil Wilkinson player card (FeaturedPictures SJ 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardNeilWilkinson.bin
	even
CardJohanGarpenlov					;Johan Garpenlov player card (FeaturedPictures SJ 9)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJohanGarpenlov.bin
	even
CardCurtisJoseph					;Curtis Joseph player card (FeaturedPictures STL 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCurtisJoseph.bin
	even
CardCraigJanney						;Craig Janney player card (FeaturedPictures STL 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCraigJanney.bin
	even
CardBrettHull						;Brett Hull player card (FeaturedPictures STL 12, ASW 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrettHull.bin
	even
CardGarthButcher					;Garth Butcher player card (FeaturedPictures STL 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGarthButcher.bin
	even
CardJeffBrown						;Jeff Brown player card (FeaturedPictures STL 16, ASW 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJeffBrown.bin
	even
CardBrendanShanahan					;Brendan Shanahan player card (FeaturedPictures STL 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrendanShanahan.bin
	even
CardBrianBradley					;Brian Bradley player card (FeaturedPictures TB 3, ASW 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrianBradley.bin
	even
CardWendellYoung					;Wendell Young player card (FeaturedPictures TB 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardWendellYoung.bin
	even
CardRomanHamrlik					;Roman Hamrlik player card (FeaturedPictures TB 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRomanHamrlik.bin
	even
CardBobBeers						;Bob Beers player card (FeaturedPictures TB 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBobBeers.bin
	even
CardMikaelAndersson					;Mikael Andersson player card (FeaturedPictures TB 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikaelAndersson.bin
	even
CardChrisKontos						;Chris Kontos player card (FeaturedPictures TB 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardChrisKontos.bin
	even
CardFelixPotvin						;Felix Potvin player card (FeaturedPictures TOR 0, ASW 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardFelixPotvin.bin
	even
CardDougGilmour						;Doug Gilmour player card (FeaturedPictures TOR 3, ASW 7)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougGilmour.bin
	even
CardNikolaiBorshevsky				;Nikolai Borshevsky player card (FeaturedPictures TOR 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardNikolaiBorshevsky.bin
	even
CardDaveEllett						;Dave Ellett player card (FeaturedPictures TOR 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaveEllett.bin
	even
CardToddGill						;Todd Gill player card (FeaturedPictures TOR 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardToddGill.bin
	even
CardDaveAndreychuk					;Dave Andreychuk player card (FeaturedPictures TOR 8). Own palette and
									;tile layout, header 0000033A 000003BA 0022
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaveAndreychuk.bin
	even
CardKirkMcLean						;Kirk McLean player card (FeaturedPictures VAN 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKirkMcLean.bin
	even
CardGeoffCourtnall					;Geoff Courtnall player card (FeaturedPictures VAN 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGeoffCourtnall.bin
	even
CardPavelBure						;Pavel Bure player card (FeaturedPictures VAN 12, ASW 13)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPavelBure.bin
	even
CardJyrkiLumme						;Jyrki Lumme player card (FeaturedPictures VAN 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJyrkiLumme.bin
	even
CardDougLidster						;Doug Lidster player card (FeaturedPictures VAN 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougLidster.bin
	even
CardCliffRonning					;Cliff Ronning player card (FeaturedPictures VAN 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCliffRonning.bin
	even
CardDonBeaupre						;Don Beaupre player card (FeaturedPictures WSH 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDonBeaupre.bin
	even
CardMikeRidley						;Mike Ridley player card (FeaturedPictures WSH 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikeRidley.bin
	even
CardDimitriKhristich				;Dimitri Khristich player card (FeaturedPictures WSH 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDimitriKhristich.bin
	even
CardPeterBondra						;Peter Bondra player card (FeaturedPictures WSH 11, ASE 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPeterBondra.bin
	even
CardKevinHatcher					;Kevin Hatcher player card (FeaturedPictures WSH 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKevinHatcher.bin
	even
CardAlIafrate						;Al Iafrate player card (FeaturedPictures WSH 17, ASE 21)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlIafrate.bin
	even
CardThomasSteen						;Thomas Steen player card (FeaturedPictures WPG 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardThomasSteen.bin
	even
CardTeemuSelanne					;Teemu Selanne player card (FeaturedPictures WPG 12, ASW 14)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTeemuSelanne.bin
	even
CardPhilHousley						;Phil Housley player card (FeaturedPictures WPG 17, ASW 21)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPhilHousley.bin
	even
CardBobEssensa						;Bob Essensa player card (FeaturedPictures WPG 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBobEssensa.bin
	even
CardTeppoNumminen					;Teppo Numminen player card (FeaturedPictures WPG 18). Own palette and
									;tile layout, header 00000352 000003D2 0023
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTeppoNumminen.bin
	even
CardAlexeiZhamnov					;Alexei Zhamnov player card (FeaturedPictures WPG 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlexeiZhamnov.bin
	even
PlayerCardsScreenPic				;the Player Cards screen picture, 40 x 28 tiles with its own palette and
									;layout (PlayerCards)
	incbin	..\Extracted\NHL94\Graphics\PlayerCardsScreenPic.bin
	even
CornerLogoMap						;read in the high ROM near NoNameTxt and by SkipOtherUserName
	incbin	..\Extracted\NHL94\Graphics\CornerLogoMap.bin
	even
ArenaGfxBank						;read in the high ROM near NoNameTxt and by SkipOtherUserName
	incbin	..\Extracted\NHL94\Graphics\ArenaGfxBank.bin
	even
PlayoffSprite						;PlayoffScreen and DrawPlayoffSprite
	incbin	..\Extracted\NHL94\Graphics\PlayoffSprite.bin
	even
HiScoreImg							;HiScoreScreen (high ROM)
	incbin	..\Extracted\NHL94\Graphics\HiScoreImg.bin
	even
HotIconMap							;read by HotColdIcon (high ROM)
	incbin	..\Extracted\NHL94\Graphics\HotIconMap.bin
	even
;HotIconMap+8: the tiles (ScoutingReport)
ColdIconMap							;read by HotColdIcon (high ROM)
	incbin	..\Extracted\NHL94\Graphics\ColdIconMap.bin
	even
;ColdIconMap+8: the tiles (ScoutingReport)
revframetbl							;the replay frame table (RestoreReplayFrame)
	incbin	..\Extracted\NHL94\Graphics\revframetbl.bin
	even
