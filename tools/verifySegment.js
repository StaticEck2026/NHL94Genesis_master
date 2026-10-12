// Overlay one assembled and fixopcodes-patched segment onto lst/nhl94.bin.
// Usage: node tools/verifySegment.js <segment> <org> <reference.bin> [<first> <last>]
const fs = require('fs');
const path = require('path');

const [segment, orgArg, referencePath, firstArg, lastArg] = process.argv.slice(2);
if (!segment || !orgArg || !referencePath) {
  console.error('Usage: node tools/verifySegment.js <segment> <org> <reference.bin> [<first> <last>]');
  process.exit(1);
}

const org = Number(orgArg);
if (!Number.isInteger(org) || org < 0) {
  console.error('org must be a hex or decimal address');
  process.exit(1);
}

const ROOT = path.join(__dirname, '..');
const builtPath = path.join(ROOT, 'output', `modified_${segment}.bin`);
const patchedPath = path.join(ROOT, 'output', `${segment}_patched.bin`);
const built = fs.readFileSync(builtPath);
const reference = fs.readFileSync(referencePath);

if (org + built.length > reference.length) {
  console.error(`segment ${built.length} bytes at ${orgArg} runs past the end of ${referencePath}`);
  process.exit(1);
}

const patched = Buffer.from(reference);
built.copy(patched, org);
fs.writeFileSync(patchedPath, patched);

const first = firstArg === undefined ? org : Number(firstArg);
const last = lastArg === undefined ? org + built.length - 1 : Number(lastArg);
const length = last - first + 1;
const mismatches = [];
for (let a = first; a <= last; a++) {
  if (built[a - org] !== reference[a]) mismatches.push(a);
}

const start = first.toString(16).padStart(6, '0');
const end = last.toString(16).padStart(6, '0');
if (mismatches.length === 0) {
  console.log(`MATCH: ${segment} confirmed ${length} bytes at 0x${start}-0x${end}`);
  console.log(`patched ROM: ${patchedPath}`);
  process.exit(0);
}

console.error(`MISMATCH: ${mismatches.length} of ${length} bytes differ in 0x${start}-0x${end}`);
for (const offset of mismatches.slice(0, 16)) {
  const i = offset - org;
  console.error(`  0x${offset.toString(16).padStart(6, '0')}: built ${built[i].toString(16).padStart(2, '0')} retail ${reference[offset].toString(16).padStart(2, '0')}`);
}
console.error(`patched ROM still written: ${patchedPath}`);
process.exit(1);
