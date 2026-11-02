/* The sample education catalogue: thirteen courses for school classes and Indian competitive exams (Rajasthan state
 * exams, SSC, reasoning and aptitude), with licensed cover images, curriculum, playable slide lectures, PDF notes,
 * quizzes and assignments — written into ONE existing academy, given by slug.
 *
 * All text, questions, lectures and notes are original to this repository. Faculty are subject-team profiles, not
 * invented people; no ratings are set and enrolment counts are the real ones.
 *
 * It never creates or changes an account. Learner activity — enrolments, progress, a quiz attempt, a graded
 * assignment, live classes and notifications — is written only for an explicitly named `.test` demo learner outside
 * production, so a real learner never sees fabricated progress or a class that will not happen.
 *
 * Safe to run again: every row has a fixed id under `edu-` and is written with an upsert, so a rerun updates the
 * same rows. No surrounding transaction — the tenancy guard checks each reference through its own connection, which
 * cannot see uncommitted rows — so rows are written in dependency order and an interrupted run is completed by the
 * next. Files are stored the way uploads are: a `MediaAsset` row plus the file in UPLOAD_DIR.
 *
 * Entry point: `scripts/seed-education.ts`. Asset credits: demo-assets/education/CREDITS.md. */
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import path from 'node:path';

import { scoreAttempt, type QuizAnswers, type QuizQuestion } from '@syniastrolms/domain';

import { asPlatform, forTenant } from '../src/lib/db.js';
import { learnerRules, progressOf, snapshotFor } from '../src/lib/learning.js';
import { COURSE_INCLUDE, mapCourse } from '../src/lib/mapCourse.js';
import { ensureUploadDir } from '../src/lib/media.js';
import { runInTenant } from '../src/lib/tenancy.js';
import { studyNotePdf, type PdfSection } from './demoPdf.js';

const ASSETS = path.resolve(import.meta.dirname, 'demo-assets/education');
const DAY = 86_400_000;
const eid = (kind: string, key: string) => `edu-${kind}-${key}`;

/** Refuses production and anything not explicitly development or staging (`test` is the suite) — for demo learner activity. */
export function assertDemoEnvironment(env: NodeJS.ProcessEnv = process.env): void {
  const nodeEnv = env.NODE_ENV;
  if (nodeEnv !== 'development' && nodeEnv !== 'staging' && nodeEnv !== 'test')
    throw new Error(`Demo learner activity is for development and staging only; NODE_ENV is ${nodeEnv ? `"${nodeEnv}"` : 'not set'}.`);
  if (/prod/i.test(env.DATABASE_URL ?? '')) throw new Error(`DATABASE_URL (${env.DATABASE_URL}) looks like a production database.`);
}

/* ─── Data ────────────────────────────────────────────────────────────── */

type LevelKey = 'foundation' | 'complete' | 'advanced';
type CategoryKey = 'rajasthan' | 'central' | 'aptitude' | 'school-9-10' | 'school-11-12';
type FacultyKey = 'rajasthan-gk' | 'general-studies' | 'aptitude' | 'pedagogy' | 'school-maths' | 'school-science' | 'languages';

const LEVELS: { key: LevelKey; name: string; order: number; summary: string }[] = [
  { key: 'foundation', name: 'Foundation', order: 1, summary: 'Starts from the basics' },
  { key: 'complete', name: 'Complete Course', order: 2, summary: 'The full syllabus' },
  { key: 'advanced', name: 'Advanced', order: 3, summary: 'Higher-level topics and practice' },
];

const CATEGORIES: { key: CategoryKey; name: string; description: string; glyph: string; order: number; levels: LevelKey[] }[] = [
  {
    key: 'rajasthan',
    name: 'Rajasthan State Exams',
    description: 'RAS, Patwari, REET and Rajasthan GK — RPSC and RSMSSB exams.',
    glyph: 'compass',
    order: 1,
    levels: ['foundation', 'complete'],
  },
  {
    key: 'central',
    name: 'Central Exams & General Studies',
    description: 'SSC exams and the general studies every exam asks.',
    glyph: 'lotus',
    order: 2,
    levels: ['foundation', 'complete'],
  },
  {
    key: 'aptitude',
    name: 'Reasoning & Maths',
    description: 'Reasoning and quantitative aptitude for every exam.',
    glyph: 'hourglass',
    order: 3,
    levels: ['foundation'],
  },
  { key: 'school-9-10', name: 'Class 9–10', description: 'CBSE and RBSE board subjects for classes 9 and 10.', glyph: 'sun', order: 4, levels: ['complete'] },
  { key: 'school-11-12', name: 'Class 11–12', description: 'Science stream subjects for classes 11 and 12.', glyph: 'moon', order: 5, levels: ['advanced'] },
];

/** Subject teams, not invented people: an admin replaces them with the real teachers. */
const FACULTY: { key: FacultyKey; name: string; expertise: string[] }[] = [
  { key: 'rajasthan-gk', name: 'Rajasthan GK Faculty', expertise: ['Rajasthan history', 'Rajasthan geography', 'Art and culture'] },
  { key: 'general-studies', name: 'General Studies Faculty', expertise: ['Indian polity', 'General awareness'] },
  { key: 'aptitude', name: 'Reasoning & Maths Faculty', expertise: ['Reasoning', 'Quantitative aptitude'] },
  { key: 'pedagogy', name: 'Teaching Aptitude Faculty', expertise: ['Child development', 'Pedagogy'] },
  { key: 'school-maths', name: 'School Mathematics Faculty', expertise: ['Algebra', 'Geometry', 'Trigonometry'] },
  { key: 'school-science', name: 'School Science Faculty', expertise: ['Physics', 'Chemistry', 'Biology'] },
  { key: 'languages', name: 'English & Hindi Faculty', expertise: ['English grammar', 'Writing skills'] },
];

type LessonDef =
  | { key: string; type: 'reading' | 'practice'; title: string; minutes: number; body: string }
  | {
      key: string;
      type: 'video';
      title: string;
      minutes: number;
      lecture: string;
      seconds: number;
      description: string;
      markers: { atSec: number; title: string }[];
    }
  | { key: string; type: 'document'; title: string; minutes: number; note: string; description: string }
  | { key: string; type: 'assessment'; title: string; minutes: number; quiz: string }
  | { key: string; type: 'assignment'; title: string; minutes: number; assignment: string };

interface CourseDef {
  key: string;
  title: string;
  subtitle: string;
  description: string;
  level: LevelKey;
  category: CategoryKey;
  motif: 'orbits' | 'houses' | 'ecliptic';
  faculty: FacultyKey[];
  price: number;
  weeks: number;
  outcomes: string[];
  tags: string[];
  chapters: { key: string; title: string; summary: string; objective: string; lessons: LessonDef[] }[];
}

