import type {
  AffiliateEarnings,
  BroadcastAudience,
  BroadcastHistoryRow,
  BroadcastInput,
  BroadcastResult,
  CourseReviewInput,
  CourseReview,
  CourseReviewStatus,
  LearnerCourseReview,
  PublicCourseReviewPage,
  StaffCourseReview,
  StaffCourseReviewPage,
  MlmCommissionRow,
  MlmCommissionStatus,
  MlmDashboard,
  MlmKycInput,
  MlmKycRow,
  MlmKycStatus,
  MlmKycView,
  MlmLiabilityReport,
  MlmMatchingRunRow,
  MlmPayoutBatchRow,
  MlmRankHistoryRow,
  MlmRewardRow,
  MlmRewardStatus,
  MlmWalletEntryRow,
  MlmWalletRow,
  MlmWithdrawalRow,
  MlmWithdrawalStatus,
  Paged,
  PublicAffiliateProgram,
  SiteContent,
  AdminBundle,
  BlogKind,
  BlogPost,
  BlogPostInput,
  BundleInput,
  BundlePurchaseView,
  PublicBundle,
  PublicMentor,
  PublicStats,
} from '@syniastrolms/domain';
/**
 * Service contracts. Screens depend on these interfaces only; the mock
 * implementation ships today and an HTTP implementation replaces it when the
 * API module lands — no component changes required.
 */
import type {
  CourseSalesRow,
  Coupon,
  CouponInput,
  CouponUpdate,
  CourseQuote,
  PaymentEventRow,
  SalesOrderDetail,
  SalesOrderList,
  SalesOrderQuery,
  BrandAsset,
  BrandAssetKind,
  PlatformBranding,
  PlatformBrandingSettings,
  SavedBrandAsset,
  MlmPlanOverview,
  MlmPlanTerms,
  MlmPlanTermsInput,
  MlmPlanVersionSummary,
  MlmProgramCourse,
  MlmLeg,
  AffiliateMe,
  AffiliateEnrolInput,
  AffiliateActivation,
  ReferralInfo,
  AffiliateStatus,
  AffiliateMemberQuery,
  AffiliateMemberRow,
  ManualPlacementInput,
  PlacementHistoryRow,
  SponsorRow,
  TeamPage,
  TeamQuery,
  TeamRow,
  TreeAncestor,
  TreeNodeView,
  AffiliateFigures,
  AffiliateOrderRow,
  MlmCarryAdjustInput,
  MlmLegFigures,
  MlmRankTier,
  MlmCarryForwardRow,
  MlmCvLedgerRow,
  MlmCvQuery,
  MlmOrderQuery,
  MlmOrderRow,
  MlmOrderStatus,
  MlmReversalReason,
} from '@syniastrolms/domain';
import type {
  MediaFile,
  PermissionGroup,
  PermissionKey,
  Role,
  QuizAnswers,
  AttemptReview,
  LearnerQuiz,
  LearnerQuizQuestion,
  QuizSessionStart,
  QuizSessionView,
  QuizStanding,
  QuizWindow,
  HelpArticle,
  HelpAudience,
  HelpCategory,
  LmsSettings,
  SettingsRecord,
  SettingsSection,
  EnrollmentSource,
  Kpi,
  LearnerSegment,
  ReportFilters,
  AppNotification,
  NotificationCategory,
  NotificationChannel,
  NotificationSettings,
  CalendarEvent,
  CalendarEventInput,
  CalendarEventType,
  LiveClassInput,
  LiveClassPhase,
  CertificateTemplate,
  CertificateTemplateInput,
  IssuedCertificate,
  IssuedCertificateStatus,
  Attachment,
  BirthDetails,
  CourseAssignment as AuthoredAssignment,
  LessonProgress,
  ProgressState,
  ProgressSummary,
  Submission as LearnerSubmission,
  ActivityKind,
  AdminEvent,
  InstructorInput,
  InstructorStatus,
  Assessment,
  Enrollment,
  ReviewStatus,
  Student,
  StudentStatus,
  Assignment,
  AssignmentInput,
  AssignmentStatus,
  CourseAssignment,
  Review,
  Submission,
  Category,
  CategoryInput,
  CategoryStatus,
  Chapter,
  ChapterInput,
  ContentStatus,
  Lesson,
  LessonInput,
  Quiz,
  QuizInput,
  QuizStatus,
  LessonType,
  CertificateRecord,
  Course,
  CourseInput,
  CourseStatus,
  CourseProgressSnapshot,
  DashboardScope,
  DashboardSnapshot,
  EnrollmentStatus,
  Instructor,
  LearningEvent,
  Level,
  LiveClass,
  Rank,
  RankStanding,
  StudyDay,
  TrendPoint,
  AccountCreated,
  AccountStartResult,
  AccountVerificationPending,
  InstructorRequestPending,
  Inquiry,
  InquiryKind,
  InquiryListResult,
  InquiryStatus,
  PublicInquiryInput,
  UserProfile,
  CoursePurchase,
  CoursePurchaseStatus,
  CourseSale,
} from '@syniastrolms/domain';

export type LearnerStatus = 'active' | 'at-risk' | 'completed' | 'paused';

export interface LearnerRow {
  id: string;
  name: string;
  email: string;
  course: string;
  progress: number;
  rank: string;
  lastActiveAt: string;
  status: LearnerStatus;
}

export interface CatalogService {
  listLevels(): Promise<Level[]>;
  listCategories(): Promise<Category[]>;
  listCourses(filter?: { levelId?: string; categoryId?: string }): Promise<Course[]>;
  getCourse(slug: string): Promise<Course>;
  listInstructors(): Promise<Instructor[]>;
  /** A listed course's published reviews, as a visitor reads them. */
  listCourseReviews(slug: string, query: { page: number; pageSize: number }): Promise<PublicCourseReviewPage>;
}

export interface LearnerService {
  listAssignments(): Promise<Assignment[]>;
  getRankLadder(): Promise<{ ranks: Rank[]; standing: RankStanding }>;
}

export interface EnrollmentService {
  enroll(courseId: string): Promise<{ courseId: string; enrolledAt: string }>;
}

export interface LearnerQuery {
  search?: string;
  status?: LearnerStatus | 'all';
  sort?: { key: 'name' | 'progress' | 'lastActiveAt'; direction: 'asc' | 'desc' };
  page: number;
  pageSize: number;
}

export interface AdminService {
  listLearners(query: LearnerQuery): Promise<{ rows: LearnerRow[]; total: number }>;
}

export interface DashboardService {
  getSnapshot(scope: DashboardScope): Promise<DashboardSnapshot>;
}

export type CourseSort = 'updated' | 'title' | 'learners' | 'created';

export interface CourseQuery {
  search?: string;
  categoryId?: string;
  instructorId?: string;
  /** Limits results to one instructor's courses — the teaching workspace. */
  scopeInstructorId?: string;
  status?: CourseStatus | 'all';
  sort?: CourseSort;
  page: number;
  pageSize: number;
}

export interface CourseListResult {
  rows: Course[];
  total: number;
  /** Counts per status for the current search and filters, before the status filter. */
  counts: Record<CourseStatus | 'all', number>;
}

export interface CourseStats {
  courseId: string;
  enrolled: number;
  active: number;
  completionRate: number;
  avgProgress: number;
  /** Weekly new enrollments, 12 weeks. */
  weekly: TrendPoint[];
  progressBuckets: { label: string; value: number }[];
  recent: { studentId: string; name: string; enrolledAt: string; progress: number; status: EnrollmentStatus }[];
  upcomingLive: number;
  certificatesIssued: number;
  reviewsWaiting: number;
  totalMinutes: number;
}

export interface CourseAdminService {
  list(query: CourseQuery): Promise<CourseListResult>;
  get(id: string, scopeInstructorId?: string): Promise<Course>;
  stats(id: string): Promise<CourseStats>;
  create(input: CourseInput): Promise<Course>;
  update(id: string, input: Partial<CourseInput>): Promise<Course>;
  /** Rejects with a conflict when the publish checklist is not met. */
  publish(id: string): Promise<Course>;
  unpublish(id: string): Promise<Course>;
  archive(id: string): Promise<Course>;
  /** Archived → draft. */
  restore(id: string): Promise<Course>;
  reorderChapters(id: string, chapterIds: string[]): Promise<Course>;
}

export type CategorySort = 'order' | 'name' | 'courses' | 'updated';

export interface CategoryQuery {
  search?: string;
  status?: CategoryStatus | 'all';
  sort?: CategorySort;
}

export interface CategoryRow {
  category: Category;
  courseCount: number;
  publishedCount: number;
  learnerCount: number;
}

export interface CategoryDetail extends CategoryRow {
  courses: Pick<Course, 'id' | 'title' | 'status' | 'enrolledCount' | 'levelId' | 'coverMotif' | 'coverImageUrl'>[];
}

export interface CategoryAdminService {
  list(query: CategoryQuery): Promise<{ rows: CategoryRow[]; counts: Record<CategoryStatus | 'all', number> }>;
  get(id: string): Promise<CategoryDetail>;
  create(input: CategoryInput): Promise<Category>;
  update(id: string, input: Partial<CategoryInput>): Promise<Category>;
  /** Rejects with a conflict when courses still use the category and no destination is given. */
  remove(id: string, options?: { moveCoursesTo?: string }): Promise<{ moved: number }>;
}

export interface CurriculumStats {
  courseId: string;
  enrolled: number;
  /** Share of enrolled learners who finished each chapter, and who started it, 0–100. */
  chapters: Record<string, { completionRate: number; startedRate: number }>;
  /** Share of enrolled learners who finished each lesson, 0–100. */
  lessons: Record<string, number>;
}

export interface ChapterAdminService {
  stats(courseId: string): Promise<CurriculumStats>;
  /** Inserts at a 1-based position; appends when omitted. */
  create(courseId: string, input: ChapterInput, position?: number): Promise<Chapter>;
  update(courseId: string, chapterId: string, input: Partial<ChapterInput>): Promise<Chapter>;
  /** Copies the chapter and its lessons as drafts, directly after the original. */
  duplicate(courseId: string, chapterId: string): Promise<Chapter>;
  remove(courseId: string, chapterId: string): Promise<{ lessonsRemoved: number }>;
  move(courseId: string, chapterId: string, position: number): Promise<Chapter[]>;
}

