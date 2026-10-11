; $01A264  Adapted from sound93.asm: sound driver, then the sound data
;	NHL 94 (retail) segment $1A264-$4B5BF
;68k side of the sound driver, as 93 sound93 (same driver, revised): p_turnoff, play_sfx_or_music_track (
;p_initfx), play_new_song, the 94 pad readers (ReadJoyData ... ResetZ80Bus, run from p_music_vblank), p_music_vblank (
;	MusicVB), UploadCommandBufferToZ80, ProcessOneMusicTrack and the event handlers, UpdateChannelFrequencyAndVolume, the 94
;volume routine SetChannelVolume, p_initialZ80 and ClearAllTrackAndSFXSlots. Then, as 93 sound93 (incbins after the
;	driver), the sound data from $1AD90 to $4B5BF: the Z80 program (Z80_Program_Code, loaded by p_initialZ80), the PCM sample table and
;	the 12 samples (pcm_sample_table), the FM patches (fm_instrument_patches), the pointer table of sounds 0-$7A (MusicTrackPointerTable,
;	songs from SongPointerTable) and the 122 sound and song event streams, each incbin a file written by npm run extractassets
;	(extractAssets94.js), split as 93 (93 file names where the bytes are the same: the Z80 driver, samples, patches and sounds 0-$2F).
;	94 changes from 93: sounds 0-$7A (93 0-$37) through a long pointer table (93 word offsets), 8 byte channel structs (93 6), a voice
;	volume word (+4) and the controller event handle_command_30, the vblank pad reading, and the Rev A 93 50 Hz tempo block.
;Transcribed from lst/nhl94.bin.lst lines 61529-63138. Global names are the s where the routine is the 93 one or
;an auto name or no label (in an), else the Locals are the 93 local where the code matches (.fnum,.bendtab,.veltab), else in
;the 93 style (.x exit,.loop, numbered), with the unless generic, in an ; handle_command_30 ($1AC82-$1ACBF) is
;	dc.b, written as instructions; the tables are written as in 93.
;RAM (ram_addrs.inc 93 names): fm_track_slots (8 x 6 bytes), fm_channel_structs (94: 6 x 8 bytes
;	+0 key, +1 note, +2 volume, +3 patch, +4 output channel, +5 age, +6 bit 0 on), fm_voice_usage_table (8 bytes per key:
;	word +0 pitch bend, +3 patch, word +4 volume), Z80_command_buffer (33 bytes, copied to Z80 RAM $02), per_channel_attenuation_table
;	per_channel_attenuation_table, music_needs_z80_update.
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp / cmpi;
;	fixopcodes.js patches the cmp encoding after assembly.

p_turnoff	;(audio stop). Silence everything: free all slots, key off and mute every output channel, send the buffer
	;and stop the PCM channel. Called from Begin and the game screens
	movem.l	d0-d7/a0-a2,-(sp)
	bsr.w	ClearAllTrackAndSFXSlots
	move.b	#$77,(Z80_command_buffer).w	;93 Z80_command_buffer: key off channels 0-2, 4-6
	move.b	#$77,(Z80_command_buffer+2).w	;volume change on 0-2, 4-6
	moveq	#6,d0
	movea.w	#(per_channel_attenuation_table-M68K_RAM),a0	;93 per_channel_attenuation_table: 7 volume bytes
.loop
	move.b	#$7F,(a0)+	;$7F = silent
	dbf	d0,.loop
	bsr.w	UploadCommandBufferToZ80
	bsr.w	ClearZ80SpecialEffectsFlags
	movem.l	(sp)+,d0-d7/a0-a2
rtsfx	;The shared rts; play_sfx_or_music_track and ProcessOneMusicTrack branch to it
	rts
play_sfx_or_music_track	;Start sound d0 (0-$7A; 93 0-$37) in the track slot with the lowest pointer. $30 and up are
	;songs: the song already playing is stopped first (play_new_song). 94 takes the event stream from the long pointer table MusicTrackPointerTable (93 word
	;offsets) and also sets each voice volume (+4) to $7F. Called from sfx and song
	cmp.w	#$7A,d0
	bhi.s	rtsfx	;out of range
	movem.l	d0-d3/a0-a2,-(sp)
	cmp.w	#$30,d0
	blt.w	.0
	bsr.w	play_new_song	;song: stop the current song
.0
	lea	(fm_track_slots).w,a1	;93 fm_track_slots: 8 x 6 bytes
	moveq	#7,d3
.loop
	move.l	(a1),d1
	move.w	d3,d2
	movea.w	a1,a2
.loop2
	cmp.l	(a1),d1
	bgt.s	.loop
	addq.w	#6,a1
	dbf	d3,.loop2
	tst.w	(a2)
	bpl.w	.x	;no free slot (lowest pointer is in use): do nothing
	asl.w	#2,d0
	lea	(MusicTrackPointerTable).l,a0
	movea.l	0(a0,d0.w),a0
	move.l	a0,(a2)
	clr.w	4(a2)
	move.b	(a0),5(a2)	;first delay
	lea	(fm_voice_usage_table).w,a0	;93 fm_voice_usage_table
	asl.w	#3,d2
	adda.w	d2,a0
	moveq	#7,d0	;the 8 midi channels of this track
.loop3
	clr.w	(a0)
	clr.b	2(a0)
	clr.b	3(a0)
	move.w	#$7F,4(a0)
	adda.w	#$40,a0
	dbf	d0,.loop3
.x
	movem.l	(sp)+,d0-d3/a0-a2
	rts
play_new_song	;Stop the song in progress: free the first slot whose pointer is at or past the first song ($30, SongPointerTable)
	;and key off its channels. Called from play_sfx_or_music_track, DoGameFrame and others
	movem.l	d0-d3/a0-a3,-(sp)
	move	sr,-(sp)
	move	#$2700,sr	;94: no interrupts while the slots change
	lea	(fm_track_slots).w,a1
	moveq	#7,d3
	movea.l	(SongPointerTable).l,a0
.find
	cmpa.l	(a1),a0
	addq.w	#6,a1
	dble	d3,.find
	bgt.w	.0	;none: no song playing
	clr.l	(Z80_command_buffer).w
	clr.b	(Z80_command_buffer+4).w
	move.l	#-1,-6(a1)	;free the slot
	moveq	#5,d1
	lea	(fm_channel_structs).w,a2	;93 fm_channel_structs (94: 6 x 8 bytes)
.kill
	move.b	(a2),d2
	andi.w	#7,d2
	cmp.w	d2,d3
	bne.w	.next
	bsr.w	ReleaseChannelAndNote
	move.b	4(a2),d0
	lea	(per_channel_attenuation_table).w,a1
	move.b	#$7F,0(a1,d0.w)
	bset	d0,(Z80_command_buffer+2).w
.next
	addq.w	#8,a2
	dbf	d1,.kill
	bsr.w	UploadCommandBufferToZ80
.0
	move	(sp)+,sr
	movem.l	(sp)+,d0-d3/a0-a3
	rts
ReadJoyData	;read the pads every vblank (p_music_vblank). With FourWayPlay, pads 1-4 through the 4 way adaptor (ReadPad4Way1 ...
	;ReadPad4Way4) to pad4way1-pad4way4, else pads 1 and 2 (ReadPad1, ReadPad2)
	movem.l	d1/a0,-(sp)
	tst.w	(FourWayPlay).w
	beq.w	.0
	bsr.s	ReadPad4Way1
	move.b	d0,(pad4way1).w
	bsr.s	ReadPad4Way2
	move.b	d0,(pad4way2).w
	bsr.w	ReadPad4Way3
	move.b	d0,(pad4way3).w
	bsr.w	ReadPad4Way4
	move.b	d0,(pad4way4).w
	bra.w	.x
