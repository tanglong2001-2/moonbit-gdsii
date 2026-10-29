import { closeSync, existsSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
function fail(stage, code, message, context = {}) {
  process.stdout.write(JSON.stringify({ error: { stage, code, message, ...context } }) + '\n');
  process.exitCode = 2;
}
function main() {
  const args = process.argv.slice(2);
  if (args.length !== 3) return fail('request', 'EXTRACTION_ARGUMENTS_REQUIRED', 'Expected SOURCE.gds CELL OUTPUT.gds.');
  const [sourcePath, cell, outputPath] = args;
  let original;
  try {
    original = readFileSync(sourcePath);
  } catch (error) {
    return fail('input', error.code ?? 'INPUT_READ_FAILED', error.message, { path: resolve(sourcePath) });
  }
  const source = { path: resolve(sourcePath), bytes: original.length, sha256: sha256(original) };
  const engine = resolve(root, '_build/js/debug/build/cmd/inspect/inspect.js');
  if (!existsSync(engine)) return fail('build', 'BUILD_UNAVAILABLE', 'Run moon build --target js from the project directory.', { path: engine });
  const child = spawnSync(process.execPath, [engine], {
    input: JSON.stringify({ mode: 'extract-cell', hex: original.toString('hex'), cell }),
    encoding: 'utf8', maxBuffer: 64 * 1024 * 1024,
  });
  if (child.error) return fail('engine', child.error.code ?? 'ENGINE_START_FAILED', child.error.message);
  if (child.status !== 0) return fail('engine', 'ENGINE_EXIT', 'Extraction engine failed.', { status: child.status, signal: child.signal, diagnostic: child.stderr ?? '' });
  let response;
  try {
    response = JSON.parse(child.stdout);
  } catch {
    return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Extraction engine did not return a JSON object.');
  }
  if (!response || typeof response !== 'object' || Array.isArray(response)) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Extraction engine did not return a JSON object.');
  if (response.error) {
    process.stdout.write(JSON.stringify({ ...response, source }) + '\n');
    process.exitCode = 2;
    return;
  }
  const result = response.extraction;
  if (!result || result.cell !== cell || !Array.isArray(result.kept_cells) ||
      !result.kept_cells.every(name => typeof name === 'string') ||
      !result.kept_cells.includes(cell) || new Set(result.kept_cells).size !== result.kept_cells.length ||
      !Array.isArray(result.bytes) || !result.bytes.every(byte => Number.isInteger(byte) && byte >= 0 && byte <= 255)) {
    return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Extraction engine did not return a complete byte artifact and cell inventory.');
  }
  const bytes = Buffer.from(result.bytes);
  let handle;
  try {
    // Parse/query validation is complete before creating a new target.
    handle = openSync(outputPath, 'wx');
    writeFileSync(handle, bytes);
    closeSync(handle);
    handle = undefined;
    const actual = readFileSync(outputPath);
    if (!actual.equals(bytes)) return fail('output', 'READBACK_MISMATCH', 'Saved bytes differ from the validated export.', { path: resolve(outputPath) });
    process.stdout.write(JSON.stringify({ schema: 'gdsii-cell-extraction-v1', cell, kept_cells: result.kept_cells, source,
      output: { path: resolve(outputPath), bytes: actual.length, sha256: sha256(actual) } }) + '\n');
  } catch (error) {
    return fail('output', error.code ?? 'OUTPUT_FAILED', error.message, { path: resolve(outputPath) });
  } finally {
    if (handle !== undefined) {
      try { closeSync(handle); } catch { /* Preserve the reported write/close failure. */ }
    }
  }
}
main();
