"""FLUTTER-031 Multi-Admin SaaS — LIVE UI E2E.

The platform is Super Admin → many Admins → each Admin's own LMS. These scenarios create two Admins
(A and B) on the contract server, each with an LMS of its own, and prove on the device that:
a learner joins exactly the LMS a join link (or a typed LMS address) names; each learner, instructor and
admin sees only their own LMS's data; a person signing in after another on the same device sees nothing
of the last one; a suspended LMS and a lapsed plan are explained; and the API refuses every cross-LMS
attempt whatever the app is asked to do.

Discovered from: lib/features/auth (register, session controller), lib/core/network (account-closed
handling), lib/app/session_scope.dart, apps/api/src/routes/auth.ts (`workspace`), publicSite.ts
(join links), superadminAcademies.ts.
"""

from __future__ import annotations

from harness import Ctx, load_state, new_identity, save_state, scenario, seed_password
from scenarios.flows import (
    LOGIN_FAILED,
    fresh_app,
    open_profile,
    relaunch,
    sign_out,
    submit_login,
    wait_new_learner_home,
    wait_staff_dashboard,
)

M = 'FLUTTER-031'
SLUG = 'multi-admin'
REGISTER_TITLE = 'Create your account'
LINK_HOST = 'https://zuviloai.com'


# ── the two Admins, created once per scratch database ─────────────────────────────────────────


def _platform(ctx: Ctx) -> str:
    return ctx.api.token('superadmin')


def _world(ctx: Ctx) -> dict:
    """Admin A and Admin B, each with an LMS of their own and a Growth trial — created through the
    Super Admin's API, as the platform creates a client. Kept in the state file for the later scenarios."""
    state = load_state()
    world = state.get('multiadmin')
    if world:
        return world
    ctx.api.assert_safe()
    su = _platform(ctx)
    growth = next(p for p in ctx.api.ok('GET', '/public/plans')['plans'] if p['code'] == 'GROWTH')
    world = {}
    for key in ('a', 'b'):
        ident = new_identity(f'ai_e2e_admin{key}')
        slug = f"e2e-{key}-{ident['first'].lower()}"
        lms = f"E2E LMS {key.upper()} {ident['first']}"
        tenant = ctx.api.ok(
            'POST',
            '/superadmin/tenants',
            {'name': lms, 'slug': slug, 'admin': {'name': f'Admin {key.upper()}', 'email': ident['email'], 'password': seed_password()}},
            token=su,
        )
        admin = ctx.api.login(ident['email'], seed_password())
        ctx.api.ok('POST', '/tenant/billing/trial', {'planId': growth['id'], 'cycle': 'monthly'}, token=admin)
        world[key] = {'tenant': tenant['id'], 'slug': slug, 'lms': lms, 'admin_email': ident['email']}
    state['multiadmin'] = world
    save_state(state)
    ctx.note(f"Admin A: {world['a']['slug']} · Admin B: {world['b']['slug']}")
    return world


def _learner(ctx: Ctx, key: str) -> dict:
    state = load_state()
    ident = state.get(f'multiadmin_learner_{key}')
    if not ident:
        ident = {k: v for k, v in new_identity(f'ai_e2e_learner{key}').items() if k != 'password'}
        state[f'multiadmin_learner_{key}'] = ident
        save_state(state)
    return {**ident, 'password': seed_password()}


def _tenant_of(ctx: Ctx, email: str) -> str | None:
    """Which LMS the server put the account in — read by the platform, never by the app."""
    rows = ctx.api.ok('GET', f'/superadmin/users?search={email}', token=_platform(ctx))['rows']
    row = next((r for r in rows if r['email'] == email), None)
    return (row or {}).get('tenant', {}).get('id')


def _register(ctx: Ctx, ident: dict, workspace: str | None) -> None:
    """Create account, with the LMS address typed (or already filled in by a join link when None)."""
    d = ctx.d
    d.wait(label=REGISTER_TITLE, timeout=30)
    if workspace is not None:
        d.fill('LMS address', workspace)
    d.fill('Full name', ident['name'])
    d.fill('Email', ident['email'])
    d.fill('Password', ident['password'])
    d.hide_keyboard()
    d.tap(d.scroll_to(label='Create account', cls='Button'))


