;	Hardware ports. These equates name the controller ports, the Z80 bus control and the video
;	chip ports.

IO_CT1_CTRL equ $A10008
IO_CT1_DATA equ $A10002
IO_CT2_CTRL equ $A1000A
IO_CT2_DATA equ $A10004
IO_Z80BUS equ $A11100
IO_Z80RES equ $A11200

Vdata equ $C00000	;video ports. Control port offset from a0 = Vdata: move.w #x,Vctrl-Vdata(a0) with a0 = Vdata
Vctrl equ Vdata+4
Asound equ $C00011	;PSG sound port
HVcount equ $C00008	;horizontal / vertical counter
;VDP register write words for the control port (register number in the high byte): move.w #VDPR_MODE2+$74,(Vctrl)
VDPR_MODE1 equ $8000
VDPR_MODE2 equ $8100
VDPR_PLANEA equ $8200	;plane A name table address / $400
VDPR_WINDOW equ $8300	;window name table address / $400
VDPR_PLANEB equ $8400	;plane B name table address / $2000
VDPR_SPRITE equ $8500	;sprite table address / $200
VDPR_BGCOL equ $8700	;backdrop colour
VDPR_HINT equ $8A00	;h interrupt counter
VDPR_MODE3 equ $8B00
VDPR_MODE4 equ $8C00
VDPR_HSCROLL equ $8D00	;h scroll table address / $400
VDPR_AUTOINC equ $8F00	;auto increment (VmInc macro)
VDPR_PLANESIZE equ $9000
VDPR_WINX equ $9100	;window h position
VDPR_WINY equ $9200	;window v position
VDPR_DMALENL equ $9300
VDPR_DMALENH equ $9400
VDPR_DMASRCL equ $9500
VDPR_DMASRCM equ $9600
VDPR_DMASRCH equ $9700
;VDP control port access commands (long): add (addr&$3FFF)<<16 + addr>>14 for the address
VRAM_W equ $40000000
CRAM_W equ $C0000000
VSRAM_W equ $40000010
; ports



