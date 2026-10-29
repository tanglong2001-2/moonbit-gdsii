import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const codes = { NoNewIssues: 0, NewIssuesFound: 3, Incomplete: 4, ErrorsFound: 2 };
try {
  if (process.argv.length !== 3) throw new Error('Expected one saved comparison-plan report path.');
  const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  const review = report.review;
  if (report.schema !== 'gdsii-rectangle-comparison-result-v1' || !review || !Object.hasOwn(codes, review.status) ||
      !Array.isArray(review.profiles) || !Array.isArray(review.results) || review.profiles.length !== review.results.length ||
      !review.results.every((result, index) => result.id === review.profiles[index].id && result.before && result.after)) throw new Error('Incomplete comparison-plan artifact.');
  for (const operand of ['before', 'after', 'plan']) {
    const input = report[operand]; const current = readFileSync(input.path);
    if (current.length !== input.bytes || createHash('sha256').update(current).digest('hex') !== input.sha256) throw new Error(`${operand} bytes changed since this comparison.`);
  }
  const side = value => Object.hasOwn(value, 'error') ? value : { status: value.preflight.status,
    checked_rectangles: value.preflight.checked_rectangles, skipped: value.preflight.skipped.length, issues: value.preflight.issues.length };
  const results = review.results.map(result => ({ id: result.id, before: side(result.before), after: side(result.after),
    ...(result.comparison ? { comparison: { status: result.comparison.status, introduced: result.comparison.introduced.length,
      removed: result.comparison.removed.length, retained: result.comparison.retained } } : {}),
    ...(Object.hasOwn(result, 'error') ? { error: result.error } : {}) }));
  process.stdout.write(JSON.stringify({ schema: 'gdsii-comparison-plan-received-v1', inputs_verified: true, cell: review.cell,
    status: review.status, counts: review.counts, coverage: review.coverage, results }) + '\n'); process.exitCode = codes[review.status];
} catch (error) { process.stdout.write(JSON.stringify({ error: { stage: 'receiver', message: error.message } }) + '\n'); process.exitCode = 2; }
