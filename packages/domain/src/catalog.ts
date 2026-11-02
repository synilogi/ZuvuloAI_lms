/**
 * Learning taxonomy: Level → Category → Course → Chapter → Lesson.
 * Every layer is data. Nothing in the UI may assume a particular level,
 * category or count — render whatever the catalog returns.
 */

export type ID = string;
/** ISO-8601 timestamp, e.g. "2026-09-17T19:00:00+05:30". */
export type ISODateTime = string;

export interface Level {
  id: ID;
  name: string;
  /** 1-based position in the progression. */
  order: number;
  summary?: string;
}

export type CategoryStatus = 'active' | 'hidden';
/** Fine-line glyph drawn for a category. The set is closed so every glyph has artwork. */
export type CategoryGlyph = 'sun' | 'houses' | 'orbits' | 'nakshatra' | 'hourglass' | 'lotus' | 'compass' | 'moon';

export interface Category {
  id: ID;
  name: string;
  description: string;
  /** A category may span several levels. */
  levelIds: ID[];
  /** Display order in catalogs and filters, 1-based. */
  order: number;
  status: CategoryStatus;
  glyph: CategoryGlyph;
  updatedAt: ISODateTime;
}

export type InstructorStatus = 'active' | 'invited' | 'inactive';

export interface Instructor {
  id: ID;
  name: string;
  title: string;
  yearsTeaching?: number;
  email: string;
  bio: string;
  expertise: string[];
  status: InstructorStatus;
  joinedAt: ISODateTime;
  city: string;
  languages: string[];
  phone?: string;
  /** Display image; initials are shown until one is uploaded. */
  photo?: MediaFile;
}

export type InstructorInput = Omit<Instructor, 'id' | 'joinedAt'> & {
  /** Courses the instructor teaches. They can edit them, run live classes and review submissions. */
  courseIds: ID[];
};

export interface InstructorIssue {
  field: 'name' | 'title' | 'email' | 'phone' | 'bio' | 'expertise' | 'languages' | 'yearsTeaching';
  message: string;
}

/** What must be true to save an instructor. A full bio is only needed once they are active and visible to learners. */
export function validateInstructor(input: InstructorInput, takenEmails: string[] = []): InstructorIssue[] {
  const issues: InstructorIssue[] = [];
  const email = input.email.trim().toLowerCase();
  if (input.name.trim().length < 3) issues.push({ field: 'name', message: 'Enter the instructor’s full name.' });
  if (input.title.trim().length < 3) issues.push({ field: 'title', message: 'Add a professional title, such as “Senior Maths Faculty”.' });
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)) issues.push({ field: 'email', message: 'Enter a valid email address — the invitation is sent there.' });
  else if (takenEmails.map((e) => e.toLowerCase()).includes(email)) issues.push({ field: 'email', message: 'Another instructor already uses this email.' });
  if (input.phone && !/^\+?[\d\s-]{8,16}$/.test(input.phone.trim()))
    issues.push({ field: 'phone', message: 'Enter a phone number with 8 to 15 digits, or leave it empty.' });
  if (input.status === 'active' && input.bio.trim().length < 60)
    issues.push({ field: 'bio', message: 'Write a bio of at least 60 characters — learners read it on every course page.' });
  if (input.expertise.length === 0) issues.push({ field: 'expertise', message: 'Add at least one area of expertise.' });
  if (input.languages.length === 0) issues.push({ field: 'languages', message: 'Add the languages they teach in.' });
  if (input.yearsTeaching !== undefined && (input.yearsTeaching < 0 || input.yearsTeaching > 70))
    issues.push({ field: 'yearsTeaching', message: 'Years teaching should be between 0 and 70.' });
  return issues;
}

export type LessonType = 'video' | 'reading' | 'document' | 'live' | 'practice' | 'assignment' | 'assessment';
export type ContentStatus = 'draft' | 'published';

export interface Lesson {
  id: ID;
  title: string;
  type: LessonType;
  durationMin: number;
  /** Playable without enrollment. */
  isPreview?: boolean;
  status: ContentStatus;
  updatedAt: ISODateTime;
  description?: string;
  objectives?: string[];
  content?: LessonContent;
  settings?: LessonSettings;
}