.0
	bsr.w	ReadPad1
	move.b	d0,(pad4way1).w
	bsr.w	ReadPad2
	move.b	d0,(pad4way2).w
.x
	movem.l	(sp)+,d1/a0
	rts
ReadPad4Way1	;4 way play pad 1: take the Z80 bus (ResetZ80Bus if it is not granted), select pad 1 on port 2 and read it on port 1 (ReadPad4WayPort1)
	move.w	#$100,(IO_Z80BUS).l
	move.w	#$64,d0
.loop
	btst	#0,(IO_Z80BUS).l
	beq.s	.0
	dbf	d0,.loop
	bsr.w	ResetZ80Bus
.0
	move.b	#$C,(IO_CT2_DATA+1).l
	bra.w	ReadPad4WayPort1
ReadPad4Way2	;4 way play pad 2: take the Z80 bus (ResetZ80Bus if it is not granted), select pad 2 on port 2 and read it on port 1 (ReadPad4WayPort1)
	move.w	#$100,(IO_Z80BUS).l
	move.w	#$64,d0
.loop
	btst	#0,(IO_Z80BUS).l
	beq.s	.0
	dbf	d0,.loop
	bsr.w	ResetZ80Bus
.0
	move.b	#$1C,(IO_CT2_DATA+1).l
	bra.w	ReadPad4WayPort1
ReadPad4Way3	;4 way play pad 3: take the Z80 bus (ResetZ80Bus if it is not granted), select pad 3 on port 2 and read it on port 1 (ReadPad4WayPort1)
	move.w	#$100,(IO_Z80BUS).l
	move.w	#$64,d0
.loop
	btst	#0,(IO_Z80BUS).l
	beq.s	.0
	dbf	d0,.loop
	bsr.w	ResetZ80Bus
.0
	move.b	#$2C,(IO_CT2_DATA+1).l
	bra.w	ReadPad4WayPort1
ReadPad4Way4	;4 way play pad 4: take the Z80 bus (ResetZ80Bus if it is not granted), select pad 4 on port 2 and read it on port 1 (ReadPad4WayPort1)
	move.w	#$100,(IO_Z80BUS).l
	move.w	#$64,d0
.loop
	btst	#0,(IO_Z80BUS).l
	beq.s	.0
	dbf	d0,.loop
	bsr.w	ResetZ80Bus
.0
	move.b	#$3C,(IO_CT2_DATA+1).l
ReadPad4WayPort1	;Read the pad on port 1; branched to from ReadPad4Way1 ... ReadPad4Way4
	movem.l	d1/a0,-(sp)
	lea	(IO_CT1_DATA+1).l,a0
	bra.w	ReadPad3Button
ReadPad2	;Read pad 2 (port 2). Falls into ReadPadA0
	movem.l	d1/a0,-(sp)
	lea	(IO_CT2_DATA+1).l,a0
	bra.s	ReadPadA0
ReadPad1	;Read pad 1 (port 1)
	movem.l	d1/a0,-(sp)
	lea	(IO_CT1_DATA+1).l,a0
ReadPadA0	;Take the Z80 bus (ResetZ80Bus if it is not granted), then ReadPad3Button
	move.w	#$100,(IO_Z80BUS).l
	move.w	#$64,d0
.loop
	btst	#0,(IO_Z80BUS).l
	beq.s	ReadPad3Button
	dbf	d0,.loop
	bsr.w	ResetZ80Bus
ReadPad3Button	;Read a 3 button pad at a0 (TH low, then high), release the bus and return d0 = the buttons, the directions through PadDirTable
	moveq	#0,d0
	move.b	#0,(a0)
	nop
	nop
	move.b	(a0),d0
	move.b	#$40,(a0)
	nop
	nop
	move.b	(a0),d1
	move.w	#0,(IO_Z80BUS).l
	asl.b	#2,d0
	andi.b	#$C0,d0
	andi.b	#$3F,d1
	or.b	d1,d0
	not.b	d0
	not.b	d1
	andi.w	#$F,d1
	lea	PadDirTable(pc),a0
	andi.b	#$F0,d0
	or.b	0(a0,d1.w),d0
	not.b	d0
	movem.l	(sp)+,d1/a0
	rts
PadDirTable	;Direction nibble table for ReadPad3Button: remaps the nibble when opposite directions are pressed together
	dc.b	0,1,2,1,4,5,6,6,8,9,$A,$A,8,9,$A,0
ResetZ80Bus	;Reset the Z80 and wait for its bus
	move.w	#$100,(IO_Z80RES).l
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	rts
p_music_vblank	;(vblank handler). Read the pads (ReadJoyData, 94), clear the change bits, run the 8 track slots (d7 = track
	;7-0), send the buffer if anything changed and age the channels. 94 keeps the Rev A 93 50 Hz block: with PALflag bit 0 set the slots run
	;again every 6th frame (music_tick_divider). Called from the vblank handlers
	bsr.w	ReadJoyData
	clr.b	(music_needs_z80_update).w	;93 music_needs_z80_update
	clr.l	(Z80_command_buffer).w	;key off/on, volume, frequency bits
	clr.b	(Z80_command_buffer+4).w	;patch bits
.loop
	lea	(fm_track_slots).w,a5
	moveq	#7,d7
.loop2
	bsr.w	ProcessOneMusicTrack
	addq.w	#6,a5
	dbf	d7,.loop2
	btst	#0,(PALflag).w
	beq.w	.0
	subq.w	#1,(music_tick_divider).w
	bpl.w	.0
	addq.w	#6,(music_tick_divider).w
	bra.s	.loop
.0
	tst.b	(music_needs_z80_update).w
	beq.w	.1	;nothing changed
	bsr.w	UploadCommandBufferToZ80
.1
	movea.w	#(fm_channel_structs-M68K_RAM),a0
	moveq	#5,d0
.loop3
	addq.b	#1,5(a0)	;age
	bne.w	.2
	subq.b	#1,5(a0)	;hold at $FF
.2
	addq.w	#8,a0
	dbf	d0,.loop3
	rts
z80_bus_release_delay	;Z80 busy: give the bus back, wait, then falls into UploadCommandBufferToZ80 to retry
	clr.w	(IO_Z80BUS).l
	moveq	#$64,d0
.delay
	dbf	d0,.delay
UploadCommandBufferToZ80	;Copy the 33 byte command buffer (Z80_command_buffer) to Z80 RAM $02 once the Z80 is idle (Z80 RAM $97 = 0, $96 = $7D)
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	movea.l	#Z80_RAM,a0
	cmpi.b	#0,$97(a0)
	bne.s	z80_bus_release_delay
	cmpi.b	#$7D,$96(a0)
	bne.s	z80_bus_release_delay
	move.b	#$D1,$96(a0)
	move.b	#0,$97(a0)
	adda.w	#2,a0
	movea.w	#(Z80_command_buffer-M68K_RAM),a1
	moveq	#$20,d0
.copy
	move.b	(a1)+,(a0)+
	dbf	d0,.copy
	clr.w	(IO_Z80BUS).l
rtscmd10	;The shared rts; handle_command_10 branches to it
	rts
ProcessOneMusicTrack	;Count down track slot a5 (track d7) and run every event that is due through command_jump_table. A 0
	;status ends the stream; a non-negative long at +2 is a loop pointer. Called from p_music_vblank
	subq.w	#1,4(a5)
	bpl.w	rtsfx
.event
	tst.w	(a5)
	bmi.w	rtsfx
	movea.l	(a5),a0
	addq.l	#4,(a5)
	clr.w	4(a5)
	move.b	4(a0),5(a5)
	move.b	1(a0),d0
	bne.w	.cmd
	st	(a5)
	tst.w	2(a0)
	bmi.w	rtsfx
	move.l	2(a0),(a5)
	bra.s	.event
