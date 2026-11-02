import { Link } from 'react-router-dom';
import { Clock, Users } from '@phosphor-icons/react';
import { courseDurationMin, type Course, type Instructor } from '@syniastrolms/domain';
import { LinkButton } from '@/components/ui/Button/Button';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { Rating } from '@/components/lms/shared/Rating';
import { saleDisplay } from '@/lib/coursePricing';
import { formatCount, formatDuration } from '@/lib/format';
import styles from './Site.module.css';

/** The instructors' names on one line. */
export const teacherNames = (course: Course, instructors: Instructor[]) =>
  course.instructorIds
    .map((id) => instructors.find((i) => i.id === id)?.name)
    .filter(Boolean)
    .join(', ');

/** A course on the public site: what it is, who teaches it, what it costs, and a link to its page. */
export function PublicCourseCard({
  course,
  instructors,
  headingLevel: Heading = 'h3',
  showActions = false,
}: {
  course: Course;
  instructors: Instructor[];
  /** The title's level in the page's outline: `h2` on a page where the cards sit straight under its `h1`. */
  headingLevel?: 'h2' | 'h3';
  /** Buy now and details beneath the price, where the card sells as well as lists. */
  showActions?: boolean;
}) {
  const sale = saleDisplay(course);
  const teachers = teacherNames(course, instructors);
  const minutes = courseDurationMin(course);
  return (
    <li className={styles.card}>
      <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.cardCover} />
      <div className={styles.cardBody}>
        <Heading className={styles.cardTitle}>
          <Link to={`/courses/${course.slug}`}>{course.title}</Link>
        </Heading>
        {teachers && <p className={styles.cardTeacher}>{teachers}</p>}
        {course.rating ? <Rating value={course.rating} count={course.ratingCount} /> : null}
        <p className={styles.cardFacts}>
          {course.enrolledCount > 0 && (
            <span>
              <Users size={14} aria-hidden="true" /> {course.enrolledCount === 1 ? '1 learner' : `${formatCount(course.enrolledCount)} learners`}
            </span>
          )}
          {minutes > 0 && (
            <span>
              <Clock size={14} aria-hidden="true" /> {formatDuration(minutes)}
            </span>
          )}
        </p>
        <p className={styles.cardPrice}>
          <strong>{sale.label}</strong>
          {sale.kind === 'paid' && sale.wasLabel ? <s>{sale.wasLabel}</s> : null}
        </p>
        {showActions && sale.kind !== 'unavailable' && (
          <div className={styles.cardActions}>
            <LinkButton to={`/learn/${course.id}`} variant="primary" size="sm">
              {sale.kind === 'paid' ? 'Buy now' : 'Enrol now'}
            </LinkButton>
            <LinkButton to={`/courses/${course.slug}`} size="sm">
              Details
            </LinkButton>
          </div>
        )}
      </div>
    </li>
  );
}
