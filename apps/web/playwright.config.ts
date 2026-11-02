import { defineConfig, devices } from '@playwright/test';

/**
 * Full-stack E2E: the built frontend in `http` mode, driving Chromium against a running API. This
 * does not start either server — `npm run e2e` (see package.json) starts the API, waits for it,
 * then runs Playwright against `WEB_BASE_URL` (the running dev/preview server for the web app).
 * Both servers are started outside this config so their logs stay visible and the API's seeded
 * `dev.db` is reused rather than rebuilt on every run, the way `apps/api`'s own test suite does.
 */
export default defineConfig({
  testDir: './e2e',
  timeout: 90_000,
  // Each worker drives a browser against one API and one database; more than two starves a shared machine.
  workers: Number(process.env.E2E_WORKERS ?? 2),
  expect: { timeout: 15_000 },
  fullyParallel: false,
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: process.env.WEB_BASE_URL ?? 'http://localhost:5174',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