export interface MediaFile {
  name: string;
  sizeMb: number;
  /** Set once the file is stored by the API. */
  id?: ID;
  /** API path the stored file streams from, e.g. `/media/<id>`. */
  url?: string;
  mime?: string;
}

/** What a lesson holds, by type. Only the block matching the lesson's type is used. */
export interface LessonContent {
  video?: { file?: MediaFile; durationSec?: number; captions: boolean; markers: { atSec: number; title: string }[] };
  article?: { body: string };
  document?: { file?: MediaFile; pages?: number; downloadable: boolean };
  /** Mirrors the linked quiz; questions and settings are edited in the quiz builder. */
  quiz?: { quizId?: ID; questions: number; passMark: number; attempts: number; timeLimitMin?: number };
  /** Mirrors the linked assignment; its brief, rubric and reviews are managed in Assignments. */
  assignment?: { assignmentId?: ID; brief: string; dueAfterDays: number; maxScore: number; submission: 'file' | 'text' | 'chart' };
  live?: { startsAt?: ISODateTime; durationMin: number; recorded: boolean; liveClassId?: ID };
}

/** How a lesson counts as done. */
export type CompletionRule = 'opened' | 'watched' | 'submitted' | 'passed';

export interface LessonSettings {
  completion: CompletionRule;
  /** Learners must finish the previous lesson first. */
  sequential: boolean;
  discussion: boolean;
  resourcesDownloadable: boolean;
}

export type LessonInput = Pick<Lesson, 'title' | 'type' | 'durationMin' | 'isPreview' | 'status' | 'description' | 'objectives' | 'content' | 'settings'>;

/** The default way a lesson of each type is completed. */
export const defaultCompletion: Record<LessonType, CompletionRule> = {
  video: 'watched',
  reading: 'opened',
  document: 'opened',
  live: 'opened',
  practice: 'submitted',
  assignment: 'submitted',
  assessment: 'passed',
};

export interface LessonIssue {
  field: string;
  message: string;
}

/** What stops a lesson from being published — shared by the editor and the API guard. */
export function lessonPublishIssues(lesson: Pick<Lesson, 'title' | 'type' | 'durationMin' | 'content'>): LessonIssue[] {
  const issues: LessonIssue[] = [];
  if (lesson.title.trim().length < 3) issues.push({ field: 'lesson-title', message: 'Give the lesson a title of at least 3 characters.' });
  if (!lesson.durationMin || lesson.durationMin < 1) issues.push({ field: 'lesson-duration', message: 'Set how long the lesson takes.' });
  const c = lesson.content;
  if (lesson.type === 'video' && !c?.video?.file) issues.push({ field: 'lesson-media', message: 'Add the video before publishing.' });
  if ((lesson.type === 'reading' || lesson.type === 'practice') && (c?.article?.body.trim().length ?? 0) < 80)
    issues.push({ field: 'lesson-body', message: 'Write at least a short paragraph before publishing.' });
  if (lesson.type === 'document' && !c?.document?.file) issues.push({ field: 'lesson-media', message: 'Attach the PDF before publishing.' });
  if (lesson.type === 'assignment' && (c?.assignment?.brief.trim().length ?? 0) < 20)
    issues.push({ field: 'lesson-brief', message: 'Describe what learners should submit.' });
  if (lesson.type === 'live' && !c?.live?.startsAt) issues.push({ field: 'lesson-live', message: 'Schedule the live session before publishing.' });
  return issues;
}

/** Reading time for article lessons at 200 words a minute. */
export const readingMinutes = (body: string) => Math.max(1, Math.round(body.trim().split(/\s+/).filter(Boolean).length / 200));

export interface Chapter {
  id: ID;
  title: string;
  summary?: string;
  /** What a learner can do after the chapter — one sentence. */
  objective?: string;
  /** Planned length before lessons exist; once lessons are added their minutes are the duration. */
  estimatedMin?: number;
  status: ContentStatus;
  lessons: Lesson[];
}

