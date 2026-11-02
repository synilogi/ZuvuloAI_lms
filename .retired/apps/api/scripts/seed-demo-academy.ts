/* Creates a NEW demo academy for testing and fills it with sample content — safe on production.
 *
 *   DEMO_ACADEMY_SLUG=demo-academy npm run seed:demo-academy -w @syniastrolms/api
 *
 * It only adds: a new academy (refused if the slug is taken), its admin, instructors and students, six
 * courses with curriculum, a year of enrolments, quizzes, assignments, certificates and live classes, and
 * a free trial on the plan `DEMO_ACADEMY_PLAN` (default PRO, so every plan-gated module is open). It never
 * reads, changes or deletes another academy's data.
 *
 * Logins are `<name>@<DEMO_EMAIL_DOMAIN>` (default `demo.syniastrolms.test` — a reserved domain, so no email
 * is ever delivered to a real person). The password is DEMO_ACADEMY_PASSWORD, or a strong one generated and
 * printed once — never the repo's public development password. Optional: DEMO_ACADEMY_NAME, DEMO_CREDENTIAL_PREFIX. */
import 'dotenv/config';
import { randomBytes } from 'node:crypto';

import { seedDemoAcademyContent } from '../prisma/academyDemo.js';
import { asPlatform, db } from '../src/lib/db.js';
import { grantAllPermissions } from '../src/lib/permissions.js';
import { createSubscription } from '../src/lib/subscriptions.js';
import { runAsPlatform } from '../src/lib/tenancy.js';

const slug = (process.env.DEMO_ACADEMY_SLUG ?? 'demo-academy').trim().toLowerCase();
const name = process.env.DEMO_ACADEMY_NAME?.trim() || 'Demo Academy';
const emailDomain = process.env.DEMO_EMAIL_DOMAIN?.trim() || 'demo.syniastrolms.test';
const planCode = process.env.DEMO_ACADEMY_PLAN?.trim() || 'PRO';
const credentialPrefix = process.env.DEMO_CREDENTIAL_PREFIX?.trim() || `DEMO-${slug.toUpperCase().replace(/[^A-Z0-9]/g, '')}`.slice(0, 20);
const password = process.env.DEMO_ACADEMY_PASSWORD || `Demo-${randomBytes(9).toString('base64url')}`;
const generated = !process.env.DEMO_ACADEMY_PASSWORD;

const platform = asPlatform('the demo academy seed creates a new academy');
const log = (...args: unknown[]) => console.log('[demo-academy]', ...args);

async function main() {
  if (!/^[a-z0-9](?:[a-z0-9-]{0,58}[a-z0-9])?$/.test(slug)) throw new Error(`"${slug}" is not a valid academy address.`);
  if (password.length < 8) throw new Error('DEMO_ACADEMY_PASSWORD must be at least 8 characters.');

  // Refuse anything that could touch existing data: the academy must be new, and no login may exist yet.
  if (await platform.tenant.findUnique({ where: { slug } })) throw new Error(`An academy with the address "${slug}" already exists. Nothing was changed.`);
  const taken = await platform.user.count({ where: { email: { endsWith: `@${emailDomain}` } } });
  if (taken) throw new Error(`${taken} account(s) already use @${emailDomain}. Choose another DEMO_EMAIL_DOMAIN. Nothing was changed.`);
  const credentials = await platform.issuedCertificate.count({ where: { credentialId: { startsWith: `${credentialPrefix}-` } } });
  if (credentials) throw new Error(`Certificates already use the prefix ${credentialPrefix}. Choose another DEMO_CREDENTIAL_PREFIX. Nothing was changed.`);
  const plan = await platform.plan.findUnique({ where: { code: planCode } });
  if (!plan || plan.status !== 'active') throw new Error(`Plan ${planCode} is not on sale. Run npm run seed:platform, or set DEMO_ACADEMY_PLAN.`);

  log(`Creating "${name}" (${slug})…`);
  const tenant = await platform.tenant.create({ data: { name, slug } });
  try {
    const logins = await seedDemoAcademyContent({
      tenantId: tenant.id,
      academyName: name,
      emailDomain,
      password,
      credentialPrefix,
      settingsCredentialPrefix: 'DEMO',
      log,
    });

    const admin = await platform.user.findUniqueOrThrow({ where: { email: logins.admin } });
    await grantAllPermissions(admin.id, { client: platform });

    // A billing address, so the academy can be invoiced and plan changes priced; and a free trial on the plan.
    await platform.billingProfile.create({
      data: {
        tenantId: tenant.id,
        legalName: `${name} (demo)`,
        email: logins.admin,
        addressLine1: '12 MG Road',
        city: 'Bengaluru',
        region: 'KA',
        postalCode: '560001',
        country: 'IN',
      },
    });
    await runAsPlatform('the demo academy seed starts its trial', () =>
      createSubscription({ type: 'system', job: 'seed-demo-academy' }, { tenantId: tenant.id, planId: plan.id, cycle: 'monthly', start: 'trial' }),
    );

    const counts = await Promise.all([
      platform.course.count({ where: { tenantId: tenant.id } }),
      platform.student.count({ where: { tenantId: tenant.id } }),
      platform.enrollment.count({ where: { tenantId: tenant.id } }),
      platform.liveClass.count({ where: { tenantId: tenant.id } }),
    ]);
    log(`Done: ${counts[0]} courses, ${counts[1]} students, ${counts[2]} enrolments, ${counts[3]} live classes; ${plan.name} free trial.`);
    log('');
    log(`Academy:    ${name}  (id ${tenant.id})`);
    log(`Admin:      ${logins.admin}`);
    log(`Instructor: ${logins.instructors.join(', ')}`);
    log(`Students:   ${logins.students.slice(0, 3).join(', ')} (+${logins.students.length - 3} more, and 36 alumni)`);
    log(`Password:   ${password}${generated ? '   ← generated now and shown only once: save it' : ''}`);
  } catch (err) {
    log(
      `Failed part-way. The new academy ${tenant.id} (${slug}) holds whatever was created; archive it from Super Admin › Academies. Nothing outside it was changed.`,
    );
    throw err;
  }
}

main()
  .catch((err) => {
    console.error('[demo-academy]', err instanceof Error ? err.message : err);
    process.exitCode = 1;
  })
  .finally(() => Promise.all([platform.$disconnect(), db.$disconnect()]));
