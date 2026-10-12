# Name review: NHL94 (names not in 93G/92G)

Verdicts from reading each routine body / usage. "ok" = name matches behavior.

## stats94

| name | verdict |
|---|---|
| GetDefenseStart | ok |
| ReloadRinkGraphics | ok |

## menu94

| name | verdict |
|---|---|
| PrintMenuItem | ok |
| vcountwait | ok |

## hockey94

| name | verdict |
|---|---|
| startpause3 | ok |
| startpause4 | ok |

## penalty94

| name | verdict |
|---|---|
| PenShotChk | ok |
| RestoreTeamEnergy | ok |
| getBAplayerInfo | ok |
| sctab | ok |

## collide94

| name | verdict |
|---|---|
| CCStart | ok |
| SetupPenaltyShot | ok |
| checkinglist | ok |
| checkpuckcoll_sfx | ok |

## attract94

| name | verdict |
|---|---|
| DrawMatchupBitmaps | ok |
| DrawTeamBitmap | ok |
| EASportsScreen | ok |

## assign94

| name | verdict |
|---|---|
| assgoaliebreakwait | ok |
| rtss21 | ok |
| rtss4 | ok |
| rtss6 | ok |

## video94

| name | verdict |
|---|---|
| PrintBigChar | ok |
| PutBigTile | ok |
| ReadJoy3 | ok |
| ReadJoy4 | ok |
| forceblack2 | ok |

## setup94

| name | verdict |
|---|---|
| ReloadCrowdTiles | ok |
| ReloadEnergyBarTiles | ok |
| ReloadFaceOffMap | ok |
| ReloadFaceOffTiles | ok |
| ReloadRefHorTiles | ok |
| ReloadRefTiles | ok |

## teamdata94

| name | verdict |
|---|---|
| Anaheim | ok |
| CreditsList | ok |
| Dallas | ok |
| Florida | ok |
| NYIslanders | ok |
| NYRangers | ok |
| UpdatePlayoffLevel | renamed from SetPojoyMode (93 name of the same routine) |

## sram94

| name | verdict |
|---|---|
| ClearSRAM | ok |
| InitSaveRAM | ok |
| MakeSRAMChecksum | ok |
| ReadSRAM | ok |
| SRAMWaitVblank | ok |
| ValidateSRAM | ok |
| WriteSRAM | ok |

## replay94

| name | verdict |
|---|---|
| ClampReplayView | ok |
| EraseReplayBanner | ok |
| EraseReplayIcon | ok |
| RevReplayAdj | ok |
| ShowReplayBanner | ok |
| ShowReplayIcon | ok |
| rtss8 | ok |

## fourway94

| name | verdict |
|---|---|
| Detect4WayPlay | ok |
| ReadJoySwapPad1 | ok |
| ReadJoySwapPad2 | ok |
| ReadJoySwapPad3 | ok |
| ReadJoySwapPad4 | ok |
| Set4WayPlayer | ok |
| Set4WayPlayerStub | ok |

## onetimer94

| name | verdict |
|---|---|
| CheckOneTimerFacing | ok |
| OneTimerFarTbl | ok |
| OneTimerGoalieTbl | ok |
| OneTimerNearTbl | ok |
| OneTimerPass | ok |
| OneTimerTarget | ok |
| PuckOnAttackHalf | ok |
| assonetimer | ok |
| onetimershot | ok |
| puckvzadj | ok |
| setonetimeranim | ok |

## input94

| name | verdict |
|---|---|
| ClampTargetY | ok |
| doinput_cbut | ok |
| doinput_chkanim | ok |
| doinput_islocked | ok |
| doinput_ispc | ok |
| doinput_onetimer | ok |
| getGoalieSCnum | ok |
| passto | ok |
| prepshot | ok |
| rtss15 | ok |
| rtss3 | ok |
| rtss7 | ok |
| shotsets | ok |

## data94

| name | verdict |
|---|---|
| FormatLastName | ok |
| FormatPlayerNameLast | ok |
| GAttribOverall | ok |
| GAttribOverallMask | ok |
| GoalBigTxt | ok |
| PAttribOverall | ok |
| PAttribOverallMask | ok |
| PPGoalBigTxt | ok |
| PauseMenuItems | ok |
| PenShotBigTxt | ok |
| PenShotPenalties | ok |
| PenaltyShotBox | ok |
| PerLabels2 | renamed from PenShotPenalties2 |
| ShootoutIntermissionMenu | ok |
| defmenuoptions | ok |

## goalie94

| name | verdict |
|---|---|
| ArenaAnims | ok |
| ArenaFrames1 | ok |
| ArenaFrames2 | ok |
| ArenaFrames3 | ok |
| ArenaFrames4 | ok |
| ArenaFrames5 | ok |
| ArenaFrames6 | ok |
| ArenaFrames7 | ok |
| ArenaFrames8 | ok |
| EndArenaAnim | ok |
| ManualGoalieMenu | ok |
| NextArenaFrame | ok |
| RunArenaAnim | ok |
| SetCameraTop | ok |
| SetFaceoffAnim | ok |
| StartArenaAnim | ok |

