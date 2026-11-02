import { useMemo, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { BookOpenText, Funnel, List, MagnifyingGlass, Plus, SquaresFour } from '@phosphor-icons/react';
import type { Category, Course, CourseStatus, Instructor, Level } from '@syniastrolms/domain';
import { courseDurationMin, courseLessons } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatCount, formatDate, formatDuration, formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { AvatarGroup } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { SearchInput, Select, Field } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { CourseStatusBadge } from '@/components/lms/course/CourseStatus';
import { services, type CourseSort } from '@/services';
import { CourseMenu, useCourseStatusActions } from './courseActions';
import styles from './Courses.module.css';

type StatusFilter = CourseStatus | 'all';
type View = 'list' | 'grid';

const SORTS: { value: CourseSort; label: string }[] = [
  { value: 'updated', label: 'Recently updated' },
  { value: 'title', label: 'Title A–Z' },
  { value: 'learners', label: 'Most learners' },
  { value: 'created', label: 'Newest first' },
];

export default function CourseListPage() {
  const { can } = usePermissions();
  const { base, instructorId, isTeaching } = useWorkspace();
  const navigate = useNavigate();
  const now = useNow();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const [filtersOpen, setFiltersOpen] = useState(false);

  const status = (params.get('status') as StatusFilter) ?? 'all';
  const search = params.get('q') ?? '';
  const categoryId = params.get('category') ?? '';
  const filterInstructor = params.get('instructor') ?? '';
  const sort = (params.get('sort') as CourseSort) ?? 'updated';
  const view: View = isMobile ? 'grid' : ((params.get('view') as View) ?? 'list');
  const page = Number(params.get('page') ?? 1);
  const pageSize = view === 'grid' ? 9 : 10;

  const update = (next: Record<string, string | undefined>, resetPage = true) => {
    const p = new URLSearchParams(params);
    for (const [key, value] of Object.entries(next)) {
      if (!value || (key === 'status' && value === 'all') || (key === 'sort' && value === 'updated') || (key === 'view' && value === 'list')) p.delete(key);
      else p.set(key, value);
    }
    if (resetPage) p.delete('page');
    setParams(p, { replace: true });
  };

  const lookups = useAsync('course-lookups', () =>
    Promise.all([services.catalog.listCategories(), services.catalog.listInstructors(), services.catalog.listLevels()]).then(
      ([categories, instructors, levels]) => ({
        categories: new Map(categories.map((c) => [c.id, c])),
        instructors: new Map(instructors.map((i) => [i.id, i])),
        levels: new Map(levels.map((l) => [l.id, l])),
        categoryList: categories,
        instructorList: instructors,
      }),
    ),
  );

  const query = {
    search,
    categoryId: categoryId || undefined,
    instructorId: filterInstructor || undefined,
    scopeInstructorId: instructorId,
    status,
    sort,
    page,
    pageSize,
  };
  const list = useAsync(JSON.stringify(query), () => services.courses.list(query));
  const { request, dialog } = useCourseStatusActions(base, () => list.run().catch(() => undefined));

  const counts = list.data?.counts;
  const rows = list.data?.rows ?? [];
  const total = list.data?.total ?? 0;
  const filtered = Boolean(search || categoryId || filterInstructor);
  const filterCount = [categoryId, filterInstructor, sort !== 'updated' ? sort : ''].filter(Boolean).length;
  const clearFilters = () => update({ q: undefined, category: undefined, instructor: undefined, status: undefined });

  const ready = list.data && lookups.data;
  const title = isTeaching ? 'My courses' : 'Courses';

  const filterControls = lookups.data && (
    <>
      <Field label="Category" hideLabel={!filtersOpen}>
        <Select value={categoryId} onChange={(e) => update({ category: e.target.value })} aria-label={filtersOpen ? undefined : 'Filter by category'}>
          <option value="">All categories</option>
          {lookups.data.categoryList.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </Select>
      </Field>
      {!isTeaching && (
        <Field label="Instructor" hideLabel={!filtersOpen}>
          <Select
            value={filterInstructor}
            onChange={(e) => update({ instructor: e.target.value })}
            aria-label={filtersOpen ? undefined : 'Filter by instructor'}
          >
            <option value="">All instructors</option>
            {lookups.data.instructorList
              .filter((i) => i.status !== 'invited')
              .map((i) => (
                <option key={i.id} value={i.id}>
                  {i.name}
                </option>
              ))}
          </Select>
        </Field>
      )}
      <Field label="Sort by" hideLabel={!filtersOpen}>
        <Select value={sort} onChange={(e) => update({ sort: e.target.value }, false)} aria-label={filtersOpen ? undefined : 'Sort courses'}>
          {SORTS.map((s) => (
            <option key={s.value} value={s.value}>
              {s.label}
            </option>
          ))}
        </Select>
      </Field>
    </>
  );

  return (
    <div className={styles.page}>
      <PageHeader
        title={title}
        count={counts ? plural(counts.all, 'course') : undefined}
        description={
          isTeaching
            ? 'Courses you teach. Add chapters and lessons — videos, articles, PDFs and quizzes — preview what students see, and publish when it’s ready.'
            : 'Draft, publish and retire courses. Learners only see what is published, and archived courses stay available to the people already enrolled.'
        }
        actions={
          can('catalog.edit') && (
            <LinkButton to={`${base}/courses/new`} iconStart={<Plus size={16} />}>
              Add course
            </LinkButton>
          )
        }
      />

      <div className={styles.controls} hidden={counts?.all === 0 && !filtered && status === 'all'}>
        <SegmentedControl<StatusFilter>
          label="Course status"
          value={status}
          onChange={(value) => update({ status: value })}
          segments={[
            { value: 'all', label: 'All', count: counts?.all },
            { value: 'published', label: 'Published', count: counts?.published },
            { value: 'draft', label: 'Drafts', count: counts?.draft },
            { value: 'archived', label: 'Archived', count: counts?.archived },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput
              value={search}
              onValueChange={(value) => update({ q: value })}
              placeholder="Search by title, subtitle or tag"
              aria-label="Search courses"
            />
          </div>
          {isMobile ? (
            <Button iconStart={<Funnel size={16} />} onClick={() => setFiltersOpen(true)}>
              Filters{filterCount ? ` · ${filterCount}` : ''}
            </Button>
          ) : (
            <>
              <div className={styles.filters}>{filterControls}</div>
              <SegmentedControl<View>
                size="sm"
                label="Layout"
                value={view}
                onChange={(value) => update({ view: value }, false)}
                segments={[
                  { value: 'list', label: <span className="sr-only">List</span>, icon: <List size={16} /> },
                  { value: 'grid', label: <span className="sr-only">Grid</span>, icon: <SquaresFour size={16} /> },
                ]}
              />
            </>
          )}
        </div>
        {filtered && list.data && (
          <p className={styles.resultNote} role="status">
            {plural(total, 'course')} match{total === 1 ? 'es' : ''}
            {search && (
              <>
                {' '}
                “<strong>{search}</strong>”
              </>
            )}
            <button type="button" className={styles.linkButton} onClick={clearFilters}>
              Clear filters
            </button>
          </p>
        )}
      </div>

      {list.status === 'error' && !list.data ? (
        <StateMessage
          kind="error"
          title="Courses didn’t load"
          actions={
            <Button variant="primary" onClick={() => list.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : ready && rows.length === 0 ? (
        filtered || status !== 'all' ? (
          <StateMessage
            icon={<MagnifyingGlass size={26} />}
            title={search ? `No courses match “${search}”` : 'No courses match these filters'}
            actions={<Button onClick={clearFilters}>Clear filters</Button>}
          >
            Try a shorter search, another category, or a different status.
          </StateMessage>
        ) : (
          <StateMessage
            icon={<BookOpenText size={26} />}
            title="No courses yet"
            actions={
              <LinkButton to={`${base}/courses/new`} iconStart={<Plus size={16} />}>
                Add your first course
              </LinkButton>
            }
          >
            Start a draft with a title and an outline. Nothing is visible to learners until you publish it.
          </StateMessage>
        )
      ) : view === 'grid' ? (
        <ul className={styles.grid} aria-label={title} aria-busy={!ready || undefined}>
          {!ready
            ? Array.from({ length: 6 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <Skeleton height={140} radius="var(--r-md)" />
                  <div className={styles.cardBody}>
                    <Skeleton width="80%" height={14} />
                    <Skeleton width="50%" height={10} />
                  </div>
                </li>
              ))
            : rows.map((course) => (
                <CourseCard
                  key={course.id}
                  course={course}
                  base={base}
                  now={now}
                  category={lookups.data!.categories.get(course.categoryId)}
                  level={lookups.data!.levels.get(course.levelId)}
                  instructors={course.instructorIds.map((id) => lookups.data!.instructors.get(id)!).filter(Boolean)}
                  menu={<CourseMenu course={course} base={base} canArchive={!isTeaching} onAction={request} navigate={navigate} />}
                />
              ))}
        </ul>
      ) : (
        <CourseTable
          rows={rows}
          loading={!ready}
          base={base}
          now={now}
          lookups={lookups.data}
          menu={(course) => <CourseMenu course={course} base={base} canArchive={!isTeaching} onAction={request} navigate={navigate} />}
        />
      )}

      {ready && total > pageSize && (
        <Pagination
          page={page}
          pageCount={Math.ceil(total / pageSize)}
          onChange={(p) => update({ page: p > 1 ? String(p) : undefined }, false)}
          summary={`Showing ${(page - 1) * pageSize + 1}–${Math.min(page * pageSize, total)} of ${total}`}
        />
      )}

      <AdaptivePanel
        open={filtersOpen}
        onClose={() => setFiltersOpen(false)}
        title="Filter courses"
        footer={
          <>
            <Button
              onClick={() => {
                update({ category: undefined, instructor: undefined, sort: undefined });
              }}
            >
              Reset
            </Button>
            <Button variant="primary" onClick={() => setFiltersOpen(false)}>
              Show {list.data ? plural(total, 'course') : 'courses'}
            </Button>
          </>
        }
      >
        <div className={styles.panelFields}>{filterControls}</div>
      </AdaptivePanel>

      {dialog}
    </div>
  );
}

/* ─── Table ────────────────────────────────────────────────────────────── */

interface Lookups {
  categories: Map<string, Category>;
  instructors: Map<string, Instructor>;
  levels: Map<string, Level>;
}

function CourseTable({
  rows,
  loading,
  base,
  now,
  lookups,
  menu,
}: {
  rows: Course[];
  loading: boolean;
  base: string;
  now: Date;
  lookups?: Lookups;
  menu: (c: Course) => JSX.Element;
}) {
  const columns = useMemo<Column<Course>[]>(
    () => [
      {
        key: 'course',
        header: 'Course',
        mobile: 'primary',
        render: (c) => (
          <span className={styles.courseCell}>
            <CourseCover motif={c.coverMotif} imageUrl={c.coverImageUrl} className={styles.thumb} />
            <span className={styles.courseText}>
              <Link to={`${base}/courses/${c.id}`} className={styles.courseTitle}>
                {c.title}
              </Link>
              <span className={styles.courseMeta}>
                {lookups?.levels.get(c.levelId)?.name} · {lookups?.categories.get(c.categoryId)?.name}
              </span>
            </span>
          </span>
        ),
      },
      {
        key: 'instructor',
        header: 'Instructor',
        width: '190px',
        mobile: 'detail',
        render: (c) => {
          const people = c.instructorIds.map((id) => lookups?.instructors.get(id)).filter((i): i is Instructor => Boolean(i));
          return (
            <span className={styles.people}>
              <AvatarGroup names={people.map((p) => p.name)} size={24} max={2} label={people.map((p) => p.name).join(', ')} />
              <span className={styles.peopleName}>
                {people[0]?.name}
                {people.length > 1 && <span className={styles.subtle}> +{people.length - 1}</span>}
              </span>
            </span>
          );
        },
      },
      {
        key: 'curriculum',
        header: 'Curriculum',
        width: '150px',
        mobile: 'meta',
        render: (c) => <CurriculumCount course={c} />,
      },
      {
        key: 'learners',
        header: 'Learners',
        align: 'end',
        width: '96px',
        mobile: 'detail',
        render: (c) => <span className="tabular">{c.enrolledCount ? formatCount(c.enrolledCount) : '—'}</span>,
      },
      { key: 'status', header: 'Status', width: '120px', mobile: 'status', render: (c) => <CourseStatusBadge status={c.status} size="sm" /> },
      {
        key: 'updated',
        header: 'Updated',
        width: '120px',
        mobile: 'detail',
        render: (c) => (
          <time dateTime={c.updatedAt} title={formatDate(c.updatedAt)} className={styles.nowrap}>
            {formatRelative(c.updatedAt, now)}
          </time>
        ),
      },
      { key: 'actions', header: 'Actions', width: '56px', align: 'end', mobile: 'hidden', render: (c) => menu(c) },
    ],
    [base, lookups, menu, now],
  );

  return (
    <div className={styles.tablePanel}>
      <DataTable label="Courses" rows={rows} columns={columns} rowKey={(c) => c.id} rowLabel={(c) => c.title} loading={loading} skeletonRows={6} />
    </div>
  );
}

function CurriculumCount({ course }: { course: Course }) {
  const lessons = courseLessons(course).length;
  if (!course.chapters.length) return <span className={styles.subtle}>No chapters yet</span>;
  return (
    <span className={styles.curriculumCell}>
      <span>
        {plural(course.chapters.length, 'chapter')} · {plural(lessons, 'lesson')}
      </span>
      <span className={styles.subtle}>{formatDuration(courseDurationMin(course))}</span>
    </span>
  );
}

/* ─── Card ─────────────────────────────────────────────────────────────── */

interface CourseCardProps {
  course: Course;
  base: string;
  now: Date;
  category?: Category;
  level?: Level;
  instructors: Instructor[];
  menu: JSX.Element;
}

function CourseCard({ course, base, now, category, level, instructors, menu }: CourseCardProps) {
  const to = `${base}/courses/${course.id}`;
  return (
    <li className={styles.card}>
      <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.cover} />
      <span className={styles.cardStatus}>
        <CourseStatusBadge status={course.status} size="sm" />
      </span>
      <div className={styles.cardBody}>
        <span className={styles.cardEyebrow}>
          {level?.name} · {category?.name}
        </span>
        <h2 className={styles.cardTitle}>
          <Link to={to}>{course.title}</Link>
        </h2>
        <span className={styles.cardInstructors}>{instructors.map((i) => i.name).join(', ')}</span>
        <dl className={styles.cardStats}>
          <div>
            <dt className="sr-only">Curriculum</dt>
            <dd>
              <CurriculumCount course={course} />
            </dd>
          </div>
          <div>
            <dt className="sr-only">Learners</dt>
            <dd className="tabular">{course.enrolledCount ? `${formatCount(course.enrolledCount)} learners` : 'No learners yet'}</dd>
          </div>
        </dl>
      </div>
      <div className={styles.cardFoot}>
        <time dateTime={course.updatedAt} className={styles.subtle}>
          Updated {formatRelative(course.updatedAt, now)}
        </time>
        {menu}
      </div>
    </li>
  );
}
