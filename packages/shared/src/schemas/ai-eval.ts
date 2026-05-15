import { Type, type Static } from '@sinclair/typebox';

export const AiEvalSummary = Type.Object({
  id: Type.String({ format: 'uuid' }),
  runAt: Type.String({ format: 'date-time' }),
  totalCases: Type.Integer({ minimum: 0 }),
  verdictAccuracy: Type.Number({ minimum: 0, maximum: 1 }),
  scammerRecallAt1: Type.Number({ minimum: 0, maximum: 1 }),
  scammerMrr: Type.Number({ minimum: 0, maximum: 1 }),
  missingFactsF1: Type.Number({ minimum: 0, maximum: 1 }),
  p95LatencyMs: Type.Integer({ minimum: 0 }),
});
export type AiEvalSummary = Static<typeof AiEvalSummary>;

export const AiEvalRunResponse = Type.Object({
  summary: AiEvalSummary,
});
export type AiEvalRunResponse = Static<typeof AiEvalRunResponse>;

export const AiEvalListResponse = Type.Object({
  items: Type.Array(AiEvalSummary),
});
export type AiEvalListResponse = Static<typeof AiEvalListResponse>;
