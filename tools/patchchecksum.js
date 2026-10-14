const fs = require('fs');

// ValidationRoutine adds every ROM long below itself and skips the header long at $18C
// (the serial tail and the checksum word). Pass the ROM after fixopcodes: the sum has to
// match the bytes the game runs. The source keeps the retail immediate, so the checksum
// segment matches the retail ROM without this step.

const HEADER_LONG = 0x18c;

function parseListing(text) {
    let routine = null;
    let cmpAddr = null;
    for (const line of text.split(/\r?\n/)) {
        let m = line.match(/^([0-9A-Fa-f]{8})\s+ValidationRoutine\b/);
        if (m) routine = parseInt(m[1], 16);
        m = line.match(/^([0-9A-Fa-f]{8})\s+0C80\s+[0-9A-Fa-f]{4}\s+[0-9A-Fa-f]{4}.*\bcmpi\.l\b/i);
        if (m) cmpAddr = parseInt(m[1], 16);
    }
    if (routine == null) throw new Error('ValidationRoutine not found in listing');
    if (cmpAddr == null) throw new Error('cmpi.l checksum compare not found in listing');
    return { routine, imm: cmpAddr + 2 };
}

function sumRom(buf, routine) {
    let sum = 0;
    for (let a = 0; a + 4 <= routine; a += 4) {
        if (a === HEADER_LONG) continue;
        sum = (sum + buf.readUInt32BE(a)) >>> 0;
    }
    return sum;
}

function main() {
    const listingPath = process.argv[2];
    const binPath = process.argv[3];
    if (!listingPath || !binPath) {
        console.error('usage: node tools/patchchecksum.js <listing> <bin>');
        process.exit(1);
    }
    const { routine, imm } = parseListing(fs.readFileSync(listingPath, 'utf8'));
    const buf = fs.readFileSync(binPath);
    if (routine > buf.length || imm + 4 > buf.length) {
        console.error('listing addresses do not fit this ROM');
        process.exit(1);
    }
    const sum = sumRom(buf, routine);
    const old = buf.readUInt32BE(imm);
    buf.writeUInt32BE(sum, imm);
    fs.writeFileSync(binPath, buf);
    const hex = (n) => n.toString(16).padStart(8, '0');
    console.log(`checksum ${hex(old)} -> ${hex(sum)} at ${hex(imm)} (routine ${hex(routine)})`);
}

module.exports = { parseListing, sumRom, HEADER_LONG };

if (require.main === module) main();
