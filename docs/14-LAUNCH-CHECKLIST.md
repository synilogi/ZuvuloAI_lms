# 14 — Production launch checklist

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

**New before launching the platform:** legal review of the rewritten Terms, Refund and Privacy pages and of the affiliate page under India's direct selling rules; the owner's decision on the TDS rate (`tdsBps`, 0 today); the eligible course and activation of a plan; `PAYMENT_CREDENTIALS_KEY` on the server; real testimonials through Website, or the section stays hidden; a rehearsal of `platform:convert` on a copy of production.

Prepared 2026-10-23 from a full audit of the API, web app, Flutter app and deploy scripts. Section A lists what still
needs a decision or an external account; section B is the deploy, in order; section C is the marketing launch.

Status keys: ✅ done and verified · ⬜ to do · 🔒 needs the owner's decision or credentials.

---

## A. Blockers and decisions

### Decided by the owner (2026-10-23)

- ✅ **Company:** Synilogic Tech Private Limited, Gumanpura, Kota, Rajasthan 324007, India, +91 96490 96197. These are on the website's footer, Contact, Terms, Privacy and Refund pages, from one source: `COMPANY` in `apps/web/src/pages/marketing/siteContent.tsx`.
- ✅ **Refunds are reviewed by hand.** Nothing refunds automatically, cancellation included. Only a super admin can refund, with a reason, at `POST /superadmin/payments/:id/refund`. Money paid against a voided invoice is recorded and flagged `refund review needed`. Tests pin both behaviours.
- ✅ **No plan checkout in the mobile app.** `BILLING_CHECKOUT_ENABLED` is `false` in `config/prod.json` and `config/staging.json`, and a test fails any config that reaches zuviloai.com with it on. Plans are bought on the website.

### Still needed

| # | What | Why |
| --- | --- | --- |
| A1 🔒 | **Email DNS** (exact records in section D) | Registration codes will land in spam or bounce, and nobody can write to an `@zuviloai.com` address. |
| A2 🔒 | **Full registered address** (street or building; the "Add" before Gumanpura looks like a placeholder) | Razorpay KYC, invoices, and legal pages. The website shows "Gumanpura, Kota, Rajasthan 324007, India" until then. |
| A3 🔒 | **CIN** (proof of the private-limited status) | Legal pages and invoices. Not shown anywhere until confirmed. |
| A4 🔒 | **GSTIN** | Plans are charged with GST, but invoices carry no seller name, address or GSTIN. A tax invoice needs the supplier's GSTIN. |
| A5 🔒 | **Grievance officer's name and email** | India's IT Rules ask for a named officer. The Privacy page names the company's channels (email, phone, post) until then. |
| A6 🔒 | **Approve the drafted wording** | `/refunds`: requests within 30 days, a decision within 2 working days, banks take 5–7 working days. Privacy: grievances acknowledged within 24 hours and resolved within 30 days. |
| A7 🔒 | **Razorpay test keys for one end-to-end run** (SAAS-016) | Never run against a deployed server. Use test-mode keys, not live ones. |
| A8 🔒 | **Rotate the live Razorpay key secret** | It was pasted into a chat on 2026-10-23. Regenerate it in the Razorpay dashboard, and enter the new key only in Super Admin → Payment gateways (stored encrypted), never in a file or a message. |
| A9 ⬜ | **Play Console** | Data safety: camera, microphone, push token, no advertising ID. Feature graphic and screenshots. Play app-signing SHA-256 for `assetlinks.json`. Update `store/PLAY_CONSOLE.md`. |
| A10 ⬜ | **Company Settings screenshot** | The brief mentioned one, but none was attached. None of its details (older address, phones, emails, GST) were reused. Any of them must be confirmed before use. |

---

## B. Deployment, in order

Each step that changes production needs the owner's explicit go-ahead.

