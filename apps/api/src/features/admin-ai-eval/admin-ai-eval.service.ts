// File-backed service for the admin AI-eval views. Reads the JSONL trend file
// and the latest full-summary mirror written by `scripts/eval-ai.ts`. Returns
// null/empty when the files do not yet exist (fresh install, no cron run yet).

import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import type {
  AdminAiEvalHistoryEntry,
  AdminAiEvalLatestResponse,
  AiEvalSummary,
} from '@my-product/shared';

const EVAL_DIR = resolve(import.meta.dirname, '../../../eval');
const HISTORY_PATH = resolve(EVAL_DIR, 'history.jsonl');
const LATEST_PATH = resolve(EVAL_DIR, 'latest.json');

const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 365;

export function getLatestSummary(): AdminAiEvalLatestResponse {
  if (!existsSync(LATEST_PATH)) return { summary: null };
  try {
    const raw = readFileSync(LATEST_PATH, 'utf8');
    return { summary: JSON.parse(raw) as AiEvalSummary };
  } catch {
    return { summary: null };
  }
}

export function getHistory(limit?: number): {
  entries: AdminAiEvalHistoryEntry[];
} {
  if (!existsSync(HISTORY_PATH)) return { entries: [] };
  const n = Math.min(Math.max(1, limit ?? DEFAULT_LIMIT), MAX_LIMIT);
  let raw: string;
  try {
    raw = readFileSync(HISTORY_PATH, 'utf8');
  } catch {
    return { entries: [] };
  }
  const lines = raw.split('\n').filter((l) => l.length > 0);
  const tail = lines.slice(-n);
  const entries: AdminAiEvalHistoryEntry[] = [];
  for (const line of tail) {
    try {
      entries.push(JSON.parse(line) as AdminAiEvalHistoryEntry);
    } catch {
      // Skip malformed lines silently — one bad line should not poison the view.
      continue;
    }
  }
  return { entries };
}
