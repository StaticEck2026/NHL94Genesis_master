#!/usr/bin/env python3
"""cmpshots.py DIR: compare each ami_N.png (the Amiga screen the harness took from the copper
list) with shot_N.png (the reference Genesis renderer) at the Genesis' 8 levels a colour
channel: the reference renderer's are linear, the Amiga's the measured Genesis output levels
(render.asm rd_gen2amiga). Prints the frames that differ; exit status 1 if any do."""
import glob, os, sys

AMI_LEVELS = [0, 52, 87, 116, 144, 172, 206, 255]


def ami_level(v):
    return min(range(8), key=lambda i: abs(AMI_LEVELS[i] - v))

from PIL import Image

bad = 0
for ami in sorted(glob.glob(os.path.join(sys.argv[1], 'ami_*.png'))):
    ref = ami.replace('ami_', 'shot_')
    if not os.path.exists(ref):
        continue
    a, b = Image.open(ami).convert('RGB'), Image.open(ref).convert('RGB')
    if a.size != b.size:
        print('%s: size %s, reference %s' % (os.path.basename(ami), a.size, b.size))
        bad += 1
        continue
    pa, pb = a.load(), b.load()
    n = 0
    for y in range(a.size[1]):
        for x in range(a.size[0]):
            if any(ami_level(u) != round(v * 7 / 255) for u, v in zip(pa[x, y], pb[x, y])):
                n += 1
    if n:
        print('%s: %d pixels differ' % (os.path.basename(ami), n))
        bad += 1
print('%d frames compared, %d differ' % (len(glob.glob(os.path.join(sys.argv[1], 'ami_*.png'))), bad))
sys.exit(1 if bad else 0)
