import type { CourseFormat, CourseVisibility, ID, ISODateTime } from './catalog';
import type { CertificateAccent } from './certificate';

/** open — anyone can enrol · approval — requests wait for an admin · invite — admins enrol learners */
export type EnrollmentPolicy = 'open' | 'approval' | 'invite';
/** view — opening counts · time — most of the lesson must play or be read · check — its quiz must be passed */
export type LessonCompletionRule = 'view' | 'time' | 'check';
export type CourseCompletionRule = 'all-lessons' | 'lessons-and-assessments' | 'percentage';
export type LatePolicy = 'accept' | 'penalty' | 'reject';
export type ReleasePolicy = 'all-at-once' | 'sequential' | 'scheduled';

export interface GeneralSettings {
  academyName: string;
  /** What learners see as the name of their space, e.g. "Learning". */
  lmsLabel: string;
  supportEmail: string;
  language: 'en-IN' | 'hi-IN';
  defaultVisibility: CourseVisibility;
  enrollment: EnrollmentPolicy;
  /** Months of access after enrolling; null for lifetime. */
  accessMonths: number | null;
  lessonDefaults: {
    durationMin: number;
    completion: LessonCompletionRule;
    allowComments: boolean;
    allowDownloads: boolean;
    previewFirstLesson: boolean;
  };
}

export interface CourseSettings {
  defaultFormat: CourseFormat;
  release: ReleasePolicy;
  requireReview: boolean;
  maxInstructors: number;
  defaultPrice: number;
  showRatings: boolean;
  /** Ratings stay hidden until a course has this many. */
  minRatings: number;
  showEnrolmentCount: boolean;
  archiveInactiveMonths: number | null;
}

export interface LearningSettings {
  /** Share of a video or reading that counts as finished, 50–100. */
  completionThreshold: number;
  courseCompletion: CourseCompletionRule;
  /** Used when course completion is a percentage. */
  completionPercent: number;
  chapterGate: boolean;
  quizAttempts: number;
  retakeWaitHours: number;
  latePolicy: LatePolicy;
  latePenalty: number;
  /** Quiet days before a learner reads as at risk. */
  atRiskDays: number;
  learnerPreferences: {
    playbackSpeed: boolean;
    captionsByDefault: boolean;
    downloadNotes: boolean;
    showRank: boolean;
    studyReminders: boolean;
  };
}

export interface CertificateSettings {
  enabled: boolean;
  autoIssue: boolean;
  minScore: number;
  defaultTemplateId: ID;
  fields: { hours: boolean; score: boolean; level: boolean; signatures: boolean };
  publicVerification: boolean;
  credentialPrefix: string;
  /** Months until a certificate needs renewing; null for never. */
  validityMonths: number | null;
}

export interface AcademyNotificationSettings {
  senderName: string;
  replyTo: string;
  learner: {
    enrolmentConfirmation: boolean;
    liveReminderMinutes: number[];
    assignmentReminderDays: number;
    weeklyDigest: boolean;
    inactivityNudge: boolean;
    certificateIssued: boolean;
  };
  staff: {
    newSubmission: boolean;
    reviewOverdue: boolean;
    dailyEnrolments: boolean;
    courseReview: boolean;
  };
  smsEnabled: boolean;
}

export type BrandAccent = CertificateAccent | 'plum';

export interface AppearanceSettings {
  brandName: string;
  accent: BrandAccent;
  learnerTheme: 'system' | 'light' | 'dark';
  density: 'comfortable' | 'compact';
  coverArt: boolean;
  welcomeMessage: string;
}

export interface LmsSettings {
  general: GeneralSettings;
  courses: CourseSettings;
  learning: LearningSettings;
  certificates: CertificateSettings;
  notifications: AcademyNotificationSettings;
  appearance: AppearanceSettings;
}

export type SettingsSection = keyof LmsSettings;

export const SETTINGS_SECTIONS: SettingsSection[] = ['general', 'courses', 'learning', 'certificates', 'notifications', 'appearance'];

