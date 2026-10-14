#!/usr/bin/env node
// build.js: the whole NHL 94 build, one line per step, on Windows and Linux (wine).
//   node tools/build.js [retail|dev] [--verbose]       full ROM -> output/nhl94.bin (nhl94-revA.bin, nhl94-dev.bin)
//   node tools/build.js --seg <name> [--verbose]       one segment (tools/segments.json), verified
//   node tools/build.js --segacd [--verbose]           Sega CD fragments, compared with cdbin/
// --no-color (or NO_COLOR) turns the colors off; they are also off when the output is not a terminal.
// retail: CHECKSUM=1 and verified against lst/nhl94.bin. dev: CHECKSUM=0, not verified.
// The rev / checksum environment variables (set rev=1 / set checksum=0 on Windows, rev=1 node ... on Linux) override the defaults.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const OUT = path.join(ROOT, 'output');
const REF = 'lst/nhl94.bin';
const SEGMENTS = require('./segments.json');
const WIN = process.platform === 'win32';

const args = process.argv.slice(2);
const verbose = args.includes('--verbose');
// ANSI colors: off when stdout is not a terminal, NO_COLOR is set, or --no-color. Windows 10+ cmd and
// PowerShell take ANSI codes from Node directly.
const color = process.stdout.isTTY && !('NO_COLOR' in process.env) && !args.includes('--no-color');
const sgr = (code) => (t) => (color ? `\x1b[${code}m${t}\x1b[0m` : String(t));
const c = { dim: sgr('2'), cyan: sgr('36'), green: sgr('32'), yellow: sgr('33'), red: sgr('31'), bold: sgr('1') };
// Values (numbers, $hex, output paths) bold; OK / MATCH green; warnings yellow.
const paint = (t) => t
    .replace(/(output\/\S+|\$[0-9A-F]+|\b\d+(?:\.\d+)?s?\b)/g, (m) => c.bold(m))
    .replace(/\b(MATCH|OK)\b/g, (m) => c.green(m))
    .replace(/\b([1-9]\d*)(\x1b\[0m)? (warnings|skipped)/g, (m) => c.yellow(m))
    .replace(/not verified \([^)]*\)/, (m) => c.yellow(m));
const segIdx = args.indexOf('--seg');
const seg = segIdx >= 0 ? args[segIdx + 1] : null;
const mode = args.find((a) => a === 'retail' || a === 'dev') || 'retail';
const env = (k) => process.env[k] ?? process.env[k.toUpperCase()] ?? process.env[k.toLowerCase()];
const rev = env('rev') === '1' ? 1 : 0;
const checksum = env('checksum') !== undefined ? (env('checksum') === '0' ? 0 : 1) : (mode === 'dev' && !seg ? 0 : 1);

let steps = 5;
let n = 0;
// Each step is two lines: "[n/5] <step>  <description>", then the result under the description.
// In a colour terminal the first line is printed (step name yellow) when the step starts and redrawn
// green or red when it ends; otherwise both lines are printed once, after the step.
const ABOUT = {
    prebuild: 'check the retail ROM and extract graphics/sound assets into Extracted/',
    assemble: 'SNASM68k turns src/*.asm into a raw ROM image',
    fixopcodes: "patch the instructions where SNASM picks a different encoding than EA's original assembler",
    fixrom: 'pad to a valid ROM size, write the header end address and the checksum',
    verify: 'compare byte-for-byte with the retail ROM',
};
const INDENT = ' '.repeat(`[0/0] ${''.padEnd(10)} `.length);
const live = color;
let current = null;
let dirty = false;
const header = (name, paintName) => `${c.cyan(`[${n}/${steps}]`)} ${paintName(name.padEnd(10))} ${c.dim(ABOUT[name] || '')}`;
function begin(name) {
    n++;
    current = name;
    dirty = false;
    if (live) console.log(header(name, c.yellow));
}
function finish(name, paintName) {
    if (current !== name) begin(name);
    if (!live) console.log(header(name, (t) => t));
    else if (!dirty) process.stdout.write(`\x1b[1A\r\x1b[2K${header(name, paintName)}\n`);
    else console.log(header(name, paintName));
    current = null;
}
const step = (name, text) => { finish(name, c.green); console.log(INDENT + paint(text)); };
const detail = (text) => { if (verbose && text.trim()) { dirty = true; console.log(text.replace(/\s+$/, '').replace(/^/gm, INDENT)); } };
function fail(name, text, log, label = 'FAILED') {
    finish(name, c.red);
    console.log(`${INDENT}${c.red(label)}: ${text}`);
    if (log) console.log(log.replace(/\s+$/, '').replace(/^/gm, INDENT));
    console.log(c.red(`BUILD FAILED at ${name}`));
    process.exit(1);
}
function run(cmd, argv, opts = {}) {
    const r = spawnSync(cmd, argv, { cwd: ROOT, encoding: 'latin1', maxBuffer: 256 << 20, ...opts });
    return { status: r.error ? -1 : r.status, out: (r.stdout || '') + (r.stderr || '') + (r.error ? String(r.error) : '') };
}
const node = (script, argv) => run(process.execPath, [path.join(__dirname, script), ...argv]);

