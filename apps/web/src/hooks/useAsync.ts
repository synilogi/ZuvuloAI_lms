import { useCallback, useEffect, useRef, useState } from 'react';

export type AsyncState<T> =
  | { status: 'idle'; data?: undefined; error?: undefined }
  | { status: 'loading'; data?: T; error?: undefined }
  | { status: 'success'; data: T; error?: undefined }
  | { status: 'error'; data?: T; error: Error };

/**
 * Runs a service call and tracks loading, success and error. Keeps previous data while reloading.
 * `key` identifies the request — when it changes, the call runs again (e.g. a serialised query).
 */
export function useAsync<T>(key: string, fn: () => Promise<T>, { immediate = true } = {}) {
  const [state, setState] = useState<AsyncState<T>>({ status: immediate ? 'loading' : 'idle' } as AsyncState<T>);
  const callId = useRef(0);
  const fnRef = useRef(fn);
  fnRef.current = fn;

  const run = useCallback(() => {
    const id = ++callId.current;
    setState((prev) => ({ status: 'loading', data: prev.data }));
    return fnRef.current().then(
      (data) => {
        if (id === callId.current) setState({ status: 'success', data });
        return data;
      },
      (error: Error) => {
        if (id === callId.current) setState((prev) => ({ status: 'error', error, data: prev.data }));
        throw error;
      },
    );
  }, []);

  useEffect(() => {
    if (immediate) run().catch(() => undefined);
  }, [key, run, immediate]);

  return { ...state, run };
}