1. ⬜ **Review and commit** the working tree on `sunil_workspace`. The new migration is `20261023120000_pending_accounts`. It is additive: one new table, one new column with a default.
2. ⬜ **Release the Flutter app first, or at the same moment.** Installed builds up to 1.1.0+4 expect a token from learner and instructor registration. After this deploy they get `202 { status: 'verify' }` and cannot finish signing up. Sign-in, invitations by sign-in and everything else keep working.
3. ⬜ **Deploy by hand once over SSH**, rather than by webhook. The webhook fix ships in this release, but the process receiving the push is still the old one, which hands its whole environment to `deploy.sh`:
   `bash /home/zuviloai/htdocs/zuviloai.com/app/deploy/deploy.sh`
   `deploy.sh` backs up the database before migrating and stops on a failed backup, migration or tenancy check.
4. ⬜ **Verify from outside:**
   - `curl -s https://zuviloai.com/api/health` should give `{"ok":true}`. It now also checks the database.
   - `curl -sI https://zuviloai.com/robots.txt` should be `text/plain`, and `/sitemap.xml` should be XML, not the app's HTML.
   - `curl -s https://zuviloai.com/api/public/academies/default` should include `invitationOnly`.
   - `/refunds` and `/join/default/teach` should load.
5. ⬜ **Prove email delivery to real inboxes** (after A1): register a test learner at `/join/default` with Gmail and Outlook addresses, and check the code lands in the inbox, not spam. Remove the test learners afterwards.
6. ⬜ **Schedule daily backups** (new `deploy/backup.sh`: database plus uploads, 14 kept, in `data/backups/daily`):
   `(crontab -l 2>/dev/null; echo "15 2 * * * /bin/bash /home/zuviloai/htdocs/zuviloai.com/app/deploy/backup.sh >> ~/backup.log 2>&1") | crontab -`
   Then copy `data/backups/daily` off the server regularly.
7. ⬜ **Log rotation:** `pm2 install pm2-logrotate`.
8. ⬜ **Uptime monitor** on `https://zuviloai.com/api/health` (any external monitor, alerting by email or phone).
9. ⬜ **Restrict the origin to Cloudflare's IP ranges** in the CloudPanel firewall (open item F18).
10. ⬜ **Remind:** the `default` academy's Professional trial ends **2026-10-29**.

### Restore, if a release must be rolled back

1. `pm2 stop zuviloai.com-api`
2. Copy the pre-deploy backup the deploy printed (`data/backups/prod-<stamp>.db`) over `data/prod.db`.
3. Check out the previous commit in `app/` and run `SKIP_FETCH=1 bash app/deploy/deploy.sh`.
4. Migrations are forward-only. The restored database file already has the old schema, so nothing needs undoing.

---

## C. Marketing launch

- ⬜ A1–A3 done: email lands in inboxes, legal pages carry the company's identity, and the refund wording is approved.
- ⬜ Google Search Console: verify the domain, then submit `https://zuviloai.com/sitemap.xml`.
- ⬜ A 1200×630 social preview image. `og:image` is the 512px app icon for now (`apps/web/index.html`).
- ⬜ Decide on website analytics. None is installed. Adding any means updating the Privacy page and the cookie notice.
- ⬜ Run a smoke test on production with throwaway accounts, then remove them:
  - register an academy, enter the code, start the trial, create a course
  - invite a learner, who joins with the code
  - an instructor asks to teach with the code, and the admin approves
  - a live class, a quiz, a certificate, then `/verify`
- ⬜ Check the `default` academy is what visitors should see. Its join link, `/join/default`, is the platform's own LMS.
- ⬜ Staff the support mailbox. The site promises a reply within one working day.
- ⬜ Play listing live (A8). Share the store link only after the build that has the email-code step.

---

## D. DNS records for zuviloai.com

The nameservers are Hostinger's (`*.dns-parking.com`). Records go in hPanel → Domains → DNS. As of 2026-10-23 the domain has no MX, SPF, DKIM or DMARC record.

**Sending: Brevo**, the SMTP relay the API uses. In Brevo → Senders, Domains & Dedicated IPs → Domains → Add `zuviloai.com` → authenticate it. Its automatic option can write these records through Hostinger. Copy the values Brevo shows: the code is unique to the account.

