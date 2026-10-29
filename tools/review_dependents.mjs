import { closeSync, existsSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const statusCodes = { Passed: 0, IssuesFound: 3, Incomplete: 4, ErrorsFound: 2 };
function fail(stage, code, message, context = {}) {
  process.stdout.write(JSON.stringify({ error: { stage, code, message, ...context } }) + '\n');
  process.exitCode = 2;
}
function main() {
  const args = process.argv.slice(2);
  if (args.length !== 7 && args.length !== 8) return fail('request', 'REVIEW_ARGUMENTS_REQUIRED', 'Expected SOURCE.gds TARGET LAYER DATATYPE WIDTH SPACING OUTPUT.json [BUDGET].');
  const [sourcePath, target, layer, datatype, width, spacing, outputPath, budget] = args;
  const values = { layer, datatype, width, spacing, ...(budget === undefined ? {} : { budget }) };
  for (const [argument, text] of Object.entries(values)) {
    const value = Number(text);
    if (!text.trim() || !Number.isInteger(value) || value < (argument === 'budget' ? 1 : 0) || value > 2147483647) {
      return fail('request', 'INVALID_NUMERIC_ARGUMENT', `${argument} must be an explicit ${argument === 'budget' ? 'positive' : 'nonnegative'} INT32 integer.`, { argument });
    }
  }
  let original;
  try { original = readFileSync(sourcePath); }
  catch (error) { return fail('input', error.code ?? 'INPUT_READ_FAILED', error.message, { path: resolve(sourcePath) }); }
  const source = { path: resolve(sourcePath), bytes: original.length, sha256: sha256(original) };
  const engine = resolve(root, '_build/js/debug/build/cmd/inspect/inspect.js');
  if (!existsSync(engine)) return fail('build', 'BUILD_UNAVAILABLE', 'Run moon build --target js from the project directory.', { path: engine });
  const profile = { layer: Number(layer), datatype: Number(datatype), min_width: Number(width), min_spacing: Number(spacing), budget: Number(budget ?? 100000) };
  const child = spawnSync(process.execPath, [engine], {
    input: JSON.stringify({ mode: 'review-dependents', hex: original.toString('hex'), cell: target,
      layer: profile.layer, datatype: profile.datatype, width: profile.min_width, spacing: profile.min_spacing, budget: profile.budget }),
    encoding: 'utf8', maxBuffer: 64 * 1024 * 1024,
  });
  if (child.error) return fail('engine', child.error.code ?? 'ENGINE_START_FAILED', child.error.message);
  if (child.status !== 0) return fail('engine', 'ENGINE_EXIT', 'Dependent review engine failed.', { status: child.status, signal: child.signal, diagnostic: child.stderr ?? '' });
  let response;
  try { response = JSON.parse(child.stdout); }
  catch { return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Review engine did not return JSON.'); }
  if (!response || typeof response !== 'object' || Array.isArray(response)) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Review engine did not return an object.');
  if (Object.hasOwn(response, 'error')) {
    process.stdout.write(JSON.stringify({ ...response, source }) + '\n'); process.exitCode = 2; return;
  }
  const review = response.dependent_review;
  if (!review || !Object.hasOwn(statusCodes, review.status) || review.dependency?.target !== target ||
      typeof review.dependency.target_defined !== 'boolean' || !Array.isArray(review.dependency.cells) ||
      !Array.isArray(review.results) || review.results.length !== review.dependency.cells.length ||
      !Object.entries(profile).every(([key, value]) => review.profile?.[key] === value) ||
      !review.dependency.cells.every((cell, index) => typeof cell.name === 'string' && typeof cell.is_top === 'boolean' &&
        Array.isArray(cell.witness) && review.results[index]?.cell === cell.name) ||
      new Set(review.dependency.cells.map(cell => cell.name)).size !== review.results.length) {
    return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Review engine did not return the complete ordered dependency review.');
  }
  const bytes = Buffer.from(JSON.stringify({ schema: 'gdsii-dependent-review-v1', source, ...review }, null, 2) + '\n');
  let handle;
  try {
    handle = openSync(outputPath, 'wx');
    writeFileSync(handle, bytes); closeSync(handle); handle = undefined;
    const actual = readFileSync(outputPath);
    if (!actual.equals(bytes)) return fail('output', 'READBACK_MISMATCH', 'Saved report differs from the complete review.', { path: resolve(outputPath) });
    process.stdout.write(JSON.stringify({ schema: 'gdsii-dependent-review-file-v1', source, target, status: review.status,
      output: { path: resolve(outputPath), bytes: actual.length, sha256: sha256(actual) } }) + '\n');
    process.exitCode = statusCodes[review.status];
  } catch (error) { return fail('output', error.code ?? 'OUTPUT_FAILED', error.message, { path: resolve(outputPath) }); }
  finally {
    if (handle !== undefined) { try { closeSync(handle); } catch { /* Preserve the reported filesystem failure. */ } }
  }
}
main();
