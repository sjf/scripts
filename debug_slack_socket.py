#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import time

from slack_sdk.socket_mode import SocketModeClient
from slack_sdk.socket_mode.client import BaseSocketModeClient
from slack_sdk.socket_mode.request import SocketModeRequest
from slack_sdk.socket_mode.response import SocketModeResponse

SLACK_APP_TOKEN_ENV = "SLACK_APP_TOKEN"


def main() -> None:
    args = _parse_args()
    _configure_logging(args.sdk_log_level)

    app_token = _required_env(SLACK_APP_TOKEN_ENV)
    socket_client = SocketModeClient(
        app_token=app_token,
        ping_interval=args.ping_interval_seconds,
    )

    socket_client.on_message_listeners.append(_print_incoming_frame)
    socket_client.socket_mode_request_listeners.append(_ack_request)

    _status("connecting")
    socket_client.connect()
    _status("connected")

    started_at = time.monotonic()
    try:
        while args.duration_seconds <= 0 or time.monotonic() - started_at < args.duration_seconds:
            time.sleep(1)
    except KeyboardInterrupt:
        _status("interrupted")
    finally:
        socket_client.close()
        _status("closed")


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Connect to Slack Socket Mode and pretty-print raw websocket frames.",
    )
    parser.add_argument(
        "--duration-seconds",
        type=int,
        default=0,
        help="How long to run. 0 means run until interrupted.",
    )
    parser.add_argument(
        "--ping-interval-seconds",
        type=float,
        default=5.0,
        help="Slack Socket Mode websocket ping interval.",
    )
    parser.add_argument(
        "--sdk-log-level",
        default="WARNING",
        help="Python logging level for slack_sdk logs, written to stderr.",
    )
    return parser.parse_args()


def _configure_logging(level_name: str) -> None:
    level = getattr(logging, level_name.upper(), logging.WARNING)
    logging.basicConfig(level=level, stream=sys.stderr)


def _required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"missing required env var: {name}")
    return value


def _print_incoming_frame(message: str) -> None:
    try:
        parsed = json.loads(message)
    except json.JSONDecodeError:
        print(message, flush=True)
        return
    print(json.dumps(parsed, indent=2, ensure_ascii=False), flush=True)


def _ack_request(client: BaseSocketModeClient, request: SocketModeRequest) -> None:
    client.send_socket_mode_response(SocketModeResponse(envelope_id=request.envelope_id))
    _status(f"acked envelope_id:{request.envelope_id} request_type:{request.type}")


def _status(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


if __name__ == "__main__":
    main()
