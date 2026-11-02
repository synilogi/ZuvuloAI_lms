import { Fragment, type ReactNode } from 'react';
import styles from './ArticleBody.module.css';

/* ─── A small, safe renderer for the article editor's markdown ─────────── */

function inline(text: string): ReactNode[] {
  const parts = text.split(/(\*\*[^*]+\*\*|_[^_]+_|\[[^\]]+\]\([^)]+\))/g);
  return parts.map((part, i) => {
    if (part.startsWith('**') && part.endsWith('**')) return <strong key={i}>{part.slice(2, -2)}</strong>;
    if (part.startsWith('_') && part.endsWith('_')) return <em key={i}>{part.slice(1, -1)}</em>;
    const link = part.match(/^\[([^\]]+)\]\(([^)]+)\)$/);
    if (link)
      return (
        <a key={i} href={link[2]} target="_blank" rel="noreferrer">
          {link[1]}
        </a>
      );
    return <Fragment key={i}>{part}</Fragment>;
  });
}

export function ArticleBody({ body }: { body: string }) {
  const blocks = body.trim().split(/\n{2,}/);
  return (
    <div className={styles.article}>
      {blocks.map((block, i) => {
        const lines = block.split('\n');
        if (block.startsWith('## ')) return <h3 key={i}>{inline(block.slice(3))}</h3>;
        if (block.startsWith('> ')) return <blockquote key={i}>{inline(lines.map((l) => l.replace(/^>\s?/, '')).join(' '))}</blockquote>;
        if (lines.every((l) => l.startsWith('- ')))
          return (
            <ul key={i}>
              {lines.map((l, j) => (
                <li key={j}>{inline(l.slice(2))}</li>
              ))}
            </ul>
          );
        if (lines.every((l) => /^\d+\.\s/.test(l)))
          return (
            <ol key={i}>
              {lines.map((l, j) => (
                <li key={j}>{inline(l.replace(/^\d+\.\s/, ''))}</li>
              ))}
            </ol>
          );
        return <p key={i}>{inline(block)}</p>;
      })}
    </div>
  );
}
