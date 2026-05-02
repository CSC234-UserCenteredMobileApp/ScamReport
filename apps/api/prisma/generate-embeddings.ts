// Generates pgvector embeddings for all verified reports.
// Run from repo root: bun apps/api/prisma/generate-embeddings.ts
//
// Idempotent: skips reports whose content hash matches stored hash.
// Uses 200ms delay between Gemini API calls to stay within rate limits.

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { config } from 'dotenv';
import { createHash } from 'crypto';
import { resolve } from 'path';
import { embed, EMBEDDING_MODEL } from '../src/core/gemini/client.js';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

function sha256(text: string): string {
  return createHash('sha256').update(text).digest('hex');
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const reports = await prisma.report.findMany({
    where: { status: 'verified' },
    select: { id: true, title: true, description: true },
  });

  const existingEmbeddings = await prisma.$queryRaw<{ report_id: string; content_hash: string }[]>`
    SELECT report_id::text, content_hash FROM report_embeddings
  `;
  const hashByReportId = new Map(existingEmbeddings.map((e) => [e.report_id, e.content_hash]));

  let generated = 0;
  let skipped = 0;

  for (const report of reports) {
    const content = report.title + '\n' + report.description;
    const hash = sha256(content);

    if (hashByReportId.get(report.id) === hash) {
      skipped++;
      continue;
    }

    const vector = await embed(content);
    const vectorLiteral = `[${vector.join(',')}]`;

    await prisma.$executeRaw`
      INSERT INTO report_embeddings (report_id, embedding, content_hash, model_version)
      VALUES (${report.id}::uuid, ${vectorLiteral}::vector, ${hash}, ${EMBEDDING_MODEL})
      ON CONFLICT (report_id) DO UPDATE SET
        embedding     = EXCLUDED.embedding,
        content_hash  = EXCLUDED.content_hash,
        model_version = EXCLUDED.model_version,
        updated_at    = now()
    `;

    generated++;
    process.stdout.write(`\rgenerate-embeddings: ${generated} generated, ${skipped} skipped`);
    await sleep(200);
  }

  console.log(`\ngenerate-embeddings: done. generated=${generated} skipped=${skipped} total=${reports.length}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
