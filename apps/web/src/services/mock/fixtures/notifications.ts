import type { AppNotification, NotificationCategory, NotificationSettings } from '@syniastrolms/domain';
import { NOTIFICATION_CATEGORIES, needsReview, reviewOverdue } from '@syniastrolms/domain';
import { statsFor } from '../quizzes';
import { DAY_MS, toIST } from '../random';
import { courseAssignments, submissions } from './assignments';
import { courses } from './catalog';
import { issuedCertificates } from './certificates';
import { DEMO_NOW, personas } from './learner';
import { quizzes } from './quizzes';

const NOW = new Date(DEMO_NOW).getTime();
const minutesAgo = (m: number) => toIST(new Date(NOW - m * 60_000));
/** A time on an earlier day, IST. */
const daysAgo = (d: number, time: string) => `${toIST(new Date(NOW - d * DAY_MS)).slice(0, 10)}T${time}:00+05:30`;

type Draft = Omit<AppNotification, 'id' | 'recipientId'> & { read?: boolean };

function build(recipientId: string, prefix: string, drafts: Draft[]): AppNotification[] {
  return drafts.map(({ read, ...n }, i) => ({
    ...n,
    id: `${prefix}-${String(i + 1).padStart(2, '0')}`,
    recipientId,
    readAt: read ? toIST(new Date(new Date(n.createdAt).getTime() + 20 * 60_000)) : undefined,
  }));
}

const quizByTitle = (title: string) => quizzes.find((q) => q.title === title);

