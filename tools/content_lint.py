#!/usr/bin/env python3
"""
EMBERVEIL — Content Lint (checklist F ⛔, ADR-003).

Validates authored content (JSON defs under content/) so typos/omissions fail fast:
  * every def has a non-empty "id"
  * ids are unique within a file and globally across content/
  * element references resolve to the 7-element set
  * (extensible) required fields per type

Pure stdlib. Runs in CI; exits non-zero on any violation.

Usage:
    python3 tools/content_lint.py [--root content]
"""
import argparse
import json
import os
import sys

ELEMENTS = {"ember", "frost", "storm", "stone", "gale", "lumen", "umbra", "none"}
ELEMENT_KEYS = {"element", "elem", "affinity", "elementId"}


def _iter_defs(node, path, out):
    if isinstance(node, dict):
        if "id" in node:
            out.append((node, path))
        for v in node.values():
            _iter_defs(v, path, out)
    elif isinstance(node, list):
        for v in node:
            _iter_defs(v, path, out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default="content")
    args = ap.parse_args()

    if not os.path.isdir(args.root):
        print("[content_lint] nothing to lint (no %s dir)" % args.root)
        sys.exit(0)

    defs = []
    for dp, _, files in os.walk(args.root):
        for fn in files:
            if not fn.endswith(".json"):
                continue
            path = os.path.join(dp, fn)
            try:
                with open(path) as f:
                    data = json.load(f)
            except Exception as e:  # noqa: BLE001
                print("[content_lint] FAIL: %s is not valid JSON: %s" % (path, e))
                sys.exit(1)
            _iter_defs(data, path, defs)

    errors = []
    seen_global = set()
    for obj, src in defs:
        oid = obj.get("id")
        if not oid:
            errors.append("MISSING id in %s" % src)
            continue
        if oid in seen_global:
            errors.append("DUPLICATE id '%s' (already defined)" % oid)
        seen_global.add(oid)
        for k, v in obj.items():
            if k.lower() in ELEMENT_KEYS and str(v).lower() not in ELEMENTS:
                errors.append("BAD element ref '%s' in %s (id=%s)" % (v, src, oid))

    print("[content_lint] scanned %d defs across %s" % (len(defs), args.root))
    if errors:
        print("[FAIL]")
        for e in errors:
            print("  - " + e)
        sys.exit(1)
    print("[PASS] content integrity OK")
    sys.exit(0)


if __name__ == "__main__":
    main()
