import { useLocation } from 'react-router-dom';
import { BookOpenText, Certificate, ClipboardText, Exam, ShieldCheck, UserPlus, VideoCamera, type Icon } from '@phosphor-icons/react';
import type { AppNotification, NotificationCategory, NotificationChannel, Role } from '@syniastrolms/domain';
import type { Tone } from '@/design/tokens';
import { formatDay, formatTime } from '@/lib/format';
import { IconChip } from '@/components/ui/Badge/Badge';

export const CATEGORY_META: Record<NotificationCategory, { label: string; plural: string; icon: Icon; tone: Tone }> = {
  course: { label: 'Course update', plural: 'Course updates', icon: BookOpenText, tone: 'accent' },
  assignment: { label: 'Assignment', plural: 'Assignments', icon: ClipboardText, tone: 'warn' },
  quiz: { label: 'Quiz', plural: 'Quizzes', icon: Exam, tone: 'info' },
  live: { label: 'Live class', plural: 'Live classes', icon: VideoCamera, tone: 'danger' },
  certificate: { label: 'Certificate', plural: 'Certificates', icon: Certificate, tone: 'accent' },
  enrollment: { label: 'Enrolment', plural: 'Enrolments', icon: UserPlus, tone: 'info' },
  system: { label: 'Account and system', plural: 'Account and system', icon: ShieldCheck, tone: 'neutral' },
};

export const CHANNEL_LABEL: Record<NotificationChannel, string> = { app: 'In the app', email: 'Email', sms: 'Text message' };
/** For sentences: “You get quizzes in the app and by email.” */
export const CHANNEL_PHRASE: Record<NotificationChannel, string> = { app: 'in the app', email: 'by email', sms: 'by text message' };

/** What each kind covers, in the words of the person receiving it. */
export const CATEGORY_DESCRIPTION: Record<Role, Record<NotificationCategory, string>> = {
  student: {
    course: 'New lessons, chapters that open for you and announcements from your instructors.',
    live: 'Reminders before classes you’ve registered for, classes going live, cancellations and recordings.',
    assignment: 'Deadlines coming up, work that’s overdue and feedback on what you hand in.',
    quiz: 'Your results, retakes opening and quizzes about to close.',
    certificate: 'Certificates ready to claim and when someone verifies yours.',
    enrollment: 'Enrolment confirmations, access ending and scholarship decisions.',
    system: 'Sign-ins from new devices, password changes and planned maintenance.',
  },
  instructor: {
    assignment: 'New submissions in your courses and reviews waiting more than 48 hours.',
    quiz: 'Results on your quizzes and learners who use their last attempt.',
    live: 'Reminders before your classes, registrations filling up and cancellations.',
    course: 'Edits by co-instructors and announcements published for you.',
    enrollment: 'New learners in your courses, sent as one note a day.',
    certificate: 'Learners who earn a certificate in your courses.',
    system: 'Sign-ins from new devices, password changes and planned maintenance.',
  },
  admin: {
    enrollment: 'New enrolments, scholarships and learners at risk of dropping off.',
    course: 'Courses sent for review, published, updated or archived.',
    certificate: 'Certificates ready to issue, revocations and checks on revoked credentials.',
    assignment: 'Review backlogs past 48 hours, by course.',
    quiz: 'Quizzes closing and their pass rates.',
    live: 'Cancellations and classes filling up.',
    system: 'Storage, instructor invitations, maintenance and security.',
  },
  // Super Admin is offered no preference groups yet (see CATEGORY_GROUPS), so none of these is ever
  // rendered. They stay empty rather than borrowing another role's words.
  superadmin: { course: '', live: '', assignment: '', quiz: '', certificate: '', enrollment: '', system: '' },
};

/** Preference groups, in the order each role cares about. */
export const CATEGORY_GROUPS: Record<Role, { title: string; categories: NotificationCategory[] }[]> = {
  student: [
    { title: 'Learning', categories: ['live', 'assignment', 'quiz', 'course'] },
    { title: 'Progress', categories: ['certificate', 'enrollment'] },
    { title: 'Account', categories: ['system'] },
  ],
  instructor: [
    { title: 'Teaching', categories: ['assignment', 'live', 'quiz'] },
    { title: 'Your courses', categories: ['course', 'enrollment', 'certificate'] },
    { title: 'Account', categories: ['system'] },
  ],
  admin: [
    { title: 'Learning', categories: ['enrollment', 'certificate', 'course'] },
    { title: 'Teaching', categories: ['assignment', 'live', 'quiz'] },
    { title: 'System', categories: ['system'] },
  ],
  // No Super Admin notifications are designed yet, so the preferences page offers it no groups.
  superadmin: [],
};

/** The notification centre for the workspace in the URL. */
export function useNotificationBase() {
  const { pathname } = useLocation();
  return pathname.startsWith('/admin/') ? '/admin/notifications' : pathname.startsWith('/teach/') ? '/teach/notifications' : '/notifications';
}

export function CategoryIcon({ category, size = 'md' }: { category: NotificationCategory; size?: 'md' | 'lg' }) {
  const meta = CATEGORY_META[category];
  const Glyph = meta.icon;
  return (
    <IconChip tone={meta.tone} size={size}>
      <Glyph size={size === 'lg' ? 20 : 17} weight="duotone" />
    </IconChip>
  );
}

const DAY = 86_400_000;
const istDay = (ms: number) => new Date(ms + 330 * 60_000).toISOString().slice(0, 10);

/** "22 min ago", "3 hours ago", "Yesterday, 9:00 AM", "Sat, 12 Sep, 10:05 AM" */
export function notificationTime(iso: string, now: Date) {
  const at = new Date(iso).getTime();
  const diff = now.getTime() - at;
  if (diff < 60_000) return 'Just now';
  if (diff < 60 * 60_000) return `${Math.round(diff / 60_000)} min ago`;
  if (istDay(at) === istDay(now.getTime())) {
    const hours = Math.round(diff / (60 * 60_000));
    return `${hours} ${hours === 1 ? 'hour' : 'hours'} ago`;
  }
  if (istDay(at) === istDay(now.getTime() - DAY)) return `Yesterday, ${formatTime(iso)}`;
  return `${formatDay(iso)}, ${formatTime(iso)}`;
}

/** Today, Yesterday, This week, Earlier — in IST, newest first. */
export function groupByRecency(rows: AppNotification[], now: Date) {
  const today = istDay(now.getTime());
  const yesterday = istDay(now.getTime() - DAY);
  const weekAgo = istDay(now.getTime() - 6 * DAY);
  const groups: { label: string; rows: AppNotification[] }[] = [];
  for (const n of rows) {
    const day = istDay(new Date(n.createdAt).getTime());
    const label = day === today ? 'Today' : day === yesterday ? 'Yesterday' : day >= weekAgo ? 'Earlier this week' : 'Earlier';
    const last = groups[groups.length - 1];
    if (last?.label === label) last.rows.push(n);
    else groups.push({ label, rows: [n] });
  }
  return groups;
}
