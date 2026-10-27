#!/usr/bin/env python3
"""Convert the Genesis sources in src/ into a vasm source tree for the Amiga build."""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
SRC = os.path.join(ROOT, 'src')
sys.path.insert(0, HERE)
import patches

SKIP = {'main94.asm', 'checksum94.asm', os.path.join('sega', 'SegaInit.asm'), os.path.join('sega', 'SegaIDTable94.asm')}

REGS = {'a0', 'a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7', 'sp', 'pc',
        'd0', 'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7'}

report = []


def ci_resolve(base, rel):
    """Resolve a Windows style relative path case-insensitively."""
    cur = base
    for p in re.split(r'[\\/]', rel):
        if p in ('', '.'):
            continue
        if p == '..':
            cur = os.path.dirname(cur)
            continue
        cand = os.path.join(cur, p)
        if not os.path.exists(cand):
            hits = [e for e in os.listdir(cur) if e.lower() == p.lower()] if os.path.isdir(cur) else []
            if not hits:
                raise FileNotFoundError(os.path.join(cur, p))
            cand = os.path.join(cur, hits[0])
        cur = cand
    return cur


def split_comment(ln):
    """Split a source line into code and comment, ignoring; inside quotes."""
    q = None
    for i, c in enumerate(ln):
        if q:
            if c == q:
                q = None
        elif c in "'\"":
            q = c
        elif c == ';':
            return ln[:i], ln[i:]
    return ln, ''


uniq = [0]


def expand_macros(code):
    """Expand String / PLAYER in place (vasm has no backwards org and few macro args)."""
    m = re.match(r'^(\S*)(\s+)(String|PLAYER|Player)\s+(.*?)\s*$', code)
    if not m:
        return [code]
    lab, ws, mac, args = m.groups()
    uniq[0] += 1
    n = uniq[0]
    out = [lab] if lab else []
    if mac == 'String':
        out += ['\tdc.w\t.se%d-*' % n, '\tdc.b\t' + args, '\tcnop\t0,2', '.se%d' % n]
    else:
        q = args.rfind("'") if "'" in args else args.rfind('"')
        name, rest = args[:q + 1], args[q + 1:]
        ratings = [r.strip() for r in rest.split(',') if r.strip()]
        out += ['\tdc.b\t0,.pe%d-*+1' % n, '\tdc.b\t' + name, '\tcnop\t0,2', '.pe%d' % n,
                '\tdc.w\t' + ','.join('$' + r for r in ratings)]
    return out


def split_operands(ops):
    """Split an operand field at top level commas."""
    res, depth, cur, q = [], 0, '', None
    for c in ops:
        if q:
            cur += c
            if c == q:
                q = None
            continue
        if c in "'\"":
            q = c
        elif c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
        elif c == ',' and depth == 0:
            res.append(cur)
            cur = ''
            continue
        cur += c
    res.append(cur)
    return res


INSN = re.compile(r'^(?P<lab>\S*)(?P<ws>\s+)(?P<op>[A-Za-z][A-Za-z0-9]*)(?P<sz>\.[bwlsBWLS])?(?:(?P<ws2>\s+)(?P<args>.*?))?(?P<tail>\s*)$')


def is_abs_symbol(inner):
    t = inner.strip().lower()
    return t not in REGS and not re.match(r'^[ad][0-7]$', t)


