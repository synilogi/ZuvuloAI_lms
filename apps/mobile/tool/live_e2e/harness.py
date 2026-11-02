"""Scenario declarations, the per-scenario context, test identities and the backend helper.

The backend helper exists for two jobs only: preparing data a scenario needs (through the same
public routes a client uses), and checking that what the UI shows is true of **the same entity**
the scenario acted on. It never replaces a UI step — every assertion that counts is made on the
screen.
"""

from __future__ import annotations

import json
import os
import secrets
import sqlite3
import subprocess
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable
from urllib.parse import urlparse

from driver import Device, E2EFailure, EnvironmentFailure

MOBILE = Path(__file__).resolve().parent.parent.parent
STATE_FILE = Path(os.environ.get('E2E_STATE', MOBILE / '.live_e2e' / 'state.json'))


class Blocked(Exception):
    """The scenario cannot run for a reason outside the app; the message names the requirement."""


@dataclass
class Scenario:
    id: str
    module: str
    title: str
    purpose: str
    actions: list[str]
    expected: list[str]
    fn: Callable[['Ctx'], None]
    preconditions: list[str] = field(default_factory=list)
    data: list[str] = field(default_factory=list)
    evidence: list[str] = field(default_factory=list)
    cleanup: str = ''
    cleanup_fn: Callable[['Ctx'], None] | None = None
    priority: str = 'P1'
    repeat_safe: bool = True
    # 'smoke': the 3–5 main flows that decide a module's live status in the fast pass.
    # 'deep': kept and documented for the later deep-QA phase; reported as DEFERRED until then.
    tier: str = 'deep'
    order: int = 0
    doc_slug: str = ''


REGISTRY: dict[str, Scenario] = {}


def scenario(id: str, module: str, title: str, *, slug: str, **meta) -> Callable:
    def wrap(fn: Callable[['Ctx'], None]) -> Callable:
        if id in REGISTRY:
            raise ValueError(f'duplicate scenario id {id}')
        REGISTRY[id] = Scenario(id=id, module=module, title=title, fn=fn, order=len(REGISTRY), doc_slug=slug, **meta)
        return fn

    return wrap


# ── identities ─────────────────────────────────────────────────────────────────────────────────
# The seeded demo accounts of the local contract database. Their e-mails are public in the seed;
# the password is read from the environment (E2E_SEED_PASSWORD), never from this repository.
SEED = {
    'learner': os.environ.get('E2E_LEARNER_EMAIL', 'ananya@syniastrolms.test'),
    'instructor': os.environ.get('E2E_INSTRUCTOR_EMAIL', 'meenakshi@syniastrolms.test'),
    'admin': os.environ.get('E2E_ADMIN_EMAIL', 'admin@syniastrolms.test'),
    'superadmin': os.environ.get('E2E_SUPERADMIN_EMAIL', 'ops@syniastrolms.test'),
}


def seed_password() -> str:
    pw = os.environ.get('E2E_SEED_PASSWORD')
    if not pw:
        raise Blocked('E2E_SEED_PASSWORD is not set: the password of the local seeded demo accounts is required')
    return pw


def load_state() -> dict:
    try:
        return json.loads(STATE_FILE.read_text())
    except FileNotFoundError:
        return {}


def save_state(state: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2))
    os.chmod(STATE_FILE, 0o600)


def new_identity(prefix: str = 'ai_e2e') -> dict:
    """A fresh, clearly synthetic learner. Its first name is unique to the run (the learner home
    greets by first name, so a greeting proves *which* account is signed in). The password is the
    configured E2E_SEED_PASSWORD — nothing secret is generated, printed or committed."""
    stamp = time.strftime('%Y%m%d%H%M%S')
    tag = secrets.token_hex(3)
    return {
        'first': f'Qa{tag}',
        'name': f'Qa{tag} Learner',
        'email': f'{prefix}_{stamp}_{tag}@example.test',
        'password': seed_password(),
    }


