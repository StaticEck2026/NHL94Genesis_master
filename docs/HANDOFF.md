# HANDOFF: comment and name cleanup (NHL94)

## Purpose
Make this bit-perfect 68000 SNASM disassembly read like clean original source: accurate names that follow the
NHL92 Genesis (EA original) lineage, and comments without disassembler or porting artifacts. Code, data and
bytes never change: every build must still MATCH the retail ROM.

## Setup
ROMs (gitignored, never commit): lst/nhl94.bin.
Windows: `npm run build:retail` (tools/prebuild.js, build94.bat, fixopcodes, verify);
segments: `npm run seg:<name>` (all keys in package.json `seg:*`).
Linux (wine): `apt install wine wine32` (dpkg --add-architecture i386), `export WINEDEBUG=-all`, then
1. `node tools/prebuild.js retail` (checks the ROM, extracts into Extracted/ if missing or incomplete; same as `node tools/extractAssets94.js lst/nhl94.bin`), then `export NHL_PREBUILD_DONE=1` so the .bat files skip their own pre-step (no node under wine). Accepts the one retail ROM (SHA-1 7b1489ab...); other ROMs are refused.
2. `wine cmd /c "set rev=0&& set checksum=1&& build94.bat"`
3. `node tools/fixopcodes.js "output/nhl94 .lst" output/nhl94.bin`
4. `node tools/verifyRom.js output/modified_nhl94.bin <reference ROM>` must print MATCH
5. Segments: run each package.json `seg:*` chain the same way (`wine cmd /c "buildseg.bat <seg>"`, then its node steps); tools/verifySegment.js must MATCH.
Failed-assembly detection: delete output/*.bin first, then check the bin exists and is fresh and that output/Build*.log has no
`^[1-9][0-9]* error` line. tools/verify_all.sh does all of this (top ROM + every segment).

## Naming lineage
- 92G (abdulahmad/NHL92Genesis, EA source) is the root. 93 -> 92; 94 -> 93 -> 92; 95 -> 94 -> 93 -> 92.
- Use the earliest game's name for the same routine/variable. 92 names are kept as-is, typos included.
- A name not from 92 that is inaccurate (checked against the routine body / usage) gets fixed, and the fix is propagated
  forward: 93 -> 94 -> 95, and to abdulahmad/NHLPA93SNES for 93 names that exist there.
- Clash rule: never reuse a name already used for a different item; pick a descriptive name instead.
- Teams: 93 (unlicensed) uses city names only; 94/95 use NYIslanders/NYRangers (NYI/NYR) style names.

## Comment rules
No other games' names or "X name" notes, no source-file/segment names, no IDA references (IDA, loc_, sub_, unk_),
no "(was: X)" history, no hardcoded ROM addresses (keep VRAM/RAM values, include address maps, RAM equate address
comments), no "only in 9x" tags ("New in 94/95:" allowed in file/section headers). Keep real explanations and
value-difference notes like "(94 $58)" / "92 used bit 6". Every routine has a header comment. Concise.

## Records
- docs/name_map.csv: every rename (old -> new, source/reason). History lives here, not in comments.
- docs/name_review_9x.md: name-accuracy checklist (name, verdict) per module.

## Conventions
Small commits per module; builds MATCH before every push; `git pull --rebase origin main` then push to main.
No force-push, no PRs, never commit ROMs, Extracted/ or output/.

## Local label style
Follow 92G (EA source): ~31% of its locals are number-only (.0, .1 ...), the rest short lowercase words
(.loop, .next, .top, .done, .ex/.exit, .ok, .wait, .skip, plus abbreviations like .nna, .nodec, .sr).
- Give a word where the branch has a clear meaning (loop top, next item, skip/no-X case, exit, wait).
- Keep plain numbers for trivial jumps and for locals inherited from a matching parent routine.
- A routine that matches a parent routine (92 or 93) uses the parent's local names.
- Data tables indexed by number (frames, team data) stay numeric, as in 92.
- Renames are scope-aware (routine scope, code part only, never comments); diff-review every commit.
  Tools on the box: /workspace/tools_ll/ll.py (rename/list), prop.py (copy parent local names).

## Current state / Next
- Comment review: done in 93, 94, 95 and NHLPA93SNES.
- Name pass (full body read), records in docs/name_review_93.md / _94.md / _95.md:
  - Phase A (93): DONE, all modules. Renames propagated to 94/95/NHLPA93SNES.
  - Phase B (94): DONE (all src modules, RAM names, equates; docs/name_review_94.md).
  - Phase C (95): DONE (all modules, ram95, graphics95, frames95, sound95; docs/name_review_95.md).
- Local label pass (locals + header register notes; checklist "Local labels" in docs/name_review_94.md):
  all 94 modules done (later modules by branch-structure review); 93->94 local name consistency check done
  (tools_ll/consist.py). Next: 95G (MISMATCH routines from
  prop.py, then new-in-95 routines, then data labels/equates).
- Header rewrite (file header comments, 92 style): 94G nhl94, main, teamdata, frames, ram, macros, sega, stubinc, hockey, menu, stats, replay, input, assign, checks, video, penalty, collide, display, setup, all modules and stubs done (94G complete).
- Restructure: root .js tools (extractAssets94, fixopcodes, verifyRom, verifySegment, sync) moved to tools/; run from repo root as node tools/<name>.js (default Extracted/output paths resolve from the repo root). Fresh extract + ROM + all segments MATCH.
- Header rewrite 2 (story-style file headers, model 93G hockey93/main93/menu93): all 94G modules done. MATCH.
- Boundary moves (Task D, routine names/headers only): check4bench input94 -> assign94 (bench assignment);
  UnpackNibbles + WeightedRandomSelect checks94 -> video94 (shared helpers); ResetCardTimer, PlayerCardTimer,
  PlayerCardScreen optsetup94 -> cards94 (player cards); the name entry block NameEntryScreen ... WriteNameRecord
  cards94 -> records94 (user name entry); ShootoutModeBox records94 -> shootout94. Stub orgs/equates,
  package.json, nhl94.asm and the ROM map updated. MATCH.
- Segment stubs moved to src/stubinc/ (buildseg.bat assembles stubinc\<seg>_stub.asm). MATCH.
- Extractor takes any known retail ROM: SHA-1 detection (one retail version, 1993.JUL -00), per-version offset map, clear refusal of unknown ROMs. verify_all.sh extracts fresh first. Fresh extract + ROM + all segments MATCH.
- Build pre-step: every entry point (npm build:*/seg:* scripts and the .bat files) runs tools/prebuild.js first. It checks the ROM (path, SHA-1, size; stops with a message naming the exact file and version if it is missing or wrong, ROMs are not in the repo) and re-runs the extractor when Extracted/ is missing or incomplete. The extractor writes Extracted/.extract-complete.json last (ROM SHA-1, extractor SHA-1, every file and size). npm scripts set NHL_PREBUILD_DONE=1 so the .bat does not repeat it; verify_all.sh runs it with Linux node. Tested with Windows npm/cmd under wine: fresh build auto-extracts and MATCHes; missing ROM stops with the message. MATCH.
