;	Hardware ports. These equates name the controller ports, the Z80 bus control and the video
;	chip ports.

IO_CT1_CTRL equ $A10008
IO_CT1_DATA equ $A10002
IO_CT1_RX equ $A1000E
IO_CT1_SMODE equ $A10012
IO_CT1_TX equ $A10010
IO_CT2_CTRL equ $A1000A
IO_CT2_DATA equ $A10004
IO_CT2_RX equ $A10014
IO_CT2_SMODE equ $A10018
IO_CT2_TX equ $A10016
IO_EXT_CTRL equ $A1000C
IO_EXT_DATA equ $A10006
IO_EXT_RX equ $A1001A
IO_EXT_SMODE equ $A1001E
IO_EXT_TX equ $A1001C
IO_FDC equ $A12000
IO_PCBVER equ $A10000
IO_RAMMODE equ $A11000
IO_TIME equ $A13000
IO_TMSS equ $A14000
IO_Z80BUS equ $A11100
IO_Z80RES equ $A11200
VDP_CNTR equ $C00008
VDP_CTRL equ $C00004
VDP_DATA equ $C00000
VDP_PSG equ $C00011
VDP__CNTR equ $C0000A
VDP__CTRL equ $C00006
VDP__DATA equ $C00002
VDP___CNTR equ $C0000C
VDP____CNTR equ $C0000E

Vdata equ VDP_DATA	;names: video ports. Control port offset from a0 = Vdata: move.w #x,Vctrl-Vdata(a0) with a0 = VDP_DATA
Vctrl equ Vdata+4
;VDP register write words for the control port (register number in the high byte): move.w #VDPR_MODE2+$74,(VDP_CTRL)
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



