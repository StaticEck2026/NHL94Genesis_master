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


def remove_routine(rel, label, table=PRE):
    """Remove 'label' and its lines up to the next global label."""
    pat = r'^%s\b[^\n]*\n(?:(?![A-Za-z_][\w]*\b)[^\n]*\n)*' % re.escape(label)
    rule(table, rel, pat, '', 1, True)


# ---------------------------------------------------------------------------------------------
# Hardware ports. The Amiga has no Z80, PSG or pad ports of the Genesis kind: the code that used
# them is rewritten below, and their addresses are left undefined so that none is missed.
for _port in ('IO_CT1_CTRL equ $A10008', 'IO_CT1_DATA equ $A10002', 'IO_CT2_CTRL equ $A1000A',
              'IO_CT2_DATA equ $A10004', 'IO_Z80BUS equ $A11100', 'IO_Z80RES equ $A11200',
              'Asound equ $C00011'):
    P(j('stubinc', 'ports.inc'), _port, ';%s (not on the Amiga)' % _port.split()[0])
P(j('stubinc', 'ports.inc'), 'HVcount equ $C00008', '\tIFD\tBENCH\nHVcount equ hal_hv\t\t\t\t;(benchmark builds: a number per game frame)\n'
  '\tELSE\nHVcount equ $DFF006\t\t\t\t;Amiga VHPOSR: beam position\n\tENDC')
P(j('stubinc', 'ram_addrs.inc'), 'Z80_RAM equ $A00000', ';Z80_RAM (no Z80 on the Amiga)')

# Native player objects: addframe2 is the renderer's (render.asm hal_addframe2: the same
# results in fewer steps, and the object noted for the renderer to draw as one image).
replace_routine('display94.asm', 'addframe2', '\tjmp\t(hal_addframe2).l\n')

# Sound. The 68000 driver's tracks run as they are; what it handed the Z80 it hands sound.asm,
# which plays it on Paula: the command buffer of key ons and offs, attenuations, frequencies and
# patches (snd_fm_commands), a PCM sound's start (snd_pcm_play), its rate and its volume
# (snd_pcm_rate, snd_pcm_vol). The Z80 program, the bus and reset handshakes and the volume
# tables built in the Z80's RAM are left out.
replace_routine('sound94.asm', 'UploadCommandBufferToZ80', '\tjmp\t(snd_fm_commands).l\t\t;(sound.asm: Paula)\n')
remove_routine('sound94.asm', 'z80_bus_release_delay')
replace_routine('sound94.asm', 'StopPCMChannel', '\tclr.b\t(snd_pcm_rate).l\t\t;(sound.asm: the PCM sound stops)\n\trts\n')
P('sound94.asm', """	move.l	0(a1,d0.w),d0
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
""", """	move.l	0(a1,d0.w),d0
	jsr	(snd_pcm_play).l			;(sound.asm: d0 = the sound's start)
""")
P('sound94.asm', """	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	neg.w	d3
	addq.w	#8,d3
	lsr.w	d3,d2
	move.b	d2,(Z80_RAM+$8E).l
	clr.w	(IO_Z80BUS).l
""", """	neg.w	d3
	addq.w	#8,d3
	lsr.w	d3,d2
	move.b	d2,(snd_pcm_rate).l			;(sound.asm)
""")
P('sound94.asm', """	move.w	#$100,(IO_Z80BUS).l
.loop
	btst	#0,(IO_Z80BUS).l
	bne.s	.loop
	lsr.b	#2,d0
""", """	lsr.b	#2,d0
""")
P('sound94.asm', """	move.b	d0,(Z80_RAM+$83).l
	clr.w	(IO_Z80BUS).l
""", """	move.b	d0,(snd_pcm_vol).l			;(sound.asm)
""")
replace_routine('sound94.asm', 'p_initialZ80', '\tbsr.w\tClearAllTrackAndSFXSlots\n'
                '\tclr.b\t(music_needs_z80_update).w\n\trts\n')
P('sound94.asm', r'^Z80_Program_Code\b[^\n]*\n(?:[^\n]*\n)*?\tdc\.b\t\$FF\t[^\n]*\n',
  ';(the Z80 program: not on the Amiga)\n', 1, regex=True)
# The pads are read by ReadJoyData (below); the port readers behind it, for 3 button pads and the
# 4 way play adaptor, are not used.
for _label in ('ReadPad4Way1', 'ReadPad4Way2', 'ReadPad4Way3', 'ReadPad4Way4', 'ReadPad4WayPort1', 'ReadPad2',
               'ReadPad1', 'ReadPadA0', 'ReadPad3Button', 'PadDirTable', 'ResetZ80Bus'):
    remove_routine('sound94.asm', _label)
