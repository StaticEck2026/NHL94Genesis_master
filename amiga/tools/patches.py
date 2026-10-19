"""Per-site rewrites for the Amiga build (used by convert.py).

pre() runs on the original text of each file, before the generic rules; post() runs on the
converted text. Every replacement names the exact text it expects and how many times it must
occur, so a change to src/ that moves or rewrites a patched site stops the build instead of
being silently skipped.
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
AMIGA_SRC = os.path.join(HERE, '..', 'src')

_used = set()
PRE = {}
POST = {}


def rule(table, rel, old, new, count=1, regex=False):
    table.setdefault(rel, []).append((old, new, count, regex))


def _apply(table, rel, text):
    for i, (old, new, count, regex) in enumerate(table.get(rel, [])):
        if regex:
            text, n = re.subn(old, new, text, flags=re.M)
        else:
            n = text.count(old)
            text = text.replace(old, new)
        if count is not None and n != count:
            raise SystemExit('patch %s #%d: expected %d matches of %r, found %d' % (rel, i, count, old, n))
        _used.add((id(table), rel, i))
    return text


def pre(rel, text):
    return _apply(PRE, rel, text)


def post(rel, text):
    return _apply(POST, rel, text)


def finish():
    for table in (PRE, POST):
        for rel, lst in table.items():
            for i in range(len(lst)):
                if (id(table), rel, i) not in _used:
                    raise SystemExit('patch for %s #%d never applied (file missing?)' % (rel, i))


def P(rel, old, new, count=1, regex=False):
    rule(PRE, rel, old, new, count, regex)


def Q(rel, old, new, count=1, regex=False):
    rule(POST, rel, old, new, count, regex)


j = os.path.join

# ---------------------------------------------------------------------------------------------
# RAM: $FFFFxxxx -> RAMBASE+$xxxx
P(j('stubinc', 'ram_addrs.inc'), r'\$FFFF([0-9A-Fa-f]{4})\b', r'RAMBASE+$\1', None, regex=True)
P(j('stubinc', 'equals.inc'), 'replaystart equ $FFFF0000', 'replaystart equ RAMBASE')

# The macro file: vasm versions.
with open(os.path.join(AMIGA_SRC, 'genesis_vasm.mac')) as _fh:
    _MAC = _fh.read()
P(j('macros', 'genesis.mac'), r'\A[\s\S]*\Z', _MAC.replace('\\', '\\\\'), 1, regex=True)

# Hard coded RAM low words compared with cmpa.w are handled by convert.py; the ones below use
# the low word arithmetic that stays correct with a 64K aligned RAMBASE and need no change:
#   video94 WeightedRandomSelect  suba.w #$D036,a1 then move.w a1,d0


def replace_routine(rel, label, body, table=PRE):
    """Replace the lines from 'label' up to the next global label with body."""
    pat = r'^%s\b[^\n]*\n(?:(?![A-Za-z_][\w]*\b)[^\n]*\n)*' % re.escape(label)
    rule(table, rel, pat, label + '\n' + body.rstrip('\n').replace('\\', '\\\\') + '\n', 1, True)


# ---------------------------------------------------------------------------------------------
# Hardware ports. The Z80 bus and reset registers become words in RAM that always read "bus
# granted"; the Z80's 8K RAM becomes a buffer that the Amiga sound code (sound.asm) reads, so
# the 68000 sound driver runs unchanged. The pad ports, the PSG and the SRAM go to the
# hardware layer too.
P(j('stubinc', 'ports.inc'), 'IO_CT1_CTRL equ $A10008', 'IO_CT1_CTRL equ hal_padports+8')
P(j('stubinc', 'ports.inc'), 'IO_CT1_DATA equ $A10002', 'IO_CT1_DATA equ hal_padports+2')
P(j('stubinc', 'ports.inc'), 'IO_CT2_CTRL equ $A1000A', 'IO_CT2_CTRL equ hal_padports+10')
P(j('stubinc', 'ports.inc'), 'IO_CT2_DATA equ $A10004', 'IO_CT2_DATA equ hal_padports+4')
P(j('stubinc', 'ports.inc'), 'IO_Z80BUS equ $A11100', 'IO_Z80BUS equ hal_z80bus')
P(j('stubinc', 'ports.inc'), 'IO_Z80RES equ $A11200', 'IO_Z80RES equ hal_z80res')
P(j('stubinc', 'ports.inc'), 'Asound equ $C00011', 'Asound equ hal_psg')
P(j('stubinc', 'ports.inc'), 'HVcount equ $C00008', '\tIFD\tBENCH\nHVcount equ hal_hv\t\t\t\t;(benchmark builds: a number per game frame)\n'
  '\tELSE\nHVcount equ $DFF006\t\t\t\t;Amiga VHPOSR: beam position\n\tENDC')
P(j('stubinc', 'ram_addrs.inc'), 'Z80_RAM equ $A00000', 'Z80_RAM equ hal_z80ram')

# The Z80 program is never run; its two bytes that hold a bank address cannot be relocated.
P('sound94.asm', 'dc.b	fm_instrument_patches&$FF,((fm_instrument_patches>>8)&$7F)|$80', 'dc.b	0,0')
P('sound94.asm', 'dc.b	$09,$3E,fm_instrument_patches>>15', 'dc.b	$09,$3E,0')

# The menu songs (title, end of period, scouting report: $78-$7A, the last) are off for now: they
# do not sound right yet on Paula. The rink's music and the sound effects play. Build with
# -DMENUMUSIC=1 for them.
P('video94.asm', """song
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	d0
	move.w	$40(sp),d0				;$40 = 16*4
	bmi.w	.none
	jsr	(play_sfx_or_music_track).l""", """song
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	d0
	move.w	$40(sp),d0				;$40 = 16*4
	bmi.w	.none
	IFND	MENUMUSIC
	cmpi.w	#$78,d0					;(the menu songs: off for now)
	bhs.w	.none
	ENDC
	jsr	(play_sfx_or_music_track).l""")

# Pads: the vblank pad reader takes the Amiga pads.
replace_routine('sound94.asm', 'ReadJoyData', '''\tmovem.l\td0-d1/a0-a1,-(sp)
\tjsr\t(hal_readpads).l\t\t;d0 = pad 1, d1 = pad 2 (Genesis bit order, active low)
\tmove.b\td0,(pad4way1).w
\tmove.b\td1,(pad4way2).w
\tmovem.l\t(sp)+,d0-d1/a0-a1
\trts
''')
replace_routine('fourway94.asm', 'Detect4WayPlay', '''\tmove.w\t#0,(FourWayPlay).w\t\t;no 4 way play adaptor on the Amiga
\trts
''')

# Save RAM: the cartridge SRAM ($200000, odd bytes) is a buffer the loader fills from disk.
P('sram94.asm', '#$200000', '#hal_sram', None)

# Video chip DMA and fills: done by the hardware layer on the emulated VDP memories.
replace_routine('video94.asm', 'DoDMA', '\tjmp\t(hal_vdp_dma).l\t\t;d0 = words, d1 = vram address, a0 = source\n')
replace_routine('video94.asm', 'DoDMA_nd2', '\tjmp\t(hal_vdp_copy).l\t\t;vram copy: d0 = bytes, d1 = dest, d2 = source\n')
replace_routine('video94.asm', 'DoFill', '\tjmp\t(hal_vdp_fill).l\t\t;d0 = words, d1 = vram address, d2 = data\n')
replace_routine('video94.asm', 'WaitDMA', '\trts\n')

# The emulated Z80 answers at once: the driver posts a command (Z80 RAM $96 = $D1 command
# buffer, $29 PCM start) and the Amiga sound code takes it before the bus is released.
P('sound94.asm', """	dbf	d0,.copy
	clr.w	(IO_Z80BUS).l""", """	dbf	d0,.copy
	jsr	(snd_z80_cmd).l
	clr.w	(IO_Z80BUS).l""")
P('sound94.asm', """	move.b	#0,$97(a1)
	clr.w	(IO_Z80BUS).l""", """	move.b	#0,$97(a1)
	jsr	(snd_z80_cmd).l
	clr.w	(IO_Z80BUS).l""")
# The Z80 got the PCM start as a 24 bit cartridge address; the Amiga sound code takes all of it.
P('sound94.asm', """	move.l	0(a1,d0.w),d0
""", """	move.l	0(a1,d0.w),d0
	move.l	d0,(snd_pcm_addr).l
