"""FLUTTER-004 Secure Session & Authentication — LIVE UI E2E.

Discovered from: lib/features/auth/** (welcome, sign in, register, forgot/reset password, session
controller, unsupported role), lib/features/profile (sign out), apps/api/src/routes/auth.ts and
students.ts (refusals, sessions, suspension), and modules.md#flutter-004's acceptance criteria.
"""

from __future__ import annotations

import time

from harness import SEED, Ctx, load_state, new_identity, outbox_link, save_state, scenario, seed_password
from scenarios.flows import (
    LOGIN_FAILED,
    LOGIN_FIELD,
    SIGN_IN_BUTTON,
    WELCOME,
    fresh_app,
    greeting,
    open_login,
    open_profile,
    relaunch,
    sign_out,
    submit_login,
    wait_learner_home,
    wait_new_learner_home,
)

M = 'FLUTTER-004'
SLUG = 'auth'
LEARNER_FIRST = 'Ananya'
SUSPENDED = 'This account is suspended. Contact your admin to continue.'
REGISTER_TITLE = 'Create your account'
# The seeded LMS's address — a learner joins an Admin's LMS by its address (multi-admin SaaS).
SEEDED_LMS = 'default'


def _no_home(ctx: Ctx) -> None:
    ctx.d.expect_absent('the learner home must not open', regex=r'^Good (morning|afternoon|evening), ')
    ctx.d.expect_absent('no learner tab bar while signed out', regex=r'^Home\nTab 1 of')


def _sessions(ctx: Ctx, email: str, password: str) -> list[dict]:
    """The account's open sessions as the server lists them (cross-check only). Listing them needs a
    session of its own, which is ended again straight away so it never pollutes the count."""
    token = ctx.api.login(email, password)
    rows = ctx.api.ok('GET', '/auth/sessions', token=token)['sessions']
    ctx.api.call('POST', '/auth/logout', token=token)
    return [r for r in rows if not r.get('current')]


def _assert_profile(ctx: Ctx, ident: dict) -> None:
    """Profile names exactly this account — the proof of *whose* (empty) home is on screen."""
    card = open_profile(ctx.d, ident['email'])
    for part in (ident['name'], ident['email'], 'Learner'):
        ctx.check(part in card.label, f'profile card does not show {part!r}: {card.label!r}')


def _new_home(ctx: Ctx, ident: dict) -> None:
    wait_new_learner_home(ctx.d)
    _assert_profile(ctx, ident)


def _identity(ctx: Ctx) -> dict:
    state = load_state()
    ident = state.get('auth_new_account')
    if not ident:
        ident = {k: v for k, v in new_identity().items() if k != 'password'}
        state['auth_new_account'] = ident
        save_state(state)
    return {**ident, 'password': seed_password()}


# ── launch and the form's own checks ───────────────────────────────────────────────────────────


