import { useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import type { Course } from '@syniastrolms/domain';
import { Button } from '@/components/ui/Button/Button';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { priceSortKey, saleDisplay } from '@/lib/coursePricing';
import { plural } from '@/lib/format';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import { PublicCourseCard, teacherNames } from './PublicCourseCard';
import { PageHero } from './SiteParts';
import styles from './Marketing.module.css';
import site from './Site.module.css';

export type PriceFilter = 'all' | 'free' | 'paid' | 'under-1000' | '1000-5000' | 'over-5000';
export type SortKey = 'popular' | 'rating' | 'newest' | 'price-low' | 'price-high';

const PRICE_OPTIONS: { value: PriceFilter; label: string }[] = [
  { value: 'all', label: 'Any price' },
  { value: 'free', label: 'Free' },
  { value: 'paid', label: 'Paid' },
  { value: 'under-1000', label: 'Under ₹1,000' },
  { value: '1000-5000', label: '₹1,000 to ₹5,000' },
  { value: 'over-5000', label: 'Over ₹5,000' },
];

/** Whether a course's selling price falls in the filter. A course with no price yet matches only "Any price". */
export function matchesPrice(course: Pick<Course, 'pricing' | 'price' | 'salePrice'>, filter: PriceFilter): boolean {
  if (filter === 'all') return true;
  const sale = saleDisplay(course);
  if (filter === 'free') return sale.kind === 'free';
  if (sale.kind !== 'paid') return false;
  const amount = sale.amount;
  if (filter === 'paid') return true;
  if (filter === 'under-1000') return amount < 1000;
  if (filter === '1000-5000') return amount >= 1000 && amount <= 5000;
  return amount > 5000;
}

export function sortCourses(courses: Course[], sort: SortKey): Course[] {
  const by: Record<SortKey, (a: Course, b: Course) => number> = {
    popular: (a, b) => b.enrolledCount - a.enrolledCount,
    rating: (a, b) => (b.rating ?? 0) - (a.rating ?? 0) || (b.ratingCount ?? 0) - (a.ratingCount ?? 0),
    newest: (a, b) => (b.publishedAt ?? '').localeCompare(a.publishedAt ?? ''),
    'price-low': (a, b) => priceSortKey(a) - priceSortKey(b),
    // A course that cannot be bought yet stays last either way.
    'price-high': (a, b) => {
      const [x, y] = [priceSortKey(a), priceSortKey(b)];
      return (Number.isFinite(y) ? y : -1) - (Number.isFinite(x) ? x : -1);
    },
  };
  return [...courses].sort(by[sort]);
}

/** `/courses`: the public catalogue. Every filter lives in the address, so a filtered list can be shared. */
export default function ExploreCoursesPage() {
  const [params, setParams] = useSearchParams();
  const search = params.get('q') ?? '';
  const categoryId = params.get('category') ?? '';
  const levelId = params.get('level') ?? '';
  const price = (params.get('price') as PriceFilter | null) ?? 'all';
  const sort = (params.get('sort') as SortKey | null) ?? 'popular';
  const update = (next: Record<string, string>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || (k === 'price' && v === 'all') || (k === 'sort' && v === 'popular')) p.delete(k);
      else p.set(k, v);
    }
    setParams(p, { replace: true });
  };

  const query = useAsync('site:explore', () =>
    Promise.all([services.catalog.listCourses(), services.catalog.listCategories(), services.catalog.listLevels(), services.catalog.listInstructors()]).then(
      ([courses, categories, levels, instructors]) => ({ courses, categories, levels, instructors }),
    ),
  );
  const data = query.data;

  const shown = useMemo(() => {
    if (!data) return [];
    const q = search.trim().toLowerCase();
    return sortCourses(
      data.courses.filter(
        (c) =>
          (!categoryId || c.categoryId === categoryId) &&
          (!levelId || c.levelId === levelId) &&
          matchesPrice(c, price) &&
          (!q || `${c.title} ${c.subtitle} ${c.tags.join(' ')} ${teacherNames(c, data.instructors)}`.toLowerCase().includes(q)),
      ),
      sort,
    );
  }, [data, search, categoryId, levelId, price, sort]);

  const filtered = Boolean(search || categoryId || levelId || price !== 'all');

  return (
    <MarketingChrome>
      <PageHero eyebrow="Explore" title="Explore courses">
        Search the catalogue, or narrow it by category, level and price. Open any course to see its outline, instructor and price.
      </PageHero>
      <section className={styles.section} aria-label="Courses">
        <div className={site.filters}>
          <Field label="Search">
            <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Course, topic or instructor" aria-label="Search courses" />
          </Field>
          <Field label="Category">
            <Select id="explore-category" value={categoryId} onChange={(e) => update({ category: e.target.value })}>
              <option value="">All categories</option>
              {data?.categories
                .filter((c) => c.status === 'active')
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
            </Select>
          </Field>
          <Field label="Level">
            <Select id="explore-level" value={levelId} onChange={(e) => update({ level: e.target.value })}>
              <option value="">All levels</option>
              {data?.levels.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.name}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Price">
            <Select id="explore-price" value={price} onChange={(e) => update({ price: e.target.value })}>
              {PRICE_OPTIONS.map((o) => (
                <option key={o.value} value={o.value}>
                  {o.label}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Sort by">
            <Select id="explore-sort" value={sort} onChange={(e) => update({ sort: e.target.value })}>
              <option value="popular">Most popular</option>
              <option value="rating">Highest rated</option>
              <option value="newest">Newest</option>
              <option value="price-low">Price, low to high</option>
              <option value="price-high">Price, high to low</option>
            </Select>
          </Field>
        </div>

        {query.status === 'error' && !data ? (
          <StateMessage
            kind="error"
            title="The courses didn’t load"
            actions={
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            }
          >
            {query.error.message}
          </StateMessage>
        ) : !data ? (
          <div aria-busy="true" className={site.courseGrid}>
            {[0, 1, 2, 3, 4, 5].map((i) => (
              <Skeleton key={i} height={320} radius="var(--r-lg)" />
            ))}
          </div>
        ) : shown.length === 0 ? (
          <StateMessage
            title={filtered ? 'No course matches these filters' : 'No courses yet'}
            actions={filtered ? <Button onClick={() => setParams({}, { replace: true })}>Clear filters</Button> : undefined}
          >
            {filtered ? 'Try fewer filters or another search.' : 'New courses are on their way. Please check back soon.'}
          </StateMessage>
        ) : (
          <>
            <p className={site.resultLine} role="status">
              {plural(shown.length, 'course')}
            </p>
            <ul className={site.courseGrid}>
              {shown.map((c) => (
                <PublicCourseCard key={c.id} course={c} instructors={data.instructors} headingLevel="h2" />
              ))}
            </ul>
          </>
        )}
      </section>
    </MarketingChrome>
  );
}
