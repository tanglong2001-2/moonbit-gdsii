import { closeSync, existsSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const codes = { NoNewIssues: 0, NewIssuesFound: 3, Incomplete: 4, ErrorsFound: 2 };
function fail(stage, code, message, context = {}) {
  process.stdout.write(JSON.stringify({ error: { stage, code, message, ...context } }) + '\n'); process.exitCode = 2;
}
function main() {
  const args = process.argv.slice(2);
  if (args.length !== 4) return fail('request', 'COMPARE_PLAN_ARGUMENTS_REQUIRED', 'Expected BEFORE.gds AFTER.gds PLAN.json OUTPUT.json.');
  const [beforePath, afterPath, planPath, outputPath] = args;
  const fingerprint = (path, bytes) => ({ path: resolve(path), bytes: bytes.length, sha256: sha256(bytes) });
  let planBytes, planValue;
  try { planBytes = readFileSync(planPath); }
  catch (error) { return fail('plan', error.code ?? 'PLAN_READ_FAILED', error.message, { path: resolve(planPath) }); }
  try { planValue = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(planBytes)); }
  catch (error) { return fail('plan', 'INVALID_REVIEW_PLAN', error.message, { path: resolve(planPath) }); }
  const snapshots = {}; const bytes = {};
  for (const [side, path] of [['before', beforePath], ['after', afterPath]]) {
    try { bytes[side] = readFileSync(path); }
    catch (error) { return fail(side, error.code ?? 'INPUT_READ_FAILED', error.message, { path: resolve(path) }); }
    snapshots[side] = fingerprint(path, bytes[side]);
  }
  snapshots.plan = fingerprint(planPath, planBytes);
  const engine = resolve(root, '_build/js/debug/build/cmd/inspect/inspect.js');
  if (!existsSync(engine)) return fail('build', 'BUILD_UNAVAILABLE', 'Run moon build --target js from the project directory.', { path: engine });
  const child = spawnSync(process.execPath, [engine], { input: JSON.stringify({ mode: 'compare-plan',
    hex: bytes.before.toString('hex'), after_hex: bytes.after.toString('hex'), plan: planValue }), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (child.error) return fail('engine', child.error.code ?? 'ENGINE_START_FAILED', child.error.message);
  if (child.status !== 0) return fail('engine', 'ENGINE_EXIT', 'Comparison plan engine failed.', { status: child.status, signal: child.signal, diagnostic: child.stderr ?? '' });
  let response;
  try { response = JSON.parse(child.stdout); }
  catch { return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Comparison engine did not return JSON.'); }
  if (!response || typeof response !== 'object' || Array.isArray(response)) return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Comparison engine did not return an object.');
  if (Object.hasOwn(response, 'error')) {
    process.stdout.write(JSON.stringify({ ...response, ...snapshots }) + '\n'); process.exitCode = 2; return;
  }
  const review = response.comparison_review;
  const keys = ['id', 'layer', 'datatype', 'min_width', 'min_spacing'];
  if (!review || !Object.hasOwn(codes, review.status) || review.cell !== planValue?.cell ||
      review.budget !== (planValue.budget ?? 100000) || !Array.isArray(review.profiles) || !Array.isArray(review.results) ||
      !Array.isArray(planValue.profiles) || review.profiles.length !== planValue.profiles.length || review.results.length !== planValue.profiles.length ||
      !review.profiles.every((profile, index) => keys.every(key => profile[key] === planValue.profiles[index][key]) &&
        review.results[index]?.id === profile.id && review.results[index].before && review.results[index].after)) {
    return fail('engine', 'ENGINE_RESPONSE_INVALID', 'Comparison engine did not return every ordered profile and both operands.');
  }
  const saved = Buffer.from(JSON.stringify({ schema: 'gdsii-rectangle-comparison-result-v1', ...snapshots, review }, null, 2) + '\n');
  let handle;
  try {
    handle = openSync(outputPath, 'wx'); writeFileSync(handle, saved); closeSync(handle); handle = undefined;
    const actual = readFileSync(outputPath);
    if (!actual.equals(saved)) return fail('output', 'READBACK_MISMATCH', 'Saved report differs from the complete comparison.', { path: resolve(outputPath) });
    process.stdout.write(JSON.stringify({ schema: 'gdsii-comparison-plan-file-v1', ...snapshots, cell: review.cell, status: review.status,
      output: { path: resolve(outputPath), bytes: actual.length, sha256: sha256(actual) } }) + '\n'); process.exitCode = codes[review.status];
  } catch (error) { return fail('output', error.code ?? 'OUTPUT_FAILED', error.message, { path: resolve(outputPath) }); }
  finally { if (handle !== undefined) { try { closeSync(handle); } catch { /* Keep the reported filesystem failure. */ } } }
}
main();
