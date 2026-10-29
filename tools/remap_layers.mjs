import { closeSync, existsSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
function fail(stage, code, message, context = {}) {
  process.stdout.write(JSON.stringify({ error: { stage, code, message, ...context } }) + '\n'); process.exitCode = 2;
}
function planFrom(bytes) {
  const text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
  const value = JSON.parse(text);
  const object = v => v !== null && typeof v === 'object' && !Array.isArray(v);
  const fields = ['from_layer', 'from_type', 'to_layer', 'to_type'];
  if (!object(value) || value.schema !== 'gdsii-layer-remap-v1' || Object.keys(value).sort().join() !== 'mappings,schema' || !Array.isArray(value.mappings)) throw new Error('Expected gdsii-layer-remap-v1 with a mappings array.');
  const sources = new Set();
  for (const rule of value.mappings) {
    if (!object(rule) || Object.keys(rule).sort().join() !== fields.toSorted().join() ||
        !fields.every(field => Number.isInteger(rule[field]) && rule[field] >= 0 && rule[field] <= 65535)) throw new Error('Every mapping requires exactly four UINT16 integer fields.');
    const key = `${rule.from_layer}/${rule.from_type}`;
    if (sources.has(key)) throw new Error('Duplicate layer remap source pair.'); sources.add(key);
  }
  return value;
}
function main() {
  const args = process.argv.slice(2);
  if (args.length !== 3) return fail('request', 'LAYER_REMAP_ARGUMENTS_REQUIRED', 'Expected SOURCE.gds MAP.json OUTPUT.gds.');
  const [sourcePath, planPath, outputPath] = args;
  let planBytes, plan, source;
  try { planBytes = readFileSync(planPath); }
  catch (error) { return fail('plan', error.code ?? 'PLAN_READ_FAILED', error.message, { path: resolve(planPath) }); }
  try { plan = planFrom(planBytes); }
  catch (error) { return fail('plan', 'INVALID_LAYER_REMAP', error.message); }
  try { source = readFileSync(sourcePath); }
  catch (error) { return fail('source', error.code ?? 'SOURCE_READ_FAILED', error.message, { path: resolve(sourcePath) }); }
  const engine = resolve(root, '_build/js/debug/build/cmd/inspect/inspect.js');
  if (!existsSync(engine)) return fail('build', 'BUILD_UNAVAILABLE', 'Run moon build --target js from the project directory.', { path: engine });
  const child = spawnSync(process.execPath, [engine], { input: JSON.stringify({ mode: 'remap-layers', hex: source.toString('hex'), mappings: plan.mappings }), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (child.error) return fail('engine', child.error.code ?? 'ENGINE_START_FAILED', child.error.message);
  if (child.status !== 0) return fail('engine', 'ENGINE_EXIT', 'Layer remap engine failed.', { status: child.status, signal: child.signal, diagnostic: child.stderr ?? '' });
  let response;
  try { response = JSON.parse(child.stdout); }
  catch { return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Layer remap engine did not return JSON.'); }
  if (!response || typeof response !== 'object' || Array.isArray(response)) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Layer remap engine did not return an object.');
  if (Object.hasOwn(response, 'error')) { process.stdout.write(JSON.stringify(response) + '\n'); process.exitCode = 2; return; }
  const result = response.remapping;
  if (!result || !Number.isInteger(result.changed_elements) || result.changed_elements < 0 || !result.catalog ||
      !Array.isArray(result.bytes) || !result.bytes.every(byte => Number.isInteger(byte) && byte >= 0 && byte <= 255)) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Layer remap engine did not return complete GDS bytes/catalogue.');
  const bytes = Buffer.from(result.bytes); let handle;
  try {
    handle = openSync(outputPath, 'wx'); writeFileSync(handle, bytes); closeSync(handle); handle = undefined;
    const actual = readFileSync(outputPath);
    if (!actual.equals(bytes)) return fail('output', 'READBACK_MISMATCH', 'Saved GDS differs from the remapped byte stream.', { path: resolve(outputPath) });
    const fingerprint = (path, data) => ({ path: resolve(path), bytes: data.length, sha256: sha256(data) });
    process.stdout.write(JSON.stringify({ schema: 'gdsii-layer-remap-file-v1', source: fingerprint(sourcePath, source), plan: fingerprint(planPath, planBytes),
      output: fingerprint(outputPath, actual), changed_elements: result.changed_elements, catalog: result.catalog }) + '\n');
  } catch (error) { return fail('output', error.code ?? 'OUTPUT_FAILED', error.message, { path: resolve(outputPath) }); }
  finally { if (handle !== undefined) { try { closeSync(handle); } catch { /* Preserve the primary filesystem failure. */ } } }
}
main();
