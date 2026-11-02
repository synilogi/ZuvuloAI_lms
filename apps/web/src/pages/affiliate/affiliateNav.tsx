import { ChartBar, CurrencyInr, House, IdentificationCard, Receipt, TreeStructure, UsersThree, Wallet } from '@phosphor-icons/react';
import { RouteTabs } from '@/components/page/RouteTabs';

/** The learner's affiliate area: home, the tree, the team, volume, orders, earnings, wallet and KYC. */
export function AffiliateNav() {
  return (
    <RouteTabs
      label="Affiliate program"
      tabs={[
        { to: '/affiliate', label: 'Overview', icon: <House size={16} />, end: true },
        { to: '/affiliate/tree', label: 'My team', icon: <TreeStructure size={16} /> },
        { to: '/affiliate/team', label: 'Team list', icon: <UsersThree size={16} /> },
        { to: '/affiliate/volume', label: 'Volume', icon: <ChartBar size={16} /> },
        { to: '/affiliate/orders', label: 'Orders', icon: <Receipt size={16} /> },
        { to: '/affiliate/earnings', label: 'Earnings', icon: <CurrencyInr size={16} /> },
        { to: '/affiliate/wallet', label: 'Wallet', icon: <Wallet size={16} /> },
        { to: '/affiliate/kyc', label: 'Identity check', icon: <IdentificationCard size={16} /> },
      ]}
    />
  );
}
