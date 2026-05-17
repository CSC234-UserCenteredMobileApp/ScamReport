// Recompute aiScore + aiConfidence for verified reports.
//
// Runs AFTER generate-embeddings.ts so the corpus is populated when
// computeAiScore queries searchSimilarReports. Without this pass, the first
// reports submitted during seed-flow have aiScore=null because the corpus
// they were embedded against was empty.
//
// Updates reports in place via Prisma `update` — backdated created_at /
// updated_at survive because `aiScore` and `aiConfidence` are scalar columns
// outside the timestamp trigger's WRITE set, but the trigger still re-stamps
// updated_at on the row. We accept that drift here because aiScore freshness
// is more important than preserving the seeded updated_at exactly.

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { computeAiScore, canonicalEmbedInput } from '../src/core/ai-score';
import { assertSafeToSeed } from './safety';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

async function main() {
  await assertSafeToSeed();

  // Score every report admins might see in the queue + verified ones,
  // skipping rejected (their embeddings are deleted on reject).
  const candidates = await prisma.report.findMany({
    where: {
      status: { in: ['verified', 'pending', 'flagged'] },
      aiScore: null,
    },
    select: {
      id: true,
      title: true,
      description: true,
      targetIdentifier: true,
      scamType: { select: { labelEn: true, labelTh: true } },
      scammer: {
        select: {
          displayName: true,
          aliases: true,
          person: { select: { fullName: true } },
        },
      },
    },
  });

  let updated = 0;
  let stillNull = 0;
  let failed = 0;

  for (const r of candidates) {
    const text = canonicalEmbedInput(r);
    let score: Awaited<ReturnType<typeof computeAiScore>>;
    try {
      score = await computeAiScore(text, { reportId: r.id });
    } catch (err) {
      // computeAiScore catches most errors internally and returns null;
      // this branch is for unexpected throws. Soft-fail to keep the
      // orchestrator running through a Gemini outage.
      failed++;
      console.error(`recompute-ai-scores: computeAiScore threw for ${r.id}: ${(err as Error).message}`);
      continue;
    }
    if (score.aiScore == null) {
      stillNull++;
      continue;
    }
    await prisma.report.update({
      where: { id: r.id },
      data: {
        aiScore: score.aiScore,
        aiConfidence: score.aiConfidence,
      },
    });
    updated++;
    // Throttle to stay friendly with Gemini quota.
    await new Promise((r) => setTimeout(r, 150));
  }

  console.log(`recompute-ai-scores: candidates=${candidates.length} updated=${updated} still_null=${stillNull} failed=${failed}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
