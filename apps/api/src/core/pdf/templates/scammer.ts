import type { Content, TDocumentDefinitions } from 'pdfmake/interfaces';
import type { ScammerDossierResponse } from '@my-product/shared';
import {
  pageHeader,
  pageFooter,
  sectionTitle,
  kvTable,
  disclaimer,
  shortId,
  formatDate,
} from '../pdf-generator';

export function scammerTemplate(d: ScammerDossierResponse): TDocumentDefinitions {
  const generatedAt = new Date();
  const s = d.scammer;

  const identifierRows = s.identifiers.length === 0
    ? [
        sectionTitle('Identifiers'),
        { text: 'None on file.', style: 'muted' },
      ]
    : [
        sectionTitle('Identifiers'),
        {
          table: {
            headerRows: 1,
            widths: ['auto', '*', 'auto'],
            body: [
              [
                { text: 'Kind', style: 'tableHeader' },
                { text: 'Value', style: 'tableHeader' },
                { text: 'Normalised', style: 'tableHeader' },
              ],
              ...s.identifiers.map((i) => [
                { text: i.kind },
                { text: i.valueRaw },
                { text: i.valueNormalized, style: 'muted' },
              ]),
            ],
          },
          layout: 'lightHorizontalLines',
        },
      ];

  const casesBlock = d.cases.length === 0
    ? [
        sectionTitle('Linked reports'),
        { text: 'No verified reports linked.', style: 'muted' },
      ]
    : [
        sectionTitle(`Linked reports (${d.cases.length})`),
        {
          table: {
            headerRows: 1,
            widths: ['auto', 'auto', '*'],
            body: [
              [
                { text: 'Verified', style: 'tableHeader' },
                { text: 'Status', style: 'tableHeader' },
                { text: 'Title', style: 'tableHeader' },
              ],
              ...d.cases.map((c) => [
                { text: formatDate(c.verifiedAt) },
                { text: c.status },
                { text: c.title },
              ]),
            ],
          },
          layout: 'lightHorizontalLines',
        },
      ];

  const content: Content[] = [
    { text: s.displayName, style: 'h1' },
    ...(s.suspectedName
      ? ([{ text: `Alleged name: ${s.suspectedName}`, margin: [0, -4, 0, 4] }] as Content[])
      : []),
    kvTable([
      ['Risk level', s.riskLevel],
      ['Total reports', String(s.reportCount)],
      ['Aliases', s.aliases.join(', ') || '—'],
      ['First seen', formatDate(s.firstSeenAt)],
      ['Last seen', formatDate(s.lastSeenAt)],
    ]),
    ...(s.notes ? ([{ text: s.notes, margin: [0, 6, 0, 0] }] as Content[]) : []),
    ...(identifierRows as Content[]),
    ...(casesBlock as Content[]),
    disclaimer(),
  ];

  return {
    header: pageHeader('Scammer', shortId(s.id)),
    footer: pageFooter(generatedAt),
    content,
  };
}
