;	Macros the converter (amiga/tools/convert.py) puts in place of the Genesis video port accesses.
;
;	VCTLW src[,An]	control port word write (register write or half of an address command)
;	VCTLL src[,An]	control port long write
;	VDATAW src	data port word write through the current VDP address (absolute form)
;	VDATAL src	data port long write
;
;	With An given, An is the register the Genesis code used as its port pointer: after the write
;	it holds the pointer into the emulated VRAM / CRAM / VSRAM that the next (An)+ data access
;	uses. A register write leaves An as it was. The flags are set from src, like the original
;	move.

VCTLW	MACRO
	IFNB	\2
	move.l	\2,(hal_vdp_ptr).l
	ENDIF
	move.w	\1,(hal_ctl_tmp).l
	jsr	(hal_vdpctl_w).l
	IFNB	\2
	movea.l	(hal_vdp_ptr).l,\2
	ENDIF
	ENDM

VCTLL	MACRO
	IFNB	\2
	move.l	\2,(hal_vdp_ptr).l
	ENDIF
	move.l	\1,(hal_ctl_tmp).l
	jsr	(hal_vdpctl_l).l
	IFNB	\2
	movea.l	(hal_vdp_ptr).l,\2
	ENDIF
	ENDM

VDATAW	MACRO
	move.l	a6,-(sp)
	movea.l	(hal_vdp_ptr).l,a6
	addq.l	#2,(hal_vdp_ptr).l
	move.w	\1,(a6)
	movea.l	(sp)+,a6
	ENDM

VDATAL	MACRO
	move.l	a6,-(sp)
	movea.l	(hal_vdp_ptr).l,a6
	addq.l	#4,(hal_vdp_ptr).l
	move.l	\1,(a6)
	movea.l	(sp)+,a6
	ENDM
