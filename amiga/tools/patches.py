"""Per-site rewrites for the Amiga build (used by convert.py)."""
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

# RAM: $FFFFxxxx -> RAMBASE+$xxxx.
P(j('stubinc', 'ram_addrs.inc'), r'\$FFFF([0-9A-Fa-f]{4})\b', r'RAMBASE+$\1', None, regex=True)
P(j('stubinc', 'equals.inc'), 'replaystart equ $FFFF0000', 'replaystart equ RAMBASE')

with open(os.path.join(AMIGA_SRC, 'genesis_vasm.mac')) as _fh:
    _MAC = _fh.read()
P(j('macros', 'genesis.mac'), r'\A[\s\S]*\Z', _MAC.replace('\\', '\\\\'), 1, regex=True)


def replace_routine(rel, label, body, table=PRE):
    """Replace the lines from 'label' up to the next global label with body."""
    pat = r'^%s\b[^\n]*\n(?:(?![A-Za-z_][\w]*\b)[^\n]*\n)*' % re.escape(label)
    rule(table, rel, pat, label + '\n' + body.rstrip('\n').replace('\\', '\\\\') + '\n', 1, True)


def remove_routine(rel, label, table=PRE):
    """Remove 'label' and its lines up to the next global label."""
    pat = r'^%s\b[^\n]*\n(?:(?![A-Za-z_][\w]*\b)[^\n]*\n)*' % re.escape(label)
    rule(table, rel, pat, '', 1, True)


def remove_equates(rel, names, table=PRE):
    """Remove the definitions (equ, =) of names."""
    for name in names.split():
        rule(table, rel, r'^%s[ \t]*(?:[ \t]equ\b|=)[^\n]*\n' % re.escape(name), '', 1, True)


def remove_macro(rel, name, table=PRE):
    """Remove the macro 'name', its definition to its endm."""
    rule(table, rel, r'^%s[ \t]+(?i:macro)\b[^\n]*\n(?:[^\n]*\n)*?[ \t]+(?i:endm)\b[^\n]*\n' % re.escape(name), '',
         1, True)


# Hardware ports.
for _port in ('IO_CT1_CTRL equ $A10008', 'IO_CT1_DATA equ $A10002', 'IO_CT2_CTRL equ $A1000A',
              'IO_CT2_DATA equ $A10004', 'IO_Z80BUS equ $A11100', 'IO_Z80RES equ $A11200',
              'Asound equ $C00011'):
    P(j('stubinc', 'ports.inc'), _port, ';%s (not on the Amiga)' % _port.split()[0])
P(j('stubinc', 'ports.inc'), 'HVcount equ $C00008', 'HVcount equ $DFF006')
P(j('stubinc', 'ram_addrs.inc'), 'Z80_RAM equ $A00000', '')

replace_routine('display94.asm', 'addframe2', '\tjmp\t(hal_addframe2).l\n')

replace_routine('sound94.asm', 'UploadCommandBufferToZ80', '\tjmp\t(snd_fm_commands).l\n')
remove_routine('sound94.asm', 'z80_bus_release_delay')
replace_routine('sound94.asm', 'StopPCMChannel', '\tclr.b\t(snd_pcm_rate).l\n\trts\n')
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
	jsr	(snd_pcm_play).l
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
	move.b	d2,(snd_pcm_rate).l
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
""", """	move.b	d0,(snd_pcm_vol).l
""")
replace_routine('sound94.asm', 'p_initialZ80', '\tbsr.w\tClearAllTrackAndSFXSlots\n'
                '\tclr.b\t(music_needs_z80_update).w\n\trts\n')
P('sound94.asm', r'^Z80_Program_Code\b[^\n]*\n(?:[^\n]*\n)*?\tdc\.b\t\$FF\t[^\n]*\n',
  '\n', 1, regex=True)
for _label in ('ReadPad4Way1', 'ReadPad4Way2', 'ReadPad4Way3', 'ReadPad4Way4', 'ReadPad4WayPort1', 'ReadPad2',
               'ReadPad1', 'ReadPadA0', 'ReadPad3Button', 'PadDirTable', 'ResetZ80Bus'):
    remove_routine('sound94.asm', _label)
for _label in ('ReadJoySwapPad1', 'ReadJoySwapPad2', 'ReadJoySwapPad3', 'ReadJoySwapPad4'):
    remove_routine('fourway94.asm', _label)
P('display94.asm', """	move.b	#$C8,(Asound).l
	move.b	#1,(Asound).l
	move.b	(asv).w,d0
	eori.b	#$F,d0
	ori.b	#$F0,d0
	move.b	d0,(Asound).l
""", """	move.b	(asv).w,d0
	eori.b	#$F,d0
	ori.b	#$F0,d0
	move.b	d0,(snd_psg_att).l
