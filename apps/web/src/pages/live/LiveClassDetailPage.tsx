import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  ArrowLeft,
  BellRinging,
  CalendarPlus,
  CaretLeft,
  CaretRight,
  CheckCircle,
  Copy,
  PencilSimple,
  PlayCircle,
  Prohibit,
  StopCircle,
  UsersThree,
  VideoCamera,
} from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { usePermissions } from '@/hooks/usePermissions';
import { useSession } from '@/providers/SessionProvider';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatDate, formatDuration, formatLongDay, formatTime, formatTimeRange, plural } from '@/lib/format';
import { SectionHeader } from '@/components/page/PageHeader';
import { PageHeader } from '@/components/page/PageHeader';
import { Switch } from '@/components/forms/Forms';
import { Avatar, AvatarGroup } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Field, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Meter } from '@/components/lms/progress/Meters';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { PhaseBadge, REMINDER_OPTIONS, seatsText } from './liveMeta';
import { PublicServerNote, RecordingViewer, RoomCheck, openExternalRoom } from './LiveRoom';
import { staffLiveActions } from './liveRules';
import styles from './Live.module.css';

/** A cancel reason, as the API takes it: a few words at least. */
const REASON_MIN = 3;

export default function LiveClassDetailPage() {
  const { liveId } = useParams();
  const { base, instructorId, isTeaching } = useWorkspace();
  const { user } = useSession();
  const { can } = usePermissions();
  const now = useNow();
  const toast = useToast();
  const query = useAsync(`live-detail:${liveId}`, () => services.live.get(liveId!, instructorId));
  const [room, setRoom] = useState(false);
  const [ending, setEnding] = useState(false);
  const [recording, setRecording] = useState(false);
  const [cancelling, setCancelling] = useState(false);
  const [reason, setReason] = useState('');
  const [reasonTried, setReasonTried] = useState(false);
  const [sending, setSending] = useState(false);
  const [savingReminders, setSavingReminders] = useState(false);
  const [copied, setCopied] = useState(false);
  usePageCrumbs(query.data ? [{ label: query.data.liveClass.title }] : [{ label: 'Live class' }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Live class not found' : 'This class didn’t load'}
          actions={
            notFound ? (
              <LinkButton to={`${base}/live`} iconStart={<ArrowLeft size={16} />}>
                Back to live classes
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!query.data || query.data.liveClass.id !== liveId) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="45%" height={30} radius="var(--r-xs)" />
        <div className={styles.detailGrid}>
          <Skeleton height={520} radius="var(--r-lg)" />
          <Skeleton height={360} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }

  const d = query.data;
  const c = d.liveClass;
  const refresh = () => query.run().catch(() => undefined);
  const upcoming = d.phase === 'upcoming' || d.phase === 'starting-soon';
  const ended = d.phase === 'ended' || d.phase === 'recording-expired';
  const builtIn = c.meeting?.kind !== 'external';
  // Learners open the class's own page, where the Join button appears once the host starts it.
  const roomLink = builtIn ? `${window.location.origin}/live/${c.id}` : (c.meeting?.link ?? '');
  // Only what the API would let this account do, now: an admin needs `live.manage` to run classes, `live.notify` for reminders.
  const actions = staffLiveActions(d, can, now);
  const canStart = actions.start;
  const roomOpen = builtIn && d.phase === 'live' && !!c.startedAt;
  const unconfigured = builtIn && d.room?.configured === false;
  const publicServer = builtIn && d.room?.provider === 'jitsi' && !unconfigured;
  const endClass = async () => {
    await services.live.end(c.id);
    toast({ kind: 'success', title: 'Class ended', text: 'Learners who held a place and never joined are marked as not joined.' });
    refresh();
  };

  const remindNow = async () => {
    setSending(true);
    try {
      const { sent } = await services.live.sendReminder(c.id);
      toast({
        kind: 'success',
        title: `Reminder sent to ${plural(sent, 'learner')}`,
        text: `${c.title} · ${formatLongDay(c.startsAt)}, ${formatTime(c.startsAt)}`,
      });
    } catch (e) {
      toast({ kind: 'error', title: 'Reminder not sent', text: (e as Error).message });
    } finally {
      setSending(false);
    }
  };
  const toggleReminder = async (minutes: number, on: boolean) => {
    const next = on ? [...(c.reminders ?? []), minutes] : (c.reminders ?? []).filter((m) => m !== minutes);
    setSavingReminders(true);
    try {
      await services.live.setReminders(c.id, next);
    } catch (e) {
      toast({ kind: 'error', title: 'Reminders not changed', text: (e as Error).message });
    } finally {
      setSavingReminders(false);
      refresh();
    }
  };
  const reasonShort = reason.trim().length < REASON_MIN;
  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(roomLink);
      setCopied(true);
    } catch {
      setCopied(false);
    }
  };

  let minute = 0;
  const startMs = new Date(c.startsAt).getTime();

  return (
    <div className={styles.page}>
      <PageHeader
        back={{ label: 'Live classes', to: `${base}/live` }}
        eyebrow={d.courseTitle}
        title={c.title}
        meta={<PhaseBadge phase={d.phase} size="md" liveClass={c} />}
        actions={
          <div className={styles.headerActions}>
            {(canStart || actions.rejoin) && (
              <Button variant="primary" iconStart={<VideoCamera size={16} />} onClick={() => setRoom(true)}>
                {roomOpen ? 'Rejoin as host' : 'Start class'}
              </Button>
            )}
            {actions.end && (
              <Button variant="danger" iconStart={<StopCircle size={16} />} onClick={() => setEnding(true)}>
                End class
              </Button>
            )}
            {actions.openMeeting && (
              <Button variant="primary" iconStart={<VideoCamera size={16} />} onClick={() => openExternalRoom(c)}>
                Open meeting
              </Button>
            )}
            {actions.edit && (
              <LinkButton to={`${base}/live/${c.id}/edit`} iconStart={<PencilSimple size={16} />}>
                Edit
              </LinkButton>
            )}
            {d.phase === 'ended' && c.recording?.status === 'ready' && (
              <Button variant="primary" iconStart={<PlayCircle size={16} />} onClick={() => setRecording(true)}>
                Watch recording
              </Button>
            )}
            {actions.scheduleAgain && (
              // A cancelled class is run again as a new class copied from it; a past one gets a follow-up in its course.
              <LinkButton
                to={d.phase === 'cancelled' ? `${base}/live/new?from=${c.id}` : `${base}/live/new?course=${c.courseId}`}
                iconStart={<CalendarPlus size={16} />}
              >
                {d.phase === 'cancelled' ? 'Reschedule' : 'Schedule a follow-up'}
              </LinkButton>
            )}
          </div>
        }
      />

      {d.phase === 'cancelled' && (
        <InlineMessage kind="warn" title="Cancelled">
          {c.cancelReason} Registered learners were told by email and in the app.
        </InlineMessage>
      )}
      {d.phase === 'live' && (
        <InlineMessage kind="error" title="Live now">
          {builtIn
            ? `${plural(c.attending ?? 0, 'learner')} joined so far. Scheduled to finish at ${formatTime(new Date(startMs + c.durationMin * 60_000).toISOString())} — end the class when you’re done.`
            : `The class runs in its outside meeting until ${formatTime(new Date(startMs + c.durationMin * 60_000).toISOString())}.`}
        </InlineMessage>
      )}
      {canStart && (
        <InlineMessage kind="info" title={new Date(c.startsAt) <= now ? 'Learners are waiting' : 'You can open the room now'}>
          Learners can join once you start the class. They are told the moment you do.
        </InlineMessage>
      )}
      {publicServer && (canStart || (upcoming && actions.edit)) && <PublicServerNote />}
      {unconfigured && !c.cancelled && (upcoming || d.phase === 'live') && (
        <InlineMessage kind="warn" title="The live room isn’t set up yet">
          This server has no video service connected, so the built-in room can’t start. Ask the platform team to connect it, or edit the class to use an outside
          meeting link.
        </InlineMessage>
      )}

      <div className={styles.detailGrid}>
        <div className={styles.column}>
          <section className={styles.panel} aria-labelledby="session-title">
            <SectionHeader id="session-title" title="Session" />
            <dl className={styles.sessionFacts}>
              <div>
                <dt>When</dt>
                <dd>
                  {formatLongDay(c.startsAt)} · {formatTimeRange(c.startsAt, c.durationMin)}
                </dd>
              </div>
              <div>
                <dt>Length</dt>
                <dd>{formatDuration(c.durationMin)}</dd>
              </div>
              <div>
                <dt>Room</dt>
                <dd className={styles.roomRow}>
                  <span className={styles.truncate}>{builtIn ? 'Built-in live room' : roomLink || 'Outside meeting'}</span>
                  {!ended && d.phase !== 'cancelled' && roomLink && (
                    <Button size="sm" variant="ghost" iconStart={copied ? <CheckCircle size={14} /> : <Copy size={14} />} onClick={copyLink}>
                      {copied ? 'Copied' : builtIn ? 'Copy class link' : 'Copy link'}
                    </Button>
                  )}
                </dd>
              </div>
              <div>
                <dt>Who can join</dt>
                {/* "Cohort" lets in everyone enrolled, the same as "enrolled": nothing narrows it further. */}
                <dd>{c.visibility === 'public' ? 'Any signed-in learner' : `Learners enrolled in ${d.courseTitle}`}</dd>
              </div>
              <div>
                <dt>Places</dt>
                <dd className={styles.seatsRow}>
                  <span>{seatsText(c.registered, c.capacity)}</span>
                  {c.capacity !== undefined && (
                    <Meter value={((c.registered ?? 0) / c.capacity) * 100} size="sm" label={`${seatsText(c.registered, c.capacity)} taken`} />
                  )}
                </dd>
              </div>
              {/* Only the built-in room knows who came in — and only that they joined from the platform. An outside meeting has no record. */}
              {ended && builtIn && c.attended !== undefined && (
                <div>
                  <dt>Joined</dt>
                  <dd>
                    {c.attended} of {c.registered} ({Math.round((c.attended / Math.max(1, c.registered ?? 1)) * 100)}%)
                  </dd>
                </div>
              )}
            </dl>
            {c.description && <p className={styles.description}>{c.description}</p>}
          </section>

          {c.agenda && c.agenda.length > 0 && (
            <section className={styles.panel} aria-labelledby="agenda-title">
              <SectionHeader id="agenda-title" title="Agenda" />
              <ol className={styles.agenda}>
                {c.agenda.map((a, i) => {
                  const at = new Date(startMs + minute * 60_000).toISOString();
                  minute += a.minutes;
                  return (
                    <li key={i}>
                      <span className={styles.agendaTime}>{formatTime(at)}</span>
                      <span className={styles.agendaTitle}>{a.title}</span>
                      <span className={styles.muted}>{a.minutes} min</span>
                    </li>
                  );
                })}
              </ol>
            </section>
          )}

          <section className={styles.panel} aria-labelledby="attendees-title">
            <SectionHeader
              id="attendees-title"
              title={builtIn && (ended || roomOpen) ? 'Attendance' : 'Registered learners'}
              count={d.attendeeTotal || undefined}
              description={
                d.attendeeTotal
                  ? undefined
                  : d.phase === 'cancelled'
                    ? 'Registrations were released when the class was cancelled.'
                    : 'Nobody has registered yet. Learners of the course see the class in their schedule.'
              }
            />
            {d.attendees.length > 0 && (
              <>
                <AvatarGroup names={d.attendees.map((a) => a.name)} max={8} size={32} label={`${plural(d.attendeeTotal, 'learner')}`} />
                <ul className={styles.attendees}>
                  {d.attendees.map((a) => (
                    <li key={a.id}>
                      <Link to={`${base}/students/${a.id}`} className={styles.attendee}>
                        <Avatar name={a.name} size={28} />
                        <span className={styles.stack}>
                          <span className={styles.attendeeName}>{a.name}</span>
                          <span className={styles.cellMeta}>{a.city}</span>
                        </span>
                        {builtIn && a.attended !== undefined && (
                          <span className={a.attended ? styles.attendedYes : styles.attendedNo}>
                            {a.attended ? (a.joinedAt ? `Joined ${formatTime(a.joinedAt)}` : 'Joined') : 'Didn’t join'}
                          </span>
                        )}
                        {/* Opening an outside meeting's link is all the platform sees — not whether they stayed. */}
                        {!builtIn && a.joinedAt && <span className={styles.cellMeta}>Opened the link {formatTime(a.joinedAt)}</span>}
                      </Link>
                    </li>
                  ))}
                </ul>
                {d.attendeeTotal > d.attendees.length && <p className={styles.muted}>and {plural(d.attendeeTotal - d.attendees.length, 'more learner')}</p>}
              </>
            )}
          </section>
        </div>

        <aside className={styles.column} aria-label="Class details">
          <section className={styles.panel} aria-labelledby="instructor-title">
            <SectionHeader id="instructor-title" title="Instructor" />
            {isTeaching ? (
              <span className={styles.instructor}>
                <Avatar name={d.instructorName} size={44} />
                <span className={styles.stack}>
                  <strong>{d.instructorName}</strong>
                  <span className={styles.cellMeta}>{d.instructorTitle}</span>
                </span>
              </span>
            ) : (
              <Link to={`/admin/instructors/${c.instructorId}`} className={styles.instructor}>
                <Avatar name={d.instructorName} size={44} />
                <span className={styles.stack}>
                  <strong>{d.instructorName}</strong>
                  <span className={styles.cellMeta}>{d.instructorTitle}</span>
                </span>
              </Link>
            )}
          </section>

          {upcoming && (actions.reminders || actions.remind) && (
            <section className={styles.panel} aria-labelledby="reminders-title">
              <SectionHeader id="reminders-title" title="Reminders" description="Sent to registered learners by email and in the app." />
              {actions.reminders &&
                REMINDER_OPTIONS.map((o) => (
                  <Switch
                    key={o.minutes}
                    checked={(c.reminders ?? []).includes(o.minutes)}
                    disabled={savingReminders}
                    onChange={(on) => toggleReminder(o.minutes, on)}
                    label={o.label}
                  />
                ))}
              {actions.remind && (
                <>
                  <Button iconStart={<BellRinging size={16} />} loading={sending} disabled={!c.registered} onClick={remindNow}>
                    Send a reminder now
                  </Button>
                  {!c.registered && <p className={styles.muted}>Nobody has registered yet, so there’s no one to remind.</p>}
                </>
              )}
            </section>
          )}

          {c.recording ? (
            <section className={styles.panel} aria-labelledby="recording-title">
              <SectionHeader id="recording-title" title="Recording" />
              <p className={styles.muted}>
                {c.recording.status === 'processing'
                  ? 'Being prepared — usually ready a few minutes after the class.'
                  : `${formatDuration(c.recording.durationMin)} · ${
                      d.phase === 'recording-expired'
                        ? `expired ${formatDate(c.recording.availableUntil)}`
                        : `available until ${formatDate(c.recording.availableUntil)}`
                    }${d.recordingViews ? ` · ${plural(d.recordingViews, 'view')}` : ''}`}
              </p>
            </section>
          ) : (
            builtIn &&
            d.room &&
            d.phase !== 'cancelled' && (
              <section className={styles.panel} aria-labelledby="recording-title">
                <SectionHeader id="recording-title" title="Recording" />
                <p className={styles.muted}>
                  {d.room.recording
                    ? ended
                      ? 'No recording was made of this class.'
                      : 'Start recording from the room’s menu. The recording appears here for learners after the class.'
                    : publicServer
                      ? 'Classes on the public meet.jit.si server aren’t recorded.'
                      : 'The platform’s video service doesn’t record classes yet.'}
                </p>
              </section>
            )
          )}

          {(d.previous || d.next) && (
            <section className={styles.panel} aria-labelledby="series-title">
              <SectionHeader id="series-title" title={`More in ${d.courseTitle}`} />
              {d.previous && (
                <Link to={`${base}/live/${d.previous.id}`} className={styles.sibling}>
                  <CaretLeft size={16} aria-hidden="true" />
                  <span className={styles.stack}>
                    <span className={styles.cellMeta}>Previous · {formatDate(d.previous.startsAt)}</span>
                    <span>{d.previous.title}</span>
                  </span>
                </Link>
              )}
              {d.next && (
                <Link to={`${base}/live/${d.next.id}`} className={styles.sibling}>
                  <span className={styles.stack}>
                    <span className={styles.cellMeta}>Next · {formatDate(d.next.startsAt)}</span>
                    <span>{d.next.title}</span>
                  </span>
                  <CaretRight size={16} aria-hidden="true" />
                </Link>
              )}
            </section>
          )}

          {actions.cancel && (
            <Button variant="ghost" iconStart={<Prohibit size={16} />} onClick={() => setCancelling(true)} className={styles.cancelButton}>
              Cancel this class…
            </Button>
          )}
          {builtIn && !ended && d.phase !== 'cancelled' && (
            <p className={styles.muted}>
              <UsersThree size={14} aria-hidden="true" /> Learners who open the room from the platform are marked as joined.
            </p>
          )}
        </aside>
      </div>

      {room && (
        <RoomCheck
          open
          onClose={() => {
            setRoom(false);
            refresh();
          }}
          liveClass={c}
          name={user.name}
          host
          provider={d.room?.provider}
          enter={async () => {
            if (c.startedAt) {
              const j = await services.live.join(c.id);
              if (j.kind !== 'room') throw new Error('This class runs on an outside meeting link.');
              return j.room;
            }
            return (await services.live.start(c.id)).room;
          }}
          onEnd={endClass}
        />
      )}
      {ending && (
        <ConfirmDialog
          open
          onClose={() => setEnding(false)}
          onConfirm={async () => {
            await endClass();
            setEnding(false);
          }}
          tone="danger"
          icon={<StopCircle size={20} />}
          title="End this class?"
          description={c.title}
          confirmLabel="End class"
        >
          <ul className={styles.impact}>
            <li>The room closes and nobody else can join.</li>
            <li>
              {plural(c.attending ?? 0, 'learner')} who joined from the platform stay marked as joined; anyone who held a place and never joined is marked as
              not joined.
            </li>
          </ul>
        </ConfirmDialog>
      )}
      <RecordingViewer open={recording} onClose={() => setRecording(false)} liveClass={c} />
      {cancelling && (
        <ConfirmDialog
          open
          onClose={() => {
            setCancelling(false);
            setReason('');
            setReasonTried(false);
          }}
          blocked={reasonTried && reasonShort}
          onConfirm={async () => {
            setReasonTried(true);
            // The dialog stays open, with the field's message, until there is a reason to send.
            if (reasonShort) return;
            await services.live.cancel(c.id, reason.trim());
            toast({ kind: 'success', title: 'Class cancelled', text: `${plural(c.registered ?? 0, 'learner')} told · ${c.title}` });
            setCancelling(false);
            setReason('');
            setReasonTried(false);
            refresh();
          }}
          tone="danger"
          icon={<Prohibit size={20} />}
          title="Cancel this class?"
          description={`${c.title} · ${formatLongDay(c.startsAt)}, ${formatTime(c.startsAt)}`}
          confirmLabel="Cancel class"
        >
          <div className={styles.dialogBody}>
            <ul className={styles.impact}>
              <li>{plural(c.registered ?? 0, 'registered learner')} are told straight away, with your reason.</li>
              <li>Reminders stop, and the class stays listed as cancelled.</li>
            </ul>
            <Field
              label="Reason for learners"
              hint="A sentence is enough — and a word on when it’ll run instead, if you know."
              error={reasonTried && reasonShort ? 'Give learners a reason — a few words at least.' : undefined}
            >
              <Textarea
                rows={3}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="I’m travelling that week. We’ll cover this in the Saturday class instead."
              />
            </Field>
          </div>
        </ConfirmDialog>
      )}
    </div>
  );
}