const COURSES: CourseDef[] = [
  {
    key: 'ras-prelims',
    title: 'RAS Prelims Foundation Batch',
    subtitle: 'राजस्थान प्रशासनिक सेवा प्रारंभिक परीक्षा · Rajasthan GK, geography, polity and exam strategy, in Hindi and English.',
    description:
      'A foundation batch for the RPSC Rajasthan Administrative Services preliminary exam. It starts with the topics most often asked about the state — how Rajasthan was formed and its physical geography — and builds towards the full general-studies syllabus, with notes, a recorded lecture and a practice test.',
    level: 'foundation',
    category: 'rajasthan',
    motif: 'houses',
    faculty: ['rajasthan-gk', 'general-studies'],
    price: 4999,
    weeks: 16,
    outcomes: [
      'Explain the seven stages of Rajasthan’s integration',
      'Describe Rajasthan’s physical divisions',
      'Plan your preparation around the RAS exam stages',
    ],
    tags: ['RAS', 'RPSC', 'Bilingual'],
    chapters: [
      {
        key: 'state',
        title: 'Rajasthan: integration and geography',
        summary: 'How the state was formed, and its land.',
        objective: 'By the end of this chapter, you can list the integration stages and the physical divisions of Rajasthan.',
        lessons: [
          {
            key: 'formation',
            type: 'reading',
            title: 'Formation of Rajasthan at a glance | राजस्थान का एकीकरण',
            minutes: 10,
            body: 'Rajasthan was formed by joining the princely states of Rajputana in seven stages, from the Matsya Union on 18 March 1948 to the reorganisation of 1 November 1956, when Abu, Delwara and Ajmer-Merwara joined the state.\n\nThe fourth stage, on 30 March 1949, brought the large states of Jaipur, Jodhpur, Bikaner and Jaisalmer into Greater Rajasthan and made Jaipur the capital. That is why 30 March is celebrated as Rajasthan Diwas.',
          },
          {
            key: 'integration-lecture',
            type: 'video',
            title: 'Integration of Rajasthan in 7 stages',
            minutes: 1,
            lecture: 'rajasthan-integration',
            seconds: 48,
            description: 'A short silent slide lecture: every stage with its date and what changed.',
            markers: [
              { atSec: 12, title: 'Stages 1–3' },
              { atSec: 24, title: 'Stages 4–5' },
              { atSec: 36, title: 'Stages 6–7' },
            ],
          },
          {
            key: 'ekikaran-notes',
            type: 'document',
            title: 'Ekikaran notes (PDF)',
            minutes: 5,
            note: 'rajasthan-ekikaran',
            description: 'All seven stages in one printable table.',
          },
          {
            key: 'physical-divisions',
            type: 'reading',
            title: 'Physical divisions of Rajasthan | राजस्थान के भौतिक विभाग',
            minutes: 12,
            body: 'Rajasthan is usually described in four physical divisions: the north-western sandy desert (the Thar), the Aravalli hill region, the eastern plains, and the south-eastern plateau of Hadoti.\n\nThe Aravalli range crosses the state from south-west to north-east and divides the dry west from the wetter east. Its highest peak, Guru Shikhar (about 1,722 m), is at Mount Abu in Sirohi district. Jaisalmer is the largest district by area.',
          },
          { key: 'basics-test', type: 'assessment', title: 'Practice test: Rajasthan basics', minutes: 10, quiz: 'ras-basics' },
        ],
      },
      {
        key: 'strategy',
        title: 'Exam strategy',
        summary: 'How the exam works and how to plan.',
        objective: 'By the end of this chapter, you have a written study plan for the prelims.',
        lessons: [
          {
            key: 'exam-stages',
            type: 'reading',
            title: 'How the RAS exam is structured',
            minutes: 8,
            body: 'RPSC selects candidates for the Rajasthan State and Subordinate Services in three stages: a preliminary exam, a main exam and an interview. The preliminary exam is an objective screening paper on general knowledge and general science; it decides who may sit the mains, and its marks do not count in the final merit list.\n\nPatterns and syllabi are revised from time to time, so always read the latest RPSC notification before you plan.',
          },
          {
            key: 'study-plan',
            type: 'practice',
            title: 'Make your prelims study plan',
            minutes: 20,
            body: 'Download the latest RPSC syllabus. List every unit, mark the ones you are weakest in, and give each a week in a sixteen-week calendar. Keep the last three weeks for revision and full-length practice tests.',
          },
        ],
      },
    ],
  },
  {
    key: 'rajasthan-gk',
    title: 'Rajasthan GK: History, Art & Culture',
    subtitle: 'राजस्थान का इतिहास, कला एवं संस्कृति · for RAS, Patwari, REET and other state exams.',
    description:
      'Rajasthan’s history, forts, folk dances and fairs — the state GK every Rajasthan exam asks about — taught topic by topic, with a written assignment and a chapter test.',
    level: 'foundation',
    category: 'rajasthan',
    motif: 'houses',
    faculty: ['rajasthan-gk'],
    price: 1499,
    weeks: 8,
    outcomes: ['Recall key events of Mewar’s history', 'Name the hill forts of Rajasthan', 'Identify Rajasthan’s major folk dances and fairs'],
    tags: ['Rajasthan GK', 'Bilingual'],
    chapters: [
      {
        key: 'history',
        title: 'History of Rajasthan',
        summary: 'Mewar, battles and forts.',
        objective: 'By the end of this chapter, you can place key battles and forts in Rajasthan’s history.',
        lessons: [
          {
            key: 'haldighati',
            type: 'reading',
            title: 'Mewar and the Battle of Haldighati | हल्दीघाटी का युद्ध',
            minutes: 10,
            body: 'The Battle of Haldighati was fought in 1576 between Maharana Pratap of Mewar and the Mughal army of Akbar, led by Raja Man Singh of Amer. Pratap was not captured and went on resisting the Mughals for the rest of his life, recovering much of Mewar.\n\nHaldighati, near Nathdwara in Rajsamand district, takes its name from the yellow, turmeric-coloured soil of the pass.',
          },
          {
            key: 'forts',
            type: 'reading',
            title: 'Forts of Rajasthan | राजस्थान के दुर्ग',
            minutes: 12,
            body: 'Six hill forts — Chittorgarh, Kumbhalgarh, Ranthambore, Gagron, Amber and Jaisalmer — were inscribed together as a UNESCO World Heritage Site, the Hill Forts of Rajasthan, in 2013.\n\nAt Chittorgarh stands the Vijay Stambh (Tower of Victory), built by Rana Kumbha in the fifteenth century to mark his victory over Mahmud Khilji of Malwa.',
          },
          { key: 'forts-notes', type: 'assignment', title: 'Short notes on three forts', minutes: 30, assignment: 'forts-notes' },
        ],
      },
      {
        key: 'culture',
        title: 'Art and culture',
        summary: 'Folk dances and fairs.',
        objective: 'By the end of this chapter, you can name Rajasthan’s major folk dances and fairs.',
        lessons: [
          {
            key: 'dances-fairs',
            type: 'reading',
            title: 'Folk dances and fairs | लोक नृत्य एवं मेले',
            minutes: 10,
            body: 'Ghoomar, performed by women in swirling ghagras, is Rajasthan’s best-known folk dance. Kalbeliya, the dance of the Kalbeliya community, was added to UNESCO’s list of the Intangible Cultural Heritage of Humanity in 2010.\n\nThe Pushkar fair is held around Kartik Purnima and is famous for its camel and cattle trading as well as its pilgrimage to Pushkar lake.',
          },
          { key: 'gk-test', type: 'assessment', title: 'Chapter test: Rajasthan GK', minutes: 8, quiz: 'raj-gk-quiz' },
        ],
      },
    ],
  },
  {
    key: 'indian-polity',
    title: 'Indian Polity and Constitution',
    subtitle: 'भारतीय राजव्यवस्था एवं संविधान · the Constitution, the Preamble and Fundamental Rights.',
    description:
      'The polity every competitive exam asks about: how the Constitution was made, what the Preamble says, and the six Fundamental Rights with their articles — with a recorded lecture, a one-page article chart and a test.',
    level: 'complete',
    category: 'central',
    motif: 'ecliptic',
    faculty: ['general-studies'],
    price: 999,
    weeks: 6,
    outcomes: ['Recall key dates of the Constitution', 'Explain the Preamble and its amendment', 'Match Fundamental Rights to their articles'],
    tags: ['Polity', 'All exams', 'Bilingual'],
    chapters: [
      {
        key: 'constitution',
        title: 'The Constitution',
        summary: 'How it was made and what it begins with.',
        objective: 'By the end of this chapter, you can explain how the Constitution was adopted and what the Preamble declares.',
        lessons: [
          {
            key: 'making',
            type: 'reading',
            title: 'Making of the Constitution | संविधान निर्माण',
            minutes: 10,
            body: 'The Constitution was drafted by the Constituent Assembly; Dr B. R. Ambedkar chaired its Drafting Committee. The Assembly adopted the Constitution on 26 November 1949 — now observed as Constitution Day — and it came into force on 26 January 1950, Republic Day.',
          },
          {
            key: 'preamble',
            type: 'reading',
            title: 'The Preamble | प्रस्तावना',
            minutes: 8,
            body: 'The Preamble declares India a sovereign, socialist, secular, democratic republic and promises its citizens justice, liberty, equality and fraternity.\n\nThe words “socialist” and “secular”, and “integrity” in “unity and integrity of the Nation”, were added by the 42nd Amendment in 1976.',
          },
        ],
      },
      {
        key: 'rights',
        title: 'Fundamental Rights',
        summary: 'Part III, Articles 12 to 35.',
        objective: 'By the end of this chapter, you can match each Fundamental Right to its articles.',
        lessons: [
          {
            key: 'rights-lecture',
            type: 'video',
            title: 'Fundamental Rights at a glance',
            minutes: 1,
            lecture: 'fundamental-rights',
            seconds: 36,
            description: 'A short silent slide lecture on the six Fundamental Rights.',
            markers: [
              { atSec: 12, title: 'The six rights' },
              { atSec: 24, title: 'Right to Property' },
            ],
          },
          {
            key: 'rights-chart',
            type: 'document',
            title: 'Fundamental Rights article chart (PDF)',
            minutes: 5,
            note: 'fundamental-rights',
            description: 'Every article from 12 to 35 on one page.',
          },
          { key: 'polity-test', type: 'assessment', title: 'Polity test', minutes: 8, quiz: 'polity-quiz' },
        ],
      },
    ],
  },
  {
    key: 'ssc-gd',
    title: 'SSC GD Constable Complete Course',
    subtitle: 'एसएससी जीडी कांस्टेबल · Reasoning, general awareness, elementary maths and language practice.',
    description:
      'A complete course for the SSC GD Constable computer-based exam: what each section tests, the reasoning and maths shortcuts that save time, and daily practice — followed by practice tests.',
    level: 'complete',
    category: 'central',
    motif: 'orbits',
    faculty: ['aptitude', 'general-studies'],
    price: 1999,
    weeks: 10,
    outcomes: ['Know what each section of the exam tests', 'Solve number-series questions quickly', 'Work percentages without a calculator'],
    tags: ['SSC', 'GD Constable', 'Bilingual'],
    chapters: [
      {
        key: 'start',
        title: 'Getting started',
        summary: 'The exam and your first practice set.',
        objective: 'By the end of this chapter, you know the exam’s sections and have taken a first practice test.',
        lessons: [
          {
            key: 'pattern',
            type: 'reading',
            title: 'SSC GD exam pattern: an overview',
            minutes: 8,
            body: 'The SSC GD Constable recruitment starts with a computer-based exam in four sections: General Intelligence and Reasoning, General Knowledge and General Awareness, Elementary Mathematics, and English or Hindi. Candidates who qualify go on to physical standard and efficiency tests and a medical examination.\n\nMarks, timing and negative marking can change between recruitment cycles, so check the current SSC notice before you plan.',
          },
          {
            key: 'series',
            type: 'reading',
            title: 'Number series: finding the rule | संख्या श्रृंखला',
            minutes: 10,
            body: 'Most number-series questions follow one rule: a fixed difference, differences that grow, multiplication, or squares and cubes. Write the differences between terms under the series first — the pattern usually shows at once.\n\nExample: 2, 6, 12, 20, 30, ? The differences are 4, 6, 8, 10, so the next is 12 and the answer is 42.',
          },
          { key: 'practice-test', type: 'assessment', title: 'Practice test 1', minutes: 10, quiz: 'ssc-gd-practice' },
        ],
      },
      {
        key: 'maths',
        title: 'Elementary maths',
        summary: 'Percentages and daily practice.',
        objective: 'By the end of this chapter, you can solve percentage questions in under a minute.',
        lessons: [
          {
            key: 'percent',
            type: 'reading',
            title: 'Percentages in one page | प्रतिशत',
            minutes: 10,
            body: 'Learn the fraction for each common percentage: 50% = 1/2, 25% = 1/4, 20% = 1/5, 12.5% = 1/8, 10% = 1/10. Then 12.5% of 640 is simply 640 ÷ 8 = 80.\n\nRemember that x% of y equals y% of x: 4% of 75 is the same as 75% of 4, which is 3.',
          },
          {
            key: 'daily',
            type: 'practice',
            title: 'Daily practice: 10 questions',
            minutes: 15,
            body: 'Set a timer for ten minutes. Solve ten percentage questions from your practice book without a calculator, then check your answers and note the type of every question you got wrong.',
          },
        ],
      },
    ],
  },
  {
    key: 'reasoning',
    title: 'Reasoning for Competitive Exams',
    subtitle: 'तर्कशक्ति · Coding-decoding, direction sense, blood relations and puzzles.',
    description:
      'The verbal and logical reasoning topics that appear in almost every recruitment exam, each taught with a method and worked examples, ending with a test.',
    level: 'foundation',
    category: 'aptitude',
    motif: 'houses',
    faculty: ['aptitude'],
    price: 799,
    weeks: 4,
    outcomes: ['Crack letter-shift codes', 'Solve direction-sense questions with a diagram', 'Draw family trees for blood-relation questions'],
    tags: ['Reasoning', 'All exams'],
    chapters: [
      {
        key: 'verbal',
        title: 'Verbal reasoning',
        summary: 'Codes and directions.',
        objective: 'By the end of this chapter, you can solve coding and direction questions reliably.',
        lessons: [
          {
            key: 'coding',
            type: 'reading',
            title: 'Coding-decoding | कूटलेखन',
            minutes: 10,
            body: 'In letter-shift codes each letter moves a fixed number of places in the alphabet. If CAT is written DBU, every letter moves one place forward, so DOG becomes EPH.\n\nNumber the alphabet (A = 1 … Z = 26) on your rough sheet; it makes shifts and reversed-alphabet codes much faster.',
          },
          {
            key: 'directions',
            type: 'reading',
            title: 'Direction sense | दिशा ज्ञान',
            minutes: 10,
            body: 'Always draw the route. Facing north, a right turn faces east and a left turn faces west; facing east, a right turn faces south.\n\nTo find the distance between start and finish, use Pythagoras on the final east-west and north-south distances: 3 km east and 4 km north is 5 km in a straight line.',
          },
          { key: 'reasoning-test', type: 'assessment', title: 'Reasoning test', minutes: 8, quiz: 'reasoning-test' },
        ],
      },
      {
        key: 'logical',
        title: 'Logical reasoning',
        summary: 'Relations and puzzles.',
        objective: 'By the end of this chapter, you can solve blood-relation and simple arrangement puzzles.',
        lessons: [
          {
            key: 'blood-relations',
            type: 'reading',
            title: 'Blood relations | रक्त संबंध',
            minutes: 10,
            body: 'Draw a family tree: males as squares, females as circles, a horizontal line for a married couple and a vertical line for parent and child.\n\nExample: “A is the son of B. B is the daughter of C.” Then C is A’s maternal grandparent — and the statement does not tell you whether C is male or female.',
          },
          {
            key: 'puzzles',
            type: 'practice',
            title: 'Puzzle practice',
            minutes: 20,
            body: 'Solve three seating-arrangement puzzles from your practice book. For each, draw the seats first, place the definite clues, then the conditional ones, and write down which clue fixed the final position.',
          },
        ],
      },
    ],
  },
  {
    key: 'quant',
    title: 'Quantitative Aptitude: Maths for Competitive Exams',
    subtitle: 'गणित · Percentage, profit and loss, interest and averages.',
    description:
      'The arithmetic chapters that decide maths scores in SSC, banking and state exams, with shortcuts that are actually exam-safe, a recorded lecture and a test.',
    level: 'foundation',
    category: 'aptitude',
    motif: 'orbits',
    faculty: ['aptitude'],
    price: 999,
    weeks: 6,
    outcomes: ['Apply the successive-percentage rule', 'Calculate profit and loss percentages', 'Find simple and compound interest'],
    tags: ['Maths', 'All exams'],
    chapters: [
      {
        key: 'percentages',
        title: 'Percentages and profit',
        summary: 'The base for every arithmetic chapter.',
        objective: 'By the end of this chapter, you can solve percentage and profit-loss questions quickly.',
        lessons: [
          {
            key: 'percent-lecture',
            type: 'video',
            title: 'Percentage shortcuts',
            minutes: 1,
            lecture: 'percentage-shortcuts',
            seconds: 36,
            description: 'A short silent slide lecture on percentage rules and successive change.',
            markers: [
              { atSec: 12, title: 'Successive change' },
              { atSec: 24, title: 'Percentage change' },
            ],
          },
          {
            key: 'profit-loss',
            type: 'reading',
            title: 'Profit and loss | लाभ और हानि',
            minutes: 12,
            body: 'Profit or loss is always worked out on the cost price. Profit % = (selling price − cost price) ÷ cost price × 100.\n\nAn item bought for ₹400 and sold for ₹500 gives a profit of ₹100, which is 25% of the cost price — not 20%, which would be the profit as a share of the selling price.',
          },
        ],
      },
      {
        key: 'interest',
        title: 'Interest and averages',
        summary: 'Simple and compound interest.',
        objective: 'By the end of this chapter, you can calculate simple and compound interest.',
        lessons: [
          {
            key: 'si-ci',
            type: 'reading',
            title: 'Simple and compound interest | ब्याज',
            minutes: 12,
            body: 'Simple interest = principal × rate × time ÷ 100. On ₹5,000 at 8% a year for 3 years it is 5000 × 8 × 3 ÷ 100 = ₹1,200.\n\nWith compound interest the amount is P × (1 + R/100)^T, because each year’s interest earns interest too. For two years the difference between CI and SI is P × (R/100)².',
          },
          { key: 'quant-test', type: 'assessment', title: 'Maths test', minutes: 10, quiz: 'quant-test' },
        ],
      },
    ],
  },
  {
    key: 'reet-level-2',
    title: 'REET Mains Level 2: Child Development & Pedagogy',
    subtitle: 'बाल विकास एवं शिक्षाशास्त्र · learning theories, the RTE Act 2009 and classroom practice.',
    description:
      'The child development and pedagogy section of the Rajasthan teacher eligibility and recruitment exams: Piaget and Vygotsky, the Right to Education Act, and how they apply in a classroom.',
    level: 'complete',
    category: 'rajasthan',
    motif: 'ecliptic',
    faculty: ['pedagogy'],
    price: 2499,
    weeks: 8,
    outcomes: ['Describe Piaget’s four stages', 'Explain the zone of proximal development', 'State the main provisions of the RTE Act'],
    tags: ['REET', 'Teaching exams', 'Bilingual'],
    chapters: [
      {
        key: 'development',
        title: 'Child development',
        summary: 'Piaget and Vygotsky.',
        objective: 'By the end of this chapter, you can compare Piaget’s and Vygotsky’s theories.',
        lessons: [
          {
            key: 'piaget',
            type: 'reading',
            title: 'Piaget’s stages of cognitive development',
            minutes: 12,
            body: 'Jean Piaget described four stages: sensorimotor (birth to about 2 years), pre-operational (about 2 to 7), concrete operational (about 7 to 11) and formal operational (from about 11). Children in the concrete operational stage understand conservation but still reason best about real objects.\n\nFor a teacher, this means using hands-on material with younger learners and moving to abstract reasoning only as they grow.',
          },
          {
            key: 'vygotsky',
            type: 'reading',
            title: 'Vygotsky and the zone of proximal development',
            minutes: 10,
            body: 'Lev Vygotsky stressed that learning is social. The zone of proximal development is the gap between what a child can do alone and what they can do with help from a teacher or a more able peer.\n\nScaffolding is the support given inside that zone, withdrawn step by step as the child becomes able to work alone.',
          },
        ],
      },
      {
        key: 'policy',
        title: 'Education policy',
        summary: 'The Right to Education Act.',
        objective: 'By the end of this chapter, you can state the main provisions of the RTE Act 2009.',
        lessons: [
          {
            key: 'rte',
            type: 'reading',
            title: 'The RTE Act 2009 | शिक्षा का अधिकार अधिनियम',
            minutes: 10,
            body: 'Article 21A, inserted by the 86th Amendment in 2002, makes free and compulsory education a fundamental right for children aged 6 to 14. The Right of Children to Free and Compulsory Education Act, 2009, which gives effect to it, came into force on 1 April 2010.\n\nAmong its provisions, private unaided schools must reserve 25% of their entry-level seats for children from disadvantaged groups and weaker sections.',
          },
          { key: 'reet-test', type: 'assessment', title: 'Pedagogy test', minutes: 8, quiz: 'reet-test' },
        ],
      },
    ],
  },
  {
    key: 'patwari',
    title: 'Rajasthan Patwari Complete Course',
    subtitle: 'राजस्थान पटवारी · computer basics, Rajasthan GK, Hindi, reasoning and maths.',
    description:
      'A complete course for the RSMSSB Patwari exam, starting with the computer section many candidates neglect and the land-records work a patwari actually does.',
    level: 'complete',
    category: 'rajasthan',
    motif: 'houses',
    faculty: ['general-studies', 'rajasthan-gk'],
    price: 2999,
    weeks: 12,
    outcomes: ['Answer basic computer questions confidently', 'Use common keyboard shortcuts', 'Explain the land records a patwari keeps'],
    tags: ['Patwari', 'RSMSSB', 'Bilingual'],
    chapters: [
      {
        key: 'computer',
        title: 'Computer basics',
        summary: 'Hardware, memory and shortcuts.',
        objective: 'By the end of this chapter, you can answer basic computer-awareness questions.',
        lessons: [
          {
            key: 'hardware',
            type: 'reading',
            title: 'Hardware, software and memory units | कंप्यूटर की मूल बातें',
            minutes: 10,
            body: 'Input devices send data into a computer (keyboard, mouse, scanner); output devices show results (monitor, printer). RAM is volatile — its contents are lost when power goes off — while ROM keeps its contents.\n\nMemory units step up by 1,024: 1 KB = 1,024 bytes, 1 MB = 1,024 KB, 1 GB = 1,024 MB.',
          },
          {
            key: 'shortcuts',
            type: 'reading',
            title: 'Useful keyboard shortcuts',
            minutes: 8,
            body: 'Ctrl + C copies, Ctrl + X cuts and Ctrl + V pastes. Ctrl + Z undoes the last action and Ctrl + Y redoes it. Ctrl + S saves, Ctrl + P prints and Ctrl + A selects everything.\n\nOn Windows, Alt + Tab switches between open windows and Windows key + D shows the desktop.',
          },
          { key: 'computer-test', type: 'assessment', title: 'Computer test', minutes: 8, quiz: 'patwari-computer' },
        ],
      },
      {
        key: 'land',
        title: 'Land records',
        summary: 'What a patwari does.',
        objective: 'By the end of this chapter, you can explain the main records a patwari maintains.',
        lessons: [
          {
            key: 'records',
            type: 'reading',
            title: 'Land records and the patwari | भू-अभिलेख',
            minutes: 10,
            body: 'A patwari is the revenue official for a patwar circle of one or more villages. The patwari keeps the land records up to date — including the jamabandi (record of rights) and the girdawari, the crop inspection carried out each season — and records changes of ownership (mutations).\n\nThese records are now largely maintained online, so the computer section of the exam reflects the real job.',
          },
          {
            key: 'revision',
            type: 'practice',
            title: 'Revision: Rajasthan’s divisions and districts',
            minutes: 20,
            body: 'Districts and divisions in Rajasthan have been reorganised in recent years. From the latest official Rajasthan government source, list the administrative divisions and their districts, and note the date of the notification you used.',
          },
        ],
      },
    ],
  },
  {
    key: 'class-10-maths',
    title: 'Class 10 Mathematics (CBSE / RBSE)',
    subtitle: 'Quadratic equations, arithmetic progressions, trigonometry and coordinate geometry.',
    description: 'Class 10 board mathematics, chapter by chapter, with a recorded lecture, a formula sheet, a homework assignment and a test.',
    level: 'complete',
    category: 'school-9-10',
    motif: 'orbits',
    faculty: ['school-maths'],
    price: 1499,
    weeks: 20,
    outcomes: ['Solve quadratic equations by factorisation and by formula', 'Find the nth term and sum of an AP', 'Use the basic trigonometric identities'],
    tags: ['Class 10', 'Maths', 'Board exam'],
    chapters: [
      {
        key: 'quadratics',
        title: 'Quadratic equations',
        summary: 'Factorisation and the quadratic formula.',
        objective: 'By the end of this chapter, you can solve any quadratic equation and describe its roots.',
        lessons: [
          {
            key: 'quadratic-lecture',
            type: 'video',
            title: 'Quadratic equations: formula and roots',
            minutes: 1,
            lecture: 'quadratic-equations',
            seconds: 36,
            description: 'A short silent slide lecture: the standard form, the formula and the discriminant.',
            markers: [
              { atSec: 12, title: 'The quadratic formula' },
              { atSec: 24, title: 'Nature of roots' },
            ],
          },
          {
            key: 'factorisation',
            type: 'reading',
            title: 'Solving by factorisation',
            minutes: 12,
            body: 'To factorise x² + bx + c, find two numbers whose product is c and whose sum is b. For x² − 7x + 12 = 0 they are −3 and −4, so (x − 3)(x − 4) = 0 and x = 3 or x = 4.\n\nWhen a ≠ 1, split the middle term using two numbers whose product is ac: 2x² + 7x + 3 = 2x² + 6x + x + 3 = (2x + 1)(x + 3).',
          },
          { key: 'quadratic-homework', type: 'assignment', title: 'Homework: five quadratic equations', minutes: 30, assignment: 'quadratic-practice' },
        ],
      },
      {
        key: 'progressions',
        title: 'Arithmetic progressions and trigonometry',
        summary: 'APs, identities and the formula sheet.',
        objective: 'By the end of this chapter, you can find terms and sums of APs and use the trigonometric identities.',
        lessons: [
          {
            key: 'ap',
            type: 'reading',
            title: 'Arithmetic progressions',
            minutes: 12,
            body: 'In an AP each term differs from the one before by a fixed common difference d. The nth term is aₙ = a + (n − 1)d, so the 10th term of 3, 7, 11, … is 3 + 9 × 4 = 39.\n\nThe sum of the first n terms is Sₙ = n/2 × [2a + (n − 1)d]. The sum of the first 10 terms of that AP is 5 × (6 + 36) = 210.',
          },
          {
            key: 'formula-sheet',
            type: 'document',
            title: 'Class 10 formula sheet (PDF)',
            minutes: 5,
            note: 'maths-formula-sheet',
            description: 'Algebra, AP, trigonometry, coordinate geometry and mensuration formulas on two pages.',
          },
          { key: 'maths-test', type: 'assessment', title: 'Chapter test', minutes: 10, quiz: 'maths-test' },
        ],
      },
    ],
  },
  {
    key: 'class-10-science',
    title: 'Class 10 Science (CBSE / RBSE)',
    subtitle: 'Chemical reactions, acids, bases and salts, and electricity.',
    description:
      'Class 10 board science explained with everyday examples: the types of chemical reactions, pH, and Ohm’s law with resistors in series and parallel.',
    level: 'complete',
    category: 'school-9-10',
    motif: 'ecliptic',
    faculty: ['school-science'],
    price: 1499,
    weeks: 20,
    outcomes: ['Classify and balance chemical reactions', 'Use the pH scale', 'Apply Ohm’s law to series and parallel circuits'],
    tags: ['Class 10', 'Science', 'Board exam'],
    chapters: [
      {
        key: 'chemistry',
        title: 'Chemical reactions',
        summary: 'Reactions, acids, bases and salts.',
        objective: 'By the end of this chapter, you can classify reactions and read the pH scale.',
        lessons: [
          {
            key: 'reactions',
            type: 'reading',
            title: 'Types of chemical reactions',
            minutes: 12,
            body: 'Reactions are grouped as combination (two substances form one), decomposition (one substance breaks into several), displacement (a more reactive element replaces a less reactive one), double displacement (two compounds exchange ions) and redox (oxidation and reduction together).\n\nA chemical equation must be balanced so that each element has the same number of atoms on both sides: 2H₂ + O₂ → 2H₂O.',
          },
          {
            key: 'acids',
            type: 'reading',
            title: 'Acids, bases and salts',
            minutes: 12,
            body: 'The pH scale runs from 0 to 14: below 7 is acidic, 7 is neutral (pure water) and above 7 is basic. An acid and a base react to give a salt and water — neutralisation.\n\nCommon salt is sodium chloride (NaCl). Baking soda is sodium hydrogencarbonate (NaHCO₃), used in cooking and in antacids.',
          },
          { key: 'science-test', type: 'assessment', title: 'Chapter test', minutes: 8, quiz: 'science-test' },
        ],
      },
      {
        key: 'electricity',
        title: 'Electricity',
        summary: 'Ohm’s law and resistors.',
        objective: 'By the end of this chapter, you can work out the current in simple circuits.',
        lessons: [
          {
            key: 'ohm',
            type: 'reading',
            title: 'Ohm’s law and resistors',
            minutes: 12,
            body: 'Ohm’s law: the potential difference across a conductor is proportional to the current through it, V = IR, at constant temperature. Current is measured in amperes, potential difference in volts and resistance in ohms.\n\nResistors in series add: R = R₁ + R₂. In parallel, 1/R = 1/R₁ + 1/R₂, so two 6 Ω resistors in parallel give 3 Ω.',
          },
        ],
      },
    ],
  },
  {
    key: 'class-12-physics',
    title: 'Class 12 Physics: Electrostatics',
    subtitle: 'Electric charge, Coulomb’s law, electric field, potential and capacitance.',
    description:
      'The electrostatics unit of Class 12 physics, which also underpins JEE and NEET preparation: forces between charges, fields, potential and capacitors, with a formula sheet and a test.',
    level: 'advanced',
    category: 'school-11-12',
    motif: 'orbits',
    faculty: ['school-science'],
    price: 1999,
    weeks: 6,
    outcomes: ['Apply Coulomb’s law', 'Relate field, force and potential', 'Calculate capacitance and stored energy'],
    tags: ['Class 12', 'Physics', 'Board exam'],
    chapters: [
      {
        key: 'fields',
        title: 'Electric charges and fields',
        summary: 'Coulomb’s law and field lines.',
        objective: 'By the end of this chapter, you can calculate the force and field due to point charges.',
        lessons: [
          {
            key: 'coulomb',
            type: 'reading',
            title: 'Coulomb’s law',
            minutes: 12,
            body: 'The force between two point charges is F = (1/4πε₀) q₁q₂ / r², where 1/4πε₀ ≈ 9 × 10⁹ N m² C⁻². Doubling the distance makes the force a quarter as strong.\n\nThe SI unit of charge is the coulomb. Like charges repel and unlike charges attract, along the line joining them.',
          },
          {
            key: 'field',
            type: 'reading',
            title: 'Electric field and field lines',
            minutes: 10,
            body: 'The electric field at a point is the force per unit positive charge placed there, E = F/q. Field lines start on positive charges and end on negative ones, and two field lines never cross.\n\nInside a conductor in electrostatic equilibrium the field is zero, and any excess charge sits on its surface.',
          },
        ],
      },
      {
        key: 'capacitance',
        title: 'Potential and capacitance',
        summary: 'Potential, capacitors and energy.',
        objective: 'By the end of this chapter, you can work with capacitors in circuits.',
        lessons: [
          {
            key: 'formula-sheet',
            type: 'document',
            title: 'Electrostatics formula sheet (PDF)',
            minutes: 5,
            note: 'electrostatics-sheet',
            description: 'Every formula of the unit on one page.',
          },
          {
            key: 'capacitors',
            type: 'reading',
            title: 'Capacitors',
            minutes: 12,
            body: 'Capacitance is the charge stored per volt, C = Q/V, measured in farads. For a parallel-plate capacitor C = ε₀A/d: larger plates or a smaller gap store more charge.\n\nThe energy stored in a charged capacitor is U = ½CV². Capacitors in parallel add directly; in series their reciprocals add.',
          },
          { key: 'physics-test', type: 'assessment', title: 'Unit test', minutes: 8, quiz: 'physics-test' },
        ],
      },
    ],
  },
  {
    key: 'class-12-chemistry',
    title: 'Class 11–12 Chemistry: Mole Concept and Solutions',
    subtitle: 'Avogadro’s number, molar mass, molarity and Raoult’s law.',
    description:
      'The quantitative backbone of school chemistry: counting particles with the mole, expressing concentration, and how solutions behave — with a unit test.',
    level: 'advanced',
    category: 'school-11-12',
    motif: 'ecliptic',
    faculty: ['school-science'],
    price: 1999,
    weeks: 6,
    outcomes: ['Convert between mass, moles and particles', 'Calculate molarity and molality', 'Apply Raoult’s law'],
    tags: ['Class 11', 'Class 12', 'Chemistry'],
    chapters: [
      {
        key: 'mole',
        title: 'The mole concept',
        summary: 'Counting particles by weighing.',
        objective: 'By the end of this chapter, you can convert between grams, moles and particles.',
        lessons: [
          {
            key: 'avogadro',
            type: 'reading',
            title: 'The mole and Avogadro’s number',
            minutes: 12,
            body: 'One mole of any substance contains 6.022 × 10²³ particles — Avogadro’s number. The molar mass is the mass of one mole in grams: water (H₂O) is about 18 g/mol and carbon dioxide (CO₂) about 44 g/mol.\n\nSo 36 g of water is 2 mol, which contains about 1.2 × 10²⁴ molecules.',
          },
          {
            key: 'concentration',
            type: 'reading',
            title: 'Molarity and molality',
            minutes: 10,
            body: 'Molarity (M) is moles of solute per litre of solution; molality (m) is moles of solute per kilogram of solvent. Molality does not change with temperature, because it depends on masses rather than volume.\n\nDissolving 0.5 mol of NaCl to make 250 mL of solution gives 0.5 ÷ 0.25 = 2 M.',
          },
        ],
      },
      {
        key: 'solutions',
        title: 'Solutions',
        summary: 'Raoult’s law.',
        objective: 'By the end of this chapter, you can apply Raoult’s law to ideal solutions.',
        lessons: [
          {
            key: 'raoult',
            type: 'reading',
            title: 'Raoult’s law',
            minutes: 10,
            body: 'For a solution of volatile liquids, the partial vapour pressure of each component equals its mole fraction times the vapour pressure of the pure component. A solution that obeys Raoult’s law at all concentrations is called ideal.\n\nReal solutions show positive or negative deviations depending on whether the forces between unlike molecules are weaker or stronger than between like molecules.',
          },
          { key: 'chemistry-test', type: 'assessment', title: 'Unit test', minutes: 8, quiz: 'chemistry-test' },
        ],
      },
    ],
  },
  {
    key: 'english-grammar',
    title: 'English Grammar for Classes 9–10',
    subtitle: 'Tenses, articles, active and passive voice, and formal letters.',
    description:
      'The grammar and writing skills of the Class 9–10 English syllabus, which also carry straight over to the English section of competitive exams.',
    level: 'complete',
    category: 'school-9-10',
    motif: 'houses',
    faculty: ['languages'],
    price: 699,
    weeks: 8,
    outcomes: ['Choose the right tense', 'Use a, an and the correctly', 'Convert between active and passive voice'],
    tags: ['Class 9', 'Class 10', 'English'],
    chapters: [
      {
        key: 'grammar',
        title: 'Tenses and articles',
        summary: 'The everyday grammar.',
        objective: 'By the end of this chapter, you can choose the right tense and article.',
        lessons: [
          {
            key: 'present',
            type: 'reading',
            title: 'Simple present and present continuous',
            minutes: 10,
            body: 'Use the simple present for habits and facts: “She goes to school every day.” “Water boils at 100 °C.” Use the present continuous for actions happening now: “She is going to school right now.”\n\nWith he, she and it, the simple present takes -s or -es: he walks, she watches.',
          },
          {
            key: 'articles',
            type: 'reading',
            title: 'Using a, an and the',
            minutes: 8,
            body: 'Choose a or an by the first sound, not the first letter: an hour, an honest man, but a university, a one-way street.\n\nUse the for something already mentioned or unique: “I saw a dog. The dog was barking.” “The sun rises in the east.”',
          },
          { key: 'english-test', type: 'assessment', title: 'Grammar test', minutes: 8, quiz: 'english-test' },
        ],
      },
      {
        key: 'writing',
        title: 'Voice and writing',
        summary: 'Passive voice and formal letters.',
        objective: 'By the end of this chapter, you can change voice and write a formal letter.',
        lessons: [
          {
            key: 'voice',
            type: 'reading',
            title: 'Active and passive voice',
            minutes: 10,
            body: 'In the passive voice the object becomes the subject and the verb takes a form of “be” with the past participle: “He wrote a letter” becomes “A letter was written by him.”\n\nKeep the tense the same: “They are building a bridge” becomes “A bridge is being built by them.”',
          },
          { key: 'formal-letter', type: 'assignment', title: 'Write a formal letter', minutes: 30, assignment: 'formal-letter' },
        ],
      },
    ],
  },
];