def ram_rules(op, sz, args, ctx):
    """Rewrite 16-bit RAM addressing forms."""
    opl = op.lower()
    szl = (sz or '').lower()
    extra = []
    if args is None:
        return op, sz, args, extra
    ops = split_operands(args)

    def fix_abs(o):
        out = o
        i = out.lower().find(').w')
        while i >= 0:
            depth, j = 0, i
            while j >= 0:
                if out[j] == ')':
                    depth += 1
                elif out[j] == '(':
                    depth -= 1
                    if depth == 0:
                        break
                j -= 1
            inner = out[j + 1:i]
            nxt = out[i + 3:i + 4]
            if j >= 0 and is_abs_symbol(inner) and not re.match(r'[A-Za-z0-9_]', nxt or ' '):
                out = out[:i] + ').l' + out[i + 3:]
            i = out.lower().find(').w', i + 3)
        return out
    ops = [fix_abs(o) for o in ops]

    if opl in ('movea', 'cmpa') and szl == '.w' and len(ops) == 2:
        src, dst = ops[0].strip(), ops[1].strip()
        dl = dst.lower()
        if src.startswith('#'):
            e = src[1:].strip()
            if 'M68K_RAM' in e:
                e = re.sub(r'\s*-\s*M68K_RAM\s*\)\s*$', ')', e)
                e = e.replace('-M68K_RAM', '')
                sz = '.l'
                ops = ['#' + e, dst]
            else:
                m = re.match(r'^\$([0-9A-Fa-f]{1,4})$', e)
                if m:
                    v = int(m.group(1), 16)
                    if v >= 0x8000:
                        sz = '.l'
                        ops = ['#RAMBASE+$%04X' % v, dst]
                elif re.match(r'^[A-Za-z_]', e):
                    sz = '.l'
        elif re.match(r'^(a[0-7]|sp)$', src.lower()):
            sz = '.l'
        elif opl == 'movea':
            extra.append('\tadda.l\t#RAMFIX,' + dst)
            report.append('%s: wordptr %s %s' % (ctx, op + (sz or ''), args))
        else:
            report.append('%s: CHECK cmpa.w %s' % (ctx, args))
    return op, sz, ','.join(ops), extra


def convert_line(code, ctx):
    m = INSN.match(code)
    if not m or m.group('op').lower() in ('dc', 'dcb', 'ds', 'equ', 'macro', 'include', 'incbin',
                                           'if', 'else', 'endif', 'elseif', 'rept', 'endr', 'org', 'set'):
        return [code]
    lab, ws, op, sz, ws2, args, tail = (m.group('lab'), m.group('ws'), m.group('op'), m.group('sz'),
                                        m.group('ws2') or '\t', m.group('args'), m.group('tail'))
    if args is not None and re.match(r'^(equ|=|set)$', op, re.I):
        return [code]
    op2, sz2, args2, extra = ram_rules(op, sz, args, ctx)
    if op2.lower() == 'move' and args2 and re.match(r'^#\$2[1-5]00,sr$', args2, re.I):
        args2 = '#$2000,sr'
    if sz2 and re.match(r'^(bra|bsr|b(hi|ls|cc|cs|ne|eq|vc|vs|pl|mi|ge|lt|gt|le|hs|lo))$', op2, re.I) \
            and '*' not in (args2 or ''):
        sz2 = None
    line = lab + ws + op2 + (sz2 or '') + ((ws2 + args2) if args2 is not None else '')
    return [line] + extra


# Video memory.

PORT_RETURNERS = {'vmaddr': 'a0', 'xymmap': None, 'xyvmmap': 'a0'}
BRANCH = re.compile(r'^(bra|bsr|jmp|jsr|b(hi|ls|cc|cs|ne|eq|vc|vs|pl|mi|ge|lt|gt|le|hs|lo)|db[a-z]+)$', re.I)
vmem_report = []


def _target(args):
    t = args.split(',')[-1].strip()
    t = re.sub(r'^\((.*)\)\.[wl]$', r'\1', t)
    return t


def vmem_pass(rel, lines):
    """Rewrite the data port writes through Vmaddr's pointer."""
    labin = {}
    for _ in range(6):
        before = repr(sorted((k, sorted(v.items())) for k, v in labin.items()))
        res = _vmem_once(rel, lines, labin, False)
        if repr(sorted((k, sorted(v.items())) for k, v in labin.items())) == before:
            break
    return _vmem_once(rel, lines, labin, True)


