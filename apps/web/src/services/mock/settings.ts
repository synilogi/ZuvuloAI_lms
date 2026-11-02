import type { LmsSettings, SettingsRecord, SettingsSection } from '@syniastrolms/domain';
import { SETTINGS_SECTIONS, validateSettings } from '@syniastrolms/domain';
import type { SettingsService } from '../contracts';
import { ServiceError } from '../contracts';
import { mockNowIso } from './clock';
import { personas } from './fixtures/learner';
import { respond } from './simulation';

const DEFAULTS: LmsSettings = {
  general: {
    academyName: 'ZuviloAI Academy',
    lmsLabel: 'Learning',
    supportEmail: 'synilogicteam@gmail.com',
    language: 'en-IN',
    defaultVisibility: 'public',
    enrollment: 'open',
    accessMonths: 12,
    lessonDefaults: { durationMin: 15, completion: 'time', allowComments: true, allowDownloads: false, previewFirstLesson: true },
  },
  courses: {
    defaultFormat: 'self-paced',
    release: 'sequential',
    requireReview: true,
    maxInstructors: 2,
    defaultPrice: 12_500,
    showRatings: true,
    minRatings: 10,
    showEnrolmentCount: true,
    archiveInactiveMonths: 18,
  },
  learning: {
    completionThreshold: 90,
    courseCompletion: 'lessons-and-assessments',
    completionPercent: 90,
    chapterGate: true,
    quizAttempts: 2,
    retakeWaitHours: 48,
    latePolicy: 'penalty',
    latePenalty: 10,
    atRiskDays: 10,
    learnerPreferences: { playbackSpeed: true, captionsByDefault: false, downloadNotes: true, showRank: true, studyReminders: true },
  },
  certificates: {
    enabled: true,
    autoIssue: false,
    minScore: 70,
    defaultTemplateId: 'tpl-classic',
    fields: { hours: true, score: true, level: true, signatures: true },
    publicVerification: true,
    credentialPrefix: 'SA',
    validityMonths: null,
  },
  notifications: {
    senderName: 'ZuviloAI Academy',
    replyTo: 'hello@zuviloai.com',
    learner: {
      enrolmentConfirmation: true,
      liveReminderMinutes: [1440, 60, 15],
      assignmentReminderDays: 2,
      weeklyDigest: true,
      inactivityNudge: true,
      certificateIssued: true,
    },
    staff: { newSubmission: true, reviewOverdue: true, dailyEnrolments: false, courseReview: true },
    smsEnabled: true,
  },
  appearance: {
    brandName: 'ZuviloAI',
    accent: 'indigo',
    learnerTheme: 'system',
    density: 'comfortable',
    coverArt: true,
    welcomeMessage: 'Pick up where you left off — your next lesson is waiting.',
  },
};

const clone = <T>(v: T): T => JSON.parse(JSON.stringify(v));

const record: SettingsRecord = {
  settings: clone(DEFAULTS),
  updatedAt: {
    general: '2026-08-02T11:20:00+05:30',
    courses: '2026-07-14T16:05:00+05:30',
    learning: '2026-08-28T10:40:00+05:30',
    certificates: '2026-06-19T12:15:00+05:30',
    notifications: '2026-09-03T09:50:00+05:30',
    appearance: '2026-05-30T18:30:00+05:30',
  },
  updatedBy: Object.fromEntries(
    SETTINGS_SECTIONS.map((s) => [s, s === 'learning' ? 'Dr. Meenakshi Iyer' : personas.admin.name]),
  ) as SettingsRecord['updatedBy'],
};

/** The academy's learning rules as saved — the quiz attempt limit and retake wait the mock's quiz sessions enforce. */
export const mockLearningRules = () => record.settings.learning;

export const settingsService: SettingsService = {
  get: () => respond(() => clone(record), 520),

  save: <S extends SettingsSection>(section: S, value: LmsSettings[S]) =>
    respond(() => {
      if (!SETTINGS_SECTIONS.includes(section)) throw new ServiceError('That settings section doesn’t exist.', 'not-found');
      const issues = validateSettings(section, value);
      if (issues.length) throw new ServiceError(issues[0].message, 'conflict');
      record.settings[section] = clone(value);
      record.updatedAt[section] = mockNowIso();
      record.updatedBy[section] = personas.admin.name;
      return clone(record);
    }, 750),
};
