import { DEFAULT_SITE_CONTENT, isLive, orderedSections, type PublicAffiliateProgram, type SiteContent } from '@syniastrolms/domain';
import type { Request } from 'express';

import { recordAuditLog } from './audit.js';
import { db } from './db.js';
import { activeMlmPlan } from './mlm/plan.js';
import { workspaceId } from './requestContext.js';
import { runInTenant } from './tenancy.js';

/*
 * The public website's editable document (docs/16 §2.6): one row for the workspace, made on the first save. Until then
 * the site shows the defaults, and any field an older document lacks falls back to its default.
 */

export async function readSiteContent(): Promise<SiteContent> {
  const row = await db.siteContent.findFirst();
  if (!row) return DEFAULT_SITE_CONTENT;
  const saved = { ...DEFAULT_SITE_CONTENT, ...(JSON.parse(row.contentJson) as Partial<SiteContent>) };
  return { ...saved, sections: orderedSections(saved.sections) };
}

/** What a visitor may read: testimonials and banners that are switched on and inside their dates. */
export async function publicSiteContent(now = new Date()): Promise<SiteContent> {
  const content = await readSiteContent();
  return { ...content, testimonials: content.testimonials.filter((t) => isLive(t, now)), banners: content.banners.filter((b) => isLive(b, now)) };
}

export async function saveSiteContent(req: Request, content: SiteContent): Promise<SiteContent> {
  const tenantId = await workspaceId();
  return runInTenant(tenantId, async () => {
    const contentJson = JSON.stringify(content);
    const existing = await db.siteContent.findFirst({ select: { id: true } });
    if (existing) await db.siteContent.update({ where: { id: existing.id }, data: { contentJson } });
    else await db.siteContent.create({ data: { tenantId, contentJson } });
    await recordAuditLog(req, {
      action: 'site.content_updated',
      targetType: 'site',
      targetId: tenantId,
      meta: { featured: content.featuredCourseIds.length, bundles: content.featuredBundleIds.length, testimonials: content.testimonials.length, banners: content.banners.length, faqs: content.faqs.length },
    });
    return content;
  });
}

/** What the affiliate page may publish: the active plan's own terms. Nothing here projects what anyone will earn. */
export async function publicAffiliateProgram(): Promise<PublicAffiliateProgram> {
  const plan = await activeMlmPlan();
  if (!plan) return { active: false, course: null, currency: 'INR', matchingRateBps: 0, withdrawalMinAmount: 0, withdrawalRequiresKyc: true, ranks: [] };
  const course = plan.eligibleCourseIds.length
    ? await db.course.findFirst({
        where: { id: { in: plan.eligibleCourseIds }, status: 'published' },
        select: { slug: true, title: true, pricing: true, priceAmount: true },
        orderBy: { title: 'asc' },
      })
    : null;
  const caps = new Map(plan.capBands.map((b) => [b.key, b.dailyCap]));
  return {
    active: true,
    course: course
      ? { slug: course.slug, title: course.title, priceAmount: course.pricing === 'paid' ? course.priceAmount : null, currency: plan.currency }
      : null,
    currency: plan.currency,
    matchingRateBps: plan.matchingRateBps,
    withdrawalMinAmount: plan.withdrawalMinAmount,
    withdrawalRequiresKyc: plan.withdrawalRequiresKyc,
    ranks: plan.tiers.map((t) => ({
      order: t.order,
      name: t.name,
      groupCv: t.groupCv,
      rewardKind: t.rewardKind,
      rewardAmount: t.rewardAmount,
      rewardCapAmount: t.rewardCapAmount,
      dailyCap: caps.get(t.capBandKey) ?? 0,
    })),
  };
}
