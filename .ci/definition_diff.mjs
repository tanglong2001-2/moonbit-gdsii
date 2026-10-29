import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/definition-diff'));
assert.equal(existsSync(output), false, 'Retain prior evidence; choose a fresh directory.'); mkdirSync(output, { recursive: true });
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const vectorBytes = readFileSync(join(root, 'testdata/definition-diff-vectors.json'));
assert.equal(sha256(vectorBytes), 'a3da1433dd6ebe1760c3189c75602008ad285b80ce55daad9ab547ee541f1f0d');
const vectors = JSON.parse(vectorBytes); const sources = {};
for (const [name, hex] of Object.entries(vectors.sources)) {
  const path = join(output, 'source-' + name + '.gds'); const bytes = Buffer.from(hex, 'hex');
  writeFileSync(path, bytes, { flag: 'wx' }); sources[name] = { path, bytes };
}
assert.deepEqual(readFileSync(join(root, 'examples/definition-diff-before.gds')), sources.base.bytes);
assert.deepEqual(readFileSync(join(root, 'examples/definition-diff-after.gds')), sources.grow.bytes);
const names = ['definition_diff.mbt', 'definition_diff_test.mbt', 'cmd/inspect/definition_diff.mbt', 'cmd/inspect/main.mbt',
  'tools/definition_diff.mjs', 'examples/read_definition_diff.mjs', '.ci/definition_diff.mjs',
  'testdata/definition-diff-vectors.json', 'tools/inspect.mjs', '_build/js/debug/build/cmd/inspect/inspect.js'];