## crowd94

| name | verdict |
|---|---|
| AttributeCalc | ok |
| BuildHotColdLists | ok |
| Clamp0to100 | ok |
| CompareHotColdTotals | ok |
| CopyColdestPlayer | ok |
| CopyHottestPlayer | ok |
| Create_HotCold_Table | ok |
| Crowd_Noise | ok |
| GetHotColdTotal | ok |
| HotColdLoop | ok |
| LoadCrowdRec | ok |
| NextAwayColdPlayer | ok |
| NextAwayHotPlayer | ok |
| NextHomeColdPlayer | ok |
| NextHomeHotPlayer | ok |
| SortHotColdStarters | ok |
| checkcornercoll | ok |
| cornercollb | ok |
| stopna2 | ok |

## records94

| name | verdict |
|---|---|
| CalcWinPercents | ok |
| ClearRecordArea | ok |
| GoalRecTitles | ok |
| PrintPlayerRecords | ok |
| PrintRecordName | ok |
| PrintRecordPage | ok |
| PrintRecordTitles | ok |
| PrintWinRecords | ok |
| ReadTeamRecords | ok |
| RecHolderByTxt | ok |
| RecHolderVsTxt | ok |
| RecParenTxt | ok |
| RecordHoldersScreen | ok |
| SaveRecTitles | ok |
| ShootoutModeBigTxt | renamed from RoundBigTxt |
| ShootoutModeBox | renamed from PlayoffRoundScreen |
| SkipOtherUserName | ok |
| UserNameEntry | ok |
| WinRecTitles | ok |

## checks94

| name | verdict |
|---|---|
| BreakawayOffsidesFlagSet | ok |
| EndPenaltyShotPlay | ok |
| PenaltyShotEndReturn | ok |
| SelectPenaltyShotSkater | ok |
| SetFaceoffComputerLine | ok |
| SkateToTempTarget | ok |
| StartFaceoffLineChange | ok |
| UpdateFaceoffLineChangeTimer | ok |
| UpdatePenaltyShotEnd | ok |
| WaitForFaceoffLineChanges | ok |
| assbreakaway | ok |
| assgoaliecpu | ok |
| assgoaliectrl | ok |
| breakaway | ok |
| checkanim | ok |
| chkpuckc | ok |
| goaliesave | ok |
| puckpenshot | ok |
| puckshootout | ok |
| rtss11 | ok |

## period94

| name | verdict |
|---|---|
| AddArenaAnimSprite | ok |
| ClampPositionBox | ok |
| ClearGameStats | ok |
| EndShootout | ok |
| GetTeamRating | ok |
| PeriodStatsScreen | ok |
| PositionBoxes | ok |
| PositionBoxesTop | ok |
| PrintPlayerNameRight | ok |
| PrintStatScrollArrows | ok |
| SetStatScroll | ok |
| ShortenMsgTimer | ok |
| SkipNameNumber | ok |
| StatScrollRow | ok |
| StatScrollRowEnd | ok |
| TeamRatings | ok |
| TeamStatTextTblNoPen | ok |
| rtsStatScroll | ok |
| rtsStatTables | ok |
| updatePPTeamTime | ok |

## shootout94

| name | verdict |
|---|---|
| ClearShooterScreen | ok |
| ClearShootout | ok |
| CountShootoutGoals | ok |
| InitShooters | ok |
| NextShooter | ok |
| PrintShooterBox | ok |
| PrintShooterList | ok |
| PrintShooterNames | ok |
| PrintShooterSlots | ok |
| ResetShooterScroll | ok |
| ShooterOverallTxt | ok |
| ShooterOverallTxt2 | ok |
| ShooterSelectList | ok |
| ShootersBackground | ok |
| ShootersExit | ok |
| ShootersLoop | ok |
| ShootersMove | ok |
| ShootersPick | ok |
| ShootersRedraw | ok |
| ShootersSelect | ok |
| ShootoutShooters | ok |
| ShootoutWonBy | ok |

## frames94

| name | verdict |
|---|---|
| SPAboardbot | ok |
| SPAboardbot_table | ok |
| SPAboardchk | ok |
| SPAboardchk_table | ok |
| SPAboardleft | ok |
| SPAboardleft_table | ok |
| SPAboardmidl | ok |
| SPAboardmidl_table | ok |
| SPAboardmidr | ok |
| SPAboardmidr_table | ok |
| SPAboardright | ok |
| SPAboardright_table | ok |
| SPAboardtop | ok |
| SPAboardtop_table | ok |
| SPAghighl | ok |
| SPAghighl_table | ok |
| SPAghighr | ok |
| SPAghighr_table | ok |
| SPAgslambot | ok |
| SPAgslambot_table | ok |
| SPAgslamtop | ok |
| SPAgslamtop_table | ok |
| SPAgstick2l | ok |
| SPAgstick2l_table | ok |
| SPAgstick2r | ok |
| SPAgstick2r_table | ok |
| SPAinjuryfall | ok |
| SPAinjuryfall_table | ok |

