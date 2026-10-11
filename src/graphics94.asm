; $04B5C0  Adapted from graphics93.asm: graphics only
;	graphics94.asm: retail $4B5C0-$F66ED (700718 bytes), the data after the sound data (sound94 ends with the sound incbins,
;	$1AD90-$4B5BF): the MATCHUPS script and the graphics, up to the 94 code in the high ROM. incbin only, no gap and no overlap. Each file
;	is a slice of lst/nhl94.bin written by npm run extractassets (extractAssets94.js) into Extracted\NHL94\Graphics and Text. One slice
;per except the player cards: one slice per card (Graphics\PlayerCards), NoPicGoalie2 first, then Card<player>
;from the roster String in teamdata94, then PlayerCardsScreenPic. Labels are the 93 names, or named for what the data is, the where it is not an
;auto name, or the name the matched segment uses (it in a string) or, for the team logos
;	logo<team>. Files use the 92 / 93 name where the 94 asset is the same one (same use, mostly the same size; 94 in the name when it
;	differs), else the extractAssets94.js draft name where its slice lined up, else the label. A map's tiles start past its 8-byte
;header: the there is written as label+8.
ScoutTextScript		;retail $4B5C0-$4B79F (480 bytes). the script ScoutTextPlayer (hockey94_06) types out word by word on the ScoutingReport (MATCHUPS) screen
	incbin	..\Extracted\NHL94\Text\ScoutTextScript.bin
	even
GameSetUpMap	;retail $4B7A0-$4DEED (10062 bytes). the game setup screen bitmap, 40 x 28 (93 GameSetUp.map.jim)
	incbin	..\Extracted\NHL94\Graphics\GameSetUp94-1.map.jim
	even
GameSetUpMap2	;retail $4DEEE-$4E45B (1390 bytes). the second game setup bitmap
	incbin	..\Extracted\NHL94\Graphics\GameSetUp94-2.map.jim
	even
TitleScreenImg		;retail $4E45C-$52DA9 (18766 bytes). the newTitleScreen backdrop (high ROM)
	incbin	..\Extracted\NHL94\Graphics\Title94-1.map.jim
	even
NHLShieldImg		;retail $52DAA-$5338B (1506 bytes). the NHL shield on newTitleScreen
	incbin	..\Extracted\NHL94\Graphics\Title94-2.map.jim
	even
PAlogoImg		;retail $5338C-$5394D (1474 bytes). the NHLPA logo on newTitleScreen
	incbin	..\Extracted\NHL94\Graphics\Title94-3.map.jim
	even
TitleImg		;retail $5394E-$54E23 (5334 bytes). the title on newTitleScreen
	incbin	..\Extracted\NHL94\Graphics\Title94-4.map.jim
	even
ScoutMap		;retail $54E24-$55B7D (3418 bytes). 93 ScoutMap: the ScoutingReport and PlayoffScreen background
	incbin	..\Extracted\NHL94\Graphics\Scouting94.map.jim
	even
framermap		;retail $55B7E-$55BF5 (120 bytes). (92 / 93 FramerMap): Framer
	incbin	..\Extracted\NHL94\Graphics\Framer.map.jim
	even
;framermap+8: retail $55B86. the framer tiles (AddFramer, ScoutingReport)
FaceOffMap		;retail $55BF6-$56059 (1124 bytes). (92 / 93 name): puckfaceoff2
	incbin	..\Extracted\NHL94\Graphics\FaceOff.map.jim
	even
;FaceOffMap+8: retail $55BFE. the tiles (puckfaceoff2, ReloadFaceOffMap)
Rinktilelist		;retail $5605A-$5C407 (25518 bytes). (93 IceRinkMap): the ice rink (updatescroll, setupIceRinkMap, ShowReplayIcon, DisplayPeriodOver, crash)
	incbin	..\Extracted\NHL94\Graphics\IceRink94.map.jim
	even
Rinktiles	equ	Rinktilelist+8	;retail $56062. the rink tiles (setupice, ClrHor)
RefsMap		;retail $5C408-$5CF63 (2908 bytes). (92 / 93 name): the ref (PushRef)
	incbin	..\Extracted\NHL94\Graphics\Refs.map.jim
	even
;RefsMap+8: retail $5C410. the tiles (puckpenshot, Endfaceoff, StartHL2, ReloadRefTiles)
RefMap2		;retail $5CF64-$5DE79 (3862 bytes). 93 RefMap2: the horizontal ref (PushRef)
	incbin	..\Extracted\NHL94\Graphics\Refs2.map.jim
	even
;RefMap2+8: retail $5CF6C. the tiles (chkprogress, ReloadRefHorTiles)
Sprites		;retail $5DE7A-$5DE83 (10 bytes). the sprite header (93 Sprites; addframe2): long offsets from here $4082A (to
	;$9E6A4) and $408AA (to frameSprData), then a word
	incbin	..\Extracted\NHL94\Graphics\Sprites.bin
	even
