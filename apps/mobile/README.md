# ZuviloAI Mobile

The Flutter client for ZuviloAI (Android first; iOS-ready but not built). It consumes the
existing backend in `apps/api` — the backend is the source of truth, and the app never replaces or
re-implements it.

- Specification: `.claude/flutter/modules.md`
- Workflow and progress: `.claude/flutter/workflow.md`, `.claude/flutter/progress.md`

## Requirements

- Flutter 3.38.x stable (Dart 3.10.x)
- JDK 17, Android SDK platform 36
- The USB-connected physical Android test phone (Infinix X6525, adb id `11015313C8063805`) for
  device runs and integration tests — always targeted explicitly (`-d 11015313C8063805`). Emulators
  are not used unless the owner asks for one.

## Flavors

| Flavor | Entry point | Application id | Config |
| --- | --- | --- | --- |
| dev | `lib/main_dev.dart` (or `lib/main.dart`, the default) | `com.shubhlms.mobile.dev` | `config/dev.json` — local contract server at `http://10.0.2.2:4100` |
| staging | `lib/main_staging.dart` | `com.shubhlms.mobile.staging` | `config/staging.json` — **placeholder**: no staging host exists yet, so it points at production and is never used for a release |
| prod | `lib/main_prod.dart` | `com.shubhlms.mobile` | `config/prod.json` — `https://zuviloai.com/api` |

The application id is a placeholder until the final id is decided (modules.md C6).

Config files hold **public values only** (`ENV_NAME`, `API_BASE_URL`, `WEB_BASE_URL`,
`BILLING_CHECKOUT_ENABLED`, `CRASH_REPORTING_ENABLED`); `test/architecture/no_secrets_test.dart`
enforces it. Always pass the matching file:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
```

`lib/main.dart` is the default dev entry point: a plain `flutter run` (or the IDE's `main.dart`
configuration) builds the dev flavor (`default-flavor: dev` in `pubspec.yaml`). Without a define
file it targets the live server, `kDefaultApiBaseUrl` / `kDefaultWebBaseUrl` at the top of
`lib/core/config/app_config.dart` (`https://zuviloai.com/api`). To work against
the local contract server instead, forward the port and pass the dev config:

```bash
adb reverse tcp:4100 tcp:4100
flutter run --dart-define-from-file=config/dev_device.json
```

A define file always overrides the default. Staging
and prod are only ever built from `main_staging.dart` / `main_prod.dart` with their own config.

Cleartext HTTP is allowed only in debug builds and only to `10.0.2.2`, `localhost` and `127.0.0.1`
(`android/app/src/debug/res/xml/network_security_config.xml`).

## Local contract server

Integration tests and fixture capture run against the **real** API on a scratch database — never
`dev.db` or `test.db`, which other work uses (workflow §7.3):

`tool/contract_server.sh` runs the **real** API from `apps/api` against a scratch SQLite database —
never `dev.db` or `test.db`, which other work uses (workflow §7.3):

```bash
export SCRATCH=/path/to/a/scratch/dir      # never inside apps/api
tool/contract_server.sh start   # migrate + seed on first run, then serve on :4100
tool/contract_server.sh seed    # recreate the scratch database
tool/contract_server.sh stop
```

`start` leaves the server running in the background, so run it detached (it holds the terminal
otherwise). The emulator reaches it at `http://10.0.2.2:4100`; the host at `http://localhost:4100`.

Fixtures are captured from that server, with tokens and e-mail addresses scrubbed, and each one gets
a `.cmd.txt` note beside it recording the command and HTTP status:

```bash
tool/capture_fixture.sh GET /catalog/levels none catalog/levels.json
tool/capture_fixture.sh GET /learning/home student learning/home.json
```

## Code generation

Models use `freezed` + `json_serializable`; generated `*.freezed.dart` / `*.g.dart` files are
committed so a checkout builds without a generator run.

```bash
dart run build_runner build --delete-conflicting-outputs --force-jit
```

`--force-jit` is required while a transitive dependency (`path_provider_foundation` → `objective_c`)
ships native build hooks, which build_runner's AOT compile of its own build script cannot handle.

## Verification

```bash
tool/verify.sh                                  # format, analyze, tests, dev debug APK
tool/verify.sh --all-flavors                    # plus staging and prod debug APKs
DEVICE=11015313C8063805 tool/verify.sh --integration
```

`test/architecture/` enforces the layering (no Dio in widgets, no cross-feature internals), design
tokens (no hard-coded colours), no secrets, no plan-name checks, and no literal UI strings.

## Release signing

Release signing reads `android/key.properties` (git-ignored). Without it, release builds are
debug-signed for local verification only and are never distributed. Store uploads are human actions.

The Play upload key lives outside the repository, in `~/keystores/shubhlms-upload.jks` (alias
`upload`, SHA-256 `A4:9D:F4:F7:95:83:30:1C:C6:C0:FA:6F:81:1C:9E:68:66:C1:6F:BF:9E:95:DD:E8:91:FA:EB:F2:C5:4C:A8:5A`),
with its passwords in `~/keystores/shubhlms-upload.key.properties`. Keep both backed up; with
Play App Signing a lost upload key can be reset from Play Console. (The earlier
`syniastrolms-upload.jks` was never registered with Play and is kept only as a record.)

```bash
flutter build appbundle --release --flavor prod -t lib/main_prod.dart \
  --dart-define-from-file=config/prod.json
# → build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

Raise `version:` in `pubspec.yaml` (the `+N` build number is the Play `versionCode`) before every
upload. Launcher icons are rendered from the web's brand mark by `tool/make_launcher_icons.py`;
`store/` holds the Play listing icon and `store/PLAY_CONSOLE.md`, the answers the Play Console
forms ask for.