| Type | Host | Value |
| --- | --- | --- |
| TXT | `@` | `brevo-code:<the code Brevo shows>` |
| CNAME | `brevo1._domainkey` | the target Brevo shows (of the form `b1.zuviloai-com.dkim.brevo.com`) |
| CNAME | `brevo2._domainkey` | the target Brevo shows (of the form `b2.zuviloai-com.dkim.brevo.com`) |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:rua@dmarc.brevo.com` |

**Receiving**, for support@, privacy@ and so on: this needs a mailbox. The example below is Hostinger Email; Google Workspace or Zoho have their own values.

| Type | Host | Priority | Value |
| --- | --- | --- | --- |
| MX | `@` | 5 | `mx1.hostinger.com` |
| MX | `@` | 10 | `mx2.hostinger.com` |
| CNAME | `hostingermail-a._domainkey` | | `hostingermail-a.dkim.mail.hostinger.com` |
| CNAME | `hostingermail-b._domainkey` | | `hostingermail-b.dkim.mail.hostinger.com` |
| CNAME | `hostingermail-c._domainkey` | | `hostingermail-c.dkim.mail.hostinger.com` |

**SPF: one record only**, covering both senders:

| Type | Host | Value |
| --- | --- | --- |
| TXT | `@` | `v=spf1 include:spf.brevo.com include:_spf.mail.hostinger.com ~all` |

Without a mailbox, use `v=spf1 include:spf.brevo.com ~all`. Keep `p=none` on DMARC for 2–4 weeks while its reports show only Brevo and the mailbox sending, then move to `p=quarantine`.

**Then, on the server (needs approval):**
1. Set `MAIL_FROM="ZuviloAI <no-reply@zuviloai.com>"` in `apps/api/.env`.
2. Run `npm run mail:test -w @syniastrolms/api -- <your Gmail address>`.
3. Check the message arrived in the inbox with SPF, DKIM and DMARC "PASS" (Gmail → Show original).

Once a mailbox exists, switch `SUPPORT_EMAIL` in `apps/web/src/pages/marketing/siteContent.tsx` and `kSupportEmail` in `apps/mobile/lib/core/platform/support.dart` from the Gmail address to it.

---

## What this audit changed (2026-10-23)

- **Registration:** learners and instructors verify their email with a 6-digit code before any account exists, through every door (join link, invitation, course link, host sign-up, request to teach). Codes are HMAC-hashed, expire in 15 minutes, and allow 5 tries and 5 sends. Sends are limited per address as well as per client. Unconfirmed rows are pruned. An academy whose enrolment policy is `invite` takes learners by invitation only. The web has an instructor request page (`/join/:slug/teach`), and server field errors now show beside their fields.
- **Tenant fix in the app:** learner and instructor sign-up no longer falls back to the `default` academy (see the Flutter changes).
- **Payments:**
  - a payment Razorpay reports as `refunded` no longer settles an invoice
  - two simultaneous renewals add one period, not two
  - a new `checkout-recovery` job finds paid-but-unconfirmed checkouts on any open invoice
  - a capture race no longer returns 502, and a record race no longer returns 500
  - money on a voided invoice is reported clearly
- **Deploy:**
  - webhook deploys spawn `deploy.sh` with a clean environment
  - `npm ci --include=dev`
  - `/health` checks the database
  - graceful shutdown, and handlers for unhandled errors
  - daily backup script
- **Website:**
  - meta description and Open Graph tags
  - per-page titles and canonical links
  - real `robots.txt` and `sitemap.xml`
  - `/refunds` page, and the Privacy link fixed
  - login no longer demands 6 characters
- **App manifest:** advertising-ID permissions removed, and Analytics collection off.

### Second pass (2026-10-23, later)

- **Company identity:** added to the footer, Contact, Terms, Privacy and Refund pages from one source. The `privacy@` and `legal@zuviloai.com` addresses, which have no mailbox, were replaced with the working support address.
- **Privacy:** the Android section now matches the app. Camera and microphone are used for live classes, Firebase only for push, and there is no advertising ID. The page also says who we are and how to raise a grievance.
- **Production command palette:** it no longer shows learners made-up items such as "Live now", "Due Fri" or astrology lesson titles. It shows their own pages instead, and never searches demo fixtures.
- **Astrology copy:** removed from the chapter editor, quick create, the branding preview and the design-system page.
- **Mobile:** in-app checkout is off in staging too (it points at production), pinned by a test.
- **Refunds:** cancelling never refunds anything, pinned by a test, and the refund policy was redrafted for review.

---

## Third pass: full audit and E2E verification (2026-10-23, evening)

### Found live (read-only checks from outside)

- Production still serves the 22 Oct build (`index-BEvkzHqo.js`). None of today's fixes are deployed: `robots.txt` and `sitemap.xml` return the app's HTML, `/.well-known/assetlinks.json` is 404, and `/api/public/academies/default` has no `invitationOnly`.
- DNS is unchanged: no MX, SPF, DKIM or DMARC (A1 still open).
- TLS is Let's Encrypt and valid until 31 Dec 2026. HSTS is on. There is no Content-Security-Policy.
- nginx adds headers on top of the API's, so `Referrer-Policy` and `X-XSS-Protection` arrive twice with conflicting values. Remove the CloudPanel `add_header` lines.
- The site is not behind Cloudflare: the domain points straight at the origin (82.25.115.114), so item B9 does not apply as written.

### Fixed in this pass (uncommitted, with tests)

- **Demo seed:** it can no longer wipe production. It loads `.env` first, then refuses NODE_ENV/APP_ENV production, any `zuviloai.com` APP_URL/CORS_ORIGIN, and any database not named `dev.db`, `test.db` or `e2e.db` (`prisma/seedGuard.ts`). Before this, `npm run seed` in an SSH shell, which has no NODE_ENV, would have deleted every academy.
- **Email-code attempt limit:** it now holds under concurrent guesses. Each guess spends an attempt before it is compared (`pendingAccounts.ts`, `signup.ts`).
- **Password reset:**
  - links are budgeted per address, not only per IP
  - a reset link works once even when submitted twice at the same moment
  - sign-in takes as long for an unknown email as for a wrong password
- **Static test OTP:** refused wherever the live site is named (zuviloai.com, www, a trailing dot, the server IP, any of several CORS origins), whatever NODE_ENV says.
- **Test-mode payments:** a gateway left in test mode takes no new payment on a production process. Records already made in test mode still settle.
- **Late authorization:** a payment the gateway authorizes after it was recorded as failed is no longer captured, which before left the money taken and nothing recorded. The invoice stays open, and a `payment.unmatched` signal is raised.
- **Boot warning:** shown when production APP_URL is not a public https address.
- **Live classes:** a new class defaulted to 24 Sep 2026, a past date. It now defaults to tomorrow.
- **Web copy:** a suspended LMS no longer says "you can still sign in". Sign-in refuses its members.
- **Mobile:** version 1.1.0+4 → 1.1.1+5. Play rejects a reused versionCode.
- **Tests added:**
  - `e2e/journeys.spec.ts`: instructor request → admin approves → course built and published → learner joins, completes a lesson, takes a quiz, submits an assignment → instructor grades it → live class booked
  - `e2e/courseCreation.spec.ts`

### Still open (new)

| # | What | Why |
| --- | --- | --- |
| A11 ✅ (web, 24 Oct 2026) | **Course prices are labels only** | Addressed by course sales (migration `20261024120000_course_purchases`): a learner buys a priced course through the academy's own Razorpay account and the enrolment opens on the gateway's confirmation (`05-API-SPECIFICATION.md` › Course sales). A course with no admin-chosen price still enrols free. The app keeps `COURSE_CHECKOUT_ENABLED=false` on `zuviloai.com` and sends learners to the website, so the store-policy question remains the owner's. |
| A12 🔒 | **Live classes on public meet.jit.si** unless JaaS keys are set | Hosts must sign in there, embedded calls are time-limited, nothing is recorded. |
| A13 ⬜ | **Content-Security-Policy** for the web app (nginx or `index.html`) | The 7-day sign-in token is in localStorage, so any XSS steals it. |
| A14 ⬜ | **Super-admin MFA** (per-account throttle ✅ 2026-10-28) | Failed sign-ins are now limited per account as well as per IP (`RATE_LIMIT_ACCOUNT_MAX`, default 10 per 15 min, on `/auth/login` and invitation sign-in). No MFA exists for any role. |
| A15 ⬜ | **Verify on the server:** `TRUST_PROXY=1`, `NODE_ENV=production`, `APP_URL=https://zuviloai.com`, MAIL_FROM on an authenticated domain, no `APP_ENV`/`TEST_OTP_*`/`SIGNUP_EMAIL_VERIFICATION=off` | It can't be read from the repo, and Claude cannot SSH. |
| A16 ⬜ | **Off-server backups and a rehearsed restore** | `backup.sh` keeps copies on the same VPS. `.env` (JWT and gateway keys) is in no backup. |
| A17 ⬜ | **Sample-catalogue video lessons have no files** (seed data). Fragmented MP4 uploads report no duration on Android, so they can never be completed. | Learners would hit "Nothing to show yet", or lessons that never complete. |
| A18 ✅ | **Payment edge cases** (fixed 2026-10-28, with tests) | A refund with no definite answer (timeout, network, 5xx) stays `pending` (still committed, settled by its webhook) instead of `failed`. The renewal job no longer marks a subscription past due that a payment renewed meanwhile. A declined early-renewal payment no longer starts dunning before the paid period ends. Still open: a course refund or chargeback made in an academy's Razorpay dashboard does not revoke that learner's access (refunds are manual by decision). |
| A19 ⬜ | **Email hygiene** (part fixed 2026-10-28) | Fixed: codes and links are sent before any backlog of notifications in each delivery tick, and their subject and body are blanked 7 days after delivery. Open: per-academy Reply-To is only in the body, not a header; notification emails have no unsubscribe or List-Unsubscribe. |
| A20 ⬜ | **Uploads** (part fixed 2026-10-28) | Fixed: a learner's upload is cut off at the hand-in size, and video refused, before anything is written to disk. Open (product rule §21): a learner's files still count 0 bytes toward the plan quota, so hand-ins are not capped per learner. |
| A21 ⬜ | **iOS** | The bundle id is still `in.synilogictech.syniastrolmsMobile`, with no Associated Domains or push entitlements. |