""")
replace_routine('display94.asm', 'KillCrowd', "\tst\t(snd_psg_att).l\n\trts\n")


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
P('sound94.asm', r'^\tincbin\t\.\.\\Extracted\\NHL94\\Sound\\(sfx_\w+_pcm)\.bin[^\n]*$',
  r'\tdc.b\t0,0', 12, regex=True)

replace_routine('sound94.asm', 'ReadJoyData', '''\tmovem.l\td0-d1/a0-a1,-(sp)
\tjsr\t(hal_readpads).l
\tmove.b\td0,(pad4way1).w
\tmove.b\td1,(pad4way2).w
\tmovem.l\t(sp)+,d0-d1/a0-a1
\trts
''')
replace_routine('fourway94.asm', 'Detect4WayPlay', '''\tmove.w\t#0,(FourWayPlay).w
\trts
''')

replace_routine('sram94.asm', 'InitSaveRAM', '''\tmove.l\t#VBcount,(VBint).l
\tmove\t#$2500,sr
\tclr.w\t(ValidSRAM).w
\tmoveq\t#0,d0
\tmove.l\t#$2000,d1
\tmovea.l\t#M68K_RAM,a0
\tbsr.w\tReadSRAM
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
replace_routine('sram94.asm', 'WriteSRAM', '''\tmovem.l\td0-d1/a0-a1,-(sp)
\tmovea.l\t#hal_sram,a1
\tadda.l\td0,a1
\tsubq.l\t#1,d1
.loop
\tmove.b\t(a0)+,(a1)+
\tdbf\td1,.loop
\tmovem.l\t(sp)+,d0-d1/a0-a1
\trts
''')
replace_routine('sram94.asm', 'ReadSRAM', '''\tmovem.l\td0-d1/a0-a1,-(sp)
\tmovea.l\t#hal_sram,a1
\tadda.l\td0,a1
\tsubq.l\t#1,d1
.loop
\tmove.b\t(a1)+,(a0)+
\tdbf\td1,.loop
\tmovem.l\t(sp)+,d0-d1/a0-a1
\trts
''')

P(j('stubinc', 'ports.inc'), 'Vdata equ $C00000', '')
P(j('stubinc', 'ports.inc'), 'Vctrl equ Vdata+4', '')
replace_routine('video94.asm', 'Vmaddr', '\tjmp\t(vm_at).l\n')
replace_routine('video94.asm', 'DoDMA', '\tjmp\t(vm_load).l\n')
replace_routine('video94.asm', 'DoDMA_nd2', '\tjmp\t(vm_copy).l\n')
replace_routine('video94.asm', 'DoFill', '\tjmp\t(vm_fill).l\n')
replace_routine('video94.asm', 'WaitDMA', '\trts\n')

P('video94.asm', """	movem.l	d0-d4/a0-a2,-(sp)
	exg	d1,d0
	movea.l	a0,a2""", """	movem.l	d0-d4/a0-a2,-(sp)
	jsr	(vm_dirty).l
	exg	d1,d0
	movea.l	a0,a2""")

# The picture's layout: colours, scroll, screen width.
P('hockey94.asm', '\tmove.w\t(Vctrl).l,d0\n', '\tmove.w\t(hal_pal50).l,d0\n')
_NOWIN = '\tsf\t(ds_win).l\t\t\t;(display.asm: no window)\n\taddq.l\t#1,(ds_gen).l\n'
P('hockey94.asm', '.hor\tmovea.l\t#Vdata,a0\n\tmove.w\t#VDPR_WINX,Vctrl-Vdata(a0)\n\tmove.w\t#VDPR_WINY,Vctrl-Vdata(a0)\n',
  '.hor\n' + _NOWIN)
P('hockey94.asm', '\tmovea.l\t#Vdata,a0\n\tmove.w\t#VDPR_WINX,Vctrl-Vdata(a0)\t;playfield 3 width\n'
  '\tmove.w\t#VDPR_WINY+$1C,Vctrl-Vdata(a0)\t;playfield 3 height\n',
  '\tmove.b\t#$1C,(ds_win).l\n\taddq.l\t#1,(ds_gen).l\n')
P('penalty94.asm', '\tmovea.l\t#Vdata,a0\n\tmove.w\t#VDPR_WINX,Vctrl-Vdata(a0)\t;window H position 0\n'
  '\tmove.w\t#VDPR_WINY,Vctrl-Vdata(a0)\t;window V position 0\n', _NOWIN)
P('setup94.asm', '\tmovea.l\t#Vctrl,a0\n\tmove.w\t#VDPR_WINY+$02,(a0)\n',
  '\tmove.b\t#$02,(ds_win).l\n\taddq.l\t#1,(ds_gen).l\n')
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
for _rel, _n in (('stats94.asm', 5), ('period94.asm', 1)):
    P(_rel, r'\tmovea\.l\t#Vdata,a0\n\tmove\.l\t#VSRAM_W\+\(2<<16\),Vctrl-Vdata\(a0\)\n'
      r'(\t[^\n]*\n\tadd\.w\t\(VertLineScrolling\)\.w,d0\n)\tmove\.w\td0,\(a0\)\n',
      r"\1\tmove.w\td0,(ds_vs+2).l\n\taddq.l\t#1,(ds_gen).l\n",
      _n, regex=True)
for _rel, _call in (('stats94.asm', 'bsr.w\tVmaddr'), ('cards94.asm', 'jsr\t(Vmaddr).l')):
    P(_rel, '\tmove.w\t#VDPR_MODE4+$81,Vctrl-Vdata(a0)\n\tmove.w\t#6,(Map3col1).w\n\tmove.w\t#VDPR_HSCROLL,Vctrl-Vdata(a0)\n'
      '\tclr.w\td0\n\t%s\n\tmove.l\t#0,(a0)\n' % _call,
      '\tst\t(ds_wide).l\t\t\t;(display.asm: 320 pixels across, unscrolled)\n\tclr.l\t(ds_hs).l\n'
      '\taddq.l\t#1,(ds_gen).l\n\tmove.w\t#6,(Map3col1).w\n')
P('stats94.asm', '\tmove.w\t(VSCRLPM).w,d0\n\tbsr.w\tVmaddr\n\tmove.l\t#0,(a0)\n\tmove.w\t#$8D00,d0\n'
  '\tmove.b\t(VSCRLPM).w,d0\n\tlsr.b\t#2,d0\n\tmove.w\td0,Vctrl-Vdata(a0)\n\tmove.w\t#VDPR_MODE4,Vctrl-Vdata(a0)\n',
  '\tsf\t(ds_wide).l\t\t\t;(display.asm: 256 pixels across, unscrolled)\n\tclr.l\t(ds_hs).l\n'
  '\taddq.l\t#1,(ds_gen).l\n')
replace_routine('display94.asm', 'SetScroll2', '\tmove.w\t(Hscroll).w,(ds_hs+2).l\t\t;(display.asm: plane B\'s scroll)\n'
                '\tmove.w\t(Vscroll).w,(ds_vs+2).l\n\taddq.l\t#1,(ds_gen).l\n\trts\n')
P('setup94.asm', '\tmove.w\t(VSCRLPM).w,d0\n\tbsr.w\tVmaddr\n\tmove.w\t#$FEA0,d0\n\tadd.w\t(DispAttribCtr).w,d0\n\tmove.w\td0,(a0)\n',
  '\tmove.w\t#$FEA0,d0\n\tadd.w\t(DispAttribCtr).w,d0\n\tmove.w\td0,(ds_hs).l\t\t\t;(display.asm: plane A\'s scroll)\n'
  '\taddq.l\t#1,(ds_gen).l\n')
_SPR = '\tjsr\t(ds_sprites).l\t\t\t;(display.asm: the sprite list, d0 words at a0)\n'
P('display94.asm', '\tmove.w\t(VSPRITES).w,d1\n\tbsr.w\tDoDMA\ndodmalist', _SPR + 'dodmalist')
P('title94.asm', '\tmove.w\t(VSPRITES).w,d1\n\tjsr\t(DoDMA).l\n', _SPR)
P('setup94.asm', '\tmove.w\t(VSPRITES).w,d1\n\tbsr.w\tDoDMA\n', _SPR)
for _rel, _call in (('stats94.asm', 'bsr.w\tVmaddr'), ('cards94.asm', 'jsr\t(Vmaddr).l')):
    P(_rel, '\tmove.w\t(VSPRITES).w,d0\n\t%s\n\tmove.l\t#0,(a0)\n' % _call,
      '\tclr.l\t(ds_spr).l\n\taddq.l\t#1,(ds_gen).l\n')
P('video94.asm', '\tmove.w\t#VDPR_AUTOINC+$02,(Vctrl).l\n', '')
P('video94.asm', r'\tmove\.w\t#\$8C00,d0[^\n]*\n(?:[^\n]*\n)*?\tmove\.l\t#0,\(a0\)\t+;playfield 1/2\n',
  '\tjsr\t(vm_dirty_all).l\n\tjsr\t(ds_setup).l\n',
  1, regex=True)
P('video94.asm', '\tmovea.l\t#Vdata,a0\n\tclr.w\td6\n.top\n\tmove.w\td3,d2\n\tmove.w\td6,d0\n\tswap\td0\n\tmove.w\t#$20,d0\n'
  '\tmove.l\td0,Vctrl-Vdata(a0)\n\tmove.w\t(a0),d7\n',
  '\tmovea.l\t#ds_pal,a0\n\tclr.w\td6\n.top\n\tmove.w\td3,d2\n\tmove.w\t(a0,d6.w),d7\n')
P('video94.asm', '\tmove.l\t#$C000,d0\n\tmove.b\td6,d0\n\tswap\td0\n\tmove.l\td0,Vctrl-Vdata(a0)\n\tmove.w\td7,(a0)\n'
  '.next\n\taddq.w\t#2,d6\n\tcmp.w\t#$80,d6\n\tbne.s\t.top\n\trts\n',
  '\tmove.w\td7,(a0,d6.w)\n.next\n\taddq.w\t#2,d6\n\tcmp.w\t#$80,d6\n\tbne.s\t.top\n\taddq.l\t#1,(ds_palgen).l\n\trts\n')
P('video94.asm', '\tmovea.l\t#Vdata,a0\n\tmove.l\t#CRAM_W,Vctrl-Vdata(a0)\n\tmoveq\t#$1F,d0\n.0\n\tmove.l\t(a1)+,(a0)\n\tdbf\td0,.0\n',
  '\tjsr\t(ds_colours).l\n')

P('display94.asm', """	move.b	(Crowdframe).w,d0
	bsr.w	.sc
	move.b	(Crowdframe+1).w,d0
	bra.w	.sc
