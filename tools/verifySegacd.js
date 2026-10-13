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

function compareAt(builtRel, discRel, discOff, length) {
  const built = read(builtRel);
  const disc = read(discRel);
  const n = length;
  if (built.length < n) {
    console.error(builtRel + ' is ' + built.length + ' bytes, wanted ' + n);
    process.exit(1);
  }
  let bad = 0;
  let first = -1;
  for (let i = 0; i < n; i++) {
    if (built[i] !== disc[discOff + i]) {
      if (first < 0) first = i;
      bad++;
    }
  }
  const name = path.basename(discRel) + ' +$' + discOff.toString(16);
  if (bad) {
    console.error(name + ' MISMATCH  first +$' + first.toString(16) + '  ' + bad + ' of ' + n);
    console.error('  built ' + built[first].toString(16) + '  disc ' + disc[discOff + first].toString(16));
    process.exit(1);
  }
  console.log(name + ' MATCH  ' + n + ' bytes');
}

compare('output/maincd.bin', 'cdbin/MAIN.BIN', 0x272);
compareAt('output/maindma.bin', 'cdbin/MAIN.BIN', 0x272, 0x28E);
compareAt('output/maincont.bin', 'cdbin/MAIN.BIN', 0x500, 0x7B8);
compareAt('output/mainblit.bin', 'cdbin/MAIN.BIN', 0xCB8, 0x608);
compareAt('output/mainvdp.bin', 'cdbin/MAIN.BIN', 0x12C0, 0x580);
compareAt('output/mainpad.bin', 'cdbin/MAIN.BIN', 0x1840, 0x650);
compareAt('output/maindisp.bin', 'cdbin/MAIN.BIN', 0x1E90, 0xE9A);
compareAt('output/mainfont.bin', 'cdbin/MAIN.BIN', 0x2D2A, 0x300);
compareAt('output/maintext.bin', 'cdbin/MAIN.BIN', 0x302A, 0x48E);
compare('output/subboot.bin', 'cdbin/STARTER.BIN', 0x90);
compareAt('output/subheap.bin', 'cdbin/STARTER.BIN', 0x4FA8, 0xC0);
compareAt('output/pcmclear.bin', 'cdbin/STARTER.BIN', 0x3A0C, 0x6A);
compareAt('output/cdcwait.bin', 'cdbin/STARTER.BIN', 0x3A76, 0x14);
compareAt('output/pcmchip.bin', 'cdbin/STARTER.BIN', 0x3FD0, 0x12A);
compareAt('output/audiostream.bin', 'cdbin/STARTER.BIN', 0x508C, 0x278);
compareAt('output/cdfade.bin', 'cdbin/STARTER.BIN', 0x54F6, 0x78);
compareAt('output/cdrequest.bin', 'cdbin/HOCKEY.BIN', 0x1C1D2, 0x34);
compareAt('output/sfxcd.bin', 'cdbin/HOCKEY.BIN', 0x1C10C, 0x68);
compareAt('output/gate34.bin', 'cdbin/HOCKEY.BIN', 0x1C174, 0x5E);
compareAt('output/songplay.bin', 'cdbin/HOCKEY.BIN', 0x10B1E, 0x3A);
compareAt('output/filmrun.bin', 'cdbin/STARTER.BIN', 0x3D94, 0x116);
compareAt('output/filmcmd.bin', 'cdbin/STARTER.BIN', 0x4D9E, 0x2C);
compareAt('output/filmbuf.bin', 'cdbin/STARTER.BIN', 0x4E26, 0x9A);
compareAt('output/cdtrack.bin', 'cdbin/HOCKEY.BIN', 0x1C206, 0xCA);
compareAt('output/cdcrowd.bin', 'cdbin/HOCKEY.BIN', 0x238CE, 0x4E);
compareAt('output/cdstart.bin', 'cdbin/HOCKEY.BIN', 0x24D66, 0x82);
compareAt('output/scoutopen.bin', 'cdbin/HOCKEY.BIN', 0xD2B6, 0xE2);
compareAt('output/scouttext.bin', 'cdbin/HOCKEY.BIN', 0x2486C, 0x21E);
compareAt('output/scouttok.bin', 'cdbin/HOCKEY.BIN', 0x24A8A, 0x180);
compareAt('output/playerpic.bin', 'cdbin/PLAYER.BIN', 0x1D54, 0x2BC);
compareAt('output/playercareer.bin', 'cdbin/PLAYER.BIN', 0x2010, 0x3C0);
compareAt('output/playerpage.bin', 'cdbin/PLAYER.BIN', 0x23D0, 0x44C);
compareAt('output/crowdanim.bin', 'cdbin/HOCKEY.BIN', 0x10D28, 0x13E);
compareAt('output/crowdtable.bin', 'cdbin/HOCKEY.BIN', 0x2654C, 0x80);
compareAt('output/filmopen.bin', 'cdbin/STARTER.BIN', 0x4336, 0x202);
compareAt('output/filmsm.bin', 'cdbin/STARTER.BIN', 0x3EAA, 0x126);
compareAt('output/scoutload.bin', 'cdbin/HOCKEY.BIN', 0x24C12, 0x154);
compareAt('output/filmtask.bin', 'cdbin/STARTER.BIN', 0x458C, 0x1A2);
compareAt('output/filmclose.bin', 'cdbin/STARTER.BIN', 0x473A, 0x42);
compareAt('output/z80load.bin', 'cdbin/MAIN.BIN', 0x76C8, 0xF0);
compareAt('output/hwread.bin', 'cdbin/MAIN.BIN', 0x3B3C, 0x102);
