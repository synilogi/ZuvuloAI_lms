/* Provisioning for the platform account.
 *
 * Deliberately not part of `prisma/seed.ts`: the seed clears every table before it writes, so it can
 * never be the way a real Super Admin comes into being. This runs against an existing database and
 * changes nothing but the one row it adds. */
import type { Role } from '@syniastrolms/domain';

import { hashPassword } from './auth.js';
import { db } from './db.js';
import { runAsPlatform } from './tenancy.js';
import { email as emailSchema, z } from './validate.js';

const SUPERADMIN: Role = 'superadmin';

/** Mirrors the rules `POST /auth/register` and `POST /auth/login` apply, so the account can always sign in. */
const inputSchema = z.object({
  email: emailSchema,
  password: z.string().min(8, 'The password must be at least 8 characters.').max(128, 'The password must be at most 128 characters.'),
  name: z.string().trim().min(2, 'The name must be at least 2 characters.').max(120).default('Super Admin'),
  descriptor: z.string().trim().max(120).default('Platform admin'),
});

export interface SuperAdminInput {
  email: string;
  password: string;
  name?: string;
  descriptor?: string;
}

export interface ProvisionedUser {
  id: string;
  email: string;
  name: string;
  role: string;
}

/**
 * - `created`   — the account did not exist and now does.
 * - `unchanged` — it was already there with the superadmin role; nothing was written.
 * - `conflict`  — the address belongs to somebody else's account, which was left exactly as it was.
 */
export type ProvisionResult = { status: 'created' | 'unchanged' | 'conflict'; user: ProvisionedUser };

const provisioned = (user: ProvisionedUser): ProvisionedUser => ({ id: user.id, email: user.email, name: user.name, role: user.role });

/**
 * Creates the Super Admin account, or reports that it is already there. Safe to run repeatedly: the
 * account is identified by its email address, the only unique column on `User`.
 */
export async function provisionSuperAdmin(input: SuperAdminInput): Promise<ProvisionResult> {
  // A platform operation from end to end: the address is checked across every academy (D2), and the
  // account it creates belongs to no academy (D1).
  return runAsPlatform('provisioning the platform super admin', () => provision(input));
}

async function provision(input: SuperAdminInput): Promise<ProvisionResult> {
  const parsed = inputSchema.safeParse(input);
  if (!parsed.success) throw new Error(`Super Admin details are not usable: ${parsed.error.issues.map((i) => i.message).join(' ')}`);
  const { email, password, name, descriptor } = parsed.data;

  const existing = await db.user.findUnique({ where: { email } });
  if (existing) {
    // An address that already belongs to an admin, instructor or learner is refused rather than
    // promoted: this script must never turn somebody else's account into a platform account.
    return { status: existing.role === SUPERADMIN ? 'unchanged' : 'conflict', user: provisioned(existing) };
  }

  // No Student or Instructor row, the same shape the academy admin has: the platform account
  // does not learn and does not teach.
  const user = await db.user.create({
    data: { name, email, passwordHash: await hashPassword(password), role: SUPERADMIN, descriptor },
  });
  return { status: 'created', user: provisioned(user) };
}
