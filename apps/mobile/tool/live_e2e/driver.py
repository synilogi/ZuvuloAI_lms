"""Operates the real app on a real Android emulator the way a person does — from outside the process.

Nothing here links against the app. The screen is read through the platform accessibility tree
(`uiautomator dump`; Flutter publishes its semantics there: a widget's label becomes the node's
`content-desc`, an editable field becomes an `EditText`, `Semantics(identifier:)` becomes its
`resource-id`), and input is delivered through `adb shell input`, exactly as the touchscreen and
keyboard would deliver it. That is what separates this layer (LIVE UI E2E) from `integration_test`,
which runs inside the app's own isolate.

Selectors are semantic — a visible label, a field's label, an identifier. A coordinate is used only
when a scenario passes one explicitly, and the scenario must say why.
"""

from __future__ import annotations

import os
import re
import shlex
import subprocess
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable, Iterable

SDK = Path(os.environ.get('ANDROID_SDK_ROOT', Path.home() / 'Library/Android/sdk'))
ADB = os.environ.get('ADB', str(SDK / 'platform-tools/adb'))
PACKAGE = os.environ.get('E2E_PACKAGE', 'com.shubhlms.mobile.dev')

_BOUNDS = re.compile(r'\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]')


class E2EFailure(AssertionError):
    """A scenario's expectation was not met on the device."""


class EnvironmentFailure(RuntimeError):
    """The device, the app or the backend is not in a state a scenario can run in."""


@dataclass(frozen=True)
class Node:
    text: str
    desc: str
    rid: str
    cls: str
    hint: str
    bounds: tuple[int, int, int, int]
    clickable: bool
    enabled: bool
    checked: bool
    checkable: bool
    focused: bool
    selected: bool
    scrollable: bool
    password: bool

    @property
    def label(self) -> str:
        """What a screen reader would announce: the description, else the text, else the hint."""
        return self.desc or self.text or self.hint

    @property
    def center(self) -> tuple[int, int]:
        l, t, r, b = self.bounds
        return (l + r) // 2, (t + b) // 2

    @property
    def visible(self) -> bool:
        l, t, r, b = self.bounds
        return r > l and b > t

    @property
    def editable(self) -> bool:
        return self.cls.endswith('EditText')

    def __str__(self) -> str:
        short = self.cls.rsplit('.', 1)[-1]
        bits = [short]
        for name, value in (('desc', self.desc), ('text', self.text), ('hint', self.hint), ('id', self.rid)):
            if value:
                bits.append(f'{name}={value!r}')
        flags = [f for f in ('checked', 'focused', 'selected', 'password') if getattr(self, f)]
        if not self.enabled:
            flags.append('disabled')
        if flags:
            bits.append('[' + ','.join(flags) + ']')
        bits.append(str(self.bounds))
        return ' '.join(bits)


@dataclass
class Screen:
    nodes: list[Node]
    raw: str

    def find_all(self, **q) -> list[Node]:
        return [n for n in self.nodes if _matches(n, **q)]

    def find(self, **q) -> Node | None:
        hits = self.find_all(**q)
        return hits[0] if hits else None

    def has(self, **q) -> bool:
        return self.find(**q) is not None

    def labels(self) -> list[str]:
        return [n.label for n in self.nodes if n.label]

    def text_blob(self) -> str:
        return '\n'.join(self.labels())

    def describe(self) -> str:
        return '\n'.join(str(n) for n in self.nodes if n.label or n.editable or n.rid)


