# CD music, PCM, and the crowd channel

The disc has two sound devices the cartridge game does not drive this way. CD audio goes through the sub CPU BIOS entry `_CDBIOS` at `$5F22`, with the function number in `d0`. Digitized samples go through the PCM chip at sub-CPU `$FF0000`. Nothing in `HOCKEY.BIN`, `STARTER.BIN`, `MAIN.BIN`, or `PLAYER.BIN` writes the Genesis PSG data port `$C00011`.

Names below are the function numbers in Sega's `CDBIOS.INC`. The call shapes in this program match that list: a track function takes `a0` pointing at a 16-bit track number, a fader function takes the level in `d1`, and `CDBSTAT` returns a status pointer in `a0`.

`jsr $6044` is a different entry. Its function number is in `d7`. A `d0` immediate next to one of those calls is an argument to that SDK entry, not a `_CDBIOS` function and not a track number.

## BIOS calls this code makes

| `d0` | Name | What this program passes |
| --- | --- | --- |
| `$02` | `MSCSTOP` | no argument |
| `$10` | `DRVINIT` | `a0` → init parameter block |
| `$12` | `MSCPLAY1` | `a0` → 16-bit track number, play once |
| `$13` | `MSCPLAYR` | `a0` → 16-bit track number, repeat |
| `$15` | `MSCSEEK` | `a0` → 16-bit track number, seek and pause |
| `$80` | `CDBCHK` | carry set while the BIOS is busy |
| `$81` | `CDBSTAT` | `a0` → the BIOS status table |
| `$85` | `FDRSET` | `d1` volume `$0000`–`$0400`, or master `$8000`–`$8400` |
| `$86` | `FDRCHG` | `d1` long: high word is the new volume, low word is the step rate (`$0400` snaps) |
| `$96` | `CDCSETMODE` | `d1` bit 1 selects CD-DA |

`CDCSETMODE` bit 1 is the CD-DA flag, so `d1 = 2` is CD-DA mode. `d1 = 0` is mode 1 (CD-ROM). `FDRSET $0400` is full volume. `FDRSET $8400` is full master volume.

## Track word

| Address | Role |
| --- | --- |
| `$1745E` | 16-bit track number |
| `$1745C` | change request. `1` means apply `$1745E`. The play site at `$10B48` stores `$FFFF` after it has consumed the word |
| `$19364` | the word `a0` points at for `MSCSEEK` / `MSCPLAY1` / `MSCPLAYR` |
| `$1747A` | `asv`, the crowd-volume accumulator from the cartridge |
| `$17CD2` | `crowdlevel`, same role as cartridge `$FFFFB89C` |

`cdrequest.asm` (`HOCKEY.BIN` `$1C1D2`) reads one word from the stack. A value from `$30` through `$77` stores `1` at `$1745C` and stores `value - $29` at `$1745E`. That range becomes tracks `$07` through `$4E`. Anything outside the range returns without writing either word.

`cdtrack.asm` (`$1C206`) is the selector:

1. `CDBCHK` until the carry is clear. A set carry returns without playing.
2. `CDBSTAT`. The high byte of the first status word is the drive state. Byte 7 of that table is the CDD track byte (song number).
3. High byte `$05` forces `$1745E` to `2`.
4. High byte `$01` (playing) forces track `2` when the song byte is below `7`, is not `$FF`, and is not already `2`. Tracks `7` and above are left alone, which is the range `cdrequest` writes.
5. High byte `$00` falls through and plays. Any other high byte plays only when `$1745C` is positive.
6. Clears `$1745C`, copies `$1745E` to `$19364`, then `FDRSET`. Track `2` uses volume `$300`. Every other track uses `$400`.
7. `MSCPLAY1` twice, both times with `a0` pointing at `$19364`.

No `jsr` absolute and no `bra`/`bsr` in `HOCKEY.BIN` lands on `$1C1D2` or `$1C206`. The same search finds no pointer long for either address. A word-offset table would not show up in that search.

## Where a track is started

`cdstart.asm` (`$24D66`) clears sub-comm bit 5, calls `$375F4` and `$376D4`, sets `$191CE`, optionally calls `$37752` when `$3FC0A` is nonzero, calls `$21FC8`, then:

