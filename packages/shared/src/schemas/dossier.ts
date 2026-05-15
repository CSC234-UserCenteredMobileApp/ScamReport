import { Type, type Static } from '@sinclair/typebox';
import { ScammerProfile } from './scammers';

export const DossierEvidenceFile = Type.Object({
  id: Type.String({ format: 'uuid' }),
  signedUrl: Type.Union([Type.String(), Type.Null()]),
  kind: Type.Union([Type.Literal('image'), Type.Literal('pdf')]),
  mimeType: Type.String(),
});
export type DossierEvidenceFile = Static<typeof DossierEvidenceFile>;

export const DossierCase = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  description: Type.String(),
  scamTypeCode: Type.String(),
  scamTypeLabelEn: Type.String(),
  scamTypeLabelTh: Type.String(),
  status: Type.String(),
  targetIdentifier: Type.Union([Type.String(), Type.Null()]),
  createdAt: Type.String({ format: 'date-time' }),
  verifiedAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  aiScore: Type.Union([Type.Integer({ minimum: 0, maximum: 100 }), Type.Null()]),
  aiConfidence: Type.Union([Type.String(), Type.Null()]),
  evidenceFiles: Type.Array(DossierEvidenceFile),
});
export type DossierCase = Static<typeof DossierCase>;

export const DossierCheckHit = Type.Object({
  inputNormalized: Type.String(),
  inputKind: Type.String(),
  verdict: Type.String(),
  matchCount: Type.Integer({ minimum: 0 }),
  createdAt: Type.String({ format: 'date-time' }),
});
export type DossierCheckHit = Static<typeof DossierCheckHit>;

export const DossierAggregates = Type.Object({
  totalCases: Type.Integer({ minimum: 0 }),
  verifiedCases: Type.Integer({ minimum: 0 }),
  pendingCases: Type.Integer({ minimum: 0 }),
  rejectedCases: Type.Integer({ minimum: 0 }),
  caseChannels: Type.Array(
    Type.Object({ kind: Type.String(), count: Type.Integer({ minimum: 0 }) }),
  ),
  scamTypeBreakdown: Type.Array(
    Type.Object({
      scamTypeCode: Type.String(),
      labelEn: Type.String(),
      count: Type.Integer({ minimum: 0 }),
    }),
  ),
  distinctReporters: Type.Integer({ minimum: 0 }),
});
export type DossierAggregates = Static<typeof DossierAggregates>;

export const DossierAiStats = Type.Object({
  avgAiScore: Type.Union([Type.Number(), Type.Null()]),
  lastAiScore: Type.Union([Type.Integer(), Type.Null()]),
  highCount: Type.Integer({ minimum: 0 }),
  mediumCount: Type.Integer({ minimum: 0 }),
  lowCount: Type.Integer({ minimum: 0 }),
  unknownCount: Type.Integer({ minimum: 0 }),
});
export type DossierAiStats = Static<typeof DossierAiStats>;

export const ScammerDossierResponse = Type.Object({
  scammer: ScammerProfile,
  cases: Type.Array(DossierCase),
  recentCheckHits: Type.Array(DossierCheckHit),
  aggregates: DossierAggregates,
  aiStats: DossierAiStats,
  generatedAt: Type.String({ format: 'date-time' }),
});
export type ScammerDossierResponse = Static<typeof ScammerDossierResponse>;

// Platform summary --------------------------------------------------------

export const PlatformSummaryRange = Type.Object({
  from: Type.String({ format: 'date-time' }),
  to: Type.String({ format: 'date-time' }),
});

export const TopScammer = Type.Object({
  id: Type.String({ format: 'uuid' }),
  displayName: Type.String(),
  reportCount: Type.Integer({ minimum: 0 }),
  riskLevel: Type.String(),
});

export const TopIdentifier = Type.Object({
  kind: Type.String(),
  valueNormalized: Type.String(),
  reportCount: Type.Integer({ minimum: 0 }),
});

export const VerdictMix = Type.Object({
  scam: Type.Integer({ minimum: 0 }),
  suspicious: Type.Integer({ minimum: 0 }),
  safe: Type.Integer({ minimum: 0 }),
  unknown: Type.Integer({ minimum: 0 }),
});

export const PlatformSummaryResponse = Type.Object({
  range: PlatformSummaryRange,
  reports: Type.Object({
    total: Type.Integer({ minimum: 0 }),
    verified: Type.Integer({ minimum: 0 }),
    pending: Type.Integer({ minimum: 0 }),
    rejected: Type.Integer({ minimum: 0 }),
    flagged: Type.Integer({ minimum: 0 }),
  }),
  scamTypeBreakdown: Type.Array(
    Type.Object({
      scamTypeCode: Type.String(),
      labelEn: Type.String(),
      count: Type.Integer({ minimum: 0 }),
    }),
  ),
  topScammers: Type.Array(TopScammer),
  topIdentifiers: Type.Array(TopIdentifier),
  checkLogs: Type.Object({
    total: Type.Integer({ minimum: 0 }),
    verdictMix: VerdictMix,
  }),
  aiScoreDistribution: Type.Object({
    high: Type.Integer({ minimum: 0 }),
    medium: Type.Integer({ minimum: 0 }),
    low: Type.Integer({ minimum: 0 }),
    unknown: Type.Integer({ minimum: 0 }),
  }),
  latestEval: Type.Union([
    Type.Object({
      runAt: Type.String({ format: 'date-time' }),
      verdictAccuracy: Type.Number(),
      scammerRecallAt1: Type.Number(),
      scammerMrr: Type.Number(),
      missingFactsF1: Type.Number(),
      p95LatencyMs: Type.Integer(),
    }),
    Type.Null(),
  ]),
  generatedAt: Type.String({ format: 'date-time' }),
});
export type PlatformSummaryResponse = Static<typeof PlatformSummaryResponse>;
