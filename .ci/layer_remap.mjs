import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, resolve, dirname } from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/layer-remap'));
assert.equal(existsSync(output), false, 'Retain earlier evidence; select a fresh output directory.'); mkdirSync(output, { recursive: true });
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const vectorsBytes = readFileSync(join(root, 'testdata/layer-remap-vectors.json'));
assert.equal(sha256(vectorsBytes), '0246a1616e871141123260cfcf20b4d56c15efecaf34586f4d9c9479e30d912a');
const vectors = JSON.parse(vectorsBytes), sources = {};
for (const [name, hex] of Object.entries(vectors.sources)) {
  const path = join(output, 'source-' + name + '.gds'), bytes = Buffer.from(hex, 'hex');
  writeFileSync(path, bytes, { flag: 'wx' }); sources[name] = { path, bytes };
}
assert.deepEqual(readFileSync(join(root, 'examples/layer-remap-source.gds')), sources.mixed.bytes);
assert.deepEqual(JSON.parse(readFileSync(join(root, 'examples/layer-remap.json'))), vectors.cases[0].plan);
const names = ['layer_remap.mbt', 'layer_remap_test.mbt', 'cmd/inspect/layer_remap.mbt', 'cmd/inspect/main.mbt',
  'tools/remap_layers.mjs', 'examples/read_remapped_layers.mjs', '.ci/layer_remap.mjs', 'testdata/layer-remap-vectors.json',
  'examples/layer-remap-source.gds', 'examples/layer-remap.json', '_build/js/debug/build/cmd/inspect/inspect.js'];
