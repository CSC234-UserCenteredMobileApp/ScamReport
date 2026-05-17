// Multi-sheet XLSX builder for the analytics bundle.
//
// Uses ExcelJS's in-memory Workbook + writeBuffer rather than the streaming
// WorkbookWriter — at the 50k-row cap the buffered size (~5–10 MB) is well
// under what a browser blob download can handle, and it avoids juggling a
// Node Writable<>Web ReadableStream adapter on Bun.

import ExcelJS from 'exceljs';

type AnyRow = { [k: string]: unknown };

export interface Sheet {
  name: string;
  headers: readonly string[];
  rows: AsyncIterable<object> | Iterable<object>;
}

export async function buildXlsxBuffer(
  sheets: ReadonlyArray<Sheet>,
): Promise<Uint8Array> {
  const wb = new ExcelJS.Workbook();
  wb.creator = 'scamreport';
  wb.created = new Date();

  for (const s of sheets) {
    const ws = wb.addWorksheet(s.name);
    ws.columns = s.headers.map((h) => ({ header: h, key: h }));
    if (Symbol.asyncIterator in (s.rows as object)) {
      for await (const r of s.rows as AsyncIterable<object>) {
        ws.addRow(toRowArray(s.headers, r));
      }
    } else {
      for (const r of s.rows as Iterable<object>) {
        ws.addRow(toRowArray(s.headers, r));
      }
    }
  }

  const buf = await wb.xlsx.writeBuffer();
  return new Uint8Array(buf as ArrayBuffer);
}

function toRowArray(headers: readonly string[], row: object): unknown[] {
  const r = row as AnyRow;
  const out: unknown[] = [];
  for (const h of headers) {
    out.push(serialiseCell(r[h]));
  }
  return out;
}

function serialiseCell(v: unknown): unknown {
  if (v === null || v === undefined) return null;
  if (v instanceof Date) return v;
  if (typeof v === 'bigint') return Number(v);
  if (typeof v === 'object') return JSON.stringify(v);
  return v;
}
