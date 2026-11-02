import { Outlet, useLocation, useSearchParams } from 'react-router-dom';
import { ArrowCounterClockwise, BookOpenText, ChalkboardTeacher, ChartLineUp, UserPlus, UsersThree } from '@phosphor-icons/react';
import type { LearnerSegment, ReportRange } from '@syniastrolms/domain';
import { LEARNER_SEGMENTS, REPORT_RANGES } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useWorkspace } from '@/hooks/useWorkspace';
import { PageHeader } from '@/components/page/PageHeader';
import { RouteTabs } from '@/components/page/RouteTabs';
import { Button } from '@/components/ui/Button/Button';
import { Field, Select } from '@/components/ui/Field/Field';
import { services } from '@/services';
import { RANGE_LABEL, SEGMENT_LABEL, useReportFilters, type ReportsOutlet } from './reportMeta';
import { reportTabs } from './reportScope';
import styles from './Reports.module.css';

const TAB_FACE = {
  overview: { label: 'Overview', icon: <ChartLineUp size={16} />, end: true },
  courses: { label: 'Courses', icon: <BookOpenText size={16} /> },
  learners: { label: 'Learner progress', icon: <UsersThree size={16} /> },
  instructors: { label: 'Instructors', icon: <ChalkboardTeacher size={16} /> },
  enrolments: { label: 'Enrolment and completion', icon: <UserPlus size={16} /> },
};

export default function ReportsLayout() {
  const [params, setParams] = useSearchParams();
  const { pathname } = useLocation();
  const filters = useReportFilters();
  const { to, base, isTeaching, instructorId } = useWorkspace();
  const BASE = to('/reports');
  // An instructor's lists hold their own courses, and the roster of other instructors is not theirs to filter by.
  const lookups = useAsync(`report-lookups:${base}`, () =>
    Promise.all([
      services.catalog.listCategories(),
      services.courses.list({ page: 1, pageSize: 100, ...(isTeaching ? { scopeInstructorId: instructorId } : {}) }),
      isTeaching ? Promise.resolve([]) : services.catalog.listInstructors(),
    ]).then(([categories, courses, instructors]) => ({
      categories,
      courses: courses.rows.filter((c) => c.status !== 'draft'),
      instructors: instructors.filter((i) => i.status !== 'invited'),
    })),
  );
  const segmentApplies = pathname.startsWith(`${BASE}/learners`) || pathname.startsWith(`${BASE}/enrolments`);
  const onCourseReport = pathname.startsWith(`${BASE}/courses/`);

  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || (k === 'range' && v === '90d') || (k === 'segment' && v === 'all')) p.delete(k);
      else p.set(k, v);
    }
    p.delete('page');
    setParams(p, { replace: true });
  };
  const keep = (() => {
    const p = new URLSearchParams(params);
    p.delete('page');
    p.delete('q');
    p.delete('sort');
    return p.toString() ? `?${p.toString()}` : '';
  })();
  // In the teaching workspace the instructor is fixed, so it is not a filter anyone set.
  const filtered = Boolean(filters.categoryId || filters.courseId || (!isTeaching && filters.instructorId) || (segmentApplies && filters.segment !== 'all'));
  const resetFilters = () => update({ category: undefined, course: undefined, instructor: undefined, segment: undefined });

  const courses = (lookups.data?.courses ?? []).filter(
    (c) => (!filters.categoryId || c.categoryId === filters.categoryId) && (!filters.instructorId || c.instructorIds.includes(filters.instructorId)),
  );
  const context: ReportsOutlet = { keep, resetFilters, filtered };

  if (onCourseReport) {
    return (
      <div className={styles.page}>
        <Outlet context={context} />
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <PageHeader
        title={isTeaching ? 'Performance' : 'Reports'}
        description={
          isTeaching
            ? 'How your courses are doing — enrolments, completion, progress and assessment results — for any period, compared with the period before.'
            : 'How the platform is doing — enrolments, completion, progress and assessment results — for any period, course or instructor, compared with the period before.'
        }
      />
      <RouteTabs label="Reports" tabs={reportTabs(base, isTeaching).map((tab) => ({ ...TAB_FACE[tab.key], to: `${tab.to}${keep}` }))} />

      <div className={styles.filterBar} role="group" aria-label="Report filters">
        <Field label="Period" className={styles.filterField}>
          <Select value={filters.range} onChange={(e) => update({ range: e.target.value })}>
            {REPORT_RANGES.map((r: ReportRange) => (
              <option key={r} value={r}>
                {RANGE_LABEL[r]}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Category" className={styles.filterField}>
          <Select value={filters.categoryId ?? ''} onChange={(e) => update({ category: e.target.value, course: undefined })}>
            <option value="">All categories</option>
            {lookups.data?.categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Course" className={styles.filterField}>
          <Select value={filters.courseId ?? ''} onChange={(e) => update({ course: e.target.value })}>
            <option value="">All courses</option>
            {courses.map((c) => (
              <option key={c.id} value={c.id}>
                {c.title}
              </option>
            ))}
          </Select>
        </Field>
        {!isTeaching && (
          <Field label="Instructor" className={styles.filterField}>
            <Select value={filters.instructorId ?? ''} onChange={(e) => update({ instructor: e.target.value, course: undefined })}>
              <option value="">All instructors</option>
              {lookups.data?.instructors.map((i) => (
                <option key={i.id} value={i.id}>
                  {i.name}
                </option>
              ))}
            </Select>
          </Field>
        )}
        {segmentApplies && (
          <Field label="Learners" className={styles.filterField}>
            <Select value={filters.segment} onChange={(e) => update({ segment: e.target.value })}>
              {LEARNER_SEGMENTS.map((s: LearnerSegment) => (
                <option key={s} value={s}>
                  {SEGMENT_LABEL[s]}
                </option>
              ))}
            </Select>
          </Field>
        )}
        {filtered && (
          <Button variant="ghost" size="sm" iconStart={<ArrowCounterClockwise size={15} />} onClick={resetFilters} className={styles.resetButton}>
            Reset filters
          </Button>
        )}
      </div>

      <Outlet context={context} />
    </div>
  );
}
