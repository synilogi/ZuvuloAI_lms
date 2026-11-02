import type { ID, ISODateTime } from './catalog';
import type { LiveClass } from './live-class';

/** A headline number with enough history to say which way it is moving. */
export interface Kpi {
  value: number;
  /** Same measure one period earlier. */
  previous: number;
  /** Oldest → newest, for a sparkline. */
  series: number[];
  unit?: '%' | 'count';
}

export interface TrendPoint {
  /** Period start, YYYY-MM-DD. */
  date: string;
  value: number;
}

export type TrendDirection = 'up' | 'down' | 'flat';

export interface KpiChange {
  direction: TrendDirection;
  /** Percent change for counts, percentage points for rates. */
  amount: number;
  unit: '%' | 'pts';
}

/** Change from previous to current. Rates compare in points so 60% → 63% reads +3 pts, not +5%. */
export function kpiChange(kpi: Pick<Kpi, 'value' | 'previous' | 'unit'>): KpiChange {
  if (kpi.unit === '%') {
    const amount = Math.round((kpi.value - kpi.previous) * 10) / 10;
    return { direction: amount > 0 ? 'up' : amount < 0 ? 'down' : 'flat', amount: Math.abs(amount), unit: 'pts' };
  }
  if (kpi.previous === 0) return { direction: kpi.value > 0 ? 'up' : 'flat', amount: kpi.value > 0 ? 100 : 0, unit: '%' };
  const pct = Math.round(((kpi.value - kpi.previous) / kpi.previous) * 1000) / 10;
  return { direction: pct > 0 ? 'up' : pct < 0 ? 'down' : 'flat', amount: Math.abs(pct), unit: '%' };
}

export interface CoursePerformance {
  courseId: ID;
  enrolled: number;
  /** Learners who opened the course in the last 14 days. */
  active: number;
  completionRate: number;
  avgProgress: number;
  rating?: number;
  /** Weekly new enrollments, oldest → newest. */
  weeklyEnrollments: number[];
}

export interface ActivityDay {
  /** YYYY-MM-DD */
  date: string;
  activeLearners: number;
  lessonsCompleted: number;
}

export type AttentionKind = 'reviews' | 'at-risk' | 'stale-draft' | 'capacity' | 'accessibility';

export interface AttentionItem {
  id: ID;
  kind: AttentionKind;
  title: string;
  detail: string;
  count?: number;
  severity: 'high' | 'medium' | 'low';
  /** Route that resolves the item. */
  to: string;
}

export type AdminEventKind = 'enrollment' | 'course-published' | 'course-updated' | 'submission' | 'certificate' | 'instructor' | 'review' | 'live-scheduled';

export interface AdminEvent {
  id: ID;
  kind: AdminEventKind;
  actor: string;
  /** Completes the sentence after the actor: "published Class 10 Mathematics". */
  summary: string;
  context?: string;
  courseId?: ID;
  at: ISODateTime;
  to?: string;
}

export type DashboardScope = { kind: 'academy' } | { kind: 'instructor'; instructorId: ID };

export interface DashboardSnapshot {
  scope: DashboardScope;
  generatedAt: ISODateTime;
  kpis: {
    courses: Kpi;
    students: Kpi;
    /** Academy: active instructors. Instructor: submissions waiting for review. */
    third: Kpi;
    completionRate: Kpi;
  };
  /** Weekly new enrollments and completions, 12 weeks, oldest → newest. */
  enrollments: TrendPoint[];
  completions: TrendPoint[];
  courses: CoursePerformance[];
  /** Daily learning activity, 28 days, oldest → newest. */
  activity: ActivityDay[];
  engagement: { lessonsCompleted: Kpi; quizAttempts: Kpi; submissions: Kpi; liveAttendance: Kpi };
  upcomingLive: LiveClass[];
  attention: AttentionItem[];
  events: AdminEvent[];
}
