import { useState } from 'react';
import { useAsync } from '@/hooks/useAsync';
import { Button } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { Rating } from '@/components/lms/shared/Rating';
import { services } from '@/services';
import styles from './Marketing.module.css';

const PAGE_SIZE = 10;

/**
 * What learners said about a course, once any of them has. Each comment is a text node, line breaks kept: nothing a
 * learner writes is ever read as markup.
 */
export function CourseReviews({ slug }: { slug: string }) {
  const [page, setPage] = useState(1);
  const query = useAsync(`public-course-reviews:${slug}:${page}`, () => services.catalog.listCourseReviews(slug, { page, pageSize: PAGE_SIZE }));
  const data = query.data;

  if (query.status === 'error' && !data) {
    return (
      <section className={styles.courseSection} aria-labelledby="course-reviews">
        <h2 id="course-reviews">What learners say</h2>
        <StateMessage
          kind="error"
          compact
          title="The reviews didn’t load"
          actions={
            <Button size="sm" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      </section>
    );
  }
  if (!data) return <Skeleton height={120} radius="var(--r-lg)" />;
  // No reviews, no section: the page simply goes on to what it does have.
  if (data.total === 0) return null;

  return (
    <section className={styles.courseSection} aria-labelledby="course-reviews">
      <h2 id="course-reviews">What learners say</h2>
      <ul className={styles.courseReviewList}>
        {data.rows.map((review, i) => (
          <li key={`${data.page}-${i}`}>
            <span className={styles.courseReviewHead}>
              <strong>{review.firstName}</strong>
              <Rating value={review.rating} />
            </span>
            {review.comment && <p className={styles.courseReviewComment}>{review.comment}</p>}
          </li>
        ))}
      </ul>
      {data.total > PAGE_SIZE && <Pagination page={page} pageCount={Math.ceil(data.total / PAGE_SIZE)} onChange={setPage} />}
    </section>
  );
}
