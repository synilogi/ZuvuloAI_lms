import type { Course, CourseInput, CoursePricing } from '@syniastrolms/domain';
import { COURSE_PRICE_MAX, COURSE_PRICE_MIN, COURSE_TITLE_MIN, pricingOf } from '@syniastrolms/domain';
import type { FieldIssue } from '@/components/forms/Forms';

/* The course editor's form: its state, what blocks a save or a publish, and what it sends. */

export interface FormState extends Omit<CourseInput, 'pricing' | 'priceAmount'> {
  /** `unset` only on a course whose price no admin has chosen yet: it stays so until the admin picks one. */
  pricing: CoursePricing;
  /** The price as typed, in whole rupees — checked by `validate`, sent as a number. */
  priceText: string;
  /** A lower price it sells at now, as typed; empty for none. */
  saleText: string;
  /** `''` lets the API place a new course in the academy's first category. */
  categoryId: string;
  levelId: string;
  /** The uploaded cover image's media id, or null when the motif is the cover. */
  coverImageId: string | null;
  awardsCertificate: boolean;
}

/** What the person asked for: keep a private draft, or take the course live. */
export type Intent = 'draft' | 'publish';

/** Fields inside "Additional settings": a problem with one of them opens the panel. */
export const ADVANCED_FIELDS = new Set(['course-weeks', 'course-live', 'course-outcomes', 'course-certificate']);

export const TITLE_MAX = 90;
export const SUBTITLE_MAX = 160;
export const DESCRIPTION_MAX = 2000;

export function toForm(course: Course | null, defaults: { levelId: string; instructorId?: string }): FormState {
  if (!course) {
    return {
      title: '',
      subtitle: '',
      description: '',
      levelId: defaults.levelId,
      categoryId: '',
      instructorIds: defaults.instructorId ? [defaults.instructorId] : [],
      format: 'self-paced',
      language: 'English',
      coverMotif: 'houses',
      coverImageId: null,
      outcomes: [],
      tags: [],
      visibility: 'public',
      liveSessions: 0,
      estimatedWeeks: undefined,
      certificateTitle: '',
      awardsCertificate: false,
      // A new course starts free; the admin chooses Paid and its price.
      pricing: 'free',
      priceText: '',
      saleText: '',
    };
  }
  return {
    title: course.title,
    subtitle: course.subtitle,
    description: course.description,
    levelId: course.levelId,
    categoryId: course.categoryId,
    instructorIds: course.instructorIds,
    format: course.format,
    language: course.language,
    coverMotif: course.coverMotif,
    coverImageId: course.coverImageId ?? null,
    outcomes: course.outcomes,
    tags: course.tags,
    visibility: course.visibility,
    liveSessions: course.liveSessions,
    estimatedWeeks: course.estimatedWeeks,
    certificateTitle: course.certificateTitle ?? '',
    awardsCertificate: Boolean(course.certificateTitle),
    pricing: pricingOf(course),
    priceText: course.price ? String(course.price.amount) : '',
    saleText: course.salePrice ? String(course.salePrice) : '',
  };
}

const PRICE_RANGE = `between ₹${COURSE_PRICE_MIN} and ₹${COURSE_PRICE_MAX.toLocaleString('en-IN')}`;

/** What is wrong with a typed price, or null when it is a whole number of rupees in range. */
export function priceIssue(text: string): string | null {
  const t = text.trim().replace(/,/g, '');
  if (!t) return 'Enter the price in whole rupees.';
  if (!/^\d+$/.test(t)) return /^\d*\.\d+$/.test(t) ? 'Enter whole rupees only — no paise.' : 'Enter the price as a number of rupees, e.g. 1499.';
  const amount = Number(t);
  if (amount < COURSE_PRICE_MIN || amount > COURSE_PRICE_MAX) return `The price must be ${PRICE_RANGE}.`;
  return null;
}

/** The typed price as whole rupees (validated first). */
export const priceAmountOf = (text: string) => Number(text.trim().replace(/,/g, ''));

/**
 * What stops the form. A draft needs only a usable title; publishing — or saving a course that is already
 * live — also needs a description and an instructor (the same three items as `publishChecklist`).
 * Optional fields are only checked when they are filled in.
 */
