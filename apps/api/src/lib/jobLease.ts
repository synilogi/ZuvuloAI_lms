import { randomUUID } from 'node:crypto';
import { hostname } from 'node:os';
import { Prisma } from '@prisma/client';

import { db } from './db.js';
import { runAsPlatform } from './tenancy.js';

/*
 * Job leases (SAAS-022). The scheduler runs in every API process; with more than one, each job would run in
 * all of them at once. Before a job runs, its process takes the job's lease — one row per job — and gives it
 * back when the job ends. A second process finds the lease held and skips the job this tick. A holder that dies
 * mid-job leaves a lease that expires after its time-to-live, and the next process takes it over. Every job is
 * idempotent as well, so a lease that expires under a job still running long only risks work that repeats
 * safely, never work that doubles.
 */

/** This process, as a lease names it: the host, the pid, and a per-boot id so a restarted pid is not mistaken for the old one. */
export const LEASE_HOLDER = `${hostname()}:${process.pid}:${randomUUID().slice(0, 8)}`;

/** How long a lease lasts if its holder never gives it back. Longer than any job's tick budget. */
export const LEASE_TTL_MS = 5 * 60_000;

/** Takes `job`'s lease for `holder` if it is free, expired or already `holder`'s. Atomic: a create, else a conditional update. */
export async function acquireLease(job: string, holder = LEASE_HOLDER, now = new Date(), ttlMs = LEASE_TTL_MS): Promise<boolean> {
  const expiresAt = new Date(now.getTime() + ttlMs);
  return runAsPlatform('the scheduler takes a job lease', async () => {
    try {
      await db.jobLease.create({ data: { job, holder, acquiredAt: now, expiresAt } });
      return true;
    } catch (err) {
      if (!(err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002')) throw err;
    }
    const { count } = await db.jobLease.updateMany({
      where: { job, OR: [{ expiresAt: { lte: now } }, { holder }] },
      data: { holder, acquiredAt: now, expiresAt },
    });
    return count === 1;
  });
}

/** Gives the lease back, recording how the run ended. Only its holder can. */
export async function releaseLease(job: string, outcome: 'ok' | 'failed', holder = LEASE_HOLDER, now = new Date()): Promise<void> {
  await runAsPlatform('the scheduler gives a job lease back', () =>
    db.jobLease.updateMany({ where: { job, holder }, data: { expiresAt: now, lastRunAt: now, lastOutcome: outcome, lastHolder: holder } }),
  );
}

/**
 * Runs `fn` under `job`'s lease, or not at all when another process holds it (answering `{ ran: false }`). The
 * lease is given back whether `fn` succeeds or throws; a throw is passed on.
 */
export async function withLease<T>(job: string, fn: () => Promise<T>, holder = LEASE_HOLDER): Promise<{ ran: true; result: T } | { ran: false }> {
  if (!(await acquireLease(job, holder))) return { ran: false };
  try {
    const result = await fn();
    await releaseLease(job, 'ok', holder);
    return { ran: true, result };
  } catch (err) {
    await releaseLease(job, 'failed', holder);
    throw err;
  }
}

/** Every lease, for the Super Admin's system page: who holds what, until when, and how each job last ended. */
export async function leaseStatus(now = new Date()) {
  const rows = await runAsPlatform('the Super Admin reads the job leases', () => db.jobLease.findMany({ orderBy: { job: 'asc' } }));
  return rows.map((l) => ({
    job: l.job,
    held: l.expiresAt > now,
    ...(l.expiresAt > now ? { holder: l.holder, since: l.acquiredAt.toISOString(), expiresAt: l.expiresAt.toISOString() } : {}),
    ...(l.lastRunAt ? { lastRunAt: l.lastRunAt.toISOString(), lastOutcome: l.lastOutcome ?? undefined, lastHolder: l.lastHolder ?? undefined } : {}),
    thisProcess: l.holder === LEASE_HOLDER && l.expiresAt > now,
  }));
}
