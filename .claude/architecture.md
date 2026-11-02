# SyniastroLMS UI Architecture

Follow the existing application's architecture and conventions.

## Before Coding
Inspect:
- current app shell
- routing
- component library
- design tokens
- existing page layouts
- forms
- tables
- dialogs
- responsive utilities
- icon system
- existing mock/data patterns

## Component Strategy
Prefer reusable components and existing primitives. Create new shared components only when a pattern is genuinely reusable.

Suggested LMS organization if compatible with the existing project:
- modules/lms/
- components/lms/
- pages or routes following the existing routing convention

Do not force this structure if the existing project uses another established pattern.

## State
Use local/mock state for UI behavior. Do not introduce backend state.

## Routing
Use the existing routing approach. Every major screen should have a logical route where the existing application supports routing.

## Established in LMS-000 (Foundation & Design System)

The project now has an established architecture. Follow it rather than the suggestions above; the full guide is `docs/01-PROJECT-ARCHITECTURE.md`.

- Workspaces: `apps/web` (frontend), `packages/domain` (shared types and rules, for the future API).
- Build new screens under `apps/web/src/pages/<area>/` and route them in `app/router.tsx` and `shell/navigation.tsx`.
- Compose from `components/ui` (shell primitives), `components/overlays` and `components/lms` (learning components) before creating anything new.
- Tokens in `styles/tokens.css`, density via `data-density`, states via `components/lms/status`.
- Data through `services` interfaces and mock services only; track requests with `useAsync(key, fn)`.
- `/design-system` documents every component and state. Update it when a module adds a reusable pattern.
- Verification: `npm run typecheck`, `npm run lint`, `npm test`, `npm run build`.