const single = (id: string, prompt: string, options: string[], correct: number, explanation?: string): QuizQuestion => ({
  id,
  type: 'single',
  prompt,
  options: options.map((text, i) => ({ id: String.fromCharCode(97 + i), text })),
  correct: [String.fromCharCode(97 + correct)],
  acceptedAnswers: [],
  points: 10,
  required: true,
  ...(explanation ? { explanation } : {}),
});
const trueFalse = (id: string, prompt: string, answer: boolean, explanation?: string): QuizQuestion => ({
  id,
  type: 'true-false',
  prompt,
  options: [
    { id: 'true', text: 'True' },
    { id: 'false', text: 'False' },
  ],
  correct: [String(answer)],
  acceptedAnswers: [],
  points: 10,
  required: true,
  ...(explanation ? { explanation } : {}),
});
const short = (id: string, prompt: string, accepted: string[]): QuizQuestion => ({
  id,
  type: 'short',
  prompt,
  options: [],
  correct: [],
  acceptedAnswers: accepted,
  points: 10,
  required: true,
});

const QUIZZES: Record<string, { title: string; questions: QuizQuestion[] }> = {
  'ras-basics': {
    title: 'Practice test: Rajasthan basics',
    questions: [
      single(
        'q1',
        'Rajasthan Diwas is celebrated on:',
        ['26 January', '30 March', '1 November', '15 May'],
        1,
        'Greater Rajasthan was formed on 30 March 1949.',
      ),
      single(
        'q2',
        'At which stage of integration did Jaipur become the capital?',
        ['Matsya Union', 'Rajasthan Union', 'Greater Rajasthan', 'The 1956 reorganisation'],
        2,
      ),
      single('q3', 'The largest district of Rajasthan by area is:', ['Barmer', 'Bikaner', 'Jaisalmer', 'Jodhpur'], 2),
      single('q4', 'Guru Shikhar, the highest peak of the Aravallis, is in:', ['Udaipur', 'Sirohi (Mount Abu)', 'Ajmer', 'Alwar'], 1),
    ],
  },
  'raj-gk-quiz': {
    title: 'Chapter test: Rajasthan GK',
    questions: [
      single('q1', 'The Battle of Haldighati was fought in:', ['1526', '1576', '1615', '1658'], 1),
      single('q2', 'The Vijay Stambh at Chittorgarh was built by:', ['Rana Sanga', 'Rana Kumbha', 'Maharana Pratap', 'Rana Hammir'], 1),
      trueFalse('q3', 'Kalbeliya was added to UNESCO’s Intangible Cultural Heritage list in 2010.', true),
      single(
        'q4',
        'Which of these is NOT one of the six “Hill Forts of Rajasthan” World Heritage forts?',
        ['Kumbhalgarh', 'Gagron', 'Mehrangarh', 'Ranthambore'],
        2,
      ),
    ],
  },
  'polity-quiz': {
    title: 'Polity test',
    questions: [
      single('q1', 'Fundamental Rights are in which Part of the Constitution?', ['Part II', 'Part III', 'Part IV', 'Part V'], 1),
      single(
        'q2',
        'Which article gives the right to move the Supreme Court to enforce Fundamental Rights?',
        ['Article 14', 'Article 21', 'Article 32', 'Article 226'],
        2,
      ),
      single(
        'q3',
        'The Right to Property was removed from Fundamental Rights by the:',
        ['42nd Amendment', '44th Amendment', '73rd Amendment', '86th Amendment'],
        1,
      ),
      trueFalse(
        'q4',
        'The Constitution came into force on 26 November 1949.',
        false,
        'It was adopted on 26 November 1949 and came into force on 26 January 1950.',
      ),
    ],
  },
  'ssc-gd-practice': {
    title: 'Practice test 1',
    questions: [
      single('q1', 'Find the next number: 2, 6, 12, 20, 30, ?', ['36', '40', '42', '48'], 2),
      single('q2', '15% of 200 is:', ['20', '25', '30', '35'], 2),
      single('q3', 'Choose the word closest in meaning to “rapid”:', ['Slow', 'Quick', 'Calm', 'Heavy'], 1),
      single('q4', 'Who chaired the Drafting Committee of the Constitution?', ['Jawaharlal Nehru', 'Rajendra Prasad', 'B. R. Ambedkar', 'Sardar Patel'], 2),
    ],
  },
  'reasoning-test': {
    title: 'Reasoning test',
    questions: [
      single('q1', 'If CAT is written DBU, how is DOG written?', ['EPH', 'CNF', 'EPG', 'FQI'], 0),
      single('q2', 'Find the next number: 3, 9, 27, 81, ?', ['162', '243', '324', '729'], 1),
      single('q3', 'Ravi walks 5 km north, then turns right. Which way is he facing now?', ['North', 'South', 'East', 'West'], 2),
      single('q4', 'Which is the odd one out? 2, 3, 5, 9, 11', ['2', '3', '9', '11'], 2, 'All the others are prime numbers.'),
    ],
  },
  'quant-test': {
    title: 'Maths test',
    questions: [
      single('q1', 'A price rises by 20% and then falls by 10%. The net change is:', ['+10%', '+8%', '+12%', '−2%'], 1),
      single('q2', 'Simple interest on ₹5,000 at 8% a year for 3 years is:', ['₹1,000', '₹1,200', '₹1,400', '₹1,600'], 1),
      single('q3', 'An item bought for ₹400 is sold for ₹500. The profit percentage is:', ['20%', '25%', '30%', '15%'], 1),
      short('q4', 'What is the average of the first 10 natural numbers? (number)', ['5.5']),
    ],
  },
  'reet-test': {
    title: 'Pedagogy test',
    questions: [
      single('q1', 'How many stages of cognitive development did Piaget describe?', ['3', '4', '5', '6'], 1),
      single('q2', 'The zone of proximal development is associated with:', ['Piaget', 'Skinner', 'Vygotsky', 'Pavlov'], 2),
      single('q3', 'The RTE Act guarantees free and compulsory education to children aged:', ['3 to 10', '6 to 14', '5 to 15', '6 to 18'], 1),
      trueFalse('q4', 'Article 21A was inserted by the 86th Amendment.', true),
    ],
  },
  'patwari-computer': {
    title: 'Computer test',
    questions: [
      single('q1', '1 KB is equal to:', ['1,000 bytes', '1,024 bytes', '1,000 bits', '1,024 bits'], 1),
      single('q2', 'Which shortcut undoes the last action?', ['Ctrl + Y', 'Ctrl + Z', 'Ctrl + U', 'Ctrl + X'], 1),
      single('q3', 'Which of these is an input device?', ['Monitor', 'Printer', 'Keyboard', 'Speaker'], 2),
      trueFalse('q4', 'RAM keeps its contents when the power is switched off.', false),
    ],
  },
  'maths-test': {
    title: 'Chapter test',
    questions: [
      single('q1', 'The discriminant of x² − 4x + 4 = 0 is:', ['−8', '0', '8', '16'], 1, 'D = 16 − 16 = 0, so the roots are equal.'),
      single('q2', 'The 10th term of the AP 3, 7, 11, … is:', ['37', '39', '41', '43'], 1),
      trueFalse('q3', 'sin²θ + cos²θ = 1 for every angle θ.', true),
      single('q4', 'The distance between (0, 0) and (3, 4) is:', ['5', '6', '7', '25'], 0),
    ],
  },
  'science-test': {
    title: 'Chapter test',
    questions: [
      single('q1', 'The chemical formula of common salt is:', ['KCl', 'NaCl', 'NaHCO₃', 'CaCO₃'], 1),
      single('q2', 'The pH of pure water is:', ['0', '5', '7', '14'], 2),
      single('q3', 'Which equation is balanced?', ['H₂ + O₂ → H₂O', '2H₂ + O₂ → 2H₂O', 'H₂ + 2O₂ → H₂O', '2H₂ + 2O₂ → H₂O'], 1),
      single('q4', 'The SI unit of electric current is the:', ['Volt', 'Ohm', 'Ampere', 'Watt'], 2),
    ],
  },
  'physics-test': {
    title: 'Unit test',
    questions: [
      single('q1', 'The SI unit of electric charge is the:', ['Ampere', 'Coulomb', 'Volt', 'Farad'], 1),
      single('q2', 'If the distance between two charges is doubled, the force between them becomes:', ['Double', 'Half', 'One quarter', 'Four times'], 2),
      trueFalse('q3', 'The electrostatic field inside a conductor in equilibrium is zero.', true),
      single('q4', 'The energy stored in a capacitor is:', ['CV', '½CV²', 'C/V', 'Q/V'], 1),
    ],
  },
  'chemistry-test': {
    title: 'Unit test',
    questions: [
      single('q1', 'Avogadro’s number is approximately:', ['6.022 × 10²³', '3.0 × 10⁸', '9.8', '1.6 × 10⁻¹⁹'], 0),
      single('q2', 'Molarity is moles of solute per:', ['kilogram of solvent', 'litre of solution', 'litre of solvent', 'mole of solvent'], 1),
      single('q3', 'The molar mass of water is about:', ['16 g/mol', '18 g/mol', '20 g/mol', '44 g/mol'], 1),
      trueFalse('q4', 'An ideal solution obeys Raoult’s law at all concentrations.', true),
    ],
  },
  'english-test': {
    title: 'Grammar test',
    questions: [
      single('q1', 'She ___ to school every day.', ['go', 'goes', 'going', 'gone'], 1),
      single('q2', 'Choose the correct article: “It took ___ hour.”', ['a', 'an', 'the', 'no article'], 1),
      single(
        'q3',
        'The passive of “He wrote a letter” is:',
        ['A letter is written by him.', 'A letter was written by him.', 'A letter has been written by him.', 'A letter wrote him.'],
        1,
      ),
      single('q4', 'Choose the word closest in meaning to “abundant”:', ['Scarce', 'Plentiful', 'Empty', 'Small'], 1),
    ],
  },
};

