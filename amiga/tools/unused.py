#!/usr/bin/env python3
"""The code and data of the Amiga build that nothing reaches (a report: unused.py
output/amiga/src [output/amiga/nhl94.lst] [-d] [-l] [-t=FILE]).

The assembled sources (output/amiga/src: the converted game and the Amiga code, from
nhl94_amiga.asm through its includes; -t=stub.asm: the launcher) are cut into blocks, each
from a global label to the next (or to a change of section). A block reaches the labels,
equates and macros its lines name, and the block after it in its section when it can run on
into it: its last instruction is not rts, rte, bra or jmp, or its last line is a local label
(the next block's start). Equates and macros reach what their definitions name. Both sides of
every IF are read, so what the harness build (HARNESS) uses counts. From the
first block (hal_header: AmigaDOS starts there), what comes before each section's first label,
and every name the build script, the tools, the test harness and the launcher use, what is not reached is
listed with its bytes in the listing. Symbols are compared without case (the build assembles
with -nocase).

-d: a data block (dc, ds, incbin only) also runs on into a data block after it (a table read
past its label). -l: the unused equates and macros too, and the unused labels with nothing
after them.
"""
import os, re, sys

ID = r'[A-Za-z_][A-Za-z0-9_]*'
TRANSFER = {'rts', 'rte', 'rtr', 'bra', 'jmp', 'bra.s', 'bra.w', 'bra.b', 'bra.l'}
DATA = {'dc', 'ds', 'dcb', 'incbin', 'even', 'cnop', 'align', 'blk'}
NOBYTES = {'inform', 'fail', 'printt', 'printv', 'echo', 'xdef', 'xref', 'opt', 'list', 'nolist'}


def strip(line):
    """The line without its comment and with its strings blanked."""
    out, q = [], None
    for ch in line:
        if q:
            out.append(' ' if ch != q else ch)
            if ch == q:
                q = None
        elif ch in '\'"':
            q = ch
            out.append(ch)
        elif ch == ';':
            break
        else:
            out.append(ch)
    s = ''.join(out)
    return '' if s.lstrip().startswith('*') and s[:1] == '*' else s


def read(src, name, out, seen):
    path = os.path.join(src, name)
    for n, raw in enumerate(open(path, encoding='latin-1').read().splitlines(), 1):
        line = strip(raw)
        m = re.match(r'^\s+include\s+"?([^"\s;]+)"?', raw, re.I)
        if m and m.group(1) not in seen:
            seen.add(m.group(1))
            if os.path.exists(os.path.join(src, m.group(1))):
                read(src, m.group(1), out, seen)
            continue
        out.append((name, n, line))