""")

# Tile data written through the data port (not by DMA): tell the renderer's tile cache.
P('video94.asm', """	movem.l	d0-d4/a0-a2,-(sp)
	exg	d1,d0
	movea.l	a0,a2""", """	movem.l	d0-d4/a0-a2,-(sp)
	jsr	(hal_vdp_dirty).l		;d0 = words, d1 = vram address
	exg	d1,d0
	movea.l	a0,a2""")
P('video94.asm', """	move.l	#0,(a0)					;playfield 1/2
	move.w	(sp)+,(disflags).w""", """	move.l	#0,(a0)					;playfield 1/2
	jsr	(hal_vdp_dirty_all).l		;all of VRAM was cleared
	move.w	(sp)+,(disflags).w""")

# The animated crowd in the stands (two sprite frames, showcrowd) is left out: in play it is
# about a tenth of the renderer's time. The penalty box players are still drawn. CROWD=1 keeps it.
P('display94.asm', """	move.b	(Crowdframe).w,d0
	bsr.w	.sc
	move.b	(Crowdframe+1).w,d0
	bra.w	.sc
""", """	IFND	CROWD
	rts						;(Amiga: no animated crowd)
	ENDC
	move.b	(Crowdframe).w,d0
	bsr.w	.sc
	move.b	(Crowdframe+1).w,d0
	bra.w	.sc
""")
