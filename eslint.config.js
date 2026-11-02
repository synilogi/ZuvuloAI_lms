import js from '@eslint/js';
import globals from 'globals';
import reactHooks from 'eslint-plugin-react-hooks';
import tseslint from 'typescript-eslint';

const PLAN_NAME_MESSAGE = 'Do not gate on a plan by its name or code — ask what the plan grants (packages/domain/src/entitlement.ts).';
/** A plan's `code` or `name`, read off anything whose name mentions a plan, or a `planCode` / `planName` variable. */
const PLAN_IDENTITY = [
  "MemberExpression[property.name=/^(code|name)$/][object.name=/plan/i]",
  "MemberExpression[property.name=/^(code|name)$/][object.property.name=/plan/i]",
  'Identifier[name=/^plan(Code|Name)$/]',
  'MemberExpression[property.name=/^plan(Code|Name)$/]',
];
const PLAN_NAME_CHECKS = PLAN_IDENTITY.flatMap((side) => [
  { selector: `BinaryExpression[operator=/^[!=]==?$/][right.type='Literal'] > ${side}.left`, message: PLAN_NAME_MESSAGE },
  { selector: `BinaryExpression[operator=/^[!=]==?$/][left.type='Literal'] > ${side}.right`, message: PLAN_NAME_MESSAGE },
  { selector: `SwitchStatement > ${side}.discriminant`, message: PLAN_NAME_MESSAGE },
]);

export default tseslint.config(
  { ignores: ['**/dist', '**/node_modules', '**/.vite', '*.html', '.retired/**'] },
  {
    files: ['**/*.{ts,tsx}'],
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    languageOptions: { ecmaVersion: 2022, globals: { ...globals.browser, ...globals.node } },
    plugins: { 'react-hooks': reactHooks },
    rules: {
      ...reactHooks.configs.recommended.rules,
      '@typescript-eslint/no-non-null-assertion': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      // What an academy may do is what its plan grants, asked of the entitlement catalogue — never which
      // plan it is on (subscriptions.md §4, SAAS-002). These catch `plan.code === 'PRO'`,
      // `'Growth' !== current.plan.name`, `planName === '…'` and a `switch` on a plan's code or name.
      'no-restricted-syntax': ['error', ...PLAN_NAME_CHECKS],
    },
  },
  {
    // A route asks the entitlement service what an academy's plan allows (apps/api/src/lib/entitlements.ts);
    // it never reads plan or subscription tables itself (subscriptions.md §22, SAAS-003). Rule options are
    // replaced per block, not merged, so the plan-name checks are repeated here.
    files: ['apps/api/src/routes/**/*.ts'],
    ignores: ['**/*.test.ts'],
    rules: {
      'no-restricted-syntax': [
        'error',
        ...PLAN_NAME_CHECKS,
        {
          selector: 'MemberExpression[object.name=/^(db|tx|client|platformDb|prisma|base)$/][property.name=/^(plan|planVersion|planFeature|planLimit|planChange|feature|limitDefinition|subscription[A-Za-z]*)$/]',
          message: 'Routes do not read plan or subscription tables — ask the entitlement service (lib/entitlements.ts) or the plan service (lib/plans.ts).',
        },
      ],
    },
  },
);
