import { db } from './db.js';
import { runAsPlatform } from './tenancy.js';

/*
 * Who may read an uploaded file (SAAS-023). Files live in exactly three places: a lesson's content, an assignment's
 * attachments, and a learner's hand-in (draft or submission). Reading one follows what the viewer may open:
 *
 * - its uploader, always;
 * - an academy admin, every file of the academy;
 * - an instructor, any file staff uploaded (course material, including a colleague's), and a learner's hand-in only
 *   when it belongs to an assignment in a course the instructor teaches;
 * - a learner, a staff file only when it is in a published lesson of a course they are enrolled in (not expired),
 *   in a published free-preview lesson, or among the attachments of a published assignment of such a course.
 *
 * Everything is read inside the request's academy, so another academy's file is never found. A refusal is the same
 * 404 as a file that does not exist. Media ids are unique, unguessable strings, so looking for one inside a content
 * column matches only where that file was placed.
 */

type Viewer = { sub: string; role: string; instructorId?: string; studentId?: string };
type Asset = { id: string; ownerUserId: string };

const STAFF = new Set(['superadmin', 'admin', 'instructor']);

/**
 * Whether a member of staff uploaded a file. Read as the platform: a Super Admin works in the academy's workspace but
 * belongs to no academy, so the academy's view of `User` cannot see them. Callers have already found the file itself
 * in their own academy, and only the uploader's role is read.
 */
export async function isStaffUpload(ownerUserId: string): Promise<boolean> {
  const owner = await runAsPlatform('a file’s uploader may be a platform account', () =>
    db.user.findUnique({ where: { id: ownerUserId }, select: { role: true } }),
  );
  return !!owner && STAFF.has(owner.role);
}

/**
 * A grant is kept briefly: a video streams as many range requests, each of which would ask again. Only grants —
 * a refusal is asked again, so a learner who has just enrolled is never held to an earlier no. Losing access (an
 * enrolment removed) takes effect within `CACHE_MS`.
 */
const CACHE_MS = 60_000;
const cache = new Map<string, number>();

export async function canReadMedia(viewer: Viewer, asset: Asset): Promise<boolean> {
  if (asset.ownerUserId === viewer.sub) return true;
  if (viewer.role === 'admin' || viewer.role === 'superadmin') return true;
  if (!STAFF.has(viewer.role) && viewer.role !== 'student') return false;

  const key = `${viewer.sub}:${asset.id}`;
  const grantedAt = cache.get(key);
  if (grantedAt && Date.now() - grantedAt < CACHE_MS) return true;
  const allowed = await decide(viewer, asset);
  if (allowed) {
    if (cache.size > 5000) cache.clear();
    cache.set(key, Date.now());
  }
  return allowed;
}

/** Forgets cached decisions (tests change enrolments between requests). */
export const clearMediaAccessCache = () => cache.clear();

async function decide(viewer: Viewer, asset: Asset): Promise<boolean> {
  const ownerIsStaff = await isStaffUpload(asset.ownerUserId);

  if (viewer.role === 'instructor') {
    if (ownerIsStaff) return true;
    if (!viewer.instructorId) return false;
    // A learner's hand-in: only for an assignment in a course this instructor teaches.
    const taught = { course: { instructors: { some: { instructorId: viewer.instructorId } } } };
    const [submitted, drafted] = await Promise.all([
      db.submission.count({ where: { filesJson: { contains: asset.id }, assignment: taught } }),
      db.assignmentDraft.count({ where: { filesJson: { contains: asset.id }, assignment: taught } }),
    ]);
    return submitted + drafted > 0;
  }

  // A learner reads another account's file only when it is course material placed where they may open it.
  if (!ownerIsStaff || !viewer.studentId) return false;
  const enrolled = await db.enrollment.findMany({ where: { studentId: viewer.studentId, status: { not: 'expired' } }, select: { courseId: true } });
  const courseIds = enrolled.map((e) => e.courseId);
  const [lessons, attachments] = await Promise.all([
    db.lesson.count({
      where: {
        contentJson: { contains: asset.id },
        status: 'published',
        OR: [{ courseId: { in: courseIds } }, { isPreview: true, chapter: { course: { status: 'published' } } }],
      },
    }),
    db.courseAssignment.count({ where: { attachmentsJson: { contains: asset.id }, status: { not: 'draft' }, courseId: { in: courseIds } } }),
  ]);
  return lessons + attachments > 0;
}
