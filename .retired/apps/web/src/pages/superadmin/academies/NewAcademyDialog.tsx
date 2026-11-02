import { useEffect, useState, type FormEvent } from 'react';
import { Copy, Eye, EyeSlash, Sparkle } from '@phosphor-icons/react';
import { ErrorSummary } from '@/components/forms/Forms';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { generatePassword } from '@/lib/password';
import { services, type PlatformAcademy } from '@/services';
import { academyFormIssues, academyInput, emptyAcademyForm, serverIssueField, withName, withSlug, type AcademyForm } from './academyMeta';
import platformStyles from '../Platform.module.css';
import styles from './Academies.module.css';

const issueFor = (issues: { field: string; message: string }[], field: string, attempt: number) =>
  attempt > 0 ? issues.find((i) => i.field === field)?.message : undefined;

/**
 * A new customer: their academy and its first admin, created together. The academy starts empty — no courses, no
 * learners, no demo content — and on no plan; its admin chooses a plan or starts a free trial on first sign-in.
 * The password is shown back once, on the academy's page, and never again.
 */
export function NewAcademyDialog({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: (academy: PlatformAcademy, password: string) => void;
}) {
  const toast = useToast();
  const [form, setForm] = useState<AcademyForm>(emptyAcademyForm);
  const [attempt, setAttempt] = useState(0);
  const [showPassword, setShowPassword] = useState(false);
  const [saving, setSaving] = useState(false);
  const [serverError, setServerError] = useState<{ field: string; message: string }>();

  useEffect(() => {
    if (open) {
      setForm(emptyAcademyForm());
      setAttempt(0);
      setSaving(false);
      setServerError(undefined);
      setShowPassword(false);
    }
  }, [open]);

  const issues = academyFormIssues(form);
  const shown = [...(attempt ? issues : []), ...(serverError ? [serverError] : [])];
  const errorFor = (field: string) => issueFor(issues, field, attempt) ?? (serverError?.field === field ? serverError.message : undefined);

  const generate = () => {
    setForm((f) => ({ ...f, password: generatePassword() }));
    setShowPassword(true);
  };

  const copyPassword = async () => {
    try {
      await navigator.clipboard.writeText(form.password);
      toast({ kind: 'success', title: 'Password copied' });
    } catch {
      toast({ kind: 'error', title: 'Couldn’t copy', text: 'Select the password and copy it yourself.' });
    }
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    if (issues.length) return;
    setSaving(true);
    try {
      const academy = await services.platform.createAcademy(academyInput(form));
      onCreated(academy, form.password);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'The Admin could not be created.';
      setServerError({ field: serverIssueField(message), message });
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="New admin" description="A new Admin gets an LMS of their own, empty and ready to choose a plan." width={560}>
      <form className={platformStyles.form} onSubmit={submit} noValidate>
        <ErrorSummary issues={shown} attempt={attempt} title="Fix these before creating the admin" />

        <fieldset className={styles.fieldset}>
          <legend className={styles.legend}>Their LMS</legend>
          <Field label="LMS name" error={errorFor('academy-name')}>
            <Input
              id="academy-name"
              value={form.name}
              onChange={(e) => setForm(withName(form, e.target.value))}
              placeholder="Saraswati Coaching Centre"
              autoFocus
            />
          </Field>
          <Field
            label="Address"
            hint="Lowercase letters, digits and single hyphens — 3 to 40 characters. Suggested from the name; you can change it."
            error={errorFor('academy-slug')}
          >
            <Input
              id="academy-slug"
              value={form.slug}
              onChange={(e) => setForm(withSlug(form, e.target.value))}
              placeholder="saraswati-coaching-centre"
              autoCapitalize="none"
              autoCorrect="off"
              spellCheck={false}
              className={styles.mono}
            />
          </Field>
        </fieldset>

        <fieldset className={styles.fieldset}>
          <legend className={styles.legend}>First admin</legend>
          <Field label="Full name" error={errorFor('academy-admin-name')}>
            <Input
              id="academy-admin-name"
              value={form.adminName}
              onChange={(e) => setForm({ ...form, adminName: e.target.value })}
              placeholder="Kavita Menon"
            />
          </Field>
          <Field label="Email address" hint="They sign in with this address." error={errorFor('academy-admin-email')}>
            <Input
              id="academy-admin-email"
              type="email"
              value={form.adminEmail}
              onChange={(e) => setForm({ ...form, adminEmail: e.target.value })}
              placeholder="name@example.com"
              autoComplete="off"
            />
          </Field>
          <Field
            label="Password"
            hint="At least 8 characters. It is shown once more after the Admin is created, then never again."
            error={errorFor('academy-admin-password')}
            id="academy-admin-password"
          >
            <div className={styles.passwordLine}>
              <div className={platformStyles.passwordRow}>
                <Input
                  id="academy-admin-password"
                  type={showPassword ? 'text' : 'password'}
                  value={form.password}
                  onChange={(e) => setForm({ ...form, password: e.target.value })}
                  autoComplete="new-password"
                  className={styles.mono}
                  aria-describedby="academy-admin-password-message"
                  aria-invalid={errorFor('academy-admin-password') ? true : undefined}
                />
                <button
                  type="button"
                  className={platformStyles.passwordToggle}
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? <EyeSlash size={18} /> : <Eye size={18} />}
                </button>
              </div>
              <span className={styles.passwordTools}>
                <Button size="sm" iconStart={<Sparkle size={14} />} onClick={generate}>
                  Generate a strong password
                </Button>
                <Button size="sm" variant="ghost" iconStart={<Copy size={14} />} onClick={copyPassword} disabled={!form.password}>
                  Copy
                </Button>
              </span>
            </div>
          </Field>
        </fieldset>

        <InlineMessage kind="info" title="The LMS starts empty.">
          No courses, learners or demo content. Its admin chooses a plan or starts a free trial the first time they sign in.
        </InlineMessage>

        <div className={platformStyles.formActions}>
          <Button type="button" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" loading={saving}>
            Create Admin
          </Button>
        </div>
      </form>
    </Modal>
  );
}
