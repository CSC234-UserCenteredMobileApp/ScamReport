import type {
  PersonDossierResponse,
  PersonCampaign,
  PersonProfile,
  ScammerRiskLevel,
} from '@my-product/shared';
import { findPersonById } from './admin-persons.repo';

export async function getPersonDossier(
  id: string,
): Promise<PersonDossierResponse | null> {
  const row = await findPersonById(id);
  if (!row) return null;

  const profile: PersonProfile = {
    id: row.id,
    fullName: row.fullName,
    aliases: row.aliases,
    riskLevel: row.riskLevel as ScammerRiskLevel,
    notes: row.notes,
    reportCount: row.reportCountCache,
    campaignCount: row.campaignCountCache,
    firstSeenAt: row.firstSeenAt?.toISOString() ?? null,
    lastSeenAt: row.lastSeenAt?.toISOString() ?? null,
    createdAt: row.createdAt.toISOString(),
  };

  const campaigns: PersonCampaign[] = row.scammers.map((s) => {
    const top: string[] = [];
    for (const r of s.reports) {
      if (!top.includes(r.scamType.code)) top.push(r.scamType.code);
    }
    return {
      id: s.id,
      displayName: s.displayName,
      suspectedName: s.suspectedName,
      riskLevel: s.riskLevel as ScammerRiskLevel,
      reportCount: s.reportCountCache,
      topScamTypeCodes: top,
      firstSeenAt: s.firstSeenAt?.toISOString() ?? null,
      lastSeenAt: s.lastSeenAt?.toISOString() ?? null,
    };
  });

  return {
    person: profile,
    campaigns,
    generatedAt: new Date().toISOString(),
  };
}
