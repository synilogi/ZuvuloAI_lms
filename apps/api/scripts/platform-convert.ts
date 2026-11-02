/* `npm run platform:convert [-- --apply]` — the data step of the platform conversion (docs/16 §3.3).
 *
 * The platform runs in one workspace (the Tenant named by DEFAULT_TENANT_SLUG). An academy from the SaaS era that is
 * not that workspace keeps every row it has, closed: its accounts are refused with WORKSPACE_CLOSED. This script
 * reports what the database holds and, with `--apply`, archives those academies. It deletes and moves nothing, and
 * running it twice changes nothing the second time.
 *
 * Dry run (the default) prints the report only. */
import 'dotenv/config';

import { asPlatform } from '../src/lib/db.js';

const apply = process.argv.includes('--apply');
const slug = process.env.DEFAULT_TENANT_SLUG ?? 'default';
const platform = asPlatform('the platform conversion reads every tenant');

async function main() {
  const workspace = await platform.tenant.findUnique({ where: { slug }, select: { id: true, name: true, status: true } });
  if (!workspace) throw new Error(`No tenant carries the slug "${slug}" (DEFAULT_TENANT_SLUG). Run the migrations and \`npm run seed:platform\` first.`);
  if (workspace.status !== 'active') throw new Error(`The workspace "${slug}" is ${workspace.status}; the platform cannot run in a closed workspace.`);
  console.log(`[convert] workspace: ${workspace.name} (${workspace.id}, slug "${slug}")${apply ? ' — applying' : ' — dry run'}`);
  // A workspace seeded before the rename (31 Oct 2026) still says ShubhLMS; the platform is ZuviloAI (docs/16, D-PLAT-14).
  if (workspace.name === 'ShubhLMS') {
    if (apply) await platform.tenant.update({ where: { id: workspace.id }, data: { name: 'ZuviloAI' } });
    console.log(`[convert] workspace name "ShubhLMS" ${apply ? 'renamed to' : 'would be renamed to'} "ZuviloAI"`);
  }
  // The name people actually see (emails, the code step) is the settings' own, a copy made when the row was seeded.
  const settings = await platform.settings.findUnique({ where: { tenantId: workspace.id }, select: { generalJson: true } });
  if (settings) {
    const general = JSON.parse(settings.generalJson) as { academyName?: string };
    if (general.academyName === 'ShubhLMS') {
      if (apply) await platform.settings.update({ where: { tenantId: workspace.id }, data: { generalJson: JSON.stringify({ ...general, academyName: 'ZuviloAI' }) } });
      console.log(`[convert] platform name in settings "ShubhLMS" ${apply ? 'changed to' : 'would be changed to'} "ZuviloAI"`);
    }
  }

  const others = await platform.tenant.findMany({ where: { id: { not: workspace.id } }, orderBy: { createdAt: 'asc' } });
  if (!others.length) console.log('[convert] no other academies: nothing to close.');
  for (const t of others) {
    const [users, courses, enrollments, purchases] = await Promise.all([
      platform.user.count({ where: { tenantId: t.id } }),
      platform.course.count({ where: { tenantId: t.id } }),
      platform.enrollment.count({ where: { tenantId: t.id } }),
      platform.coursePurchase.count({ where: { tenantId: t.id } }),
    ]);
    console.log(`[convert] academy "${t.name}" (${t.slug}, ${t.status}): ${users} accounts, ${courses} courses, ${enrollments} enrolments, ${purchases} purchases`);
    if (apply && t.status !== 'archived') {
      await platform.tenant.update({ where: { id: t.id }, data: { status: 'archived', statusReason: 'platform-conversion', statusChangedAt: new Date() } });
      console.log(`[convert]   archived (its rows are kept; its accounts are refused with WORKSPACE_CLOSED)`);
    }
  }

  // The SaaS-era records, for the owner's books: read-only history from here on (docs/16, D-PLAT-04).
  const [subscriptions, invoices, planChanges] = await Promise.all([
    platform.subscription.count({ where: { status: { in: ['trialing', 'active', 'past_due', 'paused', 'canceling'] } } }),
    platform.invoice.count({ where: { status: { in: ['open', 'past_due'] } } }),
    platform.planChange.count({ where: { status: { in: ['pending_payment', 'scheduled'] } } }),
  ]);
  console.log(`[convert] SaaS-era records kept as history: ${subscriptions} open subscriptions, ${invoices} unpaid invoices, ${planChanges} pending plan changes`);

  // Course sales now go through the platform gateway (docs/16, D-PLAT-07).
  const gateway = await platform.paymentGatewayConfig.findFirst({ where: { isActive: true }, select: { provider: true, environment: true } });
  const academyGateway = await platform.academyPaymentConfig.findUnique({ where: { tenantId: workspace.id }, select: { enabled: true, environment: true } });
  console.log(
    gateway
      ? `[convert] platform gateway active: ${gateway.provider} (${gateway.environment})`
      : '[convert] no platform gateway is active: learners cannot buy courses until a Super Admin configures Razorpay at /superadmin/payment-gateways',
  );
  if (academyGateway?.enabled)
    console.log(
      `[convert] the workspace sold courses through its own academy gateway (${academyGateway.environment}); enter those Razorpay keys as the platform gateway — credentials are never copied automatically.`,
    );
  console.log(apply ? '[convert] done.' : '[convert] dry run complete. Re-run with --apply to archive the academies listed above.');
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => platform.$disconnect());