---

## Paid courses (2026-10-23, night) — course purchases, uncommitted

Decided by the owner: each academy sells through **its own Razorpay account** (Settings › Course payments); prices are
**all-inclusive**; courses whose price came from the old academy default stay **held (`pricing = unset`) until an admin
chooses Free or Paid**. Migration `20261024120000_course_purchases` is additive (ALTER TABLE ADD COLUMN, new tables,
triggers); existing enrolments are not touched.

Before launch, in order:
1. ⬜ Deploy the API (migration) with the web build, and the app 1.1.1+5 — older apps show prices but cannot buy (they get `COURSE_PURCHASE_REQUIRED` on Enrol, and see an error).
2. ⬜ Run `npm run courses:audit-access -w @syniastrolms/api` on the server (read-only) and decide, per academy, what to do with learners enrolled for free in courses that are now held or paid. Nothing is revoked automatically.
3. ⬜ Each academy that sells: an admin opens every held course and chooses Free or Paid; connects **live** Razorpay keys and the webhook (`https://zuviloai.com/api/webhooks/academies/<tenantId>/razorpay/courses`, events `payment.captured`, `payment.authorized`, `payment.failed`, `order.paid`); turns payments on. Test mode is refused for new purchases on production.
4. ⬜ One end-to-end purchase with a real small amount on a test academy (owner approval needed), then refund it from the Razorpay dashboard.
5. 🔒 In-app course checkout stays off (`COURSE_CHECKOUT_ENABLED=false` in prod/staging): Google Play / App Store billing rules for digital content. Enabling needs a policy route (e.g. Google User Choice Billing in India).

