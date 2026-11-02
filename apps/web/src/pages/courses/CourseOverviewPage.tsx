import { Link } from 'react-router-dom';
import { ArrowRight, CheckCircle, Circle, RocketLaunch, UsersThree } from '@phosphor-icons/react';
import { chapterDisplayMin, courseLessons, publishChecklist, type LessonType } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatCount, formatDate, formatDuration, formatRelative, formatShortDate, pad2, plural } from '@/lib/format';
import { TrendChart } from '@/components/charts/Charts';
import { Figure } from '@/components/data/KpiStrip';
import { SectionHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { lessonTypeCount, lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { visibilityMeta } from '@/components/lms/course/CourseStatus';
import { Meter } from '@/components/lms/progress/Meters';
import { services } from '@/services';
import { UNSET_WARNING, pricingSummary } from '@/lib/coursePricing';
import { useCourseWorkspace } from './CourseLayout';
import styles from './CourseDetail.module.css';

const FORMAT_LABEL = { 'self-paced': 'Self-paced', cohort: 'Cohort', hybrid: 'Hybrid' } as const;

export default function CourseOverviewPage() {
  const { course, level, category, instructors, base, requestStatus } = useCourseWorkspace();
  const now = useNow();
  const stats = useAsync(`course-stats:${course.id}:${course.updatedAt}`, () => services.courses.stats(course.id));
  const lessons = courseLessons(course);
  const checks = publishChecklist(course);
  const unmet = checks.filter((c) => !c.met).length;
  const to = `${base}/courses/${course.id}`;
  const pricing = pricingSummary(course);

  const typeCounts = Object.entries(
    lessons.reduce<Record<string, number>>((acc, l) => {
      acc[l.type] = (acc[l.type] ?? 0) + 1;
      return acc;
    }, {}),
  ) as [LessonType, number][];

  return (
    <div className={styles.overview}>
      <div className={styles.overviewMain}>
        {/* Enrollment snapshot */}
        <section className={styles.panel} aria-labelledby="snapshot-title">
          <SectionHeader
            id="snapshot-title"
            title="Enrollment snapshot"
            description={
              course.status === 'published'
                ? 'Learners in this course right now'
                : course.status === 'archived'
                  ? 'Closed to new learners'
                  : 'Opens when the course is published'
            }
          />
          {stats.status === 'error' && !stats.data ? (
            <InlineMessage
              kind="error"
              title="Enrollment figures didn’t load."
              action={
                <Button size="sm" onClick={() => stats.run().catch(() => undefined)}>
                  Retry
                </Button>
              }
            >
              {stats.error.message}
            </InlineMessage>
          ) : !stats.data ? (
            <div className={styles.snapshotSkeleton}>
              <Skeleton height={48} radius="var(--r-sm)" />
              <Skeleton height={180} radius="var(--r-md)" />
            </div>
          ) : stats.data.enrolled === 0 ? (
            <div className={styles.snapshotEmpty}>
              <UsersThree size={28} aria-hidden="true" />
              <div>
                <p className={styles.snapshotEmptyTitle}>No learners yet</p>
                <p className={styles.snapshotEmptyText}>
                  {course.status === 'draft'
                    ? unmet
                      ? `Finish ${plural(unmet, 'publishing item')} and publish to open enrollment.`
                      : 'Everything is in place. Publish to open enrollment.'
                    : 'Share the course link or add learners to start the first cohort.'}
                </p>
              </div>
              {course.status === 'draft' && (
                <Button variant={unmet ? 'secondary' : 'primary'} iconStart={<RocketLaunch size={16} />} onClick={() => requestStatus('publish')}>
                  {unmet ? 'Review checklist' : 'Publish'}
                </Button>
              )}
            </div>
          ) : (
            <>
              <dl className={styles.figures}>
                <Figure label="enrolled" value={formatCount(stats.data.enrolled)} />
                <Figure label="active in 14 days" value={formatCount(stats.data.active)} />
                <Figure label="completion rate" value={`${stats.data.completionRate}%`} />
                <Figure label="average progress" value={`${stats.data.avgProgress}%`} />
              </dl>
              <TrendChart
                data={stats.data.weekly.map((p) => ({ label: formatShortDate(p.date), detail: `Week of ${formatShortDate(p.date)}`, value: p.value }))}
                label={`Weekly new enrollments in ${course.title}, last 12 weeks`}
                unit="new learners"
                height={180}
              />
              <div className={styles.snapshotSplit}>
                <div>
                  <h3 className={styles.subhead}>Where learners are</h3>
                  <ul className={styles.buckets}>
                    {stats.data.progressBuckets.map((b) => (
                      <li key={b.label}>
                        <span className={styles.bucketLabel}>{b.label}</span>
                        <Meter value={stats.data!.enrolled ? (b.value / stats.data!.enrolled) * 100 : 0} size="sm" label={`${b.label}: ${b.value} learners`} />
                        <span className={styles.bucketValue}>{formatCount(b.value)}</span>
                      </li>
                    ))}
                  </ul>
                </div>
                <div>
                  <h3 className={styles.subhead}>Recent enrollments</h3>
                  <ul className={styles.recent}>
                    {stats.data.recent.map((r) => (
                      <li key={r.studentId}>
                        <Avatar name={r.name} size={28} />
                        <span className={styles.recentText}>
                          <span className={styles.recentName}>{r.name}</span>
                          <span className={styles.recentMeta}>
                            Enrolled {formatRelative(r.enrolledAt, now)} · {r.progress}% complete
                          </span>
                        </span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </>
          )}
        </section>

        {/* About */}
        <section aria-labelledby="about-title">
          <SectionHeader
            id="about-title"
            title="About this course"
            actions={
              <LinkButton to={`${to}/edit`} variant="ghost" size="sm">
                Edit
              </LinkButton>
            }
          />
          <div className={styles.prose}>
            {course.subtitle ? <p className={styles.lead}>{course.subtitle}</p> : <p className={styles.missing}>No subtitle yet.</p>}
            {course.description ? <p>{course.description}</p> : <p className={styles.missing}>No description yet — learners see this on the course page.</p>}
          </div>
          <h3 className={styles.subhead}>What learners will be able to do</h3>
          {course.outcomes.length ? (
            <ol className={styles.outcomes}>
              {course.outcomes.map((o, i) => (
                <li key={o}>
                  <span className={styles.outcomeIndex} aria-hidden="true">
                    {pad2(i + 1)}
                  </span>
                  {o}
                </li>
              ))}
            </ol>
          ) : (
            <p className={styles.missing}>No learning outcomes yet. They’re optional — a few help learners decide to enrol.</p>
          )}
          {course.tags.length > 0 && (
            <div className={styles.tags} aria-label="Tags">
              {course.tags.map((t) => (
                <Badge key={t} size="sm">
                  {t}
                </Badge>
              ))}
            </div>
          )}
        </section>

        {/* Curriculum summary */}
        <section aria-labelledby="curriculum-title">
          <SectionHeader
            id="curriculum-title"
            title="Curriculum"
            description={
              course.chapters.length
                ? `${plural(course.chapters.length, 'chapter')} · ${plural(lessons.length, 'lesson')} · ${formatDuration(lessons.reduce((n, l) => n + l.durationMin, 0))}`
                : 'No chapters yet'
            }
            actions={
              <LinkButton to={`${to}/curriculum`} variant="ghost" size="sm" iconEnd={<ArrowRight size={14} />}>
                Open curriculum
              </LinkButton>
            }
          />
          {typeCounts.length > 0 && (
            <ul className={styles.typeCounts} aria-label="Lessons by type">
              {typeCounts.map(([type, count]) => (
                <li key={type}>
                  {lessonTypeMeta[type].icon}
                  <span className="tabular">{lessonTypeCount(type, count)}</span>
                </li>
              ))}
            </ul>
          )}
          {course.chapters.length ? (
            <ol className={styles.chapterList}>
              {course.chapters.map((c, i) => (
                <li key={c.id}>
                  <span className={styles.chapterIndex}>{pad2(i + 1)}</span>
                  <Link to={`${to}/chapters/${c.id}`} className={styles.chapterTitle}>
                    {c.title}
                  </Link>
                  {c.status === 'draft' && (
                    <Badge size="sm" tone="warn">
                      Draft
                    </Badge>
                  )}
                  <span className={styles.chapterMeta}>
                    {plural(c.lessons.length, 'lesson')} · {formatDuration(chapterDisplayMin(c))}
                  </span>
                </li>
              ))}
            </ol>
          ) : (
            <p className={styles.missing}>Chapters group lessons around one idea. Open the curriculum to plan them.</p>
          )}
        </section>
      </div>

      <aside className={styles.overviewAside}>
        {course.status === 'draft' && (
          <section className={styles.asideBlock} aria-labelledby="ready-title">
            <h2 id="ready-title" className={styles.asideTitle}>
              Publishing checklist
              <span className={styles.asideCount}>
                {checks.length - unmet}/{checks.length}
              </span>
            </h2>
            <ul className={styles.checks}>
              {checks.map((c) => (
                <li key={c.id} className={c.met ? styles.checkDone : undefined}>
                  {c.met ? <CheckCircle size={16} weight="fill" /> : <Circle size={16} />}
                  {c.label}
                  <span className="sr-only">{c.met ? ' — done' : ' — to do'}</span>
                </li>
              ))}
            </ul>
            <Button block variant={unmet ? 'secondary' : 'primary'} iconStart={<RocketLaunch size={16} />} onClick={() => requestStatus('publish')}>
              {unmet ? `${plural(unmet, 'item')} left` : 'Publish course'}
            </Button>
          </section>
        )}

        <section className={styles.asideBlock} aria-labelledby="details-title">
          <h2 id="details-title" className={styles.asideTitle}>
            Details
          </h2>
          {pricing.unset && (
            <InlineMessage
              kind="warn"
              action={
                base === '/admin' ? (
                  <LinkButton size="sm" to={`${to}/edit`}>
                    Choose
                  </LinkButton>
                ) : undefined
              }
            >
              {base === '/admin' ? UNSET_WARNING : 'Learners can’t join this course until an admin chooses Free or Paid.'}
            </InlineMessage>
          )}
          <dl className={styles.details}>
            <div>
              <dt>Pricing</dt>
              <dd>{pricing.label}</dd>
            </div>
            <div>
              <dt>Level</dt>
              <dd>{level?.name}</dd>
            </div>
            <div>
              <dt>Category</dt>
              <dd>{category?.name}</dd>
            </div>
            <div>
              <dt>Format</dt>
              <dd>{FORMAT_LABEL[course.format]}</dd>
            </div>
            <div>
              <dt>Visibility</dt>
              <dd>{visibilityMeta[course.visibility].label}</dd>
            </div>
            <div>
              <dt>Language</dt>
              <dd>{course.language}</dd>
            </div>
            {course.estimatedWeeks && (
              <div>
                <dt>Suggested pace</dt>
                <dd>{plural(course.estimatedWeeks, 'week')}</dd>
              </div>
            )}
            <div>
              <dt>Live sessions</dt>
              <dd>{course.liveSessions}</dd>
            </div>
            <div>
              <dt>Certificate</dt>
              <dd>{course.certificateTitle ?? 'None'}</dd>
            </div>
            <div>
              <dt>Created</dt>
              <dd>{formatDate(course.createdAt)}</dd>
            </div>
            {course.publishedAt && (
              <div>
                <dt>First published</dt>
                <dd>{formatDate(course.publishedAt)}</dd>
              </div>
            )}
          </dl>
        </section>

        <section className={styles.asideBlock} aria-labelledby="instructors-title">
          <h2 id="instructors-title" className={styles.asideTitle}>
            {instructors.length === 1 ? 'Instructor' : 'Instructors'}
          </h2>
          {instructors.length ? (
            <ul className={styles.instructors}>
              {instructors.map((i) => (
                <li key={i.id}>
                  <Avatar name={i.name} size={36} />
                  <span className={styles.recentText}>
                    {base === '/admin' ? (
                      <Link to={`/admin/instructors/${i.id}`} className={styles.instructorName}>
                        {i.name}
                      </Link>
                    ) : (
                      <span className={styles.instructorName}>{i.name}</span>
                    )}
                    <span className={styles.recentMeta}>{i.title}</span>
                  </span>
                </li>
              ))}
            </ul>
          ) : (
            <p className={styles.missing}>No instructor assigned.</p>
          )}
        </section>
      </aside>
    </div>
  );
}
