import { closeSync, existsSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
function fail(stage, code, message, context = {}) {
  process.stdout.write(JSON.stringify({ error: { stage, code, message, ...context } }) + '\n'); process.exitCode = 2;
}
function main() {
  const args = process.argv.slice(2);
  if (args.length !== 3) return fail('request', 'DEFINITION_DIFF_ARGUMENTS_REQUIRED', 'Expected BEFORE.gds AFTER.gds OUTPUT.json.');
  const [beforePath, afterPath, outputPath] = args;
  const snapshots = {}; const inputs = {};
  for (const [side, path] of [['before', beforePath], ['after', afterPath]]) {
    try { inputs[side] = readFileSync(path); }
    catch (error) { return fail(side, error.code ?? 'INPUT_READ_FAILED', error.message, { path: resolve(path) }); }
    snapshots[side] = { path: resolve(path), bytes: inputs[side].length, sha256: sha256(inputs[side]) };
  }
  const engine = resolve(root, '_build/js/debug/build/cmd/inspect/inspect.js');
  if (!existsSync(engine)) return fail('build', 'BUILD_UNAVAILABLE', 'Run moon build --target js from the project directory.', { path: engine });
  const child = spawnSync(process.execPath, [engine], { input: JSON.stringify({ mode: 'definition-diff',
    hex: inputs.before.toString('hex'), after_hex: inputs.after.toString('hex') }), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (child.error) return fail('engine', child.error.code ?? 'ENGINE_START_FAILED', child.error.message);
  if (child.status !== 0) return fail('engine', 'ENGINE_EXIT', 'Raw definition engine failed.', { status: child.status, signal: child.signal, diagnostic: child.stderr ?? '' });
  let response;
  try { response = JSON.parse(child.stdout); }
  catch { return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Definition engine did not return JSON.'); }
  if (!response || typeof response !== 'object' || Array.isArray(response)) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Definition engine did not return an object.');
  if (Object.hasOwn(response, 'error')) { process.stdout.write(JSON.stringify({ ...response, ...snapshots }) + '\n'); process.exitCode = 2; return; }
  const diff = response.definition_diff;
  const statuses = ['DefinitionAdded', 'DefinitionRemoved', 'DefinitionChanged', 'DefinitionUnchanged'];
  if (!diff || typeof diff.bytes_equal !== 'boolean' || !Array.isArray(diff.before_cells) || !Array.isArray(diff.after_cells) ||
      !Array.isArray(diff.cells) || !diff.cells.every(cell => typeof cell.name === 'string' && statuses.includes(cell.status) &&
        Object.hasOwn(cell, 'before') && Object.hasOwn(cell, 'after')) ||
      (diff.bytes_equal ? diff.first_difference !== null : !Number.isInteger(diff.first_difference) || diff.first_difference < 0)) {
    return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Definition engine did not return a complete raw inventory.');
  }
  const bytes = Buffer.from(JSON.stringify({ schema: 'gdsii-definition-diff-v1', ...snapshots, diff }, null, 2) + '\n');
  let handle;
  try {
    handle = openSync(outputPath, 'wx'); writeFileSync(handle, bytes); closeSync(handle); handle = undefined;
    const actual = readFileSync(outputPath);
    if (!actual.equals(bytes)) return fail('output', 'READBACK_MISMATCH', 'Saved raw inventory differs from the complete result.', { path: resolve(outputPath) });
    process.stdout.write(JSON.stringify({ schema: 'gdsii-definition-diff-file-v1', ...snapshots,
      status: diff.bytes_equal ? 'IdenticalBytes' : 'ChangedBytes', output: { path: resolve(outputPath), bytes: actual.length, sha256: sha256(actual) } }) + '\n');
    process.exitCode = diff.bytes_equal ? 0 : 3;
  } catch (error) { return fail('output', error.code ?? 'OUTPUT_FAILED', error.message, { path: resolve(outputPath) }); }
  finally { if (handle !== undefined) { try { closeSync(handle); } catch { /* Preserve the reported filesystem failure. */ } } }
}
main();
