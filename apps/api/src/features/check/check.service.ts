import { createHash } from 'crypto';
import { getPrisma } from '../../core/db/client';
import { searchSimilarReports } from '../../core/rag/retrieval';
import type { CheckResponse, Verdict } from '@my-product/shared';

const SCAM_SIMILARITY = 0.85;
const SUSPICIOUS_SIMILARITY = 0.70;

export async function getScamPhones(): Promise<string[]> {
  const prisma = getPrisma();
  const rows = await prisma.report.findMany({
    where: {
      status: 'verified',
      targetIdentifierKind: 'phone',
      targetIdentifierNormalized: { not: null },
    },
    select: { targetIdentifierNormalized: true },
  });

  const phones = [
    ...new Set(rows.map((r) => r.targetIdentifierNormalized as string)),
  ];
  return phones;
}

export async function checkText(payload: string, userId?: string): Promise<CheckResponse> {
  const prisma = getPrisma();

  let similar: Awaited<ReturnType<typeof searchSimilarReports>> = [];
  try {
    similar = await searchSimilarReports(payload, 5);
  } catch {
    // Gemini unavailable — fall back to unknown
  }

  const topSimilarity = similar[0]?.similarity ?? 0;
  const verdict: Verdict =
    topSimilarity >= SCAM_SIMILARITY
      ? 'scam'
      : topSimilarity >= SUSPICIOUS_SIMILARITY
        ? 'suspicious'
        : 'unknown';

  const matchedIds = similar
    .filter((r) => r.similarity >= SUSPICIOUS_SIMILARITY)
    .map((r) => r.reportId);

  const reports =
    matchedIds.length > 0
      ? await prisma.report.findMany({
          where: { id: { in: matchedIds } },
          select: {
            id: true,
            title: true,
            verifiedAt: true,
            scamType: { select: { code: true } },
          },
        })
      : [];

  const matches = reports
    .filter((r) => r.verifiedAt !== null)
    .map((r) => ({
      id: r.id,
      title: r.title,
      scamType: r.scamType.code,
      verifiedAt: r.verifiedAt!.toISOString(),
    }));

  try {
    await prisma.checkLog.create({
      data: {
        userId: userId ?? null,
        inputKind: 'text',
        inputNormalized: payload.substring(0, 500),
        inputHash: createHash('sha256').update(payload).digest('hex'),
        verdict,
        matchCount: matches.length,
      },
    });
  } catch {
    // Log is best-effort
  }

  return { verdict, matchedCount: matches.length, matches };
}

export async function checkPhone(payload: string, userId?: string): Promise<CheckResponse> {
  const prisma = getPrisma();

  const reports = await prisma.report.findMany({
    where: {
      status: 'verified',
      targetIdentifierKind: 'phone',
      targetIdentifierNormalized: payload,
    },
    select: {
      id: true,
      title: true,
      verifiedAt: true,
      scamType: { select: { code: true } },
    },
    take: 5,
  });

  const verdict: Verdict = reports.length > 0 ? 'scam' : 'unknown';

  const matches = reports
    .filter((r) => r.verifiedAt !== null)
    .map((r) => ({
      id: r.id,
      title: r.title,
      scamType: r.scamType.code,
      verifiedAt: r.verifiedAt!.toISOString(),
    }));

  try {
    await prisma.checkLog.create({
      data: {
        userId: userId ?? null,
        inputKind: 'phone',
        inputNormalized: payload,
        inputHash: createHash('sha256').update(payload).digest('hex'),
        verdict,
        matchCount: matches.length,
      },
    });
  } catch {
    // Log is best-effort
  }

  return { verdict, matchedCount: matches.length, matches };
}

export async function checkUrl(payload: string, userId?: string): Promise<CheckResponse> {
  const prisma = getPrisma();

  let normalized = payload.toLowerCase();
  try {
    normalized = new URL(payload).hostname.toLowerCase();
  } catch {
    // Not a valid URL — use lowercased payload
  }

  const reports = await prisma.report.findMany({
    where: {
      status: 'verified',
      targetIdentifierKind: 'url',
      targetIdentifierNormalized: normalized,
    },
    select: {
      id: true,
      title: true,
      verifiedAt: true,
      scamType: { select: { code: true } },
    },
    take: 5,
  });

  const verdict: Verdict = reports.length > 0 ? 'scam' : 'unknown';

  const matches = reports
    .filter((r) => r.verifiedAt !== null)
    .map((r) => ({
      id: r.id,
      title: r.title,
      scamType: r.scamType.code,
      verifiedAt: r.verifiedAt!.toISOString(),
    }));

  try {
    await prisma.checkLog.create({
      data: {
        userId: userId ?? null,
        inputKind: 'url',
        inputNormalized: normalized,
        inputHash: createHash('sha256').update(payload).digest('hex'),
        verdict,
        matchCount: matches.length,
      },
    });
  } catch {
    // Log is best-effort
  }

  return { verdict, matchedCount: matches.length, matches };
}
