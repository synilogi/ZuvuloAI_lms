import { useState, type FormEvent } from 'react';
import { Plus } from '@phosphor-icons/react';
import { formatMoney, isCouponCode, normaliseCouponCode, type Coupon, type CouponKind } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Field, Input, Select } from '@/components/ui/Field/Field';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { SalesTabs } from './salesMeta';
import styles from '../affiliates/Affiliates.module.css';

/** What a coupon takes off, in words. */
export const couponValue = (c: Pick<Coupon, 'kind' | 'percentBps' | 'amountOff'>) =>
  c.kind === 'percent' ? `${(c.percentBps ?? 0) / 100}% off` : `${formatMoney(c.amountOff ?? 0, 'INR')} off`;

const empty = { code: '', description: '', kind: 'percent' as CouponKind, value: '', endsAt: '', maxUses: '', courseId: '' };

type CouponIssues = Partial<Record<'code' | 'value' | 'maxUses', string>>;

/** What is wrong with the figures the form turns into a coupon, by field. Whole rupees and percentages to two places. */
export function couponFormIssues(f: typeof empty): CouponIssues {
  const issues: CouponIssues = {};
  if (!isCouponCode(normaliseCouponCode(f.code))) issues.code = 'A code is 3 to 32 letters, digits, hyphens or underscores.';
  const value = Number(f.value);
  if (f.kind === 'percent' && !(value > 0 && value <= 100)) issues.value = 'Enter a percentage above 0, up to 100.';
  if (f.kind === 'fixed' && !(Number.isInteger(value) && value > 0)) issues.value = 'Enter the amount off in whole rupees.';
  if (f.maxUses && !(Number.isInteger(Number(f.maxUses)) && Number(f.maxUses) >= 1))
    issues.maxUses = 'The number of uses must be a whole number, or left empty.';
  return issues;
}

/** Every course in the catalogue for the form's list, a page at a time. */
async function allCourses() {
  const rows: Awaited<ReturnType<typeof services.courses.list>>['rows'] = [];
  for (let page = 1; ; page += 1) {
    const result = await services.courses.list({ page, pageSize: 100 });
    rows.push(...result.rows);
    if (result.rows.length === 0 || rows.length >= result.total) return rows;
  }
}

