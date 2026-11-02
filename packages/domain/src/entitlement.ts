/**
 * The entitlement catalogue: every feature a plan can grant and every limit it can set
 * (subscriptions.md §4). This is the one place either list is written. The API mirrors it into the
 * `Feature` and `LimitDefinition` tables, a plan version grants from it with `PlanFeature` and
 * `PlanLimit` rows, and nothing anywhere asks which plan an academy is on — only what its plan grants.
 *
 * Entitlement never replaces authorization. A capability needs the account's permission *and* the
 * academy's entitlement (§41); `ENFORCEMENT_MATRIX` records which of each a capability needs.
 */

import type { PermissionKey } from './permission';

/* ─── Features ──────────────────────────────────────────────────────────── */

export type FeatureKey =
  | 'courses.manage'
  | 'assessments.manage'
  | 'certificates.manage'
  | 'live_classes'
  | 'reports.basic'
  | 'reports.advanced'
  | 'analytics.advanced'
  | 'custom_branding'
  | 'priority_support';

export type FeatureGroupId = 'teaching' | 'insight' | 'service';

/**
 * How a feature is delivered (SAAS-025): `route` — the API refuses its routes without it; `service` — a service
 * level the platform provides, which no route checks; `planned` — sold in a plan's catalogue but not built yet, so
 * nothing uses it and no route pretends to.
 */
export type FeatureEnforcement = 'route' | 'service' | 'planned';

export interface FeatureMeta {
  key: FeatureKey;
  group: FeatureGroupId;
  label: string;
  description: string;
  enforcement: FeatureEnforcement;
}

/** Every feature, in the order a plan lists them. Adding one here adds it to every plan form and, by migration, to the catalogue table. */
export const FEATURES: readonly FeatureMeta[] = [
  {
    key: 'courses.manage',
    group: 'teaching',
    label: 'Course management',
    description: 'Courses, chapters and lessons with the full editor.',
    enforcement: 'route',
  },
  {
    key: 'assessments.manage',
    group: 'teaching',
    label: 'Assessments',
    description: 'Quizzes and assignments with grading and review queues.',
    enforcement: 'route',
  },
  { key: 'live_classes', group: 'teaching', label: 'Live classes', description: 'Scheduling, registration, attendance and recordings.', enforcement: 'route' },
  { key: 'certificates.manage', group: 'teaching', label: 'Certificates', description: 'Templates, issuing and public verification.', enforcement: 'route' },
  { key: 'reports.basic', group: 'insight', label: 'Reports', description: 'The course, learner and enrolment reports.', enforcement: 'route' },
  {
    key: 'reports.advanced',
    group: 'insight',
    label: 'Advanced reports',
    description: 'Instructor and completion reporting beyond the basic reports.',
    enforcement: 'route',
  },
  { key: 'analytics.advanced', group: 'insight', label: 'Advanced analytics', description: 'Cohort funnels, retention and exports.', enforcement: 'planned' },
  {
    key: 'custom_branding',
    group: 'service',
    label: 'Custom branding',
    description: 'Academy colours, cover art and certificate marks.',
    enforcement: 'route',
  },
  {
    key: 'priority_support',
    group: 'service',
    label: 'Priority support',
    description: 'Named contact with a four-hour first response.',
    enforcement: 'service',
  },
];

export const FEATURE_KEYS: readonly FeatureKey[] = FEATURES.map((f) => f.key);

export const FEATURE_GROUP_LABEL: Record<FeatureGroupId, string> = { teaching: 'Teaching', insight: 'Insight', service: 'Brand and service' };

/** The catalogue grouped the way the plan editor renders it. */
export const FEATURE_GROUPS: readonly { id: FeatureGroupId; label: string; features: readonly FeatureMeta[] }[] = (
  Object.keys(FEATURE_GROUP_LABEL) as FeatureGroupId[]
).map((id) => ({ id, label: FEATURE_GROUP_LABEL[id], features: FEATURES.filter((f) => f.group === id) }));

export const isFeatureKey = (key: string): key is FeatureKey => (FEATURE_KEYS as readonly string[]).includes(key);

export const featureLabel = (key: FeatureKey): string => FEATURES.find((f) => f.key === key)?.label ?? key;

/** How a feature is delivered: gated by routes, a service level, or not built yet. */
export const featureEnforcement = (key: FeatureKey): FeatureEnforcement => FEATURES.find((f) => f.key === key)?.enforcement ?? 'route';

/* ─── Limits ────────────────────────────────────────────────────────────── */

export type LimitKey = 'learners.max' | 'instructors.max' | 'courses.max' | 'storage.bytes' | 'live_classes.max' | 'admin_accounts.max';