function learner(): Draft[] {
  return [
    {
      category: 'live',
      title: 'Live now: Reading dignities in real charts',
      summary: 'Dr. Meenakshi Iyer has started the class — 46 learners are in the room.',
      body: [
        'The class started at 6:30 PM and runs for an hour. You registered for it, so you can join at any point.',
        'Bring your own chart if you’d like it used as an example — Dr. Meenakshi takes two volunteers in the second half.',
      ],
      createdAt: minutesAgo(22),
      important: true,
      actor: 'Dr. Meenakshi Iyer',
      facts: [
        { label: 'Course', value: 'Foundations of Vedic Astrology' },
        { label: 'Time', value: '6:30 – 7:30 PM IST' },
      ],
      action: { label: 'Join the class', to: '/live/lc-live' },
    },
    {
      category: 'live',
      title: 'Starting at 7:00 PM: Doubt-clearing: the Nine Planets',
      summary: 'Your class with Pooja Deshpande starts in an hour. The room opens 15 minutes before.',
      body: [
        'Pooja will take questions on the Navagraha — significations, dignities and friendships. Post a question in advance and it goes to the top of the list.',
      ],
      createdAt: minutesAgo(52),
      actor: 'Pooja Deshpande',
      facts: [
        { label: 'Starts', value: 'Today, 7:00 PM IST' },
        { label: 'Length', value: '45 min' },
      ],
      action: { label: 'Open the class', to: '/live/lc-soon' },
    },
    {
      category: 'assignment',
      title: 'Feedback on Kendra houses: a first essay',
      summary: 'Scored 11 out of 20 — below the pass mark of 14. You can revise and resubmit.',
      body: [
        'Your reviewer liked the chart you chose and the way you described the fourth house. The essay loses marks on the tenth house, where career and public standing are mixed up with the eleventh house’s gains.',
        'Read the rubric comments, then resubmit — your higher score counts.',
      ],
      createdAt: minutesAgo(135),
      actor: 'Pooja Deshpande',
      facts: [
        { label: 'Score', value: '11 / 20' },
        { label: 'Pass mark', value: '14' },
        { label: 'Course', value: 'Foundations of Vedic Astrology' },
      ],
      action: { label: 'Read the feedback', to: '/assignments/a-kendra' },
    },
    {
      category: 'course',
      title: 'New worked chart in Chapter 3',
      summary: 'Dr. Meenakshi added a worked chart to “The Twelve Houses” — lordship in an Aries lagna.',
      body: [
        'A new reading follows Aries lagna house by house, with each lord and where it sits. It prepares you for the House lordship worksheet due on 26 September.',
        'It’s about 12 minutes and doesn’t change your progress in the chapter.',
      ],
      createdAt: minutesAgo(230),
      actor: 'Dr. Meenakshi Iyer',
      action: { label: 'Continue Chapter 3', to: '/learn/foundations-vedic/lessons/m3-l5' },
    },
    {
      category: 'assignment',
      title: 'Planetary friendships table handed in',
      summary: 'We’ve received your submission. Feedback usually arrives within two days.',
      body: ['Your submission is in the review queue for Foundations of Vedic Astrology. You’ll get a notification when a reviewer returns it.'],
      createdAt: daysAgo(0, '11:21'),
      read: true,
      facts: [
        { label: 'Handed in', value: 'Today, 11:20 AM' },
        { label: 'Due', value: 'Fri, 18 Sep, 11:59 PM' },
      ],
      action: { label: 'View submission', to: '/assignments/a-submitted' },
    },
    {
      category: 'assignment',
      title: 'Overdue: Nakshatra observation journal',
      summary: 'It was due on Sunday. Late work is still accepted, with a penalty on the score.',
      body: [
        'Note the Moon’s nakshatra each evening for a week and hand in your journal. The course accepts late submissions, so it still counts towards your certificate.',
      ],
      createdAt: daysAgo(1, '09:00'),
      important: true,
      facts: [
        { label: 'Was due', value: 'Sun, 13 Sep, 11:59 PM' },
        { label: 'Late work', value: 'Accepted with a penalty' },
      ],
      action: { label: 'Start the journal', to: '/assignments/a-journal' },
    },
    {
      category: 'quiz',
      title: 'Retake opens Thursday: Nakshatra lords: timed drill',
      summary: 'You scored 58%. Your second attempt opens on Thursday at 9:00 AM.',
      body: ['The pass mark is 70%. Before the retake, revise the lords of the nakshatras in groups of nine — each group repeats the same order of grahas.'],
      createdAt: daysAgo(1, '20:15'),
      read: true,
      facts: [
        { label: 'Last score', value: '58%' },
        { label: 'Pass mark', value: '70%' },
        { label: 'Retake opens', value: 'Thu, 17 Sep, 9:00 AM' },
      ],
      action: { label: 'See your assessments', to: '/assessments' },
    },
    {
      category: 'certificate',
      title: 'Your Panchang Essentials certificate is ready',
      summary: 'You finished the course with 81% on the final assessment. Claim the certificate to add it to your profile.',
      body: ['Once you claim it, the certificate gets a credential ID that anyone can check on the verification page. You can download it or share a link.'],
      createdAt: daysAgo(3, '10:05'),
      important: true,
      facts: [
        { label: 'Course', value: 'Panchang Essentials' },
        { label: 'Final score', value: '81%' },
      ],
      action: { label: 'Claim the certificate', to: '/certificates' },
    },
    {
      category: 'live',
      title: 'Recording ready: The Twelve Houses: kendra and trikona',
      summary: 'The 84-minute recording is available until 10 October.',
      body: ['If you missed part of Thursday’s class, the recording has chapter markers for each house and the questions at the end.'],
      createdAt: daysAgo(4, '22:10'),
      read: true,
      action: { label: 'Watch the recording', to: '/live/lc-ended' },
    },
    {
      category: 'system',
      title: 'New sign-in from Chrome on Windows',
      summary: 'Someone signed in to your account from Bengaluru. If it was you, there’s nothing to do.',
      body: [
        'Signed in on Friday at 8:42 PM from Chrome on Windows, near Bengaluru.',
        'If this wasn’t you, change your password straight away and sign out of other devices.',
      ],
      createdAt: daysAgo(4, '20:43'),
      read: true,
      facts: [
        { label: 'Device', value: 'Chrome on Windows' },
        { label: 'Location', value: 'Bengaluru, India' },
      ],
    },
    {
      category: 'assignment',
      title: 'Feedback on Identify exalted and debilitated planets',
      summary: 'Scored 18 out of 20 — well above the pass mark.',
      body: [
        'Every chart had the dignities right. The one note: Mercury in Virgo is both exalted and in its own sign — say which you’re using when you read it.',
      ],
      createdAt: daysAgo(6, '15:30'),
      read: true,
      actor: 'Dr. Meenakshi Iyer',
      facts: [
        { label: 'Score', value: '18 / 20' },
        { label: 'Pass mark', value: '14' },
      ],
      action: { label: 'Read the feedback', to: '/assignments/a-dignities' },
    },
    {
      category: 'certificate',
      title: 'Your certificate was verified',
      summary: 'Someone checked your Introduction to Jyotish certificate on the verification page.',
      body: ['Verification shows your name, the course and the date it was issued — nothing else from your account.', 'It has now been checked 3 times.'],
      createdAt: daysAgo(8, '12:14'),
      read: true,
      facts: [{ label: 'Credential ID', value: 'SA-JY-2026-04817' }],
      action: { label: 'View the certificate', to: '/certificates/cert-en-p1' },
      secondaryAction: { label: 'See what they saw', to: '/verify/SA-JY-2026-04817' },
    },
    {
      category: 'system',
      title: 'Planned maintenance on Sunday, 20 September',
      summary: 'ZuviloAI will be unavailable from 2:00 to 3:00 AM IST.',
      body: ['Lessons, quizzes and the live room are paused for the hour. Anything you’re writing is saved before it starts.'],
      createdAt: daysAgo(9, '18:00'),
      read: true,
    },
    {
      category: 'quiz',
      title: 'Passed: Chapter 2 check: The Nine Planets',
      summary: 'You scored 84% on your first attempt.',
      body: ['You got every question on planetary friendships right. Review the two questions on combustion before Chapter 3.'],
      createdAt: daysAgo(11, '19:40'),
      read: true,
      facts: [
        { label: 'Score', value: '84%' },
        { label: 'Pass mark', value: '70%' },
      ],
      action: { label: 'See your assessments', to: '/assessments' },
    },
    {
      category: 'enrollment',
      title: 'Your access to Introduction to Jyotish continues',
      summary: 'You finished the course, and its lessons stay open to you for revision.',
      body: ['Finished courses stay in My learning under Completed. Recordings of live classes follow their own 30-day window.'],
      createdAt: daysAgo(15, '09:00'),
      read: true,
      action: { label: 'Go to My learning', to: '/my-learning/completed' },
    },
    {
      category: 'course',
      title: 'Chapter 3 is open: The Twelve Houses',
      summary: 'You finished Chapter 2, so the next chapter is unlocked.',
      body: [
        'Chapter 3 has eight lessons, the Kendra houses essay and the House lordship worksheet. The chapter assessment unlocks when you finish the lessons.',
      ],
      createdAt: daysAgo(17, '21:05'),
      read: true,
      action: { label: 'Open the course', to: '/learn/foundations-vedic' },
    },
  ];
}

