// Real saved-plan handoff acceptance with independently authored Stream bytes.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/review-plan'));
assert.equal(existsSync(output), false, 'Retain prior evidence; choose a fresh output directory.');
mkdirSync(output, { recursive: true });
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const wrapperPath = join(root, 'tools/inspect.mjs');
const enginePath = join(root, '_build/js/debug/build/cmd/inspect/inspect.js');
const originalWrapper = readFileSync(wrapperPath);
const originalEngine = readFileSync(enginePath);
const exampleSource = readFileSync(join(root, 'examples/review-plan.gds'));
const examplePlan = readFileSync(join(root, 'examples/review-plan.json'));

// Big-endian records and geometry are declared here, without a product writer.
const rec = (kind, type = 0, payload = Buffer.alloc(0)) => {
  const header = Buffer.alloc(4);
  header.writeUInt16BE(payload.length + 4); header[2] = kind; header[3] = type;
  return Buffer.concat([header, payload]);
};
const i16 = values => { const b = Buffer.alloc(values.length * 2); values.forEach((n, i) => b.writeInt16BE(n, 2 * i)); return b; };
const i32 = values => { const b = Buffer.alloc(values.length * 4); values.forEach((n, i) => b.writeInt32BE(n, 4 * i)); return b; };
function originalStream(secondRight = 12) {
  const date = i16([126, 10, 29, 0, 0, 0, 126, 10, 29, 0, 0, 0]);
  const rectangles = [[7, 2, 0, 0, 4, 8], [7, 2, 10, 0, secondRight, 8], [8, 0, 20, 0, 24, 8], [9, 1, 30, 0, 32, 8]];
  const shapes = rectangles.flatMap(([layer, type, x0, y0, x1, y1]) => [rec(8), rec(13, 2, i16([layer])), rec(14, 2, i16([type])),
    rec(16, 3, i32([x0, y0, x1, y0, x1, y1, x0, y1, x0, y0])), rec(17)]);
  return Buffer.concat([rec(0, 2, i16([600])), rec(1, 2, date), rec(2, 6, Buffer.from('REVIEW')),
    rec(3, 5, Buffer.from('41100000000000004110000000000000', 'hex')), rec(5, 2, date), rec(6, 6, Buffer.from('top\0')),
    ...shapes, rec(9), rec(13, 2, i16([9])), rec(14, 2, i16([1])), rec(15, 3, i32([2])),
    rec(16, 3, i32([30, 12, 38, 12])), rec(17), rec(7), rec(4)]);
}
assert.deepEqual(exampleSource, originalStream());
assert.equal(exampleSource.length, 412);
const metal7 = { id: 'metal7', layer: 7, datatype: 2, min_width: 3, min_spacing: 5 };
const metal8 = { id: 'metal8', layer: 8, datatype: 0, min_width: 3, min_spacing: 5 };
const pathLayer = { id: 'path-layer', layer: 9, datatype: 1, min_width: 0, min_spacing: 0 };
const unmapped = { id: 'unmapped', layer: 10, datatype: 0, min_width: 3, min_spacing: 5 };
const planOf = profiles => ({ schema: 'gdsii-rectangle-review-plan-v1', cell: 'top', profiles });
const mixedPlan = planOf([metal7, metal8, pathLayer, unmapped]);
assert.deepEqual(JSON.parse(examplePlan), mixedPlan);
const cases = [];

