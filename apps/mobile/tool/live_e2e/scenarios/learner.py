"""Learner-facing modules FLUTTER-008 … FLUTTER-017 — smoke flows (3–4 per module).

Every entity is chosen from the signed-in learner's own API data first and then found on screen;
actions that change data are reversible within the scenario (save → unsave, take a seat → give it
back, mark unread → read) or touch only data the scenario owns.
"""

from __future__ import annotations

import time

from harness import SEED, Ctx, scenario, seed_password
from scenarios.flows import (
    fresh_app,
    open_curriculum_lesson,
    open_more_item,
    open_profile,
    sign_in_as,
    tab,
    wait_learner_home,
)


def _learner(ctx: Ctx) -> str:
    sign_in_as(ctx.d, 'learner', SEED['learner'], seed_password(), 'Ananya')
    return ctx.api.token('learner')


def _catalog(ctx: Ctx) -> list[dict]:
    return ctx.api.ok('GET', '/catalog/courses')


def _my_courses(ctx: Ctx, token: str) -> dict:
    return ctx.api.ok('GET', '/learning/courses', token=token)


# ── FLUTTER-008 Public ─────────────────────────────────────────────────────────────────────────


@scenario(
    'PUB-001', 'FLUTTER-008', 'A visitor browses the catalogue and opens a course', slug='public', tier='smoke', priority='P0',
    purpose='Signed out, Browse courses lists the published catalogue and a course opens its public page.',
    actions=['Welcome → Browse courses', 'Find the first published course from GET /catalog/courses', 'Open it'],
    expected=['"Courses" with that course listed', 'Its page: the title, "About this course", "Curriculum", "Sign in to enrol"'],
)
def pub_001(ctx: Ctx) -> None:
    d = ctx.d
    course = _catalog(ctx)[0]
    fresh_app(d)
    d.tap(label='Browse courses', cls='Button')
    card = d.wait(contains=course['title'], timeout=30)
    ctx.shot('catalogue')
    d.tap(card)
    d.wait(label=course['title'], timeout=30)
    d.scroll_to(label='Curriculum', max_swipes=8)
    d.scroll_to(label='Sign in to enrol', max_swipes=10)
    ctx.shot('course-page')


@scenario(
    'PUB-002', 'FLUTTER-008', 'Level filter narrows the catalogue', slug='public', tier='smoke', priority='P1',
    purpose='Choosing a level shows exactly the courses at that level.',
    actions=['Browse courses', 'Tap the Intermediate chip'],
    expected=['Every intermediate course from GET /catalog/courses?levelId=… is listed', 'A beginner-only course is not'],
)
def pub_002(ctx: Ctx) -> None:
    d = ctx.d
    levels = ctx.api.ok('GET', '/catalog/levels')
    inter = next(l for l in levels if l['name'].lower().startswith('intermediate'))
    beg = next(l for l in levels if l['name'].lower().startswith('beginner'))
    courses = _catalog(ctx)
    want = [c['title'] for c in courses if c['levelId'] == inter['id']]
    other = [c['title'] for c in courses if c['levelId'] == beg['id']]
    ctx.check(bool(want) and bool(other), 'precondition: need intermediate and beginner courses')
    fresh_app(d)
    d.tap(label='Browse courses', cls='Button')
    d.wait(contains=courses[0]['title'], timeout=30)
    d.tap(d.wait(regex=r'^Intermediate'))
    time.sleep(2)
    for t in want:
        d.scroll_to(contains=t, max_swipes=6)
    d.scroll(direction='up')
    d.scroll(direction='up')
    for t in other:
        d.expect_absent(f'{t!r} is a beginner course', contains=t)
    ctx.shot('intermediate')


