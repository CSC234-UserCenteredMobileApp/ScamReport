import type { CheckInputKind, VerdictLabel } from '../../generated/prisma/client';
import { getPrisma } from '../../core/db/client';

export interface EvalCaseRow {
  id: string;
  label: string;
  inputType: CheckInputKind;
  inputPayload: string;
  expectedVerdict: VerdictLabel;
  expectedScammerId: string | null;
  expectedScamTypeCode: string | null;
  expectedMissingFacts: string[];
}

export async function listCases(): Promise<EvalCaseRow[]> {
  const prisma = getPrisma();
  const rows = await prisma.aiEvalCase.findMany({
    orderBy: { createdAt: 'asc' },
    select: {
      id: true,
      label: true,
      inputType: true,
      inputPayload: true,
      expectedVerdict: true,
      expectedScammerId: true,
      expectedScamTypeCode: true,
      expectedMissingFacts: true,
    },
  });
  return rows.map((r) => ({
    id: r.id,
    label: r.label,
    inputType: r.inputType,
    inputPayload: r.inputPayload,
    expectedVerdict: r.expectedVerdict,
    expectedScammerId: r.expectedScammerId,
    expectedScamTypeCode: r.expectedScamTypeCode,
    expectedMissingFacts: Array.isArray(r.expectedMissingFacts)
      ? (r.expectedMissingFacts as string[])
      : [],
  }));
}

export interface PersistRunInput {
  totalCases: number;
  verdictAccuracy: number;
  scammerRecallAt1: number;
  scammerMrr: number;
  missingFactsF1: number;
  p95LatencyMs: number;
  results: Array<{
    caseId: string;
    actualVerdict: VerdictLabel;
    actualScammerId: string | null;
    actualMissingFacts: string[];
    scammerMatched: boolean;
    latencyMs: number;
  }>;
}

export async function persistRun(input: PersistRunInput): Promise<string> {
  const prisma = getPrisma();
  return prisma.$transaction(async (tx) => {
    const run = await tx.aiEvalRun.create({
      data: {
        totalCases: input.totalCases,
        verdictAccuracy: input.verdictAccuracy,
        scammerRecallAt1: input.scammerRecallAt1,
        scammerMrr: input.scammerMrr,
        missingFactsF1: input.missingFactsF1,
        p95LatencyMs: input.p95LatencyMs,
      },
      select: { id: true },
    });
    if (input.results.length > 0) {
      await tx.aiEvalResult.createMany({
        data: input.results.map((r) => ({
          runId: run.id,
          caseId: r.caseId,
          actualVerdict: r.actualVerdict,
          actualScammerId: r.actualScammerId,
          actualMissingFacts: r.actualMissingFacts,
          scammerMatched: r.scammerMatched,
          latencyMs: r.latencyMs,
        })),
      });
    }
    return run.id;
  });
}

export async function listRuns(limit: number) {
  const prisma = getPrisma();
  return prisma.aiEvalRun.findMany({
    orderBy: { runAt: 'desc' },
    take: limit,
  });
}

export async function findRun(id: string) {
  const prisma = getPrisma();
  return prisma.aiEvalRun.findUnique({ where: { id } });
}