## scout94

| name | verdict |
|---|---|
| DrawMatchupBitmap | ok |
| DrawMatchupLogo | ok |
| DrawMatchupPicture | ok |
| DrawMatchupPictures | ok |
| EvenAdvTxt | ok |
| GetMatchupPlayer | ok |
| GetMatchupPlayers | ok |
| GetTeamArena | ok |
| GetTeamCity | ok |
| GetTeamLogo | ok |
| GetTeamNickname | ok |
| HomeAdv0Txt | ok |
| HomeAdv1Txt | ok |
| HomeAdv2Txt | ok |
| HomeAdv3Txt | ok |
| HomeAdvMarks | ok |
| HomeTxt | ok |
| MatchupLineSlots | ok |
| MatchupPosNames | ok |
| PageMatchup | ok |
| PrintAdvantageMarks | ok |
| PrintMatchupRating | ok |
| PrintMatchupRatings | ok |
| PrintTwoSpaces | ok |
| RestartAdvantageMarks | ok |
| ScoutByTxt | ok |
| ScoutCrowdRecord | ok |
| ScoutCrowdRecordBy | ok |
| ScoutEmptyTxt | ok |
| ScoutSpaceTxt | ok |
| ScoutStub | ok |
| TwoSpacesTxt | ok |
| VisAdv0Txt | ok |
| VisAdv1Txt | ok |
| VisAdv2Txt | ok |
| VisAdv3Txt | ok |
| VisAdvMarks | ok |
| VisitorsTxt | ok |

## optsetup94

| name | verdict |
|---|---|
| BlankValueTxt | ok |
| ChangeOption | ok |
| CheckNOPUnused | ok |
| DrawHomeBlock | ok |
| DrawLogoBox | ok |
| DrawTeamLogo | ok |
| DrawVisBlock | ok |
| EraseCard | ok |
| FixModeOptions | ok |
| GameSetUp | ok |
| GoContinuePlayoffs | ok |
| GoNewPlayoffs | renamed from j_NewPO |
| GoaliesValues | ok |
| IslandersTxt | ok |
| LineChangeValues | ok |
| LoadSetupTiles | ok |
| LogoBoxHome | ok |
| LogoBoxLeft | ok |
| LogoBoxRight | ok |
| LogoBoxVis | ok |
| MoveMenuFrame | ok |
| NATxt | ok |
| OptionLimits | ok |
| OptionLimits4Way | ok |
| OptionNames | ok |
| OptionValueOffsets | ok |
| PenaltiesValues | ok |
| PerLengthValues | ok |
| PlayModeValues | ok |
| PlayerCardScreen | ok |
| PlayerCardTimer | ok |
| PlayersValues | ok |
| PrintOptTeamName | ok |
| PrintOptionNames | ok |
| PrintOptionValue | ok |
| PrintOptions | ok |
| PrintScrollMarks | ok |
| RangersTxt | ok |
| ReadSetupPads | ok |
| ResetCardTimer | ok |
| ScrollClearTxt | ok |
| ScrollDownTxt | ok |
| ScrollUpTxt | ok |
| SetFrameRect | ok |
| SetFrameRectUnused | ok |
| SetMenuArea | ok |
| SetupDemo | ok |
| SetupStart | ok |
| TeamLogoBitmaps | ok |
| UserRecValues | ok |
| WrapOption | ok |
| rtsSetup | ok |

## title94

| name | verdict |
|---|---|
| AttribAdjust | ok |
| CheckScoreLeader | ok |
| ChooseSong | ok |
| ClearLeadSong | ok |
| ClearPenalties | ok |
| ClearWinRecords | ok |
| CountButtonPress | ok |
| CreditsLineScroll | ok |
| CreditsPrintRow | ok |
| CreditsScrollStep | ok |
| CreditsWait | ok |
| DrawPlayoffSprite | ok |
| EndOneTimer | ok |
| FaceoffAnims | ok |
| GetLeagueCrowdRecord | ok |
| GetTeamStruct | ok |
| HiScoreScreen | ok |
| HotColdIcon | ok |
| LeadSong | ok |
| LeadSongExit | ok |
| LoadHomeTeamGfx | ok |
| NextPathPoint | ok |
| PSandSOpassdir | ok |
| PlaceBoardFall | ok |
| PlayedByAway | ok |
| PlayedByEmptyTxt | ok |
| PlayedByExit | ok |
| PlayedByHome | ok |
| PlayedByNone | ok |
| PlayedByText | ok |
| PlayedByTxt | ok |
| PrintParenNumber | ok |
| PrintPlayerAssists | ok |
| PrintPlayerGoals | ok |
| PuckComingToward | ok |
| RandomFaceoffAnim | ok |
| RandomSongs | ok |
| ReadGoaliePulled | ok |
| ReadLineData | ok |
| SetSflags8Bit1 | ok |
| ShootoutPath1 | ok |
| ShootoutPath2 | ok |
| ShootoutPath3 | ok |
| ShootoutPath4 | ok |
| ShootoutPath5 | ok |
| ShootoutPath6 | ok |
| ShootoutPath7 | ok |
| ShootoutPaths | ok |
| ShootoutShootCheck | ok |
| SkatePath | ok |
| StartShootoutPath | ok |
| TeamGfxList | ok |
| TeamLogoPalettes | ok |
| TeamSongs | ok |
| TerminateLogName | ok |
| UnpackPicture | ok |
| WriteLineData | ok |
| chgplayer | ok |
| chkFgtBit1 | ok |
| clrTmPdst | ok |
| getFgtbyte | ok |
| j_setc1player | ok |
| j_setc2player | ok |
| newTitleScreen | ok |
| passdirlist | ok |
| rtsChgplayer | renamed from exit |
| swpchk | ok |