export interface LimitMeta {
  key: LimitKey;
  label: string;
  /** What the number counts. Storage is in bytes; everything else is a count. */
  unit: 'count' | 'bytes';
  /** `total` is a ceiling on what exists at once; `month` resets each calendar month. */
  period: 'total' | 'month';
}

export const LIMITS: readonly LimitMeta[] = [
  { key: 'learners.max', label: 'Learners', unit: 'count', period: 'total' },
  { key: 'instructors.max', label: 'Instructors', unit: 'count', period: 'total' },
  { key: 'courses.max', label: 'Courses', unit: 'count', period: 'total' },
  { key: 'storage.bytes', label: 'Media storage', unit: 'bytes', period: 'total' },
  { key: 'live_classes.max', label: 'Live classes a month', unit: 'count', period: 'month' },
  { key: 'admin_accounts.max', label: 'Admin accounts', unit: 'count', period: 'total' },
];

export const LIMIT_KEYS: readonly LimitKey[] = LIMITS.map((l) => l.key);

export const LIMIT_LABEL = Object.fromEntries(LIMITS.map((l) => [l.key, l.label])) as Record<LimitKey, string>;

export const isLimitKey = (key: string): key is LimitKey => (LIMIT_KEYS as readonly string[]).includes(key);

/**
 * What a plan allows for each limit. `null` is "no ceiling" — never read as zero. A limit a plan does
 * not state at all grants nothing: `limitOf` answers 0 for it, so a gap in the data can only ever
 * refuse, never allow.
 */
export type PlanLimits = Record<LimitKey, number | null>;

export const limitOf = (limits: Partial<PlanLimits>, key: LimitKey): number | null => (key in limits ? (limits[key] ?? null) : 0);

/** A gibibyte, which the screens call a gigabyte: storage limits are entered and shown in these. */
export const BYTES_PER_GB = 1024 ** 3;

/* ─── Enforcement matrix (§42) ──────────────────────────────────────────── */

export interface EnforcementRule {
  /** What an academy is trying to do. */
  capability: string;
  /** The account permission it needs, from `permission.ts` — `null` where the route is not a permission-governed academy route. */
  permission: PermissionKey | null;
  /** The plan feature it needs — `null` where every plan allows it and only a limit applies. */
  feature: FeatureKey | null;
  /** The limit it consumes, if any. */
  limit: LimitKey | null;
  note?: string;
}

/**
 * The source of truth for how a capability is gated. The entitlement service (SAAS-003) and usage
 * enforcement (SAAS-011) read this; nothing is gated by a plan's name. Permission and entitlement must
 * both pass (§41). Every permission key here is a real one — the type says so, and a test checks it.
 *
 * Where this differs from the example table in §42: learners and instructors have no feature flag,
 * because the catalogue in §4 defines none (an academy without learners is not an academy), so they
 * are gated by their limits alone; courses are gated by `courses.manage`, the §4 key.
 *
 * A feature gate governs adding and changing. It never stops an academy withdrawing its own content
 * (unpublish, archive, delete, revoke) or serving learners it already has (registration, hand-ins,
 * grading, reminders): a plan that no longer includes a feature leaves what exists usable.
 */
export const ENFORCEMENT_MATRIX: readonly EnforcementRule[] = [
  {
    capability: 'Enrol a learner',
    permission: 'learners.enroll',
    feature: null,
    limit: 'learners.max',
    note: 'Counted as learners in the academy; self-registration adds one too.',
  },
  { capability: 'Add an instructor', permission: 'instructors.manage', feature: null, limit: 'instructors.max' },
  {
    capability: 'Activate an inactive instructor',
    permission: 'instructors.status',
    feature: null,
    limit: 'instructors.max',
    note: 'Leaving inactive takes a seat, through the status route or an edit (SAAS-025).',
  },
  { capability: 'Create a course', permission: 'catalog.edit', feature: 'courses.manage', limit: 'courses.max' },
  {
    capability: 'Create a category',
    permission: 'catalog.categories.manage',
    feature: null,
    limit: null,
    note: 'Categories are catalogue structure, in no plan feature. Restricted mode refuses a new one (it adds; SAAS-025).',
  },
  {
    capability: 'Change or delete a category',
    permission: 'catalog.categories.manage',
    feature: null,
    limit: null,
    note: 'Open in restricted mode: it changes or takes down what exists (SAAS-025).',
  },
  { capability: 'Change a course or its curriculum', permission: 'catalog.edit', feature: 'courses.manage', limit: null },
  { capability: 'Publish a course', permission: 'catalog.publish', feature: 'courses.manage', limit: null },
  {
    capability: 'Upload media',
    permission: null,
    feature: null,
    limit: 'storage.bytes',
    note: 'Any signed-in account may upload — lesson media and assignment hand-ins alike — and every upload counts against the academy’s storage.',
  },
  { capability: 'Create or change a quiz or assignment', permission: 'assessment.edit', feature: 'assessments.manage', limit: null },
  { capability: 'Issue a certificate', permission: 'certificates.issue', feature: 'certificates.manage', limit: null },
  { capability: 'Manage certificate templates', permission: 'certificates.templates.manage', feature: 'certificates.manage', limit: null },
  { capability: 'Schedule or change a live class', permission: 'live.manage', feature: 'live_classes', limit: 'live_classes.max' },
  { capability: 'Read the course, learner and enrolment reports', permission: 'reports.view', feature: 'reports.basic', limit: null },
  { capability: 'Read the instructor report', permission: 'reports.instructors.view', feature: 'reports.advanced', limit: null },
  {
    capability: 'Use advanced analytics',
    permission: 'reports.view',
    feature: 'analytics.advanced',
    limit: null,
    note: 'No route yet: cohort funnels, retention and exports are not built.',
  },
  { capability: 'Brand the academy', permission: 'settings.edit', feature: 'custom_branding', limit: null, note: 'The appearance section of settings.' },
  {
    capability: 'Add an academy admin',
    permission: null,
    feature: null,
    limit: 'admin_accounts.max',
    note: 'Admins are created by the platform (POST /superadmin/admins), so the limit is checked there.',
  },
  {
    capability: 'Priority support',
    permission: null,
    feature: 'priority_support',
    limit: null,
    note: 'A service level, not a route: nothing in the application is gated by it.',
  },
];

