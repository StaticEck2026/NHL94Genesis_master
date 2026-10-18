# NHL 94 for the Amiga 1200 (AGA)

This directory builds NHL 94 as an Amiga program from the Genesis disassembly in `src/`. The
game code is the Genesis 68000 code, converted at build time. A hardware layer written for the
Amiga stands in for the Genesis video chip, pads, Z80 and sound chip. The Genesis sources are
not changed, so `main` still rebuilds the cartridge byte for byte.

## Requirements

- An Amiga with the AGA chipset (A1200, A4000, CD32 with a keyboard and fast RAM, or an emulator).
- A 68020 or better. The renderer uses 68020 instructions.
- Fast RAM. The game takes about 1.5 MB of any memory and about 0.5 MB of chip RAM, so it does not
  fit in a stock 2 MB A1200.
- Kickstart 2.0 or later (3.x, or the AROS ROM, have been tested in FS-UAE).
- PAL or NTSC. The game runs its 60 Hz Genesis timing on either.

Speed: the game logic alone needs about half of a stock 14 MHz 68020. On a stock A1200 with fast
RAM, gameplay runs at about 5 frames a second; the menus are fine. An accelerator is
recommended: a 68030 at 50 MHz manages about 30 frames a second. The renderer's time goes
mostly on the sprites and the blitter.

## Running

Copy `output/amiga/NHL94`, `NHL94.info` and `nhl94.game` into the same directory. Start `NHL94`
from a Shell, or double click its icon. `NHL94` is a small launcher: it reserves the 64 KB of
memory where the game keeps the Genesis work RAM, then loads `nhl94.game`. The game takes over
the machine and gives it back when you quit.

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

`Esc` quits to the Workbench and writes the save file. The 4 way play adaptor modes are not
available.

## Building

Needs Python 3, Node.js (for the repository's asset extraction pre-step, see the main README) and
vasm (`vasmm68k_mot`, Motorola syntax; on the `PATH`, in `$VASM`, or at `/opt/amiga/vasm`).

    amiga/build.sh

writes `output/amiga/nhl94.game`, `output/amiga/NHL94` (the launcher) and `NHL94.info`. With
`VASMFLAGS`:

- `-DSHOWFPS=1` shows the frame rate in the corner (F10 toggles it).
- `-DPROFILE=1` samples the program counter 60 times a second and writes `nhl94.prof` on exit;
  `amiga/tools/amiprof.py` turns it into a list of routines.
- `-DSTATS=1` counts renderer work for the test harness (`NHL_STATS=1`).

## How it works

`amiga/tools/convert.py` copies `src/` to `output/amiga/src` with these changes:

- The Genesis RAM (`$FFFF0000`) moves to a 64 KB window at `RAMBASE` (`amiga.i`). The 16-bit
  absolute addresses the game uses for RAM become 32-bit addresses. Word pointers that are
  sign-extended into address registers are fixed up after they are loaded.
- Writes to the video chip ports go to the emulated VDP (`vdp.asm`): VRAM, CRAM and VSRAM in
  memory, and DMA, fills and copies done by the CPU. Writes also mark which tiles changed.
- Z80 bus polling, pad port reads and wait loops are rewritten. A wait loop calls `hal_idle`,
  which runs the renderer while the game waits for its next frame.
- vasm syntax: macros, local labels, `incbin` paths and other small differences.

`amiga/tools/patches.py` makes the few changes that need code written by hand: the sound
handshake, the pad reader and the save RAM.

The hardware layer:

- `hal.asm`: start-up, interrupt vectors, the 60 Hz CIA timer that stands in for the Genesis
  vertical blank, and the two contexts (the game, and the renderer it runs while the game waits).
- `os.asm`: takes the machine from the OS and gives it back; keeps the OS's memory in the
  `RAMBASE` window; loads and saves `NHL94.sav`.
- `render.asm`: draws the emulated VDP state in 64 colours on 6 interleaved bitplanes. Tiles are
  cached in planar form. Plane B is kept as a bitmap and blitted with the scroll. Plane A and the
  window are an overlay layer with masks. Sprites are drawn by the CPU. A chunky renderer with
  chunky-to-planar conversion covers line scroll and cell scroll. The copper sets the 64 colours
  and the display window, and frames are double buffered.
- `input.asm`: joysticks, CD32 pads and the keyboard, read as two 3 button pads.
- `sound.asm`: the four Paula voices in place of the Z80, YM2612 and DAC. The game's own 68000
  sound driver runs unchanged. `sound.asm` reads the commands the driver writes for the Z80:
  key on, key off, frequency, volume and patch per FM channel, and the PCM start, rate and volume.
  The 32 FM patches are rendered to samples at build time by `amiga/tools/fmrender.py`, a model
  of the YM2612. Each patch has an attack and a loop at each pitch band it is used at. The rest
  of each envelope is a volume envelope at run time. The 6 Genesis channels share 4 voices: a new
  note takes a free voice, else the quietest released one, else the oldest.
- `stub.asm`: the launcher.

## Testing without an Amiga

`amiga/harness` is a Linux test harness. It runs the build on the Musashi 68020 core with just
enough of the Amiga custom chips (blitter, copper list, Paula):

    make -C amiga/harness MUSASHI=/path/to/Musashi
    amiga/harness/regress.sh /tmp/shots

It plays through the attract mode and into a game by pressing Start. At a few frames it compares
the Amiga screen with a reference Genesis renderer (`vdpref.c`) and prints any frame whose pixels
differ. `NHL_WAV=out.wav` writes the sound; `NHL_AUDLOG=1` logs every sample start.

`amiga/tools/uaerun.sh` runs the build in FS-UAE (A1200, AROS ROM by default) on a virtual X
display, presses keys at given times and takes screenshots. Add `fast_memory = 8192` with
`UAEEXTRA`.

## Known limits

- Speed on an unexpanded 68020 (above).
- Only 4 sound voices for the Genesis' 6, so big chords lose notes. FM sounds are samples, so
  notes do not change timbre as they decay, and the LFO, detune and SSG-EG are left out.
- No 4 way play.
