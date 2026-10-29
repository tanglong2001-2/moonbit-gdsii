// Independent full reports -> actual saved-report producer -> physical recipient.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/reference-impact'));
assert.equal(existsSync(output), false, 'Keep earlier evidence; choose a fresh directory.');
mkdirSync(output, { recursive: true });
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const vectorBytes = readFileSync(join(root, 'testdata/reference-impact-vectors.json'));
assert.equal(sha256(vectorBytes), 'b6e1034773ffde9ffba2b85cc28c0106079e3b21b530352228949d50657e3814');
const vectors = JSON.parse(vectorBytes);
const sourceFiles = {};
const sources = {};
for (const [name, hexadecimal] of Object.entries(vectors.sources)) {
  const bytes = Buffer.from(hexadecimal, 'hex');
  const path = join(output, name + '.gds');
  writeFileSync(path, bytes, { flag: 'wx' });
  sourceFiles[name] = path; sources[name] = bytes;
}
assert.deepEqual(readFileSync(join(root, 'examples/reference-impact.gds')), sources.main);
const sourceNames = ['reference_impact.mbt', 'reference_impact_test.mbt', 'cmd/inspect/main.mbt',
  'cmd/inspect/dependent_review.mbt', 'tools/review_dependents.mjs', 'examples/read_dependent_review.mjs',
  'tools/inspect.mjs', 'testdata/reference-impact-vectors.json', '.ci/reference_impact.mjs', '_build/js/debug/build/cmd/inspect/inspect.js'];
