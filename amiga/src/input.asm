;	Controls: Amiga joysticks, CD32 pads and the keyboard, read as two Genesis 3 button pads.

CIAA_PRA	equ	$BFE001
CIAA_SDR	equ	$BFEC01
CIAA_ICR	equ	$BFED01
CIAA_CRA	equ	$BFEE01

JOY0DAT		equ	$00A
JOY1DAT		equ	$00C
POTGO		equ	$034
POTGOR		equ	$016

;	Genesis pad bits (active high here).
PB_UP	equ	0
PB_DOWN	equ	1
PB_LEFT	equ	2
PB_RIGHT equ	3
PB_B	equ	4
PB_C	equ	5
PB_A	equ	6
PB_START equ	7

	section	game,code

;	The keyboard, read at each vertical blank, not by its interrupt: level
;	2 is shared with the IDE port, the PCMCIA slot and expansion cards.
hal_kbd_init
	move.b	#$7F,(CIAA_ICR).l
	tst.b	(CIAA_ICR).l
	andi.b	#$BF,(CIAA_CRA).l
	st	(hal_kbdon).l
	rts

hal_kbd_exit
	move.b	#$7F,(CIAA_ICR).l
	move.b	(os_ciaamask).l,d0
	ori.b	#$80,d0
	move.b	d0,(CIAA_ICR).l
	rts

;	A vertical blank (rd_bq_int): a key code from the keyboard, if one came. Keeps all.
hal_kbd_poll
	tst.b	(hal_kbdon).l
	bne.s	.on
	rts
.on	movem.l	d0-d1/a0,-(sp)
	move.b	(CIAA_ICR).l,d0
	btst	#3,d0
	beq	.x
	move.b	(CIAA_SDR).l,d0
	ori.b	#$40,(CIAA_CRA).l
	not.b	d0
	ror.b	#1,d0
	moveq	#0,d1
	move.b	d0,d1
	andi.b	#$7F,d1
	lea	(hal_keys).l,a0
	tst.b	d0
	bmi	.up
	st	(a0,d1.w)
	cmpi.b	#$45,d1
	bne	.nesc
	st	(hal_quit).l
.nesc	cmpi.b	#$59,d1
	bne	.nf10
	not.b	(hal_fpsshow).l
	bra	.hs
.nf10	cmpi.b	#$56,d1
	bne	.nf7
	jsr	(snd_filter_toggle).l
	bra	.hs
.nf7	cmpi.b	#$55,d1
	bne	.nf6
	eori.l	#1^2,(hal_pace).l
	bra	.hs
.nf6	cmpi.b	#$57,d1
	bne	.nf8
	not.b	(hal_pal).l
	st	(hal_beam).l
	moveq	#0,d0
	move.w	#60,(hal_hz).l
	tst.b	(hal_pal).l
	beq.s	.f8n
	moveq	#$20,d0
	move.w	#50,(hal_hz).l
.f8n	move.w	d0,(CUSTOM+$1DC).l
	jsr	(hal_set_rate).l
	st	(rd_hudchg).l
	bra	.hs
.nf8
	bra	.hs
.up	sf	(a0,d1.w)
.hs
	move.b	(CUSTOM+$006).l,d0
	moveq	#2,d1
.w	cmp.b	(CUSTOM+$006).l,d0
	beq	.w
	move.b	(CUSTOM+$006).l,d0
	dbf	d1,.w
	andi.b	#$BF,(CIAA_CRA).l
.x	movem.l	(sp)+,d0-d1/a0
	rts

;	The two pads: d0 = pad 1, d1 = pad 2, as the Genesis reads them (active
;	low: bit 7 Start, 6 A, 5 C, 4 B, 3 right, 2 left, 1 down, 0 up).
hal_readpads
	IFD	HARNESS
	bra	.pad
	ENDC
	movem.l	d2-d4/a0-a1,-(sp)
	move.w	(CUSTOM+JOY1DAT).l,d0
	bsr	joy_dirs
	move.b	d0,d4
	moveq	#7,d2
	moveq	#14,d3
	bsr	joy_buttons
	or.b	d0,d4
	lea	(hal_keys).l,a0
	lea	(keys_p1,pc),a1
	bsr	keys_pad
	or.b	d0,d4
	move.b	d4,(hal_padstate+1).l
	moveq	#0,d4
	move.w	(CUSTOM+JOY0DAT).l,d0
	sf	(hal_p1mouse).l
	move.w	d0,d1
	andi.w	#$FCFC,d1
	beq.s	.p1j
	st	(hal_p1mouse).l
	bra.s	.p1b
