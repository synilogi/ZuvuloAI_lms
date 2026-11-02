import type { Icon } from '@phosphor-icons/react';
import {
  ArrowUpRight,
  Bell,
  BookOpenText,
  CalendarBlank,
  CaretRight,
  Certificate,
  ChalkboardTeacher,
  ChartLineUp,
  CheckCircle,
  ClipboardText,
  Exam,
  GearSix,
  GraduationCap,
  LinkSimple,
  MagnifyingGlass,
  Plus,
  Receipt,
  SealCheck,
  SquaresFour,
  UserPlus,
  UsersThree,
  VideoCamera,
} from '@phosphor-icons/react';
import type { CoverMotif } from '@syniastrolms/domain';
import type { ReactNode } from 'react';
import { BrandLogo } from '@/branding/BrandLogo';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { cx } from '@/lib/cx';
import styles from './ProductMock.module.css';

/*
 * Pictures of the product for the company website: the academy admin panel as it looks today, redrawn in markup so it
 * stays sharp at every width and follows the theme. Each screen follows the real one — the ink sidebar with the same
 * entries, the dashboard's four plain-language figures and "Needs your attention", the course table's columns, the
 * billing page's usage against the plan's limits. The names and numbers are sample data, shown to nobody as fact: the
 * whole picture is one image to assistive technology.
 */

export type MockScreen = 'dashboard' | 'courses' | 'people' | 'assessments' | 'reports' | 'billing';

/** The admin sidebar, as the shell lists it; `screen` is the mock screen an entry stands for. */
const NAV: { label: string; icon: Icon; screen?: MockScreen; group?: string; count?: string }[] = [
  { label: 'Dashboard', icon: SquaresFour, screen: 'dashboard' },
  { label: 'Courses', icon: BookOpenText, screen: 'courses', group: 'Catalog' },
  { label: 'Quizzes', icon: Exam, screen: 'assessments' },
  { label: 'Assignments', icon: ClipboardText, count: '5' },
  { label: 'Live classes', icon: VideoCamera },
  { label: 'Certificates', icon: Certificate },
  { label: 'Students', icon: UsersThree, screen: 'people', group: 'People' },
  { label: 'Instructors', icon: ChalkboardTeacher },
  { label: 'Reports', icon: ChartLineUp, screen: 'reports', group: 'Insight' },
  { label: 'Calendar', icon: CalendarBlank },
  { label: 'Settings', icon: GearSix },
  { label: 'Billing', icon: Receipt, screen: 'billing' },
];

export function ProductMock({ screen, label, className }: { screen: MockScreen; label: string; className?: string }) {
  return (
    <div className={cx(styles.frame, className)} role="img" aria-label={label} data-mock={screen}>
      <div className={styles.chrome} aria-hidden="true">
        <span className={styles.dots}>
          <i />
          <i />
          <i />
        </span>
        <span className={styles.chromeTitle}>Admin panel · sample data</span>
      </div>
      <div className={styles.inner} aria-hidden="true">
        <div className={styles.side} data-surface="ink">
          <div className={styles.brand}>
            <span className={styles.brandMark}>
              <BrandLogo variant="mark" alt="" />
            </span>
            <span>
              <strong>ZuviloAI</strong>
              <small>Admin</small>
            </span>
          </div>
          <span className={styles.sideAction}>
            <Plus size={12} weight="bold" /> New course
          </span>
          {NAV.map((n) => (
            <div key={n.label} className={styles.navRow}>
              {n.group && <span className={styles.navGroup}>{n.group}</span>}
              <span className={cx(styles.navItem, n.screen === screen && styles.navItemOn)}>
                <n.icon size={15} /> <span className={styles.navLabel}>{n.label}</span>
                {n.count && <span className={styles.navCount}>{n.count}</span>}
              </span>
            </div>
          ))}
        </div>
        <div className={styles.column}>
          <div className={styles.topbar}>
            <span className={styles.crumbs}>
              Home <CaretRight size={9} /> <b>{CRUMB[screen]}</b>
            </span>
            <span className={styles.search}>
              <MagnifyingGlass size={12} /> Search courses, students, lessons…
            </span>
            <span className={styles.bellMock}>
              <Bell size={14} />
              <i />
            </span>
            <span className={styles.me}>KM</span>
          </div>
          <div className={styles.main}>{SCREENS[screen]()}</div>
        </div>
      </div>
    </div>
  );
}

