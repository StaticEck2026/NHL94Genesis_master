# Contributing to NHL 94 Genesis

This is a bit-perfect disassembly of NHL Hockey 94 for the Sega Genesis. There is one release of the game, so there is no revision switch. The ROM is `lst/nhl94.bin`.

Read [README.md](README.md) first for how to build. This file says how changes are made so the repos stay
consistent with each other and with NHL 92, the root of the family (94 follows 93, which follows 92).

## 1. Every build must still match

The code, data and bytes must not change unless the change is the point of the PR. Before every push:

```
tools/verify_all.sh -q
```

It builds the full ROM and every segment listed in `tools/segments.json` (under wine on Linux or macOS) and compares each with `lst/nhl94.bin`.

A comment-only or rename-only change must not change a single byte. Never commit ROMs, `Extracted/` or
`output/`.

## 2. Names

- Use the earliest game's name for the same routine, variable or constant (92 first, then 93, then 94, ...).
  Copy 92's spelling and capitalisation exactly, including typos. Only a name that is wrong for what the
  code does may be changed, and then the change is made in every repo that has it.
- Never reuse a name for a different item. If a new name is needed, pick a descriptive one.
- Local labels (`.0`, `.loop`, `.next`, `.done`, `.exit`) follow 92: a short word where the branch has a clear
  meaning, a number for trivial jumps, and the parent routine's local names when the routine matches it.
- Record every rename in the name history file (`docs/name_map.csv`) using its existing columns. Do not leave
  `(was X)` or other history in comments.
- A routine that is the same code as a 92 routine but has another name here gets a `92 <name>` note in its
  comment. A routine that only exists in this game says so ("new in 93").

## 3. Names, not numbers

- A value that 92 (or an earlier game) names must use the name: sizes, counts, bit numbers, flags, penalty and
  sound numbers, offsets into structures. Define the constant in `src/stubinc/ram_addrs.inc` (RAM and constants) or `src/ram94.asm` if it does not exist yet.
- The address of a labelled table or routine is written as the label, never as a number
  (`#TeamList`, not `#$314`). Offsets inside data are `label-base` expressions, defined or used next to the data
  they point into.
- When a table has an equate per entry, 92 puts `Name = (*-Table)/4` or `Name equ (*-Table)` before each entry. Do the
  same unless the constants are needed by code that is assembled separately; then they go in `src/stubinc/ram_addrs.inc` (RAM and constants) or `src/ram94.asm`.
- A number is fine when the original code used one (a mask, a coordinate). Say what it is in a comment.

## 4. Comments: what to write

- Every symbol that is defined has a comment on its line: labels (also local ones), equates and RAM
  variables. A routine's label line says what it does, what it takes and returns, and where it is called from.
- Every file starts with a header that says what is in the file. It does not list the routines in order.
- Routines read as a story: a short comment for each step (a block of 3 to 8 instructions), what the
  registers hold, why a branch is taken, where the flow falls through.
- Anything not obvious gets a comment: magic numbers, bit tests (name the flag), tricks (code patched by
  `dc.w`, return addresses changed on the stack, shared tails), and differences from 92.
- Only write what you checked in the code. If you cannot tell why something is done, describe what the
  instructions do or write "probably". Never invent names.
- Do not shorten, reword or delete a comment that comes from 92. A factual error in one may be fixed when the
  PR says so.
- No IDA names or addresses (`loc_`, `sub_`, `unk_`), no source-file or segment names, no hard-coded ROM
  addresses (include lines may carry the address range of the file), no notes about other games except the
  `92 <name>` equivalents above and value differences such as `(92 $58)`.

## 5. Comment layout

- Indent with tabs; a tab is 4 columns.
- A trailing comment starts at column 36. If the code reaches column 36 or beyond, the comment goes one tab
  after the code.
- No comment line is wider than 110 columns. A longer comment continues on the next lines, starting in the same
  column as the first line.
- A header or block comment has paragraphs of at most 3 lines, separated by a `;` line. Keep headers short:
  what the file is, how it relates to its neighbours, and the few notes nobody could guess.
- A banner (`;====`) introduces a section; use one comment block under it, not a list of every routine.

`python3 tools/check_comments.py` checks width, column, paragraph length and doubled `;` markers. It must print
`comment layout OK` for the files you touched.

## 6. Where things go

- `nhl94.asm` includes the files in ROM order. A segment stub in `src/stubinc/<file>_stub.asm` assembles one file on its own, so a constant or address a file uses must be defined in an include the stub also reads (`ram_addrs.inc`) or in the stub's outside-address list.
- The RAM equates are included before `main94.asm`, so `InitialSP` (the reset vector value) keeps its own name; 92 reuses `Stack` for it.
- Names and routines that exist in 93 use the 93 name; a routine that is new in 94 says so in its comment.

## 7. Commits and pull requests

- One topic per branch and pull request; small commits. Branch from `main`.
- The pull request says what changed and that the build matches. State anything that is not obvious from the diff
  (a name fixed, a 92 comment corrected).
- Merge with a merge commit, not a squash, so the history of each change stays.
- After a merge the report at abdulahmad/nhl-disasm-report is regenerated by the maintainer.
- A change to a name, constant or comment convention that applies to more than one game is made in every game
  it applies to, starting from 92 and going forward.

## 8. Checklist

- [ ] `tools/verify_all.sh` matches
- [ ] `python3 tools/check_comments.py` is clean for the files you touched
- [ ] new symbols have comments, new constants replace the numbers they stand for
- [ ] names follow 92 (spelling, capitalisation); renames are in the history file
- [ ] no 92 comment was shortened or reworded