---

## Live classes (2026-10-26) — audit and fixes, uncommitted

**Verified on 2026-10-26:** with no JaaS keys the API uses public meet.jit.si, and **no class can start there**. Both the
Android app (Infinix, via the Jitsi SDK) and a desktop browser joined the same class room and stopped at "The conference
has not yet started because no moderators have yet arrived… please log-in". ZuviloAI's host flag means nothing on the
public server; a host would have to sign in to meet.jit.si with a personal account, and embedded calls there are time-limited.

| # | What | Status |
| --- | --- | --- |
| L1 🔒 | **JaaS (8x8 Jitsi as a Service) on the server**: `JAAS_APP_ID`, `JAAS_KID`, `JAAS_PRIVATE_KEY` (server .env only), optionally `JAAS_WEBHOOK_SECRET` for recordings | ✅ **Works with a dev key pair (2026-10-26, local API + real JaaS).** Host = desktop Chromium (fake camera/mic) as moderator, no lobby; learner = Infinix X6525 app via the SDK as participant. Measured by WebRTC stats at the host: phone→host audio ~750 packets/15 s with energy > 0, video ~24 fps from the phone's real camera; host→phone video seen on the phone's screen, host→phone audio = the app's active VOIP playback track. Mic/camera prompts shown and granted; learners join muted by design. Leave → back on the Live tab; rejoin → same room; 20 s Wi-Fi drop → frozen frame + red quality badge, recovers by itself in ~25 s. Not by ear: audible sound. **Still to do for production:** a separate prod key pair in the server .env, turn off "Allow meeting participants to join unauthenticated" in the JaaS console, the webhook for recordings. |
| L2 ⬜ | Real attendance | Today "Joined" = ZuviloAI handed the learner the way into the room (seen on the phone: recorded as joined while stuck in the lobby). Verified attendance needs JaaS participant webhooks. Outside meetings record no attendance. |
| L3 ✅🔒 | **Android background audio** | **Fixed in code and passed on the Infinix X6525 (Android 13 Go) on 2026-10-28; needs the Play Console declaration before release.** The manifest now keeps the SDK's `JitsiMeetOngoingConferenceService` (`mediaPlayback\|microphone`) and its two FOREGROUND_SERVICE_* permissions; screen capture and calendar stay removed. Measured on real JaaS (dev keys, scratch API), host = desktop Chromium with a fake camera/mic: learner unmuted in the foreground, host received ~51 audio packets/s with rising energy; after Home, the same rate for 30 s, the phone's VOICE_COMMUNICATION track still `started`, the service in the foreground with a call notification; with Chrome in front for 70 s, the same. Back via the Live tab's Join → the same call, no duplicate participant. Hang up → service, notification and audio track gone, host sees 1 participant. Caveats: one earlier app-switch trial (Chrome opened by `adb monkey`, which also injects a random input) dropped the learner from the call with the process still alive; its log was lost to the 64 KiB buffer, and the rerun held for 70 s. Recents shows the Live tab, not the call (the meeting runs in its own task); Join brings the call back. The camera does not run in the background (the SDK's service type has no `camera`). **Owner: declare Microphone and Media playback foreground services in Play Console (description + demo video).** |
| L4 ⬜ | Notification volume | Scheduling/start/cancel/reschedule notices go to every enrolled learner inside the request, one by one. Fine for small academies; batch it before courses reach thousands. |