## sound94

| name | verdict |
|---|---|
| PadDirTable | ok |
| ReadJoyData | ok |
| ReadPad1 | ok |
| ReadPad2 | ok |
| ReadPad3Button | ok |
| ReadPad4Way1 | ok |
| ReadPad4Way2 | ok |
| ReadPad4Way3 | ok |
| ReadPad4Way4 | ok |
| ReadPad4WayPort1 | ok |
| ReadPadA0 | ok |
| ResetZ80Bus | ok |
| SetChannelVolume | ok |
| SongPointerTable | ok |
| fmtune_id_30_cmdstream | ok |
| fmtune_id_31_cmdstream | ok |
| fmtune_id_32_cmdstream | ok |
| fmtune_id_33_cmdstream | ok |
| fmtune_id_34_cmdstream | ok |
| fmtune_id_35_cmdstream | ok |
| fmtune_id_36_cmdstream | ok |
| fmtune_id_37_cmdstream | ok |
| fmtune_id_38_cmdstream | ok |
| fmtune_id_39_cmdstream | ok |
| fmtune_id_3A_cmdstream | ok |
| fmtune_id_3B_cmdstream | ok |
| fmtune_id_3C_cmdstream | ok |
| fmtune_id_3D_cmdstream | ok |
| fmtune_id_3E_cmdstream | ok |
| fmtune_id_3F_cmdstream | ok |
| fmtune_id_40_cmdstream | ok |
| fmtune_id_41_cmdstream | ok |
| fmtune_id_42_cmdstream | ok |
| fmtune_id_43_cmdstream | ok |
| fmtune_id_44_cmdstream | ok |
| fmtune_id_45_cmdstream | ok |
| fmtune_id_46_cmdstream | ok |
| fmtune_id_47_cmdstream | ok |
| fmtune_id_48_cmdstream | ok |
| fmtune_id_49_cmdstream | ok |
| fmtune_id_4A_cmdstream | ok |
| fmtune_id_4B_cmdstream | ok |
| fmtune_id_4C_cmdstream | ok |
| fmtune_id_4D_cmdstream | ok |
| fmtune_id_4E_cmdstream | ok |
| fmtune_id_4F_cmdstream | ok |
| fmtune_id_50_cmdstream | ok |
| fmtune_id_51_cmdstream | ok |
| fmtune_id_52_cmdstream | ok |
| fmtune_id_53_cmdstream | ok |
| fmtune_id_54_cmdstream | ok |
| fmtune_id_55_cmdstream | ok |
| fmtune_id_56_cmdstream | ok |
| fmtune_id_57_cmdstream | ok |
| fmtune_id_58_cmdstream | ok |
| fmtune_id_59_cmdstream | ok |
| fmtune_id_5A_cmdstream | ok |
| fmtune_id_5B_cmdstream | ok |
| fmtune_id_5C_cmdstream | ok |
| fmtune_id_5D_cmdstream | ok |
| fmtune_id_5E_cmdstream | ok |
| fmtune_id_5F_cmdstream | ok |
| fmtune_id_60_cmdstream | ok |
| fmtune_id_61_cmdstream | ok |
| fmtune_id_62_cmdstream | ok |
| fmtune_id_63_cmdstream | ok |
| fmtune_id_64_cmdstream | ok |
| fmtune_id_65_cmdstream | ok |
| fmtune_id_66_cmdstream | ok |
| fmtune_id_67_cmdstream | ok |
| fmtune_id_68_cmdstream | ok |
| fmtune_id_69_cmdstream | ok |
| fmtune_id_6A_cmdstream | ok |
| fmtune_id_6B_cmdstream | ok |
| fmtune_id_6C_cmdstream | ok |
| fmtune_id_6D_cmdstream | ok |
| fmtune_id_6E_cmdstream | ok |
| fmtune_id_6F_cmdstream | ok |
| fmtune_id_70_cmdstream | ok |
| fmtune_id_71_cmdstream | ok |
| fmtune_id_72_cmdstream | ok |
| fmtune_id_73_cmdstream | ok |
| fmtune_id_74_cmdstream | ok |
| fmtune_id_75_cmdstream | ok |
| fmtune_id_76_cmdstream | ok |
| fmtune_id_77_cmdstream | ok |
| handle_command_30 | ok |
| rtscmd10 | ok |
| rtsfx | ok |

## cards94