const original = Object.fromEntries(names.map(name => [name, readFileSync(join(root, name))]));
const fingerprint = (path, bytes) => ({ path, bytes: bytes.length, sha256: sha256(bytes) });
const cases = [], outputs = [], receipts = {};
function run(name, script, args, expectedExit) {
  const child = spawnSync(process.execPath, [script, ...args], { cwd: root, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  writeFileSync(join(output, 'process-' + name + '.json'), JSON.stringify({ name, command: [process.execPath, script, ...args], expectedExit,
    status: child.status, stdout: child.stdout, stderr: child.stderr, error: child.error?.message }, null, 2) + '\n', { flag: 'wx' });
  assert.ifError(child.error); assert.equal(child.status, expectedExit, name); assert.equal(child.stderr, '', name);
  cases.push({ name, exit: child.status }); return JSON.parse(child.stdout);
}
const producer = join(root, 'tools/remap_layers.mjs'), receiver = join(root, 'examples/read_remapped_layers.mjs');
function successful(test, id = test.id, planBytes = Buffer.from(JSON.stringify(test.plan) + '\n')) {
  const source = sources[test.source], planPath = join(output, id + '-map.json');
  const path = join(output, id + ' 图层 output.gds'), receiptPath = join(output, id + '-receipt.json');
  writeFileSync(planPath, planBytes, { flag: 'wx' });
  const receipt = run(id + '-produce', producer, [source.path, planPath, path], 0);
  const actual = readFileSync(path), expected = Buffer.from(test.expected_hex, 'hex');
  assert.deepEqual(actual, expected, id + ': complete independent binary output');
  assert.deepEqual(receipt, { schema: 'gdsii-layer-remap-file-v1', source: fingerprint(source.path, source.bytes), plan: fingerprint(planPath, planBytes),
    output: fingerprint(path, expected), changed_elements: test.expected_changed_elements, catalog: test.expected_catalog });
  writeFileSync(receiptPath, JSON.stringify(receipt, null, 2) + '\n', { flag: 'wx' });
  assert.deepEqual(run(id + '-receive', receiver, [receiptPath], 0), { schema: 'gdsii-layer-remap-received-v1', inputs_verified: true,
    changed_elements: test.expected_changed_elements, changed_records: test.expected_changed_records, changed_payload_offsets: test.expected_changed_payload_offsets,
    record_count: test.expected_record_count, padding_bytes: test.expected_padding_bytes,
    cells: test.expected_catalog.cells.map(c => c.name), elements: test.expected_elements });
  assert.deepEqual(run(id + '-catalog', join(root, 'tools/inspect.mjs'), ['--catalog', path], 0), { catalog: test.expected_catalog });
  outputs.push({ case: id, bytes: actual.length, sha256: sha256(actual), changedElements: test.expected_changed_elements, changedRecords: test.expected_changed_records,
    completeIndependentBytesEqual: true, completeCatalogueEqual: true, actualPhysicalRecipientPassed: true });
  receipts[id] = { path, receiptPath, receipt, planPath, planBytes };
}
for (const test of vectors.cases) successful(test);
successful(vectors.cases[0], 'utf8-bom', Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), Buffer.from(JSON.stringify(vectors.cases[0].plan))]));
const absentOutput = join(output, 'must-not-exist.gds');
function failed(name, args, stage, code, script = producer) {
  const value = run(name, script, args, 2); assert.equal(value.error.stage, stage, name); assert.equal(value.error.code, code, name); return value;
}
failed('arguments-required', [], 'request', 'LAYER_REMAP_ARGUMENTS_REQUIRED');
failed('missing-plan', [sources.mixed.path, join(output, 'absent-map.json'), absentOutput], 'plan', 'ENOENT');
failed('missing-source', [join(output, 'absent-source.gds'), receipts.swap.planPath, absentOutput], 'source', 'ENOENT');
const badSource = join(output, 'malformed-source.gds'); writeFileSync(badSource, Buffer.from([0, 3, 0, 2]), { flag: 'wx' });
failed('malformed-source', [badSource, receipts.swap.planPath, absentOutput], 'source', 'GDS_PARSE_ERROR');
const first = vectors.cases[0].plan.mappings[0];
const plan = mappings => ({ schema: 'gdsii-layer-remap-v1', mappings });
const invalid = [
  ['wrong-schema', { schema: 'other', mappings: [] }], ['null-plan', null], ['array-plan', []],
  ['missing-mappings', { schema: 'gdsii-layer-remap-v1' }], ['extra-plan-field', { ...plan([]), extra: true }],
  ['null-mappings', plan(null)], ['missing-rule-field', plan([{ from_layer: 1 }])],
  ['extra-rule-field', plan([{ ...first, extra: 0 }])], ['fraction', plan([{ ...first, to_type: 1.5 }])],
  ['negative', plan([{ ...first, from_type: -1 }])], ['overflow', plan([{ ...first, to_layer: 65536 }])],
  ['string-value', plan([{ ...first, to_type: '8' }])], ['duplicate-identical', plan([first, first])],
  ['duplicate-unmatched', plan([{ from_layer: 60000, from_type: 60001, to_layer: 1, to_type: 2 }, { from_layer: 60000, from_type: 60001, to_layer: 9, to_type: 10 }])],
  ['invalid-last-atomic', plan([first, { from_layer: 60000, from_type: 60001, to_layer: 1, to_type: 65536 }])],
];
for (const [name, value] of invalid) {
  const path = join(output, 'bad-plan-' + name + '.json'); writeFileSync(path, JSON.stringify(value), { flag: 'wx' });
  failed(name, [sources.mixed.path, path, absentOutput], 'plan', 'INVALID_LAYER_REMAP');
}
for (const [name, bytes] of [['invalid-json', Buffer.from('{')], ['invalid-utf8', Buffer.from([0xff])], ['double-bom', Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf, 0xef, 0xbb, 0xbf]), Buffer.from(JSON.stringify(plan([])))])]]) {
  const path = join(output, name + '-map.json'); writeFileSync(path, bytes, { flag: 'wx' });
  failed(name, [sources.mixed.path, path, absentOutput], 'plan', 'INVALID_LAYER_REMAP');
}
assert.equal(existsSync(absentOutput), false);
const saved = receipts.swap;
for (const [name, path] of [['existing-output', saved.path], ['source-path', sources.mixed.path], ['plan-path', saved.planPath]]) {
  const before = readFileSync(path); failed(name + '-refused', [sources.mixed.path, saved.planPath, path], 'output', 'EEXIST'); assert.deepEqual(readFileSync(path), before);
}
failed('missing-output-directory', [sources.mixed.path, saved.planPath, join(output, 'absent-directory', 'output.gds')], 'output', 'ENOENT');
for (const side of ['source', 'plan', 'output']) {
  const dir = join(output, 'stale-' + side); mkdirSync(dir);
  const sourcePath = join(dir, 'source.gds'), planPath = join(dir, 'map.json'), path = join(dir, 'output.gds'), receiptPath = join(dir, 'receipt.json');
  writeFileSync(sourcePath, sources.mixed.bytes, { flag: 'wx' }); writeFileSync(planPath, saved.planBytes, { flag: 'wx' });
  const receipt = run('stale-' + side + '-produce', producer, [sourcePath, planPath, path], 0); writeFileSync(receiptPath, JSON.stringify(receipt), { flag: 'wx' });
  const changed = side === 'source' ? sourcePath : side === 'plan' ? planPath : path;
  writeFileSync(changed, Buffer.concat([readFileSync(changed), Buffer.from([0])]));
  assert.deepEqual(run('stale-' + side + '-reject', receiver, [receiptPath], 2), { error: { stage: 'receiver', message: `${side} bytes changed since this receipt.` } });
}
// Isolated copies of this exact wrapper exercise child failure boundaries.
// The source checkout's real compiled engine is never replaced or modified.
for (const [name, body, code] of [
  ['nonzero-child', 'process.stdout.write(JSON.stringify({remapping:{changed_elements:0,catalog:{},bytes:[]}}));process.exitCode=23;', 'ENGINE_EXIT'],
  ['truncated-child', 'process.stdout.write("{");', 'ENGINE_RESPONSE_INVALID'],
]) {
  const dir = join(output, name), tool = join(dir, 'tools/remap_layers.mjs'), engine = join(dir, '_build/js/debug/build/cmd/inspect/inspect.js');
  mkdirSync(dirname(tool), { recursive: true }); mkdirSync(dirname(engine), { recursive: true });
  writeFileSync(tool, original['tools/remap_layers.mjs'], { flag: 'wx' }); writeFileSync(engine, body, { flag: 'wx' });
  const target = join(dir, 'must-not-exist.gds'); failed(name, [sources.mixed.path, saved.planPath, target], 'engine', code, tool); assert.equal(existsSync(target), false);
}
// A transparent child receives the real snapshot request, replaces the disk
// operands, then forwards the exact original request to the actual engine.
const snapshotDir = join(output, 'snapshot-bound'), snapshotSource = join(snapshotDir, 'source.gds'), snapshotPlan = join(snapshotDir, 'map.json');
const snapshotTool = join(snapshotDir, 'tools/remap_layers.mjs'), snapshotEngine = join(snapshotDir, '_build/js/debug/build/cmd/inspect/inspect.js');
mkdirSync(dirname(snapshotTool), { recursive: true }); mkdirSync(dirname(snapshotEngine), { recursive: true });
writeFileSync(snapshotSource, sources.mixed.bytes, { flag: 'wx' }); writeFileSync(snapshotPlan, saved.planBytes, { flag: 'wx' }); writeFileSync(snapshotTool, original['tools/remap_layers.mjs'], { flag: 'wx' });
const trace = join(snapshotDir, 'forwarded-request.json');
const bridge = `const fs=require('node:fs'),cp=require('node:child_process');const request=fs.readFileSync(0,'utf8');fs.writeFileSync(${JSON.stringify(trace)},request,{flag:'wx'});fs.writeFileSync(${JSON.stringify(snapshotSource)},Buffer.from(${JSON.stringify(vectors.sources.empty)},'hex'));fs.writeFileSync(${JSON.stringify(snapshotPlan)},JSON.stringify({schema:'gdsii-layer-remap-v1',mappings:[]}));const child=cp.spawnSync(process.execPath,[${JSON.stringify(join(root, '_build/js/debug/build/cmd/inspect/inspect.js'))}],{input:request,encoding:'utf8',maxBuffer:67108864});if(child.error)throw child.error;process.stdout.write(child.stdout);process.stderr.write(child.stderr);process.exitCode=child.status;`;
writeFileSync(snapshotEngine, bridge, { flag: 'wx' });
const snapshotOutput = join(snapshotDir, 'output.gds'), snapshotReceiptPath = join(snapshotDir, 'receipt.json');
const snapshotReceipt = run('snapshot-bound-produce', snapshotTool, [snapshotSource, snapshotPlan, snapshotOutput], 0);
assert.deepEqual(JSON.parse(readFileSync(trace)), { mode: 'remap-layers', hex: vectors.sources.mixed, mappings: vectors.cases[1].plan.mappings });
assert.deepEqual(readFileSync(snapshotOutput), Buffer.from(vectors.cases[1].expected_hex, 'hex'));
assert.deepEqual(snapshotReceipt.source, fingerprint(snapshotSource, sources.mixed.bytes)); assert.deepEqual(snapshotReceipt.plan, fingerprint(snapshotPlan, saved.planBytes));
writeFileSync(snapshotReceiptPath, JSON.stringify(snapshotReceipt), { flag: 'wx' });
assert.deepEqual(run('snapshot-bound-receiver-reject', receiver, [snapshotReceiptPath], 2), { error: { stage: 'receiver', message: 'source bytes changed since this receipt.' } });
for (const [name, bytes] of Object.entries(original)) assert.deepEqual(readFileSync(join(root, name)), bytes, name);
for (const input of Object.values(sources)) assert.deepEqual(readFileSync(input.path), input.bytes);
const manifest = { schema: 'gdsii-layer-remap-acceptance-v1', status: 'PASS', commit: process.env.GITHUB_SHA ?? null, cases, outputs,
  vectorsSHA256: sha256(vectorsBytes), sourceIdentities: Object.fromEntries(Object.entries(original).map(([name, bytes]) => [name, { bytes: bytes.length, sha256: sha256(bytes) }])),
  originalInputs: Object.fromEntries(Object.entries(sources).map(([name, input]) => [name, fingerprint(input.path, input.bytes)])),
  simultaneousNotCascading: true, rawNonTagBytesAndPaddingPreserved: true, allFiveKindsAndUint16Extremes: true, fullIndependentCataloguesEqual: true,
  currentPhysicalRecipientPassed: true, invalidWholeMapAtomic: true, staleThreeOperandsRejected: true, originalOperandsUnchanged: true,
  snapshotRequestForwardedToRealEngine: true, externalAdoptionClaimed: false };
