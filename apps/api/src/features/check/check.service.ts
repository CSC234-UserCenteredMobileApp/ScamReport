import { getPrisma } from '../../core/db/client';
import { generateText } from '../../core/gemini/client';
import { normalizePhone, normalizeUrl } from '../../core/lib/identifier-extractor';
import { searchSimilarReports } from '../../core/rag/retrieval';
import {
  THRESHOLD_SCAMMER_CLUSTER,
} from '../../core/ai-score/constants';
import type {
  CheckResponse,
  MatchedScammer,
  ReportSummary,
  ScammerIdentifierKind,
} from '@my-product/shared';

const SCAMMER_RECENT_CASE_LIMIT = 5;

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

/**
 * Compose a MatchedScammer payload from a scammer id by loading the profile
 * + its most recent verified cases. Returns null when the scammer no longer
 * exists (e.g. the link survived a hard-delete race) so callers can degrade.
 */
async function loadMatchedScammer(scammerId: string): Promise<MatchedScammer | null> {
  const prisma = getPrisma();
  const scammer = await prisma.scammer.findUnique({
    where: { id: scammerId },
    include: {
      person: {
        select: {
          id: true,
          fullName: true,
          riskLevel: true,
          campaignCountCache: true,
        },
      },
      reports: {
        where: { status: 'verified' },
        orderBy: { verifiedAt: 'desc' },
        take: SCAMMER_RECENT_CASE_LIMIT,
        select: {
          id: true,
          title: true,
          verifiedAt: true,
          scamType: { select: { code: true } },
        },
      },
    },
  });
  if (!scammer) return null;
  return toMatchedScammer(
    {
      id: scammer.id,
      displayName: scammer.displayName,
      suspectedName: scammer.suspectedName,
      person: scammer.person,
      aliases: scammer.aliases,
      riskLevel: scammer.riskLevel,
      reportCountCache: scammer.reportCountCache,
    },
    scammer.reports.map((r) => ({
      id: r.id,
      title: r.title,
      verifiedAt: r.verifiedAt,
      scamTypeCode: r.scamType.code,
    })),
  );
}

function toMatchedScammer(
  s: {
    id: string;
    displayName: string;
    suspectedName: string | null;
    person: {
      id: string;
      fullName: string;
      riskLevel: string;
      campaignCountCache: number;
    } | null;
    aliases: string[];
    riskLevel: string;
    reportCountCache: number;
  },
  cases: Array<{ id: string; title: string; verifiedAt: Date | null; scamTypeCode: string }>,
): MatchedScammer {
  // Top scam-type codes derived from the recent cases. Deduped, preserving
  // recency order. Bounded by SCAMMER_RECENT_CASE_LIMIT so it stays small.
  const top: string[] = [];
  for (const c of cases) {
    if (!top.includes(c.scamTypeCode)) top.push(c.scamTypeCode);
  }
  return {
    summary: {
      id: s.id,
      displayName: s.displayName,
      suspectedName: s.suspectedName,
      person: s.person
        ? {
            id: s.person.id,
            fullName: s.person.fullName,
            riskLevel: s.person.riskLevel as MatchedScammer['summary']['riskLevel'],
            campaignCount: s.person.campaignCountCache,
          }
        : null,
      aliases: s.aliases,
      riskLevel: s.riskLevel as MatchedScammer['summary']['riskLevel'],
      reportCount: s.reportCountCache,
      topScamTypeCodes: top,
    },
    recentCases: cases
      .filter((c): c is typeof c & { verifiedAt: Date } => c.verifiedAt !== null)
      .map((c) => ({
        id: c.id,
        title: c.title,
        scamTypeCode: c.scamTypeCode,
        verifiedAt: c.verifiedAt.toISOString(),
      })),
  };
}

function inputKindToScammerKind(
  type: 'phone' | 'url' | 'text',
): ScammerIdentifierKind | null {
  if (type === 'phone') return 'phone';
  if (type === 'url') return 'url';
  return null;
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
  let matchedScammer: MatchedScammer | null = null;

  // Phase 1a — scammer identifier lookup (phone/url). Authoritative when
  // hit: load the offender + its recent linked verified cases.
  const scammerKind = inputKindToScammerKind(type);
  if (scammerKind !== null) {
    const idRow = await prisma.scammerIdentifier.findUnique({
      where: {
        kind_valueNormalized: { kind: scammerKind, valueNormalized: normalized },
      },
      select: { scammerId: true },
    });
    if (idRow) {
      matchedScammer = await loadMatchedScammer(idRow.scammerId);
      if (matchedScammer && matchedScammer.recentCases.length > 0) {
        matches = matchedScammer.recentCases
          .filter((c): c is typeof c & { verifiedAt: string } => c.verifiedAt !== null)
          .map((c) => ({
            id: c.id,
            title: c.title,
            scamType: c.scamTypeCode,
            verifiedAt: c.verifiedAt,
          }));
        verdict = 'scam';
      }
    }
  }

  // Phase 1b — fallback to legacy report-level identifier match. Catches
  // verified reports whose moderator hasn't linked a scammer yet.
  if (matches.length === 0 && (type === 'phone' || type === 'url')) {
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

  // Phase 2 — semantic similarity for text, or when no identifier match found.
  const needsSemantic = type === 'text' || matches.length === 0;
  if (needsSemantic) {
    try {
      const results = await searchSimilarReports(payload, 5);
      const top = results[0];
      if (top !== undefined && top.similarity >= 0.8) {
        verdict = 'suspicious';

        // Scammer-cluster signal: 2+ of the semantic top-K share a scammerId.
        // Counts as scam (a known offender is implicated, not just lexical
        // proximity).
        if (matchedScammer === null) {
          const counts = new Map<string, number>();
          for (const r of results) {
            if (!r.scammerId) continue;
            counts.set(r.scammerId, (counts.get(r.scammerId) ?? 0) + 1);
          }
          let bestId: string | null = null;
          let bestCount = 0;
          for (const [id, n] of counts) {
            if (n > bestCount) {
              bestId = id;
              bestCount = n;
            }
          }
          if (bestId && bestCount >= THRESHOLD_SCAMMER_CLUSTER) {
            matchedScammer = await loadMatchedScammer(bestId);
            if (matchedScammer && matchedScammer.recentCases.length > 0) {
              verdict = 'scam';
            }
          }
        }

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

  return {
    verdict,
    matchedCount: matches.length,
    matches,
    matchedScammer,
  };
}
