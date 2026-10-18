;	Sound: stands in for the Genesis Z80 and its YM2612 / DAC with the Amiga's four Paula voices.
;
;	The game's 68000 sound driver (sound94.asm) runs unchanged and talks to its Z80 program
;	through the Z80 RAM (hal_z80ram here). Its 33 byte command buffer (Z80 RAM $02-$22) holds
;	bit masks of the FM channels to key off, key on, give a new attenuation, a new frequency
;	and a new patch, then the attenuation, frequency and patch of each channel. A PCM sound is
;	its start address, Z80 RAM $8E the playback rate (0 = stop) and $83 the volume.
;
;	The FM patches are samples made at build time (amiga/tools/fmrender.py: an attack then a
;	loop, at the pitch bands the patch is used at). A key on takes a voice (a free one, else
;	the quietest released one, else the oldest) and plays the patch's sample at the note's
;	pitch; the rest of the patch's envelope (decay, release at key off) is a volume envelope
;	stepped at 60 Hz. The PCM samples are copied to chip RAM as signed bytes at start.
;
;	snd_z80_cmd takes a command from the driver (it is called where the driver hands the Z80
;	its command); snd_z80_poll, from the 60 Hz interrupt, does the work on Paula.

AUD0LC		equ	$0A0			;voice n at + n * $10: LC, LEN, PER, VOL
PCMHZ		equ	30594			;the Z80 PCM loop: 117 T states at 3.58 MHz
PAULACLK	equ	3546895
FRAMECLK	equ	PAULACLK/60		;Paula clocks a frame

;	voice
V_OWNER		equ	0			;.b -1 free, 0-6 FM channel, 7 PCM
V_STATE		equ	1			;.b
V_FRAMES	equ	2			;.w frames left of the attack / one shot sample
V_ENV		equ	4			;.l envelope attenuation, 8.8 units (1023 = 96 dB)
V_TL		equ	8			;.w note attenuation (units)
V_AGE		equ	10			;.w key on order
V_PATCH		equ	12			;.l the patch's fm_patch_table entry
V_RENDER	equ	16			;.l its fm_render_table entry
V_SL		equ	20			;.l decay left before the sustain (8.8)
V_REL		equ	24			;.b released (key off)
V_SIZE		equ	32

ST_FREE		equ	0
ST_ATTACK	equ	1			;the sample's attack is playing
ST_DECAY	equ	2
ST_SUSTAIN	equ	3
ST_ONESHOT	equ	4			;a sample with no loop is playing
ST_PCM		equ	5

PCM_OWNER	equ	7

	include	"fm_patches.i"		;the FM patch samples and tables (fmrender.py)

	section	game,code

;	Start: PCM samples to chip RAM (signed), voices free, Paula quiet.
snd_init
	movem.l	d0-d2/a0-a2,-(sp)
	lea	sfx_shotbh_pcm,a0
	lea	(snd_pcmdata).l,a1
	move.l	#fm_instrument_patches-sfx_shotbh_pcm-1,d0
.cp	move.b	(a0)+,d1
	eori.b	#$80,d1
	move.b	d1,(a1)+
	subq.l	#1,d0
	bpl	.cp
	; length of each PCM patch's sound: up to the 0 that ends it
	lea	pcm_sample_table,a0
	lea	(snd_pcm_len).l,a1
	moveq	#14,d2
.len	move.l	(a0),d0
	addq.w	#8,a0
	moveq	#0,d1
	tst.l	d0
	beq	.nl
	movea.l	d0,a2
.scan	tst.b	(a2)+
	beq	.nl
	addq.l	#1,d1
	bra	.scan
.nl	move.l	d1,(a1)+
	dbf	d2,.len
	lea	(snd_voices).l,a0
	moveq	#3,d0
.v	move.b	#-1,V_OWNER(a0)
	clr.b	V_STATE(a0)
	lea	V_SIZE(a0),a0
	dbf	d0,.v
	lea	(snd_chvoice).l,a0
	moveq	#7,d0
.c	move.b	#-1,(a0)+
	dbf	d0,.c
	move.w	#$000F,(CUSTOM+DMACON).l
	lea	(CUSTOM+AUD0LC).l,a0
	moveq	#3,d0