for _label in ('ReadJoySwapPad1', 'ReadJoySwapPad2', 'ReadJoySwapPad3', 'ReadJoySwapPad4'):
    remove_routine('fourway94.asm', _label)
# The crowd noise was the PSG's (never heard on the Amiga): its level is still worked out (asv).
P('display94.asm', """	move.b	#$C8,(Asound).l
	move.b	#1,(Asound).l
	move.b	(asv).w,d0
	eori.b	#$F,d0
	ori.b	#$F0,d0
	move.b	d0,(Asound).l
""", """	move.b	(asv).w,d0
	eori.b	#$F,d0
	ori.b	#$F0,d0
""")
replace_routine('display94.asm', 'KillCrowd', "\trts\t\t\t\t;(the crowd noise was the PSG's)\n")

# The menu songs (title, end of period, scouting report: $78-$7A, the last) have more notes at once
# than Paula's 4 voices: sound.asm mixes more while one plays (snd_song).
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
	jsr	(snd_song).l				;(sound.asm: the voices for it)
	jsr	(play_sfx_or_music_track).l""")

# The pictures of the EA Sports, title and game setup screens are not in the program as they
# are: fepack.py deflates them (fe.i, their labels in its window), fe_open (render.asm) inflates
# a screen's when it begins, and a game's start gives the window back (fe_close).
for _label, _file in (('GameSetUpMap', 'GameSetUp94-1.map.jim'), ('GameSetUpMap2', 'GameSetUp94-2.map.jim'),
                      ('TitleScreenImg', 'Title94-1.map.jim'), ('NHLShieldImg', 'Title94-2.map.jim'),
                      ('PAlogoImg', 'Title94-3.map.jim'), ('TitleImg', 'Title94-4.map.jim'),
                      ('EASportsMap', 'EASportsMap.bin'), ('SetupMenuMap', 'GameSetupBkgd1.map.jim'),
                      ('SetupFramerMap', 'GameSetupBkgd2.map.jim')):
    P('graphics94.asm', r'^%s\b[^\n]*\n\tincbin\t[^\n]*\\%s\n\teven\n' % (_label, re.escape(_file)),
      ';%s: fe.i (fepack.py)\n' % _label, 1, regex=True)
for _rel, _label, _call in (('attract94.asm', 'EASportsScreen', 'fe_open_ea'),
                            ('title94.asm', 'newTitleScreen', 'fe_open_title'),
                            ('optsetup94.asm', 'setoptions', 'fe_open_setup'),
                            ('hockey94.asm', 'StartGame', 'fe_close')):
    P(_rel, r'^(%s\b[^\n]*\n(?:[ \t]+;[^\n]*\n)*)' % _label, r'\1\tjsr\t(%s).l\t\t\t;(fe.i: render.asm)\n' % _call, 1,
      regex=True)
# The raw PCM sounds are never read here (sound.asm plays their samples in pcm.i): only their
# addresses are, in pcm_sample_table.
P('sound94.asm', r'^\tincbin\t\.\.\\Extracted\\NHL94\\Sound\\(sfx_\w+_pcm)\.bin[^\n]*$',
  r'\tdc.b\t0,0\t\t\t\t\t\t;(\1: its sample is in pcm.i)', 12, regex=True)

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

# Save RAM: the cartridge's battery RAM (its $2000 bytes the odd bytes at $200000) is a buffer
# of $2000 bytes (hal_sram), read from and written to the save file (os.asm). The power-on tests
# of the battery RAM (Start+A+C or Start+B+C held) are left out.
replace_routine('sram94.asm', 'InitSaveRAM', '''\tmove.l\t#VBcount,(VBint).l
\tmove\t#$2500,sr
\tclr.w\t(ValidSRAM).w\t\t\t;good until checked
\tmoveq\t#0,d0
\tmove.l\t#$2000,d1
\tmovea.l\t#M68K_RAM,a0
\tbsr.w\tReadSRAM\t\t\t;the save RAM to RAM
\tbsr.w\tValidateSRAM
\ttst.w\t(ValidSRAM).w
\tbpl.w\t.ex
\tbsr.w\tClearSRAM
\tmoveq\t#0,d0
\tmove.l\t#$2000,d1
\tmovea.l\t#M68K_RAM,a0
\tbsr.w\tReadSRAM
\tbsr.w\tValidateSRAM
.ex
\trts
''')
remove_routine('sram94.asm', 'SRAMWaitVblank')
replace_routine('sram94.asm', 'WriteSRAM', '''\tmovem.l\td0-d1/a0-a1,-(sp)\t\t;d1 bytes from a0 to save RAM byte d0
\tmovea.l\t#hal_sram,a1
\tadda.l\td0,a1
\tsubq.l\t#1,d1
.loop
\tmove.b\t(a0)+,(a1)+
\tdbf\td1,.loop
\tmovem.l\t(sp)+,d0-d1/a0-a1
\trts
''')
replace_routine('sram94.asm', 'ReadSRAM', '''\tmovem.l\td0-d1/a0-a1,-(sp)\t\t;d1 bytes from save RAM byte d0 to a0
\tmovea.l\t#hal_sram,a1
\tadda.l\td0,a1
\tsubq.l\t#1,d1
.loop
\tmove.b\t(a1)+,(a0)+
\tdbf\td1,.loop
\tmovem.l\t(sp)+,d0-d1/a0-a1
\trts
''')

# Video memory (vmem.asm): the game's tiles and cell maps, at the addresses it gives them. Its
# Vmaddr returns a pointer to where an address's data goes (the converter makes its data port
# writes stores through it); its DMA, fill and copy routines are copies there. The video chip's
# ports are left undefined, so that no use of them is missed.
P(j('stubinc', 'ports.inc'), 'Vdata equ $C00000', ';Vdata (no video chip ports on the Amiga)')
P(j('stubinc', 'ports.inc'), 'Vctrl equ Vdata+4', ';Vctrl')
replace_routine('video94.asm', 'Vmaddr', '\tjmp\t(vm_at).l\t\t;d0 = address: a0 = where its data goes\n')
replace_routine('video94.asm', 'DoDMA', '\tjmp\t(vm_load).l\t\t;d0 = words, d1 = address, a0 = source\n')
replace_routine('video94.asm', 'DoDMA_nd2', '\tjmp\t(vm_copy).l\t\t;d0 = bytes, d1 = destination, d2 = source\n')
replace_routine('video94.asm', 'DoFill', '\tjmp\t(vm_fill).l\t\t;d0 = words, d1 = address, d2 = data\n')
replace_routine('video94.asm', 'WaitDMA', '\trts\n')

# Tile data written through Vmaddr's pointer (not loaded): tell the renderer's tile cache.
P('video94.asm', """	movem.l	d0-d4/a0-a2,-(sp)
	exg	d1,d0
	movea.l	a0,a2""", """	movem.l	d0-d4/a0-a2,-(sp)
	jsr	(vm_dirty).l		;d0 = words, d1 = address
	exg	d1,d0
	movea.l	a0,a2""")

# ---------------------------------------------------------------------------------------------
# The picture's layout: colours, scroll, screen width, plane size and window are set in
# display.asm's state (the renderer draws from it), where the Genesis wrote its video chip's
# registers, colour RAM and scroll RAM.
P('hockey94.asm', '\tmove.w\t(Vctrl).l,d0\n', '\tmove.w\t(hal_pal50).l,d0\t\t\t;(hal.asm: bit 0 set at 50 Hz)\n')
_NOWIN = '\tsf\t(ds_win).l\t\t\t;(display.asm: no window)\n\taddq.l\t#1,(ds_gen).l\n'
P('hockey94.asm', '.hor\tmovea.l\t#Vdata,a0\n\tmove.w\t#VDPR_WINX,Vctrl-Vdata(a0)\n\tmove.w\t#VDPR_WINY,Vctrl-Vdata(a0)\n',
  '.hor\n' + _NOWIN)
P('hockey94.asm', '\tmovea.l\t#Vdata,a0\n\tmove.w\t#VDPR_WINX,Vctrl-Vdata(a0)\t;playfield 3 width\n'
  '\tmove.w\t#VDPR_WINY+$1C,Vctrl-Vdata(a0)\t;playfield 3 height\n',
  '\tmove.b\t#$1C,(ds_win).l\t\t;(display.asm: the window, 28 rows)\n\taddq.l\t#1,(ds_gen).l\n')
P('penalty94.asm', '\tmovea.l\t#Vdata,a0\n\tmove.w\t#VDPR_WINX,Vctrl-Vdata(a0)\t;window H position 0\n'
  '\tmove.w\t#VDPR_WINY,Vctrl-Vdata(a0)\t;window V position 0\n', _NOWIN)
P('setup94.asm', '\tmovea.l\t#Vctrl,a0\n\tmove.w\t#VDPR_WINY+$02,(a0)\n',
  '\tmove.b\t#$02,(ds_win).l\t\t;(display.asm: the window, 2 rows)\n\taddq.l\t#1,(ds_gen).l\n')
P('title94.asm', '\tmovea.l\t#Vdata,a0\n\tmove.w\t#VDPR_WINX,Vctrl-Vdata(a0)\n\tmove.w\t#VDPR_WINY+$17,Vctrl-Vdata(a0)\n'
  '\tmove.w\t#VDPR_MODE3+$03,Vctrl-Vdata(a0)\n',
  '\tmove.b\t#$17,(ds_win).l\t\t;(display.asm: the window, 23 rows; scrolled by lines)\n'
  '\tst\t(ds_lines).l\n\taddq.l\t#1,(ds_gen).l\n')
P('title94.asm', '\tmove.w\t(VSCRLPM).w,d1\n\tmove.w\t#$1C0,d0\n\tjsr\t(DoDMA).l\n\tmovea.l\t#Vdata,a0\n'
  '\tmove.l\t#VSRAM_W,Vctrl-Vdata(a0)\n\tmove.w\t(Vscroll).w,(a0)\n',
  '\tjsr\t(ds_hlines).l\t\t\t;(display.asm: each line\'s scroll)\n'
  '\tmove.w\t(Vscroll).w,(ds_vs).l\t\t;(plane A\'s vertical scroll)\n')
P('data94.asm', '\tmovea.l\t#Vdata,a0\n\tmove.w\t#VDPR_WINX,Vctrl-Vdata(a0)\n\tmove.w\t#VDPR_WINY+$06,Vctrl-Vdata(a0)\n'
  '\tmove.w\t#VDPR_AUTOINC+$02,Vctrl-Vdata(a0)\n\tmove.l\t#CRAM_W+($20<<16),Vctrl-Vdata(a0)\t;cram write $20 (92 $C0060000)\n',
  '\tmove.b\t#$06,(ds_win).l\t\t;(display.asm: the window, 6 rows; colours 16-31)\n'
  '\taddq.l\t#1,(ds_gen).l\n\tmovea.l\t#ds_pal+$20,a0\n')
P('data94.asm', '.pal\n\tmove.l\t(a1)+,(a0)\n\tdbf\td0,.pal\n', '.pal\n\tmove.l\t(a1)+,(a0)+\n\tdbf\td0,.pal\n'
  '\taddq.l\t#1,(ds_palgen).l\n')
# (plane B's vertical scroll in the stats screens)
for _rel, _n in (('stats94.asm', 5), ('period94.asm', 1)):
    P(_rel, r'\tmovea\.l\t#Vdata,a0\n\tmove\.l\t#VSRAM_W\+\(2<<16\),Vctrl-Vdata\(a0\)\n'
      r'(\t[^\n]*\n\tadd\.w\t\(VertLineScrolling\)\.w,d0\n)\tmove\.w\td0,\(a0\)\n',
      r"\1\tmove.w\td0,(ds_vs+2).l\t\t;(display.asm: plane B's vertical scroll)\n\taddq.l\t#1,(ds_gen).l\n",
      _n, regex=True)
# (the stats screens: 320 pixels across, unscrolled; then back to the rink's 256)
for _rel, _call in (('stats94.asm', 'bsr.w\tVmaddr'), ('cards94.asm', 'jsr\t(Vmaddr).l')):
    P(_rel, '\tmove.w\t#VDPR_MODE4+$81,Vctrl-Vdata(a0)\n\tmove.w\t#6,(Map3col1).w\n\tmove.w\t#VDPR_HSCROLL,Vctrl-Vdata(a0)\n'
      '\tclr.w\td0\n\t%s\n\tmove.l\t#0,(a0)\n' % _call,
      '\tst\t(ds_wide).l\t\t\t;(display.asm: 320 pixels across, unscrolled)\n\tclr.l\t(ds_hs).l\n'
      '\taddq.l\t#1,(ds_gen).l\n\tmove.w\t#6,(Map3col1).w\n')
P('stats94.asm', '\tmove.w\t(VSCRLPM).w,d0\n\tbsr.w\tVmaddr\n\tmove.l\t#0,(a0)\n\tmove.w\t#$8D00,d0\n'
  '\tmove.b\t(VSCRLPM).w,d0\n\tlsr.b\t#2,d0\n\tmove.w\td0,Vctrl-Vdata(a0)\n\tmove.w\t#VDPR_MODE4,Vctrl-Vdata(a0)\n',
  '\tsf\t(ds_wide).l\t\t\t;(display.asm: 256 pixels across, unscrolled)\n\tclr.l\t(ds_hs).l\n'
  '\taddq.l\t#1,(ds_gen).l\n')
# (the game's: plane B's scroll; the playoff tree's: plane A's)
replace_routine('display94.asm', 'SetScroll2', '\tmove.w\t(Hscroll).w,(ds_hs+2).l\t\t;(display.asm: plane B\'s scroll)\n'
                '\tmove.w\t(Vscroll).w,(ds_vs+2).l\n\taddq.l\t#1,(ds_gen).l\n\trts\n')
P('setup94.asm', '\tmove.w\t(VSCRLPM).w,d0\n\tbsr.w\tVmaddr\n\tmove.w\t#$FEA0,d0\n\tadd.w\t(DispAttribCtr).w,d0\n\tmove.w\td0,(a0)\n',
  '\tmove.w\t#$FEA0,d0\n\tadd.w\t(DispAttribCtr).w,d0\n\tmove.w\td0,(ds_hs).l\t\t\t;(display.asm: plane A\'s scroll)\n'
  '\taddq.l\t#1,(ds_gen).l\n')
# (the sprite list: handed over, not copied into video memory)
_SPR = '\tjsr\t(ds_sprites).l\t\t\t;(display.asm: the sprite list, d0 words at a0)\n'
P('display94.asm', '\tmove.w\t(VSPRITES).w,d1\n\tbsr.w\tDoDMA\ndodmalist', _SPR + 'dodmalist')
P('title94.asm', '\tmove.w\t(VSPRITES).w,d1\n\tjsr\t(DoDMA).l\n', _SPR)
P('setup94.asm', '\tmove.w\t(VSPRITES).w,d1\n\tbsr.w\tDoDMA\n', _SPR)
for _rel, _call in (('stats94.asm', 'bsr.w\tVmaddr'), ('cards94.asm', 'jsr\t(Vmaddr).l')):
    P(_rel, '\tmove.w\t(VSPRITES).w,d0\n\t%s\n\tmove.l\t#0,(a0)\n' % _call,
      '\tclr.l\t(ds_spr).l\t\t\t;(display.asm: no sprites)\n\taddq.l\t#1,(ds_gen).l\n')
# (setVram: VRAM cleared, then the screen's layout from disflags, Map1col1, VmMAP1-3)
P('video94.asm', '\tmove.w\t#VDPR_AUTOINC+$02,(Vctrl).l\n', '')
P('video94.asm', r'\tmove\.w\t#\$8C00,d0[^\n]*\n(?:[^\n]*\n)*?\tmove\.l\t#0,\(a0\)\t+;playfield 1/2\n',
  '\tjsr\t(vm_dirty_all).l\t\t;all of VRAM was cleared\n\tjsr\t(ds_setup).l\t\t\t;(display.asm: the screen\'s layout)\n',
  1, regex=True)
# (colours: the fade steps and the copy of palfadenew)
P('video94.asm', '\tmovea.l\t#Vdata,a0\n\tclr.w\td6\n.top\n\tmove.w\td3,d2\n\tmove.w\td6,d0\n\tswap\td0\n\tmove.w\t#$20,d0\n'
  '\tmove.l\td0,Vctrl-Vdata(a0)\n\tmove.w\t(a0),d7\n',
  '\tmovea.l\t#ds_pal,a0\t\t\t;(display.asm: the colours)\n\tclr.w\td6\n.top\n\tmove.w\td3,d2\n\tmove.w\t(a0,d6.w),d7\n')
P('video94.asm', '\tmove.l\t#$C000,d0\n\tmove.b\td6,d0\n\tswap\td0\n\tmove.l\td0,Vctrl-Vdata(a0)\n\tmove.w\td7,(a0)\n'
  '.next\n\taddq.w\t#2,d6\n\tcmp.w\t#$80,d6\n\tbne.s\t.top\n\trts\n',
  '\tmove.w\td7,(a0,d6.w)\n.next\n\taddq.w\t#2,d6\n\tcmp.w\t#$80,d6\n\tbne.s\t.top\n\taddq.l\t#1,(ds_palgen).l\n\trts\n')
P('video94.asm', '\tmovea.l\t#Vdata,a0\n\tmove.l\t#CRAM_W,Vctrl-Vdata(a0)\n\tmoveq\t#$1F,d0\n.0\n\tmove.l\t(a1)+,(a0)\n\tdbf\td0,.0\n',
  '\tjsr\t(ds_colours).l\t\t\t;(display.asm)\n')

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