# ── backend ────────────────────────────────────────────────────────────────────────────────────
class Api:
    def __init__(self, base: str | None = None):
        self.base = (base or os.environ.get('E2E_API', 'http://localhost:4201')).rstrip('/')

    def call(self, method: str, path: str, body: dict | None = None, token: str | None = None) -> tuple[int, dict]:
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method=method)
        req.add_header('Content-Type', 'application/json')
        if token:
            req.add_header('Authorization', f'Bearer {token}')
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                raw = r.read()
                return r.status, json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            raw = e.read()
            try:
                return e.code, json.loads(raw)
            except ValueError:
                return e.code, {'raw': raw.decode(errors='replace')}
        except urllib.error.URLError as e:
            raise EnvironmentFailure(f'backend unreachable at {self.base}: {e.reason}') from e

    def ok(self, method: str, path: str, body: dict | None = None, token: str | None = None) -> dict:
        status, payload = self.call(method, path, body, token)
        if status >= 400:
            raise EnvironmentFailure(f'{method} {path} → {status}: {payload}')
        return payload

    def login(self, email: str, password: str) -> str:
        return self.ok('POST', '/auth/login', {'email': email, 'password': password})['token']

    def token(self, role: str) -> str:
        return self.login(SEED[role], seed_password())

    def app_base_url(self) -> str:
        cfg = json.loads(app_config_file().read_text())
        return cfg['API_BASE_URL']

    def assert_safe(self) -> None:
        """Data-changing scenarios run only against a local server, and only when the app under
        test is pointed at it too. A production or shared host stops the run before anything."""
        host = urlparse(self.base).hostname
        if host not in ('localhost', '127.0.0.1'):
            raise EnvironmentFailure(f'refusing to run: backend {self.base} is not local')
        app_host = urlparse(self.app_base_url()).hostname
        if app_host not in ('10.0.2.2', 'localhost', '127.0.0.1'):
            raise EnvironmentFailure(f'refusing to run: the dev flavor points at {self.app_base_url()}')
        status, _ = self.call('GET', '/health')
        if status != 200:
            raise EnvironmentFailure(f'backend {self.base}/health → {status}')
        db = scratch_db()
        if db is None:
            raise EnvironmentFailure('the contract server scratch database was not found (set E2E_DB or SCRATCH)')
        # The process answering on this port must be the one holding *this* scratch database — not
        # another session's server that happens to own the port.
        port = urlparse(self.base).port
        # Prisma opens the database lazily; one refused sign-in for an address that cannot exist
        # makes it look the account up (and changes nothing).
        self.call('POST', '/auth/login', {'email': 'no-such-account@example.test', 'password': 'x'})
        pids =subprocess.run(['lsof', '-ti', f'tcp:{port}', '-sTCP:LISTEN'], capture_output=True, text=True).stdout.split()
        open_files = ''.join(subprocess.run(['lsof', '-p', pid], capture_output=True, text=True).stdout for pid in pids)
        if str(db.resolve()) not in open_files and str(db) not in open_files:
            raise EnvironmentFailure(f'the server on :{port} (pid {", ".join(pids) or "none"}) is not using {db}')


def app_config_file() -> Path:
    """The dart-define file the APK under test was built from: the git-ignored E2E override when it
    exists (its own ports, so another session's contract server is never touched), else dev.json."""
    explicit = os.environ.get('E2E_APP_CONFIG')
    if explicit:
        return Path(explicit)
    local = MOBILE / 'config/dev_e2e.local.json'
    return local if local.exists() else MOBILE / 'config/dev.json'


def scratch_db() -> Path | None:
    explicit = os.environ.get('E2E_DB')
    if explicit:
        return Path(explicit)
    scratch = os.environ.get('SCRATCH')
    if scratch:
        p = Path(scratch) / 'flutter-api/flutter.db'
        return p if p.exists() else None
    return None


def outbox_link(to: str, contains: str, timeout: float = 15) -> str:
    """The newest link in a queued e-mail to [to] — the dev environment's own mail transport
    (`MAIL_TRANSPORT=outbox`) keeps messages in the scratch database instead of sending them."""
    import re

    db = scratch_db()
    if db is None:
        raise Blocked('the contract server scratch database is needed to read the dev mail outbox')
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        con = sqlite3.connect(f'file:{db}?mode=ro', uri=True)
        try:
            rows = con.execute(
                'select subject, text from "EmailOutbox" where "toEmail" = ? order by "createdAt" desc limit 5', (to,)
            ).fetchall()
        except sqlite3.OperationalError as e:
            raise Blocked(f'the dev mail outbox (EmailOutbox) is not readable: {e}') from e
        finally:
            con.close()
        for row in rows:
            blob = ' '.join(str(v) for v in row if isinstance(v, str))
            for url in re.findall(r'https?://[^\s"<>\')]+', blob):
                if contains in url:
                    return url
        time.sleep(0.5)
    raise E2EFailure(f'no e-mail to {to} with a link containing {contains!r} reached the outbox')


# ── per-scenario context ───────────────────────────────────────────────────────────────────────
@dataclass
class Ctx:
    device: Device
    scenario: Scenario
    evidence_root: Path
    evidence: list[Path] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)
    network_touched: bool = False
    delay_touched: bool = False
    api: Api = field(default_factory=Api)
    _shots: int = 0

    @property
    def d(self) -> Device:
        return self.device

    def shot(self, name: str) -> Path:
        self._shots += 1
        p = self.device.screenshot(self.evidence_root / f'{self._shots:02d}-{name}.png')
        self.evidence.append(p)
        return p

    def save(self, name: str, content: str) -> Path:
        p = self.evidence_root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
        if p not in self.evidence:
            self.evidence.append(p)
        return p

    def note(self, text: str) -> None:
        self.notes.append(text)

    def offline(self) -> None:
        self.network_touched = True
        self.device.set_network(False)

    def online(self) -> None:
        self.device.set_network(True)

    def slow_network(self, ms: int = 2500) -> None:
        """Holds every response back [ms] in the host relay (netem.py), so a loading state lasts
        long enough to be seen from outside the app."""
        from netem import set_delay

        self.delay_touched = True
        set_delay(ms)

    def normal_network(self) -> None:
        from netem import set_delay

        set_delay(0)

    def server_unreachable(self) -> None:
        """The academy's API stops answering (the relay refuses), while the device stays online."""
        from netem import set_down

        self.delay_touched = True
        set_down(True)

    def check(self, condition: bool, message: str) -> None:
        if not condition:
            raise E2EFailure(message)
