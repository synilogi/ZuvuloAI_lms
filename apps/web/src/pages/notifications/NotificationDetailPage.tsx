import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, ArrowRight, EnvelopeSimple, EnvelopeSimpleOpen, GearSix, Trash } from '@phosphor-icons/react';
import { NOTIFICATION_CHANNELS } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useSession } from '@/providers/SessionProvider';
import { formatLongDay, formatTime } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CATEGORY_META, CategoryIcon, CHANNEL_PHRASE, notificationTime, useNotificationBase } from '@/components/lms/notification/notificationMeta';
import { announceNotificationsChanged } from '@/shell/notificationSummary';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import styles from './Notifications.module.css';

export default function NotificationDetailPage() {
  const { notificationId } = useParams();
  const base = useNotificationBase();
  const { user } = useSession();
  const now = useNow();
  const toast = useToast();
  const navigate = useNavigate();
  const query = useAsync(`notification:${user.id}:${notificationId}`, () => services.notifications.get(notificationId!, user.id));
  const d = query.data?.notification.id === notificationId ? query.data : undefined;
  const [read, setRead] = useState(true);
  const [busy, setBusy] = useState(false);
  const opened = useRef<string | null>(null);
  usePageCrumbs([{ label: 'Notifications', to: base }, { label: d?.notification.title ?? 'Notification' }]);

  // Opening a notification reads it.
  useEffect(() => {
    if (!d || opened.current === d.notification.id) return;
    opened.current = d.notification.id;
    setRead(true);
    if (!d.notification.readAt) services.notifications.setRead([d.notification.id], true).then(announceNotificationsChanged, () => undefined);
  }, [d]);

  if (query.status === 'error' && !d) {
    return (
      <div className={styles.narrowPage}>
        <StateMessage
          kind="error"
          title={(query.error as { code?: string }).code === 'not-found' ? 'Notification not found' : 'This notification didn’t load'}
          actions={
            <LinkButton to={base} iconStart={<ArrowLeft size={16} />}>
              Back to notifications
            </LinkButton>
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!d) {
    return (
      <div className={styles.narrowPage} aria-busy="true">
        <Skeleton width="30%" height={14} />
        <Skeleton width="80%" height={34} radius="var(--r-xs)" />
        <Skeleton height={220} radius="var(--r-lg)" />
      </div>
    );
  }

  const n = d.notification;
  const meta = CATEGORY_META[n.category];
  const channels = NOTIFICATION_CHANNELS.filter((c) => d.channels[c]).map((c) => CHANNEL_PHRASE[c]);

  const toggleRead = async () => {
    setBusy(true);
    try {
      await services.notifications.setRead([n.id], !read);
      setRead(!read);
      announceNotificationsChanged();
      toast({ kind: 'success', title: read ? 'Marked as unread' : 'Marked as read' });
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t update the notification', text: (e as Error).message });
    } finally {
      setBusy(false);
    }
  };

  const remove = async () => {
    setBusy(true);
    try {
      await services.notifications.remove([n.id]);
      announceNotificationsChanged();
      navigate(base, { replace: true });
      toast({
        kind: 'info',
        title: 'Notification removed',
        text: n.title,
        action: {
          label: 'Undo',
          onClick: () => services.notifications.restore([{ ...n, readAt: n.readAt ?? now.toISOString() }]).then(announceNotificationsChanged, () => undefined),
        },
      });
    } catch (e) {
      setBusy(false);
      toast({ kind: 'error', title: 'Couldn’t remove the notification', text: (e as Error).message });
    }
  };

  return (
    <div className={styles.narrowPage}>
      <PageHeader
        back={{ label: 'Notifications', to: base }}
        eyebrow={meta.label}
        title={n.title}
        meta={
          <span className={styles.detailMeta}>
            <time dateTime={n.createdAt}>
              {formatLongDay(n.createdAt)}, {formatTime(n.createdAt)} IST
            </time>
            <span aria-hidden="true">·</span>
            <span>{notificationTime(n.createdAt, now)}</span>
            {n.actor && (
              <>
                <span aria-hidden="true">·</span>
                <span>From {n.actor}</span>
              </>
            )}
            {n.important && (
              <Badge tone="danger" size="sm">
                Important
              </Badge>
            )}
          </span>
        }
      />

      <article className={styles.detail}>
        <div className={styles.detailHead}>
          <CategoryIcon category={n.category} size="lg" />
          <p className={styles.detailSummary}>{n.summary}</p>
        </div>
        <div className={styles.detailBody}>
          {n.body.map((p, i) => (
            <p key={i}>{p}</p>
          ))}
        </div>
        {n.facts && n.facts.length > 0 && (
          <dl className={styles.facts}>
            {n.facts.map((f) => (
              <div key={f.label}>
                <dt>{f.label}</dt>
                <dd>{f.value}</dd>
              </div>
            ))}
          </dl>
        )}
        {(n.action || n.secondaryAction) && (
          <div className={styles.detailActions}>
            {n.action && (
              <LinkButton to={n.action.to} variant="primary" iconEnd={<ArrowRight size={16} />}>
                {n.action.label}
              </LinkButton>
            )}
            {n.secondaryAction && <LinkButton to={n.secondaryAction.to}>{n.secondaryAction.label}</LinkButton>}
          </div>
        )}
      </article>

      <div className={styles.detailTools}>
        <Button size="sm" iconStart={read ? <EnvelopeSimple size={15} /> : <EnvelopeSimpleOpen size={15} />} onClick={toggleRead} disabled={busy}>
          {read ? 'Mark as unread' : 'Mark as read'}
        </Button>
        <Button size="sm" variant="ghost" iconStart={<Trash size={15} />} onClick={remove} disabled={busy}>
          Remove
        </Button>
      </div>

      <section className={styles.why} aria-labelledby="why-title">
        <h2 id="why-title" className={styles.whyTitle}>
          Why you got this
        </h2>
        <p className={styles.muted}>
          {channels.length
            ? `You get ${meta.plural.toLowerCase()} ${channels.length === 1 ? channels[0] : `${channels.slice(0, -1).join(', ')} and ${channels[channels.length - 1]}`}.`
            : `You’ve turned off every way of receiving ${meta.plural.toLowerCase()}, so new ones won’t reach you.`}
        </p>
        <LinkButton size="sm" variant="ghost" to={`${base}/preferences#pref-${n.category}`} iconStart={<GearSix size={15} />}>
          Change {meta.plural.toLowerCase()} settings
        </LinkButton>
      </section>

      {d.related.length > 0 && (
        <section aria-labelledby="related-title">
          <SectionHeader id="related-title" title={`More ${meta.plural.toLowerCase()}`} />
          <ul className={styles.related}>
            {d.related.map((r) => (
              <li key={r.id} data-unread={!r.readAt || undefined}>
                <Link to={`${base}/${r.id}`} className={styles.relatedLink}>
                  <span className={styles.relatedTitle}>{r.title}</span>
                  <span className={styles.muted}>{notificationTime(r.createdAt, now)}</span>
                </Link>
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
