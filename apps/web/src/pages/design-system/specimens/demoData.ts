import type { JourneyStep } from '@/components/lms/journey/LearningJourney';
import { courseProgress, chapterProgress } from '@syniastrolms/domain';
import { formatDuration } from '@/lib/format';
import { foundationsCourse } from '@/services/mock/fixtures/catalog';
import { foundationsProgress } from '@/services/mock/fixtures/learner';

/** Demo context shared by the design system chapters and composition specimens. */
export const RESUME = {
  courseTitle: foundationsCourse.title,
  chapterLabel: 'Chapter 3 · Understanding the Twelve Houses',
  lessonTitle: 'Home and mother: the fourth house',
  positionSec: 561,
  durationSec: 17 * 60,
  coursePercent: courseProgress(foundationsCourse, foundationsProgress).percent,
};

export function chapterJourney(): JourneyStep[] {
  return foundationsCourse.chapters.map((m, i) => {
    const p = chapterProgress(m, foundationsProgress);
    return {
      id: m.id,
      title: m.title,
      state: p.state,
      percent: p.percent,
      meta:
        p.state === 'completed'
          ? `${p.total} lessons · done`
          : p.state === 'in-progress'
            ? `${p.completed} of ${p.total} lessons`
            : `${p.total} lessons · ${formatDuration(p.remainingMin)}`,
      lockedReason: `After ${foundationsCourse.chapters[i - 1]?.title ?? ''}`,
    };
  });
}
