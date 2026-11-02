import { basename } from 'node:path';

/**
 * Why the demo seed must not run here, if it must not. It wipes every academy's rows platform-wide, so it runs only
 * against a development or test database file — `dev.db`, `test.db` or `e2e.db` — and never where anything says
 * production: NODE_ENV, APP_ENV, or an address on zuviloai.com. An operator's shell on the server usually has no
 * NODE_ENV at all, which is why the file name is checked too.
 */
export function demoSeedRefusal(env: NodeJS.ProcessEnv): string | null {
  if (env.NODE_ENV === 'production' || /^prod/i.test(env.APP_ENV ?? '')) return 'this is a production environment';
  if ([env.APP_URL, env.CORS_ORIGIN].some((url) => /(^|[/.])zuviloai\.com\.?(:|\/|$)/i.test(url ?? ''))) return 'it serves zuviloai.com';
  const url = env.DATABASE_URL ?? '';
  const file = url.startsWith('file:') ? basename(url.slice('file:'.length).split('?')[0]) : '';
  if (!['dev.db', 'test.db', 'e2e.db'].includes(file)) return `its database (${file || 'not a local file'}) is not dev.db, test.db or e2e.db`;
  return null;
}
