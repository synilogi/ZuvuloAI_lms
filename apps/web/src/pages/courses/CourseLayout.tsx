import { createContext, useContext } from 'react';
import { Outlet, useLocation, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Eye, ListNumbers, PencilSimple, PlayCircle, RocketLaunch, SquaresFour, UserPlus } from '@phosphor-icons/react';
import type { Category, Course, Instructor, Level } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatRelative } from '@/lib/format';
import { RouteTabs } from '@/components/page/RouteTabs';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { CourseStatusBadge, VisibilityLabel } from '@/components/lms/course/CourseStatus';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { CourseMenu, hasEnrolmentLink, useCopyEnrolmentLink, useCourseStatusActions, type StatusAction } from './courseActions';
import styles from './CourseDetail.module.css';

export interface CourseWorkspace {
  course: Course;
  levels: Level[];
  level?: Level;
  category?: Category;
  instructors: Instructor[];
  base: string;
  isTeaching: boolean;
  /** Replace the course after a mutation. */
  refresh: () => void;
  requestStatus: (action: StatusAction) => void;
}

const CourseContext = createContext<CourseWorkspace | null>(null);

export function useCourseWorkspace() {
  const ctx = useContext(CourseContext);
  if (!ctx) throw new Error('useCourseWorkspace must be used inside CourseLayout');
  return ctx;
}

/** Tab names below a course, keyed by the last path segment. */
const SUBPAGES: Record<string, string> = { curriculum: 'Curriculum', lessons: 'Lessons' };

export default function CourseLayout() {
  const { courseId } = useParams();
  const { base, instructorId, isTeaching } = useWorkspace();
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const now = useNow();

  const query = useAsync(`course:${courseId}`, () =>
    Promise.all([
      services.courses.get(courseId!, instructorId),
      services.catalog.listLevels(),
      services.catalog.listCategories(),
      services.catalog.listInstructors(),
    ]).then(([course, levels, categories, instructors]) => ({ course, levels, categories, instructors })),
  );
  const refresh = () => query.run().catch(() => undefined);
  const { request, dialog } = useCourseStatusActions(base, refresh);
  const copyEnrolmentLink = useCopyEnrolmentLink();

  const parts = pathname.split('/').filter(Boolean);
  const segment = parts.find((s) => SUBPAGES[s]);
  const chapterIndex =
    parts[parts.indexOf('chapters') + 1] && query.data ? query.data.course.chapters.findIndex((c) => c.id === parts[parts.indexOf('chapters') + 1]) : -1;
  const courseTo = `${base}/courses/${courseId}`;
  usePageCrumbs(
    !query.data
      ? [{ label: 'Course' }]
      : parts.includes('chapters') && !segment
        ? [
            { label: query.data.course.title, to: courseTo },
            { label: 'Curriculum', to: `${courseTo}/curriculum` },
            { label: chapterIndex >= 0 ? `Chapter ${chapterIndex + 1}` : 'Chapter' },
          ]
        : [{ label: query.data.course.title, to: courseTo }, ...(segment ? [{ label: SUBPAGES[segment] }] : [])],
  );

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Course not found' : 'This course didn’t load'}
          actions={
            notFound ? (
              <LinkButton to={`${base}/courses`} iconStart={<ArrowLeft size={16} />}>
                Back to courses
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={refresh}>
                Try again
              </Button>
            )
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }

  if (!query.data) {
    return (
      <div className={styles.page} role="status" aria-label="Loading course">
        <div className={styles.header}>
          <Skeleton width={96} height={60} radius="var(--r-md)" />
          <div className={styles.headerText}>
            <Skeleton width={160} height={10} />
            <Skeleton width="60%" height={28} radius="var(--r-xs)" />
            <Skeleton width={220} height={10} />
          </div>
        </div>
        <Skeleton height={320} radius="var(--r-lg)" />
      </div>
    );
  }

  const { course, levels, categories, instructors } = query.data;
  const level = levels.find((l) => l.id === course.levelId);
  const category = categories.find((c) => c.id === course.categoryId);
  const to = `${base}/courses/${course.id}`;

  const value: CourseWorkspace = {
    course,
    levels,
    level,
    category,
    instructors: course.instructorIds.map((id) => instructors.find((i) => i.id === id)).filter((i): i is Instructor => Boolean(i)),
    base,
    isTeaching,
    refresh,
    requestStatus: (action) => request(action, course),
  };

  return (
    <CourseContext.Provider value={value}>
      <div className={styles.page}>
        <header className={styles.header}>
          <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.headerCover} />
          <div className={styles.headerText}>
            <span className={styles.eyebrow}>
              {level?.name} · {category?.name}
            </span>
            <h1 className={styles.title}>{course.title}</h1>
            <div className={styles.headerMeta}>
              <CourseStatusBadge status={course.status} />
              <VisibilityLabel visibility={course.visibility} />
              <span className={styles.metaDivider} aria-hidden="true" />
              <span>Updated {formatRelative(course.updatedAt, now)}</span>
            </div>
          </div>
          <div className={styles.headerActions}>
            {hasEnrolmentLink(course) && (
              <Button iconStart={<UserPlus size={16} />} onClick={() => void copyEnrolmentLink(course)}>
                Copy enrolment link
              </Button>
            )}
            <LinkButton to={`${to}/preview`} iconStart={<Eye size={16} />}>
              Preview
            </LinkButton>
            <LinkButton to={`${to}/edit`} iconStart={<PencilSimple size={16} />}>
              Edit
            </LinkButton>
            {course.status === 'draft' && (
              <Button variant="primary" iconStart={<RocketLaunch size={16} />} onClick={() => request('publish', course)}>
                Publish
              </Button>
            )}
            <CourseMenu course={course} base={base} canArchive={!isTeaching} onAction={request} navigate={navigate} onDetails size="md" />
          </div>
        </header>

        <RouteTabs
          label="Course sections"
          tabs={[
            { to, label: 'Overview', end: true, icon: <SquaresFour size={16} /> },
            { to: `${to}/curriculum`, label: 'Curriculum', icon: <ListNumbers size={16} />, count: course.chapters.length, also: [`${to}/chapters/`] },
            { to: `${to}/lessons`, label: 'Lessons', icon: <PlayCircle size={16} />, count: course.chapters.reduce((n, c) => n + c.lessons.length, 0) },
          ]}
        />

        <Outlet />
        {dialog}
      </div>
    </CourseContext.Provider>
  );
}