def _matches(
    n: Node,
    label: str | None = None,
    contains: str | None = None,
    regex: str | None = None,
    rid: str | None = None,
    cls: str | None = None,
    field: str | None = None,
    editable: bool | None = None,
    checked: bool | None = None,
    enabled: bool | None = None,
) -> bool:
    """`label` is an exact match on any of desc/text/hint (or a line of a multi-line desc);
    `contains` a case-insensitive substring; `field` finds a text field by its label."""
    if not n.visible:
        return False
    texts = [t for t in (n.desc, n.text, n.hint) if t]
    if label is not None and not any(t == label or label in t.split('\n') for t in texts):
        return False
    if contains is not None and not any(contains.lower() in t.lower() for t in texts):
        return False
    if regex is not None and not any(re.search(regex, t) for t in texts):
        return False
    if rid is not None and n.rid != rid:
        return False
    if cls is not None and not n.cls.endswith(cls):
        return False
    if field is not None:
        # A Flutter text field exposes its decoration label as the hint (and, once filled, the
        # label is still the first line of the hint/desc); "Password · required" style labels too.
        if not n.editable:
            return False
        if not any(t == field or t.startswith(field + '\n') or t.startswith(field + ' ·') for t in texts):
            return False
    if editable is not None and n.editable != editable:
        return False
    if checked is not None and n.checked != checked:
        return False
    if enabled is not None and n.enabled != enabled:
        return False
    return True


def parse(xml: str) -> Screen:
    nodes: list[Node] = []
    root = ET.fromstring(xml)
    for el in root.iter('node'):
        a = el.attrib
        m = _BOUNDS.match(a.get('bounds', ''))
        if not m:
            continue
        b = tuple(int(x) for x in m.groups())
        nodes.append(
            Node(
                text=a.get('text', ''),
                desc=a.get('content-desc', ''),
                rid=a.get('resource-id', ''),
                cls=a.get('class', ''),
                hint=a.get('hint', ''),
                bounds=b,  # type: ignore[arg-type]
                clickable=a.get('clickable') == 'true',
                enabled=a.get('enabled') == 'true',
                checked=a.get('checked') == 'true',
                checkable=a.get('checkable') == 'true',
                focused=a.get('focused') == 'true',
                selected=a.get('selected') == 'true',
                scrollable=a.get('scrollable') == 'true',
                password=a.get('password') == 'true',
            )
        )
    return Screen(nodes, xml)