.q	clr.w	8(a0)
	lea	$10(a0),a0
	dbf	d0,.q
	movem.l	(sp)+,d0-d2/a0-a2
	rts

;	The driver has written a command to the Z80 RAM: note what it asks for (snd_z80_poll does
;	it) and answer as the Z80 does when it is done.
snd_z80_cmd
	move	sr,-(sp)
	ori	#$0700,sr
	movem.l	d0-d1/a0,-(sp)
	lea	(hal_z80ram).l,a0
	move.b	$96(a0),d0
	cmpi.b	#$D1,d0
	bne	.npcm
	; command buffer: key off cancels a key on not yet done
	move.b	2(a0),d0			;key off
	move.b	d0,d1
	not.b	d1
	and.b	d1,(snd_pend_on).l
	or.b	d0,(snd_pend_off).l
	move.b	3(a0),d0
	or.b	d0,(snd_pend_on).l
	move.b	4(a0),d0
	or.b	d0,(snd_pend_att).l
	move.b	5(a0),d0
	or.b	d0,(snd_pend_frq).l
	bra	.ack
.npcm	cmpi.b	#$29,d0
	bne	.ack
	st	(snd_pcm_start).l		;start the PCM sound at snd_pcm_addr
.ack	move.b	#$7D,$96(a0)			;idle
	clr.b	$97(a0)
	movem.l	(sp)+,d0-d1/a0
	move	(sp)+,sr
	rts

;	60 Hz: carry out the driver's commands on Paula and step the envelopes.
snd_z80_poll
	movem.l	d0-d7/a0-a6,-(sp)
	lea	(hal_z80ram).l,a5
	lea	(CUSTOM).l,a6
	moveq	#0,d7				;voices to start
	; key off (not of a channel keyed on again: that plays again on its voice)
	move.b	(snd_pend_off).l,d0
	clr.b	(snd_pend_off).l
	move.b	(snd_pend_on).l,d1
	not.b	d1
	and.b	d1,d0
	moveq	#0,d1
.off	lsr.b	#1,d0
	bcc	.noff
	bsr	snd_release
.noff	addq.w	#1,d1
	tst.b	d0
	bne	.off
	; new frequencies of sounding notes
	move.b	(snd_pend_frq).l,d0
	clr.b	(snd_pend_frq).l
	moveq	#0,d1
.frq	lsr.b	#1,d0
	bcc	.nfrq
	bsr	snd_chan_voice
	bmi	.nfrq
	bsr	snd_fm_period
	move.w	d2,6(a1)			;AUDxPER
.nfrq	addq.w	#1,d1
	tst.b	d0
	bne	.frq
	; new attenuations
	move.b	(snd_pend_att).l,d0
	clr.b	(snd_pend_att).l
	moveq	#0,d1
.att	lsr.b	#1,d0
	bcc	.natt
	bsr	snd_chan_voice
	bmi	.natt
	moveq	#0,d2
	move.b	7(a5,d1.w),d2			;attenuation (TL, 0.75 dB)
	lsl.w	#3,d2
	move.w	d2,V_TL(a0)
.natt	addq.w	#1,d1
	tst.b	d0
	bne	.att
	; key on
	move.b	(snd_pend_on).l,d0
	clr.b	(snd_pend_on).l
	moveq	#0,d1
.on	lsr.b	#1,d0
	bcc	.non
	bsr	snd_keyon
.non	addq.w	#1,d1
	tst.b	d0
	bne	.on
	; PCM
	bsr	snd_pcm
	; start the new sounds: their DMA off, then the sample, then on again
	tst.b	d7
	beq	.nost
	move.w	d7,DMACON(a6)
	bsr	snd_dmawait
	lea	(snd_voices).l,a0
	lea	AUD0LC(a6),a1
	moveq	#0,d1
.st	btst	d1,d7
	beq	.nst
	move.l	V_RENDER(a0),a2
	move.l	(a2),(a1)			;sample
	move.w	4(a2),4(a1)			;length (words)
	clr.w	8(a1)
