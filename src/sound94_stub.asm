;	Segment build for sound94.asm: sets its origin and the outside routines and data it uses,
;	then includes sound94.asm on its own for checking against the ROM.

	include	macros\genesis.mac	;String

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub. (the 68k driver, then the sound data incbins).
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; .region code
	org	$1A264

; includes for stubs to replace removed code
	include	stubinc\ports.inc	;IO_* / VDP_* ports
	include	stubinc\equals.inc	;VDP status bits
	include	stubinc\ram_addrs.inc	;RAM names

; External addresses outside: none. The sound data the driver reads (Z80_Program_Code, pcm_sample_table
; SoundStreamTable, SongPointerTable) is in this segment. Run npm run extractassets first (npm run seg:does).

; Main segment code
	include	sound94.asm
