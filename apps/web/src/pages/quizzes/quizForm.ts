import type { QuizInput, QuizIssue, QuizSettings, QuizStatus } from '@syniastrolms/domain';
import { validateQuiz } from '@syniastrolms/domain';
import { istIso, istWallClock } from '@/pages/live/liveForm';

/*
 * The quiz builder's rules, kept apart from the page so they can be tested: the availability window typed as dates and
 * times in the academy's zone (IST) and sent as moments with their offset — as live classes are — and the checks the
 * server makes before publishing (`validateQuiz`), with a half-typed window caught first.
 */

/** The window as the builder's inputs hold it: IST dates (`YYYY-MM-DD`) and times (`HH:MM`), blank when unset. */
export interface QuizWindowDraft {
  opensDate: string;
  opensTime: string;
  closesDate: string;
  closesTime: string;
}

/** A quiz's window as the inputs show it, read in IST whatever zone the server stored it in. */
export function windowDraft(settings: Pick<QuizSettings, 'opensAt' | 'closesAt'>): QuizWindowDraft {
  const opens = settings.opensAt ? istWallClock(settings.opensAt) : null;
  const closes = settings.closesAt ? istWallClock(settings.closesAt) : null;
  return { opensDate: opens?.date ?? '', opensTime: opens?.time ?? '', closesDate: closes?.date ?? '', closesTime: closes?.time ?? '' };
}

/** One edge of the window as the moment the API takes, or `undefined` while it is blank or half typed. */
const momentOf = (date: string, time: string) => (date && time ? istIso(date, time) : undefined);

/** Whether two ISO moments are the same instant, however each is written. */
const sameMoment = (a?: string, b?: string) => (a && b ? Date.parse(a) === Date.parse(b) : a === b);

/**
 * The settings with the window the inputs hold. A moment that did not change keeps the server's own spelling, so an
 * untouched window never reads as an unsaved change. Leaving both inputs of an edge blank removes it.
 */
export function applyWindow(settings: QuizSettings, draft: QuizWindowDraft): QuizSettings {
  const next: QuizSettings = { ...settings };
  const opensAt = momentOf(draft.opensDate, draft.opensTime);
  const closesAt = momentOf(draft.closesDate, draft.closesTime);
  if (opensAt) next.opensAt = sameMoment(opensAt, settings.opensAt) ? settings.opensAt : opensAt;
  else delete next.opensAt;
  if (closesAt) next.closesAt = sameMoment(closesAt, settings.closesAt) ? settings.closesAt : closesAt;
  else delete next.closesAt;
  return next;
}

/** A window edge with a date but no time, or a time but no date: it would be dropped, so it is stopped first. */
export function windowIssues(draft: QuizWindowDraft): QuizIssue[] {
  const half = (date: string, time: string) => Boolean(date) !== Boolean(time);
  const out: QuizIssue[] = [];
  if (half(draft.opensDate, draft.opensTime)) out.push({ field: 'settings', message: 'Give the opening time both a date and a time, or clear both.' });
  if (half(draft.closesDate, draft.closesTime)) out.push({ field: 'settings', message: 'Give the closing time both a date and a time, or clear both.' });
  return out;
}

/** Everything that stops a save: a half-typed window always, and the server's publishing checks when it will be live. */
export function builderIssues(input: Pick<QuizInput, 'title' | 'questions' | 'settings' | 'status'>, draft: QuizWindowDraft): QuizIssue[] {
  return [...windowIssues(draft), ...validateQuiz(input)];
}

/** Whether a quiz in this status must pass the publishing checks to be saved. Archived quizzes were published. */
export const checkedOnSave = (status: QuizStatus) => status === 'published';

/** The status labels the builder and the list show. */
export const STATUS_LABEL: Record<QuizStatus, string> = { draft: 'Draft', published: 'Published', archived: 'Archived' };

/** A learner's attempt as staff read it. */
export const ATTEMPT_STATUS_LABEL = { active: 'In progress', submitted: 'Submitted', expired: 'Time up' } as const;

/** The time an attempt took, "12 min 05 s" — or under a minute in seconds. */
export function formatTaken(sec?: number) {
  if (sec === undefined) return '—';
  if (sec < 60) return `${sec} s`;
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return s ? `${m} min ${String(s).padStart(2, '0')} s` : `${m} min`;
}