.cmd
	move.b	1(a0),d0
	andi.w	#$70,d0	;status bits 6-4
	lsr.w	#3,d0
	lea	command_jump_table(pc),a2
	adda.w	0(a2,d0.w),a2
	jsr	(a2)
	bra.s	ProcessOneMusicTrack
command_jump_table	;Event handlers by status bits 6-4, as offsets from the table. 94 adds handle_command_30
	dc.w	handle_command_00-command_jump_table
	dc.w	handle_command_10-command_jump_table
	dc.w	handle_command_skip-command_jump_table
	dc.w	handle_command_30-command_jump_table
	dc.w	handle_command_40-command_jump_table
	dc.w	handle_command_skip-command_jump_table
	dc.w	handle_command_60-command_jump_table
	dc.w	handle_command_skip-command_jump_table
handle_command_00	;Event $0x: key off note +2 on channel +1 bits 3-0 of track d7. Also entered from handle_command_10 (volume 0). Falls into ReleaseChannelAndNote
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0
	asl.w	#8,d0
	move.b	2(a0),d0
	movea.w	#(fm_track_slots-M68K_RAM),a2
	moveq	#5,d1
.find
	subq.w	#8,a2
	cmp.w	(a2),d0
	dbeq	d1,.find
	bne.w	rtsfx
	btst	#0,6(a2)
	dbne	d1,.find
	beq.w	rtsfx
ReleaseChannelAndNote	;Key off channel struct a2 if it is on. The PCM patches ($60 up) stop the PCM channel (ClearZ80SpecialEffectsFlags)
	bclr	#0,6(a2)
	beq.w	rtsfx
	cmpi.b	#$60,3(a2)
	bge.w	ClearZ80SpecialEffectsFlags
	move.b	4(a2),d0
	bset	d0,(Z80_command_buffer).w
	st	(music_needs_z80_update).w
	rts
ClearZ80SpecialEffectsFlags	;Clear Z80 RAM $8E (Z80_RAM+$8E, the PCM rate byte written by UpdateChannelFrequencyAndVolume): stops the PCM channel
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	clr.b	(Z80_RAM+$8E).l
	clr.w	(IO_Z80BUS).l
	rts
handle_command_10	;Event $1x: key on note +2 at volume +3 on channel +1 bits 3-0 of track d7 (volume 0 = key off). An FM
	;patch takes a free channel or the oldest one; a PCM patch ($60 up) sets the sample start / end (pcm_sample_table, 93 name) in Z80 RAM
	;$23-$28. Then the volume (SetChannelVolume) and the frequency (UpdateChannelFrequencyAndVolume)
	tst.b	3(a0)
	beq.s	handle_command_00	;volume 0: key off
	movea.w	#(fm_channel_struct6-M68K_RAM),a2
	lea	(fm_voice_usage_table).w,a3
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0
	move.w	d0,d6
	asl.w	#3,d0
	move.b	3(a3,d0.w),d0
	cmp.b	#$60,d0
	bge.w	.pcm	;PCM patch
	subq.w	#8,a2
	moveq	#4,d1
	bra.w	.setold
.old
	cmp.b	5(a2),d2
	bhi.w	.nextold
.setold
	movea.w	a2,a4
	move.b	5(a4),d2
.nextold
	subq.w	#8,a2
	dbf	d1,.old
	moveq	#4,d1
	movea.w	#(fm_channel_struct6-M68K_RAM),a2
.free
	subq.w	#8,a2
	btst	#0,6(a2)
	dbeq	d1,.free
	bne.w	.0
	movea.w	a2,a4
	cmp.b	3(a4),d0
	dbeq	d1,.free
	beq.w	.keyon
	bra.w	.patch
.0
	cmp.b	3(a4),d0
	beq.w	.keyon
.patch
	movea.w	a4,a2
.1
	move.b	d0,3(a2)
	clr.w	d1
	move.b	4(a2),d1
	bset	d1,(Z80_command_buffer+4).w
	movea.w	#(per_channel_patch_table-M68K_RAM),a4
	move.b	d0,0(a4,d1.w)
	st	(music_needs_z80_update).w
.keyon
	clr.b	5(a2)
	bset	#0,6(a2)
	move.b	d6,(a2)
	move.b	2(a0),1(a2)
	move.b	3(a0),2(a2)
	clr.w	d1
	move.b	4(a2),d1
	bset	d1,(Z80_command_buffer).w
	bset	d1,(Z80_command_buffer+1).w
	bsr.w	SetChannelVolume
	bra.w	UpdateChannelFrequencyAndVolume
.pcm
	bset	#0,6(a2)
	beq.w	.pcmon
	cmp.b	3(a2),d0
	ble.w	rtscmd10
.pcmon
	move.b	d0,3(a2)
	clr.b	5(a2)
	move.b	d6,(a2)
	move.b	2(a0),1(a2)
	move.b	3(a0),2(a2)
	ext.w	d0
	subi.w	#$60,d0
	asl.w	#3,d0
	lea	pcm_sample_table(pc),a1	;PCM sample start, end longs by patch - $60
	move.l	4(a1,d0.w),d1
	move.l	0(a1,d0.w),d0
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	movea.l	#Z80_RAM,a1
	move.b	d0,$25(a1)
	lsr.w	#8,d0
	move.b	d0,$24(a1)
	swap	d0
	move.b	d0,$23(a1)
	move.b	d1,$28(a1)
	lsr.w	#8,d1
	move.b	d1,$27(a1)
	swap	d1
	move.b	d1,$26(a1)
	move.b	#$29,$96(a1)
	move.b	#0,$97(a1)
	clr.w	(IO_Z80BUS).l
	bsr.w	SetChannelVolume
UpdateChannelFrequencyAndVolume	;Set the frequency of channel struct a2 from its note and the pitch bend of its key (a3 =
	;voice table, word +0 = bend). Called from handle_command_60 and handle_command_10
	clr.l	d3
	move.b	1(a2),d3
	divu.w	#$C,d3	;d3 = octave, high word = note in the octave
	move.w	d3,-(sp)
	swap	d3
	add.w	d3,d3
	lea	.fnum(pc),a4
	move.w	0(a4,d3.w),d2
	clr.w	d1
	move.b	(a2),d1
	asl.w	#3,d1
	move.w	0(a3,d1.w),d3
	beq.w	.nobend
	moveq	#$C,d1
	cmpi.b	#$60,3(a2)
	bge.w	.0
	move.b	3(a2),d1
	asl.w	#5,d1
	lea	(fm_instrument_patches).l,a4	;32 bytes per patch
	move.b	$1E(a4,d1.w),d1	;byte $1E = pitch bend scale
	ext.w	d1
.0
	muls.w	d1,d3
	asr.l	#2,d3
	asr.w	#7,d3
	addi.w	#$C0,d3	;centre of .bendtab
	add.w	d3,d3
	lea	.bendtab(pc),a4
	mulu.w	0(a4,d3.w),d2
	asl.l	#1,d2
	swap	d2
.nobend
	move.w	(sp)+,d3
	cmpi.b	#$60,3(a2)
	bge.w	.1
	asl.w	#3,d3
	asl.w	#8,d3
	or.w	d3,d2
	clr.w	d3
	move.b	4(a2),d3
	bset	d3,(Z80_command_buffer+3).w
	add.w	d3,d3
	movea.w	#(per_channel_frequency_table-M68K_RAM),a4
	move.w	d2,0(a4,d3.w)
	st	(music_needs_z80_update).w
	rts
.1
	btst	#0,6(a2)
	beq.w	.x
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	neg.w	d3
	addq.w	#8,d3
	lsr.w	d3,d2
	move.b	d2,(Z80_RAM+$8E).l
	clr.w	(IO_Z80BUS).l
