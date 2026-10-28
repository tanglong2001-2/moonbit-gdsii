// Real process/file acceptance for the existing two-file comparison wrapper.
// Fault engines below are external protocol failures, not geometry oracles.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = resolve(process.argv[2] ?? join(root, '_build/ci/wrapper-failures'));
assert.equal(existsSync(output), false, 'Choose a fresh output directory; retain earlier evidence.');
mkdirSync(output, { recursive: true });
const sha256 = data => createHash('sha256').update(data).digest('hex');
const originalWrapper = readFileSync(join(root, 'tools/inspect.mjs'));
const originalEngine = readFileSync(join(root, '_build/js/debug/build/cmd/inspect/inspect.js'));

// Complete manually declared original stream bytes. No library writer or engine
// output constructs the expected files; the second rectangle narrows 4 -> 2 DBU.
const date = '007e000a001c000000000000007e000a001c000000000000';
const header = '000600020258' + '001c0102' + date + '000c0206415554484f524544' +
  '0014030541100000000000004110000000000000' + '001c0502' + date + '00080606746f7000';
const first = '0004080000060d02000700060e020002002c1003' +
  '00000000000000000000000400000000000000040000000800000000000000080000000000000000' + '00041100';
const secondPrefix = '0004080000060d02000700060e020002002c1003';
const secondBefore = '0000000a000000000000000e000000000000000e000000080000000a000000080000000a00000000';
const secondAfter = '0000000a000000000000000c000000000000000c000000080000000a000000080000000a00000000';
const before = Buffer.from(header + first + secondPrefix + secondBefore + '000411000004070000040400', 'hex');
const after = Buffer.from(header + first + secondPrefix + secondAfter + '000411000004070000040400', 'hex');
assert.equal(before.length, 238);
assert.equal(after.length, 238);
const input = join(output, '原始 修订');
mkdirSync(input);
const beforeFile = join(input, 'before.gds');
const afterFile = join(input, 'after.gds');
writeFileSync(beforeFile, before, { flag: 'wx' });
writeFileSync(afterFile, after, { flag: 'wx' });
const expectedRequest = { hex: before.toString('hex'), cell: 'top', layer: 7, datatype: 2, width: 3, spacing: 5,
  mode: 'compare', after_hex: after.toString('hex') };
const expectedComparison = { comparison: { cell: 'top', layer: 7, datatype: 2, min_width: 3, min_spacing: 5,
  dbu_in_meters: 1, status: 'NewIssuesFound', before_status: 'RectanglesClear', after_status: 'ViolationsFound',
  before_checked_rectangles: 2, after_checked_rectangles: 2, before_skipped: [], after_skipped: [],
  introduced: [{ rule: 'Width', rectangles: [{ min_x: 10, min_y: 0, max_x: 12, max_y: 8, source: '/top:1' }],
    required: 3, measured: 2, shortfall: 1 }], removed: [], retained: 0 } };
const misleading = JSON.stringify({ comparison: { ...expectedComparison.comparison, status: 'NoNewIssues',
  after_status: 'RectanglesClear', introduced: [] } }) + '\n';
const truncated = '{"comparison":{"status":"NoNewIssues"';
const diagnostic = 'controlled comparison backend failure\n';
const cases = [];

function filesIntact() {
  assert.deepEqual(readFileSync(beforeFile), before);
  assert.deepEqual(readFileSync(afterFile), after);
  assert.deepEqual(readdirSync(input).sort(), ['after.gds', 'before.gds']);
  assert.deepEqual(readFileSync(join(root, 'tools/inspect.mjs')), originalWrapper);
  assert.deepEqual(readFileSync(join(root, '_build/js/debug/build/cmd/inspect/inspect.js')), originalEngine);
}

