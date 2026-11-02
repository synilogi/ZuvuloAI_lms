import type { Icon } from '@phosphor-icons/react';
import {
  BookOpenText,
  Certificate,
  ChalkboardTeacher,
  ChartLineUp,
  ClipboardText,
  Clock,
  CreditCard,
  DeviceMobile,
  Devices,
  Exam,
  Eye,
  GraduationCap,
  ListChecks,
  MagnifyingGlass,
  PlayCircle,
  ShieldCheck,
  UserPlus,
  UsersThree,
  VideoCamera,
} from '@phosphor-icons/react';

/*
 * The website's fixed words (docs/16 §2.6). The headline, testimonials and questions the Super Admin edits live in the
 * SiteContent document instead. Every claim here describes something the product does today, with no invented
 * customers or figures, and nothing on the site promises income (D-PLAT-13).
 */

export interface SiteFeature {
  icon: Icon;
  title: string;
  text: string;
}

export interface Step {
  title: string;
  text: string;
  icon: Icon;
}

export type { SiteFaq as Faq } from '@syniastrolms/domain';

/** Why learn here: what a course actually contains. */
export const WHY_LEARN: SiteFeature[] = [
  {
    icon: PlayCircle,
    title: 'Structured lessons',
    text: 'Courses are set out in chapters and lessons, so you always know what comes next and how far you have come.',
  },
  {
    icon: Exam,
    title: 'Practice that counts',
    text: 'Quizzes and assignments check what you have learned, and instructors review the work that needs a person.',
  },
  { icon: VideoCamera, title: 'Live classes', text: 'Courses with live sessions show them on your calendar, and you join from the course.' },
  { icon: Certificate, title: 'Certificates you can verify', text: 'A certificate carries an ID that anyone can check online.' },
];

/** What a learner gets from having an account. */
export const BENEFITS: SiteFeature[] = [
  { icon: Eye, title: 'See it before you buy', text: 'The outline, instructor and price are public, and some lessons are open as free previews.' },
  { icon: ChartLineUp, title: 'Progress saved for you', text: 'Pick up where you stopped. Your progress and notes stay with your account.' },
  {
    icon: CreditCard,
    title: 'Secure payments',
    text: 'Payments run through our payment gateway, and a course opens only once the gateway confirms the payment.',
  },
  { icon: ShieldCheck, title: 'Your orders in one place', text: 'Every order has its own number, and your purchase history is always in your account.' },
];

export const HOW_IT_WORKS: Step[] = [
  { icon: MagnifyingGlass, title: 'Find a course', text: 'Search the catalogue, or filter by category, level and price.' },
  { icon: UserPlus, title: 'Create your account', text: 'Add your name, email and mobile number, then confirm the code we send you.' },
  { icon: CreditCard, title: 'Enrol or buy', text: 'Free courses open at once. Paid courses open when the payment is confirmed.' },
  {
    icon: GraduationCap,
    title: 'Learn and finish',
    text: 'Work through the lessons, complete the assessments, and earn the certificate where the course offers one.',
  },
];

export const INSTRUCTOR_POINTS: SiteFeature[] = [
  { icon: BookOpenText, title: 'A full course builder', text: 'Chapters, lessons, video and documents, drafted and previewed before anything is published.' },
  { icon: ClipboardText, title: 'Assessments and review', text: 'Build quizzes and assignments, then review submissions from one queue.' },
  { icon: VideoCamera, title: 'Live classes', text: 'Schedule sessions for your course and hold them with your learners.' },
  { icon: UsersThree, title: 'Your learners in view', text: 'See who is enrolled in your courses and how they are progressing.' },
];

export const INSTRUCTOR_STEPS: Step[] = [
  { icon: ListChecks, title: 'Apply', text: 'Tell us what you teach, your experience, and where we can see your work.' },
  { icon: ShieldCheck, title: 'We review it', text: 'Our team reads every application and replies by email.' },
  { icon: ChalkboardTeacher, title: 'Start teaching', text: 'Once approved, you sign in to the instructor workspace and work on your courses.' },
];

/** The contact topics the website offers, as `/contact?topic=…`. The values stay as the inbox has always stored them. */
export const CONTACT_TOPICS = [
  { value: 'demo', label: 'General' },
  { value: 'sales', label: 'Courses & orders' },
  { value: 'support', label: 'Support' },
] as const;

export const SUPPORT_EMAIL = 'help@zuviloai.com';

/*
 * The company behind ZuviloAI, as its owner confirmed it on 2026-10-23 — the one place the website reads it from.
 * Only confirmed details are here. Still awaiting confirmation, and therefore shown nowhere:
 *   - the full registered address (street, building) — "Gumanpura, Kota" was all that was confirmed
 *   - the company's CIN, and its GSTIN (needed on tax invoices)
 *   - the grievance officer's name (India's IT Rules ask for it; the contact channels below stand in until then)
 * The support mailbox is a Gmail address until zuviloai.com has a mailbox of its own (no MX record as of 2026-10-23).
 */
export const COMPANY = {
  name: 'ZuviloAI',
  addressLines: ['Gumanpura', 'Kota, Rajasthan 324007', 'India'],
  phone: '+91 96490 96197',
  phoneHref: 'tel:+919649096197',
  email: SUPPORT_EMAIL,
} as const;

/** The address on one line, for running text. */
export const COMPANY_ADDRESS = COMPANY.addressLines.join(', ');

/** Why learn here, on the home page. Each is true of the product today; access follows each course's own terms. */
export const HOME_WHY: SiteFeature[] = [
  { icon: Devices, title: 'Learn anytime, anywhere', text: 'Lessons work on your phone, tablet or computer, and pick up where you stopped.' },
  { icon: ChalkboardTeacher, title: 'Expert-led courses', text: 'Every course is taught by an instructor our team has reviewed and approved.' },
  { icon: ListChecks, title: 'Structured learning', text: 'Chapters and lessons in order, so you always know what comes next and how far you have come.' },
  {
    icon: ClipboardText,
    title: 'Practical assignments',
    text: 'Quizzes and assignments check what you have learned, and instructors review the work that needs a person.',
  },
  { icon: VideoCamera, title: 'Live learning sessions', text: 'Courses with live classes show them on your calendar, and you join from the course.' },
  { icon: Certificate, title: 'Certificates', text: 'Courses that award one say so on their page, and anyone can check it on our Verify page.' },
  { icon: Clock, title: 'Clear access terms', text: 'You keep a course for as long as its terms say, and your progress stays with your account.' },
  { icon: DeviceMobile, title: 'Made for mobile', text: 'A layout built for small screens, not a shrunken desktop page.' },
];

/** How it works, on the home page. */
export const HOME_STEPS: Step[] = [
  { icon: MagnifyingGlass, title: 'Explore courses', text: 'Search the catalogue, or filter by category, level and price. No account needed.' },
  { icon: Eye, title: 'Choose your program', text: 'See the outline, the instructor and the price, and pick a single course or a bundle.' },
  { icon: CreditCard, title: 'Purchase and enrol', text: 'Pay through our gateway. Your course opens as soon as the payment is confirmed.' },
  {
    icon: GraduationCap,
    title: 'Learn, practise and grow',
    text: 'Work through the lessons and assignments, and earn the certificate where a course offers one.',
  },
];

/** The affiliate program on the home page, in the order someone goes through it. Nothing here promises income (D-PLAT-13). */
export const AFFILIATE_POINTS: string[] = [
  'Learn through ZuviloAI',
  'Join the affiliate program',
  'Get your referral link',
  'Refer eligible customers',
  'Track verified sales and eligible commissions',
  'View your network and rewards',
];
