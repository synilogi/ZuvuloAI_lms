import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useState } from 'react';
import { describe, expect, it, vi } from 'vitest';

import { Combobox, type ComboboxOption } from './Combobox';
import { ErrorSummary } from './ErrorSummary';
import { Field } from './Field';
import { FileDrop } from './FileDrop';
import { Checkbox, DateRangeInput, NumberInput, RadioGroup, Select, Switch, Textarea, TextInput, type DateRange } from './inputs';
import { TagInput } from './TagInput';

describe('Field', () => {
  it('labels the control and links hint and error to it', () => {
    render(
      <Field label="Course title" hint="Shown to learners" error="Enter a title." required>
        <TextInput />
      </Field>,
    );
    const input = screen.getByRole('textbox', { name: /Course title/ });
    expect(input).toBeRequired();
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(input).toHaveAccessibleDescription('Shown to learners Enter a title.');
  });

  it('is valid without an error', () => {
    render(
      <Field label="Subtitle">
        <TextInput />
      </Field>,
    );
    expect(screen.getByRole('textbox', { name: 'Subtitle' })).not.toHaveAttribute('aria-invalid');
  });
});

describe('inputs', () => {
  it('types into text and number inputs', async () => {
    render(
      <>
        <Field label="Name">
          <TextInput />
        </Field>
        <Field label="Capacity">
          <NumberInput />
        </Field>
      </>,
    );
    await userEvent.type(screen.getByRole('textbox', { name: 'Name' }), 'Mira');
    await userEvent.type(screen.getByRole('spinbutton', { name: 'Capacity' }), '40');
    expect(screen.getByRole('textbox', { name: 'Name' })).toHaveValue('Mira');
    expect(screen.getByRole('spinbutton', { name: 'Capacity' })).toHaveValue(40);
  });

  it('counts characters in a textarea and flags going over a soft limit', async () => {
    render(
      <Field label="Description">
        <Textarea showCounter counterMax={5} />
      </Field>,
    );
    await userEvent.type(screen.getByRole('textbox', { name: 'Description' }), 'Saturn');
    expect(screen.getByText('6 / 5')).toBeInTheDocument();
  });

  it('offers a placeholder and options in a select', async () => {
    render(
      <Field label="Category">
        <Select placeholder="Choose a category" options={[{ value: 'vedic', label: 'Vedic astrology' }]} />
      </Field>,
    );
    const select = screen.getByRole('combobox', { name: 'Category' });
    await userEvent.selectOptions(select, 'vedic');
    expect(select).toHaveValue('vedic');
  });

  it('toggles a checkbox and a switch with the keyboard', async () => {
    render(
      <>
        <Checkbox label="Free preview" />
        <Switch label="Auto-issue certificates" description="Issue as soon as a learner completes" />
      </>,
    );
    const checkbox = screen.getByRole('checkbox', { name: 'Free preview' });
    checkbox.focus();
    await userEvent.keyboard(' ');
    expect(checkbox).toBeChecked();
    const toggle = screen.getByRole('switch', { name: /Auto-issue certificates/ });
    toggle.focus();
    await userEvent.keyboard(' ');
    expect(toggle).toBeChecked();
  });

  it('reports the chosen radio option', async () => {
    const onChange = vi.fn();
    render(
      <RadioGroup
        legend="Late policy"
        name="late"
        value="accept"
        onChange={onChange}
        options={[
          { value: 'accept', label: 'Accept' },
          { value: 'penalty', label: 'Penalty' },
        ]}
      />,
    );
    expect(screen.getByRole('group', { name: 'Late policy' })).toBeInTheDocument();
    await userEvent.click(screen.getByRole('radio', { name: 'Penalty' }));
    expect(onChange).toHaveBeenCalledWith('penalty');
  });

  it('keeps a date range ordered', async () => {
    function Harness() {
      const [range, setRange] = useState<DateRange>({ from: '2026-09-01', to: '' });
      return <DateRangeInput legend="Renewal date" value={range} onChange={setRange} />;
    }
    render(<Harness />);
    const to = screen.getByLabelText('To');
    expect(to).toHaveAttribute('min', '2026-09-01');
  });
});