.nst	lea	V_SIZE(a0),a0
	lea	$10(a1),a1
	addq.w	#1,d1
	cmpi.w	#4,d1
	bne	.st
	move.w	d7,d0
	ori.w	#$8000,d0
	move.w	d0,DMACON(a6)
	bsr	snd_dmawait			;the voices have taken the start: now the repeat
	lea	(snd_voices).l,a0
	lea	AUD0LC(a6),a1
	moveq	#0,d1
.rp	btst	d1,d7
	beq	.nrp
	move.l	V_RENDER(a0),a2
	move.w	8(a2),d0			;loop length
	beq	.one
	move.l	(a2),d2
	moveq	#0,d3
	move.w	6(a2),d3
	add.l	d3,d2				;+ loop start
	move.l	d2,(a1)
	move.w	d0,4(a1)
	bra	.nrp
.one	move.l	#fm_silence,(a1)
	move.w	#1,4(a1)
.nrp	lea	V_SIZE(a0),a0
	lea	$10(a1),a1
	addq.w	#1,d1
	cmpi.w	#4,d1
	bne	.rp
.nost	bsr	snd_envelopes
	movem.l	(sp)+,d0-d7/a0-a6
	rts

;	Wait while Paula notices a DMA change: 4 lines.
snd_dmawait
	tst.b	(hal_amiga).l
	beq	.x
	movem.l	d0-d1,-(sp)
	moveq	#3,d1
.l	move.b	(CUSTOM+$006).l,d0
.w	cmp.b	(CUSTOM+$006).l,d0
	beq	.w
	dbf	d1,.l
	movem.l	(sp)+,d0-d1
.x	rts

;	d1 = FM channel: a0 = its voice, a1 = the voice's Paula registers, N set if it has none.
snd_chan_voice
	lea	(snd_chvoice).l,a0
	move.b	(a0,d1.w),d2
	bpl	snd_voice_a0
	rts					;N set
snd_voice_a0
	ext.w	d2
	lsl.w	#4,d2
	lea	AUD0LC(a6,d2.w),a1
	add.w	d2,d2
	lea	(snd_voices).l,a0
	adda.w	d2,a0
	moveq	#0,d2				;N clear
	rts

;	Key off FM channel d1: its voice goes to its release.
snd_release
	bsr	snd_chan_voice
	bmi	.x
	st	V_REL(a0)
	lea	(snd_chvoice).l,a1
	move.b	#-1,(a1,d1.w)
.x	rts

;	Voice a0's period for FM channel d1's frequency: d2.
snd_fm_period
	movem.l	d0-d1/a2,-(sp)
	move.w	14(a5,d1.w*2),d0		;block << 11 | fnum (Z80 RAM $0E + 2n)
	move.w	d0,d1
	andi.w	#$07FF,d0
	rol.w	#5,d1
	andi.w	#7,d1
	ext.l	d0
	lsl.l	d1,d0				;fnum << block
	bne	.nz
	moveq	#1,d0
.nz	move.l	V_RENDER(a0),a2
	move.l	12(a2),d2			;period numerator
	divu.l	d0,d2
	cmpi.l	#124,d2
	bhs	.lo
	moveq	#124,d2
.lo	cmpi.l	#$FFFF,d2
	bls	.hi
	move.w	#$FFFF,d2
.hi	movem.l	(sp)+,d0-d1/a2
	rts

;	Voice a0 has started a sample of d2 bytes at period d3: frames until it is played.
snd_sample_frames
	andi.l	#$FFFF,d3
	mulu.l	d3,d2
	divu.l	#FRAMECLK,d2
	addq.w	#1,d2
	move.w	d2,V_FRAMES(a0)
	rts

;	Key on FM channel d1 (patch, frequency and attenuation from the Z80 RAM). d7 |= its voice.
snd_keyon
	movem.l	d0-d1,-(sp)
	bsr	snd_chan_voice
	bpl	.have				;still on (no key off): play again on the same voice
	moveq	#0,d2				;not PCM
	bsr	snd_alloc
	lea	(snd_chvoice).l,a1
	move.b	d2,(a1,d1.w)
	bsr	snd_voice_a0
