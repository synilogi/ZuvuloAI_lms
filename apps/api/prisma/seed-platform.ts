/* `npm run seed:platform` — the platform's starting configuration (plans, default tax rule, Help Centre).
 * Safe on production: it only adds what is missing and never deletes. See prisma/platformSeed.ts. */
import 'dotenv/config';

import { db } from '../src/lib/db.js';
import { platform, seedPlatform } from './platformSeed.js';

seedPlatform((...args) => console.log('[seed:platform]', ...args))
  .then(() => console.log('[seed:platform] done'))
  .catch((err) => {
    console.error('[seed:platform]', err);
    process.exitCode = 1;
  })
  .finally(() => Promise.all([db.$disconnect(), platform.$disconnect()]));
