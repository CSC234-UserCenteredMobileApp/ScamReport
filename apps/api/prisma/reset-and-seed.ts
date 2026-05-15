// One-shot orchestrator: wipe data, seed mock content, generate embeddings.
// Run from apps/api: bun run prisma/reset-and-seed.ts
//
// WARNING: irreversible — calls reset-data.ts which truncates every data table.
// Schema and scam_types reference data are preserved.

import { resolve } from 'path';

const apiRoot = resolve(import.meta.dirname, '..');

const SCRIPTS = [
  'reset-data.ts',
  'seed-reports.ts',
  'seed-scammers.ts',
  'seed-call-screening.ts',
  'seed-ai-eval.ts',
  'generate-embeddings.ts',
];

for (const name of SCRIPTS) {
  console.log(`\n=== ${name} ===`);
  const proc = Bun.spawn(['bun', 'run', `prisma/${name}`], {
    cwd: apiRoot,
    stdout: 'inherit',
    stderr: 'inherit',
  });
  const code = await proc.exited;
  if (code !== 0) {
    console.error(`reset-and-seed: ${name} exited with code ${code}`);
    process.exit(code);
  }
}

console.log('\nreset-and-seed: all steps completed.');
