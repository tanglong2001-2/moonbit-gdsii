// A separate report recipient: inspect a saved queue and verify its current source.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';

const codes = { Passed: 0, IssuesFound: 3, Incomplete: 4, ErrorsFound: 2 };
try {
  if (process.argv.length !== 3) throw new Error('Expected one saved dependent-review JSON path.');
  const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  if (report.schema !== 'gdsii-dependent-review-v1' || !Object.hasOwn(codes, report.status) ||
      typeof report.source?.path !== 'string' || !Array.isArray(report.dependency?.cells) ||
      !Array.isArray(report.results) || report.results.length !== report.dependency.cells.length ||
      !report.results.every((result, index) => result.cell === report.dependency.cells[index].name &&
        (Object.hasOwn(result, 'error') !== Object.hasOwn(result, 'preflight')))) throw new Error('Incomplete dependent-review artifact.');
  const current = readFileSync(report.source.path);
  const currentSHA256 = createHash('sha256').update(current).digest('hex');
  if (current.length !== report.source.bytes || currentSHA256 !== report.source.sha256) throw new Error('Source bytes changed since this review.');
  process.stdout.write(JSON.stringify({ schema: 'gdsii-dependent-review-received-v1', target: report.dependency.target,
    target_defined: report.dependency.target_defined, status: report.status, counts: report.counts, coverage: report.coverage,
    source_verified: true, queue: report.dependency.cells.map((cell, index) => ({ ...cell,
      outcome: Object.hasOwn(report.results[index], 'error') ? { error: report.results[index].error } : {
        status: report.results[index].preflight.status, checked_rectangles: report.results[index].preflight.checked_rectangles,
        skipped: report.results[index].preflight.skipped.length, issues: report.results[index].preflight.issues.length } })) }) + '\n');
  process.exitCode = codes[report.status];
} catch (error) {
  process.stdout.write(JSON.stringify({ error: { stage: 'receiver', message: error.message } }) + '\n'); process.exitCode = 2;
}
