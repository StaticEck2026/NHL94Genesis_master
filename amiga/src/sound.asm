;	Sound: the game's music and effects on the Amiga's four Paula voices.
;
;	The game's 68000 sound driver (sound94.asm) runs its tracks as it did; what it handed its Z80
;	program it hands this code (patches.py). Its 33 byte command buffer (Z80_command_buffer, in
;	the game's RAM) holds bit masks of the FM channels to key off, key on, give a new
;	attenuation, a new frequency and a new patch, then the attenuation, frequency and patch of
;	each channel (snd_fm_commands). A PCM sound is its start address (snd_pcm_play), its
;	playback rate (snd_pcm_rate, 0 = stop) and its volume (snd_pcm_vol).
;
;	The FM patches are samples made at build time (amiga/tools/fmrender.py: an attack then a
;	loop, at the pitch bands the patch is used at). A key on takes a voice (a free one, else
;	the quietest released one, else the oldest) and plays the patch's sample at the note's
;	pitch; the rest of the patch's envelope (decay, release at key off) is a volume envelope
;	stepped each game frame. The PCM sounds are samples made at build time too (pcmrender.py:
;	signed, at the game's rates; one played faster than Paula can is resampled and played at a
;	longer period). All audio is 8 bit; the FM samples are rendered at 20000 Hz.
;
;	There are 9 voices: Paula's first 3, and 6 the CPU mixes into a ring Paula's fourth plays
;	(snd_mix), each with registers in memory as Paula's (so the voice code is the same for both:
;	snd_vregs). That is a voice for every sound the Genesis plays at once: a note on each FM
;	channel (a key on takes the voice of the channel's note before, still in its release, as
;	there), the PCM sound and the crowd noise (two: snd_crowd); none takes another's. A new sound takes Paula's
;	own voices first, so the CPU mixes only what more than 3 sounds at once need.
;
;	The crowd noise was the Genesis' PSG's: its noise channel, white noise clocked by its third
;	tone channel, at a volume the game moves toward its crowd level (updatesound). Here it is a
;	loop of that noise (snd_noise_init) on voices of its own (snd_crowd).
;
;	The Amiga's audio low-pass filter (the "LED" filter, about 3.3 kHz) is on while the game
;	runs, as the Genesis model 1's output filter softens its sound; F7 switches it.
;
;	snd_fm_commands and snd_pcm_play take the driver's commands; snd_frame, from the game frame
;	interrupt (50 or 60 Hz, hal_hz), does the work on Paula. The envelope speeds are made for 60 Hz and scaled to the frame rate, so the
;	sounds keep their length at 50 Hz (the YM2612's envelopes do not depend on it).
;
;	The picture of a game frame is on the screen some frames after the game made it (drawn,
;	then queued behind the frames before it). So that a shot is heard when it is seen, each
;	game frame's commands (with the buffer's bytes they use) go into a delay line and are
;	carried out snd_delay game frames later: the renderer keeps that near the picture's mean
;	delay (rd_showdue).

AUD0LC		equ	$0A0			;voice n at + n * $10: LC, LEN, PER, VOL
PCMHZ		equ	30594			;the Z80 PCM loop: 117 T states at 3.58 MHz
PAULACLK	equ	3546895

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
CROWD_L		equ	8			;(the crowd noise's voices: its left one,
CROWD_R		equ	9			;its right one)
ST_NOISE	equ	6			;the crowd noise is playing (its loop, for ever)
NOISELEN	equ	16384			;the crowd noise loop's bytes: a byte a shift of the PSG's
						;noise register, 3.5 seconds
NOISEPER	equ	761			;its period: the PSG's third tone channel at 24, which clocks
						;the noise, 3579545 / 32 / 24 = 4661 Hz

NVOICES		equ	9			;voices: Paula's first 3, and 6 mixed into its fourth
						;(snd_mix)
NHW		equ	3			;(Paula's own)
;	A mixed voice: its registers, as a Paula voice's (snd_vregs points at them, so the voice
;	code is the same), then its sound as it plays
SV_LC		equ	0			;.l
SV_LEN		equ	4			;.w (words)
SV_PER		equ	6			;.w
SV_VOL		equ	8			;.w
SV_ON		equ	10			;.b playing
SV_PTR		equ	12			;.l the block playing,
SV_END		equ	16			;.l its bytes,
SV_POS		equ	20			;.l the byte playing,
SV_FRAC		equ	24			;.w its fraction
SV_SIZE		equ	32
MXRING		equ	4096			;the mix's ring in chip RAM (bytes, a sample each)
MXLEAD		equ	832			;samples mixed ahead of where Paula plays it: a frame
						;(572 at 50 Hz) and some for a late one, so a note
						;mixed starts some 10 ms after one on Paula's own
MXMAX		equ	1664			;samples mixed at most at a time

SDMAX		equ	8			;the delay line: game frames (a power of 2)
SDREC		equ	40			;bytes a frame: the pending commands, the PCM volume and
						;rate, the crowd noise's attenuation, the PCM address, the
						;command buffer's channel bytes
;	the command buffer: each channel's attenuation, frequency, patch
SCATT		equ	per_channel_attenuation_table-Z80_command_buffer
SCFRQ		equ	per_channel_frequency_table-Z80_command_buffer
SCPAT		equ	per_channel_patch_table-Z80_command_buffer
SCMDSIZE	equ	33

	include	"fm_patches.i"		;the FM patch samples and tables (fmrender.py)
	include	"pcm.i"			;the PCM samples and their table (pcmrender.py)

	section	game,code

;	Start: voices free, Paula quiet.
snd_init
	movem.l	d0-d2/a0-a2,-(sp)
	bsr	snd_mix_tables
	bsr	snd_noise_init
	st	(snd_psg_att).l			;(the crowd noise off)
	st	(snd_psg_attd).l
	bsr	snd_vtab
	lea	(snd_voices).l,a0
	moveq	#NVOICES-1,d0
