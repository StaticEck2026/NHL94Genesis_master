;	Controls: Amiga joysticks, CD32 pads and the keyboard, read as two Genesis 3 button pads.
;
;	Player 1: joystick port 2. Player 2: joystick port 1 (the mouse port). In a game of one
;	player a pad in port 1 plays for player 1 too (the game reads only pad 1 then).
;	  CD32 green (yellow)  A
;	  fire / CD32 red      B    (pass, switch player)
;	  2nd fire / CD32 blue C    (shoot, check)
;	  CD32 play            Start
;	Keyboard, player 1: cursor keys, Z = A, X = B, C = C, Return = Start
;	          player 2: F1 = A, F2 = B, F3 = C, F4 = Start
;	Esc goes back to the Workbench (the save file is written then). F7 switches the audio
;	filter, F8 the game's speed (50 / 60 frames a second).

CIAA_PRA	equ	$BFE001
CIAA_SDR	equ	$BFEC01
CIAA_ICR	equ	$BFED01
CIAA_CRA	equ	$BFEE01

JOY0DAT		equ	$00A
JOY1DAT		equ	$00C
POTGO		equ	$034
POTGOR		equ	$016

;	Genesis pad bits (active high here)
PB_UP	equ	0
PB_DOWN	equ	1
PB_LEFT	equ	2
PB_RIGHT equ	3
PB_B	equ	4
PB_C	equ	5
PB_A	equ	6
PB_START equ	7

	section	game,code

