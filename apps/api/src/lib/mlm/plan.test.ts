import { defaultMlmPlanTerms, type MlmPlanTermsInput } from '@syniastrolms/domain';
import { beforeAll, describe, expect, it } from 'vitest';
import { db as academyDb, platformDb } from '../../test/db.js';
import { unique } from '../../test/helpers.js';
import type { AuditActor } from '../audit.js';
import { ApiError } from '../errors.js';
import { provisionSuperAdmin } from '../provisionSuperAdmin.js';
import { FIRST_TENANT_ID, runAsPlatform, runInTenant } from '../tenancy.js';
import {
  MLM_PLAN_AUDIT_ACTIONS,
  activateMlmPlanVersion,
  activeMlmPlan,
  createMlmPlanVersion,
  deleteMlmPlanDraft,
  getMlmPlanVersion,
  listMlmPlanVersions,
  listProgramCourses,
  retireMlmPlanVersion,
  setMlmEligibleCourses,
  updateMlmPlanVersion,
} from './plan.js';

/* MLM-000: the affiliate plan as versioned platform data. Every call runs as the platform, the way the Super Admin
 * router calls it. The suite starts from whatever versions other tests left and never assumes it is alone, except
 * where it retires the active version at the end so the next suite sees none. */
const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('affiliate plan tests act as the Super Admin router does', fn);

let actor: AuditActor;
let actorId: string;
let paidCourseId: string;

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `mlm-plan-${unique()}@example.com`, password: 'mlm-plan-suite-pw', name: 'Plan Owner' });
  actorId = created.user.id;
  actor = { auth: { sub: actorId, role: 'superadmin' } };
  const paid = await academyDb.course.findFirst({ where: { pricing: 'paid', status: 'published' }, select: { id: true } });
  if (!paid) throw new Error('The seed has no paid course for the affiliate plan tests.');
  paidCourseId = paid.id;
});

const terms = (over: Partial<MlmPlanTermsInput> = {}): MlmPlanTermsInput => ({ ...defaultMlmPlanTerms(FIRST_TENANT_ID), ...over });

describe('creating versions', () => {
  it('stores the PDF plan as a draft, numbered after the latest, and reads it back exactly', async () => {
    const before = await asPlatform(() => listMlmPlanVersions());
    const created = await asPlatform(() => createMlmPlanVersion(actor, terms({ note: 'from the test' })));
    expect(created.status).toBe('draft');
    expect(created.version).toBe((before[0]?.version ?? 0) + 1);
    expect(created.tiers).toHaveLength(18);
    expect(created.capBands.map((b) => b.key)).toEqual(['starter', 'star', 'silver', 'platinum', 'ruby', 'crown']);
    expect(created.tiers[17]).toMatchObject({ name: 'Legacy Ambassador', groupCv: 500_00_00_000 * 100, rewardCapAmount: 10_00_00_000 * 100 });
    expect(created.eligibleCourseIds).toEqual([]);
    const again = await asPlatform(() => getMlmPlanVersion(created.id));
    expect(again).toEqual(created);
    const audit = await platformDb.auditLog.findFirst({ where: { action: MLM_PLAN_AUDIT_ACTIONS.created, targetId: created.id } });
    expect(audit).toMatchObject({ actorId, targetType: 'mlm_plan' });
  });

  it('starts a new draft from the active version, or from the PDF when none is active', async () => {
    const fromDefaults = await asPlatform(() => createMlmPlanVersion(actor, {}));
    expect(fromDefaults.programTenantId).toBe(FIRST_TENANT_ID);
    expect(fromDefaults.tiers).toHaveLength(18);
    const copied = await asPlatform(() => createMlmPlanVersion(actor, { fromVersionId: fromDefaults.id }));
    expect(copied.version).toBe(fromDefaults.version + 1);
    expect(copied.tiers).toEqual(fromDefaults.tiers);
    expect(copied.note).toBe('');
  });

  it('refuses invalid terms with the domain’s issues, an unknown LMS, and a course of another LMS', async () => {
    await expect(asPlatform(() => createMlmPlanVersion(actor, terms({ matchingRateBps: 9000 })))).rejects.toMatchObject({ status: 400 });
    await expect(asPlatform(() => createMlmPlanVersion(actor, terms({ programTenantId: 'no-such-tenant' })))).rejects.toMatchObject({ status: 400 });
    await expect(asPlatform(() => createMlmPlanVersion(actor, terms({ eligibleCourseIds: ['not-a-course'] })))).rejects.toMatchObject({ status: 400 });
    const bad = terms();
    bad.tiers[0] = { ...bad.tiers[0], groupCv: 3 };
    const err = await asPlatform(() => createMlmPlanVersion(actor, bad)).catch((e: unknown) => e);
    expect(err).toBeInstanceOf(ApiError);
    expect((err as ApiError).issues).toEqual(expect.arrayContaining([expect.objectContaining({ field: 'tiers.0.groupCv' })]));
  });

  it('is platform configuration: refused in an academy context, and to anyone but a super admin', async () => {
    await expect(runInTenant(FIRST_TENANT_ID, () => createMlmPlanVersion(actor, terms()))).rejects.toMatchObject({ status: 403 });
    await expect(asPlatform(() => createMlmPlanVersion({ auth: { sub: 'x', role: 'admin' } } as AuditActor, terms()))).rejects.toMatchObject({ status: 403 });
  });
});