function instructor(): Draft[] {
  const now = new Date(DEMO_NOW);
  const mine = new Set(courses.filter((c) => c.instructorIds.includes('meenakshi')).map((c) => c.id));
  const assignmentIds = new Set(courseAssignments.filter((a) => mine.has(a.courseId)).map((a) => a.id));
  const queue = submissions().filter((s) => assignmentIds.has(s.assignmentId) && needsReview(s));
  const overdue = queue.filter((s) => reviewOverdue(s, now)).length;
  const finalQuiz = quizByTitle('Chapter 3 assessment: The Twelve Houses');
  const stats = finalQuiz && statsFor(finalQuiz);
  return [
    {
      category: 'assignment',
      title: `${queue.length} submissions waiting for review`,
      summary: `${overdue} have waited more than 48 hours. The oldest are at the top of your queue.`,
      body: ['Learners are told feedback arrives within two days. Reviews past that window show as overdue on your dashboard and to the academy admin.'],
      createdAt: minutesAgo(12),
      important: overdue > 0,
      facts: [
        { label: 'Waiting', value: String(queue.length) },
        { label: 'Past 48 hours', value: String(overdue) },
      ],
      action: { label: 'Open the review queue', to: '/teach/assignments/review' },
    },
    {
      category: 'live',
      title: 'Your class starts in 15 minutes',
      summary: 'Reading dignities in real charts — 52 learners registered. The room is open.',
      body: ['Your slides and the two volunteer charts are in the room already. Recording starts automatically when you go live.'],
      createdAt: minutesAgo(37),
      read: true,
      action: { label: 'Open the class', to: '/teach/live/lc-live' },
    },
    {
      category: 'assignment',
      title: 'New submission: Kendra houses: a first essay',
      summary: 'Shankar Iyengar handed in their essay.',
      body: ['This is their first attempt. The rubric has four criteria and the pass mark is 14 of 20.'],
      createdAt: daysAgo(0, '13:53'),
      actor: 'Shankar Iyengar',
      action: { label: 'Review it', to: '/teach/assignments/a-kendra/submissions/sub-a-kendra-s-1931' },
    },
    {
      category: 'assignment',
      title: 'Review overdue: Sidereal and tropical: a short reflection',
      summary: 'Ananya Rao’s reflection has been in review for three days.',
      body: ['You opened it on Sunday but haven’t returned it. If someone else should take it, reassign it from the submission page.'],
      createdAt: daysAgo(0, '09:00'),
      important: true,
      facts: [
        { label: 'Handed in', value: 'Sat, 12 Sep, 9:14 PM' },
        { label: 'Learner', value: 'Ananya Rao' },
      ],
      action: { label: 'Finish the review', to: '/teach/assignments/a-sidereal/submissions/sub-a-sidereal-u-ananya' },
    },
    {
      category: 'enrollment',
      title: 'New learners in Foundations of Vedic Astrology',
      summary: 'Kavya Reddy and 11 others enrolled today.',
      body: ['New learners start at Chapter 1. The welcome email already points them to Thursday’s class.'],
      createdAt: daysAgo(0, '18:41'),
      action: { label: 'See your learners', to: '/teach/students?course=foundations-vedic' },
    },
    {
      category: 'course',
      title: 'Pooja Deshpande edited Chapter 5',
      summary: 'Two lessons in “Nakshatras” were reordered and one reading was updated.',
      body: ['Learners already past these lessons keep their progress. The chapter’s total length is now 2h 10m.'],
      createdAt: daysAgo(1, '17:20'),
      read: true,
      actor: 'Pooja Deshpande',
      action: { label: 'View the curriculum', to: '/teach/courses/foundations-vedic/curriculum' },
    },
    {
      category: 'quiz',
      title: 'Results so far: Chapter 3 assessment: The Twelve Houses',
      summary: stats
        ? `${stats.attempts.toLocaleString('en-IN')} attempts, ${stats.passRate}% passing, average score ${stats.avgScore}%.`
        : 'See how learners are doing on the chapter assessment.',
      body: ['The question learners miss most is on the eighth house — see the question breakdown for the wrong answer they choose.'],
      createdAt: daysAgo(2, '08:00'),
      read: true,
      facts: stats
        ? [
            { label: 'Attempts', value: stats.attempts.toLocaleString('en-IN') },
            { label: 'Pass rate', value: `${stats.passRate}%` },
          ]
        : undefined,
      action: finalQuiz ? { label: 'Open results', to: `/teach/quizzes/${finalQuiz.id}/results` } : undefined,
    },
    {
      category: 'live',
      title: 'Nakshatras in practice is filling up',
      summary: '74 of 80 places are taken for Thursday’s class with Pooja Deshpande.',
      body: ['When it’s full, learners join a waiting list. You can raise the capacity from the class page.'],
      createdAt: daysAgo(2, '12:30'),
      read: true,
      action: { label: 'Open the class', to: '/teach/live/lc-upcoming' },
    },
    {
      category: 'certificate',
      title: 'Certificates earned in Introduction to Jyotish',
      summary: 'Four learners finished the course this week and are waiting for their certificates.',
      body: ['The academy admin issues certificates after a quick check. Nothing is needed from you.'],
      createdAt: daysAgo(3, '10:00'),
      read: true,
    },
    {
      category: 'system',
      title: 'Planned maintenance on Sunday, 20 September',
      summary: 'ZuviloAI will be unavailable from 2:00 to 3:00 AM IST. No classes are scheduled then.',
      body: ['The live room, course editor and review queue are paused for the hour. Drafts are saved before it starts.'],
      createdAt: daysAgo(9, '18:00'),
      read: true,
    },
    {
      category: 'course',
      title: 'Choosing a Muhurta: chapter 3 announcement published',
      summary: 'Kavita Menon published your announcement to 64 learners.',
      body: ['It went out by email and in the app with the link to the Elections in practice lessons.'],
      createdAt: daysAgo(5, '10:02'),
      read: true,
      actor: 'Kavita Menon',
      action: { label: 'Open the course', to: '/teach/courses/muhurta' },
    },
  ];
}

