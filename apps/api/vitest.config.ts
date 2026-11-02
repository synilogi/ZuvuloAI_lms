import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Every suite shares one SQLite file; run files one at a time to avoid write locks.
    fileParallelism: false,
    testTimeout: 20_000,
    // Test servers bind 127.0.0.1 — see src/test/setup.ts.
    setupFiles: ['./src/test/setup.ts'],
    env: {
      NODE_ENV: 'test',
      DATABASE_URL: 'file:./test.db',
      JWT_SECRET: 'test-secret',
      CORS_ORIGIN: 'http://localhost:5173',
      RATE_LIMIT_MAX: '100000',
      RATE_LIMIT_AUTH_MAX: '100000',
      RATE_LIMIT_EMAIL_MAX: '100000',
      RATE_LIMIT_ACCOUNT_MAX: '100000',
      // Nothing in the suite sends email, whatever apps/api/.env holds: messages stay in the test database's outbox.
      MAIL_TRANSPORT: 'outbox',
      // Fixtures register learners in one step; the suites about verification switch it back on (signup, emailVerification).
      SIGNUP_EMAIL_VERIFICATION: 'off',
      // The static test code is off whatever apps/api/.env holds; the suites about it set their own (lib/testOtp.ts).
      TEST_OTP_EMAIL: '',
      TEST_OTP_CODE: '',
      APP_ENV: '',
      // No test ever reaches a real payment gateway: suites that need one install a fake (setPaymentProvider).
      // Gateway credentials are sealed under this test-only key, which guards nothing real.
      PAYMENT_CREDENTIALS_KEY: '7e3a5c1f9b2d4e6a8c0f1b3d5e7a9c2e4f6a8b0d2c4e6f8a1b3c5d7e9f0a2b4c',
      PAYMENT_PROVIDER: '',
      RAZORPAY_KEY_ID: '',
      RAZORPAY_KEY_SECRET: '',
      RAZORPAY_WEBHOOK_SECRET: '',
      // The verification code travels by email in the suite, whatever apps/api/.env holds.
      OTP_CHANNEL: 'email',
      // The live room starts on the public Jitsi server whatever .env holds; the JaaS suite sets its own keys.
      JITSI_DOMAIN: '',
      JAAS_APP_ID: '',
      JAAS_KID: '',
      JAAS_PRIVATE_KEY: '',
      JAAS_PRIVATE_KEY_FILE: '',
      JAAS_WEBHOOK_SECRET: '',
    },
  },
});
