	include	macros\genesis.mac	;String (main94.asm includes it in the full build)

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	title94 segment stub. Retail $0FE556-$0FFABF.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$FE556

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside $0FE556-$0FFABF, read from lst/nhl94.bin: jsr / jmp (x).l, movea.l / move.l #x and
; lea (x).l carry the address; bsr.w / bra.w / Bcc.w is the displacement word address + displacement.
DecompressGraphicsWithCallback = $1172C	;jsr / jmp (x).l at $FF20A
DoDMA = $113E4			;jsr / jmp (x).l at $FF362
DoDMA_clearCallbackPointer = $11738	;jsr / jmp (x).l at $FE2FE
HiScoreImg = $F5338		;#x at $FEE00
MakeSRAMChecksum = $1A206	;jsr / jmp (x).l at $FE6B2
p_music_vblank = $1A50A			;jsr / jmp (x).l at $FF3A4
NHLShieldImg = $52DAA		;#x at $FF17C
PAlogoImg = $5338C		;#x at $FF1A8
PushNumberWidth = $11D3A		;jsr / jmp (x).l at $FDC1A
ReadSRAM = $1A244		;jsr / jmp (x).l at $FE676
SetSPA = $1073A			;jsr / jmp (x).l at $FF014
SetSframe = $16178		;jsr / jmp (x).l at $FED4A
Setplass = $15A88		;jsr / jmp (x).l at $FF02C
Sweepcheck = $C0AE		;jsr / jmp (x).l at $FFAAE
TitleImg = $5394E		;#x at $FF1D4
TitleScreenImg = $4E45C		;#x at $FF10C
WriteSRAM = $1A1E4		;jsr / jmp (x).l at $FE6AC
appendz = $11D96			;jsr / jmp (x).l at $FDEEA
appstring = $11D9E		;jsr / jmp (x).l at $FDEE4
assexit = $10646			;jsr / jmp (x).l at $FF022
clrCrowdRAM = $F9BE2		;jsr / jmp (x).l at $FEC70
cramfade = $10FB6		;jsr / jmp (x).l at $FF394
dobitmap = $1169A		;jsr / jmp (x).l at $FD990
eraser = $1197E			;jsr / jmp (x).l at $FF0D6
forceblack = $10F32		;jsr / jmp (x).l at $FEDAE
setVram_0 = $115AA		;jsr / jmp (x).l at $FEDC0
orjoy = $112BC			;jsr / jmp (x).l at $FF332
print = $11BA4			;jsr / jmp (x).l at $FD8D8
printz = $11B92			;jsr / jmp (x).l at $FD91E
randomd0 = $11086		;jsr / jmp (x).l at $FE598
setc1player = $C0BC		;jsr / jmp (x).l at $FE280
setc2player = $C0DA		;jsr / jmp (x).l at $FE2BC
setvram = $11594			;jsr / jmp (x).l at $FF09A
song = $11156			;jsr / jmp (x).l at $FF25C
StartText = $F997A		;bsr.w / Bcc.w at $FEF14
GetLogName = $FB992		;bsr.w / Bcc.w at $FEEAA
SmallFontMap = $AAC52		;#x at $FF204
PlayoffSprite = $F3098		;#x at $FED30
HotIconMap = $F5AF6		;#x at $FF964
ColdIconMap = $F5D1C		;#x at $FF972
vb2 = $15E4C			;#x at $FED70
waitx = $11176			;jsr / jmp (x).l at $FEE32

Credits = $5776			;#x at $FF224 (teamdata94)
CreditsList = $57B8		;#x at $FF290 (teamdata94)
ArenaGfxBank = $E9ED6		;dc.l x+n in ArenaAnims and TeamGfxList (graphics94)
PlayoffSprite = $F3098		;#x+$12E0 at $FEDD2 (graphics94)

; Main segment code
	include	title94.asm
