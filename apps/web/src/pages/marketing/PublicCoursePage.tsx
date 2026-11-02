import { useEffect, useMemo } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowRight, CheckCircle, Certificate as CertificateIcon, Clock, Eye, Globe, Users } from '@phosphor-icons/react';
import type { Course, Lesson } from '@syniastrolms/domain';
import { courseDurationMin } from '@syniastrolms/domain';

import { metaDescription, setPageMeta } from '@/app/pageMeta';
import { useAsync } from '@/hooks/useAsync';
import { useJsonLd } from '@/hooks/useJsonLd';
import { formatCount, formatDuration, plural } from '@/lib/format';
import { ALL_INCLUSIVE, saleDisplay, type SaleDisplay } from '@/lib/coursePricing';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Badge } from '@/components/ui/Badge/Badge';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { ArticleBody } from '@/components/lms/content/ArticleBody';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { CourseCurriculum } from '@/components/lms/course/CourseCurriculum';
import { Rating } from '@/components/lms/shared/Rating';
import { services } from '@/services';
import { API_MODE, useSession } from '@/providers/SessionProvider';
import { CourseReviews } from './CourseReviews';
import { MarketingChrome } from './MarketingChrome';
import styles from './Marketing.module.css';

const FORMAT_LABEL: Record<Course['format'], string> = {
  'self-paced': 'Self-paced',
  cohort: 'Cohort',
  hybrid: 'Self-paced with live classes',
};

/** The written part of a free preview lesson, which the public course payload already carries. */
function previewText(lesson: Lesson): string | undefined {
  const c = lesson.content as { article?: { body?: string } } | undefined;
  return c?.article?.body;
}

/**
 * A course as a visitor sees it, before signing in: what it covers, who teaches it, how long it
 * takes and what it costs, with the full curriculum outlined. Lesson bodies are not in this payload
 * — the API sends only the outline plus whatever the instructor marked as a free preview — so there
 * is nothing here to withhold in the page itself.
 */
export default function PublicCoursePage() {
  return (
    <MarketingChrome>
      <CourseDetail />
    </MarketingChrome>
  );
}

/** What a search engine reads about buying a course: a free course is an offer at no cost; one not open yet has none. */
export function courseOffer(sale: SaleDisplay, url: string) {
  if (sale.kind === 'unavailable') return undefined;
  return sale.kind === 'paid'
    ? { '@type': 'Offer', category: 'Paid', price: sale.amount, priceCurrency: 'INR', url }
    : { '@type': 'Offer', category: 'Free', price: 0, priceCurrency: 'INR', url };
}

/** The title, description and structured data search engines read for one course. */
function useCourseMeta(course: Course | undefined, sale: SaleDisplay | undefined) {
  useEffect(() => {
    if (!course) return;
    setPageMeta({
      title: `${course.title} · ZuviloAI`,
      description: metaDescription(course.subtitle || course.description),
      path: `/courses/${course.slug}`,
    });
  }, [course]);
  const url = course && `https://zuviloai.com/courses/${course.slug}`;
  const offers = sale && url ? courseOffer(sale, url) : undefined;
  useJsonLd(
    course && {
      '@context': 'https://schema.org',
      '@type': 'Course',
      name: course.title,
      description: course.subtitle || course.description,
      url,
      provider: { '@type': 'Organization', name: 'ZuviloAI', sameAs: 'https://zuviloai.com' },
      ...(offers ? { offers } : {}),
    },
  );
}

