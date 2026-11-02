import type { ReactNode } from 'react';
import {
  ArrowRight,
  BookOpenText,
  CalendarPlus,
  Certificate,
  CircleHalf,
  ClipboardText,
  Exam,
  MagnifyingGlass,
  Play,
  Plus,
  SidebarSimple,
  Stack,
  UserSwitch,
  UsersThree,
  VideoCamera,
} from '@phosphor-icons/react';
import type { Course, Role } from '@syniastrolms/domain';
import type { ToastInput } from '@/components/overlays/Toast/ToastProvider';
import { courses, foundationsCourse } from '@/services/mock/fixtures/catalog';
import { API_MODE } from '@/lib/apiMode';
import { homeFor } from '@/lib/roleHome';
import { flatItems } from '@/shell/navigation';

// Course creation navigates straight to the real editor (see the `create-course` command below and
// the sidebar's primary action) — it never needs the course-picking step the other three kinds do.
export type QuickCreateKind = 'chapter' | 'lesson' | 'live-class';

export interface CommandContext {
  role: Role;
  navigate: (to: string) => void;
  toast: (t: ToastInput) => void;
  toggleTheme: () => void;
  toggleSidebar: () => void;
  switchRole: (role: Role) => void;
  openQuickCreate: (kind: QuickCreateKind) => void;
}

export type CommandGroup = 'Continue' | 'Actions' | 'Go to' | 'Lessons' | 'Courses' | 'Preferences';

export interface Command {
  id: string;
  label: string;
  group: CommandGroup;
  icon: ReactNode;
  /** Right-aligned context — why this command is here right now. */
  hint?: string;
  hintTone?: 'live' | 'due';
  keywords?: string;
  roles: Role[];
  run: (ctx: CommandContext) => void;
}

// The three workspace roles. Super Admin is left out on purpose: none of these commands has a
// Super Admin destination yet, so it is offered its own (currently empty) navigation and nothing else.
const everyone: Role[] = ['student', 'instructor', 'admin'];
const staff: Role[] = ['instructor', 'admin'];

/**
 * Contextual commands. Student commands are about the next step in their learning;
 * staff commands are about creating and reviewing. Hints carry the reason a command is
 * offered ("Live now", "Due Fri") so the palette doubles as a to-do surface.
 */
export function baseCommands(): Command[] {
  return [
    // Student — continue. Against the real API these open the learner's own pages; only the demo build, which has
    // fixtures to point at, names a lesson or a deadline — a made-up "Live now" must never reach a real learner.
    ...(API_MODE === 'mock' ? demoContinue() : realContinue()),

    // Staff — actions
    {
      id: 'create-course',
      group: 'Actions',
      label: 'Create course',
      icon: <Plus size={17} />,
      keywords: 'new course',
      roles: ['admin', 'instructor'],
      run: (c) => c.navigate(c.role === 'instructor' ? '/teach/courses/new' : '/admin/courses/new'),
    },
    {
      id: 'add-chapter',
      group: 'Actions',
      label: 'Add chapter',
      icon: <Stack size={17} />,
      keywords: 'new chapter section module',
      roles: staff,
      run: (c) => c.openQuickCreate('chapter'),
    },
    {
      id: 'add-lesson',
      group: 'Actions',
      label: 'Add lesson',
      icon: <BookOpenText size={17} />,
      keywords: 'new lesson video reading',
      roles: staff,
      run: (c) => c.openQuickCreate('lesson'),
    },
    {
      id: 'schedule-live',
      group: 'Actions',
      label: 'Schedule live class',
      icon: <CalendarPlus size={17} />,
      keywords: 'live session webinar',
      roles: staff,
      run: (c) => c.openQuickCreate('live-class'),
    },
    {
      id: 'review',
      group: 'Actions',
      label: 'Review assignments',
      icon: <ClipboardText size={17} />,
      keywords: 'grade review submissions',
      roles: staff,
      run: (c) => c.navigate(c.role === 'instructor' ? '/teach/assignments/review' : '/admin/assignments/review'),
    },
    {
      id: 'learner-progress',
      group: 'Actions',
      label: 'View learner progress',
      icon: <UsersThree size={17} />,
      keywords: 'students progress analytics',
      roles: staff,
      run: (c) => c.navigate(c.role === 'instructor' ? '/teach/students' : '/admin/students'),
    },

    // Preferences
    {
      id: 'theme',
      group: 'Preferences',
      label: 'Toggle theme',
      icon: <CircleHalf size={17} />,
      keywords: 'dark light mode',
      roles: everyone,
      run: (c) => c.toggleTheme(),
    },
    {
      id: 'sidebar',
      group: 'Preferences',
      label: 'Toggle sidebar',
      hint: '⌘B',
      icon: <SidebarSimple size={17} />,
      roles: everyone,
      run: (c) => c.toggleSidebar(),
    },
    ...(API_MODE === 'mock'
      ? (['student', 'instructor', 'admin'] as Role[]).map<Command>((r) => ({
          id: `role-${r}`,
          group: 'Preferences',
          label: `View as ${r} (demo)`,
          icon: <UserSwitch size={17} />,
          keywords: 'switch role persona',
          roles: everyone.filter((x) => x !== r),
          run: (c) => c.switchRole(r),
        }))
      : []),
  ];
}

