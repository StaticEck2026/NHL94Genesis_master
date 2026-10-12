#!/usr/bin/env node
// Keep the local repo and GitHub in step. Run by the Claude Code hooks in .claude/settings.json (session start: pull only;
// end of every turn: commit and push), or by hand: npm run sync.
//   1. Commit any uncommitted work (git add -A) on the current branch. On the default branch it first moves the work to a new
//      autosave/<date> branch, so main is never committed to directly.
//   2. Fetch origin, then fast-forward every local branch that is behind its remote branch (a branch that has diverged is left
//      alone and reported).
//   3. Push every non-default branch that is ahead of its remote branch or has none yet (git push -u, never --force). A diverged
//      branch is not merged; its local commits are pushed to autosave/<branch> instead, so they are on GitHub too.
// Usage: node tools/sync.js [--pull-only] [--quiet]. Always exits 0, so a hook never blocks the session; problems are printed.
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const pullOnly = process.argv.includes('--pull-only');
const quiet = process.argv.includes('--quiet'); // hooks: print nothing when nothing changed (hook output goes into Claude's context)
const MAX_FILE = 50 * 1024 * 1024; // GitHub rejects files over 100 MB; leave anything over 50 MB uncommitted and say so
const log = [];
const say = (m) => log.push(m);

function git(args, opts = {}) {
  const out = execFileSync('git', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  return opts.raw ? out.replace(/\n$/, '') : out.trim(); // raw: keep the leading space of porcelain status lines
}
function tryGit(args) {
  try { return { ok: true, out: git(args) }; } catch (e) { return { ok: false, out: String(e.stderr || e.message).trim() }; }
}
function sleep(ms) { Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms); }
function withRetry(args) { // network commands: retry 4 times, 2 / 4 / 8 / 16 s apart
  let r = tryGit(args);
  for (const wait of [2000, 4000, 8000, 16000]) {
    if (r.ok || /rejected|non-fast-forward|denied|not found|403/i.test(r.out)) break;
    sleep(wait); r = tryGit(args);
  }
  return r;
}

function main() {
  process.chdir(path.join(__dirname, '..')); // sync.js sits in tools/: work at the repo root whatever directory the hook runs in
  const top = tryGit(['rev-parse', '--show-toplevel']);
  if (!top.ok) { say('not a git repository: nothing to do'); return; }
  process.chdir(top.out);
  const gitDir = git(['rev-parse', '--git-dir']);
  const busy = ['MERGE_HEAD', 'rebase-merge', 'rebase-apply', 'CHERRY_PICK_HEAD', 'REVERT_HEAD'].find((f) => fs.existsSync(path.join(gitDir, f)));
  if (busy) { say(`a merge / rebase is in progress (${busy}): not touching anything`); return; }

  const remoteHead = tryGit(['symbolic-ref', '--short', 'refs/remotes/origin/HEAD']);
  const defaultBranch = remoteHead.ok ? remoteHead.out.replace(/^origin\//, '') : 'main';
  let branch = tryGit(['symbolic-ref', '--short', 'HEAD']);
  branch = branch.ok ? branch.out : null; // null: detached HEAD

  // 1. commit uncommitted work
  if (!pullOnly && branch) {
    const status = git(['status', '--porcelain', '--untracked-files=all'], { raw: true });
    if (status) {
      const big = status.split('\n').map((l) => l.slice(3).replace(/^"|"$/g, '')).filter((f) => {
        try { return fs.statSync(f).size > MAX_FILE; } catch { return false; }
      });
      if (branch === defaultBranch) {
        const stamp = new Date().toISOString().replace(/[-:]/g, '').replace('T', '-').slice(0, 15);
        const nb = `autosave/${stamp}`;
        git(['checkout', '-b', nb]);
        say(`uncommitted work was on ${defaultBranch}: moved it to the new branch ${nb}`);
        branch = nb;
      }
      git(['add', '-A']);
      for (const f of big) { git(['reset', '-q', '--', f]); say(`left uncommitted (over 50 MB): ${f}`); }
      const staged = git(['diff', '--cached', '--name-only']);
      if (staged) {
        const files = staged.split('\n');
        const msg = `Autosave uncommitted work on ${branch}\n\n` +
          `${files.length} file(s): ${files.slice(0, 20).join(', ')}${files.length > 20 ? ', ...' : ''}\n\n` +
          'Automatic commit by sync.js (Claude Code Stop hook or npm run sync).';
        const c = tryGit(['commit', '-q', '-m', msg]);
        say(c.ok ? `committed ${files.length} file(s) on ${branch}` : `commit failed: ${c.out}`);
      }
    }
  }

  // 2. fetch, fast-forward branches that are behind
  const f = withRetry(['fetch', '--prune', 'origin']);
  if (!f.ok) { say(`fetch failed: ${f.out.split('\n').pop()}`); }
  const clean = !git(['status', '--porcelain', '--untracked-files=no']);
  const refs = git(['for-each-ref', '--format=%(refname:short)|%(upstream:short)', 'refs/heads/']).split('\n').filter(Boolean);
  const toPush = [];
  for (const line of refs) {
    const [b, up] = line.split('|');
    if (!up || !tryGit(['rev-parse', '--verify', '-q', up]).ok) { if (b !== defaultBranch) toPush.push(b); continue; }
    const [behind, ahead] = git(['rev-list', '--left-right', '--count', `${up}...${b}`]).split(/\s+/).map(Number);
    if (behind && ahead) { // keep the local commits on GitHub without touching either side: back them up to autosave/<branch>
      say(`${b} and ${up} have diverged (${ahead} ahead, ${behind} behind): not pulled; merge them by hand`);
      if (!pullOnly) {
        const p = withRetry(['push', 'origin', `${b}:refs/heads/autosave/${b}`]);
        say(p.ok ? `backed up ${b} to origin/autosave/${b}` : `backup push of ${b} failed: ${p.out.split('\n').slice(-2).join(' ')}`);
      }
      continue;
    }
    if (behind) {
      if (b === branch) {
        if (!clean) { say(`${b} is ${behind} behind ${up} but has local changes: not pulled`); continue; }
        const m = tryGit(['merge', '--ff-only', '-q', up]);
        say(m.ok ? `pulled ${b} (${behind} new commit(s))` : `pull of ${b} failed: ${m.out}`);
      } else {
        git(['update-ref', `refs/heads/${b}`, git(['rev-parse', up]), git(['rev-parse', b])]);
        say(`fast-forwarded ${b} to ${up} (${behind} new commit(s))`);
      }
    }
    if (ahead && b !== defaultBranch) toPush.push(b);
    if (ahead && b === defaultBranch) say(`${b} has ${ahead} local commit(s) not on GitHub: not pushed (default branch)`);
  }

  // 3. push branches that are ahead or new
  if (!pullOnly) {
    for (const b of toPush) {
      const p = withRetry(['push', '-u', 'origin', b]);
      say(p.ok ? `pushed ${b}` : `push of ${b} failed: ${p.out.split('\n').slice(-2).join(' ')}`);
    }
  }
  if (!log.length && !quiet) say('up to date: nothing to commit, pull or push');
}

try { main(); } catch (e) { say(`sync error: ${String(e.stderr || e.message).trim()}`); }
if (log.length) console.log('[sync] ' + log.join('\n[sync] '));
process.exit(0);
