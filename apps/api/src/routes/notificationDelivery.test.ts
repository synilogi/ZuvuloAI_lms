import { generateKeyPairSync } from 'node:crypto';
import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { queueEmail } from '../lib/mail.js';
import { deliverQueuedEmail, redactSentSecrets, setMailTransport, type MailTransport, type OutgoingMessage } from '../lib/mailDelivery.js';
import { notify } from '../lib/notify.js';
import { deliverQueuedPushes, FcmProvider, setPushProvider, type PushMessage, type PushOutcome, type PushProvider } from '../lib/push.js';
import { db, inAcademy, platformDb, T } from '../test/db.js';
import { PASSWORD, anon, app, newStudent, unique } from '../test/helpers.js';

/* SAAS-021. Queued email is delivered by a worker with retries and a final status; the same message is not
 * queued twice; devices register for push, bound to their session; push hints follow preferences and quiet
 * hours and carry only a notification's id and category. */

const MINUTE = 60_000;

/** A transport that records what it sends and fails while `failing` is set. */
class FakeTransport implements MailTransport {
  readonly name = 'fake';
  readonly delivers = true;
  sent: OutgoingMessage[] = [];
  failing = false;
  async send(message: OutgoingMessage) {
    if (this.failing) throw new Error('SMTP 421 try later');
    this.sent.push(message);
    return { messageId: `msg-${this.sent.length}` };
  }
}

class FakePush implements PushProvider {
  readonly name = 'fakepush';
  calls: { tokens: string[]; message: PushMessage }[] = [];
  answer: (token: string) => PushOutcome = (token) => ({ token, ok: true });
  async send(tokens: string[], message: PushMessage) {
    this.calls.push({ tokens, message });
    return tokens.map((t) => this.answer(t));
  }
}

const device = () => `device-token-${unique()}-${'x'.repeat(24)}`;
const register = (token: string, deviceToken: string, platform = 'android') =>
  request(app).post('/notifications/devices').set('Authorization', `Bearer ${token}`).send({ token: deviceToken, platform });

afterEach(() => {
  setMailTransport(null);
  setPushProvider(undefined);
});