Spritetiles		;retail $5DE84-$9E723 (264352 bytes). the sprite tiles (93 Sprites+$A; addframe2 adds the frame tile offset
	;to #Spritetiles)
	incbin	..\Extracted\NHL94\Graphics\Spritetiles.bin
	even
frameSprData		;retail $9E724-$A44C7 (23972 bytes). the frame data at Sprites + $408AA (93 FrameDataOff and SprDataBytes)
	incbin	..\Extracted\NHL94\Graphics\frameSprData.bin
	even
Hotlist		;retail $A44C8-$A4B53 (1676 bytes). (93 HotList): the hot spot byte pair of each frame (GetHot)
	incbin	..\Extracted\NHL94\Graphics\Hotlist.bin
	even
CrowdFrameList		;retail $A4B54-$A78AD (11610 bytes). (93 CrowdSprites): showcrowd
	incbin	..\Extracted\NHL94\Graphics\Crowd.anim
	even
;CrowdFrameList+8: retail $A4B5C. the tiles (setupice, ReloadCrowdTiles)
FaceOffSprites		;retail $A78AE-$A8921 (4212 bytes). 93 FaceOffSprites, same size: checkfo
	incbin	..\Extracted\NHL94\Graphics\FaceOff.anim
	even
;FaceOffSprites+8: retail $A78B6. the tiles (puckfaceoff2, ReloadFaceOffTiles)
ZamFrameList		;retail $A8922-$A9A0F (4334 bytes). (93 ZamSprites): showzam
	incbin	..\Extracted\NHL94\Graphics\Zam.anim
	even
;ZamFrameList+8: retail $A892A. the tiles (Intermission)
BigFontMap		;retail $A9A10-$AAC51 (4674 bytes). 93 BigFontMap: the big font (PrintBigChar)
	incbin	..\Extracted\NHL94\Graphics\BigFont94.map.jim
	even
;BigFontMap+8: retail $A9A18. the tiles (setupice, ScoutingReport, BuildCardPlayerList)
SmallFontMap		;retail $AAC52-$AB91F (3278 bytes). 93 SmallFontMap, same size: the small font (print, printsmall, showclock, RenderSmallFontChar)
	incbin	..\Extracted\NHL94\Graphics\SmallFont.map.jim
	even
;SmallFontMap+8: retail $AAC5A. the tiles (AddSmallFont, setupice, ScoutingReport, setoptions)
EnergyBarMap		;retail $AB920-$ABA13 (244 bytes). 93 EnergyBarMap, same size: the line energy bar frames (linebar)
	incbin	..\Extracted\NHL94\Graphics\EnergyBar.map.jim
	even
;EnergyBarMap+8: retail $AB928. the tiles (setupice, ReloadEnergyBarTiles)
Teamblocksmap		;retail $ABA14-$AFE11 (17406 bytes). 93 Teamblocksmap: the team blocks (setupTeamBlocksMap, DrawTeamBlocks, DrawTeamBlockBitmap)
	incbin	..\Extracted\NHL94\Graphics\TeamBlocks.map.jim
	even
;Teamblocksmap+8: retail $ABA1C. the tiles (AddTeamBlock)
TeamBitmaps		;retail $AFE12-$B352F (14110 bytes). 94 only, dobitmap entries (DrawTeamBitmap)
	incbin	..\Extracted\NHL94\Graphics\TeamBlocks94.map.jim
	even
;TeamBitmaps+8: retail $AFE1A. the tiles (LoadSetupTiles, where 93 setoptions called AddTeamBlock)
EASNmap		;retail $B3530-$B363F (272 bytes). 93 EASNmap: the EASN logo (EASNLogo)
	incbin	..\Extracted\NHL94\Graphics\EASN.map.jim
	even
;EASNmap+8: retail $B3538. the tiles (setupEASNmap)
Arrowsmap		;retail $B3640-$B389B (604 bytes). 93 Arrowsmap, same size: the playoff tree arrows (DrawPlayoffBracket)
	incbin	..\Extracted\NHL94\Graphics\Arrows.map.jim
	even
;Arrowsmap+8: retail $B3648. the tiles (PlayoffScreen)
RonBarrMap		;retail $B389C-$B3E73 (1496 bytes). 93 Ronbarrmap, same size: the Ron Barr picture (ScoutingReport). The old
	;extractAssets94.js RonBarrCompressed.map.jim ran 4 bytes into ScoresMap
	incbin	..\Extracted\NHL94\Graphics\RonBarr.map.jim
	even
ScoresMap		;retail $B3E74-$B4259 (998 bytes). 93 ScoresMap, same size: read by the 93 ShowScores code (stats94, from $80D4; not matched yet)
	incbin	..\Extracted\NHL94\Graphics\Scores.map.jim
	even
EASportsMap	;retail $B425A-$B517F (3878 bytes). the EA Sports screen map
	incbin	..\Extracted\NHL94\Graphics\EASportsMap.bin
	even
RevRinkTilelist		;retail $B5180-$BB4ED (25454 bytes). the reversed ice rink (updatescroll, ShowReplayIcon)
	incbin	..\Extracted\NHL94\Graphics\IceRink94Reverse.map.jim
	even
RevRinkTiles	equ	RevRinkTilelist+8	;retail $B5188. the tiles (setupice)
ReplayMap		;retail $BB4EE-$BC05B (2926 bytes). the replay map ShowReplayBanner shows at 0,0 (16 x 11)
	incbin	..\Extracted\NHL94\Graphics\ReplayOptions.map.jim
	even
;ReplayMap+8: retail $BB4F6. the tiles (ReplayMode)
HorRinkMap	;retail $BC05C-$BE269 (8718 bytes). SetHor (93 IceRinkMap)
	incbin	..\Extracted\NHL94\Graphics\PauseScreen.map.jim
	even
icerinkmap	equ	HorRinkMap+8	;retail $BC064. the tiles (SetHor)
PrintFont2Map		;retail $BE26A-$BEFB7 (3406 bytes). the second print font (print, printsmall)
	incbin	..\Extracted\NHL94\Graphics\SmallFont94.map.jim
	even
;PrintFont2Map+8: retail $BE272. the tiles (setoptions: the setup screen font)
SetupMenuMap		;retail $BEFB8-$BF541 (1418 bytes). the setoptions menu background (setoptions, MoveMenuFrame)
	incbin	..\Extracted\NHL94\Graphics\GameSetupBkgd1.map.jim
	even
SetupFramerMap		;retail $BF542-$BF701 (448 bytes). the setoptions framer
	incbin	..\Extracted\NHL94\Graphics\GameSetupBkgd2.map.jim
	even
;SetupFramerMap+8: retail $BF54A. the framer tiles (setoptions; 93 FramerMap+8)
LogoBoxMap		;retail $BF702-$BF8CF (462 bytes). the logo box (DrawLogoBox, LogoBoxRight)
	incbin	..\Extracted\NHL94\Graphics\GameSetupLogoBorder.map.jim
	even
;LogoBoxMap+8: retail $BF70A. the tiles (setoptions, BuildCardPlayerList)
logoANH		;retail $BF8D0-$BFD65 (1174 bytes). the ANH logo, team 0 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoANA.map.jim
	even
logoBOS		;retail $BFD66-$C00BB (854 bytes). the BOS logo, team 1 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoBOS.map.jim
	even
logoBUF		;retail $C00BC-$C0411 (854 bytes). the BUF logo, team 2 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoBUF.map.jim
	even
logoCGY		;retail $C0412-$C08A7 (1174 bytes). the CGY logo, team 3 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoCGY.map.jim
	even
logoCHI		;retail $C08A8-$C0CDD (1078 bytes). the CHI logo, team 4 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoCHI.map.jim
	even
logoDET		;retail $C0CDE-$C1033 (854 bytes). the DET logo, team 6 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoDET.map.jim
	even
logoEDM		;retail $C1034-$C1429 (1014 bytes). the EDM logo, team 7 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoEDM.map.jim
	even
logoFLA		;retail $C142A-$C18FF (1238 bytes). the FLA logo, team 8 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoFLA.map.jim
	even
logoHFD		;retail $C1900-$C1B95 (662 bytes). the HFD logo, team 9 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoHFD.map.jim
	even
logoNYI		;retail $C1B96-$C1FEB (1110 bytes). the NYI logo, team 13 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoNYI.map.jim
	even
logoLA		;retail $C1FEC-$C2361 (886 bytes). the LA logo, team 10 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoLA.map.jim
	even
logoDAL		;retail $C2362-$C2637 (726 bytes). the DAL logo, team 5 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoDAL.map.jim
	even
logoMTL		;retail $C2638-$C29AD (886 bytes). the MTL logo, team 11 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoMTL.map.jim
	even
logoNJ		;retail $C29AE-$C2E63 (1206 bytes). the NJ logo, team 12 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoNJ.map.jim
	even
logoNYR		;retail $C2E64-$C3339 (1238 bytes). the NYR logo, team 14 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoNYR.map.jim
	even
logoOTW		;retail $C333A-$C374F (1046 bytes). the OTW logo, team 15 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoOTW.map.jim
	even
logoPHI		;retail $C3750-$C3B05 (950 bytes). the PHI logo, team 16 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoPHI.map.jim
	even
logoPIT		;retail $C3B06-$C3E7B (886 bytes). the PIT logo, team 17 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoPIT.map.jim
	even
logoQUE		;retail $C3E7C-$C41D1 (854 bytes). the QUE logo, team 18 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoQUE.map.jim
	even
logoSJ		;retail $C41D2-$C4607 (1078 bytes). the SJ logo, team 19 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoSJ.map.jim
	even
logoSTL		;retail $C4608-$C49DD (982 bytes). the STL logo, team 20 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoSTL.map.jim
	even
logoTB		;retail $C49DE-$C4DF3 (1046 bytes). the TB logo, team 21 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoTB.map.jim
	even
logoTOR		;retail $C4DF4-$C5149 (854 bytes). the TOR logo, team 22 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoTOR.map.jim
	even
logoVAN		;retail $C514A-$C555F (1046 bytes). the VAN logo, team 23 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoVAN.map.jim
	even
logoWSH		;retail $C5560-$C57D5 (630 bytes). the WSH logo, team 24 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoWSH.map.jim
	even
logoWPG		;retail $C57D6-$C5C4B (1142 bytes). the WPG logo, team 25 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoWPG.map.jim
	even
logoASE		;retail $C5C4C-$C6021 (982 bytes). the ASE logo, team 26 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoASE.map.jim
	even
logoASW		;retail $C6022-$C63F7 (982 bytes). the ASW logo, team 27 in TeamLogoBitmaps (hockey94_08 DrawTeamLogo, hockey94_07 GetTeamLogo)
	incbin	..\Extracted\NHL94\Graphics\logoASW.map.jim
	even
PicturePalette		;retail $C63F8-$C682D (1078 bytes). the player picture palette, and the picture of a player with none (DrawMatchupPicture, PlayerCardScreen)
	incbin	..\Extracted\NHL94\Graphics\PicturePalette.bin
	even
NoPicSkater1		;retail $C682E-$C6B97 (874 bytes). read by DrawPlayerPicture (high ROM, not matched yet)
	incbin	..\Extracted\NHL94\Graphics\NoPicSkater1.bin
	even
NoPicSkater2		;retail $C6B98-$C6F01 (874 bytes). read by DrawPlayerPicture (high ROM, not matched yet)
	incbin	..\Extracted\NHL94\Graphics\NoPicSkater2.bin
	even
NoPicGoalie1		;retail $C6F02-$C726B (874 bytes). read by DrawPlayerPicture (high ROM, not matched yet)
	incbin	..\Extracted\NHL94\Graphics\NoPicGoalie1.bin
	even
NoPicGoalie2		;retail $C726C-$C75D5 (874 bytes). the generic goalie card: DrawPlayerPicture uses it for a goalie with no card whose hand rating (h) bit 0 is clear (NoPicGoalie1 when set). Also listed for ANH 0 and FLA 0
	incbin	..\Extracted\NHL94\Graphics\NoPicGoalie2.bin
	even
CardAndyMoog		;retail $C75D6-$C793F (874 bytes). Andy Moog player card (FeaturedPictures BOS 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAndyMoog.bin
	even
CardRayBourque		;retail $C7940-$C7CA9 (874 bytes). Ray Bourque player card (FeaturedPictures BOS 17, ASE 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRayBourque.bin
	even
CardAdamOates		;retail $C7CAA-$C8013 (874 bytes). Adam Oates player card (FeaturedPictures BOS 2, ASE 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAdamOates.bin
	even
CardDonSweeney		;retail $C8014-$C837D (874 bytes). Don Sweeney player card (FeaturedPictures BOS 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDonSweeney.bin
	even
CardJoeJuneau		;retail $C837E-$C86E7 (874 bytes). Joe Juneau player card (FeaturedPictures BOS 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJoeJuneau.bin
	even
CardCamNeely		;retail $C86E8-$C8A51 (874 bytes). Cam Neely player card (FeaturedPictures BOS 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCamNeely.bin
	even
CardAlexnderMogilny		;retail $C8A52-$C8DBB (874 bytes). Alexnder Mogilny player card (FeaturedPictures BUF 12, ASE 15)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlexnderMogilny.bin
	even
CardPatLaFontaine		;retail $C8DBC-$C9125 (874 bytes). Pat LaFontaine player card (FeaturedPictures BUF 3, ASE 9)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPatLaFontaine.bin
	even
CardDaleHawerchuk		;retail $C9126-$C948F (874 bytes). Dale Hawerchuk player card (FeaturedPictures BUF 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaleHawerchuk.bin
	even
CardDougBodger		;retail $C9490-$C97F9 (874 bytes). Doug Bodger player card (FeaturedPictures BUF 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougBodger.bin
	even
CardGrantFuhr		;retail $C97FA-$C9B63 (874 bytes). Grant Fuhr player card (FeaturedPictures BUF 0, ASE 1)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGrantFuhr.bin
	even
CardPetrSvoboda		;retail $C9B64-$C9ECD (874 bytes). Petr Svoboda player card (FeaturedPictures BUF 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPetrSvoboda.bin
	even
CardMikeVernon		;retail $C9ECE-$CA237 (874 bytes). Mike Vernon player card (FeaturedPictures CGY 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikeVernon.bin
	even
CardGaryRoberts		;retail $CA238-$CA5A1 (874 bytes). Gary Roberts player card (FeaturedPictures CGY 6, ASW 9)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGaryRoberts.bin
	even
CardTheorenFleury		;retail $CA5A2-$CA90B (874 bytes). Theoren Fleury player card (FeaturedPictures CGY 11, ASW 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTheorenFleury.bin
	even
CardGarySuter		;retail $CA90C-$CAC75 (874 bytes). Gary Suter player card (FeaturedPictures CGY 15, ASW 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGarySuter.bin
	even
CardAlMacInnis		;retail $CAC76-$CAFDF (874 bytes). Al MacInnis player card (FeaturedPictures CGY 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlMacInnis.bin
	even
CardJoeNieuwendyk		;retail $CAFE0-$CB349 (874 bytes). Joe Nieuwendyk player card (FeaturedPictures CGY 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJoeNieuwendyk.bin
	even
CardEdBelfour		;retail $CB34A-$CB6B3 (874 bytes). Ed Belfour player card (FeaturedPictures CHI 0, ASW 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEdBelfour.bin
	even
CardJeremyRoenick		;retail $CB6B4-$CBA1D (874 bytes). Jeremy Roenick player card (FeaturedPictures CHI 2, ASW 5)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJeremyRoenick.bin
	even
CardSteveLarmer		;retail $CBA1E-$CBD87 (874 bytes). Steve Larmer player card (FeaturedPictures CHI 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveLarmer.bin
	even
CardChrisChelios		;retail $CBD88-$CC0F1 (874 bytes). Chris Chelios player card (FeaturedPictures CHI 17, ASW 20)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardChrisChelios.bin
	even
CardSteveSmith		;retail $CC0F2-$CC45B (874 bytes). Steve Smith player card (FeaturedPictures CHI 18, ASW 23)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveSmith.bin
	even
CardMichelGoulet		;retail $CC45C-$CC7C5 (874 bytes). Michel Goulet player card (FeaturedPictures CHI 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMichelGoulet.bin
	even
CardTimCheveldae		;retail $CC7C6-$CCB2F (874 bytes). Tim Cheveldae player card (FeaturedPictures DET 0, ASW 1)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTimCheveldae.bin
	even
CardSteveYzerman		;retail $CCB30-$CCE99 (874 bytes). Steve Yzerman player card (FeaturedPictures DET 2, ASW 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveYzerman.bin
	even
CardSergeiFedorov		;retail $CCE9A-$CD203 (874 bytes). Sergei Fedorov player card (FeaturedPictures DET 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSergeiFedorov.bin
	even
CardPaulCoffey		;retail $CD204-$CD56D (874 bytes). Paul Coffey player card (FeaturedPictures DET 17, ASW 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPaulCoffey.bin
	even
CardSteveChiasson		;retail $CD56E-$CD8D7 (874 bytes). Steve Chiasson player card (FeaturedPictures DET 18, ASW 24)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveChiasson.bin
	even
CardDinoCiccarelli		;retail $CD8D8-$CDC41 (874 bytes). Dino Ciccarelli player card (FeaturedPictures DET 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDinoCiccarelli.bin
	even
CardBillRanford		;retail $CDC42-$CDFAB (874 bytes). Bill Ranford player card (FeaturedPictures EDM 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBillRanford.bin
	even
CardDaveManson		;retail $CDFAC-$CE315 (874 bytes). Dave Manson player card (FeaturedPictures EDM 17, ASW 22)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaveManson.bin
	even
CardIgorKravchuk		;retail $CE316-$CE67F (874 bytes). Igor Kravchuk player card (FeaturedPictures EDM 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardIgorKravchuk.bin
	even
CardShayneCorson		;retail $CE680-$CE9E9 (874 bytes). Shayne Corson player card (FeaturedPictures EDM 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardShayneCorson.bin
	even
CardDougWeight		;retail $CE9EA-$CEDEF (1030 bytes). Doug Weight player card (FeaturedPictures EDM 2). Own palette and tile layout, header 0000033A 000003BA 0022
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougWeight.bin
	even
CardPetrKlima		;retail $CEDF0-$CF159 (874 bytes). Petr Klima player card (FeaturedPictures EDM 14)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPetrKlima.bin
	even
CardSeanBurke		;retail $CF15A-$CF4C3 (874 bytes). Sean Burke player card (FeaturedPictures HFD 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSeanBurke.bin
	even
CardAndrewCassels		;retail $CF4C4-$CF82D (874 bytes). Andrew Cassels player card (FeaturedPictures HFD 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAndrewCassels.bin
	even
CardGeoffSanderson		;retail $CF82E-$CFB97 (874 bytes). Geoff Sanderson player card (FeaturedPictures HFD 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGeoffSanderson.bin
	even
CardPatVerbeek		;retail $CFB98-$CFF01 (874 bytes). Pat Verbeek player card (FeaturedPictures HFD 13)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPatVerbeek.bin
	even
CardZarleyZalapski		;retail $CFF02-$D026B (874 bytes). Zarley Zalapski player card (FeaturedPictures HFD 18, ASE 23)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardZarleyZalapski.bin
	even
CardEricWeinrich		;retail $D026C-$D05D5 (874 bytes). Eric Weinrich player card (FeaturedPictures HFD 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEricWeinrich.bin
	even
CardBenoitHogue		;retail $D05D6-$D093F (874 bytes). Benoit Hogue player card (FeaturedPictures NYI 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBenoitHogue.bin
	even
CardSteveThomas		;retail $D0940-$D0CA9 (874 bytes). Steve Thomas player card (FeaturedPictures NYI 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveThomas.bin
	even
CardPierreTurgeon		;retail $D0CAA-$D1013 (874 bytes). Pierre Turgeon player card (FeaturedPictures NYI 2, ASE 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPierreTurgeon.bin
	even
CardGlennHealy		;retail $D1014-$D137D (874 bytes). Glenn Healy player card (FeaturedPictures NYI 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGlennHealy.bin
	even
CardDariusKasparitis		;retail $D137E-$D16E7 (874 bytes). Darius Kasparitis player card (FeaturedPictures NYI 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDariusKasparitis.bin
	even
CardVladimirMalakhov		;retail $D16E8-$D1AED (1030 bytes). Vladimir Malakhov player card (FeaturedPictures NYI 17). Own palette and tile layout, header 0000033A 000003BA 0022
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardVladimirMalakhov.bin
	even
CardKellyHrudey		;retail $D1AEE-$D1EDB (1006 bytes). Kelly Hrudey player card (FeaturedPictures LA 0). Own palette and tile layout, header 00000322 000003A2 0021
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKellyHrudey.bin
	even
CardWayneGretzky		;retail $D1EDC-$D2245 (874 bytes). Wayne Gretzky player card (FeaturedPictures LA 3, ASW 8)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardWayneGretzky.bin
	even
CardLucRobitaille		;retail $D2246-$D25AF (874 bytes). Luc Robitaille player card (FeaturedPictures LA 7, ASW 10)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardLucRobitaille.bin
	even
CardTomasSandstrom		;retail $D25B0-$D2919 (874 bytes). Tomas Sandstrom player card (FeaturedPictures LA 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTomasSandstrom.bin
	even
CardRobBlake		;retail $D291A-$D2C83 (874 bytes). Rob Blake player card (FeaturedPictures LA 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRobBlake.bin
	even
CardMartyMcSorley		;retail $D2C84-$D2FED (874 bytes). Marty McSorley player card (FeaturedPictures LA 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMartyMcSorley.bin
	even
CardJonCasey		;retail $D2FEE-$D3357 (874 bytes). Jon Casey player card (FeaturedPictures DAL 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJonCasey.bin
	even
CardMikeModano		;retail $D3358-$D36C1 (874 bytes). Mike Modano player card (FeaturedPictures DAL 2, ASW 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikeModano.bin
	even
CardMarkTinordi		;retail $D36C2-$D3A2B (874 bytes). Mark Tinordi player card (FeaturedPictures DAL 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMarkTinordi.bin
	even
CardTommySjodin		;retail $D3A2C-$D3D95 (874 bytes). Tommy Sjodin player card (FeaturedPictures DAL 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTommySjodin.bin
	even
CardDaveGagner		;retail $D3D96-$D40FF (874 bytes). Dave Gagner player card (FeaturedPictures DAL 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaveGagner.bin
	even
CardRussCourtnall		;retail $D4100-$D4469 (874 bytes). Russ Courtnall player card (FeaturedPictures DAL 10)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRussCourtnall.bin
	even
CardPatrickRoy		;retail $D446A-$D47D3 (874 bytes). Patrick Roy player card (FeaturedPictures MTL 0, ASE 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPatrickRoy.bin
	even
CardEricDesjardins		;retail $D47D4-$D4B3D (874 bytes). Eric Desjardins player card (FeaturedPictures MTL 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEricDesjardins.bin
	even
CardMattSchneider		;retail $D4B3E-$D4F13 (982 bytes). Matt Schneider player card (FeaturedPictures MTL 17). Own palette and tile layout, header 0000030A 0000038A 0020
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMattSchneider.bin
	even
CardKirkMuller		;retail $D4F14-$D527D (874 bytes). Kirk Muller player card (FeaturedPictures MTL 2, ASE 5)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKirkMuller.bin
	even
CardVincentDamphousse		;retail $D527E-$D55E7 (874 bytes). Vincent Damphousse player card (FeaturedPictures MTL 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardVincentDamphousse.bin
	even
CardBrianBellows		;retail $D55E8-$D5951 (874 bytes). Brian Bellows player card (FeaturedPictures MTL 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrianBellows.bin
	even
CardScottStevens		;retail $D5952-$D5CBB (874 bytes). Scott Stevens player card (FeaturedPictures NJ 17, ASE 22)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardScottStevens.bin
	even
CardChrisTerreri		;retail $D5CBC-$D6025 (874 bytes). Chris Terreri player card (FeaturedPictures NJ 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardChrisTerreri.bin
	even
CardVachslavFetisov		;retail $D6026-$D638F (874 bytes). Vachslav Fetisov player card (FeaturedPictures NJ 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardVachslavFetisov.bin
	even
CardStephaneRicher		;retail $D6390-$D66F9 (874 bytes). Stephane Richer player card (FeaturedPictures NJ 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardStephaneRicher.bin
	even
CardAlexnderSemak		;retail $D66FA-$D6A63 (874 bytes). Alexnder Semak player card (FeaturedPictures NJ 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlexnderSemak.bin
	even
CardClaudeLemieux		;retail $D6A64-$D6DCD (874 bytes). Claude Lemieux player card (FeaturedPictures NJ 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardClaudeLemieux.bin
	even
CardJohnVanbiesbrk		;retail $D6DCE-$D71A3 (982 bytes). John Vanbiesbrk player card (FeaturedPictures NYR 0). Own palette and tile layout, header 0000030A 0000038A 0020
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJohnVanbiesbrk.bin
	even
CardMarkMessier		;retail $D71A4-$D750D (874 bytes). Mark Messier player card (FeaturedPictures NYR 2, ASE 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMarkMessier.bin
	even
CardJamesPatrick		;retail $D750E-$D7877 (874 bytes). James Patrick player card (FeaturedPictures NYR 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJamesPatrick.bin
	even
CardMikeGartner		;retail $D7878-$D7BE1 (874 bytes). Mike Gartner player card (FeaturedPictures NYR 11, ASE 13)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikeGartner.bin
	even
CardBrianLeetch		;retail $D7BE2-$D7F4B (874 bytes). Brian Leetch player card (FeaturedPictures NYR 17, ASE 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrianLeetch.bin
	even
CardEsaTikkanen		;retail $D7F4C-$D82B5 (874 bytes). Esa Tikkanen player card (FeaturedPictures NYR 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEsaTikkanen.bin
	even
CardPeterSidorkwicz		;retail $D82B6-$D868B (982 bytes). Peter Sidorkwicz player card (FeaturedPictures OTW 0). Own palette and tile layout, header 0000030A 0000038A 0020
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPeterSidorkwicz.bin
	even
CardSylvainTurgeon		;retail $D868C-$D89F5 (874 bytes). Sylvain Turgeon player card (FeaturedPictures OTW 9)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSylvainTurgeon.bin
	even
CardNormMaciver		;retail $D89F6-$D8D5F (874 bytes). Norm Maciver player card (FeaturedPictures OTW 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardNormMaciver.bin
	even
CardBradShaw		;retail $D8D60-$D90C9 (874 bytes). Brad Shaw player card (FeaturedPictures OTW 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBradShaw.bin
	even
CardJamieBaker		;retail $D90CA-$D9433 (874 bytes). Jamie Baker player card (FeaturedPictures OTW 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJamieBaker.bin
	even
CardBobKudelski		;retail $D9434-$D979D (874 bytes). Bob Kudelski player card (FeaturedPictures OTW 14)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBobKudelski.bin
	even
CardEricLindros		;retail $D979E-$D9B07 (874 bytes). Eric Lindros player card (FeaturedPictures PHI 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardEricLindros.bin
	even
CardRodBrindAmour		;retail $D9B08-$D9E71 (874 bytes). Rod BrindAmour player card (FeaturedPictures PHI 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRodBrindAmour.bin
	even
CardGarryGalley		;retail $D9E72-$DA1DB (874 bytes). Garry Galley player card (FeaturedPictures PHI 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGarryGalley.bin
	even
CardMarkRecchi		;retail $DA1DC-$DA545 (874 bytes). Mark Recchi player card (FeaturedPictures PHI 14, ASE 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMarkRecchi.bin
	even
CardTommySoderstrom		;retail $DA546-$DA8AF (874 bytes). Tommy Soderstrom player card (FeaturedPictures PHI 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTommySoderstrom.bin
	even
CardDimitriYushkevich		;retail $DA8B0-$DAC19 (874 bytes). Dimitri Yushkevich player card (FeaturedPictures PHI 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDimitriYushkevich.bin
	even
CardTomBarrasso		;retail $DAC1A-$DAF83 (874 bytes). Tom Barrasso player card (FeaturedPictures PIT 0, ASE 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTomBarrasso.bin
	even
CardMarioLemieux		;retail $DAF84-$DB2ED (874 bytes). Mario Lemieux player card (FeaturedPictures PIT 2, ASE 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMarioLemieux.bin
	even
CardKevinStevens		;retail $DB2EE-$DB657 (874 bytes). Kevin Stevens player card (FeaturedPictures PIT 6, ASE 10)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKevinStevens.bin
	even
CardJaromirJagr		;retail $DB658-$DB9C1 (874 bytes). Jaromir Jagr player card (FeaturedPictures PIT 10, ASE 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJaromirJagr.bin
	even
CardLarryMurphy		;retail $DB9C2-$DBD2B (874 bytes). Larry Murphy player card (FeaturedPictures PIT 16, ASE 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardLarryMurphy.bin
	even
CardUlfSamuelsson		;retail $DBD2C-$DC095 (874 bytes). Ulf Samuelsson player card (FeaturedPictures PIT 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardUlfSamuelsson.bin
	even
CardRonHextall		;retail $DC096-$DC46B (982 bytes). Ron Hextall player card (FeaturedPictures QUE 0). Own palette and tile layout, header 0000030A 0000038A 0020
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRonHextall.bin
	even
CardOwenNolan		;retail $DC46C-$DC7D5 (874 bytes). Owen Nolan player card (FeaturedPictures QUE 14)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardOwenNolan.bin
	even
CardSteveDuchesne		;retail $DC7D6-$DCB3F (874 bytes). Steve Duchesne player card (FeaturedPictures QUE 17, ASE 20)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardSteveDuchesne.bin
	even
CardJoeSakic		;retail $DCB40-$DCEA9 (874 bytes). Joe Sakic player card (FeaturedPictures QUE 2, ASE 7)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJoeSakic.bin
	even
CardCurtisLeschyshyn		;retail $DCEAA-$DD213 (874 bytes). Curtis Leschyshyn player card (FeaturedPictures QUE 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCurtisLeschyshyn.bin
	even
CardMatsSundin		;retail $DD214-$DD57D (874 bytes). Mats Sundin player card (FeaturedPictures QUE 13)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMatsSundin.bin
	even
CardKellyKisio		;retail $DD57E-$DD8E7 (874 bytes). Kelly Kisio player card (FeaturedPictures SJ 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKellyKisio.bin
	even
CardDougWilson		;retail $DD8E8-$DDC51 (874 bytes). Doug Wilson player card (FeaturedPictures SJ 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougWilson.bin
	even
CardPatFalloon		;retail $DDC52-$DDFBB (874 bytes). Pat Falloon player card (FeaturedPictures SJ 13, ASW 15)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPatFalloon.bin
	even
CardArtursIrbe		;retail $DDFBC-$DE325 (874 bytes). Arturs Irbe player card (FeaturedPictures SJ 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardArtursIrbe.bin
	even
CardNeilWilkinson		;retail $DE326-$DE68F (874 bytes). Neil Wilkinson player card (FeaturedPictures SJ 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardNeilWilkinson.bin
	even
CardJohanGarpenlov		;retail $DE690-$DE9F9 (874 bytes). Johan Garpenlov player card (FeaturedPictures SJ 9)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJohanGarpenlov.bin
	even
CardCurtisJoseph		;retail $DE9FA-$DED63 (874 bytes). Curtis Joseph player card (FeaturedPictures STL 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCurtisJoseph.bin
	even
CardCraigJanney		;retail $DED64-$DF0CD (874 bytes). Craig Janney player card (FeaturedPictures STL 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCraigJanney.bin
	even
CardBrettHull		;retail $DF0CE-$DF437 (874 bytes). Brett Hull player card (FeaturedPictures STL 12, ASW 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrettHull.bin
	even
CardGarthButcher		;retail $DF438-$DF7A1 (874 bytes). Garth Butcher player card (FeaturedPictures STL 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGarthButcher.bin
	even
CardJeffBrown		;retail $DF7A2-$DFB0B (874 bytes). Jeff Brown player card (FeaturedPictures STL 16, ASW 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJeffBrown.bin
	even
CardBrendanShanahan		;retail $DFB0C-$DFE75 (874 bytes). Brendan Shanahan player card (FeaturedPictures STL 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrendanShanahan.bin
	even
CardBrianBradley		;retail $DFE76-$E01DF (874 bytes). Brian Bradley player card (FeaturedPictures TB 3, ASW 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBrianBradley.bin
	even
CardWendellYoung		;retail $E01E0-$E0549 (874 bytes). Wendell Young player card (FeaturedPictures TB 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardWendellYoung.bin
	even
CardRomanHamrlik		;retail $E054A-$E08B3 (874 bytes). Roman Hamrlik player card (FeaturedPictures TB 19)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardRomanHamrlik.bin
	even
CardBobBeers		;retail $E08B4-$E0C1D (874 bytes). Bob Beers player card (FeaturedPictures TB 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBobBeers.bin
	even
CardMikaelAndersson		;retail $E0C1E-$E0F87 (874 bytes). Mikael Andersson player card (FeaturedPictures TB 11)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikaelAndersson.bin
	even
CardChrisKontos		;retail $E0F88-$E12F1 (874 bytes). Chris Kontos player card (FeaturedPictures TB 4)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardChrisKontos.bin
	even
CardFelixPotvin		;retail $E12F2-$E165B (874 bytes). Felix Potvin player card (FeaturedPictures TOR 0, ASW 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardFelixPotvin.bin
	even
CardDougGilmour		;retail $E165C-$E19C5 (874 bytes). Doug Gilmour player card (FeaturedPictures TOR 3, ASW 7)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougGilmour.bin
	even
CardNikolaiBorshevsky		;retail $E19C6-$E1D2F (874 bytes). Nikolai Borshevsky player card (FeaturedPictures TOR 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardNikolaiBorshevsky.bin
	even
CardDaveEllett		;retail $E1D30-$E2099 (874 bytes). Dave Ellett player card (FeaturedPictures TOR 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaveEllett.bin
	even
CardToddGill		;retail $E209A-$E2403 (874 bytes). Todd Gill player card (FeaturedPictures TOR 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardToddGill.bin
	even
CardDaveAndreychuk		;retail $E2404-$E2809 (1030 bytes). Dave Andreychuk player card (FeaturedPictures TOR 8). Own palette and tile layout, header 0000033A 000003BA 0022
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDaveAndreychuk.bin
	even
CardKirkMcLean		;retail $E280A-$E2B73 (874 bytes). Kirk McLean player card (FeaturedPictures VAN 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKirkMcLean.bin
	even
CardGeoffCourtnall		;retail $E2B74-$E2EDD (874 bytes). Geoff Courtnall player card (FeaturedPictures VAN 6)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardGeoffCourtnall.bin
	even
CardPavelBure		;retail $E2EDE-$E3247 (874 bytes). Pavel Bure player card (FeaturedPictures VAN 12, ASW 13)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPavelBure.bin
	even
CardJyrkiLumme		;retail $E3248-$E35B1 (874 bytes). Jyrki Lumme player card (FeaturedPictures VAN 17)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardJyrkiLumme.bin
	even
CardDougLidster		;retail $E35B2-$E391B (874 bytes). Doug Lidster player card (FeaturedPictures VAN 18)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDougLidster.bin
	even
CardCliffRonning		;retail $E391C-$E3C85 (874 bytes). Cliff Ronning player card (FeaturedPictures VAN 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardCliffRonning.bin
	even
CardDonBeaupre		;retail $E3C86-$E3FEF (874 bytes). Don Beaupre player card (FeaturedPictures WSH 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDonBeaupre.bin
	even
CardMikeRidley		;retail $E3FF0-$E4359 (874 bytes). Mike Ridley player card (FeaturedPictures WSH 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardMikeRidley.bin
	even
CardDimitriKhristich		;retail $E435A-$E46C3 (874 bytes). Dimitri Khristich player card (FeaturedPictures WSH 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardDimitriKhristich.bin
	even
CardPeterBondra		;retail $E46C4-$E4A2D (874 bytes). Peter Bondra player card (FeaturedPictures WSH 11, ASE 12)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPeterBondra.bin
	even
CardKevinHatcher		;retail $E4A2E-$E4D97 (874 bytes). Kevin Hatcher player card (FeaturedPictures WSH 16)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardKevinHatcher.bin
	even
CardAlIafrate		;retail $E4D98-$E5101 (874 bytes). Al Iafrate player card (FeaturedPictures WSH 17, ASE 21)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlIafrate.bin
	even
CardThomasSteen		;retail $E5102-$E546B (874 bytes). Thomas Steen player card (FeaturedPictures WPG 3)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardThomasSteen.bin
	even
CardTeemuSelanne		;retail $E546C-$E57D5 (874 bytes). Teemu Selanne player card (FeaturedPictures WPG 12, ASW 14)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTeemuSelanne.bin
	even
CardPhilHousley		;retail $E57D6-$E5B3F (874 bytes). Phil Housley player card (FeaturedPictures WPG 17, ASW 21)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardPhilHousley.bin
	even
CardBobEssensa		;retail $E5B40-$E5EA9 (874 bytes). Bob Essensa player card (FeaturedPictures WPG 0)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardBobEssensa.bin
	even
CardTeppoNumminen		;retail $E5EAA-$E62C7 (1054 bytes). Teppo Numminen player card (FeaturedPictures WPG 18). Own palette and tile layout, header 00000352 000003D2 0023
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardTeppoNumminen.bin
	even
CardAlexeiZhamnov		;retail $E62C8-$E6631 (874 bytes). Alexei Zhamnov player card (FeaturedPictures WPG 2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCards\CardAlexeiZhamnov.bin
	even
PlayerCardsScreenPic		;retail $E6632-$E9A7F (13390 bytes). the Player Cards screen picture, 40 x 28 tiles with its own palette and layout (PlayerCards, high94_2)
	incbin	..\Extracted\NHL94\Graphics\PlayerCardsScreenPic.bin
	even
CornerLogoMap		;retail $E9A80-$E9ED5 (1110 bytes). read in the high ROM near NoNameTxt and by SkipOtherUserName (not matched yet)
	incbin	..\Extracted\NHL94\Graphics\CornerLogoMap.bin
	even
ArenaGfxBank		;retail $E9ED6-$F3097 (37314 bytes). read in the high ROM near NoNameTxt and by SkipOtherUserName (not matched yet)
	incbin	..\Extracted\NHL94\Graphics\ArenaGfxBank.bin
	even
PlayoffSprite		;retail $F3098-$F5337 (8864 bytes). PlayoffScreen and DrawPlayoffSprite
	incbin	..\Extracted\NHL94\Graphics\PlayoffSprite.bin
	even
HiScoreImg		;retail $F5338-$F5AF5 (1982 bytes). HiScoreScreen (high ROM)
	incbin	..\Extracted\NHL94\Graphics\HiScoreImg.bin
	even
HotIconMap		;retail $F5AF6-$F5D1B (550 bytes). read by HotColdIcon (high ROM, not matched yet)
	incbin	..\Extracted\NHL94\Graphics\HotIconMap.bin
	even
;HotIconMap+8: retail $F5AFE. the tiles (ScoutingReport)
ColdIconMap		;retail $F5D1C-$F600D (754 bytes). read by HotColdIcon (high ROM, not matched yet)
	incbin	..\Extracted\NHL94\Graphics\ColdIconMap.bin
	even
;ColdIconMap+8: retail $F5D24. the tiles (ScoutingReport)
revframetbl		;retail $F600E-$F66ED (1760 bytes). the replay frame table (RestoreReplayFrame)
	incbin	..\Extracted\NHL94\Graphics\revframetbl.bin
	even
