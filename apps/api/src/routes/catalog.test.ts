import { beforeAll, describe, expect, it } from 'vitest';

import { db } from '../test/db.js';
import { anon, as, unique, type Client } from '../test/helpers.js';

let admin: Client;
let instructor: Client;
let levelId: string;
let categoryId: string;

const courseInput = (title: string, extra: Record<string, unknown> = {}) => ({ title, levelId, categoryId, coverMotif: 'orbits', instructorIds: [], ...extra });

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  levelId = (await admin.get('/catalog/levels')).body[0].id;
  categoryId = (await admin.get('/catalog/categories')).body[0].id;
});

describe('categories', () => {
  it('validates, creates, refuses duplicates and moves courses on delete', async () => {
    const bad = await admin.post('/categories', { name: 'X', glyph: 'nope' });
    expect(bad.status).toBe(400);
    const name = `Geometry ${unique()}`;
    const created = await admin.post('/categories', { name, description: 'Lines, angles and shapes', glyph: 'compass', status: 'active', levelIds: [levelId] });
    expect(created.status).toBe(201);
    expect(created.body.levelIds).toEqual([levelId]);
    expect((await admin.post('/categories', { name: name.toUpperCase(), glyph: 'sun' })).status).toBe(409);

    const course = await admin.post('/courses', courseInput(`Course in ${name}`, { categoryId: created.body.id }));
    expect(course.status).toBe(201);
    expect((await admin.delete(`/categories/${created.body.id}`)).status).toBe(409);
    const moved = await admin.delete(`/categories/${created.body.id}?moveCoursesTo=${categoryId}`);
    expect(moved.status).toBe(200);
    expect(moved.body.moved).toBe(1);
    expect((await admin.get(`/courses/${course.body.id}`)).body.categoryId).toBe(categoryId);
  });
});

describe('category display order', () => {
  it('moves a category one place and keeps every position unique, 1 to n', async () => {
    const a = await admin.post('/categories', { name: `Order A ${unique()}`, glyph: 'sun' });
    const b = await admin.post('/categories', { name: `Order B ${unique()}`, glyph: 'sun' });
    const before = await db.category.findMany({ orderBy: { order: 'asc' }, select: { id: true, order: true } });
    const atB = before.find((c) => c.id === b.body.id)!.order;
    const moved = await admin.patch(`/categories/${b.body.id}`, { order: atB - 1 });
    expect(moved.status).toBe(200);
    expect(moved.body.order).toBe(atB - 1);
    const after = await db.category.findMany({ orderBy: { order: 'asc' }, select: { id: true, order: true } });
    expect(after.map((c) => c.order)).toEqual(after.map((_, i) => i + 1));
    expect(after.findIndex((c) => c.id === b.body.id)).toBeLessThan(after.findIndex((c) => c.id === a.body.id));
    for (const c of [a, b]) await admin.delete(`/categories/${c.body.id}`);
  });
});

describe('courses: rules from settings', () => {
  it('applies academy defaults, keeps titles unique and limits instructors', async () => {
    const settings = (await admin.get('/settings')).body.settings;
    const title = `Rules ${unique()}`;
    const created = await admin.post('/courses', courseInput(title));
    expect(created.status).toBe(201);
    expect(created.body.format).toBe(settings.courses.defaultFormat);
    expect(created.body.visibility).toBe(settings.general.defaultVisibility);

    expect((await admin.post('/courses', courseInput(title.toLowerCase()))).status).toBe(409);
    expect((await admin.patch(`/courses/${created.body.id}`, { title: 'Maths Foundations for Classes 6–8' })).status).toBe(409);
    expect((await admin.post('/courses', courseInput('', {}))).status).toBe(400);

    const instructors = (await admin.get('/instructors')).body.rows.map((r: { instructor: { id: string } }) => r.instructor.id);
    const max = settings.courses.maxInstructors as number;
    const tooMany = [...instructors, ...Array.from({ length: max + 1 }, () => instructors[0])].slice(0, max + 1);
    const limited = await admin.patch(`/courses/${created.body.id}`, { instructorIds: tooMany });
    expect(limited.status).toBe(409);
    expect(limited.body.message).toMatch(/at most/);
  });

  it('lets only an admin publish while review-before-publish is on', async () => {
    const original = (await admin.get('/settings')).body.settings.courses;
    await admin.put('/settings/courses', { ...original, requireReview: true });
    // A course whose checklist is met, so only the policy stands in the way.
    const mine = (await instructor.get('/courses', { status: 'published', pageSize: 50 })).body.rows[0];
    const blocked = await instructor.post(`/courses/${mine.id}/publish`);
    expect(blocked.status).toBe(403);
    await admin.put('/settings/courses', { ...original, requireReview: false });
    const allowed = await instructor.post(`/courses/${mine.id}/publish`);
    expect([200, 409]).toContain(allowed.status); // 409 = checklist not met, which is the course's business, not the policy's
    await admin.put('/settings/courses', original);
  });
});

