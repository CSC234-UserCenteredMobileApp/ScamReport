// Seed POST /check call history by invoking runCheck() directly.
//
// Each invocation writes a `check_logs` row naturally with realistic
// verdict, matchCount, latencyMs because retrieval is live. Inputs come
// from the AI eval case bank (25 entries) — repeated with per-user
// randomisation to produce ~450 total log rows spread across all 25 users.
//
// After the loop, backdate `created_at` across the last 90 days. The
// check_logs table has no append-only / updated_at triggers, so a plain
// UPDATE works.

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { runCheck } from '../src/features/check/check.service';
import { EVAL_CASES } from '../eval/cases';
import { assertSafeToSeed } from './safety';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

const TOTAL_INVOCATIONS = 450;

async function loadReporterIds(): Promise<string[]> {
  const users = await prisma.user.findMany({
    where: { firebaseUid: { startsWith: 'synthetic-user-' }, role: 'user' },
    select: { id: true },
  });
  if (users.length === 0) {
    throw new Error('seed-check-logs: run seed-users.ts first — no synthetic users found');
  }
  return users.map((u) => u.id);
}

async function main() {
  await assertSafeToSeed();

  const reporters = await loadReporterIds();
  let calls = 0;
  let errors = 0;

  // If the first 10 calls all fail, the underlying service is broken
  // (most likely a leaked-key Gemini 403). Abort early so the orchestrator
  // doesn't hang ~20 minutes on doomed calls. Re-run this script alone
  // after rotating the key.
  let consecutiveErrors = 0;
  const ABORT_AFTER = 10;

  for (let i = 0; i < TOTAL_INVOCATIONS; i++) {
    const c = EVAL_CASES[i % EVAL_CASES.length]!;
    const userId = reporters[i % reporters.length]!;
    try {
      await runCheck(c.inputPayload, c.inputType, userId);
      calls++;
      consecutiveErrors = 0;
    } catch (err) {
      errors++;
      consecutiveErrors++;
      if (errors <= 5) {
        console.error(`seed-check-logs: runCheck failed (${c.inputType}:${c.inputPayload}) — ${(err as Error).message}`);
      } else if (errors === 6) {
        console.error('seed-check-logs: further runCheck errors suppressed');
      }
      if (consecutiveErrors >= ABORT_AFTER) {
        console.error(`seed-check-logs: ${ABORT_AFTER} consecutive failures — bailing out. Re-run after fixing the upstream (likely Gemini key).`);
        break;
      }
    }
    if ((i + 1) % 25 === 0) {
      process.stdout.write(`\rseed-check-logs: ${i + 1}/${TOTAL_INVOCATIONS} invocations (calls=${calls} errors=${errors})`);
    }
  }
  process.stdout.write('\n');

  // Backdate across the last 90 days. check_logs has no triggers — plain
  // UPDATE is fine.
  await prisma.$executeRawUnsafe(`
    UPDATE check_logs cl
    SET created_at = now() - (random() * INTERVAL '90 days')
    WHERE id IN (
      SELECT id FROM check_logs ORDER BY created_at DESC LIMIT ${TOTAL_INVOCATIONS}
    )
  `);

  console.log(`seed-check-logs: calls=${calls} errors=${errors}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
