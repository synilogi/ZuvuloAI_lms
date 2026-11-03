import { createHmac, generateKeyPairSync } from 'node:crypto';
import { rm } from 'node:fs/promises';
import { createServer, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import path from 'node:path';

import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';

import { db, inAcademy } from '../test/db.js';
import { liveRoomConfig, liveRoomUsable, verifyJaasSignature } from '../lib/liveRoom.js';
import { closeStaleRooms, keepRecording, RECORDING_DIR } from '../lib/liveSessions.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { ACADEMY } from '../test/db.js';
import { app, as, newStudent, unique, type Client } from '../test/helpers.js';

let instructor: Client;
let courseId: string;
let instructorId: string;

const inMinutes = (m: number) => new Date(Date.now() + m * 60_000).toISOString();
const input = (title: string, extra: Record<string, unknown> = {}) => ({
  courseId,
  title,
  instructorId,
  startsAt: inMinutes(10),
  durationMin: 45,
  capacity: 5,
  meeting: { kind: 'room' },
  reminders: [],
  ...extra,
});
const ids = (rows: { liveClass: { id: string } }[]) => rows.map((r) => r.liveClass.id);

const savedEnv = { ...process.env };
afterEach(() => {
  for (const key of ['JITSI_DOMAIN', 'JAAS_APP_ID', 'JAAS_KID', 'JAAS_PRIVATE_KEY', 'JAAS_WEBHOOK_SECRET', 'NODE_ENV', 'LIVE_ROOM_PUBLIC_JITSI'])
    process.env[key] = savedEnv[key];
});

beforeAll(async () => {
  instructor = await as('instructor');
  // A free course of theirs: the suite's learners enrol in it themselves (a paid one is bought).
  courseId = (
    (await instructor.get('/courses', { status: 'published', pageSize: 50 })).body.rows as { id: string; pricing: string; visibility: string }[]
  ).find((c) => c.pricing === 'free' && c.visibility === 'public')!.id;
  instructorId = (await instructor.get('/auth/me')).body.user.instructorId;
});

async function enrolled(name: string) {
  const learner = await newStudent(name);
  await learner.post(`/learning/courses/${courseId}/enroll`);
  return learner;
}

describe('live room: start, join, end, attendance', () => {
  it('lets the Super Admin host, though that account belongs to no academy', async () => {
    const email = `live-owner-${unique()}@example.com`;
    await provisionSuperAdmin({ email, password: 'platform-owner-password', name: 'Platform Owner' });
    const owner = await as({ email, password: 'platform-owner-password' });
    const created = await instructor.post('/live', input(`Owner room ${unique()}`));
    const started = await owner.post(`/live/${created.body.id}/start`);
    expect(started.status, JSON.stringify(started.body)).toBe(200);
    await owner.post(`/live/${created.body.id}/end`);
  });

  it('runs a class from the host’s start to their end, taking attendance on the way', async () => {
    const present = await enrolled('Comes On Time');
    const walkIn = await enrolled('Walks In');
    const noShow = await enrolled('Never Comes');
    const created = await instructor.post('/live', input(`Room ${unique()}`));
    expect(created.status).toBe(201);
    const id = created.body.id as string;
    await present.post(`/live/${id}/register`);
    await noShow.post(`/live/${id}/register`);

    // In the join window but not opened: learners wait, and cannot get in.
    const waiting = await present.get('/live/learner');
    expect(ids(waiting.body.upcoming)).toContain(id);
    expect(waiting.body.upcoming.find((r: { liveClass: { id: string } }) => r.liveClass.id === id).phase).toBe('starting-soon');
    expect((await present.post(`/live/${id}/join`)).status).toBe(409);

    // The host opens the room: the class is live and learners hear about it.
    const started = await instructor.post(`/live/${id}/start`);
    expect(started.status).toBe(200);
    expect(started.body.phase).toBe('live');
    expect(started.body.liveClass.startedAt).toBeTruthy();
    expect(started.body.room).toMatchObject({ provider: 'jitsi', domain: 'meet.jit.si', moderator: true });
    expect(started.body.room.room).toMatch(/^shubh-[0-9a-f]{24}$/);
    expect(started.body.room.jwt).toBeUndefined();
    expect((await present.get('/notifications', { limit: 5 })).body.rows[0].title).toMatch(/^Live now/);
    // Starting again just hands the host the same room back.
    expect((await instructor.post(`/live/${id}/start`)).body.room.room).toBe(started.body.room.room);

    const live = await present.get('/live/learner');
    expect(ids(live.body.live)).toContain(id);

    // A registered learner joins into the same room, not as moderator.
    const join = await present.post(`/live/${id}/join`);
    expect(join.status).toBe(200);
    expect(join.body).toMatchObject({ kind: 'room', room: { room: started.body.room.room, moderator: false, displayName: 'Comes On Time' } });
    // A learner who never registered is given a place on the way in.
    expect((await walkIn.post(`/live/${id}/join`)).status).toBe(200);
    // Once in, the place can't be given up.
    expect((await present.post(`/live/${id}/register`)).status).toBe(409);

    const during = await instructor.get(`/live/${id}`);
    expect(during.body.phase).toBe('live');
    expect(during.body.liveClass.attending).toBe(2);
    expect(during.body.room).toMatchObject({ provider: 'jitsi', recording: false });
    // A class under way is neither edited nor cancelled.
    expect((await instructor.patch(`/live/${id}`, input('Edited'))).status).toBe(409);
    expect((await instructor.post(`/live/${id}/cancel`, { reason: 'Changed my mind' })).status).toBe(409);
    // The host rejoins through the same endpoint.
    expect((await instructor.post(`/live/${id}/join`)).body.room.moderator).toBe(true);

    // The host ends it: who came is present, who held a place and didn't is absent.
    const ended = await instructor.post(`/live/${id}/end`);
    expect(ended.status).toBe(200);
    expect(ended.body.phase).toBe('recording-expired');
    expect(ended.body.liveClass.attended).toBe(2);
    const after = await instructor.get(`/live/${id}`);
    const byName = Object.fromEntries(after.body.attendees.map((a: { name: string; attended?: boolean }) => [a.name, a.attended]));
    expect(byName).toEqual({ 'Comes On Time': true, 'Walks In': true, 'Never Comes': false });
    expect(after.body.attendees.find((a: { name: string }) => a.name === 'Comes On Time').joinedAt).toBeTruthy();

    // Over: nobody gets in, it can't be ended or started again, and each learner's history says whether they came.
    expect((await walkIn.post(`/live/${id}/join`)).status).toBe(409);
    expect((await instructor.post(`/live/${id}/end`)).status).toBe(409);
    expect((await instructor.post(`/live/${id}/start`)).status).toBe(409);
    expect((await present.get('/live/learner')).body.history.find((r: { liveClass: { id: string } }) => r.liveClass.id === id).attended).toBe(true);
    expect((await noShow.get('/live/learner')).body.history.find((r: { liveClass: { id: string } }) => r.liveClass.id === id).attended).toBe(false);
    expect((await noShow.get(`/live/${id}`)).body).toMatchObject({ registered: true, attended: false });
  });

  it('opens the room only in its window, and only for the built-in room', async () => {
    const tooEarly = await instructor.post('/live', input(`Too early ${unique()}`, { startsAt: inMinutes(120) }));
    const early = await instructor.post(`/live/${tooEarly.body.id}/start`);
    expect(early.status).toBe(409);
    expect(early.body.message).toMatch(/15 minutes before/);

    const outside = await instructor.post('/live', input(`Outside ${unique()}`, { meeting: { kind: 'external', link: 'https://meet.example.com/abc' } }));
    expect((await instructor.post(`/live/${outside.body.id}/start`)).status).toBe(409);
    // An outside meeting opens from its join window. The LMS can't see who is in it, so opening the link takes a place
    // and records when — but is never counted as attending.
    const learner = await enrolled('Opens The Link');
    const join = await learner.post(`/live/${outside.body.id}/join`);
    expect(join.body).toEqual({ kind: 'external', link: 'https://meet.example.com/abc' });
    const detail = await instructor.get(`/live/${outside.body.id}`);
    const opened = detail.body.attendees.find((a: { name: string }) => a.name === 'Opens The Link');
    expect(opened.attended).toBeUndefined();
    expect(opened.joinedAt).toEqual(expect.any(String));

    // A learner outside the course is kept out of the room.
    const started = await instructor.post('/live', input(`Private ${unique()}`));
    await instructor.post(`/live/${started.body.id}/start`);
    const outsider = await newStudent('Not In Course');
    expect((await outsider.post(`/live/${started.body.id}/join`)).status).toBe(403);
    // A full class turns away a walk-in.
    const full = await instructor.post('/live', input(`Full ${unique()}`, { capacity: 1 }));
    await (await enrolled('Took The Seat')).post(`/live/${full.body.id}/register`);
    await instructor.post(`/live/${full.body.id}/start`);
    expect((await (await enrolled('Too Late')).post(`/live/${full.body.id}/join`)).status).toBe(409);
  });

  it('closes a room left open after the overrun, settling attendance', async () => {
    const learner = await enrolled('Left Open');
    const created = await instructor.post('/live', input(`Left open ${unique()}`));
    await learner.post(`/live/${created.body.id}/register`);
    await instructor.post(`/live/${created.body.id}/start`);
    expect(await inAcademy(() => closeStaleRooms(new Date()))).toBe(0);
    // 10 + 45 + 60 minutes on, the host never pressed End.
    expect(await inAcademy(() => closeStaleRooms(new Date(Date.now() + 116 * 60_000)))).toBeGreaterThanOrEqual(1);
    const row = await db.liveClass.findUniqueOrThrow({ where: { id: created.body.id }, include: { registrations: true } });
    expect(row.endedAt).toBeTruthy();
    expect(row.registrations[0].attended).toBe(false);
  });
});

describe('live room on JaaS', () => {
  const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const pem = privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
  const useJaas = (secret?: string) => {
    process.env.JAAS_APP_ID = 'vpaas-magic-cookie-test';
    process.env.JAAS_KID = 'kid42';
    process.env.JAAS_PRIVATE_KEY = pem.replace(/\n/g, '\\n');
    process.env.JAAS_WEBHOOK_SECRET = secret ?? '';
  };

  it('refuses a half-configured JaaS rather than fall back to the public server', () => {
    expect(() => liveRoomConfig({ JAAS_APP_ID: 'x' })).toThrow(/JAAS_KID/);
    expect(liveRoomConfig({}).provider).toBe('jitsi');
    expect(liveRoomConfig({ JITSI_DOMAIN: 'meet.example.org' }).domain).toBe('meet.example.org');
  });

  it('refuses a private key that cannot sign, at boot rather than on a host’s first class', () => {
    const cfg = (key: string) => () => liveRoomConfig({ JAAS_APP_ID: 'a', JAAS_KID: 'k', JAAS_PRIVATE_KEY: key });
    expect(cfg('not a key')).toThrow(/cannot be read/);
    const ec = generateKeyPairSync('ec', { namedCurve: 'P-256' }).privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
    expect(cfg(ec)).toThrow(/RSA/);
    expect(cfg(pem).call(null).provider).toBe('jaas');
  });

  it('never falls back to the public meet.jit.si in production, unless the owner allows it', () => {
    const publicRoom = liveRoomConfig({});
    expect(liveRoomUsable(publicRoom, { NODE_ENV: 'production' })).toBe(false);
    expect(liveRoomUsable(publicRoom, { NODE_ENV: 'production', LIVE_ROOM_PUBLIC_JITSI: 'allow' })).toBe(true);
    expect(liveRoomUsable(publicRoom, { NODE_ENV: 'development' })).toBe(true);
    expect(liveRoomUsable(liveRoomConfig({ JITSI_DOMAIN: 'meet.example.org' }), { NODE_ENV: 'production' })).toBe(true);
    expect(liveRoomUsable(liveRoomConfig({ JAAS_APP_ID: 'a', JAAS_KID: 'k', JAAS_PRIVATE_KEY: pem }), { NODE_ENV: 'production' })).toBe(true);
  });

  it('on a production server without JaaS: nothing starts, nobody is marked present, and the host is told why', async () => {
    const learner = await enrolled('Unconfigured Learner');
    const created = await instructor.post('/live', input(`No video service ${unique()}`));
    const opened = await instructor.post(`/live/${created.body.id}/start`);
    expect(opened.status).toBe(200);

    // Made before the switch: a production process also enforces plans, which this academy has none of.
    const fresh = await instructor.post('/live', input(`Never started ${unique()}`, { startsAt: inMinutes(5) }));
    expect(fresh.body).toMatchObject({ id: expect.any(String) });

    process.env.NODE_ENV = 'production';
    const restart = await instructor.post(`/live/${created.body.id}/start`);
    expect(restart.status).toBe(503);
    expect(restart.body.code).toBe('LIVE_ROOM_NOT_CONFIGURED');
    const join = await learner.post(`/live/${created.body.id}/join`);
    expect(join.status).toBe(503);
    expect(await db.liveRegistration.count({ where: { liveClassId: created.body.id, studentId: learner.studentId } })).toBe(0);

    expect((await instructor.post(`/live/${fresh.body.id}/start`)).status).toBe(503);
    expect((await db.liveClass.findUniqueOrThrow({ where: { id: fresh.body.id } })).startedAt).toBeNull();
    const detail = await instructor.get(`/live/${fresh.body.id}`);
    expect(detail.body.room).toMatchObject({ canStart: false, configured: false });
  });

  it('signs each join for its person and room: the host moderates, learners don’t', async () => {
    useJaas('whsec');
    const learner = await enrolled('Signed Learner');
    const created = await instructor.post('/live', input(`JaaS ${unique()}`));
    const host = await instructor.post(`/live/${created.body.id}/start`);
    expect(host.body.room).toMatchObject({ provider: 'jaas', domain: '8x8.vc', moderator: true, recording: true });
    const roomName = host.body.room.room.split('/')[1];
    expect(host.body.room.room).toBe(`vpaas-magic-cookie-test/${roomName}`);

    const hostToken = jwt.verify(host.body.room.jwt, publicKey, { algorithms: ['RS256'], audience: 'jitsi', issuer: 'chat' }) as jwt.JwtPayload;
    expect(jwt.decode(host.body.room.jwt, { complete: true })!.header.kid).toBe('vpaas-magic-cookie-test/kid42');
    expect(hostToken).toMatchObject({
      sub: 'vpaas-magic-cookie-test',
      room: roomName,
      context: { user: { moderator: 'true' }, features: { recording: 'true' } },
    });

    const join = await learner.post(`/live/${created.body.id}/join`);
    const learnerToken = jwt.verify(join.body.room.jwt, publicKey) as jwt.JwtPayload;
    expect(learnerToken).toMatchObject({ room: roomName, context: { user: { name: 'Signed Learner', moderator: 'false' }, features: { recording: 'false' } } });
    expect(join.body.room.recording).toBe(false);
  });

  describe('recordings', () => {
    let server: Server;
    let fileUrl: string;
    const video = Buffer.concat([Buffer.from([0, 0, 0, 0x18]), Buffer.from('ftypmp42'), Buffer.alloc(2048, 7)]);
    beforeAll(async () => {
      server = createServer((req, res) => {
        if (req.url === '/rec.mp4') {
          res.writeHead(200, { 'Content-Type': 'video/mp4', 'Content-Length': video.length });
          res.end(video);
        } else res.writeHead(404).end();
      });
      await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
      fileUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}/rec.mp4`;
    });
    afterAll(async () => {
      server.close();
    });

    const sign = (body: string, secret: string, t = Math.floor(Date.now() / 1000)) =>
      `t=${t},v1=${createHmac('sha256', secret).update(`${t}.${body}`).digest('base64')}`;

    it('checks the signature: only v1, constant-time, and not stale', () => {
      const raw = Buffer.from('{"a":1}');
      expect(verifyJaasSignature(raw, sign('{"a":1}', 's'), 's')).toBe(true);
      expect(verifyJaasSignature(raw, sign('{"a":2}', 's'), 's')).toBe(false);
      expect(verifyJaasSignature(raw, sign('{"a":1}', 'other'), 's')).toBe(false);
      expect(verifyJaasSignature(raw, sign('{"a":1}', 's', Math.floor(Date.now() / 1000) - 3600), 's')).toBe(false);
      expect(verifyJaasSignature(raw, sign('{"a":1}', 's').replace('v1=', 'v0='), 's')).toBe(false);
      expect(verifyJaasSignature(raw, undefined, 's')).toBe(false);
    });

    it('keeps the recording JaaS posts and plays it to the class’s learners only', async () => {
      useJaas('whsec');
      const learner = await enrolled('Watches Later');
      const created = await instructor.post('/live', input(`Recorded ${unique()}`));
      const id = created.body.id as string;
      const host = await instructor.post(`/live/${id}/start`);
      await learner.post(`/live/${id}/join`);
      await instructor.post(`/live/${id}/end`);
      const fqn = host.body.room.room as string;

      // Unsigned or mis-signed: refused, nothing stored.
      const body = JSON.stringify({ eventType: 'RECORDING_UPLOADED', fqn, data: { preAuthenticatedLink: fileUrl.replace('http:', 'https:') } });
      expect((await request(app).post('/webhooks/jaas').set('Content-Type', 'application/json').send(body)).status).toBe(401);
      expect((await request(app).post('/webhooks/jaas').set('X-Jaas-Signature', sign(body, 'wrong')).send(body)).status).toBe(401);
      // Not a recording: acknowledged, ignored.
      const other = JSON.stringify({ eventType: 'PARTICIPANT_JOINED', fqn });
      expect((await request(app).post('/webhooks/jaas').set('X-Jaas-Signature', sign(other, 'whsec')).send(other)).body.outcome).toBe('ignored');

      const ok = await request(app).post('/webhooks/jaas').set('Content-Type', 'application/json').set('X-Jaas-Signature', sign(body, 'whsec')).send(body);
      expect(ok.status).toBe(200);
      expect(ok.body.outcome).toBe('stored');
      expect((await instructor.get(`/live/${id}`)).body.liveClass.recording.status).toBe('processing');

      // The link is https in production; point the stored one at the local test server and keep the file.
      const row = await db.liveClass.findUniqueOrThrow({ where: { id } });
      await db.liveClass.update({ where: { id }, data: { recordingJson: row.recordingJson!.replace(fileUrl.replace('http:', 'https:'), fileUrl) } });
      expect(await keepRecording(id, ACADEMY)).toBe('ready');

      const detail = await learner.get(`/live/${id}`);
      expect(detail.body.phase).toBe('ended');
      expect(detail.body.liveClass.recording).toMatchObject({ status: 'ready' });
      expect(JSON.stringify(detail.body)).not.toContain('rec.mp4');
      expect(ids((await learner.get('/live/learner')).body.recordings)).toContain(id);

      const play = await learner.get(`/live/${id}/recording`).buffer(true);
      expect(play.status).toBe(200);
      expect(play.headers['content-type']).toMatch(/video\/mp4/);
      expect(Buffer.compare(play.body as Buffer, video)).toBe(0);
      const ranged = await learner.get(`/live/${id}/recording`).set('Range', 'bytes=0-11').buffer(true);
      expect(ranged.status).toBe(206);
      expect((await (await newStudent('Not Enrolled Viewer')).get(`/live/${id}/recording`)).status).toBe(403);
      // A browser's <video> gets a short-lived link instead; it opens without a header, and is no sign-in token.
      const link = await learner.post(`/live/${id}/recording/link`);
      expect(link.body.url).toMatch(/^\/live\/recording-files\//);
      const viaLink = await request(app).get(link.body.url).set('Range', 'bytes=0-3').buffer(true);
      expect(viaLink.status).toBe(206);
      expect(
        (
          await request(app)
            .get('/auth/me')
            .set('Authorization', `Bearer ${link.body.url.split('/').pop()}`)
        ).status,
      ).toBe(401);
      expect((await request(app).get(`${link.body.url}x`)).status).toBe(404);

      // A redelivery changes nothing.
      const again = await request(app).post('/webhooks/jaas').set('X-Jaas-Signature', sign(body, 'whsec')).send(body);
      expect(again.body.outcome).toBe('duplicate');
      await rm(path.join(RECORDING_DIR, `${id}.mp4`), { force: true });
    });

    it('answers 404 while no webhook secret is set', async () => {
      useJaas();
      const body = '{}';
      expect((await request(app).post('/webhooks/jaas').set('X-Jaas-Signature', sign(body, 'x')).send(body)).status).toBe(404);
    });
  });
});
