;	Amiga build constants shared by the hardware layer and the converted game code.

;	The Genesis work RAM ($FFFF0000-$FFFFFFFF) is the 64K at
;	RAMBASE, a label in a hunk of its own (nhl94_amiga.asm).
RAMFIX		equ	RAMBASE+$10000