def _assert_profile(ctx: Ctx, ident: dict) -> None:
    card = open_profile(ctx.d, ident['email'])
    ctx.check(ident['name'] in card.label, f"profile names {card.label!r}, not {ident['name']!r}")


# ── joining the right LMS ──────────────────────────────────────────────────────────────────────


@scenario(
    'MA-001', M, 'A join link opens Create account for that Admin’s LMS, and the learner joins it', tier='smoke', slug=SLUG, priority='P0', repeat_safe=False,
    purpose="A learner who taps Admin A's join link registers into Admin A's LMS — not the host's default one.",
    preconditions=['contract server with two Admins (created by the scenario through the Super Admin API)'],
    actions=["Open https://zuviloai.com/join/<A's address>", 'Check the LMS address is filled in', 'Enter a new learner and Create account', 'Open Profile'],
    expected=["LMS address shows A's address", 'The new learner home opens and Profile names the new learner', "The platform lists the learner in Admin A's LMS"],
)
def ma_001(ctx: Ctx) -> None:
    d = ctx.d
    world = _world(ctx)
    ident = _learner(ctx, 'a')
    fresh_app(d)
    d.open_link(f"{LINK_HOST}/join/{world['a']['slug']}")
    d.wait(label=REGISTER_TITLE, timeout=30)
    d.expect("the join link's LMS address is filled in", contains=world['a']['slug'])
    ctx.shot('join-link-prefilled')
    _register(ctx, ident, workspace=None)
    wait_new_learner_home(d)
    _assert_profile(ctx, ident)
    ctx.check(_tenant_of(ctx, ident['email']) == world['a']['tenant'], "the learner is not in Admin A's LMS")
    ctx.shot('learner-a-home')


@scenario(
    'MA-002', M, 'A typed (or pasted) LMS address joins that Admin’s LMS', tier='smoke', slug=SLUG, priority='P0', repeat_safe=False,
    purpose="The LMS address field accepts a pasted join link and the learner joins Admin B's LMS.",
    actions=['Welcome → Create account', "Paste B's whole join link into LMS address", 'Enter a new learner and Create account'],
    expected=['The new learner home opens', "The platform lists the learner in Admin B's LMS, not A's"],
)
def ma_002(ctx: Ctx) -> None:
    d = ctx.d
    world = _world(ctx)
    ident = _learner(ctx, 'b')
    fresh_app(d)
    d.tap(label='Create account', cls='Button')
    _register(ctx, ident, workspace=f"{LINK_HOST}/join/{world['b']['slug']}")
    wait_new_learner_home(d)
    _assert_profile(ctx, ident)
    ctx.check(_tenant_of(ctx, ident['email']) == world['b']['tenant'], "the learner is not in Admin B's LMS")
    ctx.shot('learner-b-home')


@scenario(
    'MA-003', M, 'An LMS address nobody has is refused, and an empty one is caught on the device', tier='smoke', slug=SLUG, priority='P1',
    purpose='A wrong address creates nothing and says why; a missing one is never sent.',
    actions=['Create account with no LMS address', 'Then with "no-such-lms-anywhere"'],
    expected=['"Enter the LMS address from your join link." under the field', 'Banner "No LMS has this address"', 'Still on Create your account; no home'],
)
def ma_003(ctx: Ctx) -> None:
    d = ctx.d
    ident = {k: v for k, v in new_identity('ai_e2e_nowhere').items()}
    fresh_app(d)
    d.tap(label='Create account', cls='Button')
    _register(ctx, ident, workspace='')
    d.wait(label='Enter the LMS address from your join link.')
    ctx.shot('no-address')
    _register(ctx, ident, workspace='no-such-lms-anywhere')
    d.wait(contains='No LMS has this address', timeout=20)
    d.expect('still registering', label=REGISTER_TITLE)
    ctx.check(_tenant_of(ctx, ident['email']) is None, 'an account was created for an unknown LMS')
    ctx.shot('unknown-address')


# ── each person sees their own LMS, and nothing of the last person ─────────────────────────────


