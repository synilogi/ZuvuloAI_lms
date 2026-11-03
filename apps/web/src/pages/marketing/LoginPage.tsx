import { useId, useState, type FormEvent } from 'react';
import { Link, Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import type { Role } from '@syniastrolms/domain';
import { Eye, EyeSlash } from '@phosphor-icons/react';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { ServiceError } from '@/services';
import { ChoiceCards, ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { API_MODE, useSession } from '@/providers/SessionProvider';
import { safeNext } from '@/lib/safeNext';
import { fieldProps } from '@/lib/fieldProps';
import { personas, type DemoRole } from '@/services/mock/fixtures/learner';
import * as httpAuth from '@/services/http/auth';
import { AuthChrome } from './MarketingChrome';
import styles from './Marketing.module.css';

const ROLE_HOME: Record<Role, string> = { student: '/home', instructor: '/teach', admin: '/admin', superadmin: '/superadmin' };
// The demo build signs in as one of the three personas it ships; Super Admin has none.
const ROLE_CHOICES: { value: DemoRole; label: string; description: string }[] = [
  { value: 'student', label: 'Learner', description: 'Study courses, join live classes.' },
  { value: 'instructor', label: 'Instructor', description: 'Teach courses, grade submissions.' },
  { value: 'admin', label: 'Admin', description: 'Run the platform.' },
];

function ForgotPasswordModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const toast = useToast();
  const [email, setEmail] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [sending, setSending] = useState(false);
  const valid = /\S+@\S+\.\S+/.test(email);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    if (!valid) return;
    if (API_MODE === 'http') {
      setSending(true);
      try {
        await httpAuth.forgotPassword(email);
      } catch (err) {
        toast({ kind: 'error', title: 'Could not send the link', text: err instanceof Error ? err.message : 'Try again in a moment.' });
        setSending(false);
        return;
      }
      setSending(false);
    }
    toast({ kind: 'success', title: 'Reset link sent', text: `If ${email} matches an account, a reset link is on its way.` });
    setEmail('');
    onClose();
  };

  return (
    <Modal open={open} onClose={onClose} title="Reset your password" description="We'll email you a link to choose a new one." width={420}>
      <form className={styles.modalForm} onSubmit={submit}>
        <Field label="Email address" error={attempt > 0 && !valid ? 'Enter a valid email address.' : undefined}>
          <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" autoFocus />
        </Field>
        <Button type="submit" variant="primary" block loading={sending}>
          Send reset link
        </Button>
      </form>
    </Modal>
  );
}

/** Sign in — real accounts in http mode; in the demo build it hands off into whichever workspace the visitor picks. */
export default function LoginPage() {
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const { switchRole, login, isAuthenticated, role: sessionRole } = useSession();
  const toast = useToast();
  const passwordId = useId();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [role, setRole] = useState<DemoRole>('student');
  const [attempt, setAttempt] = useState(0);
  const [forgotOpen, setForgotOpen] = useState(false);
  const [serverError, setServerError] = useState<string>();
  const [submitting, setSubmitting] = useState(false);
  // An account of a workspace that has closed (docs/16, D-PLAT-02): said plainly, apart from a wrong password.
  const [closed, setClosed] = useState(() => params.get('closed') === 'workspace');

  const emailValid = /\S+@\S+\.\S+/.test(email);
  const passwordValid = password.length > 0;
  const allIssues: FieldIssue[] = [
    ...(!emailValid ? [{ field: 'login-email', message: 'Enter a valid email address.' }] : []),
    ...(!passwordValid ? [{ field: passwordId, message: 'Enter your password.' }] : []),
    // The server's answer is about the last submitted credentials: once a field is invalid again it is
    // stale, and it would repeat the email field's issue.
    ...(serverError && emailValid && passwordValid ? [{ field: 'login-email', message: serverError }] : []),
  ];
  const issues = attempt ? allIssues : [];

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    if (!emailValid || !passwordValid) return;

    if (API_MODE === 'http') {
      setSubmitting(true);
      try {
        const user = await login(email, password);
        toast({ kind: 'success', title: `Signed in as ${user.name}`, text: user.descriptor });
        navigate(safeNext(params.get('next'), ROLE_HOME[user.role]), { replace: true });
      } catch (err) {
        const reason = err instanceof ServiceError ? err.reason : undefined;
        if (reason === 'WORKSPACE_CLOSED') setClosed(true);
        else setServerError(err instanceof Error ? err.message : 'Could not sign in.');
      } finally {
        setSubmitting(false);
      }
      return;
    }

    switchRole(role);
    toast({ kind: 'success', title: `Signed in as ${personas[role].name}`, text: personas[role].descriptor });
    navigate(ROLE_HOME[role], { replace: true });
  };

  // Already signed in (opening an old link, or back after a dropped connection): straight on to where they were going.
  if (API_MODE === 'http' && isAuthenticated && !submitting) return <Navigate to={safeNext(params.get('next'), ROLE_HOME[sessionRole])} replace />;

  return (
    <AuthChrome eyebrow="Welcome back">
      <h1 className={styles.authTitle}>Sign in to ZuviloAI</h1>
      <p className={styles.authSubtitle}>Continue your courses, catch up on live classes, or pick up a review queue.</p>

      {closed && (
        <InlineMessage kind="warn" title="This account has been closed.">
          Its records are kept. If you think this is a mistake, <Link to="/contact?topic=support">contact support</Link>.
        </InlineMessage>
      )}
      <ErrorSummary issues={issues} attempt={attempt} title="Fix these before signing in" />

      <form className={styles.authForm} onSubmit={submit} noValidate>
        <Field label="Email address" error={attempt > 0 && !emailValid ? 'Enter a valid email address.' : undefined}>
          <Input id="login-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" autoComplete="email" />
        </Field>
        <Field label="Password" id={passwordId} error={attempt > 0 && !passwordValid ? 'Enter your password.' : undefined}>
          <div className={styles.passwordRow}>
            <Input
              {...fieldProps(passwordId, true, attempt > 0 && !passwordValid)}
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              autoComplete="current-password"
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
        <button type="button" className={styles.forgotLink} onClick={() => setForgotOpen(true)}>
          Forgot your password?
        </button>

        {API_MODE === 'mock' && <ChoiceCards legend="Continue as" value={role} onChange={setRole} choices={ROLE_CHOICES} columns={1} />}

        <Button type="submit" variant="primary" size="lg" block loading={submitting}>
          Sign in
        </Button>
      </form>

      <p className={styles.authSwitch}>
        New here? <Link to="/register">Create your account</Link>.
      </p>

      <ForgotPasswordModal open={forgotOpen} onClose={() => setForgotOpen(false)} />
    </AuthChrome>
  );
}
