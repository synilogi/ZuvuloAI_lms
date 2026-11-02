import { beforeAll, describe, expect, it } from 'vitest';

import { as, newStudent, type Client } from './test/helpers.js';

/* Instructor scope and learner ownership, using the seeded academy: Meenakshi and Vinod teach
 * different courses; Ananya is enrolled in some of them; a freshly registered learner is in none. */

let admin: Client;
let meenakshi: Client;
let vinod: Client;
let ananya: Client;
let myCourseIds: string[];
let foreignCourseId: string;

beforeAll(async () => {
  admin = await as('admin');
  meenakshi = await as('instructor');
  vinod = await as('instructor2');
  ananya = await as('student');
  const mine = await meenakshi.get('/courses', { pageSize: 100 });
  const theirs = await vinod.get('/courses', { pageSize: 100 });
  myCourseIds = mine.body.rows.map((r: { id: string }) => r.id);
  const foreign = theirs.body.rows.find((r: { id: string }) => !myCourseIds.includes(r.id));
  if (!foreign) throw new Error('seed must give Vinod a course Meenakshi does not teach');
  foreignCourseId = foreign.id;
});

describe('instructor scope is derived from the token', () => {
  it('lists only the courses the instructor teaches, whatever the query says', async () => {
    const res = await meenakshi.get('/courses', { scopeInstructorId: 'anything', pageSize: 100 });
    expect(res.status).toBe(200);
    for (const row of res.body.rows as { instructorIds: string[] }[]) expect(row.instructorIds).toContain(meenakshiId());
    expect(res.body.rows.map((r: { id: string }) => r.id)).not.toContain(foreignCourseId);
  });

  it("answers 404 for another instructor's course on read, edit, publish and curriculum routes", async () => {
    expect((await meenakshi.get(`/courses/${foreignCourseId}`)).status).toBe(404);
    expect((await meenakshi.get(`/courses/${foreignCourseId}/stats`)).status).toBe(404);
    expect((await meenakshi.patch(`/courses/${foreignCourseId}`, { title: 'Hijacked' })).status).toBe(404);
    expect((await meenakshi.post(`/courses/${foreignCourseId}/archive`)).status).toBe(404);
    expect((await meenakshi.get(`/courses/${foreignCourseId}/chapters/stats`)).status).toBe(404);
    expect((await meenakshi.get(`/courses/${foreignCourseId}/lessons`)).status).toBe(404);
    expect((await meenakshi.post(`/courses/${foreignCourseId}/chapters`, { title: 'Sneaky chapter' })).status).toBe(404);
    // the admin, and the course's own instructor, still can
    expect((await admin.get(`/courses/${foreignCourseId}`)).status).toBe(200);
    expect((await vinod.get(`/courses/${foreignCourseId}`)).status).toBe(200);
  });

  it("keeps quizzes, assignments, certificates, live classes and submissions inside the instructor's courses", async () => {
    for (const path of ['/quizzes', '/assignments', '/certificates', '/live']) {
      const res = await meenakshi.get(path, { pageSize: 100 });
      expect(res.status).toBe(200);
      const rows = res.body.rows as Record<string, { courseId: string }>[];
      for (const row of rows) {
        const record = row.quiz ?? row.assignment ?? row.certificate ?? row.liveClass;
        expect(myCourseIds).toContain(record.courseId);
      }
    }
    // Submissions of a course the instructor does not teach are invisible even when asked for by id.
    const foreignSubs = await meenakshi.get('/assignments/submissions', { courseId: foreignCourseId, pageSize: 100 });
    expect(foreignSubs.status).toBe(200);
    expect(foreignSubs.body.rows).toEqual([]);
    const ownSubs = await vinod.get('/assignments/submissions', { courseId: foreignCourseId, pageSize: 100 });
    expect(ownSubs.status).toBe(200);

    const foreignQuiz = (await vinod.get('/quizzes')).body.rows.find((r: { quiz: { courseId: string } }) => r.quiz.courseId === foreignCourseId);
    if (foreignQuiz) {
      expect((await meenakshi.get(`/quizzes/${foreignQuiz.quiz.id}`)).status).toBe(404);
      expect((await meenakshi.delete(`/quizzes/${foreignQuiz.quiz.id}`)).status).toBe(404);
    }
    const created = await meenakshi.post('/quizzes', {
      courseId: foreignCourseId,
      title: 'Planted quiz',
      instructions: '',
      status: 'draft',
      questions: [],
      settings: {},
    });
    expect(created.status).toBe(404);
  });

  it('shows an instructor only the learners enrolled in their courses', async () => {
    const res = await meenakshi.get('/students', { pageSize: 200 });
    expect(res.status).toBe(200);
    expect(res.body.rows.length).toBeGreaterThan(0);
    for (const row of res.body.rows as { courses: { id: string }[] }[]) expect(row.courses.some((c) => myCourseIds.includes(c.id))).toBe(true);

    const stranger = await newStudent('Unrelated Learner');
    expect((await meenakshi.get(`/students/${stranger.studentId}`)).status).toBe(404);
    expect((await meenakshi.get(`/students/${stranger.studentId}/progress`)).status).toBe(404);
    expect((await admin.get(`/students/${stranger.studentId}`)).status).toBe(200);
    // enrolling someone into a course the instructor does not teach is refused too
    expect((await meenakshi.post(`/students/${stranger.studentId}/enroll`, { courseId: foreignCourseId, source: 'admin' })).status).toBe(404);
  });

  it('scopes reports and the dashboard to the instructor, ignoring query overrides', async () => {
    const report = await meenakshi.get('/reports/courses', { instructorId: vinodId(), range: '12m' });
    expect(report.status).toBe(200);
    for (const row of report.body.rows as { courseId: string }[]) expect(myCourseIds).toContain(row.courseId);
    expect((await meenakshi.get('/reports/instructors')).status).toBe(403);
    const dash = await meenakshi.get('/dashboard', { scope: 'academy' });
    expect(dash.status).toBe(200);
    for (const c of dash.body.courses as { courseId: string }[]) expect(myCourseIds).toContain(c.courseId);
  });

  it('blocks instructors from admin-only settings and category writes', async () => {
    expect((await meenakshi.put('/settings/general', {})).status).toBe(403);
    expect((await meenakshi.post('/categories', { name: 'Nope' })).status).toBe(403);
    expect((await meenakshi.post('/instructors', { name: 'X', email: 'x@example.com' })).status).toBe(403);
  });

  it('adds the creating instructor to their own new course and never lets them drop themselves', async () => {
    const created = await meenakshi.post('/courses', {
      title: `Scoped course ${Date.now()}`,
      levelId: firstLevelId,
      categoryId: firstCategoryId,
      format: 'self-paced',
      coverMotif: 'orbits',
      instructorIds: [vinodId()],
    });
    expect(created.status).toBe(201);
    expect(created.body.instructorIds).toContain(meenakshiId());
    const patched = await meenakshi.patch(`/courses/${created.body.id}`, { instructorIds: [vinodId()] });
    expect(patched.status).toBe(200);
    expect(patched.body.instructorIds).toContain(meenakshiId());
  });
});

