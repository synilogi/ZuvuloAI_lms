import { useEffect, useRef, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, CalendarCheck, CheckCircle, PlayCircle, VideoCamera } from '@phosphor-icons/react';
import type { LiveClass, LiveClassPhase } from '@syniastrolms/domain';
import { canJoin } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatDate, formatDuration, formatLongDay, formatRelative, formatTime, formatTimeRange, plural } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { DateBlock } from '@/components/lms/shared/WorkRow';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type LiveRow } from '@/services';
import { PhaseBadge, seatsText } from './liveMeta';
import { RecordingViewer, useLiveJoin } from './LiveRoom';
import { meetingHostNote } from './liveRules';
import styles from './Live.module.css';

/** A built-in room class in its window whose host hasn't opened it yet: the learner waits on this page. */
const waitingForHost = (phase: LiveClassPhase, c: LiveClass) => phase === 'starting-soon' && c.meeting?.kind === 'room' && !c.startedAt;

/** While a room waits for its host or is in session, the page looks again every 15 seconds: Join appears when the host
 * starts and goes when they end early, without a reload. */
function usePollWhile(active: boolean, refresh: () => void) {
  const latest = useRef(refresh);
  latest.current = refresh;
  useEffect(() => {
    if (!active) return;
    const t = window.setInterval(() => latest.current(), 15_000);
    return () => window.clearInterval(t);
  }, [active]);
}

/** Register or leave a class, with the places left. */
function RegisterButton({ liveClass, registered, onChange }: { liveClass: LiveClass; registered: boolean; onChange: () => void }) {
  const toast = useToast();
  const [busy, setBusy] = useState(false);
  const full = liveClass.capacity !== undefined && (liveClass.registered ?? 0) >= liveClass.capacity;
  const toggle = async () => {
    if (busy) return;
    setBusy(true);
    try {
      // The state wanted, not a toggle: a double tap or a retry can't undo itself.
      const r = await services.live.register(liveClass.id, !registered);
      toast(
        r.registered
          ? { kind: 'success', title: 'You’re registered', text: `${liveClass.title} · we’ll remind you before it starts` }
          : { kind: 'info', title: 'Registration cancelled', text: `Your place in ${liveClass.title} is free for someone else.` },
      );
      onChange();
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t register', text: (e as Error).message });
    } finally {
      setBusy(false);
    }
  };
  if (liveClass.cancelled) return null;
  return registered ? (
    <Button
      size="sm"
      iconStart={<CheckCircle size={15} weight="fill" />}
      loading={busy}
      disabled={busy}
      onClick={toggle}
      aria-label={`Registered for ${liveClass.title}. Cancel registration`}
    >
      Registered
    </Button>
  ) : (
    <Button size="sm" variant="primary" iconStart={<CalendarCheck size={15} />} loading={busy} disabled={full || busy} onClick={toggle}>
      {full ? 'Full' : 'Register'}
    </Button>
  );
}