describe('email is queued once and delivered by the worker', () => {
  const to = () => `mail-${unique()}@example.com`;

  it('does not queue the same message to the same address twice within the window', async () => {
    const address = to();
    const first = await inAcademy(() => queueEmail({ to: address, subject: 'Hello', text: 'Same body', templateKey: 'test' }));
    const again = await inAcademy(() => queueEmail({ to: address, subject: 'Hello', text: 'Same body', templateKey: 'test' }));
    const other = await inAcademy(() => queueEmail({ to: address, subject: 'Hello', text: 'A different body', templateKey: 'test' }));
    expect(again.id).toBe(first.id);
    expect(other.id).not.toBe(first.id);
    expect(await db.emailOutbox.count({ where: { toEmail: address } })).toBe(2);
  });

  it('sends what is queued and records the transport’s reference', async () => {
    const transport = new FakeTransport();
    setMailTransport(transport);
    const address = to();
    const { id } = await inAcademy(() => queueEmail({ to: address, subject: 'Welcome', text: 'Body', templateKey: 'test' }));
    const run = await deliverQueuedEmail();
    expect(run.sent).toBeGreaterThanOrEqual(1);
    expect(transport.sent.some((m) => m.to === address)).toBe(true);
    expect(await db.emailOutbox.findUniqueOrThrow({ where: { id } })).toMatchObject({ status: 'sent', attempts: 1, error: null });
    // A second run finds nothing left to send for it.
    await deliverQueuedEmail();
    expect(transport.sent.filter((m) => m.to === address)).toHaveLength(1);
  });

  it('drains a backlog of more than a thousand messages across ticks, each once', async () => {
    const transport = new FakeTransport();
    setMailTransport(transport);
    const batch = `backlog-${unique()}`;
    await platformDb.emailOutbox.createMany({
      data: Array.from({ length: 1200 }, (_, i) => ({ ...T, toEmail: `${batch}-${i}@example.com`, subject: 'Backlog', text: 'Body', templateKey: 'test' })),
    });
    // A tick stops at its time budget so other jobs are not starved, and the next carries on. How many ticks depends on the machine.
    for (let tick = 0; tick < 10 && transport.sent.filter((m) => m.to.startsWith(batch)).length < 1200; tick++) {
      expect((await deliverQueuedEmail()).sent).toBeGreaterThan(0);
    }
    const mine = transport.sent.filter((m) => m.to.startsWith(batch));
    expect(mine).toHaveLength(1200);
    expect(new Set(mine.map((m) => m.to)).size).toBe(1200);
    // 1,200 real database rounds on a shared machine: the point is that they all go, once, not how fast.
  }, 180_000);

  it('sends a verification code before an older backlog of notifications', async () => {
    const transport = new FakeTransport();
    setMailTransport(transport);
    const batch = `queue-${unique()}`;
    await platformDb.emailOutbox.createMany({
      data: Array.from({ length: 300 }, (_, i) => ({
        ...T,
        toEmail: `${batch}-${i}@example.com`,
        subject: 'News',
        text: 'Body',
        templateKey: 'notification-course',
      })),
    });
    const waiting = `${batch}-learner@example.com`;
    await inAcademy(() => queueEmail({ to: waiting, subject: '123456 is your code', text: '123456', templateKey: 'account-verification' }));
    await deliverQueuedEmail();
    const order = transport.sent.map((m) => m.to).filter((address) => address.startsWith(batch));
    expect(order[0]).toBe(waiting);
    expect(order).toHaveLength(301);
  });

  it('blanks delivered codes and links once they have all expired, keeping who was sent what and when', async () => {
    const old = new Date(Date.now() - 8 * 86_400_000);
    const make = (templateKey: string, status: string, createdAt: Date) =>
      platformDb.emailOutbox.create({
        data: { ...T, toEmail: `kept-${unique()}@example.com`, subject: '654321 is your code', text: 'Code 654321', templateKey, status, createdAt },
      });
    const sentCode = await make('account-verification', 'sent', old);
    const queuedCode = await make('account-verification', 'queued', old);
    const freshCode = await make('password-reset', 'sent', new Date());
    const news = await make('notification-course', 'sent', old);
    expect(await redactSentSecrets()).toBeGreaterThanOrEqual(1);
    const read = (id: string) => platformDb.emailOutbox.findUniqueOrThrow({ where: { id } });
    expect((await read(sentCode.id)).text).not.toMatch(/654321/);
    expect((await read(sentCode.id)).subject).not.toMatch(/654321/);
    expect((await read(sentCode.id)).toEmail).toBe(sentCode.toEmail);
    for (const kept of [queuedCode, freshCode, news]) expect((await read(kept.id)).text).toBe('Code 654321');
    expect(await redactSentSecrets()).toBe(0);
  });

  it('retries a failure on the backoff, and gives up with the reason once the attempts are used', async () => {
    const transport = new FakeTransport();
    transport.failing = true;
    setMailTransport(transport);
    const address = to();
    const { id } = await inAcademy(() =>
      queueEmail({ to: address, subject: 'Reset', text: 'Open https://example.com/reset-password/abcdef123456 within the hour', templateKey: 'test' }),
    );
    let clock = new Date();
    await deliverQueuedEmail(clock);
    let row = await db.emailOutbox.findUniqueOrThrow({ where: { id } });
    expect(row).toMatchObject({ status: 'queued', attempts: 1 });
    expect(row.nextAttemptAt!.getTime() - clock.getTime()).toBe(MINUTE);
    expect(row.error).toMatch(/421/);
    expect(row.error).not.toMatch(/reset-password/);

    // Not before it is due.
    await deliverQueuedEmail(new Date(clock.getTime() + 30_000));
    expect((await db.emailOutbox.findUniqueOrThrow({ where: { id } })).attempts).toBe(1);

    for (let i = 0; i < 5; i++) {
      row = await db.emailOutbox.findUniqueOrThrow({ where: { id } });
      clock = new Date(row.nextAttemptAt!.getTime() + 1000);
      await deliverQueuedEmail(clock);
    }
    row = await db.emailOutbox.findUniqueOrThrow({ where: { id } });
    expect(row).toMatchObject({ status: 'failed', attempts: 6 });
    expect(transport.sent).toHaveLength(0);
  });

  it('never sends one message twice when two workers run at once, and takes back one abandoned mid-send', async () => {
    const transport = new FakeTransport();
    setMailTransport(transport);
    const addresses = Array.from({ length: 6 }, to);
    for (const address of addresses) await inAcademy(() => queueEmail({ to: address, subject: 'Race', text: 'Body', templateKey: 'test' }));
    await Promise.all([deliverQueuedEmail(), deliverQueuedEmail(), deliverQueuedEmail()]);
    for (const address of addresses)
      expect(
        transport.sent.filter((m) => m.to === address),
        address,
      ).toHaveLength(1);

    const stuck = await db.emailOutbox.create({
      data: {
        ...T,
        toEmail: to(),
        subject: 'Stuck',
        text: 'Body',
        templateKey: 'test',
        status: 'sending',
        attempts: 1,
        lastAttemptAt: new Date(Date.now() - 11 * MINUTE),
      },
    });
    await deliverQueuedEmail();
    expect(await db.emailOutbox.findUniqueOrThrow({ where: { id: stuck.id } })).toMatchObject({ status: 'sent', attempts: 2 });
  });

  it('leaves the outbox alone when the transport only stores, as by default', async () => {
    const address = to();
    const { id } = await inAcademy(() => queueEmail({ to: address, subject: 'Kept', text: 'Body', templateKey: 'test' }));
    expect(await deliverQueuedEmail()).toEqual({ sent: 0, retried: 0, failed: 0 });
    expect(await db.emailOutbox.findUniqueOrThrow({ where: { id } })).toMatchObject({ status: 'queued', attempts: 0 });
  });
});

