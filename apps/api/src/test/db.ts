/* The clients test code reads and writes through. Fixture setup and assertions state their context the
 * same way production code does: the seeded academy for academy data, the platform for platform-level
 * rows (super admins, the audit trail, other academies). */
import { asPlatform, forTenant } from '../lib/db.js';
import { FIRST_TENANT_ID, runInTenant } from '../lib/tenancy.js';

/** The seeded academy — Tenant #1. */
export const ACADEMY = FIRST_TENANT_ID;

/** Every query runs for the seeded academy. */
export const db = forTenant(ACADEMY);

/** Every query runs across the platform — for super admin rows, the audit trail and other academies. */
export const platformDb = asPlatform('test fixtures inspect the platform');

/** The academy stamp for a fixture row created in the seeded academy. */
export const T = { tenantId: ACADEMY } as const;

/** Runs a job or library function as it runs in production: inside the seeded academy. */
export const inAcademy = <R>(fn: () => R | PromiseLike<R>) => runInTenant(ACADEMY, fn);