.v	move.b	#-1,V_OWNER(a0)
	clr.b	V_STATE(a0)
	lea	V_SIZE(a0),a0
	dbf	d0,.v
	lea	(snd_chvoice).l,a0
	moveq	#7,d0
.c	move.b	#-1,(a0)+
	dbf	d0,.c
	clr.l	(snd_pend_off).l		;(and snd_pcm_start)
	sf	(snd_pcm_start).l
	clr.l	(snd_dlyw).l			;(and snd_dlyr)
	move.w	#3,(snd_delay).l
	move.w	#3<<8,(snd_latf).l
	move.w	#$000F,(CUSTOM+DMACON).l
	lea	(CUSTOM+AUD0LC).l,a0
	moveq	#3,d0
.q	clr.w	8(a0)
	lea	$10(a0),a0
	dbf	d0,.q
	bsr	snd_mix_start
	; the low-pass filter on (CIA-A port A bit 1 low); the OS's setting kept for the exit
	move.b	(CIAA_PRA).l,d0
	andi.b	#2,d0
	move.b	d0,(snd_ledsave).l
	bclr	#1,(CIAA_PRA).l
	movem.l	(sp)+,d0-d2/a0-a2
	rts

;	F7: the low-pass filter on / off.
snd_filter_toggle
	bchg	#1,(CIAA_PRA).l
	rts

