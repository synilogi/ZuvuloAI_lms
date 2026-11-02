/**
 * Sends the dialog that is currently open to the printer on its own.
 *
 * It marks the document for the length of the print job; the print rules in `styles/base.css` keep
 * the app behind the dialog, the scrim and anything marked `data-print-hide` off the paper. The
 * mark is cleared on `afterprint`, and on a timer as well, because a browser that cancels the
 * dialog without firing the event would otherwise leave the document marked.
 */
export function printSheet(): void {
  const root = document.documentElement;
  root.setAttribute('data-print', 'sheet');
  const clear = () => root.removeAttribute('data-print');
  window.addEventListener('afterprint', clear, { once: true });
  window.setTimeout(clear, 60_000);
  window.print();
}
