import { useEffect, useState } from 'react';
import { DEMO_NOW } from '@/services/mock/fixtures/learner';
import { API_MODE } from '@/lib/apiMode';

const loadedAt = Date.now();
const anchor = new Date(DEMO_NOW).getTime();

/**
 * The clock every screen reads. The mock academy is written around a fixed date, so in `mock` mode
 * the clock starts there and advances in real time — that is what keeps its live classes, deadlines
 * and "2 days ago" captions stable. The real API stamps records with the real date, so in `http`
 * mode the clock must be the real one, or everything the API returns reads days out.
 */
export function demoNow() {
  return API_MODE === 'http' ? new Date() : new Date(anchor + (Date.now() - loadedAt));
}

export function useNow(intervalMs = 30_000) {
  const [now, setNow] = useState(demoNow);
  useEffect(() => {
    const id = window.setInterval(() => setNow(demoNow()), intervalMs);
    return () => window.clearInterval(id);
  }, [intervalMs]);
  return now;
}
