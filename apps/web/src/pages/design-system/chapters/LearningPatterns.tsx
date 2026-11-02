import { useMemo, useState } from 'react';
import { Certificate, ClipboardText, Exam, VideoCamera } from '@phosphor-icons/react';
import type { CertificateRecord } from '@syniastrolms/domain';
import { courseProgress, evaluateRankLadder, lessonState, chapterProgress } from '@syniastrolms/domain';
import { useNow } from '@/hooks/useNow';
import { Badge } from '@/components/ui/Badge/Badge';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { ContinueLearningAction } from '@/components/lms/actions/ContinueLearningAction';
import { EnrollmentAction } from '@/components/lms/actions/EnrollmentAction';
import { LearningActivity } from '@/components/lms/activity/LearningActivity';
import { CertificateStatus } from '@/components/lms/certificate/CertificateStatus';
import { CourseCurriculum } from '@/components/lms/course/CourseCurriculum';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { CourseIdentity, CourseInstructor, CourseLevel } from '@/components/lms/course/CourseIdentity';
import { AssessmentStatus } from '@/components/lms/coursework/AssessmentStatus';
import { AssignmentStatus } from '@/components/lms/coursework/AssignmentStatus';
import { LearningJourney, type JourneyStep } from '@/components/lms/journey/LearningJourney';
import { LessonSegments, Meter, ScoreMeter, VideoProgress } from '@/components/lms/progress/Meters';
import { MilestoneTrack } from '@/components/lms/progress/MilestoneTrack';
import { ProgressRing } from '@/components/lms/progress/ProgressRing';
import { RankProgression } from '@/components/lms/rank/RankProgression';
import { LiveClassStatus } from '@/components/lms/schedule/LiveClassStatus';
import { WorkList } from '@/components/lms/shared/WorkRow';
import { ProgressTimeline, type TimelineItem } from '@/components/lms/timeline/ProgressTimeline';
import { categoryById, courses, foundationsCourse, instructorById, instructors, levels } from '@/services/mock/fixtures/catalog';
import {
  assessments,
  assignments,
  certificates,
  foundationsProgress,
  liveClasses,
  rankStanding,
  ranks,
  recentActivity,
  studyWeek,
} from '@/services/mock/fixtures/learner';
import { ChapterIntro, DocSection, Notes, Specimen } from '../doc/Doc';
import { chapterJourney, RESUME } from '../specimens/demoData';
import styles from './Chapters.module.css';

export default function LearningPatterns() {
  return (
    <>
      <ChapterIntro title="Learning patterns">
        The components future LMS modules are composed from. Each takes domain data — levels, courses, progress snapshots — and never assumes a particular
        taxonomy. Content here is real ZuviloAI curriculum on mock services.
      </ChapterIntro>
      <CourseSection />
      <ProgressSection />
      <JourneySection />
      <CurriculumSection />
      <TimelineSection />
      <RankSection />
      <LiveSection />
      <CourseworkSection />
      <CertificateSection />
      <ActivitySection />
      <ActionsSection />
    </>
  );
}

/* ─── Course identity ───────────────────────────────────────────────────── */

const COVER_NAMES = { houses: 'Grid', nakshatra: 'Star ring', orbits: 'Orbits', ecliptic: 'Arc' } as const;

function CourseSection() {
  const courseInstructors = foundationsCourse.instructorIds.map((id) => instructorById(id)!);
  return (
    <DocSection
      id="course"
      index={1}
      title="Course identity & metadata"
      lead="An editorial identity: category and level as a quiet eyebrow, the title in display type, a readable subtitle, then who teaches and what it takes. Covers are generated fine-line geometry, so the catalog stays coherent at any size."
      api={['CourseIdentity', 'CourseCover', 'CourseLevel', 'CourseMeta', 'CourseInstructor', 'EnrollmentAction']}
    >
      <div className={styles.courseStage}>
        <CourseIdentity
          course={foundationsCourse}
          levels={levels}
          category={categoryById(foundationsCourse.categoryId)}
          instructors={courseInstructors}
          headingLevel="h3"
          showCover={false}
        />
        <div className={styles.enrollPanel}>
          <EnrollmentAction course={foundationsCourse} />
        </div>
      </div>

      <Specimen label="Generated covers">
        <ul className={styles.covers}>
          {(['houses', 'nakshatra', 'orbits', 'ecliptic'] as const).map((motif) => (
            <li key={motif}>
              <CourseCover motif={motif} />
              <span className="type-caption tone-muted">{COVER_NAMES[motif]}</span>
            </li>
          ))}
        </ul>
      </Specimen>

      <Specimen
        label="Row identity · catalog lists"
        notes={
          <Notes
            items={[
              { term: 'Level', text: 'Ticks follow the number of levels in the data. Adding a fifth level adds a fifth tick — no component change.' },
              { term: 'Motifs', text: 'Grid, star ring, orbits, arc. Chosen per course in content, not code.' },
            ]}
          />
        }
      >
        <ul className={styles.courseRows}>
          {courses.slice(1).map((c) => (
            <li key={c.id}>
              <CourseIdentity
                course={c}
                variant="row"
                levels={levels}
                category={categoryById(c.categoryId)}
                instructors={c.instructorIds.map((id) => instructorById(id)!)}
                headingLevel="h3"
              />
              <Badge tone="neutral" appearance="outline">
                {c.format.replace('-', ' ')}
              </Badge>
            </li>
          ))}
        </ul>
      </Specimen>

      <div className={styles.rowLg}>
        {levels.map((l) => (
          <CourseLevel key={l.id} levelId={l.id} levels={levels} />
        ))}
        <CourseInstructor instructors={[instructors[1]]} />
      </div>
    </DocSection>
  );
}

