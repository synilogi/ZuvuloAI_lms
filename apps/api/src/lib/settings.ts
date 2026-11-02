import { Prisma } from '@prisma/client';
import { SETTINGS_SECTIONS, type LmsSettings, type SettingsRecord, type SettingsSection } from '@syniastrolms/domain';

import { db } from './db.js';
import { readJson, writeJson } from './json.js';
import { currentTenantId, tenant } from './tenancy.js';

/** An academy's settings. Every module reads them through `getSettings()`, for the academy of the current context; its row is created on first use. */
export const DEFAULTS: LmsSettings = {
  general: {
    academyName: 'ZuviloAI',
    lmsLabel: 'Learning',
    supportEmail: 'synilogicteam@gmail.com',
    language: 'en-IN',
    defaultVisibility: 'public',
    enrollment: 'open',
    accessMonths: null,
    lessonDefaults: { durationMin: 15, completion: 'time', allowComments: true, allowDownloads: true, previewFirstLesson: true },
  },
  courses: {
    defaultFormat: 'self-paced',
    release: 'sequential',
    requireReview: true,
    maxInstructors: 3,
    defaultPrice: 2999,
    showRatings: true,
    minRatings: 5,
    showEnrolmentCount: true,
    archiveInactiveMonths: 12,
  },
  learning: {
    completionThreshold: 90,
    courseCompletion: 'all-lessons',
    completionPercent: 90,
    chapterGate: true,
    quizAttempts: 3,
    retakeWaitHours: 24,
    latePolicy: 'penalty',
    latePenalty: 10,
    atRiskDays: 10,
    learnerPreferences: { playbackSpeed: true, captionsByDefault: false, downloadNotes: true, showRank: true, studyReminders: true },
  },
  certificates: {
    enabled: true,
    autoIssue: false,
    minScore: 60,
    defaultTemplateId: '',
    fields: { hours: true, score: true, level: true, signatures: true },
    publicVerification: true,
    credentialPrefix: 'SA',
    validityMonths: null,
  },
  notifications: {
    senderName: 'ZuviloAI',
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

/** The current academy's settings (D5 — settings belong to an academy), created with the defaults on first read. */
/** The columns of a new settings row holding `settings`, every section stamped as written by the system now. */
export function newSettingsRow(settings: LmsSettings) {
  const now = new Date().toISOString();
  const updatedAt = Object.fromEntries(SETTINGS_SECTIONS.map((s) => [s, now])) as Record<SettingsSection, string>;
  const updatedBy = Object.fromEntries(SETTINGS_SECTIONS.map((s) => [s, 'system'])) as Record<SettingsSection, string>;
  return {
    record: { settings, updatedAt, updatedBy },
    data: {
      generalJson: writeJson(settings.general),
      coursesJson: writeJson(settings.courses),
      learningJson: writeJson(settings.learning),
      certificatesJson: writeJson(settings.certificates),
      notificationsJson: writeJson(settings.notifications),
      appearanceJson: writeJson(settings.appearance),
      updatedAtJson: writeJson(updatedAt),
      updatedByJson: writeJson(updatedBy),
    },
  };
}

export async function loadRecord(): Promise<SettingsRecord> {
  let row = await db.settings.findUnique({ where: { tenantId: currentTenantId() } });
  if (!row) {
    const fresh = newSettingsRow(DEFAULTS);
    try {
      await db.settings.create({ data: { ...tenant(), ...fresh.data } });
      return fresh.record;
    } catch (err) {
      // Two first reads raced and the other created the row: read the one that was written.
      if (!(err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002')) throw err;
      row = await db.settings.findUniqueOrThrow({ where: { tenantId: currentTenantId() } });
    }
  }
  return {
    settings: {
      general: readJson(row.generalJson, DEFAULTS.general),
      courses: readJson(row.coursesJson, DEFAULTS.courses),
      learning: readJson(row.learningJson, DEFAULTS.learning),
      certificates: readJson(row.certificatesJson, DEFAULTS.certificates),
      notifications: readJson(row.notificationsJson, DEFAULTS.notifications),
      appearance: readJson(row.appearanceJson, DEFAULTS.appearance),
    },
    updatedAt: readJson(row.updatedAtJson, {} as Record<SettingsSection, string>),
    updatedBy: readJson(row.updatedByJson, {} as Record<SettingsSection, string>),
  };
}

export const getSettings = async (): Promise<LmsSettings> => (await loadRecord()).settings;
