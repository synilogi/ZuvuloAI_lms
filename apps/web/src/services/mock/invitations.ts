import type { InvitationDetails, InvitationRow, InvitationService } from '../contracts';
import { ServiceError } from '../contracts';
import { courseSale } from '@syniastrolms/domain';
import { courses } from './fixtures/catalog';
import { personas } from './fixtures/learner';
import { respond } from './simulation';

/*
 * The demo build's learner invitations and course links. It keeps no accounts: links are held in memory, and joining
 * signs in as the demo learner. Any well-formed link the demo has not seen opens the demo LMS, so a pasted link works;
 * one it made and that was used or withdrawn — or `EXPIRED_DEMO_INVITE` — is refused as the API refuses it.
 */

export const DEMO_LMS = { name: 'ZuviloAI Demo LMS', slug: 'demo' };
/** A well-formed link the demo always treats as expired. */
export const EXPIRED_DEMO_INVITE = '0'.repeat(64);
const DAY = 86_400_000;
const TOKEN = /^[a-f0-9]{64}$/;

const INVALID_MESSAGE = 'This invitation link isn’t valid. It may have expired, been used or been withdrawn — ask your teacher or school for a new one.';
const invalid = () => new ServiceError(INVALID_MESSAGE, 'not-found', 'INVITE_INVALID');

interface Held extends InvitationRow {
  token: string;
}
const held: Held[] = [];
/** Links opened in the demo without being made in it, once used. */
const usedElsewhere = new Set<string>();

const newToken = () => {
  const bytes = new Uint8Array(32);
  globalThis.crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
};

const statusOf = (row: Held, now = Date.now()) =>
  row.usedAt ? 'accepted' : row.status === 'revoked' ? 'revoked' : Date.parse(row.expiresAt) <= now ? 'expired' : 'pending';

const view = (row: Held): InvitationRow => ({
  id: row.id,
  email: row.email,
  status: statusOf(row),
  expiresAt: row.expiresAt,
  createdAt: row.createdAt,
  usedAt: row.usedAt,
});

/** The pending invitation a token names: the demo's own, or a link from elsewhere it has not seen used. */
function usable(token: string): { row?: Held; details: InvitationDetails } {
  if (!TOKEN.test(token) || token === EXPIRED_DEMO_INVITE || usedElsewhere.has(token)) throw invalid();
  const row = held.find((r) => r.token === token);
  if (row && statusOf(row) !== 'pending') throw invalid();
  return {
    row,
    details: {
      lms: DEMO_LMS,
      role: 'student',
      email: row?.email ?? null,
      expiresAt: row?.expiresAt ?? new Date(Date.now() + 7 * DAY).toISOString(),
      open: true,
    },
  };
}

function consume(token: string, row?: Held) {
  if (row) row.usedAt = new Date().toISOString();
  else usedElsewhere.add(token);
}

const learner = (name?: string, email?: string) => ({
  token: 'demo',
  user: { ...personas.student, ...(name ? { name } : {}), ...(email ? { email: email.toLowerCase() } : {}) },
});

function assertAddress(invited: string | null, email: string) {
  if (invited && invited !== email.trim().toLowerCase())
    throw new ServiceError('This invitation is for a different email address. Use the address it was sent to.', 'forbidden');
}

const linkedCourse = (courseId: string) => {
  const course = courses.find((c) => c.id === courseId && c.status === 'published' && c.visibility !== 'private');
  if (!course) throw new ServiceError('Course not found.', 'not-found');
  return course;
};

export const invitationService: InvitationService = {
  describe: (token) => respond(() => usable(token).details),
  register: (token, input) =>
    respond(() => {
      const { row, details } = usable(token);
      assertAddress(details.email, input.email);
      if (input.email.trim().toLowerCase() === personas.admin.email)
        throw new ServiceError('An account with this email already exists.', 'conflict', 'CONFLICT', [
          { field: 'email', message: 'An account with this email already exists.' },
        ]);
      consume(token, row);
      // The demo keeps no inbox: an invitation's account is made at once.
      return { status: 'created' as const, ...learner(input.name.trim(), input.email.trim()) };
    }, 700),
  signIn: (token, input) =>
    respond(() => {
      const { row, details } = usable(token);
      // The demo's staff accounts belong to no learner's invitation.
      if ([personas.admin.email, personas.instructor.email].includes(input.email.trim().toLowerCase()))
        throw new ServiceError(
          'This account belongs to another LMS, so this invitation can’t be used with it. Create a new account with a different email instead.',
          'conflict',
        );
      assertAddress(details.email, input.email);
      consume(token, row);
      return learner(undefined, input.email.trim());
    }, 700),
  courseLink: (courseId) =>
    respond(() => {
      const course = linkedCourse(courseId);
      return { lms: DEMO_LMS, course: { id: course.id, title: course.title, slug: course.slug, sale: courseSale(course) }, open: true };
    }),
  joinCourse: (courseId, input) =>
    respond(() => {
      const course = linkedCourse(courseId);
      // As on the API: a paid course is bought after joining; one with no price chosen is open to nobody yet.
      const sale = courseSale(course);
      const refused =
        sale.kind === 'paid'
          ? { enrolled: false, enrolment: 'This is a paid course. Buy it to start learning.', enrolmentCode: 'COURSE_PURCHASE_REQUIRED' }
          : sale.kind === 'unavailable'
            ? { enrolled: false, enrolment: 'This course isn’t open for enrolment yet. Contact the LMS.', enrolmentCode: 'COURSE_NOT_FOR_SALE' }
            : { enrolled: true };
      return { status: 'created' as const, ...learner(input.name.trim(), input.email.trim()), ...refused };
    }, 700),
  list: () => respond(() => [...held].sort((a, b) => b.createdAt.localeCompare(a.createdAt)).map(view)),
  create: (input) =>
    respond(() => {
      const email = input.email?.trim().toLowerCase() || null;
      if (email && Object.values(personas).some((p) => p.email === email))
        throw new ServiceError('An account with this email already exists.', 'conflict', 'CONFLICT', [
          { field: 'email', message: 'An account with this email already exists.' },
        ]);
      const now = Date.now();
      const row: Held = {
        id: `inv-${held.length + 1}`,
        token: newToken(),
        email,
        status: 'pending',
        createdAt: new Date(now + held.length).toISOString(),
        expiresAt: new Date(now + 7 * DAY).toISOString(),
        usedAt: null,
      };
      held.push(row);
      return { invitation: view(row), url: `${window.location.origin}/invite/${row.token}` };
    }, 500),
  revoke: (id) =>
    respond(() => {
      const row = held.find((r) => r.id === id);
      if (!row) throw new ServiceError('Invitation not found.', 'not-found');
      if (row.usedAt) throw new ServiceError('This invitation has already been accepted.', 'conflict');
      row.status = 'revoked';
      return view(row);
    }),
};
