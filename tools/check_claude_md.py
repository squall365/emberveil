#!/usr/bin/env python3
"""A2 gate (checklist A): CLAUDE.md must exist, be non-empty, reference the main architecture
doc, and state the locked engine version (4.x).

Per the QA plan A2 / OQ3, the engineering guide must:
  - exist and be non-empty,
  - reference docs/architecture/main-architecture.md,
  - contain the engine version string (e.g. 4.3).

Exits 0 only if ALL checks pass; otherwise 1 with a per-check report.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLAUDE = os.path.join(ROOT, "CLAUDE.md")
EXPECTED_ENGINE = r"4\.\d"          # e.g. 4.3
ARCH_REF = "main-architecture.md"   # doc/architecture path referenced by A2


def main() -> int:
    failures = []
    if not os.path.isfile(CLAUDE):
        print("FAIL: CLAUDE.md missing")
        return 1
    with open(CLAUDE, "r", encoding="utf-8") as fh:
        text = fh.read()

    if len(text.strip()) == 0:
        failures.append("CLAUDE.md is empty")
    else:
        print("PASS: CLAUDE.md is non-empty (%d bytes)" % len(text))

    if ARCH_REF in text:
        print("PASS: CLAUDE.md references %s" % ARCH_REF)
    else:
        failures.append("CLAUDE.md does not reference %s" % ARCH_REF)

    m = re.search(EXPECTED_ENGINE, text)
    if m:
        print("PASS: CLAUDE.md states engine version %s" % m.group(0))
    else:
        failures.append("CLAUDE.md does not state an engine version (e.g. 4.3)")

    if failures:
        for f in failures:
            print("FAIL: " + f)
        return 1
    print("PASS: all A2 checks satisfied")
    return 0


if __name__ == "__main__":
    sys.exit(main())
