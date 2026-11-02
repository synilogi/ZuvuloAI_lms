import { describe, expect, it } from 'vitest';
import {
  ENFORCEMENT_MATRIX,
  FEATURES,
  FEATURE_GROUPS,
  MODULE_FEATURE,
  FEATURE_KEYS,
  LIMITS,
  LIMIT_KEYS,
  isFeatureKey,
  isLimitKey,
  limitOf,
  featureAccess,
  moduleAccess,
  needsPlanChoice,
  type FeatureKey,
  type PlanLimits,
  type WorkspaceModule,
} from './entitlement';
import { PERMISSION_KEYS } from './permission';

describe('the catalogue', () => {
  it('holds exactly the features and limits subscriptions.md §4 names', () => {
    expect([...FEATURE_KEYS].sort()).toEqual(
      [
        'analytics.advanced',
        'assessments.manage',
        'certificates.manage',
        'courses.manage',
        'custom_branding',
        'live_classes',
        'priority_support',
        'reports.advanced',
        'reports.basic',
      ].sort(),
    );
    expect([...LIMIT_KEYS].sort()).toEqual(
      ['admin_accounts.max', 'courses.max', 'instructors.max', 'learners.max', 'live_classes.max', 'storage.bytes'].sort(),
    );
  });

  it('lists every key once, and every feature in exactly one group', () => {
    expect(new Set(FEATURE_KEYS).size).toBe(FEATURES.length);
    expect(new Set(LIMIT_KEYS).size).toBe(LIMITS.length);
    expect(FEATURE_GROUPS.flatMap((g) => g.features.map((f) => f.key)).sort()).toEqual([...FEATURE_KEYS].sort());
  });

  it('recognises catalogue keys and nothing else', () => {
    expect(isFeatureKey('custom_branding')).toBe(true);
    expect(isFeatureKey('custom-branding')).toBe(false);
    expect(isLimitKey('storage.bytes')).toBe(true);
    expect(isLimitKey('storageGb')).toBe(false);
  });
});

describe('limitOf', () => {
  const limits: Partial<PlanLimits> = { 'learners.max': 250, 'courses.max': null };

  it('reads a stated limit, and null as unlimited', () => {
    expect(limitOf(limits, 'learners.max')).toBe(250);
    expect(limitOf(limits, 'courses.max')).toBeNull();
  });

  it('grants nothing for a limit the plan does not state', () => {
    expect(limitOf(limits, 'instructors.max')).toBe(0);
    expect(limitOf({}, 'storage.bytes')).toBe(0);
  });
});

describe('the enforcement matrix (§42)', () => {
  it('names only real permissions, features and limits', () => {
    for (const rule of ENFORCEMENT_MATRIX) {
      if (rule.permission) expect(PERMISSION_KEYS, rule.capability).toContain(rule.permission);
      if (rule.feature) expect(FEATURE_KEYS, rule.capability).toContain(rule.feature);
      if (rule.limit) expect(LIMIT_KEYS, rule.capability).toContain(rule.limit);
    }
  });

  it('covers every feature and every limit, so nothing in the catalogue is ungoverned', () => {
    const features = new Set(ENFORCEMENT_MATRIX.map((r) => r.feature).filter(Boolean));
    const limits = new Set(ENFORCEMENT_MATRIX.map((r) => r.limit).filter(Boolean));
    expect([...features].sort()).toEqual([...FEATURE_KEYS].sort());
    expect([...limits].sort()).toEqual([...LIMIT_KEYS].sort());
  });

  it('gates every academy route by a permission as well as its plan', () => {
    // A rule with no permission must say why: the capability is not an academy route.
    for (const rule of ENFORCEMENT_MATRIX.filter((r) => r.permission === null)) expect(rule.note, rule.capability).toBeTruthy();
    expect(new Set(ENFORCEMENT_MATRIX.map((r) => r.capability)).size).toBe(ENFORCEMENT_MATRIX.length);
  });
});