/* ─── Progress ──────────────────────────────────────────────────────────── */

function ProgressSection() {
  const [value, setValue] = useState(38);
  const chapter3 = foundationsCourse.chapters[2];
  const chapterSegments = foundationsCourse.chapters.map((m) => chapterProgress(m, foundationsProgress).percent / 100);

  return (
    <DocSection
      id="progress"
      index={2}
      title="Progress system"
      lead="Progress is shown in the form that answers the learner’s question: how far (ring), how much is left (meter), where am I (segments), what’s next (milestones), and did I make it (score against a pass mark)."
      api={['ProgressRing', 'Meter', 'LessonSegments', 'VideoProgress', 'MilestoneTrack', 'ScoreMeter']}
    >
      <Specimen
        label="Rings"
        toolbar={
          <label className={styles.valueControl}>
            Value
            <input type="range" min={0} max={100} value={value} onChange={(e) => setValue(Number(e.target.value))} />
            <span className={styles.valueNumber}>{value}%</span>
          </label>
        }
      >
        <div className={styles.ringRow}>
          {(['xs', 'sm', 'md', 'lg', 'xl'] as const).map((size) => (
            <span key={size} className={styles.ringItem}>
              <ProgressRing
                value={value}
                size={size}
                label={`Progress ${size}`}
                caption={size === 'xl' ? 'Course' : undefined}
                threshold={size === 'xl' ? 80 : undefined}
              />
              <span className="type-meta">{size}</span>
            </span>
          ))}
          <span className={styles.radialFeature}>
            <ProgressRing
              value={courseProgress(foundationsCourse, foundationsProgress).percent}
              size="xl"
              segments={chapterSegments}
              label="Course progress by chapter"
              caption="7 chapters"
            />
            <ol className={styles.radialLegend}>
              {foundationsCourse.chapters.slice(0, 3).map((m, i) => (
                <li key={m.id}>
                  <span className="type-meta tabular">{String(i + 1).padStart(2, '0')}</span>
                  <span>{m.title}</span>
                  <span className="tabular">{chapterProgress(m, foundationsProgress).percent}%</span>
                </li>
              ))}
              <li>
                <span />
                <span className="type-meta">4 more chapters, locked</span>
                <span />
              </li>
            </ol>
          </span>
        </div>
      </Specimen>

      <div className={styles.progressGrid}>
        <div className={styles.progressItem}>
          <span className={styles.progressItemTitle}>Meter · with threshold</span>
          <Meter value={value} showLabel label="Course progress" threshold={80} valueText={`${value}% · certificate at 80%`} />
        </div>
        <div className={styles.progressItem}>
          <span className={styles.progressItemTitle}>Chapter · lesson segments</span>
          <LessonSegments
            label={chapter3.title}
            items={chapter3.lessons.map((l) => ({
              id: l.id,
              state: lessonState(l.id, foundationsProgress),
              fraction: foundationsProgress.lessons[l.id]?.fraction,
              title: l.title,
            }))}
            summary={`Chapter 3 · ${chapterProgress(chapter3, foundationsProgress).completed} of ${chapter3.lessons.length} lessons · assessment locked`}
          />
        </div>
        <div className={styles.progressItem}>
          <span className={styles.progressItemTitle}>Video</span>
          <VideoProgress positionSec={561} durationSec={1020} chapters={[240, 610]} />
        </div>
        <div className={styles.progressItem}>
          <span className={styles.progressItemTitle}>Assessment score</span>
          <ScoreMeter score={84} passMark={70} />
        </div>
      </div>

      <Specimen label="Milestones · certificate eligibility">
        <MilestoneTrack
          value={value}
          label="Course milestones"
          milestones={[
            { id: 'm2', at: 25, label: 'Chapter 2 check', detail: 'Passed 84%' },
            { id: 'mid', at: 50, label: 'Mid-course review', detail: 'Live, 1:1' },
            { id: 'cert', at: 80, label: 'Certificate eligible', icon: <Certificate size={12} />, emphasis: true },
            { id: 'done', at: 100, label: 'Course complete' },
          ]}
        />
      </Specimen>
    </DocSection>
  );
}

