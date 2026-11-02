import { Router } from 'express';
import {
  validateTemplate,
  type CertificateTemplate,
  type CertificateTemplateInput,
  type IssuedCertificate,
  type IssuedCertificateStatus,
  type Signatory,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { currentTenantId, runAsPlatform, runInTenant, tenant } from '../lib/tenancy.js';
import { asyncHandler, badRequest, conflict, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requirePermission, requireStaffPermission } from '../lib/permissions.js';
import { assertCertificateAccess, courseScopeWhere } from '../lib/scope.js';
import { getSettings, loadRecord } from '../lib/settings.js';
import { notify } from '../lib/notify.js';
import { writeJson as writeSettingsJson } from '../lib/json.js';
import { id as idSchema, optionalId, paging, parseBody, parseQuery, searchText, z } from '../lib/validate.js';
import { readJson, writeJson } from '../lib/json.js';

export const certificatesRouter = Router();

function mapTemplate(row: {
  id: string;
  name: string;
  style: string;
  accent: string;
  heading: string;
  statement: string;
  signatoriesJson: string;
  showScore: boolean;
  showHours: boolean;
  isDefault: boolean;
  updatedAt: Date;
}): CertificateTemplate {
  return {
    id: row.id,
    name: row.name,
    style: row.style as CertificateTemplate['style'],
    accent: row.accent as CertificateTemplate['accent'],
    heading: row.heading,
    statement: row.statement,
    signatories: readJson<Signatory[]>(row.signatoriesJson, []),
    showScore: row.showScore,
    showHours: row.showHours,
    isDefault: row.isDefault,
    updatedAt: row.updatedAt.toISOString(),
  };
}

function mapCertificate(row: {
  id: string;
  credentialId: string;
  studentId: string;
  courseId: string;
  title: string;
  templateId: string;
  status: string;
  completedAt: Date;
  issuedAt: Date | null;
  revokedAt: Date | null;
  revokedReason: string | null;
  finalScore: number | null;
  hours: number;
  verifications: number;
}): IssuedCertificate {
  return {
    id: row.id,
    credentialId: row.credentialId,
    studentId: row.studentId,
    courseId: row.courseId,
    title: row.title,
    templateId: row.templateId,
    status: row.status as IssuedCertificateStatus,
    completedAt: row.completedAt.toISOString(),
    issuedAt: row.issuedAt?.toISOString(),
    revokedAt: row.revokedAt?.toISOString(),
    revokedReason: row.revokedReason ?? undefined,
    finalScore: row.finalScore ?? undefined,
    hours: row.hours,
    verifications: row.verifications,
  };
}

async function detailFor(
  row: Awaited<ReturnType<typeof db.issuedCertificate.findUniqueOrThrow>> & {
    student: { user: { name: string; email: string }; city: string };
    course: { title: string; level: { name: string } };
    template: Awaited<ReturnType<typeof db.certificateTemplate.findUniqueOrThrow>>;
  },
) {
  return {
    // The platform that issued it, by its own name (multi-admin SaaS): the certificate, its share text and the
    // public verification page say who issued it.
    issuer: (await getSettings()).general.academyName,
    certificate: mapCertificate(row),
    student: { id: row.studentId, name: row.student.user.name, email: row.student.user.email, city: row.student.city },
    courseTitle: row.course.title,
    levelTitle: row.course.level.name,
    template: mapTemplate(row.template),
    verifyUrl: `/verify/${row.credentialId}`,
  };
}

certificatesRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  asyncHandler(async (req, res) => {
    const { search, courseId, status, page, pageSize } = parseQuery(req, z.object({ search: searchText, courseId: optionalId, status: optionalId, ...paging }));
    const certs = await db.issuedCertificate.findMany({
      where: { ...(courseId ? { courseId } : {}), course: courseScopeWhere(req) },
      include: { student: { include: { user: true } }, course: true },
    });

    let rows = certs.map((c) => ({
      certificate: mapCertificate(c),
      studentName: c.student.user.name,
      studentEmail: c.student.user.email,
      courseTitle: c.course.title,
    }));
    const counts: Record<IssuedCertificateStatus | 'all', number> = { all: rows.length, issued: 0, pending: 0, revoked: 0 };
    for (const r of rows) counts[r.certificate.status]++;

    if (search)
      rows = rows.filter(
        (r) =>
          r.studentName.toLowerCase().includes(search.toLowerCase()) ||
          r.studentEmail.toLowerCase().includes(search.toLowerCase()) ||
          r.certificate.credentialId.toLowerCase().includes(search.toLowerCase()),
      );
    if (status && status !== 'all') rows = rows.filter((r) => r.certificate.status === status);

    res.json({ rows: rows.slice((page - 1) * pageSize, page * pageSize), total: rows.length, counts });
  }),
);

