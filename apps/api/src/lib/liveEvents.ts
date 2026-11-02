import { db } from './db.js';
import { readJson, writeJson } from './json.js';
import { notify, notifyMany } from './notify.js';

/**
 * Live-class events: scheduled → learners of the course, cancelled / reminders → registered
 * learners. `sendDueReminders` is run by the scheduler in `index.ts` every minute.
 */

const when = (d: Date) =>
  d.toLocaleString('en-IN', { weekday: 'short', day: 'numeric', month: 'short', hour: 'numeric', minute: '2-digit', timeZone: 'Asia/Kolkata' });

type LiveRow = { id: string; title: string; courseId: string; startsAt: Date; durationMin: number };

async function enrolledUserIds(courseId: string) {
  const rows = await db.enrollment.findMany({
    where: { courseId, status: { in: ['active', 'completed'] } },
    select: { student: { select: { userId: true } } },
  });
  return rows.map((r) => r.student.userId);
}

async function registeredUserIds(liveClassId: string) {
  const rows = await db.liveRegistration.findMany({ where: { liveClassId }, select: { student: { select: { userId: true } } } });
  return rows.map((r) => r.student.userId);
}

export async function notifyLiveScheduled(live: LiveRow, courseTitle: string, instructorName: string) {
  return notifyMany(await enrolledUserIds(live.courseId), {
    category: 'live',
    title: `New live class: ${live.title}`,
    summary: `${courseTitle} · ${when(live.startsAt)} IST · ${live.durationMin} min. Register to save your seat.`,
    actor: instructorName,
    facts: [
      { label: 'Course', value: courseTitle },
      { label: 'Starts', value: `${when(live.startsAt)} IST` },
      { label: 'Length', value: `${live.durationMin} min` },
    ],
    action: { label: 'See the class', to: `/live/${live.id}` },
  });
}

/** Everyone who was told about the class (the course's learners) and everyone holding a place hears it is off. */
export async function notifyLiveCancelled(live: LiveRow, courseTitle: string, reason: string) {
  return notifyMany([...(await enrolledUserIds(live.courseId)), ...(await registeredUserIds(live.id))], {
    category: 'live',
    title: `Cancelled: ${live.title}`,
    summary: `${courseTitle} · was ${when(live.startsAt)} IST. ${reason}`,
    important: true,
    facts: [{ label: 'Reason', value: reason }],
    action: { label: 'Live classes', to: '/live' },
  });
}

/** The class moved: the course's learners and everyone holding a place are told the new time. */
export async function notifyLiveRescheduled(live: LiveRow, courseTitle: string, previousStart: Date) {
  return notifyMany([...(await enrolledUserIds(live.courseId)), ...(await registeredUserIds(live.id))], {
    category: 'live',
    title: `New time: ${live.title}`,
    summary: `${courseTitle} · now ${when(live.startsAt)} IST (was ${when(previousStart)} IST) · ${live.durationMin} min.`,
    important: true,
    facts: [
      { label: 'Now', value: `${when(live.startsAt)} IST` },
      { label: 'Was', value: `${when(previousStart)} IST` },
      { label: 'Length', value: `${live.durationMin} min` },
    ],
    action: { label: 'See the class', to: `/live/${live.id}` },
  });
}

/** The host has opened the room: the course's learners and everyone holding a place can go in now. */
export async function notifyLiveStarted(live: LiveRow, courseTitle: string, instructorName: string) {
  const recipients = [...(await enrolledUserIds(live.courseId)), ...(await registeredUserIds(live.id))];
  return notifyMany(recipients, {
    category: 'live',
    title: `Live now: ${live.title}`,
    summary: `${instructorName} has started the class. ${courseTitle} · ${live.durationMin} min.`,
    important: true,
    actor: instructorName,
    facts: [{ label: 'Course', value: courseTitle }],
    action: { label: 'Join the class', to: `/live/${live.id}` },
  });
}

/** A reminder to everyone registered, worded from the time actually left; returns how many received it. */
export async function sendLiveReminder(live: LiveRow, courseTitle: string, actor?: string, now = new Date()) {
  const lead = Math.max(0, Math.round((live.startsAt.getTime() - now.getTime()) / 60_000));
  const leadText =
    lead >= 1440
      ? `${Math.round(lead / 1440)} day${Math.round(lead / 1440) === 1 ? '' : 's'}`
      : lead >= 60
        ? `${Math.round(lead / 60)} hour${Math.round(lead / 60) === 1 ? '' : 's'}`
        : `${lead} min`;
  return notifyMany(await registeredUserIds(live.id), {
    category: 'live',
    title: `${live.title} starts in ${leadText}`,
    summary: `${courseTitle} · ${when(live.startsAt)} IST · ${live.durationMin} min.`,
    important: lead <= 60,
    actor,
    facts: [
      { label: 'Starts', value: `${when(live.startsAt)} IST` },
      { label: 'Length', value: `${live.durationMin} min` },
    ],
    action: { label: lead <= 15 ? 'Join the class' : 'Open the class', to: `/live/${live.id}` },
  });
}

/**
 * Sends the scheduled reminder whose moment has come (start − offset ≤ now < start) and has not been sent yet. When
 * several are due at once — a class scheduled at short notice, or moved — only one goes out, and all of them count as
 * sent: nobody gets "in 1 day" and "in 1 hour" together. Safe to call repeatedly.
 */
export async function sendDueReminders(now = new Date()): Promise<number> {
  const upcoming = await db.liveClass.findMany({ where: { cancelled: false, startsAt: { gt: now } }, include: { course: { select: { title: true } } } });
  let sent = 0;
  for (const live of upcoming) {
    const offsets = readJson<number[]>(live.remindersJson, []);
    const done = new Set(readJson<number[]>(live.remindersSentJson, []));
    const due = offsets.filter((m) => !done.has(m) && live.startsAt.getTime() - m * 60_000 <= now.getTime());
    if (!due.length) continue;
    // Marked sent first, so two schedulers (or a retry) never send it twice.
    for (const m of due) done.add(m);
    await db.liveClass.update({ where: { id: live.id }, data: { remindersSentJson: writeJson([...done]) } });
    await sendLiveReminder(live, live.course.title, undefined, now);
    sent++;
  }
  return sent;
}

export { notify };
