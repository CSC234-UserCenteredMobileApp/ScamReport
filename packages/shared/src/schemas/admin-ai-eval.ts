import { Type, type Static } from '@sinclair/typebox';

const Verdict = Type.Union([
  Type.Literal('scam'),
  Type.Literal('suspicious'),
  Type.Literal('safe'),
  Type.Literal('unknown'),
]);

const InputType = Type.Union([
  Type.Literal('phone'),
  Type.Literal('url'),
  Type.Literal('text'),
]);

const TypeMetrics = Type.Object({
  n: Type.Integer({ minimum: 0 }),
  verdictAccuracy: Type.Number({ minimum: 0, maximum: 1 }),
  scammerRecallAt1: Type.Number({ minimum: 0, maximum: 1 }),
  mrr: Type.Number({ minimum: 0, maximum: 1 }),
  p95LatencyMs: Type.Integer({ minimum: 0 }),
});

const ByTypeFull = Type.Object({
  phone: TypeMetrics,
  url: TypeMetrics,
  text: TypeMetrics,
});

const VerdictRow = Type.Object({
  scam: Type.Integer({ minimum: 0 }),
  suspicious: Type.Integer({ minimum: 0 }),
  safe: Type.Integer({ minimum: 0 }),
  unknown: Type.Integer({ minimum: 0 }),
});

const ConfusionMatrix = Type.Object({
  scam: VerdictRow,
  suspicious: VerdictRow,
  safe: VerdictRow,
  unknown: VerdictRow,
});

const CaseResult = Type.Object({
  label: Type.String(),
  inputType: InputType,
  expectedVerdict: Verdict,
  actualVerdict: Verdict,
  expectedScammerDisplayName: Type.Union([Type.String(), Type.Null()]),
  actualScammerDisplayName: Type.Union([Type.String(), Type.Null()]),
  rankOfExpected: Type.Union([Type.Integer({ minimum: 1 }), Type.Null()]),
  verdictHit: Type.Boolean(),
  latencyMs: Type.Integer({ minimum: 0 }),
  tags: Type.Array(Type.String()),
});

const AiEvalSummary = Type.Object({
  runAt: Type.String({ format: 'date-time' }),
  gitSha: Type.Union([Type.String(), Type.Null()]),
  totalCases: Type.Integer({ minimum: 0 }),
  verdictAccuracy: Type.Number({ minimum: 0, maximum: 1 }),
  scammerRecallAt1: Type.Number({ minimum: 0, maximum: 1 }),
  mrr: Type.Number({ minimum: 0, maximum: 1 }),
  p95LatencyMs: Type.Integer({ minimum: 0 }),
  byType: ByTypeFull,
  confusionMatrix: ConfusionMatrix,
  threshold: Type.Number({ minimum: 0, maximum: 1 }),
  passed: Type.Boolean(),
  results: Type.Array(CaseResult),
});
export type AiEvalSummary = Static<typeof AiEvalSummary>;

export const AdminAiEvalLatestResponse = Type.Object({
  summary: Type.Union([Type.Null(), AiEvalSummary]),
});
export type AdminAiEvalLatestResponse = Static<typeof AdminAiEvalLatestResponse>;

const HistoryEntry = Type.Object({
  runAt: Type.String({ format: 'date-time' }),
  gitSha: Type.Union([Type.String(), Type.Null()]),
  totalCases: Type.Integer({ minimum: 0 }),
  verdictAccuracy: Type.Number({ minimum: 0, maximum: 1 }),
  byType: Type.Object({
    phone: Type.Number({ minimum: 0, maximum: 1 }),
    url: Type.Number({ minimum: 0, maximum: 1 }),
    text: Type.Number({ minimum: 0, maximum: 1 }),
  }),
  threshold: Type.Number({ minimum: 0, maximum: 1 }),
  passed: Type.Boolean(),
});
export type AdminAiEvalHistoryEntry = Static<typeof HistoryEntry>;

export const AdminAiEvalHistoryResponse = Type.Object({
  entries: Type.Array(HistoryEntry),
});
export type AdminAiEvalHistoryResponse = Static<typeof AdminAiEvalHistoryResponse>;
