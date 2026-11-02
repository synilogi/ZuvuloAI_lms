import { publicAffiliateProgram, publicSiteContent } from '../lib/siteContent.js';
import { getPublicBundle, listPublicBundles } from '../lib/bundles.js';
import { countPageView, isBot } from '../lib/siteMetrics.js';
import { observe } from '../lib/observe.js';
import { getPublicPost, listPublicPosts, publicMentor, publicMentors, publicStats, sendPublicImage } from '../lib/sitePublic.js';
import { Router } from 'express';
import { referralQrSvg, resolveReferral } from '../lib/mlm/affiliates.js';

import { BLOG_KINDS, INQUIRY_KINDS } from '@syniastrolms/domain';

import { asyncHandler } from '../lib/errors.js';
import { ApiError } from '../lib/errors.js';
import { acceptWithNewAccount, acceptWithSignIn, describeCourseLink, describeInvitation, joinFromCourseLink } from '../lib/invitations.js';
import { assertSelfRegistrationOpen, registerLearner, registerLearnerAt, workspaceAt } from '../lib/learners.js';
import {
  confirmVerification,
  resendVerification,
  startCourseRegistration,
  startHostRegistration,
  startInstructorApplication,
  startInstructorRegistration,
  startInvitationRegistration,
  startJoinRegistration,
  verificationStatus,
} from '../lib/pendingAccounts.js';
import { emailVerificationRequired } from '../lib/registration.js';
import { selfEnrol } from './learning.js';
import { startSession } from '../lib/sessions.js';
import { getSettings } from '../lib/settings.js';
import { toProfile } from './auth.js';
import { createPublicInquiry } from '../lib/inquiries.js';
import { runInTenant } from '../lib/tenancy.js';
import { email, optionalEnum, parseBody, parseQuery, phoneNumber, z } from '../lib/validate.js';
import { applyToTeach, PENDING_MESSAGE, requestInstructorAccess } from '../lib/instructorRequests.js';
import { publicBrandingRouter } from './branding.js';

/*
 * `/public` — what the website shows a visitor, and the doors through which people register. Anonymous; every
 * request runs in the platform's one workspace (docs/16, D-PLAT-01).
 */
export const publicSiteRouter = Router();

// The platform's logo and favicon, as every page reads them. Read-only; the Super Admin's router is what changes them.
publicSiteRouter.use('/branding', publicBrandingRouter);

const optionalText = (max: number) => z.string().trim().max(max).optional();

const inquirySchema = z.object({
  kind: z.enum(INQUIRY_KINDS),
  name: z.string().trim().min(2, 'Enter your name.').max(120),
  email,
  organisation: optionalText(160),
  phone: z
    .string()
    .trim()
    .max(32)
    .regex(/^[+()\d\s-]*$/, 'Enter a phone number with digits, spaces, + ( ) or -.')
    .optional(),
  size: optionalText(60),
  message: z.string().trim().min(10, 'Tell us a little more — at least 10 characters.').max(4000),
  /** A field people never see: a form that fills it is a bot's, and is accepted without being stored. */
  website: z.string().max(200).optional(),
});

/**
 * The contact form: a demo, a sales conversation or support (SAAS-027). Stored for the Super Admin's inbox and, where
 * `SALES_NOTIFY_EMAIL` is set, emailed to the team. Rate limited in `app.ts`.
 */
publicSiteRouter.post(
  '/inquiries',
  asyncHandler(async (req, res) => {
    const { website, ...input } = parseBody(req, inquirySchema);
    if (website) {
      // The honeypot: answer as if stored, so the bot learns nothing.
      res.status(201).json({ received: true });
      return;
    }
    await createPublicInquiry(input);
    res.status(201).json({ received: true });
  }),
);

/*
 * An academy's public join page (SAAS-028, D29). The address in the path chooses which academy's door a visitor is
 * at — the same choice a host name makes — and nothing else: it grants no access to the academy, and a learner who
 * joins belongs to that academy only. Archived academies do not exist here; a suspended one takes nobody new.
 */

