/* The platform's starting configuration: the one workspace and the shared Help Centre (docs/16 §3.5).
 * Safe in every environment, production included — it never deletes or edits anything an operator made:
 *   - the workspace row is added only when no tenant carries DEFAULT_TENANT_SLUG;
 *   - the Help Centre only when it has no category at all;
 *   - the course levels, learner ranks and a certificate template only when the workspace has none.
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

/** The course levels a course is placed in. No screen creates them, so without these no course can be saved. */
export async function seedLevels(): Promise<boolean> {
  const tenantId = (await platform.tenant.findUniqueOrThrow({ where: { slug: workspaceSlug() }, select: { id: true } })).id;
  if ((await platform.level.count({ where: { tenantId } })) > 0) return false;
  await platform.level.createMany({
    data: [
      { tenantId, name: 'Beginner', order: 1, summary: 'Building the basics' },
      { tenantId, name: 'Intermediate', order: 2, summary: 'Practice at working level' },
      { tenantId, name: 'Advanced', order: 3, summary: 'Depth for experienced learners' },
    ],
  });
  return true;
}

/** The learner ranks. No screen creates them either, and with none every new learner's meter reads 100%. */
export async function seedRanks(): Promise<boolean> {
  const tenantId = (await platform.tenant.findUniqueOrThrow({ where: { slug: workspaceSlug() }, select: { id: true } })).id;
  if ((await platform.rank.count({ where: { tenantId } })) > 0) return false;
  const required = (count: number) => JSON.stringify([{ id: 'courses', label: 'Courses completed', current: 0, required: count }]);
  await platform.rank.createMany({
    data: [
      { tenantId, title: 'Rank I · Beginner', order: 1, descriptor: 'Just getting started.', criteriaJson: '[]' },
      { tenantId, title: 'Rank II · Intermediate', order: 2, descriptor: 'Building real skills.', criteriaJson: required(2) },
      { tenantId, title: 'Rank III · Advanced', order: 3, descriptor: 'Applying them with confidence.', criteriaJson: required(4) },
    ],
  });
  return true;
}

/** The default certificate design, so a learner who finishes a course has something to claim before any is designed. */
export async function seedCertificateTemplate(): Promise<boolean> {
  const tenantId = (await platform.tenant.findUniqueOrThrow({ where: { slug: workspaceSlug() }, select: { id: true } })).id;
  if ((await platform.certificateTemplate.count({ where: { tenantId } })) > 0) return false;
  await platform.certificateTemplate.create({
    data: {
      tenantId,
      name: 'Classic seal',
      style: 'classic',
      accent: 'emerald',
      heading: 'Certificate of Completion',
      statement: 'has completed the course of study in',
      signatoriesJson: JSON.stringify([{ name: 'ZuviloAI', title: 'Academic Team' }]),
      showScore: true,
      showHours: true,
      isDefault: true,
    },
  });
  return true;
}

/** Everything a new platform starts with. Idempotent. */
export async function seedPlatform(log: (...args: unknown[]) => void = () => undefined) {
  log(`  workspace: ${(await seedWorkspace()) ? 'added' : 'kept'}`);
  log(`  help centre: ${(await seedHelpCentre()) ? 'added' : 'kept'}`);
  log(`  course levels: ${(await seedLevels()) ? 'added' : 'kept'}`);
  log(`  learner ranks: ${(await seedRanks()) ? 'added' : 'kept'}`);
  log(`  certificate template: ${(await seedCertificateTemplate()) ? 'added' : 'kept'}`);
}
