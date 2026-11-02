import { useEffect, useId, useRef, useState, type FormEvent } from 'react';
import { Link, Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import { ArrowLeft, CheckCircle, EnvelopeSimple, Eye, EyeSlash } from '@phosphor-icons/react';
import type { BillingCycle, Plan, SignupPending } from '@syniastrolms/domain';
import { offeredCycles } from '@/pages/onboarding/welcomeFlow';
import { PlanOfferCard, PlanOfferNote } from '@/components/plan/PlanOfferCard';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { useAsync } from '@/hooks/useAsync';
import { fieldProps } from '@/lib/fieldProps';
import { homeFor } from '@/lib/roleHome';
import { API_MODE, useSession } from '@/providers/SessionProvider';
import { services, ServiceError } from '@/services';
import { DEMO_SIGNUP_CODE } from '@/services/mock/signup';
import { MarketingChrome } from '@/pages/marketing/MarketingChrome';
import { PageLoading } from '@/pages/PageLoading';
import {
  accountIssues,
  activatePath,
  choiceFromQuery,
  codeIssue,
  EMPTY_ACCOUNT,
  effectiveSlug,
  rememberedSignup,
  rememberSignup,
  resendWait,
  STEPS,
  type AccountForm,
  type GetStartedStep,
  type PlanChoice,
} from './getStartedFlow';
import styles from './GetStarted.module.css';

/*
 * Get started (SAAS-026): a visitor becomes an Admin with an academy of their own.
 *   1. choose a plan (or decide later) — the plans on sale, priced by the server;
 *   2. the organisation and the admin account;
 *   3. the 6-digit code emailed to them — the academy is created only when it is confirmed;
 *   4. their new academy's plan page (`/admin/welcome`), where the free trial or checkout activates the plan.
 * Nothing on this page grants a plan: a paid plan starts only when the payment is verified by the server.
 */
export default function GetStartedPage() {
  const { isAuthenticated, authLoading, role } = useSession();
  // Whether someone was already signed in when the page opened — decided once, so the session this page itself
  // starts (a verified registration) does not send the new admin away before the hand-off to their plan page.
  const signedInOnArrival = useRef<boolean | null>(null);
  if (signedInOnArrival.current === null && !authLoading) signedInOnArrival.current = isAuthenticated;
  if (API_MODE === 'http' && authLoading && signedInOnArrival.current === null) return <PageLoading />;
  // Someone already signed in has an account; their workspace is where they continue.
  if (API_MODE === 'http' && signedInOnArrival.current) return <Navigate to={homeFor(role)} replace />;
  return (
    <MarketingChrome>
      <GetStarted />
    </MarketingChrome>
  );
}

function GetStarted() {
  const [params] = useSearchParams();
  const catalogue = useAsync('public-plans', () => services.signup.plans());
  const [step, setStep] = useState<GetStartedStep>('plan');
  const [choice, setChoice] = useState<PlanChoice | null>(null);
  const [cycle, setCycle] = useState<BillingCycle>(params.get('cycle') === 'annual' ? 'annual' : 'monthly');
  const [pending, setPending] = useState<SignupPending | null>(null);
  const [form, setForm] = useState<AccountForm>(EMPTY_ACCOUNT);

  // The pricing page sends the visitor with a plan already chosen: go straight to the account.
  const plans = catalogue.data?.plans;
  useEffect(() => {
    if (!plans) return;
    const fromQuery = choiceFromQuery(params, plans);
    if (fromQuery) {
      setChoice(fromQuery);
      setCycle(fromQuery.cycle);
      setStep((s) => (s === 'plan' ? 'account' : s));
    }
    // Only when the plans first arrive.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [plans]);

  // A refresh at the code step carries on there: the open registration is read back from the server (SAAS-026).
  const [resuming, setResuming] = useState(() => Boolean(rememberedSignup()));
  useEffect(() => {
    const signupId = rememberedSignup();
    if (!signupId) return;
    services.signup
      .status(signupId)
      .then((open) => {
        setPending(open);
        if (open.choice) {
          setChoice(open.choice);
          setCycle(open.choice.cycle);
        }
        setStep('verify');
      })
      .catch(() => rememberSignup(null))
      .finally(() => setResuming(false));
  }, []);

  const chosenPlan = plans?.find((p) => p.id === choice?.planId);
  if (resuming) return <PageLoading />;

  return (
    <div className={styles.page}>
      <header className={styles.head}>
        <p className={styles.eyebrow}>Get started</p>
        <h1 className={styles.title}>Launch your LMS</h1>
        <p className={styles.lead}>
          Become an Admin with your own admin panel, instructors and learners — kept entirely separate from every other Admin on the platform.
        </p>
        <Stepper current={step} />
      </header>

      {step === 'plan' && (
        <PlanStep
          loading={catalogue.status === 'loading' && !catalogue.data}
          error={catalogue.status === 'error' ? (catalogue.error?.message ?? 'Something went wrong.') : undefined}
          onRetry={() => catalogue.run().catch(() => undefined)}
          plans={plans ?? []}
          cycle={cycle}
          onCycle={setCycle}
          chosenPlanId={choice?.planId}
          onChoose={(plan) => {
            setChoice(plan ? { planId: plan.id, cycle } : null);
            setStep('account');
          }}
        />
      )}
      {step === 'account' && (
        <AccountStep
          form={form}
          onChange={setForm}
          chosen={chosenPlan && choice ? { plan: chosenPlan, cycle: choice.cycle } : null}
          onChangePlan={() => setStep('plan')}
          onPending={(p) => {
            rememberSignup(p.signupId);
            setPending(p);
            setStep('verify');
          }}
          choice={choice}
        />
      )}
      {step === 'verify' && pending && (
        <VerifyStep
          pending={pending}
          onResent={setPending}
          onBack={() => {
            rememberSignup(null);
            setPending(null);
            setStep('account');
          }}
          choice={choice}
        />
      )}
    </div>
  );
}

function Stepper({ current }: { current: GetStartedStep }) {
  const index = STEPS.findIndex((s) => s.id === current);
  return (
    <ol className={styles.stepper} aria-label="Registration steps">
      {STEPS.map((s, i) => (
        <li key={s.id} className={i < index ? styles.stepDone : i === index ? styles.stepCurrent : styles.step} aria-current={i === index ? 'step' : undefined}>
          <span className={styles.stepIndex} aria-hidden="true">
            {i < index ? <CheckCircle size={16} weight="fill" /> : i + 1}
          </span>
          <span>{s.label}</span>
        </li>
      ))}
    </ol>
  );
}

function PlanStep({
  loading,
  error,
  onRetry,
  plans,
  cycle,
  onCycle,
  chosenPlanId,
  onChoose,
}: {
  loading: boolean;
  error?: string;
  onRetry: () => void;
  plans: Plan[];
  cycle: BillingCycle;
  onCycle: (c: BillingCycle) => void;
  chosenPlanId?: string;
  onChoose: (plan: Plan | null) => void;
}) {
  if (error) {
    return (
      <StateMessage
        kind="error"
        title="The plans didn’t load"
        actions={
          <>
            <Button variant="primary" onClick={onRetry}>
              Try again
            </Button>
            <Button onClick={() => onChoose(null)}>Continue without a plan</Button>
          </>
        }
      >
        {error} You can still create your account and choose a plan from your admin panel.
      </StateMessage>
    );
  }
  if (loading) {
    return (
      <div className={styles.plans} role="status" aria-label="Loading the plans">
        {[0, 1, 2].map((i) => (
          <Skeleton key={i} height={420} radius="var(--r-lg)" />
        ))}
      </div>
    );
  }
  const sorted = [...plans].sort((a, b) => a.order - b.order);
  const cycles = offeredCycles(sorted);
  return (
    <section aria-labelledby="gs-plans" className={styles.section}>
      <div className={styles.controls}>
        <h2 id="gs-plans" className={styles.sectionTitle}>
          Choose a plan
        </h2>
        {cycles.length > 1 && (
          <SegmentedControl<BillingCycle>
            label="Billing cycle"
            value={cycle}
            onChange={onCycle}
            segments={[
              { value: 'monthly', label: 'Monthly' },
              { value: 'annual', label: 'Annual' },
            ]}
          />
        )}
      </div>
      {sorted.length === 0 ? (
        <StateMessage title="No plans are on sale yet" actions={<Button onClick={() => onChoose(null)}>Continue</Button>}>
          Create your account now; the platform team will help you choose a plan.
        </StateMessage>
      ) : (
        <ul className={styles.plans}>
          {sorted.map((p) => (
            <PlanOfferCard
              key={p.id}
              plan={p}
              cycle={cycle}
              highlighted={p.id === chosenPlanId}
              actions={
                <>
                  <Button variant={p.id === chosenPlanId ? 'primary' : 'secondary'} block disabled={!p.cycles.includes(cycle)} onClick={() => onChoose(p)}>
                    Choose {p.name}
                  </Button>
                  <PlanOfferNote>
                    {p.trialEnabled && p.trialDays > 0
                      ? `Start with a ${p.trialDays}-day free trial — no payment needed.`
                      : 'Pay securely once your LMS is created.'}
                  </PlanOfferNote>
                </>
              }
            />
          ))}
        </ul>
      )}
      <p className={styles.skip}>
        Not sure yet?{' '}
        <button type="button" className={styles.linkButton} onClick={() => onChoose(null)}>
          Create your account first
        </button>{' '}
        and choose a plan from your admin panel.
      </p>
    </section>
  );
}

/** Whole minutes until the emailed code expires. */
const codeMinutesLeft = (expiresAt: string, now: number) => Math.max(0, Math.ceil((Date.parse(expiresAt) - now) / 60_000));

const FIELD_ORDER: (keyof AccountForm)[] = ['academyName', 'slug', 'name', 'email', 'password', 'confirm', 'agree'];

function AccountStep({
  form,
  onChange,
  chosen,
  onChangePlan,
  onPending,
  choice,
}: {
  form: AccountForm;
  onChange: (f: AccountForm) => void;
  chosen: { plan: Plan; cycle: BillingCycle } | null;
  onChangePlan: () => void;
  onPending: (p: SignupPending) => void;
  choice: PlanChoice | null;
}) {
  const navigate = useNavigate();
  const toast = useToast();
  const { adopt } = useSession();
  const ids = { academyName: useId(), slug: useId(), name: useId(), email: useId(), password: useId(), confirm: useId(), agree: useId() };
  const [attempt, setAttempt] = useState(0);
  const [serverError, setServerError] = useState<string>();
  // The server's own per-field refusals (an address or email already taken), shown beside their fields.
  const [serverFields, setServerFields] = useState<Partial<Record<keyof AccountForm, string>>>({});
  const [submitting, setSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const issues = accountIssues(form);
  const shown: Partial<Record<keyof AccountForm, string>> = attempt > 0 ? { ...serverFields, ...issues } : {};
  const summary: FieldIssue[] = [
    ...FIELD_ORDER.filter((k) => shown[k]).map((k) => ({ field: ids[k as keyof typeof ids], message: shown[k]! })),
    ...(serverError ? [{ field: ids.email, message: serverError }] : []),
  ];
  const set = (patch: Partial<AccountForm>) => {
    setServerError(undefined);
    setServerFields((f) => Object.fromEntries(Object.entries(f).filter(([k]) => !(k in patch) && !(k === 'slug' && 'academyName' in patch))));
    onChange({ ...form, ...patch });
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    setServerFields({});
    if (Object.keys(issues).length) return;
    setSubmitting(true);
    try {
      const result = await services.signup.start({
        academyName: form.academyName.trim(),
        slug: effectiveSlug(form),
        name: form.name.trim(),
        email: form.email.trim(),
        password: form.password,
        acceptTerms: true,
        ...(choice ? { planId: choice.planId, cycle: choice.cycle } : {}),
      });
      if (result.status === 'verify') {
        onPending(result);
        return;
      }
      adopt(result);
      toast({ kind: 'success', title: 'Your LMS is ready', text: `Welcome, ${result.user.name.split(' ')[0]}.` });
      navigate(activatePath(choice), { replace: true });
    } catch (err) {
      const fields: Partial<Record<keyof AccountForm, string>> = {};
      for (const issue of err instanceof ServiceError ? (err.issues ?? []) : [])
        if ((FIELD_ORDER as string[]).includes(issue.field)) fields[issue.field as keyof AccountForm] ??= issue.message;
      setServerFields(fields);
      setServerError(Object.keys(fields).length ? undefined : err instanceof Error ? err.message : 'Your account could not be created.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section aria-labelledby="gs-account" className={styles.formCard}>
      <h2 id="gs-account" className={styles.sectionTitle}>
        Your organisation and admin account
      </h2>
      {chosen ? (
        <p className={styles.chosen}>
          Plan: <strong>{chosen.plan.name}</strong> ({chosen.cycle === 'annual' ? 'annual' : 'monthly'}){' '}
          <button type="button" className={styles.linkButton} onClick={onChangePlan}>
            Change
          </button>
        </p>
      ) : (
        <p className={styles.chosen}>
          No plan chosen yet —{' '}
          <button type="button" className={styles.linkButton} onClick={onChangePlan}>
            see plans
          </button>
          , or choose one after signing in.
        </p>
      )}

      <ErrorSummary issues={summary} attempt={attempt} title="Fix these before creating your LMS" />

      <form className={styles.form} onSubmit={submit} noValidate>
        <Field label="Organisation name" error={shown.academyName}>
          <Input
            id={ids.academyName}
            value={form.academyName}
            onChange={(e) => set({ academyName: e.target.value })}
            placeholder="Saraswati Coaching"
            autoComplete="organization"
          />
        </Field>
        <Field
          label="LMS address"
          id={ids.slug}
          hint={`Learners join at ${window.location.host}/join/${effectiveSlug(form) || 'your-academy'}`}
          error={shown.slug}
        >
          <Input
            id={ids.slug}
            value={form.slugEdited ? form.slug : effectiveSlug(form)}
            onChange={(e) => set({ slug: e.target.value.toLowerCase(), slugEdited: true })}
            placeholder="saraswati-coaching"
            autoCapitalize="none"
            spellCheck={false}
          />
        </Field>
        <Field label="Your full name" error={shown.name}>
          <Input id={ids.name} value={form.name} onChange={(e) => set({ name: e.target.value })} placeholder="Ananya Rao" autoComplete="name" />
        </Field>
        <Field label="Work email" hint="We’ll send a 6-digit code to verify it." error={shown.email}>
          <Input
            id={ids.email}
            type="email"
            value={form.email}
            onChange={(e) => set({ email: e.target.value })}
            placeholder="you@yourschool.com"
            autoComplete="email"
          />
        </Field>
        <Field label="Password" id={ids.password} hint="At least 8 characters." error={shown.password}>
          <div className={styles.passwordRow}>
            <Input
              {...fieldProps(ids.password, true, !!shown.password)}
              type={showPassword ? 'text' : 'password'}
              value={form.password}
              onChange={(e) => set({ password: e.target.value })}
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
        <Field label="Confirm password" error={shown.confirm}>
          <Input
            id={ids.confirm}
            type={showPassword ? 'text' : 'password'}
            value={form.confirm}
            onChange={(e) => set({ confirm: e.target.value })}
            autoComplete="new-password"
          />
        </Field>
        <label className={styles.checkboxRow} htmlFor={ids.agree}>
          <input id={ids.agree} type="checkbox" checked={form.agree} onChange={(e) => set({ agree: e.target.checked })} />
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
          Continue
        </Button>
      </form>
      <p className={styles.switch}>
        Already have an account? <Link to="/login">Sign in</Link>
      </p>
    </section>
  );
}

function VerifyStep({
  pending,
  onResent,
  onBack,
  choice,
}: {
  pending: SignupPending;
  onResent: (p: SignupPending) => void;
  onBack: () => void;
  choice: PlanChoice | null;
}) {
  const navigate = useNavigate();
  const toast = useToast();
  const { adopt } = useSession();
  const codeId = useId();
  const [code, setCode] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [error, setError] = useState<string>();
  const [submitting, setSubmitting] = useState(false);
  const [resending, setResending] = useState(false);
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const t = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(t);
  }, []);
  const wait = resendWait(pending.resendAvailableAt, now);
  const localIssue = attempt > 0 ? codeIssue(code) : undefined;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setError(undefined);
    if (codeIssue(code)) return;
    setSubmitting(true);
    try {
      const created = await services.signup.verify(pending.signupId, code);
      rememberSignup(null);
      adopt(created);
      toast({ kind: 'success', title: 'Your LMS is ready', text: 'Now activate your plan.' });
      navigate(activatePath(created.choice ?? choice), { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'The code could not be checked.');
    } finally {
      setSubmitting(false);
    }
  };

  const resend = async () => {
    setResending(true);
    setError(undefined);
    try {
      onResent(await services.signup.resend(pending.signupId));
      setCode('');
      toast({ kind: 'success', title: 'A new code is on its way', text: `Sent to ${pending.email}.` });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'A new code could not be sent.');
    } finally {
      setResending(false);
    }
  };

  return (
    <section aria-labelledby="gs-verify" className={styles.formCard}>
      <span className={styles.verifyIcon} aria-hidden="true">
        <EnvelopeSimple size={26} />
      </span>
      <h2 id="gs-verify" className={styles.sectionTitle}>
        Check your email
      </h2>
      <p className={styles.lead}>
        We sent a 6-digit code to <strong>{pending.email}</strong>. Your LMS is created as soon as you enter it.{' '}
        {codeMinutesLeft(pending.expiresAt, now) > 0
          ? `The code works for ${codeMinutesLeft(pending.expiresAt, now)} more minute${codeMinutesLeft(pending.expiresAt, now) === 1 ? '' : 's'}.`
          : 'The code has expired — ask for a new one.'}
      </p>
      {API_MODE === 'mock' && (
        <InlineMessage kind="info" title="Demo build">
          No email is sent here. Use the code {DEMO_SIGNUP_CODE}.
        </InlineMessage>
      )}
      {error && (
        <InlineMessage kind="error" title="That didn’t work.">
          {error}
        </InlineMessage>
      )}
      <form className={styles.form} onSubmit={submit} noValidate>
        <Field label="Verification code" error={localIssue}>
          <Input
            id={codeId}
            className={styles.codeInput}
            value={code}
            onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
            inputMode="numeric"
            autoComplete="one-time-code"
            placeholder="000000"
            maxLength={6}
          />
        </Field>
        <Button type="submit" variant="primary" size="lg" block loading={submitting}>
          Verify and create LMS
        </Button>
      </form>
      <div className={styles.verifyActions}>
        <Button variant="ghost" size="sm" onClick={onBack} iconStart={<ArrowLeft size={14} />}>
          Change details
        </Button>
        <Button variant="ghost" size="sm" onClick={resend} disabled={wait > 0} loading={resending}>
          {wait > 0 ? `Resend code in ${wait}s` : 'Resend code'}
        </Button>
      </div>
    </section>
  );
}
