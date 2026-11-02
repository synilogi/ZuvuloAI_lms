import { db } from './db.js';
import { readJson } from './json.js';
import { APP_URL, queueEmail } from './mail.js';
import { adminUserIds, instructorUserIdsFor, notify, notifyMany } from './notify.js';
import { getSettings } from './settings.js';
import { dueAtFor } from '../routes/learning.js';

/**
 * Scheduled notification work, run by the scheduler in `index.ts` (every minute; each job decides
 * whether its moment has come). Every job is idempotent.
 */

const DAY_MS = 86_400_000;
const REVIEW_WINDOW_HOURS = 48;
const ist = (d: Date) => d.toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit', timeZone: 'Asia/Kolkata' });
const istHour = (d: Date) => Number(d.toLocaleString('en-GB', { hour: '2-digit', hour12: false, timeZone: 'Asia/Kolkata' }));
const istWeekday = (d: Date) => d.toLocaleDateString('en-GB', { weekday: 'short', timeZone: 'Asia/Kolkata' });

/**
 * Daily / weekly digest emails: one email per account listing the notifications since the last
 * digest. Daily digests go out after 08:00 IST; weekly ones on Monday after 08:00 IST.
 */
export async function sendDigests(now = new Date()): Promise<number> {
  if (istHour(now) < 8) return 0;
  const rows = await db.notificationSettings.findMany({ where: { emailDigest: { in: ['daily', 'weekly'] } }, include: { user: true } });
  let sent = 0;
  for (const row of rows) {
    const period = row.emailDigest === 'weekly' ? 7 * DAY_MS : DAY_MS;
    if (row.emailDigest === 'weekly' && istWeekday(now) !== 'Mon') continue;
    if (row.lastDigestAt && now.getTime() - row.lastDigestAt.getTime() < period - 60 * 60_000) continue;
    const since = row.lastDigestAt ?? new Date(now.getTime() - period);
    const items = await db.appNotification.findMany({
      where: { recipientId: row.userId, createdAt: { gt: since, lte: now }, category: { not: 'system' } },
      orderBy: { createdAt: 'desc' },
    });
    await db.notificationSettings.update({ where: { userId: row.userId }, data: { lastDigestAt: now } });
    if (!items.length) continue;
    const lines = [`Hi ${row.user.name.split(' ')[0]},`, '', `Here is what happened since your last ${row.emailDigest} digest:`, ''];
    for (const n of items) {
      const action = readJson<{ label: string; to: string } | undefined>(n.actionJson, undefined);
      lines.push(`• ${n.title}`, `  ${n.summary}`, ...(action ? [`  ${action.label}: ${APP_URL}${action.to}`] : []), '');
    }
    lines.push(`Manage how you hear from us: ${APP_URL}/notifications/preferences`);
    await queueEmail({
      to: row.user.email,
      name: row.user.name,
      subject: `Your ${row.emailDigest} ZuviloAI digest (${items.length})`,
      text: lines.join('\n'),
      templateKey: `digest-${row.emailDigest}`,
    });
    sent++;
  }
  return sent;
}

/** Tells a course's instructors once about each submission that has waited longer than the review window. */
export async function notifyOverdueReviews(now = new Date()): Promise<number> {
  const cutoff = new Date(now.getTime() - REVIEW_WINDOW_HOURS * 3_600_000);
  const overdue = await db.submission.findMany({
    where: { reviewStatus: { in: ['waiting', 'in-review'] }, submittedAt: { lt: cutoff }, overdueNotifiedAt: null },
    include: { assignment: { include: { course: { select: { title: true } } } }, student: { include: { user: { select: { name: true } } } } },
  });
  let sent = 0;
  for (const s of overdue) {
    const hours = Math.round((now.getTime() - s.submittedAt.getTime()) / 3_600_000);
    const delivered = await notifyMany(await instructorUserIdsFor(s.assignment.courseId), {
      category: 'assignment',
      title: `Review overdue: ${s.student.user.name} · ${s.assignment.title}`,
      summary: `${s.assignment.course.title} · submitted ${ist(s.submittedAt)} IST, waiting ${hours} hours. Learners expect feedback within ${REVIEW_WINDOW_HOURS} hours.`,
      important: true,
      facts: [
        { label: 'Waiting', value: `${hours} h` },
        { label: 'Course', value: s.assignment.course.title },
      ],
      action: { label: 'Review now', to: `/teach/assignments/${s.assignmentId}/submissions/${s.id}` },
      switch: 'staff.reviewOverdue',
    });
    await db.submission.update({ where: { id: s.id }, data: { overdueNotifiedAt: now } });
    sent += delivered;
  }
  return sent;
}

