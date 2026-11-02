import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { BookOpenText, Flask, Play } from '@phosphor-icons/react';
import { courseProgress, evaluateRankLadder } from '@syniastrolms/domain';
import { useNow } from '@/hooks/useNow';
import { formatDuration } from '@/lib/format';
import { Button } from '@/components/ui/Button/Button';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { ContinueLearningAction } from '@/components/lms/actions/ContinueLearningAction';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { LearningActivity } from '@/components/lms/activity/LearningActivity';
import { CourseCurriculum } from '@/components/lms/course/CourseCurriculum';
import { CourseIdentity, CourseMeta, courseMetaItems } from '@/components/lms/course/CourseIdentity';
import { LearningJourney } from '@/components/lms/journey/LearningJourney';
import { VideoProgress } from '@/components/lms/progress/Meters';
import { ProgressRing } from '@/components/lms/progress/ProgressRing';
import { RankProgression } from '@/components/lms/rank/RankProgression';
import { NotFoundPage } from '@/pages/NotFoundPage';
import { categoryById, foundationsCourse, instructorById, levels } from '@/services/mock/fixtures/catalog';
import { foundationsProgress, rankStanding, ranks, recentActivity, studyWeek } from '@/services/mock/fixtures/learner';
import { LearnerManagement } from '../specimens/LearnerManagement';
import { chapterJourney, RESUME } from '../specimens/demoData';
import styles from '../specimens/Specimens.module.css';
import { SPECIMENS, type SpecimenId } from './specimens';

/**
 * Composition studies — foundation components assembled the way product screens will be,
 * to verify responsive behaviour in the real shell. They are not the product screens.
 */
export default function SpecimenRoute() {
  const { specimen } = useParams<{ specimen: SpecimenId }>();
  if (!specimen || !(specimen in SPECIMENS)) return <NotFoundPage />;

  return (
    <>
      <p className={styles.specimenNote}>
        <Flask size={14} /> Composition study · {SPECIMENS[specimen].label}
      </p>
      {specimen === 'course-overview' && <CourseOverview />}
      {specimen === 'lesson-canvas' && <LessonCanvas />}
      {specimen === 'learner-management' && (
        <div className={styles.specimenWide} data-density="dense">
          <LearnerManagement />
        </div>
      )}
      {specimen === 'standing' && <Standing />}
    </>
  );
}

function CourseOverview() {
  const progress = courseProgress(foundationsCourse, foundationsProgress);
  const aside = (
    <div className={styles.overviewPanel}>
      <div className={styles.overviewProgress}>
        <ProgressRing value={progress.percent} size="lg" label="Course progress" caption="Complete" threshold={80} />
        <div>
          <div className="type-h4">
            {progress.completed} of {progress.total} lessons
          </div>
          <div className="type-caption tone-muted">{formatDuration(progress.remainingMin)} left · certificate at 80%</div>
        </div>
      </div>
      <ContinueLearningAction resume={RESUME} />
    </div>
  );

  return (
    <div className={styles.specimenPage}>
      <div className={styles.overview}>
        <div className={styles.overviewMain}>
          <CourseIdentity
            course={foundationsCourse}
            levels={levels}
            category={categoryById(foundationsCourse.categoryId)}
            instructors={foundationsCourse.instructorIds.map((id) => instructorById(id)!)}
          />
          <section>
            <h2 className={styles.overviewSectionTitle}>Your path</h2>
            <LearningJourney steps={chapterJourney()} label="Chapters" currentId="m3" />
          </section>
          <section>
            <h2 className={styles.overviewSectionTitle}>Curriculum</h2>
            <CourseCurriculum course={foundationsCourse} snapshot={foundationsProgress} currentLessonId={foundationsProgress.lastLessonId} />
          </section>
        </div>
        <aside className={styles.overviewAside}>
          <StickyActionBar mobile={<ContinueLearningAction resume={RESUME} variant="bar" />}>{aside}</StickyActionBar>
          <CourseMeta variant="list" items={courseMetaItems(foundationsCourse)} />
        </aside>
      </div>
    </div>
  );
}

function LessonCanvas() {
  const [panel, setPanel] = useState(false);
  const curriculum = (
    <CourseCurriculum
      course={foundationsCourse}
      snapshot={foundationsProgress}
      currentLessonId={foundationsProgress.lastLessonId}
      onSelectLesson={() => setPanel(false)}
    />
  );

  return (
    <div className={styles.lesson} data-density="immersive">
      <article className={styles.lessonCanvas}>
        <div className={styles.lessonInner}>
          <span className="type-eyebrow">Chapter 03 · Lesson 5 of 8</span>
          <h1 className={styles.lessonTitle}>Quadratic equations: the formula and its roots</h1>
          <VideoProgress positionSec={561} durationSec={1020} chapters={[240, 610]} />
          <div className={`${styles.lessonProse} type-reading`}>
            <p>
              A quadratic equation — <em>ax² + bx + c = 0</em> with a ≠ 0 — has at most two roots. Factorising finds them when the numbers are friendly; the
              quadratic formula finds them every time, which is why it is worth learning to use it without hesitation.
            </p>
            <h3>Reading the discriminant</h3>
            <p>
              Begin with the discriminant, b² − 4ac. When it is positive the equation has two distinct real roots; when it is zero, two equal roots; and when it
              is negative, no real roots at all. Work it out before anything else — it tells you what kind of answer to expect before you find it.
            </p>
            <p>
              Always check a root by putting it back into the equation. Board examiners give marks for the method, but only a checked answer is safe — the check
              takes a few seconds and catches most slips.
            </p>
          </div>
          <div className={styles.lessonTools}>
            <Button className={styles.lessonPanelTrigger} iconStart={<BookOpenText size={16} />} onClick={() => setPanel(true)}>
              Curriculum
            </Button>
            <Button variant="primary" size="lg" iconStart={<Play size={15} weight="fill" />}>
              Continue video
            </Button>
          </div>
        </div>
      </article>
      <aside className={styles.lessonSide} aria-label="Curriculum">
        {curriculum}
      </aside>
      <AdaptivePanel open={panel} onClose={() => setPanel(false)} eyebrow={foundationsCourse.title} title="Curriculum">
        {curriculum}
      </AdaptivePanel>
    </div>
  );
}

function Standing() {
  const now = useNow();
  return (
    <div className={styles.specimenPage}>
      <div className={styles.overviewMain}>
        <RankProgression steps={evaluateRankLadder(ranks, rankStanding)} learnerName="Ananya" />
        <LearningActivity days={studyWeek} events={recentActivity} now={now} />
      </div>
    </div>
  );
}
