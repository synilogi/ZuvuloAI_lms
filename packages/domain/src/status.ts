/**
 * Canonical LMS states. The API returns these keys; the UI maps each one to a
 * label, icon, tone and shape — state is never communicated by color alone.
 */

export const LMS_STATUSES = [
  'locked',
  'not-enrolled',
  'enrolled',
  'in-progress',
  'completed',
  'upcoming',
  'live',
  'expired',
  'submitted',
  'under-review',
  'passed',
  'failed',
  'eligible',
  'not-eligible',
] as const;

export type LmsStatus = (typeof LMS_STATUSES)[number];

/** Progress state of one lesson or module for one learner. */
export type ProgressState = 'locked' | 'not-started' | 'in-progress' | 'completed';

export function isLmsStatus(value: string): value is LmsStatus {
  return (LMS_STATUSES as readonly string[]).includes(value);
}
