// Truncates all data from every table. Schema and seed reference data stay intact.
// Run from repo root: bun apps/api/prisma/reset-data.ts
//
// WARNING: irreversible — all rows in every data table are permanently deleted.
// scam_types is intentionally NOT truncated (it is seed/reference data).

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

async function main() {
  await prisma.$executeRawUnsafe(`
    TRUNCATE TABLE
      ai_message_attachments,
      ai_messages,
      ai_conversations,
      report_embeddings,
      evidence_files,
      moderation_actions,
      check_logs,
      account_deletion_requests,
      fcm_devices,
      consent_records,
      reports,
      announcements,
      users
    RESTART IDENTITY CASCADE
  `);
  console.log('reset-data: all data tables truncated. Schema and scam_types intact.');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