## Tests, quizzes and results (2026-10-26) — server-run attempts, uncommitted

Quizzes used to be scored at submit, while the timer, the questions shown in advance and the attempt count lived on the
client. Now every attempt is a **quiz session** the server starts, times, autosaves and finishes (ported unchanged from
the Classplus branch, commit 7d26c6a, "A2": same table, same migration, same checksum). Details: `lib/quizSessions.ts`,
`packages/domain/src/quizSession.ts`, `routes/learning.ts` › Quiz sessions, tests `quizSessions.test.ts` and `quizRules.test.ts`.

| # | What | Status |
| --- | --- | --- |
| Q1 🔒 | **Migration `20261014120000_quiz_sessions`** on production: creates QuizSession and rebuilds QuizAttempt (adds `sessionId`), copying every row. Its timestamp is older than migrations production already has; `prisma migrate deploy` applies it anyway (checked on a database migrated past it). Back up the database before the deploy. `dev.db` already has it (from the Classplus branch) with the same checksum. | Ready; needs the deploy. |
| Q2 ⬜ | **Installed app builds** (before this change) | Untimed quizzes with no window still work: the old submit is taken as a session started and handed in at once (counted and limited). Timed or windowed quizzes answer "Update the app" (`QUIZ_SESSION_REQUIRED`). Release the new app with the deploy. |
| Q3 ⬜ | Behaviour change: the answer key is withheld while the learner can still take the quiz for credit | Before, `score-and-answers` showed the right answers after attempt 1, which handed them to attempt 2. Now the key shows once the quiz is passed, every attempt is used, or it closes. Archiving a quiz also releases it. |
| Q4 ⬜ | Results held until the close (`resultsRelease: after-close`) | Score and answers are held; pass/fail is not, because a pass still completes the lesson. Decide whether held quizzes should complete the lesson only at the close. |
| Q5 ⬜ | Not built (decisions) | Staff releasing results by hand (`manual`); manual grading of written answers (short answers are matched against accepted answers only); question bank, sections, numeric questions, course-wide tests (all on the Classplus branch). |
| Q6 ⬜ | Negative marking | Added per question (`negativePoints`, as on the Classplus branch): wrong answers lose marks, blanks never; the total can go below zero, the percentage cannot. Confirm the product wants it. |
| Q8 ✅ | **Verified on the Infinix (2026-10-26), dev app against a local API** | Intro from the server (limit, 1 of 3 used counting a pre-session attempt); Start → server deadline, shuffled order; answer saved, "saved on the server" only after the server held it; app force-stopped and reopened → same attempt, answers kept, clock had kept running; API unreachable → "Retrying…", "Answered · not saved yet", and the server kept the last saved answer; time ran out offline → answers locked, handed in about 8 s after the connection came back, scored only on what was saved; left offline long enough, the server's minute job closed it as "Time ran out"; Back asks first; Tests list offers Resume with the hand-in time in IST. Found and fixed on the device: attempts stored as `{}` (the demo seed, also on production since 14 Oct) crashed the attempts list; the app never retried a hand-in after reconnecting; the question palette stacked one per line; passed quizzes could not be opened from Tests; a practice attempt after a pass showed as "Passed" and "No attempts left". |
| Q7 ⬜ | Merging with the Classplus branch | Same QuizSession design and migration. Windows differ: here `opensAt`/`closesAt` live in the quiz's settings JSON (no migration); Classplus has Quiz columns. Reconcile on merge. |


