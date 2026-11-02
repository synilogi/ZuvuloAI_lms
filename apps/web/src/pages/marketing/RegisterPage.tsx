import { safeNext } from '@/lib/safeNext';
import { useId, useState, type FormEvent } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Eye, EyeSlash } from '@phosphor-icons/react';
import { legFromLink, type AccountCreated, type AccountVerificationPending } from '@syniastrolms/domain';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { useAsync } from '@/hooks/useAsync';
import { fieldProps } from '@/lib/fieldProps';
import { useSession } from '@/providers/SessionProvider';
import { services, ServiceError } from '@/services';
import { EmailCodeStep } from './EmailCodeStep';
import { isPhone } from './registrationCode';
import { AuthChrome } from './MarketingChrome';
import styles from './Marketing.module.css';

type ServerField = 'name' | 'email' | 'phone' | 'password';

/*
 * A learner registers (docs/16, D-PLAT-06): name, email, mobile number and password, then a 6-digit code emailed to the
 * address before the account exists. Instructors apply at `/teach/apply`. A referral link (MLM-001) lands here with the
 * sponsor's code and the leg they chose; both ride along to the server, which checks them. The leg is where this person
 * sits under the sponsor, not where their own referrals go.
 */
export default function RegisterPage() {
  const navigate = useNavigate();
  const [search] = useSearchParams();
  const referralCode = search.get('ref')?.trim().toUpperCase() || undefined;
  const requestedLeg = legFromLink(search.get('leg'));
  const referral = useAsync(`register:ref:${referralCode ?? ''}`, () => (referralCode ? services.affiliate.referral(referralCode) : Promise.resolve(null)));
  const { adopt } = useSession();
  const toast = useToast();
  const passwordId = useId();
  const confirmId = useId();
  const agreeId = useId();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [agree, setAgree] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [serverError, setServerError] = useState<string>();
  const [serverFields, setServerFields] = useState<Partial<Record<ServerField, string>>>({});
  const [submitting, setSubmitting] = useState(false);
  const [pending, setPending] = useState<AccountVerificationPending>();

  const welcome = (session: AccountCreated) => {
    adopt(session);
    toast({ kind: 'success', title: `Welcome, ${name.trim().split(' ')[0]}!`, text: 'Your account is ready. Find your first course.' });
    navigate(safeNext(search.get('next'), '/explore'), { replace: true });
  };

  const nameValid = name.trim().length >= 2;
  const emailValid = /\S+@\S+\.\S+/.test(email);
  const phoneValid = isPhone(phone);
  const passwordValid = password.length >= 8;
  const confirmValid = confirm.length > 0 && confirm === password;

  const allIssues: FieldIssue[] = [
    ...(!nameValid ? [{ field: 'register-name', message: 'Enter your full name.' }] : []),
    ...(nameValid && serverFields.name ? [{ field: 'register-name', message: serverFields.name }] : []),
    ...(!emailValid ? [{ field: 'register-email', message: 'Enter a valid email address.' }] : []),
    ...(emailValid && serverFields.email ? [{ field: 'register-email', message: serverFields.email }] : []),
    ...(!phoneValid ? [{ field: 'register-phone', message: 'Enter a valid mobile number.' }] : []),
    ...(phoneValid && serverFields.phone ? [{ field: 'register-phone', message: serverFields.phone }] : []),
    ...(!passwordValid ? [{ field: passwordId, message: 'Password must be at least 8 characters.' }] : []),
    ...(passwordValid && serverFields.password ? [{ field: passwordId, message: serverFields.password }] : []),
    ...(!confirmValid ? [{ field: confirmId, message: 'Passwords must match.' }] : []),
    ...(!agree ? [{ field: agreeId, message: 'Agree to the Terms of Service and Privacy Policy to continue.' }] : []),
    ...(serverError ? [{ field: 'register-email', message: serverError }] : []),
  ];
  const issues = attempt ? allIssues : [];

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    setServerFields({});
    if (!nameValid || !emailValid || !phoneValid || !passwordValid || !confirmValid || !agree) return;
    setSubmitting(true);
    try {
      const result = await services.signup.register({
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password,
        // A code the server already refused is dropped: the learner still registers, just not in the program.
        referralCode: referral.status === 'error' ? undefined : referralCode,
        requestedLeg: referral.status === 'error' ? undefined : requestedLeg,
      });
      if (result.status === 'verify') setPending(result);
      else welcome(result);
    } catch (err) {
      // A field the server named goes beside it; anything else above the form.
      const fields: typeof serverFields = {};
      for (const issue of err instanceof ServiceError ? (err.issues ?? []) : []) {
        if (issue.field === 'name' || issue.field === 'email' || issue.field === 'phone' || issue.field === 'password') fields[issue.field] ??= issue.message;
      }
      setServerFields(fields);
      setServerError(Object.keys(fields).length ? undefined : err instanceof Error ? err.message : 'Could not create your account.');
    } finally {
      setSubmitting(false);
    }
  };

  if (pending) {
    return (
      <AuthChrome eyebrow="Create your account">
        <EmailCodeStep
          pending={pending}
          confirmLabel="Verify and create account"
          onConfirmed={(result) => {
            if (result.status === 'created') welcome(result);
          }}
          onBack={() => setPending(undefined)}
        />
      </AuthChrome>
    );
  }

  return (
    <AuthChrome eyebrow="Create your account">
      <h1 className={styles.authTitle}>Start learning on ZuviloAI</h1>
      <p className={styles.authSubtitle}>Create your account, then explore the courses and enrol.</p>
      {referralCode && (
        <p className={styles.authSubtitle} data-testid="referral-note">
          {referral.data
            ? `Invited by ${referral.data.sponsor.name} · you join their affiliate team.`
            : referral.status === 'error'
              ? 'This referral code isn’t valid; you can still register without it.'
              : 'Checking your referral…'}
        </p>
      )}

      <ErrorSummary issues={issues} attempt={attempt} title="Fix these before creating your account" />

      <form className={styles.authForm} onSubmit={submit} noValidate>
        <Field label="Full name" error={attempt > 0 ? (!nameValid ? 'Enter your full name.' : serverFields.name) : undefined}>
          <Input id="register-name" value={name} onChange={(e) => setName(e.target.value)} placeholder="Ananya Rao" autoComplete="name" />
        </Field>
        <Field
          label="Email address"
          hint="We’ll email you a 6-digit code to confirm it."
          error={attempt > 0 ? (!emailValid ? 'Enter a valid email address.' : serverFields.email) : undefined}
        >
          <Input id="register-email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" autoComplete="email" />
        </Field>
        <Field label="Mobile number" error={attempt > 0 ? (!phoneValid ? 'Enter a valid mobile number.' : serverFields.phone) : undefined}>
          <Input id="register-phone" type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+91 98765 43210" autoComplete="tel" />
        </Field>
        <Field
          label="Password"
          id={passwordId}
          hint="At least 8 characters."
          error={attempt > 0 ? (!passwordValid ? 'Password must be at least 8 characters.' : serverFields.password) : undefined}
        >
          <div className={styles.passwordRow}>
            <Input
              {...fieldProps(passwordId, true, attempt > 0 && !passwordValid)}
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              autoComplete="new-password"
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
        <Field label="Confirm password" error={attempt > 0 && !confirmValid ? 'Passwords must match.' : undefined}>
          <Input
            id={confirmId}
            type={showPassword ? 'text' : 'password'}
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
          Create account
        </Button>
      </form>

      <p className={styles.authSwitch}>
        Already have an account? <Link to="/login">Sign in</Link> · Want to teach? <Link to="/teach/apply">Apply as an instructor</Link>
      </p>
    </AuthChrome>
  );
}
