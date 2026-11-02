import { PrismaClient } from '@prisma/client';

import { bindContext, tenancyExtension } from './tenancy.js';

/**
 * The unscoped client. Only `lib/tenancy.ts` reads through it (its reference checks name the academy
 * explicitly); nothing else should, which is why it is not exported.
 */
const base = new PrismaClient();

/**
 * The client every route, job and script uses. Every query on an academy-owned model is confined to
 * the academy of the current context — see `lib/tenancy.ts`.
 */
export const db = base.$extends(tenancyExtension(base));

export type Db = typeof db;

/**
 * What a helper that may run inside a transaction accepts: `db` itself, or the client an interactive
 * `db.$transaction(async (tx) => …)` hands out. Both carry the tenancy extension.
 */
export type DbClient = Omit<Db, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>;

/** A client whose every query runs for one academy, whatever context it is called from. For tests and scripts. */
export const forTenant = (tenantId: string): Db => base.$extends(bindContext({ kind: 'tenant', tenantId })).$extends(tenancyExtension(base)) as unknown as Db;

/** A client whose every query runs across every academy. For operator scripts and tests; name the reason. */
export const asPlatform = (reason: string): Db => base.$extends(bindContext({ kind: 'platform', reason })).$extends(tenancyExtension(base)) as unknown as Db;