/* ─── Journey ───────────────────────────────────────────────────────────── */

const PLATFORM_JOURNEY: JourneyStep[] = [
  { id: 'discover', title: 'Discover', state: 'completed' },
  { id: 'level', title: 'Choose level', state: 'completed' },
  { id: 'enroll', title: 'Enroll', state: 'completed' },
  { id: 'learn', title: 'Learn & practise', state: 'in-progress', percent: 38 },
  { id: 'assess', title: 'Assessments', state: 'not-started' },
  { id: 'certify', title: 'Certificate', state: 'not-started' },
  { id: 'rank', title: 'Rank', state: 'not-started' },
  { id: 'community', title: 'Community', state: 'not-started' },
];

function JourneySection() {
  const steps = useMemo(chapterJourney, []);
  return (
    <DocSection
      id="journey"
      index={3}
      title="Learning journey"
      lead="A path drawn on the page, not in a box. Horizontal where each step can hold a readable title; a vertical rail in narrow containers. The current step carries its own progress ring and the next action."
      api={['LearningJourney']}
    >
      <div className={styles.journeyStack}>
        <LearningJourney
          steps={steps}
          label="Class 10 Mathematics chapters"
          currentId="m3"
          currentAction={<ContinueLearningAction resume={RESUME} variant="inline" />}
        />
        <Specimen label="Compact · the ZuviloAI learning journey">
          <LearningJourney steps={PLATFORM_JOURNEY} label="Your journey" currentId="learn" variant="compact" />
        </Specimen>
      </div>
    </DocSection>
  );
}

/* ─── Curriculum ────────────────────────────────────────────────────────── */

function CurriculumSection() {
  const [enrolled, setEnrolled] = useState<'enrolled' | 'preview'>('enrolled');
  const [density, setDensity] = useState<'immersive' | 'balanced' | 'dense'>('balanced');
  const toast = useToast();
  return (
    <DocSection
      id="curriculum"
      index={4}
      title="Curriculum"
      lead="Modules expand in place; lessons carry state, type, duration and — for the current lesson — a resume cue. Not enrolled, the same component shows preview lessons and locks the rest."
      api={['CourseCurriculum', 'LessonRow', 'LessonStatus', 'LessonDuration']}
    >
      <Specimen
        surface="panel"
        density={density}
        toolbar={
          <>
            <SegmentedControl
              label="Enrollment"
              size="sm"
              value={enrolled}
              onChange={setEnrolled}
              segments={[
                { value: 'enrolled', label: 'Enrolled' },
                { value: 'preview', label: 'Not enrolled' },
              ]}
            />
            <SegmentedControl
              label="Density"
              size="sm"
              value={density}
              onChange={setDensity}
              segments={[
                { value: 'immersive', label: 'Immersive' },
                { value: 'balanced', label: 'Balanced' },
                { value: 'dense', label: 'Dense' },
              ]}
            />
          </>
        }
        notes={
          <Notes
            items={[
              { term: 'Lesson state', text: 'Filled check · partial ring · hollow ring · dashed lock. Shape first, then tone.' },
              { term: 'Locked chapters', text: 'Say what unlocks them, in the chapter header, not in a tooltip.' },
              { term: 'Keyboard', text: 'Chapter headers are buttons with aria-expanded; collapsed lessons leave the tab order.' },
            ]}
          />
        }
      >
        <CourseCurriculum
          key={enrolled}
          course={foundationsCourse}
          snapshot={enrolled === 'enrolled' ? foundationsProgress : undefined}
          enrolled={enrolled === 'enrolled'}
          currentLessonId={enrolled === 'enrolled' ? foundationsProgress.lastLessonId : undefined}
          defaultOpen={enrolled === 'enrolled' ? undefined : ['m1']}
          onSelectLesson={(l) => toast({ kind: 'info', title: l.title, text: 'Opens the lesson in the player.' })}
        />
      </Specimen>
    </DocSection>
  );
}

/* ─── Timeline ──────────────────────────────────────────────────────────── */

