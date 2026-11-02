import type {
  AffiliateEarnings,
  MlmCommissionRow,
  MlmDashboard,
  MlmKycRow,
  MlmKycView,
  MlmLiabilityReport,
  MlmMatchingRunRow,
  MlmPayoutBatchRow,
  MlmRankHistoryRow,
  MlmRankTier,
  MlmRewardRow,
  MlmWalletEntryRow,
  MlmWalletRow,
  MlmWithdrawalRow,
  Paged,
} from '@syniastrolms/domain';
import type { AffiliateEarningsService, PlatformEarningsService } from '../contracts';
import { csv } from './affiliatesPlatform';
import { ServiceError } from '../contracts';
import { API_BASE_URL, get, getToken, post, put } from './client';

const id = encodeURIComponent;

/** The member's own earnings, against `/affiliate/*` (docs/15 §5.2). */
export const httpAffiliateEarnings: AffiliateEarningsService = {
  earnings: () => get<AffiliateEarnings>('/affiliate/earnings'),
  matchingRuns: (q = {}) => get<Paged<MlmMatchingRunRow>>('/affiliate/matching', q),
  commissions: (q = {}) => get<Paged<MlmCommissionRow>>('/affiliate/commissions', q),
  rankHistory: (q = {}) => get<Paged<MlmRankHistoryRow>>('/affiliate/ranks', q),
  rewards: (q = {}) => get<Paged<MlmRewardRow>>('/affiliate/rewards', q),
  walletEntries: (q = {}) => get<Paged<MlmWalletEntryRow>>('/affiliate/wallet', q),
  kyc: () => get<MlmKycView>('/affiliate/kyc'),
  submitKyc: (input) => put<MlmKycView>('/affiliate/kyc', input),
  withdrawals: (q = {}) => get<Paged<MlmWithdrawalRow>>('/affiliate/withdrawals', q),
  requestWithdrawal: (amount) => post<MlmWithdrawalRow>('/affiliate/withdrawals', { amount }),
  cancelWithdrawal: async (withdrawalId) => {
    await post(`/affiliate/withdrawals/${id(withdrawalId)}/cancel`, {});
  },
};

const BASE = '/superadmin/affiliates';
const act = async (path: string, body: object = {}) => {
  await post(`${BASE}${path}`, body);
};

/** The program's money for the Super Admin, against `/superadmin/affiliates/*` (docs/15 §5.3). Every rule is the server's. */
export const httpPlatformEarnings: PlatformEarningsService = {
  dashboard: () => get<MlmDashboard>(`${BASE}/dashboard`),
  matchingRuns: (q = {}) => get<Paged<MlmMatchingRunRow>>(`${BASE}/matching/runs`, q),
  runMatching: () => post<{ matched: number; paid: number; held: number; failed: number }>(`${BASE}/matching/run`, {}),
  commissions: (q = {}) => get<Paged<MlmCommissionRow>>(`${BASE}/commissions`, q),
  releaseCommission: (commissionId, reason) => act(`/commissions/${id(commissionId)}/release`, { reason }),
  writeOffCommission: (commissionId, reason) => act(`/commissions/${id(commissionId)}/write-off`, { reason }),
  ranks: () => get<MlmRankTier[]>(`${BASE}/ranks`),
  rankHistory: (q = {}) => get<Paged<MlmRankHistoryRow>>(`${BASE}/ranks/history`, q),
  recalculateRank: (memberId) => post<{ reached: number }>(`${BASE}/members/${id(memberId)}/rank/recalculate`, {}),
  rewards: (q = {}) => get<Paged<MlmRewardRow>>(`${BASE}/rewards`, q),
  approveReward: (rewardId, amount) => act(`/rewards/${id(rewardId)}/approve`, amount === undefined ? {} : { amount }),
  fundReward: (rewardId) => act(`/rewards/${id(rewardId)}/fund`),
  payReward: (rewardId) => act(`/rewards/${id(rewardId)}/pay`),
  rejectReward: (rewardId, reason) => act(`/rewards/${id(rewardId)}/reject`, { reason }),
  wallets: (q = {}) => get<Paged<MlmWalletRow>>(`${BASE}/wallets`, q),
  walletEntries: (affiliateId, q = {}) => get<Paged<MlmWalletEntryRow>>(`${BASE}/wallets/${id(affiliateId)}`, q),
  adjustWallet: (affiliateId, amount, reason) => act(`/wallets/${id(affiliateId)}/adjust`, { amount, reason }),
  kyc: (q = {}) => get<Paged<MlmKycRow>>(`${BASE}/kyc`, q),
  memberKyc: (affiliateId) => get<MlmKycRow>(`${BASE}/kyc/${id(affiliateId)}`),
  verifyKyc: (affiliateId) => act(`/kyc/${id(affiliateId)}/verify`),
  rejectKyc: (affiliateId, reason) => act(`/kyc/${id(affiliateId)}/reject`, { reason }),
  kycDocument: async (affiliateId, assetId) => {
    const res = await fetch(`${API_BASE_URL}${BASE}/kyc/${id(affiliateId)}/documents/${id(assetId)}`, { headers: { Authorization: `Bearer ${getToken()}` } });
    if (!res.ok) throw new ServiceError('The document didn’t open.', res.status === 404 ? 'not-found' : 'conflict');
    return res.blob();
  },
  withdrawals: (q = {}) => get<Paged<MlmWithdrawalRow>>(`${BASE}/withdrawals`, q),
  approveWithdrawal: (withdrawalId) => act(`/withdrawals/${id(withdrawalId)}/approve`),
  rejectWithdrawal: (withdrawalId, reason, notPaidConfirmed) =>
    act(`/withdrawals/${id(withdrawalId)}/reject`, { reason, ...(notPaidConfirmed ? { notPaidConfirmed: true } : {}) }),
  markWithdrawalPaid: (withdrawalId, reference) => act(`/withdrawals/${id(withdrawalId)}/paid`, { reference }),
  payouts: () => get<MlmPayoutBatchRow[]>(`${BASE}/payouts`),
  createPayout: (withdrawalIds) => post<MlmPayoutBatchRow>(`${BASE}/payouts`, { withdrawalIds }),
  payoutCsv: (batchId) => csv(`${BASE}/payouts/${id(batchId)}/export.csv`, {}, 'Could not export the bank file.'),
  closePayout: (batchId) => act(`/payouts/${id(batchId)}/close`),
  liability: (period) => get<MlmLiabilityReport>(`${BASE}/reports/liability`, { period }),
  liabilityCsv: (period) => csv(`${BASE}/reports/export.csv`, { period }, 'Could not export the report.'),
};
