#!/usr/bin/env python3
"""Voice lint for journal posts — deterministic, fail-closed.

Enforces the ComeHomeAlabama voice contract (the machine-readable block in
coastal-realty-ops brand/voice-profile.md, mirrored here so the public repo
stays self-contained):

  1. Denylist words/phrases (billboard-speak + AI slop) — hard fail.
  2. Required CTA: "call or text" + (251) 597-5809 somewhere in the body.
  3. Em-dash budget: max 1 per 150 words (the site voice prefers a period or
     comma where an em-dash would stack).
  4. Tier word-count bands (deterministic downgrade backstop):
     T1 300-500 · T2 700-1100 · T3 1400-2000.

Usage: lint-post-voice.py <post.mdx> [more.mdx ...]
Exit 0 = all pass; 1 = at least one failure (reasons on stdout).
"""

import re
import sys

DENYLIST = [
    "stunning",
    "dream home",
    "luxury lifestyle",
    "nestled",
    "boasts",
    "breathtaking",
    "oasis",
    "paradise found",
    "delve",
    "elevate your",
    "seamless",
    "unlock",
    "game-changer",
    "game changer",
    "in today's market",
    "look no further",
    "hidden gem",
    "!!",
]

TIER_BANDS = {"T1": (300, 500), "T2": (700, 1100), "T3": (1400, 2000)}
CTA_PHONE = "(251) 597-5809"
CTA_RE = re.compile(r"call or text", re.IGNORECASE)


def split_frontmatter(raw: str):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", raw, re.DOTALL)
    if not m:
        return None, raw
    return m.group(1), m.group(2)


def lint(path: str) -> list[str]:
    errors = []
    raw = open(path, encoding="utf-8").read()
    fm, body = split_frontmatter(raw)
    if fm is None:
        errors.append("no frontmatter block")
        body = raw
        tier = "T2"
    else:
        tm = re.search(r'^tier:\s*["\']?(T[123])', fm, re.MULTILINE)
        tier = tm.group(1) if tm else "T2"

    lower = body.lower()
    for phrase in DENYLIST:
        if phrase in lower:
            errors.append(f'denylist phrase present: "{phrase}"')

    if CTA_PHONE not in body:
        errors.append(f"missing CTA phone {CTA_PHONE}")
    if not CTA_RE.search(body):
        errors.append('missing "call or text" CTA')

    words = len(re.findall(r"\b\w+\b", body))
    em_dashes = body.count("—") + body.count(" -- ")
    budget = max(1, words // 150)
    if em_dashes > budget:
        errors.append(f"em-dash overuse: {em_dashes} in {words} words (budget {budget})")

    lo, hi = TIER_BANDS[tier]
    if not lo <= words <= hi:
        fit = next((t for t, (a, b) in TIER_BANDS.items() if a <= words <= b), None)
        errors.append(
            f"word count {words} outside {tier} band {lo}-{hi}"
            + (f" — retier as {fit}" if fit else " — cut or extend to a band")
        )
    return errors


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: lint-post-voice.py <post.mdx> [...]")
        return 1
    failed = False
    for path in sys.argv[1:]:
        errs = lint(path)
        if errs:
            failed = True
            print(f"FAIL {path}")
            for e in errs:
                print(f"  - {e}")
        else:
            print(f"PASS {path}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
