import { describe, expect, it } from 'vitest';
import { canModerateReviews, commentCountText, ratingWord, reviewDraftIssue } from './reviews';

describe('reviewDraftIssue', () => {
  it('needs a rating from 1 to 5', () => {
    expect(reviewDraftIssue(undefined, 'Good')).toMatch(/rating/);
    expect(reviewDraftIssue(0, '')).toMatch(/rating/);
    expect(reviewDraftIssue(6, '')).toMatch(/rating/);
    expect(reviewDraftIssue(1, '')).toBeUndefined();
    expect(reviewDraftIssue(5, '')).toBeUndefined();
  });

  it('limits the comment to 2000 characters once trimmed, as the API does', () => {
    expect(reviewDraftIssue(5, 'x'.repeat(2000))).toBeUndefined();
    expect(reviewDraftIssue(5, `  ${'x'.repeat(2000)}  `)).toBeUndefined();
    expect(reviewDraftIssue(5, 'x'.repeat(2001))).toMatch(/2,000/);
  });
});

describe('the words around a review', () => {
  it('names each rating', () => {
    expect(ratingWord(5)).toBe('Excellent');
    expect(ratingWord(1)).toBe('Poor');
    expect(ratingWord(9)).toBe('');
  });

  it('counts the comment as it will be saved', () => {
    expect(commentCountText('  hello ')).toBe('5 of 2,000 characters');
  });
});

describe('canModerateReviews', () => {
  const holds = () => true;
  const lacks = () => false;

  it('is for an admin with the key and the owner', () => {
    expect(canModerateReviews('admin', holds)).toBe(true);
    expect(canModerateReviews('admin', lacks)).toBe(false);
    expect(canModerateReviews('superadmin', holds)).toBe(true);
  });

  it('is never for an instructor or a learner, whom `can` always answers yes for', () => {
    expect(canModerateReviews('instructor', holds)).toBe(false);
    expect(canModerateReviews('student', holds)).toBe(false);
  });
});