/** A daily enrolment summary for admins and each course's instructors, after 08:00 IST, covering the previous day. */
export async function sendDailyEnrolments(now = new Date()): Promise<number> {
  if (istHour(now) < 8) return 0;
  const { notifications } = await getSettings();
  if (!notifications.staff.dailyEnrolments) return 0;
  const to = new Date(now.getTime() - (now.getTime() % DAY_MS));
  const from = new Date(to.getTime() - DAY_MS);
  const marker = `daily-enrolments-${to.toISOString().slice(0, 10)}`;
  if (await db.appNotification.findFirst({ where: { actor: marker }, select: { id: true } })) return 0;
  const rows = await db.enrollment.findMany({ where: { enrolledAt: { gte: from, lt: to } }, include: { course: { select: { id: true, title: true } } } });
  if (!rows.length) return 0;
  const byCourse = new Map<string, { title: string; count: number }>();
  for (const r of rows) byCourse.set(r.courseId, { title: r.course.title, count: (byCourse.get(r.courseId)?.count ?? 0) + 1 });
  const summary = [...byCourse.values()].map((c) => `${c.title}: ${c.count}`).join(' · ');
  let sent = await notifyMany(await adminUserIds(), {
    category: 'enrollment',
    title: `${rows.length} new enrolment${rows.length === 1 ? '' : 's'} yesterday`,
    summary,
    actor: marker,
    action: { label: 'Enrolment report', to: '/admin/reports/enrolments' },
    switch: 'staff.dailyEnrolments',
  });
  for (const [courseId, c] of byCourse) {
    sent += await notifyMany(await instructorUserIdsFor(courseId), {
      category: 'enrollment',
      title: `${c.count} new enrolment${c.count === 1 ? '' : 's'} in ${c.title} yesterday`,
      summary: `Welcome them in your next class or with a message from the students list.`,
      actor: marker,
      action: { label: 'See learners', to: `/teach/students?course=${courseId}` },
      switch: 'staff.dailyEnrolments',
    });
  }
  return sent;
}

/** Nudges learners who have gone quiet with active courses (after `atRiskDays`), at most once a week. */
export async function sendInactivityNudges(now = new Date()): Promise<number> {
  const { notifications, learning } = await getSettings();
  if (!notifications.learner.inactivityNudge || !learning.learnerPreferences.studyReminders) return 0;
  const quietSince = new Date(now.getTime() - learning.atRiskDays * DAY_MS);
  const students = await db.student.findMany({
    where: {
      suspended: false,
      lastActiveAt: { lt: quietSince },
      OR: [{ nudgedAt: null }, { nudgedAt: { lt: new Date(now.getTime() - 7 * DAY_MS) } }],
      enrollments: { some: { status: 'active' } },
    },
    include: {
      enrollments: { where: { status: 'active' }, include: { course: { select: { id: true, title: true } } }, orderBy: { lastActiveAt: 'desc' }, take: 1 },
    },
  });
  let sent = 0;
  for (const s of students) {
    const course = s.enrollments[0]?.course;
    if (!course) continue;
    const days = Math.round((now.getTime() - s.lastActiveAt.getTime()) / DAY_MS);
    const r = await notify({
      recipientUserId: s.userId,
      category: 'course',
      title: `Pick up ${course.title} where you left off`,
      summary: `It has been ${days} days since your last lesson. Twenty minutes this week is enough to get the rhythm back.`,
      action: { label: 'Continue learning', to: `/learn/${course.id}` },
      switch: 'learner.inactivityNudge',
    });
    await db.student.update({ where: { id: s.id }, data: { nudgedAt: now } });
    if (r.app || r.email || r.digest) sent++;
  }
  return sent;
}