const ASSIGNMENTS: Record<string, { brief: string; dueAfterDays: number }> = {
  'forts-notes': {
    brief:
      'Write short notes (about 100 words each) on three of the six Hill Forts of Rajasthan: where each stands, who built or held it, and one event connected with it.',
    dueAfterDays: 7,
  },
  'quadratic-practice': {
    brief:
      'Solve these five equations, showing every step, and state the nature of the roots for each: x² − 5x + 6 = 0; x² + 4x + 4 = 0; 2x² + 7x + 3 = 0; x² − 2x + 5 = 0; 3x² − 12 = 0.',
    dueAfterDays: 5,
  },
  'formal-letter': {
    brief:
      'Write a formal letter to your school principal requesting extra practice classes before the board exams. Use the correct format: sender’s address, date, receiver’s address, subject, salutation, body and closing.',
    dueAfterDays: 7,
  },
};

/** The PDF study notes, written for this catalogue. Text is Latin-1 plus the symbols demoPdf.ts spells out. */
const NOTES: Record<string, { file: string; title: string; subtitle: string; sections: PdfSection[] }> = {
  'rajasthan-ekikaran': {
    file: 'rajasthan-ekikaran-notes.pdf',
    title: 'Integration of Rajasthan (Ekikaran)',
    subtitle: 'RAS Prelims Foundation Batch · notes',
    sections: [
      {
        heading: 'The seven stages',
        body: [
          '• Stage 1, 18 March 1948 - Matsya Union: Alwar, Bharatpur, Dholpur and Karauli, with the Neemrana thikana.',
          '• Stage 2, 25 March 1948 - Rajasthan Union (Purva Rajasthan): states of the south-east, with Kota as the capital.',
          '• Stage 3, 18 April 1948 - United State of Rajasthan: Udaipur (Mewar) joins and Udaipur becomes the capital.',
          '• Stage 4, 30 March 1949 - Greater Rajasthan: Jaipur, Jodhpur, Bikaner and Jaisalmer join; Jaipur becomes the capital. Celebrated as Rajasthan Diwas.',
          '• Stage 5, 15 May 1949 - United State of Greater Rajasthan: the Matsya Union merges.',
          '• Stage 6, 26 January 1950 - Sirohi joins, except Abu and Delwara.',
          '• Stage 7, 1 November 1956 - under the States Reorganisation Act: Abu, Delwara, Ajmer-Merwara and the Sunel Tappa join; Sironj goes to Madhya Pradesh.',
        ],
      },
      { heading: 'Remember', body: ['Seven stages, about eight and a half years: from 18 March 1948 to 1 November 1956.'] },
    ],
  },
  'fundamental-rights': {
    file: 'fundamental-rights-chart.pdf',
    title: 'Fundamental Rights: article chart',
    subtitle: 'Indian Polity and Constitution · notes',
    sections: [
      {
        heading: 'Right to Equality (Articles 14-18)',
        body: [
          '• 14: equality before the law and equal protection of the laws.',
          '• 15: no discrimination on grounds of religion, race, caste, sex or place of birth.',
          '• 16: equality of opportunity in public employment.',
          '• 17: abolition of untouchability.',
          '• 18: abolition of titles.',
        ],
      },
      {
        heading: 'Right to Freedom (Articles 19-22)',
        body: [
          '• 19: six freedoms - speech and expression, assembly, association, movement, residence, and profession.',
          '• 20: protection in respect of conviction for offences.',
          '• 21: protection of life and personal liberty.  21A: right to education (6 to 14 years).',
          '• 22: protection against arrest and detention in certain cases.',
        ],
      },
      {
        heading: 'Right against Exploitation (Articles 23-24)',
        body: ['• 23: no traffic in human beings or forced labour.  24: no child below 14 in factories, mines or hazardous work.'],
      },
      {
        heading: 'Freedom of Religion (Articles 25-28)',
        body: [
          '• Freedom of conscience and religion, to manage religious affairs, from taxes for promoting a religion, and from compulsory religious instruction in state schools.',
        ],
      },
      {
        heading: 'Cultural and Educational Rights (Articles 29-30)',
        body: ['• 29: protection of the interests of minorities.  30: right of minorities to establish and administer educational institutions.'],
      },
      {
        heading: 'Right to Constitutional Remedies (Article 32)',
        body: [
          '• The Supreme Court can issue writs: habeas corpus, mandamus, prohibition, certiorari and quo warranto.',
          'The Right to Property was removed by the 44th Amendment (1978); it is now a legal right under Article 300A.',
        ],
      },
    ],
  },
  'maths-formula-sheet': {
    file: 'class-10-maths-formula-sheet.pdf',
    title: 'Class 10 Mathematics: formula sheet',
    subtitle: 'Class 10 Mathematics (CBSE / RBSE) · notes',
    sections: [
      {
        heading: 'Quadratic equations',
        body: [
          '• ax² + bx + c = 0, a != 0.  Roots: x = (-b ± sqrt(D)) / 2a, where D = b² - 4ac.',
          '• D > 0: two distinct real roots.  D = 0: two equal roots.  D < 0: no real roots.',
        ],
      },
      {
        heading: 'Arithmetic progressions',
        body: ['• nth term: a + (n - 1)d.', '• Sum of n terms: n/2 × [2a + (n - 1)d], or n/2 × (first term + last term).'],
      },
      {
        heading: 'Trigonometry',
        body: ['• sin²A + cos²A = 1.   1 + tan²A = sec²A.   1 + cot²A = cosec²A.', '• sin 30° = 1/2,  cos 60° = 1/2,  tan 45° = 1,  sin 90° = 1,  cos 0° = 1.'],
      },
      {
        heading: 'Coordinate geometry',
        body: ['• Distance between (x1, y1) and (x2, y2): sqrt[(x2 - x1)² + (y2 - y1)²].', '• Mid-point: ((x1 + x2)/2, (y1 + y2)/2).'],
      },
      {
        heading: 'Mensuration',
        body: [
          '• Circle: area pi r², circumference 2 pi r.',
          '• Cylinder: volume pi r²h.  Cone: volume (1/3) pi r²h.  Sphere: volume (4/3) pi r³, surface area 4 pi r².',
        ],
      },
    ],
  },
  'electrostatics-sheet': {
    file: 'electrostatics-formula-sheet.pdf',
    title: 'Electrostatics: formula sheet',
    subtitle: 'Class 12 Physics: Electrostatics · notes',
    sections: [
      {
        heading: 'Force and field',
        body: ["• Coulomb's law: F = k q1 q2 / r², with k = 1/(4 pi e0) ~ 9 × 10^9 N m² C^-2.", '• Field: E = F / q.  Field of a point charge: E = k q / r².'],
      },
      { heading: "Gauss's law", body: ['• Total flux through a closed surface = (charge enclosed) / e0.'] },
      { heading: 'Potential', body: ['• Potential of a point charge: V = k q / r.  Potential energy of two charges: U = k q1 q2 / r.'] },
      {
        heading: 'Capacitance',
        body: ['• C = Q / V.  Parallel plates: C = e0 A / d.  Energy: U = ½ C V².', '• In parallel: C = C1 + C2 + ...   In series: 1/C = 1/C1 + 1/C2 + ...'],
      },
    ],
  },
};

