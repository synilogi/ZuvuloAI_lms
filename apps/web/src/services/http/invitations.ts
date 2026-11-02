import type { CourseLinkDetails, InvitationDetails, InvitationRow, InvitationService, LearnerSession } from '../contracts';
import type { AccountStartResult } from '@syniastrolms/domain';

import { get, post } from './client';
import { asAccountStart } from './signup';

const at = (token: string) => `/public/invitations/${encodeURIComponent(token)}`;
const course = (courseId: string) => `/public/courses/${encodeURIComponent(courseId)}/enroll`;

/** Learner invitations and course links, against `/public/invitations`, `/public/courses/:id/enroll` and `/invitations`. */
export const httpInvitations: InvitationService = {
  describe: (token) => get<InvitationDetails>(at(token)),
  register: (token, input) => post<AccountStartResult>(`${at(token)}/register`, input).then(asAccountStart),
  signIn: (token, input) => post<LearnerSession>(`${at(token)}/sign-in`, input),
  courseLink: (courseId) => get<CourseLinkDetails>(course(courseId)),
  joinCourse: (courseId, input) => post<AccountStartResult>(course(courseId), input).then(asAccountStart),
  list: () => get<{ rows: InvitationRow[] }>('/invitations').then((r) => r.rows),
  create: (input) => post<{ invitation: InvitationRow; url: string }>('/invitations', input.email ? { email: input.email } : {}),
  revoke: (id) => post<InvitationRow>(`/invitations/${encodeURIComponent(id)}/revoke`),
};