/** Discount codes learners type at checkout (docs/16 §2.4). A code and its discount are fixed once made; it is disabled, never deleted. */
export default function CouponsPage() {
  const toast = useToast();
  const list = useAsync('sales:coupons', () => services.sales.coupons());
  const courses = useAsync('sales:coupon-courses', allCourses);
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState(empty);
  const [issues, setIssues] = useState<CouponIssues>({});
  const [error, setError] = useState<string>();
  const [saving, setSaving] = useState(false);
  const set = (key: keyof typeof empty) => (e: { target: { value: string } }) => setForm((f) => ({ ...f, [key]: e.target.value }));
  const rows = list.data ?? [];

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const found = couponFormIssues(form);
    setIssues(found);
    setError(undefined);
    if (Object.keys(found).length > 0) return;
    setSaving(true);
    try {
      const made = await services.sales.createCoupon({
        code: normaliseCouponCode(form.code),
        description: form.description.trim() || undefined,
        kind: form.kind,
        ...(form.kind === 'percent' ? { percentBps: Math.round(Number(form.value) * 100) } : { amountOff: Number(form.value) * 100 }),
        ...(form.endsAt ? { endsAt: new Date(`${form.endsAt}T23:59:59+05:30`).toISOString() } : {}),
        ...(form.maxUses ? { maxUses: Number(form.maxUses) } : {}),
        ...(form.courseId ? { courseId: form.courseId } : {}),
      });
      toast({ kind: 'success', title: `Coupon ${made.code} is ready`, text: couponValue(made) });
      setCreating(false);
      setForm(empty);
      await list.run();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const toggle = async (c: Coupon) => {
    try {
      await services.sales.updateCoupon(c.id, { status: c.status === 'active' ? 'disabled' : 'active' });
      await list.run();
    } catch (err) {
      toast({ kind: 'error', title: 'The coupon didn’t change', text: (err as Error).message });
    }
  };

  const columns: Column<Coupon>[] = [
    {
      key: 'code',
      header: 'Code',
      mobile: 'primary',
      render: (c) => (
        <span className={styles.stack}>
          <span className={styles.cellTitle}>{c.code}</span>
          {c.description && <span className={styles.cellMeta}>{c.description}</span>}
        </span>
      ),
    },
    { key: 'value', header: 'Discount', mobile: 'meta', render: (c) => couponValue(c) },
    { key: 'course', header: 'Applies to', mobile: 'detail', render: (c) => c.course?.title ?? 'Every paid course' },
    { key: 'used', header: 'Used', width: '100px', mobile: 'detail', render: (c) => (c.maxUses === null ? c.usedCount : `${c.usedCount} of ${c.maxUses}`) },
    {
      key: 'ends',
      header: 'Ends',
      width: '130px',
      mobile: 'detail',
      render: (c) => (c.endsAt ? formatDate(c.endsAt) : <span className={styles.faint}>No end</span>),
    },
    {
      key: 'status',
      header: 'Status',
      width: '100px',
      mobile: 'status',
      render: (c) => (
        <Badge size="sm" tone={c.status === 'active' ? 'accent' : 'neutral'}>
          {c.status === 'active' ? 'Active' : 'Disabled'}
        </Badge>
      ),
    },
    {
      key: 'action',
      header: 'Actions',
      align: 'end',
      width: '110px',
      mobile: 'detail',
      render: (c) => (
        <Button size="sm" onClick={() => void toggle(c)}>
          {c.status === 'active' ? 'Disable' : 'Enable'}
        </Button>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Coupons"
        count={list.data ? plural(rows.length, 'coupon') : undefined}
        description="Codes learners type at checkout. A coupon never takes an order below ₹1, and a use counts once the order is paid."
        actions={
          <Button variant="primary" iconStart={<Plus size={16} />} onClick={() => setCreating(true)}>
            New coupon
          </Button>
        }
      />
      <SalesTabs />
      <PrototypeNote>The demo build has no platform behind it, so a coupon cannot be saved here.</PrototypeNote>
      {list.status === 'error' && !list.data ? (
        <PlatformError title="The coupons didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !list.data ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : rows.length === 0 ? (
        <StateMessage title="No coupons yet">Make one and share its code. It works at checkout straight away.</StateMessage>
      ) : (
        <DataTable<Coupon> rows={rows} columns={columns} rowKey={(c) => c.id} label="Coupons" rowLabel={(c) => c.code} framed />
      )}

      <Modal open={creating} onClose={() => setCreating(false)} title="New coupon" description="The code and the discount cannot be changed later." width={500}>
        <form className={styles.form} onSubmit={submit} noValidate>
          {error && <InlineMessage kind="error" title={error} />}
          <Field label="Code" error={issues.code}>
            <Input id="coupon-code" value={form.code} onChange={set('code')} placeholder="WELCOME10" autoFocus />
          </Field>
          <Field label="Discount type">
            <Select id="coupon-kind" value={form.kind} onChange={set('kind')}>
              <option value="percent">Percentage</option>
              <option value="fixed">Amount in rupees</option>
            </Select>
          </Field>
          <Field label={form.kind === 'percent' ? 'Percentage off' : 'Rupees off'} error={issues.value}>
            <Input id="coupon-value" inputMode="decimal" value={form.value} onChange={set('value')} />
          </Field>
          <Field label="Course" optional hint="Leave on every paid course unless it is for one.">
            <Select id="coupon-course" value={form.courseId} onChange={set('courseId')}>
              <option value="">Every paid course</option>
              {(courses.data ?? []).map((c) => (
                <option key={c.id} value={c.id}>
                  {c.title}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Last day" optional>
            <Input id="coupon-ends" type="date" value={form.endsAt} onChange={set('endsAt')} />
          </Field>
          <Field label="Total uses" optional hint="Empty for no ceiling. Each learner can use it once." error={issues.maxUses}>
            <Input id="coupon-uses" inputMode="numeric" value={form.maxUses} onChange={set('maxUses')} />
          </Field>
          <Field label="Note" optional hint="For you; learners don’t see it.">
            <Input id="coupon-note" value={form.description} onChange={set('description')} maxLength={200} />
          </Field>
          <div className={styles.formActions}>
            <Button type="button" onClick={() => setCreating(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" loading={saving}>
              Create coupon
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
