#!/usr/bin/env python3
"""Fake OpenClaw gateway that connects to openclaw-slack-router and logs frames."""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import signal
from collections.abc import Mapping
from datetime import datetime
from typing import Any
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from aiohttp import ClientSession, WSMsgType


def _now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def _log(message: str, payload: object | None = None) -> None:
    if payload is None:
        print(f"{_now()} {message}", flush=True)
        return
    print(f"{_now()} {message} {json.dumps(payload, sort_keys=True, default=repr)}", flush=True)


def _router_ws_url(base_url: str, team_id: str, gateway_id: str | None) -> str:
    split = urlsplit(base_url)
    query = dict(parse_qsl(split.query, keep_blank_values=True))
    query["team_id"] = team_id
    if gateway_id:
        query["gateway_id"] = gateway_id
    return urlunsplit((split.scheme, split.netloc, split.path, urlencode(query), split.fragment))


def _parse_json(data: Any) -> object:
    if isinstance(data, bytes):
        data = data.decode("utf-8", errors="replace")
    if not isinstance(data, str):
        return repr(data)
    try:
        return json.loads(data)
    except json.JSONDecodeError:
        return data


def _string(value: object) -> str | None:
    return value if isinstance(value, str) else None


def _nested_mapping(value: object, key: str) -> Mapping[str, Any]:
    if isinstance(value, Mapping):
        nested = value.get(key)
        if isinstance(nested, Mapping):
            return nested
    return {}


def _slack_envelope_summary(frame: Mapping[str, Any]) -> dict[str, object]:
    payload = _nested_mapping(frame, "payload")
    event = _nested_mapping(payload, "event")
    routing = _nested_mapping(frame, "routing")
    text = _string(event.get("text"))
    if text is not None and len(text) > 240:
        text = f"{text[:240]}..."
    return {
        "type": frame.get("type"),
        "envelope_id": frame.get("envelope_id"),
        "envelope_type": frame.get("envelope_type"),
        "slack_event_id": frame.get("slack_event_id"),
        "team_id": frame.get("team_id"),
        "slack_channel_id": frame.get("slack_channel_id"),
        "slack_message_ts": frame.get("slack_message_ts"),
        "slack_user_group_id": frame.get("slack_user_group_id"),
        "mentioned_slack_user_group_ids": frame.get("mentioned_slack_user_group_ids"),
        "destination_id": frame.get("destination_id"),
        "gateway_id": frame.get("gateway_id"),
        "routing_strategy": routing.get("strategy"),
        "delivery_status": routing.get("delivery_status"),
        "event_type": event.get("type"),
        "event_subtype": event.get("subtype"),
        "channel_type": event.get("channel_type"),
        "user": event.get("user"),
        "text": text,
    }


def _hello_summary(frame: Mapping[str, Any]) -> dict[str, object]:
    return {
        "type": frame.get("type"),
        "connection_id": frame.get("connection_id"),
        "team_id": frame.get("team_id"),
        "gateway_id": frame.get("gateway_id"),
    }


async def _handle_json_frame(ws: Any, frame: Mapping[str, Any]) -> None:
    frame_type = frame.get("type")
    if frame_type == "hello":
        _log("<- router hello", _hello_summary(frame))
        return
    if frame_type == "slack_envelope":
        _log("<- router slack_envelope", _slack_envelope_summary(frame))
        _log("<- router raw slack_envelope", frame)
        ack = {"type": "ack", "envelope_id": frame.get("envelope_id")}
        await ws.send_str(json.dumps(ack))
        _log("-> router ack", ack)
        return
    _log("<- router JSON", frame)


async def _connect_once(args: argparse.Namespace) -> None:
    token = args.token or os.getenv("OPENCLAW_ROUTER_AUTH_TOKEN")
    if not token:
        raise SystemExit("Set OPENCLAW_ROUTER_AUTH_TOKEN or pass --token")

    url = _router_ws_url(args.router_url, args.team_id, args.gateway_id)
    headers = {"Authorization": f"Bearer {token}"}
    _log("connecting to openclaw-slack-router", {"url": url, "team_id": args.team_id})

    async with ClientSession() as session:
        async with session.ws_connect(url, headers=headers, heartbeat=args.heartbeat) as ws:
            _log("connected")
            async for message in ws:
                if message.type == WSMsgType.TEXT:
                    payload = _parse_json(message.data)
                    if isinstance(payload, Mapping):
                        await _handle_json_frame(ws, payload)
                    else:
                        _log("<- router TEXT", payload)
                elif message.type == WSMsgType.BINARY:
                    _log("<- router BINARY", message.data.decode("utf-8", errors="replace"))
                elif message.type == WSMsgType.ERROR:
                    _log("websocket error", {"error": repr(ws.exception())})
                    break
                elif message.type in {WSMsgType.CLOSE, WSMsgType.CLOSED, WSMsgType.CLOSING}:
                    _log("websocket closing", {"type": message.type.name})
                    break
    _log("disconnected")


async def _run(args: argparse.Namespace) -> None:
    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, stop.set)

    while not stop.is_set():
        connect_task = asyncio.create_task(_connect_once(args))
        stop_task = asyncio.create_task(stop.wait())
        try:
            done, _ = await asyncio.wait(
                {connect_task, stop_task}, return_when=asyncio.FIRST_COMPLETED
            )
            if stop_task in done:
                connect_task.cancel()
                await asyncio.gather(connect_task, return_exceptions=True)
                return
            stop_task.cancel()
            await asyncio.gather(stop_task, return_exceptions=True)
            await connect_task
            if args.once:
                return
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            _log("connection failed", {"error_type": type(exc).__name__, "error": str(exc)})
            if args.once:
                raise
        try:
            await asyncio.wait_for(stop.wait(), timeout=args.reconnect_delay)
        except asyncio.TimeoutError:
            pass


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--router-url",
        default="ws://127.0.0.1:8081/gateway/ws",
        help="openclaw-slack-router websocket URL",
    )
    parser.add_argument("--team-id", default="*", help="team_id to register for, or '*' catch-all")
    parser.add_argument("--gateway-id", default="fake-gateway")
    parser.add_argument("--token", default=None, help="gateway auth token; defaults to env")
    parser.add_argument(
        "--once", action="store_true", help="exit after the first disconnect/failure"
    )
    parser.add_argument("--reconnect-delay", type=float, default=2.0)
    parser.add_argument("--heartbeat", type=float, default=30.0)
    return parser


def main() -> None:
    asyncio.run(_run(_build_parser().parse_args()))


if __name__ == "__main__":
    main()
