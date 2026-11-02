import { useEffect, useId, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { Eye, EyeSlash } from '@phosphor-icons/react';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { API_MODE } from '@/lib/apiMode';
import * as httpAuth from '@/services/http/auth';
import { fieldProps } from '@/lib/fieldProps';
import { AuthChrome } from './MarketingChrome';
import styles from './Marketing.module.css';

/** Reached from the link in the forgot-password email: choose a new password for the account. */
export default function ResetPasswordPage() {
  const { token = '' } = useParams();
  const navigate = useNavigate();
  const toast = useToast();
  const passwordId = useId();
  const confirmId = useId();
  const [valid, setValid] = useState<boolean | null>(API_MODE === 'http' ? null : true);
  // An invitation to an LMS (an instructor or learner an Admin added) names it: "Join <LMS>".
  const [lms, setLms] = useState<string>();
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [serverError, setServerError] = useState<string>();
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (API_MODE !== 'http') return;
    let cancelled = false;
    httpAuth
      .checkResetToken(token)
      .then((check) => {
        if (cancelled) return;
        setValid(check.valid);
        setLms(check.lms);
      })
      .catch(() => !cancelled && setValid(false));
    return () => {
      cancelled = true;
    };
  }, [token]);

  const passwordValid = password.length >= 8;
  const confirmValid = confirm.length > 0 && confirm === password;
  const allIssues: FieldIssue[] = [
    ...(!passwordValid ? [{ field: passwordId, message: 'Password must be at least 8 characters.' }] : []),
    ...(!confirmValid ? [{ field: confirmId, message: 'Passwords must match.' }] : []),
    ...(serverError ? [{ field: passwordId, message: serverError }] : []),
  ];
  const issues = attempt ? allIssues : [];

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    if (!passwordValid || !confirmValid) return;

    if (API_MODE === 'http') {
      setSubmitting(true);
      try {
        await httpAuth.resetPassword(token, password);
      } catch (err) {
        setServerError(err instanceof Error ? err.message : 'Could not update your password.');
        setSubmitting(false);
        return;
      }
      setSubmitting(false);
    }
    toast({ kind: 'success', title: 'Password updated', text: 'Sign in with your new password.' });
    navigate('/login', { replace: true });
  };

  return (
    <AuthChrome eyebrow={lms ? `Join ${lms}` : 'Choose a new password'}>
      <h1 className={styles.authTitle}>{lms ? `Join ${lms} — choose your password` : 'Reset your password'}</h1>
      {valid === null && <p className={styles.authSubtitle}>Checking your reset link…</p>}
      {valid === false && (
        <>
          <p className={styles.authSubtitle}>This reset link is invalid or has expired. Reset links work once and for one hour.</p>
          <p className={styles.authSwitch}>
            <Link to="/login">Back to sign in</Link> and choose “Forgot your password?” to request a new one.
          </p>
        </>
      )}
      {valid === true && (
        <>
          <p className={styles.authSubtitle}>Pick a password of at least 8 characters that you don’t use anywhere else.</p>
          <ErrorSummary issues={issues} attempt={attempt} title="Fix these before continuing" />
          <form className={styles.authForm} onSubmit={submit} noValidate>
            <Field label="New password" id={passwordId} error={attempt > 0 && !passwordValid ? 'Password must be at least 8 characters.' : undefined}>
              <div className={styles.passwordRow}>
                <Input
                  {...fieldProps(passwordId, true, attempt > 0 && !passwordValid)}
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  autoComplete="new-password"
                  autoFocus
                />
                <button
                  type="button"
                  className={styles.passwordToggle}
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? <EyeSlash size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </Field>
            <Field label="Confirm new password" error={attempt > 0 && !confirmValid ? 'Passwords must match.' : undefined}>
              <Input
                id={confirmId}
                type={showPassword ? 'text' : 'password'}
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                placeholder="••••••••"
                autoComplete="new-password"
              />
            </Field>
            <Button type="submit" variant="primary" size="lg" block loading={submitting}>
              Update password
            </Button>
          </form>
          <p className={styles.authSwitch}>
            Remembered it? <Link to="/login">Sign in</Link>
          </p>
        </>
      )}
    </AuthChrome>
  );
}
