# SyniastroLMS — Autonomous UI Development

## Scope
UI/UX ONLY. Do not implement backend, database, APIs, authentication logic, payments, real uploads, real video processing, or real-time functionality.

Use realistic local mock data and functional UI interactions.

## Primary Design Reference
The existing SyniastroLMS App Shell is the source of truth. Extend it; do not replace it.

Reuse the existing:
- App Shell
- Sidebar
- Header
- Navigation
- Typography
- Spacing
- Color tokens
- Buttons
- Cards
- Tables
- Forms
- Dialogs
- Icons
- Responsive patterns

The LMS must feel like a native premium SyniastroLMS product, not a generic LMS/admin template.

## Development Rule
Work strictly module-by-module. Complete and verify one module before starting the next. Never mark a module complete merely because it compiles.

## Quality Bar
Every screen should be production-ready and include appropriate:
- populated state
- loading state
- empty state
- error state
- hover/focus/active/disabled states
- responsive behavior
- realistic content
- polished micro-interactions

Avoid excessive cards, random gradients/colors, generic CRUD screens, placeholder content, and unnecessary redesign of existing components.
