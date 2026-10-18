#!/bin/sh
# Harness regression run: presses Start every 120 frames (title, menus, into a game), saves the
# Amiga screen and the reference Genesis render at a few frames and compares them (frames outside
# fades: the Amiga shows the last frame it finished, which can be a vertical blank behind).
# Usage: amiga/harness/regress.sh [outdir] [frames to compare, comma separated]
OUT=${1:-/tmp/nhlshots}
SHOTS=${2:-1120,1300,1500,1800,2100,2500}
mkdir -p "$OUT"
rm -f "$OUT"/ami_*.png "$OUT"/shot_*.png
P=""; for f in $(seq 700 120 3000); do P="$P$f:80,$((f+10)):0,"; done
cd "$(dirname "$0")/../.." || exit 1
LAST=$(echo "$SHOTS" | tr , '\n' | sort -n | tail -1)
# each with the 3 frames before it, references for cmpshots.py (the Amiga can be behind)
ALL=$(for f in $(echo "$SHOTS" | tr , ' '); do echo $((f-3)) $((f-2)) $((f-1)) $f; done | tr ' ' '\n' | sort -nu | tr '\n' , | sed 's/,$//')
amiga/harness/nhlrun -c 8000000 -f "$LAST" -s "$ALL" -p "${P%,}" -o "$OUT" output/amiga/nhl94.game || exit 1
for f in $(echo "$ALL" | tr , ' '); do
  case ",$SHOTS," in *,$f,*) ;; *) rm -f "$OUT/ami_$(printf %05d $f).png" ;; esac
done
exec python3 amiga/harness/cmpshots.py "$OUT"
