; $01A050  Adapted from sram93.asm: save data
;	NHL 94 (retail) segment $1A050-$1A263
;	94 only (93 sram93 drives a serial EEPROM): the battery save RAM. 94 keeps $2000 bytes on the odd bytes at $200000, copies
;	them to M68K_RAM at power on (InitSaveRAM) and protects them with a sum / complement checksum in bytes $1FFE-$1FFF.
;	InitSaveRAM, VBcount, ValidateSRAM, ClearSRAM, WriteSRAM, MakeSRAMChecksum, ReadSRAM; p_turnoff (sound94) follows at $1A264.
;Transcribed from lst/nhl94.bin.lst lines 61322-61528. Global names are the locals are the names
;(_x ->.x) or the 93 local where the code matches, else in the 93 style (.x exit,.loop, numbered), with the unless generic, in an ;No
;	EA's compiler emits cmp #imm,Dn as CMP (Bxxx), SNASM emits CMPI (0Cxx). The source has the real cmp;
;	fixopcodes.js patches the cmp encoding after assembly.

InitSaveRAM	;Called from Begin. Copy the $2000 byte save RAM (the odd bytes at $200000) to M68K_RAM and check its checksum
	;(ValidateSRAM; ValidSRAM 0 = good, -1 = bad). A bad save RAM is cleared (ClearSRAM) and read again. Two power-on tests that never return:
	;Start+A+C held writes and reads back every bit of every byte, writes $12,$34,$56,$78 to bytes 0-3 and flashes the screen green, or red at the
	;first bad byte; Start+B+C held flashes green if bytes 0-3 are $12345678, else red
	move.l	#VBcount,(vbint).l
	move	#$2500,sr
	clr.w	(ValidSRAM).w	;good until checked
	jsr	(ReadJoy1).l	;get joypad buttons held
	move.w	d3,d0	;d3 = buttons held
	movea.l	#$200000,a0	;move SRAM address into a0
	move.w	#$E,d3	;red ($00E), fading by 2 a frame
	move.w	#2,d4	;move 2 into d4
	cmp.b	#$E0,d0	;Start+A+C button held down
	beq.w	.setiterator	;branch if held down
	cmp.b	#$B0,d0	;Start+B+C buttons held down
	beq.w	.setiterator2	;branch if held down
	moveq	#0,d0	;move 0 into d0
	move.l	#$2000,d1	;$2000 into d1
	movea.l	#M68K_RAM,a0	;start of RAM into a0
	bsr.w	ReadSRAM	;Writes SRAM to RAM
	bsr.w	ValidateSRAM
	tst.w	(ValidSRAM).w
	bpl.w	.ex
	bsr.w	ClearSRAM
	moveq	#0,d0
	move.l	#$2000,d1
	movea.l	#M68K_RAM,a0
	bsr.w	ReadSRAM	;Writes SRAM to RAM
	bsr.w	ValidateSRAM
.ex
	rts
.setiterator
	move.w	#$1FFF,d2	;$2000 bytes
.SRAMloop
	move.w	#1,d1	;bit 0, then up to bit 7
	move.w	#7,d0
.setto80
	move.w	d1,(a0)
	cmp.b	1(a0),d1
	bne.w	.loadcolor
	lsl.w	#1,d1
	dbf	d0,.setto80
	adda.w	#2,a0
	dbf	d2,.SRAMloop
	movea.l	#$200000,a0
	move.l	#$120034,(a0)+	;bytes 0-3 = $12,$34,$56,$78 (word writes: the low byte goes to the odd SRAM byte)
	move.l	#$560078,(a0)+
	move.w	#$E0,d3	;green ($0E0), fading by $20 a frame
	move.w	#$20,d4
.loadcolor
	move.w	d3,d0	;move d3 (color of flashing screen) to d0
.flashscreen
	move.l	#CRAM_W,(VDP_CTRL).l	;cram write 0: the background colour
	move.w	d0,d1
	and.w	d3,d1
	move.w	d1,(VDP_DATA).l
	bsr.w	SRAMWaitVblank	;wait a vblank
	sub.w	d4,d0
	bra.s	.flashscreen
.setiterator2
	move.w	#3,d1
.SRAMloop2
	adda.w	#1,a0	;odd byte
	lsl.l	#8,d0
	move.b	(a0)+,d0
	dbf	d1,.SRAMloop2
	cmp.l	#$12345678,d0
	bne.s	.loadcolor	;branch if not equal (screen flashes red)
	move.w	#$E0,d3	;green
	move.w	#$20,d4
	bra.s	.loadcolor	;branch (screen flashes green)
SRAMWaitVblank	;94 only. Wait for the next vblank (vcountwait, 93 MenuWaitVblank). Called from InitSaveRAM
	jsr	(vcountwait).l
	rts