describe('partial updates change only what they are sent', () => {
  it('keeps a course’s instructors, texts and tags when only its title is sent', async () => {
    const instructorId = (await admin.get('/catalog/instructors')).body[0].id as string;
    const created = await admin.post(
      '/courses',
      courseInput(`Partial ${unique()}`, { instructorIds: [instructorId], subtitle: 'A subtitle', description: 'A description', tags: ['kept'] }),
    );
    expect(created.status).toBe(201);

    const renamed = await admin.patch(`/courses/${created.body.id}`, { title: `Renamed ${unique()}` });
    expect(renamed.status).toBe(200);
    const after = (await admin.get(`/courses/${created.body.id}`)).body;
    expect(after.instructorIds).toEqual([instructorId]);
    expect(after.subtitle).toBe('A subtitle');
    expect(after.description).toBe('A description');
    expect(after.tags).toEqual(['kept']);
  });

  it('keeps a category’s levels when only its name is sent', async () => {
    const created = await admin.post('/categories', {
      name: `Partial ${unique()}`,
      description: 'Has a level',
      glyph: 'sun',
      status: 'active',
      levelIds: [levelId],
    });
    expect(created.status).toBe(201);
    expect((await admin.patch(`/categories/${created.body.id}`, { name: `Renamed ${unique()}` })).status).toBe(200);
    expect(await db.categoryLevel.count({ where: { categoryId: created.body.id } })).toBe(1);
  });
});

describe('courses: the minimum to save and to publish', () => {
  let instructorId: string;
  beforeAll(async () => {
    instructorId = (await admin.get('/catalog/instructors')).body[0].id as string;
  });

  it('saves a draft from a title alone, on the academy’s first level and first active category', async () => {
    const created = await admin.post('/courses', { title: `Title only ${unique()}` });
    expect(created.status).toBe(201);
    expect(created.body).toMatchObject({ status: 'draft', subtitle: '', description: '', outcomes: [], tags: [], instructorIds: [] });
    const levels = (await admin.get('/catalog/levels')).body as { id: string }[];
    const categories = (await admin.get('/catalog/categories')).body as { id: string; status: string }[];
    expect(created.body.levelId).toBe(levels[0].id);
    expect(created.body.categoryId).toBe(categories.find((c) => c.status === 'active')!.id);
  });

  it('refuses a draft with no usable title, saying why', async () => {
    const short = await admin.post('/courses', { title: 'Hi' });
    expect(short.status).toBe(400);
    expect(JSON.stringify(short.body)).toMatch(/at least 3 characters/);
    expect((await admin.post('/courses', { description: 'No title at all' })).status).toBe(400);
  });

  it('refuses to publish until the course has a description and an instructor, naming what is missing', async () => {
    const created = await admin.post('/courses', { title: `Not yet ${unique()}` });
    const refused = await admin.post(`/courses/${created.body.id}/publish`);
    expect(refused.status).toBe(409);
    const unmet = (refused.body.issues as { id: string; met: boolean }[]).filter((c) => !c.met).map((c) => c.id);
    expect(unmet).toEqual(['description', 'instructor']);
    expect((await admin.get(`/courses/${created.body.id}`)).body.status).toBe('draft');
  });

  it('publishes a course with only a title, a description and an instructor — no subtitle, outcomes, tags or lessons', async () => {
    const created = await admin.post('/courses', { title: `Bare course ${unique()}`, description: 'Fractions for Class 6.', instructorIds: [instructorId] });
    expect(created.status).toBe(201);
    const published = await admin.post(`/courses/${created.body.id}/publish`);
    expect(published.status).toBe(200);
    expect(published.body.status).toBe('published');
    expect(published.body.publishedAt).toBeTruthy();
    // Out of the way of the suites that read the published catalog.
    expect((await admin.post(`/courses/${created.body.id}/archive`)).status).toBe(200);
  });

  it('lets a draft be finished later: the missing parts are added by edit, then it publishes', async () => {
    const created = await admin.post('/courses', { title: `Finish later ${unique()}` });
    const edited = await admin.patch(`/courses/${created.body.id}`, { description: 'Written the next day.', instructorIds: [instructorId] });
    expect(edited.status).toBe(200);
    const after = (await admin.get(`/courses/${created.body.id}`)).body;
    expect(after).toMatchObject({
      title: created.body.title,
      description: 'Written the next day.',
      instructorIds: [instructorId],
      levelId: created.body.levelId,
    });
    expect((await admin.post(`/courses/${created.body.id}/publish`)).status).toBe(200);
    expect((await admin.post(`/courses/${created.body.id}/archive`)).status).toBe(200);
  });

  it('still refuses a publish to an account without the publish permission', async () => {
    const created = await admin.post('/courses', { title: `Gated ${unique()}`, description: 'Ready.', instructorIds: [instructorId] });
    expect((await anon().post(`/courses/${created.body.id}/publish`)).status).toBe(401);
    const learner = await as('student');
    expect((await learner.post(`/courses/${created.body.id}/publish`)).status).toBe(403);
    expect((await admin.get(`/courses/${created.body.id}`)).body.status).toBe('draft');
  });
});