const CRUMB: Record<MockScreen, string> = {
  dashboard: 'Dashboard',
  courses: 'Courses',
  people: 'Students',
  assessments: 'Quizzes',
  reports: 'Reports',
  billing: 'Billing',
};

/* ─── Small parts the screens share ─── */

function Head({ title, note, action }: { title: string; note?: string; action?: string }) {
  return (
    <div className={styles.head}>
      <div>
        <strong className={styles.title}>{title}</strong>
        {note && <small className={styles.note}>{note}</small>}
      </div>
      {action && (
        <span className={styles.btn}>
          <Plus size={12} weight="bold" /> {action}
        </span>
      )}
    </div>
  );
}

function Badge({ tone = 'ok', children }: { tone?: 'ok' | 'warn' | 'quiet'; children: ReactNode }) {
  return <span className={cx(styles.badge, styles[`badge-${tone}`])}>{children}</span>;
}

function Meter({ value }: { value: number }) {
  return (
    <span className={styles.meter}>
      <span style={{ width: `${value}%` }} />
    </span>
  );
}

function Initials({ name }: { name: string }) {
  return (
    <span className={styles.avatar}>
      {name
        .split(' ')
        .map((p) => p[0])
        .join('')
        .slice(0, 2)}
    </span>
  );
}

/** A line with a soft area under it, drawn from a handful of points on a 0–100 scale. */
function AreaChart({ points, height = 120 }: { points: number[]; height?: number }) {
  const w = 400;
  const step = w / (points.length - 1);
  const xy = points.map((p, i) => `${(i * step).toFixed(1)},${(height - (p / 100) * height).toFixed(1)}`);
  return (
    <svg viewBox={`0 0 ${w} ${height}`} preserveAspectRatio="none" className={styles.chart}>
      {[0.25, 0.5, 0.75].map((f) => (
        <line key={f} x1={0} x2={w} y1={height * f} y2={height * f} className={styles.chartGrid} />
      ))}
      <polygon points={`0,${height} ${xy.join(' ')} ${w},${height}`} className={styles.chartArea} />
      <polyline points={xy.join(' ')} className={styles.chartLine} />
    </svg>
  );
}

function Spark({ points }: { points: number[] }) {
  const xy = points.map((p, i) => `${(i * (60 / (points.length - 1))).toFixed(1)},${(22 - (p / 100) * 20).toFixed(1)}`);
  return (
    <svg viewBox="0 0 60 24" className={styles.spark}>
      <polyline points={xy.join(' ')} className={styles.chartLine} />
    </svg>
  );
}

/* ─── Screens ─── */

const KPIS: { label: string; value: string; change: string; help: string; icon: Icon; hue: string; trend: number[] }[] = [
  {
    label: 'Published courses',
    value: '12',
    change: '2 more than last month',
    help: 'Courses students can join right now.',
    icon: BookOpenText,
    hue: 'violet',
    trend: [40, 42, 42, 48, 50, 56],
  },
  {
    label: 'Students',
    value: '486',
    change: 'Up 8% from last month',
    help: 'Everyone who has joined your academy.',
    icon: UsersThree,
    hue: 'blue',
    trend: [30, 36, 44, 52, 60, 72],
  },
  {
    label: 'Instructors',
    value: '6',
    change: '1 more than last month',
    help: 'Teachers who accepted their invitation.',
    icon: ChalkboardTeacher,
    hue: 'green',
    trend: [50, 50, 58, 58, 66, 66],
  },
  {
    label: 'Finished their course',
    value: '68%',
    change: 'Up 5 points from last month',
    help: 'Of students enrolled 60+ days.',
    icon: GraduationCap,
    hue: 'gold',
    trend: [44, 50, 48, 56, 60, 64],
  },
];

