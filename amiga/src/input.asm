;	Controls: Amiga joysticks, CD32 pads and the keyboard, read as two Genesis 3 button pads.
;
;	Player 1: joystick port 2. Player 2: joystick port 1 (the mouse port).
;	  fire / CD32 red      C    (shoot, check)
;	  2nd fire / CD32 blue B    (pass, switch player)
;	  CD32 green / yellow  A
;	  CD32 play            Start
;	Keyboard, player 1: cursor keys, Z = A, X = B, C = C, Return = Start
;	          player 2: F1 = A, F2 = B, F3 = C, F4 = Start
;	Esc goes back to the Workbench (the save file is written then). F7 switches the audio
;	filter, F8 the game's speed (50 / 60 frames a second).

CIAA_PRA	equ	$BFE001
CIAA_DDRA	equ	$BFE201
CIAA_SDR	equ	$BFEC01
CIAA_ICR	equ	$BFED01
CIAA_CRA	equ	$BFEE01
CIAA_CRB	equ	$BFEF01
CIAA_TBLO	equ	$BFE601
CIAA_TBHI	equ	$BFE701

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

;	Keyboard interrupt on (level 2, CIA-A serial port).
hal_kbd_init
	lea	(hal_vectors).l,a0
	lea	hal_int2(pc),a1
	move.l	a1,$68(a0)
	tst.b	(CIAA_ICR).l			;clear
	move.b	#$88,(CIAA_ICR).l		;serial port interrupt on
	andi.b	#$BF,(CIAA_CRA).l		;serial port input
	move.w	#$0008,(CUSTOM+INTREQ).l
	move.w	#$8008,(CUSTOM+INTENA).l	;PORTS
	rts

hal_kbd_exit
	move.b	#$7F,(CIAA_ICR).l
	move.b	(os_ciaamask).l,d0
	ori.b	#$80,d0
	move.b	d0,(CIAA_ICR).l
	rts

;	Level 2: a key code from the keyboard.
hal_int2
	movem.l	d0-d1/a0,-(sp)
	move.b	(CIAA_ICR).l,d0
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
.nf7	cmpi.b	#$55,d1				;F6: a steady 25 frames a second / as many as can be
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
	IFD	PROFILE
	cmpi.b	#$58,d1				;F9: mark the start of the frame rate count
	bne	.hs
	bsr	prof_f9
	moveq	#$58,d1
	lea	(hal_keys).l,a0
	ENDIF
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
.x	move.w	#$0008,(CUSTOM+INTREQ).l
	move.w	#$0008,(CUSTOM+INTREQ).l
	movem.l	(sp)+,d0-d1/a0
	rte

;	The two pads: d0 = pad 1, d1 = pad 2, as the Genesis reads them (active low: bit 7 Start,
;	6 A, 5 C, 4 B, 3 right, 2 left, 1 down, 0 up). Called by the game's vblank code.
hal_readpads
	tst.b	(hal_amiga).l
	beq	.harness			;the test harness writes hal_padstate itself
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
	; player 2: port 1
	move.w	(CUSTOM+JOY0DAT).l,d0
	bsr	joy_dirs
	move.b	d0,d4
	moveq	#6,d2
	moveq	#10,d3
	bsr	joy_buttons
	or.b	d0,d4
	lea	(keys_p2,pc),a1
	bsr	keys_pad
	or.b	d0,d4
	move.b	d4,(hal_padstate).l
	IFD	BENCH
	tst.b	(bench_start).l
	beq.s	.nbs
	bset	#7,(hal_padstate+1).l		;(Start, pad 1)
.nbs
	ENDC
	movem.l	(sp)+,d2-d4/a0-a1
	tst.b	(hal_quit).l
	beq	.harness
	jmp	hal_exit
.harness
	move.w	(hal_padstate).l,d0
	not.w	d0
	move.w	d0,d1
	lsr.w	#8,d1
	rts

	IFD	PROFILE
;	Mark the start of the frame rate count (F9). Uses d1, a0.
prof_f9
	move.l	(rd_count).l,(prof_mark).l
	move.l	(hal_frames).l,(prof_mark+4).l
	lea	(prof_mark+20).l,a0
	moveq	#8+16+4-1,d1