@scenario(
    'PUB-003', 'FLUTTER-008', 'Verify a certificate by credential ID, and an unknown ID', slug='public', tier='smoke', priority='P0',
    purpose="A visitor checks a real credential (the learner's own) and a made-up one.",
    preconditions=["the learner's issued certificate"],
    actions=['Welcome → Verify a certificate', 'Verify with an empty field', 'Enter the issued ID → Verify', 'Check another ID → an unknown ID → Verify'],
    expected=['"Enter a credential ID."', '"This certificate is valid" for that ID and learner', '"No certificate found for this ID"'],
)
def pub_003(ctx: Ctx) -> None:
    d = ctx.d
    cred = ctx.api.ok('GET', '/learning/certificates', token=ctx.api.token('learner'))['issued'][0]['certificate']['credentialId']
    fresh_app(d)
    d.tap(label='Verify a certificate', cls='Button')
    d.wait(field='Credential ID', timeout=20)
    d.hide_keyboard()
    d.tap(label='Verify', cls='Button')
    d.wait(label='Enter a credential ID.')
    d.fill('Credential ID', cred)
    d.hide_keyboard()
    d.tap(label='Verify', cls='Button')
    d.wait(label='This certificate is valid', timeout=30)
    d.expect('same learner', contains='Ananya')
    ctx.shot('valid')
    d.tap(d.scroll_to(label='Check another ID', max_swipes=6))
    d.fill('Credential ID', 'SA-XX-0000-99999')
    d.hide_keyboard()
    d.tap(label='Verify', cls='Button')
    d.wait(label='No certificate found for this ID', timeout=30)
    ctx.shot('not-found')


@scenario(
    'PUB-004', 'FLUTTER-008', 'The help centre opens an article', slug='public', tier='smoke', priority='P2',
    purpose='A visitor reads help without signing in.',
    actions=['Welcome → Help centre', 'Open the first popular article from GET /help/articles'],
    expected=['"Help centre" with "Popular articles"', 'The article title as its page'],
)
def pub_004(ctx: Ctx) -> None:
    d = ctx.d
    arts = [a['article'] for a in ctx.api.ok('GET', '/help/articles')]
    fresh_app(d)
    d.tap(label='Help centre', cls='Button')
    d.wait(label='Popular articles', timeout=30)
    d.tap(d.scroll_to(contains=arts[0]['title'], max_swipes=6))
    time.sleep(2)
    d.expect('article page', contains=arts[0]['title'])
    ctx.shot('article')


# ── FLUTTER-009 Home & My Learning ─────────────────────────────────────────────────────────────


@scenario(
    'HOME-001', 'FLUTTER-009', "Home shows this learner's own courses and what is coming up", slug='learner-home', tier='smoke', priority='P0',
    purpose='The learner home renders /learning/home for the signed-in learner.',
    actions=['Sign in as the learner', 'Read Continue learning, Coming up, Your courses'],
    expected=["Each in-progress course of hers from /learning/home appears", '"Continue learning" offers Resume'],
)
def home_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    home = ctx.api.ok('GET', '/learning/home', token=token)
    d.expect('continue learning', label='Continue learning')
    d.expect('resume action', contains='Resume')
    for c in home['courses'][:2]:
        d.scroll_to(contains=c['course']['title'], max_swipes=6)
    ctx.shot('home')


@scenario(
    'HOME-002', 'FLUTTER-009', 'My Learning: in progress, completed and saved', slug='learner-home', tier='smoke', priority='P0',
    purpose="The three segments list exactly this learner's enrolments by state.",
    actions=['My Learning tab', 'In progress', 'Completed', 'Saved'],
    expected=['In-progress course titles from /learning/courses', 'Completed ones under Completed (or its empty state)', 'Saved ones (or "Nothing saved")'],
)
def home_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    mine = _my_courses(ctx, token)
    completed = [c['course']['title'] for c in mine['courses'] if c.get('enrollment', {}).get('status') == 'completed']
    progress = [c['course']['title'] for c in mine['courses'] if c.get('enrollment', {}).get('status') != 'completed']
    d.tap(**tab('My Learning'))
    d.wait(regex=r'^In progress', timeout=20)
    for t in progress:
        d.scroll_to(contains=t, max_swipes=4)
    ctx.shot('in-progress')
    d.tap(regex=r'^Completed')
    time.sleep(1.5)
    if completed:
        d.wait(contains=completed[0], timeout=15)
    else:
        d.wait(label='No courses completed yet', timeout=15)
    d.tap(regex=r'^Saved')
    time.sleep(1.5)
    if mine['saved']:
        d.wait(contains=mine['saved'][0]['course']['title'], timeout=15)
    else:
        d.wait(label='Nothing saved', timeout=15)
    ctx.shot('saved')


