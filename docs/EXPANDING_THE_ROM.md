# Expanding the ROM

`main` is a faithful disassembly of the retail cartridge: a stock build matches `lst/nhl94.bin`. It keeps only changes that emit the same bytes (equates, labels, assemble-time checks, build tools). Fixes that a bigger ROM or a bigger league needs are described here and belong on a mod branch, not on `main`.

## What main already does for you

- `tools/fixrom.js` runs after `fixopcodes`. It pads the image with $FF to the next size of 1MB, 1.5MB, 2MB or 4MB, writes the header ROM end ($1A4), then writes the boot checksum (the `cmpi.l` immediate in `ValidationRoutine`). A stock build stays 1MB and byte-identical.
- `src/nhl94.asm` fills to 1MB. Includes placed after that fill start at $100000, so new data does not move any retail code.
- `src/shortcalls.inc` (included last, emits nothing) stops the build if a routine the retail code calls with a short `jsr`/`jmp (x).w` moves past $7FFF. `tools/build.js` then stops at the assemble step and prints the routine, the files that call it, and the fix below.
- `NumTeams` / `NumPlayoffTeams` (`src/stubinc/equals.inc`) drive the option limits, the random team range and the playoff clamp, and every per-team table checks its length while assembling.
- `CHECKSUM=0` skips the boot check (`build:dev`); `REV` picks retail or Rev A.

## Short jumps

The retail code reaches eleven routines with absolute short calls, which only reach $0000-$7FFF: `StartGame`, `restoreteams`, `ResetClock`, `GetPeriodTime` (twice), `StartPer`, `DoGameFrame`, `updatecrowdf`, `SetupPauseScreen`, `InitMenuState`, `DrawMenuScreen` and `HandleMenuInput` (callers in setup94, penalty94, collide94, data94 and video94). `menu94` ends just below $8000, so about 375 bytes of growth in the files before it is enough to break them. `bra.w Begin` in `main94.asm` has the same kind of limit.

Fix, in order of preference:

1. Put new data after `menu94`, ideally after the 1MB fill in `src/nhl94.asm`. Nothing below $8000 moves.
2. If something below $8000 has to grow (for example `TeamList` or a team record in `teamdata94.asm`), change the affected calls to `jsr (name).l` / `jmp (name).l` on your mod branch (2 more bytes each), and `bra.w Begin` to `jmp (Begin).l` if it is out of range.

## Past 2MB: backup RAM and bank switching

The save chip sits at $200001-$203FFF (odd bytes). A ROM up to 2MB ends at $1FFFFF and needs no mapper. Anything larger overlaps the save chip:

- The game reads and writes save RAM directly at $200000 (`sram94.asm`). With ROM there, the console reads ROM instead of the chip. A cartridge (or emulator) with the Sega mapper exposes the chip only while bit 0 of $A130F1 is set, so every save access needs `move.b #1,($A130F1).l` before it and `clr.b ($A130F1).l` after it (`ReadSRAM`, `WriteSRAM`, and the two InitSaveRAM test loops). That is a mod-branch change.
- Past 4MB you need SSF2-style bank switching (the bank registers at $A130F3-$A130FF), so the code has to page data in. `tools/fixrom.js` refuses images larger than 4MB.
- Keep data above $200000 out of anything the game reads while save RAM is mapped in.

## Save RAM layout

The save layout is plain equates at the retail addresses (`src/stubinc/equals.inc`): crowd records `CrowdRecBase` ($B60, `NumTeams` blocks of 16 bytes), the records block `TeamRecBase` ($D20, eight 16-byte records), the name log `NameLogBase` ($DA0) and line data `LineDataBase` ($1EF6). The 28 retail teams fill the crowd records exactly up to $D20.

A 29th team overlaps the records block, and the build stops with "The crowd records run into the records block". On a mod branch, move `TeamRecBase` to `CrowdRecEnd` and `NameLogBase` to `TeamRecBase+RecordsBytes` (there is room below $1EF6), and expect old saves to be invalid.

