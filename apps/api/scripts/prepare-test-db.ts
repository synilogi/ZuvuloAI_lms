/* Builds a fresh, seeded SQLite database for the test suite:
 * delete prisma/test.db → apply migrations → run the seed → backfill admin permissions.
 * Runs as `pretest`. */
import { execSync } from 'node:child_process';
import { rmSync } from 'node:fs';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const dbFile = resolve(root, 'prisma/test.db');
for (const suffix of ['', '-journal', '-wal', '-shm']) rmSync(`${dbFile}${suffix}`, { force: true });

const env = { ...process.env, DATABASE_URL: 'file:./test.db', SEED_QUIET: '1' };
execSync('npx prisma migrate deploy --schema=./prisma/schema.prisma', { cwd: root, env, stdio: 'inherit' });
execSync('npx tsx prisma/seed.ts', { cwd: root, env, stdio: 'inherit' });
// The seed grants its admin the catalogue, so this backfill writes nothing; it stays so the suite still
// starts from complete admins if a future seed creates one without grants.
execSync('npx tsx scripts/backfill-admin-permissions.ts', { cwd: root, env, stdio: 'inherit' });
console.log('[test-db] prisma/test.db ready');
