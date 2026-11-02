"""User journeys shared by many scenarios. Each one is a sequence of real taps and keystrokes, and
each ends by waiting for the screen the journey promises — never by assuming it."""

from __future__ import annotations

import re
import time

from driver import Device, E2EFailure, Node

WELCOME = {'label': 'Learn from your school or coaching’s own LMS.'}
LOGIN_FIELD = {'field': 'Email'}
SIGN_IN_BUTTON = {'label': 'Sign in', 'cls': 'Button'}
LOGIN_FAILED = "We couldn't sign you in."
LEARNER_TABS = ('Home', 'My Learning', 'Explore', 'Live', 'More')


def greeting(first_name: str) -> dict:
    return {'regex': rf'^Good (morning|afternoon|evening), {re.escape(first_name)}$'}


def _remember(email: str | None) -> None:
    from harness import load_state, save_state

    state = load_state()
    state['signed_in'] = email
    save_state(state)


def _remembered() -> str | None:
    from harness import load_state

    return load_state().get('signed_in')


def fresh_app(d: Device) -> None:
    """A first-run app: data and secure storage cleared, launched, Welcome on screen."""
    _remember(None)
    d.close_system_dialogs()
    d.stop()
    d.reset()
    d.launch()
    d.wait(timeout=40, **WELCOME)


def relaunch(d: Device) -> None:
    """Kills the process and starts it again, the way a person reopening the app from recents
    after Android reclaimed it would."""
    d.stop()
    d.launch()


def open_login(d: Device) -> None:
    if d.sees(**LOGIN_FIELD):
        return
    d.tap(**SIGN_IN_BUTTON, timeout=30)
    d.wait(**LOGIN_FIELD)


def submit_login(d: Device, email: str, password: str) -> None:
    open_login(d)
    d.fill('Email', email)
    d.fill('Password', password)
    d.hide_keyboard()
    d.tap(**SIGN_IN_BUTTON)


def wait_learner_home(d: Device, first_name: str, timeout: float = 30) -> Node:
    node = d.wait(timeout=timeout, **greeting(first_name))
    for tab in LEARNER_TABS:
        d.expect(f'learner tab {tab!r}', regex=rf'^{re.escape(tab)}\nTab \d of 5')
    return node


def wait_new_learner_home(d: Device, timeout: float = 40) -> Node:
    """A learner with no enrolments: the spec's empty home ("Your learning starts here" → Explore,
    modules.md FLUTTER-009 States) inside the learner shell. It names nobody, so a scenario proves
    *whose* home it is on the Profile screen."""
    node = d.wait(timeout=timeout, label='Your learning starts here')
    d.expect('the empty home offers Explore', label='Explore courses', cls='Button')
    for tab in LEARNER_TABS:
        d.expect(f'learner tab {tab!r}', regex=rf'^{re.escape(tab)}\nTab \d of 5')
    return node


STAFF_TABS = {
    'instructor': ('Dashboard', 'Review', 'Courses', 'Live', 'More'),
    'admin': ('Dashboard', 'People', 'Courses', 'Review', 'More'),
}


def tab(name: str) -> dict:
    return {'regex': rf'^{re.escape(name)}\nTab \d of \d'}


def wait_staff_dashboard(d: Device, role: str, timeout: float = 40) -> Node:
    node = d.wait(timeout=timeout, label='Needs you')
    for name in STAFF_TABS[role]:
        d.expect(f'{role} tab {name!r}', **tab(name))
    return node


def sign_in_as(d: Device, role: str, email: str, password: str, first_name: str = '') -> None:
    """The role's landing screen, signed in as [email].

    When the app already holds a session for exactly that account (the last sign-in this harness
    made, on this install), a relaunch restores it — proven on screen: a learner's home greets
    that learner by name; a staff shell shows that role's own tabs. Anything else — another
    account, Welcome, an expired session — falls back to a cleared app and a real sign-in.
    """
    if _remembered() == email:
        d.close_system_dialogs()
        # Always a relaunch, never "go home inside the open app": each tab keeps its own stack (§5.5),
        # so a tab a previous scenario left on a detail page would reopen there, not on the list a
        # scenario expects. A relaunch restores the session with every tab at its root.
        d.relaunch()
        try:
            if role == 'learner':
                wait_learner_home(d, first_name, timeout=30)
            else:
                wait_staff_dashboard(d, role, timeout=30)
            return
        except E2EFailure:
            pass
    fresh_app(d)
    submit_login(d, email, password)
    if role == 'learner':
        wait_learner_home(d, first_name)
    else:
        wait_staff_dashboard(d, role)
    _remember(email)


def open_curriculum_lesson(d: Device, chapter: str, lesson: str) -> None:
    """On a course page: expand [chapter] (its row reads "<chapter>, n of m lessons done") unless
    its lessons already show, then tap the [lesson] row ("1.2, <lesson>, Reading · 12 min, …")."""
    row = rf'(^|\d+\.\d+, ){re.escape(lesson)}(,|\n|$)'
    if not d.dump().find(regex=row):
        d.tap(d.scroll_to(regex=rf'^{re.escape(chapter)}(,|\n|$)', max_swipes=12))
        time.sleep(1)
    d.tap(d.scroll_to(regex=row, max_swipes=8))


def open_more_item(d: Device, item: str) -> None:
    """More tab → the sheet's row [item]. Sheet rows are plain rows, so a tab or the bell with the
    same name (Live, Notifications) is never the one tapped."""
    d.tap(regex=r'^More\nTab \d of \d')
    d.wait(label='Dismiss', timeout=10)  # the sheet's drag handle: the sheet is open
    try:
        node = d.wait(label=item, cls='View', timeout=4)
    except E2EFailure:
        node = d.scroll_to(label=item, cls='View', max_swipes=4)
    d.tap(node)


def open_profile(d: Device, email: str) -> Node:
    open_more_item(d, 'Profile')
    return d.wait(contains=email, timeout=20)


def sign_out(d: Device, email: str) -> None:
    """Profile → Sign out → the confirmation dialog → Sign out."""
    open_profile(d, email)
    d.tap(d.scroll_to(label='Sign out', cls='Button'))
    d.wait(label='Sign out?', timeout=10)
    buttons = d.dump().find_all(label='Sign out', cls='Button')
    # The dialog's confirm button is the one inside the dialog, below its title.
    title = d.dump().find(label='Sign out?')
    confirm = next((b for b in buttons if title and b.bounds[1] > title.bounds[1]), None)
    if confirm is None:
        raise E2EFailure('the sign-out dialog has no Sign out button')
    d.tap(confirm)
    d.wait(timeout=20, **WELCOME)
    _remember(None)


def type_slowly_settle() -> None:
    time.sleep(0.6)
