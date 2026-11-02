/* Takes a consistent copy of the SQLite database while the API may be running (`VACUUM INTO` reads a
 * snapshot and writes a compact, standalone file), keeps the newest DB_BACKUP_KEEP (default 14) and
 * makes each readable by its owner only. deploy.sh runs it before every migration; schedule it daily too.
 *
 *   npm run db:backup -w @syniastrolms/api                  -> <database dir>/backups/<name>-<UTC stamp>.db
 *   DB_BACKUP_DIR=/path npm run db:backup -w @syniastrolms/api
 *
 * The copy holds every account, password hash and payment record: keep it off the web root and out of git.
 */
import 'dotenv/config';

import { chmodSync, existsSync, mkdirSync, readdirSync, rmSync, statSync } from 'node:fs';
import path from 'node:path';
import { PrismaClient } from '@prisma/client';

const url = process.env.DATABASE_URL ?? '';
if (!url.startsWith('file:')) {
  console.error('[backup] DATABASE_URL is not a SQLite file: URL; back this database up with its own tools.');
  process.exit(1);
}
// Prisma resolves a relative file: URL against the schema's folder.
const file = path.resolve(path.join(import.meta.dirname, '..', 'prisma'), url.slice('file:'.length).split('?')[0]);
if (!existsSync(file)) {
  console.error(`[backup] No database at ${file}; nothing to back up.`);
  process.exit(0);
}
const dir = path.resolve(process.env.DB_BACKUP_DIR ?? path.join(path.dirname(file), 'backups'));
const keep = Math.max(1, Number(process.env.DB_BACKUP_KEEP ?? 14));
mkdirSync(dir, { recursive: true, mode: 0o700 });

const base = path.basename(file, path.extname(file));
const stamp = new Date().toISOString().replace(/[-:]/g, '').replace('T', '-').replace('.', '').replace('Z', '');
const target = path.join(dir, `${base}-${stamp}.db`);
if (target.includes("'")) throw new Error(`[backup] Refusing a backup path with a quote in it: ${target}`);

const prisma = new PrismaClient();
try {
  await prisma.$executeRawUnsafe(`VACUUM INTO '${target}'`);
} finally {
  await prisma.$disconnect();
}
chmodSync(target, 0o600);
const size = statSync(target).size;
console.log(`[backup] ✓ ${file} -> ${target} (${(size / 1024 / 1024).toFixed(1)} MB)`);

const old = readdirSync(dir)
  .filter((f) => f.startsWith(`${base}-`) && f.endsWith('.db'))
  .sort()
  .reverse()
  .slice(keep);
for (const f of old) rmSync(path.join(dir, f));
if (old.length) console.log(`[backup] Removed ${old.length} older backup(s); keeping the newest ${keep}.`);
