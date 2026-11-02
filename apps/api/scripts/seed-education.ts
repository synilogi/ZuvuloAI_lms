/* Adds the sample education catalogue (`prisma/educationCatalog.ts`) to one existing academy.
 *
 *   npm run seed:education -w @syniastrolms/api -- --dry-run                     # checks only
 *   npm run seed:education -w @syniastrolms/api                                  # catalogue into the `default` academy
 *   npm run seed:education -w @syniastrolms/api -- --academy <slug>              # another academy
 *   npm run seed:education -w @syniastrolms/api -- --demo-student <x>@<y>.test   # + learner activity (dev/staging)
 *
 * It never creates, changes or deletes an account, and deletes nothing. With NODE_ENV=production it needs
 * `--production` on the command line and refuses `--demo-student`: production gets the catalogue only. */
import 'dotenv/config';

import { EDUCATION_COURSE_KEYS, educationConflicts, seedEducationCatalog } from '../prisma/educationCatalog.js';

const log = (...args: unknown[]) => console.log('[education]', ...args);
const arg = (name: string) => {
  const i = process.argv.indexOf(name);
  return i === -1 ? undefined : process.argv[i + 1];
};

async function main() {
  const env = process.env.NODE_ENV;
  const production = process.argv.includes('--production');
  const academySlug = arg('--academy') ?? process.env.DEFAULT_TENANT_SLUG ?? 'default';
  const demoStudentEmail = arg('--demo-student');
  if (env === 'production' && !production) throw new Error('NODE_ENV is production. Add --production to confirm this is intended. Nothing was changed.');
  if (env !== 'production' && env !== 'development' && env !== 'staging') throw new Error(`NODE_ENV is ${env ? `"${env}"` : 'not set'}. Nothing was changed.`);
  if (env === 'production' && demoStudentEmail) throw new Error('--demo-student is for development and staging only. Nothing was changed.');
  log(`Database: ${process.env.DATABASE_URL} (NODE_ENV=${env}); academy: ${academySlug}`);

  const { problems, tenant } = await educationConflicts(academySlug);
  if (problems.length) throw new Error(`Nothing was changed:\n  ${problems.join('\n  ')}`);
  if (process.argv.includes('--dry-run')) {
    log(
      `Dry run: would add or refresh ${EDUCATION_COURSE_KEYS.length} courses in "${tenant!.name}"${demoStudentEmail ? ` and learner activity for ${demoStudentEmail}` : ''}. Nothing was written.`,
    );
    return;
  }

  const result = await seedEducationCatalog({ academySlug, demoStudentEmail, log });
  const c = result.counts;
  log(
    `Done in "${result.academyName}": ${c.categories} categories, ${c.courses} courses, ${c.lessons} lessons, ${c.media} stored files, ${c.quizzes} tests, ${c.assignments} assignments.`,
  );
  if (result.demoStudent) log(`Demo learner ${result.demoStudent}: ${c.enrolments} enrolments, ${c.liveClasses} live classes.`);
}

main().catch((err) => {
  console.error('[education]', err instanceof Error ? err.message : err);
  process.exitCode = 1;
});