/* ─── Usage strategy (§23) ──────────────────────────────────────────────── */

export interface UsageStrategy {
  /** How the figure is obtained. Every metric is live: counted from the academy's own rows when asked. */
  strategy: 'live';
  /** What is counted. */
  counts: string;
  /** Which writes add to it, and are checked against the limit before they happen. */
  guardedWrites: string;
}

/**
 * How each limit's usage is measured — the decision §23 asks to be written down. All six are
 * live-calculated inside the same transaction as the write that would add to them, after that
 * transaction has taken the academy's guard for the limit (`UsageGuard`), so two requests can never
 * both pass a check against the same stale figure. Live counts over tenant-indexed columns are cheap at
 * this scale and can never drift, so there is no cached counter and nothing to reconcile; a counter
 * would be the change to make only if a count became slow.
 */
export const USAGE_STRATEGY: Record<LimitKey, UsageStrategy> = {
  'learners.max': { strategy: 'live', counts: 'Every learner account in the academy.', guardedWrites: 'Self-registration.' },
  'instructors.max': {
    strategy: 'live',
    counts: 'Instructors not marked inactive (an invited one can accept, so it counts).',
    guardedWrites: 'Adding an instructor.',
  },
  'courses.max': { strategy: 'live', counts: 'Courses not archived.', guardedWrites: 'Creating a course; restoring an archived one.' },
  'storage.bytes': { strategy: 'live', counts: 'The size of every uploaded file, in bytes.', guardedWrites: 'Uploading a file, by the size of the file.' },
  'live_classes.max': {
    strategy: 'live',
    counts: 'Live classes starting in a calendar month (UTC), cancelled ones excepted — the month of the class, not of the request.',
    guardedWrites: 'Scheduling a live class; moving one into another month.',
  },
  'admin_accounts.max': { strategy: 'live', counts: 'Academy admin accounts not deactivated.', guardedWrites: 'Creating an admin; reactivating one.' },
};

/* ─── Restricted mode (§21) ─────────────────────────────────────────────── */

export type RestrictedOperation =
  | 'read'
  | 'update'
  | 'withdraw'
  | 'serve_learners'
  | 'create'
  | 'publish'
  | 'live_classes'
  | 'advanced_reports'
  | 'branding'
  | 'storage'
  | 'learner_creation'
  | 'instructor_creation';

/**
 * What an academy may still do when its subscription serves no plan — never subscribed, paused,
 * cancelled or expired — once enforcement is on (§21). The rule: nothing that exists is taken away, and
 * nothing new is added. Its data stays readable and editable, it can take content down, and its
 * learners keep learning; it cannot grow — no new courses, content, classes, files, learners or
 * instructors, nothing published, no paid-tier insight or branding. Every refusal carries
 * SUBSCRIPTION_REQUIRED or SUBSCRIPTION_EXPIRED, which the screens turn into a renew/subscribe prompt.
 * The platform itself (a super admin) is never restricted.
 *
 * "Keeps what it had" is literal for plan features (SAAS-025): an operation marked allowed goes ahead on a
 * feature-gated route only if the academy's last plan included that feature. An academy that never subscribed
 * had no plan, so no plan feature stays open for it — it keeps every read, edit and learner path that no plan
 * feature governs. Restricted mode can therefore never grant more than the lowest paid tier that had the feature.
 */
