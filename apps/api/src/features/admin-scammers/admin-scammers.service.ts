// =============================================================================
// admin-scammers.service — orchestrates scammer profile reads + dossier export.
// =============================================================================

import type {
  DossierAggregates,
  DossierAiStats,
  DossierCase,
  DossierCheckHit,
  DossierEvidenceFile,
  ScammerDossierResponse,
  ScammerProfile,
  ScammerProfileSummary,
  SearchScammersResponse,
  LinkScammerRequest,
  LinkScammerResponse,
  ScammerIdentifier as SharedScammerIdentifier,
} from '@my-product/shared';
import { getSignedUrl } from '../../core/supabase/storage';
import { normalizePhone, normalizeUrl } from '../../core/lib/identifier-extractor';
import {
  createScammer,
  findById,
  linkReportToScammer,
  listLinkedReports,
  listRecentCheckHits,
  searchCandidates,
} from './admin-scammers.repo';

const EVIDENCE_BUCKET = 'evidence';
const EVIDENCE_URL_TTL_SECONDS = 3600;

export class AdminScammerError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly code: string,
  ) {
    super(message);
    this.name = 'AdminScammerError';
  }
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

export async function search(
  identifier?: string,
  q?: string,
): Promise<SearchScammersResponse> {
  // Caller passes a raw identifier — normalise it the same way the verdict
  // pipeline does so admin lookups match auto-link results.
  let normIdentifier: string | undefined;
  if (identifier) {
    const trimmed = identifier.trim();
    if (trimmed.startsWith('+') || /^\d/.test(trimmed)) {
      normIdentifier = normalizePhone(trimmed);
    } else if (trimmed.includes('.') || trimmed.startsWith('http')) {
      normIdentifier = normalizeUrl(trimmed);
    } else {
      normIdentifier = trimmed.toLowerCase();
    }
  }
  const rows = await searchCandidates({ identifier: normIdentifier, q });
  const items: ScammerProfileSummary[] = rows.map((r) => ({
    id: r.id,
    displayName: r.displayName,
    suspectedName: r.suspectedName,
    aliases: r.aliases,
    riskLevel: r.riskLevel as ScammerProfileSummary['riskLevel'],
    reportCount: r.reportCountCache,
    topScamTypeCodes: [],
  }));
  return { items };
}

// ---------------------------------------------------------------------------
// Link
// ---------------------------------------------------------------------------

export async function linkScammer(
  reportId: string,
  payload: LinkScammerRequest,
): Promise<LinkScammerResponse> {
  let scammerId: string;
  if ('scammerId' in payload) {
    scammerId = payload.scammerId;
  } else {
    const identifiers = (payload.createNew.identifiers ?? []).map((id) => ({
      kind: id.kind,
      valueRaw: id.valueRaw,
      valueNormalized: normaliseIdentifier(id.kind, id.valueRaw),
    }));
    scammerId = await createScammer({
      displayName: payload.createNew.displayName,
      aliases: payload.createNew.aliases ?? [],
      riskLevel: payload.createNew.riskLevel,
      notes: payload.createNew.notes,
      identifiers,
    });
  }
  const ok = await linkReportToScammer(reportId, scammerId);
  if (!ok) {
    throw new AdminScammerError('Report not found', 404, 'not_found');
  }
  return { reportId, scammerId };
}

function normaliseIdentifier(kind: string, raw: string): string {
  const t = raw.trim();
  if (kind === 'phone') return normalizePhone(t);
  if (kind === 'url') return normalizeUrl(t);
  return t.toLowerCase();
}

// ---------------------------------------------------------------------------
// Dossier
// ---------------------------------------------------------------------------

