# SyniastroLMS Flutter Progress

PROJECT STATUS: IN PROGRESS

This file is the recovery state for the autonomous Flutter workflow (`.claude/flutter/workflow.md`,
started with `/continue-flutter`). A new session reads **Session Checkpoint** first and resumes from its
**Next exact action**. The web UI build's record is `.claude/progress.md`; the SaaS phase's is
`.claude/saas/progress.md`; neither is edited from here.

---

## Session Checkpoint

```
Module:            LIVE UI E2E — smoke phase complete (layer C); FLUTTER-030 still waits on 028/C8
Status:            between phases — next is Deep QA (24 deferred scenarios) when asked
Current task:      —
Completed steps:   live E2E layer built; 70/70 smoke scenarios PASS on emulator-5554 across
                   FLUTTER-000…028; app bugs L1–L8 fixed with regression tests (see Live UI E2E)
Modified files:    (uncommitted, this workflow's only) apps/mobile/lib/app/routing/{app_router.dart,
                   redirect.dart,shells/app_shell.dart}, lib/features/auth/{application/session_controller.dart,
                   application/session_state.dart,data/auth_api.dart,data/auth_repository.dart,
                   presentation/screens/welcome_screen.dart}, lib/features/profile/presentation/screens/
                   profile_screen.dart; test/app/routing/{app_shell_test,public_next_test,redirect_test}.dart,
                   test/data/auth_api_test.dart, test/features/auth/session_controller_test.dart,
                   test/features/profile/profile_screen_test.dart, test/helpers/{app_harness,
                   fake_auth_repository}.dart; tool/contract_server.sh, tool/live_e2e.sh, tool/live_e2e/**,
                   .gitignore; .claude/flutter/e2e/**, .claude/flutter/progress.md
                   NOT this workflow's: the uncommitted Firebase work (pubspec.*, gradle files,
                   google-services.json, firebase.json, lib/firebase_options.dart, lib/app/{app,bootstrap,
                   config_error_app}.dart, lib/core/config/app_config.dart, lib/main_dev.dart, two tests)
Tests run:         worktree (HEAD + this workflow's files): format ✓ analyze ✓ 1833 host tests ✓;
                   working tree: 1 host failure (no_secrets_test) caused by the Firebase keys
Failing tests:     none of this workflow's
Decisions:         live layer on its own ports (relay :4200 → server :4201) and git-ignored
                   config/dev_e2e.local.json; APK under test built in a scratch worktree; no relaunch
                   between scenarios when the app is already signed in as the right account
Blockers:          none for the smoke phase. Environment: an IDE debug run twice installed lib/main.dart
                   over the E2E APK on emulator-5554 (the install-stamp guard stops the run when it happens)
Next exact action: commit this workflow's files by explicit path when asked; then Deep QA:
                   tool/live_e2e.sh run --tier deep
Updated:           2026-10-01
```

---

## Current Module

None. Every module that can be built without a human answer is done.

## In Progress

None.

## Completed Modules

### FLUTTER-000 Workspace Bootstrap & Tooling — completed 22 Sep 2026

**Built.** `apps/mobile` (Flutter 3.38.10 / Dart 3.10.9, project `syniastrolms_mobile`, Android + iOS
folders; iOS not built). Entry points `lib/main_{dev,staging,prod}.dart` → `lib/app/bootstrap.dart` →
`ProviderScope` → `SyniastroApp` placeholder (product name; replaced in 005). No API consumed.

**Files.** `pubspec.yaml`/`.lock`, `analysis_options.yaml` (flutter_lints + strict casts/inference/raw
types + the §29 rules), `build.yaml` (json_serializable explicit_to_json/checked), `config/{dev,staging,
prod}.json`, `android/app/build.gradle.kts` (flavors, SDK levels, R8 on release, key.properties-based
signing), `AndroidManifest.xml` (INTERNET, allowBackup=false, data_extraction_rules, cleartext off,
network_security_config), debug-only `network_security_config.xml`, `.gitignore` credential entries,
`README.md`, `tool/verify.sh`, `test/app/app_smoke_test.dart`, `test/architecture/*` (imports,
no hard-coded colours, no secrets + config key allow-list + HTTPS for non-dev, no plan names, no literal
UI strings — each with detector self-tests on known-bad samples), `integration_test/app_test.dart`,
empty `test/{unit,contract,data,features,golden,fixtures}`.

**Acceptance criteria — evidence.**
- analyze/format/test clean; dev APK builds and launches showing the placeholder → `tool/verify.sh
  --all-flavors` exit 0 (format 0 changes, analyze "No issues found", 18 tests passed); dev APK installed
  on `emulator-5554` (AVD Medium_Phone_API_36), `MainActivity` focused, screenshot
  `<scratchpad>/flutter-000-dev-launch.png` shows "SyniastroLMS"; integration smoke passed on device.
- Three flavors with distinct ids → `aapt2 dump badging`: `in.synilogictech.syniastrolms.mobile.dev`
  ("SyniastroLMS Dev", 1.0.0-dev), `….mobile.staging` ("SyniastroLMS Staging"), `….mobile`
  ("SyniastroLMS"); all minSdk 24 / targetSdk 36; installed package flags show no ALLOW_BACKUP.
- Root npm checks unchanged by this module → lint exit 0 before/after; format:check exit 1 before/after
  with the identical 9 pre-existing `apps/lms-react` files; typecheck 0 before, 2 after — every error is
  in `apps/api/src/lib/paymentGateways.ts` / `routes/paymentGateways.test.ts`, caused by another
  session's uncommitted `apps/api` + `schema.prisma` edits made during this module. `apps/mobile` is not
  an npm workspace (`npm query .workspace` → api, web, domain), contains no TS/`src`, and appears in no
  output. No ignore entry was needed.
- No file outside `apps/mobile/` and `.claude/flutter/` changed by this workflow → commit contains only
  those paths.

**Limitations / open.** Application id is a placeholder (C6); staging config points at production (no
staging host); release builds are debug-signed until a keystore is provided (C16).

### FLUTTER-001 Design System & Theme — completed 22 Sep 2026

**Built.** Celestial Ink in Flutter. `lib/core/theme/`: `tokens.dart` (the only colour literals;
§22.2 light/dark palettes plus the web's `faint`, shadow, scrim, media ground; `Space`, `Radii`,
`Motion`, `FontFamilies`), `tone.dart`, `AppColors` / `AppTypography` / `AppShadows` theme extensions,
`AppTheme.light()/dark()` (Material 3 scheme + component themes), `theme_context.dart`
(`context.colors/type/shadows/reduceMotion`). `lib/core/layout/breakpoints.dart`, `lib/core/format/ist.dart`
(fixed +05:30 wall-clock helpers used by the date field; FLUTTER-002 builds on it). Bundled fonts
(Fraunces 72pt 400/600/700, Plus Jakarta Sans 400–700) with `assets/fonts/LICENSES.md` (source, OFL,
SHA-256). gen-l10n with `lib/l10n/app_en.arb` (≈150 strings) and `context.l10n`.
`lib/shared/widgets/` (barrel `widgets.dart`): icons (`AppIcons`, `AppIcon` duotone), actions
(`AppButton` 4 variants/2 sizes/busy, `AppIconButton` + badge, `StickyActionBar`, `AppFab`), inputs
(`AppTextField`, `AppSearchField`, `AppSelectField`/`SelectSheet`, `AppSwitchRow` with locked reason,
`AppCheckboxRow`, `AppRadioGroup`, `AppDateTimeField` (IST), `AppFilePickerTile`, `FilterChipBar`,
`FormErrorSummary`), containers (`AppCard`, `SectionHeader`, `AppListTile`, `GroupedList`,
`KeyValueTable`, `AppDivider`), status (`StatusBadge` with a 63-kind registry ported from the web's
`statusRegistry.tsx` and every `*Meta.tsx`, `ProgressRing` with halo, `ProgressBar`, `KpiTile`,
`AvatarInitials`), charts (`Sparkline`, `TrendChart`, `ColumnChart`, `BarList`, list read-out toggle),
overlays (`AppDialog` + `showConfirmDialog` with acknowledgement and in-dialog errors,
`showAppBottomSheet`/`AppBottomSheet`/`FilterSheet`, `showAppSnackbar` with Undo), states
(`SkeletonBox/Card/List`, `DelayedLoading` 150 ms / 8 s, `EmptyState`(+`.noMatches`), `ErrorState`,
`OfflineBanner`, `PermissionDeniedView`, `FeatureUnavailableView`, `SubscriptionStateView`,
`NotFoundView`, `UnavailableLessonView`, `ConstellationArt`), learning (`CourseCover` — the web's four
SVG motifs ported to a painter, `LessonTypeIcon`, `CurriculumTree`, `LessonNavBar` with server
completion hint, `QuizQuestionCard` (no answer key), `RubricScorer`, `CertificateCanvas` shell,
`RankRing`, `StudyWeekBars`, `CountdownChip`). `lib/dev/gallery/` (entries registry + screen with
dark / 100·130·200 % / reduced motion / medium width), registered only by `main_dev.dart`.
`SyniastroApp` now uses the themes and localizations; no API consumed.

**Acceptance criteria — evidence.**
- Token table = §22.2 exactly → `test/core/theme/tokens_test.dart` "token table matches modules.md §22.2
  exactly" (every light/dark value); contrast ≥ 4.5:1 for 18 text pairs and ≥ 3:1 for 4 UI pairs in both
  themes, tone ink/soft pairs, WCAG formula checked against reference values.
- No hex literal outside `core/theme/tokens.dart` → architecture test tightened to that single file; passes.
- Every component has a gallery entry and widget coverage of states, semantics, 200 % text, dark →
  `test/shared/widgets/gallery_matrix_test.dart`: 47 entries × light/dark × 100/200 % on a 360 dp phone
  (any overflow/exception fails), with Flutter's `androidTapTargetGuideline` and
  `labeledTapTargetGuideline`, plus a completeness test that fails if any public widget class in
  `lib/shared/widgets` is missing from the gallery (it caught 4 on the first run); behaviour tests in
  `actions_inputs_test.dart`, `status_overlays_states_test.dart`, `learning_charts_test.dart`.
- Goldens (buttons, inputs, cards, lists, status badges, progress ring, KPI tile, course covers, dialog,
  bottom sheet, error/empty/permission/feature/not-found states) light + dark at compact width →
  `test/golden/components_golden_test.dart`, 30 baselines in `test/golden/goldens/`, reviewed by eye.
- Touch targets ≥ 48 dp → `expectMinTapTarget` helper (AppButton) and the tap-target guideline across
  every gallery entry.
- Device: dev APK on emulator-5554 → home → "Component gallery" → gallery renders (screenshots
  `<scratchpad>/f001-home.png`, `f001-gallery.png`, `f001-gallery-scrolled.png`), no flutter errors in
  logcat. Prod/staging entry points do not import `lib/dev` (test).
- Verification: `tool/verify.sh --all-flavors` → format 0 changes (70 files), analyze clean, 300 tests
  passed, dev/staging/prod debug APKs built.

**Defects found and fixed by the tests.** `_Dot` animation controller created lazily inside
`dispose()`; four components without gallery entries; disabled button label nearly invisible (now
muted on surface3, pair added to the contrast test); filled outline inputs cramped the always-visible
label (inputs are now outlined/unfilled); disabled switch indistinguishable from enabled.

**Limitations / open.** Goldens are macOS baselines (no CI exists — C16); `AuthImage` moves to
FLUTTER-007; `CertificateCanvas` content wiring is FLUTTER-014; `CountdownChip` takes pre-formatted
text (durations formatting is FLUTTER-002).

### FLUTTER-002 Core Infrastructure — completed 22 Sep 2026

**Built.** `lib/core/config/` — `Flavor` (moved from `lib/app`), `AppConfig` (dart-define values validated
at start-up: absolute URLs, HTTPS outside dev, no query/fragment/credentials, `ENV_NAME` must equal the
entry point's flavor) + `appConfigProvider`. `lib/core/logging/` — `Redactor` (the backend
`observe.ts` sensitive-key list and text patterns: JWT, Bearer/Basic, sk/rk/pk/whsec/rzp keys, token
query params, reset/invite links, password assignments, 13–19-digit card numbers; depth/size caps),
`AppLogger` (redacted, release keeps warn+, errors forwarded), `CrashReporter` + `CrashReport`
(redacted at construction) + `NoopCrashReporter` (C7). `lib/core/errors/` — the §10.3 `AppFailure`
sealed hierarchy with `FieldIssue` (path|field) and `Result`/`Ok`/`Err`/`AppResult`.
`lib/core/connectivity/` — `ConnectivityService` hint stream + `isOnlineProvider`. `lib/core/format/` —
`Money` (integer minor units, ISO digits from intl, en-IN grouping, unknown codes written as a code),
`formatCount`, `DatesIst` (the web's `format.ts` formats in IST, zone label, day keys, IST midnight,
query dates, greeting, relative time with the web's thresholds), `Durations` (web `formatDuration` /
`formatClock`). `lib/core/storage/preferences.dart` — typed non-sensitive preferences with
`clearUserScoped()`. `lib/app/` — `bootstrap` (guarded zone, `ErrorHooks` for `FlutterError.onError`
and `PlatformDispatcher.onError`, `ErrorBoundary.install`, config validation → `ConfigErrorApp`,
`initializeDateFormatting`, preferences), `appRoot(...)` shared with integration tests.
`lib/shared/widgets/errors/error_boundary.dart` (friendly crashed-route view, works above theme/l10n).
ARB: relative-time, duration, greeting, zone and error-boundary strings.

**Acceptance criteria — evidence.**
- Redactor masks each pattern, normal text untouched → `test/unit/logging/redactor_test.dart` (9 pattern
  cases, untouched sentence, deep key redaction, caps).
- `Money.format(399900, 'INR')` → `₹3,999.00`; zero-decimal (JPY), three-decimal (KWD), unknown (`ZZZ`)
  and malformed codes, negatives, `dropZeroFraction`, and 2^53−1 paise formatted exactly →
  `test/unit/format/format_test.dart` group Money. Only integer `~/` and `%` are used.
- 2026-09-22T18:30:00Z = 23 Sep 00:00 IST, day keys either side of midnight, `startOfDay`, `sameDay`,
  query dates → format_test group "IST dates".
- Uncaught errors reach `CrashReporter` redacted → `test/app/error_handling_test.dart` (framework +
  zone errors with a token and a Bearer header, fake reporter).
- l10n: gen-l10n runs in the build (`generate: true`, verify builds) and a localized string renders →
  error_handling_test "a localized string renders…".
- ErrorBoundary widget test → crashed widget shows the friendly view and Go home, never the exception.
- Config validation fails fast and readably → `test/unit/config/app_config_test.dart`; dev
  `ConfigErrorApp` shows the reason, other builds do not.
- Verification: `tool/verify.sh --all-flavors` exit 0 (91 files formatted, 0 changed; analyze clean;
  353 tests; 3 APKs); `flutter test integration_test -d emulator-5554` passed (real dev config read from
  dart-defines); dev APK launched standalone through `bootstrap` to its first screen in 4 s
  (`<scratchpad>/f002-launch.png`).

**Defects found and fixed.** ErrorBoundary overflowed at 200 % text in a bounded route (gallery matrix);
zone errors were invisible in debug builds while the reporter is a no-op (now presented in debug).

### FLUTTER-003 API Client & Contract Layer — completed 23 Sep 2026

**Built.** `lib/core/network/`: `ApiClient` (Dio; base URL from `AppConfig` keeping the `/api` mount,
10 s connect / 30 s send / 30 s receive, `Accept: application/json`, `get/post/put/patch/delete`,
`upload` with one `file` field, progress and no send timeout, in-flight tracking and
`endSession({except})`), interceptors (`RequestIdInterceptor` random `X-Request-Id`;
`AuthInterceptor` bearer for the API origin only with single-flight 401 handling that hands the
refused request back so it keeps its own failure; `RetryInterceptor` GET/HEAD and flagged-idempotent
PUT only, 2 retries with jittered backoff, network errors and 502/503/504; `ApiLogInterceptor`
debug-only method/path/status/duration plus a clock-skew note), `ErrorDecoder` (the §10.3 table,
including the declared-but-unissued `SUBSCRIPTION_PAST_DUE`, unknown codes falling back by status,
`issues` in both `path` and `field` shapes), `ApiException`, `TokenStore` seam, `json.dart` (UTC
converters, `enumOrUnknown`, `parseResponse`/`asJsonObject`/`asJsonList` → `ContractFailure`),
`ApiPath` (ids 1–64, URL-encoded, dot-only refused so Dio's URL normalisation cannot climb a
segment), `paging.dart` (`Paged<T>`, `PagedState<T>`, `PagedLoader<T>`), and providers
(`tokenStoreProvider`, `sessionExpiredHandlerProvider`, `apiClientProvider`).
First generated model: `lib/shared/domain/level.dart` (freezed + json_serializable).
Tooling: `tool/contract_server.sh start|seed|stop|status` (the real `apps/api` on a scratch SQLite
database, port 4100, refuses a SCRATCH inside apps/api) and `tool/capture_fixture.sh` (signs in as a
seeded role, captures the real response, scrubs tokens and e-mail addresses, writes a `.cmd.txt`
note). Fixtures captured: `health.json`, `catalog/levels.json`, `errors/{unauthenticated,validation,
not-found,bad-credentials}.json`.

**Acceptance criteria — evidence.**
- Every row of §10.3 with a fake adapter → `test/data/network/error_decoder_test.dart` (no-response
  problems incl. DNS/TLS/cancel; 400/401/402/403/404/409/413/429/502/5xx; unknown code falls back;
  generic 500 message dropped; malformed issues ignored) **plus the four real captured bodies**.
- Retry only for idempotent methods and retryable statuses; POST never retried →
  `test/data/network/api_client_test.dart` group "retry" (3 attempts on 503 with growing backoff,
  recovery, POST/PATCH/DELETE single attempt, PUT only when marked idempotent, no retry on 500/404).
- A 401 on three concurrent requests triggers the session-expired callback exactly once → same file,
  group "session expiry"; the refused request keeps its `UnauthenticatedFailure` while the others are
  cancelled; a later different token can expire again; a 401 without a token does not end the session.
- Upload reports progress and honours cancel → group "upload" (one `file` field, progress ends at 1.0,
  `sendTimeout` zero, cancellation decoded as `NetworkProblem.cancelled`).
- Fixture capture produces valid JSON against the running contract server → `200` for `/health` and
  `/catalog/levels` (see the `.cmd.txt` notes); contract test
  `test/contract/catalog_levels_test.dart` parses the captured response into `Level` and round-trips it.
- Paging → `test/data/network/paging_test.dart` (rows/total/counts, wrong shape → `ContractFailure`,
  refresh/loadMore/append/stop-at-total, empty page, failure keeps loaded items, no double load).
- End-to-end against the **real** API from the emulator → `integration_test/api_client_test.dart`:
  `/health`, `/catalog/levels` → `Level`, real 401 and real 404 decoded. 5 integration tests passed.
- Verification: `tool/verify.sh --all-flavors` exit 0 (codegen, format 111 files 0 changed, analyze
  clean, 400 tests, dev/staging/prod APKs).

**Defects found and fixed.** Ending the session cancelled the very request that received the 401, so
its caller saw "cancelled" instead of "session expired"; linking every request to a session token
leaked a listener per request (replaced with in-flight tracking).

**Backend contract notes.** 400 issues use `path` (zod), 409 checklists use `field`; 401 bodies carry
no `code`; wrong credentials and an unknown e-mail are the same 401 message;
`SUBSCRIPTION_PAST_DUE` is declared in `errors.ts` but nothing issues it yet.

### FLUTTER-004 Secure Session & Authentication — completed 23 Sep 2026

**Built.** `lib/features/auth/`: models (`UserProfile` with `UserRole` and the 24 `PermissionKey`s,
both with unknown fallbacks and `permissions` defaulting to empty — never to all; `AuthResponse`),
`SecureTokenStore` (flutter_secure_storage, key bound to the flavor), `AuthApi` (login, register,
me, forgot-password, reset-token check, reset, health — sending only what each route's zod schema
reads: never `role`, never a tenant), `AuthRepository` (`Result`, owns the token),
`SessionController` + `SessionState` (unknown / unavailable / signedOut(reason, message) / signedIn /
unsupportedRole) with restore, sign-in, register, sign-out, `handleSessionExpired` and
`refreshProfile`, the auth form controllers, validators and refusal copy, and the screens: splash
(with the brand halo and the offline retry), welcome, sign in, register, forgot password, reset
password, unsupported role. `lib/core/auth/session_cleanup.dart` is the registry other features add
their purge to. `lib/app/session_gate.dart` picks the screen from the session (FLUTTER-005 replaces
it with the router redirect) and `signed_in_placeholder.dart` stands in for the role shells;
`appRoot` now wires `tokenStoreProvider` to secure storage and the API client's 401 to
`handleSessionExpired`.

**Acceptance criteria — evidence** (integration tests run on emulator-5554 against the **real** API):
- Seeded learner, instructor and admin each sign in and land in the app, and signing out drops the
  token → `integration_test/auth_test.dart` "each seeded role signs in and lands in the app".
- A super admin is refused with no token kept → "a super admin is refused and no token is kept".
- Relaunch restores the session through `/auth/me` → "register, then a relaunch restores the session";
  the helper tears the tree down first, because pumping another `appRoot` reuses the `ProviderScope`
  and would have made the relaunch tests vacuous.
- An invalid token produces the session-ended sign-in → "a tampered token ends the session".
- A learner suspended through the real admin API is signed out on the next launch with the server's
  own message → "a learner suspended by the academy is signed out with the server's message".
- Forgot password shows the same confirmation for a known and an unknown address → widget test;
  the captured `auth/forgot-password.json` fixture shows the server's `{ok: true}` either way.
- No token or password in any log line → `test/features/auth/auth_security_test.dart` (sign-in,
  restore, reset-token check and reset with logging on; also proves a reset link is masked).
- Register calls `/auth/me` for the canonical profile and permissions → repository + fake asserts.
- Controller transitions (19), API service (paths/bodies/no `role`), screens and the session-driven
  navigation each have tests; contract tests parse the captured admin/instructor/learner profiles.
- Verification: `tool/verify.sh --all-flavors` exit 0 (455 tests, analyze clean, 3 APKs); screens
  checked on the device (`<scratchpad>/f004-welcome.png`, `f004-login.png`).

**Defects found and fixed.** The secrets architecture test flagged the localized label
`"fieldPassword": "Password"` — the pattern now requires the keyword to start the key. The relaunch
helper (above). `tool/contract_server.sh` now runs the documented `permissions:backfill` after
seeding and raises the local rate limits, because a test suite signs in far more often than a person.

**Backend contract notes.** A freshly seeded academy admin holds **no** permission keys until
`npm run permissions:backfill` is run — a real environment needs that step, and FLUTTER-006's
capability gates depend on it. A `/students` roster row nests the learner under `student`
(for FLUTTER-022). Wrong credentials and an unknown e-mail share one 401 message.

### FLUTTER-005 App Shell, Routing & Role Navigation — completed 23 Sep 2026