export interface SettingsIssue {
  field: string;
  message: string;
}

const email = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const between = (n: number, min: number, max: number) => Number.isFinite(n) && n >= min && n <= max;

/** What each section needs before it can be saved. Field names match the form's control ids. */
export function validateSettings<S extends SettingsSection>(section: S, value: LmsSettings[S]): SettingsIssue[] {
  const issues: SettingsIssue[] = [];
  const add = (field: string, message: string) => issues.push({ field, message });
  if (section === 'general') {
    const v = value as GeneralSettings;
    if (v.academyName.trim().length < 3 || v.academyName.trim().length > 60) add('academyName', 'The academy name needs 3 to 60 characters.');
    if (v.lmsLabel.trim().length < 2 || v.lmsLabel.trim().length > 24) add('lmsLabel', 'The display label needs 2 to 24 characters — it sits in the sidebar.');
    if (!email.test(v.supportEmail.trim())) add('supportEmail', 'Enter a support email learners can write to, like help@zuviloai.com.');
    if (!between(v.lessonDefaults.durationMin, 1, 240)) add('lessonDuration', 'A default lesson length is between 1 and 240 minutes.');
  }
  if (section === 'courses') {
    const v = value as CourseSettings;
    if (!between(v.maxInstructors, 1, 5)) add('maxInstructors', 'A course can have 1 to 5 instructors.');
    if (!between(v.defaultPrice, 0, 500_000)) add('defaultPrice', 'The default price is between ₹0 and ₹5,00,000.');
    if (v.showRatings && !between(v.minRatings, 1, 50)) add('minRatings', 'Show ratings after 1 to 50 of them.');
  }
  if (section === 'learning') {
    const v = value as LearningSettings;
    if (!between(v.completionThreshold, 50, 100)) add('completionThreshold', 'Count a lesson as finished at 50% to 100% of it.');
    if (v.courseCompletion === 'percentage' && !between(v.completionPercent, 50, 100))
      add('completionPercent', 'A course finishes at 50% to 100% of its lessons.');
    if (!between(v.quizAttempts, 1, 10)) add('quizAttempts', 'Allow 1 to 10 quiz attempts.');
    if (v.latePolicy === 'penalty' && !between(v.latePenalty, 1, 100)) add('latePenalty', 'The late penalty is between 1% and 100%.');
    if (!between(v.atRiskDays, 3, 44)) add('atRiskDays', 'A learner reads as at risk after 3 to 44 quiet days — inactive starts at 45.');
  }
  if (section === 'certificates') {
    const v = value as CertificateSettings;
    if (v.enabled && !between(v.minScore, 0, 100)) add('minScore', 'The minimum final score is between 0% and 100%.');
    if (!/^[A-Z]{2,4}$/.test(v.credentialPrefix)) add('credentialPrefix', 'Use 2 to 4 capital letters for the credential prefix.');
    if (v.enabled && !v.defaultTemplateId) add('defaultTemplateId', 'Choose the template new certificates use.');
  }
  if (section === 'notifications') {
    const v = value as AcademyNotificationSettings;
    if (v.senderName.trim().length < 2) add('senderName', 'Give emails a sender name learners will recognise.');
    if (!email.test(v.replyTo.trim())) add('replyTo', 'Enter a reply-to email address.');
    if (!between(v.learner.assignmentReminderDays, 0, 14)) add('assignmentReminderDays', 'Remind learners 0 to 14 days before a deadline.');
  }
  if (section === 'appearance') {
    const v = value as AppearanceSettings;
    if (v.brandName.trim().length < 2 || v.brandName.trim().length > 40) add('brandName', 'The brand name needs 2 to 40 characters.');
    if (v.welcomeMessage.trim().length > 160) add('welcomeMessage', 'Keep the welcome message to 160 characters.');
  }
  return issues;
}

export interface SettingsRecord {
  settings: LmsSettings;
  updatedAt: Record<SettingsSection, ISODateTime>;
  updatedBy: Record<SettingsSection, string>;
}
