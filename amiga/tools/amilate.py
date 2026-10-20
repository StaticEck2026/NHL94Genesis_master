#!/usr/bin/env python3
"""amilate.py LISTING nhl94.prof [N] : where the frames shown late spend their time. A
-DPROFMARK=1 build (with PROFILE) puts each frame's start and end of drawing among the PC samples
(markers $3F0000xx); its event log says when each frame's copper list was set. A frame is late
when its list was set 2 or more vertical blanks after the one before. Prints the functions
sampled while late frames were drawn (the game's ticks that came meanwhile included), per frame,
against the frames on time, most more first; then each late frame's renderer functions."""
import sys, struct, bisect, collections, os
sys.path.insert(0, os.path.dirname(__file__))
from sym import load

syms = load(sys.argv[1])
keys = [a for a, n in syms]
d = open(sys.argv[2], 'rb').read()
base, n = struct.unpack('>II', d[:8])
smp = list(struct.unpack('>%dI' % n, d[8:8 + 4 * n]))
mk = 8 + 4 * n
pos = struct.unpack('>I', d[mk + 104:mk + 108])[0]     # (the samples' ring position)
if n == 65536:
    smp = smp[pos:] + smp[:pos]
o = mk + 132
epos, ecnt = struct.unpack('>II', d[o:o + 8])
M = 65536
ring = struct.unpack('>%dI' % M, d[o + 8:o + 8 + 4 * M])
evs = [ring[(epos + i) % M] for i in range(M)] if ecnt > M else list(ring[:ecnt])

# frames from the events: S (begun), D (drawn), C (its copper list set) in order; B counts blanks
frames, pend, vb, cur = [], collections.deque(), 0, None
for e in evs:
    c = chr(e >> 24)
    if c == 'B':
        vb += 1
    elif c == 'S':
        cur = {}
        frames.append(cur)
    elif c == 'D' and cur is not None:
        pend.append(cur)
    elif c == 'C' and pend:
        pend.popleft()['vb'] = vb
# the samples of each frame's drawing (between its markers); the last marker is the last frame
segs, cs = [], None
for v in smp:
    if (v & 0xFF000000) == 0x3F000000:
        if chr(v & 0xFF) == 'S':
            cs = []
            segs.append(cs)
        elif chr(v & 0xFF) == 'D':
            cs = None
    elif cs is not None:
        cs.append(v)
k = min(len(segs), len(frames))
segs, frames = segs[-k:], frames[-k:]


def name(v):
    pc = (v & 0x3FFFFFFF) - base
    if not 0 <= pc < 0x200000:
        return '(outside)'
    return ('rd_waitblit <- ' if v >> 31 else '') + syms[bisect.bisect_right(keys, pc) - 1][1]


cnt = {1: collections.Counter(), 2: collections.Counter()}
nf = {1: 0, 2: 0}
late = []
prev = None
for f, s in zip(frames, segs):
    if 'vb' not in f:
        prev = None
        continue
    if prev is not None and f['vb'] > prev:
        g = min(f['vb'] - prev, 2)
        nf[g] += 1
        c = collections.Counter(name(v) for v in s)
        cnt[g] += c
        if g == 2:
            late.append((f['vb'], f['vb'] - prev, c))
    prev = f['vb']
print('%d frames; on time %d, late %d' % (k, nf[1], nf[2]))
rows = sorted(set(cnt[1]) | set(cnt[2]),
              key=lambda x: -(cnt[2][x] / max(1, nf[2]) - cnt[1][x] / max(1, nf[1])))
print('%-36s %8s %8s' % ('samples a frame', 'on time', 'late'))
for r in rows[:int(sys.argv[3]) if len(sys.argv) > 3 else 30]:
    print('%-36s %8.2f %8.2f' % (r[:36], cnt[1][r] / max(1, nf[1]), cnt[2][r] / max(1, nf[2])))
print('late frames (vertical blank, blanks since the one before: the renderer\'s most sampled):')
for b, g, c in late:
    print('%6d %2d  %s' % (b, g, ' '.join('%s:%d' % (x[:24], y) for x, y in c.most_common()
                                         if 'rd_' in x)[:150]))