export type LessonSort = 'position' | 'updated' | 'duration' | 'title';

export interface LessonQuery {
  search?: string;
  chapterId?: string;
  type?: LessonType | 'all';
  status?: ContentStatus | 'all';
  sort?: LessonSort;
}

export interface LessonRow {
  lesson: Lesson;
  chapterId: string;
  chapterTitle: string;
  /** 0-based positions, for "3.5" numbering. */
  chapterIndex: number;
  lessonIndex: number;
}

export interface LessonDetail extends LessonRow {
  chapter: Chapter;
  previous?: { id: string; title: string };
  next?: { id: string; title: string };
}

export interface LessonAdminService {
  list(
    courseId: string,
    query: LessonQuery,
  ): Promise<{ rows: LessonRow[]; counts: { all: number; published: number; draft: number; byType: Partial<Record<LessonType, number>> } }>;
  get(courseId: string, lessonId: string): Promise<LessonDetail>;
  create(courseId: string, chapterId: string, input: LessonInput, position?: number): Promise<Lesson>;
  /** Rejects with a conflict when publishing a lesson whose content is incomplete. */
  update(courseId: string, lessonId: string, input: Partial<LessonInput>): Promise<Lesson>;
  move(courseId: string, lessonId: string, chapterId: string, position: number): Promise<LessonDetail>;
  duplicate(courseId: string, lessonId: string): Promise<Lesson>;
  remove(courseId: string, lessonId: string): Promise<void>;
}

export interface QuizQuery {
  search?: string;
  courseId?: string;
  status?: QuizStatus | 'all';
  scopeInstructorId?: string;
}

export interface QuizRow {
  quiz: Quiz;
  courseTitle: string;
  chapterTitle?: string;
  points: number;
  attempts: number;
  /** 0–100, null until someone attempts it. */
  passRate: number | null;
  avgScore: number | null;
}

export interface QuizStats {
  quizId: string;
  attempts: number;
  learners: number;
  passRate: number;
  avgScore: number;
  medianMinutes: number;
  /** Score bands 0–9%, 10–19% … 90–100%. */
  distribution: { label: string; value: number }[];
  questions: { questionId: string; correctRate: number; commonWrongOptionId?: string }[];
}

/**
 * One attempt at a quiz, as staff see it: under way (`active`), handed in by the learner (`submitted`) or by the
 * server at the deadline (`expired`). Staff see the score whatever the quiz shows learners; one under way has none.
 */
export interface QuizAttemptRow {
  studentId: string;
  name: string;
  email: string;
  attemptId?: string;
  sessionId?: string;
  attemptNo: number;
  status: 'active' | 'submitted' | 'expired';
  /** Absent for attempts made before attempts were timed by the server. */
  startedAt?: string;
  deadlineAt?: string;
  submittedAt?: string;
  percent?: number;
  passed?: boolean;
  durationSec?: number;
}

export interface QuizAdminService {
  list(query: QuizQuery): Promise<{ rows: QuizRow[]; counts: Record<QuizStatus | 'all', number> }>;
  get(id: string, scopeInstructorId?: string): Promise<Quiz>;
  stats(id: string): Promise<QuizStats>;
  /** Every attempt at the quiz, newest first. */
  attempts(id: string): Promise<QuizAttemptRow[]>;
  create(input: QuizInput): Promise<Quiz>;
  /** Rejects with a conflict (and the validator's `issues`) when publishing a quiz that fails validation. `{ status: 'archived' }` archives it. */
  update(id: string, input: Partial<QuizInput>): Promise<Quiz>;
  duplicate(id: string): Promise<Quiz>;
  /** Refused with a conflict once anyone has taken the quiz — it is archived instead. */
  remove(id: string): Promise<void>;
}

/* ─── Assignments and reviews ─── */

export interface AssignmentQuery {
  search?: string;
  courseId?: string;
  status?: AssignmentStatus | 'all';
  scopeInstructorId?: string;
}

export interface AssignmentRow {
  assignment: CourseAssignment;
  courseTitle: string;
  chapterTitle?: string;
  submitted: number;
  /** Waiting or in review. */
  toReview: number;
  overdue: number;
  graded: number;
  /** Learners who finished the chapter without handing in. */
  missing: number;
  /** Percent of the maximum score, across graded submissions. */
  avgScore: number | null;
}

export type SubmissionFilter = 'all' | 'to-review' | 'graded' | 'returned' | 'missing';

export interface SubmissionQuery {
  assignmentId?: string;
  courseId?: string;
  filter?: SubmissionFilter;
  search?: string;
  sort?: 'oldest' | 'newest' | 'score';
  scopeInstructorId?: string;
  page: number;
  pageSize: number;
}

export interface SubmissionPerson {
  id: string;
  name: string;
  email: string;
  city: string;
}

export interface SubmissionRow {
  /** Missing rows have a learner and no submission. */
  id: string;
  submission?: Submission;
  student: SubmissionPerson;
  assignmentId: string;
  assignmentTitle: string;
  courseTitle: string;
  maxScore: number;
  overdue: boolean;
}

export interface SubmissionListResult {
  rows: SubmissionRow[];
  total: number;
  counts: Record<SubmissionFilter, number>;
}

export interface SubmissionDetail {
  submission: Submission;
  assignment: CourseAssignment;
  courseTitle: string;
  chapterTitle?: string;
  student: SubmissionPerson & { progress: number; enrolledAt: string };
  /** Position in the assignment's review queue, oldest first. */
  queue: { position: number; total: number; previousId?: string; nextId?: string };
}

export interface ReviewInput {
  decision: 'draft' | 'graded' | 'returned';
  scores: Review['scores'];
  points?: number;
  feedback: string;
  privateNote?: string;
}

export interface ReviewSummary {
  toReview: number;
  overdue: number;
  byCourse: { courseId: string; toReview: number; overdue: number }[];
}

export interface AssignmentAdminService {
  list(query: AssignmentQuery): Promise<{ rows: AssignmentRow[]; counts: Record<AssignmentStatus | 'all', number> }>;
  get(id: string, scopeInstructorId?: string): Promise<CourseAssignment>;
  create(input: AssignmentInput): Promise<CourseAssignment>;
  /** Rejects with a conflict when publishing an assignment that fails validation. */
  update(id: string, input: Partial<AssignmentInput>): Promise<CourseAssignment>;
  duplicate(id: string): Promise<CourseAssignment>;
  remove(id: string): Promise<void>;
  submissions(query: SubmissionQuery): Promise<SubmissionListResult>;
  submission(id: string, scopeInstructorId?: string): Promise<SubmissionDetail>;
  /** Rejects with a conflict when grading or returning fails validation. */
  review(id: string, input: ReviewInput): Promise<Submission>;
  remind(assignmentId: string, studentIds: string[]): Promise<{ sent: number }>;
  summary(scopeInstructorId?: string): Promise<ReviewSummary>;
}

/* ─── Students ─── */

export type StudentSort = 'recent' | 'name' | 'progress' | 'joined';

export interface StudentQuery {
  search?: string;
  courseId?: string;
  status?: StudentStatus | 'all';
  sort?: StudentSort;
  scopeInstructorId?: string;
  page: number;
  pageSize: number;
}

export interface StudentRow {
  student: Student;
  status: StudentStatus;
  /** Courses in scope, most recently enrolled first. */
  courses: { id: string; title: string; progress: number; status: EnrollmentStatus }[];
  /** Average progress across the courses in progress, or across all when none are. */
  progress: number;
}

export interface StudentListResult {
  rows: StudentRow[];
  total: number;
  counts: Record<StudentStatus | 'all', number>;
}

export interface StudentEnrollment {
  enrollment: Enrollment;
  courseTitle: string;
  levelTitle: string;
  categoryId: string;
  instructorNames: string[];
  chapters: { done: number; total: number };
  lessons: { done: number; total: number };
  lastLessonTitle?: string;
  certificateTitle?: string;
}

export interface StudentCertificate {
  id: string;
  courseId: string;
  courseTitle: string;
  title: string;
  issuedAt: string;
  credentialId: string;
}

export interface StudentProfile {
  student: Student;
  status: StudentStatus;
  quietDays: number;
  rank: { id: string; title: string; order: number; descriptor: string; achievedAt?: string };
  enrollments: StudentEnrollment[];
  certificates: StudentCertificate[];
  summary: { enrolled: number; active: number; completed: number; avgProgress: number; studyMinutes: number; submissions: number; avgScore: number | null };
}

export interface StudentProgress {
  courses: {
    courseId: string;
    courseTitle: string;
    progress: number;
    status: EnrollmentStatus;
    chapters: { id: string; title: string; percent: number; completed: number; total: number }[];
  }[];
  quizzes: { quizId: string; title: string; courseTitle: string; attempts: number; best: number; passMark: number; lastAt: string }[];
  assignments: {
    submissionId: string;
    assignmentId: string;
    title: string;
    courseTitle: string;
    submittedAt: string;
    status: ReviewStatus;
    score?: number;
    max: number;
    passMark: number;
    late: boolean;
  }[];
  studyWeeks: { label: string; detail: string; minutes: number }[];
}

export interface StudentActivityQuery {
  kind?: ActivityKind | 'all';
  courseId?: string;
  scopeInstructorId?: string;
  limit: number;
}

export interface StudentActivity {
  events: (LearningEvent & { courseId?: string })[];
  total: number;
  counts: Partial<Record<ActivityKind | 'all', number>>;
}

export interface StudentMessage {
  subject: string;
  body: string;
  channels: ('email' | 'app')[];
}

export interface StudentAdminService {
  list(query: StudentQuery): Promise<StudentListResult>;
  get(id: string, scopeInstructorId?: string): Promise<StudentProfile>;
  progress(id: string, scopeInstructorId?: string): Promise<StudentProgress>;
  activity(id: string, query: StudentActivityQuery): Promise<StudentActivity>;
  message(ids: string[], message: StudentMessage): Promise<{ sent: number }>;
  enroll(id: string, courseId: string, source: Enrollment['source']): Promise<Enrollment>;
  setEnrollmentStatus(enrollmentId: string, status: 'active' | 'paused'): Promise<Enrollment>;
  removeEnrollment(enrollmentId: string): Promise<void>;
  setSuspended(id: string, suspended: boolean, reason?: string): Promise<Student>;
  /** Admin only (SAAS-028): adds a learner to the academy and emails them a link to choose a password. */
  create(input: { name: string; email: string }): Promise<Student>;
  resendInvite(id: string): Promise<{ sentTo: string }>;
}