describe('curriculum: chapters and lessons', () => {
  let courseId: string;
  let chapterId: string;

  beforeAll(async () => {
    const course = await admin.post('/courses', courseInput(`Curriculum ${unique()}`));
    courseId = course.body.id;
    const chapter = await admin.post(`/courses/${courseId}/chapters`, { input: { title: 'Chapter one', status: 'draft' } });
    expect(chapter.status).toBe(201);
    chapterId = chapter.body.id;
  });

  it('validates chapter bodies and keeps positions contiguous', async () => {
    expect((await admin.post(`/courses/${courseId}/chapters`, { input: { title: '' } })).status).toBe(400);
    const second = await admin.post(`/courses/${courseId}/chapters`, { input: { title: 'Chapter two' } });
    const third = await admin.post(`/courses/${courseId}/chapters`, { input: { title: 'Chapter three' }, position: 1 });
    expect(third.status).toBe(201);
    const moved = await admin.post(`/courses/${courseId}/chapters/${second.body.id}/move`, { position: 1 });
    const positions = (await db.chapter.findMany({ where: { courseId }, orderBy: { position: 'asc' } })).map((c) => c.position);
    expect(positions).toEqual([0, 1, 2]);
    expect(moved.body[0].id).toBe(second.body.id);
    expect((await admin.patch(`/courses/${courseId}/chapters/does-not-exist`, { title: 'Renamed' })).status).toBe(404);
  });

  it('applies lesson defaults, validates publishing and mirrors a linked quiz', async () => {
    const first = await admin.post(`/courses/${courseId}/lessons`, { chapterId, input: { title: 'Welcome', type: 'video' } });
    expect(first.status).toBe(201);
    const { general } = (await admin.get('/settings')).body.settings;
    expect(first.body.durationMin).toBe(general.lessonDefaults.durationMin);
    expect(!!first.body.isPreview).toBe(!!general.lessonDefaults.previewFirstLesson);

    const notReady = await admin.patch(`/courses/${courseId}/lessons/${first.body.id}`, { status: 'published' });
    expect(notReady.status).toBe(409);
    expect(notReady.body.issues.some((i: { field: string }) => i.field === 'lesson-media')).toBe(true);

    const assessment = await admin.post(`/courses/${courseId}/lessons`, { chapterId, input: { title: 'Chapter check', type: 'assessment', durationMin: 20 } });
    const quiz = await admin.post('/quizzes', {
      courseId,
      title: 'Chapter check quiz',
      instructions: '',
      status: 'draft',
      questions: [],
      settings: { passMark: 80, attempts: 3, shuffleQuestions: false, shuffleOptions: true, showResults: 'score-and-answers' },
      lessonId: assessment.body.id,
    });
    expect(quiz.status).toBe(201);
    expect(quiz.body.lessonId).toBe(assessment.body.id);

    const detail = await admin.get(`/courses/${courseId}/lessons/${assessment.body.id}`);
    expect(detail.body.lesson.content.quiz).toMatchObject({ quizId: quiz.body.id, questions: 0, passMark: 80, attempts: 3 });

    // a second quiz cannot claim the same lesson; a video lesson cannot deliver a quiz
    expect(
      (await admin.post('/quizzes', { courseId, title: 'Dup', instructions: '', status: 'draft', questions: [], settings: {}, lessonId: assessment.body.id }))
        .status,
    ).toBe(409);
    expect(
      (await admin.post('/quizzes', { courseId, title: 'Wrong', instructions: '', status: 'draft', questions: [], settings: {}, lessonId: first.body.id }))
        .status,
    ).toBe(409);
    // the delivered quiz cannot be deleted; changing the lesson's type releases it
    expect((await admin.delete(`/quizzes/${quiz.body.id}`)).status).toBe(409);
    await admin.patch(`/courses/${courseId}/lessons/${assessment.body.id}`, { type: 'reading' });
    expect((await db.quiz.findUnique({ where: { id: quiz.body.id } }))?.lessonId).toBeNull();
    expect((await admin.delete(`/quizzes/${quiz.body.id}`)).status).toBe(204);
  });

  it('links an assignment to a practice lesson and releases it when the lesson is deleted', async () => {
    const lesson = await admin.post(`/courses/${courseId}/lessons`, {
      chapterId,
      input: { title: 'Word problem practice', type: 'assignment', durationMin: 45 },
    });
    const assignment = await admin.post('/assignments', {
      courseId,
      title: 'Solve a word problem',
      instructions: 'Take one real word problem, form its equation and explain each step in three paragraphs.',
      attachments: [],
      format: 'text',
      due: { kind: 'relative', days: 5 },
      acceptsLate: true,
      latePenalty: 10,
      rubric: [],
      maxScore: 20,
      passMark: 12,
      status: 'draft',
      lessonId: lesson.body.id,
    });
    expect(assignment.status).toBe(201);
    const detail = await admin.get(`/courses/${courseId}/lessons/${lesson.body.id}`);
    expect(detail.body.lesson.content.assignment).toMatchObject({ assignmentId: assignment.body.id, dueAfterDays: 5, maxScore: 20, submission: 'text' });
    expect((await admin.delete(`/assignments/${assignment.body.id}`)).status).toBe(409);
    expect((await admin.delete(`/courses/${courseId}/lessons/${lesson.body.id}`)).status).toBe(204);
    const kept = await db.courseAssignment.findUnique({ where: { id: assignment.body.id } });
    expect(kept).not.toBeNull();
    expect(kept?.lessonId).toBeNull();
  });
});

