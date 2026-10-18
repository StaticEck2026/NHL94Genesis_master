;	NHL 94 Sega CD, sub CPU boot (the front of STARTER.BIN).
;	Runtime base is $21300: the opening jmp lands on a Sierra C `link a6,#0`
;	at $262A8 (file offset $4FA8), which is the SDK heap/film startup.
;
;	This fragment is the file image from the first byte through `jmp $1B000`.
;	It is verified against STARTER.BIN.
;
;	$6044 is the sub CPU BIOS dispatcher (function number in d7).
;	$1B000 is inside HOCKEY.BIN, the game.

	org	$21300

SubBoot	move.l	$6038.w,$B090		;keep the BIOS vector the game will call through
	jmp	$262A8						;C runtime (link a6). Does not return here

; Reached again after that runtime if it jumps back, or entered on its own.
RestoreBios	move.l	$B090,$6038.w
.waitbios	btst.b	#7,$FF800E		;main CPU flag
	bne.s	.waitbios
	move.w	#$2E,$FF8020			;sub status word
	bset.b	#6,$FF800F
.wait6	btst.b	#6,$FF800E
	beq.s	.wait6
	bset.b	#7,$FF800F
	bclr.b	#6,$FF800F
.wait6b	btst.b	#6,$FF800E
	bne.s	.wait6b
	bclr.b	#7,$FF800F
	bset.b	#5,$FF800F				;BIOS call in progress
	move.l	#$1B000,d0				;HOCKEY.BIN entry (file offset $1B000)
	move.l	#$92,d1
	move.l	#$4F,d2
	move.w	#0,d7					;BIOS function 0
	jsr	$6044.w
	adda.w	#$C,sp					;BIOS function 0 takes 3 long arguments
	bclr.b	#5,$FF800F
	jmp	$1B000						;into the game
