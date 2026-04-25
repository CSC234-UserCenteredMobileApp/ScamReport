import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../../generated/prisma/client';

let _prisma: PrismaClient | null = null;

// Lazy singleton. Boots only on first call so the api can start without
// DATABASE_URL set (e.g. when working on routes that don't touch the DB).
export function getPrisma(): PrismaClient {
  if (_prisma) return _prisma;

  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL is not set — required to use Prisma.');
  }

  const adapter = new PrismaPg({ connectionString });
  _prisma = new PrismaClient({ adapter });
  return _prisma;
}
