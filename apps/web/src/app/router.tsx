import { lazy, Suspense, type ReactNode } from 'react';
import { createBrowserRouter, Navigate, useLocation, type RouteObject } from 'react-router-dom';
import { countVisit } from '@/lib/siteTelemetry';
import { applyPageMeta } from './pageMeta';
import { useSession } from '@/providers/SessionProvider';
import { API_MODE } from '@/lib/apiMode';
import { homeFor } from '@/lib/roleHome';
import { workspaceRedirect } from '@/lib/workspaceAccess';
import { AppShell } from '@/shell/AppShell';
import { NotFoundPage } from '@/pages/NotFoundPage';
import { PageLoading } from '@/pages/PageLoading';
import { Button } from '@/components/ui/Button/Button';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { getToken } from '@/services/http/client';
import { MarketingChrome } from '@/pages/marketing/MarketingChrome';

const DesignSystemLayout = lazy(() => import('@/pages/design-system/DesignSystemLayout'));
const Foundations = lazy(() => import('@/pages/design-system/chapters/Foundations'));
const Components = lazy(() => import('@/pages/design-system/chapters/Components'));
const LearningPatterns = lazy(() => import('@/pages/design-system/chapters/LearningPatterns'));
const States = lazy(() => import('@/pages/design-system/chapters/States'));
const Responsive = lazy(() => import('@/pages/design-system/chapters/Responsive'));
const Specimen = lazy(() => import('@/pages/design-system/preview/SpecimenRoute'));
const Dashboard = lazy(() => import('@/pages/dashboard/DashboardPage'));
const CourseList = lazy(() => import('@/pages/courses/CourseListPage'));
const CourseSales = lazy(() => import('@/pages/courses/CourseSalesPage'));
const CourseEditor = lazy(() => import('@/pages/courses/CourseEditorPage'));
const CourseLayout = lazy(() => import('@/pages/courses/CourseLayout'));
const CourseOverview = lazy(() => import('@/pages/courses/CourseOverviewPage'));
const Curriculum = lazy(() => import('@/pages/courses/CurriculumPage'));
const CoursePreview = lazy(() => import('@/pages/courses/CoursePreviewPage'));
const ChapterOverview = lazy(() => import('@/pages/courses/chapters/ChapterOverviewPage'));
const LessonList = lazy(() => import('@/pages/courses/lessons/LessonListPage'));
const LessonEditor = lazy(() => import('@/pages/courses/lessons/LessonEditorPage'));
const QuizList = lazy(() => import('@/pages/quizzes/QuizListPage'));
const QuizBuilder = lazy(() => import('@/pages/quizzes/QuizBuilderPage'));
const Categories = lazy(() => import('@/pages/categories/CategoriesPage'));
const LearnHome = lazy(() => import('@/pages/learn/LearnHomePage'));
const MyLearning = lazy(() => import('@/pages/learn/MyLearningPage'));
const CourseLearning = lazy(() => import('@/pages/learn/CourseLearningPage'));
const LessonPlayer = lazy(() => import('@/pages/learn/LessonPlayerPage'));
const LearnerAssignments = lazy(() => import('@/pages/learn/CourseworkPages').then((m) => ({ default: m.LearnerAssignmentsPage })));
const LearnerAssignment = lazy(() => import('@/pages/learn/CourseworkPages').then((m) => ({ default: m.LearnerAssignmentPage })));
const LearnerAssessments = lazy(() => import('@/pages/learn/CourseworkPages').then((m) => ({ default: m.LearnerAssessmentsPage })));
const Certificates = lazy(() => import('@/pages/certificates/CertificatesPage'));
const CertificateDetail = lazy(() => import('@/pages/certificates/CertificateDetailPage'));
const CertificateTemplates = lazy(() => import('@/pages/certificates/TemplatesPage'));
const TemplateEditor = lazy(() => import('@/pages/certificates/TemplatesPage').then((m) => ({ default: m.TemplateEditorPage })));
const MyCertificates = lazy(() => import('@/pages/certificates/LearnerCertificates').then((m) => ({ default: m.MyCertificatesPage })));
const MyCertificate = lazy(() => import('@/pages/certificates/LearnerCertificates').then((m) => ({ default: m.MyCertificatePage })));
const Verify = lazy(() => import('@/pages/certificates/LearnerCertificates').then((m) => ({ default: m.VerifyPage })));
const LiveClasses = lazy(() => import('@/pages/live/LiveClassesPage'));
const LiveClassEditor = lazy(() => import('@/pages/live/LiveClassEditorPage'));
const LiveClassDetail = lazy(() => import('@/pages/live/LiveClassDetailPage'));
const Calendar = lazy(() => import('@/pages/calendar/CalendarPage'));
const EventEditor = lazy(() => import('@/pages/calendar/EventEditorPage'));
const Notifications = lazy(() => import('@/pages/notifications/NotificationsPage'));
const NotificationDetail = lazy(() => import('@/pages/notifications/NotificationDetailPage'));
const NotificationPreferences = lazy(() => import('@/pages/notifications/NotificationPreferencesPage'));
const ReportsLayout = lazy(() => import('@/pages/reports/ReportsLayout'));
const ReportsOverview = lazy(() => import('@/pages/reports/ReportsOverviewPage'));
const CourseReports = lazy(() => import('@/pages/reports/CourseReportsPage'));
const CourseReport = lazy(() => import('@/pages/reports/CourseReportsPage').then((m) => ({ default: m.CourseReportPage })));
const LearnerReports = lazy(() => import('@/pages/reports/LearnerReportsPage'));
const InstructorReports = lazy(() => import('@/pages/reports/InstructorReportsPage'));
const EnrolmentReport = lazy(() => import('@/pages/reports/EnrolmentReportPage'));
const Reviews = lazy(() => import('@/pages/reviews/ReviewsPage'));
const SettingsLayout = lazy(() => import('@/pages/settings/SettingsLayout'));
const Explore = lazy(() => import('@/pages/learn/ExplorePage'));
const Purchases = lazy(() => import('@/pages/learn/PurchasesPage'));
const PurchaseReceipt = lazy(() => import('@/pages/learn/PurchaseReceiptPage'));
const PublicCourse = lazy(() => import('@/pages/marketing/PublicCoursePage'));
const SignedOut = lazy(() => import('@/pages/SignedOutPage'));
const ResetPassword = lazy(() => import('@/pages/marketing/ResetPasswordPage'));
const GeneralSettings = lazy(() => import('@/pages/settings/SettingsSections').then((m) => ({ default: m.GeneralSettingsPage })));
const CourseSettings = lazy(() => import('@/pages/settings/SettingsSections').then((m) => ({ default: m.CourseSettingsPage })));
const LearningSettings = lazy(() => import('@/pages/settings/SettingsSections').then((m) => ({ default: m.LearningSettingsPage })));
const AcademyNotificationSettings = lazy(() => import('@/pages/settings/SettingsSections').then((m) => ({ default: m.AcademyNotificationSettingsPage })));
const CertificateSettings = lazy(() => import('@/pages/settings/BrandingSettings').then((m) => ({ default: m.CertificateSettingsPage })));
const LearnerLive = lazy(() => import('@/pages/live/LearnerLive').then((m) => ({ default: m.LearnerLivePage })));
const LearnerLiveClass = lazy(() => import('@/pages/live/LearnerLive').then((m) => ({ default: m.LearnerLiveClassPage })));
const Instructors = lazy(() => import('@/pages/instructors/InstructorsPage'));
const InstructorEditor = lazy(() => import('@/pages/instructors/InstructorEditorPage'));
const InstructorLayout = lazy(() => import('@/pages/instructors/InstructorProfile'));
const InstructorOverview = lazy(() => import('@/pages/instructors/InstructorProfile').then((m) => ({ default: m.InstructorOverview })));
const InstructorCourses = lazy(() => import('@/pages/instructors/InstructorProfile').then((m) => ({ default: m.InstructorCourses })));
const InstructorPerformance = lazy(() => import('@/pages/instructors/InstructorProfile').then((m) => ({ default: m.InstructorPerformance })));
const Assignments = lazy(() => import('@/pages/assignments/AssignmentsPage'));
const AssignmentEditor = lazy(() => import('@/pages/assignments/AssignmentEditorPage'));
const SubmissionReview = lazy(() => import('@/pages/assignments/SubmissionReviewPage'));
const Students = lazy(() => import('@/pages/students/StudentsPage'));
const StudentLayout = lazy(() => import('@/pages/students/StudentLayout'));
const StudentOverview = lazy(() => import('@/pages/students/StudentTabs').then((m) => ({ default: m.StudentOverview })));
const StudentCourses = lazy(() => import('@/pages/students/StudentTabs').then((m) => ({ default: m.StudentCourses })));
const StudentProgress = lazy(() => import('@/pages/students/StudentTabs').then((m) => ({ default: m.StudentProgressTab })));
const StudentActivity = lazy(() => import('@/pages/students/StudentTabs').then((m) => ({ default: m.StudentActivityTab })));
const HelpCenter = lazy(() => import('@/pages/help/HelpCenterPage'));
const HelpCategory = lazy(() => import('@/pages/help/HelpCategoryPage'));
const HelpArticle = lazy(() => import('@/pages/help/HelpArticlePage'));
const PlatformOverview = lazy(() => import('@/pages/superadmin/PlatformOverviewPage'));
const PlatformAdmins = lazy(() => import('@/pages/superadmin/PlatformAdminsPage'));
const PlatformUsers = lazy(() => import('@/pages/superadmin/PlatformUsersPage'));
const PlatformAudit = lazy(() => import('@/pages/superadmin/PlatformAuditPage'));
const PlatformSystem = lazy(() => import('@/pages/superadmin/PlatformSystemPage'));
const PaymentGateways = lazy(() => import('@/pages/superadmin/PaymentGatewaysPage'));
const SalesOrders = lazy(() => import('@/pages/superadmin/sales/SalesOrdersPage'));
const SalesCoupons = lazy(() => import('@/pages/superadmin/sales/CouponsPage'));
const SalesEvents = lazy(() => import('@/pages/superadmin/sales/PaymentEventsPage'));
const Inquiries = lazy(() => import('@/pages/superadmin/inquiries/InquiriesPage'));
const PlatformNotifications = lazy(() => import('@/pages/superadmin/notifications/PlatformNotificationsPage'));
const PlatformBranding = lazy(() => import('@/pages/superadmin/BrandingSettingsPage'));
const AffiliatePlan = lazy(() => import('@/pages/superadmin/affiliates/AffiliatePlanPage'));
const AffiliatePlanEditor = lazy(() => import('@/pages/superadmin/affiliates/AffiliatePlanEditorPage'));
const AffiliateMembers = lazy(() => import('@/pages/superadmin/affiliates/MembersPage'));
const AffiliateMember = lazy(() => import('@/pages/superadmin/affiliates/MemberPage'));
const AffiliatePlacements = lazy(() => import('@/pages/superadmin/affiliates/PlacementsPage'));
const AffiliateSponsors = lazy(() => import('@/pages/superadmin/affiliates/SponsorsPage'));
const AffiliateOrders = lazy(() => import('@/pages/superadmin/affiliates/OrdersPage'));
const AffiliateLedgers = lazy(() => import('@/pages/superadmin/affiliates/LedgersPage'));
const AffiliateProducts = lazy(() => import('@/pages/superadmin/affiliates/ProductsPage'));
const AffiliateNetwork = lazy(() => import('@/pages/superadmin/affiliates/NetworkPage'));
const AffiliateRanks = lazy(() => import('@/pages/superadmin/affiliates/RanksPage'));
const SandboxCheckout = lazy(() => import('@/pages/billing/SandboxCheckoutPage'));
const Landing = lazy(() => import('@/pages/marketing/LandingPage'));
const Contact = lazy(() => import('@/pages/marketing/ContactPage'));
const ExploreCourses = lazy(() => import('@/pages/marketing/ExploreCoursesPage'));
const PublicCategories = lazy(() => import('@/pages/marketing/CategoriesPage'));
const BecomeInstructor = lazy(() => import('@/pages/marketing/BecomeInstructorPage'));
const AffiliateProgram = lazy(() => import('@/pages/marketing/AffiliateProgramPage'));
const Website = lazy(() => import('@/pages/superadmin/site/WebsitePage'));
const About = lazy(() => import('@/pages/marketing/SitePages').then((m) => ({ default: m.AboutPage })));
const Faq = lazy(() => import('@/pages/marketing/SitePages').then((m) => ({ default: m.FaqPage })));
const Bundles = lazy(() => import('@/pages/marketing/BundlePages').then((m) => ({ default: m.BundlesPage })));
const BundleDetail = lazy(() => import('@/pages/marketing/BundlePages').then((m) => ({ default: m.BundleDetailPage })));
const Mentors = lazy(() => import('@/pages/marketing/MentorPages').then((m) => ({ default: m.MentorsPage })));
const MentorProfile = lazy(() => import('@/pages/marketing/MentorPages').then((m) => ({ default: m.MentorProfilePage })));
const Blog = lazy(() => import('@/pages/marketing/BlogPages').then((m) => ({ default: m.BlogPage })));
const BlogPost = lazy(() => import('@/pages/marketing/BlogPages').then((m) => ({ default: m.BlogPostPage })));
const SiteBundles = lazy(() => import('@/pages/superadmin/site/BundlesPage'));
const SitePosts = lazy(() => import('@/pages/superadmin/site/PostsPage'));
const SiteVisitors = lazy(() => import('@/pages/superadmin/site/VisitorsPage'));
const Login = lazy(() => import('@/pages/marketing/LoginPage'));
const Register = lazy(() => import('@/pages/marketing/RegisterPage'));
const Ref = lazy(() => import('@/pages/marketing/RefPage'));
const AffiliateOverview = lazy(() => import('@/pages/superadmin/affiliates/AffiliateOverviewPage'));
const AffiliateMatching = lazy(() => import('@/pages/superadmin/affiliates/MatchingPage'));
const AffiliateRewards = lazy(() => import('@/pages/superadmin/affiliates/RewardsPage'));
const AffiliateWallets = lazy(() => import('@/pages/superadmin/affiliates/WalletsPage'));
const AffiliateWithdrawals = lazy(() => import('@/pages/superadmin/affiliates/WithdrawalsPage'));
const AffiliateKycReview = lazy(() => import('@/pages/superadmin/affiliates/KycPage'));
const AffiliateEarnings = lazy(() => import('@/pages/affiliate/AffiliateEarningsPage'));
const AffiliateWallet = lazy(() => import('@/pages/affiliate/AffiliateWalletPage'));
const AffiliateKyc = lazy(() => import('@/pages/affiliate/AffiliateKycPage'));
const AffiliateHome = lazy(() => import('@/pages/affiliate/AffiliateHomePage'));
const AffiliateTree = lazy(() => import('@/pages/affiliate/AffiliateTreePage'));
const AffiliateTeam = lazy(() => import('@/pages/affiliate/AffiliateTeamPage'));
const AffiliateVolume = lazy(() => import('@/pages/affiliate/AffiliateVolumePage'));
const AffiliateOrdersPage = lazy(() => import('@/pages/affiliate/AffiliateOrdersPage'));
const Invite = lazy(() => import('@/pages/marketing/InvitePage'));
const TeachRequest = lazy(() => import('@/pages/marketing/TeachRequestPage'));
const RefundPolicy = lazy(() => import('@/pages/marketing/RefundPolicyPage'));
const CourseEnroll = lazy(() => import('@/pages/marketing/CourseEnrollPage'));
const Privacy = lazy(() => import('@/pages/marketing/PrivacyPage'));
const Terms = lazy(() => import('@/pages/marketing/TermsPage'));
const DeleteAccount = lazy(() => import('@/pages/marketing/DeleteAccountPage'));