## Team checklist

The stock game has 28 teams in TeamList order. The first 26 (`ANH` through `WPG`) are playoff teams; the two all-star teams stay last (`ASE`, `ASW`). Insert a playoff team before `ASE` and renumber `ASE` and `ASW`. Each table below is checked while assembling; the build stops if its count is not `NumTeams`.

| What | Where | One entry is |
| --- | --- | --- |
| Team number | `src/stubinc/equals.inc` | The next number before `ASE`. Renumber `ASE` and `ASW`. |
| Team record | `TeamList` in `src/teamdata94.asm` | One `dc.l` to a record like `Anaheim`: player list, home and visitor palettes, city and nickname strings, eight lines, scouting bytes and scoring odds. |
| Logo bitmap | `TeamLogoBitmaps` in `src/optsetup94.asm` | One `dc.l` to a logo in `src/graphics94.asm` (`logoANH` and the rest, each an `incbin` of a `.map.jim`). |
| Logo palette | `TeamLogoPalettes` in `src/title94.asm` | 16 colors. Most teams reuse their matchup palette; BOS, FLA, HFD and SJ have their own. |
| Matchup palettes | `TeamPalettes` in `src/cards94.asm` | Two palettes of 16 colors. A is the matchup logo palette. B is A with colors 1-2 and 3-4 swapped. |
| Featured pictures | `FeaturedPictures` in `src/cards94.asm` | One pointer, then that team's list of picture and roster index, ending in 0. |
| Songs | `TeamSongs` in `src/title94.asm` | 6 bytes. 0 picks from `RandomSongs`. |
| Ice logo | `TeamGfxList` in `src/title94.asm` | One address in `ArenaGfxBank`. |
| Rating | `TeamRatings` in `src/period94.asm` | One byte. |
| Team blocks | `Teamblocksmap` (`TeamBlocks.map.jim`) | Two rows, 11 tiles wide, in the shared banner image. |
| Team block bitmaps | `TeamBitmaps` (`TeamBlocks94.map.jim`) | The same shape, the other shared image. |

Those two rows go at the new team's index, and each map grows by 2 rows. The setup banner and the scoreboard name are those tiles; the menu name and the on-ice abbreviation come from the team record. `tools/prebuild.js` measures both images and writes `output/teamcounts.inc`. The image tools (JIM-Tools) are in EA-NHL-Tools.

`NoTiles` is the zero long just before `TeamList` (the pointer for a slot with no tiles). It is not a team entry.

## Playoff rows

`playoffseats` in `src/teamdata94.asm` is 32 rows of 16 team numbers (`PlayoffRows` by `PlayoffRowTeams`), not one entry per team. `NewPO` picks a row at random and finds the menu's team in that row. All-star teams are not seeded: a team number at or past `NumPlayoffTeams` is treated as the last playoff team.

Put the new number into the existing rows. Do not add a row. The build checks that the table is still exactly those 32 rows.

`GetRandomUnusedTeam` keeps the teams it has already drawn as bits in one register. That covers 32 playoff teams. Past that the build stops.

Also check: the save RAM section above (a 29th team needs the records block moved), and the short-jump section if `TeamList` or a team record grows below $8000.

## Build and test

`node tools/build.js retail` (Windows, or Linux with wine) runs prebuild, assemble, fixopcodes and fixrom, then compares with retail. A mod reaches step 4 (size, header end, checksum) and then reports MISMATCH at step 5, which is expected; `output/nhl94.bin` is the ROM to test. `node tools/build.js dev` skips the compare and the boot check.

Boot with `checksum=1`; a red screen means the boot checksum is wrong. `tools/verify_all.sh` is the stock check and prints `ALL MATCH` only when the full ROM and every segment still match retail. A modded ROM will not match, and must not be committed to `main`.
