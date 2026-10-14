;	Shared equates. These name the video chip status bits, hardware constants and game values
;	that every module uses.

PAL_MODE equ 0
DMA_IN_PROGRESS equ 1
HBLANKING equ 2
VBLANKING equ 3
ODD_FRAME equ 4
SPRITE_COLLISION equ 5
SPRITE_OVERFLOW equ 6
VBLANK_PENDING equ 7
FIFO_FULL equ 8
FIFO_EMPTY equ 9
; ----------------------------------




; ------------- 93 structure and flag equates -------------
; Included by every *_stub.asm and by nhl94.asm. Names are the NHLPA93Genesis names; the value is 94's.

Sortobjs equ 16		;number of sorted graphics objects
SCstruct equ $80		;ram for each sortobj (SortCords entry)
puckscnum equ 14		;puck is sort obj number 14

;the sort object structure (SCstruct bytes each)
Xpos equ $0
attribute equ $4		;frame attribute switch bits
frame equ $6		;alice frame number
oldframe equ $8		;last frame
VRoffs equ $A		;offsets to find each sprites start char. (max of 6 sprites / frame)
VRchar equ $12		;vram char for graphic
Ypos equ $14
Zpos equ $18
OldXpos equ $1C
OldYpos equ $20
OldZpos equ $24
Xvel equ $28
Yvel equ $2A
Zvel equ $2C
impactp equ $2E		;last player to cause impact
limpact equ $30		;last impact value
impact equ $32		;impact value
position equ $34		;player's position (0=goalie,1=l.def,2=r.def,3=l.wing,4=center,5=r.wing)
assnum equ $36		;index to current assignment
asslist equ $38		;list of assignments in order of execution
temp1 equ $40
temp2 equ $42
temp3 equ $44
temp4 equ $46
temp5 equ $48
radiusx equ $4A		;width of this graphic
radiusy equ $4C		;height of this graphic
Wallcos equ $4E		;cos of angle of last collision
Wallsin equ $50		;sin of angle of last collision
SCnum equ $52		;index number for this struct
facedir equ $54		;direction of facing
SPA equ $58		;animation (SPA offset)
SPAnum equ $5A		;index into animation
SPAcnt equ $5C		;count down to next frame of animation
nopuck equ $5E		;no puck coll until zero
newpos equ $60		;requested next position of this player
newpnum equ $61		;requested next player (from roster) for this player
pflags equ $62
pfdoff equ 0		;bit0-deceleration off
pfna equ 1		;bit1-new assignment
pfnc equ 2		;bit2-no collision mode
pfjoycon equ 3		;is player joystick controlled
pfrev equ 4		;skating backwards
pfalock equ 5		;lock out until anim is done
pfteam equ 6		;0-home(sprite0-5)/1-visitors(sprite6-11)
pfgoal equ 7		;0=bottom, 1=top (to shoot at)
pflags2 equ $63
pf2fight equ 0		;player is fighting (93; 94 has no fights)
pf2aip equ 1		;animation in progress wait
glitch equ $65		;counter to eliminate quick frame changes (de-glitch graphics)
pnum equ $66		;player's team location number 0-22
weight equ $67
legstr equ $68
legspd equ $69
aioff equ $6A
aidef equ $6B
shotspd equ $6C
shotacc equ $6D
passacc equ $6E
rostnum equ $6F
spodds equ $70
stickhand equ $71
endurance equ $72
handed equ $76		;bit0 set is left handed
;player struct fields after handed's neighbours, not named in 93 (names from the 92/93/94 comments)
pflags3 equ $64		;player flags 3 (92: not used)
pf3oside equ 0		;offsides
pf3break equ 1		;on a breakaway
pf3gctrl equ 2		;goalie control
pf3onetimer equ 3	;doing a one-timer
pf3wall equ 4		;wall collision
pf3fall equ 5		;falling down
aggress equ $73		;aggression (Agr; goalie: glove left)
fighting equ $74		;fighting (Fgt; from the Chk/Hnd byte, always even)
checking equ $75		;checking (Chk)

;bit numbers in disflags
dfok equ 0		;graphics are ready for transfer
df32c equ 1		;32 column mode on
dfng equ 2		;don't int graphics
dfclock equ 3		;clock needs update
;bit numbers in gmode
gmclock equ 0		;game clock is stopped
gmdir equ 1		;0 = home team goes up
gmpen equ 2		;penalty has been called
gmpendel equ 3		;delayed penalty has been called
gmhl equ 4		;hilight mode
gmoffs equ 5		;offsides on
;bit numbers in sflags
sfpz equ 0		;pause mode
sfpj equ 1		;pause cont (0 for cont 1)
sfspdir equ 2		;set pass dir mode
sfssdir equ 3		;set shot dir mode
sfwrap equ 4		;replay has wrapped around
sfscrl equ 5		;replay scroll is manual cont
sfslock equ 6		;scroll lock to xc1/yc1
sfhor equ 7		;screen is in horizontal mode
;bit numbers in sflags2
sf2faceoff equ 0		;face off in progress
sf2refref equ 1		;ref needs refresh
sf2drec equ 2		;disable replay record
sf2replay equ 3		;replay in progress
sf2shot equ 4		;shot was taken
sf2pwrplay equ 5		;power play in progress
sf2pwrtm equ 6		;0 for team 1 in power play
sf2offsig equ 7		;offsides little ref on
;bit numbers in sflags3
sf3llcs equ 0		;lower line change sel.
sf3rmplay equ 1		;play mode on for replay
sf3alttree equ 2		;alt. tree
sf3sbut equ 3		;flag for start button

