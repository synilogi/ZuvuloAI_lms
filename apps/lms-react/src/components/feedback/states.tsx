import { ArrowClockwise, LockSimple, MagnifyingGlass, Question, WarningCircle } from '@phosphor-icons/react';
import type { ReactNode } from 'react';

import { Button } from '@/components/ui/Button';
import { cx } from '@/lib/cx';

import styles from './Feedback.module.css';

export interface StateProps {
  title: ReactNode;
  children?: ReactNode;
  icon?: ReactNode;
  /** Buttons/links under the text. */
  actions?: ReactNode;
  /** Smaller padding, for a card or panel rather than a page. */
  compact?: boolean;
  /** Heading level of the title (defaults to h2). */
  headingLevel?: 2 | 3;
  danger?: boolean;
}

function State({ title, children, icon, actions, compact, headingLevel = 2, danger }: StateProps) {
  const Heading = `h${headingLevel}` as const;
  return (
    <div className={cx(styles.state, compact && styles.stateCompact)}>
      {icon && (
        <span className={cx(styles.stateIcon, danger && styles.stateIconDanger)} aria-hidden="true">
          {icon}
        </span>
      )}
      <Heading className={styles.stateTitle}>{title}</Heading>
      {children && <div className={styles.stateText}>{children}</div>}
      {actions && <div className={styles.stateActions}>{actions}</div>}
    </div>
  );
}

/** Nothing exists yet. Explain the purpose and offer the first action when the viewer may take it. */
export function EmptyState(props: StateProps) {
  return <State icon={<MagnifyingGlass size={24} />} {...props} />;
}

export interface FilteredEmptyStateProps {
  /** What was searched for / filtered, e.g. `"moon" in Draft`. */
  query?: ReactNode;
  onClear: () => void;
  compact?: boolean;
}

/** Records exist but none match the search or filters. */
export function FilteredEmptyState({ query, onClear, compact }: FilteredEmptyStateProps) {
  return (
    <State
      icon={<MagnifyingGlass size={24} />}
      title={query ? <>No results for {query}</> : 'No results match these filters'}
      compact={compact}
      actions={<Button onClick={onClear}>Clear filters</Button>}
    >
      Try a different search term or remove a filter.
    </State>
  );
}

export interface ErrorStateProps {
  /** A human sentence — never a status code, stack or raw server text alone. */
  message?: ReactNode;
  title?: ReactNode;
  onRetry?: () => void;
  retrying?: boolean;
  compact?: boolean;
}

export function ErrorState({
  title = 'Something went wrong',
  message = 'We could not load this. Check your connection and try again.',
  onRetry,
  retrying,
  compact,
}: ErrorStateProps) {
  return (
    <div role="alert">
      <State
        danger
        icon={<WarningCircle size={24} />}
        title={title}
        compact={compact}
        actions={
          onRetry && (
            <Button icon={<ArrowClockwise size={16} />} onClick={onRetry} loading={retrying}>
              Try again
            </Button>
          )
        }
      >
        {message}
      </State>
    </div>
  );
}

export function NotFoundState({ title = 'We could not find that', children, actions }: Partial<StateProps>) {
  return (
    <State icon={<Question size={24} />} title={title} actions={actions}>
      {children ?? 'It may have been removed, or the link may be wrong.'}
    </State>
  );
}

export interface ForbiddenStateProps {
  /** The missing permission's catalogue label ("View reports"). */
  permissionLabel?: string;
  children?: ReactNode;
  actions?: ReactNode;
}

export function ForbiddenState({ permissionLabel, children, actions }: ForbiddenStateProps) {
  return (
    <State icon={<LockSimple size={24} />} title="You don’t have access to this" actions={actions}>
      {children ??
        (permissionLabel ? (
          <>
            This needs the <strong>{permissionLabel}</strong> permission. Ask an academy owner to grant it.
          </>
        ) : (
          'Your account cannot open this page.'
        ))}
    </State>
  );
}
