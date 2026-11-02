# SyniastroLMS UI Rules

1. Existing SyniastroLMS App Shell always wins over invented UI patterns.
2. Inspect before modifying.
3. Reuse before creating.
4. Do not rewrite working unrelated code.
5. UI only; use mock data.
6. Never expose secrets or add credentials.
7. Never perform destructive production operations.
8. Every module must work on desktop, tablet, and mobile.
9. Do not merely shrink desktop; adapt layout and controls.
10. Use realistic astrology/LMS content instead of lorem ipsum.
11. Preserve accessibility basics: labels, keyboard focus, semantic controls, contrast, readable states.
12. Every interactive control must have a meaningful visible result.
13. Avoid dead buttons and fake functionality.
14. Do not leave TODOs for core UI requirements.
15. Keep visual hierarchy, spacing, typography, and icon usage consistent.
16. Prefer existing design tokens instead of hardcoded one-off styling.
17. Verify compile/type/lint/build and inspect browser console when available.
18. Each completed module gets a separate git commit:
   feat(lms-ui): complete [module name]
