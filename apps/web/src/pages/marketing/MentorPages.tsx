import { useEffect, useMemo } from 'react';
import { useParams } from 'react-router-dom';
import { metaDescription, setPageMeta } from '@/app/pageMeta';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { plural } from '@/lib/format';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import { MentorCard, MentorPhoto } from './MentorCard';
import { PublicCourseCard } from './PublicCourseCard';
import { CtaBanner, PageHero } from './SiteParts';
import styles from './Home.module.css';
import marketing from './Marketing.module.css';
import site from './Site.module.css';

/* The mentors (docs/17): every name, title and biography is the platform's own record of an instructor teaching a listed course. */

/** `/mentors`. */
export function MentorsPage() {
  const query = useAsync('site:mentors', () => services.site.mentors());
  return (
    <MarketingChrome>
      <PageHero eyebrow="Our mentors" title="Learn from experienced instructors">
        Meet the people who teach on ZuviloAI, and see the courses each of them offers.
      </PageHero>
      <section className={marketing.section} aria-label="Mentors">
        {query.status === 'error' && !query.data ? (
          <StateMessage
            kind="error"
            title="The mentors didn’t load"
            actions={
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            }
          >
            {query.error.message}
          </StateMessage>
        ) : !query.data ? (
          <div className={styles.mentorGrid} aria-busy="true">
            {[0, 1, 2, 3].map((i) => (
              <Skeleton key={i} height={280} radius="var(--r-lg)" />
            ))}
          </div>
        ) : query.data.length === 0 ? (
          <StateMessage title="Our mentors will appear here">Instructors are listed here once their first course is published.</StateMessage>
        ) : (
          <ul className={styles.mentorGrid}>
            {query.data.map((m) => (
              <MentorCard key={m.id} mentor={m} headingLevel="h2" />
            ))}
          </ul>
        )}
      </section>
      <CtaBanner title="Want to teach here too?" to="/become-an-instructor" action="Become an instructor">
        Tell us what you teach. Our team reviews every application.
      </CtaBanner>
    </MarketingChrome>
  );
}

/** `/mentors/:id`. */
export function MentorProfilePage() {
  const { id = '' } = useParams();
  const query = useAsync(`site:mentor:${id}`, () =>
    Promise.all([services.site.mentor(id), services.catalog.listCourses(), services.catalog.listInstructors()]).then(([found, courses, instructors]) => ({
      ...found,
      courses,
      instructors,
    })),
  );
  const data = query.data;
  const courses = useMemo(() => (data ? data.courses.filter((c) => data.courseSlugs.includes(c.slug)) : []), [data]);

  useEffect(() => {
    if (data)
      setPageMeta({
        title: `${data.mentor.name} · ZuviloAI`,
        description: metaDescription(data.mentor.bio || data.mentor.title),
        path: `/mentors/${data.mentor.id}`,
      });
  }, [data]);

  if (query.status === 'error' && !data) {
    const missing = (query.error as { code?: string }).code === 'not-found';
    return (
      <MarketingChrome>
        <StateMessage
          kind={missing ? 'empty' : 'error'}
          title={missing ? 'This mentor isn’t available' : 'The profile didn’t load'}
          actions={
            missing ? (
              <LinkButton variant="primary" to="/mentors">
                Meet all mentors
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {missing ? 'They may no longer be teaching a listed course.' : query.error.message}
        </StateMessage>
      </MarketingChrome>
    );
  }
  if (!data) {
    return (
      <MarketingChrome>
        <Skeleton height={420} radius="var(--r-lg)" />
      </MarketingChrome>
    );
  }
  const { mentor } = data;
  const facts = [
    mentor.yearsTeaching != null && mentor.yearsTeaching > 0 ? `${plural(mentor.yearsTeaching, 'year')} teaching` : null,
    mentor.city || null,
    mentor.languages.length > 0 ? mentor.languages.join(', ') : null,
    plural(mentor.courseCount, 'course'),
  ].filter(Boolean);
  return (
    <MarketingChrome>
      <section className={marketing.section}>
        <div className={styles.detailMain}>
          <header className={styles.mentorHead}>
            <MentorPhoto mentor={mentor} size={120} />
            <div>
              <span className={styles.eyebrow}>Mentor</span>
              <h1>{mentor.name}</h1>
              {mentor.title && <p className={styles.detailLead}>{mentor.title}</p>}
              <p className={styles.postMeta}>{facts.join(' · ')}</p>
            </div>
          </header>
          {mentor.bio && <p className={styles.detailText}>{mentor.bio}</p>}
          {mentor.expertise.length > 0 && (
            <ul className={styles.mentorChips} aria-label="Expertise">
              {mentor.expertise.map((e) => (
                <li key={e}>
                  <Badge tone="neutral">{e}</Badge>
                </li>
              ))}
            </ul>
          )}
          <section aria-labelledby="mentor-courses">
            <h2 id="mentor-courses">Courses by {mentor.name}</h2>
            <ul className={site.courseGrid}>
              {courses.map((c) => (
                <PublicCourseCard key={c.id} course={c} instructors={data.instructors} showActions />
              ))}
            </ul>
          </section>
        </div>
      </section>
    </MarketingChrome>
  );
}