publicSiteRouter.get(
  '/academies/:slug',
  asyncHandler(async (req, res) => {
    const academy = await workspaceAt(req.params.slug);
    const { general } = await runInTenant(academy.id, () => getSettings());
    // `invitationOnly`: the academy adds learners by invitation (its enrolment policy), so its join link takes none —
    // instructors may still ask to teach there.
    res.json({
      name: general.academyName || academy.name,
      slug: academy.slug,
      open: academy.status === 'active',
      invitationOnly: general.enrollment === 'invite',
    });
  }),
);

/*
 * The platform's registration doors (docs/16, D-PLAT-06). The account always joins the one workspace, as a learner or a
 * pending instructor: nothing in the body chooses either. With verification on (the default) nothing exists until
 * `POST /public/verifications/verify` confirms the emailed code.
 */
const registerSchema = z.object({
  name: z.string().trim().min(2, 'Enter your full name.').max(120),
  email,
  phone: phoneNumber,
  password: z.string().min(8, 'Password must be at least 8 characters.').max(128),
  referralCode: z.string().trim().max(16).optional(),
  preferredLeg: z.enum(['A', 'B']).optional(),
  requestedLeg: z.enum(['A', 'B']).optional(),
});

publicSiteRouter.post(
  '/register',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, registerSchema);
    if (emailVerificationRequired()) return void res.status(202).json(await startHostRegistration(input));
    await assertSelfRegistrationOpen();
    const user = await registerLearner(input);
    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    res.status(201).json({ status: 'created', token, user: toProfile(user) });
  }),
);

const httpLink = z
  .string()
  .trim()
  .max(300)
  .regex(/^https?:\/\/\S+$/i, 'Each link must start with http:// or https://.');

const applicationSchema = z.object({
  name: z.string().trim().min(2, 'Enter your full name.').max(120),
  email,
  phone: phoneNumber,
  password: z.string().min(8, 'Password must be at least 8 characters.').max(128),
  title: z.string().trim().min(2, 'Say what you teach, in a few words.').max(120),
  bio: z.string().trim().min(30, 'Tell us about your teaching, in at least 30 characters.').max(2000),
  expertise: z.array(z.string().trim().min(1).max(60)).min(1, 'Name at least one subject.').max(12),
  yearsTeaching: z.number().int().min(0, 'Enter your years of experience.').max(70),
  links: z.array(httpLink).max(5).default([]),
});

publicSiteRouter.post(
  '/instructor-applications',
  asyncHandler(async (req, res) => {
    const { bio, expertise, yearsTeaching, links, ...person } = parseBody(req, applicationSchema);
    const profile = { bio, expertise, yearsTeaching, links };
    if (emailVerificationRequired()) return void res.status(202).json(await startInstructorApplication({ ...person, profile }));
    await applyToTeach({ ...person, profile });
    res.status(202).json({ status: 'pending', message: PENDING_MESSAGE });
  }),
);

const joinSchema = z.object({
  name: z.string().trim().min(2, 'Enter your full name.').max(120),
  email,
  password: z.string().min(8, 'Password must be at least 8 characters.').max(128),
  // An affiliate referral (MLM-001): the sponsor's code and leg from the link, and the learner's own preference for their referrals.
  referralCode: z.string().trim().max(16).optional(),
  preferredLeg: z.enum(['A', 'B']).optional(),
  requestedLeg: z.enum(['A', 'B']).optional(),
});

/**
 * A learner signs up into the academy the link names — counted against its plan, like every other way in. With email
 * verification on (the default) nothing is created yet: the answer is `202 { status: 'verify', verificationId, … }`
 * and the account is made by `POST /public/verifications/verify`.
 */
/*
 * A referral link (`/ref/<code>`, MLM-001): who shared it, which LMS it joins, whether the program is running, and
 * the link as a QR. The code alone is the credential; a malformed, unknown or terminated one is the same 404.
 */
/** The website's editable words (docs/16 §2.6). */
publicSiteRouter.get(
  '/site',
  asyncHandler(async (_req, res) => {
    res.json(await publicSiteContent());
  }),
);

