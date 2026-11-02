import { defineConfig, devices } from '@playwright/test';

// End-to-end checks run against the real API with the existing seed (workflow.md §6.1). Start the API first:
//   npm run dev -w @syniastrolms/api
// Three widths are verified for every page: desktop 1280, tablet 768, mobile 360.
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 1 : 0,
  reporter: [['list']],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:5174',
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'], viewport: { width: 1280, height: 800 } } },
    { name: 'tablet', use: { ...devices['Desktop Chrome'], viewport: { width: 768, height: 1024 }, hasTouch: true } },
    { name: 'mobile', use: { ...devices['Desktop Chrome'], viewport: { width: 360, height: 780 }, hasTouch: true, isMobile: true } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:5174',
    reuseExistingServer: true,
    timeout: 60_000,
  },
});
