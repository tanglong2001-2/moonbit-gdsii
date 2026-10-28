// Complete-file regression for the existing checked record rewrite API.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/record-rewrite'));
mkdirSync(output, { recursive: true });
const cases = [];
function run(name, command, args, expectedExit, input) {
  const result = spawnSync(command, args, { cwd: root, encoding: 'utf8', input, maxBuffer: 1024 * 1024 });
  writeFileSync(join(output, `${name}.json`), JSON.stringify({ name, command: [command, ...args],
    status: result.status, stdout: result.stdout, stderr: result.stderr }, null, 2));
  assert.ifError(result.error);
  assert.equal(result.status, expectedExit, name);
  assert.equal(result.stderr, '', name);
  const response = JSON.parse(result.stdout);
  cases.push({ name, expectedExit });
  return response;
}

// Independently construct the expected stream from the declared original layout.
// These headers/coordinates use Node's big-endian primitives, never the library.
const record = (kind, type = 0, data = Buffer.alloc(0)) => {
  const header = Buffer.alloc(4);
  header.writeUInt16BE(data.length + 4); header[2] = kind; header[3] = type;
  return Buffer.concat([header, data]);
};
const i16 = values => { const b = Buffer.alloc(values.length * 2); values.forEach((v, i) => b.writeInt16BE(v, 2 * i)); return b; };
const i32 = values => { const b = Buffer.alloc(values.length * 4); values.forEach((v, i) => b.writeInt32BE(v, 4 * i)); return b; };
const dates = i16([126, 10, 29, 4, 0, 0, 126, 10, 29, 4, 0, 0]);
const prefix = Buffer.concat([
  record(0, 2, i16([600])), record(1, 2, dates), record(2, 6, Buffer.from('REWRITE\0')),
  record(3, 5, Buffer.from('41800000000000044110000000000001', 'hex')),
  record(5, 2, dates), record(6, 6, Buffer.from('top\0')), record(8),
  record(38, 1, Buffer.from('8000', 'hex')), record(47, 3, i32([0x123456])),
  record(13, 2, i16([7])), record(14, 2, i16([2])),
  record(16, 3, i32([0, 0, 8, 0, 8, 4, 0, 4, 0, 0])),
]);
const attribute = record(43, 2, i16([7]));
const oldValue = record(44, 6, Buffer.from('old\0'));
const newValue = record(44, 6, Buffer.from('route-A\0'));
const suffix = Buffer.concat([
  record(43, 2, i16([9])), record(44, 6, Buffer.from('keep')),
  record(127, 5, Buffer.from('0000000000000001', 'hex')), record(127, 6, Buffer.from('opaque')),
  record(17), record(7), record(4),
]);
const original = Buffer.concat([prefix, attribute, oldValue, suffix, Buffer.alloc(32)]);
// from_records constructs logical records; physical input padding is not copied.
const expected = Buffer.concat([prefix, attribute, newValue, suffix]);
const expectedError = { error: ['InvalidStructure', prefix.length, 'property attribute missing'] };
const moon = process.platform === 'win32' && process.env.MOON_HOME ? join(process.env.MOON_HOME, 'bin/moon.exe') : 'moon';
const temporary = mkdtempSync(join(output, 'files-'));
const responses = [];
const pairs = [];
for (const target of ['js', 'wasm-gc']) {
  const response = run(`rewrite-${target}`, moon, ['run', 'tests/record_rewrite', '--target', target, '--quiet'], 0);
  assert.equal(response.changed_properties, 1);
  assert.equal(response.next_property_offset, prefix.length + attribute.length + newValue.length);
  assert.deepEqual(Buffer.from(response.pair.before.bytes), original);
  assert.deepEqual(Buffer.from(response.pair.after.bytes), expected);
  assert.deepEqual(response.rejected, expectedError);
  responses.push(response);

  const pair = join(temporary, target);
  run(`materialize-${target}`, process.execPath, ['tools/save_author.mjs', pair], 0, JSON.stringify(response.pair));
  assert.deepEqual(readFileSync(join(pair, 'before.gds')), original);
  assert.deepEqual(readFileSync(join(pair, 'after.gds')), expected);
  pairs.push(pair);

  const rejectedDirectory = join(temporary, `rejected-${target}`);
  const rejection = run(`refuse-${target}`, process.execPath, ['tools/save_author.mjs', rejectedDirectory], 2,
    JSON.stringify(response.rejected));
  assert.equal(rejection.error.stage, 'input');
  assert.equal(rejection.error.code, 'AUTHOR_OUTPUT_INVALID');
  assert.equal(existsSync(rejectedDirectory), false);
  assert.deepEqual(readFileSync(join(pair, 'before.gds')), original);
  assert.deepEqual(readFileSync(join(pair, 'after.gds')), expected);
}
assert.deepEqual(responses[0], responses[1]);
const profile = ['top', '7', '2', '3', '0'];
const reports = ['before', 'after'].map(side => run(`inspect-${side}`, process.execPath,
  ['tools/inspect.mjs', '--preflight', join(pairs[0], `${side}.gds`), ...profile], 0).preflight);
assert.equal(reports[0].status, 'RectanglesClear');
assert.equal(reports[0].checked_rectangles, 1);
assert.deepEqual(reports[0].skipped, []);
assert.deepEqual(reports[0].issues, []);
assert.deepEqual(reports[0], reports[1]);
const summary = { status: 'PASS', cases, originalBytes: original.length, rewrittenBytes: expected.length,
  changedPropertyValues: 1, preservedOtherRecordPayloads: 20, preservedUnitWords: 2, repeatedUnknownRecords: 2,
  originalPaddingBytes: 32, rewriteCopiesPhysicalPadding: false, errorOffset: prefix.length,
  filesReadBack: 4, rejectedDirectoriesCreated: 0,
  sourceSha256: createHash('sha256').update(original).digest('hex'),
  rewrittenSha256: createHash('sha256').update(expected).digest('hex') };
writeFileSync(join(output, 'summary.json'), JSON.stringify(summary, null, 2));
console.log(JSON.stringify(summary));
