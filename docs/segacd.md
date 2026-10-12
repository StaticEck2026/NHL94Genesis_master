# NHL 94 Sega CD

The disc is the cartridge game, linked again for the two Sega CD 68000s, with a new shell from the official Sega CD SDK around it. It is not a source-level rewrite, and it is not the cartridge ROM with a CD boot strapped on.

The six disc files used here live in `cdbin/` locally (`MAIN.BIN`, `STARTER.BIN`, `HOCKEY.BIN`, `PLAYER.BIN`, `GRAPH2.BIN`, `GTABLE.BIN`). They are not in the repo.

## What each file is

| File | CPU | What it is |
| --- | --- | --- |
| `STARTER.BIN` | Sub | SDK boot. Heap, film player, main/sub commands. Linked at `$21300`: the first instruction jumps to a Sierra C `link a6,#0` at `$262A8`. |
| `HOCKEY.BIN` | Sub | The game. Linked at `0` (its own branches land inside the file). About 181 KB. |
| `PLAYER.BIN` | Sub | A second module, also linked at `0`, with a relocating startup (`lea 0(pc,a6.l),a6`) and the scouting strings ("Power play advantage", "Number of forwards"). |
| `MAIN.BIN` | Main | SDK shell in Genesis RAM at `$FF0000`. Talks to the VDP and to the sub CPU through `$A120xx`. |
| `GTABLE.BIN` | | 2 KB of long offsets. |
| `GRAPH2.BIN` | | 3 MB graphics archive. The first longs are offsets into the file. |

`STARTER.BIN` and `MAIN.BIN` are the SDK. They contain `link a6` / `unlk a6` (39 and 26), `mmalloc` / `ffree`, `FilmOpen` / `FilmTask`, `Example Line 0` through `Example Line 7`, and the strings `SUBCPU is alive` and `MAINCPU is alive`. None of that is in the cartridge. Calls go through the sub CPU BIOS entry at `$6044` with the function number in `d7`.

`HOCKEY.BIN` has no `link a6`. It has 656 `rts` and 328 `movem.l` to the stack, the same shape as the cartridge, and it has the cartridge's screens: "Play Mode", "EA Hockey Night", "HAT TRICK!", "Line Editor", "SHOOTOUT MODE", the penalty names, the exception strings.

## The SDK change

The cartridge was built with EA's assembler. Short absolute addresses reach Genesis work RAM (`$B028` sign-extends to `$FFFFB028`), and `addq` / `bra.b` are used wherever they fit.

On the disc the same instructions were assembled with long addresses, because the game now runs on the sub CPU and those variables live in its program RAM. Two instructions from the end of the Play Mode screen:

Cartridge (`optsetup94`, bytes in front of `Play Mode`):

```
move.w  #0,$B02E.w
jsr     $11A48.l          ; printsmall
addq.w  #2,$B02A.w
bra.b   *-
bclr.b  #3,$C2F8.w
movem.l (sp)+,d0-d1
rts
```

Disc (`HOCKEY.BIN` `$928C`):

```
move.w  #0,$18D5E.l
jsr     $38D9E.l
addi.w  #2,$18D5A.l       ; addq has no absolute-long form
bra.w   *-                ; the function grew, so bra.b no longer reached
bclr.b  #3,$17F76.l
movem.l (sp)+,d0-d1
rts
```

Same order, same registers, same `#3` and `#2`. `addq` became `addi` and `bra.b` became `bra.w` because that is what the long addresses force. The EA Hockey Night ticker is the same kind of pair: `$B028` became `$18D58`, and the `bsr.w $11BA4` / `bsr.w $11D3A` calls became `bsr.w $1DF80` / `bsr.w $1E19A`.

| Cartridge | Disc | What |
| --- | --- | --- |
| `$FFB028` (`$B028.w`) | `$18D58` | print x |
| `$FFB02A` | `$18D5A` | print y |
| `$FFB02E` | `$18D5E` | print attribute |
| `$FFC2F8` (`$C2F8.w`) | `$17F76` | the flag byte `sflags6` |
| `$11A48` printsmall | `$38D9E` | now an absolute call out of `HOCKEY.BIN` |
| `$11BA4` | `$1DF80` | still inside `HOCKEY.BIN` |
| `$11D3A` PushNumberWidth | `$1E19A` | still inside `HOCKEY.BIN` |

`$38D9E` and `$39258` are above the end of `HOCKEY.BIN` (`$2D20A`). They are linked addresses in the sub CPU's program RAM, not offsets in that file.

One path really changed. The address-error hex dump is byte for byte the same (`move.w (sp)+,d0` / `andi.w #$F,d0` / `addi.b #$30,d0`). The handler under it is not: the cartridge does `move #$2700,sr` and `bsr.w $11DE2` (printbigz); the disc does `bclr.b #5,$FF800F` and `jsr $39258`. That is the sub CPU comm flag, which the cartridge does not have.

The team block at the front of `HOCKEY.BIN` matches the cartridge from Montreal's colors through the start of the roster (733 bytes, cart `$37E`, disc `$7C`) and then splits. The cartridge continues into "Madison Square Garden"; the disc has "Eastern division" there.

`PLAYER.BIN` and `HOCKEY.BIN` share no 16-byte window with each other that matters, and `PLAYER.BIN` shares almost nothing with the cartridge ROM (39 windows of 16 bytes). It is new code on the sub CPU, not a slice of `HOCKEY.BIN`.

## Disassembly that builds

`npm run build:segacd` assembles two fragments and compares them to `cdbin/`. The cartridge ROM is not involved.

| Source | Compared to | Bytes |
| --- | --- | --- |
| `src/segacd/maincd.asm` | `cdbin/MAIN.BIN` | `$FF0000`-`$FF012F` (304) |
| `src/segacd/subboot.asm` | `cdbin/STARTER.BIN` | first `$90` bytes (144) |

`maincd.asm` is the main CPU command loop: read `$A12020` when sub flag bit 6 is set, dispatch through the long table at `$FF01BE`, and put the VBlank vector at `$FD08` back when the command finishes. `subboot.asm` is the sub CPU's first instructions, the flag handshake, BIOS function 0 at `$6044`, and `jmp $1B000` into `HOCKEY.BIN`.

`tools/segacd_relocs.py` prints more address pairs by lining up the instructions in front of a shared string. Pairs from a blind zip of those instructions are only a lead; the table above is the ones read against the bytes.