export type CourseFormat = 'self-paced' | 'cohort' | 'hybrid';
export type CoverMotif = 'orbits' | 'houses' | 'nakshatra' | 'ecliptic';
export type CourseStatus = 'draft' | 'published' | 'archived';
/** public — listed in the catalog · unlisted — reachable by link · private — invited learners only */
export type CourseVisibility = 'public' | 'unlisted' | 'private';

export interface Price {
  /** Whole rupees, all-inclusive: what the learner pays. */
  amount: number;
  currency: 'INR';
}

/**
 * Whether a course costs anything. `unset`: its price was never chosen by an admin (it came from the academy
 * default before pricing existed), so nobody can enrol themselves or buy it until an admin chooses free or paid.
 */
export type CoursePricing = 'free' | 'paid' | 'unset';

/** The prices an admin may set for a paid course, in whole rupees. */
export const COURSE_PRICE_MIN = 1;
export const COURSE_PRICE_MAX = 500_000;

/** A course's pricing as stored; a record from before pricing existed reads as undecided when it carries a price. */
export const pricingOf = (course: Pick<Course, 'pricing' | 'price'>): CoursePricing => course.pricing ?? (course.price ? 'unset' : 'free');

/** How a learner gets into a course: free to join, paid (at this price), or not open to them yet. */
export type CourseSale = { kind: 'free' } | { kind: 'paid'; price: Price; listPrice?: number } | { kind: 'unavailable' };

/** What joining a course takes. A paid course without a valid price is never free: it is unavailable. */
export function courseSale(course: Pick<Course, 'pricing' | 'price'> & { salePrice?: number }): CourseSale {
  const pricing = pricingOf(course);
  if (pricing === 'free') return { kind: 'free' };
  const amount = course.price?.amount;
  if (pricing === 'paid' && Number.isInteger(amount) && amount! >= COURSE_PRICE_MIN && amount! <= COURSE_PRICE_MAX && course.price!.currency === 'INR') {
    // A sale price counts only while it is a whole price below the list price; anything else sells at the list price.
    const sale = course.salePrice;
    if (Number.isInteger(sale) && sale! >= COURSE_PRICE_MIN && sale! < amount!)
      return { kind: 'paid', price: { ...course.price!, amount: sale! }, listPrice: amount! };
    return { kind: 'paid', price: course.price! };
  }
  return { kind: 'unavailable' };
}

/** The gateway charge for a price: rupees to paise. */
export const chargeOf = (price: Price) => price.amount * 100;

/** A purchase's state: `created` until the gateway confirms, `paid` once it did (the course is open), or neither. */
export type CoursePurchaseStatus = 'created' | 'paid' | 'failed' | 'expired';

/** A learner's purchase, as the API shows it to them. Amounts in paise; `listPrice` in whole rupees. */
export interface CoursePurchase {
  id: ID;
  /** `ORD-YYYY-NNNNNN`: what a receipt calls this order. */
  orderNumber: string;
  courseId: ID;
  courseTitle: string;
  status: CoursePurchaseStatus;
  amount: number;
  currency: 'INR';
  listPrice: number;
  /** What a coupon took off, in paise. */
  discountAmount?: number;
  couponCode?: string;
  /** Set when the whole order was refunded; the course is then closed. */
  refundedAt?: ISODateTime;
  /** Whether the course is open to the learner now (the purchase opened it, or they already had it). */
  enrolled: boolean;
  failureMessage?: string;
  /** Money the gateway took that opened nothing: the academy reviews it. */
  needsReview?: boolean;
  createdAt: ISODateTime;
  paidAt?: ISODateTime;
  /** The gateway's id for the payment, once one settled the order: what the learner quotes to their bank or to support. */
  paymentReference?: string;
}