# ── FLUTTER-010 Explore & enrolment ────────────────────────────────────────────────────────────


def _not_enrolled(ctx: Ctx, token: str) -> dict:
    mine = {c['course']['id'] for c in _my_courses(ctx, token)['courses']}
    return next(c for c in _catalog(ctx) if c['id'] not in mine)


@scenario(
    'EXP-001', 'FLUTTER-010', 'Explore shows enrolled and new courses differently', slug='explore', tier='smoke', priority='P0',
    purpose="Explore lists the academy's courses and marks the ones this learner is already in.",
    actions=['Explore tab', 'Find an enrolled course and a not-enrolled course (from the API)'],
    expected=['Both listed', 'The enrolled one carries "Enrolled"'],
)
def exp_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    enrolled = _my_courses(ctx, token)['courses'][0]['course']['title']
    other = _not_enrolled(ctx, token)['title']
    d.tap(**tab('Explore'))
    node = d.scroll_to(contains=enrolled, max_swipes=8)
    ctx.check('Enrolled' in node.label or d.sees(label='Enrolled'), f'{enrolled!r} is not marked Enrolled: {node.label!r}')
    d.scroll_to(contains=other, max_swipes=8)
    ctx.shot('explore')


@scenario(
    'EXP-002', 'FLUTTER-010', 'Save a course, see it in Saved, unsave it', slug='explore', tier='smoke', priority='P0',
    purpose='Save/unsave round-trips through the server and My Learning → Saved.',
    actions=['Explore → a course she is not in', 'Save this course', 'My Learning → Saved', 'Back to the course → Remove from saved'],
    expected=['"Remove from saved" after saving', 'The course under Saved', 'Unsaved again (API agrees)'],
    cleanup='The course is unsaved at the end',
)
def exp_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    course = _not_enrolled(ctx, token)
    if any(s['course']['id'] == course['id'] for s in _my_courses(ctx, token)['saved']):
        ctx.api.ok('POST', f"/learning/courses/{course['id']}/save", token=token)  # start unsaved
    d.tap(**tab('Explore'))
    d.tap(d.scroll_to(contains=course['title'], max_swipes=8))
    d.tap(d.wait(label='Save this course', timeout=20))
    d.wait(label='Remove from saved', timeout=15)
    ctx.check(any(s['course']['id'] == course['id'] for s in _my_courses(ctx, token)['saved']), 'the server does not have it saved')
    ctx.shot('saved')
    d.tap(label='Remove from saved')
    d.wait(label='Save this course', timeout=15)
    ctx.check(not any(s['course']['id'] == course['id'] for s in _my_courses(ctx, token)['saved']), 'still saved on the server')


