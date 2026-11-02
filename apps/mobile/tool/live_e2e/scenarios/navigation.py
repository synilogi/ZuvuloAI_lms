"""FLUTTER-005 shells & routing, FLUTTER-006 entitlement states, FLUTTER-007 media, FLUTTER-028 deep
links (Part A) — smoke flows.

Sources: modules.md §5.2 (tabs; "every shell has an app bar with the page title"), §5.5 (Back pops
within a tab, then returns to the first tab, then exits); lib/app/routing/**; restricted_banner.dart;
AndroidManifest.xml App Links (host zuviloai.com: /reset-password/, /verify/,
/courses/, /learn/, /notifications); lib/core/links/deep_link.dart.
"""

from __future__ import annotations

import time

from harness import SEED, Ctx, scenario, seed_password
from scenarios.flows import (
    LEARNER_TABS,
    open_curriculum_lesson,
    WELCOME,
    fresh_app,
    open_login,
    open_more_item,
    sign_in_as,
    submit_login,
    tab,
    wait_learner_home,
    wait_staff_dashboard,
)

HOST = 'https://zuviloai.com'


def _learner(ctx: Ctx) -> None:
    sign_in_as(ctx.d, 'learner', SEED['learner'], seed_password(), 'Ananya')


def _app_bar_title(ctx: Ctx) -> str:
    """The shell's app bar title: the topmost heading-sized label above the content."""
    screen = ctx.d.dump()
    top = [n for n in screen.nodes if n.label and n.bounds[1] < 220 and n.cls.endswith('View') and n.bounds[0] < 300]
    return top[0].label if top else ''


# ── FLUTTER-005 ────────────────────────────────────────────────────────────────────────────────


