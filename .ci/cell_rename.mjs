// Complete independent symbol-edit bytes -> real producer -> existing file receivers.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/cell-rename'));
assert.equal(existsSync(output), false, 'Retain earlier evidence; choose a new directory.');
mkdirSync(output, { recursive: true });
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const vectorBytes = readFileSync(join(root, 'testdata/cell-rename-vectors.json'));
assert.equal(sha256(vectorBytes), '53ea263938f8c85e25c9cdc9f7bee2a4269894380e44bb137618a23bce45d404');
const vectors = JSON.parse(vectorBytes);
const sources = Object.fromEntries(Object.entries(vectors.sources).map(([name, hex]) => [name, Buffer.from(hex, 'hex')]));
const expected = Object.fromEntries(Object.entries(vectors.expected).map(([name, hex]) => [name, Buffer.from(hex, 'hex')]));
const original = Object.fromEntries(['tools/rename_cell.mjs', 'tools/inspect.mjs', 'rename.mbt', 'rename_test.mbt',
  'cmd/inspect/rename_cell.mbt', '_build/js/debug/build/cmd/inspect/inspect.js'].map(name => [name, readFileSync(join(root, name))]));
const sourceFile = join(root, 'examples/cell-rename-source.gds');
assert.deepEqual(readFileSync(sourceFile), sources.original);
const cases = [];
const files = [];
function run(name, script, args, exit) {
  const child = spawnSync(process.execPath, [join(root, script), ...args], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  writeFileSync(join(output, name + '.json'), JSON.stringify({ name, command: [process.execPath, script, ...args],
    expectedExit: exit, status: child.status, stdout: child.stdout, stderr: child.stderr, error: child.error?.message }, null, 2), { flag: 'wx' });
  assert.ifError(child.error); assert.equal(child.status, exit, name); assert.equal(child.stderr, '', name);
  cases.push({ name, exit: child.status });
  return JSON.parse(child.stdout);
}
function input(name, bytes) {
  const path = join(output, name + '.gds');
  writeFileSync(path, bytes, { flag: 'wx' });
  return path;
}
function rename(name, path, bytes, oldName, newName, expectedKey, cells, count) {
  const target = join(output, name + '-saved.gds');
  const response = run(name, 'tools/rename_cell.mjs', [path, oldName, newName, target], 0);
  assert.equal(response.schema, 'gdsii-cell-rename-v1');
  assert.equal(response.old_name, oldName); assert.equal(response.new_name, newName);
  assert.equal(response.changed, oldName !== newName); assert.equal(response.updated_references, count);
  assert.deepEqual(response.cells, cells);
  assert.deepEqual(response.source, { path: resolve(path), bytes: bytes.length, sha256: sha256(bytes) });
  const physical = readFileSync(target);
  assert.deepEqual(physical, expected[expectedKey]);
  assert.deepEqual(response.output, { path: resolve(target), bytes: physical.length, sha256: sha256(physical) });
  assert.deepEqual(readFileSync(path), bytes);
  files.push({ name, oldName, newName, updatedReferences: count, bytes: physical.length, sha256: sha256(physical), completeIndependentStreamMatched: true, sourceUnchanged: true });
  return target;
}
function catalog(name, path, cells, tops, missing = []) {
  const report = run(name, 'tools/inspect.mjs', ['--catalog', path], 0).catalog;
  assert.equal(report.name, 'gate');
  assert.deepEqual(report.cells.map(cell => cell.name), cells);
  assert.deepEqual(report.top_cells, tops);
  assert.deepEqual(report.missing_references.map(ref => ref.target), missing);
  return report;
}
const renamed = rename('rename-arbitrary-original', sourceFile, sources.original, 'gate', 'coreA', 'renamed', ['coreA', 'die', 'probe'], 3);
const inventory = catalog('renamed-physical-catalog', renamed, ['coreA', 'die', 'probe'], ['die', 'probe']);
assert.deepEqual(inventory.cells.flatMap(cell => cell.references.map(ref => [cell.name, ref.kind, ref.target, ref.resolved])),
  [['die', 'Sref', 'coreA', true], ['die', 'Aref', 'coreA', true], ['probe', 'Sref', 'coreA', true]]);
const hierarchy = run('renamed-physical-hierarchy', 'tools/inspect.mjs', ['--hierarchy', renamed, 'die'], 0).hierarchy;
assert.deepEqual(hierarchy.reachable_cells, ['coreA', 'die']);
assert.deepEqual(hierarchy.missing_references, []); assert.deepEqual(hierarchy.cycle, []);
const geometry = run('renamed-physical-geometry', 'tools/inspect.mjs', [renamed, 'die', '12', '4', '4', '3'], 0);
assert.deepEqual(geometry.selection.rects.map(r => [r.min_x, r.min_y, r.max_x, r.max_y]), vectors.expectedSemantics.dieRectangles);
assert.deepEqual(geometry.flattened.shapes.filter(shape => shape.kind === 'Text').map(shape => shape.text), ['gate', 'gate', 'gate']);
const preflight = run('renamed-physical-preflight', 'tools/inspect.mjs', ['--preflight', renamed, 'die', '12', '4', '4', '3'], 0).preflight;
assert.equal(preflight.status, 'RectanglesClear'); assert.equal(preflight.checked_rectangles, 3);
assert.deepEqual(preflight.skipped, []); assert.deepEqual(preflight.issues, []);
const comparison = run('unchanged-parent-findings-receiver', 'tools/inspect.mjs', ['--compare', sourceFile, renamed, 'die', '12', '4', '4', '3'], 0).comparison;
assert.equal(comparison.status, 'NoNewIssues');
// This comparison is finding-level evidence; complete stream and manual boxes
// above independently cover the geometry/record preservation claim.
function records(bytes) {
  const result = [];
  let offset = 0;
  while (offset < bytes.length) {
    const length = bytes.readUInt16BE(offset);
    assert.ok(length >= 4 && offset + length <= bytes.length);
    const kind = bytes[offset + 2];
    result.push({ offset, kind, type: bytes[offset + 3], payloadHex: bytes.subarray(offset + 4, offset + length).toString('hex') });
    offset += length;
    if (kind === 4) break;
  }
  return { records: result, tail: bytes.subarray(offset) };
}
const raw = records(readFileSync(renamed));
assert.equal(raw.tail.length, 0);
assert.equal(raw.records.find(r => r.kind === 3).payloadHex, vectors.expectedSemantics.unitsHex);
const decode = r => Buffer.from(r.payloadHex, 'hex').toString('ascii').replace(/\0$/, '');
assert.deepEqual(raw.records.filter(r => r.kind === 6).map(decode), ['coreA', 'die', 'probe']);
assert.deepEqual(raw.records.filter(r => r.kind === 18).map(decode), ['coreA', 'coreA', 'coreA']);
assert.deepEqual(raw.records.filter(r => [2, 25, 44, 0x72, 0x73].includes(r.kind)).map(r => [r.kind, decode(r)]),
  [[2, 'gate'], [0x73, 'gate'], [0x72, 'gate'], [44, 'gate'], [25, 'gate']]);
writeFileSync(join(output, 'renamed-physical-raw-records.json'), JSON.stringify(raw.records, null, 2), { flag: 'wx' });
const longName = vectors.queries.longName;
const long = rename('long-supported-name', sourceFile, sources.original, 'gate', longName, 'long_name', [longName, 'die', 'probe'], 3);
catalog('long-physical-catalog', long, [longName, 'die', 'probe'], ['die', 'probe']);
const spaced = rename('root-name-with-space', sourceFile, sources.original, 'probe', 'probe 2', 'root_name_with_space', ['gate', 'die', 'probe 2'], 0);
catalog('spaced-physical-catalog', spaced, ['gate', 'die', 'probe 2'], ['die', 'probe 2']);
assert.deepEqual(run('spaced-physical-hierarchy', 'tools/inspect.mjs', ['--hierarchy', spaced, 'probe 2'], 0).hierarchy.reachable_cells, ['gate', 'probe 2']);
const noop = rename('byte-identical-noop', sourceFile, sources.original, 'gate', 'gate', 'noop', ['gate', 'die', 'probe'], 0);
catalog('noop-physical-catalog', noop, ['gate', 'die', 'probe'], ['die', 'probe']);
assert.equal(records(readFileSync(noop)).tail.length, 24);
const captureSource = input('pending-destination', sources.capture);
catalog('original-pending-stays-legal', captureSource, ['gate', 'die', 'probe', 'pending'], ['die', 'probe', 'pending'], ['coreA']);
const pending = rename('unrelated-missing-preserved', captureSource, sources.capture, 'gate', 'fresh', 'unrelated_missing', ['fresh', 'die', 'probe', 'pending'], 3);
catalog('pending-physical-catalog', pending, ['fresh', 'die', 'probe', 'pending'], ['die', 'probe', 'pending'], ['coreA']);
assert.deepEqual(run('pending-physical-hierarchy', 'tools/inspect.mjs', ['--hierarchy', pending, 'pending'], 0).hierarchy.missing_references.map(r => [r.target, r.resolved]), [['coreA', false]]);
const cycleSource = input('self-cycle', sources.cycle);
const cycle = rename('self-reference-renamed', cycleSource, sources.cycle, 'gate', 'coreA', 'cycle', ['coreA', 'die', 'probe'], 4);
catalog('cycle-physical-catalog', cycle, ['coreA', 'die', 'probe'], ['die', 'probe']);
assert.deepEqual(run('cycle-physical-hierarchy', 'tools/inspect.mjs', ['--hierarchy', cycle, 'coreA'], 0).hierarchy.cycle, ['coreA', 'coreA']);

function queryError(name, path, bytes, oldName, newName, detail) {
  const target = join(output, name + '-absent.gds');
  const response = run(name, 'tools/rename_cell.mjs', [path, oldName, newName, target], 2);
  assert.equal(response.error.stage, 'query'); assert.deepEqual(response.error.detail, detail);
  assert.equal(existsSync(target), false); assert.deepEqual(readFileSync(path), bytes);
}
queryError('existing-symbol-collision', sourceFile, sources.original, 'gate', 'die', vectors.queryErrors.collision);
queryError('unresolved-destination-capture', captureSource, sources.capture, 'gate', 'coreA', vectors.queryErrors.capture);
queryError('missing-original-name', sourceFile, sources.original, 'absent', 'fresh', vectors.queryErrors.missing);
queryError('missing-name-noop-is-error', sourceFile, sources.original, 'absent', 'absent', vectors.queryErrors.missing);
queryError('empty-new-name', sourceFile, sources.original, 'gate', '', vectors.queryErrors.empty);
queryError('non-ascii-new-name', sourceFile, sources.original, 'gate', 'λ', vectors.queryErrors.unicode);
const malformed = input('malformed', Buffer.from([0]));
const malformedTarget = join(output, 'malformed-absent.gds');
assert.equal(run('malformed-no-artifact', 'tools/rename_cell.mjs', [malformed, 'gate', 'coreA', malformedTarget], 2).error.stage, 'parse');
assert.equal(existsSync(malformedTarget), false);
const callerOwned = Buffer.from('caller-owned target\n');
const existingTarget = input('caller-owned', callerOwned);
assert.equal(run('refuse-existing-target', 'tools/rename_cell.mjs', [sourceFile, 'gate', 'coreA', existingTarget], 2).error.code, 'EEXIST');
assert.deepEqual(readFileSync(existingTarget), callerOwned);
assert.equal(run('refuse-source-overwrite', 'tools/rename_cell.mjs', [sourceFile, 'gate', 'coreA', sourceFile], 2).error.code, 'EEXIST');
assert.deepEqual(readFileSync(sourceFile), sources.original);
const missingParent = join(output, 'missing-parent', 'out.gds');
assert.equal(run('output-parent-failure', 'tools/rename_cell.mjs', [sourceFile, 'gate', 'coreA', missingParent], 2).error.stage, 'output');
assert.equal(existsSync(missingParent), false);
const missingOutput = join(output, 'missing-input-absent.gds');
assert.equal(run('missing-input', 'tools/rename_cell.mjs', [join(output, 'absent.gds'), 'gate', 'coreA', missingOutput], 2).error.stage, 'input');
assert.equal(existsSync(missingOutput), false);
assert.equal(run('missing-arguments', 'tools/rename_cell.mjs', [sourceFile, 'gate'], 2).error.code, 'RENAME_ARGUMENTS_REQUIRED');
for (const [name, bytes] of Object.entries(original)) assert.deepEqual(readFileSync(join(root, name)), bytes);
assert.deepEqual(readFileSync(sourceFile), sources.original);
const git = spawnSync('git', ['--no-optional-locks', 'rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' });
assert.ifError(git.error); assert.equal(git.status, 0);
const identity = { schema: 'gdsii-cell-rename-acceptance-v1', status: 'PASS', commit: git.stdout.trim(), node: process.version,
  fixtureSHA256: sha256(vectorBytes), sourceExample: { bytes: sources.original.length, sha256: sha256(sources.original) },
  producerSHA256: sha256(original['tools/rename_cell.mjs']), receiverSHA256: sha256(original['tools/inspect.mjs']),
  coreSourceSHA256: sha256(original['rename.mbt']), engineSHA256: sha256(original['_build/js/debug/build/cmd/inspect/inspect.js']),
  suiteSHA256: sha256(readFileSync(fileURLToPath(import.meta.url))), files, cases,
  physicalReceivers: ['catalog', 'hierarchy', 'positional geometry', 'preflight', 'parent finding comparison'],
  originalInputsAndArtifactsUnchanged: true,
  boundary: 'Own real file/public receivers plus complete independent streams and boxes; not third-party adoption, opaque symbol inference or geometry signoff. Late I/O partial-new-file behavior is documented, not fault-injected.' };
writeFileSync(join(output, 'acceptance.json'), JSON.stringify(identity, null, 2), { flag: 'wx' });
console.log(JSON.stringify(identity));
if (process.env.GITHUB_ACTIONS === 'true') {
  const message = JSON.stringify(identity).replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A');
  console.log(`::notice title=Cell rename acceptance::${message}`);
}