export function validate(f: FormState, intent: Intent, { canPrice = true }: { canPrice?: boolean } = {}): FieldIssue[] {
  const issues: FieldIssue[] = [];
  const title = f.title.trim();
  if (!title) issues.push({ field: 'course-title', message: 'Give the course a title.' });
  else if (title.length < COURSE_TITLE_MIN) issues.push({ field: 'course-title', message: `The title needs at least ${COURSE_TITLE_MIN} characters.` });
  else if (title.length > TITLE_MAX) issues.push({ field: 'course-title', message: `Keep the title under ${TITLE_MAX} characters.` });
  if (intent === 'publish' && !f.description.trim())
    issues.push({ field: 'course-description', message: 'Add a short description — learners read it before they enrol.' });
  else if (f.description.length > DESCRIPTION_MAX) issues.push({ field: 'course-description', message: 'Keep the description under 2,000 characters.' });
  if (intent === 'publish' && !f.instructorIds.length) issues.push({ field: 'course-instructors', message: 'Assign at least one instructor.' });
  if (f.subtitle.length > SUBTITLE_MAX) issues.push({ field: 'course-subtitle', message: `Keep the subtitle under ${SUBTITLE_MAX} characters.` });
  if (f.estimatedWeeks !== undefined && (!Number.isInteger(f.estimatedWeeks) || f.estimatedWeeks < 1 || f.estimatedWeeks > 52))
    issues.push({ field: 'course-weeks', message: 'Estimated length must be between 1 and 52 weeks.' });
  if (!Number.isInteger(f.liveSessions) || f.liveSessions < 0 || f.liveSessions > 60)
    issues.push({ field: 'course-live', message: 'Live sessions must be between 0 and 60.' });
  if (f.outcomes.some((o) => o.length > 140)) issues.push({ field: 'course-outcomes', message: 'Keep each outcome under 140 characters.' });
  if (f.awardsCertificate && !f.certificateTitle?.trim()) issues.push({ field: 'course-certificate', message: 'Name the certificate learners will receive.' });
  // Only someone who sets prices is held to one; an instructor's save never touches pricing.
  if (canPrice && f.pricing === 'paid') {
    const problem = priceIssue(f.priceText);
    if (problem) issues.push({ field: 'course-price', message: problem });
    const sale = f.saleText.trim() ? priceAmountOf(f.saleText) : null;
    if (sale !== null && !(Number.isInteger(sale) && sale >= COURSE_PRICE_MIN && sale < priceAmountOf(f.priceText)))
      issues.push({ field: 'course-sale-price', message: 'A sale price is whole rupees, below the list price.' });
  }
  return issues;
}

/**
 * The pricing a save sends: for a new course always (free unless the admin chose paid); for an existing one only when
 * the admin changed it — a course's price is never rewritten by a save that did not touch it. Nothing for someone who
 * cannot set prices, or while the admin has not chosen (`unset`).
 */
export function pricingPayload(
  f: Pick<FormState, 'pricing' | 'priceText'>,
  baseline: Pick<FormState, 'pricing' | 'priceText'> | null,
  canPrice: boolean,
): Pick<CourseInput, 'pricing' | 'priceAmount'> {
  if (!canPrice || f.pricing === 'unset') return {};
  const amount = f.pricing === 'paid' ? priceAmountOf(f.priceText) : null;
  if (baseline) {
    const before = baseline.pricing === 'paid' ? priceAmountOf(baseline.priceText) : null;
    if (baseline.pricing === f.pricing && before === amount) return {};
  }
  return { pricing: f.pricing, priceAmount: amount };
}

/** What the form sends: trimmed text, and level or category only when one is chosen (the API places the rest). */
export function payloadOf(f: FormState, { baseline = null, canPrice = true }: { baseline?: FormState | null; canPrice?: boolean } = {}): CourseInput {
  const { awardsCertificate, categoryId, levelId, pricing, priceText, saleText, ...input } = f;
  const salePrice = pricing === 'paid' && saleText.trim() ? priceAmountOf(saleText) : null;
  const saleBefore = baseline?.pricing === 'paid' && baseline.saleText.trim() ? priceAmountOf(baseline.saleText) : null;
  return {
    ...input,
    ...pricingPayload({ pricing, priceText }, baseline, canPrice),
    // Sent only when it changed, by someone who sets prices.
    ...(canPrice && pricing === 'paid' && salePrice !== saleBefore ? { salePrice } : {}),
    ...(categoryId ? { categoryId } : {}),
    ...(levelId ? { levelId } : {}),
    title: input.title.trim(),
    subtitle: input.subtitle.trim(),
    description: input.description.trim(),
    outcomes: input.outcomes.map((o) => o.trim()).filter(Boolean),
    certificateTitle: awardsCertificate ? input.certificateTitle?.trim() : undefined,
  };
}
