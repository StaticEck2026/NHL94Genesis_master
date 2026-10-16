# NHL 94 Genesis

> **Work in progress:** this disassembly is unfinished and unpolished, and is being actively worked on. Expect labels, file layout and docs to change.

Bitwise rebuild of NHL 94 for the Sega Genesis.

The listing is `lst/nhl94.bin.lst`. The ROM it was generated from is `lst/nhl94.bin`. That file is the reference for every segment verify. Do not use a different ROM.
## Supported ROMs
NHL 94 had one retail release; `tools/extractAssets94.js` accepts only that ROM, found by SHA-1, and refuses any other (bad dump, hack, prototype) with its SHA-1, size and header. The slices are kept as a per-version map from retail address, so a new version only needs a row with its SHA-1 and offsets.

| Version | Header | File | Size | SHA-1 |
| --- | --- | --- | --- | --- |
| Retail | `1993.JUL`, `GM T-50656 -00` | `lst/nhl94.bin` | 1 MB | `7b1489ab501258133bf03e5f0892b77d04312580` |


The listing is an IDA LST in ASM68K / MRI mode. It has no address column. `loc_` / `sub_` names are the address.

Style source for a segment is the matching file in [NHLPA93Genesis](https://github.com/abdulahmad/NHLPA93Genesis).

## Segment queue

`src/nhl94.asm` is the top level and the include list, in ROM order. `SEGMENT_AGENT.md` is the rule file. Placeholder files are comments only.

94-only files that 93 did not have:

- `attract94.asm` for `EASportsScreen`, `HiScoreScreen`, and `LoadDefMenuOptions`
- `sram94.asm` starts at `InitSaveRAM`

## Build

Segment builds use `npm run seg -- <name>` (`tools/build.js --seg`; orgs in `tools/segments.json`). Verify against `lst/nhl94.bin`.

`npm run extractassets` runs `tools/extractAssets94.js` against `lst/nhl94.bin`. Builds do this automatically when `Extracted/` is missing or incomplete (below).

## Build pre-step: ROM check and automatic asset extraction
Every build entry point (`npm run build:retail`, `build:dev` and `seg`, all through `tools/build.js`) first runs `node tools/prebuild.js`. It:

1. checks that the ROM the build needs is in place and is exactly the right version (SHA-1 and size);
2. checks that `Extracted/` is complete: the extractor writes `Extracted/.extract-complete.json` last, listing every file it wrote (with its size), the ROM it read and the extractor's own SHA-1;
3. runs the extractor if `Extracted/` is missing, incomplete (no marker, a missing or resized file) or was written by an older extractor.

If the ROM is missing (or is a different dump), the build stops with the full path and file name to put it at, its SHA-1 and size, and a reminder that ROMs are not included in the repo:

| Build | ROM needed | SHA-1 | Size |
| --- | --- | --- | --- |
| every build and segment | `lst/nhl94.bin` | `7b1489ab501258133bf03e5f0892b77d04312580` | 1048576 bytes |

`npm run assets` runs only this step. `npm run extractassets` still forces a fresh extraction. `tools/build.js` runs it as step 1 of every build; `tools/verify_all.sh` also deletes `Extracted/` first so it is always a fresh extract.

Full ROM builds assemble `src/nhl94.asm`. The listing is `output/build/nhl94 .lst` and the raw image `output/build/nhl94.raw.bin`. The finished ROM is `output/nhl94.bin` (`nhl94-revA.bin` with `rev=1`, `nhl94-dev.bin` for a dev build); a segment is `output/<name>.bin`.

| Script | Flags | Result |
| --- | --- | --- |
| `npm run build:retail` | `rev=0`, `checksum=1` | Retail, validation included, verified byte for byte against `lst/nhl94.bin`. |
| `npm run build:dev` | `rev=0`, `checksum=0` | No validation and no retail verify. Use this while editing. |

`build:dev` (`checksum=0`): `Start` skips `jsr ValidationRoutine` (3 `nop`s instead) and the header checksum at `$18E` is 0, so changed code still boots. With `checksum=1` the validation routine sums the ROM, and any change turns the screen red. `ValidationRoutine` stays in the ROM but is never called.

## Sega CD

`npm run build:segacd` (`node tools/build.js --segacd`) assembles the 41 transcribed CD fragments in `src/segacd/` into `output/segacd/` and compares them to the disc files in `cdbin/` (not in the repo), on Windows or Linux with wine. It does not change the cartridge build. What the disc changed, and how far the disassembly goes, is `docs/segacd.md`.

## Build steps explained

`tools/build.js` prints one line per step with a short note under it: prebuild (check the ROM, extract assets), assemble (SNASM68k), fixopcodes (patch the encodings SNASM picks differently from EA's assembler), fixrom (ROM size, header end, checksum) and verify (byte-for-byte against retail). Details in `START_HERE.md`.

## Credits

Thanks to chaos, StaticEck, McMarkis and Drezz for their help with the disassembly.

These disassemblies started with a lot of manual work, especially from chaos, and have since been AI-assisted.
