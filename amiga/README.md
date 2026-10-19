# NHL 94 for the Amiga 1200 (AGA)

This directory builds NHL 94 as an Amiga program from the Genesis disassembly in `src/`. The
game code is the Genesis 68000 code, converted at build time. A hardware layer written for the
Amiga stands in for the Genesis video chip, pads, Z80 and sound chip. The Genesis sources are
not changed, so `main` still rebuilds the cartridge byte for byte.

## Requirements

- An Amiga with the AGA chipset (A1200, A4000, CD32 with a keyboard and fast RAM, or an emulator).
- A 68020 or better. The renderer uses 68020 instructions.
- 2 MB of chip RAM and at least 2 MB of fast RAM. The game takes about 1.5 MB of any memory and
  about 1.5 MB of chip RAM, so it does not fit in a stock 2 MB A1200.
- Kickstart 2.0 or later (3.x, or the AROS ROM, have been tested in FS-UAE and vAmiga).
- PAL or NTSC. The game runs at the display's rate, as on the console of that region: 50 game
  frames a second on a PAL Amiga (the speed of a PAL Mega Drive, a sixth slower than an NTSC
  Genesis), 60 on NTSC. `F8` switches between the two.

Speed: on a stock 14 MHz A1200 with fast RAM, gameplay is shown at a steady 25 frames a second
on PAL most of the time (each frame on the screen for 2 vertical blanks; heavy moments drop to
about 17), measured in FS-UAE, cycle exact. The game itself always runs at full speed; it is
the screen updates that are fewer. `F6` lifts the cap: about 30 frames a second on average,
but unevenly paced (a frame shows for 1 or 2 vertical blanks), which looks less smooth.

## Running

Copy `output/amiga/NHL94`, `NHL94.info` and `nhl94.game` into the same directory. Start `NHL94`
from a Shell, or double click its icon. `NHL94` is a small launcher that loads `nhl94.game`. The
game takes over the machine and gives it back when you quit. If it cannot run (no AGA, no 68020,
not enough memory, `nhl94.game` missing), a requester says why.

In an emulator, use the hard drive image `output/amiga/nhl94.hdf`. The build makes it when
`xdftool` is installed (`pip install amitools`). It boots straight into the game.

Each build is numbered: the number of commits on the branch (`git rev-list --count HEAD`). The
images are also written as `nhl94-b<number>.hdf` and `.adf`, their volumes are named
`NHL94-b<number>`, and `version NHL94` in a Shell shows the number and the commit (with a `+`
if the sources differed from it).

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

`Esc` quits to the Workbench and writes the save file. `F6` switches between a steady 25 frames
a second and as many as there is time for. `F7` switches the Amiga's audio low-pass filter (on
at start, like the output filter of a model 1 Genesis). `F8` switches the game between 50 and
60 frames a second.

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
- `-DPROFILE=1` samples the program counter 2000 times a second and writes `nhl94.prof` on
  exit; `amiga/tools/amiprof.py` turns it into a list of routines (time spent waiting for the
  blitter is put on the caller), the frame rate since `F9` was pressed, how many frames were
  on the screen for 1, 2, 3 ... vertical blanks, how many vertical blanks passed from each
  frame's game state to its showing, the sound's delay at the end, and the time spent in the
  game, its vblank code and the renderer (counted on the CIA-B clock at every switch, so time
  with interrupts off, which the PC samples cannot see into, is counted too).
