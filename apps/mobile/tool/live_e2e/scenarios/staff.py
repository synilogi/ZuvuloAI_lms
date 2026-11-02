"""Staff modules FLUTTER-018 … FLUTTER-027 — smoke flows (3–4 per module).

Entities come from the signed-in staff member's own API answers. Consequential actions in the smoke
set are only reversible pairs on data the scenario controls (a calendar reminder it creates and
removes; an enrolment it pauses and resumes; a course it unpublishes and publishes back). Grading,
cancelling a class, invitations, certificate issue/revoke and plan changes are deep QA.
"""

from __future__ import annotations

import time

from harness import SEED, Ctx, scenario, seed_password
from scenarios.flows import open_more_item, sign_in_as, tab


def _instructor(ctx: Ctx) -> str:
    sign_in_as(ctx.d, 'instructor', SEED['instructor'], seed_password())
    return ctx.api.token('instructor')


def _admin(ctx: Ctx) -> str:
    sign_in_as(ctx.d, 'admin', SEED['admin'], seed_password())
    return ctx.api.token('admin')


def _rows(payload) -> list:
    return payload if isinstance(payload, list) else payload.get('rows') or []


# ── FLUTTER-018 Dashboard ──────────────────────────────────────────────────────────────────────


@scenario(
    'DASH-001', 'FLUTTER-018', "The instructor's dashboard shows her figures and next class", slug='staff-dashboard', tier='smoke', priority='P0',
    purpose='GET /dashboard for the instructor is rendered: KPIs, needs-attention, upcoming live.',
    actions=['Sign in as the instructor', 'Read the dashboard top to bottom'],
    expected=['"Needs you", "How things stand" with the KPI tiles', 'Her next live class title from the API under "Coming up live" (if any)'],
)
def dash_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    dash = ctx.api.ok('GET', '/dashboard', token=token)
    d.scroll_to(label='How things stand', max_swipes=6)
    for kpi in ('Courses', 'Learners'):
        d.expect(f'KPI {kpi}', contains=kpi)
    upcoming = dash.get('upcomingLive') or []
    if upcoming:
        d.scroll(direction='up'); d.scroll(direction='up')
        d.scroll_to(contains=upcoming[0]['title'], max_swipes=8)
    ctx.shot('dashboard')


@scenario(
    'DASH-002', 'FLUTTER-018', 'Admin switches between the academy and one instructor', slug='staff-dashboard', tier='smoke', priority='P1',
    purpose='The admin scope control re-reads the dashboard for one instructor and back.',
    actions=['Sign in as the admin', 'One instructor', 'Pick the instructor', 'Whole LMS'],
    expected=['"Active instructors" KPI for the academy', 'Instructor chips appear for one instructor', 'Back to the academy view'],
)
def dash_002(ctx: Ctx) -> None:
    d = ctx.d
    _admin(ctx)
    d.wait(label='Whole LMS', timeout=20)
    d.tap(label='One instructor')
    d.wait(contains='Meenakshi', timeout=20)
    ctx.shot('one-instructor')
    d.tap(label='Whole LMS')
    d.scroll_to(contains='Active instructors', max_swipes=6)
    ctx.shot('academy')


@scenario(
    'DASH-003', 'FLUTTER-018', '"Do next" opens the review queue', slug='staff-dashboard', tier='smoke', priority='P2',
    purpose='A dashboard shortcut lands on the screen it names.',
    actions=['Instructor dashboard → Do next → Review queue'],
    expected=['The Review tab is selected with its queue'],
)
def dash_003(ctx: Ctx) -> None:
    d = ctx.d
    _instructor(ctx)
    d.tap(d.scroll_to(label='Review queue', max_swipes=6))
    time.sleep(2)
    ctx.check(d.dump().find(**tab('Review')).selected, 'Review queue did not open the Review tab')
    ctx.shot('review-from-dashboard')


# ── FLUTTER-019 Courses ────────────────────────────────────────────────────────────────────────