const lazyPage = (node: ReactNode) => <Suspense fallback={<PageLoading />}>{node}</Suspense>;

/** Addresses of the SaaS era forward to the one registration door (docs/16, D-PLAT-06), keeping a referral they carry. */
function ForwardTo({ to }: { to: string }) {
  const { search } = useLocation();
  return <Navigate to={`${to}${search}`} replace />;
}

/** Screens shared by the admin and the teaching workspace. */
const workspaceRoutes = (base: 'admin' | 'teach'): RouteObject[] => [
  { path: base, element: lazyPage(<Dashboard />) },
  { path: `${base}/courses`, element: lazyPage(<CourseList />) },
  // An instructor's own sales; the page's links are to the teaching workspace.
  ...(base === 'teach'
    ? [
        { path: 'teach/course-sales', element: lazyPage(<CourseSales />) },
        // An instructor's performance: the report pages that read one person's courses. The API scopes them to the token.
        {
          path: 'teach/reports',
          element: lazyPage(<ReportsLayout />),
          children: [
            { index: true, element: lazyPage(<ReportsOverview />) },
            { path: 'courses', element: lazyPage(<CourseReports />) },
            { path: 'courses/:courseId', element: lazyPage(<CourseReport />) },
          ],
        },
      ]
    : []),
  // Instructors read their own courses' reviews; admins read every course's, and hide and show.
  { path: `${base}/reviews`, element: lazyPage(<Reviews />) },
  { path: `${base}/courses/new`, element: lazyPage(<CourseEditor />) },
  { path: `${base}/courses/:courseId/edit`, element: lazyPage(<CourseEditor />) },
  { path: `${base}/courses/:courseId/preview`, element: lazyPage(<CoursePreview />) },
  {
    path: `${base}/courses/:courseId`,
    element: lazyPage(<CourseLayout />),
    children: [
      { index: true, element: lazyPage(<CourseOverview />) },
      {
        path: 'curriculum',
        element: lazyPage(<Curriculum />),
        // The chapter form opens as a panel over the curriculum.
        children: [
          { path: 'chapters/new', element: null },
          { path: 'chapters/:chapterId/edit', element: null },
        ],
      },
      { path: 'chapters/:chapterId', element: lazyPage(<ChapterOverview />) },
      { path: 'lessons', element: lazyPage(<LessonList />) },
    ],
  },
  { path: `${base}/quizzes`, element: lazyPage(<QuizList />) },
  { path: `${base}/quizzes/new`, element: lazyPage(<QuizBuilder />) },
  {
    path: `${base}/quizzes/:quizId`,
    element: lazyPage(<QuizBuilder />),
    children: [
      { path: 'settings', element: null },
      { path: 'preview', element: null },
      { path: 'results', element: null },
    ],
  },
  // The review queue is a tab of the assignments page.
  { path: `${base}/assignments`, element: lazyPage(<Assignments />), children: [{ path: 'review', element: null }] },
  { path: `${base}/assignments/new`, element: lazyPage(<AssignmentEditor />) },
  {
    path: `${base}/assignments/:assignmentId`,
    element: lazyPage(<AssignmentEditor />),
    children: [
      { path: 'preview', element: null },
      { path: 'submissions', element: null },
    ],
  },
  { path: `${base}/assignments/:assignmentId/submissions/:submissionId`, element: lazyPage(<SubmissionReview />) },
  { path: `${base}/live`, element: lazyPage(<LiveClasses />) },
  { path: `${base}/live/new`, element: lazyPage(<LiveClassEditor />) },
  { path: `${base}/live/:liveId`, element: lazyPage(<LiveClassDetail />) },
  { path: `${base}/live/:liveId/edit`, element: lazyPage(<LiveClassEditor />) },
  // The event panel opens over the calendar; the child path gives it an addressable URL.
  { path: `${base}/calendar`, element: lazyPage(<Calendar />), children: [{ path: ':eventId', element: null }] },
  { path: `${base}/calendar/new`, element: lazyPage(<EventEditor />) },
  { path: `${base}/calendar/:eventId/edit`, element: lazyPage(<EventEditor />) },
  { path: `${base}/notifications`, element: lazyPage(<Notifications />) },
  { path: `${base}/notifications/preferences`, element: lazyPage(<NotificationPreferences />) },
  { path: `${base}/notifications/:notificationId`, element: lazyPage(<NotificationDetail />) },
  { path: `${base}/help`, element: lazyPage(<HelpCenter />) },
  { path: `${base}/help/article/:slug`, element: lazyPage(<HelpArticle />) },
  { path: `${base}/help/:categoryId`, element: lazyPage(<HelpCategory />) },
  { path: `${base}/students`, element: lazyPage(<Students />) },
  {
    path: `${base}/students/:studentId`,
    element: lazyPage(<StudentLayout />),
    children: [
      { index: true, element: lazyPage(<StudentOverview />) },
      { path: 'courses', element: lazyPage(<StudentCourses />) },
      { path: 'progress', element: lazyPage(<StudentProgress />) },
      { path: 'activity', element: lazyPage(<StudentActivity />) },
    ],
  },
  { path: `${base}/courses/:courseId/lessons/new`, element: lazyPage(<LessonEditor />) },
  {
    path: `${base}/courses/:courseId/lessons/:lessonId`,
    element: lazyPage(<LessonEditor />),
    // Settings and preview are tabs of one editor, so unsaved work survives switching between them.
    children: [
      { path: 'settings', element: null },
      { path: 'preview', element: null },
    ],
  },
];

