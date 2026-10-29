import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, resolve } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/comparison-plan'));
assert.equal(existsSync(output), false, 'Retain earlier outputs; use a fresh directory.'); mkdirSync(output, { recursive: true });
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const vectorBytes = readFileSync(join(root, 'testdata/comparison-plan-vectors.json'));
assert.equal(sha256(vectorBytes), '2f2bc4f134d0e90ea5e98754fd1c5f7c8ff0c25ef22942241dced7dfc7aff526');
const vectors = JSON.parse(vectorBytes);
const sources = {}; const plans = {};
for (const [kind, table, target] of [['source', vectors.sources, sources], ['plan', vectors.plans, plans]]) {
  for (const [name, hex] of Object.entries(table)) {
    const path = join(output, kind + '-' + name + (kind === 'source' ? '.gds' : '.json'));
    const bytes = Buffer.from(hex, 'hex'); writeFileSync(path, bytes, { flag: 'wx' }); target[name] = { path, bytes };
  }
}
assert.deepEqual(readFileSync(join(root, 'examples/comparison-plan-before.gds')), sources.before.bytes);
assert.deepEqual(readFileSync(join(root, 'examples/comparison-plan-after.gds')), sources.changed.bytes);
assert.deepEqual(readFileSync(join(root, 'examples/comparison-plan.json')), plans.focused.bytes);
const names = ['cmd/inspect/main.mbt', 'cmd/inspect/compare_plan.mbt', 'tools/compare_plan.mjs',
  'examples/read_comparison_plan.mjs', '.ci/compare_plan.mjs', 'testdata/comparison-plan-vectors.json',
  'tools/inspect.mjs', '_build/js/debug/build/cmd/inspect/inspect.js'];
