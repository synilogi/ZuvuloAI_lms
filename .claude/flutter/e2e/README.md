# LIVE UI E2E — the Flutter app operated on the Android Emulator like a person would

This is the third test layer of the Flutter workflow, separate from the other two:

| Layer | What runs | Where it acts | Evidence it gives |
| --- | --- | --- | --- |
| A. Host (`flutter test`) | unit, widget, golden, a11y tests | the Dart VM on the Mac | the code behaves as written |
| B. Device (`flutter test integration_test`) | 182 tests in `apps/mobile/integration_test/` | **inside** the app's isolate on the emulator, driving widgets through `WidgetTester` | the code works on Android against the real API |
| **C. LIVE UI E2E (this)** | scenarios in `apps/mobile/tool/live_e2e/scenarios/` | **outside** the app: the installed dev APK, read through Android's accessibility tree (`uiautomator dump`) and driven with `adb shell input` taps, text, keys and swipes | a person using the shipped build gets the promised result |

A pass in A or B is never reported as a pass in C. C links nothing into the app, uses no
`WidgetTester`, and can only see what Android sees, so a missing semantics label, a tap that misses
because a layout moved, a dialog that never appears, or a session the server still holds are all
caught here.

## Files

| Path | What |
| --- | --- |
| `apps/mobile/tool/live_e2e/driver.py` | the device driver: emulator-only guard, screen reading, semantic selectors, tap/type/scroll/back, network on/off, screenshots, logcat, uncaught Flutter error detection |
| `apps/mobile/tool/live_e2e/harness.py` | scenario declaration, per-scenario context, test identities, the backend helper (setup / cleanup / same-entity cross-checks only), the dev mail outbox reader |
| `apps/mobile/tool/live_e2e/netem.py` | host relay :4200 → contract server :4201 that can hold responses back, so loading states can be observed |
| `apps/mobile/tool/live_e2e/runner.py` | runs scenarios in module dependency order, persists every result, writes the matrix and the spec docs |
| `apps/mobile/tool/live_e2e/scenarios/*.py` | the scenarios, one file per module |
| `apps/mobile/tool/live_e2e.sh` | entry point |
| `.claude/flutter/e2e/results.json` | persistent, resumable results (status, evidence paths, failure, fix, attempts, checkpoint) |
| `.claude/flutter/e2e/matrix.md` | the test matrix, regenerated after every scenario |
| `.claude/flutter/e2e/FLUTTER-0XX-<slug>.md` | each module's scenario specs (ID, purpose, preconditions, data, actions, expected, evidence, cleanup, priority, repeatability), generated from the scenario declarations so they cannot drift |
| `apps/mobile/.live_e2e/` (git-ignored) | evidence per run and scenario (screenshots, failure logcat, screen dump, traceback) and the local state file |

## Running

```bash
cd apps/mobile
SCRATCH=<scratch dir>
# 0. the E2E build's own config (git-ignored): dev.json with API_BASE_URL http://10.0.2.2:4200, so the
#    live layer never shares a port — or a database — with another session's contract server on 4100
python3 -c "import json;c=json.load(open('config/dev.json'));c['API_BASE_URL']='http://10.0.2.2:4200';json.dump(c,open('config/dev_e2e.local.json','w'),indent=2)"
# 1. contract server on this scratch database, on 4201; the relay takes 4200, the app's port
SCRATCH=$SCRATCH PORT=4201 tool/contract_server.sh start
python3 tool/live_e2e/netem.py serve             # :4200 → :4201 (run as a tracked background task)
# 2. emulator (visible window; software GPU avoids a black window on dual-GPU Macs)
~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36 -gpu swiftshader_indirect -no-snapshot-save -no-boot-anim -no-audio
# 3. the app under test
tool/live_e2e.sh install
# 4. scenarios
SCRATCH=$SCRATCH E2E_SEED_PASSWORD=<seed demo password> tool/live_e2e.sh run --module FLUTTER-004
tool/live_e2e.sh run --resume          # after a crash: skips what already passed or is blocked
tool/live_e2e.sh run --failed          # re-run only the failures
tool/live_e2e.sh run --scenario AUTH-013
tool/live_e2e.sh list | docs | matrix | inspect
```

## Emulator settings the runner applies

- **System animations off** (`window_animation_scale`, `transition_animation_scale`,
  `animator_duration_scale` = 0), the standard UI-automation setting. With the software renderer
  they were the largest CPU cost, and under that load input sent during an activity launch produced
  an ANR ("Application does not have a focused window") that was the environment's, not the app's.
  Flutter reads this setting as "reduce animations", so the app's reduced-motion path is the one
  exercised here; motion itself is covered by the host goldens.
- **Input only to a focused window.** Every launch is `am start -W` followed by a wait for the app's
  window focus.
- **A system ANR or crash dialog fails the scenario at once** with the dialog's title and the
  logcat reason. It is never tapped through inside a scenario; the next scenario's fresh start
  closes it.

## Rules the runner enforces

- **Emulator only.** The device id must match `emulator-<n>` **and** report `ro.kernel.qemu=1`;
  anything else is refused before a single tap.
- **Local data only, and the right local data.** The backend must be `localhost`, the APK's config
  must point at `10.0.2.2` or `localhost`, `/health` must answer through the relay and directly, and
  the process listening on the API port must have **this** scratch database open (`lsof`). A
  production or shared host, or another session's server on the port, stops the run.
- **No secrets in the repository.** The seeded demo password comes from `E2E_SEED_PASSWORD`. New
  accounts are synthetic (`ai_e2e_<stamp>_<tag>@example.test`) and use the same password; only their
  e-mail and name are kept, in the git-ignored state file.
- **The same entity.** Every assertion names the account or record the scenario selected or created:
  a greeting is checked against that account's first name, a profile against that account's e-mail,
  a server cross-check against the session that account opened.
- **No pass without evidence.** A scenario passes only if every assertion held on the screen and the
  app logged no uncaught Flutter error meanwhile; each pass keeps at least one screenshot.
- **Failures are classified before anything changes**: test defect, environment defect,
  backend/contract issue, application bug, external blocker. Only an application bug changes
  `apps/mobile/lib`; it is fixed at the root, verified (format, analyze, host tests, rebuild,
  reinstall), and the failed scenario and its neighbours re-run. At most five meaningful attempts per
  unique failure, then BLOCKED with the evidence.
