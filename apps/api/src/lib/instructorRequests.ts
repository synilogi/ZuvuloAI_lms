import { ApiError, conflict, notFound } from './errors.js';
import { db } from './db.js';
import { hashPassword } from './auth.js';
import { readJson, writeJson } from './json.js';
import { workspaceAt } from './learners.js';
import { workspaceId } from './requestContext.js';
import { APP_URL, queueEmail } from './mail.js';
import { notifyMany } from './notify.js';
import { getSettings } from './settings.js';
import { runAsPlatform, runInTenant, tenant } from './tenancy.js';

/*
 * Instructor self-registration (D34). A person asks to teach in the academy a join link names; the account exists at
 * once, as an ordinary instructor account — but with its instructor profile `pending`, which sign-in and every request
 * refuse (`routes/auth.ts`, `lib/requestContext.ts`), until an academy admin approves it. The academy is the link's,
 * never one the visitor names; approving and refusing are the academy's own admins', inside its own tenant.
 */

/** An instructor profile still waiting on the academy, or refused by it — not one of its staff. */
export const REQUEST_STATUSES = ['pending', 'rejected'] as const;
export type InstructorRequestStatus = (typeof REQUEST_STATUSES)[number];
export const isRequestStatus = (status: string): status is InstructorRequestStatus => (REQUEST_STATUSES as readonly string[]).includes(status);

/** A Prisma filter for the academy's actual staff: every instructor that is not a request. */
export const STAFF_ONLY = { status: { notIn: [...REQUEST_STATUSES] } };

export const PENDING_MESSAGE = 'Your instructor application is being reviewed. You will be able to sign in once it is approved.';
export const REJECTED_MESSAGE = 'Your instructor application was not approved. Contact support for help.';

/** Why an instructor account may not sign in or act yet, with its stable code; `undefined` when it may. */
export function instructorRequestRefusal(status: string | undefined): ApiError | undefined {
  if (status === 'pending') return new ApiError(403, PENDING_MESSAGE, undefined, 'INSTRUCTOR_PENDING');
  if (status === 'rejected') return new ApiError(403, REJECTED_MESSAGE, undefined, 'INSTRUCTOR_REJECTED');
  return undefined;
}

const emailInUse = (email: string) =>
  runAsPlatform('an email address is unique across the platform (D2)', async () =>
    Boolean(
      (await db.user.findUnique({ where: { email }, select: { id: true } })) ?? (await db.instructor.findFirst({ where: { email }, select: { id: true } })),
    ),
  );

const TAKEN = 'An account with this email already exists.';

/** What an applicant tells the platform about themselves (docs/16 §2.5). */
export interface InstructorProfileInput {
  bio: string;
  expertise: string[];
  yearsTeaching: number;
  links: string[];
}

export interface InstructorRequestInput {
  name: string;
  email: string;
  password: string;
  title?: string;
}

/**
 * A visitor asks to teach in the academy at [slug]. Creates the account and its `pending` profile; signs nobody in.
 * Takes no seat on the plan until approved. The academy's admins are told, and the visitor gets a confirmation.
 */
export async function requestInstructorAccess(slug: string, input: InstructorRequestInput) {
  const workspace = await instructorWorkspaceAt(slug);
  const email = input.email.trim().toLowerCase();
  await assertInstructorEmailFree(email);
  return createInstructorRequest(workspace, { name: input.name, email, title: input.title, passwordHash: await hashPassword(input.password) });
}

/** An instructor applying on the website, where email verification is off: the same account, pending approval. */
export async function applyToTeach(input: InstructorRequestInput & { phone: string; profile: InstructorProfileInput }) {
  const email = input.email.trim().toLowerCase();
  await assertInstructorEmailFree(email);
  const id = await workspaceId();
  const workspace = await runAsPlatform('an application names the workspace', () =>
    db.tenant.findUniqueOrThrow({ where: { id }, select: { id: true, name: true } }),
  );
  return createInstructorRequest(workspace, {
    name: input.name,
    email,
    title: input.title,
    passwordHash: await hashPassword(input.password),
    phone: input.phone,
    profile: input.profile,
  });
}

/** The workspace a join link names, when it takes instructor requests: refused while it is suspended. */
export async function instructorWorkspaceAt(slug: string) {
  const workspace = await workspaceAt(slug);
  if (workspace.status !== 'active')
    throw new ApiError(403, 'The platform isn’t accepting new instructors right now. Contact support for help.', undefined, 'ACADEMY_SUSPENDED');
  return workspace;
}

/** Refuses an address that already has an account, or an instructor profile, anywhere on the platform (D2). */
export async function assertInstructorEmailFree(email: string) {
  if (await emailInUse(email)) throw conflict(TAKEN, [{ field: 'email', message: TAKEN }]);
}

/**
 * Creates the account and its `pending` profile in [workspace], with a password already hashed — straight from the
 * form, or from a registration whose email was just verified (`lib/pendingAccounts.ts`).
 */
