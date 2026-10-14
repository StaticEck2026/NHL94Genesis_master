# Adding a team

The stock ROM stays byte-identical. A new team is new data and new table entries. The build then pads, fills the header, and writes the boot checksum.

The stock game has 28 teams in TeamList order. The first 26 (`ANH` through `WPG`) are the playoff teams. The two all-star teams stay last (`ASE`, `ASW`). `NumTeams` is `ASW+1` and `NumPlayoffTeams` is `ASE`, both in `src/stubinc/equals.inc`. Insert a playoff team before `ASE` and give `ASE` and `ASW` the next numbers. The option limits, the random team range, the playoff clamp and the crowd-record size follow those equates.

## One entry per team

Each of these is checked while assembling. The build stops if the count is not `NumTeams`.

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

`NoTiles` is the zero long just before `TeamList`. It is the pointer used when a slot has no tiles. It is not a team entry.

The two shared images are measured by `tools/prebuild.js`, which writes `output/teamcounts.inc`. Rebuilding those images, and the ice logos, is not in this repo. The graphics tools for that live in EA-NHL-Tools.

## Playoff rows

`playoffseats` in `src/teamdata94.asm` is 32 rows of 16 team numbers (`PlayoffRows` by `PlayoffRowTeams`), not one entry per team. `NewPO` picks a row at random and finds the menu's team in that row. All-star teams are not seeded: a team number at or past `NumPlayoffTeams` is treated as the last playoff team.

Put the new number into the existing rows. Do not add a row. The build checks that the table is still exactly those 32 rows.

`GetRandomUnusedTeam` keeps the teams it has already drawn as bits in one register. That covers 32 playoff teams. Past that the build stops.

## Save RAM

Crowd records are `NumTeams` blocks of 16 bytes at `CrowdRecBase`. The stock league ends on the records block, so `TeamRecBase` stays put. A larger league starts the records block at the end of the crowd records, and starts `NameLogBase` at the end of that block. The retail addresses do not change.

The records block itself is eight 16-byte records (`RecordsBytes`). It is not one record per team. The name log is `NameLogBytes` at `NameLogBase`. Line data stays at `LineDataBase`. The build stops if the name log would run into the line data.

`TeamRatings` is one byte per team. The next routine is aligned after the length check. The stock table is already even, so that alignment adds nothing.

## Where the new bytes go

`src/nhl94.asm` fills `$FF` up to 1MB before it chooses a larger size. Put the new includes after that fill. On a stock image they start at the 1MB boundary. The pad then grows the ROM to 1.5MB, 2MB or 4MB, and the header end is the last byte of that pad.

Leave the backup RAM window alone if the save data should keep working. The build warns when the image passes that window, and it still builds. Past 4MB the assemble stops.

`absjsr` and `absjmp` keep calls working when a routine moves from below `$8000` to above it. The target has to be defined before the call. A forward call is written `jsr (name).l` or `jmp (name).l`. If the startup branch to `Begin` can no longer reach, `build94.bat` assembles a second time with a long jump.

## Build and test

1. `node tools/prebuild.js retail` and `export NHL_PREBUILD_DONE=1`.
2. `wine cmd /c "set rev=0&& set checksum=1&& build94.bat"` (`WINEDEBUG=-all`). The log must say `0 error`.
3. `node tools/fixopcodes.js "output/nhl94 .lst" output/nhl94.bin`
4. `node tools/patchchecksum.js "output/nhl94 .lst" output/modified_nhl94.bin`

The ROM size is 1MB, 1.5MB, 2MB or 4MB. The header long at the ROM-end field is the last byte of that size. The checksum line prints the old immediate and the sum it wrote; that sum is every long below `ValidationRoutine`, skipping the header long that holds the checksum word.

Boot with `checksum=1`. The red screen is this check failing. `checksum=0` skips it. `tools/verify_all.sh` is the stock check: it prints `ALL MATCH` only when the full ROM and every segment still match the retail image. A ROM with an extra team will not match, and should not be committed over the retail bytes.
