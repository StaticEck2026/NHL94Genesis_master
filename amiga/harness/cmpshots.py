#!/usr/bin/env python3
"""cmpshots.py DIR: compare each ami_N.png (the Amiga screen the harness took from the copper
list) with shot_N.png (the reference Genesis renderer) at the Genesis' 8 levels a colour
channel: the reference renderer's are linear, the Amiga's the measured Genesis output levels
(render.asm rd_gen2amiga). The Amiga shows a frame once its blits are done, so it can be up to
a few frames behind the game: each screen is compared with the references of its frame and of
the 3 before it (shot_N-1.png ...) that are there, and the closest counts. Prints the frames that
differ; exit status 1 if any do."""
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
    frame = int(ref[-9:-4])
    a = Image.open(ami).convert('RGB')
    la = ami_levels(a)
    n = None
    for k in range(4):
        r = os.path.join(os.path.dirname(ref), 'shot_%05d.png' % (frame - k))
        if not os.path.exists(r):
            continue
        b = Image.open(r).convert('RGB')
        if a.size != b.size:
            continue
        lb = np.rint(np.asarray(b, dtype=np.int32) * 7 / 255).astype(int)
        m = int((la != lb).any(axis=-1).sum())
        n = m if n is None else min(n, m)
    if n is None:
        print('%s: no reference of its size' % os.path.basename(ami))
        bad += 1
        continue
    if n:
        print('%s: %d pixels differ' % (os.path.basename(ami), n))
        bad += 1
print('%d frames compared, %d differ' % (len(glob.glob(os.path.join(sys.argv[1], 'ami_*.png'))), bad))
sys.exit(1 if bad else 0)
