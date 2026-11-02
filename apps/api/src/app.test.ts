import { describe, expect, it } from 'vitest';
import request from 'supertest';

import { createApp } from './app.js';

const app = createApp();
const unique = () => `${Date.now()}-${Math.random().toString(36).slice(2)}`;

describe('auth', () => {
  it('registers a learner account and returns a usable token', async () => {
    const email = `learner-${unique()}@example.com`;
    const res = await request(app).post('/auth/register').send({ name: 'Test Learner', email, password: 'password123' });
    expect(res.status).toBe(201);
    expect(res.body.user).toMatchObject({ email, role: 'student' });
    expect(typeof res.body.token).toBe('string');

    const me = await request(app).get('/auth/me').set('Authorization', `Bearer ${res.body.token}`);
    expect(me.status).toBe(200);
    expect(me.body.user.email).toBe(email);
  });

  it('rejects a duplicate email with a conflict', async () => {
    const email = `dup-${unique()}@example.com`;
    await request(app).post('/auth/register').send({ name: 'Once', email, password: 'password123' });
    const res = await request(app).post('/auth/register').send({ name: 'Twice', email, password: 'password123' });
    expect(res.status).toBe(409);
  });

  it('rejects the wrong password', async () => {
    const email = `wrongpw-${unique()}@example.com`;
    await request(app).post('/auth/register').send({ name: 'Someone', email, password: 'password123' });
    const res = await request(app).post('/auth/login').send({ email, password: 'not-the-password' });
    expect(res.status).toBe(401);
  });

  it('rejects an unauthenticated request to a protected route', async () => {
    const res = await request(app).get('/students');
    expect(res.status).toBe(401);
  });
});

describe('catalog', () => {
  it('lists published courses without authentication', async () => {
    const res = await request(app).get('/catalog/courses');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('404s a course that does not exist', async () => {
    const res = await request(app).get('/catalog/courses/no-such-course');
    expect(res.status).toBe(404);
  });
});

describe('role guard', () => {
  it('lets a signed-in student reach their own learning home, but not the admin student list', async () => {
    const email = `student-${unique()}@example.com`;
    const register = await request(app).post('/auth/register').send({ name: 'A Student', email, password: 'password123' });
    const token = register.body.token as string;

    const home = await request(app).get('/learning/home').set('Authorization', `Bearer ${token}`);
    expect(home.status).toBe(200);
    expect(home.body.firstName).toBe('A');

    const studentsList = await request(app).get('/students').set('Authorization', `Bearer ${token}`);
    expect(studentsList.status).toBe(403);
  });
});
