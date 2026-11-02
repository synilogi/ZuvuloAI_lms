/* Gives every existing academy admin the full permission catalogue.
 *
 *   npm run permissions:backfill -w @syniastrolms/api
 *
 * Run it once per environment after the `admin_permissions` migration, and again whenever the
 * catalogue gains a key that existing admins should already hold. It is idempotent: a second run
 * finds nothing missing and writes nothing. Only `role: 'admin'` accounts are touched — no learner,
 * instructor or super admin receives a grant. It changes no authorization on its own; nothing reads
 * these grants until enforcement arrives. */
import 'dotenv/config';

import { db } from '../src/lib/db.js';
import { backfillAdminPermissions } from '../src/lib/permissions.js';

async function main() {
  const { admins, granted, unchanged } = await backfillAdminPermissions();
  console.log(`[permissions] ${admins} admin account(s): ${granted} grant(s) added, ${unchanged} already complete.`);
}

main()
  .catch((e) => {
    console.error(`[permissions] ${e instanceof Error ? e.message : String(e)}`);
    process.exitCode = 1;
  })
  .finally(() => db.$disconnect());