certificatesRouter.get(
  '/templates',
  requireAuth,
  requireRole('instructor', 'admin'),
  asyncHandler(async (_req, res) => {
    const templates = await db.certificateTemplate.findMany();
    const result = await Promise.all(
      templates.map(async (t) => {
        const courses = await db.course.findMany({ where: { certificateTemplateId: t.id }, select: { id: true, title: true } });
        const issued = await db.issuedCertificate.count({ where: { templateId: t.id, status: 'issued' } });
        return { template: mapTemplate(t), courses, issued };
      }),
    );
    res.json(result);
  }),
);

certificatesRouter.get(
  '/templates/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  asyncHandler(async (req, res) => {
    const t = await db.certificateTemplate.findUnique({ where: { id: req.params.id } });
    if (!t) throw notFound('Template not found.');
    const courses = await db.course.findMany({ where: { certificateTemplateId: t.id }, select: { id: true, title: true } });
    const issued = await db.issuedCertificate.count({ where: { templateId: t.id, status: 'issued' } });
    const allCourses = await db.course.findMany({ select: { id: true, title: true, certificateTemplateId: true } });
    res.json({
      template: mapTemplate(t),
      courses,
      issued,
      allCourses: allCourses.map((c) => ({ id: c.id, title: c.title, templateId: c.certificateTemplateId ?? '' })),
    });
  }),
);

certificatesRouter.post(
  '/templates',
  requireAuth,
  requireRole('admin'),
  requirePermission('certificates.templates.manage'),
  asyncHandler(async (req, res) => {
    // The envelope is checked here; `validateTemplate` below judges the template itself.
    const { id, input } = parseBody(req, z.object({ id: idSchema.nullish(), input: z.record(z.string(), z.unknown()) })) as {
      id: string | null;
      input: CertificateTemplateInput & { courseIds: string[] };
    };
    const issues = validateTemplate(input);
    if (issues.length) throw conflict('Check the template before saving.', issues);

    const data = {
      name: input.name,
      style: input.style,
      accent: input.accent,
      heading: input.heading,
      statement: input.statement,
      signatoriesJson: writeJson(input.signatories),
      showScore: input.showScore,
      showHours: input.showHours,
    };
    const row = id ? await db.certificateTemplate.update({ where: { id }, data }) : await db.certificateTemplate.create({ data: { ...tenant(), ...data } });
    if (input.courseIds) {
      await db.course.updateMany({ where: { certificateTemplateId: row.id }, data: { certificateTemplateId: null } });
      await db.course.updateMany({ where: { id: { in: input.courseIds } }, data: { certificateTemplateId: row.id } });
    }
    res.status(id ? 200 : 201).json(mapTemplate(row));
  }),
);

certificatesRouter.post(
  '/templates/:id/default',
  requireAuth,
  requireRole('admin'),
  requirePermission('certificates.templates.manage'),
  asyncHandler(async (req, res) => {
    await db.certificateTemplate.updateMany({ data: { isDefault: false }, where: {} });
    const row = await db.certificateTemplate.update({ where: { id: req.params.id }, data: { isDefault: true } });
    // Keep the platform setting in step so both places agree on the default.
    const record = await loadRecord();
    await db.settings.update({
      where: { tenantId: currentTenantId() },
      data: { certificatesJson: writeSettingsJson({ ...record.settings.certificates, defaultTemplateId: row.id }) },
    });
    res.json(mapTemplate(row));
  }),
);