def parse(src, top='nhl94_amiga.asm'):
    lines = []
    read(src, top, lines, set())
    blocks = []                         # [name, section, file, first line, last line, refs, last op, data,
                                        #  holds anything]
    eqs, macros = {}, {}
    cur = None
    section = 'game'
    in_macro = None
    for fn, n, line in lines:
        if in_macro is not None:
            if re.match(r'^\s*endm\b', line, re.I):
                in_macro = None
            else:
                macros[in_macro] |= set(t.lower() for t in re.findall(ID, line))
            continue
        m = re.match(r'^(%s)\s+macro\b' % ID, line, re.I) or re.match(r'^\s+macro\s+(%s)' % ID, line, re.I)
        if m:
            in_macro = m.group(1).lower()
            macros[in_macro] = set()
            continue
        m = re.match(r'^(%s):?\s+(equ|set|=|rs\.[bwl]|rs)\b(.*)$' % ID, line, re.I) or \
            re.match(r'^(%s)\s*(=)(.*)$' % ID, line)
        if m:
            eqs[m.group(1).lower()] = set(t.lower() for t in re.findall(ID, m.group(3)))
            continue
        m = re.match(r'^\s+section\s+(%s)' % ID, line, re.I)
        if m:
            section = m.group(1).lower()
            cur = None
            continue
        m = re.match(r'^(%s):?(\s+(.*))?$' % ID, line)
        body = line
        if m and not line[:1].isspace():
            cur = [m.group(1).lower(), section, fn, n, n, set(), None, True, False]
            blocks.append(cur)
            body = ' ' + (m.group(3) or '')
        elif re.match(r'^\.\w+:?', line) or re.match(r'^%s\$:?' % ID, line):
            body = ' ' + re.sub(r'^\S+', '', line)
            if cur is not None:
                cur[6] = None           # (a local label: what follows it is reached; if
                                        # nothing does in this block, the next block is)
        if cur is None:                 # (before a section's first label: always kept)
            cur = ['<%s %s:%d>' % (section, fn, n), section, fn, n, n, set(), None, True, False]
            blocks.append(cur)
        cur[4] = n
        t = body.split()
        if not t:
            continue
        op = t[0].lower()
        base = op.split('.')[0]
        if base in ('if', 'ifd', 'ifnd', 'ifeq', 'ifne', 'ifgt', 'ifge', 'iflt', 'ifle', 'else', 'endc', 'endif'):
            cur[5] |= set(x.lower() for x in re.findall(ID, ' '.join(t[1:])))
            continue
        if base in NOBYTES:
            cur[5] |= set(x.lower() for x in re.findall(r'(?<![\.\w])' + ID, ' '.join(t[1:])))
            continue
        cur[6] = op
        cur[8] = True                   # (it holds code or data)
        if base not in DATA:
            cur[7] = False
        cur[5].add(op)                  # (a macro's name)
        cur[5] |= set(x.lower() for x in re.findall(r'(?<![\.\w])' + ID, ' '.join(t[1:])))
    return blocks, eqs, macros


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('-')]
    opts = [a for a in sys.argv[1:] if a.startswith('-')]
    top = [a[3:] for a in opts if a.startswith('-t=')]
    src = args[0] if args else 'output/amiga/src'
    lst = args[1] if len(args) > 1 else os.path.join(os.path.dirname(src.rstrip('/')), 'nhl94.lst')
    blocks, eqs, macros = parse(src, top[0] if top else 'nhl94_amiga.asm')
    byname = {}
    for b in blocks:
        byname.setdefault(b[0], []).append(b)
    # roots: the first block, and the names the build, tools and harness use
    roots = {blocks[0][0]} | {b[0] for b in blocks if b[0].startswith('<')}   # (and what comes
                                        # before a section's first label: always assembled)
    here = os.path.dirname(os.path.abspath(__file__))
    other = [os.path.join(here, '..', 'src', 'stub.asm')] if not top else []   # (the launcher
    for f in [os.path.join(here, '..', 'build.sh')] + other + \
             [os.path.join(here, x) for x in os.listdir(here) if x.endswith('.py') and x != 'unused.py'] + \
             [os.path.join(here, '..', 'harness', x) for x in os.listdir(os.path.join(here, '..', 'harness'))
              if x.endswith(('.c', '.sh', '.py'))]:
        words = set(w.lower() for w in re.findall(ID, open(f, encoding='latin-1').read()))   # (reads
                                        # build.i's figures too)
        roots |= words & (set(byname) | set(eqs) | set(macros))
    # what follows a block that runs on into it
    nxt = {}
    last = {}
    for b in blocks:
        if b[1] in last:
            nxt[id(last[b[1]])] = b
        last[b[1]] = b
    live, todo = set(), list(roots)
    seenb = set()
    while todo:
        name = todo.pop()
        if name in live:
            continue
        live.add(name)
        for b in byname.get(name, []):
            seenb.add(id(b))
            todo += [r for r in b[5] if r not in live]
            n = nxt.get(id(b))
            if b[7]:                    # data: into data after it, with -d
                runs_on = '-d' in opts and n is not None and n[7]
            else:
                runs_on = b[6] not in TRANSFER
            if n is not None and runs_on and n[0] not in live:
                todo.append(n[0])
        todo += [r for r in eqs.get(name, ()) if r not in live]
        todo += [r for r in macros.get(name, ()) if r not in live]
    # the listing's addresses: bytes of each unused block
    addr = {}
    if os.path.exists(lst):
        txt = open(lst, encoding='latin-1').read()
        i = txt.find('Symbols by value:')
        for m in re.finditer(r'^([0-9A-F]{8}) (\S+)$', txt[i:], re.M):
            addr.setdefault(m.group(2).lower(), int(m.group(1), 16))
    dead = [b for b in blocks if id(b) not in seenb and not b[0].startswith('<') and b[8]]
    empty = [b for b in blocks if id(b) not in seenb and not b[0].startswith('<') and not b[8]]
    total = {}
    for b in dead:
        a = addr.get(b[0])
        later = sorted(v for k, v in addr.items() if a is not None and v > a)
        size = (later[0] - a) if later else 0
        total[b[1]] = total.get(b[1], 0) + size
        print('%-10s %-22s %5d-%-5d %7d  %s' % (b[1], b[2], b[3], b[4], size, b[0]))
    print('unused blocks: %d; bytes by section: %s' % (len(dead), ', '.join('%s %d' % kv for kv in sorted(total.items()))))
    if '-l' in opts:
        ue = sorted(k for k in eqs if k not in live)
        um = sorted(k for k in macros if k not in live)
        print('unused labels with nothing after them (%d): %s' % (len(empty), ' '.join(b[0] for b in empty)))
        print('unused equates (%d): %s' % (len(ue), ' '.join(ue)))
        print('unused macros (%d): %s' % (len(um), ' '.join(um)))


if __name__ == '__main__':
    main()