| name | verdict |
|---|---|
| AppendNumber | ok |
| AppendRecordHolder | ok |
| AppendRecordVs | ok |
| AppendTeamName | ok |
| AppendUserName | ok |
| AttribWgtList | ok |
| BuildCardPlayerList | ok |
| BuildCardPlayerLists | ok |
| CalcAttrib | ok |
| CardEmptyTxt | ok |
| CardGoalsByTxt | ok |
| CardGoalsTxt | ok |
| CardSavesByTxt | ok |
| CardSavesTxt | ok |
| CardStub | ok |
| CardVsTxt | ok |
| ClearCardText | ok |
| CopyString | renamed from StartText |
| CountGoalies | ok |
| CountPlayers | ok |
| CrowdLevelTxt | ok |
| CrowdRecordIO | ok |
| DrawPictureBox | ok |
| DrawPlayerCard | ok |
| DrawPlayerPicture | ok |
| EnterNameTxt | ok |
| FeaturedPictures | ok |
| FindLetter | ok |
| GetCardPlayer | ok |
| GetCardTeam | ok |
| GetJerseyString | ok |
| GetLogName | ok |
| GetNameLength | ok |
| GetRecordValue | ok |
| LetterGrid | ok |
| LetterGridPos | ok |
| LinePosNames | ok |
| LogArrowsClrTxt | ok |
| LogArrowsTxt | ok |
| MoveLogArrows | ok |
| NameEntryFramer | ok |
| NameEntryHelp | ok |
| NameEntryScreen | ok |
| NameLetterGrid | ok |
| NameLogIO | ok |
| NoNameTxt | ok |
| OvrGoalWgtList | ok |
| OvrPlayerWgtList | ok |
| PlayerCards | ok |
| PlayerRecordIO | ok |
| PlayerRecordOffsets | ok |
| PrintCardPosition | ok |
| PrintCardRecordLine | ok |
| PrintCardRecords | ok |
| PrintCardTeam | ok |
| PrintCentered | ok |
| PrintCrowdRecordLine | ok |
| PrintCurLetter | ok |
| PrintGoalRecordLine | ok |
| PrintGoalsAssists | ok |
| PrintLogArrows | ok |
| PrintNameCursor | ok |
| PrintNameField | ok |
| PrintNameLog | ok |
| PrintNamePrompt | ok |
| PrintOverallRating | ok |
| PrintRecordHolder | ok |
| PrintRecordValue | ok |
| PrintRecordVs | ok |
| PrintSaveRecordLine | ok |
| PrintSaves | ok |
| PrintStartingLine | ok |
| PrintTeamRating | ok |
| ReadCrowdRecord | ok |
| ReadNameLog | ok |
| ReadPlayerRecord | ok |
| ReadTeamRecord | ok |
| RecByTxt | ok |
| RecGoalTxt | ok |
| RecGoalsTxt | ok |
| RecSaveTxt | ok |
| RecSavesTxt | ok |
| RecSpaceTxt | ok |
| RecVsTxt | ok |
| RecordTxt | ok |
| SelectNameTxt | ok |
| StoreUserName | ok |
| SyncLetterCursor | ok |
| TeamPalettes | ok |
| TeamRecordIO | ok |
| TrimSpaces | ok |
| UpdateCrowdRecord | ok |
| UpdatePlayerRecords | ok |
| UpdateRecords | ok |
| UpdateTeamRecord | ok |
| WrapCardIndex | ok |
| WriteCrowdRecord | ok |
| WriteNameLog | ok |
| WriteNameRecord | ok |
| WritePlayerRecord | ok |
| WriteTeamRecord | ok |
| rtsNameCursor | ok |
| setSlotBit | ok |
| wallcollduringcheck | ok |

## graphics94

