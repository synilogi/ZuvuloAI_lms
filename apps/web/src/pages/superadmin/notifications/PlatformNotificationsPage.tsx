import { useState, type FormEvent } from 'react';
import { Megaphone } from '@phosphor-icons/react';
import type { BroadcastAudience, BroadcastHistoryRow } from '@syniastrolms/domain';
import { BROADCAST_AUDIENCES, BROADCAST_SUMMARY_MAX, BROADCAST_TITLE_MAX } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { PAGE_SIZE, PLATFORM_EYEBROW, PlatformError, pageCount } from '../platformMeta';
import { AUDIENCE_HINT, AUDIENCE_LABEL, broadcastDraftIssue, confirmTitle, outcomeText, reachText } from './broadcastMeta';
import styles from './PlatformNotifications.module.css';

/**
 * One message to one audience, as a `system` notification in the app and by email. The dialog names how many people it
 * reaches, read again as it opens, and the history below comes from the audit log.
 */
export default function PlatformNotificationsPage() {
  usePageCrumbs([{ label: 'Notifications' }]);
  const toast = useToast();
  const [audience, setAudience] = useState<BroadcastAudience>('students');
  const [title, setTitle] = useState('');
  const [summary, setSummary] = useState('');
  const [confirming, setConfirming] = useState(false);
  const [page, setPage] = useState(1);

  const reach = useAsync(`broadcast-reach:${audience}`, () => services.platform.broadcastAudienceCount(audience));
  const history = useAsync(`broadcast-history:${page}`, () => services.platform.listBroadcasts({ page, pageSize: PAGE_SIZE }));
  const count = reach.data?.audience === audience ? reach.data.count : undefined;
  const issue = broadcastDraftIssue(title, summary);

  const openConfirm = async (e: FormEvent) => {
    e.preventDefault();
    if (issue) return;
    // The count the person agrees to is the one as of now, not as of when the page opened.
    await reach.run().catch(() => undefined);
    setConfirming(true);
  };

  const send = async () => {
    const result = await services.platform.sendBroadcast({ audience, title: title.trim(), summary: summary.trim() });
    toast({
      kind: result.failed ? 'warn' : 'success',
      title: `Sent to ${reachText(result.delivered)}`,
      text: result.failed ? `${result.failed.toLocaleString('en-IN')} could not be reached. See the history below.` : undefined,
    });
    setConfirming(false);
    setTitle('');
    setSummary('');
    setPage(1);
    await history.run().catch(() => undefined);
  };

  const columns: Column<BroadcastHistoryRow>[] = [
    {
      key: 'message',
      header: 'Message',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <strong>{r.title}</strong>
          <span className={styles.muted}>{r.summary}</span>
        </span>
      ),
    },
    { key: 'audience', header: 'To', width: '150px', mobile: 'meta', render: (r) => AUDIENCE_LABEL[r.audience] ?? r.audience },
    {
      key: 'outcome',
      header: 'Outcome',
      width: '240px',
      mobile: 'status',
      render: (r) =>
        r.state === 'unfinished' ? (
          <Badge size="sm" tone="warn">
            {outcomeText(r)}
          </Badge>
        ) : (
          outcomeText(r)
        ),
    },
    {
      key: 'when',
      header: 'Sent',
      width: '170px',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.stack}>
          <time dateTime={r.createdAt}>{formatMoment(r.createdAt)}</time>
          <span className={styles.muted}>{r.sentBy}</span>
        </span>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Notifications"
        description="Send one message to one audience, in the app and by email. It is a system notice, so people can’t switch it off by category; anyone who has paused notifications doesn’t receive it."
      />

      <form className={styles.form} onSubmit={(e) => void openConfirm(e)} noValidate>
        <Field label="Audience" hint={AUDIENCE_HINT[audience]}>
          <Select value={audience} onChange={(e) => setAudience(e.target.value as BroadcastAudience)}>
            {BROADCAST_AUDIENCES.map((a) => (
              <option key={a} value={a}>
                {AUDIENCE_LABEL[a]}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Title" hint="Also the email’s subject line.">
          <Input id="broadcast-title" maxLength={BROADCAST_TITLE_MAX} value={title} onChange={(e) => setTitle(e.target.value)} />
        </Field>
        <Field label="Message" hint={`${summary.trim().length} of ${BROADCAST_SUMMARY_MAX} characters`}>
          <Textarea id="broadcast-summary" rows={4} maxLength={BROADCAST_SUMMARY_MAX} value={summary} onChange={(e) => setSummary(e.target.value)} />
        </Field>
        {reach.status === 'error' && count === undefined ? (
          <InlineMessage kind="error" title="Couldn’t count this audience.">
            {reach.error.message}{' '}
            <Button size="sm" variant="ghost" onClick={() => void reach.run().catch(() => undefined)}>
              Try again
            </Button>
          </InlineMessage>
        ) : (
          <p className={styles.reach} aria-live="polite">
            {count === undefined ? 'Counting this audience…' : count === 0 ? 'Nobody is in this audience.' : `Reaches ${reachText(count)}.`}
          </p>
        )}
        <div>
          <Button type="submit" variant="primary" iconStart={<Megaphone size={16} />} disabled={Boolean(issue) || !count}>
            Review and send
          </Button>
        </div>
      </form>

      <section className={styles.history} aria-labelledby="broadcast-history">
        <SectionHeader id="broadcast-history" title="History" description="From the activity log, newest first." />
        {history.status === 'error' && !history.data ? (
          <PlatformError title="The history didn’t load" error={history.error} onRetry={() => void history.run().catch(() => undefined)} />
        ) : (
          <>
            <DataTable<BroadcastHistoryRow>
              framed
              rows={history.data?.rows ?? []}
              columns={columns}
              rowKey={(r) => r.id}
              label="Broadcast history"
              rowLabel={(r) => r.title}
              loading={!history.data}
              empty={
                <StateMessage icon={<Megaphone size={26} />} title="Nothing sent yet" compact>
                  Messages you send appear here, with how many people they reached.
                </StateMessage>
              }
            />
            {history.data && history.data.total > PAGE_SIZE && (
              <Pagination page={page} pageCount={pageCount(history.data.total, history.data.pageSize)} onChange={setPage} />
            )}
          </>
        )}
      </section>

      <ConfirmDialog
        open={confirming}
        onClose={() => setConfirming(false)}
        onConfirm={send}
        title={count === undefined ? 'Send this message?' : confirmTitle(count)}
        description={`${AUDIENCE_LABEL[audience]}: in the app and by email.`}
        confirmLabel="Send now"
        blocked={!count}
      >
        <p>
          <strong>{title.trim()}</strong>
        </p>
        <p className={styles.preview}>{summary.trim()}</p>
        <p className={styles.muted}>This can’t be recalled once it is sent. A large audience can take a few minutes: keep this page open until it finishes.</p>
      </ConfirmDialog>
    </div>
  );
}
