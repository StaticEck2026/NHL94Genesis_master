# NHL 94 for the Amiga 1200 (AGA)

This directory builds NHL 94 as an Amiga program from the Genesis disassembly in `src/`. The
game code is the Genesis 68000 code, converted at build time. A hardware layer written for the
Amiga stands in for the Genesis video chip, pads, Z80 and sound chip. The Genesis sources are
not changed, so `main` still rebuilds the cartridge byte for byte.

## Requirements

- An Amiga with the AGA chipset (A1200, A4000, CD32 with a keyboard and fast RAM, or an emulator).
- A 68020 or better. The renderer uses 68020 instructions.
- 2 MB of chip RAM and at least 2 MB of fast RAM. The game takes about 1.7 MB of any memory (fast
  RAM where there is some: its code, its data and the Genesis RAM window) and about 1.6 MB of
  chip RAM (and up to 256 KB more for sprite images if it is free: fewer are built again), so
  it does not fit in a stock 2 MB A1200. The launcher loads it a part at a time
  (each part's compressed bytes, then the next), so that is about the most it takes. Kickstart
  leaves nearly all of 2 MB of fast RAM free, so it should fit there (not tested: the tests here
  use the AROS ROM, which keeps some 0.7 MB of the fast RAM for itself, so with it the game needs
  4 MB).
- Kickstart 2.0 or later (3.x, or the AROS ROM, have been tested in FS-UAE and vAmiga).
- PAL or NTSC. The game runs at the display's rate, as on the console of that region: 50 game
  frames a second on a PAL Amiga (the speed of a PAL Mega Drive, a sixth slower than an NTSC
  Genesis), 60 on NTSC. `F8` switches the display between 50 and 60 Hz (AGA shows either on any
  Amiga, if the monitor takes it), and the game's rate with it.

Speed: on a stock 14 MHz A1200 with fast RAM (FS-UAE, cycle exact, the benchmark game of a
`-DBENCH=1` build), the screen is updated as often as there is time for, up to every vertical
blank: at 50 Hz 49.3 frames a second (all of them on the screen for one vertical blank: the
rest are frames with nothing new to draw), at 60 Hz 57.4 a second (98% for one); the others
are heavy moments (many new animation frames at once, a scene change). The game itself
always runs at full speed. `F6` caps the screen at a steady 25 or 30 frames a second instead
(98 to 99% of them on the screen for exactly 2 vertical blanks).

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
- **FS-UAE, WinUAE, Amiberry**: an A1200 with `fast_memory` of 2 MB or more (4 MB with the AROS
  ROM) and `nhl94.hdf` as
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

`Esc` quits to the Workbench and writes the save file. `F6` switches between as many frames a
second as there is time for (up to the display's 50 or 60, the start) and a steady 25 or 30.
`F7` switches the Amiga's audio low-pass filter (on at start, like the output filter of a model
1 Genesis). `F8` switches the display between 50 and 60 Hz and the game between 50 and 60 frames
a second with it.

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
- `-DRDPACE=2` starts with the frame rate capped at 25 or 30 a second (as `F6`).
- `-DBENCH=1` makes a benchmark build that plays the same game every run and every build:
  everything is counted in the game's waits for a frame (one a game frame, however late the
  frames come): its random numbers (its reads of the beam position) come from that count,
  Start is pressed at the test harness' counts (into a game from the attract mode), and with
  `-DPROFILE=1` the frame rate count starts at 2000 (as `F9`) and the game quits at 6000
  (`BENCHSTART`, `BENCHEND`); the renderer does not take the game's time when it runs long.
  Delete `NHL94.sav` before each run: the game reads it. A game tick that comes while the
  game runs, or while the renderer has the CPU after the game already had a tick in this wait
  (a frame drawn over more than a vertical blank), waits for the game's next wait (`hal_idle`,
  at most `BENCHTP` ticks): the game never sees two ticks pass at once (it would move its
  players two frames' worth), so its course does not depend on the renderer's timing, and
  runs of one build give the same frame rate to a hundredth (FS-UAE, several at once too), so
  one run tells two builds apart. The profile has a sum at each tick of the places and speeds
  of the players and the puck (`bench_tlog`: no pointers in it, so it compares across builds
  and load addresses; `-DBENCHDUMP=n`: the whole RAM at tick n) to find where two runs part
  (`-DBENCHFULL=1`: a sum of all of the game's RAM but the stacks' last 1 KB instead; FS-UAE
  can load the game at another address each run, which changes the code pointers in its RAM,
  and so that sum, but not the game). Builds can still play different games (the course can
  change before play starts), so compare their sums before their frame rates. The renderer is linked after the game's code, so a change to
  it does not move the game's code (or the code pointers in its RAM). With `-DMEMBENCH=1` the profile also has the colour
  clocks of 1024 writes to chip memory, fast memory and a custom register, 1024 chip reads and
  256 chip writes while a blit runs (measured at count 2001).
- `-DPROFILE=1` also logs the frame pipeline's events with the time (a frame begun and ended,
  waiting for a buffer, the show queued, the queue at it or held, the copper list set, vertical
  blanks, game ticks), written after the profile (`prof_ev`).