function Dashboard() {
  return (
    <>
      <div className={styles.head}>
        <div>
          <strong className={styles.title}>Welcome back, Kavita</strong>
          <small className={styles.note}>3 things need your attention · 2 live classes this week</small>
        </div>
        <span className={styles.btn}>
          <Plus size={12} weight="bold" /> Add a course
        </span>
      </div>
      <div className={styles.kpis}>
        {KPIS.map((k) => (
          <div key={k.label} className={styles.kpi} data-hue={k.hue}>
            <span className={styles.kpiHead}>
              <span className={styles.kpiIcon}>
                <k.icon size={13} weight="duotone" />
              </span>
              <b>{k.label}</b>
            </span>
            <span className={styles.kpiRow}>
              <strong>{k.value}</strong>
              <Spark points={k.trend} />
            </span>
            <span className={styles.change}>
              <ArrowUpRight size={10} weight="bold" /> {k.change}
            </span>
            <small className={styles.faint}>{k.help}</small>
          </div>
        ))}
      </div>
      <div className={styles.split}>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>How your courses are doing</strong>
            <span className={styles.seg}>
              <b>New students</b>
              <span>Finished</span>
            </span>
          </span>
          <span className={styles.figure}>
            <strong>148</strong>
            <small>students joined a course in the last 4 weeks</small>
          </span>
          <AreaChart points={[30, 38, 34, 46, 44, 52, 50, 58, 62, 60, 70, 82]} height={104} />
        </div>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>Needs your attention</strong>
            <span className={styles.countPill}>3</span>
          </span>
          <ul className={styles.todo}>
            {[
              { icon: ClipboardText, tone: 'danger', title: '5 submissions waiting', when: 'Do today', action: 'Mark now' },
              { icon: VideoCamera, tone: 'warn', title: 'Live class is almost full', when: 'This week', action: 'Open class' },
              { icon: UsersThree, tone: 'info', title: '12 students quiet for 10 days', when: 'This week', action: 'See students' },
            ].map((t) => (
              <li key={t.title}>
                <span className={styles.todoIcon} data-tone={t.tone}>
                  <t.icon size={13} />
                </span>
                <span className={styles.todoText}>
                  <b>{t.title}</b>
                  <span className={styles.todoFoot}>
                    <span className={styles.when} data-tone={t.tone}>
                      {t.when}
                    </span>
                    <span className={styles.actionPill}>{t.action}</span>
                  </span>
                </span>
              </li>
            ))}
          </ul>
        </div>
      </div>
      <div className={styles.card}>
        <span className={styles.cardHead}>
          <strong>Recent activity</strong>
          <small className={styles.faint}>Newest first</small>
        </span>
        <ul className={cx(styles.rows, styles.activity)}>
          {[
            { icon: UserPlus, who: 'Aditi Sharma', what: 'joined Maths Foundations', when: '2 min ago' },
            { icon: VideoCamera, who: 'Meera Nair', what: 'scheduled a live class', when: '10 min ago' },
            { icon: SealCheck, who: 'Rohan Mehta', what: 'earned a certificate', when: '25 min ago' },
          ].map((e) => (
            <li key={e.who}>
              <span className={styles.activityIcon}>
                <e.icon size={12} />
              </span>
              <span>
                <b>{e.who}</b> {e.what}
              </span>
              <small className={cx(styles.faint, styles.pushEnd)}>{e.when}</small>
            </li>
          ))}
        </ul>
      </div>
    </>
  );
}

