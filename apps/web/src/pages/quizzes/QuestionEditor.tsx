import { ArrowDown, ArrowUp, Check, CheckSquare, Copy, ListChecks, Plus, RadioButton, TextAa, Trash, WarningCircle, X } from '@phosphor-icons/react';
import type { QuestionType, QuizIssue, QuizQuestion } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { ListInput, Switch } from '@/components/forms/Forms';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import styles from './Quizzes.module.css';

export const QUESTION_TYPES: { value: QuestionType; label: string; icon: JSX.Element }[] = [
  { value: 'single', label: 'Single choice', icon: <RadioButton size={16} /> },
  { value: 'multiple', label: 'Multiple choice', icon: <CheckSquare size={16} /> },
  { value: 'true-false', label: 'True / false', icon: <ListChecks size={16} /> },
  { value: 'short', label: 'Short answer', icon: <TextAa size={16} /> },
];

let serial = 0;
export const newId = (prefix: string) => `${prefix}-${Date.now().toString(36)}${(serial++).toString(36)}`;

export function blankQuestion(type: QuestionType): QuizQuestion {
  const id = newId('q');
  const options =
    type === 'true-false'
      ? [
          { id: `${id}-true`, text: 'True' },
          { id: `${id}-false`, text: 'False' },
        ]
      : type === 'short'
        ? []
        : [
            { id: `${id}-o1`, text: '' },
            { id: `${id}-o2`, text: '' },
            { id: `${id}-o3`, text: '' },
          ];
  return { id, type, prompt: '', options, correct: [], acceptedAnswers: type === 'short' ? [''] : [], points: 1, explanation: '', required: true };
}

/** Changes a question's type, keeping as much of what was written as the new type allows. */
export function convertQuestion(q: QuizQuestion, type: QuestionType): QuizQuestion {
  if (type === q.type) return q;
  const isTruth = (options: QuizQuestion['options']) => options.length === 2 && options.every((o) => /-(true|false)$/.test(o.id));
  if (type === 'true-false') {
    return {
      ...q,
      type,
      options: [
        { id: `${q.id}-true`, text: 'True' },
        { id: `${q.id}-false`, text: 'False' },
      ],
      correct: [],
    };
  }
  if (type === 'short') {
    // Choices stay on the question, unused, so switching back restores them.
    const fromChoices = isTruth(q.options) ? [] : q.options.filter((o) => q.correct.includes(o.id)).map((o) => o.text);
    const accepted = q.acceptedAnswers.filter(Boolean);
    return { ...q, type, acceptedAnswers: accepted.length ? accepted : fromChoices.length ? fromChoices : [''] };
  }
  // To single or multiple choice
  if (q.options.length >= 2 && !isTruth(q.options)) {
    return { ...q, type, correct: type === 'single' ? q.correct.slice(0, 1) : q.correct };
  }
  const seed = q.acceptedAnswers.filter(Boolean);
  const texts = [...seed, '', '', ''].slice(0, Math.max(3, seed.length));
  const options = texts.map((text, i) => ({ id: newId(`${q.id}-o${i + 1}`), text }));
  return { ...q, type, options, correct: seed.length ? [options[0].id] : [] };
}

interface QuestionEditorProps {
  question: QuizQuestion;
  number: number;
  count: number;
  issues: QuizIssue[];
  showIssues: boolean;
  onChange: (next: QuizQuestion) => void;
  onMove: (dir: -1 | 1) => void;
  onDuplicate: () => void;
  onDelete: () => void;
}

