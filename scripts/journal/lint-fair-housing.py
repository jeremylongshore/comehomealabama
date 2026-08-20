#!/usr/bin/env python3
"""Fair-housing language lint — deterministic, fail-closed, NO overrides.

Screens journal posts for advertising language that describes who should live
somewhere by protected class (Fair Housing Act: race, color, religion, national
origin, sex, familial status, disability) or uses recognized steering proxies.
Modeled on HUD advertising guidance + NAR Article 10 training wordlists.

Two lists:
  HARD  — publication blocked, no exceptions (exit 1).
  WARN  — printed for human review, does not block (exit 0 if no HARD hits).

This gate is intentionally conservative: content marketing describes the
PROPERTY and the NUMBERS, never the people who "belong" in a neighborhood.

Usage: lint-fair-housing.py <post.mdx> [...]
"""

import re
import sys

HARD = [
    # familial status
    "no children", "no kids", "adults only", "adult building", "couples only",
    "singles only", "perfect for families", "ideal for families",
    "perfect for a family", "ideal for young families", "empty nesters only",
    # steering / exclusion proxies
    "exclusive neighborhood", "exclusive community", "integrated neighborhood",
    "traditional neighborhood values", "safe neighborhood", "low crime", "crime-free",
    "desirable neighbors", "right kind of people",
    # religion / national origin / race
    "christian community", "ethnic neighborhood", "hispanic neighborhood",
    "white neighborhood", "black neighborhood",
    # disability
    "no wheelchairs", "able-bodied",
]

WARN = [
    "family-friendly", "family oriented", "family-oriented", "great schools",
    "good schools", "top schools", "school district",
    "walking distance to church", "near churches", "close to church",
    "quiet neighborhood", "safest", "bachelor", "mother-in-law suite",
    "master bedroom", "master suite", "exclusive", "private community",
]


def body_of(raw: str) -> str:
    m = re.match(r"^---\n.*?\n---\n(.*)$", raw, re.DOTALL)
    return m.group(1) if m else raw


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: lint-fair-housing.py <post.mdx> [...]")
        return 1
    blocked = False
    for path in sys.argv[1:]:
        text = body_of(open(path, encoding="utf-8").read()).lower()
        hard_hits = [p for p in HARD if p in text]
        warn_hits = [p for p in WARN if p in text]
        if hard_hits:
            blocked = True
            print(f"BLOCK {path}")
            for h in hard_hits:
                print(f"  HARD: \"{h}\" — fair-housing violation, publication refused")
        else:
            print(f"PASS {path}")
        for w in warn_hits:
            print(f"  warn: \"{w}\" — review for steering tone (not blocking)")
    return 1 if blocked else 0


if __name__ == "__main__":
    sys.exit(main())
