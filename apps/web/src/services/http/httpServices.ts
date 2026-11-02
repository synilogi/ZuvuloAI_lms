import type { Services } from '../contracts';
import { httpCatalog } from './catalog';
import { httpDashboard } from './dashboard';
import { httpCourses } from './courses';
import { httpCategories } from './categories';
import { httpChapters } from './chapters';
import { httpLessons } from './lessons';
import { httpQuizzes } from './quizzes';
import { httpAssignments } from './assignments';
import { httpStudents } from './students';
import { httpInstructors } from './instructors';
import { httpLearning } from './learning';
import { httpCertificates } from './certificates';
import { httpLive } from './live';
import { httpCalendar } from './calendar';
import { httpNotifications } from './notifications';
import { httpReports } from './reports';
import { httpSettings } from './settings';
import { httpHelp } from './help';
import { httpLearner } from './learner';
import { httpEnrollment } from './enrollment';
import { httpAdmin } from './admin';
import { httpMedia } from './media';
import { httpPlatform } from './platform';
import { httpPaymentGateways } from './paymentGateways';
import { httpSales } from './sales';
import { httpAccount } from './auth';
import { httpSignup } from './signup';
import { httpInvitations } from './invitations';
import { httpSite } from './site';
import { httpBranding } from './branding';
import { httpAffiliatesPlatform } from './affiliatesPlatform';
import { httpAffiliateEarnings, httpPlatformEarnings } from './affiliateEarnings';
import { httpAffiliate } from './affiliate';
import { httpSandbox } from './sandbox';

/** The real, database-backed implementation of every service — used when VITE_API_MODE=http. */
export const httpServices: Services = {
  signup: httpSignup,
  invitations: httpInvitations,
  site: httpSite,
  branding: httpBranding,
  affiliatesPlatform: httpAffiliatesPlatform,
  affiliateEarnings: httpAffiliateEarnings,
  platformEarnings: httpPlatformEarnings,
  affiliate: httpAffiliate,
  sandbox: httpSandbox,
  media: httpMedia,
  catalog: httpCatalog,
  dashboard: httpDashboard,
  courses: httpCourses,
  categories: httpCategories,
  chapters: httpChapters,
  lessons: httpLessons,
  quizzes: httpQuizzes,
  assignments: httpAssignments,
  students: httpStudents,
  instructors: httpInstructors,
  learning: httpLearning,
  certificates: httpCertificates,
  live: httpLive,
  calendar: httpCalendar,
  notifications: httpNotifications,
  reports: httpReports,
  settings: httpSettings,
  help: httpHelp,
  learner: httpLearner,
  enrollment: httpEnrollment,
  admin: httpAdmin,
  platform: httpPlatform,
  sales: httpSales,
  paymentGateways: httpPaymentGateways,
  account: httpAccount,
};