.x
	rts
.fnum	;frequency number of each note in the octave
	dc.w	$0146,$0159,$016E,$0184,$019B,$01B3,$01CD,$01E8,$0205,$0224,$0245,$0268
.bendtab	;385 factors, entry $C0 = $8000 (no bend)
	dc.w	$4000,$403B,$4076,$40B2,$40EE,$412A,$4166,$41A3,$41E0,$421D
	dc.w	$425A,$4297,$42D5,$4313,$4351,$438F,$43CE,$440D,$444C,$448B
	dc.w	$44CA,$450A,$454A,$458A,$45CA,$460B,$464C,$468D,$46CE,$4710
	dc.w	$4752,$4794,$47D6,$4818,$485B,$489E,$48E1,$4925,$4969,$49AD
	dc.w	$49F1,$4A35,$4A7A,$4ABF,$4B04,$4B4A,$4B8F,$4BD5,$4C1B,$4C62
	dc.w	$4CA9,$4CF0,$4D37,$4D7E,$4DC6,$4E0E,$4E56,$4E9F,$4EE8,$4F31
	dc.w	$4F7A,$4FC4,$500E,$5058,$50A2,$50ED,$5138,$5183,$51CE,$521A
	dc.w	$5266,$52B2,$52FF,$534C,$5399,$53E6,$5434,$5482,$54D0,$551F
	dc.w	$556E,$55BD,$560C,$565C,$56AC,$56FC,$574C,$579D,$57EE,$5840
	dc.w	$5891,$58E3,$5936,$5988,$59DB,$5A2E,$5A82,$5AD6,$5B2A,$5B7E
	dc.w	$5BD3,$5C28,$5C7D,$5CD3,$5D29,$5D7F,$5DD6,$5E2D,$5E84,$5EDB
	dc.w	$5F33,$5F8B,$5FE4,$603D,$6096,$60EF,$6149,$61A3,$61FD,$6258
	dc.w	$62B3,$630E,$636A,$63C6,$6423,$647F,$64DC,$653A,$6597,$65F6
	dc.w	$6654,$66B3,$6712,$6771,$67D1,$6831,$6892,$68F2,$6954,$69B5
	dc.w	$6A17,$6A79,$6ADC,$6B3F,$6BA2,$6C06,$6C6A,$6CCE,$6D33,$6D98
	dc.w	$6DFD,$6E63,$6EC9,$6F30,$6F97,$6FFE,$7066,$70CE,$7136,$719F
	dc.w	$7208,$7272,$72DC,$7346,$73B1,$741C,$7488,$74F4,$7560,$75CD
	dc.w	$763A,$76A7,$7715,$7783,$77F2,$7861,$78D0,$7940,$79B0,$7A21
	dc.w	$7A92,$7B04,$7B76,$7BE8,$7C5B,$7CCE,$7D41,$7DB5,$7E2A,$7E9F
	dc.w	$7F14,$7F89,$8000,$8076,$80ED,$8164,$81DC,$8254,$82CD,$8346
	dc.w	$83C0,$843A,$84B4,$852F,$85AA,$8626,$86A2,$871F,$879C,$881A
	dc.w	$8898,$8916,$8995,$8A14,$8A94,$8B14,$8B95,$8C16,$8C98,$8D1A
	dc.w	$8D9D,$8E20,$8EA4,$8F28,$8FAC,$9031,$90B7,$913D,$91C3,$924A
	dc.w	$92D2,$935A,$93E2,$946B,$94F4,$957E,$9609,$9694,$971F,$97AB
	dc.w	$9837,$98C4,$9952,$99E0,$9A6E,$9AFD,$9B8D,$9C1D,$9CAD,$9D3E
	dc.w	$9DD0,$9E62,$9EF5,$9F88,$A01C,$A0B0,$A145,$A1DA,$A270,$A306
	dc.w	$A39D,$A435,$A4CD,$A565,$A5FE,$A698,$A732,$A7CD,$A868,$A904
	dc.w	$A9A1,$AA3E,$AADC,$AB7A,$AC18,$ACB8,$AD58,$ADF8,$AE99,$AF3B
	dc.w	$AFDD,$B080,$B123,$B1C7,$B26C,$B311,$B3B7,$B45D,$B504,$B5AC
	dc.w	$B654,$B6FD,$B7A7,$B851,$B8FB,$B9A6,$BA52,$BAFF,$BBAC,$BC5A
	dc.w	$BD08,$BDB7,$BE67,$BF17,$BFC8,$C07A,$C12C,$C1DF,$C292,$C346
	dc.w	$C3FB,$C4B1,$C567,$C61D,$C6D5,$C78D,$C846,$C8FF,$C9B9,$CA74
	dc.w	$CB2F,$CBEC,$CCA8,$CD66,$CE24,$CEE3,$CFA2,$D063,$D124,$D1E5
	dc.w	$D2A8,$D36B,$D42E,$D4F3,$D5B8,$D67E,$D744,$D80C,$D8D4,$D99D
	dc.w	$DA66,$DB30,$DBFB,$DCC7,$DD93,$DE60,$DF2E,$DFFD,$E0CC,$E19D
	dc.w	$E26D,$E33F,$E411,$E4E5,$E5B9,$E68D,$E763,$E839,$E910,$E9E8
	dc.w	$EAC0,$EB9A,$EC74,$ED4F,$EE2A,$EF07,$EFE4,$F0C2,$F1A1,$F281
	dc.w	$F361,$F443,$F525,$F608,$F6EC,$F7D0,$F8B6,$F99C,$FA83,$FB6B
	dc.w	$FC54,$FD3E,$FE28,$FF13,$FF13
SetChannelVolume	;Set the volume of channel struct a2: note volume (+2) * the voice volume (voice table +4) / 128. FM: attenuation from
	;.veltab (volume / 8); PCM: Z80 RAM $83 (Z80_RAM+$83, at least 3). Called from handle_command_10 and handle_command_30
	movem.l	d0,-(sp)
	clr.w	d0
	move.b	2(a2),d0
	clr.w	d1
	move.b	(a2),d1
	asl.w	#3,d1
	mulu.w	4(a3,d1.w),d0
	lsr.w	#7,d0
	cmpi.b	#$60,3(a2)
	bge.w	.0
	lea	.veltab(pc),a4
	lsr.w	#3,d0
	move.b	0(a4,d0.w),d0
	clr.w	d3
	move.b	4(a2),d3
	movea.w	#(per_channel_attenuation_table-M68K_RAM),a4
	move.b	d0,0(a4,d3.w)
	bset	d3,(Z80_command_buffer+2).w
	st	(music_needs_z80_update).w
	movem.l	(sp)+,d0
	rts
.veltab	;attenuation by volume / 8 (93 handle_command_10 .veltab)
	dc.b	$1A,$18,$16,$14,$12,$10,$0E,$0C,$0A,$08,$06,$04,$03,$02,$01,$00
.0
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	lsr.b	#2,d0
	cmp.w	#3,d0
	bgt.w	.1
	moveq	#3,d0
.1
	move.b	d0,(Z80_RAM+$83).l
	clr.w	(IO_Z80BUS).l
	movem.l	(sp)+,d0
	rts
handle_command_40	;Event $4x: set the patch of channel +1 bits 3-0 of track d7 to +2 (voice table +3)
	lea	(fm_voice_usage_table).w,a3
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0
	asl.w	#3,d0
	move.b	2(a0),3(a3,d0.w)
	rts
