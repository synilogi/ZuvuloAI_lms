import { useState, type FormEvent } from 'react';
import { Lifebuoy } from '@phosphor-icons/react';
import { INQUIRY_STATUS_LABEL } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { API_MODE } from '@/lib/apiMode';
import { services } from '@/services';
import styles from './Help.module.css';

/*
 * Platform support for an academy's admins (SAAS-029): a request to the ZuviloAI team, which lands in the Super
 * Admin's inbox with this academy attached by the server. The academy's admins see each other's requests and where
 * each stands; the team's private notes are not shown here.
 */
export default function SupportPage() {
  const toast = useToast();
  const list = useAsync('academy-support', () => services.support.list());
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [attempt, setAttempt] = useState(0);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string>();
  const subjectIssue = subject.trim().length < 3 ? 'Give the request a short subject.' : undefined;
  const messageIssue = message.trim().length < 10 ? 'Describe what you need — at least 10 characters.' : undefined;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setError(undefined);
    if (subjectIssue || messageIssue) return;
    setSending(true);
    try {
      await services.support.create({ subject: subject.trim(), message: message.trim() });
      toast({ kind: 'success', title: 'Request sent', text: 'The ZuviloAI team will reply by email.' });
      setSubject('');
      setMessage('');
      setAttempt(0);
      await list.run().catch(() => undefined);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'The request could not be sent.');
    } finally {
      setSending(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Platform support"
        description="Ask the ZuviloAI team about billing, your account or anything the Help Centre doesn’t cover. We reply by email."
      />

      <section aria-labelledby="support-new" className={styles.supportCard}>
        <SectionHeader id="support-new" title="New request" />
        {API_MODE === 'mock' && (
          <InlineMessage kind="info" title="Demo build">
            Requests here are kept for this visit only and nobody answers them.
          </InlineMessage>
        )}
        {error && (
          <InlineMessage kind="error" title="Not sent.">
            {error}
          </InlineMessage>
        )}
        <form className={styles.supportForm} onSubmit={submit} noValidate>
          <Field label="Subject" error={attempt ? subjectIssue : undefined}>
            <Input value={subject} onChange={(e) => setSubject(e.target.value)} maxLength={160} />
          </Field>
          <Field label="What do you need?" error={attempt ? messageIssue : undefined}>
            <Textarea rows={5} value={message} onChange={(e) => setMessage(e.target.value)} />
          </Field>
          <div>
            <Button type="submit" variant="primary" loading={sending}>
              Send request
            </Button>
          </div>
        </form>
      </section>

      <section aria-labelledby="support-history">
        <SectionHeader id="support-history" title="Your LMS’s requests" />
        {list.status === 'error' && !list.data ? (
          <StateMessage kind="error" title="Requests didn’t load" actions={<Button onClick={() => list.run().catch(() => undefined)}>Try again</Button>}>
            {list.error?.message}
          </StateMessage>
        ) : !list.data ? (
          <Skeleton height={120} radius="var(--r-lg)" />
        ) : list.data.length === 0 ? (
          <StateMessage icon={<Lifebuoy size={26} />} title="No requests yet" compact>
            Requests your LMS’s admins send appear here with where each stands.
          </StateMessage>
        ) : (
          <ul className={styles.supportList}>
            {list.data.map((r) => (
              <li key={r.id} className={styles.supportItem}>
                <div className={styles.supportItemHead}>
                  <strong>{r.subject ?? 'Support request'}</strong>
                  <Badge size="sm" tone={r.status === 'closed' ? 'neutral' : r.status === 'new' ? 'accent' : 'info'}>
                    {INQUIRY_STATUS_LABEL[r.status]}
                  </Badge>
                </div>
                <p className={styles.muted}>
                  {r.name} · {formatDate(r.createdAt)}
                </p>
                <p className={styles.supportMessage}>{r.message}</p>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