.have	move.b	d1,V_OWNER(a0)
	sf	V_REL(a0)
	clr.l	V_ENV(a0)
	addq.w	#1,(snd_age).l
	move.w	(snd_age).l,V_AGE(a0)
	moveq	#0,d2
	move.b	7(a5,d1.w),d2
	lsl.w	#3,d2
	move.w	d2,V_TL(a0)
	; the patch's render for the note's band
	moveq	#31,d0
	and.b	$1C(a5,d1.w),d0		;patch (Z80 RAM $1C + n)
	mulu.w	#FM_PATCH_SIZE,d0
	lea	fm_patch_table,a2
	adda.w	d0,a2
	move.l	a2,V_PATCH(a0)
	move.w	14(a5,d1.w*2),d0
	move.w	d0,d2
	andi.l	#$07FF,d0
	rol.w	#5,d2
	andi.w	#7,d2
	lsl.l	d2,d0				;fnum << block
	lea	fm_band_lo,a3
	moveq	#0,d2
.band	cmp.l	(a3)+,d0
	blo	.bd
	addq.w	#2,d2
	cmpi.w	#2*(FM_BANDS-1),d2
	bne	.band
.bd	move.w	(a2,d2.w),d2
	lea	fm_render_table,a3
	adda.w	d2,a3
	move.l	a3,V_RENDER(a0)
	bsr	snd_fm_period
	move.w	d2,d3
	move.w	d3,6(a1)
	moveq	#0,d2
	move.w	6(a3),d2			;loop start = attack length
	move.b	#ST_ATTACK,V_STATE(a0)
	tst.w	8(a3)
	bne	.loop
	move.w	4(a3),d2			;one shot: all of it
	add.l	d2,d2
	move.b	#ST_ONESHOT,V_STATE(a0)
.loop	bsr	snd_sample_frames
	move.w	12(a2),d0			;decay
	move.w	d0,d2
	mulu.w	#256,d2
	move.l	d2,V_SL(a0)
	movea.l	a0,a1
	suba.l	#snd_voices,a1
	move.l	a1,d0
	lsr.w	#5,d0
	bset	d0,d7
	movem.l	(sp)+,d0-d1
	rts

;	A voice for a new sound (d2 = -1 for the PCM sound, it takes the PCM voice if it has one):
;	a free one, else the quietest released one, else the oldest FM one. d2 = voice number.
;	The FM channel that had it loses it.
snd_alloc
	movem.l	d0-d1/d3-d5/a0,-(sp)
	lea	(snd_voices).l,a0
	tst.b	d2
	beq	.nopcm
	moveq	#3,d0
.pv	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	beq	.got
	lea	V_SIZE(a0),a0
	dbf	d0,.pv
	lea	(snd_voices).l,a0
.nopcm	moveq	#3,d0
.fr	tst.b	V_STATE(a0)
	beq	.got
	lea	V_SIZE(a0),a0
	dbf	d0,.fr
	; quietest released
	lea	(snd_voices).l,a0
	moveq	#-1,d4				;best
	moveq	#-1,d5				;its envelope
	moveq	#3,d0
.rl	tst.b	V_REL(a0)
	beq	.nrl
	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	beq	.nrl
	move.l	V_ENV(a0),d1
	cmp.l	d5,d1
	ble	.nrl
	move.l	d1,d5
	move.w	d0,d4
.nrl	lea	V_SIZE(a0),a0
	dbf	d0,.rl
	tst.w	d4
	bpl	.idx
	; oldest FM voice
	lea	(snd_voices).l,a0
	move.w	(snd_age).l,d3
	moveq	#0,d5				;greatest age
	moveq	#3,d0
.ol	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	beq	.nol
	move.w	d3,d1
	sub.w	V_AGE(a0),d1
	cmp.w	d5,d1
	blo	.nol
	move.w	d1,d5
	move.w	d0,d4
.nol	lea	V_SIZE(a0),a0
	dbf	d0,.ol
	tst.w	d4
	bpl	.idx
	moveq	#3,d4				;(cannot be: only one PCM voice)
.idx	moveq	#3,d0
	sub.w	d4,d0
	move.w	d0,d2
	bra	.take
