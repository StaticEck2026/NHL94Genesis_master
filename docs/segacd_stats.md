# Career stats and player photos

`PLAYER.BIN` is a sub CPU overlay, linked at 0, with a relocating startup (`lea 0(pc,a6.l),a6`). It is not a slice of `HOCKEY.BIN` or of the cartridge. The career page, the team stat page, and the player photo live here. `a6` is the module base for the whole file.

## Photo

`playerpic.asm` (`$1D54`) picks a picture, copies it into the buffer at `$BC000`, and asks the main CPU to DMA it.

The home/away flag is `$18(a6)`. It selects one of two pointer tables (`$1C(a6)` / `$48(a6)`, or `$20(a6)` / `$4C(a6)`). The player record is `$50(a6)`. The index is `$80(a6)`.

If the word at `(table, index*2)` is not negative, the picture is the long at `(pointers, index*4)`. That is a real photo. Otherwise the code uses a generic portrait packed in this file. Each frame is `$504` bytes.

| Hand bit `$4(a3)` bit 0 | What is shown |
| --- | --- |
| Set, skater (`$5(a3)` is 0) | The still at `$68E4` |
| Clear, skater | `$6DE8` plus frame `$104(a6)`, kept below 3 |
| Set, goalie | The still at `$40C4` |
| Clear, goalie | `$45C8` plus frame `$105(a6)`, kept below 7 |

`$40C4 + 8*$504` is `$68E4`, and `$68E4 + $504` is `$6DE8`. The two `lea` targets for a position are the first frame and the rest of one strip: 8 goalie frames, then 4 skater frames. Only the clear hand bit animates.

Word 0 of a frame is skipped. Word 1 (`$0024` on the generic frames) is shifted left 4 and that many words are copied to `$BC000`. Eight longs from `$20` past that copy go to the palette buffer at `$BBCF0`. The code then forces `$EEE` at `$BBCF0` and `$444` at `$BBCB0`, `$BBCD0`, `$BBCF0`, and `$BBD10`.

The blit is 6 by 6. Each cell posts gate command `$B` (a long at `$FF8022`) and command `$D` (a word at `$FF8022`), with the bit 6 / bit 7 handshake on `$FF800E` / `$FF800F`. That is the sub CPU asking the main CPU to DMA the photo. `$B0(a6)` being 1 or 2 draws an extra highlight through `$281C` before a second sprite block.

When the record is not a career record (`$44(a6)` is 0), the caption is `lea $2966(pc)` or `lea $295B(pc)`. The ASCII `Player # ` is at `$2967` and `Goalie # ` is at `$295C`. The `lea` lands on the byte in front of the text.

## Career rows

`playercareer.asm` (`$2010`) returns immediately when `$44(a6)` is 0. The photo function calls it with `$EE(a6)` in `d0`, so the same routine paints the career block under the picture and can be entered on its own.

Records are a linked list. The word at the start is the skip to the next record. Text sits at `+5`. The walk stops when the word at offset 4 is `$656C` or `$656E`.

The header is `Regular` at `$4049`, or `Playoff` at `$4051` when `$A6(a6)` is below `$58(a6)`. `$58(a6)` also skips that many column names and that many bytes of each row. The column names that follow are:

```
Season Club Lea Gp G A Tp Pim     (skater, regular and playoff)
Season Club Lea Gp W L T Mins Ga So Avg
Gp W L Mins Ga So Avg             (goalie)
```

Up to 7 rows are painted. Each row builds a VDP address from `$B802` (the `lsl.l #2` / `lsr.w #2` / `swap` / `addi.l #$40000000` pack) and posts it as gate command `$B`. A name is three characters, a space, then the rest of the string up to a NUL, printed through `$3C16`.

## Team page

`playerpage.asm` (`$23D0`) is the page behind that. `$54(a6)` picks the block:

| `$54(a6)` | Block |
| --- | --- |
| 0 | The advantage lines, from the team file |
| 1 | `$24(a6)` or `$34(a6)`, home or away |
| anything else | `$28(a6)` or `$38(a6)` |

`$56(a6)` skips that many records, with the same `$656C` / `$656E` end words. The title is `Players` (`$3FCA`) or, when `$54(a6)` is 2, `Goalies` (`$3FD4`). The column strip at `$3FDE` (goalies use `$4004`) is:

```
Gp G A Pts +/- Pim PP Sh Gw Gt S Pctg
Gp Mins Ga Avg. W L T SO En Shts
pGP pMIN pGA pAVG pW pL pSO pEN pSA
```

The advantage page (`$2670`) prints the length-prefixed lines at `$28D0`:

```
Power play advantage
Penalty killing disadvantage
Home team advantage
Road team disadvantage
Number of forwards
Number of defensemen
```

The `lea` is one byte in front of `Power play advantage`. Each line is a counted string. The value next to it is scaled by 100 and divided by 2, or by 7 on the last pair, then printed at x `$1E1` stepping by `$28`.
