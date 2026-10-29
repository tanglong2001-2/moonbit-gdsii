// Independently inspect actual input/output record bytes, without the MoonBit engine.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
function scan(bytes) {
  const records = []; const elements = []; const cells = [];
  const kinds = new Map([[8, 'Boundary'], [9, 'Path'], [12, 'Text'], [21, 'Node'], [45, 'Box']]);
  let offset = 0, cell = null, element = null, elementIndex = 0;
  while (offset + 4 <= bytes.length) {
    const length = bytes.readUInt16BE(offset), kind = bytes[offset + 2];
    if (length < 4 || length % 2 || offset + length > bytes.length) throw new Error('Invalid physical record range.');
    const record = { offset, length, kind }; records.push(record);
    if (kind === 6) { cell = bytes.subarray(offset + 4, offset + length).toString('ascii').replace(/\0$/, ''); cells.push(cell); elementIndex = 0; }
    if (kinds.has(kind) || kind === 10 || kind === 11) { element = { cell, element_index: elementIndex++, kind: kinds.get(kind), layer: null, type: null, layerOffset: null, typeOffset: null }; }
    if (element && kind === 13) { element.layer = bytes.readUInt16BE(offset + 4); element.layerOffset = offset + 4; }
    if (element && [14, 22, 42, 46].includes(kind)) { element.type = bytes.readUInt16BE(offset + 4); element.typeOffset = offset + 4; }
    if (kind === 17) { if (element?.kind) elements.push(element); element = null; }
    offset += length;
    if (kind === 4) {
      if (!bytes.subarray(offset).every(byte => byte === 0)) throw new Error('Nonzero physical tail.');
      return { records, elements, cells, padding: bytes.length - offset };
    }
  }
  throw new Error('ENDLIB not found.');
}
try {
  if (process.argv.length !== 3) throw new Error('Expected one saved layer-remap receipt path.');
  const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  if (report.schema !== 'gdsii-layer-remap-file-v1') throw new Error('Expected layer-remap file receipt.');
  const inputs = {};
  for (const side of ['source', 'plan', 'output']) {
    const item = report[side], bytes = readFileSync(item.path);
    if (bytes.length !== item.bytes || sha256(bytes) !== item.sha256) throw new Error(`${side} bytes changed since this receipt.`);
    inputs[side] = bytes;
  }
  const plan = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(inputs.plan));
  if (plan.schema !== 'gdsii-layer-remap-v1' || !Array.isArray(plan.mappings)) throw new Error('Invalid remap plan.');
  const before = scan(inputs.source), after = scan(inputs.output);
  const expected = Buffer.from(inputs.source); let changedElements = 0, changedRecords = 0;
  for (const element of before.elements) {
    const rule = plan.mappings.find(rule => rule.from_layer === element.layer && rule.from_type === element.type);
    if (!rule) continue;
    if (element.layer !== rule.to_layer || element.type !== rule.to_type) changedElements++;
    for (const [offset, value] of [[element.layerOffset, rule.to_layer], [element.typeOffset, rule.to_type]]) {
      if (expected.readUInt16BE(offset) !== value) changedRecords++;
      expected.writeUInt16BE(value, offset);
    }
  }
  if (!expected.equals(inputs.output)) throw new Error('Physical output differs outside the exact simultaneous tag replacements.');
  if (changedElements !== report.changed_elements) throw new Error('Changed element count differs from physical records.');
  const changedOffsets = [];
  for (let i = 0; i < expected.length; i++) if (inputs.source[i] !== inputs.output[i]) changedOffsets.push(i);
  process.stdout.write(JSON.stringify({ schema: 'gdsii-layer-remap-received-v1', inputs_verified: true,
    changed_elements: changedElements, changed_records: changedRecords, changed_payload_offsets: changedOffsets,
    record_count: after.records.length, padding_bytes: after.padding, cells: after.cells,
    elements: after.elements.map(({ layerOffset, typeOffset, ...entry }) => entry) }) + '\n');
} catch (error) { process.stdout.write(JSON.stringify({ error: { stage: 'receiver', message: error.message } }) + '\n'); process.exitCode = 2; }