@scenario(
    'NAV-001', 'FLUTTER-005', 'Each role lands in its own shell', slug='navigation', tier='smoke', priority='P0',
    purpose='The session decides the shell: a learner gets the learner tabs, an instructor and an admin get their staff tabs (§5.2).',
    preconditions=['seeded learner, instructor and admin'],
    actions=['Sign in as the learner', 'Sign in as the instructor', 'Sign in as the admin'],
    expected=['Learner: Home · My Learning · Explore · Live · More', 'Instructor: Dashboard · Review · Courses · Live · More', 'Admin: Dashboard · People · Courses · Review · More'],
)
def nav_001(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    d.expect_absent('no staff tabs for a learner', **tab('Dashboard'))
    ctx.shot('learner-shell')
    sign_in_as(d, 'instructor', SEED['instructor'], seed_password())
    d.expect_absent('no learner tabs for staff', **tab('My Learning'))
    ctx.shot('instructor-shell')
    sign_in_as(d, 'admin', SEED['admin'], seed_password())
    ctx.shot('admin-shell')


@scenario(
    'NAV-002', 'FLUTTER-005', 'Tabs switch screens and Back returns to the first tab before leaving', slug='navigation', tier='smoke', priority='P0',
    purpose='§5.5: Back pops within a tab, then returns to the first tab, then exits.',
    actions=['Learner: tap My Learning, Explore, Live', 'Press Back on Live'],
    expected=['Each tap selects that tab', 'Back from Live lands on Home (still in the app)'],
)
def nav_002(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    for name in ('My Learning', 'Explore', 'Live'):
        d.tap(**tab(name))
        node = d.wait(**tab(name))
        time.sleep(0.5)
        ctx.check(d.dump().find(**tab(name)).selected, f'{name} tab is not selected after tapping it')
    d.back()
    time.sleep(1)
    ctx.check(d.foreground_package() == d.package, 'Back from the Live tab left the app instead of returning to Home')
    home = d.wait(**tab('Home'))
    ctx.check(home.selected, 'Back from Live did not return to the Home tab')
    ctx.shot('back-to-home')


@scenario(
    'NAV-003', 'FLUTTER-005', 'A More page is titled with its own name', slug='navigation', tier='smoke', priority='P1',
    purpose='§5.2: "Every shell has an app bar with the page title". A page opened from More must say what it is.',
    actions=['Learner: More → Assignments', 'Read the app bar', 'More → Certificates', 'Read the app bar'],
    expected=['App bar reads "Assignments"', 'App bar reads "Certificates"'],
)
def nav_003(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    for page in ('Assignments', 'Certificates'):
        open_more_item(d, page)
        time.sleep(1.5)
        title = _app_bar_title(ctx)
        ctx.shot(f'{page.lower()}-title')
        ctx.check(title == page, f'opened {page} from More, but the app bar reads {title!r}')


@scenario(
    'NAV-004', 'FLUTTER-005', 'Back from a More page returns to the app, not out of it', slug='navigation', tier='smoke', priority='P1',
    purpose='§5.5: Back from a page reached through More goes back inside the app (to the first tab), never straight out of it.',
    actions=['Learner: More → Assignments', 'Press Back'],
    expected=['Still in the app, on Home'],
)
def nav_004(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    d.tap(**tab('Explore'))
    open_more_item(d, 'Assignments')
    d.wait(contains='Puzzle-solving exercise', timeout=20)
    d.back()
    time.sleep(1.5)
    ctx.check(d.foreground_package() == d.package, 'Back from Assignments closed the app')
    wait_learner_home(d, 'Ananya')
    ctx.shot('back-from-more-page')


@scenario(
    'NAV-005', 'FLUTTER-005', 'An unknown link shows the not-found screen with a way home', slug='navigation', tier='smoke', priority='P2',
    purpose='A signed-in person following a link the app does not know gets a clear dead end and a Back that goes home.',
    actions=['Sign in as the learner', f'Open {HOST}/courses/BAD_SLUG_x in the app', 'Tap Back'],
    expected=['"This isn\'t available." screen', 'Back returns to the learner home'],
)
def nav_005(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    d.open_link(f'{HOST}/courses/BAD_SLUG_x', explicit=True)
    d.wait(contains="isn't available", timeout=30)
    ctx.shot('not-found')
    d.tap(label='Back', cls='Button')
    wait_learner_home(d, 'Ananya')


# ── FLUTTER-006 ────────────────────────────────────────────────────────────────────────────────


@scenario(
    'ENT-001', 'FLUTTER-006', "An academy admin is told the academy has no active plan", slug='entitlements', tier='smoke', priority='P0',
    purpose='The admin sees the academy-wide restricted banner (the seed academy has no subscription, /tenant/subscription/usage reports restricted) and it leads to Billing.',
    preconditions=['seed academy without a subscription (GET /tenant/subscription/usage → restricted: true)'],
    actions=['Check restricted from the API (as admin)', 'Sign in as the admin', 'Read the banner', 'Tap Review plan'],
    expected=['"Your academy has no active plan" banner with "Review plan"', 'Review plan opens "Your plan"'],
)
def ent_001(ctx: Ctx) -> None:
    d = ctx.d
    usage = ctx.api.ok('GET', '/tenant/subscription/usage', token=ctx.api.token('admin'))
    ctx.check(usage.get('restricted') is True, f'precondition: the academy is expected to be restricted, the API says {str(usage)[:200]}')
    sign_in_as(d, 'admin', SEED['admin'], seed_password())
    d.wait(label='Your LMS has no active plan', timeout=20)
    ctx.shot('restricted-banner')
    d.tap(label='Review plan')
    d.wait(label='Your plan', timeout=30)
    ctx.shot('billing')


@scenario(
    'ENT-002', 'FLUTTER-006', 'Instructor and learner do not see the billing banner or Billing', slug='entitlements', tier='smoke', priority='P1',
    purpose='The banner and Billing are for whoever may view billing — not an instructor, not a learner.',
    actions=['Sign in as the instructor; open More', 'Sign in as the learner'],
    expected=['Instructor: no banner, no Billing in More', 'Learner: no banner'],
)
def ent_002(ctx: Ctx) -> None:
    d = ctx.d
    sign_in_as(d, 'instructor', SEED['instructor'], seed_password())
    d.expect_absent('no plan banner for an instructor', label='Your LMS has no active plan')
    d.tap(regex=r'^More\nTab \d of \d')
    d.wait(label='Dismiss')
    time.sleep(1)
    d.expect_absent('no Billing for an instructor', label='Billing', cls='View')
    ctx.shot('instructor-more')
    d.back()
    _learner(ctx)
    d.expect_absent('no plan banner for a learner', label='Your LMS has no active plan')


@scenario(
    'ENT-003', 'FLUTTER-006', "A learner following a staff link stays in the learner app", slug='entitlements', tier='smoke', priority='P1',
    purpose="Another role's screen is not reachable by link (UX guard; the server refuses anyway).",
    actions=['Sign in as the learner', f'Open {HOST}/staff/billing in the app'],
    expected=['The learner home, not billing and not a staff shell'],
)
def ent_003(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    d.open_link(f'{HOST}/staff/billing', explicit=True)
    time.sleep(3)
    d.expect_absent('no billing for a learner', label='Your plan')
    d.expect_absent('no staff shell', **tab('Dashboard'))
    wait_learner_home(d, 'Ananya')
    ctx.shot('learner-kept-out')


# ── FLUTTER-007 ────────────────────────────────────────────────────────────────────────────────


@scenario(
    'MEDIA-001', 'FLUTTER-007', 'Choose a file opens the system picker and coming back is safe', slug='media', tier='smoke', priority='P1',
    purpose="A file assignment's upload hands over to Android's document picker; backing out returns to the same assignment with nothing attached.",
    preconditions=['a published file-format assignment on a course the learner is enrolled in (created by the scenario through the staff API, deleted afterwards)'],
    data=['assignment "E2E file upload <stamp>" (format file) on the learner\'s first enrolled course'],
    actions=['Instructor API: create and publish the file assignment', 'Learner: More → Assignments → that assignment', 'Tap Choose a file', 'Back out of the system picker'],
    expected=["Android's document picker opens (another package in front)", 'Back returns to the same assignment, no crash, nothing attached'],
    cleanup='The assignment is deleted through the staff API',
)
def media_001(ctx: Ctx) -> None:
    d = ctx.d
    learner = ctx.api.token('learner')
    staff = ctx.api.token('instructor')
    staff_courses = {c['id'] for c in ctx.api.ok('GET', '/courses', token=staff)['rows']}
    course = next(c['course'] for c in ctx.api.ok('GET', '/learning/courses', token=learner)['courses'] if c['course']['id'] in staff_courses)
    title = f'E2E file upload {int(time.time()) % 100000}'
    created = ctx.api.ok('POST', '/assignments', {
        'courseId': course['id'], 'title': title, 'format': 'file', 'status': 'published',
        'instructions': 'Upload a PDF or an image of your worked solution. Created by the live E2E suite and removed afterwards.',
        'due': {'kind': 'none'},
    }, token=staff)
    aid = created.get('id') or created.get('assignment', {}).get('id')
    try:
        _learner(ctx)
        open_more_item(d, 'Assignments')
        d.tap(d.scroll_to(contains=title, max_swipes=6))
        d.wait(label='The brief', timeout=30)
        d.tap(d.scroll_to(label='Choose a file', max_swipes=10))
        time.sleep(3)
        ctx.check(d.foreground_package() != d.package, 'the system document picker did not open')
        ctx.shot('system-picker')
        d.back()
        d.wait_focused()
        d.wait(contains=title, timeout=20)
        d.scroll_to(label='Choose a file', max_swipes=10)
        ctx.shot('back-on-assignment')
    finally:
        if aid:
            ctx.api.call('DELETE', f'/assignments/{aid}', token=staff)


@scenario(
    'MEDIA-002', 'FLUTTER-007', 'A preview lesson without a file says so instead of failing', slug='media', tier='smoke', priority='P2',
    purpose="The seeded preview video has no media attached; the player must show its empty state, not an error or a spinner.",
    actions=['Welcome → Browse courses → the first course', 'Curriculum → open its first chapter', 'Tap the free-preview lesson (isPreview in GET /catalog/courses)'],
    expected=['"Nothing to show yet" with "The academy has not attached a file to this lesson."'],
)
def media_002(ctx: Ctx) -> None:
    d = ctx.d
    course = ctx.api.ok('GET', '/catalog/courses')[0]
    chapter = next(ch for ch in course['chapters'] if any(l.get('isPreview') for l in ch['lessons']))
    lesson = next(l for l in chapter['lessons'] if l.get('isPreview'))
    fresh_app(d)
    d.tap(label='Browse courses', cls='Button')
    d.tap(d.wait(contains=course['title'], timeout=30))
    open_curriculum_lesson(d, chapter['title'], lesson['title'])
    d.wait(label='Nothing to show yet', timeout=30)
    ctx.shot('no-media')


# ── FLUTTER-028 (Part A: deep links) ───────────────────────────────────────────────────────────


@scenario(
    'LINK-001', 'FLUTTER-028', 'A certificate verification link opens the public result', slug='deep-links', tier='smoke', priority='P0',
    purpose='/verify/<credential> from outside the app opens the in-app result for that same credential, signed out.',
    preconditions=["the learner's own issued certificate (GET /learning/certificates)"],
    actions=['Pick the learner\'s issued credential from the API', f'Open {HOST}/verify/<id> with the app signed out'],
    expected=['"This certificate is valid" for that credential ID, awarded to the same learner'],
)
def link_001(ctx: Ctx) -> None:
    d = ctx.d
    certs = ctx.api.ok('GET', '/learning/certificates', token=ctx.api.token('learner'))
    issued = certs['issued']
    ctx.check(bool(issued), 'the learner has no issued certificate')
    cred = issued[0]['certificate']['credentialId']
    fresh_app(d)
    d.open_link(f'{HOST}/verify/{cred}')
    d.wait(label='This certificate is valid', timeout=30)
    d.expect('the same credential', contains=cred)
    d.expect('awarded to the same learner', contains='Ananya')
    ctx.shot('verified')


@scenario(
    'LINK-002', 'FLUTTER-028', 'A course link opens that course\'s public page', slug='deep-links', tier='smoke', priority='P1',
    purpose='/courses/<slug> maps to the catalogue page of exactly that course.',
    actions=['Pick a published course slug from GET /catalog/courses', f'Open {HOST}/courses/<slug>'],
    expected=['The public course page for that title, with "Sign in to enrol"'],
)
def link_002(ctx: Ctx) -> None:
    d = ctx.d
    course = ctx.api.ok('GET', '/catalog/courses')[-1]
    fresh_app(d)
    d.open_link(f"{HOST}/courses/{course['slug']}")
    d.wait(contains=course['title'], timeout=30)
    d.scroll_to(label='Sign in to enrol', max_swipes=6)
    ctx.shot('course-link')


@scenario(
    'LINK-003', 'FLUTTER-028', 'A protected link survives signing in from Welcome', slug='deep-links', tier='smoke', priority='P1',
    purpose='A signed-out person following /notifications is asked to sign in and then taken where the link pointed.',
    actions=['Signed out: open the notifications link', 'Welcome → Sign in → sign in as the learner'],
    expected=['After signing in, the Notifications page — not just the home'],
)
def link_003(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    d.open_link(f'{HOST}/notifications')
    time.sleep(2)
    open_login(d)
    submit_login(d, SEED['learner'], seed_password())
    time.sleep(4)
    ctx.shot('after-sign-in')
    d.wait(regex=r'^(All|Unread)', timeout=20)
