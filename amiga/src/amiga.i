;	Amiga build constants shared by the hardware layer and the converted game code.

RAMBASE		equ	$001F0000		;Genesis work RAM ($FFFF0000-$FFFFFFFF) lives here: the top 64K of chip RAM. Must be 64K
							;aligned: the game keeps RAM pointers as 16-bit words
RAMFIX		equ	RAMBASE+$10000		;add to a sign-extended RAM word pointer ($FFFFxxxx) to get
							;RAMBASE+xxxx
