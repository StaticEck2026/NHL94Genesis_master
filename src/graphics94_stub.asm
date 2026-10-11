;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	Segment stub.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; External addresses outside: none. The segment is incbin only.
; Run npm run extractassets first (npm run seg:does) to write Extracted\.
; .region data
	org	$4B5C0

; Main segment data
	include	graphics94.asm
