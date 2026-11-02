import { describe, expect, it } from 'vitest';
import { courses } from './fixtures/catalog';
import { ownMockReview, publicMockReviews, saveMockReview, setMockReviewStatus, staffMockReviews } from './reviews';

const sample = courses.find((c) => c.status === 'published')!;

describe('the demo build’s reviews', () => {
  it('shows a visitor first name, rating and comment only, and never a hidden one', () => {
    const before = publicMockReviews(sample.slug, { page: 1, pageSize: 10 });
    expect(before.total).toBeGreaterThan(0);
    expect(Object.keys(before.rows[0]).sort()).toEqual(['comment', 'firstName', 'rating']);
    expect(before.rows[0].firstName).not.toContain(' ');

    const id = staffMockReviews({ courseId: sample.id, status: 'published', page: 1, pageSize: 10 }).rows[0].id;
    setMockReviewStatus(id, 'hidden');
    expect(publicMockReviews(sample.slug, { page: 1, pageSize: 10 }).total).toBe(before.total - 1);
    setMockReviewStatus(id, 'published');
  });

  it('confines the staff list to one instructor’s courses when asked', () => {
    expect(staffMockReviews({ scopeInstructorId: 'nobody-teaches-this', page: 1, pageSize: 10 })).toMatchObject({ rows: [], total: 0, courses: [] });
    const own = sample.instructorIds[0];
    expect(staffMockReviews({ scopeInstructorId: own, page: 1, pageSize: 10 }).total).toBeGreaterThan(0);
  });

  it('refuses a course the demo learner does not hold', () => {
    expect(ownMockReview('no-such-course')).toEqual({ eligible: false, review: null });
    expect(() => saveMockReview('no-such-course', { rating: 5 })).toThrow(/enrolled/);
  });
});