handle_command_60	;Event $6x: set the pitch bend of channel +1 bits 3-0 of track d7 to word +2 - $2000, and update the frequency of every channel with that key
	lea	(fm_voice_usage_table).w,a3
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0
	move.w	d0,d4
	asl.w	#3,d0
	move.w	2(a0),0(a3,d0.w)
	subi.w	#$2000,0(a3,d0.w)
	movea.w	#(fm_channel_structs-M68K_RAM),a2
	moveq	#5,d0
.loop
	cmp.b	(a2),d4
	bne.w	.next
	bsr.w	UpdateChannelFrequencyAndVolume
.next
	addq.w	#8,a2
	dbf	d0,.loop
	rts
handle_command_30	;event $3x, controller +2 = +3 on channel +1 bits 3-0 of track d7. Only controller 7
	;(volume) is used: set the voice volume (voice table +5) and update the volume of every channel with that key (SetChannelVolume)
	cmpi.b	#7,2(a0)
	beq.w	.0
	rts
.0
	lea	(fm_voice_usage_table).w,a3
	move.b	1(a0),d0
	andi.w	#$F,d0
	asl.w	#3,d0
	or.w	d7,d0
	move.w	d0,d4
	asl.w	#3,d0
	move.b	3(a0),5(a3,d0.w)
	movea.w	#(fm_channel_structs-M68K_RAM),a2
	moveq	#5,d0
.loop
	cmp.b	(a2),d4
	bne.w	.1
	bsr.w	SetChannelVolume
.1
	addq.w	#8,a2
	dbf	d0,.loop
	rts
handle_command_skip	;Events $2x, $5x and $7x: ignored
	rts
p_initialZ80	;(initialization). Free all slots, load the Z80 program (Z80_Program_Code, $295 bytes) into Z80 RAM, build 29
	;tables of 256 bytes below Z80 RAM $2000 (Z80_RAM+$2000; (x - $80) * 8 / n + $80 for n = 8-$24), then reset and start the Z80. Called from Begin
	movem.l	d0-d2/a0-a2,-(sp)
	bsr.w	ClearAllTrackAndSFXSlots
	move.w	#$100,(IO_Z80RES).l
	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	movea.l	#Z80_Program_Code,a1
	movea.l	#Z80_RAM,a2
	move.w	#$294,d0	;$295 bytes
.loop2
	move.b	(a1)+,(a2)+
	dbf	d0,.loop2
	movea.l	#Z80_RAM+$2000,a2
	moveq	#8,d2
	move.l	#$1C,d3
.loop3
	move.w	#$FF,d0
.loop4
	move.w	d0,d1
	subi.w	#$80,d1
	asl.w	#3,d1
	ext.l	d1
	divs.w	d2,d1
	addi.w	#$80,d1
	move.b	d1,-(a2)
	dbf	d0,.loop4
	clr.b	(a2)
	addq.w	#1,d2
	dbf	d3,.loop3
	move.w	#0,(IO_Z80RES).l
	move.w	#0,(IO_Z80BUS).l
	move.w	#$1F4,d0
.loop5
	dbf	d0,.loop5
	move.w	#$100,(IO_Z80RES).l
	clr.b	(music_needs_z80_update).w
	movem.l	(sp)+,d0-d2/a0-a2
	rts
ClearAllTrackAndSFXSlots	;Free the 8 track slots and reset the 6 channel structs (output channels 0, 1, 2, 4, 5, 6). Called from p_turnoff and p_initialZ80
	lea	(fm_track_slots).w,a0
	moveq	#7,d0
	moveq	#-1,d1
.trk
	move.l	d1,(a0)
	addq.w	#6,a0
	dbf	d0,.trk
	moveq	#5,d0
	movea.w	#(fm_track_slots-M68K_RAM),a0
.chan
	subq.w	#8,a0
	move.b	d0,4(a0)
	cmp.w	#3,d0
	blt.w	.set
	addq.b	#1,4(a0)
.set
	st	3(a0)
	st	(a0)
	clr.b	1(a0)
	clr.b	6(a0)
	dbf	d0,.chan
	rts

;	Sound data, as 93 sound93: $1AD90-$4B5BF. The Z80 driver, the PCM samples and the FM patches are the 93 files (same bytes); the pointer
;	tables are written with the labels; each sound and song event stream is its own file (loop pointers written as dc.l).
Z80_Program_Code	;First byte of the Z80 program ($1AD90, movea.l in p_initialZ80); the rest of the Z80 blob from $1AD91 and the data
	;after it are the incbins below. p_initialZ80 copies $295 bytes from here (through $1B024, into pcm_sample_table, as 93 does)
	dc.b	$18
	incbin	..\Extracted\NHL94\Sound\z80_snd_drv93.bin	;the 93 Z80 driver after its first byte, up to the ld bc of the FM patch bank address
	dc.b	fm_instrument_patches&$FF,((fm_instrument_patches>>8)&$7F)|$80	;Z80 ld bc,$8000+(fm_instrument_patches&$7FFF): bank window address of the FM patches
	dc.b	$09,$3E,fm_instrument_patches>>15	;Z80 add hl,bc / ld a,bank (32K bank) of the FM patches
	incbin	..\Extracted\NHL94\Sound\z80_snd_drv93_end.bin	;rest of the Z80 driver
	dc.b	$FF			;pad: retail leftover byte (93 $83)
pcm_sample_table	;(sample address, 0) for PCM patches $60-$6E (lea in handle_command_10)
	dc.l	sfx_puckget_pcm,0		;patch $60
	dc.l	sfx_pass_pcm,0		;patch $61
	dc.l	sfx_shotbh_pcm,0		;patch $62
	dc.l	sfx_shotfh_pcm,0		;patch $63
	dc.l	sfx_check2_pcm,0		;patch $64
	dc.l	sfx_check_pcm,0		;patch $65
	dc.l	sfx_playerwall_pcm,0		;patch $66
	dc.l	sfx_hithigh_pcm,0		;patch $67
	dc.l	0,0		;patch $68
	dc.l	0,0		;patch $69
	dc.l	sfx_hithigh_pcm,0		;patch $6A
	dc.l	sfx_crowdboo_pcm,0		;patch $6B
	dc.l	sfx_oooh_pcm,0		;patch $6C
	dc.l	sfx_crowdcheer_pcm,0		;patch $6D
	dc.l	sfx_id_0E_pcm,0		;patch $6E
sfx_shotbh_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_shotbh_pcm.bin	;sample 2: shotbh
	even
sfx_pass_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_pass_pcm.bin	;sample 1: pass
	dc.b	$FF			;pad: retail leftover byte
sfx_oooh_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_oooh_pcm.bin	;sample 12: oooh, sfx_id_0D, sfx_id_0E
	even
sfx_crowdboo_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_crowdboo_pcm.bin	;sample 11: crowdboo
	dc.b	$FF			;pad: retail leftover byte
sfx_check_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_check_pcm.bin	;sample 5: check1, check3
	even
sfx_crowdcheer_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_crowdcheer_pcm.bin	;sample 13: crowdcheer, homewin
	even
sfx_id_0E_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_id_0E_pcm.bin	;sample 14: sfx_id_0E
	dc.b	$FF			;pad: retail leftover byte
sfx_playerwall_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_playerwall_pcm.bin	;sample 6: playerwall, sfx_id_21-23
	even
sfx_check2_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_check2_pcm.bin	;sample 4: check2, check4
	dc.b	$FF			;pad: retail leftover byte
sfx_hithigh_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_hithigh_pcm.bin	;samples 7 and 10: hithigh, hitlow, check1-4, songs $32 and $35-$37
	even
sfx_shotfh_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_shotfh_pcm.bin	;sample 3: shotfh
	even
sfx_puckget_pcm
	incbin	..\Extracted\NHL94\Sound\sfx_puckget_pcm.bin	;sample 0: puckget
	even
