// Platform-wide overall summary for the admin web. Aggregates report counts,
// scam-type breakdown, top scammers + identifiers, /check call volume, AI
// score distribution, and the latest AiEvalSummary. Single endpoint —
// designed for a printable executive view + the dashboard.

import type { PlatformSummaryResponse } from '@my-product/shared';
import { getPrisma } from '../../core/db/client';

const TOP_LIMIT = 10;

export async function getPlatformSummary(
  fromIso?: string,
  toIso?: string,
): Promise<PlatformSummaryResponse> {
  const prisma = getPrisma();
  const to = toIso ? new Date(toIso) : new Date();
  // Default window: last 30 days.
  const from = fromIso
    ? new Date(fromIso)
    : new Date(to.getTime() - 30 * 24 * 60 * 60 * 1000);

  const reportWhere = { createdAt: { gte: from, lte: to } };

  const [
    total,
    verified,
    pending,
    flagged,
    rejected,
    scamTypeBreakdownRows,
    topScammersRows,
    topPhoneRows,
    topUrlRows,
    checkLogsTotal,
    verdictMixRows,
    aiHigh,
    aiMedium,
    aiLow,
    aiUnknown,
    latestEval,
  ] = await Promise.all([
    prisma.report.count({ where: reportWhere }),
    prisma.report.count({ where: { ...reportWhere, status: 'verified' } }),
    prisma.report.count({ where: { ...reportWhere, status: 'pending' } }),
    prisma.report.count({ where: { ...reportWhere, status: 'flagged' } }),
    prisma.report.count({ where: { ...reportWhere, status: 'rejected' } }),
    prisma.report.groupBy({
      by: ['scamTypeId'],
      where: reportWhere,
      _count: { scamTypeId: true },
      orderBy: { _count: { scamTypeId: 'desc' } },
      take: TOP_LIMIT,
    }),
    prisma.scammer.findMany({
      orderBy: { reportCountCache: 'desc' },
      take: TOP_LIMIT,
      where: { reportCountCache: { gt: 0 } },
      select: {
        id: true,
        displayName: true,
        suspectedName: true,
        reportCountCache: true,
        riskLevel: true,
      },
    }),
    prisma.report.groupBy({
      by: ['targetIdentifierNormalized'],
      where: {
        ...reportWhere,
        targetIdentifierKind: 'phone',
        targetIdentifierNormalized: { not: null },
      },
      _count: { _all: true },
      orderBy: { _count: { id: 'desc' } },
      take: TOP_LIMIT,
    }),
    prisma.report.groupBy({
      by: ['targetIdentifierNormalized'],
      where: {
        ...reportWhere,
        targetIdentifierKind: 'url',
        targetIdentifierNormalized: { not: null },
      },
      _count: { _all: true },
      orderBy: { _count: { id: 'desc' } },
      take: TOP_LIMIT,
    }),
    prisma.checkLog.count({ where: { createdAt: { gte: from, lte: to } } }),
    prisma.checkLog.groupBy({
      by: ['verdict'],
      where: { createdAt: { gte: from, lte: to } },
      _count: { verdict: true },
    }),
    prisma.report.count({ where: { ...reportWhere, aiConfidence: 'high' } }),
    prisma.report.count({ where: { ...reportWhere, aiConfidence: 'medium' } }),
    prisma.report.count({ where: { ...reportWhere, aiConfidence: 'low' } }),
    prisma.report.count({
      where: { ...reportWhere, OR: [{ aiConfidence: null }, { aiConfidence: 'unknown' }] },
    }),
    prisma.aiEvalRun.findFirst({ orderBy: { runAt: 'desc' } }),
  ]);

  const scamTypeIds = scamTypeBreakdownRows.map((r) => r.scamTypeId);
  const scamTypes = scamTypeIds.length > 0
    ? await prisma.scamType.findMany({ where: { id: { in: scamTypeIds } } })
    : [];
  const scamTypeById = new Map(scamTypes.map((s) => [s.id, s]));

  const verdictMix = { scam: 0, suspicious: 0, safe: 0, unknown: 0 };
  for (const v of verdictMixRows) {
    const key = v.verdict as keyof typeof verdictMix;
    if (key in verdictMix) verdictMix[key] = v._count.verdict;
  }

  return {
    range: { from: from.toISOString(), to: to.toISOString() },
    reports: {
      total,
      verified,
      pending: pending + flagged,
      rejected,
      flagged,
    },
    scamTypeBreakdown: scamTypeBreakdownRows.map((r) => {
      const st = scamTypeById.get(r.scamTypeId);
      return {
        scamTypeCode: st?.code ?? 'unknown',
        labelEn: st?.labelEn ?? 'Unknown',
        count: r._count.scamTypeId,
      };
    }),
    topScammers: topScammersRows.map((s) => ({
      id: s.id,
      displayName: s.displayName,
      suspectedName: s.suspectedName,
      reportCount: s.reportCountCache,
      riskLevel: s.riskLevel,
    })),
    topIdentifiers: [
      ...topPhoneRows.map((r) => ({
        kind: 'phone',
        valueNormalized: r.targetIdentifierNormalized ?? '',
        reportCount: r._count._all,
      })),
      ...topUrlRows.map((r) => ({
        kind: 'url',
        valueNormalized: r.targetIdentifierNormalized ?? '',
        reportCount: r._count._all,
      })),
    ]
      .sort((a, b) => b.reportCount - a.reportCount)
      .slice(0, TOP_LIMIT),
    checkLogs: {
      total: checkLogsTotal,
      verdictMix,
    },
    aiScoreDistribution: {
      high: aiHigh,
      medium: aiMedium,
      low: aiLow,
      unknown: aiUnknown,
    },
    latestEval: latestEval
      ? {
          runAt: latestEval.runAt.toISOString(),
          verdictAccuracy: latestEval.verdictAccuracy,
          scammerRecallAt1: latestEval.scammerRecallAt1,
          scammerMrr: latestEval.scammerMrr,
          missingFactsF1: latestEval.missingFactsF1,
          p95LatencyMs: latestEval.p95LatencyMs,
        }
      : null,
    generatedAt: new Date().toISOString(),
  };
}