/* ─── Instructors ─── */

export type InstructorSort = 'name' | 'students' | 'rating' | 'joined';

export interface InstructorQuery {
  search?: string;
  status?: InstructorStatus | 'all';
  expertise?: string;
  sort?: InstructorSort;
}

export interface InstructorRow {
  instructor: Instructor;
  courses: { id: string; title: string; status: CourseStatus }[];
  students: number;
  /** Enrollment-weighted mean of their published courses' ratings. */
  rating: number | null;
  ratingCount: number;
  completion: number | null;
  toReview: number;
  overdue: number;
}

export interface InstructorCourse {
  id: string;
  title: string;
  status: CourseStatus;
  levelTitle: string;
  coverMotif: Course['coverMotif'];
  coverImageUrl?: string;
  role: 'lead' | 'co';
  coInstructors: string[];
  enrolled: number;
  activeLearners: number;
  rating?: number;
  ratingCount?: number;
  completion: number | null;
  lessons: number;
  updatedAt: string;
}

export interface InstructorProfile {
  instructor: Instructor;
  courses: InstructorCourse[];
  reach: { students: number; active: number; completed: number; newThisMonth: number; cities: { city: string; count: number }[] };
  performance: {
    rating: number | null;
    ratingCount: number;
    academyRating: number;
    completion: number | null;
    academyCompletion: number;
    reviewHoursMedian: number | null;
    reviewsOnTime: number | null;
    reviewed: number;
    toReview: number;
    liveDelivered: number;
    liveUpcoming: number;
    attendance: number | null;
    enrollmentsByMonth: { label: string; detail: string; value: number }[];
  };
  activity: AdminEvent[];
}

/** An instructor who registered themselves and waits for, or was refused, this academy's approval (D34). */
export interface InstructorRequest {
  id: string;
  name: string;
  email: string;
  title: string;
  status: 'pending' | 'rejected';
  requestedAt: string;
  lms: string;
  /** The application (docs/16 §2.5); absent on a request made before applications carried one. */
  phone?: string;
  bio?: string;
  expertise?: string[];
  yearsTeaching?: number;
  links?: string[];
}

export interface InstructorAdminService {
  list(query: InstructorQuery): Promise<{ rows: InstructorRow[]; counts: Record<InstructorStatus | 'all', number>; expertise: string[] }>;
  get(id: string): Promise<InstructorProfile>;
  /** Rejects with a conflict when the input fails validation or the email is taken. */
  create(input: InstructorInput): Promise<Instructor>;
  update(id: string, input: InstructorInput): Promise<Instructor>;
  setStatus(id: string, status: InstructorStatus): Promise<Instructor>;
  resendInvite(id: string): Promise<{ sentTo: string }>;
  /** Self-registrations (D34): pending by default. */
  requests(status?: 'pending' | 'rejected'): Promise<InstructorRequest[]>;
  approveRequest(id: string): Promise<InstructorRequest | { id: string; status: 'active' }>;
  rejectRequest(id: string): Promise<InstructorRequest>;
}

/* ─── Learning (the signed-in learner) ─── */

export interface NextLesson {
  id: string;
  title: string;
  type: LessonType;
  durationMin: number;
  chapterIndex: number;
  chapterTitle: string;
  lessonNumber: string;
  state: ProgressState;
  fraction?: number;
  positionSec?: number;
}

export interface LearnerCourse {
  course: Course;
  enrollment: Enrollment;
  progress: ProgressSummary;
  snapshot: CourseProgressSnapshot;
  next?: NextLesson;
  instructorNames: string[];
  levelTitle: string;
  lastActiveAt?: string;
}

export interface LearningHome {
  firstName: string;
  courses: LearnerCourse[];
  saved: { course: Course; instructorNames: string[]; levelTitle: string }[];
  recent: { courseId: string; courseTitle: string; lessonId: string; lessonTitle: string; type: LessonType; at: string; state: ProgressState }[];
  upcoming: {
    id: string;
    kind: 'live' | 'assignment' | 'quiz';
    title: string;
    context: string;
    at: string;
    to: string;
    flag?: 'live-now' | 'starting-soon' | 'overdue' | 'due-soon';
  }[];
  week: StudyDay[];
}

export interface LearnerAssignment {
  assignment: AuthoredAssignment;
  courseTitle: string;
  chapterTitle?: string;
  lessonId?: string;
  state: Assignment['state'];
  dueAt?: string;
  submission?: LearnerSubmission;
  draft?: { text: string; files: Attachment[]; chart?: BirthDetails };
}

export type LessonAccess = 'open' | 'locked' | 'not-enrolled' | 'unavailable';

export interface LessonView {
  course: Course;
  enrolled: boolean;
  snapshot: CourseProgressSnapshot;
  progress: ProgressSummary;
  chapterIndex: number;
  lessonIndex: number;
  lesson: Lesson;
  number: string;
  position: { index: number; total: number };
  state: ProgressState;
  lessonProgress?: LessonProgress;
  access: LessonAccess;
  lockedReason?: string;
  previous?: { id: string; title: string };
  next?: { id: string; title: string; locked: boolean };
  /** The quiz without its key (SAAS-018). Its questions come with a session (`startQuizSession`), never from here. */
  quiz?: LessonQuiz;
  quizBest?: number;
  assignment?: LearnerAssignment;
  live?: LiveClass;
  instructorNames: string[];
  note: string;
  bookmarked: boolean;
}

/**
 * A lesson's quiz as the learner's lesson carries it. `questions` is empty for a timed or windowed quiz — and new
 * screens ignore it for every quiz: the questions come with the session the server starts.
 */
export interface LessonQuiz extends LearnerQuiz {
  questionCount: number;
  totalPoints: number;
  attemptsUsed: number;
  /** The attempt still open, to resume. */
  openSession?: QuizSessionView;
  window: QuizWindow;
  /** Whether any question takes marks away for a wrong answer — known before the questions are sent. */
  negativeMarking?: boolean;
}

/** The learner's attempts at a quiz, newest first and cut to what they may see, and where they stand with it. */
export interface QuizAttemptsView {
  attempts: AttemptReview[];
  standing: QuizStanding;
}

/** What handing an attempt in answers — the same every time it is repeated. */
export interface QuizSubmitResult {
  session: QuizSessionView;
  /** As completing the lesson answers, on a pass; `null` otherwise. */
  completion: CompletionResult | null;
  /** Whether the final sheet sent with the submission was taken (only before the deadline). */
  answersAccepted: boolean;
  review: AttemptReview | null;
  standing: QuizStanding;
}

/** A row of the learner's tests list: its window, and the deadline of an attempt under way. `score` is absent while results are held. */
export type LearnerAssessment = Assessment & {
  lessonId?: string;
  courseTitle: string;
  window?: QuizWindow;
  opensAt?: string;
  closesAt?: string;
  deadlineAt?: string;
  /** While results are held until the quiz closes: when they are shown. Nothing about the outcome is shown before. */
  resultsAt?: string;
  negativeMarking?: boolean;
};

export interface CompletionResult {
  snapshot: CourseProgressSnapshot;
  progress: ProgressSummary;
  chapterCompleted?: string;
  courseCompleted: boolean;
  nextLessonId?: string;
}

export interface LearningService {
  getHome(): Promise<LearningHome>;
  listCourses(): Promise<{ courses: LearnerCourse[]; saved: LearningHome['saved'] }>;
  getCourse(
    courseId: string,
  ): Promise<LearnerCourse & { enrolled: boolean; live: LiveClass[]; assignments: LearnerAssignment[]; certificate?: CertificateRecord; saved: boolean }>;
  getLesson(courseId: string, lessonId: string): Promise<LessonView>;
  completeLesson(courseId: string, lessonId: string): Promise<CompletionResult>;
  savePosition(courseId: string, lessonId: string, positionSec: number, fraction: number): Promise<void>;
  saveNote(courseId: string, lessonId: string, text: string): Promise<{ savedAt: string }>;
  toggleBookmark(courseId: string, lessonId: string): Promise<{ bookmarked: boolean }>;
  toggleSaved(courseId: string): Promise<{ saved: boolean }>;
  enroll(courseId: string): Promise<LearnerCourse>;
  listAssignments(): Promise<LearnerAssignment[]>;
  getAssignment(assignmentId: string): Promise<LearnerAssignment>;
  saveAssignmentDraft(assignmentId: string, draft: NonNullable<LearnerAssignment['draft']>): Promise<{ savedAt: string }>;
  submitAssignment(assignmentId: string, draft: NonNullable<LearnerAssignment['draft']>): Promise<LearnerAssignment>;
  listAssessments(): Promise<LearnerAssessment[]>;
  /*
   * A lesson's quiz is taken through a session the server starts, keeps and finishes: it fixes the deadline, takes
   * answers only before it, and scores what it stored. Refusals carry the API's code in `ServiceError.reason`:
   * `QUIZ_TIME_UP` and `QUIZ_FINISHED` on a save, `TEST_NOT_OPEN` / `TEST_CLOSED` on a start.
   */
  /** The learner's attempts at a lesson's quiz, newest first, each cut to what they may see, and where they stand. */
  quizAttempts(courseId: string, lessonId: string): Promise<QuizAttemptsView>;
  /** Starts the next attempt — consuming it — or picks up the open one. A retried `startKey` answers with the same session. */
  startQuizSession(courseId: string, lessonId: string, startKey?: string): Promise<QuizSessionStart>;
  /** The latest attempt: the open one with its questions, a finished one without, or none. */
  getQuizSession(courseId: string, lessonId: string): Promise<{ session: QuizSessionView | null; questions: LearnerQuizQuestion[] }>;
  /** Stores the whole answer sheet. A `seq` no higher than the stored one is ignored: compare the answer's `answersSeq`. */
  saveQuizAnswers(courseId: string, lessonId: string, sessionId: string, answers: QuizAnswers, seq: number): Promise<QuizSessionView>;
  /** Hands the attempt in, with a final sheet if one is given. Safe to repeat: every call answers with the same result. */
  submitQuizSession(courseId: string, lessonId: string, sessionId: string, final?: { answers: QuizAnswers; seq: number }): Promise<QuizSubmitResult>;
  listCertificates(): Promise<{ issued: CertificateDetail[]; pending: CertificateDetail[]; working: CertificateRecord[] }>;
  getCertificate(id: string): Promise<CertificateDetail>;
  claimCertificate(id: string): Promise<CertificateDetail>;
  /** What the learner would pay now, with a coupon if they typed one. Refused as buying would be; holds nothing. */
  quotePurchase(courseId: string, couponCode?: string): Promise<CourseQuote>;
  /**
   * Opens the learner's order for a paid course, or hands back the one already open (a safe retry). The server prices
   * it: nothing here names an amount, only the coupon the learner typed. Refused with `ALREADY_ENROLLED`, `COURSE_NOT_FOR_SALE`, `PAYMENTS_NOT_SET_UP`, or
   * a plain conflict for a free course or an LMS that enrols by approval or invitation.
   */
  startPurchase(courseId: string, couponCode?: string): Promise<CoursePurchaseStart>;
  /** Hands the gateway checkout's result back. The server verifies it and asks the gateway before anything opens. */
  confirmPurchase(purchaseId: string, completion: { paymentId: string; signature: string }): Promise<CoursePurchaseConfirmation>;
  /** Where a purchase stands now — the server asks the gateway again while it is open. */
  getPurchase(purchaseId: string): Promise<CoursePurchase>;
  /** The learner's purchases, newest first. */
  listPurchases(): Promise<CoursePurchase[]>;
  /** The learner's own review of a course, and whether they may write one. */
  getCourseReview(courseId: string): Promise<LearnerCourseReview>;
  /** Creates or edits it. Editing never changes whether it is published or hidden. */
  saveCourseReview(courseId: string, input: CourseReviewInput): Promise<CourseReview>;
}

