import { ServiceError } from '../contracts';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:4000';
/** Where the API is served from — the base every request, and every address given to a provider, starts with. */
export const API_BASE_URL = BASE_URL;
const TOKEN_KEY = 'syniastrolms:token';
/** Fired on `window` when a request with a token comes back 401. */
export const UNAUTHORIZED_EVENT = 'syniastrolms:unauthorized';
/** Fired on `window` with `{ code, message }` when the signed-in account's workspace has closed (docs/16, D-PLAT-02). */
export const ACCOUNT_CLOSED_EVENT = 'syniastrolms:account-closed';

export function getToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setToken(token: string | null) {
  try {
    if (token) localStorage.setItem(TOKEN_KEY, token);
    else localStorage.removeItem(TOKEN_KEY);
  } catch {
    /* ignore */
  }
}

function codeFor(status: number): ServiceError['code'] {
  if (status === 404) return 'not-found';
  // Signed in but not allowed — kept apart from 401, which the token handling below deals with.
  if (status === 403) return 'forbidden';
  if (status === 409 || status === 400 || status === 401) return 'conflict';
  return 'unknown';
}

/** Thin fetch wrapper: attaches the bearer token, serialises JSON (or sends a `FormData` as multipart), and maps failures to ServiceError. */
export async function request<T>(path: string, options: { method?: string; body?: unknown; query?: object } = {}): Promise<T> {
  const url = new URL(path.startsWith('http') ? path : `${BASE_URL}${path}`);
  if (options.query) {
    for (const [key, value] of Object.entries(options.query as Record<string, unknown>)) {
      if (value === undefined || value === null) continue;
      if (Array.isArray(value)) value.forEach((v) => url.searchParams.append(key, String(v)));
      else url.searchParams.set(key, String(value));
    }
  }

  const token = getToken();
  // A form (file uploads) goes as it is: the browser sets its multipart type and boundary.
  const form = typeof FormData !== 'undefined' && options.body instanceof FormData ? options.body : undefined;
  let response: Response;
  try {
    response = await fetch(url.toString(), {
      method: options.method ?? 'GET',
      headers: {
        ...(options.body !== undefined && !form ? { 'Content-Type': 'application/json' } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: form ?? (options.body !== undefined ? JSON.stringify(options.body) : undefined),
    });
  } catch {
    throw new ServiceError('Could not reach the server.', 'network');
  }

  if (response.status === 204) return undefined as T;

  const isJson = response.headers.get('content-type')?.includes('application/json');
  const payload = isJson ? await response.json().catch(() => undefined) : await response.text();

  if (response.status === 401 && token) {
    // The stored token is no longer accepted (expired, revoked, secret rotated): forget it and let the
    // session provider drop to signed-out, which sends the visitor to /login.
    setToken(null);
    window.dispatchEvent(new CustomEvent(UNAUTHORIZED_EVENT));
  }

  if (!response.ok) {
    const body = isJson && payload && typeof payload === 'object' ? (payload as { message?: unknown; issues?: unknown; code?: unknown }) : undefined;
    let message = body?.message ? String(body.message) : 'Something went wrong.';
    const issues = Array.isArray(body?.issues) ? (body!.issues as { message?: string; label?: string; field?: unknown; path?: unknown }[]) : undefined;
    // Issues that name a body field (`field`, or a validation `path`), so a form can show each beside its input.
    const fieldIssues = issues
      ?.map((i) => ({ field: typeof i.field === 'string' ? i.field : typeof i.path === 'string' ? i.path : '', message: i.message ?? '' }))
      .filter((i) => i.field && i.message);
    // An issue that only repeats the message adds nothing.
    const issueMessages = issues?.map((i) => i.message ?? i.label).filter((m): m is string => !!m && m !== message);
    if (issueMessages?.length) message = `${message} ${issueMessages.join(' ')}`;
    const reason = typeof body?.code === 'string' ? body.code : undefined;
    if (token && reason === 'WORKSPACE_CLOSED') {
      // This account's workspace has closed: the session can do nothing more, so it ends with the reason shown.
      setToken(null);
      window.dispatchEvent(new CustomEvent(ACCOUNT_CLOSED_EVENT, { detail: { code: reason, message } }));
    }
    throw new ServiceError(message, codeFor(response.status), reason, fieldIssues?.length ? fieldIssues : undefined, response.status);
  }
  return payload as T;
}

export const get = <T>(path: string, query?: object) => request<T>(path, { query });
export const post = <T>(path: string, body?: unknown) => request<T>(path, { method: 'POST', body: body ?? {} });
export const patch = <T>(path: string, body?: unknown) => request<T>(path, { method: 'PATCH', body: body ?? {} });
export const put = <T>(path: string, body?: unknown) => request<T>(path, { method: 'PUT', body: body ?? {} });
export const del = <T>(path: string, query?: object) => request<T>(path, { method: 'DELETE', query });