describe('editing and activating', () => {
  it('edits a draft in place and refuses an edited version that has left draft', async () => {
    const draft = await asPlatform(() => createMlmPlanVersion(actor, terms()));
    const edited = await asPlatform(() =>
      updateMlmPlanVersion(actor, draft.id, terms({ matchingRateBps: 1200, eligibleCourseIds: [paidCourseId], note: 'edited' })),
    );
    expect(edited).toMatchObject({ id: draft.id, version: draft.version, matchingRateBps: 1200, eligibleCourseIds: [paidCourseId], note: 'edited' });
    expect(edited.tiers).toHaveLength(18);

    const active = await asPlatform(() => activateMlmPlanVersion(actor, draft.id));
    expect(active.status).toBe('active');
    expect(active.activatedAt).not.toBeNull();
    expect(await asPlatform(() => activeMlmPlan())).toMatchObject({ id: draft.id });
    await expect(asPlatform(() => updateMlmPlanVersion(actor, draft.id, terms()))).rejects.toMatchObject({ status: 409 });
    // The database agrees: a sealed tier cannot be touched even by a direct write (raw SQL carries the trigger's words; the client wraps them).
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM \`MlmRankTier\` WHERE \`planVersionId\` = ?`, draft.id)).rejects.toThrow(/left draft/);
    await expect(platformDb.$executeRawUnsafe(`UPDATE \`MlmPlanVersion\` SET \`matchingRateBps\` = 1 WHERE \`id\` = ?`, draft.id)).rejects.toThrow(
      /add a new version/,
    );
  });

  it('activation needs an eligible course, and retires the version that was active', async () => {
    const empty = await asPlatform(() => createMlmPlanVersion(actor, terms()));
    await expect(asPlatform(() => activateMlmPlanVersion(actor, empty.id))).rejects.toMatchObject({ status: 400 });
    const previous = await asPlatform(() => activeMlmPlan());
    const next = await asPlatform(() => createMlmPlanVersion(actor, terms({ eligibleCourseIds: [paidCourseId] })));
    await asPlatform(() => activateMlmPlanVersion(actor, next.id));
    expect(await asPlatform(() => activeMlmPlan())).toMatchObject({ id: next.id });
    if (previous) {
      const retired = await asPlatform(() => getMlmPlanVersion(previous.id));
      expect(retired.status).toBe('retired');
      expect(retired.retiredAt).not.toBeNull();
      await expect(asPlatform(() => activateMlmPlanVersion(actor, previous.id))).rejects.toMatchObject({ status: 409 });
    }
    // The database refuses a second active version even without the service.
    await expect(
      platformDb.$executeRawUnsafe(`UPDATE \`MlmPlanVersion\` SET \`status\` = 'active', \`activatedAt\` = CURRENT_TIMESTAMP WHERE \`id\` = ?`, empty.id),
    ).rejects.toThrow(/already active/);
    expect((await asPlatform(() => listMlmPlanVersions())).filter((v) => v.status === 'active')).toHaveLength(1);
  });

  it('lets only the course list change on the active version, never to empty', async () => {
    const active = await asPlatform(() => activeMlmPlan());
    expect(active).not.toBeNull();
    const changed = await asPlatform(() => setMlmEligibleCourses(actor, active!.id, [paidCourseId]));
    expect(changed.eligibleCourseIds).toEqual([paidCourseId]);
    await expect(asPlatform(() => setMlmEligibleCourses(actor, active!.id, []))).rejects.toMatchObject({ status: 400 });
    await expect(asPlatform(() => setMlmEligibleCourses(actor, active!.id, ['no-such-course']))).rejects.toMatchObject({ status: 400 });
  });

  it('lists the program LMS’s courses with a price only where one can be charged', async () => {
    const rows = await asPlatform(() => listProgramCourses(FIRST_TENANT_ID));
    expect(rows.length).toBeGreaterThan(0);
    const paid = rows.find((r) => r.id === paidCourseId);
    expect(paid?.priceAmount).toBeGreaterThan(0);
    expect(rows.every((r) => r.status !== 'archived')).toBe(true);
  });

  it('deletes an unused draft, keeps anything that was active, and retires the active version on request', async () => {
    const draft = await asPlatform(() => createMlmPlanVersion(actor, terms()));
    await asPlatform(() => deleteMlmPlanDraft(actor, draft.id));
    await expect(asPlatform(() => getMlmPlanVersion(draft.id))).rejects.toMatchObject({ status: 404 });

    const active = await asPlatform(() => activeMlmPlan());
    const retired = await asPlatform(() => retireMlmPlanVersion(actor, active!.id));
    expect(retired.status).toBe('retired');
    expect(await asPlatform(() => activeMlmPlan())).toBeNull();
    await expect(asPlatform(() => deleteMlmPlanDraft(actor, retired.id))).rejects.toMatchObject({ status: 409 });
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM \`MlmPlanVersion\` WHERE \`id\` = ?`, retired.id)).rejects.toThrow(/never deleted/);
    await expect(asPlatform(() => retireMlmPlanVersion(actor, retired.id))).rejects.toMatchObject({ status: 409 });
  });
});