/** The checkout a course purchase opens: publishable values only, exactly as the server chose them. */
export interface CoursePurchaseCheckout {
  provider: string;
  keyId?: string;
  orderId: string;
  /** Paise. */
  amount: number;
  currency: string;
  redirectUrl?: string;
  description: string;
  prefill: { name: string; email: string };
}

export interface CoursePurchaseStart {
  purchase: CoursePurchase;
  checkout: CoursePurchaseCheckout;
}

/** What the server found when it checked a finished checkout with the gateway. Only `enrolled` opens the course. */
export interface CoursePurchaseConfirmation {
  purchase: CoursePurchase;
  outcome: { status: CoursePurchaseStatus | 'pending'; enrolled: boolean; message: string };
}

/* ─── Certificates ─── */

export interface CertificateQuery {
  search?: string;
  courseId?: string;
  status?: IssuedCertificateStatus | 'all';
  page: number;
  pageSize: number;
}

export interface CertificateRow {
  certificate: IssuedCertificate;
  studentName: string;
  studentEmail: string;
  courseTitle: string;
}

export interface CertificateDetail {
  certificate: IssuedCertificate;
  student: SubmissionPerson;
  courseTitle: string;
  levelTitle: string;
  template: CertificateTemplate;
  verifyUrl: string;
  /** The issuing LMS's name. Absent from older API builds: the documents then name nobody but the platform. */
  issuer?: string;
}

export interface TemplateSummary {
  template: CertificateTemplate;
  courses: { id: string; title: string }[];
  issued: number;
}

export interface CertificateAdminService {
  list(query: CertificateQuery): Promise<{ rows: CertificateRow[]; total: number; counts: Record<IssuedCertificateStatus | 'all', number> }>;
  get(id: string): Promise<CertificateDetail>;
  issue(id: string): Promise<IssuedCertificate>;
  revoke(id: string, reason: string): Promise<IssuedCertificate>;
  restore(id: string): Promise<IssuedCertificate>;
  listTemplates(): Promise<TemplateSummary[]>;
  getTemplate(id: string): Promise<TemplateSummary & { allCourses: { id: string; title: string; templateId: string }[] }>;
  /** Creates a template when id is null. Rejects with a conflict when the input fails validation. */
  saveTemplate(id: string | null, input: CertificateTemplateInput & { courseIds: string[] }): Promise<CertificateTemplate>;
  setDefaultTemplate(id: string): Promise<CertificateTemplate>;
  verify(credentialId: string): Promise<CertificateDetail>;
}

/* ─── Live classes ─── */

export type LiveView = 'upcoming' | 'live' | 'history' | 'cancelled';

export interface LiveQuery {
  view?: LiveView;
  search?: string;
  courseId?: string;
  instructorId?: string;
  scopeInstructorId?: string;
  page: number;
  pageSize: number;
}

export interface LiveRow {
  liveClass: LiveClass;
  phase: LiveClassPhase;
  courseTitle: string;
  instructorName: string;
}

export interface LiveAttendee {
  id: string;
  name: string;
  city: string;
  /** Taken by the room: true once they joined; false once the class ended without them. */
  attended?: boolean;
  joinedAt?: string;
}

/** What the browser needs to enter a class's room on the academy's video service. */
export interface RoomJoin {
  provider: 'jitsi' | 'jaas';
  domain: string;
  room: string;
  jwt?: string;
  subject: string;
  displayName: string;
  email?: string;
  moderator: boolean;
  recording: boolean;
}

/** The way into a class that is on: the built-in room, or an outside meeting's link. */
export type LiveJoin = { kind: 'room'; room: RoomJoin } | { kind: 'external'; link?: string };

export interface LiveDetail extends LiveRow {
  instructorTitle: string;
  /** Staff only (empty for a learner). */
  attendees: LiveAttendee[];
  attendeeTotal: number;
  recordingViews?: number;
  /** Staff only: what the room can do here. */
  /** `configured: false`: the server has no video service, so the built-in room cannot start (API 503 LIVE_ROOM_NOT_CONFIGURED). */
  room?: { provider: 'jitsi' | 'jaas'; recording: boolean; canStart: boolean; configured?: false };
  /** Learner only: their own place and attendance. */
  registered?: boolean;
  attended?: boolean;
  previous?: { id: string; title: string; startsAt: string };
  next?: { id: string; title: string; startsAt: string };
}

export interface LearnerLive {
  /** A place must be taken before the room opens, so these carry whether the learner holds one. */
  live: (LiveRow & { registered: boolean })[];
  upcoming: (LiveRow & { registered: boolean })[];
  recordings: LiveRow[];
  /** Classes this learner held a place for, once over, with whether they came. */
  history?: (LiveRow & { attended?: boolean })[];
}

/**
 * A class as the editor sends it. On an edit, `null` clears the capacity, description or chapter; left out (undefined),
 * the API keeps what was there.
 */
export type LiveClassWrite = Omit<LiveClassInput, 'capacity' | 'description' | 'chapterId'> & {
  capacity?: number | null;
  description?: string | null;
  chapterId?: string | null;
};

export interface LiveClassService {
  list(query: LiveQuery): Promise<{ rows: LiveRow[]; total: number; counts: Record<LiveView, number> }>;
  get(id: string, scopeInstructorId?: string): Promise<LiveDetail>;
  /** Rejects with a conflict when the input fails validation; `ServiceError.issues` name the fields. */
  create(input: LiveClassWrite): Promise<LiveClass>;
  update(id: string, input: LiveClassWrite): Promise<LiveClass>;
  cancel(id: string, reason: string): Promise<LiveClass>;
  sendReminder(id: string): Promise<{ sent: number }>;
  setReminders(id: string, reminders: number[]): Promise<LiveClass>;
  forLearner(): Promise<LearnerLive>;
  /** Takes or gives up a place: `registered` is the state wanted, so a retry or a double tap lands in the same place. */
  register(id: string, registered: boolean): Promise<{ registered: boolean; spotsLeft: number }>;
  /** The host opens the built-in room (or rejoins it). */
  start(id: string): Promise<{ liveClass: LiveClass; phase: LiveClassPhase; room: RoomJoin }>;
  /**
   * A learner goes in, inside the join window (taking a place if needed): the built-in room, where they are marked as
   * joined, or an outside meeting's link — the only way a learner gets that link. Staff rejoin as host.
   */
  join(id: string): Promise<LiveJoin>;
  /** The host closes the room; whoever held a place and never came is marked absent. */
  end(id: string): Promise<{ liveClass: LiveClass; phase: LiveClassPhase }>;
  /** A short-lived URL a `<video>` can play the kept recording from. */
  recordingLink(id: string): Promise<{ url: string }>;
}

/* ─── Calendar ─── */

export interface CalendarQuery {
  /** First and last IST dates in view, inclusive — YYYY-MM-DD. */
  from: string;
  to: string;
  types?: CalendarEventType[];
  courseId?: string;
  instructorId?: string;
  scopeInstructorId?: string;
  /** Whose personal reminders to include. */
  viewerId: string;
}

export interface CalendarRow {
  event: CalendarEvent;
  courseTitle?: string;
  instructorName?: string;
  /** Live classes: where the class is in its life. */
  phase?: LiveClassPhase;
  /** Assignment deadlines: learners due and how many have handed in. */
  due?: { learners: number; submitted: number };
}

export interface CalendarDetail extends CalendarRow {
  chapterTitle?: string;
  instructorTitle?: string;
  /** Added in the calendar, so it can be edited and deleted there. */
  editable: boolean;
  live?: { registered: number; capacity?: number; attended?: number };
  learnersDue?: { id: string; name: string; submitted: boolean }[];
  quiz?: { id: string; title: string; status: QuizStatus; questions: number; timeLimitMin?: number; attempts: number; passMark: number };
  /** Learners the event is shown to or reminds. */
  audienceSize?: number;
}

export interface CalendarService {
  /** `total` counts every event in the range before filters, so an empty view can say whether filters hid it. */
  list(query: CalendarQuery): Promise<{ rows: CalendarRow[]; counts: Record<CalendarEventType, number>; total: number }>;
  get(id: string, viewerId: string, scopeInstructorId?: string): Promise<CalendarDetail>;
  /** Rejects with a conflict when the input fails validation. */
  create(input: CalendarEventInput, ownerId: string): Promise<CalendarEvent>;
  update(id: string, input: CalendarEventInput): Promise<CalendarEvent>;
  remove(id: string): Promise<void>;
  setDone(id: string, done: boolean): Promise<CalendarEvent>;
}

