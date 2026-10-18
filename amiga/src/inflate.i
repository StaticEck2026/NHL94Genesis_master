;	Inflate (RFC 1951, raw deflate data) for the launcher: 68000 code.
;	inflate: a0 = the compressed data, a1 = where the output goes; returns a1 = the end of the
;	output. Keeps d0-d7/a2-a6. The caller provides IF_SIZE bytes at ifwork (no alignment needed
;	beyond even). The data may be read up to 2 bytes past its end.
;	Codes of up to 9 bits are decoded through a table, longer ones a bit at a time.

TB_COUNT	equ	0				;codes per length (words, 16)
TB_SYM		equ	32				;symbols by code (words, 288)
TB_FAST		equ	32+576				;the next 9 bits -> symbol | length << 9 (512)
TB_SIZE		equ	TB_FAST+1024

IF_OFFS		equ	0				;(table building: words, 16)
IF_LENS		equ	32				;code lengths (bytes, 320)
IF_LTAB		equ	IF_LENS+320			;literal / length codes
IF_DTAB		equ	IF_LTAB+TB_SIZE			;distance codes (also the code length codes)
IF_SIZE		equ	IF_DTAB+TB_SIZE

inflate
	movem.l	d0-d7/a2-a6,-(sp)
	lea	(ifwork).l,a5
	moveq	#0,d7				;bit buffer (the next bit is bit 0)
	moveq	#0,d6				;bits in it
.block	moveq	#1,d0
	bsr	if_bits
	move.w	d1,-(sp)			;last block
	moveq	#2,d0
	bsr	if_bits
	tst.w	d1
	beq	.stored
	subq.w	#1,d1
	beq	.fixed
	subq.w	#1,d1
	beq	.dynamic
	addq.l	#2,sp				;(type 3: not deflate data)
	bra	.x
.next	tst.w	(sp)+
	beq.s	.block
.x	movem.l	(sp)+,d0-d7/a2-a6
	rts

.stored	; whole bytes in the bit buffer go back; then the length, its complement, the bytes
	move.w	d6,d0
	lsr.w	#3,d0
	suba.w	d0,a0
	moveq	#0,d7
	moveq	#0,d6
	moveq	#0,d0
	move.b	1(a0),d0
	lsl.w	#8,d0
	move.b	(a0),d0
	addq.l	#4,a0
	bra.s	.sc
.sl	move.b	(a0)+,(a1)+
.sc	dbf	d0,.sl
	bra.s	.next

.fixed	lea	IF_LENS(a5),a3
	movea.l	a3,a4
	move.w	#144-1,d0
.f8	move.b	#8,(a4)+
	dbf	d0,.f8
	moveq	#112-1,d0
.f9	move.b	#9,(a4)+
	dbf	d0,.f9
	moveq	#24-1,d0
.f7	move.b	#7,(a4)+
	dbf	d0,.f7
	moveq	#8-1,d0
.f8b	move.b	#8,(a4)+
	dbf	d0,.f8b
	moveq	#30-1,d0
.f5	move.b	#5,(a4)+
	dbf	d0,.f5
	lea	IF_LTAB(a5),a2
	move.w	#288,d0
	bsr	if_build
	lea	IF_LENS+288(a5),a3
	lea	IF_DTAB(a5),a2
	moveq	#30,d0
	bsr	if_build
	bra	.codes

.dynamic
	moveq	#5,d0
	bsr	if_bits
	addi.w	#257,d1
	move.w	d1,d3				;literal / length codes
	moveq	#5,d0
	bsr	if_bits
	addq.w	#1,d1
	move.w	d1,d4				;distance codes
	moveq	#4,d0
	bsr	if_bits
	addq.w	#4,d1
	move.w	d1,d5				;code length codes
	lea	IF_LENS(a5),a3
	moveq	#19-1,d0
.cz	clr.b	(a3)+
	dbf	d0,.cz
	lea	IF_LENS(a5),a3
	lea	(.order,pc),a4
	bra.s	.cle
.cl	moveq	#3,d0
	bsr	if_bits
	moveq	#0,d2
	move.b	(a4)+,d2
	move.b	d1,(a3,d2.w)
