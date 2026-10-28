import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const root = fileURLToPath(new URL('../', import.meta.url));

function consumerError(stage, code, message, context = {}) {
  process.stdout.write(JSON.stringify({ error: { stage, code, message, ...context } }) + '\n');
  process.exitCode = 2;
}

function main() {
  const args = process.argv.slice(2);
  const mode = args[0] === '--preflight-tops' ? 'preflight-tops' : args[0] === '--compare-tops' ? 'compare-tops' : args[0] === '--catalog' ? 'catalog' : args[0] === '--hierarchy' ? 'hierarchy' : args[0] === '--preflight' ? 'preflight' : args[0] === '--compare' ? 'compare' : null;
  const compare = mode === 'compare' || mode === 'compare-tops';
  const topBatch = mode === 'preflight-tops' || mode === 'compare-tops';
  const parameters = mode ? args.slice(1) : args;
  if (compare && parameters.length < 2) {
    return consumerError('request', 'COMPARE_INPUTS_REQUIRED', `--${mode} requires before and after GDS paths.`);
  }
  const scope = compare ? [parameters[0], ...parameters.slice(2)] : parameters;
  const [file = resolve(root, 'examples/demo.gds'), cell = 'top', layer = '7', datatype = '2', width = '3', spacing = '5', budget] = topBatch ? [scope[0], 'top', ...scope.slice(1)] : scope;
  const afterFile = compare ? parameters[1] : null;
  if (mode === null || mode === 'preflight' || compare || topBatch) {
    for (const [argument, value] of Object.entries({ layer, datatype, width, spacing, ...(budget === undefined ? {} : { budget }) })) {
      if (value.trim() === '') {
        const range = argument === 'budget' ? 'positive' : 'nonnegative';
        return consumerError('request', 'EMPTY_NUMERIC_ARGUMENT', `${argument} must contain an explicit ${range} INT32 integer.`, { argument });
      }
    }
  }
  let hex;
  try {
    hex = readFileSync(file).toString('hex');
  } catch (error) {
    return consumerError('input', error.code ?? 'INPUT_READ_FAILED', error.message, { path: resolve(file), ...(compare ? { side: 'before' } : {}) });
  }
  let afterHex;
  if (compare) {
    try {
      afterHex = readFileSync(afterFile).toString('hex');
    } catch (error) {
      return consumerError('input', error.code ?? 'INPUT_READ_FAILED', error.message, { path: resolve(afterFile), side: 'after' });
    }
  }
  const engine = resolve(root, '_build/js/debug/build/cmd/inspect/inspect.js');
  if (!existsSync(engine)) {
    return consumerError('build', 'BUILD_UNAVAILABLE', 'File consumer is unavailable; run moon build --target js from the project directory.', { path: engine });
  }
  const request = topBatch ? { mode, hex, layer: Number(layer), datatype: Number(datatype), width: Number(width), spacing: Number(spacing) } : mode === 'catalog' ? { mode, hex } : mode === 'hierarchy' ? { mode, hex, cell } : { hex, cell,
    layer: Number(layer), datatype: Number(datatype), width: Number(width), spacing: Number(spacing) };
  if (mode === 'preflight' || mode === 'compare') request.mode = mode;
  if (compare) request.after_hex = afterHex;
  if (budget !== undefined && mode !== 'catalog' && mode !== 'hierarchy') request.budget = Number(budget);
  const result = spawnSync(process.execPath, [engine],
    { input: JSON.stringify(request), encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
  if (result.error) {
    return consumerError('engine', result.error.code ?? 'ENGINE_START_FAILED', result.error.message, { path: engine });
  }
  if (result.status !== 0) {
    return consumerError('engine', 'ENGINE_EXIT', 'File consumer did not complete successfully.', { status: result.status, signal: result.signal, diagnostic: result.stderr ?? '' });
  }
  let response;
  try {
    response = JSON.parse(result.stdout);
  } catch {
    return consumerError('engine', 'ENGINE_RESPONSE_INVALID', 'File consumer did not return a JSON object.');
  }
  if (response === null || typeof response !== 'object' || Array.isArray(response)) {
    return consumerError('engine', 'ENGINE_RESPONSE_INVALID', 'File consumer did not return a JSON object.');
  }
  let exitCode = response.error ? 2 : 0;
  if (!response.error && topBatch) {
    const status = response.batch?.status;
    if (status === 'ErrorsFound') exitCode = 2;
    else if (status === 'Incomplete') exitCode = 4;
    else if (status === 'IssuesFound') exitCode = 3;
    else if (status !== 'Passed') {
      return consumerError('engine', 'ENGINE_RESPONSE_INVALID', 'File consumer returned an unknown batch status.');
    }
  }
  if (!response.error && mode === 'preflight') {
    const status = response.preflight?.status;
    if (status === 'ViolationsFound') exitCode = 3;
    else if (status === 'IncompleteGeometry' || status === 'EmptySelection') exitCode = 4;
    else if (status !== 'RectanglesClear') {
      return consumerError('engine', 'ENGINE_RESPONSE_INVALID', 'File consumer returned an unknown preflight status.');
    }
  }
  if (!response.error && mode === 'compare') {
    const status = response.comparison?.status;
    if (status === 'NewIssuesFound') exitCode = 3;
    else if (status === 'IncompleteComparison') exitCode = 4;
    else if (status !== 'NoNewIssues') {
      return consumerError('engine', 'ENGINE_RESPONSE_INVALID', 'File consumer returned an unknown comparison status.');
    }
  }
  process.stdout.write(result.stdout ?? '');
  process.stderr.write(result.stderr ?? '');
  process.exitCode = exitCode;
}

main();