function invoke(name, args, expectedExit, wrapper = wrapperPath) {
  const result = spawnSync(process.execPath, [wrapper, '--review-plan', ...args], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  writeFileSync(join(output, `${name}.json`), JSON.stringify({ name, command: [process.execPath, wrapper, '--review-plan', ...args],
    expectedExit, status: result.status, stdout: result.stdout, stderr: result.stderr, error: result.error?.message }, null, 2), { flag: 'wx' });
  assert.ifError(result.error);
  assert.equal(result.status, expectedExit, name);
  assert.equal(result.stderr, '', name);
  const response = JSON.parse(result.stdout);
  cases.push({ name, exit: result.status, status: response.review?.status ?? response.error?.code });
  return response;
}
function snapshots(response, sourceFile, source, planFile, plan) {
  assert.equal(response.schema, 'gdsii-rectangle-review-result-v1');
  assert.deepEqual(response.source, { path: resolve(sourceFile), bytes: source.length, sha256: sha256(source) });
  assert.deepEqual(response.plan, { path: resolve(planFile), bytes: plan.length, sha256: sha256(plan) });
}
function inspect(name, plan, expectedExit, source = exampleSource) {
  const folder = join(output, name);
  mkdirSync(folder);
  const sourceFile = join(folder, '原始 图纸.gds');
  const planFile = join(folder, '检查 计划.json');
  const bytes = Buffer.isBuffer(plan) ? plan : Buffer.from(JSON.stringify(plan));
  writeFileSync(sourceFile, source, { flag: 'wx' });
  writeFileSync(planFile, bytes, { flag: 'wx' });
  const response = invoke(name, [sourceFile, planFile], expectedExit);
  assert.deepEqual(readFileSync(sourceFile), source);
  assert.deepEqual(readFileSync(planFile), bytes);
  if (response.schema) snapshots(response, sourceFile, source, planFile, bytes);
  return response;
}
function reviewShape(response, profiles, status, counts, unchecked) {
  assert.equal(response.error, undefined);
  const review = response.review;
  assert.equal(review.cell, 'top');
  assert.equal(review.status, status);
  assert.deepEqual(review.profiles, profiles);
  assert.deepEqual(review.results.map(item => item.id), profiles.map(item => item.id));
  assert.deepEqual(review.counts, counts);
  assert.deepEqual(review.coverage, { complete: unchecked.length === 0, unchecked_profiles: unchecked });
  assert.equal(Object.values(counts).reduce((a, b) => a + b, 0), profiles.length);
  return review;
}
const mixedCounts = { passed: 1, failed: 1, incomplete: 2, errors: 0 };
function mixedExpectations(response) {
  const review = reviewShape(response, mixedPlan.profiles, 'Incomplete', mixedCounts, ['path-layer', 'unmapped']);
  assert.deepEqual(review.results.map(item => item.preflight.status), ['ViolationsFound', 'RectanglesClear', 'IncompleteGeometry', 'EmptySelection']);
  assert.deepEqual(review.results.map(item => item.preflight.checked_rectangles), [2, 1, 1, 0]);
  assert.deepEqual(review.results.map(item => item.preflight.selected_shapes), [2, 1, 2, 0]);
  assert.deepEqual(review.results[0].preflight.issues, [{ rule: 'Width', rectangles: [
    { min_x: 10, min_y: 0, max_x: 12, max_y: 8, source: '/top:1' }], required: 3, measured: 2, shortfall: 1 }]);
  assert.equal(review.results[0].preflight.dbu_in_meters, 1);
  assert.deepEqual(review.results[1].preflight.issues, []);
  assert.deepEqual(review.results[2].preflight.skipped.map(item => item.source), ['/top:4']);
  assert.match(review.results[2].preflight.skipped[0].reason, /^GeometrySkipped:/);
  assert.deepEqual(review.results[2].preflight.issues, []);
  assert.deepEqual(review.results[3].preflight.issues, []);
  return review;
}

const example = invoke('runnable-example', [join(root, 'examples/review-plan.gds'), join(root, 'examples/review-plan.json')], 4);
snapshots(example, join(root, 'examples/review-plan.gds'), exampleSource, join(root, 'examples/review-plan.json'), examplePlan);
assert.equal(mixedExpectations(example).budget, 100000);
// Same configuration under distinct IDs and arbitrary JSON key order is valid.
const repeated = { min_spacing: 5, datatype: 0, id: '金属八 / 再検', min_width: 3, layer: 8 };
reviewShape(inspect('all-clear-distinct-labels', planOf([metal8, repeated]), 0), [metal8, repeated], 'Passed',
  { passed: 2, failed: 0, incomplete: 0, errors: 0 }, []);
reviewShape(inspect('covered-violations', planOf([metal7]), 3), [metal7], 'IssuesFound',
  { passed: 0, failed: 1, incomplete: 0, errors: 0 }, []);
const partial = { ...pathLayer, min_width: 3 };
const partialReview = reviewShape(inspect('violations-and-skips', planOf([partial]), 4), [partial], 'Incomplete',
  { passed: 0, failed: 1, incomplete: 0, errors: 0 }, ['path-layer']);
assert.equal(partialReview.results[0].preflight.status, 'ViolationsFound');
assert.equal(partialReview.results[0].preflight.issues[0].measured, 2);
assert.equal(partialReview.results[0].preflight.skipped.length, 1);
reviewShape(inspect('only-empty-selection', planOf([unmapped]), 4), [unmapped], 'Incomplete',
  { passed: 0, failed: 0, incomplete: 1, errors: 0 }, ['unmapped']);
const missing = inspect('per-profile-errors', { ...mixedPlan, cell: 'missing' }, 2).review;
assert.equal(missing.status, 'ErrorsFound');
assert.deepEqual(missing.counts, { passed: 0, failed: 0, incomplete: 0, errors: 4 });
assert.deepEqual(missing.coverage, { complete: false, unchecked_profiles: mixedPlan.profiles.map(p => p.id) });
assert.deepEqual(missing.results, mixedPlan.profiles.map(p => ({ id: p.id, error: ['MissingCell', 'missing'] })));
// One visited cell plus five emitted shapes: each profile needs exactly six.
assert.equal(mixedExpectations(inspect('fresh-budget-exact', { ...mixedPlan, budget: 6 }, 4)).budget, 6);
const short = reviewShape(inspect('budget-too-small', { ...mixedPlan, budget: 5 }, 2), mixedPlan.profiles, 'ErrorsFound',
  { passed: 0, failed: 0, incomplete: 0, errors: 4 }, mixedPlan.profiles.map(p => p.id));
assert.deepEqual(short.results, mixedPlan.profiles.map(p => ({ id: p.id, error: ['ExpansionLimit', 5] })));

const invalidPlans = [
  ['empty-plan', planOf([])], ['empty-cell', { ...mixedPlan, cell: '' }],
  ['empty-id', planOf([{ ...metal7, id: '' }])], ['duplicate-ids', planOf([metal7, metal7])],
  ['unknown-plan-field', { ...mixedPlan, typo: true }],
  ['unknown-profile-field', planOf([{ ...metal7, min_spcing: 5 }])],
  ['wrong-schema', { ...mixedPlan, schema: 'other-v1' }], ['null-plan', null],
  ['fractional-rule', planOf([{ ...metal7, min_spacing: 0.5 }])],
  ['overflow-rule', planOf([{ ...metal7, min_width: 2147483648 }])],
  ['missing-selector', planOf([{ id: 'missing', layer: 7, min_width: 3, min_spacing: 5 }])],
  ['invalid-budget', { ...mixedPlan, budget: 0 }],
];
for (const [name, plan] of invalidPlans) {
  const response = inspect(name, plan, 2);
  assert.equal(response.error.stage, 'plan');
  assert.equal(response.error.code, 'INVALID_REVIEW_PLAN');
  assert.equal(response.review, undefined);
}
// An invalid last item wins even over malformed source: no partial evaluation.
const atomic = inspect('invalid-last-profile-atomic', planOf([metal7, { ...metal8, min_width: -1 }]), 2, Buffer.from([0]));
assert.equal(atomic.error.stage, 'plan');
assert.equal(atomic.review, undefined);
const maxSelector = { ...unmapped, layer: 2147483647, datatype: 2147483647 };
reviewShape(inspect('int32-selector-not-uint16', planOf([maxSelector]), 4), [maxSelector], 'Incomplete',
  { passed: 0, failed: 0, incomplete: 1, errors: 0 }, ['unmapped']);
const badSource = inspect('malformed-source', mixedPlan, 2, Buffer.from([0]));
assert.equal(badSource.error.stage, 'source');
assert.equal(badSource.error.code, 'GDS_PARSE_ERROR');
assert.equal(badSource.review, undefined);
const bom = Buffer.from([0xef, 0xbb, 0xbf]);
const unicodePlan = planOf([repeated]);
reviewShape(inspect('utf8-bom-unicode', Buffer.concat([bom, Buffer.from(JSON.stringify(unicodePlan))]), 0), [repeated], 'Passed',
  { passed: 1, failed: 0, incomplete: 0, errors: 0 }, []);
for (const [name, bytes] of [['double-bom', Buffer.concat([bom, bom, examplePlan])], ['invalid-utf8', Buffer.from([0xc3, 0x28])], ['invalid-json', Buffer.from('{')]]) {
  const response = inspect(name, bytes, 2);
  assert.equal(response.error.stage, 'plan');
  assert.equal(response.error.code, 'INVALID_REVIEW_PLAN');
  assert.equal(response.review, undefined);
}
assert.equal(invoke('missing-source-file', [join(output, 'absent.gds'), join(root, 'examples/review-plan.json')], 2).error.stage, 'input');
assert.equal(invoke('missing-plan-file', [join(root, 'examples/review-plan.gds'), join(output, 'absent.json')], 2).error.stage, 'plan');
assert.equal(invoke('missing-plan-argument', [join(root, 'examples/review-plan.gds')], 2).error.code, 'REVIEW_INPUTS_REQUIRED');

// External disk replacement after both snapshots. Forward the untouched request
// to a byte-identical real compiled engine, with no production test hook.
const replacementSource = originalStream(14);
const replacementPlan = planOf([{ ...metal7, id: 'replacement' }]);
reviewShape(inspect('replacement-is-valid', replacementPlan, 0, replacementSource), replacementPlan.profiles, 'Passed',
  { passed: 1, failed: 0, incomplete: 0, errors: 0 }, []);
const isolated = join(output, 'snapshot-replacement');
const copiedWrapper = join(isolated, 'tools/inspect.mjs');
const actor = join(isolated, '_build/js/debug/build/cmd/inspect/inspect.js');
mkdirSync(dirname(copiedWrapper), { recursive: true });
mkdirSync(dirname(actor), { recursive: true });
writeFileSync(copiedWrapper, originalWrapper, { flag: 'wx' });
const realEngine = join(dirname(actor), 'real-inspect.cjs');
writeFileSync(realEngine, originalEngine, { flag: 'wx' });
const sourceFile = join(isolated, 'source.gds');
const planFile = join(isolated, 'plan.json');
const trace = join(isolated, 'forwarded-request.json');
writeFileSync(sourceFile, exampleSource, { flag: 'wx' });
writeFileSync(planFile, examplePlan, { flag: 'wx' });
writeFileSync(actor, `const fs = require('node:fs');
const input = fs.readFileSync(0, 'utf8');
fs.writeFileSync(${JSON.stringify(trace)}, input);
fs.writeFileSync(${JSON.stringify(sourceFile)}, Buffer.from(${JSON.stringify(replacementSource.toString('hex'))}, 'hex'));
fs.writeFileSync(${JSON.stringify(planFile)}, ${JSON.stringify(JSON.stringify(replacementPlan))});
const result = require('node:child_process').spawnSync(process.execPath, [${JSON.stringify(realEngine)}], {input, encoding:'utf8', maxBuffer:64*1024*1024});
if (result.error) throw result.error;
process.stdout.write(result.stdout); process.stderr.write(result.stderr); process.exitCode = result.status;
`, { flag: 'wx' });
const bound = invoke('snapshot-bound-despite-disk-replacement', [sourceFile, planFile], 4, copiedWrapper);
mixedExpectations(bound);
snapshots(bound, sourceFile, exampleSource, planFile, examplePlan);
assert.deepEqual(JSON.parse(readFileSync(trace)), { mode: 'review-plan', hex: exampleSource.toString('hex'), plan: mixedPlan });
assert.deepEqual(readFileSync(sourceFile), replacementSource);
assert.deepEqual(JSON.parse(readFileSync(planFile)), replacementPlan);
assert.deepEqual(readFileSync(realEngine), originalEngine);
assert.deepEqual(readFileSync(copiedWrapper), originalWrapper);
assert.deepEqual(readFileSync(wrapperPath), originalWrapper);
assert.deepEqual(readFileSync(enginePath), originalEngine);
assert.deepEqual(readFileSync(join(root, 'examples/review-plan.gds')), exampleSource);
assert.deepEqual(readFileSync(join(root, 'examples/review-plan.json')), examplePlan);

const git = spawnSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' });
assert.ifError(git.error); assert.equal(git.status, 0);
const identity = { schema: 'gdsii-review-plan-acceptance-v1', status: 'PASS', commit: git.stdout.trim(), node: process.version,
  wrapperSHA256: sha256(originalWrapper), engineSHA256: sha256(originalEngine), suiteSHA256: sha256(readFileSync(fileURLToPath(import.meta.url))),
  exampleSource: { bytes: exampleSource.length, sha256: sha256(exampleSource) }, examplePlan: { bytes: examplePlan.length, sha256: sha256(examplePlan) },
  cases, snapshotHandoff: { untouchedRequestForwardedToRealEngine: true, copiedEngineSHA256: sha256(readFileSync(realEngine)),
    originalSourceSHA256: bound.source.sha256, replacementSourceSHA256: sha256(replacementSource),
    originalPlanSHA256: bound.plan.sha256, replacementPlanSHA256: sha256(readFileSync(planFile)), checkoutInputsUnchanged: true } };
writeFileSync(join(output, 'acceptance.json'), JSON.stringify(identity, null, 2), { flag: 'wx' });
console.log(JSON.stringify(identity));
if (process.env.GITHUB_ACTIONS === 'true') {
  const message = JSON.stringify(identity).replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A');
  console.log(`::notice title=Review plan acceptance::${message}`);
}