.got	moveq	#3,d2
	sub.w	d0,d2
.take	; the channel playing on it loses it
	lea	(snd_voices).l,a0
	move.w	d2,d0
	lsl.w	#5,d0
	moveq	#0,d1
	move.b	V_OWNER(a0,d0.w),d1
	cmpi.b	#PCM_OWNER,d1
	bhs	.x
	lea	(snd_chvoice).l,a0
	cmp.b	(a0,d1.w),d2
	bne	.x
	move.b	#-1,(a0,d1.w)
.x	movem.l	(sp)+,d0-d1/d3-d5/a0
	rts

;	The PCM channel: start a sound, or follow its rate (0 = stop) and volume.
snd_pcm
	moveq	#0,d1
	move.b	$8E(a5),d1			;rate
	tst.b	(snd_pcm_start).l
	beq	.run
	sf	(snd_pcm_start).l
	tst.w	d1
	beq	.x
	; which sound: its pcm_sample_table entry
	move.l	(snd_pcm_addr).l,d0
	lea	pcm_sample_table,a0
	moveq	#0,d2
.find	cmp.l	(a0,d2.w*8),d0
	beq	.found
	addq.w	#1,d2
	cmpi.w	#15,d2
	bne	.find
	bra	.x
.found	lea	(snd_pcm_len).l,a0
	move.l	(a0,d2.w*4),d3			;bytes
	beq	.x
	moveq	#-1,d2
	bsr	snd_alloc
	bsr	snd_voice_a0
	move.b	#PCM_OWNER,V_OWNER(a0)
	move.b	#ST_PCM,V_STATE(a0)
	sf	V_REL(a0)
	clr.l	V_ENV(a0)
	addq.w	#1,(snd_age).l
	move.w	(snd_age).l,V_AGE(a0)
	lea	(snd_pcm_render).l,a2		;a render of its own: the sample, then silence
	move.l	d0,d2
	sub.l	#sfx_shotbh_pcm,d2
	add.l	#snd_pcmdata,d2
	move.l	d2,(a2)
	addq.l	#1,d3
	lsr.l	#1,d3
	move.w	d3,4(a2)			;words
	clr.l	6(a2)				;no loop
	move.l	a2,V_RENDER(a0)
	bsr	snd_pcm_period
	move.w	d2,6(a1)
	move.l	d2,d4
	move.l	d3,d2
	add.l	d2,d2
	move.l	d4,d3
	bsr	snd_sample_frames
	movea.l	a0,a2
	suba.l	#snd_voices,a2
	move.l	a2,d0
	lsr.w	#5,d0
	bset	d0,d7
	bra	.vol
.run	; the sounding PCM voice
	lea	(snd_voices).l,a0
	lea	AUD0LC(a6),a1
	moveq	#3,d0
.pv	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	beq	.on
	lea	V_SIZE(a0),a0
	lea	$10(a1),a1
	dbf	d0,.pv
	bra	.x
.on	tst.w	d1
	bne	.rate
	clr.b	V_STATE(a0)			;stopped
	move.b	#-1,V_OWNER(a0)
	clr.w	8(a1)
	bra	.x
.rate	bsr	snd_pcm_period
	move.w	d2,6(a1)
.vol	moveq	#0,d1				;volume: 8 / (8 + $1F - v) of full, v = 3-$1F
	move.b	$83(a5),d1
	cmpi.w	#$1F,d1
	bls	.v1
	moveq	#$1F,d1
.v1	moveq	#39,d2
	sub.w	d1,d2
	move.l	#512,d1
	divu.w	d2,d1
	move.w	d1,V_TL(a0)			;the PCM voice keeps its Paula volume here
.x	rts

;	d1 = PCM rate (Z80 RAM $8E, steps of 1/256 sample at PCMHZ): d2 = period.
snd_pcm_period
	move.l	#(PAULACLK*16/PCMHZ)*16,d2
	divu.w	d1,d2				;(rate >= 1: at most 29664)
	andi.l	#$FFFF,d2
	cmpi.w	#124,d2
	bhs	.x
	moveq	#124,d2
