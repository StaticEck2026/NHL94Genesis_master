	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$169FA

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
AddFramer = $11F12		;bsr.w / Bcc.w.
AddPlayoffTeamStats = $182A2		;bsr.w / Bcc.w
AddSmallFont = $11F04		;bsr.w / Bcc.w.
AddTeamBlock = $11F20		;bsr.w / Bcc.w.
AdvanceStringPtr = $13510		;bsr.w / Bcc.w
p_turnoff = $1A264		;jsr / jmp (x).l
DecompressGraphicsWithCallback = $1172C	;bsr.w / Bcc.w.
DoDMA = $113E4			;bsr.w / Bcc.w
DecompressGraphicsPlain = $11738	;bsr.w / Bcc.w.
DoDMA_nd2 = $114B8		;bsr.w / Bcc.w.
DoDMAList = $15E82		;bsr.w / Bcc.w
DoFill = $11544			;bsr.w / Bcc.w
GameSetUp = $F739E		;jsr / jmp (x).l
Intermission = $130E6		;bsr.w / Bcc.w
KillCrowd = $169D0		;bsr.w / Bcc.w
p_music_vblank = $1A50A			;jsr / jmp (x).l
ReadJoy1 = $11340		;bsr.w / Bcc.w
ReadJoy2 = $11358		;bsr.w / Bcc.w
ResetClock = $7814		;jsr (x).w.
RevRinkTiles = $B5188		;#x
Rinktilelist = $5605A		;#x
Rinktiles = $56062		;#x
SetSPA = $1073A			;bsr.w / Bcc.w
StartGame = $7742		;jmp (x).w.
StartPer = $7866			;jmp (x).w.
UpdateScores = $1323E		;bsr.w / Bcc.w
VBlank = $15D9A			;#x.
Vmaddr = $11680			;bsr.w / Bcc.w
addframe2 = $167AA		;bsr.w / Bcc.w
cramfade = $10FB6		;bsr.w / Bcc.w
dobitmap = $1169A		;bsr.w / Bcc.w
eraser = $1197E			;bsr.w / Bcc.w
forceblack = $10F32		;bsr.w / Bcc.w
newTitleScreen = $FF042		;jsr / jmp (x).l
print = $11BA4			;bsr.w / Bcc.w
printsmall = $11A48			;bsr.w / Bcc.w
printz = $11B92			;bsr.w / Bcc.w
printsmallz = $11A36			;bsr.w / Bcc.w
rtss2 = $15464			;bsr.w / Bcc.w. (an rts)
setVram = $11594			;bsr.w / Bcc.w
song = $11156			;bsr.w / Bcc.w
EncodePW = $180FC		;bsr.w / Bcc.w
PlayoffStatsScreen = $9428			;jsr / jmp (x).l
NextHomeHotPlayer = $F7144		;jsr / jmp (x).l
NextAwayHotPlayer = $F7172		;jsr / jmp (x).l
NextHomeColdPlayer = $F727C		;jsr / jmp (x).l
NextAwayColdPlayer = $F72AA		;jsr / jmp (x).l
UserNameEntry = $FBB88		;jsr / jmp (x).l
ScoutCrowdRecord = $FCB9A		;jsr / jmp (x).l
ScoutingReport = $FCC76		;jsr / jmp (x).l
GetTeamNickname = $FD5AE		;jsr / jmp (x).l
GetTeamArena = $FD5F4		;jsr / jmp (x).l
LoadHomeTeamGfx = $FEA52		;jsr / jmp (x).l
DrawPlayoffSprite = $FED2A		;jsr / jmp (x).l
PlayedByHome = $FEEC8		;jsr / jmp (x).l
PlayedByAway = $FEF5A		;jsr / jmp (x).l
PlayoffTreeSetup = $1928E		;#x
ScoutTextScript = $4B5C0		;#x
ScoutMap = $54E24		;#x
FaceOffMap = $55BF6		;#x
RefsMap = $5C408		;#x
RefMap2 = $5CF64		;#x
CrowdFrameList = $A4B54		;#x
FaceOffSprites = $A78AE		;#x
BigFontMap = $A9A10		;#x
SmallFontMap = $AAC52		;#x
EnergyBarMap = $AB920		;#x
Teamblocksmap = $ABA14		;#x
EASNmap = $B3530		;#x
Arrowsmap = $B3640		;#x
PlayoffSprite = $F3098		;#x

; Main segment code
	include	setup94.asm