- `CDCSETMODE` with `d1 = 2` (CD-DA)
- store track `4` at `$19364`
- `MSCSEEK` that track, then `MSCPLAYR` the same word
- `FDRSET` volume `$400`, then master `$8400`

`$191CE` is cleared again at `$10826`.

`cdfade.asm` (STARTER file `$54F6`, runtime `$267F6`) is three helpers. The first copies a track word from the stack to `$10AD4`, `MSCSEEK`s it, `MSCPLAYR`s it, then `FDRCHG` with `d1 = $400` (volume word `0`, rate `$400`, so the fader snaps to silence) and calls `$E118` with `d0 = $1E`. The second `FDRCHG`s to a long taken from the stack. The third is `MSCSTOP`.

These sequences sit inside larger routines and play track `5` on a loop. Each one `MSCSTOP`s, waits on `CDBCHK`, polls `CDBSTAT` until the status high byte is `0`, stores `5` at `$19364`, and `MSCPLAYR`s it:

| Address | Around the play |
| --- | --- |
| `$B000` | one `MSCSTOP`, then track `5`. Continues into `$36D0A` |
| `$E50E` | saves sub-comm bit 5, `jsr $6044` with `d7 = 1` and `d0 = 4`, restores the bit, two `MSCSTOP`s, track `5`, then `printz` |
| `$E876` | same flag dance, `jsr $6044` with `d7 = 1` and `d0 = 2`, one `MSCSTOP`, track `5`, then `jmp $2E980` |
| `$107EE` | `MSCSTOP` and `rts`. The bytes at `$107F8` are a second `MSCSTOP` |
| `$10800` | clears `$191CE`, `DRVINIT` with `a0` pointing at `$1746A`, `MSCSTOP`, track `5` |
| `$10B2A` | copies `$1745E` to `$19364`, one `MSCPLAY1`, stores `$FFFF` at `$1745C` |

`$D820` is `ROMSEEK` (`$18`) of a sector long, in a menu routine. It is not a music call. That same menu clears `asv` at `$D938` and does `st.b asv` at `$D946` and `$D958`.

The shell around the movie player (STARTER runtime `$24E44`) saves BIOS `$8004` to `$EC8E`, `DRVINIT`s through `$ECA2`, and `CDCSETMODE`s with `d1 = 0`. On the way out it `DRVINIT`s again and `CDCSETMODE`s with `($EC8E & $F8) | 3`, which forces the CD-DA bit and the mode-2 bit back on.

## Crowd

On the cartridge, `updatesound` in `display94.asm` slews `asv` toward `crowdlevel` and writes the PSG noise channel: `$C8`, then `1`, then the volume byte `(asv XOR $F) OR $F0`. `KillCrowd` writes `$E7`, `$DF`, `$C8`, `1`, `$FF` to the same port. Gameplay adds to `crowdlevel` on hits, goals, and penalties, and `periodicevents` calls `updatesound`.

`cdcrowd.asm` (`HOCKEY.BIN` `$238CE`) is that slew. `crowdlevel` is `$17CD2` and `asv` is `$1747A`. The scale (`asl #3`, add `$400`, clamp at `$EFF`, step `$28`) is the cartridge math. The routine builds the old volume byte in `d0` and returns. The three PSG stores are not in this copy, and `$C00011` is not written from any of the four code files. No branch and no absolute `jsr` in `HOCKEY.BIN` targets `$238CE`.

`crowdlevel` is still stored from gameplay (the `$96` / `$C8` / `$12C` / `$3E8` adds are at the same relative sites as the cartridge). The crowd-frame routine at `$10D28` still compares it with `$15E`. That comparison moves sprites. It does not write a sound chip. `asv` is still cleared and forced to `$FF` from the menu path above, and the dead slew still reads it.

The selector's track `2` is the loop that replaces a playing track below `7`. It is also the track forced when the status high byte is `$05`, and it is the one given the lower fader (`$300` instead of `$400`). That is the continuous CD bed. The PCM stream below is a separate device.