/** Each role lands in its own workspace. */
function RoleHome() {
  const { role } = useSession();
  return <Navigate to={homeFor(role)} replace />;
}

/**
 * http mode only: the shell needs a signed-in account. Visitors without one go to /login (and come
 * back to where they were); accounts in the wrong workspace go to their own home.
 */
function RequireSession({ children }: { children: ReactNode }) {
  const { isAuthenticated, authLoading, role } = useSession();
  const location = useLocation();
  if (API_MODE !== 'http') return <>{children}</>;
  if (authLoading) return <PageLoading />;
  if (!isAuthenticated) {
    // The sign-in is still good but the server didn't answer (a deploy restarting it, a dropped connection): not a reason to ask for the password.
    if (getToken())
      return (
        <StateMessage
          kind="error"
          title="We can’t reach the server"
          actions={
            <Button variant="primary" onClick={() => window.location.reload()}>
              Try again
            </Button>
          }
        >
          You’re still signed in. Check your connection and try again.
        </StateMessage>
      );
    // A visitor at the root is on the website, not at a locked door.
    if (location.pathname === '/') return lazyPage(<Landing />);
    const next = encodeURIComponent(`${location.pathname}${location.search}`);
    return <Navigate to={`/login?next=${next}`} replace />;
  }
  const elsewhere = workspaceRedirect(role, location.pathname);
  if (elsewhere) return <Navigate to={elsewhere} replace />;
  return <>{children}</>;
}