/* ─── Writer ──────────────────────────────────────────────────────────── */

export const EDUCATION_COURSE_KEYS = COURSES.map((c) => c.key);
export const educationId = eid;

export interface SeedEducationOptions {
  /** The academy's slug, e.g. `default`. It must exist. */
  academySlug: string;
  /** A `.test` learner account in that academy to give enrolments, progress and classes. Development and staging only. */
  demoStudentEmail?: string;
  uploadDir?: string;
  now?: Date;
  log?: (...args: unknown[]) => void;
}

export interface SeedEducationResult {
  tenantId: string;
  academyName: string;
  demoStudent?: string;
  counts: Record<string, number>;
}

/** What would stop the seed: a missing academy, or an id or slug it needs held by someone else. Empty means safe. */
export async function educationConflicts(
  academySlug: string,
): Promise<{ problems: string[]; tenant?: { id: string; name: string; ownerUserId: string | null } }> {
  const platform = asPlatform('the education catalogue seed checks nothing it needs is taken');
  try {
    const tenant = await platform.tenant.findUnique({ where: { slug: academySlug }, select: { id: true, name: true, ownerUserId: true } });
    if (!tenant) return { problems: [`No academy has the address "${academySlug}".`] };
    const problems: string[] = [];
    const foreignCourses = await platform.course.count({ where: { id: { startsWith: 'edu-' }, NOT: { tenantId: tenant.id } } });
    if (foreignCourses) problems.push(`${foreignCourses} sample course(s) already belong to another academy.`);
    const foreignMedia = await platform.mediaAsset.count({ where: { id: { startsWith: 'edu-' }, NOT: { tenantId: tenant.id } } });
    if (foreignMedia) problems.push(`${foreignMedia} sample file(s) already belong to another academy.`);
    const slugTaken = await platform.course.findMany({
      where: { tenantId: tenant.id, slug: { in: EDUCATION_COURSE_KEYS }, NOT: { id: { startsWith: 'edu-' } } },
      select: { slug: true },
    });
    for (const c of slugTaken) problems.push(`The academy already has its own course at /${c.slug}.`);
    const emails = FACULTY.map((f) => facultyEmail(f.key));
    const foreignFaculty = await platform.instructor.count({ where: { email: { in: emails }, NOT: { tenantId: tenant.id } } });
    if (foreignFaculty) problems.push('A sample faculty email already belongs to another academy.');
    return { problems, tenant };
  } finally {
    await platform.$disconnect();
  }
}

