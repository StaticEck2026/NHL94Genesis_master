#!/usr/bin/env python3
"""rdcost.py LISTING PROFILE [N]: the harness' PC samples (NHL_PROF) by routine."""
import bisect, collections, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from sym import load

syms = load(sys.argv[1])
keys = [a for a, n in syms]
c = collections.Counter()
for line in open(sys.argv[2]):
    i = bisect.bisect_right(keys, int(line.split()[0], 16) - 0x200000) - 1
    c[syms[i][1] if i >= 0 else '?'] += 1
n = sum(c.values())
rd = sum(v for k, v in c.items() if k.startswith('rd_'))
print('renderer %.1f M cycles, other %.1f M' % (rd / 1000.0, (n - rd) / 1000.0))
for k, v in c.most_common(int(sys.argv[3]) if len(sys.argv) > 3 else 25):
    print('  %-24s %6.1f M %5.1f%%' % (k, v / 1000.0, 100.0 * v / n))
