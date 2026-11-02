import { describe, expect, it } from 'vitest';
import { reportInstructor } from './reportScope';

/* `useReportFilters` takes the instructor from this rule; the hook itself needs a browser, so the rule is tested alone. */
describe('reportInstructor', () => {
  const asked = new URLSearchParams('instructor=someone-else');

  it('is always the signed-in instructor in the teaching workspace, whatever the address says', () => {
    expect(reportInstructor(asked, { isTeaching: true, instructorId: 'me' })).toBe('me');
    expect(reportInstructor(asked, { isTeaching: true, instructorId: '' })).toBeUndefined();
  });

  it('is what an admin picked', () => {
    expect(reportInstructor(asked, { isTeaching: false })).toBe('someone-else');
    expect(reportInstructor(new URLSearchParams(), { isTeaching: false })).toBeUndefined();
  });
});
