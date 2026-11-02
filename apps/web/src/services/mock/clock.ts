import { toIST } from './random';
import { DEMO_NOW } from './fixtures/learner';

const loadedAt = Date.now();
const anchor = new Date(DEMO_NOW).getTime();

/** The mock backend's clock — the demo date, advancing in real time since the page loaded. */
export const mockNow = () => new Date(anchor + (Date.now() - loadedAt));
export const mockNowIso = () => toIST(mockNow());
