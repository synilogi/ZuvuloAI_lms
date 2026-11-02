import { useState } from 'react';
import { CheckCircle, Pause, Prohibit, WarningCircle, Moon } from '@phosphor-icons/react';
import type { EnrollmentSource, EnrollmentStatus, StudentStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { plural } from '@/lib/format';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import styles from './Students.module.css';

export const STUDENT_STATUS: Record<StudentStatus, { label: string; description: string }> = {
  active: { label: 'Active', description: 'Studied in the last 10 days' },
  'at-risk': { label: 'At risk', description: 'Quiet for 10 days or more with a course in progress' },
  inactive: { label: 'Inactive', description: 'Nothing opened for 45 days, or nothing in progress' },
  suspended: { label: 'Suspended', description: 'Access paused by an admin' },
};

export function StudentStatusBadge({ status, size = 'sm' }: { status: StudentStatus; size?: 'sm' | 'md' }) {
  if (status === 'active')
    return (
      <Badge size={size} tone="accent" dot>
        Active
      </Badge>
    );
  if (status === 'at-risk')
    return (
      <Badge size={size} tone="warn" icon={<WarningCircle size={13} weight="bold" />}>
        At risk
      </Badge>
    );
  if (status === 'suspended')
    return (
      <Badge size={size} tone="danger" icon={<Prohibit size={13} weight="bold" />}>
        Suspended
      </Badge>
    );
  return (
    <Badge size={size} tone="neutral" icon={<Moon size={13} />}>
      Inactive
    </Badge>
  );
}

export function EnrollmentStatusBadge({ status }: { status: EnrollmentStatus }) {
  if (status === 'completed')
    return (
      <Badge size="sm" tone="accent" icon={<CheckCircle size={13} weight="fill" />}>
        Completed
      </Badge>
    );
  if (status === 'paused')
    return (
      <Badge size="sm" tone="warn" icon={<Pause size={13} weight="fill" />}>
        Paused
      </Badge>
    );
  if (status === 'expired')
    return (
      <Badge size="sm" tone="neutral">
        Expired
      </Badge>
    );
  return (
    <Badge size="sm" tone="info" dot>
      In progress
    </Badge>
  );
}

export const SOURCE: Record<EnrollmentSource, string> = {
  self: 'Enrolled themselves',
  admin: 'Enrolled by an admin',
  cohort: 'Cohort place',
  scholarship: 'Scholarship',
  purchase: 'Bought the course',
};

/* ─── Message ──────────────────────────────────────────────────────────── */

interface MessageDialogProps {
  open: boolean;
  onClose: () => void;
  recipients: { id: string; name: string }[];
  /** A starting subject and message, e.g. a nudge for a learner who has gone quiet. */
  draft?: { subject: string; body: string };
}

export function MessageDialog({ open, onClose, recipients, draft }: MessageDialogProps) {
  const toast = useToast();
  const [subject, setSubject] = useState(draft?.subject ?? '');
  const [body, setBody] = useState(draft?.body ?? '');
  const [email, setEmail] = useState(true);
  const [app, setApp] = useState(true);
  const [attempt, setAttempt] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const first = recipients[0]?.name.split(' ')[0] ?? '';
  const issues = {
    subject: attempt && !subject.trim() ? 'Add a subject.' : undefined,
    body: attempt && body.trim().length < 10 ? 'Write a message of at least a sentence.' : undefined,
    channels: attempt && !email && !app ? 'Choose at least one way to send it.' : undefined,
  };

  const send = async () => {
    setAttempt(true);
    setError(null);
    if (!subject.trim() || body.trim().length < 10 || (!email && !app)) return;
    setSending(true);
    try {
      const { sent } = await services.students.message(
        recipients.map((r) => r.id),
        { subject, body, channels: [...(email ? ['email' as const] : []), ...(app ? ['app' as const] : [])] },
      );
      toast({ kind: 'success', title: sent === 1 ? `Message sent to ${recipients[0].name}` : `Message sent to ${plural(sent, 'learner')}`, text: subject });
      onClose();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSending(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      width={540}
      title={recipients.length === 1 ? `Message ${recipients[0].name}` : `Message ${plural(recipients.length, 'learner')}`}
      description={
        recipients.length > 1
          ? recipients
              .slice(0, 3)
              .map((r) => r.name)
              .join(', ') + (recipients.length > 3 ? ` and ${recipients.length - 3} more` : '')
          : undefined
      }
      footer={
        <>
          <Button onClick={onClose}>Cancel</Button>
          <Button variant="primary" loading={sending} onClick={send}>
            Send message
          </Button>
        </>
      }
    >
      <div className={styles.dialogForm}>
        {error && (
          <InlineMessage kind="error" title="The message wasn’t sent.">
            {error}
          </InlineMessage>
        )}
        <Field label="Subject" error={issues.subject}>
          <Input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Your next lesson is ready" autoFocus />
        </Field>
        <Field label="Message" error={issues.body} hint={recipients.length > 1 ? 'Each learner receives their own copy.' : undefined}>
          <Textarea rows={6} value={body} onChange={(e) => setBody(e.target.value)} placeholder={first ? `Hi ${first}, …` : 'Hi, …'} />
        </Field>
        <fieldset className={styles.channels}>
          <legend>Send by</legend>
          <Checkbox checked={email} onChange={(e) => setEmail(e.target.checked)} label="Email" />
          <Checkbox checked={app} onChange={(e) => setApp(e.target.checked)} label="In-app notification" />
          {issues.channels && <span className={styles.error}>{issues.channels}</span>}
        </fieldset>
      </div>
    </Modal>
  );
}

/* ─── Enroll ───────────────────────────────────────────────────────────── */

interface EnrollDialogProps {
  open: boolean;
  onClose: () => void;
  student: { id: string; name: string };
  enrolledCourseIds: string[];
  onEnrolled: () => void;
}

export function EnrollDialog({ open, onClose, student, enrolledCourseIds, onEnrolled }: EnrollDialogProps) {
  const toast = useToast();
  const courses = useAsync(`enroll-courses`, () => services.courses.list({ status: 'published', page: 1, pageSize: 100 }), { immediate: open });
  const available = (courses.data?.rows ?? []).filter((c) => !enrolledCourseIds.includes(c.id));
  const [courseId, setCourseId] = useState('');
  const [source, setSource] = useState<EnrollmentSource>('admin');
  const [attempt, setAttempt] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const enroll = async () => {
    setAttempt(true);
    setError(null);
    if (!courseId) return;
    setSaving(true);
    try {
      await services.students.enroll(student.id, courseId, source);
      toast({ kind: 'success', title: `${student.name} is enrolled`, text: available.find((c) => c.id === courseId)?.title });
      onEnrolled();
      onClose();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={`Enroll ${student.name}`}
      description="They get access straight away and a welcome email with the first lesson."
      footer={
        <>
          <Button onClick={onClose}>Cancel</Button>
          <Button variant="primary" loading={saving} disabled={!courses.data} onClick={enroll}>
            Enroll
          </Button>
        </>
      }
    >
      <div className={styles.dialogForm}>
        {error && (
          <InlineMessage kind="error" title="Couldn’t enroll.">
            {error}
          </InlineMessage>
        )}
        <Field label="Course" error={attempt && !courseId ? 'Choose a course.' : undefined}>
          <Select value={courseId} onChange={(e) => setCourseId(e.target.value)} disabled={!courses.data}>
            <option value="">
              {courses.data ? (available.length ? 'Choose a published course' : 'Already enrolled in every course') : 'Loading courses…'}
            </option>
            {available.map((c) => (
              <option key={c.id} value={c.id}>
                {c.title}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Place type">
          <Select value={source} onChange={(e) => setSource(e.target.value as EnrollmentSource)}>
            <option value="admin">Standard place</option>
            <option value="scholarship">Scholarship</option>
            <option value="cohort">Cohort place</option>
          </Select>
        </Field>
      </div>
    </Modal>
  );
}

/** Where a learner creates an account (docs/16, D-PLAT-06): the link staff share. */
export const signUpLink = (origin = window.location.origin) => `${origin}/register`;

/**
 * Adds a learner to the academy (SAAS-028). The server counts them against the plan and emails them a link to choose a
 * password; nothing here sets a password or an academy.
 */
export function AddStudentDialog({ open, onClose, onAdded }: { open: boolean; onClose: () => void; onAdded: () => void }) {
  const toast = useToast();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [attempt, setAttempt] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const nameIssue = name.trim().length < 2 ? 'Enter the learner’s full name.' : undefined;
  const emailIssue = !/^\S+@\S+\.\S+$/.test(email.trim()) ? 'Enter a valid email address.' : undefined;

  const close = () => {
    setName('');
    setEmail('');
    setAttempt(false);
    setError(null);
    onClose();
  };

  const add = async () => {
    setAttempt(true);
    setError(null);
    if (nameIssue || emailIssue) return;
    setSaving(true);
    try {
      const student = await services.students.create({ name: name.trim(), email: email.trim() });
      toast({ kind: 'success', title: `${student.name} is added`, text: `An invitation to choose a password is on its way to ${student.email}.` });
      onAdded();
      close();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={close}
      title="Add a student"
      description="They get an email to choose a password and sign in. Enrol them in courses from their profile."
      footer={
        <>
          <Button onClick={close}>Cancel</Button>
          <Button variant="primary" loading={saving} onClick={add}>
            Add student
          </Button>
        </>
      }
    >
      <div className={styles.dialogForm}>
        {error && (
          <InlineMessage kind="error" title="Couldn’t add the student.">
            {error}
          </InlineMessage>
        )}
        <Field label="Full name" error={attempt ? nameIssue : undefined}>
          <Input value={name} onChange={(e) => setName(e.target.value)} autoComplete="off" />
        </Field>
        <Field label="Email address" error={attempt ? emailIssue : undefined}>
          <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="off" />
        </Field>
      </div>
    </Modal>
  );
}