@scenario(
    'MA-004', M, 'Each learner sees only their own Admin’s messages, on the same device one after the other', tier='smoke', slug=SLUG, priority='P0',
    purpose='Admin A messages its learners; learner A sees it; learner B, signing in next on the same device, sees nothing of it.',
    preconditions=['MA-001 and MA-002 created learner A and learner B'],
    actions=["Admin A sends a message to learner A (API)", 'Learner A signs in → bell → the message is listed', 'Sign out', 'Learner B signs in → bell'],
    expected=["Learner A's notifications list Admin A's message", "Learner B's notifications do not show it — neither from the server nor left over on the device"],
)
def ma_004(ctx: Ctx) -> None:
    d = ctx.d
    _world(ctx)
    a, b = _learner(ctx, 'a'), _learner(ctx, 'b')
    admin_a = ctx.api.login(_world(ctx)['a']['admin_email'], seed_password())
    rows = ctx.api.ok('GET', f"/students?search={a['email']}", token=admin_a)['rows']
    ctx.check(len(rows) == 1, f"Admin A does not see learner A: {rows}")
    subject = f"From Admin A to {a['first']}"
    ctx.api.ok('POST', '/students/message', {'ids': [rows[0]['student']['id']], 'subject': subject, 'body': 'Welcome to our LMS — your first class is on Monday.', 'channels': ['app']}, token=admin_a)

    fresh_app(d)
    submit_login(d, a['email'], a['password'])
    wait_new_learner_home(d)
    d.tap(d.wait(regex=r'^(\d+ unread notifications?|Notifications)$', cls='Button'))
    d.wait(contains=subject, timeout=20)
    ctx.shot('learner-a-notifications')
    d.back()
    sign_out(d, a['email'])

    submit_login(d, b['email'], b['password'])
    wait_new_learner_home(d)
    d.tap(d.wait(regex=r'^(\d+ unread notifications?|Notifications)$', cls='Button'))
    d.settle(4)
    d.expect_absent("learner B must never see Admin A's message", contains=subject)
    server = ctx.api.ok('GET', '/notifications', token=ctx.api.login(b['email'], b['password']))
    ctx.check(subject not in str(server), "the server served learner B Admin A's message")
    ctx.shot('learner-b-notifications')


@scenario(
    'MA-005', M, 'Session restoration keeps the same learner; sign out and back in works', tier='smoke', slug=SLUG, priority='P0',
    purpose='A relaunch restores exactly the account that was signed in, and a sign-out ends it.',
    actions=['Learner A signs in', 'Kill and relaunch the app', 'Profile', 'Sign out', 'Sign in again'],
    expected=['After the relaunch, Profile still names learner A with no sign-in', 'After sign-out, Welcome', 'Signing in again lands on learner A'],
)
def ma_005(ctx: Ctx) -> None:
    d = ctx.d
    a = _learner(ctx, 'a')
    fresh_app(d)
    submit_login(d, a['email'], a['password'])
    wait_new_learner_home(d)
    relaunch(d)
    wait_new_learner_home(d)
    _assert_profile(ctx, a)
    ctx.shot('restored')
    sign_out(d, a['email'])
    submit_login(d, a['email'], a['password'])
    wait_new_learner_home(d)
    _assert_profile(ctx, a)


@scenario(
    'MA-006', M, 'Wrong credentials are refused without saying which part was wrong', tier='smoke', slug=SLUG, priority='P0',
    purpose='A wrong password for a real learner signs nobody in.',
    actions=['Sign in as learner A with a wrong password'],
    expected=['The sign-in failure banner', 'No home'],
)
def ma_006(ctx: Ctx) -> None:
    d = ctx.d
    a = _learner(ctx, 'a')
    fresh_app(d)
    submit_login(d, a['email'], 'definitely-not-it-123')
    d.wait(contains=LOGIN_FAILED, timeout=20)
    d.expect_absent('no home for a wrong password', label='Your learning starts here')
    ctx.shot('wrong-password')


# ── staff of an Admin ──────────────────────────────────────────────────────────────────────────


