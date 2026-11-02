import type { PlatformService } from '../contracts';
import { ServiceError } from '../contracts';
import { respond } from './simulation';

/**
 * The demo build has no platform behind it: it ships three personas and no Super Admin, so these screens are
 * unreachable in mock mode. Rather than invent a fictional platform — and especially rather than invent audit
 * records — the directory, audit and admin answers here are honest empty ones.
 */
const noPlatform = () => new ServiceError('The demo build has no platform to manage. Sign in to a real installation.', 'conflict');

const EMPTY_PAGE = { rows: [], total: 0, page: 1, pageSize: 20 };

export const platformService: PlatformService = {
  overview: () =>
    respond({
      users: { total: 0, students: 0, instructors: 0, admins: 0, superadmins: 0 },
      people: { studentProfiles: 0, suspendedStudents: 0, instructorProfiles: 0, inactiveInstructors: 0 },
      courses: { total: 0, published: 0, draft: 0, archived: 0 },
      learning: { enrollments: 0, certificatesIssued: 0 },
      audit: { events: 0 },
      sales: { orders: 0, paid: 0, revenue: 0 },
      inbox: { new: 0, inProgress: 0 },
      generatedAt: new Date().toISOString(),
    }),
  listAdmins: () => respond({ ...EMPTY_PAGE }),
  listUsers: () => respond({ ...EMPTY_PAGE }),
  listAudit: () => respond({ ...EMPTY_PAGE }),
  system: () =>
    respond({
      database: { ok: true, latencyMs: 0 },
      email: { queued: 0, sent: 0, failed: 0 },
      media: { files: 0, totalBytes: 0 },
      process: { environment: 'demo', uptimeSeconds: 0 },
      generatedAt: new Date().toISOString(),
    }),

  // There is no platform to write to in the demo build, and inventing an admin here would put a
  // fictional account in a list the real build reads from the database.
  createAdmin: () => Promise.reject(noPlatform()),
  updateAdmin: () => Promise.reject(noPlatform()),
  deactivateAdmin: () => Promise.reject(noPlatform()),
  reactivateAdmin: () => Promise.reject(noPlatform()),
  adminPermissions: () => Promise.reject(noPlatform()),
  grantPermission: () => Promise.reject(noPlatform()),
  revokePermission: () => Promise.reject(noPlatform()),

  // Nobody to reach and no audit log in the demo build, so the audience is empty and so is the history.
  broadcastAudienceCount: (audience) => respond({ audience, count: 0 }),
  sendBroadcast: () => Promise.reject(noPlatform()),
  listBroadcasts: () => respond({ ...EMPTY_PAGE }),

  // The demo build has no platform inbox: nobody can write to it, so it is honestly empty.
  listInquiries: ({ page = 1, pageSize = 20 } = {}) =>
    respond(() => ({ rows: [], total: 0, page, pageSize, counts: { new: 0, in_progress: 0, closed: 0 } }), 300),
  updateInquiry: () => Promise.reject(noPlatform()),
};
