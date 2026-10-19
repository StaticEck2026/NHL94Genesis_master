#!/usr/bin/env python3
"""rstsim.py LOG: replays a sprite log (a -DSPRLOG=1 build, the harness run with NHL_DBGPORT=1,
its stderr): per frame drawn in steady play (from frame 1700, each buffer drawn again 3 frames
on), the blitter's words for the sprites and for restoring plane B under them: whole sprite
boxes in an 8 line dirty map (as before trimming), the boxes of their pixels in maps of 8 to 1
lines, or each box restored by itself (a list)."""
import sys, collections
BUFH = 480
frames = collections.OrderedDict()
for line in open(sys.argv[1]):
    try: f = list(map(int, line.split()[1:]))
    except ValueError: continue
    if len(f) != 16: continue
    hf, buf, cnt, xorg, brow0, colx, sy, r0, r1, ncol, wb, bp0, bp1, l0, nl, nw = f
    if hf < 1700: continue
    frames.setdefault(cnt & 0xFFFF, (buf, []))[1].append(f)

def rects(spr, trimmed):
    hf, buf, cnt, xorg, brow0, colx, sy, r0, r1, ncol, wb, bp0, bp1, l0, nl, nw = spr
    if trimmed:
        x0, x1 = colx + bp0, colx + bp1
        y0, y1 = sy + l0, sy + l0 + nl - 1
    else:
        x0, x1 = colx, colx + ncol * 8 - 1
        y0, y1 = sy + r0, sy + r1 - 1
    px0, px1 = x0 + xorg - 32, x1 + xorg - 32
    c0, c1 = max(0, px0 >> 4), min(31, px1 >> 4)
    b0, b1 = max(0, y0 + brow0), min(BUFH - 1, y1 + brow0)
    return c0, c1, b0, b1

def map_restore(rs, g):
    rows = BUFH // g; wrap = 256 // g
    m = [0] * rows
    for c0, c1, b0, b1 in rs:
        if c1 < c0 or b1 < b0: continue
        bits = ((1 << (c1 - c0 + 1)) - 1) << c0
        for r in range(b0 // g, b1 // g + 1): m[r] |= bits
    words = blits = 0
    r = 0
    while r < rows:
        if not m[r]: r += 1; continue
        r0 = r; v = m[r]; r += 1
        while r < rows and r % wrap and m[r] == v: r += 1
        n = r - r0
        x = v
        while x:
            lo = (x & -x).bit_length() - 1
            ln = 0
            while x >> (lo + ln) & 1: ln += 1
            x &= ~(((1 << ln) - 1) << lo)
            words += n * g * ln * 6; blits += 1
    return words, blits

def list_restore(rs):
    w = b = 0
    for c0, c1, b0, b1 in rs:
        if c1 < c0 or b1 < b0: continue
        w += (b1 - b0 + 1) * (c1 - c0 + 1) * 6; b += 1 + (b0 < 256 <= b1)
    return w, b

res = collections.Counter(); n = 0
keys = list(frames)
last = {}
for cnt in keys:
    buf, sprs = frames[cnt]
    prev = last.get(buf)
    last[buf] = cnt
    if prev is None or (cnt - prev) & 0xFFFF != 3: continue     # steady drawing only
    old = frames[prev][1]
    n += 1
    res['spr old'] += sum((s[8] - s[7]) * (s[10] // 2) * 6 for s in sprs)
    res['spr trim'] += sum(s[14] * s[15] * 6 for s in sprs)
    res['blits spr'] += len(sprs)
    for g in (8, 4, 2, 1):
        w, b = map_restore([rects(s, True) for s in old], g)
        res['rst trim map%d' % g] += w; res['blits trim map%d' % g] += b
    w, b = map_restore([rects(s, False) for s in old], 8)
    res['rst old map8'] += w; res['blits old map8'] += b
    w, b = list_restore([rects(s, True) for s in old])
    res['rst trim list'] += w; res['blits trim list'] += b
print(n, 'frames (steady), per frame:')
for k in sorted(res): print('  %-20s %8.1f' % (k, res[k] / n))
