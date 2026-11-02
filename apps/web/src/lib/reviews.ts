import { REVIEW_COMMENT_MAX, REVIEW_RATING_MAX, REVIEW_RATING_MIN, type CourseReviewStatus } from '@syniastrolms/domain';

export const RATING_CHOICES = [1, 2, 3, 4, 5] as const;

const RATING_WORD: Record<number, string> = { 1: 'Poor', 2: 'Fair', 3: 'Good', 4: 'Very good', 5: 'Excellent' };

/** What a star means, for the label a screen reader hears and the word beside the stars. */
export const ratingWord = (rating: number): string => RATING_WORD[rating] ?? '';

/** Why a draft review can't be saved yet, in words; undefined when it can. The API checks the same limits. */
export function reviewDraftIssue(rating: number | undefined, comment: string): string | undefined {
  if (!rating || rating < REVIEW_RATING_MIN || rating > REVIEW_RATING_MAX) return 'Choose a rating from 1 to 5 stars.';
  if (comment.trim().length > REVIEW_COMMENT_MAX) return `Keep your comment to ${REVIEW_COMMENT_MAX.toLocaleString('en-IN')} characters.`;
  return undefined;
}

/** The hint under the comment box. */
export const commentCountText = (comment: string) =>
  `${comment.trim().length.toLocaleString('en-IN')} of ${REVIEW_COMMENT_MAX.toLocaleString('en-IN')} characters`;

export const REVIEW_STATUS_LABEL: Record<CourseReviewStatus, string> = { published: 'Published', hidden: 'Hidden' };

/** Who may hide and show a review: an admin holding the key, or the platform's owner. Instructors read only. */
export const canModerateReviews = (role: string, can: (key: 'catalog.publish') => boolean) =>
  (role === 'admin' || role === 'superadmin') && can('catalog.publish');
