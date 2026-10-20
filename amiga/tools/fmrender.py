#!/usr/bin/env python3
"""Render the game's 32 YM2612 FM patches as Amiga samples (build step of the Amiga port).

Paula has no FM synthesis, so each patch is played as a sample: 8 bit, rendered at 20000 Hz.
A patch is rendered at the pitch bands it is used at in the songs and sound effects (an octave
a band), so every note plays back at 0.71 to 1.41 times the render rate (14.1 to 28.3 kHz: the
top is as fast as Paula plays, a period of 124). A sound that holds is the attack (the envelopes until they
settle) then a loop of 2 periods; the rest of its envelope (decay, and the release at key off)
is a volume envelope at run time (amiga/src/sound.asm). A sound that dies away by itself is one
sample with no loop.

The synthesis is a floating point model of the YM2612: 4 operators, the 8 algorithms,
operator 1 feedback, MUL, TL, AR/D1R/D2R/SL envelopes with key scaling. Carriers are rendered
at TL 0 (the driver sets their TL from the note volume); modulators keep the patch TL.
Detune, SSG-EG and the LFO are left out. FM with feedback has harmonics far above the sample
rate, which would fold back as harsh inharmonic noise: the patches are synthesised at OS times
the rate and low-pass filtered (windowed sinc) before they are decimated.

Needs numpy. Usage: fmrender.py <Extracted/NHL94/Sound directory> out.i
"""
import glob, math, os, sys
import numpy as np

SR = 20000                # render rate: a note at the band's pitch plays back at this rate
OS = 8                    # synthesis at OS * SR
BANDS = [20.0 * 2 ** k for k in range(8)]   # band pitches (Hz); a note f uses the highest <= f*sqrt 2
ATTACK_MAX = 0.25         # at most this much attack before the loop (seconds)
SETTLE = 0.04             # attack continues this long after the last operator's attack ends
ONESHOT_MAX = 0.70        # length limit of a sound with no loop
DIES = 0.50               # a sound silent this long after its attack is one shot
FPS = 60                  # run time envelope steps a second
PAULA = 3546895           # Paula clock (PAL)
FSTEP = 7670454 / 144 / 2 ** 21   # Hz per fnum unit at block 0 (0.025399)
EGCLK = 7670454 / 144 / 3         # envelope generator clock (Hz)
TAPS = 511                # low-pass filter length at OS * SR
CUTOFF = 0.42             # its cut off, as a fraction of SR

SLOT_OF_BYTE = [0, 2, 1, 3]   # patch byte i -> operator (the chip orders them S1, S3, S2, S4)
CARRIERS = {0: [3], 1: [3], 2: [3], 3: [3], 4: [1, 3], 5: [1, 2, 3], 6: [1, 2, 3], 7: [0, 1, 2, 3]}
FNUM = [0x146, 0x159, 0x16E, 0x184, 0x19B, 0x1B3, 0x1CD, 0x1E8, 0x205, 0x224, 0x245, 0x268]


def parse(patch):
    ops = [dict() for _ in range(4)]
    for i in range(4):
        o = ops[SLOT_OF_BYTE[i]]
        o['mul'] = patch[0 + i] & 15
        o['tl'] = patch[4 + i] & 127
        o['ks'] = patch[8 + i] >> 6
        o['ar'] = patch[8 + i] & 31
        o['d1r'] = patch[12 + i] & 31
        o['d2r'] = patch[16 + i] & 31
        o['sl'] = patch[20 + i] >> 4
        o['rr'] = patch[20 + i] & 15
    return ops, patch[28] & 7, (patch[28] >> 3) & 7


def rate_step(rate):
    """Attenuation units (1023 = 96 dB) the envelope moves per EG clock at this rate."""
    if rate < 4:
        return 0.0
    rate = min(rate, 63)
    if rate < 48:
        return [0.5, 0.625, 0.75, 0.875][rate & 3] / (1 << (11 - (rate >> 2)))
    return min(8.0, [1.0, 1.25, 1.5, 1.75][rate & 3] * 2 ** ((rate >> 2) - 12))


