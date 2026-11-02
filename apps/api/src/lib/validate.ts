import type { Request } from 'express';
import { z, type ZodType } from 'zod';

import { badRequest } from './errors.js';

export { z };

/** Shape of a single validation problem returned to the client. */
export interface ValidationIssue {
  path: string;
  message: string;
}

function issuesOf(error: z.ZodError): ValidationIssue[] {
  return error.issues.map((i) => ({ path: i.path.map(String).join('.'), message: i.message }));
}

/** Parses `req.body` with `schema`; throws a 400 with `issues` when it does not match. */
export function parseBody<T extends ZodType>(req: Request, schema: T): z.infer<T> {
  const result = schema.safeParse(req.body ?? {});
  if (!result.success) throw badRequest('Check the request and try again.', issuesOf(result.error));
  return result.data;
}

/** Parses `req.query` with `schema` (strings in; coerce inside the schema where needed). */
export function parseQuery<T extends ZodType>(req: Request, schema: T): z.infer<T> {
  const result = schema.safeParse(req.query ?? {});
  if (!result.success) throw badRequest('Check the request and try again.', issuesOf(result.error));
  return result.data;
}

/* Reusable building blocks ------------------------------------------------ */

/** A non-empty, trimmed string with a sane upper bound (guards against giant payloads). */
/**
 * The body of a partial update. Every field optional and — unlike `schema.partial()` — none defaulted:
 * zod still applies a field's `.default()` under `.partial()`, so a PATCH that sent only a title came
 * back with `instructorIds: []`, `subtitle: ''` and every other default filled in, and the handler
 * dutifully wiped them. A field the client did not send must stay absent.
 */
export function patchOf<T extends z.ZodRawShape>(schema: z.ZodObject<T>): z.ZodObject<{ [K in keyof T]: z.ZodOptional<z.ZodTypeAny> }> {
  const shape: Record<string, z.ZodOptional<z.ZodTypeAny>> = {};
  for (const [key, field] of Object.entries(schema.shape) as [string, z.ZodTypeAny][]) {
    shape[key] = (field instanceof z.ZodDefault ? (field.removeDefault() as z.ZodTypeAny) : field).optional();
  }
  return z.object(shape) as z.ZodObject<{ [K in keyof T]: z.ZodOptional<z.ZodTypeAny> }>;
}

export const text = (max = 500) => z.string().trim().min(1).max(max);
export const optionalText = (max = 500) => z.string().trim().max(max).optional();
export const id = z.string().trim().min(1).max(64);
export const email = z.string().trim().toLowerCase().email().max(254);
export const isoDate = z.string().refine((v) => !Number.isNaN(Date.parse(v)), 'Enter a valid date.');
/** Query flag: `?x=true`. */
export const queryBool = z
  .union([z.literal('true'), z.literal('false'), z.boolean()])
  .transform((v) => v === true || v === 'true')
  .optional();
/** Query integer with bounds, e.g. `limit`. */
export const queryInt = (min: number, max: number, fallback: number) =>
  z
    .union([z.string(), z.number()])
    .optional()
    .transform((v) => (v === undefined || v === '' ? fallback : Number(v)))
    .pipe(z.number().int().min(min).max(max));

/**
 * Page and page size for a list. The size is capped: without a ceiling, `?pageSize=100000` hands the
 * whole table back in one request, which is both a data-dump and a cheap way to load the server.
 */
export const paging = {
  page: queryInt(1, 100_000, 1),
  /** 500 is the largest page any screen asks for (the report lookups); beyond that it is a scrape. */
  pageSize: queryInt(1, 500, 20),
};

/** An optional value that must come from a fixed set — anything else is a 400, not a 500. */
export const optionalEnum = <T extends string>(values: readonly T[]) => z.enum(values as unknown as [T, ...T[]]).optional();

/** A free-text query parameter, trimmed and bounded. */
export const searchText = z.string().trim().max(200).optional();

/** An optional id from the query string. Empty string means "not set", which is how the UI clears a filter. */
export const optionalId = z
  .string()
  .trim()
  .max(64)
  .optional()
  .transform((v) => (v ? v : undefined));

/** A mobile number as people write it: digits, with an optional leading + and spaces or hyphens between. */
export const phoneNumber = z
  .string({ error: 'Enter your mobile number.' })
  .trim()
  .regex(/^\+?\d[\d\s-]{7,18}\d$/, 'Enter a valid mobile number.');
