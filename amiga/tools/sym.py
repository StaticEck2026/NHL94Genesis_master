#!/usr/bin/env python3
"""sym.py LISTING ADDR... : name the code addresses the test harness prints (code hunk at $200000)."""
import re, sys, bisect

def load(lst):
    syms = []
    on = False
    for ln in open(lst, encoding='latin-1'):
        if ln.startswith('Symbols by name:'):
            on = True
            continue
        if ln.startswith('Symbols by value:'):
            break
        if on:
            m = re.match(r'^(\S+)\s+00:([0-9A-F]{8})', ln)
            if m:
                syms.append((int(m.group(2), 16), m.group(1)))
    syms.sort()
    return syms

if __name__ == '__main__':
    syms = load(sys.argv[1])
    keys = [s[0] for s in syms]
    for a in sys.argv[2:]:
        v = int(a, 16) - 0x200000
        i = bisect.bisect_right(keys, v) - 1
        print('%s = %s+$%X' % (a, syms[i][1], v - syms[i][0]) if i >= 0 else a)