function TimelineSection() {
  const now = useNow();
  const items: TimelineItem[] = [
    {
      id: 't1',
      at: '2026-09-09T18:45:00+05:30',
      title: 'Chapter 2 check: Polynomials',
      status: 'passed',
      statusLabel: 'Passed · 84%',
      kind: <Exam size={16} />,
    },
    {
      id: 't2',
      at: '2026-09-10T19:00:00+05:30',
      title: 'Pair of linear equations: graphs and solutions',
      status: 'completed',
      statusLabel: 'Attended',
      meta: 'Recording available',
      kind: <VideoCamera size={16} />,
    },
    {
      id: 't3',
      at: '2026-09-12T21:14:00+05:30',
      title: 'Sidereal and tropical: a short reflection',
      status: 'under-review',
      meta: 'Submitted on time',
      kind: <ClipboardText size={16} />,
    },
    {
      id: 't4',
      at: '2026-09-15T18:30:00+05:30',
      title: 'Reading dignities in real charts',
      status: 'live',
      meta: '46 attending',
      kind: <VideoCamera size={16} />,
    },
    {
      id: 't5',
      at: '2026-09-15T19:00:00+05:30',
      title: 'Doubt-clearing: Quadratic equations',
      status: 'starting-soon',
      statusLabel: 'Join window open',
      kind: <VideoCamera size={16} />,
    },
    {
      id: 't6',
      at: '2026-09-17T19:00:00+05:30',
      title: 'Trigonometry in practice: heights and distances',
      status: 'upcoming',
      meta: '90 min',
      kind: <VideoCamera size={16} />,
    },
    {
      id: 't7',
      at: '2026-09-19T23:59:00+05:30',
      title: 'Solve five quadratic equations, showing every step',
      status: 'draft',
      meta: 'Due',
      kind: <ClipboardText size={16} />,
    },
  ];
  // Items at or before "now" are behind the reader; the live item started before now.
  return (
    <DocSection
      id="timeline"
      index={5}
      title="Progress timeline"
      lead="What happened and what’s next, on one rail with a visible now. The elapsed rail is accent; the future is a neutral line."
      api={['ProgressTimeline']}
    >
      <ProgressTimeline items={items} now={now} label="This week in Class 10 Mathematics" />
    </DocSection>
  );
}

/* ─── Rank ──────────────────────────────────────────────────────────────── */

function RankSection() {
  const steps = evaluateRankLadder(ranks, rankStanding);
  return (
    <DocSection
      id="rank"
      index={6}
      title="Rank progression"
      lead="Beginner → Intermediate → Advanced → Expert. Prestige comes from typography and restraint: concentric orbits for maturity, a numeral for standing, and plain requirements for the next step."
      api={['RankProgression', 'RankEmblem', 'RankMeter']}
    >
      <RankProgression steps={steps} learnerName="Ananya" />
    </DocSection>
  );
}

/* ─── Live ──────────────────────────────────────────────────────────────── */

function LiveSection() {
  const now = useNow();
  const toast = useToast();
  return (
    <DocSection
      id="live"
      index={7}
      title="Live class states"
      lead="The phase is derived from the schedule and the clock — upcoming, starting soon (join opens 15 minutes before), live, ended with recording, recording expired, cancelled. Each phase offers exactly one next step."
      api={['LiveClassStatus', 'deriveLiveClassPhase']}
    >
      <WorkList label="Live classes">
        {liveClasses.map((c) => (
          <LiveClassStatus
            key={c.id}
            liveClass={c}
            now={now}
            instructorName={instructorById(c.instructorId)?.name}
            onJoin={() => toast({ kind: 'success', title: 'Joining live class', text: c.title })}
            onWatch={() => toast({ kind: 'info', title: 'Opening recording', text: c.title })}
            onRemind={() => toast({ kind: 'success', title: 'Reminder set', text: '15 minutes before the class' })}
          />
        ))}
      </WorkList>
    </DocSection>
  );
}

/* ─── Coursework ────────────────────────────────────────────────────────── */

