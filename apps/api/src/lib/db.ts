import { PrismaClient } from '@prisma/client';

import { isWriteConflict } from './errors.js';
import { bindContext, tenancyExtension } from './tenancy.js';

/**
 * The unscoped client. Only `lib/tenancy.ts` reads through it (its reference checks name the academy
 * explicitly); nothing else should, which is why it is not exported.
 */
// Read committed: a transaction sees what others have committed, so the unique-key races this codebase already handles resolve the
// same way they did on SQLite. MySQL's default (repeatable read) answers them with gap-lock deadlocks and stale reads instead.
const DEADLOCK_ATTEMPTS = 5;

/**
 * Runs a transaction again when MySQL chose it as a deadlock's victim. The database has already rolled it back, so running it
 * again starts clean; a transaction here only touches the database, never a gateway or a mailbox, so nothing outside is repeated.
 * Waits grow and vary, so the transactions that collided don't collide again in step.
 */
export async function retryOnDeadlock<T>(run: () => Promise<T>): Promise<T> {
  for (let attempt = 1; ; attempt++) {
    try {
      return await run();
    } catch (err) {
      if (attempt >= DEADLOCK_ATTEMPTS || !isWriteConflict(err)) throw err;
      await new Promise((resolve) => setTimeout(resolve, 20 * 2 ** attempt + Math.random() * 40));
    }
  }
}

/**
 * The connection pool, sized on purpose. Prisma's default follows the CPU count, which is 3 on a one-CPU server, and an open
 * transaction needs a second connection for the tenancy reference checks: a few at once would hold every connection while each waited
 * for another. A DATABASE_URL that names its own limits keeps them.
 */
export function pooledUrl(url: string | undefined): { url: string | undefined; connections: number } {
  const fallback = 20;
  if (!url || !URL.canParse(url)) return { url, connections: fallback };
  const parsed = new URL(url);
  if (!parsed.searchParams.has('connection_limit')) parsed.searchParams.set('connection_limit', String(fallback));
  if (!parsed.searchParams.has('pool_timeout')) parsed.searchParams.set('pool_timeout', '20');
  return { url: parsed.toString(), connections: Math.max(2, Number(parsed.searchParams.get('connection_limit')) || fallback) };
}

const pool = pooledUrl(process.env.DATABASE_URL);

const client = new PrismaClient({
  ...(pool.url ? { datasourceUrl: pool.url } : {}),
  transactionOptions: { isolationLevel: 'ReadCommitted', maxWait: 5_000, timeout: 15_000 },
});

/** At most half the pool in transactions at once, so a connection is always free for the checks those transactions wait on. */
const transactionSlots = {
  free: Math.max(1, Math.floor(pool.connections / 2)),
  waiting: [] as (() => void)[],
  async run<T>(work: () => Promise<T>): Promise<T> {
    if (this.free > 0) this.free--;
    else await new Promise<void>((resolve) => this.waiting.push(resolve));
    try {
      return await work();
    } finally {
      // A waiter inherits the slot; otherwise it goes back.
      const next = this.waiting.shift();
      if (next) next();
      else this.free++;
    }
  },
};

/**
 * A single write can deadlock too: Prisma runs a nested create as its own small transaction. Inside a larger transaction a query is
 * left alone, because the deadlock ended the whole of it, and the whole of it is what `retrying` runs again.
 */
const base = client.$extends({
  query: {
    $allOperations({ args, query, ...rest }) {
      const inTransaction = Boolean((rest as { __internalParams?: { transaction?: unknown } }).__internalParams?.transaction);
      return inTransaction ? query(args) : retryOnDeadlock(() => query(args));
    },
  },
}) as unknown as PrismaClient;

/** The client with its `$transaction` retried on a deadlock. Everything else passes straight through. */
function retrying<T extends object>(client: T): T {
  return new Proxy(client, {
    get(target, prop) {
      const value = Reflect.get(target, prop);
      if (prop !== '$transaction' || typeof value !== 'function') return value;
      return (...args: unknown[]) => retryOnDeadlock(() => transactionSlots.run(() => (value as (...a: unknown[]) => Promise<unknown>).apply(target, args)));
    },
  });
}

/**
 * The client every route, job and script uses. Every query on an academy-owned model is confined to
 * the academy of the current context — see `lib/tenancy.ts`.
 */
export const db = retrying(base.$extends(tenancyExtension(base)));

export type Db = typeof db;

/**
 * What a helper that may run inside a transaction accepts: `db` itself, or the client an interactive
 * `db.$transaction(async (tx) => …)` hands out. Both carry the tenancy extension.
 */
export type DbClient = Omit<Db, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>;

/** A client whose every query runs for one academy, whatever context it is called from. For tests and scripts. */
export const forTenant = (tenantId: string): Db =>
  retrying(base.$extends(bindContext({ kind: 'tenant', tenantId })).$extends(tenancyExtension(base))) as unknown as Db;

/** A client whose every query runs across every academy. For operator scripts and tests; name the reason. */
export const asPlatform = (reason: string): Db =>
  retrying(base.$extends(bindContext({ kind: 'platform', reason })).$extends(tenancyExtension(base))) as unknown as Db;