**Built.** `lib/app/routing/`: `routes.dart` (the whole §5.3 table as constants plus typed builders
that URL-encode every id), `route_access.dart` (`sectionOf`, `isKnownAppRoute`, `homeFor`, `canSee` —
the role stub FLUTTER-006 replaces), `redirect.dart` (the single redirect as a pure function, plus
`destinationAfterSignIn` which refuses an unknown or foreign `next`), `web_path_mapper.dart`,
`app_router.dart` (GoRouter: public routes, the learner shell and the staff shell as
`StatefulShellRoute.indexedStack`, dev-only routes from `devRoutesProvider`, not-found screen,
session-driven refresh), and `shells/` (`destinations.dart` — the tabs and overflow per role with
their branch indices; `app_shell.dart` — `NavigationBar` on phones, `NavigationRail` from 600 dp and
extended from 1024 dp, the More sheet, the notification bell, the offline banner and the §5.5 back
behaviour; `ComingSoonScreen`; `NotFoundScreen`). `lib/app/app.dart` now uses `MaterialApp.router`
and starts the session restore once; `session_gate.dart` is gone and the profile stub keeps the
sign-out until FLUTTER-017.

**Acceptance criteria — evidence.**
- Redirect matrix → `test/app/routing/redirect_test.dart`: {restoring, unavailable, signed out,
  expired, refused, learner, instructor, admin, super admin} × {public, learner, staff, admin-only,
  unknown}, including the `next` round-trip and its refusal of `//evil.example`, `https://…` and
  unknown paths.
- Tab stacks and back behaviour → `test/app/routing/app_shell_test.dart` asserts the **router
  location** after each tap, and that back returns to the first tab and then lets the app exit.
- `WebPathMapper` covers every path the backend emits → `web_path_mapper_test.dart`, written from an
  inventory of `apps/api/src` (`action.to`, dashboard `attention[]`/`events[]`, learner `upcoming[]`,
  instructor events, e-mail links): `/learn/:c(/lessons/:l)`, `/my-learning`, `/live(/:id)`,
  `/assignments/:id`, `/certificates/:id`, `/verify/:credentialId`, `/help`,
  `/notifications/preferences`, `/reset-password/:token`, and the `/teach|admin` set
  (`assignments/submissions/:id`, `assignments/review`, `students` with its query, `courses/:id`,
  `courses/:id/lessons|curriculum`, `live/:id`, `reports/enrolments`, `certificates/:id`,
  `instructors/:id`). Unknown paths, `/media/:id`, `/superadmin/*` and absolute URLs map to null, and
  every mapped route is checked against the real route table.
- Phone vs tablet → shell widget tests at 400×800, 900×1000 and 1200×900.
- Shell invariants → `destinations_test.dart`: every tab has a distinct branch, every destination is
  a real route its role may see, no duplicates, and an instructor is offered nothing admin-only.
- Verification: `tool/verify.sh --all-flavors` exit 0 (529 tests, analyze clean, 3 APKs); the 10
  integration tests still pass on the emulator against the real API with the router in place.

**Defects found and fixed.** Two tabs shipped without a branch index, so tapping them threw a null
check that the gesture handler swallowed — now the tabs carry their branch, the handler falls back to
a plain navigation, and `destinations_test.dart` guards it. A shell branch's default route cannot be
parameterized (`/my-learning/:tab`), so `/my-learning` now redirects to the first tab. The router's
splash ignored the "server unreachable" state, so the offline retry never appeared — the splash reads
the session itself. An expired session landed on the welcome screen instead of sign-in. In-shell stub
screens drew a second app bar.

**Known limitation.** Most destinations are `ComingSoonScreen` placeholders until their module lands;
they show in dev and are hidden from the More sheet in staging and prod (`built: false`). Each module
flips its own destination to `built: true`.

### FLUTTER-006 Authorization, Permissions & Entitlement States — completed 23 Sep 2026

**Built.** `lib/core/auth/capabilities.dart` — the `Capability` enum, each naming its permission key
and whether the backend guards it with `requirePermission` (admin only) or `requireStaffPermission`
(an instructor passes on role), plus `can()` / `capabilitiesOf()`. `lib/shared/entitlements/` —
`TenantEntitlements`, `UsageSummary`, `UsageLine`, `PlanSummary`, `FeatureKey`, `LimitKey`,
`SubscriptionState` (all with unknown fallbacks; `tenantId` deliberately unmodelled), `TenantPlanApi`,
`academyPlanProvider` (admins with `viewBilling` only, 5-minute cache, a refusal simply means "do not
prefetch"), `entitlement_refusal.dart` (`RefusalKind`, `refusalKindOf`, `refusalMessage`,
`RefusalView`), `restricted_banner.dart`, `capability_gate.dart`. Routing now decides access per
route: `requiredCapability(path)` + `canOpen(profile, path)` replaced `AppSection.adminOnly`, the
shells filter destinations by capability, and `/auth/me` and the academy plan are re-read on resume
(each throttled to five minutes). `lib/shared/domain/user_profile.dart` and
`lib/shared/session/current_user.dart` are the shared model and the seam the app fills.

**Capability table — verified against the backend, route by route** (`apps/api/src/routes/*.ts`,
`lib/permissions.ts`). `requireStaffPermission(key)` is `requirePermission(key, {roles:
['instructor']})`: an instructor short-circuits on role and never consults grants; an admin must hold
the key, read from the database on every request. The keys used **only** with `requirePermission`,
which an instructor can never pass, are `learners.suspend`, `instructors.manage`,
`instructors.status`, `catalog.categories.manage`, `certificates.templates.manage`,
`certificates.revoke`, `reports.instructors.view`, `settings.edit` — and `settings.view`, which is the
one key used both ways (`requireStaffPermission` on `GET /settings`, `requirePermission` on every
`/tenant` read, so **billing is admin-only**). Everything else is a staff key. Three corrections to
the assumptions in §5.3 followed: `instructors.view`, `reports.view` and `certificates.issue` are
staff keys, so an instructor is offered the instructor directory, reports and certificates; and
`GET /dashboard` itself is guarded by `reports.view`.

**Acceptance criteria — evidence.**
- Capability table unit-tested for instructor and admin → `test/unit/auth/capabilities_test.dart`
  (the table is checked against the audited admin-only key set; an instructor never passes an
  admin-only capability even when the profile lists the key; an admin holds exactly their grants;
  no grants means nothing; a fully backfilled admin holds everything; unknown keys grant nothing).
- Each refusal code renders its view with role-appropriate copy →
  `test/features/entitlements/refusal_test.dart` (permission, subscription required/expired/past-due,
  feature not included, limit reached; "Review plan" only for an admin who can read billing).
- Enforcement off → no banner; enforcement on → the refusal the app renders: the contract server was
  restarted with `ENTITLEMENT_ENFORCEMENT=on` and `POST /courses` and `POST /live` as the seeded admin
  both answered `402 SUBSCRIPTION_REQUIRED` ("This academy has no plan. Choose one to use this.") —
  captured as fixtures and asserted in `test/contract/entitlements_test.dart`.
- The restricted banner on the real API → `integration_test/entitlements_test.dart`: the seeded
  academy is served no plan, so the admin sees it, and an instructor and a learner never do.
- The prefetch refusal path → the captured `403 PERMISSION_DENIED` an instructor gets from `/tenant`;
  `academy_plan_test.dart` proves the provider asks only for admins with the billing key, caches for
  five minutes and treats a refusal as "no prefetch".
- Verification: `tool/verify.sh --all-flavors` exit 0 (578 tests, analyze clean, 3 APKs); 13
  integration tests on emulator-5554.

**Defects found and fixed.** `core` and `shared` were importing the auth feature — the architecture
test caught it, and `UserProfile` moved to `shared/domain` with a `currentUserProvider` seam.
An admin whose grants do not cover their own home would have been redirected in a loop. The
navigation bar asserts two destinations, so a shell whose every tab is capability-gated crashed while
signing out (when the profile is briefly null) — one tab is always kept. `tool/verify.sh` now formats
generated files after code generation, which the strict format check had started failing on.

**Watch item.** The SaaS session is building SAAS-020 "Sessions: Logout, Revocation & Account
Self-Service" — the backend capability FLUTTER-004 recorded as missing (B1 logout/revocation, B3
profile update and password change). FLUTTER-017 should re-read `apps/api` before assuming they are
still absent.

### FLUTTER-007 Media Foundation — completed 23 Sep 2026

**Built.** `lib/core/media/` — `MediaRules` mirrors the server allow-list in `apps/api/src/lib/media.ts`
(video `mp4|webm|mov` ≤ 500 MB and staff only, `pdf` ≤ 25 MB, `png|jpg|jpeg|webp` ≤ 5 MB, **MIME and
extension must both match**) and returns a typed `MediaRejection`; `MediaUrlResolver` turns the
server's `/media/<id>` into an absolute URL and refuses any other host, scheme or port, so the bearer
header never leaves the API origin; `MediaCache` keeps a `CacheManager` per signed-in person plus a
`syniastro_media` temp folder and registers `purge()` with `sessionCleanupProvider`.
`lib/core/network/cancellation.dart` wraps `CancelToken` as `RequestCancellation`, and
`ApiClient.downloadBytes` streams a media body with progress. `lib/features/media/` — `UploadedMedia`
DTO, `MediaApi` (`upload` multipart with progress and cancel, `bytes`), `MediaUploadController`
(pre-check → upload → progress / cancel / retry-keeps-the-file), `pdfDocumentProvider` (download to a
temp file, cancelled and deleted on dispose), and the widgets `AuthImage`, `AppVideoPlayer`,
`PdfViewerScreen`, `MediaUploadTile`. Two packages were appended to modules.md §25.2 with reasons
(`flutter_cache_manager` for the per-user image store, `path` for temp-file joins).

**Acceptance criteria — evidence.** All against the real API on the scratch database
(`tool/contract_server.sh`), `integration_test/media_test.dart`, 18 integration tests green on
emulator-5554:
- A learner image upload succeeds and reads back (`POST /media/upload` → `201`, `url` is
  `/media/<id>`, `kind: image`), and a learner video upload is refused with the server's exact words:
  "Only instructors and academy admins can upload video."
- Range requests — what seeking depends on — were proven end to end: staff-uploaded video read by a
  learner with `Range: bytes=100-199` answered **HTTP 206** with exactly the 100 expected bytes.
- One learner cannot read another's upload (**404**, not 403), and an unauthenticated read is refused
  401.
- Oversized and wrong-type files are refused before any request, with the server's own wording →
  `test/unit/media/media_rules_test.dart` (25 cases, including a `.mp4` file sent as `image/png`).
- Sign-out empties that person's image cache directory and removes the temp files →
  `test/features/media/media_cache_test.dart`.
- Widget states (image skeleton/fallback, player buffering/error/ended, upload progress/failed/
  cancelled) → `test/features/media/media_widgets_test.dart` (18 tests).
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓ (196 files, 0 changed),
  `flutter analyze --fatal-infos --fatal-warnings` ✓, **627 tests** ✓, 3 flavor APKs ✓.

**Defects found and fixed.** The architecture test caught Dio leaking out of `core/network` and
`data` into the application and presentation layers — the PDF download moved behind a provider and
cancellation now travels as `RequestCancellation`. `MediaApi.bytes` was synchronous enough to throw
before returning its future, so a bad id crashed the caller instead of failing the future.

**Schema-drift recovery.** The SaaS session added `User.tokensValidAfter` to `prisma/schema.prisma`
and regenerated the client without a migration, so every login against the contract server answered
500. `tool/contract_server.sh` now runs a `sync_schema` step (`prisma db push --skip-generate`)
against the **scratch database only** — no migration file is written into `apps/api`, which stays
read-only for this workflow.

**Limitation.** The seed creates no media assets and no licensed sample video exists in this
environment, so **codec playback of a seeded lesson video was not exercised**; the streaming path it
depends on was proven instead with real authenticated 206 range responses from the API. Playback on a
real lesson is verified in FLUTTER-010 once seeded lesson content exists.

### FLUTTER-008 Public Experience — completed 23 Sep 2026

**Built.** Three features, all unauthenticated. `features/public_catalog/` — `CatalogApi` over
`GET /catalog/{levels,categories,instructors,courses,courses/:slug}`, the models
(`CatalogCourse`, `CatalogChapter`, `CatalogLesson`, `LessonContent`, `Price`, `CatalogCategory`,
`CatalogInstructor`), the filter/search providers, and the screens `/catalog`, `/catalog/:slug`
and `/catalog/:slug/preview/:lessonId` with `CourseCard`, `CourseRating` and `InstructorRow`.
`features/verify/` — `VerifyApi`, `CredentialId`, `/verify` and `/verify/:credentialId` with the
`VerificationCard`. `features/help/` — `HelpApi`, the audience seam, `/help`, `/help/:categoryId`,
`/help/article/:slug`, and the two legal screens. Shared additions: `ArticleBody` (the tiny markup
dialect the web's `ArticleBody.tsx` renders, with its own gallery entry), `AsyncView` (one value,
its refusal and its skeleton — the three states every later screen needs) and
`Money.formatMajor`. The welcome screen now leads to all three, and a validated `next` carries a
visitor from a course back to that course after signing in.

**Clarification A2 settled — course prices are whole rupees.** `packages/domain/src/settings.ts`
validates the academy's default price "between ₹0 and ₹5,00,000", the settings screen labels the
field "Rupees", and the web renders `course.price.amount` with `formatINR` (no decimals). The seed
writes `2999` for a ₹2,999 course. So `Course.price.amount` is a **major**-unit amount, unlike
every subscription and invoice amount on the platform, which stay in minor units through
`Money.format`. `Money.formatMajor` exists for exactly this one case and says so.

**Acceptance criteria — evidence.** `integration_test/public_test.dart`, 12 new tests against the
real API on the scratch database; 30 integration tests green on emulator-5554 in total.
- The catalogue lists exactly the seeded published public courses, and a level narrows it **on the
  server** — `courses(levelId:)` returns a strict subset, every row on that level.
- A free preview plays for a visitor: an instructor opened a reading lesson with a real
  `PATCH /courses/:id/lessons/:id {isPreview:true}`, and the signed-out catalogue read then carried
  its article body; the widget test renders it (`test/features/public_catalog/preview_lesson_test.dart`).
  A lesson that is not a preview shows "Enrol to watch this lesson" and **no content is requested** —
  asserted on the recorded request list.
- `SA-JY-2026-00142` verifies; `NOPE-1` and the seeded **pending** `SA-JY-2026-00231` both answer the
  same "No certificate matches this credential ID."; revoking `SA-JY-2026-00198` through the real
  admin endpoint then verifies as revoked, with the academy's reason.
- The help hub, a topic and an article all render from the server, and the audience decides what is
  served: a visitor is sent `audience=all` and never sees the learner article.
- Every state is covered by a widget test: catalogue skeleton / empty / no-matches / offline /
  server error with a working retry; course detail for a visitor, a learner and a missing slug;
  preview playable / locked / no file attached / media needs a session; verification valid /
  revoked / expired / not found; help empty, search-empty and article-not-found.
- Navigation round trip: welcome → catalogue → course → "Sign in to enrol" →
  `/login?next=%2Flearn%2F<courseId>` → signed in → `/learn/<courseId>`
  (`test/app/routing/public_next_test.dart`), with an off-app `next` and a `next` this learner may
  not open both falling back to home.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓ (243 files, 0 changed),
  `flutter analyze --fatal-infos --fatal-warnings` ✓, **722 tests** ✓, 3 flavor APKs ✓.

**Defects found and fixed.** Riverpod 3 retries a failed async provider **on its own**, up to ten
times with backoff, for any error that is not a Dart `Error` — so a refusal sat behind about half a
minute of silence before the error state ever appeared, and stacked on top of the API client's own
retry policy. A widget test that expected the error state is what exposed it. The app now sets
`ProviderScope(retry: noProviderRetry)`, leaving one automatic policy (`RetryInterceptor`:
idempotent reads, 502/503/504, twice) and one deliberate one — the person pressing "Try again".
The architecture test then caught the new screens importing their feature's `data/dto/` directly;
each application layer now re-exports the models it hands to its screens.

**Not built here, with the reason.** The spec's "share course link
(`WEB_BASE_URL/courses/:slug`)" is not implemented: `apps/web/src/app/router.tsx` has no public
per-course route — `/courses` is the Explore list — so that link would 404. Sharing waits for
`share_plus` in FLUTTER-014 and a public web course page (recorded under Known Issues).

### FLUTTER-009 Learner Home & My Learning — completed 23 Sep 2026

**Built.** `shared/domain/progress.dart` — `ProgressState`, `LessonProgress`,
`CourseProgressSnapshot`, `ProgressSummary`, `Enrollment` and `NextLesson`, and
`shared/domain/learning.dart` — `LearnerCourse` and `SavedCourse`, the shape `/learning/home`,
`/learning/courses` and (from FLUTTER-010) `/learning/courses/:id` all return. The course model
moved out of the public-catalogue feature into `shared/domain/course.dart` in its own commit
(190e1b6), renamed to match `packages/domain/src/catalog.ts`. `features/learner_home/` —
`LearningApi`, the providers, and the two screens: `/home` (greeting, Continue learning, Coming up,
Your courses, This week, Recently viewed — §22.7's order) and `/my-learning/:tab` (in progress,
completed, saved). Both are shell bodies: the shell draws the scaffold and the app bar.

**Nothing is worked out on the device.** The percentage, what counts as complete, which lesson is
next, which tab a course belongs in and how urgent an upcoming item is all come from the server.
The contract test pins the difference: the seeded dasha course is 1 of 4 lessons done but **32 %**,
because the server weights by lesson minutes — a client counting lessons would show 25 %.

**Acceptance criteria — evidence.**
- Home shows the seeded learner's real courses, progress, next lesson, upcoming items and seven
  days of study minutes — `test/contract/learning_home_test.dart` against the captured
  `/learning/home`, and `integration_test/learning_test.dart` against the live API.
- Resume opens exactly the server's `next` lesson →
  `test/features/learner_home/learner_home_screen_test.dart` asserts the router lands on
  `/learn/<courseId>/lessons/<nextId>` taken from the response, and the integration test checks
  that lesson is one of the course's own and not already completed.
- The tabs partition by `enrollment.status` and the server's own saved list; an expired enrolment
  stays under "In progress" with "Access ended on 1 Sep 2026" rather than vanishing from both tabs.
- Priority order on a phone is asserted by comparing the sections' y positions; from the medium
  breakpoint up the courses lay out two to a row.
- An upcoming item opens the route its **web** path maps to, and a path the app does not own
  (`/admin/settings/danger`) is not followed at all (§5.4, §18).
- States: skeleton, empty ("Your learning starts here" → Explore), server error with a working
  retry, offline, and 200 % text.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓ (264 files, 0 changed),
  analyze ✓, **766 tests** ✓, 3 flavor APKs ✓, 38 integration tests ✓ on emulator-5554.

**A backend change landed mid-module: SAAS-023 Media Security.** Two rules in `apps/api` changed
under FLUTTER-007's feet, and the integration tests caught both:
1. An upload's **first bytes** must match its extension (`lib/media.ts` `matchesSignature`). The
   app's `MediaRules` claims to mirror the server's allow-list, so it now mirrors this too:
   `MediaRules.matchesSignature`, a `MediaRejection.contents` carrying the server's own wording,
   and the picker reads the first 16 bytes when the file is chosen — so a renamed file is refused
   before the upload rather than after it. Reading the head happens at pick time, not inside
   `uploadPicked`, so nothing is awaited before the pre-check's answer is published (an await there
   loses the state when the auto-disposed controller has no listener).
2. A learner may read a staff file **only where it is placed** — a published lesson of a course
   they are enrolled in, a published free preview, or a published assignment's attachment
   (`lib/mediaAccess.ts`). "Staff media is readable by any signed-in account" is no longer true, so
   that FLUTTER-007 test was rewritten: an instructor uploads a video, places it in the seeded
   free-preview lesson, and the learner then streams it and gets a real 206 for
   `Range: bytes=100-199`. A second test pins the new rule: a staff upload nobody has placed
   anywhere is a 404 for a learner.

**Defects found and fixed.** "Coming up" overflowed at 200 % text — the chip's header row and the
strip's fixed height both now follow the text scaler. The My Learning screen repeated the title the
shell's app bar already shows.

### FLUTTER-010 Explore & Enrollment — completed 23 Sep 2026

**Built.** `features/explore/` — `/explore`, the academy's catalogue read by someone signed in: the
same `GET /catalog/*` routes the visitor catalogue uses (through the public-catalogue feature's
barrel), with the courses this learner already holds marked, and every card opening their own view
of the course. `features/course_learning/` — `CourseLearningApi` (`GET /learning/courses/:id`,
`POST …/save`, `POST …/enroll`), `LearnerCourseDetail`, the `CourseActionsController`, and
`/learn/:courseId`: the overview with the price, the facts, the outline, the instructors and a
sticky bar holding **Enrol** and Save. Once enrolled the same page shows progress instead of a
price and the bar is gone (FLUTTER-011 fills in the rest).

**Nothing about a course is the app's to say.** Saving and enrolling both send **no body at all**,
asserted in `test/data/course_learning_api_test.dart`; the price, the source (`self`) and the
status come back from the server. The academy's enrolment policy is its own: with `approval` set
through the real settings endpoint, enrolling answers 409 and the app shows the academy's sentence
unchanged, and nothing is created.

**The placeholder enrolment.** `GET /learning/courses/:id` always sends an `enrollment` object; for
someone who is not enrolled it has `id: ""` and `enrolledAt: ""`. An empty date would have crashed
the screen through `DateTime.parse`, so `EmptyAsNullUtcDateTimeConverter` reads it as no date and
`Enrollment.isPlaceholder` names the case — but the response's own `enrolled` flag is what decides,
never the placeholder.

**Acceptance criteria — evidence.**
- Enrolling moves the course into Home and My Learning without a restart →
  `test/app/enrol_flow_test.dart` signs in, walks Explore → course → Enrol → confirm, and then
  opens My Learning, asserting the workspace was read again; the controller test pins the
  invalidation.
- Saving toggles and survives a fresh read → `integration_test/enrollment_test.dart` against the
  real API; the widget test shows the bookmark moving before the round trip and going back when the
  server refuses.
- With the academy's policy set to `approval` on the local server, enrol shows the policy message
  and no enrolment appears — the integration test sets it through `PUT /settings/general` as the
  seeded admin and restores it afterwards.
- The price is display only, in whole rupees (A2, D-008-1).
- States: explore skeleton, empty, filter-empty, error; overview loading, not-found, enrolled;
  enrol busy and refused; save rollback; both actions disabled offline.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓ (279 files, 0 changed),
  analyze ✓, **798 tests** ✓, 3 flavor APKs ✓, 43 integration tests ✓ on emulator-5554.

**Defects found and fixed.**
1. Enrolling invalidates the learner's workspace while Explore is still mounted in the shell's
   indexed stack. A provider **derived** from `learnerCoursesProvider` was then notified while
   another screen was flushing that same provider mid-build, and Flutter reported
   "setState() called during build". The two derived providers became plain functions over the
   workspace, read where they are used; the end-to-end enrol test is what caught it.
2. Before enrolling, tapping a free preview opened the *learner* lesson route, which the server
   would have refused — it now opens the public preview screen, and anything else says what
   unlocks it.
3. The widget-test harnesses ran with animations on, so a skeleton's repeating shimmer meant
   `pumpAndSettle` could hang; under load a course test failed for that reason alone. The harness
   now disables animations, as the component matrix already did — which immediately exposed that
   the catalogue's offline test had been passing only because the shimmer kept it pumping through
   the client's retry backoff. Both offline tests now let that time pass explicitly.

### FLUTTER-011 Course Learning & Lesson Player — completed 23 Sep 2026

