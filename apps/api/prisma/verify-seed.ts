// Quick post-seed health check. Read-only.
// Run from apps/api: bun run prisma/verify-seed.ts
import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

const counts = await prisma.$queryRaw<
  { reports: bigint; linked: bigint; scammers: bigint; identifiers: bigint; embeddings: bigint }[]
>`
  SELECT
    (SELECT COUNT(*) FROM reports) AS reports,
    (SELECT COUNT(*) FROM reports WHERE scammer_id IS NOT NULL) AS linked,
    (SELECT COUNT(*) FROM scammers) AS scammers,
    (SELECT COUNT(*) FROM scammer_identifiers) AS identifiers,
    (SELECT COUNT(*) FROM report_embeddings) AS embeddings
`;
console.log('counts:', JSON.parse(JSON.stringify(counts[0], (_, v) => typeof v === 'bigint' ? Number(v) : v)));

const perScammer = await prisma.$queryRaw<{ name: string; cases: bigint }[]>`
  SELECT s.display_name AS name, COUNT(r.id)::bigint AS cases
  FROM scammers s
  LEFT JOIN reports r ON r.scammer_id = s.id
  GROUP BY s.id
  ORDER BY cases DESC
`;
console.log('per scammer:');
for (const row of perScammer) console.log(`  ${row.name}: ${Number(row.cases)}`);

await prisma.$disconnect();
