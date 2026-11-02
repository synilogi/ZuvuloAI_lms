import { useId, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import type { AccountVerificationPending } from '@syniastrolms/domain';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { services, ServiceError } from '@/services';
import { EmailCodeStep } from './EmailCodeStep';
import { isPhone } from './registrationCode';
import { AuthChrome } from './MarketingChrome';
import styles from './Marketing.module.css';

/** Splits what was typed into its parts: subjects by comma, links by line. */
export const listFrom = (text: string, separator: RegExp) =>
  text
    .split(separator)
    .map((part) => part.trim())
    .filter(Boolean);

/*
 * An instructor applies to teach (docs/16, D-PLAT-06): their account details and professional profile, confirmed with a
 * 6-digit code emailed to the address. The application then waits for approval, and nobody is signed in until it is given.
 */
export default function TeachRequestPage() {
  const agreeId = useId();
  const [form, setForm] = useState({ name: '', email: '', phone: '', password: '', title: '', years: '', expertise: '', bio: '', links: '' });
  const [agree, setAgree] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const [serverError, setServerError] = useState<string>();
  const [serverFields, setServerFields] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [pending, setPending] = useState<AccountVerificationPending>();
  const [waiting, setWaiting] = useState<string>();
  const set = (key: keyof typeof form) => (e: { target: { value: string } }) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const expertise = listFrom(form.expertise, /,/);
  const links = listFrom(form.links, /\s*\n\s*/);
  const years = Number(form.years);
  const local: Record<string, string | undefined> = {
    name: form.name.trim().length >= 2 ? undefined : 'Enter your full name.',
    email: /\S+@\S+\.\S+/.test(form.email) ? undefined : 'Enter a valid email address.',
    phone: isPhone(form.phone) ? undefined : 'Enter a valid mobile number.',
    password: form.password.length >= 8 ? undefined : 'Password must be at least 8 characters.',
    title: form.title.trim().length >= 2 ? undefined : 'Say what you teach, in a few words.',
    yearsTeaching:
      form.years.trim() !== '' && Number.isInteger(years) && years >= 0 && years <= 70 ? undefined : 'Enter your years of experience, as a whole number.',
    expertise: expertise.length ? undefined : 'Name at least one subject.',
    bio: form.bio.trim().length >= 30 ? undefined : 'Tell us about your teaching, in at least 30 characters.',
    links: links.every((l) => /^https?:\/\/\S+$/i.test(l)) ? undefined : 'Each link must start with http:// or https://.',
  };
  const errorFor = (key: string) => (attempt > 0 ? (local[key] ?? serverFields[key]) : undefined);
  const allIssues: FieldIssue[] = [
    ...Object.keys(local).flatMap((key) => (errorFor(key) ? [{ field: `apply-${key}`, message: errorFor(key)! }] : [])),
    ...(!agree ? [{ field: agreeId, message: 'Agree to the Terms of Service and Privacy Policy to continue.' }] : []),
    ...(serverError ? [{ field: 'apply-email', message: serverError }] : []),
  ];
  const issues = attempt ? allIssues : [];

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    setServerFields({});
    if (Object.values(local).some(Boolean) || !agree) return;
    setSubmitting(true);
    try {
      const result = await services.signup.applyToTeach({
        name: form.name.trim(),
        email: form.email.trim(),
        phone: form.phone.trim(),
        password: form.password,
        title: form.title.trim(),
        bio: form.bio.trim(),
        expertise,
        yearsTeaching: years,
        links,
      });
      if (result.status === 'verify') setPending(result);
      else setWaiting(result.message);
    } catch (err) {
      const fields: Record<string, string> = {};
      for (const issue of err instanceof ServiceError ? (err.issues ?? []) : []) fields[issue.field.split('.')[0]] ??= issue.message;
      const known = Object.keys(fields).filter((key) => key in local);
      setServerFields(fields);
      setServerError(known.length ? undefined : err instanceof Error ? err.message : 'Your application wasn’t sent.');
    } finally {
      setSubmitting(false);
    }
  };

  if (waiting) {
    return (
      <AuthChrome eyebrow="Apply to teach">
        <StateMessage title="Your application is being reviewed" actions={<Link to="/login">Go to sign in</Link>}>
          {waiting} We’ve emailed you a confirmation, and we’ll email again with the decision.
        </StateMessage>
      </AuthChrome>
    );
  }
  if (pending) {
    return (
      <AuthChrome eyebrow="Apply to teach">
        <EmailCodeStep
          pending={pending}
          confirmLabel="Verify and send application"
          onConfirmed={(result) => {
            if (result.status === 'pending') setWaiting(result.message);
          }}
          onBack={() => setPending(undefined)}
        />
      </AuthChrome>
    );
  }

  return (
    <AuthChrome eyebrow="Apply to teach">
      <h1 className={styles.authTitle}>Teach on ZuviloAI</h1>
      <p className={styles.authSubtitle}>Tell us about yourself and what you teach. We review every application before you can sign in.</p>
      <ErrorSummary issues={issues} attempt={attempt} title="Fix these before sending your application" />
      <form className={styles.authForm} onSubmit={submit} noValidate>
        <Field label="Full name" error={errorFor('name')}>
          <Input id="apply-name" value={form.name} onChange={set('name')} autoComplete="name" />
        </Field>
        <Field label="Email address" hint="We’ll email you a 6-digit code to confirm it." error={errorFor('email')}>
          <Input id="apply-email" type="email" value={form.email} onChange={set('email')} placeholder="you@example.com" autoComplete="email" />
        </Field>
        <Field label="Mobile number" error={errorFor('phone')}>
          <Input id="apply-phone" type="tel" value={form.phone} onChange={set('phone')} placeholder="+91 98765 43210" autoComplete="tel" />
        </Field>
        <Field label="Password" hint="At least 8 characters." error={errorFor('password')}>
          <Input id="apply-password" type="password" value={form.password} onChange={set('password')} autoComplete="new-password" />
        </Field>
        <Field label="What you teach" hint="A short professional title, such as Mathematics teacher." error={errorFor('title')}>
          <Input id="apply-title" value={form.title} onChange={set('title')} maxLength={120} />
        </Field>
        <Field label="Years of teaching experience" error={errorFor('yearsTeaching')}>
          <Input id="apply-yearsTeaching" type="number" min={0} max={70} value={form.years} onChange={set('years')} />
        </Field>
        <Field label="Subjects" hint="Separate subjects with commas." error={errorFor('expertise')}>
          <Input id="apply-expertise" value={form.expertise} onChange={set('expertise')} placeholder="Algebra, Geometry" />
        </Field>
        <Field label="About your teaching" error={errorFor('bio')}>
          <Textarea id="apply-bio" rows={4} value={form.bio} onChange={set('bio')} maxLength={2000} />
        </Field>
        <Field label="Links (optional)" hint="A portfolio or profile, one per line." error={errorFor('links')}>
          <Textarea id="apply-links" rows={2} value={form.links} onChange={set('links')} placeholder="https://" />
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
          Send application
        </Button>
      </form>
      <p className={styles.authSwitch}>
        Already have an account? <Link to="/login">Sign in</Link> · Here to learn? <Link to="/register">Create a learner account</Link>
      </p>
    </AuthChrome>
  );
}