/* ─── Notifications ─── */

export interface NotificationQuery {
  recipientId: string;
  unreadOnly?: boolean;
  category?: NotificationCategory;
  /** How many of the newest to return. */
  limit: number;
}

export interface NotificationPage {
  rows: AppNotification[];
  /** Matching the query, before the limit. */
  total: number;
  /** All unread for the recipient, whatever the filters. */
  unread: number;
  /** Per category, within the unread filter. */
  counts: Record<NotificationCategory, number>;
}

export interface NotificationDetail {
  notification: AppNotification;
  /** Other notifications of the same kind, newest first. */
  related: AppNotification[];
  /** How this kind reaches the recipient. */
  channels: Record<NotificationChannel, boolean>;
}

export interface NotificationService {
  list(query: NotificationQuery): Promise<NotificationPage>;
  get(id: string, recipientId: string): Promise<NotificationDetail>;
  setRead(ids: string[], read: boolean): Promise<void>;
  /** Returns how many were marked. */
  markAllRead(recipientId: string, category?: NotificationCategory): Promise<number>;
  remove(ids: string[]): Promise<void>;
  /** Puts removed notifications back — the undo for a removal. */
  restore(notifications: AppNotification[]): Promise<void>;
  /** Removes every notification matching the filters; returns how many. */
  clear(recipientId: string, filter?: { category?: NotificationCategory; unreadOnly?: boolean }): Promise<number>;
  getSettings(recipientId: string): Promise<NotificationSettings & { smsNumber: string }>;
  /** Rejects with a conflict when the settings fail validation. */
  saveSettings(recipientId: string, settings: NotificationSettings): Promise<NotificationSettings>;
}

/* ─── Reports ─── */

export interface ReportPoint {
  /** Period start and end, ISO. */
  from: string;
  to: string;
  value: number;
  partial?: boolean;
}

export interface ReportContext {
  window: { from: string; to: string; previousFrom: string; previousTo: string };
  /** Courses the filters select. */
  courseCount: number;
}

export interface ReportSeries {
  enrollments: ReportPoint[];
  completions: ReportPoint[];
  activeLearners: ReportPoint[];
}

export interface CourseReportRow {
  courseId: string;
  title: string;
  categoryTitle: string;
  instructorNames: string[];
  status: CourseStatus;
  enrollments: number;
  previousEnrollments: number;
  completions: number;
  /** Finished, among enrolments at least 60 days old. */
  completionRate: number;
  activeLearners: number;
  avgProgress: number;
  quizPassRate: number | null;
  assignmentPassRate: number | null;
  rating?: number;
  /** Enrolments per chart period. */
  trend: number[];
}

export interface ReportOverview extends ReportContext {
  kpis: { enrollments: Kpi; completions: Kpi; completionRate: Kpi; activeLearners: Kpi; avgProgress: Kpi };
  series: ReportSeries;
  quizzes: { attempts: Kpi; passRate: Kpi; avgScore: Kpi };
  assignments: { submitted: Kpi; passRate: Kpi; onTime: Kpi; reviewHours: Kpi };
  engagement: { lessonsCompleted: Kpi; lessonsPerLearner: Kpi; liveAttendance: Kpi };
  progressBands: { label: string; value: number }[];
  categories: { categoryId: string; title: string; enrollments: number; completionRate: number }[];
  topCourses: CourseReportRow[];
}

export interface CourseReport extends ReportContext {
  row: CourseReportRow;
  kpis: { enrollments: Kpi; completionRate: Kpi; activeLearners: Kpi; avgProgress: Kpi };
  series: ReportSeries;
  /** Enrolments that started in the period, and how far they have come. */
  funnel: { label: string; value: number }[];
  /** Share of learners in the period who have reached each chapter. */
  chapters: { chapterId: string; title: string; reached: number }[];
  quizzes: { quizId: string; title: string; attempts: number; passRate: number; avgScore: number }[];
  assignments: { assignmentId: string; title: string; submitted: number; passRate: number | null; avgScore: number | null; onTime: number | null }[];
}

export interface LearnerReportRow {
  studentId: string;
  name: string;
  city: string;
  status: StudentStatus;
  courses: number;
  completed: number;
  avgProgress: number;
  /** Average assignment score, percent. */
  assignmentAvg: number | null;
  lastActiveAt: string;
}

export type LearnerReportSort = 'name' | 'courses' | 'progress' | 'assignments' | 'lastActive';

export interface LearnerReport extends ReportContext {
  kpis: { learners: Kpi; active: Kpi; atRisk: Kpi; avgProgress: Kpi };
  segments: Record<LearnerSegment, number>;
  statuses: Record<StudentStatus, number>;
  progressBands: { label: string; value: number }[];
  rows: LearnerReportRow[];
  /** Rows matching the search, before paging. */
  total: number;
}

export interface InstructorReportRow {
  instructorId: string;
  name: string;
  title: string;
  courses: number;
  learners: number;
  completionRate: number | null;
  rating: number | null;
  reviews: number;
  reviewHours: number | null;
  onTime: number | null;
  liveClasses: number;
  attendance: number | null;
}

export interface InstructorReport extends ReportContext {
  rows: InstructorReportRow[];
  figures: { reviews: Kpi; reviewHours: Kpi; onTime: Kpi; attendance: Kpi };
}

export interface EnrolmentReport extends ReportContext {
  kpis: { enrollments: Kpi; completions: Kpi; completionRate: Kpi; selfShare: Kpi };
  series: ReportSeries;
  sources: { source: EnrollmentSource; enrollments: number; share: number; completionRate: number }[];
  categories: { categoryId: string; title: string; enrollments: number; previousEnrollments: number; completionRate: number }[];
  /** Monthly intakes and how quickly they finished, percent. Null where not enough time has passed. */
  cohorts: { month: string; enrolled: number; within30: number | null; within60: number | null; within90: number | null; toDate: number }[];
}

export interface ReportsService {
  /** Enrolments and orders per course; an instructor sees their own. Counts, never money. */
  courseSales(): Promise<CourseSalesRow[]>;
  overview(filters: ReportFilters): Promise<ReportOverview>;
  courses(filters: ReportFilters): Promise<ReportContext & { rows: CourseReportRow[] }>;
  course(courseId: string, filters: ReportFilters): Promise<CourseReport>;
  learners(filters: ReportFilters & { search?: string; sort?: ReportSortState<LearnerReportSort>; page: number; pageSize: number }): Promise<LearnerReport>;
  instructors(filters: ReportFilters): Promise<InstructorReport>;
  enrolments(filters: ReportFilters): Promise<EnrolmentReport>;
  /** Reviews in the caller's scope, hidden ones included. The API derives the scope from the token. */
  reviews(query: StaffReviewQuery): Promise<StaffCourseReviewPage>;
  /** An admin or the platform's owner only. */
  hideReview(id: string): Promise<StaffCourseReview>;
  showReview(id: string): Promise<StaffCourseReview>;
}

export interface StaffReviewQuery {
  status?: CourseReviewStatus;
  courseId?: string;
  /** Limits results to one instructor's courses in the demo build; the API takes this from the token. */
  scopeInstructorId?: string;
  page: number;
  pageSize: number;
}

export interface ReportSortState<K extends string = string> {
  key: K;
  direction: 'asc' | 'desc';
}

/* ─── Settings ─── */

export interface SettingsService {
  get(): Promise<SettingsRecord>;
  /** Saves one section. Rejects with a conflict when it fails validation. */
  save<S extends SettingsSection>(section: S, value: LmsSettings[S]): Promise<SettingsRecord>;
}

/* ─── Help centre ─── */

export interface HelpCategoryRow {
  category: HelpCategory;
  articleCount: number;
}

export interface HelpArticleRow {
  article: HelpArticle;
  categoryName: string;
}

export interface HelpQuery {
  search?: string;
  categoryId?: string;
  /** Limits results to what this role would see; 'all' articles always show. */
  audience?: HelpAudience;
}

export interface HelpArticleDetail extends HelpArticleRow {
  related: HelpArticleRow[];
}

export interface HelpService {
  listCategories(audience?: HelpAudience): Promise<HelpCategoryRow[]>;
  listArticles(query: HelpQuery): Promise<HelpArticleRow[]>;
  /** Rejects with 'not-found' when the slug doesn't match a published article. */
  getArticle(slug: string, audience?: HelpAudience): Promise<HelpArticleDetail>;
}

/* ─── Account ─── */

export interface AccountService {
  /**
   * Deletes the signed-in learner's own account once their password confirms it, and ends every session.
   * Rejects with 'forbidden' when the password is wrong, or when the account is staff — an academy
   * administrator closes those.
   */
  deleteAccount(password: string): Promise<void>;
}

/* ─── Media ─── */

export interface MediaService {
  /** Stores a file and resolves with what the lesson/assignment keeps; `onProgress` gets 0–100. */
  upload(file: File, onProgress?: (percent: number) => void): Promise<MediaFile>;
}

/* ─── Platform (Super Admin) ─── */

/*
 * The platform surface at `/superadmin` on the API. It is deliberately apart from the academy's
 * services: the academy admin cannot reach any of it. Its writes are the platform's own: academy admins,
 * and new academies — each created empty, with its first admin.
 */

export interface PlatformOverview {
  users: { total: number; students: number; instructors: number; admins: number; superadmins: number };
  people: { studentProfiles: number; suspendedStudents: number; instructorProfiles: number; inactiveInstructors: number };
  courses: { total: number; published: number; draft: number; archived: number };
  learning: { enrollments: number; certificatesIssued: number };
  audit: { events: number };
  /** Course sales (docs/16 §2.4): orders opened, orders paid, and the paise they brought in. */
  sales: { orders: number; paid: number; revenue: number };
  /** Requests waiting for the platform team. */
  inbox: { new: number; inProgress: number };
  generatedAt: string;
}

/** A directory row. The API selects these columns explicitly, so no password material can reach here. */
export interface PlatformUserRow {
  id: string;
  name: string;
  email: string;
  role: Role;
  descriptor: string;
  instructorId?: string;
  /** When a super admin closed the account; absent means it is active. Only admins carry one today. */
  deactivatedAt?: string;
  createdAt: string;
  updatedAt: string;
  /** The workspace the account belongs to. Absent for a super admin, which belongs to the platform. */
  tenant?: { id: string; name: string; slug: string };
}

