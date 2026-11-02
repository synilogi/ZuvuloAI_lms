import { afterEach, describe, expect, it } from 'vitest';

import { assertMailConfig, mailTransport, setMailTransport, smtpTransport } from './mailDelivery.js';

/* The SMTP transport (SAAS-026): chosen by MAIL_TRANSPORT=smtp, refused at boot without a relay and a sender. */

afterEach(() => {
  delete process.env.MAIL_TRANSPORT;
  setMailTransport(null);
});

describe('the SMTP transport', () => {
  it('is what MAIL_TRANSPORT=smtp selects, and it delivers', () => {
    process.env.MAIL_TRANSPORT = 'smtp';
    const transport = mailTransport();
    expect(transport).toMatchObject({ name: 'smtp', delivers: true });
  });

  it('refuses to start without a relay host or a sending address', () => {
    expect(() => assertMailConfig({ MAIL_TRANSPORT: 'smtp' })).toThrow(/SMTP_HOST and MAIL_FROM/);
    expect(() => assertMailConfig({ MAIL_TRANSPORT: 'smtp', SMTP_HOST: 'smtp.example.com' })).toThrow(/MAIL_FROM/);
    expect(() => assertMailConfig({ MAIL_TRANSPORT: 'smtp', SMTP_HOST: 'smtp.example.com', MAIL_FROM: 'noreply@example.com' })).not.toThrow();
    expect(() => assertMailConfig({ MAIL_TRANSPORT: 'outbox' })).not.toThrow();
  });

  it('reports an unreachable relay as a failed send, which the worker retries', async () => {
    const transport = smtpTransport({ SMTP_HOST: '127.0.0.1', SMTP_PORT: '1', MAIL_FROM: 'noreply@example.com' });
    await expect(transport.send({ to: 'someone@example.com', subject: 'Hi', text: 'Hello' })).rejects.toThrow();
  });
});
