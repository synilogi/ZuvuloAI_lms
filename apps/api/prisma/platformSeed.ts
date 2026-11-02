/* The platform's starting configuration: the one workspace and the shared Help Centre (docs/16 §3.5).
 * Safe in every environment, production included — it never deletes or edits anything an operator made:
 *   - the workspace row is added only when no tenant carries DEFAULT_TENANT_SLUG;
 *   - the Help Centre only when it has no category at all.
 * No account, course or learner is created here. That is the demo seed's job (`prisma/seed.ts`), which exists for
 * development only. Run on its own with `npm run seed:platform`; deploy.sh runs it after migrating. */
import { asPlatform } from '../src/lib/db.js';
import { FIRST_TENANT_ID } from '../src/lib/tenancy.js';

/** Exported so a script can disconnect it when done. */
export const platform = asPlatform('the platform seed reads the catalogue');

/** The slug the API resolves the workspace by (`lib/requestContext.ts`). */
export const workspaceSlug = () => process.env.DEFAULT_TENANT_SLUG ?? 'default';

/** The platform's one workspace: added only when missing, never renamed or otherwise touched. */
export async function seedWorkspace(): Promise<boolean> {
  const slug = workspaceSlug();
  if (await platform.tenant.findUnique({ where: { slug }, select: { id: true } })) return false;
  await platform.tenant.create({ data: { id: slug === 'default' ? FIRST_TENANT_ID : undefined, name: 'ZuviloAI', slug } });
  return true;
}

/** The shared Help Centre's starting articles — added only when it has no category at all. */
export async function seedHelpCentre(): Promise<boolean> {
  if ((await platform.helpCategory.count()) > 0) return false;
  const getStarted = await platform.helpCategory.create({
    data: { name: 'Getting started', description: 'Your first steps on ZuviloAI.', icon: 'rocket', order: 1 },
  });
  const courses = await platform.helpCategory.create({
    data: { name: 'Courses & lessons', description: 'Finding and studying a course.', icon: 'book', order: 2 },
  });
  await platform.helpArticle.create({
    data: {
      slug: 'welcome-to-syniastrolms',
      categoryId: getStarted.id,
      title: 'Welcome to ZuviloAI',
      summary: 'A quick orientation to the platform.',
      body: '## Welcome\n\nZuviloAI is an online learning platform. Every course follows the same shape: chapters, lessons, an assignment and an assessment.\n\n- Browse courses from **Explore**\n- Track progress from **My learning**\n- Earn a certificate once you finish',
      audience: 'all',
      tagsJson: JSON.stringify(['orientation']),
      readMinutes: 2,
      popular: true,
    },
  });
  await platform.helpArticle.create({
    data: {
      slug: 'how-enrolment-works',
      categoryId: courses.id,
      title: 'How enrolment works',
      summary: 'Enrolling in a course and what happens next.',
      body: '## Enrolling\n\nOpen any published course and select **Enroll** — or **Buy now** for a paid course. Your progress, notes and bookmarks are tracked automatically from your first lesson.',
      audience: 'student',
      tagsJson: JSON.stringify(['enrolment']),
      readMinutes: 2,
    },
  });
  return true;
}

/** Everything a new platform starts with. Idempotent. */
export async function seedPlatform(log: (...args: unknown[]) => void = () => undefined) {
  log(`  workspace: ${(await seedWorkspace()) ? 'added' : 'kept'}`);
  log(`  help centre: ${(await seedHelpCentre()) ? 'added' : 'kept'}`);
}
