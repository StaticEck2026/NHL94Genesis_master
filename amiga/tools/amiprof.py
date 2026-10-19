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
    wait = pc >> 31                     # a sample in rd_waitblit: its caller
    pc &= 0x7FFFFFFF
    v = pc - base
    if 0 <= v < 0x200000:
        j = bisect.bisect_right(keys, v) - 1
        c[('rd_waitblit <- ' if wait else '') + syms[j][1]] += 1
    else:
        c['(outside code %06x)' % (pc & 0xFFFF00)] += 1
print('%d samples' % n)
if len(d) >= 8 + 4 * n + 16:
    c0, t0, c1, t1 = struct.unpack('>IIII', d[8 + 4 * n:24 + 4 * n])
    hz = struct.unpack('>I', d[24 + 4 * n:28 + 4 * n])[0] if len(d) >= 28 + 4 * n else 60
    if t1 > t0:
        print('%.2f frames a second (%d frames in %.1f s since the F9 mark, the game at %d Hz)'
              % (hz * (c1 - c0) / (t1 - t0), c1 - c0, (t1 - t0) / hz, hz))
if len(d) >= 8 + 4 * n + 52:
    h = struct.unpack('>8I', d[28 + 4 * n:60 + 4 * n])
    if sum(h):
        print('frames shown for 1 .. 8+ vertical blanks: ' + ' '.join('%d' % x for x in h) +
              ' (%s)' % ' '.join('%.0f%%' % (100.0 * x / sum(h)) for x in h))
if len(d) >= 8 + 4 * n + 116:
    h = struct.unpack('>16I', d[60 + 4 * n:124 + 4 * n])
    if sum(h[:7]):
        print('vertical blanks from a frame\'s game state to its showing, 0 .. 6+: ' +
              ' '.join('%d' % x for x in h[:7]) + ' (mean %.2f); the sound\'s delay at the end: %d'
              % (sum(i * x for i, x in enumerate(h[:7])) / sum(h[:7]), h[15]))
for k, v in c.most_common(int(sys.argv[3]) if len(sys.argv) > 3 else 30):
    print('%6.2f%%  %s' % (100.0 * v / n, k))
