# NHL 94 Genesis

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

`src/nhl94.asm` is the top level and the include list, in ROM order. `SEGMENT_AGENT.md` is the rule file. `PROMPT.md` is the first Copilot prompt. Placeholder files are comments only.

94-only files that 93 did not have:

- `attract94.asm` for `EASportsScreen`, `HiScoreScreen`, and `LoadDefMenuOptions`
- `sram94.asm` starts at `InitSaveRAM`

## Build

Segment builds use `buildseg.bat` and `npm run seg:<name>` once a segment has a stub and a confirmed org. Verify against `lst/nhl94.bin`.

`npm run extractassets` runs `tools/extractAssets94.js` against `lst/nhl94.bin`. Builds do this automatically when `Extracted/` is missing or incomplete (below).

## Build pre-step: ROM check and automatic asset extraction
Every build entry point (`npm run build:*`, `npm run seg:*`, and the batch files run directly) first runs `node tools/prebuild.js`. It:

1. checks that the ROM the build needs is in place and is exactly the right version (SHA-1 and size);
2. checks that `Extracted/` is complete: the extractor writes `Extracted/.extract-complete.json` last, listing every file it wrote (with its size), the ROM it read and the extractor's own SHA-1;
3. runs the extractor if `Extracted/` is missing, incomplete (no marker, a missing or resized file) or was written by an older extractor.

If the ROM is missing (or is a different dump), the build stops with the full path and file name to put it at, its SHA-1 and size, and a reminder that ROMs are not included in the repo:

| Build | ROM needed | SHA-1 | Size |
| --- | --- | --- | --- |
| every build and segment | `lst/nhl94.bin` | `7b1489ab501258133bf03e5f0892b77d04312580` | 1048576 bytes |

`npm run assets` runs only this step. `npm run extractassets` still forces a fresh extraction. The npm scripts set `NHL_PREBUILD_DONE=1` after the step so the batch file does not repeat it; `tools/verify_all.sh` runs the step with Linux node and sets the same variable for wine (there is no node under wine).

Full ROM builds assemble `src/nhl94.asm`. The listing is `output/nhl94 .lst`. The opcode-corrected output is `output/modified_nhl94.bin`.

| Script | Flags | Result |
| --- | --- | --- |
| `npm run build:retail` | `rev=0`, `checksum=1` | Retail, validation included, verified byte for byte against `lst/nhl94.bin`. |
| `npm run build:dev` | `rev=0`, `checksum=0` | No validation and no retail verify. Use this while editing. |

`build:dev` (`checksum=0`): `Start` skips `jsr ValidationRoutine` (3 `nop`s instead) and the header checksum at `$18E` is 0, so changed code still boots. With `checksum=1` the validation routine sums the ROM, and any change turns the screen red. `ValidationRoutine` stays in the ROM but is never called.