describe('devices register for push, bound to their session', () => {
  let learner: Awaited<ReturnType<typeof newStudent>>;
  beforeAll(async () => {
    learner = await newStudent('Device Learner');
  });

  it('registers a device for the signed-in account and lists it without echoing the token', async () => {
    const token = device();
    const res = await register(learner.token, token);
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ platform: 'android', tokenEnd: token.slice(-8), current: true });
    const list = await request(app).get('/notifications/devices').set('Authorization', `Bearer ${learner.token}`);
    expect(list.body.devices.map((d: { id: string }) => d.id)).toContain(res.body.id);
    expect(JSON.stringify(list.body)).not.toContain(token);
    // Registering again refreshes the same row.
    expect((await register(learner.token, token, 'ios')).body.id).toBe(res.body.id);
    expect(await platformDb.deviceToken.count({ where: { token } })).toBe(1);
  });

  it('moves a token to whoever registers it next, and lets only the owner remove it', async () => {
    const other = await newStudent('Next Owner');
    const token = device();
    const mine = await register(learner.token, token);
    const theirs = await register(other.token, token);
    expect((await platformDb.deviceToken.findUniqueOrThrow({ where: { token } })).userId).toBe(other.userId);
    expect((await request(app).delete(`/notifications/devices/${theirs.body.id}`).set('Authorization', `Bearer ${learner.token}`)).status).toBe(404);
    expect((await request(app).delete(`/notifications/devices/${mine.body.id}`).set('Authorization', `Bearer ${learner.token}`)).status).toBe(404);
    expect((await request(app).delete(`/notifications/devices/${theirs.body.id}`).set('Authorization', `Bearer ${other.token}`)).status).toBe(204);
    expect(await platformDb.deviceToken.count({ where: { token } })).toBe(0);
  });

  it('refuses a malformed registration and an anonymous one', async () => {
    expect((await register(learner.token, 'short')).status).toBe(400);
    expect((await register(learner.token, device(), 'windows-phone')).status).toBe(400);
    expect((await anon().post('/notifications/devices', { token: device(), platform: 'android' })).status).toBe(401);
  });

  it('removes a session’s devices when it signs out, and every device on logout-all', async () => {
    const user = await newStudent('Signing Out');
    const signIn = async () => (await request(app).post('/auth/login').send({ email: user.email, password: PASSWORD })).body.token as string;
    const phone = await signIn();
    const tablet = await signIn();
    const phoneDevice = device();
    const tabletDevice = device();
    await register(phone, phoneDevice);
    await register(tablet, tabletDevice);
    await request(app).post('/auth/logout').set('Authorization', `Bearer ${phone}`);
    expect(await platformDb.deviceToken.count({ where: { token: phoneDevice } })).toBe(0);
    expect(await platformDb.deviceToken.count({ where: { token: tabletDevice } })).toBe(1);
    await request(app).post('/auth/logout-all').set('Authorization', `Bearer ${tablet}`);
    expect(await platformDb.deviceToken.count({ where: { userId: user.userId } })).toBe(0);
  });
});

