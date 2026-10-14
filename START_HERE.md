# NHL 94 Genesis

Byte-matching SNASM68k source for the retail cartridge. A stock build matches `lst/nhl94.bin`.

Read `SEGMENT_AGENT.md` (the Current rules) and `docs/HANDOFF.md` before editing. `docs/ADDING_A_TEAM.md` is how to add a team without breaking that match.

## Build

Linux: install wine and wine32, `export WINEDEBUG=-all`, then `node tools/prebuild.js retail` and `export NHL_PREBUILD_DONE=1`. Assemble with `wine cmd /c "set rev=0&& set checksum=1&& build94.bat"`. Then `node tools/fixopcodes.js "output/nhl94 .lst" output/nhl94.bin` and `node tools/patchchecksum.js "output/nhl94 .lst" output/modified_nhl94.bin`. `tools/verify_all.sh` does the full ROM and every segment and prints `ALL MATCH`.

`checksum=1` runs ValidationRoutine at boot. The patch step writes the sum it compares against, so a changed ROM still boots with the check on. `checksum=0` skips the check. The checksum segment is left on the retail immediate so it still matches.

## Growing the ROM

`absjsr` and `absjmp` (`src/macros/genesis.mac`) pick a short absolute call when the target is below $8000 and a long one otherwise. The target must already be defined.

The image is filled with $FF through 1MB, then to 1.5MB, 2MB or 4MB if there is more. The header ROM end is `RomEnd`. Anything included after the 1MB fill starts at the 1MB boundary. Content past backup RAM warns; past 4MB the assemble stops.

`bra.w Begin` is reassembled as a long jump when the startup code can no longer reach it (`LONGBRA=1` on the second pass of `build94.bat`).

Team counts, the tables a new team has to extend, and the save-RAM crowd records are in `docs/ADDING_A_TEAM.md`.
