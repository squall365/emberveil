#!/usr/bin/env python3
"""A1 gate (checklist A): project.godot must target the gl_compatibility renderer (WebGL2).

EMBERVEIL is a low-end-web HTML5 title, so the renderer MUST be gl_compatibility. This script
asserts the literal token is present in project.godot.

Exits 0 if `gl_compatibility` is present, 1 otherwise.
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = os.path.join(ROOT, "project.godot")


def main() -> int:
    if not os.path.isfile(PROJECT):
        print("FAIL: project.godot not found at %s" % PROJECT)
        return 1
    with open(PROJECT, "r", encoding="utf-8") as fh:
        text = fh.read()
    if "gl_compatibility" in text:
        print("PASS: project.godot declares renderer/rendering_method=gl_compatibility (WebGL2)")
        return 0
    print("FAIL: project.godot missing 'gl_compatibility' (required for WebGL2 / low-end web)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