@scenario(
    'MA-007', M, 'An instructor Admin A invited signs in to A’s staff workspace', tier='smoke', slug=SLUG, priority='P0', repeat_safe=False,
    purpose="Admin A adds an instructor; the instructor sets a password from the invitation and signs in on the device.",
    actions=['Admin A creates an instructor (API)', 'The invitation link sets a password (API)', 'Sign in as the instructor'],
    expected=['The instructor staff shell (Dashboard, Review, Courses, Live, More)', "The platform lists the instructor in Admin A's LMS"],
)
def ma_007(ctx: Ctx) -> None:
    d = ctx.d
    world = _world(ctx)
    state = load_state()
    ident = state.get('multiadmin_instructor')
    if not ident:
        ident = {k: v for k, v in new_identity('ai_e2e_instr').items() if k != 'password'}
        admin_a = ctx.api.login(world['a']['admin_email'], seed_password())
        ctx.api.ok(
            'POST',
            '/instructors',
            {
                'name': ident['name'], 'title': 'Senior Mathematics Teacher', 'email': ident['email'],
                'bio': 'Teaches school mathematics with twenty years of classroom practice behind every lesson.',
                'expertise': ['Mathematics'], 'status': 'invited', 'city': 'Pune', 'languages': ['English'], 'courseIds': [],
            },
            token=admin_a,
        )
        from harness import outbox_link

        token = outbox_link(ident['email'], '/reset-password/').rsplit('/', 1)[-1]
        ctx.api.ok('POST', '/auth/reset-password', {'token': token, 'password': seed_password()})
        state['multiadmin_instructor'] = ident
        save_state(state)
    fresh_app(d)
    submit_login(d, ident['email'], seed_password())
    wait_staff_dashboard(d, 'instructor')
    ctx.check(_tenant_of(ctx, ident['email']) == world['a']['tenant'], "the instructor is not in Admin A's LMS")
    ctx.shot('instructor-a-dashboard')


@scenario(
    'MA-008', M, 'Admin A signs in on the device and sees only A’s learners', tier='smoke', slug=SLUG, priority='P0',
    purpose="The Admin's People list holds Admin A's learners and none of Admin B's.",
    actions=['Sign in as Admin A', 'People tab'],
    expected=['Admin dashboard', "Learner A listed", "Learner B absent"],
)
def ma_008(ctx: Ctx) -> None:
    d = ctx.d
    world = _world(ctx)
    a, b = _learner(ctx, 'a'), _learner(ctx, 'b')
    fresh_app(d)
    submit_login(d, world['a']['admin_email'], seed_password())
    wait_staff_dashboard(d, 'admin')
    d.tap(regex=r'^People\nTab \d of \d')
    d.wait(contains=a['name'], timeout=20)
    d.expect_absent("Admin B's learner must not be listed for Admin A", contains=b['name'])
    ctx.shot('admin-a-people')


# ── the server refuses whatever the app is asked ───────────────────────────────────────────────


@scenario(
    'MA-009', M, 'Cross-LMS requests are refused by the API whatever the client sends', tier='smoke', slug=SLUG, priority='P0',
    purpose="Tokens of Admin A's learner and admin cannot reach Admin B's records; a tenant id in a body is ignored.",
    actions=["A's admin: GET/suspend B's learner; A's learner: GET B's notifications by id; register with a forged tenantId"],
    expected=['404 for every record of B', 'The forged registration lands where its LMS address says, never where tenantId says'],
)
def ma_009(ctx: Ctx) -> None:
    world = _world(ctx)
    a, b = _learner(ctx, 'a'), _learner(ctx, 'b')
    admin_a = ctx.api.login(world['a']['admin_email'], seed_password())
    admin_b = ctx.api.login(world['b']['admin_email'], seed_password())
    learner_b_id = ctx.api.ok('GET', f"/students?search={b['email']}", token=admin_b)['rows'][0]['student']['id']
    for method, path, body in (('GET', f'/students/{learner_b_id}', None), ('POST', f'/students/{learner_b_id}/suspend', {'suspended': True})):
        status, _ = ctx.api.call(method, path, body, token=admin_a)
        ctx.check(status == 404, f"Admin A {method} {path} → {status}, expected 404")
    status, page = ctx.api.call('GET', f"/students?search={b['email']}", token=admin_a)
    ctx.check(status == 200 and not page['rows'], f"Admin A's roster search found learner B: {page}")
    notes_b = ctx.api.ok('GET', '/notifications', token=ctx.api.login(b['email'], b['password']))
    rows = notes_b.get('rows') or notes_b.get('items') or []
    if rows:
        status, _ = ctx.api.call('GET', f"/notifications/{rows[0]['id']}", token=ctx.api.login(a['email'], a['password']))
        ctx.check(status == 404, f"learner A read learner B's notification → {status}")
    forged = new_identity('ai_e2e_forged')
    ctx.api.ok('POST', '/auth/register', {'name': forged['name'], 'email': forged['email'], 'password': seed_password(), 'workspace': world['a']['slug'], 'tenantId': world['b']['tenant']})
    ctx.check(_tenant_of(ctx, forged['email']) == world['a']['tenant'], 'a forged tenantId moved the account')


