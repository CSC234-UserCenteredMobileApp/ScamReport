import { Type, type Static } from '@sinclair/typebox';

// POST /check — Quick Verdict request/response (PRD §3.1, FR-2.1..2.5).
//
// Schema is the team-locked contract from Plan-Mode decision D8 (2026-04-28).
// Both the verdict screen on mobile and the share-target / clipboard banner
// entry points produce a CheckRequest. The api fans out the matching logic
// (Postgres lookup; pgvector retrieval lives behind /search, NOT here) and
// always returns a CheckResponse — even Unknown is a successful response, not
// an HTTP error.

export const CheckType = Type.Union(
  [Type.Literal('phone'), Type.Literal('url'), Type.Literal('text')],
  { description: 'Kind of identifier the caller is asking about.' },
);
export type CheckType = Static<typeof CheckType>;

export const CheckRequest = Type.Object(
  {
    type: CheckType,
    payload: Type.String({
      minLength: 1,
      maxLength: 2000,
      description:
        'Raw user-supplied identifier. Backend normalises (E.164 for phones, lowercased host for URLs) before matching.',
    }),
    meta: Type.Optional(
      Type.Object(
        {
          source: Type.Optional(
            Type.Union([
              Type.Literal('manual'),
              Type.Literal('share'),
              Type.Literal('clipboard'),
            ]),
          ),
          locale: Type.Optional(
            Type.Union([Type.Literal('th'), Type.Literal('en')]),
          ),
        },
        { additionalProperties: false },
      ),
    ),
  },
  { additionalProperties: false },
);
export type CheckRequest = Static<typeof CheckRequest>;

export const Verdict = Type.Union(
  [
    Type.Literal('scam'),
    Type.Literal('suspicious'),
    Type.Literal('safe'),
    Type.Literal('unknown'),
  ],
  {
    description:
      'Traffic-light verdict (PRD FR-2.2). Always paired with icon + label in UI; colour is never the only differentiator.',
  },
);
export type Verdict = Static<typeof Verdict>;

// Compact card a verdict screen renders below the headline result.
// Reporter identity is intentionally absent (FR-3.4: report detail never shows
// reporter; this summary is even less detailed than that).
export const ReportSummary = Type.Object(
  {
    id: Type.String({ format: 'uuid' }),
    title: Type.String({ minLength: 1, maxLength: 200 }),
    scamType: Type.String({ minLength: 1 }),
    verifiedAt: Type.String({ format: 'date-time' }),
  },
  { additionalProperties: false },
);
export type ReportSummary = Static<typeof ReportSummary>;

export const CheckResponse = Type.Object(
  {
    verdict: Verdict,
    matchedCount: Type.Integer({ minimum: 0 }),
    matches: Type.Array(ReportSummary),
  },
  { additionalProperties: false },
);
export type CheckResponse = Static<typeof CheckResponse>;

// GET /check/phones — device sync for call-screening cache (FR-9.x).
// Returns all normalized phone numbers from verified scam reports so the
// Android CallScreeningService can make offline decisions within the 5s window.
export const PhoneSyncResponse = Type.Object(
  {
    phones: Type.Array(Type.String()),
    updatedAt: Type.String({ format: 'date-time' }),
  },
  { additionalProperties: false },
);
export type PhoneSyncResponse = Static<typeof PhoneSyncResponse>;
