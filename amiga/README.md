# NHL 94 for the Amiga 1200 (AGA)

This directory builds NHL 94 as an Amiga program from the Genesis disassembly in `src/`. The
game code is the Genesis 68000 code, converted at build time. A hardware layer written for the
Amiga stands in for the Genesis video chip, pads, Z80 and sound chip. The Genesis sources are
not changed, so `main` still rebuilds the cartridge byte for byte.

## Requirements

- An Amiga with the AGA chipset (A1200, A4000, CD32 with a keyboard and fast RAM, or an emulator).
- A 68020 or better. The renderer uses 68020 instructions.
- 2 MB of chip RAM and at least 2 MB of fast RAM. The game takes about 1.5 MB of any memory and
  about 1.3 MB of chip RAM, so it does not fit in a stock 2 MB A1200.
- Kickstart 2.0 or later (3.x, or the AROS ROM, have been tested in FS-UAE and vAmiga).
- PAL or NTSC. The game runs at the display's rate, as on the console of that region: 50 game
  frames a second on a PAL Amiga (the speed of a PAL Mega Drive, a sixth slower than an NTSC
  Genesis), 60 on NTSC. `F8` switches between the two.

Speed: on a stock 14 MHz A1200 with fast RAM, gameplay draws about 16 to 19 frames a second (FS-UAE,
cycle exact; the game itself runs at full speed, it is the screen updates that are fewer) and
the menus are smooth. An accelerator is recommended: a 68030 at 50 MHz manages about 30.

## Running

Copy `output/amiga/NHL94`, `NHL94.info` and `nhl94.game` into the same directory. Start `NHL94`
from a Shell, or double click its icon. `NHL94` is a small launcher that loads `nhl94.game`. The
game takes over the machine and gives it back when you quit. If it cannot run (no AGA, no 68020,
not enough memory, `nhl94.game` missing), a requester says why.

In an emulator, use the hard drive image `output/amiga/nhl94.hdf`. The build makes it when
`xdftool` is installed (`pip install amitools`). It boots straight into the game.