def keycode(freq):
    block = 0
    while freq / (2 ** block * FSTEP) >= 2048 and block < 7:
        block += 1
    fnum = int(freq / (2 ** block * FSTEP))
    f11, f10, f9, f8 = (fnum >> 10) & 1, (fnum >> 9) & 1, (fnum >> 8) & 1, (fnum >> 7) & 1
    n3 = (f11 & (f10 | f9 | f8)) | ((1 - f11) & f10 & f9 & f8)
    return block * 4 + (f11 << 1) + n3


def setup(patch, f0, rate):
    ops, alg, fb = parse(patch)
    kc = keycode(f0)
    for o in ops:
        ksr = kc >> (3 - o['ks'])
        o['ra'] = rate_step(2 * o['ar'] + ksr) if o['ar'] else 0.0
        o['instant'] = o['ar'] and 2 * o['ar'] + ksr >= 62
        o['rd1'] = rate_step(2 * o['d1r'] + ksr) if o['d1r'] else 0.0
        o['rd2'] = rate_step(2 * o['d2r'] + ksr) if o['d2r'] else 0.0
        o['rr_'] = rate_step(4 * o['rr'] + 2 + ksr)
        o['slatt'] = 992.0 if o['sl'] == 15 else o['sl'] * 32.0
        o['att'] = 1023.0
        o['stage'] = 0                  # 0 attack, 1 decay, 2 sustain (second decay)
        o['phase'] = 0.0
        o['inc'] = f0 * (0.5 if o['mul'] == 0 else o['mul']) / rate
    return ops, alg, fb


def env_step(o, clocks):
    if o['stage'] == 0:
        if o['instant']:
            o['att'] = 0.0
        elif o['ra']:
            k = o['ra'] * clocks
            n = int(k) + 1
            for _ in range(n):
                o['att'] -= max((o['att'] + 1) * o['ra'] / 16, min(o['ra'], 1.0)) * clocks / n
                if o['att'] <= 0:
                    break
        if o['att'] <= 0:
            o['att'] = 0.0
            o['stage'] = 1
    if o['stage'] == 1:
        o['att'] += o['rd1'] * clocks
        if o['att'] >= o['slatt']:
            o['att'] = o['slatt']
            o['stage'] = 2
    elif o['stage'] == 2:
        o['att'] = min(1023.0, o['att'] + o['rd2'] * clocks)


def render(patch, f0, n, freeze=None):
    """n samples at OS * SR of the patch keyed on at pitch f0; the envelopes stop moving at
    sample freeze. Returns (samples, operator states at the end, sample at which every attack
    had ended)."""
    rate = SR * OS
    ops, alg, fb = setup(patch, f0, rate)
    carriers = CARRIERS[alg]
    # envelopes: stepped at the EG clock, then spread over the samples
    ticks = int(n * EGCLK / rate) + 2
    tfreeze = ticks if freeze is None else int(freeze * EGCLK / rate) + 1
    att = np.zeros((4, ticks))
    attacked = None
    for t in range(ticks):
        if t < tfreeze:
            for o in ops:
                env_step(o, 1.0)
            if attacked is None and all(o['stage'] for o in ops):
                attacked = int(t * rate / EGCLK)
        for i, o in enumerate(ops):
            att[i, t] = o['att']
    tt = np.arange(n) * (EGCLK / rate)
    gain = []
    for i in range(4):
        a = np.interp(tt, np.arange(ticks), att[i]) + (0 if i in carriers else ops[i]['tl'] * 8)
        gain.append(np.where(a < 1023, 10 ** (-a * 0.09375 / 20), 0.0))
    t = np.arange(n)
    ph = [(t * o['inc']) % 1.0 for o in ops]
    tau = 2 * math.pi
    # operator 1 with its feedback, one sample after the other
    s1 = np.empty(n)
    g0, p0 = gain[0], ph[0]
    k = 2.0 ** (fb - 7) if fb else 0.0
    m0 = m1 = 0.0
    sin = math.sin
    for j in range(n):
        v = sin(tau * (p0[j] + (m0 + m1) * k)) * g0[j]
        s1[j] = v
        m0, m1 = m1, v

    def op(i, mod=0.0):
        return np.sin(tau * (ph[i] + 4 * mod)) * gain[i]
    if alg == 0:
        y = op(3, op(2, op(1, s1)))
    elif alg == 1:
        y = op(3, op(2, s1 + op(1)))
    elif alg == 2:
        y = op(3, s1 + op(2, op(1)))
    elif alg == 3:
        y = op(3, op(1, s1) + op(2))
    elif alg == 4:
        y = op(1, s1) + op(3, op(2))
    elif alg == 5:
        y = op(1, s1) + op(2, s1) + op(3, s1)
    elif alg == 6:
        y = op(1, s1) + op(2) + op(3)
    else:
        y = s1 + op(1) + op(2) + op(3)
    return y, ops, attacked


