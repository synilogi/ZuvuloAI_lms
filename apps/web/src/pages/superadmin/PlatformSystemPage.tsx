import type { ReactNode } from 'react';
import { ArrowsClockwise, Database, EnvelopeSimple, FilmSlate, Pulse } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatRelative } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError, formatBytes, formatUptime } from './platformMeta';
import styles from './Platform.module.css';

function Panel({ title, icon, status, children, footnote }: { title: string; icon: ReactNode; status?: ReactNode; children: ReactNode; footnote?: ReactNode }) {
  return (
    <section className={styles.panel} aria-label={title}>
      <div className={styles.panelHead}>
        <h2 className={styles.panelTitle}>
          {icon} {title}
        </h2>
        {status}
      </div>
      <dl className={styles.rows}>{children}</dl>
      {footnote && <p className={styles.footnote}>{footnote}</p>}
    </section>
  );
}

const Row = ({ label, value }: { label: string; value: ReactNode }) => (
  <div className={styles.row}>
    <dt className={styles.rowLabel}>{label}</dt>
    <dd className={styles.rowValue}>{value}</dd>
  </div>
);

const count = (n: number) => n.toLocaleString('en-IN');

/**
 * Operational state from `GET /superadmin/system`. The API decides what is safe to say — the
 * database round-trip, the outbox, the media table and the process's own mode and uptime. No
 * configuration value, connection string or path is part of that answer, so none can be shown here.
 */
export default function PlatformSystemPage() {
  const now = useNow();
  const system = useAsync('platform:system', () => services.platform.system());
  const data = system.data;
  const refresh = () => system.run().catch(() => undefined);

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="System health"
        description="Whether the platform is working properly right now: its database, emails, uploaded files and server."
        meta={data ? <span className={styles.muted}>Checked {formatRelative(data.generatedAt, now)}</span> : undefined}
        actions={
          <Button onClick={refresh} iconStart={<ArrowsClockwise size={16} />} loading={system.status === 'loading' && !!data}>
            Check again
          </Button>
        }
      />

      {system.status === 'error' && !data ? (
        <PlatformError title="The system status didn’t load" error={system.error} onRetry={refresh} />
      ) : !data ? (
        <div className={styles.systemGrid} aria-busy="true" aria-label="Loading the system status">
          {Array.from({ length: 4 }, (_, i) => (
            <Skeleton key={i} height={150} radius="var(--r-lg)" />
          ))}
        </div>
      ) : (
        <>
          {!data.database.ok ? (
            <InlineMessage kind="error" title="The database isn’t responding.">
              Pages may fail to load until it is back. Check the server, then press Check again.
            </InlineMessage>
          ) : data.email.failed > 0 ? (
            <InlineMessage kind="warn" title={`${count(data.email.failed)} ${data.email.failed === 1 ? 'email' : 'emails'} couldn’t be sent.`}>
              Everything else is working. Check the server’s email settings — the failed messages are listed in its outbox.
            </InlineMessage>
          ) : (
            <InlineMessage kind="success" title="Everything is working normally.">
              The database is responding and no email has failed.
            </InlineMessage>
          )}
          <div className={styles.systemGrid}>
            <Panel
              title="Database"
              icon={<Database size={17} aria-hidden="true" />}
              status={
                <Badge size="sm" tone={data.database.ok ? 'accent' : 'danger'} dot>
                  {data.database.ok ? 'Working' : 'Not responding'}
                </Badge>
              }
            >
              <Row label="Response time" value={data.database.latencyMs === undefined ? '—' : `${count(data.database.latencyMs)} ms`} />
            </Panel>

            <Panel
              title="Emails"
              icon={<EnvelopeSimple size={17} aria-hidden="true" />}
              status={data.email.failed > 0 ? <Badge size="sm" tone="danger">{`${count(data.email.failed)} failed`}</Badge> : undefined}
              footnote={data.email.oldestQueuedAt ? `The oldest one waiting was written ${formatRelative(data.email.oldestQueuedAt, now)}.` : undefined}
            >
              <Row label="Waiting to send" value={count(data.email.queued)} />
              <Row label="Sent" value={count(data.email.sent)} />
              <Row label="Failed" value={count(data.email.failed)} />
            </Panel>

            <Panel title="Uploaded files" icon={<FilmSlate size={17} aria-hidden="true" />}>
              <Row label="Files" value={count(data.media.files)} />
              <Row label="Space used" value={formatBytes(data.media.totalBytes)} />
            </Panel>

            <Panel title="Server" icon={<Pulse size={17} aria-hidden="true" />}>
              <Row label="Mode" value={data.process.environment} />
              <Row label="Running for" value={formatUptime(data.process.uptimeSeconds)} />
            </Panel>
          </div>
        </>
      )}
    </div>
  );
}