.x	rts

;	Step the voices' envelopes and set their volumes.
snd_envelopes
	lea	(snd_voices).l,a0
	lea	AUD0LC(a6),a1
	moveq	#3,d6
.v	moveq	#0,d0
	move.b	V_STATE(a0),d0
	beq	.next
	cmpi.b	#ST_PCM,d0
	beq	.pcm
	movea.l	V_PATCH(a0),a2
	move.l	V_ENV(a0),d1
	tst.b	V_REL(a0)
	beq	.nrel
	moveq	#0,d2
	move.w	2*FM_BANDS+6(a2),d2		;release
	add.l	d2,d1
.nrel	cmpi.b	#ST_ATTACK,d0
	beq	.att
	cmpi.b	#ST_ONESHOT,d0
	beq	.one
	tst.b	V_REL(a0)
	bne	.set
	cmpi.b	#ST_DECAY,d0
	bne	.sus
	moveq	#0,d2
	move.w	2*FM_BANDS(a2),d2		;decay
	add.l	d2,d1
	sub.l	d2,V_SL(a0)
	bhi	.set
	move.b	#ST_SUSTAIN,V_STATE(a0)
	bra	.set
.sus	moveq	#0,d2
	move.w	2*FM_BANDS+4(a2),d2		;sustain decay
	add.l	d2,d1
	bra	.set
.att	subq.w	#1,V_FRAMES(a0)
	bne	.set
	move.b	#ST_DECAY,V_STATE(a0)
	tst.l	V_SL(a0)
	bne	.set
	move.b	#ST_SUSTAIN,V_STATE(a0)
	bra	.set
.one	subq.w	#1,V_FRAMES(a0)
	beq	.free
.set	move.l	d1,V_ENV(a0)
	lsr.l	#8,d1
	add.w	V_TL(a0),d1
	cmpi.l	#1023,d1
	bhs	.free
	lsr.w	#3,d1
	lea	fm_voltab(pc),a2
	move.b	(a2,d1.w),d1
	ext.w	d1
	move.w	d1,8(a1)
	bra	.next
.pcm	subq.w	#1,V_FRAMES(a0)
	beq	.free
	move.w	V_TL(a0),8(a1)
	bra	.next
.free	; done: the voice is free (its sample may still loop, silently)
	clr.w	8(a1)
	clr.b	V_STATE(a0)
	moveq	#0,d1
	move.b	V_OWNER(a0),d1
	move.b	#-1,V_OWNER(a0)
	cmpi.b	#PCM_OWNER,d1
	bhs	.next
	lea	(snd_chvoice).l,a2
	moveq	#3,d2
	sub.w	d6,d2
	cmp.b	(a2,d1.w),d2
	bne	.next
	move.b	#-1,(a2,d1.w)
.next	lea	V_SIZE(a0),a0
	lea	$10(a1),a1
	dbf	d6,.v
	rts

;	Paula volume for an attenuation of 8n units (n * 0.75 dB)
fm_voltab
	dc.b	64,61,58,56,53,51,48,46,44,42,40,38,36,35,33,32
	dc.b	30,29,27,26,25,24,23,22,21,20,19,18,17,16,15,15
	dc.b	14,13,13,12,11,11,10,10,9,9,8,8,7,7,7,6
	dc.b	6,6,5,5,5,5,4,4,4,4,3,3,3,3,3,3
	dc.b	2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1
	dc.b	1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.b	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

	section	sndchip,data_c
fm_silence	dc.w	0,0

	section	chip,bss_c
snd_pcmdata	ds.b	fm_instrument_patches-sfx_shotbh_pcm
		even

	section	bss,bss
snd_voices	ds.b	4*V_SIZE
snd_pcm_len	ds.l	15
snd_pcm_render	ds.l	4
snd_pcm_addr	ds.l	1
snd_age		ds.w	1
snd_chvoice	ds.b	8			;voice of each FM channel, -1 = none
snd_pend_off	ds.b	1
snd_pend_on	ds.b	1
snd_pend_att	ds.b	1
snd_pend_frq	ds.b	1
snd_pcm_start	ds.b	1
		even

	section	game,code
