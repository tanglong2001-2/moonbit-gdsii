// Integration acceptance over original authored bytes, not a replacement DRC.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';
import { createHash } from 'node:crypto';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci'));
mkdirSync(output, { recursive: true });
const cases = [];
function run(name, command, args, expected, input) {
  const result = spawnSync(command, args, { cwd: root, input, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  const evidence = { name, command: [command, ...args], status: result.status, stdout: result.stdout, stderr: result.stderr };
  writeFileSync(join(output, `${name}.json`), JSON.stringify(evidence, null, 2));
  assert.ifError(result.error);
  assert.equal(result.status, expected, name);
  assert.equal(result.stderr, '', name);
  cases.push({ name, expectedExit: expected });
  return JSON.parse(result.stdout);
}
const moon = process.platform === 'win32' && process.env.MOON_HOME ? join(process.env.MOON_HOME, 'bin/moon.exe') : 'moon';
const js = run('author-js', moon, ['run', 'cmd/author', '--target', 'js'], 0);
const wasm = run('author-wasm', moon, ['run', 'cmd/author', '--target', 'wasm-gc'], 0);
assert.deepEqual(js, wasm);
assert.equal(js.schema, 'gdsii-author-v1');

// Independent big-endian GDS stream oracle, fixed original sample metadata.
const rec = (kind, type = 0, data = Buffer.alloc(0)) => {
  const header = Buffer.alloc(4);
  header.writeUInt16BE(data.length + 4); header[2] = kind; header[3] = type;
  return Buffer.concat([header, data]);
};
const i16 = values => { const b = Buffer.alloc(values.length * 2); values.forEach((n, i) => b.writeInt16BE(n, 2 * i)); return b; };
const i32 = values => { const b = Buffer.alloc(values.length * 4); values.forEach((n, i) => b.writeInt32BE(n, 4 * i)); return b; };
const date = i16([126, 10, 28, 0, 0, 0, 126, 10, 28, 0, 0, 0]);
function originalStream(boxes) {
  const elements = boxes.flatMap(([x0, y0, x1, y1]) => [rec(8), rec(13, 2, i16([7])), rec(14, 2, i16([2])),
    rec(16, 3, i32([x0, y0, x1, y0, x1, y1, x0, y1, x0, y0])), rec(17)]);
  return Buffer.concat([rec(0, 2, i16([600])), rec(1, 2, date), rec(2, 6, Buffer.from('AUTHORED')),
    rec(3, 5, Buffer.from('41100000000000004110000000000000', 'hex')), rec(5, 2, date),
    rec(6, 6, Buffer.from('top\0')), ...elements, rec(7), rec(4)]);
}
const before = originalStream([[0, 0, 4, 8], [10, 0, 14, 8]]);
const after = originalStream([[0, 0, 4, 8], [10, 0, 12, 8]]);
assert.deepEqual(Buffer.from(js.before.bytes), before);
assert.deepEqual(Buffer.from(js.after.bytes), after);
const pair = join(mkdtempSync(join(output, 'author-')), 'pair');
run('materialize', process.execPath, ['tools/save_author.mjs', pair], 0, JSON.stringify(js));
assert.deepEqual(readFileSync(join(pair, 'before.gds')), before);
assert.deepEqual(readFileSync(join(pair, 'after.gds')), after);
const inspect = (name, args, expected) => run(name, process.execPath, ['tools/inspect.mjs', ...args], expected);
const profile = ['7', '2', '3', '5'];
const beforeFile = join(pair, 'before.gds');
const afterFile = join(pair, 'after.gds');
assert.deepEqual(inspect('catalog', ['--catalog', afterFile], 0).catalog.top_cells, ['top']);
assert.deepEqual(inspect('hierarchy', ['--hierarchy', afterFile, 'top'], 0).hierarchy.reachable_cells, ['top']);
const preflight = inspect('preflight-after', ['--preflight', afterFile, 'top', ...profile], 3).preflight;
assert.equal(preflight.status, 'ViolationsFound');
assert.equal(preflight.checked_rectangles, 2);
assert.deepEqual(preflight.skipped, []);
assert.equal(preflight.issues.length, 1);
assert.equal(preflight.issues[0].rule, 'Width');
assert.equal(preflight.issues[0].measured, 2);
assert.equal(preflight.issues[0].shortfall, 1);
const batch = inspect('compare-tops', ['--compare-tops', beforeFile, afterFile, ...profile], 3).batch;
assert.equal(batch.status, 'IssuesFound');
assert.deepEqual(batch.counts, { passed: 0, failed: 1, incomplete: 0, errors: 0 });
assert.equal(batch.coverage.complete, true);
assert.equal(batch.results[0].comparison.introduced.length, 1);
const retained = inspect('compare-retained', ['--compare', afterFile, afterFile, 'top', ...profile], 0).comparison;
assert.equal(retained.status, 'NoNewIssues');
assert.equal(retained.retained, 1);
assert.deepEqual(inspect('budget-limit', ['--preflight', afterFile, 'top', ...profile, '2'], 2), { error: ['ExpansionLimit', 2] });
assert.deepEqual(inspect('budget-exact', ['--preflight', afterFile, 'top', ...profile, '3'], 3).preflight, preflight);
const invalid = inspect('budget-empty', ['--preflight', afterFile, 'top', ...profile, ''], 2).error;
assert.equal(invalid.code, 'EMPTY_NUMERIC_ARGUMENT');
assert.equal(invalid.message, 'budget must contain an explicit positive INT32 integer.');
const existing = run('refuse-existing-pair', process.execPath, ['tools/save_author.mjs', pair], 2, JSON.stringify(js));
assert.equal(existing.error.stage, 'output');
assert.equal(existing.error.code, 'EEXIST');
assert.deepEqual(readFileSync(beforeFile), before);
assert.deepEqual(readFileSync(afterFile), after);
const invalidPair = join(output, 'invalid-pair');
const bad = run('refuse-invalid-bytes', process.execPath, ['tools/save_author.mjs', invalidPair], 2,
  JSON.stringify({ schema: 'gdsii-author-v1', before: { bytes: [256] }, after: { bytes: [0] } }));
assert.equal(bad.error.stage, 'input');
assert.equal(existsSync(invalidPair), false);
const summary = { status: 'PASS', cases, originalStreamSha256: [before, after].map(b => createHash('sha256').update(b).digest('hex')),
  independentStreams: 2, filesReadBack: 2, newIssues: 1, retainedIssuesInNoNewComparison: 1 };
writeFileSync(join(output, 'summary.json'), JSON.stringify(summary, null, 2));
console.log(JSON.stringify(summary));
