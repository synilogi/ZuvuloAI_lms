import { useEffect, useRef, useState } from 'react';
import { useBlocker, useLocation } from 'react-router-dom';
import { FloppyDisk, LockSimple, Pause, Play } from '@phosphor-icons/react';
import type { EmailDigest, NotificationCategory, NotificationChannel, NotificationSettings, Role } from '@syniastrolms/domain';
import { isLocked, NOTIFICATION_CHANNELS, validateNotificationSettings } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useSession } from '@/providers/SessionProvider';
import { formatDay, formatTime } from '@/lib/format';
import { ChoiceCards, ErrorSummary, FormSection, Switch, type FieldIssue } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import {
  CATEGORY_DESCRIPTION,
  CATEGORY_GROUPS,
  CATEGORY_META,
  CategoryIcon,
  CHANNEL_LABEL,
  useNotificationBase,
} from '@/components/lms/notification/notificationMeta';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import styles from './Notifications.module.css';

export default function NotificationPreferencesPage() {
  const base = useNotificationBase();
  const { user, role } = useSession();
  const query = useAsync(`notification-settings:${user.id}`, () => services.notifications.getSettings(user.id));
  usePageCrumbs([{ label: 'Notifications', to: base }, { label: 'Preferences' }]);

  if (query.status === 'error' && !query.data) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title="Your preferences didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!query.data) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="35%" height={30} radius="var(--r-xs)" />
        <Skeleton height={420} radius="var(--r-lg)" />
      </div>
    );
  }
  const { smsNumber, ...settings } = query.data;
  return <Preferences key={user.id} initial={settings} smsNumber={smsNumber} recipientId={user.id} role={role} base={base} />;
}

const PAUSES = [
  { value: 'hour', label: 'For an hour' },
  { value: 'morning', label: 'Until 8 AM tomorrow' },
  { value: 'week', label: 'For a week' },
] as const;

function pauseEnd(choice: (typeof PAUSES)[number]['value'], now: Date) {
  if (choice === 'hour') return new Date(now.getTime() + 3_600_000);
  if (choice === 'week') return new Date(now.getTime() + 7 * 86_400_000);
  const tomorrow = new Date(new Date(now.getTime() + 330 * 60_000 + 86_400_000).toISOString().slice(0, 10) + 'T08:00:00+05:30');
  return tomorrow;
}

interface PreferencesProps {
  initial: NotificationSettings;
  smsNumber: string;
  recipientId: string;
  role: Role;
  base: string;
}

