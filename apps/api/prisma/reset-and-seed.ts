// One-shot orchestrator: wipe data, seed mock content via the real service
// flow, generate embeddings, recompute AI scores, seed check/Ask AI/
// announcement activity, sanity-check.
//
// Run from apps/api: bun run prisma/reset-and-seed.ts
//   - Interactive:           prompts for YES once via the safety guard.
//   - Non-interactive (CI):  SEED_CONFIRM=YES bun run prisma/reset-and-seed.ts
//
// WARNING: irreversible — calls reset-data.ts which truncates every data
// table. Schema and scam_types reference data are preserved.

import { resolve } from 'path';
import { assertSafeToSeed } from './safety';

const apiRoot = resolve(import.meta.dirname, '..');

// Run the safety prompt once here, then propagate SEED_CONFIRM=YES into the
// spawned-child env so each child script's own assertSafeToSeed() call
// passes without re-prompting. Defense-in-depth: child scripts still call
// the guard when invoked outside this orchestrator.
await assertSafeToSeed();
const childEnv = {
  ...process.env,
  SEED_CONFIRM: 'YES',
  // Propagate --allow-supabase from this process into children so each
  // child's own assertSafeToSeed() pass.
  ...(process.argv.includes('--allow-supabase') || process.env.SEED_ALLOW_SUPABASE === '1'
    ? { SEED_ALLOW_SUPABASE: '1' }
    : {}),
};

const SCRIPTS = [
  'reset-data.ts',          // truncate
  'seed-users.ts',          // users + consent + fcm devices
  'seed-scammers.ts',       // 12 offender profiles from shared fixtures
  'seed-flow.ts',           // ~122 reports via createReport + approve/reject/flag + backdate
  'generate-embeddings.ts', // fill report_embeddings for verified reports
  'recompute-ai-scores.ts', // re-run computeAiScore now that the corpus is populated
  'seed-check-logs.ts',     // ~450 runCheck() invocations
  'seed-ask-ai.ts',         // 10 conversations + messages (direct DB)
  'seed-announcements.ts',  // 6 announcements via publishAnnouncement
  'verify-seed.ts',         // sanity counts — exits non-zero on missing data
];

for (const name of SCRIPTS) {
  console.log(`\n=== ${name} ===`);
  const proc = Bun.spawn(['bun', 'run', `prisma/${name}`], {
    cwd: apiRoot,
    stdout: 'inherit',
    stderr: 'inherit',
    env: childEnv,
  });
  const code = await proc.exited;
  if (code !== 0) {
    console.error(`reset-and-seed: ${name} exited with code ${code}`);
    process.exit(code);
  }
}

console.log('\nreset-and-seed: all steps completed.');
