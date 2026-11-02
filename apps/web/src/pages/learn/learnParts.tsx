import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { BookmarkSimple, Certificate, Play } from '@phosphor-icons/react';
import { useNow } from '@/hooks/useNow';
import { cx } from '@/lib/cx';
import { formatDate, formatDuration, formatRelative, plural } from '@/lib/format';
import { saleDisplay } from '@/lib/coursePricing';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { Meter } from '@/components/lms/progress/Meters';
import { services, type LearnerCourse, type LearningHome, type NextLesson } from '@/services';
import styles from './Learn.module.css';

export const lessonTo = (courseId: string, lessonId: string) => `/learn/${courseId}/lessons/${lessonId}`;

export function nextLabel(next: NextLesson) {
  if (next.state === 'in-progress' && next.type === 'video' && next.positionSec !== undefined) {
    return `${Math.max(1, Math.ceil(next.durationMin - next.positionSec / 60))} min left`;
  }
  return `${lessonTypeMeta[next.type].label} · ${formatDuration(next.durationMin)}`;
}

/** A course the learner is enrolled in: progress, the next lesson and the one action that matters. */
export function CourseCard({ item }: { item: LearnerCourse }) {
  const now = useNow();
  const { course, progress, next, enrollment } = item;
  const done = enrollment.status === 'completed';
  return (
    <li className={styles.courseCard}>
      <Link to={`/learn/${course.id}`} className={styles.courseCoverLink} tabIndex={-1} aria-hidden="true">
        <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.courseCover} />
      </Link>
      <div className={styles.courseBody}>
        <span className={styles.eyebrow}>
          {item.levelTitle} · {item.instructorNames[0]}
        </span>
        <Link to={`/learn/${course.id}`} className={styles.courseTitle}>
          {course.title}
        </Link>
        <Meter value={progress.percent} size="sm" label={`${course.title}: ${progress.percent}% complete`} />
        <span className={styles.courseFacts}>
          <span className="tabular">{progress.percent}%</span>
          <span>
            {progress.completed} of {plural(progress.total, 'lesson')}
          </span>
          {done && enrollment.completedAt ? (
            <span>Completed {formatDate(enrollment.completedAt)}</span>
          ) : (
            item.lastActiveAt && <span>Active {formatRelative(item.lastActiveAt, now)}</span>
          )}
        </span>
        {!done && next && (
          <span className={styles.nextLine}>
            <span className={styles.nextIcon}>{lessonTypeMeta[next.type].icon}</span>
            <span className={styles.truncate}>
              {next.state === 'in-progress' ? 'Resume' : 'Next'}: {next.lessonNumber} {next.title}
            </span>
          </span>
        )}
        <div className={styles.courseActions}>
          {done ? (
            <>
              <LinkButton size="sm" to={`/learn/${course.id}`}>
                Review course
              </LinkButton>
              {course.certificateTitle && (
                <LinkButton size="sm" variant="ghost" to="/certificates" iconStart={<Certificate size={15} />}>
                  Certificate
                </LinkButton>
              )}
            </>
          ) : next ? (
            <LinkButton size="sm" variant="primary" to={lessonTo(course.id, next.id)} iconStart={<Play size={14} weight="fill" />}>
              {next.state === 'in-progress' ? 'Resume' : progress.completed === 0 ? 'Start course' : 'Continue'}
            </LinkButton>
          ) : (
            <LinkButton size="sm" to={`/learn/${course.id}`}>
              Open course
            </LinkButton>
          )}
        </div>
      </div>
    </li>
  );
}

/** A course saved for later, not yet enrolled. */
export function SavedCard({ item, onChange }: { item: LearningHome['saved'][number]; onChange: () => void }) {
  const navigate = useNavigate();
  const toast = useToast();
  const [busy, setBusy] = useState<null | 'enroll' | 'remove'>(null);
  const { course } = item;
  const sale = saleDisplay(course);

  const enroll = async () => {
    setBusy('enroll');
    try {
      const enrolled = await services.learning.enroll(course.id);
      toast({ kind: 'success', title: `You’re enrolled in ${course.title}`, text: enrolled.next ? `First up: ${enrolled.next.title}` : undefined });
      navigate(enrolled.next ? lessonTo(course.id, enrolled.next.id) : `/learn/${course.id}`);
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t enroll', text: (e as Error).message });
      setBusy(null);
    }
  };
  const remove = async () => {
    setBusy('remove');
    await services.learning.toggleSaved(course.id).catch(() => undefined);
    toast({ kind: 'info', title: 'Removed from saved', text: course.title });
    onChange();
  };

  return (
    <li className={cx(styles.courseCard, styles.savedCard)}>
      <Link to={`/learn/${course.id}`} className={styles.courseCoverLink} tabIndex={-1} aria-hidden="true">
        <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.courseCover} />
      </Link>
      <div className={styles.courseBody}>
        <span className={styles.eyebrow}>
          {item.levelTitle} · {item.instructorNames[0]}
        </span>
        <Link to={`/learn/${course.id}`} className={styles.courseTitle}>
          {course.title}
        </Link>
        <span className={styles.muted}>{course.subtitle}</span>
        <span className={styles.courseFacts}>
          <span>{plural(course.chapters.length, 'chapter')}</span>
          {course.estimatedWeeks && <span>{course.estimatedWeeks} weeks at a steady pace</span>}
          {course.rating && <span>★ {course.rating.toFixed(1)}</span>}
        </span>
        <div className={styles.courseActions}>
          {sale.kind === 'free' ? (
            <Button size="sm" variant="primary" loading={busy === 'enroll'} disabled={Boolean(busy)} onClick={enroll}>
              Enroll for free
            </Button>
          ) : sale.kind === 'paid' ? (
            // Bought on the course page, with its order summary — never from a card.
            <LinkButton size="sm" variant="primary" to={`/learn/${course.id}`}>
              Buy · {sale.label}
            </LinkButton>
          ) : (
            <Button size="sm" disabled>
              {sale.label}
            </Button>
          )}
          <LinkButton size="sm" variant="ghost" to={`/learn/${course.id}`}>
            View course
          </LinkButton>
          <IconButton
            size="sm"
            label={`Remove ${course.title} from saved`}
            icon={<BookmarkSimple size={16} weight="fill" />}
            disabled={Boolean(busy)}
            onClick={remove}
          />
        </div>
      </div>
    </li>
  );
}
