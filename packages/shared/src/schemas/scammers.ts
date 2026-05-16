import { Type, type Static } from '@sinclair/typebox';

export const ScammerRiskLevel = Type.Union([
  Type.Literal('low'),
  Type.Literal('medium'),
  Type.Literal('high'),
  Type.Literal('unknown'),
]);
export type ScammerRiskLevel = Static<typeof ScammerRiskLevel>;

export const ScammerIdentifierKind = Type.Union([
  Type.Literal('phone'),
  Type.Literal('url'),
  Type.Literal('email'),
  Type.Literal('bank_account'),
  Type.Literal('line_id'),
  Type.Literal('social_handle'),
  Type.Literal('other'),
]);
export type ScammerIdentifierKind = Static<typeof ScammerIdentifierKind>;

export const ScammerIdentifier = Type.Object({
  id: Type.String({ format: 'uuid' }),
  kind: ScammerIdentifierKind,
  valueRaw: Type.String(),
  valueNormalized: Type.String(),
});
export type ScammerIdentifier = Static<typeof ScammerIdentifier>;

// Compact summary — what mobile / Ask AI / check responses show inline.
// Inline Person reference on ScammerProfileSummary — avoids circular import
// with persons.ts. Mirrors the shape of `PersonSummary` minus aliases/counts
// the caller doesn't need at the scammer-summary level.
export const ScammerPersonRef = Type.Object({
  id: Type.String({ format: 'uuid' }),
  fullName: Type.String(),
  riskLevel: ScammerRiskLevel,
  campaignCount: Type.Integer({ minimum: 0 }),
});
export type ScammerPersonRef = Static<typeof ScammerPersonRef>;

export const ScammerProfileSummary = Type.Object({
  id: Type.String({ format: 'uuid' }),
  displayName: Type.String(),
  // Person's name the offender claimed (or is alleged to use). Null when the
  // scam is run by an anonymous campaign with no named caller. Denormalised
  // cache; the canonical identity sits on `person` when set.
  suspectedName: Type.Union([Type.String(), Type.Null()]),
  // Link to a `Person` row when the campaign is attributable to a known
  // human. Multiple scammer campaigns can share the same person.
  person: Type.Union([ScammerPersonRef, Type.Null()]),
  aliases: Type.Array(Type.String()),
  riskLevel: ScammerRiskLevel,
  reportCount: Type.Integer({ minimum: 0 }),
  topScamTypeCodes: Type.Array(Type.String()),
});
export type ScammerProfileSummary = Static<typeof ScammerProfileSummary>;

export const ScammerProfile = Type.Object({
  id: Type.String({ format: 'uuid' }),
  displayName: Type.String(),
  suspectedName: Type.Union([Type.String(), Type.Null()]),
  person: Type.Union([ScammerPersonRef, Type.Null()]),
  aliases: Type.Array(Type.String()),
  riskLevel: ScammerRiskLevel,
  notes: Type.Union([Type.String(), Type.Null()]),
  reportCount: Type.Integer({ minimum: 0 }),
  identifiers: Type.Array(ScammerIdentifier),
  firstSeenAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  lastSeenAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  createdAt: Type.String({ format: 'date-time' }),
});
export type ScammerProfile = Static<typeof ScammerProfile>;

export const MatchedScammerCase = Type.Object({
  id: Type.String({ format: 'uuid' }),
  title: Type.String(),
  scamTypeCode: Type.String(),
  verifiedAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
});
export type MatchedScammerCase = Static<typeof MatchedScammerCase>;

// Returned from /check and Ask AI when an identifier hit a known scammer.
export const MatchedScammer = Type.Object({
  summary: ScammerProfileSummary,
  recentCases: Type.Array(MatchedScammerCase),
});
export type MatchedScammer = Static<typeof MatchedScammer>;

// Admin endpoints --------------------------------------------------------

export const SearchScammersResponse = Type.Object({
  items: Type.Array(ScammerProfileSummary),
});
export type SearchScammersResponse = Static<typeof SearchScammersResponse>;

export const LinkScammerRequest = Type.Union([
  Type.Object({
    scammerId: Type.String({ format: 'uuid' }),
  }),
  Type.Object({
    createNew: Type.Object({
      displayName: Type.String({ minLength: 1, maxLength: 200 }),
      aliases: Type.Array(Type.String({ minLength: 1 }), { default: [] }),
      riskLevel: Type.Optional(ScammerRiskLevel),
      notes: Type.Optional(Type.String()),
      identifiers: Type.Optional(
        Type.Array(
          Type.Object({
            kind: ScammerIdentifierKind,
            valueRaw: Type.String({ minLength: 1 }),
          }),
        ),
      ),
    }),
  }),
]);
export type LinkScammerRequest = Static<typeof LinkScammerRequest>;

export const LinkScammerResponse = Type.Object({
  reportId: Type.String({ format: 'uuid' }),
  scammerId: Type.String({ format: 'uuid' }),
});
export type LinkScammerResponse = Static<typeof LinkScammerResponse>;