VBcount	;vbint handler while InitSaveRAM runs: vcount + 1 only
	addq.w	#1,(vcount).w	;vblank with counter only
	rte
ValidateSRAM	;Check the save RAM copy in M68K_RAM: byte $1FFF must be the sum of bytes 0-$1FFD, byte $1FFE its complement. ValidSRAM = 0 if they match, -1 if not. Called from InitSaveRAM
	move.w	#$1FFD,d1	;set iterator to  $1FFD
	clr.w	d0	;clear d0
	lea	(M68K_RAM).l,a0	;set a0 to start of RAM
.loop
	add.b	(a0)+,d0	;add value at a0 to d0 and increment a0
	dbf	d1,.loop	;loop through RAM d1 times
	clr.w	d1	;clear d1
	cmp.b	1(a0),d0	;compare data at 1+a0 ($1FFF RAM address) to d0
	beq.w	.0	;branch if equal
	addq.w	#1,d1	;add 1 to d1
.0
	not.w	d0	;toggle bits in d0 from 1->0 and vice-versa
	cmp.b	(a0),d0	;compare byte at a0 ($1FFE) with d0
	beq.w	.1	;branch if equal
	addq.w	#1,d1	;add 1 to d1 if not
.1
	swap	d0	;swap d0 word size
	move.b	(a0),d0	;move data at a0 into d0
	not.b	d0	;toggle bits
	cmp.b	1(a0),d0	;compare data a0+1 with d0
	beq.w	.2	;branch if equal
	addq.w	#1,d1	;add 1 to d1 if not
.2
	swap	d0	;swap d0 word size
	tst.w	d1	;test d1
	bne.w	.3	;branch if d1 not 0
	clr.w	(ValidSRAM).w	;clear
	bra.w	.x	;branch to exit
.3
	st	(ValidSRAM).w	;set
.x
	rts
ClearSRAM	;Clears first $2000 of RAM and SaveRAM: zero M68K_RAM $0-$1FFF with byte $1FFE = $FF (the checksum of zeros), write it to
	;the save RAM, set byte 1 to 1, then MakeSRAMChecksum. Called from InitSaveRAM
	lea	(M68K_RAM).l,a0
	move.w	#$1FFF,d0
	clr.l	d1
.loop
	move.b	d1,(a0)+
	dbf	d0,.loop
	move.b	#$FF,(sramcleared).l
	moveq	#0,d0
	move.l	#$2000,d1
	movea.l	#M68K_RAM,a0
	bsr.w	WriteSRAM
	moveq	#1,d0
	moveq	#1,d1
	move.b	#1,(M68K_RAM).l	;byte 0 of the RAM copy is written to save RAM byte 1
	movea.l	#M68K_RAM,a0
	bsr.w	WriteSRAM
	bsr.w	MakeSRAMChecksum
	rts
WriteSRAM	;Write data from a0 into SaveRAM: d1 = number of bytes, d0 = first save RAM byte (each byte is the odd byte of a word at
	;$200000 + d0 * 2). Called from ClearSRAM, MakeSRAMChecksum and the save code (clrCrowdRAM ...)
	movem.l	d0-d2/a0-a1,-(sp)
	movea.l	#$200000,a1
	add.l	d0,d0
	subq.l	#1,d1
	clr.w	d2
.loop
	move.b	(a0)+,d2
	move.w	d2,0(a1,d0.w)
	addq.w	#2,d0
	dbf	d1,.loop
	movem.l	(sp)+,d0-d2/a0-a1
	rts
MakeSRAMChecksum	;Read the whole save RAM to M68K_RAM, put the sum of bytes 0-$1FFD in byte $1FFF and its complement in byte $1FFE
	;and write those two bytes back. Called from ClearSRAM and the save code (UpdateRecords ...)
	lea	(M68K_RAM).l,a0
	move.l	#$2000,d1
	clr.l	d0
	bsr.w	ReadSRAM
	lea	(M68K_RAM).l,a0
	clr.w	d0
	move.w	#$1FFD,d1
.loop
	add.b	(a0)+,d0
	dbf	d1,.loop
	move.b	d0,1(a0)
	not.w	d0
	move.b	d0,(a0)
	movea.l	#sramcleared,a0
	moveq	#2,d1
	move.l	#$1FFE,d0
	bsr.s	WriteSRAM
	rts
ReadSRAM	;move into a0 location and increment: copy d1 save RAM bytes from byte d0 (the odd bytes at $200000 + d0 * 2) to (a0)+. Called from InitSaveRAM, MakeSRAMChecksum and the save code
	movem.l	d0-d2/a0-a1,-(sp)
	movea.l	#$200000,a1
	add.l	d0,d0
	subq.l	#1,d1
.loop
	move.b	1(a1,d0.w),d2
	move.b	d2,(a0)+
	addq.w	#2,d0
	dbf	d1,.loop
	movem.l	(sp)+,d0-d2/a0-a1
	rts
