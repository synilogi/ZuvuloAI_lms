import { describe, expect, it } from 'vitest';
import type { Course } from '@syniastrolms/domain';
import { payloadOf, priceIssue, pricingPayload, toForm, validate, type FormState } from './courseForm';

/* The course editor's rules: a draft needs a title; publishing needs a title, a description and an instructor. */

const blank = toForm(null, { levelId: 'beginner' });
const fields = (form: FormState, intent: 'draft' | 'publish') => validate(form, intent).map((i) => i.field);

describe('course form', () => {
  it('starts a new course with defaults for every optional setting', () => {
    expect(blank).toMatchObject({
      subtitle: '',
      categoryId: '',
      levelId: 'beginner',
      format: 'self-paced',
      visibility: 'public',
      outcomes: [],
      tags: [],
      liveSessions: 0,
      awardsCertificate: false,
    });
    expect(blank.estimatedWeeks).toBeUndefined();
    // An instructor starting a course is on it from the start.
    expect(toForm(null, { levelId: 'beginner', instructorId: 'i1' }).instructorIds).toEqual(['i1']);
  });

  it('saves a draft from a title alone', () => {
    expect(fields({ ...blank, title: 'Fractions made simple' }, 'draft')).toEqual([]);
  });

  it('asks for a usable title, with the reason, whatever the intent', () => {
    expect(validate(blank, 'draft')).toEqual([{ field: 'course-title', message: 'Give the course a title.' }]);
    expect(validate({ ...blank, title: 'Hi' }, 'draft')[0].message).toBe('The title needs at least 3 characters.');
    expect(validate({ ...blank, title: 'x'.repeat(91) }, 'draft')[0].message).toBe('Keep the title under 90 characters.');
  });

  it('asks for a description and an instructor only when publishing, each against its own field', () => {
    const titled = { ...blank, title: 'Fractions made simple' };
    expect(validate(titled, 'publish')).toEqual([
      { field: 'course-description', message: 'Add a short description — learners read it before they enrol.' },
      { field: 'course-instructors', message: 'Assign at least one instructor.' },
    ]);
    expect(fields({ ...titled, description: '   ' }, 'publish')).toContain('course-description');
  });

  it('publishes with a title, a description and an instructor — nothing optional is required', () => {
    const minimal = { ...blank, title: 'Fractions made simple', description: 'For Class 6.', instructorIds: ['i1'] };
    expect(validate(minimal, 'publish')).toEqual([]);
  });

  it('checks optional fields only when they are filled in', () => {
    const minimal = { ...blank, title: 'Fractions made simple', description: 'For Class 6.', instructorIds: ['i1'] };
    expect(fields({ ...minimal, estimatedWeeks: 0 }, 'publish')).toEqual(['course-weeks']);
    expect(fields({ ...minimal, awardsCertificate: true }, 'publish')).toEqual(['course-certificate']);
    expect(fields({ ...minimal, subtitle: 'x'.repeat(161) }, 'draft')).toEqual(['course-subtitle']);
  });

  it('leaves level and category out when none is chosen, so the API places the course', () => {
    const payload = payloadOf({ ...blank, title: '  Fractions  ', levelId: '', outcomes: [' Simplify ', ''] });
    expect(payload).not.toHaveProperty('categoryId');
    expect(payload).not.toHaveProperty('levelId');
    expect(payload).not.toHaveProperty('awardsCertificate');
    expect(payload).toMatchObject({ title: 'Fractions', outcomes: ['Simplify'], certificateTitle: undefined });
    expect(payloadOf({ ...blank, title: 'Fractions', categoryId: 'maths' })).toMatchObject({ categoryId: 'maths', levelId: 'beginner' });
  });

  it('loads an existing course for editing as it is saved', () => {
    const course = {
      title: 'Algebra',
      subtitle: '',
      description: 'Linear equations.',
      levelId: 'l1',
      categoryId: 'c1',
      instructorIds: ['i1'],
      format: 'cohort',
      language: 'Hindi',
      coverMotif: 'orbits',
      outcomes: [],
      tags: [],
      visibility: 'unlisted',
      liveSessions: 2,
      certificateTitle: 'Algebra certificate',
    } as unknown as Course;
    expect(toForm(course, { levelId: 'beginner' })).toMatchObject({ categoryId: 'c1', levelId: 'l1', awardsCertificate: true, coverImageId: null });
  });

  it('starts a new course as free, and loads an existing course’s pricing as it is', () => {
    expect(blank).toMatchObject({ pricing: 'free', priceText: '' });
    const paid = { ...({} as Course), pricing: 'paid', price: { amount: 1499, currency: 'INR' } } as Course;
    expect(toForm({ ...paid, title: 'x', subtitle: '', description: '', instructorIds: [], outcomes: [], tags: [] }, { levelId: 'l' })).toMatchObject({
      pricing: 'paid',
      priceText: '1499',
    });
    // An old record with the academy's default price on it was never chosen: it stays undecided.
    const legacy = {
      title: 'x',
      subtitle: '',
      description: '',
      instructorIds: [],
      outcomes: [],
      tags: [],
      price: { amount: 2999, currency: 'INR' },
    } as unknown as Course;
    expect(toForm(legacy, { levelId: 'l' }).pricing).toBe('unset');
  });

  it('asks for a whole-rupee price from ₹1 to ₹5,00,000, next to the price field', () => {
    expect(priceIssue('')).toBe('Enter the price in whole rupees.');
    expect(priceIssue('14.50')).toBe('Enter whole rupees only — no paise.');
    expect(priceIssue('abc')).toBe('Enter the price as a number of rupees, e.g. 1499.');
    expect(priceIssue('-5')).toBe('Enter the price as a number of rupees, e.g. 1499.');
    expect(priceIssue('0')).toBe('The price must be between ₹1 and ₹5,00,000.');
    expect(priceIssue('500001')).toBe('The price must be between ₹1 and ₹5,00,000.');
    expect(priceIssue('1')).toBeNull();
    expect(priceIssue('5,00,000')).toBeNull();
    const titled = { ...blank, title: 'Fractions made simple', pricing: 'paid' as const, priceText: '0' };
    expect(validate(titled, 'draft')).toEqual([{ field: 'course-price', message: 'The price must be between ₹1 and ₹5,00,000.' }]);
    expect(validate({ ...titled, priceText: '1499' }, 'draft')).toEqual([]);
    // A free course has no price to check; an instructor never sets one.
    expect(validate({ ...titled, pricing: 'free' }, 'draft')).toEqual([]);
    expect(validate(titled, 'draft', { canPrice: false })).toEqual([]);
  });

  it('sends pricing for a new course, and on an edit only when the admin changed it', () => {
    expect(payloadOf({ ...blank, title: 'Fractions' })).toMatchObject({ pricing: 'free', priceAmount: null });
    expect(payloadOf({ ...blank, title: 'Fractions', pricing: 'paid', priceText: ' 1,499 ' })).toMatchObject({ pricing: 'paid', priceAmount: 1499 });
    expect(payloadOf({ ...blank, title: 'Fractions' })).not.toHaveProperty('priceText');

    const saved = { ...blank, title: 'Fractions', pricing: 'paid' as const, priceText: '1499' };
    // Untouched: the stored price is left exactly as it is.
    expect(payloadOf({ ...saved, subtitle: 'New' }, { baseline: saved })).not.toHaveProperty('pricing');
    expect(payloadOf({ ...saved, priceText: '1,499' }, { baseline: saved })).not.toHaveProperty('priceAmount');
    expect(pricingPayload({ pricing: 'paid', priceText: '999' }, saved, true)).toEqual({ pricing: 'paid', priceAmount: 999 });
    expect(pricingPayload({ pricing: 'free', priceText: '1499' }, saved, true)).toEqual({ pricing: 'free', priceAmount: null });
    // Undecided until the admin chooses; an instructor never sends pricing at all.
    expect(pricingPayload({ pricing: 'unset', priceText: '' }, { pricing: 'unset', priceText: '' }, true)).toEqual({});
    expect(payloadOf({ ...blank, title: 'Fractions' }, { canPrice: false })).not.toHaveProperty('pricing');
    expect(pricingPayload({ pricing: 'paid', priceText: '999' }, saved, false)).toEqual({});
  });
});
