// Compare the transcribed Sega CD fragments to the disc files.
// The disc files are not in the repo. Put them in cdbin/ :
//   cdbin/MAIN.BIN  cdbin/STARTER.BIN  cdbin/HOCKEY.BIN
//   cdbin/PLAYER.BIN  cdbin/GRAPH2.BIN  cdbin/GTABLE.BIN

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');

function read(rel) {
  const p = path.join(root, rel);
  if (!fs.existsSync(p)) {
    console.error('missing ' + p);
    process.exit(1);
  }
  return fs.readFileSync(p);
}

function compare(builtRel, discRel, length) {
  const built = read(builtRel);
  const disc = read(discRel);
  const n = Math.min(length, built.length, disc.length);
  let bad = 0;
  let first = -1;
  for (let i = 0; i < n; i++) {
    if (built[i] !== disc[i]) {
      if (first < 0) first = i;
      bad++;
    }
  }
  if (built.length < length) {
    console.error(builtRel + ' is ' + built.length + ' bytes, wanted ' + length);
    process.exit(1);
  }
  if (bad) {
    console.error(path.basename(discRel) + ' MISMATCH  first $' + first.toString(16) + '  ' + bad + ' of ' + n);
    console.error('  built ' + built[first].toString(16) + '  disc ' + disc[first].toString(16));
    process.exit(1);
  }
  console.log(path.basename(discRel) + ' MATCH  ' + n + ' bytes');
}

compare('output/maincd.bin', 'cdbin/MAIN.BIN', 0x130);
compare('output/subboot.bin', 'cdbin/STARTER.BIN', 0x90);