fm_instrument_patches	;32 FM patches x 32 bytes, byte $1E = pitch bend scale (UpdateChannelFrequencyAndVolume)
	incbin	..\Extracted\NHL94\Sound\fm_instrument_patches.bin	;32 FM patches x 32 bytes (byte $1E = pitch bend scale)
	even
MusicTrackPointerTable	;event stream of sounds 0-$7A as long pointers (play_sfx_or_music_track; 93 word offsets from the table, sounds 0-$37)
	dc.l	sfx_siren_cmdstream	;sound $0
	dc.l	sfx_beep1_cmdstream	;sound $1
	dc.l	sfx_beep2_cmdstream	;sound $2
	dc.l	sfx_whistle_cmdstream	;sound $3
	dc.l	sfx_horn_cmdstream	;sound $4
	dc.l	sfx_shotwiff_cmdstream	;sound $5
	dc.l	sfx_stdef_cmdstream	;sound $6
	dc.l	sfx_puckget_cmdstream	;sound $7
	dc.l	sfx_oooh_cmdstream	;sound $8
	dc.l	sfx_hithigh_cmdstream	;sound $9
	dc.l	sfx_hitlow_cmdstream	;sound $A
	dc.l	sfx_crowdcheer_cmdstream	;sound $B
	dc.l	sfx_crowdboo_cmdstream	;sound $C
	dc.l	sfx_id_0D_cmdstream	;sound $D
	dc.l	sfx_id_0E_cmdstream	;sound $E
	dc.l	sfx_homewin_cmdstream	;sound $F
	dc.l	sfx_pass1_cmdstream	;sound $10
	dc.l	sfx_pass2_cmdstream	;sound $11
	dc.l	sfx_pass3_cmdstream	;sound $12
	dc.l	sfx_pass4_cmdstream	;sound $13
	dc.l	sfx_shotbh1_cmdstream	;sound $14
	dc.l	sfx_shotbh2_cmdstream	;sound $15
	dc.l	sfx_shotbh3_cmdstream	;sound $16
	dc.l	sfx_shotbh4_cmdstream	;sound $17
	dc.l	sfx_shotfh1_cmdstream	;sound $18
	dc.l	sfx_shotfh2_cmdstream	;sound $19
	dc.l	sfx_shotfh3_cmdstream	;sound $1A
	dc.l	sfx_shotfh4_cmdstream	;sound $1B
	dc.l	sfx_check1_cmdstream	;sound $1C
	dc.l	sfx_check2_cmdstream	;sound $1D
	dc.l	sfx_check3_cmdstream	;sound $1E
	dc.l	sfx_check4_cmdstream	;sound $1F
	dc.l	sfx_playerwall_cmdstream	;sound $20
	dc.l	sfx_id_21_cmdstream	;sound $21
	dc.l	sfx_id_22_cmdstream	;sound $22
	dc.l	sfx_id_23_cmdstream	;sound $23
	dc.l	sfx_puckbody_cmdstream	;sound $24
	dc.l	sfx_puckpost_cmdstream	;sound $25
	dc.l	sfx_id_26_27_cmdstream	;sound $26
	dc.l	sfx_id_26_27_cmdstream	;sound $27
	dc.l	sfx_puckwall1_cmdstream	;sound $28
	dc.l	sfx_puckwall2_cmdstream	;sound $29
	dc.l	sfx_puckwall3_cmdstream	;sound $2A
	dc.l	sfx_puckwall4_cmdstream	;sound $2B
	dc.l	sfx_puckice1_cmdstream	;sound $2C
	dc.l	sfx_puckice2_cmdstream	;sound $2D
	dc.l	sfx_puckice3_cmdstream	;sound $2E
	dc.l	sfx_puckice4_cmdstream	;sound $2F
SongPointerTable	;the songs $30-$7A of MusicTrackPointerTable (play_new_song reads the first)
	dc.l	fmtune_id_30_cmdstream	;song $30
	dc.l	fmtune_id_31_cmdstream	;song $31
	dc.l	fmtune_id_32_cmdstream	;song $32
	dc.l	fmtune_id_33_cmdstream	;song $33
	dc.l	fmtune_id_34_cmdstream	;song $34
	dc.l	fmtune_id_35_cmdstream	;song $35
	dc.l	fmtune_id_36_cmdstream	;song $36
	dc.l	fmtune_id_37_cmdstream	;song $37
	dc.l	fmtune_id_38_cmdstream	;song $38
	dc.l	fmtune_id_39_cmdstream	;song $39
	dc.l	fmtune_id_3A_cmdstream	;song $3A
	dc.l	fmtune_id_3B_cmdstream	;song $3B
	dc.l	fmtune_id_3C_cmdstream	;song $3C
	dc.l	fmtune_id_3D_cmdstream	;song $3D
	dc.l	fmtune_id_3E_cmdstream	;song $3E
	dc.l	fmtune_id_3F_cmdstream	;song $3F
	dc.l	fmtune_id_40_cmdstream	;song $40
	dc.l	fmtune_id_41_cmdstream	;song $41
	dc.l	fmtune_id_42_cmdstream	;song $42
	dc.l	fmtune_id_43_cmdstream	;song $43
	dc.l	fmtune_id_44_cmdstream	;song $44
	dc.l	fmtune_id_45_cmdstream	;song $45
	dc.l	fmtune_id_46_cmdstream	;song $46
	dc.l	fmtune_id_47_cmdstream	;song $47
	dc.l	fmtune_id_48_cmdstream	;song $48
	dc.l	fmtune_id_49_cmdstream	;song $49
	dc.l	fmtune_id_4A_cmdstream	;song $4A
	dc.l	fmtune_id_4B_cmdstream	;song $4B
	dc.l	fmtune_id_4C_cmdstream	;song $4C
	dc.l	fmtune_id_4D_cmdstream	;song $4D
	dc.l	fmtune_id_4E_cmdstream	;song $4E
	dc.l	fmtune_id_4F_cmdstream	;song $4F
	dc.l	fmtune_id_50_cmdstream	;song $50
	dc.l	fmtune_id_51_cmdstream	;song $51
	dc.l	fmtune_id_52_cmdstream	;song $52
	dc.l	fmtune_id_53_cmdstream	;song $53
	dc.l	fmtune_id_54_cmdstream	;song $54
	dc.l	fmtune_id_55_cmdstream	;song $55
	dc.l	fmtune_id_56_cmdstream	;song $56
	dc.l	fmtune_id_57_cmdstream	;song $57
	dc.l	fmtune_id_58_cmdstream	;song $58
	dc.l	fmtune_id_59_cmdstream	;song $59
	dc.l	fmtune_id_5A_cmdstream	;song $5A
	dc.l	fmtune_id_5B_cmdstream	;song $5B
	dc.l	fmtune_id_5C_cmdstream	;song $5C
	dc.l	fmtune_id_5D_cmdstream	;song $5D
	dc.l	fmtune_id_5E_cmdstream	;song $5E
	dc.l	fmtune_id_5F_cmdstream	;song $5F
	dc.l	fmtune_id_60_cmdstream	;song $60
	dc.l	fmtune_id_61_cmdstream	;song $61
	dc.l	fmtune_id_62_cmdstream	;song $62
	dc.l	fmtune_id_63_cmdstream	;song $63
	dc.l	fmtune_id_64_cmdstream	;song $64
	dc.l	fmtune_id_65_cmdstream	;song $65
	dc.l	fmtune_id_66_cmdstream	;song $66
	dc.l	fmtune_id_67_cmdstream	;song $67
	dc.l	fmtune_id_68_cmdstream	;song $68
	dc.l	fmtune_id_69_cmdstream	;song $69
	dc.l	fmtune_id_6A_cmdstream	;song $6A
	dc.l	fmtune_id_6B_cmdstream	;song $6B
	dc.l	fmtune_id_6C_cmdstream	;song $6C
	dc.l	fmtune_id_6D_cmdstream	;song $6D
	dc.l	fmtune_id_6E_cmdstream	;song $6E
	dc.l	fmtune_id_6F_cmdstream	;song $6F
	dc.l	fmtune_id_70_cmdstream	;song $70
	dc.l	fmtune_id_71_cmdstream	;song $71
	dc.l	fmtune_id_72_cmdstream	;song $72
	dc.l	fmtune_id_73_cmdstream	;song $73
	dc.l	fmtune_id_74_cmdstream	;song $74
	dc.l	fmtune_id_75_cmdstream	;song $75
	dc.l	fmtune_id_76_cmdstream	;song $76
	dc.l	fmtune_id_77_cmdstream	;song $77
	dc.l	fmtune_title_cmdstream	;song $78
	dc.l	fmtune_eog_cmdstream	;song $79
	dc.l	fmtune_scouting_cmdstream	;song $7A