;team variables (HmShots / AwShots = the home / away team struct)
tmshots equ $0		;shots stat
tmPwrGoals equ $2		;power play goals stat
tmPwrPlays equ $4		;power plays stat
tmPenalties equ $6		;penalties stat
tmPenmin equ $8		;penalty min. stat
tmATOP equ $A		;attack time of possesion stat
tmscore equ $C		;score
tmline equ $16		;current line
tmdata equ $1E		;team data address
tmsort equ $22		;address of first sort obj (word)
tmap equ $24		;active players on ice 4-6
tmgoalie equ $26		;goalie 1/2/none
tmflags equ $30		;flags
tmpde equ $32		;energy level of each roster player
tmpdst equ $66		;-2=bench/-1=ice/0+=penalty box
tmsize equ $364		;93 $1A2: 94 adds the hot / cold table at $1A2

;game structure variables (one per playoff matchup, gsstruct)
gst1 equ $0		;team 1
gst2 equ $2		;team 2
gspotwins equ $4		;play off top team (on tree) wins (for best of 7)
gspobwins equ $6		;play off bottom team (on tree) wins (for best of 7)
gsper equ $8		;period
gss1 equ $A		;team 1 score
gss2 equ $C		;team 2 score
gsflags equ $E		;flags
gssize equ $10
; ----------------------------------

;text control codes in Strings
;print / printz / printbig / printbigz: a negative byte -(TXPRI+TXPALn+TXVF+TXHF+TXMAPn), then x, y (printa = the bits << 9, printm = map)
TXMAP1 equ 1		;plane map 1
TXMAP2 equ 2
TXMAP3 equ 3
TXHF equ 4		;h flip
TXVF equ 8		;v flip
TXPAL1 equ $10		;palette 1
TXPAL2 equ $20
TXPAL3 equ $30
TXPRI equ $40		;high priority
;printsmall / printz2 (ControlCodeJumpTable, -byte): the code, then its argument bytes
CC_SetMap equ $FF		;-1: map
CC_SetAttribute equ $FE		;-2: palette/priority (printa)
CC_SetX equ $FD		;-3: printx
CC_SetY equ $FC		;-4: printy
CC_AddX equ $FB		;-5: add signed byte to printx
CC_AddY equ $FA		;-6: add signed byte to printy
CC_SetFont equ $F9		;-7: char set
CC_SetMapAndPosition equ $F8		;-8: attribute, map, x, y

;game sound effect numbers (sfx / song argument). 95 maps them through SfxTable
SFXsiren equ $0
SFXbeep1 equ $1
SFXbeep2 equ $2
SFXwhistle equ $3
SFXhorn equ $4
SFXshotwiff equ $5
SFXstdef equ $6
SFXpuckget equ $7
SFXoooh equ $8
SFXhithigh equ $9
SFXhitlow equ $A
SFXcrowdcheer equ $B
SFXcrowdboo equ $C
SFX0D equ $D
SFX0E equ $E
SFXhomewin equ $F		;home team won
SFXpass equ $10		;4 variants, +0-3
SFXshotbh equ $14		;+0-3
SFXshotfh equ $18		;+0-3
SFXcheck equ $1C		;+0-3
SFXplayerwall equ $20
SFX21 equ $21
SFX22 equ $22
SFX23 equ $23
SFXpuckbody equ $24
SFXpuckpost equ $25
SFX26 equ $26
SFX27 equ $27
SFXpuckwall1 equ $28		;+0-3
SFXpuckice equ $2C		;+0-3
;song numbers
SngTitle equ $78
SngEOG equ $79
SngScout equ $7A


; team numbers (TeamList order in teamdata): schedule, playoffseats and other team-indexed tables
ANH equ 0
BOS equ 1
BUF equ 2
CGY equ 3
CHI equ 4
DAL equ 5
DET equ 6
EDM equ 7
FLA equ 8
HFD equ 9
LA equ 10
MTL equ 11
NJ equ 12
NYI equ 13
NYR equ 14
OTW equ 15
PHI equ 16
PIT equ 17
QUE equ 18
SJ equ 19
STL equ 20
TB equ 21
TOR equ 22
VAN equ 23
WSH equ 24
WPG equ 25
ASE equ 26
ASW equ 27
; NumTeams includes the two all-star teams, which stay last. NumPlayoffTeams is the first
; all-star number: a new playoff team is inserted before ASE and both all-star numbers move up.
NumTeams equ ASW+1
NumPlayoffTeams equ ASE
; Roster slots per team (skaters in card lists, three-stars tables, etc.), not the league count.
RosterSlots equ 26
PlayoffRows equ 32
PlayoffRowTeams equ 16
; Save RAM layout (retail addresses). Crowd records are NumTeams blocks of CrowdRecBytes at
; CrowdRecBase and must end before the records block; see docs/EXPANDING_THE_ROM.md.
CrowdRecBase equ $B60
CrowdRecBytes equ 16
CrowdRecEnd equ CrowdRecBase+NumTeams*CrowdRecBytes
TeamRecBase equ $D20
RecordsBytes equ $80
NameLogBase equ $DA0
NameLogBytes equ $80
LineDataBase equ $1EF6
	IF TeamRecBase<CrowdRecEnd
		inform	3,"The crowd records run into the records block (see docs/EXPANDING_THE_ROM.md)"
	ENDIF
	IF 32<NumPlayoffTeams
		inform	3,"The playoff draw only keeps 32 team bits"
	ENDIF