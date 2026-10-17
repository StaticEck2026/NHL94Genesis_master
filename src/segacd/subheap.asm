;	Sub CPU heap helpers from STARTER.BIN, linked at $21300.
;	Sierra C puts the function name after the rts. These two are EngineIdle
;	and GetData. Verified against STARTER.BIN file offset $4FA8.
;	$24FB4 is the HOCKEY.SEG object. $FF8000 is the sub CPU gate array, used
;	by the routine EngineIdle calls when a free block is at least $8000.

GateCall	equ	$25546				;link a6,#-4, a5 = $FF8000
MoveBlock	equ	$260DE				;three long arguments
AllocAlign	equ	$26656				;tiny lea / jmp thunk
SegHead		equ	$24FB4				;HOCKEY.SEG object

	org	$262A8

; a4 = heap. If $10(SegHead) is clear and the free gap is at least $8000,
; call GateCall(block, $1000, 0).
EngineIdle	link	a6,#0
	move.l	a4,-(sp)
	movea.l	8(a6),a4
	lea	SegHead(pc),a0
	tst.l	$10(a0)
	bne.s	.done
	move.l	8(a4),d0
	sub.l	$C(a4),d0
	move.l	4(a4),d1
	sub.l	d0,d1
	cmpi.l	#$8000,d1
	blt.s	.done
	moveq	#0,d0
	move.l	d0,-(sp)
	pea	$1000.w
	move.l	$10(a4),-(sp)
	jsr	GateCall(pc)
	lea	$C(sp),sp
.done	movea.l	-4(a6),a4
	unlk	a6
	rts
	dc.b	$8A,'EngineIdle',0,0,0

; d0 = pointer. Grows the heap through EngineIdle until [d7,d7+d6] fits,
; then slides the tail up with MoveBlock.
GetData	link	a6,#0
	movem.l	d5-d7/a4,-(sp)
	move.l	$10(a6),d6
	move.l	$C(a6),d7
	movea.l	8(a6),a4
	bra.s	.fit
.grow	move.l	a4,-(sp)
	jsr	EngineIdle(pc)
	addq.w	#4,sp
.fit	move.l	d7,d0
	add.l	d6,d0
	cmp.l	8(a4),d0
	bgt.s	.grow
	move.l	d7,d0
	move.l	4(a4),d1
	jsr	AllocAlign(pc)
	move.l	d0,d5
	add.l	d6,d0
	move.l	d0,d7
	sub.l	4(a4),d7
	tst.l	d7
	ble.s	.skip
	move.l	d7,-(sp)
	move.l	4(a4),d0
	add.l	(a4),d0
	move.l	d0,-(sp)
	move.l	(a4),-(sp)
	jsr	MoveBlock(pc)
	lea	$C(sp),sp
.skip	add.l	(a4),d5
	move.l	d5,d0
	movem.l	-$10(a6),d5-d7/a4
	unlk	a6
	rts
	dc.b	$87,'GetData',0,0
