import { db } from './db.js';
import { notifyMany } from './notify.js';

/**
 * Reminders for events added in the calendar: `notifyMin` minutes before the event, the owner is
 * told, and the course's learners too when the audience is "learners". Run by the scheduler.
 */

const when = (d: Date) =>
  d.toLocaleString('en-IN', { weekday: 'short', day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit', timeZone: 'Asia/Kolkata' });

export async function sendDueCalendarReminders(now = new Date()): Promise<number> {
  const events = await db.calendarEvent.findMany({
    where: { notifyMin: { not: null }, notifiedAt: null, cancelled: false, done: false, startsAt: { gt: now } },
    include: { course: { select: { title: true } } },
  });
  let sent = 0;
  for (const e of events) {
    if (e.startsAt.getTime() - (e.notifyMin ?? 0) * 60_000 > now.getTime()) continue;
    const recipients = new Set<string>();
    if (e.ownerId) recipients.add(e.ownerId);
    if (e.audience === 'learners' && e.courseId) {
      const learners = await db.enrollment.findMany({
        where: { courseId: e.courseId, status: { in: ['active', 'completed'] } },
        select: { student: { select: { userId: true } } },
      });
      for (const l of learners) recipients.add(l.student.userId);
    }
    const lead = e.notifyMin ?? 0;
    const leadText =
      lead >= 1440
        ? `${Math.round(lead / 1440)} day${Math.round(lead / 1440) === 1 ? '' : 's'}`
        : lead >= 60
          ? `${Math.round(lead / 60)} hour${Math.round(lead / 60) === 1 ? '' : 's'}`
          : `${lead} min`;
    await notifyMany([...recipients], {
      category: e.type === 'quiz' ? 'quiz' : 'course',
      title: `${e.title} · in ${leadText}`,
      summary: `${e.course?.title ? `${e.course.title} · ` : ''}${when(e.startsAt)} IST${e.description ? `. ${e.description}` : ''}`,
      facts: [{ label: 'When', value: `${when(e.startsAt)} IST` }, ...(e.course ? [{ label: 'Course', value: e.course.title }] : [])],
      action: e.quizId && e.courseId ? { label: 'Open the course', to: `/learn/${e.courseId}` } : undefined,
    });
    await db.calendarEvent.update({ where: { id: e.id }, data: { notifiedAt: now } });
    sent++;
  }
  return sent;
}
