import { useMemo, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { ArrowRight, BookmarkSimple, Compass, MagnifyingGlass } from '@phosphor-icons/react';
import type { Course, CourseFormat } from '@syniastrolms/domain';
import { courseDurationMin } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { cx } from '@/lib/cx';
import { formatCount, formatDuration, plural } from '@/lib/format';
import { priceSortKey, saleDisplay } from '@/lib/coursePricing';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CategoryGlyph } from '@/components/lms/course/CategoryGlyph';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { Rating } from '@/components/lms/shared/Rating';
import { services } from '@/services';
import { API_MODE, useSession } from '@/providers/SessionProvider';
import styles from './Learn.module.css';

type Sort = 'popular' | 'rating' | 'newest' | 'price';
const FORMAT_LABEL: Record<CourseFormat, string> = { 'self-paced': 'Self-paced', cohort: 'Cohort', hybrid: 'Self-paced with live classes' };

/** The catalog: every published course, with the learner's own enrolments marked. */
export default function ExplorePage() {
  const toast = useToast();
  const { isAuthenticated, role } = useSession();
  const [params, setParams] = useSearchParams();
  const search = params.get('q') ?? '';
  const level = params.get('level') ?? 'all';
  const categoryId = params.get('category') ?? '';
  const format = (params.get('format') ?? '') as CourseFormat | '';
  const sort = (params.get('sort') as Sort | null) ?? 'popular';
  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || (k === 'level' && v === 'all') || (k === 'sort' && v === 'popular')) p.delete(k);
      else p.set(k, v);
    }
    setParams(p, { replace: true });
  };

  // The catalog is public — it is reached from the marketing site by visitors who are not signed in.
  // Only a signed-in learner has enrolments and saved courses to lay over it; asking for them as a
  // visitor answers 401 and would take the whole page down with it.
  const hasLearnerWorkspace = API_MODE !== 'http' || (isAuthenticated && role === 'student');
  const query = useAsync(`explore:${hasLearnerWorkspace}`, () =>
    Promise.all([
      services.catalog.listCourses(),
      services.catalog.listLevels(),
      services.catalog.listCategories(),
      services.catalog.listInstructors(),
      hasLearnerWorkspace ? services.learning.listCourses() : Promise.resolve({ courses: [], saved: [] }),
    ]).then(([courses, levels, categories, instructors, mine]) => ({ courses, levels, categories, instructors, mine })),
  );
  const [savedOverride, setSavedOverride] = useState<Record<string, boolean>>({});
  const data = query.data;

  const catalog = useMemo(() => (data ? data.courses.filter((c) => c.status === 'published' && c.visibility === 'public') : []), [data]);
  const shown = useMemo(() => {
    if (!data) return [];
    const q = search.trim().toLowerCase();
    const names = (c: Course) => c.instructorIds.map((id) => data.instructors.find((i) => i.id === id)?.name ?? '').join(' ');
    const list = catalog.filter(
      (c) =>
        (level === 'all' || c.levelId === level) &&
        (!categoryId || c.categoryId === categoryId) &&
        (!format || c.format === format) &&
        (!q || `${c.title} ${c.subtitle} ${c.tags.join(' ')} ${names(c)}`.toLowerCase().includes(q)),
    );
    const by: Record<Sort, (a: Course, b: Course) => number> = {
      popular: (a, b) => b.enrolledCount - a.enrolledCount,
      rating: (a, b) => (b.rating ?? 0) - (a.rating ?? 0) || (b.ratingCount ?? 0) - (a.ratingCount ?? 0),
      newest: (a, b) => (b.publishedAt ?? '').localeCompare(a.publishedAt ?? ''),
      price: (a, b) => priceSortKey(a) - priceSortKey(b),
    };
    return [...list].sort(by[sort]);
  }, [data, catalog, search, level, categoryId, format, sort]);

  const filtered = Boolean(search || level !== 'all' || categoryId || format);

  if (query.status === 'error' && !data) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title="The catalog didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }

  // A visitor has no learner workspace, so their cards open the public course page instead.
  const courseHref = (course: Course) => (hasLearnerWorkspace ? `/learn/${course.id}` : `/courses/${course.slug}`);
  const enrolledIn = new Map((data?.mine.courses ?? []).map((c) => [c.course.id, c]));
  const savedIds = new Set((data?.mine.saved ?? []).map((s) => s.course.id));
  const isSaved = (id: string) => savedOverride[id] ?? savedIds.has(id);

  const toggleSave = async (course: Course) => {
    const next = !isSaved(course.id);
    setSavedOverride((s) => ({ ...s, [course.id]: next }));
    try {
      await services.learning.toggleSaved(course.id);
      toast({ kind: next ? 'success' : 'info', title: next ? 'Saved for later' : 'Removed from saved', text: course.title });
    } catch (e) {
      setSavedOverride((s) => ({ ...s, [course.id]: !next }));
      toast({ kind: 'error', title: 'Couldn’t update saved courses', text: (e as Error).message });
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Browse courses"
        description="Every course you can join, from school subjects to competitive-exam preparation. Lessons marked Free preview can be opened before you join."
        meta={data ? <span className={styles.muted}>{plural(catalog.length, 'course')} open for enrolment</span> : undefined}
      />

      {data && !filtered && (
        <section aria-labelledby="explore-categories">
          <h2 id="explore-categories" className="sr-only">
            Browse by category
          </h2>
          <ul className={styles.categoryStrip}>
            {data.categories
              .filter((cat) => catalog.some((c) => c.categoryId === cat.id))
              .map((cat) => (
                <li key={cat.id}>
                  <button type="button" className={styles.categoryTile} onClick={() => update({ category: cat.id })}>
                    <CategoryGlyph glyph={cat.glyph} size={36} />
                    <span className={styles.categoryText}>
                      <span className={styles.categoryName}>{cat.name}</span>
                      <span className={styles.muted}>{plural(catalog.filter((c) => c.categoryId === cat.id).length, 'course')}</span>
                    </span>
                  </button>
                </li>
              ))}
          </ul>
        </section>
      )}

      <div className={styles.exploreControls}>
        <SegmentedControl
          label="Level"
          value={level}
          onChange={(v) => update({ level: v })}
          segments={[{ value: 'all', label: 'All levels' }, ...(data?.levels ?? []).map((l) => ({ value: l.id, label: l.name }))]}
        />
        <div className={styles.exploreFilters}>
          <div className={styles.exploreSearch}>
            <SearchInput
              value={search}
              onValueChange={(v) => update({ q: v })}
              placeholder="Search courses, topics or instructors"
              aria-label="Search courses"
            />
          </div>
          <Field label="Category" hideLabel className={styles.exploreFilter}>
            <Select value={categoryId} onChange={(e) => update({ category: e.target.value })}>
              <option value="">All categories</option>
              {data?.categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Format" hideLabel className={styles.exploreFilter}>
            <Select value={format} onChange={(e) => update({ format: e.target.value })}>
              <option value="">Any format</option>
              <option value="self-paced">Self-paced</option>
              <option value="cohort">Cohort</option>
              <option value="hybrid">With live classes</option>
            </Select>
          </Field>
          <Field label="Sort" hideLabel className={styles.exploreFilter}>
            <Select value={sort} onChange={(e) => update({ sort: e.target.value })}>
              <option value="popular">Most popular</option>
              <option value="rating">Highest rated</option>
              <option value="newest">Newest</option>
              <option value="price">Price, low to high</option>
            </Select>
          </Field>
        </div>
      </div>

      {!data ? (
        <ul className={styles.courseGrid} aria-busy="true">
          {Array.from({ length: 6 }, (_, i) => (
            <li key={i}>
              <Skeleton height={168} radius="var(--r-lg)" />
            </li>
          ))}
        </ul>
      ) : shown.length === 0 ? (
        filtered ? (
          <StateMessage
            icon={<MagnifyingGlass size={26} />}
            title="No courses match"
            actions={<Button onClick={() => update({ q: undefined, level: undefined, category: undefined, format: undefined })}>Show all courses</Button>}
          >
            Try another topic, or a different level or format.
          </StateMessage>
        ) : (
          <StateMessage icon={<Compass size={26} />} title="No courses are open yet">
            New courses appear here as soon as they’re published.
          </StateMessage>
        )
      ) : (
        <>
          <p className={styles.muted} aria-live="polite">
            {filtered ? `${plural(shown.length, 'course')} match` : `Showing all ${plural(shown.length, 'course')}`}
          </p>
          <ul className={styles.courseGrid}>
            {shown.map((course) => {
              const mine = enrolledIn.get(course.id);
              const levelName = data.levels.find((l) => l.id === course.levelId)?.name;
              const category = data.categories.find((c) => c.id === course.categoryId)?.name;
              const lead = data.instructors.find((i) => i.id === course.instructorIds[0])?.name;
              const minutes = courseDurationMin(course);
              return (
                <li key={course.id} className={cx(styles.courseCard, styles.exploreCard)}>
                  <Link to={courseHref(course)} className={styles.courseCoverLink} tabIndex={-1} aria-hidden="true">
                    <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.courseCover} />
                  </Link>
                  <div className={styles.courseBody}>
                    <span className={styles.eyebrow}>
                      {levelName} · {category}
                    </span>
                    <Link to={courseHref(course)} className={styles.courseTitle}>
                      {course.title}
                    </Link>
                    <span className={styles.muted}>{course.subtitle}</span>
                    <span className={styles.courseFacts}>
                      {lead && <span>{lead}</span>}
                      {course.rating && <Rating value={course.rating} count={course.ratingCount} />}
                      <span>{formatCount(course.enrolledCount)} learners</span>
                      {minutes > 0 && <span>{formatDuration(minutes)}</span>}
                      <span>{FORMAT_LABEL[course.format]}</span>
                    </span>
                    <div className={styles.courseActions}>
                      {mine ? (
                        <>
                          <LinkButton size="sm" variant="primary" to={`/learn/${course.id}`} iconEnd={<ArrowRight size={14} />}>
                            {mine.progress.state === 'completed' ? 'Review course' : 'Continue'}
                          </LinkButton>
                          <span className={styles.muted}>{mine.progress.state === 'completed' ? 'Finished' : `Enrolled · ${mine.progress.percent}%`}</span>
                        </>
                      ) : (
                        <>
                          <LinkButton size="sm" variant="primary" to={courseHref(course)}>
                            View course
                          </LinkButton>
                          <span className={styles.price}>
                            {saleDisplay(course).label}
                            {(() => {
                              const sale = saleDisplay(course);
                              return sale.kind === 'paid' && sale.wasLabel ? <s className={styles.muted}> {sale.wasLabel}</s> : null;
                            })()}
                          </span>
                          {/* Saving needs somewhere to save to, so it is for signed-in learners only. */}
                          {hasLearnerWorkspace && (
                            <IconButton
                              size="sm"
                              className={styles.saveToggle}
                              label={isSaved(course.id) ? `Remove ${course.title} from saved` : `Save ${course.title} for later`}
                              aria-pressed={isSaved(course.id)}
                              icon={<BookmarkSimple size={17} weight={isSaved(course.id) ? 'fill' : 'regular'} />}
                              onClick={() => toggleSave(course)}
                            />
                          )}
                        </>
                      )}
                    </div>
                  </div>
                </li>
              );
            })}
          </ul>
        </>
      )}
    </div>
  );
}
