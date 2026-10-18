#!/bin/sh
# Harness regression run: presses Start every 120 frames, compares the Amiga screen with the
# reference VDP renderer at a few frames (prints "frame N: K pixels differ" on a mismatch).
# Usage: amiga/harness/regress.sh [outdir]
OUT=${1:-/tmp/nhlshots}
mkdir -p "$OUT"
P=""; for f in $(seq 700 120 3000); do P="$P$f:80,$((f+10)):0,"; done
cd "$(dirname "$0")/../.." || exit 1
exec amiga/harness/nhlrun -c 8000000 -f 2500 -s 1100,1300,1500,1800,2100,2500 -p "${P%,}" -o "$OUT" output/amiga/nhl94.game