| name | verdict |
|---|---|
| ArenaGfxBank | ok |
| CardAdamOates | ok |
| CardAlIafrate | ok |
| CardAlMacInnis | ok |
| CardAlexeiZhamnov | ok |
| CardAlexnderMogilny | ok |
| CardAlexnderSemak | ok |
| CardAndrewCassels | ok |
| CardAndyMoog | ok |
| CardArtursIrbe | ok |
| CardBenoitHogue | ok |
| CardBillRanford | ok |
| CardBobBeers | ok |
| CardBobEssensa | ok |
| CardBobKudelski | ok |
| CardBradShaw | ok |
| CardBrendanShanahan | ok |
| CardBrettHull | ok |
| CardBrianBellows | ok |
| CardBrianBradley | ok |
| CardBrianLeetch | ok |
| CardCamNeely | ok |
| CardChrisChelios | ok |
| CardChrisKontos | ok |
| CardChrisTerreri | ok |
| CardClaudeLemieux | ok |
| CardCliffRonning | ok |
| CardCraigJanney | ok |
| CardCurtisJoseph | ok |
| CardCurtisLeschyshyn | ok |
| CardDaleHawerchuk | ok |
| CardDariusKasparitis | ok |
| CardDaveAndreychuk | ok |
| CardDaveEllett | ok |
| CardDaveGagner | ok |
| CardDaveManson | ok |
| CardDimitriKhristich | ok |
| CardDimitriYushkevich | ok |
| CardDinoCiccarelli | ok |
| CardDonBeaupre | ok |
| CardDonSweeney | ok |
| CardDougBodger | ok |
| CardDougGilmour | ok |
| CardDougLidster | ok |
| CardDougWeight | ok |
| CardDougWilson | ok |
| CardEdBelfour | ok |
| CardEricDesjardins | ok |
| CardEricLindros | ok |
| CardEricWeinrich | ok |
| CardEsaTikkanen | ok |
| CardFelixPotvin | ok |
| CardGarryGalley | ok |
| CardGarthButcher | ok |
| CardGaryRoberts | ok |
| CardGarySuter | ok |
| CardGeoffCourtnall | ok |
| CardGeoffSanderson | ok |
| CardGlennHealy | ok |
| CardGrantFuhr | ok |
| CardIgorKravchuk | ok |
| CardJamesPatrick | ok |
| CardJamieBaker | ok |
| CardJaromirJagr | ok |
| CardJeffBrown | ok |
| CardJeremyRoenick | ok |
| CardJoeJuneau | ok |
| CardJoeNieuwendyk | ok |
| CardJoeSakic | ok |
| CardJohanGarpenlov | ok |
| CardJohnVanbiesbrk | ok |
| CardJonCasey | ok |
| CardJyrkiLumme | ok |
| CardKellyHrudey | ok |
| CardKellyKisio | ok |
| CardKevinHatcher | ok |
| CardKevinStevens | ok |
| CardKirkMcLean | ok |
| CardKirkMuller | ok |
| CardLarryMurphy | ok |
| CardLucRobitaille | ok |
| CardMarioLemieux | ok |
| CardMarkMessier | ok |
| CardMarkRecchi | ok |
| CardMarkTinordi | ok |
| CardMartyMcSorley | ok |
| CardMatsSundin | ok |
| CardMattSchneider | ok |
| CardMichelGoulet | ok |
| CardMikaelAndersson | ok |
| CardMikeGartner | ok |
| CardMikeModano | ok |
| CardMikeRidley | ok |
| CardMikeVernon | ok |
| CardNeilWilkinson | ok |
| CardNikolaiBorshevsky | ok |
| CardNormMaciver | ok |
| CardOwenNolan | ok |
| CardPatFalloon | ok |
| CardPatLaFontaine | ok |
| CardPatVerbeek | ok |
| CardPatrickRoy | ok |
| CardPaulCoffey | ok |
| CardPavelBure | ok |
| CardPeterBondra | ok |
| CardPeterSidorkwicz | ok |
| CardPetrKlima | ok |
| CardPetrSvoboda | ok |
| CardPhilHousley | ok |
| CardPierreTurgeon | ok |
| CardRayBourque | ok |
| CardRobBlake | ok |
| CardRodBrindAmour | ok |
| CardRomanHamrlik | ok |
| CardRonHextall | ok |
| CardRussCourtnall | ok |
| CardScottStevens | ok |
| CardSeanBurke | ok |
| CardSergeiFedorov | ok |
| CardShayneCorson | ok |
| CardStephaneRicher | ok |
| CardSteveChiasson | ok |
| CardSteveDuchesne | ok |
| CardSteveLarmer | ok |
| CardSteveSmith | ok |
| CardSteveThomas | ok |
| CardSteveYzerman | ok |
| CardSylvainTurgeon | ok |
| CardTeemuSelanne | ok |
| CardTeppoNumminen | ok |
| CardTheorenFleury | ok |
| CardThomasSteen | ok |
| CardTimCheveldae | ok |
| CardToddGill | ok |
| CardTomBarrasso | ok |
| CardTomasSandstrom | ok |
| CardTommySjodin | ok |
| CardTommySoderstrom | ok |
| CardUlfSamuelsson | ok |
| CardVachslavFetisov | ok |
| CardVincentDamphousse | ok |
| CardVladimirMalakhov | ok |
| CardWayneGretzky | ok |
| CardWendellYoung | ok |
| CardZarleyZalapski | ok |
| ColdIconMap | ok |
| CornerLogoMap | ok |
| CrowdFrameList | ok |
| EASportsMap | ok |
| GameSetUpMap2 | ok |
| HiScoreImg | ok |
| HorRinkMap | ok |
| HorRinkTiles | ok |
| HotIconMap | ok |
| LogoBoxMap | ok |
| NHLShieldImg | ok |
| NoPicGoalie1 | ok |
| NoPicGoalie2 | ok |
| NoPicSkater1 | ok |
| NoPicSkater2 | ok |
| PAlogoImg | ok |
| PicturePalette | ok |
| PlayerCardsScreenPic | ok |
| PlayoffSprite | ok |
| PrintFont2Map | ok |
| ReplayMap | ok |
| RevRinkTilelist | ok |
| RevRinkTiles | ok |
| Rinktilelist | ok |
| Rinktiles | ok |
| ScoutTextScript | ok |
| SetupFramerMap | ok |
| SetupMenuMap | ok |
| TeamBitmaps | ok |
| TitleImg | ok |
| TitleScreenImg | ok |
| frameSprData | ok |
| logoANH | ok |
| logoASE | ok |
| logoASW | ok |
| logoBOS | ok |
| logoBUF | ok |
| logoCGY | ok |
| logoCHI | ok |
| logoDAL | ok |
| logoDET | ok |
| logoEDM | ok |
| logoFLA | ok |
| logoHFD | ok |
| logoLA | ok |
| logoMTL | ok |
| logoNJ | ok |
| logoNYI | ok |
| logoNYR | ok |
| logoOTW | ok |
| logoPHI | ok |
| logoPIT | ok |
| logoQUE | ok |
| logoSJ | ok |
| logoSTL | ok |
| logoTB | ok |
| logoTOR | ok |
| logoVAN | ok |
| logoWPG | ok |
| logoWSH | ok |
| revframetbl | ok |

