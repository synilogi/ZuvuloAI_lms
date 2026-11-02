/* Creates the platform's Super Admin account, or confirms the one that is already there.
 *
 * Run it by hand, once per environment, passing the credentials in the environment so they are
 * never written to a file in the repository:
 *
 *   SUPERADMIN_EMAIL=you@example.com SUPERADMIN_PASSWORD='…' npm run superadmin:create -w @syniastrolms/api
 *
 * Optional: SUPERADMIN_NAME, SUPERADMIN_DESCRIPTOR. The password is read from the environment and is
 * never printed, logged or stored anywhere but the bcrypt hash in the database. Running it a second
 * time reports the account already exists and writes nothing. */
import 'dotenv/config';

import { db } from '../src/lib/db.js';
import { provisionSuperAdmin } from '../src/lib/provisionSuperAdmin.js';

const USAGE = 'Set SUPERADMIN_EMAIL and SUPERADMIN_PASSWORD, then run: npm run superadmin:create -w @syniastrolms/api';

async function main() {
  const email = process.env.SUPERADMIN_EMAIL ?? '';
  const password = process.env.SUPERADMIN_PASSWORD ?? '';
  if (!email || !password) {
    console.error(`[superadmin] ${USAGE}`);
    process.exitCode = 1;
    return;
  }

  const result = await provisionSuperAdmin({ email, password, name: process.env.SUPERADMIN_NAME, descriptor: process.env.SUPERADMIN_DESCRIPTOR });
  if (result.status === 'created') {
    console.log(`[superadmin] created ${result.user.email}. Sign in with it the same way as any other account.`);
    return;
  }
  if (result.status === 'unchanged') {
    console.log(`[superadmin] ${result.user.email} is already a super admin. Nothing was changed.`);
    return;
  }
  console.error(`[superadmin] ${result.user.email} already belongs to a "${result.user.role}" account, which was left untouched. Use a different address.`);
  process.exitCode = 1;
}

main()
  .catch((e) => {
    console.error(`[superadmin] ${e instanceof Error ? e.message : String(e)}`);
    process.exitCode = 1;
  })
  .finally(() => db.$disconnect());