@scenario(
    'SCRS-001', 'FLUTTER-019', 'The instructor sees exactly her courses', slug='staff-courses', tier='smoke', priority='P0',
    purpose="Courses lists GET /courses for the instructor, and a search narrows to one.",
    actions=['Courses tab', 'Search for one of her titles'],
    expected=['Each of her course titles listed', 'Search leaves that course'],
)
def scrs_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    mine = [r['title'] for r in _rows(ctx.api.ok('GET', '/courses', token=token))]
    d.tap(**tab('Courses'))
    for t in mine:
        d.scroll_to(contains=t, max_swipes=6)
    ctx.shot('courses')
    d.fill('Search courses', mine[0].split()[0])
    d.hide_keyboard()
    time.sleep(2)
    d.wait(contains=mine[0], timeout=15)


@scenario(
    'SCRS-002', 'FLUTTER-019', 'Course detail and its curriculum', slug='staff-courses', tier='smoke', priority='P0',
    purpose='A course opens its stats and its read-only curriculum (chapters and lessons from the server).',
    actions=['Courses → her first course', 'Curriculum'],
    expected=['Title, "Published" badge, "How it is going"', '"{n} chapters · {n} lessons" and the first chapter title'],
)
def scrs_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    course = _rows(ctx.api.ok('GET', '/courses', token=token))[0]
    d.tap(**tab('Courses'))
    d.tap(d.scroll_to(contains=course['title'], max_swipes=6))
    d.wait(label='How it is going', timeout=30)
    ctx.shot('course-detail')
    d.tap(d.scroll_to(label='Curriculum', cls='Button', max_swipes=10))
    d.wait(regex=r'^\d+ chapters · \d+ lessons', timeout=20)
    ctx.shot('curriculum')


@scenario(
    'SCRS-003', 'FLUTTER-019', 'Admin unpublishes a course and publishes it back', slug='staff-courses', tier='smoke', priority='P1', repeat_safe=True,
    purpose="The lifecycle actions ask first and the server's status follows (reversible pair). Done as the academy admin: this academy's policy sends an instructor's publish to admin review (403), so only an admin can bring a course back.",
    actions=['Admin: Courses → a published course → Unpublish → confirm', 'Publish → confirm'],
    expected=['"Take it out of the catalogue?" then "Draft"; API status draft', '"Take this course live?" then "The course is live"; API status published'],
    cleanup='Course published again (as admin) even if the scenario fails',
)
def scrs_003(ctx: Ctx) -> None:
    d = ctx.d
    token = _admin(ctx)
    course = next(c for c in _rows(ctx.api.ok('GET', '/courses?status=published', token=token)) if c['status'] == 'published')
    try:
        d.tap(**tab('Courses'))
        d.tap(d.scroll_to(contains=course['title'], max_swipes=8))
        d.tap(d.scroll_to(label='Unpublish', cls='Button', max_swipes=10))
        d.wait(label='Take it out of the catalogue?')
        d.tap(d.dump().find_all(label='Unpublish', cls='Button')[-1])
        d.wait(contains='draft again', timeout=20)
        ctx.check(ctx.api.ok('GET', f"/courses/{course['id']}", token=token)['status'] == 'draft', 'the server does not have it as a draft')
        ctx.shot('draft')
        d.tap(d.scroll_to(label='Publish', cls='Button', max_swipes=10))
        d.wait(label='Take this course live?')
        d.tap(d.dump().find_all(label='Publish', cls='Button')[-1])
        d.wait(contains='The course is live', timeout=20)
        ctx.check(ctx.api.ok('GET', f"/courses/{course['id']}", token=token)['status'] == 'published', 'the server does not have it published again')
        ctx.shot('published')
    finally:
        if ctx.api.ok('GET', f"/courses/{course['id']}", token=token)['status'] != 'published':
            ctx.api.call('POST', f"/courses/{course['id']}/publish", token=token)
            ctx.note('cleanup published the course again through the API (admin)')


# ── FLUTTER-020 Review ─────────────────────────────────────────────────────────────────────────


@scenario(
    'REV-001', 'FLUTTER-020', 'The review queue lists hand-ins waiting for her', slug='staff-review', tier='smoke', priority='P0',
    purpose='Review shows GET /assignments/submissions?filter=to-review for the instructor.',
    actions=['Review tab'],
    expected=['"To review" selected; the first waiting learner and assignment listed (or "Nothing to review")'],
)
def rev_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    rows = _rows(ctx.api.ok('GET', '/assignments/submissions?filter=to-review', token=token))
    d.tap(**tab('Review'))
    if rows:
        d.scroll_to(contains=rows[0]['student']['name'], max_swipes=6)
    else:
        d.wait(label='Nothing to review', timeout=20)
    ctx.shot('queue')


