#!/usr/bin/env python3
"""prof.py LISTING SAMPLES : histogram of the harness's PC samples (NHL_PROF=file) by routine."""
import sys, bisect, collections
sys.path.insert(0, __import__('os').path.dirname(__file__))
from sym import load
syms = load(sys.argv[1])
keys = [s[0] for s in syms]
c = collections.Counter()
n = 0
for ln in open(sys.argv[2]):
    v = int(ln, 16) - 0x200000
    i = bisect.bisect_right(keys, v) - 1
    c[syms[i][1] if i >= 0 else '?'] += 1
    n += 1
for k, v in c.most_common(int(sys.argv[3]) if len(sys.argv) > 3 else 25):
    print('%6.2f%%  %s' % (100.0 * v / n, k))