function runCase(name, fault, expectedExit, expectedResponse) {
  const workspace = join(output, name);
  const wrapper = join(workspace, 'tools/inspect.mjs');
  const engine = join(workspace, '_build/js/debug/build/cmd/inspect/inspect.js');
  mkdirSync(dirname(wrapper), { recursive: true });
  mkdirSync(dirname(engine), { recursive: true });
  writeFileSync(wrapper, originalWrapper, { flag: 'wx' });
  assert.deepEqual(readFileSync(wrapper), originalWrapper);
  const trace = join(workspace, 'engine-request.json');
  if (fault) {
    const stdout = fault === 'exit' ? misleading : truncated;
    const stderr = fault === 'exit' ? diagnostic : '';
    const status = fault === 'exit' ? 23 : 0;
    const source = `const fs = require('node:fs');\n` +
      `const request = JSON.parse(fs.readFileSync(0, 'utf8'));\n` +
      `fs.writeFileSync(1, ${JSON.stringify(stdout)});\n` +
      `fs.writeFileSync(2, ${JSON.stringify(stderr)});\n` +
      `fs.writeFileSync(${JSON.stringify(trace)}, JSON.stringify({request, stdoutWritten: ${JSON.stringify(stdout)}, stderrWritten: ${JSON.stringify(stderr)}}));\n` +
      `process.exit(${status});\n`;
    writeFileSync(engine, source, { flag: 'wx' });
  } else {
    writeFileSync(engine, originalEngine, { flag: 'wx' });
    assert.deepEqual(readFileSync(engine), originalEngine);
  }
  const args = [wrapper, '--compare', beforeFile, afterFile, 'top', '7', '2', '3', '5'];
  const result = spawnSync(process.execPath, args, { cwd: workspace, encoding: 'utf8', timeout: 30000, maxBuffer: 1024 * 1024 });
  writeFileSync(join(output, `${name}.json`), JSON.stringify({ name, command: [process.execPath, ...args],
    status: result.status, signal: result.signal, stdout: result.stdout, stderr: result.stderr,
    error: result.error ? { code: result.error.code, message: result.error.message } : null }, null, 2));
  assert.ifError(result.error);
  assert.equal(result.status, expectedExit, name);
  assert.equal(result.signal, null, name);
  assert.equal(result.stderr, '', name);
  assert.ok(result.stdout.endsWith('\n'), name);
  const response = JSON.parse(result.stdout); // Any leaked partial/additional stdout fails.
  assert.deepEqual(response, expectedResponse, name);
  if (fault) {
    const observed = JSON.parse(readFileSync(trace, 'utf8'));
    assert.deepEqual(observed.request, expectedRequest, name);
    assert.equal(observed.stdoutWritten, fault === 'exit' ? misleading : truncated);
    assert.equal(observed.stderrWritten, fault === 'exit' ? diagnostic : '');
  }
  filesIntact();
  cases.push({ name, outerExit: result.status, stderrEmpty: true, inputFilesByteExact: true });
}

runCase('real-compiled-control', null, 3, expectedComparison);
runCase('nonzero-child-after-misleading-json', 'exit', 2, { error: { stage: 'engine', code: 'ENGINE_EXIT',
  message: 'File consumer did not complete successfully.', status: 23, signal: null, diagnostic } });
runCase('successful-child-with-truncated-json', 'truncated', 2, { error: { stage: 'engine', code: 'ENGINE_RESPONSE_INVALID',
  message: 'File consumer did not return a JSON object.' } });
const summary = { status: 'PASS', nodeVersion: process.versions.node, cases,
  wrapperSha256: sha256(originalWrapper), realEngineSha256: sha256(originalEngine),
  originalGds: { before: { bytes: before.length, sha256: sha256(before) }, after: { bytes: after.length, sha256: sha256(after) } },
  legitimateComparison: expectedComparison, exactTwoFileRequestsTraced: 2,
  originalInputsAndArtifactsUnchanged: true, productTestHookAdded: false,
  faultPayloadsAreNotNumericalOracles: true };
writeFileSync(join(output, 'summary.json'), JSON.stringify(summary, null, 2));
if (process.env.GITHUB_ACTIONS === 'true') {
  const notice = { schema: 'gdsii-wrapper-failure-acceptance-v1', commit: process.env.GITHUB_SHA,
    status: summary.status, nodeVersion: summary.nodeVersion, wrapperSha256: summary.wrapperSha256,
    realEngineSha256: summary.realEngineSha256, originalGds: summary.originalGds,
    cases: summary.cases, exactTwoFileRequestsTraced: 2, originalInputsAndArtifactsUnchanged: true };
  console.log('::notice title=Comparison wrapper acceptance::' + JSON.stringify(notice).replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A'));
}
console.log(JSON.stringify(summary));