function CourseDetail() {
  const { isAuthenticated, role } = useSession();
  const { slug = '' } = useParams();
  const query = useAsync(`public-course:${slug}`, () =>
    Promise.all([services.catalog.getCourse(slug), services.catalog.listLevels(), services.catalog.listCategories(), services.catalog.listInstructors()]).then(
      ([course, levels, categories, instructors]) => ({ course, levels, categories, instructors }),
    ),
  );
  const data = query.data;

  const loaded = data?.course;
  useCourseMeta(loaded, loaded ? saleDisplay(loaded) : undefined);

  const previews = useMemo(() => (data ? data.course.chapters.flatMap((ch) => ch.lessons).filter((l) => l.isPreview) : []), [data]);

  if (query.status === 'error' && !data) {
    const missing = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.coursePage}>
        <StateMessage
          kind={missing ? 'empty' : 'error'}
          title={missing ? 'This course isn’t available' : 'The course didn’t load'}
          actions={
            missing ? (
              <LinkButton variant="primary" to="/courses">
                Explore courses
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {missing ? 'It may have been unpublished, or the link may be wrong.' : query.error.message}
        </StateMessage>
      </div>
    );
  }

  if (!data) {
    return (
      <div className={styles.coursePage} aria-busy="true">
        <div className={styles.courseLayout}>
          <div className={styles.courseMain}>
            <Skeleton height={140} radius="var(--r-lg)" />
            <Skeleton height={180} radius="var(--r-lg)" />
            <Skeleton height={320} radius="var(--r-lg)" />
          </div>
          <Skeleton height={420} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }

  const { course } = data;
  const level = data.levels.find((l) => l.id === course.levelId)?.name;
  const category = data.categories.find((c) => c.id === course.categoryId)?.name;
  const teachers = course.instructorIds.map((id) => data.instructors.find((i) => i.id === id)).filter((i): i is NonNullable<typeof i> => !!i);
  const minutes = courseDurationMin(course);
  const lessons = course.chapters.reduce((n, ch) => n + ch.lessons.length, 0);
  const sale = saleDisplay(course);
  const learnPath = `/learn/${course.id}`;
  // A signed-in learner goes straight to the checkout; staff have a workspace and no purchases.
  const isLearner = API_MODE !== 'http' || (isAuthenticated && role === 'student');
  const isStaff = API_MODE === 'http' && isAuthenticated && role !== 'student';
  const enrolHref = isLearner ? learnPath : `/login?next=${encodeURIComponent(learnPath)}`;
  const registerHref = `/register?next=${encodeURIComponent(learnPath)}`;
  const actionLabel = sale.kind === 'paid' ? 'Buy now' : 'Enroll now';

  return (
    <div className={styles.coursePage}>
      <div className={styles.courseLayout}>
        <div className={styles.courseMain}>
          <header>
            <span className={styles.courseEyebrow}>
              {level}
              {level && category ? ' · ' : ''}
              {category}
            </span>
            <h1 className={styles.courseTitle}>{course.title}</h1>
            <p className={styles.courseSubtitle}>{course.subtitle}</p>
            <div className={styles.courseFacts}>
              {course.rating && <Rating value={course.rating} count={course.ratingCount} />}
              <span>
                <Users size={16} /> {course.enrolledCount === 1 ? '1 learner' : `${formatCount(course.enrolledCount)} learners`}
              </span>
              {minutes > 0 && (
                <span>
                  <Clock size={16} /> {formatDuration(minutes)}
                </span>
              )}
              <span>
                <Globe size={16} /> {FORMAT_LABEL[course.format]}
              </span>
              {course.certificateTitle && (
                <span>
                  <CertificateIcon size={16} /> Certificate
                </span>
              )}
            </div>
          </header>

          {course.description && (
            <section className={styles.courseSection} aria-labelledby="course-about">
              <h2 id="course-about">About this course</h2>
              <p className={styles.courseDescription}>{course.description}</p>
            </section>
          )}

          {course.outcomes.length > 0 && (
            <section className={styles.courseSection} aria-labelledby="course-outcomes">
              <h2 id="course-outcomes">What you’ll be able to do</h2>
              <ul className={styles.courseOutcomes}>
                {course.outcomes.map((o) => (
                  <li key={o}>
                    <CheckCircle size={18} weight="fill" /> {o}
                  </li>
                ))}
              </ul>
            </section>
          )}

          <section className={styles.courseSection} aria-labelledby="course-curriculum">
            <h2 id="course-curriculum">Curriculum</h2>
            <p className={styles.courseSectionNote}>
              {previews.length > 0
                ? 'Lessons marked as a free preview are open to everyone. The rest unlock when you enrol.'
                : 'Lessons unlock when you enrol.'}
            </p>
            <CourseCurriculum course={course} enrolled={false} />
          </section>

          {previews.some((l) => previewText(l)) && (
            <section className={styles.courseSection} aria-labelledby="course-preview">
              <h2 id="course-preview">
                <Eye size={20} /> A free preview
              </h2>
              {previews
                .filter((l) => previewText(l))
                .slice(0, 1)
                .map((l) => (
                  <article key={l.id} className={styles.coursePreview}>
                    <h3>{l.title}</h3>
                    <ArticleBody body={previewText(l)!} />
                  </article>
                ))}
            </section>
          )}

          {teachers.length > 0 && (
            <section className={styles.courseSection} aria-labelledby="course-teachers">
              <h2 id="course-teachers">{teachers.length === 1 ? 'Your instructor' : 'Your instructors'}</h2>
              <ul className={styles.courseTeachers}>
                {teachers.map((t) => (
                  <li key={t.id}>
                    <Avatar name={t.name} size={48} />
                    <div>
                      <strong className={styles.courseTeacherName}>
                        <Link to={`/mentors/${t.id}`}>{t.name}</Link>
                      </strong>
                      <span className={styles.courseBuyNote}>{t.title}</span>
                      {t.bio && <p className={styles.courseTeacherBio}>{t.bio}</p>}
                    </div>
                  </li>
                ))}
              </ul>
            </section>
          )}

          <CourseReviews slug={course.slug} />

          {sale.kind !== 'unavailable' && !isStaff && (
            <section className={styles.courseCta} aria-label="Enrol">
              <div className={styles.courseCtaText}>
                <strong>Ready to start {course.title}?</strong>
                {!isLearner && <span className={styles.courseBuyNote}>Log in or create an account to continue. Your progress stays with your account.</span>}
              </div>
              <div className={styles.courseCtaActions}>
                <LinkButton variant="primary" to={enrolHref} iconEnd={<ArrowRight size={16} />}>
                  {actionLabel}
                </LinkButton>
              </div>
            </section>
          )}

          {course.tags.length > 0 && (
            <ul className={styles.courseTags} aria-label="Topics">
              {course.tags.map((t) => (
                <li key={t}>
                  <Badge tone="neutral">{t}</Badge>
                </li>
              ))}
            </ul>
          )}
        </div>

        <aside className={styles.courseBuy} aria-label="Enrol">
          <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.courseBuyCover} />
          <span className={styles.coursePrice}>{sale.label}</span>
          {sale.kind === 'paid' && <span className={styles.courseBuyNote}>{ALL_INCLUSIVE}</span>}
          {sale.kind === 'unavailable' ? (
            <span className={styles.courseBuyNote}>This course isn’t open for enrolment yet.</span>
          ) : isStaff ? (
            <span className={styles.courseBuyNote}>You are signed in as staff. Log in with a learner account to buy or enrol.</span>
          ) : (
            <>
              <LinkButton variant="primary" to={enrolHref} iconEnd={<ArrowRight size={16} />}>
                {actionLabel}
              </LinkButton>
              {!isLearner && (
                <span className={styles.courseBuyNote}>
                  New here? <Link to={registerHref}>Create an account</Link> and come straight back.
                </span>
              )}
            </>
          )}
          <ul className={styles.courseBuyFacts}>
            <li>
              {plural(course.chapters.length, 'chapter')} · {plural(lessons, 'lesson')}
            </li>
            {previews.length > 0 && <li>{plural(previews.length, 'free preview lesson')}</li>}
            {course.estimatedWeeks ? <li>About {plural(course.estimatedWeeks, 'week')} at a steady pace</li> : null}
            {course.language && <li>Taught in {course.language === 'en-IN' ? 'English' : course.language}</li>}
          </ul>
        </aside>
      </div>
    </div>
  );
}
