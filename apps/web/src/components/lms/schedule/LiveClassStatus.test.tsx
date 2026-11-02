import { describe, expect, it } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import type { LiveClass } from '@syniastrolms/domain';
import { LiveClassStatus } from './LiveClassStatus';

/* The one action a live lesson offers is one that can work: no Join before the room is open, no false promises. */

const now = new Date('2026-11-02T13:00:00.000Z');
const at = (minutes: number) => new Date(now.getTime() + minutes * 60_000).toISOString();
const cls = (over: Partial<LiveClass> = {}): LiveClass => ({
  id: 'lc-1',
  courseId: 'c1',
  title: 'Ratios',
  instructorId: 'i1',
  startsAt: at(120),
  durationMin: 60,
  meeting: { kind: 'room' },
  ...over,
});
const render = (c: LiveClass, open = true) => renderToStaticMarkup(<LiveClassStatus liveClass={c} now={now} onOpen={open ? () => undefined : undefined} />);

describe('LiveClassStatus', () => {
  it('offers no Join while a built-in room waits for its host — the class page instead', () => {
    const html = render(cls({ startsAt: at(10) }));
    expect(html).not.toContain('Join class');
    expect(html).toContain('Waiting for the instructor to start');
    expect(html).toContain('See the class');
  });

  it('offers Join once the room is open, and for an outside meeting in its window', () => {
    expect(render(cls({ startsAt: at(-5), startedAt: at(-6) }))).toContain('Join now');
    expect(render(cls({ startsAt: at(10), meeting: { kind: 'external', linkHost: 'zoom.us' } }))).toContain('Join class');
  });

  it('offers a recording only once it is ready', () => {
    const ended = { startsAt: at(-180), endedAt: at(-120) };
    expect(render(cls({ ...ended, recording: { durationMin: 50, availableUntil: at(60_000), status: 'ready' } }))).toContain('Watch recording');
    const processing = render(cls({ ...ended, recording: { durationMin: 50, availableUntil: at(60_000), status: 'processing' } }));
    expect(processing).not.toContain('Watch recording');
    expect(processing).toContain('Recording being prepared');
  });

  it('tells a cancelled class’s reason, and promises no new date', () => {
    const html = render(cls({ cancelled: true, cancelReason: 'The instructor is unwell.' }));
    expect(html).toContain('The instructor is unwell.');
    expect(html).not.toContain('A new date will be announced');
  });
});