/** The demo build's next steps, from its fixtures. */
function demoContinue(): Command[] {
  return [
    {
      id: 'resume',
      group: 'Continue',
      label: 'Resume: Quadratic equations — the discriminant',
      hint: '8 min left',
      icon: <Play size={17} weight="fill" />,
      keywords: 'continue learning lesson',
      roles: ['student'],
      run: (c) => {
        c.navigate('/my-learning');
        c.toast({ kind: 'info', title: 'Resuming at 9:21', text: 'Picking up where you left off.' });
      },
    },
    {
      id: 'join-live',
      group: 'Continue',
      label: 'Join live class: Class 10 Maths doubt session',
      hint: 'Live now',
      hintTone: 'live',
      icon: <VideoCamera size={17} />,
      keywords: 'join live class session',
      roles: ['student'],
      run: (c) => {
        c.navigate('/live');
        c.toast({ kind: 'success', title: 'Joining live class', text: 'Opening the classroom in a new window…' });
      },
    },
    {
      id: 'submit-assignment',
      group: 'Continue',
      label: 'Submit assignment: Linear equations worksheet',
      hint: 'Due Fri',
      hintTone: 'due',
      icon: <ClipboardText size={17} />,
      keywords: 'submit assignment homework',
      roles: ['student'],
      run: (c) => c.navigate('/assignments'),
    },
    {
      id: 'take-assessment',
      group: 'Continue',
      label: 'Take assessment: Practice test — ratio and proportion',
      hint: '9 of 15',
      icon: <Exam size={17} />,
      keywords: 'take assessment quiz test exam',
      roles: ['student'],
      run: (c) => c.navigate('/assessments'),
    },
    {
      id: 'view-certificate',
      group: 'Continue',
      label: 'View certificate: Logical Reasoning',
      icon: <Certificate size={17} />,
      keywords: 'certificate credential',
      roles: ['student'],
      run: (c) => c.navigate('/certificates'),
    },
  ];
}

/** A real learner's next steps: their own pages, which show what is actually due. */
function realContinue(): Command[] {
  const go = (id: string, label: string, to: string, icon: ReactNode, keywords: string): Command => ({
    id,
    group: 'Continue',
    label,
    icon,
    keywords,
    roles: ['student'],
    run: (c) => c.navigate(to),
  });
  return [
    go('resume', 'Continue learning', '/my-learning', <Play size={17} weight="fill" />, 'continue resume learning lesson'),
    go('join-live', 'Live classes', '/live', <VideoCamera size={17} />, 'join live class session'),
    go('submit-assignment', 'Assignments', '/assignments', <ClipboardText size={17} />, 'submit assignment homework'),
    go('take-assessment', 'Assessments', '/assessments', <Exam size={17} />, 'take assessment quiz test exam'),
    go('view-certificate', 'Certificates', '/certificates', <Certificate size={17} />, 'certificate credential'),
  ];
}