export function QuestionEditor({ question: q, number, count, issues, showIssues, onChange, onMove, onDuplicate, onDelete }: QuestionEditorProps) {
  const issueFor = (field: QuizIssue['field']) => (showIssues ? issues.find((i) => i.field === field)?.message : undefined);
  const set = (patch: Partial<QuizQuestion>) => onChange({ ...q, ...patch });
  // Points and negative marks share the validator's `points` field: each message goes beside the input it is about.
  const pointsIssues = showIssues ? issues.filter((i) => i.field === 'points') : [];
  const negativeIssue = pointsIssues.find((i) => /negative/i.test(i.message))?.message;
  const pointsIssue = pointsIssues.find((i) => !/negative/i.test(i.message))?.message;

  const toggleCorrect = (optionId: string) => {
    if (q.type === 'multiple') set({ correct: q.correct.includes(optionId) ? q.correct.filter((id) => id !== optionId) : [...q.correct, optionId] });
    else set({ correct: [optionId] });
  };

  return (
    <section className={styles.editor} aria-labelledby={`q-${q.id}-title`}>
      <div className={styles.editorHead}>
        <h2 id={`q-${q.id}-title`} className={styles.editorTitle}>
          Question {number}
          <span className={styles.editorCount}>of {count}</span>
        </h2>
        <div className={styles.editorActions}>
          <IconButton size="sm" label="Move question up" icon={<ArrowUp size={15} />} disabled={number === 1} onClick={() => onMove(-1)} />
          <IconButton size="sm" label="Move question down" icon={<ArrowDown size={15} />} disabled={number === count} onClick={() => onMove(1)} />
          <IconButton size="sm" label="Duplicate question" icon={<Copy size={15} />} onClick={onDuplicate} />
          <IconButton size="sm" label="Delete question" icon={<Trash size={15} />} onClick={onDelete} />
        </div>
      </div>

      <SegmentedControl<QuestionType>
        size="sm"
        label="Question type"
        value={q.type}
        onChange={(type) => onChange(convertQuestion(q, type))}
        segments={QUESTION_TYPES.map((t) => ({ value: t.value, label: t.label, icon: t.icon }))}
      />

      <Field label="Question" error={issueFor('prompt')}>
        <Textarea
          id={`q-${q.id}-prompt`}
          rows={3}
          value={q.prompt}
          onChange={(e) => set({ prompt: e.target.value })}
          placeholder="Which graha is exalted in Libra?"
        />
      </Field>

      {(q.type === 'single' || q.type === 'multiple') && (
        <fieldset className={styles.answers}>
          <legend className={styles.answersLegend}>
            Answers <span className={styles.answersHint}>{q.type === 'single' ? 'Mark the one correct answer' : 'Mark every correct answer'}</span>
          </legend>
          <ul className={styles.answerList}>
            {q.options.map((option, i) => {
              const correct = q.correct.includes(option.id);
              return (
                <li key={option.id} className={cx(styles.answer, correct && styles.answerCorrect)}>
                  <button
                    type="button"
                    className={cx(styles.correctToggle, q.type === 'multiple' && styles.correctSquare, correct && styles.correctOn)}
                    aria-pressed={correct}
                    aria-label={`${correct ? 'Correct' : 'Mark as correct'}: answer ${i + 1}`}
                    onClick={() => toggleCorrect(option.id)}
                  >
                    {correct && <Check size={12} weight="bold" />}
                  </button>
                  <Input
                    aria-label={`Answer ${i + 1}`}
                    value={option.text}
                    placeholder={`Answer ${i + 1}`}
                    onChange={(e) => set({ options: q.options.map((o) => (o.id === option.id ? { ...o, text: e.target.value } : o)) })}
                  />
                  <IconButton
                    size="sm"
                    label={`Remove answer ${i + 1}`}
                    icon={<X size={14} />}
                    disabled={q.options.length <= 2}
                    onClick={() => set({ options: q.options.filter((o) => o.id !== option.id), correct: q.correct.filter((id) => id !== option.id) })}
                  />
                </li>
              );
            })}
          </ul>
          <Button
            size="sm"
            variant="ghost"
            iconStart={<Plus size={14} />}
            disabled={q.options.length >= 8}
            onClick={() => set({ options: [...q.options, { id: newId(`${q.id}-o`), text: '' }] })}
          >
            Add answer
          </Button>
          {(issueFor('options') || issueFor('correct')) && (
            <p className={styles.issue}>
              <WarningCircle size={15} /> {issueFor('options') ?? issueFor('correct')}
            </p>
          )}
        </fieldset>
      )}

      {q.type === 'true-false' && (
        <fieldset className={styles.answers}>
          <legend className={styles.answersLegend}>The statement is</legend>
          <div className={styles.truthRow}>
            {q.options.map((option) => (
              <button
                key={option.id}
                type="button"
                className={cx(styles.truth, q.correct.includes(option.id) && styles.truthOn)}
                aria-pressed={q.correct.includes(option.id)}
                onClick={() => set({ correct: [option.id] })}
              >
                {q.correct.includes(option.id) && <Check size={14} weight="bold" />}
                {option.text}
              </button>
            ))}
          </div>
          {issueFor('correct') && (
            <p className={styles.issue}>
              <WarningCircle size={15} /> {issueFor('correct')}
            </p>
          )}
        </fieldset>
      )}

      {q.type === 'short' && (
        <ListInput
          label="Accepted answer"
          value={q.acceptedAnswers}
          onChange={(acceptedAnswers) => set({ acceptedAnswers })}
          addLabel="Add another accepted answer"
          numbered={false}
          max={6}
          placeholder="Shani"
          error={issueFor('answers')}
          hint="Matching ignores capital letters and extra spaces. Add spellings and Sanskrit names learners may use."
        />
      )}

      <div className={styles.pointsRow}>
        <Field label="Points" error={pointsIssue} className={styles.points}>
          <Input type="number" inputMode="numeric" min={1} max={100} value={q.points} onChange={(e) => set({ points: Number(e.target.value) })} />
        </Field>
        <Field label="Negative marks" optional hint="Taken away for a wrong answer, never for a blank one." error={negativeIssue} className={styles.points}>
          <Input
            id={`q-${q.id}-negative`}
            type="number"
            inputMode="decimal"
            min={0}
            max={q.points}
            step={0.25}
            value={q.negativePoints ?? ''}
            placeholder="0"
            onChange={(e) => {
              const text = e.target.value.trim();
              // Blank or 0 is no negative marking: the field is left off the question.
              const next: QuizQuestion = { ...q, negativePoints: Number(text) };
              if (text === '' || Number(text) === 0) delete next.negativePoints;
              onChange(next);
            }}
          />
        </Field>
        <Switch checked={q.required} onChange={(required) => set({ required })} label="Required" description="Learners must answer before submitting." />
      </div>

      <Field label="Explanation" optional hint="Shown after answering when results include answers. Explain why, not just what.">
        <Textarea
          rows={3}
          value={q.explanation ?? ''}
          onChange={(e) => set({ explanation: e.target.value })}
          placeholder="Shani is exalted in Libra, the sign of balance, and debilitated in Aries."
        />
      </Field>
    </section>
  );
}
