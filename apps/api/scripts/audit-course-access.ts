/* Read-only audit for paid courses (migration 20261024120000_course_purchases). Changes nothing.
 *
 * For every academy it reports how its courses are priced after the migration, and the enrolments that exist in a
 * course which is now paid or not yet decided ("unset") without a verified purchase behind them — the learners who
 * joined for free before prices were enforced, and anyone staff added. Nothing is revoked: the owner decides, per
 * academy, what to do with them (see docs/14-LAUNCH-CHECKLIST.md, "Paid courses").
 *
 *   npm run courses:audit-access -w @syniastrolms/api
 */
import 'dotenv/config';

import { asPlatform } from '../src/lib/db.js';

const db = asPlatform('a read-only audit of course pricing and enrolments');

async function main() {
  const tenants = await db.tenant.findMany({ select: { id: true, slug: true, name: true, status: true }, orderBy: { createdAt: 'asc' } });
  for (const t of tenants) {
    const courses = await db.course.groupBy({ by: ['pricing'], where: { tenantId: t.id }, _count: { _all: true } });
    const unpaid = await db.enrollment.findMany({
      where: { tenantId: t.id, purchaseId: null, course: { pricing: { in: ['paid', 'unset'] } } },
      select: { source: true, status: true, course: { select: { pricing: true } } },
    });
    const bySource = new Map<string, number>();
    for (const e of unpaid) {
      const key = `${e.course.pricing} course · source ${e.source} · ${e.status}`;
      bySource.set(key, (bySource.get(key) ?? 0) + 1);
    }
    const sales = await db.coursePurchase.groupBy({ by: ['status'], where: { tenantId: t.id }, _count: { _all: true } });
    const review = await db.coursePurchase.count({ where: { tenantId: t.id, reviewReason: { not: null } } });
    console.log(`\n${t.name} (${t.slug}, ${t.status})`);
    console.log(`  courses: ${courses.map((c) => `${c.pricing} ${c._count._all}`).join(', ') || 'none'}`);
    console.log(`  enrolments in paid or undecided courses without a purchase: ${unpaid.length}`);
    for (const [key, n] of bySource) console.log(`    ${n} × ${key}`);
    console.log(`  purchases: ${sales.map((s) => `${s.status} ${s._count._all}`).join(', ') || 'none'}${review ? ` · ${review} need review` : ''}`);
  }
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => db.$disconnect());
