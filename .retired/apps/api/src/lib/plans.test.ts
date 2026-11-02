import { BYTES_PER_GB, FEATURES, LIMITS, type PlanLimits } from '@syniastrolms/domain';
import { beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { unique } from '../test/helpers.js';
import type { AuditActor } from './audit.js';
import { ApiError } from './errors.js';
import {
  PLAN_AUDIT_ACTIONS,
  archivePlan,
  createPlan,
  getPlan,
  listPlanVersions,
  listPlans,
  planForNewSubscription,
  publishPlan,
  resolvePlanVersion,
  restorePlan,
  updatePlan,
  type CreatePlanInput,
} from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { FIRST_TENANT_ID, runAsPlatform, runInTenant } from './tenancy.js';

/* SAAS-001: plans in the database, their commercial terms in append-only versions, every amount an
 * integer count of paise. The plan service is the platform's, so each call runs as the platform, the
 * way the Super Admin router will call it. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('plan tests act as the Super Admin router does', fn);

let actor: AuditActor;
let actorId: string;

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `plans-${unique()}@example.com`, password: 'plans-suite-password', name: 'Plan Owner' });
  actorId = created.user.id;
  actor = { auth: { sub: actorId, role: 'superadmin' } };
});

const LIMITS_750: PlanLimits = {
  'learners.max': 750,
  'instructors.max': 8,
  'courses.max': 40,
  'storage.bytes': 150 * BYTES_PER_GB,
  'live_classes.max': 20,
  'admin_accounts.max': 3,
};

const code = () => `T${unique().toUpperCase()}`.slice(0, 24);

const input = (over: Partial<CreatePlanInput> = {}): CreatePlanInput => ({
  name: 'Growth',
  description: 'A small faculty running scheduled batches.',
  code: code(),
  currency: 'INR',
  cycles: ['monthly', 'annual'],
  monthlyPrice: 399900,
  annualPrice: 3999000,
  trialEnabled: true,
  trialDays: 14,
  limits: LIMITS_750,
  features: ['courses.manage', 'assessments.manage', 'reports.basic'],
  ...over,
});

const newPlan = (over: Partial<CreatePlanInput> = {}) => asPlatform(() => createPlan(actor, input(over)));
const onSale = async (over: Partial<CreatePlanInput> = {}) => {
  const plan = await newPlan(over);
  return asPlatform(() => publishPlan(actor, plan.id));
};

/** The version row exactly as the database holds it. */
const versionRow = (id: string) => platformDb.planVersion.findUniqueOrThrow({ where: { id } });

const refusal = async (promise: Promise<unknown>) => {
  const err = await promise.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(err, 'expected the call to be refused').toBeInstanceOf(ApiError);
  return err as ApiError & { code?: string };
};

describe('plan codes are unique at the database level', () => {
  it('refuses a second row with the same code, whoever writes it', async () => {
    const taken = code();
    const terms = { versions: { create: { version: 1, currency: 'INR', monthlyPrice: 100000 } } };
    await platformDb.plan.create({ data: { code: taken, name: 'First', description: 'The first plan with this code.', ...terms } });
    await expect(
      platformDb.plan.create({ data: { code: taken, name: 'Second', description: 'A second plan with the same code.', ...terms } }),
    ).rejects.toMatchObject({
      code: 'P2002',
    });
  });

  it('refuses a duplicate through the service in any case or padding, as a conflict', async () => {
    const first = await newPlan();
    const err = await refusal(newPlan({ code: `  ${first.code.toLowerCase()} ` }));
    expect(err.status).toBe(409);
    expect(err.message).toBe(`The code ${first.code} already belongs to another plan.`);
  });

  it('stores a code the way it compares: trimmed and in capitals', async () => {
    const raw = `t${unique()}`;
    const plan = await newPlan({ code: `  ${raw} ` });
    expect(plan.code).toBe(raw.toUpperCase());
    // The database refuses a lower-case code outright, so no writer can store one.
    await expect(platformDb.plan.create({ data: { code: 'lower', name: 'Lower', description: 'A code in lower case.' } })).rejects.toThrow();
  });

  it('fixes the code once the plan has been offered', async () => {
    const draft = await newPlan();
    const renamed = await asPlatform(() => updatePlan(actor, draft.id, { code: code() }));
    expect(renamed.code).not.toBe(draft.code);

    const live = await asPlatform(() => publishPlan(actor, renamed.id));
    const err = await refusal(asPlatform(() => updatePlan(actor, live.id, { code: code() })));
    expect(err.status).toBe(409);
    // And the database says the same to anything that goes around the service.
    // (Prisma reports a trigger's abort as a constraint violation; raw SQL shows the trigger's own words.)
    await expect(platformDb.plan.update({ where: { id: live.id }, data: { code: code() } })).rejects.toThrow();
    await expect(platformDb.$executeRawUnsafe(`UPDATE "Plan" SET "code" = ? WHERE "id" = ?`, code(), live.id)).rejects.toThrow(
      /cannot change once the plan has left draft/,
    );
    expect((await asPlatform(() => getPlan(live.id))).code).toBe(renamed.code);
  });
});

describe('an archived plan cannot be chosen for a new subscription, but existing ones keep it', () => {
  it('sells an active plan at its current version, with the amount taken from that version', async () => {
    const plan = await onSale();
    const sale = await asPlatform(() => planForNewSubscription(plan.id, 'annual'));
    expect(sale.version.id).toBe(plan.current.id);
    expect(sale.amount).toBe(3999000);
  });

  it('refuses an archived plan, and keeps every version it ever had readable', async () => {
    const plan = await onSale();
    // What an existing subscription would hold: the id of the version it was sold on.
    const heldVersionId = (await asPlatform(() => planForNewSubscription(plan.id, 'monthly'))).version.id;

    const archived = await asPlatform(() => archivePlan(actor, plan.id));
    expect(archived.status).toBe('archived');
    expect(archived.archivedAt).toBeDefined();

    const err = await refusal(asPlatform(() => planForNewSubscription(plan.id, 'monthly')));
    expect(err.code).toBe('PLAN_UNAVAILABLE');
    expect(err.status).toBe(409);

    const held = await asPlatform(() => resolvePlanVersion(heldVersionId));
    expect(held).toMatchObject({ id: heldVersionId, version: 1, monthlyPrice: 399900, annualPrice: 3999000, currency: 'INR', trialDays: 14 });
    expect(held.plan).toMatchObject({ id: plan.id, status: 'archived' });
    // Archiving touched the plan row only.
    expect(await platformDb.planVersion.count({ where: { planId: plan.id } })).toBe(1);
  });

  it('refuses a draft, a cycle the plan does not sell, and a plan that does not exist', async () => {
    const draft = await newPlan();
    expect((await refusal(asPlatform(() => planForNewSubscription(draft.id, 'monthly')))).code).toBe('PLAN_UNAVAILABLE');

    const monthlyOnly = await onSale({ cycles: ['monthly'] });
    expect(monthlyOnly.current.annualPrice).toBeNull();
    expect((await refusal(asPlatform(() => planForNewSubscription(monthlyOnly.id, 'annual')))).code).toBe('PLAN_UNAVAILABLE');

    expect((await refusal(asPlatform(() => planForNewSubscription('no-such-plan', 'monthly')))).code).toBe('PLAN_UNAVAILABLE');
  });

  it('offers a restored plan again, on its current terms', async () => {
    const plan = await onSale();
    await asPlatform(() => archivePlan(actor, plan.id));
    const restored = await asPlatform(() => restorePlan(actor, plan.id));
    expect(restored.status).toBe('active');
    expect(restored.archivedAt).toBeUndefined();
    expect((await asPlatform(() => planForNewSubscription(plan.id, 'monthly'))).amount).toBe(399900);
  });

  it('moves status only through the named transitions', async () => {
    const plan = await newPlan();
    expect(plan.status).toBe('draft');
    expect((await refusal(asPlatform(() => restorePlan(actor, plan.id)))).status).toBe(409);
    await asPlatform(() => publishPlan(actor, plan.id));
    expect((await refusal(asPlatform(() => publishPlan(actor, plan.id)))).status).toBe(409);
    await asPlatform(() => archivePlan(actor, plan.id));
    expect((await refusal(asPlatform(() => archivePlan(actor, plan.id)))).status).toBe(409);
    // An edit carries no status: whatever a caller sends, the field is not read.
    const edited = await asPlatform(() => updatePlan(actor, plan.id, { name: 'Renamed', status: 'active' } as never));
    expect(edited.status).toBe('archived');
    // The database refuses a status outside the three.
    await expect(platformDb.plan.update({ where: { id: plan.id }, data: { status: 'deleted' } })).rejects.toThrow();
  });

  it('lets exactly one of two concurrent transitions through', async () => {
    const plan = await onSale();
    const results = await Promise.allSettled([asPlatform(() => archivePlan(actor, plan.id)), asPlatform(() => archivePlan(actor, plan.id))]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(await platformDb.auditLog.count({ where: { targetId: plan.id, action: PLAN_AUDIT_ACTIONS.archived } })).toBe(1);
  });
});

describe("editing a plan's price leaves every historical record's terms untouched", () => {
  it('adds a version for a price change and leaves the old one exactly as it was', async () => {
    const plan = await onSale();
    const before = await versionRow(plan.current.id);

    const edited = await asPlatform(() => updatePlan(actor, plan.id, { monthlyPrice: 449900 }));
    expect(edited.current.version).toBe(2);
    expect(edited.current.id).not.toBe(plan.current.id);
    expect(edited.current.monthlyPrice).toBe(449900);
    // Unchanged terms are carried into the new version.
    expect(edited.current).toMatchObject({ annualPrice: 3999000, currency: 'INR', trialDays: 14 });

    expect(await versionRow(plan.current.id)).toEqual(before);
    expect((await asPlatform(() => resolvePlanVersion(plan.current.id))).monthlyPrice).toBe(399900);
    // New subscriptions are sold the new price; the history keeps both.
    expect((await asPlatform(() => planForNewSubscription(plan.id, 'monthly'))).amount).toBe(449900);
    expect((await asPlatform(() => listPlanVersions(plan.id))).map((v) => [v.version, v.monthlyPrice])).toEqual([
      [1, 399900],
      [2, 449900],
    ]);
  });

  it('versions every commercial term — currency, cycles and trial — and nothing else', async () => {
    const plan = await newPlan();
    const named = await asPlatform(() =>
      updatePlan(actor, plan.id, { name: 'Growth Plus', description: 'A larger faculty with more batches.', displayOrder: 4 }),
    );
    expect(named.current.version).toBe(1);
    expect(named).toMatchObject({ name: 'Growth Plus', displayOrder: 4 });

    const noTrial = await asPlatform(() => updatePlan(actor, plan.id, { trialEnabled: false }));
    expect(noTrial.current).toMatchObject({ version: 2, trialDays: 0 });
    const annualOnly = await asPlatform(() => updatePlan(actor, plan.id, { cycles: ['annual'] }));
    expect(annualOnly.current).toMatchObject({ version: 3, monthlyPrice: null, cycles: ['annual'] });
    const dollars = await asPlatform(() => updatePlan(actor, plan.id, { currency: 'USD', annualPrice: 50000 }));
    expect(dollars.current).toMatchObject({ version: 4, currency: 'USD', annualPrice: 50000 });
  });

  it('writes nothing for an edit that changes nothing', async () => {
    const plan = await newPlan();
    const again = await asPlatform(() => updatePlan(actor, plan.id, { monthlyPrice: 399900, name: ' Growth ' }));
    expect(again.current.version).toBe(1);
    expect(await platformDb.auditLog.count({ where: { targetId: plan.id, action: PLAN_AUDIT_ACTIONS.updated } })).toBe(0);
  });

  it('is enforced by the database, not only by the service', async () => {
    const plan = await newPlan();
    const id = plan.current.id;
    // Through the client and around it: Prisma reports the trigger's abort as a constraint violation,
    // raw SQL shows the trigger's own words. Either way nothing is written.
    await expect(platformDb.planVersion.update({ where: { id }, data: { monthlyPrice: 1 } })).rejects.toThrow();
    await expect(platformDb.$executeRawUnsafe(`UPDATE "PlanVersion" SET "monthlyPrice" = 1 WHERE "id" = ?`, id)).rejects.toThrow(/immutable/);
    await expect(platformDb.planVersion.delete({ where: { id } })).rejects.toThrow();
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "PlanVersion" WHERE "planId" = ?`, plan.id)).rejects.toThrow(/immutable/);
    // A plan cannot be deleted from under its versions either.
    await expect(platformDb.plan.delete({ where: { id: plan.id } })).rejects.toThrow();
    expect(await versionRow(id)).toMatchObject({ monthlyPrice: 399900 });
  });

  it('keeps version numbers unique per plan, so two racing edits cannot both be version 2', async () => {
    const plan = await newPlan();
    await expect(platformDb.planVersion.create({ data: { planId: plan.id, version: 1, currency: 'INR', monthlyPrice: 100 } })).rejects.toMatchObject({
      code: 'P2002',
    });
  });
});

describe('amounts are integers in the smallest currency unit throughout', () => {
  it('refuses a fractional or negative amount at the service, with the domain rule', async () => {
    const half = await refusal(newPlan({ monthlyPrice: 3999.5 }));
    expect(half.status).toBe(400);
    expect(half.issues).toContainEqual({ field: 'monthlyPrice', message: 'Enter a price above zero, to at most 2 decimal places.' });
    expect((await refusal(newPlan({ annualPrice: -1 }))).status).toBe(400);
    expect((await refusal(newPlan({ monthlyPrice: Number.NaN }))).status).toBe(400);
    expect((await refusal(newPlan({ currency: 'ZZZ' }))).status).toBe(400);
  });

  it('stores integers, as SQLite integers', async () => {
    const plan = await newPlan({ monthlyPrice: 149950, annualPrice: 1499500 });
    const [row] = await platformDb.$queryRawUnsafe<{ m: string; a: string; t: string }[]>(
      `SELECT typeof("monthlyPrice") AS m, typeof("annualPrice") AS a, typeof("trialDays") AS t FROM "PlanVersion" WHERE "id" = ?`,
      plan.current.id,
    );
    expect(row).toEqual({ m: 'integer', a: 'integer', t: 'integer' });
    expect(plan.current.monthlyPrice).toBe(149950);
  });

  it('refuses a real number, a negative price or a plan with no cycle at the database', async () => {
    const plan = await newPlan();
    const insert = (columns: string) =>
      platformDb.$executeRawUnsafe(
        `INSERT INTO "PlanVersion" ("id", "planId", "version", "currency", "monthlyPrice", "annualPrice") VALUES (?, ?, 9, 'INR', ${columns})`,
        `v-${unique()}`,
        plan.id,
      );
    await expect(insert('3999.5, NULL')).rejects.toThrow(/CHECK/);
    await expect(insert('-100, NULL')).rejects.toThrow(/CHECK/);
    await expect(insert('NULL, NULL')).rejects.toThrow(/CHECK/);
  });

  it('reads back every amount as a whole number', async () => {
    await newPlan();
    const plans = await asPlatform(() => listPlans());
    for (const plan of plans) {
      for (const amount of [plan.current.monthlyPrice, plan.current.annualPrice]) {
        if (amount !== null) expect(Number.isSafeInteger(amount), `${plan.code} ${amount}`).toBe(true);
      }
    }
  });
});

describe("a plan's features and limits are rows, not code (SAAS-002)", () => {
  it('holds the catalogue in the database exactly as the domain writes it', async () => {
    const features = await platformDb.feature.findMany({ orderBy: { displayOrder: 'asc' } });
    expect(features.map(({ id, group, label, description, enforcement }) => ({ key: id, group, label, description, enforcement }))).toEqual(
      FEATURES.map((f) => ({ ...f })),
    );
    const limits = await platformDb.limitDefinition.findMany({ orderBy: { displayOrder: 'asc' } });
    expect(limits.map(({ id, label, unit, period }) => ({ key: id, label, unit, period }))).toEqual(LIMITS.map((l) => ({ ...l })));
  });

  it('writes a version’s allowance as PlanFeature and PlanLimit rows', async () => {
    const plan = await newPlan({ limits: { ...LIMITS_750, 'courses.max': null } });
    const features = await platformDb.planFeature.findMany({ where: { planVersionId: plan.current.id } });
    expect(features.map((f) => f.featureKey).sort()).toEqual(['assessments.manage', 'courses.manage', 'reports.basic']);
    const limits = await platformDb.planLimit.findMany({ where: { planVersionId: plan.current.id } });
    expect(Object.fromEntries(limits.map((l) => [l.limitKey, l.value === null ? null : Number(l.value)]))).toEqual({ ...LIMITS_750, 'courses.max': null });
    // Storage is in bytes: 150 GB does not fit a 32-bit integer, and is stored exactly.
    expect(plan.current.limits['storage.bytes']).toBe(161_061_273_600);
    expect(plan.current.features).toEqual(['courses.manage', 'assessments.manage', 'reports.basic']);
  });

  it('versions a change of feature or limit, and leaves the earlier allowance as it was', async () => {
    const plan = await newPlan();
    const granted = await asPlatform(() => updatePlan(actor, plan.id, { features: [...plan.current.features, 'custom_branding'] }));
    expect(granted.current).toMatchObject({ version: 2, features: ['courses.manage', 'assessments.manage', 'reports.basic', 'custom_branding'] });
    const raised = await asPlatform(() => updatePlan(actor, plan.id, { limits: { ...LIMITS_750, 'learners.max': 1000 } }));
    expect(raised.current).toMatchObject({ version: 3 });
    expect(raised.current.limits['learners.max']).toBe(1000);

    const first = await asPlatform(() => resolvePlanVersion(plan.current.id));
    expect(first.features).toEqual(['courses.manage', 'assessments.manage', 'reports.basic']);
    expect(first.limits['learners.max']).toBe(750);
    // The same allowance in another order is no change.
    const same = await asPlatform(() => updatePlan(actor, plan.id, { features: [...raised.current.features].reverse() }));
    expect(same.current.version).toBe(3);
  });

  it('refuses a feature or limit the catalogue does not have — in the service and in the database', async () => {
    expect((await refusal(newPlan({ features: ['course-management' as never] }))).status).toBe(400);
    expect((await refusal(newPlan({ limits: { ...LIMITS_750, 'seats.max': 4 } as never }))).status).toBe(400);
    const incomplete = Object.fromEntries(Object.entries(LIMITS_750).filter(([key]) => key !== 'learners.max'));
    expect((await refusal(newPlan({ limits: incomplete as never }))).status).toBe(400);

    const plan = await newPlan();
    const version = await platformDb.planVersion.create({
      data: { planId: plan.id, version: 7, currency: 'INR', monthlyPrice: 100, featureCount: 1, limitCount: 1 },
    });
    await expect(platformDb.planFeature.create({ data: { planVersionId: version.id, featureKey: 'teleportation' } })).rejects.toThrow();
    await expect(platformDb.planLimit.create({ data: { planVersionId: version.id, limitKey: 'seats.max', value: 4n } })).rejects.toThrow();
    await expect(platformDb.planLimit.create({ data: { planVersionId: version.id, limitKey: 'learners.max', value: 0n } })).rejects.toThrow();
  });

  it('seals a version’s allowance: nothing can be added, changed or removed after it is written', async () => {
    const plan = await newPlan();
    const id = plan.current.id;
    // Adding one more grant to an existing version is refused at the size the version declared.
    await expect(platformDb.$executeRawUnsafe(`INSERT INTO "PlanFeature" ("planVersionId", "featureKey") VALUES (?, 'custom_branding')`, id)).rejects.toThrow(
      /already grants every feature it declared/,
    );
    await expect(platformDb.$executeRawUnsafe(`UPDATE "PlanLimit" SET "value" = NULL WHERE "planVersionId" = ?`, id)).rejects.toThrow(/immutable/);
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "PlanFeature" WHERE "planVersionId" = ?`, id)).rejects.toThrow(/immutable/);
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "PlanLimit" WHERE "planVersionId" = ?`, id)).rejects.toThrow(/immutable/);
    await expect(platformDb.$executeRawUnsafe(`UPDATE "PlanFeature" SET "featureKey" = 'custom_branding' WHERE "planVersionId" = ?`, id)).rejects.toThrow(
      /immutable/,
    );
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "Feature" WHERE "id" = 'priority_support'`)).rejects.toThrow(/never deleted/);
    expect((await asPlatform(() => resolvePlanVersion(id))).features).toEqual(plan.current.features);
  });

  it('reads a version written before SAAS-002 as granting nothing', async () => {
    const plan = await newPlan();
    // What the plan_tables migration left: a version with no allowance, declaring none.
    const legacy = await platformDb.planVersion.create({ data: { planId: plan.id, version: 9, currency: 'INR', monthlyPrice: 100 } });
    const read = await asPlatform(() => resolvePlanVersion(legacy.id));
    expect(read.features).toEqual([]);
    expect(Object.values(read.limits).every((v) => v === 0)).toBe(true);
    await expect(
      platformDb.$executeRawUnsafe(`INSERT INTO "PlanLimit" ("planVersionId", "limitKey", "value") VALUES (?, 'learners.max', NULL)`, legacy.id),
    ).rejects.toThrow(/already sets every limit it declared/);
  });

  it('records the allowance it changed in the audit trail', async () => {
    const plan = await newPlan();
    await asPlatform(() => updatePlan(actor, plan.id, { features: ['courses.manage'] }));
    const row = await platformDb.auditLog.findFirstOrThrow({ where: { targetId: plan.id, action: PLAN_AUDIT_ACTIONS.updated } });
    const meta = JSON.parse(row.metaJson);
    expect(meta.terms.from.features).toEqual(['courses.manage', 'assessments.manage', 'reports.basic']);
    expect(meta.terms.to.features).toEqual(['courses.manage']);
    expect(meta.terms.to.limits['storage.bytes']).toBe(161_061_273_600);
  });
});

