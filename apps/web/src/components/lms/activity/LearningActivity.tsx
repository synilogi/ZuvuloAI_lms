import { useState, type ReactNode } from 'react';
import { BookOpenText, Certificate, CheckCircle, PaperPlaneTilt, SealCheck, Trophy, UserPlus, VideoCamera } from '@phosphor-icons/react';
import type { ActivityKind, LearningEvent, StudyDay } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';
import { cx } from '@/lib/cx';
import { formatDuration, formatRelative } from '@/lib/format';
import { IconChip } from '@/components/ui/Badge/Badge';
import styles from './LearningActivity.module.css';

export const ACTIVITY_KIND: Record<ActivityKind, { icon: ReactNode; tone: Tone; verb: string; label: string }> = {
  enrolled: { icon: <UserPlus size={16} />, tone: 'info', verb: 'Enrolled in', label: 'Enrollments' },
  'lesson-completed': { icon: <CheckCircle size={16} />, tone: 'accent', verb: 'Completed', label: 'Lessons' },
  'chapter-completed': { icon: <BookOpenText size={16} />, tone: 'accent', verb: 'Finished chapter', label: 'Chapters' },
  'live-attended': { icon: <VideoCamera size={16} />, tone: 'info', verb: 'Attended', label: 'Live classes' },
  'assignment-submitted': { icon: <PaperPlaneTilt size={16} />, tone: 'info', verb: 'Submitted', label: 'Assignments' },
  'assessment-passed': { icon: <SealCheck size={16} />, tone: 'accent', verb: 'Passed', label: 'Quizzes' },
  'certificate-issued': { icon: <Certificate size={16} />, tone: 'accent', verb: 'Earned certificate', label: 'Certificates' },
  'rank-achieved': { icon: <Trophy size={16} />, tone: 'warn', verb: 'Reached rank', label: 'Ranks' },
};

const weekday = new Intl.DateTimeFormat('en-IN', { weekday: 'short', timeZone: 'UTC' });
const longDay = new Intl.DateTimeFormat('en-IN', { weekday: 'long', day: 'numeric', month: 'short', timeZone: 'UTC' });

/** Seven days of study time. One series, one hue — today in the accent, earlier days a lighter step. */
export function StudyRhythm({ days, goalMin = 45 }: { days: StudyDay[]; goalMin?: number }) {
  const [active, setActive] = useState<number | null>(null);
  const total = days.reduce((n, d) => n + d.minutes, 0);
  const studied = days.filter((d) => d.minutes > 0).length;
  const max = Math.max(goalMin * 2, ...days.map((d) => d.minutes));
  const goalPct = (goalMin / max) * 100;

  return (
    <figure className={styles.rhythm}>
      <figcaption className={styles.rhythmHead}>
        <span className={styles.figure}>
          <span className={styles.figureValue}>{formatDuration(total)}</span>
          <span className={styles.figureLabel}>studied this week</span>
        </span>
        <span className={styles.figureAside}>
          {studied} of 7 days · {Math.round(total / 7)} min a day
        </span>
      </figcaption>

      <div className={styles.plot} onMouseLeave={() => setActive(null)}>
        <span className={styles.goalArea} aria-hidden="true">
          <span className={styles.goal} style={{ bottom: `${goalPct}%` }}>
            <span className={styles.goalLabel}>{goalMin} min goal</span>
          </span>
        </span>
        <ol className={styles.bars} aria-hidden="true">
          {days.map((d, i) => {
            const date = new Date(`${d.date}T00:00:00Z`);
            const today = i === days.length - 1;
            return (
              <li key={d.date} className={styles.barCol} onMouseEnter={() => setActive(i)}>
                <span
                  className={cx(styles.bar, today && styles.today, d.minutes === 0 && styles.zero)}
                  style={{ height: d.minutes === 0 ? undefined : `${(d.minutes / max) * 100}%` }}
                />
                {active === i && (
                  <span className={styles.tip}>
                    <strong>{d.minutes === 0 ? 'No study' : formatDuration(d.minutes)}</strong>
                    <span>{longDay.format(date)}</span>
                  </span>
                )}
                <span className={cx(styles.day, today && styles.dayToday)}>{today ? 'Today' : weekday.format(date)}</span>
              </li>
            );
          })}
        </ol>
      </div>

      <table className="sr-only">
        <caption>Study minutes per day, last seven days</caption>
        <tbody>
          {days.map((d) => (
            <tr key={d.date}>
              <th scope="row">{longDay.format(new Date(`${d.date}T00:00:00Z`))}</th>
              <td>{d.minutes} minutes</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}

export function ActivityFeed({ events, now, limit = 5 }: { events: LearningEvent[]; now: Date; limit?: number }) {
  return (
    <ol className={styles.feed} aria-label="Recent learning activity">
      {events.slice(0, limit).map((e) => {
        const kind = ACTIVITY_KIND[e.kind];
        return (
          <li key={e.id} className={styles.event}>
            <IconChip tone={kind.tone}>{kind.icon}</IconChip>
            <span className={styles.eventText}>
              <span className={styles.eventTitle}>
                <span className={styles.eventVerb}>{kind.verb}</span> {e.title}
              </span>
              {e.context && <span className={styles.eventContext}>{e.context}</span>}
            </span>
            <time className={styles.eventTime} dateTime={e.at}>
              {formatRelative(e.at, now)}
            </time>
          </li>
        );
      })}
    </ol>
  );
}

export function LearningActivity({ days, events, now }: { days: StudyDay[]; events: LearningEvent[]; now: Date }) {
  return (
    <div className={styles.root}>
      <div className={styles.layout}>
        <StudyRhythm days={days} />
        <ActivityFeed events={events} now={now} />
      </div>
    </div>
  );
}
