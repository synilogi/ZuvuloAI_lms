# Module — Authentication

Status: **COMPLETED** (phase F1) · Depends on: Foundation (F0)

## 1. Purpose
Accounts for every role (admin, instructor, student), sign-in/sign-up, password reset and the session the
frontend keeps in `localStorage` (`syniastrolms:token`).

## 2. Existing UI
- `/login` — `apps/web/src/pages/marketing/LoginPage.tsx` (email + password; "Forgot password?" modal; demo persona cards in mock mode only).
- `/register` — `RegisterPage.tsx` (name, email, password, agree to terms → creates a student).
- `/signed-out` — confirmation page after sign-out.
- Header account menu → sign out; profile dialog (name/email read-only).
- `/reset-password/:token` — `ResetPasswordPage.tsx` (checks the link, new password + confirm).

## 3. UI Data Requirements
`SessionUser { id, name, email, role, avatarUrl?, studentId?, instructorId? }` from `/auth/me`;
`{ token, user }` from login/register. Forgot: `{ ok: true }` always. Reset: `{ ok: true }` or a conflict.

## 4. Database
`User` (id, email unique, passwordHash, name, role, descriptor, instructorId?, createdAt, updatedAt) with an
optional 1:1 `Student` row (`Student.userId`) or a link to an `Instructor` row (`User.instructorId`).
`PasswordResetToken` (userId FK, tokenHash unique, expiresAt, usedAt, createdAt; index userId).
`EmailOutbox` (toEmail, toName, subject, text, templateKey, status, error, createdAt, sentAt).

## 5. API
| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| POST | `/auth/register` | public | creates User(role student) + Student in a transaction; 409 on duplicate email |
| POST | `/auth/login` | public | 401 on bad credentials (same message for unknown email) |
| GET | `/auth/me` | bearer | profile without `passwordHash` |
| POST | `/auth/forgot-password` | public | always `{ ok: true }`; writes a reset token + outbox email for known accounts |
| GET | `/auth/reset-password/:token` | public | `{ valid }` |
| POST | `/auth/reset-password` | public | `{ token, password }`; single use; 409 when invalid/used/expired |

## 6. Business Rules
- Password ≥ 8 characters (register/reset); email normalised to lower case; bcrypt cost 10; registration always creates a learner.
- JWT payload `{ sub, role, studentId?, instructorId? }`, expiry `JWT_EXPIRES_IN` (default 7d).
- Reset tokens: random 32 bytes, stored as SHA-256 hash, 1 hour validity, single use.
- No account enumeration: forgot-password returns the same response for unknown emails.

## 7. Permissions
Public: register, login, forgot, reset. Authenticated: me. Roles are read from the token only.

## 8. Backend Status
✅ register / login / me (schema-validated; registration is always a learner) · ✅ rate limit on `/auth/*` · ✅ forgot / reset with outbox · ✅ production secret check.

## 9. Frontend Integration
`services/http/auth.ts` (`login`, `register`, `me`, `logout`, `forgotPassword`, `checkResetToken`,
`resetPassword`) · `providers/SessionProvider.tsx` (token in storage, `/auth/me` on boot, listens for the
client's 401 event) · `RequireSession` in `app/router.tsx` (redirects to `/login?next=`, workspace
redirects) · `LoginPage` honours `?next=` · `useWorkspace` uses `user.instructorId` in http mode.

## 10. Testing
`apps/api/src/app.test.ts` + `foundation.test.ts` + `routes/auth.test.ts` — register (happy, duplicate, staff
role ignored, validation); login ok / wrong password; me with/without token; forgot (known + unknown → same
200, outbox only for known); reset (valid, reused, superseded, expired, validation); rate limit 429;
production secret check. Browser: guard, `?next=`, workspace redirects, forgot → reset → sign in.

## 11. Completion
- [x] Register / login / me
- [x] Forgot / reset password + outbox + page
- [x] 401 handling + route guard
- [x] Rate limiting on auth routes (F0)
- [x] Tests listed above
