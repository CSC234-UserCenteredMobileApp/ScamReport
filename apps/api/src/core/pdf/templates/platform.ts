import type { TDocumentDefinitions } from 'pdfmake/interfaces';
import type { PlatformSummaryResponse } from '@my-product/shared';
import {
  pageHeader,
  pageFooter,
  sectionTitle,
  kvTable,
  disclaimer,
  formatDate,
} from '../pdf-generator';

export function platformTemplate(s: PlatformSummaryResponse): TDocumentDefinitions {
  const generatedAt = new Date();

  return {
    header: pageHeader('Platform Summary', formatDate(s.generatedAt).replace(/\s/g, '')),
    footer: pageFooter(generatedAt),
    content: [
      { text: 'Platform Summary', style: 'h1' },
      {
        text: `Window: ${formatDate(s.range.from)} → ${formatDate(s.range.to)}`,
        style: 'muted',
      },

      sectionTitle('Reports'),
      kvTable([
        ['Total', String(s.reports.total)],
        ['Verified', String(s.reports.verified)],
        ['Pending', String(s.reports.pending)],
        ['Flagged', String(s.reports.flagged)],
        ['Rejected', String(s.reports.rejected)],
      ]),

      sectionTitle(`Scam-type breakdown (${s.scamTypeBreakdown.length})`),
      s.scamTypeBreakdown.length === 0
        ? { text: 'No data.', style: 'muted' }
        : {
            table: {
              headerRows: 1,
              widths: ['*', 'auto'],
              body: [
                [
                  { text: 'Scam type', style: 'tableHeader' },
                  { text: 'Count', style: 'tableHeader' },
                ],
                ...s.scamTypeBreakdown.map((r) => [
                  { text: r.labelEn },
                  { text: String(r.count), alignment: 'right' as const },
                ]),
              ],
            },
            layout: 'lightHorizontalLines',
          },

      sectionTitle(`Top scammers (${s.topScammers.length})`),
      s.topScammers.length === 0
        ? { text: 'No data.', style: 'muted' }
        : {
            table: {
              headerRows: 1,
              widths: ['*', 'auto', 'auto'],
              body: [
                [
                  { text: 'Scammer', style: 'tableHeader' },
                  { text: 'Risk', style: 'tableHeader' },
                  { text: 'Cases', style: 'tableHeader' },
                ],
                ...s.topScammers.map((r) => [
                  { text: r.displayName + (r.suspectedName ? `\nAlleged: ${r.suspectedName}` : '') },
                  { text: r.riskLevel },
                  { text: String(r.reportCount), alignment: 'right' as const },
                ]),
              ],
            },
            layout: 'lightHorizontalLines',
          },

      sectionTitle(`Top identifiers (${s.topIdentifiers.length})`),
      s.topIdentifiers.length === 0
        ? { text: 'No data.', style: 'muted' }
        : {
            table: {
              headerRows: 1,
              widths: ['auto', '*', 'auto'],
              body: [
                [
                  { text: 'Kind', style: 'tableHeader' },
                  { text: 'Normalised value', style: 'tableHeader' },
                  { text: 'Count', style: 'tableHeader' },
                ],
                ...s.topIdentifiers.map((r) => [
                  { text: r.kind },
                  { text: r.valueNormalized },
                  { text: String(r.reportCount), alignment: 'right' as const },
                ]),
              ],
            },
            layout: 'lightHorizontalLines',
          },

      sectionTitle('Check-log activity'),
      kvTable([
        ['Total calls', String(s.checkLogs.total)],
        ['Verdict: scam', String(s.checkLogs.verdictMix.scam)],
        ['Verdict: suspicious', String(s.checkLogs.verdictMix.suspicious)],
        ['Verdict: safe', String(s.checkLogs.verdictMix.safe)],
        ['Verdict: unknown', String(s.checkLogs.verdictMix.unknown)],
      ]),

      disclaimer(),
    ],
  };
}