const original = Object.fromEntries(names.map(name => [name, readFileSync(join(root, name))]));
const fingerprint = input => ({ path: input.path, bytes: input.bytes.length, sha256: sha256(input.bytes) });
const cases = []; const reports = []; const produced = {};
function run(name, script, args, expectedExit) {
  const child = spawnSync(process.execPath, [join(root, script), ...args], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  // Prefix process records so an input fixture can never take the same pathname.
  writeFileSync(join(output, 'process-' + name + '.json'), JSON.stringify({ name, command: [process.execPath, script, ...args],
    expectedExit, status: child.status, stdout: child.stdout, stderr: child.stderr, error: child.error?.message }, null, 2) + '\n', { flag: 'wx' });
  assert.ifError(child.error); assert.equal(child.status, expectedExit, name); assert.equal(child.stderr, '', name);
  cases.push({ name, exit: child.status }); return JSON.parse(child.stdout);
}
for (const test of vectors.cases) {
  const before = sources[test.before]; const after = sources[test.after]; const path = join(output, test.id + '-report.json');
  const bindings = { before: fingerprint(before), after: fingerprint(after) };
  const receipt = run(test.id + '-produce', 'tools/definition_diff.mjs', [before.path, after.path, path], test.exit);
  const bytes = readFileSync(path);
  assert.deepEqual(JSON.parse(bytes), { schema: 'gdsii-definition-diff-v1', ...bindings, diff: test.expected }, test.id + ': full independent raw inventory');
  assert.deepEqual(receipt, { schema: 'gdsii-definition-diff-file-v1', ...bindings, status: test.exit === 0 ? 'IdenticalBytes' : 'ChangedBytes',
    output: { path, bytes: bytes.length, sha256: sha256(bytes) } });
  const received = run(test.id + '-receive', 'examples/read_definition_diff.mjs', [path], test.exit);
  const first = test.expected.first_difference;
  const span = (range, variant, name) => range === null ? null : { ...range, sha256: sha256(Buffer.from(vectors.cell_blocks[variant][name], 'hex')) };
  assert.deepEqual(received, { schema: 'gdsii-definition-diff-received-v1', inputs_verified: true, status: test.exit === 0 ? 'IdenticalBytes' : 'ChangedBytes',
    first_difference: first, first_bytes: first === null ? null : { before: first < before.bytes.length ? before.bytes[first] : null, after: first < after.bytes.length ? after.bytes[first] : null },
    cells: test.expected.cells.map(cell => ({ name: cell.name, status: cell.status, before: span(cell.before, test.before, cell.name), after: span(cell.after, test.after, cell.name) })) });
  reports.push({ case: test.id, status: receipt.status, exit: test.exit, cellStates: test.expected.cells.map(c => [c.name, c.status]),
    bytes: bytes.length, sha256: sha256(bytes), completeIndependentReportMatched: true, physicalCellBlocksRead: true }); produced[test.id] = path;
}
for (const variant of ['base', 'membership']) {
  const catalog = run('physical-catalog-' + variant, 'tools/inspect.mjs', ['--catalog', sources[variant].path], 0).catalog;
  const expected = vectors.cases.find(test => test.after === variant).expected.after_cells;
  assert.deepEqual(catalog.cells.map(cell => cell.name), expected);
}
const absent = join(output, 'absent-report.json');
function failed(name, args, stage, code) {
  const response = run(name, 'tools/definition_diff.mjs', args, 2);
  assert.equal(response.error.stage, stage); assert.equal(response.error.code, code); return response;
}
failed('arguments-required', [], 'request', 'DEFINITION_DIFF_ARGUMENTS_REQUIRED');
failed('missing-before', [join(output, 'absent.gds'), sources.base.path, absent], 'before', 'ENOENT');
failed('missing-after', [sources.base.path, join(output, 'absent.gds'), absent], 'after', 'ENOENT');
const bad = join(output, 'malformed-input.gds'); writeFileSync(bad, Buffer.from(vectors.malformedSourceHex, 'hex'), { flag: 'wx' });
failed('malformed-before', [bad, sources.base.path, absent], 'before', 'GDS_PARSE_ERROR');
failed('malformed-after', [sources.base.path, bad, absent], 'after', 'GDS_PARSE_ERROR');
assert.equal(existsSync(absent), false);
const saved = readFileSync(produced['shifted-offsets']);
failed('existing-output-refused', [sources.base.path, sources.grow.path, produced['shifted-offsets']], 'output', 'EEXIST');
assert.deepEqual(readFileSync(produced['shifted-offsets']), saved);
for (const side of ['base', 'grow']) {
  failed(side + '-source-refused', [sources.base.path, sources.grow.path, sources[side].path], 'output', 'EEXIST');
  assert.deepEqual(readFileSync(sources[side].path), sources[side].bytes);
}
failed('missing-output-directory', [sources.base.path, sources.grow.path, join(output, 'absent-directory', 'report.json')], 'output', 'ENOENT');
for (const side of ['before', 'after']) {
  const before = join(output, 'stale-' + side + '-before.gds'); const after = join(output, 'stale-' + side + '-after.gds');
  const path = join(output, 'stale-' + side + '-report.json');
  writeFileSync(before, sources.base.bytes, { flag: 'wx' }); writeFileSync(after, sources.grow.bytes, { flag: 'wx' });
  run('stale-' + side + '-produce', 'tools/definition_diff.mjs', [before, after, path], 3);
  writeFileSync(side === 'before' ? before : after, side === 'before' ? sources.grow.bytes : sources.base.bytes);
  assert.deepEqual(run('stale-' + side + '-reject', 'examples/read_definition_diff.mjs', [path], 2),
    { error: { stage: 'receiver', message: `${side} bytes changed since this inventory.` } });
}
for (const [name, bytes] of Object.entries(original)) assert.deepEqual(readFileSync(join(root, name)), bytes);
for (const input of Object.values(sources)) assert.deepEqual(readFileSync(input.path), input.bytes);
const manifest = { schema: 'gdsii-definition-diff-acceptance-v1', status: 'PASS', commit: process.env.GITHUB_SHA ?? null, cases, reports,
  vectorsSHA256: sha256(vectorBytes), sourceIdentities: Object.fromEntries(Object.entries(original).map(([name, bytes]) => [name, { bytes: bytes.length, sha256: sha256(bytes) }])),
  originalInputs: Object.fromEntries(Object.entries(sources).map(([name, input]) => [name, fingerprint(input)])),
  offsetsDoNotChangeCellIdentity: true, opaqueAndDatesIncluded: true, wholeBytesIndependentOfViews: true,
  emptySidesHandled: true, actualCellBlocksRead: true, sourcesUnchanged: true, externalAdoptionClaimed: false };
const engine = manifest.sourceIdentities['_build/js/debug/build/cmd/inspect/inspect.js'];
const notice = { schema: manifest.schema, status: 'PASS', commit: manifest.commit ?? '0'.repeat(40),
  caseCount: cases.length, casesSHA256: sha256(JSON.stringify(cases)), exitCounts: Object.fromEntries([0, 2, 3].map(code => [code, cases.filter(c => c.exit === code).length])),
  reportCount: reports.length, reportSemanticsSHA256: sha256(JSON.stringify(reports.map(({ bytes, sha256, ...semantic }) => semantic))),
  reports: reports.map(r => [r.case, r.bytes, r.sha256]), vectorsSHA256: manifest.vectorsSHA256,
  engineBytes: engine.bytes, engineSHA256: engine.sha256,
  originalInputs: Object.fromEntries(Object.entries(sources).map(([name, input]) => [name, { bytes: input.bytes.length, sha256: sha256(input.bytes) }])),
  offsetsDoNotChangeCellIdentity: true, wholeBytesIndependentOfViews: true, emptySidesHandled: true, actualCellBlocksRead: true, externalAdoptionClaimed: false };
const noticeText = JSON.stringify(notice); assert.ok(Buffer.byteLength(noticeText) < 3900);
writeFileSync(join(output, 'checks-notice.json'), noticeText + '\n', { flag: 'wx' });
writeFileSync(join(output, 'acceptance.json'), JSON.stringify(manifest, null, 2) + '\n', { flag: 'wx' });
process.stdout.write(JSON.stringify(manifest) + '\n');
if (process.env.GITHUB_ACTIONS === 'true') process.stdout.write('::notice title=Definition diff acceptance::' + noticeText.replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A') + '\n');