const original = Object.fromEntries(names.map(name => [name, readFileSync(join(root, name))]));
const cases = []; const reports = []; const produced = {};
function run(name, script, args, expectedExit) {
  const result = spawnSync(process.execPath, [join(root, script), ...args], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  writeFileSync(join(output, name + '.json'), JSON.stringify({ name, command: [process.execPath, script, ...args], expectedExit,
    status: result.status, stdout: result.stdout, stderr: result.stderr, error: result.error?.message }, null, 2) + '\n', { flag: 'wx' });
  assert.ifError(result.error); assert.equal(result.status, expectedExit, name); assert.equal(result.stderr, '', name);
  cases.push({ name, exit: result.status }); return JSON.parse(result.stdout);
}
const fingerprint = input => ({ path: input.path, bytes: input.bytes.length, sha256: sha256(input.bytes) });
for (const test of vectors.cases) {
  const before = sources[test.before]; const after = sources[test.after]; const plan = plans[test.plan];
  const bindings = { before: fingerprint(before), after: fingerprint(after), plan: fingerprint(plan) };
  const path = join(output, test.id + '-report.json');
  const receipt = run(test.id + '-produce', 'tools/compare_plan.mjs', [before.path, after.path, plan.path, path], test.exit);
  const bytes = readFileSync(path); const report = JSON.parse(bytes);
  assert.deepEqual(report, { schema: 'gdsii-rectangle-comparison-result-v1', ...bindings, review: test.expected }, test.id + ': full independent report');
  assert.deepEqual(receipt, { schema: 'gdsii-comparison-plan-file-v1', ...bindings, cell: test.expected.cell, status: test.expected.status,
    output: { path, bytes: bytes.length, sha256: sha256(bytes) } });
  const received = run(test.id + '-receive', 'examples/read_comparison_plan.mjs', [path], test.exit);
  const side = value => Object.hasOwn(value, 'error') ? value : { status: value.preflight.status, checked_rectangles: value.preflight.checked_rectangles,
    skipped: value.preflight.skipped.length, issues: value.preflight.issues.length };
  assert.deepEqual(received, { schema: 'gdsii-comparison-plan-received-v1', inputs_verified: true, cell: test.expected.cell,
    status: test.expected.status, counts: test.expected.counts, coverage: test.expected.coverage,
    results: test.expected.results.map(result => ({ id: result.id, before: side(result.before), after: side(result.after),
      ...(result.comparison ? { comparison: { status: result.comparison.status, introduced: result.comparison.introduced.length,
        removed: result.comparison.removed.length, retained: result.comparison.retained } } : {}), ...(result.error ? { error: result.error } : {}) })) });
  if (['regression', 'retained-baseline', 'reordered-baseline', 'partial-coverage', 'dbu-mismatch'].includes(test.id)) {
    for (let index = 0; index < test.expected.profiles.length; index++) {
      const profile = test.expected.profiles[index]; const result = test.expected.results[index];
      const args = ['--compare', before.path, after.path, test.expected.cell, ...['layer', 'datatype', 'min_width', 'min_spacing'].map(key => String(profile[key]))];
      const code = result.error ? 2 : { NoNewIssues: 0, NewIssuesFound: 3, IncompleteComparison: 4 }[result.comparison.status];
      const old = run(test.id + '-pair-' + index, 'tools/inspect.mjs', args, code);
      assert.deepEqual(old, result.error ? { error: result.error } : { comparison: result.comparison });
    }
  }
  reports.push({ case: test.id, status: test.expected.status, exit: test.exit, ids: test.expected.profiles.map(p => p.id),
    bytes: bytes.length, sha256: sha256(bytes), completeIndependentReportMatched: true, physicalRecipientRead: true });
  produced[test.id] = path;
}
const absent = join(output, 'absent-report.json');
function failed(name, args, stage, code) {
  const result = run(name, 'tools/compare_plan.mjs', args, 2); assert.ok(result.error);
  assert.equal(result.error.stage, stage); assert.equal(result.error.code, code); return result;
}
failed('arguments-required', [], 'request', 'COMPARE_PLAN_ARGUMENTS_REQUIRED');
failed('missing-plan', [sources.before.path, sources.changed.path, join(output, 'absent-plan.json'), absent], 'plan', 'ENOENT');
failed('missing-before', [join(output, 'absent.gds'), sources.changed.path, plans.focused.path, absent], 'before', 'ENOENT');
failed('missing-after', [sources.before.path, join(output, 'absent.gds'), plans.focused.path, absent], 'after', 'ENOENT');
const malformed = join(output, 'malformed.gds'); writeFileSync(malformed, Buffer.from(vectors.malformedSourceHex, 'hex'), { flag: 'wx' });
failed('malformed-before', [malformed, sources.changed.path, plans.focused.path, absent], 'before', 'GDS_PARSE_ERROR');
failed('malformed-after', [sources.before.path, malformed, plans.focused.path, absent], 'after', 'GDS_PARSE_ERROR');
const invalid = join(output, 'invalid-plan.json'); writeFileSync(invalid, JSON.stringify(vectors.invalidPlan), { flag: 'wx' });
failed('plan-validates-before-source-parsing', [malformed, malformed, invalid, absent], 'plan', 'INVALID_REVIEW_PLAN');
const invalidUTF8 = join(output, 'invalid-utf8-plan-input.json'); writeFileSync(invalidUTF8, Buffer.from([255]), { flag: 'wx' });
failed('invalid-utf8-plan', [sources.before.path, sources.changed.path, invalidUTF8, absent], 'plan', 'INVALID_REVIEW_PLAN');
assert.equal(existsSync(absent), false);
const saved = readFileSync(produced.regression);
failed('existing-report-refused', [sources.before.path, sources.changed.path, plans.focused.path, produced.regression], 'output', 'EEXIST');
assert.deepEqual(readFileSync(produced.regression), saved);
for (const [name, input] of [['before', sources.before], ['after', sources.changed], ['plan', plans.focused]]) {
  failed(name + '-overwrite-refused', [sources.before.path, sources.changed.path, plans.focused.path, input.path], 'output', 'EEXIST');
  assert.deepEqual(readFileSync(input.path), input.bytes);
}
failed('missing-output-parent', [sources.before.path, sources.changed.path, plans.focused.path, join(output, 'absent-directory', 'report.json')], 'output', 'ENOENT');
for (const operand of ['before', 'after', 'plan']) {
  const inputs = {};
  for (const [key, input] of [['before', sources.before], ['after', sources.changed], ['plan', plans.focused]]) {
    const path = join(output, 'stale-' + operand + '-' + key); writeFileSync(path, input.bytes, { flag: 'wx' }); inputs[key] = path;
  }
  const path = join(output, 'stale-' + operand + '-report.json');
  run('stale-' + operand + '-produce', 'tools/compare_plan.mjs', [inputs.before, inputs.after, inputs.plan, path], 3);
  writeFileSync(inputs[operand], operand === 'before' ? sources.changed.bytes : operand === 'after' ? sources.before.bytes : Buffer.concat([plans.focused.bytes, Buffer.from('\n')]));
  assert.deepEqual(run('stale-' + operand + '-reject', 'examples/read_comparison_plan.mjs', [path], 2),
    { error: { stage: 'receiver', message: `${operand} bytes changed since this comparison.` } });
}
for (const [name, bytes] of Object.entries(original)) assert.deepEqual(readFileSync(join(root, name)), bytes);
for (const input of [...Object.values(sources), ...Object.values(plans)]) assert.deepEqual(readFileSync(input.path), input.bytes);
const manifest = { schema: 'gdsii-comparison-plan-acceptance-v1', status: 'PASS', commit: process.env.GITHUB_SHA ?? null, cases, reports,
  vectorsSHA256: sha256(vectorBytes), sourceIdentities: Object.fromEntries(Object.entries(original).map(([name, bytes]) => [name, { bytes: bytes.length, sha256: sha256(bytes) }])),
  originalInputs: Object.fromEntries(Object.entries(sources).map(([name, input]) => [name, { bytes: input.bytes.length, sha256: sha256(input.bytes) }])),
  planInputs: Object.fromEntries(Object.entries(plans).map(([name, input]) => [name, { bytes: input.bytes.length, sha256: sha256(input.bytes) }])),
  bothSideErrorsPreserved: true, retainedIssuesCanHaveNoNewIssues: true, incompletePrecedesFindings: true,
  staleAllThreeOperandsRejected: true, originalInputsUnchanged: true, publicInterfaceChanged: false, externalAdoptionClaimed: false };
const engine = manifest.sourceIdentities['_build/js/debug/build/cmd/inspect/inspect.js'];
const notice = { schema: manifest.schema, status: 'PASS', commit: manifest.commit ?? '0'.repeat(40), caseCount: cases.length,
  casesSHA256: sha256(JSON.stringify(cases)), exitCounts: Object.fromEntries([0, 2, 3, 4].map(code => [code, cases.filter(c => c.exit === code).length])),
  reportCount: reports.length, reportSemanticsSHA256: sha256(JSON.stringify(reports.map(({ bytes, sha256, ...semantic }) => semantic))),
  reports: reports.map(r => [r.case, r.bytes, r.sha256]), vectorsSHA256: manifest.vectorsSHA256,
  engineBytes: engine.bytes, engineSHA256: engine.sha256, originalInputs: manifest.originalInputs, planInputs: manifest.planInputs,
  bothSideErrorsPreserved: true, incompletePrecedesFindings: true, staleAllThreeOperandsRejected: true, externalAdoptionClaimed: false };
const noticeText = JSON.stringify(notice); assert.ok(Buffer.byteLength(noticeText) < 3900);
writeFileSync(join(output, 'checks-notice.json'), noticeText + '\n', { flag: 'wx' });
writeFileSync(join(output, 'acceptance.json'), JSON.stringify(manifest, null, 2) + '\n', { flag: 'wx' });
process.stdout.write(JSON.stringify(manifest) + '\n');
if (process.env.GITHUB_ACTIONS === 'true') process.stdout.write('::notice title=Comparison plan acceptance::' + noticeText.replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A') + '\n');
