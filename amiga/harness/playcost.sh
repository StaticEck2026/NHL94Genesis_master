#!/bin/sh
# The renderer's CPU time in uninterrupted play: Start is pressed only until the game begins,
# the game's beam position reads are fixed (NHL_FIXEDHV, so every build plays the same game),
# and the harness' PC samples (one each 1000 cycles) are counted from frame FROM to END. The
# renderer draws every second game frame: the odd ones or the even ones (NHL_PHASE), and the
# work differs between the two, so both are measured and the mean is given.
# Usage: amiga/harness/playcost.sh [FROM] [END]   (defaults 2000 6000; FROM >= 2000)
FROM=${1:-2000}; END=${2:-6000}
cd "$(dirname "$0")/../.." || exit 1
T=${TMPDIR:-/tmp}/playcost.$$
mkdir -p $T
P=""; for f in $(seq 700 120 1180); do P="$P$f:80,$((f+10)):0,"; done
for PH in 0 1; do
  for F in $FROM $END; do
    NHL_PHASE=$PH NHL_FIXEDHV=1 NHL_PROF=$T/prof_${PH}_$F.txt amiga/harness/nhlrun -c 8000000 -f $F -p "${P%,}" \
      -o $T output/amiga/nhl94.game 2>&1 | grep stopped | sed 's/.*, \([0-9]*\) frames drawn.*/\1/' > $T/fd_${PH}_$F.txt
  done
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
tot = collections.Counter(); frs = 0; each = []
for ph in (0, 1):
    d = count('%s/prof_%d_%s.txt' % (t, ph, f1)) - count('%s/prof_%d_%s.txt' % (t, ph, f0))
    fr = int(open('%s/fd_%d_%s.txt' % (t, ph, f1)).read()) - int(open('%s/fd_%d_%s.txt' % (t, ph, f0)).read())
    each.append(sum(v for k, v in d.items() if k.startswith('rd_')) / fr)
    tot += d; frs += fr
rd = sum(v for k, v in tot.items() if k.startswith('rd_'))
print('frames %s-%s: the renderer %.1f k cycles a frame (even game frames drawn %.1f k, odd %.1f k)'
      % (f0, f1, rd / frs, each[0], each[1]))
for k, v in tot.most_common(40):
    if k.startswith('rd_') and v / frs >= 2: print('  %-22s %6.1f k' % (k, v / frs))
PY
rm -rf $T