.cle	dbf	d5,.cl
	movem.w	d3-d4,-(sp)
	lea	IF_DTAB(a5),a2
	moveq	#19,d0
	bsr	if_build
	; the code lengths of both alphabets, one run after the other
	movem.w	(sp),d3-d4
	lea	IF_LENS(a5),a4
	lea	(a4,d3.w),a6
	adda.w	d4,a6				;their end
.ln	cmpa.l	a6,a4
	bhs.s	.lnd
	lea	IF_DTAB(a5),a2
	bsr	if_decode
	cmpi.w	#16,d1
	bhs.s	.rep
	move.b	d1,(a4)+
	bra.s	.ln
.rep	bne.s	.zeros
	moveq	#2,d0				;16: the last length 3-6 times
	bsr	if_bits
	addq.w	#3-1,d1
	move.b	-1(a4),d2
.r16	move.b	d2,(a4)+
	dbf	d1,.r16
	bra.s	.ln
.zeros	cmpi.w	#17,d1
	bne.s	.z18
	moveq	#3,d0				;17: 3-10 zeros
	bsr	if_bits
	addq.w	#3-1,d1
	bra.s	.z
.z18	moveq	#7,d0				;18: 11-138 zeros
	bsr	if_bits
	addi.w	#11-1,d1
.z	clr.b	(a4)+
	dbf	d1,.z
	bra.s	.ln
.lnd	movem.w	(sp),d3-d4
	lea	IF_LENS(a5),a3
	lea	IF_LTAB(a5),a2
	move.w	d3,d0
	bsr	if_build
	movem.w	(sp)+,d3-d4
	lea	IF_LENS(a5),a3
	adda.w	d3,a3
	lea	IF_DTAB(a5),a2
	move.w	d4,d0
	bsr	if_build

.codes	lea	IF_LTAB(a5),a2
	bsr	if_decode
	cmpi.w	#256,d1
	blo.s	.lit
	beq	.next
	subi.w	#257,d1				;length
	lea	(.lext,pc),a4
	moveq	#0,d0
	move.b	(a4,d1.w),d0
	add.w	d1,d1
	lea	(.lbase,pc),a4
	move.w	(a4,d1.w),d3
	bsr	if_bits
	add.w	d1,d3
	move.w	d3,-(sp)
	lea	IF_DTAB(a5),a2			;distance
	bsr	if_decode
	lea	(.dext,pc),a4
	moveq	#0,d0
	move.b	(a4,d1.w),d0
	add.w	d1,d1
	lea	(.dbase,pc),a4
	moveq	#0,d3
	move.w	(a4,d1.w),d3
	bsr	if_bits
	add.l	d1,d3
	movea.l	a1,a2
	suba.l	d3,a2
	move.w	(sp)+,d0
	subq.w	#1,d0
.cp	move.b	(a2)+,(a1)+
	dbf	d0,.cp
	bra.s	.codes
.lit	move.b	d1,(a1)+
	bra.s	.codes

.order	dc.b	16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15
.lext	dc.b	0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0
.dext	dc.b	0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13
	even
.lbase	dc.w	3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258
.dbase	dc.w	1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073
	dc.w	4097,6145,8193,12289,16385,24577

;	d1 = the next d0 bits (0-16). Uses d2.
if_bits
	cmp.w	d0,d6
	bge.s	.ok
.fill	moveq	#0,d2
	move.b	(a0)+,d2
	lsl.l	d6,d2
	or.l	d2,d7
	addq.w	#8,d6
	cmp.w	d0,d6
	blt.s	.fill
.ok	moveq	#1,d1
	lsl.l	d0,d1
	subq.l	#1,d1
	and.l	d7,d1
	lsr.l	d0,d7
	sub.w	d0,d6
	rts

;	d1 = the next symbol of the code a2. Uses d0-d5/a3.
if_decode
	moveq	#9,d0
	cmp.w	d0,d6
	bge.s	.ok
.fill	moveq	#0,d2
	move.b	(a0)+,d2
	lsl.l	d6,d2
	or.l	d2,d7
	addq.w	#8,d6
	cmp.w	d0,d6
	blt.s	.fill
.ok	move.w	d7,d2
	andi.w	#511,d2
	add.w	d2,d2
	lea	TB_FAST(a2),a3
	move.w	(a3,d2.w),d1
	beq.s	.slow
	move.w	d1,d0
	lsr.w	#8,d0
	lsr.w	#1,d0				;length
	lsr.l	d0,d7
	sub.w	d0,d6
	andi.w	#511,d1
	rts
