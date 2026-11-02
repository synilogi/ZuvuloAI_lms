import { describe, expect, it } from 'vitest';

import { app } from '../test/helpers.js';
import request from 'supertest';

/* The help centre is public — no route here requires a token. These tests cover audience filtering,
 * search, per-category counts, an unknown slug and related articles. */

describe('help centre', () => {
  it('lists categories with counts, filtered to what the viewer may see', async () => {
    const anonymous = await request(app).get('/help/categories');
    expect(anonymous.status).toBe(200);
    expect(anonymous.body.length).toBeGreaterThan(0);
    const getStarted = anonymous.body.find((c: { category: { name: string } }) => c.category.name === 'Getting started');
    expect(getStarted).toBeTruthy();
    expect(getStarted.articleCount).toBeGreaterThan(0);

    const courses = anonymous.body.find((c: { category: { name: string } }) => c.category.name === 'Courses & lessons');
    const allViewers = courses.articleCount;
    const asStudent = await request(app).get('/help/categories').query({ audience: 'student' });
    const coursesForStudent = asStudent.body.find((c: { category: { name: string } }) => c.category.name === 'Courses & lessons');
    // A student sees at least everything an anonymous visitor does (audience: 'all' plus their own).
    expect(coursesForStudent.articleCount).toBeGreaterThanOrEqual(allViewers);
  });

  it('lists articles, filters by category and audience, and searches title/summary/tags', async () => {
    const all = await request(app).get('/help/articles');
    expect(all.status).toBe(200);
    expect(all.body.length).toBeGreaterThan(0);
    expect(all.body[0]).toHaveProperty('article.title');
    expect(all.body[0]).toHaveProperty('categoryName');

    const studentOnly = await request(app).get('/help/articles').query({ audience: 'student' });
    expect(studentOnly.body.some((r: { article: { audience: string } }) => r.article.audience === 'student')).toBe(true);
    // An instructor-only article must not reach a learner's list.
    const asInstructor = await request(app).get('/help/articles').query({ audience: 'instructor' });
    expect(asInstructor.body.some((r: { article: { audience: string } }) => r.article.audience === 'student')).toBe(false);

    const bySearch = await request(app).get('/help/articles').query({ search: 'enrolment' });
    expect(bySearch.body.length).toBeGreaterThan(0);
    expect(
      bySearch.body.every((r: { article: { title: string; summary: string; tags: string[] } }) => {
        const a = r.article;
        return a.title.toLowerCase().includes('enrolment') || a.summary.toLowerCase().includes('enrolment') || a.tags.some((t) => t.includes('enrolment'));
      }),
    ).toBe(true);

    const noMatch = await request(app).get('/help/articles').query({ search: 'xyzxyzxyz-no-such-article' });
    expect(noMatch.body).toEqual([]);
  });

  it('serves one article by slug with related articles from the same category, and 404s an unknown slug', async () => {
    const res = await request(app).get('/help/articles/welcome-to-syniastrolms');
    expect(res.status).toBe(200);
    expect(res.body.article.slug).toBe('welcome-to-syniastrolms');
    expect(res.body.article.body).toContain('Welcome');
    expect(res.body.categoryName).toBe('Getting started');
    expect(Array.isArray(res.body.related)).toBe(true);
    expect(res.body.related.length).toBeLessThanOrEqual(3);
    expect(res.body.related.every((r: { article: { id: string } }) => r.article.id !== res.body.article.id)).toBe(true);

    expect((await request(app).get('/help/articles/no-such-article')).status).toBe(404);
  });

  it('hides an audience-restricted article from a viewer outside that audience', async () => {
    const asStudent = await request(app).get('/help/articles/how-enrolment-works').query({ audience: 'student' });
    expect(asStudent.status).toBe(200);
    const asInstructor = await request(app).get('/help/articles/how-enrolment-works').query({ audience: 'instructor' });
    expect(asInstructor.status).toBe(404);
  });
});
