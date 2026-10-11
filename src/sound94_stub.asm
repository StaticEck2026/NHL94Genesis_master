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
; MusicTrackPointerTable, SongPointerTable) is in this segment. Run npm run extractassets first (npm run seg:does).

; Main segment code
	include	sound94.asm
