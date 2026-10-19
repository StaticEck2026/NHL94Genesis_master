#!/bin/sh
# The renderer's CPU time in uninterrupted play: Start is pressed only until the game begins,
# the game's beam position reads are fixed (NHL_FIXEDHV, so every build plays the same game),
# and the harness' PC samples (one each 1000 cycles) are counted from frame FROM to END.
# Usage: amiga/harness/playcost.sh [FROM] [END]   (defaults 2000 6000)
FROM=${1:-2000}; END=${2:-6000}
cd "$(dirname "$0")/../.." || exit 1
T=${TMPDIR:-/tmp}/playcost.$$
mkdir -p $T
P=""; for f in $(seq 700 120 1180); do P="$P$f:80,$((f+10)):0,"; done
for F in $FROM $END; do
  NHL_FIXEDHV=1 NHL_PROF=$T/prof_$F.txt amiga/harness/nhlrun -c 8000000 -f $F -p "${P%,}" -o $T \
    output/amiga/nhl94.game 2>&1 | grep stopped | sed 's/.*, \([0-9]*\) frames drawn.*/\1/' > $T/fd_$F.txt
done
python3 - $T $FROM $END <<'PY'
import bisect, collections, sys
sys.path.insert(0, 'amiga/tools')
from sym import load
t, f0, f1 = sys.argv[1], sys.argv[2], sys.argv[3]
syms = load('output/amiga/nhl94.lst'); keys = [a for a, n in syms]
def count(p):
    c = collections.Counter()
    for line in open(p):
        i = bisect.bisect_right(keys, int(line.split()[0], 16) - 0x200000) - 1
        c[syms[i][1] if i >= 0 else '?'] += 1
    return c
d = count('%s/prof_%s.txt' % (t, f1)) - count('%s/prof_%s.txt' % (t, f0))
fr = int(open('%s/fd_%s.txt' % (t, f1)).read()) - int(open('%s/fd_%s.txt' % (t, f0)).read())
rd = sum(v for k, v in d.items() if k.startswith('rd_'))
print('frames %s-%s: %d drawn, the renderer %.1f k cycles a frame' % (f0, f1, fr, rd / fr))
for k, v in d.most_common(40):
    if k.startswith('rd_') and v / fr >= 2: print('  %-22s %6.1f k' % (k, v / fr))
PY
rm -rf $T