export const RESTRICTED_MODE_POLICY: Record<RestrictedOperation, { allowed: boolean; covers: string }> = {
  read: {
    allowed: true,
    covers: 'Every read: courses, learners, settings, the dashboard — and reports on the basic tier while the last plan included them.',
  },
  update: {
    allowed: true,
    covers: 'Editing what already exists: a category, course, chapter, lesson, quiz, assignment, live class, certificate template default.',
  },
  withdraw: { allowed: true, covers: 'Unpublishing, archiving, deleting and cancelling; deleting a category; revoking a certificate.' },
  serve_learners: {
    allowed: true,
    covers: 'Everything learners do, and staff do for them: learning, hand-ins, grading, registrations, reminders, issuing earned certificates.',
  },
  create: { allowed: false, covers: 'New categories, courses, chapters, lessons, quizzes, assignments and certificate templates; duplicating any of them.' },
  publish: { allowed: false, covers: 'Putting a course in front of learners.' },
  live_classes: { allowed: false, covers: 'Scheduling a new live class (existing ones still run and can be edited).' },
  advanced_reports: { allowed: false, covers: 'The instructor report and advanced analytics.' },
  branding: { allowed: false, covers: 'Changing the academy’s appearance.' },
  storage: { allowed: false, covers: 'Uploading files.' },
  learner_creation: { allowed: false, covers: 'New learner sign-ups.' },
  instructor_creation: { allowed: false, covers: 'Adding instructors, or activating an inactive one.' },
};

/* ─── Workspace modules (plan-aware navigation) ─────────────────────────── */

/** The staff workspace's plan-gated modules. Everything else (dashboard, students, calendar, help, billing…) needs no plan feature. */
export type WorkspaceModule = 'courses' | 'quizzes' | 'assignments' | 'certificates' | 'live' | 'reports' | 'branding';

/** The plan feature each module is sold under — the same feature its routes check (`ENFORCEMENT_MATRIX`). */
export const MODULE_FEATURE: Readonly<Record<WorkspaceModule, FeatureKey>> = {
  courses: 'courses.manage',
  quizzes: 'assessments.manage',
  assignments: 'assessments.manage',
  certificates: 'certificates.manage',
  live: 'live_classes',
  reports: 'reports.basic',
  branding: 'custom_branding',
};

/** What an academy's plan, as `GET /academy/plan` reports it, lets its staff see. */
export interface AcademyPlan {
  /** Whether plans are enforced yet (`ENTITLEMENT_ENFORCEMENT`). While not, every module is open. */
  enforced: boolean;
  /** The subscription's server status, or null when the academy has never subscribed. */
  status: 'trialing' | 'active' | 'past_due' | 'paused' | 'canceling' | 'canceled' | 'expired' | null;
  /** No plan is served (never subscribed, paused, ended): nothing new can be added (§21). */
  restricted: boolean;
  plan: { id: string; code: string; name: string } | null;
  /** The features the academy is served now. */
  features: FeatureKey[];
  /** While restricted after a plan ended: the features that plan had, which stay readable (SAAS-025). */
  lastFeatures: FeatureKey[];
  trialEndsAt?: string;
  renewsAt?: string;
  /** The academy itself: its display name and the address its join link uses (`/join/:slug`, SAAS-028). */
  academy?: { name: string; slug: string };
}

/** How a plan-gated part of the workspace appears to an academy's staff. */
export type PlanAccess = 'open' | 'read-only' | 'locked';

/**
 * How a feature appears to an academy's staff:
 *   - `open` — enforcement is off, or the plan includes the feature;
 *   - `read-only` — the plan that included it has ended: what was made stays readable, nothing new is added;
 *   - `locked` — no plan the academy is served (or had) includes it: shown with what unlocks it.
 */
export function featureAccess(plan: Pick<AcademyPlan, 'enforced' | 'features' | 'lastFeatures'>, feature: FeatureKey): PlanAccess {
  if (!plan.enforced) return 'open';
  if (plan.features.includes(feature)) return 'open';
  if (plan.lastFeatures.includes(feature)) return 'read-only';
  return 'locked';
}

/** How a module appears to an academy's staff — the access of the feature it is sold under (`featureAccess`). */
export function moduleAccess(plan: Pick<AcademyPlan, 'enforced' | 'features' | 'lastFeatures'>, module: WorkspaceModule): PlanAccess {
  return featureAccess(plan, MODULE_FEATURE[module]);
}

/**
 * Whether the academy still has to choose its first plan: plans are enforced and it has never subscribed, or it
 * is restricted with nothing kept from an earlier plan. Its admin is shown the plans (and the free trial) first.
 */
export const needsPlanChoice = (plan: Pick<AcademyPlan, 'enforced' | 'status' | 'restricted' | 'lastFeatures'>): boolean =>
  plan.enforced && (plan.status === null || (plan.restricted && plan.lastFeatures.length === 0));
