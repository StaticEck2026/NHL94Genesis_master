#!/usr/bin/env python3
"""cmpshots.py DIR: compare each ami_N.png (the Amiga screen the harness took from the copper
list) with shot_N.png (the reference Genesis renderer) at the Genesis' 8 levels a colour
channel: the reference renderer's are linear, the Amiga's the measured Genesis output levels
(render.asm rd_gen2amiga). In the wide view (a 320 pixel Amiga screen, a 256 pixel Genesis
one) the Genesis screen is where it matches best, 0 to 64 pixels from the left (the renderer
moves it from the middle at the edges of plane B). Prints the frames that differ; exit status
1 if any do."""
import glob, os, sys
import numpy as np

AMI_LEVELS = [0, 52, 87, 116, 144, 172, 206, 255]


def ami_levels(img):
    """the Amiga's channel values as Genesis levels 0-7"""
    v = np.asarray(img, dtype=np.int32)[..., None]
    return np.abs(v - np.array(AMI_LEVELS)).argmin(axis=-1)

from PIL import Image

bad = 0
for ami in sorted(glob.glob(os.path.join(sys.argv[1], 'ami_*.png'))):
    ref = ami.replace('ami_', 'shot_')
    if not os.path.exists(ref):
        continue
    a, b = Image.open(ami).convert('RGB'), Image.open(ref).convert('RGB')
    la = ami_levels(a)
    lb = np.rint(np.asarray(b, dtype=np.int32) * 7 / 255).astype(int)
    offsets = [0]
    if a.size[0] == 320 and b.size[0] == 256:    # the wide view
        offsets = range(65)
    elif a.size != b.size:
        print('%s: size %s, reference %s' % (os.path.basename(ami), a.size, b.size))
        bad += 1
        continue
    n = min(int((la[:, o:o + b.size[0]] != lb).any(axis=-1).sum()) for o in offsets)
    if n:
        print('%s: %d pixels differ' % (os.path.basename(ami), n))
        bad += 1
print('%d frames compared, %d differ' % (len(glob.glob(os.path.join(sys.argv[1], 'ami_*.png'))), bad))
sys.exit(1 if bad else 0)
