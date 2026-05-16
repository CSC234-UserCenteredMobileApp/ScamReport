// Admin report dossier PDF template.

import type { Content, TDocumentDefinitions } from 'pdfmake/interfaces';
import type { AdminReportDetail } from '@my-product/shared';
import {
  pageHeader,
  pageFooter,
  sectionTitle,
  pill,
  kvTable,
  disclaimer,
  shortId,
  formatDate,
} from '../pdf-generator';

function statusKind(status: string): 'scam' | 'warn' | 'ok' | 'neutral' {
  switch (status) {
    case 'verified':
      return 'scam';
    case 'flagged':
      return 'warn';
    case 'rejected':
      return 'neutral';
    default:
      return 'warn';
  }
}

// Map of evidence file id → data-URL of its raw bytes (caller fetches from
// Supabase storage). Files absent from the map render as text-only rows.
export type EvidenceImageMap = Record<string, string>;

export function reportTemplate(
  detail: AdminReportDetail,
  images: EvidenceImageMap = {},
): TDocumentDefinitions {
  const generatedAt = new Date();

  const headerBlock = [
    { text: detail.title, style: 'h1' },
    {
      columns: [
        pill(`Status: ${detail.status.toUpperCase()}`, statusKind(detail.status)),
        pill(`Type: ${detail.scamTypeLabelEn}`),
        ...(detail.aiScore !== null
          ? [pill(`AI score: ${detail.aiScore} (${detail.aiConfidence ?? 'unknown'})`)]
          : []),
        ...(detail.priorityFlag ? [pill('Priority flag', 'warn')] : []),
      ],
      columnGap: 8,
    },
    { text: `Submitted: ${formatDate(detail.submittedAt)}`, style: 'muted', margin: [0, 4, 0, 0] },
  ];

  const descriptionBlock = [
    sectionTitle('Description'),
    { text: detail.description },
  ];

  const targetBlock = detail.targetIdentifier
    ? [
        sectionTitle('Target identifier'),
        kvTable([
          ['Value', detail.targetIdentifier],
          ['Kind', detail.targetIdentifierKind ?? '—'],
        ]),
      ]
    : [];

  const suspectedNameBlock = detail.suspectedNameAtSubmit
    ? [
        sectionTitle('Reported suspect name'),
        kvTable([
          ['Alleged name', detail.suspectedNameAtSubmit],
          ['Source', 'Reporter / Ask AI at submit time'],
        ]),
      ]
    : [];

  const scammerBlock = detail.scammer
    ? [
        sectionTitle('Linked scammer'),
        kvTable([
          ['Display name', detail.scammer.displayName],
          ...((detail.scammer.suspectedName
            ? [['Alleged name', detail.scammer.suspectedName] as [string, string]]
            : []) as Array<[string, string]>),
          ['Risk level', detail.scammer.riskLevel],
          ['Reports on file', String(detail.scammer.reportCount)],
          ...((detail.scammer.aliases.length > 0
            ? [['Aliases', detail.scammer.aliases.join(', ')] as [string, string]]
            : []) as Array<[string, string]>),
          ...((detail.siblingCases.length > 0
            ? [
                [
                  'Other cases',
                  `${detail.siblingCases.length} — ${detail.siblingCases
                    .slice(0, 5)
                    .map((c) => c.title)
                    .join('; ')}`,
                ] as [string, string],
              ]
            : []) as Array<[string, string]>),
        ]),
      ]
    : [];

  const evidenceImages: Content[] = [];
  for (const f of detail.evidenceFiles) {
    const dataUrl = images[f.id];
    if (dataUrl) {
      evidenceImages.push({
        stack: [
          {
            image: dataUrl,
            // pdfmake fits to width; cap so a tall portrait stays on one page.
            fit: [480, 480],
            margin: [0, 6, 0, 2],
          },
          {
            text: `${f.storagePath.split('/').pop() ?? f.storagePath} · ${f.mimeType}`,
            style: 'muted',
            margin: [0, 0, 0, 8],
          },
        ],
      });
    }
  }

  const evidenceBlock =
    detail.evidenceFiles.length === 0
      ? [
          sectionTitle('Evidence'),
          { text: 'No evidence attached.', style: 'muted' },
        ]
      : [
          sectionTitle(`Evidence (${detail.evidenceFiles.length})`),
          {
            table: {
              headerRows: 1,
              widths: ['*', 'auto', 'auto'],
              body: [
                [
                  { text: 'File', style: 'tableHeader' },
                  { text: 'Kind', style: 'tableHeader' },
                  { text: 'Mime', style: 'tableHeader' },
                ],
                ...detail.evidenceFiles.map((f) => [
                  { text: f.storagePath.split('/').pop() ?? f.storagePath },
                  { text: f.kind },
                  { text: f.mimeType },
                ]),
              ],
            },
            layout: 'lightHorizontalLines',
          },
          ...evidenceImages,
        ];

  const auditBlock =
    detail.auditTrail.length === 0
      ? [
          sectionTitle('Audit trail'),
          { text: 'No moderation actions yet.', style: 'muted' },
        ]
      : [
          sectionTitle('Audit trail'),
          {
            table: {
              headerRows: 1,
              widths: ['auto', 'auto', '*'],
              body: [
                [
                  { text: 'When', style: 'tableHeader' },
                  { text: 'Action', style: 'tableHeader' },
                  { text: 'Remark', style: 'tableHeader' },
                ],
                ...detail.auditTrail.map((a) => [
                  { text: formatDate(a.createdAt) },
                  { text: a.action },
                  { text: a.remark },
                ]),
              ],
            },
            layout: 'lightHorizontalLines',
          },
        ];

  const content: Content[] = [
    ...(headerBlock as Content[]),
    ...(descriptionBlock as Content[]),
    ...(targetBlock as Content[]),
    ...(suspectedNameBlock as Content[]),
    ...(scammerBlock as Content[]),
    ...(evidenceBlock as Content[]),
    ...(auditBlock as Content[]),
    disclaimer(),
  ];

  return {
    header: pageHeader('Report', shortId(detail.id)),
    footer: pageFooter(generatedAt),
    content,
  };
}
