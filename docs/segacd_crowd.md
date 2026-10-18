# Crowd animation

`updatecrowdf` is on the disc. It is the cartridge routine with long addresses, plus one real change: the sub CPU cannot read the VDP HV counter, so both of those reads go through the main CPU.

`crowdanim.asm` is `HOCKEY.BIN` `$10D28` through the `rts` at `$10E64`. `crowdtable.asm` is the frame table at file `$2654C`.

## Same frames as the cartridge

The cartridge `updatecrowdf` (`hockey94.asm`) decays `Crowdlevel`, steps `Crowdstep` by 2 masked with `$1E`, and indexes `cd0`. A loud crowd (`Crowdlevel` above `$118`) can store a random extra frame, `$13` through `$19` (19 through 25).

On the disc the variables moved with the rest of work RAM:

| Cartridge | Disc | What |
| --- | --- | --- |
| `Crowdframe` `$B89A` | `$17CD0` | frame byte, high byte of the word |
| `Crowdlevel` `$B89C` | `$17CD2` | excitement |
| `Crowdstep` `$B89E` | `$17CD4` | index step |
| `Crowdcnt` `$B8A0` | `$17CD6` | ticks until the next frame |

The thresholds are the cartridge ones: calm a crowd at or above `$15E` by an extra 3, clamp the index source at `$7F`, mask `$60`, and the loud-crowd window `$118` / `$13` / `$19`. The frame table is the cartridge `cd0` bytes, 64 words, four bands. `HOCKEY.BIN` is entered at `$1B000`, so file `$2654C` is address `$4154C`, which is the `movea.l #$4154C,a0` in the driver. Nothing is appended after the last `$0B03`.

## Where the random word comes from

The cartridge reads `VDP_CNTR` (`$C00008`). The disc posts `$1B` to `$FF8020` and, once bit 6 of `$FF800E` is set, reads `$FF8010`. It does that twice: once for the frame delay, once for the loud-crowd frame. The rest of the handshake is the usual bit 6 / bit 7 pair on `$FF800F`.

`$FF8010` is main-CPU `$A12010`. `hwread.asm` is the run of one-instruction readers at `$FF3B3C`. One of them is `move.w $C00008,$A12010`, the HV counter copied into that comm word. The command `$1B` slot in the jump table at `$FF01BE` is `$FF142A`, and that handler does not itself read the HV counter. The word the crowd driver uses is whatever the main CPU last stored at `$A12010`.

The PSG crowd bed is still gone. `cdcrowd.asm` computes the old volume byte and returns it. This driver only picks a frame.