## RAM names (src/stubinc/ram_addrs.inc), checked by usage
| name | verdict |
|---|---|
| AwGoals | ok |
| AwShots | ok |
| BA_Checker_Offset | ok |
| BA_Goalie_Offset | ok |
| BA_Goalie_SCnum | ok |
| BA_PS_flags | ok |
| BA_Skater_Offset | ok |
| BA_Sktr_SCnum | ok |
| BA_Team | ok |
| ChkBodyG | ok |
| ChkBodySqG | ok |
| CrowdAvg | ok |
| CrowdPeak | ok |
| CrowdRecord | ok |
| CurCrowdMeter | ok |
| CwdChkCnt | ok |
| CwdChkCntr | ok |
| DelayedPen | ok |
| FallXPos | ok |
| FallYPos | ok |
| FourWayPlay | ok |
| HmGoals | ok |
| HmTeam | ok |
| Joy1Struct | ok |
| Joy3Struct | ok |
| Joy4Struct | ok |
| Map1col1 | ok |
| Map2col1 | ok |
| Map3col1 | ok |
| NegChkBodyG | ok |
| Opt1Team | ok |
| Opt2Team | ok |
| OptGoalie | ok |
| OptUserRec | ok |
| OvrDividend | ok |
| OvrDivisor | ok |
| PALflag | ok |
| PadControlBits34 | ok |
| PlayerChked | ok |
| PlayerChking | ok |
| PuckZCntr | ok |
| ReplayStarStruct | ok |
| SongIndex | ok |
| SongNum | ok |
| TempBuffer | kept: multi-use scratch |
| TempEnergySpd | ok |
| TempLegSpd | ok |
| TempMaxSpd | kept: multi-use scratch |
| TempOptPlayMode | ok |
| TempRawSpd | ok |
| TempWord1 | kept: multi-use scratch |
| TempWord2 | kept: multi-use scratch |
| ThreeStars | kept: multi-use scratch |
| TmpJoyPuckCarrier | ok |
| TmpOptLine | ok |
| TmpOptLine2 | ok |
| TmpOptPen | ok |
| TmpOptUserRec | ok |
| TmpPuckX | ok |
| TmpPuckZ | ok |
| ValidSRAM | ok |
| Z80_YM2612 | ok (unreferenced) |
| advcount | ok |
| advframe | ok |
| aholdtimer | ok |
| aholdtimer34 | ok |
| arenaanim | ok |
| arenaanimchars | ok |
| arenaframe | ok |
| arenaframeidx | ok |
| arenaframelist | ok |
| arenaframetime | ok |
| arenaspritelist | ok |
| awaycardidx | ok |
| awaycardlist | ok |
| awaycoldidx | ok |
| awaycoldplayer | ok |
| awaydirpresses | ok |
| awaygoalies | ok |
| awayhotcoldsave | ok |
| awayhotidx | ok |
| awayhotplayer | ok |
| awayhotter | ok |
| awayplayers | ok |
| awaypresses | ok |
| awayshooters | ok |
| awayshootgoals | ok |
| awayuser | ok |
| bholdtimer | ok |
| bholdtimer34 | ok |
| c3playernum | ok |
| c4playernum | ok |
| cardcount | ok |
| carddelay | ok |
| cardindex | ok |
| cardlogochars1 | ok |
| cardlogochars2 | ok |
| cardplayer | ok |
| cardprintx | ok |
| cardprinty | ok |
| cardroster | ok |
| cardteamnum | ok |
| cardtimer | ok |
| cardvis | ok |
| coldiconchars | ok |
| cont3team | ok |
| cont4team | ok |
| crowdnoisedelay | ok |
| cursoron | ok |
| delayedsong | ok |
| facelcwait | ok |
| faceoffanim | ok |
| featuredplayer | ok |
| fm_channel_struct6 | ok |
| gmode2 | ok |
| goaliemode1 | ok |
| goaliemode2 | ok |
| gsstruct | ok |
| holdreset | ok |
| homecardidx | ok |
| homecardlist | ok |
| homecoldidx | ok |
| homecoldplayer | ok |
| homedirpresses | ok |
| homegoalies | ok |
| homehotcoldsave | ok |
| homehotidx | ok |
| homehotplayer | ok |
| homepicchars | ok |
| homeplayers | ok |
| homepresses | ok |
| homerating | ok |
| homeshooters | ok |
| homeshootgoals | ok |
| homeshootnum | ok |
| homeuser | ok |
| hoticonchars | ok |
| iconplayer | ok |
| iconx | ok |
| inputjoy | ok |
| joypuckcarrier | ok |
| lj3 | ok |
| lj4 | ok |
| lognametext | ok |
| logobox1chars | ok |
| logobox2chars | ok |
| logoteam | ok |
| matchup | ok |
| matchuphome | ok |
| matchupslot | ok |
| matchuptimer | ok |
| matchupvis | ok |
| msgtimer | ok |
| nameentrybuf | ok |
| nameentryvis | ok |
| nameframechars | ok |
| namelength | ok |
| namelog | ok |
| namelogarrows | ok |
| namelogsel | ok |
| onetimerclock | ok |
| onetimerflags | ok |
| onetimerheight | ok |
| onetimerplayer | ok |
| onetimertargetx | ok |
| onetimertargety | ok |
| pad4way1 | ok |
| pad4way2 | ok |
| pad4way3 | ok |
| pad4way4 | ok |
| pad4waysave1 | ok |
| pad4waysave2 | ok |
| pad4waysave3 | ok |
| pad4waysave4 | ok |
| pad4wayword | ok |
| padword1 | ok |
| padword2 | ok |
| padword3 | ok |
| padword4 | ok |
| passmodetimer | ok |
| passplayer | ok |
| pausepad | ok |
| picturebits | ok |
| picturebuf | ok |
| pspenalty | ok |
| puck_pflags2 | ok |
| puckcross2 | ok |
| puckcross4 | ok (unreferenced) |
| puckcross6 | ok |
| puckx_nopuck | ok |
| reclosses | ok |
| recsort1 | ok |
| recsort2 | ok |
| recties | ok |
| recwins | ok |
| replaydelay | ok |
| replayicontimer | ok |
| savednewpnum | ok |
| scorergoalies | ok |
| scoutunused | ok |
| scoutwait | ok |
| setupcardflags | ok |
| setupfirstline | ok |
| setupfontchars | ok |
| setuphome | ok |
| setupmenuchars | ok |
| setupprevline | ok |
| setupvis | ok |
| sflags4 | ok |
| sflags5 | ok |
| sflags6 | ok |
| sflags7 | ok |
| sflags8 | ok |
| shootoutclock | ok |
| shootoutdelay | ok |
| shootoutjiffy | ok |
| shootoutround | ok |
| shootoutstate | ok |
| shootoutteam | ok |
| songdelay | ok |
| sopath | ok |
| sopathdir | ok |
| sopathend | ok |
| sopathpoint | ok |
| sopathx | ok |
| sopathy | ok |
| sramcleared | ok |
| teambitmapchars | ok |
| teamrecbuf | ok |
| typedelay | ok |
| vispicchars | ok |
| visrating | ok |
| waitxpad | ok |
| wingames | ok |
| winpcts | ok |
| winsort | ok |
| winties | ok |

