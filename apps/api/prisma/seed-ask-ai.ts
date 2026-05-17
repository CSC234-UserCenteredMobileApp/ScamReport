// Seed Ask AI conversations + messages.
//
// Direct DB inserts (no Gemini calls). The Ask AI service has no Firestore
// mirror, no FCM, no moderation side-effects — the only "flow" is the
// append-only message rows + lastMessageAt timestamp update. Bypassing the
// live AI saves ~80 Gemini generation calls per seed run.
//
// For conversations linked to a scammer (via fixtures.AI_CONVERSATIONS),
// we look up one verified report tied to that scammer's displayName and
// attach it as `linked_report_id`. Lets the admin "conversation → report"
// bridge surface in the seeded data.

import { PrismaPg } from '@prisma/adapter-pg';
import { config } from 'dotenv';
import { resolve } from 'path';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { assertSafeToSeed } from './safety';
import { AI_CONVERSATIONS, scammerByKey } from './seed-fixtures';

config({ path: resolve(import.meta.dirname, '../.env') });

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL! });
const prisma = new PrismaClient({ adapter });

async function loadReporterIds(): Promise<string[]> {
  const users = await prisma.user.findMany({
    where: { firebaseUid: { startsWith: 'synthetic-user-' }, role: 'user' },
    select: { id: true },
  });
  if (users.length === 0) {
    throw new Error('seed-ask-ai: run seed-users.ts first — no synthetic users found');
  }
  return users.map((u) => u.id);
}

async function findVerifiedReportByScammerKey(key: string): Promise<string | null> {
  const scammer = scammerByKey(key);
  if (!scammer) return null;
  const row = await prisma.report.findFirst({
    where: {
      status: 'verified',
      scammer: { displayName: scammer.displayName },
    },
    orderBy: { createdAt: 'desc' },
    select: { id: true },
  });
  return row?.id ?? null;
}

async function main() {
  await assertSafeToSeed();
  const reporters = await loadReporterIds();
  let conversations = 0;
  let messages = 0;

  for (let i = 0; i < AI_CONVERSATIONS.length; i++) {
    const script = AI_CONVERSATIONS[i]!;
    const userId = reporters[i % reporters.length]!;
    const linkedReportId = script.linkedScammerKey
      ? await findVerifiedReportByScammerKey(script.linkedScammerKey)
      : null;

    const createdAt = new Date(Date.now() - (i * 5 + 3) * 24 * 60 * 60 * 1000);
    const messageGapMs = 90 * 1000;

    const draftState = script.draft && linkedReportId
      ? {
          // Lightweight draft shape — enough to exercise the
          // "conversation has a draft" branch in the Ask AI UI.
          version: 1,
          title: 'Draft from AI conversation',
          description: 'Draft assembled from the conversation context.',
          scamTypeCode: 'phone_impersonation',
          targetIdentifier: null,
          targetIdentifierKind: null,
          evidenceAttachmentIds: [],
        }
      : null;

    const conv = await prisma.aiConversation.create({
      data: {
        userId,
        linkedReportId,
        createdAt,
        lastMessageAt: new Date(createdAt.getTime() + script.messages.length * messageGapMs),
        draftState: draftState as never,
      },
      select: { id: true },
    });
    conversations++;

    for (let mi = 0; mi < script.messages.length; mi++) {
      const m = script.messages[mi]!;
      await prisma.aiMessage.create({
        data: {
          conversationId: conv.id,
          role: m.role,
          content: m.content,
          intentDetected: !!m.intentDetected,
          createdAt: new Date(createdAt.getTime() + mi * messageGapMs),
        },
      });
      messages++;
    }
  }

  console.log(`seed-ask-ai: conversations=${conversations} messages=${messages}`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
