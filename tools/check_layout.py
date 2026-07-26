#!/usr/bin/env python3
"""A4 gate (checklist A): required repo layout present; no stray .godot residue committed.

Per OQ3 / A4, the following top-level directories MUST exist:
  content, src, tests, docs  (+ docs/architecture)
and a headless run must not leave committed .godot residue (it must be absent, or
explicitly gitignored).

`assets/` is OPTIONAL: if absent it only emits a warning (exit 0). Many WebGL2 titles author
art directly under content/ or skip pre-baked asset folders; absence is not a layout fault.
If present, it is reported as PASS.

Exits 0 if all required dirs exist and .godot is absent/gitignored, else 1.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REQUIRED_DIRS = ["content", "src", "tests", "docs", "docs/architecture"]
OPTIONAL_DIRS = ["assets"]
GODOT_DIR = os.path.join(ROOT, ".godot")


def main() -> int:
    failures = []

    for d in REQUIRED_DIRS:
        path = os.path.join(ROOT, d)
        if os.path.isdir(path):
            print("PASS: directory exists: %s" % d)
        else:
            failures.append("missing required directory: %s" % d)

    # assets/ is optional: warn but never fail.
    for d in OPTIONAL_DIRS:
        path = os.path.join(ROOT, d)
        if os.path.isdir(path):
            print("PASS: optional directory present: %s" % d)
        else:
            print("WARN: optional directory absent (non-fatal): %s" % d)

    # .godot residue check: must be absent, or explicitly gitignored.
    if os.path.isdir(GODOT_DIR):
        gitignore = os.path.join(ROOT, ".gitignore")
        ignored = False
        if os.path.isfile(gitignore):
            with open(gitignore, "r", encoding="utf-8") as fh:
                for line in fh:
                    if ".godot" in line:
                        ignored = True
                        break
        if ignored:
            print("PASS: .godot present but gitignored (no committed residue)")
        else:
            failures.append(".godot directory present and NOT gitignored (risk of committed residue)")
    else:
        print("PASS: no .godot directory (no headless residue)")

    if failures:
        for f in failures:
            print("FAIL: " + f)
        return 1
    print("PASS: all A4 layout checks satisfied")
    return 0


if __name__ == "__main__":
    sys.exit(main())