## Equates (src/stubinc/equals.inc)
| name | verdict |
|---|---|
| ANH | ok |
| ASE | ok |
| ASW | ok |
| BOS | ok |
| BUF | ok |
| CGY | ok |
| CHI | ok |
| DAL | ok |
| DET | ok |
| EDM | ok |
| FLA | ok |
| HFD | ok |
| LA | ok |
| MTL | ok |
| NJ | ok |
| NYI | ok |
| NYR | ok |
| OTW | ok |
| PHI | ok |
| PIT | ok |
| QUE | ok |
| SJ | ok |
| STL | ok |
| TB | ok |
| TOR | ok |
| TXHF | ok |
| TXMAP1 | ok |
| TXMAP2 | ok |
| TXMAP3 | ok |
| TXPAL1 | ok |
| TXPAL2 | ok |
| TXPAL3 | ok |
| TXPRI | ok |
| TXVF | ok |
| VAN | ok |
| WPG | ok |
| WSH | ok |
| checking | ok |
| fighting | ok |
| pf3break | ok |
| pf3fall | ok |
| pf3gctrl | ok |
| pf3onetimer | ok |
| pf3wall | ok |

## Local labels

| module | status |
|---|---|
| stats94, menu94 | 93G local names propagated (same routine structure) |
| hockey94 | Pausemode .loop from 93 |
| period94 | DisplayTeamStatsScreen .row from 93 |
| assign94, goalie94, hockey94, menu94, onetimer94, sram94, stats94 | new-in-94 routines read; locals named (asseben .nna as 92, ManualGoalieMenu, assscore shootout branch, ValidateSRAM .bad ...); routine names ok (ManualGoalieMenu, RunArenaAnim, NextArenaFrame, vcountwait, puckvzadj, PuckOnAttackHalf, ValidateSRAM, assgoaliebreakwait) |
