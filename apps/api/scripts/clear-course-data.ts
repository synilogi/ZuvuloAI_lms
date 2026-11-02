/* Clears every academy's course and learning data and keeps every account. One-off reset, approval-gated.
 *
 *   npm run data:clear-courses -w @syniastrolms/api                    # dry run: counts what would go
 *   CLEAR_COURSE_DATA=yes npm run data:clear-courses -w @syniastrolms/api -- --apply
 *
 * Production also needs `--production` on the command line: an operator decision, never a default.
 * `--academy <slug>` (repeatable) limits the reset to those academies; without it every academy is reset.
 *
 * Deleted, in every academy in scope: categories, levels, courses and their curriculum, quizzes and attempts, assignments,
 * drafts and submissions, enrolments, lesson progress, notes, bookmarks and saved courses, issued certificates, live
 * classes and registrations, calendar events tied to a course or instructor, learning notifications (course,
 * assignment, quiz, live, certificate, enrolment), stored course files (MediaAsset rows; the files stay on disk), and
 * instructor profiles that have no login.
 *
 * Kept: academies, users and passwords, learner profiles, instructors who have a login, admin permissions, ranks,
 * certificate templates, settings, subscriptions, invoices, payments and every other billing row, invitations,
 * inquiries, system notifications, the email outbox (held mail stays held) and the audit trail.
 *
 * Before deleting it writes a consistent copy of the database (`VACUUM INTO`) next to it, under backups/, and never
 * prunes older backups. Every delete runs in one transaction: all of it happens, or none of it does. */
import 'dotenv/config';
import { execSync } from 'node:child_process';
import path from 'node:path';

import { asPlatform } from '../src/lib/db.js';

const apply = process.argv.includes('--apply');
const production = process.argv.includes('--production');
const log = (...args: unknown[]) => console.log('[clear-courses]', ...args);

const academySlugs = process.argv.flatMap((a, i, all) => (a === '--academy' && all[i + 1] ? [all[i + 1]] : []));

const LEARNING_NOTIFICATIONS = ['course', 'assignment', 'quiz', 'live', 'certificate', 'enrollment'];

