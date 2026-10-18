;	Top level of the Amiga build. The converted Genesis modules (output/amiga/src) in cartridge
;	order, with the Amiga hardware layer in front of them.

	machine	68020
	include	"amiga.i"
	include	"stubinc/ports.inc"
	include	"stubinc/equals.inc"
	include	"stubinc/ram_addrs.inc"
	include	"hal_macros.i"
	include	"macros/genesis.mac"

	section	game,code

	include	"hal.asm"
	include	"vdp.asm"

	include	"teamdata94.asm"
	include	"frames94.asm"
	include	"hockey94.asm"
	include	"menu94.asm"
	include	"stats94.asm"
	include	"replay94.asm"
	include	"input94.asm"
	include	"assign94.asm"
	include	"checks94.asm"
	include	"video94.asm"
	include	"penalty94.asm"
	include	"collide94.asm"
	include	"display94.asm"
	include	"setup94.asm"
	include	"attract94.asm"
	include	"data94.asm"
	include	"sram94.asm"
	include	"sound94.asm"
	include	"graphics94.asm"
	include	"onetimer94.asm"
	include	"fourway94.asm"
	include	"crowd94.asm"
	include	"optsetup94.asm"
	include	"cards94.asm"
	include	"records94.asm"
	include	"shootout94.asm"
	include	"scout94.asm"
	include	"period94.asm"
	include	"goalie94.asm"
	include	"title94.asm"
;checksum94.asm: not used (cartridge ROM check)