describe('ErrorSummary', () => {
  it('announces problems and moves focus to the field', async () => {
    render(
      <>
        <ErrorSummary errors={[{ fieldId: 'title', message: 'Enter a course title.' }, { message: 'The server refused the change.' }]} />
        <input id="title" aria-label="Title" />
      </>,
    );
    expect(screen.getByRole('alert')).toHaveAccessibleName('There is a problem');
    await userEvent.click(screen.getByRole('link', { name: 'Enter a course title.' }));
    expect(screen.getByRole('textbox', { name: 'Title' })).toHaveFocus();
    expect(screen.getByText('The server refused the change.')).toBeInTheDocument();
  });

  it('renders nothing without errors', () => {
    const { container } = render(<ErrorSummary errors={[]} />);
    expect(container).toBeEmptyDOMElement();
  });
});

describe('TagInput', () => {
  function Harness() {
    const [tags, setTags] = useState<string[]>(['nakshatra']);
    return (
      <Field label="Tags">
        <TagInput value={tags} onChange={setTags} />
      </Field>
    );
  }

  it('adds with Enter or comma, skips duplicates and removes with Backspace', async () => {
    render(<Harness />);
    const input = screen.getByRole('textbox', { name: 'Tags' });
    await userEvent.type(input, 'dasha{Enter}transits,Dasha{Enter}');
    expect(screen.getByText('dasha')).toBeInTheDocument();
    expect(screen.getByText('transits')).toBeInTheDocument();
    expect(screen.getAllByRole('button', { name: /Remove/ })).toHaveLength(3);
    await userEvent.keyboard('{Backspace}');
    expect(screen.queryByText('transits')).not.toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Remove nakshatra' }));
    expect(screen.queryByText('nakshatra')).not.toBeInTheDocument();
  });
});

describe('FileDrop', () => {
  it('passes accepted files and refuses the wrong type or size before upload', async () => {
    const onFiles = vi.fn();
    const onReject = vi.fn();
    const { container } = render(<FileDrop onFiles={onFiles} onReject={onReject} accept=".pdf,image/*" maxBytes={1024} />);
    const input = container.querySelector('input[type="file"]') as HTMLInputElement;
    await userEvent.upload(input, new File(['x'], 'brief.pdf', { type: 'application/pdf' }));
    expect(onFiles).toHaveBeenCalledWith([expect.objectContaining({ name: 'brief.pdf' })]);
    await userEvent.upload(input, new File([new Uint8Array(2048)], 'chart.png', { type: 'image/png' }));
    expect(onReject).toHaveBeenCalledWith('chart.png is larger than 1.0 KB.');
    expect(screen.getByRole('button', { name: 'Choose a file' })).toBeInTheDocument();
  });
});

describe('Combobox', () => {
  const people: ComboboxOption[] = [
    { value: 'i1', label: 'Anaya Rao', description: 'anaya@example.test' },
    { value: 'i2', label: 'Dev Kapoor' },
  ];

  function Harness({ onPick }: { onPick: (option: ComboboxOption | null) => void }) {
    const [value, setValue] = useState<ComboboxOption | null>(null);
    const [text, setText] = useState('');
    const options = people.filter((person) => person.label.toLowerCase().includes(text.toLowerCase()));
    return (
      <Field label="Instructor">
        <Combobox
          options={options}
          value={value}
          onInputChange={setText}
          onChange={(option) => {
            setValue(option);
            onPick(option);
          }}
        />
      </Field>
    );
  }

  it('filters, moves with arrow keys and selects with Enter', async () => {
    const onPick = vi.fn();
    render(<Harness onPick={onPick} />);
    const input = screen.getByRole('combobox', { name: 'Instructor' });
    await userEvent.click(input);
    expect(screen.getAllByRole('option')).toHaveLength(2);
    await userEvent.keyboard('{ArrowDown}{Enter}');
    expect(onPick).toHaveBeenCalledWith(people[1]);
    expect(input).toHaveValue('Dev Kapoor');
    expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
  });

  it('shows an empty message and closes on Escape', async () => {
    render(<Harness onPick={() => {}} />);
    const input = screen.getByRole('combobox', { name: 'Instructor' });
    await userEvent.type(input, 'zz');
    expect(screen.getByText('No matches')).toBeInTheDocument();
    await userEvent.keyboard('{Escape}');
    expect(input).toHaveAttribute('aria-expanded', 'false');
  });
});