function navCommands(role: Role): Command[] {
  return flatItems(role).map((item) => ({
    id: `go-${item.id}`,
    group: 'Go to' as const,
    label: item.label,
    icon: <ArrowRight size={17} />,
    roles: [role],
    run: (c: CommandContext) => c.navigate(item.to),
  }));
}

/** The workspace a staff command opens in. Roles without one are sent to their own home instead of a teaching path. */
const staffBase = (role: Role) => (role === 'admin' || role === 'superadmin' ? '/admin' : role === 'instructor' ? '/teach' : homeFor(role));

/**
 * Search results appear once a query is typed — lessons and courses from the catalog. In http mode
 * the palette passes the published catalog it loaded; the demo build searches its fixtures.
 */
function searchCommands(query: string, catalog?: Course[]): Command[] {
  // Against the real API, only the catalog it loaded: never the demo's fixtures, even while it loads or if it failed.
  if (!catalog && API_MODE === 'http') return [];
  const q = query.toLowerCase();
  const lessonSource = catalog
    ? catalog.flatMap((course) => course.chapters.map((m) => ({ m, course })))
    : foundationsCourse.chapters.map((m) => ({ m, course: foundationsCourse }));
  const lessons = lessonSource
    .flatMap(({ m, course }, mi) => m.lessons.map((l) => ({ l, m, mi: catalog ? course.chapters.indexOf(m) : mi, course })))
    .filter(({ l }) => l.title.toLowerCase().includes(q))
    .slice(0, 5)
    .map<Command>(({ l, m, mi, course }) => ({
      id: `lesson-${l.id}`,
      group: 'Lessons',
      label: l.title,
      hint: `Chapter ${mi + 1} · ${m.title}`,
      icon: <BookOpenText size={17} />,
      roles: everyone,
      run: (c) =>
        catalog
          ? c.navigate(c.role === 'student' ? `/learn/${course.id}/lessons/${l.id}` : `${staffBase(c.role)}/courses/${course.id}/lessons/${l.id}`)
          : c.toast({ kind: 'info', title: l.title, text: 'Opening the lesson.' }),
    }));
  const courseHits = (catalog ?? courses)
    .filter((course) => `${course.title} ${course.subtitle}`.toLowerCase().includes(q))
    .slice(0, 4)
    .map<Command>((course) => ({
      id: `course-${course.id}`,
      group: 'Courses',
      label: course.title,
      icon: <MagnifyingGlass size={17} />,
      roles: everyone,
      run: (c) => c.navigate(c.role === 'student' ? '/explore' : `${staffBase(c.role)}/courses/${course.id}`),
    }));
  return [...lessons, ...courseHits];
}

export const GROUP_ORDER: CommandGroup[] = ['Continue', 'Actions', 'Lessons', 'Courses', 'Go to', 'Preferences'];

export function resolveCommands(role: Role, query: string, catalog?: Course[]): Command[] {
  const q = query.trim().toLowerCase();
  const pool = [...baseCommands(), ...navCommands(role)].filter((c) => c.roles.includes(role));
  const matched = q ? pool.filter((c) => `${c.label} ${c.group} ${c.keywords ?? ''}`.toLowerCase().includes(q)) : pool;
  // Catalog hits carry their own audience too, so a role with no workspace to open them in is offered none.
  const results = q.length >= 2 ? [...matched, ...searchCommands(q, catalog).filter((c) => c.roles.includes(role))] : matched;
  return [...results].sort((a, b) => GROUP_ORDER.indexOf(a.group) - GROUP_ORDER.indexOf(b.group));
}
