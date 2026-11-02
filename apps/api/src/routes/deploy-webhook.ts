import { createHmac, timingSafeEqual } from 'node:crypto';
import { spawn } from 'node:child_process';
import { openSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import express, { Router } from 'express';

import { describeError, observe } from '../lib/observe.js';

/**
 * GitHub push webhook → `deploy.sh`. Disabled unless DEPLOY_WEBHOOK_SECRET is set, so a
 * deployment that doesn't configure it just gets a 404 here, same as if the route didn't exist.
 *
 * Mounted before the app's `express.json()` (see app.ts) because the signature covers the raw
 * body — once json() parses it, the exact bytes GitHub signed are gone.
 *
 * The body is read raw whatever its content type: GitHub's webhook form defaults to
 * `application/x-www-form-urlencoded` (the JSON document arrives as a `payload=` field) and the
 * signature is over those raw bytes either way. Matching only `application/json` left `req.body`
 * as `{}` for the default encoding, which the HMAC then rejected with a 500.
 */
/** The variables deploy.sh is spawned with: a login shell's, so PATH finds node, npm and pm2 and HOME finds ~/.pm2. */
const SHELL_ENV = ['PATH', 'HOME', 'USER', 'LOGNAME', 'SHELL', 'LANG', 'LC_ALL', 'TZ', 'PM2_HOME'] as const;

export const deployWebhookRouter = Router();

deployWebhookRouter.use(express.raw({ type: () => true, limit: '1mb' }));

/** The JSON document GitHub sent, whichever of its two encodings the webhook was created with. */
function documentOf(raw: Buffer, contentType: string): string {
  if (!/application\/x-www-form-urlencoded/i.test(contentType)) return raw.toString('utf8');
  return new URLSearchParams(raw.toString('utf8')).get('payload') ?? '';
}

deployWebhookRouter.post('/', (req, res) => {
  const secret = process.env.DEPLOY_WEBHOOK_SECRET;
  if (!secret) return res.status(404).json({ message: 'Not found.' });

  const body = req.body;
  if (!Buffer.isBuffer(body)) return res.status(400).json({ message: 'A request body is required.' });
  const signature = req.header('x-hub-signature-256') ?? '';
  const expected = `sha256=${createHmac('sha256', secret).update(body).digest('hex')}`;
  const given = Buffer.from(signature);
  const wanted = Buffer.from(expected);
  if (given.length !== wanted.length || !timingSafeEqual(given, wanted)) {
    return res.status(401).json({ message: 'Invalid signature.' });
  }

  // GitHub sends a `ping` event when the webhook is first created; answer it without deploying.
  const event = req.header('x-github-event');
  if (event === 'ping') return res.status(200).json({ ok: true });
  if (event !== 'push') return res.status(204).end();

  let payload: { ref?: string; after?: string };
  try {
    payload = JSON.parse(documentOf(body, req.header('content-type') ?? ''));
  } catch {
    return res.status(400).json({ message: 'Invalid JSON payload.' });
  }

  const branch = process.env.DEPLOY_BRANCH;
  if (!branch || payload.ref !== `refs/heads/${branch}`) return res.status(204).end();

  if (!process.env.WEB_DIST) return res.status(500).json({ message: 'WEB_DIST is not set; cannot locate the checkout.' });

  res.status(202).json({ ok: true, message: 'Deploy triggered.' });

  // WEB_DIST is `${SITE}/web` (see web.ts), so its parent is the site root.
  const site = path.dirname(process.env.WEB_DIST);
  const script = path.join(site, 'app', 'deploy', 'deploy.sh');
  const logFd = openSync(path.join(os.homedir(), 'deploy-webhook.log'), 'a');
  // The pushed commit, so deploy.sh can wait for GitHub to serve it: the webhook can fire before
  // a fetch sees the new ref, and a deploy of the previous tip would look like a success.
  // BRANCH is the branch that was pushed, and deploy.sh ships it whatever deploy.conf says: when
  // the two disagreed, a push to `production` rebuilt deploy.conf's stale `master` instead and
  // the site silently went back to an old release.
  // Only what a login shell would have, never this process's own environment: deploy.sh reads its settings from
  // apps/api/.env and deploy.conf itself. Inherited, NODE_ENV=production made `npm ci` drop the devDependencies the
  // build and the API run on (tsx, prisma, vite), and the old .env values rode `pm2 reload --update-env` into the
  // new process — where dotenv never overrides a variable already set — so an edited .env did not take effect.
  const env: NodeJS.ProcessEnv = {
    ...Object.fromEntries(SHELL_ENV.flatMap((key) => (process.env[key] ? [[key, process.env[key]]] : []))),
    BRANCH: branch,
    ...(payload.after ? { DEPLOY_EXPECT_SHA: payload.after } : {}),
  };
  // `setsid -f` forks the script off and returns at once, so it is re-parented to init before
  // deploy.sh reaches `pm2 reload`. Without that, PM2's tree-kill of the old API process — this
  // process — takes the deploy down with it in the middle of its own reload step. The cost is
  // that the script's exit code is not observable here: its outcome is in ~/deploy-webhook.log,
  // and a second trigger while one runs is refused by deploy.sh's own lock, in that same log.
  const child = spawn('setsid', ['-f', 'bash', script], { detached: true, stdio: ['ignore', logFd, logFd], env });
  child.on('error', (err) => observe('job.failed', { job: 'deploy.sh', error: describeError(err) }));
  child.unref();
});