describe('plans are the platform’s', () => {
  it('refuses a write from inside an academy, whoever the caller is', async () => {
    const err = await refusal(runInTenant(FIRST_TENANT_ID, () => createPlan(actor, input())));
    expect(err.status).toBe(403);
    const plan = await newPlan();
    expect((await refusal(runInTenant(FIRST_TENANT_ID, () => archivePlan(actor, plan.id)))).status).toBe(403);
    expect((await refusal(runInTenant(FIRST_TENANT_ID, () => updatePlan(actor, plan.id, { monthlyPrice: 1 })))).status).toBe(403);
  });

  it('refuses a signed-in caller who is not a super admin, even as the platform', async () => {
    const admin: AuditActor = { auth: { sub: 'someone', role: 'admin' } };
    expect((await refusal(asPlatform(() => createPlan(admin, input())))).status).toBe(403);
  });

  it('lets an academy read the catalogue it will be sold from', async () => {
    const plan = await onSale();
    const seen = await runInTenant(FIRST_TENANT_ID, () => planForNewSubscription(plan.id, 'monthly'));
    expect(seen.plan.id).toBe(plan.id);
  });
});

describe('audit', () => {
  it('records every change to a plan against the super admin who made it', async () => {
    const plan = await newPlan();
    await asPlatform(() => updatePlan(actor, plan.id, { monthlyPrice: 419900, name: 'Growth II' }));
    await asPlatform(() => publishPlan(actor, plan.id));
    await asPlatform(() => archivePlan(actor, plan.id));
    await asPlatform(() => restorePlan(actor, plan.id));

    const rows = await platformDb.auditLog.findMany({ where: { targetType: 'plan', targetId: plan.id }, orderBy: { createdAt: 'asc' } });
    expect(rows.map((r) => r.action)).toEqual(['plan.created', 'plan.updated', 'plan.published', 'plan.archived', 'plan.restored']);
    for (const row of rows) expect(row).toMatchObject({ actorId, actorRole: 'superadmin' });

    const updated = JSON.parse(rows[1].metaJson);
    expect(updated.version).toEqual({ from: 1, to: 2 });
    expect(updated.terms.from.monthlyPrice).toBe(399900);
    expect(updated.terms.to.monthlyPrice).toBe(419900);
    expect(updated.changes.name).toEqual({ from: 'Growth', to: 'Growth II' });
    expect(JSON.parse(rows[3].metaJson).status).toEqual({ from: 'active', to: 'archived' });
  });

  it('writes no event for a refused change', async () => {
    const plan = await newPlan();
    await refusal(asPlatform(() => updatePlan(actor, plan.id, { monthlyPrice: -5 })));
    await refusal(asPlatform(() => restorePlan(actor, plan.id)));
    expect(await platformDb.auditLog.count({ where: { targetId: plan.id } })).toBe(1);
  });
});
