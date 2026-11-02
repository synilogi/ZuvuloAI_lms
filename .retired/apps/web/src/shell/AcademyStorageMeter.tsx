import { useAsync } from '@/hooks/useAsync';
import { limitText } from '@/pages/superadmin/subscriptions/subscriptionMeta';
import { services } from '@/services';
import { SidebarMeter } from './SidebarMeter';

/*
 * The academy admin's sidebar storage meter: media storage against the plan's allowance, as the billing API
 * counts it (SAAS-016; it replaces a fixed prototype figure that contradicted the real usage on the Billing
 * page). Shown only when there is a figure to show — an admin who cannot read billing, or an academy on no
 * plan, gets no meter rather than an invented one.
 */
export function AcademyStorageMeter({ enabled }: { enabled: boolean }) {
  const query = useAsync('shell:storage', () => (enabled ? services.tenantBilling.summary() : Promise.resolve(null)));
  const line = query.data?.usage.find((u) => u.limit === 'storage.bytes');
  if (!line || !query.data?.plan) return null;
  const used = limitText('storage.bytes', line.used);
  if (line.allowed === null) return <SidebarMeter label="Media storage" value={0} max={100} valueText="Unlimited" caption={`${used} used`} />;
  const pct = line.allowed > 0 ? Math.min(100, Math.round((line.used / line.allowed) * 100)) : 100;
  return (
    <SidebarMeter label="Media storage" value={pct} max={100} valueText={`${pct}%`} caption={`${used} of ${limitText('storage.bytes', line.allowed)} used`} />
  );
}
