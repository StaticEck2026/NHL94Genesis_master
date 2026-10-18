#!/usr/bin/env python3
"""amiprof.py LISTING nhl94.prof [N] : histogram of the PC samples a -DPROFILE build writes on exit."""
import sys, struct, bisect, collections, os
sys.path.insert(0, os.path.dirname(__file__))
from sym import load
syms = load(sys.argv[1])
keys = [s[0] for s in syms]
d = open(sys.argv[2], 'rb').read()
base, n = struct.unpack('>II', d[:8])
c = collections.Counter()
for i in range(n):
    pc, = struct.unpack('>I', d[8 + 4 * i:12 + 4 * i])
    v = pc - base
    if 0 <= v < 0x200000:
        j = bisect.bisect_right(keys, v) - 1
        c[syms[j][1]] += 1
    else:
        c['(outside code %06x)' % (pc & 0xFFFF00)] += 1
print('%d samples' % n)
for k, v in c.most_common(int(sys.argv[3]) if len(sys.argv) > 3 else 30):
    print('%6.2f%%  %s' % (100.0 * v / n, k))