/**
 * A free catalog course with a chapter of lessons, one of them not a preview. Other suites add courses of every kind to
 * the shared database — paid ones, which nobody enrols in for free, and ones without lessons yet — so the first course
 * listed is not necessarily this.
 */
async function freeCourseWithLessons(client: { get: (path: string) => PromiseLike<{ body: unknown }> }) {
  type Listed = { id: string; slug: string; pricing?: string; chapters: { lessons: { id: string; title: string; isPreview?: boolean }[] }[] };
  const listed = (await client.get('/catalog/courses')).body as Listed[];
  const found = listed.find((c) => c.pricing === 'free' && c.chapters[0]?.lessons.length && c.chapters.some((ch) => ch.lessons.some((l) => !l.isPreview)));
  if (!found) throw new Error('No free course with lessons in the catalog.');
  return found;
}

describe('learners only reach their own records and enrolled content', () => {
  it('keeps staff routes closed to learners', async () => {
    expect((await ananya.get('/courses')).status).toBe(403);
    expect((await ananya.get(`/courses/${foreignCourseId}`)).status).toBe(403);
    expect((await ananya.get('/students')).status).toBe(403);
    expect((await ananya.get('/quizzes')).status).toBe(403);
    expect((await ananya.get('/settings')).status).toBe(403);
    expect((await ananya.get('/dashboard')).status).toBe(403);
    expect((await ananya.get('/reports/overview')).status).toBe(403);
  });

  it('hides lesson bodies from learners who are not enrolled, but keeps the outline', async () => {
    const stranger = await newStudent();
    const publishedCourse = await freeCourseWithLessons(stranger);
    const lesson = publishedCourse.chapters.flatMap((c) => c.lessons).find((l) => !l.isPreview)!;

    const course = await stranger.get(`/learning/courses/${publishedCourse.id}`);
    expect(course.status).toBe(200);
    expect(course.body.enrolled).toBe(false);
    const outline = course.body.course.chapters
      .flatMap((c: { lessons: { id: string; content: object }[] }) => c.lessons)
      .find((l: { id: string }) => l.id === lesson.id);
    expect(outline.title).toBe(lesson.title);
    expect(outline.content).toEqual({});

    const player = await stranger.get(`/learning/courses/${publishedCourse.id}/lessons/${lesson.id}`);
    expect(player.status).toBe(200);
    expect(player.body.access).toBe('not-enrolled');
    expect(player.body.lesson.content).toEqual({});
    expect(player.body.quiz).toBeUndefined();

    expect((await stranger.post(`/learning/courses/${publishedCourse.id}/lessons/${lesson.id}/complete`)).status).toBe(403);
    expect((await stranger.put(`/learning/courses/${publishedCourse.id}/lessons/${lesson.id}/note`, { text: 'hi' })).status).toBe(403);
    expect((await stranger.post(`/learning/courses/${publishedCourse.id}/lessons/${lesson.id}/quiz-attempt`, { percent: 100, passed: true })).status).toBe(403);

    // catalog never carries bodies either
    const catalogLesson = (await stranger.get(`/catalog/courses/${publishedCourse.slug}`)).body.chapters
      .flatMap((c: { lessons: { id: string; content: object }[] }) => c.lessons)
      .find((l: { id: string }) => l.id === lesson.id);
    expect(catalogLesson.content).toEqual({});
  });

  it('serves full lesson bodies to an enrolled learner', async () => {
    const enrolled = await newStudent();
    const publishedCourse = await freeCourseWithLessons(enrolled);
    const lesson = publishedCourse.chapters[0].lessons[0] as { id: string };
    expect((await enrolled.post(`/learning/courses/${publishedCourse.id}/enroll`)).status).toBe(200);
    const player = await enrolled.get(`/learning/courses/${publishedCourse.id}/lessons/${lesson.id}`);
    expect(player.status).toBe(200);
    expect(['open', 'locked']).toContain(player.body.access);
    if (player.body.access === 'open') expect(Object.keys(player.body.lesson.content).length).toBeGreaterThan(0);
  });

  it('refuses drafts and unknown courses to learners', async () => {
    const draft = await admin.post('/courses', {
      title: `Draft ${Date.now()}`,
      levelId: firstLevelId,
      categoryId: firstCategoryId,
      format: 'self-paced',
      coverMotif: 'orbits',
      instructorIds: [],
    });
    expect(draft.status).toBe(201);
    expect((await ananya.get(`/learning/courses/${draft.body.id}`)).status).toBe(404);
    expect((await ananya.post(`/learning/courses/${draft.body.id}/enroll`)).status).toBe(404);
    expect((await ananya.get(`/catalog/courses/${draft.body.slug}`)).status).toBe(404);
  });

  it("keeps assignments, certificates and live registration to the learner's own enrollments", async () => {
    const stranger = await newStudent();
    const mine = await ananya.get('/learning/assignments');
    expect(mine.status).toBe(200);
    const anAssignment = mine.body[0]?.assignment?.id as string | undefined;
    if (anAssignment) {
      expect((await stranger.get(`/learning/assignments/${anAssignment}`)).status).toBe(403);
      expect((await stranger.post(`/learning/assignments/${anAssignment}/submit`, { text: 'planted' })).status).toBe(403);
      expect((await ananya.get(`/learning/assignments/${anAssignment}`)).status).toBe(200);
    }

    const certs = await ananya.get('/learning/certificates');
    const someCert = (certs.body.issued[0] ?? certs.body.pending[0])?.certificate?.id as string | undefined;
    expect(someCert).toBeDefined();
    expect((await stranger.get(`/learning/certificates/${someCert}`)).status).toBe(404);
    expect((await stranger.post(`/learning/certificates/${someCert}/claim`)).status).toBe(404);
    expect((await ananya.get(`/learning/certificates/${someCert}`)).status).toBe(200);
    // an issued certificate cannot be "claimed" again either
    if (certs.body.issued[0]) expect((await ananya.post(`/learning/certificates/${certs.body.issued[0].certificate.id}/claim`)).status).toBe(404);

    // An enrolment-only class: `public` ("Any learner") classes are open to every learner by design,
    // and are covered in routes/live.test.ts.
    const live = (await admin.get('/live', { pageSize: 100 })).body.rows.find(
      (r: { liveClass: { cancelled?: boolean; visibility?: string } }) => !r.liveClass.cancelled && r.liveClass.visibility !== 'public',
    );
    if (live) expect((await stranger.post(`/live/${live.liveClass.id}/register`)).status).toBe(403);
  });
});

/* seed lookups */
let firstLevelId: string;
let firstCategoryId: string;
const ids: Record<string, string> = {};
const meenakshiId = () => ids.meenakshi;
const vinodId = () => ids.vinod;

beforeAll(async () => {
  const levels = await (await as('admin')).get('/catalog/levels');
  const categories = await (await as('admin')).get('/catalog/categories');
  firstLevelId = levels.body[0].id;
  firstCategoryId = categories.body[0].id;
  const instructors = await (await as('admin')).get('/instructors');
  for (const row of instructors.body.rows ?? instructors.body) {
    const ins = row.instructor ?? row;
    if (ins.email === 'meenakshi@syniastrolms.test') ids.meenakshi = ins.id;
    if (ins.email === 'vinod@syniastrolms.test') ids.vinod = ins.id;
  }
});
