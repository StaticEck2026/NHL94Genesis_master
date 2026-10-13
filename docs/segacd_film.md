# Film player, Z80 loader, hardware readers

These three are Sega CD code. None of them is in the cartridge.

## Film player

The names sit in `STARTER.BIN` after each `rts`: `FilmOpen` at file `$4539`, `FilmTask` at `$472F`, `FilmClose` at `$477D`. Runtime is file plus `$21300`.

| Source | File | Runtime | What |
| --- | --- | --- | --- |
| `filmopen.asm` | `$4336` | `$25636` | Open a `FILM` blob |
| `filmsm.asm` | `$3EAA` | `$251AA` | Walk an `SM` chunk (294 bytes, through `jmp (a0)`) |
| `filmtask.asm` | `$458C` | `$2588C` | One frame |
| `filmclose.asm` | `$473A` | `$25A3A` | Release it |

`FilmOpen` takes the caller's long at `8(a6)`. It rejects a null buffer from the `$800`-byte allocator, then requires the first long to be `$46494C4D` (`FILM`). A bad file prints through `$25BC4` and returns -1. A good file rounds the size at offset 4 up by `$7FF` and divides by `$800` (the same compiler thunk `audiostream.asm` uses at `$26632`). The frame index at `$40(a4)` starts at -1. The state block is `$40` bytes into the struct at `$24FB4`.

`FilmTask` returns -2 when `$38` of that struct is set, and -1 when the frame index is still negative. Otherwise it steps the index and reads a 16-byte record at `$10` plus index times 16. A record whose long at offset 8 is -1 is fed through `$262FC` / `$26480`. Any other record is also read, and if the first word of the returned block is `$534D` (`SM`) the task calls `filmsm` with `$C0000` and that block.

`filmsm` checks `SM` again. The word at offset 8 and the word at offset 10 are multiplied, doubled, rounded up to a long, and that count leads a copy of the chunk. `FilmTask` passes `$C0000` as the destination and the `SM` block as the source. The routine then walks the sub-blocks that follow the header. `FilmTask` waits on `$265B2` against `$258` while that chunk is live, then calls `$2609E` with 2.

`FilmClose` stops the block at `$30(a4)`, frees `$14(a4)`, sets the frame index back to -1, and calls `$2609E` with 3.

## Who calls it

`filmrun.asm` (file `$3D94`, runtime `$25094`) is the switch in front of those three.

| Word at `4(sp)` | What runs |
| --- | --- |
| `0` | Save six caller longs into the block at `$24FB4`, set bit 2 of `$FF8002`, install two BIOS vectors, call `FilmOpen` with the long at `$A(a6)` |
| `1` | `FilmTask` |
| anything else | `FilmClose`, then put the two old vectors back |

The first vector replaces BIOS `$5F36`. Its handler adds one to the long at `$24FB8` and, if the long at `$24FE8` is set, calls it. The second replaces BIOS `$5F90`. Open installs both. Close restores both. The bytes between the switch and those hooks clear eight longs at address `0` and store `$208008` at `$80`.

`filmcmd.asm` (runtime `$2609E`) is the post those calls use. It waits until `$FF8010` is `0`, writes the caller's word to `$FF8020`, waits until `$FF8010` is nonzero, and clears `$FF8020`. `GetCommandFromSub` in `maintext.asm` is the main CPU side: it waits for `$A12020`, answers `$1` in `$A12010`, and returns the word. `DoMoviePlayBack` loops on that. Command `2` is the frame: it reads three longs from word RAM at `$200000` and calls `$FF2BA0`. `FilmTask` posts `2` after an `SM` chunk. `FilmClose` posts `3`.

`filmbuf.asm` (runtime `$26126`) asks `$25E34` for a size. Below `$14000` it returns -1. Above `$34000` it clamps. It then rounds `(size - $4000)` up to a multiple of `$800`, allocates that plus `$4000`, and stores the pointer in the film block.

The `FILM` bytes are not in these six disc files. `filmrun` plays whatever buffer the caller passes.

The `add.l #$7FF,d0` in `FilmOpen` is the same encoding as `AudioTime`: the disc has `D0BC`, and SNASM would emit `addi.l`. The source uses `dc.w $D0BC` / `dc.l $000007FF`.

## Z80 loader

`z80load.asm` is `MAIN.BIN` `$FF76C8`. The main CPU owns the Z80. The cartridge sound driver used to.

It masks interrupts, stores `a1+4` at `$FF855A`, then takes the Z80 bus (`$A11100` = `$100`) and holds reset (`$A11200` = `$100`). The block is accepted only when its first byte is `$C3` and the next byte is `$00` (a Z80 jump to address 0). Otherwise it returns 6 with carry set. The accepted block is copied to `$A00000` for `d1+1` bytes. Reset is released, a `$1F4` spin runs, reset is asserted again, and the slot tables are cleared: five longs of `$FFFFFFFF` at `$FF85EC`, eight longs of `$FFFFFFFF` at `$FF841C`, eight zero longs, eight `$FFFF` words, eight zero words. Success returns 0 with carry clear.

## Hardware readers

`hwread.asm` is `MAIN.BIN` `$FF3B3C` through `$FF3C3B`, twenty-one one-line functions. The argument word or long is `$A12022` (sub CPU `$FF8022`). The reply word is `$A12010` (sub CPU `$FF8010`).

Writes from the argument: VDP control `$C00004` and VDP data `$C00000` as byte, word, and long; joypad ports `$A10003`, `$A10005`, `$A10009`, `$A1000B` as a byte; Z80 bus request `$A11100` as a word.

Reads into `$A12010`: joypad 1, joypad 2, VDP data word, VDP data long, VDP status `$C00004`, HV counter word `$C00008`, HV counter byte, and a byte, word, or long from the address in `$A12022`.

The crowd driver samples `$FF8010` after posting command `$1B`. The word reader here is the instruction that puts the HV counter in that comm word. See `docs/segacd_crowd.md`.
