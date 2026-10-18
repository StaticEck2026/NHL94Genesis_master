#!/usr/bin/env python3
"""Pack nhl94.game for a floppy (build step of the Amiga port): NHL94.pak.

A hunk executable does not fit on an 880 KB disk, so its hunks are deflate compressed, each on
its own, and the launcher (stub.asm, inflate.i) loads them itself: it allocates each hunk,
inflates it in place, then applies the relocations. Layout (big endian longs):

  'NHLZ', hunks, reloc table bytes
  per hunk: size in longs with the memory type in bits 30 / 31 (as in HUNK_HEADER),
            compressed bytes (0: nothing to inflate, a BSS hunk)
  the reloc table's compressed bytes
  the hunks' deflate data, one after the other, then the reloc table's
The reloc table (inflated): per hunk, groups of (count, target hunk, count offsets), a 0 count
after the hunk's last group.

Usage: pack.py nhl94.game NHL94.pak
"""
import struct, sys, zlib

HUNK_UNIT, HUNK_NAME, HUNK_CODE, HUNK_DATA, HUNK_BSS = 0x3E7, 0x3E8, 0x3E9, 0x3EA, 0x3EB
HUNK_RELOC32, HUNK_SYMBOL, HUNK_DEBUG, HUNK_END, HUNK_HEADER = 0x3EC, 0x3F0, 0x3F1, 0x3F2, 0x3F3
HUNK_RELOC32SHORT, HUNK_DREL32 = 0x3FC, 0x3F7


def parse(d):
    """sizes (longs, with memory bits), data per hunk (bytes), relocs per hunk {target: [offset]}"""
    p = 0

    def long():
        nonlocal p
        v = struct.unpack('>I', d[p:p + 4])[0]
        p += 4
        return v

    def word():
        nonlocal p
        v = struct.unpack('>H', d[p:p + 2])[0]
        p += 2
        return v

    assert long() == HUNK_HEADER
    while long():
        pass
    long()
    first, last = long(), long()
    nh = last - first + 1
    sizes = [long() for _ in range(nh)]
    assert not any((s >> 30) == 3 for s in sizes), 'extended memory types are not handled'
    data = [b''] * nh
    rel = [dict() for _ in range(nh)]
    h = 0
    while p < len(d) and h < nh:
        t = long() & 0x3FFFFFFF
        if t in (HUNK_CODE, HUNK_DATA):
            n = long() & 0x3FFFFFFF
            data[h] = d[p:p + n * 4]
            p += n * 4
        elif t == HUNK_BSS:
            long()
        elif t == HUNK_RELOC32:
            while True:
                n = long()
                if not n:
                    break
                target = long()
                rel[h].setdefault(target, []).extend(long() for _ in range(n))
        elif t in (HUNK_RELOC32SHORT, HUNK_DREL32):
            while True:
                n = word()
                if not n:
                    break
                target = word()
                rel[h].setdefault(target, []).extend(word() for _ in range(n))
            if p & 2:
                p += 2
        elif t == HUNK_SYMBOL:
            while True:
                n = long()
                if not n:
                    break
                p += n * 4
                long()
        elif t in (HUNK_DEBUG, HUNK_NAME, HUNK_UNIT):
            p += long() * 4
        elif t == HUNK_END:
            h += 1
        else:
            raise SystemExit('pack.py: hunk type %x not handled' % t)
    return sizes, data, rel


def deflate(b):
    c = zlib.compressobj(9, zlib.DEFLATED, -15, 9)
    return c.compress(b) + c.flush()


def main():
    src, dst = sys.argv[1:3]
    sizes, data, rel = parse(open(src, 'rb').read())
    table = b''
    for r in rel:
        for target in sorted(r):
            offs = sorted(r[target])
            table += struct.pack('>II%dI' % len(offs), len(offs), target, *offs)
        table += struct.pack('>I', 0)
    streams = [deflate(b) if b else b'' for b in data]
    rstream = deflate(table)
    for b, s in zip(data, streams):                 # the packed data must give the hunks back
        assert not b or zlib.decompress(s, -15) == b
    out = b'NHLZ' + struct.pack('>II', len(sizes), len(table))
    for sz, s in zip(sizes, streams):
        out += struct.pack('>II', sz, len(s))
    out += struct.pack('>I', len(rstream))
    out += b''.join(streams) + rstream
    open(dst, 'wb').write(out)
    print('pack.py: %d hunks, %d relocations, %d bytes' %
          (len(sizes), sum(len(o) for r in rel for o in r.values()), len(out)))


if __name__ == '__main__':
    main()
