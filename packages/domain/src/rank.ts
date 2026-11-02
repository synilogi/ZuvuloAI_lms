import type { ID, ISODateTime } from './catalog';
import type { CertificateCriterion } from './certificate';
import { criteriaPercent } from './certificate';

/** A step in a learner's standing — e.g. Beginner → Intermediate → Advanced → Expert. */
export interface Rank {
  id: ID;
  title: string;
  order: number;
  /** What this standing means for the learner. */
  descriptor: string;
  /** Requirements to reach this rank from the one below. */
  criteria: CertificateCriterion[];
}

export interface RankStanding {
  rankId: ID;
  achieved: Record<ID, ISODateTime>;
  /** Live values toward the next rank, keyed by criterion id. */
  progress: Record<ID, number>;
}

export type RankStepState = 'achieved' | 'current' | 'next' | 'future';

export interface RankStep {
  rank: Rank;
  state: RankStepState;
  achievedAt?: ISODateTime;
  /** Only on the next rank: criteria with the learner's current values. */
  criteria?: CertificateCriterion[];
  percent?: number;
}

export function evaluateRankLadder(ranks: Rank[], standing: RankStanding): RankStep[] {
  const ordered = [...ranks].sort((a, b) => a.order - b.order);
  const currentIndex = Math.max(
    0,
    ordered.findIndex((r) => r.id === standing.rankId),
  );

  return ordered.map((rank, i): RankStep => {
    if (i < currentIndex) return { rank, state: 'achieved', achievedAt: standing.achieved[rank.id] };
    if (i === currentIndex) return { rank, state: 'current', achievedAt: standing.achieved[rank.id] };
    if (i === currentIndex + 1) {
      const criteria = rank.criteria.map((c) => ({ ...c, current: standing.progress[c.id] ?? 0 }));
      return { rank, state: 'next', criteria, percent: criteriaPercent(criteria) };
    }
    return { rank, state: 'future' };
  });
}