sfx_beep1_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_beep1_cmdstream.bin	;sound $1 (SFXbeep1)
	even
sfx_id_26_27_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_id_26_27_cmdstream.bin	;sound $26, sound $27
	even
sfx_beep2_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_beep2_cmdstream.bin	;sound $2 (SFXbeep2)
	even
sfx_horn_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_horn_cmdstream.bin	;sound $4 (92 SFXhorn)
	even
sfx_stdef_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_stdef_cmdstream.bin	;sound $6 (92 SFXstdef)
	even
sfx_puckget_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckget_cmdstream.bin	;sound $7 (92 SFXpuckget)
	even
sfx_puckice1_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckice1_cmdstream.bin	;sound $2C (92 SFXpuckice)
	even
sfx_puckice2_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckice2_cmdstream.bin	;sound $2D
	even
sfx_puckice3_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckice3_cmdstream.bin	;sound $2E
	even
sfx_puckice4_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckice4_cmdstream.bin	;sound $2F
	even
sfx_puckbody_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckbody_cmdstream.bin	;sound $24 (92 SFXpuckbody)
	even
sfx_oooh_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_oooh_cmdstream.bin	;sound $8 (92 SFXoooh)
	even
sfx_puckpost_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckpost_cmdstream.bin	;sound $25 (92 SFXpuckpost)
	even
sfx_playerwall_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_playerwall_cmdstream.bin	;sound $20 (92 SFXplayerwall)
	even
sfx_id_21_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_id_21_cmdstream.bin	;sound $21
	even
sfx_id_22_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_id_22_cmdstream.bin	;sound $22
	even
sfx_id_23_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_id_23_cmdstream.bin	;sound $23
	even
sfx_puckwall1_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckwall1_cmdstream.bin	;sound $28
	even
sfx_puckwall2_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckwall2_cmdstream.bin	;sound $29
	even
sfx_puckwall3_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckwall3_cmdstream.bin	;sound $2A
	even
sfx_puckwall4_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_puckwall4_cmdstream.bin	;sound $2B
	even
sfx_whistle_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_whistle_cmdstream.bin	;sound $3 (92 SFXwhistle)
	even
	dc.b	$FF,$FF			;pad: retail leftover bytes (93 has none here)
sfx_shotwiff_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotwiff_cmdstream.bin	;sound $5 (92 SFXshotwiff)
	even
sfx_check1_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_check1_cmdstream.bin	;sound $1C (92 SFXcheck)
	even
sfx_check2_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_check2_cmdstream.bin	;sound $1D
	even
sfx_check3_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_check3_cmdstream.bin	;sound $1E
	even
sfx_check4_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_check4_cmdstream.bin	;sound $1F
	even
sfx_pass1_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_pass1_cmdstream.bin	;sound $10 (92 SFXpass)
	even
sfx_pass2_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_pass2_cmdstream.bin	;sound $11
	even
sfx_pass3_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_pass3_cmdstream.bin	;sound $12
	even
sfx_pass4_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_pass4_cmdstream.bin	;sound $13
	even
sfx_shotbh1_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotbh1_cmdstream.bin	;sound $14 (92 SFXshotbh)
	even
sfx_shotbh2_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotbh2_cmdstream.bin	;sound $15
	even
sfx_shotbh3_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotbh3_cmdstream.bin	;sound $16
	even
sfx_shotbh4_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotbh4_cmdstream.bin	;sound $17
	even
sfx_shotfh1_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotfh1_cmdstream.bin	;sound $18 (92 SFXshotfh)
	even
sfx_shotfh2_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotfh2_cmdstream.bin	;sound $19
	even
sfx_shotfh3_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotfh3_cmdstream.bin	;sound $1A
	even
sfx_shotfh4_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_shotfh4_cmdstream.bin	;sound $1B
	even
sfx_hithigh_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_hithigh_cmdstream.bin	;sound $9 (SFXhithigh)
	even
sfx_hitlow_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_hitlow_cmdstream.bin	;sound $A (SFXhitlow)
	even
sfx_homewin_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_homewin_cmdstream.bin	;sound $F
	even
sfx_crowdcheer_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_crowdcheer_cmdstream.bin	;sound $B (SFXcrowdcheer)
	even
sfx_crowdboo_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_crowdboo_cmdstream.bin	;sound $C (SFXcrowdboo)
	even
sfx_id_0E_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_id_0E_cmdstream.bin	;sound $E
	even
sfx_id_0D_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_id_0D_cmdstream.bin	;sound $D
	even
sfx_siren_cmdstream
	incbin	..\Extracted\NHL94\Sound\sfx_siren_cmdstream.bin	;sound $0 (92 SFXsiren)
	even
fmtune_id_30_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_30_cmdstream.bin	;song $30: ChooseSong, TeamSongs BOS
	even
fmtune_id_31_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_31_cmdstream.bin	;song $31: ChooseSong, TeamSongs BOS
	even
fmtune_id_32_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_32_cmdstream.bin	;song $32: ChooseSong, TeamSongs BOS
	even
fmtune_id_33_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_33_cmdstream.bin	;song $33: ChooseSong, TeamSongs BUF
	even
fmtune_id_34_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_34_cmdstream.bin	;song $34: ChooseSong, TeamSongs BUF, RandomSongs
	even
fmtune_id_35_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_35_cmdstream.bin	;song $35: ChooseSong, TeamSongs CGY
	even
fmtune_id_36_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_36_cmdstream.bin	;song $36: ChooseSong, TeamSongs CGY
	even
fmtune_id_37_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_37_cmdstream.bin	;song $37: ChooseSong, TeamSongs CGY
	even
fmtune_id_38_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_38_cmdstream.bin	;song $38: ChooseSong, TeamSongs CHI
	even
fmtune_id_39_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_39_cmdstream.bin	;song $39: ChooseSong, TeamSongs CHI
	even
fmtune_id_3A_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_3A_cmdstream.bin	;song $3A: ChooseSong, TeamSongs CHI
	even
fmtune_id_3B_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_3B_cmdstream.bin	;song $3B: ChooseSong, TeamSongs DET
	even
fmtune_id_3C_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_3C_cmdstream.bin	;song $3C: ChooseSong, TeamSongs DET
	even
fmtune_id_3D_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_3D_cmdstream.bin	;song $3D: ChooseSong, TeamSongs DET
	even
fmtune_id_3E_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_3E_cmdstream.bin	;song $3E: ChooseSong, TeamSongs EDM
	even
fmtune_id_3F_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_3F_cmdstream.bin	;song $3F: ChooseSong, TeamSongs EDM
	even
