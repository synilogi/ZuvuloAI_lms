/* An academy's lifecycle on the platform (SAAS-019). Pure rules, shared by the API and any client. */

export type AcademyStatus = 'active' | 'suspended' | 'archived';
export const ACADEMY_STATUSES: readonly AcademyStatus[] = ['active', 'suspended', 'archived'];

export type AcademyAction = 'suspend' | 'reactivate' | 'archive';

/**
 * Where each action may start. Suspending pauses an active academy; archiving closes an active or suspended
 * one; reactivating opens either again. Nothing here deletes data — every status keeps every row.
 */
const FROM: Record<AcademyAction, readonly AcademyStatus[]> = {
  suspend: ['active'],
  archive: ['active', 'suspended'],
  reactivate: ['suspended', 'archived'],
};
const TO: Record<AcademyAction, AcademyStatus> = { suspend: 'suspended', archive: 'archived', reactivate: 'active' };

/** The status an action leads to, or `null` when it cannot start from `from`. */
export const academyTransition = (from: AcademyStatus, action: AcademyAction): AcademyStatus | null => (FROM[action].includes(from) ? TO[action] : null);

export const isAcademyStatus = (value: unknown): value is AcademyStatus => ACADEMY_STATUSES.includes(value as AcademyStatus);

/** What a signed-in member of an academy that is not active is told. */
export const ACADEMY_CLOSED_MESSAGE: Record<Exclude<AcademyStatus, 'active'>, string> = {
  suspended: 'This account is suspended. Contact ZuviloAI support to restore access.',
  archived: 'This account has been closed.',
};

/** Slugs a new academy cannot take: they name platform routes or read as the platform. */
export const RESERVED_ACADEMY_SLUGS = ['admin', 'api', 'app', 'auth', 'default', 'help', 'platform', 'superadmin', 'support', 'www'] as const;

/** A slug is 3–40 lowercase letters, digits and single hyphens, starting and ending with a letter or digit. */
export function validateAcademySlug(slug: string): string | null {
  if (slug.length < 3 || slug.length > 40) return 'Use 3 to 40 characters.';
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) return 'Use lowercase letters, digits and single hyphens, starting and ending with a letter or digit.';
  if ((RESERVED_ACADEMY_SLUGS as readonly string[]).includes(slug)) return 'That address is reserved. Choose another.';
  return null;
}

/** A slug from an academy's name: `Saraswati Coaching Centre` → `saraswati-coaching-centre`. */
export const academySlugFrom = (name: string) =>
  name
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40)
    .replace(/-+$/, '');
