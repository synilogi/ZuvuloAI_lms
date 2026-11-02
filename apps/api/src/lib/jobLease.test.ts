import { beforeAll, describe, expect, it } from 'vitest';

import { acquireLease, LEASE_HOLDER, LEASE_TTL_MS, leaseStatus, releaseLease, withLease } from './jobLease.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { runScheduledJobs } from './scheduler.js';
import { platformDb } from '../test/db.js';
import { as, unique, type Client } from '../test/helpers.js';

/* SAAS-022. Only one process runs a scheduled job at a time: the job's lease is taken atomically, given back
 * when the job ends, and taken over when its holder dies. */

const job = () => `test-job-${unique()}`;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

let platform: Client;
beforeAll(async () => {
  const email = `leases-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: 'leases-secret-1', name: 'Platform' });
  platform = await as({ email, password: 'leases-secret-1' });
});

describe('a job lease', () => {
  it('goes to exactly one of several processes asking at once', async () => {
    const name = job();
    const results = await Promise.all(['a', 'b', 'c', 'd', 'e'].map((holder) => acquireLease(name, holder)));
    expect(results.filter(Boolean)).toHaveLength(1);
  });

  it('runs the job in one process while another finds it held, and frees it afterwards', async () => {
    const name = job();
    let running = 0;
    let peak = 0;
    const work = async () => {
      running++;
      peak = Math.max(peak, running);
      await sleep(80);
      running--;
      return 'done';
    };
    const [first, second] = await Promise.all([withLease(name, work, 'process-1'), withLease(name, work, 'process-2')]);
    expect([first.ran, second.ran].sort()).toEqual([false, true]);
    expect(peak).toBe(1);
    // Given back: the next tick of either process runs it.
    expect((await withLease(name, work, 'process-2')).ran).toBe(true);
  });

  it('is taken over once its holder has died and it has expired — not before', async () => {
    const name = job();
    const start = new Date();
    expect(await acquireLease(name, 'dead-process', start)).toBe(true);
    expect(await acquireLease(name, 'survivor', new Date(start.getTime() + LEASE_TTL_MS - 1000))).toBe(false);
    expect(await acquireLease(name, 'survivor', new Date(start.getTime() + LEASE_TTL_MS + 1000))).toBe(true);
    expect((await platformDb.jobLease.findUniqueOrThrow({ where: { job: name } })).holder).toBe('survivor');
  });

  it('is given back when the job fails, which is recorded and passed on', async () => {
    const name = job();
    await expect(
      withLease(
        name,
        async () => {
          throw new Error('job broke');
        },
        'process-1',
      ),
    ).rejects.toThrow('job broke');
    const row = await platformDb.jobLease.findUniqueOrThrow({ where: { job: name } });
    expect(row).toMatchObject({ lastOutcome: 'failed', lastHolder: 'process-1' });
    expect(await acquireLease(name, 'process-2')).toBe(true);
  });

  it('can be given back only by its holder', async () => {
    const name = job();
    await acquireLease(name, 'owner');
    await releaseLease(name, 'ok', 'intruder');
    expect(await acquireLease(name, 'intruder')).toBe(false);
  });
});

describe('the scheduler’s tick', () => {
  it('skips a job another process holds and runs the rest', async () => {
    await acquireLease('quiz-session-expiry', 'another-api-process');
    try {
      const tick = await runScheduledJobs();
      expect(tick.quizzes).toBeNull();
      expect(tick.notifications).not.toBeNull();
    } finally {
      await releaseLease('quiz-session-expiry', 'ok', 'another-api-process');
    }
    const after = await runScheduledJobs();
    expect(after.quizzes).not.toBeNull();
  });

  it('shows every lease, its holder and how each job last ended on the Super Admin’s system page', async () => {
    await runScheduledJobs();
    const res = await platform.get('/superadmin/system');
    expect(res.status).toBe(200);
    const jobs = res.body.jobs as { job: string; held: boolean; lastOutcome?: string; lastHolder?: string }[];
    for (const name of ['scheduled-notifications', 'quiz-session-expiry', 'session-prune', 'email-delivery', 'push-delivery']) {
      const lease = jobs.find((j) => j.job === name);
      expect(lease, name).toMatchObject({ held: false, lastOutcome: 'ok', lastHolder: LEASE_HOLDER });
    }
    expect((await leaseStatus()).length).toBeGreaterThanOrEqual(5);
  });
});