export interface Course {
  /** A lower price the course sells at now, in whole rupees; `price` stays the list price. */
  salePrice?: number;
  id: ID;
  slug: string;
  title: string;
  subtitle: string;
  description: string;
  levelId: ID;
  categoryId: ID;
  instructorIds: ID[];
  format: CourseFormat;
  language: string;
  /** Generated artwork, drawn whenever there is no cover image or it cannot be loaded. */
  coverMotif: CoverMotif;
  /** The uploaded cover image's media id, when the course has one. */
  coverImageId?: ID;
  /** API path the cover image streams from (`/catalog/covers/<id>`); absent when there is none. */
  coverImageUrl?: string;
  chapters: Chapter[];
  liveSessions: number;
  /** Suggested pace, e.g. 12 weeks. Lesson minutes are summed separately. */
  estimatedWeeks?: number;
  certificateTitle?: string;
  price?: Price;
  /** Absent on records from before pricing existed: read it with `pricingOf`. */
  pricing?: CoursePricing;
  enrolledCount: number;
  status: CourseStatus;
  visibility: CourseVisibility;
  outcomes: string[];
  tags: string[];
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
  publishedAt?: ISODateTime;
  /** Mean learner rating, 1–5. */
  rating?: number;
  ratingCount?: number;
}

export function courseLessons(course: Course): Lesson[] {
  return course.chapters.flatMap((c) => c.lessons);
}

export function chapterDurationMin(chapter: Chapter): number {
  return chapter.lessons.reduce((sum, l) => sum + l.durationMin, 0);
}

export function courseDurationMin(course: Course): number {
  return course.chapters.reduce((sum, c) => sum + chapterDurationMin(c), 0);
}

/** URL-safe slug from a title: "Reading the Navamsha" → "reading-the-navamsha". */
export function slugify(title: string): string {
  return title
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}

export interface PublishCheck {
  id: string;
  label: string;
  met: boolean;
}

/** The shortest title a course can be saved or published with. */
export const COURSE_TITLE_MIN = 3;

/**
 * What a course needs before it can be published: a title, a description and an instructor. Everything
 * else — subtitle, outcomes, tags, cover, curriculum — is optional and can follow later. The same list
 * drives the editor, the publish dialog and the API guard.
 */
export function publishChecklist(course: Course): PublishCheck[] {
  return [
    { id: 'title', label: 'Course title', met: course.title.trim().length >= COURSE_TITLE_MIN },
    { id: 'description', label: 'Course description', met: course.description.trim().length > 0 },
    { id: 'instructor', label: 'At least one instructor', met: course.instructorIds.length > 0 },
  ];
}

/** Whether learners would find anything to study: a published chapter holding at least one published lesson. */
export function hasPublishedLessons(course: Course): boolean {
  return course.chapters.some((c) => c.status === 'published' && c.lessons.some((l) => l.status === 'published'));
}

/**
 * The editable fields of a course — what the create and edit forms send. Level and category may be left
 * out of a new course: the academy's first level and category fill them.
 */
export type CourseInput = Partial<{
  /** A lower price the course sells at now, in whole rupees; `null` ends the sale. */
  salePrice: number | null;
  /** An uploaded image's media id; `null` removes the cover image. Left out, the cover is unchanged. */
  coverImageId: ID | null;
}> &
  Partial<Pick<Course, 'levelId' | 'categoryId'>> &
  /** Free or paid, and the price in whole rupees for a paid course. Left out on an edit, both stay as they are. */
  Partial<{ pricing: 'free' | 'paid'; priceAmount: number | null }> &
  Pick<
    Course,
    | 'title'
    | 'subtitle'
    | 'description'
    | 'instructorIds'
    | 'format'
    | 'language'
    | 'coverMotif'
    | 'outcomes'
    | 'tags'
    | 'visibility'
    | 'liveSessions'
    | 'certificateTitle'
    | 'estimatedWeeks'
  >;

export type CategoryInput = Pick<Category, 'name' | 'description' | 'glyph' | 'status' | 'levelIds' | 'order'>;

export type ChapterInput = Pick<Chapter, 'title' | 'summary' | 'objective' | 'status' | 'estimatedMin'>;

/** Duration shown for a chapter: its lessons when it has any, otherwise the planned estimate. */
export function chapterDisplayMin(chapter: Chapter): number {
  return chapter.lessons.length ? chapterDurationMin(chapter) : (chapter.estimatedMin ?? 0);
}