function admin(): Draft[] {
  const now = new Date(DEMO_NOW);
  const pending = issuedCertificates().filter((c) => c.status === 'pending');
  const dashaIds = new Set(courseAssignments.filter((a) => a.courseId === 'dasha').map((a) => a.id));
  const dashaOverdue = submissions().filter((s) => dashaIds.has(s.assignmentId) && reviewOverdue(s, now)).length;
  const muhurtaFinal = quizByTitle('Final assessment: Muhurta');
  const muhurtaStats = muhurtaFinal && statsFor(muhurtaFinal);
  return [
    {
      category: 'enrollment',
      title: 'Kavya Reddy enrolled in Foundations of Vedic Astrology',
      summary: 'Self-enrolled and paid ₹18,500. That’s 12 new enrolments today.',
      body: ['Kavya joins the current intake and starts at Chapter 1. The welcome email has gone out.'],
      createdAt: minutesAgo(12),
      actor: 'Kavya Reddy',
      facts: [
        { label: 'Course', value: 'Foundations of Vedic Astrology' },
        { label: 'Source', value: 'Self-enrolled' },
      ],
      action: { label: 'Find the learner', to: '/admin/students?q=Kavya%20Reddy' },
    },
    {
      category: 'certificate',
      title: `${pending.length} certificates are ready to issue`,
      summary: 'Learners who finished in the last ten days are waiting for their certificates.',
      body: ['Each one meets its course’s requirements. Review a few, then issue them — learners are notified straight away.'],
      createdAt: minutesAgo(48),
      important: true,
      facts: [{ label: 'Ready to issue', value: String(pending.length) }],
      action: { label: 'Review certificates', to: '/admin/certificates?status=pending' },
    },
    {
      category: 'assignment',
      title: 'Review backlog on Reading the Dasha System',
      summary: `${dashaOverdue} submissions have waited more than 48 hours for Acharya Vinod Shastri.`,
      body: ['The course’s other reviewers have room this week. Ask Rohan Kulkarni to take some, or remind Acharya Vinod.'],
      createdAt: daysAgo(0, '09:30'),
      important: true,
      facts: [{ label: 'Past 48 hours', value: String(dashaOverdue) }],
      action: { label: 'Open the review queue', to: '/admin/assignments/review?course=dasha' },
    },
    {
      category: 'live',
      title: 'Cancelled: Open Q&A: Vimshottari timing',
      summary: 'Acharya Vinod Shastri cancelled tomorrow’s class. Registered learners have been told.',
      body: ['The reason given: the questions will be answered in Wednesday’s Antardasha timing workshop instead.'],
      createdAt: daysAgo(0, '15:12'),
      actor: 'Acharya Vinod Shastri',
      action: { label: 'Open the class', to: '/admin/live/lc-cancelled' },
    },
    {
      category: 'course',
      title: 'Medical Astrology is ready for review',
      summary: 'Dr. Nandini Varma asked for the draft course to be reviewed before launch.',
      body: ['The course has one chapter so far. Check the outcomes, pricing and certificate before it’s published.'],
      createdAt: daysAgo(1, '16:45'),
      actor: 'Dr. Nandini Varma',
      action: { label: 'Open the course', to: '/admin/courses/medical' },
    },
    {
      category: 'enrollment',
      title: 'Learners at risk in Foundations of Vedic Astrology',
      summary: 'Some learners haven’t opened a lesson in two weeks.',
      body: ['A short message from the instructor usually brings about a third of them back. Filter the list to at-risk learners to send one.'],
      createdAt: daysAgo(1, '08:00'),
      read: true,
      action: { label: 'See learners at risk', to: '/admin/students?status=at-risk&course=foundations-vedic' },
    },
    {
      category: 'system',
      title: 'Media storage is 62% full',
      summary: '148 GB of 240 GB is used. Recordings are the largest share.',
      body: ['Recordings past their 30-day window can be archived. At the current rate, storage reaches 80% in about three months.'],
      createdAt: daysAgo(1, '07:00'),
      read: true,
      facts: [
        { label: 'Used', value: '148 GB' },
        { label: 'Available', value: '240 GB' },
      ],
    },
    {
      category: 'live',
      title: 'Chara dasha case clinic is filling up',
      summary: '41 of 60 places are taken for Friday’s class.',
      body: ['Registrations are coming in faster than for the last clinic. Consider raising the capacity or adding a second session.'],
      createdAt: daysAgo(2, '11:10'),
      read: true,
      action: { label: 'Open the class', to: '/admin/live/lc-jaimini-clinic' },
    },
    {
      category: 'quiz',
      title: 'Closed: Final assessment: Muhurta',
      summary: muhurtaStats
        ? `${muhurtaStats.attempts} attempts in total, ${muhurtaStats.passRate}% passing.`
        : 'The final assessment for the August cohort has closed.',
      body: ['Learners who didn’t pass can take it again with the October cohort. Certificates for those who passed are in the ready-to-issue list.'],
      createdAt: daysAgo(2, '00:00'),
      read: true,
      action: muhurtaFinal ? { label: 'Open results', to: `/admin/quizzes/${muhurtaFinal.id}/results` } : undefined,
    },
    {
      category: 'system',
      title: 'Kiran Joshi hasn’t accepted the instructor invitation',
      summary: 'The invitation was sent 9 days ago. It expires in 5 days.',
      body: ['You can resend the invitation from the instructor profile.'],
      createdAt: daysAgo(3, '09:00'),
      read: true,
      action: { label: 'Open the profile', to: '/admin/instructors/kiran' },
    },
    {
      category: 'certificate',
      title: 'A revoked certificate was checked',
      summary: 'Someone looked up a revoked credential on the verification page.',
      body: ['The page showed it as revoked, with the reason you recorded. No action is needed unless you expect it to be valid.'],
      createdAt: daysAgo(4, '14:22'),
      read: true,
      action: { label: 'See revoked certificates', to: '/admin/certificates?status=revoked' },
    },
    {
      category: 'course',
      title: 'Reading the Dasha System was updated',
      summary: 'Acharya Vinod Shastri added two lessons to Chapter 3.',
      body: ['Both are published. Learners past Chapter 3 see them marked as new without losing progress.'],
      createdAt: daysAgo(5, '19:30'),
      read: true,
      actor: 'Acharya Vinod Shastri',
      action: { label: 'Open the course', to: '/admin/courses/dasha' },
    },
    {
      category: 'system',
      title: 'Planned maintenance on Sunday, 20 September',
      summary: 'ZuviloAI will be unavailable from 2:00 to 3:00 AM IST.',
      body: ['Learners and instructors see a banner from Saturday evening. No live classes are scheduled during the window.'],
      createdAt: daysAgo(9, '18:00'),
      read: true,
    },
    {
      category: 'enrollment',
      title: 'Scholarship enrolments approved',
      summary: 'Five scholarship learners were enrolled in Panchang Essentials.',
      body: ['They have 12 months of access, the same as paid enrolments.'],
      createdAt: daysAgo(12, '11:00'),
      read: true,
      action: { label: 'See enrolments', to: '/admin/students?course=panchang' },
    },
  ];
}