const original = Object.fromEntries(sourceNames.map(name => [name, readFileSync(join(root, name))]));
const cases = []; const reports = [];
function run(name, script, args, exit) {
  const child = spawnSync(process.execPath, [join(root, script), ...args], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  writeFileSync(join(output, name + '.json'), JSON.stringify({ name, command: [process.execPath, script, ...args],
    expectedExit: exit, status: child.status, stdout: child.stdout, stderr: child.stderr, error: child.error?.message }, null, 2) + '\n', { flag: 'wx' });
  assert.ifError(child.error); assert.equal(child.status, exit, name); assert.equal(child.stderr, '', name);
  cases.push({ name, exit: child.status });
  return JSON.parse(child.stdout);
}
const produced = {};
for (const test of vectors.cases) {
  const path = sourceFiles[test.source];
  const bytes = sources[test.source];
  const source = { path, bytes: bytes.length, sha256: sha256(bytes) };
  const target = join(output, test.id + '-report.json');
  const arguments_ = [path, test.target, '18', '0', String(test.width ?? 5), '0', target];
  if (test.budget !== undefined) arguments_.push(String(test.budget));
  const receipt = run(test.id + '-produce', 'tools/review_dependents.mjs', arguments_, test.exit);
  const saved = readFileSync(target);
  assert.deepEqual(receipt, { schema: 'gdsii-dependent-review-file-v1', source, target: test.target, status: test.expected.status,
    output: { path: target, bytes: saved.length, sha256: sha256(saved) } });
  const report = JSON.parse(saved);
  assert.deepEqual(report, { schema: 'gdsii-dependent-review-v1', source, ...test.expected }, test.id + ': complete independent report');
  const received = run(test.id + '-receive', 'examples/read_dependent_review.mjs', [target], test.exit);
  assert.deepEqual(received, { schema: 'gdsii-dependent-review-received-v1', target: test.target,
    target_defined: test.expected.dependency.target_defined, status: test.expected.status,
    counts: test.expected.counts, coverage: test.expected.coverage, source_verified: true,
    queue: test.expected.dependency.cells.map((cell, index) => {
      const result = test.expected.results[index];
      return { ...cell, outcome: Object.hasOwn(result, 'error') ? { error: result.error } : {
        status: result.preflight.status, checked_rectangles: result.preflight.checked_rectangles,
        skipped: result.preflight.skipped.length, issues: result.preflight.issues.length } };
    }) });
  // Existing file preflight receives the same physical input independently.
  if (['cycle-and-shared-callers', 'width-findings', 'findings-with-skips', 'per-cell-budget'].includes(test.id) || test.id === 'shortest-tie') {
    for (const result of test.expected.results) {
      if (test.id === 'shortest-tie' && result.cell !== 'top') continue;
      const args = ['--preflight', path, result.cell, '18', '0', String(test.width ?? 5), '0'];
      if (test.budget !== undefined) args.push(String(test.budget));
      const code = Object.hasOwn(result, 'error') ? 2 : result.preflight.status === 'ViolationsFound' ? 3 : result.preflight.status === 'RectanglesClear' ? 0 : 4;
      const response = run(test.id + '-existing-' + result.cell, 'tools/inspect.mjs', args, code);
      const { cell, ...expected } = result;
      assert.deepEqual(response, expected);
    }
  }
  assert.deepEqual(readFileSync(path), bytes);
  produced[test.id] = target;
  reports.push({ case: test.id, status: test.expected.status, exit: test.exit, cells: test.expected.dependency.cells.map(c => c.name),
    bytes: saved.length, sha256: sha256(saved), fullIndependentExpectedReportMatched: true, physicalReceiverRead: true });
}
const catalog = run('physical-input-catalog', 'tools/inspect.mjs', ['--catalog', sourceFiles.main], 0).catalog;
assert.deepEqual(catalog.cells.map(c => c.name), ['spare', 'leaf', 'mid', 'right', 'top', 'cycleA', 'cycleB', 'waiting']);
assert.deepEqual(catalog.top_cells, ['spare', 'top', 'waiting']);
const forward = run('physical-input-forward-hierarchy', 'tools/inspect.mjs', ['--hierarchy', sourceFiles.main, 'leaf'], 0).hierarchy;
assert.deepEqual(forward.reachable_cells, ['leaf']);

function failed(name, args, stage, code) {
  const response = run(name, 'tools/review_dependents.mjs', args, 2);
  assert.ok(Object.hasOwn(response, 'error'));
  if (stage) assert.equal(response.error.stage, stage);
  if (code) assert.equal(response.error.code, code);
  return response;
}
const absent = join(output, 'no-report.json');
failed('missing-source', [join(output, 'absent.gds'), 'leaf', '18', '0', '5', '0', absent], 'input', 'ENOENT');
assert.equal(existsSync(absent), false);
const malformed = join(output, 'malformed.gds');
writeFileSync(malformed, Buffer.from([0, 3, 0, 0]), { flag: 'wx' });
failed('malformed-source', [malformed, 'leaf', '18', '0', '5', '0', absent]);
assert.equal(existsSync(absent), false);
for (const [name, width, budget] of [['negative-width', '-1', undefined], ['empty-width', '', undefined], ['invalid-budget', '5', '0']]) {
  const args = [sourceFiles.main, 'leaf', '18', '0', width, '0', absent];
  if (budget !== undefined) args.push(budget);
  failed(name, args, 'request', 'INVALID_NUMERIC_ARGUMENT'); assert.equal(existsSync(absent), false);
}
failed('arguments-required', [], 'request', 'REVIEW_ARGUMENTS_REQUIRED');
const savedOriginal = readFileSync(produced['clear-callers']);
failed('existing-report-refused', [sourceFiles.acyclic, 'leaf', '18', '0', '5', '0', produced['clear-callers']], 'output', 'EEXIST');
assert.deepEqual(readFileSync(produced['clear-callers']), savedOriginal);
failed('source-overwrite-refused', [sourceFiles.main, 'leaf', '18', '0', '5', '0', sourceFiles.main], 'output', 'EEXIST');
assert.deepEqual(readFileSync(sourceFiles.main), sources.main);
failed('missing-output-directory', [sourceFiles.acyclic, 'leaf', '18', '0', '5', '0', join(output, 'absent-directory', 'review.json')], 'output', 'ENOENT');

// Alter only this gate's private temporary input to exercise a real stale handoff.
const staleSource = join(output, 'stale-private-source.gds');
const staleReport = join(output, 'stale-private-report.json');
writeFileSync(staleSource, sources.acyclic, { flag: 'wx' });
run('stale-report-produce', 'tools/review_dependents.mjs', [staleSource, 'leaf', '18', '0', '5', '0', staleReport], 0);
writeFileSync(staleSource, sources.main);
const rejected = run('stale-report-rejected', 'examples/read_dependent_review.mjs', [staleReport], 2);
assert.deepEqual(rejected, { error: { stage: 'receiver', message: 'Source bytes changed since this review.' } });
for (const [name, bytes] of Object.entries(original)) assert.deepEqual(readFileSync(join(root, name)), bytes);
for (const [name, bytes] of Object.entries(sources)) assert.deepEqual(readFileSync(sourceFiles[name]), bytes);
const manifest = { schema: 'gdsii-reference-impact-acceptance-v1', commit: process.env.GITHUB_SHA ?? null,
  vectorsSHA256: sha256(vectorBytes), cases, reports, completeIndependentReports: reports.length,
  sourceIdentities: Object.fromEntries(Object.entries(original).map(([name, bytes]) => [name, { bytes: bytes.length, sha256: sha256(bytes) }])),
  originalInputs: Object.fromEntries(Object.entries(sources).map(([name, bytes]) => [name, { bytes: bytes.length, sha256: sha256(bytes) }])),
  sourcesUnchanged: true, shortestDefinitionWitnesses: true, rootlessCyclesIncluded: true, unknownIsIncomplete: true,
  skippedFindingsCannotPass: true, stalePhysicalReportRejected: true, existingFilesNotOverwritten: true,
  externalAdoptionClaimed: false };
writeFileSync(join(output, 'acceptance.json'), JSON.stringify(manifest, null, 2) + '\n', { flag: 'wx' });
process.stdout.write(JSON.stringify(manifest) + '\n');
if (process.env.GITHUB_ACTIONS === 'true') {
  // Checks annotations have a bounded payload. Keep the full manifest in the
  // artifact; bind its complete cases/semantics with canonical digests here.
  const engine = manifest.sourceIdentities['_build/js/debug/build/cmd/inspect/inspect.js'];
  const notice = JSON.stringify({ schema: manifest.schema, status: 'PASS', commit: manifest.commit,
    vectorsSHA256: manifest.vectorsSHA256, caseCount: cases.length, casesSHA256: sha256(JSON.stringify(cases)),
    exitCounts: Object.fromEntries([0, 2, 3, 4].map(code => [code, cases.filter(test => test.exit === code).length])),
    reportCount: reports.length,
    reportSemanticsSHA256: sha256(JSON.stringify(reports.map(({ bytes, sha256, ...semantics }) => semantics))),
    reports: reports.map(report => [report.case, report.bytes, report.sha256]),
    engineBytes: engine.bytes, engineSHA256: engine.sha256,
    originalInputs: manifest.originalInputs, sourcesUnchanged: true, shortestDefinitionWitnesses: true,
    rootlessCyclesIncluded: true, unknownIsIncomplete: true, skippedFindingsCannotPass: true,
    stalePhysicalReportRejected: true, existingFilesNotOverwritten: true, externalAdoptionClaimed: false });
  assert.ok(Buffer.byteLength(notice) < 3900, 'Keep the complete Checks notice below the observed truncation boundary.');
  process.stdout.write('::notice title=Reference impact acceptance::' + notice.replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A') + '\n');
}
