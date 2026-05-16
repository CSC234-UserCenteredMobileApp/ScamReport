import type { Content, TDocumentDefinitions } from 'pdfmake/interfaces';
import type { PersonDossierResponse } from '@my-product/shared';
import {
  pageHeader,
  pageFooter,
  sectionTitle,
  kvTable,
  disclaimer,
  shortId,
  formatDate,
} from '../pdf-generator';

export function personTemplate(d: PersonDossierResponse): TDocumentDefinitions {
  const generatedAt = new Date();
  const p = d.person;

  const campaigns = d.campaigns.length === 0
    ? [
        sectionTitle('Campaigns'),
        { text: 'No campaigns linked.', style: 'muted' },
      ]
    : [
        sectionTitle(`Campaigns (${d.campaigns.length})`),
        {
          table: {
            headerRows: 1,
            widths: ['*', 'auto', 'auto', 'auto'],
            body: [
              [
                { text: 'Display name', style: 'tableHeader' },
                { text: 'Risk', style: 'tableHeader' },
                { text: 'Cases', style: 'tableHeader' },
                { text: 'Top types', style: 'tableHeader' },
              ],
              ...d.campaigns.map((c) => [
                { text: c.displayName + (c.suspectedName ? `\nAlleged: ${c.suspectedName}` : '') },
                { text: c.riskLevel },
                { text: String(c.reportCount), alignment: 'right' as const },
                { text: c.topScamTypeCodes.join(', ') || '—' },
              ]),
            ],
          },
          layout: 'lightHorizontalLines',
        },
      ];

  const content: Content[] = [
    { text: p.fullName, style: 'h1' },
    kvTable([
      ['Risk level', p.riskLevel],
      ['Campaigns', String(p.campaignCount)],
      ['Total reports', String(p.reportCount)],
      ['Aliases', p.aliases.join(', ') || '—'],
      ['First seen', formatDate(p.firstSeenAt)],
      ['Last seen', formatDate(p.lastSeenAt)],
    ]),
    ...(p.notes ? ([{ text: p.notes, margin: [0, 6, 0, 0] }] as Content[]) : []),
    ...(campaigns as Content[]),
    disclaimer(),
  ];

  return {
    header: pageHeader('Person', shortId(p.id)),
    footer: pageFooter(generatedAt),
    content,
  };
}
