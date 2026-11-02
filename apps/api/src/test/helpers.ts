/* Shared helpers for API integration tests. `npm test` prepares `prisma/test.db` (migrations + seed)
 * before Vitest starts, so every suite runs against the same seeded academy. */
import request, { type Test } from 'supertest';

import { createApp } from '../app.js';

export const app = createApp();

export const PASSWORD = 'syniastrolms123';

/** Seeded accounts (see prisma/seed.ts). */
export const ACCOUNTS = {
  admin: 'admin@syniastrolms.test',
  instructor: 'meenakshi@syniastrolms.test',
  instructor2: 'vinod@syniastrolms.test',
  student: 'ananya@syniastrolms.test',
  student2: 'rohit@syniastrolms.test',
  student3: 'priya@syniastrolms.test',
} as const;

export type Account = keyof typeof ACCOUNTS;

const tokens = new Map<string, string>();

export async function tokenFor(account: Account | { email: string; password?: string }): Promise<string> {
  const email = typeof account === 'string' ? ACCOUNTS[account] : account.email;
  const password = typeof account === 'string' ? PASSWORD : (account.password ?? PASSWORD);
  const cached = tokens.get(email);
  if (cached) return cached;
  const res = await request(app).post('/auth/login').send({ email, password });
  if (res.status !== 200) throw new Error(`Could not sign in as ${email}: ${res.status} ${JSON.stringify(res.body)}`);
  tokens.set(email, res.body.token as string);
  return res.body.token as string;
}

export interface Client {
  get(path: string, query?: Record<string, unknown>): Test;
  post(path: string, body?: unknown): Test;
  patch(path: string, body?: unknown): Test;
  put(path: string, body?: unknown): Test;
  delete(path: string): Test;
  /** A POST without a JSON body, for multipart uploads (`.attach(...)`). */
  upload(path: string): Test;
  token: string;
}

/** A supertest client that sends the account's bearer token with every request. */
export async function as(account: Account | { email: string; password?: string }): Promise<Client> {
  const token = await tokenFor(account);
  const auth = (t: Test) => t.set('Authorization', `Bearer ${token}`);
  return {
    token,
    get: (path, query) =>
      auth(
        request(app)
          .get(path)
          .query(query ?? {}),
      ),
    post: (path, body) =>
      auth(
        request(app)
          .post(path)
          .send(body ?? {}),
      ),
    patch: (path, body) =>
      auth(
        request(app)
          .patch(path)
          .send(body ?? {}),
      ),
    put: (path, body) =>
      auth(
        request(app)
          .put(path)
          .send(body ?? {}),
      ),
    delete: (path) => auth(request(app).delete(path)),
    upload: (path) => auth(request(app).post(path)),
  };
}

export const anon = (): Client => ({
  token: '',
  get: (path, query) =>
    request(app)
      .get(path)
      .query(query ?? {}),
  post: (path, body) =>
    request(app)
      .post(path)
      .send(body ?? {}),
  patch: (path, body) =>
    request(app)
      .patch(path)
      .send(body ?? {}),
  put: (path, body) =>
    request(app)
      .put(path)
      .send(body ?? {}),
  delete: (path) => request(app).delete(path),
  upload: (path) => request(app).post(path),
});

export const unique = () => `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;

/** Registers a fresh learner and returns a signed-in client for them. */
export async function newStudent(name = 'Test Learner'): Promise<Client & { email: string; userId: string; studentId: string }> {
  const email = `learner-${unique()}@example.com`;
  const res = await request(app).post('/auth/register').send({ name, email, password: PASSWORD });
  if (res.status !== 201) throw new Error(`register failed: ${res.status} ${JSON.stringify(res.body)}`);
  tokens.set(email, res.body.token as string);
  const client = await as({ email });
  const payload = decodeToken(client.token);
  return { ...client, email, userId: payload.sub, studentId: payload.studentId ?? '' };
}

/** Reads the (unverified) JWT payload — fine for tests, which only need the ids inside. */
export function decodeToken(token: string): { sub: string; role: string; studentId?: string; instructorId?: string } {
  const [, body] = token.split('.');
  return JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
}
