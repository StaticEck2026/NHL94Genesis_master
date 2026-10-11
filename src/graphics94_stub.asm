;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;	graphics94 segment stub. Retail $04B5C0-$0F66ED.
;
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

; External addresses outside $04B5C0-$0F66ED: none. The segment is incbin only.
; Run npm run extractassets first (npm run seg:does) to write Extracted\NHL94.
; .region data
	org	$4B5C0

; Main segment data
	include	graphics94.asm