There is also a bootable floppy, `output/amiga/nhl94.adf` (880 KB, double density, so it works
in the A1200's own drive and in every emulator). The game does not fit on a floppy as it is, so
there it is `NHL94.pak`, its parts deflate compressed, which the launcher loads and unpacks
itself. Loading from a real floppy takes about 70 seconds; the hard drive image starts at once.
To install the floppy on a hard drive, copy `NHL94`, `NHL94.info` and `NHL94.pak` into one
directory.

- **vAmigaWeb** (vamigaweb.github.io): choose the Amiga 1200 model with fast RAM (the "A1200"
  preset with 8 MB fast RAM), then drop `nhl94.hdf` onto the page. Do not drop `nhl94.game`
  itself: an executable that big is put on a high density floppy, and booting that hangs or crashes
  (it does with any large executable).
- **FS-UAE, WinUAE, Amiberry**: an A1200 with `fast_memory` of 2 MB or more and `nhl94.hdf` as
  the first hard drive (or the directory with the three files as a hard drive folder).

Battery save data (season, playoffs, records) is written to `NHL94.sav` next to the game when
you quit, and is read when it starts.

### Controls

| | Player 1 (joystick port 2) | Player 2 (joystick port 1) |
|---|---|---|
| Move | joystick / cursor keys | joystick |
| C (shoot, check) | fire / CD32 red / `C` | fire / CD32 red / `F3` |
| B (pass, switch player) | 2nd button / CD32 blue / `X` | 2nd button / CD32 blue / `F2` |
| A | CD32 green or yellow / `Z` | CD32 green or yellow / `F1` |
| Start (pause) | CD32 play / `Return` | CD32 play / `F4` |

`Esc` quits to the Workbench and writes the save file. `F7` switches the Amiga's audio low-pass
filter (on at start, like the output filter of a model 1 Genesis). `F8` switches the game
between 50 and 60 frames a second.

### Screen

Every screen is shown as the Genesis shows it: the menus 320 pixels wide, the rink 256 (the
Genesis' H32 mode), centred.

In vAmigaWeb, set "visible display area" to "viewport tracking" in the settings: it then zooms to
the picture the game shows, without the borders. The 4 way play adaptor modes are not
available.

## Building

Needs Python 3 with numpy, Node.js (for the repository's asset extraction pre-step, see the main README) and
vasm (`vasmm68k_mot`, Motorola syntax; on the `PATH`, in `$VASM`, or at `/opt/amiga/vasm`).

    amiga/build.sh

writes `output/amiga/nhl94.game`, `output/amiga/NHL94` (the launcher) and `NHL94.info`. With
`VASMFLAGS`:

- `-DWATCHDOG=1` shows a debug screen (the last interrupted program counters) when no frame has
  been drawn for 4 seconds.
- `-DSHOWFPS=1` shows the frame rate in the corner (F10 toggles it).
- `-DPROFILE=1` samples the program counter 60 times a second and writes `nhl94.prof` on exit;
  `amiga/tools/amiprof.py` turns it into a list of routines.
- `-DSTATS=1` counts renderer work for the test harness (`NHL_STATS=1`).
- `-DMENUMUSIC=1` plays the menu songs (title, end of period, scouting report), which are off
  for now: they do not sound right yet.
- `-DVERIFY=1` makes the renderer check its scroll buffers every frame: every part of plane B
  not listed for repair must match the bitmap. The test harness reports the first failure.

## How it works

`amiga/tools/convert.py` copies `src/` to `output/amiga/src` with these changes:

- The Genesis RAM (`$FFFF0000`) moves to a 64 KB window at `RAMBASE`. The 16-bit absolute
  addresses the game uses for RAM become 32-bit addresses. Word pointers that are sign-extended
  into address registers are fixed up after they are loaded. The window must be 64 KB aligned
  (the game keeps RAM pointers as words), which AmigaDOS cannot do, so `RAMBASE` is a hunk of
  its own: `amiga/tools/ramrel.py` lists every place that holds its address, and at start the
  game takes an aligned block (in fast RAM if there is some) and moves those addresses there.
- Writes to the video chip ports go to the emulated VDP (`vdp.asm`): VRAM, CRAM and VSRAM in
  memory, and DMA, fills and copies done by the CPU. Writes also mark which tiles changed.
- Z80 bus polling, pad port reads and wait loops are rewritten. A wait loop calls `hal_idle`,
  which runs the renderer while the game waits for its next frame.
- vasm syntax: macros, local labels, `incbin` paths and other small differences.

`amiga/tools/patches.py` makes the few changes that need code written by hand: the sound
handshake, the pad reader and the save RAM.

The hardware layer:

- `hal.asm`: start-up, interrupt vectors, the 50 / 60 Hz CIA timer that stands in for the Genesis
  vertical blank, and the two contexts (the game, and the renderer it runs while the game waits).
- `os.asm`: takes the machine from the OS and gives it back; keeps the OS's memory in the
  `RAMBASE` window; loads and saves `NHL94.sav`.
- `render.asm`: draws the emulated VDP state in 64 colours on 6 interleaved bitplanes. Tiles are
  cached in planar form. Plane B is kept as a bitmap. On the rink each screen buffer holds the
  whole of plane B (512 x 256, its top 224 lines twice for the vertical wrap) and the display
  hardware scrolls it: the bitplane pointers, a fetch that starts up to 31 pixels early and the
  BPLCON1 delay. Only what was drawn over it two frames ago and the cells the game changed are
  blitted back from the bitmap (a dirty map per buffer, 16 pixels by 8 lines a bit). Other
  screens get plane B blitted in at the scroll position. Plane A and the window are an overlay
  layer with masks. Sprites are blits of images kept in a cache in chip RAM (built once from
  the tiles, used again until a tile of theirs changes), and plane B's high priority cells are
  blitted back over what was drawn under them; the CPU queues a whole frame for the blitter
  without waiting. A chunky renderer with
  chunky-to-planar conversion covers line scroll and cell scroll. The copper sets the 64 colours
  and the display window, and frames are double buffered. A frame is drawn from a snapshot of
  the VDP registers, scroll and sprite list taken when it starts (the game runs several of its
  frames meanwhile; without it, players could be from a later game frame than the rink). A
  finished frame's copper list is taken at the next vertical blank, and the renderer waits for
  that blank (counted by the level 3 interrupt) before it draws into the other buffer, which is
  on the screen until then.
  The colours are AGA 24 bit colours (each written as high then low nibbles) at the levels the
  Genesis puts out, which are not a straight line from 0 to 255; Extra Half-Brite is switched
  off so all 64 registers are used.
- `input.asm`: joysticks, CD32 pads and the keyboard, read as two 3 button pads.
- `sound.asm`: the four Paula voices in place of the Z80, YM2612 and DAC. The game's own 68000
  sound driver runs unchanged. `sound.asm` reads the commands the driver writes for the Z80:
  key on, key off, frequency, volume and patch per FM channel, and the PCM start, rate and volume.
  All audio is 8 bit at 11 kHz at most. The 32 FM patches are rendered to samples at 11025 Hz at
  build time by `amiga/tools/fmrender.py`, a model of the YM2612. Each patch has an attack and a
  loop at each octave band it is used at, so every note plays at 7.8 to 15.6 kHz. The synthesis runs at 8 times the sample rate and is low-pass
  filtered before it is decimated, as FM harmonics above the sample rate would otherwise fold
  back as harsh noise. The rest of each envelope is a volume envelope at run time. The 6 Genesis channels share 4 voices: a new
  note takes a free voice, else the quietest released one, else the oldest. The PCM sounds
  (crowd, shots, checks) are made into samples at build time too, by `amiga/tools/pcmrender.py`:
  most already play at 11 kHz or less and are kept as they are; the two the game plays faster
  (the glass at 29 kHz, a hit at 12 kHz) are resampled to 11025 Hz and played at a period that
  keeps their pitch.
- `stub.asm`: the launcher. It runs `NHL94.pak` when it is there (the floppy): it reads the
  file, allocates each hunk as AmigaDOS would, inflates it in place (`inflate.i`, a 68000 deflate
  decoder with a lookup table for codes of up to 9 bits) and applies the relocations. Otherwise
  it has AmigaDOS load `NHL94.game`.

The renderer queues its blits; the blitter's interrupt starts each next one, so the CPU goes on
building the next layer meanwhile.

## Testing without an Amiga

`amiga/harness` is a Linux test harness. It runs the build on the Musashi 68020 core with just
enough of the Amiga custom chips (blitter, copper list, Paula):

    make -C amiga/harness MUSASHI=/path/to/Musashi
    amiga/harness/regress.sh /tmp/shots

It plays through the attract mode and into a game by pressing Start. At a few frames (a second
argument lists others) it compares the Amiga screen, taken from the copper list, with a
reference Genesis renderer (`vdpref.c`) and prints any frame whose pixels differ. A screen can
lag one VDP update behind when the game changes it mid frame (text being printed, a mode
change). `NHL_WAV=out.wav` writes the sound; `NHL_AUDLOG=1` logs every sample start;
`NHL_PROF=file` writes a PC sample every 1000 cycles, which `amiga/harness/rdcost.py` sums.

`amiga/tools/uaerun.sh` runs the build in FS-UAE (A1200, AROS ROM by default) on a virtual X
display, presses keys at given times and takes screenshots. Add `fast_memory = 8192` with
`UAEEXTRA`.

## Known limits

- Speed on an unexpanded 68020 (above).
- Only 4 sound voices for the Genesis' 6, so big chords lose notes. FM sounds are samples, so
  notes do not change timbre as they decay, and the LFO, detune and SSG-EG are left out.
- No 4 way play.
