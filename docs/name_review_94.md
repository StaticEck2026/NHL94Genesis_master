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
