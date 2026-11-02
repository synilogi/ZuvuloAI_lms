import type { Services } from './contracts';
import { mockServices } from './mock/mockServices';
import { httpServices } from './http/httpServices';

export * from './contracts';

const mode = import.meta.env.VITE_API_MODE ?? 'mock';

export const services: Services = mode === 'http' ? httpServices : mockServices;