describe('the public catalog', () => {
  it('lists public courses, serves an unlisted one by its link, and hides a private one', async () => {
    const make = async (visibility: string) => {
      const created = await admin.post('/courses', courseInput(`Visibility ${visibility} ${unique()}`, { visibility }));
      expect(created.status).toBe(201);
      await db.course.update({ where: { id: created.body.id }, data: { status: 'published', visibility } });
      return created.body;
    };
    const open = await make('public');
    const unlisted = await make('unlisted');
    const priv = await make('private');

    // The listing is the public shelf: only `public` courses stand on it.
    const listed = (await anon().get('/catalog/courses')).body.map((c: { id: string }) => c.id);
    expect(listed).toContain(open.id);
    expect(listed).not.toContain(unlisted.id);
    expect(listed).not.toContain(priv.id);

    // By link: public and unlisted open to anyone; private is not there at all.
    expect((await anon().get(`/catalog/courses/${open.slug}`)).status).toBe(200);
    expect((await anon().get(`/catalog/courses/${unlisted.slug}`)).status).toBe(200);
    expect((await anon().get(`/catalog/courses/${priv.slug}`)).status).toBe(404);
  });

  it('sends the outline to a visitor but keeps lesson bodies for enrolled learners', async () => {
    const res = await anon().get('/catalog/courses');
    expect(res.status).toBe(200);
    const withLessons = res.body.find((c: { chapters: { lessons: unknown[] }[] }) => c.chapters.some((ch) => ch.lessons.length));
    expect(withLessons).toBeDefined();
    const lessons = withLessons.chapters.flatMap((ch: { lessons: { isPreview?: boolean; content?: object }[] }) => ch.lessons);
    for (const l of lessons) {
      if (!l.isPreview) expect(l.content ?? {}).toEqual({});
    }
  });
});

describe('media uploads', () => {
  const png = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex');

  it('stores an allowed file and streams it back to signed-in users only', async () => {
    const res = await admin.upload('/media/upload').attach('file', png, { filename: 'cover.png', contentType: 'image/png' });
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ name: 'cover.png', url: `/media/${res.body.id}`, mime: 'image/png', kind: 'image' });
    expect(res.body.sizeMb).toBeGreaterThan(0);

    const stream = await admin.get(res.body.url);
    expect(stream.status).toBe(200);
    expect(stream.headers['content-type']).toBe('image/png');
    expect(stream.headers['content-disposition']).toContain('cover.png');
    expect(stream.headers['x-content-type-options']).toBe('nosniff');
    expect((await anon().get(res.body.url)).status).toBe(401);
    expect((await anon().upload('/media/upload').attach('file', png, { filename: 'x.png', contentType: 'image/png' })).status).toBe(401);
  });

  it('rejects disallowed types, mismatched extensions and oversized files', async () => {
    expect(
      (await admin.upload('/media/upload').attach('file', Buffer.from('MZ'), { filename: 'tool.exe', contentType: 'application/octet-stream' })).status,
    ).toBe(400);
    expect((await admin.upload('/media/upload').attach('file', png, { filename: 'notes.pdf', contentType: 'image/png' })).status).toBe(400);
    const big = Buffer.alloc(5 * 1024 * 1024 + 1, 1);
    expect((await admin.upload('/media/upload').attach('file', big, { filename: 'huge.png', contentType: 'image/png' })).status).toBe(413);
    expect((await admin.upload('/media/upload')).status).toBe(400);
    expect((await admin.get('/media/not-a-file')).status).toBe(404);
  });
});
