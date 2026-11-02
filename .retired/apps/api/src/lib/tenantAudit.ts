import { Prisma } from '@prisma/client';

import { asPlatform } from './db.js';
import { TENANT_OR_PLATFORM_MODELS, TENANT_OWNED_MODELS, isScopedModel } from './tenancy.js';

/*
 * Checks that the data in the database obeys the tenancy rules — the precondition for enforcement.
 * Run by `npm run tenants:verify` (and by deploy.sh after migrating), and by the test suite against
 * everything the suite itself wrote.
 *
 * The checks read the rows directly, so they describe the data as it is rather than as the extension
 * would present it:
 *   - every tenantId names an academy that exists, and a required one is never NULL
 *   - an account belongs to an academy exactly when it is not a super admin (D1)
 *   - a row hanging off an account sits in that account's academy
 *   - every foreign key between academy-owned rows joins two rows of the same academy — the invariant
 *     that makes a scoped parent's children safe to include without filtering them again
 */

export interface TenancyViolation {
  check: string;
  count: number;
}

export interface TenancyAudit {
  tables: number;
  rows: number;
  relations: number;
  violations: TenancyViolation[];
}

/** One foreign key between two academy-owned tables, from the schema. */
function scopedRelations(): { child: string; column: string; parent: string }[] {
  const out: { child: string; column: string; parent: string }[] = [];
  for (const model of Prisma.dmmf.datamodel.models) {
    if (!isScopedModel(model.name)) continue;
    for (const field of model.fields) {
      if (field.kind !== 'object' || !isScopedModel(field.type)) continue;
      const [column] = field.relationFromFields ?? [];
      if (column && column !== 'tenantId') out.push({ child: model.name, column, parent: field.type });
    }
  }
  return out;
}

const q = (name: string) => `"${name}"`;

/** The database has not had the tenant_foundation migration yet, so there is nothing to audit. */
export class TenancyNotMigratedError extends Error {
  constructor() {
    super('This database has no Tenant table: the tenant_foundation migration has not been applied. Run `npx prisma migrate deploy` first.');
    this.name = 'TenancyNotMigratedError';
  }
}

export async function auditTenancy(): Promise<TenancyAudit> {
  const platform = asPlatform('auditing the tenancy of every row');
  const count = async (sql: string) => Number((await platform.$queryRawUnsafe<{ n: bigint | number }[]>(sql))[0].n);
  if (!(await count(`SELECT count(*) AS n FROM sqlite_master WHERE type = 'table' AND name = 'Tenant'`))) {
    throw new TenancyNotMigratedError();
  }
  const violations: TenancyViolation[] = [];
  const flag = (check: string, n: number) => n && violations.push({ check, count: n });

  let rows = 0;
  for (const model of [...TENANT_OWNED_MODELS, ...TENANT_OR_PLATFORM_MODELS]) {
    rows += await count(`SELECT count(*) AS n FROM ${q(model)}`);
    flag(
      `${model}: tenantId names no academy`,
      await count(`SELECT count(*) AS n FROM ${q(model)} WHERE tenantId IS NOT NULL AND tenantId NOT IN (SELECT id FROM "Tenant")`),
    );
  }
  for (const model of TENANT_OWNED_MODELS) {
    flag(`${model}: required tenantId is NULL`, await count(`SELECT count(*) AS n FROM ${q(model)} WHERE tenantId IS NULL`));
  }

  flag(
    'User: a super admin with an academy, or an academy account without one',
    await count(`SELECT count(*) AS n FROM "User" WHERE (role = 'superadmin') = (tenantId IS NOT NULL)`),
  );
  for (const [model, column] of [
    ['PasswordResetToken', 'userId'],
    ['NotificationSettings', 'userId'],
    ['AppNotification', 'recipientId'],
  ] as const) {
    flag(
      `${model}: not in its account's academy`,
      await count(`SELECT count(*) AS n FROM ${q(model)} t JOIN "User" u ON u.id = t.${q(column)} WHERE t.tenantId IS NOT u.tenantId`),
    );
  }

  const relations = scopedRelations();
  for (const { child, column, parent } of relations) {
    flag(
      `${child}.${column} → ${parent}: joins two academies`,
      await count(`SELECT count(*) AS n FROM ${q(child)} c JOIN ${q(parent)} p ON p.id = c.${q(column)} WHERE c.tenantId IS NOT p.tenantId`),
    );
  }

  return { tables: TENANT_OWNED_MODELS.length + TENANT_OR_PLATFORM_MODELS.length, rows, relations: relations.length, violations };
}