""", '\trts\n')

# What nothing in the build reaches: routines and tables never called or read.
for _rel, _labels in (('hockey94.asm', 'VBjsr'), ('checks94.asm', 'SkateToTempTarget'),
                      ('video94.asm', 'UnpackNibbles waitjoy'),
                      ('attract94.asm', 'dotb ClearRosterName setoptions_printpos2 PickStartingGoalie'),
                      ('data94.asm', 'AddError Illinst ZeroDiv crash'), ('fourway94.asm', 'Set4WayPlayer'),
                      ('crowd94.asm', 'Clamp0to100'), ('optsetup94.asm', 'SetFrameRectUnused CheckNOPUnused'),
                      ('scout94.asm', 'ScoutCrowdRecordBy ScoutEmptyTxt ScoutByTxt ScoutSpaceTxt GetTeamCity '
                                      'ScoutStub'),
                      ('period94.asm', 'ClampPositionBox PositionBoxes PositionBoxesTop SkipNameNumber'),
                      ('goalie94.asm', 'SetCameraTop'), ('title94.asm', 'TerminateLogName PuckComingToward')):
    for _label in _labels.split():
        remove_routine(_rel, _label)
remove_equates(j('stubinc', 'ports.inc'), 'VDPR_AUTOINC VDPR_MODE1 VDPR_MODE2 VDPR_PLANEA VDPR_WINDOW VDPR_PLANEB VDPR_SPRITE '
               'VDPR_BGCOL VDPR_HINT VDPR_MODE3 VDPR_MODE4 VDPR_HSCROLL VDPR_PLANESIZE VDPR_WINX VDPR_WINY '
               'VDPR_DMALENL VDPR_DMALENH VDPR_DMASRCL VDPR_DMASRCM VDPR_DMASRCH VRAM_W CRAM_W VSRAM_W')
remove_equates(j('stubinc', 'equals.inc'), 'bbut Sortobjs tmshots TXHF TXVF SFXoooh SFXhithigh SFXhitlow SFXpass '
               'SFXplayerwall2 SFXplayerwall3 SFXplayerwall4 SFXpuckpost SFX26 SFX27 SFXpuckwall1 SFXpuckwall2 '
               'SFXpuckwall3 SFXpuckwall4 RecordsBytes')
remove_equates(j('stubinc', 'ram_addrs.inc'), 'puckcross4 pad4wayword pad4waysave1 pad4waysave2 pad4waysave3 '
               'pad4waysave4 PenWhistle PenGoal PenOffsides PenRoughing2 PenNoText PenSlashing PenCrossChk '
               'PenHooking PenTripping PenInterference PenHolding PenFighting PenFighting2 PenInst PenDelay '
               'PenHookingPS PenTrippingPS PenGhold2 PenInterferencePS PenRoughingPS PenChargingPS PenCrossChkPS '
               'PenSlashingPS dmaram lognametext Z80_YM2612')
remove_equates('teamdata94.asm', 'Playerdata Palettedata Teamname LineSets ScoutReport GoalieOdds')
remove_equates('frames94.asm', 'SPAgready2 SPAfake')
for _name in ('VmInc', 'String', 'HEX2', 'PLAYER'):
    remove_macro(j('macros', 'genesis.mac'), _name)
