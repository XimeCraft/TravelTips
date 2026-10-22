#!/usr/bin/env python3
"""
Phase 0 evaluation: text → ExtractedDocument JSON via a local Ollama model.

Usage:
    python3 tools/eval/extract_eval.py --model qwen3:4b [--samples tools/eval/samples]

Sends each sample .txt to Ollama with a JSON-schema-constrained output
(mirrors ExtractedDocument in docs/MVP2-smart-import.md §4), prints the
result and latency. No third-party dependencies.
"""
import argparse
import json
import sys
import time
import urllib.request
from pathlib import Path

OLLAMA_URL = "http://localhost:11434/api/chat"

SYSTEM_PROMPT = """You extract structured data from travel booking confirmations (flights, trains, buses, ferries, hotels, activities).
Rules:
- Output ONLY the JSON object matching the schema. No commentary.
- kind: flight | train | bus | ferry | hotel | activity | unknown
- Dates as yyyy-MM-dd. Times as HH:mm in 24h, local time of that place. Unknown → null.
- A round trip or a connection produces one segment per leg, in travel order.
- "+1" after an arrival time means arrival is the next calendar day.
- Ignore fare rules, cancellation policies, and marketing text.
- Always emit every field in the schema; use null when the document does not say.
- segments must be [] unless kind is flight, train, bus or ferry. stay must be null unless kind is hotel. activity must be null unless kind is activity.
- operatorName: airline / rail operator name. serviceNumber: the full flight or train number as printed (e.g. "CA981", "G1234").
- If a date has no year, infer it: order numbers often embed yyyyMMdd; otherwise use the trip dates given in the context.
- passengerNames: only real names found in the text, never placeholders.
- confidence: your own 0–1 estimate of how reliable the extraction is."""

SCHEMA = {
    "type": "object",
    "properties": {
        "kind": {"type": "string", "enum": ["flight", "train", "bus", "ferry", "hotel", "activity", "unknown"]},
        "confidence": {"type": "number"},
        "bookingReference": {"type": ["string", "null"]},
        "passengerNames": {"type": "array", "items": {"type": "string"}},
        "segments": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "operatorName": {"type": ["string", "null"]},
                    "serviceNumber": {"type": ["string", "null"]},
                    "fromCode": {"type": ["string", "null"]},
                    "fromName": {"type": "string"},
                    "toCode": {"type": ["string", "null"]},
                    "toName": {"type": "string"},
                    "departureDate": {"type": "string", "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"},
                    "departureTime": {"type": ["string", "null"], "pattern": "^[0-9]{2}:[0-9]{2}$"},
                    "arrivalDate": {"type": ["string", "null"], "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"},
                    "arrivalTime": {"type": ["string", "null"], "pattern": "^[0-9]{2}:[0-9]{2}$"},
                    "seat": {"type": ["string", "null"]},
                },
                "required": ["operatorName", "serviceNumber", "fromCode", "fromName", "toCode", "toName",
                             "departureDate", "departureTime", "arrivalDate", "arrivalTime", "seat"],
            },
        },
        "stay": {
            "type": ["object", "null"],
            "properties": {
                "name": {"type": "string"},
                "address": {"type": ["string", "null"]},
                "checkInDate": {"type": "string", "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"},
                "checkOutDate": {"type": "string", "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"},
                "checkInTime": {"type": ["string", "null"], "pattern": "^[0-9]{2}:[0-9]{2}$"},
                "roomType": {"type": ["string", "null"]},
                "confirmationNumber": {"type": ["string", "null"]},
            },
            "required": ["name", "address", "checkInDate", "checkOutDate", "checkInTime", "roomType", "confirmationNumber"],
        },
        "activity": {
            "type": ["object", "null"],
            "properties": {
                "name": {"type": "string"},
                "address": {"type": ["string", "null"]},
                "date": {"type": ["string", "null"], "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"},
                "time": {"type": ["string", "null"], "pattern": "^[0-9]{2}:[0-9]{2}$"},
                "ticketPrice": {"type": ["string", "null"]},
                "notes": {"type": ["string", "null"]},
            },
            "required": ["name", "address", "date", "time", "ticketPrice", "notes"],
        },
    },
    "required": ["kind", "confidence", "bookingReference", "passengerNames", "segments", "stay", "activity"],
}


def run_one(model: str, text: str, think: bool, context: str) -> tuple[dict | None, float, str]:
    body = {
        "model": model,
        "stream": False,
        "think": think,
        "format": SCHEMA,
        "options": {"temperature": 0, "num_ctx": 8192},
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"Context: {context}\n\nExtract from this document:\n\n{text}"},
        ],
    }
    req = urllib.request.Request(
        OLLAMA_URL, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"}
    )
    # Bypass any system HTTP proxy: Ollama is local.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    t0 = time.time()
    with opener.open(req, timeout=600) as resp:
        payload = json.load(resp)
    dt = time.time() - t0
    raw = payload["message"]["content"]
    try:
        return json.loads(raw), dt, raw
    except json.JSONDecodeError:
        return None, dt, raw


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True)
    ap.add_argument("--samples", default=str(Path(__file__).parent / "samples"))
    ap.add_argument("--think", action="store_true", help="enable thinking mode (slower)")
    ap.add_argument("--context", default="Today is 2026-10-21. The user's trip runs 2026-03-12 to 2026-03-23.")
    args = ap.parse_args()

    files = sorted(Path(args.samples).glob("*.txt"))
    if not files:
        print(f"no .txt samples in {args.samples}", file=sys.stderr)
        return 1

    total = 0.0
    for f in files:
        text = f.read_text(encoding="utf-8")
        print(f"\n=== {f.name}  ({len(text)} chars) ===")
        try:
            obj, dt, raw = run_one(args.model, text, args.think, args.context)
        except Exception as e:  # noqa: BLE001
            print(f"ERROR: {e}")
            continue
        total += dt
        print(f"latency: {dt:.1f}s")
        if obj is None:
            print("INVALID JSON:\n" + raw[:800])
        else:
            print(json.dumps(obj, ensure_ascii=False, indent=2))
    print(f"\ntotal: {total:.1f}s over {len(files)} docs, model={args.model}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