certificatesRouter.get(
  '/verify/:credentialId',
  asyncHandler(async (req, res) => {
    // A verification link carries no academy, and the visitor following it is usually not signed in.
    // The credential ID is unique across the platform (D4), so it finds its certificate on its own;
    // everything after that — the academy's switch, its validity rule, the count — runs in the academy
    // that issued it.
    const found = await runAsPlatform('a credential ID is unique across the platform and verifies without an academy (D4)', () =>
      db.issuedCertificate.findUnique({ where: { credentialId: req.params.credentialId }, select: { id: true, tenantId: true } }),
    );
    if (!found) throw notFound('No certificate matches this credential ID.');
    await runInTenant(found.tenantId, async () => {
      // Public verification can be switched off by the academy; pending certificates never verify.
      const { certificates } = await getSettings();
      if (!certificates.publicVerification) throw notFound('No certificate matches this credential ID.');
      const row = await db.issuedCertificate.findUnique({
        where: { id: found.id },
        include: { student: { include: { user: true } }, course: { include: { level: true } }, template: true },
      });
      if (!row || row.status === 'pending') throw notFound('No certificate matches this credential ID.');
      await db.issuedCertificate.update({ where: { id: row.id }, data: { verifications: { increment: 1 } } });
      // Certificates can carry a validity period (settings.certificates.validityMonths).
      const validUntil =
        certificates.validityMonths && row.issuedAt ? new Date(new Date(row.issuedAt).setMonth(row.issuedAt.getMonth() + certificates.validityMonths)) : null;
      res.json({ ...(await detailFor(row as never)), validUntil: validUntil?.toISOString(), expired: validUntil ? validUntil < new Date() : false });
    });
  }),
);

certificatesRouter.get(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  asyncHandler(async (req, res) => {
    await assertCertificateAccess(req, req.params.id);
    const row = await db.issuedCertificate.findUnique({
      where: { id: req.params.id },
      include: { student: { include: { user: true } }, course: { include: { level: true } }, template: true },
    });
    if (!row) throw notFound('Certificate not found.');
    res.json(await detailFor(row as never));
  }),
);

certificatesRouter.post(
  '/:id/issue',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('certificates.issue'),
  asyncHandler(async (req, res) => {
    const cert = await assertCertificateAccess(req, req.params.id);
    if (cert.status !== 'pending') throw conflict('Only a pending certificate can be issued.');
    const row = await db.issuedCertificate.update({
      where: { id: cert.id },
      data: { status: 'issued', issuedAt: new Date() },
      include: { student: true, course: true },
    });
    await notify({
      recipientUserId: row.student.userId,
      category: 'certificate',
      title: `Your certificate for ${row.course.title} has been issued`,
      summary: `Credential ${row.credentialId} — download and share it from your certificates.`,
      important: true,
      facts: [{ label: 'Credential', value: row.credentialId }],
      action: { label: 'View certificate', to: `/certificates/${row.id}` },
      switch: 'learner.certificateIssued',
    });
    res.json(mapCertificate(row));
  }),
);

certificatesRouter.post(
  '/:id/revoke',
  requireAuth,
  requireRole('admin'),
  requirePermission('certificates.revoke'),
  asyncHandler(async (req, res) => {
    const { reason } = parseBody(req, z.object({ reason: z.string().trim().max(1000).default('') }));
    if (reason.length < 3) throw badRequest('Explain why this certificate is being revoked.');
    const existing = await db.issuedCertificate.findUnique({ where: { id: req.params.id } });
    if (!existing) throw notFound('Certificate not found.');
    const row = await db.issuedCertificate.update({
      where: { id: existing.id },
      data: { status: 'revoked', revokedAt: new Date(), revokedReason: reason },
      include: { student: true, course: true },
    });
    await notify({
      recipientUserId: row.student.userId,
      category: 'certificate',
      title: `Your certificate for ${row.course.title} has been revoked`,
      summary: reason,
      important: true,
      action: { label: 'Contact support', to: '/help' },
    });
    res.json(mapCertificate(row));
  }),
);

certificatesRouter.post(
  '/:id/restore',
  requireAuth,
  requireRole('admin'),
  requirePermission('certificates.revoke'),
  asyncHandler(async (req, res) => {
    const existing = await db.issuedCertificate.findUnique({ where: { id: req.params.id } });
    if (!existing) throw notFound('Certificate not found.');
    if (existing.status !== 'revoked') throw conflict('Only a revoked certificate can be restored.');
    const row = await db.issuedCertificate.update({ where: { id: existing.id }, data: { status: 'issued', revokedAt: null, revokedReason: null } });
    res.json(mapCertificate(row));
  }),
);
