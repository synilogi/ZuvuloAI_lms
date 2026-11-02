/**
 * Academy admin permissions.
 *
 * These govern the `admin` role only. Instructors keep the role-and-scope authorization they have
 * always had, and the platform `superadmin` is outside this system entirely — its reach is defined
 * by the `/superadmin` router, never by a grant.
 *
 * Keys are code, grants are data: the catalogue below is the single source of truth, and the
 * database stores only which keys a given admin holds.
 */

export type PermissionGroup = 'catalog' | 'assessment' | 'learners' | 'instructors' | 'certification' | 'live' | 'insight' | 'settings';

export type PermissionKey =
  | 'catalog.view'
  | 'catalog.edit'
  | 'catalog.publish'
  | 'catalog.archive'
  | 'catalog.categories.manage'
  | 'assessment.view'
  | 'assessment.edit'
  | 'assessment.grade'
  | 'learners.view'
  | 'learners.enroll'
  | 'learners.suspend'
  | 'learners.message'
  | 'instructors.view'
  | 'instructors.manage'
  | 'instructors.status'
  | 'certificates.issue'
  | 'certificates.revoke'
  | 'certificates.templates.manage'
  | 'live.manage'
  | 'live.notify'
  | 'reports.view'
  | 'reports.instructors.view'
  | 'settings.view'
  | 'settings.edit';

export interface PermissionMeta {
  group: PermissionGroup;
  /** Short name for a checkbox. */
  label: string;
  /** What holding it lets the admin do, in the words of the person granting it. */
  description: string;
}

/**
 * Every configurable permission. Exhaustive over `PermissionKey`, so a key without a description
 * cannot compile — the catalogue and the union can never drift apart.
 */
export const PERMISSIONS: Record<PermissionKey, PermissionMeta> = {
  'catalog.view': { group: 'catalog', label: 'View courses', description: 'See courses, chapters and lessons, and the media inside them.' },
  'catalog.edit': { group: 'catalog', label: 'Edit courses', description: 'Create and change courses, chapters and lessons.' },
  'catalog.publish': { group: 'catalog', label: 'Publish courses', description: 'Put a course in front of learners, or take it back off.' },
  'catalog.archive': {
    group: 'catalog',
    label: 'Archive courses',
    description: 'Archive a course or restore one, including courses learners are enrolled in.',
  },
  'catalog.categories.manage': { group: 'catalog', label: 'Manage categories', description: 'Shape the catalogue: create, rename and remove categories.' },

  'assessment.view': { group: 'assessment', label: 'View assessments', description: 'See quizzes, assignments and what learners have handed in.' },
  'assessment.edit': { group: 'assessment', label: 'Edit assessments', description: 'Create and change quizzes and assignments.' },
  'assessment.grade': { group: 'assessment', label: 'Grade submissions', description: 'Review hand-ins and set the marks that count towards a certificate.' },

  'learners.view': { group: 'learners', label: 'View learners', description: 'See the learner directory, profiles, progress and activity.' },
  'learners.enroll': {
    group: 'learners',
    label: 'Add and enrol learners',
    description: 'Add a learner to the academy, enrol a learner in a course, change an enrolment or end one.',
  },
  'learners.suspend': { group: 'learners', label: 'Suspend learners', description: 'Suspend a learner account, or lift a suspension.' },
  'learners.message': { group: 'learners', label: 'Message learners', description: 'Send a message to learners in the academy’s name.' },

  'instructors.view': { group: 'instructors', label: 'View instructors', description: 'See the instructor directory and each profile.' },
  'instructors.manage': {
    group: 'instructors',
    label: 'Manage instructors',
    description: 'Invite an instructor — which creates their sign-in — and edit their details.',
  },
  'instructors.status': {
    group: 'instructors',
    label: 'Activate instructors',
    description: 'Deactivate an instructor, ending their access, or reactivate one.',
  },

  'certificates.issue': { group: 'certification', label: 'Issue certificates', description: 'Issue a credential the academy vouches for.' },
  'certificates.revoke': { group: 'certification', label: 'Revoke certificates', description: 'Revoke an issued credential, or restore a revoked one.' },
  'certificates.templates.manage': {
    group: 'certification',
    label: 'Manage certificate templates',
    description: 'Design the templates every credential is issued from, and choose the default.',
  },

  'live.manage': { group: 'live', label: 'Manage live classes', description: 'Schedule, change and cancel live classes.' },
  'live.notify': { group: 'live', label: 'Send live reminders', description: 'Send reminders about a live class to everyone registered.' },

  'reports.view': { group: 'insight', label: 'View reports', description: 'Read the dashboard and the course, learner and enrolment reports.' },
  'reports.instructors.view': {
    group: 'insight',
    label: 'View instructor performance',
    description: 'Read the report covering how each instructor’s courses are doing.',
  },

  'settings.view': { group: 'settings', label: 'View settings', description: 'Read the academy’s settings.' },
  'settings.edit': { group: 'settings', label: 'Edit settings', description: 'Change the academy’s settings, including branding and learning rules.' },
};

/** Every configurable key, in catalogue order. */
export const PERMISSION_KEYS = Object.keys(PERMISSIONS) as PermissionKey[];

export const PERMISSION_GROUPS: PermissionGroup[] = ['catalog', 'assessment', 'learners', 'instructors', 'certification', 'live', 'insight', 'settings'];

export const PERMISSION_GROUP_LABEL: Record<PermissionGroup, string> = {
  catalog: 'Catalog',
  assessment: 'Assessment',
  learners: 'Learners',
  instructors: 'Instructors',
  certification: 'Certification',
  live: 'Live classes',
  insight: 'Insight',
  settings: 'Academy settings',
};

/** Narrows a value read from the database, where a key is only ever a string. */
export const isPermissionKey = (value: string): value is PermissionKey => Object.prototype.hasOwnProperty.call(PERMISSIONS, value);

/** The catalogue's keys for one group, in catalogue order. */
export const permissionsInGroup = (group: PermissionGroup): PermissionKey[] => PERMISSION_KEYS.filter((key) => PERMISSIONS[key].group === group);
