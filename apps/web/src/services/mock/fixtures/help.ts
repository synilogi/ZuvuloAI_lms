import type { HelpArticle, HelpCategory } from '@syniastrolms/domain';

export const helpCategories: HelpCategory[] = [
  { id: 'getting-started', name: 'Getting started', description: 'Your account, your workspace and finding your way around.', icon: 'rocket', order: 1 },
  { id: 'courses', name: 'Courses & lessons', description: 'How courses are put together, and how to build or study one.', icon: 'book', order: 2 },
  { id: 'assignments', name: 'Assignments & quizzes', description: 'Writing, taking, handing in and reviewing coursework.', icon: 'clipboard', order: 3 },
  { id: 'live', name: 'Live classes & calendar', description: 'Scheduling, joining and keeping track of what’s coming up.', icon: 'video', order: 4 },
  {
    id: 'certificates',
    name: 'Certificates & reports',
    description: 'Earning and issuing certificates, and reading the numbers.',
    icon: 'certificate',
    order: 5,
  },
  { id: 'settings', name: 'Academy settings', description: 'Defaults, branding and the instructors who teach here.', icon: 'gear', order: 6 },
];

export const helpArticles: HelpArticle[] = [
  // ── Getting started ──────────────────────────────────────────────────
  {
    id: 'welcome-to-syniastrolms',
    slug: 'welcome-to-syniastrolms',
    categoryId: 'getting-started',
    title: 'Welcome to ZuviloAI',
    summary: 'What the academy offers, and the three kinds of workspace you might sign in to.',
    audience: 'all',
    tags: ['orientation', 'account', 'workspace'],
    readMinutes: 3,
    updatedAt: '2026-09-01T10:00:00+05:30',
    popular: true,
    body:
      'ZuviloAI is a school for Vedic astrology, taught the way any serious subject should be: structured courses, live classes with real instructors, graded assignments, and a certificate once you can show what you’ve learned.\n\n' +
      '## Three workspaces, one academy\n\n' +
      'Everyone signs in to the same product, but what you see depends on your role.\n\n' +
      '- **Learner** — study courses, watch live classes, hand in coursework and collect certificates.\n' +
      '- **Instructor** — write courses, run live classes and grade what your learners submit.\n' +
      '- **Admin** — run the academy: every course, every learner, reports, and the settings behind all of it.\n\n' +
      '> If you’re trying this as a demo, use the account menu in the top-right corner to switch between the three — everything you see is realistic sample data, not a live academy.\n\n' +
      'Wherever you land, start with **[Find your way around the workspace](/help/article/find-your-way-around)** — the sidebar, the search bar and the notification bell work the same way in every workspace.',
  },
  {
    id: 'find-your-way-around',
    slug: 'find-your-way-around',
    categoryId: 'getting-started',
    title: 'Find your way around the workspace',
    summary: 'The sidebar, the breadcrumb trail, search, and the bell — the four things that never move.',
    audience: 'all',
    tags: ['navigation', 'sidebar', 'search'],
    readMinutes: 3,
    updatedAt: '2026-08-20T09:30:00+05:30',
    body:
      'Four things stay in the same place everywhere you go, in every workspace.\n\n' +
      '## The sidebar\n\n' +
      'On the left, grouped by what it’s for. Click the collapse arrow at the bottom (or press **Ctrl/⌘ + B**) to shrink it to icons when you want more room. On a phone it becomes a bottom bar with your four most-used destinations, plus **More** for everything else.\n\n' +
      '## The breadcrumb trail\n\n' +
      'Along the top, showing exactly where you are — Home › Courses › Foundations of Vedic Astrology, for example. Click any part of it to jump back.\n\n' +
      '## Search\n\n' +
      'The search bar (or **Ctrl/⌘ + K** from anywhere) opens the command menu: search for a course, a learner, a page, or run an action like “New course” without leaving the keyboard.\n\n' +
      '## The bell\n\n' +
      'Shows what needs your attention — a class about to go live, feedback on your work, a submission waiting for review. Open the full **Notifications** page for everything, or **Preferences** to decide what reaches you and how.',
  },
  {
    id: 'choose-your-workspace',
    slug: 'choose-your-workspace',
    categoryId: 'getting-started',
    title: 'Student, instructor or admin: choosing your workspace',
    summary: 'What each role can see and do, and how the same screens are shared between them.',
    audience: 'all',
    tags: ['roles', 'permissions', 'workspace'],
    readMinutes: 3,
    updatedAt: '2026-08-15T09:00:00+05:30',
    body:
      'A learning management system has to work for very different people at once. ZuviloAI keeps that simple by giving each role exactly the tools it needs.\n\n' +
      '1. **Learners** get a flat, short menu: Home, Explore, My learning, Live classes, Assignments, Assessments, Certificates. Nothing to manage — just study.\n' +
      '2. **Instructors** work in a teaching workspace scoped to the courses they’re assigned to: their courses, quizzes, the submissions waiting for review, their live classes and their learners.\n' +
      '3. **Admins** see the whole academy — every course and category, every instructor and learner, reports across all of it, and the settings that shape how the academy behaves.\n\n' +
      '> Course management screens are genuinely the same screens for instructors and admins — an instructor just sees their own courses, and an admin sees everyone’s. Nothing needs to be learned twice.\n\n' +
      'Most academies invite instructors rather than letting them sign up directly — see **[Invite and manage instructors](/help/article/manage-instructors)** if you’re setting one up.',
  },
  {
    id: 'keyboard-shortcuts-and-search',
    slug: 'keyboard-shortcuts-and-search',
    categoryId: 'getting-started',
    title: 'Search fast and use keyboard shortcuts',
    summary: 'The handful of shortcuts worth learning, and what the command menu can do.',
    audience: 'all',
    tags: ['shortcuts', 'search', 'productivity'],
    readMinutes: 2,
    updatedAt: '2026-07-28T09:00:00+05:30',
    body:
      'A short list, but each one saves a trip through the menus.\n\n' +
      '- **Ctrl/⌘ + K** — open the command menu. Type a course name, a learner, or an action like “schedule a live class”.\n' +
      '- **Ctrl/⌘ + B** — collapse or expand the sidebar.\n' +
      '- **Ctrl/⌘ + S** — save the form you’re editing, in Settings and most editors.\n' +
      '- **Esc** — close whatever’s open: a menu, a side panel, a dialog.\n' +
      '- **Arrow keys**, then **Page Up / Page Down** — move between days and months in the calendar.\n\n' +
      'The same list is always one click away: open **Help and shortcuts** from the toolbar icon next to the theme switch, or **Keyboard shortcuts** in the account menu.',
  },

  // ── Courses & lessons ─────────────────────────────────────────────────
  {
    id: 'how-courses-are-structured',
    slug: 'how-courses-are-structured',
    categoryId: 'courses',
    title: 'How a course is structured',
    summary: 'Level, category, chapters and lessons — the shape every course in the catalog shares.',
    audience: 'all',
    tags: ['courses', 'chapters', 'lessons', 'catalog'],
    readMinutes: 3,
    updatedAt: '2026-08-25T10:00:00+05:30',
    popular: true,
    body:
      'Every course in the catalog is built from the same pieces, however different the subject.\n\n' +
      '1. **Level** — Beginner through Master, so learners know what they’re ready for.\n' +
      '2. **Category** — where it sits in the catalog, like Predictive Techniques or Muhurta & Prashna.\n' +
      '3. **Chapters** — the course broken into stages, each with its own objective.\n' +
      '4. **Lessons** — video, reading, document, live session, practice, assignment or quiz. A chapter is usually a mix of several.\n\n' +
      '> A course can run **self-paced** (open whenever you like), as a **cohort** (a group moving through it together, with dates), or **hybrid** — self-paced lessons with live classes woven in.\n\n' +
      'A lesson counts as finished once you’ve watched most of a video, read a document, or passed its quiz — and a chapter’s quiz only unlocks once its other lessons are done, so a course builds in order.',
  },
  {
    id: 'build-a-course-learners-finish',
    slug: 'build-a-course-learners-finish',
    categoryId: 'courses',
    title: 'Build a course learners actually finish',
    summary: 'A short checklist for instructors, from the first chapter to the final assessment.',
    audience: 'instructor',
    tags: ['instructor', 'curriculum', 'completion'],
    readMinutes: 4,
    updatedAt: '2026-08-10T09:30:00+05:30',
    body:
      'Most courses lose learners in the first chapter, not the last. A few habits keep people moving.\n\n' +
      '- **Open with a short win.** A 5–10 minute first lesson that’s marked as a free preview gives a visitor something to finish before they even enrol.\n' +
      '- **One objective per chapter.** Write it in a sentence — it shows on the chapter and tells a learner exactly what they’ll be able to do next.\n' +
      '- **Check as you go.** A short quiz at the end of a chapter catches confusion early, rather than saving it all for one long final assessment.\n' +
      '- **Mix the format.** A chapter that’s all video reads as a lecture; add a reading, a practice lesson, or a live session and it reads as a course.\n\n' +
      '> Your curriculum autosaves as you edit it, and a chapter’s length updates itself from its lessons — you never have to keep the two in sync by hand.\n\n' +
      'When it’s ready, send it for review from the course editor rather than publishing directly — see **[Publishing, sending for review and archiving a course](/help/article/publish-review-archive)**.',
  },
  {
    id: 'publish-review-archive',
    slug: 'publish-review-archive',
    categoryId: 'courses',
    title: 'Publishing, sending for review and archiving a course',
    summary: 'The path a course takes from draft to the catalog, and how to retire one gracefully.',
    audience: 'admin',
    tags: ['admin', 'publishing', 'catalog'],
    readMinutes: 3,
    updatedAt: '2026-08-05T09:00:00+05:30',
    body:
      'A course moves through three states: **draft**, **published**, and **archived**.\n\n' +
      '1. An instructor builds the course as a draft — nothing is visible to learners yet.\n' +
      '2. If your academy requires review (the default in Settings › Courses), it’s sent to an admin, who checks pricing, outcomes and the curriculum before publishing it to the catalog.\n' +
      '3. A published course can still be edited — updates go out immediately, and learners already enrolled keep their progress.\n' +
      '4. When a course has run its course, archive it rather than deleting it: it disappears from the catalog, but everyone who finished it keeps their certificate and their record.\n\n' +
      '> Courses that sit as an untouched draft for a long time show up on the admin dashboard under **Needs attention**, so nothing is quietly forgotten.\n\n' +
      'Category and instructor changes, visibility, and pricing all live on the course’s own editor — there’s no separate approval step beyond the one review.',
  },
  {
    id: 'track-your-progress',
    slug: 'track-your-progress',
    categoryId: 'courses',
    title: 'Track your progress through a course',
    summary: 'What the progress bar counts, how chapters unlock, and where to pick up where you left off.',
    audience: 'student',
    tags: ['student', 'progress', 'my-learning'],
    readMinutes: 2,
    updatedAt: '2026-07-30T09:00:00+05:30',
    body:
      'Your progress on a course is weighted by how long each lesson takes, not just how many you’ve ticked off — a 40-minute lesson moves the bar further than a 4-minute one.\n\n' +
      '- **Resume lesson**, at the top of your sidebar, always opens exactly where you stopped.\n' +
      '- A chapter’s quiz unlocks once its other lessons are finished — so if something’s locked, that’s why.\n' +
      '- **My learning** splits everything into **In progress**, **Completed** and **Saved** — courses you’ve bookmarked from **Explore** but haven’t started yet.\n' +
      '- Notes you take on a lesson, and any bookmark you leave, are saved automatically as you go.\n\n' +
      '> Finished every chapter, quiz and assignment a course requires? Check **Certificates** — it’s probably ready to claim.',
  },

  // ── Assignments & quizzes ────────────────────────────────────────────
  {
    id: 'write-a-quiz-that-works',
    slug: 'write-a-quiz-that-works',
    categoryId: 'assignments',
    title: 'Write a quiz learners can pass on the first try',
    summary: 'Question types, pass marks and attempts — set so a quiz checks understanding, not luck.',
    audience: 'instructor',
    tags: ['instructor', 'quizzes', 'assessment'],
    readMinutes: 3,
    updatedAt: '2026-07-22T09:00:00+05:30',
    body:
      'A quiz has one job: tell a learner, quickly, whether they’ve understood the chapter.\n\n' +
      '- **Question types** — single choice, multiple choice, true/false and short answer. Mix them; a quiz of nothing but true/false rewards guessing.\n' +
      '- **Pass mark** — set as a percentage of the total points, so it stays correct even after you add or remove a question.\n' +
      '- **Attempts** — two is the usual default. The higher of the two scores counts, so a nervous first attempt doesn’t follow a learner around.\n' +
      '- **Shuffle** — turn on shuffled options (and questions, for a bigger bank) so the quiz doesn’t become memorised order rather than memorised content.\n\n' +
      '> A quiz stays a **draft** until you publish it — you can preview exactly what a learner will see before that happens, and duplicate a quiz to reuse its questions in another chapter.\n\n' +
      'Once learners start attempting it, check **Results** on the quiz for the pass rate and which question is missed most often.',
  },
  {
    id: 'review-inside-48-hours',
    slug: 'review-inside-48-hours',
    categoryId: 'assignments',
    title: 'Review submissions inside the 48-hour window',
    summary: 'How the review queue is ordered, and what learners are told about turnaround time.',
    audience: 'instructor',
    tags: ['instructor', 'grading', 'review-queue'],
    readMinutes: 3,
    updatedAt: '2026-07-18T09:30:00+05:30',
    popular: true,
    body:
      'Learners are promised feedback within 48 hours of handing something in, and the review queue is built around keeping that promise.\n\n' +
      '- The queue sorts oldest first, so working straight down it clears the ones closest to the deadline before anything else.\n' +
      '- A submission past 48 hours is flagged **overdue** — for you, and on the admin dashboard, so a backlog doesn’t stay invisible.\n' +
      '- Grade against the assignment’s rubric where it has one; where it doesn’t, enter a score out of the maximum directly.\n' +
      '- A late submission is scored the same way, then reduced by the late penalty the assignment sets — the reduction shows separately from the raw score, so a learner can see both.\n\n' +
      '> Feedback you write is visible to the learner the moment you submit the review — there’s no separate “publish” step.\n\n' +
      'If a queue is genuinely too large for one person, an admin can see the same backlog by course in **Reports › Instructors** and move work between reviewers.',
  },
  {
    id: 'hand-in-your-first-assignment',
    slug: 'hand-in-your-first-assignment',
    categoryId: 'assignments',
    title: 'Hand in your first assignment',
    summary: 'Uploading a file, writing straight into the page, or submitting a chart — and what happens after.',
    audience: 'student',
    tags: ['student', 'assignments', 'submissions'],
    readMinutes: 2,
    updatedAt: '2026-07-10T09:00:00+05:30',
    body:
      'An assignment page shows the brief, what format it wants, and the deadline — everything you need before you start.\n\n' +
      '1. Depending on the assignment, either upload a file, write your answer directly on the page, or fill in a chart with the birth details it asks for.\n' +
      '2. Your work saves as a **draft** automatically, so closing the tab by accident doesn’t lose anything.\n' +
      '3. **Submit** when you’re done — after that the brief locks, so you always know exactly what you were graded against.\n' +
      '4. If you’re past the deadline, check the assignment first: some accept late work with a small penalty, others close on the day.\n\n' +
      '> Feedback usually arrives within 48 hours. You’ll get a notification the moment it does, with your score and your instructor’s comments.',
  },
  {
    id: 'retake-a-quiz',
    slug: 'retake-a-quiz',
    categoryId: 'assignments',
    title: 'Retake a quiz after a failed attempt',
    summary: 'How many tries you get, when the retake opens, and which score counts.',
    audience: 'student',
    tags: ['student', 'quizzes', 'retake'],
    readMinutes: 1,
    updatedAt: '2026-07-05T09:00:00+05:30',
    body:
      'Not passing a quiz on the first try is normal, and it’s built into how quizzes work.\n\n' +
      '- Most quizzes allow **two attempts**, and your higher score is the one that counts toward the course.\n' +
      '- If a quiz has a wait between attempts, the countdown starts the moment you finish the first one — you’ll see exactly when the retake opens.\n' +
      '- A timed quiz keeps the same time limit on every attempt.\n\n' +
      '> **Assessments** in your sidebar lists every quiz you’ve taken across your courses, with your best score and whether a retake is available right now.',
  },

  // ── Live classes & calendar ──────────────────────────────────────────
  {
    id: 'schedule-a-live-class',
    slug: 'schedule-a-live-class',
    categoryId: 'live',
    title: 'Schedule a live class step by step',
    summary: 'Room or outside link, capacity, agenda and reminders — everything the form asks for.',
    audience: 'instructor',
    tags: ['instructor', 'live-classes', 'scheduling'],
    readMinutes: 3,
    updatedAt: '2026-08-12T09:00:00+05:30',
    body:
      'Scheduling a class takes one form, and everything on it shows up somewhere learners will see it.\n\n' +
      '1. Pick the **course** and, if it’s just for one part of it, the **chapter**.\n' +
      '2. Choose the **room**: the academy’s built-in room (recording and attendance are automatic) or an outside meeting link.\n' +
      '3. Set the **date and time** — the room opens 15 minutes early, so learners aren’t left waiting at the door.\n' +
      '4. Add a rough **agenda**; it gives learners a reason to show up on time rather than 20 minutes in.\n' +
      '5. Leave the default **reminders** (a day, an hour and 15 minutes before) or adjust them.\n\n' +
      '> Once a class has started, its time and room lock — cancel it instead if plans change, and give a reason; registered learners are told immediately either way.\n\n' +
      'A class you can’t make live still has a purpose: recordings stay available for 30 days, so a scheduling clash doesn’t cost anyone the material.',
  },
  {
    id: 'join-and-catch-up',
    slug: 'join-and-catch-up',
    categoryId: 'live',
    title: 'Join a live class, or catch up on the recording',
    summary: 'Registering ahead of time, joining when it goes live, and where recordings live afterwards.',
    audience: 'student',
    tags: ['student', 'live-classes', 'recordings'],
    readMinutes: 2,
    updatedAt: '2026-08-08T09:00:00+05:30',
    body:
      '**Live classes** in your sidebar shows what’s happening now, what’s coming up, and what you can watch back.\n\n' +
      '- **Register** for a class ahead of time and you’ll get reminders as it approaches — a day before, an hour before, and 15 minutes before, by default.\n' +
      '- Once a class is **starting soon**, the room opens and **Join** appears; the same page shows who else is attending.\n' +
      '- Missed it? Recordings stay available for **30 days**, listed right below the upcoming classes.\n\n' +
      '> A class you’re registered for also shows on your dashboard and the academy calendar, so it’s never something you have to remember to look up.',
  },
  {
    id: 'read-the-calendar',
    slug: 'read-the-calendar',
    categoryId: 'live',
    title: 'Read the academy calendar',
    summary: 'Month, week and list views, and the five kinds of thing that can appear on them.',
    audience: 'all',
    tags: ['calendar', 'schedule'],
    readMinutes: 2,
    updatedAt: '2026-08-02T09:30:00+05:30',
    body:
      'The calendar brings together everything with a date attached, in one place.\n\n' +
      '- **Live classes**, coloured by how soon they are.\n' +
      '- **Assignment deadlines**, with how many learners have handed theirs in already.\n' +
      '- **Quiz windows** — either a closing deadline, or a set time when everyone sits it together.\n' +
      '- **Course milestones** — a cohort starting, a chapter opening, enrolment closing.\n' +
      '- **Reminders** you’ve added yourself, privately or sent to a course’s learners.\n\n' +
      '> Switch between **Month**, **Week** and **List** with the buttons at the top right; on a phone, List is the default so nothing is too small to tap. Filter by type, course or instructor with the chips underneath.',
  },
  {
    id: 'set-a-reminder',
    slug: 'set-a-reminder',
    categoryId: 'live',
    title: 'Set a reminder for a class or a deadline',
    summary: 'Adding your own reminder to the calendar, private or shared with a course.',
    audience: 'all',
    tags: ['calendar', 'reminders'],
    readMinutes: 1,
    updatedAt: '2026-07-25T09:00:00+05:30',
    body:
      'Live classes and deadlines already carry their own reminders — this is for everything else.\n\n' +
      '1. Open the calendar and choose **Add event**.\n' +
      '2. Pick **Reminder**, then decide who it’s for: **just you**, or **learners of a course** (instructors and admins only).\n' +
      '3. Set the date and time, and how far ahead you want the notification.\n\n' +
      '> Mark a reminder **done** once you’ve dealt with it — it stays on the calendar as a record rather than disappearing, so you can see what you followed up on.',
  },

  // ── Certificates & reports ───────────────────────────────────────────
  {
    id: 'how-a-certificate-is-earned',
    slug: 'how-a-certificate-is-earned',
    categoryId: 'certificates',
    title: 'How a certificate is earned',
    summary: 'The requirements a course sets, and what happens once you’ve met them.',
    audience: 'student',
    tags: ['student', 'certificates', 'completion'],
    readMinutes: 2,
    updatedAt: '2026-06-28T09:00:00+05:30',
    popular: true,
    body:
      'Not every course awards a certificate, but where one does, its page lists exactly what it takes — usually a mix of these:\n\n' +
      '- Finishing every lesson (or a set share of them).\n' +
      '- Passing the assignments and quizzes it counts.\n' +
      '- A minimum score on the final assessment.\n\n' +
      '> Your course page shows a progress meter against each requirement, so you always know what’s left rather than finding out at the end.\n\n' +
      'Once every requirement is met, the certificate appears on your **Certificates** page — either issued straight away, or waiting for an admin’s check, depending on how the academy is set up. Once it’s issued, it carries a credential ID anyone can check — see **[Verify a credential ID](/help/article/verify-a-credential)**.',
  },
  {
    id: 'issue-and-revoke',
    slug: 'issue-and-revoke',
    categoryId: 'certificates',
    title: 'Issue, revoke and restore a certificate',
    summary: 'Reviewing what’s ready, and what happens on both sides if one has to be taken back.',
    audience: 'admin',
    tags: ['admin', 'certificates', 'issuing'],
    readMinutes: 3,
    updatedAt: '2026-06-20T09:00:00+05:30',
    body:
      '**Certificates** lists everyone who has met a course’s requirements, filtered by status.\n\n' +
      '1. Learners who finished in the last ten days sit under **Ready to issue** — open one to see their record before confirming.\n' +
      '2. **Issue** stamps it with a credential ID and makes it visible to the learner and to anyone who verifies it.\n' +
      '3. If a certificate needs to be undone — a mistake in the record, most often — **Revoke** it with a reason. The learner sees why, and the reason shows on public verification too, so nothing looks silently wrong.\n' +
      '4. **Restore** brings a revoked certificate back exactly as it was.\n\n' +
      '> The template — layout, colour, wording, and which details print — is set once in **Certificates › Templates** and applies to every course that uses it.',
  },
  {
    id: 'verify-a-credential',
    slug: 'verify-a-credential',
    categoryId: 'certificates',
    title: 'Verify a credential ID',
    summary: 'Checking whether a certificate is genuine, without needing to sign in.',
    audience: 'all',
    tags: ['certificates', 'verification'],
    readMinutes: 1,
    updatedAt: '2026-06-15T09:00:00+05:30',
    body:
      'Every issued certificate carries a credential ID, printed on the certificate itself — something like `SA-JY-2026-04817`.\n\n' +
      '1. Open the **Verify a certificate** page.\n' +
      '2. Enter the credential ID exactly as printed.\n' +
      '3. A genuine certificate shows who earned it, the course, and when — enough to confirm it, not so much that it exposes anything private.\n\n' +
      '> A revoked certificate still verifies — it just says so, along with the reason, rather than pretending the credential never existed.',
  },
  {
    id: 'read-the-reports-overview',
    slug: 'read-the-reports-overview',
    categoryId: 'certificates',
    title: 'Read the reports overview',
    summary: 'Where the headline numbers come from, and how to compare one period with another.',
    audience: 'admin',
    tags: ['admin', 'reports', 'analytics'],
    readMinutes: 3,
    updatedAt: '2026-06-10T09:00:00+05:30',
    body:
      '**Reports** starts with the numbers that matter most across the whole academy, and every one of them is compared with the period before it.\n\n' +
      '- **Enrolments and completion rate** — completion only counts enrolments old enough to have had a fair chance to finish.\n' +
      '- **Active learners** — anyone who studied at any point in the period, not just today.\n' +
      '- **Quiz and assignment results** — attempts, pass rate, and how long reviews are taking against the 48-hour promise.\n\n' +
      '> Change the period, category, course or instructor at the top — every chart and table on the page follows the same filters, so nothing is comparing two different slices by accident.\n\n' +
      'For a closer look, the **Courses**, **Learner progress**, **Instructors** and **Enrolment and completion** tabs break the same data down further, each exportable as a CSV.',
  },

  // ── Academy settings ──────────────────────────────────────────────────
  {
    id: 'course-and-learning-defaults',
    slug: 'course-and-learning-defaults',
    categoryId: 'settings',
    title: 'Set course and learning defaults',
    summary: 'What a new course starts with, and the rules that decide when something counts as finished.',
    audience: 'admin',
    tags: ['admin', 'settings', 'defaults'],
    readMinutes: 3,
    updatedAt: '2026-05-20T09:00:00+05:30',
    body:
      'Two settings sections shape how every course behaves, without needing to be set again on each one.\n\n' +
      '## Courses\n\n' +
      'The format a new course starts as, whether chapters release all at once or in order, whether a course needs review before publishing, and how many instructors a course can have.\n\n' +
      '## Learning\n\n' +
      'How much of a video or reading counts as “finished”, what a course requires to be marked complete, how many quiz attempts learners get, and how a late assignment is treated.\n\n' +
      '> These are defaults, not locks — an individual course, quiz or assignment can still be set up differently. Changing a setting here doesn’t rewrite courses that already exist.',
  },
  {
    id: 'certificates-and-notifications',
    slug: 'certificates-and-notifications',
    categoryId: 'settings',
    title: 'Configure certificates and notifications',
    summary: 'Turning certificates on, choosing what to show on them, and what the academy sends by email.',
    audience: 'admin',
    tags: ['admin', 'settings', 'certificates', 'notifications'],
    readMinutes: 2,
    updatedAt: '2026-05-15T09:00:00+05:30',
    body:
      '## Certificates\n\n' +
      'Turn certificates on or off academy-wide, choose whether they’re issued automatically or wait for an admin to check, set a minimum score, and decide which details print — hours of study, final score, level, signatures.\n\n' +
      '## Notifications\n\n' +
      'The sender name and reply-to address on academy emails, and which automatic messages go out: enrolment confirmations, live class reminders, deadline reminders, a weekly progress summary, and alerts to instructors about new submissions.\n\n' +
      '> People still choose for themselves on top of this, in their own **Notification preferences** — these settings decide what exists to be sent, not who personally receives it.',
  },
  {
    id: 'brand-your-academy',
    slug: 'brand-your-academy',
    categoryId: 'settings',
    title: 'Brand your academy’s appearance',
    summary: 'Name, accent colour, theme and the welcome message learners see on their home page.',
    audience: 'admin',
    tags: ['admin', 'settings', 'branding'],
    readMinutes: 2,
    updatedAt: '2026-05-08T09:00:00+05:30',
    body:
      '**Settings › Appearance** controls how the academy presents itself to learners, with a live preview beside the form.\n\n' +
      '- **Brand name** and a short **welcome message** shown under the greeting on learner home.\n' +
      '- **Accent colour** — used for buttons, progress bars and links throughout; status colours like live and overdue stay the same whatever you pick.\n' +
      '- **Theme** — match the learner’s device, or fix it to light or dark.\n' +
      '- **Course cover art** — the generated line-art covers, on or off.\n\n' +
      '> The preview updates as you type, so you can see exactly what changes before saving.',
  },
  {
    id: 'manage-instructors',
    slug: 'manage-instructors',
    categoryId: 'settings',
    title: 'Invite and manage instructors',
    summary: 'Sending an invitation, assigning courses, and what happens if someone leaves.',
    audience: 'admin',
    tags: ['admin', 'instructors', 'people'],
    readMinutes: 2,
    updatedAt: '2026-05-01T09:00:00+05:30',
    body:
      'Instructors don’t sign themselves up — an admin invites them, which keeps the teaching workspace limited to people the academy has actually brought on.\n\n' +
      '1. From **Instructors**, add a new one with their name, title and the courses they’ll teach.\n' +
      '2. They show as **Invited** until they accept; resend the invitation any time from their profile if it’s gone quiet.\n' +
      '3. Reassign a course to someone else at any point — its history and reports stay with the course, not the person.\n' +
      '4. An instructor with the only assignment to a course can’t be removed from it until someone else is added — a course always keeps at least one teacher.\n\n' +
      '> An instructor’s profile shows their reach (learners, courses, completion rate) and performance (rating, reviews, review time) at a glance — the same figures that feed **Reports › Instructors**.',
  },
];
