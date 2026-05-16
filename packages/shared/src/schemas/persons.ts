import { Type, type Static } from '@sinclair/typebox';
import { ScammerRiskLevel } from './scammers';

// Person = one real human offender. Many Scammer rows (campaigns / surfaces)
// can reference the same Person. Used in admin dossier and as the
// `person` field on ScammerProfileSummary so callers know the offender's
// identity sits in a stable shared row, not a per-campaign string.
export const PersonSummary = Type.Object({
  id: Type.String({ format: 'uuid' }),
  fullName: Type.String(),
  aliases: Type.Array(Type.String()),
  riskLevel: ScammerRiskLevel,
  reportCount: Type.Integer({ minimum: 0 }),
  campaignCount: Type.Integer({ minimum: 0 }),
});
export type PersonSummary = Static<typeof PersonSummary>;

export const PersonProfile = Type.Object({
  id: Type.String({ format: 'uuid' }),
  fullName: Type.String(),
  aliases: Type.Array(Type.String()),
  riskLevel: ScammerRiskLevel,
  notes: Type.Union([Type.String(), Type.Null()]),
  reportCount: Type.Integer({ minimum: 0 }),
  campaignCount: Type.Integer({ minimum: 0 }),
  firstSeenAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  lastSeenAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  createdAt: Type.String({ format: 'date-time' }),
});
export type PersonProfile = Static<typeof PersonProfile>;

// One scammer campaign attributable to this person.
export const PersonCampaign = Type.Object({
  id: Type.String({ format: 'uuid' }),
  displayName: Type.String(),
  suspectedName: Type.Union([Type.String(), Type.Null()]),
  riskLevel: ScammerRiskLevel,
  reportCount: Type.Integer({ minimum: 0 }),
  topScamTypeCodes: Type.Array(Type.String()),
  firstSeenAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
  lastSeenAt: Type.Union([Type.String({ format: 'date-time' }), Type.Null()]),
});
export type PersonCampaign = Static<typeof PersonCampaign>;

export const PersonDossierResponse = Type.Object({
  person: PersonProfile,
  campaigns: Type.Array(PersonCampaign),
  generatedAt: Type.String({ format: 'date-time' }),
});
export type PersonDossierResponse = Static<typeof PersonDossierResponse>;