/** What it takes to create a staff admin. The role is the server's to decide, so it is not here; the workspace is the platform's one. */
export interface AdminInput {
  name: string;
  email: string;
  password: string;
}

/** The only things about an admin that can be changed. Neither role nor password is among them. */
export interface AdminUpdate {
  name?: string;
  email?: string;
}

export interface PlatformAuditEntry {
  id: string;
  action: string;
  targetType: string;
  targetId?: string;
  actor: { id?: string; email: string; role: string };
  /** Free-shaped context the API parsed out of its JSON column. */
  meta: Record<string, unknown>;
  createdAt: string;
}

export interface PlatformSystemStatus {
  database: { ok: boolean; latencyMs?: number };
  email: { queued: number; sent: number; failed: number; oldestQueuedAt?: string };
  media: { files: number; totalBytes: number };
  process: { environment: string; uptimeSeconds: number };
  generatedAt: string;
}

/** The API's paged envelope: the rows for this page, and what was asked for. */
export interface PlatformPage<T> {
  rows: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface PlatformPaging {
  page?: number;
  pageSize?: number;
}

export interface PlatformAuditQuery extends PlatformPaging {
  /** Only actions starting with this: `mlm.` is the affiliate program's. */
  prefix?: string;
}

export interface PlatformUserQuery extends PlatformPaging {
  /** Matches a fragment of a name or an email address. */
  search?: string;
  role?: Role;
}

/** One permission as the editor shows it: what it is called, what it means, whether the admin holds it. */
export interface PlatformPermission {
  key: PermissionKey;
  label: string;
  description: string;
  granted: boolean;
}

/** The catalogue as the API groups it — the frontend renders this rather than rebuilding it. */
export interface PlatformPermissionGroup {
  group: PermissionGroup;
  label: string;
  permissions: PlatformPermission[];
}

export interface PlatformPermissionState {
  admin: PlatformUserRow;
  /** The keys held right now, in catalogue order. */
  granted: PermissionKey[];
  groups: PlatformPermissionGroup[];
  /** Keys in the database that the catalogue no longer knows. They grant nothing. */
  unknown: string[];
}

export interface PlatformService {
  overview(): Promise<PlatformOverview>;
  listAdmins(query?: PlatformPaging): Promise<PlatformPage<PlatformUserRow>>;
  listUsers(query?: PlatformUserQuery): Promise<PlatformPage<PlatformUserRow>>;
  /** Newest first, as the API returns them. */
  listAudit(query?: PlatformAuditQuery): Promise<PlatformPage<PlatformAuditEntry>>;
  system(): Promise<PlatformSystemStatus>;

  /* Admin management — the only writes on this service. Each one answers with the admin as it now
   * stands, and none of them can change a role: that is fixed by the API. */
  createAdmin(input: AdminInput): Promise<PlatformUserRow>;
  updateAdmin(id: string, changes: AdminUpdate): Promise<PlatformUserRow>;
  /** Keeps the account and closes it — sign-in is refused until it is reactivated. */
  deactivateAdmin(id: string): Promise<PlatformUserRow>;
  reactivateAdmin(id: string): Promise<PlatformUserRow>;

  /* One admin's permissions, one key at a time. Each call answers with the whole state as it now
   * stands, so the editor never has to guess what the change did. */
  adminPermissions(id: string): Promise<PlatformPermissionState>;
  grantPermission(id: string, key: PermissionKey): Promise<PlatformPermissionState>;
  revokePermission(id: string, key: PermissionKey): Promise<PlatformPermissionState>;

  /* A message to one audience, and the history of them from the audit log. */
  broadcastAudienceCount(audience: BroadcastAudience): Promise<{ audience: BroadcastAudience; count: number }>;
  sendBroadcast(input: BroadcastInput): Promise<BroadcastResult>;
  listBroadcasts(query?: PlatformPaging): Promise<PlatformPage<BroadcastHistoryRow>>;

  /* The platform team's inbox: contact and support requests, newest first. */
  listInquiries(query?: InquiryQuery): Promise<InquiryListResult>;
  updateInquiry(id: string, changes: { status?: InquiryStatus; note?: string }): Promise<Inquiry>;
}

export interface InquiryQuery extends PlatformPaging {
  status?: InquiryStatus;
  kind?: InquiryKind;
  search?: string;
}

/* ─── Payment gateways (Super Admin, SAAS-017) ─── */

/*
 * The gateways the platform can take academy payments through, configured at runtime by a super admin.
 * Each gateway has two credential slots, test and live, stored apart and sealed on the server with its
 * PAYMENT_CREDENTIALS_KEY (a deployment secret, never entered in the panel). Nothing here ever carries a
 * secret back — a stored secret shows only as "set", a key id only as a masked hint. The browser never
 * chooses the gateway for a payment either; the server opens every checkout with the one that is active.
 */

export type GatewayEnvironment = 'test' | 'live';

export const GATEWAY_ENVIRONMENTS: readonly GatewayEnvironment[] = ['test', 'live'];

/** One credential a gateway needs. A secret one is write-only: it can be replaced, never read. */
export interface GatewayField {
  key: string;
  label: string;
  secret: boolean;
  /** Where to find it, in the gateway's dashboard. */
  help?: string;
}

/** What is stored for one environment — flags and masks only. */
export interface GatewayCredentialView {
  /** Usable credentials are stored for this environment. */
  configured: boolean;
  /** Stored, but sealed under another key (or unreadable without one): must be entered again. */
  needsReentry: boolean;
  /** Masked, e.g. `{ keyId: 'rzp_test_…te01' }`. Never a whole value. */
  hint: Record<string, string>;
  /** Which secret fields have a stored value. The values themselves never leave the server. */
  secretsSet: string[];
  configuredAt: string | null;
}

export interface GatewayView {
  /** 'razorpay' | 'vyapargateway' */
  provider: string;
  label: string;
  /** Whether the platform has an adapter for it. Without one its credentials can be stored, but it cannot take payments. */
  implemented: boolean;
  /** Why an unimplemented gateway cannot take payments. */
  unavailableReason?: string;
  /** The fields are what is publicly confirmed, pending the gateway's merchant contract. */
  fieldsProvisional: boolean;
  enabled: boolean;
  /** Whose credentials new payments use. */
  environment: GatewayEnvironment;
  /** The gateway new payments go through. At most one is active. */
  isActive: boolean;
  /** Usable credentials for `environment`. */
  configured: boolean;
  /** For `environment`. */
  needsReentry: boolean;
  /** Test and live, stored separately. */
  credentials: Record<GatewayEnvironment, GatewayCredentialView>;
  /** As in `credentials[environment]`. */
  hint: Record<string, string>;
  secretsSet: string[];
  configuredAt: string | null;
  /** Whether it can be set active now; the server says why not. */
  canActivate: boolean;
  activationBlockedReason?: string;
  /** Whether "Test configuration" can check the credentials with the gateway. */
  testSupported: boolean;
  fields: GatewayField[];
  updatedAt: string | null;
}

export interface GatewayList {
  rows: GatewayView[];
  /** Whether the deployment set PAYMENT_CREDENTIALS_KEY. Until it does, a save is refused by the server. */
  vaultConfigured: boolean;
  /** The provider new payments go through, or null when online payment is off. */
  active: string | null;
}

export interface GatewayConfigInput {
  /** The slot being saved. The other environment's credentials are untouched. */
  environment: GatewayEnvironment;
  /** A field left blank (or left out) keeps what is stored. Every field is required where nothing is. */
  credentials: Record<string, string>;
}

export interface GatewayUpdate {
  enabled?: boolean;
  /** Which environment's credentials new payments use. Only one with credentials can be chosen. */
  environment?: GatewayEnvironment;
}

/** What the server found when it checked a gateway's credentials. No payment is made. */
export interface GatewayTestResult {
  /** Never true unless the gateway was asked and accepted them. */
  ok: boolean;
  /** Whether the gateway was actually asked. False: nothing was checked — not a failure, not a success. */
  checked: boolean;
  environment: GatewayEnvironment;
  detail: string;
}

export interface PaymentGatewayService {
  list(): Promise<GatewayList>;
  get(provider: string): Promise<GatewayView>;
  /** Stores one environment's credentials. A blank field keeps its stored value; the answer carries only masked hints. */
  configure(provider: string, input: GatewayConfigInput): Promise<GatewayView>;
  /** Enables or disables a gateway, or switches its environment. The active gateway cannot be disabled. */
  update(provider: string, changes: GatewayUpdate): Promise<GatewayView>;
  /** Checks an environment's stored credentials (the current one when omitted) without charging anything. */
  test(provider: string, environment?: GatewayEnvironment): Promise<GatewayTestResult>;
  /** Makes this the gateway new payments go through. */
  activate(provider: string): Promise<GatewayView>;
  /** Turns online payment off: no gateway is active, and invoices are paid by hand. */
  deactivate(): Promise<{ deactivated: string | null }>;
}

/** The platform's course orders, coupons and payment events, for the Super Admin (docs/16 §2.4). */
export interface SalesService {
  orders(query?: SalesOrderQuery): Promise<SalesOrderList>;
  order(id: string): Promise<SalesOrderDetail>;
  /** Refunds the whole order through the gateway that took the money. */
  refund(id: string, input: { reason: string; note?: string }): Promise<SalesOrderDetail>;
  ordersCsv(query?: Pick<SalesOrderQuery, 'status' | 'search'>): Promise<string>;
  coupons(): Promise<Coupon[]>;
  createCoupon(input: CouponInput): Promise<Coupon>;
  updateCoupon(id: string, changes: CouponUpdate): Promise<Coupon>;
  events(query?: { page?: number; pageSize?: number }): Promise<{ rows: PaymentEventRow[]; total: number; page: number; pageSize: number }>;
}

/**
 * Registration (docs/16 §2.5). Public: no session is needed. A registration's result carries the new account's session
 * for `useSession().adopt`.
 */
export interface InstructorApplicationInput {
  name: string;
  email: string;
  phone: string;
  password: string;
  title: string;
  bio: string;
  expertise: string[];
  yearsTeaching: number;
  links: string[];
}

export interface SignupService {
  /** A learner registers: a code is emailed (`verify`), or — where verification is off — they are signed in. */
  register(input: {
    name: string;
    email: string;
    phone: string;
    password: string;
    referralCode?: string;
    preferredLeg?: MlmLeg;
    /** The leg of the sponsor that the sponsor's link named. */
    requestedLeg?: MlmLeg;
  }): Promise<AccountStartResult>;
  /** Someone applies to teach: a code is emailed; once confirmed the application waits for approval. */
  applyToTeach(input: InstructorApplicationInput): Promise<AccountVerificationPending | InstructorRequestPending>;
  /** Where a learner's or instructor's own registration stands; `not-found` once used, replaced or expired long ago. */

