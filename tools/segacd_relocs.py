#!/usr/bin/env python3
"""Pair cartridge RAM/ROM addresses with Sega CD addresses.

HOCKEY.BIN is the cartridge game rebuilt for the sub CPU. The same instruction
sequence sits in front of the same string, with absolute addresses changed.
This prints those pairs for the strings it can line up.

  python3 tools/segacd_relocs.py lst/nhl94.bin cdbin/HOCKEY.BIN
"""

import re
import sys
from capstone import Cs, CS_ARCH_M68K, CS_MODE_BIG_ENDIAN, CS_MODE_M68K_000

md = Cs(CS_ARCH_M68K, CS_MODE_M68K_000 | CS_MODE_BIG_ENDIAN)

STRINGS = [
    b"Play Mode",
    b"EA Hockey Night",
    b"HAT TRICK!",
    b"Game  Statistics",
    b"Penalty  Summary",
    b"Line Changes",
    b"Address Error",
    b"Stars of the Game",
    b"New York Rangers",
    b"SHOOTOUT MODE",
    b"Crowd  Meter",
]


def insns_before(blob, end, nbytes=200):
    start = max(0, end - nbytes)
    if start & 1:
        start += 1
    out = []
    for insn in md.disasm(blob[start:end], start):
        if insn.address + insn.size > end:
            break
        out.append(insn)
    return out


def code_end(blob, text_at):
    text = blob[text_at:text_at + 80].split(b"\x00", 1)[0]
    if text_at >= 2 and blob[text_at - 2] == 0 and blob[text_at - 1] == len(text):
        return text_at - 2
    return text_at


def abs_addrs(op):
    return re.findall(r"\$[0-9a-f]+", op)


def main():
    rom = open(sys.argv[1], "rb").read()
    cd = open(sys.argv[2], "rb").read()
    pairs = {}
    for s in STRINGS:
        ir, ih = rom.find(s), cd.find(s)
        if min(ir, ih) < 0:
            continue
        a = insns_before(rom, code_end(rom, ir))
        b = insns_before(cd, code_end(cd, ih))
        # Line the tails up. The CD side is longer when abs.w became abs.l.
        for insn_r, insn_c in zip(a[-12:], b[-12:]):
            if insn_r.mnemonic != insn_c.mnemonic:
                continue
            ar, ac = abs_addrs(insn_r.op_str), abs_addrs(insn_c.op_str)
            if len(ar) == 1 and len(ac) == 1 and ar[0] != ac[0]:
                pairs.setdefault((ar[0], ac[0]), []).append(s.decode().strip())
    print(f"{'cartridge':<12} {'sega cd':<12} strings")
    for (src, dst), names in sorted(pairs.items(), key=lambda kv: int(kv[0][0][1:], 16)):
        print(f"{src:<12} {dst:<12} {', '.join(names)}")


if __name__ == "__main__":
    main()
