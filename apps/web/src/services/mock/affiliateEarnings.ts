import type { MlmDashboard, MlmKycView, MlmLiabilityReport } from '@syniastrolms/domain';
import type { AffiliateEarningsService, PlatformEarningsService } from '../contracts';
import { ServiceError } from '../contracts';
import { respond } from './simulation';

/* The demo build runs no money: its earnings are honestly empty, and anything that would move money is refused. */

const noServer = () => new ServiceError('The demo build moves no money. Sign in to a real installation.', 'conflict');
const empty = ({ page = 1, pageSize = 20 }: { page?: number; pageSize?: number } = {}) => respond({ rows: [] as never[], total: 0, page, pageSize });
const refuse = () => Promise.reject(noServer());
const period = (at?: string): MlmLiabilityReport => ({
  period: at ?? new Date().toISOString().slice(0, 7),
  grossEligibleSales: 0,
  ceilingAmount: 0,
  normalAmount: 0,
  matchingPaid: 0,
  rewardsPaid: 0,
  reversals: 0,
  fieldPayout: 0,
  payoutRatioBps: 0,
  heldAmount: 0,
  headroom: 0,
  withdrawalsPaid: 0,
  walletLiability: 0,
  currency: 'INR',
});
const noKyc: MlmKycView = {
  status: 'none',
  legalName: '',
  panLast4: '',
  bankAccountLast4: '',
  ifsc: '',
  accountHolder: '',
  upiId: null,
  rejectionReason: null,
  submittedAt: null,
  reviewedAt: null,
  documents: [],
};

export const affiliateEarningsService: AffiliateEarningsService = {
  earnings: () =>
    respond({
      wallet: { available: 0, held: 0, paid: 0, heldByPolicy: 0, currency: 'INR' },
      progress: { current: null, next: null },
      lifetimeA: 0,
      lifetimeB: 0,
      matchingIncome: 0,
      rewardIncome: 0,
    }),
  matchingRuns: empty,
  commissions: empty,
  rankHistory: empty,
  rewards: empty,
  walletEntries: empty,
  kyc: () => respond(noKyc),
  submitKyc: refuse,
  withdrawals: empty,
  requestWithdrawal: refuse,
  cancelWithdrawal: refuse,
};

const dashboard: MlmDashboard = {
  jobs: [],
  members: { total: 0, active: 0, pending: 0, suspended: 0 },
  queues: { kyc: 0, rewards: 0, withdrawals: 0, heldCommissions: 0 },
  period: period(),
  lastMatchingDate: null,
};

export const platformEarningsService: PlatformEarningsService = {
  dashboard: () => respond(dashboard),
  matchingRuns: empty,
  runMatching: refuse,
  commissions: empty,
  releaseCommission: refuse,
  writeOffCommission: refuse,
  ranks: () => respond([]),
  rankHistory: empty,
  recalculateRank: refuse,
  rewards: empty,
  approveReward: refuse,
  fundReward: refuse,
  payReward: refuse,
  rejectReward: refuse,
  wallets: empty,
  walletEntries: (_id, q) => empty(q),
  adjustWallet: refuse,
  kyc: empty,
  memberKyc: () => Promise.reject(new ServiceError('This member has not submitted an identity check.', 'not-found')),
  verifyKyc: refuse,
  rejectKyc: refuse,
  kycDocument: refuse,
  withdrawals: empty,
  approveWithdrawal: refuse,
  rejectWithdrawal: refuse,
  markWithdrawalPaid: refuse,
  payouts: () => respond([]),
  createPayout: refuse,
  payoutCsv: () => respond('batch\r\n'),
  closePayout: refuse,
  liability: (at) => respond(period(at)),
  liabilityCsv: () => respond('figure,value\r\n'),
};
