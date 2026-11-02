/** 'http' selects the real API-backed services; 'mock' (the default) keeps the in-memory demo. */
export const API_MODE: 'mock' | 'http' = import.meta.env.VITE_API_MODE === 'http' ? 'http' : 'mock';
