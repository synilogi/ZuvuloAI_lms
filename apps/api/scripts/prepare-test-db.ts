/* Builds a fresh, seeded MySQL database for the test suite:
 * drop and recreate it → apply migrations → run the seed → backfill admin permissions.
 * Runs as `pretest`. Point it elsewhere with TEST_DATABASE_URL; the name must end in `_test`, so it can never touch anything else. */
import { execSync } from 'node:child_process';
import { resolve } from 'node:path';
import { PrismaClient } from '@prisma/client';

const root = resolve(import.meta.dirname, '..');
const url = process.env.TEST_DATABASE_URL ?? 'mysql://root:root@127.0.0.1:3306/zuviloai_test';
const parsed = new URL(url);
const name = parsed.pathname.slice(1);
if (!/^\w+_test$/.test(name)) throw new Error('[test-db] TEST_DATABASE_URL must name a database ending in _test.');

// Connected to the server's own `mysql` schema, since the test database may not exist yet.
parsed.pathname = '/mysql';
const server = new PrismaClient({ datasourceUrl: parsed.toString() });
try {
  await server.$executeRawUnsafe(`DROP DATABASE IF EXISTS \`${name}\``);
  await server.$executeRawUnsafe(`CREATE DATABASE \`${name}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`);
} finally {
  await server.$disconnect();
}

const env = { ...process.env, DATABASE_URL: url, SEED_QUIET: '1' };
execSync('npx prisma migrate deploy --schema=./prisma/schema.prisma', { cwd: root, env, stdio: 'inherit' });
execSync('npx tsx prisma/seed.ts', { cwd: root, env, stdio: 'inherit' });
// The seed grants its admin the catalogue, so this backfill writes nothing; it stays so the suite still
// starts from complete admins if a future seed creates one without grants.
execSync('npx tsx scripts/backfill-admin-permissions.ts', { cwd: root, env, stdio: 'inherit' });
console.log('[test-db] ready');
