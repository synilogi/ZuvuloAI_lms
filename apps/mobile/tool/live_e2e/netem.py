#!/usr/bin/env python3
"""A network conditioner between the emulator and the local contract server.

The E2E build of the dev flavor talks to http://10.0.2.2:4200 (config/dev_e2e.local.json). The
contract server listens on 4201 and this relay listens on 4200, forwarding every byte unchanged. A scenario that
needs to *see* a loading state sets a latency, and each response is then held back that long — the
emulator console's `network delay` only throttles the emulated cellular modem, not the Wi-Fi the
app actually uses, so it cannot do this.

    python3 tool/live_e2e/netem.py serve [--listen 4200] [--upstream 4201]   (foreground)
    python3 tool/live_e2e/netem.py delay 2500 | delay 0 | down | up

The latency lives in a file (E2E_NETEM_FILE), so the runner changes it without talking to the
process. Nothing is ever rewritten, cached or faked: it is a pipe with an optional wait.
"""

from __future__ import annotations

import argparse
import os
import select
import socket
import sys
import threading
import time
from pathlib import Path

MOBILE = Path(__file__).resolve().parent.parent.parent
CONTROL = Path(os.environ.get('E2E_NETEM_FILE', MOBILE / '.live_e2e' / 'netem_delay_ms'))


def _control() -> str:
    try:
        return CONTROL.read_text().strip()
    except FileNotFoundError:
        return ''


def current_delay() -> float:
    try:
        return max(0, int(_control() or 0)) / 1000
    except ValueError:
        return 0.0


def server_down() -> bool:
    """`down`: every connection is accepted and closed at once — what the app sees when the
    academy's API is unreachable while the device itself is online."""
    return _control() == 'down'


def set_delay(ms: int) -> None:
    CONTROL.parent.mkdir(parents=True, exist_ok=True)
    CONTROL.write_text(str(int(ms)))


def set_down(down: bool) -> None:
    CONTROL.parent.mkdir(parents=True, exist_ok=True)
    CONTROL.write_text('down' if down else '0')


def _pipe(client: socket.socket, upstream_port: int) -> None:
    if server_down():
        client.close()
        return
    try:
        upstream = socket.create_connection(('127.0.0.1', upstream_port), timeout=10)
    except OSError:
        client.close()
        return
    awaiting_response = False
    socks = [client, upstream]
    try:
        while True:
            readable, _, _ = select.select(socks, [], [], 120)
            if not readable:
                return
            for s in readable:
                data = s.recv(65536)
                if not data:
                    return
                if s is client:
                    awaiting_response = True
                    upstream.sendall(data)
                else:
                    if awaiting_response:
                        delay = current_delay()
                        if delay:
                            time.sleep(delay)
                        awaiting_response = False
                    client.sendall(data)
    except OSError:
        return
    finally:
        for s in socks:
            try:
                s.close()
            except OSError:
                pass


def serve(listen: int, upstream: int) -> None:
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(('127.0.0.1', listen))
    srv.listen(64)
    set_delay(0)
    print(f'netem relay :{listen} → :{upstream} (delay file {CONTROL})', flush=True)
    while True:
        client, _ = srv.accept()
        threading.Thread(target=_pipe, args=(client, upstream), daemon=True).start()


def main() -> int:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('serve')
    s.add_argument('--listen', type=int, default=4200)
    s.add_argument('--upstream', type=int, default=4201)
    d = sub.add_parser('delay')
    d.add_argument('ms', type=int)
    sub.add_parser('down')
    sub.add_parser('up')
    args = p.parse_args()
    if args.cmd == 'serve':
        serve(args.listen, args.upstream)
    elif args.cmd in ('down', 'up'):
        set_down(args.cmd == 'down')
    else:
        set_delay(args.ms)
    return 0


if __name__ == '__main__':
    sys.exit(main())