  /** A fresh code; refused before `resendAvailableAt`, and after a few. */
  resendVerification(verificationId: string): Promise<AccountVerificationPending>;
  /** Confirms the code: a learner is created and signed in; an instructor's request goes to the Admin. */
  confirmVerification(verificationId: string, code: string): Promise<AccountCreated | InstructorRequestPending>;
}

/* ─── Learner invitations and course links ─── */

/** Where a learner invitation stands, as the Admin sees it. Only a pending one can be used or withdrawn. */
export type InvitationStatus = 'pending' | 'accepted' | 'expired' | 'revoked';

export interface InvitationRow {
  id: string;
  /** The address the link is bound to, or null for a link anyone may use once. */
  email: string | null;
  status: InvitationStatus;
  expiresAt: string;
  createdAt: string;
  usedAt: string | null;
}

/** What an invitation link shows before anything is asked: whose LMS, and for which address. */
export interface InvitationDetails {
  lms: { name: string; slug: string };
  role: 'student';
  email: string | null;
  expiresAt: string;
  /** False while the LMS takes nobody new. */
  open: boolean;
}

/** What a course enrolment link shows: the course, and the LMS it belongs to. */
export interface CourseLinkDetails {
  lms: { name: string; slug: string };
  /** `sale`: free to join, paid (bought on the course page once signed in), or not open yet. */
  course: { id: string; title: string; slug: string; sale?: CourseSale };
  open: boolean;
}

export type LearnerSession = { token: string; user: UserProfile };

/**
 * Learner invitations (`/invite/<token>`) and course enrolment links (`/courses/<id>/enroll`). The token or the course
 * names the Admin's LMS; the server decides the workspace and the role — nothing here sends either. The public calls
 * reject with reason `INVITE_INVALID` for a link that is malformed, unknown, used, withdrawn or expired.
 */
export interface InvitationService {
  describe(token: string): Promise<InvitationDetails>;
  /** A new learner accepts: a code is emailed, and once confirmed the account is created in the invitation's LMS. */
  register(token: string, input: { name: string; email: string; password: string }): Promise<AccountStartResult>;
  /** Someone who already learns at that LMS accepts by signing in. */
  signIn(token: string, input: { email: string; password: string }): Promise<LearnerSession>;
  /** The published course a course link names; `not-found` for an unknown, draft or private one. */
  courseLink(courseId: string): Promise<CourseLinkDetails>;
  /** A new learner joins the course's LMS and is enrolled when its policy allows; `enrolment` says why not. */
  joinCourse(courseId: string, input: { name: string; email: string; password: string }): Promise<AccountStartResult>;
  /** Admin: this LMS's invitations, newest first. */
  list(): Promise<InvitationRow[]>;
  /** Admin: a new link. `url` is shown once — only its hash is kept. Emailed too when an address is given. */
  create(input: { email?: string }): Promise<{ invitation: InvitationRow; url: string }>;
  /** Admin: withdraws a pending invitation; `conflict` once accepted. */
  revoke(id: string): Promise<InvitationRow>;
}

/**
 * The sandbox payment gateway's test checkout (SAAS-030): development and E2E only. These calls play the gateway's
 * own page; the platform learns the outcome only from the gateway's signed webhook.
 */
export interface SandboxGatewayService {
  order(orderId: string): Promise<{ orderId: string; amount: number; currency: string; receipt: string; status: string }>;
  pay(orderId: string, outcome: 'success' | 'failure'): Promise<{ paymentId: string; status: string; webhookDelivered: boolean }>;
}

export type { BrandAsset, BrandAssetKind, PlatformBranding, PlatformBrandingSettings, SavedBrandAsset };

/** The company website's own requests (SAAS-027): the contact form. Public. */
export interface SiteService {
  /** Sends a question, an order enquiry or a support request to the Super Admin's inbox. */
  contact(input: PublicInquiryInput): Promise<void>;
  /** The website's editable words, public. */
  content(): Promise<SiteContent>;
  /** The active affiliate plan's published terms, public. */
  affiliateProgram(): Promise<PublicAffiliateProgram>;
  /** The same document for the Super Admin to edit. */
  adminContent(): Promise<SiteContent>;
  saveContent(input: SiteContent): Promise<SiteContent>;
  /** The home page's figures, counted from the records. Public. */
  stats(): Promise<PublicStats>;
  /** Instructors teaching a listed course: no email, no phone. Public. */
  mentors(): Promise<PublicMentor[]>;
  mentor(id: string): Promise<{ mentor: PublicMentor; courseSlugs: string[] }>;
  /** Bundles on sale now. Public. */
  bundles(): Promise<PublicBundle[]>;
  bundle(slug: string): Promise<PublicBundle>;
  /** Live posts, without their bodies. Public. */
  posts(kind?: BlogKind): Promise<BlogPost[]>;
  post(slug: string): Promise<BlogPost>;
  /** What this learner would get from a bundle now. Holds nothing. */
  quoteBundle(bundleId: string): Promise<BundleQuote>;
  /** Opens the learner's order: the server prices it. */
  startBundlePurchase(bundleId: string): Promise<BundleCheckoutStart>;
  confirmBundlePurchase(purchaseId: string, completion: { paymentId: string; signature: string }): Promise<BundleConfirmation>;
  getBundlePurchase(purchaseId: string): Promise<BundlePurchaseView>;
  adminBundles(): Promise<AdminBundle[]>;
  createBundle(input: BundleInput): Promise<AdminBundle>;
  updateBundle(id: string, input: BundleInput): Promise<AdminBundle>;
  deleteBundle(id: string): Promise<void>;
  adminPosts(): Promise<BlogPost[]>;
  createPost(input: BlogPostInput): Promise<BlogPost>;
  updatePost(id: string, input: BlogPostInput): Promise<BlogPost>;
  deletePost(id: string): Promise<void>;
  /** Places an uploaded image on the website, so a visitor can read it. */
  placeImage(mediaId: string): Promise<{ url: string }>;
}

export interface BundleQuote {
  price: number;
  charge: number;
  alreadyHeldCourseIds: string[];
}

export interface BundleCheckoutStart {
  purchase: BundlePurchaseView;
  checkout: CoursePurchaseCheckout;
}

export interface BundleConfirmation {
  purchase: BundlePurchaseView;
  outcome: { status: string; enrolled: boolean; message: string };
}

/**
 * The platform's own logo and favicon — the ZuviloAI website, its sign-in screens and the workspace chrome. One set
 * for the whole platform; an academy's appearance settings are `SettingsService`'s and never reach it.
 */
export interface BrandingService {
  /** What every page shows. Public. A `null` asset is the built-in one. Addresses are ready to load. */
  current(): Promise<PlatformBranding>;
  /** Super Admin: what is saved. */
  settings(): Promise<PlatformBrandingSettings>;
  /** Super Admin: replaces the logo and/or the favicon. The server judges each file; a refusal names its field. */
  save(files: Partial<Record<BrandAssetKind, File>>): Promise<PlatformBrandingSettings>;
  /** Super Admin: back to the built-in asset — for one kind, or both. */
  restore(kind?: BrandAssetKind): Promise<PlatformBrandingSettings>;
}

/* ─── Affiliate program (the learner's own) ─── */

/** The signed-in learner's affiliate surface (MLM-001), and the public referral landing data. */
export interface AffiliateService {
  /** The learner's own record, or null when they have not joined the program. */
  me(): Promise<AffiliateMe | null>;
  /** A learner already in the academy opts in, naming a sponsor's code or none. */
  enrol(input: AffiliateEnrolInput): Promise<AffiliateMe>;
  setPreferredLeg(leg: MlmLeg): Promise<AffiliateMe>;
  /** The eligible course(s) and where the learner stands with each. */
  activation(): Promise<AffiliateActivation>;
  /** What a referral link shows a visitor; `REFERRAL_INVALID` for a bad code. */
  referral(code: string): Promise<ReferralInfo>;
  /** The referral link as a QR image, by URL — public, so an `<img>` can load it. */
  qrUrl(code: string): string;
  /* The network (MLM-002). */
  /** The caller's subtree, or a downline member's (`root`), a few levels at a time. */
  tree(root?: string, depth?: number): Promise<TreeNodeView>;
  /** Everyone under the caller, flat, with counts. */
  team(query?: TeamQuery): Promise<TeamPage>;
  /** The people the caller referred, wherever they were placed. */
  referrals(): Promise<TeamRow[]>;
  /* Volume (MLM-003). */
  /** The caller's leg pools: lifetime and unmatched CV per leg, what the next matching run can pay on. */
  figures(): Promise<AffiliateFigures>;
  /** The caller's own paid purchases of eligible courses, newest first. */
  orders(query?: { page?: number; pageSize?: number }): Promise<Paged<AffiliateOrderRow>>;
  /** Every credit and reversal on the caller's legs, newest first. */
  cvLedger(query?: Pick<MlmCvQuery, 'leg' | 'kind' | 'page' | 'pageSize'>): Promise<CvLedgerResult>;
}

/* ─── Affiliate earnings (docs/15 MLM-004 to MLM-008) ─── */

export interface PageQuery {
  page?: number;
  pageSize?: number;
}

/** The member's own earnings, wallet, KYC and withdrawals. */
export interface AffiliateEarningsService {
  earnings(): Promise<AffiliateEarnings>;
  matchingRuns(query?: PageQuery): Promise<Paged<MlmMatchingRunRow>>;
  commissions(query?: PageQuery): Promise<Paged<MlmCommissionRow>>;
  rankHistory(query?: PageQuery): Promise<Paged<MlmRankHistoryRow>>;
  rewards(query?: PageQuery): Promise<Paged<MlmRewardRow>>;
  walletEntries(query?: PageQuery): Promise<Paged<MlmWalletEntryRow>>;
  kyc(): Promise<MlmKycView>;
  submitKyc(input: MlmKycInput): Promise<MlmKycView>;
  withdrawals(query?: PageQuery): Promise<Paged<MlmWithdrawalRow>>;
  requestWithdrawal(amount: number): Promise<MlmWithdrawalRow>;
  cancelWithdrawal(id: string): Promise<void>;
}

/** The program's money, for the Super Admin. */
export interface PlatformEarningsService {
  dashboard(): Promise<MlmDashboard>;
  matchingRuns(query?: PageQuery & { date?: string; affiliateId?: string }): Promise<Paged<MlmMatchingRunRow>>;
  runMatching(): Promise<{ matched: number; paid: number; held: number; failed: number }>;
  commissions(query?: PageQuery & { status?: MlmCommissionStatus; affiliateId?: string }): Promise<Paged<MlmCommissionRow>>;
  releaseCommission(id: string, reason: string): Promise<void>;
  writeOffCommission(id: string, reason: string): Promise<void>;
  /** The active plan version's rank tiers, lowest first. */
  ranks(): Promise<MlmRankTier[]>;
  rankHistory(query?: PageQuery & { affiliateId?: string }): Promise<Paged<MlmRankHistoryRow>>;
  /** Checks one member's legs against the ranks now; `reached` is how many new ranks that gave them. */
  recalculateRank(id: string): Promise<{ reached: number }>;
  rewards(query?: PageQuery & { status?: MlmRewardStatus; affiliateId?: string }): Promise<Paged<MlmRewardRow>>;
  approveReward(id: string, amount?: number): Promise<void>;
  fundReward(id: string): Promise<void>;
  payReward(id: string): Promise<void>;
  rejectReward(id: string, reason: string): Promise<void>;
  wallets(query?: PageQuery & { search?: string }): Promise<Paged<MlmWalletRow>>;
  walletEntries(affiliateId: string, query?: PageQuery): Promise<Paged<MlmWalletEntryRow>>;
  adjustWallet(affiliateId: string, amount: number, reason: string): Promise<void>;
  kyc(query?: PageQuery & { status?: MlmKycStatus }): Promise<Paged<MlmKycRow>>;
  /** One member's identity check, masked; `not-found` when they submitted none. */
  memberKyc(affiliateId: string): Promise<MlmKycRow>;
  verifyKyc(affiliateId: string): Promise<void>;
  rejectKyc(affiliateId: string, reason: string): Promise<void>;
  /** A document attached to a member's KYC, for review. */
  kycDocument(affiliateId: string, assetId: string): Promise<Blob>;
  withdrawals(query?: PageQuery & { status?: MlmWithdrawalStatus }): Promise<Paged<MlmWithdrawalRow>>;
  approveWithdrawal(id: string): Promise<void>;
  rejectWithdrawal(id: string, reason: string, notPaidConfirmed?: boolean): Promise<void>;
  markWithdrawalPaid(id: string, reference: string): Promise<void>;
  payouts(): Promise<MlmPayoutBatchRow[]>;
  createPayout(withdrawalIds: string[]): Promise<MlmPayoutBatchRow>;
  payoutCsv(id: string): Promise<string>;
  closePayout(id: string): Promise<void>;
  liability(period?: string): Promise<MlmLiabilityReport>;
  liabilityCsv(period?: string): Promise<string>;
}

/* ─── Affiliate program (Super Admin) ─── */

/** The affiliate program's management surface (docs/15 §5.3). MLM-000: the plan; later modules add the rest. */
export interface PlatformAffiliateService {
  plan(): Promise<MlmPlanOverview>;
  listPlanVersions(): Promise<MlmPlanVersionSummary[]>;
  getPlanVersion(id: string): Promise<MlmPlanTerms>;
  /** A new draft: full terms, or where to start from (the active version, a named one, or the published plan). */
  createPlanVersion(input: MlmPlanTermsInput | { fromVersionId?: string; programTenantId?: string }): Promise<MlmPlanTerms>;
  /** Replaces a draft's terms, ranks and bands; refused once the version has left draft. */
  updatePlanVersion(id: string, input: MlmPlanTermsInput): Promise<MlmPlanTerms>;
  /** The one change an active version allows: which courses generate CV. */
  setEligibleCourses(id: string, courseIds: string[]): Promise<MlmPlanTerms>;
  /** Makes a draft the version the program runs under, retiring the one before. */
  activatePlanVersion(id: string): Promise<MlmPlanTerms>;
  retirePlanVersion(id: string): Promise<MlmPlanTerms>;
  deletePlanDraft(id: string): Promise<void>;
  programCourses(tenantId: string): Promise<MlmProgramCourse[]>;
  /* Members, network, placements and sponsors (MLM-002). */
  listMembers(query?: AffiliateMemberQuery): Promise<MemberListResult>;
  getMember(id: string): Promise<AffiliateMemberRow>;
  /** Suspend, reactivate or terminate; activation itself comes from the eligible purchase. */
  setMemberStatus(id: string, status: 'active' | 'suspended' | 'terminated', note?: string): Promise<AffiliateMemberRow>;
  memberTree(id: string, depth?: number): Promise<TreeNodeView>;
  memberAncestors(id: string): Promise<TreeAncestor[]>;
  memberTeam(id: string, query?: TeamQuery): Promise<TeamPage>;
  /** A manual placement or move with a reason; refused for a cycle, a filled position, or a team unless `moveSubtree`. */
  placeMember(id: string, input: ManualPlacementInput): Promise<AffiliateMemberRow>;
  changeSponsor(id: string, sponsorId: string | null, reason: string): Promise<AffiliateMemberRow>;
  placements(query?: { affiliateId?: string; tenantId?: string; page?: number; pageSize?: number }): Promise<PlacementListResult>;
  sponsors(query?: { tenantId?: string; search?: string; page?: number; pageSize?: number }): Promise<SponsorListResult>;
  /** The genealogy under a node as CSV text, for the page to hand the browser as a download. */
  networkCsv(root: string): Promise<string>;
  /* Products, orders, the CV ledger and carry-forward (MLM-003). */
  /** The active version's eligible courses against the program LMS's catalogue; null `active` when no version runs. */
  products(): Promise<MlmProducts>;
  /** The one change the active version allows: which courses generate CV. Refused when it would leave none. */
  setProducts(eligibleCourseIds: string[]): Promise<MlmProducts>;
  orders(query?: MlmOrderQuery): Promise<OrderListResult>;
  getOrder(id: string): Promise<MlmOrderRow>;
  /** A refund made in the gateway's dashboard, a chargeback, or a correction: the order's credits are negated, once. */
  reverseOrder(id: string, reason: MlmReversalReason, note?: string): Promise<MlmOrderRow>;
  cvLedger(query?: MlmCvQuery): Promise<CvLedgerResult>;
  /** The ledger as CSV text, for the page to hand the browser as a download. */
  cvCsv(query?: MlmCvQuery): Promise<string>;
  carryForward(query?: { tenantId?: string; search?: string; page?: number; pageSize?: number }): Promise<CarryForwardResult>;
  /** A signed correction to one leg's unmatched pool, with a reason. Refused below zero; lifetime CV never moves. */
  adjustCarryForward(id: string, input: MlmCarryAdjustInput): Promise<MlmLegFigures>;
}

export interface MlmProducts {
  active: { id: string; version: number; programTenantId: string; eligibleCourseIds: string[] } | null;
  courses: MlmProgramCourse[];
}

export interface OrderListResult {
  rows: MlmOrderRow[];
  total: number;
  page: number;
  pageSize: number;
  counts: Record<MlmOrderStatus | 'all', number>;
}

export interface CvLedgerResult {
  rows: MlmCvLedgerRow[];
  total: number;
  page: number;
  pageSize: number;
}

export interface CarryForwardResult {
  rows: MlmCarryForwardRow[];
  total: number;
  page: number;
  pageSize: number;
}

export interface MemberListResult {
  rows: AffiliateMemberRow[];
  total: number;
  page: number;
  pageSize: number;
  counts: Record<AffiliateStatus | 'all', number>;
}

export interface PlacementListResult {
  rows: PlacementHistoryRow[];
  total: number;
  page: number;
  pageSize: number;
}

export interface SponsorListResult {
  rows: SponsorRow[];
  total: number;
  page: number;
  pageSize: number;
}

export interface Services {
  signup: SignupService;
  invitations: InvitationService;
  site: SiteService;
  branding: BrandingService;
  sandbox: SandboxGatewayService;
  media: MediaService;
  catalog: CatalogService;
  dashboard: DashboardService;
  courses: CourseAdminService;
  categories: CategoryAdminService;
  chapters: ChapterAdminService;
  lessons: LessonAdminService;
  quizzes: QuizAdminService;
  assignments: AssignmentAdminService;
  students: StudentAdminService;
  instructors: InstructorAdminService;
  learning: LearningService;
  certificates: CertificateAdminService;
  live: LiveClassService;
  calendar: CalendarService;
  notifications: NotificationService;
  reports: ReportsService;
  settings: SettingsService;
  help: HelpService;
  learner: LearnerService;
  enrollment: EnrollmentService;
  admin: AdminService;
  platform: PlatformService;
  sales: SalesService;
  paymentGateways: PaymentGatewayService;
  account: AccountService;
  affiliatesPlatform: PlatformAffiliateService;
  affiliateEarnings: AffiliateEarningsService;
  platformEarnings: PlatformEarningsService;
  affiliate: AffiliateService;
}

export class ServiceError extends Error {
  constructor(
    message: string,
    public readonly code: 'network' | 'not-found' | 'forbidden' | 'conflict' | 'unknown' = 'unknown',
    /**
     * The API's stable code, when it gave one (`VALIDATION_FAILED`, `LIMIT_REACHED`, …). The subscription
     * refusals among them (§34) are shown as states: `lib/billingStates.ts`.
     */
    public readonly reason?: string,
    /** The API's per-field issues, when it gave any: `field` is the request body's key (`email`, `name`, …). */
    public readonly issues?: { field: string; message: string }[],
    /** The HTTP status the API answered with, when there was one — 401 and 409 share the `conflict` code. */
    public readonly status?: number,
  ) {
    super(message);
    this.name = 'ServiceError';
  }
}
