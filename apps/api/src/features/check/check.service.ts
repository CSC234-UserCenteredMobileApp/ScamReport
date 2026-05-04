import { getPrisma } from '../../core/db/client';
import { searchSimilarReports } from '../../core/rag/retrieval';
import type { CheckResponse, ReportSummary } from '@my-product/shared';

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

function normalizePhone(raw: string): string {
  const stripped = raw.replace(/[\s\-\(\)]/g, '');
  // Thai local format 0XX → E.164 +66XX
  if (/^0\d{8,9}$/.test(stripped)) return '+66' + stripped.slice(1);
  return stripped;
}

function normalizeUrl(raw: string): string {
  try {
    const url = new URL(raw.startsWith('http') ? raw : 'https://' + raw);
    return url.hostname.toLowerCase();
  } catch {
    return raw.toLowerCase().trim();
  }
}

async function hashInput(text: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export async function runCheck(
  payload: string,
  type: 'phone' | 'url' | 'text',
  userId?: string | null,
): Promise<CheckResponse> {
  const start = Date.now();
  const prisma = getPrisma();

  const normalized =
    type === 'phone'
      ? normalizePhone(payload)
      : type === 'url'
        ? normalizeUrl(payload)
        : payload.trim();

  let verdict: 'scam' | 'suspicious' | 'safe' | 'unknown' = 'safe';
  let matches: ReportSummary[] = [];

  // Phase 1 — exact identifier lookup for phone/url
  if (type === 'phone' || type === 'url') {
    const rows = await prisma.report.findMany({
      where: { status: 'verified', targetIdentifierNormalized: normalized },
      orderBy: { verifiedAt: 'desc' },
      take: 10,
      select: {
        id: true,
        title: true,
        scamType: { select: { code: true } },
        verifiedAt: true,
      },
    });

    matches = rows.map((r) => ({
      id: r.id,
      title: r.title,
      scamType: r.scamType.code,
      verifiedAt: r.verifiedAt!.toISOString(),
    }));

    if (matches.length >= 1) verdict = 'scam';
  }

  // Phase 2 — semantic fallback for text, or when no identifier match found
  const needsSemantic = type === 'text' || matches.length === 0;
  if (needsSemantic) {
    try {
      const results = await searchSimilarReports(payload, 5);
      const top = results[0];
      if (top !== undefined && top.similarity >= 0.7) {
        verdict = 'suspicious';
        const topIds = results.slice(0, 3).map((r) => r.reportId);
        const rows = await prisma.report.findMany({
          where: { id: { in: topIds }, status: 'verified' },
          select: {
            id: true,
            title: true,
            scamType: { select: { code: true } },
            verifiedAt: true,
          },
        });
        matches = rows.map((r) => ({
          id: r.id,
          title: r.title,
          scamType: r.scamType.code,
          verifiedAt: r.verifiedAt!.toISOString(),
        }));
      } else {
        verdict = 'safe';
      }
    } catch {
      // Gemini unavailable or no embeddings — fall back gracefully
      verdict = type === 'text' ? 'unknown' : verdict;
    }
  }

  // Write check_log — non-fatal
  try {
    const hash = await hashInput(payload);
    await prisma.checkLog.create({
      data: {
        userId: userId ?? null,
        inputKind: type,
        inputNormalized: normalized,
        inputHash: hash,
        verdict,
        matchCount: matches.length,
        latencyMs: Date.now() - start,
      },
    });
  } catch {
    // Log write failure must never surface to the caller
  }

  return { verdict, matchedCount: matches.length, matches };
}
