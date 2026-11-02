import type { CertificateTemplate, IssuedCertificate, IssuedCertificateStatus } from '@syniastrolms/domain';
import { validateTemplate } from '@syniastrolms/domain';
import type { CertificateAdminService, CertificateDetail, CertificateRow } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNowIso } from './clock';
import { certificateTemplates, courseTemplate, issuedCertificates, templateFor } from './fixtures/certificates';
import { courses, levels } from './fixtures/catalog';
import { students } from './fixtures/people';
import { respond, scenario } from './simulation';

const studentById = new Map(students.map((s) => [s.id, s]));

export function certificateDetail(cert: IssuedCertificate): CertificateDetail {
  const course = courses.find((c) => c.id === cert.courseId);
  const s = studentById.get(cert.studentId);
  const template = certificateTemplates.find((t) => t.id === cert.templateId) ?? certificateTemplates[0];
  return {
    certificate: cert,
    student: { id: cert.studentId, name: s?.name ?? 'Former learner', email: s?.email ?? '', city: s?.city ?? '' },
    courseTitle: course?.title ?? cert.title,
    levelTitle: levels.find((l) => l.id === course?.levelId)?.name ?? '',
    template,
    verifyUrl: `https://zuviloai.com/verify/${cert.credentialId}`,
  };
}

function find(id: string) {
  const cert = issuedCertificates().find((c) => c.id === id);
  if (!cert) throw new ServiceError('This certificate doesn’t exist.', 'not-found');
  return cert;
}

/** Issuing prints on the course's current template. */
export function issue(cert: IssuedCertificate) {
  if (cert.status !== 'pending') throw new ServiceError('Only a certificate waiting to be issued can be issued.', 'conflict');
  cert.status = 'issued';
  cert.issuedAt = mockNowIso();
  cert.templateId = templateFor(cert.courseId);
  invalidateAnalytics();
  return cert;
}

const summaries = () =>
  certificateTemplates.map((template) => ({
    template,
    courses: courses.filter((c) => c.certificateTitle && templateFor(c.id) === template.id).map((c) => ({ id: c.id, title: c.title })),
    issued: issuedCertificates().filter((c) => c.templateId === template.id && c.status === 'issued').length,
  }));

export const certificateAdminService: CertificateAdminService = {
  list: ({ search = '', courseId, status = 'all', page, pageSize }) =>
    respond(() => {
      const empty: Record<IssuedCertificateStatus | 'all', number> = { all: 0, issued: 0, pending: 0, revoked: 0 };
      if (scenario() === 'empty') return { rows: [], total: 0, counts: empty };
      const q = search.trim().toLowerCase();
      const matching: CertificateRow[] = [];
      for (const cert of issuedCertificates()) {
        if (courseId && cert.courseId !== courseId) continue;
        const s = studentById.get(cert.studentId);
        if (q && !`${s?.name} ${s?.email} ${cert.credentialId} ${cert.title}`.toLowerCase().includes(q)) continue;
        matching.push({
          certificate: cert,
          studentName: s?.name ?? 'Former learner',
          studentEmail: s?.email ?? '',
          courseTitle: courses.find((c) => c.id === cert.courseId)?.title ?? '',
        });
      }
      const counts = { ...empty, all: matching.length };
      for (const r of matching) counts[r.certificate.status] += 1;
      const rows = matching.filter((r) => status === 'all' || r.certificate.status === status);
      return { rows: rows.slice((page - 1) * pageSize, page * pageSize), total: rows.length, counts };
    }, 520),

  get: (id) => respond(() => certificateDetail(find(id)), 460),

  issue: (id) => respond(() => issue(find(id)), 800),

  revoke: (id, reason) =>
    respond(() => {
      const cert = find(id);
      if (cert.status !== 'issued') throw new ServiceError('Only an issued certificate can be revoked.', 'conflict');
      if (reason.trim().length < 10) throw new ServiceError('Record why the certificate is being revoked — the learner sees this.', 'conflict');
      cert.status = 'revoked';
      cert.revokedAt = mockNowIso();
      cert.revokedReason = reason.trim();
      return cert;
    }, 800),

  restore: (id) =>
    respond(() => {
      const cert = find(id);
      if (cert.status !== 'revoked') throw new ServiceError('This certificate isn’t revoked.', 'conflict');
      cert.status = 'issued';
      cert.revokedAt = undefined;
      cert.revokedReason = undefined;
      return cert;
    }, 700),

  listTemplates: () => respond(summaries, 420),

  getTemplate: (id) =>
    respond(() => {
      const summary = summaries().find((s) => s.template.id === id);
      if (!summary) throw new ServiceError('This template doesn’t exist.', 'not-found');
      return {
        ...summary,
        allCourses: courses
          .filter((c) => c.certificateTitle && c.status !== 'archived')
          .map((c) => ({ id: c.id, title: c.title, templateId: templateFor(c.id) })),
      };
    }, 420),

  saveTemplate: (id, input) =>
    respond(() => {
      const issues = validateTemplate(input);
      if (issues.length) throw new ServiceError(issues[0].message, 'conflict');
      const { courseIds, ...fields } = input;
      let template: CertificateTemplate;
      if (id) {
        template = certificateTemplates.find((t) => t.id === id) as CertificateTemplate;
        if (!template) throw new ServiceError('This template doesn’t exist.', 'not-found');
        Object.assign(template, fields, { updatedAt: mockNowIso() });
      } else {
        template = { ...fields, id: `tpl-${Date.now().toString(36)}`, isDefault: false, updatedAt: mockNowIso() };
        certificateTemplates.push(template);
      }
      // Courses moved to this template; courses taken off it fall back to the default.
      for (const course of courses.filter((c) => c.certificateTitle)) {
        if (courseIds.includes(course.id)) courseTemplate[course.id] = template.id;
        else if (courseTemplate[course.id] === template.id) delete courseTemplate[course.id];
      }
      return template;
    }, 800),

  setDefaultTemplate: (id) =>
    respond(() => {
      const template = certificateTemplates.find((t) => t.id === id);
      if (!template) throw new ServiceError('This template doesn’t exist.', 'not-found');
      for (const t of certificateTemplates) t.isDefault = t.id === id;
      return template;
    }, 600),

  verify: (credentialId) =>
    respond(() => {
      const cert = issuedCertificates().find((c) => c.credentialId.toLowerCase() === credentialId.trim().toLowerCase());
      if (!cert || cert.status === 'pending') throw new ServiceError('No certificate matches this credential ID.', 'not-found');
      cert.verifications += 1;
      return certificateDetail(cert);
    }, 700),
};
