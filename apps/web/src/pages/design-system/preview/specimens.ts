import type { Role } from '@syniastrolms/domain';

export type SpecimenId = 'course-overview' | 'lesson-canvas' | 'learner-management' | 'standing';

export const SPECIMENS: Record<SpecimenId, { label: string; description: string; role?: Role }> = {
  'course-overview': {
    label: 'Course overview',
    description:
      'Editorial split: identity, journey and curriculum on the page; progress and Continue in an elevated aside that becomes a sticky bottom bar on phones.',
    role: 'student',
  },
  'lesson-canvas': {
    label: 'Lesson canvas',
    description:
      'Immersive density on a focused reading canvas. The curriculum is an inline side panel at ≥1280px, a drawer on tablets and a bottom sheet on phones.',
    role: 'student',
  },
  'learner-management': {
    label: 'Learner table',
    description: 'Dense admin composition at the wide container: bulk selection, filters and sorting. Rows become structured list items on phones.',
    role: 'admin',
  },
  standing: {
    label: 'Rank & activity',
    description: 'Rank orbits beside the ladder on wide screens; emblem, current rank and requirements stacked on phones.',
    role: 'student',
  },
};