- `-DRDPACE=1` starts with the frame rate cap off (as `F6`).
- `-DSTATS=1` counts renderer work for the test harness (`NHL_STATS=1`).
- `-DCROWD=1` draws the animated crowd in the stands, which is left out by default (about 4
  of the 37 sprites a frame in play, about 9% of the renderer's time).
- `-DMENUMUSIC=1` plays the menu songs (title, end of period, scouting report), which are off
  for now: they do not sound right yet.
- `-DVERIFY=1` makes the renderer check its scroll buffers every frame: every part of plane B
  not listed for repair must match the bitmap. It also compares every name table each frame
  and fails if one changed that the write marks said could not have. The test harness reports
  the first failure.

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
  hardware scrolls it: the bitplane pointers, a fetch that starts up to 63 pixels early and the
  BPLCON1 delay. The planes are fetched 64 bits at a time (FMODE 3), which leaves the most of
  the chip bus to the blitter and the CPU. Only what was drawn over it two frames ago and the
  cells the game changed are blitted back from the bitmap (a dirty map per buffer, 16 pixels
  by 4 lines a bit; `-DDLS=n` makes it 2^n lines). Other
  screens get plane B blitted in at the scroll position. Plane A and the window are an overlay
  layer with masks. On the 256 pixel wide screens (the rink) the overlay's high priority part,
  the score and clock boxes, is shown by up to 4 attached pairs of AGA 64 pixel wide hardware
  sprites (15 colours of their own) instead of being blitted every frame; only the bytes of a
  cell the game changes are made again (a clock digit), and a whole new set is built into the
  second of two copies, so the frames queued go on showing the old one. If it does not fit
  (wider, more than 4 groups of 8 columns, 64 lines or 15 colours) it is blitted as before.
  Sprites are blits of images kept in a cache in chip RAM (built once from
  the tiles, used again until a tile of theirs changes); only the box of an image's pixels is
  blitted and marked for the restore (found when it is built: a fifth of the words of the
  whole sprites, and of what is restored), and plane B's high priority cells are
  blitted back over what was drawn under them (found by moving the screen cells something low
  was drawn on to plane columns and ANDing them with a bitmap of those cells); the CPU queues a whole frame for the blitter
  without waiting. A chunky renderer with
  chunky-to-planar conversion covers line scroll and cell scroll. The copper sets the 64 colours
  and the display window, and frames are triple buffered. A frame is drawn from a snapshot of
  the VDP registers, scroll and sprite list taken when it starts, with the changed tiles
  converted in the same game frame (the game runs several of its frames meanwhile; without it,
  players could be from a later game frame than the rink). A frame's copper list is handed
  over by a marker queued after its blits (the level 3 interrupt takes it when the queue gets
  there) and set at the first vertical blank that keeps the frame before on the screen for 2,
  so the CPU goes on to the next frame while the blitter finishes. A new frame is begun every
  2 game frames at most. A buffer is drawn into again only once the frame after it has been
  on the screen for a vertical blank (counted by the same interrupt). When the game runs at the
  display's rate (50 Hz PAL, 60 Hz NTSC) its frames are timed by the vertical blank too, so
  they cannot drift against the frames shown; otherwise by a CIA timer. The game's own
  interrupt masks (5, 3: the Genesis line interrupt) are lowered to 0 in conversion, so the
  blit queue is fed while the game's code runs. The renderer only reads which name tables the
  game may have written (DMA, fills and copies mark the blocks they change, data port writes
  the block they begin in) and compares only those with its copies.
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
  keeps their pitch. A frame's picture reaches the screen a few vertical blanks after the game
  made it (drawn, then queued behind the frames before it: 3 with the 25 fps cap, 2 to 3
  without), so the sound would come before what it goes with. Each game frame's sound commands,
  with the Z80 RAM bytes they use, go into a delay line and are carried out that much later;
  the renderer measures the picture's delay at every frame shown and keeps the sound's delay
  at its mean, changing it only when it is off by 3/4 of a frame.
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
`NHL_FIXEDHV=1` gives the game's reads of the beam position (which it uses as random numbers)
values that depend only on the frame and the read's number in it, so every build plays the
same game (with the real beam position the renderer's speed changes the game's course).
`amiga/harness/playcost.sh [from] [end]` uses it: Start is pressed only until the game
begins, then the renderer's harness cycles per frame drawn are counted over uninterrupted
play, by routine, to compare builds. `NHL_RAMDUMP=file:from:to` writes the Genesis RAM every
frame. `NHL_BLITKINDS=1` splits the blitter's time from frame 1700 by which of the renderer's chip
buffers each blit reads and writes (plane B restores, sprites, overlay, clears). The harness'
Start presses pause and resume the game every 120 frames, and each resume restores whole
screens, so these are not the steady figures of play. For those, a build with `-DSPRLOG=1`
logs every sprite blit (`NHL_DBGPORT=1`), and `amiga/harness/rstsim.py log` replays the log:
the words a frame for the sprites and for restoring under them, whole boxes or trimmed, and
dirty maps of 8 to 1 lines, all on the same frames (builds that differ play differently: the
game's random numbers depend on its timing).

`amiga/tools/uaerun.sh` runs the build in FS-UAE (A1200, AROS ROM by default) on a virtual X
display, presses keys at given times and takes screenshots. Add `fast_memory = 8192` with
`UAEEXTRA`.

## Known limits

- Speed on an unexpanded 68020 (above).
- Only 4 sound voices for the Genesis' 6, so big chords lose notes. FM sounds are samples, so
  notes do not change timbre as they decay, and the LFO, detune and SSG-EG are left out.
- No 4 way play.
