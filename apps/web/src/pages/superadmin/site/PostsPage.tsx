import { useState } from 'react';
import { PencilSimple, Plus, Trash } from '@phosphor-icons/react';
import { BLOG_KINDS, BLOG_KIND_LABELS, BLOG_LIMITS, type BlogPost, type BlogPostInput } from '@syniastrolms/domain';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { DateTimeField, SiteImageField } from './siteFields';
import styles from '../affiliates/Affiliates.module.css';

const EMPTY: BlogPostInput = { kind: 'article', title: '', excerpt: '', body: '', coverUrl: '', externalUrl: '', eventAt: null, status: 'draft', publishAt: null };

const inputOf = (p: BlogPost): BlogPostInput => ({
  kind: p.kind,
  title: p.title,
  excerpt: p.excerpt,
  body: p.body,
  coverUrl: p.coverUrl,
  externalUrl: p.externalUrl,
  eventAt: p.eventAt ?? null,
  status: p.status,
  publishAt: p.publishAt ?? null,
});

/** What must be right before saving. The API checks the same rules. */
export function postIssue(input: BlogPostInput): string | undefined {
  if (input.title.trim().length < 3) return 'Give the post a title.';
  if (input.externalUrl && !/^https:\/\/\S+$/i.test(input.externalUrl.trim())) return 'A link must start with https://.';
  if (input.status === 'published' && !input.body.trim() && !input.externalUrl.trim()) return 'A published post needs some text or a link.';
  return undefined;
}

/** The website's blog, resources, webinars and workshops (docs/17). */
export default function PostsPage() {
  const toast = useToast();
  const list = useAsync('site:admin:posts', () => services.site.adminPosts());
  const [editing, setEditing] = useState<{ id?: string; input: BlogPostInput } | null>(null);
  const [removing, setRemoving] = useState<BlogPost | null>(null);
  const [error, setError] = useState<string>();
  const [saving, setSaving] = useState(false);

  if (list.status === 'error' && !list.data) {
    return <PlatformError title="The posts didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />;
  }

  const patch = (next: Partial<BlogPostInput>) => setEditing((e) => e && { ...e, input: { ...e.input, ...next } });

  const open = async (post: BlogPost) => {
    setError(undefined);
    setEditing({ id: post.id, input: inputOf(post) });
  };

  const save = async () => {
    if (!editing) return;
    const found = postIssue(editing.input);
    setError(found);
    if (found) return;
    setSaving(true);
    try {
      if (editing.id) await services.site.updatePost(editing.id, editing.input);
      else await services.site.createPost(editing.input);
      toast({ kind: 'success', title: editing.id ? 'The post is updated' : 'The post is created' });
      setEditing(null);
      await list.run().catch(() => undefined);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const statusLabel = (p: BlogPost) => (p.status === 'draft' ? 'Draft' : p.publishAt && Date.parse(p.publishAt) > Date.now() ? 'Scheduled' : 'Published');

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Blog and resources"
        description="Articles, free resources, webinars, live workshops, community news and career guidance. The latest three appear on the home page."
        actions={
          <Button
            variant="primary"
            iconStart={<Plus size={16} />}
            onClick={() => {
              setError(undefined);
              setEditing({ input: EMPTY });
            }}
          >
            New post
          </Button>
        }
      />
      {!list.data ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : list.data.length === 0 ? (
        <div className={styles.empty}>No posts yet. The section stays off the home page until there is one to show.</div>
      ) : (
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Post</th>
                <th>Kind</th>
                <th>Status</th>
                <th>Created</th>
                <th aria-label="Actions" />
              </tr>
            </thead>
            <tbody>
              {list.data.map((p) => (
                <tr key={p.id}>
                  <td>
                    <span className={styles.cellTitle}>{p.title}</span>
                    <span className={styles.cellMeta}>/blog/{p.slug}</span>
                  </td>
                  <td>{BLOG_KIND_LABELS[p.kind]}</td>
                  <td>
                    <Badge tone={p.status === 'draft' ? 'neutral' : 'accent'}>{statusLabel(p)}</Badge>
                  </td>
                  <td>{formatDate(p.createdAt)}</td>
                  <td>
                    <div className={styles.rowActions}>
                      <IconButton label={`Edit ${p.title}`} icon={<PencilSimple size={16} />} onClick={() => void open(p)} />
                      <IconButton label={`Delete ${p.title}`} icon={<Trash size={16} />} onClick={() => setRemoving(p)} />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Modal
        open={editing !== null}
        onClose={() => setEditing(null)}
        title={editing?.id ? 'Edit post' : 'New post'}
        width={680}
        footer={
          <>
            <Button onClick={() => setEditing(null)}>Cancel</Button>
            <Button variant="primary" loading={saving} onClick={() => void save()}>
              Save post
            </Button>
          </>
        }
      >
        {editing && (
          <div className={styles.form}>
            {error && <InlineMessage kind="error" title={error} />}
            <div className={styles.fieldRow}>
              <Field label="Kind">
                <Select id="post-kind" value={editing.input.kind} onChange={(e) => patch({ kind: e.target.value as BlogPostInput['kind'] })}>
                  {BLOG_KINDS.map((k) => (
                    <option key={k} value={k}>
                      {BLOG_KIND_LABELS[k]}
                    </option>
                  ))}
                </Select>
              </Field>
              <Field label="Status">
                <Select id="post-status" value={editing.input.status} onChange={(e) => patch({ status: e.target.value as BlogPostInput['status'] })}>
                  <option value="draft">Draft: not on the website</option>
                  <option value="published">Published</option>
                </Select>
              </Field>
            </div>
            <Field label="Title">
              <Input id="post-title" value={editing.input.title} maxLength={BLOG_LIMITS.title} onChange={(e) => patch({ title: e.target.value })} />
            </Field>
            <Field label="Short summary" optional>
              <Textarea id="post-excerpt" rows={2} value={editing.input.excerpt} maxLength={BLOG_LIMITS.excerpt} onChange={(e) => patch({ excerpt: e.target.value })} />
            </Field>
            <Field label="Text" hint="Headings with ##, **bold**, lists and links, as in a lesson article." optional>
              <Textarea id="post-body" rows={10} value={editing.input.body} maxLength={BLOG_LIMITS.body} onChange={(e) => patch({ body: e.target.value })} />
            </Field>
            <SiteImageField label="Cover image" value={editing.input.coverUrl} onChange={(coverUrl) => patch({ coverUrl })} />
            <Field label="Link" hint="Where a webinar is held or a resource lives. Must start with https://." optional>
              <Input id="post-link" value={editing.input.externalUrl} maxLength={BLOG_LIMITS.link} onChange={(e) => patch({ externalUrl: e.target.value })} />
            </Field>
            <div className={styles.fieldRow}>
              <DateTimeField label="Takes place" hint="For a webinar or workshop." value={editing.input.eventAt} onChange={(eventAt) => patch({ eventAt: eventAt ?? null })} />
              <DateTimeField label="Publish from" hint="Leave empty to publish straight away." value={editing.input.publishAt} onChange={(publishAt) => patch({ publishAt: publishAt ?? null })} />
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={removing !== null}
        onClose={() => setRemoving(null)}
        tone="danger"
        title={`Delete ${removing?.title ?? 'this post'}?`}
        description="It leaves the website at once, and this can’t be undone."
        confirmLabel="Delete post"
        onConfirm={async () => {
          if (!removing) return;
          await services.site.deletePost(removing.id);
          setRemoving(null);
          toast({ kind: 'success', title: 'The post is deleted' });
          await list.run().catch(() => undefined);
        }}
      />
    </div>
  );
}