---

## Fourth pass: production-readiness audit (2026-10-28) — uncommitted

Five areas audited (assessments, admin/instructor UI, registration and email, live classes, security and payments);
every finding below was traced in the code before it was fixed. No migration. Nothing was deployed, committed or sent.

### Fixed, with tests

| Area | Fix |
| --- | --- |
| Quizzes | The credited score is the best attempt up to and including the first pass. Retakes after a pass, taken with the answers shown, no longer raise the score on certificates, the Tests list or the lesson. |
| Quizzes | A quiz set to hide results no longer shows the score in the Tests list or on the lesson page. |
| Quizzes | Publishing is refused when there is no pass mark (nobody could ever pass), when a key names an answer that is not offered or repeats one, or when two answers share an id. A short-answer question with no accepted answers gives a 409, not a 500. |
| Quizzes | **Behaviour change:** percentages round down. 69.5 % shows as 69 % and does not pass a 70 % mark; 4 of 6 is now 66 %, not 67 %. |
| Quizzes | A review shows the pass mark the attempt was scored against. Final answers sent without their save number are refused (400) rather than silently dropped. |
| Payments | A refund with an unknown outcome stays pending, closing the double-refund risk. Early-renewal decline and the renewal race are also fixed (A18). |
| Sign-in | Failed sign-ins are limited per account (A14). |
| Sign-in | Changing an instructor's email ends the set-password link sent to the old address, and their sessions. Changing a password ends any open reset link. |
| Static test OTP | It now runs only with NODE_ENV=development or test. A staging deployment (`APP_ENV=staging`), any APP_ENV of staging or production, or any zuviloai.com address refuses it; the API will not start with it set there. |
| Live classes | A production server with no JaaS keys no longer falls back to public meet.jit.si: start and join answer 503 `LIVE_ROOM_NOT_CONFIGURED`. The host's page explains why, and outside-meeting links keep working. `LIVE_ROOM_PUBLIC_JITSI=allow` overrides this. |
| Live classes | A JaaS private key that cannot sign stops boot. A learner's join token is made before attendance is written, so a failure no longer marks them present. |
| Live classes | The Android ongoing-class service is restored (L3). |
| Email | Codes and links go out before a notification backlog. Delivered codes and links are blanked from the outbox after 7 days (A19). |
| Uploads | Learner limits apply before any bytes are written (A20). |
| Admin/instructor UI | The learner report's Export CSV now works; it asked for a 100 000-row page, which the API refuses above 500. Exports are protected against spreadsheet formula injection. |
| Admin/instructor UI | Category Move up/down keeps positions unique, 1…n. |
| Admin/instructor UI | An instructor's learner list no longer shows other instructors' courses. |
| Admin/instructor UI | Pressing Publish under review-before-publish asks the admins once a day per course, not on every press. |
| Admin/instructor UI | `/design-system` (sample data, pretend toasts) is no longer in production builds. |
| Production config | A loud boot error appears when `SIGNUP_EMAIL_VERIFICATION=off` in production. It is a warning, not a refusal, because the live .env can't be read from here. |