const engine = manifest.sourceIdentities['_build/js/debug/build/cmd/inspect/inspect.js'];
const notice = { schema: manifest.schema, status: 'PASS', commit: manifest.commit ?? '0'.repeat(40), caseCount: cases.length, casesSHA256: sha256(JSON.stringify(cases)),
  exitCounts: Object.fromEntries([0, 2].map(code => [code, cases.filter(c => c.exit === code).length])), outputCount: outputs.length,
  outputSemanticsSHA256: sha256(JSON.stringify(outputs)), outputs: outputs.map(item => [item.case, item.bytes, item.sha256]), vectorsSHA256: manifest.vectorsSHA256,
  engineBytes: engine.bytes, engineSHA256: engine.sha256, originalInputs: Object.fromEntries(Object.entries(sources).map(([name, input]) => [name, { bytes: input.bytes.length, sha256: sha256(input.bytes) }])),
  simultaneousNotCascading: true, rawNonTagBytesAndPaddingPreserved: true, fullIndependentCataloguesEqual: true, staleThreeOperandsRejected: true,
  snapshotRequestForwardedToRealEngine: true, externalAdoptionClaimed: false };
const text = JSON.stringify(notice); assert.ok(Buffer.byteLength(text) < 3900);
writeFileSync(join(output, 'checks-notice.json'), text + '\n', { flag: 'wx' }); writeFileSync(join(output, 'acceptance.json'), JSON.stringify(manifest, null, 2) + '\n', { flag: 'wx' });
process.stdout.write(JSON.stringify(manifest) + '\n');
if (process.env.GITHUB_ACTIONS === 'true') process.stdout.write('::notice title=Layer remap acceptance::' + text.replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A') + '\n');
