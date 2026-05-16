// Authority-handoff PDF generator. Wraps pdfmake so feature handlers stay
// declarative — each template returns a TDocumentDefinitions object; we
// render to Uint8Array bytes and the route streams them as application/pdf.
//
// Reporter PII is not surfaced anywhere; templates accept only the
// already-redacted admin payloads (FR-7.4 + FR-7.8).

// @ts-expect-error — `pdfmake/js/Printer` ships JS only; declare its shape locally.
import PdfPrinter from 'pdfmake/js/Printer';
import type { TDocumentDefinitions, ContentText, ContentTable } from 'pdfmake/interfaces';

interface PdfPrinterCtor {
  new (
    fontDescriptors: Record<string, Record<string, Buffer>>,
    virtualfs?: Record<string, unknown>,
    urlResolver?: { resolve: (url: string, headers?: unknown) => void },
    localAccessPolicy?: (path: string) => boolean,
  ): {
    createPdfKitDocument(
      doc: TDocumentDefinitions,
    ): Promise<NodeJS.ReadableStream & { end(): void }>;
  };
}

type PdfPrinterInstance = InstanceType<PdfPrinterCtor>;

// Roboto ships with pdfmake's bundled vfs in the dist/standard fonts path.
// Reusing the standard Roboto avoids vendoring a Thai font for v1 — Thai
// characters render via the same Roboto fallback the admin web uses
// (Sarabun is loaded only on the web in index.html). Acceptable trade-off:
// Latin and digits look professional; if Thai diacritics need to look better
// later, drop a `Sarabun` font under fonts/ and add to FONTS map.
const FONTS = {
  Roboto: {
    normal: 'node_modules/pdfmake/build/vfs_fonts.js',
  },
} as const;

// Avoid eager font loading at import — pdfmake's PdfPrinter expects file
// paths but Bun bundles can read from disk fine. We construct the printer
// lazily on first render.
let printer: PdfPrinterInstance | null = null;

function getPrinter(): PdfPrinterInstance {
  if (printer) return printer;
  // Use Sarabun (vendored via @expo-google-fonts/sarabun) as the default
  // font — covers Latin + Thai out of the box. Roboto (pdfmake's bundled
  // default) lacks Thai glyphs, so Thai-language reports rendered as boxes.
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const path = require('node:path') as typeof import('node:path');
  const resolve = (rel: string) => require.resolve(`@expo-google-fonts/sarabun/${rel}`);
  const Ctor = PdfPrinter as unknown as PdfPrinterCtor;
  printer = new Ctor(
    {
      Sarabun: {
        normal: resolve('400Regular/Sarabun_400Regular.ttf') as unknown as Buffer,
        bold: resolve('700Bold/Sarabun_700Bold.ttf') as unknown as Buffer,
        italics: resolve('400Regular_Italic/Sarabun_400Regular_Italic.ttf') as unknown as Buffer,
        bolditalics: resolve('700Bold_Italic/Sarabun_700Bold_Italic.ttf') as unknown as Buffer,
      },
    },
    undefined,
    {
      resolve: () => undefined,
      resolved: async () => undefined,
    } as unknown as { resolve: (url: string, headers?: unknown) => void },
    () => true,
  );
  // `path` import is used implicitly by `require.resolve` plus keeps lint
  // happy in case future templates need to compose paths manually.
  void path;
  return printer;
}

export async function renderPdf(doc: TDocumentDefinitions): Promise<Uint8Array> {
  const p = getPrinter();
  const pdf = await p.createPdfKitDocument({
    pageSize: 'A4',
    pageMargins: [40, 60, 40, 60],
    defaultStyle: { font: 'Sarabun', fontSize: 10, color: '#1a1a1a' },
    styles: {
      h1: { fontSize: 18, bold: true, margin: [0, 0, 0, 8] },
      h2: { fontSize: 13, bold: true, color: '#374151', margin: [0, 12, 0, 6] },
      label: { fontSize: 8, color: '#6b7280', characterSpacing: 0.6, bold: true },
      muted: { color: '#6b7280', fontSize: 9 },
      pillScam: { color: '#9a1d1d', fontSize: 9, bold: true },
      pillWarn: { color: '#7c4a03', fontSize: 9, bold: true },
      pillOk: { color: '#0f5132', fontSize: 9, bold: true },
      pillNeutral: { color: '#374151', fontSize: 9, bold: true },
      disclaimer: { fontSize: 8, color: '#475569', italics: true },
      tableHeader: { fontSize: 9, bold: true, fillColor: '#f3f4f6', color: '#111827' },
    },
    ...doc,
  });
  return await new Promise<Uint8Array>((resolve, reject) => {
    const chunks: Buffer[] = [];
    pdf.on('data', (c: Buffer) => chunks.push(c));
    pdf.on('end', () => resolve(new Uint8Array(Buffer.concat(chunks))));
    pdf.on('error', reject);
    pdf.end();
  });
}

// ---------------------------------------------------------------------------
// Layout helpers — kept here so every template renders identically.
// ---------------------------------------------------------------------------

export function pageHeader(subjectLabel: string, shortRef: string): TDocumentDefinitions['header'] {
  return () => ({
    margin: [40, 24, 40, 0],
    columns: [
      { text: 'ScamReport — Authority Handoff', style: 'muted', alignment: 'left' },
      { text: `${subjectLabel} #${shortRef}`, style: 'muted', alignment: 'right' },
    ],
  });
}

export function pageFooter(generatedAt: Date): TDocumentDefinitions['footer'] {
  const stamp = generatedAt.toISOString().replace('T', ' ').slice(0, 19) + ' UTC';
  return (currentPage, pageCount) => ({
    margin: [40, 0, 40, 24],
    columns: [
      { text: `Generated ${stamp}`, style: 'muted', alignment: 'left' },
      { text: `Page ${currentPage} of ${pageCount}`, style: 'muted', alignment: 'right' },
    ],
  });
}

export function sectionTitle(text: string): ContentText {
  return { text: text.toUpperCase(), style: 'label', margin: [0, 12, 0, 4] };
}

export function pill(text: string, kind: 'scam' | 'warn' | 'ok' | 'neutral' = 'neutral'): ContentText {
  const style = kind === 'scam' ? 'pillScam' : kind === 'warn' ? 'pillWarn' : kind === 'ok' ? 'pillOk' : 'pillNeutral';
  return { text, style };
}

export function kvTable(rows: Array<[string, string]>): ContentTable {
  return {
    table: {
      widths: ['auto', '*'],
      body: rows.map(([k, v]) => [
        { text: k, style: 'muted' },
        { text: v },
      ]),
    },
    layout: 'noBorders',
  };
}

export function disclaimer(): ContentText {
  return {
    text:
      'Disclaimer: Compiled by ScamReport from user-submitted reports. All ' +
      'attributions remain alleged until corroborated through your own ' +
      'verification process. Reporter identity withheld for source-protection.',
    style: 'disclaimer',
    margin: [0, 24, 0, 0],
  };
}

export function shortId(id: string): string {
  return id.replace(/-/g, '').slice(0, 8);
}

export function formatDate(d: Date | string | null | undefined): string {
  if (!d) return '—';
  const date = typeof d === 'string' ? new Date(d) : d;
  return date.toISOString().replace('T', ' ').slice(0, 16);
}
