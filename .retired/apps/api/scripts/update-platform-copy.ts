/* One-off (2026-10): replaces the astrology wording left in platform content that `seed:platform` created before the
 * product moved to general education. The seed only creates missing rows, so existing Help Centre articles and plans
 * keep their old text until this runs. It changes a row only while it still holds the exact old wording, so an edit
 * made since by a Super Admin is never overwritten; running it again changes nothing.
 *
 *   npm run platform:update-copy -w @syniastrolms/api              # dry run
 *   npm run platform:update-copy -w @syniastrolms/api -- --apply   # (+ --production on the server) */
import 'dotenv/config';

import { asPlatform } from '../src/lib/db.js';
import { updatePlan } from '../src/lib/plans.js';
import { runAsPlatform } from '../src/lib/tenancy.js';

const OLD_HELP = /is a structured school for Vedic astrology\./;
const NEW_HELP = 'is a structured learning platform for schools and coaching institutes.';
const OLD_PLAN = 'A single teacher with one course — being written for astrology tutors teaching part time.';
const NEW_PLAN = 'A single teacher with one course — for tutors teaching part time.';
const log = (...args: unknown[]) => console.log('[platform-copy]', ...args);

async function main() {
  const apply = process.argv.includes('--apply');
  if (process.env.NODE_ENV === 'production' && !process.argv.includes('--production'))
    throw new Error('NODE_ENV is production. Add --production to confirm. Nothing was changed.');
  const db = asPlatform('a one-off copy update replaces old astrology wording in platform content');
  try {
    const articles = (await db.helpArticle.findMany({ select: { id: true, title: true, body: true } })).filter((a) => OLD_HELP.test(a.body));
    const plans = await db.plan.findMany({ where: { description: OLD_PLAN }, select: { id: true, code: true } });
    log(`Help articles with the old wording: ${articles.map((a) => a.title).join(', ') || 'none'}. Plans: ${plans.map((p) => p.code).join(', ') || 'none'}.`);
    if (!apply) return log('Dry run: nothing was changed. Add --apply.');
    for (const a of articles) await db.helpArticle.update({ where: { id: a.id }, data: { body: a.body.replace(OLD_HELP, NEW_HELP) } });
    // Plans change only through the plan service; an operator task carries no signed-in caller.
    await runAsPlatform('a one-off copy update edits a plan description', async () => {
      for (const p of plans) await updatePlan({}, p.id, { description: NEW_PLAN });
    });
    log(`Updated ${articles.length} article(s) and ${plans.length} plan(s).`);
  } finally {
    await db.$disconnect();
  }
}

main().catch((err) => {
  console.error('[platform-copy]', err instanceof Error ? err.message : err);
  process.exitCode = 1;
});
