import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';

import { Avatar, Badge, Card, Checklist, defineStatusMap, initials, KeyValueList, KpiTile, ProgressBar, ProgressRing, StatusBadge, Timeline } from './display';

const courseStatus = defineStatusMap({
  draft: { tone: 'neutral', label: 'Draft' },
  published: { tone: 'success', label: 'Published' },
  archived: { tone: 'warn', label: 'Archived' },
});

describe('StatusBadge', () => {
  it('renders a status through its domain map', () => {
    render(<StatusBadge status="published" map={courseStatus} />);
    expect(screen.getByText('Published')).toBeInTheDocument();
  });

  it('shows an unknown status as its raw value rather than crashing', () => {
    render(<StatusBadge status={'paused' as 'draft'} map={courseStatus} />);
    expect(screen.getByText('paused')).toBeInTheDocument();
  });
});

describe('display', () => {
  it('renders a badge and a card with a heading', () => {
    render(
      <Card title="Enrolment snapshot" description="Last 30 days" headingLevel={3}>
        <Badge tone="info">New</Badge>
      </Card>,
    );
    expect(screen.getByRole('heading', { level: 3, name: 'Enrolment snapshot' })).toBeInTheDocument();
    expect(screen.getByText('New')).toBeInTheDocument();
  });

  it('shows initials when there is no picture, named for assistive tech', () => {
    render(<Avatar name="Anaya Rao" />);
    expect(screen.getByRole('img', { name: 'Anaya Rao' })).toHaveTextContent('AR');
    expect(initials('  ')).toBe('?');
    expect(initials('Mira')).toBe('M');
  });

  it('clamps progress and exposes it as a progressbar', () => {
    render(
      <>
        <ProgressBar value={140} label="Course progress" showLabel />
        <ProgressRing value={-5} label="Chapter progress" />
      </>,
    );
    expect(screen.getByRole('progressbar', { name: 'Course progress' })).toHaveAttribute('aria-valuenow', '100');
    expect(screen.getByRole('progressbar', { name: 'Chapter progress' })).toHaveAttribute('aria-valuenow', '0');
  });

  it('states a KPI change in words, not only colour', () => {
    render(<KpiTile label="Overdue reviews" value="12" change={{ direction: 'up', label: '+4', upIsGood: false, context: 'vs last week' }} />);
    expect(screen.getByText('Up', { exact: false })).toBeInTheDocument();
    expect(screen.getByText(/\+4 vs last week/)).toBeInTheDocument();
  });

  it('lists key values, a timeline and a checklist with text statuses', () => {
    render(
      <>
        <KeyValueList
          items={[
            { label: 'Plan', value: 'Growth' },
            { label: 'Renewal', value: null },
          ]}
        />
        <Timeline label="History" items={[{ id: '1', title: 'Trial started', meta: '1 Sep 2026' }]} />
        <Checklist
          label="Publish checklist"
          items={[
            { id: 'a', label: 'At least 5 lessons', done: true },
            { id: 'b', label: 'Three learning outcomes', done: false },
          ]}
        />
      </>,
    );
    expect(screen.getByText('—')).toBeInTheDocument();
    expect(screen.getByRole('list', { name: 'History' })).toHaveTextContent('Trial started');
    expect(screen.getByRole('list', { name: 'Publish checklist' })).toHaveTextContent('Not done: Three learning outcomes');
  });
});