describe('push hints follow the in-app notification', () => {
  const fresh = async (name: string) => {
    const user = await newStudent(name);
    await register(user.token, device());
    return user;
  };
  const tell = (userId: string, over: Partial<Parameters<typeof notify>[0]> = {}) =>
    inAcademy(() => notify({ recipientUserId: userId, category: 'course', title: 'New lesson', summary: 'A lesson is ready.', ...over }));
  const latestPush = (userId: string) => db.pushDelivery.findFirst({ where: { userId }, orderBy: { createdAt: 'desc' } });

  it('queues and sends nothing without a provider', async () => {
    const user = await fresh('No Provider');
    await tell(user.userId);
    expect(await latestPush(user.userId)).toBeNull();
    expect(await deliverQueuedPushes()).toEqual({ sent: 0, skipped: 0, retried: 0, failed: 0 });
  });

  it('sends only the notification’s id and category, once', async () => {
    const provider = new FakePush();
    setPushProvider(provider);
    const user = await fresh('Pushed Learner');
    await tell(user.userId);
    const push = await latestPush(user.userId);
    expect(push).toMatchObject({ status: 'queued' });
    await deliverQueuedPushes();
    const call = provider.calls.find((c) => c.message.notificationId === push!.notificationId)!;
    expect(call.message).toEqual({ notificationId: push!.notificationId, category: 'course' });
    expect(await db.pushDelivery.findUniqueOrThrow({ where: { id: push!.id } })).toMatchObject({ status: 'sent', delivered: 1 });
    await deliverQueuedPushes();
    expect(provider.calls.filter((c) => c.message.notificationId === push!.notificationId)).toHaveLength(1);
  });

  it('respects the recipient’s channel choice, and holds a push through quiet hours unless it is important', async () => {
    setPushProvider(new FakePush());
    const off = await fresh('Channel Off');
    await db.notificationSettings.create({
      data: { ...T, userId: off.userId, categoriesJson: JSON.stringify([{ category: 'course', channels: { app: false, email: true, sms: false } }]) },
    });
    await tell(off.userId);
    expect(await latestPush(off.userId)).toBeNull();

    const quiet = await fresh('Quiet Learner');
    // Quiet all day but one minute: whatever the time, it is inside.
    const now = new Date(Date.now() + 5.5 * 3_600_000);
    const hhmm = (d: Date) => `${String(d.getUTCHours()).padStart(2, '0')}:${String(d.getUTCMinutes()).padStart(2, '0')}`;
    const ending = new Date(now.getTime() - MINUTE);
    await db.notificationSettings.create({
      data: { ...T, userId: quiet.userId, quietHoursJson: JSON.stringify({ enabled: true, from: hhmm(now), to: hhmm(ending) }) },
    });
    await tell(quiet.userId);
    expect((await latestPush(quiet.userId))!.nextAttemptAt.getTime()).toBeGreaterThan(Date.now() + 60 * MINUTE);
    await tell(quiet.userId, { important: true, title: 'Urgent' });
    expect((await latestPush(quiet.userId))!.nextAttemptAt.getTime()).toBeLessThanOrEqual(Date.now());
  });

  it('removes a token the provider no longer accepts, retries a failure, and skips a notification already read', async () => {
    const provider = new FakePush();
    setPushProvider(provider);
    const gone = await fresh('Uninstalled');
    provider.answer = (token) => ({ token, ok: false, invalidToken: true, error: 'FCM 404 UNREGISTERED' });
    await tell(gone.userId);
    await deliverQueuedPushes();
    expect(await platformDb.deviceToken.count({ where: { userId: gone.userId } })).toBe(0);
    expect((await latestPush(gone.userId))!.status).toBe('skipped');

    const flaky = await fresh('Flaky Network');
    provider.answer = (token) => ({ token, ok: false, invalidToken: false, error: 'FCM 503 UNAVAILABLE' });
    await tell(flaky.userId);
    await deliverQueuedPushes();
    expect(await latestPush(flaky.userId)).toMatchObject({ status: 'queued', attempts: 1, error: 'FCM 503 UNAVAILABLE' });

    const reader = await fresh('Quick Reader');
    provider.answer = (token) => ({ token, ok: true });
    await tell(reader.userId);
    const push = await latestPush(reader.userId);
    await db.appNotification.update({ where: { id: push!.notificationId }, data: { readAt: new Date() } });
    await deliverQueuedPushes();
    expect(await db.pushDelivery.findUniqueOrThrow({ where: { id: push!.id } })).toMatchObject({ status: 'skipped' });
  });
});

