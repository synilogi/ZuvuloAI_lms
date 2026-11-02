/* Verifies that every row in the database obeys the tenancy rules — run after migrating, before an
 * API process built on tenancy starts serving. Exits 1 and names each broken rule when it finds one,
 * so a deploy can refuse to continue. Reads only; it changes nothing.
 *
 *   npm run tenants:verify -w @syniastrolms/api
 */
import 'dotenv/config';

import { auditTenancy, TenancyNotMigratedError } from '../src/lib/tenantAudit.js';

const audit = await auditTenancy().catch((err: unknown) => {
  if (err instanceof TenancyNotMigratedError) {
    console.error(`[tenancy] ✗ ${err.message}`);
    process.exit(1);
  }
  throw err;
});
console.log(`[tenancy] ${audit.tables} academy-owned tables, ${audit.rows} rows, ${audit.relations} relations between them checked.`);
if (audit.violations.length) {
  for (const v of audit.violations) console.error(`[tenancy] ✗ ${v.check} — ${v.count} row(s)`);
  console.error('[tenancy] The data does not obey the tenancy rules. Do not start the API on it; see docs/10-DEPLOYMENT.md.');
  process.exit(1);
}
console.log('[tenancy] Every row belongs to an academy that exists, and no relation crosses academies.');
process.exit(0);
