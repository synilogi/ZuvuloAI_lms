import { Router } from 'express';
import { validateSettings, SETTINGS_SECTIONS, type SettingsSection } from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { currentTenantId } from '../lib/tenancy.js';
import { asyncHandler, badRequest, conflict } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requirePermission, requireStaffPermission } from '../lib/permissions.js';
import { writeJson } from '../lib/json.js';
import { loadRecord } from '../lib/settings.js';

export const settingsRouter = Router();

settingsRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('settings.view'),
  asyncHandler(async (_req, res) => {
    res.json(await loadRecord());
  }),
);

settingsRouter.put(
  '/:section',
  requireAuth,
  requireRole('admin'),
  requirePermission('settings.edit'),
  // Branding is a plan feature; the other settings sections are not.
  asyncHandler(async (req, res) => {
    const section = req.params.section as SettingsSection;
    if (!SETTINGS_SECTIONS.includes(section)) throw badRequest('Unknown settings section.');
    const value = req.body;
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw badRequest('Send the section as an object.');
    // The section validators read the fields they judge, so a body missing them throws rather than
    // returning issues. A payload the validator cannot even read is a bad request, not a server fault.
    let issues;
    try {
      issues = validateSettings(section, value);
    } catch {
      throw badRequest('Send the whole section — some of its fields are missing.');
    }
    if (issues.length) throw conflict('Check this section before saving.', issues);

    const current = await loadRecord();
    current.settings[section] = value;
    current.updatedAt[section] = new Date().toISOString();
    // Who saved it, by name — the settings pages show it.
    const editor = await db.user.findUnique({ where: { id: req.auth!.sub }, select: { name: true } });
    current.updatedBy[section] = editor?.name ?? 'Admin';

    await db.settings.update({
      where: { tenantId: currentTenantId() },
      data: {
        generalJson: writeJson(current.settings.general),
        coursesJson: writeJson(current.settings.courses),
        learningJson: writeJson(current.settings.learning),
        certificatesJson: writeJson(current.settings.certificates),
        notificationsJson: writeJson(current.settings.notifications),
        appearanceJson: writeJson(current.settings.appearance),
        updatedAtJson: writeJson(current.updatedAt),
        updatedByJson: writeJson(current.updatedBy),
      },
    });
    res.json(current);
  }),
);
