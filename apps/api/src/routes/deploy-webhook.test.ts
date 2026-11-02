import { createHmac } from 'node:crypto';
import { afterEach, describe, expect, it } from 'vitest';
import request from 'supertest';

import { app } from '../test/helpers.js';

/* Signed by GitHub over the raw body (see deploy-webhook.ts). The success path (branch match,
 * DEPLOY_WEBHOOK_SECRET set) is not exercised here since it spawns deploy.sh — that belongs in a
 * deploy-time smoke test on the server, not a hermetic unit test. */

const SECRET = 'test-webhook-secret';
const sign = (body: string) => `sha256=${createHmac('sha256', SECRET).update(body).digest('hex')}`;

afterEach(() => {
  delete process.env.DEPLOY_WEBHOOK_SECRET;
  delete process.env.DEPLOY_BRANCH;
});

describe('deploy webhook', () => {
  it('404s when DEPLOY_WEBHOOK_SECRET is not configured', async () => {
    const body = JSON.stringify({ ref: 'refs/heads/main' });
    const res = await request(app)
      .post('/deploy/webhook')
      .set('X-Hub-Signature-256', sign(body))
      .set('X-GitHub-Event', 'push')
      .set('Content-Type', 'application/json')
      .send(body);
    expect(res.status).toBe(404);
  });

  it('rejects a missing or wrong signature', async () => {
    process.env.DEPLOY_WEBHOOK_SECRET = SECRET;
    const body = JSON.stringify({ ref: 'refs/heads/main' });

    const noSig = await request(app).post('/deploy/webhook').set('X-GitHub-Event', 'push').set('Content-Type', 'application/json').send(body);
    expect(noSig.status).toBe(401);

    const wrongSig = await request(app)
      .post('/deploy/webhook')
      .set('X-Hub-Signature-256', 'sha256=deadbeef')
      .set('X-GitHub-Event', 'push')
      .set('Content-Type', 'application/json')
      .send(body);
    expect(wrongSig.status).toBe(401);
  });

  it('answers a ping event without checking the branch', async () => {
    process.env.DEPLOY_WEBHOOK_SECRET = SECRET;
    const body = JSON.stringify({ zen: 'Responsive is better than fast.' });
    const res = await request(app)
      .post('/deploy/webhook')
      .set('X-Hub-Signature-256', sign(body))
      .set('X-GitHub-Event', 'ping')
      .set('Content-Type', 'application/json')
      .send(body);
    expect(res.status).toBe(200);
  });

  it('accepts the form-encoded body GitHub sends by default, signed over the raw bytes', async () => {
    process.env.DEPLOY_WEBHOOK_SECRET = SECRET;
    process.env.DEPLOY_BRANCH = 'main';
    const ping = `payload=${encodeURIComponent(JSON.stringify({ zen: 'Keep it logically awesome.' }))}`;
    const pong = await request(app)
      .post('/deploy/webhook')
      .set('X-Hub-Signature-256', sign(ping))
      .set('X-GitHub-Event', 'ping')
      .set('Content-Type', 'application/x-www-form-urlencoded')
      .send(ping);
    expect(pong.status).toBe(200);

    // The branch is read from inside the `payload` field, so a foreign branch is still a no-op.
    const push = `payload=${encodeURIComponent(JSON.stringify({ ref: 'refs/heads/some-other-branch' }))}`;
    const res = await request(app)
      .post('/deploy/webhook')
      .set('X-Hub-Signature-256', sign(push))
      .set('X-GitHub-Event', 'push')
      .set('Content-Type', 'application/x-www-form-urlencoded')
      .send(push);
    expect(res.status).toBe(204);
  });

  it('refuses a request with no body instead of failing', async () => {
    process.env.DEPLOY_WEBHOOK_SECRET = SECRET;
    const res = await request(app).post('/deploy/webhook').set('X-GitHub-Event', 'ping');
    expect([400, 401]).toContain(res.status);
  });

  it('no-ops a push to a branch other than DEPLOY_BRANCH', async () => {
    process.env.DEPLOY_WEBHOOK_SECRET = SECRET;
    process.env.DEPLOY_BRANCH = 'main';
    const body = JSON.stringify({ ref: 'refs/heads/some-other-branch' });
    const res = await request(app)
      .post('/deploy/webhook')
      .set('X-Hub-Signature-256', sign(body))
      .set('X-GitHub-Event', 'push')
      .set('Content-Type', 'application/json')
      .send(body);
    expect(res.status).toBe(204);
  });
});
