import { useEffect, useId, useState, type FormEvent } from 'react';
import { ArrowLeft, EnvelopeSimple } from '@phosphor-icons/react';
import type { AccountCreated, AccountVerificationPending, InstructorRequestPending } from '@syniastrolms/domain';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { API_MODE } from '@/providers/SessionProvider';
import { services, ServiceError } from '@/services';
import { DEMO_SIGNUP_CODE } from '@/services/mock/signup';
import { codeIssue, resendWait } from './registrationCode';
import marketing from './Marketing.module.css';
import styles from './EmailCodeStep.module.css';

/*
 * The code step every learner or instructor who registers themselves goes through (join link, invitation, course link,
 * request to teach): the server holds the registration and emails a 6-digit code; nothing exists until it is entered.
 * The page that started the registration decides what happens once it is confirmed.
 */

const minutesLeft = (expiresAt: string, now: number) => Math.max(0, Math.ceil((Date.parse(expiresAt) - now) / 60_000));

export function EmailCodeStep({
  pending: initial,
  confirmLabel = 'Verify and continue',
  onConfirmed,
  onBack,
}: {
  pending: AccountVerificationPending;
  confirmLabel?: string;
  /** Resolves once the page has acted on the result (signed in, or shown the waiting message). */
  onConfirmed: (result: AccountCreated | InstructorRequestPending) => void | Promise<void>;
  onBack: () => void;
}) {
  const toast = useToast();
  const codeId = useId();
  const [pending, setPending] = useState(initial);
  const [code, setCode] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [error, setError] = useState<string>();
  const [closed, setClosed] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [resending, setResending] = useState(false);
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const t = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(t);
  }, []);
  const wait = resendWait(pending.resendAvailableAt, now);
  const minutes = minutesLeft(pending.expiresAt, now);
  const localIssue = attempt > 0 ? codeIssue(code) : undefined;

  const failed = (err: unknown, fallback: string) => {
    // A registration that is gone (used, replaced, pruned) can only be started again.
    if (err instanceof ServiceError && err.code === 'not-found' && err.reason === 'VERIFICATION_FAILED') setClosed(true);
    setError(err instanceof Error ? err.message : fallback);
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setError(undefined);
    if (codeIssue(code)) return;
    setSubmitting(true);
    try {
      await onConfirmed(await services.signup.confirmVerification(pending.verificationId, code));
    } catch (err) {
      failed(err, 'The code could not be checked.');
    } finally {
      setSubmitting(false);
    }
  };

  const resend = async () => {
    setResending(true);
    setError(undefined);
    try {
      setPending(await services.signup.resendVerification(pending.verificationId));
      setCode('');
      toast({ kind: 'success', title: 'A new code is on its way', text: `Sent to ${pending.email}.` });
    } catch (err) {
      failed(err, 'A new code could not be sent.');
    } finally {
      setResending(false);
    }
  };

  return (
    <section className={styles.step} aria-labelledby={`${codeId}-title`}>
      <span className={styles.icon} aria-hidden="true">
        <EnvelopeSimple size={26} />
      </span>
      <h1 id={`${codeId}-title`} className={marketing.authTitle}>
        Check your email
      </h1>
      <p className={marketing.authSubtitle}>
        We sent a 6-digit code to <strong>{pending.email}</strong>.{' '}
        {pending.role === 'instructor' ? `Enter it to send your request to ${pending.lms}.` : `Enter it to create your account at ${pending.lms}.`}{' '}
        {minutes > 0 ? `It works for ${minutes} more minute${minutes === 1 ? '' : 's'}.` : 'It has expired — ask for a new one.'}
      </p>
      {API_MODE === 'mock' && (
        <InlineMessage kind="info" title="Demo build">
          No email is sent here. Use the code {DEMO_SIGNUP_CODE}.
        </InlineMessage>
      )}
      {error && (
        <InlineMessage kind="error" title={closed ? 'This registration has ended' : 'That didn’t work.'}>
          {error}
        </InlineMessage>
      )}
      {closed ? (
        <Button variant="primary" size="lg" block onClick={onBack}>
          Start again
        </Button>
      ) : (
        <>
          <form className={marketing.authForm} onSubmit={submit} noValidate>
            <Field label="Verification code" hint="Check your spam folder if it hasn’t arrived in a minute." error={localIssue}>
              <Input
                id={codeId}
                className={styles.codeInput}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                inputMode="numeric"
                autoComplete="one-time-code"
                placeholder="000000"
                maxLength={6}
                autoFocus
              />
            </Field>
            <Button type="submit" variant="primary" size="lg" block loading={submitting}>
              {confirmLabel}
            </Button>
          </form>
          <div className={styles.actions}>
            <Button variant="ghost" size="sm" onClick={onBack} iconStart={<ArrowLeft size={14} />}>
              Change details
            </Button>
            <Button variant="ghost" size="sm" onClick={resend} disabled={wait > 0} loading={resending}>
              {wait > 0 ? `Resend code in ${wait}s` : 'Resend code'}
            </Button>
          </div>
        </>
      )}
    </section>
  );
}
