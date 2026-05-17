// Seed safety guard. Imported by every seed entrypoint — NEVER run directly.
//
// Why this exists:
//   The seed scripts wipe and rewrite every data table. A misconfigured shell
//   that points DATABASE_URL at production would destroy real user data.
//   This module is the only kill-switch between "bun run prisma/reset-and-seed"
//   and "all rows are gone."
//
// Behaviour:
//   1. process.exit(1) if NODE_ENV=production or BUN_ENV=production.
//   2. process.exit(1) if DATABASE_URL host contains 'pooler.supabase.com'
//      AND the calling script was not invoked with --allow-supabase. (Supabase
//      dev pooler is fine; explicit flag prevents accidental prod pooler use.)
//   3. Print which DB the seed is about to overwrite.
//   4. Require typed YES confirmation:
//        - Interactive TTY: prompt on stdin, accept exact "YES".
//        - Non-interactive: require env var SEED_CONFIRM=YES.
//
// Wiring:
//   The orchestrator (reset-and-seed.ts) runs the interactive prompt ONCE,
//   then propagates SEED_CONFIRM=YES into spawned-child env. Each child
//   script still calls assertSafeToSeed() at the top — defense-in-depth for
//   anyone who runs e.g. `bun run prisma/seed-flow.ts` outside the orchestrator.

import { config } from 'dotenv';
import { resolve } from 'path';

config({ path: resolve(import.meta.dirname, '../.env') });

function parseDbHost(url: string | undefined): string {
  if (!url) return '<no DATABASE_URL>';
  try {
    const u = new URL(url);
    const db = u.pathname.replace(/^\//, '');
    return `${u.host}/${db}`;
  } catch {
    return '<unparseable DATABASE_URL>';
  }
}

function readYesFromStdin(): Promise<string> {
  return new Promise((resolveAnswer) => {
    process.stdout.write('Type YES to proceed (anything else aborts): ');
    let buf = '';
    process.stdin.setEncoding('utf-8');
    const onData = (chunk: string) => {
      buf += chunk;
      if (buf.includes('\n')) {
        process.stdin.removeListener('data', onData);
        process.stdin.pause();
        resolveAnswer(buf.trim());
      }
    };
    process.stdin.resume();
    process.stdin.on('data', onData);
  });
}

export async function assertSafeToSeed(opts: { allowSupabase?: boolean } = {}): Promise<void> {
  const nodeEnv = process.env.NODE_ENV ?? '';
  const bunEnv = process.env.BUN_ENV ?? '';
  if (nodeEnv === 'production' || bunEnv === 'production') {
    console.error('[seed-safety] refusing to run: NODE_ENV/BUN_ENV=production');
    process.exit(1);
  }

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    console.error('[seed-safety] refusing to run: DATABASE_URL is not set');
    process.exit(1);
  }

  const allowSupabase =
    opts.allowSupabase ||
    process.argv.includes('--allow-supabase') ||
    process.env.SEED_ALLOW_SUPABASE === '1';
  if (dbUrl.includes('pooler.supabase.com') && !allowSupabase) {
    console.error(
      '[seed-safety] refusing to run: DATABASE_URL points at a Supabase pooler. ' +
        'Pass --allow-supabase (or set the orchestrator flag) if this is the dev pooler.',
    );
    process.exit(1);
  }

  const hostDb = parseDbHost(dbUrl);
  console.log(`[seed-safety] target = ${hostDb}`);

  if (process.env.SEED_CONFIRM === 'YES') {
    console.log('[seed-safety] SEED_CONFIRM=YES — proceeding.');
    return;
  }

  if (!process.stdin.isTTY) {
    console.error(
      '[seed-safety] refusing to run: non-interactive shell and SEED_CONFIRM != YES',
    );
    process.exit(1);
  }

  const answer = await readYesFromStdin();
  if (answer !== 'YES') {
    console.error('[seed-safety] aborted: expected exact "YES", got ' + JSON.stringify(answer));
    process.exit(1);
  }
}