/**
 * Routes. Management screens are shared by the admin (`/admin`) and the teaching workspace (`/teach`);
 * `useWorkspace` scopes their data. `/superadmin` holds what only the platform's owner does (docs/16 §2.2),
 * and an address that matches nothing resolves to the shell's not-found page.
 */
export const router = createBrowserRouter(
  [
    {
      element: (
        <RequireSession>
          <AppShell />
        </RequireSession>
      ),
      children: [
        { index: true, element: <RoleHome /> },
        ...workspaceRoutes('admin'),
        {
          // Panels open over the list; child paths only give them addressable URLs.
          path: 'admin/categories',
          element: lazyPage(<Categories />),
          children: [
            { path: 'new', element: null },
            { path: ':categoryId', element: null },
            { path: ':categoryId/edit', element: null },
          ],
        },
        {
          path: 'admin/settings',
          element: lazyPage(<SettingsLayout />),
          children: [
            { index: true, element: <Navigate to="general" replace /> },
            { path: 'general', element: lazyPage(<GeneralSettings />) },
            { path: 'courses', element: lazyPage(<CourseSettings />) },
            { path: 'learning', element: lazyPage(<LearningSettings />) },
            { path: 'certificates', element: lazyPage(<CertificateSettings />) },
            { path: 'notifications', element: lazyPage(<AcademyNotificationSettings />) },
          ],
        },
        {
          path: 'admin/reports',
          element: lazyPage(<ReportsLayout />),
          children: [
            { index: true, element: lazyPage(<ReportsOverview />) },
            { path: 'courses', element: lazyPage(<CourseReports />) },
            { path: 'courses/:courseId', element: lazyPage(<CourseReport />) },
            { path: 'learners', element: lazyPage(<LearnerReports />) },
            { path: 'instructors', element: lazyPage(<InstructorReports />) },
            { path: 'enrolments', element: lazyPage(<EnrolmentReport />) },
          ],
        },
        { path: 'admin/certificates', element: lazyPage(<Certificates />) },
        { path: 'admin/certificates/templates', element: lazyPage(<CertificateTemplates />) },
        { path: 'admin/certificates/templates/:templateId', element: lazyPage(<TemplateEditor />) },
        { path: 'admin/certificates/:certificateId', element: lazyPage(<CertificateDetail />) },
        // Instructors are managed by admins only.
        { path: 'admin/instructors', element: lazyPage(<Instructors />) },
        { path: 'admin/instructors/new', element: lazyPage(<InstructorEditor />) },
        { path: 'admin/instructors/:instructorId/edit', element: lazyPage(<InstructorEditor />) },
        {
          path: 'admin/instructors/:instructorId',
          element: lazyPage(<InstructorLayout />),
          children: [
            { index: true, element: lazyPage(<InstructorOverview />) },
            { path: 'courses', element: lazyPage(<InstructorCourses />) },
            { path: 'performance', element: lazyPage(<InstructorPerformance />) },
          ],
        },
        // The platform workspace. `RequireSession` admits only the superadmin role here.
        { path: 'superadmin', element: lazyPage(<PlatformOverview />) },
        { path: 'superadmin/admins', element: lazyPage(<PlatformAdmins />) },
        { path: 'superadmin/users', element: lazyPage(<PlatformUsers />) },
        { path: 'superadmin/audit', element: lazyPage(<PlatformAudit />) },
        // The platform team's inbox: contact and support requests.
        { path: 'superadmin/inquiries', element: lazyPage(<Inquiries />) },
        // One message to one audience, and the history of them.
        { path: 'superadmin/notifications', element: lazyPage(<PlatformNotifications />) },
        { path: 'superadmin/system', element: lazyPage(<PlatformSystem />) },
        // The platform's own logo and favicon.
        { path: 'superadmin/branding', element: lazyPage(<PlatformBranding />) },
        // The affiliate program (MLM-000 plan, MLM-002 network, MLM-003 orders and ledgers; later modules add wallets and payouts).
        { path: 'superadmin/website', element: lazyPage(<Website />) },
        { path: 'superadmin/website/posts', element: lazyPage(<SitePosts />) },
        { path: 'superadmin/website/visitors', element: lazyPage(<SiteVisitors />) },
        { path: 'superadmin/sales/bundles', element: lazyPage(<SiteBundles />) },
        { path: 'superadmin/affiliates', element: <Navigate to="/superadmin/affiliates/overview" replace /> },
        { path: 'superadmin/affiliates/overview', element: lazyPage(<AffiliateOverview />) },
        { path: 'superadmin/affiliates/matching', element: lazyPage(<AffiliateMatching />) },
        { path: 'superadmin/affiliates/rewards', element: lazyPage(<AffiliateRewards />) },
        { path: 'superadmin/affiliates/wallets', element: lazyPage(<AffiliateWallets />) },
        { path: 'superadmin/affiliates/withdrawals', element: lazyPage(<AffiliateWithdrawals />) },
        { path: 'superadmin/affiliates/kyc', element: lazyPage(<AffiliateKycReview />) },
        { path: 'superadmin/affiliates/members', element: lazyPage(<AffiliateMembers />) },
        { path: 'superadmin/affiliates/members/:memberId', element: lazyPage(<AffiliateMember />) },
        { path: 'superadmin/affiliates/placements', element: lazyPage(<AffiliatePlacements />) },
        { path: 'superadmin/affiliates/sponsors', element: lazyPage(<AffiliateSponsors />) },
        { path: 'superadmin/affiliates/orders', element: lazyPage(<AffiliateOrders />) },
        { path: 'superadmin/affiliates/ledgers', element: lazyPage(<AffiliateLedgers />) },
        { path: 'superadmin/affiliates/products', element: lazyPage(<AffiliateProducts />) },
        { path: 'superadmin/affiliates/network', element: lazyPage(<AffiliateNetwork />) },
        { path: 'superadmin/affiliates/ranks', element: lazyPage(<AffiliateRanks />) },
        { path: 'superadmin/affiliates/plan', element: lazyPage(<AffiliatePlan />) },
        { path: 'superadmin/affiliates/plan/versions/:versionId/edit', element: lazyPage(<AffiliatePlanEditor />) },
        // Where course money settles (docs/16, D-PLAT-07): gateway credentials, which one is active, online payment on or off.
        { path: 'superadmin/payment-gateways', element: lazyPage(<PaymentGateways />) },
        { path: 'superadmin/sales', element: <Navigate to="/superadmin/sales/orders" replace /> },
        { path: 'superadmin/sales/orders', element: lazyPage(<SalesOrders />) },
        { path: 'superadmin/sales/coupons', element: lazyPage(<SalesCoupons />) },
        { path: 'superadmin/sales/events', element: lazyPage(<SalesEvents />) },
        ...workspaceRoutes('teach'),
        // The learner's side
        { path: 'home', element: lazyPage(<LearnHome />) },
        { path: 'explore', element: lazyPage(<Explore />) },
        { path: 'my-learning', element: <Navigate to="/my-learning/in-progress" replace /> },
        { path: 'my-learning/:tab', element: lazyPage(<MyLearning />) },
        { path: 'learn/:courseId', element: lazyPage(<CourseLearning />) },
        { path: 'learn/:courseId/lessons/:lessonId', element: lazyPage(<LessonPlayer />) },
        { path: 'assignments', element: lazyPage(<LearnerAssignments />) },
        { path: 'assignments/:assignmentId', element: lazyPage(<LearnerAssignment />) },
        { path: 'assessments', element: lazyPage(<LearnerAssessments />) },
        { path: 'live', element: lazyPage(<LearnerLive />) },
        { path: 'live/:liveId', element: lazyPage(<LearnerLiveClass />) },
        { path: 'certificates', element: lazyPage(<MyCertificates />) },
        // The learner's course purchases: order details, newest first.
        { path: 'purchases', element: lazyPage(<Purchases />) },
        { path: 'purchases/:purchaseId', element: lazyPage(<PurchaseReceipt />) },
        // The affiliate program's own surface (MLM-001 …).
        { path: 'affiliate', element: lazyPage(<AffiliateHome />) },
        { path: 'affiliate/tree', element: lazyPage(<AffiliateTree />) },
        { path: 'affiliate/team', element: lazyPage(<AffiliateTeam />) },
        { path: 'affiliate/volume', element: lazyPage(<AffiliateVolume />) },
        { path: 'affiliate/orders', element: lazyPage(<AffiliateOrdersPage />) },
        { path: 'affiliate/earnings', element: lazyPage(<AffiliateEarnings />) },
        { path: 'affiliate/wallet', element: lazyPage(<AffiliateWallet />) },
        { path: 'affiliate/kyc', element: lazyPage(<AffiliateKyc />) },
        { path: 'certificates/:certificateId', element: lazyPage(<MyCertificate />) },
        { path: 'notifications', element: lazyPage(<Notifications />) },
        { path: 'notifications/preferences', element: lazyPage(<NotificationPreferences />) },
        { path: 'notifications/:notificationId', element: lazyPage(<NotificationDetail />) },
        { path: 'help', element: lazyPage(<HelpCenter />) },
        { path: 'help/article/:slug', element: lazyPage(<HelpArticle />) },
        { path: 'help/:categoryId', element: lazyPage(<HelpCategory />) },
        // The design-system reference shows sample data and pretend toasts: a developer's page, never in a production build.
        ...(import.meta.env.DEV
          ? [
              {
                path: 'design-system',
                element: lazyPage(<DesignSystemLayout />),
                children: [
                  { index: true, element: lazyPage(<Foundations />) },
                  { path: 'components', element: lazyPage(<Components />) },
                  { path: 'learning', element: lazyPage(<LearningPatterns />) },
                  { path: 'states', element: lazyPage(<States />) },
                  { path: 'responsive', element: lazyPage(<Responsive />) },
                ],
              },
              { path: 'design-system/specimen/:specimen', element: lazyPage(<Specimen />) },
            ]
          : []),
        { path: '*', element: <NotFoundPage /> },
      ],
    },
    { path: 'signed-out', element: lazyPage(<SignedOut />) },
    { path: 'welcome', element: lazyPage(<Landing />) },
    // The website.
    { path: 'categories', element: lazyPage(<PublicCategories />) },
    { path: 'bundles', element: lazyPage(<Bundles />) },
    { path: 'bundles/:slug', element: lazyPage(<BundleDetail />) },
    { path: 'mentors', element: lazyPage(<Mentors />) },
    { path: 'mentors/:id', element: lazyPage(<MentorProfile />) },
    { path: 'blog', element: lazyPage(<Blog />) },
    { path: 'blog/:slug', element: lazyPage(<BlogPost />) },
    { path: 'become-an-instructor', element: lazyPage(<BecomeInstructor />) },
    { path: 'affiliate-program', element: lazyPage(<AffiliateProgram />) },
    // The SaaS era's product pages: the addresses forward, the pages are gone.
    { path: 'features', element: <Navigate to="/welcome" replace /> },
    { path: 'solutions', element: <Navigate to="/welcome" replace /> },
    { path: 'how-it-works', element: <Navigate to="/welcome#how-it-works" replace /> },
    { path: 'about', element: lazyPage(<About />) },
    { path: 'faq', element: lazyPage(<Faq />) },
    { path: 'contact', element: lazyPage(<Contact />) },
    { path: 'login', element: lazyPage(<Login />) },
    // The SaaS era's plans and academy sign-up (docs/16 §2.3): the addresses forward, the pages are gone.
    { path: 'pricing', element: <Navigate to="/welcome" replace /> },
    { path: 'get-started', element: <ForwardTo to="/register" /> },
    { path: 'register', element: lazyPage(<Register />) },
    { path: 'teach/apply', element: lazyPage(<TeachRequest />) },
    // A referral link (MLM-001): resolves the sponsor and sends the visitor on to register.
    { path: 'ref/:code', element: lazyPage(<Ref />) },
    { path: 'join', element: <ForwardTo to="/register" /> },
    { path: 'join/:slug', element: <ForwardTo to="/register" /> },
    { path: 'join/:slug/teach', element: <ForwardTo to="/teach/apply" /> },
    // An invitation for one learner: the token names the role, on the server.
    { path: 'invite/:token', element: lazyPage(<Invite />) },
    // A course's enrolment link: new learners register and enrol, signed-in learners enrol.
    { path: 'courses/:courseId/enroll', element: lazyPage(<CourseEnroll />) },
    { path: 'reset-password/:token', element: lazyPage(<ResetPassword />) },
    // The sandbox gateway's hosted test checkout; the API answers it only outside production.
    { path: 'sandbox-checkout/:orderId', element: lazyPage(<SandboxCheckout />) },
    { path: 'privacy', element: lazyPage(<Privacy />) },
    { path: 'terms', element: lazyPage(<Terms />) },
    { path: 'refunds', element: lazyPage(<RefundPolicy />) },
    { path: 'delete-account', element: lazyPage(<DeleteAccount />) },
    // Public, no sign-in required — reached from the website as well as shared outside it.
    { path: 'courses', element: lazyPage(<ExploreCourses />) },
    {
      // The page behind "Copy course link" (and the mobile app's deep link): one course, reached by its link.
      path: 'courses/:slug',
      element: lazyPage(<PublicCourse />),
    },
    {
      path: 'verify',
      element: lazyPage(
        <MarketingChrome>
          <Verify />
        </MarketingChrome>,
      ),
    },
    {
      path: 'verify/:credentialId',
      element: lazyPage(
        <MarketingChrome>
          <Verify />
        </MarketingChrome>,
      ),
    },
    {
      path: 'support',
      element: lazyPage(
        <MarketingChrome>
          <HelpCenter />
        </MarketingChrome>,
      ),
    },
    {
      path: 'support/article/:slug',
      element: lazyPage(
        <MarketingChrome>
          <HelpArticle />
        </MarketingChrome>,
      ),
    },
    {
      path: 'support/:categoryId',
      element: lazyPage(
        <MarketingChrome>
          <HelpCategory />
        </MarketingChrome>,
      ),
    },
  ],
  { future: { v7_relativeSplatPath: true } },
);

// Each public page's title, description and canonical URL (src/app/pageMeta.ts), on arrival and on every navigation.
// Only a new address writes them, so a page's own tags (a course's, set from its data) survive other router updates.
if (typeof document !== 'undefined') {
  let metaPath = router.state.location.pathname;
  applyPageMeta(metaPath);
  countVisit(metaPath);
  router.subscribe(({ location }) => {
    if (location.pathname === metaPath) return;
    metaPath = location.pathname;
    applyPageMeta(metaPath);
    countVisit(metaPath);
  });
}