/** Reminds learners who still owe an assignment `assignmentReminderDays` before a fixed deadline (once). */
export async function sendAssignmentDueReminders(now = new Date()): Promise<number> {
  const { notifications } = await getSettings();
  const days = notifications.learner.assignmentReminderDays;
  if (!days || days <= 0) return 0;
  const assignments = await db.courseAssignment.findMany({ where: { status: 'published' }, include: { course: { select: { title: true } } } });
  let sent = 0;
  for (const a of assignments) {
    const due = readJson<{ kind: string; dueAt?: string }>(a.dueJson, { kind: 'none' });
    if (due.kind !== 'date' || !due.dueAt) continue;
    const dueAt = new Date(due.dueAt);
    const window = dueAt.getTime() - days * DAY_MS;
    if (now.getTime() < window || now.getTime() >= dueAt.getTime()) continue;
    const marker = `assignment-due-${a.id}`;
    const enrolled = await db.enrollment.findMany({
      where: { courseId: a.courseId, status: 'active' },
      include: { student: { select: { id: true, userId: true } } },
    });
    const submitted = new Set((await db.submission.findMany({ where: { assignmentId: a.id }, select: { studentId: true } })).map((s) => s.studentId));
    for (const e of enrolled) {
      if (submitted.has(e.studentId)) continue;
      if (await db.appNotification.findFirst({ where: { recipientId: e.student.userId, actor: marker }, select: { id: true } })) continue;
      const when = await dueAtFor(a, e.studentId, e.enrolledAt);
      const r = await notify({
        recipientUserId: e.student.userId,
        category: 'assignment',
        title: `“${a.title}” is due in ${days} day${days === 1 ? '' : 's'}`,
        summary: `${a.course.title} · due ${ist(new Date(when ?? due.dueAt))} IST. Hand in from the assignment page.`,
        actor: marker,
        action: { label: 'Open the assignment', to: `/assignments/${a.id}` },
      });
      if (r.app || r.email || r.digest) sent++;
    }
  }
  return sent;
}

/**
 * Archives published courses nobody has touched for `settings.courses.archiveInactiveMonths`: no active
 * enrollment, no edit and no enrolment in that time. Admins are told which courses were archived.
 */
export async function archiveInactiveCourses(now = new Date()): Promise<number> {
  const { courses } = await getSettings();
  const months = courses.archiveInactiveMonths;
  if (!months || months <= 0) return 0;
  const cutoff = new Date(now);
  cutoff.setMonth(cutoff.getMonth() - months);
  const stale = await db.course.findMany({
    where: {
      status: 'published',
      updatedAt: { lt: cutoff },
      enrollments: { none: { OR: [{ status: 'active' }, { enrolledAt: { gte: cutoff } }, { lastActiveAt: { gte: cutoff } }] } },
    },
    select: { id: true, title: true },
  });
  if (!stale.length) return 0;
  await db.course.updateMany({ where: { id: { in: stale.map((c) => c.id) } }, data: { status: 'archived' } });
  await notifyMany(await adminUserIds(), {
    category: 'course',
    title: `${stale.length} inactive course${stale.length === 1 ? '' : 's'} archived`,
    summary: `No activity for ${months} months: ${stale.map((c) => c.title).join(', ')}. Restore any of them from the courses list.`,
    action: { label: 'Archived courses', to: '/admin/courses?status=archived' },
  });
  return stale.length;
}

/** Everything the scheduler runs each tick. */
export async function runNotificationJobs(now = new Date()) {
  return {
    digests: await sendDigests(now),
    overdueReviews: await notifyOverdueReviews(now),
    dailyEnrolments: await sendDailyEnrolments(now),
    nudges: await sendInactivityNudges(now),
    dueReminders: await sendAssignmentDueReminders(now),
    archived: await archiveInactiveCourses(now),
  };
}
