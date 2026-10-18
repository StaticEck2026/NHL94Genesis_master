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
amiga/harness/nhlrun -c 8000000 -f "$LAST" -s "$SHOTS" -p "${P%,}" -o "$OUT" output/amiga/nhl94.game || exit 1
exec python3 amiga/harness/cmpshots.py "$OUT"
