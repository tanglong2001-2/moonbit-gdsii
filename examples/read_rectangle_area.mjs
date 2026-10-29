// A physical saved-report consumer. It verifies source binding and exact decimal
// representation/scope; it does not reflatten GDS or authenticate report authors.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const codes = { Complete: 0, IncompleteGeometry: 4, EmptySelection: 4 };
try {
  if (process.argv.length !== 3) throw new Error('Expected one saved rectangle-area JSON path.');
  const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  if (report.schema !== 'gdsii-rectangle-area-v1') throw new Error('Expected rectangle-area report.');
  const source = readFileSync(report.source.path);
  if (source.length !== report.source.bytes || sha256(source) !== report.source.sha256) throw new Error('source bytes changed since this measurement.');
  const q = report.query, m = report.measurement;
  if (!q || typeof q.cell !== 'string' || !q.cell.length || !Number.isInteger(q.layer) || q.layer < 0 || q.layer > 2147483647 ||
      !Number.isInteger(q.datatype) || q.datatype < 0 || q.datatype > 2147483647 || !Number.isInteger(q.budget) || q.budget < 1 || q.budget > 2147483647) throw new Error('Invalid measurement scope.');
  if (!m || m.cell !== q.cell || m.layer !== q.layer || m.datatype !== q.datatype || !Object.hasOwn(codes, m.status) ||
      typeof m.area_dbu2 !== 'string' || !/^(0|[1-9][0-9]*)$/.test(m.area_dbu2) || BigInt(m.area_dbu2) > 18446744073709551615n ||
      !Array.isArray(m.rectangles) || !Array.isArray(m.skipped)) throw new Error('Invalid exact area or measurement scope.');
  for (const r of m.rectangles) {
    if (![r.min_x, r.min_y, r.max_x, r.max_y].every(v => Number.isInteger(v) && v >= -2147483648 && v <= 2147483647) || r.min_x >= r.max_x || r.min_y >= r.max_y || typeof r.source !== 'string') throw new Error('Invalid checked rectangle.');
  }
  if (!m.skipped.every(item => typeof item.source === 'string' && typeof item.reason === 'string') || m.checked_rectangles !== m.rectangles.length ||
      m.selected_shapes !== m.rectangles.length + m.skipped.length || m.status !== (m.skipped.length ? 'IncompleteGeometry' : m.rectangles.length ? 'Complete' : 'EmptySelection') ||
      (!m.rectangles.length && m.area_dbu2 !== '0')) throw new Error('Incomplete or inconsistent geometry scope.');
  process.stdout.write(JSON.stringify({ schema: 'gdsii-rectangle-area-received-v1', source_verified: true, precision: 'uint64-decimal', query: q,
    measurement: { ...m, area_dbu2: BigInt(m.area_dbu2).toString() } }) + '\n'); process.exitCode = codes[m.status];
} catch (error) { process.stdout.write(JSON.stringify({ error: { stage: 'receiver', message: error.message } }) + '\n'); process.exitCode = 2; }
