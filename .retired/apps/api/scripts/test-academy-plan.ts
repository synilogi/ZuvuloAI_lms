/* Test databases only (SAAS-025): subscribes the seeded academy to the plan `TEST_ACADEMY_PLAN` names, through the
 * subscription service, so a suite can run with ENTITLEMENT_ENFORCEMENT=on. Called by prepare-test-db.ts when that
 * variable is set, and by the E2E runner; refuses any database not named test.db or e2e.db. */
import { basename } from 'node:path';
import { db } from '../src/lib/db.js';
import { provisionSuperAdmin } from '../src/lib/provisionSuperAdmin.js';
import { createSubscription } from '../src/lib/subscriptions.js';
import { FIRST_TENANT_ID, runAsPlatform } from '../src/lib/tenancy.js';

// A test database only: `test.db` or `e2e.db`, relative to prisma/ or (for an isolated E2E run) an absolute path — never
// dev.db, prod.db or anything else.
const dbUrl = process.env.DATABASE_URL ?? '';
const dbName = dbUrl.startsWith('file:') ? basename(dbUrl.slice('file:'.length)) : '';
if (!['test.db', 'e2e.db'].includes(dbName)) throw new Error('test-academy-plan runs against a test.db or e2e.db only.');
const code = process.env.TEST_ACADEMY_PLAN!;
const { user } = await provisionSuperAdmin({ email: 'test-plan-operator@example.com', password: 'test-plan-operator-1', name: 'Test plan operator' });
const plan = await runAsPlatform('test fixture: the plan for the seeded academy', () =>
  db.plan.findUniqueOrThrow({ where: { code }, include: { versions: { orderBy: { version: 'desc' }, take: 1 } } }),
);
// Whichever cycle the plan is sold on.
const cycle = plan.versions[0]?.monthlyPrice !== null ? 'monthly' : 'annual';
await runAsPlatform('test fixture: subscribe the seeded academy', () =>
  createSubscription({ type: 'user', auth: { sub: user.id, role: 'superadmin' } }, { tenantId: FIRST_TENANT_ID, planId: plan.id, cycle, start: 'active' }),
);
console.log(`[test-db] the seeded academy is on ${code}`);
process.exit(0);
