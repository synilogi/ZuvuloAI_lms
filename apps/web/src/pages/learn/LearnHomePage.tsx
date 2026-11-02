import { Link } from 'react-router-dom';
import { ArrowRight, BookOpenText, CheckCircle, ClipboardText, Clock, Exam, Play, VideoCamera } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatDuration, formatLongDay, formatRelative, formatTime, greeting, plural } from '@/lib/format';
import { StatCards, type StatItem } from '@/components/data/StatCards';
import { SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { StudyRhythm } from '@/components/lms/activity/LearningActivity';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { Meter, VideoProgress } from '@/components/lms/progress/Meters';
import { DateBlock, WorkList, WorkRow } from '@/components/lms/shared/WorkRow';
import { StatusNodeFor } from '@/components/lms/status/Status';
import { services } from '@/services';
import { CourseCard, lessonTo, nextLabel, SavedCard } from './learnParts';
import styles from './Learn.module.css';

const KIND_ICON = { live: <VideoCamera size={18} />, assignment: <ClipboardText size={18} />, quiz: <Exam size={18} /> };
const FLAG_LABEL = { 'live-now': 'Live now', 'starting-soon': 'Starting soon', overdue: 'Overdue', 'due-soon': 'Due soon' } as const;

export default function LearnHomePage() {
  const now = useNow();
  const home = useAsync('learning-home', () => services.learning.getHome());

  if (home.status === 'error' && !home.data) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title="Your learning didn’t load"
          actions={
            <Button variant="primary" onClick={() => home.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {home.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!home.data) {
    return (
      <div className={styles.page} aria-busy="true" aria-label="Loading your learning">
        <Skeleton width={180} height={12} />
        <Skeleton width="45%" height={34} radius="var(--r-xs)" />
        <Skeleton height={180} radius="var(--r-lg)" />
        <div className={styles.homeGrid}>
          <Skeleton height={320} radius="var(--r-lg)" />
          <Skeleton height={320} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }

  const h = home.data;
  const active = h.courses.filter((c) => c.enrollment.status === 'active');
  const resume = active.find((c) => c.next);
  const next = resume?.next;
  const refresh = () => home.run().catch(() => undefined);

  // At a glance, from what the page already has: nothing here is a new figure, only a sum of what is shown below.
  const finished = h.courses.filter((c) => c.progress.state === 'completed' || c.progress.percent >= 100).length;
  const inProgress = active.length - active.filter((c) => c.progress.state === 'completed' || c.progress.percent >= 100).length;
  const lessonsDone = h.courses.reduce((n, c) => n + c.progress.completed, 0);
  const lessonsTotal = h.courses.reduce((n, c) => n + c.progress.total, 0);
  const weekMinutes = h.week.reduce((n, d) => n + d.minutes, 0);
  const due = h.upcoming.filter((u) => u.kind !== 'live');
  const overdue = due.filter((u) => u.flag === 'overdue').length;
  const glance: StatItem[] = [
    {
      id: 'courses',
      label: 'Courses in progress',
      help: 'Courses you’re studying right now.',
      icon: <BookOpenText size={18} weight="duotone" />,
      hue: 'violet',
      value: String(inProgress),
      note: finished ? `${plural(finished, 'course')} finished` : 'None finished yet',
      to: '/my-learning/in-progress',
      linkLabel: 'Open my courses',
    },
    {
      id: 'lessons',
      label: 'Lessons finished',
      help: 'Across all your courses.',
      icon: <CheckCircle size={18} weight="duotone" />,
      hue: 'green',
      value: String(lessonsDone),
      note: `of ${plural(lessonsTotal, 'lesson')} in total`,
    },
    {
      id: 'week',
      label: 'Studied this week',
      help: 'Time spent on lessons in the last 7 days.',
      icon: <Clock size={18} weight="duotone" />,
      hue: 'blue',
      value: weekMinutes ? formatDuration(weekMinutes) : '0 min',
      note: weekMinutes ? 'Keep it going' : 'A short lesson today is a good start',
    },
    {
      id: 'due',
      label: 'Due soon',
      help: 'Assignments and quizzes in the next two weeks.',
      icon: <ClipboardText size={18} weight="duotone" />,
      hue: 'orange',
      value: String(due.length),
      note: overdue ? `${overdue} overdue` : due.length ? 'Nothing overdue' : 'You’re all caught up',
      to: '/assignments',
      linkLabel: 'Open assignments',
    },
  ];

  if (h.courses.length === 0) {
    return (
      <div className={styles.page}>
        <header className={styles.greeting}>
          <span className={styles.eyebrow}>{formatLongDay(now)}</span>
          <h1 className={styles.homeTitle}>
            {greeting(now)}, {h.firstName}
          </h1>
        </header>
        <StateMessage icon={<BookOpenText size={28} />} title="Your learning starts here">
          When you join a course, it shows up here with your next lesson ready to open, your live classes and anything due.
        </StateMessage>
        <div>
          <LinkButton variant="primary" to="/explore" iconEnd={<ArrowRight size={14} />}>
            Browse courses
          </LinkButton>
        </div>
        {h.saved.length > 0 && (
          <section aria-labelledby="saved-title">
            <SectionHeader id="saved-title" title="Saved for later" />
            <ul className={styles.courseGrid}>
              {h.saved.map((s) => (
                <SavedCard key={s.course.id} item={s} onChange={refresh} />
              ))}
            </ul>
          </section>
        )}
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <header className={styles.greeting}>
        <span className={styles.eyebrow}>{formatLongDay(now)}</span>
        <h1 className={styles.homeTitle}>
          {greeting(now)}, {h.firstName}
        </h1>
        {resume && (
          <p className={styles.lede}>
            You’re {resume.progress.percent}% through {resume.course.title}.{' '}
            {next && next.state === 'in-progress' ? `Pick up “${next.title}” where you paused.` : next ? `Next up: “${next.title}”.` : ''}
          </p>
        )}
      </header>

      {resume && next && (
        <section className={styles.resume} aria-labelledby="resume-title">
          <CourseCover motif={resume.course.coverMotif} imageUrl={resume.course.coverImageUrl} className={styles.resumeCover} />
          <div className={styles.resumeBody}>
            <span className={styles.eyebrow}>
              {next.state === 'in-progress' ? 'Continue where you left off' : 'Up next'} · Chapter {next.chapterIndex + 1}
            </span>
            <h2 id="resume-title" className={styles.resumeTitle}>
              {next.title}
            </h2>
            <span className={styles.resumeMeta}>
              {lessonTypeMeta[next.type].icon} {resume.course.title} · Lesson {next.lessonNumber} · {nextLabel(next)}
            </span>
            {next.type === 'video' && next.positionSec !== undefined ? (
              <VideoProgress positionSec={next.positionSec} durationSec={next.durationMin * 60} />
            ) : (
              <Meter
                value={resume.progress.percent}
                size="sm"
                label={`${resume.course.title}: ${resume.progress.percent}%`}
                showLabel
                valueText={`${resume.progress.percent}% of the course`}
              />
            )}
          </div>
          <div className={styles.resumeAction}>
            <LinkButton size="lg" variant="primary" to={lessonTo(resume.course.id, next.id)} iconStart={<Play size={16} weight="fill" />}>
              {next.state === 'in-progress' ? 'Resume lesson' : 'Start lesson'}
            </LinkButton>
          </div>
        </section>
      )}

      <StatCards items={glance} label="Your progress at a glance" />

      <div className={styles.homeGrid}>
        <div className={styles.column}>
          <section aria-labelledby="courses-title">
            <SectionHeader
              id="courses-title"
              title="Your courses"
              count={h.courses.length}
              actions={
                <LinkButton size="sm" variant="ghost" to="/my-learning" iconEnd={<ArrowRight size={14} />}>
                  All my courses
                </LinkButton>
              }
            />
            <ul className={styles.courseList}>
              {h.courses.slice(0, 3).map((c) => (
                <CourseCard key={c.course.id} item={c} />
              ))}
            </ul>
          </section>

          <section className={styles.panel} aria-labelledby="recent-title">
            <SectionHeader id="recent-title" title="Recently opened" description="Jump back into a lesson." />
            {h.recent.length === 0 ? (
              <p className={styles.muted}>Lessons you open show up here.</p>
            ) : (
              <ol className={styles.recent}>
                {h.recent.map((r) => (
                  <li key={`${r.courseId}-${r.lessonId}`}>
                    <Link to={lessonTo(r.courseId, r.lessonId)} className={styles.recentRow}>
                      <StatusNodeFor status={r.state} size={20} />
                      <span className={styles.recentText}>
                        <span className={styles.recentTitle}>{r.lessonTitle}</span>
                        <span className={styles.muted}>
                          {lessonTypeMeta[r.type].label} · {r.courseTitle}
                        </span>
                      </span>
                      <time className={styles.recentTime} dateTime={r.at}>
                        {r.state === 'in-progress' ? 'In progress' : formatRelative(r.at, now)}
                      </time>
                    </Link>
                  </li>
                ))}
              </ol>
            )}
          </section>
        </div>

        <div className={styles.column}>
          <section className={styles.panel} aria-labelledby="upcoming-title">
            <SectionHeader id="upcoming-title" title="Coming up" description="Live classes, things to hand in and quizzes in the next two weeks." />
            {h.upcoming.length === 0 ? (
              <p className={styles.muted}>Nothing scheduled. Enjoy the quiet — or get ahead on your next lesson.</p>
            ) : (
              <WorkList label="Coming up">
                {h.upcoming.map((u) => (
                  <WorkRow
                    key={`${u.kind}-${u.id}`}
                    lead={u.kind === 'quiz' ? <span className={styles.kindIcon}>{KIND_ICON.quiz}</span> : <DateBlock iso={u.at} highlight={Boolean(u.flag)} />}
                    eyebrow={
                      <>
                        {KIND_ICON[u.kind]} {u.kind === 'live' ? `Live · ${formatTime(u.at)}` : u.kind === 'assignment' ? 'Assignment due' : 'Quiz'}
                      </>
                    }
                    title={<Link to={u.to}>{u.title}</Link>}
                    meta={u.context}
                    emphasis={u.flag === 'live-now' ? 'live' : u.flag ? 'attention' : undefined}
                    status={
                      u.flag ? (
                        <Badge size="sm" tone={u.flag === 'live-now' || u.flag === 'overdue' ? 'danger' : 'warn'} dot={u.flag === 'live-now'}>
                          {FLAG_LABEL[u.flag]}
                        </Badge>
                      ) : undefined
                    }
                  />
                ))}
              </WorkList>
            )}
          </section>

          <section className={styles.panel} aria-label="Study this week">
            <StudyRhythm days={h.week} />
          </section>

          {h.saved.length > 0 && (
            <section aria-labelledby="saved-home-title">
              <SectionHeader id="saved-home-title" title="Saved for later" count={h.saved.length} />
              <ul className={styles.courseList}>
                {h.saved.slice(0, 2).map((s) => (
                  <SavedCard key={s.course.id} item={s} onChange={refresh} />
                ))}
              </ul>
            </section>
          )}
        </div>
      </div>
    </div>
  );
}
