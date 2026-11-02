import request from 'supertest';
import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest';
import { countedPath, funnelRates } from '@syniastrolms/domain';

import { alertText, shouldAlert } from '../lib/alerts.js';
import { onObservationError, observabilitySnapshot, observe } from '../lib/observe.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { isBot, istDay } from '../lib/siteMetrics.js';
import { db } from '../test/db.js';
import { PASSWORD, app, as, newStudent, unique, type Client } from '../test/helpers.js';

/* What an operator sees (docs/19): visits counted without identifying anyone, browser errors, and alerts. */

const BROWSER = 'Mozilla/5.0 (X11; Linux x86_64) Chrome/130 Safari/537.36';
let owner: Client;

const view = (path: string, ua = BROWSER) => request(app).post('/public/metrics').set('User-Agent', ua).send({ path });
const countOf = async (path: string) => (await db.siteMetricDay.aggregate({ where: { path }, _sum: { count: true } }))._sum.count ?? 0;

beforeAll(async () => {
  const email = `ops-owner-${unique()}@example.test`;
  await provisionSuperAdmin({ email, name: 'Ops Owner', password: PASSWORD });
  owner = await as({ email, password: PASSWORD });
});

afterEach(() => onObservationError(undefined));

describe('counting visits', () => {
  it('counts public pages only, and folds the home page together', () => {
    expect(countedPath('/')).toBe('/');
    expect(countedPath('/welcome')).toBe('/');
    expect(countedPath('/courses/maths/')).toBe('/courses/maths');
    for (const path of [
      '/admin/students',
      '/superadmin',
      '/learn/abc',
      '/home',
      '/reset-password/a-token',
      '/invite/a-token',
      '/ref/ABC123',
      '/courses/<script>',
      '/purchases',
    ])
      expect(countedPath(path), path).toBeNull();
  });

  it('adds one view a time, on one row a day', async () => {
    const path = `/courses/metric-${unique()}`;
    for (let i = 0; i < 3; i++) expect((await view(path)).status).toBe(204);
    expect(await countOf(path)).toBe(3);
    expect(await db.siteMetricDay.count({ where: { path } })).toBe(1);
  });

  it('survives many views of one page at once', async () => {
    const path = `/courses/rush-${unique()}`;
    const answers = await Promise.all(Array.from({ length: 12 }, () => view(path)));
    expect(answers.every((a) => a.status === 204)).toBe(true);
    expect(await countOf(path)).toBe(12);
  });

  it('ignores bots and private addresses, answering the same', async () => {
    const path = `/courses/bot-${unique()}`;
    expect((await view(path, 'Mozilla/5.0 (compatible; Googlebot/2.1)')).status).toBe(204);
    expect(await countOf(path)).toBe(0);
    expect(isBot(undefined)).toBe(true);
    const before = await db.siteMetricDay.count();
    expect((await view('/admin/students')).status).toBe(204);
    expect(await db.siteMetricDay.count()).toBe(before);
  });

  it('holds nothing about a person', () => {
    expect(Object.keys(db.siteMetricDay.fields).sort()).toEqual(['count', 'day', 'id', 'path', 'tenantId']);
  });

  it('dates a view by India’s day', () => {
    expect(istDay(new Date('2026-11-02T19:00:00Z'))).toBe('2026-11-03');
    expect(istDay(new Date('2026-11-02T18:00:00Z'))).toBe('2026-11-02');
  });
});

describe('the visitor report', () => {
  it('belongs to the Super Admin', async () => {
    const learner = await newStudent();
    expect((await learner.get('/superadmin/sales/visitors')).status).toBe(403);
    expect((await request(app).get('/superadmin/sales/visitors')).status).toBe(401);
  });

  it('adds up views a day, pages and the funnel', async () => {
    const path = `/courses/report-${unique()}`;
    await view(path);
    await view('/register');
    const res = await owner.get('/superadmin/sales/visitors', { days: 7 });
    expect(res.status).toBe(200);
    expect(res.body.daily).toHaveLength(7);
    expect(res.body.funnel.map((s: { label: string }) => s.label)).toEqual([
      'Page views',
      'Course and bundle pages opened',
      'Sign-up page opened',
      'New learners',
      'Checkouts started',
      'Orders paid',
    ]);
    expect(res.body.funnel[0].count).toBe(res.body.daily.reduce((n: number, d: { views: number }) => n + d.views, 0));
    expect(res.body.funnel[1].count).toBeGreaterThan(0);
    expect((await owner.get('/superadmin/sales/visitors', { days: 9999 })).status).toBe(400);
  });

  it('works out how many reached each step', () => {
    expect(
      funnelRates([
        { label: 'a', count: 200 },
        { label: 'b', count: 50 },
        { label: 'c', count: 0 },
        { label: 'd', count: 0 },
      ]),
    ).toEqual([null, 25, 0, null]);
  });
});

describe('browser errors', () => {
  it('reach the operator’s window, with secrets masked', async () => {
    const res = await request(app)
      .post('/public/client-errors')
      .set('User-Agent', BROWSER)
      .send({ message: `Boom ${unique()} token=abc123secret`, path: '/courses' });
    expect(res.status).toBe(204);
    const seen = observabilitySnapshot({ signal: 'client.error', limit: 5 });
    expect(JSON.stringify(seen)).toContain('Boom');
    expect(JSON.stringify(seen)).not.toContain('abc123secret');
  });

  it('refuses an oversized report', async () => {
    expect(
      (
        await request(app)
          .post('/public/client-errors')
          .send({ message: 'x'.repeat(501) })
      ).status,
    ).toBe(400);
  });
});

describe('alerts', () => {
  it('hear errors, not warnings', () => {
    const heard = vi.fn();
    onObservationError(heard);
    observe('client.error', { message: 'a warning' });
    expect(heard).not.toHaveBeenCalled();
    observe('job.failed', { job: 'test', password: 'hunter2' }, 'error');
    expect(heard).toHaveBeenCalledTimes(1);
    expect(JSON.stringify(heard.mock.calls[0][0])).not.toContain('hunter2');
  });

  it('stay quiet while one failure repeats', () => {
    const signal = `test.${unique()}`;
    expect(shouldAlert(signal, 1_000)).toBe(true);
    expect(shouldAlert(signal, 2_000)).toBe(false);
    expect(shouldAlert(signal, 1_000 + 16 * 60_000)).toBe(true);
  });

  it('survive a listener that throws', () => {
    onObservationError(() => {
      throw new Error('alert transport down');
    });
    expect(() => observe('job.failed', { job: 'test' }, 'error')).not.toThrow();
  });

  it('read clearly', () => {
    expect(alertText({ signal: 'job.failed', at: '2026-11-02T00:00:00Z', fields: { job: 'x' } })).toContain('job.failed');
  });
});
