/**
 * The id/aria wiring `Field` applies automatically when its child is the real control — for the
 * few places a control needs to sit next to something else inside a `Field` (a password show/hide
 * toggle, a copy button), pass `Field` that same `id` and spread this onto the actual control so
 * the label, hint and error stay associated with it instead of the wrapping element around it.
 */
export function fieldProps(id: string, message: unknown, error: unknown) {
  return {
    id,
    'aria-describedby': message ? `${id}-message` : undefined,
    'aria-invalid': error ? true : undefined,
  };
}
