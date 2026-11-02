import { useEffect } from 'react';

/** Adds structured data for search engines to the document head while the page is shown. Nothing until `data` is set. */
export function useJsonLd(data: object | undefined) {
  const text = data ? JSON.stringify(data) : undefined;
  useEffect(() => {
    if (!text) return;
    const script = document.createElement('script');
    script.type = 'application/ld+json';
    script.text = text;
    document.head.appendChild(script);
    return () => script.remove();
  }, [text]);
}