@scenario(
    'AUTH-001', M, 'Cold launch shows Welcome, then the sign-in form', tier='smoke', slug=SLUG, priority='P0',
    purpose='A first-run app opens on the unauthenticated Welcome screen and its Sign in action opens the form.',
    preconditions=['dev flavor installed', 'app data cleared'],
    actions=['Clear app data', 'Launch the app', 'Read the Welcome screen', 'Tap Sign in'],
    expected=[
        'Welcome shows the headline and Sign in / Create account / Browse courses / Verify a certificate / Help centre',
        'No learner home and no tab bar',
        'Sign in screen shows Email, Password, Show password, Sign in, Forgot password?, Create account',
    ],
    evidence=['welcome screenshot', 'sign-in screenshot'],
)
def auth_001(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    for label in ('Sign in', 'Create account', 'Browse courses', 'Verify a certificate', 'Help centre'):
        d.expect(f'Welcome action {label!r}', label=label, cls='Button')
    _no_home(ctx)
    ctx.shot('welcome')
    open_login(d)
    d.expect('Sign in title', label='Sign in', cls='View')
    d.expect('Password field', field='Password')
    d.expect('Show password toggle', label='Show password', cls='Button')
    for label in ('Sign in', 'Forgot password?', 'Create account'):
        d.expect(f'sign-in action {label!r}', label=label, cls='Button')
    ctx.shot('sign-in')


@scenario(
    'AUTH-002', M, 'Empty email and password are refused on the device', tier='smoke', slug=SLUG, priority='P0',
    purpose='Submitting an empty form shows both field errors and sends nothing.',
    preconditions=['signed out'],
    actions=['Open Sign in', 'Leave both fields empty', 'Tap Sign in'],
    expected=['"Enter a valid email address." under Email', '"Enter your password." under Password', 'No server error banner', 'Still on Sign in'],
)
def auth_002(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    open_login(d)
    d.tap(**SIGN_IN_BUTTON)
    d.wait(label='Enter a valid email address.')
    d.expect('password required', label='Enter your password.')
    d.expect_absent('no server refusal for a form that was never sent', contains=LOGIN_FAILED)
    d.expect('still on sign in', **LOGIN_FIELD)
    _no_home(ctx)
    ctx.shot('empty-validation')


@scenario(
    'AUTH-003', M, 'Malformed email is refused', slug=SLUG, priority='P1',
    purpose='An address without a domain is caught by the client check before any request.',
    preconditions=['signed out'],
    data=['email "not-an-email"', 'any password'],
    actions=['Type "not-an-email" into Email', 'Type a password', 'Tap Sign in'],
    expected=['"Enter a valid email address." shown', 'No password error', 'No server banner', 'Still on Sign in'],
)
def auth_003(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, 'not-an-email', 'whatever-123')
    d.wait(label='Enter a valid email address.')
    d.expect_absent('password was given', label='Enter your password.')
    d.expect_absent('nothing was sent', contains=LOGIN_FAILED)
    d.expect('typed value kept', label='not-an-email')
    _no_home(ctx)
    ctx.shot('invalid-email')


@scenario(
    'AUTH-004', M, 'Valid email with an empty password is refused', slug=SLUG, priority='P1',
    purpose='Only the password error appears when only the password is missing.',
    preconditions=['signed out'],
    data=['seeded learner email'],
    actions=['Type the learner email', 'Leave Password empty', 'Tap Sign in'],
    expected=['"Enter your password." shown', 'No email error', 'Still on Sign in'],
)
def auth_004(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, SEED['learner'], '')
    d.wait(label='Enter your password.')
    d.expect_absent('the email is valid', label='Enter a valid email address.')
    d.expect_absent('nothing was sent', contains=LOGIN_FAILED)
    _no_home(ctx)
    ctx.shot('password-required')


@scenario(
    'AUTH-005', M, 'Empty email with a password is refused', slug=SLUG, priority='P1',
    purpose='Only the email error appears when only the email is missing.',
    preconditions=['signed out'],
    actions=['Leave Email empty', 'Type a password', 'Tap Sign in'],
    expected=['"Enter a valid email address." shown', 'No password error', 'Still on Sign in'],
)
def auth_005(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, '', seed_password())
    d.wait(label='Enter a valid email address.')
    d.expect_absent('the password was given', label='Enter your password.')
    d.expect_absent('nothing was sent', contains=LOGIN_FAILED)
    _no_home(ctx)
    ctx.shot('email-required')


# ── refusals from the server ───────────────────────────────────────────────────────────────────


@scenario(
    'AUTH-006', M, 'Wrong password is refused and the person stays signed out', tier='smoke', slug=SLUG, priority='P0',
    purpose="The server's 401 is shown as the app's title plus the server's message; nothing is stored.",
    preconditions=['seeded learner exists'],
    data=['seeded learner email', 'a wrong password'],
    actions=['Sign in with the learner email and a wrong password', 'Read the banner', 'Relaunch the app'],
    expected=[
        "Banner \"We couldn't sign you in.\" with \"Incorrect email or password.\"",
        'Still on Sign in; the email stays filled in; no learner home',
        'After a relaunch the app is still signed out (Welcome)',
    ],
)
def auth_006(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, SEED['learner'], 'definitely-not-the-password')
    banner = d.wait(contains=LOGIN_FAILED, timeout=20)
    ctx.check('Incorrect email or password.' in banner.label, f'unexpected refusal text: {banner.label!r}')
    d.expect('email kept for a retry', label=SEED['learner'])
    d.expect('still on sign in', **LOGIN_FIELD)
    _no_home(ctx)
    ctx.shot('wrong-password')
    relaunch(d)
    d.wait(timeout=30, **WELCOME)
    _no_home(ctx)


@scenario(
    'AUTH-007', M, 'Unknown email gets the same refusal as a wrong password', slug=SLUG, priority='P1',
    purpose='The app does not reveal whether an account exists.',
    data=['nonexistent_<stamp>@example.test'],
    actions=['Sign in with an address that has no account'],
    expected=["Same banner text as AUTH-006 (\"Incorrect email or password.\")", 'Still signed out'],
)
def auth_007(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, f'nonexistent_{int(time.time())}@example.test', 'some-password-1')
    banner = d.wait(contains=LOGIN_FAILED, timeout=20)
    ctx.check('Incorrect email or password.' in banner.label, f'unknown account must read like a wrong password: {banner.label!r}')
    _no_home(ctx)
    ctx.shot('unknown-email')


@scenario(
    'AUTH-008', M, 'Network failure on sign-in, then retry once back online', slug=SLUG, priority='P0',
    purpose='With no network the app explains it cannot reach the academy, keeps the form, and the same tap works once online.',
    preconditions=['seeded learner exists'],
    actions=['Turn Wi-Fi and mobile data off', 'Sign in with valid credentials', 'Read the banner', 'Turn the network back on', 'Tap Sign in again'],
    expected=["Banner \"We couldn't sign you in.\" with \"You're offline. Connect to continue.\"", 'Still on Sign in while offline', 'The retry signs Ananya in'],
    cleanup='Network restored even if the scenario fails',
)
def auth_008(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    open_login(d)
    ctx.offline()
    submit_login(d, SEED['learner'], seed_password())
    banner = d.wait(contains=LOGIN_FAILED, timeout=40)
    ctx.check("You're offline. Connect to continue." in banner.label, f'offline refusal text: {banner.label!r}')
    _no_home(ctx)
    ctx.shot('offline-refusal')
    ctx.online()
    time.sleep(3)
    d.tap(**SIGN_IN_BUTTON)
    wait_learner_home(d, LEARNER_FIRST)
    ctx.shot('retry-signed-in')


# ── a successful sign-in, the session, sign-out ────────────────────────────────────────────────


@scenario(
    'AUTH-009', M, 'Valid sign-in: busy state, then that learner\'s own home', tier='smoke', slug=SLUG, priority='P0',
    purpose='The button shows its busy state while the request is in flight and the home that opens belongs to the account that signed in.',
    preconditions=['seeded learner exists'],
    data=['seeded learner (Ananya)'],
    actions=['Slow the emulator network', 'Sign in as the learner', 'Watch the Sign in button', 'Wait for home', 'Open Profile'],
    expected=[
        'Sign in button is disabled (busy) while the request runs, and the form is not left half-submitted',
        'Learner home greets "Ananya" with the five learner tabs',
        'Profile shows Ananya Rao, ananya@syniastrolms.test, Learner — the same account /auth/me returns for those credentials',
    ],
    cleanup='Network latency removed',
)
def auth_009(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    me = ctx.api.ok('GET', '/auth/me', token=ctx.api.token('learner'))['user']
    open_login(d)
    d.fill('Email', SEED['learner'])
    d.fill('Password', seed_password())
    d.hide_keyboard()
    # Held for 6 s: one accessibility read takes 3–4 s on the software-rendered emulator, so a
    # shorter hold can end before the first read and the busy state is never seen.
    ctx.slow_network(6000)
    d.tap(**SIGN_IN_BUTTON)
    busy = d.observe(7, label='Sign in', cls='Button', enabled=False)
    ctx.check(busy, 'the Sign in button never showed its busy (disabled) state during a 6s request')
    ctx.shot('busy')
    ctx.normal_network()
    wait_learner_home(d, me['name'].split()[0])
    ctx.shot('home')
    card = open_profile(d, me['email'])
    for part in (me['name'], me['email'], 'Learner'):
        ctx.check(part in card.label, f'profile card does not show {part!r}: {card.label!r}')
    ctx.shot('profile')


@scenario(
    'AUTH-010', M, 'A signed-in session survives a relaunch', slug=SLUG, priority='P0',
    purpose='The token in secure storage restores the session through GET /auth/me after the process is killed.',
    preconditions=['learner signed in (AUTH-009 or fresh sign-in)'],
    actions=['Sign in as the learner', 'Force-stop the app', 'Launch it again'],
    expected=['The learner home opens again for Ananya without the sign-in form'],
)
def auth_010(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, SEED['learner'], seed_password())
    wait_learner_home(d, LEARNER_FIRST)
    relaunch(d)
    wait_learner_home(d, LEARNER_FIRST, timeout=40)
    d.expect_absent('no sign-in form after a restore', **LOGIN_FIELD)
    ctx.shot('restored')


@scenario(
    'AUTH-011', M, 'Back from the signed-in home does not return to the sign-in form', slug=SLUG, priority='P1',
    purpose='The sign-in stack is cleared after signing in, so Back cannot land on the form (or bypass anything).',
    preconditions=['signed out'],
    actions=['Sign in as the learner', 'Press Back on the home', 'Reopen the app'],
    expected=['Back does not show Sign in or Welcome', 'Reopening shows the learner home'],
)
def auth_011(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, SEED['learner'], seed_password())
    wait_learner_home(d, LEARNER_FIRST)
    d.back()
    time.sleep(1.5)
    if d.foreground_package() == d.package:
        d.expect_absent('Back must not reopen the sign-in form', **LOGIN_FIELD)
        d.expect_absent('Back must not reopen Welcome', **WELCOME)
    d.launch()
    wait_learner_home(d, LEARNER_FIRST, timeout=40)
    ctx.shot('after-back')


@scenario(
    'AUTH-012', M, 'Sign out from Profile returns to Welcome and stays signed out', slug=SLUG, priority='P0',
    purpose='Sign out asks for confirmation, clears the session, and neither Back nor a relaunch brings the home back.',
    preconditions=['seeded learner exists'],
    actions=['Sign in as the learner', 'More → Profile → Sign out', 'Confirm in the dialog', 'Press Back', 'Relaunch'],
    expected=['A "Sign out?" confirmation appears first', 'Welcome after confirming', 'Back does not reopen the home', 'Relaunch stays on Welcome'],
)
def auth_012(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, SEED['learner'], seed_password())
    wait_learner_home(d, LEARNER_FIRST)
    sign_out(d, SEED['learner'])
    ctx.shot('signed-out')
    d.back()
    time.sleep(1.5)
    if d.foreground_package() == d.package:
        _no_home(ctx)
    relaunch(d)
    d.wait(timeout=40, **WELCOME)
    _no_home(ctx)
    d.expect_absent('a deliberate sign-out is not an expired session', label='Your session ended. Sign in again.')
    ctx.shot('relaunched-signed-out')


@scenario(
    'AUTH-013', M, 'Sign out ends the session on the server too', slug=SLUG, priority='P0',
    purpose='POST /auth/logout exists (SAAS-020, backend item B1 settled): signing out in the app must end that session server-side, not only forget the token locally.',
    preconditions=['seeded learner exists'],
    actions=['Count the learner\'s open sessions (API)', 'Sign in through the app', 'Count again (+1)', 'Sign out through the app', 'Count again'],
    expected=['Signing in opens exactly one new session', 'Signing out closes it again'],
)
def auth_013(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    pw = seed_password()
    before = {s['id'] for s in _sessions(ctx, SEED['learner'], pw)}
    submit_login(d, SEED['learner'], pw)
    wait_learner_home(d, LEARNER_FIRST)
    opened = [s for s in _sessions(ctx, SEED['learner'], pw) if s['id'] not in before]
    ctx.check(len(opened) == 1, f'signing in should open exactly one session, opened {len(opened)}')
    sign_out(d, SEED['learner'])
    time.sleep(1.5)
    still = {s['id'] for s in _sessions(ctx, SEED['learner'], pw)}
    ctx.check(opened[0]['id'] not in still, f"the app's session {opened[0]['id']} is still open on the server after signing out")
    ctx.shot('signed-out')


@scenario(
    'AUTH-014', M, 'Signing in again after signing out', tier='smoke', slug=SLUG, priority='P0',
    purpose='The sign-in form works normally after a sign-out in the same app process.',
    actions=['Sign in as the learner', 'Sign out', 'Sign in as the learner again'],
    expected=['Learner home for Ananya again'],
)
def auth_014(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, SEED['learner'], seed_password())
    wait_learner_home(d, LEARNER_FIRST)
    sign_out(d, SEED['learner'])
    submit_login(d, SEED['learner'], seed_password())
    wait_learner_home(d, LEARNER_FIRST)
    ctx.shot('signed-in-again')


@scenario(
    'AUTH-015', M, 'Rapid repeated taps on Sign in open one session', slug=SLUG, priority='P1',
    purpose='A busy form ignores further taps, so three quick taps cannot create three sessions.',
    preconditions=['seeded learner exists'],
    actions=['Fill valid credentials', 'Slow the network', 'Tap Sign in three times quickly', 'Count new sessions (API)'],
    expected=['Exactly one new server session', 'Learner home opens once'],
    cleanup='Network latency removed',
)
def auth_015(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    pw = seed_password()
    before = {s['id'] for s in _sessions(ctx, SEED['learner'], pw)}
    open_login(d)
    d.fill('Email', SEED['learner'])
    d.fill('Password', pw)
    d.hide_keyboard()
    button = d.wait(**SIGN_IN_BUTTON)
    ctx.slow_network(2500)
    x, y = button.center
    d.shell(f'input tap {x} {y}; input tap {x} {y}; input tap {x} {y}')
    ctx.normal_network()
    wait_learner_home(d, LEARNER_FIRST, timeout=40)
    opened = [s for s in _sessions(ctx, SEED['learner'], pw) if s['id'] not in before]
    ctx.check(len(opened) == 1, f'three taps opened {len(opened)} sessions')
    ctx.shot('one-session')


@scenario(
    'AUTH-016', M, 'Session ended elsewhere sends the person back to sign in', slug=SLUG, priority='P1',
    purpose='When every session of the account is revoked (logout-all from another device), the app notices on its next request and says so.',
    preconditions=['seeded learner exists'],
    actions=['Sign in as the learner in the app', 'End all of the learner\'s sessions through the API (another device)', 'Relaunch the app'],
    expected=['Sign in with "Your session ended. Sign in again."', 'No learner home'],
)
def auth_016(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, SEED['learner'], seed_password())
    wait_learner_home(d, LEARNER_FIRST)
    ctx.api.ok('POST', '/auth/logout-all', token=ctx.api.token('learner'))
    relaunch(d)
    d.wait(label='Your session ended. Sign in again.', timeout=40)
    d.expect('sign in form', **LOGIN_FIELD)
    _no_home(ctx)
    ctx.shot('session-ended')


# ── accounts other than a learner ──────────────────────────────────────────────────────────────


@scenario(
    'AUTH-017', M, 'Super Admin is told the app is not for them', slug=SLUG, priority='P1',
    purpose='The platform Super Admin role is refused by the app (it lives on the web).',
    preconditions=['platform super admin provisioned in the scratch database'],
    actions=['Sign in as the super admin'],
    expected=['"Platform administration is on the web" screen', 'No learner or staff shell'],
)
def auth_017(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    submit_login(d, SEED['superadmin'], seed_password())
    d.wait(label='Platform administration is on the web', timeout=30)
    _no_home(ctx)
    d.expect_absent('no staff dashboard', regex=r'^Dashboard\nTab')
    ctx.shot('unsupported-role')


# ── registration ───────────────────────────────────────────────────────────────────────────────


@scenario(
    'AUTH-018', M, 'Registration form checks its fields', slug=SLUG, priority='P1',
    purpose='The learner registration form refuses empty and too-short input before sending.',
    actions=['Welcome → Create account', 'Tap Create account with every field empty', 'Type a 1-letter name, a bad email and a 5-character password', 'Tap Create account'],
    expected=['Errors for name, email and password ("Use at least 8 characters.")', 'Still on "Create your account"'],
)
def auth_018(ctx: Ctx) -> None:
    d = ctx.d
    fresh_app(d)
    d.tap(label='Create account', cls='Button')
    d.wait(label=REGISTER_TITLE)
    d.tap(d.scroll_to(label='Create account', cls='Button'))
    d.wait(label='Enter your full name.')
    d.expect('email error', label='Enter a valid email address.')
    d.expect('LMS address error', label='Enter the LMS address from your join link.')
    ctx.shot('register-empty')
    d.fill('Full name', 'Q')
    d.fill('Email', 'nobody@nowhere')
    d.fill('Password', 'short')
    d.hide_keyboard()
    d.tap(d.scroll_to(label='Create account', cls='Button'))
    d.wait(label='Enter your full name.')
    d.expect('bad email', label='Enter a valid email address.')
    d.expect('short password', regex=r'^Use at least 8 characters\.$')
    d.expect('still registering', label=REGISTER_TITLE)
    _no_home(ctx)
    ctx.shot('register-invalid')


@scenario(
    'AUTH-019', M, 'Register a new learner and land on their own home', slug=SLUG, priority='P0', repeat_safe=False,
    purpose='Public registration creates a learner, signs them in and greets that exact new account.',
    preconditions=['academy accepts self-registration (seed)'],
    data=['ai_e2e_<stamp>_<tag>@example.test, name "Qa<tag> Learner", password E2E_SEED_PASSWORD'],
    actions=['Welcome → Create account', 'Enter the new identity', 'Tap Create account', 'Open Profile'],
    expected=['The learner shell opens on the empty home ("Your learning starts here" → Explore courses): a new learner has no enrolments', 'Profile shows the new name, email and Learner', 'GET /auth/me for those credentials: same email, role student'],
    cleanup='The account stays in the scratch database for AUTH-020…AUTH-024; nothing shared is changed',
)
def auth_019(ctx: Ctx) -> None:
    d = ctx.d
    state = load_state()
    state.pop('auth_new_account', None)
    save_state(state)
    ident = _identity(ctx)
    ctx.note(f"created {ident['email']}")
    fresh_app(d)
    d.tap(label='Create account', cls='Button')
    d.wait(label=REGISTER_TITLE)
    d.fill('LMS address', SEEDED_LMS)
    d.fill('Full name', ident['name'])
    d.fill('Email', ident['email'])
    d.fill('Password', ident['password'])
    d.hide_keyboard()
    d.tap(d.scroll_to(label='Create account', cls='Button'))
    wait_new_learner_home(d)
    ctx.shot('new-home')
    _assert_profile(ctx, ident)
    me = ctx.api.ok('GET', '/auth/me', token=ctx.api.login(ident['email'], ident['password']))['user']
    ctx.check(me['email'] == ident['email'] and me['role'] == 'student', f'/auth/me disagrees: {me}')
    ctx.shot('new-profile')


@scenario(
    'AUTH-020', M, 'The new account signs out and back in', slug=SLUG, priority='P0',
    purpose='The account created in AUTH-019 is a real, reusable account.',
    preconditions=['AUTH-019 created the account'],
    actions=['Sign in as the new account', 'Sign out', 'Sign in again'],
    expected=['Each time, the learner shell opens and Profile names the new account'],
)
def auth_020(ctx: Ctx) -> None:
    d = ctx.d
    ident = _identity(ctx)
    fresh_app(d)
    submit_login(d, ident['email'], ident['password'])
    _new_home(ctx, ident)
    sign_out(d, ident['email'])
    submit_login(d, ident['email'], ident['password'])
    _new_home(ctx, ident)
    ctx.shot('new-account-again')


@scenario(
    'AUTH-021', M, 'Registering the same email twice is refused', slug=SLUG, priority='P1',
    purpose="The server's 409 is shown on the form and no second account or session appears.",
    preconditions=['AUTH-019 created the account'],
    actions=['Welcome → Create account', 'Enter a different name with the AUTH-019 email', 'Tap Create account'],
    expected=["Banner \"We couldn't create your account.\" with \"An account with this email already exists.\"", 'Still on Create your account'],
)
def auth_021(ctx: Ctx) -> None:
    d = ctx.d
    ident = _identity(ctx)
    fresh_app(d)
    d.tap(label='Create account', cls='Button')
    d.wait(label=REGISTER_TITLE)
    d.fill('LMS address', SEEDED_LMS)
    d.fill('Full name', 'Duplicate Person')
    d.fill('Email', ident['email'])
    d.fill('Password', ident['password'])
    d.hide_keyboard()
    d.tap(d.scroll_to(label='Create account', cls='Button'))
    banner = d.wait(contains="We couldn't create your account.", timeout=20)
    ctx.check('An account with this email already exists.' in banner.label, f'duplicate refusal text: {banner.label!r}')
    d.expect('still registering', label=REGISTER_TITLE)
    _no_home(ctx)
    ctx.shot('duplicate')


# ── password reset, through the dev mail outbox ────────────────────────────────────────────────


@scenario(
    'AUTH-022', M, 'Forgot password: validation, then the neutral confirmation', slug=SLUG, priority='P1',
    purpose='The reset request checks the address, then confirms without saying whether it exists — and a link really is queued for a real account.',
    preconditions=['AUTH-019 created the account'],
    actions=['Sign in → Forgot password?', 'Tap Send with an invalid address', 'Enter the new account\'s email and send'],
    expected=['Email validation error', '"Check your email" confirmation', 'The dev outbox holds a reset link addressed to that account'],
)
def auth_022(ctx: Ctx) -> None:
    d = ctx.d
    ident = _identity(ctx)
    fresh_app(d)
    open_login(d)
    d.tap(label='Forgot password?', cls='Button')
    d.wait(label='Reset your password')
    d.fill('Email', 'broken@')
    d.hide_keyboard()
    d.tap(label='Send link', cls='Button')
    d.wait(label='Enter a valid email address.')
    d.fill('Email', ident['email'])
    d.hide_keyboard()
    d.tap(label='Send link', cls='Button')
    d.wait(label='Check your email', timeout=20)
    d.expect('neutral wording', contains='If an account exists for that email')
    link = outbox_link(ident['email'], '/reset-password/')
    ctx.check(link.rsplit('/', 1)[-1] != '', 'reset link has no token')
    ctx.shot('check-email')


@scenario(
    'AUTH-023', M, 'Reset link opened in the app sets a new password', slug=SLUG, priority='P1', repeat_safe=False,
    purpose="Opening the e-mailed link (as the academy's App Link) shows the reset form; the new password works and the old one stops working; the used link is dead.",
    preconditions=['AUTH-022 queued a link'],
    actions=[
        'Open https://zuviloai.com/reset-password/<token> from the outbox in the app',
        'Enter mismatched passwords → error',
        'Enter the new password twice → Password updated',
        'Sign in with the old password → refused',
        'Sign in with the new password → home',
        'Open the same link again',
    ],
    expected=['"Set a new password" form', '"Both passwords must match."', '"Password updated"', 'Old password refused', 'The new account signs in with the new password (Profile names it)', '"This link is no longer valid"'],
    cleanup='The password is set back to E2E_SEED_PASSWORD through a second reset link so later scenarios still sign in',
)
def auth_023(ctx: Ctx) -> None:
    d = ctx.d
    ident = _identity(ctx)
    new_pw = ident['password'] + '-r1'
    token = outbox_link(ident['email'], '/reset-password/').rsplit('/', 1)[-1]
    link = f'https://zuviloai.com/reset-password/{token}'
    fresh_app(d)
    d.open_link(link)
    d.wait(label='Set a new password', timeout=30)
    d.fill('New password', new_pw)
    d.fill('Confirm password', new_pw + 'x')
    d.hide_keyboard()
    d.tap(d.scroll_to(label='Save password', cls='Button'))
    d.wait(label='Both passwords must match.')
    ctx.shot('mismatch')
    d.fill('Confirm password', new_pw, previous_length=len(new_pw) + 2)
    d.hide_keyboard()
    d.tap(d.scroll_to(label='Save password', cls='Button'))
    d.wait(label='Password updated', timeout=20)
    ctx.shot('updated')
    d.tap(label='Sign in', cls='Button')
    submit_login(d, ident['email'], ident['password'])
    d.wait(contains=LOGIN_FAILED, timeout=20)
    submit_login(d, ident['email'], new_pw)
    _new_home(ctx, ident)
    ctx.shot('new-password-works')
    relaunch(d)
    d.open_link(link)
    d.wait(label='This link is no longer valid', timeout=30)
    ctx.shot('link-used')
    # Put the original password back, through the same public reset flow.
    ctx.api.ok('POST', '/auth/forgot-password', {'email': ident['email']})
    fresh = outbox_link(ident['email'], '/reset-password/').rsplit('/', 1)[-1]
    ctx.check(fresh != token, 'a second reset link was not issued')
    ctx.api.ok('POST', '/auth/reset-password', {'token': fresh, 'password': ident['password']})


@scenario(
    'AUTH-024', M, 'A suspended learner cannot sign in', slug=SLUG, priority='P1',
    purpose="An academy suspension is enforced at sign-in and the app shows the server's reason.",
    preconditions=['AUTH-019 created the account', 'admin holds learners.suspend'],
    actions=['Admin suspends the new learner (API setup)', 'Sign in as that learner in the app', 'Admin restores the learner (cleanup)', 'Sign in again'],
    expected=[f'Banner with "{SUSPENDED}"', 'No home while suspended', 'After restore the same learner signs in'],
    cleanup='Suspension lifted even if the scenario fails',
)
def auth_024(ctx: Ctx) -> None:
    d = ctx.d
    ident = _identity(ctx)
    admin = ctx.api.token('admin')
    rows = ctx.api.ok('GET', f"/students?search={ident['email']}", token=admin)['rows']
    match = [r for r in rows if r['student']['email'] == ident['email']]
    ctx.check(len(match) == 1, f"expected exactly the new learner, found {len(match)}")
    sid = match[0]['student']['id']
    ctx.api.ok('POST', f'/students/{sid}/suspend', {'suspended': True, 'reason': 'Live E2E check'}, token=admin)
    try:
        fresh_app(d)
        submit_login(d, ident['email'], ident['password'])
        banner = d.wait(contains=LOGIN_FAILED, timeout=20)
        ctx.check(SUSPENDED in banner.label, f'suspension reason not shown: {banner.label!r}')
        _no_home(ctx)
        ctx.shot('suspended')
    finally:
        ctx.api.ok('POST', f'/students/{sid}/suspend', {'suspended': False}, token=admin)
    d.tap(**SIGN_IN_BUTTON)
    _new_home(ctx, ident)
    ctx.shot('restored')
