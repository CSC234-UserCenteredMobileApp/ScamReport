import 'dotenv/config';
import { defineConfig } from 'prisma/config';

// Read at devtime by the Prisma CLI for migrations and other admin tasks.
// Runtime queries do NOT come through here — they go through the driver
// adapter constructed in src/core/db/client.ts.
//
// `datasource.url` here is the DIRECT (unpooled) connection. Supabase requires
// a direct connection for migrations because PgBouncer/Supavisor strip out
// some statements that migrations rely on.
//
// We fall back to a placeholder when DIRECT_URL is unset so that
// `prisma generate` (which never connects) succeeds in CI and on a fresh
// clone before .env is populated. Anything that *does* connect (`prisma
// migrate dev`, etc.) will fail loudly against the placeholder, which is the
// behaviour we want.
const DIRECT_URL =
  process.env.DIRECT_URL ??
  'postgresql://unset:unset@localhost:5432/unset';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url: DIRECT_URL,
  },
});
