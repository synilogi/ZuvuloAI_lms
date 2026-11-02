import type { Plan } from './subscription';
import type { UserProfile } from './identity';

/*
 * Self-serve registration of an academy and its admin (SAAS-026), and the public plan catalogue the company
 * website and the registration wizard show. The API answers in these shapes; the web app and the mobile app read
 * them as they are.
 */

/** `GET /public/plans`: the plans on sale, priced by the server, and the tax the price is charged with. */
export interface PublicPlanCatalogue {
  plans: Plan[];
  /** The platform's home-market tax rule; `inclusive: false` means it is added at checkout. Null when none applies. */
  tax: { name: string; inclusive: boolean; rateBps: number } | null;
}

/** `POST /signup/start`: the organisation and its first admin. The registrant is always the academy's owner admin. */
export interface SignupInput {
  academyName: string;
  /** The academy's address; derived from the name when omitted. */
  slug?: string;
  name: string;
  email: string;
  password: string;
  acceptTerms: true;
  /** The plan chosen first; kept with the registration and offered first on the new plan page — never granted. */
  planId?: string;
  cycle?: 'monthly' | 'annual';
}

/** The plan a registration carries. */
export interface SignupChoice {
  planId: string;
  cycle: 'monthly' | 'annual';
}

/** A registration waiting for the emailed code. */
export interface SignupPending {
  status: 'verify';
  signupId: string;
  email: string;
  expiresAt: string;
  /** Before this, a new code is refused. */
  resendAvailableAt: string;
  choice?: SignupChoice | null;
}

/** The academy exists and its owner is signed in. */
export interface SignupCreated {
  status: 'created';
  token: string;
  user: UserProfile;
  choice?: SignupChoice | null;
}

export type SignupStartResult = SignupPending | SignupCreated;

/** The 6-digit code the verification email carries. */
export const isSignupCode = (code: string) => /^\d{6}$/.test(code.trim());

/*
 * Learners and instructors who register themselves — through an academy's join link, an invitation, a course link or
 * a request to teach — verify their email the same way: nothing exists until the emailed code is confirmed at
 * `POST /public/verifications/verify`.
 */

/** A learner's or instructor's own registration, waiting for the emailed code. */
export interface AccountVerificationPending {
  status: 'verify';
  verificationId: string;
  email: string;
  role: 'student' | 'instructor';
  /** The LMS the account will belong to. */
  lms: string;
  expiresAt: string;
  /** Before this, a new code is refused. */
  resendAvailableAt: string;
}

/** The learner's account exists and is signed in; from a course link, whether they were enrolled and why not. */
export interface AccountCreated {
  status: 'created';
  token: string;
  user: UserProfile;
  enrolled?: boolean;
  enrolment?: string;
  /** Why a course-link sign-up was not enrolled: the API's code. `COURSE_PURCHASE_REQUIRED` sends them on to buy it. */
  enrolmentCode?: string;
}

/** An instructor's verified request waits for the LMS Admin's approval; nobody is signed in. */
export interface InstructorRequestPending {
  status: 'pending';
  message: string;
}

/** What a learner's registration answers: a code to confirm, or — where verification is off — the account itself. */
export type AccountStartResult = AccountVerificationPending | AccountCreated;