export async function getDossier(
  scammerId: string,
): Promise<ScammerDossierResponse | null> {
  const scammer = await findById(scammerId);
  if (!scammer) return null;

  const reports = await listLinkedReports(scammerId);

  // Sign evidence URLs lazily. Per-file failure leaves signedUrl null; the
  // print template renders a placeholder.
  const cases: DossierCase[] = await Promise.all(
    reports.map(async (r) => {
      const evidenceFiles: DossierEvidenceFile[] = await Promise.all(
        r.evidenceFiles.map(async (f) => {
          let signedUrl: string | null = null;
          try {
            signedUrl = await getSignedUrl(EVIDENCE_BUCKET, f.storagePath, EVIDENCE_URL_TTL_SECONDS);
          } catch (err) {
            console.error('[admin-scammers] dossier sign url failed', {
              scammerId,
              reportId: r.id,
              fileId: f.id,
              err,
            });
          }
          return {
            id: f.id,
            signedUrl,
            kind: f.kind as 'image' | 'pdf',
            mimeType: f.mimeType,
          };
        }),
      );
      return {
        id: r.id,
        title: r.title,
        description: r.description,
        scamTypeCode: r.scamType.code,
        scamTypeLabelEn: r.scamType.labelEn,
        scamTypeLabelTh: r.scamType.labelTh,
        status: r.status,
        targetIdentifier: r.targetIdentifier,
        createdAt: r.createdAt.toISOString(),
        verifiedAt: r.verifiedAt?.toISOString() ?? null,
        aiScore: r.aiScore,
        aiConfidence: r.aiConfidence,
        evidenceFiles,
      };
    }),
  );

  // Recent check hits on any of the scammer's identifiers.
  const normalisedValues = scammer.identifiers.map((i) => i.valueNormalized);
  const checkHits = await listRecentCheckHits(normalisedValues);
  const recentCheckHits: DossierCheckHit[] = checkHits.map((h) => ({
    inputNormalized: h.inputNormalized,
    inputKind: h.inputKind,
    verdict: h.verdict,
    matchCount: h.matchCount,
    createdAt: h.createdAt.toISOString(),
  }));

  const aggregates = computeAggregates(scammer.identifiers, reports);
  const aiStats = computeAiStats(reports);

  const identifiers: SharedScammerIdentifier[] = scammer.identifiers.map((i) => ({
    id: i.id,
    kind: i.kind as SharedScammerIdentifier['kind'],
    valueRaw: i.valueRaw,
    valueNormalized: i.valueNormalized,
  }));

  const profile: ScammerProfile = {
    id: scammer.id,
    displayName: scammer.displayName,
    suspectedName: scammer.suspectedName,
    aliases: scammer.aliases,
    riskLevel: scammer.riskLevel as ScammerProfile['riskLevel'],
    notes: scammer.notes,
    reportCount: scammer.reportCountCache,
    identifiers,
    firstSeenAt: scammer.firstSeenAt?.toISOString() ?? null,
    lastSeenAt: scammer.lastSeenAt?.toISOString() ?? null,
    createdAt: scammer.createdAt.toISOString(),
  };

  return {
    scammer: profile,
    cases,
    recentCheckHits,
    aggregates,
    aiStats,
    generatedAt: new Date().toISOString(),
  };
}

function computeAggregates(
  identifiers: { kind: string }[],
  reports: Array<{
    status: string;
    scamType: { code: string; labelEn: string };
    reporterId: string | null;
  }>,
): DossierAggregates {
  const channelCount = new Map<string, number>();
  for (const i of identifiers) channelCount.set(i.kind, (channelCount.get(i.kind) ?? 0) + 1);

  const scamTypeCount = new Map<string, { labelEn: string; count: number }>();
  let verified = 0;
  let pending = 0;
  let rejected = 0;
  const reporters = new Set<string>();
  for (const r of reports) {
    if (r.status === 'verified') verified++;
    else if (r.status === 'pending' || r.status === 'flagged') pending++;
    else if (r.status === 'rejected') rejected++;
    const existing = scamTypeCount.get(r.scamType.code);
    if (existing) {
      existing.count++;
    } else {
      scamTypeCount.set(r.scamType.code, { labelEn: r.scamType.labelEn, count: 1 });
    }
    if (r.reporterId) reporters.add(r.reporterId);
  }
  return {
    totalCases: reports.length,
    verifiedCases: verified,
    pendingCases: pending,
    rejectedCases: rejected,
    caseChannels: Array.from(channelCount.entries()).map(([kind, count]) => ({ kind, count })),
    scamTypeBreakdown: Array.from(scamTypeCount.entries()).map(([code, v]) => ({
      scamTypeCode: code,
      labelEn: v.labelEn,
      count: v.count,
    })),
    distinctReporters: reporters.size,
  };
}

function computeAiStats(
  reports: Array<{ aiScore: number | null; aiConfidence: string | null }>,
): DossierAiStats {
  const scores = reports.map((r) => r.aiScore).filter((s): s is number => s !== null);
  const avgAiScore = scores.length > 0
    ? scores.reduce((a, b) => a + b, 0) / scores.length
    : null;
  const lastAiScore = scores.length > 0 ? scores[0]! : null;
  let high = 0;
  let medium = 0;
  let low = 0;
  let unknown = 0;
  for (const r of reports) {
    if (r.aiConfidence === 'high') high++;
    else if (r.aiConfidence === 'medium') medium++;
    else if (r.aiConfidence === 'low') low++;
    else unknown++;
  }
  return {
    avgAiScore: avgAiScore === null ? null : Math.round(avgAiScore * 10) / 10,
    lastAiScore,
    highCount: high,
    mediumCount: medium,
    lowCount: low,
    unknownCount: unknown,
  };
}