const facultyEmail = (key: FacultyKey) => `${key}@faculty.sample.invalid`;

/** A local time in India (UTC+05:30) `days` from `now`, as an instant. */
export function istAt(now: Date, days: number, hour: number, minute = 0): Date {
  const ist = new Date(now.getTime() + 330 * 60_000 + days * DAY);
  return new Date(Date.UTC(ist.getUTCFullYear(), ist.getUTCMonth(), ist.getUTCDate(), hour, minute) - 330 * 60_000);
}

export async function seedEducationCatalog(opts: SeedEducationOptions): Promise<SeedEducationResult> {
  const log = opts.log ?? (() => undefined);
  const now = opts.now ?? new Date();
  const ago = (days: number, hours = 0) => new Date(now.getTime() - days * DAY - hours * 3_600_000);
  const uploadDir = opts.uploadDir ?? ensureUploadDir();

  const { problems, tenant } = await educationConflicts(opts.academySlug);
  if (problems.length || !tenant) throw new Error(`Nothing was changed:\n  ${problems.join('\n  ')}`);
  const tenantId = tenant.id;
  const T = { tenantId };
  const db = forTenant(tenantId);

  try {
    // Course files are owned by a member of staff, so every signed-in learner of the academy may open them.
    const owner =
      (tenant.ownerUserId && (await db.user.findFirst({ where: { id: tenant.ownerUserId, role: { in: ['admin', 'instructor'] } }, select: { id: true } }))) ||
      (await db.user.findFirst({ where: { role: 'admin' }, orderBy: { createdAt: 'asc' }, select: { id: true } }));
    if (!owner) throw new Error(`"${tenant.name}" has no admin to own the course files. Nothing was changed.`);

    let demo: { id: string; userId: string; email: string } | undefined;
    if (opts.demoStudentEmail) {
      assertDemoEnvironment();
      if (!opts.demoStudentEmail.endsWith('.test')) throw new Error('The demo learner must be a .test account, never a real person. Nothing was changed.');
      const user = await db.user.findFirst({ where: { email: opts.demoStudentEmail, role: 'student' }, include: { student: true } });
      if (!user?.student) throw new Error(`${opts.demoStudentEmail} is not a learner in "${tenant.name}". Nothing was changed.`);
      demo = { id: user.student.id, userId: user.id, email: user.email };
    }

    const sources = JSON.parse(readFileSync(path.join(ASSETS, 'sources.json'), 'utf8')) as {
      covers: { key: string; file: string; title: string; author: string; licence: string }[];
    };

    log(`Academy: ${tenant.name} (${opts.academySlug})`);
    log('Levels, categories, faculty...');
    for (const l of LEVELS) {
      const data = { name: l.name, order: l.order, summary: l.summary };
      await db.level.upsert({ where: { id: eid('level', l.key) }, create: { id: eid('level', l.key), ...T, ...data }, update: data });
    }
    for (const c of CATEGORIES) {
      const data = { name: c.name, description: c.description, glyph: c.glyph, order: c.order, status: 'active' };
      await db.category.upsert({ where: { id: eid('category', c.key) }, create: { id: eid('category', c.key), ...T, ...data }, update: data });
      for (const lk of c.levels)
        await db.categoryLevel.upsert({
          where: { categoryId_levelId: { categoryId: eid('category', c.key), levelId: eid('level', lk) } },
          create: { ...T, categoryId: eid('category', c.key), levelId: eid('level', lk) },
          update: {},
        });
    }
    for (const f of FACULTY) {
      const data = {
        name: f.name,
        title: 'Subject team',
        email: facultyEmail(f.key),
        bio: 'A subject-team profile for the sample catalogue. An admin can edit it or replace it with the real teachers.',
        expertiseJson: JSON.stringify(f.expertise),
        status: 'active',
        languagesJson: JSON.stringify(['Hindi', 'English']),
      };
      await db.instructor.upsert({ where: { id: eid('faculty', f.key) }, create: { id: eid('faculty', f.key), ...T, ...data }, update: data });
    }

    log('Cover images, lectures and notes (files + MediaAsset rows)...');
    async function storeMedia(key: string, file: { bytes: Buffer; ext: string; mime: string; kind: 'image' | 'video' | 'document'; originalName: string }) {
      const id = eid('media', key);
      const storageName = `${id}${file.ext}`;
      const target = path.join(uploadDir, storageName);
      const same = existsSync(target) && statSync(target).size === file.bytes.length && sha(readFileSync(target)) === sha(file.bytes);
      if (!same) writeFileSync(target, file.bytes);
      const data = { kind: file.kind, mime: file.mime, originalName: file.originalName, sizeBytes: file.bytes.length, storageName, ownerUserId: owner!.id };
      await db.mediaAsset.upsert({ where: { id }, create: { id, ...T, ...data }, update: data });
      return { id, sizeBytes: file.bytes.length };
    }
    const coverIds = new Map<string, string>();
    for (const c of sources.covers) {
      const stored = await storeMedia(`cover-${c.key}`, {
        bytes: readFileSync(path.join(ASSETS, c.file)),
        ext: '.webp',
        mime: 'image/webp',
        kind: 'image',
        originalName: `${c.key}.webp`,
      });
      coverIds.set(c.key, stored.id);
    }

    log('Courses, chapters, lessons, quizzes and assignments...');
    const courseId = (key: string) => eid('course', key);
    const chapterId = (course: string, key: string) => eid('chapter', `${course}-${key}`);
    const lessonId = (course: string, key: string) => eid('lesson', `${course}-${key}`);
    for (const c of COURSES) {
      const credit = sources.covers.find((s) => s.key === c.key);
      if (!credit) throw new Error(`No cover image for ${c.key} in sources.json.`);
      const data = {
        slug: c.key,
        title: c.title,
        subtitle: c.subtitle,
        description: `${c.description}\n\nCover image: “${credit.title}”, ${credit.author}, ${credit.licence}, via Wikimedia Commons (cropped).`,
        levelId: eid('level', c.level),
        categoryId: eid('category', c.category),
        format: 'self-paced',
        language: 'en-IN',
        coverMotif: c.motif,
        coverImageId: coverIds.get(c.key)!,
        estimatedWeeks: c.weeks,
        certificateTitle: `Certificate of completion: ${c.title}`,
        priceAmount: c.price,
        priceCurrency: 'INR',
        status: 'published',
        visibility: 'public',
        outcomesJson: JSON.stringify(c.outcomes),
        tagsJson: JSON.stringify(c.tags),
        // No ratings are invented: a course has none until learners give them.
        rating: null,
        ratingCount: null,
      };
      await db.course.upsert({ where: { id: courseId(c.key) }, create: { id: courseId(c.key), ...T, ...data, publishedAt: now }, update: data });
      for (const fk of c.faculty)
        await db.courseInstructor.upsert({
          where: { courseId_instructorId: { courseId: courseId(c.key), instructorId: eid('faculty', fk) } },
          create: { ...T, courseId: courseId(c.key), instructorId: eid('faculty', fk) },
          update: {},
        });

      for (const [ci, ch] of c.chapters.entries()) {
        const chData = { courseId: courseId(c.key), title: ch.title, summary: ch.summary, objective: ch.objective, status: 'published', position: ci };
        await db.chapter.upsert({ where: { id: chapterId(c.key, ch.key) }, create: { id: chapterId(c.key, ch.key), ...T, ...chData }, update: chData });

        for (const [li, l] of ch.lessons.entries()) {
          const id = lessonId(c.key, l.key);
          let content: object = {};
          let description: string | null = null;
          if (l.type === 'reading' || l.type === 'practice') content = { article: { body: l.body } };
          if (l.type === 'video') {
            const media = await storeMedia(`lecture-${l.lecture}`, {
              bytes: readFileSync(path.join(ASSETS, 'lectures', `${l.lecture}.mp4`)),
              ext: '.mp4',
              mime: 'video/mp4',
              kind: 'video',
              originalName: `${l.lecture}.mp4`,
            });
            content = {
              video: {
                file: { id: media.id, name: `${l.lecture}.mp4`, sizeMb: mb(media.sizeBytes), url: `/media/${media.id}`, mime: 'video/mp4' },
                durationSec: l.seconds,
                captions: false,
                markers: l.markers,
              },
            };
            description = l.description;
          }
          if (l.type === 'document') {
            const note = NOTES[l.note];
            const footer = `${tenant.name} · ${note.title}`;
            const media = await storeMedia(`note-${l.note}`, {
              bytes: studyNotePdf(note.title, note.subtitle, note.sections, footer),
              ext: '.pdf',
              mime: 'application/pdf',
              kind: 'document',
              originalName: note.file,
            });
            content = {
              document: {
                file: { id: media.id, name: note.file, sizeMb: mb(media.sizeBytes), url: `/media/${media.id}`, mime: 'application/pdf' },
                downloadable: true,
              },
            };
            description = l.description;
          }
          if (l.type === 'assessment')
            content = { quiz: { quizId: eid('quiz', l.quiz), questions: QUIZZES[l.quiz].questions.length, passMark: 60, attempts: 3 } };
          if (l.type === 'assignment') {
            const a = ASSIGNMENTS[l.assignment];
            content = {
              assignment: { assignmentId: eid('assignment', l.assignment), brief: a.brief, dueAfterDays: a.dueAfterDays, maxScore: 100, submission: 'text' },
            };
          }
          const lData = {
            chapterId: chapterId(c.key, ch.key),
            courseId: courseId(c.key),
            title: l.title,
            type: l.type,
            durationMin: l.minutes,
            status: 'published',
            isPreview: ci === 0 && li === 0,
            description,
            contentJson: JSON.stringify(content),
            position: li,
          };
          await db.lesson.upsert({ where: { id }, create: { id, ...T, ...lData }, update: lData });

          if (l.type === 'assessment') {
            const q = QUIZZES[l.quiz];
            const qData = {
              courseId: courseId(c.key),
              chapterId: chapterId(c.key, ch.key),
              lessonId: id,
              title: q.title,
              instructions: 'Answer every question. You can take this test up to three times; your best score counts.',
              status: 'published',
              questionsJson: JSON.stringify(q.questions),
              settingsJson: JSON.stringify(QUIZ_SETTINGS),
            };
            await db.quiz.upsert({ where: { id: eid('quiz', l.quiz) }, create: { id: eid('quiz', l.quiz), ...T, ...qData }, update: qData });
          }
          if (l.type === 'assignment') {
            const a = ASSIGNMENTS[l.assignment];
            const aData = {
              courseId: courseId(c.key),
              chapterId: chapterId(c.key, ch.key),
              lessonId: id,
              title: l.title,
              instructions: a.brief,
              format: 'text',
              dueJson: JSON.stringify({ kind: 'relative', days: a.dueAfterDays }),
              acceptsLate: true,
              latePenalty: 10,
              rubricJson: '[]',
              maxScore: 100,
              passMark: 40,
              status: 'published',
            };
            await db.courseAssignment.upsert({
              where: { id: eid('assignment', l.assignment) },
              create: { id: eid('assignment', l.assignment), ...T, ...aData },
              update: aData,
            });
          }
        }
      }
    }

    if (demo) await seedDemoLearner(db, demo, { tenantId, now, ago, courseId, lessonId, log });

    for (const c of COURSES) {
      const enrolledCount = await db.enrollment.count({ where: { courseId: courseId(c.key) } });
      const liveSessions = await db.liveClass.count({ where: { courseId: courseId(c.key), cancelled: false } });
      await db.course.update({ where: { id: courseId(c.key) }, data: { enrolledCount, liveSessions } });
    }

    const edu = { id: { startsWith: 'edu-' } };
    const counts = {
      categories: await db.category.count({ where: edu }),
      courses: await db.course.count({ where: edu }),
      lessons: await db.lesson.count({ where: edu }),
      media: await db.mediaAsset.count({ where: edu }),
      quizzes: await db.quiz.count({ where: edu }),
      assignments: await db.courseAssignment.count({ where: edu }),
      liveClasses: await db.liveClass.count({ where: edu }),
      enrolments: await db.enrollment.count({ where: edu }),
    };
    return { tenantId, academyName: tenant.name, demoStudent: demo?.email, counts };
  } finally {
    await db.$disconnect();
  }
}

