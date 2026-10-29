// Independent frozen streams -> real producer -> physical GDS -> existing receivers.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/cell-extraction'));
assert.equal(existsSync(output), false, 'Retain previous evidence; choose a fresh output directory.');
mkdirSync(output, { recursive: true });
const sha256 = data => createHash('sha256').update(data).digest('hex');
const vectorBytes = readFileSync(join(root, 'testdata/cell-extract-vectors.json'));
assert.equal(sha256(vectorBytes), '5524d10c4489e5a240241f60658aa0f00bbf558a693645b76734118692537bcb');
const vectors = JSON.parse(vectorBytes);
const source = Object.fromEntries(Object.entries(vectors.sources).map(([key, hex]) => [key, Buffer.from(hex, 'hex')]));
const expected = Object.fromEntries(Object.entries(vectors.expected).map(([key, hex]) => [key, Buffer.from(hex, 'hex')]));
const example = join(root, 'examples/cell-extract-source.gds');
assert.deepEqual(readFileSync(example), source.original);
const originalArtifacts = Object.fromEntries(['tools/extract_cell.mjs', 'tools/inspect.mjs', 'extract.mbt',
  'extract_test.mbt', 'cmd/inspect/extract_cell.mbt', '_build/js/debug/build/cmd/inspect/inspect.js'].map(name => [name, readFileSync(join(root, name))]));
