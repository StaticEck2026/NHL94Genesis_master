#!/usr/bin/env python3
"""Emit SNASM for a contiguous slice of a Sega CD binary.

The slice is one org. Branches inside the slice become labels. Branches
outside it use an equate, which SNASM resolves against the org.

Assemble with /o oz- . oz+ folds a zero displacement (move.w $0(a5),d0)
into the short form, and the disc keeps the 16-bit displacement.

  python3 tools/emit_m68k.py cdbin/MAIN.BIN 0x272 0x500 0xFF0000 src/segacd/maindma.asm
"""

import re
import sys

from capstone import Cs, CS_ARCH_M68K, CS_MODE_BIG_ENDIAN, CS_MODE_M68K_000

md = Cs(CS_ARCH_M68K, CS_MODE_M68K_000 | CS_MODE_BIG_ENDIAN)

BRANCH = {
    "bra", "bsr", "beq", "bne", "bhi", "bls", "bcc", "bcs", "bpl", "bmi",
    "bvc", "bvs", "bge", "bgt", "ble", "blt", "dbra", "dbf", "dbne", "dbt",
    "dbeq", "dbhi", "dbcc", "dbcs",
}


def load_insns(blob, start, end, base):
    out = []
    pc = start
    while pc < end:
        got = None
        for insn in md.disasm(blob[pc:pc + 12], base + pc):
            got = insn
            break
        if got is None or got.address != base + pc or pc + got.size > end:
            break
        out.append(got)
        pc += got.size
    return out, pc


def target_of(insn):
    m = re.search(r"\$([0-9a-f]+)", insn.op_str)
    if not m:
        return None
    return int(m.group(1), 16)


def snasm_op(insn, labels, base):
    op = insn.op_str
    op = op.replace("a7", "sp")
    op = re.sub(r"#\$([0-9a-f]+)", lambda m: "#$" + m.group(1).upper(), op)
    op = re.sub(r"\$([0-9a-f]+)", lambda m: "$" + m.group(1).upper(), op)
    # Sign-extended absolute short must be written as a 32-bit value.
    def widen(m):
        n = int(m.group(1), 16)
        # Capstone prints the size suffix in lowercase (.w). SNASM rejects
        # an absolute short whose unsigned value does not fit in signed 16.
        if m.group(2).lower() == ".w" and n >= 0x8000:
            n = n | 0xFFFF0000
            return f"${n:X}.w"
        return m.group(0)
    op = re.sub(r"\$([0-9A-Fa-f]+)(\.[WwLl])", widen, op)
    kind = insn.mnemonic.split(".")[0]
    # SNASM rejects btst.b #n,dn. The size is implied by a data register.
    if kind in ("btst", "bclr", "bset", "bchg") and re.search(r",d[0-7]$", op.replace(" ", "")):
        insn_mnem_override = kind
    else:
        insn_mnem_override = None
    if kind in BRANCH or "(pc)" in insn.op_str:
        dest = target_of(insn)
        if dest is None:
            return op
        if dest in labels:
            name = labels[dest]
        else:
            name = f"X_{dest:X}"
        op = re.sub(r"\$[0-9A-F]+", name, op, count=1)
        op = op.replace(name + "(pc)", name + "(pc)")
    op = op.replace(", ", ",")
    return op


def main():
    blob = open(sys.argv[1], "rb").read()
    start = int(sys.argv[2], 16)
    end = int(sys.argv[3], 16)
    base = int(sys.argv[4], 16)
    out_path = sys.argv[5]
    insns, stopped = load_insns(blob, start, end, base)
    if stopped != end:
        print(f"stopped at file ${stopped:X}, wanted ${end:X}", file=sys.stderr)
        sys.exit(1)
    labels = {}
    for insn in insns:
        kind = insn.mnemonic.split(".")[0]
        if kind in BRANCH or "(pc)" in insn.op_str:
            dest = target_of(insn)
            if dest is not None and base + start <= dest < base + end:
                labels.setdefault(dest, f"L{dest:X}")
    # An instruction address that is fallen into is labeled when something targets it.
    lines = [f"\torg\t${base + start:X}", ""]
    externs = []
    for insn in insns:
        kind = insn.mnemonic.split(".")[0]
        if kind in BRANCH or "(pc)" in insn.op_str:
            dest = target_of(insn)
            if dest is not None and dest not in labels and f"X_{dest:X}" not in externs:
                externs.append(f"X_{dest:X}")
    for name in externs:
        lines.insert(0, f"{name}\tequ\t${name[2:]}")
    if externs:
        lines.insert(len(externs), "")
    for insn in insns:
        label = labels.get(insn.address, "")
        text = snasm_op(insn, labels, base)
        mnem = insn.mnemonic
        kind = mnem.split(".")[0]
        if kind in ("btst", "bclr", "bset", "bchg") and re.search(r",d[0-7]$", text.replace(" ", "")):
            mnem = kind
        # SNASM sign-extends moveq #$FF into the wrong byte. Write -128..-1.
        if kind == "moveq":
            m = re.match(r"#\$([0-9A-F]+),(.*)", text)
            if m:
                n = int(m.group(1), 16) & 0xFF
                if n >= 0x80:
                    text = f"#{n - 256},{m.group(2)}"
        # move sr / (sp)+ uses the source's unsized form; sized move.w sr is the same bytes.
        line = f"{label}\t{mnem}\t{text}" if text else f"{label}\t{mnem}"
        lines.append(line.rstrip())
    open(out_path, "w").write("\n".join(lines) + "\n")
    print(f"wrote {out_path}  {len(insns)} insns  ${start:X}-${stopped:X}")


if __name__ == "__main__":
    main()