const COURSES: { title: string; meta: string; motif: CoverMotif; teacher: string; outline: string; learners: string; draft?: boolean }[] = [
  { title: 'Maths Foundations', meta: 'Beginner · Classes 6–8', motif: 'houses', teacher: 'Meera Nair', outline: '5 chapters · 22 lessons', learners: '214' },
  { title: 'Logical Reasoning', meta: 'Intermediate · Exam prep', motif: 'orbits', teacher: 'Arjun Rao', outline: '4 chapters · 14 lessons', learners: '132' },
  {
    title: 'Algebra Essentials',
    meta: 'Intermediate · Classes 9–10',
    motif: 'ecliptic',
    teacher: 'Meera Nair',
    outline: '4 chapters · 16 lessons',
    learners: '86',
  },
  {
    title: 'RAS Mains Answer Writing',
    meta: 'Advanced · State exams',
    motif: 'nakshatra',
    teacher: 'Kavya Iyer',
    outline: '2 chapters · 5 lessons',
    learners: '—',
    draft: true,
  },
];

function Courses() {
  return (
    <>
      <Head title="Courses" note="Draft, publish and retire courses" action="Add course" />
      <span className={styles.tabs}>
        <b>All 12</b>
        <span>Published 9</span>
        <span>Drafts 2</span>
        <span>Archived 1</span>
      </span>
      <div className={cx(styles.card, styles.table)}>
        <div className={cx(styles.tr, styles.th, styles.colsCourses)}>
          <span>Course</span>
          <span className={styles.hideMd}>Instructor</span>
          <span className={styles.hideSm}>Curriculum</span>
          <span>Learners</span>
          <span>Status</span>
        </div>
        {COURSES.map((c) => (
          <div key={c.title} className={cx(styles.tr, styles.colsCourses)}>
            <span className={styles.courseCell}>
              <CourseCover motif={c.motif} className={styles.thumb} />
              <span>
                <b>{c.title}</b>
                <small>{c.meta}</small>
              </span>
            </span>
            <span className={cx(styles.person, styles.hideMd)}>
              <Initials name={c.teacher} /> {c.teacher}
            </span>
            <span className={styles.hideSm}>{c.outline}</span>
            <span>{c.learners}</span>
            <span>{c.draft ? <Badge tone="warn">Draft</Badge> : <Badge>Published</Badge>}</span>
          </div>
        ))}
      </div>
    </>
  );
}

const STUDENTS = [
  { name: 'Aditi Sharma', courses: '3 courses', progress: 82, state: 'Active' },
  { name: 'Rohan Mehta', courses: '2 courses', progress: 56, state: 'Active' },
  { name: 'Sana Khan', courses: '1 course', progress: 34, state: 'Active' },
  { name: 'Vikram Das', courses: '2 courses', progress: 100, state: 'Completed' },
];

function People() {
  return (
    <>
      <Head title="Students" note="486 students · 6 instructors" action="Add student" />
      <div className={styles.split}>
        <div className={cx(styles.card, styles.table)}>
          <div className={cx(styles.tr, styles.th, styles.colsPeople)}>
            <span>Student</span>
            <span className={styles.hideMd}>Enrolled</span>
            <span>Progress</span>
            <span>Status</span>
          </div>
          {STUDENTS.map((s) => (
            <div key={s.name} className={cx(styles.tr, styles.colsPeople)}>
              <span className={styles.person}>
                <Initials name={s.name} /> <b>{s.name}</b>
              </span>
              <span className={styles.hideMd}>{s.courses}</span>
              <span className={styles.progress}>
                <Meter value={s.progress} /> {s.progress}%
              </span>
              <span>
                <Badge tone={s.state === 'Completed' ? 'quiet' : 'ok'}>{s.state}</Badge>
              </span>
            </div>
          ))}
        </div>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>Bring in learners</strong>
          </span>
          <small className={styles.note}>Share your join link — students who sign up through it join your LMS only.</small>
          <span className={styles.linkBox}>
            <LinkSimple size={14} /> /join/your-academy
          </span>
          <span className={styles.btnGhost}>Send an invitation</span>
        </div>
      </div>
    </>
  );
}