.slow	; canonical codes a bit at a time: the code so far, the first code and the first symbol
	; of this length
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#1,d0
.bit	tst.w	d6
	bne.s	.have
	moveq	#0,d7
	move.b	(a0)+,d7
	moveq	#8,d6
.have	moveq	#1,d2
	and.l	d7,d2
	lsr.l	#1,d7
	subq.w	#1,d6
	or.w	d2,d3
	move.w	d0,d2
	add.w	d2,d2
	move.w	TB_COUNT(a2,d2.w),d2
	move.w	d3,d1
	sub.w	d4,d1
	cmp.w	d2,d1
	blo.s	.found
	add.w	d2,d5
	add.w	d2,d4
	add.w	d4,d4
	add.w	d3,d3
	addq.w	#1,d0
	cmpi.w	#16,d0
	blt.s	.bit
	move.w	#256,d1				;(not a code: end the block)
	rts
.found	add.w	d5,d1
	add.w	d1,d1
	move.w	TB_SYM(a2,d1.w),d1
	rts

;	Build the code table a2 from the d0 code lengths at a3. Uses d0-d5/a4.
if_build
	movem.l	d6-d7,-(sp)
	movea.l	a2,a4
	moveq	#15,d1
.cz	clr.w	(a4)+
	dbf	d1,.cz
	moveq	#0,d1
.cc	moveq	#0,d2
	move.b	(a3,d1.w),d2
	add.w	d2,d2
	addq.w	#1,TB_COUNT(a2,d2.w)
	addq.w	#1,d1
	cmp.w	d0,d1
	blt.s	.cc
	clr.w	TB_COUNT(a2)			;(length 0: no code)
	; symbols sorted by length, then by value
	moveq	#0,d2
	moveq	#2,d1				;(length 1, as a word offset)
.of	move.w	d2,IF_OFFS(a5,d1.w)
	add.w	TB_COUNT(a2,d1.w),d2
	addq.w	#2,d1
	cmpi.w	#32,d1
	blt.s	.of
	moveq	#0,d1
.sy	moveq	#0,d2
	move.b	(a3,d1.w),d2
	beq.s	.sn
	add.w	d2,d2
	move.w	IF_OFFS(a5,d2.w),d3
	addq.w	#1,IF_OFFS(a5,d2.w)
	add.w	d3,d3
	move.w	d1,TB_SYM(a2,d3.w)
.sn	addq.w	#1,d1
	cmp.w	d0,d1
	blt.s	.sy
	; codes of up to 9 bits in the fast table, at each index that ends in the code's bits
	; (reversed: the first bit is bit 0)
	lea	TB_FAST(a2),a4
	move.w	#511,d1
.fz	clr.w	(a4)+
	dbf	d1,.fz
	lea	TB_FAST(a2),a4
	moveq	#0,d3				;code
	moveq	#0,d4				;symbol index
	moveq	#1,d1				;length
.len	move.w	d1,d2
	add.w	d2,d2
	move.w	TB_COUNT(a2,d2.w),d5
	bra.s	.ke
.k	cmpi.w	#9,d1
	bhi.s	.kn
	move.w	d3,d0
	moveq	#0,d2
	move.w	d1,d6
	subq.w	#1,d6
.rev	lsr.w	#1,d0
	roxl.w	#1,d2
	dbf	d6,.rev
	move.w	d1,d7
	lsl.w	#8,d7
	add.w	d7,d7				;length << 9
	move.w	d4,d0
	add.w	d0,d0
	or.w	TB_SYM(a2,d0.w),d7
	moveq	#1,d0
	lsl.w	d1,d0				;step
.fill	move.w	d2,d6
	add.w	d6,d6
	move.w	d7,(a4,d6.w)
	add.w	d0,d2
	cmpi.w	#512,d2
	blt.s	.fill
.kn	addq.w	#1,d3
	addq.w	#1,d4
.ke	dbf	d5,.k
	add.w	d3,d3
	addq.w	#1,d1
	cmpi.w	#16,d1
	blt.s	.len
	movem.l	(sp)+,d6-d7
	rts
