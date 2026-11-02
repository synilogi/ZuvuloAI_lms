import type { CertificateTemplate, IssuedCertificate, IssuedCertificateStatus } from '@syniastrolms/domain';

import type { CertificateAdminService, CertificateDetail, CertificateRow, TemplateSummary } from '../contracts';
import { get, post } from './client';

export const httpCertificates: CertificateAdminService = {
  list: (query) => get<{ rows: CertificateRow[]; total: number; counts: Record<IssuedCertificateStatus | 'all', number> }>('/certificates', query),
  get: (id) => get<CertificateDetail>(`/certificates/${id}`),
  issue: (id) => post<IssuedCertificate>(`/certificates/${id}/issue`),
  revoke: (id, reason) => post<IssuedCertificate>(`/certificates/${id}/revoke`, { reason }),
  restore: (id) => post<IssuedCertificate>(`/certificates/${id}/restore`),
  listTemplates: () => get<TemplateSummary[]>('/certificates/templates'),
  getTemplate: (id) => get<TemplateSummary & { allCourses: { id: string; title: string; templateId: string }[] }>(`/certificates/templates/${id}`),
  saveTemplate: (id, input) => post<CertificateTemplate>('/certificates/templates', { id, input }),
  setDefaultTemplate: (id) => post<CertificateTemplate>(`/certificates/templates/${id}/default`),
  verify: (credentialId) => get<CertificateDetail>(`/certificates/verify/${credentialId}`),
};
