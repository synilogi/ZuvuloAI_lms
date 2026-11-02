/* A minimal, dependency-free PDF writer for the student demo's study notes (`prisma/studentDemo.ts`): A4 pages of
 * Helvetica text, a title, headed sections and paragraphs wrapped to the page. The output is deterministic (no
 * dates, no ids) so re-running the seed writes the same bytes. Text is WinAnsi (Latin-1): keep to it. */

export interface PdfSection {
  heading: string;
  /** Paragraphs; a line starting with "• " is kept as a bullet. */
  body: string[];
}

const PAGE_W = 595;
const PAGE_H = 842;
const MARGIN = 56;
/** Characters per line at 10.5 pt Helvetica across the text column; a conservative average. */
const WRAP = 92;

/** WinAnsi code points for the typographic characters outside Latin-1, and plain spellings for the maths symbols
 * Helvetica cannot draw. Anything else outside Latin-1 is refused rather than printed as the wrong glyph. */
const WIN_ANSI: Record<string, string> = {
  '•': '\x95',
  '‘': '\x91',
  '’': '\x92',
  '“': '\x93',
  '”': '\x94',
  '–': '\x96',
  '—': '\x97',
  '′': "'",
  '″': '"',
  '−': '-',
  '≈': '~',
  '≠': '!=',
  '≤': '<=',
  '≥': '>=',
  '→': '->',
  π: 'pi',
  ε: 'e',
  '√': 'sqrt',
  Φ: 'Phi',
  '₹': 'Rs ',
  '⁻': '^-',
  θ: 'theta',
};

const escape = (text: string) =>
  text
    .replace(/[\u0100-\uffff]/g, (c) => {
      if (c in WIN_ANSI) return WIN_ANSI[c];
      throw new Error(`The study-note PDF cannot print "${c}" (U+${c.codePointAt(0)!.toString(16).toUpperCase()}). Spell it out in the note text.`);
    })
    .replace(/\\/g, '\\\\')
    .replace(/\(/g, '\\(')
    .replace(/\)/g, '\\)');

function wrap(text: string, width = WRAP): string[] {
  const lines: string[] = [];
  let line = '';
  for (const word of text.split(/\s+/).filter(Boolean)) {
    if (line && line.length + 1 + word.length > width) {
      lines.push(line);
      line = word;
    } else line = line ? `${line} ${word}` : word;
  }
  if (line) lines.push(line);
  return lines;
}

/** Builds the PDF. `footer` is printed on every page with the page number. */
export function studyNotePdf(title: string, subtitle: string, sections: PdfSection[], footer: string): Buffer {
  type Op = { font: 'F1' | 'F2'; size: number; text: string; gapBefore: number };
  const ops: Op[] = [
    { font: 'F2', size: 18, text: title, gapBefore: 0 },
    { font: 'F1', size: 10.5, text: subtitle, gapBefore: 8 },
  ];
  for (const section of sections) {
    ops.push({ font: 'F2', size: 12.5, text: section.heading, gapBefore: 20 });
    for (const para of section.body) {
      const bullet = para.startsWith('• ');
      wrap(bullet ? para.slice(2) : para, bullet ? WRAP - 4 : WRAP).forEach((line, i) =>
        ops.push({ font: 'F1', size: 10.5, text: bullet ? (i === 0 ? `•  ${line}` : `    ${line}`) : line, gapBefore: i === 0 ? 7 : 2 }),
      );
    }
  }

  // Lay out into pages.
  const pages: string[][] = [[]];
  let y = PAGE_H - MARGIN;
  for (const op of ops) {
    const step = op.gapBefore + op.size * 1.25;
    if (y - step < MARGIN + 30) {
      pages.push([]);
      y = PAGE_H - MARGIN;
    }
    y -= step;
    pages[pages.length - 1].push(`BT /${op.font} ${op.size} Tf ${MARGIN} ${y.toFixed(1)} Td (${escape(op.text)}) Tj ET`);
  }
  const contents = pages.map(
    (lines, i) => `${lines.join('\n')}\nBT /F1 8.5 Tf ${MARGIN} ${MARGIN - 20} Td (${escape(`${footer}  ·  page ${i + 1} of ${pages.length}`)}) Tj ET`,
  );

  // Objects: 1 catalog, 2 pages, 3 Helvetica, 4 Helvetica-Bold, then a page and its content stream per page.
  const objects: string[] = [];
  const pageIds = contents.map((_, i) => 5 + i * 2);
  objects[1] = '<< /Type /Catalog /Pages 2 0 R >>';
  objects[2] = `<< /Type /Pages /Kids [${pageIds.map((id) => `${id} 0 R`).join(' ')}] /Count ${pageIds.length} >>`;
  objects[3] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>';
  objects[4] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>';
  contents.forEach((stream, i) => {
    const pageId = pageIds[i];
    objects[pageId] =
      `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${PAGE_W} ${PAGE_H}] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents ${pageId + 1} 0 R >>`;
    objects[pageId + 1] = `<< /Length ${Buffer.byteLength(stream, 'latin1')} >>\nstream\n${stream}\nendstream`;
  });

  let pdf = '%PDF-1.4\n%\xe2\xe3\xcf\xd3\n';
  const offsets: number[] = [];
  for (let id = 1; id < objects.length; id++) {
    offsets[id] = Buffer.byteLength(pdf, 'latin1');
    pdf += `${id} 0 obj\n${objects[id]}\nendobj\n`;
  }
  const xref = Buffer.byteLength(pdf, 'latin1');
  pdf += `xref\n0 ${objects.length}\n0000000000 65535 f \n`;
  for (let id = 1; id < objects.length; id++) pdf += `${String(offsets[id]).padStart(10, '0')} 00000 n \n`;
  pdf += `trailer\n<< /Size ${objects.length} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
  return Buffer.from(pdf, 'latin1');
}
