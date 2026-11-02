/* Lists every active Admin workspace (tenant) that plan enforcement would restrict: no live subscription
 * (never subscribed, or its last one canceled/expired), or one that is paused or in its grace period.
 * Under ENTITLEMENT_ENFORCEMENT such a workspace keeps reading everything but cannot add anything new
 * until it is on a plan — so on a server that already has customers, put each of them on a plan or a
 * trial (Super Admin › Admins › Billing) before enforcement reaches them. Reads only; changes nothing.
 *
 *   npm run enforcement:check -w @syniastrolms/api            report, exit 0
 *   npm run enforcement:check -w @syniastrolms/api -- --strict exit 1 when any workspace would be restricted
 */
import 'dotenv/config';

import { asPlatform } from '../src/lib/db.js';
import { entitlementEnforcement } from '../src/lib/entitlements.js';

const strict = process.argv.includes('--strict');
const db = asPlatform('checking which workspaces plan enforcement would restrict');

const tenants = await db.tenant.findMany({
  where: { status: 'active' },
  select: { id: true, name: true, slug: true, createdAt: true },
  orderBy: { createdAt: 'asc' },
});
const live = await db.subscription.findMany({
  where: { status: { notIn: ['canceled', 'expired'] } },
  select: { tenantId: true, status: true, trialEndAt: true, currentPeriodEndAt: true, gracePeriodEndAt: true },
});
const byTenant = new Map(live.map((s) => [s.tenantId, s]));
const users = await db.user.groupBy({ by: ['tenantId'], where: { deactivatedAt: null, tenantId: { not: null } }, _count: { _all: true } });
const userCount = new Map(users.map((u) => [u.tenantId, u._count._all]));

const day = (d: Date | null | undefined) => (d ? d.toISOString().slice(0, 10) : '—');
const restricted: string[] = [];
const atRisk: string[] = [];
for (const t of tenants) {
  const sub = byTenant.get(t.id);
  const label = `${t.name} (${t.slug}) — ${userCount.get(t.id) ?? 0} account(s)`;
  if (!sub) restricted.push(`${label}: no plan`);
  else if (sub.status === 'paused') restricted.push(`${label}: paused`);
  else if (sub.status === 'past_due') atRisk.push(`${label}: past due, grace until ${day(sub.gracePeriodEndAt)}`);
  else if (sub.status === 'trialing') atRisk.push(`${label}: trial ends ${day(sub.trialEndAt)}`);
}

const on = entitlementEnforcement();
console.log(`[enforcement] ENTITLEMENT_ENFORCEMENT is ${on ? 'ON' : 'off'} for this environment. ${tenants.length} active workspace(s).`);
if (restricted.length) {
  console.log(`[enforcement] ${restricted.length} workspace(s) ${on ? 'are' : 'would be'} restricted to read-only:`);
  for (const r of restricted) console.log(`    ✗ ${r}`);
  console.log('[enforcement] Put each on a plan or a trial from Super Admin › Admins › Billing, or let its Admin start the free trial.');
}
if (atRisk.length) {
  console.log(`[enforcement] ${atRisk.length} workspace(s) on a trial or overdue (restricted when it ends unpaid):`);
  for (const r of atRisk) console.log(`    • ${r}`);
}
if (!restricted.length) console.log('[enforcement] ✓ Every active workspace is on a plan.');
process.exit(strict && restricted.length ? 1 : 0);