const QUIZ_SETTINGS = { passMark: 60, attempts: 3, shuffleQuestions: false, shuffleOptions: true, showResults: 'score-and-answers' } as const;

/** Enrolments, progress, a passed test, a graded assignment, live classes and notifications for one `.test` learner. */
async function seedDemoLearner(
  db: ReturnType<typeof forTenant>,
  demo: { id: string; userId: string },
  ctx: {
    tenantId: string;
    now: Date;
    ago: (days: number, hours?: number) => Date;
    courseId: (key: string) => string;
    lessonId: (course: string, key: string) => string;
    log: (...args: unknown[]) => void;
  },
) {
  const { tenantId, now, ago, courseId, lessonId, log } = ctx;
  const T = { tenantId };
  log('Demo learner: enrolments, progress, live classes, notifications...');

  type Step = { lesson: string; daysAgo: number; hoursAgo?: number } & (
    { state: 'completed' } | { state: 'in-progress'; fraction: number; positionSec?: number }
  );
  const plan: { course: string; enrolledDaysAgo: number; steps: Step[] }[] = [
    {
      course: 'reasoning',
      enrolledDaysAgo: 30,
      steps: ['coding', 'directions', 'reasoning-test', 'blood-relations', 'puzzles'].map((lesson, i) => ({
        lesson,
        state: 'completed' as const,
        daysAgo: 26 - i * 4,
      })),
    },
    {
      course: 'class-10-maths',
      enrolledDaysAgo: 12,
      steps: [{ lesson: 'quadratic-lecture', state: 'in-progress', fraction: 0.5, positionSec: 18, daysAgo: 3 }],
    },
    {
      course: 'ras-prelims',
      enrolledDaysAgo: 18,
      steps: [
        { lesson: 'formation', state: 'completed', daysAgo: 16 },
        { lesson: 'integration-lecture', state: 'completed', daysAgo: 12 },
        { lesson: 'ekikaran-notes', state: 'completed', daysAgo: 7 },
        // The most recent activity, so this is the course Continue Learning offers.
        { lesson: 'physical-divisions', state: 'in-progress', fraction: 0.4, daysAgo: 0, hoursAgo: 18 },
      ],
    },
    {
      course: 'ssc-gd',
      enrolledDaysAgo: 2,
      // Both readings done, which unlocks the chapter's practice test: a test ready to take.
      steps: [
        { lesson: 'pattern', state: 'completed', daysAgo: 1 },
        { lesson: 'series', state: 'completed', daysAgo: 0, hoursAgo: 22 },
      ],
    },
  ];

  for (const e of plan) {
    for (const s of e.steps) {
      const at = ago(s.daysAgo, s.hoursAgo ?? 0);
      const data =
        s.state === 'completed'
          ? { state: 'completed', fraction: 1, positionSec: null, completedAt: at, lastAccessedAt: at }
          : { state: 'in-progress', fraction: s.fraction, positionSec: s.positionSec ?? null, completedAt: null, lastAccessedAt: at };
      await db.lessonProgress.upsert({
        where: { studentId_lessonId: { studentId: demo.id, lessonId: lessonId(e.course, s.lesson) } },
        create: { ...T, studentId: demo.id, lessonId: lessonId(e.course, s.lesson), ...data },
        update: data,
      });
    }
    const last = [...e.steps].sort((a, b) => a.daysAgo * 24 + (a.hoursAgo ?? 0) - (b.daysAgo * 24 + (b.hoursAgo ?? 0)))[0];
    const data = {
      enrolledAt: ago(e.enrolledDaysAgo),
      status: 'active',
      progress: 0,
      source: 'self',
      lastActiveAt: last ? ago(last.daysAgo, last.hoursAgo ?? 0) : ago(e.enrolledDaysAgo),
      completedAt: null,
      expiresAt: null,
      lastLessonId: last ? lessonId(e.course, last.lesson) : null,
    };
    await db.enrollment.upsert({
      where: { studentId_courseId: { studentId: demo.id, courseId: courseId(e.course) } },
      create: { id: eid('enrolment', `demo-${e.course}`), ...T, studentId: demo.id, courseId: courseId(e.course), ...data },
      update: data,
    });
  }

  // The reasoning test, passed with three of four right — scored the way the API scores it.
  const quiz = QUIZZES['reasoning-test'];
  const answers: QuizAnswers = { q1: ['a'], q2: ['b'], q3: ['c'], q4: ['b'] };
  const result = scoreAttempt({ questions: quiz.questions, settings: QUIZ_SETTINGS }, answers);
  const attempt = {
    quizId: eid('quiz', 'reasoning-test'),
    studentId: demo.id,
    answersJson: JSON.stringify(answers),
    resultJson: JSON.stringify(result),
    percent: result.percent,
    passed: result.passed,
    durationSec: 284,
    createdAt: ago(18),
  };
  await db.quizAttempt.upsert({
    where: { id: eid('attempt', 'demo-reasoning-test') },
    create: { id: eid('attempt', 'demo-reasoning-test'), ...T, ...attempt },
    update: attempt,
  });

  log('Live classes for the demo learner’s courses...');
  const live = [
    {
      key: 'reasoning-recap',
      course: 'reasoning',
      faculty: 'aptitude',
      at: istAt(now, -8, 18),
      minutes: 60,
      title: 'Reasoning: puzzle-solving session',
      recording: true,
    },
    {
      key: 'ras-geography',
      course: 'ras-prelims',
      faculty: 'rajasthan-gk',
      at: istAt(now, 2, 18),
      minutes: 90,
      title: 'Rajasthan geography: live revision',
      recording: false,
    },
    {
      key: 'quadratic-doubts',
      course: 'class-10-maths',
      faculty: 'school-maths',
      at: istAt(now, 5, 17),
      minutes: 60,
      title: 'Quadratic equations: doubt-clearing class',
      recording: false,
    },
    {
      key: 'ssc-practice-discussion',
      course: 'ssc-gd',
      faculty: 'aptitude',
      at: istAt(now, 8, 19),
      minutes: 60,
      title: 'Practice test 1: solutions discussion',
      recording: false,
    },
  ];
  for (const lc of live) {
    const data = {
      courseId: courseId(lc.course),
      instructorId: eid('faculty', lc.faculty),
      title: lc.title,
      startsAt: lc.at,
      durationMin: lc.minutes,
      capacity: 100,
      cancelled: false,
      description: 'A live class for learners on this course: a short recap, worked questions and time for doubts.',
      agendaJson: JSON.stringify([
        { title: 'Recap', minutes: 10 },
        { title: 'Worked questions', minutes: lc.minutes - 25 },
        { title: 'Doubts', minutes: 15 },
      ]),
      visibility: 'enrolled',
      meetingJson: JSON.stringify({ kind: 'room' }),
      remindersJson: JSON.stringify([1440, 60]),
      // Dates move to today on every run, so reminders already sent for the old time are forgotten.
      remindersSentJson: '[]',
      recordingJson: lc.recording ? JSON.stringify({ durationMin: lc.minutes - 4, availableUntil: istAt(now, 30, 23, 59).toISOString() }) : null,
    };
    await db.liveClass.upsert({ where: { id: eid('live', lc.key) }, create: { id: eid('live', lc.key), ...T, ...data }, update: data });
  }
  for (const [lc, attended, registeredDaysAgo] of [
    ['reasoning-recap', true, 10],
    ['ras-geography', null, 1],
  ] as const) {
    const data = { registeredAt: ago(registeredDaysAgo), attended };
    await db.liveRegistration.upsert({
      where: { liveClassId_studentId: { liveClassId: eid('live', lc), studentId: demo.id } },
      create: { ...T, liveClassId: eid('live', lc), studentId: demo.id, ...data },
      update: data,
    });
  }

  // Stored progress is the API's own figure.
  await runInTenant(tenantId, async () => {
    const rules = await learnerRules();
    for (const e of plan) {
      const course = mapCourse(await db.course.findUniqueOrThrow({ where: { id: courseId(e.course) }, include: COURSE_INCLUDE }));
      const snapshot = await snapshotFor(course, demo.id, rules.chapterGate);
      const done = course.chapters.flatMap((ch) => ch.lessons).every((l) => snapshot.lessons[l.id]?.state === 'completed');
      const finished = e.steps.reduce<Date | null>((at, s) => {
        const t = ago(s.daysAgo, s.hoursAgo ?? 0);
        return s.state === 'completed' && (!at || t > at) ? t : at;
      }, null);
      await db.enrollment.update({
        where: { studentId_courseId: { studentId: demo.id, courseId: course.id } },
        data: { progress: progressOf(course, snapshot).percent, status: done ? 'completed' : 'active', completedAt: done ? finished : null },
      });
    }
  });

  const notes = [
    {
      key: 'live-ras',
      category: 'live',
      title: 'Live class in two days',
      summary: 'Rajasthan geography: live revision · RAS Prelims Foundation Batch.',
      daysAgo: 0,
      read: false,
    },
    {
      key: 'test-ready',
      category: 'quiz',
      title: 'Practice test 1 is ready',
      summary: 'SSC GD Constable Complete Course: you finished the chapter, so the test is open.',
      daysAgo: 0,
      read: false,
    },
    { key: 'reasoning-done', category: 'course', title: 'Course completed', summary: 'You finished Reasoning for Competitive Exams.', daysAgo: 10, read: true },
  ];
  for (const n of notes) {
    const data = {
      recipientId: demo.userId,
      category: n.category,
      title: n.title,
      summary: n.summary,
      bodyJson: JSON.stringify([n.summary]),
      createdAt: ago(n.daysAgo, 1),
      readAt: n.read ? ago(n.daysAgo) : null,
      important: n.category === 'live',
    };
    await db.appNotification.upsert({ where: { id: eid('notification', n.key) }, create: { id: eid('notification', n.key), ...T, ...data }, update: data });
  }
  const latest = await db.lessonProgress.findFirst({ where: { studentId: demo.id }, orderBy: { lastAccessedAt: 'desc' }, select: { lastAccessedAt: true } });
  if (latest?.lastAccessedAt) await db.student.update({ where: { id: demo.id }, data: { lastActiveAt: latest.lastAccessedAt } });
}

const sha = (bytes: Buffer) => createHash('sha256').update(bytes).digest('hex');
const mb = (bytes: number) => Math.round((bytes / 1_048_576) * 100) / 100;