const rel = (p) => path.relative(ROOT, p).split(path.sep).join('/');

// --segacd: the transcribed Sega CD fragments (src/segacd/, options per fragment in tools/segacd.json),
// compared with the disc files in cdbin/ by tools/verifySegacd.js. Does not touch the cartridge build.
if (args.includes('--segacd')) {
    steps = 2;
    ABOUT.assemble = 'SNASM68k assembles each src/segacd/*.asm fragment with its own options';
    ABOUT.verify = 'compare each fragment with its bytes on the disc (cdbin/)';
    const frags = require('./segacd.json');
    const BUILD = path.join(OUT, 'build');
    const CD = path.join(OUT, 'segacd');
    fs.mkdirSync(BUILD, { recursive: true });
    fs.mkdirSync(CD, { recursive: true });
    const exe = path.join(ROOT, 'assembler', 'Assembler.exe');
    begin('assemble');
    const t0 = Date.now();
    for (const f of frags) {
        const out = path.join(CD, `${f.name}.bin`);
        fs.rmSync(out, { force: true });
        const a = ['/p', '/m', '/g', ...f.options, `segacd\\${f.name}.asm,..\\output\\segacd\\${f.name}.bin,..\\output\\build\\${f.name},..\\output\\build\\${f.name}`];
        const r = WIN ? run(exe, a, { cwd: path.join(ROOT, 'src') })
            : run('wine', [exe, ...a], { cwd: path.join(ROOT, 'src'), env: { ...process.env, WINEDEBUG: '-all' } });
        const logPath = path.join(BUILD, `Build_${f.name}.log`);
        fs.writeFileSync(logPath, r.out, 'latin1');
        const sum = r.out.match(/(\d+) error\(s\) from/);
        if (!sum || Number(sum[1]) > 0 || !fs.existsSync(out)) {
            const lines = r.out.split(/\r\n|\n|\r/);
            fail('assemble', `${f.name} (see ${rel(logPath)})`, lines.filter((l) => /\.(asm|inc|mac)\(\d+|error|not recognised|undefined/i.test(l) && !/error\(s\) from/.test(l)).slice(0, 40).join('\n') || lines.slice(-20).join('\n'));
        }
        detail(`${f.name}: ${sum[0]} -> ${rel(out)}`);
    }
    step('assemble', `${frags.length} fragments, 0 errors in ${((Date.now() - t0) / 1000).toFixed(1)}s -> output/segacd/`);
    begin('verify');
    const r = node('verifySegacd.js', []);
    const matches = (r.out.match(/ MATCH /g) || []).length;
    if (r.status !== 0) {
        fail('verify', r.out.trim().split(/\r?\n/).pop(), verbose ? r.out : '', /missing .*cdbin/.test(r.out) ? 'FAILED' : 'MISMATCH');
    }
    step('verify', `MATCH ${matches} fragments against cdbin/`);
    detail(r.out);
    process.exit(0);
}

if (seg !== null && !SEGMENTS[seg]) {
    console.error(`unknown segment '${seg}'. Known: ${Object.keys(SEGMENTS).join(', ')}`);
    process.exit(1);
}
const name = seg || 'nhl94';
// Intermediate files go in output/build/: the raw assembler image, its listing and the log.
// The one result is output/<final>: nhl94.bin (retail), nhl94-revA.bin, nhl94-dev.bin, or <seg>.bin.
const BUILD = path.join(OUT, 'build');
const bin = path.join(BUILD, `${name}.raw.bin`);
const lst = path.join(BUILD, `${name} .lst`);
const fixed = path.join(BUILD, `modified_${name}.raw.bin`);
const logPath = path.join(BUILD, `Build_${name}.log`);
const final = seg ? `${seg}.bin` : `nhl94${rev ? '-revA' : ''}${mode === 'dev' ? '-dev' : ''}.bin`;
const mod = path.join(OUT, final);

// 1. prebuild: ROM check and Extracted/ assets.
{
    begin('prebuild');
    const r = node('prebuild.js', ['retail']);
    if (r.status !== 0) fail('prebuild', 'ROM or asset extraction', r.out);
    let count = '?';
    try { count = JSON.parse(fs.readFileSync(path.join(ROOT, 'Extracted', '.extract-complete.json'), 'utf8')).files.length; } catch (e) { /* keep ? */ }
    step('prebuild', `ROM OK, ${count} assets${/extracting/.test(r.out) ? ' (extracted again)' : ''}`);
    detail(r.out);
}

// 2. assemble: SNASM68k, directly on Windows, under wine elsewhere. Its console output is the log.
{
    begin('assemble');
    fs.mkdirSync(BUILD, { recursive: true });
    for (const f of [bin, fixed, mod]) fs.rmSync(f, { force: true });
    const src = seg ? `stubinc\\${seg}_stub.asm` : 'nhl94.asm';
    const o = `..\\output\\build\\${name}`;
    const asmArgs = ['/p', '/m', '/g', '/o', 'd-', '/o', 's-', '/o', 'r+', '/o', 'l+', '/o', 'l.', '/o', 'ow+', '/o', 'op-',
        '/o', 'os+', '/o', 'oz+', '/o', 'omq-', '/o', 'oaq+', '/o', 'osq+',
        '/e', `REV=${rev}`, '/e', `CHECKSUM=${checksum}`, `${src},${o}.raw.bin,${o},${o}`];
    const exe = path.join(ROOT, 'assembler', 'Assembler.exe');
    const r = WIN ? run(exe, asmArgs, { cwd: path.join(ROOT, 'src') })
        : run('wine', [exe, ...asmArgs], { cwd: path.join(ROOT, 'src'), env: { ...process.env, WINEDEBUG: '-all' } });
    fs.writeFileSync(logPath, r.out, 'latin1');
    const lines = r.out.split(/\r\n|\n|\r/);
    const sum = r.out.match(/(\d+) error\(s\) from (\d+) lines in ([\d.]+) seconds/);
    const warnings = lines.filter((l) => /warning/i.test(l)).length;
    const short = lines.filter((l) => /SHORTCALL /.test(l));
    if (short.length) {
        fail('assemble', 'a routine called with a short jsr/jmp (x).w moved past $7FFF',
            short.join('\n') + '\nPut the added data after menu94 (or after the 1MB pad), or change those calls to .l.\nSee docs/EXPANDING_THE_ROM.md.');
    }
    if (!sum) fail('assemble', `no assembler summary in ${rel(logPath)} (exit ${r.status})`, lines.slice(-20).join('\n'));
    const errors = Number(sum[1]);
    if (errors > 0 || !fs.existsSync(bin)) {
        const bad = lines.filter((l) => /\.(asm|inc|mac)\(\d+|error|fatal|not recognised|undefined/i.test(l) && !/error\(s\) from/.test(l)).slice(0, 40);
        fail('assemble', `${errors} error(s), see ${rel(logPath)}`, bad.join('\n'));
    }
    step('assemble', `${errors} errors, ${warnings} warnings, ${sum[2]} lines in ${sum[3]}s (REV=${rev} CHECKSUM=${checksum}) -> ${rel(bin)}`);
    detail(r.out);
}

// 3. fixopcodes: rewrite the EA cmp / exg encodings SNASM picks differently; the result becomes output/<final>.
{
    begin('fixopcodes');
    const r = node('fixopcodes.js', [lst, bin, ...(seg ? [SEGMENTS[seg]] : [])]);
    const m = r.out.match(/Modified (\d+) instructions/);
    if (r.status !== 0 || !m || !fs.existsSync(fixed)) fail('fixopcodes', 'did not write the fixed binary', r.out);
    fs.renameSync(fixed, mod);
    const skipped = (r.out.match(/Skipping/g) || []).length;
    step('fixopcodes', `${m[1]} opcodes fixed${skipped ? `, ${skipped} skipped` : ''}`);
    detail(r.out);
}

// 4. fixrom: pad to the cartridge size, header ROM end, boot checksum. Segments are not a ROM.
if (seg) {
    step('fixrom', 'skipped (segment)');
} else {
    begin('fixrom');
    const r = node('fixrom.js', [lst, mod]);
    const m = r.out.match(/size (\w+) \(end (\w+)\), checksum (\w+) -> (\w+)/);
    if (r.status !== 0 || !m) fail('fixrom', 'size or checksum', r.out);
    step('fixrom', `size $${m[1].toUpperCase()}, header end $${m[2].toUpperCase()}, checksum $${m[4].toUpperCase()}${m[3] !== m[4] ? ` (was $${m[3].toUpperCase()})` : ''}`);
    detail(r.out);
}

// 5. verify against the retail ROM.
if (!seg && mode === 'dev') {
    step('verify', `${rel(mod)} not verified (dev build)`);
} else if (!seg && rev) {
    step('verify', `${rel(mod)} not verified (no REV A reference ROM)`);
} else {
    begin('verify');
    const r = seg ? node('verifySegment.js', [seg, SEGMENTS[seg], REF]) : node('verifyRom.js', [mod, REF]);
    const first = r.out.split(/\r?\n/).find((l) => l.trim()) || '';
    if (r.status !== 0 || !/^MATCH/.test(first)) {
        fail('verify', rel(mod), r.out, 'MISMATCH');
    }
    step('verify', `MATCH ${rel(mod)}${seg ? ` (${first.replace(/^MATCH:?\s*/, '')})` : ''}`);
    detail(r.out);
}
