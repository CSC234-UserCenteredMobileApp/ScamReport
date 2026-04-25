import 'dotenv/config';
import { defineConfig, env } from 'prisma/config';

// Read at devtime by the Prisma CLI for migrations and other admin tasks.
// Runtime queries do NOT come through here — they go through the driver
// adapter constructed in src/core/db/client.ts.
//
// `datasource.url` here is the DIRECT (unpooled) connection. Supabase requires
// a direct connection for migrations because PgBouncer/Supavisor strip out
// some statements that migrations rely on.
export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url: env('DIRECT_URL'),
  },
});
