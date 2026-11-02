#!/usr/bin/env node
/*
 * Orchestrates a full-stack E2E run: reseed the API's database, start the real API, build and
 * preview the real frontend against it, run Playwright, then tear both servers down — win or lose.
 *
 * Grading the one waiting submission in `instructor.spec.ts` is not idempotent: run this against
 * a database that already had it graded and the review-queue test finds nothing to grade. That is
 * why this script always rebuilds its database first, the same way `apps/api`'s own `pretest`
 * rebuilds `test.db` before every run — an E2E run is only meaningful against a database it knows
 * the shape of.
 *
 * That database is its own, named by `E2E_DATABASE_URL` and ending in `_e2e`: dropped and rebuilt (migrate → demo seed →
 * permission backfill → E2E Super Admin) on every run. A developer's `dev.db` is never opened.
 *
 * Isolation — a run touches nothing a developer owns and reaches nothing outside the machine:
 *   - the frontend is built into a temporary folder (`E2E_WEB_OUT`), never `apps/web/dist`;
 *   - uploads go to a temporary folder (`E2E_UPLOAD_DIR`), Playwright's traces to `E2E_OUTPUT_DIR`;
 *   - the API and preview ports are `E2E_API_PORT` / `E2E_WEB_PORT` (4000 / 4173 by default);
 *   - every outside provider is pinned off whatever `apps/api/.env` says: mail is stored in the outbox and never sent,
 *     no Razorpay, JaaS or push keys, and gateway credentials are sealed under a throwaway key made for this run.
 *
 * Example, fully isolated: E2E_DATABASE_URL=mysql://root@127.0.0.1:3306/run1_e2e E2E_WEB_OUT=/tmp/x/web E2E_UPLOAD_DIR=/tmp/x/uploads
 *   E2E_OUTPUT_DIR=/tmp/x/results E2E_API_PORT=4300 E2E_WEB_PORT=4373 npm run e2e
 */
import { spawn, spawnSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { mkdirSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { setTimeout as sleep } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const webRoot = resolve(here, '..');
const apiRoot = resolve(webRoot, '../api');

// Where this run keeps everything it writes. Nothing defaults into a folder a developer owns.
const scratch = mkdtempSync(join(tmpdir(), 'zuviloai-e2e-'));
const databaseUrl = process.env.E2E_DATABASE_URL || 'mysql://root:root@127.0.0.1:3306/zuviloai_e2e';
if (!/_e2e(\?|$)/.test(databaseUrl)) throw new Error('E2E_DATABASE_URL must name a database ending in _e2e: this run drops it.');
const webOut = resolve(process.env.E2E_WEB_OUT || join(scratch, 'web'));
const uploadDir = resolve(process.env.E2E_UPLOAD_DIR || join(scratch, 'uploads'));
const outputDir = resolve(process.env.E2E_OUTPUT_DIR || join(scratch, 'results'));
const apiPort = process.env.E2E_API_PORT || '4000';
const webPort = process.env.E2E_WEB_PORT || '4173';
const apiUrl = `http://localhost:${apiPort}`;
const webUrl = `http://localhost:${webPort}`;
if (webOut === resolve(webRoot, 'dist')) throw new Error('E2E_WEB_OUT must not be apps/web/dist — that build is the developer’s own.');
for (const dir of [uploadDir, outputDir]) mkdirSync(dir, { recursive: true });

/**
 * Outside services, pinned off for every step of the run. `dotenv/config` (loaded by the API) never overwrites a
 * variable already in the environment — an empty one included — so these win over `apps/api/.env`.
 */
const SAFE_PROVIDERS = {
  MAIL_TRANSPORT: 'outbox',
  PAYMENT_PROVIDER: '',
  RAZORPAY_KEY_ID: '',
  RAZORPAY_KEY_SECRET: '',
  RAZORPAY_WEBHOOK_SECRET: '',
  PAYMENT_CREDENTIALS_KEY: randomBytes(32).toString('hex'),
  PUSH_PROVIDER: '',
  JAAS_APP_ID: '',
  JAAS_KID: '',
  JAAS_PRIVATE_KEY: '',
  JAAS_PRIVATE_KEY_FILE: '',
  JAAS_WEBHOOK_SECRET: '',
  SALES_NOTIFY_EMAIL: '',
  DEPLOY_WEBHOOK_SECRET: '',
  WEB_DIST: '',
  UPLOAD_DIR: uploadDir,
};
const npx = 'npx';
// `npx` resolves to `npx.cmd` on Windows, a batch file spawn() cannot exec directly — it needs a shell.
const onWindows = process.platform === 'win32';

const children = [];
function run(cmd, args, opts = {}) {
  const child = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], shell: onWindows, ...opts });
  children.push(child);
  return child;
}

