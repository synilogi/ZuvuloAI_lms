import type { Assignment, Rank, RankStanding } from '@syniastrolms/domain';

import type { LearnerAssignment, LearnerService } from '../contracts';
import { get } from './client';

function toLegacyAssignment(row: LearnerAssignment): Assignment {
  return {
    id: row.assignment.id,
    courseId: row.assignment.courseId,
    chapterId: row.assignment.chapterId ?? '',
    title: row.assignment.title,
    brief: row.assignment.instructions,
    dueAt: row.dueAt ?? new Date().toISOString(),
    state: row.state === 'graded' ? 'graded' : row.state === 'submitted' ? 'submitted' : 'not-started',
    submittedAt: row.submission?.submittedAt,
    grade:
      row.submission?.review.score != null
        ? { score: row.submission.review.score, max: row.assignment.maxScore, passMark: row.assignment.passMark }
        : undefined,
  };
}

export const httpLearner: LearnerService = {
  listAssignments: async () => (await get<LearnerAssignment[]>('/learning/assignments')).map(toLegacyAssignment),
  getRankLadder: () => get<{ ranks: Rank[]; standing: RankStanding }>('/learning/rank-ladder'),
};
