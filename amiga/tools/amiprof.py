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
busy = 0
for i in range(n):
    pc, = struct.unpack('>I', d[8 + 4 * i:12 + 4 * i])
    wait = pc >> 31                     # a sample in rd_waitblit: its caller
    busy += (pc >> 30) & 1              # the blitter busy then
    pc &= 0x3FFFFFFF
    v = pc - base
    if 0 <= v < 0x200000:
        j = bisect.bisect_right(keys, v) - 1
        c[('rd_waitblit <- ' if wait else '') + syms[j][1]] += 1
    else:
        c['(outside code %06x)' % (pc & 0xFFFF00)] += 1
print('%d samples, the blitter busy in %.1f%%' % (n, 100.0 * busy / max(1, n)))
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
if len(d) >= 8 + 4 * n + 132 and t1 > t0:
    g, r, v = struct.unpack('>3I', d[124 + 4 * n:136 + 4 * n])
    lines = 15625.0 if hz == 50 else 15734.0       # (horizontal syncs a second)
    el = (t1 - t0) / hz
    tot = (g + r + v) / lines
    print('time: game %.1f%%, its vblank code %.1f%%, renderer %.1f%% (of %.1f s accounted, %.1f s elapsed)'
          % (100 * g / lines / el, 100 * v / lines / el, 100 * r / lines / el, tot, el))
    print('      game %.2f ms a game frame (%.2f of it the vblank code), renderer %.2f ms a frame drawn'
          % (1000 * (g + v) / lines / (t1 - t0), 1000 * v / lines / (t1 - t0),
             1000 * r / lines / max(1, c1 - c0)))
if len(d) >= 8 + 4 * n + 116 and t1 > t0 and c1 > c0:
    h = struct.unpack('>16I', d[60 + 4 * n:124 + 4 * n])
    if h[7] or h[8]:
        print('blits a frame drawn: %.1f; the copper started again %.1f times; level 3 interrupts %.1f'
              % (h[7] / (c1 - c0), h[8] / (c1 - c0), h[9] / (c1 - c0)))
if len(d) >= 8 + 4 * n + 116:
    h = struct.unpack('>16I', d[60 + 4 * n:124 + 4 * n])
    if h[10] and h[11] < 100000:
        print('game ticks put off while the game ran (BENCH): %d, run all the same %d' % (h[10], h[11]))
    if h[10] and h[11] >= 100000:
        print('colour clocks for 1024 word writes: chip %d, fast %d, a register %d; 1024 chip reads %d; '
              '256 chip writes during a blit %d%s' % (h[10], h[11], h[12], h[13], h[14] & 0x7FFFFFFF,
              '' if h[14] & 0x80000000 else ' (the blit ended first)'))
for k, v in c.most_common(int(sys.argv[3]) if len(sys.argv) > 3 else 30):
    print('%6.2f%%  %s' % (100.0 * v / n, k))
