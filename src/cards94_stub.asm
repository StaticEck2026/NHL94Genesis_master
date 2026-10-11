	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	cards94 segment stub. Retail $0F8B5A-$0FBB87.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$F8B5A

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0F8B5A-$0FBB87, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement. IDA names.
AddSmallFont = $11F04		;jsr / jmp (x).l at $FB0B6
AttribAdjust = $FEF7C		;bsr.w / Bcc.w at $FA916
DecompressGraphicsWithCallback = $1172C	;jsr / jmp (x).l at $FA0EE
DoDMA_clearCallbackPointer = $11738	;jsr / jmp (x).l at $FB118
ExitAttributeScreen2 = $9CD8	;jsr / jmp (x).l at $FA29C
FormatPlayerNameShort = $18B6E	;jsr / jmp (x).l at $FA9B0
Framer = $119B8			;jsr / jmp (x).l at $FB186
GetPlayerCount = $9F9A		;jsr / jmp (x).l at $F9FF4
MakeSRAMChecksum = $1A206	;jsr / jmp (x).l at $F9DCE
ProcessInputWithRepeat = $11318	;jsr / jmp (x).l at $FA220
PushNumberWidth = $11D3A		;jsr / jmp (x).l at $FAC2C
ReadAttributeNibble = $9F40	;jsr / jmp (x).l at $F9FCA
ReadJoy1 = $11340		;jsr / jmp (x).l at $FB2EE
ReadJoy2 = $11358		;jsr / jmp (x).l at $FB2E0
ReadSRAM = $1A244		;jsr / jmp (x).l at $F9BCE
VBlank_SetOptions = $17C42	;#x at $FB024
Vmaddr = $11680			;jsr / jmp (x).l at $FA0A6
WriteSRAM = $1A1E4		;jsr / jmp (x).l at $F9BC4
appstring = $11D9E		;jsr / jmp (x).l at $F990A
checkcornercoll94 = $F6FD6		;jsr / jmp (x).l at $F8B8E
dobitmap = $1169A		;jsr / jmp (x).l at $FA126
PAttribOverallMask = $19420		;move.l (x).l operand, retail long
GAttribOverallMask = $19582		;move.l (x).l operand, retail long
eraser = $1197E			;jsr / jmp (x).l at $FA152
forceblack = $10F32		;jsr / jmp (x).l at $FA08C
getpzjoy = $A41E			;jsr / jmp (x).l at $FA21A
nodiag = $112F0			;jsr / jmp (x).l at $FA250
orjoy = $112BC			;jsr / jmp (x).l at $FB07C
print = $11BA4			;jsr / jmp (x).l at $FB16C
printsmall = $11A48			;jsr / jmp (x).l at $FA3D2
printbigz = $11DE2		;jsr / jmp (x).l at $FB1FE
printz = $11B92			;jsr / jmp (x).l at $FA0FC
printsmallz = $11A36			;jsr / jmp (x).l at $FA42A
setupIceRinkMap = $16C96		;jsr / jmp (x).l at $FB0D6
setvram = $11594			;jsr / jmp (x).l at $FB072
FormatPlayerNameLast = $18B5E		;jsr / jmp (x).l at $FA3F0
GetDefenseStart = $9F5C			;jsr / jmp (x).l at $FAB7E
GetTeamRating = $FE172		;bsr.w / Bcc.w at $FAC24
UnpackPicture = $FE98A		;bsr.w / Bcc.w at $FAF0E
GetTeamStruct = $FEE4A		;bsr.w / Bcc.w at $FA93E
ScoutMap = $54E24		;#x at $FB0E8
framermap = $55B7E		;#x at $FB086
BigFontMap = $A9A10		;#x at $FB122
SmallFontMap = $AAC52		;#x at $FA0E8
LogoBoxMap = $BF702		;#x at $FB112
PicturePalette = $C63F8		;#x at $FAEEE
NoPicSkater1 = $C682E		;#x at $FAEB0
NoPicSkater2 = $C6B98		;#x at $FAEA0
NoPicGoalie1 = $C6F02		;#x at $FAE84
NoPicGoalie2 = $C726C		;#x at $FAE94
CardAndyMoog = $C75D6		;dc.l x at $F93B4 (FeaturedPictures)
CardRayBourque = $C7940		;dc.l x at $F93C0 (FeaturedPictures)
CardAdamOates = $C7CAA		;dc.l x at $F93CC (FeaturedPictures)
CardDonSweeney = $C8014		;dc.l x at $F93BA (FeaturedPictures)
CardJoeJuneau = $C837E		;dc.l x at $F93C6 (FeaturedPictures)
CardCamNeely = $C86E8		;dc.l x at $F93D2 (FeaturedPictures)
CardAlexnderMogilny = $C8A52		;dc.l x at $F9400 (FeaturedPictures)
CardPatLaFontaine = $C8DBC		;dc.l x at $F93FA (FeaturedPictures)
CardDaleHawerchuk = $C9126		;dc.l x at $F93F4 (FeaturedPictures)
CardDougBodger = $C9490		;dc.l x at $F93E8 (FeaturedPictures)
CardGrantFuhr = $C97FA		;dc.l x at $F93E2 (FeaturedPictures)
CardPetrSvoboda = $C9B64		;dc.l x at $F93EE (FeaturedPictures)
CardMikeVernon = $C9ECE		;dc.l x at $F940A (FeaturedPictures)
CardGaryRoberts = $CA238		;dc.l x at $F941C (FeaturedPictures)
CardTheorenFleury = $CA5A2		;dc.l x at $F9428 (FeaturedPictures)
CardGarySuter = $CA90C		;dc.l x at $F9410 (FeaturedPictures)
CardAlMacInnis = $CAC76		;dc.l x at $F9416 (FeaturedPictures)
CardJoeNieuwendyk = $CAFE0		;dc.l x at $F9422 (FeaturedPictures)
CardEdBelfour = $CB34A		;dc.l x at $F9432 (FeaturedPictures)
CardJeremyRoenick = $CB6B4		;dc.l x at $F944A (FeaturedPictures)
CardSteveLarmer = $CBA1E		;dc.l x at $F9450 (FeaturedPictures)
CardChrisChelios = $CBD88		;dc.l x at $F943E (FeaturedPictures)
CardSteveSmith = $CC0F2		;dc.l x at $F9438 (FeaturedPictures)
CardMichelGoulet = $CC45C		;dc.l x at $F9444 (FeaturedPictures)
CardTimCheveldae = $CC7C6		;dc.l x at $F9482 (FeaturedPictures)
CardSteveYzerman = $CCB30		;dc.l x at $F949A (FeaturedPictures)
CardSergeiFedorov = $CCE9A		;dc.l x at $F9494 (FeaturedPictures)
CardPaulCoffey = $CD204		;dc.l x at $F948E (FeaturedPictures)
CardSteveChiasson = $CD56E		;dc.l x at $F9488 (FeaturedPictures)
CardDinoCiccarelli = $CD8D8		;dc.l x at $F94A0 (FeaturedPictures)
CardBillRanford = $CDC42		;dc.l x at $F94AA (FeaturedPictures)
CardDaveManson = $CDFAC		;dc.l x at $F94B0 (FeaturedPictures)
CardIgorKravchuk = $CE316		;dc.l x at $F94B6 (FeaturedPictures)
CardShayneCorson = $CE680		;dc.l x at $F94BC (FeaturedPictures)
CardDougWeight = $CE9EA		;dc.l x at $F94C2 (FeaturedPictures)
CardPetrKlima = $CEDF0		;dc.l x at $F94C8 (FeaturedPictures)
CardSeanBurke = $CF15A		;dc.l x at $F94D2 (FeaturedPictures)
CardAndrewCassels = $CF4C4		;dc.l x at $F94EA (FeaturedPictures)
CardGeoffSanderson = $CF82E		;dc.l x at $F94E4 (FeaturedPictures)
CardPatVerbeek = $CFB98		;dc.l x at $F94F0 (FeaturedPictures)
CardZarleyZalapski = $CFF02		;dc.l x at $F94D8 (FeaturedPictures)
CardEricWeinrich = $D026C		;dc.l x at $F94DE (FeaturedPictures)
CardBenoitHogue = $D05D6		;dc.l x at $F9596 (FeaturedPictures)
CardSteveThomas = $D0940		;dc.l x at $F958A (FeaturedPictures)
CardPierreTurgeon = $D0CAA		;dc.l x at $F9590 (FeaturedPictures)
CardGlennHealy = $D1014		;dc.l x at $F9578 (FeaturedPictures)
CardDariusKasparitis = $D137E		;dc.l x at $F957E (FeaturedPictures)
CardVladimirMalakhov = $D16E8		;dc.l x at $F9584 (FeaturedPictures)
CardKellyHrudey = $D1AEE		;dc.l x at $F94FA (FeaturedPictures)
CardWayneGretzky = $D1EDC		;dc.l x at $F9512 (FeaturedPictures)
CardLucRobitaille = $D2246		;dc.l x at $F950C (FeaturedPictures)
CardTomasSandstrom = $D25B0		;dc.l x at $F9518 (FeaturedPictures)
CardRobBlake = $D291A		;dc.l x at $F9500 (FeaturedPictures)
CardMartyMcSorley = $D2C84		;dc.l x at $F9506 (FeaturedPictures)
CardJonCasey = $D2FEE		;dc.l x at $F945A (FeaturedPictures)
CardMikeModano = $D3358		;dc.l x at $F9472 (FeaturedPictures)
CardMarkTinordi = $D36C2		;dc.l x at $F9460 (FeaturedPictures)
CardTommySjodin = $D3A2C		;dc.l x at $F9466 (FeaturedPictures)
CardDaveGagner = $D3D96		;dc.l x at $F946C (FeaturedPictures)
CardRussCourtnall = $D4100		;dc.l x at $F9478 (FeaturedPictures)
CardPatrickRoy = $D446A		;dc.l x at $F9528 (FeaturedPictures)
CardEricDesjardins = $D47D4		;dc.l x at $F9534 (FeaturedPictures)
CardMattSchneider = $D4B3E		;dc.l x at $F952E (FeaturedPictures)
CardKirkMuller = $D4F14		;dc.l x at $F9540 (FeaturedPictures)
CardVincentDamphousse = $D527E		;dc.l x at $F953A (FeaturedPictures)
CardBrianBellows = $D55E8		;dc.l x at $F9546 (FeaturedPictures)
CardScottStevens = $D5952		;dc.l x at $F955C (FeaturedPictures)
CardChrisTerreri = $D5CBC		;dc.l x at $F9550 (FeaturedPictures)
CardVachslavFetisov = $D6026		;dc.l x at $F9556 (FeaturedPictures)
CardStephaneRicher = $D6390		;dc.l x at $F9562 (FeaturedPictures)
CardAlexnderSemak = $D66FA		;dc.l x at $F9568 (FeaturedPictures)
CardClaudeLemieux = $D6A64		;dc.l x at $F956E (FeaturedPictures)
CardJohnVanbiesbrk = $D6DCE		;dc.l x at $F95A0 (FeaturedPictures)
CardMarkMessier = $D71A4		;dc.l x at $F95B8 (FeaturedPictures)
CardJamesPatrick = $D750E		;dc.l x at $F95A6 (FeaturedPictures)
CardMikeGartner = $D7878		;dc.l x at $F95BE (FeaturedPictures)
CardBrianLeetch = $D7BE2		;dc.l x at $F95AC (FeaturedPictures)
CardEsaTikkanen = $D7F4C		;dc.l x at $F95B2 (FeaturedPictures)
CardPeterSidorkwicz = $D82B6		;dc.l x at $F95C8 (FeaturedPictures)
CardSylvainTurgeon = $D868C		;dc.l x at $F95DA (FeaturedPictures)
CardNormMaciver = $D89F6		;dc.l x at $F95D4 (FeaturedPictures)
CardBradShaw = $D8D60		;dc.l x at $F95CE (FeaturedPictures)
CardJamieBaker = $D90CA		;dc.l x at $F95E0 (FeaturedPictures)
CardBobKudelski = $D9434		;dc.l x at $F95E6 (FeaturedPictures)
CardEricLindros = $D979E		;dc.l x at $F9608 (FeaturedPictures)
CardRodBrindAmour = $D9B08		;dc.l x at $F9602 (FeaturedPictures)
CardGarryGalley = $D9E72		;dc.l x at $F95FC (FeaturedPictures)
CardMarkRecchi = $DA1DC		;dc.l x at $F960E (FeaturedPictures)
CardTommySoderstrom = $DA546		;dc.l x at $F95F0 (FeaturedPictures)
CardDimitriYushkevich = $DA8B0		;dc.l x at $F95F6 (FeaturedPictures)
CardTomBarrasso = $DAC1A		;dc.l x at $F9618 (FeaturedPictures)
CardMarioLemieux = $DAF84		;dc.l x at $F9630 (FeaturedPictures)
CardKevinStevens = $DB2EE		;dc.l x at $F962A (FeaturedPictures)
CardJaromirJagr = $DB658		;dc.l x at $F9636 (FeaturedPictures)
CardLarryMurphy = $DB9C2		;dc.l x at $F961E (FeaturedPictures)
CardUlfSamuelsson = $DBD2C		;dc.l x at $F9624 (FeaturedPictures)
CardRonHextall = $DC096		;dc.l x at $F964C (FeaturedPictures)
CardOwenNolan = $DC46C		;dc.l x at $F966A (FeaturedPictures)
CardSteveDuchesne = $DC7D6		;dc.l x at $F9658 (FeaturedPictures)
CardJoeSakic = $DCB40		;dc.l x at $F965E (FeaturedPictures)
CardCurtisLeschyshyn = $DCEAA		;dc.l x at $F9652 (FeaturedPictures)
CardMatsSundin = $DD214		;dc.l x at $F9664 (FeaturedPictures)
CardKellyKisio = $DD57E		;dc.l x at $F968C (FeaturedPictures)
CardDougWilson = $DD8E8		;dc.l x at $F9680 (FeaturedPictures)
CardPatFalloon = $DDC52		;dc.l x at $F9692 (FeaturedPictures)
CardArtursIrbe = $DDFBC		;dc.l x at $F9674 (FeaturedPictures)
CardNeilWilkinson = $DE326		;dc.l x at $F967A (FeaturedPictures)
CardJohanGarpenlov = $DE690		;dc.l x at $F9686 (FeaturedPictures)
CardCurtisJoseph = $DE9FA		;dc.l x at $F969C (FeaturedPictures)
CardCraigJanney = $DED64		;dc.l x at $F96B4 (FeaturedPictures)
CardBrettHull = $DF0CE		;dc.l x at $F96BA (FeaturedPictures)
CardGarthButcher = $DF438		;dc.l x at $F96A8 (FeaturedPictures)
CardJeffBrown = $DF7A2		;dc.l x at $F96A2 (FeaturedPictures)
CardBrendanShanahan = $DFB0C		;dc.l x at $F96AE (FeaturedPictures)
CardBrianBradley = $DFE76		;dc.l x at $F96DC (FeaturedPictures)
CardWendellYoung = $E01E0		;dc.l x at $F96C4 (FeaturedPictures)
CardRomanHamrlik = $E054A		;dc.l x at $F96CA (FeaturedPictures)
CardBobBeers = $E08B4		;dc.l x at $F96D0 (FeaturedPictures)
CardMikaelAndersson = $E0C1E		;dc.l x at $F96D6 (FeaturedPictures)
CardChrisKontos = $E0F88		;dc.l x at $F96E2 (FeaturedPictures)
CardFelixPotvin = $E12F2		;dc.l x at $F96EC (FeaturedPictures)
CardDougGilmour = $E165C		;dc.l x at $F9704 (FeaturedPictures)
CardNikolaiBorshevsky = $E19C6		;dc.l x at $F970A (FeaturedPictures)
CardDaveEllett = $E1D30		;dc.l x at $F96F2 (FeaturedPictures)
CardToddGill = $E209A		;dc.l x at $F96F8 (FeaturedPictures)
CardDaveAndreychuk = $E2404		;dc.l x at $F96FE (FeaturedPictures)
CardKirkMcLean = $E280A		;dc.l x at $F9714 (FeaturedPictures)
CardGeoffCourtnall = $E2B74		;dc.l x at $F9726 (FeaturedPictures)
CardPavelBure = $E2EDE		;dc.l x at $F9732 (FeaturedPictures)
CardJyrkiLumme = $E3248		;dc.l x at $F9720 (FeaturedPictures)
CardDougLidster = $E35B2		;dc.l x at $F971A (FeaturedPictures)
CardCliffRonning = $E391C		;dc.l x at $F972C (FeaturedPictures)
CardDonBeaupre = $E3C86		;dc.l x at $F973C (FeaturedPictures)
CardMikeRidley = $E3FF0		;dc.l x at $F9754 (FeaturedPictures)
CardDimitriKhristich = $E435A		;dc.l x at $F974E (FeaturedPictures)
CardPeterBondra = $E46C4		;dc.l x at $F975A (FeaturedPictures)
CardKevinHatcher = $E4A2E		;dc.l x at $F9748 (FeaturedPictures)
CardAlIafrate = $E4D98		;dc.l x at $F9742 (FeaturedPictures)
CardThomasSteen = $E5102		;dc.l x at $F977C (FeaturedPictures)
CardTeemuSelanne = $E546C		;dc.l x at $F9788 (FeaturedPictures)
CardPhilHousley = $E57D6		;dc.l x at $F9776 (FeaturedPictures)
CardBobEssensa = $E5B40		;dc.l x at $F976A (FeaturedPictures)
CardTeppoNumminen = $E5EAA		;dc.l x at $F9770 (FeaturedPictures)
CardAlexeiZhamnov = $E62C8		;dc.l x at $F9782 (FeaturedPictures)
PlayerCardsScreenPic = $E6632		;#x at $FA108
CornerLogoMap = $E9A80		;movea.l #x, retail long
ArenaGfxBank = $E9ED6		;#x at $FA192
TeamLogoBitmaps = $F86F2		;#x at $FA69C
TeamLogoPalettes = $FF462		;#x at $FA6AE
vcountwait = $80BA		;jsr / jmp (x).l at $FA214

SkipOtherUserName = $FBBDE	;bsr.w / bra.w / Bcc.w at $FB224. records94

; Main segment code
	include	cards94.asm
