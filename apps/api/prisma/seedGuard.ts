/**
 * Why the demo seed must not run here, if it must not. It wipes every academy's rows platform-wide, so it runs only
 * against a development or test database on this machine, one whose name ends in `_dev`, `_test` or `_e2e`, and never
 * where anything says production: NODE_ENV, APP_ENV, or an address on zuviloai.com. An operator's shell on the server
 * usually has no NODE_ENV at all, which is why the database's name is checked too.
 */
export function demoSeedRefusal(env: NodeJS.ProcessEnv): string | null {
  if (env.NODE_ENV === 'production' || /^prod/i.test(env.APP_ENV ?? '')) return 'this is a production environment';
  if ([env.APP_URL, env.CORS_ORIGIN].some((url) => /(^|[/.])zuviloai\.com\.?(:|\/|$)/i.test(url ?? ''))) return 'it serves zuviloai.com';
  const parsed = URL.canParse(env.DATABASE_URL ?? '') ? new URL(env.DATABASE_URL!) : null;
  const name = parsed?.pathname.slice(1) ?? '';
  if (!/_(dev|test|e2e)$/.test(name)) return `its database (${name || 'unknown'}) is not named *_dev, *_test or *_e2e`;
  if (!['127.0.0.1', 'localhost'].includes(parsed!.hostname)) return `its database is on ${parsed!.hostname}, not this machine`;
  return null;
}