const cases = [];
const exports = [];
function run(name, script, args, expectedExit) {
  const result = spawnSync(process.execPath, [join(root, script), ...args], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  writeFileSync(join(output, name + '.json'), JSON.stringify({ name, command: [process.execPath, script, ...args],
    expectedExit, status: result.status, stdout: result.stdout, stderr: result.stderr, error: result.error?.message }, null, 2), { flag: 'wx' });
  assert.ifError(result.error);
  assert.equal(result.status, expectedExit, name);
  assert.equal(result.stderr, '', name);
  const response = JSON.parse(result.stdout);
  cases.push({ name, exit: result.status });
  return response;
}
function input(name, bytes) {
  const file = join(output, name + '.gds');
  writeFileSync(file, bytes, { flag: 'wx' });
  return file;
}
function exportCase(name, file, raw, cell, expectedKey, cells) {
  const target = join(output, name + '-export.gds');
  const result = run(name, 'tools/extract_cell.mjs', [file, cell, target], 0);
  assert.equal(result.schema, 'gdsii-cell-extraction-v1');
  assert.equal(result.cell, cell);
  assert.deepEqual(result.kept_cells, cells);
  assert.deepEqual(result.source, { path: resolve(file), bytes: raw.length, sha256: sha256(raw) });
  const actual = readFileSync(target); // independent physical readback, not producer JSON
  assert.deepEqual(actual, expected[expectedKey]);
  assert.deepEqual(result.output, { path: resolve(target), bytes: actual.length, sha256: sha256(actual) });
  assert.deepEqual(readFileSync(file), raw);
  exports.push({ name, cell, cells, bytes: actual.length, sha256: sha256(actual), independentCompleteStreamMatched: true, sourceUnchanged: true });
  return target;
}
function catalog(name, file, cells, tops) {
  const report = run(name, 'tools/inspect.mjs', ['--catalog', file], 0).catalog;
  assert.deepEqual(report.cells.map(cell => cell.name), cells);
  assert.deepEqual(report.top_cells, tops);
  assert.deepEqual(report.missing_references, []);
  return report;
}
function hierarchy(name, file, cell, cells, cycle = []) {
  const report = run(name, 'tools/inspect.mjs', ['--hierarchy', file, cell], 0).hierarchy;
  assert.deepEqual(report.reachable_cells, cells);
  assert.deepEqual(report.missing_references, []);
  assert.deepEqual(report.cycle, cycle);
  return report;
}

const top = exportCase('selected-top', example, source.original, 'top', 'top', ['leaf', 'top']);
catalog('top-physical-catalog', top, ['leaf', 'top'], ['top']);
const inventory = hierarchy('top-physical-hierarchy', top, 'top', ['leaf', 'top']);
assert.deepEqual(inventory.layers, [{ kind: 'Boundary', layer: 7, datatype: 2, elements: 1 }]);
assert.deepEqual(inventory.references.map(r => [r.cell, r.kind, r.target, r.columns, r.rows]),
  [['top', 'Sref', 'leaf', 1, 1], ['top', 'Aref', 'leaf', 2, 1]]);
const report = run('top-physical-preflight', 'tools/inspect.mjs', ['--preflight', top, 'top', '7', '2', '3', '1'], 3).preflight;
assert.equal(report.status, 'ViolationsFound');
assert.equal(report.checked_rectangles, 3);
assert.deepEqual(report.skipped, []);
assert.equal(report.issues.length, 3);
assert.deepEqual(report.issues.map(issue => issue.rectangles.map(r => [r.min_x, r.min_y, r.max_x, r.max_y])),
  vectors.expectedTop.rectangles.map(rect => [rect]));
for (const issue of report.issues) {
  assert.equal(issue.rule, 'Width');
  assert.equal(issue.required, 3); assert.equal(issue.measured, 2); assert.equal(issue.shortfall, 1);
}
// Read raw records independently to verify the preserved raw UNITS and full framing.
const actual = readFileSync(top);
let offset = 0;
const rawRecords = [];
while (offset < actual.length) {
  const length = actual.readUInt16BE(offset);
  assert.ok(length >= 4 && offset + length <= actual.length);
  rawRecords.push({ offset, kind: actual[offset + 2], type: actual[offset + 3], payloadHex: actual.subarray(offset + 4, offset + length).toString('hex') });
  offset += length;
}
assert.equal(offset, actual.length);
assert.equal(rawRecords.at(-1).kind, 4);
assert.equal(rawRecords.find(r => r.kind === 3).payloadHex, vectors.expectedTop.unitsHex);
assert.deepEqual(rawRecords.filter(r => [0x70, 0x71, 0x7f].includes(r.kind)).map(r => [r.kind, r.payloadHex]),
  [[0x70, '4c56'], [0x71, '4356'], [0x7f, '5859']]);
writeFileSync(join(output, 'top-physical-raw-records.json'), JSON.stringify(rawRecords, null, 2), { flag: 'wx' });

const leaf = exportCase('selected-child', example, source.original, 'leaf', 'leaf', ['leaf']);
catalog('child-physical-catalog', leaf, ['leaf'], ['leaf']);
for (const key of ['outside_missing', 'outside_cycle']) {
  const file = input(key, source[key]);
  const target = exportCase(key, file, source[key], 'top', 'top', ['leaf', 'top']);
  catalog(key + '-physical-catalog', target, ['leaf', 'top'], ['top']);
}
const cycleInput = input('cycle', source.cycle);
const cycle = exportCase('closed-cycle', cycleInput, source.cycle, 'A', 'cycle', ['A', 'B']);
catalog('cycle-physical-catalog', cycle, ['A', 'B'], []);
hierarchy('cycle-physical-hierarchy', cycle, 'A', ['A', 'B'], ['A', 'B', 'A']);
const cycleError = run('cycle-still-unflattened', 'tools/inspect.mjs', ['--preflight', cycle, 'A', '7', '2', '3', '1'], 2);
assert.deepEqual(cycleError.error, ['CyclicReference', ['A', 'B', 'A']]);
const emptyInput = input('empty', source.empty);
const empty = exportCase('empty-cell', emptyInput, source.empty, 'empty', 'empty', ['empty']);
catalog('empty-physical-catalog', empty, ['empty'], ['empty']);
assert.equal(run('empty-is-not-clear', 'tools/inspect.mjs', ['--preflight', empty, 'empty', '7', '2', '3', '1'], 4).preflight.status, 'EmptySelection');

function queryFailure(name, file, raw, cell, stage, detail) {
  const target = join(output, name + '-absent.gds');
  const result = run(name, 'tools/extract_cell.mjs', [file, cell, target], 2);
  assert.equal(result.error.stage, stage);
  if (detail) assert.deepEqual(result.error.detail, detail);
  assert.equal(existsSync(target), false);
  assert.deepEqual(readFileSync(file), raw);
  return result;
}
const missingInput = input('reachable-missing', source.reachable_missing);
queryFailure('reachable-missing-no-artifact', missingInput, source.reachable_missing, 'top', 'query', ['MissingCell', 'ghost']);
queryFailure('missing-selected-no-artifact', example, source.original, 'not-found', 'query', ['MissingCell', 'not-found']);
queryFailure('exact-name-not-trimmed', example, source.original, 'top ', 'query', ['MissingCell', 'top ']);
const malformed = Buffer.from([0]);
const malformedInput = input('malformed', malformed);
queryFailure('malformed-no-artifact', malformedInput, malformed, 'top', 'parse', ['InvalidRecord', 0, 'truncated header']);
const sentinel = Buffer.from('existing caller-owned bytes\n');
const existingTarget = input('existing-target', sentinel);
assert.equal(run('refuse-existing-target', 'tools/extract_cell.mjs', [example, 'top', existingTarget], 2).error.code, 'EEXIST');
assert.deepEqual(readFileSync(existingTarget), sentinel);
assert.equal(run('refuse-source-overwrite', 'tools/extract_cell.mjs', [example, 'top', example], 2).error.code, 'EEXIST');
assert.deepEqual(readFileSync(example), source.original);
const missingParent = join(output, 'absent-parent', 'out.gds');
assert.equal(run('output-parent-failure', 'tools/extract_cell.mjs', [example, 'top', missingParent], 2).error.stage, 'output');
assert.equal(existsSync(missingParent), false);
const absentOutput = join(output, 'missing-input-absent.gds');
assert.equal(run('missing-input', 'tools/extract_cell.mjs', [join(output, 'absent.gds'), 'top', absentOutput], 2).error.stage, 'input');
assert.equal(existsSync(absentOutput), false);
assert.equal(run('missing-arguments', 'tools/extract_cell.mjs', [example, 'top'], 2).error.code, 'EXTRACTION_ARGUMENTS_REQUIRED');

for (const [name, bytes] of Object.entries(originalArtifacts)) assert.deepEqual(readFileSync(join(root, name)), bytes);
assert.deepEqual(readFileSync(example), source.original);
const git = spawnSync('git', ['--no-optional-locks', 'rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' });
assert.ifError(git.error); assert.equal(git.status, 0);
const identity = { schema: 'gdsii-cell-extraction-acceptance-v1', status: 'PASS', commit: git.stdout.trim(), node: process.version,
  fixtureSHA256: sha256(vectorBytes), sourceExample: { bytes: source.original.length, sha256: sha256(source.original) },
  producerSHA256: sha256(originalArtifacts['tools/extract_cell.mjs']), receiverSHA256: sha256(originalArtifacts['tools/inspect.mjs']),
  coreSourceSHA256: sha256(originalArtifacts['extract.mbt']), engineSHA256: sha256(originalArtifacts['_build/js/debug/build/cmd/inspect/inspect.js']),
  suiteSHA256: sha256(readFileSync(fileURLToPath(import.meta.url))), exports, cases,
  physicalReceivers: ['catalog', 'hierarchy', 'preflight'], originalInputsAndArtifactsUnchanged: true,
  boundary: 'Complete hand-frozen stream oracle and own real public/file receivers; no third-party adoption or opaque-extension semantics claimed. Late I/O partial-new-file behavior is documented, not fault-injected here.' };
writeFileSync(join(output, 'acceptance.json'), JSON.stringify(identity, null, 2), { flag: 'wx' });
console.log(JSON.stringify(identity));
if (process.env.GITHUB_ACTIONS === 'true') {
  const message = JSON.stringify(identity).replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A');
  console.log(`::notice title=Cell extraction acceptance::${message}`);
}