export async function createInstructorRequest(
  workspace: { id: string; name: string },
  input: { name: string; email: string; title?: string | null; passwordHash: string; phone?: string | null; profile?: InstructorProfileInput },
) {
  const email = input.email.trim().toLowerCase();
  const name = input.name.trim();
  const title = input.title?.trim() || 'Instructor';
  const passwordHash = input.passwordHash;

  return runInTenant(workspace.id, async () => {
    let created: { userId: string; instructorId: string };
    try {
      // As adding an instructor does (`routes/instructors.ts`): the profile, then its account. The tenancy layer checks
      // the account's profile exists, so the two are not one transaction; a failed account removes its profile.
      const instructor = await db.instructor.create({
        data: {
          ...tenant(),
          name,
          title,
          email,
          status: 'pending',
          phone: input.phone || null,
          ...(input.profile
            ? {
                bio: input.profile.bio,
                expertiseJson: writeJson(input.profile.expertise),
                yearsTeaching: input.profile.yearsTeaching,
                linksJson: writeJson(input.profile.links),
              }
            : {}),
        },
        select: { id: true },
      });
      try {
        const user = await db.user.create({
          data: { ...tenant(), name, email, passwordHash, phone: input.phone || null, role: 'instructor', descriptor: title, instructorId: instructor.id },
          select: { id: true },
        });
        created = { userId: user.id, instructorId: instructor.id };
      } catch (err) {
        await db.instructor.delete({ where: { id: instructor.id } });
        throw err;
      }
    } catch (err) {
      // The same address asked twice at once: the unique index let one through.
      if ((err as { code?: string }).code === 'P2002') throw conflict(TAKEN, [{ field: 'email', message: TAKEN }]);
      throw err;
    }

    const { general } = await getSettings();
    const lms = general.academyName || workspace.name;
    await queueEmail({
      to: email,
      name,
      subject: `Your application to teach on ${lms} is being reviewed`,
      templateKey: 'instructor-request-received',
      text: [
        `Hi ${name.split(' ')[0]},`,
        '',
        `Thank you for applying to teach on ${lms}. Your application is being reviewed.`,
        'We will email you as soon as it is approved; you can then sign in with this email address and the password you chose.',
        '',
        'If you did not register, you can ignore this email.',
      ].join('\n'),
    });
    // Staff admins of the workspace, and the platform's owner, who has no tenant (docs/16, D-PLAT-03).
    const admins = await runAsPlatform('an application is announced to staff and the owner', () =>
      db.user.findMany({ where: { deactivatedAt: null, OR: [{ role: 'admin', tenantId: workspace.id }, { role: 'superadmin' }] }, select: { id: true } }),
    );
    await notifyMany(
      admins.map((a) => a.id),
      {
        category: 'system',
        title: 'New instructor application',
        summary: `${name} (${email}) applied to teach on ${lms}. Approve or reject the application.`,
        important: true,
        action: { label: 'Review application', to: '/admin/instructors?tab=requests' },
      },
    );
    return { status: 'pending' as const, ...created };
  });
}

/** The academy's instructor requests, newest first: pending by default, or the refused ones. */
export async function listInstructorRequests(status: InstructorRequestStatus = 'pending') {
  const rows = await db.instructor.findMany({
    where: { status },
    orderBy: { joinedAt: 'desc' },
    select: {
      id: true,
      name: true,
      email: true,
      title: true,
      status: true,
      joinedAt: true,
      phone: true,
      bio: true,
      expertiseJson: true,
      yearsTeaching: true,
      linksJson: true,
    },
  });
  const { general } = await getSettings();
  return rows.map((r) => ({
    id: r.id,
    name: r.name,
    email: r.email,
    title: r.title,
    status: r.status,
    requestedAt: r.joinedAt.toISOString(),
    lms: general.academyName,
    phone: r.phone ?? undefined,
    bio: r.bio,
    expertise: readJson<string[]>(r.expertiseJson, []),
    yearsTeaching: r.yearsTeaching ?? undefined,
    links: readJson<string[]>(r.linksJson, []),
  }));
}

async function requestRow(id: string) {
  // The tenancy layer scopes this read to the signed-in admin's academy: another academy's request is not found.
  const row = await db.instructor.findUnique({ where: { id }, select: { id: true, name: true, email: true, status: true } });
  if (!row || !isRequestStatus(row.status)) throw notFound('Instructor request not found.');
  return row;
}

/**
 * Approves a request: the instructor becomes active staff and may sign in. Takes a seat on the plan, inside the plan's
 * limit (refused when the academy is full or restricted). A refused request may still be approved later.
 */
export async function approveInstructorRequest(id: string) {
  const row = await requestRow(id);
  const moved = await db.$transaction((tx) =>
    tx.instructor.updateMany({ where: { id, status: row.status }, data: { status: 'active', joinedAt: new Date() } }),
  );
  if (moved.count !== 1) throw conflict('This request changed while it was being approved. Reload and try again.');
  const { general } = await getSettings();
  await queueEmail({
    to: row.email,
    name: row.name,
    subject: `You can now teach at ${general.academyName}`,
    templateKey: 'instructor-request-approved',
    text: [
      `Hi ${row.name.split(' ')[0]},`,
      '',
      `Your instructor account at ${general.academyName} has been approved. Sign in with this email address and the password you chose:`,
      `${APP_URL}/login`,
    ].join('\n'),
  });
  return { ...row, status: 'active' as const };
}

/** Refuses a pending request: the account stays, but can never sign in unless an admin approves it later. */
export async function rejectInstructorRequest(id: string) {
  const row = await requestRow(id);
  if (row.status !== 'pending') throw conflict('Only a pending request can be rejected.');
  const moved = await db.instructor.updateMany({ where: { id, status: 'pending' }, data: { status: 'rejected' } });
  if (moved.count !== 1) throw conflict('This request changed while it was being rejected. Reload and try again.');
  const { general } = await getSettings();
  await queueEmail({
    to: row.email,
    name: row.name,
    subject: `Your request to teach at ${general.academyName}`,
    templateKey: 'instructor-request-rejected',
    text: [
      `Hi ${row.name.split(' ')[0]},`,
      '',
      `Your request to teach at ${general.academyName} was not approved by the platform team. If you think this is a mistake, contact support.`,
    ].join('\n'),
  });
  return { ...row, status: 'rejected' as const };
}
