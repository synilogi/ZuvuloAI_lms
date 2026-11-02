import { CreditCard, Pulse, Receipt, Ticket } from '@phosphor-icons/react';
import { RouteTabs } from '@/components/page/RouteTabs';

export const SALES_BASE = '/superadmin/sales';

export function SalesTabs() {
  return (
    <RouteTabs
      label="Sales"
      tabs={[
        { to: `${SALES_BASE}/orders`, label: 'Orders', icon: <Receipt size={16} /> },
        { to: `${SALES_BASE}/coupons`, label: 'Coupons', icon: <Ticket size={16} /> },
        { to: `${SALES_BASE}/events`, label: 'Payment events', icon: <Pulse size={16} /> },
        { to: '/superadmin/payment-gateways', label: 'Payment setup', icon: <CreditCard size={16} /> },
      ]}
    />
  );
}