export function LearnerLivePage() {
  const query = useAsync('learner-live', () => services.live.forLearner());
  const [watching, setWatching] = useState<LiveClass | null>(null);
  const data = query.data;
  const refresh = () => query.run().catch(() => undefined);
  const { join, busyId, inRoom, element: joinFlow } = useLiveJoin(refresh);
  // Read again while a room waits for its host — Join appears when they start — or is in session, since only the
  // server knows when the host ends it early.
  usePollWhile(
    !!data && (data.upcoming.some((r) => waitingForHost(r.phase, r.liveClass)) || data.live.some((r) => r.liveClass.meeting?.kind === 'room')) && !inRoom,
    refresh,
  );

  return (
    <div className={styles.page}>
      <PageHeader title="Live classes" description="Join a class while it’s on, book a place in the next ones, and watch recordings of any you missed." />
      {query.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Your live classes didn’t load"
          actions={
            <Button variant="primary" onClick={refresh}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      ) : !data ? (
        <div className={styles.skeletons} aria-busy="true">
          <Skeleton height={120} radius="var(--r-lg)" />
          <Skeleton height={76} radius="var(--r-md)" />
          <Skeleton height={76} radius="var(--r-md)" />
        </div>
      ) : data.live.length + data.upcoming.length + data.recordings.length === 0 ? (
        <StateMessage icon={<VideoCamera size={26} />} title="No live classes yet">
          Live classes from your courses appear here — with a reminder before each one starts.
        </StateMessage>
      ) : (
        <>
          {data.live.map((r) => (
            <section key={r.liveClass.id} className={styles.liveHero} aria-labelledby={`live-now-${r.liveClass.id}`}>
              <div className={styles.liveHeroText}>
                <PhaseBadge phase={r.phase} size="md" liveClass={r.liveClass} />
                <h2 id={`live-now-${r.liveClass.id}`} className={styles.liveHeroTitle}>
                  <Link to={`/live/${r.liveClass.id}`}>{r.liveClass.title}</Link>
                </h2>
                <span className={styles.sessionMeta}>
                  <Avatar name={r.instructorName} size={22} /> {r.instructorName} · {r.courseTitle} ·{' '}
                  {formatTimeRange(r.liveClass.startsAt, r.liveClass.durationMin)}
                </span>
                {r.liveClass.attending !== undefined && <span className={styles.muted}>{plural(r.liveClass.attending, 'learner')} joined so far</span>}
                {meetingHostNote(r.liveClass) && <span className={styles.muted}>{meetingHostNote(r.liveClass)}</span>}
              </div>
              {/* Joining takes a place if the learner had none, while there is one. */}
              <Button size="lg" variant="primary" iconStart={<VideoCamera size={18} />} loading={busyId === r.liveClass.id} onClick={() => join(r.liveClass)}>
                Join now
              </Button>
            </section>
          ))}

          <section aria-labelledby="upcoming-live">
            <SectionHeader id="upcoming-live" title="Coming up" count={data.upcoming.length || undefined} />
            {data.upcoming.length === 0 ? (
              <p className={styles.muted}>Nothing scheduled in your courses right now.</p>
            ) : (
              <ol className={styles.timeline}>
                {data.upcoming.map((r) => (
                  <LearnerRow
                    key={r.liveClass.id}
                    row={r}
                    registered={r.registered}
                    joining={busyId === r.liveClass.id}
                    onJoin={() => join(r.liveClass)}
                    onChange={refresh}
                  />
                ))}
              </ol>
            )}
          </section>

          <section aria-labelledby="recordings-live">
            <SectionHeader id="recordings-live" title="Recordings" count={data.recordings.length || undefined} />
            {data.recordings.length === 0 ? (
              <p className={styles.muted}>Recordings of past classes appear here.</p>
            ) : (
              <ul className={styles.recordings}>
                {data.recordings.slice(0, 9).map((r) => (
                  <li key={r.liveClass.id} className={styles.recordingCard}>
                    <button type="button" className={styles.recordingThumb} onClick={() => setWatching(r.liveClass)} aria-label={`Watch ${r.liveClass.title}`}>
                      <PlayCircle size={34} weight="fill" />
                      <span>{formatDuration(r.liveClass.recording?.durationMin ?? r.liveClass.durationMin)}</span>
                    </button>
                    <div className={styles.stack}>
                      <Link to={`/live/${r.liveClass.id}`} className={styles.cellTitle}>
                        {r.liveClass.title}
                      </Link>
                      <span className={styles.cellMeta}>
                        {formatDate(r.liveClass.startsAt)} · {r.instructorName}
                      </span>
                      {r.liveClass.recording && (
                        <span className={styles.cellMeta}>
                          {r.liveClass.recording.status === 'processing'
                            ? 'Being prepared'
                            : `Available until ${formatDate(r.liveClass.recording.availableUntil)}`}
                        </span>
                      )}
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </section>

          {!!data.history?.length && (
            <section aria-labelledby="history-live">
              <SectionHeader
                id="history-live"
                title="Your attendance"
                description="Past classes in the built-in room you held a place for, and whether you joined them from here."
              />
              <ul className={styles.attendees}>
                {data.history.map((r) => (
                  <li key={r.liveClass.id}>
                    <Link to={`/live/${r.liveClass.id}`} className={styles.attendee}>
                      <span className={styles.stack}>
                        <span className={styles.attendeeName}>{r.liveClass.title}</span>
                        <span className={styles.cellMeta}>
                          {formatDate(r.liveClass.startsAt)} · {r.courseTitle}
                        </span>
                      </span>
                      <span className={r.attended ? styles.attendedYes : styles.attendedNo}>{r.attended ? 'Joined' : 'Didn’t join'}</span>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          )}
        </>
      )}
      {joinFlow}
      {watching && <RecordingViewer open onClose={() => setWatching(null)} liveClass={watching} />}
    </div>
  );
}

function LearnerRow({
  row: r,
  registered,
  joining,
  onJoin,
  onChange,
}: {
  row: LiveRow;
  registered: boolean;
  joining: boolean;
  onJoin: () => void;
  onChange: () => void;
}) {
  const c = r.liveClass;
  return (
    <li className={styles.session} data-phase={r.phase}>
      <DateBlock iso={c.startsAt} highlight={r.phase === 'starting-soon'} />
      <div className={styles.sessionMain}>
        <span className={styles.sessionTime}>
          {formatTimeRange(c.startsAt, c.durationMin)} · {formatDuration(c.durationMin)}
        </span>
        <Link to={`/live/${c.id}`} className={styles.sessionTitle}>
          {c.title}
        </Link>
        <span className={styles.sessionMeta}>
          <Avatar name={r.instructorName} size={20} /> {r.instructorName} · {r.courseTitle}
          {meetingHostNote(c) && <> · {meetingHostNote(c)}</>}
        </span>
      </div>
      <div className={styles.sessionSeats}>
        {r.phase === 'cancelled' ? (
          <span className={styles.muted}>{c.cancelReason}</span>
        ) : waitingForHost(r.phase, c) ? (
          <span className={styles.muted}>Waiting for {r.instructorName} to start</span>
        ) : (
          <span>{seatsText(c.registered, c.capacity)}</span>
        )}
      </div>
      <div className={styles.sessionStatus}>
        <PhaseBadge phase={r.phase} liveClass={r.liveClass} />
      </div>
      <div className={styles.sessionAction}>
        {canJoin(r.phase, c) ? (
          <Button size="sm" variant="primary" iconStart={<VideoCamera size={15} />} loading={joining} onClick={onJoin}>
            Join
          </Button>
        ) : (
          <RegisterButton liveClass={c} registered={registered} onChange={onChange} />
        )}
      </div>
    </li>
  );
}

/** One line under the time that says what this phase means for the learner. */
function learnerPhaseNote(phase: LiveClassPhase, c: LiveClass, now: Date) {
  switch (phase) {
    case 'upcoming':
      return `Starts ${formatRelative(c.startsAt, now)} · ${seatsText(c.registered, c.capacity)}`;
    case 'starting-soon':
      return waitingForHost(phase, c)
        ? 'Waiting for the instructor to start the class — Join appears here when they do'
        : c.meeting?.kind === 'external'
          ? `Starts ${formatRelative(c.startsAt, now)} — the meeting link opens from here`
          : `Starts ${formatRelative(c.startsAt, now)} — the room is open`;
    case 'live':
      return c.attending !== undefined ? `${plural(c.attending, 'learner')} joined so far` : 'In progress';
    case 'ended':
      return c.recording?.status === 'processing'
        ? 'The recording is being prepared'
        : c.recording
          ? `Recording available until ${formatDate(c.recording.availableUntil)}`
          : 'This class has ended';
    case 'recording-expired':
      return c.recording ? 'The recording is no longer available' : 'This class has ended';
    case 'cancelled':
      return c.cancelReason ?? 'This class was cancelled';
  }
}

export function LearnerLiveClassPage() {
  const { liveId } = useParams();
  const now = useNow();
  const query = useAsync(`learner-live-detail:${liveId}`, () => Promise.all([services.live.get(liveId!), services.live.forLearner()]));
  const [watching, setWatching] = useState(false);
  const refresh = () => query.run().catch(() => undefined);
  const { join, busyId, inRoom, element: joinFlow } = useLiveJoin(refresh);
  usePollWhile(
    !!query.data &&
      (waitingForHost(query.data[0].phase, query.data[0].liveClass) || (query.data[0].phase === 'live' && query.data[0].liveClass.meeting?.kind === 'room')) &&
      !inRoom,
    refresh,
  );
  usePageCrumbs(query.data ? [{ label: query.data[0].liveClass.title }] : [{ label: 'Live class' }]);

  if (query.status === 'error' && !query.data) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title="This class isn’t available"
          actions={
            <LinkButton to="/live" iconStart={<ArrowLeft size={16} />}>
              Back to live classes
            </LinkButton>
          }
        >
          It may be for a course you’re not enrolled in.
        </StateMessage>
      </div>
    );
  }
  if (!query.data || query.data[0].liveClass.id !== liveId) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton height={360} radius="var(--r-lg)" />
      </div>
    );
  }
  const [d, mine] = query.data;
  const c = d.liveClass;
  const registered = d.registered ?? [...mine.live, ...mine.upcoming].some((u) => u.liveClass.id === c.id && u.registered);
  const over = d.phase === 'ended' || d.phase === 'recording-expired';
  let minute = 0;
  const startMs = new Date(c.startsAt).getTime();
  return (
    <div className={styles.narrowPage}>
      <PageHeader
        back={{ label: 'Live classes', to: '/live' }}
        eyebrow={d.courseTitle}
        title={c.title}
        meta={<PhaseBadge phase={d.phase} size="md" liveClass={c} />}
      />
      <section className={styles.sessionPanel} data-phase={d.phase} aria-label="When and how to join">
        <DateBlock iso={c.startsAt} highlight={d.phase === 'live' || d.phase === 'starting-soon'} />
        <div className={styles.sessionPanelText}>
          <strong>{formatLongDay(c.startsAt)}</strong>
          <span>
            {formatTimeRange(c.startsAt, c.durationMin)} · {formatDuration(c.durationMin)}
          </span>
          <span className={styles.muted}>{learnerPhaseNote(d.phase, c, now)}</span>
          {meetingHostNote(c) && !over && d.phase !== 'cancelled' && <span className={styles.muted}>{meetingHostNote(c)}</span>}
          {over && d.attended !== undefined && (
            <span className={d.attended ? styles.attendedYes : styles.attendedNo}>{d.attended ? 'You joined this class' : 'You didn’t join this class'}</span>
          )}
        </div>
        <div className={styles.sessionPanelAction}>
          {canJoin(d.phase, c) ? (
            <Button variant="primary" iconStart={<VideoCamera size={16} />} loading={busyId === c.id} onClick={() => join(c)}>
              {d.phase === 'live' ? 'Join now' : 'Join class'}
            </Button>
          ) : d.phase === 'ended' && c.recording?.status === 'ready' ? (
            <Button variant="primary" iconStart={<PlayCircle size={16} />} onClick={() => setWatching(true)}>
              Watch recording
            </Button>
          ) : d.phase === 'upcoming' || canJoin(d.phase) ? (
            // Not registered yet — take a place first; the room opens once it is held.
            <RegisterButton liveClass={c} registered={registered} onChange={refresh} />
          ) : null}
        </div>
      </section>
      {c.description && (
        <section className={styles.panel} aria-labelledby="learner-live-about">
          <SectionHeader id="learner-live-about" title="About this class" />
          <p className={styles.description}>{c.description}</p>
          <span className={styles.instructor}>
            <Avatar name={d.instructorName} size={40} />
            <span className={styles.stack}>
              <strong>{d.instructorName}</strong>
              <span className={styles.cellMeta}>{d.instructorTitle}</span>
            </span>
          </span>
        </section>
      )}
      {c.agenda && c.agenda.length > 0 && (
        <section className={styles.panel} aria-labelledby="learner-live-agenda">
          <SectionHeader
            id="learner-live-agenda"
            title="Agenda"
            description={`${plural(d.attendeeTotal, 'learner')} ${d.phase === 'ended' ? 'registered' : 'going'}`}
          />
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
      {joinFlow}
      {watching && <RecordingViewer open onClose={() => setWatching(false)} liveClass={c} />}
    </div>
  );
}
