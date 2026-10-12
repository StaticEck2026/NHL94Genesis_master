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