/** One view of a public page. Answers the same whatever happened: a visitor's page never waits on or learns from this. */
publicSiteRouter.post(
  '/metrics',
  asyncHandler(async (req, res) => {
    const { path } = parseBody(req, z.object({ path: z.string().max(300) }));
    if (!isBot(req.get('user-agent'))) await countPageView(path).catch(() => undefined);
    res.status(204).end();
  }),
);

/** An error in a visitor's browser, so a page broken for someone reaches the Super Admin's system view instead of nobody. */
publicSiteRouter.post(
  '/client-errors',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ message: z.string().max(500), source: z.string().max(300).optional(), path: z.string().max(300).optional() }));
    if (!isBot(req.get('user-agent'))) observe('client.error', input);
    res.status(204).end();
  }),
);

/** The home page's figures, counted from the records. */
publicSiteRouter.get(
  '/stats',
  asyncHandler(async (_req, res) => {
    res.json(await publicStats());
  }),
);

publicSiteRouter.get(
  '/mentors',
  asyncHandler(async (_req, res) => {
    res.json(await publicMentors());
  }),
);

publicSiteRouter.get(
  '/mentors/:id',
  asyncHandler(async (req, res) => {
    res.json(await publicMentor(req.params.id));
  }),
);

publicSiteRouter.get(
  '/bundles',
  asyncHandler(async (_req, res) => {
    res.json(await listPublicBundles());
  }),
);

publicSiteRouter.get(
  '/bundles/:slug',
  asyncHandler(async (req, res) => {
    res.json(await getPublicBundle(req.params.slug));
  }),
);

publicSiteRouter.get(
  '/posts',
  asyncHandler(async (req, res) => {
    const { kind } = parseQuery(req, z.object({ kind: optionalEnum(BLOG_KINDS) }));
    res.json(await listPublicPosts(kind));
  }),
);

publicSiteRouter.get(
  '/posts/:slug',
  asyncHandler(async (req, res) => {
    res.json(await getPublicPost(req.params.slug));
  }),
);

/** An image placed on the website, or an active instructor's photo. Any other upload is the same 404. */
publicSiteRouter.get(
  '/images/:mediaId',
  asyncHandler(async (req, res) => {
    await sendPublicImage(req.params.mediaId, res);
  }),
);

/** The affiliate program's published terms, from the active plan. */
publicSiteRouter.get(
  '/affiliate-program',
  asyncHandler(async (_req, res) => {
    res.json(await publicAffiliateProgram());
  }),
);

publicSiteRouter.get(
  '/affiliates/ref/:code',
  asyncHandler(async (req, res) => {
    res.json(await resolveReferral(req.params.code));
  }),
);

publicSiteRouter.get(
  '/affiliates/ref/:code/qr.svg',
  asyncHandler(async (req, res) => {
    const svg = await referralQrSvg(req.params.code);
    res.type('image/svg+xml').set('Cache-Control', 'public, max-age=86400').send(svg);
  }),
);

publicSiteRouter.post(
  '/academies/:slug/register',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, joinSchema);
    if (emailVerificationRequired()) return void res.status(202).json(await startJoinRegistration(req.params.slug, input));
    const user = await registerLearnerAt(req.params.slug, input);
    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    res.status(201).json({ token, user: toProfile(user) });
  }),
);

const instructorRequestSchema = joinSchema.extend({ title: z.string().trim().max(120).optional() });

/**
 * A visitor asks to teach in the academy the link names (D34). The account is created pending the academy admin's
 * approval: no session is started, and sign-in refuses it until then. The academy is the link's, never the body's.
 */
publicSiteRouter.post(
  '/academies/:slug/instructor-requests',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, instructorRequestSchema);
    if (emailVerificationRequired()) return void res.status(202).json(await startInstructorRegistration(req.params.slug, input));
    await requestInstructorAccess(req.params.slug, input);
    res.status(202).json({ status: 'pending', message: PENDING_MESSAGE });
  }),
);

/*
 * A learner invitation (`/invite/<token>`). The token alone names the Admin's workspace and the role; the visitor
 * creates an account there or signs in with the one they already have there. Refused alike when the link is
 * malformed, unknown, used, withdrawn or expired.
 */

