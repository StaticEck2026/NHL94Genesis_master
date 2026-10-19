#!/bin/sh
# The renderer's CPU time in uninterrupted play: Start is pressed only until the game begins,
# the harness is deterministic (NHL_DETERM: every build plays the same game, the renderer's
# own work taking none of its time),
# and the harness' PC samples (one each 1000 cycles) are counted from frame FROM to END. The
# renderer draws every second game frame: the odd ones or the even ones (NHL_PHASE), and the
# work differs between the two, so both are measured and the mean is given (PHASES="0" for one).
# Usage: amiga/harness/playcost.sh [FROM] [END]   (defaults 2000 6000; FROM >= 2000)
FROM=${1:-2000}; END=${2:-6000}
cd "$(dirname "$0")/../.." || exit 1
T=${TMPDIR:-/tmp}/playcost.$$
mkdir -p $T
P=""; for f in $(seq 700 120 1180); do P="$P$f:80,$((f+10)):0,"; done
for PH in ${PHASES:-0 1}; do
  for F in $FROM $END; do
    NHL_PHASE=$PH NHL_DETERM=1 NHL_PROF=$T/prof_${PH}_$F.txt amiga/harness/nhlrun -c 8000000 -f $F -p "${P%,}" \
      -s $F -o $T output/amiga/nhl94.game 2>&1 | grep stopped | sed 's/.*, \([0-9]*\) frames drawn.*/\1/' > $T/fd_${PH}_$F.txt
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
import os
tot = collections.Counter(); frs = 0; each = []
phs = [int(x) for x in os.environ.get('PHASES', '0 1').split()]
for ph in phs:
    d = count('%s/prof_%d_%s.txt' % (t, ph, f1)) - count('%s/prof_%d_%s.txt' % (t, ph, f0))
    fr = int(open('%s/fd_%d_%s.txt' % (t, ph, f1)).read()) - int(open('%s/fd_%d_%s.txt' % (t, ph, f0)).read())
    each.append(sum(v for k, v in d.items() if k.startswith('rd_')) / fr)
    tot += d; frs += fr
rd = sum(v for k, v in tot.items() if k.startswith('rd_'))
print('frames %s-%s: the renderer %.1f k cycles a frame (%s)' % (f0, f1, rd / frs,
      ', '.join('%s game frames drawn %.1f k' % ('even' if p == 0 else 'odd', e) for p, e in zip(phs, each))))
for k, v in tot.most_common(40):
    if k.startswith('rd_') and v / frs >= 2: print('  %-22s %6.1f k' % (k, v / frs))
PY
# the game's state at the end (the reference renderer's picture): builds compare exactly only
# when it is the same (the game's course can still depend on the renderer's timing)
echo "game at frame $END: $(md5sum < $T/shot_$(printf %05d $END).png | cut -c1-12)"
rm -rf $T
