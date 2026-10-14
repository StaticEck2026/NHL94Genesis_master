# NHL 94 Genesis

Byte-matching SNASM68k source for the retail cartridge. A stock build matches `lst/nhl94.bin`.

Read `SEGMENT_AGENT.md` (the Current rules) and `docs/HANDOFF.md` before editing. `docs/EXPANDING_THE_ROM.md` covers growing the ROM and adding a team.

## Build

`npm run build:retail` (or `node tools/build.js retail`) runs the whole build and prints one line per step; `npm run build:dev` (`node tools/build.js dev`) builds with `CHECKSUM=0` and skips the verify. Linux needs wine and wine32 (`build.js` runs the assembler under wine); Windows runs it directly. `build94.bat` calls the same script. Add `--verbose` for each step's full output. `rev=1` in the environment builds REV A.

```
[1/5] prebuild   ROM OK, 475 assets
[2/5] assemble   0 errors, 0 warnings, 69719 lines in 0.31s (REV=0 CHECKSUM=1) -> output/nhl94.bin
[3/5] fixopcodes 473 opcodes fixed
[4/5] fixrom     size $00100000, header end $000FFFFF, checksum $8AB9F121
[5/5] verify     MATCH output/modified_nhl94.bin
```

A failing step prints `FAILED`, the relevant log lines (`output/Build94.log` for the assembler) and `BUILD FAILED at <step>`, and exits 1. `tools/verify_all.sh` builds the full ROM and every segment and prints `ALL MATCH`.

`checksum=1` runs ValidationRoutine at boot. The fixrom step writes the sum it compares against, so a changed ROM still boots with the check on. `checksum=0` skips the check. The checksum segment is left on the retail immediate so it still matches.

## Growing the ROM

`main` stays a faithful retail disassembly. `tools/fixrom.js` pads a larger image to 1.5MB, 2MB or 4MB, sets the header ROM end and fixes the checksum; `src/shortcalls.inc` stops the build if a short-called routine moves past $7FFF. Short jumps, save RAM past 2MB, bank switching and the team checklist are in `docs/EXPANDING_THE_ROM.md`.