describe('usage strategy and restricted mode (§21, §23)', () => {
  it('writes a strategy down for every limit', async () => {
    const { USAGE_STRATEGY } = await import('./entitlement');
    expect(Object.keys(USAGE_STRATEGY).sort()).toEqual([...LIMIT_KEYS].sort());
    for (const s of Object.values(USAGE_STRATEGY)) expect(s.counts.length && s.guardedWrites.length).toBeTruthy();
  });

  it('keeps what exists and stops what is new', async () => {
    const { RESTRICTED_MODE_POLICY } = await import('./entitlement');
    const allowed = Object.entries(RESTRICTED_MODE_POLICY)
      .filter(([, p]) => p.allowed)
      .map(([op]) => op)
      .sort();
    expect(allowed).toEqual(['read', 'serve_learners', 'update', 'withdraw']);
    // §21 names these operations; each has a written policy.
    for (const op of ['read', 'create', 'update', 'publish', 'live_classes', 'advanced_reports', 'storage', 'learner_creation', 'instructor_creation']) {
      expect(RESTRICTED_MODE_POLICY, op).toHaveProperty(op);
    }
  });
});

describe('moduleAccess', () => {
  const plan = (over: Partial<{ enforced: boolean; features: FeatureKey[]; lastFeatures: FeatureKey[] }> = {}) => ({
    enforced: true,
    features: [] as FeatureKey[],
    lastFeatures: [] as FeatureKey[],
    ...over,
  });

  it('opens every module while plans are not enforced', () => {
    for (const module of Object.keys(MODULE_FEATURE) as WorkspaceModule[]) expect(moduleAccess(plan({ enforced: false }), module)).toBe('open');
  });

  it('opens what the plan includes and locks the rest', () => {
    const growth = plan({ features: ['courses.manage', 'assessments.manage', 'live_classes', 'reports.basic', 'certificates.manage'] });
    expect(moduleAccess(growth, 'courses')).toBe('open');
    expect(moduleAccess(growth, 'quizzes')).toBe('open');
    expect(moduleAccess(growth, 'branding')).toBe('locked');
  });

  it('keeps a module the ended plan had readable, and locks everything for an academy that never subscribed', () => {
    expect(moduleAccess(plan({ lastFeatures: ['courses.manage'] }), 'courses')).toBe('read-only');
    expect(moduleAccess(plan(), 'courses')).toBe('locked');
  });

  it('maps every module to a feature in the catalogue', () => {
    for (const feature of Object.values(MODULE_FEATURE)) expect(FEATURE_KEYS).toContain(feature);
  });
});

describe('featureAccess', () => {
  const plan = { enforced: true, features: ['reports.basic'] as FeatureKey[], lastFeatures: [] as FeatureKey[] };

  it('answers for a feature that is no module of its own, such as the advanced reports', () => {
    expect(featureAccess(plan, 'reports.basic')).toBe('open');
    expect(featureAccess(plan, 'reports.advanced')).toBe('locked');
    expect(featureAccess({ ...plan, enforced: false }, 'reports.advanced')).toBe('open');
    expect(featureAccess({ ...plan, features: [], lastFeatures: ['reports.advanced'] }, 'reports.advanced')).toBe('read-only');
  });
});

describe('needsPlanChoice', () => {
  const base = { enforced: true, status: null, restricted: true, lastFeatures: [] as FeatureKey[] };

  it('asks an academy that never subscribed to choose a plan, only while plans are enforced', () => {
    expect(needsPlanChoice(base)).toBe(true);
    expect(needsPlanChoice({ ...base, enforced: false })).toBe(false);
  });

  it('leaves an academy on a plan, or one that keeps an ended plan’s features, where it is', () => {
    expect(needsPlanChoice({ ...base, status: 'trialing', restricted: false })).toBe(false);
    expect(needsPlanChoice({ ...base, status: 'expired', lastFeatures: ['courses.manage'] })).toBe(false);
    expect(needsPlanChoice({ ...base, status: 'expired' })).toBe(true);
  });
});
