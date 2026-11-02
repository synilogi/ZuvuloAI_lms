import { createContext, useContext, useEffect } from 'react';

export interface Crumb {
  label: string;
  /** Omit on the current page. */
  to?: string;
}

interface PageCrumbsValue {
  crumbs: Crumb[];
  setCrumbs: (crumbs: Crumb[]) => void;
}

export const PageCrumbsContext = createContext<PageCrumbsValue>({ crumbs: [], setCrumbs: () => undefined });

export const usePageCrumbList = () => useContext(PageCrumbsContext).crumbs;

/**
 * Extends the shell breadcrumb below the navigation item a page belongs to —
 * e.g. Courses › Class 10 Mathematics › Edit. Cleared when the page unmounts.
 */
export function usePageCrumbs(crumbs: Crumb[]) {
  const { setCrumbs } = useContext(PageCrumbsContext);
  const key = JSON.stringify(crumbs);
  useEffect(() => {
    setCrumbs(JSON.parse(key) as Crumb[]);
    return () => setCrumbs([]);
  }, [key, setCrumbs]);
}