- `-DPROFMARK=1` (with `-DPROFILE=1`) also puts each frame's start and end of drawing among the
  PC samples, so `amiga/tools/amilate.py LISTING nhl94.prof` can tell what the frames shown
  late (2 or more vertical blanks after the one before) spent their time on, against the frames
  on time, and list each late frame's busiest renderer routines.
- `-DSTATS=1` counts renderer work for the test harness (`NHL_STATS=1`).
- `-DCROWD=1` draws the animated crowd in the stands, which is left out by default (about 4
  of the 37 sprites a frame in play, about 9% of the renderer's time).
- `-DMENUMUSIC=1` plays the menu songs (title, end of period, scouting report), which are off
  for now: they do not sound right yet.
- `-DVERIFY=1` makes the renderer check its scroll buffers every frame: every part of plane B
  not listed for repair (nor drawn over by the blits listed for the frame) must match the
  bitmap. It also compares every name table each frame
  and fails if one changed that the write marks said could not have (or, written only by DMA,
  fills and copies, outside the blocks they marked). The test harness reports the first
  failure.

## How it works

`amiga/tools/convert.py` copies `src/` to `output/amiga/src` with these changes:

- The Genesis RAM (`$FFFF0000`) moves to a 64 KB window at `RAMBASE`. The 16-bit absolute
  addresses the game uses for RAM become 32-bit addresses. Word pointers that are sign-extended
  into address registers are fixed up after they are loaded. The window must be 64 KB aligned
  (the game keeps RAM pointers as words), which AmigaDOS cannot do, so `RAMBASE` is a hunk of
  its own: `amiga/tools/ramrel.py` lists every place that holds its address, and at start the
  game takes an aligned block (in fast RAM if there is some) and moves those addresses there.
- Writes to the video chip ports go to the emulated VDP (`vdp.asm`): VRAM, CRAM and VSRAM in
  memory, and DMA, fills and copies done by the CPU. Writes also mark which tiles changed. The
  players' sprite tiles (`Spritetiles`) are native instead: converted to planar rows in place
  at start, and a DMA from them copies nothing, it only notes where each tile's data is (the
  renderer takes it from there). The test harness rebuilds those tiles from
  `Extracted/NHL94/Graphics/Spritetiles.bin` for its reference renderer. The players are native
  objects too: `addframe2`, which writes a player's frame as a few sprites in a row of the
  sprite table, notes the range and the frame (with its flips and palette); the notes go with
  the table when it is sent, and the renderer draws each such object as one image, built once
  from the native tiles (its sprites in their order, at any pixel offsets: one at a whole byte
  over none drawn before it goes straight in, the others through bit fields), kept in the sprite
  image ring and found by its frame: one blit an object instead of one a sprite. An object
  drawn the same in the frame before (the same frame, place, scroll and image in its place of
  the sprite list) takes that blit, its box and its cover again instead of being placed and cut
  anew (about half of them in play).
- Z80 bus polling, pad port reads and wait loops are rewritten. A wait loop calls `hal_idle`,
  which runs the renderer while the game waits for its next frame.
- vasm syntax: macros, local labels, `incbin` paths and other small differences.

`amiga/tools/patches.py` makes the few changes that need code written by hand: the sound
handshake, the pad reader and the save RAM.

The hardware layer:

- `hal.asm`: start-up, interrupt vectors, the 50 / 60 Hz CIA timer that stands in for the Genesis
  vertical blank, and the two contexts (the game, and the renderer it runs while the game waits).
- `os.asm`: takes the machine from the OS and gives it back (the 68020's instruction cache
  on, a data cache off while the game runs); keeps the OS's memory in the `RAMBASE` window;
  loads and saves `NHL94.sav`.