describe('the FCM provider speaks HTTP v1 as documented', () => {
  it('exchanges a signed service-account JWT for a token, sends a data-only message, and reports a dead token', async () => {
    const { privateKey, publicKey } = generateKeyPairSync('rsa', {
      modulusLength: 2048,
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
      publicKeyEncoding: { type: 'spki', format: 'pem' },
    });
    const calls: { url: string; init: RequestInit }[] = [];
    const fakeFetch = (async (url: string, init: RequestInit) => {
      calls.push({ url, init });
      if (url.includes('oauth2')) return new Response(JSON.stringify({ access_token: 'ya29.fake', expires_in: 3600 }), { status: 200 });
      const token = JSON.parse(String(init.body)).message.token as string;
      if (token === 'dead') return new Response(JSON.stringify({ error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] } }), { status: 404 });
      return new Response(JSON.stringify({ name: 'projects/p/messages/1' }), { status: 200 });
    }) as typeof fetch;
    const fcm = new FcmProvider({ project_id: 'qa-project', client_email: 'push@qa-project.iam.gserviceaccount.com', private_key: privateKey }, fakeFetch);

    const outcomes = await fcm.send(['live', 'dead'], { notificationId: 'n1', category: 'live' });
    expect(outcomes).toEqual([
      { token: 'live', ok: true },
      { token: 'dead', ok: false, invalidToken: true, error: 'FCM 404 UNREGISTERED' },
    ]);
    const exchange = calls[0];
    const assertion = new URLSearchParams(String(exchange.init.body)).get('assertion')!;
    expect(jwt.verify(assertion, publicKey, { algorithms: ['RS256'] })).toMatchObject({
      iss: 'push@qa-project.iam.gserviceaccount.com',
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
    });
    const send = calls.find((c) => c.url.includes('messages:send'))!;
    expect(send.url).toBe('https://fcm.googleapis.com/v1/projects/qa-project/messages:send');
    expect((send.init.headers as Record<string, string>).authorization).toBe('Bearer ya29.fake');
    expect(JSON.parse(String(send.init.body)).message).toMatchObject({ data: { notificationId: 'n1', category: 'live' } });
    expect(JSON.parse(String(send.init.body)).message.notification).toBeUndefined();
    // The access token is reused, not fetched per message.
    await fcm.send(['live'], { notificationId: 'n2', category: 'live' });
    expect(calls.filter((c) => c.url.includes('oauth2'))).toHaveLength(1);
  });
});
