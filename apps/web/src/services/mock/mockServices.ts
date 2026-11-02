import type { Services } from '../contracts';
import { ServiceError } from '../contracts';
import { buildDashboard } from './analytics';
import { categoryAdminService } from './categories';
import { chapterAdminService } from './chapters';
import { lessonAdminService } from './lessons';
import { quizAdminService } from './quizzes';
import { assignmentAdminService } from './assignments';
import { studentAdminService } from './students';
import { instructorAdminService } from './instructors';
import { learningService } from './learning';
import { certificateAdminService } from './certificates';
import { liveClassService } from './live';
import { calendarService } from './calendar';
import { notificationService } from './notifications';
import { reportsService } from './reports';
import { publicMockReviews } from './reviews';
import { settingsService } from './settings';
import { helpService } from './help';
import { courseAdminService } from './courses';
import { platformService } from './platform';
import { paymentGatewayService } from './paymentGateways';
import { salesService } from './sales';
import { accountService } from './account';
import { signupService } from './signup';
import { invitationService } from './invitations';
import { siteService } from './site';
import { brandingService } from './branding';
import { affiliatesPlatformService } from './affiliatesPlatform';
import { affiliateEarningsService, platformEarningsService } from './affiliateEarnings';
import { affiliateService } from './affiliate';
import { sandboxService } from './sandbox';
import { respond, scenario } from './simulation';
import { learnerRows } from './fixtures/admin';
import { categories, courses, instructors, levels } from './fixtures/catalog';
import { assignments, DEMO_NOW, rankStanding, ranks } from './fixtures/learner';

import { mediaService } from './media';

export { simulation } from './simulation';

export const mockServices: Services = {
  signup: signupService,
  invitations: invitationService,
  site: siteService,
  branding: brandingService,
  affiliatesPlatform: affiliatesPlatformService,
  affiliateEarnings: affiliateEarningsService,
  platformEarnings: platformEarningsService,
  affiliate: affiliateService,
  sandbox: sandboxService,
  media: mediaService,
  catalog: {
    listLevels: () => respond(levels),
    listCategories: () => respond(categories),
    listCourses: (filter) =>
      respond(courses.filter((c) => (!filter?.levelId || c.levelId === filter.levelId) && (!filter?.categoryId || c.categoryId === filter.categoryId))),
    getCourse: (slug) => {
      const course = courses.find((c) => c.slug === slug);
      return course ? respond(course) : Promise.reject(new ServiceError('Course not found', 'not-found'));
    },
    listInstructors: () => respond(instructors),
    listCourseReviews: (slug, query) => respond(() => publicMockReviews(slug, query)),
  },
  dashboard: {
    getSnapshot: (scope) => respond(() => buildDashboard(scope, scenario() === 'empty'), 700),
  },
  courses: courseAdminService,
  categories: categoryAdminService,
  chapters: chapterAdminService,
  lessons: lessonAdminService,
  quizzes: quizAdminService,
  assignments: assignmentAdminService,
  students: studentAdminService,
  instructors: instructorAdminService,
  learning: learningService,
  certificates: certificateAdminService,
  live: liveClassService,
  calendar: calendarService,
  notifications: notificationService,
  reports: reportsService,
  settings: settingsService,
  help: helpService,
  learner: {
    listAssignments: () => respond(assignments),
    getRankLadder: () => respond({ ranks, standing: rankStanding }),
  },
  enrollment: {
    enroll: (courseId) => respond({ courseId, enrolledAt: DEMO_NOW }, 1100),
  },
  admin: {
    listLearners: ({ search = '', status = 'all', sort, page, pageSize }) => {
      const q = search.trim().toLowerCase();
      let rows = learnerRows.filter((r) => (status === 'all' || r.status === status) && (!q || `${r.name} ${r.email} ${r.course}`.toLowerCase().includes(q)));
      if (sort) {
        const dir = sort.direction === 'asc' ? 1 : -1;
        rows = [...rows].sort((a, b) => (a[sort.key] > b[sort.key] ? dir : a[sort.key] < b[sort.key] ? -dir : 0));
      }
      const start = (page - 1) * pageSize;
      return respond({ rows: rows.slice(start, start + pageSize), total: rows.length }, 380);
    },
  },
  platform: platformService,
  sales: salesService,
  paymentGateways: paymentGatewayService,
  account: accountService,
};