@dataclass
class Device:
    serial: str = field(default_factory=lambda: os.environ.get('E2E_DEVICE', 'emulator-5554'))
    package: str = PACKAGE
    log: Callable[[str], None] = print
    _last: Screen | None = None

    # ── adb ────────────────────────────────────────────────────────────────────────────────────
    def adb(self, *args: str, check: bool = True, timeout: float = 60) -> str:
        cmd = [ADB, '-s', self.serial, *args]
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if check and p.returncode != 0:
            raise EnvironmentFailure(f'adb {" ".join(args)} → {p.returncode}: {p.stderr.strip()}')
        return p.stdout

    def shell(self, command: str, check: bool = True, timeout: float = 60) -> str:
        return self.adb('shell', command, check=check, timeout=timeout)

    def assert_ready(self) -> dict[str, str]:
        # LIVE E2E runs on the Android Emulator only — never a physical or wireless device, whatever
        # E2E_DEVICE says. Both the adb serial and the kernel must say emulator.
        if not re.fullmatch(r'emulator-\d+', self.serial):
            raise EnvironmentFailure(f'refusing to run on {self.serial}: LIVE E2E targets an emulator-* device only')
        state = subprocess.run([ADB, '-s', self.serial, 'get-state'], capture_output=True, text=True)
        if state.stdout.strip() != 'device':
            raise EnvironmentFailure(f'{self.serial} is not attached ({state.stderr.strip()})')
        if self.shell('getprop ro.kernel.qemu').strip() != '1':
            raise EnvironmentFailure(f'refusing to run on {self.serial}: it is not a QEMU emulator')
        if self.shell('getprop sys.boot_completed').strip() != '1':
            raise EnvironmentFailure(f'{self.serial} has not finished booting')
        if self.package not in self.shell(f'pm list packages {self.package}'):
            raise EnvironmentFailure(f'{self.package} is not installed on {self.serial}')
        return {
            'serial': self.serial,
            'avd': self.shell('getprop ro.boot.qemu.avd_name', check=False).strip()
            or self.shell('getprop ro.kernel.qemu.avd_name', check=False).strip(),
            'android': self.shell('getprop ro.build.version.release').strip(),
            'api': self.shell('getprop ro.build.version.sdk').strip(),
            'package': self.package,
        }

    # ── app lifecycle ──────────────────────────────────────────────────────────────────────────
    def launcher_activity(self) -> str:
        out = self.shell(f'cmd package resolve-activity --brief {self.package}').strip().splitlines()
        return out[-1].strip() if out else ''

    def launch(self) -> None:
        """Starts the launcher activity and waits until its window holds the input focus — input
        sent to an activity that has no focused window yet is what produces a launch-time ANR on
        a loaded emulator ("Application does not have a focused window")."""
        self.shell(f'am start -W -n {self.launcher_activity()}', timeout=90)
        self.wait_focused()

    def wait_focused(self, timeout: float = 45) -> None:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            focus = self.shell('dumpsys window | grep -m1 mCurrentFocus', check=False)
            if self.package in focus:
                time.sleep(0.5)
                return
            time.sleep(0.5)
        raise EnvironmentFailure(f'{self.package} never got the window focus within {timeout:.0f}s')

    def close_system_dialogs(self) -> list[str]:
        """Closes an ANR / crash dialog left by an earlier scenario, returning what it said, so the
        next scenario starts clean (the earlier one has already failed and recorded it)."""
        seen = []
        for _ in range(3):
            screen = self._dump_raw()
            title = next((n.text for n in screen.nodes if n.rid == 'android:id/alertTitle'), '')
            close = next((n for n in screen.nodes if n.rid in ('android:id/aerr_close', 'android:id/aerr_restart')), None)
            if not close:
                break
            seen.append(title)
            x, y = close.center
            self.shell(f'input tap {x} {y}')
            time.sleep(1)
        return seen

    def stop(self) -> None:
        self.shell(f'am force-stop {self.package}')

    def reset(self) -> None:
        """A first-run app: data, secure storage and caches cleared, as after a reinstall."""
        self.shell(f'pm clear {self.package}')

    def relaunch(self) -> None:
        self.stop()
        self.launch()

    def open_link(self, url: str, explicit: bool = False) -> None:
        """Opens [url] the way a tapped link does. [explicit] addresses the app's activity directly
        (as the OS does once App Links are verified) so a path outside the intent filters still
        reaches the app's own router."""
        target = f'-n {self.launcher_activity()}' if explicit else self.package
        self.shell(f'am start -W -a android.intent.action.VIEW -d {shlex.quote(url)} {target}', timeout=90)

    def install_stamp(self) -> str:
        out = self.shell(f'dumpsys package {self.package} | grep -m1 lastUpdateTime', check=False)
        return out.split('=', 1)[-1].strip()

    def foreground_package(self) -> str:
        out = self.shell('dumpsys activity activities | grep -m1 -E "topResumedActivity|mResumedActivity"', check=False)
        m = re.search(r'u0 ([\w.]+)/', out)
        return m.group(1) if m else ''

    def app_pid(self) -> str:
        return self.shell(f'pidof {self.package}', check=False).strip()

    # ── reading the screen ─────────────────────────────────────────────────────────────────────
    def dump(self) -> Screen:
        """The current screen. A system ANR or crash dialog in front of the app is never something a
        scenario should tap through: it fails the scenario at once, with the dialog's words."""
        screen = self._dump_raw()
        dialog = next((n for n in screen.nodes if n.rid.startswith('android:id/aerr_')), None)
        if dialog is not None:
            title = next((n.text for n in screen.nodes if n.rid == 'android:id/alertTitle'), 'system dialog')
            raise EnvironmentFailure(f'Android is showing "{title}" over the app (see failure-logcat.txt for the ANR/crash reason)')
        return screen

    def _dump_raw(self) -> Screen:
        # 'null root node' is normal for a moment while a window is being created (splash, a new
        # route); it is retried for a few seconds before it counts as an environment failure.
        last_err = ''
        for _ in range(15):
            out = self.adb('exec-out', 'uiautomator', 'dump', '--compressed', '/dev/tty', check=False)
            start = out.find('<?xml')
            end = out.rfind('</hierarchy>')
            if start >= 0 and end > start:
                self._last = parse(out[start : end + len('</hierarchy>')])
                return self._last
            last_err = out.strip()[-200:]
            time.sleep(0.4)
        raise EnvironmentFailure(f'uiautomator dump failed: {last_err}')

    def wait(self, timeout: float = 15, interval: float = 0.4, **q) -> Node:
        """Waits for a node matching [q] to be on screen and returns it."""
        deadline = time.monotonic() + timeout
        while True:
            screen = self.dump()
            hit = screen.find(**q)
            if hit:
                return hit
            if time.monotonic() > deadline:
                raise E2EFailure(f'not on screen after {timeout:.0f}s: {q}\n--- screen ---\n{screen.describe()}')
            time.sleep(interval)

    def wait_gone(self, timeout: float = 15, **q) -> None:
        deadline = time.monotonic() + timeout
        while True:
            screen = self.dump()
            if not screen.has(**q):
                return
            if time.monotonic() > deadline:
                raise E2EFailure(f'still on screen after {timeout:.0f}s: {q}')
            time.sleep(0.4)

    def wait_any(self, options: dict[str, dict], timeout: float = 20) -> tuple[str, Node]:
        """Waits for the first of several outcomes; returns its name — for asserting which one came."""
        deadline = time.monotonic() + timeout
        while True:
            screen = self.dump()
            for name, q in options.items():
                hit = screen.find(**q)
                if hit:
                    return name, hit
            if time.monotonic() > deadline:
                raise E2EFailure(f'none of {list(options)} after {timeout:.0f}s\n--- screen ---\n{screen.describe()}')
            time.sleep(0.4)

    def sees(self, **q) -> bool:
        return self.dump().has(**q)

    def expect(self, message: str = '', **q) -> Node:
        hit = self.dump().find(**q)
        if not hit:
            raise E2EFailure(f'{message or "expected on screen"}: {q}\n--- screen ---\n{self._last.describe() if self._last else ""}')
        return hit

    def expect_absent(self, message: str = '', **q) -> None:
        hit = self.dump().find(**q)
        if hit:
            raise E2EFailure(f'{message or "must not be on screen"}: {q} → {hit}')

    def observe(self, duration: float, **q) -> bool:
        """Polls for [duration] seconds; True if [q] was ever seen (catches transient states such as
        a busy indicator that lasts a fraction of a second)."""
        deadline = time.monotonic() + duration
        while time.monotonic() < deadline:
            if self.dump().has(**q):
                return True
        return False

    # ── acting ─────────────────────────────────────────────────────────────────────────────────
    def tap(self, node: Node | None = None, timeout: float = 15, **q) -> Node:
        target = node or self.wait(timeout=timeout, **q)
        x, y = target.center
        self.shell(f'input tap {x} {y}')
        time.sleep(0.35)
        return target

    def tap_start(self, node: Node) -> Node:
        """Taps near the leading edge of [node]. For a left-aligned button whose accessibility node
        is wider than the button drawn (the node spans the row, the button does not), the node's
        centre is empty space. Coordinate fallback, justified by the node's own bounds."""
        l, t, r, b = node.bounds
        self.tap_at(l + min(120, (r - l) // 4), (t + b) // 2, why='node wider than the drawn button')
        return node

    def tap_at(self, x: int, y: int, why: str) -> None:
        """Coordinate fallback. [why] is mandatory: it states why no semantic selector exists."""
        assert why, 'a coordinate tap must say why no selector could be used'
        self.shell(f'input tap {x} {y}')
        time.sleep(0.35)

    def long_press(self, node: Node | None = None, ms: int = 900, **q) -> Node:
        target = node or self.wait(**q)
        x, y = target.center
        self.shell(f'input swipe {x} {y} {x} {y} {ms}')
        time.sleep(0.35)
        return target

    def type_text(self, text: str) -> None:
        """Types through the soft keyboard's input connection, chunked (long `input text` calls are
        dropped by the IME on some images)."""
        for i in range(0, len(text), 20):
            chunk = text[i : i + 20].replace(' ', '%s')
            self.shell(f'input text {shlex.quote(chunk)}')
        time.sleep(0.2)

    def key(self, *codes: str) -> None:
        self.shell('input keyevent ' + ' '.join(codes))
        time.sleep(0.2)

    def clear_focused(self, length: int = 0) -> None:
        """Empties the focused field: select-all + delete, then deletes whatever is left (some IMEs
        ignore Ctrl+A). A secret field shows one bullet per character, so its length is readable too."""
        self.shell('input keycombination KEYCODE_CTRL_LEFT KEYCODE_A', check=False)
        self.key('KEYCODE_DEL')
        focused = next((n for n in self.dump().nodes if n.editable and n.focused), None)
        left = len(focused.text) if focused and focused.text and focused.text != focused.hint else 0
        if left or (focused is None and length):
            self.shell('input keyevent KEYCODE_MOVE_END')
            self.shell('input keyevent ' + ' '.join(['KEYCODE_DEL'] * ((left or length) + 2)))

    def settle(self, timeout: float = 3) -> Screen:
        """Waits until two consecutive reads of the screen agree on every node's position — a
        keyboard opening re-centres a form, and a tap aimed at the old position lands elsewhere."""
        deadline = time.monotonic() + timeout
        prev = self.dump()
        while time.monotonic() < deadline:
            time.sleep(0.6)
            cur = self.dump()
            if [(n.label, n.bounds) for n in cur.nodes] == [(n.label, n.bounds) for n in prev.nodes]:
                return cur
            prev = cur
        return prev

    def focus_field(self, field_label: str) -> Node:
        """Taps the field until it really holds the focus (a person would see the caret)."""
        for _ in range(3):
            self.settle()
            target = self.scroll_to(field=field_label)
            if target.focused:
                return target
            self.tap(target)
            focused = self.settle().find(field=field_label)
            if focused and focused.focused:
                return focused
        raise E2EFailure(f'could not focus the {field_label!r} field\n--- screen ---\n{self._last.describe() if self._last else ""}')

    def fill(self, field_label: str, value: str, clear: bool = True, previous_length: int = 40) -> Node:
        """Focuses the field labelled [field_label], empties it, types [value], and reads it back
        (secret fields only by length, since the screen shows bullets). The emulator's IME now and
        then drops injected text right after the keyboard opens; one clean retype is allowed, and
        the field must still end up holding exactly [value]."""
        target = self.focus_field(field_label)
        shown = ''
        for attempt in range(2):
            if clear or attempt:
                self.clear_focused(previous_length)
            if value:
                self.type_text(value)
            time.sleep(0.3)
            screen = self.dump()
            # A search field's only name is its hint, which Flutter stops exposing once text is in;
            # the focused field is then the one just typed into.
            after = screen.find(field=field_label) or next((n for n in screen.nodes if n.editable and n.focused), None)
            if after is None or not after.focused:
                raise E2EFailure(f'typing into {field_label!r} left the field unfocused')
            shown = after.text if after.text != after.hint else ''
            ok = len(shown) == len(value) if after.password else (shown == value or (not value and shown in ('', after.hint)))
            if ok:
                return target
        masked = '•' * len(value) if after.password else repr(value)
        raise E2EFailure(f'{field_label!r} shows {shown!r} after typing {masked} (twice)')

    def hide_keyboard(self) -> None:
        if 'mInputShown=true' in self.shell('dumpsys input_method | grep mInputShown', check=False):
            self.key('KEYCODE_BACK')

    def back(self) -> None:
        self.key('KEYCODE_BACK')
        time.sleep(0.4)

    def swipe(self, x1: int, y1: int, x2: int, y2: int, ms: int = 350) -> None:
        self.shell(f'input swipe {x1} {y1} {x2} {y2} {ms}')
        time.sleep(0.5)

    def screen_size(self) -> tuple[int, int]:
        m = re.search(r'(\d+)x(\d+)', self.shell('wm size'))
        return (int(m.group(1)), int(m.group(2))) if m else (1080, 2400)

    def scroll(self, direction: str = 'down', fraction: float = 0.45) -> None:
        w, h = self.screen_size()
        x = w // 2
        top, bottom = int(h * 0.30), int(h * 0.30 + h * fraction)
        if direction == 'down':
            self.swipe(x, bottom, x, top)
        else:
            self.swipe(x, top, x, bottom)

    def scroll_to(self, max_swipes: int = 8, direction: str = 'down', **q) -> Node:
        """Scrolls until a node matching [q] is fully within the usable screen — first in
        [direction], then back the other way (a target can sit above where the page now is)."""
        w, h = self.screen_size()
        for way in (direction, 'up' if direction == 'down' else 'down'):
            for _ in range(max_swipes + 1):
                screen = self.dump()
                hit = screen.find(**q)
                # Its top edge comfortably on screen: a row peeking out above the tab bar is not
                # something a person would tap.
                if hit and 100 <= hit.bounds[1] <= h * 0.8:
                    return hit
                before = screen.text_blob()
                self.scroll(way)
                if self.dump().text_blob() == before:
                    hit = self._last.find(**q) if self._last else None
                    if hit:
                        return hit
                    break
        raise E2EFailure(f'could not scroll to {q}\n--- screen ---\n{self._last.describe() if self._last else ""}')

    def automation_settings(self) -> dict[str, str]:
        """System animations off (the standard UI-automation setting): on a software-rendered
        emulator they are the largest CPU cost, and they make every wait longer. Flutter reads
        this as "reduce animations"."""
        for key in ('window_animation_scale', 'transition_animation_scale', 'animator_duration_scale'):
            self.shell(f'settings put global {key} 0')
        return {'animations': 'off (window/transition/animator scale 0)'}

    # ── network (offline scenarios) ────────────────────────────────────────────────────────────
    def set_network(self, online: bool) -> None:
        state = 'enable' if online else 'disable'
        self.shell(f'svc wifi {state}', check=False)
        self.shell(f'svc data {state}', check=False)
        time.sleep(2.5)

    # ── evidence ───────────────────────────────────────────────────────────────────────────────
    def screenshot(self, path: Path) -> Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        data = subprocess.run([ADB, '-s', self.serial, 'exec-out', 'screencap', '-p'], capture_output=True).stdout
        path.write_bytes(data)
        return path

    def logcat_clear(self) -> None:
        self.adb('logcat', '-c', check=False)

    def logcat(self, path: Path, lines: int = 1500) -> Path:
        path.parent.mkdir(parents=True, exist_ok=True)
        out = self.adb('logcat', '-d', '-v', 'time', '-t', str(lines), check=False)
        path.write_text(out)
        return path

    def flutter_errors(self) -> list[str]:
        """Uncaught Flutter/Dart errors and crashes **of the app under test** since the last
        logcat clear. Android's FATAL EXCEPTION block names its process on the next line; only
        the app's own count — the uiautomator processes this driver starts can crash on their own."""
        keys = ('EXCEPTION CAUGHT', 'Unhandled Exception', 'RenderFlex overflowed', 'Another exception was thrown')
        flutter = self.adb('logcat', '-d', '-s', 'flutter:E', 'flutter:W', 'flutter:I', check=False)
        found = [line for line in flutter.splitlines() if any(k in line for k in keys)]
        crashes = self.adb('logcat', '-d', '-b', 'crash', '-b', 'main', '-s', 'AndroidRuntime:E', check=False).splitlines()
        for i, line in enumerate(crashes):
            if 'FATAL EXCEPTION' in line:
                process = next((l for l in crashes[i + 1 : i + 4] if 'Process:' in l), '')
                if f'Process: {self.package},' in process:
                    found.append(line + ' | ' + process.strip())
        return found

def first(iterable: Iterable[Node]) -> Node | None:
    return next(iter(iterable), None)