def lowpass():
    """Windowed sinc (Blackman) low-pass at OS * SR, cut off CUTOFF * SR, unity gain."""
    m = np.arange(TAPS) - (TAPS - 1) / 2
    fc = CUTOFF / OS
    h = 2 * fc * np.sinc(2 * fc * m) * np.blackman(TAPS)
    return h / h.sum()


LOWPASS = lowpass()


def decimate(x):
    """Filter and keep every OS-th sample (zero phase: output sample j is input sample j * OS)."""
    y = np.convolve(x, LOWPASS)[(TAPS - 1) // 2:]
    return y[::OS][:len(x) // OS]


def make_sample(patch, band):
    """One render of the patch for a band. Returns (data, loop start, loop length, carrier op
    state at the loop) with loop length 0 for a one shot sound."""
    spc = max(2, round(SR / band))      # samples a period
    f0 = SR / spc
    per2 = 2 * spc                      # the loop: 2 periods (MUL 0 is half the pitch)
    first, ops, attacked = render(patch, f0, int((ATTACK_MAX + DIES) * SR * OS))
    if attacked is None:
        attacked = int(ATTACK_MAX * SR * OS)
    attacked //= OS
    loop = max(per2, -(-int(attacked + SETTLE * SR) // per2) * per2)
    loop = min(loop, max(per2, int(ATTACK_MAX * SR) // per2 * per2))
    main = ops[3]                       # S4 is a carrier in every algorithm
    if main['att'] >= 1000 or (main['stage'] == 2 and main['rd2'] * EGCLK * DIES > 1023):
        # dies away: one shot, cut where it is silent
        full = decimate(render(patch, f0, int(ONESHOT_MAX * SR * OS))[0])
        loud = np.nonzero(np.abs(full) > 0.004)[0]
        n = int(loud[-1]) + 1 if len(loud) else 2
        n += n & 1
        return full[:n], n, 0, None
    # the envelopes stop at the loop; the loop starts once the filter has settled after that
    settle = -(-(TAPS // OS + 2) // per2) * per2
    total = loop + settle + per2
    full, ops, _ = render(patch, f0, total * OS, freeze=loop * OS)
    out = decimate(full)[:total]
    return out, loop + settle, per2, ops[3]


def bands_used(sound_dir):
    """Band numbers each patch's notes fall in, from the song and sound effect event streams."""
    used = {}
    for fn in sorted(glob.glob(os.path.join(sound_dir, '*cmdstream*.bin'))):
        d = open(fn, 'rb').read()
        patch = {}
        for i in range(0, len(d) - 3, 4):
            st = d[i + 1]
            if st == 0:
                continue
            if st & 0x70 == 0x40:
                patch[st & 15] = d[i + 2]
            if st & 0x70 == 0x10 and d[i + 3] and patch.get(st & 15, 0x60) < 32:
                n = d[i + 2]
                used.setdefault(patch[st & 15], set()).add(band_of(FNUM[n % 12] * 2 ** (n // 12) * FSTEP))
    return used


def band_of(f):
    b = 0
    for i, g in enumerate(BANDS):
        if g <= f * math.sqrt(2):
            b = i
    return b


def per_frame(units_per_clock):
    """Run time envelope speed: attenuation units a frame, 8.8 fixed point (at most 255 units)."""
    return min(0xFFFF, int(round(units_per_clock * EGCLK / FPS * 256)))


def main():
    sound_dir, outname = sys.argv[1], sys.argv[2]
    raw = open(os.path.join(sound_dir, 'fm_instrument_patches.bin'), 'rb').read()
    used = bands_used(sound_dir)
    lines = [';\tGenerated by amiga/tools/fmrender.py from the game\'s FM patches: the patches as',
             ';\tsamples (signed 8 bit) at the pitch bands they are used at.', '',
             'FM_BANDS\tequ\t%d' % len(BANDS), '', '\tsection\tsndchip,data_c']
    renders = []        # (label, words, loop start, loop words, K)
    patches = []        # (render per band, r1, sl, r2, rr)
    total = 0
    for p in range(len(raw) // 32):
        patch = raw[p * 32:p * 32 + 32]
        bands = sorted(used.get(p, {3}))
        made = {}
        main = None
        datas = []
        for b in bands:
            data, ls, ll, op = make_sample(patch, BANDS[b])
            datas.append((b, data, ls, ll))
            if op is not None and main is None:
                main = op
        peak = max(float(np.abs(d[1]).max()) for d in datas)
        scale = 127.0 / max(peak, 1.0)        # quiet patches stay quiet
        for b, data, ls, ll in datas:
            label = 'fm_p%02d_b%d' % (p, b)
            lines.append(label)
            bs = (np.clip(np.round(np.asarray(data) * scale), -127, 127).astype(np.int16) & 0xFF).astype(np.uint8).tobytes()
            if len(bs) & 1:
                bs += b'\0'
            for i in range(0, len(bs), 32):
                lines.append('\tdc.b\t' + ','.join('$%02X' % x for x in bs[i:i + 32]))
            spc = max(2, round(SR / BANDS[b]))
            k = int(round(PAULA / (spc * FSTEP)))     # Paula period = k / (fnum << block)
            made[b] = len(renders)
            renders.append((label, len(bs) // 2, ls, ll // 2, k))
            total += len(bs)
        table = [made[min(made, key=lambda x: abs(x - b))] for b in range(len(BANDS))]
        if main is None:
            ops, _, _ = setup(patch, BANDS[bands[0]], SR * OS)
            main = ops[3]
            r1 = sl = r2 = 0
        else:
            r1 = per_frame(main['rd1']) if main['stage'] == 1 else 0
            sl = max(0, int(main['slatt'] - main['att'])) if main['stage'] == 1 else 0
            r2 = per_frame(main['rd2'])
        patches.append((table, r1, sl, r2, per_frame(main['rr_'])))
    lines += ['', '\tsection\tgame,code', '',
              ';\tnote pitch bands: band n is used from fnum << block >= fm_band_lo[n]',
              'fm_band_lo']
    for b in BANDS[1:]:
        lines.append('\tdc.l\t%d' % int(b / math.sqrt(2) / FSTEP))
    lines += ['', ';\tper patch: render for each band (offsets in fm_render_table), then the run time',
              ';\tenvelope after the attack in attenuation units (1023 = 96 dB) a frame, 8.8: decay',
              ';\tspeed, decay depth (units), sustain decay speed, release speed', 'fm_patch_table']
    for table, r1, sl, r2, rr in patches:
        lines.append('\tdc.w\t%s,%d,%d,%d,%d' % (','.join(str(16 * t) for t in table), r1, sl, r2, rr))
    lines += ['FM_PATCH_SIZE\tequ\t%d' % (2 * (len(BANDS) + 4)), '',
              ';\tper render: sample, length (words), loop start (bytes), loop length (words, 0 = one',
              ';\tshot), 0, period numerator (period = it / (fnum << block))', 'fm_render_table']
    for label, n, ls, ll, k in renders:
        lines.append('\tdc.l\t%s\n\tdc.w\t%d,%d,%d,0\n\tdc.l\t%d' % (label, n, ls, ll, k))
    open(outname, 'w').write('\n'.join(lines) + '\n')
    print('fmrender: %d patches, %d renders, %d bytes of samples' % (len(patches), len(renders), total))


if __name__ == '__main__':
    main()