def _vmem_once(rel, lines, labin, final):
    state = {}
    routine = ''
    out = []
    for idx, (code, com) in enumerate(lines):
        m = re.match(r'^([A-Za-z_.@][\w.@]*)?(\s+(.*))?$', code)
        lab = m.group(1) if m else None
        body = (m.group(3) or '').strip() if m else code.strip()
        if lab:
            if not lab.startswith('.') and not lab.startswith('@'):
                state, routine = {}, lab
            for r, v in labin.get((routine, lab), {}).items():
                state.setdefault(r, v)
        mm = re.match(r'^([A-Za-z]+)(\.[bwlsBWLS])?\s*(.*)$', body)
        if not mm:
            out.append((code, com))
            continue
        op, sz, args = mm.group(1).lower(), (mm.group(2) or ''), mm.group(3).strip()
        ops = split_operands(args) if args else []
        new = None
        ctx = '%s:%d' % (rel, idx + 1)
        if op in ('move', 'clr') and ops:
            dst = ops[-1].strip()
            src = ops[0].strip() if len(ops) == 2 else None
            dl = dst.lower()
            mctl = re.match(r'^vctrl\s*-\s*vdata\s*\((a[0-7])\)$', dl)
            if mctl or dl in ('(vctrl).l', 'vctrl', '(vdata).l', 'vdata'):
                raise SystemExit('%s: a video chip port access (%s): give it a native form (patches.py)' % (ctx, body))
            mr = re.match(r'^\((a[0-7])\)$', dl)
            if mr and state.get(mr.group(1)) == 'data':
                ops[-1] = '(%s)+' % mr.group(1)
                new = op + sz + '\t' + ','.join(o.strip() for o in ops)
            elif mr and state.get(mr.group(1)) == 'ctrl':
                raise SystemExit('%s: a video chip port access (%s): give it a native form (patches.py)' % (ctx, body))
            if new is None and src is not None:
                sl = src.lower()
                mr = re.match(r'^\((a[0-7])\)$', sl)
                if sl in ('(vctrl).l', '(vdata).l'):
                    raise SystemExit('%s: a video chip port access (%s): give it a native form (patches.py)' % (ctx, body))
                elif mr and state.get(mr.group(1)) == 'data':
                    ops[0] = '(%s)+' % mr.group(1)
                    new = op + sz + '\t' + ','.join(o.strip() for o in ops)
            if new and final:
                vmem_report.append('%s: %s  ->  %s' % (ctx, body, new))
        if op in ('movea', 'lea', 'move') and len(ops) == 2:
            s0, d0 = ops[0].strip().lower(), ops[1].strip().lower()
            if re.match(r'^a[0-7]$', d0):
                if s0 in ('#vdata', '(vdata).l', 'vdata'):
                    state[d0] = 'data'
                elif s0 in ('#vctrl', '(vctrl).l', 'vctrl'):
                    state[d0] = 'ctrl'
                else:
                    state.pop(d0, None)
        elif op in ('bsr', 'jsr', 'bra', 'jmp'):
            t = _target(args).lower()
            if PORT_RETURNERS.get(t):
                state[PORT_RETURNERS[t]] = 'data'
        elif op == 'movem' and len(ops) == 2 and ops[0].strip().lower() == '(sp)+':
            regs = ops[1].lower()
            for r in list(state):
                n = int(r[1])
                for part in regs.split('/'):
                    part = part.strip()
                    if '-' in part:
                        a, b = part.split('-')
                        if a[0] == 'a' and int(a[1]) <= n <= int(b[1]):
                            state.pop(r, None)
                    elif part == r:
                        state.pop(r, None)
        elif op == 'exg' and len(ops) == 2:
            a, b = ops[0].strip().lower(), ops[1].strip().lower()
            va, vb = state.pop(a, None), state.pop(b, None)
            if va: state[b] = va
            if vb: state[a] = vb
        elif len(ops) == 2 and re.match(r'^a[0-7]$', ops[1].strip().lower()) and op not in (
                'cmpa', 'cmp', 'tst', 'btst'):
            state.pop(ops[1].strip().lower(), None)
        if BRANCH.match(op):
            t = _target(args)
            if t.startswith('.') and state:
                pend = labin.setdefault((routine, t), {})
                for r, v in state.items():
                    pend.setdefault(r, v)
        if op in ('rts', 'rte', 'bra', 'jmp'):
            state = {}
        if new:
            code = (lab or '') + '\t' + new
        out.append((code, com))
    return out


WAITOPS = ('cmp', 'cmpi', 'tst', 'btst')


IDLE_SKIP = {'sound94.asm'}


