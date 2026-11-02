/* Takes a consistent copy of the MySQL database while the API may be running (`mysqldump --single-transaction` reads a
 * snapshot), gzips it, keeps the newest DB_BACKUP_KEEP (default 14) and makes each readable by its owner only.
 * deploy.sh runs it before every migration; schedule it daily too.
 *
 *   npm run db:backup -w @syniastrolms/api                  -> <DB_BACKUP_DIR>/<name>-<UTC stamp>.sql.gz
 *   DB_BACKUP_DIR=/path npm run db:backup -w @syniastrolms/api
 *
 * The copy holds every account, password hash and payment record: keep it off the web root and out of git.
 */
import 'dotenv/config';

import { spawn } from 'node:child_process';
import { chmodSync, createWriteStream, mkdirSync, readdirSync, rmSync, statSync } from 'node:fs';
import path from 'node:path';
import { pipeline } from 'node:stream/promises';
import { createGzip } from 'node:zlib';

const url = URL.canParse(process.env.DATABASE_URL ?? '') ? new URL(process.env.DATABASE_URL!) : null;
if (url?.protocol !== 'mysql:') {
  console.error('[backup] DATABASE_URL is not a mysql:// address.');
  process.exit(1);
}
const database = url.pathname.slice(1);
const dir = path.resolve(process.env.DB_BACKUP_DIR ?? path.join(import.meta.dirname, '..', 'backups'));
const keep = Math.max(1, Number(process.env.DB_BACKUP_KEEP ?? 14));
mkdirSync(dir, { recursive: true, mode: 0o700 });

const stamp = new Date().toISOString().replace(/[-:]/g, '').replace('T', '-').replace('.', '').replace('Z', '');
const target = path.join(dir, `${database}-${stamp}.sql.gz`);

// The password goes by the environment: on a command line any user on the machine could read it.
const dump = spawn(
  'mysqldump',
  ['--single-transaction', '--no-tablespaces', '--triggers', '--default-character-set=utf8mb4', '-h', url.hostname, '-P', url.port || '3306', '-u', decodeURIComponent(url.username), database],
  { env: { ...process.env, MYSQL_PWD: decodeURIComponent(url.password) }, stdio: ['ignore', 'pipe', 'inherit'] },
);
const exited = new Promise<number>((resolve, reject) => {
  dump.on('error', reject);
  dump.on('close', (code) => resolve(code ?? 1));
});
await pipeline(dump.stdout, createGzip(), createWriteStream(target, { mode: 0o600 }));
const code = await exited;
if (code !== 0) {
  rmSync(target, { force: true });
  console.error(`[backup] mysqldump failed with code ${code}; nothing was kept.`);
  process.exit(1);
}
chmodSync(target, 0o600);
console.log(`[backup] ✓ ${database} -> ${target} (${(statSync(target).size / 1024 / 1024).toFixed(1)} MB)`);

const old = readdirSync(dir)
  .filter((f) => f.startsWith(`${database}-`) && f.endsWith('.sql.gz'))
  .sort()
  .reverse()
  .slice(keep);
for (const f of old) rmSync(path.join(dir, f));
if (old.length) console.log(`[backup] Removed ${old.length} older backup(s); keeping the newest ${keep}.`);
