;	RAM map: the names and addresses of all game variables.

M68K_RAM equ $FFFF0000
sramcleared equ $FFFF1FFE
replayend equ $FFFFAF54	;end of the replay frames ($62 bytes each from M68K_RAM); suba4, adda43 and the record step wrap here
;$FFFFAFCA is SortCords-SCstruct
VSCRLPM equ $FFFFB000
VSPRITES equ $FFFFB002
VmMap1 equ $FFFFB004
Map1col1 equ $FFFFB006
VmMap2 equ $FFFFB008
Map2col1 equ $FFFFB00A
VmMap3 equ $FFFFB00C
Map3col1 equ $FFFFB00E
BigFontChars equ $FFFFB010
smallfontchars equ $FFFFB012
smallfont2chars equ $FFFFB014
energybarchars equ $FFFFB016
rinkvrcset equ $FFFFB018
animchars equ $FFFFB01A	;94 keeps the crowd tiles 1st vram char here
faceoffvrcset equ $FFFFB01C
framercset equ $FFFFB01E
EASNcset equ $FFFFB020
basetileoffset equ $FFFFB022
spritechars equ $FFFFB024
ExtraChars equ $FFFFB026
printx equ $FFFFB028
printy equ $FFFFB02A
printa equ $FFFFB02C
printm equ $FFFFB02E
printfontset equ $FFFFB030
fodropx equ $FFFFB032
fodropy equ $FFFFB034
recbpr equ $FFFFB036
vbint equ $FFFFB03A
vcount equ $FFFFB03E
oldvcount equ $FFFFB040
repeatdelayframes equ $FFFFB042
asv equ $FFFFB044
lldisp equ $FFFFB046
periodendtime equ $FFFFB048
SortCords equ $FFFFB04A
;$FFFFB066 is SortCords+OldXpos
;$FFFFB366 is SortCords+(6*SCstruct)+OldXpos
;$FFFFB5CA is SortCords+(11*SCstruct), the away goalie SCstruct
;$FFFFB64A is SortCords+(12*SCstruct)
;$FFFFB6CA is SortCords+(13*SCstruct)
puckx equ $FFFFB74A
;$FFFFB74E is SortCords+(puckscnum*SCstruct)+attribute
pucky equ $FFFFB75E
puckz equ $FFFFB762
puckvx equ $FFFFB772
puckvy equ $FFFFB774
puckvz equ $FFFFB776
;$FFFFB78A is SortCords+(puckscnum*SCstruct)+temp1
puckx_nopuck equ $FFFFB7A8
puckc equ $FFFFB7AA
;$FFFFB7AC is SortCords+(puckscnum*SCstruct)+pflags
puck_pflags2 equ $FFFFB7AD
;$FFFFB7CA is SortCords+((puckscnum+1)*SCstruct)
;$FFFFB7E2 is SortCords+((puckscnum+1)*SCstruct)+Zpos
;$FFFFB7E3 is SortCords+((puckscnum+1)*SCstruct)+Zpos+1
Ylist equ $FFFFB84A
OOlistpos equ $FFFFB86A
OOlist equ $FFFFB88A
crowdframe equ $FFFFB89A
crowdlevel equ $FFFFB89C
crowdstep equ $FFFFB89E
crowdcnt equ $FFFFB8A0
CwdExciteLvl equ $FFFFB8A2
MaxCwdExciteLvl equ $FFFFB8A4
NumCwdExciteLvl equ $FFFFB8A6
SumCwdExciteLvl equ $FFFFB8A8
zamx equ $FFFFB8AC
playoffspritex equ $FFFFB8AE
playoffspritey equ $FFFFB8B0
clampcounter equ $FFFFB8B2
DMAList equ $FFFFB8B4
DMAlistend equ $FFFFBD14
Vpos equ $FFFFBD18
Oldrow equ $FFFFBD1A
Hpos equ $FFFFBD1C
Hscroll equ $FFFFBD1E
Vscroll equ $FFFFBD20
wcradiusx equ $FFFFBD22
wcradiusy equ $FFFFBD24
palcount equ $FFFFBD26
palfadenew equ $FFFFBD28
;$FFFFBD36 is palfadenew+$E
;$FFFFBD4A is palfadenew+$22
;$FFFFBD4E is palfadenew+$26
;$FFFFBD52 is palfadenew+$2A
;$FFFFBD68 is palfadenew+$40
;$FFFFBD6A is palfadenew+$42
;$FFFFBD82 is palfadenew+$5A
;$FFFFBD88 is palfadenew+$60
;$FFFFBDA2 is palfadenew+$7A
fofdata2 equ $FFFFBDA8
;$FFFFBDAC is fofdata2+4
fofdata equ $FFFFBDB0
pads equ $FFFFBDB4
Joy1Struct equ $FFFFBDD0
ReplayStarStruct equ $FFFFBE08
replayactive equ $FFFFBE1E
Joy3Struct equ $FFFFBE24
Joy4Struct equ $FFFFBE40
glovestruct equ $FFFFBE5C
PadControlBits equ $FFFFBE78
padcont equ $FFFFBE7A
;$FFFFBE7E is padcont+4
;$FFFFBE82 is padcont+8
PadControlBits34 equ $FFFFBE86	;as PadControlBits, for pads 3 and 4 (4 way play)
sso equ $FFFFBE88
shotplayer equ $FFFFBED8
lastplayer equ $FFFFBEDA
passdir equ $FFFFBEDC
passspeed equ $FFFFBEDE
passplayer equ $FFFFBEE0
glovecords equ $FFFFBEE2
threat equ $FFFFBEE4
puckcross equ $FFFFBEE6
puckcross2 equ $FFFFBEE8
puckcross4 equ $FFFFBEEA
puckcross6 equ $FFFFBEEC
lj1 equ $FFFFBEEE
lj2 equ $FFFFBEF0
lj3 equ $FFFFBEF2
lj4 equ $FFFFBEF4
pad4way1 equ $FFFFBEF6
pad4way2 equ $FFFFBEF7
pad4way3 equ $FFFFBEF8
pad4way4 equ $FFFFBEF9
pad4wayword equ $FFFFBEFA	;the pad word the unused ReadJoySwapPad1-4 swap a pad's saved word into around ReadJoy1
pad4waysave1 equ $FFFFBEFE	;ReadJoySwapPad1 saved pad word
pad4waysave2 equ $FFFFBF00	;ReadJoySwapPad2 saved pad word
pad4waysave3 equ $FFFFBF02	;ReadJoySwapPad3 saved pad word
pad4waysave4 equ $FFFFBF04	;ReadJoySwapPad4 saved pad word
bholdtimer equ $FFFFBF06	;B button hold timers of pads 1 / 2 (one byte each); bholdtimer34 for pads 3 / 4
bholdtimer34 equ $FFFFBF08
padword3 equ $FFFFBF0A
padword4 equ $FFFFBF0C
padword1 equ $FFFFBF0E	;a pad 1 word swapped with padword3 for 4 way play (updateplayers)
padword2 equ $FFFFBF10	;a pad 2 word swapped with padword4 for 4 way play (updateplayers)
TempWord1 equ $FFFFBF12	;a scratch word (hot / cold totals, record page, button direction ...)
TempWord2 equ $FFFFBF14	;a scratch word (hot / cold totals, attribute number, credits step ...)
TempRawSpd equ $FFFFBF16
TempMaxSpd equ $FFFFBF18
TempEnergySpd equ $FFFFBF1C
TempLegSpd equ $FFFFBF1E
TempBuffer equ $FFFFBF20	;40 byte scratch buffer: String buffer (AppendNumber, names, "(played by NAME)"), hot / cold player, sum byte pairs
;$FFFFBF2A is TempBuffer+10, the 6th (coldest) SortHotColdStarters pair
scorergoalies equ $FFFFBF48
recties equ $FFFFBF4A
reclosses equ $FFFFBF4C
recwins equ $FFFFBF4E
awayhotter equ $FFFFBF50
setupfontchars equ $FFFFBF52
awayhotidx equ $FFFFBF54
homehotidx equ $FFFFBF56
awaycoldidx equ $FFFFBF58
homecoldidx equ $FFFFBF5A
awayhotplayer equ $FFFFBF5C	;the away team's hottest starter (BuildHotColdLists)
homehotplayer equ $FFFFBF5E	;the home team's hottest starter
awaycoldplayer equ $FFFFBF60	;the away team's coldest starter
homecoldplayer equ $FFFFBF62	;the home team's coldest starter
ChkBodyG equ $FFFFBF64
ChkBodySqG equ $FFFFBF66
NegChkBodyG equ $FFFFBF6A
onetimerplayer equ $FFFFBF6C
onetimerclock equ $FFFFBF6E
onetimerflags equ $FFFFBF76
disflags equ $FFFFBF78
ltplayer equ $FFFFBF7A
ltx equ $FFFFBF7C
lty equ $FFFFBF7E
iflags equ $FFFFBF80
icingPlayer equ $FFFFBF81
clockram equ $FFFFBF86
;$FFFFBF8C is clockram+6
xc1 equ $FFFFBF8E
yc1 equ $FFFFBF90
yleader equ $FFFFBF92
fox equ $FFFFBF94
foy equ $FFFFBF96
fodir1 equ $FFFFBF98
fodir2 equ $FFFFBF9A
deltax equ $FFFFBF9C
deltay equ $FFFFBF9E
collflag equ $FFFFBFA0
evalue equ $FFFFBFA2
mesarea equ $FFFFBFA4
TextBuffer equ $FFFFBFA6
;$FFFFBFC2 is mesarea+30
PushWidthBuf equ $FFFFC008
;$FFFFC00A is PushWidthBuf+2
PushNumberBuf equ $FFFFC010
redrawicons equ $FFFFC012
ltack equ $FFFFC014
lastsfx equ $FFFFC016
Satt equ $FFFFC018
Sattsize equ $FFFFC2E8
gmode equ $FFFFC2EA
sflags equ $FFFFC2EC
sflags2 equ $FFFFC2EE
sflags3 equ $FFFFC2F0
BA_PS_flags equ $FFFFC2F2
sflags4 equ $FFFFC2F4	;94 flag word: reverse angle replay (bits 4, 6, 7), slot, penalty shot goal ...
sflags5 equ $FFFFC2F6	;94 flag word: crowd noise on (bit 7), menu handler keeps its screen (bit 1), setup scroll (bit 2) ...
sflags6 equ $FFFFC2F8	;94 flag word: one-timer (bits 1, 2), slot (bit 5), save RAM write (bit 6), record value (bit 7) ...
gmode2 equ $FFFFC2FA	;94 game mode word, beside gmode: shootout (bit 0), shootout skater has the puck (bit 1), breakaway (bit 4) ...
sflags7 equ $FFFFC2FC	;94 flag byte: arena faceoff animation (bit 0), injury (bit 5), crowd meter broken (bit 6) ...
sflags8 equ $FFFFC2FE	;94 flag byte: penalty shot / shootout and one-timer bits
DelayedPen equ $FFFFC300
crowdnoisedelay equ $FFFFC304
CwdChkCntr equ $FFFFC306
CwdChkCnt equ $FFFFC308
CurCrowdMeter equ $FFFFC30E
CrowdRecord equ $FFFFC310
CrowdAvg equ $FFFFC312
CrowdPeak equ $FFFFC314
pausepad equ $FFFFC316
joypuckcarrier equ $FFFFC318
msgtimer equ $FFFFC31A
passmodetimer equ $FFFFC31C
savednewpnum equ $FFFFC31E
c1playernum equ $FFFFC320
c2playernum equ $FFFFC322
c3playernum equ $FFFFC324
c4playernum equ $FFFFC326
cont1team equ $FFFFC328
cont2team equ $FFFFC32A
cont3team equ $FFFFC32C
cont4team equ $FFFFC32E
HomeTeam equ $FFFFC330
VisTeam equ $FFFFC332
TeamBlockMap equ $FFFFC334	;Map word buffer for CopyTeamBlockMapData and PutTeamBlock
PenBuf equ $FFFFC3A4
Pencntdwn equ $FFFFC3E6
Penaltytimer equ $FFFFC3E8
PBnum equ $FFFFC3EA
InjCntDown equ $FFFFC3EC
penmsgtimer equ $FFFFC3EE
RefCnt equ $FFFFC3F0
RefStep equ $FFFFC3F2
RefPen equ $FFFFC3F4
RefRamMap equ $FFFFC3F6
gsp equ $FFFFC466
gameclock equ $FFFFC468
;$FFFFC46A is gameclock+2
PerTimeTotal equ $FFFFC46C
ChkCnt equ $FFFFC46E
TempPlOffset equ $FFFFC470
ScoreSumbytes equ $FFFFC472
ScoreSum equ $FFFFC474
PenSumLength equ $FFFFC5DC
PenSum equ $FFFFC5DE
tmstruct equ $FFFFC6CE
HmGoals equ $FFFFC6DA
;$FFFFC6E4 is HmShots+tmline
HomeTeamRosterPtr equ $FFFFC6EC
;$FFFFC6F4 is HmShots+tmgoalie
;$FFFFC6FE is HmShots+tmflags
;$FFFFC768 is HmShots+tmpdst+$34
AwShots equ $FFFFCA32
AwGoals equ $FFFFCA3E
;$FFFFCA48 is AwShots+tmline
AwayTeamRosterPtr equ $FFFFCA50
;$FFFFCA58 is AwShots+tmgoalie
;$FFFFCA62 is AwShots+tmflags
;$FFFFCACC is AwShots+tmpdst+$34
statsbuffer equ $FFFFCD96
gsstruct equ $FFFFCE66
;$FFFFCED6 is gsstruct+(7*$10)
gamenum equ $FFFFCEE6
postarts equ $FFFFCEE8
bosgames equ $FFFFCEEA
gamelevel equ $FFFFCEEC
potreeteam equ $FFFFCEEE
pojoy equ $FFFFCEF0
WinBits equ $FFFFCEF2
potree equ $FFFFCEF4
PlList equ $FFFFCF14
menuitem equ $FFFFCF20	;menu state: selected item, then (+2) first item shown
menulist equ $FFFFCF24
menudraw equ $FFFFCF28
TickerNum equ $FFFFCF2C
PPBonus equ $FFFFCF2E
PKBonus equ $FFFFCF2F
ThirdPBonus equ $FFFFCF30
HmAwBonus equ $FFFFCF31
callbackPtr equ $FFFFCF32
ThreeStars equ $FFFFCF36
;$FFFFCF38 is ThreeStars+2, the text after a String length word at ThreeStars
teamrecbuf equ $FFFFCFFE	;SRAM team record buffer: the 16 byte record of a team (ReadCrowdRecord), byte 8 crowd record, byte 9 its name number
nibblebuffer equ $FFFFD036
;$FFFFD03A is nibblebuffer+4
homeuser equ $FFFFD042
awayuser equ $FFFFD044
FourWayPlay equ $FFFFD046
OptPlayMode equ $FFFFD048
OptNOP equ $FFFFD04A
Opt1Team equ $FFFFD04C
Opt2Team equ $FFFFD04E
OptPerlen equ $FFFFD050
OptGoalie equ $FFFFD052
OptUserRec equ $FFFFD054
OptPen equ $FFFFD056
OptLine equ $FFFFD058
goaliemode1 equ $FFFFD05A
goaliemode2 equ $FFFFD05C
TmpOptUserRec equ $FFFFD05E
TmpOptPen equ $FFFFD060
TmpOptLine equ $FFFFD062
demoflag equ $FFFFD064
seed equ $FFFFD066
dmaram equ $FFFFD06A
PalMode equ $FFFFD06E
music_tick_divider equ $FFFFD070
TmpOptLine2 equ $FFFFD072
TempOptPlayMode equ $FFFFD074
databuffer equ $FFFFD076
pwddatabuffer equ $FFFFD088
outputbuffer equ $FFFFD092
tpassbits equ $FFFFD176
music_needs_z80_update equ $FFFFD180
Z80_command_buffer equ $FFFFD182
;$FFFFD186 is Z80_command_buffer+4
per_channel_attenuation_table equ $FFFFD187
per_channel_frequency_table equ $FFFFD18E
per_channel_patch_table equ $FFFFD19C
fm_voice_usage_table equ $FFFFD1A4
fm_channel_structs equ $FFFFD3A4
fm_channel_struct6 equ $FFFFD3CC
fm_track_slots equ $FFFFD3D4
BA_Team equ $FFFFD404
BA_Sktr_SCnum equ $FFFFD406
BA_Goalie_SCnum equ $FFFFD408
BA_Skater_Offset equ $FFFFD40A
BA_Goalie_Offset equ $FFFFD40C
BA_Checker_Offset equ $FFFFD40E
pspenalty equ $FFFFD410
holdreset equ $FFFFD412
onetimertargetx equ $FFFFD414
onetimertargety equ $FFFFD416
onetimerheight equ $FFFFD418
FallYPos equ $FFFFD41A
FallXPos equ $FFFFD41C
aholdtimer equ $FFFFD41E	;A button hold timers of pads 1 / 2 (one byte each); aholdtimer34 for pads 3 / 4
aholdtimer34 equ $FFFFD420
setupfirstline equ $FFFFD422
setupprevline equ $FFFFD424
setupmenuchars equ $FFFFD426
logoteam equ $FFFFD428
setuphome equ $FFFFD42A
setupvis equ $FFFFD42C
setupcardflags equ $FFFFD42E
homepicchars equ $FFFFD430
vispicchars equ $FFFFD432
cardroster equ $FFFFD434
logobox1chars equ $FFFFD436
logobox2chars equ $FFFFD438
teambitmapchars equ $FFFFD43A
cardtimer equ $FFFFD43C
featuredplayer equ $FFFFD43E
carddelay equ $FFFFD440
cardprintx equ $FFFFD442
cardprinty equ $FFFFD444
cardteamnum equ $FFFFD446
homegoalies equ $FFFFD448
awaygoalies equ $FFFFD44A
homeplayers equ $FFFFD44C
awayplayers equ $FFFFD44E
cardlogochars1 equ $FFFFD450
cardlogochars2 equ $FFFFD452
shootoutclock equ $FFFFD454
shootoutjiffy equ $FFFFD456
ValidSRAM equ $FFFFD458
namelog equ $FFFFD45A	;the user name log: $80 bytes from save RAM $DA0 (NameLogIO), 12 bytes per name, namelogsel the entry
nameentrybuf equ $FFFFD4DA
;$FFFFD4DC is nameentrybuf+2, the text after its length word
namelength equ $FFFFD4E8
namelogsel equ $FFFFD4EA
namelogarrows equ $FFFFD4EC
nameentryvis equ $FFFFD4EE
homecardidx equ $FFFFD4F0
awaycardidx equ $FFFFD4F2
cardindex equ $FFFFD4F4
cardvis equ $FFFFD4F6
cardcount equ $FFFFD4F8
homecardlist equ $FFFFD4FA	;the home player card order (BuildCardPlayerLists), read by GetCardPlayer
awaycardlist equ $FFFFD514	;the away player card order
cardplayer equ $FFFFD52E
nameframechars equ $FFFFD530
recsort1 equ $FFFFD532	;Record Holders row order sorted on record byte 0 (ReadTeamRecords), read by PrintPlayerRecords
recsort2 equ $FFFFD53A	;Record Holders row order sorted on record byte 4 (ReadTeamRecords, sflags6 bit 6)
winsort equ $FFFFD542	;Record Holders win row order (CalcWinPercents), read by PrintWinRecords
winpcts equ $FFFFD54A	;the win % byte of each of the 8 records (CalcWinPercents)
winties equ $FFFFD552	;the ties word of each record (record bytes $C-$D)
wingames equ $FFFFD562	;the games word of each record (record bytes $A-$B)
shootoutstate equ $FFFFD572	;first of the 19 words ClearGameStats clears ($FFD572-$FFD597: shootout goals, shootoutround, shooter lists ...)
homeshootgoals equ $FFFFD574
awayshootgoals equ $FFFFD576
shootoutround equ $FFFFD578
homeshooters equ $FFFFD57A	;the home shootout shooter list (6 words, homeshootnum the index)
;$FFFFD585 is homeshootnum-1
homeshootnum equ $FFFFD586
awayshooters equ $FFFFD588	;the away shootout shooter list (6 words)
;$FFFFD593 is shootoutteam-1
shootoutteam equ $FFFFD594
matchup equ $FFFFD598
scoutunused equ $FFFFD59A	;cleared by ScoutingReport, never read
matchuphome equ $FFFFD59C
matchupvis equ $FFFFD59E	;the visitors player of the matchup; also the scroll limit of GameStatisticsScreen
homerating equ $FFFFD5A0
visrating equ $FFFFD5A2
advframe equ $FFFFD5A4
advcount equ $FFFFD5A6
matchuptimer equ $FFFFD5A8
matchupslot equ $FFFFD5AA
DispAttribCtr equ $FFFFD5AC
VertLineScrolling equ $FFFFD5AE
PlayerScrollCtr equ $FFFFD5B0
SelectedPlayerIdx equ $FFFFD5B2
typedelay equ $FFFFD5B4
screentimer equ $FFFFD5B6
TestList equ $FFFFD5B8
arenaanimchars equ $FFFFD6AC
arenaframe equ $FFFFD6AE
arenaframeidx equ $FFFFD6B0
arenaframetime equ $FFFFD6B2
arenaanim equ $FFFFD6B4
arenaframelist equ $FFFFD6B6
arenaspritelist equ $FFFFD6BA
faceoffanim equ $FFFFD6BE
cursoron equ $FFFFD6C4
facelcwait equ $FFFFD6C6
SongNum equ $FFFFD6C8
HmTeam equ $FFFFD6CA
SongIndex equ $FFFFD6CC
OvrDivisor equ $FFFFD6CE
OvrDividend equ $FFFFD6D0
homehotcoldsave equ $FFFFD6D2	;clearTeamStats keeps the first $1A0 bytes of the home hot / cold table (HmShots+$1A2) here
awayhotcoldsave equ $FFFFD872	;the same for AwShots+$1A2
sopath equ $FFFFDA12
sopathpoint equ $FFFFDA14
sopathx equ $FFFFDA16
sopathy equ $FFFFDA18
sopathdir equ $FFFFDA1A
sopathend equ $FFFFDA1C
picturebuf equ $FFFFDA1E	;UnpackPicture output: tile count word, then the 4 bit tiles (DrawMatchupBitmap, dobitmap read it)
picturebits equ $FFFFDEA0	;UnpackPicture: the 3 packed bytes of the row being unpacked
homepresses equ $FFFFDEA4
homedirpresses equ $FFFFDEA8
awaypresses equ $FFFFDEAC
awaydirpresses equ $FFFFDEB0
replayicontimer equ $FFFFDEB4
TmpPuckX equ $FFFFDEB6
lognametext equ $FFFFDEBA	;the unused TerminateLogName's GetLogName String text (length word at -2)
songdelay equ $FFFFDECC
delayedsong equ $FFFFDECE
shootoutdelay equ $FFFFDED0
PuckZCntr equ $FFFFDED2
waitxpad equ $FFFFDED4
TmpPuckZ equ $FFFFDED6
inputjoy equ $FFFFDED8
TmpJoyPuckCarrier equ $FFFFDEDA
PlayerChked equ $FFFFDEDC
PlayerChking equ $FFFFDEE0
hoticonchars equ $FFFFDEE4
coldiconchars equ $FFFFDEE6
iconplayer equ $FFFFDEE8
iconx equ $FFFFDEEA
scoutwait equ $FFFFDEEC
replaydelay equ $FFFFDEF0
PALflag equ $FFFFDEF2
Stack equ $FFFFFFFE
Z80_RAM equ $A00000
Z80_YM2612 equ $A04000
; ----------------------------------



