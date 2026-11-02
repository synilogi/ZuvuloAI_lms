import { Plus } from '@phosphor-icons/react';
import { ColumnChart, Sparkline, TrendChart } from '@/components/charts/Charts';
import { Delta, Figure, KpiStrip } from '@/components/data/KpiStrip';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { formatDay, formatShortDate } from '@/lib/format';
import { Column, Columns, DocSection, Notes, Specimen } from '../doc/Doc';

const WEEKS = ['22 Jun', '29 Jun', '6 Jul', '13 Jul', '20 Jul', '27 Jul', '3 Aug', '10 Aug', '17 Aug', '24 Aug', '31 Aug', '7 Sep'];
const ENROLLMENTS = [198, 198, 211, 206, 226, 197, 186, 206, 252, 205, 222, 232];
const ACTIVE = [512, 538, 441, 596, 672, 498, 553, 571, 540, 468, 624, 655, 571, 566, 578, 470, 700, 745, 556, 559, 660, 628, 519, 723, 755, 628, 490];

/** Page and section headings, headline figures and charts — the vocabulary of management screens. */
export function FiguresSection() {
  return (
    <DocSection
      id="figures"
      index={8}
      title="Headers, figures and charts"
      lead="Management screens open with the shell’s page header, summarise with a typographic figure band instead of stat cards, and chart one measure at a time in one hue. Every change says its direction with an arrow and a sign; every chart can be read with the keyboard and has a table behind it."
      api={['PageHeader', 'SectionHeader', 'KpiStrip', 'Delta', 'Figure', 'TrendChart', 'ColumnChart', 'Sparkline']}
    >
      <Specimen label="Page header" surface="panel">
        <PageHeader
          eyebrow="Tuesday, 15 September"
          title="Courses"
          count="16 courses"
          description="Draft, publish and retire courses. Learners only see what is published."
          actions={
            <Button variant="primary" iconStart={<Plus size={16} />}>
              Add course
            </Button>
          }
        />
      </Specimen>

      <Specimen
        label="Figure band"
        notes={
          <Notes
            items={[
              { term: 'Counts', text: 'Change in percent. Small counts (courses, instructors) show the raw difference instead.' },
              { term: 'Rates', text: 'Change in points — 64% → 65% reads +1 pt, never +1.6%.' },
              { term: 'Direction', text: 'Arrow and sign carry direction; tone only says whether it is good news, and can be neutral.' },
            ]}
          />
        }
      >
        <KpiStrip
          label="Example figures"
          items={[
            {
              id: 'c',
              label: 'Active courses',
              value: '11',
              kpi: { value: 11, previous: 10, series: [9, 10, 10, 10, 11, 11, 10, 11] },
              absolute: true,
              period: 'vs last month',
            },
            {
              id: 's',
              label: 'Total students',
              value: '3,412',
              kpi: { value: 3412, previous: 3113, series: [1706, 1932, 2135, 2380, 2628, 2864, 3113, 3412] },
              period: 'vs last month',
            },
            {
              id: 'r',
              label: 'Reviews waiting',
              value: '14',
              kpi: { value: 14, previous: 9, series: [6, 8, 11, 7, 9, 12, 9, 14] },
              good: 'down',
              absolute: true,
              period: 'vs last week',
            },
            {
              id: 'p',
              label: 'Completion rate',
              value: '65%',
              kpi: { value: 65.3, previous: 65, series: [63, 63, 64, 65, 65, 65, 65, 65.3], unit: '%' },
              period: 'vs last month',
            },
          ]}
        />
      </Specimen>

      <Columns>
        <Column title="Section header" caption="Title, one-line description and actions on a hairline — no container.">
          <SectionHeader title="Course performance" description="Across published courses, week by week" actions={<Button size="sm">Export</Button>} />
        </Column>
        <Column title="Figure and delta" caption="Inline summaries above a chart.">
          <Figure value="911" label="new enrollments in the last four weeks">
            <Delta kpi={{ value: 911, previous: 815 }} period="vs the four weeks before" />
            <Sparkline values={ENROLLMENTS} />
          </Figure>
        </Column>
      </Columns>

      <Columns>
        <Column title="Trend" caption="Line and soft area for a measure over time. Hover or use ← → to read a week.">
          <TrendChart
            data={ENROLLMENTS.map((value, i) => ({ label: WEEKS[i], detail: `Week of ${WEEKS[i]}`, value }))}
            label="Weekly new enrollments"
            unit="enrollments"
            height={200}
          />
        </Column>
        <Column title="Columns" caption="Discrete days or categories. A still-accruing period is hatched and says so.">
          <ColumnChart
            data={ACTIVE.map((value, i) => {
              const day = new Date(Date.UTC(2026, 7, 20 + i, 6)).toISOString();
              return { label: formatShortDate(day), detail: formatDay(day), value };
            })}
            label="Daily active learners"
            unit="active learners"
            height={200}
            partialIndex={ACTIVE.length - 1}
            partialNote="Today so far"
          />
        </Column>
      </Columns>
    </DocSection>
  );
}