## PCM stream

The chip is the RF5C164 on the sub CPU, base `$FF0000`. `MAIN.BIN` is linked at `$FF0000` on the main CPU, so those are not the same address. Writes are byte-sized, odd addresses only for wave RAM, and each control write is followed by `moveq #$14,d0` / `dbra`. The play-address registers are read twice.

`pcmchip.asm` (STARTER file `$3FD0`, runtime `$252D0`):

| Runtime | What it writes |
| --- | --- |
| `$252D0` | mute `$FF0011 = $FF`, channel `$FF000F = $C0` then `$88`, envelope `$FF0001 = $FF`, pan `$FF0003 = $FF`, frequency high `$FF0007 = $04` (FD `$0400`), frequency low / loop / start cleared, one `$FF` sample at `$FF2001` |
| `$25356` | `$FF000F = $80`, `$FF0011 = $FE` (channel 0 on) |
| `$25370` | `$FF0011 = $FF` (mute) |
| `$2537E` | `$FF0021` twice into the low byte, `$FF0023` twice into the high byte |
| `$253A6` | stack argument at `8(sp)` is the bank, ORed with `$80` and written to `$FF000F`. Then `$1000` bytes from `4(sp)` are copied to `$FF2001`, stepping the chip pointer by 2 |

`pcmclear.asm` (`$24D0C`) selects channels `0`–`7` with `$40` added to the index, clears the start registers, fills wave RAM, and mutes with `$FF0011 = $FF`.

`audiostream.asm` (file `$508C`, runtime `$2638C`) is nine Sierra C functions. The name bytes follow each `rts`. The struct passed in `8(a6)` is:

| Offset | Use |
| --- | --- |
| `+0` | block index. `-1` means stopped. `AudioPlayPos` returns `0` in that case |
| `+4` | blocks submitted |
| `+8` | source pointer |
| `+$C` | bytes still to send |
| `+$E` | the word `AudioBusy` returns (the low word of the long at `+$C`) |

`AudioPlayPos` reads the chip address, shifts it right by 12, and calls `$26656` with that index and `d1 = 8`. If the two differ it increments the index. Eight banks of `$1000` bytes is the ring those shifts line up with.

`AudioInit` stores `-1` and three zero longs, then calls the PCM init at `$252D0`.

`AudioIdle` calls `AudioPlayPos`. It returns when no bytes remain, and when `submitted - playpos` is at least 8. Otherwise it loads one `$1000` bank through `$253A6` at slot `submitted mod 8` (the same `$26656` call), advances the source, and drops the remaining count by `$1000`.

`AudioFeed` stores the caller's pointer and length, fills while bytes remain and fewer than 8 blocks are queued, calls `$25356` to open channel 0, and sets the index to `0`. If the index was already running it returns after the two idle calls.

`AudioSilence` allocates `$1000` bytes at `$25E7E`, fills `$400` longs with zero, submits that block eight times, frees it at `$25CFA`, and starts channel 0. It does nothing when the index is already running.

`AudioStop` mutes at `$25370`.

`AudioTicks` returns `(index << 12) | (chip address & $FFF)`.

`AudioTime` calls `AudioTicks`, multiplies by the second argument through `$2660C`, adds `$1F40` (8000), and divides by `$3E80` (16000) through `$26632`. The frequency register `$0400` is the setting that lines up with a 16000 divisor. SNASM rewrites `add.l #$1F40,d0` into `addi.l`. The disc byte is `D0 BC 00 00 1F 40`, so that one instruction is a `dc.w` / `dc.l` in `audiostream.asm`.

`$2660C`, `$26632`, and `$26656` are compiler thunks. Capstone stops inside `$26632` on a `dc.w $4C41`. They are called as multiply, divide, and the divide-by-8 used for the bank slot. Their bodies are not in this slice.

No absolute pointer to `AudioFeed` or `$253A6` turned up in `HOCKEY.BIN`. The callers are PC-relative inside `STARTER.BIN`, or they go through a pointer that is not the full address. The scouting-report announcer is the next pass; the credit string `Announcer:` is in STARTER at file `$1B032`.
