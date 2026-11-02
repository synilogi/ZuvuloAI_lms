import { useEffect, useState, type FormEvent } from 'react';
import { Star } from '@phosphor-icons/react';
import { REVIEW_COMMENT_MAX } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { commentCountText, RATING_CHOICES, ratingWord, reviewDraftIssue } from '@/lib/reviews';
import { SectionHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { Field, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { cx } from '@/lib/cx';
import styles from './Learn.module.css';

/** The learner's review of a course they hold: write it, or change it. Renders nothing once their access has ended. */
export function CourseReviewPanel({ courseId }: { courseId: string }) {
  const toast = useToast();
  const query = useAsync(`course-review:${courseId}`, () => services.learning.getCourseReview(courseId));
  const saved = query.data?.review ?? null;
  const [rating, setRating] = useState<number>();
  const [comment, setComment] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();

  useEffect(() => {
    setRating(saved?.rating);
    setComment(saved?.comment ?? '');
  }, [saved]);

  if (query.status === 'error' && !query.data) {
    return (
      <section className={styles.panel} aria-labelledby="course-review">
        <SectionHeader id="course-review" title="Your review" />
        <StateMessage
          kind="error"
          compact
          title="Your review didn’t load"
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
  if (!query.data) return <Skeleton height={220} radius="var(--r-lg)" />;
  if (!query.data.eligible) return null;

  const issue = reviewDraftIssue(rating, comment);
  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (issue || !rating) return;
    setSaving(true);
    setError(undefined);
    try {
      await services.learning.saveCourseReview(courseId, { rating, comment: comment.trim() });
      toast({ kind: 'success', title: saved ? 'Your review is updated' : 'Thanks for your review' });
      await query.run();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <section className={styles.panel} aria-labelledby="course-review">
      <SectionHeader
        id="course-review"
        title="Your review"
        description={saved ? undefined : 'Your first name, rating and comment appear on the course page.'}
      />
      {saved?.status === 'hidden' && (
        <InlineMessage kind="warn" title="This review is hidden.">
          Our team has taken it off the course page. Changes you make are saved, and it stays hidden unless they show it again.
        </InlineMessage>
      )}
      <form className={styles.reviewForm} onSubmit={submit} noValidate>
        {error && (
          <InlineMessage kind="error" title="Couldn’t save your review.">
            {error}
          </InlineMessage>
        )}
        <fieldset className={styles.reviewStars}>
          <legend>Rating{rating ? ` · ${ratingWord(rating)}` : ''}</legend>
          {RATING_CHOICES.map((n) => (
            <label key={n} className={cx(styles.reviewStar, rating !== undefined && n <= rating && styles.reviewStarOn)}>
              <input
                type="radio"
                name="course-review-rating"
                value={n}
                checked={rating === n}
                onChange={() => setRating(n)}
                aria-label={`${n} of 5, ${ratingWord(n)}`}
              />
              <Star size={24} weight={rating !== undefined && n <= rating ? 'fill' : 'regular'} aria-hidden="true" />
            </label>
          ))}
        </fieldset>
        <Field label="Comment" optional hint={commentCountText(comment)}>
          <Textarea id="course-review-comment" rows={4} maxLength={REVIEW_COMMENT_MAX} value={comment} onChange={(e) => setComment(e.target.value)} />
        </Field>
        <div className={styles.reviewActions}>
          <Button type="submit" variant="primary" loading={saving} disabled={Boolean(issue)}>
            {saved ? 'Update review' : 'Post review'}
          </Button>
        </div>
      </form>
    </section>
  );
}
