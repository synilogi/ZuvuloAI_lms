"""FLUTTER-000 Bootstrap, FLUTTER-001 Design System, FLUTTER-002 Core Infrastructure and
FLUTTER-003 API Client — the parts of them a person can actually touch.

Discovered from: android/app/build.gradle.kts (dev launcher label), lib/main_dev.dart and
lib/dev/gallery/** (the dev-only component gallery reached from Profile), lib/app/routing/shells
(OfflineBanner in the shell), lib/core/connectivity, and the splash's SessionUnavailable state
(lib/features/auth/presentation/screens/splash_screen.dart).
"""

from __future__ import annotations

import time

from harness import SEED, Ctx, scenario, seed_password
from scenarios.flows import (
    WELCOME,
    fresh_app,
    open_profile,
    relaunch,
    submit_login,
    wait_learner_home,
)

LEARNER_FIRST = 'Ananya'
OFFLINE_BANNER = "You're offline. Showing what was loaded."


def _signed_in_learner(ctx: Ctx) -> None:
    fresh_app(ctx.d)
    submit_login(ctx.d, SEED['learner'], seed_password())
    wait_learner_home(ctx.d, LEARNER_FIRST)


# ── FLUTTER-000 ────────────────────────────────────────────────────────────────────────────────


@scenario(
    'BOOT-001', 'FLUTTER-000', 'Open the dev build from the launcher like a person', tier='smoke', slug='bootstrap', priority='P0',
    purpose='The dev flavor is installed under its own launcher label and opens on Welcome when tapped there.',
    preconditions=['dev flavor installed'],
    actions=['Go to the Android home screen', 'Open the app drawer', 'Tap "ZuviloAI Dev"'],
    expected=['The drawer lists "ZuviloAI Dev"', 'Tapping it brings the dev package to the foreground on Welcome'],
)
def boot_001(ctx: Ctx) -> None:
    d = ctx.d
    d.stop()
    d.reset()
    d.key('KEYCODE_HOME')
    time.sleep(1.5)
    w, h = d.screen_size()
    d.swipe(w // 2, int(h * 0.85), w // 2, int(h * 0.25), 400)  # open the app drawer
    icon = d.wait(label='ZuviloAI Dev', timeout=15)
    ctx.shot('app-drawer')
    d.tap(icon)
    d.wait_focused()
    d.wait(timeout=40, **WELCOME)
    ctx.check(d.foreground_package() == d.package, f'foreground is {d.foreground_package()}, not the dev build')
    ctx.shot('welcome')


@scenario(
    'BOOT-002', 'FLUTTER-000', 'Back on Welcome leaves the app cleanly; reopening returns to Welcome', slug='bootstrap', priority='P2',
    purpose='The root screen hands Back to Android (no blank page, no crash) and a reopen starts normally.',
    actions=['Launch to Welcome', 'Press Back', 'Reopen the app'],
    expected=['The launcher is in front after Back', 'No crash logged', 'Welcome again on reopen'],
)
def boot_002(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    d.back()
    time.sleep(1.5)
    ctx.check(d.foreground_package() != d.package, 'Back on the root screen should leave the app')
    d.launch()
    d.wait(timeout=40, **WELCOME)
    ctx.shot('reopened')


# ── FLUTTER-001 ────────────────────────────────────────────────────────────────────────────────

GALLERY_GROUPS = ('Actions', 'Inputs', 'Containers', 'Status', 'Charts', 'Overlays', 'States', 'Learning')


def _open_gallery(ctx: Ctx) -> None:
    _signed_in_learner(ctx)
    open_profile(ctx.d, SEED['learner'])
    ctx.d.tap(ctx.d.scroll_to(label='Component gallery'))
    ctx.d.wait(label='Component gallery', timeout=20)
    ctx.d.wait(label='Actions')


def _gallery_tap(ctx: Ctx, label: str) -> None:
    ctx.d.tap(ctx.d.scroll_to(label=label, cls='Button', max_swipes=40))


@scenario(
    'DS-001', 'FLUTTER-001', 'The component gallery opens in the dev build and shows every group', tier='smoke', slug='design-system', priority='P1',
    purpose='The hidden gallery (dev builds only) is reachable from Profile and renders all eight component groups.',
    preconditions=['dev flavor', 'learner signed in'],
    actions=['Profile → Component gallery', 'Scroll from top to bottom'],
    expected=[f'Group headers {", ".join(GALLERY_GROUPS)} each appear', 'Theme/text-size chips (Dark, 100%, 130%, 200%) present'],
)
def ds_001(ctx: Ctx) -> None:
    d = ctx.d
    _open_gallery(ctx)
    for chip in ('Dark', '100%', '200%'):
        d.expect(f'gallery toggle {chip!r}', label=chip)
    ctx.shot('gallery-top')
    for group in GALLERY_GROUPS:
        d.scroll_to(label=group, max_swipes=40)
    ctx.shot('gallery-bottom')


@scenario(
    'DS-002', 'FLUTTER-001', 'Confirm dialog: cancel keeps things, confirm closes', tier='smoke', slug='design-system', priority='P1',
    purpose='The shared confirmation dialog opens, Cancel dismisses it, Publish confirms it.',
    actions=['Gallery → Confirm dialog', 'Cancel', 'Confirm dialog again', 'Publish'],
    expected=['"Publish course?" with Publish and Cancel', 'Dialog gone after Cancel', 'Dialog gone after Publish'],
)
def ds_002(ctx: Ctx) -> None:
    d = ctx.d
    _open_gallery(ctx)
    _gallery_tap(ctx, 'Confirm dialog')
    d.wait(label='Publish course?')
    ctx.shot('confirm-dialog')
    d.tap(label='Cancel', cls='Button')
    d.wait_gone(label='Publish course?')
    _gallery_tap(ctx, 'Confirm dialog')
    d.wait(label='Publish course?')
    d.tap(label='Publish', cls='Button')
    d.wait_gone(label='Publish course?')


@scenario(
    'DS-003', 'FLUTTER-001', 'Destructive dialog needs the acknowledgement and shows a refusal', slug='design-system', priority='P1',
    purpose="A destructive action cannot be confirmed until \"I understand this can't be undone\" is ticked, and its error stays in the dialog.",
    actions=['Gallery → Dialog with error', 'Try Archive before ticking', 'Tick the acknowledgement', 'Archive'],
    expected=['Archive disabled until ticked', 'After Archive: "The course has live classes scheduled." inside the dialog'],
)
def ds_003(ctx: Ctx) -> None:
    d = ctx.d
    _open_gallery(ctx)
    _gallery_tap(ctx, 'Dialog with error')
    d.wait(label='Archive course?')
    archive = d.wait(label='Archive', cls='Button')
    ctx.check(not archive.enabled, 'Archive must be disabled before the acknowledgement is ticked')
    d.tap(contains="I understand this can't be undone")
    d.wait(label='Archive', cls='Button', enabled=True)
    d.tap(label='Archive', cls='Button')
    d.wait(label='The course has live classes scheduled.', timeout=15)
    d.expect('the refusal is shown inside the dialog', label='Archive course?')
    ctx.shot('destructive-error')


@scenario(
    'DS-004', 'FLUTTER-001', 'Snackbar with Undo and the filter sheet', slug='design-system', priority='P2',
    purpose='Transient feedback offers Undo; a bottom sheet opens and closes with its own actions.',
    actions=['Gallery → Snackbar with undo', 'Read the snackbar', 'Gallery → Filter sheet', 'Apply'],
    expected=['"Notification removed" with Undo', '"Filter students" sheet with Reset/Apply, closed by Apply'],
)
def ds_004(ctx: Ctx) -> None:
    d = ctx.d
    _open_gallery(ctx)
    _gallery_tap(ctx, 'Snackbar with undo')
    d.wait(label='Notification removed', timeout=10)
    d.expect('undo action', label='Undo')
    ctx.shot('snackbar')
    _gallery_tap(ctx, 'Filter sheet')
    d.wait(label='Filter students')
    d.expect('reset', label='Reset')
    d.tap(label='Apply')
    d.wait_gone(label='Filter students')


@scenario(
    'DS-005', 'FLUTTER-001', 'Dark theme and 200% text render the same components', slug='design-system', priority='P2',
    purpose='The gallery switches to dark and to 200% text without losing any component (layout overflow is caught in logcat).',
    actions=['Gallery → Dark', 'Gallery → 200%', 'Scroll the whole gallery'],
    expected=['Dark and 200% chips selected', 'All groups still present', 'No RenderFlex overflow logged'],
)
def ds_005(ctx: Ctx) -> None:
    d = ctx.d
    _open_gallery(ctx)
    d.tap(label='Dark')
    d.tap(label='200%')
    time.sleep(1)
    ctx.shot('dark-200')
    for group in GALLERY_GROUPS:
        d.scroll_to(label=group, max_swipes=60)
    ctx.shot('dark-200-bottom')


# ── FLUTTER-002 ────────────────────────────────────────────────────────────────────────────────


@scenario(
    'CORE-001', 'FLUTTER-002', 'Offline banner appears when the device loses its network and clears on return', tier='smoke', slug='core', priority='P0',
    purpose="The connectivity monitor tells a signed-in person they are offline and that they are seeing what was already loaded.",
    preconditions=['learner signed in'],
    actions=['Sign in as the learner', 'Turn Wi-Fi and data off', 'Read the shell', 'Turn them back on'],
    expected=[f'"{OFFLINE_BANNER}" appears above the content', 'Content already loaded stays on screen', 'The banner disappears once online'],
    cleanup='Network restored even on failure',
)
def core_001(ctx: Ctx) -> None:
    d = ctx.d
    _signed_in_learner(ctx)
    ctx.offline()
    d.wait(label=OFFLINE_BANNER, timeout=20)
    wait_learner_home(d, LEARNER_FIRST)
    ctx.shot('offline-banner')
    ctx.online()
    d.wait_gone(label=OFFLINE_BANNER, timeout=30)
    ctx.shot('back-online')


# ── FLUTTER-003 ────────────────────────────────────────────────────────────────────────────────


@scenario(
    'API-001', 'FLUTTER-003', "Academy unreachable at launch: keep the session, offer Try again", tier='smoke', slug='api-client', priority='P0',
    purpose="A stored session is not thrown away because the server cannot be reached; the splash explains and recovers.",
    preconditions=['learner signed in'],
    actions=['Sign in as the learner', 'Make the API unreachable (relay refuses; device stays online)', 'Relaunch', 'Restore the API', 'Tap Try again'],
    expected=['"Can\'t reach ZuviloAI" with "Try again" — not the sign-in form', 'After Try again: the learner home for Ananya, without signing in again'],
    cleanup='API reachable again even on failure',
)
def api_001(ctx: Ctx) -> None:
    d = ctx.d
    _signed_in_learner(ctx)
    ctx.server_unreachable()
    relaunch(d)
    d.wait(label="Can't reach ZuviloAI", timeout=60)
    d.expect('retry offered', label='Try again', cls='Button')
    d.expect_absent('the session must not be dropped', field='Email')
    ctx.shot('cannot-reach')
    ctx.normal_network()
    d.tap(label='Try again', cls='Button')
    wait_learner_home(d, LEARNER_FIRST, timeout=40)
    ctx.shot('recovered')


@scenario(
    'API-002', 'FLUTTER-003', 'A screen that fails to load offers a retry that works', slug='api-client', priority='P1',
    purpose='A data screen opened while the API is unreachable shows the shared error state, and its retry loads the real data.',
    preconditions=['learner signed in'],
    actions=['Sign in as the learner', 'Make the API unreachable', 'Open the My Learning tab', 'Restore the API', 'Tap the retry action'],
    expected=['An error state with a retry action (no endless spinner, no crash)', "After retry: the first of this learner's own enrolled courses (read from /learning/courses) is listed"],
    cleanup='API reachable again even on failure',
)
def api_002(ctx: Ctx) -> None:
    d = ctx.d
    _signed_in_learner(ctx)
    # The course to look for is chosen *from this learner's own* enrolments, not assumed.
    titles = [c['course']['title'] for c in ctx.api.ok('GET', '/learning/courses', token=ctx.api.token('learner'))['courses']]
    ctx.check(bool(titles), 'the learner has no enrolled courses to check against')
    ctx.server_unreachable()
    d.tap(regex=r'^My Learning\nTab')
    retry = d.wait(regex=r'^(Try again|Retry)$', cls='Button', timeout=40)
    ctx.shot('load-error')
    ctx.normal_network()
    d.tap(retry)
    d.wait(contains=titles[0], timeout=30)
    ctx.shot('loaded-after-retry')