let store: AppNotification[] | undefined;
/** Every notification, newest first. Built on first use because some counts come from generated records. */
export function notificationStore() {
  if (!store) {
    store = [
      ...build(personas.student.id, 'ntf-l', learner()),
      ...build(personas.instructor.id, 'ntf-i', instructor()),
      ...build(personas.admin.id, 'ntf-a', admin()),
    ].sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }
  return store;
}

const on = (app: boolean, email: boolean, sms: boolean) => ({ app, email, sms });

const DEFAULTS: Record<string, Partial<Record<NotificationCategory, ReturnType<typeof on>>>> = {
  [personas.student.id]: {
    live: on(true, true, true),
    assignment: on(true, true, false),
    quiz: on(true, false, false),
    course: on(true, false, false),
    certificate: on(true, true, false),
    enrollment: on(true, true, false),
  },
  [personas.instructor.id]: {
    assignment: on(true, true, false),
    live: on(true, true, true),
    quiz: on(true, false, false),
    course: on(true, true, false),
    enrollment: on(true, false, false),
    certificate: on(false, false, false),
  },
  [personas.admin.id]: {
    certificate: on(true, true, false),
    assignment: on(true, true, false),
    enrollment: on(true, false, false),
    course: on(true, true, false),
    live: on(true, false, false),
    quiz: on(true, false, false),
  },
};

const settings = new Map<string, NotificationSettings>();
export function settingsFor(recipientId: string): NotificationSettings {
  let s = settings.get(recipientId);
  if (!s) {
    const defaults = DEFAULTS[recipientId] ?? {};
    s = {
      categories: NOTIFICATION_CATEGORIES.map((category) => ({
        category,
        channels: category === 'system' ? on(true, true, false) : (defaults[category] ?? on(true, false, false)),
      })),
      emailDigest: recipientId === personas.admin.id ? 'daily' : 'instant',
      quietHours: { enabled: true, from: '22:00', to: '07:00' },
    };
    settings.set(recipientId, s);
  }
  return s;
}

export const saveSettingsFor = (recipientId: string, next: NotificationSettings) => settings.set(recipientId, next);

export const SMS_NUMBERS: Record<string, string> = {
  [personas.student.id]: '+91 98••• ••210',
  [personas.instructor.id]: '+91 94••• ••318',
  [personas.admin.id]: '+91 99••• ••047',
};