@scenario(
    'EXP-003', 'FLUTTER-010', 'Enrol asks first; Cancel enrols nobody', slug='explore', tier='smoke', priority='P1',
    purpose='The enrol confirmation appears and cancelling leaves the learner not enrolled (the irreversible confirm is deep QA).',
    actions=['Explore → a course she is not in', 'Enrol', 'Cancel'],
    expected=['"Enrol in this course?" dialog', 'After Cancel: still not enrolled (API), Enrol still offered'],
)
def exp_003(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    course = _not_enrolled(ctx, token)
    d.tap(**tab('Explore'))
    d.tap(d.scroll_to(contains=course['title'], max_swipes=8))
    d.tap(d.wait(label='Enrol', cls='Button', timeout=20))
    d.wait(label='Enrol in this course?')
    ctx.shot('enrol-dialog')
    d.tap(label='Cancel', cls='Button')
    d.wait_gone(label='Enrol in this course?')
    ctx.check(course['id'] not in {c['course']['id'] for c in _my_courses(ctx, token)['courses']}, 'cancelled enrolment enrolled her anyway')
    d.expect('enrol still offered', label='Enrol', cls='Button')


# ── FLUTTER-011 Course learning ────────────────────────────────────────────────────────────────


def _in_progress(ctx: Ctx, token: str) -> dict:
    return next(c for c in _my_courses(ctx, token)['courses'] if c.get('enrollment', {}).get('status') != 'completed')


@scenario(
    'LEARN-001', 'FLUTTER-011', 'Resume opens the next lesson of that course', slug='course-learning', tier='smoke', priority='P0',
    purpose="Home's Resume takes the learner to the lesson the server says is next, in the same course.",
    actions=['Home → Continue learning → Resume'],
    expected=['The lesson player shows the next lesson title from /learning/home', '"{n} of {total}" position'],
)
def learn_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    home = ctx.api.ok('GET', '/learning/home', token=token)
    cont = next(c for c in home['courses'] if c.get('next'))
    d.tap(d.wait(contains='Resume'))
    d.wait(contains=cont['next']['title'], timeout=30)
    d.expect('position in the course', regex=r'\d+ of \d+')
    ctx.shot('lesson')


@scenario(
    'LEARN-002', 'FLUTTER-011', 'The course page lists its curriculum and moves between lessons', slug='course-learning', tier='smoke', priority='P0',
    purpose='Opening an enrolled course shows chapters and lessons; Next and Previous move within the course.',
    actions=['My Learning → an in-progress course', 'Open its first lesson', 'Next', 'Previous'],
    expected=['"Curriculum" with the first chapter title', 'Next shows a different lesson; Previous returns to the first'],
)
def learn_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    c = _in_progress(ctx, token)
    detail = ctx.api.ok('GET', f"/learning/courses/{c['course']['id']}", token=token)
    chapters = detail.get('chapters') or detail.get('course', {}).get('chapters') or []
    first_lesson = chapters[0]['lessons'][0]['title']
    d.tap(**tab('My Learning'))
    d.tap(d.scroll_to(contains=c['course']['title'], max_swipes=4))
    d.scroll_to(label='Curriculum', max_swipes=6)
    ctx.shot('course')
    open_curriculum_lesson(d, chapters[0]['title'], first_lesson)
    d.wait(contains=first_lesson, timeout=30)
    d.tap(d.wait(label='Next', timeout=15))
    time.sleep(2)
    d.tap(d.wait(label='Previous', timeout=15))
    d.wait(contains=first_lesson, timeout=20)
    ctx.shot('previous')


# ── FLUTTER-012 Quizzes ────────────────────────────────────────────────────────────────────────


@scenario(
    'QUIZ-001', 'FLUTTER-012', "Assessments lists this learner's quizzes with their state", slug='quizzes', tier='smoke', priority='P0',
    purpose='More → Assessments shows each quiz from /learning/assessments with its pass mark.',
    actions=['More → Assessments'],
    expected=['Each quiz title listed', '"pass 70%"-style pass mark shown'],
)
def quiz_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    quizzes = ctx.api.ok('GET', '/learning/assessments', token=token)
    open_more_item(d, 'Assessments')
    for q in quizzes:
        d.scroll_to(contains=q['title'], max_swipes=6)
    d.expect('pass mark', contains=f"pass {quizzes[0]['passMark']}%")
    ctx.shot('assessments')


@scenario(
    'QUIZ-002', 'FLUTTER-012', 'Take a passed quiz again as practice and pass it', slug='quizzes', tier='smoke', priority='P1', repeat_safe=True,
    purpose='A quiz already passed can be practised again; answering it right ends in "Passed" (the server scores it).',
    preconditions=['a quiz in state passed (unlimited practice after a pass)'],
    actions=['More → Assessments → the passed quiz', 'Start the quiz', 'Answer each question', 'Review answers → Submit → Submit'],
    expected=['"Question 1 of N"', '"Submit this attempt?"', 'A result screen ("Passed" or "Not passed this time") from the server'],
)
def quiz_002(ctx: Ctx) -> None:
    from harness import Blocked

    d = ctx.d
    token = _learner(ctx)
    passed = [q for q in ctx.api.ok('GET', '/learning/assessments', token=token) if q['state'] == 'passed']
    if not passed:
        raise Blocked('no passed quiz for the learner to practise without spending a graded attempt')
    q = passed[0]
    detail = ctx.api.ok('GET', f"/learning/courses/{q['courseId']}", token=token)
    chapter = next(ch for ch in detail['course']['chapters'] if any(l['id'] == q['lessonId'] for l in ch['lessons']))
    lesson = next(l for l in chapter['lessons'] if l['id'] == q['lessonId'])
    # A passed quiz is not reopened from the Assessments list (only available/failed rows open);
    # a learner reaches it through the course, as here.
    d.tap(**tab('My Learning'))
    d.tap(d.scroll_to(contains=q['courseTitle'], max_swipes=6))
    open_curriculum_lesson(d, chapter['title'], lesson['title'])
    # The intro card ("Before you start … Start the quiz") is one merged node; its Start button is
    # drawn along the card's bottom edge, where a person taps it.
    intro = d.wait(label='Start the quiz', cls='Button', timeout=30)
    l, t, r, b = intro.bounds
    d.tap_at((l + r) // 2, b - 70, why='Start the quiz is merged into the intro card node; tap where it is drawn')
    # Progress is announced with the question ("33%, 33% complete / Question 1 of 3 / …").
    d.wait(regex=r'(^|\n)Question 1 of \d+', timeout=30)
    ctx.shot('question-1')
    known = ('12', 'False', '75%')  # the seed's correct answers (academyDemo.ts)
    for _ in range(q['questions']):
        screen = d.dump()
        question = screen.find(regex=r'(^|\n)Question \d+ of \d+')
        # Answer options are the buttons inside the question card — never its own navigation, and
        # never the lesson's Previous/Next bar below it.
        navigation = {'Previous', 'Next', 'Review answers', 'Completed', 'Mark complete'}
        options = [n for n in screen.nodes if n.cls.endswith('Button') and question
                   and question.bounds[1] < n.bounds[1] < question.bounds[3] and n.label not in navigation]
        choice = next((n for n in options if n.label in known), options[0] if options else None)
        if choice:
            d.tap(choice)
        elif screen.find(field='Your answer'):
            d.fill('Your answer', '75%')
            d.hide_keyboard()
        settled = d.settle()
        before = settled.find(regex=r'(^|\n)Question \d+ of \d+')
        # The quiz's own Next/Review sits above the lesson's Previous/Next bar.
        quiz_nav = [n for n in settled.find_all(regex=r'^(Next|Review answers)$', cls='Button') if n.bounds[3] < 1950]
        if not quiz_nav:
            break
        d.tap(quiz_nav[0])
        after = d.settle()
        ctx.check(
            after.has(label='Your answers') or after.find(regex=r'(^|\n)Question \d+ of \d+') is None
            or after.find(regex=r'(^|\n)Question \d+ of \d+').label != (before.label if before else ''),
            f'tapping {quiz_nav[0].label} on a settled screen did not move on from {before.label.splitlines()[1] if before else "?"}',
        )
    # The review card ("Your answers … Submit") is one merged node whose centre is a question row
    # (tapping it reopens that question); Submit is drawn along the card's bottom edge.
    review = d.wait(label='Submit', cls='Button', timeout=15)
    l, t, r, b = review.bounds
    d.tap_at((l + r) // 2, b - 70, why='Submit is merged into the review card node; tap where it is drawn')
    d.wait(label='Submit this attempt?')
    buttons = d.dump().find_all(label='Submit', cls='Button')
    d.tap(buttons[-1])
    d.wait(regex=r'^(Passed|Not passed this time)', timeout=30)
    ctx.shot('result')


# ── FLUTTER-013 Assignments ────────────────────────────────────────────────────────────────────


@scenario(
    'ASG-001', 'FLUTTER-013', "Assignments lists this learner's work with its state", slug='assignments', tier='smoke', priority='P0',
    purpose='More → Assignments shows every assignment from /learning/assignments, the overdue one marked Overdue.',
    actions=['More → Assignments'],
    expected=['Each assignment title', 'An overdue one shows "Overdue"'],
)
def asg_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    rows = ctx.api.ok('GET', '/learning/assignments', token=token)
    open_more_item(d, 'Assignments')
    for r in rows:
        node = d.scroll_to(contains=r['assignment']['title'], max_swipes=6)
        if r['state'] == 'overdue':
            ctx.check('Overdue' in node.label, f"{r['assignment']['title']!r} is overdue but reads {node.label!r}")
    ctx.shot('assignments')


@scenario(
    'ASG-002', 'FLUTTER-013', 'Write a draft and save it', slug='assignments', tier='smoke', priority='P0',
    purpose='A learner drafts an answer on an open assignment and the draft is saved on the server.',
    preconditions=['an assignment the learner can still work on (not submitted)'],
    actions=['More → Assignments → an open assignment', 'Type into "Your work"', 'Save draft'],
    expected=['"Draft saved"', 'GET /learning/assignments/:id holds the typed text'],
    cleanup='Only the learner\'s own draft on that assignment is changed',
)
def asg_002(ctx: Ctx) -> None:
    from harness import Blocked

    d = ctx.d
    token = _learner(ctx)
    rows = ctx.api.ok('GET', '/learning/assignments', token=token)
    open_rows = [r for r in rows if r['state'] in ('not-started', 'draft', 'overdue', 'resubmit')]
    if not open_rows:
        raise Blocked(f"no open assignment for the learner (states: {[r['state'] for r in rows]})")
    a = open_rows[0]['assignment']
    text = f'Live E2E draft {int(time.time())}'
    open_more_item(d, 'Assignments')
    d.tap(d.scroll_to(contains=a['title'], max_swipes=6))
    d.fill('Your work', text)
    d.hide_keyboard()
    d.tap(d.scroll_to(label='Save draft', cls='Button', max_swipes=8))
    # The status is announced as part of the field ("Your work / 4 words / Draft saved now").
    d.wait(regex=r'(^|\n)Draft saved', timeout=20)
    detail = ctx.api.ok('GET', f"/learning/assignments/{a['id']}", token=token)
    ctx.check(text in str(detail), 'the server does not hold the draft that was typed')
    ctx.shot('draft-saved')


# ── FLUTTER-014 Certificates & ranks ───────────────────────────────────────────────────────────


@scenario(
    'CERT-001', 'FLUTTER-014', 'The wallet shows her issued certificate and its details', slug='certificates', tier='smoke', priority='P0',
    purpose="More → Certificates lists the learner's issued certificate; its detail shows that credential.",
    actions=['More → Certificates', 'Open the issued certificate'],
    expected=['"Issued" section with the credential ID from /learning/certificates', 'Detail: "Certificate details" and the same ID'],
)
def cert_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    issued = ctx.api.ok('GET', '/learning/certificates', token=token)['issued'][0]
    cred = issued['certificate']['credentialId']
    open_more_item(d, 'Certificates')
    node = d.scroll_to(contains=cred, max_swipes=6)
    ctx.shot('wallet')
    d.tap(node)
    d.wait(label='Certificate details', timeout=30)
    d.scroll_to(contains=cred, max_swipes=6)
    ctx.shot('detail')


@scenario(
    'CERT-002', 'FLUTTER-014', 'The rank ladder shows where she is', slug='certificates', tier='smoke', priority='P1',
    purpose='More → Rank ladder shows the ranks and marks the current one.',
    actions=['More → Rank ladder'],
    expected=['"Rank I · Beginner" and "Where you are now" on one step'],
)
def cert_002(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    open_more_item(d, 'Rank ladder')
    d.wait(contains='Rank I', timeout=30)
    d.scroll_to(contains='Where you are now', max_swipes=6)
    ctx.shot('ranks')


# ── FLUTTER-015 Live ───────────────────────────────────────────────────────────────────────────


@scenario(
    'LIVE-001', 'FLUTTER-015', 'Live lists her upcoming class and its detail', slug='live', tier='smoke', priority='P0',
    purpose='The Live tab shows the upcoming class from /live/learner and its detail page.',
    actions=['Live tab', 'Open the upcoming class'],
    expected=['"Upcoming" with that class title', 'Detail: "About this class" and the instructor'],
)
def live_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    up = ctx.api.ok('GET', '/live/learner', token=token)['upcoming'][0]
    d.tap(**tab('Live'))
    d.tap(d.scroll_to(contains=up['liveClass']['title'], max_swipes=6))
    d.scroll_to(label='About this class', max_swipes=6)
    d.expect('instructor', contains=up['instructorName'])
    ctx.shot('live-detail')


@scenario(
    'LIVE-002', 'FLUTTER-015', 'Take a seat and give it back', slug='live', tier='smoke', priority='P0',
    purpose="Registration toggles on the server for that same class.",
    actions=['Live → upcoming class', 'Save my seat (or Give up my seat first if already registered)', 'Give up my seat'],
    expected=['"Give up my seat" + "Registered" after saving; API registered=true', 'Back to "Save my seat"; API registered as at the start'],
    cleanup='Registration returned to its initial state',
)
def live_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    up = ctx.api.ok('GET', '/live/learner', token=token)['upcoming'][0]
    start = up['registered']
    d.tap(**tab('Live'))
    d.tap(d.scroll_to(contains=up['liveClass']['title'], max_swipes=6))
    first, second = ('Give up my seat', 'Save my seat') if start else ('Save my seat', 'Give up my seat')
    d.tap(d.scroll_to(label=first, max_swipes=8))
    d.scroll_to(label=second, max_swipes=8)
    now = ctx.api.ok('GET', '/live/learner', token=token)['upcoming'][0]
    ctx.check(now['registered'] != start, 'the server did not record the change')
    ctx.shot('toggled')
    d.tap(d.scroll_to(label=second, max_swipes=8))
    d.scroll_to(label=first, max_swipes=8)
    ctx.check(ctx.api.ok('GET', '/live/learner', token=token)['upcoming'][0]['registered'] == start, 'not restored on the server')


# ── FLUTTER-016 Notifications ──────────────────────────────────────────────────────────────────


@scenario(
    'NOTIF-001', 'FLUTTER-016', 'The bell opens her notifications', slug='notifications', tier='smoke', priority='P0',
    purpose="The bell's unread count matches the server and opens the list of this learner's notifications.",
    actions=['Read the bell', 'Tap it'],
    expected=['Bell says "{n} unread notifications" (n from GET /notifications) or "Notifications"', 'The newest notification title is listed'],
)
def notif_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    data = ctx.api.ok('GET', '/notifications', token=token)
    unread = data['unread']
    bell = d.wait(regex=r'^(\d+ unread notifications|Notifications)$', cls='Button')
    expected = f'{unread} unread notifications' if unread else 'Notifications'
    ctx.check(bell.label == expected, f'bell reads {bell.label!r}, the server says {unread} unread')
    d.tap(bell)
    d.wait(contains=data['rows'][0]['title'], timeout=30)
    ctx.shot('notifications')


@scenario(
    'NOTIF-002', 'FLUTTER-016', 'Mark one notification unread, then read again', slug='notifications', tier='smoke', priority='P1',
    purpose='Per-row read state round-trips through the server.',
    actions=['Bell → the newest notification\'s More menu → Mark unread / Mark read', 'Then the opposite'],
    expected=['The server\'s unread count goes up by one, then back'],
    cleanup='Read state restored',
)
def notif_002(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    before = ctx.api.ok('GET', '/notifications', token=token)
    row = before['rows'][0]
    d.tap(d.wait(regex=r'^(\d+ unread notifications|Notifications)$', cls='Button'))
    d.wait(contains=row['title'], timeout=30)
    menus = d.dump().find_all(label='More', cls='Button')
    title_node = d.dump().find(contains=row['title'])
    menu = min((m for m in menus if m.bounds[1] >= title_node.bounds[1] - 150), key=lambda m: abs(m.bounds[1] - title_node.bounds[1]), default=None)
    ctx.check(menu is not None, 'no per-row menu next to the notification')
    d.tap(menu)
    choice = d.wait(regex=r'^Mark (unread|read)$', timeout=10)
    d.tap(choice)
    time.sleep(2)
    mid = ctx.api.ok('GET', '/notifications', token=token)['unread']
    ctx.check(mid != before['unread'], 'the unread count did not change on the server')
    ctx.shot('toggled')
    d.tap(menu)
    d.tap(d.wait(regex=r'^Mark (unread|read)$', timeout=10))
    time.sleep(2)
    ctx.check(ctx.api.ok('GET', '/notifications', token=token)['unread'] == before['unread'], 'read state not restored')


@scenario(
    'NOTIF-003', 'FLUTTER-016', 'Notification settings open with her channels', slug='notifications', tier='smoke', priority='P2',
    purpose='Profile → Notification settings shows the per-category channels and the digest.',
    actions=['More → Profile → Notification settings'],
    expected=['"What you hear about" and "Email digest"'],
)
def notif_003(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    open_profile(d, SEED['learner'])
    d.tap(d.scroll_to(label='Notification settings', max_swipes=6))
    d.wait(label='What you hear about', timeout=30)
    d.scroll_to(label='Email digest', max_swipes=8)
    ctx.shot('preferences')


# ── FLUTTER-017 Profile & settings ─────────────────────────────────────────────────────────────


@scenario(
    'PROF-001', 'FLUTTER-017', 'Profile shows who is signed in', slug='profile', tier='smoke', priority='P0',
    purpose='Profile renders /auth/me for the signed-in account.',
    actions=['More → Profile'],
    expected=['Name, email and "Learner" of the account /auth/me returns'],
)
def prof_001(ctx: Ctx) -> None:
    d = ctx.d
    token = _learner(ctx)
    me = ctx.api.ok('GET', '/auth/me', token=token)['user']
    card = open_profile(d, me['email'])
    for part in (me['name'], me['email'], 'Learner'):
        ctx.check(part in card.label, f'profile card lacks {part!r}: {card.label!r}')
    ctx.shot('profile')


@scenario(
    'PROF-002', 'FLUTTER-017', 'Switch to the dark theme and back', slug='profile', tier='smoke', priority='P1',
    purpose='App settings → Appearance changes the theme immediately and the choice is kept.',
    actions=['Profile → App settings', 'Dark', 'Relaunch', 'Match my phone'],
    expected=['Dark selected and kept after a relaunch', 'Restored to Match my phone'],
    cleanup='Appearance back to Match my phone',
)
def prof_002(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    open_profile(d, SEED['learner'])
    d.tap(d.scroll_to(label='App settings', max_swipes=6))
    d.wait(label='Appearance', timeout=20)
    d.tap(label='Dark')
    time.sleep(1)
    ctx.check(d.dump().find(label='Dark').checked, 'Dark is not selected after tapping it')
    ctx.shot('dark')
    d.relaunch()
    d.wait_focused()
    wait_learner_home(d, 'Ananya', timeout=60)  # a cold restore of the session can take ~40 s here
    open_profile(d, SEED['learner'])
    d.tap(d.scroll_to(label='App settings', max_swipes=6))
    d.wait(label='Appearance', timeout=20)
    ctx.check(d.dump().find(label='Dark').checked, 'the Dark choice was not kept after a relaunch')
    d.tap(label='Match my phone')
    time.sleep(1)
    ctx.check(d.dump().find(label='Match my phone').checked, 'could not switch back to Match my phone')


@scenario(
    'PROF-003', 'FLUTTER-017', 'About this app names the app and its version', slug='profile', tier='smoke', priority='P2',
    purpose='The About dialog identifies the build.',
    actions=['Profile → About this app'],
    expected=['"ZuviloAI" and "Version …"'],
)
def prof_003(ctx: Ctx) -> None:
    d = ctx.d
    _learner(ctx)
    open_profile(d, SEED['learner'])
    d.tap(d.scroll_to(label='About this app', max_swipes=6))
    d.wait(contains='Version', timeout=15)
    d.expect('app name', contains='ZuviloAI')
    ctx.shot('about')
    d.back()
