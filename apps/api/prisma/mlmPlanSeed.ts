/* The affiliate program's starting plan (MLM-000): version 1 of *AI Course 2-Leg MLM Plan — Corrected 50:50 Balance
 * Edition* (docs/specs), bound to the default LMS, written as a DRAFT. Safe in every environment: it writes nothing
 * when any version already exists, never activates anything, and never touches an academy. Activation — after the
 * Super Admin names the eligible course — is a human step on /superadmin/affiliates/plan.
 * Run with `npm run seed:mlm-plan`. */
import { defaultMlmPlanTerms } from '@syniastrolms/domain';
import { asPlatform } from '../src/lib/db.js';
import { createMlmPlanVersion } from '../src/lib/mlm/plan.js';
import { runAsPlatform } from '../src/lib/tenancy.js';

/** Exported so a script can disconnect it when done. */
export const platform = asPlatform('the affiliate plan seed reads the platform');

export async function seedMlmPlan(log: (...args: unknown[]) => void = () => undefined): Promise<'created' | 'kept'> {
  return runAsPlatform('the affiliate plan seed writes version 1', async () => {
    const existing = await platform.mlmPlanVersion.count();
    if (existing > 0) {
      log(`affiliate plan: ${existing} version(s) already exist, nothing written`);
      return 'kept';
    }
    const slug = process.env.DEFAULT_TENANT_SLUG || 'default';
    const tenant = await platform.tenant.findUnique({ where: { slug }, select: { id: true, name: true } });
    if (!tenant) throw new Error(`The default LMS (${slug}) does not exist yet; run the platform seed or create it first.`);
    const terms = defaultMlmPlanTerms(tenant.id);
    const version = await createMlmPlanVersion({ auth: undefined }, terms);
    log(
      `affiliate plan: version ${version.version} written as a draft for ${tenant.name} (${version.tiers.length} ranks, ${version.capBands.length} cap bands)`,
    );
    return 'created';
  });
}
