#!/usr/bin/env python3
"""
Merge translations into TravelTips/Localizable.xcstrings without touching
entries that already exist (so edits made in Xcode are preserved).

Usage:
    python3 tools/i18n/add_translations.py tools/i18n/batch.json [--overwrite]

batch.json:
    {
      "zh-Hans": {"English key": "中文", ...},
      "en_plural": {"%lld days": ["%lld day", "%lld days"], ...},
      "no_translate": ["%@ %@", ...]
    }
"""
import json
import sys
from pathlib import Path

CATALOG = Path(__file__).resolve().parents[2] / "TravelTips" / "Localizable.xcstrings"


def unit(value):
    return {"stringUnit": {"state": "translated", "value": value}}


def main():
    batch = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    overwrite = "--overwrite" in sys.argv
    doc = json.loads(CATALOG.read_text(encoding="utf-8"))
    strings = doc.setdefault("strings", {})
    added = updated = 0

    for key, zh in batch.get("zh-Hans", {}).items():
        entry = strings.setdefault(key, {})
        loc = entry.setdefault("localizations", {})
        if "zh-Hans" in loc and not overwrite:
            continue
        updated += "zh-Hans" in loc
        added += "zh-Hans" not in loc
        loc["zh-Hans"] = unit(zh)
        entry.pop("shouldTranslate", None)

    for key, (one, other) in batch.get("en_plural", {}).items():
        loc = strings.setdefault(key, {}).setdefault("localizations", {})
        if "en" in loc and not overwrite:
            continue
        loc["en"] = {"variations": {"plural": {"one": unit(one), "other": unit(other)}}}

    for key in batch.get("no_translate", []):
        strings.setdefault(key, {"shouldTranslate": False})

    CATALOG.write_text(json.dumps(doc, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"added {added}, updated {updated}, total keys {len(strings)}")


if __name__ == "__main__":
    main()
