/* `npm run seed:mlm-plan` — writes version 1 of the affiliate plan as a draft when no version exists (prisma/mlmPlanSeed.ts). */
import 'dotenv/config';
import { db } from '../src/lib/db.js';
import { platform, seedMlmPlan } from '../prisma/mlmPlanSeed.js';

seedMlmPlan((...args) => console.log('[seed:mlm-plan]', ...args))
  .then((result) => console.log(`[seed:mlm-plan] done (${result})`))
  .catch((err) => {
    console.error('[seed:mlm-plan]', err);
    process.exitCode = 1;
  })
  .finally(() => Promise.all([db.$disconnect(), platform.$disconnect()]));