publicSiteRouter.get(
  '/invitations/:token',
  asyncHandler(async (req, res) => {
    res.json(await describeInvitation(req.params.token));
  }),
);

publicSiteRouter.post(
  '/invitations/:token/register',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, joinSchema);
    if (emailVerificationRequired()) return void res.status(202).json(await startInvitationRegistration(req.params.token, input));
    const user = await acceptWithNewAccount(req.params.token, input);
    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    res.status(201).json({ token, user: toProfile(user) });
  }),
);

publicSiteRouter.post(
  '/invitations/:token/sign-in',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ email, password: z.string().min(1, 'Enter your email and password.').max(128) }));
    const user = await acceptWithSignIn(req.params.token, input);
    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    res.json({ token, user: toProfile(user) });
  }),
);

/*
 * A course link (`/courses/<course-id>/enroll`): the course names the Admin's LMS. A new learner joins that LMS and is
 * enrolled when its policy lets learners enrol themselves. A signed-in learner enrols through
 * `POST /learning/courses/:courseId/enroll`, which finds only their own LMS's courses.
 */

publicSiteRouter.get(
  '/courses/:courseId/enroll',
  asyncHandler(async (req, res) => {
    res.json(await describeCourseLink(req.params.courseId));
  }),
);

publicSiteRouter.post(
  '/courses/:courseId/enroll',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, joinSchema);
    if (emailVerificationRequired()) return void res.status(202).json(await startCourseRegistration(req.params.courseId, input));
    const { user, tenantId, courseId } = await joinFromCourseLink(req.params.courseId, input);
    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    res.status(201).json({ token, user: toProfile(user), ...(await enrolFromLink(user.student!.id, tenantId, courseId)) });
  }),
);

/** Enrols a learner who joined from a course link, under the LMS's policy; the learner is told why not. */
async function enrolFromLink(studentId: string, tenantId: string, courseId: string) {
  try {
    await runInTenant(tenantId, () => selfEnrol(studentId, courseId));
    return { enrolled: true };
  } catch (err) {
    // The account is made either way; the LMS's own policy decides the enrolment.
    if (!(err instanceof ApiError) || err.status >= 500) throw err;
    // `enrolmentCode` tells the client why: COURSE_PURCHASE_REQUIRED sends the new learner on to buy the course.
    return { enrolled: false, enrolment: err.message, ...(err.code ? { enrolmentCode: err.code } : {}) };
  }
}

/*
 * Email verification for learners and instructors who register themselves (`lib/pendingAccounts.ts`). The id names a
 * registration the server holds in the academy its link named; nothing here can choose an academy, a role, an
 * invitation or a course. Rate limited in `app.ts`, and each registration allows a few wrong codes and a few resends.
 */

const verificationId = z.string().trim().min(1).max(64);

publicSiteRouter.get(
  '/verifications/:id',
  asyncHandler(async (req, res) => {
    // Any id that names no open registration — malformed ones included — is the same 404.
    res.json(await verificationStatus(req.params.id.slice(0, 64)));
  }),
);

publicSiteRouter.post(
  '/verifications/resend',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ verificationId }));
    res.json(await resendVerification(input.verificationId));
  }),
);

/**
 * Confirms the code. A learner's account is created and signed in (and enrolled, for a course link, under the LMS's
 * policy): `201 { status: 'created', token, user }`. An instructor's request reaches the academy's admins and nobody is
 * signed in: `202 { status: 'pending', message }`.
 */
publicSiteRouter.post(
  '/verifications/verify',
  asyncHandler(async (req, res) => {
    const input = parseBody(
      req,
      z.object({
        verificationId,
        code: z
          .string()
          .trim()
          .regex(/^\d{6}$/, 'Enter the 6-digit code from the email.'),
      }),
    );
    const result = await confirmVerification(input.verificationId, input.code);
    if (result.role === 'instructor') return void res.status(202).json({ status: 'pending', message: PENDING_MESSAGE });
    const { user } = result;
    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    const enrolment = result.courseId ? await enrolFromLink(user.student!.id, result.tenantId, result.courseId) : {};
    res.status(201).json({ status: 'created', token, user: toProfile(user), ...enrolment });
  }),
);
