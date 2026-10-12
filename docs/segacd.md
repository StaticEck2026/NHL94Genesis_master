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

Same order, same registers, same `#3` and `#2`. `addq` became `addi` and `bra.b` became `bra.w` because that is what the long addresses force. The EA Hockey Night ticker is the same kind of pair: `$B028` became `$18D58`.

| Cartridge | Disc | What |
| --- | --- | --- |
| `$FFB028` (`$B028.w`) | `$18D58` | print x |
| `$FFB02A` | `$18D5A` | print y |
| `$FFB02E` | `$18D5E` | print attribute |
| `$FFC2F8` (`$C2F8.w`) | `$17F76` | the flag byte `sflags6` |
| `$11086` random | `$37050` | absolute call |
| `$11340` ReadJoy1 | `$374F0` | absolute call |
| `$119B8` Framer | `$38CA0` | absolute call, 87 sites |
| `$11A48` printsmall | `$38D9E` | absolute call, 32 sites |
| `$11B92` printz | `$38F6E` | absolute call, 216 sites |
| `$11D3A` PushNumberWidth | `$3919A` | absolute call |
| `$11DE2` printbigz | `$39258` | absolute call, 36 sites |

`tools/segacd_relocs.py` finds these by matching six-instruction windows and keeping an absolute operand only when the cartridge address always becomes the same disc address. The full list is `docs/segacd_pairs.txt`.

Those `$37xxx`–`$39xxx` targets are above the end of `HOCKEY.BIN` (`$2D20A`). None of the six disc files, loaded flat, contains the reassembled bytes at that address. The same routines also exist inside `HOCKEY.BIN` (printsmall's register save is at `$1DDAC`) and are reached with `bsr`. A call site uses one or the other. The `$37xxx` image is the open question: it is linked, and it is not a raw slice of these files.

One path really changed. The address-error hex dump is byte for byte the same (`move.w (sp)+,d0` / `andi.w #$F,d0` / `addi.b #$30,d0`). The handler under it is not: the cartridge does `move #$2700,sr` and `bsr.w $11DE2` (printbigz); the disc does `bclr.b #5,$FF800F` and `jsr $39258`. `$39258` is that same printbigz. The new instruction is the sub CPU comm flag, which the cartridge does not have.

The team block at the front of `HOCKEY.BIN` matches the cartridge from Montreal's colors through the start of the roster (733 bytes, cart `$37E`, disc `$7C`) and then splits. The cartridge continues into "Madison Square Garden"; the disc has "Eastern division" there.

`PLAYER.BIN` and `HOCKEY.BIN` share no 16-byte window with each other that matters, and `PLAYER.BIN` shares almost nothing with the cartridge ROM (39 windows of 16 bytes). It is new code on the sub CPU, not a slice of `HOCKEY.BIN`.

## Disassembly that builds

`npm run build:segacd` assembles the fragments below and compares them to `cdbin/`. The cartridge ROM is not involved. The Sega CD assemble uses `/o oz-` so a written `$0(an)` stays a 16-bit displacement. The cartridge build still uses `/o oz+`.

Verified bytes are 6,544 of the 410,162 bytes in the four code files (1.6%). `MAIN.BIN` is contiguous from the first byte through `$FF183F` (6,208 of 60,416, 10.3%). `STARTER.BIN` is 336 bytes. `HOCKEY.BIN` and `PLAYER.BIN` are not transcribed yet. `GRAPH2.BIN` and `GTABLE.BIN` are still untouched.

| Source | Compared to | Bytes |
| --- | --- | --- |
| `src/segacd/maincd.asm` | `cdbin/MAIN.BIN` | `$FF0000`-`$FF0271` (626) |
| `src/segacd/maindma.asm` | `cdbin/MAIN.BIN` `$272` | `$FF0272`-`$FF04FF` (654) |
| `src/segacd/maincont.asm` | `cdbin/MAIN.BIN` `$500` | `$FF0500`-`$FF0CB7` (1,976) |
| `src/segacd/mainblit.asm` | `cdbin/MAIN.BIN` `$CB8` | `$FF0CB8`-`$FF12BF` (1,544) |
| `src/segacd/mainvdp.asm` | `cdbin/MAIN.BIN` `$12C0` | `$FF12C0`-`$FF183F` (1,408) |
| `src/segacd/subboot.asm` | `cdbin/STARTER.BIN` | first `$90` bytes (144) |
| `src/segacd/subheap.asm` | `cdbin/STARTER.BIN` `$4FA8` | `EngineIdle` and `GetData` (192) |

`maincd.asm` is the main CPU command loop: read `$A12020` when sub flag bit 6 is set, dispatch through the long table at `$FF01BE`, and put the VBlank vector at `$FD08` back when the command finishes. Past the handshake it clears the eight command words, waits on memory-mode bit 2, and hands word RAM back and forth (DMNA / RET in `$A12003`). Two commands add `$180000` to a sub CPU pointer so the main CPU sees the same word RAM (`$080000` there, `$200000` here).

`maindma.asm` is the word-RAM blit that command path calls. It expands nibbles, writes the VDP at `$C00000`, and sets up DMA. A source in `$200000`-`$240000` is adjusted by two when the address is odd. The slice ends on `cmpa.w #0,a0`, and `maincont.asm` is the rest of that routine: the VBlank-status spin at `$FF051C`, a copy of the `$23A450` block into `$FF284E`, VDP fills, and the helpers that add `$180000` to a pointer. A 9-long table sits at `$FF0C94`.

`mainblit.asm` reads a byte stream into `$FF2DB2`-`$FF2DBA` and shakes the gate-array flag bits at `$A12018` / `$A12028`. It ends with the 16-long handler table at `$FF1280`. `mainvdp.asm` is those handlers and the routines next to them: VDP data and register writes, waits on `$A12024`, and copies that add `$180000` before calling the DMA helper at `$FF0418`. The file stops on the `rts` at `$FF183E`. The following bytes are zero through `$FF1DBB`.

`subboot.asm` is the sub CPU's first instructions, the flag handshake, BIOS function 0 at `$6044`, and `jmp $1B000` into `HOCKEY.BIN`. `subheap.asm` is the Sierra C `EngineIdle` and `GetData` at `$262A8` (the `link a6` the boot jumps to). The function name is the bytes after each `rts`.

`tools/emit_m68k.py` writes a slice as SNASM (`moveq #-1` instead of `moveq #$FF`, unsized `btst` to a data register, `$FFFFFD08.w` instead of `$FD08.w`). `tools/segacd_relocs.py` is the six-instruction matcher behind `docs/segacd_pairs.txt`.
