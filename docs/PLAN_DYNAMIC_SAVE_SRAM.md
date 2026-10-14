# Plan: fully dynamic save RAM and large ROM (NHL 94)

The mod-safe build already pads the ROM, patches the boot checksum, slides team save blocks when `NumTeams` grows, and warns when assembled content passes the backup-RAM window. This plan finishes what chaos asked for: save read/write that follow the chip and the ROM size, not only the team-block offsets.

Stock bytes stay identical until a modder actually needs the new paths. Every phase ends with `tools/verify_all.sh` printing **ALL MATCH** on the retail tree.

## Phase 1 — Save chip equates (done)

**Goal:** One place defines the chip base, mirror size, and checksum byte offsets. All routines in `sram94.asm` use those names. At stock values the assembled ROM is unchanged.

| Equate | Stock value | Role |
| --- | --- | --- |
| `SaveRamBase` | `$200000` | Cartridge backup RAM in the 68000 map (odd byte of each word) |
| `SaveMirrorBytes` | `$2000` | Bytes copied to work RAM at power on |
| `SaveMirrorLast` | `$1FFF` | Last mirror byte index (clear loop) |
| `SaveSumDb` | `$1FFD` | `dbf` count when summing bytes 0 .. checksum−2 |
| `SaveChecksumByte` / `SaveChecksumSum` | `$1FFE` / `$1FFF` | Complement and sum in the mirror |
| `SaveRamMapPort` | `$A130F1` | Maps the backup chip when ROM also occupies `$200000` |

**Files:** `src/stubinc/equals.inc`, `src/sram94.asm`, `docs/HANDOFF.md`.

**Gate:** Full ROM and `sram94` segment MATCH.

## Phase 2 — Backup-RAM map toggle for ROM past `$200000` (done)

**Goal:** When the assembled image uses addresses at or above `$200000`, every access to the save chip turns the hardware map on before the access and off after. Retail 1 MB builds never emit those instructions.

**Mechanism:**

- Assembler flag `SRAMTOGGLE=0` by default (`build94.bat`, `buildseg.bat`).
- If the assemble log contains `ROM content overlaps backup RAM`, `build94.bat` assembles again with `SRAMTOGGLE=1` (same idea as `LONGBRA`).
- `ReadSRAM` and `WriteSRAM` wrap chip access with `move.b #1` / `clr.b` on `SaveRamMapPort` only when `SRAMTOGGLE=1`.
- InitSaveRAM factory-test loops that touch the chip directly get the same wrap when `SRAMTOGGLE=1`.

**Verify on hardware or BlastEm** with a throwaway ROM whose code or data ends above `$1FFFFF` but still boots: save still reads/writes after toggle path.

**Gate:** Stock MATCH; grown-ROM test boots and save I/O works in emulator.

## Phase 3 — Mirror and checksum follow `SaveMirrorBytes`

**Goal:** If the header save range or a future mod grows the chip beyond `$2000` bytes (new header longs, larger `SaveMirrorBytes`), `InitSaveRAM`, `ValidateSRAM`, `ClearSRAM`, and `MakeSRAMChecksum` use the equates only. At `$2000` nothing changes.

**Optional later:** Move the work-RAM mirror off `$FFFF0000` if the mirror grows past low RAM used by the game. That is a separate layout pass and is not required for one extra team.

**Gate:** Stock MATCH; assemble-time check that logical save layout fits in `SaveMirrorBytes`.

## Phase 4 — Remaining fixed save slots

**Goal:** Document and, where needed, slide or size: playoff password bits, the eight record-holder block (`RecordsBytes`), shootout blocks, and any other save fields still hardcoded. Tie each to an equate or a build-time check.

**Gate:** Stock MATCH; `docs/ADDING_A_TEAM.md` lists every save field a modder can grow.

## Phase 5 — Documentation and modder workflow

**Goal:** `docs/ADDING_A_TEAM.md` points here. Describe: when the overlap warning appears, the second assemble enables the map toggle; modders must not place ROM data in `$200000`–`$203FFF` if they rely on saves unless the toggle build is used.

## Out of scope (unless hardware proves otherwise)

- Changing the header backup-RAM range (`$200001`–`$203FFF`) without a new cartridge definition.
- SNES-style header checksum (Genesis uses `ValidationRoutine` + optional header word `$18E`).
- Automatic relocation of game code into the `$200000` window.

## Order of work

1. Phase 1 (equates) — **now**
2. Phase 2 (toggle + build retry)
3. Phases 3–4 as modders hit limits
4. Phase 5 kept in sync each commit
