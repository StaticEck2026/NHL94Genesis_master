;	Amiga build constants shared by the hardware layer and the converted game code.

;	The Genesis work RAM ($FFFF0000-$FFFFFFFF) is the 64K at RAMBASE, a label in a hunk of its
;	own (nhl94_amiga.asm). It must be 64K aligned, as the game keeps RAM pointers as 16-bit words,
;	so at start the game moves it to a 64K aligned block (ram_relocate, os.asm).
RAMFIX		equ	RAMBASE+$10000		;add to a sign-extended RAM word pointer ($FFFFxxxx) to get
							;RAMBASE+xxxx