.ch	clr.l	(a0)+
	dbf	d1,.ch
	rts
	ENDC

	IFD	BENCH
;	Benchmark builds (-DBENCH=1, for FS-UAE): the same game every run and every build. Called
;	at each game tick, before the game's vblank code; a tick never comes while the game runs
;	(hal_int6 puts it off to the game's next wait, hal_idle), so the count is the game's own:
;	the game's random numbers (HVcount) come from it, Start is pressed at the test harness'
;	counts (from the attract mode into a game), the frame rate count starts at BENCHSTART (as
;	F9, PROFILE builds) and the game quits at BENCHEND. Keeps all.
	IFND	BENCHSTART
BENCHSTART	equ	2000
	ENDC
	IFND	BENCHEND
BENCHEND	equ	6000
	ENDC
bench_wait
	movem.l	d0-d1/a0,-(sp)
	IFD	PROFILE
	movem.l	d2/a1,-(sp)			;(statistics: a sum of every 64th long of the game's RAM
	lea	(RAMBASE).l,a0			;at each tick, to find where two runs part)
	moveq	#0,d0
	move.w	#$10000/256-1,d1
.ts	add.l	(a0),d0
	rol.l	#1,d0
	lea	256(a0),a0
	dbf	d1,.ts
	move.l	(bench_n).l,d1
	andi.l	#BTLOG-1,d1
	lea	(bench_tlog).l,a1
	move.l	d0,(a1,d1.l*4)
	IFD	BENCHDUMP
	cmpi.l	#BENCHDUMP,(bench_n).l		;(the game's RAM at that tick, for the exit's dump)
	bne.s	.nd
	lea	(RAMBASE).l,a0
	lea	(bench_ram).l,a1
	move.w	#$10000/4-1,d1
.dc	move.l	(a0)+,(a1)+
	dbf	d1,.dc
.nd
	ENDC
	movem.l	(sp)+,d2/a1
	ENDC
	addq.l	#1,(bench_n).l
	move.l	(bench_n).l,d0
	move.l	d0,d1
	mulu.l	#$9E3779B1,d1
	swap	d1
	move.w	d1,(hal_hv).l
	sf	(bench_start).l
	cmpi.l	#700,d0				;Start at 700, 820 .. 1180, for 10
	blo.s	.np
	cmpi.l	#1190,d0
	bhs.s	.np
	subi.l	#700,d0
	divu.w	#120,d0
	swap	d0
	cmpi.w	#10,d0
	bhs.s	.np
	st	(bench_start).l
.np	move.l	(bench_n).l,d0
	IFD	PROFILE
	cmpi.l	#BENCHSTART,d0
	bne.s	.nm
	bsr	prof_f9
.nm
	ENDC
	IFD	MEMBENCH
	cmpi.l	#BENCHSTART+1,d0
	bne.s	.nb
	bsr	prof_memb
.nb
	ENDC
	cmpi.l	#BENCHEND,d0
	blo.s	.x
	IFD	PROFILE
	tst.b	(hal_quit).l
	bne.s	.q
	lea	(RAMBASE).l,a0			;(statistics: the game's RAM summed, to see that the
	move.w	#($10000-$400)/4-1,d1		;runs played the same game; not the stacks at the top)
	moveq	#0,d0
.sum	add.l	(a0)+,d0
	rol.l	#1,d0
	dbf	d1,.sum
	move.l	d0,(prof_mark+128).l
	ENDC
.q	st	(hal_quit).l
.x	movem.l	(sp)+,d0-d1/a0
	rts
	IFD	MEMBENCH
;	(statistics) Colour clocks for 1024 word writes to chip memory, fast memory, a custom
;	register (NO-OP), 1024 chip reads, and 256 chip writes while the blitter runs a blit
;	with all four channels: prof_mark+92 ... +108.
prof_memb
	movem.l	d0-d7/a0-a2/a6,-(sp)
	jsr	(rd_waitblit).l
	move	sr,-(sp)
	ori	#$0700,sr
	lea	(mb_chip).l,a0
	bsr	mb_now
	move.l	d0,d6
	moveq	#127,d1
.c	REPT	8
	move.w	d0,(a0)+
	ENDR
	dbf	d1,.c
	bsr	mb_now
	sub.l	d6,d0
	move.l	d0,(prof_mark+92).l
	lea	(prof_buf).l,a0
	bsr	mb_now
	move.l	d0,d6
	moveq	#127,d1
.f	REPT	8
	move.w	d0,(a0)+
	ENDR
	dbf	d1,.f
	bsr	mb_now
	sub.l	d6,d0
	move.l	d0,(prof_mark+96).l
	lea	(CUSTOM+$1FE).l,a0
	bsr	mb_now
	move.l	d0,d6
	moveq	#127,d1
.r	REPT	8
	move.w	d0,(a0)
	ENDR
	dbf	d1,.r
	bsr	mb_now
	sub.l	d6,d0
	move.l	d0,(prof_mark+100).l
	lea	(mb_chip).l,a0
	bsr	mb_now
	move.l	d0,d6
	moveq	#127,d1
.rd	REPT	8
	move.w	(a0)+,d2
	ENDR
	dbf	d1,.rd
	bsr	mb_now
	sub.l	d6,d0
	move.l	d0,(prof_mark+104).l
	; a blit (A, B, C, D) over mb_blt, 64 words by 64 rows, and chip writes meanwhile
	lea	(CUSTOM).l,a6
	jsr	(rd_cq_inval).l
	move.l	#$0FCA0000,$040(a6)
	move.l	#-1,$044(a6)
	lea	(mb_blt).l,a1
	move.l	a1,$048(a6)
	move.l	a1,$04C(a6)
	move.l	a1,$050(a6)
	move.l	a1,$054(a6)
	clr.l	$060(a6)
	clr.l	$064(a6)
	move.w	#64,$05C(a6)
	move.w	#64,$05E(a6)
	lea	(mb_chip).l,a0
	bsr	mb_now
	move.l	d0,d6
	moveq	#31,d1
.b	REPT	8
	move.w	d0,(a0)+
	ENDR
	dbf	d1,.b
	bsr	mb_now
	sub.l	d6,d0
	btst	#6,(CUSTOM+DMACONR).l		;(the blit still runs: bit 31)
	beq.s	.bd
	bset	#31,d0
.bd	move.l	d0,(prof_mark+108).l
	move	(sp)+,sr
	jsr	(rd_waitblit).l
	movem.l	(sp)+,d0-d7/a0-a2/a6
	rts
;	The beam's place in colour clocks from the frame's start (d0). Uses d0.
mb_now
	move.l	d1,-(sp)
	move.l	(CUSTOM+$004).l,d0
	andi.l	#$1FFFF,d0
	move.l	d0,d1
	lsr.l	#8,d1
	mulu.w	#227,d1
	andi.w	#$FF,d0
	ext.l	d0
	add.l	d1,d0
	move.l	(sp)+,d1
	rts
	ENDC
bench_n		dc.l	0
	IFD	PROFILE
BTLOG		equ	8192
	ENDC
bench_start	dc.b	0
	even
	ENDC

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
	; a CD32 pad shifts out 1 then 0 as its last bits (bits 1, 0 here: 0 1 read as low)
	move.b	d6,d1
	andi.b	#3,d1
	cmpi.b	#2,d1
	bne	.joy
	btst	#8,d6				;blue
	beq	.c1
	bset	#PB_B,d0
.c1	btst	#7,d6				;red
	beq	.c2
	bset	#PB_C,d0
.c2	btst	#6,d6				;yellow
	beq	.c3
	bset	#PB_A,d0
.c3	btst	#5,d6				;green
	beq	.c4
	bset	#PB_A,d0
.c4	btst	#2,d6				;play
	beq	.x
	bset	#PB_START,d0
	bra	.x
.joy	; ordinary joystick: fire (active low) and the second button
	btst	d2,(a0)
	bne	.j1
	bset	#PB_C,d0
.j1	move.w	(a1),d4
	btst	d3,d4
	bne	.x
	bset	#PB_B,d0
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

hal_quit	ds.b	1
hal_fpsshow	ds.b	1
		even

	section	game,code
