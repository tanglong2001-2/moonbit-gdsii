import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url)), output = resolve(process.argv[2] ?? join(root, '_build/ci/rectangle-area'));
assert.equal(existsSync(output), false, 'Preserve earlier evidence; choose a fresh output directory.'); mkdirSync(output, { recursive: true });
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const canonical = value => Array.isArray(value) ? value.map(canonical) : value && typeof value === 'object' ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonical(value[key])])) : value;
const vectorsBytes = readFileSync(join(root, 'testdata/rectangle-area-vectors.json'));
assert.equal(sha256(vectorsBytes), '5737fca14f00b976c8f302b11dd0c4e60e3b38ddf8f0cb8aaba3958fdb2604e1');
const vectors = JSON.parse(vectorsBytes), sourceBytes = Buffer.from(vectors.source_hex, 'hex'), sourcePath = join(output, 'source 原始.gds');
writeFileSync(sourcePath, sourceBytes, { flag: 'wx' }); assert.deepEqual(readFileSync(join(root, 'examples/rectangle-area-source.gds')), sourceBytes);
const names = ['rectangle_area.mbt', 'rectangle_area_test.mbt', 'cmd/inspect/rectangle_area.mbt', 'cmd/inspect/main.mbt', 'tools/measure_area.mjs',
  'examples/read_rectangle_area.mjs', '.ci/rectangle_area.mjs', 'testdata/rectangle-area-vectors.json', 'examples/rectangle-area-source.gds', '_build/js/debug/build/cmd/inspect/inspect.js'];
