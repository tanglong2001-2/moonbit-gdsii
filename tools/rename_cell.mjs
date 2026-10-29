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
  if (args.length !== 4) return fail('request', 'RENAME_ARGUMENTS_REQUIRED', 'Expected SOURCE.gds OLD_NAME NEW_NAME OUTPUT.gds.');
  const [sourcePath, oldName, newName, outputPath] = args;
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
    input: JSON.stringify({ mode: 'rename-cell', hex: original.toString('hex'), old_name: oldName, new_name: newName }),
    encoding: 'utf8', maxBuffer: 64 * 1024 * 1024,
  });
  if (child.error) return fail('engine', child.error.code ?? 'ENGINE_START_FAILED', child.error.message);
  if (child.status !== 0) return fail('engine', 'ENGINE_EXIT', 'Rename engine failed.', { status: child.status, signal: child.signal, diagnostic: child.stderr ?? '' });
  let response;
  try {
    response = JSON.parse(child.stdout);
  } catch {
    return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Rename engine did not return a JSON object.');
  }
  if (!response || typeof response !== 'object' || Array.isArray(response)) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Rename engine did not return a JSON object.');
  if (response.error) {
    process.stdout.write(JSON.stringify({ ...response, source }) + '\n');
    process.exitCode = 2;
    return;
  }
  const result = response.renaming;
  if (!result || result.old_name !== oldName || result.new_name !== newName ||
      !Number.isInteger(result.updated_references) || result.updated_references < 0 ||
      !Array.isArray(result.cells) || !result.cells.every(name => typeof name === 'string') ||
      !result.cells.includes(newName) || new Set(result.cells).size !== result.cells.length ||
      (oldName !== newName && result.cells.includes(oldName)) ||
      !Array.isArray(result.bytes) || !result.bytes.every(byte => Number.isInteger(byte) && byte >= 0 && byte <= 255)) {
    return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Rename engine did not return a complete byte artifact and cell inventory.');
  }
  const bytes = Buffer.from(result.bytes);
  let handle;
  try {
    handle = openSync(outputPath, 'wx');
    writeFileSync(handle, bytes);
    closeSync(handle);
    handle = undefined;
    const actual = readFileSync(outputPath);
    if (!actual.equals(bytes)) return fail('output', 'READBACK_MISMATCH', 'Saved bytes differ from the validated rename.', { path: resolve(outputPath) });
    process.stdout.write(JSON.stringify({ schema: 'gdsii-cell-rename-v1', old_name: oldName, new_name: newName,
      changed: oldName !== newName, updated_references: result.updated_references, cells: result.cells, source,
      output: { path: resolve(outputPath), bytes: actual.length, sha256: sha256(actual) } }) + '\n');
  } catch (error) {
    return fail('output', error.code ?? 'OUTPUT_FAILED', error.message, { path: resolve(outputPath) });
  } finally {
    if (handle !== undefined) {
      try { closeSync(handle); } catch { /* Preserve the reported filesystem failure. */ }
    }
  }
}
main();
