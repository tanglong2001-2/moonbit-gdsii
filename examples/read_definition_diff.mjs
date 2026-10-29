// Consume actual GDS cell ranges using record headers, without a geometry engine.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
function records(bytes) {
  const result = []; let offset = 0;
  while (offset + 4 <= bytes.length) {
    const length = bytes.readUInt16BE(offset); const kind = bytes[offset + 2];
    if (length < 4 || length % 2 || offset + length > bytes.length) throw new Error('Invalid physical record range.');
    result.push({ offset, length, kind }); offset += length;
    if (kind === 4) return result;
  }
  throw new Error('ENDLIB not found.');
}
try {
  if (process.argv.length !== 3) throw new Error('Expected one saved definition-diff JSON path.');
  const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  if (report.schema !== 'gdsii-definition-diff-v1' || !Array.isArray(report.diff?.cells)) throw new Error('Incomplete raw definition inventory.');
  const inputs = {}; const tables = {};
  for (const side of ['before', 'after']) {
    const source = report[side]; const bytes = readFileSync(source.path);
    if (bytes.length !== source.bytes || sha256(bytes) !== source.sha256) throw new Error(`${side} bytes changed since this inventory.`);
    inputs[side] = bytes; tables[side] = records(bytes);
  }
  function span(side, range, name) {
    if (range === null) return null;
    const selected = tables[side].slice(range.first_record, range.first_record + range.record_count);
    if (!selected.length || selected.length !== range.record_count || selected[0].offset !== range.byte_offset ||
        selected[0].kind !== 5 || selected.at(-1).kind !== 7 ||
        selected.at(-1).offset + selected.at(-1).length !== range.byte_offset + range.byte_length) throw new Error('Cell span does not match physical record boundaries.');
    const names = selected.filter(record => record.kind === 6).map(record => inputs[side].subarray(record.offset + 4, record.offset + record.length).toString('ascii').replace(/\0$/, ''));
    if (names.length !== 1 || names[0] !== name) throw new Error('Cell span name differs from the physical STRNAME.');
    const bytes = inputs[side].subarray(range.byte_offset, range.byte_offset + range.byte_length);
    return { ...range, sha256: sha256(bytes) };
  }
  const cells = report.diff.cells.map(cell => ({ name: cell.name, status: cell.status,
    before: span('before', cell.before, cell.name), after: span('after', cell.after, cell.name) }));
  const left = inputs.before; const right = inputs.after; let first = null;
  for (let i = 0; i < Math.min(left.length, right.length); i++) { if (left[i] !== right[i]) { first = i; break; } }
  if (first === null && left.length !== right.length) first = Math.min(left.length, right.length);
  if (report.diff.first_difference !== first || report.diff.bytes_equal !== (first === null)) throw new Error('Physical byte comparison differs from the saved inventory.');
  process.stdout.write(JSON.stringify({ schema: 'gdsii-definition-diff-received-v1', inputs_verified: true,
    status: first === null ? 'IdenticalBytes' : 'ChangedBytes', first_difference: first,
    first_bytes: first === null ? null : { before: first < left.length ? left[first] : null, after: first < right.length ? right[first] : null }, cells }) + '\n');
  process.exitCode = first === null ? 0 : 3;
} catch (error) { process.stdout.write(JSON.stringify({ error: { stage: 'receiver', message: error.message } }) + '\n'); process.exitCode = 2; }