;	Back to the OS: the voices silent (the OS's DMA settings come back after: if they have the
;	audio on, Paula would go on playing the last samples, a loop of the crowd noise or of the
;	mix's ring), the filter as it was.
snd_exit
	move.l	a0,-(sp)
	lea	(CUSTOM+AUD0LC).l,a0
	clr.w	8(a0)
	clr.w	8+$10(a0)
	clr.w	8+$20(a0)
	clr.w	8+$30(a0)
	movea.l	(sp)+,a0
	bclr	#1,(CIAA_PRA).l
	tst.b	(snd_ledsave).l
	beq.s	.x
	bset	#1,(CIAA_PRA).l
.x	rts

;	The driver's command buffer is ready (UploadCommandBufferToZ80): note what it asks for
;	(snd_frame does it); key off cancels a key on not yet done. Keeps all.
snd_fm_commands
	move	sr,-(sp)
	ori	#$0700,sr
	movem.l	d0-d1/a0,-(sp)
	lea	(Z80_command_buffer).l,a0
	move.b	(a0),d0				;key off
	move.b	d0,d1
	not.b	d1
	and.b	d1,(snd_pend_on).l
	or.b	d0,(snd_pend_off).l
	move.b	1(a0),d0
	or.b	d0,(snd_pend_on).l
	move.b	2(a0),d0
	or.b	d0,(snd_pend_att).l
	move.b	3(a0),d0
	or.b	d0,(snd_pend_frq).l
	movem.l	(sp)+,d0-d1/a0
	move	(sp)+,sr
	rts

;	The driver starts the PCM sound at d0 (its pcm_sample_table address). Keeps all.
snd_pcm_play
	move.l	d0,(snd_pcm_addr).l
	st	(snd_pcm_start).l
	rts

;	Each game frame: carry out the driver's commands of snd_delay frames ago on Paula (more
;	than one frame's when the delay has just got shorter, none when longer) and step the
;	envelopes.
snd_frame
	movem.l	d0-d7/a0-a6,-(sp)
	bsr	snd_dly_push
	bsr.s	snd_play_do
	movem.l	(sp)+,d0-d7/a0-a6
	rts
;	A vertical blank whose game tick was run early (hal_tick_early, which put its commands into
;	the delay line): the Paula side alone, as each vertical blank. The commands the driver has
;	given since that tick (snd_pend_*, snd_pcm_start: where the delay line's come out too) wait
;	for the next one.
snd_play
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	(snd_pend_off).l,-(sp)
	move.b	(snd_pcm_start).l,-(sp)
	clr.l	(snd_pend_off).l
	sf	(snd_pcm_start).l
	bsr.s	snd_play_do
	move.b	(sp)+,(snd_pcm_start).l
	move.l	(sp)+,(snd_pend_off).l
	movem.l	(sp)+,d0-d7/a0-a6
	rts
snd_play_do
	lea	(snd_cmdd).l,a5			;(the command buffer as it was then)
	lea	(CUSTOM).l,a6
	moveq	#0,d7				;voices to start
.rec	bsr	snd_dly_pop
	beq	.due
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
	move.b	SCATT(a5,d1.w),d2		;attenuation (TL, 0.75 dB)
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
	; PCM, the crowd noise
	bsr	snd_pcm
	bsr	snd_crowd
	bra	.rec
.due	; start the new sounds: their DMA off, then the sample, then on again (a mixed voice
	; takes it as Paula's do, snd_soft_start)
	tst.w	d7
	beq	.nost
	move.w	d7,d0
	and.w	(snd_hwmask).l,d0
	move.w	d0,DMACON(a6)
	bsr	snd_dmawait
	lea	(snd_voices).l,a0
	lea	(snd_vregs).l,a3
	moveq	#0,d1
.st	movea.l	(a3)+,a1
	btst	d1,d7
	beq	.nst
	move.l	V_RENDER(a0),a2
	move.l	(a2),(a1)			;sample
	move.w	4(a2),4(a1)			;length (words)
	clr.w	8(a1)
.nst	lea	V_SIZE(a0),a0
	addq.w	#1,d1
	cmp.w	(snd_nvoice).l,d1
	bne	.st
	move.w	d7,d0
	and.w	(snd_hwmask).l,d0
	ori.w	#$8000,d0
	move.w	d0,DMACON(a6)
	bsr	snd_soft_start
	bsr	snd_dmawait			;the voices have taken the start: now the repeat
	lea	(snd_voices).l,a0
	lea	(snd_vregs).l,a3
	moveq	#0,d1
.rp	movea.l	(a3)+,a1
	btst	d1,d7
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
	addq.w	#1,d1
	cmp.w	(snd_nvoice).l,d1
	bne	.rp
.nost	bsr	snd_envelopes
	bra	snd_mix

;	(snd_play_do) The mixed voices among d7's take their sample as Paula's voices do when their
;	DMA is switched on: the block their LC and LEN name, from its start. Keeps all.
snd_soft_start
	movem.l	d0-d1/a1,-(sp)
	move.w	(snd_nhw).l,d1
.v	cmp.w	(snd_nvoice).l,d1
	bhs.s	.x
	btst	d1,d7
	beq.s	.n
	lea	(snd_soft).l,a1
	move.w	d1,d0
	mulu.w	#SV_SIZE,d0
	adda.l	d0,a1
	move.l	SV_LC(a1),SV_PTR(a1)
	moveq	#0,d0
	move.w	SV_LEN(a1),d0
	add.l	d0,d0
	move.l	d0,SV_END(a1)
	clr.l	SV_POS(a1)
	clr.w	SV_FRAC(a1)
	st	SV_ON(a1)
.n	addq.w	#1,d1
	bra.s	.v
.x	movem.l	(sp)+,d0-d1/a1
	rts

;	This game frame's commands (snd_fm_commands, snd_pcm_play) and the bytes they use into the
;	delay line.
snd_dly_push
	move.w	(snd_dlyw).l,d0
	andi.w	#SDMAX-1,d0
	mulu.w	#SDREC,d0
	lea	(snd_dly).l,a0
	adda.w	d0,a0
	move.l	(snd_pend_off).l,(a0)+		;off, on, attenuation, frequency
	move.b	(snd_pcm_start).l,(a0)+
	clr.l	(snd_pend_off).l
	sf	(snd_pcm_start).l
	move.b	(snd_pcm_vol).l,(a0)+
	move.b	(snd_pcm_rate).l,(a0)+
	move.b	(snd_psg_att).l,(a0)+
	move.l	(snd_pcm_addr).l,(a0)+
	lea	(Z80_command_buffer+SCATT).l,a1
	moveq	#SCMDSIZE-SCATT-1,d0		;attenuations, frequencies, patches
.c	move.b	(a1)+,(a0)+
	dbf	d0,.c
	addq.w	#1,(snd_dlyw).l
	rts

;	The next game frame's commands of the delay line, if due: into the pending bytes and
;	snd_cmdd. Z set if none. Uses d0, a0, a1.
snd_dly_pop
	move.w	(snd_dlyw).l,d0
	sub.w	(snd_dlyr).l,d0
	cmp.w	(snd_delay).l,d0
	bls	.none
	move.w	(snd_dlyr).l,d0
	addq.w	#1,(snd_dlyr).l
	andi.w	#SDMAX-1,d0
	mulu.w	#SDREC,d0
	lea	(snd_dly).l,a0
	adda.w	d0,a0
	move.l	(a0)+,(snd_pend_off).l
	move.b	(a0)+,(snd_pcm_start).l
	move.b	(a0)+,(snd_pcm_vold).l
	move.b	(a0)+,(snd_pcm_rated).l
	move.b	(a0)+,(snd_psg_attd).l
	move.l	(a0)+,(snd_pcm_addrd).l
	lea	(snd_cmdd+SCATT).l,a1
	moveq	#SCMDSIZE-SCATT-1,d0
.c	move.b	(a0)+,(a1)+
	dbf	d0,.c
	moveq	#1,d0				;(Z clear)
	rts
.none	moveq	#0,d0
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
	lea	(snd_vregs).l,a1
	movea.l	(a1,d2.w*4),a1
	lsl.w	#5,d2				;(V_SIZE)
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
	move.w	SCFRQ(a5,d1.w*2),d0		;block << 11 | fnum
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
	movem.l	d4-d5,-(sp)
	moveq	#0,d5
	move.w	(hal_hz).l,d5
	move.l	#PAULACLK,d4
	divu.l	d5,d4				;Paula clocks a frame
	andi.l	#$FFFF,d3
	mulu.l	d3,d2
	divu.l	d4,d2
	addq.w	#1,d2
	move.w	d2,V_FRAMES(a0)
	movem.l	(sp)+,d4-d5
	rts

;	d2 = the envelope step d2 (attenuation units a 60 Hz frame) for a frame at hal_hz.
snd_rate
	cmpi.w	#60,(hal_hz).l
	beq.s	.x
	mulu.w	#6,d2
	divu.l	#5,d2				;(50 Hz)
.x	rts

;	Key on FM channel d1 (patch, frequency and attenuation from the command buffer). d7 |= its voice.
snd_keyon
	movem.l	d0-d1,-(sp)
	bsr	snd_chan_voice
	bpl	.have				;still on (no key off): play again on the same voice
	lea	(snd_voices).l,a0		;its note before still in its release ends, as on the
	moveq	#0,d2				;Genesis, where a key on ends what is left of the
.tl	cmp.b	V_OWNER(a0),d1			;channel's note before: its voice silent and free
	bne.s	.tn
	tst.b	V_STATE(a0)
	bne.s	.tail
.tn	lea	V_SIZE(a0),a0
	addq.w	#1,d2
	cmpi.w	#NVOICES,d2
	blo.s	.tl
	bra.s	.new
.tail	move.w	d2,d0
	bsr	snd_voice_a0
	clr.b	V_STATE(a0)
	move.b	#-1,V_OWNER(a0)
	clr.w	8(a1)
	bclr	d0,d7				;(if started this frame)
	cmpi.w	#NHW,d0
	blo.s	.new
	sf	SV_ON(a1)
.new	moveq	#0,d2				;a voice, as for any sound (not PCM): Paula's own first
	bsr	snd_alloc
	lea	(snd_chvoice).l,a1
	move.b	d2,(a1,d1.w)
	bsr	snd_voice_a0
.have
	IFD	STATS
	addq.l	#1,(snd_stats).l		;(statistics: key ons)
	ENDC
	move.b	d1,V_OWNER(a0)
	sf	V_REL(a0)
	clr.l	V_ENV(a0)
	addq.w	#1,(snd_age).l
	move.w	(snd_age).l,V_AGE(a0)
	moveq	#0,d2
	move.b	SCATT(a5,d1.w),d2
	lsl.w	#3,d2
	move.w	d2,V_TL(a0)
	; the patch's render for the note's band
	moveq	#31,d0
	and.b	SCPAT(a5,d1.w),d0		;patch
	mulu.w	#FM_PATCH_SIZE,d0
	lea	fm_patch_table,a2
	adda.w	d0,a2
	move.l	a2,V_PATCH(a0)
	move.w	SCFRQ(a5,d1.w*2),d0
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
;	a free one (Paula's first), else the quietest released one, else the oldest FM one. d2 =
;	voice number. The FM channel that had it loses it.
snd_alloc
	movem.l	d0-d1/d3-d6/a0,-(sp)
	move.w	(snd_nvoice).l,d6
	lea	(snd_voices).l,a0
	moveq	#0,d0				;voice
	tst.b	d2
	beq	.fr
.pv	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	beq	.got
	lea	V_SIZE(a0),a0
	addq.w	#1,d0
	cmp.w	d6,d0
	blo	.pv
	lea	(snd_voices).l,a0
	moveq	#0,d0
.fr	tst.b	V_STATE(a0)
	beq	.got
	lea	V_SIZE(a0),a0
	addq.w	#1,d0
	cmp.w	d6,d0
	blo	.fr
	; quietest released
	lea	(snd_voices).l,a0
	moveq	#-1,d4				;best
	moveq	#-1,d5				;its envelope
	moveq	#0,d0
.rl	tst.b	V_REL(a0)
	beq	.nrl
	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	bhs	.nrl
	move.l	V_ENV(a0),d1
	cmp.l	d5,d1
	ble	.nrl
	move.l	d1,d5
	move.w	d0,d4
.nrl	lea	V_SIZE(a0),a0
	addq.w	#1,d0
	cmp.w	d6,d0
	blo	.rl
	tst.w	d4
	bpl	.idx
	; oldest FM voice
	lea	(snd_voices).l,a0
	move.w	(snd_age).l,d3
	moveq	#0,d5				;greatest age
	moveq	#0,d0
.ol	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	bhs	.nol				;(the PCM's, the crowd's)
	move.w	d3,d1
	sub.w	V_AGE(a0),d1
	cmp.w	d5,d1
	blo	.nol
	move.w	d1,d5
	move.w	d0,d4
.nol	lea	V_SIZE(a0),a0
	addq.w	#1,d0
	cmp.w	d6,d0
	blo	.ol
	tst.w	d4
	bpl	.idx
	moveq	#0,d4				;(cannot be: only one PCM voice)
.idx	move.w	d4,d2
	bra	.take
.got	move.w	d0,d2
.take
	IFD	STATS
	lea	(snd_voices).l,a0		;(statistics: a sounding FM voice taken, held)
	move.w	d2,d0
	lsl.w	#5,d0
	adda.w	d0,a0
	tst.b	V_STATE(a0)
	beq.s	.sn
	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	bhs.s	.sn
	addq.l	#1,(snd_stats+4).l
	tst.b	V_REL(a0)
	bne.s	.sn
	addq.l	#1,(snd_stats+8).l
.sn
	ENDC
	; the channel playing on it loses it
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
.x	movem.l	(sp)+,d0-d1/d3-d6/a0
	rts

;	The PCM channel: start a sound, or follow its rate (0 = stop) and volume.
snd_pcm
	moveq	#0,d1
	move.b	(snd_pcm_rated).l,d1		;rate
	tst.b	(snd_pcm_start).l
	beq	.run
	sf	(snd_pcm_start).l
	tst.w	d1
	beq	.x
	; which sound: its pcm_sample_table entry
	move.l	(snd_pcm_addrd).l,d0
	lea	pcm_sample_table,a0
	moveq	#0,d2
.find	cmp.l	(a0,d2.w*8),d0
	beq	.found
	addq.w	#1,d2
	cmpi.w	#15,d2
	bne	.find
	bra	.x
.found	lea	(snd_pcm_tab).l,a3		;its sample (pcmrender.py)
	lsl.w	#3,d2
	adda.w	d2,a3
	tst.l	(a3)
	beq	.x
	moveq	#0,d3
	move.w	4(a3),d3			;words
	beq	.x
	move.w	6(a3),(snd_pcm_k).l
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
	move.l	(a3),(a2)
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
	moveq	#0,d0
.pv	cmpi.b	#PCM_OWNER,V_OWNER(a0)
	beq	.on
	lea	V_SIZE(a0),a0
	addq.w	#1,d0
	cmp.w	(snd_nvoice).l,d0
	blo	.pv
	bra	.x
.on	lea	(snd_vregs).l,a1
	movea.l	(a1,d0.w*4),a1
	tst.w	d1
	bne	.rate
	clr.b	V_STATE(a0)			;stopped
	move.b	#-1,V_OWNER(a0)
	clr.w	8(a1)
	cmp.w	(snd_nhw).l,d0
	blo	.x
	sf	SV_ON(a1)			;(a mixed voice: not mixed now)
	bra	.x
.rate	bsr	snd_pcm_period
	move.w	d2,6(a1)
.vol	moveq	#0,d1				;volume: 8 / (8 + $1F - v) of full, v = 3-$1F
	move.b	(snd_pcm_vold).l,d1
	cmpi.w	#$1F,d1
	bls	.v1
	moveq	#$1F,d1
.v1	moveq	#39,d2
	sub.w	d1,d2
	move.l	#512,d1
	divu.w	d2,d1
	move.w	d1,V_TL(a0)			;the PCM voice keeps its Paula volume here
.x	rts

;	d1 = PCM rate (snd_pcm_rate, steps of 1/256 sample at PCMHZ): d2 = period (times the sound's
;	factor, for a sample made at a lower rate).
snd_pcm_period
	move.l	#(PAULACLK*16/PCMHZ)*16,d2
	divu.w	d1,d2				;(rate >= 1: at most 29664)
	mulu.w	(snd_pcm_k).l,d2
	lsr.l	#8,d2
	cmpi.l	#$FFFF,d2
	bls	.k
	move.l	#$FFFF,d2
.k	cmpi.w	#124,d2
	bhs	.x
	moveq	#124,d2
.x	rts

;	Step the voices' envelopes and set their volumes.
snd_envelopes
	lea	(snd_voices).l,a0
	lea	(snd_vregs).l,a3
	moveq	#0,d6				;voice
.v	movea.l	(a3)+,a1
	moveq	#0,d0
	move.b	V_STATE(a0),d0
	beq	.next
	cmpi.b	#ST_PCM,d0
	beq	.pcm
	cmpi.b	#ST_NOISE,d0
	beq	.noise
	movea.l	V_PATCH(a0),a2
	move.l	V_ENV(a0),d1
	tst.b	V_REL(a0)
	beq	.nrel
	moveq	#0,d2
	move.w	2*FM_BANDS+6(a2),d2		;release
	bsr	snd_rate
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
	bsr	snd_rate
	add.l	d2,d1
	sub.l	d2,V_SL(a0)
	bhi	.set
	move.b	#ST_SUSTAIN,V_STATE(a0)
	bra	.set
.sus	moveq	#0,d2
	move.w	2*FM_BANDS+4(a2),d2		;sustain decay
	bsr	snd_rate
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
	bne.s	.vs
	tst.b	V_REL(a0)			;released and down to silence: done (a mixed voice
	bne.s	.free				;costs the CPU until it is)
.vs	move.w	d1,8(a1)
	bra	.next
.pcm	subq.w	#1,V_FRAMES(a0)
	beq	.free
.noise	move.w	V_TL(a0),8(a1)			;(the PCM's, the crowd's: its Paula volume)
	bra	.next
.free	; done: the voice is free (its sample may still loop, silently; a mixed one is not
	; mixed now)
	clr.w	8(a1)
	cmp.w	(snd_nhw).l,d6
	blo.s	.fh
	sf	SV_ON(a1)
.fh	clr.b	V_STATE(a0)
	moveq	#0,d1
	move.b	V_OWNER(a0),d1
	move.b	#-1,V_OWNER(a0)
	cmpi.b	#PCM_OWNER,d1
	bhs	.next
	lea	(snd_chvoice).l,a2
	cmp.b	(a2,d1.w),d6
	bne	.next
	move.b	#-1,(a2,d1.w)
.next	lea	V_SIZE(a0),a0
	addq.w	#1,d6
	cmp.w	(snd_nvoice).l,d6
	blo	.v
	IFD	STATS
	lea	(snd_voices).l,a0		;(statistics: most voices sounding)
	moveq	#0,d0
	moveq	#NVOICES-1,d1
.cn	tst.b	V_STATE(a0)
	beq.s	.cz
	addq.l	#1,d0
.cz	lea	V_SIZE(a0),a0
	dbf	d1,.cn
	cmp.l	(snd_stats+20).l,d0
	bls.s	.cx
	move.l	d0,(snd_stats+20).l
.cx
	ENDC
	rts

;	Each voice's registers (snd_vregs): Paula's first 3 voices', then the mixed voices' own.
snd_vtab
	movem.l	d0/a0-a1,-(sp)
	lea	(snd_vregs).l,a0
	lea	(CUSTOM+AUD0LC).l,a1
	moveq	#0,d0
.p	move.l	a1,(a0)+
	lea	$10(a1),a1
	addq.w	#1,d0
	cmpi.w	#NHW,d0
	blo.s	.p
	lea	(snd_soft+NHW*SV_SIZE).l,a1
.s	move.l	a1,(a0)+
	lea	SV_SIZE(a1),a1
	addq.w	#1,d0
	cmpi.w	#NVOICES,d0
	blo.s	.s
	move.w	#NHW,(snd_nhw).l
	move.w	#NVOICES,(snd_nvoice).l
	move.w	#(1<<NHW)-1,(snd_hwmask).l
	movem.l	(sp)+,d0/a0-a1
	rts

;	Paula's fourth voice plays the mix's ring (silent at first, snd_mix) from now on. Keeps all.
snd_mix_start
	movem.l	d0-d1/a0,-(sp)
	lea	(snd_soft).l,a0
	moveq	#NVOICES-1,d1
.s	sf	SV_ON(a0)
	lea	SV_SIZE(a0),a0
	dbf	d1,.s
	lea	(mx_ring).l,a0
	move.w	#MXRING/4-1,d1
.z	clr.l	(a0)+
	dbf	d1,.z
	lea	(CUSTOM+AUD0LC+3*$10).l,a0
	move.l	#mx_ring,(a0)
	move.w	#MXRING/2,4(a0)
	move.w	#124,6(a0)
	move.w	#64,8(a0)
	bsr	snd_dmawait			;(Paula has seen its DMA off)
	move.w	#$8008,(CUSTOM+DMACON).l
	bsr	mx_tod24
	move.l	d0,(mx_tod).l
	clr.l	(mx_ccr).l
	clr.l	(mx_play).l
	clr.l	(mx_wr).l
	clr.l	(mx_quiet).l
	movem.l	(sp)+,d0-d1/a0
	rts

;	The crowd noise (snd_psg_attd: the attenuation the game gave the PSG's noise channel, in
;	2 dB steps, 15 = off; snd_crowd_vol the Paula volume for it): the noise loop on two voices,
;	a left and a right one (Paula's 0 and 3 are on the left, 1 and 2 on the right), as the
;	Genesis' PSG is heard in the middle. Paula's own voices when they are free (it plays all
;	through a game: mixed only while it must be): the left one Paula's 0, else a mixed one (the
;	mix is on the left) until 0 is free; the right one Paula's 1 or 2, else none until one of
;	them is free. A note is never cut for it. d7 |= the voices started. Uses d0-d3, a0-a3.
snd_crowd
	moveq	#15,d1
	and.b	(snd_psg_attd).l,d1		;attenuation
	moveq	#CROWD_L,d3
	lea	(.left,pc),a3
	bsr.s	.part
	moveq	#CROWD_R,d3
	lea	(.right,pc),a3
.part	; the part owned by d3, its voices a3 (in order; -2: any mixed one; -1: the end)
	lea	(snd_voices).l,a0
	moveq	#0,d0
.f	cmp.b	V_OWNER(a0),d3
	beq.s	.has
	lea	V_SIZE(a0),a0
	addq.w	#1,d0
	cmpi.w	#NVOICES,d0
	blo.s	.f
	cmpi.w	#15,d1
	beq	.x				;(none, and none wanted)
	bsr	.free
	bmi	.x
	bra.s	.start
.has	cmpi.w	#15,d1
	beq.s	.off
	cmpi.w	#NHW,d0
	blo.s	.vol				;on Paula's
	bsr	.free				;mixed: to Paula's if one of its own is free now
	bmi.s	.vol
	cmpi.w	#NHW,d2
	bhs.s	.vol
	move.w	d2,-(sp)
	bsr.s	.off
	move.w	(sp)+,d2
.start	move.w	d2,d0				;d2: the voice
	lsl.w	#5,d0
	lea	(snd_voices).l,a0
	adda.w	d0,a0
	lea	(snd_vregs).l,a1
	movea.l	(a1,d2.w*4),a1
	move.b	d3,V_OWNER(a0)
	move.b	#ST_NOISE,V_STATE(a0)
	sf	V_REL(a0)
	clr.l	V_ENV(a0)
	move.l	#snd_noise_render,V_RENDER(a0)
	move.w	#NOISEPER,6(a1)
	bset	d2,d7
.vol	lea	(snd_crowd_vol,pc),a2
	moveq	#0,d2
	move.b	(a2,d1.w),d2
	move.w	d2,V_TL(a0)			;(its Paula volume: snd_envelopes)
.x	rts
.off	; voice d0 (a0) free: silent, not mixed
	clr.b	V_STATE(a0)
	move.b	#-1,V_OWNER(a0)
	lea	(snd_vregs).l,a1
	movea.l	(a1,d0.w*4),a1
	clr.w	8(a1)
	cmpi.w	#NHW,d0
	blo.s	.o
	sf	SV_ON(a1)
.o	bclr	d0,d7				;(if started this frame)
	rts
.free	; d2 = the first of a3's voices that is free, N set if none. Uses a1, a2.
	move.w	d0,-(sp)
	movea.l	a3,a2
.fn	move.b	(a2)+,d2
	ext.w	d2
	bmi.s	.fm
	move.w	d2,d0
	lsl.w	#5,d0
	lea	(snd_voices).l,a1
	tst.b	V_STATE(a1,d0.w)
	bne.s	.fn
	bra.s	.fy
.fm	cmpi.w	#-2,d2				;-2: a free mixed voice
	bne.s	.fz				;(-1: the end: none)
	moveq	#NHW,d2
	lea	(snd_voices+NHW*V_SIZE).l,a1
.fq	tst.b	V_STATE(a1)
	beq.s	.fy
	lea	V_SIZE(a1),a1
	addq.w	#1,d2
	cmpi.w	#NVOICES,d2
	blo.s	.fq
.fz	move.w	(sp)+,d0
	moveq	#-1,d2				;(N set)
	rts
.fy	move.w	(sp)+,d0
	tst.w	d2				;(N clear)
	rts
.left	dc.b	0,-2,-1
.right	dc.b	1,2,-1
	even

;	Paula volume for the crowd noise's attenuation (2 dB steps): 40 at none.
snd_crowd_vol
	dc.b	40,32,25,20,16,13,10,8,6,5,4,3,3,2,2,0

;	The crowd noise loop (snd_noise): the PSG's noise register, 16 bits, white noise (its new
;	top bit bits 0 and 3 of it, xored), from $8000, a byte a shift: high when its bit 0 is
;	(+-100: a little under full scale, as noise is louder than a tone of the same peak).
snd_noise_init
	movem.l	d0-d2/a0,-(sp)
	lea	(snd_noise).l,a0
	move.w	#$8000,d0
	move.w	#NOISELEN-1,d1
.n	moveq	#100,d2
	btst	#0,d0
	bne.s	.h
	moveq	#-100,d2
.h	move.b	d2,(a0)+
	move.w	d0,d2
	lsr.w	#3,d2
	eor.w	d0,d2
	lsr.w	#1,d0
	lsl.w	#8,d2
	lsl.w	#7,d2				;(bit 0 to 15)
	or.w	d2,d0
	dbf	d1,.n
	lea	(snd_noise_render).l,a0		;a render as fmrender.py's: the sample, its words, the
	move.l	#snd_noise,(a0)+		;loop's start (bytes) and words: all of it, for ever
	move.w	#NOISELEN/2,(a0)+
	clr.w	(a0)+
	move.w	#NOISELEN/2,(a0)+
	movem.l	(sp)+,d0-d2/a0
	rts

;	The mix (from each vertical blank's sound work): the mixed voices' samples, at the
;	rate Paula's voice 3 plays its ring (a period of 124), written up to MXLEAD samples ahead of
;	where it plays. That is counted from the CIA-B TOD (horizontal syncs: 227 colour clocks on
;	a PAL display, 227.5 on NTSC), so the ring keeps in step with Paula however the calls come.
;	Uses d0-d7, a0-a6.
snd_mix
	bsr	mx_tod24
	move.l	d0,d1
	sub.l	(mx_tod).l,d1
	andi.l	#$FFFFFF,d1			;lines since the last time
	move.l	d0,(mx_tod).l
	cmpi.l	#4096,d1
	bls.s	.l
	move.l	#4096,d1			;(a stall)
.l	move.l	#455,d0				;half colour clocks a line
	tst.b	(hal_pal).l
	beq.s	.p
	move.l	#454,d0
.p	mulu.l	d0,d1
	add.l	(mx_ccr).l,d1
	divul.l	#2*124,d0:d1			;samples played, the rest kept
	move.l	d0,(mx_ccr).l
	add.l	d1,(mx_play).l
	move.l	(mx_play).l,d7			;samples to mix: to MXLEAD past it (4 at a time:
	addi.l	#MXLEAD,d7			;the ring is written in longs)
	sub.l	(mx_wr).l,d7
	andi.l	#-4,d7
	ble	.x
	cmpi.l	#MXMAX,d7
	bls.s	.n
	move.l	(mx_play).l,d0			;(fallen behind it: from MXMAX before the end)
	addi.l	#MXLEAD-MXMAX,d0
	andi.l	#-4,d0
	move.l	d0,(mx_wr).l
	move.l	#MXMAX,d7
.n	moveq	#0,d6				;voices mixed (the first is stored, the others added)
	lea	(snd_soft).l,a2
	move.w	(snd_nhw).l,d0
	mulu.w	#SV_SIZE,d0
	adda.l	d0,a2
	moveq	#NVOICES-1,d5
	sub.w	(snd_nhw).l,d5
.vo	tst.b	SV_ON(a2)
	beq.s	.vn
	bsr	mx_voice
	addq.w	#1,d6
.vn	lea	SV_SIZE(a2),a2
	dbf	d5,.vo
	tst.w	d6
	beq.s	.q
	IFD	STATS
	addq.l	#1,(snd_stats+12).l		;(statistics: mixing, voices mixed)
	ext.l	d6
	add.l	d6,(snd_stats+16).l
	ENDC
	clr.l	(mx_quiet).l
	bra.s	.o0
.q	move.l	(mx_quiet).l,d0			;silence: written until the ring is all silent
	cmpi.l	#MXRING,d0
	bhs.s	.adv
	add.l	d7,(mx_quiet).l
.o0	; the sums into the ring, clipped: to its end, then from its start
	move.l	(mx_wr).l,d0
	andi.l	#MXRING-1,d0
	lea	(mx_ring).l,a1
	adda.l	d0,a1
	move.l	#MXRING,d1
	sub.l	d0,d1				;bytes to the ring's end
	move.l	d7,d2
	cmp.l	d1,d2
	bls.s	.o1
	move.l	d1,d2
.o1	lea	(mx_acc).l,a6
	lea	(mx_clip+4096).l,a4
	move.l	d7,d5
	sub.l	d2,d5				;(the rest, from the start)
	bsr.s	.cv
	move.l	d5,d2
	beq.s	.adv
	lea	(mx_ring).l,a1
	bsr.s	.cv
.adv	add.l	d7,(mx_wr).l
.x	rts
.cv	; d2 samples (4 at a time) to a1: the sums at a6, or silence if no voice was mixed
	lsr.l	#2,d2
	subq.w	#1,d2
	tst.w	d6
	beq.s	.cz
.cl	move.w	(a6)+,d0
	asr.w	#3,d0
	move.b	(a4,d0.w),d3
	lsl.w	#8,d3
	move.w	(a6)+,d0
	asr.w	#3,d0
	move.b	(a4,d0.w),d3
	swap	d3
	move.w	(a6)+,d0
	asr.w	#3,d0
	move.b	(a4,d0.w),d3
	lsl.w	#8,d3
	move.w	(a6)+,d0
	asr.w	#3,d0
	move.b	(a4,d0.w),d3
	move.l	d3,(a1)+
	dbf	d2,.cl
	rts
.cz	clr.l	(a1)+
	dbf	d2,.cz
	rts

;	(snd_mix) Mixed voice a2's next d7 samples into the sums (mx_acc: stored if d6 is 0, else
;	added) at its period and volume, as Paula plays: its block (SV_PTR, SV_END bytes) to the
;	end, then the block its registers name then (SV_LC, SV_LEN: the loop, or silence), a run
;	of samples to each block's end at a time. Keeps d5-d7, a2.
mx_voice
	movem.l	d5-d7/a2,-(sp)
	moveq	#0,d3
	move.w	SV_PER(a2),d3
	cmpi.w	#124,d3
	bhs.s	.p
	moveq	#124,d3
.p	move.l	#124<<16,d4
	divu.l	d3,d4				;the step a sample (16.16, at most 1)
	move.l	d4,(mx_step).l
	moveq	#0,d2
	swap	d4
	move.w	d4,d2				;(its whole part)
	swap	d4				;(d4.w: its fraction)
	moveq	#0,d0
	move.w	SV_VOL(a2),d0
	cmpi.w	#64,d0
	bls.s	.v
	moveq	#64,d0
.v	lsl.l	#8,d0
	add.l	d0,d0
	lea	(mx_vol).l,a4
	adda.l	d0,a4				;(sample * volume / 2, by the sample's byte)
	movea.l	SV_PTR(a2),a0
	move.l	SV_POS(a2),d0
	move.w	SV_FRAC(a2),d1
	move.l	SV_END(a2),d5
	lea	(mx_acc).l,a6
	move.w	d6,(mx_add).l
	moveq	#0,d3				;(the sample's byte: an index 0-255)
.seg	; samples to the block's end: ((end - pos) << 16 - fraction) / step, rounded up
	move.l	d5,d6
	sub.l	d0,d6
	swap	d6
	clr.w	d6
	sub.l	d1,d6
	add.l	(mx_step).l,d6
	subq.l	#1,d6
	divul.l	(mx_step).l,d6
	cmp.l	d7,d6
	bls.s	.k
	move.l	d7,d6
.k	sub.l	d6,d7				;(left after this run)
	move.l	d7,(mx_left).l
	subq.w	#1,d6
	bmi.s	.e
	tst.w	(mx_add).l
	bne.s	.a
.s	move.b	(a0,d0.l),d3			;the first voice: stored
	move.w	(a4,d3.w*2),(a6)+
	add.w	d4,d1
	addx.l	d2,d0
	dbf	d6,.s
	bra.s	.e
.a	move.b	(a0,d0.l),d3			;the others: added
	move.w	(a4,d3.w*2),d7
	add.w	d7,(a6)+
	add.w	d4,d1
	addx.l	d2,d0
	dbf	d6,.a
.e	move.l	(mx_left).l,d7
	cmp.l	d5,d0
	blo.s	.r
	sub.l	d5,d0				;the block's end: the next, from the registers
	movea.l	SV_LC(a2),a0
	moveq	#0,d5
	move.w	SV_LEN(a2),d5
	add.l	d5,d5
.r	tst.l	d7
	bne.s	.seg
	move.l	a0,SV_PTR(a2)
	move.l	d0,SV_POS(a2)
	move.w	d1,SV_FRAC(a2)
	move.l	d5,SV_END(a2)
	movem.l	(sp)+,d5-d7/a2
	rts

;	d0 = the CIA-B TOD (24 bits). Uses d0.
mx_tod24
	moveq	#0,d0
	move.b	(CIAB_TODHI).l,d0		;(reading it holds the count until TODLO is read)
	lsl.l	#8,d0
	move.b	(CIAB_TODMID).l,d0
	lsl.l	#8,d0
	move.b	(CIAB_TODLO).l,d0
	rts

;	The mix's tables: sample * volume / 2 (volumes 0-64, by the sample's byte 0-255, a signed
;	sample), and a sum / 8 (-4096 to 4095) to a sample, / 4 and clipped.
snd_mix_tables
	movem.l	d0-d3/a0,-(sp)
	lea	(mx_vol).l,a0
	moveq	#0,d1				;volume
.tv	moveq	#0,d2
.ts	move.b	d2,d3
	ext.w	d3
	muls.w	d1,d3
	asr.l	#1,d3
	move.w	d3,(a0)+
	addq.w	#1,d2
	cmpi.w	#256,d2
	blt.s	.ts
	addq.w	#1,d1
	cmpi.w	#64,d1
	bls.s	.tv
	lea	(mx_clip).l,a0
	move.w	#-4096,d2
.tc	move.w	d2,d3
	asr.w	#2,d3
	cmpi.w	#127,d3
	ble.s	.c1
	moveq	#127,d3
.c1	cmpi.w	#-128,d3
	bge.s	.c2
	moveq	#-128,d3
.c2	move.b	d3,(a0)+
	addq.w	#1,d2
	cmpi.w	#4096,d2
	blt.s	.tc
	movem.l	(sp)+,d0-d3/a0
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
mx_ring		ds.b	MXRING			;(snd_mix)

	section	ring,bss_c			;(with the sprite image ring: the largest chip hunk is
snd_noise	ds.b	NOISELEN		;kept small) the crowd noise loop (snd_noise_init)

	section	bss,bss
snd_stats	ds.l	8			;(statistics, STATS builds: key ons, sounding FM voices
						;taken, of them held; frames with voices mixed, mixed
						;voice frames; most voices sounding at once)
snd_voices	ds.b	NVOICES*V_SIZE
snd_soft	ds.b	NVOICES*SV_SIZE		;the mixed voices (by voice number)
snd_vregs	ds.l	NVOICES			;each voice's registers (snd_vtab)
snd_nvoice	ds.w	1
snd_nhw		ds.w	1
snd_hwmask	ds.w	1
mx_tod		ds.l	1			;(snd_mix: the TOD at the last time,
mx_ccr		ds.l	1			;half colour clocks not a sample yet,
mx_play		ds.l	1			;samples Paula has played,
mx_wr		ds.l	1			;written,
mx_quiet	ds.l	1			;silent in a row)
mx_step		ds.l	1			;(mx_voice: the step,
mx_left		ds.l	1			;samples left after the run,
mx_add		ds.w	1			;0: the first voice, stored)
mx_acc		ds.w	MXMAX
mx_vol		ds.w	65*256
mx_clip		ds.b	8192
snd_psg_att	ds.b	1			;the crowd noise's attenuation (the PSG's noise
snd_psg_attd	ds.b	1			;channel, updatesound: 15 off), and delayed
		even
snd_noise_render ds.l	3			;(snd_noise_init)
snd_pcm_render	ds.l	4
snd_pcm_addr	ds.l	1
snd_age		ds.w	1
snd_pcm_k	ds.w	1			;the PCM sound's period factor (8.8)
snd_chvoice	ds.b	8			;voice of each FM channel, -1 = none
		cnop	0,4
snd_pend_off	ds.b	1			;(these 4 in this order, a long)
snd_pend_on	ds.b	1
snd_pend_att	ds.b	1
snd_pend_frq	ds.b	1
snd_pcm_start	ds.b	1
snd_ledsave	ds.b	1
		even
snd_dlyw	ds.w	1			;the delay line: game frames written,
snd_dlyr	ds.w	1			;carried out
snd_delay	ds.w	1			;game frames the commands wait (rd_showdue)
snd_latf	ds.w	1			;the picture's mean delay (8.8, rd_showdue)
snd_pcm_addrd	ds.l	1			;the delayed snd_pcm_addr
snd_dly		ds.b	SDMAX*SDREC
snd_cmdd	ds.b	SCMDSIZE			;the delayed command buffer (its channel bytes)
snd_pcm_vol	ds.b	1			;the PCM sound's volume (3-$1F),
snd_pcm_rate	ds.b	1			;its rate (0: stopped)
snd_pcm_vold	ds.b	1			;(delayed)
snd_pcm_rated	ds.b	1

	section	game,code