function Assessments() {
  return (
    <>
      <Head title="Quizzes & assignments" note="Build assessments, review work from one queue" action="New quiz" />
      <div className={styles.split}>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>To mark</strong>
            <Badge tone="warn">5 waiting</Badge>
          </span>
          <ul className={styles.rows}>
            {[
              ['Aditi Sharma', 'Fractions worksheet · Maths Foundations', 'Rubric 3 of 4 scored'],
              ['Rohan Mehta', 'Puzzle set 2 · Logical Reasoning', 'Submitted yesterday'],
              ['Sana Khan', 'Model answer · RAS Mains', 'Submitted 2 days ago'],
            ].map(([name, work, state]) => (
              <li key={name}>
                <Initials name={name} />
                <span>
                  <b>{name}</b>
                  <small>{work}</small>
                </span>
                <small className={cx(styles.faint, styles.hideSm, styles.pushEnd)}>{state}</small>
              </li>
            ))}
          </ul>
        </div>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>Question 4 of 10</strong>
            <Badge tone="quiet">Single answer</Badge>
          </span>
          <small className={styles.note}>What is 3/4 written as a percentage?</small>
          <ul className={styles.options}>
            <li>34%</li>
            <li className={styles.optionOn}>
              <CheckCircle size={14} weight="fill" /> 75%
            </li>
            <li>43%</li>
          </ul>
          <small className={styles.faint}>2 attempts allowed · results shown after submission</small>
        </div>
      </div>
    </>
  );
}

function Reports() {
  const bars: [string, number][] = [
    ['Maths Foundations', 78],
    ['Logical Reasoning', 64],
    ['Algebra Essentials', 52],
    ['RAS Mains Answer Writing', 31],
  ];
  return (
    <>
      <Head title="Reports" note="Courses, students and enrolments" />
      <span className={styles.tabs}>
        <b>Courses</b>
        <span>Students</span>
        <span>Enrolments</span>
        <span>Instructors</span>
      </span>
      <div className={styles.split}>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>Enrolments, week by week</strong>
          </span>
          <AreaChart points={[30, 34, 42, 40, 48, 55, 52, 60, 66, 63, 72, 80]} />
        </div>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>Finished, course by course</strong>
          </span>
          <ul className={styles.bars}>
            {bars.map(([name, value]) => (
              <li key={name}>
                <span>
                  {name} <b>{value}%</b>
                </span>
                <Meter value={value} />
              </li>
            ))}
          </ul>
        </div>
      </div>
    </>
  );
}

function Billing() {
  const usage: [string, string, number][] = [
    ['Students', '486 of 750', 65],
    ['Instructors', '6 of 8', 75],
    ['Courses', '12 of 40', 30],
    ['Media storage', '3.2 GB of 150 GB', 4],
  ];
  return (
    <>
      <Head title="Billing" note="Paid and current. It renews on its own." />
      <span className={styles.planLine}>
        <Badge>Active</Badge> Your plan · Monthly
      </span>
      <div className={styles.split}>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>Usage</strong>
            <small className={styles.faint}>Against each limit of your plan</small>
          </span>
          <ul className={cx(styles.bars, styles.barsGrid)}>
            {usage.map(([name, text, value]) => (
              <li key={name}>
                <span>
                  {name} <b>{text}</b>
                </span>
                <Meter value={value} />
              </li>
            ))}
          </ul>
        </div>
        <div className={styles.card}>
          <span className={styles.cardHead}>
            <strong>Included in the plan</strong>
          </span>
          <span className={styles.chips}>
            {['Course management', 'Assessments', 'Live classes', 'Certificates', 'Reports'].map((f) => (
              <span key={f}>
                <CheckCircle size={13} weight="fill" /> {f}
              </span>
            ))}
          </span>
          <span className={styles.btnGhost}>Change plan</span>
        </div>
      </div>
    </>
  );
}

const SCREENS: Record<MockScreen, () => ReactNode> = {
  dashboard: Dashboard,
  courses: Courses,
  people: People,
  assessments: Assessments,
  reports: Reports,
  billing: Billing,
};
