const fs = require('fs');
const { parseListing, sumRom } = require('./patchchecksum');

// Post-build fix for a ROM that may have grown past 1MB:
//   1. pad with $FF to the next size the cartridge hardware accepts (1MB, 1.5MB, 2MB, 4MB),
//   2. write the header ROM end ($1A4) as that size - 1,
//   3. write the boot checksum (the cmpi.l immediate in ValidationRoutine).
// The stock build stays 1MB and byte-identical. See docs/EXPANDING_THE_ROM.md.

const SIZES = [0x100000, 0x180000, 0x200000, 0x400000];
const ROM_END = 0x1a4;
const BACKUP_RAM = 0x200000;

function main() {
    const [listingPath, binPath] = process.argv.slice(2);
    if (!listingPath || !binPath) {
        console.error('usage: node tools/fixrom.js <listing> <bin>');
        process.exit(1);
    }
    let buf = fs.readFileSync(binPath);
    // The listing gives the real content end only through the fill; trailing $FF counts as free.
    let used = buf.length;
    while (used > 0 && buf[used - 1] === 0xff) used--;
    const size = SIZES.find((s) => used <= s && buf.length <= s);
    if (!size) {
        console.error(`ROM is ${buf.length} bytes: larger than 4MB needs a mapper (docs/EXPANDING_THE_ROM.md)`);
        process.exit(1);
    }
    if (size > BACKUP_RAM) console.warn('warning: ROM overlaps the backup RAM window at $200000 (docs/EXPANDING_THE_ROM.md)');
    if (buf.length < size) buf = Buffer.concat([buf, Buffer.alloc(size - buf.length, 0xff)]);
    buf.writeUInt32BE(size - 1, ROM_END);
    const { routine, imm } = parseListing(fs.readFileSync(listingPath, 'utf8'));
    const sum = sumRom(buf, routine);
    const old = buf.readUInt32BE(imm);
    buf.writeUInt32BE(sum, imm);
    fs.writeFileSync(binPath, buf);
    const hex = (n) => n.toString(16).padStart(8, '0');
    console.log(`size ${hex(size)} (end ${hex(size - 1)}), checksum ${hex(old)} -> ${hex(sum)} at ${hex(imm)}`);
}

main();
