import { getPrisma } from '../../core/db/client';
import { generateText } from '../../core/gemini/client';
import { searchSimilarReports } from '../../core/rag/retrieval';
import type { CheckResponse, ReportSummary } from '@my-product/shared';

function normalizePhone(raw: string): string {
  const stripped = raw.replace(/[\s\-\(\)]/g, '');
  if (/^0\d{8,9}$/.test(stripped)) return '+66' + stripped.slice(1);
  return stripped;
}

function normalizeUrl(raw: string): string {
  try {
    const url = new URL(raw.startsWith('http') ? raw : 'https://' + raw);
    return url.hostname.toLowerCase();
  } catch (_e) {
    return raw.toLowerCase().trim();
  }
}

async function hashInput(text: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function analyzeWithAI(
  payload: string,
  type: 'text' | 'url',
): Promise<'scam' | 'suspicious' | 'safe' | 'unknown'> {
  const subject = type === 'url' ? 'URL' : 'SMS message';
  const context = type === 'url' ? `URL to analyze: ${payload}` : `SMS message body: ${payload}`;
  const prompt = `You are a scam detection assistant. Analyze the following ${subject} and classify it.

${context}

Respond with ONLY a JSON object in this exact format (no explanation, no markdown):
{"verdict":"scam"|"suspicious"|"safe","reason":"one sentence"}

Criteria:
- "scam": clear attempt to defraud (phishing link, urgent money transfer, fake authority)
- "suspicious": potentially harmful but not certain (unusual request, unfamiliar sender pattern)
- "safe": normal, benign content`;

  try {
    const raw = await generateText(prompt);
    const cleaned = raw.replace(/```json?\n?|```/g, '').trim();
    const parsed = JSON.parse(cleaned) as { verdict: string };
    if (['scam', 'suspicious', 'safe'].includes(parsed.verdict)) {
      return parsed.verdict as 'scam' | 'suspicious' | 'safe';
    }
    return 'unknown';
  } catch (_e) {
    return 'unknown';
  }
}

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
  return [...new Set(rows.map((r) => r.targetIdentifierNormalized as string))];
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

    matches = rows
      .filter((r): r is typeof r & { verifiedAt: Date } => r.verifiedAt !== null)
      .map((r) => ({
        id: r.id,
        title: r.title,
        scamType: r.scamType.code,
        verifiedAt: r.verifiedAt.toISOString(),
      }));

    if (matches.length >= 1) verdict = 'scam';
  }

  // Phase 2 — semantic similarity for text, or when no identifier match found
  const needsSemantic = type === 'text' || matches.length === 0;
  if (needsSemantic) {
    try {
      const results = await searchSimilarReports(payload, 5);
      const top = results[0];
      if (top !== undefined && top.similarity >= 0.7) {
        verdict = 'suspicious';
        const topIds = results.slice(0, 3).map((r) => r.reportId);
        const semanticRows = await prisma.report.findMany({
          where: { id: { in: topIds }, status: 'verified' },
          select: {
            id: true,
            title: true,
            scamType: { select: { code: true } },
            verifiedAt: true,
          },
        });
        matches = semanticRows
          .filter((r): r is typeof r & { verifiedAt: Date } => r.verifiedAt !== null)
          .map((r) => ({
            id: r.id,
            title: r.title,
            scamType: r.scamType.code,
            verifiedAt: r.verifiedAt.toISOString(),
          }));
      } else {
        verdict = type === 'text' ? 'unknown' : 'safe';
      }
    } catch (_e) {
      // Gemini unavailable or no embeddings — fall back gracefully
      if (type === 'text') verdict = 'unknown';
    }
  }

  // Phase 3 — Gemini AI content analysis (always for text/url)
  if (type === 'text' || type === 'url') {
    const aiVerdict = await analyzeWithAI(payload, type);
    if (aiVerdict === 'scam' && verdict !== 'scam') verdict = 'scam';
    else if (aiVerdict === 'suspicious' && (verdict === 'safe' || verdict === 'unknown')) verdict = 'suspicious';
    else if (aiVerdict === 'safe' && verdict === 'unknown') verdict = 'safe';
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
  } catch (_e) {
    // Log write failure must never surface to the caller
  }

  return { verdict, matchedCount: matches.length, matches };
}
