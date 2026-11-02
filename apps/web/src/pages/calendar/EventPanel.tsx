import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { ArrowSquareOut, CheckCircle, Circle, PencilSimple, Trash, WarningCircle } from '@phosphor-icons/react';
import { calendarEventEnd } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatDuration, formatLongDay, formatRelative, plural } from '@/lib/format';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Meter } from '@/components/lms/progress/Meters';
import { services, type CalendarDetail } from '@/services';
import { EventBadge, eventState, MILESTONE_LABEL, notifyLabel, timeText, TYPE_META } from './calendarMeta';
import styles from './Calendar.module.css';

interface EventPanelProps {
  eventId: string;
  base: string;
  viewerId: string;
  scopeInstructorId?: string;
  onClose: () => void;
  /** After a change, so the calendar reloads. */
  onChanged: () => void;
  onLoaded?: (detail: CalendarDetail) => void;
}

/** Event detail over the calendar: a drawer on desktop, a bottom sheet on phones. */
export function EventPanel({ eventId, base, viewerId, scopeInstructorId, onClose, onChanged, onLoaded }: EventPanelProps) {
  const detail = useAsync(`calendar-event:${eventId}`, () => services.calendar.get(eventId, viewerId, scopeInstructorId));
  const now = useNow();
  const toast = useToast();
  const navigate = useNavigate();
  const [deleting, setDeleting] = useState(false);
  const [marking, setMarking] = useState(false);
  const loaded = useRef(onLoaded);
  loaded.current = onLoaded;
  const d = detail.data?.event.id === eventId ? detail.data : undefined;

  useEffect(() => {
    if (d) loaded.current?.(d);
  }, [d]);

  const e = d?.event;
  const past = e ? calendarEventEnd(e).getTime() <= now.getTime() : false;
  const state = d ? eventState(d, now) : 'upcoming';

  const markDone = async () => {
    if (!e) return;
    setMarking(true);
    try {
      await services.calendar.setDone(e.id, !e.done);
      toast({ kind: 'success', title: e.done ? 'Marked as not done' : 'Reminder done', text: e.title });
      await detail.run();
      onChanged();
    } catch (err) {
      toast({ kind: 'error', title: 'Couldn’t update the reminder', text: (err as Error).message });
    } finally {
      setMarking(false);
    }
  };

  const remove = async () => {
    if (!e) return;
    await services.calendar.remove(e.id);
    toast({ kind: 'success', title: 'Event deleted', text: e.title });
    setDeleting(false);
    onChanged();
    onClose();
  };

  const footer = (() => {
    if (!d || !e) return undefined;
    if (e.source?.kind === 'live-class') {
      return (
        <>
          {(d.phase === 'upcoming' || d.phase === 'starting-soon') && (
            <LinkButton to={`${base}/live/${e.source.id}/edit`} iconStart={<PencilSimple size={16} />}>
              Edit class
            </LinkButton>
          )}
          <LinkButton variant="primary" to={`${base}/live/${e.source.id}`} iconEnd={<ArrowSquareOut size={15} />}>
            Open class
          </LinkButton>
        </>
      );
    }
    if (e.source?.kind === 'assignment') {
      return (
        <>
          <LinkButton to={`${base}/assignments/${e.source.id}`} iconStart={<PencilSimple size={16} />}>
            Edit assignment
          </LinkButton>
          <LinkButton variant="primary" to={`${base}/assignments/${e.source.id}/submissions`} iconEnd={<ArrowSquareOut size={15} />}>
            Submissions
          </LinkButton>
        </>
      );
    }
    return (
      <>
        <Button variant="ghost" iconStart={<Trash size={16} />} onClick={() => setDeleting(true)}>
          Delete
        </Button>
        {!past && (
          <Button iconStart={<PencilSimple size={16} />} onClick={() => navigate(`${base}/calendar/${e.id}/edit`)}>
            Edit
          </Button>
        )}
        {e.type === 'reminder' ? (
          <Button variant="primary" loading={marking} iconStart={e.done ? <Circle size={16} /> : <CheckCircle size={16} />} onClick={markDone}>
            {e.done ? 'Mark as not done' : 'Mark as done'}
          </Button>
        ) : e.type === 'quiz' && e.quizId ? (
          <LinkButton variant="primary" to={`${base}/quizzes/${e.quizId}`} iconEnd={<ArrowSquareOut size={15} />}>
            Open quiz
          </LinkButton>
        ) : e.courseId ? (
          <LinkButton variant="primary" to={`${base}/courses/${e.courseId}`} iconEnd={<ArrowSquareOut size={15} />}>
            Open course
          </LinkButton>
        ) : null}
      </>
    );
  })();

  return (
    <AdaptivePanel open onClose={onClose} eyebrow={e ? TYPE_META[e.type].label : 'Event'} title={e?.title ?? 'Event'} width={460} footer={footer}>
      {detail.status === 'error' && !d ? (
        <StateMessage kind="error" title={(detail.error as { code?: string }).code === 'not-found' ? 'Event not found' : 'The event didn’t load'} compact>
          {detail.error.message}
        </StateMessage>
      ) : !d || !e ? (
        <div className={styles.panelSkeleton} aria-busy="true">
          <Skeleton width="40%" height={14} />
          <Skeleton height={120} radius="var(--r-md)" />
          <Skeleton width="80%" height={12} />
        </div>
      ) : (
        <div className={styles.panelBody}>
          <div className={styles.panelTags}>
            <EventBadge row={d} now={now} />
          </div>

          <dl className={styles.facts}>
            <dt>When</dt>
            <dd>
              <span className={styles.factStrong}>{formatLongDay(e.startsAt)}</span>
              <span>
                {timeText(e)}
                {e.timing !== 'all-day' && ' IST'}
                {state !== 'cancelled' && !past && ` · ${formatRelative(e.startsAt, now)}`}
              </span>
            </dd>
            {e.timing === 'timed' && e.durationMin !== undefined && (
              <>
                <dt>Length</dt>
                <dd>{formatDuration(e.durationMin)}</dd>
              </>
            )}
            {d.courseTitle && e.courseId && (
              <>
                <dt>Course</dt>
                <dd>
                  <Link to={`${base}/courses/${e.courseId}`} className={styles.inlineLink}>
                    {d.courseTitle}
                  </Link>
                  {d.chapterTitle && <span className={styles.muted}>Chapter · {d.chapterTitle}</span>}
                </dd>
              </>
            )}
            {e.milestone && (
              <>
                <dt>Milestone</dt>
                <dd>{MILESTONE_LABEL[e.milestone]}</dd>
              </>
            )}
            {d.instructorName && e.type !== 'reminder' && (
              <>
                <dt>{e.type === 'live' ? 'Instructor' : 'Lead instructor'}</dt>
                <dd className={styles.person}>
                  <Avatar name={d.instructorName} size={28} />
                  <span className={styles.stack}>
                    <span className={styles.factStrong}>{d.instructorName}</span>
                    {d.instructorTitle && <span className={styles.muted}>{d.instructorTitle}</span>}
                  </span>
                </dd>
              </>
            )}
            <dt>Who’s included</dt>
            <dd>{audienceText(d)}</dd>
            <dt>Notification</dt>
            <dd>{e.type === 'assignment' ? 'Learners are reminded a day before' : notifyLabel(e.notifyMin)}</dd>
          </dl>

          {e.description && <p className={styles.panelDescription}>{e.description}</p>}

          {d.live && (
            <div className={styles.panelBlock}>
              {past && d.live.attended !== undefined ? (
                <Meter
                  value={d.live.registered ? (d.live.attended / d.live.registered) * 100 : 0}
                  showLabel
                  label="Attended"
                  valueText={`${d.live.attended} of ${d.live.registered}`}
                  size="sm"
                />
              ) : d.live.capacity ? (
                <Meter
                  value={(d.live.registered / d.live.capacity) * 100}
                  showLabel
                  label="Places taken"
                  valueText={`${d.live.registered} of ${d.live.capacity}`}
                  size="sm"
                  tone="info"
                />
              ) : (
                <span className={styles.muted}>{plural(d.live.registered, 'learner')} registered</span>
              )}
            </div>
          )}

          {d.due && (
            <div className={styles.panelBlock}>
              <Meter
                value={d.due.learners ? (d.due.submitted / d.due.learners) * 100 : 0}
                showLabel
                label="Handed in"
                valueText={`${d.due.submitted} of ${d.due.learners}`}
                size="sm"
                tone="warn"
              />
              {d.learnersDue && d.learnersDue.length > 0 && (
                <ul className={styles.learners} aria-label="Learners due">
                  {d.learnersDue.map((l) => (
                    <li key={l.id}>
                      <Avatar name={l.name} size={24} />
                      <span className={styles.truncate}>{l.name}</span>
                      <span className={styles.learnerState} data-submitted={l.submitted || undefined}>
                        {l.submitted ? <CheckCircle size={14} weight="fill" aria-hidden="true" /> : <Circle size={14} aria-hidden="true" />}
                        {l.submitted ? 'Handed in' : past ? 'Missing' : 'Not yet'}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
              {d.due.learners > (d.learnersDue?.length ?? 0) && (
                <span className={styles.muted}>and {plural(d.due.learners - (d.learnersDue?.length ?? 0), 'other learner')}</span>
              )}
            </div>
          )}

          {d.quiz && (
            <div className={styles.panelBlock}>
              <span className={styles.factStrong}>{d.quiz.title}</span>
              <span className={styles.muted}>
                {plural(d.quiz.questions, 'question')} · {d.quiz.timeLimitMin ? `${formatDuration(d.quiz.timeLimitMin)} limit` : 'No time limit'} ·{' '}
                {d.quiz.attempts ? plural(d.quiz.attempts, 'attempt') : 'Unlimited attempts'} · pass mark {d.quiz.passMark}%
              </span>
              {d.quiz.status === 'draft' && (
                <InlineMessage kind="warn" title="This quiz is still a draft.">
                  Learners can’t take it until it’s published.
                </InlineMessage>
              )}
            </div>
          )}

          {e.source && (
            <p className={styles.sourceNote}>
              <WarningCircle size={15} aria-hidden="true" />
              {e.source.kind === 'live-class'
                ? 'Scheduled in Live classes — change the time, room or places there.'
                : 'Set on the assignment — change the deadline there.'}
            </p>
          )}
        </div>
      )}

      <ConfirmDialog
        open={deleting}
        onClose={() => setDeleting(false)}
        onConfirm={remove}
        tone="danger"
        title="Delete this event?"
        description={
          e
            ? `“${e.title}” is removed from the calendar${e.type !== 'reminder' || e.audience === 'learners' ? ' and learners won’t be notified about it' : ''}.`
            : undefined
        }
        confirmLabel="Delete event"
      />
    </AdaptivePanel>
  );
}

function audienceText(d: CalendarDetail) {
  const e = d.event;
  const learners = d.audienceSize !== undefined ? plural(d.audienceSize, 'learner') : 'Learners';
  switch (e.type) {
    case 'live':
      return d.live ? `${plural(d.live.registered, 'registered learner')} of ${d.courseTitle}` : `Registered learners of ${d.courseTitle}`;
    case 'assignment':
      return d.due ? `${plural(d.due.learners, 'learner')} in the current cohort` : 'Learners in the current cohort';
    case 'quiz':
      return `${learners} taking ${d.courseTitle}`;
    case 'milestone':
      return e.milestone === 'course-launch' ? 'Staff until the course is published' : `${learners} in the current cohort`;
    case 'reminder':
      return e.audience === 'learners' ? `Only you — and ${learners.toLowerCase()} of ${d.courseTitle} get the reminder` : 'Only you';
  }
}
