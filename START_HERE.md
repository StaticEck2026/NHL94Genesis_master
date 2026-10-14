# NHL 94 Genesis

Byte-matching SNASM68k source for the retail cartridge. A stock build matches `lst/nhl94.bin`.

Read `SEGMENT_AGENT.md` (the Current rules) and `docs/HANDOFF.md` before editing. `docs/EXPANDING_THE_ROM.md` covers growing the ROM and adding a team.

## Build

Linux: install wine and wine32, `export WINEDEBUG=-all`, then `node tools/prebuild.js retail` and `export NHL_PREBUILD_DONE=1`. Assemble with `wine cmd /c "set rev=0&& set checksum=1&& build94.bat"`. Then `node tools/fixopcodes.js "output/nhl94 .lst" output/nhl94.bin` and `node tools/fixrom.js "output/nhl94 .lst" output/modified_nhl94.bin`. `tools/verify_all.sh` does the full ROM and every segment and prints `ALL MATCH`.

`checksum=1` runs ValidationRoutine at boot. The fixrom step writes the sum it compares against, so a changed ROM still boots with the check on. `checksum=0` skips the check. The checksum segment is left on the retail immediate so it still matches.

## Growing the ROM

`main` stays a faithful retail disassembly. `tools/fixrom.js` pads a larger image to 1.5MB, 2MB or 4MB, sets the header ROM end and fixes the checksum; `src/shortcalls.inc` stops the build if a short-called routine moves past $7FFF. Short jumps, save RAM past 2MB, bank switching and the team checklist are in `docs/EXPANDING_THE_ROM.md`.
