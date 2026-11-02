import { useEffect, useState, type FormEvent } from 'react';
import { Eye, EyeSlash } from '@phosphor-icons/react';
import { ErrorSummary } from '@/components/forms/Forms';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { Modal } from '@/components/overlays/Overlay';
import type { PlatformUserRow } from '@/services';
import { adminChanges, adminFormIssues, emptyAdminForm, type AdminForm } from './platformMeta';
import styles from './Platform.module.css';

const issueFor = (issues: { field: string; message: string }[], field: string, attempt: number) =>
  attempt > 0 ? issues.find((i) => i.field === field)?.message : undefined;

/**
 * Creating a staff admin (docs/16, D-PLAT-03). The role is not on this form and is not sent: the API fixes it, and
 * every admin belongs to the platform's one workspace. The password is typed twice, never shown back afterwards,
 * and never returned by the API.
 */
export function CreateAdminDialog({ open, onClose, onCreate }: { open: boolean; onClose: () => void; onCreate: (form: AdminForm) => Promise<void> }) {
  const [form, setForm] = useState<AdminForm>(emptyAdminForm);
  const [attempt, setAttempt] = useState(0);
  const [showPassword, setShowPassword] = useState(false);
  const [saving, setSaving] = useState(false);
  const [serverError, setServerError] = useState<string>();

  useEffect(() => {
    if (open) {
      setForm(emptyAdminForm());
      setAttempt(0);
      setSaving(false);
      setServerError(undefined);
      setShowPassword(false);
    }
  }, [open]);

  const issues = adminFormIssues(form, 'create');
  const shown = [...(attempt ? issues : []), ...(serverError ? [{ field: 'admin-email', message: serverError }] : [])];

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    if (issues.length) return;
    setSaving(true);
    try {
      await onCreate(form);
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'The admin could not be created.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Add an admin user"
      description="A staff account for the workspace, at /admin, limited by the permissions you give it. It cannot reach the platform pages."
      width={500}
    >
      <form className={styles.form} onSubmit={submit} noValidate>
        <ErrorSummary issues={shown} attempt={attempt} title="Fix these before saving" />
        <Field label="Full name" error={issueFor(issues, 'admin-name', attempt)}>
          <Input id="admin-name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="Kavita Menon" autoFocus />
        </Field>
        <Field label="Email address" error={issueFor(issues, 'admin-email', attempt)}>
          <Input
            id="admin-email"
            type="email"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            placeholder="name@example.com"
          />
        </Field>
        <Field
          label="Password"
          hint="At least 8 characters. Share it with them another way — it is never shown again."
          error={issueFor(issues, 'admin-password', attempt)}
        >
          <div className={styles.passwordRow}>
            <Input
              id="admin-password"
              type={showPassword ? 'text' : 'password'}
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
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
        <Field label="Confirm password" error={issueFor(issues, 'admin-confirm', attempt)}>
          <Input
            id="admin-confirm"
            type="password"
            value={form.confirm}
            onChange={(e) => setForm({ ...form, confirm: e.target.value })}
            autoComplete="new-password"
          />
        </Field>
        <div className={styles.formActions}>
          <Button type="button" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" loading={saving}>
            Create admin
          </Button>
        </div>
      </form>
    </Modal>
  );
}

/** Renaming an admin or moving it to another address — the only two things that can change. */
export function EditAdminDialog({
  admin,
  onClose,
  onSave,
}: {
  admin: PlatformUserRow | null;
  onClose: () => void;
  onSave: (id: string, form: AdminForm) => Promise<void>;
}) {
  const [form, setForm] = useState<AdminForm>(emptyAdminForm);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [serverError, setServerError] = useState<string>();

  useEffect(() => {
    if (admin) {
      setForm({ ...emptyAdminForm(), name: admin.name, email: admin.email });
      setAttempt(0);
      setSaving(false);
      setServerError(undefined);
    }
  }, [admin]);

  const issues = adminFormIssues(form, 'edit');
  const shown = [...(attempt ? issues : []), ...(serverError ? [{ field: 'edit-admin-email', message: serverError }] : [])];
  const unchanged = admin ? Object.keys(adminChanges(form, admin)).length === 0 : true;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (!admin) return;
    setAttempt((a) => a + 1);
    setServerError(undefined);
    if (issues.length) return;
    setSaving(true);
    try {
      await onSave(admin.id, form);
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'The changes could not be saved.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal open={Boolean(admin)} onClose={onClose} title="Edit admin" description="Their role cannot be changed here, or anywhere else." width={460}>
      <form className={styles.form} onSubmit={submit} noValidate>
        <ErrorSummary issues={shown} attempt={attempt} title="Fix these before saving" />
        <Field label="Full name" error={issueFor(issues, 'admin-name', attempt)}>
          <Input id="edit-admin-name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} autoFocus />
        </Field>
        <Field label="Email address" hint="They sign in with this address." error={issueFor(issues, 'admin-email', attempt)}>
          <Input id="edit-admin-email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
        </Field>
        <div className={styles.formActions}>
          <Button type="button" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" loading={saving} disabled={unchanged}>
            Save changes
          </Button>
        </div>
      </form>
    </Modal>
  );
}
