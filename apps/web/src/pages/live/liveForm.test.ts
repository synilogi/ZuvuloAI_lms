import { describe, expect, it } from 'vitest';
import type { LiveClass } from '@syniastrolms/domain';
import { buildLivePayload, forValidation, istDateAfter, istIso, istWallClock, serverFieldIssues, toLiveForm } from './liveForm';

/*
 * The editor reads a class's start as an IST date and time and writes it back with `+05:30`. The API answers in UTC, so
 * slicing that string (as the editor once did) read 13:30 for a 19:00 class and saved it 5h30m early on every edit.
 */

const cls = (over: Partial<LiveClass> = {}): LiveClass => ({
  id: 'lc-1',
  courseId: 'c1',
  title: 'Ratios doubt-clearing',
  instructorId: 'i1',
  startsAt: '2026-11-02T13:30:00.000Z',
  durationMin: 60,
  capacity: 40,
  description: 'Bring your questions.',
  chapterId: 'ch1',
  visibility: 'enrolled',
  meeting: { kind: 'room' },
  agenda: [{ title: 'Warm-up', minutes: 10 }],
  reminders: [60],
  ...over,
});
const now = new Date('2026-10-26T06:00:00.000Z');
const opts = { now, courseId: 'c1', instructorId: 'i1' };

describe('IST date and time', () => {
  it('reads a UTC start as the IST wall clock and writes the same moment back', () => {
    expect(istWallClock('2026-11-02T13:30:00.000Z')).toEqual({ date: '2026-11-02', time: '19:00' });
    const saved = istIso('2026-11-02', '19:00');
    expect(saved).toBe('2026-11-02T19:00:00+05:30');
    expect(Date.parse(saved)).toBe(Date.parse('2026-11-02T13:30:00.000Z'));
  });

  it('puts a class before 05:30 IST on its IST date, not the UTC one', () => {
    // 04:00 IST on 3 November is still 2 November in UTC.
    expect(istWallClock('2026-11-02T22:30:00.000Z')).toEqual({ date: '2026-11-03', time: '04:00' });
    expect(Date.parse(istIso('2026-11-03', '04:00'))).toBe(Date.parse('2026-11-02T22:30:00.000Z'));
    // Midnight is 00:00, never 24:00.
    expect(istWallClock('2026-11-02T18:30:00.000Z')).toEqual({ date: '2026-11-03', time: '00:00' });
  });

  it('dates a new class tomorrow in IST', () => {
    // 23:00 IST on 26 October: tomorrow is the 27th in India, though UTC still says the 26th.
    expect(istDateAfter(new Date('2026-10-26T17:30:00.000Z'), 1)).toBe('2026-10-27');
    expect(istDateAfter(new Date('2026-10-26T18:30:00.000Z'), 1)).toBe('2026-10-28');
  });
});

describe('the edit round trip', () => {
  it('saves an untouched class at exactly the instant it was scheduled', () => {
    for (const startsAt of ['2026-11-02T13:30:00.000Z', '2026-11-02T22:30:00.000Z', '2026-11-02T00:15:00.000Z']) {
      const form = toLiveForm(cls({ startsAt }), opts);
      const payload = buildLivePayload(form, true);
      expect(Date.parse(payload.startsAt)).toBe(Date.parse(startsAt));
      expect(payload.startsAt).toMatch(/\+05:30$/);
      expect(payload.durationMin).toBe(60);
    }
  });

  it('changing only the title keeps the time', () => {
    const form = { ...toLiveForm(cls(), opts), title: 'Ratios: your questions' };
    const payload = buildLivePayload(form, true);
    expect(payload).toMatchObject({ title: 'Ratios: your questions', startsAt: '2026-11-02T19:00:00+05:30' });
  });

  it('keeps an edited class with no limit at no limit', () => {
    expect(toLiveForm(cls({ capacity: undefined }), opts).capacity).toBe('');
  });
});

describe('the body sent', () => {
  it('sends null for a capacity, description and chapter cleared on an edit', () => {
    const form = { ...toLiveForm(cls(), opts), capacity: '', description: '  ', chapterId: '' };
    const payload = buildLivePayload(form, true);
    expect(payload.capacity).toBeNull();
    expect(payload.description).toBeNull();
    expect(payload.chapterId).toBeNull();
    // Over the wire null is kept, which is what clears it; undefined would be dropped.
    expect(JSON.parse(JSON.stringify(payload))).toMatchObject({ capacity: null, description: null, chapterId: null });
    // The shared validator reads a cleared field as unset.
    expect(forValidation(payload)).toMatchObject({ capacity: undefined, description: undefined, chapterId: undefined });
  });

  it('leaves empty optional fields out of a new class', () => {
    const form = { ...toLiveForm(null, opts), title: 'New class', capacity: '', description: '', chapterId: '' };
    const payload = buildLivePayload(form, false);
    expect(payload.capacity).toBeUndefined();
    expect(payload.description).toBeUndefined();
    expect(payload.chapterId).toBeUndefined();
  });

  it('sends the values that are set', () => {
    const payload = buildLivePayload({ ...toLiveForm(cls(), opts), capacity: '25', meetingKind: 'external', link: ' https://zoom.us/j/1 ' }, true);
    expect(payload).toMatchObject({
      capacity: 25,
      description: 'Bring your questions.',
      chapterId: 'ch1',
      meeting: { kind: 'external', link: 'https://zoom.us/j/1' },
    });
  });
});

describe('a new class', () => {
  it('starts tomorrow at 19:00 IST for an hour', () => {
    expect(toLiveForm(null, opts)).toMatchObject({ date: '2026-10-27', start: '19:00', end: '20:00', capacity: '80', visibility: 'enrolled' });
  });

  it('copies a cancelled class, keeping its time of day but not its date, and drops "cohort"', () => {
    const template = cls({ cancelled: true, visibility: 'cohort', meeting: { kind: 'external', link: 'https://meet.google.com/abc' } });
    const form = toLiveForm(null, { ...opts, template });
    expect(form).toMatchObject({
      title: template.title,
      description: template.description,
      courseId: 'c1',
      instructorId: 'i1',
      date: '2026-10-27',
      start: '19:00',
      end: '20:00',
      meetingKind: 'external',
      link: 'https://meet.google.com/abc',
      visibility: 'enrolled',
    });
  });

  it('keeps "cohort" on a class that already has it', () => {
    expect(toLiveForm(cls({ visibility: 'cohort' }), opts).visibility).toBe('cohort');
  });
});

describe('server issues', () => {
  it('places the API’s issues beside their fields and drops the ones it can’t place', () => {
    const err = {
      issues: [
        { field: 'instructor', message: 'This instructor doesn’t teach the course.' },
        { field: 'startsAt', message: 'This class is already scheduled at this time.' },
        { field: 'somethingElse', message: 'Ignored.' },
      ],
    };
    expect(serverFieldIssues(err)).toEqual([
      { field: 'live-instructor', message: 'This instructor doesn’t teach the course.' },
      { field: 'live-date', message: 'This class is already scheduled at this time.' },
    ]);
    expect(serverFieldIssues(new Error('Network down'))).toEqual([]);
  });
});