@scenario(
    'REV-002', 'FLUTTER-020', 'Open a hand-in and see what the learner sent', slug='staff-review', tier='smoke', priority='P0',
    purpose='The submission detail shows that learner, the brief, what they handed in and the score panel.',
    preconditions=['at least one hand-in waiting for review'],
    actions=['Review → the first waiting hand-in'],
    expected=['That learner\'s name, "The brief", "What the learner handed in", "The score"'],
)
def rev_002(ctx: Ctx) -> None:
    from harness import Blocked

    d = ctx.d
    token = _instructor(ctx)
    rows = _rows(ctx.api.ok('GET', '/assignments/submissions?filter=to-review', token=token))
    if not rows:
        raise Blocked('no hand-in waiting for this instructor in the scratch data')
    d.tap(**tab('Review'))
    d.tap(d.scroll_to(contains=rows[0]['student']['name'], max_swipes=6))
    d.wait(label='The brief', timeout=30)
    d.expect('the same learner', contains=rows[0]['student']['name'])
    d.scroll_to(label='What the learner handed in', max_swipes=6)
    d.scroll_to(label='The score', max_swipes=10)
    ctx.shot('submission')


@scenario(
    'REV-003', 'FLUTTER-020', 'Status filters switch the list', slug='staff-review', tier='smoke', priority='P2',
    purpose='The Graded filter shows graded work from the server.',
    actions=['Review → Graded'],
    expected=['A graded learner from filter=graded listed (or the empty state)'],
)
def rev_003(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    graded = _rows(ctx.api.ok('GET', '/assignments/submissions?filter=graded', token=token))
    d.tap(**tab('Review'))
    d.tap(d.wait(regex=r'^Graded'))
    time.sleep(2)
    if graded:
        d.scroll_to(contains=graded[0]['student']['name'], max_swipes=6)
    ctx.shot('graded')


# ── FLUTTER-021 Quizzes ────────────────────────────────────────────────────────────────────────


@scenario(
    'SQZ-001', 'FLUTTER-021', 'Quizzes list and one quiz\'s set-up and results', slug='staff-quizzes', tier='smoke', priority='P0',
    purpose='More → Quizzes lists GET /quizzes; a quiz opens its configuration and statistics.',
    actions=['More → Quizzes', 'Open the first quiz'],
    expected=['That quiz title listed', '"How it is set up" with "Pass mark" and the attempts statistics'],
)
def sqz_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    row = _rows(ctx.api.ok('GET', '/quizzes', token=token))[0]
    title = row['quiz']['title'] if 'quiz' in row else row['title']
    open_more_item(d, 'Quizzes')
    d.tap(d.scroll_to(contains=title, max_swipes=6))
    d.wait(label='How it is set up', timeout=30)
    d.expect('pass mark', contains='Pass mark')
    d.scroll_to(regex=r'^(Attempts|No attempts yet)', max_swipes=10)
    ctx.shot('quiz')


@scenario(
    'SQZ-002', 'FLUTTER-021', 'Staff see the answer key', slug='staff-quizzes', tier='smoke', priority='P2',
    purpose='The questions section shows answers to staff only.',
    actions=['More → Quizzes → first quiz → The questions'],
    expected=['"The answers below are shown to staff only." and a "Correct" marker'],
)
def sqz_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    row = _rows(ctx.api.ok('GET', '/quizzes', token=token))[0]
    title = row['quiz']['title'] if 'quiz' in row else row['title']
    open_more_item(d, 'Quizzes')
    d.tap(d.scroll_to(contains=title, max_swipes=6))
    d.scroll_to(label='The answers below are shown to staff only.', max_swipes=12)
    d.scroll_to(contains='Correct', max_swipes=6)
    ctx.shot('answers')


# ── FLUTTER-022 Students ───────────────────────────────────────────────────────────────────────


@scenario(
    'STU-001', 'FLUTTER-022', 'Search the roster and open a learner', slug='staff-students', tier='smoke', priority='P0',
    purpose="People lists the academy's learners; a search finds one and her profile shows her own enrolments.",
    actions=['Admin: People tab', 'Search "Ananya"', 'Open her'],
    expected=['Ananya Rao listed', 'Profile tabs Overview/Courses/Progress/Activity; her enrolled course titles under Courses'],
)
def stu_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _admin(ctx)
    row = next(r for r in _rows(ctx.api.ok('GET', '/students?search=ananya', token=token)) if r['student']['email'] == SEED['learner'])
    d.tap(**tab('People'))
    d.fill('Search by name or email', 'Ananya')
    d.hide_keyboard()
    d.tap(d.wait(contains=row['student']['name'], timeout=20))
    d.wait(label='Overview', timeout=30)
    d.tap(label='Courses', cls='Button') if d.sees(label='Courses', cls='Button') else None
    time.sleep(1.5)
    d.scroll_to(contains=row['courses'][0]['title'], max_swipes=8)
    ctx.shot('learner')


@scenario(
    'STU-002', 'FLUTTER-022', 'Status filter: Active', slug='staff-students', tier='smoke', priority='P2',
    purpose='The Active chip narrows the roster to active learners (counts from the server).',
    actions=['People → Active'],
    expected=['Chip reads "Active, {n}" with n from GET /students counts'],
)
def stu_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _admin(ctx)
    counts = ctx.api.ok('GET', '/students', token=token)['counts']
    d.tap(**tab('People'))
    chip = d.wait(regex=r'^Active, \d+', timeout=20)
    n = counts.get('active')
    ctx.check(n is None or chip.label.startswith(f'Active, {n}'), f'chip {chip.label!r} vs server active={n}')
    d.tap(chip)
    ctx.shot('active')


# ── FLUTTER-023 Staff live ─────────────────────────────────────────────────────────────────────


@scenario(
    'SLIV-001', 'FLUTTER-023', "The instructor's upcoming classes and one class", slug='staff-live', tier='smoke', priority='P0',
    purpose='Live lists GET /live?view=upcoming; a class opens with its sections and actions.',
    actions=['Live tab', 'Open the first upcoming class'],
    expected=['That class title', '"About this class", "Who registered", and Edit / "Cancel the class" actions'],
)
def sliv_001(ctx: Ctx) -> None:
    from harness import Blocked

    d = ctx.d
    token = _instructor(ctx)
    rows = _rows(ctx.api.ok('GET', '/live?view=upcoming', token=token))
    if not rows:
        raise Blocked('no upcoming class for the instructor in the scratch data')
    title = rows[0]['liveClass']['title']
    d.tap(**tab('Live'))
    d.tap(d.scroll_to(contains=title, max_swipes=6))
    d.wait(label='About this class', timeout=30)
    d.scroll_to(label='Who registered', max_swipes=10)
    d.scroll_to(label='Cancel the class', max_swipes=10)
    ctx.shot('class')


@scenario(
    'SLIV-002', 'FLUTTER-023', 'The schedule form will not send an empty class', slug='staff-live', tier='smoke', priority='P1',
    purpose='"Schedule a class" opens the form, and with nothing filled in its submit stays disabled, so nothing can be created.',
    actions=['Live → Schedule a class', 'Look at "Schedule it" with the form empty', 'Back'],
    expected=['The form "Schedule a class" with Course, Title and Meeting link fields', '"Schedule it" disabled', 'No new class on the server'],
)
def sliv_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    before = len(_rows(ctx.api.ok('GET', '/live?view=upcoming', token=token)))
    d.tap(**tab('Live'))
    d.tap_start(d.wait(label='Schedule a class', cls='Button', timeout=20))
    d.wait(field='Title', timeout=20)
    submit = d.scroll_to(label='Schedule it', cls='Button', max_swipes=12)
    ctx.check(not submit.enabled, '"Schedule it" is enabled on an empty form')
    ctx.shot('empty-form')
    ctx.check(len(_rows(ctx.api.ok('GET', '/live?view=upcoming', token=token))) == before, 'a class was created')


# ── FLUTTER-024 Calendar ───────────────────────────────────────────────────────────────────────


@scenario(
    'CAL-001', 'FLUTTER-024', 'Add a private reminder, see it, remove it', slug='staff-calendar', tier='smoke', priority='P0', repeat_safe=True,
    purpose='The instructor creates her own reminder (Only me), finds it on the agenda, opens it and removes it.',
    actions=['More → Calendar → Add to the calendar', 'Title "E2E reminder <stamp>", Only me → Add it', 'Open it → Remove → confirm'],
    expected=['"It is on the calendar" and the reminder on the agenda', 'The server lists it', '"The event is removed" and it is gone from the server'],
    cleanup='The reminder is removed even if the scenario fails',
)
def cal_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _instructor(ctx)
    title = f'E2E reminder {int(time.time()) % 100000}'
    try:
        open_more_item(d, 'Calendar')
        d.tap(d.wait(label='Add to the calendar', timeout=30))
        d.wait(field='Title', timeout=20)
        d.fill('Title', title)
        d.hide_keyboard()
        d.tap(d.scroll_to(label='Add it', cls='Button', max_swipes=12))
        d.wait(contains='It is on the calendar', timeout=20)
        d.scroll_to(contains=title, max_swipes=8)
        ctx.shot('on-agenda')
        d.tap(d.scroll_to(contains=title, max_swipes=8))
        d.tap(d.scroll_to(label='Remove', cls='Button', max_swipes=8))
        d.wait(label='Remove this event?')
        tick = d.dump().find(contains="can't be undone") or d.dump().find(contains='I understand')
        if tick:
            d.tap(tick)
        d.tap(d.dump().find_all(label='Remove', cls='Button')[-1])
        d.wait(contains='The event is removed', timeout=20)
        ctx.shot('removed')
    finally:
        import datetime

        today = datetime.date.today()
        window = f'from={(today - datetime.timedelta(days=7)).isoformat()}&to={(today + datetime.timedelta(days=60)).isoformat()}'
        for e in _rows(ctx.api.ok('GET', f'/calendar?{window}', token=token)):
            if e['event'].get('title') == title:
                ctx.api.call('DELETE', f"/calendar/{e['event']['id']}", token=token)
                ctx.note(f'cleanup removed {title} through the API')


# ── FLUTTER-025 Instructors & certificate register ─────────────────────────────────────────────


@scenario(
    'INS-001', 'FLUTTER-025', 'The instructor directory and one profile', slug='staff-instructors', tier='smoke', priority='P0',
    purpose='More → Instructors lists GET /instructors; an instructor opens her profile with her courses.',
    actions=['Admin: More → Instructors', 'Open Dr. Meenakshi Iyer', 'Courses tab'],
    expected=['Her name listed', 'Profile Overview/Courses/Performance; her course titles under Courses'],
)
def ins_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _admin(ctx)
    inst = next(r for r in _rows(ctx.api.ok('GET', '/instructors', token=token)) if r['instructor'].get('email') == SEED['instructor'] or 'Meenakshi' in r['instructor'].get('name', ''))
    name = inst['instructor']['name']
    open_more_item(d, 'Instructors')
    d.tap(d.scroll_to(contains=name, max_swipes=6))
    d.wait(label='Overview', timeout=30)
    ctx.shot('instructor')


@scenario(
    'INS-002', 'FLUTTER-025', 'The certificate register finds a credential', slug='staff-instructors', tier='smoke', priority='P0',
    purpose="More → Certificates (admin) searches the register for the learner's credential and opens it.",
    actions=['Admin: More → Certificates', 'Search the credential ID', 'Open it'],
    expected=['That credential and learner listed', 'Detail: "The learner", "Certificate details", "Public verification"'],
)
def ins_002(ctx: Ctx) -> None:
    d = ctx.d
    _admin(ctx)
    cred = ctx.api.ok('GET', '/learning/certificates', token=ctx.api.token('learner'))['issued'][0]['certificate']['credentialId']
    open_more_item(d, 'Certificates')
    d.fill('Search by learner, email or credential', cred)
    d.hide_keyboard()
    # The list re-reads after the search settles; tap the row only once the screen is still.
    # The search box itself now holds the credential too; the result is the row, not the field.
    d.wait(contains=cred, editable=False, timeout=20)
    time.sleep(1.5)
    d.tap(d.settle().find(contains=cred, editable=False))
    d.wait(label='The learner', timeout=30)
    d.scroll_to(label='Public verification', max_swipes=8)
    ctx.shot('certificate')


# ── FLUTTER-026 Reports ────────────────────────────────────────────────────────────────────────


@scenario(
    'REP-001', 'FLUTTER-026', 'The overview report and a period change', slug='staff-reports', tier='smoke', priority='P0',
    purpose='More → Reports shows the overview; changing the period re-reads it.',
    actions=['Admin: More → Reports', 'Filters → Last 30 days → Show the reports'],
    expected=['"Last 90 days" caption with KPIs', '"Last 30 days" caption afterwards'],
)
def rep_001(ctx: Ctx) -> None:
    d = ctx.d
    _admin(ctx)
    open_more_item(d, 'Reports')
    d.wait(contains='Last 90 days', timeout=30)
    d.expect('KPI', contains='Enrolments')
    ctx.shot('overview')
    # "Filters" is merged into the "Overview" header's single accessibility node; it is drawn at
    # that node's top-right, which is where a person taps it.
    header = d.wait(label='Filters', cls='Button')
    l, t, r, b = header.bounds
    d.tap_at(r - 160, t + 70, why='Filters is merged into the Overview header node; tap where it is drawn')
    d.wait(label='What these reports cover', timeout=15)
    d.tap(d.wait(label='Period', cls='Button'))  # a select field: open it, then choose
    d.tap(d.wait(label='Last 30 days', timeout=15))
    d.tap(d.scroll_to(label='Show the reports', max_swipes=6))
    d.wait(contains='Last 30 days', timeout=20)
    ctx.shot('30-days')


@scenario(
    'REP-002', 'FLUTTER-026', 'Courses report lists the busiest courses', slug='staff-reports', tier='smoke', priority='P2',
    purpose='The Courses report opens from the overview and names real courses.',
    actions=['Reports → Courses'],
    expected=['A published course title from GET /courses'],
)
def rep_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _admin(ctx)
    titles = [r['title'] for r in _rows(ctx.api.ok('GET', '/courses', token=token))]
    open_more_item(d, 'Reports')
    d.tap(d.scroll_to(label='Courses', cls='Button', max_swipes=10))
    time.sleep(2)
    hit = next((t for t in titles if d.sees(contains=t)), None)
    if not hit:
        d.scroll()
        hit = next((t for t in titles if d.sees(contains=t)), None)
    ctx.check(hit is not None, 'the Courses report names none of the academy\'s courses')
    ctx.shot('courses-report')


# ── FLUTTER-027 Billing ────────────────────────────────────────────────────────────────────────


@scenario(
    'BILL-001', 'FLUTTER-027', 'Billing tells the admin the academy has no plan, and lists plans', slug='staff-billing', tier='smoke', priority='P0',
    purpose="GET /tenant/billing is rendered: the academy's state and the plans on sale (no change is made).",
    actions=['Admin: More → Billing', 'See the plans'],
    expected=['"Your plan" with the no-plan / ended state', '"Plans" with each plan name from the API'],
)
def bill_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _admin(ctx)
    billing = ctx.api.ok('GET', '/tenant/billing', token=token)
    plans = [p['name'] for p in billing['plans']]
    open_more_item(d, 'Billing')
    d.wait(label='Your plan', timeout=30)
    d.wait(regex=r"(isn.t on a plan yet|Your plan has ended)", timeout=15)
    ctx.shot('billing')
    d.tap_start(d.scroll_to(regex=r'^(See the plans|Change plan)$', cls='Button', max_swipes=6))
    d.wait(label='Plans', timeout=20)
    for name in [p for p in plans if p][:2]:
        d.scroll_to(contains=name, max_swipes=8)
    ctx.shot('plans')


@scenario(
    'BILL-002', 'FLUTTER-027', 'Billing usage and invoices sections', slug='staff-billing', tier='smoke', priority='P2',
    purpose='The usage and invoice sections render from the same response.',
    actions=['Admin: More → Billing', 'Scroll'],
    expected=['"What you’re using", "Invoices" (or "No invoices yet.")'],
)
def bill_002(ctx: Ctx) -> None:
    d = ctx.d
    _admin(ctx)
    open_more_item(d, 'Billing')
    d.wait(label='Your plan', timeout=30)
    d.scroll_to(contains='using', max_swipes=8)
    d.scroll_to(regex=r'^(Invoices|No invoices yet\.)$', max_swipes=10)
    ctx.shot('usage-invoices')