function collect(child, label) {
  let buf = '';
  const onData = (d) => {
    buf += d.toString();
    process.stdout.write(`[${label}] ${d}`);
  };
  child.stdout.on('data', onData);
  child.stderr.on('data', onData);
  return () => buf;
}

async function waitFor(url, timeoutMs = 30_000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const res = await fetch(url);
      if (res.ok) return true;
    } catch {
      /* not up yet */
    }
    await sleep(500);
  }
  throw new Error(`Timed out waiting for ${url}`);
}

function killAll() {
  for (const child of children) {
    if (child.exitCode !== null || child.signalCode !== null || !child.pid) continue;
    try {
      // On Windows, `shell: true` runs the command inside cmd.exe; killing that process leaves the
      // real node/vite process it spawned running. `taskkill /t` kills the whole tree instead.
      if (onWindows) spawnSync('taskkill', ['/pid', String(child.pid), '/t', '/f'], { stdio: 'ignore' });
      else child.kill();
    } catch {
      /* already gone */
    }
  }
}
process.on('exit', killAll);
process.on('SIGINT', () => process.exit(130));
process.on('SIGTERM', () => process.exit(143));

async function main() {
  // Every step below, and the API itself, runs against this file and nothing else.
  console.log(`[e2e] Database ${new URL(databaseUrl).pathname.slice(1)} · frontend build ${webOut} · uploads ${uploadDir} · results ${outputDir}`);
  console.log(`[e2e] API ${apiUrl} · web ${webUrl} · mail stored, never sent · no payment, live or push keys`);
  const dbEnv = { ...process.env, ...SAFE_PROVIDERS, DATABASE_URL: databaseUrl, SEED_QUIET: '1' };
  const step = (label, args) =>
    new Promise((resolvePromise, reject) => {
      console.log(`[e2e] ${label}…`);
      const child = run(npx, args, { cwd: apiRoot, env: dbEnv });
      collect(child, 'db');
      child.on('exit', (code) => (code === 0 ? resolvePromise() : reject(new Error(`${label} exited ${code}`))));
    });
  await step('Emptying the E2E database', ['tsx', 'scripts/recreate-database.ts']);
  await step('Building the E2E database', ['prisma', 'migrate', 'deploy']);
  await step('Seeding the demo academy', ['tsx', 'prisma/seed.ts']);
  await step('Granting the demo admins their permissions', ['tsx', 'scripts/backfill-admin-permissions.ts']);
  await step('Writing the affiliate plan draft', ['tsx', 'scripts/seed-mlm-plan.ts']);
  // Some specs act as the platform: a Super Admin of their own, created the way an operator
  // creates one, so no real account's password is ever needed.
  await new Promise((resolvePromise, reject) => {
    console.log('[e2e] Provisioning the E2E Super Admin…');
    const su = run(npx, ['tsx', 'scripts/create-superadmin.ts'], {
      cwd: apiRoot,
      env: { ...dbEnv, SUPERADMIN_EMAIL: 'e2e-superadmin@syniastrolms.test', SUPERADMIN_PASSWORD: 'syniastrolms123', SUPERADMIN_NAME: 'E2E Platform' },
    });
    collect(su, 'superadmin');
    su.on('exit', (code) => (code === 0 ? resolvePromise() : reject(new Error(`create-superadmin exited ${code}`))));
  });

  console.log('[e2e] Starting the API…');
  // Override whatever origin apps/api/.env has on file for local dev — the E2E run always serves
  // the built frontend from the preview server below, on this fixed port. `dotenv/config` (loaded
  // by src/index.ts) never overwrites a variable already present in the environment, so this wins.
  // SUBSCRIPTION_INVOICE_LEAD_DAYS=31: a monthly subscription started during the run is invoiced for its next
  // period on the scheduler's next tick, so the billing spec can pay a real renewal invoice without moving a clock.
  const api = run(npx, ['tsx', 'src/index.ts'], {
    cwd: apiRoot,
    // PAYMENT_SANDBOX=on: no real gateway is configured in the E2E database, so the sandbox gateway takes payments —
    // its test checkout drives pay, decline and cancel through the real signed-webhook path (SAAS-030). APP_URL is
    // where it sends the payer, and what email links point at.
    env: {
      ...dbEnv,
      SEED_QUIET: '',
      PORT: apiPort,
      CORS_ORIGIN: webUrl,
      APP_URL: webUrl,
      SUBSCRIPTION_INVOICE_LEAD_DAYS: '31',
      PAYMENT_SANDBOX: 'on',
      // Every spec signs in from the same client (localhost), so the whole suite shares one `/auth` budget per window;
      // production's 30 is far below what a full run needs. The limiter itself stays on, and is tested in apps/api.
      RATE_LIMIT_AUTH_MAX: '300',
      RATE_LIMIT_ACCOUNT_MAX: '300',
      // The same for the general budget: a full run makes well over production's 1,000 requests a window from one
      // client, and the last specs were refused with 429s.
      RATE_LIMIT_MAX: '20000',
    },
  });
  collect(api, 'api');
  await waitFor(`${apiUrl}/health`);
  console.log('[e2e] API healthy.');

  console.log('[e2e] Building the frontend…');
  // Vite bakes VITE_* into the bundle at build time, so this cannot rely on a developer's local
  // apps/web/.env existing (or being http mode) — the E2E build always targets the real API.
  await new Promise((resolvePromise, reject) => {
    const build = run(npx, ['vite', 'build', '--outDir', webOut, '--emptyOutDir'], {
      cwd: webRoot,
      env: { ...process.env, VITE_API_MODE: 'http', VITE_API_BASE_URL: apiUrl },
    });
    collect(build, 'build');
    build.on('exit', (code) => (code === 0 ? resolvePromise() : reject(new Error(`build exited ${code}`))));
  });

  console.log('[e2e] Starting the preview server…');
  const preview = run(npx, ['vite', 'preview', '--outDir', webOut, '--port', webPort, '--strictPort'], { cwd: webRoot });
  const readPreview = collect(preview, 'web');
  await waitFor(`${webUrl}/`);
  void readPreview;
  console.log('[e2e] Preview server ready.');

  console.log('[e2e] Running Playwright…');
  const exitCode = await new Promise((resolvePromise) => {
    // Anything after `npm run e2e --` goes to Playwright: a spec file, `--grep`, and so on.
    const pw = run(npx, ['playwright', 'test', '--output', outputDir, ...process.argv.slice(2)], {
      cwd: webRoot,
      env: { ...process.env, WEB_BASE_URL: webUrl, E2E_API_URL: apiUrl, E2E_DATABASE_URL: databaseUrl },
    });
    collect(pw, 'playwright');
    pw.on('exit', (code) => resolvePromise(code ?? 1));
  });

  killAll();
  process.exit(exitCode);
}

main().catch((err) => {
  console.error('[e2e]', err);
  killAll();
  process.exit(1);
});
