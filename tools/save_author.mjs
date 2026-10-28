// Materialize cmd/author's documented byte arrays into a new directory.
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

let stage = 'request';
try {
  if (process.argv.length !== 3) {
    throw Object.assign(new Error('Usage: moon run cmd/author --target js | node tools/save_author.mjs NEW_DIRECTORY'), { code: 'USAGE' });
  }
  stage = 'input';
  const authored = JSON.parse(readFileSync(0, 'utf8').replace(/^\uFEFF/, ''));
  if (authored?.schema !== 'gdsii-author-v1') throw new Error('Expected cmd/author schema gdsii-author-v1.');
  const snapshots = ['before', 'after'].map(side => {
    const bytes = authored[side]?.bytes;
    if (!Array.isArray(bytes) || bytes.length === 0 || !bytes.every(value => Number.isInteger(value) && value >= 0 && value <= 255)) {
      throw new Error(`${side}.bytes must be a nonempty array of byte integers.`);
    }
    return { side, bytes: Buffer.from(bytes) };
  });
  const directory = resolve(process.argv[2]);
  stage = 'output';
  mkdirSync(directory); // A fresh directory is required; never overwrite a pair.
  const files = snapshots.map(({ side, bytes }) => {
    const path = join(directory, `${side}.gds`);
    writeFileSync(path, bytes, { flag: 'wx' });
    return { side, path, bytes: bytes.length };
  });
  process.stdout.write(JSON.stringify({ directory, files }) + '\n');
} catch (error) {
  process.stdout.write(JSON.stringify({ error: { stage, code: error.code ?? 'AUTHOR_OUTPUT_INVALID', message: error.message } }) + '\n');
  process.exitCode = 2;
}