const original = Object.fromEntries(names.map(name => [name, readFileSync(join(root, name))]));
const fingerprint = (path, bytes) => ({ path, bytes: bytes.length, sha256: sha256(bytes) });
const producer = join(root, 'tools/measure_area.mjs'), receiver = join(root, 'examples/read_rectangle_area.mjs');
const cases = [], reports = [], produced = {};
function run(name, script, args, expectedExit) {
  const child = spawnSync(process.execPath, [script, ...args], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  writeFileSync(join(output, 'process-' + name + '.json'), JSON.stringify({ name, command: [process.execPath, script, ...args], expectedExit,
    status: child.status, stdout: child.stdout, stderr: child.stderr, error: child.error?.message }, null, 2) + '\n', { flag: 'wx' });
  assert.ifError(child.error); assert.equal(child.status, expectedExit, name); assert.equal(child.stderr, '', name);
  cases.push({ name, exit: child.status }); return JSON.parse(child.stdout);
}
function argumentsFor(q, path, input = sourcePath) { return [input, q.cell, String(q.layer), String(q.datatype), path, String(q.budget)]; }
for (const test of vectors.measurements) {
  const path = join(output, test.id + '-report.json'), q = test.query;
  const receipt = run(test.id + '-produce', producer, argumentsFor(q, path), test.exit);
  const bytes = readFileSync(path), report = JSON.parse(bytes);
  assert.deepEqual(report, { schema: 'gdsii-rectangle-area-v1', source: fingerprint(sourcePath, sourceBytes), query: q, measurement: test.expected }, test.id + ': full independently expected geometry/area/skips');
  assert.deepEqual(receipt, { schema: 'gdsii-rectangle-area-file-v1', source: fingerprint(sourcePath, sourceBytes), query: q, status: test.expected.status,
    output: fingerprint(path, bytes) });
  assert.deepEqual(run(test.id + '-receive', receiver, [path], test.exit), { schema: 'gdsii-rectangle-area-received-v1', source_verified: true, precision: 'uint64-decimal', query: q, measurement: test.expected });
  reports.push({ case: test.id, status: test.expected.status, area_dbu2: test.expected.area_dbu2, checkedRectangles: test.expected.checked_rectangles, skippedShapes: test.expected.skipped.length,
    measurementSHA256: sha256(JSON.stringify(canonical(report.measurement))), completeIndependentMeasurementEqual: true, actualPhysicalRecipientPassed: true, bytes: bytes.length, sha256: sha256(bytes) });
  produced[test.id] = { path, report, bytes };
}
const absent = join(output, 'must-not-exist.json'), q = vectors.measurements[0].query;
function failed(name, args, stage, code, script = producer) {
  const value = run(name, script, args, 2); assert.equal(value.error.stage, stage, name); assert.equal(value.error.code, code, name); return value;
}
failed('arguments-required', [], 'request', 'AREA_ARGUMENTS_REQUIRED');
failed('missing-source', argumentsFor(q, absent, join(output, 'absent.gds')), 'source', 'ENOENT');
const bad = join(output, 'malformed.gds'); writeFileSync(bad, Buffer.from([0, 3, 0, 2]), { flag: 'wx' });
assert.deepEqual(failed('malformed-source', argumentsFor(q, absent, bad), 'source', 'GDS_PARSE_ERROR').error.detail, ['InvalidRecord', 0, 'invalid or truncated record length']);
for (const [name, query, detail] of [
  ['missing-cell', { ...q, cell: 'absent' }, ['MissingCell', 'absent']],
  ['missing-target', { ...q, cell: 'missing' }, ['MissingCell', 'ghost']],
  ['cyclic-root', { ...q, cell: 'cycle' }, ['CyclicReference', ['cycle', 'cycle']]],
  ['expansion-budget', { ...q, budget: 1 }, ['ExpansionLimit', 1]],
]) assert.deepEqual(failed(name, argumentsFor(query, absent), 'query', 'AREA_QUERY_ERROR').error.detail, detail);
for (const [name, slot, value] of [
  ['blank-layer', 2, ' '], ['negative-layer', 2, '-1'], ['fraction-type', 3, '1.5'], ['overflow-type', 3, '2147483648'],
  ['nan-layer', 2, 'NaN'], ['infinite-type', 3, 'Infinity'], ['zero-budget', 5, '0'], ['blank-budget', 5, ''],
  ['overflow-budget', 5, '2147483648'], ['empty-cell', 1, ''],
]) { const args = argumentsFor(q, absent); args[slot] = value; failed(name, args, 'request', 'INVALID_AREA_QUERY'); }
assert.equal(existsSync(absent), false);
for (const [name, path] of [['existing-report', produced['top-overlap'].path], ['source-path', sourcePath]]) {
  const bytes = readFileSync(path); failed(name + '-refused', argumentsFor(q, path), 'output', 'EEXIST'); assert.deepEqual(readFileSync(path), bytes);
}
failed('missing-output-directory', argumentsFor(q, join(output, 'absent-directory', 'area.json')), 'output', 'ENOENT');
const staleSource = join(output, 'stale-source.gds'), staleReport = join(output, 'stale-report.json');
writeFileSync(staleSource, sourceBytes, { flag: 'wx' }); run('stale-source-produce', producer, argumentsFor(q, staleReport, staleSource), 0);
writeFileSync(staleSource, Buffer.concat([sourceBytes, Buffer.from([0])]));
assert.deepEqual(run('stale-source-reject', receiver, [staleReport], 2), { error: { stage: 'receiver', message: 'source bytes changed since this measurement.' } });
// The reader never converts exact decimal area to Number. Invalid numeric wire
// values and inconsistent skip coverage are rejected, without an auth claim.
const rounded = structuredClone(produced['full-int32-area'].report); rounded.measurement.area_dbu2 = Number(rounded.measurement.area_dbu2);
const roundedPath = join(output, 'invalid-number-area.json'); writeFileSync(roundedPath, JSON.stringify(rounded), { flag: 'wx' });
assert.deepEqual(run('rounded-area-receiver-reject', receiver, [roundedPath], 2), { error: { stage: 'receiver', message: 'Invalid exact area or measurement scope.' } });
const incomplete = structuredClone(produced['partial-selected'].report); incomplete.measurement.skipped = []; incomplete.measurement.status = 'Complete';
const incompletePath = join(output, 'inconsistent-coverage.json'); writeFileSync(incompletePath, JSON.stringify(incomplete), { flag: 'wx' });
assert.deepEqual(run('inconsistent-coverage-receiver-reject', receiver, [incompletePath], 2), { error: { stage: 'receiver', message: 'Incomplete or inconsistent geometry scope.' } });
for (const [name, body, code] of [
  ['nonzero-child', 'process.stdout.write(' + JSON.stringify(JSON.stringify({ measurement: vectors.measurements[0].expected })) + ');process.exitCode=23;', 'ENGINE_EXIT'],
  ['truncated-child', 'process.stdout.write("{");', 'ENGINE_RESPONSE_INVALID'],
  ['number-area-child', 'process.stdout.write(' + JSON.stringify(JSON.stringify({ measurement: { ...vectors.measurements[2].expected, area_dbu2: Number(vectors.measurements[2].expected.area_dbu2) } })) + ');', 'ENGINE_RESPONSE_INVALID'],
]) {
  const dir = join(output, name), tool = join(dir, 'tools/measure_area.mjs'), engine = join(dir, '_build/js/debug/build/cmd/inspect/inspect.js'), path = join(dir, 'must-not-exist.json');
  mkdirSync(dirname(tool), { recursive: true }); mkdirSync(dirname(engine), { recursive: true });
  writeFileSync(tool, original['tools/measure_area.mjs'], { flag: 'wx' }); writeFileSync(engine, body, { flag: 'wx' });
  failed(name, argumentsFor(name === 'number-area-child' ? vectors.measurements[2].query : q, path), 'engine', code, tool); assert.equal(existsSync(path), false);
}
const dir = join(output, 'snapshot-bound'), sourceCopy = join(dir, 'source.gds'), toolCopy = join(dir, 'tools/measure_area.mjs');
const bridgePath = join(dir, '_build/js/debug/build/cmd/inspect/inspect.js'), trace = join(dir, 'forwarded-request.json'), snapshotReport = join(dir, 'area.json');
mkdirSync(dirname(toolCopy), { recursive: true }); mkdirSync(dirname(bridgePath), { recursive: true });
writeFileSync(sourceCopy, sourceBytes, { flag: 'wx' }); writeFileSync(toolCopy, original['tools/measure_area.mjs'], { flag: 'wx' });
const bridge = `const fs=require('node:fs'),cp=require('node:child_process');const request=fs.readFileSync(0,'utf8');fs.writeFileSync(${JSON.stringify(trace)},request,{flag:'wx'});fs.appendFileSync(${JSON.stringify(sourceCopy)},Buffer.from([0]));const child=cp.spawnSync(process.execPath,[${JSON.stringify(join(root, '_build/js/debug/build/cmd/inspect/inspect.js'))}],{input:request,encoding:'utf8',maxBuffer:67108864});if(child.error)throw child.error;process.stdout.write(child.stdout);process.stderr.write(child.stderr);process.exitCode=child.status;`;
writeFileSync(bridgePath, bridge, { flag: 'wx' });
run('snapshot-bound-produce', toolCopy, argumentsFor(q, snapshotReport, sourceCopy), 0);
assert.deepEqual(JSON.parse(readFileSync(trace)), { mode: 'rectangle-area', hex: vectors.source_hex, ...q });
assert.deepEqual(JSON.parse(readFileSync(snapshotReport)), { schema: 'gdsii-rectangle-area-v1', source: fingerprint(sourceCopy, sourceBytes), query: q, measurement: vectors.measurements[0].expected });
assert.deepEqual(run('snapshot-bound-receiver-reject', receiver, [snapshotReport], 2), { error: { stage: 'receiver', message: 'source bytes changed since this measurement.' } });
for (const [name, bytes] of Object.entries(original)) assert.deepEqual(readFileSync(join(root, name)), bytes, name);
assert.deepEqual(readFileSync(sourcePath), sourceBytes);
const manifest = { schema: 'gdsii-rectangle-area-acceptance-v1', status: 'PASS', commit: process.env.GITHUB_SHA ?? null, cases, reports,
  vectorsSHA256: sha256(vectorsBytes), sourceIdentities: Object.fromEntries(Object.entries(original).map(([name, bytes]) => [name, { bytes: bytes.length, sha256: sha256(bytes) }])),
  originalInput: fingerprint(sourcePath, sourceBytes), fullIndependentMeasurementAndSkipListsEqual: true, exactUnsigned64Decimal: true, originalDrcUnchanged: true,
  incompleteAndEmptyCannotPass: true, physicalSavedReportConsumed: true, sourceSnapshotForwardedToRealEngine: true,
  recipientBoundary: 'Checks source physical binding and exact decimal/scope fields; does not reflatten GDS/recompute area or authenticate arbitrary report authors.', externalAdoptionClaimed: false };
const engine = manifest.sourceIdentities['_build/js/debug/build/cmd/inspect/inspect.js'];
const notice = { schema: manifest.schema, status: 'PASS', commit: manifest.commit ?? '0'.repeat(40), caseCount: cases.length, casesSHA256: sha256(JSON.stringify(cases)),
  exitCounts: Object.fromEntries([0, 2, 4].map(code => [code, cases.filter(item => item.exit === code).length])), reportCount: reports.length,
  reportSemanticsSHA256: sha256(JSON.stringify(reports.map(({ bytes, sha256, ...semantic }) => semantic))), reports: reports.map(item => [item.case, item.bytes, item.sha256]),
  exactAreas: reports.map(item => [item.case, item.area_dbu2, item.status]), vectorsSHA256: manifest.vectorsSHA256, engineBytes: engine.bytes, engineSHA256: engine.sha256,
  originalInput: { bytes: sourceBytes.length, sha256: sha256(sourceBytes) }, fullIndependentMeasurementAndSkipListsEqual: true, exactUnsigned64Decimal: true,
  incompleteAndEmptyCannotPass: true, sourceSnapshotForwardedToRealEngine: true, externalAdoptionClaimed: false };
const text = JSON.stringify(notice); assert.ok(Buffer.byteLength(text) < 3900);
writeFileSync(join(output, 'checks-notice.json'), text + '\n', { flag: 'wx' }); writeFileSync(join(output, 'acceptance.json'), JSON.stringify(manifest, null, 2) + '\n', { flag: 'wx' });
process.stdout.write(JSON.stringify(manifest) + '\n');
if (process.env.GITHUB_ACTIONS === 'true') process.stdout.write('::notice title=Rectangle union area acceptance::' + text.replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A') + '\n');
