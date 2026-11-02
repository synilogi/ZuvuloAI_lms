import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { DEMO_SPONSOR_CODE, affiliateService as svc, resetAffiliateMock } from './affiliate';
import { simulation } from './simulation';

describe('the demo affiliate program', () => {
  beforeAll(() => vi.stubGlobal('window', globalThis));
  afterAll(() => vi.unstubAllGlobals());
  beforeEach(() => {
    resetAffiliateMock();
    simulation.latencyMs = 0;
  });

  it('starts outside the program, and opts in with the fixture sponsor', async () => {
    expect(await svc.me()).toBeNull();
    await expect(svc.activation()).rejects.toMatchObject({ reason: 'NOT_AN_AFFILIATE' });
    const me = await svc.enrol({ referralCode: DEMO_SPONSOR_CODE.toLowerCase(), preferredLeg: 'B' });
    expect(me).toMatchObject({ status: 'pending', preferredLeg: 'B', sponsor: { code: DEMO_SPONSOR_CODE } });
    expect(me.placement).not.toBeNull();
    expect(me.referralLink).toContain(`/ref/${me.code}`);
    expect((await svc.me())?.code).toBe(me.code);
    expect((await svc.setPreferredLeg('A')).preferredLeg).toBe('A');
    const activation = await svc.activation();
    expect(activation.courses[0]).toMatchObject({ purchase: 'none' });
    await expect(svc.enrol({})).rejects.toMatchObject({ code: 'conflict' });
  });

  it('places by the leg a link names, keeps the member’s own preference apart, and has no orders to list', async () => {
    const me = await svc.enrol({ referralCode: DEMO_SPONSOR_CODE, requestedLeg: 'B', preferredLeg: 'A' });
    expect(me.preferredLeg).toBe('A');
    // The demo sponsor prefers A and has both legs filled; a B link spills down leg B, and its open B is the outermost place.
    expect(me.placement).toMatchObject({ leg: 'B', depth: 2 });
    expect(me.legLinks.B).toContain(`ref=${me.code}&leg=B`);
    expect(await svc.orders()).toMatchObject({ rows: [], total: 0 });
  });

  it('resolves a referral link and refuses a bad code', async () => {
    const info = await svc.referral(DEMO_SPONSOR_CODE);
    expect(info.sponsor.code).toBe(DEMO_SPONSOR_CODE);
    expect(info.joinLink).toContain(`?ref=${DEMO_SPONSOR_CODE}`);
    await expect(svc.referral('NOPE1234')).rejects.toMatchObject({ reason: 'REFERRAL_INVALID' });
    await expect(svc.enrol({ referralCode: 'NOPE1234' })).rejects.toMatchObject({ reason: 'REFERRAL_INVALID' });
  });

  it('reads the tree, the team and the referrals of the visiting learner', async () => {
    await svc.enrol({ referralCode: DEMO_SPONSOR_CODE, preferredLeg: 'A' });
    const tree = await svc.tree();
    expect(tree.name).toBe('Ananya Rao');
    expect(tree.children).toEqual({ A: null, B: null });
    const team = await svc.team();
    expect(team.summary.total).toBe(0);
    expect(await svc.referrals()).toEqual([]);
    // A stranger's node is not in the learner's team.
    await expect(svc.tree('aff-2')).rejects.toMatchObject({ code: 'not-found' });
  });

  it('shows the visiting learner empty legs and an empty ledger until someone under them buys', async () => {
    await expect(svc.figures()).rejects.toMatchObject({ reason: 'NOT_AN_AFFILIATE' });
    await svc.enrol({ referralCode: DEMO_SPONSOR_CODE, preferredLeg: 'A' });
    expect(await svc.figures()).toMatchObject({ lifetimeA: 0, lifetimeB: 0, unmatchedA: 0, unmatchedB: 0, matchable: 0, eligibleOrders: 0, currency: 'INR' });
    expect((await svc.cvLedger()).rows).toEqual([]);
  });
});
