// ZIP-of-CSVs builder for the analytics bundle when the user picks
// `format=zip`. Built with fflate for zero-dep Bun safety.
//
// Each entry is a fully-materialised CSV string (the row cap keeps memory
// bounded). We use zipSync to avoid the async-flow complexity; throughput at
// 50k rows is trivial.

import { zipSync, strToU8 } from 'fflate';

export interface ZipEntry {
  filename: string; // e.g. "reports.csv"
  content: string;  // CSV (or JSON, or text) — UTF-8
}

export function buildZip(entries: ReadonlyArray<ZipEntry>): Uint8Array {
  const map: Record<string, Uint8Array> = {};
  for (const e of entries) {
    map[e.filename] = strToU8(e.content);
  }
  return zipSync(map, { level: 6 });
}
