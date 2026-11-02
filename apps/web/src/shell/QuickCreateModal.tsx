import { useEffect, useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { BookOpenText, CalendarPlus, Stack } from '@phosphor-icons/react';
import type { Course } from '@syniastrolms/domain';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Select } from '@/components/ui/Field/Field';
import { Modal } from '@/components/overlays/Overlay';
import { useWorkspace } from '@/hooks/useWorkspace';
import type { QuickCreateKind } from '@/commands/registry';
import { services } from '@/services';

const COPY: Record<QuickCreateKind, { title: string; description: string; icon: JSX.Element; placeholder: string }> = {
  chapter: {
    title: 'Add chapter',
    description: 'Chapters group lessons around one idea. Choose the course to add it to.',
    icon: <Stack size={20} />,
    placeholder: 'Linear equations',
  },
  lesson: {
    title: 'New lesson',
    description: 'Lessons are saved as drafts until you publish. Choose the course to add it to.',
    icon: <BookOpenText size={20} />,
    placeholder: 'Mars in the tenth house',
  },
  'live-class': {
    title: 'Schedule live class',
    description: 'Enrolled learners get a calendar invite. Choose the course it belongs to.',
    icon: <CalendarPlus size={20} />,
    placeholder: 'Doubt-clearing: the twelve houses',
  },
};

/**
 * A fast on-ramp into the real creation flow, not a second copy of it: this only asks for a title
 * and the course to attach to, then hands off to the actual curriculum panel, lesson editor or
 * live-class scheduler — which own the real validation and the real write. Nothing here calls the
 * API, and it never claims to have created anything either.
 */
export function QuickCreateModal({ kind, onClose }: { kind: QuickCreateKind | null; onClose: () => void }) {
  const navigate = useNavigate();
  const { base } = useWorkspace();
  const [title, setTitle] = useState('');
  const [courseId, setCourseId] = useState('');
  const [courses, setCourses] = useState<Course[]>([]);
  const [error, setError] = useState<string | undefined>();
  const copy = kind ? COPY[kind] : null;

  useEffect(() => {
    if (!kind) return;
    let cancelled = false;
    services.courses.list({ status: 'all', page: 1, pageSize: 100 }).then((res) => {
      if (cancelled) return;
      setCourses(res.rows);
      setCourseId((current) => current || res.rows[0]?.id || '');
    });
    return () => {
      cancelled = true;
    };
  }, [kind]);

  const close = () => {
    setTitle('');
    setError(undefined);
    onClose();
  };

  const submit = (e?: FormEvent) => {
    e?.preventDefault();
    if (title.trim().length < 3) {
      setError('Give it a title of at least 3 characters.');
      return;
    }
    if (!courseId) {
      setError('Choose a course first.');
      return;
    }

    if (kind === 'chapter') navigate(`${base}/courses/${courseId}/curriculum/chapters/new`);
    else if (kind === 'lesson') navigate(`${base}/courses/${courseId}/lessons/new`);
    else if (kind === 'live-class') navigate(`${base}/live/new?course=${courseId}`);
    close();
  };

  return (
    <Modal
      open={!!kind}
      onClose={close}
      title={copy?.title}
      description={copy?.description}
      icon={copy?.icon}
      footer={
        <>
          <Button onClick={close}>Cancel</Button>
          <Button variant="primary" onClick={() => submit()} disabled={courses.length === 0}>
            Continue
          </Button>
        </>
      }
    >
      <form onSubmit={submit} className="contents">
        <Field label="Title" error={error}>
          <Input
            value={title}
            placeholder={copy?.placeholder}
            data-autofocus
            onChange={(e) => {
              setTitle(e.target.value);
              setError(undefined);
            }}
          />
        </Field>
        <Field label="Course" hint={courses.length === 0 ? 'No courses yet — create one first.' : undefined}>
          <Select value={courseId} onChange={(e) => setCourseId(e.target.value)}>
            {courses.map((c) => (
              <option key={c.id} value={c.id}>
                {c.title}
              </option>
            ))}
          </Select>
        </Field>
      </form>
    </Modal>
  );
}
