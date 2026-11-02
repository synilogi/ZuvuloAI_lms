import type { PermissionKey, Role, UserProfile } from '@syniastrolms/domain';

/**
 * What the academy admin workspace may show.
 *
 * Only `role === 'admin'` is permission-driven. An instructor keeps the access their role and scope
 * give them, and the platform super admin has its own workspace — neither is filtered here.
 *
 * This is convenience, never security: the API refuses the same calls on its own, so hiding a button
 * only spares someone a 403 they would otherwise walk into.
 */

/**
 * The key that opens each admin page, longest prefix first. A page is listed only when the endpoint
 * behind it asks for a key — the dashboard's figures come from the reports endpoints, the catalog
 * pages from the catalog reads, and so on.
 *
 * Deliberately absent, because the API governs them by role alone: the calendar, notifications, the
 * Help Centre, the account dialogs, and reading certificates and live classes (the catalogue has no
 * `certificates.view` or `live.view`, and this phase did not invent one).
 */
export const ADMIN_PAGE_PERMISSIONS: readonly { path: string; key: PermissionKey; exact?: boolean }[] = [
  { path: '/admin/reports/instructors', key: 'reports.instructors.view' },
  { path: '/admin/courses', key: 'catalog.view' },
  { path: '/admin/categories', key: 'catalog.view' },
  { path: '/admin/quizzes', key: 'assessment.view' },
  { path: '/admin/assignments', key: 'assessment.view' },
  { path: '/admin/students', key: 'learners.view' },
  { path: '/admin/instructors', key: 'instructors.view' },
  { path: '/admin/reports', key: 'reports.view' },
  { path: '/admin/reviews', key: 'reports.view' },
  { path: '/admin/settings', key: 'settings.view' },
  // The dashboard itself, matched exactly: its figures come from the reports endpoints. Everything
  // else under /admin is governed by its own entry above, or by role alone.
  { path: '/admin', key: 'reports.view', exact: true },
];

/** The key a path needs, or `undefined` when the page is not permission-controlled. */
export function pagePermission(pathname: string): PermissionKey | undefined {
  const match = ADMIN_PAGE_PERMISSIONS.find(({ path, exact }) => (exact ? pathname === path : pathname === path || pathname.startsWith(`${path}/`)));
  return match?.key;
}

/** The keys an account holds. A profile without the field holds none — never all. */
export const permissionsOf = (user: Pick<UserProfile, 'permissions'>): PermissionKey[] => user.permissions ?? [];

/**
 * Whether this account may do `key`. An undefined key means the thing is not permission-controlled.
 * Every role but `admin` answers yes, because no other role is governed by this system.
 */
export function allows(role: Role, permissions: PermissionKey[], key?: PermissionKey): boolean {
  if (!key) return true;
  if (role !== 'admin') return true;
  return permissions.includes(key);
}