function Preferences({ initial, smsNumber, recipientId, role, base }: PreferencesProps) {
  const toast = useToast();
  const now = useNow();
  const { hash } = useLocation();
  const { isMobile } = useViewport();
  const [saved, setSaved] = useState(initial);
  const [form, setForm] = useState(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const dirty = JSON.stringify(form) !== JSON.stringify(saved);
  const savingRef = useRef(false);

  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !savingRef.current && currentLocation.pathname !== nextLocation.pathname);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  // A link from a notification lands on its kind of preference.
  useEffect(() => {
    if (!hash.startsWith('#pref-')) return;
    const el = document.getElementById(hash.slice(1));
    el?.scrollIntoView({ block: 'center' });
    el?.setAttribute('data-highlight', 'true');
  }, [hash]);

  const all = validateNotificationSettings(form);
  const issues: FieldIssue[] = attempt ? all.map((i) => ({ field: i.field === 'quietHours' ? 'quiet-from' : 'pref-system', message: i.message })) : [];
  const paused = form.pausedUntil && new Date(form.pausedUntil).getTime() > now.getTime() ? form.pausedUntil : undefined;

  const setChannel = (category: NotificationCategory, channel: NotificationChannel, on: boolean) =>
    setForm((f) => ({ ...f, categories: f.categories.map((c) => (c.category === category ? { ...c, channels: { ...c.channels, [channel]: on } } : c)) }));

  const save = async () => {
    setAttempt((a) => a + 1);
    setError(null);
    if (all.length) return;
    setSaving(true);
    savingRef.current = true;
    try {
      const next = await services.notifications.saveSettings(recipientId, form);
      setSaved(next);
      setForm(next);
      toast({
        kind: 'success',
        title: 'Preferences saved',
        text: next.pausedUntil ? `Paused until ${formatDay(next.pausedUntil)}, ${formatTime(next.pausedUntil)}` : 'New notifications follow these settings.',
      });
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
      savingRef.current = false;
    }
  };

  const actions = (
    <div className={styles.formActions}>
      {dirty && <span className={styles.unsaved}>Unsaved changes</span>}
      <Button onClick={() => setForm(saved)} disabled={!dirty || saving}>
        Discard
      </Button>
      <Button variant="primary" onClick={save} loading={saving} disabled={!dirty} iconStart={<FloppyDisk size={16} />}>
        Save preferences
      </Button>
    </div>
  );

  return (
    <div className={styles.page}>
      <PageHeader
        back={{ label: 'Notifications', to: base }}
        title="Notification preferences"
        description="Choose what you hear about and how. Changes apply to new notifications once you save."
      />

      <div className={styles.form}>
        <ErrorSummary issues={issues} attempt={attempt} />
        {error && (
          <InlineMessage kind="error" title="Couldn’t save.">
            {error}
          </InlineMessage>
        )}

        <FormSection
          id="pause"
          title="Pause"
          description="Take a break. Important notifications — like a class going live that you registered for — still come through."
        >
          {paused ? (
            <InlineMessage
              kind="warn"
              title={`Paused until ${formatDay(paused)}, ${formatTime(paused)}`}
              action={
                <Button size="sm" iconStart={<Play size={14} />} onClick={() => setForm((f) => ({ ...f, pausedUntil: undefined }))}>
                  Resume now
                </Button>
              }
            >
              Only important notifications arrive until then.
            </InlineMessage>
          ) : (
            <div className={styles.pauseRow}>
              {PAUSES.map((p) => (
                <Button
                  key={p.value}
                  size="sm"
                  iconStart={<Pause size={14} />}
                  onClick={() => setForm((f) => ({ ...f, pausedUntil: pauseEnd(p.value, now).toISOString() }))}
                >
                  {p.label}
                </Button>
              ))}
            </div>
          )}
        </FormSection>

        {CATEGORY_GROUPS[role].map((group) => (
          <FormSection key={group.title} id={`group-${group.title.toLowerCase().replace(/\s+/g, '-')}`} title={group.title}>
            <div className={styles.prefTable} role="table" aria-label={`${group.title} notifications`}>
              {!isMobile && (
                <div className={styles.prefHead} role="row">
                  <span role="columnheader">Notification</span>
                  {NOTIFICATION_CHANNELS.map((ch) => (
                    <span key={ch} role="columnheader" className={styles.prefChannelHead}>
                      {CHANNEL_LABEL[ch]}
                    </span>
                  ))}
                </div>
              )}
              {group.categories.map((category) => {
                const pref = form.categories.find((c) => c.category === category)!;
                const meta = CATEGORY_META[category];
                return (
                  <div key={category} id={`pref-${category}`} tabIndex={-1} className={styles.prefRow} role="row">
                    <div className={styles.prefName} role="cell">
                      <CategoryIcon category={category} />
                      <span className={styles.prefText}>
                        <span className={styles.prefTitle}>{meta.plural}</span>
                        <span className={styles.muted}>{CATEGORY_DESCRIPTION[role][category]}</span>
                        {category === 'system' && (
                          <span className={styles.lockNote}>
                            <LockSimple size={13} aria-hidden="true" /> Always on in the app and by email, to keep your account safe.
                          </span>
                        )}
                      </span>
                    </div>
                    {NOTIFICATION_CHANNELS.map((ch) => (
                      <div key={ch} role="cell" className={styles.prefCell}>
                        <Switch
                          checked={pref.channels[ch]}
                          disabled={isLocked(category, ch)}
                          hideLabel={!isMobile}
                          label={isMobile ? CHANNEL_LABEL[ch] : `${meta.plural}: ${CHANNEL_LABEL[ch].toLowerCase()}`}
                          onChange={(on) => setChannel(category, ch, on)}
                        />
                      </div>
                    ))}
                  </div>
                );
              })}
            </div>
          </FormSection>
        ))}

        <FormSection id="email" title="Email" description="How email notifications are grouped. Important ones are always sent straight away.">
          <ChoiceCards<EmailDigest>
            legend="Email delivery"
            hideLegend
            columns={3}
            value={form.emailDigest}
            onChange={(v) => setForm((f) => ({ ...f, emailDigest: v }))}
            choices={[
              { value: 'instant', label: 'As they happen', description: 'One email for each notification.' },
              { value: 'daily', label: 'Daily summary', description: 'One email at 8 AM with the day before.' },
              { value: 'weekly', label: 'Weekly summary', description: 'One email on Monday at 8 AM.' },
            ]}
          />
        </FormSection>

        <FormSection
          id="quiet"
          title="Quiet hours and text messages"
          description={smsNumber ? `Text messages go to ${smsNumber}.` : 'Add a phone number to get text messages.'}
        >
          <Switch
            checked={form.quietHours.enabled}
            onChange={(on) => setForm((f) => ({ ...f, quietHours: { ...f.quietHours, enabled: on } }))}
            label="Hold text messages overnight"
            description="Nothing is texted between these times, India Standard Time. It all still arrives in the app."
          />
          <div className={styles.quietTimes}>
            <Field label="From" error={attempt && all.some((i) => i.field === 'quietHours') ? all.find((i) => i.field === 'quietHours')?.message : undefined}>
              <Input
                id="quiet-from"
                type="time"
                step={900}
                value={form.quietHours.from}
                disabled={!form.quietHours.enabled}
                onChange={(e) => setForm((f) => ({ ...f, quietHours: { ...f.quietHours, from: e.target.value } }))}
              />
            </Field>
            <Field label="Until">
              <Input
                type="time"
                step={900}
                value={form.quietHours.to}
                disabled={!form.quietHours.enabled}
                onChange={(e) => setForm((f) => ({ ...f, quietHours: { ...f.quietHours, to: e.target.value } }))}
              />
            </Field>
          </div>
        </FormSection>

        {!isMobile && actions}
      </div>

      {isMobile && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{actions}</div>}>
          <span />
        </StickyActionBar>
      )}

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description="Your notification preferences haven’t been saved."
        footer={
          <>
            <Button onClick={() => blocker.reset?.()}>Keep editing</Button>
            <Button variant="danger" onClick={() => blocker.proceed?.()}>
              Discard changes
            </Button>
          </>
        }
      />
    </div>
  );
}
