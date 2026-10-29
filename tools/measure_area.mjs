import { closeSync, existsSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
const root = fileURLToPath(new URL('../', import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const exits = { Complete: 0, EmptySelection: 4, IncompleteGeometry: 4 };
function fail(stage, code, message, context = {}) {
  process.stdout.write(JSON.stringify({ error: { stage, code, message, ...context } }) + '\n'); process.exitCode = 2;
}
function main() {
  const args = process.argv.slice(2);
  if (args.length < 5 || args.length > 6) return fail('request', 'AREA_ARGUMENTS_REQUIRED', 'Expected SOURCE.gds CELL LAYER DATATYPE OUTPUT.json [BUDGET].');
  const [sourcePath, cell, layerText, datatypeText, outputPath, budgetText = '100000'] = args;
  const values = { layer: layerText, datatype: datatypeText, budget: budgetText };
  for (const [name, text] of Object.entries(values)) {
    const value = Number(text);
    if (!text.trim() || !Number.isInteger(value) || value < (name === 'budget' ? 1 : 0) || value > 2147483647) return fail('request', 'INVALID_AREA_QUERY', `${name} must be an explicit ${name === 'budget' ? 'positive' : 'nonnegative'} INT32 integer.`);
    values[name] = value;
  }
  if (!cell.length) return fail('request', 'INVALID_AREA_QUERY', 'Expected an exact nonempty cell name.');
  let source;
  try { source = readFileSync(sourcePath); }
  catch (error) { return fail('source', error.code ?? 'SOURCE_READ_FAILED', error.message, { path: resolve(sourcePath) }); }
  const query = { cell, ...values }, binding = { path: resolve(sourcePath), bytes: source.length, sha256: sha256(source) };
  const engine = resolve(root, '_build/js/debug/build/cmd/inspect/inspect.js');
  if (!existsSync(engine)) return fail('build', 'BUILD_UNAVAILABLE', 'Run moon build --target js from the project directory.', { path: engine });
  const child = spawnSync(process.execPath, [engine], { input: JSON.stringify({ mode: 'rectangle-area', hex: source.toString('hex'), ...query }), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (child.error) return fail('engine', child.error.code ?? 'ENGINE_START_FAILED', child.error.message);
  if (child.status !== 0) return fail('engine', 'ENGINE_EXIT', 'Rectangle area engine failed.', { status: child.status, signal: child.signal, diagnostic: child.stderr ?? '' });
  let response;
  try { response = JSON.parse(child.stdout); }
  catch { return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Rectangle area engine did not return JSON.'); }
  if (!response || typeof response !== 'object' || Array.isArray(response)) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Rectangle area engine did not return an object.');
  if (Object.hasOwn(response, 'error')) { process.stdout.write(JSON.stringify({ ...response, source: binding, query }) + '\n'); process.exitCode = 2; return; }
  const m = response.measurement;
  if (!m || !Object.hasOwn(exits, m.status) || typeof m.area_dbu2 !== 'string' || !/^(0|[1-9][0-9]*)$/.test(m.area_dbu2) || BigInt(m.area_dbu2) > 18446744073709551615n ||
      m.cell !== cell || m.layer !== values.layer || m.datatype !== values.datatype || !Array.isArray(m.rectangles) || !Array.isArray(m.skipped) ||
      m.checked_rectangles !== m.rectangles.length || m.selected_shapes !== m.rectangles.length + m.skipped.length ||
      m.status !== (m.skipped.length ? 'IncompleteGeometry' : m.rectangles.length ? 'Complete' : 'EmptySelection')) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Expected a complete exact rectangle-area result and coverage scope.');
  const bytes = Buffer.from(JSON.stringify({ schema: 'gdsii-rectangle-area-v1', source: binding, query, measurement: m }, null, 2) + '\n'); let handle;
  try {
    handle = openSync(outputPath, 'wx'); writeFileSync(handle, bytes); closeSync(handle); handle = undefined;
    const actual = readFileSync(outputPath);
    if (!actual.equals(bytes)) return fail('output', 'READBACK_MISMATCH', 'Saved measurement differs from the complete exact result.', { path: resolve(outputPath) });
    process.stdout.write(JSON.stringify({ schema: 'gdsii-rectangle-area-file-v1', source: binding, query, status: m.status,
      output: { path: resolve(outputPath), bytes: actual.length, sha256: sha256(actual) } }) + '\n'); process.exitCode = exits[m.status];
  } catch (error) { return fail('output', error.code ?? 'OUTPUT_FAILED', error.message, { path: resolve(outputPath) }); }
  finally { if (handle !== undefined) { try { closeSync(handle); } catch { /* Preserve the primary filesystem failure. */ } } }
}
main();
