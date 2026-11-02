import { describe, expect, it } from 'vitest';

import { pooledUrl, retryOnDeadlock } from '../lib/db.js';
import { isWriteConflict } from '../lib/errors.js';
import { db } from '../test/db.js';
import { as, newStudent, unique } from '../test/helpers.js';

/* Many people at once. MySQL lets writers overlap, so these collisions can actually happen. */

describe('learners enrolling at the same moment', () => {
  it('all get in, and the course counts every one of them', async () => {
    const admin = await as('admin');
    const instructorId = (await admin.get('/catalog/instructors')).body[0].id as string;
    const course = await admin.post('/courses', {
      title: `Rush ${unique()}`,
      description: 'A popular course.',
      instructorIds: [instructorId],
      pricing: 'free',
    });
    expect((await admin.post(`/courses/${course.body.id}/publish`)).status).toBe(200);
    const learners = await Promise.all(Array.from({ length: 12 }, (_, i) => newStudent(`Rush ${i}`)));

    const answers = await Promise.all(learners.map((l) => l.post(`/learning/courses/${course.body.id}/enroll`)));

    expect(answers.map((a) => a.status)).toEqual(learners.map(() => 200));
    const row = await db.course.findUniqueOrThrow({ where: { id: course.body.id }, select: { enrolledCount: true } });
    expect(row.enrolledCount).toBe(12);
    expect(await db.enrollment.count({ where: { courseId: course.body.id } })).toBe(12);
  });
});

describe('a transaction MySQL ended as a deadlock victim', () => {
  const deadlock = () => Object.assign(new Error('Transaction failed due to a write conflict or a deadlock. Please retry your transaction'), { code: 'P2034' });

  it('is recognised, whether Prisma names it or only quotes the database', () => {
    expect(isWriteConflict(new Error('Code: `1213`. Deadlock found when trying to get lock'))).toBe(true);
    expect(isWriteConflict(new Error('Lock wait timeout exceeded'))).toBe(true);
    expect(isWriteConflict(new Error('That already exists'))).toBe(false);
  });

  it('runs again until it succeeds', async () => {
    let runs = 0;
    const answer = await retryOnDeadlock(async () => {
      runs++;
      if (runs < 3) throw new Error('Deadlock found when trying to get lock');
      return 'done';
    });
    expect(answer).toBe('done');
    expect(runs).toBe(3);
  });

  it('gives up in the end, and never repeats any other failure', async () => {
    let runs = 0;
    await expect(
      retryOnDeadlock(async () => {
        runs++;
        throw deadlock();
      }),
    ).rejects.toThrow(/deadlock/);
    expect(runs).toBe(5);
    runs = 0;
    await expect(
      retryOnDeadlock(async () => {
        runs++;
        throw new Error('A paid course purchase cannot be changed.');
      }),
    ).rejects.toThrow(/cannot be changed/);
    expect(runs).toBe(1);
  });
});

describe('the connection pool', () => {
  it('is sized on purpose, unless the address names its own limits', () => {
    expect(pooledUrl('mysql://u:p@127.0.0.1:3306/app')).toEqual({ url: 'mysql://u:p@127.0.0.1:3306/app?connection_limit=20&pool_timeout=20', connections: 20 });
    expect(pooledUrl('mysql://u:p@127.0.0.1:3306/app?connection_limit=8').connections).toBe(8);
    expect(pooledUrl(undefined).url).toBeUndefined();
  });
});
