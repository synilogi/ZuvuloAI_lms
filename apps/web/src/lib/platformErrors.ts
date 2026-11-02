import type { ServiceError } from '@/services/contracts';

/*
 * Platform-configuration refusals the API answers with, by their stable code, as the states the Super Admin
 * screens show. Kept apart from `billingStates.ts` on purpose: those are an academy's subscription refusals
 * (§34), which the HTTP client announces to the whole academy shell. These concern the platform's own setup,
 * are met only by a super admin, and carry the server's message unchanged.
 */

export const PLATFORM_ERROR_CODES = ['SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED'] as const;

export type PlatformErrorCode = (typeof PLATFORM_ERROR_CODES)[number];

export interface PlatformErrorState {
  code: PlatformErrorCode;
  tone: 'warn' | 'danger' | 'info';
  title: string;
  /** What it means and who can resolve it. */
  body: string;
}

export const PLATFORM_ERROR_STATES: Record<PlatformErrorCode, Omit<PlatformErrorState, 'code'>> = {
  SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED: {
    tone: 'warn',
    title: 'Secure credential storage is not configured on the server.',
    body: 'Gateway credentials are encrypted with PAYMENT_CREDENTIALS_KEY, a master key the server administrator sets on the API server — it is never entered here. Once it is set and the API restarted, credentials can be saved. Nothing was saved.',
  },
};

export const isPlatformErrorCode = (code: unknown): code is PlatformErrorCode => (PLATFORM_ERROR_CODES as readonly unknown[]).includes(code);

/** The state behind an error, when it is one of these refusals. */
export function platformErrorOf(error: unknown): PlatformErrorState | null {
  const reason = (error as Partial<ServiceError> | null)?.reason;
  return isPlatformErrorCode(reason) ? { code: reason, ...PLATFORM_ERROR_STATES[reason] } : null;
}
