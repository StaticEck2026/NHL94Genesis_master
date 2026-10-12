;	NHL 94 Sega CD, main CPU shell (MAIN.BIN). Linked at $FF0000 in Genesis work RAM.
;	Official Sega CD SDK code: Sierra C (link a6) plus the SDK's main/sub command
;	protocol. The cartridge game does not have this file.
;
;	The sub CPU owns the game. This CPU drives the VDP and trades commands through
;	the gate array ($A1200E flags, $A12010 command words, $A12020 status words).
;	$FF0000-$FF183F is transcribed and verified. This file is $FF0000-$FF0271.
;	maindma.asm, maincont.asm, mainblit.asm and mainvdp.asm continue it.

	org	$FF0000

MainEntry	jmp	$FF45A8			;slot at $FF45A8 is zero in MAIN.BIN (filled at load, or unused)

; Run one sub command. Stack is saved in work RAM because the handler borrows a7.
RunSubCommand	move.l	a7,$FF2840
	move	sr,-(sp)
	move.w	#0,$FF2844		;command not finished
	bsr.w	ClearMainComm
	bsr.w	SyncFlag7
	bsr.w	WaitModeBit2
	bsr.w	GiveWordRAM
	move	sr,-(sp)
	move	#$2700,sr		;interrupts off
	bsr.w	SwapVBlank
	move.w	#$8164,$C00004		;VDP register 1: display on, DMA, VBlank
	move	(sp)+,sr
.watch	bsr.w	ReadSubCommand
	cmpi.w	#$FFFF,d0		;no command waiting
	beq.s	.watch
	bsr.w	DispatchSubCommand
	tst.w	$FF2844			;handler sets this when the command is done
	beq.s	.watch
	move	#$2700,sr
	move.l	$FF2846,$FFFFFD08.w	;restore the VBlank vector the handler replaced
	jsr	$FF1130.l
	move	(sp)+,sr
	movea.l	$FF2840,a7
	rts

SetCmdPending	move.w	#$FFFF,$FF2844
	rts

; Point the VBlank vector ($FD08, cart vbint) at CD code, keeping the old one.
SwapVBlank	bsr.w	SyncFlag7
	move.l	$FFFFFD08.w,$FF2846
	move.l	#$FF24E4,$FFFFFD08.w
	rts

; d0 = status word the sub CPU posted at $A12020, or -1 if flag bit 6 is clear.
; Bit 6 of $A1200E / $A1200F is the main/sub handshake for that word.
ReadSubCommand	moveq	#-1,d0
	btst.b	#6,$A1200F
	beq.s	.none
	move.w	$A12020,d0
	bset.b	#6,$A1200E
.wait	btst.b	#6,$A1200F
	bne.s	.wait
	bclr.b	#6,$A1200E
.none	rts

; d0 = command number. Longs at CmdJumpTable are distances from the table.
DispatchSubCommand
	bclr.b	#0,$A12014		;drop the main CPU's busy bit while it runs
	move	sr,-(sp)
	move	#$2700,sr
	bsr.w	DispatchPrep
	bsr.w	WaitWordRAM
	bsr.w	DispatchBody
	move	(sp)+,sr
	lsl.w	#2,d0
	lea	CmdJumpTable(pc),a0
	adda.l	(a0,d0.w),a0
	jsr	(a0)
	move	sr,-(sp)
	move	#$2700,sr
	bset.b	#0,$A12014
.wait	btst.b	#1,$A12024		;wait until the sub CPU sees it
	beq.s	.wait
	bsr.w	DispatchAfter
	bsr.w	GiveWordRAM
	bsr.w	DispatchTail
	move	(sp)+,sr
	rts

; Bit 7 is the other handshake (used around VBlank swaps).
SyncFlag7	bset.b	#7,$A1200E
.wait1	btst.b	#7,$A1200F
	beq.s	.wait1
	bclr.b	#7,$A1200E
.wait2	btst.b	#7,$A1200F
	bne.s	.wait2
	rts

; Zero the eight main-to-sub command words ($A12010-$A1201E).
ClearMainComm	move.w	#0,$A12010
	move.w	#0,$A12012
	move.w	#0,$A12014
	move.w	#0,$A12016
	move.w	#0,$A12018
	move.w	#0,$A1201A
	move.w	#0,$A1201C
	move.w	#0,$A1201E
	rts

; Memory mode $A12003 bit 2. Spin until the sub CPU clears it.
WaitModeBit2	btst.b	#2,$A12003
	bne.s	WaitModeBit2
	rts

; Main CPU owns word RAM when DMNA (bit 1) is clear and RET (bit 0) is set.
WaitWordRAM	move	sr,-(sp)
	move	#$2700,sr
.wait	btst.b	#1,$A12003
	bne.s	.wait
	btst.b	#0,$A12003
	beq.s	.wait
	bclr.b	#1,$FF2A16
	move	(sp)+,sr
	rts

; Give word RAM to the sub CPU (set DMNA).
GiveWordRAM	move	sr,-(sp)
	move	#$2700,sr
	bset.b	#1,$A12003
	bset.b	#1,$FF2A16
	move	(sp)+,sr
	rts

; Distances from this table. DispatchSubCommand adds the long to the table address.
; The last two entries fall inside this shell ($FF006C and $FF01BD).
CmdJumpTable	dc.l	$248,$22E,$36C,$1EC
	dc.l	$96,$80,$59C,$5FE
	dc.l	$7AA,$812,$82E,$93C
	dc.l	$B86,$BFA,$C5A,$CCA
	dc.l	$CD6,$CFA,$F44,$111C
	dc.l	$1128,$1156,$117C,$5BE
	dc.l	$63A,$11A2,$11BA,$126C
	dc.l	$12D6,$12F0,$FFFFFEAE,$FFFFFFFF

; Command 5. A pointer the sub CPU wrote, plus $180000, is the same bytes in
; the main CPU's word RAM (sub $080000, main $200000).
StoreLinkedPtr	lea	$23A450,a0
	move.l	(a0)+,d0
	addi.l	#$180000,d0
	lea	LinkedPtr(pc),a0
	move.l	d0,(a0)
	rts

; Command 4. Same translation, then the routine just past this one. d4 is put back.
CallLinkedPtr	lea	$23A450,a0
	move.l	(a0)+,d4
	movea.l	(a0),a2
	adda.l	#$180000,a2
	bsr.w	LinkedCall
	lea	$23A450,a0
	move.l	d4,(a0)
	rts

; Bodies live later in MAIN.BIN. The labels keep the branches above honest.
LinkedCall
	org	$FF0F2C
DispatchPrep
	org	$FF0F52
DispatchBody
	org	$FF0F78
DispatchAfter
	org	$FF0F9E
DispatchTail
	org	$FF1884
LinkedPtr