New settings: `RATE_LIMIT_ACCOUNT_MAX` (default 10) and `LIVE_ROOM_PUBLIC_JITSI` (unset). Both are documented in `deploy/api.env.example`.

### Found and left for the owner

| # | What | Why it is not fixed here |
| --- | --- | --- |
| R1 🔒 | **Production JaaS keys.** Production has none, so after this deploy the built-in room is off there until they are set. | Needs a separate production key pair and the JaaS console setting "Allow meeting participants to join unauthenticated" turned **off**. |
| R2 🔒 | **Play Console** foreground-service declarations for L3 | Owner's console. |
| R3 ⬜ | Attendance is still "the learner was handed a join token" (L2) | Trustworthy attendance needs JaaS `PARTICIPANT_JOINED`/`LEFT` webhooks mapped to learners. The webhook route verifies signatures (HMAC-SHA256, ±300 s), but its timestamp unit is unverified against a real delivery, and there is no idempotency-key store. |
| R4 ⬜ | The server's End and stale-room close don't end the meeting on JaaS | Learners already inside stay until they leave or their token expires (at most the class end + 60 min). |
| R5 ⬜ | An OTP resend resets the 5-guess counter: 25 guesses per registration | Changing it means a learner who mistypes 5 times restarts the form. This is a UX decision. |
| R6 ⬜ | Course ratings are seeded random numbers in the demo academy; real academies always show "Not rated yet" | Nothing writes ratings. It's demo data, not a code path, but the dashboard Rating column and reports show it. |
| R7 ⬜ | Admin UI shows some actions that the API refuses for an admin missing that permission | API enforcement is correct. Affected: instructor profile Resend/Edit/Deactivate, course Publish/Archive, learner Pause/Remove, bulk Message, grading, assignment row menu, certificate templates. |
| R8 ⬜ | Course lookups in filters and pickers stop at 100 courses; the course-sales list stops at 200 with no paging | Scale issue. |
| R9 ⬜ | `/auth/register` without an academy still registers into `default` | Installed apps up to 1.1.0+4 send `workspace: 'default'` anyway; the new app build removes that. Ship the app with the deploy. |
| R10 ⬜ | Multiple-choice: equal right and wrong picks score 0 and, with negative marking, lose the negative marks | Scoring policy (Q6). |
| R11 ⬜ | An E2E flake: `liveClasses.spec.ts` "cancels the class…" timed out on the heading once (the page rendered just after); it passed on the rerun | Timing. |

### Live production check (read-only, 2026-10-28)

- Still the 22 Oct build (`index-BEvkzHqo.js`).
- `robots.txt` and `sitemap.xml` return HTML, and `/.well-known/assetlinks.json` is 404.
- `/api/public/academies/default` has no `invitationOnly`.
- No MX, SPF, DKIM or DMARC records.
- `x-frame-options` arrives twice and `referrer-policy` twice with conflicting values.
