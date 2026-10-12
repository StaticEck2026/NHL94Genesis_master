# Segment prompt

Paste this into a new Copilot Agent session. Opus 5.5, High. One segment only. Run it again for the next file. Do not edit this prompt.

```text
Read SEGMENT_AGENT.md before you write any asm. It is the queue and the history. Take the first file in the ROM map that is not marked matched. That file is the only segment this session. Do not start the file after it.

Open the listing before you write any asm. It is already in the repo:

lst/nhl94.bin.lst

Search it for the start label named in SEGMENT_AGENT.md. The listing has no address column. loc_ and sub_ names are the address. If it does not open, stop and say the path you tried.

Do not disassemble lst/nhl94.bin. Do not write a disassembler. Do not edit nhl94.asm. Do not delete an asm file. Edit the segment file in place. Do not rewrite SEGMENT_AGENT.md as a whole file. Edit the current-segment line, the matched row, and the history in place.

Follow the rules already in SEGMENT_AGENT.md. The reference ROM is lst/nhl94.bin. Style source is the matching file in https://github.com/abdulahmad/NHLPA93Genesis.

1. Write or reuse src/<file>_stub.asm at the confirmed org. Include src/stubinc/ports.inc, equals.inc, ram_addrs.inc, and src/<file>.asm.
2. Point package.json build:seg and verify:seg at that file and org. Add seg:<file>: buildseg.bat, then tools/fixopcodes.js on "output\<file> .lst" and output\<file>.bin, then tools/verifySegment.js <file> <org> lst/nhl94.bin. The assembler listing name has a space before .lst.
3. Transcribe the listing for the confirmed range. Write real cmp / cmpi / exg. fixopcodes.js rewrites an EA cmp.l only. A real cmpi.l stays 0C80. Take every outside stub address from the branch displacement in lst/nhl94.bin.
4. Run npm.cmd run seg:<file>. MATCH must cover the confirmed range and must not be 0 bytes. Then add comments and run it again.
5. In SEGMENT_AGENT.md, mark that file matched with the byte count and range. Move it into History. Set Current segment to the next unmatched file. Do not mark the next file matched.

Stop after 5 failed verifies. Report the file, the first address, the built byte, the retail byte, and the instruction you emitted. Do not continue.
```