**Built.** `/learn/:courseId/lessons/:lessonId` — the player: the lesson header (type, number,
"5 of 7", duration, and "Completed on …" once it is done), the body by type, the notes, the
bookmark, the curriculum in a sheet, and `LessonNavBar` with Previous · Complete-or-the-rule ·
Next. Bodies: video through FLUTTER-007's player, resuming at the server's `positionSec` and
reporting back; reading and practice through `ArticleBody`; documents through the PDF viewer; an
assessment shows the quiz it delivers and the learner's best score; an assignment shows its state
and opens it; a live lesson shows when it starts. The enrolled course page gained "Next up", the
course's assignments, and how close the certificate is, criterion by criterion.
`shared/domain/course.dart` grew the quiz, assignment and live content blocks and `LessonSettings`;
`LessonView`, `CompleteResult` and the lesson endpoints live in `features/course_learning`.

**Nothing is decided here.** The app never unlocks a lesson, never marks one complete before the
server's `CompleteResult`, and never works out the percentage. A 409 from `complete` is not an
error to apologise for — it is the academy saying what is still missing, so it becomes the hint
where the button was: "Watch at least 90% of the lesson to complete it.", "Pass the quiz to
complete this lesson.", "Write your working in the notes to complete the exercise." — each captured
from the real API.

**Acceptance criteria — evidence.**
- Every seeded lesson type renders, and the locks match the server's snapshot: a fixture per type
  (`test/contract/lesson_view_test.dart`) and a live sweep of all seven lessons of the seeded
  course (`integration_test/lesson_test.dart`).
- A locked lesson shows only the academy's reason, with no body, no nav bar and no notes; its own
  `next` is locked too.
- Watching past the threshold completes the lesson **through the server**: the integration test
  reports a full position and the next read comes back `completed` with a `completedAt` — the app
  asked for nothing.
- Complete on a `passed`-rule lesson before passing shows the server's sentence, live and in the
  widget test.
- Notes save (debounced, and on demand) and come back with the lesson; the bookmark toggles and is
  remembered — both against the real API.
- Chapter and course moments appear only when `CompleteResult` says so: the course moment is a real
  captured response (Priya finishing a two-lesson course), and the widget tests show a dialog for
  the course and an announcement for a chapter.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓ (290 files, 0 changed),
  analyze ✓, **847 tests** ✓, 3 flavor APKs ✓, 51 integration tests ✓ on emulator-5554.

**What this module deliberately leaves for its own modules.** Taking a quiz is FLUTTER-012, so an
assessment lesson shows the quiz's shape and the learner's best score and says what completing it
needs; handing in an assignment is FLUTTER-013, so the player links to it; the live class's phase
clock and Join are FLUTTER-014, so a live lesson shows when it starts. None of these is a stub
standing in for missing data — each shows what the server sent.

### FLUTTER-012 Learner Quizzes & Assessments — completed 29 Sep 2026

**Built.** `shared/domain/quiz.dart` — the quiz as the **learner** is served it, with no field for
an answer key at all: `correct`, `acceptedAnswers` and `explanation` are not modelled, so a model
that cannot hold a key cannot leak one. `features/assessments/` — `AssessmentsApi`
(`GET /learning/assessments`, `POST …/quiz-attempt`), `AssessmentRow`, the `QuizTakerController`
(intro → questions → review → the server's verdict), `/assessments`, and the taker itself, which
the lesson player hands an assessment lesson to. All four question types render through
`QuizQuestionCard`: single, true/false, short answer and multiple choice.

**Nothing is marked here.** The attempt goes to the server, which scores it and answers the JSON
literal `null` for "not passed" or a `CompleteResult` for "passed" — the same completion that
finishing a lesson gives, so passing a quiz can finish its chapter and its course. A 409 is the
academy speaking ("You can try this quiz again in 24 hours.", "You have used all 3 attempts for
this quiz.") and is shown unchanged.

**A real defect found by testing against the live API.** A choice answer must be sent as a **list**
of option ids. `scoreAttempt` reads `(answer as ID[])[0]`, so a bare string is read character by
character: `'a'` scored correct by accident because its first character is the option id, and
`'false'` scored **incorrect**. Reading back `/quiz-attempts` question by question is what showed
it. The controller now sends a one-element list for single and true/false, and the API, controller
and integration tests pin the shape. Recorded for the backend owners as finding 12.

**Acceptance criteria — evidence.**
- The seeded quiz can be taken end to end, and a deliberately wrong attempt comes back as the
  literal `null` with the attempt counted; the seed file's own answers (taken from
  `apps/api/prisma/seed.ts`, never from the API payload) pass, complete the lesson and open the
  next chapter in the server's snapshot — `integration_test/quiz_test.dart` against the real API.
  The academy's retake wait and attempt cap are relaxed through the real settings and quiz
  endpoints for the length of that test and put back afterwards, so it is repeatable.
- The learner quiz DTO drops `correct`, `acceptedAnswers` and `explanation` even when they are
  present in the JSON — `test/contract/quiz_test.dart`, which round-trips a question carrying all
  three and asserts the model keeps only `id, type, prompt, options, points, required`. The live
  test asserts the same of what the route actually sends.
- The countdown is a display: it counts down and, at zero, takes the attempt to the review rather
  than submitting it — a widget test pumps the academy's fifteen minutes through.
- All four question types render and are answerable, with the review reporting what is still
  unanswered and allowing submit anyway (the server marks it, not the app).
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓ (307 files, 0 changed),
  analyze ✓, **883 tests** ✓, 3 flavor APKs ✓, **55 integration tests** ✓ on emulator-5554.

**The 24 September blocker, and what it turned out to be.** Every `flutter test integration_test`
run timed out at twelve minutes while loading, including files that had been green hours earlier.
Two separate things were wrong. A corrupt `build/` directory was breaking the **host** suite too —
`flutter clean` fixed that. The device side was a wedged `qemu` process: once it was killed and the
emulator launched fresh, the same suite ran in under twelve minutes. Nothing in the app was at
fault, and no test was changed to make it pass.

**Two test-environment defects fixed at the root.**
1. `tool/contract_server.sh` never provisioned the platform Super Admin. It is deliberately not
   seeded — `apps/api/scripts/create-superadmin.ts` creates it once per environment from the
   environment — so FLUTTER-004's "a super admin is refused" test only ever passed because an
   earlier session had run that script by hand, and it failed as soon as the scratch database was
   rebuilt. `seed` now provisions it, and there is a `superadmin` subcommand.
2. The widget-test harness let the API client's retry policy wait in real time, so a controller
   test that counts retries failed under a loaded full-suite run and passed on its own. The harness
   now gives the client a no-op backoff: the policy is still exercised, the waiting is not.

### FLUTTER-013 Learner Assignments — completed 29 Sep 2026

**Built.** `features/assignments/` — `AssignmentsApi` (`GET /learning/assignments`,
`GET …/:id`, `PUT …/:id/draft`, `POST …/:id/submit`), the `LearnerAssignment` models,
`AssignmentWorkController`, `/assignments` (every course's coursework, in the server's own order:
soonest deadline first) and `/assignments/:assignmentId` — the brief through the article renderer,
the instructor's attachments (opened in the app's PDF viewer or an image sheet, since media is
authenticated), the rubric with its points, a work area for the assignment's own `format`, the draft
status line, a sticky Save draft / Submit bar, what was handed in, and the reviewer's verdict.

**The work area is the server's.** It starts from what the academy holds — the saved draft, else the
work of a submission the reviewer sent back — and starts again whenever that changes, so handing in
clears it. Nothing is kept on the device (§15): typing is saved to the server 3 s after it stops, on
demand, and on the way out, and what is shown as "Draft saved" is the server's own `savedAt`. Off the
network the work simply stays unsaved and says so, and Submit is disabled.

**Two spec corrections, found by reading the route and testing it.**
1. `wordLimit` **is** enforced server-side — the submit route calls `validateSubmission`, which
   refuses a longer answer — contradicting the spec's "display; server does not enforce, §28.4.3".
   The app treats it as a rule, and a test pins the server's own sentence.
2. A hand-in may carry at most **3** files (`MAX_SUBMISSION_FILES`), not the 20 the route's schema
   allows: the schema caps one request, the domain caps the hand-in. A draft may hold more.

**A returned hand-in.** The documented quirk holds on the live server: it arrives with
`state: draft` and `submission.review.status == 'returned'`, and its review carries `score: 0`,
which is not a grade. The app shows "Returned for changes", never that zero, and offers "Submit
again" starting from the work that came back.

**Acceptance criteria — evidence.** `integration_test/assignment_test.dart`, against the real API on
the scratch database (7 tests, all green, and repeatable — the setup has the seeded instructor return
any hand-in an earlier run left, through the real review route):
- A draft of written work **+ an uploaded PDF + the birth chart** saves and reloads from the server,
  with the file's name read back from the stored upload rather than from the request.
- Handing the chart work in succeeds and the server says `submitted`, with the draft cleared; the
  same is true of the row read fresh from the list.
- Grading it as the seeded instructor (`meenakshi@syniastrolms.test`, `POST
  /assignments/submissions/:id/review` with `decision: graded`) shows the score and the feedback on
  the learner's next read — 78 of 100, above the academy's pass mark of 60.
- An empty hand-in is prevented client-side (the widget test asserts Submit is disabled with nothing
  written) and the server's 409 — "Add your work before submitting." — is shown as it stands if
  anything gets past that.
- A returned submission is resubmitted: attempt 2, waiting for review.
- A file that is not the learner's own upload is refused by `ownFiles` ("One of the files is not an
  upload of yours."), which is why the work body carries the stored file exactly as the media route
  returned it.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **928 tests** ✓, 3 flavor APKs ✓; 7 assignment integration tests ✓ on emulator-5554.

**Two shell destinations were still marked unbuilt.** `/assignments` is this module's, and
`/assessments` had been left `built: false` by FLUTTER-012 — which hides a finished screen from the
learner's More sheet in staging and prod, where unbuilt destinations are not shown. Both are now
`built: true`.

### FLUTTER-014 Learner Certificates & Ranks — completed 29 Sep 2026

