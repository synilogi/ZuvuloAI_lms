/* DEVELOPMENT ONLY. Seeds a small but coherent demo academy: levels, categories, courses with real
 * curriculum, instructors, a rank ladder, certificate templates, settings, and three ready-to-use login
 * accounts (admin / instructor / student), each demonstrating enrollments, progress, a quiz attempt, an
 * assignment submission and an issued certificate.
 *
 * It DELETES every workspace row it reseeds before inserting the demo, so it refuses to run with
 * NODE_ENV=production. A real deployment starts from `npm run seed:platform` (the workspace, the Help Centre). The test suite and the E2E runner run it against
 * their own database files, never dev.db or production. */
// First, so the guard below sees what the API would: Prisma reads apps/api/.env by itself, and so must this check.
import 'dotenv/config';
import { asPlatform } from '../src/lib/db.js';
import { grantAllPermissions } from '../src/lib/permissions.js';
import { FIRST_TENANT_ID } from '../src/lib/tenancy.js';
import { seedDemoAcademyContent } from './academyDemo.js';
import { demoSeedRefusal } from './seedGuard.js';
import { seedHelpCentre, platform as platformSeedClient } from './platformSeed.js';

const refusal = demoSeedRefusal(process.env);
if (refusal) {
  console.error(`[seed] Refusing to run the demo seed: ${refusal}. It deletes every academy's data. Use \`npm run seed:platform\`.`);
  process.exit(1);
}

/*
 * Everything the seed creates belongs to Tenant #1, the academy that existed before tenancy
 * (`prisma/academyDemo.ts` writes through a client bound to it); clearing the old data is the one
 * platform-wide step.
 */
const platform = asPlatform('the seed resets the demo data');
const DEMO_PASSWORD = 'syniastrolms123';
const quiet = process.env.SEED_QUIET === '1';
const log = (...args: unknown[]) => { if (!quiet) console.log(...args); };

async function main() {
  // Orders and ledgers cannot be cleared: they refuse deletes by design, and this script is for an empty database.
  const sold = await platform.coursePurchase.count();
  if (sold > 0) {
    throw new Error(`This database has ${sold} course order(s), which the demo seed cannot and must not clear. Point DATABASE_URL at a new file to seed one.`);
  }
  log('Clearing existing data...');
  const tables = [
    'AppNotification', 'NotificationSettings', 'CalendarEvent', 'AssignmentDraft', 'LiveRegistration', 'LiveClass',
    'IssuedCertificate', 'CertificateTemplate', 'Submission', 'CourseAssignment', 'QuizAttempt', 'Quiz',
    'SavedCourse', 'LessonBookmark', 'LessonNote', 'LessonProgress', 'Enrollment', 'Lesson', 'Chapter',
    'CourseInstructor', 'Course', 'CategoryLevel', 'Category', 'Level', 'HelpArticle', 'HelpCategory',
    'Settings', 'Student', 'Instructor', 'User', 'Rank',
  ];
  for (const t of tables) {
    await (platform as never as Record<string, { deleteMany: () => Promise<unknown> }>)[t[0].toLowerCase() + t.slice(1)].deleteMany();
  }
  // Tenant #1 is created by the tenant_foundation migration; ensure it here too, so the seed also runs
  // against a database whose migrations were applied before the academy row existed.
  await platform.tenant.upsert({ where: { id: FIRST_TENANT_ID }, create: { id: FIRST_TENANT_ID, name: 'ZuviloAI', slug: 'default' }, update: {} });

  const logins = await seedDemoAcademyContent({
    tenantId: FIRST_TENANT_ID,
    academyName: 'ZuviloAI',
    emailDomain: 'syniastrolms.test',
    password: DEMO_PASSWORD,
    credentialPrefix: 'SA-JY-2026',
    settingsCredentialPrefix: 'SA',
    log,
  });

  // The demo admin holds the whole permission catalogue, as an admin created with a new academy does
  // (lib/academies.ts). Without it, signing in as the admin met "You don't have access" on the dashboard.
  const admin = await platform.user.findUniqueOrThrow({ where: { email: logins.admin } });
  await grantAllPermissions(admin.id, { client: platform });

  log('Help centre...');
  await seedHelpCentre();

  log(`\nSeed complete. Demo accounts (password "${DEMO_PASSWORD}" for all):`);
  log(`  Admin:      ${logins.admin}`);
  log(`  Instructor: ${logins.instructors[0]}`);
  log(`  Student:    ${logins.students[0]}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => Promise.all([platform.$disconnect(), platformSeedClient.$disconnect()]));