;	The keyboard (CIA-A's serial port), read at each vertical blank (hal_kbd_poll), not by
;	its interrupt: level 2 (PORTS) is shared with the IDE port, the PCMCIA slot and expansion
;	cards, and one of those left asking with no driver to answer it would take the CPU from
;	the game and the renderer for good. CIA-A's interrupts off; its flags still say a key came.
hal_kbd_init
	move.b	#$7F,(CIAA_ICR).l		;CIA-A interrupts off
	tst.b	(CIAA_ICR).l			;(its flags cleared)
	andi.b	#$BF,(CIAA_CRA).l		;serial port input
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
	move.b	(CIAA_ICR).l,d0			;(reading clears its flags)
	btst	#3,d0
	beq	.x
	move.b	(CIAA_SDR).l,d0
	ori.b	#$40,(CIAA_CRA).l		;handshake: serial port to output
	not.b	d0
	ror.b	#1,d0				;key code, bit 7 = released
	moveq	#0,d1
	move.b	d0,d1
	andi.b	#$7F,d1
	lea	(hal_keys).l,a0
	tst.b	d0
	bmi	.up
	st	(a0,d1.w)
	cmpi.b	#$45,d1				;Esc
	bne	.nesc
	st	(hal_quit).l
.nesc	cmpi.b	#$59,d1				;F10: frame rate
	bne	.nf10
	not.b	(hal_fpsshow).l
	bra	.hs
.nf10	cmpi.b	#$56,d1				;F7: audio filter
	bne	.nf7
	jsr	(snd_filter_toggle).l
	bra	.hs
.nf7	cmpi.b	#$55,d1				;F6: as many frames as can be / a steady 25 or 30
	bne	.nf6
	eori.l	#1^2,(hal_pace).l
	bra	.hs
.nf6	cmpi.b	#$57,d1				;F8: a 50 / 60 Hz display, the game at its rate
	bne	.nf8
	not.b	(hal_pal).l
	st	(hal_beam).l
	moveq	#0,d0				;BEAMCON0: NTSC
	move.w	#60,(hal_hz).l
	tst.b	(hal_pal).l
	beq.s	.f8n
	moveq	#$20,d0				;PAL
	move.w	#50,(hal_hz).l
.f8n	move.w	d0,(CUSTOM+$1DC).l
	jsr	(hal_set_rate).l
	st	(rd_hudchg).l			;(the HUD sprites' lines are the display's)
	bra	.hs
.nf8
	bra	.hs
.up	sf	(a0,d1.w)
.hs	; hold the handshake at least 85 microseconds: 3 lines
	move.b	(CUSTOM+$006).l,d0
	moveq	#2,d1
.w	cmp.b	(CUSTOM+$006).l,d0
	beq	.w
	move.b	(CUSTOM+$006).l,d0
	dbf	d1,.w
	andi.b	#$BF,(CIAA_CRA).l		;back to input
.x	movem.l	(sp)+,d0-d1/a0
	rts

;	The two pads: d0 = pad 1, d1 = pad 2, as the Genesis reads them (active low: bit 7 Start,
;	6 A, 5 C, 4 B, 3 right, 2 left, 1 down, 0 up). Called by the game's vblank code.
hal_readpads
	IFD	HARNESS
	bra	.pad				;(the test harness writes hal_padstate)
	ENDC
	movem.l	d2-d4/a0-a1,-(sp)
	; player 1: port 2
	move.w	(CUSTOM+JOY1DAT).l,d0
	bsr	joy_dirs
	move.b	d0,d4
	moveq	#7,d2				;fire bit in CIA-A PRA
	moveq	#14,d3				;second button in POTGOR
	bsr	joy_buttons
	or.b	d0,d4
	lea	(hal_keys).l,a0
	lea	(keys_p1,pc),a1
	bsr	keys_pad
	or.b	d0,d4
	move.b	d4,(hal_padstate+1).l
	; player 2: port 1 (a mouse there gives no directions: its counters take any value, a
	; joystick's only bits 0, 1, 8 and 9)
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
	; while the game gives pad 2 no team (a game of one player) port 1's pad is player 1's too,
	; so a lone pad works in either port (not a mouse's buttons)
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



;	d0 = JOYxDAT -> d0 = direction bits
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
;	A CD32 pad is read through its shift register; an ordinary joystick gives fire and 2nd.
;	d0 = pad bits.
joy_buttons
	movem.l	d1-d6/a0-a1,-(sp)
	lea	(CIAA_PRA).l,a0
	lea	(CUSTOM+POTGOR).l,a1
	; CD32 shift register: fire line as output clocks it, pin 9 is the data
	move.w	#$6F00,d5			;POTGO for port 2
	cmpi.w	#14,d3
	beq	.p2
	move.w	#$F600,d5			;port 1
.p2	bset	d2,$200(a0)			;fire pin output
	bclr	d2,(a0)				;low: load
	move.w	d5,POTGO-POTGOR(a1)
	moveq	#0,d6
	moveq	#8,d1				;9 bits: blue, red, yellow, green, fwd, rwd, play, id
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
	bclr	d2,$200(a0)			;fire pin input again
	move.w	#$FF00,POTGO-POTGOR(a1)		;both second buttons as inputs, pulled up
	moveq	#0,d0
	; after its 7 buttons a CD32 pad shifts out a 1 then a 0 (a bit is set here when the line
	; reads low: bit 1 clear, bit 0 set); a joystick's pin 9 gives all 0 or all 1
	move.b	d6,d1
	andi.b	#3,d1
	cmpi.b	#1,d1
	bne	.joy
	btst	#8,d6				;blue: C
	beq	.c1
	bset	#PB_C,d0
.c1	btst	#7,d6				;red: B
	beq	.c2
	bset	#PB_B,d0
.c2	btst	#6,d6				;yellow: A too
	beq	.c3
	bset	#PB_A,d0
.c3	btst	#5,d6				;green: A
	beq	.c4
	bset	#PB_A,d0
.c4	btst	#2,d6				;play
	beq	.x
	bset	#PB_START,d0
	bra	.x
.joy	; ordinary joystick: fire (active low; the CD32 red line) and the second button (blue)
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
;	d0 = pad bits.
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

keys_p1	dc.b	$4C,$4D,$4F,$4E,$32,$33,$31,$44	;cursor keys, X, C, Z, Return
keys_p2	dc.b	0,0,0,0,$51,$52,$50,$53		;F2, F3, F1, F4
	even

	section	bss,bss
hal_keys	ds.b	128
hal_p1mouse	ds.b	1			;port 1 has a mouse (hal_readpads)
	even

hal_quit	ds.b	1
hal_fpsshow	ds.b	1
hal_kbdon	ds.b	1			;the keyboard is read (hal_kbd_init: not in the harness)
		even

	section	game,code
