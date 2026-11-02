import { countedPath, type VisitorReport } from '@syniastrolms/domain';

import { db } from './db.js';
import { tenant } from './tenancy.js';

/*
 * How many people reach each public page (docs/19). A count per page per day and nothing else: no cookie, no address, no account,
 * so there is nothing here that identifies anyone. A browser that asks not to be tracked is not counted, and neither is a known bot.
 */

const BOT = /bot|crawl|spider|slurp|headless|lighthouse|facebookexternalhit|whatsapp|preview|curl|wget|python-requests|axios|node-fetch/i;

export const isBot = (userAgent: string | undefined) => !userAgent || BOT.test(userAgent);

/** A day as India counts it, since that is when the company's day starts and ends. */
export const istDay = (at: Date) => new Date(at.getTime() + 5.5 * 3_600_000).toISOString().slice(0, 10);

/** Adds one view. Anything that is not a public page is ignored, so this cannot be filled with arbitrary rows or private addresses. */
export async function countPageView(pathname: string, now = new Date()): Promise<boolean> {
  const path = countedPath(pathname);
  if (!path) return false;
  const day = istDay(now);
  const { tenantId } = tenant();
  const add = () => db.siteMetricDay.updateMany({ where: { tenantId, day, path }, data: { count: { increment: 1 } } });
  if ((await add()).count > 0) return true;
  try {
    await db.siteMetricDay.create({ data: { tenantId, day, path, count: 1 } });
  } catch (err) {
    // Two first views of the day at once: the other made the row, so this one adds to it.
    if ((err as { code?: string }).code !== 'P2002') throw err;
    await add();
  }
  return true;
}

const sum = (rows: { _sum: { count: number | null } }[]) => rows.reduce((n, r) => n + (r._sum.count ?? 0), 0);

/** The last `days` days: views a day, the most visited pages, and how far people get from a first visit to a paid order. */
export async function visitorReport(days: number, now = new Date()): Promise<VisitorReport> {
  const dayList = Array.from({ length: days }, (_, i) => istDay(new Date(now.getTime() - (days - 1 - i) * 86_400_000)));
  const [from, to] = [dayList[0], dayList[days - 1]];
  const since = new Date(`${from}T00:00:00+05:30`);
  const inRange = { day: { gte: from, lte: to } };
  const [byDay, byPath, signups, carts, bundleCarts, paid, bundlesPaid] = await Promise.all([
    db.siteMetricDay.groupBy({ by: ['day'], where: inRange, _sum: { count: true } }),
    db.siteMetricDay.groupBy({ by: ['path'], where: inRange, _sum: { count: true } }),
    db.user.count({ where: { role: 'student', createdAt: { gte: since } } }),
    // A share of a bundle is counted once, as its bundle order.
    db.coursePurchase.count({ where: { createdAt: { gte: since }, bundlePurchaseId: null } }),
    db.bundlePurchase.count({ where: { createdAt: { gte: since } } }),
    db.coursePurchase.count({ where: { status: 'paid', paidAt: { gte: since }, bundlePurchaseId: null } }),
    db.bundlePurchase.count({ where: { status: 'paid', paidAt: { gte: since } } }),
  ]);
  const viewsOn = new Map(byDay.map((r) => [r.day, r._sum.count ?? 0]));
  const views = byPath.map((r) => ({ path: r.path, views: r._sum.count ?? 0 })).sort((a, b) => b.views - a.views || a.path.localeCompare(b.path));
  const viewsOf = (test: (path: string) => boolean) => views.filter((v) => test(v.path)).reduce((n, v) => n + v.views, 0);
  return {
    days,
    from,
    to,
    daily: dayList.map((day) => ({ day, views: viewsOn.get(day) ?? 0 })),
    topPages: views.slice(0, 15),
    funnel: [
      { label: 'Page views', count: sum(byDay) },
      { label: 'Course and bundle pages opened', count: viewsOf((p) => /^\/(courses|bundles)\/[^/]+$/.test(p)) },
      { label: 'Sign-up page opened', count: viewsOf((p) => p === '/register') },
      { label: 'New learners', count: signups },
      { label: 'Checkouts started', count: carts + bundleCarts },
      { label: 'Orders paid', count: paid + bundlesPaid },
    ],
  };
}