fmtune_id_40_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_40_cmdstream.bin	;song $40: ChooseSong, TeamSongs HFD, RandomSongs
	even
fmtune_id_41_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_41_cmdstream.bin	;song $41: ChooseSong, TeamSongs HFD
	even
fmtune_id_42_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_42_cmdstream.bin	;song $42: ChooseSong, TeamSongs HFD, RandomSongs
	even
fmtune_id_43_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_43_cmdstream.bin	;song $43: ChooseSong, TeamSongs LA
	even
fmtune_id_44_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_44_cmdstream.bin	;song $44: ChooseSong, TeamSongs LA
	even
fmtune_id_45_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_45_cmdstream.bin	;song $45: ChooseSong, TeamSongs LA
	even
fmtune_id_46_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_46_cmdstream.bin	;song $46: ChooseSong, TeamSongs LA
	even
fmtune_id_47_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_47_cmdstream.bin	;song $47: ChooseSong, TeamSongs NYI
	even
fmtune_id_48_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_48_cmdstream.bin	;song $48: ChooseSong, TeamSongs NYI
	even
fmtune_id_49_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_49_cmdstream.bin	;song $49: ChooseSong, TeamSongs NYI, RandomSongs
	even
fmtune_id_4A_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_4A_cmdstream.bin	;song $4A: ChooseSong, TeamSongs DAL
	even
fmtune_id_4B_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_4B_cmdstream.bin	;song $4B: ChooseSong, TeamSongs DAL
	even
fmtune_id_4C_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_4C_cmdstream.bin	;song $4C: ChooseSong, TeamSongs MTL
	even
fmtune_id_4D_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_4D_cmdstream.bin	;song $4D: ChooseSong, TeamSongs MTL
	even
fmtune_id_4E_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_4E_cmdstream.bin	;song $4E: ChooseSong, TeamSongs MTL
	even
fmtune_id_4F_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_4F_cmdstream.bin	;song $4F: ChooseSong, TeamSongs MTL
	even
fmtune_id_50_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_50_cmdstream.bin	;song $50: ChooseSong, TeamSongs NJ
	even
fmtune_id_51_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_51_cmdstream.bin	;song $51: ChooseSong, TeamSongs NJ
	even
fmtune_id_52_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_52_cmdstream.bin	;song $52: ChooseSong, TeamSongs NJ
	even
fmtune_id_53_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_53_cmdstream.bin	;song $53: ChooseSong, TeamSongs NYR / ASE / ASW
	even
fmtune_id_54_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_54_cmdstream.bin	;song $54: ChooseSong, TeamSongs NYR / ASE / ASW
	even
fmtune_id_55_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_55_cmdstream.bin	;song $55: ChooseSong, TeamSongs NYR / ASE / ASW
	even
fmtune_id_56_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_56_cmdstream.bin	;song $56: ChooseSong, TeamSongs PHI
	even
fmtune_id_57_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_57_cmdstream.bin	;song $57: ChooseSong, TeamSongs PHI
	even
fmtune_id_58_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_58_cmdstream.bin	;song $58: ChooseSong, TeamSongs PHI, RandomSongs
	even
fmtune_id_59_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_59_cmdstream.bin	;song $59: ChooseSong, TeamSongs PIT
	even
fmtune_id_5A_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_5A_cmdstream.bin	;song $5A: ChooseSong, TeamSongs (25 teams: all but CGY, PHI and SJ)
	even
fmtune_id_5B_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_5B_cmdstream.bin	;song $5B: ChooseSong, TeamSongs PIT
	even
fmtune_id_5C_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_5C_cmdstream.bin	;song $5C: ChooseSong, TeamSongs PIT, RandomSongs
	even
fmtune_id_5D_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_5D_cmdstream.bin	;song $5D: ChooseSong, TeamSongs QUE
	even
fmtune_id_5E_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_5E_cmdstream.bin	;song $5E: ChooseSong, TeamSongs QUE
	even
fmtune_id_5F_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_5F_cmdstream.bin	;song $5F: ChooseSong, TeamSongs SJ
	even
fmtune_id_60_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_60_cmdstream.bin	;song $60: ChooseSong, TeamSongs SJ
	even
fmtune_id_61_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_61_cmdstream.bin	;song $61: ChooseSong, TeamSongs SJ
	even
fmtune_id_62_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_62_cmdstream.bin	;song $62: ChooseSong, not in TeamSongs or RandomSongs
	even
fmtune_id_63_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_63_cmdstream.bin	;song $63: ChooseSong, TeamSongs SJ
	even
fmtune_id_64_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_64_cmdstream.bin	;song $64: ChooseSong, TeamSongs SJ
	even
fmtune_id_65_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_65_cmdstream.bin	;song $65: ChooseSong, TeamSongs CHI / SJ, RandomSongs
	even
fmtune_id_66_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_66_cmdstream.bin	;song $66: ChooseSong, RandomSongs
	even
fmtune_id_67_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_67_cmdstream.bin	;song $67: ChooseSong, TeamSongs STL
	even
fmtune_id_68_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_68_cmdstream.bin	;song $68: ChooseSong, TeamSongs STL
	even
fmtune_id_69_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_69_cmdstream.bin	;song $69: ChooseSong, TeamSongs STL
	even
fmtune_id_6A_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_6A_cmdstream.bin	;song $6A: ChooseSong, TeamSongs TB
	even
fmtune_id_6B_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_6B_cmdstream.bin	;song $6B: ChooseSong, TeamSongs TB
	even
fmtune_id_6C_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_6C_cmdstream.bin	;song $6C: ChooseSong, TeamSongs TOR
	even
fmtune_id_6D_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_6D_cmdstream.bin	;song $6D: ChooseSong, TeamSongs TOR
	even
fmtune_id_6E_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_6E_cmdstream.bin	;song $6E: ChooseSong, TeamSongs VAN
	even
fmtune_id_6F_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_6F_cmdstream.bin	;song $6F: ChooseSong, TeamSongs VAN
	even
fmtune_id_70_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_70_cmdstream.bin	;song $70: ChooseSong, TeamSongs VAN
	even
fmtune_id_71_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_71_cmdstream.bin	;song $71: ChooseSong, TeamSongs WSH
	even
fmtune_id_72_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_72_cmdstream.bin	;song $72: ChooseSong, not in TeamSongs or RandomSongs
	even
fmtune_id_73_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_73_cmdstream.bin	;song $73: ChooseSong, TeamSongs WSH
	even
fmtune_id_74_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_74_cmdstream.bin	;song $74: ChooseSong, TeamSongs WSH
	even
fmtune_id_75_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_75_cmdstream.bin	;song $75: ChooseSong, TeamSongs ANH / FLA / OTW / WPG
	even
fmtune_id_76_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_76_cmdstream.bin	;song $76: ChooseSong, TeamSongs ANH / FLA / OTW / WPG
	even
fmtune_id_77_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_id_77_cmdstream.bin	;song $77: ChooseSong, TeamSongs ANH / FLA / OTW / WPG
	even
fmtune_title_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_title_cmdstream94.bin	;song $78 (93 $35): ExitToOpening, newTitleScreen. 94: one stream that loops to its start (93: intro, loop body)
	even
	dc.l	fmtune_title_cmdstream	;loop pointer
fmtune_eog_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_eog_cmdstream94.bin	;song $79 (93 $36): IntermissionStart, StartHL2 (differs from 93)
	even
	dc.l	fmtune_eog_cmdstream+4	;loop pointer (past the first event)
fmtune_scouting_cmdstream
	incbin	..\Extracted\NHL94\Sound\fmtune_scouting_cmdstream94.bin	;song $7A (93 $37): ScoutingReport (differs from 93)
	even
	dc.l	fmtune_scouting_cmdstream+4	;loop pointer (past the first event)
