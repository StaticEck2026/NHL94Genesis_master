;	Top level of the ROM build. Includes the equates and then every module in ROM order;
;	each file assembles at the address after the one before it.

	include	stubinc\ports.inc	;IO_* / VDP_* ports. Equates only
	include	stubinc\equals.inc	;VDP status bits. Equates only
	include	stubinc\ram_addrs.inc	;RAM names. Equates only

	include	main94.asm		; $000000 header, startup, vectors
	include	teamdata94.asm		; $00030A teams, palettes, credits text
	include	frames94.asm		; $005B1C sprite animation tables
	include	ram94.asm		;          equates only
	include	hockey94.asm		; $0076B2 game loop, pause
	include	menu94.asm		; $007E36 menu core
	include	stats94.asm		; $0080D4 scores, line editor, roster, scoring and penalty summaries, player stats, crowd meter, goalie select
	include	replay94.asm		; $009FD0 replay
	include	input94.asm		; $00B0E8 controller input and line changes
	include	assign94.asm		; $00C67A player assignments
	include	checks94.asm		; $00D09C checks before the display code
	include	video94.asm		; $010E88 display helpers
	include	penalty94.asm		; $011F2C penalties, scoreboard, highlights
	include	collide94.asm		; $0138AC puck, players, walls, fights, goals
	include	display94.asm		; $015D9A vblank, clock, crowd, rink scroll
	include	setup94.asm		; $0169FA ice setup, intermission, playoff screen
	include	attract94.asm		; $017A18  NEW in 94: EA Sports attract screen
	include	data94.asm		; $017C72 menus, season results, string tables
	include	sram94.asm		; $01A050 save data
	include	sound94.asm		; $01A264 sound driver, then the sound data
	include	graphics94.asm		; $04B5C0 graphics only
	include	onetimer94.asm		; $0F66EE  NEW in 94: one-timer
	include	fourway94.asm		; $0F6D5E  NEW in 94: four-player adaptor
	include	crowd94.asm		; $0F6E8A  NEW in 94: crowd meter and hot / cold players
	include	optsetup94.asm		; $0F739E expanded: game setup and options
	include	cards94.asm		; $0F87D2  NEW in 94: player cards and matchup palettes
	include	records94.asm		; $0FB018  NEW in 94: name entry and record holders
	include	shootout94.asm		; $0FC320  NEW in 94: shootout
	include	scout94.asm		; $0FCB9A  NEW in 94: matchups and scouting report
	include	period94.asm		; $0FD618  NEW in 94: period stats and game statistics
	include	goalie94.asm		; $0FE1D8  NEW in 94: manual goalie
	include	title94.asm		; $0FE556  NEW in 94: song select, title, credits
	include	checksum94.asm		; $0FFAC0 checksum
; Pad to the next size the cartridge hardware accepts: 1MB, 1.5MB, 2MB or 4MB.
; Content past the backup RAM window still builds, with a warning. Past 4MB the build stops.
	IF $400000<*
		inform	3,"ROM is larger than 4MB"
	ENDIF
	IF $200000<*
		inform	1,"ROM content overlaps backup RAM"
	ENDIF
; Finish the 1MB image first. An include after this pad starts at the 1MB boundary,
; and the pad below then grows the ROM to the next size.
	IF *<$100000
		dcb.b	$100000-*,$FF
	ENDIF
	IF *<$100001
RomSize	equ	$100000
	ENDIF
	IF $100000<*
		IF *<$180001
RomSize	equ	$180000
		ENDIF
	ENDIF
	IF $180000<*
		IF *<$200001
RomSize	equ	$200000
		ENDIF
	ENDIF
	IF $200000<*
		IF *<$400001
RomSize	equ	$400000
		ENDIF
	ENDIF
	dcb.b	RomSize-*,$FF
RomEnd	equ	RomSize-1