**Built.** `shared/domain/certificate.dart` and `shared/domain/rank.dart` — the certificate, its
template, the academy's criteria and the rank ladder, in one place: the course page's own criterion
model was folded into them, so there is a single definition of "how close am I". `features/
certificates/` — `CertificatesApi` (`GET /learning/certificates`, `GET …/:id`, `POST …/:id/claim`,
`GET /learning/rank-ladder`), the `ClaimController`, `/certificates` (issued · pending · working
towards), `/certificates/:certificateId` (the certificate drawn on `CertificateCanvas` from the
academy's template, everything it is printed from, and Claim / Share / Open the verification page)
and `/ranks`.

**The academy issues; the app asks.** Claiming sends no body at all — no status, no date — and the
route answers with the issued certificate, which is what the screen then shows. A refusal is the
academy's own sentence. The verification link is built from `WEB_BASE_URL` and the credential id and
is the **only** thing shared: the learner's e-mail is not modelled anywhere a certificate is read,
though the route sends it.

**Two things the academy does not publish, and are therefore not shown.**
1. `/learning/rank-ladder` sends `standing.achieved` and `standing.progress` as empty objects
   (finding 13), so the ladder shows what each rank **requires** and says plainly that the academy
   does not publish how far along the learner is. No fraction is invented for the ring.
2. No learner-reachable endpoint carries the academy's own name (finding 14), so the certificate's
   header shows the seal alone rather than a name this app made up.

**No download.** The server returns certificate data only — there is no PDF or image endpoint — so
the app offers sharing and verification and does not offer a download it cannot produce (the
module spec's B8-like note).

**A latent parse failure fixed while passing.** `IssuedCertificateDto.hours` was an `int`, but the
academy rounds study hours to the nearest **half** hour (`hoursFor`), so a 6.5-hour course would
have failed to parse and broken the public verification screen. Hours are a `num` now, in both the
verify feature and the new models, and the string that prints them takes one.

**Acceptance criteria — evidence.**
- The seeded issued certificate renders on the canvas with the template's own fields — heading,
  statement, learner, course, credential id, `emerald` accent, both signatories, and "91%" and
  "6 hours" because that template prints both. A widget test reads them off the canvas; goldens in
  `test/golden/goldens/certificate_canvas_{portrait,landscape}_{light,dark}.png` show the paper at
  360 dp portrait and in landscape, and a test proves it keeps its proportions at 200% text.
- Pending → claim → issued, for real: `integration_test/certificate_test.dart` completes a short
  seeded course lesson by lesson, the academy creates the certificate as **pending** (its own
  `autoIssue: false`), the learner claims it, and it comes back issued with a credential id and an
  issue date — then verifies publicly, signed out, through `/certificates/verify/:credentialId`.
  Claiming it a second time is refused. A certificate cannot be made pending again, so the test
  takes the next learner and short course that has none yet and says so clearly if the scratch
  database has been used up.
- The share sheet is handed exactly `https://web.test/verify/SA-JY-2026-00142` and a subject naming
  the certificate — asserted through a `core/platform/share.dart` seam, with nothing about the
  learner in it.
- The rank ladder shows the seeded standing: the current rank, the next, and what it asks for.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **970 tests** ✓, 3 flavor APKs ✓; **66 integration tests** ✓ on emulator-5554.

**The emulator was replaced mid-module.** `emulator-5554` disappeared and a physical phone appeared
in its place; a fresh `emulator -avd Medium_Phone_API_36` brought it back and the suite ran clean.
Nothing in the app was involved.

### FLUTTER-015 Learner Live Classes — completed 29 Sep 2026

**Built.** `shared/domain/live_class.dart` — the class, its agenda, its meeting and its recording,
with `deriveLiveClassPhase` and `JOIN_WINDOW_MIN` ported from the domain package.
`features/live/` — `LiveApi` (`GET /live/learner`, `POST /live/:id/register`), the registration
controller, `/live` (live now · upcoming · recordings) and `/live/:liveId`.

**The room opens on the clock, not on a refetch.** A `liveClockProvider` ticks every 30 s while a
live screen is on, and every row reads its phase from that clock. A class sixteen minutes away shows
a seat to take; two minutes later, with **no further request**, it offers Join — a widget test
drives the clock through the boundary and asserts the request count did not move. The server's own
`phase` is still what a row arrives with; the app only carries it forward.

**Joining is an external link and nothing else.** Only an `https` link is ever opened, through
`core/platform/external_link.dart`, and the host is named in a confirmation first ("This opens
meet.example.com outside the app"). The academy's own room carries no link at all (B12), so the app
says so rather than offering a button that cannot work. Every seeded class is a `room`.

**Clarification A1 is settled.** The write schema names `meeting.url`, but `validateLiveClass` reads
`meeting.link` and the route stores whatever came in. Sending only `url` is refused —
"Check the class details before scheduling." — and `link` is what works; the integration test asserts
both against the live server (finding 15).

**Three more things the route does not give a learner** (findings 16–18): a recording carries only
its length and its expiry, with no address to play it from; the counts on a learner's own row are
their own registrations, not the class's, so seats left can only come from the register answer; and a
**cancelled** class is in none of the route's three buckets, so it simply disappears from the
schedule. The app says what it can and invents nothing.

**Acceptance criteria — evidence.** `integration_test/live_test.dart`, against the real API (6 tests):
- The seeded classes arrive in the right buckets, every row naming its course, instructor and phase.
- A seat is taken and given up again, and the academy's own `spotsLeft` moves 40 → 39 → 40; the
  schedule's `registered` flag follows.
- A class created ten minutes ahead with a real `https` link reads as `starting-soon` on both sides
  and is joinable — the real check the module spec asks for. It is cancelled again afterwards.
- A class in a course the learner has not joined refuses the seat, and an ended one answers
  "This class has already ended."
- `test/unit/live/live_phase_test.dart` pins every boundary of the ported phase function and the
  https-only rule; the widget tests cover each phase, both registration paths, the refusal, the
  recording note and the class that is not in the schedule.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1000 tests** ✓, 3 flavor APKs ✓; **72 integration tests** ✓ on emulator-5554.

**Three test defects fixed at the root while running the full suite.**
1. `enrollment_test.dart` (FLUTTER-010) enrolled a learner on every run and never gave the seat
   back, so it used up one of the six seeded courses each time until "a course the learner has not
   joined" had none left. It — and the certificate test, which enrols to complete a course — now
   return the enrolment through `DELETE /students/enrollments/:id`, and the certificate test stays
   off the two accounts the enrolment test needs free.
2. `GET /assignments/:id/submissions` is **paginated** (20 by default). As the scratch database
   accumulated attempts, the grading setup stopped finding this run's hand-in; it now asks for the
   newest on a large page.
3. The note and draft autosave tests waited a fixed 60 ms past the debounce, which a loaded
   parallel run can overshoot — one flaked. Both now wait for the state they are about, through a
   `waitFor` helper in the harness.

### FLUTTER-016 Notifications Centre & Preferences — completed 29 Sep 2026

**Built.** `shared/domain/notification.dart` — the notification, its facts and actions, the page with
the academy's own counts, and the settings, with `LOCKED_CHANNELS` and `validateNotificationSettings`
mirrored. `features/notifications/` — `NotificationsApi` (list, detail, read, read-all, remove,
restore, clear, settings), the list/filter/action/settings controllers, and the same three screens
for **every** role: `/notifications` and `/staff/notifications`, `…/:notificationId`, and
`…/preferences`. The shell's bell now carries the unread count.

**Polling, because there is nothing else.** No socket and no push in the app yet, so the bell asks
the academy every 60 s while the app is in front, on resume, and after every mutation — never while
it is in the background (§12). A failed poll keeps the last number: the bell is not where a network
problem is reported.

**Nothing is counted here.** "5 marked read" and "5 cleared" are the bare numbers the route answers
with; the unread badge is the list's own `unread`; the filter chips carry the academy's per-category
counts. The undo sends the **whole** notification back to `/notifications/restore`, which is why a
removed one is kept until the undo has gone.

**An action is a web path, not a link.** `action.to` goes through the §5.4 mapper into one of the
app's own routes; anything it does not recognise — a path a client could have supplied — is shown as
plain text with no way to follow it, and never opened as a URL.

**Clarification B4 is settled, and §12 is out of date.** SAAS-021 added
`POST|GET|DELETE /notifications/devices` **and** an FCM transport (`apps/api/src/lib/push.ts`): a
push carries only the notification's id and category, and the app is expected to fetch it through
the API before showing anything — exactly the design FLUTTER-028 planned for. Only the Firebase
credentials (C8) are still missing.

**Three more findings** (19–21): the restore route refuses a null where its schema expects an
optional string, so the app omits what a notification does not have rather than sending `null`; SMS
is a preference the academy stores but nothing sends, so the app shows it locked with a plain
sentence; and `emailDigest` accepts `off`, which the shared domain type leaves out.

**Acceptance criteria — evidence.** `integration_test/notification_test.dart` against the real API
(7 tests):
- The seeded notices render for the learner and for the instructor, with their own categories and
  actions; the per-category counts add up to the unread total.
- Opening one marks it read **on the server** and the unread count falls by exactly one.
- Remove → Undo restores the academy's own notice, title, date, action and read state included.
- Mark all read answers the bare number and leaves the bell at zero.
- The settings round-trip; switching the `system` category off is refused by the app's own check and
  by the academy ("Check your notification settings."), as are quiet hours that start when they end.
- Someone else's notification is a 404.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1043 tests** ✓, 3 flavor APKs ✓; **79 integration tests** ✓ on emulator-5554.

**Two defects in this module's own code, found by its tests and fixed at the root.**
1. The unread poll wrote its result after the provider had gone (closing the app mid-poll), which
   Riverpod refuses. It now checks `ref.mounted` after the request.
2. A swiped notification stayed in the list until the server answered, so Flutter rebuilt a
   dismissed `Dismissible` — an assertion in debug. The row now leaves the list the moment the swipe
   ends and comes back only if the academy refuses.

### FLUTTER-017 Profile, Account & App Settings — completed 29 Sep 2026

**Built.** `shared/domain/activity.dart` (the learner's week and what they have been doing, with
`StudyDayMinutes` moved here from the home DTO so one model serves both) and `features/profile/` —
the `ActivityApi`, the app-settings controller, `/profile` and `/staff/profile`, and
`/profile/settings`. The placeholder FLUTTER-005 left in the profile tab is gone.

**The profile is the academy's answer.** Name, e-mail, role label and descriptor come from
`GET /auth/me`; a learner also sees the standing `/learning/rank-ladder` gives and the feed
`/learning/activity` gives, and a staff member sees neither — those routes are the learner's and
the app does not ask for them. There are **no edit controls**: the academy offers no way to change a
name, an e-mail or a password while signed in (B3), so "Change password" opens the forgot-password
flow with the address already filled in — the only door there is — and the About dialog claims
nothing else.

**The app's own settings are the device's.** Theme, reduced motion and the text-size preview are
kept on the phone, apply the moment they are chosen, and survive signing out; motion and text sit
**on top of** the platform's own settings rather than replacing them, and the preview says plainly
that the phone's own text size is what really decides. "Clear cached images" empties the same store
sign-out purges — local disk, nothing of the academy's.

**Acceptance criteria — evidence.** `integration_test/profile_test.dart` and the updated
`auth_test.dart`, against the real API, driving the app itself:
- The profile shows what `/auth/me` answered, with the role label and descriptor the web uses.
- Choosing Dark applies across the app at once, and `Preferences` still holds it after signing out.
- Signing out returns to Welcome and the device's secure storage no longer holds a token.
- Signing in as an instructor afterwards shows their name and **none** of the learner's — no name,
  no e-mail, no standing, no activity.
- The activity route is refused for anyone who is not a learner, which is why the screen asks only
  when one is signed in.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1061 tests** ✓, 3 flavor APKs ✓; **83 integration tests** ✓ on emulator-5554.

### FLUTTER-018 Staff Dashboard — completed 29 Sep 2026

**Built.** `shared/domain/dashboard.dart` — the whole `DashboardSnapshot` with `kpiChange` ported
from `packages/domain/src/analytics.ts`, and `features/staff_dashboard/` — the API, the scope
controller and `/staff`, in the phone order LMS-001 asks for: what needs you, what to do next,
what is coming live, then the figures, the trends, engagement, what happened, and how each course
is doing. Two columns from the tablet breakpoint.

**Nothing is recomputed.** Every figure is the server's; the app only says which way it moved, using
the academy's own rule — a count in percent, a rate in **points**, so 59% → 58% completion reads
"−1 pts" and 43 → 52 learners reads "+20.9%". The design system's `KpiTile` gained a `deltaUnit` so
it can say either.

**Scope is the route's to decide.** An instructor's request carries no `scope` and no
`instructorId` at all — asserted in a widget test and against the live server, where asking for the
academy as an instructor still answers with their own. Only an academy admin sees the picker.

**Where the academy points, the app checks first.** Every `to` on an attention item or an event goes
through the §5.4 mapper; one the app has no screen for is shown without a way to follow it, and the
card is not a door.

**Finding 22.** `CoursePerformance` carries a `courseId` and no title, so a client cannot name the
courses it is showing. The app reads the staff course list beside the dashboard for the names —
which is also right for drafts, since the public catalogue would not have them.

**Acceptance criteria — evidence.** `integration_test/dashboard_test.dart` against the real API
(6 tests):
- The academy's dashboard answers with its own figures: twelve weeks of trends, twenty-eight days of
  activity, and a title for every course it lists.
- An instructor's scope is their own whatever they ask for, their third figure is the review queue,
  and they see only the courses they teach.
- An admin reads one instructor's figures and they are a part of the academy's.
- Every `to` the academy sends is a path, never a URL.
- The change the app shows is exactly what the ported rule gives.
- A learner has no dashboard at all — the academy refuses them.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1094 tests** ✓, 3 flavor APKs ✓; **89 integration tests** ✓ on emulator-5554.

### FLUTTER-019 Staff Courses & Curriculum — completed 30 Sep 2026

**Built.** `features/staff_courses/` — `GET /courses` (search, category, admin instructor filter,
status, sort, paging), `GET /courses/:id`, `/stats`, `/chapters/stats`, `/lessons`,
`/lessons/:lessonId`, `GET /categories`, and the four lifecycle actions — behind four screens:
`/staff/courses` (status tabs carrying the academy's own counts), `/staff/courses/:courseId`
(figures, the enrolment trend, the progress spread, recent learners, lifecycle actions, "Edit on the
web"), `/staff/courses/:courseId/curriculum` (chapters and lessons with the started and completed
rates the academy counted) and `/staff/courses/:courseId/lessons/:lessonId` (read-only, drawn with
011's renderers).

**The checklist is the academy's, word for word.** A refused publish answers 409 with the publish
checklist in a shape of its own — `{id, label, met}`, which the shared decoder's `{field, message}`
reading drops (finding 23). `ConflictFailure` now keeps the array verbatim as `rawIssues`, and
`publishChecklistOf` reads it in the one feature that knows the shape. The dialog lists every line,
met and unmet, in the academy's words; the app never decides whether a course is ready.

**Nothing the route did not send.** The progress bands keep the server's own labels, the live classes
still to come are the count the route sends (not a list), and `totalMinutes` is its sum. Correcting
the DTO against `routes/courses.ts` caught three shapes the module spec had wrong — `weekly` and
`progressBuckets` are objects, not numbers, and `recent` carries `studentId`/`enrolledAt`.

**Who may act, and what it costs.** Publish and unpublish need `catalog.publish`, archive and restore
`catalog.archive`; an admin without the key is offered neither. Archiving asks for an
acknowledgement, unpublishing only a confirmation, because enrolled learners keep their access. A
restore the plan refuses (`LIMIT_REACHED`) is shown as the entitlement refusal §9 asks for, with the
academy's own sentence. An instructor never sends an `instructorId`: the token scopes their list.

**Acceptance criteria — evidence.** `integration_test/staff_courses_test.dart` against the real API
(8 tests):
- The seeded instructor's list is a part of the academy's, its counts are their own, and another
  instructor's course id answers 404 — not "forbidden", exactly as §7 requires.
- Publishing the incomplete draft answers with all six checklist lines, every one carrying words to
  show, and leaves the course a draft.
- The fullest published course goes out of the catalogue and back in: `published` and `draft` counts
  move by one and return, and it disappears from the published list in between.
- Archive takes the draft out of the draft list and adds to `archived`; restore brings it back as a
  draft.
- The figures, the curriculum rates and the lesson list are read from their own routes and agree
  with the course outline; one lesson comes back with its chapter and its neighbours.
- A learner is refused the catalogue entirely.
- "Edit on the web" is asserted for both roles in the widget tests: `/admin/courses/:id/edit` for an
  academy admin, `/teach/courses/:id/edit` for an instructor.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1156 tests** ✓, 3 flavor APKs ✓; **97 integration tests** ✓ on emulator-5554.

### FLUTTER-020 Staff Assignment Review & Grading — completed 30 Sep 2026

**Built.** `shared/domain/assignment.dart` — the coursework models promoted out of the learner
feature, with `countWords`, `reviewScore` and `validateReview` ported from
`packages/domain/src/assignment.ts` — and `features/staff_review/` — `GET /assignments/review`,
`/assignments/submissions`, `/assignments/:id/submissions`, `/assignments/submissions/:id`, the
review POST and `POST /assignments/:id/remind`, behind `/staff/review` (the academy's two numbers,
the per-course load, filter tabs with its counts, search, sort, an assignment picker, paging),
`/staff/assignments/:assignmentId/submissions` (with "Remind who is missing") and
`/staff/submissions/:submissionId`. From the expanded breakpoint the queue and the review sit side
by side and moving to the next hand-in changes the pane, not the route.

**The grade is the academy's.** The app adds up a rubric to show what a review would come to, and
says so — "About 41 of 50 — the academy works out the final score" — because the late policy is the
server's and only its answer is the grade. A late hand-in says the academy may take its percentage
off. Nothing the app computes is ever sent: the review carries scores, points, feedback and a
private note, never a score.

**A refusal names its field.** `validateReview`'s issues come back as `{field, message}` with a
`criterionId` beside `scores` — a shape no other route uses (finding 26) — so `FieldIssue` gained
`criterionId` and each rubric stepper carries the academy's own words about its own line. The app
mirrors the same rule to keep a button honest, and the server still decides.

**What a reviewer would lose is kept.** Leaving with an unsent score asks first, and says that a
draft keeps it; a draft is stored as `in-review` and is there again when the hand-in is opened. The
private note is marked "Only staff see this", and an integration test reads the learner's own raw
response to prove it never travels.

**Acceptance criteria — evidence.** `integration_test/staff_review_test.dart` against the real API
(9 tests):
- A seeded waiting hand-in is scored, given feedback and graded: the academy stores 41 of 50 — the
  same figure the app's own estimate showed — the queue is one shorter, and the learner reads their
  grade and feedback from their own route.
- Returning it for changes lets the learner hand in again: they get their own work back, and the new
  attempt is waiting.
- A draft review is kept and reloads with its scores and feedback, and is not a grade.
- An incomplete grade is refused criterion by criterion, and a one-word return is refused on the
  feedback alone; both leave the hand-in where it was.
- Who still owes an assignment is the academy's answer, and reminding someone who has handed in
  reaches nobody.
- A learner has no queue at all.
- The tablet two-pane layout is asserted in the widget tests: tapping a hand-in at 1200 px changes
  the pane and leaves the route alone.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1229 tests** ✓, 3 flavor APKs ✓; **106 integration tests** ✓ on emulator-5554.

### FLUTTER-021 Staff Quizzes Overview — completed 30 Sep 2026

**Built.** `features/staff_quizzes/` — `GET /quizzes` (search, course filter, status tabs with the
route's counts), `GET /quizzes/:id` and `/stats`, behind `/staff/quizzes` and
`/staff/quizzes/:quizId`: how the quiz is set up, what it asks — every option with the answer marked —
and how the learners did, question by question, with the wrong option most often chosen instead.
Building a quiz stays on the web; "Edit on the web" opens the editor for the role.

**The answer key is staff-only, and an architecture test says so.** `GET /quizzes/:id` serves staff
the whole quiz, `correct` and `acceptedAnswers` included, so `StaffQuiz` is a separate model from the
learner's `LearnerQuiz` — and `test/architecture/no_answer_key_for_learners_test.dart` fails the
build if anything outside a `staff_*` feature reaches it, or if the learner's own model ever grows a
`correct` field. The composition root may import the barrel, because it only builds the screen.

**Nothing is recomputed.** The distribution's ten bands keep the labels the server wrote (`0–9%` …
`90–100%`), the figures are counted over attempts rather than learners — and the screen says which —
and a quiz nobody has taken says "No attempts yet" instead of a wall of zeros. A row with no attempts
carries no pass rate at all rather than a 0% that would read as everyone failing.

**Acceptance criteria — evidence.** `integration_test/staff_quizzes_test.dart` against the real API
(6 tests):
- A seeded quiz's stats are exactly what its own stats route sends: the same attempts, pass rate and
  average as the list row, ten bands adding up to every attempt, and one stat per question whose
  named wrong option is one of that question's own and never a correct one.
- Staff are served the answer key: every question has one, in options or in accepted text, and every
  correct id names an option the question has.
- An instructor's list is a subset of the academy's, and a quiz outside their courses answers 404.
- A learner is refused the quizzes entirely — the answer key never leaves the staff routes.
- The architecture test proves the learner features cannot reach the staff model (22 architecture
  tests, 6 of them new).
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1280 tests** ✓, 3 flavor APKs ✓; **112 integration tests** ✓ on emulator-5554.

### FLUTTER-022 Staff Students — completed 30 Sep 2026

**Built.** `shared/domain/people.dart` — the learner and their enrolments, with `deriveStudentStatus`
and `completionRate` ported from `packages/domain/src/people.ts` — and `features/staff_students/` —
`GET /students`, `/students/:id`, `/progress`, `/activity`, the message route, enrol, pause, remove and
suspend, behind `/staff/students` (search, status tabs with the academy's counts, course filter, four
sorts, paging, multi-select → Message) and `/staff/students/:studentId` with four tabs: who they are
and how they are doing, their courses with pause/remove, their progress chapter by chapter with
quizzes, hand-ins and weeks of study, and their activity filtered by kind.

**The academy's count, not the one asked for.** `POST /students/message` drops any learner outside the
caller's scope without a word and answers with how many it reached; the roster reports that figure —
"Sent to 1 learner" for three ids named — because saying "sent to three" would be the app's fiction.
The same holds for a reminder and for every status on the roster: the route derives them.

**Contact details are staff-only, and the screen says so.** The e-mail and phone live on the shared
`Student` because only staff read it; the overview carries the line "Contact details are shown to staff
only", and nothing here is written to disk.

**Consequences before confirmation.** Removing an enrolment takes the learner's progress with it and
suspending signs them out, so both ask for an acknowledgement and say what will happen; pausing, which
is reversible and keeps their progress, asks only to confirm. Suspend is offered to an admin with
`learners.suspend` and to nobody else — and the route refuses anyone else regardless.

**Acceptance criteria — evidence.** `integration_test/staff_students_test.dart` against the real API
(11 tests):
- The instructor's roster is a part of the academy's, and a learner outside their courses answers 404.
- A learner's profile, progress and activity agree: the same courses on each, one enrolment event per
  enrolment, and the counts adding up to the total.
- Enrolling puts the course on their profile and the academy's count moves with it; pausing and
  resuming both take, and the learner is left exactly as they were found.
- A message to a seeded learner is read by that learner from their own notifications route, and a
  message naming a learner who does not exist still reports one reached, not two.
- Suspending moves them into the suspended tab and their status with it; restoring reverses it.
- An instructor may not suspend anyone, and a learner has no roster at all.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1353 tests** ✓, 3 flavor APKs ✓; **123 integration tests** ✓ on emulator-5554.

### FLUTTER-023 Staff Live Classes — completed 30 Sep 2026

**Built.** `features/staff_live/` — `GET /live`, `GET /live/:id`, `POST /live`, `PATCH /live/:id`,
`/cancel`, `/remind` and `/reminders`, behind `/staff/live` (the four views with the route's own
counts, search, course filter and an admin's instructor filter), `/staff/live/:liveId` (phase, times,
capacity, who registered, the agenda, the reminder offsets, the meeting link, and the class before and
after it in the course) and `/staff/live/new` · `/staff/live/:liveId/edit`.

**A save sends the whole class.** `PATCH /live/:id` takes a full `LiveClassInput`, so an edit opens on
the class as the academy has it and sends every field back; a missing one would read as a change. The
meeting is sent as `meeting.link`, which is what the write path validates and stores even though the
schema names `url` — asserted against the live server in both directions (finding 15, A1).

**The phase is shown, never decided.** `deriveLivePhase` is the ported rule, re-read every thirty
seconds from the device clock, so Join opens by itself at T-15 and a class moves to "Live now" while
the screen is open. What the academy will actually take — an edit, a cancellation — is its own call,
and its refusal is what the screen says.

**Consequences first.** Cancelling asks for a reason the learners will read *and* an acknowledgement,
because there is no un-cancel route (finding 28). A class that has started or was called off offers no
edit, and says which of the two it is. A reminder reports the academy's own count.

**Acceptance criteria — evidence.** `integration_test/staff_live_test.dart` against the real API
(11 tests):
- Scheduling a class for a seeded course tells the enrolled learner: their notifications carry the
  class by name, and it appears in their own schedule (FLUTTER-015's route) with the academy's phase.
- An edit sends the whole class and the academy keeps every field, including the ones not touched;
  the class is then put back exactly as it was found.
- Reminder offsets are set and read back; a reminder now answers with the academy's count.
- Cancelling carries the reason, closes the class to edits and to a second cancellation, and takes it
  out of the upcoming view; a reason under three characters is refused.
- A class with a bad title, a past start, too short a duration and a plain-http link is refused field
  by field — and the app's own reading names exactly the same four fields.
- Sending `meeting.url` instead of `link` is refused, as it was in FLUTTER-015.
- An instructor's schedule is a part of the academy's, and a learner has none.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1425 tests** ✓, 3 flavor APKs ✓; **134 integration tests** ✓ on emulator-5554.

### FLUTTER-024 Staff Calendar — completed 30 Sep 2026

**Built.** `features/staff_calendar/` — `GET /calendar`, `GET /calendar/:id`, `POST /calendar`,
`PATCH /calendar/:id`, `DELETE /calendar/:id` and `POST /calendar/:id/done`, behind `/staff/calendar`
(week strip and day agenda on a phone, a month grid beside the agenda from the tablet breakpoint, the
five type chips with the route's own counts, a course filter and an admin's instructor filter),
`/staff/calendar/:eventId` (detail by type: live phase and join, a deadline's `due` counts and the
learners who still owe it, a quiz window with its audience size, a milestone, a reminder with done)
and `/staff/calendar/new` · `/staff/calendar/:eventId/edit`.

**One calendar, two kinds of row.** A live class and an assignment deadline arrive generated —
`live-<id>`, `assignment-<id>`, `source` set, `editable: false` — and sit in the same agenda as the
calendar's own reminders, milestones and quiz windows. A generated row opens where it really lives
(the live class of FLUTTER-023, the submissions list of FLUTTER-020) and offers no edit, because the
record is that route's to change (D-024-3).

**IST all the way down.** An IST calendar day is carried as a UTC-flagged midnight, the range asks for
`from`/`to` as IST dates, and an event is filed by the IST day its instant falls on — so an event
stored at 19:00 UTC belongs to the next morning's agenda. `from`/`to` are built from the IST
wall-clock fields rather than through `DateFormat`: the integration run, which has no `MaterialApp`,
showed that a query formatted through `intl` throws `LocaleDataException` where nothing has
initialised locale data, and a wire format has no business needing it (D-024-1).

**The envelope each route asks for.** A create wraps the event as `{input: …}`; a save sends it bare.
Both are asserted in the data tests and against the live server, and the asymmetry is recorded as
finding 30 for the backend owners (D-024-2).

**Acceptance criteria — evidence.** `integration_test/staff_calendar_test.dart` against the real API
(8 tests):
- *Agenda matches the server rows.* A 90-day range around today reads back with every row on an IST
  day inside it, every type and timing known to the app, and the per-type counts adding up to `total`.
- *A live class is a derived event.* The class FLUTTER-023's route calls upcoming appears as
  `live-<id>` with the academy's own phase and its course title; its detail says `editable: false`,
  names `source.kind: 'live-class'` and carries the audience size.
- *Create, edit, delete a personal reminder.* One is added through the real route, found on the agenda
  under its IST day, read in detail as this account's to change, ticked off and back again, renamed
  and re-timed through the bare-body save, then deleted — and reading it afterwards is a 404, so
  nothing accumulates in the scratch database.
- *IST boundaries near midnight.* An all-day milestone stored at 19:00 UTC reads back as belonging to
  the following IST day, and the agenda files it under that day rather than the UTC one.
- *A refusal names fields.* An event with a short title, no course, no quiz and a past start is
  refused field by field, and `calendarFormProblems` names exactly the same four fields, so the app
  never offers a button for a write the academy will not take.
- *A live class is never written here.* `POST /calendar` with `type: live` is refused on `type`.
- *Scope.* An instructor reads their own calendar and cannot see — or open — another account's private
  reminder (`audience: me`); a learner has no calendar of this kind at all.
- Verification: `tool/verify.sh --all-flavors` exit 0 — codegen ✓, format ✓, analyze ✓,
  **1516 host tests** ✓, 3 flavor APKs ✓; this module's **8 integration tests** ✓ on emulator-5554.
  The project-wide integration sweep is deferred to the QA phase by direction (30 Sep 2026): from
  FLUTTER-025 on, a module is verified with format → analyze → its own tests → build, and the whole
  device suite runs once development is complete.

### FLUTTER-025 Admin Instructors & Certificates — completed 30 Sep 2026

**Built.** Two features against the real routes. `features/staff_instructors/` — `GET /instructors`,
`GET /instructors/:id`, `POST /instructors`, `PATCH /instructors/:id`, `/status` and
`/resend-invite`, behind `/staff/instructors` (search, the four status tabs with the route's own
counts, an expertise filter built from the tags the academy actually uses, and its four sorts),
`/staff/instructors/:instructorId` (Overview with the bio, expertise, reach, cities and recent work ·
Courses · Performance) and `/staff/instructors/invite` · `/staff/instructors/:instructorId/edit`.
`features/staff_certificates/` — `GET /certificates`, `GET /certificates/:id`, `/issue`, `/revoke`
and `/restore`, behind `/staff/certificates` (search, course filter, the four status tabs, paging)
and `/staff/certificates/:certificateId`, which draws the credential on **FLUTTER-014's own canvas**
and puts the academy's actions beside it.

**A save sends the whole instructor.** `POST /instructors` and `PATCH /instructors/:id` both parse a
full `InstructorInput`, so an edit opens on the record as the academy holds it and sends every field
back. The photo is never sent: the app offers no upload for one, and sending nothing leaves the
academy's own untouched.

**The academy's comparison, not the app's.** The performance tab shows their rating and completion
against `academyRating` and `academyCompletion` — both figures the route computed. The only
arithmetic the app does is the difference between them, and it is labelled as such.

**Consequences first.** Making an instructor inactive says they will no longer be able to sign in and
that their courses and learners stay as they are; making one active says it takes a seat on the plan.
Revoking a certificate asks for the reason the learner will read and will not send one under three
characters, because that route answers **400 with no field at all** (finding 31). Only an instructor
still waiting on an invitation is offered another.

**Acceptance criteria — evidence.** 82 tests for this module, all against fixtures captured from the
real API with `tool/capture_fixture.sh` (`staff/instructors.json`, `instructor.json`,
`certificates.json`, `certificate.json`):
- *Contract* (30, `test/contract/staff_instructors_test.dart`): every directory row carries a record
  the app can read and a status it knows; the status counts add up to `all`; the expertise offered is
  exactly the set in use, sorted; a rating is absent until a course is rated; the reach's cities come
  ordered by size; the performance comparison is the academy's and the app's gap is arithmetic on it;
  enrolments arrive as eight labelled months with the last one "so far"; activity is newest-first;
  the register's counts add up to `total`, a pending certificate has no issue date and a revoked one
  carries the academy's reason; the verification path is `/verify/<credentialId>`; and the
  learner-facing copy of a staff certificate carries **no e-mail address**.
- *Service* (14, `test/data/staff_instructors_api_test.dart`): every filter travels by the route's own
  name and nothing is sent when nothing is narrowed; ids are escaped into the path; a write sends the
  record bare; a status change sends only the status; an invitation answers with the address the
  academy used, and an answer without it is a `ContractFailure` rather than an empty string; the
  register always sends its page and page size; revoking carries the reason, trimmed.
- *Controller* (19): the directory's default order sends nothing; filters clear rather than send
  blank; a new instructor opens as `invited` and an edit from the record; a 409 keeps the academy's
  words field by field and a `LIMIT_REACHED` keeps its own message with no field; a status change
  re-reads the record and the directory; a second action in flight is ignored; changing what the
  register is showing starts again at its first page; and a revocation reason the route would refuse
  never leaves the app.
- *Widget* (19): the directory lists the academy's instructors with its figures; an admin is offered
  the invitation and an instructor is not; an empty result offers to clear the filters; the profile
  shows the record, the reach and "vs the academy", and its Courses tab opens the course it names; an
  active instructor is offered no second invitation while an invited one is, and the address reported
  is the academy's answer; making one inactive asks first and says what it costs; the invite form
  offers nothing until the academy would take it, and a refusal lands on the field it names; the
  register opens a credential; a pending one offers issuing, an issued one revoking (disabled until
  the reason is long enough), a revoked one shows the reason and offers restoring; and an instructor
  may issue but never revoke.
- Verification: format ✓, `flutter analyze --fatal-infos --fatal-warnings` ✓, **1598 host tests** ✓
  (1516 → 1598), `flutter build apk --debug --flavor dev` ✓. The device suite runs in the QA phase.

### FLUTTER-026 Admin Reports — completed 30 Sep 2026

**Built.** `features/staff_reports/` — `GET /reports/overview`, `/courses`, `/courses/:courseId`,
`/learners`, `/enrolments` and `/instructors`, behind `/staff/reports` and its five sibling routes.
One filter serves the whole section (period, learner segment, course and — for an admin — instructor),
so moving between tabs keeps what the reader chose, and the line under each title says the period, how
many courses it covers and how many filters are narrowing it.

**Nothing is recomputed.** Every figure, band, funnel step, ranking and comparison is the route's own
arithmetic. The app formats them, ranks nothing itself, and the single piece of arithmetic it does —
the gap between a figure and its previous period — is `kpiChange`, ported in FLUTTER-018: a rate
compares in **points** and a count in **percent**, so completion falling 69% → 58% reads "11 pts",
never "16%".

**Every chart is also a list.** `ReportSeriesView` draws the series and writes it out underneath, so
the figures survive a screen reader and 200% text; a widget test pumps the overview at textScale 2.
Tables become ranked cards on a phone (§20), and the learner table's ordering belongs to the academy:
`sortKey` and `sortDirection` travel as two flat strings and the page comes back in that order, which
the app never re-sorts (the web once sent them as one object and the route ignored it).

**A refusal is not an error.** `AsyncView` now draws `RefusalView` for an `EntitlementFailure`, so the
instructor report on a plan without `reports.advanced` says the plan does not include it instead of
offering a retry — and every other screen in the app gained the same reading.

**Absences stay absent.** `percentOf` sends `null` where there was nothing to divide by, so a cohort
the period cannot answer for yet, a course nobody has rated and a learner who has handed nothing in
all show a dash. A nought would read as nobody finishing.

**Acceptance criteria — evidence.** 70 tests for this module, all against fixtures captured from the
real API with `tool/capture_fixture.sh` (`staff/reports-overview.json`, `-courses`, `-course`,
`-learners`, `-enrolments`, `-instructors`):
- *Contract* (30, `test/contract/staff_reports_test.dart`): every tab's window is the period plus an
  equal one before it ending where it starts; the units are the route's (`count` vs `%`) and the
  ported change rule holds on its real figures; each series is an ordered run of buckets; the
  progress bands are the academy's five; the busiest courses come ranked by enrolments; a rating is
  sent only for a published course; the funnel never widens; the learner segments are read by the
  academy's own words including `at-risk` and `new`; the statuses add up to the learners covered; the
  page is served in the order asked for; the enrolment sources' shares add to about a hundred; a
  cohort keeps an unreachable milestone absent; and the shared query serialises every filter and both
  sort fields by the route's own names.
- *Service* (8, `test/data/staff_reports_api_test.dart`): each tab reads its own path and always names
  the period; all four periods and the hyphenated segment travel correctly; nothing narrowed sends
  nothing but the period; a course id is escaped; and the learner table sends `sortKey` and
  `sortDirection` as **two flat strings**, never an object.
- *Controller* (13): the section opens on the academy's default period; one filter reaches every tab;
  "all learners" is no segment rather than a segment named all; clearing puts every tab back; the
  table opens on progress highest-first, turns around when the same column is asked for again, starts
  a name A–Z, returns to page 1 on a new search, and sorting it does not re-read the other tabs.
- *Widget* (19): the overview shows the academy's figures and what they cover; a rate's change reads
  in points; each chart has its list read-out; the busiest courses open their own report; an academy
  with nothing to report says so; the page survives 200% text; the filter sheet re-reads for a new
  period and hides the instructor filter from an instructor; a course with no report says it may be a
  draft rather than offering a retry; the learner table's column choice and direction reach the
  academy; a learner opens their profile; a cohort milestone shows a dash; and the instructor report
  on a plan without it draws a refusal, not an error.
- Verification: format ✓, `flutter analyze --fatal-infos --fatal-warnings` ✓, **1668 host tests** ✓
  (1598 → 1668), `flutter build apk --debug --flavor dev` ✓. The device suite runs in the QA phase.

### FLUTTER-027 Academy Billing & Provider-Agnostic Checkout — completed 30 Sep 2026 (read-only; in-app payment pending C4)

**Built.** `features/staff_billing/` — `GET /tenant/billing`, `GET /tenant/billing/invoices/:idOrNumber`
and `GET /tenant/plans`, behind `/staff/billing` (the plan card, what each status means right now,
usage meters per limit, features included and not, the open plan change, invoices and payments),
`/staff/billing/invoices/:invoiceId` and `/staff/billing/plans`. The writes are all there too:
`POST /tenant/subscription/change`, `/plan-changes/:id/cancel`, `/cancel` and `/resume`, plus the
checkout contract — `/billing/purchase`, `/billing/checkout` and `/billing/checkout/confirm`.

**No amount, price, tenant, status or entitlement is ever sent.** A purchase names a plan and a
cycle; a checkout names one invoice **or** one plan change; a confirmation passes the provider's own
three fields back unchanged. The service tests assert each body's key set exactly and check by name
that `amount`, `price`, `total`, `currency`, `tenantId`, `status` and `entitlement` are absent.

**Every figure is the academy's.** Subtotal, tax and total come from `amounts`, which the academy
fixed when it issued the invoice: tax may be inclusive and several components each round, so nothing
is added up again. A limit with no ceiling reads "Unlimited" and draws no meter; `remaining` is the
academy's subtraction, not the app's.

**The app never decides a payment succeeded.** `confirm` hands the provider's result to the academy and
reads `settled`/`applied` from its answer; while the academy says the bank has not settled it, the app
asks again (5 s × 12) and stays on "waiting", never "paid". Only a fresh `/tenant/billing` shows a plan
as active.

**Checkout is provider-agnostic and off by default.** `planCheckout` reads the shape of the
`CheckoutParams` the academy pinned: a registered native launcher first, then the page the academy gave
(**https only**), then "complete this on the web". `nativeLaunchers` is **empty on purpose** — adding a
payment SDK is a store-policy decision (C4) and a new dependency — so no dead button is ever offered.
A payment control appears only where `BILLING_CHECKOUT_ENABLED` is on **and** the academy reports
`checkoutAvailable`, and a widget test proves none exists in the tree as shipped.

**Acceptance criteria — evidence.** 76 tests for this module. Three real states were created on the
local server through its own routes and captured with `tool/capture_fixture.sh`:
`tenant-billing-none.json` (never subscribed), `-active.json` (on the Growth plan, annual) and
`-change.json` (an upgrade to Professional quoted and waiting for payment).
- *Contract* (17): the no-plan academy is restricted with no subscription and still lists usage,
  features and the plans on sale; the on-a-plan academy carries the subscription in the academy's own
  words with its plan's prices and limits, and `remaining` equals `allowed − used`; features say
  whether they are included and how each is delivered; the payment method is a brand and a last four
  and no more; the quoted upgrade carries the academy's own credit and charge; a `CheckoutStart`'s
  amount **is** the invoice's total; a pending outcome is not a failure and an unknown status is not a
  success; and an invoice's `amounts` are read as sent, absent rather than invented.
- *Service* (12): the request bodies, key by key — `{planId, cycle}`, `{invoiceId}` alone,
  `{planChangeId}` alone, `{orderId, paymentId, signature}`, `{immediately, reason}` — with the
  forbidden keys asserted absent.
- *Unit* (14, `test/unit/billing/checkout_launcher_test.dart`): the registry is empty in this build, so
  a gateway with no page cannot run here; a registered launcher takes only its own provider and refuses
  a missing key, a missing order, a nought amount or no currency; a native launcher is preferred over a
  page; a page is opened only over `https` and only with a host, so `http`, `ftp`, `javascript:` and a
  bare path are all refused; and a payment control needs both the build and the academy to allow it.
- *Controller* (14): starting a checkout answers with what this device can do; a `PAYMENT_REQUIRED`
  refusal leaves nothing issued; a settled payment re-reads the page and only then reads as active; an
  unsettled one is asked about again the given number of times and stays "waiting"; one that settles on
  a later ask is taken as settled then; a refused confirmation and a cancelled payment both leave
  everything unchanged; a short cancellation reason never leaves the app; and a second action in flight
  is ignored.
- *Widget* (19): the no-plan academy says so and offers the plans, not a purchase; usage, features,
  invoices and payments all read from the academy; the on-a-plan academy shows ₹39,990.00 billed yearly
  and 60 of 750 with 690 left; cancelling asks for a reason and refuses a short one; an admin who may
  only read is offered no change; the quoted upgrade shows both of the academy's figures and offers to
  be given up but **not** to be paid; the plans screen marks the current plan, and choosing another
  sends only `{planId, cycle}`; and an invoice shows the academy's subtotal, tax and total, who it was
  billed to and how it was paid.
- Verification: format ✓, `flutter analyze --fatal-infos --fatal-warnings` ✓, **1744 host tests** ✓
  (1668 → 1744), `flutter build apk --debug --flavor dev` ✓.
- **Pending C4.** The acceptance item "a real test-mode payment completes and the plan becomes active
  only after confirm/re-read" is **not** met and cannot be: the local server has no payment gateway
  configured (`checkoutAvailable: false`), configuring one needs credentials, and carrying a payment
  SDK needs the store-policy answer. The module completes read-only, exactly as its spec allows, with
  the whole checkout contract, the launcher registry and the confirm/poll rule built and tested.

**Follow-up — 2026-10-03 (backend billing changes; still no in-app payment as shipped, C4 open).**

- _Cancel/resume bug fixed._ `/tenant/subscription/cancel` and `/resume` answer with the raw
  `SubscriptionRecord`, which the app parsed as `SubscriptionView` (required `startedAt`/`renewsAt`
  → a contract failure on every success). Both are now `Future<void>`; the page and the shell's plan
  are re-read. A platform pause refused with 403 shows the server's own words. The service test's
  mock is now the real record shape (`fixtures/staff/subscription-record.json`).
- _`GET /tenant/plans` fixed._ `PlanView.fromPlanRecord` reads terms under `current` and order from
  `displayOrder`; `api.plans()` sorts by it (`fixtures/staff/tenant-plans.json`).
- _First purchase._ An academy with no live subscription is offered **Subscribe monthly/yearly** (only
  where the academy reports `checkoutAvailable`; otherwise the server would refuse it). Without a
  billing profile (`GET /tenant/billing-profile` 404) a billing details form (`PUT`) comes first, with
  the server's checks mirrored and its field issues shown. Then `POST /tenant/billing/purchase`.
- _Plan change._ Same-plan cycle changes are offered; every change is previewed with the new
  `POST /tenant/subscription/preview` (credit, charge, tax, total — or "applies on <date>" and the
  limits already over) before **Ask for this change**; `needsBillingAddress` asks for details first.
- _Checkout wired._ `carryOutCheckout` (`presentation/widgets/checkout_parts.dart`): flag off (the
  default) → "Your invoice <number> for <amount> is ready. Payment is completed from the web
  dashboard."; flag on → hosted page opened externally via `openExternalLinkProvider`, or a native
  runner (`nativeCheckoutRunnerProvider`, null as shipped) whose result goes to `confirm()`/poll. Open
  invoices and a quoted upgrade read "Pay from the web dashboard" instead of a button when the build
  does not take payments; the invoice screen pays via `startInvoicePayment` when it does.
- _Banner._ The restricted banner now needs `restricted` **and** `TenantBilling.enforced` (read by
  `TenantPlanApi.enforced()`; unknown = not enforced). New past-due variant ("Payment overdue" → Open
  billing). Billing notices' `/admin/billing` action already mapped to `/staff/billing` (test added).
- _Visibility._ Billing is `built: true` in `destinations.dart`.
- Fixtures `tenant-plans`, `subscription-record`, `subscription-preview-{upgrade,downgrade}` are
  **constructed** from the API source (server was down) — `.cmd.txt` says so; recapture when it is up.
- Verification: build_runner (`--force-jit`; AOT compile fails on this machine) ✓, format ✓,
  `flutter analyze --fatal-infos --fatal-warnings` ✓, `flutter test` 1916 passed / 1 failed — the
  failure is the pre-existing `no_secrets_test` (Firebase keys committed in 60f214a), not this work.
  Integration tests updated (preview, billing details; banner follows `enforced`), not run.

### FLUTTER-028 Push Notifications & Deep Links — Part A completed, module blocked on C8 (30 Sep 2026)

**Part A — deep links — is built and verified on a device.**

- `lib/core/links/deep_link.dart`: `resolveDeepLink` takes a whole URL and answers with the app route
  it points at, or why it will not be followed. A link is untrusted input: the host must be one the
  academy serves, the scheme must be `https` — so a token never travels over a link that can be read
  on the way — and every id must be the shape the API issues. `deepLinkReplacement` does the same job
  for the *path* Android hands the router.
- The Android manifest claims `/reset-password/*`, `/verify/*`, `/courses/*`, `/learn/*` and
  `/notifications*` on `shubhlms.com` with `android:autoVerify="true"`, and turns on
  Flutter's own deep linking.
- `tool/assetlinks.sh` generates `android/assetlinks/assetlinks.json` for all three flavour packages
  from whichever keystore it is given, and writes `DEPLOY.md` beside it with the exact step a human
  takes to serve it (B13), how to check it, and how to re-run it once a release key exists.

**Two real defects were found by running it on a device, not by the tests.**

1. *The resolver was not wired to anything.* The link opened the app and the app then ignored it. The
   mapping now runs inside the router's one redirect, which is where an incoming location arrives.
2. *A link on a cold start was lost to the session restore.* `SessionUnknown` sends everyone to the
   splash, so the location the link asked for was thrown away and the reader landed on their home.
   `LinkResume` holds the link for exactly as long as the restore takes and hands it back afterwards,
   where the ordinary rules apply — including keeping it as `next` for someone who must sign in first
   (§5.4). Without this, every deep link into a signed-in screen was silently swallowed.

**The id rules are the API's, not a guess at them.** A reset token is checked against
`^[a-f0-9]{64}$`, which is exactly what `issuePasswordResetToken` produces and what `findUsableToken`
will accept. The app's *own* paths (`/verify`, `/learn`, `/notifications`) are deliberately **not**
re-checked in the redirect: that would put this module's idea of an id between the app and its own
navigation, and a bad id is already answered by the screen from the API's 404. Two existing redirect
tests were using stand-in ids (`'tok'`, `c1`) — the stand-ins were replaced with ids the academy
would really issue, which is what made the difference visible.

**Part B — push — is built as far as it can be without a Firebase project.**

- `POST|GET|DELETE /notifications/devices` are real (SAAS-021 settled **B4**), so registering,
  listing and unregistering a device are built and tested against them. The token is a credential for
  the device: it is sent once, the route never echoes it back, and what the app holds afterwards is
  its last eight characters.
- `lib/core/push/push_hint.dart` reads what the academy actually sends — `{notificationId, category}`
  and nothing else. A payload with no id, an id the API would never have issued, a non-string id or
  category, is dropped without a word; a payload carrying a title, body or image did not come from
  the academy's transport. Nothing from a push is ever shown: tapping one opens the notification and
  the API says what it is.

**Acceptance criteria — evidence.** 54 tests for this module, and the links checked on emulator-5554:
- *Unit — links* (19): each supported URL resolves to its own route with the right sign-in
  requirement; a lookalike host (`shubhlms.com.evil.test`) is refused; `http`, a
  custom scheme, `javascript:` and a bare path are all refused; an unknown path is refused; and a
  traversal, a space, a script tag, a quote and an over-long id are each refused on the paths that
  take one.
- *Unit — push* (12): the academy's hint is read and routes to the notification; every category it
  sends is understood and one it adds later is still routable; a payload with no id, a bad id, a
  non-string id or category is dropped; and a payload carrying content is recognised as not the
  academy's.
- *Service* (6): registering sends only `{token, platform}` — never an account or a tenant — trimmed
  as the route trims it; the answer carries eight characters of the token and the model never holds
  more; listing and unregistering use their own paths; and a token outside 20–4096 characters is
  recognised before it is sent.
- *Contract* (3, `test/contract/devices_test.dart`): against a device really registered through the
  route and then removed — `current` is the session that registered it, not merely the account.
- *Navigation* (9): every resolved route is one the app's router answers, and each opens its own
  screen; a push opens the notification rather than jumping to the class it is about.
- *Redirect* (11 new): the web's `/courses/:slug` becomes `/catalog/:slug`; a slug the catalogue never
  built goes nowhere the app answers; a reset token that is not the academy's is refused while a real
  one is left to the reset screen; the app's own paths keep their ids; and a link is held across the
  restore, resumed at the splash, kept as `next` when a sign-in is needed, and dropped once the reader
  has moved on.
- *On the device*: `adb shell am start -a android.intent.action.VIEW -d …` with the domain verified
  locally (`pm set-app-links --package … 1 all`) — all five claimed paths are handled by the app's own
  activity rather than the browser, and screenshots confirm the screens: `/verify/SA-JY-2026-00142`
  drew the real certificate ("This certificate is valid", Ananya Rao, 91%), `/courses/foundations-vedic`
  mapped to the catalogue and drew the real course (₹2,999, 4.8 from 325, 7 lessons), and
  `/learn/<courseId>` reached the course inside the learner shell **after the session restored**,
  which is the fix above working end to end. Android reports the app's signing fingerprint as the one
  `tool/assetlinks.sh` wrote, so the generated file is right for this build.
- Verification: format ✓, `flutter analyze --fatal-infos --fatal-warnings` ✓, **1804 host tests** ✓
  (1744 → 1804), and all three flavours build with the new manifest.

**Why the module is blocked rather than completed.** Everything that does not need a Firebase project
is done. What remains needs **C8**: `google-services.json`, `firebase_core` and `firebase_messaging`,
the Android 13+ permission request, and the token round-trip with a real push. Adding the Firebase
dependencies without the credential does not build, and inventing one is not an option. Only
FLUTTER-030 depends on this module.

### FLUTTER-029 Integration & End-to-End Test Suite — completed 30 Sep 2026

**What was missing.** Twenty-two integration files existed, but the three modules built this session —
FLUTTER-025, 026 and 027 — had no device coverage at all, and the screens they added had never been
held to the accessibility guidelines. That is what this module filled.

**39 new integration tests, against the real API on the scratch database.**
- `integration_test/staff_instructors_test.dart` (13): the directory and its counts; a status narrows
  the page while the counts still describe the academy; one instructor's courses, reach and the
  academy comparison; an instructor invited, **saved whole** and made inactive — after which they
  cannot sign in; a refusal field by field, with the app's own reading naming exactly the same fields;
  a duplicate e-mail refused; an instructor may read the directory and never change it; a learner has
  none. Then the register: its counts add up to the whole of it; a certificate issued, revoked with
  its reason and restored; **public verification still answers for a revoked credential and reports it
  as revoked**, which is the point of it; a short revocation reason refused; an instructor may issue
  but never revoke; and a learner sees their own certificate and no register.
- `integration_test/staff_reports_test.dart` (15): every tab's window is the period plus an equal one
  before it, at 90 days **and** at 12 months, and all four tabs say they cover the same academy; a
  year holds at least as much as the ninety days inside it; the ported change rule holds on the real
  figures; one course's report matches its row in the list and its funnel never widens; a draft has no
  report; a course filter narrows every tab; the learner table comes back in the order asked for and
  reversing really reverses it; paging keeps the total describing the answer rather than the page; a
  search narrows to who it names; the segments and statuses add up; an instructor reports on their own
  courses and no more; and a learner has no reports.
- `integration_test/staff_billing_test.dart` (11): the page is the academy's own account of itself;
  a limit with a ceiling reports what is left and **is clamped at nothing rather than going negative**
  — the academy's arithmetic, not the app's; every plan carries its own prices and limits; the
  fallback plans route agrees with the page; online payment is unavailable and the academy says so
  itself; a checkout is refused before anything is issued; an academy with no plan running is told why
  it cannot change plan; a plan change is quoted and then given up, leaving nothing behind; a short
  cancellation reason is refused; a missing invoice is not found; and neither an instructor nor a
  learner has a billing page.

**18 accessibility checks** (`test/features/a11y/staff_screens_a11y_test.dart`): each of the ten
screens those modules added, drawn from a real captured response, held to
`androidTapTargetGuideline`, `labeledTapTargetGuideline` and `textContrastGuideline`, and drawn again
at **200% text** — the size at which a screen that assumed its own font falls over.

**Three of the app's assumptions were wrong, and the real API said so.** Each was fixed in the test,
not in the assertion's strength: a revoked credential still verifies (and must); `remaining` never
goes negative; and a cancelled subscription is still *there*, so "has a subscription" is not the same
question as "has a plan running".

- Verification: format ✓, `flutter analyze --fatal-infos --fatal-warnings` ✓, **1822 host tests** ✓
  (1804 → 1822), and the three new integration files pass on emulator-5554 (13 + 15 + 11).
- **The twice-through run is done, and clean.** The whole device suite, twice consecutively:

  | Pass | Database | Result | Duration |
  | --- | --- | --- | --- |
  | 1 | accumulated from the session | **182 passed, 0 failed** | 25m32s |
  | 2 | freshly seeded | **182 passed, 0 failed** | 25m37s |

  Device: `emulator-5554`, Medium_Phone_API_36 (Android API 36, phone profile), `--flavor dev`
  against the local contract server. No load failures and no flakiness in either pass.

  A run before these two found one failure, and it was this module's own doing: the new instructor
  suite had issued the seed's only pending certificate, which `public_test` needs to stay pending.
  Fixed at the root — the suite leaves it alone and covers issuing through its refusal path instead
  (finding 33) — rather than by softening either test.

## Live UI E2E (layer C) — smoke phase, 1 Oct 2026

A third test layer, separate from host tests (A) and `integration_test` (B): the installed dev APK
operated on `emulator-5554` from outside the app through Android's accessibility tree and `adb input`
(`apps/mobile/tool/live_e2e/`, `.claude/flutter/e2e/README.md`). Results, the matrix and per-module
scenario specs live in `.claude/flutter/e2e/` and are written after every scenario. Smoke phase: 3–5
main flows per module decide its live status; 24 deeper scenarios are kept and reported DEFERRED.

**Application bugs found by this layer and fixed** (each with a host regression test that fails
without the fix; verified in an isolated worktree of HEAD + these changes: 1830 host tests ✓):

| # | Module | Found by | Defect | Fix |
| --- | --- | --- | --- | --- |
| L1 | FLUTTER-004 | AUTH-013 | Sign-out was local only although `POST /auth/logout` now exists (B1 settled by SAAS-020): the server session stayed valid up to 7 days | `AuthApi.logout`, `AuthRepository.endServerSession`; `SessionController.signOut` ends the server session first, never blocks the local sign-out, and a 401 from its own logout is not reported as an expiry |
| L2 | FLUTTER-002 | CORE-001 | The offline banner (and the admin restricted banner beside it) was drawn but absent from the accessibility tree: each tab page's `ModalBarrier` `BlockSemantics` hid everything painted before it | `app_shell.dart`: `Semantics(container: true)` around the tab content |
| L3 | FLUTTER-005 | NAV-002 | Device only: on Android 16 / targetSdk 36 predictive back, Back on any tab but the first **closed the app** — the tab navigators told Android the framework would not handle Back; host tests miss it because `handlePopRoute()` bypasses Android | the shell answers `NavigationNotification(canHandlePop: true)` whenever the person is not on the first tab's own page |
| L4 | FLUTTER-005 | NAV-004 | Back from a page opened through More (which replaces the first tab's page) closed the app (§5.5) | Back leaves only from the first tab's own page; otherwise it returns there |
| L5 | FLUTTER-005 | NAV-003 | Every page opened from More was titled "Home"/"Dashboard" (§5.2 requires the page title) | app bar shows the longest-matching destination's label |
| L6 | FLUTTER-017 | PROF-003 | The first "About this app" never showed the version: a `FutureProvider` nothing had loaded was read with `.value` | `showAboutThisApp` awaits `appInfoProvider.future` |
| L7 | FLUTTER-028 / §5.1 | LINK-003 | A protected link opened while signed out (`/welcome?next=/notifications`) was lost when the person signed in from Welcome — Welcome opened the sign-in and register forms without `next`, so they landed on home | the welcome route passes `next` to `WelcomeScreen`, which hands it to both forms (still validated before it is followed) |

| L8 | FLUTTER-004 / §5.1 | AUTH-014 (regression run) | Exposed by L7: a deliberate sign-out from a protected page redirected to `/welcome?next=<that page>`, so the next person to sign in on the device landed on the previous user's last page | `SignedOutReason.signedOut` for a deliberate sign-out; the redirect keeps no `next` for it (links and expiry unchanged) |

Verification of L1–L8 in an isolated worktree of HEAD + only these changes: format ✓, analyze ✓,
**1833 host tests ✓** (1822 + 11 new regression tests, each shown to fail without its fix), every
fixed scenario re-run green on the emulator, and a 12-scenario regression set re-run on the final
APK (auth, shells/back/titles, home, dashboard, entitlements, deep links): 12/12 ✓.

**Smoke status (1 Oct 2026, final APK):** 70 smoke scenarios, **70 PASS**, 0 fail, 0 blocked;
24 deep scenarios DEFERRED. Live E2E (smoke) **PASS for every developed module FLUTTER-000 … FLUTTER-028**
(028: Part A deep links only — Part B push is still blocked on C8). FLUTTER-029 is a test-suite module
with no screens of its own; FLUTTER-030 is not developed. Matrix: `.claude/flutter/e2e/matrix.md`.

**Observations kept for deep QA (not fixed — UX/accessibility, no spec rule broken):** several actions
are merged into a parent's single accessibility node ("Filters" in the Reports header, "Start the quiz"
in the quiz intro card, "Submit" in the review card) so TalkBack offers no separate button for them;
left-aligned buttons ("Schedule a class", "See the plans") expose an accessibility node wider than the
drawn button; a filled search field exposes no accessible name (its only label is the hint); passed
quizzes cannot be reopened from the Assessments list (only through the course); Billing shows usage
as "Learners 44 of 0" for an academy with no plan.

**Environment and harness findings (not app bugs).** The emulator window was black on this dual-GPU
Mac under host GPU (fixed: `-gpu swiftshader_indirect`); system animations are switched off for
automation; port 4100 was held by another session's contract server on another scratch database, so
the live layer runs on its own ports (relay :4200 → server :4201) with a per-run database identity
check; an IDE debug run replaced the APK under test mid-run, so every scenario now checks the
install stamp; the working tree's dev flavor cannot build while the uncommitted Firebase change is
half-done (`google-services.json` has no client for the `.dev` package), so the APK under test is
built in a scratch worktree of HEAD + this layer's changes only.

**Open (not fixed here):** the uncommitted Firebase change makes `test/architecture/no_secrets_test.dart`
fail (API keys in `google-services.json` and `lib/firebase_options.dart`) and `lib/firebase_options.dart`
fails the format check — whoever finishes that change needs to resolve both.

## Blocked

**FLUTTER-028 Push Notifications & Deep Links** — Part A (deep links) is complete and verified on a
device; Part B (push delivery) waits on **C8**, a Firebase project and its `google-services.json`.
The device-registration routes exist (B4 settled by SAAS-021) and the app's side of them — register,
list, unregister, and the payload rules — is built and tested. What cannot be done without the
credential: adding `firebase_core`/`firebase_messaging`, the Android 13+ permission request, and a
real token round-trip with a test push. Only FLUTTER-030 depends on this.


---

## Module Status Overview

| Id | Name | Status |
| --- | --- | --- |
| FLUTTER-000 | Workspace Bootstrap & Tooling | completed |
| FLUTTER-001 | Design System & Theme | completed |
| FLUTTER-002 | Core Infrastructure | completed |
| FLUTTER-003 | API Client & Contract Layer | completed |
| FLUTTER-004 | Secure Session & Authentication | completed |
| FLUTTER-005 | App Shell, Routing & Role Navigation | completed |
| FLUTTER-006 | Authorization, Permissions & Entitlement States | completed |
| FLUTTER-007 | Media Foundation | completed |
| FLUTTER-008 | Public Experience | completed |
| FLUTTER-009 | Learner Home & My Learning | completed |
| FLUTTER-010 | Explore & Enrollment | completed |
| FLUTTER-011 | Course Learning & Lesson Player | completed |
| FLUTTER-012 | Learner Quizzes & Assessments | completed |
| FLUTTER-013 | Learner Assignments | completed |
| FLUTTER-014 | Learner Certificates & Ranks | completed |
| FLUTTER-015 | Learner Live Classes | completed |
| FLUTTER-016 | Notifications Centre & Preferences | completed |
| FLUTTER-017 | Profile, Account & App Settings | completed |
| FLUTTER-018 | Staff Dashboard | completed |
| FLUTTER-019 | Staff Courses & Curriculum | completed |
| FLUTTER-020 | Staff Assignment Review & Grading | completed |
| FLUTTER-021 | Staff Quizzes Overview | completed |
| FLUTTER-022 | Staff Students | completed |
| FLUTTER-023 | Staff Live Classes | completed |
| FLUTTER-024 | Staff Calendar | completed |
| FLUTTER-025 | Admin Instructors & Certificates | completed |
| FLUTTER-026 | Admin Reports | completed |
| FLUTTER-027 | Academy Billing & Provider-Agnostic Checkout | completed |
| FLUTTER-028 | Push Notifications & Deep Links | blocked (C8) |
| FLUTTER-029 | Integration & End-to-End Test Suite | completed |
| FLUTTER-030 | Final Hardening & Release | pending |

---

## Verification Results

| Module | Date | Result |
| --- | --- | --- |
| FLUTTER-000 | 2026-09-22 | format ✓ · analyze ✓ · 18 tests ✓ · dev/staging/prod debug APKs ✓ · device launch ✓ · integration smoke ✓ (emulator-5554) |
| FLUTTER-001 | 2026-09-22 | format ✓ · analyze ✓ · 300 tests ✓ (incl. 188 gallery-matrix a11y variants, 30 goldens) · 3 flavor APKs ✓ · gallery on emulator ✓ |
| FLUTTER-002 | 2026-09-22 | format ✓ · analyze ✓ · 353 tests ✓ · 3 flavor APKs ✓ · integration ✓ (emulator) · bootstrap launch ✓ |
| FLUTTER-003 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 400 tests ✓ · 3 flavor APKs ✓ · 5 integration tests ✓ against the real API |
| FLUTTER-004 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 455 tests ✓ · 3 flavor APKs ✓ · 10 integration tests ✓ (seeded roles, super admin, relaunch restore, tampered token, suspension) |
| FLUTTER-005 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 529 tests ✓ · 3 flavor APKs ✓ · 10 integration tests ✓ |
| FLUTTER-006 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 578 tests ✓ · 3 flavor APKs ✓ · 13 integration tests ✓ (incl. enforcement-on refusals captured from the real API) |
| FLUTTER-007 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 627 tests ✓ · 3 flavor APKs ✓ · 18 integration tests ✓ (incl. a real `Range: bytes=100-199` → 206 on the API) |
| FLUTTER-008 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 722 tests ✓ · 3 flavor APKs ✓ · 30 integration tests ✓ (incl. a real preview opened by an instructor and a real revocation) |
| FLUTTER-009 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 766 tests ✓ · 3 flavor APKs ✓ · 38 integration tests ✓ (incl. a video placed in a preview lesson and streamed by a learner) |
| FLUTTER-010 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 798 tests ✓ · 3 flavor APKs ✓ · 43 integration tests ✓ (incl. a real enrolment and a real enrolment-policy refusal) |
| FLUTTER-011 | 2026-09-23 | codegen ✓ · format ✓ · analyze ✓ · 847 tests ✓ · 3 flavor APKs ✓ · 51 integration tests ✓ (incl. a video completed by the server from a reported position) |
| FLUTTER-012 | 2026-09-29 | codegen ✓ · format ✓ · analyze ✓ · 883 tests ✓ · 3 flavor APKs ✓ · 55 integration tests ✓ (incl. a real wrong attempt and a real passing one) |
| FLUTTER-013 | 2026-09-29 | codegen ✓ · format ✓ · analyze ✓ · 928 tests ✓ · 3 flavor APKs ✓ · 7 assignment integration tests ✓ (a real draft with an uploaded PDF, a real hand-in, a real grading and a real resubmission) |
| FLUTTER-014 | 2026-09-29 | codegen ✓ · format ✓ · analyze ✓ · 970 tests ✓ (incl. 4 new certificate goldens) · 3 flavor APKs ✓ · 66 integration tests ✓ (incl. a real course completion, a real claim and a real public verification) |
| FLUTTER-015 | 2026-09-29 | codegen ✓ · format ✓ · analyze ✓ · 1000 tests ✓ · 3 flavor APKs ✓ · 72 integration tests ✓ (incl. a class scheduled ten minutes ahead, joined by its real link, and a real seat taken and given back) |
| FLUTTER-016 | 2026-09-29 | codegen ✓ · format ✓ · analyze ✓ · 1043 tests ✓ · 3 flavor APKs ✓ · 79 integration tests ✓ (incl. a real read marking, a real remove/undo round trip and a real settings refusal) |
| FLUTTER-017 | 2026-09-29 | codegen ✓ · format ✓ · analyze ✓ · 1061 tests ✓ · 3 flavor APKs ✓ · 83 integration tests ✓ (incl. a real sign-out purge and a real change of account) |
| FLUTTER-018 | 2026-09-29 | codegen ✓ · format ✓ · analyze ✓ · 1094 tests ✓ · 3 flavor APKs ✓ · 89 integration tests ✓ (incl. a real academy and instructor scope, and a learner refused) |
| FLUTTER-019 | 2026-09-30 | codegen ✓ · format ✓ · analyze ✓ · 1156 tests ✓ · 3 flavor APKs ✓ · 97 integration tests ✓ (incl. a real publish refused with the academy's checklist, and a real unpublish/publish and archive/restore round trip) |
| FLUTTER-020 | 2026-09-30 | codegen ✓ · format ✓ · analyze ✓ · 1229 tests ✓ · 3 flavor APKs ✓ · 106 integration tests ✓ (incl. a real hand-in graded, returned and handed in again, and the learner reading their own grade) |
| FLUTTER-021 | 2026-09-30 | codegen ✓ · format ✓ · analyze ✓ · 1280 tests ✓ · 3 flavor APKs ✓ · 112 integration tests ✓ (incl. the seeded quiz's stats matching its own route, and a learner refused the answer key) |
| FLUTTER-022 | 2026-09-30 | codegen ✓ · format ✓ · analyze ✓ · 1353 tests ✓ · 3 flavor APKs ✓ · 123 integration tests ✓ (incl. a real enrolment added and removed, a real message read by the learner, and a real suspension reversed) |
| FLUTTER-023 | 2026-09-30 | codegen ✓ · format ✓ · analyze ✓ · 1425 tests ✓ · 3 flavor APKs ✓ · 134 integration tests ✓ (incl. a real class scheduled and seen by the learner, a whole-object edit, and a real cancellation) |


**Follow-up — 2026-10-03 (plan-aware workspace + self-serve onboarding; no backend/web/packages edits).**

Product decisions applied: a new academy self-serves a free trial on its admin's first sign-in (or
buys a plan); modules outside the plan are shown **locked** with an upgrade path, not hidden; a Super
Admin still has no Flutter workspace.

- _Academy plan (all staff)._ `GET /academy/plan` replaces the admin-only `/tenant/subscription/*` +
  `/tenant/billing.enforced` prefetch. New freezed `AcademyPlan` DTO (`shared/entitlements/dto/
  entitlements.dart`; the route's five keys are `@JsonKey(required: true)`, so a foreign body is a
  ContractFailure, never "not enforced, never subscribed"); `AcademyPlanApi` (`academy_plan_api.dart`,
  `tenant_plan_api.dart` deleted); `academyPlanProvider` is now `AsyncNotifier<AcademyPlan?>` read for
  admins **and** instructors — `null` = not known (learner, 401/403/404) and opens everything.
  `parseResponse` also maps json_annotation `BadKeyException` to ContractFailure.
- _Module access._ `shared/entitlements/module_access.dart`: `WorkspaceModule` (the domain's
  `MODULE_FEATURE` table, exact) and pure `moduleAccess(plan, module)` (not enforced → open; served →
  open; in lastFeatures → read-only; else locked); `moduleOf(path)` in `route_access.dart` maps staff
  routes (courses/quizzes/review+assignments+submissions → assignments/certificates/live/reports).
- _Navigation._ `ShellDestination.module`/`accessUnder(plan)`; bottom bar + rail use
  `PlanAwareNavIcon` (lock badge + "Locked. Upgrade the plan to use it." / eye + "Read-only"); the More
  sheet shows `PlanAccessBadge` ("Upgrade" / "Read-only"). Still tappable. No drawer exists.
- _Gate._ Every gated staff route is wrapped in `PlanGate` (`staff_billing/presentation/screens/
  plan_gate_screen.dart`): locked → `PlanGateScreen` (name, description, admins: plans on sale that
  include it from `/tenant/billing` with its own loading/empty/error, CTA "See plans" or — never
  subscribed — "Choose a plan"; instructors: "Ask your academy admin to upgrade", no billing read;
  instructors of a never-subscribed academy: `AcademySetupView` "Your academy is being set up");
  read-only → persistent `ReadOnlyModuleBanner` above the page. Create actions disabled with a reason:
  Live "Schedule a class" FAB (`AppFab.disabledReason`, tooltip + semantics hint) and course Publish
  (caption). Grading/issuing stay enabled (restricted mode `serve_learners`).
- _Onboarding._ `/staff/get-started` (`ChoosePlanScreen`, outside the shell, `settings.view`):
  monthly/yearly toggle, plan cards (price per cycle, trial, 4 key limits by name, features by the
  academy's label), "Start N-day free trial" (`POST /tenant/billing/trial`, body `{planId, cycle}`
  only; no payment so it ignores C4) where `trialAvailable` and the plan has a trial; "Buy for …" only
  with the build flag **and** `checkoutAvailable`, else "Paid plans are bought from the web
  dashboard."; success state → re-read plan + billing → "Go to the dashboard"; 409 PLAN_UNAVAILABLE /
  INVALID_SUBSCRIPTION_STATE explained and billing re-read; "Not now" defers for the session.
  `onboardingRedirect` (pure, `redirect.dart`) replaces only the dashboard for an admin with
  `settings.view` when `enforced && status == null`; the router listenable also listens to the plan
  and the deferral. Enforcement off: dismissible `TrialOfferCard` on the dashboard (person-scoped
  preference `user.trialOfferDismissed`). `TrialController` in `staff_billing/application/`.
- _Banner._ `AcademyPlanBanner` (replaces `AcademyRestrictedBanner`): one at a time, past due >
  restricted (never subscribed → "Choose a plan") > trial ("Free trial · N days left", part days count
  as a day, warn tone in the last 3) — admins with `settings.view` only.
- _Consistency fix._ `PlanOfferCard` listed raw limit keys (`learners.max`); limits now use
  `limitLabel`/`limitValue` (storage in GB/MB) on both plan screens. `TenantBilling.trialAvailable`,
  `PlanView.offersTrial`, `StartedTrial` DTO added.
- Fixtures (all **constructed-from-source**, `.cmd.txt` says so): `entitlements/academy-plan-{new,
  trialing,lapsed,active}.json`, `staff/tenant-billing-trial-start.json`,
  `staff/tenant-billing-onboarding.json`. Recapture when the contract server is up.
- Tests: contract (academy plan ×6, onboarding/trial ×4), service (`academy_plan_api_test`, trial body
  whitelist + 409 codes), controller (`trial_controller_test`), widgets (`plan_gate_test`,
  `choose_plan_screen_test`, `trial_offer_card_test`, `academy_plan_banner_test`, shell nav/onboarding
  in `app_shell_test`, live FAB + course Publish read-only), unit (`module_access_test`, redirect).
  Integration tests updated (academy plan as admin/instructor/learner, trial refusals only — starting
  one is a one-way door; entitlements test follows onboarding), not run.
- Verification: build_runner `--force-jit` ✓, format ✓, `flutter analyze --fatal-infos
  --fatal-warnings` ✓, `flutter test` 2017 passed / 1 failed — the pre-existing `no_secrets_test`
  (Firebase keys committed in 60f214a), not this work.

## Verification commands

Fixed by FLUTTER-000. From `apps/mobile/` (`tool/verify.sh` runs them in this order):

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs          # once any part '*.g.dart' exists
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
#   staging / prod: same with --flavor staging|prod, lib/main_<flavor>.dart, config/<flavor>.json
flutter test integration_test -d <device> --flavor dev --dart-define-from-file=config/dev.json
```

Shortcuts: `tool/verify.sh`, `tool/verify.sh --all-flavors`,
`DEVICE=emulator-5554 tool/verify.sh --integration`. Emulator: AVD `Medium_Phone_API_36`, booted with
`~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36 -no-window -no-audio -no-boot-anim`.

**A `drag` shorter than `kDragSlopDefault` (18 px) is delivered as a tap.** FLUTTER-017's profile
integration test dragged a list by a fixed 120 px to clear the bottom navigation; once this session's
data made the learner's activity feed longer, the item it wanted was already on the midline, the drag
became a tap, and the tile opened before the test could tap it — the failure reads as "found 0 widgets",
which looks like a scroll problem and is not. `reveal()` in that file now lands the item on the
viewport's midline and skips the drag when it is already there. It also uses the list's **first**
scrollable: `.last` was the rank ladder's horizontal strip, and only worked because a vertical drag
bubbles up to the enclosing list.

**Never run `flutter test` and `flutter test integration_test` at the same time.** They share
`build/`, and a host test then fails on a missing asset (`shaders/ink_sparkle.frag`) that has nothing
to do with the code. **Each integration test file leaves an ~80 MB kernel snapshot in
`apps/mobile/.dart_tool/flutter_build/`**, one per build, and they are never cleaned up: after a few
sessions they filled the disk mid-run (30 Sep 2026, 359 directories, 28 GB). `rm -rf
apps/mobile/.dart_tool/flutter_build apps/mobile/build` is safe — both are regenerated — and is worth
doing before a full suite run.

**The emulator must be started as a tracked long-running task, not with `nohup … &`.** A process
backgrounded from an ordinary shell call is reaped when that call's session ends: the emulator logs
`Wait for emulator (pid …) 20 seconds to shutdown gracefully before kill` and every test file after
that fails to load with "Unable to start the app on the device" — seven files in one run on 30 Sep
2026, which reads as seven test failures and is not one. `setsid` does not exist on macOS. Run
`/Users/mac/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36 -no-snapshot-save
-no-boot-anim -no-audio` as its own background task and wait for `getprop sys.boot_completed`.

**`dart run build_runner build` needs `--force-jit` in this workspace.** build_runner compiles its
generated build script with `dart compile aot-snapshot`, and that command refuses outright here —
"'dart compile' does not support build hooks, use 'dart build' instead" — because a package in the
graph declares build hooks (`.dart_tool/hooks_runner`, `native_assets.yaml`). While `.dart_tool/build/`
holds a cached snapshot it never notices; clear that directory and every codegen run fails with only
"Failed to compile build script", naming nothing. `dart run build_runner build --force-jit
--delete-conflicting-outputs` works and takes about 45s.

**The scratch academy's billing history is not quite the seed's any more.** FLUTTER-027 needed an
on-a-plan state to capture, so one was created through `POST /superadmin/subscriptions` and then
cancelled immediately once the fixtures were taken. `/tenant/billing` reports `restricted: true` again
— which is what `integration_test/entitlements_test.dart` depends on — but `subscription` is now a
**canceled** record rather than `null`, so the live billing screen shows "Your plan has ended" where a
freshly seeded academy shows "isn't on a plan yet". Both states are covered by fixtures
(`tenant-billing-none.json` and `-active.json`); re-seed the scratch database if a test needs the
never-subscribed state live.

**An integration test must never pick one entity and then assert a fact about another.**
`staff_live_test.dart` scheduled a class on "the first published course with an enrolment" and then
asserted that *ananya* was told about it. Both halves were reasonable and the pairing was not: the
`/courses` list is ordered by `updatedAt`, so as soon as another module's test edited a course the
first row became a course that learner is not enrolled in, the academy correctly notified the eleven
learners who are, and the test failed on an unread count. It now asks the learner's own
`/learning/courses` which courses are theirs and schedules on one of those. Whenever a test asserts
something about a named account, choose the entity **from** that account.

---

## Decisions

Planning decisions (22 Sep 2026). Changing one later is recorded here as a new entry, not an edit.

| | Decision | Reason |
| --- | --- | --- |
| **F1** | **Riverpod** for state and DI; **GetX not used** | Testability, compile safety, lifecycle-bound cancellation; GetX's global locator and bundled routing conflict with the required layering (modules.md §25.1) |
| **F2** | **go_router**, **dio**, **freezed/json_serializable**, **flutter_secure_storage**, **shared_preferences**; no offline database | modules.md §25 |
| **F3** | App at **`apps/mobile`**, Android first (minSdk 24, target 36), iOS-ready but not built | Monorepo placement; npm workspaces only include folders with a `package.json` |
| **F4** | **Super Admin and heavy authoring stay on the web**; mobile covers learner, instructor and academy-admin operations | modules.md §2.2; Needs clarification C2/C3/C15 |
| **F5** | **Billing is read-only by default** (`BILLING_CHECKOUT_ENABLED=false`); the provider-agnostic launcher is built and tested but no gateway SDK ships until store-policy approval | modules.md §11; C4 |
| **F6** | **No local scoring, unlocking, completion, pricing or entitlement logic**; the learner quiz model does not map the answer key the backend currently sends | Backend is authoritative; modules.md §18, §28.4 |
| **F7** | **Polling** for notifications (60 s foreground); push waits for a backend capability | No push transport or device endpoint exists (B4) |
| **F8** | **Celestial Ink** design system ported from the web tokens (sRGB conversions in modules.md §22.2), fonts bundled | One product identity across web and mobile |
| **F9** | Display times in **IST** (fixed +05:30), labelled when the device zone differs | Matches the web and the server's calendar ranges; C12 |
| **F10** | Integration tests run against the **real API on a scratch database** started by the workflow — never against `dev.db`/`test.db`, never a fake server | Other sessions use those databases; no mock business data |
| **D-000-1** | `json_annotation: ^4.9.0` (resolves 4.9.0) with `json_serializable` 6.11.2, `freezed` 3.2.3, `build_runner` 2.15.1 | `json_annotation` 4.12 requires `json_serializable` ≥ 6.14, which needs an analyzer newer than Flutter 3.38's pinned SDK packages allow — unresolvable |
| **D-000-2** | No root ignore entry for `apps/mobile` | Root lint/format globs only TS/TSX/CSS under `src/`; `apps/mobile` has no `package.json`, so it is not a workspace |
| **D-000-3** | Template `cupertino_icons` removed | Not in §25.2; icons come from Phosphor (001) |
| **D-000-4** | `invalid_annotation_target: ignore` in analysis_options | Standard freezed setup (`@JsonKey` on constructor parameters) — a known false positive, not a silenced finding |
| **D-001-1** | gen-l10n set up in FLUTTER-001 (spec places it in 002) | Components need user-facing copy and 001 does not depend on 002; literals in widgets are forbidden. 002 adds its strings to the same ARB |
| **D-001-2** | Fraunces bundled as static 72pt instances (400/600/700) | Flutter does not map `FontWeight` to a variable `wght` axis; every Fraunces style is ≥ 22sp |
| **D-001-3** | Web `faint` token carried over (light `#848391`, dark `#787165`) for decorative neutral ink | Needed for the neutral tone and disabled glyphs; ≥ 3:1 on surface |
| **D-001-4** | `formatter: page_width: 100` in analysis_options | Readability at the project's line length |
| **D-001-5** | `AuthImage` moves to FLUTTER-007 | It needs the bearer-header media layer |
| **D-001-6** | `ErrorSummary` is named `FormErrorSummary` | Clashes with Flutter's foundation `ErrorSummary` |
| **D-001-7** | Outlined inputs are unfilled | Filled outline inputs cramped the always-visible floating label |
| **D-001-8** | Certificate paper always uses the light palette | It is a document (as on the web), in either app theme |
| **D-001-9** | Developer gallery registered via `devRoutes` from `main_dev.dart` only | Keeps developer screens out of staging/prod builds (tested) |
| **D-002-1** | `Flavor` lives in `lib/core/config/` | `core` must not depend on `lib/app` |
| **D-002-2** | Durations follow the web ("1h 20m", "45 min"), not the spec's example "1 h 20 min" | One product voice across web and mobile (`apps/web/src/lib/format.ts`) |
| **D-002-3** | `AvatarInitials` follows the web's `initials()` (honorifics dropped, first two words) | Same person, same initials on both clients |
| **D-002-4** | `initializeDateFormatting('en')` in bootstrap and the test config | `DateFormat` may run before MaterialApp loads its localizations |
| **D-002-5** | `appRoot(...)` builds the provider scope for both `bootstrap` and integration tests | Integration tests must not replace the test binding's error hooks |
| **D-003-1** | Code generation runs with `--force-jit` | build_runner's AOT compile of its build script fails while `path_provider_foundation` → `objective_c` ships native build hooks ("'dart compile' does not support build hooks"); recorded in the README and `tool/verify.sh` |
| **D-003-2** | Generated `*.freezed.dart` / `*.g.dart` are committed | A checkout builds and tests without running the generator |
| **D-003-3** | `NetworkProblem.cancelled` added | Cancellation is a no-response outcome callers must be able to ignore quietly |
| **D-003-4** | `EntitlementProblem.subscriptionPastDue` added | `SUBSCRIPTION_PAST_DUE` is a declared stable code; decoding it defensively costs nothing |
| **D-003-5** | `Level` lives in `lib/shared/domain/` | Several features read `/catalog/levels`; it is a shared value type (§26) |
| **D-004-1** | `SessionController` lives in `features/auth/application/`, not `core/auth/` as §26 sketches | `core` must not import a feature, and the controller needs the auth repository; other features reach it through the auth barrel |
| **D-004-2** | Android secure storage uses the package's Keystore-backed AES-GCM default | flutter_secure_storage 11 removed the `EncryptedSharedPreferences` backend §6 named and migrated existing data to this cipher |
| **D-004-3** | `lib/app/session_gate.dart` chooses the screen for now | The router arrives in FLUTTER-005; the decision it encodes is the same one |
| **D-004-4** | The reset-token check returns a `Result` rather than throwing | The screen must tell "link expired" from "we could not reach the server" |
| **D-004-5** | The contract server seeds **and** backfills admin permissions, and raises the local rate limits | A seeded admin otherwise holds no keys, and a test suite signs in far more often than a person; the app's real 429 handling stays covered by unit tests |
| **D-004-6** | Integration relaunches pump an empty widget first | Otherwise Flutter reuses the `ProviderScope`, the session survives, and the test proves nothing |
| **D-005-1** | The staff shell has five fixed branches (dashboard, review, courses, live, students); each role's four tabs map onto them | One router serves instructor and admin, and a role change needs no new route table |
| **D-005-2** | `/my-learning` redirects to the in-progress tab | go_router forbids a parameterized default route for a shell branch |
| **D-005-3** | Unbuilt destinations show in dev and are hidden in staging/prod | modules.md FLUTTER-005 route table; the profile stub counts as built because it signs out |
| **D-005-4** | Shell tests assert the router's location, not the app-bar text | Titles repeat across the bar and the nav; the location is unambiguous — and it caught the null-branch bug |
| **D-005-5** | No device screenshot for this module | Scripted `adb` taps proved unreliable; the admin shell is covered by an integration test and by widget tests at both breakpoints |
| **D-006-1** | Access is decided per route by `requiredCapability(path)`, not by an "admin-only" section | The backend guards routes individually, and three of them are staff keys the spec's §5.3 treated as admin-only |
| **D-006-2** | `UserProfile` lives in `shared/domain`, with `currentUserProvider` as a seam the app overrides | `core` and `shared` must not import a feature (§26), and the architecture test enforces it |
| **D-006-3** | An unread plan answers "included" for every feature | Nothing is hidden on a guess; the server's refusal is what decides (§9.3) |
| **D-006-4** | The shell always keeps one tab, even when no capability permits any | `NavigationBar` asserts two destinations; the kept screen shows its own refusal |
| **D-006-5** | `tool/verify.sh` formats generated files after code generation | Generators emit their own line width; the strict check then covers only hand-written code |
| **D-007-1** | Cancellation crosses layers as `RequestCancellation`, not Dio's `CancelToken` | The architecture test forbids Dio outside `core/network` and `data`; controllers and screens still need to cancel |
| **D-007-2** | The image cache is keyed per signed-in person and lives beside a `syniastro_media` temp folder, both emptied by `sessionCleanupProvider` | One device, several accounts: nobody inherits the previous person's media (§13, tested) |
| **D-007-3** | `MediaUrlResolver` attaches the bearer only for the API origin and refuses any other host, scheme or port | A server-supplied URL must never be able to send the token elsewhere |
| **D-007-4** | PDF bytes are fetched by `pdfDocumentProvider` (auto-dispose `StreamProvider.family`) | Ties the download's cancellation and the temp file's deletion to the route's lifetime |
| **D-007-5** | `Durations` is renamed `AppDurations` | Clashes with Flutter material's own `Durations` |
| **D-007-6** | `tool/contract_server.sh` gained a `sync_schema` step (`prisma db push --skip-generate`) on the scratch database | Another session edits `prisma/schema.prisma` without migrations; the scratch DB must match the generated client, and `apps/api` stays untouched |
| **D-008-1** | `Course.price.amount` is a **major**-unit amount (whole rupees), formatted with `Money.formatMajor` | Clarification A2, settled from `packages/domain/src/settings.ts` ("₹0 to ₹5,00,000"), the settings screen's "Rupees" hint and the web's `formatINR`. Subscription and invoice amounts stay minor units |
| **D-008-2** | Riverpod's automatic provider retry is switched off (`ProviderScope(retry: noProviderRetry)`) | Riverpod 3 retries a failed async provider ten times with backoff for any non-`Error`, hiding a refusal for ~30 s and stacking on the API client's own policy. One automatic policy (`RetryInterceptor`) and one deliberate one (the "Try again" button) — §10.2, §17 |
| **D-008-3** | Each feature's application layer re-exports the models its screens read | Presentation must not import a `data/` path (§26); the architecture test enforces it |
| **D-008-4** | Help search runs on the server, debounced 300 ms | `GET /help/articles?search=` already searches title, summary and tags; a local filter would answer differently from the web |
| **D-008-5** | The legal screens link to the web's `/privacy` and `/terms` instead of shipping the text | No endpoint serves it, and a bundled copy would fall out of date; C6 is still open on the final policy URL |
| **D-008-6** | Sharing a course link is not built in 008 | The web app has no public `/courses/:slug` page, so the link the spec names would 404; sharing arrives with `share_plus` in 014 |
| **D-008-7** | `ArticleBody` and `AsyncView` live in `shared/widgets` | A reading lesson (010), assignment briefs and every screen with one server value need them |
| **D-009-1** | `Course`, `Chapter`, `Lesson`, `Instructor` and `CourseCategory` live in `shared/domain/course.dart`; progress and enrolment in `progress.dart`; `LearnerCourse`/`SavedCourse` in `learning.dart` | The learner's workspace reads the same course the public catalogue does (§26). `CourseCategory` because Flutter's foundation already exports a `Category` |
| **D-009-2** | The learner screens are shell **bodies** — no `Scaffold`, no `SafeArea` of their own | The shell draws the frame, the app bar and the offline banner; a nested scaffold repeats the title (the defect FLUTTER-005 found in its stubs) |
| **D-009-3** | An **expired** enrolment stays under "In progress", carrying its status and the date access ended | It is neither open nor completed, so it would otherwise disappear from every tab without explanation |
| **D-009-4** | The 400 "Only learners have a learning workspace." is turned into a not-found | A staff account in the learner shell is a routing mistake, not a bad request; §16 forbids showing a developer message. Any other 400 keeps the server's own failure |
| **D-009-5** | `MediaRules` mirrors the server's new content check, and the first bytes are read when the file is **picked** | SAAS-023 refuses a renamed file; the mirror exists so a person is not made to wait for an upload that cannot succeed (§13). Reading at pick time keeps `uploadPicked` synchronous up to its first state |
| **D-010-1** | Explore reads the **public** catalogue routes, through `features/public_catalog`'s barrel | They are the same endpoints, and the module spec names them; a signed-in learner needs no separate list |
| **D-010-2** | `LearnerCourseDetail` is written by hand, not generated | The response is flat: `LearnerCourse.fromJson` parses the shared part and the two extra flags are read beside it |
| **D-010-3** | An empty `enrolledAt` reads as no date (`EmptyAsNullUtcDateTimeConverter`), and `enrolled` decides | The route sends a placeholder enrolment (`id: ""`, `enrolledAt: ""`) for someone who is not enrolled; parsing it as a date would have crashed the page |
| **D-010-4** | "Already enrolled" and "saved" are plain functions over the workspace, not derived providers | A provider derived from `learnerCoursesProvider` was notified mid-build when the course page invalidated it after enrolling, which Flutter reports as "setState() called during build" |
| **D-010-5** | The enrol confirmation says what enrolling does, not how long access lasts; the access date is shown **after** enrolling, from the enrolment the server returned | Only the academy knows its `accessMonths`, and the app never predicts a server value (§18) |
| **D-011-1** | A 409 from `complete` becomes the **hint** under the button, not an error banner | The academy is saying what is still missing, in its own words; an apology would be the wrong voice (§16) |
| **D-011-2** | A position report is retried once and then let go | Losing one costs a few seconds of progress and the player reports again shortly; a queue would outlive the lesson (§17) |
| **D-011-3** | Notes save 1.5 s after the typing stops **and** on demand, and the server's `savedAt` is what is shown | A practice lesson completes on written working, so the note is the work; the timestamp is the server's receipt, not the app's guess |
| **D-011-4** | The certificate section shows the academy's own criteria (current/required) and nothing more | FLUTTER-014 builds the certificate; the course page only says how close it is, from `certificateRecordFor` |
| **D-011-5** | An assessment lesson shows the quiz's shape and the best score, and no way to start it yet | Taking a quiz is FLUTTER-012; showing a button that leads nowhere would be worse than showing what the lesson is |
| **D-012-1** | The learner quiz model has **no** field for an answer key — not `correct`, not `acceptedAnswers`, not `explanation` | The route already strips them (`learnerQuestion`); a model that cannot hold a key cannot leak one, and a contract test proves the fields are dropped even when present in the JSON (§18, §28.4) |
| **D-012-2** | A choice answer is sent as a **one-element list** of option ids; only a short answer is a string | `QuizAnswers` is `Record<ID, ID[] \| string>` and the server's scorer reads `answer[0]`; a bare string is read character by character (finding 12) |
| **D-012-3** | The countdown is a display: at zero the attempt is taken to the review, not submitted | §28.4.2 — the academy's limit is the academy's, and an attempt is never sent without the learner pressing Submit, least of all while offline |
| **D-012-4** | The outcome screen says "Detailed results aren't available yet" and shows no per-question feedback | The API offers the learner no per-question review (backend finding B7); the app will not invent one |
| **D-012-5** | `tool/contract_server.sh` provisions the platform Super Admin as part of `seed`, with a `superadmin` subcommand | The account is not seeded by design (`create-superadmin.ts` runs once per environment); without this step FLUTTER-004's refusal test breaks whenever the scratch database is rebuilt |
| **D-012-6** | The widget-test harness gives the API client a no-op retry backoff | The retry policy is still exercised; removing the wall-clock wait stops a retry-counting test depending on how busy the machine is |
| **D-013-1** | The work area is a **family** notifier that watches `assignmentProvider`, so its starting state is the server's draft (or the work a reviewer returned) | Nothing has to load it from a widget lifecycle — Riverpod forbids modifying a provider in `initState`/`build`/`dispose` — and a hand-in clears the area because the server's own view of the assignment changed |
| **D-013-2** | Leaving the screen saves an outstanding draft from the provider's **own** `onDispose`, using an API object captured while it was alive | "Saved on leave" without touching state after disposal; nothing is waiting for it, and a failure leaves the draft exactly as it was |
| **D-013-3** | `wordLimit` is treated as a **rule**, not guidance | The submit route calls `validateSubmission`, which refuses a longer answer — the spec said the server does not enforce it (§28.4.3). Being refused after writing would be the worse discovery |
| **D-013-4** | A hand-in may carry at most 3 files (`MAX_SUBMISSION_FILES`); a draft may carry the 20 the route's schema allows | The schema caps one request, the domain caps the hand-in. The uploader stops offering a file at 3, and the limit is said as guidance rather than as an error |
| **D-013-5** | A review's score is shown only when its status is `graded` (`Review.gradedScore`) | A returned review carries `score: 0`, which is not a grade; showing it would read as a zero the learner was given |
| **D-013-6** | What is missing is only said once the learner has begun — an untouched assignment is not told it is empty | §19: a field is not marked wrong before anyone has typed in it. Submit stays disabled either way, which is the honest signal |
| **D-013-7** | `MediaUploadTile.onUploaded` hands back the whole `UploadedMedia`, not just its id | The work body must carry the stored file as the media route returned it, so the server's `ownFiles` can match it to the learner's own upload |
| **D-013-8** | The learner's `/assignments` **and** `/assessments` destinations are marked `built` | An unbuilt destination is hidden outside dev, so a finished screen was unreachable in staging and prod (FLUTTER-012 left `/assessments` false) |
| **D-014-1** | The certificate and rank models live in `shared/domain`, and the course page's own criterion model was folded into them | "How close am I" is asked by the course page, the wallet and the ladder; one definition means one answer. The criterion's `required` is `needed` in Dart, where `required` is taken |
| **D-014-2** | The learner's e-mail is not modelled on any certificate the app reads, although the route sends it | Nothing about a credential may carry it (§18), and a model that cannot hold it cannot share it — the same rule the verify screen follows |
| **D-014-3** | The canvas prints no academy name | No learner-reachable endpoint carries one (finding 14), and a certificate will not print a name this app invented |
| **D-014-4** | The ladder shows each rank's **requirements**, and says the academy does not publish progress | `/learning/rank-ladder` sends `achieved` and `progress` empty (finding 13); a ring filled from a guess would be a claim the academy never made |
| **D-014-5** | No "Download" is offered | The server returns certificate data only — there is no PDF or image endpoint — and a button that cannot work is worse than none (the module spec's B8-like note) |
| **D-014-6** | Sharing goes through `core/platform/share.dart`, not `share_plus` in the screen | A platform capability like connectivity: behind a provider, a test can see exactly what would leave the app, which is how the verification link is pinned |
| **D-014-7** | Study hours are a `num` everywhere | The academy rounds them to the nearest half hour (`hoursFor`), so the verify screen's `int` would have failed to parse a 6.5-hour course and broken the page |
| **D-015-1** | Every live screen reads its phase from a clock that ticks every 30 s | Join opens a quarter of an hour before the start without asking the server again (§14); the server's own phase is what a row arrives with, and the clock only carries it forward |
| **D-015-2** | The wall clock is a provider (`core/platform/clock.dart`) | A test drives time instead of waiting for it — which is how "the room opens without a refetch" is proved at all |
| **D-015-3** | Only an `https` external link is ever opened, and the host is named first | §13 and B12: the academy's own room has no link, and nobody is sent somewhere they were not told about |
| **D-015-4** | Seats left are shown only from the academy's answer to a registration | `/live/learner` counts only the caller's own registrations (finding 17), so the list cannot be counted from — the register response is the only real figure |
| **D-015-5** | No recording playback is offered | The recording carries its length and its expiry and no address at all (finding 16); the app says the academy has not published a way to play it |
| **D-015-6** | A class that is not in the schedule shows an empty state with the way back | A cancelled class is in none of the route's three buckets (finding 18), so this is also what a learner sees after one is called off |
| **D-015-7** | The list offers Join from the moment the room opens, and a seat before that | `canJoin` covers `starting-soon` and `live`; a seat is only worth taking while the class is still ahead |
| **D-015-8** | Tests that enrol give the seat back through the academy's staff route | A learner cannot leave a course, so without it every run used up one of the six seeded courses (see the three test defects above) |
| **D-016-1** | The bell's number is polled — 60 s in front, on resume, after every mutation — and a failed poll keeps the last number | There is no socket and no push in the app yet (§12), and a bell that shouted about a dropped request would be worse than one that waits a minute |
| **D-016-2** | A poll that outlives its provider is dropped (`ref.mounted`) | Closing the app mid-poll otherwise writes to a disposed provider, which Riverpod refuses — found by this module's own tests |
| **D-016-3** | A removed notification leaves the list the moment the swipe ends, and comes back only if the academy refuses | Flutter asserts on a dismissed `Dismissible` still in the tree, and the removal is the academy's to confirm — the list is read again either way |
| **D-016-4** | The undo sends the **whole** notification to `/notifications/restore` | That is what the route takes, so what comes back is the academy's own notice — the same id, date and read state — not a copy the app made |
| **D-016-5** | `action.to` is mapped through §5.4, and an unrecognised path is shown without a way to follow it | The route accepts a client-supplied `secondaryAction` unchecked, so a path is never followed blindly and never opened as a URL (§18) |
| **D-016-6** | The `system` category's app and e-mail switches are locked, and **every** SMS switch is locked | The server refuses the first (`LOCKED_CHANNELS`) and nothing sends the second (finding 20); offering either would be a lie (§16) |
| **D-016-7** | A saved settings change takes the PUT's own answer as what the academy holds, and the draft survives a background read | Re-reading after a save showed the old values for a moment; keeping the draft means a poll can never wipe what someone is typing |
| **D-016-8** | The restore body leaves out what a notification does not have, rather than sending `null` | The route's schema marks those fields optional, and zod refuses a null where it expects a string (finding 19) |
| **D-017-1** | The profile shows **no** edit controls — not disabled ones | The academy has no route to change a name, an e-mail or a password in session (B3); a greyed-out field would promise something that does not exist (§16) |
| **D-017-2** | "Change password" opens the forgot-password flow with the address filled in | That reset e-mail is the only way the backend offers, and it is honest about it |
| **D-017-3** | Theme, motion and text size are the **device's**: kept on it, applied at once, and untouched by signing out | They are not the academy's to hold, and someone who set the app dark did not do so for one account (§8.4) |
| **D-017-4** | Reduced motion and the text-size preview sit on top of the platform's own settings, never instead of them | A phone that asks for less motion gets less motion whatever the app says, and the preview multiplies the system scale rather than replacing it (§19) |
| **D-017-5** | `StudyDayMinutes` moved to `shared/domain`, and the home DTO re-exports it | The profile's week and the home's week are the same `StudyDay`; `core`/`shared` may not import a feature, so the model had to live where both can read it |
| **D-017-6** | The learner's standing and activity are asked for only when a learner is signed in | `/learning/activity` and `/learning/rank-ladder` refuse anyone else; asking and swallowing the refusal would be a request the app knows will fail (§7) |
| **D-018-1** | `kpiChange` is ported, and no KPI is ever recomputed | A count moves in percent and a rate in points (§18); the figures themselves are the academy's, and a second arithmetic would be a second truth |
| **D-018-2** | `KpiTile` gained a `deltaUnit` rather than a second tile | The same component now says "+20.9%" or "−1 pts", which is the only difference between a count and a rate |
| **D-018-3** | An instructor's request carries no `scope` and no `instructorId` | The route decides their scope from their own account whatever it is asked for (§7); sending one would be asking for something the app has no business asking |
| **D-018-4** | Course titles come from the **staff** course list, not the public catalogue | The dashboard names no course (finding 22), and a staff list includes the drafts an admin is looking at |
| **D-018-5** | An attention item or event the §5.4 mapper does not recognise is shown, but is not a door | The academy may point at a screen this app does not have; following it blindly, or hiding the item, would both be wrong (§18) |
| **D-019-1** | `ConflictFailure` gained `rawIssues` — the 409 `issues` array exactly as sent | The publish checklist is `{id, label, met}` and the shared decoder reads `{field, message}` (finding 23); the feature that knows the shape reads it from there, and no other feature has to care |
| **D-019-2** | `formatFigure` moved from the dashboard's widgets to `core/format/figures.dart` | Two staff features now write the academy's figures; a shared formatter beats a cross-feature import or a second copy |
| **D-019-3** | The staff list's status tabs are the app's four words over the route's `counts`, and `all` sends no `status` at all | `GET /courses` counts every status for the current search and category, so the tabs can show real numbers without a second request |
| **D-019-4** | The progress spread keeps the server's own band labels (`0-20%` …) | The bands are the route's arithmetic; renaming them in the app would invent a second definition of a band (§18) |
| **D-019-5** | Archive asks for an acknowledgement, unpublish only a confirmation | Archiving takes a course out of every list; unpublishing leaves enrolled learners exactly where they are, and the copy says so |
| **D-019-6** | A refused action clears itself from the controller once shown | The checklist and the refusal are answers to one press, not state a screen should keep — and a second press must ask the academy again |
| **D-020-1** | The coursework models moved to `shared/domain/assignment.dart`, with `countWords`, `reviewScore` and `validateReview` ported beside them | The learner's screens and the staff review read the same submission, rubric and verdict (§26); the alternative was the staff feature importing the learner feature's own DTOs |
| **D-020-2** | The score the app shows before asking is labelled an estimate, and the grade shown afterwards is the server's own | The academy's late policy is not in the app, so its arithmetic can differ; the response is what the screen then shows (§18) |
| **D-020-3** | `FieldIssue` gained a `criterionId` | A rubric refusal names the line it refused, and without it three `scores` problems are indistinguishable (finding 26) |
| **D-020-4** | The scorer's view model was renamed `ScoringCriterion` | The review screen holds both it and the domain's `RubricCriterion`; two types of the same name in one file is a trap rather than a convenience |
| **D-020-5** | A hand-in to mark is chosen by its review status, never by its place in the list | Every attempt is listed as its own row (finding 27), so "the first row" is the oldest attempt, not the one waiting |
| **D-020-6** | The unsaved-changes guard is a `PopScope` on the review, and a draft is the way to keep work | A reviewer who leaves mid-review would otherwise lose a score and feedback the server never saw |
| **D-021-1** | `StaffQuiz` is a separate model from `LearnerQuiz`, and an architecture test keeps learner code away from it | The staff route serves the answer key; one shared model would put `correct` one import away from a learner screen (§18, §28.4) |
| **D-021-2** | The score distribution keeps the server's own band labels | The bands are its arithmetic; renaming them in the app would invent a second definition of a band |
| **D-021-3** | A quiz with no attempts shows "No attempts yet" and a row with none shows a dash | The route sends `null` for a rate it cannot compute, and a 0% would read as everyone failing something nobody has taken |
| **D-022-1** | The learner and enrolment models moved to `shared/domain/people.dart`, with `deriveStudentStatus` and `completionRate` ported beside them | The roster, the profile and the reports to come all read the same learner (§26); the ports let the app read a status it was not given, never overrule one it was |
| **D-022-2** | After a message the app reports the academy's `sent`, never the number of learners named | The route silently drops ids outside the caller's scope (§7); reporting the ask would claim something that did not happen |
| **D-022-3** | `activityLabel` and `activityIcon` moved from the profile feature into `shared/widgets` | The learner reads their own activity and staff read theirs from the same `ActivityKind`; a staff screen importing the learner feature for two mappings had it backwards |
| **D-022-4** | Removing an enrolment and suspending ask for an acknowledgement; pausing only confirms | Removing takes the learner's progress and suspending signs them out; pausing is reversible and keeps everything (§22.5) |
| **D-023-1** | The live form holds the **whole** class and sends every field on a save | `PATCH /live/:id` takes a full `LiveClassInput`; sending a subset would read as clearing what was left out |
| **D-023-2** | A write sends `meeting.link`, never `url` | The write path validates and stores `link` (finding 15); `url` is accepted by the schema and then refused by the validator |
| **D-023-3** | The phase on a live screen is re-derived every thirty seconds from the device clock | §14 asks for it, and it is presentation only: the row arrives with the server's own phase, and what may be joined is never the app's decision |
| **D-023-4** | Cancelling asks for an acknowledgement as well as a reason | There is no un-cancel route (finding 28) and the registered learners are told at once, so it cannot be taken back |
| **D-023-5** | The form's own checks name only the fields the academy's validator names | The academy writes the words; the app decides which field to put them against, so a server refusal and the app's own reading agree (asserted against the live server) |
| **D-024-1** | An IST calendar day is carried as a UTC-flagged midnight, and `from`/`to` are built from the IST wall-clock fields rather than through `DateFormat` | The query is a wire format: it must not depend on `intl` locale data being initialised, which a service reached outside a `MaterialApp` cannot assume (the integration run found this) |
| **D-024-2** | A create wraps the event as `{input: …}` and a save sends it bare | That is what the two routes ask for, one each way (finding 30); both directions are asserted against the live server |
| **D-024-3** | The generated rows (`live-…`, `assignment-…`) share the agenda with the calendar's own events, but open where they really live and offer no edit | `editable` is the academy's word, and a live class or a deadline is owned by its own route (023, 020) — editing it here would be a second way to change one record |
| **D-024-4** | The week strip and the month grid are two views over **one** range read, and the month grid appears from the tablet breakpoint | A day, a week and a month are the same rows grouped differently; reading each separately would show three answers for one calendar (§20) |
| **D-024-5** | The form's own checks mirror `validateCalendarEvent` and name the same fields the route names | As in FLUTTER-023: the academy writes the words, the app only decides which field to put them against, and the pairing is asserted against the live server |
| **D-025-1** | The admin instructor record is its own model, `AcademyInstructor`, beside the public `Instructor` | The public one carries only what a learner may see; one model for both would put an e-mail address and a status one import away from a course page (§18, §26) |
| **D-025-2** | Staff get their own `RegisterLearner` with an e-mail, and `StaffCertificateDetail.asPrinted` hands the canvas a learner without one | The register's search matches on the address, so staff need it; nothing about *sharing* a credential may carry it, so the shared `CertificateLearner` stays as it is (§18) |
| **D-025-3** | The staff certificate screen draws FLUTTER-014's canvas rather than one of its own | It is the same paper; a second implementation would drift, and the learner's view is the one that matters |
| **D-025-4** | A revocation reason is checked in the app before it is sent | That route answers a short reason with a plain 400 and no field (finding 31), which no screen could put against the reason box |
| **D-025-5** | The app never pre-empts the plan's instructor limit | `withinLimit` counts seats in the same transaction as the write; a count the app did first could only be out of date (§6) |
| **D-025-6** | The performance tab shows the academy's own comparison figures, and only the gap is computed | `academyRating` and `academyCompletion` are the route's; recomputing either in the app would be a second definition of how the academy is doing (§18) |
| **D-026-1** | One filter serves the whole report section, and the learner table's ordering is its own | The period and course a reader chose should survive moving between tabs; sorting a column should not re-read five other endpoints |
| **D-026-2** | `sortKey` and `sortDirection` travel as two flat strings | That is what the route's schema parses; the web once sent one object and the route silently ignored it, which is the bug this pins down |
| **D-026-3** | Every chart is written out as a list beside it | A chart is unreadable to a screen reader and unusable at 200% text; the read-out is the figures themselves, not a description of them (§16, §19) |
| **D-026-4** | `AsyncView` draws `RefusalView` for an `EntitlementFailure` | A plan that does not include a report is not an error to retry; every screen gained the correct reading, not just this one (§6, §9) |
| **D-026-5** | A figure the academy sent as `null` shows a dash | `percentOf` returns null where there was nothing to divide by; a nought would read as nobody finishing (§18) |
| **D-026-6** | The comparison line uses a plain period name ("vs the previous 90 days") | The picker's own label reads "Last 90 days", which makes "vs the previous Last 90 days" — found by a widget test counting sixteen of them |
| **D-027-1** | `nativeLaunchers` ships **empty**, and every provider falls through to the academy's page or to "finish this on the web" | A payment SDK is a store-policy decision (C4) and a dependency; an empty registry makes every answer the app gives honest instead of offering a button that leads nowhere (B9, A3) |
| **D-027-2** | A payment control needs the build flag **and** the academy's `checkoutAvailable` | The flag is this build's decision and the gateway is the academy's; either one alone would offer a payment that cannot be taken |
| **D-027-3** | `confirm` polls while the academy reports the payment unsettled, and the plan reads as active only from a fresh `/tenant/billing` | `settled` and `applied` are the academy's words; an SDK callback flipping the UI to active would claim something the academy has not said (§11, §18) |
| **D-027-4** | A hosted payment page is opened only over `https`, with a host | A payment carried over a link that can be read on the way is worse than no payment at all; anything else is not opened |
| **D-027-5** | The invoice screen shows `amounts` and computes nothing | Tax may be inclusive and several components each round, so a total the app added up could differ from what the academy charged |
| **D-027-6** | The billing service's request bodies are a closed list, asserted key by key | §18 forbids the client to choose a price, an amount, a tenant, a status or an entitlement; a test that names the forbidden keys is what keeps one from being added later |
| **D-028-1** | An incoming link is mapped and validated inside the router's one redirect | That is where a location from outside actually arrives; a resolver nothing calls protects nothing, which is what the first device run showed |
| **D-028-2** | `LinkResume` holds a link across the session restore | A cold start from a link races the restore, and `SessionUnknown` sends everyone to the splash — without this every deep link into a signed-in screen was silently lost |
| **D-028-3** | A reset token is checked against `^[a-f0-9]{64}$`, and the app's own paths are not re-checked | That regex is the API's own (`findUsableToken`); re-checking `/verify`, `/learn` and `/notifications` would put this module between the app and its own navigation, and their screens already answer a bad id from the API's 404 |
| **D-028-4** | `assetlinks.json` is generated by a script into `android/assetlinks/`, with the deployment step written beside it | Serving it is a web-hosting change outside this workflow (B13); generating it here means the fingerprints are this build's, and a human only has to copy it |
| **D-028-5** | Nothing from a push is ever displayed | The academy sends `{notificationId, category}` and nothing else precisely so the reader sees what the API served, not what arrived on the wire; a payload carrying a title or body did not come from it (§12, §18) |
| **D-029-1** | An integration test that finds the app's assumption wrong is corrected against the API, never softened | The API is the source of truth: a revoked credential verifying, `remaining` not going negative and a cancelled subscription still existing were all the academy being right and the test being wrong |
| **D-029-2** | The accessibility pass draws each screen from a real captured response, at 100% and 200% text | A guideline check against an empty screen proves nothing, and 200% is where a layout that assumed its own font size gives way (§16, §19) |

---

## Known Issues

Backend findings recorded for the backend owners (modules.md §28.4) — not fixed by this workflow:

1. The learner lesson endpoint sends the quiz answer key (`correct`, `acceptedAnswers`) before answering.
2. Quiz time limits are not enforced server-side.
3. ~~Assignment `format`/`wordLimit` are not enforced; submitted file ids are not ownership-checked.~~
   **Not a finding — corrected 29 Sep 2026 (FLUTTER-013).** The submit route calls
   `validateSubmission` (format **and** `wordLimit`) and both the draft and submit routes resolve
   every file through `ownFiles`, which refuses a file that is not the caller's own upload and reads
   the name and size from the stored file. Both were tested against the live server.
4. Tenant `status` (suspended/archived) is not enforced on requests.
5. Role-only endpoints still honour a deactivated admin's unexpired token.
6. **B14** — `GET /media/:id` is behind `requireAuth`, so a signed-out visitor cannot stream a
   free-preview video or open a preview document. Only an article preview is genuinely public.
   The app offers sign-in rather than a player that could only fail (FLUTTER-008).
7. `GET /catalog/courses/:slug` filters on `status: 'published'` alone, not on `visibility`, so a
   published `unlisted` **or `private`** course is served to anyone who knows its slug. Unlisted is
   "reachable by link" by design; private is not.
8. `GET /help/categories` and `GET /help/articles` treat a **missing** `audience` as "show
   everything", so a client that omits it is served staff-only articles. The app always sends one.
9. The seed's lesson video and document blocks carry a file name and size but no stored media id or
   URL, so no seeded lesson media can be played (this is also why FLUTTER-007 could not exercise
   codec playback).
10. The web app has no public per-course page: `apps/web/src/app/router.tsx` serves `/courses`
    (Explore) but nothing at `/courses/:slug`, so a shared course link has nowhere to land.

Backend changes observed while this workflow was building (not findings — work by the SaaS
session that the mobile app had to follow):

11. `POST …/lessons/:id/complete` checks the lesson's completion rule **before** it checks whether
    the lesson is locked, so a locked video is refused with "Watch at least 90% of the lesson to
    complete it." rather than the lock's own reason. Not reachable from the app — a locked lesson
    offers no complete button — but a misleading sentence for any other client (FLUTTER-011).
12. `scoreAttempt` reads a choice question's answer as an array (`(answer as ID[])[0]`), but the
    attempt route's schema accepts `string | string[]` for every answer. A single or true/false
    answer sent as a bare string is therefore read character by character: `'a'` happens to score
    correct because its first character is the option id, and `'false'` scores **incorrect**. The
    domain's own type says choice answers are `ID[]`, so the app now sends a one-element list —
    but the schema should refuse a string for a choice question, or the scorer should accept one
    (FLUTTER-012).
13. `GET /learning/rank-ladder` builds its standing as
    `{ rankId, achieved: {}, progress: {} }` — both maps are hard-coded empty. The shared domain's
    own `evaluateRankLadder` reads `standing.achieved[rank.id]` for when a rank was reached and
    `standing.progress[criterion.id]` for how far along the next one a learner is, so no client can
    show either. The app shows each rank's requirements instead and says the academy does not
    publish progress (FLUTTER-014).
15. The live-class write schema names `meeting.url`, but `validateLiveClass` reads `meeting.link`
    and the route stores the object as it came in (`.passthrough()`). An external class created with
    `url` is therefore always refused — "Check the class details before scheduling." — and one
    created with `link` is stored and read back correctly. **This settles clarification A1**: `link`
    is the field, and the schema should name it (FLUTTER-015, asserted live).
16. A live class's `recording` is `{ durationMin, availableUntil }` — no media id and no URL — so no
    client can play a recording. The app lists what was recorded and says the academy has not
    published a way to play it (FLUTTER-015).
17. `GET /live/learner` includes `registrations: { where: { studentId } }`, so `mapLive` fills
    `registered`, `attending` and `attended` from **the caller's own** registration: they are 0 or 1
    and say nothing about how full the class is. Seats left can only come from the answer to
    `POST /live/:id/register` (FLUTTER-015).
18. `GET /live/learner` buckets `live`, `upcoming`/`starting-soon` and `ended` only. A **cancelled**
    class — and one whose recording has expired — is in none of them, so it disappears from the
    learner's schedule with no word that it was called off, and `cancelReason` never reaches them
    (FLUTTER-015).
19. `POST /notifications/restore` types its optional fields as `z.string().optional()`, which zod
    refuses a `null` for. A client that models a notification faithfully — `readAt: null` on one that
    was never read — cannot send it back; the field has to be left out entirely. `.nullish()` would
    accept the shape the list route itself describes (FLUTTER-016).
20. SMS is a preference with nothing behind it: `channelsFor` can answer `sms: true` (the academy's
    `smsEnabled` defaults to true and the account may hold a number), but `NotifyResult` has no sms
    and `notify()` never sends one. A learner could switch on a channel that does nothing, so the app
    shows it locked (FLUTTER-016).
21. `PUT /notifications/settings/me` accepts `emailDigest: 'off'` and stores it, but the shared
    domain's `EmailDigest` is `'instant' | 'daily' | 'weekly'`. The app models `off` because the
    route stores it; the type should say so (FLUTTER-016).
22. `GET /dashboard`'s `CoursePerformance` carries a `courseId` and no title, so a client cannot
    name the courses in its own performance list. The app reads `GET /courses` beside it for the
    names (FLUTTER-018).
23. A refused publish answers `409 {message, issues}` where `issues` is the **publish checklist** —
    `{id, label, met}` — not the `{field, message}` pairs every other 409 carries. A generic decoder
    reading `message` finds nothing and drops the whole list. The app keeps the array verbatim on
    `ConflictFailure.rawIssues` so the feature that knows the shape can read it; a single shape, or
    a `code` naming this one, would let every client read it (FLUTTER-019).
24. The seeded catalogue contains **published courses that no longer meet `publishChecklist`** —
    three of the six have fewer than five lessons. `POST /courses/:id/unpublish` has no such guard,
    so unpublishing one of them is a one-way door: it becomes a draft the API will never take live
    again. Either the seed should satisfy today's checklist or unpublish should warn. Found by
    FLUTTER-019's integration test, which now round-trips only the fullest course.
25. There is no way to delete a course: `coursesRouter` has no `DELETE`, and archive is the only
    removal. A test or a mistaken creation therefore stays in the academy's counts for good
    (FLUTTER-019 reuses one named draft rather than creating one per run).
26. A refused review's `issues` carry a **`criterionId`** beside `field: 'scores'` (`ReviewIssue`),
    which no other route's issues use. A decoder that reads only `path`/`field` therefore gets three
    identical `scores` problems and cannot say which rubric line is wrong. The app now keeps
    `criterionId` on `FieldIssue`; documenting it as part of the issue shape would let every client
    do the same (FLUTTER-020).
27. `GET /assignments/submissions` lists **every attempt** of a resubmitted hand-in as its own row,
    and `counts` counts them all, so one learner can appear several times in "All" and the totals
    read higher than the number of learners. Only the latest attempt can be acted on. The app reads
    each row's own review rather than its position, but a `latestOnly` or an `attempt` filter would
    make the list say what a reviewer means (FLUTTER-020).
28. There is no way to delete a **live class** either: cancelling is the only removal, and a
    cancelled class stays in the staff `cancelled` view for good. FLUTTER-015's contract test cancels
    the class it creates — the only cleanup the API offers — so twelve runs had left twelve cancelled
    classes in the academy's schedule by 30 Sep 2026. FLUTTER-023's own test reuses one named class
    instead of creating one per run.
29. `POST /live` and `PATCH /live/:id` accept a `meeting` object through `.passthrough()`, so the
    write path stores whatever field it is given — `url` is stored and then fails `validateLiveClass`,
    which reads `link`. The refusal is correct but says only "Check the class details", naming no
    field, so a client sending `url` has nothing to go on. Settling the schema on one name would end
    it (clarification A1, finding 15, confirmed again in FLUTTER-023).
30. The two calendar write routes take the same event two different ways: `POST /calendar` parses
    `{input: CalendarEventInput}` while `PATCH /calendar/:id` parses the event **bare**. Both call
    the same `eventInputSchema` and the same `validateCalendarEvent`, so the asymmetry is in the
    envelope alone, and a client that guesses wrong is told only "Invalid request". Every other
    write pair in the API uses one shape for both (FLUTTER-024).
31. `POST /certificates/:id/revoke` refuses a reason under three characters with `badRequest` —
    a 400 carrying a message and **no** `issues` — while every other refusal in the same area sends
    field-mapped issues. A screen therefore cannot put the academy's words against the reason box,
    and the app checks the length itself to avoid a refusal it could not place (FLUTTER-025). The
    route's own schema caps the reason at 1000 characters, so the app checks both ends.
32. **No invoice can be raised on the local server, so none could be captured.** An invoice is only
    issued when a checkout starts (`lib/checkout.ts` → `invoiceForPlanChange`), and that path calls
    `requireActiveProvider()` first — with no payment gateway configured, `/tenant/billing` reports
    `checkoutAvailable: false` and `invoices: []` even for an academy on a plan with an upgrade
    quoted. The invoice screens are therefore modelled field-for-field from
    `packages/domain/src/subscription.ts` (the read-only source of truth) and asserted against that
    shape, including a paid invoice, an open one, a withdrawn one and one with no `amounts`. A real
    capture needs a gateway on the local server, which needs credentials (FLUTTER-027).
33. **Issuing a certificate is a one-way door, and the seed has exactly one pending certificate.**
    `POST /certificates/:id/issue` moves it to `issued`; `restore` puts a *revoked* one back to
    `issued`, and nothing puts one back to `pending`. The seed's `SA-JY-2026-00231` is the only
    pending credential, and `integration_test/public_test.dart` depends on it staying that way —
    a certificate not yet issued must not verify publicly. FLUTTER-029's new instructor suite issued
    it and broke that test on the next run. The suite now leaves it alone and covers issuing through
    its refusal path instead; the device suite is meant to run on a freshly seeded database each
    time, and this is why (FLUTTER-029).
14. Nothing a learner may call carries the academy's own name: `/settings` is staff-only, and the
    catalogue, learning and certificate routes never name the academy. A certificate therefore
    cannot print the name of the academy awarding it — the canvas has a place for it and the app
    leaves it empty rather than invent one (FLUTTER-014).

- **SAAS-023 Media Security**, landed 23 Sep 2026 during FLUTTER-009. `POST /media/upload` now
  checks a file's first bytes against its extension, and `GET /media/:id` decides through
  `lib/mediaAccess.ts`: a learner reads a staff file only where it is placed (a published lesson of
  an enrolled course, a published free preview, a published assignment's attachment). The app
  mirrors the signature check (D-009-5) and FLUTTER-007's integration tests were rewritten. It also
  narrows finding 6: a free-preview **video** is readable by a signed-in learner once the academy
  attaches it to the preview lesson — a signed-out visitor still cannot read it.

Concurrent work observed 22 Sep 2026 (during FLUTTER-000): another session has uncommitted edits in
`apps/api`. On 23 Sep 2026 those included `lib/auth.ts`, `lib/permissions.ts`, `lib/requestContext.ts`
and `lib/scope.ts` — exactly the files FLUTTER-004 consumes, so **FLUTTER-004 must re-read them before
modelling the session**. Earlier the same session had `prisma/schema.prisma`, `lib/audit.ts`,
`lib/errors.ts`, `lib/paymentProvider.ts`, `lib/razorpay.ts` and `lib/tenancy.ts` open, and
`npm run typecheck` fails in `apps/api` until its Prisma client is regenerated. Not this workflow's —
left untouched.

Concurrent work at planning time: another session was building SAAS-017 (payment gateways) in
`apps/api`; it was committed and blocked on the VyaparGateway API contract (`5bea798`) while this plan
was written. The Flutter workflow never touches `apps/api`. FLUTTER-027 re-reads
`lib/paymentProvider.ts` / `lib/checkout.ts` before modelling `CheckoutParams`.

---

## Pending Clarifications

Full register in modules.md §28. Items most likely to stop a module:

| Ref | Needed from | Blocks |
| --- | --- | --- |
| C4 | Product owner — is in-app SaaS plan checkout allowed under store policy? | **027 completed read-only 30 Sep 2026.** The whole checkout contract, the launcher registry and the confirm/poll rule are built and tested; `nativeLaunchers` is empty and no payment control ships (D-027-1). Answering C4 adds one launcher and one dependency, nothing more |
| C6 / C16 | Product owner — application id, app name/icon, release signing, CI | Release part of 030 |
| C7 | Product owner — crash-reporting vendor + account | Crash reporting in 030 |
| C8 | Product owner — Firebase project and credentials | **Now the only thing blocking 028.** Part A is done and verified on a device, and the app's side of device registration is built and tested against the real routes; the Firebase dependency and a real push are what remain. Push part of 028. **B4 settled 29 Sep 2026 (FLUTTER-016): SAAS-021 added `POST\|GET\|DELETE /notifications/devices` and an FCM transport (`lib/push.ts`) that sends id+category only — the hint design 028 planned for.** §12 still says neither exists |
| B13 | Web hosting — serve `/.well-known/assetlinks.json` | **The file is generated**: `apps/mobile/android/assetlinks/assetlinks.json` with `DEPLOY.md` beside it (FLUTTER-028). Until it is served the links open the browser, which the web handles — the intended fallback |
| A1 | ~~Backend — live-class `meeting.link` vs `meeting.url` on writes~~ | **Settled 29 Sep 2026 (FLUTTER-015): `link` is the field the write path validates and stores; `url` alone is refused.** See finding 15 |
| A2 | ~~Backend — `Course.price.amount` unit~~ | **Settled 23 Sep 2026 (FLUTTER-008): whole rupees.** See D-008-1 |
| A3 | Backend — VyaparGateway checkout contract | Still open, and it no longer blocks anything: an unknown provider with a page is opened, and one without is sent to the web (D-027-1) |
| C1 | Product owner — one app for all academies or white-label per academy | Nothing now; affects public catalog scope |

---

## FLUTTER-031 — Multi-Admin SaaS Integration (3 Oct 2026, UNCOMMITTED by the owner's instruction)

Backend unchanged; uses `POST /auth/register { workspace }`, `/public/academies/:slug`, codes `ACADEMY_SUSPENDED/ARCHIVED`.

- **Create account joins the named Admin's LMS:** required "LMS address" field (a pasted join link works);
  `https://shubhlms.com/join/<address>` deep link (Android intent filter `/join/`) opens it pre-filled; the request
  carries name, email, password and `workspace` only — never a role or tenant id.
- **Suspended / closed LMS:** `AccountClosedFailure` (a `ForbiddenFailure`, so existing switches hold); any
  authenticated request refused with it ends the session (`accountClosedHandlerProvider` → `handleAccountClosed`) and
  the sign-in screen gives the server's words; signing in shows "This account is suspended / has been closed".
- **No person's data survives a change of session:** `lib/app/session_scope.dart` — the app root listens for a change of
  signed-in person and invalidates the providers that held one person's data (learner home/courses, assignments,
  assessments, rank ladder, the LMS's catalogue, media auth headers, unread count, trial offer flag). Found by audit:
  `mediaAuthHeadersProvider` kept the previous person's token and `learnerHomeProvider` their home.
- **Wording:** 79 l10n strings moved from "academy" to Admin/LMS terms (`app_en.arb`, regenerated); billing strings
  say the platform confirms payments.
- **Bugs found and fixed while testing:** (1) watching the session from feature providers rebuilt the bell mid-frame
  (`markNeedsBuild` during build) — replaced by the root listener; (2) the sign-in banner titled a suspended LMS
  "We couldn't sign you in." — now its own title; (3) pre-existing: the reset-password screen's "Sign in" did
  nothing when a reset link cold-started the app (popUntil on the only route) — now goes to sign-in
  (`reset_from_link_test.dart`, fails on the old code); (4) a late 401 from a request sent before a deliberate
  sign-out could relabel it "session ended" and land on sign-in instead of Welcome (intermittent in
  `integration_test/auth_test.dart`) — expiry is now ignored once signed out (unit test).
- **Final results:** host 2,030 pass (+ the pre-existing `no_secrets_test` failure); device integration auth 5/5,
  entitlements 3/3 (app_test asserts port 4100 while this run used the 4200 relay — environment); LIVE layer C on
  the final builds: FLUTTER-031 MA-001…011 PASS, FLUTTER-004 AUTH-001…024 PASS (smoke + deep), NAV-001…005,
  DASH-001…003, ENT-002/003 PASS; ENT-001 not applicable here (expects the seeded LMS without a plan; it was put on
  a Growth trial for this run).
- **Tests:** host suite 2,028 pass (1 pre-existing failure: `no_secrets_test` flags Firebase API keys in
  `firebase_options.dart`/`google-services.json`); new `test/app/session_scope_test.dart`,
  `test/unit/multi_admin_test.dart`, session/auth-screen tests; 4 goldens regenerated for changed copy.
- **Live UI E2E (layer C) on emulator-5554, contract server with plan enforcement ON:** new module FLUTTER-031,
  MA-001…MA-011 all PASS (two Admins created through the Super Admin API; join link, pasted address, unknown address,
  per-Admin messages with learner B after learner A on one device, session restore, wrong password, instructor of A,
  Admin A's People list, API cross-LMS refusals and forged tenantId, suspended LMS sign-out/sign-in/reactivation,
  lapsed plan read-only for A's instructor and B untouched).

## Last Completed Action

3 Oct 2026 — FLUTTER-031 Multi-Admin SaaS Integration implemented and live-tested (uncommitted).

## Next Action

None startable: FLUTTER-030 waits on FLUTTER-028 (C8) and on human answers for signing,
crash reporting and store upload. The Phase 3 QA sweep is the next useful work.