function CourseworkSection() {
  const now = useNow();
  const toast = useToast();
  const chapterTitle = (id: string) => {
    const i = foundationsCourse.chapters.findIndex((m) => m.id === id);
    return i >= 0 ? `Chapter ${i + 1} · ${foundationsCourse.chapters[i].title}` : undefined;
  };
  return (
    <DocSection
      id="coursework"
      index={8}
      title="Assignment & assessment states"
      lead="Gradable work shares one row anatomy: what it is, when it’s due, where it stands, and the single next action. Scores appear as rings with the pass mark drawn on them."
      api={['AssignmentStatus', 'AssessmentStatus', 'WorkRow']}
    >
      <Specimen label="Assignments">
        <WorkList label="Assignments">
          {assignments.map((a) => (
            <AssignmentStatus
              key={a.id}
              assignment={a}
              chapterTitle={chapterTitle(a.chapterId)}
              now={now}
              onOpen={() => toast({ kind: 'info', title: a.title, text: 'Opens the assignment brief and submission.' })}
            />
          ))}
        </WorkList>
      </Specimen>
      <Specimen label="Assessments">
        <WorkList label="Assessments">
          {assessments.map((a) => (
            <AssessmentStatus key={a.id} assessment={a} now={now} onStart={() => toast({ kind: 'info', title: a.title, text: 'Starts the assessment.' })} />
          ))}
        </WorkList>
      </Specimen>
    </DocSection>
  );
}

/* ─── Certificates ──────────────────────────────────────────────────────── */

function CertificateSection() {
  const toast = useToast();
  const [records, setRecords] = useState<CertificateRecord[]>(certificates);

  const claim = (record: CertificateRecord) =>
    new Promise<void>((resolve) =>
      window.setTimeout(() => {
        setRecords((all) => all.map((r) => (r.id === record.id ? { ...r, issuedAt: '2026-09-15T18:52:00+05:30', credentialId: 'AD-PN-2026-11342' } : r)));
        toast({ kind: 'success', title: 'Certificate issued', text: record.title });
        resolve();
      }, 900),
    );

  return (
    <DocSection
      id="certificates"
      index={9}
      title="Certificate states"
      lead="Not yet eligible shows exactly what’s left; eligible offers one clear claim; issued becomes a credential with an ID that can be verified and shared."
      api={['CertificateStatus', 'CertificateSeal', 'certificateState']}
    >
      <div className={styles.certStack}>
        {records.map((r) => (
          <CertificateStatus key={r.id} record={r} onClaim={claim} onView={() => toast({ kind: 'info', title: r.title, text: 'Opens the certificate.' })} />
        ))}
      </div>
    </DocSection>
  );
}

/* ─── Activity ──────────────────────────────────────────────────────────── */

function ActivitySection() {
  const now = useNow();
  return (
    <DocSection
      id="activity"
      index={10}
      title="Learning activity"
      lead="A calm record of effort: seven days of study against a gentle goal, and what was done. No streak counters, no flames — consistency is shown, not gamified."
      api={['LearningActivity', 'StudyRhythm', 'ActivityFeed']}
    >
      <LearningActivity days={studyWeek} events={recentActivity} now={now} />
    </DocSection>
  );
}

/* ─── Actions ───────────────────────────────────────────────────────────── */

function ActionsSection() {
  const toast = useToast();
  return (
    <DocSection
      id="actions"
      index={11}
      title="Continue & enroll actions"
      lead="The two actions that move a learner forward. Continue carries enough context to be trusted at a glance; enrollment confirms, then turns into the next step in place."
      api={['ContinueLearningAction', 'EnrollmentAction', 'StickyActionBar']}
    >
      <div className={styles.continueStage}>
        <div className={styles.continuePanel}>
          <ContinueLearningAction resume={RESUME} onResume={() => toast({ kind: 'info', title: 'Resuming at 9:21', text: RESUME.lessonTitle })} />
        </div>
        <div className={styles.stack}>
          <span className={styles.progressItemTitle}>Inline</span>
          <ContinueLearningAction resume={RESUME} variant="inline" />
          <span className={styles.progressItemTitle}>Mobile sticky bar</span>
          <div className={styles.barPreview}>
            <ContinueLearningAction resume={RESUME} variant="bar" />
          </div>
          <p className={styles.caption}>On phones, the desktop aside becomes this bar, fixed above the bottom navigation. See Responsive.</p>
        </div>
      </div>

      <Specimen label="Enrollment states" surface="sunken">
        <div className={styles.enrollStates}>
          <div className={styles.enrollState}>
            <span className={styles.progressItemTitle}>Enrolled</span>
            <EnrollmentAction course={courses[2]} initialPhase="enrolled" />
          </div>
          <div className={styles.enrollState}>
            <span className={styles.progressItemTitle}>Closed</span>
            <EnrollmentAction course={courses[1]} initialPhase="closed" nextCohort="5 Oct 2026" />
          </div>
          <div className={styles.enrollState}>
            <span className={styles.progressItemTitle}>Error</span>
            <EnrollmentAction course={courses[3]} initialPhase="error" layout="inline" />
          </div>
        </div>
      </Specimen>
    </DocSection>
  );
}
