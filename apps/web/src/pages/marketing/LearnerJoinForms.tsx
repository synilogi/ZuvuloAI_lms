import { useId, useState, type FormEvent, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { Eye, EyeSlash } from '@phosphor-icons/react';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { fieldProps } from '@/lib/fieldProps';
import type { JoinFailure } from './joinFailure';
import styles from './Marketing.module.css';

/*
 * The learner's two ways through a join link (an invitation, or a course link): create an account in the LMS the link
 * names, or sign in with one already there. Neither form names a workspace or a role — the link does, on the server.
 * `onSubmit` resolves with what went wrong, if anything; a link that stopped working is the page's to show.
 */

const EMAIL = /^\S+@\S+\.\S+$/;

function PasswordInput({
  id,
  invalid,
  value,
  onChange,
  autoComplete,
}: {
  id: string;
  invalid: boolean;
  value: string;
  onChange: (v: string) => void;
  autoComplete: string;
}) {
  const [show, setShow] = useState(false);
  return (
    <div className={styles.passwordRow}>
      <Input
        {...fieldProps(id, true, invalid)}
        type={show ? 'text' : 'password'}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="••••••••"
        autoComplete={autoComplete}
      />
      <button type="button" className={styles.passwordToggle} onClick={() => setShow((v) => !v)} aria-label={show ? 'Hide password' : 'Show password'}>
        {show ? <EyeSlash size={18} /> : <Eye size={18} />}
      </button>
    </div>
  );
}

function FailureBanner({ failure }: { failure?: JoinFailure }) {
  if (!failure?.banner) return null;
  return (
    <InlineMessage kind="error" title={failure.banner.title}>
      {failure.banner.text}
    </InlineMessage>
  );
}

export interface CreateAccountInput {
  name: string;
  email: string;
  password: string;
  /** What an instructor teaches, when the form asks (`withTitle`). */
  title?: string;
}

export function CreateAccountForm({
  lmsName,
  fixedEmail,
  submitLabel = 'Create account',
  withTitle = false,
  onSubmit,
  footer,
}: {
  lmsName: string;
  /** Asks what the person teaches (optional): an instructor's request. */
  withTitle?: boolean;
  /** The address an invitation is bound to: shown, and not editable. */
  fixedEmail?: string | null;
  submitLabel?: string;
  onSubmit: (input: CreateAccountInput) => Promise<JoinFailure | undefined>;
  footer?: ReactNode;
}) {
  const nameId = useId();
  const titleId = useId();
  const emailId = useId();
  const passwordId = useId();
  const confirmId = useId();
  const agreeId = useId();
  const [name, setName] = useState('');
  const [title, setTitle] = useState('');
  const [email, setEmail] = useState(fixedEmail ?? '');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [agree, setAgree] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [failure, setFailure] = useState<JoinFailure>();
  const [submitting, setSubmitting] = useState(false);

  const local = {
    name: name.trim().length >= 2 ? undefined : 'Enter your full name.',
    email: EMAIL.test(email.trim()) ? undefined : 'Enter a valid email address.',
    password: password.length >= 8 ? undefined : 'Password must be at least 8 characters.',
    confirm: confirm.length > 0 && confirm === password ? undefined : 'Passwords must match.',
    agree: agree ? undefined : 'Agree to the Terms of Service and Privacy Policy to continue.',
  };
  const shown = attempt
    ? {
        name: local.name ?? failure?.fields.name,
        email: local.email ?? failure?.fields.email,
        password: local.password ?? failure?.fields.password,
        confirm: local.confirm,
        agree: local.agree,
      }
    : {};
  const issues: FieldIssue[] = [
    ...(shown.name ? [{ field: nameId, message: shown.name }] : []),
    ...(shown.email ? [{ field: emailId, message: shown.email }] : []),
    ...(shown.password ? [{ field: passwordId, message: shown.password }] : []),
    ...(shown.confirm ? [{ field: confirmId, message: shown.confirm }] : []),
    ...(shown.agree ? [{ field: agreeId, message: shown.agree }] : []),
  ];

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setFailure(undefined);
    if (Object.values(local).some(Boolean)) return;
    setSubmitting(true);
    try {
      setFailure(await onSubmit({ name: name.trim(), email: email.trim(), password, ...(withTitle && title.trim() ? { title: title.trim() } : {}) }));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      <FailureBanner failure={failure} />
      <ErrorSummary issues={issues} attempt={attempt} title="Fix these before creating your account" />
      <form className={styles.authForm} onSubmit={submit} noValidate>
        <Field label="Full name" error={shown.name}>
          <Input id={nameId} value={name} onChange={(e) => setName(e.target.value)} placeholder="Ananya Rao" autoComplete="name" />
        </Field>
        {withTitle && (
          <Field label="What you teach" hint="Optional — shown to the Admin with your request, for example “Physics, Class 11–12”.">
            <Input id={titleId} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Physics teacher" maxLength={120} />
          </Field>
        )}
        <Field
          label="Email address"
          error={shown.email}
          hint={fixedEmail ? `This invitation is for ${fixedEmail}.` : `We’ll email you a 6-digit code to confirm it. Your account belongs to ${lmsName} only.`}
        >
          <Input
            id={emailId}
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            readOnly={Boolean(fixedEmail)}
            placeholder="you@example.com"
            autoComplete="email"
          />
        </Field>
        <Field label="Password" id={passwordId} hint="At least 8 characters." error={shown.password}>
          <PasswordInput id={passwordId} invalid={Boolean(shown.password)} value={password} onChange={setPassword} autoComplete="new-password" />
        </Field>
        <Field label="Confirm password" error={shown.confirm}>
          <Input
            id={confirmId}
            type="password"
            value={confirm}
            onChange={(e) => setConfirm(e.target.value)}
            placeholder="••••••••"
            autoComplete="new-password"
          />
        </Field>
        <label className={styles.checkboxRow} htmlFor={agreeId}>
          <input id={agreeId} type="checkbox" checked={agree} onChange={(e) => setAgree(e.target.checked)} />
          <span>
            I agree to the{' '}
            <Link to="/terms" target="_blank" rel="noopener">
              Terms of Service
            </Link>{' '}
            and{' '}
            <Link to="/privacy" target="_blank" rel="noopener">
              Privacy Policy
            </Link>
            .
          </span>
        </label>
        <Button type="submit" variant="primary" size="lg" block loading={submitting}>
          {submitLabel}
        </Button>
      </form>
      {footer}
    </>
  );
}

export function SignInForm({
  fixedEmail,
  onSubmit,
  footer,
}: {
  fixedEmail?: string | null;
  onSubmit: (input: { email: string; password: string }) => Promise<JoinFailure | undefined>;
  footer?: ReactNode;
}) {
  const emailId = useId();
  const passwordId = useId();
  const [email, setEmail] = useState(fixedEmail ?? '');
  const [password, setPassword] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [failure, setFailure] = useState<JoinFailure>();
  const [submitting, setSubmitting] = useState(false);

  const local = {
    email: EMAIL.test(email.trim()) ? undefined : 'Enter a valid email address.',
    password: password.length > 0 ? undefined : 'Enter your password.',
  };
  const shown = attempt ? { email: local.email ?? failure?.fields.email, password: local.password ?? failure?.fields.password } : {};
  const issues: FieldIssue[] = [
    ...(shown.email ? [{ field: emailId, message: shown.email }] : []),
    ...(shown.password ? [{ field: passwordId, message: shown.password }] : []),
  ];

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setFailure(undefined);
    if (local.email || local.password) return;
    setSubmitting(true);
    try {
      setFailure(await onSubmit({ email: email.trim(), password }));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      <FailureBanner failure={failure} />
      <ErrorSummary issues={issues} attempt={attempt} title="Fix these before signing in" />
      <form className={styles.authForm} onSubmit={submit} noValidate>
        <Field label="Email address" error={shown.email}>
          <Input
            id={emailId}
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            readOnly={Boolean(fixedEmail)}
            placeholder="you@example.com"
            autoComplete="email"
          />
        </Field>
        <Field label="Password" id={passwordId} error={shown.password}>
          <PasswordInput id={passwordId} invalid={Boolean(shown.password)} value={password} onChange={setPassword} autoComplete="current-password" />
        </Field>
        <Button type="submit" variant="primary" size="lg" block loading={submitting}>
          Sign in and join
        </Button>
      </form>
      {footer}
    </>
  );
}
