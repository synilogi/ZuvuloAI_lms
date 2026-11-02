import { describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { MemoryRouter } from 'react-router-dom';
import type { AsyncState } from '@/hooks/useAsync';
import type { CourseLinkDetails } from '@/services/contracts';
import { ServiceError } from '@/services/contracts';
import { enrolFailure } from './joinFailure';

vi.hoisted(() => {
  (globalThis as { window?: unknown }).window ??= { location: { search: '', origin: 'http://localhost' } };
});

const { CourseEnrollView, signInReturningTo } = await import('./CourseEnrollPage');
type Viewer = Parameters<typeof CourseEnrollView>[0]['viewer'];

/* A course enrolment link (`/courses/<id>/enroll`) as a visitor, a learner and a staff account see it. */

const details: CourseLinkDetails = {
  lms: { name: 'Jyotish Vidya Peetham', slug: 'jyotish-vidya' },
  course: { id: 'course-1234', title: 'Foundations of Vedic Astrology', slug: 'foundations' },
  open: true,
};
const view = (viewer: Viewer, load: AsyncState<CourseLinkDetails> = { status: 'success', data: details }) =>
  renderToStaticMarkup(
    <MemoryRouter>
      <CourseEnrollView load={load} courseId="course-1234" viewer={viewer} onEnrol={async () => undefined} onJoined={() => undefined} retry={() => undefined} />
    </MemoryRouter>,
  );

describe('a course enrolment link', () => {
  it('asks a visitor to create an account, or sign in and come back', () => {
    const html = view({ kind: 'signed-out' });
    expect(html).toMatch(/<h1[^>]*>Foundations of Vedic Astrology<\/h1>/);
    expect(html).toContain('on Jyotish Vidya Peetham');
    expect(html).toContain('Create account and enrol');
    expect(html).toContain(`href="${signInReturningTo('course-1234')}"`);
    expect(signInReturningTo('course-1234')).toBe('/login?next=%2Fcourses%2Fcourse-1234%2Fenroll');
    expect(html).not.toMatch(/academy/i);
  });

  it('offers a signed-in learner one button to enrol', () => {
    const html = view({ kind: 'signed-in', name: 'Ananya Rao', role: 'student' });
    expect(html).toContain('You’re signed in as Ananya Rao.');
    expect(html).toMatch(/<button[^>]*>.*Enrol<\/button>|>Enrol</);
    expect(html).not.toContain('Full name');
  });

  it('tells a staff account the link is for learners', () => {
    const html = view({ kind: 'signed-in', name: 'Kavita Menon', role: 'admin' });
    expect(html).toContain('Course links are for learners');
    expect(html).toContain('href="/admin"');
    expect(html).not.toContain('>Enrol<');
  });

  it('says when the course isn’t found, and when the LMS takes nobody new', () => {
    expect(view({ kind: 'signed-out' }, { status: 'error', error: new ServiceError('Course not found.', 'not-found') })).toContain(
      'We couldn’t find that course',
    );
    const closed = view({ kind: 'signed-out' }, { status: 'success', data: { ...details, open: false } });
    expect(closed).toContain('Jyotish Vidya Peetham isn’t taking new learners right now');
    expect(closed).not.toContain('Create account and enrol');
  });

  it('a learner of another LMS is told they can’t join; a policy refusal is the LMS’s own words', () => {
    expect(enrolFailure(new ServiceError('Course not found.', 'not-found'))).toBe('This course isn’t open to your account.');
    expect(enrolFailure(new ServiceError('Enrolment in this LMS needs approval.', 'conflict'))).toBe('Enrolment in this LMS needs approval.');
  });
});