def idle_pass(rel, lines):
    """Put jsr hal_idle at the top of busy-wait loops: a local label."""
    out = list(lines)
    if rel in IDLE_SKIP:
        return out
    code = [split_comment(l)[0] for l in lines]
    n = 0
    for i, c in enumerate(code):
        m = re.match(r'^(\.[\w]+)\s*(\S.*)?$', c)
        if not m:
            continue
        lab = m.group(1)
        body = [m.group(2)] if m.group(2) else []
        j = i + 1
        while len(body) < 5 and j < len(code):
            if code[j].strip():
                if re.match(r'^[A-Za-z_.]', code[j]):
                    break
                body.append(code[j].strip())
            j += 1
        k = 0
        while k < len(body) and k < 3:
            mm = re.match(r'^([a-z]+)(\.[bwl])?\s+(.*)$', body[k], re.I)
            if not mm or ')+' in body[k] or '-(' in body[k]:
                break
            opn = mm.group(1).lower()
            ops = split_operands(mm.group(3))
            if opn in WAITOPS:
                pass
            elif opn in ('move', 'sub', 'subi', 'and', 'andi') and len(ops) == 2 \
                    and re.match(r'^d[0-7]$', ops[1].strip(), re.I):
                pass
            else:
                break
            k += 1
        if k == 0 or k >= len(body):
            continue
        mb = re.match(r'^b(ne|eq|pl|mi|lt|ge|gt|le|cc|cs|hi|ls)(\.[sw])?\s+(\S+)$', body[k], re.I)
        if not mb or mb.group(3) != lab:
            continue
        if m.group(2):
            cm = split_comment(lines[i])[1]
            out[i] = lab + '\n\tjsr\t(hal_idle).l\n\t' + m.group(2) + cm
        else:
            out[i] = lines[i] + '\n\tjsr\t(hal_idle).l'
        n += 1
        idle_report.append('%s:%d %s' % (rel, i + 1, lab))
    return out


idle_report = []


def convert_file(rel, text, out):
    lines = idle_pass(rel, text.split('\n'))
    lines = '\n'.join(lines).split('\n')
    split = []
    for ln in lines:
        if re.match(r'^(\S*\s+)(include|incbin)(\s+)', ln, re.I):
            split.append((ln, None))
        else:
            split.append(split_comment(ln))
    split = vmem_pass(rel, [(c, m) if m is not None else (c, '') for c, m in split])
    lines = [c + m for c, m in split]
    res = []
    for i, ln in enumerate(lines):
        ctx = '%s:%d' % (rel, i + 1)
        m = re.match(r'^(\S*\s+)(include|incbin)(\s+)(\S+)(.*)$', ln, re.I)
        if m:
            p = ci_resolve(SRC, m.group(4))
            if p.startswith(SRC + os.sep):
                p = os.path.join(os.path.abspath(out), os.path.relpath(p, SRC))
            res.append(m.group(1) + m.group(2).lower() + m.group(3) + '"' + p + '"' + m.group(5))
            continue
        code, com = split_comment(ln)
        code = code.replace('<>', '!=')
        exp = expand_macros(code)
        conv = []
        for c in exp:
            conv.extend(convert_line(c, ctx))
        conv[-1] += com
        res.extend(conv)
    return '\n'.join(res)


def main():
    out = os.path.abspath(sys.argv[1])
    for dp, dn, fn in os.walk(SRC):
        for f in fn:
            sp = os.path.join(dp, f)
            rel = os.path.relpath(sp, SRC)
            if rel in SKIP or rel.startswith('segacd') or rel.startswith('stubinc' + os.sep) and rel.endswith('_stub.asm'):
                continue
            with open(sp, encoding='latin-1') as fh:
                text = fh.read()
            text = patches.pre(rel, text)
            text = convert_file(rel, text, out)
            text = patches.post(rel, text)
            op = os.path.join(out, rel)
            os.makedirs(os.path.dirname(op), exist_ok=True)
            with open(op, 'w', encoding='latin-1') as fh:
                fh.write(text)
    patches.finish()
    with open(os.path.join(out, 'convert_report.txt'), 'w') as fh:
        fh.write('\n'.join(report) + '\n\n' + '\n'.join(vmem_report) + '\n\nidle:\n' + '\n'.join(idle_report) + '\n')


if __name__ == '__main__':
    main()
