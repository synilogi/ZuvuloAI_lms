import { useCallback, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { BellSimple, BellSimpleSlash, Checks, DotsThree, EnvelopeSimple, EnvelopeSimpleOpen, GearSix, Trash } from '@phosphor-icons/react';
import type { AppNotification, NotificationCategory } from '@syniastrolms/domain';
import { NOTIFICATION_CATEGORIES } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useSession } from '@/providers/SessionProvider';
import { formatLongDay, formatTime, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Field, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CATEGORY_META, CategoryIcon, groupByRecency, notificationTime, useNotificationBase } from '@/components/lms/notification/notificationMeta';
import { announceNotificationsChanged, useNotificationsChanged } from '@/shell/notificationSummary';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import styles from './Notifications.module.css';

const PAGE = 12;
const isCategory = (value: string | null): value is NotificationCategory => (NOTIFICATION_CATEGORIES as string[]).includes(value ?? '');

export default function NotificationsPage() {
  const base = useNotificationBase();
  const { user } = useSession();
  const now = useNow();
  const toast = useToast();
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();
  const view = params.get('view') === 'unread' ? 'unread' : 'all';
  const typeParam = params.get('type');
  const category = isCategory(typeParam) ? typeParam : undefined;
  const [limit, setLimit] = useState(PAGE);
  const [clearing, setClearing] = useState(false);
  const [marking, setMarking] = useState(false);
  usePageCrumbs([{ label: 'Notifications' }]);

  const query = { recipientId: user.id, unreadOnly: view === 'unread', category, limit };
  const list = useAsync(`notifications:${JSON.stringify(query)}`, () => services.notifications.list(query));
  const { run } = list;
  const refresh = useCallback(() => {
    run().catch(() => undefined);
  }, [run]);
  useNotificationsChanged(refresh);
  const data = list.data;

  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (v) p.set(k, v);
      else p.delete(k);
    }
    setLimit(PAGE);
    setParams(p, { replace: true });
  };

  const setRead = async (n: AppNotification, read: boolean) => {
    try {
      await services.notifications.setRead([n.id], read);
      announceNotificationsChanged();
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t update the notification', text: (e as Error).message });
    }
  };

  const remove = async (n: AppNotification) => {
    try {
      await services.notifications.remove([n.id]);
      announceNotificationsChanged();
      toast({
        kind: 'info',
        title: 'Notification removed',
        text: n.title,
        action: {
          label: 'Undo',
          onClick: () => {
            services.notifications.restore([n]).then(announceNotificationsChanged, () => undefined);
          },
        },
      });
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t remove the notification', text: (e as Error).message });
    }
  };

  const markAll = async () => {
    setMarking(true);
    try {
      const count = await services.notifications.markAllRead(user.id, category);
      announceNotificationsChanged();
      toast({
        kind: 'success',
        title: count ? `${plural(count, 'notification')} marked as read` : 'Nothing left to mark',
        text: category ? CATEGORY_META[category].plural : undefined,
      });
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t mark notifications as read', text: (e as Error).message });
    } finally {
      setMarking(false);
    }
  };

  const clearAll = async () => {
    const count = await services.notifications.clear(user.id, { category, unreadOnly: view === 'unread' });
    setClearing(false);
    announceNotificationsChanged();
    toast({ kind: 'success', title: `${plural(count, 'notification')} cleared` });
  };

  const scopeLabel = category ? `${CATEGORY_META[category].label.toLowerCase()} notifications` : 'notifications';
  const groups = data ? groupByRecency(data.rows, now) : [];

  return (
    <div className={styles.page}>
      <PageHeader
        title="Notifications"
        description="News about your courses, classes and work — newest first. Open one to see the details and what to do next."
        meta={data && data.unread > 0 ? <span className={styles.headerMeta}>{plural(data.unread, 'unread notification')}</span> : undefined}
        actions={
          <div className={styles.headerActions}>
            <Button iconStart={<Checks size={16} />} onClick={markAll} loading={marking} disabled={!data || data.unread === 0}>
              Mark all as read
            </Button>
            <LinkButton to={`${base}/preferences`} iconStart={<GearSix size={16} />}>
              Preferences
            </LinkButton>
          </div>
        }
      />

      <div className={styles.controls}>
        <SegmentedControl<'all' | 'unread'>
          label="Show"
          value={view}
          onChange={(v) => update({ view: v === 'all' ? undefined : v })}
          segments={[
            { value: 'all', label: 'All' },
            { value: 'unread', label: 'Unread', count: data?.unread },
          ]}
        />
        <div className={styles.controlsEnd}>
          <Field label="Type" hideLabel className={styles.filter}>
            <Select value={category ?? ''} onChange={(e) => update({ type: e.target.value || undefined })}>
              <option value="">All types</option>
              {NOTIFICATION_CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {CATEGORY_META[c].plural}
                  {data ? ` (${data.counts[c]})` : ''}
                </option>
              ))}
            </Select>
          </Field>
          <Button variant="ghost" iconStart={<Trash size={16} />} onClick={() => setClearing(true)} disabled={!data || data.total === 0}>
            Clear all
          </Button>
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Notifications didn’t load"
          actions={
            <Button variant="primary" onClick={refresh}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : !data ? (
        <div className={styles.skeletonList} aria-busy="true">
          {Array.from({ length: 5 }, (_, i) => (
            <div key={i} className={styles.skeletonRow}>
              <Skeleton width={36} height={36} radius="var(--r-sm)" />
              <div className={styles.skeletonText}>
                <Skeleton width="55%" height={14} />
                <Skeleton width="85%" height={12} />
              </div>
            </div>
          ))}
        </div>
      ) : data.total === 0 ? (
        view === 'unread' && !category ? (
          <StateMessage
            icon={<Checks size={26} />}
            title="You’re all caught up"
            actions={
              <Button onClick={() => update({ view: undefined })} iconStart={<BellSimple size={16} />}>
                Show all notifications
              </Button>
            }
          >
            Nothing unread. New notifications appear here and on the bell.
          </StateMessage>
        ) : category ? (
          <StateMessage
            icon={<CategoryIcon category={category} />}
            title={view === 'unread' ? `No unread ${scopeLabel}` : `No ${scopeLabel}`}
            actions={<Button onClick={() => update({ type: undefined })}>Show all types</Button>}
          >
            {view === 'unread' ? 'Everything of this kind has been read.' : 'Nothing of this kind has arrived yet.'}
          </StateMessage>
        ) : (
          <StateMessage
            icon={<BellSimpleSlash size={26} />}
            title="No notifications"
            actions={
              <LinkButton to={`${base}/preferences`} iconStart={<GearSix size={16} />}>
                Choose what you hear about
              </LinkButton>
            }
          >
            When there’s news about your courses, classes or work, it shows up here.
          </StateMessage>
        )
      ) : (
        <>
          <div className={styles.groups} aria-busy={list.status === 'loading' || undefined}>
            {groups.map((g) => (
              <section key={g.label} className={styles.group} aria-labelledby={`group-${g.label}`}>
                <h2 id={`group-${g.label}`} className={styles.groupTitle}>
                  {g.label}
                </h2>
                <ul className={styles.list}>
                  {g.rows.map((n) => {
                    const unread = !n.readAt;
                    return (
                      <li key={n.id} className={styles.item} data-unread={unread || undefined}>
                        <CategoryIcon category={n.category} />
                        <div className={styles.itemMain}>
                          <div className={styles.itemTop}>
                            <Link to={`${base}/${n.id}`} className={styles.itemTitle}>
                              {n.title}
                              {unread && <span className="sr-only"> · unread</span>}
                            </Link>
                            {n.important && unread && (
                              <Badge tone="danger" size="sm">
                                Important
                              </Badge>
                            )}
                          </div>
                          <p className={styles.itemSummary}>{n.summary}</p>
                          <span className={styles.itemMeta}>
                            {CATEGORY_META[n.category].label}
                            <span aria-hidden="true"> · </span>
                            <time dateTime={n.createdAt} title={`${formatLongDay(n.createdAt)}, ${formatTime(n.createdAt)} IST`}>
                              {notificationTime(n.createdAt, now)}
                            </time>
                          </span>
                        </div>
                        <div className={styles.itemSide}>
                          {unread && <span className={styles.unreadDot} aria-hidden="true" />}
                          <IconButton
                            size="sm"
                            className={styles.readToggle}
                            label={unread ? `Mark as read: ${n.title}` : `Mark as unread: ${n.title}`}
                            icon={unread ? <EnvelopeSimpleOpen size={16} /> : <EnvelopeSimple size={16} />}
                            onClick={() => setRead(n, unread)}
                          />
                          <Menu
                            align="end"
                            width={240}
                            trigger={(props) => (
                              <IconButton {...props} size="sm" label={`More actions: ${n.title}`} icon={<DotsThree size={18} weight="bold" />} />
                            )}
                            sections={[
                              {
                                items: [
                                  {
                                    id: 'read',
                                    label: unread ? 'Mark as read' : 'Mark as unread',
                                    icon: unread ? <EnvelopeSimpleOpen size={17} /> : <EnvelopeSimple size={17} />,
                                    onSelect: () => setRead(n, unread),
                                  },
                                  { id: 'remove', label: 'Remove', icon: <Trash size={17} />, tone: 'danger', onSelect: () => remove(n) },
                                ],
                              },
                              {
                                items: [
                                  {
                                    id: 'prefs',
                                    label: `Change ${CATEGORY_META[n.category].plural.toLowerCase()} settings`,
                                    icon: <GearSix size={17} />,
                                    onSelect: () => navigate(`${base}/preferences#pref-${n.category}`),
                                  },
                                ],
                              },
                            ]}
                          />
                        </div>
                      </li>
                    );
                  })}
                </ul>
              </section>
            ))}
          </div>
          <div className={styles.listFoot}>
            <span className={styles.muted}>
              Showing {data.rows.length} of{' '}
              {plural(data.total, category || view === 'unread' ? 'match' : 'notification', category || view === 'unread' ? 'matches' : 'notifications')}
            </span>
            {data.rows.length < data.total && (
              <Button onClick={() => setLimit((l) => l + PAGE)} loading={list.status === 'loading'}>
                Show older
              </Button>
            )}
          </div>
        </>
      )}

      <ConfirmDialog
        open={clearing}
        onClose={() => setClearing(false)}
        onConfirm={clearAll}
        tone="danger"
        title={`Clear ${view === 'unread' ? 'unread ' : 'all '}${scopeLabel}?`}
        description={
          data
            ? `This removes ${plural(data.total, 'notification')}${view === 'all' && !category && data.unread ? `, ${data.unread} of them unread` : ''}. Cleared notifications can’t be brought back.`
            : undefined
        }
        confirmLabel="Clear all"
      />
    </div>
  );
}