# ── a lapsed plan and a suspended LMS ──────────────────────────────────────────────────────────


@scenario(
    'MA-010', M, 'A suspended LMS signs its learner out with the reason, and refuses sign-in', tier='smoke', slug=SLUG, priority='P0',
    purpose='When the platform suspends Admin B, learner B — already signed in on the device — is told why, and cannot sign in until it is restored.',
    actions=['Learner B signs in', 'The Super Admin suspends Admin B (API)', 'Relaunch the app', 'Try to sign in again', 'The Super Admin reactivates B (API)', 'Sign in'],
    expected=['After the relaunch: the sign-in screen with "This account is suspended…"', 'Signing in: banner "This account is suspended"', 'After reactivation, learner B signs in'],
    cleanup='Admin B is reactivated',
)
def ma_010(ctx: Ctx) -> None:
    d = ctx.d
    world = _world(ctx)
    b = _learner(ctx, 'b')
    fresh_app(d)
    submit_login(d, b['email'], b['password'])
    wait_new_learner_home(d)
    su = _platform(ctx)
    ctx.api.ok('POST', f"/superadmin/tenants/{world['b']['tenant']}/suspend", {'reason': 'E2E suspension'}, token=su)
    try:
        relaunch(d)
        d.wait(contains='This account is suspended', timeout=40)
        ctx.shot('suspended-signed-out')
        submit_login(d, b['email'], b['password'])
        d.wait(label='This account is suspended', timeout=20)
        d.expect_absent('no home for a suspended LMS', label='Your learning starts here')
        ctx.shot('suspended-sign-in')
    finally:
        ctx.api.ok('POST', f"/superadmin/tenants/{world['b']['tenant']}/reactivate", {}, token=su)
    fresh_app(d)
    submit_login(d, b['email'], b['password'])
    wait_new_learner_home(d)


@scenario(
    'MA-011', M, 'A lapsed plan is shown to Admin A’s instructor as the backend reports it', tier='smoke', slug=SLUG, priority='P1', repeat_safe=False,
    purpose="When Admin A's subscription ends, A's instructor sees the restricted state the server reports — and Admin B is untouched.",
    preconditions=['MA-007 created the instructor'],
    actions=["The Super Admin ends A's subscription now (API)", "A's instructor signs in"],
    expected=['/academy/plan for A: restricted', 'The device marks the plan modules (Review, Courses, Live) "Read-only"', "/academy/plan for B: not restricted"],
)
def ma_011(ctx: Ctx) -> None:
    d = ctx.d
    world = _world(ctx)
    ident = load_state().get('multiadmin_instructor')
    ctx.check(bool(ident), 'MA-007 must run first')
    su = _platform(ctx)
    sub = ctx.api.ok('GET', f"/superadmin/tenants/{world['a']['tenant']}", token=su)['subscription']
    if sub and sub['status'] not in ('canceled', 'expired'):
        ctx.api.ok('POST', f"/superadmin/subscriptions/{sub['id']}/cancel", {'immediately': True, 'reason': 'E2E: check the lapsed state'}, token=su)
    instr = ctx.api.login(ident['email'], seed_password())
    plan_a = ctx.api.ok('GET', '/academy/plan', token=instr)
    ctx.check(plan_a['restricted'] is True, f'A is not restricted: {plan_a}')
    plan_b = ctx.api.ok('GET', '/academy/plan', token=ctx.api.login(world['b']['admin_email'], seed_password()))
    ctx.check(plan_b['restricted'] is False, f'B was affected: {plan_b}')
    fresh_app(d)
    submit_login(d, ident['email'], seed_password())
    # The lapsed plan's modules stay readable and are marked so, as /academy/plan reports (restricted).
    d.wait(label='Needs you', timeout=40)
    for name in ('Review', 'Courses', 'Live'):
        d.expect(f'{name} marked read-only', regex=rf'^Read-only\n{name}\nTab \d of \d')
    ctx.shot('instructor-a-lapsed')