- `render.asm`: draws the emulated VDP state in 64 colours on 6 interleaved bitplanes. Tiles are
  cached in planar form. Plane B is kept as a bitmap. On the rink each screen buffer holds the
  whole of plane B (512 x 256, its top 224 lines twice for the vertical wrap) and the display
  hardware scrolls it. A rink cell whose entry or tile changes is converted into the bitmap
  only when it is within 8 lines and 16 pixels of the screen, a few a frame within 48 pixels,
  otherwise once it comes that near: the game writes each new row 2 rows ahead of the screen
  (spread over frames instead of one) and animates a tile at the plane's right edge (not
  converted while out of sight): the bitplane pointers, a fetch that starts up to 63 pixels early and the
  BPLCON1 delay. The planes are fetched 64 bits at a time (FMODE 3), which leaves the most of
  the chip bus to the blitter and the CPU. Only what was drawn over it two frames ago and the
  cells the game changed are blitted back from the bitmap (a dirty map per buffer, 16 pixels
  by 8 lines a bit; `-DDLS=n` makes it 2^n lines, 1 or 2: finer rows restore fewer words
  but take more blits, and each blit costs the CPU its copper block). A buffer keeps what was
  drawn into it, and in a still scene (a faceoff, a goal) nearly all of it is the same again,
  in play often much of it: so a frame's cut blits (sprites, overlay, plane B's high priority
  cells) are first listed, each with its box of the dirty map, and matched in order with the
  list of the buffer's last frame (the same pointers, sizes, shift and image: an image is
  known by its place in the image ring's history). What the last frame drew and this one does
  not is restored with the changed cells, and only the blits that are new, over what was
  restored or over a blit drawn before them in this frame are drawn. A faceoff takes the
  blitter some 15k cycles a frame instead of 220k, play about 40% less (harness). A sprite the
  CPU draws (cut by the screen's left margin), a full list or an image written over in the ring
  ends the listing for that frame: all is restored and drawn as it comes. Other
  screens get plane B blitted in at the scroll position. Plane A and the window are an overlay
  layer with masks, cut into the screen as rectangles (runs of columns with cells in each band
  of 8 lines, a run the same in the bands below one rectangle; made again when a cell adds a
  column). Drawn anew (more than a few of its cells changed), only the bands its cells covered
  are cleared first: by the CPU for a little (a score box), else their lines by the blitter
  (not all 190 KB of image and masks, which took the blitter some 3 frames). On
  the 256 pixel wide screens (the rink) the overlay's high priority part,
  the score and clock boxes, is shown by up to 4 attached pairs of AGA 64 pixel wide hardware
  sprites (15 colours of their own) instead of being blitted every frame; only the bytes of a
  cell the game changes are made again (a clock digit). Each screen buffer shows its own copy
  of the sprites, brought up to date when its frame is made (the bands of 8 lines changed since
  its last copy), so a frame queued before a change keeps the HUD of its own moment (a clock
  digit changes with the picture). If it does not fit
  (wider, more than 4 groups of 8 columns, 64 lines or 15 colours) it is blitted as before.
  Sprites are blits of images kept in a cache in chip RAM, built once from the tiles (in fast
  memory, then copied in longs; rows without a spare word for the shift: the blit reads past
  the row and its last word mask clears what it read). An image
  whose tiles a DMA sent from consecutive addresses of the program (the players' animation
  frames: the VDP layer notes each tile's source address) is found by that address, size,
  flips and palette, so a frame sent again, or the same frame on another player of the team,
  is not built again; other images are used until a tile of theirs changes. The images go
  round a ring of chip RAM: 256 KB in the program, and a second part of up to 256 KB more
  taken at the start from the chip memory left (32 KB is left over); an image is built again
  once the ring has come round to it. The table of the images, and the objects' (below),
  keep a key in either entry of a pair (the one built longer ago is written over), so two
  keys of the same place both stay. Changed tiles are
  converted to planar form at once only if plane A, B or the window uses them; the others
  (sprites' tiles) when an image of them is built, which the cache mostly spares. Only the box
  of an image's pixels is
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
  over by a marker queued after its blits (the copper stops there and calls the level 3
  interrupt) and set at the first vertical blank that keeps the frame before on the screen for 2,
  so the CPU goes on to the next frame while the blitter finishes. A new frame is begun every
  2 game frames at most. A buffer is drawn into again only once the frame after it has been
  on the screen for a vertical blank (counted by the same interrupt). When the game runs at the
  display's rate (50 Hz PAL, 60 Hz NTSC) its frames are timed by the vertical blank too, so
  they cannot drift against the frames shown; otherwise by a CIA timer. At the full frame rate,
  when the game waits for its next frame and the renderer has drawn the last one, that next
  game frame is run at once rather than at the vertical blank (at most one ahead: that
  vertical blank then runs none), so the game's work goes into time the CPU would spend idle
  and a frame that takes long to draw does not make the next one late. Its sound commands go
  into the sound's delay line then and are played from vertical blanks as ever. The game's own
  interrupt masks (5, 3: the Genesis line interrupt) are lowered to 0 in conversion, so the
  blit queue is fed while the game's code runs. The renderer only reads which name tables the
  game may have written (DMA, fills and copies mark the blocks they change, data port writes
  the block they begin in) and compares only those with its copies: a table written by a
  data port write all of it, one written only by DMA, fills and copies only the 32 byte blocks
  they changed (the game clock's 5 words: 8 longs compared instead of 1024).
  The colours are AGA 24 bit colours (each written as high then low nibbles) at the levels the
  Genesis puts out, which are not a straight line from 0 to 255; Extra Half-Brite is switched
  off so all 64 registers are used.
- `input.asm`: joysticks, CD32 pads and the keyboard, read as two 3 button pads.
- `sound.asm`: the four Paula voices in place of the Z80, YM2612 and DAC. The game's own 68000
  sound driver runs unchanged. `sound.asm` reads the commands the driver writes for the Z80:
  key on, key off, frequency, volume and patch per FM channel, and the PCM start, rate and volume.
  All audio is 8 bit, played as fast as Paula plays (a period of 124: about 28.6 kHz). The 32
  FM patches are rendered to samples at 20000 Hz at build time by `amiga/tools/fmrender.py`, a
  model of the YM2612. Each patch has an attack and a loop at each octave band it is used at, so
  every note plays at 14.1 to 28.3 kHz. The synthesis runs at 8 times the sample rate and is low-pass
  filtered before it is decimated, as FM harmonics above the sample rate would otherwise fold
  back as harsh noise. The rest of each envelope is a volume envelope at run time. The 6 Genesis channels share 4 voices: a new
  note takes a free voice, else the quietest released one, else the oldest. The PCM sounds
  (crowd, shots, checks) are made into samples at build time too, by `amiga/tools/pcmrender.py`,
  at the game's own rates (6.5 to 12 kHz); the glass, which the game plays at 29 kHz, faster
  than Paula, is resampled to 28.6 kHz and played at a period that keeps its pitch. A frame's
  picture reaches the screen a few vertical blanks after the game made it (drawn, then queued
  behind the frames before it: 2 to 3 at full speed, 3 with the 25 fps cap), so the sound
  would come before what it goes with. Each game frame's sound commands, with the Z80 RAM bytes
  they use, go into a delay line and are carried out that much later; the renderer measures
  the picture's delay at every frame shown, from the game tick that gave the frame its state
  (whose commands are the frame's) to its showing, and half a frame more for the beam to come
  down to the middle of the screen, and keeps the sound's delay at its mean, changing it only
  when it is off by 3/4 of a frame.
- The pictures of the EA Sports, title and game setup screens (44 KB) are not kept in the
  program: `amiga/tools/fepack.py` deflates each screen's into a block (19 KB in all), and when
  the screen begins (`fe_open`, called where the game's code for the screen begins) its block
  is inflated into a window at the top of the sprite image cache, which the cache leaves alone
  while the window is held (the cache emptied, with no frame half drawn, each time it changes
  size). A game's start gives the window back (`fe_close`); the screen shown again inflates its
  pictures again. The game's own copies of the PCM sounds (77 KB) are left out too: only their
  addresses are used, the sounds are played from their samples in chip RAM.
- `stub.asm`: the launcher. It runs `NHL94.pak` when it is there (the floppy): it reads the
  file, allocates each hunk as AmigaDOS would, inflates it in place (`inflate.i`, a 68000 deflate
  decoder with a lookup table for codes of up to 9 bits) and applies the relocations. Otherwise
  it has AmigaDOS load `NHL94.game`.

The copper starts the blits. The renderer writes each blit into a ring of copper code in chip
memory (`rd_bq_go`): a wait for the blitter, then moves to the blitter's registers (BLTSIZH
last starts it) and to COP2LCL. Each display list ends by jumping to COP2LC, so after a
vertical blank the copper goes on where it was (a block cut short runs again, which a blit
allows). So the CPU takes no interrupt for a blit and the blitter does not wait for one. A
CPU write to chip memory takes about 0.7 us, twice that while a blit runs (FS-UAE), and the
68020 runs some 7 cycles an instruction from fast memory, so a block moves only the registers
its blit uses (BLTSIZV always: the blitter counts it down), and the two kinds of blit there are
most of (the cuts: sprites, overlay, plane B fixups; the restores) write their blocks
themselves with constants where they can (a run of restores sets BLTCON0 to BLTALWM once, so
does a run of unshifted cuts). After
the last block the copper stops, setting INTREQ's SOFT bit (no interrupt) first; the next block
written there takes its place, and the CPU starts the copper again (COPJMP2) if SOFT says it
stopped. A show marker sends the copper to a parking place that sets DSKBLK and calls the level
3 interrupt (COPER), which sets the copper list when due and starts the copper again after the
marker; a vertical blank while it waits there calls again, which is told apart by DSKBLK.
The CPU never starts the copper near a vertical blank (the end of the last line to the start
of line 0), so it never cuts a display list short. The test harness runs the copper too:
`NHL_COPSTRESS=n` restarts it at one in n of its instructions on average, as a vertical
blank could, to check the ring survives that anywhere. `NHL_CHIPWAIT=n` charges n more cycles for each
CPU access to chip memory or a custom register (8 is about what FS-UAE's A1200 takes while
the blitter runs), so the renderer's cycles weigh its chip writes as the Amiga does. The
harness gives the sprite image ring a second part as the launcher would, 256 KB
(`NHL_SCX=bytes`, 0 for none). `NHL_BLITFRAMES=file` writes a line for each frame shown: the game frame and the
blitter's cycles and blits since the frame before by kind (copies A to D, cookie cuts, D only,
other), with NHL_DETERM the same game every build. `NHL_BLITLOG=file` writes every blit: the
frames shown so far, the game frame, BLTCON0, BLTCON1, the first and last word masks, the A, B,
C and D pointers (0: not used), words, lines and its time. `NHL_HAZARD=n` reports (up to n)
blits that read a word the CPU wrote after the blit was queued (after it wrote the copper's
move that starts it), with the pc of that write and of the queueing: what a queued blit reads
has to stay as it was until it has run, a vertical blank's restart included. (A cookie cut's
last word of a row, whose mask is 0, is not reported: what it reads is never used.) Game ticks
are run before their vertical blank (hal_tick_early) only with `NHL_EARLY=1`: the reference
picture is the VDP at the frame's end, which could then be part way into the next game frame.

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
`NHL_PROF=file` writes a PC sample every 1000 cycles (the instruction running then), which
`amiga/harness/rdcost.py` sums.
`NHL_FIXEDHV=1` gives the game's reads of the beam position (which it uses as random numbers)
values that depend only on the frame and the read's number in it. `NHL_DETERM=1` does that and
more, so that every build plays exactly the same game: the renderer's own work takes none of
the game's time (a frame ends once the game and its tick have run their cycles; the
renderer's and the blit queue interrupt's do not count), a frame also ends whenever the CPU
would only wait (the renderer for a vertical blank, the blitter or room in its queue, or
giving way; the game waiting with nothing to draw), so each of the game's wait loops goes round
once a frame however long the renderer took, blits are done at once, and no vertical blank is
lost or given to the renderer. The CPU core is built with its instruction hook and its
interrupt acknowledge callback for it. With `NHL_DETBLIT=1` as well, blits take their time
(the CPU's work and the blitter's overlap, as on the Amiga; a wait of the renderer for the
blitter ends the blit at once), but the game's course is no longer the same for every build:
the renderer's waits for a free buffer then end frames at other points.
`amiga/harness/playcost.sh [from] [end]` uses it: Start is pressed only until the game
begins, then the renderer's harness cycles per frame drawn are counted over uninterrupted
play, by routine, to compare builds; it prints a fingerprint of the game at the end, which is
the same for two builds that played the same game. The renderer draws every second game frame, the odd or
the even ones depending on its timing earlier on, and the work can differ between the two:
`NHL_PHASE=0` or `1` sets which (from frame 2000), and playcost.sh measures both. `NHL_RAMDUMP=file:from:to` writes the Genesis RAM every
frame. `NHL_FREELOG=file` (with `NHL_DETERM`) writes the renderer's cycles each frame, for the
spread of the cost per frame drawn (the PC samples of `NHL_PROF` carry their frame too). `NHL_BLITKINDS=1` splits the blitter's time from frame 1700 by which of the renderer's chip
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