async function main() {
  const env = process.env.NODE_ENV;
  if (env === 'production' && !production) throw new Error('NODE_ENV is production. Add --production to confirm this is intended. Nothing was changed.');
  if (env !== 'production' && env !== 'development' && env !== 'staging') throw new Error(`NODE_ENV is ${env ? `"${env}"` : 'not set'}. Nothing was changed.`);
  const url = process.env.DATABASE_URL ?? '';
  if (!url.startsWith('mysql://')) throw new Error('DATABASE_URL is not a mysql:// address. Nothing was changed.');
  log(`Database: ${new URL(url).pathname.slice(1)} (NODE_ENV=${env})`);

  const db = asPlatform('an approved one-off reset clears course and learning data and keeps accounts');
  try {
    let scope: { tenantId?: { in: string[] } } = {};
    if (academySlugs.length) {
      const tenants = await db.tenant.findMany({ where: { slug: { in: academySlugs } }, select: { id: true, slug: true, name: true } });
      const missing = academySlugs.filter((s) => !tenants.some((t) => t.slug === s));
      if (missing.length) throw new Error(`No academy has the address ${missing.join(', ')}. Nothing was changed.`);
      scope = { tenantId: { in: tenants.map((t) => t.id) } };
      log(`Academies: ${tenants.map((t) => `${t.name} (${t.slug})`).join(', ')}`);
    } else log('Academies: all');
    // Instructor profiles nobody signs in as are content, not accounts.
    const withLogin = new Set((await db.user.findMany({ where: { instructorId: { not: null } }, select: { instructorId: true } })).map((u) => u.instructorId!));
    const profilesOnly = (await db.instructor.findMany({ where: scope, select: { id: true } })).map((i) => i.id).filter((id) => !withLogin.has(id));
    // A photo on a kept instructor stays; every other stored file belonged to a course, a lesson or a hand-in.
    const photoRefs = (await db.instructor.findMany({ where: { id: { in: [...withLogin] } }, select: { photoJson: true } }))
      .map((i) => i.photoJson ?? '')
      .join(' ');
    const media = await db.mediaAsset.findMany({ where: scope, select: { id: true } });
    const mediaToDelete = media.map((m) => m.id).filter((id) => !photoRefs.includes(id));

    const unscoped = {
      appNotification: { tenantId: { not: null }, category: { in: LEARNING_NOTIFICATIONS } },
      calendarEvent: { OR: [{ courseId: { not: null } }, { instructorId: { in: profilesOnly } }, { quizId: { not: null } }] },
      liveRegistration: {},
      liveClass: {},
      issuedCertificate: {},
      submission: {},
      assignmentDraft: {},
      courseAssignment: {},
      quizAttempt: {},
      quiz: {},
      lessonNote: {},
      lessonBookmark: {},
      lessonProgress: {},
      savedCourse: {},
      enrollment: {},
      lesson: {},
      chapter: {},
      courseInstructor: {},
      course: {},
      categoryLevel: {},
      category: {},
      level: {},
      instructor: { id: { in: profilesOnly } },
      mediaAsset: { id: { in: mediaToDelete } },
    } as const;
    type Model = keyof typeof unscoped;
    const plan = Object.fromEntries(Object.entries(unscoped).map(([m, where]) => [m, { ...where, ...scope }])) as Record<Model, object>;
    type Delegate = { count(args: { where: object }): Promise<number>; deleteMany(args: { where: object }): Promise<{ count: number }> };
    const delegate = (m: Model) => (db as unknown as Record<Model, Delegate>)[m];

    const counts: Record<string, number> = {};
    for (const m of Object.keys(plan) as Model[]) counts[m] = await delegate(m).count({ where: plan[m] });
    log(
      'Would delete:',
      Object.entries(counts)
        .map(([m, n]) => `${m} ${n}`)
        .join(', '),
    );
    const kept = {
      tenants: await db.tenant.count(),
      users: await db.user.count(),
      students: await db.student.count(),
      instructorsWithLogin: withLogin.size,
      subscriptions: await db.subscription.count(),
      emailOutbox: await db.emailOutbox.count(),
    };
    log(
      'Keeps:',
      Object.entries(kept)
        .map(([k, n]) => `${k} ${n}`)
        .join(', '),
    );
    if (!apply) return log('Dry run: nothing was changed. Add --apply (and CLEAR_COURSE_DATA=yes) to delete.');
    if (process.env.CLEAR_COURSE_DATA !== 'yes') throw new Error('Set CLEAR_COURSE_DATA=yes to delete. Nothing was changed.');

    // The same copy deploy.sh takes before a migration. A failed backup stops here, before anything has changed.
    execSync('npx tsx scripts/backup-db.ts', { cwd: path.join(import.meta.dirname, '..'), stdio: 'inherit' });

    const results = await db.$transaction((Object.keys(plan) as Model[]).map((m) => delegate(m).deleteMany({ where: plan[m] }) as never));
    log('Deleted:', (Object.keys(plan) as Model[]).map((m, i) => `${m} ${(results[i] as { count: number }).count}`).join(', '));
    const after = {
      tenants: await db.tenant.count(),
      users: await db.user.count(),
      students: await db.student.count(),
      emailOutbox: await db.emailOutbox.count(),
    };
    for (const [k, n] of Object.entries(after))
      if (n !== kept[k as keyof typeof kept]) throw new Error(`${k} changed from ${kept[k as keyof typeof kept]} to ${n}. Restore the backup db:backup just took.`);
    log('Accounts, academies and the email outbox are unchanged.');
  } finally {
    await db.$disconnect();
  }
}

main().catch((err) => {
  console.error('[clear-courses]', err instanceof Error ? err.message : err);
  process.exitCode = 1;
});