.p1j	bsr	joy_dirs
	move.b	d0,d4
.p1b	moveq	#6,d2
	moveq	#10,d3
	bsr	joy_buttons
	or.b	d0,d4
	lea	(keys_p2,pc),a1
	bsr	keys_pad
	or.b	d0,d4
	move.b	d4,(hal_padstate).l
	tst.w	(cont2team).l
	bne.s	.two
	tst.b	(hal_p1mouse).l
	bne.s	.two
	or.b	d4,(hal_padstate+1).l
.two
	movem.l	(sp)+,d2-d4/a0-a1
	tst.b	(hal_quit).l
	beq	.pad
	jmp	hal_exit
.pad
	move.w	(hal_padstate).l,d0
	not.w	d0
	move.w	d0,d1
	lsr.w	#8,d1
	rts

;	d0 = JOYxDAT -> d0 = direction bits.
joy_dirs
	moveq	#0,d1
	btst	#1,d0
	beq	.nr
	bset	#PB_RIGHT,d1
.nr	btst	#9,d0
	beq	.nl
	bset	#PB_LEFT,d1
.nl	move.w	d0,d2
	lsr.w	#1,d2
	eor.w	d0,d2
	btst	#0,d2
	beq	.nd
	bset	#PB_DOWN,d1
.nd	btst	#8,d2
	beq	.nu
	bset	#PB_UP,d1
.nu	move.b	d1,d0
	rts

;	Buttons of the port with fire bit d2 (CIA-A PRA) and second button bit d3 (POTGOR).
joy_buttons
	movem.l	d1-d6/a0-a1,-(sp)
	lea	(CIAA_PRA).l,a0
	lea	(CUSTOM+POTGOR).l,a1
	move.w	#$6F00,d5
	cmpi.w	#14,d3
	beq	.p2
	move.w	#$F600,d5
.p2	bset	d2,$200(a0)
	bclr	d2,(a0)
	move.w	d5,POTGO-POTGOR(a1)
	moveq	#0,d6
	moveq	#8,d1
	bra	.in
.loop	tst.b	(a0)
	tst.b	(a0)
.in	tst.b	(a0)
	tst.b	(a0)
	tst.b	(a0)
	tst.b	(a0)
	tst.b	(a0)
	tst.b	(a0)
	move.w	(a1),d4
	bset	d2,(a0)
	bclr	d2,(a0)
	btst	d3,d4
	bne	.n
	bset	d1,d6
.n	dbf	d1,.loop
	bclr	d2,$200(a0)
	move.w	#$FF00,POTGO-POTGOR(a1)
	moveq	#0,d0
	move.b	d6,d1
	andi.b	#3,d1
	cmpi.b	#1,d1
	bne	.joy
	btst	#8,d6
	beq	.c1
	bset	#PB_C,d0
.c1	btst	#7,d6
	beq	.c2
	bset	#PB_B,d0
.c2	btst	#6,d6
	beq	.c3
	bset	#PB_A,d0
.c3	btst	#5,d6
	beq	.c4
	bset	#PB_A,d0
.c4	btst	#2,d6
	beq	.x
	bset	#PB_START,d0
	bra	.x
.joy
	btst	d2,(a0)
	bne	.j1
	bset	#PB_B,d0
.j1	move.w	(a1),d4
	btst	d3,d4
	bne	.x
	bset	#PB_C,d0
.x	movem.l	(sp)+,d1-d6/a0-a1
	rts

;	Keys a1 (8 key codes: up, down, left, right, B, C, A, Start; 0 = none) in the key map a0.
keys_pad
	moveq	#0,d0
	moveq	#0,d1
	moveq	#7,d2
.k	move.b	(a1,d1.w),d3
	beq	.n
	andi.w	#$7F,d3
	tst.b	(a0,d3.w)
	beq	.n
	bset	d1,d0
.n	addq.w	#1,d1
	dbf	d2,.k
	rts

keys_p1	dc.b	$4C,$4D,$4F,$4E,$32,$33,$31,$44
keys_p2	dc.b	0,0,0,0,$51,$52,$50,$53
	even

	section	bss,bss
hal_keys	ds.b	128
hal_p1mouse	ds.b	1
	even

hal_quit	ds.b	1
hal_fpsshow	ds.b	1
hal_kbdon	ds.b	1
		even

	section	game,code
