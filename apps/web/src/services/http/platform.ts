import type {
  AdminInput,
  AdminUpdate,
  PlatformPermissionState,
  PlatformAuditEntry,
  PlatformOverview,
  PlatformPage,
  PlatformAuditQuery,
  PlatformPaging,
  PlatformService,
  PlatformSystemStatus,
  PlatformUserQuery,
  PlatformUserRow,
  InquiryQuery,
} from '../contracts';
import type { BroadcastAudience, BroadcastHistoryRow, BroadcastResult, Inquiry, InquiryListResult, PermissionKey } from '@syniastrolms/domain';

import { del, get, patch, post } from './client';

/**
 * The Super Admin surface. It goes through the same client as every other service, so the bearer
 * token, the 401 handling and the ServiceError mapping are the shared ones — there is no second
 * client and no second session here. The writes are admin management and the inbox.
 */
export const httpPlatform: PlatformService = {
  overview: () => get<PlatformOverview>('/superadmin/overview'),
  listAdmins: (query = {}) => get<PlatformPage<PlatformUserRow>>('/superadmin/admins', query satisfies PlatformPaging),
  listUsers: (query = {}) => get<PlatformPage<PlatformUserRow>>('/superadmin/users', query satisfies PlatformUserQuery),
  listAudit: (query = {}) => get<PlatformPage<PlatformAuditEntry>>('/superadmin/audit', query satisfies PlatformAuditQuery),
  system: () => get<PlatformSystemStatus>('/superadmin/system'),

  createAdmin: (input: AdminInput) => post<PlatformUserRow>('/superadmin/admins', input),
  updateAdmin: (id: string, changes: AdminUpdate) => patch<PlatformUserRow>(`/superadmin/admins/${id}`, changes),
  deactivateAdmin: (id: string) => post<PlatformUserRow>(`/superadmin/admins/${id}/deactivate`),
  reactivateAdmin: (id: string) => post<PlatformUserRow>(`/superadmin/admins/${id}/reactivate`),

  adminPermissions: (id: string) => get<PlatformPermissionState>(`/superadmin/admins/${id}/permissions`),
  grantPermission: (id: string, key: PermissionKey) => post<PlatformPermissionState>(`/superadmin/admins/${id}/permissions`, { key }),
  revokePermission: (id: string, key: PermissionKey) => del<PlatformPermissionState>(`/superadmin/admins/${id}/permissions/${key}`),

  broadcastAudienceCount: (audience) => get<{ audience: BroadcastAudience; count: number }>('/superadmin/notifications/audience-count', { audience }),
  sendBroadcast: (input) => post<BroadcastResult>('/superadmin/notifications/broadcast', input),
  listBroadcasts: (query = {}) => get<PlatformPage<BroadcastHistoryRow>>('/superadmin/notifications/broadcasts', query satisfies PlatformPaging),

  listInquiries: (query = {}) => get<InquiryListResult>('/superadmin/inquiries', query satisfies InquiryQuery),
  updateInquiry: (id, changes) => patch<Inquiry>(`/superadmin/inquiries/${id}`, changes),
};
