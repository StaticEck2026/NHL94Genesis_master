;	Segment build for graphics94.asm: sets its origin and the outside routines and data it uses,
;	then includes graphics94.asm on its own for checking against the ROM.

; External addresses outside: none. The segment is incbin only.
; Run npm run extractassets first (npm run seg:does) to write Extracted\.
; .region data
	org	$4B5C0

	include	stubinc\equals.inc	;NumTeams, for the team-block entry checks

; Main segment data
	include	graphics94.asm
