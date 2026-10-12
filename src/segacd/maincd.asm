;	NHL 94 Sega CD, main CPU shell (MAIN.BIN). Linked at $FF0000 in Genesis work RAM.
;	Official Sega CD SDK code: Sierra C (link a6) plus the SDK's main/sub command
;	protocol. The cartridge game does not have this file.
;
;	The sub CPU owns the game. This CPU drives the VDP and trades commands through
;	the gate array ($A1200E flags, $A12010 command words, $A12020 status words).
;	$FF0000-$FF012F is transcribed and verified against MAIN.BIN. Labels past that
;	exist so the branches assemble; their bodies are still in the binary.

	org	$FF0000

MainEntry	jmp	$FF45A8			;slot at $FF45A8 is zero in MAIN.BIN (filled at load, or unused)

; Run one sub command. Stack is saved in work RAM because the handler borrows a7.
RunSubCommand	move.l	a7,$FF2840
	move	sr,-(sp)
	move.w	#0,$FF2844		;command not finished
	bsr.w	ClearMainComm
	bsr.w	SyncFlag7
	bsr.w	ShellInitA
	bsr.w	ShellInitB
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
	bsr.w	ShellInitC
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
	bsr.w	ShellInitB
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

; Bodies live later in MAIN.BIN. The labels keep the branches in $FF0000-$FF012F honest.
	org	$FF0130
ClearMainComm
	org	$FF0172
ShellInitA
	org	$FF017E
ShellInitC
	org	$FF01A4
ShellInitB
	org	$FF01BE
CmdJumpTable
	org	$FF0F2C
DispatchPrep
	org	$FF0F52
DispatchBody
	org	$FF0F78
DispatchAfter
	org	$FF0F9E
DispatchTail
