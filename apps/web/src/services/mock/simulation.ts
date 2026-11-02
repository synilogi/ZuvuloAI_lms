import { ServiceError } from '../contracts';

export type Scenario = 'normal' | 'empty' | 'error' | 'slow';

/**
 * Simulation controls for the mock backend. The design system flips `failNext`; any page can be
 * previewed in another state by adding `?scenario=empty|error|slow` to its URL.
 */
export const simulation = {
  latencyMs: 650,
  failNext: false,
};

export function scenario(): Scenario {
  if (typeof window === 'undefined' || !window.location) return 'normal';
  const value = new URLSearchParams(window.location.search).get('scenario');
  return value === 'empty' || value === 'error' || value === 'slow' ? value : 'normal';
}

export function respond<T>(value: T | (() => T), latency = simulation.latencyMs): Promise<T> {
  const mode = scenario();
  return new Promise((resolve, reject) => {
    window.setTimeout(
      () => {
        if (simulation.failNext || mode === 'error') {
          simulation.failNext = false;
          reject(new ServiceError('We couldn’t reach ZuviloAI. Check your connection and try again.', 'network'));
          return;
        }
        try {
          resolve(structuredClone(typeof value === 'function' ? (value as () => T)() : value));
        } catch (error) {
          reject(error instanceof ServiceError ? error : new ServiceError(error instanceof Error ? error.message : 'Something went wrong'));
        }
      },
      mode === 'slow' ? latency + 2400 : latency,
    );
  });
}

export const fail = (message: string, code: ServiceError['code'] = 'unknown') => Promise.reject(new ServiceError(message, code));
