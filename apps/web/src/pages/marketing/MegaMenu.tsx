import { useEffect, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, CaretDown, Stack } from '@phosphor-icons/react';
import { CategoryGlyph } from '@/components/lms/course/CategoryGlyph';
import { Skeleton } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { saleDisplay } from '@/lib/coursePricing';
import { plural } from '@/lib/format';
import { services } from '@/services';
import styles from './Marketing.module.css';

const SHOWN = { categories: 8, courses: 3, bundles: 3 };

/** Loaded the first time it opens, so a page that never opens it asks for nothing more. */
function MegaPanel() {
  const query = useAsync('site:mega', () =>
    Promise.all([services.catalog.listCategories(), services.catalog.listCourses(), services.site.bundles().catch(() => [])]).then(
      ([categories, courses, bundles]) => ({ categories, courses, bundles }),
    ),
  );
  const data = query.data;
  if (query.status === 'error' && !data) {
    return (
      <p className={styles.megaEmpty}>
        The menu didn’t load. <Link to="/courses">See all courses</Link>.
      </p>
    );
  }
  if (!data) return <Skeleton height={220} radius="var(--r-lg)" />;
  const categories = data.categories
    .filter((c) => c.status === 'active' && data.courses.some((course) => course.categoryId === c.id))
    .slice(0, SHOWN.categories);
  const courses = [...data.courses].sort((a, b) => b.enrolledCount - a.enrolledCount).slice(0, SHOWN.courses);
  const bundles = data.bundles.slice(0, SHOWN.bundles);
  return (
    <div className={styles.megaGrid}>
      <div>
        <h2 className={styles.megaHeading}>Categories</h2>
        <ul className={styles.megaCategories}>
          {categories.map((c) => (
            <li key={c.id}>
              <Link to={`/courses?category=${c.id}`}>
                <CategoryGlyph glyph={c.glyph} size={24} />
                <span>{c.name}</span>
              </Link>
            </li>
          ))}
        </ul>
        <Link to="/categories" className={styles.megaMore}>
          All categories <ArrowRight size={14} aria-hidden="true" />
        </Link>
      </div>
      <div>
        <h2 className={styles.megaHeading}>Popular courses</h2>
        <ul className={styles.megaList}>
          {courses.map((c) => (
            <li key={c.id}>
              <Link to={`/courses/${c.slug}`}>
                <strong>{c.title}</strong>
                <small>{saleDisplay(c).label}</small>
              </Link>
            </li>
          ))}
        </ul>
        <Link to="/courses" className={styles.megaMore}>
          All courses <ArrowRight size={14} aria-hidden="true" />
        </Link>
      </div>
      {bundles.length > 0 && (
        <div>
          <h2 className={styles.megaHeading}>Course bundles</h2>
          <ul className={styles.megaList}>
            {bundles.map((b) => (
              <li key={b.id}>
                <Link to={`/bundles/${b.slug}`}>
                  <strong>
                    <Stack size={14} aria-hidden="true" /> {b.title}
                  </strong>
                  <small>{plural(b.courseCount, 'course')}</small>
                </Link>
              </li>
            ))}
          </ul>
          <Link to="/bundles" className={styles.megaMore}>
            All bundles <ArrowRight size={14} aria-hidden="true" />
          </Link>
        </div>
      )}
    </div>
  );
}

/** "Explore Courses" in the header: a link, with a panel that opens on hover or from its own button. */
export function ExploreMenu({ pathKey }: { pathKey: string }) {
  const [open, setOpen] = useState(false);
  const root = useRef<HTMLDivElement>(null);
  const closing = useRef<number | undefined>(undefined);
  // Reaching the button with a mouse has already opened the panel, so that click must not shut it again.
  const openedByHover = useRef(false);

  useEffect(() => setOpen(false), [pathKey]);
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setOpen(false);
        root.current?.querySelector('button')?.focus();
      }
    };
    const onPointer = (e: PointerEvent) => {
      if (!root.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('keydown', onKey);
    document.addEventListener('pointerdown', onPointer);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('pointerdown', onPointer);
    };
  }, [open]);
  useEffect(() => () => window.clearTimeout(closing.current), []);

  const hoverOpen = () => {
    window.clearTimeout(closing.current);
    if (!open) openedByHover.current = true;
    setOpen(true);
  };
  const toggle = () => {
    if (openedByHover.current) openedByHover.current = false;
    else setOpen((v) => !v);
  };
  // A short grace, so crossing the gap between the link and the panel doesn't close it.
  const hoverClose = () => {
    closing.current = window.setTimeout(() => {
      openedByHover.current = false;
      setOpen(false);
    }, 160);
  };

  return (
    <div ref={root} className={styles.megaRoot} onMouseEnter={hoverOpen} onMouseLeave={hoverClose}>
      <Link to="/courses">Explore Courses</Link>
      <button type="button" className={styles.megaToggle} aria-expanded={open} aria-label="Show the courses menu" onClick={toggle}>
        <CaretDown size={13} aria-hidden="true" />
      </button>
      {open && (
        <div className={styles.megaPanel}>
          <MegaPanel />
        </div>
      )}
    </div>
  );
}
